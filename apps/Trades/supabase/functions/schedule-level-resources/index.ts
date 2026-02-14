// ZAFTO Resource Leveling Engine
// GC3: Over-allocation detection + priority-based heuristic leveling.
// Accepts { project_id, options? } — detects resource conflicts,
// delays non-critical tasks to resolve, re-runs CPM after each shift.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ── Types ──

interface Task {
  id: string;
  project_id: string;
  parent_id: string | null;
  task_type: string;
  original_duration: number | null;
  early_start: string | null;
  early_finish: string | null;
  total_float: number | null;
  is_critical: boolean;
  sort_order: number;
  calendar_id: string | null;
}

interface Resource {
  id: string;
  name: string;
  resource_type: string;
  max_units: number;
  cost_per_hour: number;
  calendar_id: string | null;
}

interface TaskResource {
  id: string;
  task_id: string;
  resource_id: string;
  units_assigned: number;
  hours_per_day: number | null;
}

interface CalendarConfig {
  work_days_mask: number;
  exceptions: Set<string>;
  overtimeDates: Map<string, number>;
}

interface DailyUsage {
  date: string;
  hours: number;
  capacity: number;
  over_allocated: boolean;
}

interface LevelingOptions {
  respect_critical_path: boolean;
  leveling_order: 'priority' | 'float';
}

// ── Calendar-Aware Date Math (shared with CPM engine) ──

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
  if (cal.overtimeDates.has(ds)) return true;
  const dow = d.getUTCDay();
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

/** Get all work dates between start (inclusive) and end (exclusive). */
function getWorkDates(start: Date, end: Date, cal: CalendarConfig): string[] {
  const dates: string[] = [];
  const cursor = new Date(start);
  // Include start date if it's a work day
  if (isWorkDay(cursor, cal)) dates.push(formatDate(cursor));
  while (true) {
    cursor.setUTCDate(cursor.getUTCDate() + 1);
    if (cursor >= end) break;
    if (isWorkDay(cursor, cal)) dates.push(formatDate(cursor));
  }
  return dates;
}

// ── Resource Usage Timeline Builder ──

function buildResourceTimeline(
  resource: Resource,
  taskResources: TaskResource[],
  tasks: Map<string, Task>,
  cal: CalendarConfig,
  hoursPerDay: number,
): DailyUsage[] {
  // Get all task assignments for this resource
  const assignments = taskResources.filter(tr => tr.resource_id === resource.id);
  if (assignments.length === 0) return [];

  // Build daily usage map
  const dailyHours = new Map<string, number>();

  for (const assignment of assignments) {
    const task = tasks.get(assignment.task_id);
    if (!task || !task.early_start || !task.early_finish) continue;
    if (task.task_type === 'summary' || task.task_type === 'milestone') continue;

    const start = parseDate(task.early_start);
    const end = parseDate(task.early_finish);
    if (!start || !end) continue;

    const workDates = getWorkDates(start, end, cal);
    const hpd = assignment.hours_per_day ?? (hoursPerDay * assignment.units_assigned);

    for (const date of workDates) {
      dailyHours.set(date, (dailyHours.get(date) ?? 0) + hpd);
    }
  }

  // Convert to array sorted by date
  const capacity = resource.max_units * hoursPerDay;
  const result: DailyUsage[] = [];
  const sortedDates = [...dailyHours.keys()].sort();

  for (const date of sortedDates) {
    const hours = dailyHours.get(date)!;
    result.push({
      date,
      hours,
      capacity,
      over_allocated: hours > capacity,
    });
  }

  return result;
}

// ── Over-Allocation Detection ──

interface OverAllocation {
  resource_id: string;
  resource_name: string;
  date: string;
  allocated_hours: number;
  capacity: number;
  excess_hours: number;
  conflicting_task_ids: string[];
}

function detectOverAllocations(
  resources: Resource[],
  taskResources: TaskResource[],
  tasks: Map<string, Task>,
  cal: CalendarConfig,
  hoursPerDay: number,
): OverAllocation[] {
  const overAllocations: OverAllocation[] = [];

  for (const resource of resources) {
    const assignments = taskResources.filter(tr => tr.resource_id === resource.id);
    if (assignments.length === 0) continue;

    const capacity = resource.max_units * hoursPerDay;

    // Build per-date usage with task tracking
    const dateUsage = new Map<string, { total: number; taskIds: string[] }>();

    for (const assignment of assignments) {
      const task = tasks.get(assignment.task_id);
      if (!task || !task.early_start || !task.early_finish) continue;
      if (task.task_type === 'summary' || task.task_type === 'milestone') continue;

      const start = parseDate(task.early_start);
      const end = parseDate(task.early_finish);
      if (!start || !end) continue;

      const workDates = getWorkDates(start, end, cal);
      const hpd = assignment.hours_per_day ?? (hoursPerDay * assignment.units_assigned);

      for (const date of workDates) {
        const existing = dateUsage.get(date) ?? { total: 0, taskIds: [] };
        existing.total += hpd;
        existing.taskIds.push(task.id);
        dateUsage.set(date, existing);
      }
    }

    // Check for over-allocations
    for (const [date, usage] of dateUsage) {
      if (usage.total > capacity) {
        overAllocations.push({
          resource_id: resource.id,
          resource_name: resource.name,
          date,
          allocated_hours: usage.total,
          capacity,
          excess_hours: usage.total - capacity,
          conflicting_task_ids: usage.taskIds,
        });
      }
    }
  }

  // Sort by date
  overAllocations.sort((a, b) => a.date.localeCompare(b.date));
  return overAllocations;
}

// ── Priority-Based Heuristic Leveling ──

interface LevelingResult {
  delays: { task_id: string; original_start: string; new_start: string; delay_days: number }[];
  resolved: number;
  remaining: number;
  iterations: number;
  warnings: string[];
}

function levelResources(
  resources: Resource[],
  taskResources: TaskResource[],
  tasks: Map<string, Task>,
  cal: CalendarConfig,
  hoursPerDay: number,
  options: LevelingOptions,
): LevelingResult {
  const MAX_ITERATIONS = 1000;
  const delays: LevelingResult['delays'] = [];
  const warnings: string[] = [];
  let iterations = 0;
  let resolved = 0;

  // Clone task dates so we can modify them
  const taskDates = new Map<string, { early_start: string; early_finish: string }>();
  for (const [id, task] of tasks) {
    if (task.early_start && task.early_finish) {
      taskDates.set(id, { early_start: task.early_start, early_finish: task.early_finish });
    }
  }

  while (iterations < MAX_ITERATIONS) {
    iterations++;

    // Detect over-allocations with current dates
    const overAllocs = detectOverAllocations(resources, taskResources, tasks, cal, hoursPerDay);
    if (overAllocs.length === 0) break;

    // Process first over-allocation (chronological)
    const conflict = overAllocs[0];
    const conflictingTasks = conflict.conflicting_task_ids
      .map(id => tasks.get(id))
      .filter((t): t is Task => t !== null && t !== undefined);

    // Sort by priority: critical path first, then by float or sort_order
    conflictingTasks.sort((a, b) => {
      // Critical tasks first (keep them in place)
      if (a.is_critical && !b.is_critical) return -1;
      if (!a.is_critical && b.is_critical) return 1;

      if (options.respect_critical_path) {
        if (a.is_critical && b.is_critical) return 0; // Don't move either
      }

      if (options.leveling_order === 'float') {
        // Higher float = easier to delay
        return (b.total_float ?? 0) - (a.total_float ?? 0);
      }
      // By sort order (priority)
      return a.sort_order - b.sort_order;
    });

    // Find the task to delay: last in priority (lowest priority non-critical)
    const taskToDelay = conflictingTasks[conflictingTasks.length - 1];

    if (!taskToDelay) {
      warnings.push(`Could not resolve over-allocation for ${conflict.resource_name} on ${conflict.date}`);
      break;
    }

    // If respect_critical_path and all tasks are critical, warn and skip
    if (options.respect_critical_path && taskToDelay.is_critical) {
      warnings.push(`All conflicting tasks on ${conflict.date} for ${conflict.resource_name} are critical — cannot level without extending project`);
      // Remove this resource from further processing to avoid infinite loop
      break;
    }

    // Delay the task by 1 work day
    const currentStart = parseDate(taskToDelay.early_start);
    if (!currentStart) {
      warnings.push(`Task ${taskToDelay.id} has no early_start — skipping`);
      break;
    }

    const newStart = addWorkDays(currentStart, 1, cal);
    const duration = taskToDelay.original_duration ?? 0;
    const newFinish = duration > 0 ? addWorkDays(newStart, duration, cal) : newStart;

    const originalStart = taskToDelay.early_start!;
    taskToDelay.early_start = formatDate(newStart);
    taskToDelay.early_finish = formatDate(newFinish);

    // Track this delay
    const existingDelay = delays.find(d => d.task_id === taskToDelay.id);
    if (existingDelay) {
      existingDelay.new_start = formatDate(newStart);
      existingDelay.delay_days++;
    } else {
      delays.push({
        task_id: taskToDelay.id,
        original_start: originalStart,
        new_start: formatDate(newStart),
        delay_days: 1,
      });
    }

    resolved++;
  }

  if (iterations >= MAX_ITERATIONS) {
    warnings.push(`Circuit breaker: reached ${MAX_ITERATIONS} iterations. Some over-allocations may remain.`);
  }

  // Count remaining over-allocations
  const remaining = detectOverAllocations(resources, taskResources, tasks, cal, hoursPerDay).length;

  return { delays, resolved, remaining, iterations, warnings };
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

    const body = await req.json();
    const { project_id, options: rawOptions } = body;

    if (!project_id) {
      return new Response(JSON.stringify({ error: 'Missing project_id' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const options: LevelingOptions = {
      respect_critical_path: rawOptions?.respect_critical_path ?? true,
      leveling_order: rawOptions?.leveling_order ?? 'float',
    };

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // ── Verify project ownership ──
    const { data: project, error: projErr } = await supabaseAdmin
      .from('schedule_projects')
      .select('id, default_calendar_id, hours_per_day')
      .eq('id', project_id)
      .eq('company_id', companyId)
      .single();

    if (projErr || !project) {
      return new Response(JSON.stringify({ error: 'Project not found' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const hoursPerDay = project.hours_per_day ?? 8;

    // ── Fetch tasks ──
    const { data: rawTasks } = await supabaseAdmin
      .from('schedule_tasks')
      .select('id, project_id, parent_id, task_type, original_duration, early_start, early_finish, total_float, is_critical, sort_order, calendar_id')
      .eq('project_id', project_id)
      .is('deleted_at', null);

    if (!rawTasks || rawTasks.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        message: 'No tasks to level',
        over_allocations: [],
        histogram: {},
      }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const tasks = new Map<string, Task>();
    for (const t of rawTasks) tasks.set(t.id, t);

    // ── Fetch resources ──
    const { data: resources } = await supabaseAdmin
      .from('schedule_resources')
      .select('id, name, resource_type, max_units, cost_per_hour, calendar_id')
      .eq('company_id', companyId)
      .is('deleted_at', null);

    if (!resources || resources.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        message: 'No resources defined',
        over_allocations: [],
        histogram: {},
      }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── Fetch task-resource assignments ──
    const taskIds = rawTasks.map(t => t.id);
    const { data: taskResources } = await supabaseAdmin
      .from('schedule_task_resources')
      .select('id, task_id, resource_id, units_assigned, hours_per_day')
      .in('task_id', taskIds);

    if (!taskResources || taskResources.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        message: 'No resource assignments',
        over_allocations: [],
        histogram: {},
      }), {
        status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── Load calendar ──
    let calConfig: CalendarConfig = {
      work_days_mask: 31, // Mon-Fri
      exceptions: new Set(),
      overtimeDates: new Map(),
    };

    if (project.default_calendar_id) {
      const { data: cal } = await supabaseAdmin
        .from('schedule_calendars')
        .select('work_days_mask')
        .eq('id', project.default_calendar_id)
        .single();

      if (cal) calConfig.work_days_mask = cal.work_days_mask;

      const { data: exceptions } = await supabaseAdmin
        .from('schedule_calendar_exceptions')
        .select('exception_date, exception_type, hours_available')
        .eq('calendar_id', project.default_calendar_id);

      for (const exc of exceptions ?? []) {
        if (exc.exception_type === 'overtime') {
          calConfig.overtimeDates.set(exc.exception_date, exc.hours_available ?? 8);
        } else {
          calConfig.exceptions.add(exc.exception_date);
        }
      }
    }

    // ── Detect over-allocations ──
    const overAllocations = detectOverAllocations(
      resources, taskResources, tasks, calConfig, hoursPerDay
    );

    // ── Run leveling if requested ──
    let levelingResult: LevelingResult | null = null;
    const shouldLevel = body.level !== false; // default: level

    if (shouldLevel && overAllocations.length > 0) {
      levelingResult = levelResources(
        resources, taskResources, tasks, calConfig, hoursPerDay, options
      );

      // Apply delayed task dates to database
      if (levelingResult.delays.length > 0) {
        for (const delay of levelingResult.delays) {
          const task = tasks.get(delay.task_id);
          if (!task) continue;

          await supabaseAdmin
            .from('schedule_tasks')
            .update({
              early_start: task.early_start,
              early_finish: task.early_finish,
            })
            .eq('id', delay.task_id);
        }

        // Trigger CPM recalculation after leveling
        const cpmResponse = await fetch(
          `${Deno.env.get('SUPABASE_URL')}/functions/v1/schedule-calculate-cpm`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: authHeader,
            },
            body: JSON.stringify({ project_id }),
          },
        );

        if (!cpmResponse.ok) {
          levelingResult.warnings.push('CPM recalculation after leveling failed — dates may be inconsistent');
        }

        // Log leveling action
        await supabaseAdmin.from('schedule_task_changes').insert({
          company_id: companyId,
          project_id,
          task_id: rawTasks[0].id,
          change_type: 'updated',
          changed_by: user.id,
          source: 'resource_level',
          notes: `Resource leveling: ${levelingResult.delays.length} tasks delayed, ${levelingResult.resolved} conflicts resolved in ${levelingResult.iterations} iterations`,
        });
      }
    }

    // ── Build histogram data ──
    const histogram: Record<string, DailyUsage[]> = {};
    for (const resource of resources) {
      const timeline = buildResourceTimeline(resource, taskResources, tasks, calConfig, hoursPerDay);
      if (timeline.length > 0) {
        histogram[resource.id] = timeline;
      }
    }

    // ── Broadcast result ──
    const channel = supabaseAdmin.channel(`schedule:${project_id}`);
    await channel.send({
      type: 'broadcast',
      event: 'resource_leveled',
      payload: {
        project_id,
        over_allocations_count: overAllocations.length,
        tasks_delayed: levelingResult?.delays.length ?? 0,
        leveled_at: new Date().toISOString(),
      },
    });
    supabaseAdmin.removeChannel(channel);

    return new Response(JSON.stringify({
      success: true,
      project_id,
      over_allocations: overAllocations,
      over_allocation_count: overAllocations.length,
      leveling: levelingResult ? {
        delays: levelingResult.delays,
        resolved: levelingResult.resolved,
        remaining: levelingResult.remaining,
        iterations: levelingResult.iterations,
        warnings: levelingResult.warnings,
      } : null,
      histogram,
    }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err) {
    console.error('Resource leveling error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
