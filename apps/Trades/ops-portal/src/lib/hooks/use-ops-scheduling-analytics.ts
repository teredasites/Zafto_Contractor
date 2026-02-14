'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

interface SchedulingMetrics {
  total_projects: number;
  active_projects: number;
  on_time_pct: number;
  avg_delay_days: number;
  avg_resource_utilization: number;
  total_tasks: number;
  critical_tasks: number;
  overdue_milestones: number;
}

interface MonthlyHealth {
  month: string;
  on_time: number;
  delayed: number;
  completed: number;
}

interface TradeBottleneck {
  trade: string;
  delay_count: number;
  avg_delay_days: number;
}

interface SchedulingAnalytics {
  metrics: SchedulingMetrics;
  monthly_health: MonthlyHealth[];
  bottlenecks: TradeBottleneck[];
}

export function useOpsSchedulingAnalytics() {
  const [analytics, setAnalytics] = useState<SchedulingAnalytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAnalytics = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Fetch all projects (ops = super_admin, cross-company)
      const { data: projects } = await supabase
        .from('schedule_projects')
        .select('id, name, status, planned_start, planned_finish, company_id');

      const allProjects = projects || [];
      const activeProjects = allProjects.filter(p => p.status === 'active' || p.status === 'planning');
      const projectIds = allProjects.map(p => p.id);

      // Fetch all tasks across projects
      const { data: tasks } = await supabase
        .from('schedule_tasks')
        .select('id, project_id, name, task_type, planned_finish, early_finish, percent_complete, is_critical, total_float')
        .in('project_id', projectIds.length > 0 ? projectIds : ['_none_'])
        .is('deleted_at', null);

      const allTasks = tasks || [];
      const today = new Date().toISOString().slice(0, 10);

      // Metrics
      const criticalTasks = allTasks.filter(t => t.is_critical);
      const milestones = allTasks.filter(t => t.task_type === 'milestone');
      const overdueMilestones = milestones.filter(m => {
        const date = m.planned_finish || m.early_finish;
        return date && date < today && (m.percent_complete || 0) < 100;
      });

      // Determine on-time projects (estimated finish within baseline)
      // For simplicity: check if any critical task is past its planned finish
      let onTimeCount = 0;
      let totalDelay = 0;
      let projectsWithDelay = 0;

      for (const proj of allProjects) {
        const projTasks = allTasks.filter(t => t.project_id === proj.id);
        const overdueTasks = projTasks.filter(t => {
          const finish = t.planned_finish;
          return finish && finish < today && (t.percent_complete || 0) < 100;
        });

        if (overdueTasks.length === 0) {
          onTimeCount++;
        } else {
          // Calculate max delay
          const maxDelay = overdueTasks.reduce((max, t) => {
            const finish = new Date(t.planned_finish!);
            const diff = Math.round((Date.now() - finish.getTime()) / (1000 * 60 * 60 * 24));
            return diff > max ? diff : max;
          }, 0);
          totalDelay += maxDelay;
          projectsWithDelay++;
        }
      }

      // Resource utilization (simplified: assigned tasks / total tasks)
      const { data: assignments } = await supabase
        .from('schedule_task_resources')
        .select('id, task_id');

      const assignedTaskIds = new Set((assignments || []).map(a => a.task_id));
      const utilizationPct = allTasks.length > 0
        ? (assignedTaskIds.size / allTasks.length) * 100
        : 0;

      const metrics: SchedulingMetrics = {
        total_projects: allProjects.length,
        active_projects: activeProjects.length,
        on_time_pct: allProjects.length > 0 ? Math.round((onTimeCount / allProjects.length) * 100) : 0,
        avg_delay_days: projectsWithDelay > 0 ? Math.round(totalDelay / projectsWithDelay) : 0,
        avg_resource_utilization: Math.round(utilizationPct),
        total_tasks: allTasks.length,
        critical_tasks: criticalTasks.length,
        overdue_milestones: overdueMilestones.length,
      };

      // Monthly health (last 6 months)
      const monthlyHealth: MonthlyHealth[] = [];
      for (let i = 5; i >= 0; i--) {
        const d = new Date();
        d.setMonth(d.getMonth() - i);
        const monthStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
        const monthLabel = d.toLocaleDateString('en-US', { month: 'short', year: '2-digit' });

        const monthTasks = allTasks.filter(t => {
          const finish = t.planned_finish;
          return finish && finish.startsWith(monthStr);
        });

        const onTime = monthTasks.filter(t => (t.total_float || 0) >= 0 || (t.percent_complete || 0) >= 100).length;
        const delayed = monthTasks.filter(t => (t.total_float || 0) < 0 && (t.percent_complete || 0) < 100).length;
        const completed = monthTasks.filter(t => (t.percent_complete || 0) >= 100).length;

        monthlyHealth.push({ month: monthLabel, on_time: onTime, delayed, completed });
      }

      // Trade bottlenecks (from resources with trade field)
      const { data: resources } = await supabase
        .from('schedule_resources')
        .select('id, trade');

      const resourceTradeMap = new Map<string, string>();
      for (const r of (resources || [])) {
        if (r.trade) resourceTradeMap.set(r.id, r.trade);
      }

      const { data: taskResources } = await supabase
        .from('schedule_task_resources')
        .select('task_id, resource_id');

      const tradeDelays = new Map<string, { count: number; totalDelay: number }>();
      for (const tr of (taskResources || [])) {
        const trade = resourceTradeMap.get(tr.resource_id);
        if (!trade) continue;

        const task = allTasks.find(t => t.id === tr.task_id);
        if (!task || !task.planned_finish) continue;

        if (task.planned_finish < today && (task.percent_complete || 0) < 100) {
          const delay = Math.round((Date.now() - new Date(task.planned_finish).getTime()) / (1000 * 60 * 60 * 24));
          const existing = tradeDelays.get(trade) || { count: 0, totalDelay: 0 };
          existing.count++;
          existing.totalDelay += delay;
          tradeDelays.set(trade, existing);
        }
      }

      const bottlenecks: TradeBottleneck[] = [...tradeDelays.entries()]
        .map(([trade, data]) => ({
          trade,
          delay_count: data.count,
          avg_delay_days: Math.round(data.totalDelay / data.count),
        }))
        .sort((a, b) => b.delay_count - a.delay_count)
        .slice(0, 10);

      setAnalytics({ metrics, monthly_health: monthlyHealth, bottlenecks });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load analytics';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchAnalytics(); }, [fetchAnalytics]);

  return { analytics, loading, error, refetch: fetchAnalytics };
}
