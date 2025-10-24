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

import * as cheerio from 'cheerio';
import { type MangaParkStatus } from './types';
import { ENDPOINTS, SUPPORTED_FILTERS, SUPPORTED_SORTS } from './config';

export default class MangaParkSource extends Adapter<
  typeof SUPPORTED_SORTS,
  typeof SUPPORTED_FILTERS,
  MappingFor<typeof SUPPORTED_SORTS, string>,
  MappingFor<typeof SUPPORTED_FILTERS, string>
> {
  protected readonly sortMap = {
    rating: 'field_score',
    popularity: 'field_follows',
    chapters: 'field_chapter_count',
    updatedAt: 'field_uploaded',
    createdAt: 'field_created',
    title: 'field_name',
  } as const satisfies MappingFor<typeof SUPPORTED_SORTS, string>;

  protected readonly filterMap = {
    includeTag: 'genres',
    excludeTag: 'genres_exclude',
    status: 'status',
    originalLanguage: 'orig',
    minChapters: 'chapters',
  } as const satisfies MappingFor<typeof SUPPORTED_FILTERS, string>;

  constructor(source: Source) {
    super(source);
  }

  protected async performAuthentication(
    credentials: AuthRequest,
  ): Promise<AuthResponse> {
    const cookie = credentials.cookie;

    if (!cookie || typeof cookie !== 'string') {
      return {
        success: false,
        error: {
          code: 'MISSING_FIELDS',
          message: 'Cookie is required',
        },
      };
    }

    return {
      success: true,
      headers: {
        Cookie: cookie,
      },
    };
  }

  protected buildParams(request: SearchRequest): URLSearchParams {
    const params = new URLSearchParams();

    if (request.query) {
      params.append('word', request.query);
    }

    params.append('page', String(request.page));

    if (request.sort && request.sort !== 'relevance') {
      const sortValue = this.sortMap[request.sort as keyof typeof this.sortMap];
      if (sortValue) {
        params.append('sortby', sortValue);
      }
    }

    const filters = request.filters || {};
    Object.entries(filters).forEach(([key, value]) => {
      const apiParam = this.filterMap[key as keyof typeof this.filterMap];

      if (!apiParam) return;

      if (key === 'includeTag' || key === 'excludeTag') {
        const values = Array.isArray(value) ? value : [value];
        values.forEach((v) => params.append(apiParam, String(v)));
      } else if (key === 'status') {
        const values = Array.isArray(value) ? value : [value];
        const statusMap: Record<string, string> = {
          Ongoing: 'ongoing',
          Completed: 'completed',
          Hiatus: 'hiatus',
          Cancelled: 'cancelled',
        };
        values.forEach((v) => {
          const mappedStatus = statusMap[String(v)];
          if (mappedStatus) params.append(apiParam, mappedStatus);
        });
      } else {
        params.append(apiParam, String(value));
      }
    });

    return params;
  }

  protected async performSearch(
    params: URLSearchParams,
    headers?: Record<string, string>,
  ): Promise<SearchResponse> {
    const url = `${ENDPOINTS.search}?${params.toString()}`;

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

    $('div.flex.border-b.border-b-base-200.pb-5').each((_, element) => {
      const $element = $(element);

      const link = $element.find('a[href*="/title/"]').first();
      const href = link.attr('href');
      if (!href) return;

      const slugMatch = href.match(/\/title\/([^/]+)/);
      if (!slugMatch) return;
      const slug = slugMatch[1];

      const title = $element.find('h3.font-bold a').first().text().trim();

      if (!title) return;

      const imgElement = $element.find('img').first();
      const coverSrc = imgElement.attr('src');
      const cover = coverSrc ? `https://mangapark.org${coverSrc}` : null;

      entries.push(
        EntrySchema.parse({
          slug,
          title,
          cover,
        }),
      );
    });

    const currentPage = Number(params.get('page') || 1);

    // check if there's a next page by looking for pagination links
    let hasMore = false;
    $('div.flex.items-center.flex-wrap a[href*="page="]').each((_, element) => {
      const href = $(element).attr('href');
      if (href) {
        const pageMatch = href.match(/page=(\d+)/);
        if (pageMatch) {
          const pageNum = parseInt(pageMatch[1]!);
          if (pageNum > currentPage) {
            hasMore = true;
            return false; // break loop
          }
        }
      }
    });

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
    const url = ENDPOINTS.title(slug);

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

    const title = $('h3.font-bold a').first().text().trim();

    const altTitlesDiv = $('h3.font-bold')
      .first()
      .parent()
      .find('div.opacity-80')
      .first();
    const alternativeTitles: string[] = [];
    altTitlesDiv.find('span').each((_, el) => {
      const text = $(el).text().trim();
      if (text && text !== '/' && text.toLowerCase() !== title.toLowerCase()) {
        alternativeTitles.push(text);
      }
    });

    const authorsDiv = $('div.mt-2.opacity-80').first();
    const authors: string[] = [];
    authorsDiv.find('a').each((_, el) => {
      const authorText = $(el).text().trim();
      const cleanedAuthor = authorText.replace(/\(.*?\)/g, '').trim();
      if (cleanedAuthor) authors.push(cleanedAuthor);
    });

    const tags: string[] = [];
    const genresDiv = $('div.flex.items-center.flex-wrap').first();
    genresDiv.find('span.whitespace-nowrap').each((_, el) => {
      const tag = $(el).text().trim();
      if (tag && tag !== 'Genres:') tags.push(tag);
    });

    let statusText = '';
    $('div').each((_, el) => {
      const text = $(el).text();
      if (text.includes('Original Publication:')) {
        statusText = $(el).find('span.uppercase').first().text().trim();
        return false;
      }
    });

    // original language is not used in the output; skip parsing

    const synopsisParagraphs: string[] = [];
    const synopsisDiv = $('div.limit-html.prose').first();
    synopsisDiv.find('div.limit-html-p').each((_, el) => {
      const text = $(el).text().trim();
      if (text) synopsisParagraphs.push(text);
    });
    const synopsis = synopsisParagraphs.join('\n\n');

    const coverMeta = $('meta[property="og:image"]').attr('content');
    const covers = coverMeta ? [`https://mangapark.org${coverMeta}`] : [];

    const creationTimeText = $('time').last().text().trim();
    const createdAt = this.parseDate(creationTimeText);

    const updatedAt = new Date().toISOString().split('.')[0] + 'Z';

    return MangaSchema.parse({
      slug,
      title,
      authors,
      alternativeTitles,
      synopsis,
      createdAt,
      updatedAt,
      classification: this.mapToClassification(tags),
      publication: this.mapToPublication(statusText as MangaParkStatus),
      tags,
      covers,
      url,
    });
  }

  async getChapters(
    mangaSlug: string,
    headers?: Record<string, string>,
  ): Promise<Chapter[]> {
    const url = ENDPOINTS.title(mangaSlug);

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

    $('div[data-name="chapter-list"] div.px-2.py-2.flex').each((_, element) => {
      const $element = $(element);

      const link = $element.find('a[href*="/title/"]').first();
      const href = link.attr('href');
      if (!href) return;

      const slugMatch = href.match(/\/title\/[^/]+\/([^/]+)/);
      if (!slugMatch) return;
      const slug = slugMatch[1];

      const chapterText = link.text().trim();
      const subtitleText = $element
        .find('span.opacity-80')
        .first()
        .text()
        .trim();

      const numberMatch = chapterText.match(/Chapter\s+([\d.]+)/i);
      const number = numberMatch ? parseFloat(numberMatch[1]!) : 0;

      const title = subtitleText
        ? `${chapterText}${subtitleText}`
        : chapterText;

      let scanlator = 'MangaPark';
      const scanlatorLink = $element.find('a[href*="/u/"]').first();
      if (scanlatorLink.length > 0) {
        scanlator = scanlatorLink.find('span').text().trim() || 'MangaPark';
      }

      const timeElement = $element.find('time[data-time]').first();
      const timestamp = timeElement.attr('data-time');
      const date = timestamp
        ? new Date(parseInt(timestamp)).toISOString().split('.')[0] + 'Z'
        : new Date().toISOString().split('.')[0] + 'Z';

      chapters.push(
        ChapterSchema.parse({
          slug,
          title,
          number,
          scanlator,
          language: 'en',
          url: `https://mangapark.org${href}`,
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
    const url = `https://mangapark.org/title/${chapterSlug}`;

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

    const images: string[] = [];
    $('div#images div[data-name="image-item"] img').each((_, element) => {
      const src = $(element).attr('src');
      if (src) images.push(src);
    });

    return images;
  }

  private mapToClassification(tags: string[]): Classification {
    const nsfwTags = ['adult', 'mature', 'smut', 'ecchi', 'hentai'];
    const hasNsfw = tags.some((tag) => nsfwTags.includes(tag.toLowerCase()));

    return hasNsfw ? 'Pornographic' : 'Safe';
  }

  private mapToPublication(status: MangaParkStatus): Publication {
    const mappings: Record<MangaParkStatus, Publication> = {
      Ongoing: 'Ongoing',
      Completed: 'Completed',
      Cancelled: 'Cancelled',
      Hiatus: 'Hiatus',
    };

    return mappings[status] || 'Unknown';
  }

  private parseDate(dateStr: string): string {
    try {
      const date = new Date(dateStr);
      if (!isNaN(date.getTime())) {
        return date.toISOString().split('.')[0] + 'Z';
      }
    } catch {
      // fallback
    }
    return new Date().toISOString().split('.')[0] + 'Z';
  }
}
