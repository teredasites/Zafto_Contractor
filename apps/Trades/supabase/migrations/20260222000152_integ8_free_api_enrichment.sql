-- ============================================================
-- INTEG8: Free API Enrichment
-- Migration 000152
--
-- Wire free government/public APIs ($0/mo) into existing features.
-- 250+ APIs cataloged in S132 research — this sprint wires core ones.
--
-- New tables:
--   property_fema_data     (FEMA flood zones + disaster history)
--   property_epa_data      (EPA ECHO environmental compliance)
--   energy_star_products   (ENERGY STAR appliance certifications)
--   rebate_incentives      (Rewiring America + state/utility rebates)
--   census_tract_data      (Census ACS demographic data)
--   ppi_material_indices   (BLS PPI construction material indices)
--
-- Alters:
--   estimate_pricing       (add ppi_adjusted_cost column)
-- ============================================================

-- ============================================================
-- 1. PROPERTY FEMA DATA (flood zones + disaster history)
--    Sources: FEMA NFHL API (flood zones), OpenFEMA API (disasters)
--    Both free, no API key needed
-- ============================================================

CREATE TABLE IF NOT EXISTS property_fema_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Location
  address TEXT,
  latitude NUMERIC(10,7),
  longitude NUMERIC(10,7),
  zip TEXT,
  county_fips TEXT,         -- 5-digit FIPS code
  state_fips TEXT,          -- 2-digit FIPS code

  -- Flood zone data (FEMA NFHL)
  flood_zone TEXT,          -- 'A', 'AE', 'V', 'X', etc.
  flood_zone_description TEXT,
  base_flood_elevation_ft NUMERIC(8,2),
  is_special_flood_hazard BOOLEAN NOT NULL DEFAULT false,
  flood_insurance_required BOOLEAN NOT NULL DEFAULT false,
  panel_number TEXT,
  effective_date DATE,
  community_number TEXT,

  -- Disaster history (OpenFEMA)
  disaster_count INTEGER NOT NULL DEFAULT 0,
  recent_disasters JSONB DEFAULT '[]'::jsonb,
  -- [{disaster_number, title, type, declaration_date, end_date, program_types}]
  last_disaster_date DATE,
  disaster_types JSONB DEFAULT '[]'::jsonb, -- ['Hurricane', 'Flood', 'Fire', 'Tornado']

  -- Risk scoring
  flood_risk_score INTEGER CHECK (flood_risk_score IS NULL OR (flood_risk_score BETWEEN 0 AND 100)),
  disaster_risk_score INTEGER CHECK (disaster_risk_score IS NULL OR (disaster_risk_score BETWEEN 0 AND 100)),
  combined_risk_score INTEGER CHECK (combined_risk_score IS NULL OR (combined_risk_score BETWEEN 0 AND 100)),

  -- Cache management
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '30 days'),
  raw_nfhl_response JSONB,
  raw_openfema_response JSONB,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_pfd_zip ON property_fema_data(zip);
CREATE INDEX idx_pfd_county ON property_fema_data(county_fips);
CREATE INDEX idx_pfd_coords ON property_fema_data(latitude, longitude);
CREATE INDEX idx_pfd_flood_zone ON property_fema_data(flood_zone) WHERE flood_zone IS NOT NULL;
CREATE INDEX idx_pfd_sfha ON property_fema_data(is_special_flood_hazard) WHERE is_special_flood_hazard = true;
CREATE INDEX idx_pfd_expires ON property_fema_data(expires_at);

-- Public reference data — no company_id
ALTER TABLE property_fema_data ENABLE ROW LEVEL SECURITY;
CREATE POLICY pfd_select ON property_fema_data FOR SELECT TO authenticated USING (true);
CREATE POLICY pfd_service ON property_fema_data FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('property_fema_data');


-- ============================================================
-- 2. PROPERTY EPA DATA (environmental compliance)
--    Source: EPA ECHO API — free, no key needed
--    Facility compliance data within radius of property
-- ============================================================

CREATE TABLE IF NOT EXISTS property_epa_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Location center
  latitude NUMERIC(10,7) NOT NULL,
  longitude NUMERIC(10,7) NOT NULL,
  search_radius_miles NUMERIC(5,2) NOT NULL DEFAULT 1.0,
  zip TEXT,

  -- Nearby facilities
  facility_count INTEGER NOT NULL DEFAULT 0,
  facilities JSONB DEFAULT '[]'::jsonb,
  -- [{registry_id, name, address, lat, lng, distance_miles,
  --   compliance_status, violation_count, last_inspection, programs[]}]

  -- Risk flags
  has_superfund_sites BOOLEAN NOT NULL DEFAULT false,
  superfund_site_count INTEGER NOT NULL DEFAULT 0,
  has_active_violations BOOLEAN NOT NULL DEFAULT false,
  has_air_quality_issues BOOLEAN NOT NULL DEFAULT false,
  has_water_quality_issues BOOLEAN NOT NULL DEFAULT false,

  -- Lead/Asbestos context (relevant for restoration)
  lead_risk_level TEXT CHECK (lead_risk_level IS NULL OR lead_risk_level IN ('low', 'moderate', 'high')),
  asbestos_risk_level TEXT CHECK (asbestos_risk_level IS NULL OR asbestos_risk_level IN ('low', 'moderate', 'high')),

  -- Overall environmental risk
  environmental_risk_score INTEGER CHECK (environmental_risk_score IS NULL OR (environmental_risk_score BETWEEN 0 AND 100)),

  -- Cache
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '90 days'),
  raw_echo_response JSONB,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ped_coords ON property_epa_data(latitude, longitude);
CREATE INDEX idx_ped_zip ON property_epa_data(zip);
CREATE INDEX idx_ped_risk ON property_epa_data(environmental_risk_score) WHERE environmental_risk_score IS NOT NULL;
CREATE INDEX idx_ped_expires ON property_epa_data(expires_at);

ALTER TABLE property_epa_data ENABLE ROW LEVEL SECURITY;
CREATE POLICY ped_select ON property_epa_data FOR SELECT TO authenticated USING (true);
CREATE POLICY ped_service ON property_epa_data FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('property_epa_data');


-- ============================================================
-- 3. ENERGY STAR PRODUCTS (certified appliance data)
--    Source: ENERGY STAR Product API — free
--    Populated via EF (monthly sync or on-demand)
-- ============================================================

CREATE TABLE IF NOT EXISTS energy_star_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Product info
  energy_star_id TEXT UNIQUE,
  product_category TEXT NOT NULL,  -- 'Central Air Conditioners and Heat Pumps', 'Water Heaters', etc.
  brand TEXT NOT NULL,
  model_name TEXT,
  model_number TEXT,

  -- Specs
  specs JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- {seer, hspf, eer, energy_factor, gallons, btu, watts, etc.}

  -- Efficiency
  efficiency_rating NUMERIC(8,2),
  efficiency_unit TEXT,  -- 'SEER2', 'EF', 'COP'
  annual_energy_cost NUMERIC(8,2),
  annual_energy_savings_pct NUMERIC(5,2),

  -- Certifications
  is_most_efficient BOOLEAN NOT NULL DEFAULT false,
  certification_date DATE,

  -- Rebate eligibility
  is_rebate_eligible BOOLEAN NOT NULL DEFAULT false,
  rebate_programs JSONB DEFAULT '[]'::jsonb,

  -- Cache
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '90 days'),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_esp_category ON energy_star_products(product_category);
CREATE INDEX idx_esp_brand ON energy_star_products(brand);
CREATE INDEX idx_esp_model ON energy_star_products(model_number) WHERE model_number IS NOT NULL;
CREATE INDEX idx_esp_most_efficient ON energy_star_products(product_category, is_most_efficient) WHERE is_most_efficient = true;
CREATE INDEX idx_esp_rebate ON energy_star_products(is_rebate_eligible) WHERE is_rebate_eligible = true;

ALTER TABLE energy_star_products ENABLE ROW LEVEL SECURITY;
CREATE POLICY esp_select ON energy_star_products FOR SELECT TO authenticated USING (true);
CREATE POLICY esp_service ON energy_star_products FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('energy_star_products');


-- ============================================================
-- 4. REBATE INCENTIVES (Rewiring America + state/utility)
--    Source: Rewiring America API — free
--    IRA/state/utility rebates by ZIP for electrification
-- ============================================================

CREATE TABLE IF NOT EXISTS rebate_incentives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Geographic scope
  zip TEXT,
  state TEXT,
  utility_name TEXT,
  coverage_type TEXT NOT NULL DEFAULT 'federal'
    CHECK (coverage_type IN ('federal', 'state', 'utility', 'local', 'manufacturer')),

  -- Rebate info
  program_name TEXT NOT NULL,
  program_url TEXT,
  description TEXT,
  eligible_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- ['heat_pump', 'solar', 'ev_charger', 'induction_range', 'insulation', 'water_heater']

  -- Financial
  rebate_type TEXT NOT NULL DEFAULT 'fixed'
    CHECK (rebate_type IN ('fixed', 'percentage', 'tax_credit', 'loan', 'mixed')),
  max_rebate_amount NUMERIC(10,2),
  rebate_percentage NUMERIC(5,2),
  income_qualified BOOLEAN NOT NULL DEFAULT false,
  income_limit TEXT,

  -- Dates
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT true,

  -- Source
  source TEXT NOT NULL DEFAULT 'rewiring_america'
    CHECK (source IN ('rewiring_america', 'dsire', 'utility_direct', 'state_program', 'manual')),

  -- Cache
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '30 days'),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ri_zip ON rebate_incentives(zip);
CREATE INDEX idx_ri_state ON rebate_incentives(state);
CREATE INDEX idx_ri_coverage ON rebate_incentives(coverage_type);
CREATE INDEX idx_ri_active ON rebate_incentives(is_active) WHERE is_active = true;
CREATE INDEX idx_ri_items ON rebate_incentives USING gin(eligible_items);

ALTER TABLE rebate_incentives ENABLE ROW LEVEL SECURITY;
CREATE POLICY ri_select ON rebate_incentives FOR SELECT TO authenticated USING (true);
CREATE POLICY ri_service ON rebate_incentives FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('rebate_incentives');


-- ============================================================
-- 5. CENSUS TRACT DATA (ACS demographic context)
--    Source: Census Bureau ACS API — free (needs key)
--    Refreshed annually. Used by CMA/FLIP for neighborhood analysis.
-- ============================================================

CREATE TABLE IF NOT EXISTS census_tract_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Geography
  tract_id TEXT NOT NULL,       -- 11-digit tract FIPS
  county_fips TEXT NOT NULL,    -- 5-digit county FIPS
  state_fips TEXT NOT NULL,     -- 2-digit state FIPS
  state_name TEXT,
  county_name TEXT,

  -- ACS year
  acs_year INTEGER NOT NULL DEFAULT 2023,

  -- Demographics
  total_population INTEGER,
  total_households INTEGER,
  median_household_income NUMERIC(10,2),
  median_home_value NUMERIC(12,2),
  homeownership_rate NUMERIC(5,2),
  vacancy_rate NUMERIC(5,2),
  median_age NUMERIC(5,1),

  -- Housing
  total_housing_units INTEGER,
  owner_occupied INTEGER,
  renter_occupied INTEGER,
  median_year_built INTEGER,
  median_rooms NUMERIC(4,1),
  median_gross_rent NUMERIC(8,2),

  -- Education/Employment
  college_degree_pct NUMERIC(5,2),
  unemployment_rate NUMERIC(5,2),
  poverty_rate NUMERIC(5,2),

  -- Derived scores
  affluence_score INTEGER CHECK (affluence_score IS NULL OR (affluence_score BETWEEN 0 AND 100)),
  investment_score INTEGER CHECK (investment_score IS NULL OR (investment_score BETWEEN 0 AND 100)),

  -- Cache
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '365 days'),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_ctd_tract_year ON census_tract_data(tract_id, acs_year);
CREATE INDEX idx_ctd_county ON census_tract_data(county_fips);
CREATE INDEX idx_ctd_state ON census_tract_data(state_fips);
CREATE INDEX idx_ctd_income ON census_tract_data(median_household_income) WHERE median_household_income IS NOT NULL;
CREATE INDEX idx_ctd_home_value ON census_tract_data(median_home_value) WHERE median_home_value IS NOT NULL;

ALTER TABLE census_tract_data ENABLE ROW LEVEL SECURITY;
CREATE POLICY ctd_select ON census_tract_data FOR SELECT TO authenticated USING (true);
CREATE POLICY ctd_service ON census_tract_data FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('census_tract_data');


-- ============================================================
-- 6. PPI MATERIAL INDICES (BLS Producer Price Index)
--    Source: BLS API v2 — free (500 req/day with key)
--    Monthly construction material price indices
-- ============================================================

CREATE TABLE IF NOT EXISTS ppi_material_indices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- BLS series identification
  series_id TEXT NOT NULL,        -- e.g. 'WPU0811', 'WPU133'
  series_title TEXT NOT NULL,     -- 'Lumber and wood products'
  material_category TEXT NOT NULL, -- 'lumber', 'copper', 'steel', 'concrete', etc.

  -- Index values
  period_year INTEGER NOT NULL,
  period_month INTEGER NOT NULL CHECK (period_month BETWEEN 1 AND 12),
  index_value NUMERIC(10,3) NOT NULL,
  percent_change_month NUMERIC(6,2),   -- month-over-month % change
  percent_change_year NUMERIC(6,2),    -- year-over-year % change

  -- Derived pricing adjustment factor
  -- Base: index_value / base_index_value (e.g., Jan 2020 = 100)
  base_period_year INTEGER DEFAULT 2020,
  base_period_month INTEGER DEFAULT 1,
  base_index_value NUMERIC(10,3),
  adjustment_factor NUMERIC(8,4) GENERATED ALWAYS AS (
    CASE WHEN base_index_value > 0 THEN index_value / base_index_value ELSE 1.0 END
  ) STORED,

  -- Source
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  raw_bls_response JSONB,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_pmi_series_period ON ppi_material_indices(series_id, period_year, period_month);
CREATE INDEX idx_pmi_category ON ppi_material_indices(material_category);
CREATE INDEX idx_pmi_period ON ppi_material_indices(period_year, period_month);

ALTER TABLE ppi_material_indices ENABLE ROW LEVEL SECURITY;
CREATE POLICY pmi_select ON ppi_material_indices FOR SELECT TO authenticated USING (true);
CREATE POLICY pmi_service ON ppi_material_indices FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('ppi_material_indices');


-- ============================================================
-- 7. ALTER estimate_pricing — add PPI adjustment column
--    Allows price book entries to be auto-adjusted by PPI data
-- ============================================================

ALTER TABLE estimate_pricing
  ADD COLUMN IF NOT EXISTS ppi_series_id TEXT,
  ADD COLUMN IF NOT EXISTS ppi_adjusted_cost NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS ppi_adjustment_factor NUMERIC(8,4),
  ADD COLUMN IF NOT EXISTS ppi_last_updated TIMESTAMPTZ;


-- ============================================================
-- 8. SEED: BLS PPI series IDs for construction materials
-- ============================================================

INSERT INTO ppi_material_indices (series_id, series_title, material_category, period_year, period_month, index_value, base_index_value) VALUES
  ('WPU0811', 'Lumber', 'lumber', 2026, 1, 100.0, 100.0),
  ('WPU1017', 'Steel mill products', 'steel', 2026, 1, 100.0, 100.0),
  ('WPU1025', 'Copper and copper alloy mill shapes', 'copper', 2026, 1, 100.0, 100.0),
  ('WPU133', 'Concrete ingredients', 'concrete', 2026, 1, 100.0, 100.0),
  ('WPU1392', 'Gypsum products', 'drywall', 2026, 1, 100.0, 100.0),
  ('WPU0723', 'Plastic construction products', 'plastic_pipe', 2026, 1, 100.0, 100.0),
  ('WPU1331', 'Flat glass', 'glass', 2026, 1, 100.0, 100.0),
  ('WPU0531', 'Asphalt roofing and siding', 'roofing', 2026, 1, 100.0, 100.0),
  ('WPU0813', 'Millwork', 'millwork', 2026, 1, 100.0, 100.0),
  ('WPU0721', 'Plastic pipe', 'pvc_pipe', 2026, 1, 100.0, 100.0),
  ('WPU1361', 'Insulation materials', 'insulation', 2026, 1, 100.0, 100.0),
  ('WPU1541', 'Paints and allied products', 'paint', 2026, 1, 100.0, 100.0)
ON CONFLICT (series_id, period_year, period_month) DO NOTHING;
