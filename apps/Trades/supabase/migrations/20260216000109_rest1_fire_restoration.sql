-- ZAFTO Migration: REST1 — Fire Restoration Dedicated Tools
-- Sprint REST1 (Session 131)
-- Tables: fire_assessments, content_packout_items
-- Fire damage has fundamentally different workflows than water damage:
-- soot types, thermal fogging, content pack-out, odor treatment, board-up

-- =============================================================================
-- FIRE ASSESSMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS fire_assessments (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id     uuid NOT NULL REFERENCES companies(id),
  job_id         uuid NOT NULL REFERENCES jobs(id),
  insurance_claim_id uuid REFERENCES insurance_claims(id),
  created_by_user_id uuid REFERENCES auth.users(id),

  -- Fire origin & cause (documentation only — leave investigation to fire marshal)
  origin_room          text,
  origin_description   text,
  fire_department_report_number text,
  fire_department_name text,
  date_of_loss         timestamptz,

  -- Overall severity
  damage_severity      text NOT NULL DEFAULT 'moderate'
    CHECK (damage_severity IN ('minor', 'moderate', 'major', 'total_loss')),

  -- Structural assessment
  structural_compromise boolean NOT NULL DEFAULT false,
  roof_damage           boolean NOT NULL DEFAULT false,
  foundation_damage     boolean NOT NULL DEFAULT false,
  load_bearing_affected boolean NOT NULL DEFAULT false,
  structural_notes      text,

  -- Damage zones (JSONB array of rooms with zone classification)
  -- Each: { room, zone_type: direct_flame|smoke|heat|water_suppression, severity, soot_type, notes, photos[] }
  damage_zones    jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- Soot classification per area
  -- Each: { room, soot_type: wet_smoke|dry_smoke|protein|fuel_oil|mixed, surface_types[], cleaning_method, notes }
  soot_assessments jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- Odor treatment tracking
  -- Each: { method: thermal_fog|ozone|hydroxyl|air_scrub|sealer, room, start_time, end_time, equipment_id, pre_reading, post_reading, notes }
  odor_treatments jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- Board-up / emergency securing
  -- Each: { opening_type: window|door|roof|wall, location, material, dimensions, photo_before, photo_after, secured_by, secured_at }
  board_up_entries jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- Air quality readings
  -- Each: { location, reading_type: particulate|co|voc, value, unit, timestamp, equipment }
  air_quality_readings jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- Water from fire suppression (links to existing water damage workflow)
  water_damage_from_suppression boolean NOT NULL DEFAULT false,
  water_damage_assessment_id    uuid REFERENCES water_damage_assessments(id),

  -- Photos (array of storage paths tagged by room + damage type)
  photos         jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- Status workflow
  assessment_status text NOT NULL DEFAULT 'in_progress'
    CHECK (assessment_status IN ('in_progress', 'pending_review', 'approved', 'submitted_to_carrier')),

  -- Notes
  notes          text,

  -- Soft delete + audit
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  deleted_at     timestamptz
);

-- Indexes
CREATE INDEX idx_fire_assessments_company ON fire_assessments(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_fire_assessments_job ON fire_assessments(job_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_fire_assessments_claim ON fire_assessments(insurance_claim_id) WHERE deleted_at IS NULL AND insurance_claim_id IS NOT NULL;

-- Triggers
CREATE TRIGGER fire_assessments_updated_at
  BEFORE UPDATE ON fire_assessments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER fire_assessments_audit
  AFTER INSERT OR UPDATE OR DELETE ON fire_assessments
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- RLS
ALTER TABLE fire_assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY fire_assessments_select ON fire_assessments
  FOR SELECT USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
    OR (auth.jwt()->'app_metadata'->>'role')::text = 'super_admin'
  );

CREATE POLICY fire_assessments_insert ON fire_assessments
  FOR INSERT WITH CHECK (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

CREATE POLICY fire_assessments_update ON fire_assessments
  FOR UPDATE USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
    AND (auth.jwt()->'app_metadata'->>'role')::text IN ('owner', 'admin', 'office_manager', 'technician')
  );

CREATE POLICY fire_assessments_delete ON fire_assessments
  FOR DELETE USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
    AND (auth.jwt()->'app_metadata'->>'role')::text IN ('owner', 'admin')
  );

-- =============================================================================
-- CONTENT PACKOUT ITEMS
-- =============================================================================

CREATE TABLE IF NOT EXISTS content_packout_items (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  fire_assessment_id uuid NOT NULL REFERENCES fire_assessments(id) ON DELETE CASCADE,
  job_id            uuid NOT NULL REFERENCES jobs(id),

  -- Item details
  item_description  text NOT NULL,
  room_of_origin    text NOT NULL,

  -- Category
  category          text NOT NULL DEFAULT 'other'
    CHECK (category IN (
      'electronics', 'soft_goods', 'hard_goods', 'documents',
      'artwork', 'furniture', 'clothing', 'appliances',
      'kitchenware', 'personal', 'tools', 'sporting', 'other'
    )),

  -- Condition assessment
  condition         text NOT NULL DEFAULT 'needs_cleaning'
    CHECK (condition IN ('salvageable', 'non_salvageable', 'needs_cleaning', 'needs_restoration', 'questionable')),

  -- Cleaning method
  cleaning_method   text
    CHECK (cleaning_method IS NULL OR cleaning_method IN (
      'dry_clean', 'wet_clean', 'ultrasonic', 'ozone', 'immersion',
      'soda_blast', 'dry_ice_blast', 'hand_wipe', 'laundry', 'none'
    )),

  -- Pack-out tracking
  box_number        text,
  storage_location  text,
  packed_at         timestamptz,
  packed_by_user_id uuid REFERENCES auth.users(id),
  returned_at       timestamptz,
  returned_to       text,

  -- Valuation
  estimated_value   numeric(12,2),
  replacement_cost  numeric(12,2),
  actual_cash_value numeric(12,2),

  -- Photos (before cleaning, after cleaning)
  photo_urls        jsonb NOT NULL DEFAULT '[]'::jsonb,

  -- Notes
  notes             text,

  -- Soft delete + audit
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

-- Indexes
CREATE INDEX idx_content_packout_company ON content_packout_items(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_content_packout_assessment ON content_packout_items(fire_assessment_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_content_packout_job ON content_packout_items(job_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_content_packout_box ON content_packout_items(box_number) WHERE deleted_at IS NULL AND box_number IS NOT NULL;

-- Triggers
CREATE TRIGGER content_packout_items_updated_at
  BEFORE UPDATE ON content_packout_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER content_packout_items_audit
  AFTER INSERT OR UPDATE OR DELETE ON content_packout_items
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- RLS
ALTER TABLE content_packout_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY content_packout_select ON content_packout_items
  FOR SELECT USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
    OR (auth.jwt()->'app_metadata'->>'role')::text = 'super_admin'
  );

CREATE POLICY content_packout_insert ON content_packout_items
  FOR INSERT WITH CHECK (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
  );

CREATE POLICY content_packout_update ON content_packout_items
  FOR UPDATE USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
    AND (auth.jwt()->'app_metadata'->>'role')::text IN ('owner', 'admin', 'office_manager', 'technician')
  );

CREATE POLICY content_packout_delete ON content_packout_items
  FOR DELETE USING (
    company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid
    AND (auth.jwt()->'app_metadata'->>'role')::text IN ('owner', 'admin')
  );

-- =============================================================================
-- SEED DATA: Soot types, cleaning methods, thermal fogging protocols
-- =============================================================================

-- Insert into restoration_line_items if table exists (fire_restoration category)
-- These are Zafto's own line items for fire restoration work
INSERT INTO restoration_line_items (
  company_id, category, code, description, unit, unit_price, labor_hours_per_unit, notes
)
SELECT
  '00000000-0000-0000-0000-000000000000'::uuid,
  v.category, v.code, v.description, v.unit, v.unit_price, v.labor_hours, v.notes
FROM (VALUES
  -- Board-up & Emergency Securing
  ('fire_restoration', 'Z-FIRE-001', 'Board-up window opening (standard)', 'EA', 85.00, 0.75, 'OSB + 2x4 frame, per opening up to 4x4 ft'),
  ('fire_restoration', 'Z-FIRE-002', 'Board-up window opening (large)', 'EA', 135.00, 1.25, 'OSB + 2x4 frame, per opening over 4x4 ft'),
  ('fire_restoration', 'Z-FIRE-003', 'Board-up door opening', 'EA', 125.00, 1.0, 'OSB + 2x4 frame, standard door'),
  ('fire_restoration', 'Z-FIRE-004', 'Emergency roof tarp (up to 20x30)', 'EA', 450.00, 2.0, 'Poly tarp with 2x4 batten strips'),
  ('fire_restoration', 'Z-FIRE-005', 'Emergency roof tarp (over 20x30)', 'EA', 750.00, 3.5, 'Heavy-duty tarp with full batten system'),
  ('fire_restoration', 'Z-FIRE-006', 'Temporary fencing (per linear foot)', 'LF', 4.50, 0.05, '6ft chain link with stands'),

  -- Soot & Smoke Cleaning
  ('fire_restoration', 'Z-FIRE-010', 'Dry soot removal — walls (per SF)', 'SF', 2.25, 0.03, 'Dry sponge/chem sponge technique'),
  ('fire_restoration', 'Z-FIRE-011', 'Wet smoke cleaning — walls (per SF)', 'SF', 3.75, 0.05, 'Degreaser + wipe, requires multiple passes'),
  ('fire_restoration', 'Z-FIRE-012', 'Protein residue cleaning — walls (per SF)', 'SF', 4.50, 0.06, 'Enzyme cleaner, discoloration may persist'),
  ('fire_restoration', 'Z-FIRE-013', 'Ceiling soot cleaning (per SF)', 'SF', 3.50, 0.05, 'Overhead work premium'),
  ('fire_restoration', 'Z-FIRE-014', 'HVAC duct cleaning (per register)', 'EA', 175.00, 1.5, 'Vacuum + wipe each register + accessible duct'),
  ('fire_restoration', 'Z-FIRE-015', 'Soot seal / encapsulant (per SF)', 'SF', 1.75, 0.02, 'BIN shellac or Kilz Original after cleaning'),

  -- Odor Treatment
  ('fire_restoration', 'Z-FIRE-020', 'Thermal fogging — per room (small)', 'EA', 125.00, 0.5, 'Room up to 150 SF, deodorant fog'),
  ('fire_restoration', 'Z-FIRE-021', 'Thermal fogging — per room (large)', 'EA', 200.00, 0.75, 'Room over 150 SF, deodorant fog'),
  ('fire_restoration', 'Z-FIRE-022', 'Ozone treatment — per room/day', 'EA', 175.00, 0.25, 'Requires vacancy, 24hr minimum'),
  ('fire_restoration', 'Z-FIRE-023', 'Hydroxyl generator — per day', 'DAY', 150.00, 0.1, 'Safe for occupied spaces'),
  ('fire_restoration', 'Z-FIRE-024', 'Air scrubber w/ carbon filter — per day', 'DAY', 95.00, 0.1, 'HEPA + activated carbon'),
  ('fire_restoration', 'Z-FIRE-025', 'Odor counteractant application (per SF)', 'SF', 0.85, 0.01, 'Spray application after cleaning'),

  -- Content Pack-out & Cleaning
  ('fire_restoration', 'Z-FIRE-030', 'Content pack-out — per box', 'EA', 45.00, 0.5, 'Inventory, wrap, box, label, transport'),
  ('fire_restoration', 'Z-FIRE-031', 'Content dry cleaning — soft goods (per item)', 'EA', 8.50, 0.15, 'Ozone chamber or professional dry clean'),
  ('fire_restoration', 'Z-FIRE-032', 'Content wet cleaning — hard goods (per item)', 'EA', 12.00, 0.2, 'Hand wash + deodorize'),
  ('fire_restoration', 'Z-FIRE-033', 'Ultrasonic cleaning — electronics/delicates', 'EA', 25.00, 0.3, 'Ultrasonic bath + inspect'),
  ('fire_restoration', 'Z-FIRE-034', 'Content storage — per vault/month', 'MO', 175.00, 0.0, 'Climate-controlled vault storage'),
  ('fire_restoration', 'Z-FIRE-035', 'Content pack-back/delivery', 'EA', 35.00, 0.5, 'Return cleaned items to home'),

  -- Demolition & Removal (fire-specific)
  ('fire_restoration', 'Z-FIRE-040', 'Charred framing removal (per LF)', 'LF', 5.50, 0.08, 'Remove and dispose fire-damaged framing'),
  ('fire_restoration', 'Z-FIRE-041', 'Fire-damaged drywall removal (per SF)', 'SF', 2.00, 0.03, 'Remove, bag, dispose'),
  ('fire_restoration', 'Z-FIRE-042', 'Fire-damaged insulation removal (per SF)', 'SF', 1.75, 0.03, 'Remove smoke-saturated insulation'),
  ('fire_restoration', 'Z-FIRE-043', 'Debris removal — fire (per CY)', 'CY', 65.00, 0.25, 'Load, haul, dump fees included'),
  ('fire_restoration', 'Z-FIRE-044', 'Ash/soot vacuum — industrial (per SF)', 'SF', 1.25, 0.02, 'HEPA vacuum all surfaces')
) AS v(category, code, description, unit, unit_price, labor_hours, notes)
WHERE NOT EXISTS (
  SELECT 1 FROM restoration_line_items WHERE code = 'Z-FIRE-001'
);
