-- DEPTH34: Property Preservation Module
-- PP work orders, smart photo system, national company profiles,
-- winterization/dewinterization, debris estimation, boiler/furnace DB,
-- stripped property estimators, utility coordination, vendor apps,
-- REO lead generation, securing reference, board-up calculator.

-- ============================================================================
-- PP NATIONAL COMPANY PROFILES (system-wide reference — no company_id)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pp_national_companies (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name               text NOT NULL,
  name_normalized    text NOT NULL,
  portal_url         text,
  vendor_signup_url  text,
  phone              text,
  email              text,
  photo_naming       text,
  photo_orientation  text CHECK (photo_orientation IS NULL OR photo_orientation IN ('landscape','portrait','any')),
  required_shots     jsonb DEFAULT '{}',
  submission_deadline_hours integer DEFAULT 48,
  pay_schedule       text CHECK (pay_schedule IS NULL OR pay_schedule IN ('weekly','biweekly','monthly','net30','net45','net60')),
  insurance_minimum  numeric(12,2),
  chargeback_policy  text,
  notes              text,
  is_active          boolean NOT NULL DEFAULT true,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),
  deleted_at         timestamptz
);

CREATE INDEX idx_pp_nationals_name ON pp_national_companies (name_normalized) WHERE deleted_at IS NULL;

ALTER TABLE pp_national_companies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pp_nationals_select" ON pp_national_companies
  FOR SELECT TO authenticated USING (deleted_at IS NULL);

CREATE POLICY "pp_nationals_system" ON pp_national_companies
  FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('pp_national_companies');

-- Seed national company profiles
INSERT INTO pp_national_companies (name, name_normalized, portal_url, vendor_signup_url, submission_deadline_hours, pay_schedule, insurance_minimum, photo_orientation, notes) VALUES
('Safeguard Properties', 'safeguard properties', 'safeguardproperties.com', 'safeguardproperties.com/vendor-signup', 24, 'weekly', 1000000, 'landscape', 'Largest PP national. Date-stamped landscape photos. Weekly pay. 24hr submission deadline.'),
('MCS/Stewart', 'mcs stewart', 'maboreal.com', 'maboreal.com/apply', 48, 'biweekly', 1000000, 'any', 'Bold naming convention. Bi-weekly pay. 48hr submission window.'),
('Cyprexx', 'cyprexx', 'cyprexx.com', 'cyprexx.com/vendors', 48, 'biweekly', 1000000, 'any', 'Growing national. Standard photo requirements.'),
('NFR', 'nfr', 'nfronline.com', 'nfronline.com/become-a-vendor', 72, 'biweekly', 1000000, 'any', 'Requires orientation webinar. Background check mandatory.'),
('Xome', 'xome', 'xome.com', 'xome.com/field-services', 48, 'monthly', 1000000, 'any', 'Technology-forward portal. Monthly payment cycles.'),
('Altisource', 'altisource', 'altisource.com', 'altisource.com/vendor-management', 48, 'net30', 1000000, 'any', 'Diversified services. Net-30 payment terms.'),
('Spectrum Field Services', 'spectrum field services', 'spectrumfs.com', 'spectrumfs.com/vendors', 48, 'biweekly', 1000000, 'any', 'Regional presence. Standard requirements.'),
('United Field Services', 'united field services', 'unitedfs.com', 'unitedfs.com/apply', 48, 'biweekly', 1000000, 'any', 'Growing regional national.'),
('Brookstone Management', 'brookstone management', 'brookstonemanagement.com', 'brookstonemanagement.com/vendor', 72, 'net30', 1000000, 'any', 'Asset management focus. Detailed photo documentation required.')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PP WORK ORDER TYPES (system reference — 25+ service types)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pp_work_order_types (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code            text NOT NULL UNIQUE,
  name            text NOT NULL,
  category        text NOT NULL CHECK (category IN (
    'securing', 'winterization', 'debris', 'lawn_snow',
    'inspection', 'repair', 'utility', 'specialty'
  )),
  description     text,
  default_checklist jsonb DEFAULT '[]',
  required_photos   jsonb DEFAULT '[]',
  estimated_hours   numeric(4,1),
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE pp_work_order_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pp_wo_types_select" ON pp_work_order_types
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "pp_wo_types_system" ON pp_work_order_types
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Seed work order types
INSERT INTO pp_work_order_types (code, name, category, estimated_hours) VALUES
('INIT_SECURE', 'Initial Secure', 'securing', 2.0),
('REKEY', 'Re-key', 'securing', 1.0),
('PADLOCK', 'Padlock Install', 'securing', 0.5),
('LOCKBOX', 'Lockbox Install', 'securing', 0.5),
('GARAGE_DISABLE', 'Garage Disable', 'securing', 1.0),
('BOARDUP', 'Board-up', 'securing', 2.0),
('WINT_DRY', 'Dry Winterization', 'winterization', 2.0),
('WINT_WET', 'Wet/Radiant Winterization', 'winterization', 3.0),
('WINT_STEAM', 'Steam Winterization', 'winterization', 3.0),
('DEWINT', 'De-winterization', 'winterization', 2.0),
('REWINT', 'Re-winterization', 'winterization', 2.5),
('WINT_WELL', 'Well Winterization', 'winterization', 1.5),
('WINT_SEPTIC', 'Septic Winterization', 'winterization', 1.0),
('WINT_SPRINKLER', 'Sprinkler Winterization', 'winterization', 1.5),
('DEBRIS_INT', 'Interior Debris Removal', 'debris', 4.0),
('DEBRIS_EXT', 'Exterior Debris Removal', 'debris', 3.0),
('APPLIANCE_REMOVE', 'Appliance Removal', 'debris', 2.0),
('GRASS_INIT', 'Initial Grass Cut', 'lawn_snow', 2.0),
('GRASS_RECUR', 'Recurring Grass Cut', 'lawn_snow', 1.5),
('SHRUB_TRIM', 'Shrub/Tree Trimming', 'lawn_snow', 2.0),
('SNOW_REMOVE', 'Snow Removal', 'lawn_snow', 1.5),
('POOL_WINT', 'Pool Winterization', 'specialty', 2.0),
('POOL_SECURE', 'Pool Securing', 'specialty', 1.0),
('INSPECT_OCC', 'Occupancy Inspection', 'inspection', 1.0),
('INSPECT_DMG', 'Damage Inspection', 'inspection', 1.5),
('SALES_CLEAN', 'Sales Clean (Broom Sweep)', 'debris', 3.0),
('MOLD_ASSESS', 'Mold Assessment', 'inspection', 2.0),
('HAZARD_CLAIM', 'Hazard Claim', 'specialty', 1.5),
('EVICTION_SUPPORT', 'Eviction Support', 'specialty', 3.0),
('CODE_VIOLATION', 'Code Violation Remediation', 'repair', 4.0),
('HOA_VIOLATION', 'HOA Violation Remediation', 'repair', 3.0),
('ROOF_TARP', 'Roof Tarp', 'repair', 2.0),
('SUMP_PUMP', 'Sump Pump Install', 'repair', 3.0),
('SMOKE_CO', 'Smoke/CO Detector Install', 'repair', 1.0),
('HANDRAIL', 'Handrail Install', 'repair', 2.0),
('TRIP_HAZARD', 'Trip Hazard Remediation', 'repair', 2.0),
('UTILITY_COORD', 'Utility Coordination', 'utility', 1.0),
('PROP_REG', 'Property Registration', 'specialty', 0.5)
ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- PP WORK ORDERS (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pp_work_orders (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  property_id       uuid REFERENCES properties(id),
  job_id            uuid REFERENCES jobs(id),
  national_company_id uuid REFERENCES pp_national_companies(id),
  work_order_type_id uuid NOT NULL REFERENCES pp_work_order_types(id),
  external_order_id text,
  status            text NOT NULL DEFAULT 'assigned'
    CHECK (status IN ('assigned','in_progress','completed','submitted','approved','rejected','disputed')),
  assigned_to       uuid REFERENCES auth.users(id),
  assigned_at       timestamptz,
  started_at        timestamptz,
  completed_at      timestamptz,
  submitted_at      timestamptz,
  due_date          timestamptz,
  bid_amount        numeric(12,2),
  approved_amount   numeric(12,2),
  photo_mode        text DEFAULT 'standard'
    CHECK (photo_mode IN ('quick','standard','full_protection')),
  checklist_progress jsonb DEFAULT '{}',
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

CREATE INDEX idx_pp_wo_company ON pp_work_orders (company_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_wo_property ON pp_work_orders (property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_wo_national ON pp_work_orders (national_company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_wo_assigned ON pp_work_orders (assigned_to, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_wo_due ON pp_work_orders (due_date) WHERE deleted_at IS NULL AND status NOT IN ('completed','approved');

ALTER TABLE pp_work_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pp_wo_select" ON pp_work_orders
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

CREATE POLICY "pp_wo_insert" ON pp_work_orders
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "pp_wo_update" ON pp_work_orders
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('pp_work_orders');
SELECT audit_trigger_fn('pp_work_orders');

-- ============================================================================
-- PP CHARGEBACKS (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pp_chargebacks (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  work_order_id     uuid REFERENCES pp_work_orders(id),
  national_company_id uuid REFERENCES pp_national_companies(id),
  property_address  text,
  amount            numeric(12,2) NOT NULL,
  reason            text NOT NULL,
  chargeback_date   date NOT NULL,
  dispute_status    text DEFAULT 'none'
    CHECK (dispute_status IN ('none','submitted','under_review','resolved_won','resolved_lost','denied')),
  dispute_submitted_at timestamptz,
  dispute_resolved_at  timestamptz,
  evidence_notes    text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

CREATE INDEX idx_pp_cb_company ON pp_chargebacks (company_id, chargeback_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_cb_national ON pp_chargebacks (national_company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_cb_dispute ON pp_chargebacks (dispute_status) WHERE deleted_at IS NULL AND dispute_status != 'none';

ALTER TABLE pp_chargebacks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pp_cb_select" ON pp_chargebacks
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

CREATE POLICY "pp_cb_insert" ON pp_chargebacks
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "pp_cb_update" ON pp_chargebacks
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('pp_chargebacks');
SELECT audit_trigger_fn('pp_chargebacks');

-- ============================================================================
-- PP WINTERIZATION RECORDS (company-scoped documentation)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pp_winterization_records (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  work_order_id     uuid REFERENCES pp_work_orders(id),
  property_id       uuid REFERENCES properties(id),
  record_type       text NOT NULL CHECK (record_type IN ('winterization','dewinterization')),
  heat_type         text CHECK (heat_type IN ('dry','wet_radiant','steam','electric','none')),
  has_well          boolean DEFAULT false,
  has_septic        boolean DEFAULT false,
  has_sprinkler     boolean DEFAULT false,
  pressure_test_start_psi numeric(5,1),
  pressure_test_end_psi   numeric(5,1),
  pressure_test_duration_min integer DEFAULT 30,
  pressure_test_passed boolean,
  antifreeze_gallons numeric(4,1),
  fixture_count     integer,
  checklist_data    jsonb DEFAULT '{}',
  completed_by      uuid REFERENCES auth.users(id),
  completed_at      timestamptz,
  certificate_url   text,
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

CREATE INDEX idx_pp_wint_company ON pp_winterization_records (company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_wint_property ON pp_winterization_records (property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_wint_wo ON pp_winterization_records (work_order_id) WHERE deleted_at IS NULL;

ALTER TABLE pp_winterization_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pp_wint_select" ON pp_winterization_records
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

CREATE POLICY "pp_wint_insert" ON pp_winterization_records
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "pp_wint_update" ON pp_winterization_records
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('pp_winterization_records');
SELECT audit_trigger_fn('pp_winterization_records');

-- ============================================================================
-- PP DEBRIS ESTIMATES (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pp_debris_estimates (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  work_order_id     uuid REFERENCES pp_work_orders(id),
  property_id       uuid REFERENCES properties(id),
  estimation_method text NOT NULL CHECK (estimation_method IN ('room_by_room','sqft_quick','manual')),
  rooms_data        jsonb DEFAULT '[]',
  property_sqft     integer,
  cleanout_level    text CHECK (cleanout_level IN ('broom_clean','normal','heavy','hoarder')),
  hoarding_level    integer CHECK (hoarding_level IS NULL OR hoarding_level BETWEEN 1 AND 5),
  total_cubic_yards numeric(8,1),
  estimated_weight_lbs numeric(10,0),
  recommended_dumpster_size integer,
  dumpster_pulls    integer DEFAULT 1,
  hud_rate_per_cy   numeric(8,2),
  estimated_revenue numeric(12,2),
  estimated_cost    numeric(12,2),
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

CREATE INDEX idx_pp_debris_company ON pp_debris_estimates (company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_debris_wo ON pp_debris_estimates (work_order_id) WHERE deleted_at IS NULL;

ALTER TABLE pp_debris_estimates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pp_debris_select" ON pp_debris_estimates
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

CREATE POLICY "pp_debris_insert" ON pp_debris_estimates
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "pp_debris_update" ON pp_debris_estimates
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('pp_debris_estimates');
SELECT audit_trigger_fn('pp_debris_estimates');

-- ============================================================================
-- PP UTILITY TRACKING (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pp_utility_tracking (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  property_id       uuid REFERENCES properties(id),
  utility_type      text NOT NULL CHECK (utility_type IN ('electric','gas','water','oil','propane')),
  status            text NOT NULL DEFAULT 'unknown'
    CHECK (status IN ('on','off','meter_pulled','winterized','unknown')),
  provider_name     text,
  account_number    text,
  contact_phone     text,
  last_checked      timestamptz,
  next_action       text,
  next_action_date  timestamptz,
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

CREATE INDEX idx_pp_util_company ON pp_utility_tracking (company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_util_property ON pp_utility_tracking (property_id) WHERE deleted_at IS NULL;

ALTER TABLE pp_utility_tracking ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pp_util_select" ON pp_utility_tracking
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

CREATE POLICY "pp_util_insert" ON pp_utility_tracking
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "pp_util_update" ON pp_utility_tracking
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('pp_utility_tracking');
SELECT audit_trigger_fn('pp_utility_tracking');

-- ============================================================================
-- PP VENDOR APPLICATIONS (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pp_vendor_applications (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES companies(id),
  national_company_id uuid NOT NULL REFERENCES pp_national_companies(id),
  status              text NOT NULL DEFAULT 'not_started'
    CHECK (status IN ('not_started','in_progress','submitted','approved','rejected')),
  applied_at          timestamptz,
  approved_at         timestamptz,
  rejected_at         timestamptz,
  checklist           jsonb DEFAULT '{}',
  portal_username     text,
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  deleted_at          timestamptz
);

CREATE INDEX idx_pp_vendor_app_company ON pp_vendor_applications (company_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_pp_vendor_app_unique ON pp_vendor_applications (company_id, national_company_id) WHERE deleted_at IS NULL;

ALTER TABLE pp_vendor_applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pp_vendor_app_select" ON pp_vendor_applications
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

CREATE POLICY "pp_vendor_app_insert" ON pp_vendor_applications
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "pp_vendor_app_update" ON pp_vendor_applications
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('pp_vendor_applications');
SELECT audit_trigger_fn('pp_vendor_applications');

-- ============================================================================
-- BOILER/FURNACE MODEL DATABASE (system-wide reference)
-- ============================================================================

CREATE TABLE IF NOT EXISTS boiler_furnace_models (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer    text NOT NULL,
  model_name      text NOT NULL,
  model_number    text,
  equipment_type  text NOT NULL CHECK (equipment_type IN ('boiler','furnace','heat_pump','water_heater')),
  fuel_type       text CHECK (fuel_type IN ('gas','oil','electric','propane','dual_fuel')),
  common_issues   jsonb DEFAULT '[]',
  error_codes     jsonb DEFAULT '{}',
  winterization_notes text,
  serial_decoder  jsonb DEFAULT '{}',
  parts_commonly_needed jsonb DEFAULT '[]',
  approximate_lifespan_years integer,
  is_discontinued boolean DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_bf_models_mfr ON boiler_furnace_models (manufacturer, model_name);
CREATE INDEX idx_bf_models_type ON boiler_furnace_models (equipment_type, fuel_type);

ALTER TABLE boiler_furnace_models ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bf_models_select" ON boiler_furnace_models
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "bf_models_system" ON boiler_furnace_models
  FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('boiler_furnace_models');

-- Seed major manufacturers
INSERT INTO boiler_furnace_models (manufacturer, model_name, equipment_type, fuel_type, approximate_lifespan_years) VALUES
-- Boilers
('Weil-McLain', 'CGa', 'boiler', 'gas', 20),
('Weil-McLain', 'ECO', 'boiler', 'gas', 25),
('Weil-McLain', 'WGO', 'boiler', 'oil', 20),
('Burnham', 'Series 2', 'boiler', 'gas', 20),
('Burnham', 'Holiday', 'boiler', 'oil', 20),
('Peerless', 'MI/MIH', 'boiler', 'gas', 25),
('Smith Cast Iron', 'Mills 28A', 'boiler', 'gas', 25),
('New Yorker', 'CL-Series', 'boiler', 'oil', 20),
('Crown', 'Bimini', 'boiler', 'gas', 25),
('Slant/Fin', 'Sentry', 'boiler', 'gas', 20),
('Buderus', 'G115', 'boiler', 'oil', 25),
('Navien', 'NCB', 'boiler', 'gas', 20),
('Rinnai', 'i-Series', 'boiler', 'gas', 20),
-- Furnaces
('Carrier', 'Infinity 98', 'furnace', 'gas', 18),
('Lennox', 'SL297NV', 'furnace', 'gas', 20),
('Trane', 'S9X2', 'furnace', 'gas', 18),
('Goodman', 'GMVM97', 'furnace', 'gas', 15),
('York', 'YP9C', 'furnace', 'gas', 18),
('Bryant', '987M', 'furnace', 'gas', 18),
('Amana', 'AMVM97', 'furnace', 'gas', 18),
('Rheem', 'R97V', 'furnace', 'gas', 18),
('Heil', 'G9MVE', 'furnace', 'gas', 15),
('Coleman', 'TM9X', 'furnace', 'gas', 15),
-- Water heaters
('Rheem', 'Performance Platinum', 'water_heater', 'gas', 12),
('AO Smith', 'ProLine', 'water_heater', 'gas', 12),
('Bradford White', 'RG2', 'water_heater', 'gas', 12),
('Rinnai', 'RU199', 'water_heater', 'gas', 20),
('Navien', 'NPE-A2', 'water_heater', 'gas', 20),
('Rheem', 'Performance', 'water_heater', 'electric', 10),
('AO Smith', 'Voltex', 'water_heater', 'electric', 12)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PP PRICING MATRICES (system-wide HUD/Fannie/VA rates by state)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pp_pricing_matrices (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  state_code      text NOT NULL,
  work_order_type text NOT NULL,
  pricing_source  text NOT NULL CHECK (pricing_source IN ('hud','fannie_mae','freddie_mac','va')),
  rate            numeric(10,2) NOT NULL,
  rate_unit       text NOT NULL DEFAULT 'flat' CHECK (rate_unit IN ('flat','per_cy','per_ui','per_sqft','per_hour')),
  conditions      text,
  effective_date  date NOT NULL DEFAULT CURRENT_DATE,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_pp_pricing_lookup ON pp_pricing_matrices (state_code, work_order_type, pricing_source);

ALTER TABLE pp_pricing_matrices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pp_pricing_select" ON pp_pricing_matrices
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "pp_pricing_system" ON pp_pricing_matrices
  FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('pp_pricing_matrices');

-- ============================================================================
-- PP STRIPPED PROPERTY ESTIMATES (repipe, rewire, HVAC, water heater)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pp_stripped_estimates (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  work_order_id     uuid REFERENCES pp_work_orders(id),
  property_id       uuid REFERENCES properties(id),
  estimate_type     text NOT NULL CHECK (estimate_type IN ('repipe','rewire','hvac_replace','water_heater')),
  input_data        jsonb NOT NULL DEFAULT '{}',
  materials_list    jsonb DEFAULT '[]',
  material_cost     numeric(12,2),
  labor_hours       numeric(6,1),
  labor_cost        numeric(12,2),
  total_estimate    numeric(12,2),
  hud_allowable     numeric(12,2),
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

CREATE INDEX idx_pp_stripped_company ON pp_stripped_estimates (company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_stripped_wo ON pp_stripped_estimates (work_order_id) WHERE deleted_at IS NULL;

ALTER TABLE pp_stripped_estimates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pp_stripped_select" ON pp_stripped_estimates
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

CREATE POLICY "pp_stripped_insert" ON pp_stripped_estimates
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "pp_stripped_update" ON pp_stripped_estimates
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('pp_stripped_estimates');
SELECT audit_trigger_fn('pp_stripped_estimates');
