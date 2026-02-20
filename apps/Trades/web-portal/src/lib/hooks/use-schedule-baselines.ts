'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import type { ScheduleBaseline, ScheduleBaselineTask } from '@/lib/types/scheduling';

interface VarianceRow {
  task_id: string;
  task_name: string;
  baseline_start: string | null;
  baseline_finish: string | null;
  current_start: string | null;
  current_finish: string | null;
  start_variance_days: number;
  finish_variance_days: number;
  status: 'ahead' | 'behind' | 'on_time';
}

interface EvmMetrics {
  bcws: number;
  bcwp: number;
  acwp: number;
  spi: number;
  cpi: number;
}

export function useScheduleBaselines(projectId: string | undefined) {
  const [baselines, setBaselines] = useState<ScheduleBaseline[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchBaselines = useCallback(async () => {
    if (!projectId) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('schedule_baselines')
        .select('*')
        .eq('project_id', projectId)
        .order('baseline_number', { ascending: true });

      if (err) throw err;
      setBaselines(data || []);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load baselines';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [projectId]);

  useEffect(() => {
    fetchBaselines();
  }, [fetchBaselines]);

  const saveBaseline = async (name: string, notes?: string): Promise<{ baseline_id: string; evm: EvmMetrics } | null> => {
    if (!projectId) return null;

    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) throw new Error('Not authenticated');

    const response = await fetch(
      `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/schedule-baseline-capture`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({ project_id: projectId, name, notes }),
      },
    );

    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.error || 'Failed to save baseline');
    }

    const result = await response.json();
    await fetchBaselines();
    return { baseline_id: result.baseline_id, evm: result.evm };
  };

  const deleteBaseline = async (id: string) => {
    const supabase = getSupabase();

    // Soft-delete baseline tasks first
    await supabase.from('schedule_baseline_tasks').update({ deleted_at: new Date().toISOString() }).eq('baseline_id', id);
    // Then soft-delete the baseline
    const { error: err } = await supabase.from('schedule_baselines').update({ deleted_at: new Date().toISOString() }).eq('id', id);
    if (err) throw err;
    await fetchBaselines();
  };

  const getBaselineTasks = async (baselineId: string): Promise<ScheduleBaselineTask[]> => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('schedule_baseline_tasks')
      .select('*')
      .eq('baseline_id', baselineId)
      .order('created_at', { ascending: true });

    if (err) throw err;
    return data || [];
  };

  const getVarianceReport = async (baselineId: string): Promise<VarianceRow[]> => {
    if (!projectId) return [];

    interface CurrentTask {
      id: string;
      name: string;
      early_start: string | null;
      early_finish: string | null;
      planned_start: string | null;
      planned_finish: string | null;
    }

    const supabase = getSupabase();

    // Fetch baseline tasks
    const { data: baselineTasks } = await supabase
      .from('schedule_baseline_tasks')
      .select('task_id, name, planned_start, planned_finish')
      .eq('baseline_id', baselineId);

    // Fetch current tasks
    const { data: currentTasks } = await supabase
      .from('schedule_tasks')
      .select('id, name, early_start, early_finish, planned_start, planned_finish')
      .eq('project_id', projectId)
      .is('deleted_at', null);

    if (!baselineTasks || !currentTasks) return [];

    const currentMap = new Map<string, CurrentTask>();
    for (const t of currentTasks as unknown as CurrentTask[]) {
      currentMap.set(t.id, t);
    }
    const report: VarianceRow[] = [];

    for (const bt of baselineTasks) {
      const ct = currentMap.get(bt.task_id);
      if (!ct) continue;

      const bStart = bt.planned_start ? new Date(bt.planned_start) : null;
      const bFinish = bt.planned_finish ? new Date(bt.planned_finish) : null;
      const cStart = ct.early_start || ct.planned_start ? new Date(ct.early_start || ct.planned_start!) : null;
      const cFinish = ct.early_finish || ct.planned_finish ? new Date(ct.early_finish || ct.planned_finish!) : null;

      const startVar = bStart && cStart ? Math.round((cStart.getTime() - bStart.getTime()) / (1000 * 60 * 60 * 24)) : 0;
      const finishVar = bFinish && cFinish ? Math.round((cFinish.getTime() - bFinish.getTime()) / (1000 * 60 * 60 * 24)) : 0;

      let status: 'ahead' | 'behind' | 'on_time' = 'on_time';
      if (finishVar > 0) status = 'behind';
      else if (finishVar < 0) status = 'ahead';

      report.push({
        task_id: bt.task_id,
        task_name: bt.name || ct.name || 'Unnamed',
        baseline_start: bt.planned_start,
        baseline_finish: bt.planned_finish,
        current_start: ct.early_start || ct.planned_start,
        current_finish: ct.early_finish || ct.planned_finish,
        start_variance_days: startVar,
        finish_variance_days: finishVar,
        status,
      });
    }

    return report;
  };

  return {
    baselines,
    loading,
    error,
    saveBaseline,
    deleteBaseline,
    getBaselineTasks,
    getVarianceReport,
    refetch: fetchBaselines,
  };
}
