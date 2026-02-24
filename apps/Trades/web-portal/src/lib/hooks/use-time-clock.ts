'use client';

// Time Clock hook — fetches time_entries with user/job joins
// Supports week navigation, approval actions, and real-time updates.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface TimeEntry {
  id: string;
  userId: string;
  userName: string;
  userAvatar: string | null;
  jobId: string | null;
  jobTitle: string | null;
  clockIn: string;
  clockOut: string | null;
  breakMinutes: number;
  totalMinutes: number | null;
  overtimeMinutes: number;
  hourlyRate: number | null;
  laborCost: number | null;
  status: 'active' | 'completed' | 'approved' | 'rejected';
  notes: string | null;
  createdAt: string;
}

export interface TimeClockSummary {
  totalEntries: number;
  activeNow: number;
  totalHoursWeek: number;
  totalOvertimeWeek: number;
  pendingApproval: number;
}

export function useTimeClock(weekStart: Date) {
  const [entries, setEntries] = useState<TimeEntry[]>([]);
  const [summary, setSummary] = useState<TimeClockSummary>({
    totalEntries: 0, activeNow: 0, totalHoursWeek: 0, totalOvertimeWeek: 0, pendingApproval: 0,
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const weekEnd = new Date(weekStart);
  weekEnd.setDate(weekEnd.getDate() + 7);

  const fetchEntries = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: fetchErr } = await supabase
        .from('time_entries')
        .select(`
          id, user_id, job_id, clock_in, clock_out, break_minutes,
          total_minutes, overtime_minutes, hourly_rate, labor_cost,
          status, notes, created_at
        `)
        .is('deleted_at', null)
        .gte('clock_in', weekStart.toISOString())
        .lt('clock_in', weekEnd.toISOString())
        .order('clock_in', { ascending: false });

      if (fetchErr) throw fetchErr;

      // Fetch user names for the entries
      const userIds = [...new Set((data || []).map((e: Record<string, unknown>) => e.user_id as string))];
      const userMap = new Map<string, { name: string; avatar: string | null }>();

      if (userIds.length > 0) {
        const { data: profiles } = await getSupabase()
          .from('profiles')
          .select('id, full_name, avatar_url')
          .in('id', userIds);

        for (const p of profiles || []) {
          userMap.set(p.id, { name: p.full_name || 'Unknown', avatar: p.avatar_url });
        }
      }

      // Fetch job names
      const jobIds = [...new Set((data || []).map((e: Record<string, unknown>) => e.job_id as string).filter(Boolean))];
      const jobMap = new Map<string, string>();

      if (jobIds.length > 0) {
        const { data: jobs } = await getSupabase()
          .from('jobs')
          .select('id, name')
          .in('id', jobIds)
          .is('deleted_at', null);

        for (const j of jobs || []) {
          jobMap.set(j.id, j.name);
        }
      }

      const mapped: TimeEntry[] = (data || []).map((e: Record<string, unknown>) => {
        const user = userMap.get(e.user_id as string);
        return {
          id: e.id as string,
          userId: e.user_id as string,
          userName: user?.name || 'Unknown',
          userAvatar: user?.avatar || null,
          jobId: e.job_id as string | null,
          jobTitle: e.job_id ? (jobMap.get(e.job_id as string) || null) : null,
          clockIn: e.clock_in as string,
          clockOut: e.clock_out as string | null,
          breakMinutes: (e.break_minutes || 0) as number,
          totalMinutes: e.total_minutes as number | null,
          overtimeMinutes: (e.overtime_minutes || 0) as number,
          hourlyRate: e.hourly_rate as number | null,
          laborCost: e.labor_cost as number | null,
          status: e.status as TimeEntry['status'],
          notes: e.notes as string | null,
          createdAt: e.created_at as string,
        };
      });

      setEntries(mapped);

      // Compute summary
      const activeNow = mapped.filter(e => e.status === 'active').length;
      const totalMins = mapped.reduce((sum, e) => sum + (e.totalMinutes || 0), 0);
      const otMins = mapped.reduce((sum, e) => sum + e.overtimeMinutes, 0);
      const pending = mapped.filter(e => e.status === 'completed').length;

      setSummary({
        totalEntries: mapped.length,
        activeNow,
        totalHoursWeek: Math.round(totalMins / 60 * 10) / 10,
        totalOvertimeWeek: Math.round(otMins / 60 * 10) / 10,
        pendingApproval: pending,
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load time entries');
    } finally {
      setLoading(false);
    }
  }, [weekStart.toISOString()]);

  useEffect(() => { fetchEntries(); }, [fetchEntries]);

  useEffect(() => {
    const sb = getSupabase();
    const channel = sb
      .channel('time-clock-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'time_entries' }, () => fetchEntries())
      .subscribe();
    return () => { sb.removeChannel(channel); };
  }, [fetchEntries]);

  const approveEntry = useCallback(async (entryId: string) => {
    const { error: err } = await getSupabase()
      .from('time_entries')
      .update({ status: 'approved', approved_at: new Date().toISOString() })
      .eq('id', entryId);
    if (err) throw err;
    await fetchEntries();
  }, [fetchEntries]);

  const rejectEntry = useCallback(async (entryId: string) => {
    const { error: err } = await getSupabase()
      .from('time_entries')
      .update({ status: 'rejected' })
      .eq('id', entryId);
    if (err) throw err;
    await fetchEntries();
  }, [fetchEntries]);

  return { entries, summary, loading, error, refresh: fetchEntries, approveEntry, rejectEntry };
}
