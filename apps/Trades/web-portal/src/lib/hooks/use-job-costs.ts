'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export type RiskLevel = 'on_track' | 'at_risk' | 'over_budget' | 'critical';

export interface JobCostData {
  id: string;
  name: string;
  customer: string;
  trade: string;
  bidAmount: number;
  actualSpend: number;
  projectedTotal: number;
  percentComplete: number;
  percentBudgetUsed: number;
  laborActual: number;
  materialsActual: number;
  expenseActual: number;
  changeOrdersTotal: number;
  risk: RiskLevel;
  alerts: string[];
  projectedMargin: number;
  originalMargin: number;
}

export interface PortfolioStats {
  activeJobs: number;
  totalBudget: number;
  totalSpend: number;
  projectedTotal: number;
  atRisk: number;
  critical: number;
  avgMarginProjected: number;
  avgMarginOriginal: number;
}

function assessRisk(percentComplete: number, percentBudgetUsed: number, projectedMargin: number): RiskLevel {
  if (projectedMargin < -10 || percentBudgetUsed > percentComplete + 30) return 'critical';
  if (projectedMargin < 0 || percentBudgetUsed > percentComplete + 15) return 'over_budget';
  if (projectedMargin < 10 || percentBudgetUsed > percentComplete + 5) return 'at_risk';
  return 'on_track';
}

function generateAlerts(job: JobCostData): string[] {
  const alerts: string[] = [];
  const overrun = job.projectedTotal - job.bidAmount;
  if (overrun > 0) alerts.push(`Projected ${formatMoney(overrun)} overrun`);
  if (job.percentBudgetUsed > job.percentComplete + 15)
    alerts.push(`Budget burn rate ${job.percentBudgetUsed}% exceeds progress ${job.percentComplete}%`);
  if (job.changeOrdersTotal > 0) alerts.push(`${formatMoney(job.changeOrdersTotal)} in change orders`);
  return alerts;
}

function formatMoney(n: number): string {
  return '$' + Math.abs(n).toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
}

export function useJobCosts() {
  const [jobs, setJobs] = useState<JobCostData[]>([]);
  const [stats, setStats] = useState<PortfolioStats>({
    activeJobs: 0, totalBudget: 0, totalSpend: 0, projectedTotal: 0,
    atRisk: 0, critical: 0, avgMarginProjected: 0, avgMarginOriginal: 0,
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Get active jobs (not completed, cancelled, or invoiced)
      const { data: jobsData, error: jobsErr } = await supabase
        .from('jobs')
        .select('id, title, customer_name, status, estimated_amount, actual_amount, tags, created_at')
        .not('status', 'in', '("completed","invoiced","cancelled")');

      if (jobsErr) throw jobsErr;
      const activeJobs: Record<string, unknown>[] = jobsData || [];
      const jobIds = activeJobs.map((j) => j.id as string);

      if (jobIds.length === 0) {
        setJobs([]);
        setStats({
          activeJobs: 0, totalBudget: 0, totalSpend: 0, projectedTotal: 0,
          atRisk: 0, critical: 0, avgMarginProjected: 0, avgMarginOriginal: 0,
        });
        setLoading(false);
        return;
      }

      // Fetch labor (time entries), materials, expenses, and change orders for active jobs
      const [timeRes, materialsRes, expensesRes, changeOrdersRes] = await Promise.all([
        supabase.from('time_entries').select('job_id, total_minutes, hourly_rate, labor_cost').in('job_id', jobIds).neq('status', 'rejected'),
        supabase.from('job_materials').select('job_id, total_cost').in('job_id', jobIds),
        supabase.from('expense_records').select('job_id, amount').in('job_id', jobIds).neq('status', 'void'),
        supabase.from('change_orders').select('job_id, amount, status').in('job_id', jobIds),
      ]);

      const timeEntries: Record<string, unknown>[] = timeRes.data || [];
      const materials: Record<string, unknown>[] = materialsRes.data || [];
      const expenses: Record<string, unknown>[] = expensesRes.data || [];
      const changeOrders: Record<string, unknown>[] = changeOrdersRes.data || [];

      // Aggregate labor cost by job: prefer pre-computed labor_cost, fall back to (minutes/60) * rate
      const laborByJob: Record<string, number> = {};
      for (const te of timeEntries) {
        const jid = te.job_id as string;
        if (!jid) continue;
        const precomputed = Number(te.labor_cost || 0);
        const cost = precomputed > 0
          ? precomputed
          : (Number(te.total_minutes || 0) / 60) * Number(te.hourly_rate || 0);
        laborByJob[jid] = (laborByJob[jid] || 0) + cost;
      }

      // Aggregate materials by job
      const materialsByJob: Record<string, number> = {};
      for (const m of materials) {
        const jid = m.job_id as string;
        materialsByJob[jid] = (materialsByJob[jid] || 0) + Number(m.total_cost || 0);
      }

      // Aggregate expenses by job
      const expensesByJob: Record<string, number> = {};
      for (const ex of expenses) {
        const jid = ex.job_id as string;
        if (jid) expensesByJob[jid] = (expensesByJob[jid] || 0) + Number(ex.amount || 0);
      }

      // Aggregate approved change orders by job
      const coByJob: Record<string, number> = {};
      for (const co of changeOrders) {
        if (co.status === 'approved') {
          const jid = co.job_id as string;
          coByJob[jid] = (coByJob[jid] || 0) + Number(co.amount || 0);
        }
      }

      // Build job cost data
      const jobCosts: JobCostData[] = activeJobs.map((job) => {
        const jid = job.id as string;
        const bidAmount = Number(job.estimated_amount || 0);
        const actualAmount = Number(job.actual_amount || 0);
        const laborCost = laborByJob[jid] || 0;
        const matCost = materialsByJob[jid] || 0;
        const expCost = expensesByJob[jid] || 0;
        const coCost = coByJob[jid] || 0;
        // Full cost formula: labor + materials + expenses + change orders
        const computedSpend = laborCost + matCost + expCost;
        const actualSpend = actualAmount > 0 ? actualAmount : computedSpend;

        // Approximate percent complete from actual vs estimated
        const percentComplete = bidAmount > 0 ? Math.min(Math.round((actualSpend / bidAmount) * 100), 95) : 0;
        const percentBudgetUsed = bidAmount > 0 ? Math.round((actualSpend / bidAmount) * 100) : 0;

        // Project total based on burn rate
        const projectedTotal = percentComplete > 0
          ? Math.round(actualSpend / (percentComplete / 100))
          : bidAmount;

        const originalMargin = bidAmount > 0 ? Math.round(((bidAmount - (bidAmount * 0.7)) / bidAmount) * 100 * 10) / 10 : 30;
        const projectedMargin = bidAmount > 0
          ? Math.round(((bidAmount + coCost - projectedTotal) / (bidAmount + coCost)) * 100 * 10) / 10
          : 0;

        const tags = (job.tags as string[]) || [];
        const trade = tags[0] || 'General';

        const jc: JobCostData = {
          id: jid,
          name: (job.title as string) || 'Untitled Job',
          customer: (job.customer_name as string) || 'Unknown',
          trade: trade.charAt(0).toUpperCase() + trade.slice(1),
          bidAmount,
          actualSpend,
          projectedTotal,
          percentComplete,
          percentBudgetUsed,
          laborActual: laborCost,
          materialsActual: matCost,
          expenseActual: expCost,
          changeOrdersTotal: coCost,
          risk: assessRisk(percentComplete, percentBudgetUsed, projectedMargin),
          alerts: [],
          projectedMargin,
          originalMargin,
        };
        jc.alerts = generateAlerts(jc);
        return jc;
      });

      // Sort by risk (critical first)
      const riskOrder: Record<RiskLevel, number> = { critical: 0, over_budget: 1, at_risk: 2, on_track: 3 };
      jobCosts.sort((a, b) => riskOrder[a.risk] - riskOrder[b.risk]);

      setJobs(jobCosts);

      // Compute portfolio stats
      const totalBudget = jobCosts.reduce((s, j) => s + j.bidAmount, 0);
      const totalSpend = jobCosts.reduce((s, j) => s + j.actualSpend, 0);
      const projectedTotal = jobCosts.reduce((s, j) => s + j.projectedTotal, 0);
      const margins = jobCosts.filter((j) => j.bidAmount > 0);
      const avgMarginProjected = margins.length > 0
        ? Math.round((margins.reduce((s, j) => s + j.projectedMargin, 0) / margins.length) * 10) / 10
        : 0;
      const avgMarginOriginal = margins.length > 0
        ? Math.round((margins.reduce((s, j) => s + j.originalMargin, 0) / margins.length) * 10) / 10
        : 0;

      setStats({
        activeJobs: jobCosts.length,
        totalBudget,
        totalSpend,
        projectedTotal,
        atRisk: jobCosts.filter((j) => j.risk === 'at_risk').length,
        critical: jobCosts.filter((j) => j.risk === 'critical' || j.risk === 'over_budget').length,
        avgMarginProjected,
        avgMarginOriginal,
      });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load job costs');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { jobs, stats, loading, error, refetch: fetchData };
}
