import {
  Source,
  Adapter,
  AuthRequest,
  AuthResponse,
  SearchRequest,
  SearchResponse,
  MappingFor,
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
  ENDPOINTS,
  CDN_ENDPOINTS,
  IMAGE_QUALITY,
  CONTENT_FILTERS,
  SUPPORTED_FILTERS,
  SUPPORTED_SORTS,
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
  MangadexEntityResponse,
  ChapterFeedResponse,
  AtHomeServerResponse,
  CoverCollectionResponseSchema,
  CoverCollectionResponse,
} from './types';

export default class MangaDexSource extends Adapter<
  typeof SUPPORTED_SORTS,
  typeof SUPPORTED_FILTERS,
  MappingFor<typeof SUPPORTED_SORTS, string>,
  MappingFor<typeof SUPPORTED_FILTERS, string>
> {
  protected readonly sortMap = {
    title: 'title',
    year: 'year',
    createdAt: 'createdAt',
    updatedAt: 'latestUploadedChapter',
    popularity: 'followedCount',
    rating: 'rating',
    relevance: 'relevance',
  } as const satisfies MappingFor<typeof SUPPORTED_SORTS, string>;

  protected readonly filterMap = {
    year: 'year',
    includeTag: 'includedTags[]',
    excludeTag: 'excludedTags[]',
    status: 'status[]',
    originalLanguage: 'originalLanguage[]',
    translatedLanguage: 'availableTranslatedLanguage[]',
    contentRating: 'contentRating[]',
  } as const satisfies MappingFor<typeof SUPPORTED_FILTERS, string>;

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

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
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
        this.sortMap[request.sort as keyof typeof this.sortMap];
      if (apiSortField) {
        params.append(`order[${apiSortField}]`, request.direction);
      }
    }

    const filters = request.filters || {};
    Object.entries(filters).forEach(([key, value]) => {
      const apiParam = this.filterMap[key as keyof typeof this.filterMap];

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
    const url = `${ENDPOINTS.manga}?${params.toString()}`;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
        Accept: 'application/json',
        ...headers,
      },
    });

    if (!response.ok) {
      console.error(
        `[mangadex] search failed with status ${response.status}:`,
        response.statusText,
      );
      throw new Error(`http error! status: ${response.status}`);
    }

    const data = await response.json();
    console.log('[mangadex] search response received');

    const collection = MangadexCollectionResponseSchema.parse(data);

    const limit = Number(params.get('limit'));
    const offset = Number(params.get('offset'));

    return {
      results: collection.data.map((entry) => this.buildSearchEntry(entry)),
      page: Math.floor(offset / limit) + 1,
      more: offset + limit < collection.total,
    };
  }

  async getManga(
    slug: string,
    headers?: Record<string, string>,
  ): Promise<Manga> {
    const params = new URLSearchParams();
    MangaDexSource.DETAIL_INCLUDES.forEach((include) =>
      params.append('includes[]', include),
    );

    const response = await this.httpClient.get<MangadexEntityResponse>(
      `${ENDPOINTS.manga}/${slug}`,
      { params, headers },
    );
    const entityResponse = MangadexEntityResponseSchema.parse(response.data);
    const { id, attributes, relationships = [] } = entityResponse.data;

    const authors = relationships.filter(
      (rel): rel is AuthorRelationship => rel.type === 'author',
    );

    const artists = relationships.filter(
      (rel): rel is ArtistRelationship => rel.type === 'artist',
    );

    // fetch ALL covers from the cover endpoint
    const coversResponse = await this.fetchAllCovers(id, headers);

    const authorNames = [
      ...new Set([
        ...authors.map((a) => a.attributes?.name).filter(Boolean),
        ...artists.map((a) => a.attributes?.name).filter(Boolean),
      ]),
    ];

    return MangaSchema.parse({
      slug: id,
      title: this.selectPreferredTitle(attributes.title),
      authors: authorNames,
      alternativeTitles:
        attributes.altTitles
          ?.flatMap((titleObject: LocalizedString) =>
            Object.values(titleObject),
          )
          .filter((title: string) => title.trim().length > 0) || [],
      synopsis: this.selectPreferredDescription(attributes.description),
      createdAt: attributes.createdAt,
      updatedAt: attributes.updatedAt,
      classification: this.mapToClassification(attributes.contentRating),
      publication: this.mapToPublication(attributes.status),
      tags:
        attributes.tags
          ?.filter((tag) => tag.attributes?.name?.en)
          .map((tag) => tag.attributes.name.en) || [],
      covers: coversResponse,
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
      const params = new URLSearchParams();
      params.append('limit', String(limit));
      params.append('offset', String(offset));
      params.append('order[chapter]', 'asc');
      params.append('order[volume]', 'asc');

      this.source.languages.forEach((lang) =>
        params.append('translatedLanguage[]', lang),
      );

      MangaDexSource.CHAPTER_INCLUDES.forEach((include) =>
        params.append('includes[]', include),
      );

      // include all ratings for chapters regardless of manga rating
      ['safe', 'suggestive', 'erotica', 'pornographic'].forEach((rating) =>
        params.append('contentRating[]', rating),
      );

      const response = await this.httpClient.get<ChapterFeedResponse>(
        ENDPOINTS.feed(mangaSlug),
        { params, headers },
      );
      const feedResponse = ChapterFeedResponseSchema.parse(
        response.data,
      ) as ChapterFeedResponse;

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
    _: string, // manga slug unused - chapters are fetched directly by id
    chapterSlug: string,
    headers?: Record<string, string>,
  ): Promise<string[]> {
    const response = await this.httpClient.get<AtHomeServerResponse>(
      ENDPOINTS.at_home(chapterSlug),
      { headers },
    );

    const atHomeResponse = AtHomeServerResponseSchema.parse(response.data);

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
      erotica: 'Explicit',
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

  private async fetchAllCovers(
    mangaId: string,
    headers?: Record<string, string>,
  ): Promise<string[]> {
    const params = new URLSearchParams();
    params.append('manga[]', mangaId);
    params.append('limit', '100'); // max limit per request
    params.append('order[volume]', 'asc');

    const response = await this.httpClient.get<CoverCollectionResponse>(
      ENDPOINTS.cover,
      { params, headers },
    );

    const collection = CoverCollectionResponseSchema.parse(response.data);

    return collection.data
      .filter((cover) => cover.attributes.fileName)
      .map((cover) => {
        const fileName = cover.attributes.fileName;
        return `${CDN_ENDPOINTS.covers}/${mangaId}/${fileName}`;
      });
  }
}
