import {
  Source,
  Adapter,
  AuthRequest,
  AuthResponse,
  SearchRequest,
  SearchResponse,
} from '@repo/contracts';

import {
  Chapter,
  ChapterSchema,
  Classification,
  Entry,
  EntrySchema,
  Manga,
  MangaSchema,
  Publication,
} from '@repo/schema';

import {
  USER_AGENT,
  ENDPOINTS,
  CDN_ENDPOINTS,
  IMAGE_QUALITY,
  CONTENT_FILTERS,
} from './config';

import {
  CoverArtRelationship,
  AuthorRelationship,
  ArtistRelationship,
  ScanlationGroupRelationship,
  MangadexEntry,
  ChapterEntry,
  MangadexCollectionResponseSchema,
  MangadexEntityResponseSchema,
  ChapterFeedResponseSchema,
  AtHomeServerResponseSchema,
  ContentRating,
  MangaStatus,
  LocalizedString,
} from './types';

export default class MangaDexSource extends Adapter {
  private static readonly API_SORT_MAPPING = {
    title: 'title',
    year: 'year',
    createdAt: 'createdAt',
    updatedAt: 'latestUploadedChapter',
    popularity: 'followedCount',
    rating: 'rating',
  } as const;

  private static readonly API_FILTER_MAPPING = {
    year: 'year',
    includeTag: 'includedTags[]',
    excludeTag: 'excludedTags[]',
    status: 'status[]',
    originalLanguage: 'originalLanguage[]',
    translatedLanguage: 'availableTranslatedLanguage[]',
    contentRating: 'contentRating[]',
  } as const;

  private static readonly PREFERRED_TITLE_LANGUAGES = [
    'en',
    'ja-ro',
    'kr',
    'ja',
  ] as const;

  private static readonly SEARCH_INCLUDES = ['cover_art'] as const;
  private static readonly DETAIL_INCLUDES = [
    'cover_art',
    'author',
    'artist',
    'tag',
  ] as const;

  private static readonly CHAPTER_INCLUDES = [
    'scanlation_group',
    'user',
  ] as const;

  constructor(source: Source) {
    super(source);
  }

  protected async performAuthentication(_: AuthRequest): Promise<AuthResponse> {
    // mangadex doesn't require auth for public api
    return {
      success: true,
      headers: {},
    };
  }

  protected buildParams(request: SearchRequest): URLSearchParams {
    const params = new URLSearchParams();

    if (request.query) {
      params.append('title', request.query);
    }

    const offset = (request.page - 1) * request.limit;
    params.append('limit', String(request.limit));
    params.append('offset', String(offset));

    if (request.sort !== 'relevance') {
      const apiSortField =
        MangaDexSource.API_SORT_MAPPING[
          request.sort as keyof typeof MangaDexSource.API_SORT_MAPPING
        ];
      if (apiSortField) {
        params.append(`order[${apiSortField}]`, request.direction);
      }
    }

    const filters = request.filters || {};
    Object.entries(filters).forEach(([key, value]) => {
      const apiParam =
        MangaDexSource.API_FILTER_MAPPING[
          key as keyof typeof MangaDexSource.API_FILTER_MAPPING
        ];

      if (!apiParam) return;

      const values = Array.isArray(value) ? value : [value];
      values.forEach((v) => params.append(apiParam, String(v)));
    });

    // apply defaults when not explicitly filtered
    if (!filters.status) {
      CONTENT_FILTERS.defaultStatuses.forEach((status) =>
        params.append('status[]', status),
      );
    }

    if (!filters.contentRating) {
      CONTENT_FILTERS.defaultContentRatings.forEach((rating) =>
        params.append('contentRating[]', rating),
      );
    }

    MangaDexSource.SEARCH_INCLUDES.forEach((include) =>
      params.append('includes[]', include),
    );

    return params;
  }

  protected async performSearch(
    params: URLSearchParams,
    headers?: Record<string, string>,
  ): Promise<SearchResponse> {
    const response = await this.fetchFromApi(ENDPOINTS.manga, params, headers);
    const json = await response.json();
    const collection = MangadexCollectionResponseSchema.parse(json);

    const limit = Number(params.get('limit'));
    const offset = Number(params.get('offset'));
    const currentPage = Math.floor(offset / limit) + 1;

    return {
      results: collection.data.map((entry) => this.buildSearchEntry(entry)),
      page: currentPage,
      more: offset + limit < collection.total,
    };
  }

  async getManga(
    slug: string,
    headers?: Record<string, string>,
  ): Promise<Manga> {
    const url = new URL(`${ENDPOINTS.manga}/${slug}`);
    MangaDexSource.DETAIL_INCLUDES.forEach((include) =>
      url.searchParams.append('includes[]', include),
    );

    const response = await this.fetchFromApi(url.toString(), null, headers);
    const json = await response.json();
    const entityResponse = MangadexEntityResponseSchema.parse(json);
    const { id, attributes, relationships = [] } = entityResponse.data;

    const authors = relationships.filter(
      (rel): rel is AuthorRelationship => rel.type === 'author',
    );

    const artists = relationships.filter(
      (rel): rel is ArtistRelationship => rel.type === 'artist',
    );

    const covers = relationships.filter(
      (rel): rel is CoverArtRelationship => rel.type === 'cover_art',
    );

    // combine authors and artists, removing duplicates
    const authorNames = [
      ...new Set([
        ...authors.map((a) => a.attributes?.name).filter(Boolean),
        ...artists.map((a) => a.attributes?.name).filter(Boolean),
      ]),
    ];

    return MangaSchema.parse({
      slug: id,
      title: this.selectPreferredTitle(attributes.title),
      authors: authorNames.length > 0 ? authorNames : undefined,
      alternativeTitles:
        attributes.altTitles
          ?.flatMap((titleObject: LocalizedString) =>
            Object.values(titleObject),
          )
          .filter((title: string) => title.trim().length > 0) || undefined,
      synopsis: this.selectPreferredDescription(attributes.description),
      createdAt: attributes.createdAt,
      updatedAt: attributes.updatedAt,
      classification: this.mapToClassification(attributes.contentRating),
      publication: this.mapToPublication(attributes.status),
      tags:
        attributes.tags
          ?.filter((tag) => tag.attributes?.name?.en)
          .map((tag) => tag.attributes.name.en) || undefined,
      covers:
        covers.length > 0
          ? covers
              .filter((cover) => cover.attributes?.fileName)
              .map(
                (cover) =>
                  `${CDN_ENDPOINTS.covers}/${id}/${cover.attributes.fileName}`,
              )
          : undefined,
      url: `https://mangadex.org/title/${id}`,
    });
  }

  async getChapters(
    mangaSlug: string,
    headers?: Record<string, string>,
  ): Promise<Chapter[]> {
    const allChapters: Chapter[] = [];
    const limit = 100; // mangadex max per request
    let offset = 0;
    let hasMore = true;

    while (hasMore) {
      const url = new URL(ENDPOINTS.feed(mangaSlug));
      url.searchParams.append('limit', String(limit));
      url.searchParams.append('offset', String(offset));
      url.searchParams.append('order[chapter]', 'asc');
      url.searchParams.append('order[volume]', 'asc');

      this.source.languages.forEach((lang) =>
        url.searchParams.append('translatedLanguage[]', lang),
      );

      MangaDexSource.CHAPTER_INCLUDES.forEach((include) =>
        url.searchParams.append('includes[]', include),
      );

      // include all ratings for chapters regardless of manga rating
      ['safe', 'suggestive', 'erotica', 'pornographic'].forEach((rating) =>
        url.searchParams.append('contentRating[]', rating),
      );

      const response = await this.fetchFromApi(url.toString(), null, headers);
      const json = await response.json();
      const feedResponse = ChapterFeedResponseSchema.parse(json);

      const validChapters = feedResponse.data
        .filter((chapter) => chapter.attributes.pages > 0)
        .map((chapter) => this.buildChapter(chapter));

      allChapters.push(...validChapters);

      hasMore =
        feedResponse.data.length === limit &&
        feedResponse.total > offset + limit;
      offset += limit;

      if (offset > 10000) {
        console.warn(`stopping chapter fetch at ${offset} for safety`);
        break;
      }
    }

    return allChapters;
  }

  async getChapter(
    _: string, // mangaslug unused - chapters are fetched directly by id
    chapterSlug: string,
    headers?: Record<string, string>,
  ): Promise<string[]> {
    const url = ENDPOINTS.at_home(chapterSlug);
    const response = await this.fetchFromApi(url, null, headers);
    const json = await response.json();
    const atHomeResponse = AtHomeServerResponseSchema.parse(json);

    const { baseUrl, chapter } = atHomeResponse;
    const { hash, data: fileNames, dataSaver: dataSaverFileNames } = chapter;

    if (!fileNames?.length) {
      return [];
    }

    const useDataSaver =
      IMAGE_QUALITY.page.dataSaver &&
      dataSaverFileNames &&
      dataSaverFileNames.length > 0;
    const pagesToUse = useDataSaver ? dataSaverFileNames : fileNames;
    const quality = useDataSaver ? 'data-saver' : 'data';

    return pagesToUse.map(
      (fileName: string) => `${baseUrl}/${quality}/${hash}/${fileName}`,
    );
  }

  private async fetchFromApi(
    endpoint: string,
    params: URLSearchParams | null,
    headers?: Record<string, string>,
  ): Promise<Response> {
    const url = params ? `${endpoint}?${params.toString()}` : endpoint;

    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': USER_AGENT,
        ...headers,
      },
    });

    if (response.ok) {
      return response;
    }

    const body = await response.text().catch(() => 'unknown error');
    throw new Error(
      `mangadex api error (${response.status}): ${response.statusText} - ${body}`,
    );
  }

  private buildSearchEntry(apiEntry: MangadexEntry): Entry {
    const coverArt = apiEntry.relationships?.find(
      (rel): rel is CoverArtRelationship => rel.type === 'cover_art',
    );

    const coverUrl = coverArt?.attributes?.fileName
      ? `${CDN_ENDPOINTS.covers}/${apiEntry.id}/${coverArt.attributes.fileName}.${IMAGE_QUALITY.cover.medium}.jpg`
      : null;

    return EntrySchema.parse({
      slug: apiEntry.id,
      title: this.selectPreferredTitle(apiEntry.attributes.title),
      cover: coverUrl,
    });
  }

  private buildChapter(chapterEntry: ChapterEntry): Chapter {
    const { id, attributes, relationships = [] } = chapterEntry;

    const scanlationGroup = relationships.find(
      (rel): rel is ScanlationGroupRelationship =>
        rel.type === 'scanlation_group',
    );

    const scanlator = scanlationGroup?.attributes?.name || undefined;
    const chapterNum = attributes.chapter;
    const parsedNumber = chapterNum ? parseFloat(chapterNum) : undefined;

    const titlePart = attributes.title?.trim();
    const chapterTitle = chapterNum
      ? titlePart
        ? `Chapter ${chapterNum}: ${titlePart}`
        : `Chapter ${chapterNum}`
      : titlePart || undefined;

    return ChapterSchema.parse({
      slug: id,
      title: chapterTitle,
      number: parsedNumber,
      scanlator,
      language: attributes.translatedLanguage || 'en',
      url: `https://mangadex.org/chapter/${id}`,
      date: attributes.publishAt || attributes.createdAt,
    });
  }

  private selectPreferredTitle(titles: LocalizedString): string | undefined {
    for (const language of MangaDexSource.PREFERRED_TITLE_LANGUAGES) {
      if (titles[language]) {
        return titles[language];
      }
    }
    return Object.values(titles)[0];
  }

  private selectPreferredDescription(
    descriptions?: LocalizedString,
  ): string | undefined {
    if (!descriptions) return undefined;
    return descriptions.en || Object.values(descriptions)[0];
  }

  private mapToClassification(rating?: ContentRating): Classification {
    if (!rating) return 'Unknown';

    const mappings: Record<ContentRating, Classification> = {
      safe: 'Safe',
      suggestive: 'Suggestive',
      erotica: 'Erotica',
      pornographic: 'Pornographic',
    };

    return mappings[rating] || 'Unknown';
  }

  private mapToPublication(status?: MangaStatus): Publication {
    if (!status) return 'Unknown';

    const mappings: Record<MangaStatus, Publication> = {
      ongoing: 'Ongoing',
      completed: 'Completed',
      cancelled: 'Cancelled',
      hiatus: 'Hiatus',
    };

    return mappings[status] || 'Unknown';
  }
}
