'use client';

/**
 * ZAFTO Permission Gate Component
 * Session 23 - RBAC Enforcement for Web Portal
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
import { doc, onSnapshot } from 'firebase/firestore';
import { db } from '@/lib/firebase';
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
} as const;

// ============================================================
// TYPES
// ============================================================

export type Permission = (typeof PERMISSIONS)[keyof typeof PERMISSIONS];

export type CompanyTier = 'solo' | 'team' | 'business' | 'enterprise';

export interface Role {
  id: string;
  companyId: string;
  name: string;
  description?: string;
  isSystemRole: boolean;
  isDefault: boolean;
  permissions: Record<string, boolean>;
}

export interface Company {
  id: string;
  name: string;
  tier: CompanyTier;
  ownerUserId: string;
  uiMode?: 'simple' | 'pro';
  enabledProFeatures?: string[];
}

interface PermissionContextType {
  // State
  loading: boolean;
  companyId: string | null;
  roleId: string | null;
  company: Company | null;
  role: Role | null;

  // Permission checks
  can: (permission: Permission) => boolean;
  canAll: (permissions: Permission[]) => boolean;
  canAny: (permissions: Permission[]) => boolean;

  // Tier checks
  tier: CompanyTier | null;
  isSolo: boolean;
  isTeamOrHigher: boolean;
  isBusinessOrHigher: boolean;
  isEnterprise: boolean;

  // Ownership
  isOwner: boolean;

  // Pro Mode (Session 23)
  isProMode: boolean;
  hasProFeature: (feature: string) => boolean;
}

const PermissionContext = createContext<PermissionContextType>({
  loading: true,
  companyId: null,
  roleId: null,
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
  const { user, loading: authLoading } = useAuth();
  const [loading, setLoading] = useState(true);
  const [companyId, setCompanyId] = useState<string | null>(null);
  const [roleId, setRoleId] = useState<string | null>(null);
  const [company, setCompany] = useState<Company | null>(null);
  const [role, setRole] = useState<Role | null>(null);
  // Initialize from localStorage synchronously (client-only)
  const [localProMode, setLocalProMode] = useState<boolean>(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('zafto_pro_mode') === 'true';
    }
    return false;
  });

  // Listen for changes from ProModeToggle
  useEffect(() => {
    const handleProModeChange = (e: CustomEvent) => {
      setLocalProMode(e.detail as boolean);
    };
    window.addEventListener('proModeChange', handleProModeChange as EventListener);
    return () => window.removeEventListener('proModeChange', handleProModeChange as EventListener);
  }, []);

  // Fetch user's company/role from Firestore
  useEffect(() => {
    if (authLoading) return;
    if (!user) {
      setLoading(false);
      setCompanyId(null);
      setRoleId(null);
      setCompany(null);
      setRole(null);
      return;
    }

    // Subscribe to user document to get companyId and roleId
    const userRef = doc(db, 'users', user.uid);
    const unsubUser = onSnapshot(userRef, (doc) => {
      if (doc.exists()) {
        const data = doc.data();
        setCompanyId(data.companyId || null);
        setRoleId(data.roleId || null);
      } else {
        setCompanyId(null);
        setRoleId(null);
        setLoading(false);
      }
    });

    return () => unsubUser();
  }, [user, authLoading]);

  // Fetch company data
  useEffect(() => {
    if (!companyId) {
      setCompany(null);
      return;
    }

    const companyRef = doc(db, 'companies', companyId);
    const unsubCompany = onSnapshot(companyRef, (doc) => {
      if (doc.exists()) {
        setCompany({ id: doc.id, ...doc.data() } as Company);
      } else {
        setCompany(null);
      }
    });

    return () => unsubCompany();
  }, [companyId]);

  // Fetch role data
  useEffect(() => {
    if (!companyId || !roleId) {
      setRole(null);
      setLoading(false);
      return;
    }

    const roleRef = doc(db, 'companies', companyId, 'roles', roleId);
    const unsubRole = onSnapshot(roleRef, (doc) => {
      if (doc.exists()) {
        setRole({ id: doc.id, ...doc.data() } as Role);
      } else {
        setRole(null);
      }
      setLoading(false);
    });

    return () => unsubRole();
  }, [companyId, roleId]);

  // Permission check functions
  const can = (permission: Permission): boolean => {
    if (!role) return false;
    return role.permissions[permission] === true;
  };

  const canAll = (permissions: Permission[]): boolean => {
    return permissions.every((p) => can(p));
  };

  const canAny = (permissions: Permission[]): boolean => {
    return permissions.some((p) => can(p));
  };

  // Tier helpers
  const tier = company?.tier || null;
  const isSolo = tier === 'solo';
  const isTeamOrHigher = tier === 'team' || tier === 'business' || tier === 'enterprise';
  const isBusinessOrHigher = tier === 'business' || tier === 'enterprise';
  const isEnterprise = tier === 'enterprise';

  // Ownership
  const isOwner = user?.uid === company?.ownerUserId;

  // Pro Mode (Session 23)
  // Use localStorage state if no company, otherwise use Firestore
  const isProMode = company ? company.uiMode === 'pro' : localProMode;
  const hasProFeature = (feature: string): boolean => {
    if (!isProMode) return false;
    // If no company or no specific features enabled, all are available in pro mode
    if (!company || !company.enabledProFeatures || company.enabledProFeatures.length === 0) return true;
    return company.enabledProFeatures.includes(feature);
  };

  const value: PermissionContextType = {
    loading,
    companyId,
    roleId,
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
  /** Single permission to check */
  permission?: Permission;
  /** Multiple permissions to check */
  permissions?: Permission[];
  /** If true, requires ALL permissions; if false, requires ANY (default: false) */
  requireAll?: boolean;
  /** Content to show when permission is granted */
  children: ReactNode;
  /** Optional content to show when permission is denied */
  fallback?: ReactNode;
}

/**
 * Gate that shows content only if user has required permission(s)
 */
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
  /** Minimum tier required */
  minimumTier: CompanyTier;
  /** Content to show when tier requirement is met */
  children: ReactNode;
  /** Optional content to show when tier requirement is not met */
  fallback?: ReactNode;
}

/**
 * Gate that shows content only if company meets minimum tier
 */
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
  /** Content to show when in Pro Mode */
  children: ReactNode;
  /** Optional content to show in Simple Mode */
  fallback?: ReactNode;
  /** Optional specific feature to check */
  feature?: string;
}

/**
 * Gate that shows content only in Pro Mode (Session 23)
 */
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

/**
 * Gate that shows content only for company owner
 */
export function OwnerOnly({ children, fallback = null }: OwnerOnlyProps) {
  const { isOwner, loading } = usePermissions();

  if (loading) return null;

  return isOwner ? <>{children}</> : <>{fallback}</>;
}
