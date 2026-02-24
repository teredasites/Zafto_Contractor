'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ══════════════════════════════════════════════════════════════
// TYPES
// ══════════════════════════════════════════════════════════════

interface PortfolioProject {
  id: string;
  name: string;
  status: string;
  planned_start: string | null;
  planned_finish: string | null;
  total_tasks: number;
  critical_tasks: number;
  milestones: number;
  completed_milestones: number;
  overall_progress: number;
  health: 'on_track' | 'at_risk' | 'behind';
  min_float: number;
}

interface PortfolioMilestone {
  id: string;
  name: string;
  project_id: string;
  project_name: string;
  planned_date: string | null;
  percent_complete: number;
  is_overdue: boolean;
}

interface CrossProjectConflict {
  resource_id: string;
  resource_name: string;
  projects: { project_id: string; project_name: string; task_name: string; start: string; finish: string }[];
  overlap_start: string;
  overlap_end: string;
}

interface ResourceUtilization {
  resource_id: string;
  resource_name: string;
  resource_type: string;
  project_count: number;
  total_assignments: number;
  is_over_allocated: boolean;
}

interface PortfolioData {
  projects: PortfolioProject[];
  milestones: PortfolioMilestone[];
  conflicts: CrossProjectConflict[];
  resource_utilization: ResourceUtilization[];
  summary: {
    total_projects: number;
    on_track: number;
    at_risk: number;
    behind: number;
    upcoming_milestones: number;
  };
}

// ══════════════════════════════════════════════════════════════
// HOOK
// ══════════════════════════════════════════════════════════════

export function useSchedulePortfolio() {
  const [portfolio, setPortfolio] = useState<PortfolioData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPortfolio = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Fetch all projects
      const { data: projects, error: projErr } = await supabase
        .from('schedule_projects')
        .select('id, name, status, planned_start, planned_finish')
        .neq('status', 'archived')
        .is('deleted_at', null)
        .order('name');

      if (projErr) throw projErr;
      if (!projects || projects.length === 0) {
        setPortfolio({
          projects: [], milestones: [], conflicts: [], resource_utilization: [],
          summary: { total_projects: 0, on_track: 0, at_risk: 0, behind: 0, upcoming_milestones: 0 },
        });
        return;
      }

      const projectIds = projects.map((p: { id: string }) => p.id);

      // Fetch all tasks
      interface TaskRow {
        id: string;
        project_id: string;
        name: string;
        task_type: string;
        planned_start: string | null;
        planned_finish: string | null;
        early_start: string | null;
        early_finish: string | null;
        percent_complete: number;
        is_critical: boolean;
        total_float: number | null;
      }

      const { data: tasksRaw } = await supabase
        .from('schedule_tasks')
        .select('id, project_id, name, task_type, planned_start, planned_finish, early_start, early_finish, percent_complete, is_critical, total_float')
        .in('project_id', projectIds)
        .is('deleted_at', null);

      const allTasks = (tasksRaw || []) as unknown as TaskRow[];
      const today = new Date().toISOString().slice(0, 10);
      const twoWeeks = new Date(Date.now() + 14 * 86400000).toISOString().slice(0, 10);

      // Build portfolio projects
      const portfolioProjects: PortfolioProject[] = projects.map((p: { id: string; name: string; status: string; planned_start: string | null; planned_finish: string | null }) => {
        const tasks = allTasks.filter(t => t.project_id === p.id);
        const criticalTasks = tasks.filter(t => t.is_critical);
        const milestones = tasks.filter(t => t.task_type === 'milestone');
        const completedMilestones = milestones.filter(m => m.percent_complete >= 100);
        const progress = tasks.length > 0
          ? tasks.reduce((s, t) => s + (t.percent_complete || 0), 0) / tasks.length
          : 0;

        const minFloat = criticalTasks.length > 0
          ? Math.min(...criticalTasks.map(t => t.total_float ?? 0))
          : 0;

        let health: 'on_track' | 'at_risk' | 'behind' = 'on_track';
        if (minFloat < -2) health = 'behind';
        else if (minFloat < 0) health = 'at_risk';

        // Check for overdue tasks
        const overdueTasks = tasks.filter(t => {
          const finish = t.early_finish || t.planned_finish;
          return finish && finish < today && t.percent_complete < 100;
        });
        if (overdueTasks.length > 0) health = 'behind';

        return {
          id: p.id,
          name: p.name,
          status: p.status,
          planned_start: p.planned_start,
          planned_finish: p.planned_finish,
          total_tasks: tasks.length,
          critical_tasks: criticalTasks.length,
          milestones: milestones.length,
          completed_milestones: completedMilestones.length,
          overall_progress: Math.round(progress),
          health,
          min_float: minFloat,
        };
      });

      // Build milestones (next 2 weeks)
      const milestones = allTasks.filter(t => t.task_type === 'milestone');
      const upcomingMilestones: PortfolioMilestone[] = milestones
        .filter(m => {
          const date = m.early_finish || m.planned_finish;
          return date && date <= twoWeeks && m.percent_complete < 100;
        })
        .map(m => {
          const proj = projects.find((p: { id: string }) => p.id === m.project_id);
          const date = m.early_finish || m.planned_finish;
          return {
            id: m.id,
            name: m.name,
            project_id: m.project_id,
            project_name: proj?.name || 'Unknown',
            planned_date: date,
            percent_complete: m.percent_complete,
            is_overdue: date ? date < today : false,
          };
        })
        .sort((a, b) => (a.planned_date || '').localeCompare(b.planned_date || ''));

      // Cross-project resource detection
      interface AssignRow { task_id: string; resource_id: string; units: number }
      interface ResourceRow { id: string; name: string; resource_type: string; max_units: number }

      const { data: assignmentsRaw } = await supabase
        .from('schedule_task_resources')
        .select('task_id, resource_id, units');

      const { data: resourcesRaw } = await supabase
        .from('schedule_resources')
        .select('id, name, resource_type, max_units')
        .is('deleted_at', null);

      const assignments = (assignmentsRaw || []) as unknown as AssignRow[];
      const resources = (resourcesRaw || []) as unknown as ResourceRow[];

      const resourceMap = new Map<string, ResourceRow>();
      for (const r of resources) resourceMap.set(r.id, r);

      const taskMap = new Map<string, TaskRow>();
      for (const t of allTasks) taskMap.set(t.id, t);

      // Group assignments by resource
      const resourceAssignments = new Map<string, { task: TaskRow; projectName: string }[]>();
      for (const a of assignments) {
        const task = taskMap.get(a.task_id);
        if (!task) continue;
        const proj = projects.find((p: { id: string }) => p.id === task.project_id);
        if (!proj) continue;

        if (!resourceAssignments.has(a.resource_id)) {
          resourceAssignments.set(a.resource_id, []);
        }
        resourceAssignments.get(a.resource_id)!.push({
          task,
          projectName: proj.name,
        });
      }

      // Detect conflicts (same resource, overlapping dates, different projects)
      const conflicts: CrossProjectConflict[] = [];
      for (const [resourceId, taskAssignments] of resourceAssignments) {
        // Group by project
        const projectGroups = new Map<string, typeof taskAssignments>();
        for (const ta of taskAssignments) {
          if (!projectGroups.has(ta.task.project_id)) {
            projectGroups.set(ta.task.project_id, []);
          }
          projectGroups.get(ta.task.project_id)!.push(ta);
        }

        if (projectGroups.size < 2) continue; // Only check cross-project

        // Check for date overlaps between projects
        const projectEntries = [...projectGroups.entries()];
        for (let i = 0; i < projectEntries.length; i++) {
          for (let j = i + 1; j < projectEntries.length; j++) {
            const [, tasks1] = projectEntries[i];
            const [, tasks2] = projectEntries[j];

            for (const t1 of tasks1) {
              for (const t2 of tasks2) {
                const s1 = t1.task.early_start || t1.task.planned_start;
                const f1 = t1.task.early_finish || t1.task.planned_finish;
                const s2 = t2.task.early_start || t2.task.planned_start;
                const f2 = t2.task.early_finish || t2.task.planned_finish;

                if (!s1 || !f1 || !s2 || !f2) continue;
                if (s1 <= f2 && s2 <= f1) {
                  const res = resourceMap.get(resourceId);
                  conflicts.push({
                    resource_id: resourceId,
                    resource_name: res?.name || 'Unknown',
                    projects: [
                      { project_id: t1.task.project_id, project_name: t1.projectName, task_name: t1.task.name, start: s1, finish: f1 },
                      { project_id: t2.task.project_id, project_name: t2.projectName, task_name: t2.task.name, start: s2, finish: f2 },
                    ],
                    overlap_start: s1 > s2 ? s1 : s2,
                    overlap_end: f1 < f2 ? f1 : f2,
                  });
                }
              }
            }
          }
        }
      }

      // Resource utilization
      const utilization: ResourceUtilization[] = [];
      for (const [resourceId, taskAssignments] of resourceAssignments) {
        const res = resourceMap.get(resourceId);
        if (!res) continue;
        const projectSet = new Set(taskAssignments.map(ta => ta.task.project_id));

        utilization.push({
          resource_id: resourceId,
          resource_name: res.name,
          resource_type: res.resource_type,
          project_count: projectSet.size,
          total_assignments: taskAssignments.length,
          is_over_allocated: projectSet.size > 1, // Simplified: multi-project = potential over-allocation
        });
      }

      // Summary
      const onTrack = portfolioProjects.filter(p => p.health === 'on_track').length;
      const atRisk = portfolioProjects.filter(p => p.health === 'at_risk').length;
      const behind = portfolioProjects.filter(p => p.health === 'behind').length;

      setPortfolio({
        projects: portfolioProjects,
        milestones: upcomingMilestones,
        conflicts,
        resource_utilization: utilization.sort((a, b) => b.total_assignments - a.total_assignments),
        summary: {
          total_projects: portfolioProjects.length,
          on_track: onTrack,
          at_risk: atRisk,
          behind,
          upcoming_milestones: upcomingMilestones.length,
        },
      });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load portfolio';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchPortfolio(); }, [fetchPortfolio]);

  return { portfolio, loading, error, refetch: fetchPortfolio };
}
