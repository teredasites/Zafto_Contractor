'use client';

import { ArrowLeft } from 'lucide-react';
import Link from 'next/link';

export default function AccessibilityPage() {
  return (
    <main
      className="min-h-screen py-12 px-4 sm:px-6"
      style={{ background: 'var(--bg-secondary)' }}
    >
      <div className="max-w-2xl mx-auto">
        <Link
          href="/"
          className="inline-flex items-center gap-2 text-sm text-muted hover:text-main transition-colors mb-8"
        >
          <ArrowLeft size={16} />
          Back
        </Link>

        <h1 className="text-2xl font-bold text-main mb-2">Accessibility Statement</h1>
        <p className="text-sm text-muted mb-8">
          Last updated: {new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}
        </p>

        <div className="space-y-6 text-sm text-main leading-relaxed">
          <section>
            <h2 className="text-lg font-semibold mb-3">Our Commitment</h2>
            <p>
              Zafto is committed to ensuring digital accessibility for people with disabilities.
              We are continually improving the user experience for everyone and applying the
              relevant accessibility standards to guarantee we provide equal access to all users.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold mb-3">Standards</h2>
            <p>
              We design and develop our products to conform to the Web Content Accessibility
              Guidelines (WCAG) 2.2 Level AA standards.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold mb-3">Feedback</h2>
            <p>
              If you experience any accessibility barriers, please contact us at{' '}
              <a
                href="mailto:support@zafto.app"
                className="text-accent hover:underline"
              >
                support@zafto.app
              </a>
            </p>
          </section>
        </div>

        <div className="mt-12 pt-6 border-t border-[var(--border-light)]">
          <p className="text-xs text-muted text-center">
            &copy; {new Date().getFullYear()} Zafto. All rights reserved.
          </p>
        </div>
      </div>
    </main>
  );
}
