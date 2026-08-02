// ============================================================================
// ExamForge AI — Enterprise Logger
// ============================================================================
// Structured logging that replaces console.* throughout the codebase.
// - In development: logs to console with color-coded levels
// - In production: logs structured JSON for observability platforms
// - Never logs sensitive data (passwords, tokens, secrets)
// ============================================================================

type LogLevel = 'debug' | 'info' | 'warn' | 'error'

interface LogEntry {
  level: LogLevel
  message: string
  timestamp: string
  context?: Record<string, unknown>
  error?: {
    name: string
    message: string
    stack?: string
  }
}

// Sensitive field names that should never be logged
const SENSITIVE_FIELDS = new Set([
  'password', 'token', 'secret', 'authorization', 'cookie',
  'api_key', 'apikey', 'access_token', 'refresh_token',
  'credit_card', 'card_number', 'cvv', 'pin',
])

function sanitizeContext(context: Record<string, unknown>): Record<string, unknown> {
  const sanitized: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(context)) {
    if (SENSITIVE_FIELDS.has(key.toLowerCase())) {
      sanitized[key] = '[REDACTED]'
    } else {
      sanitized[key] = value
    }
  }
  return sanitized
}

function formatLogEntry(entry: LogEntry): string {
  if (process.env.NODE_ENV === 'production') {
    return JSON.stringify(entry)
  }
  const colors: Record<LogLevel, string> = {
    debug: '\x1b[36m', // cyan
    info: '\x1b[32m',  // green
    warn: '\x1b[33m',  // yellow
    error: '\x1b[31m', // red
  }
  const reset = '\x1b[0m'
  const level = entry.level.toUpperCase().padEnd(5)
  const time = entry.timestamp
  const context = entry.context ? ` ${JSON.stringify(entry.context)}` : ''
  const error = entry.error ? ` | ${entry.error.message}` : ''
  return `${colors[entry.level]}[${level}]${reset} ${time} ${entry.message}${context}${error}`
}

function createLogEntry(
  level: LogLevel,
  message: string,
  context?: Record<string, unknown>,
  error?: Error
): LogEntry {
  return {
    level,
    message,
    timestamp: new Date().toISOString(),
    context: context ? sanitizeContext(context) : undefined,
    error: error ? { name: error.name, message: error.message, stack: error.stack } : undefined,
  }
}

// ──────────────────────────────────────────────────────────────
// Logger API
// ──────────────────────────────────────────────────────────────

export const logger = {
  debug(message: string, context?: Record<string, unknown>) {
    if (process.env.NODE_ENV === 'development') {
      const entry = createLogEntry('debug', message, context)
      console.log(formatLogEntry(entry))
    }
  },

  info(message: string, context?: Record<string, unknown>) {
    const entry = createLogEntry('info', message, context)
    console.info(formatLogEntry(entry))
  },

  warn(message: string, context?: Record<string, unknown>) {
    const entry = createLogEntry('warn', message, context)
    console.warn(formatLogEntry(entry))
  },

  error(message: string, error?: Error | unknown, context?: Record<string, unknown>) {
    const err = error instanceof Error ? error : error ? new Error(String(error)) : undefined
    const entry = createLogEntry('error', message, context, err)
    console.error(formatLogEntry(entry))
  },

  /** Log a security-related event */
  security(message: string, context?: Record<string, unknown>) {
    const entry = createLogEntry('warn', `[SECURITY] ${message}`, context)
    console.warn(formatLogEntry(entry))
  },

  /** Log an auth-related event */
  auth(message: string, context?: Record<string, unknown>) {
    const entry = createLogEntry('info', `[AUTH] ${message}`, context)
    console.info(formatLogEntry(entry))
  },

  /** Log a data access event */
  dataAccess(message: string, context?: Record<string, unknown>) {
    if (process.env.NODE_ENV === 'development') {
      const entry = createLogEntry('debug', `[DATA] ${message}`, context)
      console.log(formatLogEntry(entry))
    }
  },
}
