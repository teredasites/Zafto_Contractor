'use client';

// J4: Job Intelligence Hook — autopsy data, insights, adjustments, profitability
// Real-time subscription on job_cost_autopsies + estimate_adjustments.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface JobCostAutopsy {
  id: string;
  company_id: string;
  job_id: string;
  estimated_labor_hours: number | null;
  estimated_labor_cost: number | null;
  estimated_material_cost: number | null;
  estimated_total: number | null;
  actual_labor_hours: number | null;
  actual_labor_cost: number | null;
  actual_material_cost: number | null;
  actual_drive_time_hours: number;
  actual_drive_cost: number;
  actual_callbacks: number;
  actual_change_order_cost: number;
  actual_total: number | null;
  revenue: number | null;
  gross_profit: number | null;
  gross_margin_pct: number | null;
  variance_pct: number | null;
  job_type: string | null;
  trade_type: string | null;
  primary_tech_id: string | null;
  completed_at: string | null;
  created_at: string;
}

export interface AutopsyInsight {
  id: string;
  company_id: string;
  insight_type: string;
  insight_key: string;
  insight_data: Record<string, unknown>;
  sample_size: number;
  confidence_score: number;
  period_start: string | null;
  period_end: string | null;
  created_at: string;
}

interface EstimateAdjustment {
  id: string;
  company_id: string;
  job_type: string;
  trade_type: string | null;
  adjustment_type: string;
  suggested_multiplier: number | null;
  suggested_flat_amount: number | null;
  based_on_jobs: number;
  avg_variance_pct: number | null;
  status: 'pending' | 'accepted' | 'dismissed' | 'applied';
  applied_at: string | null;
  created_at: string;
}

interface ProfitabilitySummary {
  totalJobs: number;
  avgMargin: number;
  totalRevenue: number;
  totalProfit: number;
  overBudgetCount: number;
  avgVariance: number;
}

export function useJobIntelligence() {
  const supabase = getSupabase();
  const [autopsies, setAutopsies] = useState<JobCostAutopsy[]>([]);
  const [insights, setInsights] = useState<AutopsyInsight[]>([]);
  const [adjustments, setAdjustments] = useState<EstimateAdjustment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAll = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const [autopsyRes, insightRes, adjustmentRes] = await Promise.all([
        supabase
          .from('job_cost_autopsies')
          .select('*')
          .is('deleted_at', null)
          .order('completed_at', { ascending: false }),
        supabase
          .from('autopsy_insights')
          .select('*')
          .is('deleted_at', null)
          .order('created_at', { ascending: false }),
        supabase
          .from('estimate_adjustments')
          .select('*')
          .is('deleted_at', null)
          .order('created_at', { ascending: false }),
      ]);

      if (autopsyRes.error) throw autopsyRes.error;
      if (insightRes.error) throw insightRes.error;
      if (adjustmentRes.error) throw adjustmentRes.error;

      setAutopsies(autopsyRes.data || []);
      setInsights(insightRes.data || []);
      setAdjustments(adjustmentRes.data || []);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAll();

    // Real-time subscriptions
    const channel = supabase
      .channel('job-intelligence')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'job_cost_autopsies' }, () => fetchAll())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'estimate_adjustments' }, () => fetchAll())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchAll]);

  // ── Computed stats ──
  const summary: ProfitabilitySummary = {
    totalJobs: autopsies.length,
    avgMargin: autopsies.length > 0
      ? autopsies.reduce((s, a) => s + (a.gross_margin_pct || 0), 0) / autopsies.length
      : 0,
    totalRevenue: autopsies.reduce((s, a) => s + (a.revenue || 0), 0),
    totalProfit: autopsies.reduce((s, a) => s + (a.gross_profit || 0), 0),
    overBudgetCount: autopsies.filter(a => (a.variance_pct || 0) > 0).length,
    avgVariance: autopsies.length > 0
      ? autopsies.reduce((s, a) => s + (a.variance_pct || 0), 0) / autopsies.length
      : 0,
  };

  const pendingAdjustments = adjustments.filter(a => a.status === 'pending');

  const insightsByType = (type: string) => insights.filter(i => i.insight_type === type);

  // ── Mutations ──
  const updateAdjustmentStatus = useCallback(
    async (id: string, status: 'accepted' | 'dismissed' | 'applied') => {
      const updates: Record<string, unknown> = { status };
      if (status === 'applied') updates.applied_at = new Date().toISOString();

      const { error: err } = await supabase
        .from('estimate_adjustments')
        .update(updates)
        .eq('id', id);

      if (err) throw err;
      await fetchAll();
    },
    [fetchAll],
  );

  const getAutopsyByJobId = useCallback(
    (jobId: string): JobCostAutopsy | undefined => {
      return autopsies.find(a => a.job_id === jobId);
    },
    [autopsies],
  );

  return {
    autopsies,
    insights,
    adjustments,
    loading,
    error,
    summary,
    pendingAdjustments,
    insightsByType,
    updateAdjustmentStatus,
    getAutopsyByJobId,
    refresh: fetchAll,
  };
}
