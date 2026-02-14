'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

interface TeamProject {
  id: string;
  name: string;
  status: string;
  planned_start: string | null;
  planned_finish: string | null;
  total_tasks: number;
  my_tasks: number;
  my_completed: number;
  next_deadline: string | null;
  overall_progress: number;
}

interface TeamTask {
  id: string;
  name: string;
  task_type: string;
  planned_start: string | null;
  planned_finish: string | null;
  early_start: string | null;
  early_finish: string | null;
  percent_complete: number;
  is_critical: boolean;
  original_duration: number | null;
  total_float: number | null;
}

export function useTeamSchedule() {
  const [projects, setProjects] = useState<TeamProject[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchProjects = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // Get projects where user has assigned tasks (via schedule_task_resources)
      const { data: assignments } = await supabase
        .from('schedule_task_resources')
        .select('task_id, resource_id')
        .eq('company_id', user.app_metadata?.company_id);

      if (!assignments || assignments.length === 0) {
        setProjects([]);
        return;
      }

      const taskIds = [...new Set(assignments.map((a: { task_id: string }) => a.task_id))];

      // Get tasks and their projects
      const { data: tasks } = await supabase
        .from('schedule_tasks')
        .select('id, project_id, name, planned_finish, percent_complete, task_type')
        .in('id', taskIds)
        .is('deleted_at', null);

      if (!tasks) { setProjects([]); return; }

      // Group by project
      const projectMap = new Map<string, typeof tasks>();
      for (const task of tasks) {
        if (!projectMap.has(task.project_id)) projectMap.set(task.project_id, []);
        projectMap.get(task.project_id)!.push(task);
      }

      // Get project details
      const projectIds = [...projectMap.keys()];
      const { data: projectData } = await supabase
        .from('schedule_projects')
        .select('id, name, status, planned_start, planned_finish')
        .in('id', projectIds);

      if (!projectData) { setProjects([]); return; }

      // Get total task counts per project
      interface TaskCountRow { id: string; project_id: string; percent_complete: number }
      const { data: allTasksRaw } = await supabase
        .from('schedule_tasks')
        .select('id, project_id, percent_complete')
        .in('project_id', projectIds)
        .is('deleted_at', null);

      const allTasks = (allTasksRaw || []) as unknown as TaskCountRow[];

      const result: TeamProject[] = projectData.map((p: { id: string; name: string; status: string; planned_start: string | null; planned_finish: string | null }) => {
        const myTasks = projectMap.get(p.id) || [];
        const allProjectTasks = allTasks.filter((t: TaskCountRow) => t.project_id === p.id);
        const myCompleted = myTasks.filter((t: { percent_complete: number }) => t.percent_complete >= 100).length;
        const deadlines = myTasks
          .filter((t: { planned_finish: string | null; percent_complete: number }) => t.planned_finish && t.percent_complete < 100)
          .map((t: { planned_finish: string }) => t.planned_finish)
          .sort();
        const overallPct = allProjectTasks.length > 0
          ? allProjectTasks.reduce((s: number, t: TaskCountRow) => s + (t.percent_complete || 0), 0) / allProjectTasks.length
          : 0;

        return {
          id: p.id,
          name: p.name,
          status: p.status,
          planned_start: p.planned_start,
          planned_finish: p.planned_finish,
          total_tasks: allProjectTasks.length,
          my_tasks: myTasks.length,
          my_completed: myCompleted,
          next_deadline: deadlines[0] || null,
          overall_progress: Math.round(overallPct),
        };
      });

      setProjects(result);
    } catch (e) {
      console.error('Failed to load team schedule:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchProjects(); }, [fetchProjects]);

  return { projects, loading, refetch: fetchProjects };
}

export function useTeamProjectTasks(projectId: string | undefined) {
  const [tasks, setTasks] = useState<TeamTask[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchTasks = useCallback(async () => {
    if (!projectId) { setLoading(false); return; }

    try {
      setLoading(true);
      const supabase = getSupabase();

      const { data, error } = await supabase
        .from('schedule_tasks')
        .select('id, name, task_type, planned_start, planned_finish, early_start, early_finish, percent_complete, is_critical, original_duration, total_float')
        .eq('project_id', projectId)
        .is('deleted_at', null)
        .order('sort_order', { ascending: true });

      if (error) throw error;
      setTasks(data || []);
    } catch (e) {
      console.error('Failed to load tasks:', e);
    } finally {
      setLoading(false);
    }
  }, [projectId]);

  useEffect(() => { fetchTasks(); }, [fetchTasks]);

  const updateProgress = async (taskId: string, percent: number) => {
    const supabase = getSupabase();
    const { error } = await supabase
      .from('schedule_tasks')
      .update({ percent_complete: percent })
      .eq('id', taskId);
    if (error) throw error;
    await fetchTasks();
  };

  // Real-time subscription
  useEffect(() => {
    if (!projectId) return;
    const supabase = getSupabase();
    const channel = supabase
      .channel(`team-schedule-${projectId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'schedule_tasks',
        filter: `project_id=eq.${projectId}`,
      }, () => { fetchTasks(); })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [projectId, fetchTasks]);

  return { tasks, loading, updateProgress, refetch: fetchTasks };
}
