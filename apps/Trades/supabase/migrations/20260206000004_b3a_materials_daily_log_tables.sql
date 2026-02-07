-- ============================================================
-- ZAFTO CORE SCHEMA — B3a: Materials + Daily Log Tables
-- Sprint B3a | Session 47
--
-- Run against: dev first, then staging, then prod
-- Tables: job_materials, daily_logs
-- Depends on: A3a (companies, users), A3b (jobs), A3c (receipts)
-- ============================================================

-- MATERIALS / EQUIPMENT USED ON JOB
CREATE TABLE job_materials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid NOT NULL REFERENCES jobs(id),
  added_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  name text NOT NULL,
  description text,
  category text DEFAULT 'material' CHECK (category IN ('material', 'equipment', 'tool', 'consumable', 'rental')),
  quantity numeric(10,2) NOT NULL DEFAULT 1,
  unit text DEFAULT 'each',
  unit_cost numeric(12,2),
  total_cost numeric(12,2),
  vendor text,
  receipt_id uuid REFERENCES receipts(id),
  is_billable boolean DEFAULT true,
  installed_at timestamptz,
  serial_number text,
  warranty_info text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE job_materials ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_job_materials_job ON job_materials (job_id);
CREATE TRIGGER job_materials_updated_at BEFORE UPDATE ON job_materials FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER job_materials_audit AFTER INSERT OR UPDATE OR DELETE ON job_materials FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "job_materials_select" ON job_materials FOR SELECT USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY "job_materials_insert" ON job_materials FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "job_materials_update" ON job_materials FOR UPDATE USING (company_id = requesting_company_id());

-- DAILY JOB LOG ENTRIES
CREATE TABLE daily_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid NOT NULL REFERENCES jobs(id),
  author_user_id uuid NOT NULL REFERENCES auth.users(id),
  log_date date NOT NULL DEFAULT CURRENT_DATE,
  weather text,
  temperature_f int,
  summary text NOT NULL,
  work_performed text,
  issues text,
  delays text,
  visitors text,
  crew_members uuid[] DEFAULT '{}',
  crew_count int DEFAULT 1,
  hours_worked numeric(4,1),
  photo_ids uuid[] DEFAULT '{}',
  safety_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE daily_logs ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_daily_logs_job_date ON daily_logs (job_id, log_date DESC);
CREATE UNIQUE INDEX idx_daily_logs_unique_per_day ON daily_logs (job_id, log_date);
CREATE TRIGGER daily_logs_updated_at BEFORE UPDATE ON daily_logs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER daily_logs_audit AFTER INSERT OR UPDATE OR DELETE ON daily_logs FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "daily_logs_select" ON daily_logs FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "daily_logs_insert" ON daily_logs FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "daily_logs_update" ON daily_logs FOR UPDATE USING (company_id = requesting_company_id());
