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
  MangadexEntry,
  MangadexCollectionResponseSchema,
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

  constructor(source: Source) {
    super(source);
  }

  protected async performAuthentication(_: AuthRequest): Promise<AuthResponse> {
    return {
      success: true,
      headers: {},
    };
  }

  protected buildParams(request: SearchRequest): URLSearchParams {
    const params = new URLSearchParams();

    // add search query if provided
    if (request.query) {
      params.append('title', request.query);
    }

    // calculate pagination offset
    const offset = (request.page - 1) * request.limit;
    params.append('limit', String(request.limit));
    params.append('offset', String(offset));

    // apply sort order unless using default relevance
    if (request.sort !== 'relevance') {
      const apiSortField =
        MangaDexSource.API_SORT_MAPPING[
          request.sort as keyof typeof MangaDexSource.API_SORT_MAPPING
        ];
      if (apiSortField) {
        params.append(`order[${apiSortField}]`, request.direction);
      }
    }

    // map and apply user filters to api parameters
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

    // apply default status filter if not specified
    if (!filters.status) {
      CONTENT_FILTERS.defaultStatuses.forEach((status) =>
        params.append('status[]', status),
      );
    }

    // include required relationships for response
    MangaDexSource.SEARCH_INCLUDES.forEach((include) =>
      params.append('includes[]', include),
    );

    return params;
  }

  protected async performSearch(
    params: URLSearchParams,
    headers?: Record<string, string>,
  ): Promise<SearchResponse> {
    // fetch and parse api response
    const response = await this.fetchFromApi(ENDPOINTS.manga, params, headers);
    const collection = MangadexCollectionResponseSchema.parse(
      await response.json(),
    );

    // extract pagination info from params
    const limit = Number(params.get('limit'));
    const offset = Number(params.get('offset'));
    const currentPage = Math.floor(offset / limit) + 1;

    // build search response with transformed entries
    return {
      results: collection.data.map((entry) => this.buildSearchEntry(entry)),
      total: collection.total,
      page: currentPage,
      more: offset + limit < collection.total,
    };
  }

  async getManga(
    slug: string,
    headers?: Record<string, string>,
  ): Promise<Manga> {
    // build url with required includes
    const url = new URL(`${ENDPOINTS.manga}/${slug}`);
    MangaDexSource.DETAIL_INCLUDES.forEach((include) =>
      url.searchParams.append('includes[]', include),
    );

    // fetch and validate response
    const response = await this.fetchFromApi(url.toString(), null, headers);
    const json = await response.json();

    if (json.result !== 'ok' || !json.data) {
      throw new Error('Invalid MangaDex API response structure');
    }

    const { id, attributes, relationships = [] } = json.data;

    // transform api data to domain model
    return MangaSchema.parse({
      slug: id,

      title: this.selectPreferredTitle(attributes.title),

      authors: relationships
        .filter((rel: any) => rel.type === 'author' && rel.attributes?.name)
        .map((rel: any) => rel.attributes.name),

      alternativeTitles: (attributes.altTitles || [])
        .flatMap((titleObject: LocalizedString) => Object.values(titleObject))
        .filter((title: string) => title.trim().length > 0),

      synopsis: this.selectPreferredDescription(attributes.description),

      createdAt: attributes.createdAt,

      updatedAt: attributes.updatedAt,

      classification: this.mapToClassification(attributes.contentRating),

      publication: this.mapToPublication(attributes.status),

      tags: (attributes.tags || [])
        .filter((tag: any) => tag.attributes?.name?.en)
        .map((tag: any) => tag.attributes.name.en),

      covers: relationships
        .filter(
          (rel: any) => rel.type === 'cover_art' && rel.attributes?.fileName,
        )
        .map(
          (rel: any) =>
            `${CDN_ENDPOINTS.covers}/${id}/${rel.attributes.fileName}`,
        ),

      url: `https://mangadex.org/title/${id}`,
    });
  }

  async getChapters(
    mangaSlug: string,
    headers?: Record<string, string>,
  ): Promise<Chapter[]> {
    const allChapters: Chapter[] = [];
    const limit = 100; // mangadex max is 100 per request
    let offset = 0;
    let hasMore = true;

    while (hasMore) {
      // build feed url with pagination and includes
      const url = new URL(`${ENDPOINTS.manga}/${mangaSlug}/feed`);
      url.searchParams.append('limit', String(limit));
      url.searchParams.append('offset', String(offset));
      url.searchParams.append('includes[]', 'scanlation_group');
      url.searchParams.append('order[chapter]', 'asc');
      url.searchParams.append('order[volume]', 'asc');
      url.searchParams.append('translatedLanguage[]', 'en');

      // fetch chapter batch
      const response = await this.fetchFromApi(url.toString(), null, headers);
      const json = await response.json();

      if (json.result !== 'ok') {
        throw new Error('Invalid MangaDex chapter feed response');
      }

      // handle empty data gracefully
      const chapters = json.data || [];

      // transform and add valid chapters to collection
      const validChapters = chapters
        .filter((chapter: any) => chapter.attributes?.pages > 0)
        .map((chapter: any) => this.buildChapter(chapter));

      allChapters.push(...validChapters);

      // check if there are more chapters to fetch
      hasMore = chapters.length === limit && json.total > offset + limit;
      offset += limit;

      // safety check to prevent infinite loops
      if (offset > 10000) {
        console.warn(`Stopping chapter fetch at ${offset} for safety`);
        break;
      }
    }

    return allChapters;
  }

  async getChapter(
    _: string, // doesn't use mangaSlug
    chapterSlug: string,
    headers?: Record<string, string>,
  ): Promise<string[]> {
    // fetch at-home server data which includes both the base URL and file lists
    const url = ENDPOINTS.at_home(chapterSlug);
    const response = await this.fetchFromApi(url, null, headers);
    const data = await response.json();

    if (data.result !== 'ok' || !data.baseUrl || !data.chapter) {
      throw new Error('Invalid MangaDex at-home response');
    }

    const { baseUrl, chapter } = data;
    const { hash, data: fileNames, dataSaver: dataSaverFileNames } = chapter;

    if (!hash || !fileNames || fileNames.length === 0) {
      throw new Error('Chapter has no available pages');
    }

    // determine which file list to use based on image quality settings
    const useDataSaver =
      IMAGE_QUALITY.page.dataSaver && dataSaverFileNames?.length > 0;
    const pagesToUse = useDataSaver ? dataSaverFileNames : fileNames;
    const quality = useDataSaver ? 'data-saver' : 'data';

    // build page urls
    const pageUrls = pagesToUse.map(
      (fileName: string) => `${baseUrl}/${quality}/${hash}/${fileName}`,
    );

    return pageUrls;
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

    const body = await response.text().catch(() => 'Unknown error');
    throw new Error(
      `MangaDex API error (${response.status}): ${response.statusText} - ${body}`,
    );
  }

  private buildSearchEntry(apiEntry: MangadexEntry): Entry {
    // find cover art relationship
    const coverArt = apiEntry.relationships?.find(
      (rel): rel is CoverArtRelationship => rel.type === 'cover_art',
    );

    // build cover url if available
    let coverUrl = '';
    if (coverArt?.attributes?.fileName) {
      const size = IMAGE_QUALITY.cover.medium;
      coverUrl = `${CDN_ENDPOINTS.covers}/${apiEntry.id}/${coverArt.attributes.fileName}.${size}.jpg`;
    }

    return EntrySchema.parse({
      slug: apiEntry.id,
      title: this.selectPreferredTitle(apiEntry.attributes.title),
      cover: coverUrl,
    });
  }

  private selectPreferredTitle(titles: LocalizedString): string {
    // check for titles in preferred language order
    for (const language of MangaDexSource.PREFERRED_TITLE_LANGUAGES) {
      if (titles[language]) {
        return titles[language];
      }
    }

    // fallback to first available title
    const firstAvailable = Object.values(titles)[0];
    if (!firstAvailable) {
      throw new Error('No title found for manga entry');
    }

    return firstAvailable;
  }

  private selectPreferredDescription(descriptions?: LocalizedString): string {
    if (!descriptions) return '';
    return descriptions.en || Object.values(descriptions)[0] || '';
  }

  private mapToClassification(rating: ContentRating): Classification {
    const mappings: Record<ContentRating, Classification> = {
      safe: 'Safe',
      suggestive: 'Suggestive',
      erotica: 'Erotica',
      pornographic: 'Pornographic',
    };

    return mappings[rating] || 'Unknown';
  }

  private mapToPublication(status: MangaStatus): Publication {
    const mappings: Record<MangaStatus, Publication> = {
      ongoing: 'Ongoing',
      completed: 'Completed',
      cancelled: 'Cancelled',
      hiatus: 'Hiatus',
    };

    return mappings[status] || 'Unknown';
  }

  private buildChapter(apiChapter: any): Chapter {
    const { id, attributes, relationships = [] } = apiChapter;

    // extract scanlation group name
    const scanlationGroup = relationships.find(
      (rel: any) => rel.type === 'scanlation_group',
    );
    const scanlator = scanlationGroup?.attributes?.name || 'Unknown Scanlator';

    // parse chapter number with fallback
    const chapterNum = attributes.chapter || '0';
    const parsedNumber = parseFloat(chapterNum) || 0;

    // build chapter title
    const title = attributes.title?.trim();
    const chapterTitle = title
      ? `Chapter ${chapterNum}: ${title}`
      : `Chapter ${chapterNum}`;

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
}
