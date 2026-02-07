-- D5c: Unit Turns + Job Linkage (Migration 3 of 3)
-- Tables: unit_turns, unit_turn_tasks, approval_thresholds
-- + ALTER jobs, expenses, vendor_payments

-- 17. Unit Turns
CREATE TABLE unit_turns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  unit_id uuid NOT NULL REFERENCES units(id),
  outgoing_lease_id uuid REFERENCES leases(id),
  incoming_lease_id uuid REFERENCES leases(id),
  move_out_date date,
  target_ready_date date,
  actual_ready_date date,
  move_out_inspection_id uuid REFERENCES pm_inspections(id),
  move_in_inspection_id uuid REFERENCES pm_inspections(id),
  total_cost numeric(10,2) DEFAULT 0,
  deposit_deductions numeric(10,2) DEFAULT 0,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'ready', 'listed', 'leased', 'cancelled')),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_unit_turns ON unit_turns(unit_id, status);

-- 18. Unit Turn Tasks
CREATE TABLE unit_turn_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_turn_id uuid NOT NULL REFERENCES unit_turns(id) ON DELETE CASCADE,
  task_type text NOT NULL CHECK (task_type IN ('clean', 'paint', 'repair', 'replace', 'inspect', 'photograph', 'pest_control', 'carpet', 'landscaping', 'other')),
  description text NOT NULL,
  job_id uuid REFERENCES jobs(id),
  assigned_to uuid REFERENCES users(id),
  vendor_id uuid REFERENCES vendors(id),
  estimated_cost numeric(10,2),
  actual_cost numeric(10,2),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped')),
  completed_at timestamptz,
  notes text,
  sort_order integer DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_turn_tasks ON unit_turn_tasks(unit_turn_id, sort_order);

-- 19. Approval Thresholds (company config)
CREATE TABLE approval_thresholds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  entity_type text NOT NULL CHECK (entity_type IN ('maintenance_request', 'vendor_invoice', 'expense')),
  threshold_amount numeric(10,2) NOT NULL,
  requires_role text NOT NULL DEFAULT 'owner',
  is_active boolean DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_thresholds ON approval_thresholds(company_id, entity_type) WHERE is_active = true;

-- Linkage: Add maintenance_request_id to jobs for chain tracing
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS maintenance_request_id uuid REFERENCES maintenance_requests(id);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS property_id uuid REFERENCES properties(id);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS unit_id uuid REFERENCES units(id);

-- Linkage: Add property_id to expense_records for Schedule E allocation
ALTER TABLE expense_records ADD COLUMN IF NOT EXISTS property_id uuid REFERENCES properties(id);
ALTER TABLE expense_records ADD COLUMN IF NOT EXISTS tax_schedule text CHECK (tax_schedule IN ('schedule_c', 'schedule_e'));

-- Linkage: Add property_id to vendor_payments
ALTER TABLE vendor_payments ADD COLUMN IF NOT EXISTS property_id uuid REFERENCES properties(id);
ALTER TABLE vendor_payments ADD COLUMN IF NOT EXISTS job_id uuid REFERENCES jobs(id);

-- RLS
ALTER TABLE unit_turns ENABLE ROW LEVEL SECURITY;
ALTER TABLE unit_turn_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE approval_thresholds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "unit_turns_select" ON unit_turns FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "unit_turns_insert" ON unit_turns FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "unit_turns_update" ON unit_turns FOR UPDATE USING (company_id = requesting_company_id());

CREATE POLICY "turn_tasks_select" ON unit_turn_tasks FOR SELECT USING (unit_turn_id IN (SELECT id FROM unit_turns WHERE company_id = requesting_company_id()));
CREATE POLICY "turn_tasks_insert" ON unit_turn_tasks FOR INSERT WITH CHECK (unit_turn_id IN (SELECT id FROM unit_turns WHERE company_id = requesting_company_id()));
CREATE POLICY "turn_tasks_update" ON unit_turn_tasks FOR UPDATE USING (unit_turn_id IN (SELECT id FROM unit_turns WHERE company_id = requesting_company_id()));

CREATE POLICY "thresholds_select" ON approval_thresholds FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "thresholds_insert" ON approval_thresholds FOR INSERT WITH CHECK (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));
CREATE POLICY "thresholds_update" ON approval_thresholds FOR UPDATE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- Audit triggers
CREATE TRIGGER unit_turns_audit AFTER INSERT OR UPDATE OR DELETE ON unit_turns FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
