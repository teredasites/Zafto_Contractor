-- D2a: Insurance/Restoration Infrastructure
-- 7 new tables for insurance claims, supplements, TPI, Xactimate, moisture, drying, equipment

-- Insurance Claims — linked to jobs with type='insurance_claim'
CREATE TABLE insurance_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  -- Carrier info
  insurance_company TEXT NOT NULL,
  claim_number TEXT NOT NULL,
  policy_number TEXT,
  -- Loss info
  date_of_loss DATE NOT NULL,
  loss_type TEXT NOT NULL DEFAULT 'unknown' CHECK (loss_type IN ('fire','water','storm','wind','hail','theft','vandalism','mold','flood','earthquake','other','unknown')),
  loss_description TEXT,
  -- Adjuster
  adjuster_name TEXT,
  adjuster_phone TEXT,
  adjuster_email TEXT,
  adjuster_company TEXT,
  -- Financials
  deductible NUMERIC(12,2) DEFAULT 0,
  coverage_limit NUMERIC(12,2),
  approved_amount NUMERIC(12,2),
  supplement_total NUMERIC(12,2) DEFAULT 0,
  depreciation NUMERIC(12,2) DEFAULT 0,
  acv NUMERIC(12,2),
  rcv NUMERIC(12,2),
  -- Status
  claim_status TEXT NOT NULL DEFAULT 'new' CHECK (claim_status IN ('new','scope_requested','scope_submitted','estimate_pending','estimate_approved','supplement_submitted','supplement_approved','work_in_progress','work_complete','final_inspection','settled','closed','denied')),
  -- Dates
  scope_submitted_at TIMESTAMPTZ,
  estimate_approved_at TIMESTAMPTZ,
  work_started_at TIMESTAMPTZ,
  work_completed_at TIMESTAMPTZ,
  settled_at TIMESTAMPTZ,
  -- Xactimate
  xactimate_claim_id TEXT,
  xactimate_file_url TEXT,
  -- Metadata
  notes TEXT,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- Claim Supplements — additional scope + cost beyond original estimate
CREATE TABLE claim_supplements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  claim_id UUID NOT NULL REFERENCES insurance_claims(id),
  supplement_number INTEGER NOT NULL DEFAULT 1,
  title TEXT NOT NULL,
  description TEXT,
  reason TEXT NOT NULL DEFAULT 'hidden_damage' CHECK (reason IN ('hidden_damage','code_upgrade','scope_change','material_upgrade','additional_repair','other')),
  amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','submitted','under_review','approved','denied','partially_approved')),
  approved_amount NUMERIC(12,2),
  line_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,
  submitted_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  reviewer_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- TPI Scheduling — Third-Party Inspector appointments
CREATE TABLE tpi_scheduling (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  claim_id UUID NOT NULL REFERENCES insurance_claims(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  inspector_name TEXT,
  inspector_company TEXT,
  inspector_phone TEXT,
  inspector_email TEXT,
  inspection_type TEXT NOT NULL DEFAULT 'progress' CHECK (inspection_type IN ('initial','progress','supplement','final','re_inspection')),
  scheduled_date TIMESTAMPTZ,
  completed_date TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','scheduled','confirmed','in_progress','completed','cancelled','rescheduled')),
  result TEXT CHECK (result IN ('passed','failed','conditional','deferred')),
  findings TEXT,
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Xactimate Estimate Lines — imported line items from ESX files
CREATE TABLE xactimate_estimate_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  claim_id UUID NOT NULL REFERENCES insurance_claims(id),
  category TEXT NOT NULL,
  item_code TEXT,
  description TEXT NOT NULL,
  quantity NUMERIC(10,2) NOT NULL DEFAULT 1,
  unit TEXT NOT NULL DEFAULT 'EA',
  unit_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  total NUMERIC(12,2) NOT NULL DEFAULT 0,
  is_supplement BOOLEAN DEFAULT false,
  supplement_id UUID REFERENCES claim_supplements(id),
  depreciation_rate NUMERIC(5,2) DEFAULT 0,
  acv_amount NUMERIC(12,2),
  rcv_amount NUMERIC(12,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Moisture Readings — daily tracked readings per affected area
CREATE TABLE moisture_readings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  claim_id UUID REFERENCES insurance_claims(id),
  area_name TEXT NOT NULL,
  floor_level TEXT,
  material_type TEXT NOT NULL DEFAULT 'drywall' CHECK (material_type IN ('drywall','wood','concrete','carpet','pad','insulation','subfloor','hardwood','laminate','tile_backer','other')),
  reading_value NUMERIC(6,1) NOT NULL,
  reading_unit TEXT NOT NULL DEFAULT 'percent' CHECK (reading_unit IN ('percent','relative','wme','grains')),
  target_value NUMERIC(6,1),
  meter_type TEXT,
  meter_model TEXT,
  ambient_temp_f NUMERIC(5,1),
  ambient_humidity NUMERIC(5,1),
  is_dry BOOLEAN DEFAULT false,
  recorded_by_user_id UUID REFERENCES auth.users(id),
  recorded_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Drying Logs — immutable timestamped entries (legal compliance)
CREATE TABLE drying_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  claim_id UUID REFERENCES insurance_claims(id),
  log_type TEXT NOT NULL DEFAULT 'daily' CHECK (log_type IN ('setup','daily','adjustment','equipment_change','completion','note')),
  summary TEXT NOT NULL,
  details TEXT,
  equipment_count INTEGER DEFAULT 0,
  dehumidifiers_running INTEGER DEFAULT 0,
  air_movers_running INTEGER DEFAULT 0,
  air_scrubbers_running INTEGER DEFAULT 0,
  outdoor_temp_f NUMERIC(5,1),
  outdoor_humidity NUMERIC(5,1),
  indoor_temp_f NUMERIC(5,1),
  indoor_humidity NUMERIC(5,1),
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,
  recorded_by_user_id UUID REFERENCES auth.users(id),
  recorded_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
  -- NOTE: NO updated_at — drying logs are immutable (legal record)
);

-- Restoration Equipment — deployed equipment tracking with daily billing
CREATE TABLE restoration_equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  claim_id UUID REFERENCES insurance_claims(id),
  equipment_type TEXT NOT NULL CHECK (equipment_type IN ('dehumidifier','air_mover','air_scrubber','heater','moisture_meter','thermal_camera','hydroxyl_generator','negative_air_machine','other')),
  make TEXT,
  model TEXT,
  serial_number TEXT,
  asset_tag TEXT,
  area_deployed TEXT NOT NULL,
  deployed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  removed_at TIMESTAMPTZ,
  daily_rate NUMERIC(10,2) NOT NULL DEFAULT 0,
  -- total_days computed in application layer (now() is not immutable for GENERATED columns)
  status TEXT NOT NULL DEFAULT 'deployed' CHECK (status IN ('deployed','removed','maintenance','lost')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS policies
ALTER TABLE insurance_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE claim_supplements ENABLE ROW LEVEL SECURITY;
ALTER TABLE tpi_scheduling ENABLE ROW LEVEL SECURITY;
ALTER TABLE xactimate_estimate_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE moisture_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE drying_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE restoration_equipment ENABLE ROW LEVEL SECURITY;

CREATE POLICY insurance_claims_company ON insurance_claims FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY claim_supplements_company ON claim_supplements FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY tpi_company ON tpi_scheduling FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY xactimate_company ON xactimate_estimate_lines FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY moisture_company ON moisture_readings FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY drying_logs_company ON drying_logs FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY equipment_company ON restoration_equipment FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Drying logs: INSERT-only (immutable audit trail — legal compliance)
-- Drop the ALL policy and replace with specific policies
DROP POLICY drying_logs_company ON drying_logs;
CREATE POLICY drying_logs_select ON drying_logs FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY drying_logs_insert ON drying_logs FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
-- No UPDATE or DELETE policies on drying_logs — immutable

-- Indexes
CREATE INDEX idx_claims_job ON insurance_claims(job_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_claims_company ON insurance_claims(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_claims_status ON insurance_claims(claim_status) WHERE deleted_at IS NULL;
CREATE INDEX idx_supplements_claim ON claim_supplements(claim_id);
CREATE INDEX idx_tpi_claim ON tpi_scheduling(claim_id);
CREATE INDEX idx_moisture_job ON moisture_readings(job_id);
CREATE INDEX idx_drying_job ON drying_logs(job_id);
CREATE INDEX idx_equipment_job ON restoration_equipment(job_id);

-- Audit triggers (reuse existing update_updated_at function)
CREATE TRIGGER insurance_claims_updated BEFORE UPDATE ON insurance_claims FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER claim_supplements_updated BEFORE UPDATE ON claim_supplements FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tpi_updated BEFORE UPDATE ON tpi_scheduling FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER equipment_updated BEFORE UPDATE ON restoration_equipment FOR EACH ROW EXECUTE FUNCTION update_updated_at();
