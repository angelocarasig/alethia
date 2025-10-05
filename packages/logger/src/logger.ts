import * as Sentry from '@sentry/cloudflare';
import type { ILogger, LogLevel, LogContext, LoggerConfig } from './types';

export class Logger implements ILogger {
  private context: LogContext = {};
  private config: LoggerConfig;

  constructor(config: LoggerConfig = {}) {
    this.config = config;
  }

  withContext(context: LogContext): ILogger {
    const newLogger = new Logger(this.config);
    newLogger.context = { ...this.context, ...context };
    return newLogger;
  }

  debug(message: string, context?: LogContext): void {
    this.log('debug', message, context);
  }

  info(message: string, context?: LogContext): void {
    this.log('info', message, context);
  }

  warn(message: string, context?: LogContext): void {
    this.log('warn', message, context);
  }

  error(message: string, error?: Error, context?: LogContext): void {
    const fullContext = { ...this.context, ...context };

    console.error(message, fullContext);

    if (this.config.enableSentry && error) {
      Sentry.captureException(error, {
        level: 'error',
        tags: this.extractTags(fullContext),
        contexts: {
          details: fullContext,
        },
      });
    }
  }

  fatal(message: string, error?: Error, context?: LogContext): void {
    const fullContext = { ...this.context, ...context };

    console.error(`[FATAL] ${message}`, fullContext);

    if (this.config.enableSentry && error) {
      Sentry.captureException(error, {
        level: 'fatal',
        tags: this.extractTags(fullContext),
        contexts: {
          details: fullContext,
        },
      });
    }
  }

  startTimer(operation: string): () => void {
    const startTime = Date.now();
    const threshold = this.config.performanceThresholds?.[operation];

    return () => {
      const duration = Date.now() - startTime;
      const context = {
        ...this.context,
        operation,
        duration_ms: duration,
        threshold_ms: threshold,
      };

      if (threshold && duration > threshold) {
        this.warn(`slow operation: ${operation}`, context);
      } else {
        this.info(operation, context);
      }
    };
  }

  private log(level: LogLevel, message: string, context?: LogContext): void {
    const fullContext = { ...this.context, ...context };
    const logMessage = `[${level.toUpperCase()}] ${message}`;

    // console output
    switch (level) {
      case 'debug':
      case 'info':
        console.log(logMessage, fullContext);
        break;
      case 'warn':
        console.warn(logMessage, fullContext);
        break;
      case 'error':
      case 'fatal':
        console.error(logMessage, fullContext);
        break;
    }

    // sentry breadcrumb for info/debug
    if (this.config.enableSentry && (level === 'info' || level === 'debug')) {
      Sentry.addBreadcrumb({
        category: this.config.source || 'general',
        message,
        level,
        data: fullContext,
      });
    }

    // sentry message for warnings
    if (this.config.enableSentry && level === 'warn') {
      Sentry.captureMessage(message, {
        level: 'warning',
        tags: this.extractTags(fullContext),
        contexts: {
          details: fullContext,
        },
      });
    }
  }

  private extractTags(context: LogContext): Record<string, string> {
    const tags: Record<string, string> = {};

    if (this.config.source) {
      tags.source = this.config.source;
    }

    // extract common tags from context
    const tagFields = ['operation', 'source', 'environment'];
    for (const field of tagFields) {
      if (context[field] && typeof context[field] === 'string') {
        tags[field] = context[field] as string;
      }
    }

    return tags;
  }
}
