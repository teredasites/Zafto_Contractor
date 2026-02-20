/**
 * Structured logging utility — INFRA-5
 *
 * Every Edge Function should use this instead of console.log.
 * Includes company_id, user_id, action, entity, timestamp in every log line.
 * JSON-structured for easy parsing by log aggregators.
 */

type LogLevel = 'debug' | 'info' | 'warn' | 'error'

interface LogContext {
  company_id?: string
  user_id?: string
  action?: string
  entity?: string
  entity_id?: string
  [key: string]: unknown
}

function log(level: LogLevel, message: string, context?: LogContext): void {
  const entry = {
    level,
    message,
    timestamp: new Date().toISOString(),
    service: 'edge-function',
    ...context,
  }

  switch (level) {
    case 'error':
      console.error(JSON.stringify(entry))
      break
    case 'warn':
      console.warn(JSON.stringify(entry))
      break
    case 'debug':
      console.debug(JSON.stringify(entry))
      break
    default:
      console.log(JSON.stringify(entry))
  }
}

export const logger = {
  debug: (message: string, context?: LogContext) => log('debug', message, context),
  info: (message: string, context?: LogContext) => log('info', message, context),
  warn: (message: string, context?: LogContext) => log('warn', message, context),
  error: (message: string, context?: LogContext) => log('error', message, context),
}
