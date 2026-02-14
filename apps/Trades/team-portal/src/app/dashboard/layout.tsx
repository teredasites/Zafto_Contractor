'use client';

import { AuthProvider } from '@/components/auth-provider';
import { Sidebar } from '@/components/sidebar';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <div className="min-h-screen bg-main">
        <Sidebar />
        <main className="lg:pl-12">
          <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6 pt-14 lg:pt-6">
            {children}
          </div>
        </main>
      </div>
    </AuthProvider>
  );
}
