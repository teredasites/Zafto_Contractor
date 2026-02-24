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
  MapPin,
  UserCog,
  Mail,
  Star,
  Truck,
  GraduationCap,
  FileBarChart,
  Satellite,
  PanelLeft,
  PanelLeftClose,
  Check,
  Radio,
  ShieldAlert,
  Scale,
  Package,
} from 'lucide-react';
import { Logo } from '@/components/logo';
import { ZMark } from '@/components/z-console/z-mark';
import { PermissionGate, PERMISSIONS } from '@/components/permission-gate';
import { cn } from '@/lib/utils';
import { useAuth } from '@/components/auth-provider';
import { useCompanyFeatures } from '@/lib/hooks/use-tpa-programs';
import { useTranslation } from '@/lib/translations';
import type { User } from '@supabase/supabase-js';

// ── Types ──

interface NavItem {
  name: string;
  href: string;
  icon: any; // LucideIcon or null (for ZMark)
  permission?: string;
}

interface NavGroup {
  label: string;
  key: string;
  railIcon: any; // Icon shown on the rail
  items: NavItem[];
  featureFlag?: string;
}

// ── Navigation groups ──
// Each group = one icon on the rail. Click → detail panel with sub-items.

const navigationGroups: NavGroup[] = [
  {
    label: 'Business',
    key: 'business',
    railIcon: Briefcase,
    items: [
      { name: 'Leads', href: '/dashboard/leads', icon: Target },
      { name: 'Bids', href: '/dashboard/bids', icon: FileText },
      { name: 'Estimates', href: '/dashboard/estimates', icon: Calculator },
      { name: 'Jobs', href: '/dashboard/jobs', icon: Briefcase },
      { name: 'Change Orders', href: '/dashboard/change-orders', icon: ArrowRightLeft },
      { name: 'Invoices', href: '/dashboard/invoices', icon: Receipt },
      { name: 'Customers', href: '/dashboard/customers', icon: Users },
      { name: 'Service Agreements', href: '/dashboard/service-agreements', icon: Handshake },
      { name: 'Warranties', href: '/dashboard/warranties', icon: Shield },
      { name: 'Warranty Intel', href: '/dashboard/warranty-intelligence', icon: ShieldAlert },
      { name: 'Reviews', href: '/dashboard/reviews', icon: Star },
    ],
  },
  {
    label: 'Finance',
    key: 'finance',
    railIcon: DollarSign,
    items: [
      { name: 'Ledger', href: '/dashboard/books', icon: DollarSign },
      { name: 'Reports', href: '/dashboard/reports', icon: BarChart3 },
      { name: 'Revenue', href: '/dashboard/revenue-insights', icon: TrendingUp },
      { name: 'Payroll', href: '/dashboard/payroll', icon: Banknote, permission: PERMISSIONS.FINANCIALS_VIEW },
      { name: 'Job Intelligence', href: '/dashboard/job-intelligence', icon: FileBarChart },
      { name: 'Job Cost Radar', href: '/dashboard/job-cost-radar', icon: Radar },
      { name: 'Pricing Rules', href: '/dashboard/pricing-settings', icon: Cog },
      { name: 'Pricing Analytics', href: '/dashboard/pricing-analytics', icon: BarChart3 },
    ],
  },
  {
    label: 'Operations',
    key: 'operations',
    railIcon: Calendar,
    items: [
      { name: 'Dispatch', href: '/dashboard/dispatch', icon: Radio },
      { name: 'Subcontractors', href: '/dashboard/subcontractors', icon: HardHat },
      { name: 'Calendar', href: '/dashboard/calendar', icon: Calendar },
      { name: 'Schedule', href: '/dashboard/scheduling', icon: ClipboardList },
      { name: 'Meetings', href: '/dashboard/meetings', icon: Video },
      { name: 'Time Clock', href: '/dashboard/time-clock', icon: Clock, permission: PERMISSIONS.TIMECLOCK_VIEW_ALL },
      { name: 'Inspections', href: '/dashboard/inspections', icon: ClipboardCheck },
      { name: 'Inspection Engine', href: '/dashboard/inspection-engine', icon: Shield },
      { name: 'OSHA Standards', href: '/dashboard/osha-standards', icon: FileCheck2 },
      { name: 'Permits', href: '/dashboard/permits', icon: FileCheck2 },
      { name: 'Jurisdictions', href: '/dashboard/permits/jurisdictions', icon: MapPin },
      { name: 'Compliance', href: '/dashboard/compliance', icon: Shield },
      { name: 'CE Tracking', href: '/dashboard/compliance/ce-tracking', icon: GraduationCap },
      { name: 'Compliance Packets', href: '/dashboard/compliance/packets', icon: Package },
      { name: 'Lien Protection', href: '/dashboard/lien-protection', icon: Scale },
      { name: 'Maintenance Pipeline', href: '/dashboard/maintenance-pipeline', icon: Wrench },
      { name: 'Property Preservation', href: '/dashboard/property-preservation', icon: Home },
    ],
  },
  {
    label: 'Comms',
    key: 'comms',
    railIcon: MessageSquare,
    items: [
      { name: 'Communications', href: '/dashboard/communications', icon: MessageSquare },
      { name: 'Team Chat', href: '/dashboard/team-chat', icon: MessageSquare },
      { name: 'Calls', href: '/dashboard/phone', icon: Phone },
      { name: 'Messages', href: '/dashboard/phone/sms', icon: MessageSquare },
      { name: 'Fax', href: '/dashboard/phone/fax', icon: Printer },
      { name: 'Email', href: '/dashboard/email', icon: Mail },
    ],
  },
  {
    label: 'Insurance',
    key: 'insurance',
    railIcon: Umbrella,
    items: [
      { name: 'Claims', href: '/dashboard/insurance', icon: Umbrella },
      { name: 'Moisture Readings', href: '/dashboard/moisture-readings', icon: Droplets },
      { name: 'Drying Logs', href: '/dashboard/drying-logs', icon: Wind },
      { name: 'Site Surveys', href: '/dashboard/site-surveys', icon: MapPin },
      { name: 'Sketch Engine', href: '/dashboard/sketch-engine', icon: PenTool },
    ],
  },
  {
    label: 'TPA Programs',
    key: 'tpa',
    railIcon: Shield,
    featureFlag: 'tpa_enabled',
    items: [
      { name: 'TPA Dashboard', href: '/dashboard/tpa', icon: BarChart3 },
      { name: 'Programs', href: '/dashboard/settings/tpa-programs', icon: Shield },
      { name: 'Assignments', href: '/dashboard/tpa/assignments', icon: ClipboardList },
      { name: 'Scorecards', href: '/dashboard/tpa/scorecards', icon: FileBarChart },
    ],
  },
  {
    label: 'Recon',
    key: 'recon',
    railIcon: Satellite,
    items: [
      { name: 'Property Scans', href: '/dashboard/recon', icon: Satellite },
      { name: 'Area Scans', href: '/dashboard/recon/area-scans', icon: MapPin },
    ],
  },
  {
    label: 'Team',
    key: 'team',
    railIcon: HardHat,
    items: [
      { name: 'Team', href: '/dashboard/team', icon: Users },
      { name: 'Certifications', href: '/dashboard/certifications', icon: Award, permission: PERMISSIONS.CERTIFICATIONS_VIEW },
      { name: 'Equipment', href: '/dashboard/equipment', icon: Wrench },
      { name: 'Tool Checkout', href: '/dashboard/tool-checkout', icon: Package },
      { name: 'Vendors', href: '/dashboard/vendors', icon: Store },
      { name: 'Purchase Orders', href: '/dashboard/purchase-orders', icon: ShoppingCart },
      { name: 'Fleet', href: '/dashboard/fleet', icon: Truck },
      { name: 'HR', href: '/dashboard/hr', icon: UserCog },
      { name: 'Hiring', href: '/dashboard/hiring', icon: UserCog },
      { name: 'Marketplace', href: '/dashboard/marketplace', icon: Store },
    ],
  },
  {
    label: 'Tools',
    key: 'tools',
    railIcon: Wrench,
    items: [
      { name: 'Walkthroughs', href: '/dashboard/walkthroughs', icon: ClipboardList },
      { name: 'ZForge', href: '/dashboard/zdocs', icon: FileText },
      { name: 'Documents', href: '/dashboard/documents', icon: FolderOpen },
      { name: 'Automations', href: '/dashboard/automations', icon: Zap },
      { name: 'Growth', href: '/dashboard/growth', icon: Rocket },
    ],
  },
  {
    label: 'Properties',
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
  // Z Intelligence — Phase E (AI). Hidden until AI layer is built.
  // Job Cost Radar moved to Finance group.
];

// ── CPA-only nav (minimal — finance only) ──

const cpaGroups: NavGroup[] = [
  {
    label: 'Overview',
    key: 'cpa-overview',
    railIcon: LayoutDashboard,
    items: [
      { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
    ],
  },
  {
    label: 'Finance',
    key: 'cpa-finance',
    railIcon: DollarSign,
    items: [
      { name: 'Ledger', href: '/dashboard/books', icon: DollarSign },
      { name: 'Reports', href: '/dashboard/reports', icon: BarChart3 },
      { name: 'Revenue', href: '/dashboard/revenue-insights', icon: TrendingUp },
      { name: 'Payroll', href: '/dashboard/payroll', icon: Banknote },
    ],
  },
];

// ── Mobile state persistence ──

const MOBILE_STORAGE_KEY = 'zafto_sidebar_groups';

function loadMobileGroupState(): Record<string, boolean> {
  if (typeof window === 'undefined') return { business: true };
  try {
    const stored = localStorage.getItem(MOBILE_STORAGE_KEY);
    if (stored) return JSON.parse(stored);
  } catch { /* */ }
  return { business: true };
}

function saveMobileGroupState(state: Record<string, boolean>) {
  try { localStorage.setItem(MOBILE_STORAGE_KEY, JSON.stringify(state)); } catch { /* */ }
}

// ── Sidebar mode persistence ──

type SidebarMode = 'expanded' | 'collapsed' | 'hover';
const SIDEBAR_MODE_KEY = 'zafto_sidebar_mode';

function isTouchDevice(): boolean {
  if (typeof window === 'undefined') return false;
  return 'ontouchstart' in window || navigator.maxTouchPoints > 0;
}

function loadSidebarMode(): SidebarMode {
  if (typeof window === 'undefined') return 'hover';
  try {
    const stored = localStorage.getItem(SIDEBAR_MODE_KEY) as SidebarMode | null;
    if (stored && ['expanded', 'collapsed', 'hover'].includes(stored)) return stored;
  } catch { /* */ }
  // Touch devices default to collapsed (no hover interactions)
  return isTouchDevice() ? 'collapsed' : 'hover';
}

function saveSidebarMode(mode: SidebarMode) {
  try {
    localStorage.setItem(SIDEBAR_MODE_KEY, mode);
    window.dispatchEvent(new Event('sidebarModeChange'));
  } catch { /* */ }
}

// ── Sidebar ──

interface SidebarProps {
  mobileOpen: boolean;
  onMobileClose: () => void;
  user: User | null;
  onSignOut: () => void;
}

// ── Nav item name → i18n key mapping ──
const navI18nKeys: Record<string, string> = {
  'Dashboard': 'nav.dashboard', 'Leads': 'nav.leads', 'Bids': 'nav.bids',
  'Estimates': 'nav.estimates', 'Jobs': 'nav.jobs', 'Change Orders': 'nav.changeOrders',
  'Invoices': 'nav.invoices', 'Customers': 'nav.customers', 'Service Agreements': 'nav.serviceAgreements',
  'Warranties': 'nav.warranties', 'Warranty Intel': 'nav.warrantyIntel', 'Reviews': 'nav.reviews',
  'Ledger': 'nav.ledger', 'Reports': 'nav.reports', 'Revenue': 'nav.revenue',
  'Payroll': 'nav.payroll', 'Job Intelligence': 'nav.jobIntelligence', 'Job Cost Radar': 'nav.jobCostRadar',
  'Pricing Rules': 'nav.pricingRules', 'Pricing Analytics': 'nav.pricingAnalytics',
  'Dispatch': 'nav.dispatch', 'Subcontractors': 'nav.subcontractors', 'Calendar': 'nav.calendar',
  'Schedule': 'nav.schedule', 'Meetings': 'nav.meetings', 'Time Clock': 'nav.timeClock',
  'Inspections': 'nav.inspections', 'Inspection Engine': 'nav.inspectionEngine',
  'OSHA Standards': 'nav.oshaStandards', 'Permits': 'nav.permits', 'Jurisdictions': 'nav.jurisdictions',
  'Compliance': 'nav.compliance', 'CE Tracking': 'nav.ceTracking', 'Compliance Packets': 'nav.compliancePackets',
  'Lien Protection': 'nav.lienProtection', 'Maintenance Pipeline': 'nav.maintenancePipeline',
  'Communications': 'nav.communications', 'Team Chat': 'nav.teamChat', 'Calls': 'nav.calls',
  'Messages': 'nav.messages', 'Fax': 'nav.fax', 'Email': 'nav.emailNav',
  'Claims': 'nav.claims', 'Moisture Readings': 'nav.moistureReadings', 'Drying Logs': 'nav.dryingLogs',
  'Site Surveys': 'nav.siteSurveys', 'Sketch Engine': 'nav.sketchEngine',
  'TPA Dashboard': 'nav.tpaDashboard', 'Programs': 'nav.programs', 'Assignments': 'nav.assignments',
  'Scorecards': 'nav.scorecards', 'Property Scans': 'nav.propertyScans', 'Area Scans': 'nav.areaScans',
  'Team': 'nav.team', 'Certifications': 'nav.certifications', 'Equipment': 'nav.equipment',
  'Tool Checkout': 'nav.toolCheckout', 'Vendors': 'nav.vendors', 'Purchase Orders': 'nav.purchaseOrders',
  'Fleet': 'nav.fleet', 'HR': 'nav.hr', 'Hiring': 'nav.hiring', 'Marketplace': 'nav.marketplace', 'Overview': 'nav.overview',
  'Walkthroughs': 'nav.walkthroughs', 'ZForge': 'nav.zforge', 'Documents': 'nav.documents',
  'Automations': 'nav.automations', 'Growth': 'nav.growth',
  'Portfolio': 'nav.portfolio', 'Units': 'nav.units', 'Tenants': 'nav.tenants',
  'Leases': 'nav.leases', 'Rent': 'nav.rent', 'Maintenance': 'nav.maintenance',
  'Assets': 'nav.assets', 'Unit Turns': 'nav.unitTurns',
  'Settings': 'nav.settings', 'Sign out': 'common.signOut',
  // Group labels
  'Business': 'nav.business', 'Finance': 'nav.finance', 'Operations': 'nav.operations',
  'Comms': 'nav.comms', 'Insurance': 'nav.insurance', 'TPA Programs': 'nav.tpa',
  'Recon': 'nav.recon', 'Tools': 'nav.tools', 'Properties': 'nav.properties',
};

export function Sidebar({ mobileOpen, onMobileClose, user, onSignOut }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const { t } = useTranslation();
  // Translate nav names: lookup i18n key, fallback to original English name
  const tn = useCallback((name: string) => {
    const key = navI18nKeys[name];
    if (!key) return name;
    const translated = t(key);
    return translated === key ? name : translated; // If key not found, use original
  }, [t]);
  const [activeGroup, setActiveGroup] = useState<string | null>(null);
  const [hoveredGroup, setHoveredGroup] = useState<string | null>(null);
  const [mobileGroups, setMobileGroups] = useState<Record<string, boolean>>({ business: true });
  const [sidebarMode, setSidebarMode] = useState<SidebarMode>('hover');
  const [railHovered, setRailHovered] = useState(false);
  const [controlOpen, setControlOpen] = useState(false);
  const railRef = useRef<HTMLElement>(null);
  const detailRef = useRef<HTMLDivElement>(null);
  const controlRef = useRef<HTMLDivElement>(null);
  const hoverTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const railHoverTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const { features } = useCompanyFeatures();
  const { profile } = useAuth();

  // Select groups based on role — CPA sees finance-only nav
  const baseGroups = profile?.role === 'cpa' ? cpaGroups : navigationGroups;

  // Filter groups by feature flags
  const visibleGroups = baseGroups.filter(g => {
    if (!g.featureFlag) return true;
    return features[g.featureFlag] === true;
  });

  const initials = user?.email ? user.email.substring(0, 2).toUpperCase() : 'U';

  // Is the sidebar currently showing expanded (wide) view?
  const isWide = sidebarMode === 'expanded' || (sidebarMode === 'hover' && railHovered);
  const sidebarWidth = isWide ? 220 : 48;

  // Hydrate sidebar mode + mobile state
  useEffect(() => {
    setSidebarMode(loadSidebarMode());
    setMobileGroups(loadMobileGroupState());
  }, []);

  const handleSetMode = useCallback((mode: SidebarMode) => {
    setSidebarMode(mode);
    saveSidebarMode(mode);
    setControlOpen(false);
    if (mode !== 'hover') setRailHovered(false);
    if (mode === 'expanded') setActiveGroup(null);
  }, []);

  // Rail hover handlers for "hover" mode
  const handleRailMouseEnter = useCallback(() => {
    if (railHoverTimeoutRef.current) clearTimeout(railHoverTimeoutRef.current);
    setRailHovered(true);
  }, []);

  const handleRailMouseLeave = useCallback(() => {
    railHoverTimeoutRef.current = setTimeout(() => {
      setRailHovered(false);
      setActiveGroup(null);
    }, 200);
  }, []);

  // Close detail panel on route change
  useEffect(() => {
    setActiveGroup(null);
    setHoveredGroup(null);
  }, [pathname]);

  // Close sidebar control popup on click outside
  useEffect(() => {
    if (!controlOpen) return;
    const handler = (e: MouseEvent) => {
      if (controlRef.current && !controlRef.current.contains(e.target as Node)) {
        setControlOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [controlOpen]);

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
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setActiveGroup(null);
    };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [activeGroup]);

  // Cleanup hover timeouts
  useEffect(() => {
    return () => {
      if (hoverTimeoutRef.current) clearTimeout(hoverTimeoutRef.current);
      if (railHoverTimeoutRef.current) clearTimeout(railHoverTimeoutRef.current);
    };
  }, []);

  const handleRailClick = useCallback((key: string) => {
    setActiveGroup(prev => prev === key ? null : key);
    setHoveredGroup(null);
  }, []);

  const handleRailHoverEnter = useCallback((key: string) => {
    if (hoverTimeoutRef.current) clearTimeout(hoverTimeoutRef.current);
    // Only show hover label if no detail panel is open, OR show it alongside
    setHoveredGroup(key);
  }, []);

  const handleRailHoverLeave = useCallback(() => {
    hoverTimeoutRef.current = setTimeout(() => {
      setHoveredGroup(null);
    }, 150);
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

  // Which panel is showing? Active click panel takes priority
  const currentDetailGroup = activeGroup
    ? visibleGroups.find(g => g.key === activeGroup) || null
    : null;

  // ── Render a nav item in the detail panel ──
  const renderDetailItem = (item: NavItem, onClose?: () => void) => {
    const active = isItemActive(item);
    const isZ = item.icon === null;

    const link = (
      <Link
        key={item.name}
        href={item.href}
        onClick={() => { setActiveGroup(null); onClose?.(); }}
        className={cn(
          'flex items-center gap-3 px-3 py-[7px] rounded-md text-[14px] font-medium transition-colors relative',
          active
            ? 'text-accent bg-accent/5'
            : 'text-muted hover:text-main hover:bg-surface-hover',
        )}
      >
        {active && (
          <span className="absolute left-0 top-1.5 bottom-1.5 w-[2px] rounded-full bg-accent" />
        )}
        {isZ ? (
          <ZMark size={17} className={cn('flex-shrink-0', active && 'text-accent')} />
        ) : (
          <item.icon size={18} className="flex-shrink-0" />
        )}
        <span>{tn(item.name)}</span>
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
          MOBILE — Full overlay drawer
          ═══════════════════════════════════════════ */}

      {mobileOpen && (
        <div
          className="fixed inset-0 bg-black/20 dark:bg-black/50 z-40 md:hidden"
          onClick={onMobileClose}
        />
      )}

      <aside
        className={cn(
          'fixed top-0 left-0 z-50 h-full w-[280px] bg-surface border-r border-main flex flex-col',
          'transform transition-transform duration-200 ease-out md:hidden',
          mobileOpen ? 'translate-x-0' : '-translate-x-full',
        )}
        aria-label="Main navigation"
        role="navigation"
      >
        {/* Mobile header */}
        <div className="flex items-center justify-between h-12 px-4 border-b border-main">
          <Link href="/dashboard" className="flex items-center gap-2" onClick={onMobileClose}>
            <Logo size={18} className="text-accent" animated={false} />
            <span className="text-[15px] font-semibold tracking-[0.02em] text-main">ZAFTO</span>
          </Link>
          <button
            className="p-1.5 text-muted hover:text-main rounded-md hover:bg-surface-hover transition-colors"
            onClick={onMobileClose}
            aria-label="Close navigation menu"
          >
            <X size={18} />
          </button>
        </div>

        {/* Mobile nav */}
        <nav className="flex-1 py-2 overflow-y-auto scrollbar-hide" aria-label="Mobile navigation">
          {/* Dashboard — pinned */}
          <div className="px-2 mb-1">
            <Link
              href="/dashboard"
              onClick={onMobileClose}
              className={cn(
                'flex items-center gap-3 px-3 py-[7px] rounded-md text-[14px] font-medium transition-colors relative',
                pathname === '/dashboard'
                  ? 'text-accent bg-accent/5'
                  : 'text-muted hover:text-main hover:bg-surface-hover',
              )}
            >
              {pathname === '/dashboard' && (
                <span className="absolute left-0 top-1.5 bottom-1.5 w-[2px] rounded-full bg-accent" />
              )}
              <LayoutDashboard size={16} className="flex-shrink-0" />
              <span>{tn('Dashboard')}</span>
            </Link>
          </div>

          {/* Collapsible groups */}
          {visibleGroups.map(group => {
            const isOpen = mobileGroups[group.key] ?? false;
            const hasActive = groupHasActiveChild(group);
            const RailIcon = group.railIcon;

            return (
              <div key={group.key} className="mb-0.5">
                <button
                  onClick={() => toggleMobileGroup(group.key)}
                  className={cn(
                    'flex items-center justify-between w-full px-4 py-1.5 mt-1',
                    'text-[12px] font-semibold uppercase tracking-[0.06em] transition-colors',
                    hasActive && !isOpen ? 'text-accent/60' : 'text-muted/40',
                    'hover:text-muted/70',
                  )}
                >
                  <div className="flex items-center gap-2.5">
                    {RailIcon ? (
                      <RailIcon size={14} className="flex-shrink-0" />
                    ) : (
                      <ZMark size={12} className="flex-shrink-0" />
                    )}
                    <span>{tn(group.label)}</span>
                  </div>
                  <ChevronDown
                    size={13}
                    className={cn(
                      'transition-transform duration-150 flex-shrink-0',
                      isOpen ? 'rotate-0' : '-rotate-90',
                    )}
                  />
                </button>
                <div
                  className={cn(
                    'overflow-hidden transition-all duration-150 ease-out',
                    isOpen ? 'max-h-[600px] opacity-100' : 'max-h-0 opacity-0',
                  )}
                >
                  <div className="px-2 space-y-[1px]">
                    {group.items.map(item => renderDetailItem(item, onMobileClose))}
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
              'flex items-center gap-3 px-3 py-[7px] rounded-md text-[14px] font-medium transition-colors',
              pathname === '/dashboard/settings' ? 'text-accent' : 'text-muted hover:text-main hover:bg-surface-hover',
            )}
          >
            <Settings size={16} className="flex-shrink-0" />
            <span>{tn('Settings')}</span>
          </Link>
          <button
            onClick={onSignOut}
            className="w-full flex items-center gap-3 px-3 py-[7px] rounded-md text-[14px] font-medium text-muted hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors"
          >
            <LogOut size={16} className="flex-shrink-0" />
            <span>{tn('Sign out')}</span>
          </button>
        </div>
      </aside>

      {/* ═══════════════════════════════════════════
          DESKTOP — Adaptive sidebar (expanded / collapsed / hover)
          Collapsed = 48px icon rail + click flyout
          Expanded = 220px sidebar with inline labels
          Hover = 48px → 220px on mouseenter
          ═══════════════════════════════════════════ */}

      <aside
        ref={railRef}
        onMouseEnter={sidebarMode === 'hover' ? handleRailMouseEnter : undefined}
        onMouseLeave={sidebarMode === 'hover' ? handleRailMouseLeave : undefined}
        className={cn(
          'fixed top-0 left-0 z-40 h-full bg-surface border-r border-main/50 flex-col hidden md:flex transition-[width] duration-200 ease-out overflow-hidden',
        )}
        style={{ width: sidebarWidth }}
        aria-label="Main navigation"
        role="navigation"
      >
        {/* Logo */}
        <div className="h-12 flex items-center border-b border-main flex-shrink-0 px-3 gap-2 min-w-0">
          <Link href="/dashboard" className="flex items-center gap-2 min-w-0">
            <Logo size={20} className="text-accent flex-shrink-0" animated={false} />
            {isWide && (
              <span className="text-[15px] font-semibold tracking-[0.02em] text-main whitespace-nowrap">ZAFTO</span>
            )}
          </Link>
        </div>

        {/* Dashboard — direct link */}
        <div className="px-1.5 pt-2 pb-1">
          <Link
            href="/dashboard"
            onMouseEnter={!isWide ? () => setHoveredGroup('__dashboard') : undefined}
            onMouseLeave={!isWide ? handleRailHoverLeave : undefined}
            className={cn(
              'relative flex items-center py-2 rounded-md transition-colors group',
              isWide ? 'px-3 gap-3' : 'justify-center',
              pathname === '/dashboard'
                ? 'text-accent bg-accent/10'
                : 'text-muted hover:text-main hover:bg-surface-hover',
            )}
          >
            {pathname === '/dashboard' && (
              <span className="absolute left-0 top-1 bottom-1 w-[2px] rounded-full bg-accent" />
            )}
            <LayoutDashboard size={20} className="flex-shrink-0" />
            {isWide && <span className="text-[14px] font-medium whitespace-nowrap">{tn('Dashboard')}</span>}
            {!isWide && hoveredGroup === '__dashboard' && !activeGroup && (
              <div className="absolute left-full ml-3 px-3 py-1.5 bg-surface border border-main rounded-lg shadow-xl z-50 whitespace-nowrap sidebar-flyout-enter pointer-events-none">
                <span className="text-[14px] font-medium text-main">{tn('Dashboard')}</span>
              </div>
            )}
          </Link>
        </div>

        {/* Divider */}
        <div className="mx-2.5 border-t border-main/40" />

        {/* Group icons / expanded groups */}
        <div className="flex-1 py-1.5 px-1.5 space-y-0.5 overflow-y-auto scrollbar-hide">
          {visibleGroups.map(group => {
            const isOpen = activeGroup === group.key;
            const hasActive = groupHasActiveChild(group);
            const isHovered = hoveredGroup === group.key;
            const RailIcon = group.railIcon;

            // ── Wide mode: collapsible group with inline items ──
            if (isWide) {
              return (
                <div key={group.key} className="mb-0.5">
                  <button
                    onClick={() => setActiveGroup(prev => prev === group.key ? null : group.key)}
                    className={cn(
                      'flex items-center justify-between w-full px-3 py-1.5 mt-1',
                      'text-[12px] font-semibold uppercase tracking-[0.06em] transition-colors',
                      hasActive && !isOpen ? 'text-accent/60' : 'text-muted/40',
                      'hover:text-muted/70',
                    )}
                  >
                    <div className="flex items-center gap-2.5 min-w-0">
                      {RailIcon ? (
                        <RailIcon size={14} className="flex-shrink-0" />
                      ) : (
                        <ZMark size={12} className="flex-shrink-0" />
                      )}
                      <span className="whitespace-nowrap">{tn(group.label)}</span>
                    </div>
                    <ChevronDown
                      size={13}
                      className={cn(
                        'transition-transform duration-150 flex-shrink-0',
                        isOpen ? 'rotate-0' : '-rotate-90',
                      )}
                    />
                  </button>
                  <div
                    className={cn(
                      'overflow-hidden transition-all duration-150 ease-out',
                      isOpen ? 'max-h-[600px] opacity-100' : 'max-h-0 opacity-0',
                    )}
                  >
                    <div className="px-1 space-y-[1px]">
                      {group.items.map(item => renderDetailItem(item))}
                    </div>
                  </div>
                </div>
              );
            }

            // ── Narrow mode: icon rail with click flyout ──
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
                  {RailIcon ? (
                    <RailIcon size={20} />
                  ) : (
                    <ZMark size={18} className={cn((isOpen || hasActive) && 'text-accent')} />
                  )}
                </button>

                {/* Hover tooltip — narrow mode only */}
                {isHovered && !isOpen && (
                  <div className="absolute left-full top-1/2 -translate-y-1/2 ml-3 px-3 py-1.5 bg-surface border border-main rounded-lg shadow-xl z-50 whitespace-nowrap sidebar-flyout-enter pointer-events-none">
                    <span className="text-[14px] font-medium text-main">{tn(group.label)}</span>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Divider */}
        <div className="mx-2.5 border-t border-main/40" />

        {/* Bottom: Z Assistant + Settings + Sidebar Control + Sign Out + User */}
        <div className="px-1.5 py-2 space-y-0.5">
          {/* Settings */}
          <Link
            href="/dashboard/settings"
            onMouseEnter={!isWide ? () => setHoveredGroup('__settings') : undefined}
            onMouseLeave={!isWide ? handleRailHoverLeave : undefined}
            className={cn(
              'relative flex items-center py-2 rounded-md transition-colors group',
              isWide ? 'px-3 gap-3' : 'justify-center',
              pathname === '/dashboard/settings'
                ? 'text-accent bg-accent/10'
                : 'text-muted hover:text-main hover:bg-surface-hover',
            )}
          >
            <Settings size={20} className="flex-shrink-0" />
            {isWide && <span className="text-[14px] font-medium whitespace-nowrap">{tn('Settings')}</span>}
            {!isWide && hoveredGroup === '__settings' && (
              <div className="absolute left-full ml-3 px-3 py-1.5 bg-surface border border-main rounded-lg shadow-xl z-50 whitespace-nowrap sidebar-flyout-enter pointer-events-none">
                <span className="text-[14px] font-medium text-main">{tn('Settings')}</span>
              </div>
            )}
          </Link>

          {/* Sidebar Control */}
          <div ref={controlRef} className="relative">
            <button
              onClick={() => setControlOpen(prev => !prev)}
              onMouseEnter={!isWide ? () => setHoveredGroup('__control') : undefined}
              onMouseLeave={!isWide ? handleRailHoverLeave : undefined}
              className={cn(
                'relative w-full flex items-center py-2 rounded-md transition-colors',
                isWide ? 'px-3 gap-3' : 'justify-center',
                controlOpen
                  ? 'text-accent bg-accent/10'
                  : 'text-muted hover:text-main hover:bg-surface-hover',
              )}
            >
              {sidebarMode === 'expanded' ? (
                <PanelLeftClose size={18} className="flex-shrink-0" />
              ) : (
                <PanelLeft size={18} className="flex-shrink-0" />
              )}
              {isWide && <span className="text-[14px] font-medium whitespace-nowrap">Sidebar</span>}
              {!isWide && hoveredGroup === '__control' && !controlOpen && (
                <div className="absolute left-full ml-3 px-3 py-1.5 bg-surface border border-main rounded-lg shadow-xl z-50 whitespace-nowrap sidebar-flyout-enter pointer-events-none">
                  <span className="text-[14px] font-medium text-main">Sidebar control</span>
                </div>
              )}
            </button>

            {/* Sidebar control popup */}
            {controlOpen && (
              <div className={cn(
                'absolute bottom-0 z-50 w-52 bg-surface border border-main rounded-xl shadow-xl overflow-hidden sidebar-flyout-enter',
                isWide ? 'left-full ml-2' : 'left-full ml-3',
              )}>
                <div className="px-3 py-2 border-b border-main">
                  <p className="text-[12px] font-semibold text-main">Sidebar control</p>
                </div>
                <div className="p-1.5 space-y-0.5">
                  {([
                    { mode: 'expanded' as const, label: 'Expanded', icon: PanelLeft },
                    { mode: 'collapsed' as const, label: 'Collapsed', icon: PanelLeftClose },
                    { mode: 'hover' as const, label: 'Expand on hover', icon: PanelLeft },
                  ]).map(opt => (
                    <button
                      key={opt.mode}
                      onClick={() => handleSetMode(opt.mode)}
                      className={cn(
                        'w-full flex items-center gap-2.5 px-2.5 py-2 rounded-lg text-[14px] font-medium transition-colors',
                        sidebarMode === opt.mode
                          ? 'text-accent bg-accent/5'
                          : 'text-muted hover:text-main hover:bg-surface-hover',
                      )}
                    >
                      <opt.icon size={15} className="flex-shrink-0" />
                      <span className="flex-1 text-left">{opt.label}</span>
                      {sidebarMode === opt.mode && (
                        <Check size={14} className="text-accent flex-shrink-0" />
                      )}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Sign out */}
          <button
            onClick={onSignOut}
            onMouseEnter={!isWide ? () => setHoveredGroup('__signout') : undefined}
            onMouseLeave={!isWide ? handleRailHoverLeave : undefined}
            className={cn(
              'relative w-full flex items-center py-2 rounded-md text-muted hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors',
              isWide ? 'px-3 gap-3' : 'justify-center',
            )}
          >
            <LogOut size={18} className="flex-shrink-0" />
            {isWide && <span className="text-[14px] font-medium whitespace-nowrap">{tn('Sign out')}</span>}
            {!isWide && hoveredGroup === '__signout' && (
              <div className="absolute left-full ml-3 px-3 py-1.5 bg-surface border border-main rounded-lg shadow-xl z-50 whitespace-nowrap sidebar-flyout-enter pointer-events-none">
                <span className="text-[14px] font-medium text-main">{tn('Sign out')}</span>
              </div>
            )}
          </button>

          {/* User avatar */}
          {user && (
            <button
              onClick={() => router.push('/dashboard/settings')}
              onMouseEnter={!isWide ? () => setHoveredGroup('__user') : undefined}
              onMouseLeave={!isWide ? handleRailHoverLeave : undefined}
              className={cn(
                'relative w-full flex items-center py-1',
                isWide ? 'px-3 gap-3' : 'justify-center',
              )}
            >
              <div className="w-7 h-7 rounded-full bg-accent/10 flex items-center justify-center hover:bg-accent/20 transition-colors flex-shrink-0">
                <span className="text-accent text-[10px] font-semibold">{initials}</span>
              </div>
              {isWide && (
                <span className="text-[12px] text-muted truncate">{user.email || 'Profile'}</span>
              )}
              {!isWide && hoveredGroup === '__user' && (
                <div className="absolute left-full ml-3 px-3 py-1.5 bg-surface border border-main rounded-lg shadow-xl z-50 whitespace-nowrap sidebar-flyout-enter pointer-events-none">
                  <span className="text-[14px] font-medium text-main">{user.email || 'Profile'}</span>
                </div>
              )}
            </button>
          )}
        </div>
      </aside>

      {/* ═══════════════════════════════════════════
          DETAIL PANEL — slides out when a group is clicked (collapsed mode only)
          Shows all sub-items for the selected category
          ═══════════════════════════════════════════ */}

      {!isWide && activeGroup && currentDetailGroup && (
        <div
          ref={detailRef}
          className="fixed top-0 left-12 z-[45] h-full w-[220px] bg-surface border-r border-main shadow-xl hidden md:flex flex-col sidebar-detail-enter"
        >
          {/* Panel header */}
          <div className="h-12 flex items-center justify-between px-4 border-b border-main flex-shrink-0">
            <span className="text-[14px] font-semibold tracking-[0.02em] text-main">
              {tn(currentDetailGroup.label)}
            </span>
            <button
              onClick={() => setActiveGroup(null)}
              className="p-1 text-muted hover:text-main rounded-md hover:bg-surface-hover transition-colors"
            >
              <X size={14} />
            </button>
          </div>

          {/* Panel items */}
          <nav className="flex-1 py-2 px-2 overflow-y-auto scrollbar-hide space-y-[1px]" aria-label={`${tn(currentDetailGroup.label)} navigation`}>
            {currentDetailGroup.items.map(item => renderDetailItem(item))}
          </nav>
        </div>
      )}
    </>
  );
}

// ── Hook for layout to read sidebar width ──
// Returns the pixel width the main content should be offset by.
// Only "expanded" mode pushes content; "hover" overlays on top (no push).
export function useSidebarWidth(): number {
  const [width, setWidth] = useState(48);

  useEffect(() => {
    const mode = loadSidebarMode();
    setWidth(mode === 'expanded' ? 220 : 48);

    // Listen for storage changes (same tab)
    const handler = () => {
      const m = loadSidebarMode();
      setWidth(m === 'expanded' ? 220 : 48);
    };
    window.addEventListener('storage', handler);
    // Also listen for custom event from sidebar mode change
    window.addEventListener('sidebarModeChange', handler);
    return () => {
      window.removeEventListener('storage', handler);
      window.removeEventListener('sidebarModeChange', handler);
    };
  }, []);

  return width;
}
