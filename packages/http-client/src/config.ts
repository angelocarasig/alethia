import { RequestOptions } from './types';

export const DEFAULT_TIMEOUT = 30000; // 30 seconds

export const DEFAULT_HEADERS = {
  'Content-Type': 'application/json',
  Accept: 'application/json',
} as const;

export const DEFAULT_USER_AGENT =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36';

export const DEFAULT_REQUEST_OPTIONS: RequestOptions = {
  headers: DEFAULT_HEADERS,
  timeout: DEFAULT_TIMEOUT,
};

export const RETRY_CONFIG = {
  maxRetries: 3,
  retryDelay: 1000, // 1 second
  retryMultiplier: 2, // exponential backoff
  retryableStatuses: [408, 429, 500, 502, 503, 504] as readonly number[],
} as const;

export const RATE_LIMIT_CONFIG = {
  maxRequestsPerSecond: 10,
  maxConcurrentRequests: 5,
} as const;
