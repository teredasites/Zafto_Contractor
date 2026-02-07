'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapDailyLog, type DailyLogData } from './mappers';

export function useDailyLogs(jobId?: string) {
  const [logs, setLogs] = useState<DailyLogData[]>([]);
  const [todayLog, setTodayLog] = useState<DailyLogData | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchLogs = useCallback(async () => {
    const supabase = getSupabase();
    let query = supabase.from('daily_logs').select('*').order('log_date', { ascending: false });
    if (jobId) query = query.eq('job_id', jobId);
    const { data } = await query;
    const mapped = (data || []).map(mapDailyLog);
    setLogs(mapped);
    const today = new Date().toISOString().split('T')[0];
    setTodayLog(mapped.find((l: DailyLogData) => l.logDate === today) || null);
    setLoading(false);
  }, [jobId]);

  useEffect(() => {
    fetchLogs();
  }, [fetchLogs]);

  const saveLog = async (logData: Partial<DailyLogData> & { jobId: string }) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const today = new Date().toISOString().split('T')[0];
    const payload = {
      job_id: logData.jobId,
      company_id: user.app_metadata?.company_id,
      created_by_user_id: user.id,
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
      await supabase.from('daily_logs').update(payload).eq('id', todayLog.id);
    } else {
      await supabase.from('daily_logs').insert(payload);
    }
    fetchLogs();
  };

  return { logs, todayLog, loading, saveLog };
}
