-- ============================================================
-- ZAFTO D6: ENTERPRISE FOUNDATION
-- Sprint D6a | Session 65
--
-- Tables: branches, custom_roles, form_templates, certifications, api_keys
-- ALTERs: users (branch_id, custom_role_id), jobs (branch_id), customers (branch_id)
-- Also: form_template_id on compliance_records, extended record_type CHECK
-- ============================================================

-- ============================================================
-- BRANCHES TABLE — Multi-location support
-- ============================================================
CREATE TABLE branches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  address text,
  city text,
  state text,
  zip_code text,
  phone text,
  email text,
  manager_user_id uuid REFERENCES auth.users(id),
  timezone text NOT NULL DEFAULT 'America/New_York',
  is_active boolean NOT NULL DEFAULT true,
  settings jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER branches_updated_at BEFORE UPDATE ON branches FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER branches_audit AFTER INSERT OR UPDATE OR DELETE ON branches FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE INDEX idx_branches_company ON branches (company_id);

CREATE POLICY "branches_select" ON branches FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "branches_insert" ON branches FOR INSERT WITH CHECK (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
);
CREATE POLICY "branches_update" ON branches FOR UPDATE USING (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
);
CREATE POLICY "branches_delete" ON branches FOR DELETE USING (
  company_id = requesting_company_id() AND requesting_user_role() = 'owner'
);

-- ============================================================
-- CUSTOM_ROLES TABLE — Company-defined permission sets
-- ============================================================
CREATE TABLE custom_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  base_role text NOT NULL DEFAULT 'technician',
  permissions jsonb NOT NULL DEFAULT '{}',
  is_system_role boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE custom_roles ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER custom_roles_updated_at BEFORE UPDATE ON custom_roles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER custom_roles_audit AFTER INSERT OR UPDATE OR DELETE ON custom_roles FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE INDEX idx_custom_roles_company ON custom_roles (company_id);

CREATE POLICY "custom_roles_select" ON custom_roles FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "custom_roles_insert" ON custom_roles FOR INSERT WITH CHECK (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
);
CREATE POLICY "custom_roles_update" ON custom_roles FOR UPDATE USING (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
);
CREATE POLICY "custom_roles_delete" ON custom_roles FOR DELETE USING (
  company_id = requesting_company_id() AND requesting_user_role() = 'owner'
);

-- ============================================================
-- FORM_TEMPLATES TABLE — Configurable compliance form schemas
-- ============================================================
CREATE TABLE form_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE, -- NULL = system default
  trade text, -- NULL = all trades
  name text NOT NULL,
  description text,
  category text NOT NULL DEFAULT 'compliance' CHECK (category IN (
    'safety', 'compliance', 'inspection', 'certification', 'quality', 'lien_waiver'
  )),
  regulation_reference text, -- e.g. 'EPA 608', 'OSHA 1926.502'
  fields jsonb NOT NULL DEFAULT '[]', -- [{key, type, label, required, options[], placeholder, validation, computed_from}]
  is_active boolean NOT NULL DEFAULT true,
  is_system boolean NOT NULL DEFAULT false,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE form_templates ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER form_templates_updated_at BEFORE UPDATE ON form_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER form_templates_audit AFTER INSERT OR UPDATE OR DELETE ON form_templates FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE INDEX idx_form_templates_company ON form_templates (company_id);
CREATE INDEX idx_form_templates_trade ON form_templates (trade);

-- Users see their own company templates + all system templates (company_id IS NULL)
CREATE POLICY "form_templates_select" ON form_templates FOR SELECT USING (
  company_id = requesting_company_id() OR company_id IS NULL
);
CREATE POLICY "form_templates_insert" ON form_templates FOR INSERT WITH CHECK (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
);
CREATE POLICY "form_templates_update" ON form_templates FOR UPDATE USING (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
);
CREATE POLICY "form_templates_delete" ON form_templates FOR DELETE USING (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
);

-- ============================================================
-- CERTIFICATIONS TABLE — Employee license/cert tracking
-- ============================================================
CREATE TABLE certifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  certification_type text NOT NULL,
  certification_name text NOT NULL,
  issuing_authority text,
  certification_number text,
  issued_date date,
  expiration_date date,
  renewal_required boolean NOT NULL DEFAULT true,
  renewal_reminder_days int NOT NULL DEFAULT 30,
  document_url text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'pending_renewal', 'revoked')),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE certifications ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER certifications_updated_at BEFORE UPDATE ON certifications FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER certifications_audit AFTER INSERT OR UPDATE OR DELETE ON certifications FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE INDEX idx_certifications_company ON certifications (company_id);
CREATE INDEX idx_certifications_user ON certifications (user_id);
CREATE INDEX idx_certifications_expiration ON certifications (expiration_date);

CREATE POLICY "certifications_select" ON certifications FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "certifications_insert" ON certifications FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "certifications_update" ON certifications FOR UPDATE USING (
  company_id = requesting_company_id() AND (
    requesting_user_role() IN ('owner', 'admin', 'office_manager') OR user_id = auth.uid()
  )
);
CREATE POLICY "certifications_delete" ON certifications FOR DELETE USING (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
);

-- ============================================================
-- API_KEYS TABLE — Per-company API access
-- ============================================================
CREATE TABLE api_keys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  key_hash text NOT NULL,
  prefix text NOT NULL, -- first 8 chars for display
  permissions jsonb NOT NULL DEFAULT '{}',
  last_used_at timestamptz,
  expires_at timestamptz,
  is_active boolean NOT NULL DEFAULT true,
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER api_keys_audit AFTER INSERT OR UPDATE OR DELETE ON api_keys FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE INDEX idx_api_keys_company ON api_keys (company_id);
CREATE INDEX idx_api_keys_prefix ON api_keys (prefix);

CREATE POLICY "api_keys_select" ON api_keys FOR SELECT USING (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
);
CREATE POLICY "api_keys_insert" ON api_keys FOR INSERT WITH CHECK (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin')
);
CREATE POLICY "api_keys_update" ON api_keys FOR UPDATE USING (
  company_id = requesting_company_id() AND requesting_user_role() = 'owner'
);
CREATE POLICY "api_keys_delete" ON api_keys FOR DELETE USING (
  company_id = requesting_company_id() AND requesting_user_role() = 'owner'
);

-- ============================================================
-- ALTER EXISTING TABLES — Add branch_id + custom_role_id
-- ============================================================

-- Users: branch assignment + custom role
ALTER TABLE users ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES branches(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS custom_role_id uuid REFERENCES custom_roles(id);

-- Jobs: branch assignment
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES branches(id);

-- Customers: branch assignment
ALTER TABLE customers ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES branches(id);

-- Compliance records: form_template_id for dynamic form submissions
ALTER TABLE compliance_records ADD COLUMN IF NOT EXISTS form_template_id uuid REFERENCES form_templates(id);

-- Extend compliance_records record_type CHECK to include form_submission
ALTER TABLE compliance_records DROP CONSTRAINT IF EXISTS compliance_records_record_type_check;
ALTER TABLE compliance_records ADD CONSTRAINT compliance_records_record_type_check CHECK (
  record_type IN ('safety_briefing', 'incident_report', 'loto', 'confined_space', 'dead_man_switch', 'inspection', 'form_submission')
);

-- ============================================================
-- UPDATE handle_new_user() to include branch_id in JWT claims
-- ============================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE auth.users
  SET raw_app_meta_data = raw_app_meta_data || jsonb_build_object(
    'company_id', NEW.company_id::text,
    'role', NEW.role,
    'branch_id', COALESCE(NEW.branch_id::text, '')
  )
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update role change trigger to also sync branch_id
CREATE OR REPLACE FUNCTION handle_user_role_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.role IS DISTINCT FROM NEW.role OR OLD.branch_id IS DISTINCT FROM NEW.branch_id THEN
    UPDATE auth.users
    SET raw_app_meta_data = raw_app_meta_data || jsonb_build_object(
      'role', NEW.role,
      'branch_id', COALESCE(NEW.branch_id::text, '')
    )
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- SEED SYSTEM FORM TEMPLATES (~30 pre-built templates)
-- Field types: text, number, select, multiselect, checkbox, date, time,
--              photo, signature, gps, textarea, calculated
-- ============================================================

-- HVAC Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('hvac', 'Refrigerant Tracking Log', 'EPA Section 608 refrigerant tracking for leak rate calculations', 'compliance', 'EPA 608', true, true, 1,
'[
  {"key":"equipment_id","type":"text","label":"Equipment ID / Tag","required":true},
  {"key":"refrigerant_type","type":"select","label":"Refrigerant Type","required":true,"options":["R-22","R-410A","R-134a","R-404A","R-407C","R-32","R-454B","Other"]},
  {"key":"action","type":"select","label":"Action","required":true,"options":["Add","Recover","Reclaim","Recycle"]},
  {"key":"amount_lbs","type":"number","label":"Amount (lbs)","required":true},
  {"key":"total_charge_lbs","type":"number","label":"Total System Charge (lbs)","required":true},
  {"key":"leak_rate","type":"calculated","label":"Annualized Leak Rate (%)","computed_from":"amount_lbs,total_charge_lbs"},
  {"key":"leak_location","type":"text","label":"Leak Location (if applicable)"},
  {"key":"repair_performed","type":"checkbox","label":"Leak Repair Performed"},
  {"key":"verification_test","type":"select","label":"Verification Test","options":["Standing Pressure","Electronic Leak Detector","Bubble Test","UV Dye","N/A"]},
  {"key":"technician_epa_cert","type":"text","label":"Technician EPA Cert #","required":true},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"photo","type":"photo","label":"Equipment Photo"},
  {"key":"signature","type":"signature","label":"Technician Signature","required":true}
]'::jsonb),

('hvac', 'HVAC Maintenance Checklist', 'Standard preventive maintenance inspection checklist', 'inspection', null, true, true, 2,
'[
  {"key":"system_type","type":"select","label":"System Type","required":true,"options":["Split System","Package Unit","Mini-Split","VRF","Chiller","Boiler","Heat Pump","Furnace","RTU"]},
  {"key":"filter_replaced","type":"checkbox","label":"Filter Replaced"},
  {"key":"filter_size","type":"text","label":"Filter Size"},
  {"key":"coil_cleaned","type":"checkbox","label":"Coil Cleaned"},
  {"key":"drain_clear","type":"checkbox","label":"Condensate Drain Clear"},
  {"key":"electrical_connections","type":"select","label":"Electrical Connections","options":["Tight","Loose - Corrected","Corroded - Needs Replacement"]},
  {"key":"capacitor_reading","type":"number","label":"Capacitor Reading (MFD)"},
  {"key":"supply_temp","type":"number","label":"Supply Air Temp (F)"},
  {"key":"return_temp","type":"number","label":"Return Air Temp (F)"},
  {"key":"suction_pressure","type":"number","label":"Suction Pressure (PSI)"},
  {"key":"head_pressure","type":"number","label":"Head Pressure (PSI)"},
  {"key":"superheat","type":"number","label":"Superheat (F)"},
  {"key":"subcooling","type":"number","label":"Subcooling (F)"},
  {"key":"amp_draw","type":"number","label":"Compressor Amp Draw"},
  {"key":"overall_condition","type":"select","label":"Overall Condition","required":true,"options":["Good","Fair","Poor","Needs Immediate Attention"]},
  {"key":"recommendations","type":"textarea","label":"Recommendations"},
  {"key":"photos","type":"photo","label":"Photos"},
  {"key":"signature","type":"signature","label":"Technician Signature","required":true}
]'::jsonb),

('hvac', 'Equipment Startup / Commissioning', 'New equipment startup verification', 'compliance', null, true, true, 3,
'[
  {"key":"equipment_make","type":"text","label":"Equipment Make","required":true},
  {"key":"equipment_model","type":"text","label":"Equipment Model","required":true},
  {"key":"serial_number","type":"text","label":"Serial Number","required":true},
  {"key":"install_date","type":"date","label":"Install Date","required":true},
  {"key":"refrigerant_type","type":"select","label":"Refrigerant Type","required":true,"options":["R-410A","R-32","R-454B","R-22","Other"]},
  {"key":"charge_amount","type":"number","label":"Initial Charge (lbs)"},
  {"key":"airflow_verified","type":"checkbox","label":"Airflow Verified"},
  {"key":"electrical_verified","type":"checkbox","label":"Electrical Verified"},
  {"key":"thermostat_calibrated","type":"checkbox","label":"Thermostat Calibrated"},
  {"key":"customer_walkthrough","type":"checkbox","label":"Customer Walkthrough Completed"},
  {"key":"warranty_registered","type":"checkbox","label":"Warranty Registered"},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"photo","type":"photo","label":"Equipment Photo"},
  {"key":"signature","type":"signature","label":"Technician Signature","required":true},
  {"key":"customer_signature","type":"signature","label":"Customer Signature"}
]'::jsonb);

-- Plumbing Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('plumbing', 'Backflow Test Report', 'Annual backflow preventer test per local water authority requirements', 'compliance', 'USC FCCCHR', true, true, 1,
'[
  {"key":"device_type","type":"select","label":"Device Type","required":true,"options":["RPZ","DCVA","PVB","SVB","AVB"]},
  {"key":"device_make","type":"text","label":"Device Make","required":true},
  {"key":"device_model","type":"text","label":"Device Model"},
  {"key":"serial_number","type":"text","label":"Serial Number","required":true},
  {"key":"device_size","type":"select","label":"Device Size","required":true,"options":["3/4\"","1\"","1-1/2\"","2\"","3\"","4\"","6\"","8\"","10\""]},
  {"key":"location","type":"text","label":"Device Location"},
  {"key":"check_valve_1","type":"number","label":"Check Valve #1 (PSI)"},
  {"key":"check_valve_2","type":"number","label":"Check Valve #2 (PSI)"},
  {"key":"relief_valve_opening","type":"number","label":"Relief Valve Opening (PSI)"},
  {"key":"test_result","type":"select","label":"Test Result","required":true,"options":["Pass","Fail - Repaired & Retested","Fail - Replacement Needed"]},
  {"key":"repair_notes","type":"textarea","label":"Repair Notes (if applicable)"},
  {"key":"tester_cert_number","type":"text","label":"Tester Certification #","required":true},
  {"key":"signature","type":"signature","label":"Tester Signature","required":true}
]'::jsonb),

('plumbing', 'Sewer Camera Inspection', 'Video inspection report for sewer/drain lines', 'inspection', null, true, true, 2,
'[
  {"key":"line_location","type":"text","label":"Line Location","required":true},
  {"key":"line_material","type":"select","label":"Pipe Material","options":["PVC","Cast Iron","Clay","Orangeburg","ABS","Copper","Galvanized","HDPE","Unknown"]},
  {"key":"line_size","type":"select","label":"Pipe Size","options":["2\"","3\"","4\"","6\"","8\"","10\"","12\"","Other"]},
  {"key":"total_length","type":"number","label":"Total Length Inspected (ft)"},
  {"key":"condition","type":"select","label":"Overall Condition","required":true,"options":["Good","Fair","Poor","Critical"]},
  {"key":"findings","type":"multiselect","label":"Findings","options":["Root Intrusion","Belly/Sag","Offset Joint","Crack","Break","Buildup/Scale","Grease","Foreign Object","Channel","Corrosion","None"]},
  {"key":"recommendation","type":"select","label":"Recommendation","required":true,"options":["No Action Needed","Hydrojetting","Lining/CIPP","Spot Repair","Full Replacement","Further Inspection"]},
  {"key":"notes","type":"textarea","label":"Detailed Notes"},
  {"key":"photos","type":"photo","label":"Key Screenshots"},
  {"key":"gps","type":"gps","label":"Location"},
  {"key":"signature","type":"signature","label":"Technician Signature","required":true}
]'::jsonb),

('plumbing', 'Water Heater Compliance', 'Water heater installation/inspection checklist', 'compliance', null, true, true, 3,
'[
  {"key":"heater_type","type":"select","label":"Type","required":true,"options":["Tank Gas","Tank Electric","Tankless Gas","Tankless Electric","Heat Pump","Solar"]},
  {"key":"make","type":"text","label":"Make","required":true},
  {"key":"model","type":"text","label":"Model","required":true},
  {"key":"serial_number","type":"text","label":"Serial Number","required":true},
  {"key":"capacity","type":"text","label":"Capacity (gallons or GPM)"},
  {"key":"tpr_valve","type":"checkbox","label":"T&P Relief Valve Installed"},
  {"key":"tpr_discharge","type":"checkbox","label":"T&P Discharge Piped to Safe Location"},
  {"key":"expansion_tank","type":"checkbox","label":"Expansion Tank Installed (closed system)"},
  {"key":"seismic_straps","type":"checkbox","label":"Seismic Straps (if required)"},
  {"key":"gas_leak_test","type":"checkbox","label":"Gas Leak Test Performed (gas units)"},
  {"key":"venting_verified","type":"checkbox","label":"Venting Verified (gas units)"},
  {"key":"temp_setting","type":"number","label":"Temperature Setting (F)"},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"photo","type":"photo","label":"Installation Photo"},
  {"key":"signature","type":"signature","label":"Technician Signature","required":true}
]'::jsonb);

-- Electrical Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('electrical', 'Panel Inspection', 'Electrical panel inspection and documentation', 'inspection', 'NEC', true, true, 1,
'[
  {"key":"panel_type","type":"select","label":"Panel Type","required":true,"options":["Main Breaker","Main Lug","Sub-Panel","Disconnect","Transfer Switch"]},
  {"key":"panel_make","type":"text","label":"Panel Make"},
  {"key":"amperage","type":"select","label":"Panel Amperage","required":true,"options":["60A","100A","125A","150A","200A","225A","400A","600A","800A"]},
  {"key":"voltage","type":"select","label":"Voltage","required":true,"options":["120/240V Single Phase","120/208V Three Phase","277/480V Three Phase"]},
  {"key":"grounding_verified","type":"checkbox","label":"Grounding Electrode Verified"},
  {"key":"bonding_verified","type":"checkbox","label":"Bonding Verified"},
  {"key":"afci_required_circuits","type":"checkbox","label":"AFCI Protection on Required Circuits"},
  {"key":"gfci_required_circuits","type":"checkbox","label":"GFCI Protection on Required Circuits"},
  {"key":"wire_torque_verified","type":"checkbox","label":"Wire Torque Specs Verified"},
  {"key":"panel_schedule_accurate","type":"checkbox","label":"Panel Schedule Accurate"},
  {"key":"working_clearance","type":"checkbox","label":"Working Clearance Met (NEC 110.26)"},
  {"key":"deficiencies","type":"textarea","label":"Deficiencies Found"},
  {"key":"recommendations","type":"textarea","label":"Recommendations"},
  {"key":"thermal_scan","type":"photo","label":"Thermal Scan Photo"},
  {"key":"panel_photo","type":"photo","label":"Panel Photo"},
  {"key":"signature","type":"signature","label":"Electrician Signature","required":true}
]'::jsonb),

('electrical', 'Arc Flash Survey', 'Arc flash hazard analysis documentation', 'safety', 'NFPA 70E', true, true, 2,
'[
  {"key":"equipment_id","type":"text","label":"Equipment ID","required":true},
  {"key":"equipment_type","type":"select","label":"Equipment Type","required":true,"options":["Switchboard","Panel","MCC","Transformer","Disconnect","Bus Duct","Other"]},
  {"key":"voltage","type":"number","label":"System Voltage","required":true},
  {"key":"available_fault_current","type":"number","label":"Available Fault Current (kA)"},
  {"key":"arc_flash_boundary","type":"number","label":"Arc Flash Boundary (inches)"},
  {"key":"incident_energy","type":"number","label":"Incident Energy (cal/cm2)"},
  {"key":"ppe_category","type":"select","label":"PPE Category","required":true,"options":["1","2","3","4","Danger - Do Not Operate"]},
  {"key":"label_installed","type":"checkbox","label":"Arc Flash Label Installed"},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"photo","type":"photo","label":"Label Photo"},
  {"key":"signature","type":"signature","label":"Engineer Signature","required":true}
]'::jsonb);

-- Roofing Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('roofing', 'Roof Inspection Report', 'Pre-bid or maintenance roof inspection', 'inspection', null, true, true, 1,
'[
  {"key":"roof_type","type":"select","label":"Roof Type","required":true,"options":["Asphalt Shingle","Metal Standing Seam","Metal Screw-Down","TPO","EPDM","PVC","Built-Up","Modified Bitumen","Tile (Clay)","Tile (Concrete)","Slate","Wood Shake","Flat/Low Slope"]},
  {"key":"approximate_age","type":"number","label":"Approximate Age (years)"},
  {"key":"total_squares","type":"number","label":"Total Squares"},
  {"key":"slope","type":"text","label":"Roof Slope (e.g., 4/12)"},
  {"key":"layers","type":"select","label":"Number of Layers","options":["1","2","3+"]},
  {"key":"decking_type","type":"select","label":"Decking Type","options":["Plywood","OSB","Skip Sheathing","Concrete","Metal","Unknown"]},
  {"key":"condition","type":"select","label":"Overall Condition","required":true,"options":["Good","Fair","Poor","Failed"]},
  {"key":"findings","type":"multiselect","label":"Findings","options":["Missing Shingles","Curling/Buckling","Granule Loss","Flashing Issues","Valley Deterioration","Ridge Damage","Soffit/Fascia Damage","Gutter Issues","Ponding Water","Membrane Tears","Seam Separation","Penetration Leaks","Ventilation Issues","Ice Dam Evidence","Hail Damage","Wind Damage","Algae/Moss","None"]},
  {"key":"recommendation","type":"select","label":"Recommendation","required":true,"options":["No Action","Spot Repair","Re-Roof (Overlay)","Tear-Off and Replace","Emergency Tarp/Repair","Further Investigation"]},
  {"key":"notes","type":"textarea","label":"Detailed Notes"},
  {"key":"photos","type":"photo","label":"Photos"},
  {"key":"gps","type":"gps","label":"Location"},
  {"key":"signature","type":"signature","label":"Inspector Signature","required":true}
]'::jsonb),

('roofing', 'Storm Damage Assessment', 'Wind/hail/storm damage documentation for insurance', 'inspection', null, true, true, 2,
'[
  {"key":"storm_date","type":"date","label":"Storm Date","required":true},
  {"key":"storm_type","type":"multiselect","label":"Storm Type","required":true,"options":["Hail","Wind","Tornado","Hurricane","Heavy Rain","Fallen Tree/Debris"]},
  {"key":"hail_size","type":"select","label":"Hail Size (if applicable)","options":["Pea","Marble","Quarter","Golf Ball","Tennis Ball","Baseball","Softball","N/A"]},
  {"key":"wind_speed_estimated","type":"text","label":"Estimated Wind Speed (mph)"},
  {"key":"shingle_damage_count","type":"number","label":"Damaged Shingles (count)"},
  {"key":"soft_metal_test","type":"checkbox","label":"Soft Metal Test Performed (HVAC/vents)"},
  {"key":"collateral_damage","type":"multiselect","label":"Collateral Damage","options":["Gutters","Siding","Windows","Fence","Screens","Garage Door","Deck","None"]},
  {"key":"interior_damage","type":"checkbox","label":"Interior Water Damage Present"},
  {"key":"test_squares","type":"number","label":"Test Squares Inspected"},
  {"key":"hits_per_square","type":"number","label":"Average Hits Per Test Square"},
  {"key":"recommendation","type":"select","label":"Recommendation","required":true,"options":["Full Replacement (Insurance Claim)","Partial Repair","Cosmetic Only","No Actionable Damage"]},
  {"key":"notes","type":"textarea","label":"Detailed Notes"},
  {"key":"photos","type":"photo","label":"Damage Photos","required":true},
  {"key":"gps","type":"gps","label":"Location"},
  {"key":"signature","type":"signature","label":"Inspector Signature","required":true}
]'::jsonb);

-- Restoration Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('restoration', 'Content Inventory / Pack-out', 'Document contents for insurance claim during packout', 'compliance', null, true, true, 1,
'[
  {"key":"room","type":"text","label":"Room / Area","required":true},
  {"key":"item_description","type":"text","label":"Item Description","required":true},
  {"key":"quantity","type":"number","label":"Quantity","required":true},
  {"key":"condition","type":"select","label":"Condition","required":true,"options":["Undamaged","Light Damage","Moderate Damage","Severe Damage","Total Loss"]},
  {"key":"disposition","type":"select","label":"Disposition","required":true,"options":["Pack-Out","Clean on Site","Dispose","Store in Place"]},
  {"key":"estimated_value","type":"number","label":"Estimated Value ($)"},
  {"key":"box_number","type":"text","label":"Box/Crate Number"},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"photo","type":"photo","label":"Item Photo","required":true}
]'::jsonb),

('restoration', 'Air Quality Test', 'Indoor air quality testing for mold/particulates', 'inspection', 'IICRC S520', true, true, 2,
'[
  {"key":"test_type","type":"select","label":"Test Type","required":true,"options":["Air Sample","Surface Swab","Tape Lift","Bulk Sample"]},
  {"key":"sample_location","type":"text","label":"Sample Location","required":true},
  {"key":"sample_id","type":"text","label":"Sample ID / Lab #","required":true},
  {"key":"outdoor_control","type":"checkbox","label":"Outdoor Control Sample Taken"},
  {"key":"temperature","type":"number","label":"Temperature (F)"},
  {"key":"humidity","type":"number","label":"Relative Humidity (%)"},
  {"key":"volume_liters","type":"number","label":"Volume Collected (liters)"},
  {"key":"lab_name","type":"text","label":"Laboratory Name"},
  {"key":"results_pending","type":"checkbox","label":"Results Pending"},
  {"key":"spore_count","type":"number","label":"Spore Count (if available)"},
  {"key":"species_identified","type":"textarea","label":"Species Identified"},
  {"key":"pass_fail","type":"select","label":"Result","options":["Pass","Fail","Pending"]},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"photo","type":"photo","label":"Sample Location Photo"},
  {"key":"gps","type":"gps","label":"Location"},
  {"key":"signature","type":"signature","label":"Technician Signature","required":true}
]'::jsonb),

('restoration', 'Containment Checklist', 'Verify containment setup for mold/asbestos/lead work', 'safety', 'IICRC S520 / EPA RRP', true, true, 3,
'[
  {"key":"containment_type","type":"select","label":"Containment Type","required":true,"options":["Full","Partial","Source","None Required"]},
  {"key":"barrier_material","type":"select","label":"Barrier Material","options":["6-mil Poly","Fire-Rated Poly","Rigid Panel","ZipWall","Combination"]},
  {"key":"negative_air","type":"checkbox","label":"Negative Air Machine Running"},
  {"key":"air_changes_per_hour","type":"number","label":"Air Changes Per Hour (ACH)"},
  {"key":"decon_chamber","type":"checkbox","label":"Decontamination Chamber Set Up"},
  {"key":"warning_signs","type":"checkbox","label":"Warning Signs Posted"},
  {"key":"sealed_hvac","type":"checkbox","label":"HVAC Sealed / Isolated"},
  {"key":"sealed_openings","type":"checkbox","label":"All Openings Sealed"},
  {"key":"pressure_differential","type":"number","label":"Pressure Differential (Pa)"},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"photos","type":"photo","label":"Containment Photos","required":true},
  {"key":"signature","type":"signature","label":"Supervisor Signature","required":true}
]'::jsonb);

-- Painting Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('painting', 'Surface Prep Checklist', 'Document surface preparation before coating application', 'quality', null, true, true, 1,
'[
  {"key":"surface_type","type":"select","label":"Surface Type","required":true,"options":["Drywall","Wood","Metal","Concrete","Stucco","Brick","Previously Painted","Wallpaper"]},
  {"key":"prep_methods","type":"multiselect","label":"Prep Methods Used","required":true,"options":["Sanding","Scraping","Power Washing","Chemical Strip","TSP Wash","Deglossing","Skim Coat","Caulking","Patching","Priming"]},
  {"key":"moisture_reading","type":"number","label":"Moisture Reading (%)"},
  {"key":"temperature","type":"number","label":"Surface Temperature (F)"},
  {"key":"humidity","type":"number","label":"Relative Humidity (%)"},
  {"key":"primer_used","type":"text","label":"Primer Used"},
  {"key":"coats_of_primer","type":"number","label":"Coats of Primer"},
  {"key":"surface_clean","type":"checkbox","label":"Surface Clean and Dry"},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"photos","type":"photo","label":"Before Photos"},
  {"key":"signature","type":"signature","label":"Painter Signature","required":true}
]'::jsonb),

('painting', 'Lead Paint RRP Checklist', 'EPA RRP Rule compliance for pre-1978 properties', 'compliance', 'EPA RRP 40 CFR 745', true, true, 2,
'[
  {"key":"property_year","type":"number","label":"Property Year Built","required":true},
  {"key":"lead_test_method","type":"select","label":"Lead Test Method","required":true,"options":["XRF","EPA Test Kit","Lab Analysis","Assume Lead Present"]},
  {"key":"lead_detected","type":"checkbox","label":"Lead Paint Detected"},
  {"key":"firm_cert_number","type":"text","label":"Firm Certification #","required":true},
  {"key":"renovator_cert_number","type":"text","label":"Renovator Certification #","required":true},
  {"key":"containment_set","type":"checkbox","label":"Containment Set Up"},
  {"key":"poly_sheeting","type":"checkbox","label":"6-mil Poly Sheeting Placed"},
  {"key":"warning_signs","type":"checkbox","label":"Warning Signs Posted"},
  {"key":"prohibited_practices","type":"checkbox","label":"No Prohibited Practices Used (no open flame, no heat gun >1100F, no uncontained power tools)"},
  {"key":"hepa_vacuum","type":"checkbox","label":"HEPA Vacuum Used for Cleanup"},
  {"key":"cleaning_verification","type":"select","label":"Cleaning Verification","required":true,"options":["Visual Inspection","Wet Cloth Test","Clearance Testing"]},
  {"key":"pamphlet_provided","type":"checkbox","label":"EPA Pamphlet Provided to Owner/Occupant"},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"photos","type":"photo","label":"Documentation Photos"},
  {"key":"signature","type":"signature","label":"Certified Renovator Signature","required":true}
]'::jsonb);

-- General / All-Trade Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
(null, 'Pre-Task Plan', 'Pre-task safety planning before work begins', 'safety', 'OSHA', true, true, 1,
'[
  {"key":"task_description","type":"textarea","label":"Task Description","required":true},
  {"key":"hazards_identified","type":"multiselect","label":"Hazards Identified","required":true,"options":["Electrical","Fall","Struck By","Caught In","Chemical","Heat/Cold","Confined Space","Trenching","Heavy Lifting","Noise","Asbestos/Lead","Biological","Traffic","Other"]},
  {"key":"controls","type":"textarea","label":"Controls / Mitigations","required":true},
  {"key":"ppe_required","type":"multiselect","label":"PPE Required","required":true,"options":["Hard Hat","Safety Glasses","Face Shield","Hearing Protection","Gloves","Steel-Toe Boots","Hi-Vis Vest","Fall Harness","Respirator","Tyvek Suit","Rubber Boots","Arc Flash PPE"]},
  {"key":"permits_required","type":"multiselect","label":"Permits Required","options":["Hot Work","Confined Space","Excavation","Electrical Work","Roof Access","Crane/Rigging","None"]},
  {"key":"emergency_plan","type":"textarea","label":"Emergency Plan"},
  {"key":"crew_briefed","type":"checkbox","label":"All Crew Members Briefed"},
  {"key":"notes","type":"textarea","label":"Additional Notes"},
  {"key":"gps","type":"gps","label":"Job Site Location"},
  {"key":"signature","type":"signature","label":"Supervisor Signature","required":true}
]'::jsonb),

(null, 'Job Safety Analysis (JSA)', 'Step-by-step job hazard analysis', 'safety', 'OSHA', true, true, 2,
'[
  {"key":"job_title","type":"text","label":"Job/Task Title","required":true},
  {"key":"department","type":"text","label":"Department/Trade"},
  {"key":"analysis_date","type":"date","label":"Analysis Date","required":true},
  {"key":"step_1_task","type":"text","label":"Step 1 - Task","required":true},
  {"key":"step_1_hazard","type":"textarea","label":"Step 1 - Potential Hazards"},
  {"key":"step_1_controls","type":"textarea","label":"Step 1 - Controls"},
  {"key":"step_2_task","type":"text","label":"Step 2 - Task"},
  {"key":"step_2_hazard","type":"textarea","label":"Step 2 - Potential Hazards"},
  {"key":"step_2_controls","type":"textarea","label":"Step 2 - Controls"},
  {"key":"step_3_task","type":"text","label":"Step 3 - Task"},
  {"key":"step_3_hazard","type":"textarea","label":"Step 3 - Potential Hazards"},
  {"key":"step_3_controls","type":"textarea","label":"Step 3 - Controls"},
  {"key":"step_4_task","type":"text","label":"Step 4 - Task"},
  {"key":"step_4_hazard","type":"textarea","label":"Step 4 - Potential Hazards"},
  {"key":"step_4_controls","type":"textarea","label":"Step 4 - Controls"},
  {"key":"step_5_task","type":"text","label":"Step 5 - Task"},
  {"key":"step_5_hazard","type":"textarea","label":"Step 5 - Potential Hazards"},
  {"key":"step_5_controls","type":"textarea","label":"Step 5 - Controls"},
  {"key":"reviewed_by","type":"text","label":"Reviewed By","required":true},
  {"key":"signature","type":"signature","label":"Supervisor Signature","required":true}
]'::jsonb),

(null, 'Site Inspection', 'General job site inspection report', 'inspection', null, true, true, 3,
'[
  {"key":"inspection_type","type":"select","label":"Inspection Type","required":true,"options":["Pre-Construction","Progress","Final","Safety","Quality","Warranty"]},
  {"key":"weather_conditions","type":"select","label":"Weather","options":["Clear","Cloudy","Rain","Snow","Wind","Extreme Heat","Extreme Cold"]},
  {"key":"housekeeping","type":"select","label":"Housekeeping","required":true,"options":["Excellent","Good","Fair","Poor"]},
  {"key":"safety_compliance","type":"select","label":"Safety Compliance","required":true,"options":["Full","Partial","Non-Compliant"]},
  {"key":"ppe_compliance","type":"checkbox","label":"All Workers in Proper PPE"},
  {"key":"fall_protection","type":"select","label":"Fall Protection","options":["In Use","Not Required","Deficient","N/A"]},
  {"key":"electrical_safety","type":"select","label":"Electrical Safety","options":["Compliant","Issues Found","N/A"]},
  {"key":"work_quality","type":"select","label":"Work Quality","required":true,"options":["Excellent","Acceptable","Needs Correction","Unacceptable"]},
  {"key":"deficiencies","type":"textarea","label":"Deficiencies / Corrective Actions"},
  {"key":"notes","type":"textarea","label":"General Notes"},
  {"key":"photos","type":"photo","label":"Site Photos"},
  {"key":"gps","type":"gps","label":"Location"},
  {"key":"signature","type":"signature","label":"Inspector Signature","required":true}
]'::jsonb);

-- Pool Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('pool', 'Water Chemistry Log', 'Pool/spa water chemistry testing and treatment', 'compliance', null, true, true, 1,
'[
  {"key":"pool_type","type":"select","label":"Pool Type","required":true,"options":["Residential Pool","Residential Spa","Commercial Pool","Commercial Spa"]},
  {"key":"sanitizer_type","type":"select","label":"Sanitizer Type","options":["Chlorine","Salt/SWG","Bromine","Biguanide","UV/Ozone"]},
  {"key":"free_chlorine","type":"number","label":"Free Chlorine (ppm)","required":true},
  {"key":"total_chlorine","type":"number","label":"Total Chlorine (ppm)"},
  {"key":"ph","type":"number","label":"pH","required":true},
  {"key":"alkalinity","type":"number","label":"Total Alkalinity (ppm)","required":true},
  {"key":"calcium_hardness","type":"number","label":"Calcium Hardness (ppm)"},
  {"key":"cya","type":"number","label":"Cyanuric Acid (ppm)"},
  {"key":"tds","type":"number","label":"TDS (ppm)"},
  {"key":"water_temp","type":"number","label":"Water Temperature (F)"},
  {"key":"salt_level","type":"number","label":"Salt Level (ppm)"},
  {"key":"phosphates","type":"number","label":"Phosphates (ppb)"},
  {"key":"chemicals_added","type":"textarea","label":"Chemicals Added (type & amount)"},
  {"key":"filter_pressure","type":"number","label":"Filter Pressure (PSI)"},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"signature","type":"signature","label":"Technician Signature","required":true}
]'::jsonb),

('pool', 'Equipment Inspection', 'Pool equipment inspection and service report', 'inspection', null, true, true, 2,
'[
  {"key":"pump_running","type":"checkbox","label":"Pump Running Properly"},
  {"key":"pump_amps","type":"number","label":"Pump Amp Draw"},
  {"key":"pump_primed","type":"checkbox","label":"Pump Primed / No Air Leaks"},
  {"key":"filter_type","type":"select","label":"Filter Type","options":["Sand","DE","Cartridge"]},
  {"key":"filter_condition","type":"select","label":"Filter Condition","options":["Good","Needs Cleaning","Needs Replacement"]},
  {"key":"heater_operational","type":"select","label":"Heater Status","options":["Operational","Not Operational","N/A"]},
  {"key":"salt_cell_condition","type":"select","label":"Salt Cell Condition","options":["Good","Needs Cleaning","Needs Replacement","N/A"]},
  {"key":"automation_functional","type":"select","label":"Automation System","options":["Functional","Issues","N/A"]},
  {"key":"safety_equipment","type":"multiselect","label":"Safety Equipment Verified","options":["Drain Covers (VGBA)","Fence/Barrier","Gate Self-Closing","Gate Self-Latching","Pool Alarm","Safety Cover"]},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"photos","type":"photo","label":"Equipment Photos"},
  {"key":"signature","type":"signature","label":"Technician Signature","required":true}
]'::jsonb);

-- Pest Control Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('pest', 'Chemical Application Log', 'Pesticide application record per state regulations', 'compliance', 'EPA FIFRA', true, true, 1,
'[
  {"key":"target_pest","type":"multiselect","label":"Target Pest","required":true,"options":["Ants","Roaches","Termites","Rodents","Mosquitoes","Bed Bugs","Spiders","Wasps/Bees","Fleas/Ticks","Wildlife","Stored Product Pests","Other"]},
  {"key":"product_name","type":"text","label":"Product Name","required":true},
  {"key":"epa_reg_number","type":"text","label":"EPA Registration #","required":true},
  {"key":"active_ingredient","type":"text","label":"Active Ingredient"},
  {"key":"application_method","type":"select","label":"Application Method","required":true,"options":["Spray","Bait","Dust","Fumigation","Trap","Exclusion","Granular","Fog/ULV","Injection"]},
  {"key":"amount_used","type":"text","label":"Amount Used","required":true},
  {"key":"dilution_rate","type":"text","label":"Dilution Rate"},
  {"key":"area_treated","type":"text","label":"Area Treated","required":true},
  {"key":"square_footage","type":"number","label":"Square Footage Treated"},
  {"key":"wind_speed","type":"number","label":"Wind Speed (mph)"},
  {"key":"temperature","type":"number","label":"Temperature (F)"},
  {"key":"re_entry_interval","type":"text","label":"Re-Entry Interval"},
  {"key":"applicator_license","type":"text","label":"Applicator License #","required":true},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"signature","type":"signature","label":"Applicator Signature","required":true}
]'::jsonb),

('pest', 'WDO Report', 'Wood-Destroying Organism inspection report (real estate)', 'inspection', null, true, true, 2,
'[
  {"key":"inspection_type","type":"select","label":"Inspection Type","required":true,"options":["Original","Re-Inspection","Supplemental"]},
  {"key":"property_type","type":"select","label":"Property Type","required":true,"options":["Single Family","Multi-Family","Condo","Townhouse","Commercial"]},
  {"key":"areas_inspected","type":"multiselect","label":"Areas Inspected","required":true,"options":["Interior","Exterior","Attic","Crawl Space","Garage","Basement","Detached Structures"]},
  {"key":"areas_not_inspected","type":"textarea","label":"Areas NOT Inspected (explain why)"},
  {"key":"evidence_found","type":"multiselect","label":"Evidence Found","options":["Live Termites","Termite Damage","Termite Tubes","Previous Treatment","Carpenter Ants","Carpenter Bees","Wood Rot","Powder Post Beetles","None"]},
  {"key":"damage_description","type":"textarea","label":"Damage Description"},
  {"key":"treatment_recommended","type":"checkbox","label":"Treatment Recommended"},
  {"key":"repairs_recommended","type":"checkbox","label":"Repairs Recommended"},
  {"key":"repair_description","type":"textarea","label":"Repair Description"},
  {"key":"diagram_notes","type":"textarea","label":"Diagram Notes"},
  {"key":"photos","type":"photo","label":"Evidence Photos"},
  {"key":"inspector_license","type":"text","label":"Inspector License #","required":true},
  {"key":"signature","type":"signature","label":"Inspector Signature","required":true}
]'::jsonb);

-- Solar Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('solar', 'Solar System Inspection', 'PV system inspection and performance check', 'inspection', 'NEC 690', true, true, 1,
'[
  {"key":"system_size_kw","type":"number","label":"System Size (kW)","required":true},
  {"key":"panel_count","type":"number","label":"Panel Count","required":true},
  {"key":"panel_make","type":"text","label":"Panel Manufacturer"},
  {"key":"panel_model","type":"text","label":"Panel Model"},
  {"key":"inverter_type","type":"select","label":"Inverter Type","required":true,"options":["String","Micro","Hybrid","Off-Grid"]},
  {"key":"inverter_make","type":"text","label":"Inverter Make"},
  {"key":"mounting_type","type":"select","label":"Mounting","required":true,"options":["Roof Mount","Ground Mount","Carport","Tracker"]},
  {"key":"panel_condition","type":"select","label":"Panel Condition","required":true,"options":["Good","Dirty","Cracked","Delaminating","Hot Spot"]},
  {"key":"wiring_condition","type":"select","label":"Wiring Condition","required":true,"options":["Good","Exposed/Damaged","Loose Connections"]},
  {"key":"dc_voltage","type":"number","label":"DC String Voltage (V)"},
  {"key":"ac_output","type":"number","label":"AC Output (W)"},
  {"key":"production_ytd_kwh","type":"number","label":"Production YTD (kWh)"},
  {"key":"rapid_shutdown","type":"checkbox","label":"Rapid Shutdown Functional (NEC 690.12)"},
  {"key":"grounding_verified","type":"checkbox","label":"Equipment Grounding Verified"},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"photos","type":"photo","label":"System Photos"},
  {"key":"signature","type":"signature","label":"Technician Signature","required":true}
]'::jsonb);

-- Fire Protection Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('fire_protection', 'NFPA 25 ITM Report', 'Inspection/Testing/Maintenance of fire sprinkler systems', 'compliance', 'NFPA 25', true, true, 1,
'[
  {"key":"system_type","type":"select","label":"System Type","required":true,"options":["Wet Pipe","Dry Pipe","Pre-Action","Deluge","Standpipe","Fire Pump"]},
  {"key":"inspection_frequency","type":"select","label":"Inspection Frequency","required":true,"options":["Weekly","Monthly","Quarterly","Semi-Annual","Annual","5-Year"]},
  {"key":"main_drain_test","type":"checkbox","label":"Main Drain Test Performed"},
  {"key":"main_drain_psi","type":"number","label":"Main Drain Static PSI"},
  {"key":"main_drain_residual","type":"number","label":"Main Drain Residual PSI"},
  {"key":"alarm_test","type":"checkbox","label":"Alarm Test Performed"},
  {"key":"alarm_functional","type":"checkbox","label":"Alarm Functional"},
  {"key":"gauges_normal","type":"checkbox","label":"All Gauges in Normal Range"},
  {"key":"valves_open","type":"checkbox","label":"All Control Valves Open/Secured"},
  {"key":"tamper_switches","type":"checkbox","label":"Tamper Switches Functional"},
  {"key":"heads_condition","type":"select","label":"Sprinkler Heads Condition","options":["Good","Corroded","Painted Over","Damaged","Obstructed"]},
  {"key":"spare_heads","type":"checkbox","label":"Spare Head Cabinet Stocked"},
  {"key":"fire_pump_tested","type":"checkbox","label":"Fire Pump Tested (if applicable)"},
  {"key":"deficiencies","type":"textarea","label":"Deficiencies Found"},
  {"key":"corrective_actions","type":"textarea","label":"Corrective Actions Taken"},
  {"key":"photos","type":"photo","label":"Photos"},
  {"key":"next_inspection_date","type":"date","label":"Next Inspection Due"},
  {"key":"inspector_license","type":"text","label":"Inspector License #","required":true},
  {"key":"signature","type":"signature","label":"Inspector Signature","required":true}
]'::jsonb);

-- Environmental Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('environmental', 'Sample Collection Log', 'Environmental sample collection chain of custody', 'compliance', null, true, true, 1,
'[
  {"key":"sample_id","type":"text","label":"Sample ID","required":true},
  {"key":"sample_type","type":"select","label":"Sample Type","required":true,"options":["Soil","Water","Air","Surface Wipe","Bulk Material","Waste"]},
  {"key":"matrix","type":"text","label":"Matrix Description"},
  {"key":"collection_method","type":"select","label":"Collection Method","required":true,"options":["Grab","Composite","Continuous","Swab","Core","Auger"]},
  {"key":"collection_date","type":"date","label":"Collection Date","required":true},
  {"key":"collection_time","type":"time","label":"Collection Time","required":true},
  {"key":"location_description","type":"text","label":"Location Description","required":true},
  {"key":"depth","type":"text","label":"Depth (if applicable)"},
  {"key":"container_type","type":"text","label":"Container Type"},
  {"key":"preservative","type":"text","label":"Preservative Used"},
  {"key":"analysis_requested","type":"multiselect","label":"Analysis Requested","options":["Metals","VOCs","SVOCs","PCBs","Pesticides","Asbestos","Lead","Petroleum","Bacteria","pH/Conductivity"]},
  {"key":"lab_name","type":"text","label":"Laboratory Name","required":true},
  {"key":"chain_of_custody_number","type":"text","label":"COC Number"},
  {"key":"gps","type":"gps","label":"Sample Location"},
  {"key":"photos","type":"photo","label":"Sample Photos"},
  {"key":"sampler_signature","type":"signature","label":"Sampler Signature","required":true}
]'::jsonb);

-- Septic Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('septic', 'Pumping Record', 'Septic tank pumping service record', 'compliance', null, true, true, 1,
'[
  {"key":"tank_type","type":"select","label":"Tank Type","required":true,"options":["Concrete","Fiberglass","Polyethylene","Steel","Unknown"]},
  {"key":"tank_size_gallons","type":"number","label":"Tank Size (gallons)","required":true},
  {"key":"gallons_pumped","type":"number","label":"Gallons Pumped","required":true},
  {"key":"tank_condition","type":"select","label":"Tank Condition","required":true,"options":["Good","Fair","Cracked","Deteriorating","Needs Replacement"]},
  {"key":"baffles_condition","type":"select","label":"Inlet/Outlet Baffles","required":true,"options":["Good","Missing","Damaged","N/A"]},
  {"key":"lids_condition","type":"select","label":"Lids/Risers","options":["Good","Cracked","Missing","Below Grade"]},
  {"key":"scum_layer","type":"number","label":"Scum Layer Thickness (inches)"},
  {"key":"sludge_layer","type":"number","label":"Sludge Layer Thickness (inches)"},
  {"key":"effluent_filter","type":"select","label":"Effluent Filter","options":["Present - Clean","Present - Dirty","Not Installed","N/A"]},
  {"key":"drainfield_condition","type":"select","label":"Drainfield Condition","options":["Good","Slow","Surfacing","Failed","Not Inspected"]},
  {"key":"disposal_facility","type":"text","label":"Disposal Facility","required":true},
  {"key":"manifest_number","type":"text","label":"Manifest Number"},
  {"key":"notes","type":"textarea","label":"Notes"},
  {"key":"photos","type":"photo","label":"Photos"},
  {"key":"pumper_license","type":"text","label":"Pumper License #"},
  {"key":"signature","type":"signature","label":"Technician Signature","required":true}
]'::jsonb),

('septic', 'System Inspection', 'Full septic system inspection (real estate / regulatory)', 'inspection', null, true, true, 2,
'[
  {"key":"inspection_purpose","type":"select","label":"Inspection Purpose","required":true,"options":["Real Estate Transfer","Annual","Complaint","Permit Renewal","Design Verification"]},
  {"key":"system_type","type":"select","label":"System Type","required":true,"options":["Conventional","Chamber","Mound","Drip","Aerobic Treatment Unit","Sand Filter","Constructed Wetland"]},
  {"key":"system_age","type":"number","label":"System Age (years)"},
  {"key":"bedrooms","type":"number","label":"Number of Bedrooms"},
  {"key":"daily_flow_estimate","type":"number","label":"Estimated Daily Flow (GPD)"},
  {"key":"tank_pumped","type":"checkbox","label":"Tank Pumped for Inspection"},
  {"key":"structural_integrity","type":"select","label":"Tank Structural Integrity","required":true,"options":["Sound","Minor Issues","Major Issues","Failed"]},
  {"key":"hydraulic_load_test","type":"checkbox","label":"Hydraulic Load Test Performed"},
  {"key":"test_result","type":"select","label":"Hydraulic Test Result","options":["Pass","Slow","Fail","N/A"]},
  {"key":"distribution_box","type":"select","label":"Distribution Box","options":["Level","Uneven","Damaged","N/A"]},
  {"key":"overall_result","type":"select","label":"Overall Result","required":true,"options":["Pass","Conditional Pass","Fail"]},
  {"key":"conditions","type":"textarea","label":"Conditions / Recommendations"},
  {"key":"photos","type":"photo","label":"Inspection Photos"},
  {"key":"gps","type":"gps","label":"System Location"},
  {"key":"inspector_license","type":"text","label":"Inspector License #","required":true},
  {"key":"signature","type":"signature","label":"Inspector Signature","required":true}
]'::jsonb);

-- Chimney Templates
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('chimney', 'NFPA 211 Chimney Inspection', 'Chimney inspection per NFPA 211 standards (Level 1/2/3)', 'inspection', 'NFPA 211', true, true, 1,
'[
  {"key":"inspection_level","type":"select","label":"Inspection Level","required":true,"options":["Level 1","Level 2","Level 3"]},
  {"key":"chimney_type","type":"select","label":"Chimney Type","required":true,"options":["Masonry","Factory-Built/Prefab","Metal Liner","Clay Liner","Cast-in-Place Liner","Unlined"]},
  {"key":"appliance_type","type":"select","label":"Connected Appliance","required":true,"options":["Fireplace (Wood)","Fireplace (Gas)","Wood Stove","Pellet Stove","Furnace","Boiler","Water Heater","None"]},
  {"key":"flue_size","type":"text","label":"Flue Size"},
  {"key":"chimney_height","type":"number","label":"Chimney Height (ft)"},
  {"key":"cap_condition","type":"select","label":"Chimney Cap","required":true,"options":["Good","Damaged","Missing"]},
  {"key":"crown_condition","type":"select","label":"Crown/Wash","required":true,"options":["Good","Cracked","Deteriorated","Missing"]},
  {"key":"flashing_condition","type":"select","label":"Flashing","required":true,"options":["Good","Loose","Corroded","Missing"]},
  {"key":"mortar_joints","type":"select","label":"Mortar Joints","options":["Good","Minor Deterioration","Major Deterioration","N/A"]},
  {"key":"liner_condition","type":"select","label":"Liner Condition","required":true,"options":["Good","Cracked","Gaps","Missing Sections","Deteriorated"]},
  {"key":"creosote_level","type":"select","label":"Creosote Buildup","options":["None/Light (Stage 1)","Moderate (Stage 2)","Glazed (Stage 3)","N/A"]},
  {"key":"clearance_to_combustibles","type":"checkbox","label":"Proper Clearance to Combustibles"},
  {"key":"smoke_chamber","type":"select","label":"Smoke Chamber","options":["Good","Corbelled","Damaged","N/A"]},
  {"key":"damper_functional","type":"checkbox","label":"Damper Functional"},
  {"key":"recommendations","type":"textarea","label":"Recommendations"},
  {"key":"photos","type":"photo","label":"Inspection Photos"},
  {"key":"signature","type":"signature","label":"Inspector Signature","required":true}
]'::jsonb);

-- Landscaping Template
INSERT INTO form_templates (trade, name, description, category, regulation_reference, is_system, is_active, sort_order, fields) VALUES
('landscaping', 'Irrigation System Inspection', 'Sprinkler/irrigation system inspection and audit', 'inspection', null, true, true, 1,
'[
  {"key":"system_type","type":"select","label":"System Type","required":true,"options":["In-Ground Sprinkler","Drip Irrigation","Combination","Manual"]},
  {"key":"controller_make","type":"text","label":"Controller Make/Model"},
  {"key":"zones_total","type":"number","label":"Total Zones","required":true},
  {"key":"zones_inspected","type":"number","label":"Zones Inspected"},
  {"key":"pressure_psi","type":"number","label":"System Pressure (PSI)"},
  {"key":"backflow_device","type":"select","label":"Backflow Device","required":true,"options":["PVB","RPZ","DCVA","AVB","None"]},
  {"key":"backflow_test_current","type":"checkbox","label":"Backflow Test Current"},
  {"key":"broken_heads","type":"number","label":"Broken/Damaged Heads"},
  {"key":"coverage_issues","type":"checkbox","label":"Coverage/Uniformity Issues Found"},
  {"key":"leak_detected","type":"checkbox","label":"Leaks Detected"},
  {"key":"rain_sensor","type":"select","label":"Rain Sensor","options":["Present & Working","Present & Not Working","Not Installed"]},
  {"key":"schedule_efficient","type":"checkbox","label":"Watering Schedule Efficient"},
  {"key":"recommendations","type":"textarea","label":"Recommendations"},
  {"key":"photos","type":"photo","label":"System Photos"},
  {"key":"signature","type":"signature","label":"Technician Signature","required":true}
]'::jsonb);
