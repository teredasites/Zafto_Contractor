# Phase GC: Schedule
## Construction-Grade Critical Path Scheduling for Trade Contractors
### Created: February 11, 2026
### ~124 hours, 11 sprints (GC1-GC11)
### Builds after Phase SK (Sketch Engine), before Phase U (Unification)

---

> **DATABASE:** Supabase PostgreSQL. See `Locked/29_DATABASE_MIGRATION.md`.
> **SECURITY:** 6-layer architecture. See `Locked/30_SECURITY_ARCHITECTURE.md`.
> **MOBILE:** Flutter/Dart with `legacy_gantt_chart` (MIT). Offline-first via Hive/PowerSync.
> **WEB CRM:** Next.js 15 with DHTMLX Gantt PRO ($699/dev one-time). Real-time via Supabase Realtime.
> **PORTALS:** Team Portal (read-only + progress), Client Portal (milestones), Ops Portal (analytics).
> **BACKEND:** Supabase Edge Functions for CPM engine, resource leveling, and P6/MPP import/export.

---

## WHAT THIS IS

A construction-grade scheduling engine with full Critical Path Method (CPM) analysis, resource leveling, baseline management, P6/MS Project interoperability, and real-time multi-user collaboration. Connected to every part of the ZAFTO platform: jobs, estimates, team, field tools, Ledger, phone, and meetings.

**No competitor does:** Full CPM scheduling connected to CRM + estimates + team management + field tools + accounting + phone system + AI -- all in one platform, priced for the $0-$50M trade contractor market that enterprise tools ignore and trade platforms underserve.

---

## WHY THIS MATTERS

### The Scheduling Gap

There are two worlds in construction scheduling. Neither serves trade contractors.

**Enterprise World ($10K+/year):**
- Oracle Primavera P6: $2,570/user/year. Built for $50M+ GCs building hospitals and highways. 6-month learning curve. Desktop-first. No mobile field use. No CRM integration.
- Planera: ~$10K+/year. Modern web UI but targets the same enterprise GC market. No trade-specific features. No estimate integration. No field tools.
- Microsoft Project: $1,080/user/year (Plan 5). Generic project management. No construction logic. No CPM awareness. No resource leveling for crews.

**Trade Platform World ($0-200/month):**
- ServiceTitan: Calendar view and dispatch board. No Gantt. No CPM. No dependencies. No critical path. Scheduling means "assign a tech to a time slot."
- Jobber: Basic calendar scheduling. Drag jobs to dates. Zero dependency logic. Zero resource analysis.
- Buildertrend: Has a Gantt-style "schedule" view but no CPM engine, no float calculation, no resource leveling, no P6 interop. It is a colored timeline, not a scheduling engine.
- Contractor Foreman: Basic Gantt-like timeline. No CPM. No resource leveling. No import/export.

**The gap:** Nobody serves the $0-$50M trade contractor who needs real scheduling -- the electrician running 5 concurrent projects, the restoration company with 30 jobs across 8 crews, the remodeling GC juggling subs and materials across 12 active renovations. They need CPM to know what is actually critical. They need resource leveling to know when crews are overbooked. They need baseline comparison to prove schedule delays. And they need it connected to their jobs, estimates, team, and accounting -- not in a $10K standalone tool.

### What This Replaces

| Current Tool | Annual Cost | What ZAFTO Replaces |
|-------------|-----------|-------------------|
| Primavera P6 | $2,570/user/yr | Full CPM + resource leveling + baselines + P6 import/export |
| Planera | ~$10,000+/yr | Web Gantt + CPM + collaboration |
| MS Project | $1,080/user/yr | Gantt + dependencies + resource allocation |
| Buildertrend scheduling | $499-899/mo | Connected schedule + job + estimate + team |
| Contractor Foreman | $49-148/mo | Gantt + basic scheduling |
| Excel/whiteboards | $0 + pain | Everything above + actually works |

---

## COMPETITIVE ANALYSIS

| Feature | Primavera P6 | Planera | Buildertrend | ServiceTitan | Contractor Foreman | **ZAFTO** |
|---------|-------------|---------|-------------|-------------|-------------------|-----------|
| Full CPM engine | Yes | Yes | No | No | No | **Yes** |
| 4 dependency types (FS/FF/SS/SF) | Yes | Yes | FS only | No | FS only | **Yes** |
| 8 constraint types | Yes | Partial | No | No | No | **Yes** |
| Float calculation | Yes | Yes | No | No | No | **Yes** |
| Resource leveling | Yes | Partial | No | No | No | **Yes** |
| Baseline comparison | Yes | Yes | No | No | No | **Yes** |
| P6 .XER import/export | Native | Yes | No | No | No | **Yes** |
| MS Project import | Yes | Yes | No | No | No | **Yes** |
| Real-time collaboration | No (file-based) | Yes | Partial | No | No | **Yes** |
| Mobile field use | No | Partial | Yes | Yes | Yes | **Yes (offline)** |
| CRM integration | No | No | Partial | Partial | Partial | **Yes (full)** |
| Estimate integration | No | No | Partial | No | No | **Yes (D8 engine)** |
| Team/crew management | No | No | Partial | Yes | Partial | **Yes (full RBAC)** |
| Field tool integration | No | No | Partial | No | No | **Yes (photos, logs, punch)** |
| Accounting integration | No | No | Partial | No | No | **Yes (Ledger)** |
| Phone/meeting system | No | No | No | Dispatch only | No | **Yes** |
| AI scheduling assist | No | No | No | No | No | **Yes (Phase E)** |
| Price per user/year | $2,570 | ~$10,000+ | $5,988-10,788 | $3,000+ | $588-1,776 | **Included** |

**ZAFTO's position:** Enterprise scheduling power at trade contractor pricing. The only platform where your schedule talks to your jobs, estimates, team, field tools, books, phone, and AI.

---

## DATABASE SCHEMA (12 Tables)

### Migration: `gc1_schedule_engine.sql`

```sql
-- ============================================================
-- PHASE GC: GANTT & CPM SCHEDULING ENGINE
-- 12 tables, full RLS, audit triggers, indexes
-- ============================================================

-- ============================================================
-- 1. schedule_projects — Project-level scheduling container
-- ============================================================
CREATE TABLE schedule_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Link to ZAFTO ecosystem (optional — can be standalone schedule)
  job_id UUID REFERENCES jobs(id),

  -- Project info
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
    'draft', 'active', 'on_hold', 'complete', 'archived'
  )),

  -- Schedule boundaries
  planned_start DATE,
  planned_finish DATE,
  actual_start DATE,
  actual_finish DATE,

  -- Data date — the "as of" date for CPM calculations
  data_date DATE DEFAULT CURRENT_DATE,

  -- Calendar reference
  default_calendar_id UUID, -- FK added after schedule_calendars created

  -- Settings
  duration_unit TEXT NOT NULL DEFAULT 'days' CHECK (duration_unit IN ('hours', 'days', 'weeks')),
  hours_per_day NUMERIC NOT NULL DEFAULT 8,
  currency TEXT NOT NULL DEFAULT 'USD',

  -- Progress
  overall_percent_complete NUMERIC DEFAULT 0 CHECK (overall_percent_complete >= 0 AND overall_percent_complete <= 100),

  -- Metadata
  metadata JSONB DEFAULT '{}',
  created_by UUID NOT NULL REFERENCES users(id),
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE schedule_projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "schedule_projects_select" ON schedule_projects
  FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "schedule_projects_insert" ON schedule_projects
  FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "schedule_projects_update" ON schedule_projects
  FOR UPDATE USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "schedule_projects_delete" ON schedule_projects
  FOR DELETE USING (company_id = auth.company_id() AND auth.user_role() IN ('owner', 'admin'));

CREATE INDEX idx_schedule_projects_company ON schedule_projects(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_schedule_projects_job ON schedule_projects(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX idx_schedule_projects_status ON schedule_projects(company_id, status) WHERE deleted_at IS NULL;

CREATE TRIGGER schedule_projects_updated_at
  BEFORE UPDATE ON schedule_projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER schedule_projects_audit
  AFTER INSERT OR UPDATE OR DELETE ON schedule_projects
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 2. schedule_calendars — Work calendar definitions
-- ============================================================
CREATE TABLE schedule_calendars (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  name TEXT NOT NULL,                           -- "5-Day Work Week", "6-Day", "Night Shift"
  description TEXT,
  calendar_type TEXT NOT NULL DEFAULT 'standard' CHECK (calendar_type IN (
    'standard', 'custom'
  )),

  -- Work days (bitmask: Mon=1, Tue=2, Wed=4, Thu=8, Fri=16, Sat=32, Sun=64)
  -- 5-day = 31 (Mon-Fri), 6-day = 63 (Mon-Sat), 7-day = 127
  work_days_mask INTEGER NOT NULL DEFAULT 31,

  -- Daily work hours
  work_start_time TIME NOT NULL DEFAULT '07:00',
  work_end_time TIME NOT NULL DEFAULT '15:30',
  hours_per_day NUMERIC NOT NULL DEFAULT 8,

  -- Default flag
  is_default BOOLEAN DEFAULT false,

  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE schedule_calendars ENABLE ROW LEVEL SECURITY;

CREATE POLICY "schedule_calendars_select" ON schedule_calendars
  FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "schedule_calendars_insert" ON schedule_calendars
  FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "schedule_calendars_update" ON schedule_calendars
  FOR UPDATE USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "schedule_calendars_delete" ON schedule_calendars
  FOR DELETE USING (company_id = auth.company_id() AND auth.user_role() IN ('owner', 'admin'));

CREATE INDEX idx_schedule_calendars_company ON schedule_calendars(company_id) WHERE deleted_at IS NULL;

-- Add FK from schedule_projects to schedule_calendars now that table exists
ALTER TABLE schedule_projects
  ADD CONSTRAINT fk_schedule_projects_calendar
  FOREIGN KEY (default_calendar_id) REFERENCES schedule_calendars(id);

CREATE TRIGGER schedule_calendars_updated_at
  BEFORE UPDATE ON schedule_calendars
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER schedule_calendars_audit
  AFTER INSERT OR UPDATE OR DELETE ON schedule_calendars
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 3. schedule_calendar_exceptions — Holidays, weather, overtime
-- ============================================================
CREATE TABLE schedule_calendar_exceptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  calendar_id UUID NOT NULL REFERENCES schedule_calendars(id) ON DELETE CASCADE,

  exception_date DATE NOT NULL,
  exception_type TEXT NOT NULL CHECK (exception_type IN (
    'holiday',        -- Non-working day (company holiday, federal holiday)
    'weather',        -- Non-working day (weather delay)
    'overtime',       -- Working day on normally non-working day (Saturday OT)
    'half_day',       -- Partial working day
    'shutdown'        -- Company shutdown (plant turnaround, etc.)
  )),

  name TEXT,                                     -- "New Year's Day", "Hurricane Milton", "Saturday OT"

  -- For overtime/half_day: custom hours for this exception date
  work_start_time TIME,
  work_end_time TIME,
  hours_available NUMERIC,

  is_recurring BOOLEAN DEFAULT false,            -- Repeats annually (holidays)

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE schedule_calendar_exceptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "schedule_calendar_exceptions_select" ON schedule_calendar_exceptions
  FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "schedule_calendar_exceptions_insert" ON schedule_calendar_exceptions
  FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "schedule_calendar_exceptions_update" ON schedule_calendar_exceptions
  FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "schedule_calendar_exceptions_delete" ON schedule_calendar_exceptions
  FOR DELETE USING (company_id = auth.company_id());

CREATE INDEX idx_schedule_calendar_exceptions_calendar ON schedule_calendar_exceptions(calendar_id);
CREATE INDEX idx_schedule_calendar_exceptions_date ON schedule_calendar_exceptions(calendar_id, exception_date);

CREATE TRIGGER schedule_calendar_exceptions_updated_at
  BEFORE UPDATE ON schedule_calendar_exceptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 4. schedule_tasks — Core task with WBS hierarchy + CPM fields
-- ============================================================
CREATE TABLE schedule_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES schedule_projects(id) ON DELETE CASCADE,

  -- WBS hierarchy
  parent_id UUID REFERENCES schedule_tasks(id) ON DELETE CASCADE,  -- NULL = top-level
  wbs_code TEXT,                                 -- "1.2.3" — auto-generated or manual
  sort_order INTEGER NOT NULL DEFAULT 0,
  indent_level INTEGER NOT NULL DEFAULT 0,

  -- Task identity
  name TEXT NOT NULL,
  description TEXT,
  task_type TEXT NOT NULL DEFAULT 'task' CHECK (task_type IN (
    'task',          -- Normal work activity with duration
    'milestone',     -- Zero-duration marker event
    'summary',       -- Roll-up of child tasks (auto-calculated)
    'hammock'        -- Duration determined by predecessor/successor relationship
  )),

  -- Duration and progress
  original_duration NUMERIC,                     -- Planned duration in project duration_unit
  remaining_duration NUMERIC,                    -- Duration remaining
  actual_duration NUMERIC,                       -- Duration completed
  percent_complete NUMERIC DEFAULT 0 CHECK (percent_complete >= 0 AND percent_complete <= 100),

  -- Dates (user-entered or CPM-calculated)
  planned_start DATE,
  planned_finish DATE,
  actual_start DATE,
  actual_finish DATE,

  -- CPM calculated fields (populated by schedule-calculate-cpm Edge Function)
  early_start DATE,
  early_finish DATE,
  late_start DATE,
  late_finish DATE,
  total_float NUMERIC,                           -- Late Start - Early Start (in work days)
  free_float NUMERIC,                            -- Min(successor ES) - Early Finish (in work days)
  is_critical BOOLEAN DEFAULT false,             -- Total Float <= 0

  -- Constraint types (matching Primavera P6 constraint system)
  constraint_type TEXT DEFAULT 'asap' CHECK (constraint_type IN (
    'asap',    -- As Soon As Possible (default)
    'alap',    -- As Late As Possible
    'snet',    -- Start No Earlier Than
    'snlt',    -- Start No Later Than
    'fnet',    -- Finish No Earlier Than
    'fnlt',    -- Finish No Later Than
    'mso',     -- Must Start On
    'mfo'      -- Must Finish On
  )),
  constraint_date DATE,                          -- Required for all constraint types except asap/alap

  -- Calendar override (NULL = use project default calendar)
  calendar_id UUID REFERENCES schedule_calendars(id),

  -- ZAFTO integration links
  job_id UUID REFERENCES jobs(id),               -- Link task back to a ZAFTO job
  estimate_item_id UUID,                         -- Link to estimate line item (FK deferred)
  assigned_to UUID REFERENCES users(id),         -- Primary assignee

  -- Cost loading (feeds Ledger)
  budgeted_cost NUMERIC DEFAULT 0,
  actual_cost NUMERIC DEFAULT 0,

  -- Visual
  color TEXT,                                    -- Hex color override for Gantt bar
  notes TEXT,

  -- Metadata
  metadata JSONB DEFAULT '{}',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE schedule_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "schedule_tasks_select" ON schedule_tasks
  FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "schedule_tasks_insert" ON schedule_tasks
  FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "schedule_tasks_update" ON schedule_tasks
  FOR UPDATE USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "schedule_tasks_delete" ON schedule_tasks
  FOR DELETE USING (company_id = auth.company_id());

CREATE INDEX idx_schedule_tasks_project ON schedule_tasks(project_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_schedule_tasks_parent ON schedule_tasks(parent_id) WHERE parent_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_schedule_tasks_critical ON schedule_tasks(project_id, is_critical) WHERE is_critical = true AND deleted_at IS NULL;
CREATE INDEX idx_schedule_tasks_job ON schedule_tasks(job_id) WHERE job_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_schedule_tasks_assigned ON schedule_tasks(assigned_to) WHERE assigned_to IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_schedule_tasks_sort ON schedule_tasks(project_id, sort_order) WHERE deleted_at IS NULL;

CREATE TRIGGER schedule_tasks_updated_at
  BEFORE UPDATE ON schedule_tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER schedule_tasks_audit
  AFTER INSERT OR UPDATE OR DELETE ON schedule_tasks
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 5. schedule_dependencies — FS, FF, SS, SF with lag/lead
-- ============================================================
CREATE TABLE schedule_dependencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES schedule_projects(id) ON DELETE CASCADE,

  predecessor_id UUID NOT NULL REFERENCES schedule_tasks(id) ON DELETE CASCADE,
  successor_id UUID NOT NULL REFERENCES schedule_tasks(id) ON DELETE CASCADE,

  dependency_type TEXT NOT NULL DEFAULT 'FS' CHECK (dependency_type IN (
    'FS',    -- Finish-to-Start (most common: B can't start until A finishes)
    'FF',    -- Finish-to-Finish (B can't finish until A finishes)
    'SS',    -- Start-to-Start (B can't start until A starts)
    'SF'     -- Start-to-Finish (B can't finish until A starts — rare)
  )),

  -- Lag/Lead in work days (positive = lag/delay, negative = lead/overlap)
  lag_days NUMERIC DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- Prevent duplicate dependency between same pair
  UNIQUE(predecessor_id, successor_id)
);

ALTER TABLE schedule_dependencies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "schedule_dependencies_select" ON schedule_dependencies
  FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "schedule_dependencies_insert" ON schedule_dependencies
  FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "schedule_dependencies_update" ON schedule_dependencies
  FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "schedule_dependencies_delete" ON schedule_dependencies
  FOR DELETE USING (company_id = auth.company_id());

CREATE INDEX idx_schedule_dependencies_project ON schedule_dependencies(project_id);
CREATE INDEX idx_schedule_dependencies_predecessor ON schedule_dependencies(predecessor_id);
CREATE INDEX idx_schedule_dependencies_successor ON schedule_dependencies(successor_id);

CREATE TRIGGER schedule_dependencies_updated_at
  BEFORE UPDATE ON schedule_dependencies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 6. schedule_baselines — Named baseline snapshots
-- ============================================================
CREATE TABLE schedule_baselines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES schedule_projects(id) ON DELETE CASCADE,

  name TEXT NOT NULL,                            -- "Original Baseline", "Rev 1 — Owner Change", "Weather Delay"
  description TEXT,
  baseline_number INTEGER NOT NULL,              -- 1, 2, 3... per project

  -- Snapshot metadata
  captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  captured_by UUID NOT NULL REFERENCES users(id),
  data_date DATE NOT NULL,                       -- Data date at time of capture

  -- Project-level snapshot
  planned_start DATE,
  planned_finish DATE,
  total_tasks INTEGER,
  total_milestones INTEGER,
  total_cost NUMERIC,

  is_active BOOLEAN DEFAULT true,                -- Currently displayed baseline

  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE schedule_baselines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "schedule_baselines_select" ON schedule_baselines
  FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "schedule_baselines_insert" ON schedule_baselines
  FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "schedule_baselines_update" ON schedule_baselines
  FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "schedule_baselines_delete" ON schedule_baselines
  FOR DELETE USING (company_id = auth.company_id() AND auth.user_role() IN ('owner', 'admin'));

CREATE INDEX idx_schedule_baselines_project ON schedule_baselines(project_id);
CREATE INDEX idx_schedule_baselines_active ON schedule_baselines(project_id, is_active) WHERE is_active = true;

CREATE TRIGGER schedule_baselines_audit
  AFTER INSERT OR UPDATE OR DELETE ON schedule_baselines
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 7. schedule_baseline_tasks — Task state at baseline capture
-- ============================================================
CREATE TABLE schedule_baseline_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  baseline_id UUID NOT NULL REFERENCES schedule_baselines(id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES schedule_tasks(id) ON DELETE CASCADE,

  -- Snapshot of task state at baseline capture
  name TEXT NOT NULL,
  wbs_code TEXT,
  task_type TEXT NOT NULL,

  original_duration NUMERIC,
  planned_start DATE,
  planned_finish DATE,

  early_start DATE,
  early_finish DATE,
  late_start DATE,
  late_finish DATE,
  total_float NUMERIC,
  free_float NUMERIC,
  is_critical BOOLEAN,

  budgeted_cost NUMERIC DEFAULT 0,
  percent_complete NUMERIC DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE schedule_baseline_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "schedule_baseline_tasks_select" ON schedule_baseline_tasks
  FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "schedule_baseline_tasks_insert" ON schedule_baseline_tasks
  FOR INSERT WITH CHECK (company_id = auth.company_id());

CREATE INDEX idx_schedule_baseline_tasks_baseline ON schedule_baseline_tasks(baseline_id);
CREATE INDEX idx_schedule_baseline_tasks_task ON schedule_baseline_tasks(task_id);


-- ============================================================
-- 8. schedule_resources — Resource type definitions
-- ============================================================
CREATE TABLE schedule_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  name TEXT NOT NULL,                            -- "Electrician Crew A", "Boom Lift", "Copper Wire 12/2"
  resource_type TEXT NOT NULL CHECK (resource_type IN (
    'labor',         -- Crews or individuals
    'equipment',     -- Machinery, tools, vehicles
    'material'       -- Consumable materials
  )),

  -- Capacity
  max_units NUMERIC NOT NULL DEFAULT 1,          -- Labor: crew size (3 electricians). Equipment: 1 (single-use). Material: available quantity.
  cost_per_hour NUMERIC DEFAULT 0,               -- Labor/equipment hourly rate
  cost_per_unit NUMERIC DEFAULT 0,               -- Material cost per unit
  overtime_rate_multiplier NUMERIC DEFAULT 1.5,   -- OT multiplier for labor

  -- Labor-specific
  trade TEXT,                                    -- electrical, plumbing, hvac, general, etc.
  role TEXT,                                     -- journeyman, apprentice, foreman, etc.

  -- Link to ZAFTO employees (for labor resources)
  user_id UUID REFERENCES users(id),             -- Maps to a specific ZAFTO employee

  -- Calendar override (e.g., night-shift crew has different calendar)
  calendar_id UUID REFERENCES schedule_calendars(id),

  color TEXT,                                    -- Hex color for resource histogram

  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE schedule_resources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "schedule_resources_select" ON schedule_resources
  FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "schedule_resources_insert" ON schedule_resources
  FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "schedule_resources_update" ON schedule_resources
  FOR UPDATE USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "schedule_resources_delete" ON schedule_resources
  FOR DELETE USING (company_id = auth.company_id());

CREATE INDEX idx_schedule_resources_company ON schedule_resources(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_schedule_resources_type ON schedule_resources(company_id, resource_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_schedule_resources_user ON schedule_resources(user_id) WHERE user_id IS NOT NULL AND deleted_at IS NULL;

CREATE TRIGGER schedule_resources_updated_at
  BEFORE UPDATE ON schedule_resources
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER schedule_resources_audit
  AFTER INSERT OR UPDATE OR DELETE ON schedule_resources
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 9. schedule_task_resources — Resource allocation per task
-- ============================================================
CREATE TABLE schedule_task_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES schedule_tasks(id) ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES schedule_resources(id) ON DELETE CASCADE,

  -- Allocation
  units_assigned NUMERIC NOT NULL DEFAULT 1,     -- How many units of this resource (e.g., 2 of 3 electricians)
  hours_per_day NUMERIC,                         -- Override: hours this resource works per day on this task

  -- Cost
  budgeted_cost NUMERIC DEFAULT 0,               -- Calculated: units * rate * duration
  actual_cost NUMERIC DEFAULT 0,

  -- Material-specific
  quantity_needed NUMERIC,                       -- Material: total quantity required
  quantity_used NUMERIC DEFAULT 0,               -- Material: quantity consumed so far

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  UNIQUE(task_id, resource_id)
);

ALTER TABLE schedule_task_resources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "schedule_task_resources_select" ON schedule_task_resources
  FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "schedule_task_resources_insert" ON schedule_task_resources
  FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "schedule_task_resources_update" ON schedule_task_resources
  FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "schedule_task_resources_delete" ON schedule_task_resources
  FOR DELETE USING (company_id = auth.company_id());

CREATE INDEX idx_schedule_task_resources_task ON schedule_task_resources(task_id);
CREATE INDEX idx_schedule_task_resources_resource ON schedule_task_resources(resource_id);

CREATE TRIGGER schedule_task_resources_updated_at
  BEFORE UPDATE ON schedule_task_resources
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 10. schedule_task_changes — Audit log of every task modification
-- ============================================================
CREATE TABLE schedule_task_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES schedule_projects(id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES schedule_tasks(id) ON DELETE CASCADE,

  change_type TEXT NOT NULL CHECK (change_type IN (
    'created', 'updated', 'deleted', 'moved', 'progress',
    'dependency_added', 'dependency_removed',
    'resource_added', 'resource_removed',
    'cpm_recalculated'
  )),

  -- What changed
  field_name TEXT,                               -- "planned_start", "duration", "percent_complete", etc.
  old_value TEXT,                                -- Previous value (as text)
  new_value TEXT,                                -- New value (as text)

  -- Who/when
  changed_by UUID NOT NULL REFERENCES users(id),
  changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Source
  source TEXT DEFAULT 'manual' CHECK (source IN (
    'manual',        -- User edit
    'cpm_engine',    -- CPM recalculation
    'import',        -- P6/MPP import
    'integration',   -- ZAFTO system integration (job progress, field tool)
    'resource_level' -- Resource leveling adjustment
  )),

  notes TEXT
);

ALTER TABLE schedule_task_changes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "schedule_task_changes_select" ON schedule_task_changes
  FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "schedule_task_changes_insert" ON schedule_task_changes
  FOR INSERT WITH CHECK (company_id = auth.company_id());

CREATE INDEX idx_schedule_task_changes_project ON schedule_task_changes(project_id);
CREATE INDEX idx_schedule_task_changes_task ON schedule_task_changes(task_id);
CREATE INDEX idx_schedule_task_changes_date ON schedule_task_changes(changed_at DESC);


-- ============================================================
-- 11. schedule_task_locks — Pessimistic micro-locks for real-time
-- ============================================================
CREATE TABLE schedule_task_locks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES schedule_tasks(id) ON DELETE CASCADE,

  locked_by UUID NOT NULL REFERENCES users(id),
  locked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '30 seconds'),

  -- Lock scope
  lock_type TEXT NOT NULL DEFAULT 'edit' CHECK (lock_type IN (
    'edit',          -- Full task edit lock
    'progress',      -- Progress update only
    'drag'           -- Gantt bar drag operation
  )),

  UNIQUE(task_id)  -- Only one lock per task at a time
);

ALTER TABLE schedule_task_locks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "schedule_task_locks_select" ON schedule_task_locks
  FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "schedule_task_locks_insert" ON schedule_task_locks
  FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "schedule_task_locks_update" ON schedule_task_locks
  FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "schedule_task_locks_delete" ON schedule_task_locks
  FOR DELETE USING (company_id = auth.company_id());

CREATE INDEX idx_schedule_task_locks_task ON schedule_task_locks(task_id);
CREATE INDEX idx_schedule_task_locks_expires ON schedule_task_locks(expires_at);

-- Auto-clean expired locks (run via pg_cron or Edge Function every 60s)
-- DELETE FROM schedule_task_locks WHERE expires_at < now();


-- ============================================================
-- 12. schedule_views — Saved filter/view configurations per user
-- ============================================================
CREATE TABLE schedule_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES schedule_projects(id) ON DELETE CASCADE,

  user_id UUID NOT NULL REFERENCES users(id),

  name TEXT NOT NULL,                            -- "Critical Path Only", "My Tasks", "Next 2 Weeks"
  is_default BOOLEAN DEFAULT false,

  -- View configuration
  filters JSONB DEFAULT '{}',                    -- {"is_critical": true, "assigned_to": "uuid", "status": "in_progress"}
  visible_columns JSONB DEFAULT '[]',            -- ["name", "duration", "start", "finish", "float", "resources"]
  sort_by TEXT DEFAULT 'sort_order',
  sort_direction TEXT DEFAULT 'asc' CHECK (sort_direction IN ('asc', 'desc')),
  zoom_level TEXT DEFAULT 'weeks' CHECK (zoom_level IN ('hours', 'days', 'weeks', 'months', 'quarters', 'years')),
  collapsed_tasks JSONB DEFAULT '[]',            -- Array of collapsed summary task IDs

  -- Gantt display options
  show_critical_path BOOLEAN DEFAULT true,
  show_float BOOLEAN DEFAULT false,
  show_baselines BOOLEAN DEFAULT false,
  show_dependencies BOOLEAN DEFAULT true,
  show_resources BOOLEAN DEFAULT false,
  show_progress BOOLEAN DEFAULT true,
  baseline_id UUID REFERENCES schedule_baselines(id), -- Which baseline to display

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE schedule_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "schedule_views_select" ON schedule_views
  FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "schedule_views_insert" ON schedule_views
  FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "schedule_views_update" ON schedule_views
  FOR UPDATE USING (company_id = auth.company_id() AND user_id = auth.uid());
CREATE POLICY "schedule_views_delete" ON schedule_views
  FOR DELETE USING (company_id = auth.company_id() AND user_id = auth.uid());

CREATE INDEX idx_schedule_views_project_user ON schedule_views(project_id, user_id);

CREATE TRIGGER schedule_views_updated_at
  BEFORE UPDATE ON schedule_views
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

---

## CPM ENGINE SPECIFICATION

### Edge Function: `schedule-calculate-cpm`

The heart of the scheduling engine. Implements the Critical Path Method as a Supabase Edge Function (Deno/TypeScript). Triggered on any task or dependency change. Returns updated CPM fields for all affected tasks in the project.

### Algorithm Overview

```
INPUT:  All tasks + dependencies for a project
OUTPUT: early_start, early_finish, late_start, late_finish, total_float, free_float, is_critical for every task

1. FORWARD PASS (earliest possible dates)
   - Topological sort all tasks by dependency graph
   - For each task in topological order:
     a. If no predecessors: early_start = project.planned_start
     b. If has predecessors: early_start = MAX(predecessor early dates + lag, adjusted by dependency type)
     c. Apply constraint (see constraint logic below)
     d. early_finish = early_start + duration (in work days, respecting calendar)

2. BACKWARD PASS (latest allowable dates)
   - For each task in REVERSE topological order:
     a. If no successors: late_finish = project.planned_finish (or max early_finish if no project finish)
     b. If has successors: late_finish = MIN(successor late dates - lag, adjusted by dependency type)
     c. Apply constraint (see constraint logic below)
     d. late_start = late_finish - duration (in work days, respecting calendar)

3. FLOAT CALCULATION
   - Total Float = late_start - early_start (in work days)
   - Free Float = MIN(all successor early_start) - early_finish - lag (in work days)
   - For FS: free_float = successor.early_start - this.early_finish - lag
   - For FF: free_float = successor.early_finish - this.early_finish - lag
   - For SS: free_float = successor.early_start - this.early_start - lag
   - For SF: free_float = successor.early_finish - this.early_start - lag

4. CRITICAL PATH IDENTIFICATION
   - is_critical = (total_float <= 0)
   - Critical path = connected chain of critical tasks from project start to project finish
```

### Dependency Type Logic

```
FORWARD PASS — Early Start calculation for successor:

FS (Finish-to-Start):
  successor.early_start >= predecessor.early_finish + lag
  "B can't start until A finishes (+ lag days)"

FF (Finish-to-Finish):
  successor.early_finish >= predecessor.early_finish + lag
  successor.early_start = successor.early_finish - successor.duration
  "B can't finish until A finishes (+ lag days)"

SS (Start-to-Start):
  successor.early_start >= predecessor.early_start + lag
  "B can't start until A starts (+ lag days)"

SF (Start-to-Finish):
  successor.early_finish >= predecessor.early_start + lag
  successor.early_start = successor.early_finish - successor.duration
  "B can't finish until A starts (+ lag days)"

BACKWARD PASS — Late Finish calculation for predecessor:

FS: predecessor.late_finish <= successor.late_start - lag
FF: predecessor.late_finish <= successor.late_finish - lag
SS: predecessor.late_start <= successor.late_start - lag
SF: predecessor.late_start <= successor.late_finish - lag
```

### Constraint Type Logic (Matching Primavera P6)

```
ASAP (As Soon As Possible) — DEFAULT
  No constraint applied. Task scheduled at earliest possible date.

ALAP (As Late As Possible)
  Forward pass: no change.
  Backward pass: task uses late dates as its schedule dates.
  Use case: delay non-critical work to preserve flexibility.

SNET (Start No Earlier Than)
  Forward pass: early_start = MAX(calculated_early_start, constraint_date)
  Backward pass: no change.
  Use case: material delivery date, permit approval expected date.

SNLT (Start No Later Than)
  Forward pass: no change.
  Backward pass: late_start = MIN(calculated_late_start, constraint_date)
  Use case: seasonal deadline, weather window.

FNET (Finish No Earlier Than)
  Forward pass: early_finish = MAX(calculated_early_finish, constraint_date)
  Backward pass: no change.
  Use case: concrete cure time, inspection scheduling.

FNLT (Finish No Later Than)
  Forward pass: no change.
  Backward pass: late_finish = MIN(calculated_late_finish, constraint_date)
  Use case: contractual completion deadline.

MSO (Must Start On)
  Forward pass: early_start = constraint_date (forced)
  Backward pass: late_start = constraint_date (forced)
  Use case: fixed external event (crane delivery, utility shutdown).
  WARNING: Can cause negative float. Flag to user.

MFO (Must Finish On)
  Forward pass: early_finish = constraint_date (forced)
  Backward pass: late_finish = constraint_date (forced)
  Use case: contractual milestone deadline.
  WARNING: Can cause negative float. Flag to user.
```

### Calendar-Aware Date Math

```
addWorkDays(startDate, workDays, calendarId):
  1. Load calendar (work_days_mask, work hours, exceptions)
  2. Starting from startDate, count forward through calendar
  3. Skip non-work days (weekends per mask)
  4. Skip exception days (holidays, weather, shutdowns)
  5. Count overtime/half-day exceptions as work days with adjusted hours
  6. Return the date after workDays of actual work time

subtractWorkDays(endDate, workDays, calendarId):
  Same logic but counting backward.

workDaysBetween(startDate, endDate, calendarId):
  Count work days between two dates, respecting calendar.
```

### Circular Dependency Detection

```
Before CPM calculation:
1. Build directed graph from dependencies
2. Run Kahn's algorithm (topological sort with cycle detection)
3. If cycle detected: return error with cycle path
4. User sees: "Circular dependency detected: Task A → Task B → Task C → Task A"
```

### Summary Task Roll-Up

```
For tasks with task_type = 'summary':
  - early_start = MIN(child.early_start)
  - early_finish = MAX(child.early_finish)
  - late_start = MIN(child.late_start)
  - late_finish = MAX(child.late_finish)
  - duration = work days between early_start and early_finish
  - percent_complete = weighted average of children (by duration)
  - budgeted_cost = SUM(child.budgeted_cost)
  - actual_cost = SUM(child.actual_cost)
  - is_critical = ANY(child.is_critical)
```

### Performance and Debouncing

```
TRIGGER:
  - Any INSERT/UPDATE/DELETE on schedule_tasks or schedule_dependencies
  - Debounce 500ms on rapid edits (user dragging tasks)
  - Batch: single CPM pass covers all changes

PERFORMANCE:
  - 100 tasks: < 50ms
  - 500 tasks: < 200ms
  - 1,000 tasks: < 500ms
  - 5,000 tasks: < 2 seconds
  - Optimization: only recalculate affected subgraph when possible
  - Full recalculation forced on: dependency structure changes, calendar changes, constraint changes

RESPONSE:
  Returns array of updated task objects with new CPM fields.
  Client applies updates via Supabase Realtime (postgres_changes channel).
```

---

## RESOURCE LEVELING SPECIFICATION

### Edge Function: `schedule-level-resources`

Detects over-allocation and automatically adjusts task dates to resolve conflicts while respecting dependencies and the critical path.

### Algorithm: Priority-Based Heuristic

```
1. BUILD RESOURCE USAGE TIMELINE
   For each resource, for each work day in the project:
   - Sum units_assigned across all tasks active on that day
   - Compare against resource.max_units
   - Flag any day where demand > capacity as over-allocated

2. DETECT OVER-ALLOCATIONS
   Group over-allocations by resource and date range.
   Example: "Electrician Crew A is over-allocated Feb 15-22 (need 5, have 3)"

3. RESOLVE (Priority-Based Heuristic)
   For each over-allocated period:
   a. Identify all tasks using this resource during the conflict
   b. Sort tasks by priority:
      - Critical tasks first (never move these)
      - Lower total float = higher priority
      - Earlier planned start = higher priority
      - User-set priority override (if specified)
   c. For lowest-priority tasks that can move:
      - Delay start date until resource becomes available
      - Re-run CPM to check impact
      - If delay makes a new task critical: warn but apply
   d. Repeat until demand <= capacity for every day

4. TRADE SEQUENCING AWARENESS
   Respect trade-specific sequencing rules:
   - Rough-in electrical before drywall (implicit FS dependency)
   - Plumbing top-out before insulation inspection
   - HVAC ductwork before ceiling close
   These can be modeled as dependencies, but the leveling engine
   should flag when it detects a trade sequencing violation.

5. EQUIPMENT SINGLE-USE CONSTRAINTS
   Equipment resources (boom lift, excavator, etc.) have max_units = 1.
   Two tasks cannot share the same equipment on the same day.
   Leveling treats these as hard constraints (never double-book).

6. CREW-BASED RESOURCES
   Labor resources represent crews, not individuals.
   "Electrician Crew A" with max_units = 3 means 3 electricians.
   A task needing 2 electricians consumes 2 of 3 available units.
   Remaining capacity: 1 electrician for other tasks.
```

### Resource Histogram Data

```
For the Gantt resource view, generate histogram data:

Per resource, per time period (day/week):
{
  resource_id: "uuid",
  period_start: "2026-03-01",
  period_end: "2026-03-07",
  capacity: 3,           // max_units * work_hours
  allocated: 4.5,        // sum of assigned hours
  is_over_allocated: true,
  tasks: [
    { task_id: "uuid", name: "Panel upgrade", units: 2 },
    { task_id: "uuid", name: "Rough-in kitchen", units: 2.5 }
  ]
}
```

---

## IMPORT/EXPORT SPECIFICATION

### Edge Function: `schedule-import-xer`

Imports Primavera P6 .XER files (plain text, pipe-delimited format).

```
XER FILE STRUCTURE:
  ERMHDR — file header
  PROJECT — project records
  PROJWBS — WBS structure
  TASK — task records (TASK_ID, TASK_CODE, TASK_NAME, TARGET_START, TARGET_END, ...)
  TASKPRED — predecessor relationships
  TASKRSRC — resource assignments
  RSRC — resource definitions
  CALENDAR — calendar definitions
  CALDATA — calendar non-work periods

IMPORT MAPPING:
  XER TASK → schedule_tasks
    - task_code → wbs_code
    - task_name → name
    - task_type (TT_Task, TT_Mile, TT_LOE, TT_WBS) → task_type
    - target_start_date → planned_start
    - target_end_date → planned_finish
    - target_drtn_hr_cnt / hours_per_day → original_duration
    - phys_complete_pct → percent_complete
    - total_float_hr_cnt → total_float
    - free_float_hr_cnt → free_float
    - cstr_type (CS_ASAP, CS_ALAP, CS_SNET, etc.) → constraint_type
    - cstr_date → constraint_date

  XER TASKPRED → schedule_dependencies
    - pred_type (PR_FS, PR_FF, PR_SS, PR_SF) → dependency_type
    - lag_hr_cnt / hours_per_day → lag_days

  XER RSRC → schedule_resources
  XER TASKRSRC → schedule_task_resources

VALIDATION:
  - Check for circular dependencies after import
  - Validate all dates parse correctly
  - Map XER calendar IDs to ZAFTO calendars (create if needed)
  - Report import summary: X tasks, Y dependencies, Z resources imported
```

### Edge Function: `schedule-export-xer`

Exports ZAFTO schedule to P6-compatible .XER format.

```
EXPORT MAPPING (reverse of import):
  schedule_tasks → XER TASK records
  schedule_dependencies → XER TASKPRED records
  schedule_resources → XER RSRC records
  schedule_task_resources → XER TASKRSRC records
  schedule_calendars → XER CALENDAR + CALDATA records

OUTPUT:
  UTF-8 text file with pipe-delimited records
  Standard P6 XER format (importable by P6, Planera, Phoenix Project Manager, etc.)
```

### Edge Function: `schedule-import-mpp`

Imports Microsoft Project .MPP and .XML files.

```
MS PROJECT XML IMPORT:
  XML format is well-documented and easier to parse than binary .MPP.

  MAPPING:
    <Task> → schedule_tasks
      - UID → external reference
      - Name → name
      - WBS → wbs_code
      - Duration → original_duration (parse "PT48H0M0S" → 6 days)
      - Start → planned_start
      - Finish → planned_finish
      - PercentComplete → percent_complete
      - Milestone (boolean) → task_type = 'milestone'
      - Summary (boolean) → task_type = 'summary'
      - ConstraintType → constraint_type mapping (0=ASAP, 1=ALAP, 2=MSO, 3=MFO, 4=SNET, 5=SNLT, 6=FNET, 7=FNLT)
      - ConstraintDate → constraint_date

    <PredecessorLink> → schedule_dependencies
      - Type (0=FF, 1=FS, 2=SF, 3=SS) → dependency_type
      - LinkLag → lag_days (convert from tenths of minutes)

    <Resource> → schedule_resources
    <Assignment> → schedule_task_resources

BINARY .MPP IMPORT:
  Use mpxj library (Java, but available as WASM or via API service).
  mpxj reads .MPP, .MPX, .XML, .XER — universal project file reader.
  Deploy as a micro-service or compile to WASM for Edge Function use.
```

### CSV Export

```
Export schedule data as CSV for reporting:
  - tasks.csv: WBS, Name, Duration, Start, Finish, Float, % Complete, Cost, Resources
  - dependencies.csv: Predecessor, Successor, Type, Lag
  - resources.csv: Name, Type, Capacity, Rate, Allocation Summary
```

### PDF Gantt Chart Export

```
Server-side rendering of Gantt chart to PDF:
  - Use Puppeteer/Playwright to render DHTMLX Gantt in headless browser
  - Or use DHTMLX Gantt's built-in PDF export API
  - Title block: company name, project name, data date, print date
  - Options: page size (letter, legal, tabloid, A3), orientation, zoom level
  - Include: task list, Gantt bars, dependencies, critical path highlight, legend
  - Edge Function: `schedule-export-pdf`
```

---

## FLUTTER INTEGRATION

### Package: `legacy_gantt_chart` (MIT License)

Selected for:
- MIT license (free, no per-seat cost)
- Supports 10,000+ tasks with smooth scrolling
- All 4 dependency types (FS, FF, SS, SF)
- Resource histogram view
- Touch-optimized gesture system
- Dart-native (no platform channel overhead)

### Flutter Screens

| Screen | Purpose |
|--------|---------|
| `schedule_list_screen.dart` | List all schedule projects for company. Status filter, search, create new. |
| `schedule_gantt_screen.dart` | Full Gantt chart view. Task table left, timeline right. Pinch-zoom for timescale. Tap task to edit. Drag bar to reschedule. Draw dependencies by dragging connector dots. Critical path highlight toggle. |
| `schedule_task_detail_screen.dart` | Task detail bottom sheet: name, duration, dates, constraint, resources, notes, progress slider, dependency list. |
| `schedule_resource_screen.dart` | Resource list + histogram. See who is allocated where. Over-allocation warnings in red. |
| `schedule_baseline_screen.dart` | Baseline list + comparison view. Select two baselines (or current vs baseline) to see date shifts and duration changes. |

### Flutter Architecture

```
lib/
├── models/
│   ├── schedule_project.dart
│   ├── schedule_task.dart
│   ├── schedule_dependency.dart
│   ├── schedule_resource.dart
│   ├── schedule_task_resource.dart
│   ├── schedule_baseline.dart
│   ├── schedule_baseline_task.dart
│   ├── schedule_calendar.dart
│   ├── schedule_calendar_exception.dart
│   └── schedule_view.dart
├── repositories/
│   ├── schedule_project_repository.dart
│   ├── schedule_task_repository.dart
│   ├── schedule_dependency_repository.dart
│   ├── schedule_resource_repository.dart
│   └── schedule_baseline_repository.dart
├── providers/
│   ├── schedule_project_provider.dart
│   ├── schedule_tasks_provider.dart
│   ├── schedule_dependencies_provider.dart
│   ├── schedule_resources_provider.dart
│   └── schedule_baselines_provider.dart
├── screens/
│   └── scheduling/
│       ├── schedule_list_screen.dart
│       ├── schedule_gantt_screen.dart
│       ├── schedule_task_detail_screen.dart
│       ├── schedule_resource_screen.dart
│       └── schedule_baseline_screen.dart
└── widgets/
    └── scheduling/
        ├── gantt_task_row.dart
        ├── gantt_dependency_painter.dart
        ├── resource_histogram.dart
        ├── baseline_comparison_bar.dart
        ├── task_progress_slider.dart
        └── calendar_exception_chip.dart
```

### Touch-Optimized Field Use

```
MOBILE GANTT GESTURES:
  - Pinch to zoom timescale (days → weeks → months)
  - Horizontal scroll through timeline
  - Vertical scroll through task list
  - Tap task bar → open task detail sheet
  - Long-press task bar → drag to reschedule
  - Swipe right on task → quick progress update (slider)
  - Two-finger tap → toggle critical path highlight

FIELD PROGRESS UPDATE (offline-capable):
  1. Tech opens schedule from job detail
  2. Finds their assigned task
  3. Swipes right → progress slider appears
  4. Drags to 75% → confirms
  5. Update saved to Hive cache immediately
  6. Syncs to Supabase when online
  7. CPM recalculation triggers server-side
  8. All connected clients see updated schedule via Realtime
```

---

## WEB CRM INTEGRATION

### Package: DHTMLX Gantt PRO ($699/dev, one-time)

Selected for:
- Handles 30,000+ tasks with virtual rendering
- Built-in critical path calculation (client-side validation)
- P6 export built-in
- All 4 dependency types with drag-to-create
- Resource histogram and workload views
- Baseline comparison display
- Undo/redo built-in
- Keyboard shortcuts
- Print/PDF export
- Actively maintained, enterprise-grade

### Web CRM Pages

| Page | Route | Purpose |
|------|-------|---------|
| Scheduling Dashboard | `/dashboard/scheduling` | List all schedule projects. Cards with progress, critical task count, next milestone. Quick filters. |
| Project Gantt | `/dashboard/scheduling/[id]` | Full DHTMLX Gantt view. Task table, timeline, critical path, dependencies, baselines. Toolbar: zoom, filter, view mode, import/export, baseline. |
| Resource Allocation | `/dashboard/scheduling/[id]/resources` | Resource list + histogram. Drag-to-assign resources. Over-allocation warnings. |
| Baseline Comparison | `/dashboard/scheduling/[id]/baselines` | Side-by-side baseline comparison. Date variance table. Gantt overlay (current vs baseline bars). |
| Multi-Project Portfolio | `/dashboard/scheduling/portfolio` | All active projects on one timeline. Cross-project resource conflicts. Portfolio-level milestones. |

### Web CRM Hooks

| Hook | Purpose |
|------|---------|
| `use-schedule.ts` | CRUD for schedule_projects. Real-time subscription. |
| `use-schedule-tasks.ts` | CRUD for schedule_tasks. Bulk operations (indent, outdent, move). Real-time subscription. |
| `use-schedule-dependencies.ts` | CRUD for dependencies. Circular dependency validation. |
| `use-schedule-resources.ts` | CRUD for resources + task_resources. Over-allocation detection. |
| `use-schedule-baselines.ts` | Create/list/compare baselines. Active baseline toggle. |
| `use-schedule-calendar.ts` | CRUD for calendars + exceptions. |
| `use-schedule-cpm.ts` | Trigger CPM recalculation. Subscribe to CPM result updates. |
| `use-schedule-import.ts` | File upload + import progress tracking. |
| `use-schedule-views.ts` | Saved view configurations per user. |

### Real-Time Collaboration

```
SUPABASE REALTIME CHANNELS:

Channel: schedule:{project_id}

1. PRESENCE (who's looking at what):
   - Track which users have the schedule open
   - Show user avatars/cursors on the Gantt chart
   - "Sarah is viewing this schedule" indicator

2. BROADCAST (ephemeral events):
   - Task selection: "Robert selected Task #47"
   - Task dragging: real-time drag preview for other users
   - Zoom/scroll sync option: "Follow Robert's view"

3. POSTGRES CHANGES (data mutations):
   - schedule_tasks: INSERT/UPDATE/DELETE → re-render affected tasks
   - schedule_dependencies: changes → re-draw dependency lines
   - schedule_task_resources: changes → update resource histogram

MICRO-LOCK PROTOCOL:
  1. User starts editing task → acquire lock (INSERT into schedule_task_locks)
  2. Lock expires in 30 seconds (auto-cleanup via expires_at)
  3. Other users see lock indicator on task: "Robert is editing..."
  4. If lock expired and user still editing → silently re-acquire
  5. On save or cancel → release lock (DELETE from schedule_task_locks)
  6. If two users try to lock same task → second user sees "Task is being edited by Robert"

CONFLICT RESOLUTION:
  - Optimistic concurrency via updated_at check
  - If server updated_at > client's last-known updated_at → conflict
  - Show diff: "Robert changed the duration from 5 to 8 days. Keep your change or accept theirs?"
```

---

## PORTAL INTEGRATION

### Team Portal (team.zafto.cloud)

```
WHAT TECHS SEE:
  - Simplified read-only Gantt view of the projects they're assigned to
  - Their tasks highlighted, with dates and dependencies visible
  - Progress update button on each assigned task (slider 0-100%)
  - Daily task list: "Today's scheduled tasks" extracted from Gantt
  - Notification: "Task 'Rough-in Kitchen' is scheduled to start tomorrow"

PAGES:
  /schedule — List of projects with assigned tasks
  /schedule/[id] — Read-only Gantt with progress update capability

HOOKS:
  use-team-schedule.ts — Read-only schedule data, filtered to assigned tasks
  use-team-task-progress.ts — Progress update mutations
```

### Client Portal (client.zafto.cloud)

```
WHAT CLIENTS SEE:
  - Project timeline view (simplified — NOT a full Gantt)
  - Milestones shown as markers on a timeline
  - Current phase highlighted: "Phase 2 of 4: Rough-In (65% complete)"
  - Estimated completion date with confidence
  - Status updates: "On schedule" / "2 days ahead" / "3 days behind (weather delay)"
  - NO task-level detail, NO costs, NO resource names, NO internal notes

PAGES:
  /project/[id]/timeline — Milestone timeline view

HOOKS:
  use-client-timeline.ts — Milestone + progress data only (no sensitive fields)
```

### Ops Portal (ops.zafto.cloud)

```
WHAT OPS SEES:
  - Multi-company scheduling analytics
  - Average project duration by type
  - Schedule adherence rate (% of projects finishing on time)
  - Most common delay causes (from calendar exceptions + constraint violations)
  - Resource utilization across all companies
  - Critical path analysis trends

PAGES:
  /analytics/scheduling — Scheduling analytics dashboard

HOOKS:
  use-ops-scheduling-analytics.ts — Aggregated scheduling metrics
```

---

## ZAFTO SYSTEM INTEGRATION (The Killer Feature)

This is what makes ZAFTO scheduling fundamentally different from every competitor. The schedule is not an island. It is wired into every part of the platform.

### 1. Jobs <-> Tasks

```
WHEN A JOB IS CREATED:
  - If job has a schedule_project: auto-create a top-level summary task
  - Task name = job name
  - Task dates = job estimated start/end
  - Link: schedule_tasks.job_id = jobs.id

WHEN A TASK IS COMPLETED:
  - If task.job_id is set: update job progress percentage
  - Weighted by task duration relative to total project duration
  - Job status auto-advances: scheduled → in_progress → completing

WHEN A JOB STATUS CHANGES:
  - If job → cancelled: mark all linked tasks as cancelled (soft delete)
  - If job → on_hold: set schedule_project.status = 'on_hold'

BI-DIRECTIONAL SYNC:
  Job detail screen shows a mini Gantt of linked schedule tasks.
  Schedule Gantt shows job status badges on linked tasks.
```

### 2. Estimates -> Schedules

```
GENERATE SCHEDULE FROM ESTIMATE:
  Edge Function: schedule-generate-from-estimate

  INPUT: estimate_id
  OUTPUT: schedule_project with tasks generated from estimate line items

  LOGIC:
  1. Read estimate areas and line items
  2. Group by area (room/zone) → create summary tasks
  3. For each line item:
     - Create task with name = line item description
     - Duration = estimated labor hours / hours_per_day
     - Budgeted cost = line item total
     - Auto-assign trade-based dependencies:
       * Demo before rough-in
       * Rough-in before inspection
       * Inspection before close-in
       * Close-in before finish
     - Create resource needs from line item trade/category
  4. Link tasks back to estimate line items via estimate_item_id

  RESULT: A contractor clicks "Generate Schedule" on an estimate
  and gets a ready-to-adjust CPM schedule with intelligent defaults.
```

### 3. Team -> Resources

```
ZAFTO EMPLOYEE → SCHEDULE RESOURCE MAPPING:
  - Each ZAFTO employee can be linked to a schedule_resource
  - resource.user_id = users.id
  - Resource capacity = employee's configured work hours
  - Resource trade = employee's trade specialty
  - Resource role = employee's RBAC role

  When assigning resources in the schedule:
  - Show ZAFTO employees as available resources
  - Show their existing job assignments as capacity constraints
  - Flag conflicts: "Mike is assigned to Job #1234 on Feb 15-18"

AVAILABILITY SYNC:
  - Employee time-off (from ZAFTO time tracking) → calendar exceptions
  - Employee job assignments → resource allocation constraints
  - Crew assignments from job management → pre-populated resource allocations
```

### 4. Field Tools -> Progress

```
AUTOMATIC PROGRESS UPDATES FROM FIELD ACTIVITY:

Daily Job Logs:
  - Tech submits daily log for a job
  - If job has linked schedule tasks:
    * Match log entries to tasks by description/category
    * Suggest progress update: "Log mentions 'panel installed' — update 'Panel Upgrade' to 100%?"
    * Auto-update with tech confirmation

Photos:
  - Photos tagged with task reference → evidence of progress
  - Photo count per task shown in task detail

Punch Lists:
  - Punch list items linked to schedule tasks
  - When all punch items for a task are resolved → suggest task completion

Inspection Checklists:
  - Inspection pass → advance dependent tasks
  - Inspection fail → flag schedule delay, suggest re-inspection task

TIME TRACKING:
  - Clock-in/clock-out entries matched to tasks
  - Actual hours → actual_duration on schedule_tasks
  - Variance tracking: actual vs planned duration
```

### 5. Ledger -> Cost Loading

```
SCHEDULE COST INTEGRATION:

Task budgeted_cost → Ledger job costing:
  - Each task's budgeted_cost contributes to job cost budget
  - Resource costs (labor rate * hours) feed cost projections
  - Material costs from task_resources feed material budget

Earned Value Management (EVM):
  - Planned Value (PV) = budgeted cost of work scheduled to date
  - Earned Value (EV) = budgeted cost of work actually completed
  - Actual Cost (AC) = actual cost recorded in Ledger
  - Schedule Performance Index (SPI) = EV / PV
  - Cost Performance Index (CPI) = EV / AC
  - Displayed on project dashboard and Ops Portal

Invoice triggers:
  - Milestone completion → trigger invoice generation
  - "Invoice on completion of Phase 2: Rough-In" → auto-draft invoice when milestone task reaches 100%
```

### 6. Phone/Meetings -> Schedule

```
SCHEDULE-TRIGGERED COMMUNICATIONS:

Reminders:
  - 24 hours before task start → push notification to assigned resource
  - 48 hours before milestone → email to project stakeholders
  - Configurable per task or project-wide

Coordination Calls:
  - Schedule generates "Pre-task coordination" meeting suggestions
  - "3 trades converging on Feb 15 — suggest coordination meeting?"
  - One-tap to create ZAFTO Meeting with all relevant parties

Delay Notifications:
  - CPM detects schedule slip → auto-notify affected parties
  - "Critical path delayed 3 days. New completion: March 18."
  - Client Portal updated automatically
```

---

## EDGE FUNCTIONS SUMMARY

| Function | Trigger | Purpose |
|----------|---------|---------|
| `schedule-calculate-cpm` | Task/dependency changes | Full CPM forward + backward pass, float calculation, critical path |
| `schedule-level-resources` | Manual trigger or after CPM | Priority-based resource leveling with over-allocation resolution |
| `schedule-import-xer` | File upload | Parse P6 .XER and create ZAFTO schedule objects |
| `schedule-export-xer` | User action | Generate P6-compatible .XER file from ZAFTO schedule |
| `schedule-import-mpp` | File upload | Parse MS Project .XML/.MPP and create ZAFTO schedule objects |
| `schedule-export-csv` | User action | Generate CSV files for tasks, dependencies, resources |
| `schedule-export-pdf` | User action | Render Gantt chart to PDF via headless browser |
| `schedule-generate-from-estimate` | User action | Auto-generate schedule from D8 estimate line items |
| `schedule-generate-from-job` | Job creation | Auto-create schedule project linked to job |
| `schedule-clean-locks` | Cron (60s) | Delete expired micro-locks from schedule_task_locks |
| `schedule-sync-progress` | Field tool events | Update task progress from daily logs, photos, punch lists |
| `schedule-baseline-capture` | User action | Snapshot all task states into baseline tables |

---

## SPRINT BREAKDOWN

### GC1: Database Schema + Work Calendars (~8 hrs)

```
[ ] Create migration gc1_schedule_engine.sql with all 12 tables
[ ] All RLS policies (company_id isolation)
[ ] All indexes
[ ] All audit triggers (update_updated_at + audit_trigger_fn)
[ ] Seed default calendars: 5-day, 6-day, 7-day
[ ] Seed common US holidays as calendar exceptions
[ ] Dart models: schedule_project, schedule_task, schedule_dependency, schedule_resource,
    schedule_task_resource, schedule_baseline, schedule_baseline_task, schedule_calendar,
    schedule_calendar_exception, schedule_view
[ ] Dart repositories: schedule_project_repository, schedule_task_repository,
    schedule_dependency_repository, schedule_resource_repository, schedule_baseline_repository
[ ] TypeScript types in web-portal: src/lib/types/scheduling.ts
[ ] Verify: dart analyze passes, migration applies cleanly
```

### GC2: CPM Engine Edge Function (~12 hrs)

```
[ ] Edge Function: schedule-calculate-cpm
[ ] Forward pass algorithm (early start / early finish)
[ ] Backward pass algorithm (late start / late finish)
[ ] Float calculation (total float, free float)
[ ] Critical path identification
[ ] All 4 dependency types (FS, FF, SS, SF) with lag/lead
[ ] All 8 constraint types (asap, alap, snet, snlt, fnet, fnlt, mso, mfo)
[ ] Calendar-aware date math (addWorkDays, subtractWorkDays, workDaysBetween)
[ ] Circular dependency detection (Kahn's algorithm)
[ ] Summary task roll-up
[ ] Debounce 500ms for rapid edits
[ ] Unit tests: 20+ test cases covering all dependency types, constraint types, float scenarios
[ ] Performance test: 1000 tasks < 500ms
[ ] Verify: deploy to Supabase, test via curl
```

### GC3: Resource Management + Leveling Edge Function (~12 hrs)

```
[ ] Edge Function: schedule-level-resources
[ ] Resource usage timeline builder
[ ] Over-allocation detection
[ ] Priority-based heuristic leveling algorithm
[ ] Crew-based resources (partial allocation)
[ ] Equipment single-use constraints
[ ] Trade sequencing awareness
[ ] Resource histogram data generation
[ ] Dart models: schedule_resource, schedule_task_resource
[ ] Dart repository: schedule_resource_repository
[ ] Web hook: use-schedule-resources.ts
[ ] Unit tests: over-allocation scenarios, leveling correctness
[ ] Verify: deploy, test with sample data
```

### GC4: Flutter Gantt Screens (~16 hrs)

```
[ ] Add legacy_gantt_chart to pubspec.yaml
[ ] schedule_list_screen.dart — project list with status cards
[ ] schedule_gantt_screen.dart — full Gantt with task table + timeline
[ ] schedule_task_detail_screen.dart — task detail bottom sheet
[ ] schedule_resource_screen.dart — resource list + histogram
[ ] Riverpod providers: schedule_project_provider, schedule_tasks_provider,
    schedule_dependencies_provider, schedule_resources_provider
[ ] Touch gestures: pinch-zoom, drag-to-reschedule, swipe-for-progress
[ ] Dependency drawing: drag connector dots between tasks
[ ] Critical path toggle (highlight critical tasks in red)
[ ] Offline progress updates: queue in Hive, sync when online
[ ] Navigation: add scheduling to main drawer/bottom nav
[ ] Verify: dart analyze, manual test on Android emulator + iOS simulator
```

### GC5: Web CRM Gantt Pages (~16 hrs)

```
[ ] Install DHTMLX Gantt PRO in web-portal
[ ] Scheduling Dashboard page: /dashboard/scheduling
[ ] Project Gantt page: /dashboard/scheduling/[id]
    — DHTMLX Gantt configuration: task table columns, timeline, dependencies
    — Critical path plugin enabled
    — Baseline display (ghost bars)
    — Toolbar: zoom in/out, filter, view mode toggle, import/export
[ ] Resource Allocation page: /dashboard/scheduling/[id]/resources
[ ] Hooks: use-schedule.ts, use-schedule-tasks.ts, use-schedule-dependencies.ts
[ ] DHTMLX ↔ Supabase data adapter (bidirectional sync)
[ ] Keyboard shortcuts: Ctrl+Z undo, Delete task, Tab next, Enter edit
[ ] Verify: npm run build passes, manual test in browser
```

### GC6: Baseline Management + Comparison Views (~8 hrs)

```
[ ] Edge Function: schedule-baseline-capture
    — Snapshot all task states into schedule_baseline_tasks
[ ] Flutter: schedule_baseline_screen.dart
    — Baseline list, create new, compare
    — Current vs baseline overlay on Gantt (dual bars)
    — Date variance table: task name, baseline start/finish, current start/finish, variance days
[ ] Web CRM: Baseline Comparison page /dashboard/scheduling/[id]/baselines
    — DHTMLX baseline plugin integration
    — Variance highlighting (red for slippage, green for ahead)
[ ] Hook: use-schedule-baselines.ts
[ ] Riverpod provider: schedule_baselines_provider
[ ] Verify: create baseline, modify schedule, compare — variance displayed correctly
```

### GC7: P6/MS Project Import/Export (~12 hrs)

```
[ ] Edge Function: schedule-import-xer — parse XER, create ZAFTO objects
[ ] Edge Function: schedule-export-xer — generate P6-compatible XER
[ ] Edge Function: schedule-import-mpp — parse MS Project XML
[ ] Edge Function: schedule-export-csv — CSV export for reporting
[ ] Edge Function: schedule-export-pdf — render Gantt to PDF
[ ] Flutter: import/export buttons on schedule_gantt_screen
    — File picker for import (.xer, .xml, .mpp)
    — Share sheet for export
[ ] Web CRM: import/export toolbar buttons on Project Gantt page
    — Drag-and-drop file upload for import
    — Download for export
[ ] Import validation: circular dependency check, date parse, summary report
[ ] Round-trip test: export from ZAFTO → import into P6 → export from P6 → import back
[ ] Verify: deploy all EFs, test with real P6 XER file and MS Project XML
```

### GC8: Portal Views + Real-Time Collaboration (~12 hrs)

```
[ ] Team Portal:
    — /schedule page: list of projects with assigned tasks
    — /schedule/[id] page: read-only Gantt with progress update
    — Hook: use-team-schedule.ts, use-team-task-progress.ts
[ ] Client Portal:
    — /project/[id]/timeline page: milestone timeline view
    — Hook: use-client-timeline.ts
    — Status display: on schedule / ahead / behind + reason
[ ] Ops Portal:
    — /analytics/scheduling page: multi-company scheduling analytics
    — Hook: use-ops-scheduling-analytics.ts
[ ] Real-time collaboration (Web CRM):
    — Supabase Realtime channel per project: presence, broadcast, postgres_changes
    — User cursors/avatars on Gantt chart
    — Micro-lock system: acquire on edit, 30s TTL, visual indicator
    — Conflict resolution UI: show diff, accept mine / accept theirs
[ ] Edge Function: schedule-clean-locks (cron every 60s)
[ ] Verify: open schedule in 2 browser tabs, edit in one, see update in other
```

### GC9: Multi-Project Portfolio + Cross-Project Resources (~8 hrs)

```
[ ] Web CRM: Multi-Project Portfolio page /dashboard/scheduling/portfolio
    — All active projects on one timeline
    — Project-level bars with progress
    — Cross-project milestones
    — Portfolio-level critical path (optional)
[ ] Cross-project resource detection:
    — Same resource assigned to overlapping tasks in different projects
    — Warning: "Electrician Crew A is double-booked Feb 15-18 (Job #1234 + Job #5678)"
    — Resolution suggestions: reassign, delay, split
[ ] Portfolio dashboard cards:
    — Projects on track / behind / ahead
    — Upcoming milestones (next 2 weeks)
    — Resource utilization summary
[ ] Hook: use-schedule-portfolio.ts
[ ] Verify: create 3 projects with shared resources, detect cross-project conflict
```

### GC10: ZAFTO Integration Wiring (~12 hrs)

```
[ ] Jobs <-> Tasks:
    — Job creation → auto-create schedule task (if project exists)
    — Task completion → update job progress
    — Job status change → update schedule status
    — Mini Gantt widget on job detail screen (Flutter + Web)
[ ] Estimates → Schedules:
    — Edge Function: schedule-generate-from-estimate
    — "Generate Schedule" button on estimate detail
    — Trade-based default dependencies (demo → rough-in → inspection → close-in → finish)
[ ] Team → Resources:
    — Employee ↔ resource mapping
    — Show ZAFTO employees as assignable resources
    — Employee time-off → calendar exceptions
[ ] Field Tools → Progress:
    — Edge Function: schedule-sync-progress
    — Daily log → suggest task progress update
    — Photo tags → task evidence
    — Punch list resolution → task completion suggestion
[ ] Ledger → Cost Loading:
    — Task budgeted_cost → job cost budget
    — EVM calculations (PV, EV, AC, SPI, CPI) on project dashboard
    — Milestone completion → invoice trigger
[ ] Phone/Meetings → Schedule:
    — Schedule reminders (24h before task, 48h before milestone)
    — Coordination meeting suggestions
    — Delay notifications to affected parties
[ ] Verify: end-to-end flow — create estimate → generate schedule → assign team →
    update progress from field → costs flow to Ledger → client sees milestone timeline
```

### GC11: Testing + QA (~8 hrs)

```
[ ] CPM engine comprehensive test suite:
    — Forward/backward pass correctness
    — All 4 dependency types with positive/negative lag
    — All 8 constraint types
    — Circular dependency rejection
    — Summary task roll-up
    — Calendar-aware date math (holidays, weekends, overtime)
    — Performance: 1000+ tasks
[ ] Resource leveling test suite:
    — Over-allocation detection
    — Leveling preserves critical path
    — Equipment single-use enforcement
    — Crew partial allocation
[ ] Import/export test suite:
    — P6 XER round-trip
    — MS Project XML import
    — CSV export correctness
[ ] Real-time collaboration test:
    — 2 users editing same schedule simultaneously
    — Lock acquisition/release
    — Conflict resolution
[ ] Integration test:
    — Job → schedule → progress → Ledger flow
    — Estimate → schedule generation
    — Field tool → progress update
[ ] Flutter: dart analyze (0 errors), manual test all 5 screens
[ ] Web CRM: npm run build (0 errors), manual test all 5 pages
[ ] Team Portal: npm run build, test progress update flow
[ ] Client Portal: npm run build, test milestone timeline view
[ ] Ops Portal: npm run build, test analytics dashboard
[ ] Button audit: every button clicks, every export works, every flow completes
```

---

## SPRINT SUMMARY

| Sprint | Focus | Hours |
|--------|-------|:-----:|
| GC1 | Database schema + work calendars | ~8 |
| GC2 | CPM engine Edge Function | ~12 |
| GC3 | Resource management + leveling Edge Function | ~12 |
| GC4 | Flutter Gantt screens (legacy_gantt_chart) | ~16 |
| GC5 | Web CRM Gantt pages (DHTMLX Gantt PRO) | ~16 |
| GC6 | Baseline management + comparison views | ~8 |
| GC7 | P6/MS Project import/export Edge Functions | ~12 |
| GC8 | Portal views + real-time collaboration | ~12 |
| GC9 | Multi-project portfolio + cross-project resources | ~8 |
| GC10 | ZAFTO integration wiring (jobs, estimates, team, field, Ledger) | ~12 |
| GC11 | Testing + QA | ~8 |
| **Total** | | **~124** |

**Build order:** GC1 → GC2 → GC3 → GC4 + GC5 (parallel) → GC6 → GC7 → GC8 → GC9 → GC10 → GC11

**Dependencies:**
- GC1 is foundation for everything (schema + models)
- GC2 (CPM engine) before GC4/GC5 (Gantt views need CPM data)
- GC3 (resources) before GC4/GC5 (resource views)
- GC4 (Flutter) and GC5 (Web) can run in parallel
- GC6 (baselines) after GC4/GC5 (needs Gantt views to display)
- GC7 (import/export) after GC2 (needs CPM for post-import calculation)
- GC8 (portals) after GC4/GC5 (reuses components)
- GC9 (portfolio) after GC5 (extends web Gantt)
- GC10 (integration) after all feature sprints
- GC11 (testing) last

---

## FILE INVENTORY

### New Files -- Flutter (Mobile)

| File | Purpose |
|------|---------|
| `lib/models/schedule_project.dart` | ScheduleProject model |
| `lib/models/schedule_task.dart` | ScheduleTask model with CPM fields |
| `lib/models/schedule_dependency.dart` | ScheduleDependency model (4 types) |
| `lib/models/schedule_resource.dart` | ScheduleResource model (labor/equipment/material) |
| `lib/models/schedule_task_resource.dart` | ScheduleTaskResource allocation model |
| `lib/models/schedule_baseline.dart` | ScheduleBaseline model |
| `lib/models/schedule_baseline_task.dart` | ScheduleBaselineTask snapshot model |
| `lib/models/schedule_calendar.dart` | ScheduleCalendar model |
| `lib/models/schedule_calendar_exception.dart` | ScheduleCalendarException model |
| `lib/models/schedule_view.dart` | ScheduleView saved config model |
| `lib/repositories/schedule_project_repository.dart` | CRUD for schedule_projects |
| `lib/repositories/schedule_task_repository.dart` | CRUD for schedule_tasks + bulk ops |
| `lib/repositories/schedule_dependency_repository.dart` | CRUD for dependencies |
| `lib/repositories/schedule_resource_repository.dart` | CRUD for resources + allocations |
| `lib/repositories/schedule_baseline_repository.dart` | CRUD for baselines + snapshots |
| `lib/providers/schedule_project_provider.dart` | Riverpod provider for projects |
| `lib/providers/schedule_tasks_provider.dart` | Riverpod provider for tasks (real-time) |
| `lib/providers/schedule_dependencies_provider.dart` | Riverpod provider for dependencies |
| `lib/providers/schedule_resources_provider.dart` | Riverpod provider for resources |
| `lib/providers/schedule_baselines_provider.dart` | Riverpod provider for baselines |
| `lib/screens/scheduling/schedule_list_screen.dart` | Project list screen |
| `lib/screens/scheduling/schedule_gantt_screen.dart` | Full Gantt chart screen |
| `lib/screens/scheduling/schedule_task_detail_screen.dart` | Task detail bottom sheet |
| `lib/screens/scheduling/schedule_resource_screen.dart` | Resource list + histogram |
| `lib/screens/scheduling/schedule_baseline_screen.dart` | Baseline comparison screen |
| `lib/widgets/scheduling/gantt_task_row.dart` | Individual Gantt task bar widget |
| `lib/widgets/scheduling/gantt_dependency_painter.dart` | CustomPainter for dependency lines |
| `lib/widgets/scheduling/resource_histogram.dart` | Resource utilization bar chart |
| `lib/widgets/scheduling/baseline_comparison_bar.dart` | Dual-bar baseline overlay |
| `lib/widgets/scheduling/task_progress_slider.dart` | Quick progress update slider |
| `lib/widgets/scheduling/calendar_exception_chip.dart` | Holiday/weather day indicator |
| `lib/widgets/scheduling/mini_gantt_widget.dart` | Compact Gantt for job detail screen |

### New Files -- Web CRM (web-portal)

| File | Purpose |
|------|---------|
| `src/lib/types/scheduling.ts` | TypeScript interfaces for all schedule types |
| `src/lib/hooks/use-schedule.ts` | Schedule project CRUD + real-time |
| `src/lib/hooks/use-schedule-tasks.ts` | Task CRUD + bulk ops + real-time |
| `src/lib/hooks/use-schedule-dependencies.ts` | Dependency CRUD + validation |
| `src/lib/hooks/use-schedule-resources.ts` | Resource CRUD + over-allocation |
| `src/lib/hooks/use-schedule-baselines.ts` | Baseline CRUD + comparison |
| `src/lib/hooks/use-schedule-calendar.ts` | Calendar + exception CRUD |
| `src/lib/hooks/use-schedule-cpm.ts` | CPM trigger + result subscription |
| `src/lib/hooks/use-schedule-import.ts` | Import progress tracking |
| `src/lib/hooks/use-schedule-views.ts` | Saved view configurations |
| `src/lib/hooks/use-schedule-portfolio.ts` | Multi-project portfolio data |
| `src/app/dashboard/scheduling/page.tsx` | Scheduling dashboard |
| `src/app/dashboard/scheduling/[id]/page.tsx` | Project Gantt page |
| `src/app/dashboard/scheduling/[id]/resources/page.tsx` | Resource allocation page |
| `src/app/dashboard/scheduling/[id]/baselines/page.tsx` | Baseline comparison page |
| `src/app/dashboard/scheduling/portfolio/page.tsx` | Multi-project portfolio |
| `src/components/scheduling/GanttChart.tsx` | DHTMLX Gantt wrapper component |
| `src/components/scheduling/GanttToolbar.tsx` | Gantt toolbar (zoom, filter, export) |
| `src/components/scheduling/ResourceHistogram.tsx` | Resource histogram component |
| `src/components/scheduling/BaselineComparison.tsx` | Baseline overlay component |
| `src/components/scheduling/TaskDetailPanel.tsx` | Task detail side panel |
| `src/components/scheduling/ImportDialog.tsx` | File import dialog |
| `src/components/scheduling/ExportMenu.tsx` | Export format selection menu |
| `src/components/scheduling/CollaborationPresence.tsx` | User avatars + cursors |

### New Files -- Team Portal (team-portal)

| File | Purpose |
|------|---------|
| `src/lib/hooks/use-team-schedule.ts` | Read-only schedule data for assigned tasks |
| `src/lib/hooks/use-team-task-progress.ts` | Progress update mutations |
| `src/app/schedule/page.tsx` | Project list with assigned tasks |
| `src/app/schedule/[id]/page.tsx` | Read-only Gantt + progress update |

### New Files -- Client Portal (client-portal)

| File | Purpose |
|------|---------|
| `src/lib/hooks/use-client-timeline.ts` | Milestone + progress data (no sensitive fields) |
| `src/app/project/[id]/timeline/page.tsx` | Milestone timeline view |

### New Files -- Ops Portal (ops-portal)

| File | Purpose |
|------|---------|
| `src/lib/hooks/use-ops-scheduling-analytics.ts` | Aggregated scheduling metrics |
| `src/app/analytics/scheduling/page.tsx` | Scheduling analytics dashboard |

### New Files -- Supabase Edge Functions

| File | Purpose |
|------|---------|
| `supabase/functions/schedule-calculate-cpm/index.ts` | CPM engine |
| `supabase/functions/schedule-level-resources/index.ts` | Resource leveling |
| `supabase/functions/schedule-import-xer/index.ts` | P6 XER import |
| `supabase/functions/schedule-export-xer/index.ts` | P6 XER export |
| `supabase/functions/schedule-import-mpp/index.ts` | MS Project import |
| `supabase/functions/schedule-export-csv/index.ts` | CSV export |
| `supabase/functions/schedule-export-pdf/index.ts` | PDF Gantt export |
| `supabase/functions/schedule-generate-from-estimate/index.ts` | Estimate → schedule |
| `supabase/functions/schedule-generate-from-job/index.ts` | Job → schedule task |
| `supabase/functions/schedule-clean-locks/index.ts` | Expired lock cleanup |
| `supabase/functions/schedule-sync-progress/index.ts` | Field tool → progress |
| `supabase/functions/schedule-baseline-capture/index.ts` | Baseline snapshot |

### New Migration

| Migration | Tables/Changes |
|-----------|---------------|
| `gc1_schedule_engine.sql` | CREATE 12 tables + RLS + indexes + triggers |

### Modified Files

| File | Changes |
|------|---------|
| `pubspec.yaml` | Add `legacy_gantt_chart` package |
| `web-portal/package.json` | Add `dhtmlx-gantt` (PRO) |
| `lib/screens/jobs/job_detail_screen.dart` | Add mini Gantt widget section |
| `web-portal/src/app/dashboard/jobs/[id]/page.tsx` | Add mini Gantt widget section |
| `web-portal/src/app/dashboard/layout.tsx` | Add scheduling nav item |
| `team-portal/src/app/layout.tsx` | Add schedule nav item |
| `client-portal/src/app/project/[id]/layout.tsx` | Add timeline nav item |

---

## PACKAGES ADDED

### Flutter (pubspec.yaml)

- `legacy_gantt_chart` -- MIT license, Gantt chart with 10K+ task support, all dependency types, resource histograms, touch gestures

### Web CRM (web-portal/package.json)

- `dhtmlx-gantt` (PRO) -- $699/dev one-time license. 30K+ task virtual rendering, built-in critical path, P6 export, baseline display, resource views, undo/redo, keyboard shortcuts, PDF export.

---

## TECHNICAL NOTES

### Licensing Costs

- **DHTMLX Gantt PRO**: $699/developer, one-time purchase. Includes all plugins (critical path, resource, baseline, grouping, export). No per-user or per-company fees. Commercial license allows SaaS deployment.
- **legacy_gantt_chart**: MIT license. Free.

### Performance Targets

| Scenario | Target |
|----------|--------|
| CPM calculation (100 tasks) | < 50ms |
| CPM calculation (500 tasks) | < 200ms |
| CPM calculation (1,000 tasks) | < 500ms |
| CPM calculation (5,000 tasks) | < 2s |
| Gantt render (1,000 tasks, Flutter) | Smooth 60fps scroll |
| Gantt render (1,000 tasks, DHTMLX) | Smooth 60fps scroll |
| Real-time update propagation | < 200ms (Supabase Realtime) |
| Lock acquisition | < 100ms |
| XER import (500 tasks) | < 5s |
| PDF export | < 10s |

### CPM Recalculation Strategy

```
DEBOUNCE:
  - 500ms debounce on rapid edits (user dragging tasks in Gantt)
  - Batch: accumulate changes during debounce window, single CPM pass

INCREMENTAL vs FULL:
  - Task date/duration change: incremental (recalculate from changed task forward/backward)
  - Dependency structure change: full recalculation
  - Calendar change: full recalculation
  - Constraint change: full recalculation
  - Import: full recalculation after all data loaded

OPTIMISTIC UI:
  - Client-side: immediate visual update on drag
  - Server-side: CPM validates and adjusts if needed
  - If server disagrees: animate task to corrected position
```

### Real-Time Architecture

```
SUPABASE REALTIME CHANNELS:

schedule:{project_id}
  ├── Presence
  │   ├── User joins/leaves schedule view
  │   ├── User avatar positions on Gantt
  │   └── "3 users viewing this schedule"
  ├── Broadcast
  │   ├── Task selection events (ephemeral)
  │   ├── Drag preview coordinates (ephemeral)
  │   └── View follow requests
  └── Postgres Changes
      ├── schedule_tasks → re-render task bars
      ├── schedule_dependencies → re-draw lines
      ├── schedule_task_resources → update histogram
      └── schedule_task_locks → show/hide lock indicators

MICRO-LOCK TTL: 30 seconds
  - Client heartbeat: re-acquire lock every 20 seconds while editing
  - Server cleanup: delete expired locks every 60 seconds (cron EF)
  - If client disconnects: lock expires in 30s, other users can edit
```

---

## BUILD ORDER IN ZAFTO ROADMAP

```
... → Phase SK (Sketch Engine) → Phase GC (Schedule) → Phase U (Unification) → ...

Phase GC prerequisites:
  - Core database (A1-A4): companies, users, jobs, estimates — DONE
  - Job management (Sprint 3.6): job CRUD — DONE
  - D8 Estimates: estimate line items — DONE
  - Team management: users with roles — DONE
  - Ledger: job costing tables — DONE

Phase GC enables:
  - Phase U: unified experience ties scheduling into single workflow
  - Phase E (AI): AI scheduling suggestions, auto-optimization, delay prediction
  - Client Portal: project timeline visibility
  - Ops Portal: scheduling analytics across all companies
```

---

## LEGAL NOTES

- **DHTMLX Gantt PRO**: Commercial license ($699/dev). Allows SaaS deployment. No per-end-user fees. Review EULA for redistribution terms.
- **legacy_gantt_chart**: MIT license. No restrictions.
- **P6 XER format**: Oracle does not restrict reading/writing XER files. It is a documented text format. No patent or license issues.
- **MS Project XML format**: Microsoft's published XML schema. Open for interoperability.
- **mpxj library**: LGPL license. Used as a service/tool, not distributed with ZAFTO binaries. Safe.

---

## THE MOAT

```
WHAT PRIMAVERA P6 WILL NEVER HAVE:
  Connected CRM. Connected estimates. Connected team management.
  Connected field tools. Connected accounting. Connected phone system.
  Connected AI. All in one platform. At trade contractor prices.

WHAT BUILDERTREND/SERVICETITAN WILL NEVER HAVE:
  Real CPM. Real float calculation. Real resource leveling.
  Real baseline comparison. Real P6 interoperability.
  Because adding a real scheduling engine to a CRM
  is harder than adding a CRM to a scheduling engine.
  And ZAFTO has both.

WHAT NOBODY HAS:
  Upload a blueprint → AI reads it → estimate generated →
  schedule auto-created with trade dependencies →
  crews assigned from team → progress tracked from field →
  costs flow to books → client sees milestones →
  delays trigger coordination calls → AI suggests optimization.

  All in one app. All offline-capable. All real-time synced.
  All at a price a 3-person electrical shop can afford.

  That's the moat. It's not one feature. It's the network effect
  of every feature being connected to every other feature.
```

---

## CHANGELOG

| Date | Change |
|------|--------|
| 2026-02-11 | Created. 12 tables, 12 Edge Functions, 5 Flutter screens, 5 Web CRM pages, 4 portal pages. Full CPM engine with 4 dependency types, 8 constraint types, resource leveling, baseline management, P6/MPP import/export, real-time collaboration. ~124 hours across 11 sprints (GC1-GC11). |
