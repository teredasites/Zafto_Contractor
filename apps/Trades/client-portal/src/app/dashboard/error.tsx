'use client';

import * as Sentry from '@sentry/nextjs';
import { useEffect } from 'react';

export default function DashboardError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <div className="flex min-h-[50vh] flex-col items-center justify-center gap-4 p-8">
      <div className="w-full max-w-md rounded-lg border border-red-200 bg-red-50 p-6 text-center">
        <h2 className="text-lg font-semibold text-red-800">Dashboard Error</h2>
        <p className="mt-2 text-sm text-red-600">
          {error.message || 'Something went wrong loading this section.'}
        </p>
        <div className="mt-4 flex justify-center gap-3">
          <button
            onClick={reset}
            className="rounded-md bg-zinc-900 px-4 py-2 text-sm font-medium text-white hover:bg-zinc-800"
          >
            Try again
          </button>
          <a
            href="/"
            className="rounded-md border border-zinc-300 bg-white px-4 py-2 text-sm font-medium text-zinc-700 hover:bg-zinc-50"
          >
            Back to Home
          </a>
        </div>
      </div>
    </div>
  );
}
