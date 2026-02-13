-- P1: Property Intelligence Foundation
-- Phase P (Recon) — Sprint P1
-- Core tables: property_scans, roof_measurements, roof_facets

-- ============================================================================
-- TABLE: PROPERTY SCANS — master scan record per property
-- ============================================================================

CREATE TABLE property_scans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),
  created_by UUID REFERENCES auth.users(id),
  -- Address
  address TEXT NOT NULL,
  address_line2 TEXT,
  city TEXT,
  state TEXT,
  zip TEXT,
  country TEXT DEFAULT 'US',
  -- Geocode
  latitude NUMERIC(10,7),
  longitude NUMERIC(10,7),
  -- Scan status
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending', 'scanning', 'complete', 'partial', 'failed'
  )),
  -- Data sources that contributed
  scan_sources JSONB DEFAULT '[]'::jsonb,  -- ["google_solar", "ms_footprints", "usgs", "attom", "regrid"]
  -- Confidence
  confidence_score INTEGER DEFAULT 0 CHECK (confidence_score BETWEEN 0 AND 100),
  confidence_grade TEXT DEFAULT 'low' CHECK (confidence_grade IN ('high', 'moderate', 'low')),
  confidence_factors JSONB DEFAULT '{}'::jsonb,
  -- Imagery
  imagery_date DATE,
  imagery_source TEXT,  -- 'google_solar', 'mapbox', 'user_uploaded'
  imagery_age_months INTEGER,
  -- Cache
  cached_until TIMESTAMPTZ,
  -- Metadata
  error_message TEXT,
  raw_google_solar JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- ============================================================================
-- TABLE: ROOF MEASUREMENTS — aggregate roof data per scan
-- ============================================================================

CREATE TABLE roof_measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  -- Areas
  total_area_sqft NUMERIC(10,2) DEFAULT 0,
  total_area_squares NUMERIC(8,2) DEFAULT 0,  -- sqft / 100
  -- Pitch
  pitch_primary TEXT,  -- e.g., "6/12"
  pitch_degrees NUMERIC(5,2),
  pitch_distribution JSONB DEFAULT '[]'::jsonb,  -- [{pitch: "6/12", area_pct: 60}, ...]
  -- Edge lengths
  ridge_length_ft NUMERIC(8,2) DEFAULT 0,
  hip_length_ft NUMERIC(8,2) DEFAULT 0,
  valley_length_ft NUMERIC(8,2) DEFAULT 0,
  eave_length_ft NUMERIC(8,2) DEFAULT 0,
  rake_length_ft NUMERIC(8,2) DEFAULT 0,
  -- Structure
  facet_count INTEGER DEFAULT 0,
  complexity_score NUMERIC(4,2) DEFAULT 0,  -- 1-10 scale
  predominant_shape TEXT CHECK (predominant_shape IN (
    'gable', 'hip', 'flat', 'gambrel', 'mansard', 'mixed'
  )),
  predominant_material TEXT,  -- e.g., "asphalt_shingle", "metal", "tile"
  condition_score NUMERIC(4,2),  -- 1-10, null if unknown
  penetration_count INTEGER DEFAULT 0,  -- vents, chimneys, skylights
  -- Source
  data_source TEXT DEFAULT 'google_solar',
  raw_response JSONB,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TABLE: ROOF FACETS — individual roof segments
-- ============================================================================

CREATE TABLE roof_facets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  roof_measurement_id UUID NOT NULL REFERENCES roof_measurements(id) ON DELETE CASCADE,
  -- Facet data
  facet_number INTEGER NOT NULL,
  area_sqft NUMERIC(10,2) DEFAULT 0,
  pitch_degrees NUMERIC(5,2),
  azimuth_degrees NUMERIC(5,2),  -- 0=N, 90=E, 180=S, 270=W
  -- Solar data
  annual_sun_hours NUMERIC(8,2),
  shade_factor NUMERIC(4,2),  -- 0-1, 1 = full sun
  -- Shape
  shape_type TEXT,  -- 'rectangle', 'triangle', 'trapezoid', 'irregular'
  vertices JSONB DEFAULT '[]'::jsonb,  -- [[x,y], [x,y], ...]
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE property_scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE roof_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE roof_facets ENABLE ROW LEVEL SECURITY;

CREATE POLICY ps_company ON property_scans
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- roof_measurements inherits access through scan_id join
CREATE POLICY rm_company ON roof_measurements
  FOR ALL USING (
    EXISTS (SELECT 1 FROM property_scans ps WHERE ps.id = scan_id AND ps.company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  );

CREATE POLICY rf_company ON roof_facets
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM roof_measurements rm
      JOIN property_scans ps ON ps.id = rm.scan_id
      WHERE rm.id = roof_measurement_id
      AND ps.company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_ps_company ON property_scans(company_id);
CREATE INDEX idx_ps_job ON property_scans(job_id);
CREATE INDEX idx_ps_status ON property_scans(status);
CREATE INDEX idx_ps_address ON property_scans(address);
CREATE INDEX idx_ps_coords ON property_scans(latitude, longitude);
CREATE INDEX idx_rm_scan ON roof_measurements(scan_id);
CREATE INDEX idx_rf_measurement ON roof_facets(roof_measurement_id);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER ps_updated BEFORE UPDATE ON property_scans FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER ps_audit AFTER INSERT OR UPDATE OR DELETE ON property_scans FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER rm_updated BEFORE UPDATE ON roof_measurements FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER rm_audit AFTER INSERT OR UPDATE OR DELETE ON roof_measurements FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Add property_scan_id to jobs table
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'jobs' AND column_name = 'property_scan_id') THEN
    ALTER TABLE jobs ADD COLUMN property_scan_id UUID REFERENCES property_scans(id);
  END IF;
END $$;

-- Add property_scan_id to estimates table
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'estimates' AND column_name = 'property_scan_id') THEN
    ALTER TABLE estimates ADD COLUMN property_scan_id UUID REFERENCES property_scans(id);
  END IF;
END $$;
