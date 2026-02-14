// ZAFTO Schedule Engine TypeScript Types
// Interfaces matching all 12 schedule tables in Supabase.
// GC1: Phase GC foundation.

// ── Enums ──

export type ScheduleProjectStatus = 'draft' | 'active' | 'on_hold' | 'complete' | 'archived';
export type DurationUnit = 'hours' | 'days' | 'weeks';
export type ScheduleTaskType = 'task' | 'milestone' | 'summary' | 'hammock';
export type ConstraintType = 'asap' | 'alap' | 'snet' | 'snlt' | 'fnet' | 'fnlt' | 'mso' | 'mfo';
export type DependencyType = 'FS' | 'FF' | 'SS' | 'SF';
export type ResourceType = 'labor' | 'equipment' | 'material';
export type CalendarExceptionType = 'holiday' | 'weather' | 'overtime' | 'half_day' | 'shutdown';
export type TaskChangeType = 'created' | 'updated' | 'deleted' | 'moved' | 'progress' | 'dependency_added' | 'dependency_removed' | 'resource_added' | 'resource_removed' | 'cpm_recalculated';
export type ChangeSource = 'manual' | 'cpm_engine' | 'import' | 'integration' | 'resource_level';
export type LockType = 'edit' | 'progress' | 'drag';
export type ZoomLevel = 'hours' | 'days' | 'weeks' | 'months' | 'quarters' | 'years';

// ── 1. schedule_projects ──

export interface ScheduleProject {
  id: string;
  company_id: string;
  job_id: string | null;
  name: string;
  description: string | null;
  status: ScheduleProjectStatus;
  planned_start: string | null;
  planned_finish: string | null;
  actual_start: string | null;
  actual_finish: string | null;
  data_date: string | null;
  default_calendar_id: string | null;
  duration_unit: DurationUnit;
  hours_per_day: number;
  currency: string;
  overall_percent_complete: number;
  metadata: Record<string, unknown>;
  created_by: string | null;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
}

// ── 2. schedule_calendars ──

export interface ScheduleCalendar {
  id: string;
  company_id: string;
  name: string;
  description: string | null;
  calendar_type: 'standard' | 'custom';
  work_days_mask: number;
  work_start_time: string;
  work_end_time: string;
  hours_per_day: number;
  is_default: boolean;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
}

// ── 3. schedule_calendar_exceptions ──

export interface ScheduleCalendarException {
  id: string;
  company_id: string;
  calendar_id: string;
  exception_date: string;
  exception_type: CalendarExceptionType;
  name: string | null;
  work_start_time: string | null;
  work_end_time: string | null;
  hours_available: number | null;
  is_recurring: boolean;
  created_at: string;
  updated_at: string;
}

// ── 4. schedule_tasks ──

export interface ScheduleTask {
  id: string;
  company_id: string;
  project_id: string;
  parent_id: string | null;
  wbs_code: string | null;
  sort_order: number;
  indent_level: number;
  name: string;
  description: string | null;
  task_type: ScheduleTaskType;
  // Duration & Progress
  original_duration: number | null;
  remaining_duration: number | null;
  actual_duration: number | null;
  percent_complete: number;
  // Dates
  planned_start: string | null;
  planned_finish: string | null;
  actual_start: string | null;
  actual_finish: string | null;
  // CPM calculated
  early_start: string | null;
  early_finish: string | null;
  late_start: string | null;
  late_finish: string | null;
  total_float: number | null;
  free_float: number | null;
  is_critical: boolean;
  // Constraints
  constraint_type: ConstraintType;
  constraint_date: string | null;
  // Calendar override
  calendar_id: string | null;
  // ZAFTO integration
  job_id: string | null;
  estimate_item_id: string | null;
  assigned_to: string | null;
  // Costing
  budgeted_cost: number;
  actual_cost: number;
  // Display
  color: string | null;
  notes: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
}

// ── 5. schedule_dependencies ──

export interface ScheduleDependency {
  id: string;
  company_id: string;
  project_id: string;
  predecessor_id: string;
  successor_id: string;
  dependency_type: DependencyType;
  lag_days: number;
  created_at: string;
  updated_at: string;
}

// ── 6. schedule_resources ──

export interface ScheduleResource {
  id: string;
  company_id: string;
  name: string;
  resource_type: ResourceType;
  max_units: number;
  cost_per_hour: number;
  cost_per_unit: number;
  overtime_rate_multiplier: number;
  trade: string | null;
  role: string | null;
  user_id: string | null;
  calendar_id: string | null;
  color: string | null;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
}

// ── 7. schedule_task_resources ──

export interface ScheduleTaskResource {
  id: string;
  company_id: string;
  task_id: string;
  resource_id: string;
  units_assigned: number;
  hours_per_day: number | null;
  budgeted_cost: number;
  actual_cost: number;
  quantity_needed: number | null;
  quantity_used: number;
  created_at: string;
  updated_at: string;
}

// ── 8. schedule_baselines ──

export interface ScheduleBaseline {
  id: string;
  company_id: string;
  project_id: string;
  name: string;
  description: string | null;
  baseline_number: number;
  captured_at: string;
  captured_by: string | null;
  data_date: string | null;
  planned_start: string | null;
  planned_finish: string | null;
  total_tasks: number;
  total_milestones: number;
  total_cost: number;
  is_active: boolean;
  created_at: string;
}

// ── 9. schedule_baseline_tasks ──

export interface ScheduleBaselineTask {
  id: string;
  company_id: string;
  baseline_id: string;
  task_id: string;
  name: string | null;
  wbs_code: string | null;
  task_type: string | null;
  original_duration: number | null;
  planned_start: string | null;
  planned_finish: string | null;
  early_start: string | null;
  early_finish: string | null;
  late_start: string | null;
  late_finish: string | null;
  total_float: number | null;
  free_float: number | null;
  is_critical: boolean | null;
  budgeted_cost: number | null;
  percent_complete: number | null;
  created_at: string;
}

// ── 10. schedule_task_changes ──

export interface ScheduleTaskChange {
  id: string;
  company_id: string;
  project_id: string;
  task_id: string;
  change_type: TaskChangeType;
  field_name: string | null;
  old_value: string | null;
  new_value: string | null;
  changed_by: string | null;
  changed_at: string;
  source: ChangeSource;
  notes: string | null;
}

// ── 11. schedule_task_locks ──

export interface ScheduleTaskLock {
  id: string;
  company_id: string;
  task_id: string;
  locked_by: string;
  locked_at: string;
  expires_at: string;
  lock_type: LockType;
}

// ── 12. schedule_views ──

export interface ScheduleView {
  id: string;
  company_id: string;
  project_id: string;
  user_id: string;
  name: string;
  is_default: boolean;
  filters: Record<string, unknown>;
  visible_columns: string[];
  sort_by: string;
  sort_direction: 'asc' | 'desc';
  zoom_level: ZoomLevel;
  collapsed_tasks: string[];
  show_critical_path: boolean;
  show_float: boolean;
  show_baselines: boolean;
  show_dependencies: boolean;
  show_resources: boolean;
  show_progress: boolean;
  baseline_id: string | null;
  created_at: string;
  updated_at: string;
}

// ── Helper types for CPM engine ──

export interface CpmResult {
  tasks: ScheduleTask[];
  criticalPath: string[]; // task IDs on the critical path
  projectFinish: string | null;
  hasCycle: boolean;
  cyclePath?: string[]; // task IDs forming a cycle
}

export interface WorkCalendarConfig {
  calendar: ScheduleCalendar;
  exceptions: ScheduleCalendarException[];
}
