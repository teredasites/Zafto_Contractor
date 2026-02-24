'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import type { ScheduleProject, ScheduleProjectStatus } from '@/lib/types/scheduling';

export function useScheduleProjects() {
  const [projects, setProjects] = useState<ScheduleProject[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchProjects = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('schedule_projects')
        .select('*')
        .is('deleted_at', null)
        .order('updated_at', { ascending: false });

      if (err) throw err;
      setProjects(data || []);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load schedule projects';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchProjects();

    const supabase = getSupabase();
    const channel = supabase
      .channel('schedule-projects-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'schedule_projects' }, () => {
        fetchProjects();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchProjects]);

  const createProject = async (data: {
    name: string;
    description?: string;
    job_id?: string;
    planned_start?: string;
    planned_finish?: string;
    default_calendar_id?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('schedule_projects')
      .insert({
        company_id: companyId,
        name: data.name,
        description: data.description || null,
        job_id: data.job_id || null,
        planned_start: data.planned_start || null,
        planned_finish: data.planned_finish || null,
        default_calendar_id: data.default_calendar_id || null,
        status: 'draft',
        created_by: user.id,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateProject = async (id: string, data: Partial<ScheduleProject>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.name !== undefined) updateData.name = data.name;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.planned_start !== undefined) updateData.planned_start = data.planned_start;
    if (data.planned_finish !== undefined) updateData.planned_finish = data.planned_finish;
    if (data.default_calendar_id !== undefined) updateData.default_calendar_id = data.default_calendar_id;
    if (data.hours_per_day !== undefined) updateData.hours_per_day = data.hours_per_day;
    if (data.duration_unit !== undefined) updateData.duration_unit = data.duration_unit;

    const { error: err } = await supabase
      .from('schedule_projects')
      .update(updateData)
      .eq('id', id);
    if (err) throw err;
  };

  const deleteProject = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('schedule_projects')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  return {
    projects,
    loading,
    error,
    createProject,
    updateProject,
    deleteProject,
    refetch: fetchProjects,
  };
}

export function useScheduleProject(id: string | undefined) {
  const [project, setProject] = useState<ScheduleProject | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) {
      setLoading(false);
      return;
    }

    let ignore = false;

    const fetchProject = async () => {
      try {
        setLoading(true);
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('schedule_projects')
          .select('*')
          .eq('id', id)
          .is('deleted_at', null)
          .single();

        if (ignore) return;
        if (err) throw err;
        setProject(data);
      } catch (e: unknown) {
        if (ignore) return;
        const msg = e instanceof Error ? e.message : 'Project not found';
        setError(msg);
      } finally {
        if (!ignore) setLoading(false);
      }
    };

    fetchProject();

    const supabase = getSupabase();
    const channel = supabase
      .channel(`schedule-project-${id}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'schedule_projects',
        filter: `id=eq.${id}`,
      }, () => {
        fetchProject();
      })
      .subscribe();

    return () => {
      ignore = true;
      supabase.removeChannel(channel);
    };
  }, [id]);

  return { project, loading, error };
}
