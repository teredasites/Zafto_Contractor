'use client';

import { useState, useEffect } from 'react';
import { AuthProvider, useAuth } from '@/components/auth-provider';
import { Sidebar } from '@/components/sidebar';
import { getSupabase } from '@/lib/supabase';
import { AxeDevTools } from '@/components/axe-dev-tools';

function ImpersonationBanner() {
  const [impersonation, setImpersonation] = useState<{
    companyId: string;
    companyName: string;
    sessionId: string;
    startedAt: string;
  } | null>(null);
  const [ending, setEnding] = useState(false);

  useEffect(() => {
    const stored = localStorage.getItem('zafto_impersonation');
    if (stored) {
      try {
        setImpersonation(JSON.parse(stored));
      } catch { /* ignore */ }
    }
  }, []);

  if (!impersonation) return null;

  const handleEndSession = async () => {
    setEnding(true);
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (session) {
        await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/impersonate-company`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ action: 'end' }),
        });
      }
      localStorage.removeItem('zafto_impersonation');
      window.location.reload();
    } catch {
      setEnding(false);
    }
  };

  return (
    <div className="bg-red-600 text-white px-4 py-2 flex items-center justify-between text-sm font-medium">
      <span>
        Viewing as <strong>{impersonation.companyName}</strong> &mdash; Remote Support Mode
      </span>
      <button
        onClick={handleEndSession}
        disabled={ending}
        className="px-3 py-1 bg-white text-red-600 rounded font-semibold hover:bg-red-50 transition-colors disabled:opacity-50"
      >
        {ending ? 'Ending...' : 'End Session'}
      </button>
    </div>
  );
}

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
      <AxeDevTools />
      <ImpersonationBanner />
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
