-- E5a: Xactimate Estimate Engine — Pricing Database Foundation
-- 4 new tables + ALTER existing xactimate_estimate_lines

-- Master code registry (27,000+ codes from published Xactimate documentation)
CREATE TABLE xactimate_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_code TEXT NOT NULL,         -- 2-3 letter code (RFG, DRY, ELE, etc.)
  category_name TEXT NOT NULL,         -- Full name (Roofing, Drywall, Electrical)
  selector_code TEXT NOT NULL,         -- 3-4+ letter code (SHGL, HANG12, etc.)
  full_code TEXT NOT NULL,             -- Combined: 'RFG SHGL'
  description TEXT NOT NULL,           -- Human-readable description
  unit TEXT NOT NULL DEFAULT 'EA',     -- Measurement unit (EA, LF, SF, SY, HR, DA, LS, CF, CY)
  coverage_group TEXT NOT NULL DEFAULT 'structural'
    CHECK (coverage_group IN ('structural', 'contents', 'other')),
  has_material BOOLEAN DEFAULT true,
  has_labor BOOLEAN DEFAULT true,
  has_equipment BOOLEAN DEFAULT false,
  is_system BOOLEAN DEFAULT true,      -- ZAFTO-maintained vs user-added
  deprecated BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(full_code)
);

-- Full-text search index on code description
CREATE INDEX idx_xact_codes_fts ON xactimate_codes USING gin(to_tsvector('english', description));
CREATE INDEX idx_xact_codes_category ON xactimate_codes(category_code);
CREATE INDEX idx_xact_codes_full ON xactimate_codes(full_code);

-- RLS: readable by all authenticated users (reference data)
ALTER TABLE xactimate_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY xact_codes_read ON xactimate_codes FOR SELECT USING (true);

-- Regional pricing data
CREATE TABLE pricing_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_id UUID NOT NULL REFERENCES xactimate_codes(id),
  region_code TEXT NOT NULL,           -- ZIP code or region identifier
  material_cost NUMERIC(12,2) DEFAULT 0,
  labor_cost NUMERIC(12,2) DEFAULT 0,
  equipment_cost NUMERIC(12,2) DEFAULT 0,
  total_cost NUMERIC(12,2) GENERATED ALWAYS AS (material_cost + labor_cost + equipment_cost) STORED,
  source TEXT NOT NULL DEFAULT 'crowd'
    CHECK (source IN ('crowd', 'manual', 'import', 'ai_extracted')),
  source_count INTEGER DEFAULT 1,      -- How many data points this is based on
  confidence TEXT DEFAULT 'low'
    CHECK (confidence IN ('low', 'medium', 'high', 'verified')),
  effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
  expires_date DATE,                   -- NULL = no expiry
  company_id UUID REFERENCES companies(id), -- NULL = global, set = company override
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(code_id, region_code, company_id, effective_date)
);

CREATE INDEX idx_pricing_code_region ON pricing_entries(code_id, region_code);
CREATE INDEX idx_pricing_company ON pricing_entries(company_id)
  WHERE company_id IS NOT NULL;
CREATE INDEX idx_pricing_expires ON pricing_entries(expires_date) WHERE expires_date IS NOT NULL;

-- RLS: global entries readable by all, company entries scoped
ALTER TABLE pricing_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY pricing_read ON pricing_entries FOR SELECT
  USING (company_id IS NULL OR company_id = requesting_company_id());
CREATE POLICY pricing_write ON pricing_entries FOR ALL
  USING (company_id = requesting_company_id());

-- Reusable estimate templates
CREATE TABLE estimate_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  description TEXT,
  trade_type TEXT,                     -- 'electrical', 'plumbing', 'hvac', 'roofing', etc.
  loss_type TEXT,                      -- 'water', 'fire', 'wind', 'mold', etc.
  line_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Each item: { code, description, qty, unit, notes }
  is_system BOOLEAN DEFAULT false,     -- ZAFTO-provided vs user-created
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE estimate_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY estimate_templates_company ON estimate_templates
  USING (company_id = requesting_company_id() OR is_system = true);

-- Anonymized pricing data from user jobs
CREATE TABLE pricing_contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_id UUID NOT NULL REFERENCES xactimate_codes(id),
  region_code TEXT NOT NULL,           -- ZIP from job address
  material_cost NUMERIC(12,2),
  labor_cost NUMERIC(12,2),
  equipment_cost NUMERIC(12,2),
  source_type TEXT NOT NULL DEFAULT 'invoice'
    CHECK (source_type IN ('invoice', 'bid', 'manual', 'estimate')),
  -- Anonymized — NO company_id or job_id stored
  contributed_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_contributions_code ON pricing_contributions(code_id, region_code);

-- No company RLS needed — anonymized aggregate data
-- Readable by system only (via service role), not by regular users
ALTER TABLE pricing_contributions ENABLE ROW LEVEL SECURITY;

-- ESX imports tracking
CREATE TABLE esx_imports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  claim_id UUID REFERENCES insurance_claims(id),
  file_name TEXT NOT NULL,
  file_size INTEGER,
  storage_path TEXT,                   -- Supabase Storage path
  parse_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (parse_status IN ('pending', 'parsing', 'complete', 'failed')),
  parse_errors JSONB DEFAULT '[]'::jsonb,
  extracted_lines INTEGER DEFAULT 0,
  xactdoc_version TEXT,               -- Xactimate version detected
  metadata JSONB DEFAULT '{}'::jsonb,  -- Carrier, adjuster, dates, etc.
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE esx_imports ENABLE ROW LEVEL SECURITY;
CREATE POLICY esx_imports_company ON esx_imports
  USING (company_id = requesting_company_id());

-- ALTER existing xactimate_estimate_lines — add E5 columns
ALTER TABLE xactimate_estimate_lines
  ADD COLUMN IF NOT EXISTS code_id UUID REFERENCES xactimate_codes(id),
  ADD COLUMN IF NOT EXISTS material_cost NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS labor_cost NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS equipment_cost NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS room_name TEXT,
  ADD COLUMN IF NOT EXISTS line_number INTEGER,
  ADD COLUMN IF NOT EXISTS coverage_group TEXT DEFAULT 'structural'
    CHECK (coverage_group IN ('structural', 'contents', 'other'));

CREATE INDEX idx_xact_lines_code ON xactimate_estimate_lines(code_id) WHERE code_id IS NOT NULL;

-- Audit triggers
CREATE TRIGGER pricing_entries_updated BEFORE UPDATE ON pricing_entries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER estimate_templates_updated BEFORE UPDATE ON estimate_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Seed initial category codes (top-level categories only — full 27K codes seeded separately)
INSERT INTO xactimate_codes (category_code, category_name, selector_code, full_code, description, unit, coverage_group, has_material, has_labor, has_equipment) VALUES
-- Demolition
('DMO', 'Demolition', 'DRYWALL', 'DMO DRYWALL', 'Remove drywall', 'SF', 'structural', false, true, false),
('DMO', 'Demolition', 'BASEBOARD', 'DMO BASEBOARD', 'Remove baseboard', 'LF', 'structural', false, true, false),
('DMO', 'Demolition', 'FLOORING', 'DMO FLOORING', 'Remove flooring', 'SF', 'structural', false, true, false),
('DMO', 'Demolition', 'CARPET', 'DMO CARPET', 'Remove carpet', 'SY', 'structural', false, true, false),
('DMO', 'Demolition', 'CABINETRY', 'DMO CABINETRY', 'Remove cabinetry', 'LF', 'structural', false, true, false),
('DMO', 'Demolition', 'INSULATION', 'DMO INSULATION', 'Remove insulation', 'SF', 'structural', false, true, false),
-- Drywall
('DRY', 'Drywall', 'HANG12', 'DRY HANG12', 'Hang 1/2" drywall', 'SF', 'structural', true, true, false),
('DRY', 'Drywall', 'HANG58', 'DRY HANG58', 'Hang 5/8" drywall', 'SF', 'structural', true, true, false),
('DRY', 'Drywall', 'TAPE', 'DRY TAPE', 'Tape and float drywall', 'SF', 'structural', true, true, false),
('DRY', 'Drywall', 'TEXTURE', 'DRY TEXTURE', 'Texture drywall', 'SF', 'structural', true, true, false),
-- Electrical
('ELE', 'Electrical', 'OUTLET', 'ELE OUTLET', 'Install outlet (standard)', 'EA', 'structural', true, true, false),
('ELE', 'Electrical', 'SWITCH', 'ELE SWITCH', 'Install switch (standard)', 'EA', 'structural', true, true, false),
('ELE', 'Electrical', 'LIGHT', 'ELE LIGHT', 'Install light fixture', 'EA', 'structural', true, true, false),
('ELE', 'Electrical', 'PANEL', 'ELE PANEL', 'Install electrical panel', 'EA', 'structural', true, true, false),
('ELE', 'Electrical', 'WIRE', 'ELE WIRE', 'Run electrical wire (14/2 NM-B)', 'LF', 'structural', true, true, false),
-- Framing
('FRM', 'Framing', 'WALL24', 'FRM WALL24', 'Frame wall 2x4', 'LF', 'structural', true, true, false),
('FRM', 'Framing', 'WALL26', 'FRM WALL26', 'Frame wall 2x6', 'LF', 'structural', true, true, false),
('FRM', 'Framing', 'HEADER', 'FRM HEADER', 'Install header', 'EA', 'structural', true, true, false),
-- Flooring
('FCV', 'Floor Covering - Vinyl/Resilient', 'LVP', 'FCV LVP', 'Install luxury vinyl plank', 'SF', 'structural', true, true, false),
('FCT', 'Floor Covering - Tile', 'CERAMIC', 'FCT CERAMIC', 'Install ceramic tile', 'SF', 'structural', true, true, false),
('FCW', 'Floor Covering - Wood', 'HARDWOOD', 'FCW HARDWOOD', 'Install hardwood flooring', 'SF', 'structural', true, true, false),
('FCC', 'Floor Covering - Carpet', 'CARPET', 'FCC CARPET', 'Install carpet', 'SY', 'structural', true, true, false),
-- HVAC
('HVC', 'HVAC', 'DUCT', 'HVC DUCT', 'Install ductwork', 'LF', 'structural', true, true, false),
('HVC', 'HVAC', 'FURNACE', 'HVC FURNACE', 'Install furnace', 'EA', 'structural', true, true, true),
('HVC', 'HVAC', 'CONDENSER', 'HVC CONDENSER', 'Install AC condenser', 'EA', 'structural', true, true, true),
-- Insulation
('INS', 'Insulation', 'BATT', 'INS BATT', 'Install batt insulation', 'SF', 'structural', true, true, false),
('INS', 'Insulation', 'BLOWN', 'INS BLOWN', 'Install blown insulation', 'SF', 'structural', true, true, true),
-- Painting
('PNT', 'Painting', 'WALL', 'PNT WALL', 'Paint wall (2 coats)', 'SF', 'structural', true, true, false),
('PNT', 'Painting', 'CEILING', 'PNT CEILING', 'Paint ceiling (2 coats)', 'SF', 'structural', true, true, false),
('PNT', 'Painting', 'TRIM', 'PNT TRIM', 'Paint trim/baseboard', 'LF', 'structural', true, true, false),
('PNT', 'Painting', 'DOOR', 'PNT DOOR', 'Paint door (both sides)', 'EA', 'structural', true, true, false),
-- Plumbing
('PLM', 'Plumbing', 'TOILET', 'PLM TOILET', 'Install toilet', 'EA', 'structural', true, true, false),
('PLM', 'Plumbing', 'SINK', 'PLM SINK', 'Install sink', 'EA', 'structural', true, true, false),
('PLM', 'Plumbing', 'FAUCET', 'PLM FAUCET', 'Install faucet', 'EA', 'structural', true, true, false),
('PLM', 'Plumbing', 'WATERHEATER', 'PLM WATERHEATER', 'Install water heater', 'EA', 'structural', true, true, false),
-- Roofing
('RFG', 'Roofing', 'SHGL', 'RFG SHGL', 'Install asphalt shingles', 'SQ', 'structural', true, true, false),
('RFG', 'Roofing', 'FELT', 'RFG FELT', 'Install roofing felt/underlayment', 'SQ', 'structural', true, true, false),
('RFG', 'Roofing', 'FLASH', 'RFG FLASH', 'Install flashing', 'LF', 'structural', true, true, false),
('RFG', 'Roofing', 'RIDGE', 'RFG RIDGE', 'Install ridge cap', 'LF', 'structural', true, true, false),
('RFG', 'Roofing', 'DRIP', 'RFG DRIP', 'Install drip edge', 'LF', 'structural', true, true, false),
-- Doors
('DOR', 'Doors', 'INT', 'DOR INT', 'Install interior door (pre-hung)', 'EA', 'structural', true, true, false),
('DOR', 'Doors', 'EXT', 'DOR EXT', 'Install exterior door (pre-hung)', 'EA', 'structural', true, true, false),
-- Windows
('WDW', 'Windows', 'STD', 'WDW STD', 'Install standard window', 'EA', 'structural', true, true, false),
('WDW', 'Windows', 'SLIDER', 'WDW SLIDER', 'Install sliding window', 'EA', 'structural', true, true, false),
-- Cabinets
('CAB', 'Cabinets', 'BASE', 'CAB BASE', 'Install base cabinet', 'LF', 'structural', true, true, false),
('CAB', 'Cabinets', 'WALL', 'CAB WALL', 'Install wall cabinet', 'LF', 'structural', true, true, false),
('CAB', 'Cabinets', 'COUNTERTOP', 'CAB COUNTERTOP', 'Install countertop', 'LF', 'structural', true, true, false),
-- Siding
('SDG', 'Siding', 'VINYL', 'SDG VINYL', 'Install vinyl siding', 'SF', 'structural', true, true, false),
('SDG', 'Siding', 'WOOD', 'SDG WOOD', 'Install wood siding', 'SF', 'structural', true, true, false),
-- Concrete/Masonry
('CNC', 'Concrete', 'SLAB', 'CNC SLAB', 'Pour concrete slab', 'SF', 'structural', true, true, true),
('MAS', 'Masonry', 'BRICK', 'MAS BRICK', 'Install brick', 'SF', 'structural', true, true, false),
-- Tile
('TIL', 'Tile', 'WALL', 'TIL WALL', 'Install wall tile', 'SF', 'structural', true, true, false),
('TIL', 'Tile', 'FLOOR', 'TIL FLOOR', 'Install floor tile', 'SF', 'structural', true, true, false),
('TIL', 'Tile', 'SHOWER', 'TIL SHOWER', 'Install shower tile', 'SF', 'structural', true, true, false),
-- Cleaning
('CLN', 'Cleaning', 'GENERAL', 'CLN GENERAL', 'General cleaning', 'SF', 'structural', true, true, false),
('CLN', 'Cleaning', 'CARPET', 'CLN CARPET', 'Clean carpet', 'SF', 'structural', true, true, true),
('CLN', 'Cleaning', 'MOLD', 'CLN MOLD', 'Mold remediation cleaning', 'SF', 'structural', true, true, true),
-- Water Extraction/Remediation
('WTR', 'Water Extraction/Remediation', 'EXTRACT', 'WTR EXTRACT', 'Water extraction', 'SF', 'structural', false, true, true),
('WTR', 'Water Extraction/Remediation', 'DRY', 'WTR DRY', 'Structural drying', 'SF', 'structural', false, true, true),
('WTR', 'Water Extraction/Remediation', 'DEHU', 'WTR DEHU', 'Dehumidifier (per day)', 'DA', 'structural', false, false, true),
('WTR', 'Water Extraction/Remediation', 'AIRMOVER', 'WTR AIRMOVER', 'Air mover (per day)', 'DA', 'structural', false, false, true),
-- Contents
('CON', 'Contents', 'PACKOUT', 'CON PACKOUT', 'Contents pack-out', 'HR', 'contents', false, true, false),
('CON', 'Contents', 'STORAGE', 'CON STORAGE', 'Contents storage (per month)', 'EA', 'contents', false, false, true),
('CON', 'Contents', 'CLEANING', 'CON CLEANING', 'Contents cleaning', 'HR', 'contents', true, true, false),
-- Appliances (Contents category)
('APP', 'Appliances', 'FRIDGE', 'APP FRIDGE', 'Refrigerator', 'EA', 'contents', true, true, false),
('APP', 'Appliances', 'RANGE', 'APP RANGE', 'Range/Stove', 'EA', 'contents', true, true, false),
('APP', 'Appliances', 'DISHWASHER', 'APP DISHWASHER', 'Dishwasher', 'EA', 'contents', true, true, false),
('APP', 'Appliances', 'WASHER', 'APP WASHER', 'Washing machine', 'EA', 'contents', true, true, false),
('APP', 'Appliances', 'DRYER', 'APP DRYER', 'Dryer', 'EA', 'contents', true, true, false),
-- Temporary/Other
('TMP', 'Temporary Repairs', 'TARP', 'TMP TARP', 'Emergency tarping', 'SQ', 'other', true, true, false),
('TMP', 'Temporary Repairs', 'BOARDUP', 'TMP BOARDUP', 'Board-up', 'SF', 'other', true, true, false),
('FEE', 'Fees', 'PERMIT', 'FEE PERMIT', 'Building permit', 'EA', 'other', false, false, false),
('FEE', 'Fees', 'DUMPSTER', 'FEE DUMPSTER', 'Dumpster/debris removal', 'EA', 'other', false, false, true),
('FEE', 'Fees', 'PORTAPOTTY', 'FEE PORTAPOTTY', 'Portable toilet rental', 'EA', 'other', false, false, true),
('LAB', 'General Labor', 'HELPER', 'LAB HELPER', 'General labor - helper', 'HR', 'structural', false, true, false),
('LAB', 'General Labor', 'SKILLED', 'LAB SKILLED', 'General labor - skilled', 'HR', 'structural', false, true, false),
('LAB', 'General Labor', 'SUPERVISOR', 'LAB SUPERVISOR', 'Supervision/project management', 'HR', 'other', false, true, false);
