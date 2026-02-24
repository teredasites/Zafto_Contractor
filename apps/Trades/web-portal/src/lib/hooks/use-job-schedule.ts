'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ══════════════════════════════════════════════════════════════
// TYPES
// ══════════════════════════════════════════════════════════════

interface JobScheduleProject {
  id: string;
  name: string;
  status: string;
  planned_start: string | null;
  planned_finish: string | null;
  overall_percent_complete: number;
}

interface JobScheduleTask {
  id: string;
  name: string;
  task_type: string;
  planned_start: string | null;
  planned_finish: string | null;
  early_start: string | null;
  early_finish: string | null;
  percent_complete: number;
  is_critical: boolean;
}

// ══════════════════════════════════════════════════════════════
// HOOK
// ══════════════════════════════════════════════════════════════

export function useJobSchedule(jobId: string | undefined) {
  const [schedule, setSchedule] = useState<JobScheduleProject | null>(null);
  const [tasks, setTasks] = useState<JobScheduleTask[]>([]);
  const [loading, setLoading] = useState(true);

  const fetch = useCallback(async () => {
    if (!jobId) { setLoading(false); return; }

    try {
      setLoading(true);
      const supabase = getSupabase();

      // Find schedule project linked to this job
      const { data: project, error: projErr } = await supabase
        .from('schedule_projects')
        .select('id, name, status, planned_start, planned_finish, overall_percent_complete')
        .eq('job_id', jobId)
        .neq('status', 'archived')
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (projErr || !project) {
        setSchedule(null);
        setTasks([]);
        return;
      }

      setSchedule(project as JobScheduleProject);

      // Fetch tasks for the mini gantt
      const { data: taskData } = await supabase
        .from('schedule_tasks')
        .select('id, name, task_type, planned_start, planned_finish, early_start, early_finish, percent_complete, is_critical')
        .eq('project_id', project.id)
        .is('deleted_at', null)
        .order('sort_order', { ascending: true });

      setTasks((taskData || []) as JobScheduleTask[]);
    } catch {
      setSchedule(null);
      setTasks([]);
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => { fetch(); }, [fetch]);

  return { schedule, tasks, loading, refetch: fetch };
}
