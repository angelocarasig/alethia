import { Source } from '@repo/contracts';
import type { MangaStatus, ContentRating } from './types';

export const config: Source = {
  name: 'MangaDex',
  slug: 'mangadex',
  icon: 'mangadex',
  languages: ['en'],
  nsfw: false,
  url: 'https://mangadex.org',
  referer: 'https://mangadex.org',
  auth: {
    type: 'none',
    required: false,
  },
  search: {
    // must update any fields inside of the source mappings if changed here
    sort: [
      'title',
      'year',
      'createdAt',
      'updatedAt',
      'relevance',
      'popularity',
      'rating',
    ],
    filters: [
      'year',
      'includeTag',
      'excludeTag',
      'status',
      'originalLanguage',
      'translatedLanguage',
      'contentRating',
    ],
  },
} as const;

export const API_BASE_URL = 'https://api.mangadex.org' as const;
export const CDN_BASE_URL = 'https://uploads.mangadex.org' as const;

export const ENDPOINTS = {
  manga: `${API_BASE_URL}/manga`,
  chapter: `${API_BASE_URL}/chapter`,
  author: `${API_BASE_URL}/author`,
  cover: `${API_BASE_URL}/cover`,
  tag: `${API_BASE_URL}/manga/tag`,
  statistics: `${API_BASE_URL}/statistics/manga`,
  feed: (id: string) => `${API_BASE_URL}/manga/${id}/feed`,
  aggregate: (id: string) => `${API_BASE_URL}/manga/${id}/aggregate`,
  at_home: (id: string) => `${API_BASE_URL}/at-home/server/${id}`,
} as const;

export const CDN_ENDPOINTS = {
  covers: `${CDN_BASE_URL}/covers`,
  data: `${CDN_BASE_URL}/data`,
  dataSaver: `${CDN_BASE_URL}/data-saver`,
} as const;

export const REQUEST_CONFIG = {
  userAgent:
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
  timeout: 30000, // 30 seconds
  retryAttempts: 3,
  retryDelay: 1000, // 1 second
} as const;

export const IMAGE_QUALITY = {
  cover: {
    thumb: 256,
    medium: 512,
    original: null, // use original size
  },
  page: {
    dataSaver: false,
    original: true,
  },
} as const;

// content filter defaults
export const CONTENT_FILTERS = {
  defaultContentRatings: ['safe', 'suggestive'] as ContentRating[],
  defaultStatuses: [
    'ongoing',
    'completed',
    'hiatus',
    'cancelled',
  ] as MangaStatus[],
  defaultLanguages: ['en'] as const,
} as const;

export const API_URL = API_BASE_URL;
export const USER_AGENT = REQUEST_CONFIG.userAgent;
