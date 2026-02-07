'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  LayoutDashboard,
  FileText,
  Briefcase,
  Receipt,
  Calendar,
  Users,
  Settings,
  LogOut,
  X,
  ChevronDown,
  DollarSign,
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
  Clock,
  PanelLeftClose,
  PanelLeftOpen,
  Award,
  Building2,
  Home,
  KeyRound,
  ScrollText,
  Banknote,
  HardHat,
  ScanSearch,
  Cog,
  RotateCcw,
  Calculator,
  Umbrella,
} from 'lucide-react';
import { Logo } from '@/components/logo';
import { ZMark } from '@/components/z-console/z-mark';
import { PermissionGate, PERMISSIONS } from '@/components/permission-gate';
import { cn } from '@/lib/utils';
import type { User } from '@supabase/supabase-js';

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
    label: 'INSURANCE',
    items: [
      { name: 'Claims', href: '/dashboard/insurance', icon: Umbrella },
      { name: 'Estimate Writer', href: '/dashboard/estimates', icon: Calculator },
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
      { name: 'Certifications', href: '/dashboard/certifications', icon: Award, permission: PERMISSIONS.CERTIFICATIONS_VIEW },
      { name: 'Equipment', href: '/dashboard/equipment', icon: Wrench },
      { name: 'Inventory', href: '/dashboard/inventory', icon: Package },
      { name: 'Vendors', href: '/dashboard/vendors', icon: Store },
      { name: 'Purchase Orders', href: '/dashboard/purchase-orders', icon: ShoppingCart },
    ],
  },
  {
    label: 'OFFICE',
    items: [
      { name: 'ZBooks', href: '/dashboard/books', icon: DollarSign },
      { name: 'Price Book', href: '/dashboard/price-book', icon: BookOpen },
      { name: 'Documents', href: '/dashboard/documents', icon: FolderOpen },
      { name: 'Reports', href: '/dashboard/reports', icon: BarChart3 },
      { name: 'Automations', href: '/dashboard/automations', icon: Zap },
    ],
  },
  {
    label: 'PROPERTIES',
    items: [
      { name: 'Portfolio', href: '/dashboard/properties', icon: Building2 },
      { name: 'Units', href: '/dashboard/properties/units', icon: Home },
      { name: 'Tenants', href: '/dashboard/properties/tenants', icon: KeyRound },
      { name: 'Leases', href: '/dashboard/properties/leases', icon: ScrollText },
      { name: 'Rent', href: '/dashboard/properties/rent', icon: Banknote },
      { name: 'Maintenance', href: '/dashboard/properties/maintenance', icon: HardHat },
      { name: 'Inspections', href: '/dashboard/properties/inspections', icon: ScanSearch },
      { name: 'Assets', href: '/dashboard/properties/assets', icon: Cog },
      { name: 'Unit Turns', href: '/dashboard/properties/turns', icon: RotateCcw },
    ],
  },
  {
    label: 'Z INTELLIGENCE',
    items: [
      { name: 'Z AI', href: '/dashboard/z', icon: ZMark },
      { name: 'Z Voice', href: '/dashboard/z-voice', icon: Mic },
      { name: 'Bid Brain', href: '/dashboard/bid-brain', icon: Brain },
      { name: 'Job Cost Radar', href: '/dashboard/job-cost-radar', icon: Radar },
      { name: 'Equipment Memory', href: '/dashboard/equipment-memory', icon: Cpu },
      { name: 'Revenue Autopilot', href: '/dashboard/revenue-autopilot', icon: Rocket },
    ],
  },
];

interface SidebarProps {
  pinned: boolean;
  onPinnedChange: (pinned: boolean) => void;
  mobileOpen: boolean;
  onMobileClose: () => void;
  user: User | null;
  onSignOut: () => void;
}

export function Sidebar({
  pinned,
  onPinnedChange,
  mobileOpen,
  onMobileClose,
  user,
  onSignOut,
}: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const [hovered, setHovered] = useState(false);

  const expanded = pinned || hovered;

  const initials = user?.email
    ? user.email.substring(0, 2).toUpperCase()
    : 'U';

  const renderNavItem = (item: NavItem) => {
    const isActive = pathname === item.href ||
      (item.href !== '/dashboard' && pathname.startsWith(item.href + '/'));

    const link = (
      <Link
        key={item.name}
        href={item.href}
        title={!expanded ? item.name : undefined}
        onClick={onMobileClose}
        className={cn(
          'group relative flex items-center rounded-md text-[13px] font-medium transition-colors',
          expanded ? 'gap-3 px-3 py-[7px]' : 'justify-center px-0 py-[7px]',
          isActive
            ? 'text-accent'
            : 'text-muted hover:text-main hover:bg-surface-hover',
        )}
      >
        {isActive && (
          <span className="absolute left-0 top-1/2 -translate-y-1/2 w-[2px] h-4 bg-accent rounded-r" />
        )}
        <item.icon size={18} className="flex-shrink-0" />
        {expanded && (
          <span className="whitespace-nowrap overflow-hidden sidebar-label">
            {item.name}
          </span>
        )}
      </Link>
    );

    if (item.permission) {
      return (
        <PermissionGate key={item.name} permission={item.permission as any}>
          {link}
        </PermissionGate>
      );
    }

    return <div key={item.name}>{link}</div>;
  };

  const sidebarContent = (
    <>
      {/* Navigation */}
      <nav className="flex-1 py-3 overflow-y-auto scrollbar-hide">
        {navigationGroups.map((group) => (
          <div key={group.label} className="mb-1">
            {expanded && (
              <p className="px-4 mb-1 mt-2 first:mt-0 text-[10px] font-semibold uppercase tracking-[0.08em] text-muted/40 sidebar-label">
                {group.label}
              </p>
            )}
            {!expanded && group !== navigationGroups[0] && (
              <div className="mx-3 my-2 border-t border-main/50" />
            )}
            <div className={cn('space-y-[1px]', expanded ? 'px-2' : 'px-1.5')}>
              {group.items.map(renderNavItem)}
            </div>
          </div>
        ))}
      </nav>

      {/* Bottom section */}
      <div className="border-t border-main">
        {/* Settings */}
        <div className={cn('py-1.5', expanded ? 'px-2' : 'px-1.5')}>
          {(() => {
            const isActive = pathname === '/dashboard/settings';
            return (
              <Link
                href="/dashboard/settings"
                title={!expanded ? 'Settings' : undefined}
                className={cn(
                  'relative flex items-center rounded-md text-[13px] font-medium transition-colors',
                  expanded ? 'gap-3 px-3 py-[7px]' : 'justify-center py-[7px]',
                  isActive
                    ? 'text-accent'
                    : 'text-muted hover:text-main hover:bg-surface-hover',
                )}
              >
                {isActive && (
                  <span className="absolute left-0 top-1/2 -translate-y-1/2 w-[2px] h-4 bg-accent rounded-r" />
                )}
                <Settings size={18} className="flex-shrink-0" />
                {expanded && <span className="sidebar-label">Settings</span>}
              </Link>
            );
          })()}
          <button
            onClick={onSignOut}
            title={!expanded ? 'Sign out' : undefined}
            className={cn(
              'w-full relative flex items-center rounded-md text-[13px] font-medium text-muted hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors',
              expanded ? 'gap-3 px-3 py-[7px]' : 'justify-center py-[7px]',
            )}
          >
            <LogOut size={18} className="flex-shrink-0" />
            {expanded && <span className="sidebar-label">Sign out</span>}
          </button>
        </div>

        {/* User */}
        {user && (
          <div className={cn(
            'border-t border-main py-2',
            expanded ? 'px-3' : 'px-1.5',
          )}>
            {expanded ? (
              <button
                onClick={() => router.push('/dashboard/settings')}
                className="flex items-center gap-3 w-full px-2 py-1.5 rounded-md hover:bg-surface-hover transition-colors"
              >
                <div className="w-7 h-7 rounded-full bg-accent-light flex items-center justify-center flex-shrink-0">
                  <span className="text-accent text-xs font-medium">{initials}</span>
                </div>
                <div className="flex-1 text-left min-w-0">
                  <p className="text-[13px] font-medium text-main truncate sidebar-label">
                    {user.email}
                  </p>
                  <p className="text-[11px] text-muted sidebar-label">Owner</p>
                </div>
              </button>
            ) : (
              <button
                onClick={() => router.push('/dashboard/settings')}
                title={user.email || 'Profile'}
                className="flex justify-center w-full py-1"
              >
                <div className="w-7 h-7 rounded-full bg-accent-light flex items-center justify-center">
                  <span className="text-accent text-xs font-medium">{initials}</span>
                </div>
              </button>
            )}
          </div>
        )}
      </div>
    </>
  );

  return (
    <>
      {/* Mobile backdrop */}
      {mobileOpen && (
        <div
          className="fixed inset-0 bg-black/20 dark:bg-black/50 z-40 lg:hidden"
          onClick={onMobileClose}
        />
      )}

      {/* Mobile sidebar — full width, overlay */}
      <aside
        className={cn(
          'fixed top-0 left-0 z-50 h-full w-[280px] bg-surface border-r border-main flex flex-col',
          'transform transition-transform duration-200 ease-out lg:hidden',
          mobileOpen ? 'translate-x-0' : '-translate-x-full',
        )}
      >
        {/* Mobile header */}
        <div className="flex items-center justify-between h-14 px-4 border-b border-main">
          <Link href="/dashboard" className="flex items-center gap-2" onClick={onMobileClose}>
            <Logo size={24} className="text-main" animated={false} />
            <span className="text-base font-semibold text-main">Zafto</span>
          </Link>
          <button
            className="p-1.5 text-muted hover:text-main rounded-md hover:bg-surface-hover transition-colors"
            onClick={onMobileClose}
          >
            <X size={18} />
          </button>
        </div>

        {sidebarContent}
      </aside>

      {/* Desktop sidebar — collapsible icon rail */}
      <aside
        onMouseEnter={() => { if (!pinned) setHovered(true); }}
        onMouseLeave={() => { if (!pinned) setHovered(false); }}
        className={cn(
          'fixed top-0 left-0 z-40 h-full bg-surface border-r flex flex-col',
          'transition-[width] duration-200 ease-out',
          'hidden lg:flex',
          expanded ? 'w-[220px]' : 'w-12',
          !pinned && hovered && 'shadow-2xl z-50',
          // Border: subtle when collapsed, normal when expanded
          expanded ? 'border-main' : 'border-main/50',
        )}
      >
        {/* Desktop header */}
        <div className={cn(
          'flex items-center h-14 border-b border-main flex-shrink-0',
          expanded ? 'px-4 justify-between' : 'justify-center',
        )}>
          <Link href="/dashboard" className="flex items-center gap-2.5">
            <Logo size={22} className="text-main flex-shrink-0" animated={false} />
            {expanded && (
              <span className="text-[15px] font-semibold text-main whitespace-nowrap sidebar-label">
                Zafto
              </span>
            )}
          </Link>
          {expanded && (
            <button
              onClick={() => onPinnedChange(!pinned)}
              className="p-1 text-muted hover:text-main rounded-md hover:bg-surface-hover transition-colors"
              title={pinned ? 'Collapse sidebar' : 'Pin sidebar open'}
            >
              {pinned ? <PanelLeftClose size={16} /> : <PanelLeftOpen size={16} />}
            </button>
          )}
        </div>

        {sidebarContent}
      </aside>
    </>
  );
}
