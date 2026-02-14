-- U20: Subcontractor Management
-- Dedicated subcontractors table + job_subcontractors bridge

CREATE TABLE IF NOT EXISTS subcontractors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  name text NOT NULL,
  company_name text,
  email text,
  phone text,
  trade_types text[] NOT NULL DEFAULT '{}',
  license_number text,
  license_state text,
  license_expiry date,
  insurance_carrier text,
  insurance_policy_number text,
  insurance_expiry date,
  w9_on_file boolean NOT NULL DEFAULT false,
  notes text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','suspended')),
  rating numeric(2,1) CHECK (rating >= 1 AND rating <= 5),
  total_jobs_assigned int NOT NULL DEFAULT 0,
  total_paid numeric(12,2) NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE IF NOT EXISTS job_subcontractors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  job_id uuid NOT NULL REFERENCES jobs(id),
  subcontractor_id uuid NOT NULL REFERENCES subcontractors(id),
  scope_description text,
  agreed_amount numeric(12,2) NOT NULL DEFAULT 0,
  paid_amount numeric(12,2) NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'assigned' CHECK (status IN ('assigned','in_progress','completed','disputed')),
  start_date date,
  end_date date,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE subcontractors ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_subcontractors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sub_select" ON subcontractors FOR SELECT USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "sub_insert" ON subcontractors FOR INSERT WITH CHECK (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "sub_update" ON subcontractors FOR UPDATE USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "sub_delete" ON subcontractors FOR DELETE USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "job_sub_select" ON job_subcontractors FOR SELECT USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "job_sub_insert" ON job_subcontractors FOR INSERT WITH CHECK (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "job_sub_update" ON job_subcontractors FOR UPDATE USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "job_sub_delete" ON job_subcontractors FOR DELETE USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

-- Indexes
CREATE INDEX idx_subcontractors_company ON subcontractors(company_id);
CREATE INDEX idx_subcontractors_status ON subcontractors(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_subcontractors_trade ON subcontractors USING gin(trade_types);
CREATE INDEX idx_job_sub_job ON job_subcontractors(job_id);
CREATE INDEX idx_job_sub_sub ON job_subcontractors(subcontractor_id);
CREATE INDEX idx_sub_insurance_expiry ON subcontractors(insurance_expiry) WHERE insurance_expiry IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_sub_license_expiry ON subcontractors(license_expiry) WHERE license_expiry IS NOT NULL AND deleted_at IS NULL;

-- Triggers
CREATE TRIGGER set_updated_at BEFORE UPDATE ON subcontractors FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON job_subcontractors FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER audit_subcontractors AFTER INSERT OR UPDATE OR DELETE ON subcontractors FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
