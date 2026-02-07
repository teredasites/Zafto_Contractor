'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import { mapProject, type ProjectData } from './mappers';

export function useProjects() {
  const { profile } = useAuth();
  const [projects, setProjects] = useState<ProjectData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchProjects = useCallback(async () => {
    if (!profile?.customerId) { setLoading(false); return; }
    const supabase = getSupabase();

    const { data } = await supabase
      .from('jobs')
      .select('*')
      .eq('customer_id', profile.customerId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    setProjects((data || []).map(mapProject));
    setLoading(false);
  }, [profile?.customerId]);

  useEffect(() => {
    fetchProjects();
    if (!profile?.customerId) return;

    const supabase = getSupabase();
    const channel = supabase.channel('client-projects')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'jobs' }, () => fetchProjects())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchProjects, profile?.customerId]);

  return { projects, loading };
}

export function useProject(id: string) {
  const { profile } = useAuth();
  const [project, setProject] = useState<ProjectData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetch() {
      if (!profile?.customerId) {
        setError('Not authenticated');
        setLoading(false);
        return;
      }
      const supabase = getSupabase();
      const { data, error: fetchError } = await supabase
        .from('jobs')
        .select('*')
        .eq('id', id)
        .eq('customer_id', profile.customerId)
        .single();

      if (fetchError) {
        setError(fetchError.message);
      } else if (data) {
        setProject(mapProject(data));
      }
      setLoading(false);
    }
    fetch();
  }, [id, profile?.customerId]);

  return { project, loading, error };
}
