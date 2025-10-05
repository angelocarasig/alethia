import { MiddlewareHandler } from 'hono';
import { Logger } from '@repo/logger';

export const loggingMiddleware = (): MiddlewareHandler => {
  return async (c, next) => {
    const logger = new Logger({
      enableSentry: true,
    }).withContext({
      method: c.req.method,
      path: c.req.path,
    });

    const startTime = Date.now();

    try {
      await next();

      const duration = Date.now() - startTime;
      logger.info('request completed', {
        status: c.res.status,
        duration_ms: duration,
      });
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error('request failed', error as Error, {
        status: c.res.status || 500,
        duration_ms: duration,
      });
      throw error;
    }
  };
};
