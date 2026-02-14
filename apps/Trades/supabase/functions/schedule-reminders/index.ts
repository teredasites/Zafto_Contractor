// ZAFTO Schedule Reminders — Edge Function (Cron)
// GC10: Daily cron job that creates notifications for upcoming schedule events.
// - 24h before task start
// - 48h before milestone
// - Coordination alerts when trades overlap
// - Delay notifications when critical tasks slip
// Designed to run daily via Supabase cron: `SELECT net.http_post(...)`

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const today = new Date();
    const todayStr = today.toISOString().slice(0, 10);
    const tomorrow = new Date(today.getTime() + 86400000);
    const tomorrowStr = tomorrow.toISOString().slice(0, 10);
    const twoDays = new Date(today.getTime() + 2 * 86400000);
    const twoDaysStr = twoDays.toISOString().slice(0, 10);

    let remindersCreated = 0;

    // ── 1. Task Start Reminders (24h before) ──
    interface TaskRow {
      id: string;
      name: string;
      project_id: string;
      company_id: string;
      task_type: string;
      planned_start: string | null;
      early_start: string | null;
      planned_finish: string | null;
      early_finish: string | null;
      percent_complete: number;
      is_critical: boolean;
      assigned_to: string | null;
    }

    const { data: upcomingTasks } = await supabase
      .from('schedule_tasks')
      .select('id, name, project_id, company_id, task_type, planned_start, early_start, planned_finish, early_finish, percent_complete, is_critical, assigned_to')
      .is('deleted_at', null)
      .lt('percent_complete', 100);

    const tasks = (upcomingTasks || []) as unknown as TaskRow[];

    // Group tasks by company for batch notification creation
    const companyAdminCache = new Map<string, string[]>();

    async function getAdminUsers(companyId: string): Promise<string[]> {
      if (companyAdminCache.has(companyId)) return companyAdminCache.get(companyId)!;
      const { data } = await supabase
        .from('users')
        .select('id')
        .eq('company_id', companyId)
        .in('role', ['owner', 'admin', 'office_manager']);
      const ids = (data || []).map((u: { id: string }) => u.id);
      companyAdminCache.set(companyId, ids);
      return ids;
    }

    // Get project names
    const projectIds = [...new Set(tasks.map(t => t.project_id))];
    const projectNameMap = new Map<string, string>();
    if (projectIds.length > 0) {
      const { data: projects } = await supabase
        .from('schedule_projects')
        .select('id, name')
        .in('id', projectIds);
      for (const p of (projects || []) as { id: string; name: string }[]) {
        projectNameMap.set(p.id, p.name);
      }
    }

    const notifications: {
      company_id: string;
      user_id: string;
      title: string;
      body: string;
      type: string;
      entity_type: string;
      entity_id: string;
    }[] = [];

    for (const task of tasks) {
      const startDate = task.early_start || task.planned_start;
      const finishDate = task.early_finish || task.planned_finish;
      const projectName = projectNameMap.get(task.project_id) || 'Unknown Project';

      // Task start reminder (24h before)
      if (startDate === tomorrowStr && task.percent_complete === 0) {
        const targetUsers = task.assigned_to
          ? [task.assigned_to]
          : await getAdminUsers(task.company_id);

        for (const userId of targetUsers) {
          notifications.push({
            company_id: task.company_id,
            user_id: userId,
            title: `Task starting tomorrow: ${task.name}`,
            body: `[${projectName}] "${task.name}" is scheduled to start tomorrow.${task.is_critical ? ' (Critical Path)' : ''}`,
            type: 'system',
            entity_type: 'schedule_task',
            entity_id: task.id,
          });
        }
      }

      // Milestone reminder (48h before)
      if (task.task_type === 'milestone' && finishDate === twoDaysStr && task.percent_complete < 100) {
        const adminUsers = await getAdminUsers(task.company_id);
        for (const userId of adminUsers) {
          notifications.push({
            company_id: task.company_id,
            user_id: userId,
            title: `Milestone in 2 days: ${task.name}`,
            body: `[${projectName}] Milestone "${task.name}" is due in 2 days.`,
            type: 'system',
            entity_type: 'schedule_task',
            entity_id: task.id,
          });
        }
      }

      // Delay notification (critical task overdue)
      if (task.is_critical && finishDate && finishDate < todayStr && task.percent_complete < 100) {
        const daysLate = Math.round((today.getTime() - new Date(finishDate).getTime()) / 86400000);
        // Only alert if 1 day late (avoid repeated spam — real system would check notification_sent flag)
        if (daysLate === 1) {
          const adminUsers = await getAdminUsers(task.company_id);
          for (const userId of adminUsers) {
            notifications.push({
              company_id: task.company_id,
              user_id: userId,
              title: `Critical task delayed: ${task.name}`,
              body: `[${projectName}] Critical path task "${task.name}" is ${daysLate} day(s) overdue. This may affect the project finish date.`,
              type: 'system',
              entity_type: 'schedule_task',
              entity_id: task.id,
            });
          }
        }
      }
    }

    // ── 2. Trade Overlap / Coordination Alerts ──
    // Group by project, find overlapping tasks with different assigned_to
    const projectTasks = new Map<string, TaskRow[]>();
    for (const t of tasks) {
      if (!t.assigned_to || !t.planned_start || !t.planned_finish) continue;
      if (!projectTasks.has(t.project_id)) projectTasks.set(t.project_id, []);
      projectTasks.get(t.project_id)!.push(t);
    }

    for (const [projectId, pTasks] of projectTasks) {
      // Find tasks starting tomorrow that overlap with other active tasks
      const startingTomorrow = pTasks.filter(t => (t.early_start || t.planned_start) === tomorrowStr);

      for (const newTask of startingTomorrow) {
        const newStart = newTask.early_start || newTask.planned_start!;
        const newFinish = newTask.early_finish || newTask.planned_finish!;

        // Find other tasks active during this period
        const overlapping = pTasks.filter(t => {
          if (t.id === newTask.id) return false;
          if (t.assigned_to === newTask.assigned_to) return false;
          const tStart = t.early_start || t.planned_start!;
          const tFinish = t.early_finish || t.planned_finish!;
          return tStart <= newFinish && tFinish >= newStart;
        });

        if (overlapping.length > 0) {
          const projectName = projectNameMap.get(projectId) || 'Unknown';
          const tradeNames = [...new Set(overlapping.map(t => t.name))].slice(0, 3).join(', ');
          const adminUsers = await getAdminUsers(newTask.company_id);

          for (const userId of adminUsers) {
            notifications.push({
              company_id: newTask.company_id,
              user_id: userId,
              title: `Trade coordination needed`,
              body: `[${projectName}] "${newTask.name}" starts tomorrow and overlaps with: ${tradeNames}. Consider scheduling a coordination meeting.`,
              type: 'system',
              entity_type: 'schedule_project',
              entity_id: projectId,
            });
          }
        }
      }
    }

    // ── Batch insert notifications ──
    if (notifications.length > 0) {
      // Deduplicate by user_id + entity_id (prevent duplicate notifications)
      const seen = new Set<string>();
      const unique = notifications.filter(n => {
        const key = `${n.user_id}:${n.entity_id}:${n.title}`;
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      });

      // Insert in batches of 100
      for (let i = 0; i < unique.length; i += 100) {
        const batch = unique.slice(i, i + 100);
        const { error } = await supabase.from('notifications').insert(batch);
        if (error) console.error('Failed to insert notification batch:', error.message);
        else remindersCreated += batch.length;
      }
    }

    return new Response(
      JSON.stringify({ success: true, reminders_created: remindersCreated }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    console.error('schedule-reminders error:', e);
    return new Response(
      JSON.stringify({ error: 'Internal error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
