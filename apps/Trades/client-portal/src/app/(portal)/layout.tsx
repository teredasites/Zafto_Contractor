'use client';
import { usePathname } from 'next/navigation';
import Link from 'next/link';
import { Home, FolderKanban, CreditCard, Building2, Menu, Bell } from 'lucide-react';
import { Logo } from '@/components/logo';
import { ThemeToggle } from '@/components/theme-toggle';
import { AuthProvider, useAuth } from '@/components/auth-provider';
import AiChatWidget from '@/components/ai-chat-widget';

const tabs = [
  { label: 'Home', href: '/home', icon: Home },
  { label: 'Projects', href: '/projects', icon: FolderKanban },
  { label: 'Payments', href: '/payments', icon: CreditCard },
  { label: 'My Home', href: '/my-home', icon: Building2 },
  { label: 'Menu', href: '/menu', icon: Menu },
];

function PortalShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { profile } = useAuth();
  const initials = profile?.displayName
    ? profile.displayName.split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2)
    : '?';

  const isActive = (href: string) => {
    if (href === '/home') return pathname === '/home';
    if (href === '/menu') return pathname === '/menu' || ['/messages', '/documents', '/request', '/referrals', '/review', '/settings', '/rent', '/lease', '/maintenance', '/inspections'].some(p => pathname.startsWith(p));
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
              {tabs.map(tab => {
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
            <button className="relative p-2 text-muted hover:text-main hover:bg-surface-hover rounded-lg transition-colors">
              <Bell size={18} />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full" style={{ backgroundColor: 'var(--accent)' }} />
            </button>
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
