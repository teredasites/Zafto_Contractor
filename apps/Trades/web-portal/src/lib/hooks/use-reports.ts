'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface MonthlyRevenue {
  date: string;
  revenue: number;
  expenses: number;
  profit: number;
}

export interface StatusCount {
  name: string;
  value: number;
  color: string;
}

export interface RevenueCategory {
  name: string;
  value: number;
  color: string;
}

export interface TeamMemberStat {
  name: string;
  role: string;
  jobs: number;
  revenue: number;
  avgRating: number;
}

export interface InvoiceStats {
  totalInvoiced: number;
  totalCollected: number;
  outstanding: number;
  overdue: number;
  aging: { label: string; amount: number; bgClass: string; textClass: string }[];
}

export interface JobStats {
  total: number;
  completionRate: number;
  avgValue: number;
}

export interface ReportData {
  monthlyRevenue: MonthlyRevenue[];
  jobsByStatus: StatusCount[];
  revenueByCategory: RevenueCategory[];
  team: TeamMemberStat[];
  invoiceStats: InvoiceStats;
  jobStats: JobStats;
}

const STATUS_COLORS: Record<string, string> = {
  draft: '#94a3b8',
  scheduled: '#3b82f6',
  dispatched: '#8b5cf6',
  enRoute: '#06b6d4',
  inProgress: '#f59e0b',
  onHold: '#ef4444',
  completed: '#10b981',
  invoiced: '#6366f1',
  cancelled: '#6b7280',
};

const STATUS_LABELS: Record<string, string> = {
  draft: 'Draft',
  scheduled: 'Scheduled',
  dispatched: 'Dispatched',
  enRoute: 'En Route',
  inProgress: 'In Progress',
  onHold: 'On Hold',
  completed: 'Completed',
  invoiced: 'Invoiced',
  cancelled: 'Cancelled',
};

const MONTH_NAMES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

export function useReports() {
  const [data, setData] = useState<ReportData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchReports = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const [invoicesRes, jobsRes, usersRes, materialsRes] = await Promise.all([
        supabase.from('invoices').select('id, status, total, amount_paid, amount_due, due_date, paid_at, created_at').is('deleted_at', null),
        supabase.from('jobs').select('id, status, estimated_amount, actual_amount, assigned_user_ids, tags, completed_at, created_at').is('deleted_at', null),
        supabase.from('users').select('id, full_name, role'),
        supabase.from('job_materials').select('id, job_id, total_cost, created_at').is('deleted_at', null),
      ]);

      const invoices: Record<string, unknown>[] = invoicesRes.data || [];
      const jobs: Record<string, unknown>[] = jobsRes.data || [];
      const users: Record<string, unknown>[] = usersRes.data || [];
      const materials: Record<string, unknown>[] = materialsRes.data || [];

      const now = new Date();

      // === Monthly Revenue (last 12 months) ===
      const monthlyRevenue: MonthlyRevenue[] = [];
      for (let i = 11; i >= 0; i--) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const monthStart = d;
        const monthEnd = new Date(d.getFullYear(), d.getMonth() + 1, 0, 23, 59, 59);

        const monthInvoices = invoices.filter((inv) => {
          const paidAt = inv.paid_at ? new Date(inv.paid_at as string) : null;
          return paidAt && paidAt >= monthStart && paidAt <= monthEnd;
        });
        const revenue = monthInvoices.reduce((sum, inv) => sum + Number(inv.total || 0), 0);

        const monthMaterials = materials.filter((m) => {
          const created = new Date(m.created_at as string);
          return created >= monthStart && created <= monthEnd;
        });
        const expenses = monthMaterials.reduce((sum, m) => sum + Number(m.total_cost || 0), 0);

        monthlyRevenue.push({
          date: MONTH_NAMES[d.getMonth()],
          revenue,
          expenses,
          profit: revenue - expenses,
        });
      }

      // === Jobs by Status ===
      const statusCounts: Record<string, number> = {};
      for (const job of jobs) {
        const status = (job.status as string) || 'draft';
        statusCounts[status] = (statusCounts[status] || 0) + 1;
      }
      const jobsByStatus: StatusCount[] = Object.entries(statusCounts)
        .map(([status, count]) => ({
          name: STATUS_LABELS[status] || status,
          value: count,
          color: STATUS_COLORS[status] || '#94a3b8',
        }))
        .sort((a, b) => b.value - a.value);

      // === Revenue by Category (from job tags) ===
      const categoryColors = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4'];
      const categoryMap: Record<string, number> = {};
      for (const job of jobs) {
        const tags = (job.tags as string[]) || [];
        const category = tags[0] || 'uncategorized';
        const amount = Number(job.actual_amount || job.estimated_amount || 0);
        categoryMap[category] = (categoryMap[category] || 0) + amount;
      }
      const revenueByCategory: RevenueCategory[] = Object.entries(categoryMap)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 6)
        .map(([name, value], i) => ({
          name: name.charAt(0).toUpperCase() + name.slice(1),
          value,
          color: categoryColors[i % categoryColors.length],
        }));
      if (revenueByCategory.length === 0) {
        revenueByCategory.push({ name: 'No data', value: 0, color: '#94a3b8' });
      }

      // === Team Performance ===
      const team: TeamMemberStat[] = users
        .map((user) => {
          const userJobs = jobs.filter((j) => {
            const assigned = (j.assigned_user_ids as string[]) || [];
            return assigned.includes(user.id as string);
          });
          const jobRevenue = userJobs.reduce(
            (sum, j) => sum + Number(j.actual_amount || j.estimated_amount || 0),
            0
          );
          return {
            name: ((user.full_name || 'Unknown') as string),
            role: ((user.role as string) || 'field_tech'),
            jobs: userJobs.length,
            revenue: jobRevenue,
            avgRating: 0,
          };
        })
        .filter((m) => m.jobs > 0)
        .sort((a, b) => b.revenue - a.revenue);

      // === Invoice Stats ===
      const totalInvoiced = invoices.reduce((sum, inv) => sum + Number(inv.total || 0), 0);
      const totalCollected = invoices.reduce((sum, inv) => sum + Number(inv.amount_paid || 0), 0);
      const outstandingInvs = invoices.filter(
        (inv) => inv.status !== 'paid' && inv.status !== 'voided'
      );
      const outstanding = outstandingInvs.reduce((sum, inv) => sum + Number(inv.amount_due || 0), 0);
      const overdueInvs = outstandingInvs.filter(
        (inv) => inv.due_date && new Date(inv.due_date as string) < now
      );
      const overdueAmount = overdueInvs.reduce((sum, inv) => sum + Number(inv.amount_due || 0), 0);

      const aging: InvoiceStats['aging'] = [
        { label: 'Current (0-30 days)', amount: 0, bgClass: 'bg-emerald-50 dark:bg-emerald-900/20', textClass: 'text-emerald-600' },
        { label: '31-60 days', amount: 0, bgClass: 'bg-amber-50 dark:bg-amber-900/20', textClass: 'text-amber-600' },
        { label: '61-90 days', amount: 0, bgClass: 'bg-orange-50 dark:bg-orange-900/20', textClass: 'text-orange-600' },
        { label: '90+ days', amount: 0, bgClass: 'bg-red-50 dark:bg-red-900/20', textClass: 'text-red-600' },
      ];
      for (const inv of outstandingInvs) {
        if (!inv.due_date) continue;
        const daysOverdue = Math.floor(
          (now.getTime() - new Date(inv.due_date as string).getTime()) / (1000 * 60 * 60 * 24)
        );
        const amount = Number(inv.amount_due || 0);
        if (daysOverdue <= 30) aging[0].amount += amount;
        else if (daysOverdue <= 60) aging[1].amount += amount;
        else if (daysOverdue <= 90) aging[2].amount += amount;
        else aging[3].amount += amount;
      }

      // === Job Stats ===
      const completedJobs = jobs.filter((j) => j.status === 'completed' || j.status === 'invoiced');
      const completionRate = jobs.length > 0 ? Math.round((completedJobs.length / jobs.length) * 100) : 0;
      const totalJobValue = jobs.reduce((sum, j) => sum + Number(j.estimated_amount || 0), 0);
      const avgValue = jobs.length > 0 ? totalJobValue / jobs.length : 0;

      setData({
        monthlyRevenue,
        jobsByStatus,
        revenueByCategory,
        team,
        invoiceStats: { totalInvoiced, totalCollected, outstanding, overdue: overdueAmount, aging },
        jobStats: { total: jobs.length, completionRate, avgValue },
      });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load reports');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchReports();
  }, [fetchReports]);

  return { data, loading, error, refetch: fetchReports };
}
