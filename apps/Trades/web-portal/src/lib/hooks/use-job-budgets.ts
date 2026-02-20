'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Job Budgets Hook — Budget vs Actual reporting
// Sprint U4, Session 110
// ============================================================

export interface JobBudgetLine {
  id: string;
  jobId: string;
  category: string;
  description: string | null;
  budgetedAmount: number;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface JobBudgetSummary {
  jobId: string;
  jobName: string;
  totalBudget: number;
  totalActual: number;
  variance: number;
  variancePercent: number;
  categories: {
    category: string;
    budgeted: number;
    actual: number;
    variance: number;
  }[];
}

const BUDGET_CATEGORIES = ['materials', 'labor', 'equipment', 'subcontractor', 'permits', 'overhead', 'other'] as const;
export type BudgetCategory = (typeof BUDGET_CATEGORIES)[number];

export const CATEGORY_LABELS: Record<string, string> = {
  materials: 'Materials',
  labor: 'Labor',
  equipment: 'Equipment',
  subcontractor: 'Subcontractor',
  permits: 'Permits & Fees',
  overhead: 'Overhead',
  other: 'Other',
};

export function useJobBudgets(jobId?: string) {
  const [budgets, setBudgets] = useState<JobBudgetLine[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchBudgets = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      let query = supabase.from('job_budgets').select('*').order('category');

      if (jobId) {
        query = query.eq('job_id', jobId);
      }

      const { data, error: err } = await query;
      if (err) throw err;

      setBudgets(
        (data || []).map((d: Record<string, unknown>) => ({
          id: d.id as string,
          jobId: d.job_id as string,
          category: d.category as string,
          description: d.description as string | null,
          budgetedAmount: Number(d.budgeted_amount) || 0,
          notes: d.notes as string | null,
          createdAt: d.created_at as string,
          updatedAt: d.updated_at as string,
        }))
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load budgets');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetchBudgets();
  }, [fetchBudgets]);

  const createBudgetLine = async (data: {
    jobId: string;
    category: string;
    description?: string;
    budgetedAmount: number;
    notes?: string;
  }) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase.from('job_budgets').insert({
        job_id: data.jobId,
        category: data.category,
        description: data.description || null,
        budgeted_amount: data.budgetedAmount,
        notes: data.notes || null,
      });
      if (err) throw err;
      await fetchBudgets();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create budget line');
    }
  };

  const updateBudgetLine = async (
    id: string,
    data: Partial<{ category: string; description: string; budgetedAmount: number; notes: string }>
  ) => {
    try {
      const supabase = getSupabase();
      const update: Record<string, unknown> = {};
      if (data.category !== undefined) update.category = data.category;
      if (data.description !== undefined) update.description = data.description;
      if (data.budgetedAmount !== undefined) update.budgeted_amount = data.budgetedAmount;
      if (data.notes !== undefined) update.notes = data.notes;

      const { error: err } = await supabase.from('job_budgets').update(update).eq('id', id);
      if (err) throw err;
      await fetchBudgets();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update budget line');
    }
  };

  const deleteBudgetLine = async (id: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase.from('job_budgets').update({ deleted_at: new Date().toISOString() }).eq('id', id);
      if (err) throw err;
      await fetchBudgets();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete budget line');
    }
  };

  return {
    budgets,
    loading,
    error,
    createBudgetLine,
    updateBudgetLine,
    deleteBudgetLine,
    refresh: fetchBudgets,
    categories: BUDGET_CATEGORIES,
  };
}

// ============================================================
// Budget vs Actual Summary — pulls budgets + expense actuals
// ============================================================

export function useBudgetVsActual() {
  const [summaries, setSummaries] = useState<JobBudgetSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSummaries = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Fetch all job budgets with job name
      const { data: budgetData, error: budgetErr } = await supabase
        .from('job_budgets')
        .select('*, jobs!inner(id, name)')
        .order('job_id');

      if (budgetErr) throw budgetErr;

      // Fetch actual expenses grouped by job + category (approved/posted only)
      const { data: expenseData, error: expenseErr } = await supabase
        .from('expense_records')
        .select('job_id, category, amount')
        .not('job_id', 'is', null)
        .in('status', ['approved', 'posted']);

      if (expenseErr) throw expenseErr;

      // Build actual amounts map: job_id -> category -> total
      const actualMap: Record<string, Record<string, number>> = {};
      for (const exp of expenseData || []) {
        const jid = exp.job_id as string;
        const cat = exp.category as string;
        if (!actualMap[jid]) actualMap[jid] = {};
        actualMap[jid][cat] = (actualMap[jid][cat] || 0) + Number(exp.amount || 0);
      }

      // Group budget lines by job
      const jobMap: Record<string, { jobName: string; lines: { category: string; budgeted: number }[] }> = {};
      for (const b of budgetData || []) {
        const jid = b.job_id as string;
        const jobObj = b.jobs as { name: string } | null;
        const jobName = jobObj?.name || 'Unknown Job';
        if (!jobMap[jid]) jobMap[jid] = { jobName, lines: [] };
        jobMap[jid].lines.push({
          category: b.category as string,
          budgeted: Number(b.budgeted_amount || 0),
        });
      }

      // Build summaries
      const results: JobBudgetSummary[] = Object.entries(jobMap).map(([jobId, { jobName, lines }]) => {
        const actuals = actualMap[jobId] || {};
        const categories = lines.map((line) => {
          const actual = actuals[line.category] || 0;
          return {
            category: line.category,
            budgeted: line.budgeted,
            actual,
            variance: line.budgeted - actual,
          };
        });

        const totalBudget = categories.reduce((sum, c) => sum + c.budgeted, 0);
        const totalActual = categories.reduce((sum, c) => sum + c.actual, 0);
        const variance = totalBudget - totalActual;
        const variancePercent = totalBudget > 0 ? (variance / totalBudget) * 100 : 0;

        return { jobId, jobName, totalBudget, totalActual, variance, variancePercent, categories };
      });

      setSummaries(results);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load budget summaries');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSummaries();
  }, [fetchSummaries]);

  return { summaries, loading, error, refresh: fetchSummaries };
}
