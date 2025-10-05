import { ErrorHandler } from 'hono';
import * as Sentry from '@sentry/cloudflare';

export const errorHandler: ErrorHandler = (err, c) => {
  Sentry.captureException(err);
  return c.json({ error: 'Internal Server Error' }, 500);
};
