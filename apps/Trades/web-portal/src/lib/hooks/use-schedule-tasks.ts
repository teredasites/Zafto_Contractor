'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import type { ScheduleTask, ScheduleTaskType, ConstraintType } from '@/lib/types/scheduling';

export function useScheduleTasks(projectId: string | undefined) {
  const [tasks, setTasks] = useState<ScheduleTask[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTasks = useCallback(async () => {
    if (!projectId) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('schedule_tasks')
        .select('*')
        .eq('project_id', projectId)
        .is('deleted_at', null)
        .order('sort_order', { ascending: true });

      if (err) throw err;
      setTasks(data || []);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load tasks';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [projectId]);

  useEffect(() => {
    fetchTasks();

    if (!projectId) return;

    const supabase = getSupabase();
    const channel = supabase
      .channel(`schedule-tasks-${projectId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'schedule_tasks',
        filter: `project_id=eq.${projectId}`,
      }, () => {
        fetchTasks();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [projectId, fetchTasks]);

  const createTask = async (data: {
    name: string;
    task_type?: ScheduleTaskType;
    original_duration?: number;
    planned_start?: string;
    planned_finish?: string;
    parent_id?: string;
    constraint_type?: ConstraintType;
    constraint_date?: string;
    sort_order?: number;
    indent_level?: number;
    color?: string;
    notes?: string;
  }): Promise<string> => {
    if (!projectId) throw new Error('No project selected');

    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const maxSort = tasks.length > 0
      ? Math.max(...tasks.map(t => t.sort_order)) + 10
      : 10;

    const { data: result, error: err } = await supabase
      .from('schedule_tasks')
      .insert({
        company_id: companyId,
        project_id: projectId,
        name: data.name,
        task_type: data.task_type || 'task',
        original_duration: data.original_duration ?? 5,
        planned_start: data.planned_start || null,
        planned_finish: data.planned_finish || null,
        parent_id: data.parent_id || null,
        constraint_type: data.constraint_type || 'asap',
        constraint_date: data.constraint_date || null,
        sort_order: data.sort_order ?? maxSort,
        indent_level: data.indent_level ?? 0,
        color: data.color || null,
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateTask = async (id: string, data: Partial<ScheduleTask>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.name !== undefined) updateData.name = data.name;
    if (data.task_type !== undefined) updateData.task_type = data.task_type;
    if (data.original_duration !== undefined) updateData.original_duration = data.original_duration;
    if (data.remaining_duration !== undefined) updateData.remaining_duration = data.remaining_duration;
    if (data.percent_complete !== undefined) updateData.percent_complete = data.percent_complete;
    if (data.planned_start !== undefined) updateData.planned_start = data.planned_start;
    if (data.planned_finish !== undefined) updateData.planned_finish = data.planned_finish;
    if (data.actual_start !== undefined) updateData.actual_start = data.actual_start;
    if (data.actual_finish !== undefined) updateData.actual_finish = data.actual_finish;
    if (data.constraint_type !== undefined) updateData.constraint_type = data.constraint_type;
    if (data.constraint_date !== undefined) updateData.constraint_date = data.constraint_date;
    if (data.parent_id !== undefined) updateData.parent_id = data.parent_id;
    if (data.sort_order !== undefined) updateData.sort_order = data.sort_order;
    if (data.indent_level !== undefined) updateData.indent_level = data.indent_level;
    if (data.color !== undefined) updateData.color = data.color;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.assigned_to !== undefined) updateData.assigned_to = data.assigned_to;
    if (data.budgeted_cost !== undefined) updateData.budgeted_cost = data.budgeted_cost;
    if (data.actual_cost !== undefined) updateData.actual_cost = data.actual_cost;

    const { error: err } = await supabase
      .from('schedule_tasks')
      .update(updateData)
      .eq('id', id);
    if (err) throw err;
  };

  const deleteTask = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('schedule_tasks')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  const updateProgress = async (id: string, percentComplete: number) => {
    const supabase = getSupabase();
    const updates: Record<string, unknown> = { percent_complete: percentComplete };

    if (percentComplete > 0 && percentComplete < 100) {
      const today = new Date().toISOString().slice(0, 10);
      updates.actual_start = today;
    }
    if (percentComplete >= 100) {
      const today = new Date().toISOString().slice(0, 10);
      updates.actual_finish = today;
      updates.remaining_duration = 0;
    }

    const { error: err } = await supabase
      .from('schedule_tasks')
      .update(updates)
      .eq('id', id);
    if (err) throw err;
  };

  const triggerCpmRecalc = async () => {
    if (!projectId) return;
    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return;

    await fetch(
      `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/schedule-calculate-cpm`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({ project_id: projectId }),
      },
    );
  };

  return {
    tasks,
    loading,
    error,
    createTask,
    updateTask,
    deleteTask,
    updateProgress,
    triggerCpmRecalc,
    refetch: fetchTasks,
  };
}
