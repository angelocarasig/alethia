export interface RequestOptions {
  headers?: Record<string, string>;
  params?: URLSearchParams | Record<string, string>;
  timeout?: number;
  signal?: AbortSignal;
}

export interface HttpResponse<T = unknown> {
  data: T;
  status: number;
  statusText: string;
  headers: Headers;
}

export interface HttpClient {
  get<T = unknown>(
    url: string,
    options?: RequestOptions,
  ): Promise<HttpResponse<T>>;
  post<T = unknown>(
    url: string,
    body?: unknown,
    options?: RequestOptions,
  ): Promise<HttpResponse<T>>;
}
