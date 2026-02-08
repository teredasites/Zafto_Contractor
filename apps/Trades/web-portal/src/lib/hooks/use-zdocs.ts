'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// ZDocs Hook — Templates, Renders, Sections, Signatures + Real-time
// ============================================================

// ==================== TYPES ====================

export interface TemplateVariable {
  name: string;
  label: string;
  type: string;
  defaultValue: string | null;
}

export interface ZDocsTemplate {
  id: string;
  companyId: string;
  name: string;
  description: string | null;
  templateType: string;
  contentHtml: string | null;
  variables: TemplateVariable[];
  isActive: boolean;
  isSystem: boolean;
  requiresSignature: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ZDocsSection {
  id: string;
  templateId: string;
  sectionType: string;
  title: string;
  contentHtml: string | null;
  config: Record<string, unknown> | null;
  sortOrder: number;
  isRequired: boolean;
  isConditional: boolean;
  conditionField: string | null;
  conditionValue: string | null;
  createdAt: string;
}

export interface ZDocsRender {
  id: string;
  companyId: string;
  templateId: string;
  entityType: string | null;
  entityId: string | null;
  title: string;
  renderedHtml: string | null;
  pdfStoragePath: string | null;
  dataSnapshot: Record<string, unknown> | null;
  variablesUsed: Record<string, unknown> | null;
  status: string;
  requiresSignature: boolean;
  signatureStatus: string | null;
  signatureRequestedAt: string | null;
  signedAt: string | null;
  sentToEmail: string | null;
  sentAt: string | null;
  renderedByUserId: string | null;
  createdAt: string;
  // Joined data
  templateName?: string;
  templateType?: string;
}

export interface ZDocsSignatureRequest {
  id: string;
  renderId: string;
  signerName: string;
  signerEmail: string;
  signerRole: string | null;
  status: string;
  sentAt: string | null;
  viewedAt: string | null;
  signedAt: string | null;
  accessToken: string | null;
  expiresAt: string | null;
}

export const ZDOCS_TEMPLATE_TYPES = [
  'contract', 'proposal', 'lien_waiver', 'change_order', 'invoice',
  'warranty', 'scope_of_work', 'safety_plan', 'daily_report',
  'inspection_report', 'completion_cert', 'other',
] as const;

export const ZDOCS_TEMPLATE_TYPE_LABELS: Record<string, string> = {
  contract: 'Contract',
  proposal: 'Proposal',
  lien_waiver: 'Lien Waiver',
  change_order: 'Change Order',
  invoice: 'Invoice',
  warranty: 'Warranty',
  scope_of_work: 'Scope of Work',
  safety_plan: 'Safety Plan',
  daily_report: 'Daily Report',
  inspection_report: 'Inspection Report',
  completion_cert: 'Completion Certificate',
  other: 'Other',
};

export const ZDOCS_ENTITY_TYPES = [
  'job', 'customer', 'estimate', 'invoice', 'bid', 'property',
] as const;

export const ZDOCS_ENTITY_TYPE_LABELS: Record<string, string> = {
  job: 'Job',
  customer: 'Customer',
  estimate: 'Estimate',
  invoice: 'Invoice',
  bid: 'Bid',
  property: 'Property',
};

export const ZDOCS_RENDER_STATUSES = [
  'draft', 'rendered', 'sent', 'signed',
] as const;

export const ZDOCS_SIGNATURE_STATUSES = [
  'pending', 'sent', 'viewed', 'signed', 'declined', 'expired',
] as const;

// ==================== MAPPERS ====================

function mapTemplate(row: Record<string, unknown>): ZDocsTemplate {
  const rawVars = row.variables;
  let variables: TemplateVariable[] = [];
  if (Array.isArray(rawVars)) {
    variables = rawVars as TemplateVariable[];
  } else if (rawVars && typeof rawVars === 'object') {
    variables = [];
  }

  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    name: (row.name as string) || '',
    description: row.description as string | null,
    templateType: (row.template_type as string) || 'other',
    contentHtml: row.content_html as string | null,
    variables,
    isActive: (row.is_active as boolean) ?? true,
    isSystem: (row.is_system as boolean) ?? false,
    requiresSignature: (row.requires_signature as boolean) ?? false,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapRender(row: Record<string, unknown>): ZDocsRender {
  const templateData = row.document_templates as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    templateId: (row.template_id as string) || '',
    entityType: row.entity_type as string | null,
    entityId: row.entity_id as string | null,
    title: (row.title as string) || '',
    renderedHtml: row.rendered_html as string | null,
    pdfStoragePath: row.pdf_storage_path as string | null,
    dataSnapshot: row.data_snapshot as Record<string, unknown> | null,
    variablesUsed: row.variables_used as Record<string, unknown> | null,
    status: (row.status as string) || 'draft',
    requiresSignature: (row.requires_signature as boolean) ?? false,
    signatureStatus: row.signature_status as string | null,
    signatureRequestedAt: row.signature_requested_at as string | null,
    signedAt: row.signed_at as string | null,
    sentToEmail: row.sent_to_email as string | null,
    sentAt: row.sent_at as string | null,
    renderedByUserId: row.rendered_by_user_id as string | null,
    createdAt: row.created_at as string,
    templateName: templateData ? (templateData.name as string) || '' : undefined,
    templateType: templateData ? (templateData.template_type as string) || '' : undefined,
  };
}

function mapSignatureRequest(row: Record<string, unknown>): ZDocsSignatureRequest {
  return {
    id: row.id as string,
    renderId: (row.render_id as string) || '',
    signerName: (row.signer_name as string) || '',
    signerEmail: (row.signer_email as string) || '',
    signerRole: row.signer_role as string | null,
    status: (row.status as string) || 'pending',
    sentAt: row.sent_at as string | null,
    viewedAt: row.viewed_at as string | null,
    signedAt: row.signed_at as string | null,
    accessToken: row.access_token as string | null,
    expiresAt: row.expires_at as string | null,
  };
}

// ==================== HOOK ====================

export function useZDocs() {
  const [templates, setTemplates] = useState<ZDocsTemplate[]>([]);
  const [renders, setRenders] = useState<ZDocsRender[]>([]);
  const [signatureRequests, setSignatureRequests] = useState<ZDocsSignatureRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTemplates = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('document_templates')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);

      if (err) throw err;
      setTemplates((data || []).map((r: Record<string, unknown>) => mapTemplate(r)));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load templates';
      setError(msg);
    }
  }, []);

  const fetchRenders = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('zdocs_renders')
        .select('*, document_templates(name, template_type)')
        .order('created_at', { ascending: false })
        .limit(100);

      if (err) throw err;
      setRenders((data || []).map((r: Record<string, unknown>) => mapRender(r)));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load renders';
      setError(msg);
    }
  }, []);

  const fetchSignatureRequests = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('zdocs_signature_requests')
        .select('*')
        .order('sent_at', { ascending: false });

      if (err) throw err;
      setSignatureRequests((data || []).map((r: Record<string, unknown>) => mapSignatureRequest(r)));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load signature requests';
      setError(msg);
    }
  }, []);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    setError(null);
    await Promise.all([fetchTemplates(), fetchRenders(), fetchSignatureRequests()]);
    setLoading(false);
  }, [fetchTemplates, fetchRenders, fetchSignatureRequests]);

  useEffect(() => {
    fetchAll();

    const supabase = getSupabase();
    const channel = supabase
      .channel('zdocs-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'zdocs_renders' }, () => {
        fetchRenders();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'zdocs_signature_requests' }, () => {
        fetchSignatureRequests();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'document_templates' }, () => {
        fetchTemplates();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchAll, fetchTemplates, fetchRenders, fetchSignatureRequests]);

  // ==================== MUTATIONS ====================

  const createTemplate = async (data: {
    name: string;
    description?: string;
    templateType: string;
    contentHtml?: string;
    variables?: TemplateVariable[];
    requiresSignature?: boolean;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('document_templates')
      .insert({
        company_id: companyId,
        name: data.name,
        description: data.description || null,
        template_type: data.templateType,
        content_html: data.contentHtml || null,
        variables: data.variables || [],
        is_active: true,
        is_system: false,
        requires_signature: data.requiresSignature || false,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateTemplate = async (id: string, data: Partial<{
    name: string;
    description: string | null;
    templateType: string;
    contentHtml: string | null;
    variables: TemplateVariable[];
    isActive: boolean;
    requiresSignature: boolean;
  }>) => {
    const supabase = getSupabase();
    const update: Record<string, unknown> = {};
    if (data.name !== undefined) update.name = data.name;
    if (data.description !== undefined) update.description = data.description;
    if (data.templateType !== undefined) update.template_type = data.templateType;
    if (data.contentHtml !== undefined) update.content_html = data.contentHtml;
    if (data.variables !== undefined) update.variables = data.variables;
    if (data.isActive !== undefined) update.is_active = data.isActive;
    if (data.requiresSignature !== undefined) update.requires_signature = data.requiresSignature;

    const { error: err } = await supabase.from('document_templates').update(update).eq('id', id);
    if (err) throw err;
  };

  const deleteTemplate = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('document_templates')
      .update({ is_active: false })
      .eq('id', id);
    if (err) throw err;
  };

  const renderDocument = async (data: {
    templateId: string;
    entityType?: string;
    entityId?: string;
    title?: string;
    customVariables?: Record<string, unknown>;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Fetch the template to get content
    const template = templates.find((t) => t.id === data.templateId);
    const templateName = template?.name || 'Untitled';
    const title = data.title || templateName;

    const { data: result, error: err } = await supabase
      .from('zdocs_renders')
      .insert({
        company_id: companyId,
        template_id: data.templateId,
        entity_type: data.entityType || null,
        entity_id: data.entityId || null,
        title,
        rendered_html: template?.contentHtml || null,
        status: 'rendered',
        requires_signature: template?.requiresSignature || false,
        signature_status: template?.requiresSignature ? 'pending' : null,
        variables_used: data.customVariables || null,
        rendered_by_user_id: user.id,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const sendForSignature = async (renderId: string, signers: {
    name: string;
    email: string;
    role?: string;
  }[]) => {
    const supabase = getSupabase();

    const inserts = signers.map((signer) => ({
      render_id: renderId,
      signer_name: signer.name,
      signer_email: signer.email,
      signer_role: signer.role || null,
      status: 'sent',
      sent_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 days
    }));

    const { error: insertErr } = await supabase
      .from('zdocs_signature_requests')
      .insert(inserts);

    if (insertErr) throw insertErr;

    // Update render signature status
    const { error: updateErr } = await supabase
      .from('zdocs_renders')
      .update({
        signature_status: 'sent',
        signature_requested_at: new Date().toISOString(),
      })
      .eq('id', renderId);

    if (updateErr) throw updateErr;
  };

  const duplicateTemplate = async (id: string): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const template = templates.find((t) => t.id === id);
    if (!template) throw new Error('Template not found');

    const { data: result, error: err } = await supabase
      .from('document_templates')
      .insert({
        company_id: companyId,
        name: `Copy of ${template.name}`,
        description: template.description,
        template_type: template.templateType,
        content_html: template.contentHtml,
        variables: template.variables,
        is_active: true,
        is_system: false,
        requires_signature: template.requiresSignature,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const deleteRender = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase.from('zdocs_renders').delete().eq('id', id);
    if (err) throw err;
  };

  // ==================== COMPUTED ====================

  const activeTemplates = useMemo(
    () => templates.filter((t) => t.isActive),
    [templates]
  );

  const totalRenders = useMemo(() => renders.length, [renders]);

  const pendingSignatures = useMemo(
    () => renders.filter((r) => r.signatureStatus === 'sent' || r.signatureStatus === 'viewed'),
    [renders]
  );

  const recentRenders = useMemo(() => {
    const thirtyDaysAgo = Date.now() - 30 * 24 * 60 * 60 * 1000;
    return renders.filter((r) => new Date(r.createdAt).getTime() > thirtyDaysAgo);
  }, [renders]);

  return {
    templates,
    renders,
    signatureRequests,
    loading,
    error,
    // Mutations
    createTemplate,
    updateTemplate,
    deleteTemplate,
    renderDocument,
    sendForSignature,
    duplicateTemplate,
    deleteRender,
    // Computed
    activeTemplates,
    totalRenders,
    pendingSignatures,
    recentRenders,
    // Refetch
    refetch: fetchAll,
  };
}
