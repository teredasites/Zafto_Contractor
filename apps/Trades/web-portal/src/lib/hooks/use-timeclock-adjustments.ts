'use client';

// Time Clock Adjustments hook — managers can adjust employee clock entries
// Full audit trail with before/after values, reason required.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──

type AdjustmentType = 'manual' | 'correction' | 'missed_punch' | 'break_adjustment' | 'job_reassignment';

export interface TimeclockAdjustment {
  id: string;
  companyId: string;
  timeEntryId: string;
  adjustedBy: string;
  adjustedByName: string | null;
  employeeId: string;
  employeeName: string | null;
  originalClockIn: string;
  originalClockOut: string | null;
  originalBreakMinutes: number | null;
  adjustedClockIn: string;
  adjustedClockOut: string | null;
  adjustedBreakMinutes: number | null;
  reason: string;
  adjustmentType: AdjustmentType;
  employeeNotified: boolean;
  employeeAcknowledgedAt: string | null;
  createdAt: string;
}

interface AdjustTimeEntryInput {
  timeEntryId: string;
  employeeId: string;
  originalClockIn: string;
  originalClockOut: string | null;
  originalBreakMinutes: number | null;
  adjustedClockIn: string;
  adjustedClockOut: string | null;
  adjustedBreakMinutes: number | null;
  reason: string;
  adjustmentType?: AdjustmentType;
}

// ── Mapper ──

function mapAdjustment(
  row: Record<string, unknown>,
  adjusterMap: Map<string, string>,
  employeeMap: Map<string, string>,
): TimeclockAdjustment {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    timeEntryId: row.time_entry_id as string,
    adjustedBy: row.adjusted_by as string,
    adjustedByName: adjusterMap.get(row.adjusted_by as string) || null,
    employeeId: row.employee_id as string,
    employeeName: employeeMap.get(row.employee_id as string) || null,
    originalClockIn: row.original_clock_in as string,
    originalClockOut: row.original_clock_out as string | null,
    originalBreakMinutes: row.original_break_minutes as number | null,
    adjustedClockIn: row.adjusted_clock_in as string,
    adjustedClockOut: row.adjusted_clock_out as string | null,
    adjustedBreakMinutes: row.adjusted_break_minutes as number | null,
    reason: row.reason as string,
    adjustmentType: (row.adjustment_type as AdjustmentType) || 'manual',
    employeeNotified: (row.employee_notified as boolean) || false,
    employeeAcknowledgedAt: row.employee_acknowledged_at as string | null,
    createdAt: row.created_at as string,
  };
}

// ── Hook: Adjustments for a time entry ──

export function useTimeclockAdjustments(timeEntryId: string | null) {
  const [adjustments, setAdjustments] = useState<TimeclockAdjustment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!timeEntryId) {
      setAdjustments([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('timeclock_adjustments')
        .select('*')
        .eq('time_entry_id', timeEntryId)
        .order('created_at', { ascending: false });

      if (err) throw err;

      const rows = data || [];
      const userIds = [
        ...new Set([
          ...rows.map((r: Record<string, unknown>) => r.adjusted_by as string),
          ...rows.map((r: Record<string, unknown>) => r.employee_id as string),
        ]),
      ];

      const nameMap = new Map<string, string>();
      if (userIds.length > 0) {
        const { data: profiles } = await supabase
          .from('profiles')
          .select('id, full_name')
          .in('id', userIds);
        for (const p of profiles || []) {
          nameMap.set(p.id, p.full_name || 'Unknown');
        }
      }

      setAdjustments(rows.map((r: Record<string, unknown>) => mapAdjustment(r, nameMap, nameMap)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load adjustments');
    } finally {
      setLoading(false);
    }
  }, [timeEntryId]);

  useEffect(() => { fetch(); }, [fetch]);

  return { adjustments, loading, error, refresh: fetch };
}

// ── Hook: Adjustment history for an employee ──

export function useEmployeeAdjustmentHistory(employeeId: string | null, opts?: { from?: string; to?: string }) {
  const [adjustments, setAdjustments] = useState<TimeclockAdjustment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!employeeId) {
      setAdjustments([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      let query = supabase
        .from('timeclock_adjustments')
        .select('*')
        .eq('employee_id', employeeId);

      if (opts?.from) query = query.gte('created_at', opts.from);
      if (opts?.to) query = query.lte('created_at', opts.to);

      const { data, error: err } = await query.order('created_at', { ascending: false });
      if (err) throw err;

      const rows = data || [];
      const userIds = [
        ...new Set([
          ...rows.map((r: Record<string, unknown>) => r.adjusted_by as string),
          ...rows.map((r: Record<string, unknown>) => r.employee_id as string),
        ]),
      ];

      const nameMap = new Map<string, string>();
      if (userIds.length > 0) {
        const { data: profiles } = await getSupabase()
          .from('profiles')
          .select('id, full_name')
          .in('id', userIds);
        for (const p of profiles || []) {
          nameMap.set(p.id, p.full_name || 'Unknown');
        }
      }

      setAdjustments(rows.map((r: Record<string, unknown>) => mapAdjustment(r, nameMap, nameMap)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load adjustment history');
    } finally {
      setLoading(false);
    }
  }, [employeeId, opts?.from, opts?.to]);

  useEffect(() => { fetch(); }, [fetch]);

  return { adjustments, loading, error, refresh: fetch };
}

// ── Hook: Create time adjustment (manager action) ──

export function useAdjustTimeClock() {
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const adjustTimeEntry = useCallback(async (input: AdjustTimeEntryInput) => {
    try {
      setSubmitting(true);
      setError(null);
      const supabase = getSupabase();

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const companyId = user.app_metadata?.company_id;
      if (!companyId) throw new Error('No company context');

      // 1. Insert the adjustment audit record
      const { error: adjErr } = await supabase
        .from('timeclock_adjustments')
        .insert({
          company_id: companyId,
          time_entry_id: input.timeEntryId,
          adjusted_by: user.id,
          employee_id: input.employeeId,
          original_clock_in: input.originalClockIn,
          original_clock_out: input.originalClockOut,
          original_break_minutes: input.originalBreakMinutes,
          adjusted_clock_in: input.adjustedClockIn,
          adjusted_clock_out: input.adjustedClockOut,
          adjusted_break_minutes: input.adjustedBreakMinutes,
          reason: input.reason,
          adjustment_type: input.adjustmentType || 'manual',
        });

      if (adjErr) throw adjErr;

      // 2. Update the time entry with adjusted values
      const updateData: Record<string, unknown> = {
        clock_in: input.adjustedClockIn,
        last_adjusted_at: new Date().toISOString(),
        last_adjusted_by: user.id,
      };
      if (input.adjustedClockOut !== null) {
        updateData.clock_out = input.adjustedClockOut;
      }
      if (input.adjustedBreakMinutes !== null) {
        updateData.break_minutes = input.adjustedBreakMinutes;
      }
      // Recalculate total_minutes
      if (input.adjustedClockOut) {
        const totalMins = Math.floor(
          (new Date(input.adjustedClockOut).getTime() - new Date(input.adjustedClockIn).getTime()) / 60000
        ) - (input.adjustedBreakMinutes || 0);
        updateData.total_minutes = totalMins > 0 ? totalMins : 0;
      }

      const { error: updateErr } = await supabase
        .from('time_entries')
        .update(updateData)
        .eq('id', input.timeEntryId);

      if (updateErr) throw updateErr;

      // 3. Create notification for the employee
      try {
        await supabase.from('notifications').insert({
          company_id: companyId,
          user_id: input.employeeId,
          title: 'Time entry adjusted',
          body: `Your time entry was adjusted. Reason: ${input.reason}`,
          type: 'timeclock_adjustment',
          entity_type: 'time_entry',
          entity_id: input.timeEntryId,
          priority: 'normal',
        });
      } catch {
        // Notification failure is non-critical — don't block the adjustment
      }

      return true;
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Failed to adjust time entry';
      setError(msg);
      throw e;
    } finally {
      setSubmitting(false);
    }
  }, []);

  return { adjustTimeEntry, submitting, error };
}
