'use client';

// Time Clock Adjustments hook (Team Portal) — employee view
// Employees see adjustment history on their entries + acknowledge.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──

export interface TimeclockAdjustment {
  id: string;
  timeEntryId: string;
  adjustedByName: string | null;
  originalClockIn: string;
  originalClockOut: string | null;
  originalBreakMinutes: number | null;
  adjustedClockIn: string;
  adjustedClockOut: string | null;
  adjustedBreakMinutes: number | null;
  reason: string;
  adjustmentType: string;
  employeeAcknowledgedAt: string | null;
  createdAt: string;
}

// ── Hook: My adjustment history ──

export function useMyTimeclockAdjustments() {
  const [adjustments, setAdjustments] = useState<TimeclockAdjustment[]>([]);
  const [unacknowledgedCount, setUnacknowledgedCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const { data, error: err } = await supabase
        .from('timeclock_adjustments')
        .select('*')
        .eq('employee_id', user.id)
        .order('created_at', { ascending: false })
        .limit(50);

      if (err) throw err;

      const rows = data || [];

      // Resolve adjuster names
      const adjusterIds = [...new Set(rows.map((r: Record<string, unknown>) => r.adjusted_by as string))];
      const nameMap = new Map<string, string>();
      if (adjusterIds.length > 0) {
        const { data: profiles } = await supabase
          .from('profiles')
          .select('id, full_name')
          .in('id', adjusterIds);
        for (const p of profiles || []) {
          nameMap.set(p.id, p.full_name || 'Manager');
        }
      }

      const mapped: TimeclockAdjustment[] = rows.map((r: Record<string, unknown>) => ({
        id: r.id as string,
        timeEntryId: r.time_entry_id as string,
        adjustedByName: nameMap.get(r.adjusted_by as string) || 'Manager',
        originalClockIn: r.original_clock_in as string,
        originalClockOut: r.original_clock_out as string | null,
        originalBreakMinutes: r.original_break_minutes as number | null,
        adjustedClockIn: r.adjusted_clock_in as string,
        adjustedClockOut: r.adjusted_clock_out as string | null,
        adjustedBreakMinutes: r.adjusted_break_minutes as number | null,
        reason: r.reason as string,
        adjustmentType: (r.adjustment_type as string) || 'manual',
        employeeAcknowledgedAt: r.employee_acknowledged_at as string | null,
        createdAt: r.created_at as string,
      }));

      setAdjustments(mapped);
      setUnacknowledgedCount(mapped.filter(a => !a.employeeAcknowledgedAt).length);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load adjustments');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetch();
    const supabase = getSupabase();
    const channel = supabase
      .channel('team-timeclock-adj')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'timeclock_adjustments' }, () => fetch())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetch]);

  const acknowledge = useCallback(async (adjustmentId: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('timeclock_adjustments')
        .update({ employee_acknowledged_at: new Date().toISOString() })
        .eq('id', adjustmentId);
      if (err) throw err;
      fetch();
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Failed to acknowledge';
      setError(msg);
    }
  }, [fetch]);

  return { adjustments, unacknowledgedCount, loading, error, acknowledge, refresh: fetch };
}
