'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import type { ScheduleDependency, DependencyType } from '@/lib/types/scheduling';

export function useScheduleDependencies(projectId: string | undefined) {
  const [dependencies, setDependencies] = useState<ScheduleDependency[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDependencies = useCallback(async () => {
    if (!projectId) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('schedule_dependencies')
        .select('*')
        .eq('project_id', projectId)
        .order('created_at', { ascending: true });

      if (err) throw err;
      setDependencies(data || []);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load dependencies';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [projectId]);

  useEffect(() => {
    fetchDependencies();

    if (!projectId) return;

    const supabase = getSupabase();
    const channel = supabase
      .channel(`schedule-deps-${projectId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'schedule_dependencies',
        filter: `project_id=eq.${projectId}`,
      }, () => {
        fetchDependencies();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [projectId, fetchDependencies]);

  const createDependency = async (data: {
    predecessor_id: string;
    successor_id: string;
    dependency_type?: DependencyType;
    lag_days?: number;
  }): Promise<string> => {
    if (!projectId) throw new Error('No project selected');

    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('schedule_dependencies')
      .insert({
        company_id: companyId,
        project_id: projectId,
        predecessor_id: data.predecessor_id,
        successor_id: data.successor_id,
        dependency_type: data.dependency_type || 'FS',
        lag_days: data.lag_days ?? 0,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const deleteDependency = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('schedule_dependencies')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  return {
    dependencies,
    loading,
    error,
    createDependency,
    deleteDependency,
    refetch: fetchDependencies,
  };
}
