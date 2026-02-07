'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { ThemeToggle } from '@/components/theme-toggle';
import { onAuthChange, signOut } from '@/lib/auth';
import type { User } from '@supabase/supabase-js';
import {
  Menu,
  Bell,
  Search,
} from 'lucide-react';
import { ZMark } from '@/components/z-console/z-mark';
import { AuthProvider } from '@/components/auth-provider';
import { PermissionProvider } from '@/components/permission-gate';
import { Sidebar } from '@/components/sidebar';
import { ZConsoleProvider, ZConsole, useZConsole } from '@/components/z-console';
import { cn } from '@/lib/utils';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [sidebarPinned, setSidebarPinned] = useState(() => {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('zafto_sidebar_pinned');
      return stored === null ? true : stored === 'true';
    }
    return true;
  });
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthChange((user) => {
      if (!user) {
        router.push('/');
      } else {
        setUser(user);
      }
      setLoading(false);
    });
    return () => unsubscribe();
  }, [router]);

  useEffect(() => {
    localStorage.setItem('zafto_sidebar_pinned', String(sidebarPinned));
  }, [sidebarPinned]);

  const handleSignOut = async () => {
    await signOut();
    router.push('/');
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-main">
        <div className="w-8 h-8 border-2 border-[var(--accent)]/30 border-t-[var(--accent)] rounded-full animate-spin" />
      </div>
    );
  }

  if (!user) {
    return null;
  }

  return (
    <AuthProvider>
      <PermissionProvider>
        <ZConsoleProvider>
          <DashboardShell
            sidebarPinned={sidebarPinned}
            sidebarOpen={sidebarOpen}
            onSidebarOpenChange={setSidebarOpen}
            onSidebarPinnedChange={setSidebarPinned}
            user={user}
            onSignOut={handleSignOut}
          >
            {children}
          </DashboardShell>
        </ZConsoleProvider>
      </PermissionProvider>
    </AuthProvider>
  );
}

// ── Inner shell — reads Z console state for dynamic margin ──
function DashboardShell({
  children,
  sidebarPinned,
  sidebarOpen,
  onSidebarOpenChange,
  onSidebarPinnedChange,
  user,
  onSignOut,
}: {
  children: React.ReactNode;
  sidebarPinned: boolean;
  sidebarOpen: boolean;
  onSidebarOpenChange: (open: boolean) => void;
  onSidebarPinnedChange: (pinned: boolean) => void;
  user: User;
  onSignOut: () => void;
}) {
  const { consoleState } = useZConsole();
  const isArtifact = consoleState === 'artifact';

  return (
    <div className="min-h-screen bg-main">
      <Sidebar
        pinned={sidebarPinned}
        onPinnedChange={onSidebarPinnedChange}
        mobileOpen={sidebarOpen}
        onMobileClose={() => onSidebarOpenChange(false)}
        user={user}
        onSignOut={onSignOut}
      />

      {/* Main content — compresses when artifact is open */}
      <div
        className={cn(
          'transition-[padding,margin] duration-[280ms] ease-out',
          sidebarPinned ? 'lg:pl-[220px]' : 'lg:pl-12',
        )}
        style={{
          marginRight: isArtifact ? 'min(60vw, 800px)' : '0px',
          transition: 'margin-right 280ms cubic-bezier(0.32, 0.72, 0, 1), padding 200ms ease-out',
        }}
      >
        {/* Top bar */}
        <header className="sticky top-0 z-30 h-14 bg-main/80 backdrop-blur-sm border-b border-main">
          <div className="flex items-center justify-between h-full px-4 lg:px-6">
            <div className="flex items-center gap-3">
              <button
                className="lg:hidden text-muted hover:text-main p-1.5 rounded-md hover:bg-surface-hover transition-colors"
                onClick={() => onSidebarOpenChange(true)}
              >
                <Menu size={20} />
              </button>

              {/* Search - Command Palette Trigger */}
              <button className="hidden sm:flex items-center gap-2 px-3 py-1.5 bg-secondary border border-main rounded-lg w-56 hover:border-accent/40 transition-colors">
                <Search size={15} className="text-muted" />
                <span className="text-[13px] text-muted flex-1 text-left">Search...</span>
                <kbd className="hidden md:inline text-[11px] text-muted bg-main px-1.5 py-0.5 rounded border border-main">
                  ⌘K
                </kbd>
              </button>
            </div>

            <div className="flex items-center gap-1">
              <ProModeToggle />
              <ThemeToggle />
              <button className="relative p-2 text-muted hover:text-main hover:bg-surface-hover rounded-lg transition-colors">
                <Bell size={18} />
                <span className="absolute top-1.5 right-1.5 w-1.5 h-1.5 bg-accent rounded-full" />
              </button>
            </div>
          </div>
        </header>

        {/* Page content */}
        <main className="p-4 lg:p-8">
          {children}
        </main>
      </div>

      {/* Z Console — fixed position, renders per state */}
      <ZConsole />
    </div>
  );
}

function ProModeToggle() {
  const [isOn, setIsOn] = useState(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('zafto_pro_mode') === 'true';
    }
    return false;
  });

  useEffect(() => {
    const handleProModeChange = (e: CustomEvent) => {
      setIsOn(e.detail as boolean);
    };
    window.addEventListener('proModeChange', handleProModeChange as EventListener);
    return () => window.removeEventListener('proModeChange', handleProModeChange as EventListener);
  }, []);

  const handleToggle = () => {
    const newValue = !isOn;
    setIsOn(newValue);
    localStorage.setItem('zafto_pro_mode', String(newValue));
    window.dispatchEvent(new CustomEvent('proModeChange', { detail: newValue }));
  };

  return (
    <button
      onClick={handleToggle}
      className={cn(
        'flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-[13px] font-medium transition-all',
        isOn
          ? 'bg-accent text-white'
          : 'text-muted hover:text-main hover:bg-surface-hover',
      )}
    >
      <ZMark size={14} />
      <span>PRO</span>
      <span className={cn('w-7 h-3.5 rounded-full relative transition-colors', isOn ? 'bg-white/30' : 'bg-secondary')}>
        <span className={cn('absolute top-0.5 w-2.5 h-2.5 rounded-full bg-white shadow-sm transition-all duration-200', isOn ? 'left-3.5' : 'left-0.5')} />
      </span>
    </button>
  );
}
