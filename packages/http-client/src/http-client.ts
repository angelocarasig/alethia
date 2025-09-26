import { HttpError } from './http-error';
import { HttpClient, HttpResponse, RequestOptions } from './types';
import {
  DEFAULT_REQUEST_OPTIONS,
  DEFAULT_USER_AGENT,
  RETRY_CONFIG,
} from './config';

export class HTTPClient implements HttpClient {
  private baseConfig: RequestOptions;

  constructor(config?: RequestOptions) {
    this.baseConfig = {
      ...DEFAULT_REQUEST_OPTIONS,
      ...config,
      headers: {
        ...DEFAULT_REQUEST_OPTIONS.headers,
        'User-Agent': DEFAULT_USER_AGENT,
        ...config?.headers,
      },
    };
  }

  async get<T = unknown>(
    url: string,
    options?: RequestOptions,
  ): Promise<HttpResponse<T>> {
    return this.request<T>('GET', url, undefined, options);
  }

  async post<T = unknown>(
    url: string,
    body?: unknown,
    options?: RequestOptions,
  ): Promise<HttpResponse<T>> {
    return this.request<T>('POST', url, body, options);
  }

  private async request<T>(
    method: string,
    url: string,
    body?: unknown,
    options?: RequestOptions,
  ): Promise<HttpResponse<T>> {
    const config = {
      ...this.baseConfig,
      ...options,
      headers: {
        ...this.baseConfig.headers,
        ...options?.headers,
      },
    };

    if (config.params) {
      const params =
        config.params instanceof URLSearchParams
          ? config.params
          : new URLSearchParams(config.params);
      url = `${url}?${params.toString()}`;
    }

    // retry logic
    let lastError: HttpError | Error | undefined;

    for (let attempt = 0; attempt <= RETRY_CONFIG.maxRetries; attempt++) {
      try {
        // create abort controller for timeout
        const controller = new AbortController();
        const timeoutId = config.timeout
          ? setTimeout(() => controller.abort(), config.timeout)
          : undefined;

        const response = await fetch(url, {
          method,
          headers: config.headers,
          body: body ? JSON.stringify(body) : undefined,
          signal: config.signal || controller.signal,
        });

        if (timeoutId) clearTimeout(timeoutId);

        const data = await response.json().catch(() => null);

        if (!response.ok) {
          const error = new HttpError(
            `HTTP ${response.status}: ${response.statusText}`,
            response.status,
            response.statusText,
            data,
          );

          // check if retryable
          if (
            attempt < RETRY_CONFIG.maxRetries &&
            RETRY_CONFIG.retryableStatuses.includes(response.status)
          ) {
            lastError = error;
            await this.delay(
              RETRY_CONFIG.retryDelay *
                Math.pow(RETRY_CONFIG.retryMultiplier, attempt),
            );
            continue;
          }

          throw error;
        }

        return {
          data: data as T,
          status: response.status,
          statusText: response.statusText,
          headers: response.headers,
        };
      } catch (error) {
        // handle timeout/network errors
        if (error instanceof Error && error.name === 'AbortError') {
          lastError = new HttpError('Request timeout', 408, 'Request Timeout');
        } else {
          lastError = error as Error;
        }

        if (attempt < RETRY_CONFIG.maxRetries) {
          await this.delay(
            RETRY_CONFIG.retryDelay *
              Math.pow(RETRY_CONFIG.retryMultiplier, attempt),
          );
          continue;
        }
      }
    }

    throw lastError || new Error('Request failed');
  }

  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
