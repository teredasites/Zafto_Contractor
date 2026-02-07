'use client';

import { useState, useEffect } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapJob, type JobData } from './mappers';

export function useMyJobs() {
  const [jobs, setJobs] = useState<JobData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const supabase = getSupabase();

    async function fetchJobs() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const { data } = await supabase
        .from('jobs')
        .select('*')
        .contains('assigned_to', [user.id])
        .is('deleted_at', null)
        .order('scheduled_start', { ascending: true, nullsFirst: false });

      setJobs((data || []).map(mapJob));
      setLoading(false);
    }

    fetchJobs();

    const channel = supabase.channel('team-jobs')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'jobs' }, () => fetchJobs())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, []);

  return { jobs, loading };
}

export function useJob(jobId: string) {
  const [job, setJob] = useState<JobData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!jobId) { setLoading(false); return; }
    const supabase = getSupabase();

    async function fetchJob() {
      const { data } = await supabase
        .from('jobs')
        .select('*')
        .eq('id', jobId)
        .single();

      setJob(data ? mapJob(data) : null);
      setLoading(false);
    }

    fetchJob();
  }, [jobId]);

  return { job, loading };
}
