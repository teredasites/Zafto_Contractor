-- T4a: Equipment Deployment, IICRC Calculator Results, Warehouse Inventory
-- Phase T (Programs/TPA Module) — Sprint T4
-- IICRC S500 equipment placement formulas, billing clock, warehouse tracking

-- ============================================================================
-- ALTER restoration_equipment — add TPA + AHAM columns
-- (Base table exists in D2 migration with job-level deployment tracking)
-- ============================================================================

ALTER TABLE restoration_equipment
  ADD COLUMN IF NOT EXISTS tpa_assignment_id UUID REFERENCES tpa_assignments(id),
  ADD COLUMN IF NOT EXISTS water_damage_assessment_id UUID REFERENCES water_damage_assessments(id),
  ADD COLUMN IF NOT EXISTS equipment_inventory_id UUID,  -- FK added below after table creation
  ADD COLUMN IF NOT EXISTS room_name TEXT,
  ADD COLUMN IF NOT EXISTS placement_location TEXT,  -- "Center of room", "Against north wall", etc.
  ADD COLUMN IF NOT EXISTS aham_ppd NUMERIC(8,1),  -- AHAM-rated Pints Per Day (dehumidifiers)
  ADD COLUMN IF NOT EXISTS aham_cfm NUMERIC(8,1),  -- AHAM-rated CFM (air movers, scrubbers)
  ADD COLUMN IF NOT EXISTS calculated_by_formula BOOLEAN DEFAULT false,  -- placed based on IICRC calc
  ADD COLUMN IF NOT EXISTS formula_reference_id UUID;  -- links to equipment_calculations

CREATE INDEX IF NOT EXISTS idx_restore_equip_tpa ON restoration_equipment(tpa_assignment_id) WHERE tpa_assignment_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_restore_equip_wda ON restoration_equipment(water_damage_assessment_id) WHERE water_damage_assessment_id IS NOT NULL;

-- ============================================================================
-- TABLE 1: EQUIPMENT CALCULATIONS — IICRC formula results per room
-- ============================================================================

CREATE TABLE equipment_calculations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  tpa_assignment_id UUID REFERENCES tpa_assignments(id),
  water_damage_assessment_id UUID REFERENCES water_damage_assessments(id),
  created_by_user_id UUID REFERENCES auth.users(id),
  -- Room dimensions
  room_name TEXT NOT NULL,
  room_length_ft NUMERIC(8,2) NOT NULL,
  room_width_ft NUMERIC(8,2) NOT NULL,
  room_height_ft NUMERIC(8,2) NOT NULL DEFAULT 8,
  -- Computed values
  floor_sqft NUMERIC(10,2) GENERATED ALWAYS AS (room_length_ft * room_width_ft) STORED,
  wall_linear_ft NUMERIC(10,2) GENERATED ALWAYS AS (2 * (room_length_ft + room_width_ft)) STORED,
  cubic_ft NUMERIC(12,2) GENERATED ALWAYS AS (room_length_ft * room_width_ft * room_height_ft) STORED,
  ceiling_sqft NUMERIC(10,2) GENERATED ALWAYS AS (room_length_ft * room_width_ft) STORED,
  -- IICRC classification for this room
  water_class INTEGER NOT NULL CHECK (water_class BETWEEN 1 AND 4),
  -- Dehumidifier calculation
  -- Formula: cubic_ft / chart_factor = PPD needed / unit_ppd = units
  dehu_chart_factor NUMERIC(8,2) NOT NULL DEFAULT 40,  -- varies by class: 40 (C1), 40 (C2), 30 (C3), 25 (C4)
  dehu_ppd_needed NUMERIC(10,2),  -- cubic_ft / chart_factor
  dehu_unit_ppd NUMERIC(8,1) DEFAULT 70,  -- PPD rating of specific unit
  dehu_units_required INTEGER,  -- CEIL(ppd_needed / unit_ppd)
  -- Air mover calculation
  -- Formula: wall_lf/14 + floor_sf/(50-70) + ceiling_sf/(100-150) + insets
  am_wall_units NUMERIC(6,1),  -- wall_lf / 14
  am_floor_units NUMERIC(6,1),  -- floor_sqft / divisor (50 for C2-3, 70 for C1)
  am_ceiling_units NUMERIC(6,1),  -- ceiling_sqft / divisor (100-150)
  am_floor_divisor NUMERIC(6,1) DEFAULT 50,  -- 50 for C2-3, 70 for C1
  am_ceiling_divisor NUMERIC(6,1) DEFAULT 100,  -- 100 for C3, 150 for C2
  am_inset_count INTEGER DEFAULT 0,  -- closets, toe kicks, etc.
  am_units_required INTEGER,  -- CEIL(sum of all)
  -- Air scrubber calculation
  -- Formula: cubic_ft * target_ACH / 60 / scrubber_cfm = units
  scrubber_target_ach NUMERIC(6,1) DEFAULT 6,  -- Air Changes per Hour target
  scrubber_unit_cfm NUMERIC(8,1) DEFAULT 500,  -- CFM of specific unit
  scrubber_units_required INTEGER,  -- CEIL(formula result)
  -- Variance & adjuster justification
  actual_dehu_placed INTEGER DEFAULT 0,
  actual_am_placed INTEGER DEFAULT 0,
  actual_scrubber_placed INTEGER DEFAULT 0,
  variance_notes TEXT,  -- explain any deviation from formula
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TABLE 2: EQUIPMENT INVENTORY — Company warehouse inventory
-- ============================================================================

CREATE TABLE equipment_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  -- Equipment identity
  equipment_type TEXT NOT NULL CHECK (equipment_type IN (
    'dehumidifier','air_mover','air_scrubber','heater',
    'moisture_meter','thermal_camera','hydroxyl_generator',
    'negative_air_machine','injectidry','other'
  )),
  name TEXT NOT NULL,  -- "Dri-Eaz Sahara Pro X3"
  make TEXT,
  model TEXT,
  serial_number TEXT,
  asset_tag TEXT,  -- internal tag (e.g., "AM-001")
  -- AHAM ratings
  aham_ppd NUMERIC(8,1),  -- Pints Per Day (dehumidifiers only)
  aham_cfm NUMERIC(8,1),  -- Cubic Feet per Minute (movers, scrubbers)
  -- Financial
  purchase_date DATE,
  purchase_price NUMERIC(10,2),
  daily_rental_rate NUMERIC(10,2) DEFAULT 0,
  -- Status tracking
  status TEXT NOT NULL DEFAULT 'available' CHECK (status IN (
    'available','deployed','maintenance','retired','lost'
  )),
  current_job_id UUID REFERENCES jobs(id),
  current_deployment_id UUID,  -- FK to restoration_equipment
  -- Maintenance
  last_maintenance_date DATE,
  next_maintenance_date DATE,
  maintenance_notes TEXT,
  total_deploy_days INTEGER DEFAULT 0,  -- lifetime deployment days
  -- Photos
  photo_storage_path TEXT,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- Add FK from restoration_equipment to equipment_inventory
ALTER TABLE restoration_equipment
  ADD CONSTRAINT fk_restore_equip_inventory
  FOREIGN KEY (equipment_inventory_id) REFERENCES equipment_inventory(id);

-- Add FK from equipment_calculations formula_reference
ALTER TABLE restoration_equipment
  ADD CONSTRAINT fk_restore_equip_calc
  FOREIGN KEY (formula_reference_id) REFERENCES equipment_calculations(id);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE equipment_calculations ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment_inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY equipment_calculations_company ON equipment_calculations
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY equipment_inventory_company ON equipment_inventory
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- equipment_calculations
CREATE INDEX idx_equip_calc_company ON equipment_calculations(company_id);
CREATE INDEX idx_equip_calc_job ON equipment_calculations(job_id);
CREATE INDEX idx_equip_calc_tpa ON equipment_calculations(tpa_assignment_id) WHERE tpa_assignment_id IS NOT NULL;

-- equipment_inventory
CREATE INDEX idx_equip_inv_company ON equipment_inventory(company_id);
CREATE INDEX idx_equip_inv_status ON equipment_inventory(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_equip_inv_type ON equipment_inventory(equipment_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_equip_inv_job ON equipment_inventory(current_job_id) WHERE current_job_id IS NOT NULL;
CREATE INDEX idx_equip_inv_serial ON equipment_inventory(company_id, serial_number) WHERE serial_number IS NOT NULL;
CREATE INDEX idx_equip_inv_asset ON equipment_inventory(company_id, asset_tag) WHERE asset_tag IS NOT NULL;
CREATE INDEX idx_equip_inv_maint ON equipment_inventory(next_maintenance_date) WHERE status != 'retired' AND deleted_at IS NULL;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER equipment_calculations_updated BEFORE UPDATE ON equipment_calculations FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER equipment_inventory_updated BEFORE UPDATE ON equipment_inventory FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit trail
CREATE TRIGGER equipment_calculations_audit AFTER INSERT OR UPDATE OR DELETE ON equipment_calculations FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER equipment_inventory_audit AFTER INSERT OR UPDATE OR DELETE ON equipment_inventory FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
