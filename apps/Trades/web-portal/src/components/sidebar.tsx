'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
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
  ClipboardList,
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
  TrendingUp,
  Menu,
  Phone,
  Printer,
  Video,
  Droplets,
  Wind,
  PenTool,
  Ruler,
  MapPin,
  Car,
  Banknote as BanknoteIcon,
  UserCog,
  Mail,
  Truck,
  GraduationCap,
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
  key: string;
  railIcon: any | null; // null = special rendering (ZMark)
  items: NavItem[];
}

const navigationGroups: NavGroup[] = [
  {
    label: 'WORK',
    key: 'work',
    railIcon: Briefcase,
    items: [
      { name: 'Leads', href: '/dashboard/leads', icon: Target },
      { name: 'Bids', href: '/dashboard/bids', icon: FileText },
      { name: 'Estimates', href: '/dashboard/estimates', icon: Calculator },
      { name: 'Jobs', href: '/dashboard/jobs', icon: Briefcase },
      { name: 'Change Orders', href: '/dashboard/change-orders', icon: ArrowRightLeft },
      { name: 'Walkthroughs', href: '/dashboard/walkthroughs', icon: ClipboardList },
      { name: 'Invoices', href: '/dashboard/invoices', icon: Receipt },
    ],
  },
  {
    label: 'SCHEDULING',
    key: 'scheduling',
    railIcon: Calendar,
    items: [
      { name: 'Calendar', href: '/dashboard/calendar', icon: Calendar },
      { name: 'Meetings', href: '/dashboard/meetings', icon: Video },
      { name: 'Inspections', href: '/dashboard/inspections', icon: ClipboardCheck },
      { name: 'Inspection Engine', href: '/dashboard/inspection-engine', icon: Shield },
      { name: 'OSHA Standards', href: '/dashboard/osha-standards', icon: FileCheck2 },
      { name: 'Permits', href: '/dashboard/permits', icon: FileCheck2 },
      { name: 'Time Clock', href: '/dashboard/time-clock', icon: Clock, permission: PERMISSIONS.TIMECLOCK_VIEW_ALL },
    ],
  },
  {
    label: 'CUSTOMERS',
    key: 'customers',
    railIcon: Users,
    items: [
      { name: 'Customers', href: '/dashboard/customers', icon: Users },
      { name: 'Communications', href: '/dashboard/communications', icon: MessageSquare },
      { name: 'Team Chat', href: '/dashboard/team-chat', icon: MessageSquare },
      { name: 'Phone', href: '/dashboard/phone', icon: Phone },
      { name: 'Messages', href: '/dashboard/phone/sms', icon: MessageSquare },
      { name: 'Fax', href: '/dashboard/phone/fax', icon: Printer },
      { name: 'Service Agreements', href: '/dashboard/service-agreements', icon: Handshake },
      { name: 'Warranties', href: '/dashboard/warranties', icon: Shield },
    ],
  },
  {
    label: 'INSURANCE',
    key: 'insurance',
    railIcon: Umbrella,
    items: [
      { name: 'Claims', href: '/dashboard/insurance', icon: Umbrella },
      { name: 'Moisture Readings', href: '/dashboard/moisture-readings', icon: Droplets },
      { name: 'Drying Logs', href: '/dashboard/drying-logs', icon: Wind },
      { name: 'Site Surveys', href: '/dashboard/site-surveys', icon: MapPin },
      { name: 'Sketch + Bid', href: '/dashboard/sketch-bid', icon: PenTool },
    ],
  },
  {
    label: 'TEAM & RESOURCES',
    key: 'resources',
    railIcon: HardHat,
    items: [
      { name: 'Team', href: '/dashboard/team', icon: Users },
      { name: 'Certifications', href: '/dashboard/certifications', icon: Award, permission: PERMISSIONS.CERTIFICATIONS_VIEW },
      { name: 'Equipment', href: '/dashboard/equipment', icon: Wrench },
      { name: 'Inventory', href: '/dashboard/inventory', icon: Package },
      { name: 'Vendors', href: '/dashboard/vendors', icon: Store },
      { name: 'Purchase Orders', href: '/dashboard/purchase-orders', icon: ShoppingCart },
      { name: 'Fleet', href: '/dashboard/fleet', icon: Truck },
      { name: 'HR', href: '/dashboard/hr', icon: UserCog },
      { name: 'Payroll', href: '/dashboard/payroll', icon: BanknoteIcon, permission: PERMISSIONS.FINANCIALS_VIEW },
      { name: 'Training', href: '/dashboard/hr', icon: GraduationCap },
      { name: 'Hiring', href: '/dashboard/hiring', icon: UserCog },
      { name: 'Marketplace', href: '/dashboard/marketplace', icon: Store },
    ],
  },
  {
    label: 'OFFICE',
    key: 'office',
    railIcon: BookOpen,
    items: [
      { name: 'ZBooks', href: '/dashboard/books', icon: DollarSign },
      { name: 'Price Book', href: '/dashboard/price-book', icon: BookOpen },
      { name: 'ZDocs', href: '/dashboard/zdocs', icon: FileText },
      { name: 'Documents', href: '/dashboard/documents', icon: FolderOpen },
      { name: 'Reports', href: '/dashboard/reports', icon: BarChart3 },
      { name: 'Revenue', href: '/dashboard/revenue-insights', icon: TrendingUp },
      { name: 'Automations', href: '/dashboard/automations', icon: Zap },
      { name: 'Growth', href: '/dashboard/growth', icon: Rocket },
      { name: 'Email', href: '/dashboard/email', icon: Mail },
    ],
  },
  {
    label: 'PROPERTIES',
    key: 'properties',
    railIcon: Building2,
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
    key: 'z-intelligence',
    railIcon: null, // Uses ZMark component
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

// Mobile collapsible group state
const MOBILE_STORAGE_KEY = 'zafto_sidebar_groups';
const DEFAULT_MOBILE_OPEN: Record<string, boolean> = { work: true };

function loadMobileGroupState(): Record<string, boolean> {
  if (typeof window === 'undefined') return DEFAULT_MOBILE_OPEN;
  try {
    const stored = localStorage.getItem(MOBILE_STORAGE_KEY);
    if (stored) return JSON.parse(stored);
  } catch { /* ignore */ }
  return DEFAULT_MOBILE_OPEN;
}

function saveMobileGroupState(state: Record<string, boolean>) {
  try {
    localStorage.setItem(MOBILE_STORAGE_KEY, JSON.stringify(state));
  } catch { /* ignore */ }
}

interface SidebarProps {
  mobileOpen: boolean;
  onMobileClose: () => void;
  user: User | null;
  onSignOut: () => void;
}

export function Sidebar({
  mobileOpen,
  onMobileClose,
  user,
  onSignOut,
}: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const [activeGroup, setActiveGroup] = useState<string | null>(null);
  const [mobileGroups, setMobileGroups] = useState<Record<string, boolean>>(DEFAULT_MOBILE_OPEN);
  const railRef = useRef<HTMLElement>(null);
  const detailRef = useRef<HTMLElement>(null);

  const initials = user?.email
    ? user.email.substring(0, 2).toUpperCase()
    : 'U';

  // Load mobile group state
  useEffect(() => {
    setMobileGroups(loadMobileGroupState());
  }, []);

  // Close detail panel on route change
  useEffect(() => {
    setActiveGroup(null);
  }, [pathname]);

  // Click outside to close detail panel
  useEffect(() => {
    if (!activeGroup) return;
    const handler = (e: MouseEvent) => {
      const target = e.target as Node;
      if (railRef.current?.contains(target) || detailRef.current?.contains(target)) return;
      setActiveGroup(null);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [activeGroup]);

  // Escape key to close detail panel
  useEffect(() => {
    if (!activeGroup) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setActiveGroup(null);
    };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [activeGroup]);

  const handleRailClick = useCallback((key: string) => {
    setActiveGroup(prev => prev === key ? null : key);
  }, []);

  const toggleMobileGroup = useCallback((key: string) => {
    setMobileGroups(prev => {
      const next = { ...prev, [key]: !prev[key] };
      saveMobileGroupState(next);
      return next;
    });
  }, []);

  const isItemActive = (item: NavItem) =>
    pathname === item.href ||
    (item.href !== '/dashboard' && pathname.startsWith(item.href + '/'));

  const groupHasActiveChild = (group: NavGroup) =>
    group.items.some(isItemActive);

  const currentGroup = navigationGroups.find(g => g.key === activeGroup) || null;

  // ── Render helpers ──

  const renderDetailItem = (item: NavItem) => {
    const active = isItemActive(item);
    const link = (
      <Link
        key={item.name}
        href={item.href}
        onClick={() => { setActiveGroup(null); onMobileClose(); }}
        className={cn(
          'flex items-center gap-3 px-3 py-[7px] rounded-md text-[13px] font-medium transition-colors',
          active
            ? 'text-accent bg-accent/5'
            : 'text-muted hover:text-main hover:bg-surface-hover',
        )}
      >
        {item.icon === ZMark ? (
          <ZMark size={15} className={cn('flex-shrink-0', active && 'text-accent')} />
        ) : (
          <item.icon size={16} className="flex-shrink-0" />
        )}
        <span>{item.name}</span>
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

  const renderMobileItem = (item: NavItem) => {
    const active = isItemActive(item);
    const link = (
      <Link
        key={item.name}
        href={item.href}
        onClick={onMobileClose}
        className={cn(
          'flex items-center gap-3 px-3 py-[7px] rounded-md text-[13px] font-medium transition-colors',
          active
            ? 'text-accent bg-accent/5'
            : 'text-muted hover:text-main hover:bg-surface-hover',
        )}
      >
        {item.icon === ZMark ? (
          <ZMark size={15} className={cn('flex-shrink-0', active && 'text-accent')} />
        ) : (
          <item.icon size={16} className="flex-shrink-0" />
        )}
        <span>{item.name}</span>
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

  return (
    <>
      {/* ═══════════════════════════════════════════
          MOBILE SIDEBAR — Full overlay drawer
          ═══════════════════════════════════════════ */}

      {/* Mobile backdrop */}
      {mobileOpen && (
        <div
          className="fixed inset-0 bg-black/20 dark:bg-black/50 z-40 lg:hidden"
          onClick={onMobileClose}
        />
      )}

      {/* Mobile sidebar */}
      <aside
        className={cn(
          'fixed top-0 left-0 z-50 h-full w-[280px] bg-surface border-r border-main flex flex-col',
          'transform transition-transform duration-200 ease-out lg:hidden',
          mobileOpen ? 'translate-x-0' : '-translate-x-full',
        )}
      >
        {/* Mobile header */}
        <div className="flex items-center justify-between h-14 px-4 border-b border-main">
          <Link href="/dashboard" className="flex items-center" onClick={onMobileClose}>
            <span className="text-[17px] font-semibold tracking-[0.04em] text-main">ZAFTO</span>
          </Link>
          <button
            className="p-1.5 text-muted hover:text-main rounded-md hover:bg-surface-hover transition-colors"
            onClick={onMobileClose}
          >
            <X size={18} />
          </button>
        </div>

        {/* Mobile navigation — collapsible groups */}
        <nav className="flex-1 py-3 overflow-y-auto scrollbar-hide">
          {/* Dashboard — always pinned */}
          <div className="px-2 mb-1">
            <Link
              href="/dashboard"
              onClick={onMobileClose}
              className={cn(
                'flex items-center gap-3 px-3 py-[7px] rounded-md text-[13px] font-medium transition-colors',
                pathname === '/dashboard'
                  ? 'text-accent bg-accent/5'
                  : 'text-muted hover:text-main hover:bg-surface-hover',
              )}
            >
              <LayoutDashboard size={18} className="flex-shrink-0" />
              <span>Dashboard</span>
            </Link>
          </div>

          {/* Collapsible groups for mobile */}
          {navigationGroups.map(group => {
            const isOpen = mobileGroups[group.key] ?? false;
            const hasActive = groupHasActiveChild(group);

            return (
              <div key={group.key} className="mb-0.5">
                <button
                  onClick={() => toggleMobileGroup(group.key)}
                  className={cn(
                    'flex items-center justify-between w-full px-4 py-1.5 mt-1',
                    'text-[10px] font-semibold uppercase tracking-[0.08em] transition-colors',
                    hasActive && !isOpen ? 'text-accent/60' : 'text-muted/40',
                    'hover:text-muted/70',
                  )}
                >
                  <span>{group.label}</span>
                  <ChevronDown
                    size={12}
                    className={cn(
                      'transition-transform duration-150 flex-shrink-0',
                      isOpen ? 'rotate-0' : '-rotate-90',
                    )}
                  />
                </button>
                <div
                  className={cn(
                    'overflow-hidden transition-all duration-150 ease-out',
                    isOpen ? 'max-h-[500px] opacity-100' : 'max-h-0 opacity-0',
                  )}
                >
                  <div className="px-2 space-y-[1px]">
                    {group.items.map(renderMobileItem)}
                  </div>
                </div>
              </div>
            );
          })}
        </nav>

        {/* Mobile footer */}
        <div className="border-t border-main p-2 space-y-0.5">
          <Link
            href="/dashboard/settings"
            onClick={onMobileClose}
            className={cn(
              'flex items-center gap-3 px-3 py-[7px] rounded-md text-[13px] font-medium transition-colors',
              pathname === '/dashboard/settings'
                ? 'text-accent'
                : 'text-muted hover:text-main hover:bg-surface-hover',
            )}
          >
            <Settings size={18} className="flex-shrink-0" />
            <span>Settings</span>
          </Link>
          <button
            onClick={onSignOut}
            className="w-full flex items-center gap-3 px-3 py-[7px] rounded-md text-[13px] font-medium text-muted hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors"
          >
            <LogOut size={18} className="flex-shrink-0" />
            <span>Sign out</span>
          </button>
        </div>
      </aside>

      {/* ═══════════════════════════════════════════
          DESKTOP — Dual-rail (Supabase-style)
          Icon rail (48px) + slide-out detail panel
          ═══════════════════════════════════════════ */}

      {/* Icon Rail — always visible */}
      <aside
        ref={railRef}
        className="fixed top-0 left-0 z-40 h-full w-12 bg-surface border-r border-main/50 flex-col hidden lg:flex"
      >
        {/* Logo */}
        <div className="h-14 flex items-center justify-center border-b border-main flex-shrink-0">
          <Link href="/dashboard">
            <Logo size={22} className="text-main flex-shrink-0" animated={false} />
          </Link>
        </div>

        {/* Dashboard — direct link, always visible */}
        <div className="px-1.5 pt-2 pb-1">
          <Link
            href="/dashboard"
            title="Dashboard"
            className={cn(
              'flex items-center justify-center py-2 rounded-md transition-colors',
              pathname === '/dashboard'
                ? 'text-accent bg-accent/10'
                : 'text-muted hover:text-main hover:bg-surface-hover',
            )}
          >
            <LayoutDashboard size={18} />
          </Link>
        </div>

        {/* Divider */}
        <div className="mx-2.5 border-t border-main/50" />

        {/* Group icons */}
        <div className="flex-1 py-1.5 px-1.5 space-y-0.5 overflow-y-auto scrollbar-hide">
          {navigationGroups.map(group => {
            const isOpen = activeGroup === group.key;
            const hasActive = groupHasActiveChild(group);
            const RailIcon = group.railIcon;

            return (
              <button
                key={group.key}
                onClick={() => handleRailClick(group.key)}
                title={group.label}
                className={cn(
                  'w-full flex items-center justify-center py-2 rounded-md transition-colors',
                  isOpen
                    ? 'bg-accent/10 text-accent'
                    : hasActive
                      ? 'text-accent'
                      : 'text-muted hover:text-main hover:bg-surface-hover',
                )}
              >
                {RailIcon ? (
                  <RailIcon size={18} />
                ) : (
                  <ZMark size={16} className={cn(isOpen || hasActive ? 'text-accent' : '')} />
                )}
              </button>
            );
          })}
        </div>

        {/* Divider */}
        <div className="mx-2.5 border-t border-main/50" />

        {/* Bottom: Settings + Sign Out + User */}
        <div className="px-1.5 py-2 space-y-0.5">
          <Link
            href="/dashboard/settings"
            title="Settings"
            className={cn(
              'flex items-center justify-center py-2 rounded-md transition-colors',
              pathname === '/dashboard/settings'
                ? 'text-accent bg-accent/10'
                : 'text-muted hover:text-main hover:bg-surface-hover',
            )}
          >
            <Settings size={18} />
          </Link>
          <button
            onClick={onSignOut}
            title="Sign out"
            className="w-full flex items-center justify-center py-2 rounded-md text-muted hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors"
          >
            <LogOut size={18} />
          </button>
          {user && (
            <button
              onClick={() => router.push('/dashboard/settings')}
              title={user.email || 'Profile'}
              className="w-full flex justify-center py-1"
            >
              <div className="w-7 h-7 rounded-full bg-accent-light flex items-center justify-center">
                <span className="text-accent text-[10px] font-medium">{initials}</span>
              </div>
            </button>
          )}
        </div>
      </aside>

      {/* Detail Panel — slides out when a group is selected */}
      {activeGroup && currentGroup && (
        <aside
          ref={detailRef}
          className="fixed top-0 left-12 z-[45] h-full w-[220px] bg-surface border-r border-main shadow-xl hidden lg:flex flex-col sidebar-detail-enter"
        >
          {/* Panel header */}
          <div className="h-14 flex items-center justify-between px-4 border-b border-main flex-shrink-0">
            <span className="text-[13px] font-semibold tracking-[0.02em] text-main">
              {currentGroup.label}
            </span>
            <button
              onClick={() => setActiveGroup(null)}
              className="p-1 text-muted hover:text-main rounded-md hover:bg-surface-hover transition-colors"
            >
              <X size={14} />
            </button>
          </div>

          {/* Panel items */}
          <nav className="flex-1 py-2 px-2 overflow-y-auto scrollbar-hide space-y-[1px]">
            {currentGroup.items.map(renderDetailItem)}
          </nav>
        </aside>
      )}
    </>
  );
}
