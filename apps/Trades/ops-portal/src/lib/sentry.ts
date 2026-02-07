interface SentryUser {
  id: string;
  email?: string;
  role?: string;
}

export function setSentryUser(user: SentryUser): void {
  if (!process.env.NEXT_PUBLIC_SENTRY_DSN) return;

  try {
    // Sentry SDK integration point — will be wired when Sentry is configured
    console.debug('[Sentry] Set user:', user.id);
  } catch {
    // Graceful no-op
  }
}

export function clearSentryUser(): void {
  if (!process.env.NEXT_PUBLIC_SENTRY_DSN) return;

  try {
    console.debug('[Sentry] Cleared user');
  } catch {
    // Graceful no-op
  }
}

export function captureException(error: unknown, context?: Record<string, unknown>): void {
  if (!process.env.NEXT_PUBLIC_SENTRY_DSN) return;

  try {
    console.error('[Sentry] Captured exception:', error, context);
  } catch {
    // Graceful no-op
  }
}
