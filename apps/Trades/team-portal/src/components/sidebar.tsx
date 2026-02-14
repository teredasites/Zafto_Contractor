'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { usePathname } from 'next/navigation';
import Link from 'next/link';
import {
  LayoutDashboard, Briefcase, Clock, Calendar, Camera, FileText,
  Package, CheckSquare, FileSignature, Bell, Settings, Wrench,
  Receipt, Menu, Sun, Moon, LogOut, X, Award, Building2, Calculator, Phone, Video,
  DollarSign, Car, GraduationCap, FolderOpen, Hammer,
} from 'lucide-react';
import { Logo } from '@/components/logo';
import { useTheme } from '@/components/theme-provider';
import { useAuth } from '@/components/auth-provider';
import { signOut } from '@/lib/auth';
import { cn, getInitials } from '@/lib/utils';

// ── Types ──

interface NavItem {
  name: string;
  href: string;
  icon: any;
}

interface NavGroup {
  label: string;
  key: string;
  railIcon: any;
  items: NavItem[];
}

// ── Navigation groups for field techs ──

const navigationGroups: NavGroup[] = [
  {
    label: 'Overview',
    key: 'overview',
    railIcon: LayoutDashboard,
    items: [
      { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
      { name: 'My Jobs', href: '/dashboard/jobs', icon: Briefcase },
      { name: 'Properties', href: '/dashboard/properties', icon: Building2 },
      { name: 'Schedule', href: '/dashboard/schedule', icon: Calendar },
      { name: 'Maintenance', href: '/dashboard/maintenance', icon: Hammer },
    ],
  },
  {
    label: 'Clock & Tools',
    key: 'clock',
    railIcon: Clock,
    items: [
      { name: 'Time Clock', href: '/dashboard/time-clock', icon: Clock },
      { name: 'Field Tools', href: '/dashboard/field-tools', icon: Wrench },
      { name: 'Calls', href: '/dashboard/phone', icon: Phone },
      { name: 'Meetings', href: '/dashboard/meetings', icon: Video },
    ],
  },
  {
    label: 'Documentation',
    key: 'docs',
    railIcon: FileText,
    items: [
      { name: 'Daily Log', href: '/dashboard/daily-log', icon: FileText },
      { name: 'Materials', href: '/dashboard/materials', icon: Package },
      { name: 'Punch List', href: '/dashboard/punch-list', icon: CheckSquare },
      { name: 'Change Orders', href: '/dashboard/change-orders', icon: FileSignature },
      { name: 'My Documents', href: '/dashboard/my-documents', icon: FolderOpen },
    ],
  },
  {
    label: 'My Stuff',
    key: 'my-stuff',
    railIcon: DollarSign,
    items: [
      { name: 'Pay Stubs', href: '/dashboard/pay-stubs', icon: DollarSign },
      { name: 'My Fleet', href: '/dashboard/my-vehicle', icon: Car },
      { name: 'Training', href: '/dashboard/training', icon: GraduationCap },
    ],
  },
  {
    label: 'Business',
    key: 'business',
    railIcon: Receipt,
    items: [
      { name: 'Estimates', href: '/dashboard/estimates', icon: Calculator },
      { name: 'Bids', href: '/dashboard/bids', icon: Receipt },
      { name: 'Certifications', href: '/dashboard/certifications', icon: Award },
      { name: 'Notifications', href: '/dashboard/notifications', icon: Bell },
    ],
  },
];

// ── Mobile section persistence ──

const MOBILE_KEY = 'zafto_team_sidebar_groups';

function loadMobileSections(): Record<string, boolean> {
  if (typeof window === 'undefined') return { overview: true };
  try {
    const s = localStorage.getItem(MOBILE_KEY);
    return s ? JSON.parse(s) : { overview: true };
  } catch { return { overview: true }; }
}

function saveMobileSections(v: Record<string, boolean>) {
  try { localStorage.setItem(MOBILE_KEY, JSON.stringify(v)); } catch { /* */ }
}

// ── Sidebar ──

export function Sidebar() {
  const pathname = usePathname();
  const { theme, toggleTheme } = useTheme();
  const { profile } = useAuth();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [activeGroup, setActiveGroup] = useState<string | null>(null);
  const [hoveredGroup, setHoveredGroup] = useState<string | null>(null);
  const [mobileSections, setMobileSections] = useState<Record<string, boolean>>({ overview: true });
  const railRef = useRef<HTMLElement>(null);
  const detailRef = useRef<HTMLDivElement>(null);
  const hoverTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => { setMobileSections(loadMobileSections()); }, []);

  // Close detail panel on route change
  useEffect(() => { setActiveGroup(null); setHoveredGroup(null); }, [pathname]);

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

  // Escape to close
  useEffect(() => {
    if (!activeGroup) return;
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') setActiveGroup(null); };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [activeGroup]);

  useEffect(() => {
    return () => { if (hoverTimeoutRef.current) clearTimeout(hoverTimeoutRef.current); };
  }, []);

  const handleSignOut = async () => { await signOut(); window.location.href = '/'; };

  const handleRailClick = useCallback((key: string) => {
    setActiveGroup(prev => prev === key ? null : key);
    setHoveredGroup(null);
  }, []);

  const handleRailHoverEnter = useCallback((key: string) => {
    if (hoverTimeoutRef.current) clearTimeout(hoverTimeoutRef.current);
    setHoveredGroup(key);
  }, []);

  const handleRailHoverLeave = useCallback(() => {
    hoverTimeoutRef.current = setTimeout(() => setHoveredGroup(null), 150);
  }, []);

  const toggleMobileSection = useCallback((key: string) => {
    setMobileSections(prev => {
      const next = { ...prev, [key]: !prev[key] };
      saveMobileSections(next);
      return next;
    });
  }, []);

  const isActive = (href: string) =>
    pathname === href || (href !== '/dashboard' && pathname.startsWith(href + '/'));

  const groupHasActiveChild = (group: NavGroup) => group.items.some(i => isActive(i.href));

  const currentDetailGroup = activeGroup ? navigationGroups.find(g => g.key === activeGroup) || null : null;

  const initials = profile?.displayName ? getInitials(profile.displayName) : '?';

  // ── Render a nav item ──
  const renderItem = (item: NavItem, onClose?: () => void) => {
    const active = isActive(item.href);
    return (
      <div key={item.name}>
        <Link
          href={item.href}
          onClick={() => { setActiveGroup(null); onClose?.(); }}
          className={cn(
            'flex items-center gap-3 px-3 py-[7px] rounded-md text-[13px] font-medium transition-colors relative',
            active
              ? 'text-accent bg-accent/5'
              : 'text-muted hover:text-main hover:bg-surface-hover',
          )}
        >
          {active && <span className="absolute left-0 top-1.5 bottom-1.5 w-[2px] rounded-full bg-accent" />}
          <item.icon size={16} className="flex-shrink-0" />
          <span>{item.name}</span>
        </Link>
      </div>
    );
  };

  return (
    <>
      {/* ═══ MOBILE ═══ */}

      {/* Mobile toggle */}
      <button
        onClick={() => setMobileOpen(true)}
        className="lg:hidden fixed top-3 left-3 z-50 p-2 rounded-lg bg-surface border border-main shadow-sm"
      >
        <Menu size={20} className="text-main" />
      </button>

      {/* Mobile overlay */}
      {mobileOpen && (
        <div className="lg:hidden fixed inset-0 z-50">
          <div className="absolute inset-0 bg-black/50" onClick={() => setMobileOpen(false)} />
          <aside className="absolute left-0 top-0 bottom-0 w-[280px] bg-surface border-r border-main shadow-xl flex flex-col">
            {/* Header */}
            <div className="flex items-center justify-between h-12 px-4 border-b border-main">
              <Link href="/dashboard" className="flex items-center gap-2" onClick={() => setMobileOpen(false)}>
                <Logo className="text-[15px] font-semibold text-accent" />
                <span className="text-[15px] font-semibold tracking-[0.02em] text-main">ZAFTO</span>
              </Link>
              <button onClick={() => setMobileOpen(false)} className="p-1.5 rounded-md hover:bg-surface-hover">
                <X size={16} className="text-muted" />
              </button>
            </div>

            {/* Nav */}
            <nav className="flex-1 py-2 overflow-y-auto scrollbar-hide">
              {navigationGroups.map(group => {
                const isOpen = mobileSections[group.key] ?? false;
                const hasActive = groupHasActiveChild(group);
                return (
                  <div key={group.key} className="mb-0.5">
                    <button
                      onClick={() => toggleMobileSection(group.key)}
                      className={cn(
                        'flex items-center justify-between w-full px-4 py-1.5 mt-1',
                        'text-[10px] font-semibold uppercase tracking-[0.08em]',
                        hasActive && !isOpen ? 'text-accent/60' : 'text-muted/40',
                        'hover:text-muted/70 transition-colors',
                      )}
                    >
                      <div className="flex items-center gap-2">
                        <group.railIcon size={12} className="flex-shrink-0" />
                        <span>{group.label}</span>
                      </div>
                      <svg
                        className={cn('w-3 h-3 transition-transform', isOpen ? 'rotate-0' : '-rotate-90')}
                        fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                      </svg>
                    </button>
                    <div className={cn(
                      'overflow-hidden transition-all duration-150 ease-out',
                      isOpen ? 'max-h-[400px] opacity-100' : 'max-h-0 opacity-0',
                    )}>
                      <div className="px-2 space-y-[1px]">
                        {group.items.map(item => renderItem(item, () => setMobileOpen(false)))}
                      </div>
                    </div>
                  </div>
                );
              })}
            </nav>

            {/* Footer */}
            <div className="p-3 border-t border-main space-y-2">
              <button onClick={toggleTheme} className="flex items-center gap-3 w-full px-3 py-2 rounded-lg text-sm text-muted hover:text-main hover:bg-surface-hover transition-colors">
                {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
                <span>{theme === 'dark' ? 'Light Mode' : 'Dark Mode'}</span>
              </button>
              <div className="flex items-center gap-3 px-3 py-2">
                <div className="w-8 h-8 rounded-full bg-accent/15 flex items-center justify-center text-xs font-semibold text-accent">
                  {initials}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-main truncate">{profile?.displayName || 'Team Member'}</p>
                  <p className="text-xs text-muted truncate">{profile?.role || 'tech'}</p>
                </div>
                <button onClick={handleSignOut} className="p-1.5 rounded-md hover:bg-surface-hover text-muted hover:text-main transition-colors" title="Sign out">
                  <LogOut size={14} />
                </button>
              </div>
            </div>
          </aside>
        </div>
      )}

      {/* ═══ DESKTOP — Supabase-style rail + flyout ═══ */}

      {/* Icon Rail */}
      <aside
        ref={railRef}
        className="fixed top-0 left-0 z-40 h-full w-12 bg-surface border-r border-main/50 flex-col hidden lg:flex"
      >
        {/* Logo */}
        <div className="h-12 flex items-center justify-center border-b border-main flex-shrink-0">
          <Link href="/dashboard">
            <span className="text-[14px] font-bold text-accent">Z<span className="text-accent/60">.</span></span>
          </Link>
        </div>

        {/* Group icons */}
        <div className="flex-1 py-2 px-1.5 space-y-0.5 overflow-y-auto scrollbar-hide">
          {navigationGroups.map(group => {
            const isOpen = activeGroup === group.key;
            const hasActive = groupHasActiveChild(group);
            const isHovered = hoveredGroup === group.key;
            const RailIcon = group.railIcon;

            return (
              <div key={group.key} className="relative">
                <button
                  onClick={() => handleRailClick(group.key)}
                  onMouseEnter={() => handleRailHoverEnter(group.key)}
                  onMouseLeave={handleRailHoverLeave}
                  className={cn(
                    'w-full flex items-center justify-center py-2 rounded-md transition-colors relative',
                    isOpen
                      ? 'bg-accent/10 text-accent'
                      : hasActive
                        ? 'text-accent'
                        : 'text-muted hover:text-main hover:bg-surface-hover',
                  )}
                >
                  {(isOpen || hasActive) && (
                    <span className="absolute left-0 top-1 bottom-1 w-[2px] rounded-full bg-accent" />
                  )}
                  <RailIcon size={18} />
                </button>

                {/* Hover flyout label */}
                {isHovered && !isOpen && (
                  <div className="absolute left-full top-1/2 -translate-y-1/2 ml-3 px-3 py-1.5 bg-surface border border-main rounded-lg shadow-xl z-50 whitespace-nowrap sidebar-flyout-enter pointer-events-none">
                    <span className="text-[13px] font-medium text-main">{group.label}</span>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Bottom: Theme + Settings + Sign Out + User */}
        <div className="border-t border-main/40 px-1.5 py-2 space-y-0.5">
          {/* Theme toggle */}
          <button
            onClick={toggleTheme}
            onMouseEnter={() => setHoveredGroup('__theme')}
            onMouseLeave={handleRailHoverLeave}
            className="relative w-full flex items-center justify-center py-2 rounded-md text-muted hover:text-main hover:bg-surface-hover transition-colors"
          >
            {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
            {hoveredGroup === '__theme' && (
              <div className="absolute left-full ml-3 px-3 py-1.5 bg-surface border border-main rounded-lg shadow-xl z-50 whitespace-nowrap sidebar-flyout-enter pointer-events-none">
                <span className="text-[13px] font-medium text-main">{theme === 'dark' ? 'Light Mode' : 'Dark Mode'}</span>
              </div>
            )}
          </button>

          {/* Settings */}
          <Link
            href="/dashboard/settings"
            onMouseEnter={() => setHoveredGroup('__settings')}
            onMouseLeave={handleRailHoverLeave}
            className={cn(
              'relative flex items-center justify-center py-2 rounded-md transition-colors',
              pathname === '/dashboard/settings' ? 'text-accent bg-accent/10' : 'text-muted hover:text-main hover:bg-surface-hover',
            )}
          >
            <Settings size={18} />
            {hoveredGroup === '__settings' && (
              <div className="absolute left-full ml-3 px-3 py-1.5 bg-surface border border-main rounded-lg shadow-xl z-50 whitespace-nowrap sidebar-flyout-enter pointer-events-none">
                <span className="text-[13px] font-medium text-main">Settings</span>
              </div>
            )}
          </Link>

          {/* Sign out */}
          <button
            onClick={handleSignOut}
            onMouseEnter={() => setHoveredGroup('__signout')}
            onMouseLeave={handleRailHoverLeave}
            className="relative w-full flex items-center justify-center py-2 rounded-md text-muted hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors"
          >
            <LogOut size={18} />
            {hoveredGroup === '__signout' && (
              <div className="absolute left-full ml-3 px-3 py-1.5 bg-surface border border-main rounded-lg shadow-xl z-50 whitespace-nowrap sidebar-flyout-enter pointer-events-none">
                <span className="text-[13px] font-medium text-main">Sign out</span>
              </div>
            )}
          </button>

          {/* User avatar */}
          <div className="flex justify-center pt-1">
            <div className="w-7 h-7 rounded-full bg-accent/10 flex items-center justify-center">
              <span className="text-accent text-[10px] font-semibold">{initials}</span>
            </div>
          </div>
        </div>
      </aside>

      {/* Detail Panel — slides out */}
      {activeGroup && currentDetailGroup && (
        <div
          ref={detailRef}
          className="fixed top-0 left-12 z-[45] h-full w-[220px] bg-surface border-r border-main shadow-xl hidden lg:flex flex-col sidebar-detail-enter"
        >
          <div className="h-12 flex items-center justify-between px-4 border-b border-main flex-shrink-0">
            <span className="text-[13px] font-semibold tracking-[0.02em] text-main">
              {currentDetailGroup.label}
            </span>
            <button
              onClick={() => setActiveGroup(null)}
              className="p-1 text-muted hover:text-main rounded-md hover:bg-surface-hover transition-colors"
            >
              <X size={14} />
            </button>
          </div>
          <nav className="flex-1 py-2 px-2 overflow-y-auto scrollbar-hide space-y-[1px]">
            {currentDetailGroup.items.map(item => renderItem(item))}
          </nav>
        </div>
      )}
    </>
  );
}
