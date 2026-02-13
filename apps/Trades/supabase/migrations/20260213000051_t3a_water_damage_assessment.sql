-- T3a: Water Damage Assessment, Psychrometric Monitoring, Contents Inventory
-- Phase T (Programs/TPA Module) — Sprint T3
-- IICRC S500-compliant water damage classification, moisture mapping, psychrometric monitoring

-- ============================================================================
-- TABLE 1: WATER DAMAGE ASSESSMENTS
-- IICRC S500 compliant: Category 1-3 water source, Class 1-4 evaporation rate
-- ============================================================================

CREATE TABLE water_damage_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  tpa_assignment_id UUID REFERENCES tpa_assignments(id),
  created_by_user_id UUID REFERENCES auth.users(id),
  -- IICRC S500 Classification
  water_category INTEGER NOT NULL CHECK (water_category BETWEEN 1 AND 3),
  -- Cat 1: Clean water (supply lines, rain, melting ice)
  -- Cat 2: Gray water (dishwasher, washing machine, toilet overflow with urine)
  -- Cat 3: Black water (sewage, rising flood, toilet with fecal matter)
  water_class INTEGER NOT NULL CHECK (water_class BETWEEN 1 AND 4),
  -- Class 1: Least amount of water absorption — part of room, materials low porosity
  -- Class 2: Significant water — entire room, carpet and cushion wet, <24" wicking walls
  -- Class 3: Greatest water — saturated ceiling, walls, insulation, carpet, subfloor
  -- Class 4: Specialty drying — deep pockets: hardwood, plaster, concrete, stone
  category_can_escalate BOOLEAN DEFAULT false,
  -- Source identification
  source_type TEXT NOT NULL CHECK (source_type IN (
    'supply_line','drain_line','appliance','toilet','sewage',
    'roof_leak','window_leak','foundation','storm','flood',
    'fire_suppression','hvac','ice_dam','unknown','other'
  )),
  source_description TEXT,
  source_location_room TEXT,
  source_stopped BOOLEAN DEFAULT false,
  source_stopped_at TIMESTAMPTZ,
  source_stopped_by TEXT,
  -- Loss date/time (for insurance SLA tracking)
  loss_date TIMESTAMPTZ NOT NULL,
  discovered_date TIMESTAMPTZ,
  -- Affected areas — JSONB array of rooms/areas with details
  -- [{room, floor_level, sqft_affected, materials_affected: [], wall_height_wet_inches, ceiling_wet, has_contents, pre_existing_damage, notes}]
  affected_areas JSONB DEFAULT '[]'::jsonb,
  total_sqft_affected NUMERIC(10,2) DEFAULT 0,
  floors_affected INTEGER DEFAULT 1,
  -- Pre-existing conditions
  pre_existing_damage TEXT,
  pre_existing_mold BOOLEAN DEFAULT false,
  -- Assessment outcome
  emergency_services_required BOOLEAN DEFAULT false,
  containment_required BOOLEAN DEFAULT false,
  asbestos_suspect BOOLEAN DEFAULT false,
  lead_paint_suspect BOOLEAN DEFAULT false,
  -- Recommended actions
  recommended_equipment JSONB DEFAULT '[]'::jsonb,
  -- [{type: 'dehumidifier'|'air_mover'|'air_scrubber'|'heater'|'negative_air', quantity, area, notes}]
  estimated_drying_days INTEGER,
  -- Status
  status TEXT DEFAULT 'initial' CHECK (status IN (
    'initial','in_progress','monitoring','drying_complete','closed'
  )),
  completed_at TIMESTAMPTZ,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- ============================================================================
-- TABLE 2: PSYCHROMETRIC LOGS
-- Indoor/outdoor conditions tracking for drying optimization
-- ============================================================================

CREATE TABLE psychrometric_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  tpa_assignment_id UUID REFERENCES tpa_assignments(id),
  water_damage_assessment_id UUID REFERENCES water_damage_assessments(id),
  recorded_by_user_id UUID REFERENCES auth.users(id),
  -- Indoor conditions
  indoor_temp_f NUMERIC(5,1) NOT NULL,
  indoor_rh NUMERIC(5,1) NOT NULL,  -- relative humidity %
  indoor_gpp NUMERIC(8,2),  -- grains per pound (calculated or entered)
  indoor_dew_point_f NUMERIC(5,1),  -- calculated
  -- Outdoor conditions (comparison baseline)
  outdoor_temp_f NUMERIC(5,1),
  outdoor_rh NUMERIC(5,1),
  outdoor_gpp NUMERIC(8,2),
  outdoor_dew_point_f NUMERIC(5,1),
  -- Dehumidifier performance (inlet vs outlet)
  dehu_inlet_temp_f NUMERIC(5,1),
  dehu_inlet_rh NUMERIC(5,1),
  dehu_inlet_gpp NUMERIC(8,2),
  dehu_outlet_temp_f NUMERIC(5,1),
  dehu_outlet_rh NUMERIC(5,1),
  dehu_outlet_gpp NUMERIC(8,2),
  -- Equipment counts at time of reading
  dehumidifiers_running INTEGER DEFAULT 0,
  air_movers_running INTEGER DEFAULT 0,
  air_scrubbers_running INTEGER DEFAULT 0,
  heaters_running INTEGER DEFAULT 0,
  -- Room where reading taken
  room_name TEXT,
  -- Notes
  notes TEXT,
  -- Timestamp
  recorded_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TABLE 3: CONTENTS INVENTORY
-- Room-by-room item tracking: move/block/pack-out/dispose
-- Billable service (10-30% of water mitigation invoices)
-- ============================================================================

CREATE TABLE contents_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  tpa_assignment_id UUID REFERENCES tpa_assignments(id),
  -- Item identity
  item_number INTEGER NOT NULL,  -- sequential within job
  description TEXT NOT NULL,
  quantity INTEGER DEFAULT 1,
  -- Location
  room_name TEXT NOT NULL,
  floor_level TEXT,
  -- Condition assessment
  condition_before TEXT CHECK (condition_before IN (
    'new','good','fair','poor','damaged','unknown'
  )),
  condition_after TEXT CHECK (condition_after IN (
    'new','good','fair','poor','damaged','destroyed','unknown'
  )),
  damage_description TEXT,
  -- Action taken
  action TEXT NOT NULL CHECK (action IN (
    'move','block','pack_out','dispose','clean','restore','no_action'
  )),
  -- Move = relocate within structure
  -- Block = elevate/protect in place
  -- Pack-out = remove from structure to off-site storage
  -- Dispose = non-salvageable, documented for claim
  -- Clean = on-site cleaning
  -- Restore = repair/refinish
  destination TEXT,  -- where item was moved/stored
  -- Financial
  pre_loss_value NUMERIC(10,2),
  replacement_value NUMERIC(10,2),
  actual_cash_value NUMERIC(10,2),  -- ACV = replacement - depreciation
  -- Photo documentation
  photo_ids UUID[] DEFAULT '{}',
  photo_storage_paths TEXT[] DEFAULT '{}',
  -- Pack-out tracking
  packed_by_user_id UUID REFERENCES auth.users(id),
  packed_at TIMESTAMPTZ,
  returned_at TIMESTAMPTZ,
  returned_condition TEXT,
  -- Status
  status TEXT DEFAULT 'inventoried' CHECK (status IN (
    'inventoried','in_transit','stored','returned','disposed','claimed'
  )),
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- ============================================================================
-- ALTER moisture_readings — add TPA integration columns
-- ============================================================================

ALTER TABLE moisture_readings
  ADD COLUMN IF NOT EXISTS tpa_assignment_id UUID REFERENCES tpa_assignments(id),
  ADD COLUMN IF NOT EXISTS water_damage_assessment_id UUID REFERENCES water_damage_assessments(id),
  ADD COLUMN IF NOT EXISTS location_number INTEGER,  -- numbered grid location (1, 2, 3...)
  ADD COLUMN IF NOT EXISTS reference_standard NUMERIC(6,1),  -- IICRC reference dry standard for material
  ADD COLUMN IF NOT EXISTS drying_goal_mc NUMERIC(6,1),  -- moisture content goal (may differ from reference)
  ADD COLUMN IF NOT EXISTS notes TEXT;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE water_damage_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE psychrometric_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE contents_inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY water_damage_assessments_company ON water_damage_assessments
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY psychrometric_logs_company ON psychrometric_logs
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY contents_inventory_company ON contents_inventory
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- water_damage_assessments
CREATE INDEX idx_wda_company ON water_damage_assessments(company_id);
CREATE INDEX idx_wda_job ON water_damage_assessments(job_id);
CREATE INDEX idx_wda_tpa ON water_damage_assessments(tpa_assignment_id) WHERE tpa_assignment_id IS NOT NULL;
CREATE INDEX idx_wda_status ON water_damage_assessments(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_wda_category ON water_damage_assessments(water_category, water_class);

-- psychrometric_logs
CREATE INDEX idx_psychro_company ON psychrometric_logs(company_id);
CREATE INDEX idx_psychro_job ON psychrometric_logs(job_id);
CREATE INDEX idx_psychro_assessment ON psychrometric_logs(water_damage_assessment_id) WHERE water_damage_assessment_id IS NOT NULL;
CREATE INDEX idx_psychro_recorded ON psychrometric_logs(recorded_at DESC);

-- contents_inventory
CREATE INDEX idx_contents_company ON contents_inventory(company_id);
CREATE INDEX idx_contents_job ON contents_inventory(job_id);
CREATE INDEX idx_contents_tpa ON contents_inventory(tpa_assignment_id) WHERE tpa_assignment_id IS NOT NULL;
CREATE INDEX idx_contents_status ON contents_inventory(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_contents_room ON contents_inventory(job_id, room_name);
CREATE INDEX idx_contents_action ON contents_inventory(action);

-- moisture_readings enhancement indexes
CREATE INDEX idx_moisture_tpa ON moisture_readings(tpa_assignment_id) WHERE tpa_assignment_id IS NOT NULL;
CREATE INDEX idx_moisture_wda ON moisture_readings(water_damage_assessment_id) WHERE water_damage_assessment_id IS NOT NULL;
CREATE INDEX idx_moisture_location ON moisture_readings(job_id, location_number) WHERE location_number IS NOT NULL;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER water_damage_assessments_updated BEFORE UPDATE ON water_damage_assessments FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER contents_inventory_updated BEFORE UPDATE ON contents_inventory FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit trail
CREATE TRIGGER water_damage_assessments_audit AFTER INSERT OR UPDATE OR DELETE ON water_damage_assessments FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER psychrometric_logs_audit AFTER INSERT OR UPDATE OR DELETE ON psychrometric_logs FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER contents_inventory_audit AFTER INSERT OR UPDATE OR DELETE ON contents_inventory FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
