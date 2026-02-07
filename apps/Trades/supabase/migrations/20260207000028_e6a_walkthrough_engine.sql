-- E6a: Bid Walkthrough Engine — Data Model + Templates
-- Tables: walkthroughs, walkthrough_rooms, walkthrough_photos, walkthrough_templates, property_floor_plans

-- ── Walkthroughs ──
CREATE TABLE IF NOT EXISTS walkthroughs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id),
  created_by uuid REFERENCES users(id),
  customer_id uuid REFERENCES customers(id),
  job_id uuid REFERENCES jobs(id),
  bid_id uuid REFERENCES bids(id),
  property_id uuid REFERENCES properties(id),
  name text NOT NULL,
  walkthrough_type text NOT NULL DEFAULT 'general' CHECK (walkthrough_type IN (
    'general', 'trade_specific', 'insurance_restoration', 'property_inspection', 'commercial', 'custom'
  )),
  property_type text DEFAULT 'residential' CHECK (property_type IN (
    'residential', 'commercial', 'industrial', 'multi_family'
  )),
  address text,
  city text,
  state text,
  zip_code text,
  latitude double precision,
  longitude double precision,
  template_id uuid,
  status text NOT NULL DEFAULT 'in_progress' CHECK (status IN (
    'in_progress', 'completed', 'uploaded', 'bid_generated', 'archived'
  )),
  started_at timestamptz DEFAULT now(),
  completed_at timestamptz,
  room_count int DEFAULT 0,
  photo_count int DEFAULT 0,
  notes text,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  deleted_at timestamptz
);

-- ── Walkthrough Rooms ──
CREATE TABLE IF NOT EXISTS walkthrough_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  walkthrough_id uuid NOT NULL REFERENCES walkthroughs(id) ON DELETE CASCADE,
  name text NOT NULL,
  floor_level text DEFAULT '1st Floor' CHECK (floor_level IN (
    'Basement', '1st Floor', '2nd Floor', '3rd Floor', 'Attic', 'Exterior', 'Roof'
  )),
  room_type text DEFAULT 'general',
  sort_order int DEFAULT 0,
  dimensions jsonb DEFAULT '{}', -- {length, width, height, sqft, lidar_raw}
  condition_tags text[] DEFAULT '{}', -- 'Damage', 'Replace', 'Repair', etc.
  material_tags text[] DEFAULT '{}', -- 'drywall', 'hardwood', 'tile', etc.
  notes text,
  voice_note_url text,
  voice_note_transcript text,
  lidar_scan_url text,
  photo_count int DEFAULT 0,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ── Walkthrough Photos ──
CREATE TABLE IF NOT EXISTS walkthrough_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  walkthrough_id uuid NOT NULL REFERENCES walkthroughs(id) ON DELETE CASCADE,
  room_id uuid REFERENCES walkthrough_rooms(id) ON DELETE SET NULL,
  storage_path text NOT NULL,
  thumbnail_path text,
  file_name text NOT NULL,
  photo_number int DEFAULT 1,
  photo_type text DEFAULT 'general' CHECK (photo_type IN (
    'general', 'damage', 'before', 'after', 'detail', 'wide', 'exterior', 'selfie'
  )),
  annotations jsonb, -- JSON overlay data (shapes, text, arrows)
  annotated_url text, -- rendered PNG with annotations
  gps_latitude double precision,
  gps_longitude double precision,
  compass_heading double precision,
  caption text,
  tags text[] DEFAULT '{}',
  ai_analysis jsonb, -- Claude Vision analysis results
  width int,
  height int,
  file_size int,
  created_at timestamptz DEFAULT now()
);

-- ── Walkthrough Templates ──
CREATE TABLE IF NOT EXISTS walkthrough_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id), -- null = system template
  name text NOT NULL,
  description text,
  walkthrough_type text NOT NULL DEFAULT 'general',
  property_type text DEFAULT 'residential',
  trade_type text, -- for trade-specific templates
  rooms jsonb NOT NULL DEFAULT '[]', -- [{name, floor_level, room_type, checklist_items}]
  checklist jsonb DEFAULT '[]', -- global checklist items
  required_photos jsonb DEFAULT '[]', -- [{room_type, description, min_count}]
  bid_format text DEFAULT 'standard', -- determines AI bid output format
  is_system boolean DEFAULT false,
  usage_count int DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ── Property Floor Plans ──
CREATE TABLE IF NOT EXISTS property_floor_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id),
  property_id uuid REFERENCES properties(id),
  walkthrough_id uuid REFERENCES walkthroughs(id),
  name text NOT NULL DEFAULT 'Main Floor',
  floor_level text DEFAULT '1st Floor',
  plan_data jsonb NOT NULL DEFAULT '{}', -- structured JSON: walls, doors, windows, fixtures, dimensions
  render_url text, -- rendered PNG for sharing
  lidar_mesh_url text, -- 3D mesh data from LiDAR
  width_ft double precision,
  height_ft double precision,
  scale_factor double precision DEFAULT 1.0,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ── ALTER existing tables ──

-- Add walkthrough links to bids
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bids' AND column_name = 'walkthrough_id') THEN
    ALTER TABLE bids ADD COLUMN walkthrough_id uuid REFERENCES walkthroughs(id);
  END IF;
END $$;

-- Add walkthrough links to jobs
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'jobs' AND column_name = 'walkthrough_id') THEN
    ALTER TABLE jobs ADD COLUMN walkthrough_id uuid REFERENCES walkthroughs(id);
  END IF;
END $$;

-- ── Indexes ──
CREATE INDEX IF NOT EXISTS idx_walkthroughs_company ON walkthroughs(company_id);
CREATE INDEX IF NOT EXISTS idx_walkthroughs_customer ON walkthroughs(customer_id);
CREATE INDEX IF NOT EXISTS idx_walkthroughs_job ON walkthroughs(job_id);
CREATE INDEX IF NOT EXISTS idx_walkthroughs_status ON walkthroughs(status);
CREATE INDEX IF NOT EXISTS idx_walkthrough_rooms_walkthrough ON walkthrough_rooms(walkthrough_id);
CREATE INDEX IF NOT EXISTS idx_walkthrough_photos_walkthrough ON walkthrough_photos(walkthrough_id);
CREATE INDEX IF NOT EXISTS idx_walkthrough_photos_room ON walkthrough_photos(room_id);
CREATE INDEX IF NOT EXISTS idx_floor_plans_property ON property_floor_plans(property_id);
CREATE INDEX IF NOT EXISTS idx_floor_plans_walkthrough ON property_floor_plans(walkthrough_id);

-- ── RLS ──
ALTER TABLE walkthroughs ENABLE ROW LEVEL SECURITY;
ALTER TABLE walkthrough_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE walkthrough_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE walkthrough_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_floor_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY walkthroughs_company ON walkthroughs FOR ALL USING (
  company_id IN (SELECT company_id FROM users WHERE id = auth.uid())
);
CREATE POLICY walkthrough_rooms_via_walkthrough ON walkthrough_rooms FOR ALL USING (
  walkthrough_id IN (SELECT id FROM walkthroughs WHERE company_id IN (SELECT company_id FROM users WHERE id = auth.uid()))
);
CREATE POLICY walkthrough_photos_via_walkthrough ON walkthrough_photos FOR ALL USING (
  walkthrough_id IN (SELECT id FROM walkthroughs WHERE company_id IN (SELECT company_id FROM users WHERE id = auth.uid()))
);
CREATE POLICY walkthrough_templates_access ON walkthrough_templates FOR ALL USING (
  is_system = true OR company_id IN (SELECT company_id FROM users WHERE id = auth.uid())
);
CREATE POLICY floor_plans_company ON property_floor_plans FOR ALL USING (
  company_id IN (SELECT company_id FROM users WHERE id = auth.uid())
);

-- ── Audit Triggers ──
CREATE TRIGGER set_walkthroughs_updated BEFORE UPDATE ON walkthroughs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_walkthrough_rooms_updated BEFORE UPDATE ON walkthrough_rooms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_walkthrough_templates_updated BEFORE UPDATE ON walkthrough_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_floor_plans_updated BEFORE UPDATE ON property_floor_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Seed System Templates ──
INSERT INTO walkthrough_templates (name, description, walkthrough_type, property_type, trade_type, rooms, checklist, required_photos, bid_format, is_system)
VALUES
  ('Kitchen Remodel', 'Standard kitchen renovation walkthrough', 'general', 'residential', NULL,
   '[{"name":"Kitchen","floor_level":"1st Floor","room_type":"kitchen","checklist_items":["Cabinets","Countertops","Backsplash","Flooring","Lighting","Plumbing fixtures","Appliances","Electrical outlets","Ventilation"]},{"name":"Adjacent Hallway","floor_level":"1st Floor","room_type":"hallway","checklist_items":["Transition flooring","Wall repair","Painting"]}]',
   '["Measure all walls","Photo all existing appliances","Check electrical panel capacity","Verify plumbing locations"]',
   '[{"room_type":"kitchen","description":"Wide shot of full kitchen","min_count":2},{"room_type":"kitchen","description":"Close-up of each wall","min_count":4}]',
   'standard', true),

  ('Bathroom Remodel', 'Standard bathroom renovation walkthrough', 'general', 'residential', NULL,
   '[{"name":"Bathroom","floor_level":"1st Floor","room_type":"bathroom","checklist_items":["Tub/Shower","Vanity","Toilet","Flooring","Tile","Lighting","Ventilation fan","Mirror","Accessories"]}]',
   '["Check for water damage behind tub surround","Verify drain locations","Measure vanity space","Photo existing fixtures"]',
   '[{"room_type":"bathroom","description":"Full room shot from door","min_count":1},{"room_type":"bathroom","description":"Close-up of each fixture","min_count":3}]',
   'standard', true),

  ('Whole House Renovation', 'Full property renovation walkthrough', 'general', 'residential', NULL,
   '[{"name":"Exterior Front","floor_level":"Exterior","room_type":"exterior"},{"name":"Exterior Back","floor_level":"Exterior","room_type":"exterior"},{"name":"Living Room","floor_level":"1st Floor","room_type":"living"},{"name":"Kitchen","floor_level":"1st Floor","room_type":"kitchen"},{"name":"Dining Room","floor_level":"1st Floor","room_type":"dining"},{"name":"Master Bedroom","floor_level":"2nd Floor","room_type":"bedroom"},{"name":"Master Bathroom","floor_level":"2nd Floor","room_type":"bathroom"},{"name":"Bedroom 2","floor_level":"2nd Floor","room_type":"bedroom"},{"name":"Bedroom 3","floor_level":"2nd Floor","room_type":"bedroom"},{"name":"Hall Bathroom","floor_level":"2nd Floor","room_type":"bathroom"},{"name":"Garage","floor_level":"1st Floor","room_type":"garage"},{"name":"Basement","floor_level":"Basement","room_type":"basement"}]',
   '["Full exterior walk-around","Check roof condition","Inspect foundation","Verify HVAC system","Check electrical panel","Photo utility meters"]',
   '[]', 'standard', true),

  ('Water Damage Restoration', 'Insurance water damage claim walkthrough', 'insurance_restoration', 'residential', NULL,
   '[{"name":"Source Area","floor_level":"1st Floor","room_type":"source","checklist_items":["Identify water source","Measure affected area","Check moisture levels","Photo water lines"]},{"name":"Primary Damage","floor_level":"1st Floor","room_type":"damage","checklist_items":["Drywall damage","Flooring damage","Baseboards","Cabinets","Contents affected"]},{"name":"Secondary Damage","floor_level":"1st Floor","room_type":"damage","checklist_items":["Adjacent room spread","Ceiling damage below","Mold presence","Odor"]}]',
   '["Document water source","Moisture readings with pin meter","Photo category of water","Document all affected materials","Check for mold (visual + smell)"]',
   '[{"room_type":"source","description":"Water source close-up","min_count":2},{"room_type":"damage","description":"Full room damage overview","min_count":2},{"room_type":"damage","description":"Close-up of damaged materials","min_count":4}]',
   'xactimate', true),

  ('Fire Damage Restoration', 'Insurance fire damage claim walkthrough', 'insurance_restoration', 'residential', NULL,
   '[{"name":"Origin Area","floor_level":"1st Floor","room_type":"origin","checklist_items":["Fire origin point","Char patterns","Structural damage","Smoke damage extent"]},{"name":"Smoke Damage","floor_level":"1st Floor","room_type":"smoke","checklist_items":["Smoke staining","Soot deposits","Odor severity","HVAC contamination"]},{"name":"Contents","floor_level":"1st Floor","room_type":"contents","checklist_items":["Damaged items inventory","Salvageable items","Pack-out needed"]}]',
   '["Document fire origin","Photo char patterns for cause investigation","Measure smoke damage extent","Check structural integrity","Document contents damage"]',
   '[]', 'xactimate', true),

  ('Wind/Storm Damage', 'Insurance storm damage claim walkthrough', 'insurance_restoration', 'residential', NULL,
   '[{"name":"Roof","floor_level":"Roof","room_type":"roof","checklist_items":["Missing shingles","Lifted shingles","Hail impacts","Ridge damage","Flashing","Gutters"]},{"name":"Exterior","floor_level":"Exterior","room_type":"exterior","checklist_items":["Siding damage","Window damage","Door damage","Fence/landscape","Trees/debris"]},{"name":"Interior","floor_level":"1st Floor","room_type":"interior","checklist_items":["Ceiling leaks","Window leaks","Water stains","Structural movement"]}]',
   '["Photo roof from ground (all 4 sides)","Close-up of each damage point","Document debris field","Check attic for leaks","Photo hail damage on soft metals (AC units, vents)"]',
   '[]', 'xactimate', true),

  ('Electrical Inspection', 'Trade-specific electrical walkthrough', 'trade_specific', 'residential', 'electrical',
   '[{"name":"Main Panel","floor_level":"1st Floor","room_type":"electrical","checklist_items":["Panel brand/model","Amp rating","Available spaces","Wire types","Grounding","Labeling"]},{"name":"Sub Panel","floor_level":"1st Floor","room_type":"electrical","checklist_items":["Location","Rating","Feed wire size"]},{"name":"Kitchen Circuits","floor_level":"1st Floor","room_type":"kitchen","checklist_items":["GFCI protection","Dedicated circuits","Appliance circuits"]},{"name":"Bathroom Circuits","floor_level":"1st Floor","room_type":"bathroom","checklist_items":["GFCI protection","Vent fan circuit","Lighting"]},{"name":"Outdoor","floor_level":"Exterior","room_type":"exterior","checklist_items":["Weatherproof outlets","Landscape lighting","Pool/spa equipment"]}]',
   '["Photo panel with cover off","Photo panel schedule","Check GFCI outlets in wet areas","Verify smoke/CO detector locations","Note any aluminum wiring","Check for double-tapped breakers"]',
   '[]', 'standard', true),

  ('Plumbing Inspection', 'Trade-specific plumbing walkthrough', 'trade_specific', 'residential', 'plumbing',
   '[{"name":"Water Entry","floor_level":"1st Floor","room_type":"plumbing","checklist_items":["Main shutoff location","Pipe material","Water pressure","PRV present"]},{"name":"Water Heater","floor_level":"1st Floor","room_type":"plumbing","checklist_items":["Type/size","Age","Condition","T&P valve","Drain pan"]},{"name":"Kitchen","floor_level":"1st Floor","room_type":"kitchen","checklist_items":["Faucet condition","Disposal","Dishwasher supply/drain","Under sink condition"]},{"name":"Bathrooms","floor_level":"1st Floor","room_type":"bathroom","checklist_items":["Fixtures condition","Drain speed","Toilet condition","Shower valve type"]},{"name":"Sewer/Drain","floor_level":"Basement","room_type":"plumbing","checklist_items":["Cleanout location","Sewer material","Sump pump","Backflow prevention"]}]',
   '["Check water pressure at hose bib","Photo all shutoff valves","Note pipe materials throughout","Photo water heater data plate","Check for active leaks","Photo sewer cleanout"]',
   '[]', 'standard', true),

  ('HVAC Inspection', 'Trade-specific HVAC walkthrough', 'trade_specific', 'residential', 'hvac',
   '[{"name":"Outdoor Unit","floor_level":"Exterior","room_type":"hvac","checklist_items":["Brand/model/serial","Age","Refrigerant type","Condition","Clearance"]},{"name":"Indoor Unit","floor_level":"1st Floor","room_type":"hvac","checklist_items":["Brand/model/serial","Filter size/condition","Drain line","Blower condition"]},{"name":"Ductwork","floor_level":"1st Floor","room_type":"hvac","checklist_items":["Material","Insulation","Connections","Dampers","Returns"]},{"name":"Thermostat","floor_level":"1st Floor","room_type":"hvac","checklist_items":["Type","Location","Programming","Zoning"]}]',
   '["Photo data plates on all units","Measure temperature split at supply/return","Photo filter condition","Check refrigerant pressures if tools available","Photo ductwork connections","Note any unusual noises"]',
   '[]', 'standard', true),

  ('Roofing Inspection', 'Trade-specific roofing walkthrough', 'trade_specific', 'residential', 'roofing',
   '[{"name":"Roof Overview","floor_level":"Roof","room_type":"roof","checklist_items":["Material type","Approximate age","Layers visible","General condition"]},{"name":"North Slope","floor_level":"Roof","room_type":"roof"},{"name":"South Slope","floor_level":"Roof","room_type":"roof"},{"name":"East Slope","floor_level":"Roof","room_type":"roof"},{"name":"West Slope","floor_level":"Roof","room_type":"roof"},{"name":"Penetrations","floor_level":"Roof","room_type":"roof","checklist_items":["Vents","Pipes","Chimneys","Skylights","Flashing condition"]},{"name":"Gutters","floor_level":"Exterior","room_type":"exterior","checklist_items":["Material","Condition","Downspouts","Guards"]},{"name":"Attic","floor_level":"Attic","room_type":"attic","checklist_items":["Ventilation","Insulation","Decking condition","Leak evidence"]}]',
   '["Measure roof from ground or satellite","Photo each slope from ground","Close-up of any damage areas","Photo all penetrations","Check attic ventilation","Photo gutter condition"]',
   '[]', 'standard', true),

  ('Pre-Purchase Inspection', 'Property inspection for buyers', 'property_inspection', 'residential', NULL,
   '[{"name":"Exterior Front","floor_level":"Exterior","room_type":"exterior"},{"name":"Exterior Back","floor_level":"Exterior","room_type":"exterior"},{"name":"Exterior Sides","floor_level":"Exterior","room_type":"exterior"},{"name":"Roof","floor_level":"Roof","room_type":"roof"},{"name":"Foundation","floor_level":"Exterior","room_type":"foundation"},{"name":"Garage","floor_level":"1st Floor","room_type":"garage"},{"name":"Living Areas","floor_level":"1st Floor","room_type":"living"},{"name":"Kitchen","floor_level":"1st Floor","room_type":"kitchen"},{"name":"Bathrooms","floor_level":"1st Floor","room_type":"bathroom"},{"name":"Bedrooms","floor_level":"2nd Floor","room_type":"bedroom"},{"name":"Attic","floor_level":"Attic","room_type":"attic"},{"name":"Basement","floor_level":"Basement","room_type":"basement"},{"name":"Mechanical","floor_level":"Basement","room_type":"mechanical"},{"name":"Electrical","floor_level":"1st Floor","room_type":"electrical"}]',
   '["Full exterior walk-around","Check all windows and doors operate","Run all faucets","Flush all toilets","Check HVAC operation","Check electrical panel","Photo any defects found","Check for moisture in basement"]',
   '[]', 'inspection_report', true),

  ('Commercial Buildout', 'Commercial tenant improvement walkthrough', 'commercial', 'commercial', NULL,
   '[{"name":"Exterior/Entry","floor_level":"1st Floor","room_type":"exterior"},{"name":"Reception/Lobby","floor_level":"1st Floor","room_type":"lobby"},{"name":"Open Office","floor_level":"1st Floor","room_type":"office"},{"name":"Private Offices","floor_level":"1st Floor","room_type":"office"},{"name":"Conference Room","floor_level":"1st Floor","room_type":"conference"},{"name":"Break Room","floor_level":"1st Floor","room_type":"kitchen"},{"name":"Restrooms","floor_level":"1st Floor","room_type":"bathroom"},{"name":"Storage/IT","floor_level":"1st Floor","room_type":"storage"},{"name":"Mechanical Room","floor_level":"1st Floor","room_type":"mechanical"},{"name":"Ceiling Plenum","floor_level":"1st Floor","room_type":"ceiling"}]',
   '["Verify lease requirements","Check ADA compliance","Document existing conditions","Measure all spaces","Photo fire suppression system","Note ceiling height and type","Check electrical capacity"]',
   '[]', 'standard', true),

  ('Move-In/Move-Out Inspection', 'Rental property condition report', 'property_inspection', 'residential', NULL,
   '[{"name":"Exterior","floor_level":"Exterior","room_type":"exterior"},{"name":"Entry/Hallway","floor_level":"1st Floor","room_type":"hallway"},{"name":"Living Room","floor_level":"1st Floor","room_type":"living"},{"name":"Kitchen","floor_level":"1st Floor","room_type":"kitchen"},{"name":"Dining Area","floor_level":"1st Floor","room_type":"dining"},{"name":"Master Bedroom","floor_level":"1st Floor","room_type":"bedroom"},{"name":"Master Bathroom","floor_level":"1st Floor","room_type":"bathroom"},{"name":"Bedroom 2","floor_level":"1st Floor","room_type":"bedroom"},{"name":"Bathroom 2","floor_level":"1st Floor","room_type":"bathroom"},{"name":"Laundry","floor_level":"1st Floor","room_type":"laundry"},{"name":"Garage","floor_level":"1st Floor","room_type":"garage"},{"name":"Yard","floor_level":"Exterior","room_type":"exterior"}]',
   '["Photo each wall of each room","Document any existing damage","Check all appliances operate","Test all faucets and drains","Check all windows/doors lock","Photo all fixtures","Check smoke/CO detectors"]',
   '[]', 'inspection_report', true)
ON CONFLICT DO NOTHING;
