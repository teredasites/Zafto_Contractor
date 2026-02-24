'use client';

import * as Sentry from '@sentry/nextjs';
import { useEffect } from 'react';

export default function DashboardError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <div className="flex min-h-[50vh] flex-col items-center justify-center gap-4 p-8">
      <div className="w-full max-w-md rounded-lg border border-red-200 bg-red-50 p-6 text-center dark:border-red-900 dark:bg-red-950">
        <h2 className="text-lg font-semibold text-red-800 dark:text-red-200">Dashboard Error</h2>
        <p className="mt-2 text-sm text-red-600 dark:text-red-400">
          {error.message || 'Something went wrong loading this section.'}
        </p>
        <div className="mt-4 flex justify-center gap-3">
          <button
            onClick={reset}
            className="rounded-md bg-surface px-4 py-2 text-sm font-medium text-main hover:bg-surface-hover"
          >
            Try again
          </button>
          <a
            href="/dashboard"
            className="rounded-md border border-main bg-secondary px-4 py-2 text-sm font-medium text-muted hover:bg-surface-hover"
          >
            Back to Dashboard
          </a>
        </div>
      </div>
    </div>
  );
}
