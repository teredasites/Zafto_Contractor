'use client';

import { usePathname } from 'next/navigation';
import Link from 'next/link';
import {
  LayoutDashboard, Briefcase, Clock, Calendar, Camera, FileText,
  Package, CheckSquare, FileSignature, Bell, Settings, Wrench,
  Receipt, ChevronLeft, Menu, Sun, Moon, LogOut, X, Award, Building2, Calculator, Phone, Video,
  DollarSign, Car, GraduationCap, FolderOpen,
} from 'lucide-react';
import { Logo } from '@/components/logo';
import { useTheme } from '@/components/theme-provider';
import { useAuth } from '@/components/auth-provider';
import { signOut } from '@/lib/auth';
import { cn, getInitials } from '@/lib/utils';
import { useState } from 'react';

const navItems = [
  { label: 'OVERVIEW', items: [
    { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
    { name: 'My Jobs', href: '/dashboard/jobs', icon: Briefcase },
    { name: 'Properties', href: '/dashboard/properties', icon: Building2 },
    { name: 'Schedule', href: '/dashboard/schedule', icon: Calendar },
  ]},
  { label: 'CLOCK & TOOLS', items: [
    { name: 'Time Clock', href: '/dashboard/time-clock', icon: Clock },
    { name: 'Field Tools', href: '/dashboard/field-tools', icon: Wrench },
    { name: 'Phone', href: '/dashboard/phone', icon: Phone },
    { name: 'Meetings', href: '/dashboard/meetings', icon: Video },
  ]},
  { label: 'DOCUMENTATION', items: [
    { name: 'Daily Log', href: '/dashboard/daily-log', icon: FileText },
    { name: 'Materials', href: '/dashboard/materials', icon: Package },
    { name: 'Punch List', href: '/dashboard/punch-list', icon: CheckSquare },
    { name: 'Change Orders', href: '/dashboard/change-orders', icon: FileSignature },
    { name: 'My Documents', href: '/dashboard/my-documents', icon: FolderOpen },
  ]},
  { label: 'MY STUFF', items: [
    { name: 'Pay Stubs', href: '/dashboard/pay-stubs', icon: DollarSign },
    { name: 'My Fleet', href: '/dashboard/my-vehicle', icon: Car },
    { name: 'Training', href: '/dashboard/training', icon: GraduationCap },
  ]},
  { label: 'BUSINESS', items: [
    { name: 'Estimates', href: '/dashboard/estimates', icon: Calculator },
    { name: 'Bids', href: '/dashboard/bids', icon: Receipt },
    { name: 'Certifications', href: '/dashboard/certifications', icon: Award },
    { name: 'Notifications', href: '/dashboard/notifications', icon: Bell },
    { name: 'Settings', href: '/dashboard/settings', icon: Settings },
  ]},
];

export function Sidebar() {
  const pathname = usePathname();
  const { theme, toggleTheme } = useTheme();
  const { profile } = useAuth();
  const [mobileOpen, setMobileOpen] = useState(false);

  const handleSignOut = async () => {
    await signOut();
    window.location.href = '/';
  };

  const sidebarContent = (
    <div className="flex flex-col h-full">
      <div className="px-4 py-4 border-b border-main">
        <Logo className="text-lg font-bold tracking-tight text-main" />
      </div>

      <nav className="flex-1 overflow-y-auto py-3 px-2 space-y-5">
        {navItems.map((section) => (
          <div key={section.label}>
            <div className="px-3 mb-1.5 text-[10px] font-semibold tracking-widest uppercase text-muted">
              {section.label}
            </div>
            <div className="space-y-0.5">
              {section.items.map((item) => {
                const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setMobileOpen(false)}
                    className={cn(
                      'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                      isActive
                        ? 'bg-accent/10 text-accent border-l-2 border-accent'
                        : 'text-muted hover:text-main hover:bg-surface-hover'
                    )}
                  >
                    <item.icon size={18} className="flex-shrink-0" />
                    <span>{item.name}</span>
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      <div className="p-3 border-t border-main space-y-2">
        <button onClick={toggleTheme} className="flex items-center gap-3 w-full px-3 py-2 rounded-lg text-sm text-muted hover:text-main hover:bg-surface-hover transition-colors">
          {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
          <span>{theme === 'dark' ? 'Light Mode' : 'Dark Mode'}</span>
        </button>

        <div className="flex items-center gap-3 px-3 py-2">
          <div className="w-8 h-8 rounded-full bg-accent/15 flex items-center justify-center text-xs font-semibold text-accent">
            {profile?.displayName ? getInitials(profile.displayName) : '?'}
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
    </div>
  );

  return (
    <>
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
          <div className="absolute left-0 top-0 bottom-0 w-[260px] bg-surface border-r border-main shadow-xl">
            <button onClick={() => setMobileOpen(false)} className="absolute top-3 right-3 p-1.5 rounded-md hover:bg-surface-hover">
              <X size={16} className="text-muted" />
            </button>
            {sidebarContent}
          </div>
        </div>
      )}

      {/* Desktop sidebar */}
      <aside className="hidden lg:flex lg:flex-col lg:w-[240px] lg:fixed lg:inset-y-0 bg-surface border-r border-main">
        {sidebarContent}
      </aside>
    </>
  );
}
