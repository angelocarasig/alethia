import {
  Adapter,
  AuthRequest,
  AuthResponse,
  SearchRequest,
  SearchResponse,
  Source,
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

import { ENDPOINTS, SUPPORTED_FILTERS, SUPPORTED_SORTS } from './config';
import { GQL_QUERIES } from './types';

export default class MangaParkSource extends Adapter<
  typeof SUPPORTED_SORTS,
  typeof SUPPORTED_FILTERS,
  MappingFor<typeof SUPPORTED_SORTS, string>,
  MappingFor<typeof SUPPORTED_FILTERS, string>
> {
  protected readonly sortMap = {
    relevance: 'field_score',
    rating: 'field_score',
    popularity: 'field_follow',
    chapters: 'field_chapter',
    updatedAt: 'field_update',
    createdAt: 'field_create',
    title: 'field_name',
  } as const satisfies MappingFor<typeof SUPPORTED_SORTS, string>;

  protected readonly filterMap = {
    includeTag: 'incGenres',
    excludeTag: 'excGenres',
    status: 'siteStatus',
    originalLanguage: 'incOLangs',
    minChapters: 'chapCount',
  } as const satisfies MappingFor<typeof SUPPORTED_FILTERS, string>;

  private readonly statusMap: Record<string, string> = {
    Ongoing: 'ongoing',
    Completed: 'completed',
    Hiatus: 'hiatus',
    Cancelled: 'cancelled',
  };

  private readonly publicationMap: Record<string, Publication> = {
    ongoing: 'Ongoing',
    completed: 'Completed',
    cancelled: 'Cancelled',
    hiatus: 'Hiatus',
  };

  private readonly genreMap: Map<string, string>;

  constructor(source: Source) {
    super(source);

    this.genreMap = new Map(
      source.search.tags.map((tag) => [tag.slug, tag.name]),
    );
  }

  protected async performAuthentication(_: AuthRequest): Promise<AuthResponse> {
    return {
      success: true,
      headers: {},
    };
  }

  protected buildParams(request: SearchRequest): URLSearchParams {
    const params = new URLSearchParams({
      page: String(request.page),
      size: String(request.limit),
      word: request.query || '',
    });

    if (request.sort && request.sort !== 'relevance') {
      const sortValue = this.sortMap[request.sort as keyof typeof this.sortMap];
      if (sortValue) params.append('sortby', sortValue);
    }

    this.appendFilters(params, request.filters || {});

    if (!params.has('incTLangs')) {
      params.append('incTLangs', 'en');
    }

    return params;
  }

  protected async performSearch(
    params: URLSearchParams,
    headers?: Record<string, string>,
  ): Promise<SearchResponse> {
    const select = this.buildGraphQLSelect(params);

    const res = await fetch(ENDPOINTS.gql, {
      method: 'POST',
      headers: {
        ...headers,
        'content-type': 'application/json',
        accept: 'application/json',
        referrer: this.source.referer,
        origin: this.source.referer,
      },
      body: JSON.stringify({
        operationName: 'get_searchComic',
        query: GQL_QUERIES.SEARCH,
        variables: { select },
      }),
    });

    if (!res.ok) {
      throw new Error(`HTTP error! status: ${res.status}`);
    }

    const data = await res.json();
    const root = data?.data?.get_searchComic;

    return {
      results: this.parseEntries(root?.items ?? []),
      page: Number(root?.paging?.page ?? params.get('page') ?? 1),
      more: Boolean(root?.paging?.next),
    };
  }

  async getManga(
    slug: string,
    headers?: Record<string, string>,
  ): Promise<Manga> {
    const res = await fetch(ENDPOINTS.gql, {
      method: 'POST',
      headers: {
        ...headers,
        'content-type': 'application/json',
        accept: 'application/json',
        referrer: this.source.referer,
        origin: this.source.referer,
      },
      body: JSON.stringify({
        operationName: 'get_comic',
        query: GQL_QUERIES.MANGA,
        variables: { comicId: slug },
      }),
    });

    if (!res.ok) {
      throw new Error(`HTTP error! status: ${res.status}`);
    }

    const data = await res.json();
    const comicData = data?.data?.get_comicNode?.data;

    if (!comicData) {
      throw new Error(`Manga not found: ${slug}`);
    }

    return this.parseGraphQLManga(comicData, slug);
  }

  async getChapters(
    mangaSlug: string,
    headers?: Record<string, string>,
  ): Promise<Chapter[]> {
    const res = await fetch(ENDPOINTS.gql, {
      method: 'POST',
      headers: {
        ...headers,
        'content-type': 'application/json',
        accept: 'application/json',
        referrer: this.source.referer,
        origin: this.source.referer,
      },
      body: JSON.stringify({
        operationName: 'get_comicChapterList',
        query: GQL_QUERIES.CHAPTERS,
        variables: { comicId: mangaSlug },
      }),
    });

    if (!res.ok) {
      throw new Error(`HTTP error! status: ${res.status}`);
    }

    const data = await res.json();
    const chapterItems = data?.data?.get_comicChapterList ?? [];

    return chapterItems
      .map((item: any) => this.parseGraphQLChapter(item.data))
      .filter(Boolean);
  }

  async getChapter(
    _: string,
    chapterSlug: string,
    headers?: Record<string, string>,
  ): Promise<string[]> {
    const res = await fetch(ENDPOINTS.gql, {
      method: 'POST',
      headers: {
        ...headers,
        'content-type': 'application/json',
        accept: 'application/json',
        referrer: this.source.referer,
        origin: this.source.referer,
      },
      body: JSON.stringify({
        operationName: 'Get_chapterNode',
        query: GQL_QUERIES.CHAPTER,
        variables: { chapterId: chapterSlug },
      }),
    });

    if (!res.ok) {
      throw new Error(`HTTP error! status: ${res.status}`);
    }

    const data = await res.json();
    const urlList = data?.data?.get_chapterNode?.data?.imageFile?.urlList ?? [];

    return urlList.filter(Boolean);
  }

  private appendFilters(
    params: URLSearchParams,
    filters: Record<string, unknown>,
  ): void {
    for (const [key, value] of Object.entries(filters)) {
      const apiParam = this.filterMap[key as keyof typeof this.filterMap];
      if (!apiParam) continue;

      const values = Array.isArray(value) ? value : [value];

      if (
        apiParam === 'incGenres' ||
        apiParam === 'excGenres' ||
        apiParam === 'incOLangs'
      ) {
        values.forEach((v) => params.append(apiParam, String(v)));
        continue;
      }

      if (apiParam === 'siteStatus') {
        values.forEach((v) => {
          const mapped = this.statusMap[String(v)];
          if (mapped) params.append(apiParam, mapped);
        });
        continue;
      }

      if (apiParam === 'chapCount') {
        const n = Number(values[0]);
        if (!isNaN(n)) params.append(apiParam, String(n));
        continue;
      }

      params.append(apiParam, String(values[0]));
    }
  }

  private buildGraphQLSelect(params: URLSearchParams): Record<string, unknown> {
    const select: Record<string, unknown> = {};
    const arrays: Record<string, string[]> = {};

    params.forEach((value, key) => {
      if (['incGenres', 'excGenres', 'incOLangs', 'incTLangs'].includes(key)) {
        if (!arrays[key]) arrays[key] = [];
        arrays[key].push(value);
      } else if (['page', 'size', 'chapCount'].includes(key)) {
        select[key] = Number(value);
      } else if (['sortby', 'word', 'siteStatus'].includes(key)) {
        select[key] = value;
      }
    });

    return { ...select, ...arrays };
  }

  private parseEntries(items: unknown[]): Entry[] {
    const entries: Entry[] = [];

    for (const item of items) {
      const data = (item as any)?.data;
      if (!data) continue;

      const slug = String(data.id ?? '').trim();
      const title = String(data.name ?? '').trim();
      if (!slug || !title) continue;

      const rawCover = data.urlCoverOri || data.urlCover600 || '';

      const cover = rawCover
        ? rawCover.startsWith('http')
          ? rawCover
          : ENDPOINTS.cover(rawCover)
        : null;

      entries.push(EntrySchema.parse({ slug, title, cover }));
    }

    return entries;
  }

  private parseGraphQLManga(data: any, slug: string): Manga {
    const authors = Array.isArray(data.authors) ? data.authors : [];
    const artists = Array.isArray(data.artists) ? data.artists : [];
    const mergedAuthors = [...new Set([...authors, ...artists])];

    const genreSlugs = Array.isArray(data.genres) ? data.genres : [];
    const tags = genreSlugs
      .map((slug: string) => this.genreMap.get(slug) || slug)
      .filter(Boolean);

    const alternativeTitles = Array.isArray(data.altNames) ? data.altNames : [];

    const status = String(data.originalStatus || '').toLowerCase();
    const publication = this.publicationMap[status] || 'Unknown';

    const classification: Classification =
      data.sfw_result === true ? 'Safe' : 'Pornographic';

    const covers = data.urlCoverOri
      ? [
          data.urlCoverOri.startsWith('http')
            ? data.urlCoverOri
            : ENDPOINTS.cover(data.urlCoverOri),
        ]
      : [];

    const createdAt = this.parseDate(data.dateCreate);
    const updatedAt = data.max_chapterNode?.data?.dateCreate
      ? this.parseDate(data.max_chapterNode.data.dateCreate)
      : this.formatDate(new Date());

    const url = ENDPOINTS.title(slug);

    return MangaSchema.parse({
      slug,
      title: data.name || 'Unknown Title',
      authors: mergedAuthors,
      alternativeTitles,
      synopsis: data.summary || 'No Description.',
      createdAt,
      updatedAt,
      classification,
      publication,
      tags,
      covers,
      url,
    });
  }

  private parseGraphQLChapter(data: any): Chapter | null {
    if (!data?.id) return null;

    const slug = String(data.id);
    const title = data.dname || 'No Title';
    const number = Number(data.serial) || 0;

    const scanlator = data.userNode?.data?.name || 'MangaPark';

    const language = 'en';

    const url = data.urlPath
      ? `https://mangapark.org${data.urlPath}`
      : `https://mangapark.org/chapter/${slug}`;

    let timestamp = data.dateCreate;
    if (timestamp && timestamp < 1e12) {
      timestamp *= 1000;
    }
    const date = timestamp
      ? this.formatDate(new Date(timestamp))
      : this.formatDate(new Date());

    return ChapterSchema.parse({
      slug,
      title,
      number,
      scanlator,
      language,
      url,
      date,
    });
  }

  private parseDate(dateStr: string | number): string {
    try {
      let timestamp = typeof dateStr === 'string' ? parseInt(dateStr) : dateStr;

      if (timestamp < 1e12) {
        timestamp *= 1000;
      }

      const date = new Date(timestamp);
      if (!isNaN(date.getTime())) {
        return this.formatDate(date);
      }
    } catch {
      // fallback to current date
    }
    return this.formatDate(new Date());
  }

  private formatDate(date: Date): string {
    return date.toISOString().split('.')[0] + 'Z';
  }
}
