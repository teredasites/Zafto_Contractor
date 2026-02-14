// ZAFTO Schedule Progress Sync — Edge Function
// GC10: Syncs field activity into schedule task progress.
// Triggers: daily log submission, photo upload tagged to task, punch list resolution.
// Creates progress suggestions and auto-updates when confidence is high.

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

    // Auth
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

    const { data: { user }, error: authErr } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''));
    if (authErr || !user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

    const companyId = user.app_metadata?.company_id;
    if (!companyId) return new Response(JSON.stringify({ error: 'No company' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

    const body = await req.json();
    const { event_type, payload } = body;

    // ── Event: Daily Log Submission ──
    if (event_type === 'daily_log') {
      const { job_id, notes, tasks_worked } = payload;
      if (!job_id) return jsonResp({ error: 'job_id required' }, 400);

      // Find schedule project for this job
      const { data: project } = await supabase
        .from('schedule_projects')
        .select('id')
        .eq('job_id', job_id)
        .eq('company_id', companyId)
        .neq('status', 'archived')
        .limit(1)
        .maybeSingle();

      if (!project) return jsonResp({ message: 'No schedule linked to job', suggestions: [] });

      // Find tasks assigned to this user
      const { data: assignments } = await supabase
        .from('schedule_task_resources')
        .select('task_id')
        .eq('company_id', companyId);

      if (!assignments || assignments.length === 0) return jsonResp({ message: 'No assigned tasks', suggestions: [] });

      const taskIds = assignments.map((a: { task_id: string }) => a.task_id);

      const { data: tasks } = await supabase
        .from('schedule_tasks')
        .select('id, name, percent_complete, planned_start, planned_finish')
        .eq('project_id', project.id)
        .in('id', taskIds)
        .is('deleted_at', null)
        .lt('percent_complete', 100);

      if (!tasks || tasks.length === 0) return jsonResp({ message: 'All tasks complete', suggestions: [] });

      // Generate suggestions based on tasks_worked or notes
      interface Suggestion { task_id: string; task_name: string; current_percent: number; suggested_percent: number; reason: string }
      const suggestions: Suggestion[] = [];

      if (tasks_worked && Array.isArray(tasks_worked)) {
        for (const tw of tasks_worked) {
          const { task_id, percent_complete } = tw as { task_id: string; percent_complete: number };
          const task = tasks.find((t: { id: string }) => t.id === task_id);
          if (task && percent_complete > task.percent_complete) {
            suggestions.push({
              task_id: task.id,
              task_name: task.name,
              current_percent: task.percent_complete,
              suggested_percent: percent_complete,
              reason: 'Daily log progress update',
            });
          }
        }
      }

      // Auto-apply high-confidence suggestions (explicit task_id + percent)
      const applied: string[] = [];
      for (const s of suggestions) {
        await supabase
          .from('schedule_tasks')
          .update({
            percent_complete: s.suggested_percent,
            ...(s.suggested_percent > 0 && !tasks.find((t: { id: string }) => t.id === s.task_id)?.actual_start
              ? { actual_start: new Date().toISOString().slice(0, 10) }
              : {}),
            ...(s.suggested_percent >= 100
              ? { actual_finish: new Date().toISOString().slice(0, 10) }
              : {}),
          })
          .eq('id', s.task_id)
          .eq('company_id', companyId);
        applied.push(s.task_id);
      }

      // For remaining open tasks, suggest progress based on daily log existence
      for (const task of tasks) {
        if (applied.includes(task.id)) continue;
        // If task is in the current date range, suggest incremental progress
        const today = new Date().toISOString().slice(0, 10);
        if (task.planned_start && task.planned_finish && task.planned_start <= today && task.planned_finish >= today) {
          // Calculate expected progress based on date
          const start = new Date(task.planned_start).getTime();
          const finish = new Date(task.planned_finish).getTime();
          const now = Date.now();
          const expectedPct = Math.round(((now - start) / (finish - start)) * 100);
          if (expectedPct > task.percent_complete + 5) {
            suggestions.push({
              task_id: task.id,
              task_name: task.name,
              current_percent: task.percent_complete,
              suggested_percent: Math.min(expectedPct, 95),
              reason: 'Task in progress — daily log filed, consider updating',
            });
          }
        }
      }

      return jsonResp({ applied: applied.length, suggestions });
    }

    // ── Event: Photo Tagged to Task ──
    if (event_type === 'photo_tagged') {
      const { task_id, photo_url } = payload;
      if (!task_id) return jsonResp({ error: 'task_id required' }, 400);

      // Update task metadata with photo evidence
      const { data: task } = await supabase
        .from('schedule_tasks')
        .select('id, metadata, percent_complete')
        .eq('id', task_id)
        .eq('company_id', companyId)
        .single();

      if (!task) return jsonResp({ error: 'Task not found' }, 404);

      const metadata = (task.metadata as Record<string, unknown>) || {};
      const photos = (metadata.evidence_photos as string[]) || [];
      photos.push(photo_url);

      await supabase
        .from('schedule_tasks')
        .update({ metadata: { ...metadata, evidence_photos: photos } })
        .eq('id', task_id)
        .eq('company_id', companyId);

      // If task has no progress yet, suggest starting
      if (task.percent_complete === 0) {
        return jsonResp({
          message: 'Photo evidence attached',
          suggestion: { task_id, suggested_percent: 10, reason: 'Photo evidence suggests work started' },
        });
      }

      return jsonResp({ message: 'Photo evidence attached' });
    }

    // ── Event: Punch List Item Resolved ──
    if (event_type === 'punch_list_resolved') {
      const { task_id } = payload;
      if (!task_id) return jsonResp({ error: 'task_id required' }, 400);

      // Mark linked task step as complete — increment progress
      const { data: task } = await supabase
        .from('schedule_tasks')
        .select('id, percent_complete')
        .eq('id', task_id)
        .eq('company_id', companyId)
        .single();

      if (!task) return jsonResp({ error: 'Task not found' }, 404);

      // Nudge progress forward by 10% (punch list resolution = progress)
      const newPct = Math.min(task.percent_complete + 10, 100);

      await supabase
        .from('schedule_tasks')
        .update({
          percent_complete: newPct,
          ...(newPct >= 100 ? { actual_finish: new Date().toISOString().slice(0, 10) } : {}),
        })
        .eq('id', task_id)
        .eq('company_id', companyId);

      return jsonResp({ message: 'Progress updated', task_id, new_percent: newPct });
    }

    // ── Event: Job Status Change ──
    if (event_type === 'job_status_change') {
      const { job_id, new_status } = payload;
      if (!job_id || !new_status) return jsonResp({ error: 'job_id and new_status required' }, 400);

      // Find linked schedule project
      const { data: project } = await supabase
        .from('schedule_projects')
        .select('id')
        .eq('job_id', job_id)
        .eq('company_id', companyId)
        .neq('status', 'archived')
        .limit(1)
        .maybeSingle();

      if (!project) return jsonResp({ message: 'No linked schedule' });

      // Map job status to schedule status
      const statusMap: Record<string, string> = {
        scheduled: 'active',
        in_progress: 'active',
        on_hold: 'on_hold',
        completed: 'complete',
        cancelled: 'archived',
      };

      const scheduleStatus = statusMap[new_status];
      if (scheduleStatus) {
        await supabase
          .from('schedule_projects')
          .update({ status: scheduleStatus })
          .eq('id', project.id)
          .eq('company_id', companyId);
      }

      // If completed, set all incomplete tasks to 100%
      if (new_status === 'completed') {
        await supabase
          .from('schedule_tasks')
          .update({ percent_complete: 100, actual_finish: new Date().toISOString().slice(0, 10) })
          .eq('project_id', project.id)
          .lt('percent_complete', 100)
          .is('deleted_at', null);
      }

      return jsonResp({ message: 'Schedule synced', schedule_status: scheduleStatus });
    }

    return jsonResp({ error: 'Unknown event_type' }, 400);
  } catch (e) {
    console.error('schedule-sync-progress error:', e);
    return new Response(JSON.stringify({ error: 'Internal error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

function jsonResp(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      'Content-Type': 'application/json',
    },
  });
}
