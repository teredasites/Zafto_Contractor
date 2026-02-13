-- P3: Wall Measurements + Trade Bid Data
-- Phase P (Recon) — Sprint P3
-- Tables: wall_measurements, trade_bid_data

-- ============================================================================
-- TABLE: WALL MEASUREMENTS — exterior wall data per scan
-- ============================================================================

CREATE TABLE wall_measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  structure_id UUID REFERENCES property_structures(id) ON DELETE SET NULL,
  -- Totals
  total_wall_area_sqft NUMERIC(10,2) DEFAULT 0,
  total_siding_area_sqft NUMERIC(10,2) DEFAULT 0,  -- wall area minus openings
  -- Per-face breakdown
  per_face JSONB DEFAULT '[]'::jsonb,
  -- [{direction: "north", width_ft, height_ft, area_sqft, window_count_est, door_count_est, net_area_sqft}]
  stories INTEGER DEFAULT 1,
  avg_wall_height_ft NUMERIC(6,2) DEFAULT 9,
  -- Openings
  window_area_est_sqft NUMERIC(8,2) DEFAULT 0,
  door_area_est_sqft NUMERIC(8,2) DEFAULT 0,
  -- Trim / accessories
  trim_linear_ft NUMERIC(8,2) DEFAULT 0,
  fascia_linear_ft NUMERIC(8,2) DEFAULT 0,
  soffit_sqft NUMERIC(8,2) DEFAULT 0,
  -- Source
  data_source TEXT DEFAULT 'derived',  -- 'derived', 'manual', 'ai_cv', 'lidar'
  confidence NUMERIC(4,2) DEFAULT 50,  -- 0-100
  is_estimated BOOLEAN DEFAULT true,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TABLE: TRADE BID DATA — pre-calculated per-trade measurements
-- ============================================================================

CREATE TABLE trade_bid_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  trade TEXT NOT NULL CHECK (trade IN (
    'roofing', 'siding', 'gutters', 'solar', 'painting',
    'landscaping', 'fencing', 'concrete', 'hvac', 'electrical'
  )),
  -- Trade-specific measurements
  measurements JSONB DEFAULT '{}'::jsonb,
  -- Material list
  material_list JSONB DEFAULT '[]'::jsonb,
  -- [{item, quantity, unit, waste_pct, total_with_waste}]
  waste_factor_pct NUMERIC(5,2) DEFAULT 10,
  complexity_score NUMERIC(4,2) DEFAULT 1,
  notes TEXT,
  recommended_crew_size INTEGER DEFAULT 2,
  estimated_labor_hours NUMERIC(6,2),
  data_sources JSONB DEFAULT '[]'::jsonb,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE wall_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE trade_bid_data ENABLE ROW LEVEL SECURITY;

-- wall_measurements: access through scan_id → property_scans company check
CREATE POLICY wm_company ON wall_measurements
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM property_scans ps
      WHERE ps.id = scan_id
      AND ps.company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );

-- trade_bid_data: access through scan_id → property_scans company check
CREATE POLICY tbd_company ON trade_bid_data
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM property_scans ps
      WHERE ps.id = scan_id
      AND ps.company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_wm_scan ON wall_measurements(scan_id);
CREATE INDEX idx_wm_structure ON wall_measurements(structure_id);
CREATE INDEX idx_tbd_scan ON trade_bid_data(scan_id);
CREATE INDEX idx_tbd_trade ON trade_bid_data(trade);
CREATE UNIQUE INDEX idx_tbd_scan_trade ON trade_bid_data(scan_id, trade);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER wm_updated BEFORE UPDATE ON wall_measurements FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER wm_audit AFTER INSERT OR UPDATE OR DELETE ON wall_measurements FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER tbd_updated BEFORE UPDATE ON trade_bid_data FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tbd_audit AFTER INSERT OR UPDATE OR DELETE ON trade_bid_data FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
