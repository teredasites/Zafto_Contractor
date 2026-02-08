-- F4f: Sketch + Bid Flow tables
-- bid_sketches = a sketch document (one per bid/estimate)
-- sketch_rooms = individual rooms within a sketch (dimensions, damage areas, photos)

-- Bid Sketches — top-level sketch document linked to a bid/estimate/job
CREATE TABLE bid_sketches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),
  estimate_id UUID REFERENCES estimates(id),
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','in_progress','completed','submitted')),
  total_sqft NUMERIC(10,2) DEFAULT 0,
  total_rooms INTEGER DEFAULT 0,
  sketch_data JSONB NOT NULL DEFAULT '{}'::jsonb,  -- SVG/canvas overlay data for full property sketch
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,  -- property type, story count, etc.
  location_lat NUMERIC(10,7),
  location_lng NUMERIC(10,7),
  address TEXT,
  created_by_user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Sketch Rooms — individual rooms with dimensions, damage, photos
CREATE TABLE sketch_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  sketch_id UUID NOT NULL REFERENCES bid_sketches(id) ON DELETE CASCADE,
  room_name TEXT NOT NULL,
  room_type TEXT NOT NULL DEFAULT 'room' CHECK (room_type IN ('room','hallway','bathroom','kitchen','garage','attic','basement','closet','utility','exterior','other')),
  floor_level TEXT DEFAULT 'main' CHECK (floor_level IN ('basement','main','upper','attic','exterior')),
  sort_order INTEGER DEFAULT 0,
  -- Dimensions
  length_ft NUMERIC(8,2),
  width_ft NUMERIC(8,2),
  height_ft NUMERIC(8,2) DEFAULT 8.0,
  sqft NUMERIC(10,2),  -- computed or manual override
  -- Ceiling
  ceiling_type TEXT DEFAULT 'flat' CHECK (ceiling_type IN ('flat','vaulted','tray','cathedral','coffered','drop','other')),
  ceiling_height_peak_ft NUMERIC(8,2),
  -- Windows/Doors
  window_count INTEGER DEFAULT 0,
  door_count INTEGER DEFAULT 0,
  window_details JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{width, height, type}]
  door_details JSONB NOT NULL DEFAULT '[]'::jsonb,    -- [{width, height, type}]
  -- Damage (for insurance/restoration)
  has_damage BOOLEAN DEFAULT false,
  damage_areas JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{type, severity, location, photos, notes}]
  damage_class TEXT CHECK (damage_class IN ('1','2','3','4')),  -- IICRC water damage class
  damage_category TEXT CHECK (damage_category IN ('1','2','3')),  -- IICRC water category
  -- Sketch overlay
  sketch_data JSONB NOT NULL DEFAULT '{}'::jsonb,  -- room-level SVG/canvas overlay (walls, annotations, measurements)
  -- Photos
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{path, caption, taken_at, is_before}]
  -- Linked estimate items
  linked_items JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{item_id, zafto_code, quantity, unit, action}]
  -- Calculated totals
  estimated_total NUMERIC(12,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Site Surveys — structured site condition assessments
CREATE TABLE site_surveys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),
  sketch_id UUID REFERENCES bid_sketches(id),
  title TEXT NOT NULL,
  survey_type TEXT NOT NULL DEFAULT 'pre_job' CHECK (survey_type IN ('pre_job','progress','final','insurance','maintenance')),
  surveyor_id UUID REFERENCES auth.users(id),
  surveyor_name TEXT NOT NULL,
  -- Property details
  property_type TEXT CHECK (property_type IN ('residential','commercial','industrial','multi_family','other')),
  year_built INTEGER,
  stories INTEGER DEFAULT 1,
  total_sqft NUMERIC(10,2),
  -- Conditions
  exterior_condition TEXT CHECK (exterior_condition IN ('good','fair','poor','damaged')),
  interior_condition TEXT CHECK (interior_condition IN ('good','fair','poor','damaged')),
  roof_condition TEXT CHECK (roof_condition IN ('good','fair','poor','damaged')),
  -- Utility info
  electrical_service TEXT,
  plumbing_type TEXT,
  hvac_type TEXT,
  -- Structured data
  conditions JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{area, condition, notes, photos, severity}]
  measurements JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{area, length, width, height, notes}]
  hazards JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{type, location, severity, mitigation_needed, photo}]
  access_notes TEXT,
  -- Photos
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Status
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','in_progress','completed','submitted')),
  completed_at TIMESTAMPTZ,
  signature_path TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE bid_sketches ENABLE ROW LEVEL SECURITY;
ALTER TABLE sketch_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_surveys ENABLE ROW LEVEL SECURITY;

CREATE POLICY bid_sketches_company ON bid_sketches FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY sketch_rooms_company ON sketch_rooms FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY site_surveys_company ON site_surveys FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Indexes
CREATE INDEX idx_sketches_job ON bid_sketches(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX idx_sketches_estimate ON bid_sketches(estimate_id) WHERE estimate_id IS NOT NULL;
CREATE INDEX idx_sketches_company ON bid_sketches(company_id);
CREATE INDEX idx_sketch_rooms_sketch ON sketch_rooms(sketch_id);
CREATE INDEX idx_site_surveys_job ON site_surveys(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX idx_site_surveys_company ON site_surveys(company_id);

-- Triggers
CREATE TRIGGER bid_sketches_updated BEFORE UPDATE ON bid_sketches FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER sketch_rooms_updated BEFORE UPDATE ON sketch_rooms FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER site_surveys_updated BEFORE UPDATE ON site_surveys FOR EACH ROW EXECUTE FUNCTION update_updated_at();
