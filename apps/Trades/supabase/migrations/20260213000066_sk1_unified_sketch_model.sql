-- SK1: Unified Sketch Engine Data Model
-- Phase SK — Sprint SK1
-- Merges property_floor_plans + bid_sketches into single source of truth.
-- Creates: floor_plan_snapshots, floor_plan_photo_pins, floor_plan_layers,
--          floor_plan_rooms, floor_plan_estimate_links
-- Alters:  property_floor_plans (add job/estimate/status/sync/floor fields)
--          bid_sketches (add floor_plan_id FK)

-- ============================================================================
-- ALTER property_floor_plans — add sketch engine fields
-- ============================================================================

ALTER TABLE property_floor_plans
  ADD COLUMN IF NOT EXISTS job_id UUID REFERENCES jobs(id),
  ADD COLUMN IF NOT EXISTS estimate_id UUID REFERENCES estimates(id),
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'draft'
    CHECK (status IN ('draft','scanning','processing','complete','archived')),
  ADD COLUMN IF NOT EXISTS sync_version INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS last_synced_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS floor_number INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_floor_plans_job
  ON property_floor_plans(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_floor_plans_estimate
  ON property_floor_plans(estimate_id) WHERE estimate_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_floor_plans_status
  ON property_floor_plans(status);
CREATE INDEX IF NOT EXISTS idx_floor_plans_company
  ON property_floor_plans(company_id);

-- ============================================================================
-- floor_plan_snapshots — version history for floor plans
-- Auto/manual snapshots for undo across sessions, change order tracking
-- ============================================================================

CREATE TABLE floor_plan_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  floor_plan_id UUID NOT NULL REFERENCES property_floor_plans(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id),
  plan_data JSONB NOT NULL,
  snapshot_reason TEXT NOT NULL DEFAULT 'manual'
    CHECK (snapshot_reason IN ('manual','auto','pre_change_order','pre_edit')),
  snapshot_label TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_fps_floor_plan ON floor_plan_snapshots(floor_plan_id, created_at DESC);
CREATE INDEX idx_fps_company ON floor_plan_snapshots(company_id);

ALTER TABLE floor_plan_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY fps_select ON floor_plan_snapshots
  FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fps_insert ON floor_plan_snapshots
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fps_update ON floor_plan_snapshots
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fps_delete ON floor_plan_snapshots
  FOR DELETE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- floor_plan_photo_pins — link photos to floor plan locations
-- Connects walkthrough/job photos to specific (x,y) on the plan
-- ============================================================================

CREATE TABLE floor_plan_photo_pins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  floor_plan_id UUID NOT NULL REFERENCES property_floor_plans(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id),
  photo_id UUID,
  photo_path TEXT,
  position_x NUMERIC NOT NULL,
  position_y NUMERIC NOT NULL,
  room_id UUID,
  label TEXT,
  pin_type TEXT DEFAULT 'photo'
    CHECK (pin_type IN ('photo','damage','note','measurement','before','after')),
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_fpp_floor_plan ON floor_plan_photo_pins(floor_plan_id);
CREATE INDEX idx_fpp_company ON floor_plan_photo_pins(company_id);
CREATE INDEX idx_fpp_room ON floor_plan_photo_pins(room_id) WHERE room_id IS NOT NULL;

ALTER TABLE floor_plan_photo_pins ENABLE ROW LEVEL SECURITY;

CREATE POLICY fpp_select ON floor_plan_photo_pins
  FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fpp_insert ON floor_plan_photo_pins
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fpp_update ON floor_plan_photo_pins
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fpp_delete ON floor_plan_photo_pins
  FOR DELETE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE TRIGGER fpp_updated BEFORE UPDATE ON floor_plan_photo_pins
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- floor_plan_layers — trade-specific overlay layers
-- Each floor plan can have multiple layers (electrical, plumbing, HVAC, damage, custom)
-- ============================================================================

CREATE TABLE floor_plan_layers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  floor_plan_id UUID NOT NULL REFERENCES property_floor_plans(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id),
  layer_type TEXT NOT NULL DEFAULT 'custom'
    CHECK (layer_type IN ('electrical','plumbing','hvac','damage','custom')),
  layer_name TEXT NOT NULL,
  layer_data JSONB DEFAULT '{}'::jsonb,
  visible BOOLEAN DEFAULT true,
  locked BOOLEAN DEFAULT false,
  opacity NUMERIC DEFAULT 1.0 CHECK (opacity >= 0 AND opacity <= 1),
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_fpl_floor_plan ON floor_plan_layers(floor_plan_id);
CREATE INDEX idx_fpl_company ON floor_plan_layers(company_id);
CREATE INDEX idx_fpl_type ON floor_plan_layers(layer_type);

ALTER TABLE floor_plan_layers ENABLE ROW LEVEL SECURITY;

CREATE POLICY fpl_select ON floor_plan_layers
  FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fpl_insert ON floor_plan_layers
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fpl_update ON floor_plan_layers
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fpl_delete ON floor_plan_layers
  FOR DELETE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE TRIGGER fpl_updated BEFORE UPDATE ON floor_plan_layers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- floor_plan_rooms — detected/drawn rooms with computed measurements
-- Stores boundary, area, perimeter, damage classification, IICRC data
-- ============================================================================

CREATE TABLE floor_plan_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  floor_plan_id UUID NOT NULL REFERENCES property_floor_plans(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL DEFAULT 'Room',
  room_type TEXT DEFAULT 'room'
    CHECK (room_type IN (
      'room','bedroom','bathroom','kitchen','living_room','dining_room',
      'hallway','garage','attic','basement','closet','utility','laundry',
      'office'
    )),
  boundary_points JSONB DEFAULT '[]'::jsonb,
  boundary_wall_ids JSONB DEFAULT '[]'::jsonb,
  floor_area_sf NUMERIC(10,2) DEFAULT 0,
  wall_area_sf NUMERIC(10,2) DEFAULT 0,
  perimeter_lf NUMERIC(10,2) DEFAULT 0,
  ceiling_height_inches INTEGER DEFAULT 96,
  floor_material TEXT,
  damage_class TEXT CHECK (damage_class IN ('1','2','3','4')),
  iicrc_category TEXT CHECK (iicrc_category IN ('1','2','3')),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_fpr_floor_plan ON floor_plan_rooms(floor_plan_id);
CREATE INDEX idx_fpr_company ON floor_plan_rooms(company_id);
CREATE INDEX idx_fpr_type ON floor_plan_rooms(room_type);

ALTER TABLE floor_plan_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY fpr_select ON floor_plan_rooms
  FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fpr_insert ON floor_plan_rooms
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fpr_update ON floor_plan_rooms
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fpr_delete ON floor_plan_rooms
  FOR DELETE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE TRIGGER fpr_updated BEFORE UPDATE ON floor_plan_rooms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- floor_plan_estimate_links — bridge floor plan rooms to D8 estimate areas
-- Enables auto-populate estimate line items from room measurements
-- ============================================================================

CREATE TABLE floor_plan_estimate_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  floor_plan_id UUID NOT NULL REFERENCES property_floor_plans(id) ON DELETE CASCADE,
  room_id UUID NOT NULL REFERENCES floor_plan_rooms(id) ON DELETE CASCADE,
  estimate_id UUID NOT NULL REFERENCES estimates(id) ON DELETE CASCADE,
  estimate_area_id UUID,
  auto_generated BOOLEAN DEFAULT true,
  company_id UUID NOT NULL REFERENCES companies(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_fpel_floor_plan ON floor_plan_estimate_links(floor_plan_id);
CREATE INDEX idx_fpel_room ON floor_plan_estimate_links(room_id);
CREATE INDEX idx_fpel_estimate ON floor_plan_estimate_links(estimate_id);
CREATE INDEX idx_fpel_company ON floor_plan_estimate_links(company_id);

ALTER TABLE floor_plan_estimate_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY fpel_select ON floor_plan_estimate_links
  FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fpel_insert ON floor_plan_estimate_links
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fpel_update ON floor_plan_estimate_links
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fpel_delete ON floor_plan_estimate_links
  FOR DELETE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- ALTER bid_sketches — add floor_plan_id FK to unify systems
-- ============================================================================

ALTER TABLE bid_sketches
  ADD COLUMN IF NOT EXISTS floor_plan_id UUID REFERENCES property_floor_plans(id);

CREATE INDEX IF NOT EXISTS idx_sketches_floor_plan
  ON bid_sketches(floor_plan_id) WHERE floor_plan_id IS NOT NULL;

-- ============================================================================
-- Audit triggers on new tables
-- ============================================================================

CREATE TRIGGER fps_audit AFTER INSERT OR UPDATE OR DELETE ON floor_plan_snapshots
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER fpp_audit AFTER INSERT OR UPDATE OR DELETE ON floor_plan_photo_pins
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER fpl_audit AFTER INSERT OR UPDATE OR DELETE ON floor_plan_layers
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER fpr_audit AFTER INSERT OR UPDATE OR DELETE ON floor_plan_rooms
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER fpel_audit AFTER INSERT OR UPDATE OR DELETE ON floor_plan_estimate_links
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
