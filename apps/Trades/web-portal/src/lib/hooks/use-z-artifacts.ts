'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import type { ZArtifactType, ZArtifactStatus } from '@/lib/z-intelligence/types';

export interface ZArtifactRow {
  id: string;
  threadId: string | null;
  type: ZArtifactType;
  title: string;
  content: string;
  data: Record<string, unknown>;
  versions: Array<{ version: number; content: string; data: Record<string, unknown>; createdAt: string }>;
  currentVersion: number;
  status: ZArtifactStatus;
  approvedBy: string | null;
  approvedAt: string | null;
  sourceJobId: string | null;
  sourceCustomerId: string | null;
  convertedToBidId: string | null;
  convertedToInvoiceId: string | null;
  createdAt: string;
  updatedAt: string;
}

function mapArtifact(row: Record<string, unknown>): ZArtifactRow {
  return {
    id: row.id as string,
    threadId: row.thread_id as string | null,
    type: row.type as ZArtifactType,
    title: row.title as string,
    content: row.content as string,
    data: (row.data as Record<string, unknown>) || {},
    versions: (row.versions as ZArtifactRow['versions']) || [],
    currentVersion: (row.current_version as number) || 1,
    status: row.status as ZArtifactStatus,
    approvedBy: row.approved_by as string | null,
    approvedAt: row.approved_at as string | null,
    sourceJobId: row.source_job_id as string | null,
    sourceCustomerId: row.source_customer_id as string | null,
    convertedToBidId: row.converted_to_bid_id as string | null,
    convertedToInvoiceId: row.converted_to_invoice_id as string | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

export function useZArtifacts(filters?: { type?: ZArtifactType; status?: ZArtifactStatus }) {
  const [artifacts, setArtifacts] = useState<ZArtifactRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchArtifacts = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      let query = supabase
        .from('z_artifacts')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(50);

      if (filters?.type) query = query.eq('type', filters.type);
      if (filters?.status) query = query.eq('status', filters.status);

      const { data, error: err } = await query;
      if (err) throw err;
      setArtifacts((data || []).map(mapArtifact));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load artifacts';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [filters?.type, filters?.status]);

  useEffect(() => {
    fetchArtifacts();

    const supabase = getSupabase();
    const channel = supabase
      .channel('z-artifacts-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'z_artifacts' }, () => {
        fetchArtifacts();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchArtifacts]);

  const updateArtifactStatus = useCallback(async (
    artifactId: string,
    status: ZArtifactStatus,
    approvedBy?: string
  ) => {
    try {
      const supabase = getSupabase();
      const update: Record<string, unknown> = { status };
      if (status === 'approved' && approvedBy) {
        update.approved_by = approvedBy;
        update.approved_at = new Date().toISOString();
      }
      await supabase
        .from('z_artifacts')
        .update(update)
        .eq('id', artifactId);
    } catch (e: unknown) {
      console.error('Failed to update artifact status:', e);
    }
  }, []);

  const convertArtifact = useCallback(async (
    artifactId: string,
    targetType: 'bid' | 'invoice',
    targetId: string
  ) => {
    try {
      const supabase = getSupabase();
      const field = targetType === 'bid' ? 'converted_to_bid_id' : 'converted_to_invoice_id';
      await supabase
        .from('z_artifacts')
        .update({ [field]: targetId, status: 'approved' })
        .eq('id', artifactId);
    } catch (e: unknown) {
      console.error('Failed to convert artifact:', e);
    }
  }, []);

  return { artifacts, loading, error, fetchArtifacts, updateArtifactStatus, convertArtifact };
}

export function useZArtifact(artifactId: string | null) {
  const [artifact, setArtifact] = useState<ZArtifactRow | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!artifactId) {
      setArtifact(null);
      return;
    }

    const fetchArtifact = async () => {
      setLoading(true);
      try {
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('z_artifacts')
          .select('*')
          .eq('id', artifactId)
          .single();

        if (err) throw err;
        setArtifact(data ? mapArtifact(data) : null);
      } catch {
        setArtifact(null);
      } finally {
        setLoading(false);
      }
    };

    fetchArtifact();
  }, [artifactId]);

  return { artifact, loading };
}
