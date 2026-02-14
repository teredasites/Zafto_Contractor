'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ══════════════════════════════════════════════════════════════
// TYPES
// ══════════════════════════════════════════════════════════════

export interface ScheduleCostSummary {
  total_budgeted: number;
  total_actual: number;
  cost_variance: number;
  // Earned Value metrics
  pv: number;   // Planned Value (BCWS)
  ev: number;   // Earned Value (BCWP)
  ac: number;   // Actual Cost (ACWP)
  spi: number;  // Schedule Performance Index (EV/PV)
  cpi: number;  // Cost Performance Index (EV/AC)
  eac: number;  // Estimate at Completion (AC + (BAC - EV) / CPI)
  etc: number;  // Estimate to Complete (EAC - AC)
  vac: number;  // Variance at Completion (BAC - EAC)
  // Progress
  percent_complete: number;
  percent_spent: number;
}

// ══════════════════════════════════════════════════════════════
// HOOK
// ══════════════════════════════════════════════════════════════

export function useScheduleCosts(projectId: string | undefined) {
  const [costs, setCosts] = useState<ScheduleCostSummary | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchCosts = useCallback(async () => {
    if (!projectId) { setLoading(false); return; }

    try {
      setLoading(true);
      const supabase = getSupabase();

      interface TaskCostRow {
        budgeted_cost: number;
        actual_cost: number;
        percent_complete: number;
        planned_start: string | null;
        planned_finish: string | null;
      }

      const { data, error } = await supabase
        .from('schedule_tasks')
        .select('budgeted_cost, actual_cost, percent_complete, planned_start, planned_finish')
        .eq('project_id', projectId)
        .is('deleted_at', null);

      if (error) throw error;

      const tasks = (data || []) as unknown as TaskCostRow[];

      if (tasks.length === 0) {
        setCosts(null);
        return;
      }

      const today = new Date();
      const todayStr = today.toISOString().slice(0, 10);

      let totalBudgeted = 0;
      let totalActual = 0;
      let pv = 0; // Planned Value: budget of tasks that should be done by now
      let ev = 0; // Earned Value: budget × % complete

      for (const task of tasks) {
        const bc = task.budgeted_cost || 0;
        const ac = task.actual_cost || 0;
        const pct = task.percent_complete || 0;

        totalBudgeted += bc;
        totalActual += ac;

        // EV = sum of (budgeted_cost × percent_complete / 100)
        ev += bc * (pct / 100);

        // PV = budget of tasks that should be started/completed by today
        if (task.planned_finish && task.planned_finish <= todayStr) {
          pv += bc; // Should be 100% complete
        } else if (task.planned_start && task.planned_start <= todayStr && task.planned_finish) {
          // Partially through the task — pro-rate
          const start = new Date(task.planned_start).getTime();
          const finish = new Date(task.planned_finish).getTime();
          const duration = finish - start;
          if (duration > 0) {
            const elapsed = today.getTime() - start;
            const ratio = Math.min(elapsed / duration, 1);
            pv += bc * ratio;
          }
        }
      }

      const bac = totalBudgeted; // Budget at Completion
      const spi = pv > 0 ? ev / pv : 1;
      const cpi = totalActual > 0 ? ev / totalActual : 1;
      const eac = cpi > 0 ? totalActual + (bac - ev) / cpi : bac;
      const etc = Math.max(eac - totalActual, 0);
      const vac = bac - eac;

      const overallPct = tasks.length > 0
        ? tasks.reduce((s, t) => s + (t.percent_complete || 0), 0) / tasks.length
        : 0;

      setCosts({
        total_budgeted: totalBudgeted,
        total_actual: totalActual,
        cost_variance: totalBudgeted - totalActual,
        pv: Math.round(pv * 100) / 100,
        ev: Math.round(ev * 100) / 100,
        ac: totalActual,
        spi: Math.round(spi * 100) / 100,
        cpi: Math.round(cpi * 100) / 100,
        eac: Math.round(eac * 100) / 100,
        etc: Math.round(etc * 100) / 100,
        vac: Math.round(vac * 100) / 100,
        percent_complete: Math.round(overallPct),
        percent_spent: totalBudgeted > 0 ? Math.round((totalActual / totalBudgeted) * 100) : 0,
      });
    } catch {
      setCosts(null);
    } finally {
      setLoading(false);
    }
  }, [projectId]);

  useEffect(() => { fetchCosts(); }, [fetchCosts]);

  return { costs, loading, refetch: fetchCosts };
}
