import * as Sentry from '@sentry/cloudflare';
import { createApp } from './app';
import type { Bindings } from './types';

const app = createApp();

export default Sentry.withSentry(
  (env: Bindings) => ({
    dsn: env.SENTRY_DSN,
    release: env.CF_VERSION_METADATA?.id,
    tracesSampleRate: 1.0,
    environment: env.ENVIRONMENT || 'production',
  }),
  app,
);
