'use client';

import { AuthProvider, useAuth } from '@/components/auth-provider';
import { Sidebar } from '@/components/sidebar';

function DashboardContent({ children }: { children: React.ReactNode }) {
  const { loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-6 h-6 border-2 border-[var(--accent)] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen">
      <Sidebar />
      <main className="lg:ml-[260px] min-h-screen">
        <div className="p-6 lg:p-8 max-w-[1400px]">{children}</div>
      </main>
    </div>
  );
}

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AuthProvider>
      <DashboardContent>{children}</DashboardContent>
    </AuthProvider>
  );
}
