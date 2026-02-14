'use client';

// Client Portal: fetch documents scoped to the authenticated customer
// Documents can be linked via customer_id directly, or through jobs the customer owns.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '../supabase';
import { useAuth } from '@/components/auth-provider';

const supabase = getSupabase();

export interface ClientDocument {
  id: string;
  name: string;
  fileType: string;
  documentType: string;
  fileSizeBytes: number;
  storagePath: string | null;
  jobName: string | null;
  createdAt: string;
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export function useClientDocuments() {
  const { profile } = useAuth();
  const [documents, setDocuments] = useState<ClientDocument[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDocuments = useCallback(async () => {
    if (!profile?.customerId) { setLoading(false); return; }

    try {
      setLoading(true);

      // Get customer's jobs for name lookup
      const { data: jobs } = await supabase
        .from('jobs')
        .select('id, name')
        .eq('customer_id', profile.customerId)
        .is('deleted_at', null);

      const jobMap = new Map<string, string>(
        (jobs || []).map((j: { id: string; name: string }) => [j.id, j.name])
      );
      const jobIds = (jobs || []).map((j: { id: string }) => j.id);

      // Fetch documents linked to this customer directly
      const { data: directDocs, error: directErr } = await supabase
        .from('documents')
        .select('id, name, file_type, document_type, file_size_bytes, storage_path, job_id, created_at')
        .eq('customer_id', profile.customerId)
        .eq('status', 'active')
        .eq('is_latest', true)
        .order('created_at', { ascending: false });

      if (directErr) throw directErr;

      // Also fetch docs linked to customer's jobs (that might not have customer_id set)
      let jobDocs: typeof directDocs = [];
      if (jobIds.length > 0) {
        const { data: jDocs, error: jErr } = await supabase
          .from('documents')
          .select('id, name, file_type, document_type, file_size_bytes, storage_path, job_id, created_at')
          .in('job_id', jobIds)
          .eq('status', 'active')
          .eq('is_latest', true)
          .order('created_at', { ascending: false });

        if (jErr) throw jErr;
        jobDocs = jDocs || [];
      }

      // Merge and deduplicate
      const allDocsMap = new Map<string, Record<string, unknown>>();
      for (const doc of [...(directDocs || []), ...jobDocs]) {
        allDocsMap.set(doc.id, doc);
      }

      const mapped: ClientDocument[] = Array.from(allDocsMap.values()).map((d: Record<string, unknown>) => ({
        id: d.id as string,
        name: d.name as string,
        fileType: (d.file_type || 'pdf') as string,
        documentType: (d.document_type || 'general') as string,
        fileSizeBytes: (d.file_size_bytes || 0) as number,
        storagePath: d.storage_path as string | null,
        jobName: d.job_id ? (jobMap.get(d.job_id as string) || null) : null,
        createdAt: d.created_at as string,
      }));

      // Sort by created_at descending
      mapped.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

      setDocuments(mapped);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load documents');
    } finally {
      setLoading(false);
    }
  }, [profile?.customerId]);

  useEffect(() => { fetchDocuments(); }, [fetchDocuments]);

  useEffect(() => {
    const channel = supabase
      .channel('client-documents-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'documents' }, () => fetchDocuments())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchDocuments]);

  return { documents, loading, error, refresh: fetchDocuments, formatFileSize };
}
