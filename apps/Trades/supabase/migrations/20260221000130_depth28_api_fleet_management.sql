-- DEPTH28 Part E: API Fleet Management & Health Monitoring
-- API registry, health events, health reports, usage tracking
-- Foundation for all external API calls across the platform

-- ============================================================================
-- TABLE: API_REGISTRY — master registry of all external APIs
-- ============================================================================

CREATE TABLE api_registry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,                     -- e.g., 'google_solar', 'fema_nfhl'
  display_name TEXT NOT NULL,                    -- e.g., 'Google Solar API'
  category TEXT NOT NULL DEFAULT 'property',     -- property, weather, government, financial, mapping
  base_url TEXT NOT NULL,
  auth_type TEXT NOT NULL DEFAULT 'none'
    CHECK (auth_type IN ('none', 'api_key', 'oauth', 'bearer')),
  key_env_var TEXT,                              -- Supabase secret name, null if no key needed
  -- Rate limits
  rate_limit_per_minute INTEGER,
  rate_limit_per_day INTEGER,
  rate_limit_per_month INTEGER,
  free_tier_limit INTEGER,                       -- monthly free tier cap
  -- Usage tracking
  current_month_usage INTEGER DEFAULT 0,
  usage_reset_at TIMESTAMPTZ,                    -- when counter was last reset
  -- Health status
  status TEXT DEFAULT 'unknown'
    CHECK (status IN ('healthy', 'degraded', 'down', 'over_limit', 'key_invalid', 'unknown')),
  last_check_at TIMESTAMPTZ,
  last_success_at TIMESTAMPTZ,
  last_error_at TIMESTAMPTZ,
  last_error_message TEXT,
  avg_response_ms NUMERIC(8,2),                  -- rolling 24h average
  uptime_percent_30d NUMERIC(5,2) DEFAULT 100,   -- 0-100
  -- Probe config
  probe_endpoint TEXT,                           -- lightweight endpoint to test
  probe_method TEXT DEFAULT 'GET',
  -- Docs
  docs_url TEXT,
  notes TEXT,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TABLE: API_HEALTH_EVENTS — status change log
-- ============================================================================

CREATE TABLE api_health_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_id UUID NOT NULL REFERENCES api_registry(id) ON DELETE CASCADE,
  old_status TEXT,
  new_status TEXT NOT NULL,
  response_ms NUMERIC(8,2),
  status_code INTEGER,
  error_message TEXT,
  checked_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TABLE: API_HEALTH_REPORTS — monthly summary reports
-- ============================================================================

CREATE TABLE api_health_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_month TEXT NOT NULL,                    -- '2026-02'
  total_calls INTEGER DEFAULT 0,
  avg_uptime_pct NUMERIC(5,2) DEFAULT 100,
  apis_with_incidents INTEGER DEFAULT 0,
  total_cost_usd NUMERIC(8,2) DEFAULT 0,        -- should always be 0
  details JSONB DEFAULT '{}'::jsonb,             -- per-API breakdown
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TABLE: API_USAGE_LOG — granular usage tracking per call
-- ============================================================================

CREATE TABLE api_usage_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_name TEXT NOT NULL,
  company_id UUID REFERENCES companies(id),
  edge_function TEXT,                            -- which EF made the call
  response_ms NUMERIC(8,2),
  status_code INTEGER,
  success BOOLEAN DEFAULT true,
  called_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE api_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_health_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_health_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_usage_log ENABLE ROW LEVEL SECURITY;

-- api_registry: read for all authenticated, write for super_admin only
CREATE POLICY api_reg_read ON api_registry
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY api_reg_write ON api_registry
  FOR ALL USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin'
  );

-- api_health_events: read for all authenticated
CREATE POLICY api_health_ev_read ON api_health_events
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY api_health_ev_write ON api_health_events
  FOR INSERT WITH CHECK (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin'
  );

-- api_health_reports: read for all authenticated
CREATE POLICY api_health_rep_read ON api_health_reports
  FOR SELECT USING (auth.role() = 'authenticated');

-- api_usage_log: company-scoped reads + service role inserts
CREATE POLICY api_usage_read ON api_usage_log
  FOR SELECT USING (
    company_id IS NULL OR
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_api_reg_name ON api_registry(name);
CREATE INDEX idx_api_reg_status ON api_registry(status);
CREATE INDEX idx_api_health_ev_api ON api_health_events(api_id);
CREATE INDEX idx_api_health_ev_checked ON api_health_events(checked_at);
CREATE INDEX idx_api_usage_name ON api_usage_log(api_name);
CREATE INDEX idx_api_usage_called ON api_usage_log(called_at);
CREATE INDEX idx_api_usage_company ON api_usage_log(company_id);
CREATE INDEX idx_api_health_rep_month ON api_health_reports(report_month);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER api_reg_updated BEFORE UPDATE ON api_registry
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- SEED DATA: Register all 24+ free APIs
-- ============================================================================

INSERT INTO api_registry (name, display_name, category, base_url, auth_type, key_env_var, rate_limit_per_month, free_tier_limit, probe_endpoint, probe_method, docs_url) VALUES
-- ═══════════════════════════════════════
-- NO KEY NEEDED (15 APIs)
-- ═══════════════════════════════════════
('open_meteo', 'Open-Meteo Weather', 'weather',
 'https://api.open-meteo.com', 'none', NULL,
 NULL, NULL,
 '/v1/forecast?latitude=40.7&longitude=-74.0&current_weather=true', 'GET',
 'https://open-meteo.com/en/docs'),

('noaa_storm_events', 'NOAA Storm Events', 'weather',
 'https://www.ncdc.noaa.gov', 'none', NULL,
 NULL, NULL,
 '/cdo-web/api/v2/datasets?limit=1', 'GET',
 'https://www.ncdc.noaa.gov/stormevents/'),

('fema_nfhl', 'FEMA Flood Zones (NFHL)', 'government',
 'https://hazards.fema.gov', 'none', NULL,
 NULL, NULL,
 '/gis/nfhl/rest/services/public/NFHL/MapServer?f=json', 'GET',
 'https://www.fema.gov/flood-maps/national-flood-hazard-layer'),

('usfs_wildfire', 'USFS Wildfire Risk', 'government',
 'https://apps.fs.usda.gov', 'none', NULL,
 NULL, NULL,
 '/arcx/rest/services/RDW_Wildfire/ProbabilisticWildfireRisk/MapServer?f=json', 'GET',
 'https://wildfirerisk.org/'),

('nlcd_tree_canopy', 'NLCD Tree Canopy', 'property',
 'https://www.mrlc.gov', 'none', NULL,
 NULL, NULL,
 '/geoserver/mrlc_display/wms?service=WMS&request=GetCapabilities', 'GET',
 'https://www.mrlc.gov/data'),

('usgs_3dep', 'USGS 3DEP LiDAR', 'property',
 'https://elevation.nationalmap.gov', 'none', NULL,
 NULL, NULL,
 '/arcgis/rest/services/3DEPElevation/ImageServer?f=json', 'GET',
 'https://www.usgs.gov/3d-elevation-program'),

('epa_radon', 'EPA Radon Zones', 'government',
 'https://www.epa.gov', 'none', NULL,
 NULL, NULL,
 '/radon/epa-map-areas-radon-zones', 'GET',
 'https://www.epa.gov/radon'),

('epa_envirofacts', 'EPA Envirofacts', 'government',
 'https://data.epa.gov', 'none', NULL,
 NULL, NULL,
 '/efservice/count/tri_facility/state_abbr/NY/JSON', 'GET',
 'https://www.epa.gov/enviro/envirofacts-data-service-api'),

('osm_overpass', 'OpenStreetMap Overpass', 'mapping',
 'https://overpass-api.de', 'none', NULL,
 10000, NULL,
 '/api/interpreter?data=[out:json];node(40.7,-74.0,40.71,-73.99);out%20count;', 'GET',
 'https://overpass-api.de/'),

('ms_building_footprints', 'Microsoft Building Footprints', 'mapping',
 'https://minedbuildings.blob.core.windows.net', 'none', NULL,
 NULL, NULL,
 '/global-buildings/dataset-links.csv', 'GET',
 'https://github.com/microsoft/GlobalMLBuildingFootprints'),

('overture_maps', 'Overture Maps Foundation', 'mapping',
 'https://overturemaps.org', 'none', NULL,
 NULL, NULL,
 '/', 'GET',
 'https://overturemaps.org/'),

('nominatim', 'Nominatim Geocoding', 'mapping',
 'https://nominatim.openstreetmap.org', 'none', NULL,
 1, NULL,
 '/search?q=New+York&format=json&limit=1', 'GET',
 'https://nominatim.org/release-docs/develop/api/Overview/'),

('prism_climate', 'PRISM Climate Data', 'weather',
 'https://prism.oregonstate.edu', 'none', NULL,
 NULL, NULL,
 '/explorer/', 'GET',
 'https://prism.oregonstate.edu/'),

('census_housing', 'Census Housing Characteristics', 'government',
 'https://api.census.gov', 'none', NULL,
 NULL, NULL,
 '/data/2022/acs/acs5?get=B25001_001E&for=state:36', 'GET',
 'https://www.census.gov/data/developers/data-sets/acs-5year.html'),

('opentopography', 'OpenTopography LiDAR', 'property',
 'https://portal.opentopography.org', 'none', NULL,
 NULL, NULL,
 '/API/globaldem?demtype=SRTMGL3&south=40.7&north=40.71&west=-74.0&east=-73.99&outputFormat=JSON', 'GET',
 'https://opentopography.org/'),

-- ═══════════════════════════════════════
-- EXISTING GOOGLE/MAPBOX KEYS (5 APIs)
-- ═══════════════════════════════════════
('google_solar', 'Google Solar/Building Insights', 'property',
 'https://solar.googleapis.com', 'api_key', 'GOOGLE_CLOUD_API_KEY',
 10000, 10000,
 '/v1/buildingInsights:findClosest?location.latitude=40.7128&location.longitude=-74.006&key=', 'GET',
 'https://developers.google.com/maps/documentation/solar'),

('google_geocoding', 'Google Geocoding', 'mapping',
 'https://maps.googleapis.com', 'api_key', 'GOOGLE_CLOUD_API_KEY',
 40000, 40000,
 '/maps/api/geocode/json?address=1600+Amphitheatre+Parkway&key=', 'GET',
 'https://developers.google.com/maps/documentation/geocoding'),

('google_street_view', 'Google Street View Static', 'mapping',
 'https://maps.googleapis.com', 'api_key', 'GOOGLE_CLOUD_API_KEY',
 28000, 28000,
 '/maps/api/streetview/metadata?location=40.7128,-74.006&key=', 'GET',
 'https://developers.google.com/maps/documentation/streetview'),

('google_aerial_view', 'Google Aerial View', 'mapping',
 'https://aerialview.googleapis.com', 'api_key', 'GOOGLE_CLOUD_API_KEY',
 10000, 10000,
 '/v1/videos:lookupVideo?address=1600+Amphitheatre+Parkway&key=', 'GET',
 'https://developers.google.com/maps/documentation/aerial-view'),

('mapbox', 'Mapbox', 'mapping',
 'https://api.mapbox.com', 'api_key', 'MAPBOX_ACCESS_TOKEN',
 100000, 100000,
 '/geocoding/v5/mapbox.places/-73.99.json?access_token=', 'GET',
 'https://docs.mapbox.com/api/'),

-- ═══════════════════════════════════════
-- FREE KEYS TO CREATE (8 APIs)
-- ═══════════════════════════════════════
('census_acs', 'Census ACS API', 'government',
 'https://api.census.gov', 'api_key', 'CENSUS_API_KEY',
 500, 500,
 '/data/2022/acs/acs5?get=B25001_001E&for=state:36&key=', 'GET',
 'https://api.census.gov/data/key_signup.html'),

('fred_api', 'FRED Economic Data', 'financial',
 'https://api.stlouisfed.org', 'api_key', 'FRED_API_KEY',
 NULL, NULL,
 '/fred/series/observations?series_id=WPUSI012011&api_key=&file_type=json&limit=1', 'GET',
 'https://fred.stlouisfed.org/docs/api/fred/'),

('eia_open_data', 'EIA Energy Data', 'government',
 'https://api.eia.gov', 'api_key', 'EIA_API_KEY',
 NULL, NULL,
 '/v2/electricity/retail-sales?api_key=&frequency=annual&data[0]=revenue&facets[stateid][]=NY&length=1', 'GET',
 'https://www.eia.gov/opendata/'),

('nrel_solar', 'NREL PVWatts/Solar', 'property',
 'https://developer.nrel.gov', 'api_key', 'NREL_API_KEY',
 1000, 1000,
 '/api/pvwatts/v8.json?api_key=DEMO_KEY&system_capacity=4&module_type=0&losses=14&array_type=1&tilt=20&azimuth=180&lat=40&lon=-74', 'GET',
 'https://developer.nrel.gov/docs/solar/pvwatts/v8/'),

('shovels_ai', 'Shovels.ai Permit History', 'property',
 'https://api.shovels.ai', 'bearer', 'SHOVELS_API_KEY',
 250, 250,
 '/v2/permits?address=1600+Amphitheatre+Parkway', 'GET',
 'https://docs.shovels.ai/'),

('homesage_ai', 'Homesage.ai Property Data', 'property',
 'https://api.homesage.ai', 'api_key', 'HOMESAGE_API_KEY',
 1250, 1250,
 '/v1/property?address=1600+Amphitheatre+Parkway', 'GET',
 'https://homesage.ai/docs'),

('rentcast', 'RentCast Property Details', 'property',
 'https://api.rentcast.io', 'api_key', 'RENTCAST_API_KEY',
 50, 50,
 '/v1/properties?address=1600+Amphitheatre+Parkway', 'GET',
 'https://developers.rentcast.io/reference'),

('nws_alerts', 'NWS Weather Alerts', 'weather',
 'https://api.weather.gov', 'none', NULL,
 NULL, NULL,
 '/alerts/active?status=actual&limit=1', 'GET',
 'https://www.weather.gov/documentation/services-web-api'),

('noaa_spc', 'NOAA Storm Prediction Center', 'weather',
 'https://www.spc.noaa.gov', 'none', NULL,
 NULL, NULL,
 '/products/outlook/day1otlk.html', 'GET',
 'https://www.spc.noaa.gov/'),

('usda_soil', 'USDA Web Soil Survey', 'property',
 'https://SDMDataAccess.sc.egov.usda.gov', 'none', NULL,
 NULL, NULL,
 '/Tabular/SDMTabularService.asmx', 'GET',
 'https://sdmdataaccess.sc.egov.usda.gov/'),

('asce_hazard', 'ASCE Hazard Tool', 'government',
 'https://asce7hazardtool.online', 'none', NULL,
 NULL, NULL,
 '/', 'GET',
 'https://asce7hazardtool.online/'),

('bls_oews', 'BLS OEWS Wages', 'financial',
 'https://api.bls.gov', 'api_key', 'BLS_API_KEY',
 500, 500,
 '/publicAPI/v2/timeseries/data/OEUM003300000000047213103', 'GET',
 'https://www.bls.gov/developers/'),

('fema_disasters', 'FEMA Disaster Declarations', 'government',
 'https://www.fema.gov', 'none', NULL,
 NULL, NULL,
 '/api/open/v2/FemaWebDisasterDeclarations?$top=1', 'GET',
 'https://www.fema.gov/about/openfema/data-sets');

-- ============================================================================
-- DEPTH28 Part B: Property Intelligence Layer tables
-- ============================================================================

-- TABLE: property_profiles — comprehensive property data card
CREATE TABLE property_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id),
  -- Basic property info
  year_built INTEGER,
  living_area_sqft NUMERIC(10,2),
  lot_area_sqft NUMERIC(12,2),
  stories NUMERIC(3,1),
  bedrooms INTEGER,
  bathrooms_full INTEGER,
  bathrooms_half INTEGER,
  -- Construction details
  construction_type TEXT,              -- wood_frame, masonry, steel, manufactured
  foundation_type TEXT,                -- slab, crawlspace, basement, pier_beam
  roof_style TEXT,                     -- gable, hip, flat, mansard, gambrel
  exterior_material TEXT,              -- vinyl, wood, brick, stucco, fiber_cement
  -- Ownership & financials
  owner_name TEXT,
  owner_mailing_address TEXT,
  assessed_value NUMERIC(12,2),
  market_value_est NUMERIC(12,2),
  last_sale_price NUMERIC(12,2),
  last_sale_date DATE,
  ownership_years NUMERIC(4,1),
  -- Energy & utilities
  heating_type TEXT,
  cooling_type TEXT,
  electric_utility TEXT,
  gas_utility TEXT,
  water_provider TEXT,
  service_amperage INTEGER,            -- 100, 150, 200, etc.
  service_phase TEXT,                  -- single, three_phase
  -- Environmental hazards
  lead_paint_probability TEXT CHECK (lead_paint_probability IN ('none', 'low', 'moderate', 'high')),
  asbestos_probability TEXT CHECK (asbestos_probability IN ('none', 'low', 'moderate', 'high')),
  radon_zone TEXT,                     -- 1, 2, 3
  termite_zone TEXT,                   -- 1, 2, 3, 4
  flood_zone TEXT,                     -- A, AE, X, X500, etc.
  flood_risk_level TEXT,               -- high, moderate, minimal, unknown
  wildfire_risk_score NUMERIC(5,2),
  seismic_zone TEXT,
  expansive_soil_risk TEXT,
  -- HOA info
  hoa_name TEXT,
  hoa_contact TEXT,
  hoa_architectural_review BOOLEAN DEFAULT false,
  hoa_restrictions JSONB DEFAULT '{}'::jsonb,
  -- Building codes
  jurisdiction TEXT,
  ibc_irc_year TEXT,
  nec_year TEXT,
  ipc_upc_year TEXT,
  iecc_year TEXT,
  wind_speed_mph NUMERIC(5,1),
  snow_load_psf NUMERIC(5,1),
  seismic_design_category TEXT,
  frost_line_depth_inches INTEGER,
  climate_zone TEXT,
  -- Neighborhood context
  neighborhood_avg_value NUMERIC(12,2),
  neighborhood_construction_type TEXT,
  -- Data sources and confidence
  data_sources JSONB DEFAULT '[]'::jsonb,
  confidence_score INTEGER DEFAULT 0,
  raw_responses JSONB DEFAULT '{}'::jsonb,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- TABLE: permit_history — permits pulled for the property
CREATE TABLE permit_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id),
  -- Permit data
  permit_number TEXT,
  permit_type TEXT,                    -- building, electrical, plumbing, mechanical, roofing, demo
  description TEXT,
  contractor_name TEXT,
  contractor_license TEXT,
  -- Dates
  filed_date DATE,
  issued_date DATE,
  final_date DATE,
  expiration_date DATE,
  -- Status
  status TEXT DEFAULT 'unknown'
    CHECK (status IN ('filed', 'issued', 'in_progress', 'final', 'failed', 'expired', 'unknown')),
  inspection_results JSONB DEFAULT '[]'::jsonb,
  -- Financials
  estimated_cost NUMERIC(12,2),
  -- Flags
  is_red_flag BOOLEAN DEFAULT false,   -- open/expired/failed = red flag
  red_flag_reason TEXT,
  -- Source
  source TEXT DEFAULT 'shovels_ai',
  raw_data JSONB DEFAULT '{}'::jsonb,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- DEPTH28 Part C: Weather & Storm Intelligence tables
-- ============================================================================

-- TABLE: weather_intelligence — weather data per property scan
CREATE TABLE weather_intelligence (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id),
  -- Current conditions
  current_temp_f NUMERIC(5,1),
  current_wind_mph NUMERIC(5,1),
  current_precip_mm NUMERIC(6,2),
  current_uv_index NUMERIC(3,1),
  current_conditions TEXT,
  weather_fetched_at TIMESTAMPTZ,
  -- Historical storm data
  last_hail_event_date DATE,
  last_hail_size_inches NUMERIC(4,2),
  last_tornado_date DATE,
  last_tornado_distance_mi NUMERIC(6,1),
  last_flood_event_date DATE,
  total_storm_events_5yr INTEGER DEFAULT 0,
  total_storm_events_10yr INTEGER DEFAULT 0,
  -- Climate data
  freeze_thaw_cycles_yr NUMERIC(5,1),
  annual_precip_inches NUMERIC(6,2),
  heating_degree_days INTEGER,
  cooling_degree_days INTEGER,
  avg_snow_load_psf NUMERIC(5,1),
  avg_wind_speed_mph NUMERIC(5,1),
  -- Storm damage probability
  storm_damage_score INTEGER DEFAULT 0 CHECK (storm_damage_score BETWEEN 0 AND 100),
  storm_score_factors JSONB DEFAULT '{}'::jsonb,
  -- Data sources
  data_sources JSONB DEFAULT '[]'::jsonb,
  raw_responses JSONB DEFAULT '{}'::jsonb,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- TABLE: material_price_indices — tracked from FRED/BLS
CREATE TABLE material_price_indices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  material_name TEXT NOT NULL,         -- 'lumber', 'steel', 'copper', 'pvc', etc.
  series_id TEXT NOT NULL,             -- FRED/BLS series ID
  source TEXT DEFAULT 'fred',          -- 'fred', 'bls'
  -- Latest values
  latest_value NUMERIC(10,2),
  latest_date DATE,
  -- 12-month trend
  value_12m_ago NUMERIC(10,2),
  change_12m_pct NUMERIC(6,2),
  trend TEXT CHECK (trend IN ('rising', 'falling', 'stable')),
  -- Historical data (last 24 months)
  history JSONB DEFAULT '[]'::jsonb,   -- [{date, value}, ...]
  -- Metadata
  fetched_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- DEPTH28 Part D: Trade-Specific Auto-Scope Generation
-- ============================================================================

-- TABLE: trade_auto_scopes — auto-generated scope per trade from scan data
CREATE TABLE trade_auto_scopes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id),
  trade TEXT NOT NULL,                  -- roofing, siding, electrical, plumbing, etc.
  -- Scope content
  scope_summary TEXT,                  -- 1-2 paragraph narrative
  scope_items JSONB DEFAULT '[]'::jsonb,
  -- [{category, item, value, unit, source, confidence}]
  -- e.g., {category: "measurements", item: "roof_area", value: "2400", unit: "sqft", source: "google_solar", confidence: 85}
  -- Code requirements
  code_requirements JSONB DEFAULT '[]'::jsonb,
  -- [{code_type: "IBC", year: "2021", requirement: "...", section: "R905.2"}]
  -- Permits
  permits_required BOOLEAN,
  permit_types JSONB DEFAULT '[]'::jsonb,  -- ["building", "roofing"]
  -- Dependencies (cross-trade)
  dependencies JSONB DEFAULT '[]'::jsonb,
  -- [{trade: "electrical", reason: "Panel upgrade needed for heat pump", priority: "before"}]
  -- Confidence
  confidence_score INTEGER DEFAULT 0,
  data_sources JSONB DEFAULT '[]'::jsonb,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- DEPTH28 Part A: Expand trade_bid_data for all trades
-- ============================================================================

-- Expand trade_bid_data CHECK constraint to include all trades
ALTER TABLE trade_bid_data DROP CONSTRAINT IF EXISTS trade_bid_data_trade_check;
ALTER TABLE trade_bid_data ADD CONSTRAINT trade_bid_data_trade_check
  CHECK (trade IN (
    'roofing', 'siding', 'gutters', 'solar', 'painting',
    'landscaping', 'fencing', 'concrete', 'hvac', 'electrical',
    'plumbing', 'insulation', 'windows_doors', 'flooring',
    'drywall', 'framing', 'demolition', 'masonry', 'paving',
    'water_restoration', 'fire_restoration', 'mold_remediation',
    'general_remodel', 'tree_service', 'pool', 'garage_doors',
    'pressure_washing', 'stucco', 'decking', 'foundation'
  ));

-- Add new columns to property_scans for expanded data
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS property_profile_id UUID;
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS weather_intelligence_id UUID;
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS trade_scans_requested JSONB DEFAULT '[]'::jsonb;
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS trade_scans_complete JSONB DEFAULT '[]'::jsonb;

-- ============================================================================
-- ROW LEVEL SECURITY for new tables
-- ============================================================================

ALTER TABLE property_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permit_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_intelligence ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_price_indices ENABLE ROW LEVEL SECURITY;
ALTER TABLE trade_auto_scopes ENABLE ROW LEVEL SECURITY;

CREATE POLICY pp_company ON property_profiles
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY ph_company ON permit_history
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY wi_company ON weather_intelligence
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY mpi_read ON material_price_indices
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY tas_company ON trade_auto_scopes
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- INDEXES for new tables
-- ============================================================================

CREATE INDEX idx_pp_scan ON property_profiles(scan_id);
CREATE INDEX idx_pp_company ON property_profiles(company_id);
CREATE INDEX idx_ph_scan ON permit_history(scan_id);
CREATE INDEX idx_ph_company ON permit_history(company_id);
CREATE INDEX idx_ph_type ON permit_history(permit_type);
CREATE INDEX idx_ph_status ON permit_history(status);
CREATE INDEX idx_wi_scan ON weather_intelligence(scan_id);
CREATE INDEX idx_wi_company ON weather_intelligence(company_id);
CREATE INDEX idx_mpi_material ON material_price_indices(material_name);
CREATE INDEX idx_mpi_series ON material_price_indices(series_id);
CREATE INDEX idx_tas_scan ON trade_auto_scopes(scan_id);
CREATE INDEX idx_tas_company ON trade_auto_scopes(company_id);
CREATE INDEX idx_tas_trade ON trade_auto_scopes(trade);

-- ============================================================================
-- TRIGGERS for new tables
-- ============================================================================

CREATE TRIGGER pp_updated BEFORE UPDATE ON property_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER pp_audit AFTER INSERT OR UPDATE OR DELETE ON property_profiles
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER ph_audit AFTER INSERT OR UPDATE OR DELETE ON permit_history
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER wi_updated BEFORE UPDATE ON weather_intelligence
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER mpi_updated BEFORE UPDATE ON material_price_indices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tas_updated BEFORE UPDATE ON trade_auto_scopes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- RPC: increment_api_usage — atomic counter increment
-- ============================================================================

CREATE OR REPLACE FUNCTION increment_api_usage(api_name_param TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE api_registry
  SET current_month_usage = current_month_usage + 1
  WHERE name = api_name_param;
END;
$$;

-- ============================================================================
-- SEED: Material price index series to track
-- ============================================================================

INSERT INTO material_price_indices (material_name, series_id, source) VALUES
  ('lumber', 'WPU081', 'fred'),
  ('softwood_lumber', 'WPS0811', 'fred'),
  ('steel_mill', 'PCU33111133111105', 'bls'),
  ('copper', 'WPUSI019011', 'fred'),
  ('aluminum', 'WPU102502', 'fred'),
  ('pvc_pipe', 'PCU326122326122', 'bls'),
  ('asphalt_shingles', 'PCU324121324121111', 'bls'),
  ('concrete_ready_mix', 'PCU327320327320P', 'bls'),
  ('glass_flat', 'PCU32721132721101', 'bls'),
  ('gypsum_drywall', 'PCU327420327420', 'bls'),
  ('insulation_fiberglass', 'PCU327993327993', 'bls'),
  ('paint_coatings', 'PCU325510325510', 'bls'),
  ('brick', 'PCU327121327121', 'bls'),
  ('roofing_tar', 'WPU0591', 'fred'),
  ('electrical_wire', 'PCU335920335920P', 'bls');
