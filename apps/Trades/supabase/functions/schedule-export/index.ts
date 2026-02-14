// ZAFTO Schedule Export Engine
// GC7: Exports schedule data to P6 XER, MS Project XML, CSV, and PDF formats.
// Fetches full schedule, generates format-specific output,
// uploads to Storage (temp, 24hr expiry), returns signed URL.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ══════════════════════════════════════════════════════════════
// MAIN HANDLER
// ══════════════════════════════════════════════════════════════

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return jsonError('Missing authorization', 401);

    const supabaseUser = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: authErr } = await supabaseUser.auth.getUser();
    if (authErr || !user) return jsonError('Unauthorized', 401);

    const companyId = user.app_metadata?.company_id;
    if (!companyId) return jsonError('No company assigned', 400);

    const { project_id, format, options } = await req.json();

    if (!project_id) return jsonError('Missing project_id', 400);
    if (!format || !['xer', 'msp_xml', 'csv', 'pdf'].includes(format)) {
      return jsonError('Invalid format. Must be: xer, msp_xml, csv, pdf', 400);
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Verify project ownership + fetch project data
    const { data: project, error: projErr } = await supabaseAdmin
      .from('schedule_projects')
      .select('*')
      .eq('id', project_id)
      .eq('company_id', companyId)
      .single();

    if (projErr || !project) return jsonError('Project not found', 404);

    // Fetch all schedule data
    const [tasksRes, depsRes, resourcesRes, assignmentsRes, calendarsRes] = await Promise.all([
      supabaseAdmin.from('schedule_tasks').select('*')
        .eq('project_id', project_id).is('deleted_at', null)
        .order('sort_order', { ascending: true }),
      supabaseAdmin.from('schedule_dependencies').select('*')
        .eq('project_id', project_id),
      supabaseAdmin.from('schedule_resources').select('*')
        .eq('company_id', companyId),
      supabaseAdmin.from('schedule_task_resources').select('*')
        .eq('company_id', companyId),
      supabaseAdmin.from('schedule_calendars').select('*')
        .eq('project_id', project_id),
    ]);

    const tasks = tasksRes.data || [];
    const deps = depsRes.data || [];
    const resources = resourcesRes.data || [];
    const assignments = assignmentsRes.data || [];
    const calendars = calendarsRes.data || [];

    // Generate export content
    let content: string;
    let filename: string;
    let contentType: string;

    switch (format) {
      case 'xer':
        content = generateXER(project, tasks, deps, resources, assignments, calendars);
        filename = `${sanitizeFilename(project.name)}_export.xer`;
        contentType = 'text/plain';
        break;
      case 'msp_xml':
        content = generateMSProjectXML(project, tasks, deps, resources, assignments);
        filename = `${sanitizeFilename(project.name)}_export.xml`;
        contentType = 'application/xml';
        break;
      case 'csv':
        content = generateCSV(tasks, deps, resources, assignments);
        filename = `${sanitizeFilename(project.name)}_export.csv`;
        contentType = 'text/csv';
        break;
      case 'pdf':
        content = generatePDFContent(project, tasks, deps, options);
        filename = `${sanitizeFilename(project.name)}_export.pdf`;
        contentType = 'application/pdf';
        break;
      default:
        return jsonError('Unsupported format', 400);
    }

    // Upload to storage
    const storagePath = `exports/${companyId}/${project_id}/${filename}`;
    const blob = format === 'pdf'
      ? new Blob([content], { type: contentType })
      : new Blob([content], { type: contentType });

    const { error: uploadErr } = await supabaseAdmin.storage
      .from('documents')
      .upload(storagePath, blob, {
        contentType,
        upsert: true,
      });

    if (uploadErr) {
      return jsonError(`Upload failed: ${uploadErr.message}`, 500);
    }

    // Generate signed URL (24hr expiry)
    const { data: signedData, error: signErr } = await supabaseAdmin.storage
      .from('documents')
      .createSignedUrl(storagePath, 86400);

    if (signErr || !signedData) {
      return jsonError('Failed to generate download URL', 500);
    }

    // Log export
    await supabaseAdmin.from('schedule_task_changes').insert({
      company_id: companyId,
      project_id,
      task_id: project_id,
      change_type: 'updated',
      changed_by: user.id,
      source: 'export',
      notes: `Exported ${format.toUpperCase()}: ${tasks.length} tasks, ${deps.length} deps`,
    });

    return new Response(JSON.stringify({
      success: true,
      download_url: signedData.signedUrl,
      filename,
      format,
      tasks_exported: tasks.length,
      dependencies_exported: deps.length,
      resources_exported: resources.length,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err) {
    console.error('Schedule export error:', err);
    return jsonError('Internal server error', 500);
  }
});

// ══════════════════════════════════════════════════════════════
// P6 XER GENERATOR
// ══════════════════════════════════════════════════════════════

interface ScheduleData {
  id: string;
  name: string;
  [key: string]: unknown;
}

function generateXER(
  project: ScheduleData,
  tasks: ScheduleData[],
  deps: ScheduleData[],
  resources: ScheduleData[],
  assignments: ScheduleData[],
  calendars: ScheduleData[],
): string {
  const lines: string[] = [];
  lines.push('ERMHDR\t3.0\t2024-01-01\tZAFTO Export');
  lines.push('');

  // PROJECT table
  lines.push('%T\tPROJECT');
  lines.push('%F\tproj_id\tproj_short_name\twbs_max_sum_level\tlast_recalc_date');
  lines.push(`%R\t${project.id}\t${project.name}\t10\t${todayStr()}`);
  lines.push('');

  // CALENDAR table
  lines.push('%T\tCALENDAR');
  lines.push('%F\tclndr_id\tclndr_name\tdefault_flag\tday_hr_cnt');
  if (calendars.length > 0) {
    for (const cal of calendars) {
      lines.push(`%R\t${cal.id}\t${cal.name}\tN\t8`);
    }
  } else {
    lines.push(`%R\tdefault_cal\tStandard\tY\t8`);
  }
  lines.push('');

  // TASK table
  lines.push('%T\tTASK');
  lines.push('%F\ttask_id\ttask_code\ttask_name\ttask_type\twbs_id\ttarget_drtn_hr_cnt\ttarget_start_date\ttarget_end_date\tphys_complete_pct\tcstr_type\tcstr_date\ttotal_float_hr_cnt');
  for (const task of tasks) {
    const durationHrs = ((task.original_duration as number) || 0) * 8;
    const taskType = mapToP6TaskType(task.task_type as string);
    const cstr = mapToP6Constraint(task.constraint_type as string);
    lines.push(`%R\t${task.id}\t${task.wbs_code || ''}\t${task.name}\t${taskType}\t${task.wbs_code || ''}\t${durationHrs}\t${task.planned_start || ''}\t${task.planned_finish || ''}\t${task.percent_complete || 0}\t${cstr}\t${task.constraint_date || ''}\t${((task.total_float as number) || 0) * 8}`);
  }
  lines.push('');

  // TASKPRED table
  lines.push('%T\tTASKPRED');
  lines.push('%F\ttask_pred_id\ttask_id\tpred_task_id\tpred_type\tlag_hr_cnt');
  for (const dep of deps) {
    const predType = mapToP6DepType(dep.dependency_type as string);
    const lagHrs = ((dep.lag_days as number) || 0) * 8;
    lines.push(`%R\t${dep.id}\t${dep.successor_id}\t${dep.predecessor_id}\t${predType}\t${lagHrs}`);
  }
  lines.push('');

  // RSRC table
  lines.push('%T\tRSRC');
  lines.push('%F\trsrc_id\trsrc_name\trsrc_type\tmax_qty');
  for (const res of resources) {
    const resType = mapToP6ResType(res.resource_type as string);
    lines.push(`%R\t${res.id}\t${res.name}\t${resType}\t${res.max_units || 1}`);
  }
  lines.push('');

  // TASKRSRC table
  lines.push('%T\tTASKRSRC');
  lines.push('%F\ttaskrsrc_id\ttask_id\trsrc_id\ttarget_qty');
  for (const assign of assignments) {
    lines.push(`%R\t${assign.id}\t${assign.task_id}\t${assign.resource_id}\t${assign.units || 1}`);
  }
  lines.push('');

  lines.push('%E');
  return lines.join('\n');
}

function mapToP6TaskType(type: string): string {
  const map: Record<string, string> = {
    task: 'TT_Task', milestone: 'TT_Mile', summary: 'TT_WBS', loe: 'TT_LOE',
  };
  return map[type] || 'TT_Task';
}

function mapToP6Constraint(type: string): string {
  const map: Record<string, string> = {
    ASAP: 'CS_ASAP', ALAP: 'CS_ALAP', SNET: 'CS_SNET', SNLT: 'CS_SNLT',
    FNET: 'CS_FNET', FNLT: 'CS_FNLT', MSO: 'CS_MSO', MFO: 'CS_MFO',
  };
  return map[type] || 'CS_ASAP';
}

function mapToP6DepType(type: string): string {
  const map: Record<string, string> = {
    FS: 'PR_FS', FF: 'PR_FF', SS: 'PR_SS', SF: 'PR_SF',
  };
  return map[type] || 'PR_FS';
}

function mapToP6ResType(type: string): string {
  const map: Record<string, string> = {
    labor: 'RT_Labor', equipment: 'RT_Equip', material: 'RT_Mat',
  };
  return map[type] || 'RT_Labor';
}

// ══════════════════════════════════════════════════════════════
// MS PROJECT XML GENERATOR
// ══════════════════════════════════════════════════════════════

function generateMSProjectXML(
  project: ScheduleData,
  tasks: ScheduleData[],
  deps: ScheduleData[],
  resources: ScheduleData[],
  assignments: ScheduleData[],
): string {
  // Build UID maps (MSP uses sequential UIDs)
  const taskUIDMap = new Map<string, number>();
  const resUIDMap = new Map<string, number>();

  tasks.forEach((t, i) => taskUIDMap.set(t.id, i + 1));
  resources.forEach((r, i) => resUIDMap.set(r.id, i + 1));

  // Build dependency lookup per task
  const depsBySuccessor = new Map<string, ScheduleData[]>();
  for (const dep of deps) {
    const succId = dep.successor_id as string;
    if (!depsBySuccessor.has(succId)) depsBySuccessor.set(succId, []);
    depsBySuccessor.get(succId)!.push(dep);
  }

  const xml: string[] = [];
  xml.push('<?xml version="1.0" encoding="UTF-8"?>');
  xml.push('<Project xmlns="http://schemas.microsoft.com/project">');
  xml.push(`  <Name>${escXML(project.name as string)}</Name>`);
  xml.push(`  <StartDate>${project.planned_start || todayStr()}</StartDate>`);
  xml.push(`  <FinishDate>${project.planned_finish || todayStr()}</FinishDate>`);
  xml.push(`  <CreationDate>${new Date().toISOString()}</CreationDate>`);

  // Tasks
  xml.push('  <Tasks>');
  // Summary task 0
  xml.push('    <Task>');
  xml.push('      <UID>0</UID>');
  xml.push(`      <Name>${escXML(project.name as string)}</Name>`);
  xml.push('      <Summary>1</Summary>');
  xml.push('    </Task>');

  for (const task of tasks) {
    const uid = taskUIDMap.get(task.id)!;
    const isMilestone = task.task_type === 'milestone';
    const isSummary = task.task_type === 'summary';
    const durationMins = ((task.original_duration as number) || 0) * 8 * 60;

    xml.push('    <Task>');
    xml.push(`      <UID>${uid}</UID>`);
    xml.push(`      <Name>${escXML(task.name as string)}</Name>`);
    xml.push(`      <WBS>${escXML((task.wbs_code as string) || '')}</WBS>`);
    xml.push(`      <Start>${task.planned_start || ''}T08:00:00</Start>`);
    xml.push(`      <Finish>${task.planned_finish || ''}T17:00:00</Finish>`);
    xml.push(`      <Duration>PT${durationMins}M0S</Duration>`);
    xml.push(`      <PercentComplete>${task.percent_complete || 0}</PercentComplete>`);
    xml.push(`      <Milestone>${isMilestone ? '1' : '0'}</Milestone>`);
    xml.push(`      <Summary>${isSummary ? '1' : '0'}</Summary>`);

    if (task.constraint_type && task.constraint_type !== 'ASAP') {
      const cType = mapToMSPConstraint(task.constraint_type as string);
      xml.push(`      <ConstraintType>${cType}</ConstraintType>`);
      if (task.constraint_date) {
        xml.push(`      <ConstraintDate>${task.constraint_date}T08:00:00</ConstraintDate>`);
      }
    }

    if (task.budgeted_cost) {
      xml.push(`      <Cost>${task.budgeted_cost}</Cost>`);
    }

    // Predecessors
    const taskDeps = depsBySuccessor.get(task.id) || [];
    for (const dep of taskDeps) {
      const predUID = taskUIDMap.get(dep.predecessor_id as string);
      if (!predUID) continue;

      const depTypeMap: Record<string, string> = { FS: '1', FF: '0', SS: '3', SF: '2' };
      const lagTenths = ((dep.lag_days as number) || 0) * 4800;

      xml.push('      <PredecessorLink>');
      xml.push(`        <PredecessorUID>${predUID}</PredecessorUID>`);
      xml.push(`        <Type>${depTypeMap[(dep.dependency_type as string)] || '1'}</Type>`);
      xml.push(`        <LinkLag>${Math.round(lagTenths)}</LinkLag>`);
      xml.push('      </PredecessorLink>');
    }

    xml.push('    </Task>');
  }
  xml.push('  </Tasks>');

  // Resources
  xml.push('  <Resources>');
  for (const res of resources) {
    const uid = resUIDMap.get(res.id)!;
    const resTypeMap: Record<string, string> = { labor: '1', material: '0', equipment: '2' };

    xml.push('    <Resource>');
    xml.push(`      <UID>${uid}</UID>`);
    xml.push(`      <Name>${escXML(res.name as string)}</Name>`);
    xml.push(`      <Type>${resTypeMap[(res.resource_type as string)] || '1'}</Type>`);
    xml.push(`      <MaxUnits>${res.max_units || 1}</MaxUnits>`);
    if (res.cost_per_hour) {
      xml.push(`      <StandardRate>${res.cost_per_hour}</StandardRate>`);
    }
    xml.push('    </Resource>');
  }
  xml.push('  </Resources>');

  // Assignments
  xml.push('  <Assignments>');
  let assignUID = 1;
  for (const assign of assignments) {
    const taskUID = taskUIDMap.get(assign.task_id as string);
    const resUID = resUIDMap.get(assign.resource_id as string);
    if (!taskUID || !resUID) continue;

    xml.push('    <Assignment>');
    xml.push(`      <UID>${assignUID++}</UID>`);
    xml.push(`      <TaskUID>${taskUID}</TaskUID>`);
    xml.push(`      <ResourceUID>${resUID}</ResourceUID>`);
    xml.push(`      <Units>${assign.units || 1}</Units>`);
    xml.push('    </Assignment>');
  }
  xml.push('  </Assignments>');

  xml.push('</Project>');
  return xml.join('\n');
}

function mapToMSPConstraint(type: string): string {
  const map: Record<string, string> = {
    ASAP: '0', ALAP: '1', MSO: '2', MFO: '3',
    SNET: '4', SNLT: '5', FNET: '6', FNLT: '7',
  };
  return map[type] || '0';
}

function escXML(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// ══════════════════════════════════════════════════════════════
// CSV GENERATOR
// ══════════════════════════════════════════════════════════════

function generateCSV(
  tasks: ScheduleData[],
  deps: ScheduleData[],
  resources: ScheduleData[],
  assignments: ScheduleData[],
): string {
  // Build predecessor strings per task
  const predMap = new Map<string, string[]>();
  // Map task ID → sort_order for predecessor references
  const taskOrderMap = new Map<string, number>();
  tasks.forEach((t, i) => taskOrderMap.set(t.id, i + 1));

  for (const dep of deps) {
    const succId = dep.successor_id as string;
    const predOrder = taskOrderMap.get(dep.predecessor_id as string);
    if (!predOrder) continue;

    const depType = dep.dependency_type as string || 'FS';
    const lag = dep.lag_days as number || 0;
    let predStr = String(predOrder);
    if (depType !== 'FS') predStr += depType;
    if (lag !== 0) predStr += (lag > 0 ? '+' : '') + lag;

    if (!predMap.has(succId)) predMap.set(succId, []);
    predMap.get(succId)!.push(predStr);
  }

  // Build resource assignment strings per task
  const resNameMap = new Map<string, string>();
  for (const res of resources) {
    resNameMap.set(res.id, res.name as string);
  }

  const taskResMap = new Map<string, string[]>();
  for (const assign of assignments) {
    const taskId = assign.task_id as string;
    const resName = resNameMap.get(assign.resource_id as string);
    if (!resName) continue;
    if (!taskResMap.has(taskId)) taskResMap.set(taskId, []);
    taskResMap.get(taskId)!.push(resName);
  }

  const headers = [
    'ID', 'Name', 'WBS', 'Type', 'Duration (days)', 'Start', 'Finish',
    'Predecessors', 'Resources', '% Complete', 'Total Float (days)',
    'Critical', 'Budgeted Cost',
  ];

  const rows = [headers.join(',')];

  tasks.forEach((task, i) => {
    const preds = predMap.get(task.id)?.join(';') || '';
    const res = taskResMap.get(task.id)?.join(';') || '';

    const values = [
      i + 1,
      csvQuote(task.name as string),
      csvQuote((task.wbs_code as string) || ''),
      task.task_type || 'task',
      task.original_duration || '',
      task.planned_start || '',
      task.planned_finish || '',
      csvQuote(preds),
      csvQuote(res),
      task.percent_complete || 0,
      task.total_float || '',
      task.is_critical ? 'Yes' : 'No',
      task.budgeted_cost || '',
    ];

    rows.push(values.join(','));
  });

  return rows.join('\n');
}

function csvQuote(s: string): string {
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return '"' + s.replace(/"/g, '""') + '"';
  }
  return s;
}

// ══════════════════════════════════════════════════════════════
// PDF GENERATOR (text-based schedule report)
// ══════════════════════════════════════════════════════════════

function generatePDFContent(
  project: ScheduleData,
  tasks: ScheduleData[],
  deps: ScheduleData[],
  _options?: Record<string, unknown>,
): string {
  // Generate a structured text report that the client can render/print
  // For a true PDF we would need pdf-lib, but that adds ~200KB to the bundle.
  // Instead, we generate a rich HTML report that the client converts to PDF
  // via browser print/save-as-PDF (universal, zero server cost).

  const criticalTasks = tasks.filter(t => t.is_critical);
  const milestones = tasks.filter(t => t.task_type === 'milestone');
  const totalCost = tasks.reduce((s: number, t) => s + ((t.budgeted_cost as number) || 0), 0);
  const avgProgress = tasks.length > 0
    ? tasks.reduce((s: number, t) => s + ((t.percent_complete as number) || 0), 0) / tasks.length
    : 0;

  const html = `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>${escXML(project.name as string)} — Schedule Report</title>
<style>
  body { font-family: 'Inter', -apple-system, sans-serif; color: #1a1a1a; max-width: 1100px; margin: 0 auto; padding: 40px 20px; font-size: 12px; }
  h1 { font-size: 22px; margin-bottom: 4px; }
  h2 { font-size: 16px; margin-top: 24px; border-bottom: 2px solid #e5e5e5; padding-bottom: 4px; }
  .meta { color: #666; font-size: 11px; margin-bottom: 20px; }
  .stats { display: grid; grid-template-columns: repeat(5, 1fr); gap: 12px; margin: 16px 0; }
  .stat { background: #f5f5f5; border-radius: 8px; padding: 12px; text-align: center; }
  .stat-value { font-size: 20px; font-weight: 700; }
  .stat-label { font-size: 10px; color: #888; margin-top: 2px; }
  table { width: 100%; border-collapse: collapse; margin: 12px 0; font-size: 11px; }
  th { background: #f0f0f0; padding: 6px 8px; text-align: left; font-weight: 600; border-bottom: 2px solid #ddd; }
  td { padding: 5px 8px; border-bottom: 1px solid #eee; }
  tr:nth-child(even) { background: #fafafa; }
  .critical { color: #dc2626; font-weight: 600; }
  .milestone { color: #7c3aed; }
  .footer { margin-top: 30px; padding-top: 12px; border-top: 1px solid #e5e5e5; color: #999; font-size: 10px; text-align: center; }
  @media print { body { padding: 0; } .no-print { display: none; } }
</style>
</head>
<body>
<h1>${escXML(project.name as string)}</h1>
<div class="meta">
  Generated: ${new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })} |
  Start: ${project.planned_start || '—'} |
  Finish: ${project.planned_finish || '—'}
</div>

<div class="stats">
  <div class="stat"><div class="stat-value">${tasks.length}</div><div class="stat-label">Total Tasks</div></div>
  <div class="stat"><div class="stat-value">${milestones.length}</div><div class="stat-label">Milestones</div></div>
  <div class="stat"><div class="stat-value">${criticalTasks.length}</div><div class="stat-label">Critical Tasks</div></div>
  <div class="stat"><div class="stat-value">${avgProgress.toFixed(0)}%</div><div class="stat-label">Avg Progress</div></div>
  <div class="stat"><div class="stat-value">$${totalCost.toLocaleString()}</div><div class="stat-label">Total Budget</div></div>
</div>

<h2>Task Schedule</h2>
<table>
  <thead>
    <tr><th>#</th><th>Name</th><th>Type</th><th>Duration</th><th>Start</th><th>Finish</th><th>% Done</th><th>Float</th><th>Critical</th></tr>
  </thead>
  <tbody>
${tasks.map((t, i) => `    <tr${t.is_critical ? ' class="critical"' : ''}>
      <td>${i + 1}</td>
      <td>${escXML(t.name as string)}</td>
      <td>${t.task_type === 'milestone' ? '<span class="milestone">Milestone</span>' : (t.task_type || 'task')}</td>
      <td>${t.original_duration || '—'}d</td>
      <td>${t.planned_start || '—'}</td>
      <td>${t.planned_finish || '—'}</td>
      <td>${t.percent_complete || 0}%</td>
      <td>${t.total_float || '—'}</td>
      <td>${t.is_critical ? 'Yes' : 'No'}</td>
    </tr>`).join('\n')}
  </tbody>
</table>

${criticalTasks.length > 0 ? `
<h2>Critical Path</h2>
<table>
  <thead><tr><th>#</th><th>Name</th><th>Start</th><th>Finish</th><th>Duration</th><th>Float</th></tr></thead>
  <tbody>
${criticalTasks.map((t, i) => `    <tr>
      <td>${i + 1}</td>
      <td>${escXML(t.name as string)}</td>
      <td>${t.planned_start || '—'}</td>
      <td>${t.planned_finish || '—'}</td>
      <td>${t.original_duration || '—'}d</td>
      <td>${t.total_float || 0}</td>
    </tr>`).join('\n')}
  </tbody>
</table>` : ''}

${milestones.length > 0 ? `
<h2>Milestones</h2>
<table>
  <thead><tr><th>#</th><th>Name</th><th>Date</th><th>Status</th></tr></thead>
  <tbody>
${milestones.map((t, i) => {
  const pct = (t.percent_complete as number) || 0;
  const status = pct >= 100 ? 'Complete' : pct > 0 ? 'In Progress' : 'Pending';
  return `    <tr>
      <td>${i + 1}</td>
      <td class="milestone">${escXML(t.name as string)}</td>
      <td>${t.planned_finish || t.planned_start || '—'}</td>
      <td>${status}</td>
    </tr>`;
}).join('\n')}
  </tbody>
</table>` : ''}

<div class="footer">
  ${escXML(project.name as string)} — Schedule Report — ZAFTO Construction Management
</div>
</body>
</html>`;

  return html;
}

// ══════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════

function todayStr(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function sanitizeFilename(name: string): string {
  return name.replace(/[^a-zA-Z0-9_-]/g, '_').substring(0, 50);
}

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
