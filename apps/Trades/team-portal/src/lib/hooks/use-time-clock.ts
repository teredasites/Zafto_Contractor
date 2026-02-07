'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapTimeEntry, type TimeEntryData } from './mappers';

export function useTimeClock() {
  const [entries, setEntries] = useState<TimeEntryData[]>([]);
  const [activeEntry, setActiveEntry] = useState<TimeEntryData | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchEntries = useCallback(async () => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setLoading(false); return; }

    const today = new Date().toISOString().split('T')[0];

    const { data } = await supabase
      .from('time_entries')
      .select('*, jobs(title)')
      .eq('user_id', user.id)
      .gte('clock_in', today)
      .order('clock_in', { ascending: false });

    const mapped = (data || []).map(mapTimeEntry);
    setEntries(mapped);
    setActiveEntry(mapped.find((e: TimeEntryData) => !e.clockOut) || null);
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchEntries();
    const supabase = getSupabase();
    const channel = supabase.channel('team-time')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'time_entries' }, () => fetchEntries())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchEntries]);

  const clockIn = async (jobId?: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const companyId = user.app_metadata?.company_id;
    await supabase.from('time_entries').insert({
      user_id: user.id,
      company_id: companyId,
      job_id: jobId || null,
      clock_in: new Date().toISOString(),
      status: 'active',
    });
    fetchEntries();
  };

  const clockOut = async () => {
    if (!activeEntry) return;
    const supabase = getSupabase();
    await supabase.from('time_entries')
      .update({ clock_out: new Date().toISOString(), status: 'completed' })
      .eq('id', activeEntry.id);
    fetchEntries();
  };

  const todayHours = entries.reduce((sum, e) => sum + e.totalHours, 0);

  return { entries, activeEntry, loading, clockIn, clockOut, todayHours };
}
