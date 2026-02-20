-- LEGAL-4: Legal reference registry + check log + freshness tracking
-- S143: Every legal reference in the platform tracked with review cycles

-- ============================================================
-- legal_reference_registry — Master registry of all legal references
-- ============================================================
CREATE TYPE legal_reference_type AS ENUM (
  'code_standard', 'state_law', 'federal_regulation',
  'form_template', 'seed_data', 'api_data'
);

CREATE TYPE legal_reference_status AS ENUM (
  'current', 'review_due', 'outdated', 'superseded'
);

CREATE TABLE legal_reference_registry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reference_type legal_reference_type NOT NULL,
  reference_key TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  current_edition TEXT,
  adopted_date DATE,
  next_review_cycle INTERVAL, -- e.g. '3 years' for NEC
  last_verified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  verified_by TEXT,
  source_url TEXT,
  affects_entities TEXT[] DEFAULT '{}', -- e.g. ['contractor','inspector']
  affects_sprints TEXT[] DEFAULT '{}', -- e.g. ['INS7','DEPTH20']
  status legal_reference_status NOT NULL DEFAULT 'current',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE legal_reference_registry ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER legal_reference_registry_updated_at BEFORE UPDATE ON legal_reference_registry FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER legal_reference_registry_audit AFTER INSERT OR UPDATE OR DELETE ON legal_reference_registry FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Super admin only (ops portal)
CREATE POLICY "legal_ref_registry_select" ON legal_reference_registry FOR SELECT USING (
  requesting_user_role() = 'super_admin'
);
CREATE POLICY "legal_ref_registry_modify" ON legal_reference_registry FOR ALL USING (
  requesting_user_role() = 'super_admin'
);

CREATE INDEX idx_legal_ref_registry_status ON legal_reference_registry (status);
CREATE INDEX idx_legal_ref_registry_type ON legal_reference_registry (reference_type);

-- ============================================================
-- legal_reference_check_log — Audit trail of verification checks
-- ============================================================
CREATE TYPE legal_check_result AS ENUM (
  'still_current', 'update_needed', 'updated', 'no_change_found'
);

CREATE TABLE legal_reference_check_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reference_id UUID NOT NULL REFERENCES legal_reference_registry(id) ON DELETE CASCADE,
  checked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  checked_by TEXT NOT NULL,
  result legal_check_result NOT NULL,
  notes TEXT,
  source_checked TEXT
);

ALTER TABLE legal_reference_check_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "legal_ref_check_log_select" ON legal_reference_check_log FOR SELECT USING (
  requesting_user_role() = 'super_admin'
);
CREATE POLICY "legal_ref_check_log_insert" ON legal_reference_check_log FOR INSERT WITH CHECK (
  requesting_user_role() = 'super_admin'
);

CREATE INDEX idx_legal_ref_check_log_ref ON legal_reference_check_log (reference_id);

-- ============================================================
-- Seed ~60 legal references
-- ============================================================

-- Code Standards (~15)
INSERT INTO legal_reference_registry (reference_type, reference_key, display_name, current_edition, next_review_cycle, affects_entities, affects_sprints, source_url) VALUES
('code_standard', 'NEC_2023', 'National Electrical Code (NFPA 70)', '2023', '3 years', '{"contractor","inspector"}', '{"DEPTH3","DEPTH4","INS7"}', 'https://www.nfpa.org/codes-and-standards/nfpa-70-standard-development/70'),
('code_standard', 'IBC_2021', 'International Building Code', '2021', '3 years', '{"contractor","inspector"}', '{"DEPTH5","INS7"}', 'https://www.iccsafe.org/products-and-services/i-codes/2021-i-codes/ibc/'),
('code_standard', 'IRC_2021', 'International Residential Code', '2021', '3 years', '{"contractor","inspector"}', '{"DEPTH5","INS7"}', 'https://www.iccsafe.org/products-and-services/i-codes/2021-i-codes/irc/'),
('code_standard', 'NFPA_70E_2024', 'NFPA 70E: Electrical Safety in the Workplace', '2024', '3 years', '{"contractor"}', '{"DEPTH3"}', 'https://www.nfpa.org/codes-and-standards/nfpa-70e-standard-development/70e'),
('code_standard', 'NFPA_25', 'NFPA 25: Inspection, Testing, and Maintenance of Water-Based Fire Protection Systems', '2023', '3 years', '{"contractor","inspector"}', '{"DEPTH20"}', NULL),
('code_standard', 'OSHA_1926', 'OSHA 29 CFR 1926 (Construction Safety)', 'Ongoing', NULL, '{"contractor"}', '{"DEPTH6","DEPTH7"}', 'https://www.osha.gov/laws-regs/regulations/standardnumber/1926'),
('code_standard', 'OSHA_1910', 'OSHA 29 CFR 1910 (General Industry)', 'Ongoing', NULL, '{"contractor"}', '{"DEPTH6"}', 'https://www.osha.gov/laws-regs/regulations/standardnumber/1910'),
('code_standard', 'IICRC_S500', 'IICRC S500: Water Damage Restoration', '2021', '5 years', '{"contractor"}', '{"REST1","DEPTH20"}', 'https://iicrc.org/standards/iicrc-s500/'),
('code_standard', 'IICRC_S520', 'IICRC S520: Mold Remediation', '2015', '5 years', '{"contractor","inspector"}', '{"REST2","DEPTH20"}', 'https://iicrc.org/standards/iicrc-s520/'),
('code_standard', 'EPA_RRP', 'EPA RRP Rule (40 CFR 745)', 'Ongoing', NULL, '{"contractor"}', '{"DEPTH8"}', 'https://www.epa.gov/lead/renovation-repair-and-painting-program'),
('code_standard', 'IECC_2021', 'International Energy Conservation Code', '2021', '3 years', '{"contractor","inspector"}', '{"DEPTH5"}', NULL),
('code_standard', 'UPC_2021', 'Uniform Plumbing Code', '2021', '3 years', '{"contractor","inspector"}', '{"DEPTH9"}', NULL),
('code_standard', 'ACCA_MANUAL_J', 'ACCA Manual J: Residential Load Calculation', '8th Edition', '5 years', '{"contractor"}', '{"DEPTH10"}', NULL),
('code_standard', 'NPMA_33', 'NPMA-33: WDI Inspection Report', 'Current', NULL, '{"inspector"}', '{"INS7"}', NULL),
('code_standard', 'ADA_STANDARDS', 'ADA Accessibility Standards', '2010', NULL, '{"contractor","inspector","realtor"}', '{"A11Y1"}', 'https://www.ada.gov/law-and-regs/design-standards/');

-- Federal Regulations (~10)
INSERT INTO legal_reference_registry (reference_type, reference_key, display_name, current_edition, next_review_cycle, affects_entities, source_url) VALUES
('federal_regulation', 'FLSA_OVERTIME', 'FLSA Overtime Rules', '2024 Update', '2 years', '{"contractor"}', 'https://www.dol.gov/agencies/whd/overtime'),
('federal_regulation', 'CCPA_CPRA', 'California Consumer Privacy Act / CPRA', '2023', '1 year', '{"contractor","realtor","adjuster","inspector","homeowner"}', NULL),
('federal_regulation', 'EPA_LEAD_SAFE', 'EPA Lead-Safe Certification', 'Ongoing', NULL, '{"contractor"}', 'https://www.epa.gov/lead'),
('federal_regulation', 'FMCSA_REGS', 'DOT/FMCSA Regulations', 'Ongoing', NULL, '{"contractor"}', NULL),
('federal_regulation', 'FTC_ADVERTISING', 'FTC Contractor Advertising Rules', 'Ongoing', NULL, '{"contractor","realtor"}', NULL),
('federal_regulation', 'RESPA', 'Real Estate Settlement Procedures Act', 'Current', NULL, '{"realtor"}', NULL),
('federal_regulation', 'TRID', 'TRID / Dodd-Frank Disclosure Rules', 'Current', NULL, '{"realtor"}', NULL),
('federal_regulation', 'FAIR_HOUSING', 'Fair Housing Act', 'Current', NULL, '{"realtor","homeowner"}', NULL),
('federal_regulation', 'ADA_TITLE_III', 'ADA Title III (Public Accommodations)', 'Current', NULL, '{"contractor","realtor"}', NULL),
('federal_regulation', 'ESIGN_ACT', 'E-SIGN Act / UETA (E-Signatures)', '2000/2006', NULL, '{"contractor","realtor","adjuster","inspector"}', NULL);

-- State Laws (grouped — tracked as groups with notes per state)
INSERT INTO legal_reference_registry (reference_type, reference_key, display_name, current_edition, next_review_cycle, affects_entities, notes) VALUES
('state_law', 'LIEN_LAWS_50', 'Mechanics Lien Laws (50 states)', 'Varies', '1 year', '{"contractor"}', 'Track per-state. Preliminary notice deadlines, lien filing deadlines, waiver requirements vary dramatically.'),
('state_law', 'CONTRACTOR_LICENSE_50', 'Contractor Licensing Requirements (50 states)', 'Varies', '1 year', '{"contractor"}', '13 states no license. Others: state, county, or city level. Track reciprocity agreements.'),
('state_law', 'REALTOR_DISCLOSURE_50', 'Realtor Disclosure Requirements (50 states)', 'Varies', '1 year', '{"realtor"}', 'Seller disclosure forms, agency disclosure, lead paint, natural hazard varies by state.'),
('state_law', 'INSPECTOR_LICENSE_50', 'Inspector Licensing Requirements (50 states)', 'Varies', '1 year', '{"inspector"}', 'Some states no license. Others require certification, insurance, SOP compliance.'),
('state_law', 'ADJUSTER_LICENSE_50', 'Adjuster Licensing Requirements (50 states)', 'Varies', '1 year', '{"adjuster"}', 'All states require license. Reciprocity varies. Continuing ed requirements differ.'),
('state_law', 'PRELIM_NOTICE_50', 'Preliminary Notice Requirements (50 states)', 'Varies', '1 year', '{"contractor"}', 'Required in most states before filing lien. Deadlines range from 10-45 days.'),
('state_law', 'HOME_IMPROVEMENT_50', 'Home Improvement Contractor Acts (50 states)', 'Varies', '1 year', '{"contractor","homeowner"}', 'Consumer protection laws for residential work. Right to cancel, deposit limits, contract requirements.');

-- Form Templates (grouped)
INSERT INTO legal_reference_registry (reference_type, reference_key, display_name, current_edition, next_review_cycle, affects_entities, notes) VALUES
('form_template', 'ZDOCS_SYSTEM_TEMPLATES', 'ZDocs System Templates (5)', 'v1', '6 months', '{"contractor"}', 'Proposal, contract, lien waiver, change order, daily report'),
('form_template', 'INSPECTION_TEMPLATES', 'Inspection Report Templates (25+)', 'v1', '1 year', '{"inspector"}', 'Track per standard: WDI/NPMA-33, electrical, plumbing, HVAC, structural, mold, fire, radon'),
('form_template', 'LIEN_TEMPLATES', 'Lien Document Templates (16)', 'v1', '1 year', '{"contractor"}', 'Conditional/unconditional, progress/final, 4 types × state variants'),
('form_template', 'FORM_TEMPLATES_SEED', 'Form Templates Seed Data (30+)', 'v1', '1 year', '{"contractor","inspector"}', 'Safety checklists, compliance forms, certification docs');

-- Seed Data
INSERT INTO legal_reference_registry (reference_type, reference_key, display_name, current_edition, next_review_cycle, affects_entities, notes) VALUES
('seed_data', 'CODE_REFERENCES_SEED', 'Code Reference Seed Data (61 sections)', 'NEC 2023 / IBC 2021', '3 years', '{"contractor","inspector"}', 'When code cycle updates, all 61 sections need review'),
('seed_data', 'CALCULATOR_FORMULAS', 'Calculator Formulas (1,194+)', 'Various', '3 years', '{"contractor"}', 'Formulas based on code editions. Update when codes update.'),
('seed_data', 'TRADE_SEED_DATA', 'Trade-Specific Seed Data', 'Various', '1 year', '{"contractor"}', 'Wire gauges, pipe sizes, HVAC specs, material specs');

-- API Data
INSERT INTO legal_reference_registry (reference_type, reference_key, display_name, current_edition, next_review_cycle, affects_entities, notes) VALUES
('api_data', 'BLS_OEWS', 'BLS OEWS Labor Rates', '2025 Annual', '1 year', '{"contractor"}', 'Annual update. SOC codes may change.'),
('api_data', 'GOOGLE_SOLAR', 'Google Solar API', 'v1', NULL, '{"contractor","realtor"}', 'No versioning. Monitor for deprecation.'),
('api_data', 'USGS_ELEVATION', 'USGS Elevation Service', 'Current', NULL, '{"contractor","inspector"}', 'Government API. Stable.'),
('api_data', 'NOAA_WEATHER', 'NOAA Weather API', 'Current', NULL, '{"contractor"}', 'Government API. Stable.'),
('api_data', 'FEMA_FLOOD', 'FEMA Flood Zone Data', 'Current', '1 year', '{"contractor","realtor","adjuster","inspector"}', 'NFHL map updates irregularly.');
