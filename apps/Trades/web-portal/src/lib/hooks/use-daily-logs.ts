'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface DailyLogData {
  id: string;
  companyId: string;
  jobId: string;
  authorUserId: string;
  logDate: string;
  weather: string;
  temperatureF: number | null;
  summary: string;
  workPerformed: string;
  issues: string;
  delays: string;
  visitors: string;
  crewMembers: string[];
  crewCount: number;
  hoursWorked: number;
  photoIds: string[];
  safetyNotes: string;
  tradeData: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

function mapDailyLog(row: Record<string, unknown>): DailyLogData {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    jobId: (row.job_id as string) || '',
    authorUserId: (row.author_user_id as string) || '',
    logDate: (row.log_date as string) || '',
    weather: (row.weather as string) || '',
    temperatureF: (row.temperature_f as number) ?? null,
    summary: (row.summary as string) || '',
    workPerformed: (row.work_performed as string) || '',
    issues: (row.issues as string) || '',
    delays: (row.delays as string) || '',
    visitors: (row.visitors as string) || '',
    crewMembers: (row.crew_members as string[]) || [],
    crewCount: (row.crew_count as number) || 0,
    hoursWorked: (row.hours_worked as number) || 0,
    photoIds: (row.photo_ids as string[]) || [],
    safetyNotes: (row.safety_notes as string) || '',
    tradeData: (row.trade_data as Record<string, unknown>) || {},
    createdAt: (row.created_at as string) || '',
    updatedAt: (row.updated_at as string) || '',
  };
}

export function useDailyLogs(jobId?: string) {
  const [logs, setLogs] = useState<DailyLogData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchLogs = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      let query = supabase
        .from('daily_logs')
        .select('*')
        .is('deleted_at', null)
        .order('log_date', { ascending: false });
      if (jobId) query = query.eq('job_id', jobId);
      const { data, error: err } = await query;
      if (err) throw err;
      setLogs((data || []).map(mapDailyLog));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load daily logs');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetchLogs();
    const supabase = getSupabase();
    const channel = supabase
      .channel('crm-daily-logs')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'daily_logs' }, () => fetchLogs())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchLogs]);

  const saveLog = async (data: {
    jobId: string;
    summary: string;
    weather?: string;
    temperatureF?: number;
    workPerformed?: string;
    issues?: string;
    delays?: string;
    visitors?: string;
    crewCount?: number;
    hoursWorked?: number;
    safetyNotes?: string;
    tradeData?: Record<string, unknown>;
  }) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const today = new Date().toISOString().split('T')[0];
      const todayLog = logs.find(l => l.logDate === today && l.jobId === data.jobId);

      const payload = {
        job_id: data.jobId,
        company_id: user.app_metadata?.company_id,
        author_user_id: user.id,
        log_date: today,
        summary: data.summary,
        weather: data.weather || '',
        temperature_f: data.temperatureF ?? null,
        work_performed: data.workPerformed || '',
        issues: data.issues || '',
        delays: data.delays || '',
        visitors: data.visitors || '',
        crew_count: data.crewCount || 1,
        hours_worked: data.hoursWorked || 0,
        safety_notes: data.safetyNotes || '',
        trade_data: data.tradeData || {},
      };

      if (todayLog) {
        const { error: err } = await supabase.from('daily_logs').update(payload).eq('id', todayLog.id);
        if (err) throw err;
      } else {
        const { error: err } = await supabase.from('daily_logs').insert(payload);
        if (err) throw err;
      }
      await fetchLogs();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to save daily log';
      setError(msg);
      throw e;
    }
  };

  const updateLog = async (logId: string, updates: {
    summary?: string;
    weather?: string;
    temperatureF?: number;
    workPerformed?: string;
    issues?: string;
    delays?: string;
    visitors?: string;
    crewCount?: number;
    hoursWorked?: number;
    safetyNotes?: string;
    tradeData?: Record<string, unknown>;
  }) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const payload: Record<string, unknown> = {};
      if (updates.summary !== undefined) payload.summary = updates.summary;
      if (updates.weather !== undefined) payload.weather = updates.weather;
      if (updates.temperatureF !== undefined) payload.temperature_f = updates.temperatureF;
      if (updates.workPerformed !== undefined) payload.work_performed = updates.workPerformed;
      if (updates.issues !== undefined) payload.issues = updates.issues;
      if (updates.delays !== undefined) payload.delays = updates.delays;
      if (updates.visitors !== undefined) payload.visitors = updates.visitors;
      if (updates.crewCount !== undefined) payload.crew_count = updates.crewCount;
      if (updates.hoursWorked !== undefined) payload.hours_worked = updates.hoursWorked;
      if (updates.safetyNotes !== undefined) payload.safety_notes = updates.safetyNotes;
      if (updates.tradeData !== undefined) payload.trade_data = updates.tradeData;
      const { error: err } = await supabase.from('daily_logs').update(payload).eq('id', logId);
      if (err) throw err;
      await fetchLogs();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to update daily log';
      setError(msg);
      throw e;
    }
  };

  const deleteLog = async (logId: string) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('daily_logs')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', logId);
      if (err) throw err;
      await fetchLogs();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to delete daily log');
      throw e;
    }
  };

  const todayLog = logs.find(l => l.logDate === new Date().toISOString().split('T')[0]);
  const logsWithIssues = logs.filter(l => l.issues && l.issues.trim().length > 0);

  return { logs, todayLog, logsWithIssues, loading, error, saveLog, updateLog, deleteLog, refresh: fetchLogs };
}
