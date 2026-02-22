'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { ThemeToggle } from '@/components/theme-toggle';
import { onAuthChange, signOut } from '@/lib/auth';
import type { User } from '@supabase/supabase-js';
import {
  Menu,
  Search,
  FolderOpen,
  Briefcase,
  ChevronDown,
  FileText,
  Clock,
  Loader2,
  Bell,
  Check,
} from 'lucide-react';
import { ZMark } from '@/components/z-console/z-mark';
import { useNotifications } from '@/lib/hooks/use-notifications';
import { AuthProvider, useAuth } from '@/components/auth-provider';
import { PermissionProvider } from '@/components/permission-gate';
import { Sidebar, useSidebarWidth } from '@/components/sidebar';
import { CommandPalette } from '@/components/command-palette';
import { ZConsoleProvider, ZConsole, useZConsole } from '@/components/z-console';
import { cn } from '@/lib/utils';
import { AxeDevTools } from '@/components/axe-dev-tools';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const [sidebarOpen, setSidebarOpen] = useState(false);
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
          <AxeDevTools />
          <DashboardShell
            sidebarOpen={sidebarOpen}
            onSidebarOpenChange={setSidebarOpen}
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
  sidebarOpen,
  onSidebarOpenChange,
  user,
  onSignOut,
}: {
  children: React.ReactNode;
  sidebarOpen: boolean;
  onSidebarOpenChange: (open: boolean) => void;
  user: User;
  onSignOut: () => void;
}) {
  const router = useRouter();
  const { consoleState, chatWidth, artifactWidth, setConsoleState } = useZConsole();
  const { profile } = useAuth();
  const isArtifact = consoleState === 'artifact';
  const sidebarPx = useSidebarWidth();

  const companyName = profile?.companyName || null;

  return (
    <div className="min-h-screen bg-main">
      {/* Skip navigation — appears on first Tab press */}
      <a
        href="#main-content"
        className="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:z-[100] focus:px-4 focus:py-2 focus:bg-[var(--accent)] focus:text-white focus:rounded-lg focus:text-sm focus:font-medium focus:outline-none"
      >
        Skip to main content
      </a>

      <Sidebar
        mobileOpen={sidebarOpen}
        onMobileClose={() => onSidebarOpenChange(false)}
        user={user}
        onSignOut={onSignOut}
      />

      {/* Main content — offset by sidebar width, compresses when artifact open */}
      <div
        className="transition-[padding,margin] duration-[280ms] ease-out"
        style={{
          paddingLeft: `${sidebarPx}px`,
          marginRight: isArtifact ? `${chatWidth + artifactWidth}px` : '0px',
          transition: 'margin-right 280ms cubic-bezier(0.32, 0.72, 0, 1), padding-left 200ms ease-out',
        }}
      >
        {/* Top bar */}
        <header className="sticky top-0 z-30 h-14 bg-main/80 backdrop-blur-sm border-b border-main" aria-label="Top bar">
          <div className="flex items-center justify-between h-full px-4 md:px-6">
            {/* Left side: hamburger (mobile) + company name */}
            <div className="flex items-center gap-3">
              <button
                className="md:hidden text-muted hover:text-main p-1.5 rounded-md hover:bg-surface-hover transition-colors"
                onClick={() => onSidebarOpenChange(true)}
                aria-label="Open navigation menu"
              >
                <Menu size={20} />
              </button>

              {companyName ? (
                <span className="text-[15px] font-semibold text-main truncate max-w-[200px]">
                  {companyName}
                </span>
              ) : (
                <span className="text-[15px] font-semibold tracking-[0.04em] text-main">
                  ZAFTO
                </span>
              )}
            </div>

            {/* Right side: search + actions */}
            <div className="flex items-center gap-2">
              {/* Search - Command Palette Trigger */}
              <button
                onClick={() => {
                  document.dispatchEvent(new KeyboardEvent('keydown', { key: 'k', ctrlKey: true, bubbles: true }));
                }}
                className="hidden sm:flex items-center gap-2 px-3 py-1.5 bg-secondary border border-main rounded-lg w-56 hover:border-accent/40 transition-colors"
                aria-label="Search or jump to (Ctrl+K)"
              >
                <Search size={15} className="text-muted" />
                <span className="text-[13px] text-muted flex-1 text-left">Search or jump to...</span>
                <kbd className="hidden md:inline text-[11px] text-muted bg-main px-1.5 py-0.5 rounded border border-main">
                  ⌘K
                </kbd>
              </button>

              {/* Documents / Files */}
              <button
                onClick={() => router.push('/dashboard/documents')}
                className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-[13px] font-medium text-muted hover:text-main hover:bg-surface-hover transition-all"
                aria-label="Documents and files"
              >
                <FolderOpen size={16} />
                <span className="hidden sm:inline">Files</span>
              </button>

              {/* Z Intelligence toggle */}
              <button
                onClick={() => {
                  if (consoleState === 'collapsed') {
                    setConsoleState('open');
                  } else {
                    setConsoleState('collapsed');
                  }
                }}
                className={cn(
                  'flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-[13px] font-medium transition-all',
                  consoleState !== 'collapsed'
                    ? 'bg-emerald-500/10 text-emerald-500'
                    : 'text-muted hover:text-main hover:bg-surface-hover',
                )}
                aria-label={`Z Intelligence ${consoleState !== 'collapsed' ? '(active)' : ''} — Ctrl+J`}
                aria-pressed={consoleState !== 'collapsed'}
              >
                <ZMark size={16} />
              </button>

              <ThemeToggle />
              <NotificationBell />
              <ActiveWorkDropdown />
            </div>
          </div>
        </header>

        {/* Page content */}
        <main id="main-content" className="p-4 md:p-8" aria-label="Page content">
          <CommandPalette />
          {children}
        </main>
      </div>

      {/* Z Console — fixed position, renders per state */}
      <ZConsole />
    </div>
  );
}

// ── Notification Bell ──
function NotificationBell() {
  const { notifications, unreadCount, markAsRead, markAllAsRead } = useNotifications();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const router = useRouter();

  useEffect(() => {
    if (!open) return;
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [open]);

  const getEntityPath = (n: { entityType: string | null; entityId: string | null }) => {
    if (!n.entityType || !n.entityId) return null;
    const map: Record<string, string> = {
      job: '/dashboard/jobs',
      invoice: '/dashboard/invoices',
      bid: '/dashboard/bids',
      customer: '/dashboard/customers',
      estimate: '/dashboard/estimates',
    };
    return map[n.entityType] || null;
  };

  const timeAgo = (dateStr: string) => {
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1) return 'now';
    if (mins < 60) return `${mins}m`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs}h`;
    const days = Math.floor(hrs / 24);
    return `${days}d`;
  };

  return (
    <div ref={ref} className="relative">
      <button
        onClick={() => setOpen(!open)}
        className={cn(
          'relative p-2 rounded-lg transition-colors',
          open ? 'bg-accent/10 text-accent' : 'text-muted hover:text-main hover:bg-surface-hover',
        )}
        aria-label={`Notifications${unreadCount > 0 ? ` — ${unreadCount} unread` : ''}`}
        aria-expanded={open}
        aria-haspopup="true"
      >
        <Bell size={16} />
        {unreadCount > 0 && (
          <span className="absolute -top-0.5 -right-0.5 min-w-[16px] h-4 px-1 rounded-full bg-red-500 text-white text-[10px] font-bold flex items-center justify-center" aria-hidden="true">
            {unreadCount > 99 ? '99+' : unreadCount}
          </span>
        )}
      </button>

      {open && (
        <div className="absolute right-0 top-full mt-2 w-80 bg-surface border border-main rounded-xl shadow-xl z-50 overflow-hidden animate-fade-in" role="dialog" aria-label="Notifications" aria-modal="false">
          <div className="px-4 py-3 border-b border-main flex items-center justify-between">
            <div>
              <h2 className="text-[13px] font-semibold text-main">Notifications</h2>
              <p className="text-[11px] text-muted">{unreadCount > 0 ? `${unreadCount} unread` : 'All caught up'}</p>
            </div>
            {unreadCount > 0 && (
              <button
                onClick={() => markAllAsRead()}
                className="text-[11px] font-medium text-accent hover:underline flex items-center gap-1"
              >
                <Check size={12} />
                Mark all read
              </button>
            )}
          </div>

          <div className="max-h-[360px] overflow-y-auto" role="list" aria-label="Notification items">
            {notifications.length === 0 ? (
              <div className="py-10 text-center">
                <Bell size={24} className="mx-auto mb-2 text-muted" aria-hidden="true" />
                <p className="text-[13px] text-muted">No notifications yet</p>
              </div>
            ) : (
              <div className="p-1.5">
                {notifications.map((n) => (
                  <button
                    key={n.id}
                    onClick={() => {
                      if (!n.isRead) markAsRead(n.id);
                      const path = getEntityPath(n);
                      if (path) {
                        setOpen(false);
                        router.push(path);
                      }
                    }}
                    className={cn(
                      'w-full flex items-start gap-3 px-3 py-2.5 rounded-lg text-left transition-colors',
                      n.isRead ? 'hover:bg-surface-hover' : 'bg-accent/5 hover:bg-accent/10',
                    )}
                  >
                    {!n.isRead && (
                      <div className="w-2 h-2 rounded-full bg-accent flex-shrink-0 mt-1.5" />
                    )}
                    <div className={cn('flex-1 min-w-0', n.isRead && 'ml-5')}>
                      <p className={cn('text-[13px] truncate', n.isRead ? 'text-muted' : 'font-medium text-main')}>
                        {n.title}
                      </p>
                      <p className="text-[12px] text-muted truncate">{n.body}</p>
                    </div>
                    <span className="text-[11px] text-muted flex-shrink-0 mt-0.5">{timeAgo(n.createdAt)}</span>
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ── Active Work dropdown ──
function ActiveWorkDropdown() {
  const [open, setOpen] = useState(false);
  const [items, setItems] = useState<{ id: string; type: string; title: string; status: string; customer: string }[]>([]);
  const [loading, setLoading] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  // Close on click outside
  useEffect(() => {
    if (!open) return;
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [open]);

  // Load active work items when opened
  useEffect(() => {
    if (!open || items.length > 0) return;
    setLoading(true);
    (async () => {
      try {
        const { getSupabase } = await import('@/lib/supabase');
        const supabase = getSupabase();

        // Fetch recent in-progress bids, jobs, estimates
        const [bidsRes, jobsRes] = await Promise.all([
          supabase.from('bids').select('id, title, status, customer_name').in('status', ['draft', 'sent', 'pending']).order('updated_at', { ascending: false }).limit(5),
          supabase.from('jobs').select('id, title, status, customer_name').in('status', ['scheduled', 'in_progress']).order('updated_at', { ascending: false }).limit(5),
        ]);

        const result: typeof items = [];

        for (const b of bidsRes.data || []) {
          result.push({ id: b.id, type: 'bid', title: b.title || 'Untitled Bid', status: b.status, customer: b.customer_name || '' });
        }
        for (const j of jobsRes.data || []) {
          result.push({ id: j.id, type: 'job', title: j.title || 'Untitled Job', status: j.status, customer: j.customer_name || '' });
        }

        setItems(result);
      } catch {
        setItems([]);
      }
      setLoading(false);
    })();
  }, [open, items.length]);

  const router = useRouter();

  return (
    <div ref={ref} className="relative">
      <button
        onClick={() => setOpen(!open)}
        className={cn(
          'flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-[13px] font-medium transition-all',
          open
            ? 'bg-accent/10 text-accent'
            : 'text-muted hover:text-main hover:bg-surface-hover',
        )}
        aria-label="Active work items"
        aria-expanded={open}
        aria-haspopup="true"
      >
        <Briefcase size={16} />
        <span className="hidden sm:inline">Active</span>
        <ChevronDown size={12} className={cn('transition-transform', open && 'rotate-180')} aria-hidden="true" />
      </button>

      {open && (
        <div className="absolute right-0 top-full mt-2 w-80 bg-surface border border-main rounded-xl shadow-xl z-50 overflow-hidden animate-fade-in">
          <div className="px-4 py-3 border-b border-main">
            <p className="text-[13px] font-semibold text-main">Active Work</p>
            <p className="text-[11px] text-muted">In-progress bids, jobs & estimates</p>
          </div>

          <div className="max-h-[320px] overflow-y-auto">
            {loading ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 size={18} className="animate-spin text-muted" />
              </div>
            ) : items.length === 0 ? (
              <div className="py-8 text-center">
                <Briefcase size={24} className="mx-auto mb-2 text-muted" />
                <p className="text-[13px] text-muted">No active items</p>
              </div>
            ) : (
              <div className="p-1.5">
                {items.map(item => (
                  <button
                    key={`${item.type}-${item.id}`}
                    onClick={() => {
                      setOpen(false);
                      const path = item.type === 'bid' ? `/dashboard/bids` : `/dashboard/jobs`;
                      router.push(path);
                    }}
                    className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-left hover:bg-surface-hover transition-colors"
                  >
                    <div className={cn(
                      'w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0',
                      item.type === 'bid' ? 'bg-blue-50 text-blue-600' : 'bg-emerald-50 text-emerald-600',
                    )}>
                      {item.type === 'bid' ? <FileText size={14} /> : <Briefcase size={14} />}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-[13px] font-medium text-main truncate">{item.title}</p>
                      <div className="flex items-center gap-2">
                        {item.customer && <span className="text-[11px] text-muted truncate">{item.customer}</span>}
                        <span className={cn(
                          'text-[10px] font-medium px-1.5 py-0.5 rounded',
                          item.status === 'in_progress' ? 'bg-emerald-50 text-emerald-600' :
                          item.status === 'draft' ? 'bg-gray-100 text-gray-600' :
                          item.status === 'sent' || item.status === 'pending' ? 'bg-amber-50 text-amber-600' :
                          'bg-blue-50 text-blue-600',
                        )}>
                          {item.status.replace('_', ' ')}
                        </span>
                      </div>
                    </div>
                    <Clock size={12} className="text-muted flex-shrink-0" />
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

