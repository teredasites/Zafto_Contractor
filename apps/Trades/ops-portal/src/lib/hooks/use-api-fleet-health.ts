'use client';

// DEPTH28: API Fleet Health Hook (Ops Portal)
// Monitors API registry status, health events, usage, and monthly reports.

import { useState, useEffect, useCallback } from 'react';
import { createClient } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface ApiRegistryEntry {
  id: string;
  name: string;
  displayName: string;
  category: string;
  baseUrl: string;
  requiresKey: boolean;
  rateLimitPerDay: number;
  currentDayUsage: number;
  status: 'active' | 'degraded' | 'down' | 'disabled';
  lastCheckedAt: string | null;
  lastSuccessAt: string | null;
  avgResponseMs: number;
  usagePercent: number; // computed
}

export interface ApiHealthEvent {
  id: string;
  apiName: string;
  previousStatus: string;
  newStatus: string;
  reason: string | null;
  createdAt: string;
}

export interface ApiUsageSummary {
  apiName: string;
  totalCalls: number;
  successCalls: number;
  failedCalls: number;
  avgResponseMs: number;
  successRate: number;
}

export interface ApiHealthReport {
  id: string;
  month: string;
  totalApis: number;
  activeCount: number;
  degradedCount: number;
  downCount: number;
  totalCalls: number;
  overallUptime: number;
  details: Record<string, unknown>;
  createdAt: string;
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapRegistry(row: Record<string, unknown>): ApiRegistryEntry {
  const limit = Number(row.rate_limit_per_day) || 1;
  const usage = Number(row.current_day_usage) || 0;
  return {
    id: row.id as string,
    name: row.name as string,
    displayName: row.display_name as string,
    category: row.category as string,
    baseUrl: row.base_url as string,
    requiresKey: row.requires_key === true,
    rateLimitPerDay: limit,
    currentDayUsage: usage,
    status: row.status as ApiRegistryEntry['status'],
    lastCheckedAt: row.last_checked_at as string | null,
    lastSuccessAt: row.last_success_at as string | null,
    avgResponseMs: Number(row.avg_response_ms) || 0,
    usagePercent: Math.round((usage / limit) * 100),
  };
}

function mapEvent(row: Record<string, unknown>): ApiHealthEvent {
  return {
    id: row.id as string,
    apiName: row.api_name as string,
    previousStatus: row.previous_status as string,
    newStatus: row.new_status as string,
    reason: row.reason as string | null,
    createdAt: row.created_at as string,
  };
}

function mapReport(row: Record<string, unknown>): ApiHealthReport {
  return {
    id: row.id as string,
    month: row.month as string,
    totalApis: Number(row.total_apis) || 0,
    activeCount: Number(row.active_count) || 0,
    degradedCount: Number(row.degraded_count) || 0,
    downCount: Number(row.down_count) || 0,
    totalCalls: Number(row.total_calls) || 0,
    overallUptime: Number(row.overall_uptime_pct) || 0,
    details: (row.details as Record<string, unknown>) || {},
    createdAt: row.created_at as string,
  };
}

// ============================================================================
// HOOK: useApiFleetHealth
// ============================================================================

export function useApiFleetHealth() {
  const [apis, setApis] = useState<ApiRegistryEntry[]>([]);
  const [events, setEvents] = useState<ApiHealthEvent[]>([]);
  const [reports, setReports] = useState<ApiHealthReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = createClient();

      const [apiRes, eventRes, reportRes] = await Promise.all([
        supabase
          .from('api_registry')
          .select('*')
          .order('category')
          .order('display_name'),
        supabase
          .from('api_health_events')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(50),
        supabase
          .from('api_health_reports')
          .select('*')
          .order('month', { ascending: false })
          .limit(12),
      ]);

      setApis((apiRes.data || []).map(mapRegistry));
      setEvents((eventRes.data || []).map(mapEvent));
      setReports((reportRes.data || []).map(mapReport));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load API fleet health');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  // Trigger health check
  const triggerHealthCheck = useCallback(async () => {
    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/api-health-check`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({}),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Health check failed');

      await fetchAll();
      return data;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Health check failed');
      return null;
    }
  }, [fetchAll]);

  // Computed summaries
  const summary = {
    total: apis.length,
    active: apis.filter(a => a.status === 'active').length,
    degraded: apis.filter(a => a.status === 'degraded').length,
    down: apis.filter(a => a.status === 'down').length,
    disabled: apis.filter(a => a.status === 'disabled').length,
    totalCallsToday: apis.reduce((sum, a) => sum + a.currentDayUsage, 0),
    avgUsagePercent: apis.length > 0
      ? Math.round(apis.reduce((sum, a) => sum + a.usagePercent, 0) / apis.length)
      : 0,
  };

  return {
    apis,
    events,
    reports,
    summary,
    loading,
    error,
    refetch: fetchAll,
    triggerHealthCheck,
  };
}
