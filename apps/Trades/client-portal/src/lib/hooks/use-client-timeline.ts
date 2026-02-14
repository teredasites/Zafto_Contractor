'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

interface MilestoneItem {
  id: string;
  name: string;
  planned_date: string | null;
  percent_complete: number;
  status: 'completed' | 'upcoming' | 'overdue';
}

interface TimelineData {
  project_name: string;
  overall_progress: number;
  planned_start: string | null;
  planned_finish: string | null;
  schedule_status: 'on_schedule' | 'ahead' | 'behind';
  delay_days: number;
  current_phase: string | null;
  milestones: MilestoneItem[];
}

export function useClientTimeline(projectId: string | undefined) {
  const [timeline, setTimeline] = useState<TimelineData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTimeline = useCallback(async () => {
    if (!projectId) { setLoading(false); return; }

    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Get project details
      const { data: project, error: projErr } = await supabase
        .from('schedule_projects')
        .select('id, name, status, planned_start, planned_finish')
        .eq('id', projectId)
        .single();

      if (projErr) throw projErr;
      if (!project) throw new Error('Project not found');

      // Get all tasks
      const { data: tasks } = await supabase
        .from('schedule_tasks')
        .select('id, name, task_type, planned_start, planned_finish, early_finish, percent_complete, is_critical')
        .eq('project_id', projectId)
        .is('deleted_at', null)
        .order('sort_order', { ascending: true });

      interface TaskRow {
        id: string;
        name: string;
        task_type: string;
        planned_start: string | null;
        planned_finish: string | null;
        early_finish: string | null;
        percent_complete: number;
        is_critical: boolean;
      }

      const allTasks = (tasks || []) as unknown as TaskRow[];
      const milestones = allTasks.filter((t: TaskRow) => t.task_type === 'milestone');
      const today = new Date().toISOString().slice(0, 10);

      // Overall progress
      const overallPct = allTasks.length > 0
        ? allTasks.reduce((s, t) => s + (t.percent_complete || 0), 0) / allTasks.length
        : 0;

      // Schedule status
      let scheduleStatus: 'on_schedule' | 'ahead' | 'behind' = 'on_schedule';
      let delayDays = 0;

      if (project.planned_finish) {
        // Check active baseline for variance
        const { data: baseline } = await supabase
          .from('schedule_baselines')
          .select('planned_finish')
          .eq('project_id', projectId)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

        if (baseline?.planned_finish) {
          // Find current projected finish
          const criticalTasks = allTasks.filter(t => t.is_critical);
          const latestFinish = criticalTasks.reduce((latest, t) => {
            const finish = t.early_finish || t.planned_finish;
            if (!finish) return latest;
            return finish > latest ? finish : latest;
          }, '');

          if (latestFinish) {
            const baselineFinish = new Date(baseline.planned_finish);
            const currentFinish = new Date(latestFinish);
            delayDays = Math.round((currentFinish.getTime() - baselineFinish.getTime()) / (1000 * 60 * 60 * 24));

            if (delayDays > 1) scheduleStatus = 'behind';
            else if (delayDays < -1) scheduleStatus = 'ahead';
          }
        }
      }

      // Current phase (first incomplete milestone or in-progress summary task)
      const inProgressTasks = allTasks.filter(t =>
        t.percent_complete > 0 && t.percent_complete < 100 && t.task_type === 'milestone'
      );
      const currentPhase = inProgressTasks.length > 0
        ? inProgressTasks[0].name
        : milestones.find(m => m.percent_complete < 100)?.name || null;

      // Build milestone items
      const milestoneItems: MilestoneItem[] = milestones.map(m => {
        const plannedDate = m.planned_finish || m.planned_start;
        let status: 'completed' | 'upcoming' | 'overdue' = 'upcoming';
        if (m.percent_complete >= 100) {
          status = 'completed';
        } else if (plannedDate && plannedDate < today) {
          status = 'overdue';
        }

        return {
          id: m.id,
          name: m.name,
          planned_date: plannedDate,
          percent_complete: m.percent_complete || 0,
          status,
        };
      });

      setTimeline({
        project_name: project.name,
        overall_progress: Math.round(overallPct),
        planned_start: project.planned_start,
        planned_finish: project.planned_finish,
        schedule_status: scheduleStatus,
        delay_days: delayDays,
        current_phase: currentPhase,
        milestones: milestoneItems,
      });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load timeline';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [projectId]);

  useEffect(() => { fetchTimeline(); }, [fetchTimeline]);

  return { timeline, loading, error, refetch: fetchTimeline };
}
