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

export interface PostMortem {
  id: string;
  jobName: string;
  trade: string;
  completedDate: string;
  estimatedLabor: number;
  actualLabor: number;
  estimatedMaterials: number;
  actualMaterials: number;
  estimatedTotal: number;
  actualTotal: number;
  profitMargin: number;
  estimatedMargin: number;
}

export interface LineItemAccuracy {
  category: string;
  estimatedAvg: number;
  actualAvg: number;
  variance: number;
  sampleSize: number;
  trend: 'over' | 'under' | 'on_target';
  suggestion: string;
}

export interface CrewMetric {
  crewName: string;
  members: number;
  avgJobDays: number;
  avgDailyOutput: number;
  completionRate: number;
  callbackRate: number;
  specialties: string[];
  costPerHour: number;
}

export interface CostTrend {
  month: string;
  avgMargin: number;
  totalRevenue: number;
  totalCost: number;
  jobCount: number;
}

export interface OverheadItem {
  category: string;
  monthlyCost: number;
  perJobHour: number;
  percentOfRevenue: number;
}

export interface EstimateFeedback {
  category: string;
  adjustment: string;
  reason: string;
  direction: 'up' | 'down' | 'neutral';
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

// ── Overhead category mapping for expense_records ──
const OVERHEAD_CATEGORIES: Record<string, string> = {
  fuel: 'Vehicle / Fuel',
  vehicle: 'Vehicle / Fuel',
  insurance: 'Insurance (GL + WC)',
  tools: 'Tool Depreciation',
  equipment: 'Equipment',
  office: 'Office / Admin',
  utilities: 'Utilities',
  advertising: 'Marketing',
  permits: 'Licenses / Permits',
  subcontractor: 'Subcontractor',
  uncategorized: 'Misc Operating',
};

export function useJobCosts() {
  const [jobs, setJobs] = useState<JobCostData[]>([]);
  const [stats, setStats] = useState<PortfolioStats>({
    activeJobs: 0, totalBudget: 0, totalSpend: 0, projectedTotal: 0,
    atRisk: 0, critical: 0, avgMarginProjected: 0, avgMarginOriginal: 0,
  });
  const [postMortems, setPostMortems] = useState<PostMortem[]>([]);
  const [lineItems, setLineItems] = useState<LineItemAccuracy[]>([]);
  const [crews, setCrews] = useState<CrewMetric[]>([]);
  const [costTrends, setCostTrends] = useState<CostTrend[]>([]);
  const [overhead, setOverhead] = useState<OverheadItem[]>([]);
  const [estimateFeedback, setEstimateFeedback] = useState<EstimateFeedback[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // ── 1. ACTIVE JOBS (Portfolio tab) ──
      const { data: jobsData, error: jobsErr } = await supabase
        .from('jobs')
        .select('id, title, customer_name, status, estimated_amount, actual_amount, tags, trade_type, created_at, completed_at')
        .not('status', 'in', '("completed","invoiced","cancelled")')
        .is('deleted_at', null);

      if (jobsErr) throw jobsErr;
      const activeJobs: Record<string, unknown>[] = jobsData || [];
      const jobIds = activeJobs.map((j) => j.id as string);

      // ── 2. COMPLETED JOBS (Post-Mortem, Trends, Line Items) ──
      const ninetyDaysAgo = new Date();
      ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setDate(sixMonthsAgo.getDate() - 180);

      const { data: completedJobsData, error: completedJobsErr } = await supabase
        .from('jobs')
        .select('id, title, customer_name, status, estimated_amount, actual_amount, tags, trade_type, created_at, completed_at')
        .in('status', ['completed', 'invoiced'])
        .gte('completed_at', sixMonthsAgo.toISOString())
        .is('deleted_at', null)
        .order('completed_at', { ascending: false });

      if (completedJobsErr) throw completedJobsErr;
      const completedJobs: Record<string, unknown>[] = completedJobsData || [];
      const completedJobIds = completedJobs.map((j) => j.id as string);
      const allJobIds = [...jobIds, ...completedJobIds];

      // ── 3. FETCH ALL COST DATA ──
      const [timeRes, materialsRes, expensesRes, changeOrdersRes, overheadExpensesRes, crewPerfRes] = await Promise.all([
        allJobIds.length > 0
          ? supabase.from('time_entries').select('job_id, user_id, total_minutes, hourly_rate, labor_cost, clock_in, clock_out').in('job_id', allJobIds).neq('status', 'rejected')
          : Promise.resolve({ data: [], error: null }),
        allJobIds.length > 0
          ? supabase.from('job_materials').select('job_id, name, category, total_cost').in('job_id', allJobIds).is('deleted_at', null)
          : Promise.resolve({ data: [], error: null }),
        allJobIds.length > 0
          ? supabase.from('expense_records').select('job_id, amount, category, expense_date').in('job_id', allJobIds).neq('status', 'voided').is('deleted_at', null)
          : Promise.resolve({ data: [], error: null }),
        allJobIds.length > 0
          ? supabase.from('change_orders').select('job_id, amount, status').in('job_id', allJobIds)
          : Promise.resolve({ data: [], error: null }),
        // Overhead: company-level expenses (no job_id) from last 6 months
        supabase.from('expense_records').select('amount, category, expense_date').is('job_id', null).neq('status', 'voided').is('deleted_at', null).gte('expense_date', sixMonthsAgo.toISOString().split('T')[0]),
        // Crew performance log for line item accuracy
        supabase.from('crew_performance_log').select('task_name, trade, estimated_hours, actual_hours, crew_size, job_id'),
      ]);

      const timeEntries: Record<string, unknown>[] = timeRes.data || [];
      const materials: Record<string, unknown>[] = materialsRes.data || [];
      const expenses: Record<string, unknown>[] = expensesRes.data || [];
      const changeOrders: Record<string, unknown>[] = changeOrdersRes.data || [];
      const overheadExpenses: Record<string, unknown>[] = overheadExpensesRes.data || [];
      const crewPerfLogs: Record<string, unknown>[] = crewPerfRes.data || [];

      // ── AGGREGATE HELPERS ──
      const laborByJob: Record<string, number> = {};
      const minutesByJob: Record<string, number> = {};
      const userJobMap: Record<string, Set<string>> = {};
      const userMinutesMap: Record<string, number> = {};
      const userCostMap: Record<string, number> = {};
      const userJobDaysMap: Record<string, number[]> = {};

      for (const te of timeEntries) {
        const jid = te.job_id as string;
        const uid = te.user_id as string;
        if (!jid) continue;
        const precomputed = Number(te.labor_cost || 0);
        const mins = Number(te.total_minutes || 0);
        const cost = precomputed > 0
          ? precomputed
          : (mins / 60) * Number(te.hourly_rate || 0);
        laborByJob[jid] = (laborByJob[jid] || 0) + cost;
        minutesByJob[jid] = (minutesByJob[jid] || 0) + mins;

        // Crew tracking
        if (uid) {
          if (!userJobMap[uid]) userJobMap[uid] = new Set();
          userJobMap[uid].add(jid);
          userMinutesMap[uid] = (userMinutesMap[uid] || 0) + mins;
          userCostMap[uid] = (userCostMap[uid] || 0) + cost;

          // Track daily hours per job for computing avg job days
          if (te.clock_in) {
            const day = (te.clock_in as string).split('T')[0];
            const key = `${uid}:${jid}:${day}`;
            if (!userJobDaysMap[uid]) userJobDaysMap[uid] = [];
            // Use a set-like approach via the key
            if (!userJobDaysMap[`_seen_${key}`]) {
              userJobDaysMap[`_seen_${key}`] = [1];
              if (!userJobDaysMap[uid]) userJobDaysMap[uid] = [];
              userJobDaysMap[uid].push(1);
            }
          }
        }
      }

      const materialsByJob: Record<string, number> = {};
      const materialCatByJob: Record<string, Record<string, number>> = {};
      for (const m of materials) {
        const jid = m.job_id as string;
        const cost = Number(m.total_cost || 0);
        materialsByJob[jid] = (materialsByJob[jid] || 0) + cost;
        const cat = (m.category as string) || (m.name as string) || 'material';
        if (!materialCatByJob[jid]) materialCatByJob[jid] = {};
        materialCatByJob[jid][cat] = (materialCatByJob[jid][cat] || 0) + cost;
      }

      const expensesByJob: Record<string, number> = {};
      for (const ex of expenses) {
        const jid = ex.job_id as string;
        if (jid) expensesByJob[jid] = (expensesByJob[jid] || 0) + Number(ex.amount || 0);
      }

      const coByJob: Record<string, number> = {};
      for (const co of changeOrders) {
        if (co.status === 'approved') {
          const jid = co.job_id as string;
          coByJob[jid] = (coByJob[jid] || 0) + Number(co.amount || 0);
        }
      }

      // ══════════════════════════════════════════════════════
      // ── PORTFOLIO TAB: Build active job cost data ──
      // ══════════════════════════════════════════════════════

      const jobCosts: JobCostData[] = activeJobs.map((job) => {
        const jid = job.id as string;
        const bidAmount = Number(job.estimated_amount || 0);
        const actualAmount = Number(job.actual_amount || 0);
        const laborCost = laborByJob[jid] || 0;
        const matCost = materialsByJob[jid] || 0;
        const expCost = expensesByJob[jid] || 0;
        const coCost = coByJob[jid] || 0;
        const computedSpend = laborCost + matCost + expCost;
        const actualSpend = actualAmount > 0 ? actualAmount : computedSpend;

        const percentComplete = bidAmount > 0 ? Math.min(Math.round((actualSpend / bidAmount) * 100), 95) : 0;
        const percentBudgetUsed = bidAmount > 0 ? Math.round((actualSpend / bidAmount) * 100) : 0;

        const projectedTotal = percentComplete > 0
          ? Math.round(actualSpend / (percentComplete / 100))
          : bidAmount;

        const originalMargin = bidAmount > 0 ? Math.round(((bidAmount - (bidAmount * 0.7)) / bidAmount) * 100 * 10) / 10 : 30;
        const projectedMargin = bidAmount > 0
          ? Math.round(((bidAmount + coCost - projectedTotal) / (bidAmount + coCost)) * 100 * 10) / 10
          : 0;

        const tags = (job.tags as string[]) || [];
        const trade = (job.trade_type as string) || tags[0] || 'General';

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

      const riskOrder: Record<RiskLevel, number> = { critical: 0, over_budget: 1, at_risk: 2, on_track: 3 };
      jobCosts.sort((a, b) => riskOrder[a.risk] - riskOrder[b.risk]);
      setJobs(jobCosts);

      // Portfolio stats
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

      // ══════════════════════════════════════════════════════
      // ── POST-MORTEM TAB: Completed jobs analysis ──
      // ══════════════════════════════════════════════════════

      const pmList: PostMortem[] = completedJobs
        .filter((cj) => {
          const compDate = cj.completed_at as string | null;
          return compDate && new Date(compDate) >= ninetyDaysAgo;
        })
        .map((cj) => {
          const jid = cj.id as string;
          const estimatedTotal = Number(cj.estimated_amount || 0);
          const laborCost = laborByJob[jid] || 0;
          const matCost = materialsByJob[jid] || 0;
          const expCost = expensesByJob[jid] || 0;
          const actualTotal = laborCost + matCost + expCost;

          // Estimate labor/materials split: default 60% labor, 40% materials of estimated
          const estimatedLabor = estimatedTotal * 0.6;
          const estimatedMaterials = estimatedTotal * 0.4;

          const profitMargin = estimatedTotal > 0
            ? Math.round(((estimatedTotal - actualTotal) / estimatedTotal) * 100 * 10) / 10
            : 0;
          const estimatedMargin = 30; // Default assumed margin

          const tags = (cj.tags as string[]) || [];
          const trade = (cj.trade_type as string) || tags[0] || 'General';
          const completedDate = cj.completed_at
            ? new Date(cj.completed_at as string).toISOString().split('T')[0]
            : '';

          return {
            id: jid,
            jobName: (cj.title as string) || 'Untitled Job',
            trade: trade.charAt(0).toUpperCase() + trade.slice(1),
            completedDate,
            estimatedLabor,
            actualLabor: laborCost,
            estimatedMaterials,
            actualMaterials: matCost,
            estimatedTotal,
            actualTotal,
            profitMargin,
            estimatedMargin,
          };
        });

      setPostMortems(pmList);

      // ══════════════════════════════════════════════════════
      // ── LINE-ITEM ACCURACY TAB ──
      // ══════════════════════════════════════════════════════

      // Use crew_performance_log for task-level accuracy if available
      const taskAccuracy: Record<string, { estHrs: number[]; actHrs: number[]; count: number }> = {};
      for (const log of crewPerfLogs) {
        const task = (log.task_name as string) || (log.trade as string) || 'Unknown';
        const estH = Number(log.estimated_hours || 0);
        const actH = Number(log.actual_hours || 0);
        if (estH <= 0 && actH <= 0) continue;
        if (!taskAccuracy[task]) taskAccuracy[task] = { estHrs: [], actHrs: [], count: 0 };
        taskAccuracy[task].estHrs.push(estH);
        taskAccuracy[task].actHrs.push(actH);
        taskAccuracy[task].count++;
      }

      // Also derive from material categories on completed jobs
      const matCatAccuracy: Record<string, { estimated: number[]; actual: number[] }> = {};
      for (const cj of completedJobs) {
        const jid = cj.id as string;
        const estimatedTotal = Number(cj.estimated_amount || 0);
        const cats = materialCatByJob[jid] || {};
        const totalMatCost = materialsByJob[jid] || 0;
        for (const [cat, actualCost] of Object.entries(cats)) {
          // Estimate per-category budget proportionally
          const fraction = totalMatCost > 0 ? actualCost / totalMatCost : 0;
          const estCost = estimatedTotal * 0.4 * fraction; // 40% materials budget * category fraction
          if (!matCatAccuracy[cat]) matCatAccuracy[cat] = { estimated: [], actual: [] };
          matCatAccuracy[cat].estimated.push(estCost);
          matCatAccuracy[cat].actual.push(actualCost);
        }
      }

      const liItems: LineItemAccuracy[] = [];

      // From crew performance logs (task-level)
      for (const [task, data] of Object.entries(taskAccuracy)) {
        if (data.count < 2) continue; // Need at least 2 samples
        const avgEst = data.estHrs.reduce((a, b) => a + b, 0) / data.count;
        const avgAct = data.actHrs.reduce((a, b) => a + b, 0) / data.count;
        const variance = avgEst > 0 ? Math.round(((avgAct - avgEst) / avgEst) * 100 * 10) / 10 : 0;
        const trend: LineItemAccuracy['trend'] = variance > 5 ? 'over' : variance < -5 ? 'under' : 'on_target';

        let suggestion = '';
        if (trend === 'over') suggestion = `${task} consistently runs over estimate by ${Math.abs(variance).toFixed(0)}%. Consider increasing labor hours.`;
        else if (trend === 'under') suggestion = `${task} estimates are conservative. Could reduce labor allocation by ${Math.abs(variance).toFixed(0)}%.`;
        else suggestion = `${task} estimates are well-calibrated within 5% of actuals.`;

        liItems.push({
          category: task,
          estimatedAvg: Math.round(avgEst * 100) / 100,
          actualAvg: Math.round(avgAct * 100) / 100,
          variance,
          sampleSize: data.count,
          trend,
          suggestion,
        });
      }

      // From material categories
      for (const [cat, data] of Object.entries(matCatAccuracy)) {
        if (data.estimated.length < 2) continue;
        const n = data.estimated.length;
        const avgEst = data.estimated.reduce((a, b) => a + b, 0) / n;
        const avgAct = data.actual.reduce((a, b) => a + b, 0) / n;
        if (avgEst <= 0) continue;
        const variance = Math.round(((avgAct - avgEst) / avgEst) * 100 * 10) / 10;
        const trend: LineItemAccuracy['trend'] = variance > 5 ? 'over' : variance < -5 ? 'under' : 'on_target';

        const label = cat.charAt(0).toUpperCase() + cat.slice(1);
        let suggestion = '';
        if (trend === 'over') suggestion = `${label} costs consistently run over by ${Math.abs(variance).toFixed(0)}%. Review supplier pricing or adjust estimates.`;
        else if (trend === 'under') suggestion = `${label} estimates are conservative. Could tighten by ${Math.abs(variance).toFixed(0)}%.`;
        else suggestion = `${label} estimates are accurate within 5%.`;

        liItems.push({
          category: label,
          estimatedAvg: Math.round(avgEst),
          actualAvg: Math.round(avgAct),
          variance,
          sampleSize: n,
          trend,
          suggestion,
        });
      }

      // Sort by absolute variance descending
      liItems.sort((a, b) => Math.abs(b.variance) - Math.abs(a.variance));
      setLineItems(liItems);

      // ══════════════════════════════════════════════════════
      // ── ESTIMATE FEEDBACK (derived from line items) ──
      // ══════════════════════════════════════════════════════

      const feedbackItems: EstimateFeedback[] = liItems.slice(0, 8).map((li) => {
        const absVar = Math.abs(li.variance);
        if (li.trend === 'over') {
          return {
            category: li.category,
            adjustment: `+${absVar.toFixed(0)}%`,
            reason: `Actuals consistently exceed estimates by ${absVar.toFixed(0)}% across ${li.sampleSize} jobs`,
            direction: 'up' as const,
          };
        } else if (li.trend === 'under') {
          return {
            category: li.category,
            adjustment: `-${absVar.toFixed(0)}%`,
            reason: `Estimates are padded by ~${absVar.toFixed(0)}% on average. Crew efficiency has improved.`,
            direction: 'down' as const,
          };
        } else {
          return {
            category: li.category,
            adjustment: 'No change',
            reason: `Estimates are well-calibrated within ${absVar.toFixed(1)}% of actuals`,
            direction: 'neutral' as const,
          };
        }
      });

      setEstimateFeedback(feedbackItems);

      // ══════════════════════════════════════════════════════
      // ── CREW PERFORMANCE TAB ──
      // ══════════════════════════════════════════════════════

      const completedJobSet = new Set(completedJobIds);
      const crewMetrics: CrewMetric[] = [];

      for (const [uid, jobSet] of Object.entries(userJobMap)) {
        const totalMins = userMinutesMap[uid] || 0;
        const totalCost = userCostMap[uid] || 0;
        const totalJobs = jobSet.size;
        if (totalJobs === 0 || totalMins === 0) continue;

        const totalHours = totalMins / 60;
        const costPerHour = totalHours > 0 ? Math.round(totalCost / totalHours) : 0;

        // Compute completions and avg days
        let completedCount = 0;
        const jobDays: number[] = [];
        for (const jid of jobSet) {
          if (completedJobSet.has(jid)) completedCount++;
        }
        const completionRate = totalJobs > 0 ? Math.round((completedCount / totalJobs) * 100) : 0;

        // Approximate avg job days from time entry days
        const daysArr = userJobDaysMap[uid] || [];
        const avgDays = totalJobs > 0 ? Math.round((daysArr.length / totalJobs) * 10) / 10 : 0;
        const avgDailyOutput = daysArr.length > 0 ? Math.round(totalCost / daysArr.length) : 0;

        // Find trade specialties from jobs
        const specialties = new Set<string>();
        for (const jid of jobSet) {
          const matchJob = [...activeJobs, ...completedJobs].find((j) => (j.id as string) === jid);
          if (matchJob) {
            const trade = (matchJob.trade_type as string) || ((matchJob.tags as string[]) || [])[0] || '';
            if (trade) specialties.add(trade.charAt(0).toUpperCase() + trade.slice(1));
          }
        }

        crewMetrics.push({
          crewName: `Worker ${uid.substring(0, 6)}`,
          members: 1,
          avgJobDays: avgDays,
          avgDailyOutput,
          completionRate,
          callbackRate: 0, // No callback data available yet
          specialties: Array.from(specialties).slice(0, 3),
          costPerHour,
        });
      }

      // Sort by daily output descending
      crewMetrics.sort((a, b) => b.avgDailyOutput - a.avgDailyOutput);
      setCrews(crewMetrics.slice(0, 20)); // Limit to top 20

      // ══════════════════════════════════════════════════════
      // ── COST TRENDS TAB (Monthly from completed jobs) ──
      // ══════════════════════════════════════════════════════

      const monthMap: Record<string, { revenue: number; cost: number; jobCount: number; margins: number[] }> = {};

      for (const cj of completedJobs) {
        const jid = cj.id as string;
        const compDate = cj.completed_at as string | null;
        if (!compDate) continue;
        const d = new Date(compDate);
        const monthKey = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
        const monthLabel = d.toLocaleString('en-US', { month: 'short', year: 'numeric' });

        if (!monthMap[monthKey]) monthMap[monthKey] = { revenue: 0, cost: 0, jobCount: 0, margins: [] };

        const revenue = Number(cj.estimated_amount || 0);
        const labor = laborByJob[jid] || 0;
        const mat = materialsByJob[jid] || 0;
        const exp = expensesByJob[jid] || 0;
        const cost = labor + mat + exp;
        const margin = revenue > 0 ? ((revenue - cost) / revenue) * 100 : 0;

        monthMap[monthKey].revenue += revenue;
        monthMap[monthKey].cost += cost;
        monthMap[monthKey].jobCount++;
        monthMap[monthKey].margins.push(margin);
        // Store label in a way we can retrieve it
        (monthMap[monthKey] as Record<string, unknown>)._label = monthLabel;
      }

      const trendsList: CostTrend[] = Object.entries(monthMap)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([, data]) => {
          const avgMargin = data.margins.length > 0
            ? Math.round((data.margins.reduce((s, m) => s + m, 0) / data.margins.length) * 10) / 10
            : 0;
          return {
            month: ((data as Record<string, unknown>)._label as string) || '',
            avgMargin,
            totalRevenue: Math.round(data.revenue),
            totalCost: Math.round(data.cost),
            jobCount: data.jobCount,
          };
        });

      setCostTrends(trendsList);

      // ══════════════════════════════════════════════════════
      // ── OVERHEAD TAB (Company-level expenses) ──
      // ══════════════════════════════════════════════════════

      const catTotals: Record<string, number> = {};
      const monthsInRange = Math.max(1, Math.ceil((Date.now() - sixMonthsAgo.getTime()) / (30 * 24 * 60 * 60 * 1000)));

      for (const oe of overheadExpenses) {
        const cat = (oe.category as string) || 'uncategorized';
        const label = OVERHEAD_CATEGORIES[cat] || cat.charAt(0).toUpperCase() + cat.slice(1);
        catTotals[label] = (catTotals[label] || 0) + Number(oe.amount || 0);
      }

      // Also include non-job expenses from the expenses fetched for jobs
      // (already filtered above)

      // Compute total monthly revenue from cost trends
      const totalMonthlyRevenue = trendsList.length > 0
        ? trendsList.reduce((s, t) => s + t.totalRevenue, 0) / trendsList.length
        : 1; // Avoid division by zero

      // Total billable hours from time entries (approximate)
      const totalBillableMinutes = Object.values(minutesByJob).reduce((s, m) => s + m, 0);
      const totalBillableHours = Math.max(1, totalBillableMinutes / 60);
      const monthlyBillableHours = totalBillableHours / monthsInRange;

      const overheadItems: OverheadItem[] = Object.entries(catTotals)
        .map(([category, total]) => {
          const monthlyCost = Math.round(total / monthsInRange);
          const perJobHour = monthlyBillableHours > 0 ? Math.round((monthlyCost / monthlyBillableHours) * 100) / 100 : 0;
          const percentOfRevenue = totalMonthlyRevenue > 0 ? Math.round((monthlyCost / totalMonthlyRevenue) * 100 * 10) / 10 : 0;
          return { category, monthlyCost, perJobHour, percentOfRevenue };
        })
        .sort((a, b) => b.monthlyCost - a.monthlyCost);

      setOverhead(overheadItems);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load job costs');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return {
    jobs,
    stats,
    postMortems,
    lineItems,
    crews,
    costTrends,
    overhead,
    estimateFeedback,
    loading,
    error,
    refetch: fetchData,
  };
}
