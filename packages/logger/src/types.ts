export type LogLevel = 'debug' | 'info' | 'warn' | 'error' | 'fatal';

export interface LogContext {
  [key: string]: unknown;
}

export interface PerformanceThresholds {
  [operation: string]: number;
}

export interface LoggerConfig {
  source?: string;
  enableSentry?: boolean;
  performanceThresholds?: PerformanceThresholds;
}

export interface ILogger {
  debug(message: string, context?: LogContext): void;
  info(message: string, context?: LogContext): void;
  warn(message: string, context?: LogContext): void;
  error(message: string, error?: Error, context?: LogContext): void;
  fatal(message: string, error?: Error, context?: LogContext): void;

  withContext(context: LogContext): ILogger;
  startTimer(operation: string): () => void;
}
