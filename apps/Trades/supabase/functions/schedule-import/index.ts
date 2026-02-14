// ZAFTO Schedule Import Engine
// GC7: Imports P6 XER, MS Project XML, and CSV schedule data.
// Downloads from Storage, parses format, maps to ZAFTO schema,
// creates tasks/deps/resources, triggers CPM recalc.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { parse as parseXML } from 'https://esm.sh/fast-xml-parser@4.3.2'

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
    if (!authHeader) {
      return jsonError('Missing authorization', 401);
    }

    const supabaseUser = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: authErr } = await supabaseUser.auth.getUser();
    if (authErr || !user) return jsonError('Unauthorized', 401);

    const companyId = user.app_metadata?.company_id;
    if (!companyId) return jsonError('No company assigned', 400);

    const { project_id, format, file_path, csv_mapping } = await req.json();

    if (!project_id) return jsonError('Missing project_id', 400);
    if (!format || !['xer', 'msp_xml', 'csv'].includes(format)) {
      return jsonError('Invalid format. Must be: xer, msp_xml, csv', 400);
    }
    if (!file_path) return jsonError('Missing file_path', 400);

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Verify project ownership
    const { data: project, error: projErr } = await supabaseAdmin
      .from('schedule_projects')
      .select('id, company_id')
      .eq('id', project_id)
      .eq('company_id', companyId)
      .single();

    if (projErr || !project) return jsonError('Project not found', 404);

    // Download file from Storage
    const { data: fileData, error: dlErr } = await supabaseAdmin.storage
      .from('documents')
      .download(file_path);

    if (dlErr || !fileData) return jsonError('Failed to download file', 500);

    const content = await fileData.text();
    const warnings: string[] = [];

    // Parse based on format
    let parsed: ParsedSchedule;
    switch (format) {
      case 'xer':
        parsed = parseXER(content, warnings);
        break;
      case 'msp_xml':
        parsed = parseMSProjectXML(content, warnings);
        break;
      case 'csv':
        parsed = parseCSV(content, csv_mapping, warnings);
        break;
      default:
        return jsonError('Unsupported format', 400);
    }

    if (parsed.tasks.length === 0) {
      return jsonError('No tasks found in file', 422);
    }

    // Circular dependency check
    const circularCheck = detectCircularDeps(parsed.tasks, parsed.dependencies);
    if (circularCheck) {
      warnings.push(`Circular dependency detected: ${circularCheck}. Some dependencies were skipped.`);
    }

    // Import into database
    const result = await importSchedule(
      supabaseAdmin, companyId, project_id, user.id, parsed, warnings,
    );

    // Trigger CPM recalc
    try {
      await supabaseAdmin.functions.invoke('schedule-calculate-cpm', {
        body: { project_id },
      });
    } catch (e) {
      warnings.push('CPM recalculation failed. Please trigger manually.');
    }

    // Log import
    await supabaseAdmin.from('schedule_task_changes').insert({
      company_id: companyId,
      project_id,
      task_id: project_id,
      change_type: 'updated',
      changed_by: user.id,
      source: 'import',
      notes: `Imported ${format.toUpperCase()}: ${result.tasks_imported} tasks, ${result.dependencies_imported} deps, ${result.resources_imported} resources`,
    });

    return new Response(JSON.stringify({
      success: true,
      ...result,
      warnings,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err) {
    console.error('Schedule import error:', err);
    return jsonError('Internal server error', 500);
  }
});

// ══════════════════════════════════════════════════════════════
// TYPES
// ══════════════════════════════════════════════════════════════

interface ParsedTask {
  external_id: string;
  name: string;
  wbs_code?: string;
  task_type?: string;
  duration?: number;
  planned_start?: string;
  planned_finish?: string;
  percent_complete?: number;
  budgeted_cost?: number;
  constraint_type?: string;
  constraint_date?: string;
  calendar_name?: string;
}

interface ParsedDependency {
  from_external_id: string;
  to_external_id: string;
  dependency_type?: string;
  lag_days?: number;
}

interface ParsedResource {
  external_id: string;
  name: string;
  resource_type?: string;
  cost_per_hour?: number;
  max_units?: number;
}

interface ParsedAssignment {
  task_external_id: string;
  resource_external_id: string;
  units?: number;
}

interface ParsedSchedule {
  tasks: ParsedTask[];
  dependencies: ParsedDependency[];
  resources: ParsedResource[];
  assignments: ParsedAssignment[];
}

// ══════════════════════════════════════════════════════════════
// P6 XER PARSER
// ══════════════════════════════════════════════════════════════

function parseXER(content: string, warnings: string[]): ParsedSchedule {
  const result: ParsedSchedule = {
    tasks: [], dependencies: [], resources: [], assignments: [],
  };

  // XER is a tab-delimited text format with %T (table), %F (fields), %R (rows)
  const lines = content.split('\n').map(l => l.trimEnd());
  let currentTable = '';
  let currentFields: string[] = [];

  const tables: Record<string, { fields: string[]; rows: Record<string, string>[] }> = {};

  for (const line of lines) {
    if (line.startsWith('%T')) {
      currentTable = line.substring(3).trim();
      tables[currentTable] = { fields: [], rows: [] };
    } else if (line.startsWith('%F')) {
      currentFields = line.substring(3).split('\t');
      if (tables[currentTable]) {
        tables[currentTable].fields = currentFields;
      }
    } else if (line.startsWith('%R')) {
      const values = line.substring(3).split('\t');
      if (tables[currentTable]) {
        const row: Record<string, string> = {};
        currentFields.forEach((field, i) => {
          row[field] = values[i] ?? '';
        });
        tables[currentTable].rows.push(row);
      }
    }
  }

  // Parse TASK table
  const taskTable = tables['TASK'];
  if (taskTable) {
    for (const row of taskTable.rows) {
      const taskId = row['task_id'] || row['task_code'] || '';
      if (!taskId) continue;

      const taskType = row['task_type'] || '';
      let mappedType = 'task';
      if (taskType.includes('TT_Mile') || taskType.includes('Milestone')) {
        mappedType = 'milestone';
      } else if (taskType.includes('TT_LOE') || taskType.includes('Level of Effort')) {
        mappedType = 'loe';
      } else if (taskType.includes('TT_WBS') || taskType.includes('WBS Summary')) {
        mappedType = 'summary';
      }

      result.tasks.push({
        external_id: taskId,
        name: row['task_name'] || row['task_code'] || 'Imported Task',
        wbs_code: row['wbs_id'] || undefined,
        task_type: mappedType,
        duration: parseFloat(row['target_drtn_hr_cnt'] || '0') / 8 || undefined,
        planned_start: parseP6Date(row['target_start_date']),
        planned_finish: parseP6Date(row['target_end_date']),
        percent_complete: parseFloat(row['phys_complete_pct'] || '0') || 0,
        budgeted_cost: parseFloat(row['target_work_qty'] || '0') || undefined,
        constraint_type: mapP6Constraint(row['cstr_type']),
        constraint_date: parseP6Date(row['cstr_date']),
      });
    }
  } else {
    warnings.push('No TASK table found in XER file');
  }

  // Parse TASKPRED table (dependencies)
  const predTable = tables['TASKPRED'];
  if (predTable) {
    for (const row of predTable.rows) {
      const fromId = row['pred_task_id'] || '';
      const toId = row['task_id'] || '';
      if (!fromId || !toId) continue;

      result.dependencies.push({
        from_external_id: fromId,
        to_external_id: toId,
        dependency_type: mapP6DepType(row['pred_type']),
        lag_days: parseFloat(row['lag_hr_cnt'] || '0') / 8 || 0,
      });
    }
  }

  // Parse RSRC table (resources)
  const rsrcTable = tables['RSRC'];
  if (rsrcTable) {
    for (const row of rsrcTable.rows) {
      const rsrcId = row['rsrc_id'] || '';
      if (!rsrcId) continue;

      const rsrcType = row['rsrc_type'] || '';
      let mappedType = 'labor';
      if (rsrcType.includes('RT_Equip')) mappedType = 'equipment';
      else if (rsrcType.includes('RT_Mat')) mappedType = 'material';

      result.resources.push({
        external_id: rsrcId,
        name: row['rsrc_name'] || row['rsrc_short_name'] || 'Resource',
        resource_type: mappedType,
        cost_per_hour: parseFloat(row['cost_qty_link_flag'] || '0') || undefined,
        max_units: parseFloat(row['max_qty'] || '1') || 1,
      });
    }
  }

  // Parse TASKRSRC table (assignments)
  const taskRsrcTable = tables['TASKRSRC'];
  if (taskRsrcTable) {
    for (const row of taskRsrcTable.rows) {
      const taskId = row['task_id'] || '';
      const rsrcId = row['rsrc_id'] || '';
      if (!taskId || !rsrcId) continue;

      result.assignments.push({
        task_external_id: taskId,
        resource_external_id: rsrcId,
        units: parseFloat(row['target_qty'] || '1') || 1,
      });
    }
  }

  return result;
}

function parseP6Date(value: string | undefined): string | undefined {
  if (!value) return undefined;
  // P6 dates: "2024-03-15 08:00" or "2024-03-15T08:00:00"
  const match = value.match(/(\d{4})-(\d{2})-(\d{2})/);
  if (match) return `${match[1]}-${match[2]}-${match[3]}`;
  return undefined;
}

function mapP6Constraint(value: string | undefined): string | undefined {
  if (!value) return undefined;
  const map: Record<string, string> = {
    'CS_ASAP': 'ASAP', 'CS_ALAP': 'ALAP',
    'CS_SNET': 'SNET', 'CS_SNLT': 'SNLT',
    'CS_FNET': 'FNET', 'CS_FNLT': 'FNLT',
    'CS_MSO': 'MSO', 'CS_MFO': 'MFO',
  };
  return map[value] || undefined;
}

function mapP6DepType(value: string | undefined): string {
  if (!value) return 'FS';
  const map: Record<string, string> = {
    'PR_FS': 'FS', 'PR_FF': 'FF', 'PR_SS': 'SS', 'PR_SF': 'SF',
  };
  return map[value] || 'FS';
}

// ══════════════════════════════════════════════════════════════
// MS PROJECT XML PARSER
// ══════════════════════════════════════════════════════════════

function parseMSProjectXML(content: string, warnings: string[]): ParsedSchedule {
  const result: ParsedSchedule = {
    tasks: [], dependencies: [], resources: [], assignments: [],
  };

  const options = {
    ignoreAttributes: false,
    attributeNamePrefix: '@_',
    isArray: (name: string) => ['Task', 'Resource', 'Assignment', 'PredecessorLink'].includes(name),
  };

  let doc: Record<string, unknown>;
  try {
    doc = parseXML(content, options);
  } catch (e) {
    warnings.push('Failed to parse XML: ' + (e instanceof Error ? e.message : String(e)));
    return result;
  }

  const project = (doc as Record<string, unknown>)['Project'] as Record<string, unknown> | undefined;
  if (!project) {
    warnings.push('No <Project> root element found in XML');
    return result;
  }

  // UID → external_id mapping
  const uidMap = new Map<string, string>();

  // Parse Tasks
  const tasks = ((project['Tasks'] as Record<string, unknown>)?.['Task'] || []) as Record<string, unknown>[];
  for (const task of tasks) {
    const uid = String(task['UID'] || '');
    if (!uid || uid === '0') continue; // Skip summary task 0

    const name = String(task['Name'] || 'Imported Task');
    const isMilestone = task['Milestone'] === '1' || task['Milestone'] === 'true' || task['Milestone'] === true;
    const isSummary = task['Summary'] === '1' || task['Summary'] === 'true' || task['Summary'] === true;

    let taskType = 'task';
    if (isMilestone) taskType = 'milestone';
    else if (isSummary) taskType = 'summary';

    const durationStr = String(task['Duration'] || '');
    const duration = parseMSPDuration(durationStr);

    result.tasks.push({
      external_id: uid,
      name,
      wbs_code: String(task['WBS'] || '') || undefined,
      task_type: taskType,
      duration,
      planned_start: parseMSPDate(task['Start']),
      planned_finish: parseMSPDate(task['Finish']),
      percent_complete: parseFloat(String(task['PercentComplete'] || '0')),
      budgeted_cost: parseFloat(String(task['Cost'] || '0')) || undefined,
      constraint_type: mapMSPConstraint(String(task['ConstraintType'] || '')),
      constraint_date: parseMSPDate(task['ConstraintDate']),
    });

    uidMap.set(uid, uid);

    // Parse predecessor links
    const preds = (task['PredecessorLink'] || []) as Record<string, unknown>[];
    for (const pred of preds) {
      const predUID = String(pred['PredecessorUID'] || '');
      if (!predUID) continue;

      const depTypeNum = String(pred['Type'] || '1');
      const depType = ({ '0': 'FF', '1': 'FS', '2': 'SF', '3': 'SS' })[depTypeNum] || 'FS';

      const lagStr = String(pred['LinkLag'] || '0');
      const lagTenths = parseInt(lagStr, 10) || 0;
      const lagDays = lagTenths / 4800; // MSP stores lag in tenths of minutes, 480 min = 1 day

      result.dependencies.push({
        from_external_id: predUID,
        to_external_id: uid,
        dependency_type: depType,
        lag_days: Math.round(lagDays * 10) / 10,
      });
    }
  }

  // Parse Resources
  const resources = ((project['Resources'] as Record<string, unknown>)?.['Resource'] || []) as Record<string, unknown>[];
  for (const res of resources) {
    const uid = String(res['UID'] || '');
    if (!uid || uid === '0') continue;

    const resType = String(res['Type'] || '1');
    let mappedType = 'labor';
    if (resType === '0') mappedType = 'material';
    else if (resType === '2') mappedType = 'equipment'; // Cost type → equipment

    result.resources.push({
      external_id: uid,
      name: String(res['Name'] || 'Resource'),
      resource_type: mappedType,
      cost_per_hour: parseFloat(String(res['StandardRate'] || '0')) || undefined,
      max_units: parseFloat(String(res['MaxUnits'] || '1')) || 1,
    });
  }

  // Parse Assignments
  const assignments = ((project['Assignments'] as Record<string, unknown>)?.['Assignment'] || []) as Record<string, unknown>[];
  for (const assign of assignments) {
    const taskUID = String(assign['TaskUID'] || '');
    const resUID = String(assign['ResourceUID'] || '');
    if (!taskUID || !resUID || taskUID === '0' || resUID === '0') continue;

    result.assignments.push({
      task_external_id: taskUID,
      resource_external_id: resUID,
      units: parseFloat(String(assign['Units'] || '1')) || 1,
    });
  }

  return result;
}

function parseMSPDate(value: unknown): string | undefined {
  if (!value) return undefined;
  const str = String(value);
  const match = str.match(/(\d{4})-(\d{2})-(\d{2})/);
  if (match) return `${match[1]}-${match[2]}-${match[3]}`;
  return undefined;
}

function parseMSPDuration(durationStr: string): number | undefined {
  // MSP XML Duration format: PT480H0M0S (hours), or P5D, etc.
  if (!durationStr) return undefined;
  const hoursMatch = durationStr.match(/PT(\d+)H/);
  if (hoursMatch) return parseFloat(hoursMatch[1]) / 8;
  const daysMatch = durationStr.match(/P(\d+)D/);
  if (daysMatch) return parseFloat(daysMatch[1]);
  return undefined;
}

function mapMSPConstraint(value: string): string | undefined {
  const map: Record<string, string> = {
    '0': 'ASAP', '1': 'ALAP',
    '2': 'MSO', '3': 'MFO',
    '4': 'SNET', '5': 'SNLT',
    '6': 'FNET', '7': 'FNLT',
  };
  return map[value] || undefined;
}

// ══════════════════════════════════════════════════════════════
// CSV PARSER
// ══════════════════════════════════════════════════════════════

interface CSVMapping {
  name: string;
  start?: string;
  finish?: string;
  duration?: string;
  predecessors?: string;
  resources?: string;
  wbs?: string;
  percent_complete?: string;
  cost?: string;
}

function parseCSV(content: string, mapping: CSVMapping | undefined, warnings: string[]): ParsedSchedule {
  const result: ParsedSchedule = {
    tasks: [], dependencies: [], resources: [], assignments: [],
  };

  const lines = content.split(/\r?\n/).filter(l => l.trim());
  if (lines.length < 2) {
    warnings.push('CSV file has no data rows');
    return result;
  }

  const headers = parseCSVLine(lines[0]);

  // Auto-detect mapping if not provided
  const map = mapping || autoDetectCSVMapping(headers, warnings);
  if (!map.name) {
    warnings.push('Could not determine task name column');
    return result;
  }

  const nameIdx = headers.indexOf(map.name);
  const startIdx = map.start ? headers.indexOf(map.start) : -1;
  const finishIdx = map.finish ? headers.indexOf(map.finish) : -1;
  const durationIdx = map.duration ? headers.indexOf(map.duration) : -1;
  const predIdx = map.predecessors ? headers.indexOf(map.predecessors) : -1;
  const resIdx = map.resources ? headers.indexOf(map.resources) : -1;
  const wbsIdx = map.wbs ? headers.indexOf(map.wbs) : -1;
  const pctIdx = map.percent_complete ? headers.indexOf(map.percent_complete) : -1;
  const costIdx = map.cost ? headers.indexOf(map.cost) : -1;

  if (nameIdx === -1) {
    warnings.push(`Column "${map.name}" not found in CSV headers`);
    return result;
  }

  // Track task row numbers for predecessor references
  const taskRowMap = new Map<number, string>(); // row number → external_id

  for (let i = 1; i < lines.length; i++) {
    const values = parseCSVLine(lines[i]);
    const name = values[nameIdx]?.trim();
    if (!name) continue;

    const externalId = String(i);
    taskRowMap.set(i, externalId);

    result.tasks.push({
      external_id: externalId,
      name,
      wbs_code: wbsIdx >= 0 ? values[wbsIdx]?.trim() || undefined : undefined,
      duration: durationIdx >= 0 ? parseFloat(values[durationIdx] || '0') || undefined : undefined,
      planned_start: startIdx >= 0 ? parseFlexibleDate(values[startIdx]) : undefined,
      planned_finish: finishIdx >= 0 ? parseFlexibleDate(values[finishIdx]) : undefined,
      percent_complete: pctIdx >= 0 ? parseFloat(values[pctIdx] || '0') || 0 : 0,
      budgeted_cost: costIdx >= 0 ? parseFloat(values[costIdx]?.replace(/[$,]/g, '') || '0') || undefined : undefined,
    });

    // Parse predecessors (e.g., "1FS", "2SS+2", "3,5")
    if (predIdx >= 0 && values[predIdx]) {
      const preds = values[predIdx].split(/[,;]/);
      for (const pred of preds) {
        const predMatch = pred.trim().match(/^(\d+)(\w{2})?([+-]\d+)?$/);
        if (predMatch) {
          const predRow = parseInt(predMatch[1], 10);
          const depType = predMatch[2]?.toUpperCase() || 'FS';
          const lag = predMatch[3] ? parseInt(predMatch[3], 10) : 0;

          if (['FS', 'FF', 'SS', 'SF'].includes(depType)) {
            result.dependencies.push({
              from_external_id: String(predRow),
              to_external_id: externalId,
              dependency_type: depType,
              lag_days: lag,
            });
          }
        }
      }
    }

    // Parse resource names
    if (resIdx >= 0 && values[resIdx]) {
      const resNames = values[resIdx].split(/[,;]/).map(r => r.trim()).filter(Boolean);
      for (const resName of resNames) {
        if (!result.resources.find(r => r.name === resName)) {
          result.resources.push({
            external_id: `res_${resName}`,
            name: resName,
            resource_type: 'labor',
          });
        }
        result.assignments.push({
          task_external_id: externalId,
          resource_external_id: `res_${resName}`,
          units: 1,
        });
      }
    }
  }

  return result;
}

function parseCSVLine(line: string): string[] {
  const result: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch === ',' && !inQuotes) {
      result.push(current);
      current = '';
    } else {
      current += ch;
    }
  }
  result.push(current);
  return result;
}

function autoDetectCSVMapping(headers: string[], warnings: string[]): CSVMapping {
  const lower = headers.map(h => h.toLowerCase().trim());
  const find = (patterns: string[]) => {
    for (const p of patterns) {
      const idx = lower.findIndex(h => h.includes(p));
      if (idx >= 0) return headers[idx];
    }
    return undefined;
  };

  const mapping: CSVMapping = {
    name: find(['task name', 'name', 'activity name', 'title', 'task']) || '',
    start: find(['start', 'begin', 'start date', 'planned start']),
    finish: find(['finish', 'end', 'end date', 'finish date', 'planned finish']),
    duration: find(['duration', 'days', 'original duration']),
    predecessors: find(['predecessor', 'pred', 'depends on', 'dependency']),
    resources: find(['resource', 'assigned to', 'resources']),
    wbs: find(['wbs', 'wbs code', 'outline']),
    percent_complete: find(['percent', 'complete', '% complete', 'progress']),
    cost: find(['cost', 'budget', 'budgeted cost']),
  };

  if (!mapping.name) {
    warnings.push('Auto-detection: could not find task name column');
  }

  return mapping;
}

function parseFlexibleDate(value: string | undefined): string | undefined {
  if (!value) return undefined;
  const trimmed = value.trim();

  // ISO format: 2024-03-15
  if (/^\d{4}-\d{2}-\d{2}/.test(trimmed)) {
    return trimmed.substring(0, 10);
  }

  // US format: 03/15/2024 or 3/15/24
  const usMatch = trimmed.match(/^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$/);
  if (usMatch) {
    const month = usMatch[1].padStart(2, '0');
    const day = usMatch[2].padStart(2, '0');
    let year = usMatch[3];
    if (year.length === 2) year = (parseInt(year) > 50 ? '19' : '20') + year;
    return `${year}-${month}-${day}`;
  }

  // Try Date.parse as fallback
  const parsed = Date.parse(trimmed);
  if (!isNaN(parsed)) {
    const d = new Date(parsed);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }

  return undefined;
}

// ══════════════════════════════════════════════════════════════
// CIRCULAR DEPENDENCY CHECK
// ══════════════════════════════════════════════════════════════

function detectCircularDeps(
  tasks: ParsedTask[],
  deps: ParsedDependency[],
): string | null {
  const taskIds = new Set(tasks.map(t => t.external_id));
  const adj = new Map<string, string[]>();
  const inDeg = new Map<string, number>();

  for (const id of taskIds) {
    adj.set(id, []);
    inDeg.set(id, 0);
  }

  for (const dep of deps) {
    if (!taskIds.has(dep.from_external_id) || !taskIds.has(dep.to_external_id)) continue;
    adj.get(dep.from_external_id)!.push(dep.to_external_id);
    inDeg.set(dep.to_external_id, (inDeg.get(dep.to_external_id) || 0) + 1);
  }

  // Kahn's algorithm
  const queue: string[] = [];
  for (const [id, deg] of inDeg) {
    if (deg === 0) queue.push(id);
  }

  let visited = 0;
  while (queue.length > 0) {
    const node = queue.shift()!;
    visited++;
    for (const neighbor of adj.get(node) || []) {
      const newDeg = (inDeg.get(neighbor) || 1) - 1;
      inDeg.set(neighbor, newDeg);
      if (newDeg === 0) queue.push(neighbor);
    }
  }

  if (visited < taskIds.size) {
    // Find one node in a cycle
    const unvisited = [...inDeg.entries()].find(([_, deg]) => deg > 0);
    return unvisited ? `task ${unvisited[0]}` : 'unknown cycle';
  }

  return null;
}

// ══════════════════════════════════════════════════════════════
// DATABASE IMPORT
// ══════════════════════════════════════════════════════════════

async function importSchedule(
  supabase: ReturnType<typeof createClient>,
  companyId: string,
  projectId: string,
  userId: string,
  parsed: ParsedSchedule,
  warnings: string[],
) {
  // Map external IDs → new ZAFTO UUIDs
  const taskIdMap = new Map<string, string>();
  const resourceIdMap = new Map<string, string>();

  // Insert tasks in batches
  let tasksImported = 0;
  for (let i = 0; i < parsed.tasks.length; i += 50) {
    const batch = parsed.tasks.slice(i, i + 50).map((t, idx) => ({
      company_id: companyId,
      project_id: projectId,
      name: t.name,
      wbs_code: t.wbs_code || null,
      task_type: t.task_type || 'task',
      original_duration: t.duration || null,
      remaining_duration: t.duration || null,
      planned_start: t.planned_start || null,
      planned_finish: t.planned_finish || null,
      percent_complete: t.percent_complete || 0,
      budgeted_cost: t.budgeted_cost || null,
      constraint_type: t.constraint_type || 'ASAP',
      constraint_date: t.constraint_date || null,
      sort_order: i + idx + 1,
      created_by: userId,
    }));

    const { data: inserted, error: insertErr } = await supabase
      .from('schedule_tasks')
      .insert(batch)
      .select('id');

    if (insertErr) {
      warnings.push(`Task batch insert error: ${insertErr.message}`);
      continue;
    }

    if (inserted) {
      for (let j = 0; j < inserted.length; j++) {
        const externalId = parsed.tasks[i + j].external_id;
        taskIdMap.set(externalId, inserted[j].id);
        tasksImported++;
      }
    }
  }

  // Insert resources
  let resourcesImported = 0;
  for (const res of parsed.resources) {
    const { data: inserted, error: resErr } = await supabase
      .from('schedule_resources')
      .insert({
        company_id: companyId,
        name: res.name,
        resource_type: res.resource_type || 'labor',
        cost_per_hour: res.cost_per_hour || 0,
        max_units: res.max_units || 1,
      })
      .select('id')
      .single();

    if (resErr) {
      warnings.push(`Resource insert error (${res.name}): ${resErr.message}`);
      continue;
    }

    if (inserted) {
      resourceIdMap.set(res.external_id, inserted.id);
      resourcesImported++;
    }
  }

  // Insert dependencies (filter out circular ones)
  let depsImported = 0;
  const validDeps = parsed.dependencies.filter(dep => {
    const fromId = taskIdMap.get(dep.from_external_id);
    const toId = taskIdMap.get(dep.to_external_id);
    return fromId && toId && fromId !== toId;
  });

  for (let i = 0; i < validDeps.length; i += 50) {
    const batch = validDeps.slice(i, i + 50).map(dep => ({
      company_id: companyId,
      project_id: projectId,
      predecessor_id: taskIdMap.get(dep.from_external_id)!,
      successor_id: taskIdMap.get(dep.to_external_id)!,
      dependency_type: dep.dependency_type || 'FS',
      lag_days: dep.lag_days || 0,
    }));

    const { error: depErr } = await supabase
      .from('schedule_dependencies')
      .insert(batch);

    if (depErr) {
      warnings.push(`Dependency batch insert error: ${depErr.message}`);
      continue;
    }
    depsImported += batch.length;
  }

  // Insert assignments
  let assignmentsImported = 0;
  for (const assign of parsed.assignments) {
    const taskId = taskIdMap.get(assign.task_external_id);
    const resourceId = resourceIdMap.get(assign.resource_external_id);
    if (!taskId || !resourceId) continue;

    const { error: assignErr } = await supabase
      .from('schedule_task_resources')
      .insert({
        company_id: companyId,
        task_id: taskId,
        resource_id: resourceId,
        units: assign.units || 1,
      });

    if (assignErr) {
      warnings.push(`Assignment error: ${assignErr.message}`);
      continue;
    }
    assignmentsImported++;
  }

  return {
    tasks_imported: tasksImported,
    dependencies_imported: depsImported,
    resources_imported: resourcesImported,
    assignments_imported: assignmentsImported,
  };
}

// ══════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
