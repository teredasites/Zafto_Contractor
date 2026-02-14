// ZAFTO Baseline Capture Engine
// GC6: Snapshots all current task data into schedule_baseline_tasks.
// Max 5 baselines per project. Returns baseline_id.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUser = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: authErr } = await supabaseUser.auth.getUser();
    if (authErr || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const companyId = user.app_metadata?.company_id;
    if (!companyId) {
      return new Response(JSON.stringify({ error: 'No company assigned' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { project_id, name, notes } = await req.json();

    if (!project_id) {
      return new Response(JSON.stringify({ error: 'Missing project_id' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!name || !name.trim()) {
      return new Response(JSON.stringify({ error: 'Missing baseline name' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // ── Verify project ownership ──
    const { data: project, error: projErr } = await supabaseAdmin
      .from('schedule_projects')
      .select('id, planned_start, planned_finish')
      .eq('id', project_id)
      .eq('company_id', companyId)
      .single();

    if (projErr || !project) {
      return new Response(JSON.stringify({ error: 'Project not found' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── Check baseline count (max 5) ──
    const { data: existingBaselines } = await supabaseAdmin
      .from('schedule_baselines')
      .select('id, baseline_number')
      .eq('project_id', project_id)
      .order('baseline_number', { ascending: true });

    const baselineCount = existingBaselines?.length ?? 0;

    if (baselineCount >= 5) {
      return new Response(JSON.stringify({
        error: 'Maximum 5 baselines per project. Delete an existing baseline first.',
      }), {
        status: 422, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const nextNumber = baselineCount > 0
      ? Math.max(...existingBaselines!.map(b => b.baseline_number)) + 1
      : 1;

    // ── Fetch all tasks for snapshot ──
    const { data: tasks, error: taskErr } = await supabaseAdmin
      .from('schedule_tasks')
      .select('*')
      .eq('project_id', project_id)
      .is('deleted_at', null)
      .order('sort_order', { ascending: true });

    if (taskErr || !tasks) {
      return new Response(JSON.stringify({ error: 'Failed to fetch tasks' }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── Deactivate previous active baselines ──
    await supabaseAdmin
      .from('schedule_baselines')
      .update({ is_active: false })
      .eq('project_id', project_id)
      .eq('is_active', true);

    // ── Create baseline record ──
    const milestoneCount = tasks.filter(t => t.task_type === 'milestone').length;
    const totalCost = tasks.reduce((sum: number, t: { budgeted_cost?: number }) => sum + (t.budgeted_cost ?? 0), 0);

    const { data: baseline, error: baseErr } = await supabaseAdmin
      .from('schedule_baselines')
      .insert({
        company_id: companyId,
        project_id,
        name: name.trim(),
        description: notes || null,
        baseline_number: nextNumber,
        captured_by: user.id,
        data_date: new Date().toISOString().slice(0, 10),
        planned_start: project.planned_start,
        planned_finish: project.planned_finish,
        total_tasks: tasks.length,
        total_milestones: milestoneCount,
        total_cost: totalCost,
        is_active: true,
      })
      .select('id')
      .single();

    if (baseErr || !baseline) {
      return new Response(JSON.stringify({ error: 'Failed to create baseline record' }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── Snapshot tasks into baseline_tasks ──
    if (tasks.length > 0) {
      const baselineTasks = tasks.map(t => ({
        company_id: companyId,
        baseline_id: baseline.id,
        task_id: t.id,
        name: t.name,
        wbs_code: t.wbs_code,
        task_type: t.task_type,
        original_duration: t.original_duration,
        planned_start: t.planned_start,
        planned_finish: t.planned_finish,
        early_start: t.early_start,
        early_finish: t.early_finish,
        late_start: t.late_start,
        late_finish: t.late_finish,
        total_float: t.total_float,
        free_float: t.free_float,
        is_critical: t.is_critical,
        budgeted_cost: t.budgeted_cost,
        percent_complete: t.percent_complete,
      }));

      // Insert in batches of 100
      for (let i = 0; i < baselineTasks.length; i += 100) {
        const batch = baselineTasks.slice(i, i + 100);
        const { error: insertErr } = await supabaseAdmin
          .from('schedule_baseline_tasks')
          .insert(batch);

        if (insertErr) {
          console.error('Baseline task insert error:', insertErr);
        }
      }
    }

    // ── Log baseline capture ──
    await supabaseAdmin.from('schedule_task_changes').insert({
      company_id: companyId,
      project_id,
      task_id: tasks.length > 0 ? tasks[0].id : project_id,
      change_type: 'updated',
      changed_by: user.id,
      source: 'manual',
      notes: `Baseline "${name.trim()}" captured (#${nextNumber}): ${tasks.length} tasks, $${totalCost.toFixed(2)} total cost`,
    });

    // ── Compute EVM metrics ──
    let bcws = 0; // Budgeted Cost of Work Scheduled
    let bcwp = 0; // Budgeted Cost of Work Performed
    let acwp = 0; // Actual Cost of Work Performed

    for (const t of tasks) {
      const cost = t.budgeted_cost ?? 0;
      const pct = (t.percent_complete ?? 0) / 100;
      bcws += cost; // Full budgeted cost
      bcwp += cost * pct; // Earned value
      acwp += t.actual_cost ?? 0;
    }

    const spi = bcws > 0 ? bcwp / bcws : 0; // Schedule Performance Index
    const cpi = acwp > 0 ? bcwp / acwp : 0; // Cost Performance Index

    return new Response(JSON.stringify({
      success: true,
      baseline_id: baseline.id,
      baseline_number: nextNumber,
      tasks_captured: tasks.length,
      evm: { bcws, bcwp, acwp, spi, cpi },
    }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err) {
    console.error('Baseline capture error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
