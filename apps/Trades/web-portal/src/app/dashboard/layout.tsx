'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { ThemeToggle } from '@/components/theme-toggle';
import { onAuthChange, signOut, type User } from '@/lib/auth';
import {
  LayoutDashboard,
  FileText,
  Briefcase,
  Receipt,
  Calendar,
  Users,
  Settings,
  LogOut,
  Menu,
  X,
  ChevronDown,
  Bell,
  Search,
  DollarSign,
  Sparkles,
  BookOpen,
  BarChart3,
  Target,
  ArrowRightLeft,
  ClipboardCheck,
  FileCheck2,
  Shield,
  Zap,
  ShoppingCart,
  Store,
  Package,
  Wrench,
  MessageSquare,
  FolderOpen,
  Handshake,
  Mic,
  Brain,
  Radar,
  Cpu,
  Rocket,
} from 'lucide-react';
import { Logo } from '@/components/logo';
import { AuthProvider } from '@/components/auth-provider';
import { PermissionProvider, PermissionGate, ProModeGate, PERMISSIONS, usePermissions } from '@/components/permission-gate';
import { Clock } from 'lucide-react';
import { doc, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface NavItem {
  name: string;
  href: string;
  icon: any;
  permission?: string;
}

interface NavGroup {
  label: string;
  items: NavItem[];
}

const navigationGroups: NavGroup[] = [
  {
    label: 'OPERATIONS',
    items: [
      { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
      { name: 'Leads', href: '/dashboard/leads', icon: Target },
      { name: 'Bids', href: '/dashboard/bids', icon: FileText },
      { name: 'Jobs', href: '/dashboard/jobs', icon: Briefcase },
      { name: 'Change Orders', href: '/dashboard/change-orders', icon: ArrowRightLeft },
      { name: 'Invoices', href: '/dashboard/invoices', icon: Receipt },
    ],
  },
  {
    label: 'SCHEDULING',
    items: [
      { name: 'Calendar', href: '/dashboard/calendar', icon: Calendar },
      { name: 'Inspections', href: '/dashboard/inspections', icon: ClipboardCheck },
      { name: 'Permits', href: '/dashboard/permits', icon: FileCheck2 },
      { name: 'Time Clock', href: '/dashboard/time-clock', icon: Clock, permission: PERMISSIONS.TIMECLOCK_VIEW_ALL },
    ],
  },
  {
    label: 'CUSTOMERS',
    items: [
      { name: 'Customers', href: '/dashboard/customers', icon: Users },
      { name: 'Communications', href: '/dashboard/communications', icon: MessageSquare },
      { name: 'Service Agreements', href: '/dashboard/service-agreements', icon: Handshake },
      { name: 'Warranties', href: '/dashboard/warranties', icon: Shield },
    ],
  },
  {
    label: 'RESOURCES',
    items: [
      { name: 'Team', href: '/dashboard/team', icon: Users },
      { name: 'Equipment', href: '/dashboard/equipment', icon: Wrench },
      { name: 'Inventory', href: '/dashboard/inventory', icon: Package },
      { name: 'Vendors', href: '/dashboard/vendors', icon: Store },
      { name: 'Purchase Orders', href: '/dashboard/purchase-orders', icon: ShoppingCart },
    ],
  },
  {
    label: 'OFFICE',
    items: [
      { name: 'Books', href: '/dashboard/books', icon: DollarSign },
      { name: 'Price Book', href: '/dashboard/price-book', icon: BookOpen },
      { name: 'Documents', href: '/dashboard/documents', icon: FolderOpen },
      { name: 'Reports', href: '/dashboard/reports', icon: BarChart3 },
      { name: 'Automations', href: '/dashboard/automations', icon: Zap },
    ],
  },
  {
    label: 'Z INTELLIGENCE',
    items: [
      { name: 'Z AI', href: '/dashboard/z', icon: Sparkles },
      { name: 'Z Voice', href: '/dashboard/z-voice', icon: Mic },
      { name: 'Bid Brain', href: '/dashboard/bid-brain', icon: Brain },
      { name: 'Job Cost Radar', href: '/dashboard/job-cost-radar', icon: Radar },
      { name: 'Equipment Memory', href: '/dashboard/equipment-memory', icon: Cpu },
      { name: 'Revenue Autopilot', href: '/dashboard/revenue-autopilot', icon: Rocket },
    ],
  },
];

const bottomNav = [
  { name: 'Settings', href: '/dashboard/settings', icon: Settings },
];

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
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

  // Get user initials
  const initials = user.email
    ? user.email.substring(0, 2).toUpperCase()
    : 'U';

  // Navigation item renderer with optional permission gate
  const renderNavItem = (item: NavItem) => {
    const isActive = pathname === item.href;
    const navLink = (
      <Link
        key={item.name}
        href={item.href}
        className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
          isActive
            ? 'bg-accent-light text-accent'
            : 'text-muted hover:text-main hover:bg-surface-hover'
        }`}
      >
        <item.icon size={18} />
        {item.name}
      </Link>
    );

    if (item.permission) {
      return (
        <PermissionGate key={item.name} permission={item.permission as any}>
          {navLink}
        </PermissionGate>
      );
    }

    return navLink;
  };

  return (
    <AuthProvider>
      <PermissionProvider>
        <div className="min-h-screen bg-main">
          {/* Mobile sidebar backdrop */}
          {sidebarOpen && (
            <div
              className="fixed inset-0 bg-black/20 dark:bg-black/50 z-40 lg:hidden"
              onClick={() => setSidebarOpen(false)}
            />
          )}

          {/* Sidebar */}
          <aside
            className={`fixed top-0 left-0 z-50 h-full w-64 bg-surface border-r border-main transform transition-transform duration-200 lg:translate-x-0 ${
              sidebarOpen ? 'translate-x-0' : '-translate-x-full'
            }`}
          >
            <div className="flex flex-col h-full">
              {/* Logo */}
              <div className="flex items-center justify-between h-16 px-6 border-b border-main">
                <Link href="/dashboard" className="flex items-center">
                  <Logo size={36} className="text-main" />
                </Link>
                <button
                  className="lg:hidden text-muted hover:text-main"
                  onClick={() => setSidebarOpen(false)}
                >
                  <X size={20} />
                </button>
              </div>

              {/* Navigation */}
              <nav className="flex-1 px-3 py-4 space-y-4 overflow-y-auto">
                {navigationGroups.map((group) => (
                  <div key={group.label}>
                    <p className="px-3 mb-1 text-[10px] font-semibold uppercase tracking-widest text-muted/60">
                      {group.label}
                    </p>
                    <div className="space-y-0.5">
                      {group.items.map(renderNavItem)}
                    </div>
                  </div>
                ))}
              </nav>

          {/* Bottom nav */}
          <div className="px-3 py-4 border-t border-main space-y-1">
            {bottomNav.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                    isActive
                      ? 'bg-accent-light text-accent'
                      : 'text-muted hover:text-main hover:bg-surface-hover'
                  }`}
                >
                  <item.icon size={18} />
                  {item.name}
                </Link>
              );
            })}
            <button
              onClick={handleSignOut}
              className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-muted hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 w-full transition-colors"
            >
              <LogOut size={18} />
              Sign out
            </button>
          </div>

          {/* User */}
          <div className="px-3 py-4 border-t border-main">
            <UserDropdown user={user} initials={initials} onSignOut={handleSignOut} />
          </div>
        </div>
      </aside>

      {/* Main content */}
      <div className="lg:pl-64">
        {/* Top bar */}
        <header className="sticky top-0 z-30 h-16 bg-main/80 backdrop-blur-sm border-b border-main">
          <div className="flex items-center justify-between h-full px-4 lg:px-8">
            <div className="flex items-center gap-4">
              <button
                className="lg:hidden text-muted hover:text-main"
                onClick={() => setSidebarOpen(true)}
              >
                <Menu size={24} />
              </button>

              {/* Search - Command Palette Trigger */}
              <button className="hidden sm:flex items-center gap-2 px-3 py-2 bg-secondary border border-main rounded-lg w-64 hover:border-accent/50 transition-colors">
                <Search size={16} className="text-muted" />
                <span className="text-sm text-muted flex-1 text-left">Search...</span>
                <kbd className="hidden md:inline text-xs text-muted bg-main px-1.5 py-0.5 rounded border border-main">
                  ⌘K
                </kbd>
              </button>
            </div>

            <div className="flex items-center gap-2">
              {/* Pro Mode Toggle */}
              <ProModeToggle />

              {/* Theme toggle */}
              <ThemeToggle />

              {/* Notifications */}
              <button className="relative p-2 text-muted hover:text-main hover:bg-surface-hover rounded-lg transition-colors">
                <Bell size={20} />
                <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-accent rounded-full" />
              </button>
            </div>
          </div>
        </header>

          {/* Page content */}
          <main className="p-4 lg:p-8">{children}</main>
        </div>
      </div>
      </PermissionProvider>
    </AuthProvider>
  );
}

function UserDropdown({ user, initials, onSignOut }: { user: User; initials: string; onSignOut: () => void }) {
  const [isOpen, setIsOpen] = useState(false);
  const router = useRouter();

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-3 w-full px-3 py-2 rounded-lg hover:bg-surface-hover transition-colors"
      >
        <div className="w-8 h-8 rounded-full bg-accent-light flex items-center justify-center">
          <span className="text-accent text-sm font-medium">{initials}</span>
        </div>
        <div className="flex-1 text-left min-w-0">
          <p className="text-sm font-medium text-main truncate">{user.email}</p>
          <p className="text-xs text-muted">Owner</p>
        </div>
        <ChevronDown size={16} className={`text-muted flex-shrink-0 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {isOpen && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setIsOpen(false)} />
          <div className="absolute bottom-full left-0 right-0 mb-2 bg-surface border border-main rounded-lg shadow-lg py-1 z-50">
            <button
              onClick={() => {
                router.push('/dashboard/settings');
                setIsOpen(false);
              }}
              className="w-full px-4 py-2 text-left text-sm text-main hover:bg-surface-hover flex items-center gap-2"
            >
              <Settings size={16} className="text-muted" />
              Settings
            </button>
            <hr className="my-1 border-main" />
            <button
              onClick={() => {
                onSignOut();
                setIsOpen(false);
              }}
              className="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 flex items-center gap-2"
            >
              <LogOut size={16} />
              Sign out
            </button>
          </div>
        </>
      )}
    </div>
  );
}

function ProModeToggle() {
  // Initialize from localStorage synchronously
  const [isOn, setIsOn] = useState(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('zafto_pro_mode') === 'true';
    }
    return false;
  });

  // Listen for changes from other components
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
    // Force re-render across app
    window.dispatchEvent(new CustomEvent('proModeChange', { detail: newValue }));
  };

  return (
    <button
      onClick={handleToggle}
      className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm font-medium transition-all ${
        isOn
          ? 'bg-gradient-to-r from-teal-600 to-cyan-600 text-white shadow-sm'
          : 'bg-surface-hover text-muted hover:text-main'
      }`}
    >
      <Sparkles size={14} />
      <span>PRO</span>
      <span className={`w-8 h-4 rounded-full relative transition-colors ${isOn ? 'bg-white/30' : 'bg-secondary'}`}>
        <span className={`absolute top-0.5 w-3 h-3 rounded-full bg-white shadow-sm transition-all duration-200 ${isOn ? 'left-4' : 'left-0.5'}`} />
      </span>
    </button>
  );
}
