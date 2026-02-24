'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapInspection } from './mappers';
import type { InspectionData } from './mappers';

export function useInspections() {
  const [inspections, setInspections] = useState<InspectionData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchInspections = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('compliance_records')
        .select('*, jobs(title, customer_name, address, city, state)')
        .eq('record_type', 'inspection')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setInspections((data || []).map(mapInspection));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load inspections';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchInspections();

    const supabase = getSupabase();
    const channel = supabase
      .channel('inspections-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'compliance_records' }, () => {
        fetchInspections();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchInspections]);

  const createInspection = async (input: {
    jobId: string;
    type: string;
    title: string;
    assignedTo: string;
    scheduledDate?: Date;
    checklist?: { id: string; label: string; completed: boolean; photoRequired: boolean; hasPhoto: boolean }[];
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('compliance_records')
      .insert({
        company_id: companyId,
        job_id: input.jobId,
        created_by_user_id: user.id,
        record_type: 'inspection',
        status: 'scheduled',
        started_at: input.scheduledDate ? input.scheduledDate.toISOString() : null,
        data: {
          inspection_type: input.type,
          title: input.title,
          assigned_to: input.assignedTo,
          checklist: input.checklist || [],
          notes: input.notes || null,
          overall_score: null,
          photo_count: 0,
        },
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateInspectionStatus = async (id: string, status: string) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = { status };
    if (status === 'passed' || status === 'failed') {
      updateData.ended_at = new Date().toISOString();
    }
    const { error: err } = await supabase.from('compliance_records').update(updateData).eq('id', id);
    if (err) throw err;
  };

  return { inspections, loading, error, createInspection, updateInspectionStatus, refetch: fetchInspections };
}
