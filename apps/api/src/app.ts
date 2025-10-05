import { Hono } from 'hono';
import { loggingMiddleware } from './middleware/logging';
import { errorHandler } from './middleware/error';
import host from './routes/host';
import sources from './routes/sources';
import type { Bindings } from './types';

export const createApp = () => {
  const app = new Hono<{ Bindings: Bindings }>();

  app.use('*', loggingMiddleware());
  app.onError(errorHandler);

  app.route('/', host);
  app.route('/', sources);

  return app;
};
