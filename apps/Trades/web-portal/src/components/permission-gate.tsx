'use client';

/**
 * ZAFTO Permission Gate Component
 * Sprint B4a (Session 48) — Rewritten for Supabase
 *
 * Usage:
 * ```tsx
 * <PermissionGate permission="jobs.create">
 *   <CreateJobButton />
 * </PermissionGate>
 *
 * <PermissionGate permissions={["jobs.view.all", "jobs.edit.all"]} requireAll>
 *   <AdminJobsPanel />
 * </PermissionGate>
 * ```
 */

import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from './auth-provider';

// ============================================================
// PERMISSION CONSTANTS (mirror mobile role.dart)
// ============================================================

export const PERMISSIONS = {
  // Jobs
  JOBS_VIEW_OWN: 'jobs.view.own',
  JOBS_VIEW_ALL: 'jobs.view.all',
  JOBS_CREATE: 'jobs.create',
  JOBS_EDIT_OWN: 'jobs.edit.own',
  JOBS_EDIT_ALL: 'jobs.edit.all',
  JOBS_DELETE: 'jobs.delete',
  JOBS_ASSIGN: 'jobs.assign',
  // Invoices
  INVOICES_VIEW_OWN: 'invoices.view.own',
  INVOICES_VIEW_ALL: 'invoices.view.all',
  INVOICES_CREATE: 'invoices.create',
  INVOICES_EDIT: 'invoices.edit',
  INVOICES_SEND: 'invoices.send',
  INVOICES_APPROVE: 'invoices.approve',
  INVOICES_VOID: 'invoices.void',
  // Customers
  CUSTOMERS_VIEW_OWN: 'customers.view.own',
  CUSTOMERS_VIEW_ALL: 'customers.view.all',
  CUSTOMERS_CREATE: 'customers.create',
  CUSTOMERS_EDIT: 'customers.edit',
  CUSTOMERS_DELETE: 'customers.delete',
  // Team
  TEAM_VIEW: 'team.view',
  TEAM_INVITE: 'team.invite',
  TEAM_EDIT: 'team.edit',
  TEAM_REMOVE: 'team.remove',
  // Dispatch
  DISPATCH_VIEW: 'dispatch.view',
  DISPATCH_MANAGE: 'dispatch.manage',
  // Reports
  REPORTS_VIEW: 'reports.view',
  REPORTS_EXPORT: 'reports.export',
  // Admin
  COMPANY_SETTINGS: 'company.settings',
  BILLING_MANAGE: 'billing.manage',
  ROLES_MANAGE: 'roles.manage',
  AUDIT_VIEW: 'audit.view',
  // Time Clock
  TIMECLOCK_OWN: 'timeclock.own',
  TIMECLOCK_VIEW_ALL: 'timeclock.view.all',
  TIMECLOCK_MANAGE: 'timeclock.manage',
  // Enterprise
  BRANCHES_VIEW: 'branches.view',
  BRANCHES_MANAGE: 'branches.manage',
  CERTIFICATIONS_VIEW: 'certifications.view',
  CERTIFICATIONS_MANAGE: 'certifications.manage',
  FORMS_VIEW: 'forms.view',
  FORMS_MANAGE: 'forms.manage',
  API_KEYS_MANAGE: 'api_keys.manage',
  // Financials
  FINANCIALS_VIEW: 'financials.view',
  FINANCIALS_MANAGE: 'financials.manage',
  // Fleet
  FLEET_VIEW: 'fleet.view',
  FLEET_MANAGE: 'fleet.manage',
  // Payroll
  PAYROLL_VIEW: 'payroll.view',
  PAYROLL_MANAGE: 'payroll.manage',
} as const;

// ============================================================
// TYPES
// ============================================================

export type Permission = (typeof PERMISSIONS)[keyof typeof PERMISSIONS];

export type CompanyTier = 'solo' | 'team' | 'business' | 'enterprise';

export interface Company {
  id: string;
  name: string;
  tier: CompanyTier;
  owner_user_id: string;
  ui_mode?: 'simple' | 'pro';
  enabled_pro_features?: string[];
}

// Default permissions by role. Owner gets everything.
// This will later be replaced by a roles table in Supabase.
const ROLE_PERMISSIONS: Record<string, Permission[]> = {
  owner: Object.values(PERMISSIONS),
  admin: Object.values(PERMISSIONS),
  office: [
    PERMISSIONS.JOBS_VIEW_ALL, PERMISSIONS.JOBS_CREATE, PERMISSIONS.JOBS_EDIT_ALL,
    PERMISSIONS.INVOICES_VIEW_ALL, PERMISSIONS.INVOICES_CREATE, PERMISSIONS.INVOICES_EDIT, PERMISSIONS.INVOICES_SEND,
    PERMISSIONS.CUSTOMERS_VIEW_ALL, PERMISSIONS.CUSTOMERS_CREATE, PERMISSIONS.CUSTOMERS_EDIT,
    PERMISSIONS.TEAM_VIEW,
    PERMISSIONS.DISPATCH_VIEW, PERMISSIONS.DISPATCH_MANAGE,
    PERMISSIONS.REPORTS_VIEW, PERMISSIONS.REPORTS_EXPORT,
    PERMISSIONS.TIMECLOCK_OWN, PERMISSIONS.TIMECLOCK_VIEW_ALL,
    PERMISSIONS.BRANCHES_VIEW, PERMISSIONS.CERTIFICATIONS_VIEW, PERMISSIONS.FORMS_VIEW,
  ],
  tech: [
    PERMISSIONS.JOBS_VIEW_OWN, PERMISSIONS.JOBS_EDIT_OWN,
    PERMISSIONS.CUSTOMERS_VIEW_OWN,
    PERMISSIONS.TIMECLOCK_OWN,
  ],
  cpa: [
    PERMISSIONS.INVOICES_VIEW_ALL,
    PERMISSIONS.REPORTS_VIEW, PERMISSIONS.REPORTS_EXPORT,
    PERMISSIONS.AUDIT_VIEW,
  ],
};

interface PermissionContextType {
  loading: boolean;
  companyId: string | null;
  company: Company | null;
  role: string | null;
  can: (permission: Permission) => boolean;
  canAll: (permissions: Permission[]) => boolean;
  canAny: (permissions: Permission[]) => boolean;
  tier: CompanyTier | null;
  isSolo: boolean;
  isTeamOrHigher: boolean;
  isBusinessOrHigher: boolean;
  isEnterprise: boolean;
  isOwner: boolean;
  isProMode: boolean;
  hasProFeature: (feature: string) => boolean;
}

const PermissionContext = createContext<PermissionContextType>({
  loading: true,
  companyId: null,
  company: null,
  role: null,
  can: () => false,
  canAll: () => false,
  canAny: () => false,
  tier: null,
  isSolo: true,
  isTeamOrHigher: false,
  isBusinessOrHigher: false,
  isEnterprise: false,
  isOwner: false,
  isProMode: false,
  hasProFeature: () => false,
});

// ============================================================
// PERMISSION PROVIDER
// ============================================================

interface PermissionProviderProps {
  children: ReactNode;
}

export function PermissionProvider({ children }: PermissionProviderProps) {
  const { user, profile, loading: authLoading } = useAuth();
  const [loading, setLoading] = useState(true);
  const [company, setCompany] = useState<Company | null>(null);
  const [customPermissions, setCustomPermissions] = useState<Record<string, boolean> | null>(null);
  const [localProMode, setLocalProMode] = useState<boolean>(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('zafto_pro_mode') === 'true';
    }
    return false;
  });

  // Listen for Pro Mode toggle changes.
  useEffect(() => {
    const handleProModeChange = (e: CustomEvent) => {
      setLocalProMode(e.detail as boolean);
    };
    window.addEventListener('proModeChange', handleProModeChange as EventListener);
    return () => window.removeEventListener('proModeChange', handleProModeChange as EventListener);
  }, []);

  // Fetch company data from Supabase.
  useEffect(() => {
    if (authLoading) return;
    if (!profile?.companyId) {
      setCompany(null);
      setLoading(false);
      return;
    }

    const supabase = getSupabase();
    supabase
      .from('companies')
      .select('id, name, subscription_tier, owner_user_id, settings')
      .eq('id', profile.companyId)
      .single()
      .then(({ data }: { data: { id: string; name: string; subscription_tier: string; owner_user_id: string; settings: Record<string, unknown> | null } | null }) => {
        if (data) {
          const s = data.settings || {};
          setCompany({
            id: data.id,
            name: data.name,
            tier: (data.subscription_tier as CompanyTier) || 'solo',
            owner_user_id: data.owner_user_id,
            ui_mode: (s.ui_mode as 'simple' | 'pro') || undefined,
            enabled_pro_features: (s.enabled_pro_features as string[]) || undefined,
          });
        } else {
          setCompany(null);
        }
        setLoading(false);
      })
      .catch(() => {
        setCompany(null);
        setLoading(false);
      });
  }, [profile?.companyId, authLoading]);

  // Fetch custom role permissions if user has custom_role_id.
  useEffect(() => {
    if (authLoading || !profile?.customRoleId) {
      setCustomPermissions(null);
      return;
    }

    const supabase = getSupabase();
    supabase
      .from('custom_roles')
      .select('permissions')
      .eq('id', profile.customRoleId)
      .single()
      .then(({ data }: { data: { permissions: Record<string, boolean> } | null }) => {
        if (data?.permissions) {
          setCustomPermissions(data.permissions);
        }
      })
      .catch(() => {
        setCustomPermissions(null);
      });
  }, [profile?.customRoleId, authLoading]);

  // Role from user profile.
  const role = profile?.role || null;

  // Permission check: custom role permissions override default role-based lookup.
  const can = (permission: Permission): boolean => {
    if (!role) return false;
    // If user has custom role permissions, use those.
    if (customPermissions) {
      return customPermissions[permission] === true;
    }
    // Fall back to default role-based permissions.
    const perms = ROLE_PERMISSIONS[role];
    if (!perms) return false;
    return perms.includes(permission);
  };

  const canAll = (permissions: Permission[]): boolean => {
    return permissions.every((p) => can(p));
  };

  const canAny = (permissions: Permission[]): boolean => {
    return permissions.some((p) => can(p));
  };

  // Tier helpers.
  const tier = company?.tier || null;
  const isSolo = tier === 'solo';
  const isTeamOrHigher = tier === 'team' || tier === 'business' || tier === 'enterprise';
  const isBusinessOrHigher = tier === 'business' || tier === 'enterprise';
  const isEnterprise = tier === 'enterprise';

  // Ownership.
  const isOwner = user?.id === company?.owner_user_id;

  // Pro Mode.
  const isProMode = company ? company.ui_mode === 'pro' : localProMode;
  const hasProFeature = (feature: string): boolean => {
    if (!isProMode) return false;
    if (!company || !company.enabled_pro_features || company.enabled_pro_features.length === 0) return true;
    return company.enabled_pro_features.includes(feature);
  };

  const value: PermissionContextType = {
    loading,
    companyId: profile?.companyId || null,
    company,
    role,
    can,
    canAll,
    canAny,
    tier,
    isSolo,
    isTeamOrHigher,
    isBusinessOrHigher,
    isEnterprise,
    isOwner,
    isProMode,
    hasProFeature,
  };

  return <PermissionContext.Provider value={value}>{children}</PermissionContext.Provider>;
}

// ============================================================
// HOOKS
// ============================================================

export function usePermissions() {
  return useContext(PermissionContext);
}

// ============================================================
// GATE COMPONENTS
// ============================================================

interface PermissionGateProps {
  permission?: Permission;
  permissions?: Permission[];
  requireAll?: boolean;
  children: ReactNode;
  fallback?: ReactNode;
}

export function PermissionGate({
  permission,
  permissions,
  requireAll = false,
  children,
  fallback = null,
}: PermissionGateProps) {
  const { can, canAll, canAny, loading } = usePermissions();

  if (loading) return null;

  let hasAccess = false;

  if (permission) {
    hasAccess = can(permission);
  } else if (permissions) {
    hasAccess = requireAll ? canAll(permissions) : canAny(permissions);
  }

  return hasAccess ? <>{children}</> : <>{fallback}</>;
}

interface TierGateProps {
  minimumTier: CompanyTier;
  children: ReactNode;
  fallback?: ReactNode;
}

export function TierGate({ minimumTier, children, fallback = null }: TierGateProps) {
  const { tier, loading } = usePermissions();

  if (loading) return null;

  const tierOrder: CompanyTier[] = ['solo', 'team', 'business', 'enterprise'];
  const currentIndex = tier ? tierOrder.indexOf(tier) : -1;
  const requiredIndex = tierOrder.indexOf(minimumTier);

  const hasAccess = currentIndex >= requiredIndex;

  return hasAccess ? <>{children}</> : <>{fallback}</>;
}

interface ProModeGateProps {
  children: ReactNode;
  fallback?: ReactNode;
  feature?: string;
}

export function ProModeGate({ children, fallback = null, feature }: ProModeGateProps) {
  const { isProMode, hasProFeature, loading } = usePermissions();

  if (loading) return null;

  let hasAccess = isProMode;
  if (feature) {
    hasAccess = hasProFeature(feature);
  }

  return hasAccess ? <>{children}</> : <>{fallback}</>;
}

// ============================================================
// UTILITY COMPONENTS
// ============================================================

interface OwnerOnlyProps {
  children: ReactNode;
  fallback?: ReactNode;
}

export function OwnerOnly({ children, fallback = null }: OwnerOnlyProps) {
  const { isOwner, loading } = usePermissions();

  if (loading) return null;

  return isOwner ? <>{children}</> : <>{fallback}</>;
}
