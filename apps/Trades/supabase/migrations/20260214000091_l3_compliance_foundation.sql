-- L3: Compliance Foundation Tables
-- ALTER certifications to add compliance fields.
-- CREATE compliance_requirements (regulatory reference data).
-- CREATE compliance_packets (generated doc bundles).

-- ── ALTER certifications ────────────────────────────────
ALTER TABLE certifications
  ADD COLUMN IF NOT EXISTS compliance_category text,
  ADD COLUMN IF NOT EXISTS policy_number text,
  ADD COLUMN IF NOT EXISTS coverage_amount numeric(12,2),
  ADD COLUMN IF NOT EXISTS renewal_cost numeric(10,2),
  ADD COLUMN IF NOT EXISTS auto_renew boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS document_path text;

-- compliance_category values: license, insurance, bond, osha, epa, vehicle, certification, other
COMMENT ON COLUMN certifications.compliance_category IS 'license|insurance|bond|osha|epa|vehicle|certification|other';
COMMENT ON COLUMN certifications.policy_number IS 'Insurance policy or bond number';
COMMENT ON COLUMN certifications.coverage_amount IS 'Insurance coverage or bond amount in dollars';

-- ── compliance_requirements (public reference data) ─────
CREATE TABLE compliance_requirements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trade_type text NOT NULL,
  job_type_pattern text,
  required_compliance_category text NOT NULL,
  required_certification_type text,
  state_code text,
  description text NOT NULL,
  regulatory_reference text,
  penalty_description text,
  severity text NOT NULL DEFAULT 'required' CHECK (severity IN ('required', 'recommended', 'optional')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE compliance_requirements ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER compliance_requirements_updated BEFORE UPDATE ON compliance_requirements
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_compliance_req_trade ON compliance_requirements (trade_type);
CREATE INDEX idx_compliance_req_state ON compliance_requirements (state_code);

-- Public read access for reference data
CREATE POLICY compliance_req_select ON compliance_requirements
  FOR SELECT TO authenticated USING (true);

-- Seed: common compliance requirements across trades
INSERT INTO compliance_requirements (trade_type, required_compliance_category, required_certification_type, description, regulatory_reference, penalty_description, severity) VALUES
  ('electrical', 'license', 'journeyman_electrician', 'State journeyman electrician license required for all electrical work', 'State licensing board', 'Fine up to $10,000 + work stoppage', 'required'),
  ('electrical', 'license', 'master_electrician', 'Master electrician license required to pull permits and supervise', 'State licensing board', 'Fine + license revocation', 'required'),
  ('electrical', 'insurance', 'general_liability', 'General liability insurance minimum $1M per occurrence', 'State contractor licensing', 'License suspension', 'required'),
  ('electrical', 'insurance', 'workers_comp', 'Workers compensation insurance required if 1+ employees', 'State workers comp board', 'Criminal penalties + fines', 'required'),
  ('plumbing', 'license', 'journeyman_plumber', 'State journeyman plumber license required', 'State licensing board', 'Fine up to $5,000', 'required'),
  ('plumbing', 'license', 'master_plumber', 'Master plumber license required to pull permits', 'State licensing board', 'Fine + license revocation', 'required'),
  ('plumbing', 'insurance', 'general_liability', 'General liability insurance minimum $1M', 'State contractor licensing', 'License suspension', 'required'),
  ('hvac', 'license', 'hvac_technician', 'HVAC technician certification required', 'State licensing board', 'Fine + work stoppage', 'required'),
  ('hvac', 'certification', 'epa_608', 'EPA Section 608 certification for refrigerant handling', 'EPA Clean Air Act Section 608', 'Fine up to $44,539 per day per violation', 'required'),
  ('roofing', 'license', 'roofing_contractor', 'Roofing contractor license required in most states', 'State contractor licensing', 'Fine + work stoppage', 'required'),
  ('roofing', 'insurance', 'general_liability', 'General liability insurance minimum $1M', 'State contractor licensing', 'License suspension', 'required'),
  ('general', 'osha', 'osha_10', 'OSHA 10-hour construction safety training', 'OSHA 29 CFR 1926', 'Fines up to $15,625 per serious violation', 'required'),
  ('general', 'osha', 'osha_30', 'OSHA 30-hour for supervisors/foremen', 'OSHA 29 CFR 1926', 'Fines up to $156,259 for willful violations', 'recommended'),
  ('general', 'insurance', 'vehicle_insurance', 'Commercial vehicle insurance for company vehicles', 'State DOT requirements', 'Vehicle impound + fine', 'required'),
  ('general', 'bond', 'surety_bond', 'Surety bond required for licensed contractors in most states', 'State contractor licensing', 'License revocation', 'required'),
  ('restoration', 'certification', 'iicrc_wrt', 'IICRC Water Restoration Technician certification', 'Industry standard (IICRC S500)', 'Loss of insurance carrier approval', 'required'),
  ('restoration', 'certification', 'iicrc_fsrt', 'IICRC Fire & Smoke Restoration Technician', 'Industry standard (IICRC S540)', 'Loss of carrier approval', 'recommended'),
  ('restoration', 'certification', 'lead_safe', 'EPA Lead-Safe Certified Firm for pre-1978 buildings', 'EPA RRP Rule 40 CFR 745', 'Fines up to $37,500 per day', 'required'),
  ('painting', 'certification', 'lead_safe', 'EPA Lead-Safe Certified Firm for pre-1978 buildings', 'EPA RRP Rule 40 CFR 745', 'Fines up to $37,500 per day', 'required'),
  ('solar', 'certification', 'nabcep', 'NABCEP PV Installation Professional certification', 'Industry standard', 'Loss of manufacturer warranties', 'recommended');

-- ── compliance_packets (company-specific doc bundles) ───
CREATE TABLE compliance_packets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  packet_name text NOT NULL,
  requested_by uuid REFERENCES auth.users(id),
  documents jsonb NOT NULL DEFAULT '[]'::jsonb,
  generated_at timestamptz,
  shared_via text,
  share_link text,
  expires_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE compliance_packets ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER compliance_packets_updated BEFORE UPDATE ON compliance_packets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER compliance_packets_audit AFTER INSERT OR UPDATE OR DELETE ON compliance_packets
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE INDEX idx_compliance_packets_company ON compliance_packets (company_id);

CREATE POLICY compliance_packets_select ON compliance_packets
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY compliance_packets_insert ON compliance_packets
  FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY compliance_packets_update ON compliance_packets
  FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY compliance_packets_delete ON compliance_packets
  FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));
