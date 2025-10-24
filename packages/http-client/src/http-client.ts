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

    const startTime = Date.now();
    let lastError: HttpError | Error | undefined;

    console.log(`[http-client] ${method} ${url}`);
    console.log('[http-client] request config:', { config });

    for (let attempt = 0; attempt <= RETRY_CONFIG.maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          console.log(
            `[http-client] retry attempt ${attempt} for ${method} ${url}`,
          );
        }

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

        const duration = Date.now() - startTime;
        const data = await response.json().catch(() => null);

        if (!response.ok) {
          console.error(
            `[http-client] ${method} ${url} failed with status ${response.status} (${duration}ms)`,
          );

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
            const retryDelay =
              RETRY_CONFIG.retryDelay *
              Math.pow(RETRY_CONFIG.retryMultiplier, attempt);

            console.log(
              `[http-client] status ${response.status} is retryable, waiting ${retryDelay}ms before retry`,
            );

            lastError = error;
            await this.delay(retryDelay);
            continue;
          }

          throw error;
        }

        console.log(
          `[http-client] ${method} ${url} completed with status ${response.status} (${duration}ms)`,
        );

        return {
          data: data as T,
          status: response.status,
          statusText: response.statusText,
          headers: response.headers,
        };
      } catch (error) {
        const duration = Date.now() - startTime;

        // handle timeout/network errors
        if (error instanceof Error && error.name === 'AbortError') {
          console.error(
            `[http-client] ${method} ${url} timed out after ${duration}ms`,
          );
          lastError = new HttpError('request timeout', 408, 'request timeout');
        } else if (error instanceof HttpError) {
          // already logged above
          lastError = error;
        } else {
          console.error(
            `[http-client] ${method} ${url} failed with error:`,
            error,
          );
          lastError = error as Error;
        }

        if (attempt < RETRY_CONFIG.maxRetries) {
          const retryDelay =
            RETRY_CONFIG.retryDelay *
            Math.pow(RETRY_CONFIG.retryMultiplier, attempt);

          console.log(
            `[http-client] retrying after ${retryDelay}ms (attempt ${attempt + 1}/${RETRY_CONFIG.maxRetries})`,
          );

          await this.delay(retryDelay);
          continue;
        }

        console.error(
          `[http-client] ${method} ${url} failed after ${RETRY_CONFIG.maxRetries + 1} attempts (${duration}ms)`,
        );
      }
    }

    throw lastError || new Error('request failed');
  }

  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
