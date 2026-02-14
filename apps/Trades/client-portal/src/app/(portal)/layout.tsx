'use client';
import { useState, useEffect, useRef } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import Link from 'next/link';
import { Home, FolderKanban, CreditCard, Building2, Menu, Bell, MessageSquare, Video, Check } from 'lucide-react';
import { Logo } from '@/components/logo';
import { ThemeToggle } from '@/components/theme-toggle';
import { AuthProvider, useAuth } from '@/components/auth-provider';
import { useNotifications } from '@/lib/hooks/use-notifications';
import AiChatWidget from '@/components/ai-chat-widget';

const tabs = [
  { label: 'Home', href: '/home', icon: Home },
  { label: 'Projects', href: '/projects', icon: FolderKanban },
  { label: 'Payments', href: '/payments', icon: CreditCard },
  { label: 'My Home', href: '/my-home', icon: Building2 },
  { label: 'Menu', href: '/menu', icon: Menu },
];

const desktopTabs = [
  { label: 'Home', href: '/home', icon: Home },
  { label: 'Projects', href: '/projects', icon: FolderKanban },
  { label: 'Payments', href: '/payments', icon: CreditCard },
  { label: 'Messages', href: '/messages', icon: MessageSquare },
  { label: 'Meetings', href: '/meetings', icon: Video },
  { label: 'My Home', href: '/my-home', icon: Building2 },
  { label: 'Menu', href: '/menu', icon: Menu },
];

function PortalShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { profile } = useAuth();
  const { notifications, unreadCount, markAsRead, markAllAsRead } = useNotifications();
  const [bellOpen, setBellOpen] = useState(false);
  const bellRef = useRef<HTMLDivElement>(null);
  const router = useRouter();
  const initials = profile?.displayName
    ? profile.displayName.split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2)
    : '?';

  useEffect(() => {
    if (!bellOpen) return;
    const handler = (e: MouseEvent) => {
      if (bellRef.current && !bellRef.current.contains(e.target as Node)) setBellOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [bellOpen]);

  const isActive = (href: string) => {
    if (href === '/home') return pathname === '/home';
    if (href === '/messages') return pathname.startsWith('/messages');
    if (href === '/meetings') return pathname.startsWith('/meetings') || pathname.startsWith('/book');
    if (href === '/menu') return pathname === '/menu' || ['/documents', '/request', '/referrals', '/review', '/settings', '/rent', '/lease', '/maintenance', '/inspections', '/get-quotes', '/find-a-pro', '/agreements'].some(p => pathname.startsWith(p));
    return pathname.startsWith(href);
  };

  return (
    <div className="min-h-screen bg-main">
      {/* Desktop Top Nav */}
      <header className="sticky top-0 z-40 bg-main/80 backdrop-blur-sm border-b border-main">
        <div className="max-w-5xl mx-auto flex items-center justify-between h-14 px-4 lg:px-8">
          <div className="flex items-center gap-6">
            <Link href="/home" className="flex items-center gap-2.5">
              <Logo size={28} className="text-main" />
              <span className="text-sm font-semibold text-main hidden sm:block">Client Portal</span>
            </Link>

            {/* Desktop nav tabs */}
            <nav className="hidden md:flex items-center gap-1">
              {desktopTabs.map(tab => {
                const Icon = tab.icon;
                const active = isActive(tab.href);
                return (
                  <Link key={tab.href} href={tab.href}
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                      active ? 'bg-accent-light text-accent' : 'text-muted hover:text-main hover:bg-surface-hover'
                    }`}>
                    <Icon size={16} />
                    <span>{tab.label}</span>
                  </Link>
                );
              })}
            </nav>
          </div>

          <div className="flex items-center gap-1">
            <ThemeToggle />
            <div ref={bellRef} className="relative">
              <button
                onClick={() => setBellOpen(!bellOpen)}
                className={`relative p-2 rounded-lg transition-colors ${bellOpen ? 'bg-accent-light text-accent' : 'text-muted hover:text-main hover:bg-surface-hover'}`}
              >
                <Bell size={18} />
                {unreadCount > 0 && (
                  <span className="absolute top-1 right-1 min-w-[14px] h-3.5 px-0.5 rounded-full bg-red-500 text-white text-[9px] font-bold flex items-center justify-center">
                    {unreadCount > 99 ? '99+' : unreadCount}
                  </span>
                )}
              </button>

              {bellOpen && (
                <div className="absolute right-0 top-full mt-2 w-80 bg-surface border border-main rounded-xl shadow-xl z-50 overflow-hidden">
                  <div className="px-4 py-3 border-b border-main flex items-center justify-between">
                    <div>
                      <p className="text-[13px] font-semibold text-main">Notifications</p>
                      <p className="text-[11px] text-muted">{unreadCount > 0 ? `${unreadCount} unread` : 'All caught up'}</p>
                    </div>
                    {unreadCount > 0 && (
                      <button onClick={() => markAllAsRead()} className="text-[11px] font-medium text-accent hover:underline flex items-center gap-1">
                        <Check size={12} /> Mark all read
                      </button>
                    )}
                  </div>
                  <div className="max-h-[320px] overflow-y-auto">
                    {notifications.length === 0 ? (
                      <div className="py-10 text-center">
                        <Bell size={24} className="mx-auto mb-2 text-muted" />
                        <p className="text-[13px] text-muted">No notifications yet</p>
                      </div>
                    ) : (
                      <div className="p-1.5">
                        {notifications.map((n) => {
                          const ago = (() => { const m = Math.floor((Date.now() - new Date(n.createdAt).getTime()) / 60000); if (m < 1) return 'now'; if (m < 60) return `${m}m`; const h = Math.floor(m / 60); if (h < 24) return `${h}h`; return `${Math.floor(h / 24)}d`; })();
                          return (
                            <button key={n.id} onClick={() => { if (!n.isRead) markAsRead(n.id); }}
                              className={`w-full flex items-start gap-3 px-3 py-2.5 rounded-lg text-left transition-colors ${n.isRead ? 'hover:bg-surface-hover' : 'bg-accent/5 hover:bg-accent/10'}`}>
                              {!n.isRead && <div className="w-2 h-2 rounded-full bg-accent flex-shrink-0 mt-1.5" />}
                              <div className={`flex-1 min-w-0 ${n.isRead ? 'ml-5' : ''}`}>
                                <p className={`text-[13px] truncate ${n.isRead ? 'text-muted' : 'font-medium text-main'}`}>{n.title}</p>
                                <p className="text-[12px] text-muted truncate">{n.body}</p>
                              </div>
                              <span className="text-[11px] text-muted flex-shrink-0 mt-0.5">{ago}</span>
                            </button>
                          );
                        })}
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
            <div className="w-8 h-8 rounded-full flex items-center justify-center ml-1" style={{ backgroundColor: 'var(--accent-light)' }}>
              <span className="text-xs font-semibold" style={{ color: 'var(--accent)' }}>{initials}</span>
            </div>
          </div>
        </div>
      </header>

      {/* Page Content */}
      <main className="max-w-5xl mx-auto px-4 lg:px-8 py-6 pb-24 md:pb-8">
        {children}
      </main>

      {/* Mobile Bottom Tab Bar */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50 bg-surface border-t border-main">
        <div className="flex items-center justify-around h-16">
          {tabs.map(tab => {
            const Icon = tab.icon;
            const active = isActive(tab.href);
            return (
              <Link key={tab.href} href={tab.href}
                className={`flex flex-col items-center gap-0.5 px-3 py-1.5 transition-colors ${
                  active ? 'text-accent' : 'text-muted'
                }`}>
                <Icon size={20} />
                <span className="text-[10px] font-medium">{tab.label}</span>
              </Link>
            );
          })}
        </div>
      </nav>

      {/* AI Chat Widget */}
      <AiChatWidget />
    </div>
  );
}

export default function PortalLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <PortalShell>{children}</PortalShell>
    </AuthProvider>
  );
}
