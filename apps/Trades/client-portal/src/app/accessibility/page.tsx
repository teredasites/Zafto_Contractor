'use client';

import { ArrowLeft } from 'lucide-react';
import Link from 'next/link';

export default function AccessibilityPage() {
  return (
    <main className="min-h-screen bg-white py-12 px-4 sm:px-6">
      <div className="max-w-2xl mx-auto">
        <Link
          href="/"
          className="inline-flex items-center gap-2 text-sm text-zinc-500 hover:text-zinc-900 transition-colors mb-8"
        >
          <ArrowLeft size={16} />
          Back
        </Link>

        <h1 className="text-2xl font-bold text-zinc-900 mb-2">Accessibility Statement</h1>
        <p className="text-sm text-zinc-500 mb-8">
          Last updated: {new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}
        </p>

        <div className="space-y-6 text-sm text-zinc-700 leading-relaxed">
          <section>
            <h2 className="text-lg font-semibold text-zinc-900 mb-3">Our Commitment</h2>
            <p>
              Zafto is committed to ensuring digital accessibility for people with disabilities.
              We are continually improving the user experience for everyone and applying the
              relevant accessibility standards to guarantee we provide equal access to all users.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-zinc-900 mb-3">Standards</h2>
            <p>
              We design and develop our products to conform to the Web Content Accessibility
              Guidelines (WCAG) 2.2 Level AA standards. These guidelines explain how to make web
              content more accessible to people with a wide range of disabilities.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-zinc-900 mb-3">Measures We Take</h2>
            <ul className="list-disc pl-5 space-y-2 text-zinc-600">
              <li>Semantic HTML with proper landmark regions and heading hierarchy</li>
              <li>Keyboard navigation support throughout the application</li>
              <li>Screen reader compatibility with ARIA labels and live regions</li>
              <li>Sufficient color contrast ratios (4.5:1 for normal text, 3:1 for large text)</li>
              <li>Color-independent status indicators</li>
              <li>Reduced motion support for users with vestibular disorders</li>
              <li>Responsive design that supports text scaling up to 200%</li>
              <li>Focus indicators on all interactive elements</li>
              <li>Skip navigation links for keyboard users</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-zinc-900 mb-3">Feedback</h2>
            <p>
              If you experience any accessibility barriers or have suggestions for improvement,
              please contact us:
            </p>
            <ul className="list-none space-y-2 text-zinc-600 mt-3">
              <li>
                Email:{' '}
                <a
                  href="mailto:support@zafto.app"
                  className="text-emerald-600 hover:underline"
                >
                  support@zafto.app
                </a>
              </li>
            </ul>
            <p className="mt-3 text-zinc-500">
              We aim to respond to accessibility feedback within 2 business days.
            </p>
          </section>
        </div>

        <div className="mt-12 pt-6 border-t border-zinc-200">
          <p className="text-xs text-zinc-400 text-center">
            &copy; {new Date().getFullYear()} Tereda Software LLC. All rights reserved.
          </p>
        </div>
      </div>
    </main>
  );
}
