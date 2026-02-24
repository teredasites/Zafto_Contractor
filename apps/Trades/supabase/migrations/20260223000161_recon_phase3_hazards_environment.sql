-- Phase 3A+3B: Recon Hazard Flags, Environmental Data, Code Requirements
-- Adds comprehensive hazard detection, environmental analysis, and building code fields

-- ============================================================================
-- property_scans: Hazard flags + environmental + code data
-- ============================================================================
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS hazard_flags JSONB DEFAULT '[]'::jsonb;
  -- Array of: { type, severity, title, description, what_to_do, cost_implications, regulatory }
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS environmental_data JSONB DEFAULT '{}'::jsonb;
  -- { climate_zone, frost_line_depth_in, soil_type, soil_drainage, tree_canopy_pct, radon_zone, wildfire_risk, termite_zone }
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS code_requirements JSONB DEFAULT '{}'::jsonb;
  -- { wind_speed_mph, snow_load_psf, seismic_category, energy_code, insulation_r_values, frost_line_depth_in }
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS weather_history JSONB DEFAULT '{}'::jsonb;
  -- { freeze_thaw_cycles, annual_precip_in, temp_min_f, temp_max_f, hail_events, wind_events, avg_wind_mph }
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS computed_measurements JSONB DEFAULT '{}'::jsonb;
  -- { lawn_area_sqft, wall_area_sqft, roof_complexity_factor, boundary_perimeter_ft, driveway_area_sqft }
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS noaa_storm_events JSONB DEFAULT '[]'::jsonb;
  -- Array of: { date, event_type, magnitude, description }

-- ============================================================================
-- property_features: Environmental + code columns (queryable)
-- ============================================================================
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS radon_zone INTEGER;
  -- EPA radon zone: 1 (high), 2 (moderate), 3 (low)
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS wildfire_risk TEXT;
  -- 'very_high', 'high', 'moderate', 'low', 'very_low'
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS seismic_category TEXT;
  -- ASCE 7 seismic design category: A, B, C, D0, D1, D2, E, F
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS climate_zone TEXT;
  -- IECC climate zone: '1A', '2A', '2B', '3A', '3B', '3C', '4A', '4B', '4C', '5A', '5B', '6A', '6B', '7', '8'
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS frost_line_depth_in INTEGER;
  -- Frost line depth in inches (from ASCE 7 / local codes)
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS design_wind_speed_mph INTEGER;
  -- ASCE 7 basic wind speed for the location
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS snow_load_psf NUMERIC(6,1);
  -- Ground snow load in PSF
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS soil_type TEXT;
  -- USDA soil classification
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS soil_drainage TEXT;
  -- 'well_drained', 'moderately_drained', 'somewhat_poorly_drained', 'poorly_drained'
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS soil_bearing_capacity TEXT;
  -- 'high', 'moderate', 'low'
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS tree_canopy_pct NUMERIC(5,2);
  -- NLCD tree canopy coverage percentage
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS lawn_area_sqft NUMERIC(10,2);
  -- Computed: lot_sqft - footprint_sqft - driveway_estimate
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS wall_area_sqft NUMERIC(10,2);
  -- Computed: perimeter * stories * ceiling_height - window/door estimates
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS roof_complexity_factor NUMERIC(4,2);
  -- 1.0 = simple gable, 1.5 = moderate hip, 2.0+ = complex multi-level
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS boundary_perimeter_ft NUMERIC(10,2);
  -- Linear feet of property boundary (for fence estimates)
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS termite_zone TEXT;
  -- 'very_heavy', 'moderate_to_heavy', 'slight_to_moderate', 'none_to_slight'

-- ============================================================================
-- Indexes for hazard queries
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_ps_hazard_flags ON property_scans USING gin(hazard_flags);
CREATE INDEX IF NOT EXISTS idx_pf_climate_zone ON property_features(climate_zone) WHERE climate_zone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pf_radon_zone ON property_features(radon_zone) WHERE radon_zone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pf_wildfire_risk ON property_features(wildfire_risk) WHERE wildfire_risk IS NOT NULL;
