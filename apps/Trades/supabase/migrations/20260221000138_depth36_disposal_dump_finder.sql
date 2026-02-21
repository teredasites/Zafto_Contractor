-- DEPTH36: Disposal & Dump Finder
-- Universal disposal facility finder for ALL trades.
-- Cheapest per-ton by waste type, nearest by distance,
-- scrap/recycling value, receipt tracking, cost analytics.

-- ============================================================================
-- DISPOSAL FACILITIES (system-wide + contractor-submitted)
-- ============================================================================

CREATE TABLE IF NOT EXISTS disposal_facilities (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid REFERENCES companies(id),  -- NULL = system-wide, set = contractor-submitted
  name              text NOT NULL,
  address           text,
  city              text,
  state_code        text,
  zip_code          text,
  latitude          numeric(10,7),
  longitude         numeric(10,7),
  phone             text,
  website           text,
  hours_json        jsonb DEFAULT '{}',  -- {mon: "7:00-17:00", tue: "7:00-17:00", ...}
  facility_type     text NOT NULL CHECK (facility_type IN (
    'landfill', 'transfer_station', 'recycling_center', 'scrap_yard',
    'hazmat_facility', 'composting_facility', 'concrete_recycler',
    'e_waste_facility', 'tire_recycler', 'asbestos_disposal',
    'biohazard_facility', 'metal_recycler', 'other'
  )),
  accepted_waste_types jsonb NOT NULL DEFAULT '[]',
  pricing_json      jsonb DEFAULT '[]',  -- [{waste_type, price_per_ton, price_per_yard, min_charge, notes}]
  weight_limit_tons numeric(8,1),
  permit_required   boolean DEFAULT false,
  permit_details    text,
  special_instructions text,
  data_source       text CHECK (data_source IS NULL OR data_source IN (
    'epa_frs', 'state_agency', 'county_directory', 'contractor_submitted', 'google_places', 'manual'
  )),
  external_id       text,  -- EPA FRS ID or state facility ID
  verified          boolean DEFAULT false,
  verified_at       timestamptz,
  is_active         boolean DEFAULT true,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

CREATE INDEX idx_disposal_fac_type ON disposal_facilities (facility_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_disposal_fac_state ON disposal_facilities (state_code) WHERE deleted_at IS NULL;
CREATE INDEX idx_disposal_fac_coords ON disposal_facilities (latitude, longitude) WHERE deleted_at IS NULL;
CREATE INDEX idx_disposal_fac_company ON disposal_facilities (company_id) WHERE deleted_at IS NULL;

ALTER TABLE disposal_facilities ENABLE ROW LEVEL SECURITY;

-- System facilities visible to all; contractor-submitted visible to their company
CREATE POLICY "disposal_fac_select" ON disposal_facilities
  FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL AND (
      company_id IS NULL
      OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );

CREATE POLICY "disposal_fac_insert" ON disposal_facilities
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "disposal_fac_update" ON disposal_facilities
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('disposal_facilities');
SELECT audit_trigger_fn('disposal_facilities');

-- ============================================================================
-- SCRAP/RECYCLING PRICE INDEX (system-wide reference)
-- ============================================================================

CREATE TABLE IF NOT EXISTS scrap_price_index (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  material          text NOT NULL,  -- copper, aluminum, steel, brass, stainless, lead, etc.
  grade             text,           -- #1 copper, #2 copper, insulated wire, etc.
  price_per_lb      numeric(8,4),
  price_per_ton     numeric(10,2),
  unit              text NOT NULL DEFAULT 'lb',
  region            text DEFAULT 'national',
  source            text,           -- isri, kitco, scrapmonster, manual
  effective_date    date NOT NULL DEFAULT CURRENT_DATE,
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_scrap_price_material ON scrap_price_index (material, effective_date DESC);

ALTER TABLE scrap_price_index ENABLE ROW LEVEL SECURITY;

CREATE POLICY "scrap_price_select" ON scrap_price_index
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "scrap_price_system" ON scrap_price_index
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- DUMP RECEIPTS (company-scoped, linked to jobs/work orders)
-- ============================================================================

CREATE TABLE IF NOT EXISTS dump_receipts (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  facility_id       uuid REFERENCES disposal_facilities(id),
  job_id            uuid REFERENCES jobs(id),
  work_order_id     uuid,  -- FK to pp_work_orders if preservation
  captured_by       uuid REFERENCES auth.users(id),
  receipt_date      date NOT NULL DEFAULT CURRENT_DATE,
  facility_name     text,  -- denormalized for quick display
  waste_type        text,
  weight_tons       numeric(8,3),
  volume_yards      numeric(8,2),
  cost              numeric(10,2),
  tax               numeric(10,2) DEFAULT 0,
  total_cost        numeric(10,2),
  payment_method    text CHECK (payment_method IS NULL OR payment_method IN (
    'cash', 'check', 'credit_card', 'company_account', 'prepaid', 'other'
  )),
  receipt_photo_url text,
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

CREATE INDEX idx_dump_receipts_company ON dump_receipts (company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_dump_receipts_job ON dump_receipts (job_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_dump_receipts_facility ON dump_receipts (facility_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_dump_receipts_date ON dump_receipts (company_id, receipt_date DESC) WHERE deleted_at IS NULL;

ALTER TABLE dump_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "dump_receipt_select" ON dump_receipts
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

CREATE POLICY "dump_receipt_insert" ON dump_receipts
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "dump_receipt_update" ON dump_receipts
  FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('dump_receipts');
SELECT audit_trigger_fn('dump_receipts');

-- ============================================================================
-- SEED: Scrap metal price index (approximate national averages)
-- Prices from database only, flagged as seed data. $0 = unpriced.
-- ============================================================================

INSERT INTO scrap_price_index (material, grade, price_per_lb, unit, region, source, effective_date) VALUES
-- Copper
('copper', '#1 Bare Bright', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('copper', '#1 Copper Tubing', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('copper', '#2 Copper', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('copper', 'Insulated Copper Wire', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('copper', 'Copper Pipe (Light)', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
-- Aluminum
('aluminum', 'Aluminum Cans (UBC)', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('aluminum', 'Aluminum Siding', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('aluminum', 'Aluminum Wire', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('aluminum', 'Cast Aluminum', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('aluminum', 'Aluminum Gutters', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
-- Steel/Iron
('steel', 'Light Iron/Tin', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('steel', 'Heavy Iron/Steel', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('steel', 'Structural Steel', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('steel', 'Stainless Steel (304)', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('steel', 'Stainless Steel (316)', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
-- Brass
('brass', 'Yellow Brass', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('brass', 'Red Brass', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('brass', 'Brass Valves/Fittings', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
-- Lead
('lead', 'Soft Lead', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('lead', 'Lead Wheel Weights', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
-- Other
('nickel', 'Nickel Alloy', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('zinc', 'Zinc Die Cast', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('wire', 'Romex (NM-B) Wire', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('wire', 'THHN Wire', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('batteries', 'Auto Batteries', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('appliances', 'Appliances (Freon-free)', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('appliances', 'Appliances (Freon-containing)', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE),
('catalytic_converter', 'Catalytic Converter (aftermarket)', 0, 'lb', 'national', 'seed_unpriced', CURRENT_DATE)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SEED: Waste type reference (for dropdown menus)
-- ============================================================================

CREATE TABLE IF NOT EXISTS waste_type_reference (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code        text NOT NULL UNIQUE,
  label       text NOT NULL,
  category    text NOT NULL,  -- general, hazmat, recyclable, special
  trades      jsonb DEFAULT '[]',  -- which trades generate this waste type
  disposal_notes text,
  requires_permit boolean DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE waste_type_reference ENABLE ROW LEVEL SECURITY;

CREATE POLICY "waste_type_ref_select" ON waste_type_reference
  FOR SELECT TO authenticated USING (true);

INSERT INTO waste_type_reference (code, label, category, trades, disposal_notes, requires_permit) VALUES
('mixed_cd', 'Mixed Construction Debris', 'general', '["general","roofing","framing","demolition","remodeling"]', 'Most transfer stations accept. Pricing varies by region.', false),
('concrete', 'Concrete / Masonry / Brick', 'recyclable', '["concrete","masonry","demolition","foundation"]', 'Often cheaper than mixed C&D. Many recyclers pay for clean concrete.', false),
('clean_dirt', 'Clean Dirt / Soil', 'general', '["excavation","landscaping","foundation","grading"]', 'Some facilities accept free or charge minimal fee.', false),
('contaminated_soil', 'Contaminated Soil', 'hazmat', '["excavation","environmental","tank_removal"]', 'Must go to licensed hazmat facility. Testing required.', true),
('yard_waste', 'Yard Waste / Green Waste', 'recyclable', '["landscaping","tree_service","lawn_care"]', 'Many municipalities offer free drop-off for residents.', false),
('wood_untreated', 'Wood (Untreated)', 'recyclable', '["framing","carpentry","demolition","remodeling"]', 'Can be recycled or burned at biomass facilities.', false),
('wood_treated', 'Wood (Pressure Treated / Painted)', 'special', '["fencing","deck","demolition"]', 'Cannot be burned. Must go to landfill. CCA-treated is hazardous in some states.', false),
('metal_ferrous', 'Ferrous Metal (Steel/Iron)', 'recyclable', '["hvac","plumbing","electrical","demolition","roofing"]', 'Scrap yards pay for this. Always separate from other waste.', false),
('metal_nonferrous', 'Non-Ferrous Metal (Copper/Aluminum/Brass)', 'recyclable', '["electrical","plumbing","hvac"]', 'Higher value than ferrous. Separate by type for best price.', false),
('roofing_shingles', 'Roofing Shingles', 'recyclable', '["roofing"]', 'Many facilities recycle shingles for road base. Cheaper than landfill.', false),
('drywall', 'Drywall / Gypsum', 'recyclable', '["drywall","remodeling","demolition"]', 'Must be separated from other waste. Some recyclers accept.', false),
('carpet', 'Carpet / Padding', 'general', '["flooring","remodeling","demolition"]', 'Some facilities recycle carpet fiber. Check local options.', false),
('mold_waste', 'Mold-Contaminated Materials', 'special', '["mold_remediation","restoration"]', 'Double-bagged in 6-mil poly. Some states require licensed disposal.', false),
('asbestos', 'Asbestos-Containing Materials', 'hazmat', '["abatement","demolition","renovation"]', 'MUST go to licensed asbestos disposal facility. EPA/NESHAP regulated.', true),
('lead_paint', 'Lead Paint Waste', 'hazmat', '["painting","lead_abatement","renovation"]', 'EPA RRP Rule applies. Licensed disposal required in most states.', true),
('hazmat_general', 'Hazardous Materials (Paint/Chemicals/Solvents)', 'hazmat', '["painting","industrial","cleaning"]', 'Cannot go to regular landfill. HHW collection events or licensed facility.', true),
('tires', 'Tires', 'special', '["automotive","fleet"]', 'Most facilities charge per tire. Some states have tire recycling programs.', false),
('mattresses', 'Mattresses', 'special', '["moving","demolition","remodeling"]', 'Some states have mattress recycling laws. Check local requirements.', false),
('appliances_freon', 'Appliances (Freon-Containing)', 'special', '["hvac","appliance_repair","demolition"]', 'Freon must be recovered by EPA-certified technician before disposal.', true),
('appliances_standard', 'Appliances (Standard)', 'recyclable', '["appliance_repair","demolition","remodeling"]', 'Scrap yards often accept and may pay for appliances.', false),
('ewaste', 'Electronics / E-Waste', 'special', '["general","demolition","commercial"]', 'Must go to certified e-waste recycler. Many accept free.', false),
('biohazard', 'Biohazard / Trauma Waste', 'hazmat', '["restoration","crime_scene"]', 'Licensed biohazard disposal company required.', true),
('insulation_fiberglass', 'Fiberglass Insulation', 'general', '["insulation","remodeling","demolition"]', 'Bag tightly to prevent fiber release. Standard landfill disposal.', false),
('insulation_foam', 'Spray Foam Insulation', 'general', '["insulation","remodeling"]', 'Cured foam is non-hazardous. Standard landfill disposal.', false)
ON CONFLICT (code) DO NOTHING;
