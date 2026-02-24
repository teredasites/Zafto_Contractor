import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 p-8">
      <div className="text-center">
        <p className="text-6xl font-bold text-muted">404</p>
        <h2 className="mt-4 text-xl font-semibold text-main">Page not found</h2>
        <p className="mt-2 text-sm text-muted">The page you&apos;re looking for doesn&apos;t exist or has been moved.</p>
        <Link
          href="/dashboard"
          className="mt-6 inline-block rounded-md bg-surface px-4 py-2 text-sm font-medium text-main hover:bg-surface-hover"
        >
          Back to Dashboard
        </Link>
      </div>
    </div>
  );
}
