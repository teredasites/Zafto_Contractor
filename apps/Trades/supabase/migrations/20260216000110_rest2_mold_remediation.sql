-- ZAFTO Migration: REST2 — Mold Remediation Dedicated Tools
-- Sprint REST2 (Session 131)
-- Tables: mold_assessments, mold_chain_of_custody, mold_state_regulations, mold_labs
-- IICRC S520 compliant: severity levels 1-3, containment, air sampling, clearance

-- =============================================================================
-- MOLD ASSESSMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS mold_assessments (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id            uuid NOT NULL REFERENCES companies(id),
  job_id                uuid NOT NULL REFERENCES jobs(id),
  insurance_claim_id    uuid REFERENCES insurance_claims(id),
  created_by_user_id    uuid REFERENCES auth.users(id),

  -- IICRC S520 classification
  iicrc_level           smallint NOT NULL DEFAULT 2
    CHECK (iicrc_level BETWEEN 1 AND 3),

  -- Affected area
  affected_area_sqft    numeric(10,2),
  mold_type             text,  -- visual categorization (always recommend lab confirmation)
  moisture_source       text,  -- identified moisture source feeding mold growth

  -- Containment
  containment_type      text NOT NULL DEFAULT 'none'
    CHECK (containment_type IN ('none', 'limited', 'full')),
  negative_pressure     boolean NOT NULL DEFAULT false,
  containment_notes     text,

  -- Containment integrity checks (JSONB: daily log)
  -- Each: { date, time, inspector, pressure_reading, integrity_pass, notes }
  containment_checks    jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- Air sampling
  air_sampling_required boolean NOT NULL DEFAULT false,
  pre_samples           jsonb NOT NULL DEFAULT '[]'::jsonb,   -- pre-remediation samples
  post_samples          jsonb NOT NULL DEFAULT '[]'::jsonb,  -- post-remediation samples
  outdoor_baseline      jsonb,                                 -- outdoor reference sample

  -- Clearance
  clearance_status      text NOT NULL DEFAULT 'pending'
    CHECK (clearance_status IN ('pending', 'sampling', 'awaiting_results', 'passed', 'failed', 'not_required')),
  clearance_date        timestamptz,
  clearance_inspector   text,
  clearance_company     text,

  -- Lab info
  lab_name              text,
  lab_sample_id         text,
  spore_count_before    numeric(12,2),
  spore_count_after     numeric(12,2),

  -- Remediation protocol
  protocol_level        text  -- e.g., 'iicrc_s520_level_2'
    CHECK (protocol_level IS NULL OR protocol_level IN (
      'iicrc_s520_level_1', 'iicrc_s520_level_2', 'iicrc_s520_level_3'
    )),

  -- Protocol steps (JSONB checklist)
  -- Each: { step_number, description, completed, completed_at, completed_by }
  protocol_steps        jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- Material removal scope
  -- Each: { room, material, area_sqft, cut_line_height, removal_method, disposed }
  material_removal      jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- Equipment deployed (HEPA vacuums, air scrubbers, dehumidifiers)
  -- Each: { equipment_type, model, serial_number, deployed_at, location, removed_at }
  equipment_deployed    jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- PPE requirements
  ppe_level             text DEFAULT 'standard'
    CHECK (ppe_level IS NULL OR ppe_level IN ('minimum', 'standard', 'full', 'hazmat')),

  -- Antimicrobial treatment
  -- Each: { product, epa_registration, application_method, area, applied_at, applied_by }
  antimicrobial_treatments jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- Photos
  photos                jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- Assessment status
  assessment_status     text NOT NULL DEFAULT 'in_progress'
    CHECK (assessment_status IN ('in_progress', 'pending_review', 'remediation_active', 'awaiting_clearance', 'cleared', 'failed_clearance')),

  -- Notes
  notes                 text,

  -- Soft delete + audit
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  deleted_at            timestamptz
);

CREATE INDEX idx_mold_assessments_company ON mold_assessments(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_mold_assessments_job ON mold_assessments(job_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_mold_assessments_claim ON mold_assessments(insurance_claim_id) WHERE deleted_at IS NULL AND insurance_claim_id IS NOT NULL;
CREATE INDEX idx_mold_assessments_clearance ON mold_assessments(clearance_status) WHERE deleted_at IS NULL;

CREATE TRIGGER mold_assessments_updated_at
  BEFORE UPDATE ON mold_assessments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER mold_assessments_audit
  AFTER INSERT OR UPDATE OR DELETE ON mold_assessments
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

ALTER TABLE mold_assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY mold_assessments_select ON mold_assessments
  FOR SELECT USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
    OR (auth.jwt()->'app_metadata'->>'role')::text = 'super_admin'
  );

CREATE POLICY mold_assessments_insert ON mold_assessments
  FOR INSERT WITH CHECK (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

CREATE POLICY mold_assessments_update ON mold_assessments
  FOR UPDATE USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
    AND (auth.jwt()->'app_metadata'->>'role')::text IN ('owner', 'admin', 'office_manager', 'technician')
  );

CREATE POLICY mold_assessments_delete ON mold_assessments
  FOR DELETE USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
    AND (auth.jwt()->'app_metadata'->>'role')::text IN ('owner', 'admin')
  );

-- =============================================================================
-- MOLD CHAIN OF CUSTODY (lab sample tracking)
-- =============================================================================

CREATE TABLE IF NOT EXISTS mold_chain_of_custody (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id            uuid NOT NULL REFERENCES companies(id),
  mold_assessment_id    uuid NOT NULL REFERENCES mold_assessments(id) ON DELETE CASCADE,

  -- Sample info
  sample_type           text NOT NULL
    CHECK (sample_type IN ('air', 'surface', 'bulk', 'tape_lift')),
  sample_location       text NOT NULL,
  sample_id_external    text,  -- lab-assigned sample ID

  -- Chain of custody timeline
  collected_by          text,
  collected_at          timestamptz,
  shipped_to_lab_at     timestamptz,
  lab_received_at       timestamptz,
  results_available_at  timestamptz,

  -- Lab info
  lab_name              text,
  lab_aiha_accredited   boolean DEFAULT false,

  -- Results
  result_data           jsonb,  -- structured lab results
  result_summary        text,   -- human-readable summary
  pass_fail             text
    CHECK (pass_fail IS NULL OR pass_fail IN ('pass', 'fail', 'inconclusive')),

  -- Timestamps
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_mold_coc_company ON mold_chain_of_custody(company_id);
CREATE INDEX idx_mold_coc_assessment ON mold_chain_of_custody(mold_assessment_id);

CREATE TRIGGER mold_coc_updated_at
  BEFORE UPDATE ON mold_chain_of_custody
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER mold_coc_audit
  AFTER INSERT OR UPDATE OR DELETE ON mold_chain_of_custody
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

ALTER TABLE mold_chain_of_custody ENABLE ROW LEVEL SECURITY;

CREATE POLICY mold_coc_select ON mold_chain_of_custody
  FOR SELECT USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
    OR (auth.jwt()->'app_metadata'->>'role')::text = 'super_admin'
  );

CREATE POLICY mold_coc_insert ON mold_chain_of_custody
  FOR INSERT WITH CHECK (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

CREATE POLICY mold_coc_update ON mold_chain_of_custody
  FOR UPDATE USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

-- =============================================================================
-- MOLD STATE REGULATIONS (reference data)
-- =============================================================================

CREATE TABLE IF NOT EXISTS mold_state_regulations (
  id                                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  state_code                        text NOT NULL UNIQUE,
  state_name                        text NOT NULL,
  license_required                  boolean NOT NULL DEFAULT false,
  license_type                      text,
  notification_threshold_sqft       numeric(10,2),
  tenant_notice_required            boolean NOT NULL DEFAULT false,
  tenant_notice_days                smallint,
  assessment_required_before_remediation boolean NOT NULL DEFAULT false,
  clearance_testing_required        boolean NOT NULL DEFAULT false,
  allowable_spore_count             numeric(12,2),
  regulatory_body                   text,
  regulation_url                    text,
  notes                             text,
  created_at                        timestamptz NOT NULL DEFAULT now(),
  updated_at                        timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE mold_state_regulations ENABLE ROW LEVEL SECURITY;

CREATE POLICY mold_state_regs_select ON mold_state_regulations
  FOR SELECT USING (true);  -- public reference data

-- =============================================================================
-- MOLD LABS (reference data — AIHA-accredited labs)
-- =============================================================================

CREATE TABLE IF NOT EXISTS mold_labs (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  text NOT NULL,
  address               text,
  city                  text,
  state_code            text,
  zip                   text,
  phone                 text,
  website               text,
  aiha_accredited       boolean NOT NULL DEFAULT true,
  turnaround_days       smallint,
  sample_types_accepted text[],  -- {'air', 'surface', 'bulk', 'tape_lift'}
  notes                 text,
  created_at            timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE mold_labs ENABLE ROW LEVEL SECURITY;

CREATE POLICY mold_labs_select ON mold_labs
  FOR SELECT USING (true);  -- public reference data

-- =============================================================================
-- SEED: State Regulations (all 50 states)
-- =============================================================================

INSERT INTO mold_state_regulations (state_code, state_name, license_required, license_type, notification_threshold_sqft, tenant_notice_required, tenant_notice_days, assessment_required_before_remediation, clearance_testing_required, notes)
VALUES
  ('AL', 'Alabama', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('AK', 'Alaska', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('AZ', 'Arizona', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('AR', 'Arkansas', false, null, null, false, null, false, false, 'Limited mold provisions in landlord-tenant law'),
  ('CA', 'California', false, null, null, true, 30, false, false, 'SB 655/AB 284: landlords must provide mold disclosure. No licensing required but Cal/OSHA applies to workers'),
  ('CO', 'Colorado', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('CT', 'Connecticut', false, null, null, true, null, false, false, 'Indoor air quality regulations apply'),
  ('DE', 'Delaware', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('FL', 'Florida', true, 'Mold Assessor / Mold Remediator', 10.0, false, null, true, true, 'FL Stat. 468.84: separate licenses for assessment and remediation. Assessment required before remediation >10 sqft'),
  ('GA', 'Georgia', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('HI', 'Hawaii', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('ID', 'Idaho', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('IL', 'Illinois', true, 'Mold Remediation License', null, false, null, false, false, 'IL Mold Inspection and Remediation Act: licensing required for remediators'),
  ('IN', 'Indiana', false, null, null, true, null, false, false, 'Landlord disclosure required'),
  ('IA', 'Iowa', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('KS', 'Kansas', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('KY', 'Kentucky', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('LA', 'Louisiana', true, 'Mold Remediation License', null, true, null, true, false, 'LA RS 37:2181: licensing + assessment required'),
  ('ME', 'Maine', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('MD', 'Maryland', true, 'Mold Remediation License', null, true, null, false, false, 'MD Environment Code: licensing required. Tenant notification required'),
  ('MA', 'Massachusetts', false, null, null, true, null, false, false, 'State sanitary code applies to rental properties'),
  ('MI', 'Michigan', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('MN', 'Minnesota', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('MS', 'Mississippi', true, 'Mold Remediation License', null, false, null, false, false, 'MS Mold Remediation Act'),
  ('MO', 'Missouri', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('MT', 'Montana', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('NE', 'Nebraska', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('NV', 'Nevada', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('NH', 'New Hampshire', false, null, null, true, null, false, false, 'Landlord disclosure required'),
  ('NJ', 'New Jersey', true, 'Mold Inspector/Remediator', null, true, null, true, true, 'NJ Toxic Mold Protection Act: separate inspector/remediator roles. Assessment + clearance required'),
  ('NM', 'New Mexico', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('NY', 'New York', true, 'Mold Assessor / Mold Remediation', 10.0, true, null, true, true, 'NY Labor Law Article 32: licensing for both assessment and remediation. >10 sqft requires licensed professional'),
  ('NC', 'North Carolina', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('ND', 'North Dakota', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('OH', 'Ohio', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('OK', 'Oklahoma', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('OR', 'Oregon', false, null, null, true, null, false, false, 'Landlord disclosure required'),
  ('PA', 'Pennsylvania', false, null, null, false, null, false, false, 'No specific mold regulations (Philadelphia has local ordinance)'),
  ('RI', 'Rhode Island', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('SC', 'South Carolina', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('SD', 'South Dakota', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('TN', 'Tennessee', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('TX', 'Texas', true, 'Mold Assessor / Mold Remediator', 25.0, false, null, true, true, 'TX Occupations Code Ch. 1958: separate assessor/remediator licenses. >25 sqft requires licensed professional'),
  ('UT', 'Utah', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('VT', 'Vermont', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('VA', 'Virginia', true, 'Mold Inspector/Remediator', null, true, null, true, false, 'VA Code 54.1-501: licensing required'),
  ('WA', 'Washington', false, null, null, true, null, false, false, 'Landlord mold disclosure required under WA RCW 59.18'),
  ('WV', 'West Virginia', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('WI', 'Wisconsin', false, null, null, false, null, false, false, 'No specific mold regulations'),
  ('WY', 'Wyoming', false, null, null, false, null, false, false, 'No specific mold regulations')
ON CONFLICT (state_code) DO NOTHING;

-- =============================================================================
-- SEED: Top AIHA-accredited mold labs (nationwide)
-- =============================================================================

INSERT INTO mold_labs (name, city, state_code, aiha_accredited, turnaround_days, sample_types_accepted, phone, website, notes)
VALUES
  ('EMSL Analytical', 'Cinnaminson', 'NJ', true, 3, '{air,surface,bulk,tape_lift}', '856-858-4800', 'emsl.com', 'Largest environmental testing lab in US. 14 locations nationwide'),
  ('EMLab P&K (now Eurofins)', 'San Bruno', 'CA', true, 3, '{air,surface,bulk,tape_lift}', '866-888-6653', 'emlabpk.com', 'Part of Eurofins network. 7 US locations'),
  ('Aerobiology Laboratory', 'Duluth', 'GA', true, 2, '{air,surface,tape_lift}', '770-995-4646', 'aerobiology.net', 'Same-day rush available'),
  ('Indoor Science', 'Chicago', 'IL', true, 3, '{air,surface,bulk}', '312-920-9393', 'indoorscience.com', 'Midwest specialty lab'),
  ('ProLab', 'Weston', 'FL', true, 3, '{air,surface,tape_lift}', '800-427-0550', 'prolabinc.com', 'Fast turnaround. Southeast focus'),
  ('Galson Laboratories', 'East Syracuse', 'NY', true, 5, '{air,surface,bulk}', '888-432-5227', 'galsonlabs.com', 'Northeast. Also does asbestos/lead'),
  ('SanAir Technologies', 'Powhatan', 'VA', true, 2, '{air,surface,tape_lift}', '888-895-1177', 'sanair.com', 'Fast turnaround with online portal'),
  ('Forensic Analytical', 'Hayward', 'CA', true, 3, '{air,surface,bulk,tape_lift}', '510-266-4600', 'forensicanalytical.com', 'West Coast specialty'),
  ('ALS Global', 'Houston', 'TX', true, 5, '{air,surface,bulk}', '713-995-0303', 'alsglobal.com', 'Global lab network. Also industrial hygiene'),
  ('Pace Analytical', 'Mount Juliet', 'TN', true, 5, '{air,surface,bulk}', '855-786-7223', 'pacelabs.com', 'Multi-location national lab'),
  ('SGS Galson', 'East Syracuse', 'NY', true, 3, '{air,surface,bulk,tape_lift}', '315-432-5227', 'sgs.com', 'Part of SGS global network'),
  ('RHP Risk Management', 'Franklin', 'TN', true, 2, '{air,surface}', '615-543-5222', 'rhprisk.com', 'Quick turnaround. Southeast'),
  ('Environmental Diagnostics Laboratory', 'Burlington', 'NC', true, 3, '{air,surface,bulk,tape_lift}', '800-893-0411', 'edlab.org', 'East Coast specialty'),
  ('Mycotoxin Analysis', 'Fort Worth', 'TX', true, 5, '{air,surface,bulk}', '817-377-1080', null, 'Specializes in mycotoxin testing'),
  ('Aerotech Laboratories', 'Phoenix', 'AZ', true, 3, '{air,surface,tape_lift}', '800-651-4802', 'aerotechlabs.com', 'Southwest. Fast service')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- SEED: IICRC S520 remediation line items
-- =============================================================================

INSERT INTO restoration_line_items (
  company_id, category, code, description, unit, unit_price, labor_hours_per_unit, notes
)
SELECT
  '00000000-0000-0000-0000-000000000000'::uuid,
  v.category, v.code, v.description, v.unit, v.unit_price, v.labor_hours, v.notes
FROM (VALUES
  -- Containment
  ('mold_remediation', 'Z-MOLD-001', 'Limited containment setup', 'EA', 250.00, 2.0, 'Single layer 6-mil poly, tape seal, for areas <10 sqft'),
  ('mold_remediation', 'Z-MOLD-002', 'Full containment setup', 'EA', 750.00, 4.0, 'Double layer 6-mil poly, zippered entry, decontamination chamber'),
  ('mold_remediation', 'Z-MOLD-003', 'Negative air machine — per day', 'DAY', 150.00, 0.1, 'HEPA-filtered, maintain -0.02" WC minimum'),
  ('mold_remediation', 'Z-MOLD-004', 'Air scrubber — per day', 'DAY', 95.00, 0.1, 'HEPA + carbon filter'),
  ('mold_remediation', 'Z-MOLD-005', 'Containment integrity check', 'EA', 50.00, 0.25, 'Daily smoke pencil test + pressure reading'),

  -- Remediation
  ('mold_remediation', 'Z-MOLD-010', 'HEPA vacuum all surfaces (per SF)', 'SF', 1.50, 0.02, 'Pre and post remediation'),
  ('mold_remediation', 'Z-MOLD-011', 'Antimicrobial treatment (per SF)', 'SF', 2.00, 0.03, 'EPA-registered product. Spray application'),
  ('mold_remediation', 'Z-MOLD-012', 'Drywall removal — mold affected (per SF)', 'SF', 3.00, 0.04, 'Cut 2ft beyond visible growth. Bag in 6-mil poly'),
  ('mold_remediation', 'Z-MOLD-013', 'Insulation removal — mold affected (per SF)', 'SF', 2.50, 0.03, 'Remove and double-bag'),
  ('mold_remediation', 'Z-MOLD-014', 'Wood framing treatment — wire brush + HEPA + antimicrobial (per LF)', 'LF', 6.00, 0.08, 'Sand/wire brush, HEPA vacuum, apply antimicrobial'),
  ('mold_remediation', 'Z-MOLD-015', 'Carpet/pad removal — mold affected (per SF)', 'SF', 2.00, 0.03, 'Cut into manageable sections, roll, bag, dispose'),
  ('mold_remediation', 'Z-MOLD-016', 'Encapsulant application (per SF)', 'SF', 2.25, 0.03, 'Post-remediation encapsulant on cleaned framing'),

  -- Air Sampling & Testing
  ('mold_remediation', 'Z-MOLD-020', 'Air sample collection — per sample', 'EA', 125.00, 0.25, 'Spore trap cassette, calibrated pump, 5 min at 15 LPM'),
  ('mold_remediation', 'Z-MOLD-021', 'Surface sample collection — per sample', 'EA', 75.00, 0.15, 'Tape lift or swab with chain of custody'),
  ('mold_remediation', 'Z-MOLD-022', 'Lab analysis — per sample', 'EA', 45.00, 0.0, 'AIHA-accredited lab. 3-5 day standard turnaround'),
  ('mold_remediation', 'Z-MOLD-023', 'Rush lab analysis — per sample', 'EA', 95.00, 0.0, 'Same-day or next-day results'),
  ('mold_remediation', 'Z-MOLD-024', 'Clearance testing package (4 samples)', 'EA', 400.00, 1.0, '3 indoor + 1 outdoor baseline. Industry standard minimum'),

  -- PPE & Safety
  ('mold_remediation', 'Z-MOLD-030', 'PPE Level 2 (per worker/day)', 'DAY', 35.00, 0.0, 'N95 respirator, goggles, Tyvek suit, gloves'),
  ('mold_remediation', 'Z-MOLD-031', 'PPE Level 3 (per worker/day)', 'DAY', 65.00, 0.0, 'Half-face P100 respirator, goggles, full Tyvek, boot covers, gloves'),

  -- Demolition & Disposal
  ('mold_remediation', 'Z-MOLD-040', 'Mold waste disposal — per bag', 'EA', 25.00, 0.1, '6-mil poly bag, sealed, labeled "Mold Contaminated"'),
  ('mold_remediation', 'Z-MOLD-041', 'Dehumidifier — per day', 'DAY', 75.00, 0.1, 'Post-remediation drying')
) AS v(category, code, description, unit, unit_price, labor_hours, notes)
WHERE NOT EXISTS (
  SELECT 1 FROM restoration_line_items WHERE code = 'Z-MOLD-001'
);
