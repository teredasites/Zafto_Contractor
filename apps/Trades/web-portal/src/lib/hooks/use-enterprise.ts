'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// TYPES
// ============================================================

export interface Branch {
  id: string;
  companyId: string;
  name: string;
  address: string | null;
  city: string | null;
  state: string | null;
  zipCode: string | null;
  phone: string | null;
  email: string | null;
  managerUserId: string | null;
  timezone: string;
  isActive: boolean;
  settings: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export interface CustomRole {
  id: string;
  companyId: string;
  name: string;
  description: string | null;
  baseRole: string;
  permissions: Record<string, boolean>;
  isSystemRole: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface FormTemplate {
  id: string;
  companyId: string | null;
  trade: string | null;
  name: string;
  description: string | null;
  category: string;
  regulationReference: string | null;
  fields: FormFieldDefinition[];
  isActive: boolean;
  isSystem: boolean;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
}

export interface FormFieldDefinition {
  key: string;
  type: string;
  label: string;
  required?: boolean;
  options?: string[];
  placeholder?: string;
  validation?: Record<string, unknown>;
  computed_from?: string;
}

export interface Certification {
  id: string;
  companyId: string;
  userId: string;
  certificationType: string;
  certificationName: string;
  issuingAuthority: string | null;
  certificationNumber: string | null;
  issuedDate: string | null;
  expirationDate: string | null;
  renewalRequired: boolean;
  renewalReminderDays: number;
  documentUrl: string | null;
  status: 'active' | 'expired' | 'pending_renewal' | 'revoked';
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface CertificationTypeConfig {
  id: string;
  companyId: string | null;
  typeKey: string;
  displayName: string;
  category: string;
  description: string | null;
  regulationReference: string | null;
  applicableTrades: string[];
  applicableRegions: string[];
  requiredFields: { key: string; label: string; required?: boolean }[];
  attachmentRequired: boolean;
  defaultRenewalDays: number;
  defaultRenewalRequired: boolean;
  isSystem: boolean;
  isActive: boolean;
  sortOrder: number;
}

export interface ApiKey {
  id: string;
  companyId: string;
  name: string;
  prefix: string;
  permissions: Record<string, boolean>;
  lastUsedAt: string | null;
  expiresAt: string | null;
  isActive: boolean;
  createdByUserId: string;
  createdAt: string;
}

// ============================================================
// MAPPERS
// ============================================================

function mapBranch(row: Record<string, unknown>): Branch {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    name: row.name as string,
    address: row.address as string | null,
    city: row.city as string | null,
    state: row.state as string | null,
    zipCode: row.zip_code as string | null,
    phone: row.phone as string | null,
    email: row.email as string | null,
    managerUserId: row.manager_user_id as string | null,
    timezone: (row.timezone as string) || 'America/New_York',
    isActive: (row.is_active as boolean) ?? true,
    settings: (row.settings as Record<string, unknown>) || {},
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapCustomRole(row: Record<string, unknown>): CustomRole {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    name: row.name as string,
    description: row.description as string | null,
    baseRole: (row.base_role as string) || 'technician',
    permissions: (row.permissions as Record<string, boolean>) || {},
    isSystemRole: (row.is_system_role as boolean) ?? false,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapFormTemplate(row: Record<string, unknown>): FormTemplate {
  return {
    id: row.id as string,
    companyId: row.company_id as string | null,
    trade: row.trade as string | null,
    name: row.name as string,
    description: row.description as string | null,
    category: (row.category as string) || 'compliance',
    regulationReference: row.regulation_reference as string | null,
    fields: (row.fields as FormFieldDefinition[]) || [],
    isActive: (row.is_active as boolean) ?? true,
    isSystem: (row.is_system as boolean) ?? false,
    sortOrder: (row.sort_order as number) ?? 0,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapCertification(row: Record<string, unknown>): Certification {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    userId: row.user_id as string,
    certificationType: (row.certification_type as string) || 'other',
    certificationName: (row.certification_name as string) || '',
    issuingAuthority: row.issuing_authority as string | null,
    certificationNumber: row.certification_number as string | null,
    issuedDate: row.issued_date as string | null,
    expirationDate: row.expiration_date as string | null,
    renewalRequired: (row.renewal_required as boolean) ?? true,
    renewalReminderDays: (row.renewal_reminder_days as number) ?? 30,
    documentUrl: row.document_url as string | null,
    status: (row.status as Certification['status']) || 'active',
    notes: row.notes as string | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapCertificationType(row: Record<string, unknown>): CertificationTypeConfig {
  return {
    id: row.id as string,
    companyId: row.company_id as string | null,
    typeKey: (row.type_key as string) || 'other',
    displayName: (row.display_name as string) || '',
    category: (row.category as string) || 'trade',
    description: row.description as string | null,
    regulationReference: row.regulation_reference as string | null,
    applicableTrades: (row.applicable_trades as string[]) || [],
    applicableRegions: (row.applicable_regions as string[]) || [],
    requiredFields: (row.required_fields as CertificationTypeConfig['requiredFields']) || [],
    attachmentRequired: (row.attachment_required as boolean) ?? false,
    defaultRenewalDays: (row.default_renewal_days as number) ?? 30,
    defaultRenewalRequired: (row.default_renewal_required as boolean) ?? true,
    isSystem: (row.is_system as boolean) ?? false,
    isActive: (row.is_active as boolean) ?? true,
    sortOrder: (row.sort_order as number) ?? 0,
  };
}

function mapApiKey(row: Record<string, unknown>): ApiKey {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    name: row.name as string,
    prefix: (row.prefix as string) || '',
    permissions: (row.permissions as Record<string, boolean>) || {},
    lastUsedAt: row.last_used_at as string | null,
    expiresAt: row.expires_at as string | null,
    isActive: (row.is_active as boolean) ?? true,
    createdByUserId: row.created_by_user_id as string,
    createdAt: row.created_at as string,
  };
}

// ============================================================
// HOOKS
// ============================================================

export function useBranches() {
  const [branches, setBranches] = useState<Branch[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchBranches = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('branches')
        .select('*')
        .order('name');

      if (err) throw err;
      setBranches((data || []).map(mapBranch));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load branches';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchBranches();

    const supabase = getSupabase();
    const channel = supabase
      .channel('branches-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'branches' }, () => {
        fetchBranches();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchBranches]);

  const createBranch = async (data: Partial<Branch>): Promise<string> => {
    const supabase = getSupabase();
    const { data: row, error: err } = await supabase
      .from('branches')
      .insert({
        company_id: data.companyId,
        name: data.name,
        address: data.address,
        city: data.city,
        state: data.state,
        zip_code: data.zipCode,
        phone: data.phone,
        email: data.email,
        manager_user_id: data.managerUserId,
        timezone: data.timezone || 'America/New_York',
        is_active: data.isActive ?? true,
      })
      .select()
      .single();

    if (err) throw err;
    return row.id;
  };

  const updateBranch = async (id: string, data: Partial<Branch>) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('branches')
      .update({
        name: data.name,
        address: data.address,
        city: data.city,
        state: data.state,
        zip_code: data.zipCode,
        phone: data.phone,
        email: data.email,
        manager_user_id: data.managerUserId,
        timezone: data.timezone,
        is_active: data.isActive,
      })
      .eq('id', id);

    if (err) throw err;
  };

  const deleteBranch = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('branches')
      .delete()
      .eq('id', id);

    if (err) throw err;
  };

  return { branches, loading, error, createBranch, updateBranch, deleteBranch, refresh: fetchBranches };
}

export function useCustomRoles() {
  const [roles, setRoles] = useState<CustomRole[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchRoles = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('custom_roles')
        .select('*')
        .order('name');

      if (err) throw err;
      setRoles((data || []).map(mapCustomRole));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load roles';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchRoles();
  }, [fetchRoles]);

  const createRole = async (data: Partial<CustomRole>): Promise<string> => {
    const supabase = getSupabase();
    const { data: row, error: err } = await supabase
      .from('custom_roles')
      .insert({
        company_id: data.companyId,
        name: data.name,
        description: data.description,
        base_role: data.baseRole || 'technician',
        permissions: data.permissions || {},
      })
      .select()
      .single();

    if (err) throw err;
    return row.id;
  };

  const updateRole = async (id: string, data: Partial<CustomRole>) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('custom_roles')
      .update({
        name: data.name,
        description: data.description,
        base_role: data.baseRole,
        permissions: data.permissions,
      })
      .eq('id', id);

    if (err) throw err;
  };

  const deleteRole = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('custom_roles')
      .delete()
      .eq('id', id);

    if (err) throw err;
  };

  return { roles, loading, error, createRole, updateRole, deleteRole, refresh: fetchRoles };
}

export function useFormTemplates() {
  const [templates, setTemplates] = useState<FormTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTemplates = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('form_templates')
        .select('*')
        .order('trade')
        .order('sort_order');

      if (err) throw err;
      setTemplates((data || []).map(mapFormTemplate));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load form templates';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTemplates();
  }, [fetchTemplates]);

  const createTemplate = async (data: Partial<FormTemplate>): Promise<string> => {
    const supabase = getSupabase();
    const { data: row, error: err } = await supabase
      .from('form_templates')
      .insert({
        company_id: data.companyId,
        trade: data.trade,
        name: data.name,
        description: data.description,
        category: data.category || 'compliance',
        regulation_reference: data.regulationReference,
        fields: data.fields || [],
        is_active: data.isActive ?? true,
        sort_order: data.sortOrder ?? 0,
      })
      .select()
      .single();

    if (err) throw err;
    return row.id;
  };

  const updateTemplate = async (id: string, data: Partial<FormTemplate>) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('form_templates')
      .update({
        name: data.name,
        description: data.description,
        category: data.category,
        regulation_reference: data.regulationReference,
        fields: data.fields,
        is_active: data.isActive,
        sort_order: data.sortOrder,
      })
      .eq('id', id);

    if (err) throw err;
  };

  const deleteTemplate = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('form_templates')
      .delete()
      .eq('id', id);

    if (err) throw err;
  };

  return { templates, loading, error, createTemplate, updateTemplate, deleteTemplate, refresh: fetchTemplates };
}

export function useCertifications() {
  const [certifications, setCertifications] = useState<Certification[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchCertifications = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('certifications')
        .select('*')
        .order('expiration_date');

      if (err) throw err;
      setCertifications((data || []).map(mapCertification));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load certifications';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchCertifications();

    const supabase = getSupabase();
    const channel = supabase
      .channel('certifications-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'certifications' }, () => {
        fetchCertifications();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchCertifications]);

  const createCertification = async (data: Partial<Certification>): Promise<string> => {
    const supabase = getSupabase();
    const { data: row, error: err } = await supabase
      .from('certifications')
      .insert({
        company_id: data.companyId,
        user_id: data.userId,
        certification_type: data.certificationType,
        certification_name: data.certificationName,
        issuing_authority: data.issuingAuthority,
        certification_number: data.certificationNumber,
        issued_date: data.issuedDate,
        expiration_date: data.expirationDate,
        renewal_required: data.renewalRequired ?? true,
        renewal_reminder_days: data.renewalReminderDays ?? 30,
        document_url: data.documentUrl,
        status: data.status || 'active',
        notes: data.notes,
      })
      .select()
      .single();

    if (err) throw err;
    writeCertAuditLog(row.id, 'created', {}, {
      certification_type: data.certificationType,
      certification_name: data.certificationName,
      user_id: data.userId,
      status: data.status || 'active',
    }, `Created certification: ${data.certificationName}`);
    return row.id;
  };

  const updateCertification = async (id: string, data: Partial<Certification>) => {
    // Capture previous state for audit
    const existing = certifications.find(c => c.id === id);
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('certifications')
      .update({
        certification_type: data.certificationType,
        certification_name: data.certificationName,
        issuing_authority: data.issuingAuthority,
        certification_number: data.certificationNumber,
        issued_date: data.issuedDate,
        expiration_date: data.expirationDate,
        renewal_required: data.renewalRequired,
        renewal_reminder_days: data.renewalReminderDays,
        document_url: data.documentUrl,
        status: data.status,
        notes: data.notes,
      })
      .eq('id', id);

    if (err) throw err;
    const action = existing && data.status && data.status !== existing.status ? 'status_changed' : 'updated';
    const summary = action === 'status_changed'
      ? `Status changed from ${existing?.status} to ${data.status}`
      : `Updated certification: ${data.certificationName || existing?.certificationName}`;
    writeCertAuditLog(id, action,
      existing ? { status: existing.status, certification_name: existing.certificationName } : {},
      { status: data.status, certification_name: data.certificationName },
      summary,
    );
  };

  const deleteCertification = async (id: string) => {
    const existing = certifications.find(c => c.id === id);
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('certifications')
      .delete()
      .eq('id', id);

    if (err) throw err;
    writeCertAuditLog(id, 'deleted',
      existing ? { certification_name: existing.certificationName, status: existing.status } : {},
      {},
      `Deleted certification: ${existing?.certificationName || id}`,
    );
  };

  return { certifications, loading, error, createCertification, updateCertification, deleteCertification, refresh: fetchCertifications };
}

// Certification audit log — immutable trail of changes
async function writeCertAuditLog(
  certificationId: string,
  action: 'created' | 'updated' | 'status_changed' | 'deleted' | 'renewed',
  previousValues: Record<string, unknown> = {},
  newValues: Record<string, unknown> = {},
  changeSummary?: string,
) {
  try {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const companyId = user.app_metadata?.company_id;
    if (!companyId) return;
    await supabase.from('certification_audit_log').insert({
      certification_id: certificationId,
      company_id: companyId,
      action,
      changed_by: user.id,
      previous_values: previousValues,
      new_values: newValues,
      change_summary: changeSummary,
    });
  } catch {
    // Audit log failure should not block the operation
  }
}

export function useCertificationTypes() {
  const [types, setTypes] = useState<CertificationTypeConfig[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchTypes = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('certification_types')
        .select('*')
        .eq('is_active', true)
        .order('sort_order');

      if (err) throw err;
      setTypes((data || []).map(mapCertificationType));
    } catch {
      // Fallback: if table doesn't exist yet, types will be empty
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTypes();
  }, [fetchTypes]);

  // Build a quick lookup map: typeKey → CertificationTypeConfig
  const typeMap = Object.fromEntries(types.map(t => [t.typeKey, t]));

  return { types, typeMap, loading, refresh: fetchTypes };
}

export function useApiKeys() {
  const [apiKeys, setApiKeys] = useState<ApiKey[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchApiKeys = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('api_keys')
        .select('*')
        .order('created_at', { ascending: false });

      if (err) throw err;
      setApiKeys((data || []).map(mapApiKey));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load API keys';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchApiKeys();
  }, [fetchApiKeys]);

  const revokeApiKey = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('api_keys')
      .update({ is_active: false })
      .eq('id', id);

    if (err) throw err;
    fetchApiKeys();
  };

  const deleteApiKey = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('api_keys')
      .delete()
      .eq('id', id);

    if (err) throw err;
  };

  return { apiKeys, loading, error, revokeApiKey, deleteApiKey, refresh: fetchApiKeys };
}
