-- P5: Lead Scoring + Batch Area Scanning
-- Phase P (Recon) — Sprint P5
-- Tables: property_lead_scores, area_scans

-- ============================================================================
-- TABLE: AREA SCANS — batch polygon-based scanning
-- ============================================================================

CREATE TABLE area_scans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT,
  scan_type TEXT DEFAULT 'prospecting' CHECK (
    scan_type IN ('prospecting', 'storm_response', 'canvassing')
  ),
  polygon_geojson JSONB,  -- GeoJSON polygon defining scan area
  storm_event_id TEXT,
  storm_date DATE,
  storm_type TEXT,  -- 'hail', 'wind', 'tornado', 'flood'
  -- Progress tracking
  total_parcels INTEGER DEFAULT 0,
  scanned_parcels INTEGER DEFAULT 0,
  hot_leads INTEGER DEFAULT 0,
  warm_leads INTEGER DEFAULT 0,
  cold_leads INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (
    status IN ('pending', 'scanning', 'complete', 'failed')
  ),
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- ============================================================================
-- TABLE: PROPERTY LEAD SCORES — qualification scoring per scan
-- ============================================================================

CREATE TABLE property_lead_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id),
  area_scan_id UUID REFERENCES area_scans(id) ON DELETE SET NULL,
  -- Scores
  overall_score INTEGER DEFAULT 0 CHECK (overall_score BETWEEN 0 AND 100),
  grade TEXT DEFAULT 'cold' CHECK (grade IN ('hot', 'warm', 'cold')),
  -- Component scores (0-100 each)
  roof_age_score INTEGER DEFAULT 0,
  property_value_score INTEGER DEFAULT 0,
  owner_tenure_score INTEGER DEFAULT 0,
  condition_score INTEGER DEFAULT 0,
  permit_score INTEGER DEFAULT 0,
  -- Storm data
  storm_damage_probability NUMERIC(5,2) DEFAULT 0,
  -- Scoring factors breakdown
  scoring_factors JSONB DEFAULT '{}'::jsonb,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE area_scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_lead_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY as_company ON area_scans
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY pls_company ON property_lead_scores
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_as_company ON area_scans(company_id);
CREATE INDEX idx_as_status ON area_scans(status);
CREATE INDEX idx_pls_scan ON property_lead_scores(property_scan_id);
CREATE INDEX idx_pls_company ON property_lead_scores(company_id);
CREATE INDEX idx_pls_area_scan ON property_lead_scores(area_scan_id);
CREATE INDEX idx_pls_grade ON property_lead_scores(grade);
CREATE INDEX idx_pls_score ON property_lead_scores(overall_score DESC);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER as_updated BEFORE UPDATE ON area_scans FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER as_audit AFTER INSERT OR UPDATE OR DELETE ON area_scans FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER pls_updated BEFORE UPDATE ON property_lead_scores FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER pls_audit AFTER INSERT OR UPDATE OR DELETE ON property_lead_scores FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
