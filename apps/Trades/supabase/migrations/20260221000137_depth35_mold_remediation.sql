-- DEPTH35: Mold Remediation Module
-- Assessment → containment → remediation → clearance
-- IICRC S520 standards, moisture mapping, lab tracking,
-- equipment management, state licensing, scope templates.

-- ============================================================================
-- MOLD STATE LICENSING (system-wide reference — no company_id)
-- ============================================================================

CREATE TABLE IF NOT EXISTS mold_state_licensing (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  state_code        text NOT NULL UNIQUE,
  state_name        text NOT NULL,
  license_required  boolean NOT NULL DEFAULT false,
  license_types     jsonb DEFAULT '[]',
  issuing_agency    text,
  agency_url        text,
  cost_range        text,
  renewal_period    text,
  ce_requirements   text,
  reciprocity_states jsonb DEFAULT '[]',
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE mold_state_licensing ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mold_licensing_select" ON mold_state_licensing
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "mold_licensing_system" ON mold_state_licensing
  FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('mold_state_licensing');

-- Seed state licensing data (key states with mold licensing laws)
INSERT INTO mold_state_licensing (state_code, state_name, license_required, license_types, issuing_agency, agency_url, cost_range, renewal_period, notes) VALUES
('TX', 'Texas', true, '["Mold Assessment Technician","Mold Remediation Technician"]', 'Texas Department of Licensing and Regulation (TDLR)', 'tdlr.texas.gov', '$200-$400', '1 year', 'Both assessment and remediation require separate licenses. 24hr CE required for renewal.'),
('FL', 'Florida', true, '["Mold Assessor","Mold Remediator"]', 'Dept of Business and Professional Regulation (DBPR)', 'myfloridalicense.com', '$250-$500', '2 years', 'Separate licenses for assessment and remediation. 14hr CE per cycle.'),
('LA', 'Louisiana', true, '["Mold Remediation Contractor"]', 'Louisiana State Licensing Board for Contractors', 'lslbc.louisiana.gov', '$100-$300', '1 year', 'Contractor license with mold specialty.'),
('MD', 'Maryland', true, '["Mold Inspector","Mold Remediator"]', 'Maryland Dept of the Environment (MDE)', 'mde.maryland.gov', '$150-$400', '2 years', 'Both assessment and remediation require licenses.'),
('NH', 'New Hampshire', true, '["Indoor Air Quality Investigator"]', 'NH Dept of Health and Human Services', 'dhhs.nh.gov', '$100-$200', '2 years', 'Indoor environmental professional certification.'),
('NY', 'New York', true, '["Mold Assessment License","Mold Remediation License"]', 'NY Dept of Labor', 'labor.ny.gov', '$200-$600', '2 years', 'Article 32 — Mold Program. Both licenses required. Strict notification requirements.'),
('VA', 'Virginia', true, '["Mold Inspector","Mold Remediator"]', 'Dept of Professional and Occupational Regulation (DPOR)', 'dpor.virginia.gov', '$150-$300', '2 years', 'Separate licenses. 16hr CE per cycle.'),
('IL', 'Illinois', true, '["Mold Inspector","Mold Remediation Worker"]', 'Illinois Dept of Public Health (IDPH)', 'dph.illinois.gov', '$100-$250', '3 years', 'Licensing under Mold Inspection and Remediation Act.'),
('MS', 'Mississippi', true, '["Mold Remediation Contractor"]', 'Mississippi State Board of Contractors', 'msboc.us', '$100-$200', '1 year', 'Contractor license required for remediation over 25 sq ft.'),
('CT', 'Connecticut', true, '["Mold Assessor","Mold Remediator"]', 'CT Dept of Public Health', 'portal.ct.gov/dph', '$150-$350', '2 years', 'Indoor Environmental Professional certification program.'),
('AL', 'Alabama', false, '[]', null, null, null, null, 'No specific mold licensing law. General contractor license may apply.'),
('AK', 'Alaska', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('AZ', 'Arizona', false, '[]', null, null, null, null, 'No mold licensing. ROC contractor license covers remediation work.'),
('AR', 'Arkansas', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('CA', 'California', false, '[]', null, null, null, null, 'No mold-specific license. General B or C-21 license covers remediation.'),
('CO', 'Colorado', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('DE', 'Delaware', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('GA', 'Georgia', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('HI', 'Hawaii', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('ID', 'Idaho', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('IN', 'Indiana', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('IA', 'Iowa', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('KS', 'Kansas', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('KY', 'Kentucky', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('ME', 'Maine', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('MA', 'Massachusetts', false, '[]', null, null, null, null, 'No mold-specific license. HIC registration covers work.'),
('MI', 'Michigan', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('MN', 'Minnesota', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('MO', 'Missouri', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('MT', 'Montana', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('NE', 'Nebraska', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('NV', 'Nevada', false, '[]', null, null, null, null, 'No specific mold licensing. Contractor license covers work.'),
('NJ', 'New Jersey', false, '[]', null, null, null, null, 'No specific mold licensing. HIC registration covers work.'),
('NM', 'New Mexico', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('NC', 'North Carolina', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('ND', 'North Dakota', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('OH', 'Ohio', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('OK', 'Oklahoma', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('OR', 'Oregon', false, '[]', null, null, null, null, 'No mold-specific license. CCB license covers remediation.'),
('PA', 'Pennsylvania', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('RI', 'Rhode Island', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('SC', 'South Carolina', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('SD', 'South Dakota', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('TN', 'Tennessee', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('UT', 'Utah', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('VT', 'Vermont', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('WA', 'Washington', false, '[]', null, null, null, null, 'No mold-specific license. General contractor registration covers work.'),
('WV', 'West Virginia', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('WI', 'Wisconsin', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('WY', 'Wyoming', false, '[]', null, null, null, null, 'No specific mold licensing requirements.'),
('DC', 'District of Columbia', false, '[]', null, null, null, null, 'No specific mold licensing requirements.')
ON CONFLICT (state_code) DO NOTHING;

-- ============================================================================
-- MOLD ASSESSMENTS (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS mold_assessments (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES companies(id),
  property_id         uuid REFERENCES properties(id),
  job_id              uuid REFERENCES jobs(id),
  assessed_by         uuid REFERENCES auth.users(id),
  assessment_date     timestamptz NOT NULL DEFAULT now(),
  suspected_cause     text CHECK (suspected_cause IS NULL OR suspected_cause IN (
    'water_intrusion', 'hvac_issue', 'plumbing_leak', 'flooding',
    'condensation', 'unknown', 'roof_leak', 'foundation_crack'
  )),
  affected_area_sqft  numeric(8,1),
  affected_materials  jsonb DEFAULT '[]',
  visible_mold_type   jsonb DEFAULT '[]',
  moisture_source_status text CHECK (moisture_source_status IS NULL OR moisture_source_status IN (
    'active_leak', 'resolved', 'unknown'
  )),
  occupancy_status    text CHECK (occupancy_status IS NULL OR occupancy_status IN (
    'occupied', 'vacant', 'evacuated'
  )),
  remediation_level   integer CHECK (remediation_level IS NULL OR remediation_level BETWEEN 1 AND 3),
  overall_notes       text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  deleted_at          timestamptz
);

CREATE INDEX idx_mold_assess_company ON mold_assessments (company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_mold_assess_property ON mold_assessments (property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_mold_assess_job ON mold_assessments (job_id) WHERE deleted_at IS NULL;

ALTER TABLE mold_assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mold_assess_select" ON mold_assessments
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

CREATE POLICY "mold_assess_insert" ON mold_assessments
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "mold_assess_update" ON mold_assessments
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('mold_assessments');
SELECT audit_trigger_fn('mold_assessments');

-- ============================================================================
-- MOLD MOISTURE READINGS (company-scoped, linked to assessment)
-- ============================================================================

CREATE TABLE IF NOT EXISTS mold_moisture_readings (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  assessment_id     uuid NOT NULL REFERENCES mold_assessments(id),
  room_name         text NOT NULL,
  location_detail   text,
  reading_type      text NOT NULL CHECK (reading_type IN (
    'surface_pin', 'relative_humidity', 'dew_point', 'wood_moisture_content'
  )),
  reading_value     numeric(8,2) NOT NULL,
  reading_unit      text NOT NULL DEFAULT '%',
  severity          text CHECK (severity IS NULL OR severity IN ('normal', 'concern', 'saturation')),
  meter_model       text,
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_mold_moisture_assessment ON mold_moisture_readings (assessment_id);
CREATE INDEX idx_mold_moisture_company ON mold_moisture_readings (company_id);

ALTER TABLE mold_moisture_readings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mold_moisture_select" ON mold_moisture_readings
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "mold_moisture_insert" ON mold_moisture_readings
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- MOLD REMEDIATION PLANS (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS mold_remediation_plans (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  assessment_id     uuid NOT NULL REFERENCES mold_assessments(id),
  job_id            uuid REFERENCES jobs(id),
  remediation_level integer NOT NULL CHECK (remediation_level BETWEEN 1 AND 3),
  containment_type  text CHECK (containment_type IS NULL OR containment_type IN (
    'minimal', 'limited', 'full'
  )),
  scope_description text,
  materials_to_remove jsonb DEFAULT '[]',
  checklist_progress jsonb DEFAULT '{}',
  status            text NOT NULL DEFAULT 'planned'
    CHECK (status IN ('planned', 'in_progress', 'completed', 'on_hold')),
  started_at        timestamptz,
  completed_at      timestamptz,
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

CREATE INDEX idx_mold_remed_company ON mold_remediation_plans (company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_mold_remed_assessment ON mold_remediation_plans (assessment_id) WHERE deleted_at IS NULL;

ALTER TABLE mold_remediation_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mold_remed_select" ON mold_remediation_plans
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

CREATE POLICY "mold_remed_insert" ON mold_remediation_plans
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "mold_remed_update" ON mold_remediation_plans
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('mold_remediation_plans');
SELECT audit_trigger_fn('mold_remediation_plans');

-- ============================================================================
-- MOLD EQUIPMENT DEPLOYMENTS (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS mold_equipment_deployments (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  remediation_id    uuid REFERENCES mold_remediation_plans(id),
  equipment_type    text NOT NULL CHECK (equipment_type IN (
    'dehumidifier', 'air_scrubber', 'negative_air_machine',
    'air_mover', 'moisture_meter', 'thermo_hygrometer',
    'hepa_vacuum', 'sprayer', 'other'
  )),
  model_name        text,
  serial_number     text,
  capacity          text,
  placement_location text,
  deployed_at       timestamptz NOT NULL DEFAULT now(),
  retrieved_at      timestamptz,
  runtime_hours     numeric(8,1),
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_mold_equip_company ON mold_equipment_deployments (company_id);
CREATE INDEX idx_mold_equip_remed ON mold_equipment_deployments (remediation_id);

ALTER TABLE mold_equipment_deployments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mold_equip_select" ON mold_equipment_deployments
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "mold_equip_insert" ON mold_equipment_deployments
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "mold_equip_update" ON mold_equipment_deployments
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('mold_equipment_deployments');

-- ============================================================================
-- MOLD LAB SAMPLES (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS mold_lab_samples (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  assessment_id     uuid REFERENCES mold_assessments(id),
  sample_type       text NOT NULL CHECK (sample_type IN (
    'air_cassette', 'tape_lift', 'bulk_swab', 'surface_wipe'
  )),
  sample_location   text NOT NULL,
  room_name         text,
  date_collected    timestamptz NOT NULL DEFAULT now(),
  collected_by      uuid REFERENCES auth.users(id),
  lab_name          text,
  lab_reference     text,
  status            text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'sent', 'received', 'results_in')),
  species_found     jsonb DEFAULT '[]',
  spore_count       numeric(12,0),
  spore_count_unit  text DEFAULT 'spores_per_m3',
  outdoor_baseline  numeric(12,0),
  pass_fail         text CHECK (pass_fail IS NULL OR pass_fail IN ('pass', 'fail', 'inconclusive')),
  results_notes     text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

CREATE INDEX idx_mold_lab_company ON mold_lab_samples (company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_mold_lab_assessment ON mold_lab_samples (assessment_id) WHERE deleted_at IS NULL;

ALTER TABLE mold_lab_samples ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mold_lab_select" ON mold_lab_samples
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

CREATE POLICY "mold_lab_insert" ON mold_lab_samples
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "mold_lab_update" ON mold_lab_samples
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('mold_lab_samples');
SELECT audit_trigger_fn('mold_lab_samples');

-- ============================================================================
-- MOLD CLEARANCE TESTS (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS mold_clearance_tests (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  remediation_id    uuid REFERENCES mold_remediation_plans(id),
  assessment_id     uuid REFERENCES mold_assessments(id),
  clearance_date    timestamptz NOT NULL DEFAULT now(),
  assessor_name     text,
  assessor_company  text,
  assessor_license  text,
  visual_pass       boolean,
  moisture_pass     boolean,
  air_quality_pass  boolean,
  odor_pass         boolean,
  overall_result    text CHECK (overall_result IS NULL OR overall_result IN ('pass', 'fail', 'conditional')),
  post_moisture_readings jsonb DEFAULT '[]',
  lab_results_ref   text,
  certificate_number text,
  certificate_url   text,
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

CREATE INDEX idx_mold_clear_company ON mold_clearance_tests (company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_mold_clear_remed ON mold_clearance_tests (remediation_id) WHERE deleted_at IS NULL;

ALTER TABLE mold_clearance_tests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mold_clear_select" ON mold_clearance_tests
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

CREATE POLICY "mold_clear_insert" ON mold_clearance_tests
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "mold_clear_update" ON mold_clearance_tests
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('mold_clearance_tests');
SELECT audit_trigger_fn('mold_clearance_tests');
