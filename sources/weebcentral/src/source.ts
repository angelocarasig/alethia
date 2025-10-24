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
  Manga,
  MangaSchema,
  Chapter,
  EntrySchema,
  Entry,
  Publication,
  Classification,
  ChapterSchema,
} from '@repo/schema';

import * as cheerio from 'cheerio';
import { SUPPORTED_FILTERS, SUPPORTED_SORTS } from './config';

export default class WeebCentralSource extends Adapter<
  typeof SUPPORTED_SORTS,
  typeof SUPPORTED_FILTERS,
  MappingFor<typeof SUPPORTED_SORTS, string>,
  MappingFor<typeof SUPPORTED_FILTERS, string>
> {
  protected readonly sortMap = {
    title: 'Alphabet',
    popularity: 'Popularity',
    follows: 'Subscribers',
    createdAt: 'Recently Added',
    updatedAt: 'Latest Updates',
    relevance: 'Best Match',
  } as const satisfies MappingFor<typeof SUPPORTED_SORTS, string>;

  protected readonly filterMap = {
    includeTag: 'included_tag',
    status: 'status',
  } as const satisfies MappingFor<typeof SUPPORTED_FILTERS, string>;

  // precompiled regexes to reduce per-call allocations
  private static readonly RE_SERIES_SLUG = /\/series\/([^/]+)/;
  private static readonly RE_CHAPTER_SLUG = /\/chapters\/([^/]+)/;
  private static readonly RE_CHAPTER_NUM = /Chapter\s+([\d.]+)/i;

  private static readonly API_DEFAULTS = {
    official: 'Any',
    anime: 'Any',
    adult: 'Any',
    display_mode: 'Full Display',
  } as const;

  private static readonly ENDPOINTS = {
    search: 'https://weebcentral.com/search/data',
    series: (slug: string) => `https://weebcentral.com/series/${slug}`,
    chapterList: (slug: string) =>
      `https://weebcentral.com/series/${slug}/full-chapter-list`,
    chapter: (seriesSlug: string) =>
      `https://weebcentral.com/chapters/${seriesSlug}/images?is_prev=False&current_page=1&reading_style=long_strip`,
  } as const;

  constructor(source: Source) {
    super(source);
  }

  protected async performAuthentication(
    _credentials: AuthRequest,
  ): Promise<AuthResponse> {
    void _credentials;
    return {
      success: true,
      headers: {},
    };
  }

  protected buildParams(request: SearchRequest): URLSearchParams {
    const params = new URLSearchParams();

    params.append('author', '');

    if (request.query) {
      params.append('text', request.query);
    }

    const limit = Math.min(request.limit, 100);
    const offset = Math.max((request.page - 1) * limit, 0);
    params.append('limit', String(limit));
    params.append('offset', String(offset));

    const sortValue =
      this.sortMap[request.sort as keyof typeof this.sortMap] ||
      this.sortMap.relevance;
    params.append('sort', sortValue);
    params.append(
      'order',
      request.direction === 'asc' ? 'Ascending' : 'Descending',
    );

    Object.entries(WeebCentralSource.API_DEFAULTS).forEach(([key, value]) => {
      params.append(key, value);
    });

    const filters = request.filters || {};
    Object.entries(filters).forEach(([key, value]) => {
      const apiParam = this.filterMap[key as keyof typeof this.filterMap];

      if (!apiParam) return;

      const values = Array.isArray(value) ? value : [value];
      values.forEach((v) => params.append(apiParam, String(v)));
    });

    return params;
  }

  protected async performSearch(
    params: URLSearchParams,
    headers?: Record<string, string>,
  ): Promise<SearchResponse> {
    const url = `${WeebCentralSource.ENDPOINTS.search}?${params.toString()}`;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        ...headers,
        Accept: 'text/html',
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const html = await response.text();
    const $ = cheerio.load(html);
    const entries: Entry[] = [];

    const cards = $('article.bg-base-300.flex.gap-4.p-4').toArray();
    for (const el of cards) {
      const $el = $(el);

      const link = $el.find('a[href*="/series/"]').first();
      const href = link.attr('href');
      if (!href) continue;

      const m = href.match(WeebCentralSource.RE_SERIES_SLUG);
      if (!m) continue;
      const slug = m[1]!;

      const titleEl = $el
        .find('.text-ellipsis.truncate.text-white.text-center.text-lg.z-20')
        .first();
      const title = titleEl.text().trim();
      if (!title) continue;

      const picture = $el.find('picture').first();
      const cover =
        picture.find('source[media="(min-width: 768px)"]').attr('srcset') ||
        picture.find('source').first().attr('srcset') ||
        picture.find('img').attr('src') ||
        null;

      entries.push(
        EntrySchema.parse({
          slug,
          title,
          cover,
        }),
      );
    }

    const limit = Number(params.get('limit') || 32);
    const offset = Number(params.get('offset') || 0);
    const currentPage = Math.floor(offset / limit) + 1;
    // cheaper than a DOM query for a single text occurrence
    const hasMore = html.includes('View More Results');

    return {
      results: entries,
      page: currentPage,
      more: hasMore,
    };
  }

  async getManga(
    slug: string,
    headers?: Record<string, string>,
  ): Promise<Manga> {
    const url = WeebCentralSource.ENDPOINTS.series(slug);

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        ...headers,
        Accept: 'text/html',
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const html = await response.text();
    const $ = cheerio.load(html);

    const title = $('h1').first().text().trim();

    // grab the two lists once
    const lists = $('ul.flex.flex-col.gap-4');
    const metadataList = lists.eq(0);
    const descriptionList = lists.eq(1);

    const authors: string[] = [];
    const tags: string[] = [];
    let statusText = '';
    let year = '';
    let adultContent = '';
    let alternativeTitles: string[] = [];
    let synopsis = '';

    // single pass over metadata li elements
    metadataList.children('li').each((_, li) => {
      const $li = $(li);
      const label = $li.find('strong').first().text().trim().replace(/:$/, '');
      const key = label.toLowerCase();
      if (key.startsWith('author')) {
        $li.find('a').each((__, a) => {
          authors.push($(a).text().trim());
        });
      } else if (key.startsWith('tags')) {
        $li.find('a').each((__, a) => {
          tags.push($(a).text().trim());
        });
      } else if (key.startsWith('status')) {
        statusText = $li.find('a').first().text().trim();
      } else if (key.startsWith('released')) {
        year = $li.find('span').first().text().trim();
      } else if (key.startsWith('adult content')) {
        adultContent = $li.find('a').first().text().trim();
      }
    });

    // single pass over description li elements
    descriptionList.children('li').each((_, li) => {
      const $li = $(li);
      const label = $li.find('strong').first().text().trim();
      const key = label.toLowerCase();
      if (key.includes('associated name')) {
        alternativeTitles = $li
          .find('ul.list-disc li')
          .map((__, el) => $(el).text().trim())
          .get()
          .filter((t) => t && t.toLowerCase() !== title.toLowerCase());
      } else if (key.includes('description')) {
        synopsis = $li.find('p').text().trim();
      }
    });

    const coverSection = $('section.flex.items-center.justify-center picture');
    const coverUrl =
      coverSection.find('source').first().attr('srcset') ||
      coverSection.find('img').attr('src');
    const covers = coverUrl ? [coverUrl] : [];

    const chapterListTime = $('#chapter-list time').first().attr('datetime');
    const updatedAt = chapterListTime
      ? chapterListTime.split('.')[0] + 'Z'
      : new Date().toISOString().split('.')[0] + 'Z';

    return MangaSchema.parse({
      slug,
      title,
      authors,
      alternativeTitles,
      synopsis,
      createdAt: year
        ? `${year}-01-01T00:00:00Z`
        : new Date().toISOString().split('.')[0] + 'Z',
      updatedAt,
      classification: this.mapToClassification(adultContent === 'Yes'),
      publication: this.mapToPublication(statusText),
      tags,
      covers,
      url,
    });
  }

  private mapToPublication(status: string): Publication {
    const normalized = status.toLowerCase();
    if (normalized === 'ongoing') return 'Ongoing';
    if (normalized === 'complete' || normalized === 'completed')
      return 'Completed';
    if (normalized === 'cancelled') return 'Cancelled';
    if (normalized === 'hiatus') return 'Hiatus';
    return 'Unknown';
  }

  private mapToClassification(isAdult: boolean): Classification {
    return isAdult ? 'Pornographic' : 'Safe';
  }

  async getChapters(
    mangaSlug: string,
    headers?: Record<string, string>,
  ): Promise<Chapter[]> {
    const url = WeebCentralSource.ENDPOINTS.chapterList(mangaSlug);

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        ...headers,
        Accept: 'text/html',
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const html = await response.text();
    const $ = cheerio.load(html);
    const chapters: Chapter[] = [];

    const chapterRows = $('#chapter-list div.flex.items-center').toArray();
    for (const row of chapterRows) {
      const $row = $(row);
      const link = $row.find('a[href*="/chapters/"]').first();
      const href = link.attr('href');
      if (!href) continue;

      const m = href.match(WeebCentralSource.RE_CHAPTER_SLUG);
      if (!m) continue;
      const slug = m[1]!;

      const chapterText = link.find('span').first().text().trim();
      const n = chapterText.match(WeebCentralSource.RE_CHAPTER_NUM);
      const number = n ? parseFloat(n[1]!) : 0;

      const datetime = link.find('time').attr('datetime');
      const date = datetime
        ? datetime.split('.')[0] + 'Z'
        : new Date().toISOString().split('.')[0] + 'Z';

      chapters.push(
        ChapterSchema.parse({
          slug,
          title: number ? `Chapter ${number}` : chapterText || undefined,
          number,
          scanlator: 'WeebCentral',
          language: 'en',
          url: href,
          date,
        }),
      );
    }

    return chapters;
  }

  async getChapter(
    _: string,
    chapterSlug: string,
    headers?: Record<string, string>,
  ): Promise<string[]> {
    const response = await fetch(
      WeebCentralSource.ENDPOINTS.chapter(chapterSlug),
      {
        method: 'GET',
        headers: {
          ...headers,
          Accept: 'text/html',
        },
      },
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const $ = cheerio.load(await response.text());

    return $('section img[src]')
      .map((_, el) => $(el).attr('src')!)
      .get();
  }
}
