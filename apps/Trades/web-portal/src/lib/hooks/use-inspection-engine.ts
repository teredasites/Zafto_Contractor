'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface InspectionTemplate {
  id: string;
  companyId: string | null;
  trade: string | null;
  category: string;
  name: string;
  description: string | null;
  items: Array<{ section: string; title: string; description?: string; requiresPhotoOnFail?: boolean }>;
  isSystem: boolean;
  isActive: boolean;
}

export interface InspectionResult {
  id: string;
  companyId: string;
  jobId: string | null;
  jobTitle?: string;
  templateId: string | null;
  title: string;
  inspectorId: string;
  inspectorName: string;
  items: Array<{ itemTitle: string; status: string; note?: string; photoPath?: string }>;
  totalItems: number;
  passedItems: number;
  failedItems: number;
  naItems: number;
  status: string;
  completedAt: string | null;
  signaturePath: string | null;
  overallResult: string | null;
  notes: string | null;
  createdAt: string;
}

function mapTemplate(row: Record<string, unknown>): InspectionTemplate {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || null,
    trade: (row.trade as string) || null,
    category: (row.category as string) || 'inspection',
    name: row.name as string,
    description: (row.description as string) || null,
    items: (row.items as InspectionTemplate['items']) || [],
    isSystem: (row.is_system as boolean) || false,
    isActive: (row.is_active as boolean) ?? true,
  };
}

function mapResult(row: Record<string, unknown>): InspectionResult {
  const job = row.jobs as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    jobId: (row.job_id as string) || null,
    jobTitle: (job?.title as string) || undefined,
    templateId: (row.template_id as string) || null,
    title: row.title as string,
    inspectorId: row.inspector_id as string,
    inspectorName: row.inspector_name as string,
    items: (row.items as InspectionResult['items']) || [],
    totalItems: (row.total_items as number) || 0,
    passedItems: (row.passed_items as number) || 0,
    failedItems: (row.failed_items as number) || 0,
    naItems: (row.na_items as number) || 0,
    status: row.status as string,
    completedAt: (row.completed_at as string) || null,
    signaturePath: (row.signature_path as string) || null,
    overallResult: (row.overall_result as string) || null,
    notes: (row.notes as string) || null,
    createdAt: row.created_at as string,
  };
}

export function useInspectionEngine() {
  const [results, setResults] = useState<InspectionResult[]>([]);
  const [templates, setTemplates] = useState<InspectionTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const [resultsRes, templatesRes] = await Promise.all([
        supabase
          .from('inspection_results')
          .select('*, jobs(title)')
          .order('created_at', { ascending: false })
          .limit(100),
        supabase
          .from('inspection_templates')
          .select('*')
          .eq('is_active', true)
          .is('deleted_at', null)
          .order('name'),
      ]);

      if (resultsRes.error) throw resultsRes.error;
      if (templatesRes.error) throw templatesRes.error;

      setResults((resultsRes.data || []).map(mapResult));
      setTemplates((templatesRes.data || []).map(mapTemplate));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load inspections');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();

    const supabase = getSupabase();
    const channel = supabase
      .channel('inspection-results-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'inspection_results' }, () => fetchData())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchData]);

  const inProgress = results.filter(r => r.status === 'in_progress');
  const completed = results.filter(r => r.status === 'completed' || r.status === 'signed');
  const failed = results.filter(r => r.overallResult === 'fail');

  return { results, templates, inProgress, completed, failed, loading, error, refetch: fetchData };
}
