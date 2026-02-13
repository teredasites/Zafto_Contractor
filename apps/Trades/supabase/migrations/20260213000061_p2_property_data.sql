-- P2: Property Data + Parcel + Multi-Structure Detection
-- Phase P (Recon) — Sprint P2
-- Tables: parcel_boundaries, property_features, property_structures

-- ============================================================================
-- TABLE: PARCEL BOUNDARIES — lot/parcel data per scan
-- ============================================================================

CREATE TABLE parcel_boundaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  apn TEXT,  -- Assessor Parcel Number
  boundary_geojson JSONB,  -- GeoJSON polygon of parcel
  lot_area_sqft NUMERIC(12,2),
  lot_width_ft NUMERIC(8,2),
  lot_depth_ft NUMERIC(8,2),
  zoning TEXT,
  zoning_description TEXT,
  owner_name TEXT,
  owner_type TEXT,  -- 'individual', 'corporate', 'trust', 'government'
  data_source TEXT DEFAULT 'user_drawn',  -- 'regrid', 'user_drawn', 'manual'
  raw_regrid JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TABLE: PROPERTY FEATURES — detailed property characteristics
-- ============================================================================

CREATE TABLE property_features (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  -- Building characteristics
  year_built INTEGER,
  stories INTEGER,
  living_sqft NUMERIC(10,2),
  lot_sqft NUMERIC(12,2),
  beds INTEGER,
  baths_full INTEGER,
  baths_half INTEGER,
  construction_type TEXT,  -- 'wood_frame', 'masonry', 'steel', 'concrete'
  wall_type TEXT,  -- 'vinyl', 'brick', 'stucco', 'wood', 'fiber_cement', 'stone'
  roof_type_record TEXT,  -- 'asphalt_shingle', 'metal', 'tile', 'slate', 'flat'
  -- HVAC
  heating_type TEXT,
  cooling_type TEXT,
  -- Exterior features
  pool_type TEXT,
  garage_spaces INTEGER DEFAULT 0,
  -- Financials
  assessed_value NUMERIC(14,2),
  last_sale_price NUMERIC(14,2),
  last_sale_date DATE,
  -- Terrain
  elevation_ft NUMERIC(8,2),
  terrain_slope_pct NUMERIC(5,2),
  tree_coverage_pct NUMERIC(5,2),
  building_height_ft NUMERIC(6,2),
  -- Sources
  data_sources JSONB DEFAULT '[]'::jsonb,  -- ["google_solar", "usgs", "attom", "user"]
  raw_attom JSONB,
  raw_regrid JSONB,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TABLE: PROPERTY STRUCTURES — individual buildings on the lot
-- ============================================================================

CREATE TABLE property_structures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  structure_type TEXT NOT NULL DEFAULT 'primary' CHECK (
    structure_type IN ('primary', 'secondary', 'accessory', 'other')
  ),
  label TEXT,  -- 'Main House', 'Detached Garage', 'Shed', 'Workshop'
  footprint_sqft NUMERIC(10,2),
  footprint_geojson JSONB,  -- GeoJSON polygon of building footprint
  estimated_stories INTEGER DEFAULT 1,
  estimated_roof_area_sqft NUMERIC(10,2),
  estimated_wall_area_sqft NUMERIC(10,2),
  has_roof_measurement BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE parcel_boundaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_structures ENABLE ROW LEVEL SECURITY;

-- parcel_boundaries: access through scan_id → property_scans company check
CREATE POLICY pb_company ON parcel_boundaries
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM property_scans ps
      WHERE ps.id = scan_id
      AND ps.company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );

-- property_features: access through scan_id → property_scans company check
CREATE POLICY pf_company ON property_features
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM property_scans ps
      WHERE ps.id = scan_id
      AND ps.company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );

-- property_structures: access through property_scan_id → property_scans company check
CREATE POLICY pst_company ON property_structures
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM property_scans ps
      WHERE ps.id = property_scan_id
      AND ps.company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_pb_scan ON parcel_boundaries(scan_id);
CREATE INDEX idx_pf_scan ON property_features(scan_id);
CREATE INDEX idx_pst_scan ON property_structures(property_scan_id);
CREATE INDEX idx_pst_type ON property_structures(structure_type);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER pb_updated BEFORE UPDATE ON parcel_boundaries FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER pb_audit AFTER INSERT OR UPDATE OR DELETE ON parcel_boundaries FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER pf_updated BEFORE UPDATE ON property_features FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER pf_audit AFTER INSERT OR UPDATE OR DELETE ON property_features FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER pst_updated BEFORE UPDATE ON property_structures FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER pst_audit AFTER INSERT OR UPDATE OR DELETE ON property_structures FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
