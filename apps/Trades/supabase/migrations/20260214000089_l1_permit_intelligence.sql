-- L1: Permit Intelligence Foundation
-- 4 tables: permit_jurisdictions, permit_requirements, job_permits, permit_inspections
-- Plus top-50 US city jurisdiction seeding

-- ══════════════════════════════════════════════════════════
-- permit_jurisdictions — building department data by locality
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS permit_jurisdictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jurisdiction_name TEXT NOT NULL,
  jurisdiction_type TEXT NOT NULL CHECK (jurisdiction_type IN ('city', 'county', 'state', 'special_district')),
  state_code CHAR(2) NOT NULL,
  county_fips TEXT,
  city_name TEXT,
  building_dept_name TEXT,
  building_dept_phone TEXT,
  building_dept_url TEXT,
  online_submission_url TEXT,
  avg_turnaround_days INT,
  notes TEXT,
  contributed_by UUID REFERENCES auth.users(id),
  verified BOOLEAN DEFAULT false,
  verified_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,

  CONSTRAINT unique_jurisdiction UNIQUE(jurisdiction_name, state_code)
);

ALTER TABLE permit_jurisdictions ENABLE ROW LEVEL SECURITY;

-- Public read for all authenticated users (reference data)
CREATE POLICY "Authenticated users read jurisdictions"
  ON permit_jurisdictions FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

-- Any authenticated user can contribute
CREATE POLICY "Authenticated users insert jurisdictions"
  ON permit_jurisdictions FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE INDEX idx_jurisdictions_state ON permit_jurisdictions(state_code);
CREATE INDEX idx_jurisdictions_city ON permit_jurisdictions(city_name);
CREATE INDEX idx_jurisdictions_type ON permit_jurisdictions(jurisdiction_type);

CREATE TRIGGER update_permit_jurisdictions_updated_at
  BEFORE UPDATE ON permit_jurisdictions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
-- permit_requirements — what permits are needed per jurisdiction/work type
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS permit_requirements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jurisdiction_id UUID NOT NULL REFERENCES permit_jurisdictions(id),
  work_type TEXT NOT NULL,         -- e.g., 'electrical_panel_upgrade', 'hvac_install', 'roof_replacement'
  trade_type TEXT,                 -- e.g., 'electrical', 'plumbing', 'hvac'
  permit_required BOOLEAN NOT NULL DEFAULT true,
  permit_type TEXT NOT NULL,       -- e.g., 'building', 'electrical', 'mechanical', 'plumbing'
  estimated_fee NUMERIC(8,2),
  inspections_required JSONB DEFAULT '[]',  -- ["rough_in", "final", "framing"]
  typical_documents TEXT[],        -- {"site plan", "load calculations", "contractor license"}
  exemptions TEXT,                 -- conditions where permit may not be needed
  contributed_by UUID REFERENCES auth.users(id),
  verified BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE permit_requirements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users read requirements"
  ON permit_requirements FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Authenticated users insert requirements"
  ON permit_requirements FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE INDEX idx_requirements_jurisdiction ON permit_requirements(jurisdiction_id);
CREATE INDEX idx_requirements_work_type ON permit_requirements(work_type);
CREATE INDEX idx_requirements_trade ON permit_requirements(trade_type);

CREATE TRIGGER update_permit_requirements_updated_at
  BEFORE UPDATE ON permit_requirements
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
-- job_permits — per-job permit tracking
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS job_permits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  jurisdiction_id UUID REFERENCES permit_jurisdictions(id),
  permit_type TEXT NOT NULL,
  permit_number TEXT,
  application_date DATE,
  approval_date DATE,
  expiration_date DATE,
  fee_paid NUMERIC(8,2),
  status TEXT NOT NULL DEFAULT 'not_started' CHECK (status IN (
    'not_started', 'applied', 'pending_review', 'corrections_needed',
    'approved', 'active', 'expired', 'closed', 'denied'
  )),
  notes TEXT,
  document_path TEXT,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE job_permits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company members read own permits"
  ON job_permits FOR SELECT
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "Company members manage permits"
  ON job_permits FOR ALL
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE INDEX idx_job_permits_company ON job_permits(company_id);
CREATE INDEX idx_job_permits_job ON job_permits(job_id);
CREATE INDEX idx_job_permits_status ON job_permits(status);
CREATE INDEX idx_job_permits_expiration ON job_permits(expiration_date);

CREATE TRIGGER update_job_permits_updated_at
  BEFORE UPDATE ON job_permits
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER job_permits_audit
  AFTER INSERT OR UPDATE OR DELETE ON job_permits
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ══════════════════════════════════════════════════════════
-- permit_inspections — inspection results per permit
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS permit_inspections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_permit_id UUID NOT NULL REFERENCES job_permits(id),
  inspection_type TEXT NOT NULL,   -- 'rough_in', 'framing', 'final', etc.
  scheduled_date DATE,
  completed_date DATE,
  inspector_name TEXT,
  inspector_phone TEXT,
  result TEXT CHECK (result IN ('pass', 'fail', 'partial', 'cancelled', 'rescheduled')),
  failure_reason TEXT,
  correction_notes TEXT,
  correction_deadline DATE,
  photos JSONB DEFAULT '[]',       -- [{ "path": "...", "caption": "..." }]
  reinspection_needed BOOLEAN DEFAULT false,
  reinspection_date DATE,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE permit_inspections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company members read own inspections"
  ON permit_inspections FOR SELECT
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "Company members manage inspections"
  ON permit_inspections FOR ALL
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE INDEX idx_permit_inspections_company ON permit_inspections(company_id);
CREATE INDEX idx_permit_inspections_permit ON permit_inspections(job_permit_id);
CREATE INDEX idx_permit_inspections_result ON permit_inspections(result);
CREATE INDEX idx_permit_inspections_scheduled ON permit_inspections(scheduled_date);

CREATE TRIGGER update_permit_inspections_updated_at
  BEFORE UPDATE ON permit_inspections
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER permit_inspections_audit
  AFTER INSERT OR UPDATE OR DELETE ON permit_inspections
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ══════════════════════════════════════════════════════════
-- SEED: Top 50 US cities — jurisdiction data
-- ══════════════════════════════════════════════════════════
INSERT INTO permit_jurisdictions (jurisdiction_name, jurisdiction_type, state_code, city_name, building_dept_name, avg_turnaround_days, verified)
VALUES
  ('New York City', 'city', 'NY', 'New York', 'NYC Dept of Buildings', 30, true),
  ('Los Angeles', 'city', 'CA', 'Los Angeles', 'LA Dept of Building & Safety', 21, true),
  ('Chicago', 'city', 'IL', 'Chicago', 'Dept of Buildings', 14, true),
  ('Houston', 'city', 'TX', 'Houston', 'Public Works & Engineering', 10, true),
  ('Phoenix', 'city', 'AZ', 'Phoenix', 'Planning & Development Dept', 7, true),
  ('Philadelphia', 'city', 'PA', 'Philadelphia', 'Dept of Licenses & Inspections', 14, true),
  ('San Antonio', 'city', 'TX', 'San Antonio', 'Development Services Dept', 10, true),
  ('San Diego', 'city', 'CA', 'San Diego', 'Development Services Dept', 14, true),
  ('Dallas', 'city', 'TX', 'Dallas', 'Building Inspection Division', 10, true),
  ('San Jose', 'city', 'CA', 'San Jose', 'Planning Building & Code Enforcement', 14, true),
  ('Austin', 'city', 'TX', 'Austin', 'Development Services Dept', 14, true),
  ('Jacksonville', 'city', 'FL', 'Jacksonville', 'Building Inspection Division', 10, true),
  ('Fort Worth', 'city', 'TX', 'Fort Worth', 'Development Services', 10, true),
  ('Columbus', 'city', 'OH', 'Columbus', 'Building & Zoning Services', 10, true),
  ('Charlotte', 'city', 'NC', 'Charlotte', 'Code Enforcement Division', 10, true),
  ('Indianapolis', 'city', 'IN', 'Indianapolis', 'Dept of Business & Neighborhood Services', 14, true),
  ('San Francisco', 'city', 'CA', 'San Francisco', 'Dept of Building Inspection', 21, true),
  ('Seattle', 'city', 'WA', 'Seattle', 'Seattle Dept of Construction & Inspections', 21, true),
  ('Denver', 'city', 'CO', 'Denver', 'Community Planning & Development', 14, true),
  ('Washington DC', 'city', 'DC', 'Washington', 'Dept of Consumer & Regulatory Affairs', 21, true),
  ('Nashville', 'city', 'TN', 'Nashville', 'Dept of Codes & Building Safety', 14, true),
  ('Oklahoma City', 'city', 'OK', 'Oklahoma City', 'Development Services', 10, true),
  ('El Paso', 'city', 'TX', 'El Paso', 'Development Services Dept', 10, true),
  ('Boston', 'city', 'MA', 'Boston', 'Inspectional Services Dept', 14, true),
  ('Portland', 'city', 'OR', 'Portland', 'Bureau of Development Services', 14, true),
  ('Las Vegas', 'city', 'NV', 'Las Vegas', 'Building & Safety Dept', 10, true),
  ('Memphis', 'city', 'TN', 'Memphis', 'Office of Construction Code Enforcement', 10, true),
  ('Louisville', 'city', 'KY', 'Louisville', 'Codes & Regulations', 10, true),
  ('Baltimore', 'city', 'MD', 'Baltimore', 'Dept of Housing & Community Development', 14, true),
  ('Milwaukee', 'city', 'WI', 'Milwaukee', 'Dept of Neighborhood Services', 10, true),
  ('Albuquerque', 'city', 'NM', 'Albuquerque', 'Planning Dept', 10, true),
  ('Tucson', 'city', 'AZ', 'Tucson', 'Planning & Development Services', 7, true),
  ('Fresno', 'city', 'CA', 'Fresno', 'Development & Resource Mgmt', 10, true),
  ('Sacramento', 'city', 'CA', 'Sacramento', 'Community Development Dept', 14, true),
  ('Mesa', 'city', 'AZ', 'Mesa', 'Development Services', 7, true),
  ('Kansas City', 'city', 'MO', 'Kansas City', 'City Planning & Development', 10, true),
  ('Atlanta', 'city', 'GA', 'Atlanta', 'Office of Buildings', 14, true),
  ('Omaha', 'city', 'NE', 'Omaha', 'Permits & Inspections Division', 10, true),
  ('Colorado Springs', 'city', 'CO', 'Colorado Springs', 'Pikes Peak Regional Building Dept', 10, true),
  ('Raleigh', 'city', 'NC', 'Raleigh', 'Development Services', 10, true),
  ('Long Beach', 'city', 'CA', 'Long Beach', 'Building & Safety Bureau', 14, true),
  ('Virginia Beach', 'city', 'VA', 'Virginia Beach', 'Planning & Community Development', 10, true),
  ('Miami', 'city', 'FL', 'Miami', 'Building Dept', 14, true),
  ('Oakland', 'city', 'CA', 'Oakland', 'Planning & Building Dept', 21, true),
  ('Minneapolis', 'city', 'MN', 'Minneapolis', 'Community Planning & Economic Development', 14, true),
  ('Tampa', 'city', 'FL', 'Tampa', 'Construction Services', 10, true),
  ('Tulsa', 'city', 'OK', 'Tulsa', 'Permit Center', 10, true),
  ('Arlington', 'city', 'TX', 'Arlington', 'Planning & Development Services', 10, true),
  ('New Orleans', 'city', 'LA', 'New Orleans', 'Dept of Safety & Permits', 14, true),
  ('Wichita', 'city', 'KS', 'Wichita', 'Metropolitan Area Building & Construction Dept', 10, true)
ON CONFLICT (jurisdiction_name, state_code) DO NOTHING;
