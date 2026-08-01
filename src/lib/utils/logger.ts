// ============================================================================
// ExamForge AI — Logger Utility
// ============================================================================
// Structured logger with severity levels. Only logs in development mode
// to prevent sensitive data leakage in production. Supports structured
// context objects for machine-parseable output.
// ============================================================================

type LogLevel = 'debug' | 'info' | 'warn' | 'error'

interface LogContext {
  [key: string]: unknown
}

interface LogEntry {
  timestamp: string
  level: LogLevel
  message: string
  context?: LogContext
}

// ──────────────────────────────────────────────────────────────
// Configuration
// ──────────────────────────────────────────────────────────────

const IS_DEV = process.env.NODE_ENV === 'development'

const LEVEL_PRIORITY: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
}

const MIN_LEVEL: LogLevel = (process.env.LOG_LEVEL as LogLevel) ?? 'debug'

// ──────────────────────────────────────────────────────────────
// Structured Log Formatter
// ──────────────────────────────────────────────────────────────

function formatLogEntry(entry: LogEntry): string {
  const { timestamp, level, message, context } = entry
  const prefix = `[${timestamp}] ${level.toUpperCase()}`

  if (context && Object.keys(context).length > 0) {
    return `${prefix}: ${message} ${JSON.stringify(context)}`
  }

  return `${prefix}: ${message}`
}

// ──────────────────────────────────────────────────────────────
// Logger Class
// ──────────────────────────────────────────────────────────────

class Logger {
  private module: string

  constructor(module: string = 'app') {
    this.module = module
  }

  /**
   * Create a child logger scoped to a specific module.
   *
   * @param module - Module name for log scoping
   * @returns A new Logger instance scoped to the module
   */
  child(module: string): Logger {
    return new Logger(`${this.module}:${module}`)
  }

  /**
   * Log a debug-level message.
   * Only outputs in development mode.
   */
  debug(message: string, context?: LogContext): void {
    this.log('debug', message, context)
  }

  /**
   * Log an info-level message.
   * Only outputs in development mode.
   */
  info(message: string, context?: LogContext): void {
    this.log('info', message, context)
  }

  /**
   * Log a warning-level message.
   * Only outputs in development mode.
   */
  warn(message: string, context?: LogContext): void {
    this.log('warn', message, context)
  }

  /**
   * Log an error-level message.
   * Outputs in all environments (production errors should be visible).
   */
  error(message: string, context?: LogContext): void {
    this.log('error', message, context, true)
  }

  private log(
    level: LogLevel,
    message: string,
    context?: LogContext,
    forceLog: boolean = false
  ): void {
    // Skip if below minimum level
    if (LEVEL_PRIORITY[level] < LEVEL_PRIORITY[MIN_LEVEL]) return

    // Skip non-error logs in production unless forced
    if (!IS_DEV && !forceLog && level !== 'error') return

    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      message: `[${this.module}] ${message}`,
      context: context && Object.keys(context).length > 0 ? context : undefined,
    }

    const formatted = formatLogEntry(entry)

    switch (level) {
      case 'debug':
        console.debug(formatted)
        break
      case 'info':
        console.info(formatted)
        break
      case 'warn':
        console.warn(formatted)
        break
      case 'error':
        console.error(formatted)
        break
    }
  }
}

// ──────────────────────────────────────────────────────────────
// Singleton Export
// ──────────────────────────────────────────────────────────────

export const logger = new Logger()

export { Logger }
export type { LogLevel, LogContext, LogEntry }
