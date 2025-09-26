import {
  Adapter,
  AuthRequest,
  AuthResponse,
  SearchRequest,
  SearchResponse,
  Source,
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

export default class WeebCentralSource extends Adapter {
  private static readonly API_SORT_MAPPING = {
    title: 'Alphabet',
    popularity: 'Popularity',
    follows: 'Subscribers',
    createdAt: 'Recently Added',
    updatedAt: 'Latest Updates',
    relevance: 'Best Match',
  } as const;

  private static readonly API_FILTER_MAPPING = {
    includeTag: 'included_tag',
    status: 'status',
  } as const;

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

  protected async performAuthentication(_: AuthRequest): Promise<AuthResponse> {
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
      WeebCentralSource.API_SORT_MAPPING[
        request.sort as keyof typeof WeebCentralSource.API_SORT_MAPPING
      ] || WeebCentralSource.API_SORT_MAPPING.relevance;
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
      const apiParam =
        WeebCentralSource.API_FILTER_MAPPING[
          key as keyof typeof WeebCentralSource.API_FILTER_MAPPING
        ];

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

    $('article.bg-base-300.flex.gap-4.p-4').each((_, element) => {
      const $element = $(element);

      const link = $element.find('a[href*="/series/"]').first();
      const href = link.attr('href');
      if (!href) return;

      const slugMatch = href.match(/\/series\/([^\/]+)/);
      if (!slugMatch) return;
      const slug = slugMatch[1];

      const title = $element
        .find('.text-ellipsis.truncate.text-white.text-center.text-lg.z-20')
        .first()
        .text()
        .trim();

      if (!title) return;

      const picture = $element.find('picture').first();
      let cover: string | null = null;

      picture.find('source').each((_, source) => {
        const srcset = $(source).attr('srcset');
        const media = $(source).attr('media');

        if (srcset && media === '(min-width: 768px)') {
          cover = srcset;
          return false;
        }
      });

      if (!cover) {
        cover =
          picture.find('source').first().attr('srcset') ||
          picture.find('img').attr('src') ||
          null;
      }

      if (slug && title) {
        entries.push(
          EntrySchema.parse({
            slug,
            title,
            cover,
          }),
        );
      }
    });

    const limit = Number(params.get('limit') || 32);
    const offset = Number(params.get('offset') || 0);
    const currentPage = Math.floor(offset / limit) + 1;
    const hasMore = $('span:contains("View More Results")').length > 0;

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
    const metadataList = $('ul.flex.flex-col.gap-4').first();
    const descriptionList = $('ul.flex.flex-col.gap-4').eq(1);

    const authors: string[] = [];
    metadataList.find('li:contains("Author(s):") a').each((_, el) => {
      authors.push($(el).text().trim());
    });

    const tags: string[] = [];
    metadataList.find('li:contains("Tags(s):") a').each((_, el) => {
      tags.push($(el).text().trim());
    });

    const altTitlesSet = new Set<string>();
    descriptionList
      .find('li:has(strong:contains("Associated Name")) ul.list-disc li')
      .each((_, el) => {
        const altTitle = $(el).text().trim();
        if (altTitle && altTitle.toLowerCase() !== title.toLowerCase()) {
          altTitlesSet.add(altTitle);
        }
      });
    const alternativeTitles = Array.from(altTitlesSet);

    const statusText = metadataList
      .find('li:contains("Status:") a')
      .text()
      .trim();

    const year = metadataList
      .find('li:contains("Released:") span')
      .text()
      .trim();

    const adultContent = metadataList
      .find('li:contains("Adult Content:") a')
      .text()
      .trim();

    const synopsis = descriptionList
      .find('li:has(strong:contains("Description")) p')
      .text()
      .trim();

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

    $('div.flex.items-center').each((_, element) => {
      const $element = $(element);

      const link = $element.find('a[href*="/chapters/"]').first();
      const href = link.attr('href');
      if (!href) return;

      const slugMatch = href.match(/\/chapters\/([^\/]+)/);
      if (!slugMatch) return;
      const slug = slugMatch[1];

      // extract chapter text and parse number
      const chapterText = link
        .find('span:contains("Chapter")')
        .first()
        .text()
        .trim();
      const numberMatch = chapterText.match(/Chapter\s+([\d.]+)/i);
      const number = numberMatch ? parseFloat(numberMatch[1]!) : 0;

      // extract date and remove milliseconds
      const datetime = link.find('time').attr('datetime');
      const date = datetime
        ? datetime.split('.')[0] + 'Z'
        : new Date().toISOString().split('.')[0] + 'Z';

      chapters.push(
        ChapterSchema.parse({
          slug,
          title: `Chapter ${number}`,
          number,
          scanlator: 'WeebCentral',
          language: 'en',
          url: href,
          date,
        }),
      );
    });

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
    console.log($.html());

    return $('section.flex-1.flex.flex-col.pb-4.cursor-pointer img')
      .map((_, el) => $(el).attr('src')!)
      .get();
  }
}
