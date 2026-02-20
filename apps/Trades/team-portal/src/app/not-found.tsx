import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 p-8">
      <div className="text-center">
        <p className="text-6xl font-bold text-zinc-300 dark:text-zinc-700">404</p>
        <h2 className="mt-4 text-xl font-semibold text-zinc-900 dark:text-zinc-100">Page not found</h2>
        <p className="mt-2 text-sm text-zinc-500">The page you&apos;re looking for doesn&apos;t exist or has been moved.</p>
        <Link
          href="/dashboard"
          className="mt-6 inline-block rounded-md bg-zinc-900 px-4 py-2 text-sm font-medium text-white hover:bg-zinc-800 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
        >
          Back to Dashboard
        </Link>
      </div>
    </div>
  );
}
