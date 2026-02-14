'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapActivity } from './mappers';
import type { DashboardStats, Activity } from '@/types';

const EMPTY_STATS: DashboardStats = {
  bids: { pending: 0, sent: 0, accepted: 0, totalValue: 0, conversionRate: 0 },
  jobs: { scheduled: 0, inProgress: 0, completed: 0, completedThisMonth: 0 },
  invoices: { draft: 0, sent: 0, overdue: 0, overdueAmount: 0, paidThisMonth: 0 },
  revenue: { today: 0, thisWeek: 0, thisMonth: 0, lastMonth: 0, monthOverMonthChange: 0 },
};

export function useStats() {
  const [stats, setStats] = useState<DashboardStats>(EMPTY_STATS);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchStats = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Date boundaries
      const now = new Date();
      const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
      const thisMonthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
      const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString();
      const lastMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59).toISOString();
      // Week start (Monday)
      const dayOfWeek = now.getDay();
      const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
      const weekStart = new Date(now.getFullYear(), now.getMonth(), now.getDate() - mondayOffset).toISOString();

      // Parallel queries for all stats
      const [jobsRes, bidsRes, invoicesRes, paidRecentRes, paidLastMonthRes, completedThisMonthRes] = await Promise.all([
        supabase.from('jobs').select('status'),
        supabase.from('bids').select('status, total'),
        supabase.from('invoices').select('status, total, amount_due, paid_at'),
        // Paid invoices from start of last month to now (covers today, week, this month)
        supabase.from('invoices').select('total, paid_at').eq('status', 'paid').gte('paid_at', lastMonthStart),
        // Paid invoices last month only (for MoM comparison)
        supabase.from('invoices').select('total, paid_at').eq('status', 'paid').gte('paid_at', lastMonthStart).lte('paid_at', lastMonthEnd),
        // Jobs completed this month
        supabase.from('jobs').select('id').eq('status', 'completed').gte('completed_at', thisMonthStart),
      ]);

      const jobs: { status: string }[] = jobsRes.data || [];
      const bids: { status: string; total: number }[] = bidsRes.data || [];
      const invoices: { status: string; total: number; amount_due: number; paid_at: string | null }[] = invoicesRes.data || [];
      const paidRecent: { total: number; paid_at: string | null }[] = paidRecentRes.data || [];
      const paidLastMonth: { total: number; paid_at: string | null }[] = paidLastMonthRes.data || [];
      const completedThisMonthJobs: { id: string }[] = completedThisMonthRes.data || [];

      // Job stats
      const jobScheduled = jobs.filter((j) => j.status === 'scheduled').length;
      const jobInProgress = jobs.filter((j) => j.status === 'inProgress' || j.status === 'dispatched' || j.status === 'enRoute' || j.status === 'in_progress' || j.status === 'en_route').length;
      const jobCompleted = jobs.filter((j) => j.status === 'completed').length;

      // Bid stats
      const bidDraft = bids.filter((b) => b.status === 'draft').length;
      const bidSent = bids.filter((b) => b.status === 'sent' || b.status === 'viewed').length;
      const bidAccepted = bids.filter((b) => b.status === 'accepted').length;
      const bidTotalValue = bids.reduce((sum, b) => sum + (Number(b.total) || 0), 0);
      // Conversion rate: accepted / (sent + viewed + accepted + rejected) — excludes drafts
      const bidSentOrBeyond = bids.filter((b) => b.status !== 'draft').length;
      const bidConversion = bidSentOrBeyond > 0 ? Math.round((bidAccepted / bidSentOrBeyond) * 100) : 0;

      // Invoice stats
      const invDraft = invoices.filter((i) => i.status === 'draft' || i.status === 'pendingApproval').length;
      const invSent = invoices.filter((i) => i.status === 'sent' || i.status === 'viewed').length;
      const invOverdue = invoices.filter((i) => i.status === 'overdue').length;
      const invOverdueAmount = invoices
        .filter((i) => i.status === 'overdue')
        .reduce((sum, i) => sum + (Number(i.amount_due) || 0), 0);

      // Revenue stats — compute all periods from paidRecent
      const revenueToday = paidRecent
        .filter((i) => i.paid_at && i.paid_at >= todayStart)
        .reduce((sum, i) => sum + (Number(i.total) || 0), 0);
      const revenueThisWeek = paidRecent
        .filter((i) => i.paid_at && i.paid_at >= weekStart)
        .reduce((sum, i) => sum + (Number(i.total) || 0), 0);
      const revenueThisMonth = paidRecent
        .filter((i) => i.paid_at && i.paid_at >= thisMonthStart)
        .reduce((sum, i) => sum + (Number(i.total) || 0), 0);
      const revenueLastMonth = paidLastMonth.reduce((sum, i) => sum + (Number(i.total) || 0), 0);
      const paidThisMonthCount = paidRecent.filter((i) => i.paid_at && i.paid_at >= thisMonthStart).length;

      // Month-over-month change
      const monthOverMonthChange = revenueLastMonth > 0
        ? Math.round(((revenueThisMonth - revenueLastMonth) / revenueLastMonth) * 100)
        : revenueThisMonth > 0 ? 100 : 0;

      setStats({
        bids: {
          pending: bidDraft,
          sent: bidSent,
          accepted: bidAccepted,
          totalValue: bidTotalValue,
          conversionRate: bidConversion,
        },
        jobs: {
          scheduled: jobScheduled,
          inProgress: jobInProgress,
          completed: jobCompleted,
          completedThisMonth: completedThisMonthJobs.length,
        },
        invoices: {
          draft: invDraft,
          sent: invSent,
          overdue: invOverdue,
          overdueAmount: invOverdueAmount,
          paidThisMonth: paidThisMonthCount,
        },
        revenue: {
          today: revenueToday,
          thisWeek: revenueThisWeek,
          thisMonth: revenueThisMonth,
          lastMonth: revenueLastMonth,
          monthOverMonthChange,
        },
      });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load stats';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchStats();
  }, [fetchStats]);

  return { stats, loading, error, refetch: fetchStats };
}

export function useActivity(limit = 10) {
  const [activity, setActivity] = useState<Activity[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchActivity = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('audit_log')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(limit);

      if (err) throw err;
      setActivity((data || []).map(mapActivity));
    } catch {
      setActivity([]);
    } finally {
      setLoading(false);
    }
  }, [limit]);

  useEffect(() => {
    fetchActivity();
  }, [fetchActivity]);

  return { activity, loading };
}
