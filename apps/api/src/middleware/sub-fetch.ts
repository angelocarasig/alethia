import type { MiddlewareHandler, Context } from 'hono';
import { Logger } from '@repo/logger';

interface SubFetchOptions {
  /**
   * Toggle using a structured Logger or plain console.
   * If true (default), uses @repo/logger.
   */
  useLogger?: boolean;

  /**
   * Max length of request body snippet to log for POST requests.
   * Defaults to 500 characters.
   */
  maxBodyLength?: number;
}

/**
 * Middleware that intercepts and logs all outbound `fetch()` calls
 * made during the lifetime of a request handler.
 *
 * The middleware temporarily patches `globalThis.fetch` for each request,
 * allowing you to see sub-HTTP requests (e.g., calls to external APIs)
 * triggered within Hono routes.
 *
 * Example log:
 *   [subfetch:POST] https://api.example.com/users -> 200 (142.4ms)
 *   body: {"name":"Jane Doe",...}
 *
 * If `useLogger` is true, the middleware will create a scoped Logger
 * with request context; otherwise it falls back to `console`.
 *
 * Safe for Cloudflare Workers, Bun, and Node runtimes.
 */
export const subFetch = (options: SubFetchOptions = {}): MiddlewareHandler => {
  const { useLogger = true, maxBodyLength = 999999999 } = options;

  return async (c: Context, next) => {
    // Create scoped logger or fallback console
    const logger = useLogger
      ? new Logger({ enableSentry: true }).withContext({
          method: c.req.method,
          path: c.req.path,
        })
      : console;

    const requestId = crypto.randomUUID();
    const originalFetch = globalThis.fetch;

    // Scoped fetch patch
    globalThis.fetch = async (...args) => {
      const [url, opts] = args;
      const method = (opts?.method || 'GET').toUpperCase();
      const start = performance.now();

      // Capture and truncate POST body safely
      let bodySnippet: string | undefined;
      if (method === 'POST' && opts?.body) {
        try {
          if (typeof opts.body === 'string') {
            bodySnippet = opts.body.slice(0, maxBodyLength);
          } else if (opts.body instanceof Blob) {
            const text = await opts.body.text();
            bodySnippet = text.slice(0, maxBodyLength);
          } else if (opts.body instanceof FormData) {
            const entries = Array.from(opts.body.entries());
            bodySnippet = JSON.stringify(entries).slice(0, maxBodyLength);
          } else if (opts.body instanceof URLSearchParams) {
            bodySnippet = opts.body.toString().slice(0, maxBodyLength);
          } else {
            bodySnippet = '[unloggable body type]';
          }
        } catch {
          bodySnippet = '[error reading body]';
        }
      }

      try {
        const res = await originalFetch(...args);
        const duration = (performance.now() - start).toFixed(1);

        logger.info?.(
          `[subfetch:${method}] ${url} -> ${res.status} (${duration}ms)`,
          {
            request_id: requestId,
            method,
            url: String(url),
            status: res.status,
            duration_ms: Number(duration),
            ...(bodySnippet ? { body_snippet: bodySnippet } : {}),
          },
        );

        // Optionally also output body snippet to console/log separately
        if (bodySnippet) {
          logger.debug?.(`[subfetch body:${method}] ${url}`, {
            snippet: bodySnippet,
          });
        }

        return res;
      } catch (err) {
        logger.error?.(`[subfetch:${method}] ${url} -> ERROR`, err as Error, {
          request_id: requestId,
          method,
          url: String(url),
          ...(bodySnippet ? { body_snippet: bodySnippet } : {}),
        });
        throw err;
      }
    };

    try {
      await next();
    } finally {
      // Restore global fetch to prevent leaks across requests
      globalThis.fetch = originalFetch;
    }
  };
};
