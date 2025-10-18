import { Hono } from 'hono';
import { cache } from 'hono/cache';
import { loggingMiddleware } from './middleware/logging';
import * as Sentry from '@sentry/cloudflare';
import host from './routes/host';
import sources from './routes/sources';
import type { Bindings } from './types';
import { HTTPException } from 'hono/http-exception';

export const createApp = () => {
  const app = new Hono<{ Bindings: Bindings }>();

  // onerror hook to report unhandled exceptions
  app.onError((err, c) => {
    Sentry.captureException(err);

    if (err instanceof HTTPException) {
      return err.getResponse();
    }

    return c.json({ error: 'internal server error' }, 500);
  });

  // global context middleware
  app.use('*', (c, next) => {
    // set tags for all requests
    Sentry.setTag('route', c.req.path);
    Sentry.setTag('method', c.req.method);

    // set user context from ip
    const cfConnectingIP = c.req.header('cf-connecting-ip');
    if (cfConnectingIP) {
      Sentry.setUser({ ip_address: cfConnectingIP });
    }

    return next();
  });

  app.use('*', loggingMiddleware());

  // 5min cache
  app.use(
    '*',
    cache({
      cacheName: 'alethia-api',
      cacheControl: 'max-age=300', // 5 minutes
    }),
  );

  app.route('/', host);
  app.route('/', sources);

  // debug route for testing
  app.get('/debug-sentry', async () => {
    await Sentry.startSpan(
      {
        op: 'test',
        name: 'debug sentry test',
      },
      async () => {
        await new Promise((resolve) => setTimeout(resolve, 100));
        throw new Error('sentry test error!');
      },
    );
  });

  return app;
};
