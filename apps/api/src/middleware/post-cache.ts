import { MiddlewareHandler } from 'hono';
import type { Context } from 'hono';

interface PostCacheOptions {
  cacheName?: string;
  cacheControl?: string;
}

/**
 * creates a sha-256 hash of the request body for use as cache key
 * based on cloudflare's official post caching example:
 * https://developers.cloudflare.com/workers/examples/cache-post-request/
 */
async function hashBody(body: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(body);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

/**
 * middleware for caching POST requests based on body hash
 *
 * uses cloudflare's cache api to store responses with a synthetic cache key
 * that includes the hashed request body. this allows identical POST requests
 * to be served from cache without hitting the origin.
 *
 * implementation follows cloudflare's recommended pattern:
 * https://developers.cloudflare.com/workers/examples/cache-post-request/
 *
 * the cache api requires GET requests, so we convert the POST to a synthetic
 * GET with the body hash appended to the URL as documented here:
 * https://developers.cloudflare.com/workers/runtime-apis/cache/
 *
 * @param options - cache configuration options
 * @param options.cacheName - name of the cache (default: 'alethia-api-post')
 * @param options.cacheControl - cache-control header value (default: 'max-age=300')
 */
export const postCacheMiddleware = (
  options: PostCacheOptions = {},
): MiddlewareHandler => {
  const { cacheControl = 'max-age=300' } = options;

  return async (c: Context, next) => {
    // only handle POST requests
    if (c.req.method !== 'POST') {
      return next();
    }

    try {
      // access cloudflare's cache api
      // @ts-expect-error - caches is a cloudflare workers global
      const cache = caches.default;

      // read and hash the request body
      const body = await c.req.text();
      const bodyHash = await hashBody(body);

      // create cache key by appending hash to url
      const url = new URL(c.req.url);
      url.pathname = `${url.pathname}/${bodyHash}`;

      // create a synthetic GET request for cache lookup
      // cache api only supports GET/HEAD methods
      const cacheKey = new Request(url.toString(), {
        method: 'GET',
        headers: c.req.raw.headers,
      });

      // try to get cached response
      let response = await cache.match(cacheKey);

      if (response) {
        console.log(`[post-cache] cache hit for: ${c.req.url}`);
        return response;
      }

      console.log(
        `[post-cache] cache miss for: ${c.req.url}, fetching and caching`,
      );

      // reconstruct request with body for handler
      // need to create new request since we consumed the body
      const requestWithBody = new Request(c.req.url, {
        method: 'POST',
        headers: c.req.raw.headers,
        body: body,
      });

      // override the request in context
      c.req.raw = requestWithBody;

      // process the request through remaining middleware/handler
      await next();

      // clone response for caching
      const responseToCache = c.res.clone();

      // only cache successful responses
      if (responseToCache.status >= 200 && responseToCache.status < 300) {
        // create new response with cache headers
        const cachedResponse = new Response(responseToCache.body, {
          status: responseToCache.status,
          statusText: responseToCache.statusText,
          headers: responseToCache.headers,
        });

        // add cache control header
        cachedResponse.headers.set('Cache-Control', cacheControl);

        // store in cache asynchronously
        c.executionCtx.waitUntil(cache.put(cacheKey, cachedResponse));
      }
    } catch (error) {
      console.error('[post-cache] error:', error);
      // on error, just process request normally
      return next();
    }
  };
};
