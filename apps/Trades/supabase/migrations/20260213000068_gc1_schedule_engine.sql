-- ============================================================================
-- GC1: Schedule Engine Foundation — 12 tables
-- Phase GC: Gantt & CPM Scheduling Engine
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1. schedule_calendars — Work calendar definitions
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE schedule_calendars (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name          text NOT NULL,
  description   text,
  calendar_type text NOT NULL DEFAULT 'standard' CHECK (calendar_type IN ('standard','custom')),
  work_days_mask integer NOT NULL DEFAULT 31, -- bitmask: Mon=1 Tue=2 Wed=4 Thu=8 Fri=16 Sat=32 Sun=64. 31=Mon-Fri
  work_start_time time NOT NULL DEFAULT '07:00',
  work_end_time   time NOT NULL DEFAULT '15:30',
  hours_per_day numeric NOT NULL DEFAULT 8,
  is_default    boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  deleted_at    timestamptz
);

ALTER TABLE schedule_calendars ENABLE ROW LEVEL SECURITY;
CREATE POLICY "schedule_calendars_select" ON schedule_calendars FOR SELECT USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY "schedule_calendars_insert" ON schedule_calendars FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "schedule_calendars_update" ON schedule_calendars FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "schedule_calendars_delete" ON schedule_calendars FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner','admin'));

CREATE INDEX idx_schedule_calendars_company ON schedule_calendars(company_id);
CREATE TRIGGER schedule_calendars_updated_at BEFORE UPDATE ON schedule_calendars FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ────────────────────────────────────────────────────────────────────────────
-- 2. schedule_calendar_exceptions — Holidays, weather days, overtime
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE schedule_calendar_exceptions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  calendar_id     uuid NOT NULL REFERENCES schedule_calendars(id) ON DELETE CASCADE,
  exception_date  date NOT NULL,
  exception_type  text NOT NULL DEFAULT 'holiday' CHECK (exception_type IN ('holiday','weather','overtime','half_day','shutdown')),
  name            text,
  work_start_time time,
  work_end_time   time,
  hours_available numeric,
  is_recurring    boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE schedule_calendar_exceptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "schedule_cal_exc_select" ON schedule_calendar_exceptions FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "schedule_cal_exc_insert" ON schedule_calendar_exceptions FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "schedule_cal_exc_update" ON schedule_calendar_exceptions FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "schedule_cal_exc_delete" ON schedule_calendar_exceptions FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner','admin'));

CREATE INDEX idx_schedule_cal_exc_calendar ON schedule_calendar_exceptions(calendar_id);
CREATE INDEX idx_schedule_cal_exc_date ON schedule_calendar_exceptions(calendar_id, exception_date);
CREATE TRIGGER schedule_cal_exc_updated_at BEFORE UPDATE ON schedule_calendar_exceptions FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ────────────────────────────────────────────────────────────────────────────
-- 3. schedule_projects — Project-level scheduling container
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE schedule_projects (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id              uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id                  uuid REFERENCES jobs(id) ON DELETE SET NULL,
  name                    text NOT NULL,
  description             text,
  status                  text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','on_hold','complete','archived')),
  planned_start           date,
  planned_finish          date,
  actual_start            date,
  actual_finish           date,
  data_date               date,
  default_calendar_id     uuid REFERENCES schedule_calendars(id) ON DELETE SET NULL,
  duration_unit           text NOT NULL DEFAULT 'days' CHECK (duration_unit IN ('hours','days','weeks')),
  hours_per_day           numeric NOT NULL DEFAULT 8,
  currency                text NOT NULL DEFAULT 'USD',
  overall_percent_complete numeric NOT NULL DEFAULT 0 CHECK (overall_percent_complete >= 0 AND overall_percent_complete <= 100),
  metadata                jsonb DEFAULT '{}',
  created_by              uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  deleted_at              timestamptz
);

ALTER TABLE schedule_projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "schedule_projects_select" ON schedule_projects FOR SELECT USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY "schedule_projects_insert" ON schedule_projects FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "schedule_projects_update" ON schedule_projects FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "schedule_projects_delete" ON schedule_projects FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner','admin'));

CREATE INDEX idx_schedule_projects_company ON schedule_projects(company_id);
CREATE INDEX idx_schedule_projects_job ON schedule_projects(job_id);
CREATE INDEX idx_schedule_projects_status ON schedule_projects(company_id, status);
CREATE TRIGGER schedule_projects_updated_at BEFORE UPDATE ON schedule_projects FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ────────────────────────────────────────────────────────────────────────────
-- 4. schedule_tasks — Core task with WBS hierarchy + CPM fields
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE schedule_tasks (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id        uuid NOT NULL REFERENCES schedule_projects(id) ON DELETE CASCADE,
  parent_id         uuid REFERENCES schedule_tasks(id) ON DELETE CASCADE,
  wbs_code          text,
  sort_order        integer NOT NULL DEFAULT 0,
  indent_level      integer NOT NULL DEFAULT 0,
  name              text NOT NULL,
  description       text,
  task_type         text NOT NULL DEFAULT 'task' CHECK (task_type IN ('task','milestone','summary','hammock')),
  -- Duration & Progress
  original_duration numeric,
  remaining_duration numeric,
  actual_duration   numeric,
  percent_complete  numeric NOT NULL DEFAULT 0 CHECK (percent_complete >= 0 AND percent_complete <= 100),
  -- Dates (user-entered or CPM-calculated)
  planned_start     date,
  planned_finish    date,
  actual_start      date,
  actual_finish     date,
  -- CPM calculated fields
  early_start       date,
  early_finish      date,
  late_start        date,
  late_finish       date,
  total_float       numeric,
  free_float        numeric,
  is_critical       boolean NOT NULL DEFAULT false,
  -- Constraints (P6-style)
  constraint_type   text NOT NULL DEFAULT 'asap' CHECK (constraint_type IN ('asap','alap','snet','snlt','fnet','fnlt','mso','mfo')),
  constraint_date   date,
  -- Calendar override
  calendar_id       uuid REFERENCES schedule_calendars(id) ON DELETE SET NULL,
  -- ZAFTO integration
  job_id            uuid REFERENCES jobs(id) ON DELETE SET NULL,
  estimate_item_id  uuid,
  assigned_to       uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  -- Costing
  budgeted_cost     numeric NOT NULL DEFAULT 0,
  actual_cost       numeric NOT NULL DEFAULT 0,
  -- Display
  color             text,
  notes             text,
  metadata          jsonb DEFAULT '{}',
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

ALTER TABLE schedule_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "schedule_tasks_select" ON schedule_tasks FOR SELECT USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY "schedule_tasks_insert" ON schedule_tasks FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "schedule_tasks_update" ON schedule_tasks FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "schedule_tasks_delete" ON schedule_tasks FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner','admin'));

CREATE INDEX idx_schedule_tasks_project ON schedule_tasks(project_id);
CREATE INDEX idx_schedule_tasks_parent ON schedule_tasks(parent_id);
CREATE INDEX idx_schedule_tasks_project_status ON schedule_tasks(project_id, task_type);
CREATE INDEX idx_schedule_tasks_critical ON schedule_tasks(project_id, is_critical) WHERE is_critical = true;
CREATE INDEX idx_schedule_tasks_sort ON schedule_tasks(project_id, sort_order);
CREATE INDEX idx_schedule_tasks_assigned ON schedule_tasks(assigned_to);
CREATE INDEX idx_schedule_tasks_job ON schedule_tasks(job_id);
CREATE INDEX idx_schedule_tasks_dates ON schedule_tasks(project_id, planned_start, planned_finish);
CREATE TRIGGER schedule_tasks_updated_at BEFORE UPDATE ON schedule_tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ────────────────────────────────────────────────────────────────────────────
-- 5. schedule_dependencies — FS, FF, SS, SF with lag/lead
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE schedule_dependencies (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id       uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id       uuid NOT NULL REFERENCES schedule_projects(id) ON DELETE CASCADE,
  predecessor_id   uuid NOT NULL REFERENCES schedule_tasks(id) ON DELETE CASCADE,
  successor_id     uuid NOT NULL REFERENCES schedule_tasks(id) ON DELETE CASCADE,
  dependency_type  text NOT NULL DEFAULT 'FS' CHECK (dependency_type IN ('FS','FF','SS','SF')),
  lag_days         numeric NOT NULL DEFAULT 0,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (predecessor_id, successor_id)
);

ALTER TABLE schedule_dependencies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "schedule_deps_select" ON schedule_dependencies FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "schedule_deps_insert" ON schedule_dependencies FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "schedule_deps_update" ON schedule_dependencies FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "schedule_deps_delete" ON schedule_dependencies FOR DELETE USING (company_id = requesting_company_id());

CREATE INDEX idx_schedule_deps_project ON schedule_dependencies(project_id);
CREATE INDEX idx_schedule_deps_predecessor ON schedule_dependencies(predecessor_id);
CREATE INDEX idx_schedule_deps_successor ON schedule_dependencies(successor_id);
CREATE TRIGGER schedule_deps_updated_at BEFORE UPDATE ON schedule_dependencies FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ────────────────────────────────────────────────────────────────────────────
-- 6. schedule_resources — Labor, equipment, material definitions
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE schedule_resources (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id             uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name                   text NOT NULL,
  resource_type          text NOT NULL DEFAULT 'labor' CHECK (resource_type IN ('labor','equipment','material')),
  max_units              numeric NOT NULL DEFAULT 1,
  cost_per_hour          numeric NOT NULL DEFAULT 0,
  cost_per_unit          numeric NOT NULL DEFAULT 0,
  overtime_rate_multiplier numeric NOT NULL DEFAULT 1.5,
  trade                  text,
  role                   text,
  user_id                uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  calendar_id            uuid REFERENCES schedule_calendars(id) ON DELETE SET NULL,
  color                  text,
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now(),
  deleted_at             timestamptz
);

ALTER TABLE schedule_resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "schedule_resources_select" ON schedule_resources FOR SELECT USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY "schedule_resources_insert" ON schedule_resources FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "schedule_resources_update" ON schedule_resources FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "schedule_resources_delete" ON schedule_resources FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner','admin'));

CREATE INDEX idx_schedule_resources_company ON schedule_resources(company_id);
CREATE INDEX idx_schedule_resources_type ON schedule_resources(company_id, resource_type);
CREATE INDEX idx_schedule_resources_user ON schedule_resources(user_id);
CREATE TRIGGER schedule_resources_updated_at BEFORE UPDATE ON schedule_resources FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ────────────────────────────────────────────────────────────────────────────
-- 7. schedule_task_resources — Resource allocation per task
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE schedule_task_resources (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  task_id         uuid NOT NULL REFERENCES schedule_tasks(id) ON DELETE CASCADE,
  resource_id     uuid NOT NULL REFERENCES schedule_resources(id) ON DELETE CASCADE,
  units_assigned  numeric NOT NULL DEFAULT 1,
  hours_per_day   numeric,
  budgeted_cost   numeric NOT NULL DEFAULT 0,
  actual_cost     numeric NOT NULL DEFAULT 0,
  quantity_needed numeric,
  quantity_used   numeric NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (task_id, resource_id)
);

ALTER TABLE schedule_task_resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "schedule_task_res_select" ON schedule_task_resources FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "schedule_task_res_insert" ON schedule_task_resources FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "schedule_task_res_update" ON schedule_task_resources FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "schedule_task_res_delete" ON schedule_task_resources FOR DELETE USING (company_id = requesting_company_id());

CREATE INDEX idx_schedule_task_res_task ON schedule_task_resources(task_id);
CREATE INDEX idx_schedule_task_res_resource ON schedule_task_resources(resource_id);
CREATE TRIGGER schedule_task_res_updated_at BEFORE UPDATE ON schedule_task_resources FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ────────────────────────────────────────────────────────────────────────────
-- 8. schedule_baselines — Named baseline snapshots
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE schedule_baselines (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id       uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id       uuid NOT NULL REFERENCES schedule_projects(id) ON DELETE CASCADE,
  name             text NOT NULL,
  description      text,
  baseline_number  integer NOT NULL DEFAULT 1,
  captured_at      timestamptz NOT NULL DEFAULT now(),
  captured_by      uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  data_date        date,
  planned_start    date,
  planned_finish   date,
  total_tasks      integer NOT NULL DEFAULT 0,
  total_milestones integer NOT NULL DEFAULT 0,
  total_cost       numeric NOT NULL DEFAULT 0,
  is_active        boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE schedule_baselines ENABLE ROW LEVEL SECURITY;
CREATE POLICY "schedule_baselines_select" ON schedule_baselines FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "schedule_baselines_insert" ON schedule_baselines FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "schedule_baselines_update" ON schedule_baselines FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "schedule_baselines_delete" ON schedule_baselines FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner','admin'));

CREATE INDEX idx_schedule_baselines_project ON schedule_baselines(project_id);
CREATE INDEX idx_schedule_baselines_active ON schedule_baselines(project_id, is_active) WHERE is_active = true;

-- ────────────────────────────────────────────────────────────────────────────
-- 9. schedule_baseline_tasks — Task state at baseline capture
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE schedule_baseline_tasks (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  baseline_id       uuid NOT NULL REFERENCES schedule_baselines(id) ON DELETE CASCADE,
  task_id           uuid NOT NULL REFERENCES schedule_tasks(id) ON DELETE CASCADE,
  name              text,
  wbs_code          text,
  task_type         text,
  original_duration numeric,
  planned_start     date,
  planned_finish    date,
  early_start       date,
  early_finish      date,
  late_start        date,
  late_finish       date,
  total_float       numeric,
  free_float        numeric,
  is_critical       boolean,
  budgeted_cost     numeric,
  percent_complete  numeric,
  created_at        timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE schedule_baseline_tasks ENABLE ROW LEVEL SECURITY;
-- Immutable: SELECT + INSERT only
CREATE POLICY "schedule_bl_tasks_select" ON schedule_baseline_tasks FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "schedule_bl_tasks_insert" ON schedule_baseline_tasks FOR INSERT WITH CHECK (company_id = requesting_company_id());

CREATE INDEX idx_schedule_bl_tasks_baseline ON schedule_baseline_tasks(baseline_id);
CREATE INDEX idx_schedule_bl_tasks_task ON schedule_baseline_tasks(task_id);

-- ────────────────────────────────────────────────────────────────────────────
-- 10. schedule_task_changes — Audit log of every task modification
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE schedule_task_changes (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id   uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id   uuid NOT NULL REFERENCES schedule_projects(id) ON DELETE CASCADE,
  task_id      uuid NOT NULL REFERENCES schedule_tasks(id) ON DELETE CASCADE,
  change_type  text NOT NULL CHECK (change_type IN ('created','updated','deleted','moved','progress','dependency_added','dependency_removed','resource_added','resource_removed','cpm_recalculated')),
  field_name   text,
  old_value    text,
  new_value    text,
  changed_by   uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  changed_at   timestamptz NOT NULL DEFAULT now(),
  source       text NOT NULL DEFAULT 'manual' CHECK (source IN ('manual','cpm_engine','import','integration','resource_level')),
  notes        text
);

ALTER TABLE schedule_task_changes ENABLE ROW LEVEL SECURITY;
-- Immutable: SELECT + INSERT only
CREATE POLICY "schedule_changes_select" ON schedule_task_changes FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "schedule_changes_insert" ON schedule_task_changes FOR INSERT WITH CHECK (company_id = requesting_company_id());

CREATE INDEX idx_schedule_changes_project ON schedule_task_changes(project_id);
CREATE INDEX idx_schedule_changes_task ON schedule_task_changes(task_id);
CREATE INDEX idx_schedule_changes_at ON schedule_task_changes(changed_at DESC);

-- ────────────────────────────────────────────────────────────────────────────
-- 11. schedule_task_locks — Pessimistic micro-locks for real-time editing
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE schedule_task_locks (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  task_id    uuid NOT NULL REFERENCES schedule_tasks(id) ON DELETE CASCADE,
  locked_by  uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  locked_at  timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '30 seconds'),
  lock_type  text NOT NULL DEFAULT 'edit' CHECK (lock_type IN ('edit','progress','drag')),
  UNIQUE (task_id)
);

ALTER TABLE schedule_task_locks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "schedule_locks_select" ON schedule_task_locks FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "schedule_locks_insert" ON schedule_task_locks FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "schedule_locks_update" ON schedule_task_locks FOR UPDATE USING (company_id = requesting_company_id() AND locked_by = auth.uid());
-- DELETE: owner of lock OR expired locks
CREATE POLICY "schedule_locks_delete" ON schedule_task_locks FOR DELETE USING (
  company_id = requesting_company_id() AND (locked_by = auth.uid() OR expires_at < now())
);

CREATE INDEX idx_schedule_locks_task ON schedule_task_locks(task_id);
CREATE INDEX idx_schedule_locks_expires ON schedule_task_locks(expires_at);

-- ────────────────────────────────────────────────────────────────────────────
-- 12. schedule_views — Saved filter/view configurations per user
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE schedule_views (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id          uuid NOT NULL REFERENCES schedule_projects(id) ON DELETE CASCADE,
  user_id             uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name                text NOT NULL,
  is_default          boolean NOT NULL DEFAULT false,
  filters             jsonb DEFAULT '{}',
  visible_columns     jsonb DEFAULT '["name","duration","start","finish","float","resources"]',
  sort_by             text NOT NULL DEFAULT 'sort_order',
  sort_direction      text NOT NULL DEFAULT 'asc' CHECK (sort_direction IN ('asc','desc')),
  zoom_level          text NOT NULL DEFAULT 'weeks' CHECK (zoom_level IN ('hours','days','weeks','months','quarters','years')),
  collapsed_tasks     jsonb DEFAULT '[]',
  show_critical_path  boolean NOT NULL DEFAULT true,
  show_float          boolean NOT NULL DEFAULT false,
  show_baselines      boolean NOT NULL DEFAULT false,
  show_dependencies   boolean NOT NULL DEFAULT true,
  show_resources      boolean NOT NULL DEFAULT false,
  show_progress       boolean NOT NULL DEFAULT true,
  baseline_id         uuid REFERENCES schedule_baselines(id) ON DELETE SET NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE schedule_views ENABLE ROW LEVEL SECURITY;
CREATE POLICY "schedule_views_select" ON schedule_views FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "schedule_views_insert" ON schedule_views FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "schedule_views_update" ON schedule_views FOR UPDATE USING (company_id = requesting_company_id() AND user_id = auth.uid());
CREATE POLICY "schedule_views_delete" ON schedule_views FOR DELETE USING (company_id = requesting_company_id() AND user_id = auth.uid());

CREATE INDEX idx_schedule_views_project_user ON schedule_views(project_id, user_id);
CREATE TRIGGER schedule_views_updated_at BEFORE UPDATE ON schedule_views FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ────────────────────────────────────────────────────────────────────────────
-- SEED: Default work calendars (company_id NULL = system-wide templates)
-- These get copied per-company on first schedule creation.
-- ────────────────────────────────────────────────────────────────────────────

-- Note: Seed calendars use a fixed company_id placeholder.
-- In practice, the app copies these templates when a company creates their first schedule.
-- For now, we create a helper function to clone system calendars.

-- ────────────────────────────────────────────────────────────────────────────
-- AUDIT TRIGGERS (business tables only — not locks/changes/baseline_tasks)
-- ────────────────────────────────────────────────────────────────────────────
-- audit_trigger_fn is already defined in earlier migrations.
-- Attach to business tables:
DO $$
BEGIN
  -- Only attach if audit_trigger_fn exists (it should from core migrations)
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'audit_trigger_fn') THEN
    CREATE TRIGGER schedule_projects_audit AFTER INSERT OR UPDATE OR DELETE ON schedule_projects FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
    CREATE TRIGGER schedule_tasks_audit AFTER INSERT OR UPDATE OR DELETE ON schedule_tasks FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
    CREATE TRIGGER schedule_calendars_audit AFTER INSERT OR UPDATE OR DELETE ON schedule_calendars FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
    CREATE TRIGGER schedule_resources_audit AFTER INSERT OR UPDATE OR DELETE ON schedule_resources FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
    CREATE TRIGGER schedule_dependencies_audit AFTER INSERT OR UPDATE OR DELETE ON schedule_dependencies FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
    CREATE TRIGGER schedule_baselines_audit AFTER INSERT OR UPDATE OR DELETE ON schedule_baselines FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
  END IF;
END;
$$;
