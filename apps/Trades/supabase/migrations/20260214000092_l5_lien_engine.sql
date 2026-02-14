-- L5: Mechanic's Lien Engine Foundation
-- 3 tables: lien_rules_by_state (50+DC reference), lien_tracking (per-job), lien_document_templates.
-- All data sourced from publicly available state statutes.

-- ── lien_rules_by_state ─────────────────────────────────
CREATE TABLE lien_rules_by_state (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  state_code text NOT NULL UNIQUE,
  state_name text NOT NULL,
  preliminary_notice_required boolean NOT NULL DEFAULT false,
  preliminary_notice_deadline_days int,
  preliminary_notice_from text,
  preliminary_notice_recipients text[],
  lien_filing_deadline_days int NOT NULL,
  lien_filing_from text NOT NULL DEFAULT 'last_work',
  lien_enforcement_deadline_days int,
  lien_enforcement_from text DEFAULT 'lien_filing',
  notice_of_intent_required boolean NOT NULL DEFAULT false,
  notice_of_intent_deadline_days int,
  notarization_required boolean NOT NULL DEFAULT false,
  special_rules jsonb DEFAULT '[]'::jsonb,
  residential_different boolean NOT NULL DEFAULT false,
  residential_rules jsonb,
  statutory_reference text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE lien_rules_by_state ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER lien_rules_updated BEFORE UPDATE ON lien_rules_by_state
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Public read for reference data
CREATE POLICY lien_rules_select ON lien_rules_by_state
  FOR SELECT TO authenticated USING (true);

-- ── lien_tracking ───────────────────────────────────────
CREATE TABLE lien_tracking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid NOT NULL,
  customer_id uuid,
  property_address text NOT NULL,
  property_city text,
  property_state text NOT NULL,
  state_code text NOT NULL REFERENCES lien_rules_by_state(state_code),
  contract_amount numeric(12,2),
  amount_owed numeric(12,2),
  first_work_date date,
  last_work_date date,
  completion_date date,
  preliminary_notice_sent boolean DEFAULT false,
  preliminary_notice_date date,
  preliminary_notice_document_path text,
  notice_of_intent_sent boolean DEFAULT false,
  notice_of_intent_date date,
  notice_of_intent_document_path text,
  lien_filed boolean DEFAULT false,
  lien_filing_date date,
  lien_filing_document_path text,
  lien_released boolean DEFAULT false,
  lien_release_date date,
  lien_release_document_path text,
  enforcement_filed boolean DEFAULT false,
  enforcement_filing_date date,
  status text NOT NULL DEFAULT 'monitoring' CHECK (status IN (
    'monitoring', 'notice_due', 'notice_sent', 'lien_eligible', 'lien_filed',
    'payment_received', 'lien_released', 'enforcement', 'resolved', 'expired'
  )),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE lien_tracking ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER lien_tracking_updated BEFORE UPDATE ON lien_tracking
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER lien_tracking_audit AFTER INSERT OR UPDATE OR DELETE ON lien_tracking
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE INDEX idx_lien_tracking_company ON lien_tracking (company_id);
CREATE INDEX idx_lien_tracking_job ON lien_tracking (job_id);
CREATE INDEX idx_lien_tracking_status ON lien_tracking (status);

CREATE POLICY lien_tracking_select ON lien_tracking
  FOR SELECT USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY lien_tracking_insert ON lien_tracking
  FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY lien_tracking_update ON lien_tracking
  FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY lien_tracking_delete ON lien_tracking
  FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- ── lien_document_templates ─────────────────────────────
CREATE TABLE lien_document_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  state_code text NOT NULL REFERENCES lien_rules_by_state(state_code),
  document_type text NOT NULL CHECK (document_type IN (
    'preliminary_notice', 'notice_of_intent', 'mechanics_lien', 'lien_release',
    'notice_of_completion', 'stop_notice', 'bond_claim'
  )),
  template_name text NOT NULL,
  template_content text NOT NULL,
  placeholders jsonb NOT NULL DEFAULT '[]'::jsonb,
  requires_notarization boolean DEFAULT false,
  filing_instructions text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE lien_document_templates ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER lien_templates_updated BEFORE UPDATE ON lien_document_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Public read
CREATE POLICY lien_templates_select ON lien_document_templates
  FOR SELECT TO authenticated USING (true);

CREATE INDEX idx_lien_templates_state ON lien_document_templates (state_code);
CREATE INDEX idx_lien_templates_type ON lien_document_templates (document_type);

-- ══════════════════════════════════════════════════════════
-- SEED: 50 states + DC lien rules (from publicly available statutes)
-- ══════════════════════════════════════════════════════════

INSERT INTO lien_rules_by_state (state_code, state_name, preliminary_notice_required, preliminary_notice_deadline_days, preliminary_notice_from, lien_filing_deadline_days, lien_filing_from, lien_enforcement_deadline_days, notice_of_intent_required, notarization_required, statutory_reference) VALUES
('AL', 'Alabama', false, NULL, NULL, 180, 'last_work', 180, false, false, 'Ala. Code § 35-11-210 et seq.'),
('AK', 'Alaska', true, 15, 'start_work', 120, 'last_work', 180, false, false, 'Alaska Stat. § 34.35.050 et seq.'),
('AZ', 'Arizona', true, 20, 'start_work', 120, 'completion', 180, false, false, 'Ariz. Rev. Stat. § 33-981 et seq.'),
('AR', 'Arkansas', false, NULL, NULL, 120, 'last_work', 365, false, false, 'Ark. Code § 18-44-101 et seq.'),
('CA', 'California', true, 20, 'start_work', 90, 'completion', 90, false, false, 'Cal. Civ. Code § 8000 et seq.'),
('CO', 'Colorado', false, NULL, NULL, 120, 'last_work', 180, true, false, 'Colo. Rev. Stat. § 38-22-101 et seq.'),
('CT', 'Connecticut', false, NULL, NULL, 90, 'last_work', 365, false, false, 'Conn. Gen. Stat. § 49-33 et seq.'),
('DE', 'Delaware', false, NULL, NULL, 120, 'last_work', 365, false, false, 'Del. Code tit. 25, § 2701 et seq.'),
('DC', 'District of Columbia', true, 0, 'contract_date', 90, 'last_work', 365, false, false, 'D.C. Code § 40-301.01 et seq.'),
('FL', 'Florida', true, 45, 'start_work', 90, 'last_work', 365, false, false, 'Fla. Stat. § 713.001 et seq.'),
('GA', 'Georgia', true, 0, 'contract_date', 90, 'last_work', 365, false, false, 'Ga. Code § 44-14-360 et seq.'),
('HI', 'Hawaii', false, NULL, NULL, 90, 'completion', 180, false, false, 'Haw. Rev. Stat. § 507-41 et seq.'),
('ID', 'Idaho', false, NULL, NULL, 90, 'completion', 180, false, false, 'Idaho Code § 45-501 et seq.'),
('IL', 'Illinois', true, 60, 'start_work', 120, 'completion', 730, false, false, 'Ill. Comp. Stat. 770 ILCS 60/1 et seq.'),
('IN', 'Indiana', true, 60, 'start_work', 90, 'last_work', 365, false, false, 'Ind. Code § 32-28-3 et seq.'),
('IA', 'Iowa', true, 30, 'start_work', 90, 'last_work', 730, false, false, 'Iowa Code § 572.1 et seq.'),
('KS', 'Kansas', false, NULL, NULL, 120, 'last_work', 365, false, false, 'Kan. Stat. § 60-1101 et seq.'),
('KY', 'Kentucky', false, NULL, NULL, 180, 'last_work', 365, false, false, 'Ky. Rev. Stat. § 376.010 et seq.'),
('LA', 'Louisiana', true, 0, 'start_work', 60, 'last_work', 365, false, false, 'La. Rev. Stat. § 9:4801 et seq.'),
('ME', 'Maine', false, NULL, NULL, 90, 'last_work', 365, false, false, 'Me. Rev. Stat. tit. 10, § 3251 et seq.'),
('MD', 'Maryland', true, 0, 'contract_date', 180, 'last_work', 365, false, false, 'Md. Code, Real Prop. § 9-101 et seq.'),
('MA', 'Massachusetts', true, 0, 'contract_date', 90, 'last_work', 30, false, false, 'Mass. Gen. Laws ch. 254, § 1 et seq.'),
('MI', 'Michigan', true, 20, 'start_work', 90, 'last_work', 365, false, true, 'Mich. Comp. Laws § 570.1101 et seq.'),
('MN', 'Minnesota', true, 45, 'start_work', 120, 'last_work', 365, false, false, 'Minn. Stat. § 514.01 et seq.'),
('MS', 'Mississippi', true, 0, 'start_work', 120, 'last_work', 365, false, false, 'Miss. Code § 85-7-131 et seq.'),
('MO', 'Missouri', false, NULL, NULL, 180, 'last_work', 365, false, false, 'Mo. Rev. Stat. § 429.010 et seq.'),
('MT', 'Montana', true, 20, 'start_work', 90, 'last_work', 730, false, false, 'Mont. Code § 71-3-521 et seq.'),
('NE', 'Nebraska', false, NULL, NULL, 120, 'last_work', 730, false, false, 'Neb. Rev. Stat. § 52-101 et seq.'),
('NV', 'Nevada', true, 31, 'start_work', 90, 'completion', 180, false, false, 'Nev. Rev. Stat. § 108.221 et seq.'),
('NH', 'New Hampshire', false, NULL, NULL, 120, 'last_work', 365, false, false, 'N.H. Rev. Stat. § 447:1 et seq.'),
('NJ', 'New Jersey', false, NULL, NULL, 90, 'last_work', 365, false, false, 'N.J. Stat. § 2A:44A-1 et seq.'),
('NM', 'New Mexico', false, NULL, NULL, 120, 'last_work', 365, false, false, 'N.M. Stat. § 48-2-1 et seq.'),
('NY', 'New York', false, NULL, NULL, 240, 'last_work', 365, false, false, 'N.Y. Lien Law § 1 et seq.'),
('NC', 'North Carolina', true, 0, 'start_work', 120, 'last_work', 180, false, false, 'N.C. Gen. Stat. § 44A-7 et seq.'),
('ND', 'North Dakota', false, NULL, NULL, 90, 'last_work', 180, false, false, 'N.D. Cent. Code § 35-27-01 et seq.'),
('OH', 'Ohio', true, 21, 'start_work', 75, 'last_work', 180, false, false, 'Ohio Rev. Code § 1311.01 et seq.'),
('OK', 'Oklahoma', true, 0, 'start_work', 90, 'last_work', 365, false, false, 'Okla. Stat. tit. 42, § 141 et seq.'),
('OR', 'Oregon', true, 8, 'start_work', 75, 'completion', 120, false, false, 'Or. Rev. Stat. § 87.001 et seq.'),
('PA', 'Pennsylvania', true, 0, 'contract_date', 120, 'completion', 730, false, false, 'Pa. Stat. tit. 49, § 1101 et seq.'),
('RI', 'Rhode Island', false, NULL, NULL, 120, 'last_work', 365, false, false, 'R.I. Gen. Laws § 34-28-1 et seq.'),
('SC', 'South Carolina', false, NULL, NULL, 90, 'last_work', 180, false, false, 'S.C. Code § 29-5-10 et seq.'),
('SD', 'South Dakota', true, 0, 'start_work', 120, 'last_work', 180, false, false, 'S.D. Codified Laws § 44-9-1 et seq.'),
('TN', 'Tennessee', true, 90, 'start_work', 90, 'last_work', 365, false, false, 'Tenn. Code § 66-11-101 et seq.'),
('TX', 'Texas', true, 15, 'each_month', 120, 'last_work', 365, false, true, 'Tex. Prop. Code § 53.001 et seq.'),
('UT', 'Utah', true, 20, 'start_work', 180, 'completion', 365, false, false, 'Utah Code § 38-1a-101 et seq.'),
('VT', 'Vermont', false, NULL, NULL, 180, 'last_work', 365, false, false, 'Vt. Stat. tit. 9, § 1921 et seq.'),
('VA', 'Virginia', false, NULL, NULL, 90, 'last_work', 180, false, false, 'Va. Code § 43-1 et seq.'),
('WA', 'Washington', true, 60, 'start_work', 90, 'last_work', 240, false, false, 'Wash. Rev. Code § 60.04.011 et seq.'),
('WV', 'West Virginia', false, NULL, NULL, 100, 'last_work', 180, false, false, 'W. Va. Code § 38-2-1 et seq.'),
('WI', 'Wisconsin', false, NULL, NULL, 120, 'last_work', 730, false, false, 'Wis. Stat. § 779.01 et seq.'),
('WY', 'Wyoming', true, 0, 'start_work', 150, 'last_work', 180, false, false, 'Wyo. Stat. § 29-1-301 et seq.');

-- ══════════════════════════════════════════════════════════
-- SEED: Document templates for top 10 states
-- Placeholders use {{VARIABLE}} syntax.
-- ══════════════════════════════════════════════════════════

INSERT INTO lien_document_templates (state_code, document_type, template_name, template_content, placeholders, requires_notarization, filing_instructions) VALUES
-- California
('CA', 'preliminary_notice', 'CA 20-Day Preliminary Notice', '<h1>PRELIMINARY NOTICE (20-DAY)</h1><p>State of California</p><p>To: {{PROPERTY_OWNER_NAME}}</p><p>Property Address: {{PROPERTY_ADDRESS}}</p><p>This notice is given pursuant to California Civil Code Section 8200.</p><p>The undersigned hereby notifies you that they have furnished or will furnish labor, services, equipment, or materials for the improvement of the real property described above.</p><p><strong>Claimant:</strong> {{COMPANY_NAME}}<br/>Address: {{COMPANY_ADDRESS}}<br/>Phone: {{COMPANY_PHONE}}</p><p><strong>Nature of Work:</strong> {{WORK_DESCRIPTION}}</p><p><strong>Estimated Price of Work:</strong> ${{CONTRACT_AMOUNT}}</p><p>Date of First Work: {{FIRST_WORK_DATE}}</p><p>Signature: ___________________________<br/>Date: {{CURRENT_DATE}}</p>', '["PROPERTY_OWNER_NAME","PROPERTY_ADDRESS","COMPANY_NAME","COMPANY_ADDRESS","COMPANY_PHONE","WORK_DESCRIPTION","CONTRACT_AMOUNT","FIRST_WORK_DATE","CURRENT_DATE"]', false, 'Must be served within 20 days of first furnishing labor/materials. Serve on property owner, general contractor, and construction lender by certified mail or personal delivery.'),
('CA', 'mechanics_lien', 'CA Mechanics Lien Claim', '<h1>CLAIM OF MECHANICS LIEN</h1><p>State of California, County of {{COUNTY}}</p><p>NOTICE IS HEREBY GIVEN that {{COMPANY_NAME}}, the claimant herein, claims a mechanics lien upon the property described below.</p><p><strong>Property:</strong> {{PROPERTY_ADDRESS}}</p><p><strong>Property Owner:</strong> {{PROPERTY_OWNER_NAME}}</p><p><strong>Amount of Lien:</strong> ${{AMOUNT_OWED}}</p><p><strong>Description of Work:</strong> {{WORK_DESCRIPTION}}</p><p><strong>First Work Date:</strong> {{FIRST_WORK_DATE}}</p><p><strong>Last Work Date:</strong> {{LAST_WORK_DATE}}</p><p>Claimant declares under penalty of perjury that the foregoing is true and correct.</p><p>Signature: ___________________________<br/>{{COMPANY_NAME}}<br/>Date: {{CURRENT_DATE}}</p>', '["COUNTY","COMPANY_NAME","PROPERTY_ADDRESS","PROPERTY_OWNER_NAME","AMOUNT_OWED","WORK_DESCRIPTION","FIRST_WORK_DATE","LAST_WORK_DATE","CURRENT_DATE"]', false, 'Must be recorded within 90 days after completion of work. File with County Recorder. Serve copy on property owner within 10 days of recording.'),
-- Texas
('TX', 'preliminary_notice', 'TX Monthly Preliminary Notice', '<h1>NOTICE TO OWNER</h1><p>State of Texas</p><p>To: {{PROPERTY_OWNER_NAME}}</p><p>Property: {{PROPERTY_ADDRESS}}</p><p>Pursuant to Texas Property Code Section 53.056, notice is hereby given that:</p><p>{{COMPANY_NAME}} has furnished or will furnish labor or materials for improvements on the above property.</p><p><strong>Month of Work:</strong> {{WORK_MONTH}}</p><p><strong>Amount Due:</strong> ${{AMOUNT_OWED}}</p><p>Signature: ___________________________<br/>Date: {{CURRENT_DATE}}</p>', '["PROPERTY_OWNER_NAME","PROPERTY_ADDRESS","COMPANY_NAME","WORK_MONTH","AMOUNT_OWED","CURRENT_DATE"]', false, 'Must send by 15th of 2nd month following each month work performed. Send by certified mail to property owner and general contractor.'),
('TX', 'mechanics_lien', 'TX Mechanics Lien Affidavit', '<h1>AFFIDAVIT CLAIMING MECHANICS AND MATERIALMAN''S LIEN</h1><p>State of Texas, County of {{COUNTY}}</p><p>Before me, the undersigned authority, on this day personally appeared {{CLAIMANT_NAME}}, who being duly sworn states:</p><p>{{COMPANY_NAME}} performed labor/furnished materials for improvements on property located at {{PROPERTY_ADDRESS}}.</p><p>Owner: {{PROPERTY_OWNER_NAME}}</p><p>Amount of Lien: ${{AMOUNT_OWED}}</p><p>First Work: {{FIRST_WORK_DATE}} | Last Work: {{LAST_WORK_DATE}}</p><p>Work Description: {{WORK_DESCRIPTION}}</p><p>Affiant: ___________________________<br/>Sworn before me: ___________________________<br/>Notary Public, State of Texas<br/>Date: {{CURRENT_DATE}}</p>', '["COUNTY","CLAIMANT_NAME","COMPANY_NAME","PROPERTY_ADDRESS","PROPERTY_OWNER_NAME","AMOUNT_OWED","FIRST_WORK_DATE","LAST_WORK_DATE","WORK_DESCRIPTION","CURRENT_DATE"]', true, 'File affidavit with County Clerk within 120 days of last work. Must be notarized. TX requires notarization for all lien filings.'),
-- Florida
('FL', 'preliminary_notice', 'FL Notice to Owner', '<h1>NOTICE TO OWNER</h1><p>State of Florida</p><p>To: {{PROPERTY_OWNER_NAME}}</p><p>RE: {{PROPERTY_ADDRESS}}</p><p>In accordance with Florida Statutes Section 713.06, you are hereby notified that {{COMPANY_NAME}} has furnished or will furnish services or materials as follows:</p><p>{{WORK_DESCRIPTION}}</p><p>The furnishing began on {{FIRST_WORK_DATE}}.</p><p>{{COMPANY_NAME}}<br/>{{COMPANY_ADDRESS}}<br/>Date: {{CURRENT_DATE}}</p>', '["PROPERTY_OWNER_NAME","PROPERTY_ADDRESS","COMPANY_NAME","WORK_DESCRIPTION","FIRST_WORK_DATE","COMPANY_ADDRESS","CURRENT_DATE"]', false, 'Must serve within 45 days of first furnishing. Serve on owner by certified mail. Required for subcontractors and suppliers (not GC).'),
('FL', 'mechanics_lien', 'FL Claim of Lien', '<h1>CLAIM OF LIEN</h1><p>State of Florida, County of {{COUNTY}}</p><p>{{COMPANY_NAME}} claims a lien against the real property in {{COUNTY}} County described as: {{PROPERTY_ADDRESS}}</p><p>Owner: {{PROPERTY_OWNER_NAME}}</p><p>Amount: ${{AMOUNT_OWED}}</p><p>Description: {{WORK_DESCRIPTION}}</p><p>First Furnishing: {{FIRST_WORK_DATE}}</p><p>Last Furnishing: {{LAST_WORK_DATE}}</p><p>Signature: ___________________________<br/>Date: {{CURRENT_DATE}}</p>', '["COUNTY","COMPANY_NAME","PROPERTY_ADDRESS","PROPERTY_OWNER_NAME","AMOUNT_OWED","WORK_DESCRIPTION","FIRST_WORK_DATE","LAST_WORK_DATE","CURRENT_DATE"]', false, 'Record with County Recorder within 90 days of last furnishing. Serve on owner within 15 days of recording. Enforce within 1 year.'),
-- New York
('NY', 'mechanics_lien', 'NY Notice of Mechanics Lien', '<h1>NOTICE OF MECHANIC''S LIEN</h1><p>State of New York, County of {{COUNTY}}</p><p>Please take notice that {{COMPANY_NAME}} claims a lien for labor and/or materials furnished for the improvement of real property at {{PROPERTY_ADDRESS}}.</p><p>Owner: {{PROPERTY_OWNER_NAME}}</p><p>Amount: ${{AMOUNT_OWED}}</p><p>Work Description: {{WORK_DESCRIPTION}}</p><p>First Work: {{FIRST_WORK_DATE}} | Last Work: {{LAST_WORK_DATE}}</p><p>Filed by: {{COMPANY_NAME}}<br/>Date: {{CURRENT_DATE}}</p>', '["COUNTY","COMPANY_NAME","PROPERTY_ADDRESS","PROPERTY_OWNER_NAME","AMOUNT_OWED","WORK_DESCRIPTION","FIRST_WORK_DATE","LAST_WORK_DATE","CURRENT_DATE"]', false, 'File with County Clerk within 8 months of last work. Serve on owner within 30 days of filing. Enforce within 1 year of filing.'),
-- Pennsylvania
('PA', 'preliminary_notice', 'PA Notice of Furnishing', '<h1>NOTICE OF FURNISHING</h1><p>Commonwealth of Pennsylvania</p><p>To: {{PROPERTY_OWNER_NAME}}</p><p>Property: {{PROPERTY_ADDRESS}}</p><p>This notice is given in accordance with Pennsylvania mechanics lien law. {{COMPANY_NAME}} has contracted to furnish labor and/or materials for the improvement of the above property.</p><p>Description: {{WORK_DESCRIPTION}}</p><p>Contract Amount: ${{CONTRACT_AMOUNT}}</p><p>{{COMPANY_NAME}}<br/>Date: {{CURRENT_DATE}}</p>', '["PROPERTY_OWNER_NAME","PROPERTY_ADDRESS","COMPANY_NAME","WORK_DESCRIPTION","CONTRACT_AMOUNT","CURRENT_DATE"]', false, 'Subcontractors must file notice within 30 days of contract date for residential; no later than filing lien for commercial.'),
-- Illinois
('IL', 'preliminary_notice', 'IL 60-Day Notice', '<h1>NOTICE OF LIEN RIGHTS</h1><p>State of Illinois</p><p>To: {{PROPERTY_OWNER_NAME}}</p><p>Property: {{PROPERTY_ADDRESS}}</p><p>Pursuant to 770 ILCS 60/24, notice is hereby given that {{COMPANY_NAME}} has furnished or will furnish labor, services, or materials for improvements to the above property.</p><p>Nature of Work: {{WORK_DESCRIPTION}}</p><p>Total Price: ${{CONTRACT_AMOUNT}}</p><p>{{COMPANY_NAME}}<br/>Date: {{CURRENT_DATE}}</p>', '["PROPERTY_OWNER_NAME","PROPERTY_ADDRESS","COMPANY_NAME","WORK_DESCRIPTION","CONTRACT_AMOUNT","CURRENT_DATE"]', false, 'Subcontractors must serve within 60 days of first furnishing. Serve on owner by certified mail or personal delivery.'),
-- Ohio
('OH', 'preliminary_notice', 'OH Notice of Furnishing', '<h1>NOTICE OF FURNISHING</h1><p>State of Ohio</p><p>To: {{PROPERTY_OWNER_NAME}}</p><p>Property: {{PROPERTY_ADDRESS}}</p><p>Pursuant to Ohio Revised Code Section 1311.05, {{COMPANY_NAME}} hereby provides notice of furnishing labor and/or materials for the improvement of the above property.</p><p>{{WORK_DESCRIPTION}}</p><p>First Furnished: {{FIRST_WORK_DATE}}</p><p>Estimated Cost: ${{CONTRACT_AMOUNT}}</p><p>{{COMPANY_NAME}}<br/>Date: {{CURRENT_DATE}}</p>', '["PROPERTY_OWNER_NAME","PROPERTY_ADDRESS","COMPANY_NAME","WORK_DESCRIPTION","FIRST_WORK_DATE","CONTRACT_AMOUNT","CURRENT_DATE"]', false, 'Must file within 21 days of first furnishing. File with County Recorder.'),
-- Georgia
('GA', 'preliminary_notice', 'GA Notice of Commencement', '<h1>NOTICE OF COMMENCEMENT OF LABOR OR FURNISHING OF MATERIALS</h1><p>State of Georgia, County of {{COUNTY}}</p><p>{{COMPANY_NAME}} hereby gives notice that it has commenced to furnish labor and/or materials for the improvement of property at {{PROPERTY_ADDRESS}}.</p><p>Owner: {{PROPERTY_OWNER_NAME}}</p><p>Date Commenced: {{FIRST_WORK_DATE}}</p><p>Description: {{WORK_DESCRIPTION}}</p><p>{{COMPANY_NAME}}<br/>Date: {{CURRENT_DATE}}</p>', '["COUNTY","COMPANY_NAME","PROPERTY_ADDRESS","PROPERTY_OWNER_NAME","FIRST_WORK_DATE","WORK_DESCRIPTION","CURRENT_DATE"]', false, 'File within 30 days of first furnishing. File with Clerk of Superior Court in county where property is located.'),
-- Michigan
('MI', 'preliminary_notice', 'MI Notice of Furnishing', '<h1>NOTICE OF FURNISHING</h1><p>State of Michigan</p><p>To: {{PROPERTY_OWNER_NAME}} and {{GENERAL_CONTRACTOR_NAME}}</p><p>Property: {{PROPERTY_ADDRESS}}</p><p>In accordance with Michigan Construction Lien Act (Act 497), {{COMPANY_NAME}} provides this notice that it has begun to furnish labor and/or materials.</p><p>Description: {{WORK_DESCRIPTION}}</p><p>Commenced: {{FIRST_WORK_DATE}}</p><p>{{COMPANY_NAME}}<br/>Date: {{CURRENT_DATE}}</p>', '["PROPERTY_OWNER_NAME","GENERAL_CONTRACTOR_NAME","PROPERTY_ADDRESS","COMPANY_NAME","WORK_DESCRIPTION","FIRST_WORK_DATE","CURRENT_DATE"]', false, 'Subcontractors must serve within 20 days of first furnishing. Serve on owner and GC by certified mail.'),
-- North Carolina
('NC', 'preliminary_notice', 'NC Notice to Lien Agent', '<h1>NOTICE TO LIEN AGENT</h1><p>State of North Carolina</p><p>{{COMPANY_NAME}} hereby provides notice to the designated Lien Agent that it has commenced furnishing labor and/or materials for improvements at {{PROPERTY_ADDRESS}}.</p><p>Owner: {{PROPERTY_OWNER_NAME}}</p><p>Lien Agent: {{LIEN_AGENT_NAME}}</p><p>First Furnishing: {{FIRST_WORK_DATE}}</p><p>Work: {{WORK_DESCRIPTION}}</p><p>{{COMPANY_NAME}}<br/>Date: {{CURRENT_DATE}}</p>', '["COMPANY_NAME","PROPERTY_ADDRESS","PROPERTY_OWNER_NAME","LIEN_AGENT_NAME","FIRST_WORK_DATE","WORK_DESCRIPTION","CURRENT_DATE"]', false, 'Serve on designated Lien Agent within 15 days of first furnishing. NC uses a Lien Agent system unique among states.'),
-- Lien Release (universal template)
('CA', 'lien_release', 'CA Lien Release', '<h1>RELEASE OF MECHANICS LIEN</h1><p>{{COMPANY_NAME}} hereby releases the mechanics lien recorded on {{LIEN_FILING_DATE}} in the official records of {{COUNTY}} County, against property at {{PROPERTY_ADDRESS}}.</p><p>The lien is released due to: {{RELEASE_REASON}}</p><p>Signature: ___________________________<br/>{{COMPANY_NAME}}<br/>Date: {{CURRENT_DATE}}</p>', '["COMPANY_NAME","LIEN_FILING_DATE","COUNTY","PROPERTY_ADDRESS","RELEASE_REASON","CURRENT_DATE"]', false, 'Record release with same County Recorder where lien was filed.'),
('TX', 'lien_release', 'TX Lien Release', '<h1>RELEASE OF MECHANIC''S AND MATERIALMAN''S LIEN</h1><p>State of Texas, County of {{COUNTY}}</p><p>{{COMPANY_NAME}} hereby releases the lien filed on {{LIEN_FILING_DATE}} against {{PROPERTY_ADDRESS}}.</p><p>Release Reason: {{RELEASE_REASON}}</p><p>Affiant: ___________________________<br/>Sworn before me: ___________________________<br/>Notary Public, State of Texas<br/>Date: {{CURRENT_DATE}}</p>', '["COUNTY","COMPANY_NAME","LIEN_FILING_DATE","PROPERTY_ADDRESS","RELEASE_REASON","CURRENT_DATE"]', true, 'Must be notarized. File with County Clerk.'),
('FL', 'lien_release', 'FL Satisfaction of Lien', '<h1>SATISFACTION AND RELEASE OF CLAIM OF LIEN</h1><p>{{COMPANY_NAME}} hereby acknowledges satisfaction of the Claim of Lien recorded on {{LIEN_FILING_DATE}} in {{COUNTY}} County against {{PROPERTY_ADDRESS}}.</p><p>Amount Paid: ${{AMOUNT_PAID}}</p><p>Signature: ___________________________<br/>Date: {{CURRENT_DATE}}</p>', '["COMPANY_NAME","LIEN_FILING_DATE","COUNTY","PROPERTY_ADDRESS","AMOUNT_PAID","CURRENT_DATE"]', false, 'Record with same County Recorder. FL requires satisfaction within 10 days of payment.');
