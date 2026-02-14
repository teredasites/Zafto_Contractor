'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface OshaStandard {
  id: string;
  standardNumber: string;
  title: string;
  part: string;
  subpart: string;
  tradeTags: string[];
  isFrequentlyCited: boolean;
  fullText: string | null;
  effectiveDate: string | null;
  lastSyncedAt: string | null;
  createdAt: string;
}

export interface ViolationResult {
  establishmentName: string;
  inspectionDate: string;
  state: string;
  violationType: string;
  penaltyAmount: number;
}

type TradeFilter =
  | 'all'
  | 'electrical'
  | 'plumbing'
  | 'hvac'
  | 'roofing'
  | 'general_construction'
  | 'restoration'
  | 'solar';

function mapStandard(row: Record<string, unknown>): OshaStandard {
  return {
    id: row.id as string,
    standardNumber: row.standard_number as string,
    title: row.title as string,
    part: row.part as string,
    subpart: row.subpart as string,
    tradeTags: (row.trade_tags as string[]) || [],
    isFrequentlyCited: row.is_frequently_cited as boolean,
    fullText: (row.full_text as string) || null,
    effectiveDate: (row.effective_date as string) || null,
    lastSyncedAt: (row.last_synced_at as string) || null,
    createdAt: row.created_at as string,
  };
}

export function useOshaStandards() {
  const [standards, setStandards] = useState<OshaStandard[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [tradeFilter, setTradeFilter] = useState<TradeFilter>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [frequentlyOnly, setFrequentlyOnly] = useState(false);

  const fetchStandards = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('osha_standards')
        .select('*')
        .order('standard_number', { ascending: true });

      if (err) throw err;
      setStandards((data || []).map(mapStandard));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load OSHA standards';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchStandards();

    const supabase = getSupabase();
    const channel = supabase
      .channel('osha-standards-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'osha_standards' }, () => {
        fetchStandards();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchStandards]);

  const filteredStandards = useMemo(() => {
    return standards.filter((s) => {
      const query = searchQuery.toLowerCase();
      const matchesSearch =
        !query ||
        s.standardNumber.toLowerCase().includes(query) ||
        s.title.toLowerCase().includes(query);
      const matchesTrade =
        tradeFilter === 'all' || s.tradeTags.includes(tradeFilter);
      const matchesFrequent = !frequentlyOnly || s.isFrequentlyCited;
      return matchesSearch && matchesTrade && matchesFrequent;
    });
  }, [standards, searchQuery, tradeFilter, frequentlyOnly]);

  const syncStandards = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { error: err } = await supabase.functions.invoke('osha-data-sync', {
        body: { action: 'sync_standards' },
      });
      if (err) throw err;
      await fetchStandards();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to sync standards';
      setError(msg);
    }
  }, [fetchStandards]);

  const lookupViolations = useCallback(
    async (companyName: string, state: string): Promise<ViolationResult[]> => {
      try {
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase.functions.invoke('osha-data-sync', {
          body: { action: 'lookup_violations', companyName, state },
        });
        if (err) throw err;
        const results: ViolationResult[] = (data?.violations || []).map(
          (v: Record<string, unknown>) => ({
            establishmentName: (v.establishment_name as string) || '',
            inspectionDate: (v.inspection_date as string) || '',
            state: (v.state as string) || '',
            violationType: (v.violation_type as string) || '',
            penaltyAmount: (v.penalty_amount as number) || 0,
          })
        );
        return results;
      } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Failed to lookup violations';
        setError(msg);
        return [];
      }
    },
    []
  );

  /** Get a safety checklist for a specific trade type (for auto-populating on job creation) */
  const getSafetyChecklistByTrade = useCallback(
    (trade: string): { title: string; standardNumber: string; required: boolean }[] => {
      const tradeKey = trade.toLowerCase();
      const relevant = standards.filter(
        (s) => s.tradeTags.some((t) => t.toLowerCase() === tradeKey) || s.isFrequentlyCited
      );
      return relevant.slice(0, 10).map((s) => ({
        title: s.title,
        standardNumber: s.standardNumber,
        required: s.isFrequentlyCited,
      }));
    },
    [standards]
  );

  return {
    standards,
    filteredStandards,
    loading,
    error,
    syncStandards,
    lookupViolations,
    getSafetyChecklistByTrade,
    tradeFilter,
    setTradeFilter,
    searchQuery,
    setSearchQuery,
    frequentlyOnly,
    setFrequentlyOnly,
  };
}
