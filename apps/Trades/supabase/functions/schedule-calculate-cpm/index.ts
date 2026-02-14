// ZAFTO CPM Engine — Critical Path Method Calculation
// GC2: Forward/backward pass, float, critical path, 8 constraints.
// Triggered when tasks or dependencies change. Recalculates entire project.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ── Types ──

interface Task {
  id: string;
  parent_id: string | null;
  task_type: string;
  original_duration: number | null;
  planned_start: string | null;
  planned_finish: string | null;
  actual_start: string | null;
  actual_finish: string | null;
  percent_complete: number;
  constraint_type: string;
  constraint_date: string | null;
  calendar_id: string | null;
  sort_order: number;
}

interface Dependency {
  predecessor_id: string;
  successor_id: string;
  dependency_type: string; // FS, FF, SS, SF
  lag_days: number;
}

interface CalendarConfig {
  work_days_mask: number;
  exceptions: Set<string>; // ISO date strings that are non-work days
  overtimeDates: Map<string, number>; // date → hours available
}

interface CpmTask extends Task {
  early_start: string | null;
  early_finish: string | null;
  late_start: string | null;
  late_finish: string | null;
  total_float: number | null;
  free_float: number | null;
  is_critical: boolean;
  children: string[];
}

// ── Calendar-Aware Date Math ──

function parseDate(s: string | null): Date | null {
  if (!s) return null;
  const d = new Date(s + 'T00:00:00Z');
  return isNaN(d.getTime()) ? null : d;
}

function formatDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

function isWorkDay(d: Date, cal: CalendarConfig): boolean {
  const ds = formatDate(d);
  if (cal.exceptions.has(ds)) return false;
  // Overtime dates count as work days even if normally off
  if (cal.overtimeDates.has(ds)) return true;
  const dow = d.getUTCDay(); // 0=Sun, 1=Mon...6=Sat
  // Convert to bitmask position: Mon=bit0, Tue=bit1...Sun=bit6
  const bit = dow === 0 ? 64 : (1 << (dow - 1));
  return (cal.work_days_mask & bit) !== 0;
}

function addWorkDays(start: Date, days: number, cal: CalendarConfig): Date {
  if (days <= 0) return new Date(start);
  const result = new Date(start);
  let remaining = days;
  while (remaining > 0) {
    result.setUTCDate(result.getUTCDate() + 1);
    if (isWorkDay(result, cal)) remaining--;
  }
  return result;
}

function subtractWorkDays(end: Date, days: number, cal: CalendarConfig): Date {
  if (days <= 0) return new Date(end);
  const result = new Date(end);
  let remaining = days;
  while (remaining > 0) {
    result.setUTCDate(result.getUTCDate() - 1);
    if (isWorkDay(result, cal)) remaining--;
  }
  return result;
}

function workDaysBetween(start: Date, end: Date, cal: CalendarConfig): number {
  if (end <= start) return 0;
  let count = 0;
  const cursor = new Date(start);
  while (cursor < end) {
    cursor.setUTCDate(cursor.getUTCDate() + 1);
    if (isWorkDay(cursor, cal)) count++;
  }
  return count;
}

// ── Topological Sort (Kahn's Algorithm) ──

function topologicalSort(
  taskIds: string[],
  deps: Dependency[],
): { sorted: string[]; hasCycle: boolean; cyclePath: string[] } {
  const inDegree = new Map<string, number>();
  const adjList = new Map<string, string[]>();

  for (const id of taskIds) {
    inDegree.set(id, 0);
    adjList.set(id, []);
  }

  for (const dep of deps) {
    if (!inDegree.has(dep.predecessor_id) || !inDegree.has(dep.successor_id)) continue;
    adjList.get(dep.predecessor_id)!.push(dep.successor_id);
    inDegree.set(dep.successor_id, (inDegree.get(dep.successor_id) ?? 0) + 1);
  }

  const queue: string[] = [];
  for (const [id, deg] of inDegree) {
    if (deg === 0) queue.push(id);
  }

  const sorted: string[] = [];
  while (queue.length > 0) {
    const node = queue.shift()!;
    sorted.push(node);
    for (const neighbor of adjList.get(node) ?? []) {
      const newDeg = (inDegree.get(neighbor) ?? 1) - 1;
      inDegree.set(neighbor, newDeg);
      if (newDeg === 0) queue.push(neighbor);
    }
  }

  if (sorted.length < taskIds.length) {
    // Cycle detected — find cycle path
    const remaining = taskIds.filter(id => !sorted.includes(id));
    return { sorted: [], hasCycle: true, cyclePath: remaining };
  }

  return { sorted, hasCycle: false, cyclePath: [] };
}

// ── CPM Forward Pass ──

function forwardPass(
  sorted: string[],
  tasks: Map<string, CpmTask>,
  deps: Dependency[],
  cal: CalendarConfig,
  projectStart: Date,
): void {
  // Build predecessor map: successorId → [deps]
  const predMap = new Map<string, Dependency[]>();
  for (const dep of deps) {
    if (!predMap.has(dep.successor_id)) predMap.set(dep.successor_id, []);
    predMap.get(dep.successor_id)!.push(dep);
  }

  for (const taskId of sorted) {
    const task = tasks.get(taskId);
    if (!task || task.task_type === 'summary') continue;

    const duration = task.original_duration ?? 0;
    const preds = predMap.get(taskId) ?? [];
    let es: Date;

    if (preds.length === 0) {
      // Root task — start at project start or planned_start
      es = parseDate(task.planned_start) ?? projectStart;
    } else {
      // ES = max of all predecessor constraints
      let maxDate = new Date(0);
      for (const dep of preds) {
        const pred = tasks.get(dep.predecessor_id);
        if (!pred) continue;

        const predES = parseDate(pred.early_start);
        const predEF = parseDate(pred.early_finish);
        if (!predES || !predEF) continue;

        let candidateDate: Date;
        const lag = dep.lag_days;

        switch (dep.dependency_type) {
          case 'FS': // ES(succ) >= EF(pred) + lag
            candidateDate = addWorkDays(predEF, lag, cal);
            break;
          case 'SS': // ES(succ) >= ES(pred) + lag
            candidateDate = addWorkDays(predES, lag, cal);
            break;
          case 'FF': // EF(succ) >= EF(pred) + lag → ES = EF(pred) + lag - duration
            candidateDate = subtractWorkDays(addWorkDays(predEF, lag, cal), duration, cal);
            break;
          case 'SF': // EF(succ) >= ES(pred) + lag → ES = ES(pred) + lag - duration
            candidateDate = subtractWorkDays(addWorkDays(predES, lag, cal), duration, cal);
            break;
          default:
            candidateDate = addWorkDays(predEF, lag, cal);
        }

        if (candidateDate > maxDate) maxDate = candidateDate;
      }
      es = maxDate.getTime() === 0 ? projectStart : maxDate;
    }

    // Apply constraints (forward direction)
    es = applyForwardConstraint(task, es, duration, cal);

    // Ensure ES falls on a work day
    while (!isWorkDay(es, cal)) {
      es.setUTCDate(es.getUTCDate() + 1);
    }

    const ef = duration > 0 ? addWorkDays(es, duration, cal) : new Date(es);

    // Milestone: EF = ES
    if (task.task_type === 'milestone') {
      task.early_start = formatDate(es);
      task.early_finish = formatDate(es);
    } else {
      task.early_start = formatDate(es);
      task.early_finish = formatDate(ef);
    }
  }
}

// ── CPM Backward Pass ──

function backwardPass(
  sorted: string[],
  tasks: Map<string, CpmTask>,
  deps: Dependency[],
  cal: CalendarConfig,
  projectFinish: Date,
): void {
  // Build successor map: predecessorId → [deps]
  const succMap = new Map<string, Dependency[]>();
  for (const dep of deps) {
    if (!succMap.has(dep.predecessor_id)) succMap.set(dep.predecessor_id, []);
    succMap.get(dep.predecessor_id)!.push(dep);
  }

  // Reverse order
  for (let i = sorted.length - 1; i >= 0; i--) {
    const taskId = sorted[i];
    const task = tasks.get(taskId);
    if (!task || task.task_type === 'summary') continue;

    const duration = task.original_duration ?? 0;
    const succs = succMap.get(taskId) ?? [];
    let lf: Date;

    if (succs.length === 0) {
      // Terminal task — finish at project finish
      lf = projectFinish;
    } else {
      let minDate = new Date(8640000000000000); // max date
      for (const dep of succs) {
        const succ = tasks.get(dep.successor_id);
        if (!succ) continue;

        const succLS = parseDate(succ.late_start);
        const succLF = parseDate(succ.late_finish);
        if (!succLS || !succLF) continue;

        let candidateDate: Date;
        const lag = dep.lag_days;

        switch (dep.dependency_type) {
          case 'FS': // LF(pred) <= LS(succ) - lag
            candidateDate = subtractWorkDays(succLS, lag, cal);
            break;
          case 'SS': // LS(pred) <= LS(succ) - lag → LF = LS(succ) - lag + duration
            candidateDate = addWorkDays(subtractWorkDays(succLS, lag, cal), duration, cal);
            break;
          case 'FF': // LF(pred) <= LF(succ) - lag
            candidateDate = subtractWorkDays(succLF, lag, cal);
            break;
          case 'SF': // LS(pred) <= LF(succ) - lag → LF = LF(succ) - lag + duration
            candidateDate = addWorkDays(subtractWorkDays(succLF, lag, cal), duration, cal);
            break;
          default:
            candidateDate = subtractWorkDays(succLS, lag, cal);
        }

        if (candidateDate < minDate) minDate = candidateDate;
      }
      lf = minDate.getTime() === 8640000000000000 ? projectFinish : minDate;
    }

    // Apply constraints (backward direction)
    lf = applyBackwardConstraint(task, lf, duration, cal);

    const ls = duration > 0 ? subtractWorkDays(lf, duration, cal) : new Date(lf);

    if (task.task_type === 'milestone') {
      task.late_start = formatDate(lf);
      task.late_finish = formatDate(lf);
    } else {
      task.late_start = formatDate(ls);
      task.late_finish = formatDate(lf);
    }
  }
}

// ── Constraint Application ──

function applyForwardConstraint(task: CpmTask, es: Date, duration: number, cal: CalendarConfig): Date {
  const cd = parseDate(task.constraint_date);
  switch (task.constraint_type) {
    case 'snet': // Start No Earlier Than
      if (cd && es < cd) return new Date(cd);
      break;
    case 'snlt': // Start No Later Than
      if (cd && es > cd) return new Date(cd);
      break;
    case 'fnet': { // Finish No Earlier Than
      if (cd) {
        const minES = subtractWorkDays(cd, duration, cal);
        if (es < minES) return minES;
      }
      break;
    }
    case 'fnlt': { // Finish No Later Than
      if (cd) {
        const maxES = subtractWorkDays(cd, duration, cal);
        if (es > maxES) return maxES;
      }
      break;
    }
    case 'mso': // Must Start On
      if (cd) return new Date(cd);
      break;
    case 'mfo': { // Must Finish On
      if (cd) return subtractWorkDays(cd, duration, cal);
      break;
    }
    // asap, alap: no forward constraint
  }
  return es;
}

function applyBackwardConstraint(task: CpmTask, lf: Date, duration: number, cal: CalendarConfig): Date {
  const cd = parseDate(task.constraint_date);
  switch (task.constraint_type) {
    case 'fnlt': // Finish No Later Than
      if (cd && lf > cd) return new Date(cd);
      break;
    case 'fnet': // Finish No Earlier Than
      if (cd && lf < cd) return new Date(cd);
      break;
    case 'snlt': { // Start No Later Than
      if (cd) {
        const maxLF = addWorkDays(cd, duration, cal);
        if (lf > maxLF) return maxLF;
      }
      break;
    }
    case 'snet': { // Start No Earlier Than
      if (cd) {
        const minLF = addWorkDays(cd, duration, cal);
        if (lf < minLF) return minLF;
      }
      break;
    }
    case 'mfo': // Must Finish On
      if (cd) return new Date(cd);
      break;
    case 'mso': { // Must Start On
      if (cd) return addWorkDays(cd, duration, cal);
      break;
    }
    case 'alap': // As Late As Possible — LF stays at max
      break;
    // asap: no backward constraint
  }
  return lf;
}

// ── Float Calculation ──

function calculateFloat(
  tasks: Map<string, CpmTask>,
  deps: Dependency[],
  cal: CalendarConfig,
): void {
  // Build successor map for free float calc
  const succMap = new Map<string, Dependency[]>();
  for (const dep of deps) {
    if (!succMap.has(dep.predecessor_id)) succMap.set(dep.predecessor_id, []);
    succMap.get(dep.predecessor_id)!.push(dep);
  }

  for (const task of tasks.values()) {
    if (task.task_type === 'summary') continue;

    const es = parseDate(task.early_start);
    const ls = parseDate(task.late_start);
    const ef = parseDate(task.early_finish);

    if (es && ls) {
      task.total_float = workDaysBetween(es, ls, cal);
      // Negative float for constraints that push past project end
      if (ls < es) task.total_float = -workDaysBetween(ls, es, cal);
    }

    // Free float = min(successor ES) - EF
    const succs = succMap.get(task.id) ?? [];
    if (succs.length > 0 && ef) {
      let minSuccES = new Date(8640000000000000);
      for (const dep of succs) {
        const succ = tasks.get(dep.successor_id);
        if (!succ) continue;
        const succES = parseDate(succ.early_start);
        if (succES && succES < minSuccES) minSuccES = succES;
      }
      if (minSuccES.getTime() !== 8640000000000000) {
        task.free_float = workDaysBetween(ef, minSuccES, cal);
        if (minSuccES < ef) task.free_float = -workDaysBetween(minSuccES, ef, cal);
      }
    } else {
      task.free_float = task.total_float;
    }

    // Critical = total float <= 0
    task.is_critical = (task.total_float ?? 0) <= 0;
  }
}

// ── Summary Task Roll-Up ──

function rollUpSummaryTasks(tasks: Map<string, CpmTask>, cal: CalendarConfig): void {
  // Build parent → children map
  for (const task of tasks.values()) {
    if (task.parent_id) {
      const parent = tasks.get(task.parent_id);
      if (parent) parent.children.push(task.id);
    }
  }

  // Process bottom-up: sort by indent level descending (deepest first)
  const summaryTasks = [...tasks.values()]
    .filter(t => t.task_type === 'summary' && t.children.length > 0);

  // Recursive roll-up from leaves
  function rollUp(taskId: string): void {
    const task = tasks.get(taskId);
    if (!task || task.task_type !== 'summary') return;

    // Ensure children are rolled up first
    for (const childId of task.children) {
      const child = tasks.get(childId);
      if (child?.task_type === 'summary') rollUp(childId);
    }

    let minES: Date | null = null;
    let maxEF: Date | null = null;
    let minLS: Date | null = null;
    let maxLF: Date | null = null;
    let totalWeightedPct = 0;
    let totalDuration = 0;
    let totalBudget = 0;
    let totalActual = 0;
    let anyCritical = false;

    for (const childId of task.children) {
      const child = tasks.get(childId);
      if (!child) continue;

      const childES = parseDate(child.early_start);
      const childEF = parseDate(child.early_finish);
      const childLS = parseDate(child.late_start);
      const childLF = parseDate(child.late_finish);
      const dur = child.original_duration ?? 0;

      if (childES && (!minES || childES < minES)) minES = childES;
      if (childEF && (!maxEF || childEF > maxEF)) maxEF = childEF;
      if (childLS && (!minLS || childLS < minLS)) minLS = childLS;
      if (childLF && (!maxLF || childLF > maxLF)) maxLF = childLF;

      totalWeightedPct += child.percent_complete * dur;
      totalDuration += dur;
      totalBudget += (child as any).budgeted_cost ?? 0;
      totalActual += (child as any).actual_cost ?? 0;
      if (child.is_critical) anyCritical = true;
    }

    task.early_start = minES ? formatDate(minES) : null;
    task.early_finish = maxEF ? formatDate(maxEF) : null;
    task.late_start = minLS ? formatDate(minLS) : null;
    task.late_finish = maxLF ? formatDate(maxLF) : null;
    task.original_duration = minES && maxEF ? workDaysBetween(minES, maxEF, cal) : 0;
    task.percent_complete = totalDuration > 0 ? totalWeightedPct / totalDuration : 0;
    task.is_critical = anyCritical;

    if (minES && minLS) {
      task.total_float = workDaysBetween(minES, minLS, cal);
    }
    task.free_float = task.total_float;
  }

  // Find top-level summaries and roll up recursively
  for (const st of summaryTasks) {
    if (!st.parent_id || !tasks.get(st.parent_id)?.children.length) {
      rollUp(st.id);
    }
  }
  // Roll up any remaining
  for (const st of summaryTasks) {
    if (st.early_start === null) rollUp(st.id);
  }
}

// ── Main Handler ──

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

    const { project_id } = await req.json();
    if (!project_id) {
      return new Response(JSON.stringify({ error: 'Missing project_id' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // ── Debounce: skip if CPM was recalculated within last 2 seconds ──
    const { data: recentCalc } = await supabaseAdmin
      .from('schedule_task_changes')
      .select('created_at')
      .eq('project_id', project_id)
      .eq('change_type', 'cpm_recalculated')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (recentCalc) {
      const lastCalcAge = Date.now() - new Date(recentCalc.created_at).getTime();
      if (lastCalcAge < 2000) {
        return new Response(JSON.stringify({
          success: true,
          message: 'CPM calculation debounced — recalculated within last 2 seconds',
          debounced: true,
        }), {
          status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    }

    // ── Fetch project ──
    const { data: project, error: projErr } = await supabaseAdmin
      .from('schedule_projects')
      .select('*')
      .eq('id', project_id)
      .eq('company_id', companyId)
      .single();

    if (projErr || !project) {
      return new Response(JSON.stringify({ error: 'Project not found' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── Fetch tasks ──
    const { data: rawTasks, error: taskErr } = await supabaseAdmin
      .from('schedule_tasks')
      .select('*')
      .eq('project_id', project_id)
      .is('deleted_at', null)
      .order('sort_order', { ascending: true });

    if (taskErr) {
      return new Response(JSON.stringify({ error: 'Failed to fetch tasks', detail: taskErr.message }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!rawTasks || rawTasks.length === 0) {
      return new Response(JSON.stringify({ success: true, message: 'No tasks to calculate', critical_path: [] }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── Fetch dependencies ──
    const { data: rawDeps } = await supabaseAdmin
      .from('schedule_dependencies')
      .select('predecessor_id, successor_id, dependency_type, lag_days')
      .eq('project_id', project_id);

    const deps: Dependency[] = (rawDeps ?? []).map(d => ({
      predecessor_id: d.predecessor_id,
      successor_id: d.successor_id,
      dependency_type: d.dependency_type,
      lag_days: d.lag_days ?? 0,
    }));

    // ── Fetch calendar ──
    let calConfig: CalendarConfig = {
      work_days_mask: 31, // Mon-Fri default
      exceptions: new Set(),
      overtimeDates: new Map(),
    };

    const calendarId = project.default_calendar_id;
    if (calendarId) {
      const { data: cal } = await supabaseAdmin
        .from('schedule_calendars')
        .select('work_days_mask')
        .eq('id', calendarId)
        .single();

      if (cal) calConfig.work_days_mask = cal.work_days_mask;

      const { data: exceptions } = await supabaseAdmin
        .from('schedule_calendar_exceptions')
        .select('exception_date, exception_type, hours_available')
        .eq('calendar_id', calendarId);

      for (const exc of exceptions ?? []) {
        if (exc.exception_type === 'overtime') {
          calConfig.overtimeDates.set(exc.exception_date, exc.hours_available ?? 8);
        } else {
          calConfig.exceptions.add(exc.exception_date);
        }
      }
    }

    // ── Build task map ──
    const tasks = new Map<string, CpmTask>();
    const nonSummaryIds: string[] = [];

    for (const t of rawTasks) {
      const cpmTask: CpmTask = {
        ...t,
        early_start: null,
        early_finish: null,
        late_start: null,
        late_finish: null,
        total_float: null,
        free_float: null,
        is_critical: false,
        children: [],
      };
      tasks.set(t.id, cpmTask);
      if (t.task_type !== 'summary') nonSummaryIds.push(t.id);
    }

    // ── Topological sort (non-summary tasks only) ──
    const { sorted, hasCycle, cyclePath } = topologicalSort(nonSummaryIds, deps);

    if (hasCycle) {
      return new Response(JSON.stringify({
        error: 'Circular dependency detected',
        cycle: cyclePath,
      }), {
        status: 422, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── CPM calculation ──
    const projectStart = parseDate(project.planned_start) ?? new Date();

    forwardPass(sorted, tasks, deps, calConfig, projectStart);

    // Determine project finish: max EF or planned_finish
    let maxEF = parseDate(project.planned_finish);
    for (const task of tasks.values()) {
      if (task.task_type === 'summary') continue;
      const ef = parseDate(task.early_finish);
      if (ef && (!maxEF || ef > maxEF)) maxEF = ef;
    }
    const projectFinish = maxEF ?? new Date();

    backwardPass(sorted, tasks, deps, calConfig, projectFinish);
    calculateFloat(tasks, deps, calConfig);
    rollUpSummaryTasks(tasks, calConfig);

    // ── Batch update tasks ──
    const updates: { id: string; early_start: string | null; early_finish: string | null; late_start: string | null; late_finish: string | null; total_float: number | null; free_float: number | null; is_critical: boolean }[] = [];

    for (const task of tasks.values()) {
      updates.push({
        id: task.id,
        early_start: task.early_start,
        early_finish: task.early_finish,
        late_start: task.late_start,
        late_finish: task.late_finish,
        total_float: task.total_float,
        free_float: task.free_float,
        is_critical: task.is_critical,
      });
    }

    // Update in batches of 50
    for (let i = 0; i < updates.length; i += 50) {
      const batch = updates.slice(i, i + 50);
      for (const u of batch) {
        await supabaseAdmin
          .from('schedule_tasks')
          .update({
            early_start: u.early_start,
            early_finish: u.early_finish,
            late_start: u.late_start,
            late_finish: u.late_finish,
            total_float: u.total_float,
            free_float: u.free_float,
            is_critical: u.is_critical,
          })
          .eq('id', u.id);
      }
    }

    // ── Log CPM recalculation ──
    await supabaseAdmin.from('schedule_task_changes').insert({
      company_id: companyId,
      project_id,
      task_id: rawTasks[0].id, // reference first task
      change_type: 'cpm_recalculated',
      changed_by: user.id,
      source: 'cpm_engine',
      notes: `CPM recalculated: ${updates.length} tasks, ${deps.length} dependencies`,
    });

    // ── Build response ──
    const criticalPath = updates
      .filter(u => u.is_critical)
      .map(u => u.id);

    // ── Broadcast via Realtime ──
    const channel = supabaseAdmin.channel(`schedule:${project_id}`);
    await channel.send({
      type: 'broadcast',
      event: 'cpm_recalc',
      payload: {
        project_id,
        critical_path: criticalPath,
        affected_task_ids: updates.map(u => u.id),
        project_finish: formatDate(projectFinish),
        recalculated_at: new Date().toISOString(),
      },
    });
    supabaseAdmin.removeChannel(channel);

    return new Response(JSON.stringify({
      success: true,
      project_id,
      tasks_updated: updates.length,
      critical_path: criticalPath,
      critical_count: criticalPath.length,
      project_finish: formatDate(projectFinish),
    }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err) {
    console.error('CPM engine error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
