'use client';

import { useEffect, useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

interface LegalReference {
  id: string;
  reference_type: string;
  reference_key: string;
  display_name: string;
  current_edition: string | null;
  next_review_cycle: string | null;
  last_verified_at: string;
  verified_by: string | null;
  source_url: string | null;
  affects_entities: string[];
  affects_sprints: string[];
  status: 'current' | 'review_due' | 'outdated' | 'superseded';
  notes: string | null;
  created_at: string;
  updated_at: string;
}

interface CheckLog {
  id: string;
  reference_id: string;
  checked_at: string;
  checked_by: string;
  result: string;
  notes: string | null;
  source_checked: string | null;
}

interface ComplianceHealthState {
  references: LegalReference[];
  checkLogs: CheckLog[];
  totalCount: number;
  currentCount: number;
  reviewDueCount: number;
  outdatedCount: number;
  supersededCount: number;
  byEntityType: Record<string, LegalReference[]>;
  byCategory: Record<string, LegalReference[]>;
  loading: boolean;
  error: string | null;
  markVerified: (referenceId: string, notes?: string) => Promise<void>;
  flagForUpdate: (referenceId: string, notes?: string) => Promise<void>;
  refresh: () => void;
}

/**
 * useComplianceHealth — LEGAL-4
 *
 * Fetches legal_reference_registry + check_log data for ops portal.
 * Computes staleness counts and provides actions to mark verified or flag for update.
 */
export function useComplianceHealth(): ComplianceHealthState {
  const [references, setReferences] = useState<LegalReference[]>([]);
  const [checkLogs, setCheckLogs] = useState<CheckLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        setLoading(true);
        const supabase = getSupabase();

        const [refsResult, logsResult] = await Promise.all([
          supabase
            .from('legal_reference_registry')
            .select('*')
            .order('status', { ascending: true })
            .order('display_name'),
          supabase
            .from('legal_reference_check_log')
            .select('*')
            .order('checked_at', { ascending: false })
            .limit(100),
        ]);

        if (cancelled) return;

        if (refsResult.error) {
          setError(refsResult.error.message);
          setLoading(false);
          return;
        }

        setReferences((refsResult.data as LegalReference[]) || []);
        setCheckLogs((logsResult.data as CheckLog[]) || []);
        setLoading(false);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : 'Failed to load compliance data');
          setLoading(false);
        }
      }
    }

    load();
    return () => { cancelled = true; };
  }, [refreshKey]);

  const totalCount = references.length;
  const currentCount = references.filter(r => r.status === 'current').length;
  const reviewDueCount = references.filter(r => r.status === 'review_due').length;
  const outdatedCount = references.filter(r => r.status === 'outdated').length;
  const supersededCount = references.filter(r => r.status === 'superseded').length;

  // Group by entity type
  const byEntityType: Record<string, LegalReference[]> = {};
  for (const ref of references) {
    for (const entity of (ref.affects_entities || [])) {
      if (!byEntityType[entity]) byEntityType[entity] = [];
      byEntityType[entity].push(ref);
    }
  }

  // Group by reference type
  const byCategory: Record<string, LegalReference[]> = {};
  for (const ref of references) {
    if (!byCategory[ref.reference_type]) byCategory[ref.reference_type] = [];
    byCategory[ref.reference_type].push(ref);
  }

  const markVerified = useCallback(async (referenceId: string, notes?: string) => {
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();

      await Promise.all([
        supabase
          .from('legal_reference_registry')
          .update({
            status: 'current',
            last_verified_at: new Date().toISOString(),
            verified_by: user?.email || 'system',
          })
          .eq('id', referenceId),
        supabase
          .from('legal_reference_check_log')
          .insert({
            reference_id: referenceId,
            checked_by: user?.email || 'system',
            result: 'still_current',
            notes: notes || null,
          }),
      ]);

      setRefreshKey(k => k + 1);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to mark verified');
    }
  }, []);

  const flagForUpdate = useCallback(async (referenceId: string, notes?: string) => {
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();

      await Promise.all([
        supabase
          .from('legal_reference_registry')
          .update({ status: 'review_due' })
          .eq('id', referenceId),
        supabase
          .from('legal_reference_check_log')
          .insert({
            reference_id: referenceId,
            checked_by: user?.email || 'system',
            result: 'update_needed',
            notes: notes || null,
          }),
      ]);

      setRefreshKey(k => k + 1);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to flag for update');
    }
  }, []);

  return {
    references,
    checkLogs,
    totalCount,
    currentCount,
    reviewDueCount,
    outdatedCount,
    supersededCount,
    byEntityType,
    byCategory,
    loading,
    error,
    markVerified,
    flagForUpdate,
    refresh: () => setRefreshKey(k => k + 1),
  };
}
