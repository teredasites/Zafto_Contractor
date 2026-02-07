-- ============================================================
-- ZAFTO D7a+: MODULAR CERTIFICATION SYSTEM
-- Session 68
--
-- Tables: certification_types (configurable per company),
--         certification_audit_log (immutable change tracking)
-- Seed: 25 system default certification types
-- ============================================================

-- ============================================================
-- CERTIFICATION_TYPES TABLE — Configurable cert type registry
-- NULL company_id = system default (visible to all companies)
-- ============================================================
CREATE TABLE certification_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE, -- NULL = system default
  type_key text NOT NULL, -- machine key: 'epa608', 'osha30', 'custom_my_cert'
  display_name text NOT NULL, -- human label: 'EPA 608'
  category text NOT NULL DEFAULT 'trade' CHECK (category IN (
    'safety', 'license', 'trade', 'regulatory', 'environmental', 'specialty'
  )),
  description text,
  regulation_reference text, -- e.g., 'EPA Section 608', 'OSHA 29 CFR 1926.502'
  applicable_trades text[] DEFAULT '{}', -- empty = all trades
  applicable_regions text[] DEFAULT '{}', -- empty = all regions, e.g., {'FL','CA','TX'}
  required_fields jsonb NOT NULL DEFAULT '[]', -- [{key, label, required}] beyond standard cert fields
  attachment_required boolean NOT NULL DEFAULT false,
  default_renewal_days int NOT NULL DEFAULT 30,
  default_renewal_required boolean NOT NULL DEFAULT true,
  is_system boolean NOT NULL DEFAULT false, -- system types can't be deleted by companies
  is_active boolean NOT NULL DEFAULT true,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  -- type_key must be unique within a company scope (or within system defaults)
  UNIQUE (company_id, type_key)
);

ALTER TABLE certification_types ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER certification_types_updated_at BEFORE UPDATE ON certification_types FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER certification_types_audit AFTER INSERT OR UPDATE OR DELETE ON certification_types FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE INDEX idx_certification_types_company ON certification_types (company_id);
CREATE INDEX idx_certification_types_key ON certification_types (type_key);

-- Users see their company types + all system types (company_id IS NULL)
CREATE POLICY "cert_types_select" ON certification_types FOR SELECT USING (
  company_id = requesting_company_id() OR company_id IS NULL
);
CREATE POLICY "cert_types_insert" ON certification_types FOR INSERT WITH CHECK (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
);
CREATE POLICY "cert_types_update" ON certification_types FOR UPDATE USING (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
  AND is_system = false -- system types are read-only
);
CREATE POLICY "cert_types_delete" ON certification_types FOR DELETE USING (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
  AND is_system = false
);

-- ============================================================
-- CERTIFICATION_AUDIT_LOG — INSERT-only immutable change trail
-- Tracks every create/update/delete on certifications table
-- ============================================================
CREATE TABLE certification_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  certification_id uuid NOT NULL, -- no FK: preserve history even if cert deleted
  company_id uuid NOT NULL,
  action text NOT NULL CHECK (action IN ('created', 'updated', 'status_changed', 'deleted', 'document_uploaded', 'renewed')),
  changed_by uuid NOT NULL REFERENCES auth.users(id),
  previous_values jsonb DEFAULT '{}',
  new_values jsonb DEFAULT '{}',
  change_summary text, -- human-readable: "Status changed from active to expired"
  ip_address text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE certification_audit_log ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_cert_audit_certification ON certification_audit_log (certification_id);
CREATE INDEX idx_cert_audit_company ON certification_audit_log (company_id);
CREATE INDEX idx_cert_audit_created ON certification_audit_log (created_at DESC);

-- SELECT only — no update/delete (immutable audit trail)
CREATE POLICY "cert_audit_select" ON certification_audit_log FOR SELECT USING (
  company_id = requesting_company_id()
);
CREATE POLICY "cert_audit_insert" ON certification_audit_log FOR INSERT WITH CHECK (
  company_id = requesting_company_id()
);
-- No UPDATE or DELETE policies — records are immutable

-- ============================================================
-- SEED 25 SYSTEM DEFAULT CERTIFICATION TYPES
-- company_id = NULL means visible to all companies
-- ============================================================
INSERT INTO certification_types (company_id, type_key, display_name, category, description, regulation_reference, applicable_trades, default_renewal_days, default_renewal_required, attachment_required, is_system, sort_order) VALUES
-- REGULATORY
(NULL, 'epa608', 'EPA 608', 'regulatory', 'EPA Section 608 Technician Certification for refrigerant handling', 'EPA 40 CFR Part 82', '{hvac}', 0, false, true, true, 1),
(NULL, 'rrpCertifiedRenovator', 'EPA RRP Certified Renovator', 'regulatory', 'Lead-safe renovation certification for pre-1978 properties', 'EPA 40 CFR Part 745', '{painting,general}', 365, true, true, true, 2),
(NULL, 'rrpFirm', 'EPA RRP Firm Certification', 'regulatory', 'Firm-level RRP certification', 'EPA 40 CFR Part 745', '{painting,general}', 365, true, true, true, 3),

-- SAFETY
(NULL, 'osha10', 'OSHA 10-Hour', 'safety', 'OSHA 10-hour construction safety training', 'OSHA 29 CFR 1926', '{}', 0, false, true, true, 10),
(NULL, 'osha30', 'OSHA 30-Hour', 'safety', 'OSHA 30-hour construction safety training', 'OSHA 29 CFR 1926', '{}', 0, false, true, true, 11),
(NULL, 'firstAidCpr', 'First Aid / CPR', 'safety', 'First aid and CPR/AED certification', 'OSHA 29 CFR 1910.151', '{}', 730, true, true, true, 12),
(NULL, 'confinedSpace', 'Confined Space Entry', 'safety', 'Permit-required confined space entry training', 'OSHA 29 CFR 1910.146', '{}', 365, true, true, true, 13),
(NULL, 'fallProtection', 'Fall Protection Competent Person', 'safety', 'Fall protection competent person certification', 'OSHA 29 CFR 1926.502', '{}', 365, true, true, true, 14),
(NULL, 'forklift', 'Forklift / Powered Industrial Truck', 'safety', 'Powered industrial truck operator certification', 'OSHA 29 CFR 1910.178', '{}', 1095, true, true, true, 15),
(NULL, 'hazmat', 'Hazmat Operations', 'safety', 'Hazardous materials operations level training', 'OSHA 29 CFR 1910.120', '{}', 365, true, true, true, 16),

-- LICENSE
(NULL, 'cdl', 'Commercial Driver License', 'license', 'Commercial driver license (CDL)', null, '{}', 1825, true, true, true, 20),
(NULL, 'stateContractorLicense', 'State Contractor License', 'license', 'State-issued general contractor license', null, '{}', 365, true, true, true, 21),
(NULL, 'stateElectrical', 'State Electrical License', 'license', 'State-issued electrical contractor/journeyman license', null, '{electrical}', 365, true, true, true, 22),
(NULL, 'statePlumbing', 'State Plumbing License', 'license', 'State-issued plumbing contractor/journeyman license', null, '{plumbing}', 365, true, true, true, 23),
(NULL, 'stateHvac', 'State HVAC License', 'license', 'State-issued HVAC contractor license', null, '{hvac}', 365, true, true, true, 24),

-- TRADE
(NULL, 'backflowTester', 'Backflow Prevention Tester', 'trade', 'Certified backflow prevention assembly tester', 'USC FCCCHR', '{plumbing}', 365, true, true, true, 30),
(NULL, 'cpo', 'Certified Pool Operator', 'trade', 'Certified Pool/Spa Operator (CPO)', null, '{pool}', 1825, true, true, true, 31),
(NULL, 'nicet', 'NICET Fire Protection', 'trade', 'National Institute for Certification in Engineering Technologies', null, '{fire_protection}', 1095, true, true, true, 32),
(NULL, 'fireSprinkler', 'Fire Sprinkler Inspector', 'trade', 'Fire sprinkler system inspector certification', 'NFPA 25', '{fire_protection}', 365, true, true, true, 33),
(NULL, 'csia', 'CSIA Chimney Sweep', 'trade', 'Chimney Safety Institute of America certification', null, '{chimney}', 365, true, true, true, 34),
(NULL, 'isaArborist', 'ISA Certified Arborist', 'trade', 'International Society of Arboriculture certification', null, '{landscaping}', 1095, true, true, true, 35),

-- ENVIRONMENTAL
(NULL, 'asbestosWorker', 'Asbestos Worker', 'environmental', 'Asbestos abatement worker certification', 'EPA AHERA / OSHA', '{environmental,restoration}', 365, true, true, true, 40),
(NULL, 'leadAbatement', 'Lead Abatement', 'environmental', 'Lead abatement worker/supervisor certification', 'EPA 40 CFR Part 745', '{environmental,painting}', 365, true, true, true, 41),

-- SPECIALTY
(NULL, 'iicrcWrt', 'IICRC WRT (Water Restoration)', 'specialty', 'Water Restoration Technician certification', 'IICRC S500', '{restoration}', 1095, true, true, true, 50),
(NULL, 'iicrcAmrt', 'IICRC AMRT (Mold Remediation)', 'specialty', 'Applied Microbial Remediation Technician', 'IICRC S520', '{restoration}', 1095, true, true, true, 51);

-- Also add a catch-all 'other' type
INSERT INTO certification_types (company_id, type_key, display_name, category, description, is_system, sort_order)
VALUES (NULL, 'other', 'Other', 'specialty', 'Custom or unlisted certification type', true, 99);
