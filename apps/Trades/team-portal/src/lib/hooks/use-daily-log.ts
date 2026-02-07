'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapDailyLog, type DailyLogData } from './mappers';

export function useDailyLogs(jobId?: string) {
  const [logs, setLogs] = useState<DailyLogData[]>([]);
  const [todayLog, setTodayLog] = useState<DailyLogData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchLogs = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      let query = supabase.from('daily_logs').select('*').order('log_date', { ascending: false });
      if (jobId) query = query.eq('job_id', jobId);
      const { data, error: err } = await query;

      if (err) throw err;
      const mapped = (data || []).map(mapDailyLog);
      setLogs(mapped);
      const today = new Date().toISOString().split('T')[0];
      setTodayLog(mapped.find((l: DailyLogData) => l.logDate === today) || null);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load daily logs';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetchLogs();
  }, [fetchLogs]);

  const saveLog = async (logData: Partial<DailyLogData> & { jobId: string }) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const today = new Date().toISOString().split('T')[0];
      const payload = {
        job_id: logData.jobId,
        company_id: user.app_metadata?.company_id,
        author_user_id: user.id,
        log_date: today,
        weather: logData.weather || '',
        temperature_f: logData.temperatureF || null,
        summary: logData.summary || '',
        work_performed: logData.workPerformed || '',
        issues: logData.issues || '',
        crew_count: logData.crewCount || 0,
        hours_worked: logData.hoursWorked || 0,
      };

      if (todayLog) {
        const { error: err } = await supabase.from('daily_logs').update(payload).eq('id', todayLog.id);
        if (err) throw err;
      } else {
        const { error: err } = await supabase.from('daily_logs').insert(payload);
        if (err) throw err;
      }
      fetchLogs();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to save daily log';
      setError(msg);
      throw e;
    }
  };

  return { logs, todayLog, loading, error, saveLog };
}
