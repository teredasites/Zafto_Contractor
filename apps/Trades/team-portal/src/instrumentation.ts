import * as Sentry from '@sentry/nextjs';

export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    Sentry.init({
      dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
      environment: process.env.NODE_ENV,
      tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.2 : 1.0,
      debug: false,
      beforeSend(event) {
        if (!process.env.NEXT_PUBLIC_SENTRY_DSN) return null;
        return event;
      },
    });
  }

  if (process.env.NEXT_RUNTIME === 'edge') {
    Sentry.init({
      dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
      environment: process.env.NODE_ENV,
      tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.2 : 1.0,
      debug: false,
      beforeSend(event) {
        if (!process.env.NEXT_PUBLIC_SENTRY_DSN) return null;
        return event;
      },
    });
  }
}

export const onRequestError = Sentry.captureRequestError;
