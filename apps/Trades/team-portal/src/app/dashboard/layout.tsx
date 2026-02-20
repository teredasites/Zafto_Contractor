'use client';

import { AuthProvider } from '@/components/auth-provider';
import { Sidebar } from '@/components/sidebar';
import { AxeDevTools } from '@/components/axe-dev-tools';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <AxeDevTools />
      <div className="min-h-screen bg-main">
        {/* Skip navigation */}
        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:z-[100] focus:px-4 focus:py-2 focus:bg-[var(--accent)] focus:text-white focus:rounded-lg focus:text-sm focus:font-medium focus:outline-none"
        >
          Skip to main content
        </a>
        <Sidebar />
        <main id="main-content" className="lg:pl-12" aria-label="Page content">
          <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6 pt-14 lg:pt-6">
            {children}
          </div>
        </main>
      </div>
    </AuthProvider>
  );
}
