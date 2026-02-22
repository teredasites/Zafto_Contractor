'use client';

// DATA-ARCH1: Data Source Registry + Ingestion Dashboard (Ops Portal)
// Manages data_sources table, data_ingestion_log, api_gateway_metrics.
// Provides: source list, stale detection, manual refresh, ingestion history, metrics.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface DataSource {
  id: string;
  sourceKey: string;
  displayName: string;
  description: string | null;
  category: string;
  tier: number;
  baseUrl: string;
  authMethod: string;
  rateLimitPerMinute: number;
  rateLimitPerDay: number;
  rateLimitRemaining: number;
  rateLimitResetsAt: string | null;
  refreshFrequency: string;
  nextRefreshAt: string | null;
  lastRefreshedAt: string | null;
  lastStatus: string;
  lastError: string | null;
  monthlyCostCents: number;
  costNotes: string | null;
  fallbackSourceKey: string | null;
  license: string | null;
  documentationUrl: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface IngestionLogEntry {
  id: string;
  sourceKey: string;
  startedAt: string;
  completedAt: string | null;
  durationMs: number | null;
  status: string;
  recordsFetched: number;
  recordsUpserted: number;
  recordsSkipped: number;
  errorMessage: string | null;
  triggeredBy: string;
  createdAt: string;
}

export interface GatewayMetric {
  id: string;
  sourceKey: string;
  metricDate: string;
  totalRequests: number;
  cacheHits: number;
  cacheMisses: number;
  externalCalls: number;
  failures: number;
  avgResponseMs: number;
  p95ResponseMs: number;
}

export interface StaleSource {
  source_key: string;
  display_name: string;
  last_refreshed: string | null;
  staleness_hours: number | null;
}

// ============================================================================
// HOOK
// ============================================================================

export function useDataSources() {
  const [sources, setSources] = useState<DataSource[]>([]);
  const [ingestionLogs, setIngestionLogs] = useState<IngestionLogEntry[]>([]);
  const [metrics, setMetrics] = useState<GatewayMetric[]>([]);
  const [staleSources, setStaleSources] = useState<StaleSource[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState<string | null>(null); // sourceKey being refreshed

  const supabase = getSupabase();

  // ── Load data sources ──
  const loadSources = useCallback(async () => {
    try {
      const { data, error: fetchError } = await supabase
        .from('data_sources')
        .select('*')
        .is('deleted_at', null)
        .order('tier', { ascending: true })
        .order('category');

      if (fetchError) throw fetchError;

      setSources(
        (data || []).map((s: Record<string, unknown>) => ({
          id: s.id as string,
          sourceKey: s.source_key as string,
          displayName: s.display_name as string,
          description: s.description as string | null,
          category: s.category as string,
          tier: s.tier as number,
          baseUrl: s.base_url as string,
          authMethod: s.auth_method as string,
          rateLimitPerMinute: s.rate_limit_per_minute as number,
          rateLimitPerDay: s.rate_limit_per_day as number,
          rateLimitRemaining: s.rate_limit_remaining as number,
          rateLimitResetsAt: s.rate_limit_resets_at as string | null,
          refreshFrequency: s.refresh_frequency as string,
          nextRefreshAt: s.next_refresh_at as string | null,
          lastRefreshedAt: s.last_refreshed_at as string | null,
          lastStatus: s.last_status as string,
          lastError: s.last_error as string | null,
          monthlyCostCents: s.monthly_cost_cents as number,
          costNotes: s.cost_notes as string | null,
          fallbackSourceKey: s.fallback_source_key as string | null,
          license: s.license as string | null,
          documentationUrl: s.documentation_url as string | null,
          isActive: s.is_active as boolean,
          createdAt: s.created_at as string,
          updatedAt: s.updated_at as string,
        }))
      );
    } catch (err) {
      setError((err as Error).message);
    }
  }, [supabase]);

  // ── Load ingestion logs (last 100) ──
  const loadIngestionLogs = useCallback(async () => {
    try {
      const { data, error: fetchError } = await supabase
        .from('data_ingestion_log')
        .select('*')
        .order('started_at', { ascending: false })
        .limit(100);

      if (fetchError) throw fetchError;

      setIngestionLogs(
        (data || []).map((l: Record<string, unknown>) => ({
          id: l.id as string,
          sourceKey: l.source_key as string,
          startedAt: l.started_at as string,
          completedAt: l.completed_at as string | null,
          durationMs: l.duration_ms as number | null,
          status: l.status as string,
          recordsFetched: l.records_fetched as number,
          recordsUpserted: l.records_upserted as number,
          recordsSkipped: l.records_skipped as number,
          errorMessage: l.error_message as string | null,
          triggeredBy: l.triggered_by as string,
          createdAt: l.created_at as string,
        }))
      );
    } catch (err) {
      setError((err as Error).message);
    }
  }, [supabase]);

  // ── Load gateway metrics (last 7 days) ──
  const loadMetrics = useCallback(async () => {
    try {
      const sevenDaysAgo = new Date(Date.now() - 7 * 86400000).toISOString().split('T')[0];
      const { data, error: fetchError } = await supabase
        .from('api_gateway_metrics')
        .select('*')
        .gte('metric_date', sevenDaysAgo)
        .order('metric_date', { ascending: false });

      if (fetchError) throw fetchError;

      setMetrics(
        (data || []).map((m: Record<string, unknown>) => ({
          id: m.id as string,
          sourceKey: m.source_key as string,
          metricDate: m.metric_date as string,
          totalRequests: m.total_requests as number,
          cacheHits: m.cache_hits as number,
          cacheMisses: m.cache_misses as number,
          externalCalls: m.external_calls as number,
          failures: m.failures as number,
          avgResponseMs: m.avg_response_ms as number,
          p95ResponseMs: m.p95_response_ms as number,
        }))
      );
    } catch (err) {
      setError((err as Error).message);
    }
  }, [supabase]);

  // ── Check stale sources ──
  const checkStale = useCallback(async () => {
    try {
      const { data, error: rpcError } = await supabase.rpc('fn_check_stale_sources');
      if (rpcError) throw rpcError;
      setStaleSources(data || []);
    } catch (err) {
      console.error('Stale check failed:', err);
    }
  }, [supabase]);

  // ── Manual refresh a specific source ──
  const refreshSource = useCallback(async (sourceKey: string) => {
    setRefreshing(sourceKey);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) throw new Error('Not authenticated');

      const resp = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/data-ingest-orchestrator`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
            apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
          },
          body: JSON.stringify({ action: 'refresh', source_key: sourceKey }),
        }
      );

      if (!resp.ok) {
        const err = await resp.json();
        throw new Error(err.error || `Refresh failed: ${resp.status}`);
      }

      // Reload data after refresh
      await Promise.all([loadSources(), loadIngestionLogs(), checkStale()]);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setRefreshing(null);
    }
  }, [supabase, loadSources, loadIngestionLogs, checkStale]);

  // ── Refresh all stale sources ──
  const refreshAllStale = useCallback(async () => {
    setRefreshing('__all__');
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.access_token) throw new Error('Not authenticated');

      const resp = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/data-ingest-orchestrator`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
            apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
          },
          body: JSON.stringify({ action: 'refresh-stale' }),
        }
      );

      if (!resp.ok) {
        const err = await resp.json();
        throw new Error(err.error || `Stale refresh failed: ${resp.status}`);
      }

      await Promise.all([loadSources(), loadIngestionLogs(), checkStale()]);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setRefreshing(null);
    }
  }, [supabase, loadSources, loadIngestionLogs, checkStale]);

  // ── Toggle source active/disabled ──
  const toggleSource = useCallback(async (sourceKey: string, isActive: boolean) => {
    try {
      const { error: updateError } = await supabase
        .from('data_sources')
        .update({
          is_active: isActive,
          last_status: isActive ? 'PENDING' : 'DISABLED',
        })
        .eq('source_key', sourceKey);

      if (updateError) throw updateError;
      await loadSources();
    } catch (err) {
      setError((err as Error).message);
    }
  }, [supabase, loadSources]);

  // ── Initial load ──
  useEffect(() => {
    setLoading(true);
    Promise.all([loadSources(), loadIngestionLogs(), loadMetrics(), checkStale()])
      .finally(() => setLoading(false));
  }, [loadSources, loadIngestionLogs, loadMetrics, checkStale]);

  // ── Real-time subscription on data_sources changes ──
  useEffect(() => {
    const channel = supabase
      .channel('data-sources-changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'data_sources' },
        () => { loadSources(); checkStale(); }
      )
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'data_ingestion_log' },
        () => { loadIngestionLogs(); }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [supabase, loadSources, loadIngestionLogs, checkStale]);

  // ── Computed values ──
  const totalSources = sources.length;
  const activeSources = sources.filter((s) => s.isActive).length;
  const tier1Sources = sources.filter((s) => s.tier === 1);
  const tier2Sources = sources.filter((s) => s.tier === 2);
  const tier3Sources = sources.filter((s) => s.tier === 3);
  const totalMonthlyCost = sources.reduce((sum, s) => sum + s.monthlyCostCents, 0);
  const failedSources = sources.filter((s) => s.lastStatus === 'FAILED');
  const categories = [...new Set(sources.map((s) => s.category))];

  return {
    // Data
    sources,
    ingestionLogs,
    metrics,
    staleSources,
    // Computed
    totalSources,
    activeSources,
    tier1Sources,
    tier2Sources,
    tier3Sources,
    totalMonthlyCost,
    failedSources,
    categories,
    // State
    loading,
    error,
    refreshing,
    // Actions
    refreshSource,
    refreshAllStale,
    toggleSource,
    reload: () => Promise.all([loadSources(), loadIngestionLogs(), loadMetrics(), checkStale()]),
  };
}
