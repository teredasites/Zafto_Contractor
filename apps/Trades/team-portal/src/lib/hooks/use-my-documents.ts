'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type DocumentCategory = 'pay_stubs' | 'contracts' | 'training_certs' | 'job_docs' | 'company' | 'other';

export interface DocumentData {
  id: string;
  companyId: string;
  uploadedByUserId: string;
  name: string;
  fileName: string;
  fileType: string;
  fileSize: number;
  category: DocumentCategory;
  storagePath: string;
  description: string;
  sharedWith: string[];
  jobId: string | null;
  createdAt: string;
}

export interface ZDocsRenderData {
  id: string;
  entityType: string;
  entityId: string;
  templateName: string;
  status: 'pending' | 'rendering' | 'completed' | 'failed';
  outputPath: string | null;
  createdAt: string;
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapDocument(row: Record<string, unknown>): DocumentData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    uploadedByUserId: (row.uploaded_by_user_id as string) || '',
    name: (row.name as string) || '',
    fileName: (row.file_name as string) || '',
    fileType: (row.file_type as string) || '',
    fileSize: (row.file_size as number) || 0,
    category: (row.category as DocumentCategory) || 'other',
    storagePath: (row.storage_path as string) || '',
    description: (row.description as string) || '',
    sharedWith: (row.shared_with as string[]) || [],
    jobId: (row.job_id as string) || null,
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

function mapZDocsRender(row: Record<string, unknown>): ZDocsRenderData {
  return {
    id: row.id as string,
    entityType: (row.entity_type as string) || '',
    entityId: (row.entity_id as string) || '',
    templateName: (row.template_name as string) || '',
    status: (row.status as ZDocsRenderData['status']) || 'pending',
    outputPath: (row.output_path as string) || null,
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

// ============================================================================
// HOOK: useMyDocuments (team portal — scoped to current user)
// ============================================================================

export function useMyDocuments() {
  const [documents, setDocuments] = useState<DocumentData[]>([]);
  const [renders, setRenders] = useState<ZDocsRenderData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      // Fetch documents uploaded by user OR shared with user
      const [ownDocsRes, sharedDocsRes, rendersRes] = await Promise.all([
        supabase
          .from('documents')
          .select('*')
          .eq('uploaded_by_user_id', user.id)
          .order('created_at', { ascending: false })
          .limit(100),
        supabase
          .from('documents')
          .select('*')
          .contains('shared_with', [user.id])
          .order('created_at', { ascending: false })
          .limit(100),
        supabase
          .from('zdocs_renders')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(50),
      ]);

      if (ownDocsRes.error) throw ownDocsRes.error;
      if (sharedDocsRes.error) throw sharedDocsRes.error;
      if (rendersRes.error) throw rendersRes.error;

      // Merge and deduplicate documents
      const allDocs = [
        ...(ownDocsRes.data || []),
        ...(sharedDocsRes.data || []),
      ];
      const seen = new Set<string>();
      const uniqueDocs = allDocs.filter(d => {
        const id = (d as Record<string, unknown>).id as string;
        if (seen.has(id)) return false;
        seen.add(id);
        return true;
      });

      setDocuments(uniqueDocs.map((row: Record<string, unknown>) => mapDocument(row)));
      setRenders((rendersRes.data || []).map((row: Record<string, unknown>) => mapZDocsRender(row)));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load documents';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();

    const supabase = getSupabase();
    const channel = supabase
      .channel('team-documents')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'documents' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'zdocs_renders' }, () => fetchData())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchData]);

  // Group documents by category
  const byCategory = useMemo(() => {
    const groups: Record<DocumentCategory, DocumentData[]> = {
      pay_stubs: [],
      contracts: [],
      training_certs: [],
      job_docs: [],
      company: [],
      other: [],
    };
    documents.forEach(doc => {
      const cat = groups[doc.category] ? doc.category : 'other';
      groups[cat].push(doc);
    });
    return groups;
  }, [documents]);

  // Get download URL for a document
  const getDownloadUrl = async (storagePath: string): Promise<string> => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase.storage
      .from('documents')
      .createSignedUrl(storagePath, 3600); // 1 hour expiry

    if (err) throw err;
    return data.signedUrl;
  };

  return {
    documents, renders, byCategory,
    loading, error,
    getDownloadUrl,
    refetch: fetchData,
  };
}

// ============================================================================
// HELPERS
// ============================================================================

export const CATEGORY_LABELS: Record<DocumentCategory, string> = {
  pay_stubs: 'Pay Stubs',
  contracts: 'Contracts',
  training_certs: 'Training Certs',
  job_docs: 'Job Documents',
  company: 'Company',
  other: 'Other',
};

export const CATEGORY_COLORS: Record<DocumentCategory, { bg: string; text: string }> = {
  pay_stubs: { bg: 'bg-emerald-100 dark:bg-emerald-900/30', text: 'text-emerald-700 dark:text-emerald-300' },
  contracts: { bg: 'bg-blue-100 dark:bg-blue-900/30', text: 'text-blue-700 dark:text-blue-300' },
  training_certs: { bg: 'bg-purple-100 dark:bg-purple-900/30', text: 'text-purple-700 dark:text-purple-300' },
  job_docs: { bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-700 dark:text-amber-300' },
  company: { bg: 'bg-slate-100 dark:bg-slate-900/30', text: 'text-slate-700 dark:text-slate-300' },
  other: { bg: 'bg-slate-100 dark:bg-slate-900/30', text: 'text-slate-600 dark:text-slate-400' },
};

export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
}
