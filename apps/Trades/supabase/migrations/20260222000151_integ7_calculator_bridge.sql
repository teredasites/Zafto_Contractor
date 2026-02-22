-- ============================================================
-- INTEG7: Calculator Bridge
-- Migration 000151
--
-- Wires 1,139 trade calculator files to produce output that
-- flows into business documents. Uses trade_tool_results and
-- trade_tool_estimate_links from INTEG2 (migration 148).
--
-- New tables:
--   calc_estimate_mappings   (config: how each calc maps to estimate items)
--   calc_sketch_annotations  (calculator results pinned to floor plans)
--   permit_attachments       (calculator printouts attached to permits)
--
-- Alters:
--   trade_tool_results       (add sketch/permit connection columns)
-- ============================================================

-- ============================================================
-- 1. CALC ESTIMATE MAPPINGS (seed/config table)
--    Defines how each calculator type maps its output items
--    to estimate_items fields. One row per calculator type.
-- ============================================================

CREATE TABLE IF NOT EXISTS calc_estimate_mappings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Calculator identification
  tool_key TEXT NOT NULL UNIQUE,  -- 'hvac_load_calc', 'paint_calculator', etc.
  tool_name TEXT NOT NULL,
  trade TEXT NOT NULL,

  -- Mapping rules: how output items → estimate line items
  output_to_estimate_map JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- [{
  --   output_field: 'btu_capacity',
  --   estimate_field: 'quantity',
  --   unit: 'BTU',
  --   category: 'HVAC Equipment',
  --   description_template: '{tool_name}: {output_field} = {value} {unit}',
  --   material_catalog_filter: { trade: 'hvac', category: 'equipment' }
  -- }]

  -- Default estimate area/category for this calc type
  default_estimate_category TEXT,
  default_trade_category TEXT,

  -- Which output items should be included
  include_labor BOOLEAN NOT NULL DEFAULT true,
  include_materials BOOLEAN NOT NULL DEFAULT true,
  include_equipment BOOLEAN NOT NULL DEFAULT false,

  -- Batch settings
  supports_batch_import BOOLEAN NOT NULL DEFAULT true,
  max_items_per_import INTEGER DEFAULT 50,

  -- Status
  is_active BOOLEAN NOT NULL DEFAULT true,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Publicly readable config table (no company_id — system-wide)
ALTER TABLE calc_estimate_mappings ENABLE ROW LEVEL SECURITY;
CREATE POLICY cem_select ON calc_estimate_mappings FOR SELECT TO authenticated USING (true);
CREATE POLICY cem_admin ON calc_estimate_mappings FOR ALL TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin');

SELECT update_updated_at('calc_estimate_mappings');


-- ============================================================
-- 2. CALC SKETCH ANNOTATIONS
--    Calculator results pinned to Sketch Engine floor plan
--    "Save to Sketch Layer" — measurement annotations on plans
-- ============================================================

CREATE TABLE IF NOT EXISTS calc_sketch_annotations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Calculator source
  tool_result_id UUID NOT NULL REFERENCES trade_tool_results(id) ON DELETE CASCADE,
  tool_key TEXT NOT NULL,
  trade TEXT NOT NULL,

  -- Sketch/floor plan location
  floor_plan_id UUID NOT NULL REFERENCES property_floor_plans(id) ON DELETE CASCADE,
  room_id UUID REFERENCES floor_plan_rooms(id) ON DELETE SET NULL,

  -- Position on floor plan canvas
  canvas_x NUMERIC(12,4) NOT NULL,
  canvas_y NUMERIC(12,4) NOT NULL,

  -- Annotation data
  annotation_type TEXT NOT NULL DEFAULT 'measurement'
    CHECK (annotation_type IN ('measurement', 'equipment', 'material', 'note', 'warning')),
  label TEXT NOT NULL,           -- "Wire Run: 45 ft 12 AWG"
  value TEXT,                    -- "45"
  unit TEXT,                     -- "ft"
  description TEXT,
  color_hex VARCHAR(7) DEFAULT '#3B82F6',
  icon TEXT,                     -- Lucide icon name

  -- Visibility
  layer_name TEXT NOT NULL DEFAULT 'calculations',
  is_visible BOOLEAN NOT NULL DEFAULT true,

  -- Link to specific output item
  output_item_index INTEGER,

  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_csa_company ON calc_sketch_annotations(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_csa_tool_result ON calc_sketch_annotations(tool_result_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_csa_floor_plan ON calc_sketch_annotations(floor_plan_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_csa_room ON calc_sketch_annotations(room_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_csa_trade ON calc_sketch_annotations(trade) WHERE deleted_at IS NULL;

ALTER TABLE calc_sketch_annotations ENABLE ROW LEVEL SECURITY;

CREATE POLICY csa_select ON calc_sketch_annotations FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY csa_insert ON calc_sketch_annotations FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY csa_update ON calc_sketch_annotations FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY csa_delete ON calc_sketch_annotations FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('calc_sketch_annotations');
CREATE TRIGGER csa_audit AFTER INSERT OR UPDATE OR DELETE ON calc_sketch_annotations
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 3. PERMIT ATTACHMENTS
--    Calculator printouts attached to permit applications
--    Supports PDF generation of calc inputs/outputs
-- ============================================================

CREATE TABLE IF NOT EXISTS permit_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Permit reference
  permit_id UUID REFERENCES permits(id) ON DELETE CASCADE,
  job_permit_id UUID REFERENCES job_permits(id) ON DELETE CASCADE,

  -- Source
  attachment_type TEXT NOT NULL DEFAULT 'calculator'
    CHECK (attachment_type IN ('calculator', 'photo', 'document', 'drawing', 'inspection_report')),
  tool_result_id UUID REFERENCES trade_tool_results(id) ON DELETE SET NULL,

  -- File info
  file_name TEXT NOT NULL,
  file_url TEXT,
  file_size_bytes INTEGER,
  mime_type TEXT DEFAULT 'application/pdf',

  -- Calculator summary (for quick reference without opening file)
  calc_summary TEXT,
  calc_trade TEXT,
  calc_key TEXT,

  -- Status
  is_submitted BOOLEAN NOT NULL DEFAULT false,
  submitted_at TIMESTAMPTZ,
  submitted_by UUID REFERENCES auth.users(id),

  -- Metadata
  notes TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,

  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_pa_company ON permit_attachments(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pa_permit ON permit_attachments(permit_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pa_job_permit ON permit_attachments(job_permit_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pa_tool_result ON permit_attachments(tool_result_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pa_type ON permit_attachments(attachment_type) WHERE deleted_at IS NULL;

ALTER TABLE permit_attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY pa_select ON permit_attachments FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY pa_insert ON permit_attachments FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY pa_update ON permit_attachments FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY pa_delete ON permit_attachments FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('permit_attachments');
CREATE TRIGGER pa_audit AFTER INSERT OR UPDATE OR DELETE ON permit_attachments
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 4. SEED: Default calc_estimate_mappings for core calculators
-- ============================================================

INSERT INTO calc_estimate_mappings (tool_key, tool_name, trade, default_estimate_category, output_to_estimate_map) VALUES
  ('hvac_load_calc', 'HVAC Load Calculator', 'hvac', 'HVAC', '[{"output_field":"btu_capacity","estimate_field":"quantity","unit":"BTU","description_template":"HVAC: {value} BTU system"}]'),
  ('electrical_panel_calc', 'Electrical Panel Calculator', 'electrical', 'Electrical', '[{"output_field":"total_amps","estimate_field":"quantity","unit":"A","description_template":"Panel: {value}A service"}]'),
  ('paint_calculator', 'Paint Calculator', 'painting', 'Painting', '[{"output_field":"gallons_needed","estimate_field":"quantity","unit":"gal","description_template":"Paint: {value} gallons"}]'),
  ('roofing_calculator', 'Roofing Calculator', 'roofing', 'Roofing', '[{"output_field":"squares_needed","estimate_field":"quantity","unit":"sq","description_template":"Roofing: {value} squares"}]'),
  ('plumbing_pipe_calc', 'Plumbing Pipe Calculator', 'plumbing', 'Plumbing', '[{"output_field":"total_pipe_ft","estimate_field":"quantity","unit":"LF","description_template":"Pipe: {value} LF"}]'),
  ('concrete_calculator', 'Concrete Calculator', 'concrete', 'Concrete/Masonry', '[{"output_field":"cubic_yards","estimate_field":"quantity","unit":"CY","description_template":"Concrete: {value} CY"}]'),
  ('drywall_calculator', 'Drywall Calculator', 'drywall', 'Drywall', '[{"output_field":"sheets_4x8","estimate_field":"quantity","unit":"sheet","description_template":"Drywall: {value} sheets (4x8)"}]'),
  ('flooring_calculator', 'Flooring Calculator', 'flooring', 'Flooring', '[{"output_field":"sqft_needed","estimate_field":"quantity","unit":"SF","description_template":"Flooring: {value} SF"}]'),
  ('insulation_calculator', 'Insulation Calculator', 'insulation', 'Insulation', '[{"output_field":"sqft_coverage","estimate_field":"quantity","unit":"SF","description_template":"Insulation: {value} SF @ R-{r_value}"}]'),
  ('gutter_calculator', 'Gutter Calculator', 'gutters', 'Gutters', '[{"output_field":"linear_feet","estimate_field":"quantity","unit":"LF","description_template":"Gutters: {value} LF"}]'),
  ('conduit_fill_calc', 'Conduit Fill Calculator', 'electrical', 'Electrical', '[{"output_field":"conduit_size","estimate_field":"description","unit":"in","description_template":"Conduit: {value}\" EMT"}]'),
  ('wire_run_calc', 'Wire Run Calculator', 'electrical', 'Electrical', '[{"output_field":"wire_length_ft","estimate_field":"quantity","unit":"LF","description_template":"Wire: {value} LF {gauge} AWG"}]'),
  ('duct_sizing_calc', 'Duct Sizing Calculator', 'hvac', 'HVAC', '[{"output_field":"duct_size_in","estimate_field":"description","unit":"in","description_template":"Ductwork: {value}\" diameter"}]'),
  ('tile_calculator', 'Tile Calculator', 'tile', 'Tile/Stone', '[{"output_field":"tiles_needed","estimate_field":"quantity","unit":"ea","description_template":"Tile: {value} tiles + {waste_pct}% waste"}]'),
  ('framing_calculator', 'Framing Calculator', 'framing', 'Framing', '[{"output_field":"studs_needed","estimate_field":"quantity","unit":"ea","description_template":"Studs: {value} ea @ {spacing}\" OC"}]'),
  ('siding_calculator', 'Siding Calculator', 'siding', 'Siding', '[{"output_field":"squares_needed","estimate_field":"quantity","unit":"sq","description_template":"Siding: {value} squares"}]'),
  ('fence_calculator', 'Fence Calculator', 'fencing', 'Fencing', '[{"output_field":"posts_needed","estimate_field":"quantity","unit":"ea","description_template":"Fence: {value} posts, {linear_feet} LF"}]'),
  ('deck_calculator', 'Deck Calculator', 'carpentry', 'Decking', '[{"output_field":"boards_needed","estimate_field":"quantity","unit":"ea","description_template":"Decking: {value} boards ({sqft} SF)"}]'),
  ('solar_calculator', 'Solar Calculator', 'solar', 'Solar', '[{"output_field":"panels_needed","estimate_field":"quantity","unit":"panel","description_template":"Solar: {value} panels ({kw_capacity} kW)"}]'),
  ('stair_calculator', 'Stair Calculator', 'carpentry', 'Stairs', '[{"output_field":"risers","estimate_field":"quantity","unit":"riser","description_template":"Stairs: {value} risers, {treads} treads"}]')
ON CONFLICT (tool_key) DO NOTHING;


-- ============================================================
-- 5. ALTER trade_tool_results — add sketch/permit columns
-- ============================================================

ALTER TABLE trade_tool_results
  ADD COLUMN IF NOT EXISTS has_sketch_annotations BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sketch_annotation_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS has_permit_attachment BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS pdf_url TEXT;
