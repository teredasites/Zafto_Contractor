'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Building2,
  Users,
  TicketCheck,
  BookOpen,
  Activity,
  AlertTriangle,
  DollarSign,
  CreditCard,
  TrendingDown,
  FolderOpen,
  Phone,
  Video,
  Code2,
  Calculator,
  LogOut,
  Sun,
  Moon,
  Menu,
  X,
  Banknote,
  Truck,
  Briefcase,
  Mail,
  ShoppingBag,
  Satellite,
  Database,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { Logo } from '@/components/logo';
import { useAuth } from '@/components/auth-provider';
import { useTheme } from '@/components/theme-provider';

interface NavItem {
  label: string;
  href: string;
  icon: React.ReactNode;
}

interface NavSection {
  title: string;
  items: NavItem[];
}

const navSections: NavSection[] = [
  {
    title: 'COMMAND CENTER',
    items: [
      {
        label: 'Dashboard',
        href: '/dashboard',
        icon: <LayoutDashboard className="h-4 w-4" />,
      },
    ],
  },
  {
    title: 'ACCOUNTS',
    items: [
      {
        label: 'Companies',
        href: '/dashboard/companies',
        icon: <Building2 className="h-4 w-4" />,
      },
      {
        label: 'Users',
        href: '/dashboard/users',
        icon: <Users className="h-4 w-4" />,
      },
    ],
  },
  {
    title: 'SUPPORT',
    items: [
      {
        label: 'Tickets',
        href: '/dashboard/tickets',
        icon: <TicketCheck className="h-4 w-4" />,
      },
      {
        label: 'Knowledge Base',
        href: '/dashboard/knowledge-base',
        icon: <BookOpen className="h-4 w-4" />,
      },
    ],
  },
  {
    title: 'HEALTH',
    items: [
      {
        label: 'System Status',
        href: '/dashboard/system-status',
        icon: <Activity className="h-4 w-4" />,
      },
      {
        label: 'Errors',
        href: '/dashboard/errors',
        icon: <AlertTriangle className="h-4 w-4" />,
      },
      {
        label: 'Data Health',
        href: '/dashboard/data-health',
        icon: <Database className="h-4 w-4" />,
      },
      {
        label: 'API Costs',
        href: '/dashboard/api-costs',
        icon: <Satellite className="h-4 w-4" />,
      },
    ],
  },
  {
    title: 'REVENUE',
    items: [
      {
        label: 'Dashboard',
        href: '/dashboard/revenue',
        icon: <DollarSign className="h-4 w-4" />,
      },
      {
        label: 'Subscriptions',
        href: '/dashboard/subscriptions',
        icon: <CreditCard className="h-4 w-4" />,
      },
      {
        label: 'Churn',
        href: '/dashboard/churn',
        icon: <TrendingDown className="h-4 w-4" />,
      },
    ],
  },
  {
    title: 'DATA',
    items: [
      {
        label: 'Estimates',
        href: '/dashboard/estimates',
        icon: <Calculator className="h-4 w-4" />,
      },
      {
        label: 'Code Contributions',
        href: '/dashboard/code-contributions',
        icon: <Code2 className="h-4 w-4" />,
      },
      {
        label: 'Pricing Engine',
        href: '/dashboard/pricing-engine',
        icon: <DollarSign className="h-4 w-4" />,
      },
    ],
  },
  {
    title: 'SERVICES',
    items: [
      {
        label: 'Directory',
        href: '/dashboard/directory',
        icon: <FolderOpen className="h-4 w-4" />,
      },
      {
        label: 'Phone Analytics',
        href: '/dashboard/phone-analytics',
        icon: <Phone className="h-4 w-4" />,
      },
      {
        label: 'Meeting Analytics',
        href: '/dashboard/meeting-analytics',
        icon: <Video className="h-4 w-4" />,
      },
    ],
  },
  {
    title: 'PLATFORM',
    items: [
      {
        label: 'Payroll Analytics',
        href: '/dashboard/payroll-analytics',
        icon: <Banknote className="h-4 w-4" />,
      },
      {
        label: 'Fleet Analytics',
        href: '/dashboard/fleet-analytics',
        icon: <Truck className="h-4 w-4" />,
      },
      {
        label: 'Hiring Analytics',
        href: '/dashboard/hiring-analytics',
        icon: <Briefcase className="h-4 w-4" />,
      },
      {
        label: 'Email Analytics',
        href: '/dashboard/email-analytics',
        icon: <Mail className="h-4 w-4" />,
      },
      {
        label: 'Marketplace Analytics',
        href: '/dashboard/marketplace-analytics',
        icon: <ShoppingBag className="h-4 w-4" />,
      },
      {
        label: 'TPA Analytics',
        href: '/dashboard/tpa',
        icon: <Building2 className="h-4 w-4" />,
      },
    ],
  },
];

export function Sidebar() {
  const pathname = usePathname();
  const { signOut, profile } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const [mobileOpen, setMobileOpen] = useState(false);

  const isActive = (href: string) => {
    if (href === '/dashboard') return pathname === '/dashboard';
    return pathname.startsWith(href);
  };

  const navContent = (
    <div className="flex flex-col h-full">
      {/* Logo */}
      <div className="p-5 border-b border-[var(--border)]">
        <Logo size="sm" />
      </div>

      {/* Navigation */}
      <nav className="flex-1 overflow-y-auto py-4 px-3 space-y-6" aria-label="Operations navigation">
        {navSections.map((section) => (
          <div key={section.title}>
            <p className="px-3 mb-2 text-[10px] font-semibold uppercase tracking-widest text-[var(--text-secondary)] sidebar-label">
              {section.title}
            </p>
            <div className="space-y-0.5">
              {section.items.map((item) => {
                const active = isActive(item.href);
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setMobileOpen(false)}
                    className={cn(
                      'flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors relative',
                      active
                        ? 'bg-[var(--accent)]/10 text-[var(--accent)] font-medium'
                        : 'text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)] hover:text-[var(--text-primary)]'
                    )}
                  >
                    {active && (
                      <span className="absolute left-0 top-1/2 -translate-y-1/2 w-[3px] h-5 rounded-r-full bg-[var(--accent)]" />
                    )}
                    {item.icon}
                    <span>{item.label}</span>
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      {/* Footer */}
      <div className="border-t border-[var(--border)] p-3 space-y-1">
        {profile && (
          <div className="px-3 py-2 mb-1">
            <p className="text-sm font-medium text-[var(--text-primary)] truncate">
              {profile.name}
            </p>
            <p className="text-xs text-[var(--text-secondary)] truncate">
              {profile.role}
            </p>
          </div>
        )}
        <button
          onClick={toggleTheme}
          className="flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)] hover:text-[var(--text-primary)] transition-colors w-full"
        >
          {theme === 'dark' ? (
            <Sun className="h-4 w-4" />
          ) : (
            <Moon className="h-4 w-4" />
          )}
          <span>{theme === 'dark' ? 'Light Mode' : 'Dark Mode'}</span>
        </button>
        <button
          onClick={signOut}
          className="flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-[var(--text-secondary)] hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-950/30 dark:hover:text-red-400 transition-colors w-full"
        >
          <LogOut className="h-4 w-4" />
          <span>Sign Out</span>
        </button>
      </div>
    </div>
  );

  return (
    <>
      {/* Mobile toggle */}
      <button
        onClick={() => setMobileOpen(!mobileOpen)}
        className="fixed top-4 left-4 z-50 lg:hidden p-2 rounded-lg bg-[var(--bg-card)] border border-[var(--border)] text-[var(--text-primary)]"
      >
        {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
      </button>

      {/* Mobile overlay */}
      {mobileOpen && (
        <div
          className="fixed inset-0 z-30 bg-black/50 lg:hidden"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          'fixed left-0 top-0 z-40 h-screen w-[260px] bg-[var(--bg-card)] border-r border-[var(--border)] transition-transform duration-200',
          'lg:translate-x-0',
          mobileOpen ? 'translate-x-0' : '-translate-x-full'
        )}
        aria-label="Operations navigation"
        role="navigation"
      >
        {navContent}
      </aside>
    </>
  );
}
