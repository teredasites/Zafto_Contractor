'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Documents Hook — Folders, Documents, Templates + Real-time
// ============================================================

export interface DocumentFolder {
  id: string;
  companyId: string;
  parentId: string | null;
  name: string;
  path: string;
  folderType: string;
  relatedType: string | null;
  relatedId: string | null;
  icon: string | null;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
}

export interface DocumentData {
  id: string;
  companyId: string;
  folderId: string | null;
  name: string;
  fileType: string;
  mimeType: string | null;
  fileSizeBytes: number;
  storagePath: string | null;
  documentType: string;
  jobId: string | null;
  customerId: string | null;
  propertyId: string | null;
  version: number;
  parentDocumentId: string | null;
  isLatest: boolean;
  status: string;
  requiresSignature: boolean;
  signatureStatus: string | null;
  signedAt: string | null;
  signedBy: string | null;
  signaturePath: string | null;
  docusignEnvelopeId: string | null;
  tags: string[];
  description: string | null;
  uploadedByUserId: string | null;
  createdAt: string;
  updatedAt: string;
  // Joined data
  jobTitle?: string;
  customerName?: string;
}

export interface DocumentTemplate {
  id: string;
  companyId: string;
  name: string;
  description: string | null;
  templateType: string;
  contentHtml: string | null;
  storagePath: string | null;
  variables: Record<string, unknown> | null;
  isActive: boolean;
  isSystem: boolean;
  requiresSignature: boolean;
  createdAt: string;
  updatedAt: string;
}

export const DOCUMENT_TYPES = [
  'general', 'contract', 'proposal', 'lien_waiver', 'permit',
  'insurance_cert', 'change_order', 'invoice', 'receipt', 'photo',
  'plan', 'specification', 'warranty', 'license', 'certificate',
  'report', 'other',
] as const;

export const DOCUMENT_TYPE_LABELS: Record<string, string> = {
  general: 'General',
  contract: 'Contract',
  proposal: 'Proposal',
  lien_waiver: 'Lien Waiver',
  permit: 'Permit',
  insurance_cert: 'Insurance Cert',
  change_order: 'Change Order',
  invoice: 'Invoice',
  receipt: 'Receipt',
  photo: 'Photo',
  plan: 'Plan',
  specification: 'Specification',
  warranty: 'Warranty',
  license: 'License',
  certificate: 'Certificate',
  report: 'Report',
  other: 'Other',
};

export const TEMPLATE_TYPES = [
  'contract', 'proposal', 'lien_waiver', 'change_order', 'invoice',
  'warranty', 'scope_of_work', 'safety_plan', 'daily_report', 'other',
] as const;

export const TEMPLATE_TYPE_LABELS: Record<string, string> = {
  contract: 'Contract',
  proposal: 'Proposal',
  lien_waiver: 'Lien Waiver',
  change_order: 'Change Order',
  invoice: 'Invoice',
  warranty: 'Warranty',
  scope_of_work: 'Scope of Work',
  safety_plan: 'Safety Plan',
  daily_report: 'Daily Report',
  other: 'Other',
};

function mapFolder(row: Record<string, unknown>): DocumentFolder {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    parentId: row.parent_id as string | null,
    name: row.name as string,
    path: row.path as string,
    folderType: row.folder_type as string,
    relatedType: row.related_type as string | null,
    relatedId: row.related_id as string | null,
    icon: row.icon as string | null,
    sortOrder: (row.sort_order as number) ?? 0,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapDocument(row: Record<string, unknown>): DocumentData {
  const jobs = row.jobs as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    folderId: row.folder_id as string | null,
    name: row.name as string,
    fileType: row.file_type as string,
    mimeType: row.mime_type as string | null,
    fileSizeBytes: (row.file_size_bytes as number) ?? 0,
    storagePath: row.storage_path as string | null,
    documentType: row.document_type as string,
    jobId: row.job_id as string | null,
    customerId: row.customer_id as string | null,
    propertyId: row.property_id as string | null,
    version: (row.version as number) ?? 1,
    parentDocumentId: row.parent_document_id as string | null,
    isLatest: row.is_latest as boolean,
    status: row.status as string,
    requiresSignature: row.requires_signature as boolean,
    signatureStatus: row.signature_status as string | null,
    signedAt: row.signed_at as string | null,
    signedBy: row.signed_by as string | null,
    signaturePath: row.signature_path as string | null,
    docusignEnvelopeId: row.docusign_envelope_id as string | null,
    tags: (row.tags as string[]) ?? [],
    description: row.description as string | null,
    uploadedByUserId: row.uploaded_by_user_id as string | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
    jobTitle: jobs?.title as string | undefined,
    customerName: jobs?.customer_name as string | undefined,
  };
}

function mapTemplate(row: Record<string, unknown>): DocumentTemplate {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    name: row.name as string,
    description: row.description as string | null,
    templateType: row.template_type as string,
    contentHtml: row.content_html as string | null,
    storagePath: row.storage_path as string | null,
    variables: row.variables as Record<string, unknown> | null,
    isActive: row.is_active as boolean,
    isSystem: row.is_system as boolean,
    requiresSignature: row.requires_signature as boolean,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

export function useDocuments() {
  const [documents, setDocuments] = useState<DocumentData[]>([]);
  const [folders, setFolders] = useState<DocumentFolder[]>([]);
  const [templates, setTemplates] = useState<DocumentTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDocuments = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const [docsRes, foldersRes, templatesRes] = await Promise.all([
        supabase
          .from('documents')
          .select('*, jobs(title, customer_name)')
          .eq('is_latest', true)
          .eq('status', 'active')
          .order('created_at', { ascending: false }),
        supabase
          .from('document_folders')
          .select('*')
          .order('sort_order', { ascending: true }),
        supabase
          .from('document_templates')
          .select('*')
          .eq('is_active', true)
          .order('name'),
      ]);

      if (docsRes.error) throw docsRes.error;
      if (foldersRes.error) throw foldersRes.error;
      if (templatesRes.error) throw templatesRes.error;

      setDocuments((docsRes.data || []).map((r: Record<string, unknown>) => mapDocument(r)));
      setFolders((foldersRes.data || []).map((r: Record<string, unknown>) => mapFolder(r)));
      setTemplates((templatesRes.data || []).map((r: Record<string, unknown>) => mapTemplate(r)));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load documents');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchDocuments();

    const supabase = getSupabase();
    const channel = supabase
      .channel('documents-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'documents' }, () => {
        fetchDocuments();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchDocuments]);

  // Mutations

  const createFolder = async (data: {
    name: string;
    parentId?: string;
    folderType?: string;
    icon?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const parentPath = data.parentId
      ? folders.find((f) => f.id === data.parentId)?.path || '/'
      : '/';
    const newPath = parentPath === '/' ? `/${data.name}` : `${parentPath}/${data.name}`;

    const { data: result, error: err } = await supabase
      .from('document_folders')
      .insert({
        company_id: companyId,
        parent_id: data.parentId || null,
        name: data.name,
        path: newPath,
        folder_type: data.folderType || 'custom',
        icon: data.icon || null,
        sort_order: folders.length,
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchDocuments();
    return result.id;
  };

  const uploadDocument = async (data: {
    name: string;
    fileType: string;
    mimeType?: string;
    fileSizeBytes?: number;
    storagePath?: string;
    documentType: string;
    folderId?: string;
    jobId?: string;
    customerId?: string;
    propertyId?: string;
    tags?: string[];
    description?: string;
    requiresSignature?: boolean;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('documents')
      .insert({
        company_id: companyId,
        folder_id: data.folderId || null,
        name: data.name,
        file_type: data.fileType,
        mime_type: data.mimeType || null,
        file_size_bytes: data.fileSizeBytes || 0,
        storage_path: data.storagePath || null,
        document_type: data.documentType,
        job_id: data.jobId || null,
        customer_id: data.customerId || null,
        property_id: data.propertyId || null,
        version: 1,
        is_latest: true,
        status: 'active',
        requires_signature: data.requiresSignature || false,
        signature_status: data.requiresSignature ? 'pending' : null,
        tags: data.tags || [],
        description: data.description || null,
        uploaded_by_user_id: user.id,
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchDocuments();
    return result.id;
  };

  const updateDocument = async (id: string, data: Partial<{
    name: string;
    documentType: string;
    folderId: string | null;
    jobId: string | null;
    customerId: string | null;
    tags: string[];
    description: string | null;
    requiresSignature: boolean;
    signatureStatus: string | null;
  }>) => {
    const supabase = getSupabase();
    const update: Record<string, unknown> = {};
    if (data.name !== undefined) update.name = data.name;
    if (data.documentType !== undefined) update.document_type = data.documentType;
    if (data.folderId !== undefined) update.folder_id = data.folderId;
    if (data.jobId !== undefined) update.job_id = data.jobId;
    if (data.customerId !== undefined) update.customer_id = data.customerId;
    if (data.tags !== undefined) update.tags = data.tags;
    if (data.description !== undefined) update.description = data.description;
    if (data.requiresSignature !== undefined) update.requires_signature = data.requiresSignature;
    if (data.signatureStatus !== undefined) update.signature_status = data.signatureStatus;

    const { error: err } = await supabase.from('documents').update(update).eq('id', id);
    if (err) throw err;
    await fetchDocuments();
  };

  const archiveDocument = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('documents')
      .update({ status: 'archived' })
      .eq('id', id);
    if (err) throw err;
    await fetchDocuments();
  };

  const createTemplate = async (data: {
    name: string;
    description?: string;
    templateType: string;
    contentHtml?: string;
    storagePath?: string;
    variables?: Record<string, unknown>;
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
        storage_path: data.storagePath || null,
        variables: data.variables || {},
        is_active: true,
        is_system: false,
        requires_signature: data.requiresSignature || false,
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchDocuments();
    return result.id;
  };

  const updateTemplate = async (id: string, data: Partial<{
    name: string;
    description: string | null;
    templateType: string;
    contentHtml: string | null;
    variables: Record<string, unknown>;
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
    await fetchDocuments();
  };

  // Computed values

  const totalDocuments = documents.length;

  const byType = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const doc of documents) {
      counts[doc.documentType] = (counts[doc.documentType] || 0) + 1;
    }
    return counts;
  }, [documents]);

  const recentlyUploaded = useMemo(() => {
    const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
    return documents.filter((d) => new Date(d.createdAt).getTime() > sevenDaysAgo);
  }, [documents]);

  const pendingSignatures = useMemo(() => {
    return documents.filter(
      (d) => d.requiresSignature && (d.signatureStatus === 'pending' || d.signatureStatus === 'sent')
    );
  }, [documents]);

  // U22: Auto-attach generated PDF to documents
  const autoAttachDocument = async (input: {
    entityType: string;
    entityId: string;
    name: string;
    storagePath: string;
    documentType: string;
    customerId?: string;
    jobId?: string;
  }) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { error: err } = await supabase.from('documents').insert({
      company_id: companyId,
      name: input.name,
      file_type: 'pdf',
      mime_type: 'application/pdf',
      storage_path: input.storagePath,
      document_type: input.documentType,
      entity_type: input.entityType,
      entity_id: input.entityId,
      customer_id: input.customerId || null,
      job_id: input.jobId || null,
      status: 'active',
      is_latest: true,
      version: 1,
    });
    if (err) throw err;
  };

  // U22: Get documents by entity
  const getDocumentsByEntity = (entityType: string, entityId: string) => {
    return documents.filter((d) =>
      (d as unknown as Record<string, unknown>).entity_type === entityType &&
      (d as unknown as Record<string, unknown>).entity_id === entityId
    );
  };

  return {
    documents,
    folders,
    templates,
    loading,
    error,
    // Mutations
    createFolder,
    uploadDocument,
    updateDocument,
    archiveDocument,
    createTemplate,
    updateTemplate,
    autoAttachDocument,
    // Computed
    totalDocuments,
    byType,
    recentlyUploaded,
    pendingSignatures,
    getDocumentsByEntity,
    // Refetch
    refetch: fetchDocuments,
  };
}
