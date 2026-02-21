-- ============================================================================
-- DEPTH30 — Recon-to-Estimate Pipeline
-- One Address → Complete Bid
-- ============================================================================
-- Connects property recon (DEPTH28) to the estimate engine (DEPTH29)
-- so a contractor can enter an address, select trade, get a complete estimate.

-- ── 1. Recon-to-estimate measurement mapping rules ──────────────────────────
-- Maps trade+measurement_type → estimate line item template with quantity formulas
CREATE TABLE IF NOT EXISTS recon_estimate_mappings (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    uuid REFERENCES companies(id),  -- NULL = system default
  trade         text NOT NULL,
  measurement_type text NOT NULL,         -- e.g. 'roof_area_sqft', 'ridge_length_ft', 'wall_area_sqft'
  line_description text NOT NULL,         -- e.g. 'Architectural shingles - remove & replace'
  material_category text,                 -- links to material_catalog category
  default_material_tier text DEFAULT 'standard',
  unit_code     text NOT NULL DEFAULT 'SF', -- EA, SF, LF, SQ, CY, etc.
  quantity_formula text NOT NULL,          -- formula string: 'measurement', 'measurement * 1.10', 'measurement / 100'
  waste_factor_pct numeric(5,2) DEFAULT 0,
  round_up_to   numeric(10,2),            -- round to purchasable units (e.g., 1 for sheets)
  labor_task_name text,                   -- links to labor_units.task_name for auto labor
  sort_order    int DEFAULT 0,
  is_active     boolean DEFAULT true,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now(),
  deleted_at    timestamptz
);

CREATE INDEX idx_rem_trade ON recon_estimate_mappings(trade) WHERE deleted_at IS NULL;
CREATE INDEX idx_rem_company ON recon_estimate_mappings(company_id) WHERE deleted_at IS NULL;

-- RLS
ALTER TABLE recon_estimate_mappings ENABLE ROW LEVEL SECURITY;

-- System defaults (company_id IS NULL) readable by all authenticated
CREATE POLICY "rem_select_system" ON recon_estimate_mappings
  FOR SELECT USING (
    company_id IS NULL
    OR company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

CREATE POLICY "rem_insert" ON recon_estimate_mappings
  FOR INSERT WITH CHECK (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

CREATE POLICY "rem_update" ON recon_estimate_mappings
  FOR UPDATE USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

CREATE POLICY "rem_delete" ON recon_estimate_mappings
  FOR DELETE USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

-- Audit trigger
CREATE TRIGGER trg_rem_updated
  BEFORE UPDATE ON recon_estimate_mappings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 2. Material recommendations based on property conditions ────────────────
CREATE TABLE IF NOT EXISTS recon_material_recommendations (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    uuid REFERENCES companies(id),  -- NULL = system default
  trade         text NOT NULL,
  condition_field text NOT NULL,          -- property field: 'flood_zone', 'wind_speed_mph', 'year_built', etc.
  condition_operator text NOT NULL,       -- 'eq', 'ne', 'gt', 'lt', 'gte', 'lte', 'in', 'contains'
  condition_value text NOT NULL,          -- the threshold value (e.g., '1978', 'A', '130')
  recommendation_text text NOT NULL,      -- human-readable: "Property in flood zone — suggest moisture-resistant materials"
  suggested_material_category text,       -- auto-suggest from material_catalog
  suggested_material_tier text,           -- suggest upgrade tier
  add_line_description text,             -- auto-add line item if condition met
  add_line_unit text,
  add_line_quantity_formula text,
  severity      text DEFAULT 'info',      -- info, warning, critical
  is_code_required boolean DEFAULT false, -- true = code mandate, not just suggestion
  sort_order    int DEFAULT 0,
  is_active     boolean DEFAULT true,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now(),
  deleted_at    timestamptz
);

CREATE INDEX idx_rmr_trade ON recon_material_recommendations(trade) WHERE deleted_at IS NULL;
CREATE INDEX idx_rmr_company ON recon_material_recommendations(company_id) WHERE deleted_at IS NULL;

-- RLS
ALTER TABLE recon_material_recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rmr_select_system" ON recon_material_recommendations
  FOR SELECT USING (
    company_id IS NULL
    OR company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

CREATE POLICY "rmr_insert" ON recon_material_recommendations
  FOR INSERT WITH CHECK (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

CREATE POLICY "rmr_update" ON recon_material_recommendations
  FOR UPDATE USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

CREATE POLICY "rmr_delete" ON recon_material_recommendations
  FOR DELETE USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

CREATE TRIGGER trg_rmr_updated
  BEFORE UPDATE ON recon_material_recommendations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 3. Estimate bundles for multi-trade proposals ───────────────────────────
CREATE TABLE IF NOT EXISTS estimate_bundles (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    uuid NOT NULL REFERENCES companies(id),
  customer_id   uuid REFERENCES customers(id),
  property_address text,
  scan_id       uuid REFERENCES property_scans(id),
  title         text,
  bundle_discount_pct numeric(5,2) DEFAULT 0,
  combined_total numeric(12,2) DEFAULT 0,
  discounted_total numeric(12,2) DEFAULT 0,
  notes         text,
  dependency_warnings jsonb DEFAULT '[]'::jsonb,  -- cross-trade warnings
  created_by    uuid REFERENCES auth.users(id),
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now(),
  deleted_at    timestamptz
);

CREATE INDEX idx_eb_company ON estimate_bundles(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_eb_customer ON estimate_bundles(customer_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_eb_scan ON estimate_bundles(scan_id) WHERE deleted_at IS NULL;

ALTER TABLE estimate_bundles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "eb_select" ON estimate_bundles
  FOR SELECT USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "eb_insert" ON estimate_bundles
  FOR INSERT WITH CHECK (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "eb_update" ON estimate_bundles
  FOR UPDATE USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "eb_delete" ON estimate_bundles
  FOR DELETE USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE TRIGGER trg_eb_updated
  BEFORE UPDATE ON estimate_bundles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 4. Add recon pipeline columns to estimates table ────────────────────────
-- Using expand-contract: add nullable columns, no breaking changes
ALTER TABLE estimates
  ADD COLUMN IF NOT EXISTS source_scan_id uuid REFERENCES property_scans(id),
  ADD COLUMN IF NOT EXISTS bundle_id uuid REFERENCES estimate_bundles(id),
  ADD COLUMN IF NOT EXISTS confidence_level text DEFAULT 'manual',  -- manual, low, medium, high
  ADD COLUMN IF NOT EXISTS confidence_detail jsonb,                 -- per-measurement confidence breakdown
  ADD COLUMN IF NOT EXISTS is_quick_bid boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_field_verified boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS field_verified_at timestamptz,
  ADD COLUMN IF NOT EXISTS field_verified_by uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS trade text,
  ADD COLUMN IF NOT EXISTS recon_measurements jsonb;                -- snapshot of recon data used

CREATE INDEX IF NOT EXISTS idx_est_source_scan ON estimates(source_scan_id) WHERE source_scan_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_est_bundle ON estimates(bundle_id) WHERE bundle_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_est_trade ON estimates(trade) WHERE trade IS NOT NULL;

-- ── 5. Seed system-default measurement mappings per trade ───────────────────

-- ROOFING mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('roofing', 'roof_area_squares', 'Shingles — remove & replace', 'shingles', 'SQ', 'measurement', 10, 1, 1),
  ('roofing', 'roof_area_sqft', 'Underlayment (synthetic)', 'underlayment', 'SF', 'measurement', 5, NULL, 2),
  ('roofing', 'ridge_length_ft', 'Ridge cap', 'ridge_cap', 'LF', 'measurement', 5, NULL, 3),
  ('roofing', 'hip_length_ft', 'Hip cap', 'hip_cap', 'LF', 'measurement', 5, NULL, 4),
  ('roofing', 'valley_length_ft', 'Valley metal / ice & water shield', 'valley_materials', 'LF', 'measurement', 10, NULL, 5),
  ('roofing', 'eave_length_ft', 'Drip edge', 'drip_edge', 'LF', 'measurement', 5, NULL, 6),
  ('roofing', 'eave_length_ft', 'Ice & water shield at eaves', 'ice_water_shield', 'LF', 'measurement * 3', 0, NULL, 7),
  ('roofing', 'rake_length_ft', 'Rake edge trim', 'rake_trim', 'LF', 'measurement', 5, NULL, 8),
  ('roofing', 'penetration_count', 'Pipe boot / flashing', 'pipe_boots', 'EA', 'measurement', 0, 1, 9),
  ('roofing', 'roof_area_squares', 'Starter strip', 'starter_strip', 'LF', 'measurement * 30', 5, NULL, 10);

-- SIDING mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('siding', 'total_siding_area_sqft', 'Siding — remove & replace', 'siding', 'SF', 'measurement', 10, NULL, 1),
  ('siding', 'trim_linear_ft', 'Trim / J-channel', 'trim', 'LF', 'measurement', 10, NULL, 2),
  ('siding', 'fascia_linear_ft', 'Fascia board', 'fascia', 'LF', 'measurement', 5, NULL, 3),
  ('siding', 'soffit_sqft', 'Soffit panels', 'soffit', 'SF', 'measurement', 5, NULL, 4),
  ('siding', 'total_siding_area_sqft', 'House wrap / moisture barrier', 'housewrap', 'SF', 'measurement', 5, NULL, 5);

-- GUTTERS mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('gutters', 'eave_length_ft', 'Seamless gutters — 5" K-style', 'gutters', 'LF', 'measurement', 5, NULL, 1),
  ('gutters', 'stories', 'Downspouts', 'downspouts', 'EA', 'measurement * 2', 0, 1, 2),
  ('gutters', 'eave_length_ft', 'Gutter guards', 'gutter_guards', 'LF', 'measurement', 0, NULL, 3);

-- PAINTING (exterior) mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('painting', 'total_siding_area_sqft', 'Exterior paint — 2 coats', 'exterior_paint', 'SF', 'measurement', 0, NULL, 1),
  ('painting', 'trim_linear_ft', 'Trim paint', 'trim_paint', 'LF', 'measurement', 0, NULL, 2),
  ('painting', 'fascia_linear_ft', 'Fascia paint', 'trim_paint', 'LF', 'measurement', 0, NULL, 3),
  ('painting', 'total_siding_area_sqft', 'Pressure wash / surface prep', 'surface_prep', 'SF', 'measurement', 0, NULL, 4);

-- FENCING mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('fencing', 'boundary_length_ft', 'Fence — remove & replace', 'fencing', 'LF', 'measurement', 5, NULL, 1),
  ('fencing', 'boundary_length_ft', 'Fence posts (8ft OC)', 'fence_posts', 'EA', 'measurement / 8', 0, 1, 2),
  ('fencing', 'gate_count', 'Gate(s)', 'gates', 'EA', 'measurement', 0, 1, 3);

-- CONCRETE mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('concrete', 'driveway_sqft', 'Concrete — remove & replace (4" slab)', 'concrete', 'SF', 'measurement', 5, NULL, 1),
  ('concrete', 'driveway_sqft', 'Concrete (cubic yards)', 'concrete_cy', 'CY', 'measurement * 0.33 / 27', 10, 0.5, 2),
  ('concrete', 'driveway_sqft', 'Gravel base (4" depth)', 'gravel', 'CY', 'measurement * 0.33 / 27', 10, 0.5, 3),
  ('concrete', 'sidewalk_sqft', 'Sidewalk pour (4" slab)', 'concrete', 'SF', 'measurement', 5, NULL, 4);

-- INSULATION mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('insulation', 'attic_sqft', 'Attic insulation — blown-in', 'blown_insulation', 'SF', 'measurement', 5, NULL, 1),
  ('insulation', 'total_wall_area_sqft', 'Wall insulation — batt R-13', 'batt_insulation', 'SF', 'measurement', 10, NULL, 2);

-- WINDOWS/DOORS mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('windowsDoors', 'window_count', 'Window — remove & replace', 'windows', 'EA', 'measurement', 0, 1, 1),
  ('windowsDoors', 'door_count', 'Exterior door — remove & replace', 'exterior_doors', 'EA', 'measurement', 0, 1, 2);

-- HVAC mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('hvac', 'living_sqft', 'HVAC system (tonnage from sqft)', 'hvac_systems', 'EA', 'measurement / 600', 0, 0.5, 1),
  ('hvac', 'living_sqft', 'Ductwork', 'ductwork', 'SF', 'measurement', 10, NULL, 2);

-- ELECTRICAL mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('electrical', 'living_sqft', 'Panel upgrade (200A)', 'electrical_panels', 'EA', '1', 0, 1, 1),
  ('electrical', 'living_sqft', 'Outlets (per code: 1 per 12 LF wall)', 'outlets', 'EA', 'measurement / 150', 0, 1, 2),
  ('electrical', 'living_sqft', 'Lighting fixtures', 'lighting', 'EA', 'measurement / 100', 0, 1, 3);

-- PLUMBING mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('plumbing', 'bathroom_count', 'Bathroom rough-in', 'plumbing_rough', 'EA', 'measurement', 0, 1, 1),
  ('plumbing', 'kitchen_count', 'Kitchen plumbing rough-in', 'plumbing_rough', 'EA', 'measurement', 0, 1, 2),
  ('plumbing', 'living_sqft', 'Water heater replacement', 'water_heaters', 'EA', '1', 0, 1, 3);

-- FLOORING mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('flooring', 'room_sqft', 'Flooring — remove & replace', 'flooring', 'SF', 'measurement', 10, NULL, 1),
  ('flooring', 'room_sqft', 'Underlayment / subfloor prep', 'floor_underlayment', 'SF', 'measurement', 5, NULL, 2),
  ('flooring', 'room_perimeter_ft', 'Baseboard / trim', 'baseboards', 'LF', 'measurement', 5, NULL, 3);

-- LANDSCAPING mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('landscaping', 'lot_sqft', 'Sod / lawn installation', 'sod', 'SF', 'measurement * 0.6', 5, NULL, 1),
  ('landscaping', 'lot_sqft', 'Mulch (3" depth)', 'mulch', 'CY', 'measurement * 0.3 * 0.25 / 27', 10, 1, 2),
  ('landscaping', 'tree_count', 'Tree removal', 'tree_service', 'EA', 'measurement', 0, 1, 3);

-- SOLAR mappings
INSERT INTO recon_estimate_mappings (trade, measurement_type, line_description, material_category, unit_code, quantity_formula, waste_factor_pct, round_up_to, sort_order)
VALUES
  ('solar', 'usable_roof_sqft', 'Solar panels (400W)', 'solar_panels', 'EA', 'measurement / 18', 0, 1, 1),
  ('solar', 'usable_roof_sqft', 'Racking / mounting system', 'solar_racking', 'SF', 'measurement', 0, NULL, 2),
  ('solar', 'panel_count', 'Inverter (micro or string)', 'inverters', 'EA', '1', 0, 1, 3);

-- ── 6. Seed material recommendations based on property conditions ───────────

INSERT INTO recon_material_recommendations (trade, condition_field, condition_operator, condition_value, recommendation_text, suggested_material_tier, severity, is_code_required, sort_order)
VALUES
  -- Hurricane / high wind
  ('roofing', 'wind_speed_mph', 'gte', '130', 'High wind zone (130+ mph) — use impact-rated shingles with 6-nail pattern', 'premium', 'critical', true, 1),
  ('windowsDoors', 'wind_speed_mph', 'gte', '130', 'Hurricane zone — suggest impact-rated windows', 'premium', 'critical', true, 2),

  -- Flood zone
  ('general', 'flood_zone', 'in', 'A,AE,AH,AO,V,VE', 'Property in FEMA flood zone — use moisture-resistant materials, elevate mechanicals', 'premium', 'critical', true, 3),
  ('plumbing', 'flood_zone', 'in', 'A,AE,AH,AO,V,VE', 'Flood zone — recommend sump pump installation and backflow prevention', NULL, 'warning', false, 4),

  -- Lead paint (pre-1978)
  ('painting', 'year_built', 'lt', '1978', 'Property built before 1978 — lead paint likely. EPA RRP certification required. Add encapsulation/abatement scope', NULL, 'critical', true, 5),
  ('general', 'year_built', 'lt', '1978', 'Pre-1978 construction — flag for lead paint and asbestos assessment before demolition', NULL, 'critical', true, 6),

  -- Aluminum wiring
  ('electrical', 'wiring_type', 'eq', 'aluminum', 'Aluminum wiring detected — suggest COPALUM connectors or full re-wire to copper', 'premium', 'critical', true, 7),

  -- Wildfire zone
  ('siding', 'wildfire_risk_score', 'gte', '7', 'High wildfire risk — use fire-resistant siding (fiber cement, metal, stone)', 'premium', 'critical', true, 8),
  ('roofing', 'wildfire_risk_score', 'gte', '7', 'Wildfire zone — Class A fire-rated roofing required. Use ember-resistant ridge vents', 'premium', 'critical', true, 9),

  -- Cold climate / insulation
  ('insulation', 'climate_zone', 'in', '5,6,7,8', 'Climate zone 5+ — suggest R-49 attic insulation and R-20 wall insulation minimum', 'premium', 'warning', true, 10),
  ('windowsDoors', 'climate_zone', 'in', '6,7,8', 'Cold climate — suggest triple-pane windows for energy efficiency', 'premium', 'warning', false, 11),

  -- High wind (non-hurricane)
  ('roofing', 'wind_speed_mph', 'gte', '110', 'High wind zone (110+ mph) — upgrade to wind-rated shingles above code minimum', 'premium', 'warning', false, 12),

  -- Seismic zone
  ('general', 'seismic_zone', 'in', 'D,E', 'High seismic zone — verify structural connections, hold-downs, and shear walls per code', NULL, 'warning', true, 13),

  -- Expansive soil
  ('concrete', 'expansive_soil_risk', 'eq', 'high', 'Expansive soil risk — use post-tension slab or pier & beam foundation. Standard slab may crack', 'premium', 'warning', true, 14),

  -- Snow load
  ('roofing', 'snow_load_psf', 'gte', '50', 'Heavy snow load area (50+ psf) — verify roof structural capacity. Consider snow guards', NULL, 'warning', true, 15);

-- ── 7. Cross-trade dependency seed data ─────────────────────────────────────
-- Stored in estimate_bundles.dependency_warnings as JSONB,
-- but let's create a reference table for reusable cross-trade warnings

CREATE TABLE IF NOT EXISTS cross_trade_dependencies (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_trade text NOT NULL,
  dependent_trade text NOT NULL,
  dependency_type text NOT NULL DEFAULT 'before',  -- before, after, concurrent
  warning_text  text NOT NULL,
  severity      text DEFAULT 'info',  -- info, warning, critical
  sort_order    int DEFAULT 0,
  created_at    timestamptz DEFAULT now()
);

INSERT INTO cross_trade_dependencies (primary_trade, dependent_trade, dependency_type, warning_text, severity, sort_order)
VALUES
  ('roofing', 'painting', 'before', 'Complete roof before exterior paint — prevents paint damage from roofing debris', 'warning', 1),
  ('roofing', 'solar', 'before', 'Complete roof replacement before solar panel installation', 'critical', 2),
  ('roofing', 'gutters', 'before', 'Install gutters after roofing to ensure proper drip edge alignment', 'warning', 3),
  ('electrical', 'hvac', 'before', 'Electrical panel upgrade may be required before HVAC heat pump installation', 'warning', 4),
  ('electrical', 'solar', 'before', 'Panel upgrade required before solar interconnection', 'critical', 5),
  ('plumbing', 'flooring', 'before', 'Complete plumbing rough-in before flooring installation', 'critical', 6),
  ('electrical', 'flooring', 'before', 'Complete electrical rough-in before flooring in renovation', 'warning', 7),
  ('insulation', 'drywall', 'before', 'Install insulation before drywall', 'critical', 8),
  ('drywall', 'painting', 'before', 'Complete drywall before interior painting', 'critical', 9),
  ('framing', 'electrical', 'before', 'Complete framing before electrical rough-in', 'critical', 10),
  ('framing', 'plumbing', 'before', 'Complete framing before plumbing rough-in', 'critical', 11),
  ('framing', 'insulation', 'before', 'Complete framing before insulation', 'critical', 12),
  ('demolition', 'framing', 'before', 'Complete demolition before new framing', 'critical', 13),
  ('concrete', 'fencing', 'before', 'Pour fence post footings before fence panel installation', 'warning', 14),
  ('siding', 'painting', 'before', 'Complete siding before trim paint if new siding is primed', 'info', 15);

ALTER TABLE cross_trade_dependencies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ctd_select" ON cross_trade_dependencies
  FOR SELECT USING (true);  -- read-only reference data, visible to all authenticated

-- Done
