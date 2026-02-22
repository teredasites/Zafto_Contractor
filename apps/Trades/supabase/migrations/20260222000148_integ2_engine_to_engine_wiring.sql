-- ============================================================
-- INTEG2: Engine-to-Engine Wiring
-- Migration 000148
--
-- Bridge tables connecting VIZ, Sketch, Estimates, Trade Tools,
-- Recon, and Material systems. Currently isolated islands that
-- don't share data — this wires them together.
--
-- New tables:
--   viz_sketch_links         (VIZ ↔ Sketch bidirectional)
--   viz_estimate_links       (VIZ → Estimate generation)
--   material_estimate_map    (Material catalog → Estimate items)
--   trade_tool_results       (Calculator output storage)
--   trade_tool_estimate_links (Trade Tools → Estimate bridge)
--   materials_master         (Unified material catalog hub)
--
-- Alters:
--   property_scans           (add scan_purpose ENUM)
-- ============================================================

-- ============================================================
-- 1. SCAN PURPOSE ENUM + property_scans discriminator
--    Resolves collision between Recon property_scans (P1) and
--    VIZ scan data — unified table with scan_purpose column
-- ============================================================

DO $$ BEGIN
  CREATE TYPE scan_purpose_type AS ENUM ('recon', 'viz', 'combined', 'inspection', 'preservation');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE property_scans
  ADD COLUMN IF NOT EXISTS scan_purpose scan_purpose_type NOT NULL DEFAULT 'recon';

-- Index for filtering by purpose
CREATE INDEX IF NOT EXISTS idx_ps_scan_purpose ON property_scans(scan_purpose) WHERE deleted_at IS NULL;

-- ============================================================
-- 2. VIZ ↔ SKETCH BIDIRECTIONAL LINKS
--    VIZ scans → Sketch floor plans and vice versa
--    Shared coordinate system with transform offsets
-- ============================================================

CREATE TABLE IF NOT EXISTS viz_sketch_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- VIZ side
  scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,

  -- Sketch side
  floor_plan_id UUID NOT NULL REFERENCES property_floor_plans(id) ON DELETE CASCADE,

  -- Sync state
  sync_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (sync_status IN ('pending', 'syncing', 'synced', 'conflict', 'failed')),
  sync_direction TEXT NOT NULL DEFAULT 'viz_to_sketch'
    CHECK (sync_direction IN ('viz_to_sketch', 'sketch_to_viz', 'bidirectional')),
  last_synced_at TIMESTAMPTZ,
  last_sync_error TEXT,

  -- Coordinate transform (VIZ world coords → Sketch canvas coords)
  transform_offset_x NUMERIC(12,4) DEFAULT 0,
  transform_offset_y NUMERIC(12,4) DEFAULT 0,
  transform_scale NUMERIC(8,6) DEFAULT 1.0,
  transform_rotation_deg NUMERIC(6,2) DEFAULT 0,

  -- Room matching (VIZ rooms ↔ Sketch rooms)
  room_mappings JSONB DEFAULT '[]'::jsonb,
  -- [{viz_room_id, sketch_room_id, confidence, auto_matched}]

  -- Metadata
  created_by UUID REFERENCES auth.users(id),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_vsl_company ON viz_sketch_links(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_vsl_scan ON viz_sketch_links(scan_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_vsl_floor_plan ON viz_sketch_links(floor_plan_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_vsl_status ON viz_sketch_links(sync_status) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_vsl_unique_pair ON viz_sketch_links(scan_id, floor_plan_id) WHERE deleted_at IS NULL;

ALTER TABLE viz_sketch_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY vsl_select ON viz_sketch_links FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY vsl_insert ON viz_sketch_links FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY vsl_update ON viz_sketch_links FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY vsl_delete ON viz_sketch_links FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('viz_sketch_links');
CREATE TRIGGER vsl_audit AFTER INSERT OR UPDATE OR DELETE ON viz_sketch_links
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 3. VIZ → ESTIMATE LINKS
--    Renovation config in VIZ generates estimate line items
--    Material swaps, texture changes → estimate_line_items
-- ============================================================

CREATE TABLE IF NOT EXISTS viz_estimate_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- VIZ side
  scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,

  -- Estimate side
  estimate_id UUID NOT NULL REFERENCES estimates(id) ON DELETE CASCADE,

  -- Link type
  link_type TEXT NOT NULL DEFAULT 'manual'
    CHECK (link_type IN ('manual', 'auto_generated', 'renovation_config')),

  -- VIZ configuration snapshot (materials, textures, room mods at time of estimate)
  viz_config_snapshot JSONB DEFAULT '{}'::jsonb,

  -- Sync tracking
  is_synced BOOLEAN NOT NULL DEFAULT false,
  last_synced_at TIMESTAMPTZ,
  items_generated INTEGER DEFAULT 0,

  -- Metadata
  generated_by UUID REFERENCES auth.users(id),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_vel_company ON viz_estimate_links(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_vel_scan ON viz_estimate_links(scan_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_vel_estimate ON viz_estimate_links(estimate_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_vel_unique_pair ON viz_estimate_links(scan_id, estimate_id) WHERE deleted_at IS NULL;

ALTER TABLE viz_estimate_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY vel_select ON viz_estimate_links FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY vel_insert ON viz_estimate_links FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY vel_update ON viz_estimate_links FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY vel_delete ON viz_estimate_links FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('viz_estimate_links');
CREATE TRIGGER vel_audit AFTER INSERT OR UPDATE OR DELETE ON viz_estimate_links
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 4. MATERIAL ESTIMATE MAP
--    Maps material_catalog entries to estimate line items
--    "This specific material → this line item in this estimate"
-- ============================================================

CREATE TABLE IF NOT EXISTS material_estimate_map (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Material side
  material_catalog_id UUID NOT NULL REFERENCES material_catalog(id) ON DELETE CASCADE,

  -- Estimate side
  estimate_id UUID NOT NULL REFERENCES estimates(id) ON DELETE CASCADE,
  estimate_line_item_id UUID REFERENCES estimate_line_items(id) ON DELETE SET NULL,

  -- Quantities
  quantity NUMERIC(12,4) NOT NULL DEFAULT 0,
  unit TEXT NOT NULL DEFAULT 'ea',
  waste_factor_pct NUMERIC(5,2) NOT NULL DEFAULT 10,
  quantity_with_waste NUMERIC(12,4) GENERATED ALWAYS AS (
    quantity * (1 + waste_factor_pct / 100)
  ) STORED,

  -- Pricing snapshot (at time of mapping — may differ from catalog)
  unit_cost_snapshot NUMERIC(10,2) NOT NULL DEFAULT 0,
  total_cost NUMERIC(12,2) GENERATED ALWAYS AS (
    quantity * (1 + waste_factor_pct / 100) * unit_cost_snapshot
  ) STORED,

  -- Source of mapping
  source TEXT NOT NULL DEFAULT 'manual'
    CHECK (source IN ('manual', 'viz_config', 'trade_tool', 'auto_generated', 'recon_recommendation')),
  source_reference_id UUID,  -- ID of the viz_config or trade_tool_result that generated this

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_mem_company ON material_estimate_map(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_mem_material ON material_estimate_map(material_catalog_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_mem_estimate ON material_estimate_map(estimate_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_mem_line_item ON material_estimate_map(estimate_line_item_id) WHERE deleted_at IS NULL;

ALTER TABLE material_estimate_map ENABLE ROW LEVEL SECURITY;

CREATE POLICY mem_select ON material_estimate_map FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY mem_insert ON material_estimate_map FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY mem_update ON material_estimate_map FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY mem_delete ON material_estimate_map FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('material_estimate_map');
CREATE TRIGGER mem_audit AFTER INSERT OR UPDATE OR DELETE ON material_estimate_map
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 5. TRADE TOOL RESULTS
--    Persistent storage for calculator output (qty, unit,
--    material, labor hours). Enables "Add to Estimate" workflow.
-- ============================================================

CREATE TABLE IF NOT EXISTS trade_tool_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES auth.users(id),

  -- Tool identification
  tool_key TEXT NOT NULL,  -- e.g. 'hvac_load_calc', 'electrical_panel_calc', 'paint_calculator'
  tool_name TEXT NOT NULL,
  trade TEXT NOT NULL,     -- e.g. 'hvac', 'electrical', 'painting'

  -- Context
  job_id UUID REFERENCES jobs(id) ON DELETE SET NULL,
  property_scan_id UUID REFERENCES property_scans(id) ON DELETE SET NULL,
  property_address TEXT,

  -- Input snapshot (the parameters entered into the calculator)
  input_params JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- Output (the calculated results)
  output_summary TEXT NOT NULL,  -- human-readable summary
  output_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- [{name, quantity, unit, material_catalog_id?, unit_cost, labor_hours, notes}]

  -- Totals
  total_material_cost NUMERIC(12,2) DEFAULT 0,
  total_labor_hours NUMERIC(8,2) DEFAULT 0,
  total_estimated_cost NUMERIC(12,2) DEFAULT 0,

  -- Status
  is_finalized BOOLEAN NOT NULL DEFAULT false,  -- once finalized, no edits
  added_to_estimate BOOLEAN NOT NULL DEFAULT false,

  -- Metadata
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_ttr_company ON trade_tool_results(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ttr_created_by ON trade_tool_results(created_by) WHERE deleted_at IS NULL;
CREATE INDEX idx_ttr_tool_key ON trade_tool_results(tool_key) WHERE deleted_at IS NULL;
CREATE INDEX idx_ttr_trade ON trade_tool_results(trade) WHERE deleted_at IS NULL;
CREATE INDEX idx_ttr_job ON trade_tool_results(job_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ttr_property ON trade_tool_results(property_scan_id) WHERE deleted_at IS NULL;

ALTER TABLE trade_tool_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY ttr_select ON trade_tool_results FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY ttr_insert ON trade_tool_results FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY ttr_update ON trade_tool_results FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY ttr_delete ON trade_tool_results FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('trade_tool_results');
CREATE TRIGGER ttr_audit AFTER INSERT OR UPDATE OR DELETE ON trade_tool_results
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 6. TRADE TOOL → ESTIMATE LINKS (bridge table)
--    "Add to Estimate" from any calculator result
--    Supports batch import: multiple tool results → one estimate
-- ============================================================

CREATE TABLE IF NOT EXISTS trade_tool_estimate_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Tool side
  tool_result_id UUID NOT NULL REFERENCES trade_tool_results(id) ON DELETE CASCADE,

  -- Estimate side
  estimate_id UUID NOT NULL REFERENCES estimates(id) ON DELETE CASCADE,
  estimate_line_item_id UUID REFERENCES estimate_line_items(id) ON DELETE SET NULL,

  -- Item from the tool output that was imported
  tool_output_item_index INTEGER,  -- index into tool_result.output_items array
  item_name TEXT NOT NULL,
  quantity NUMERIC(12,4) NOT NULL DEFAULT 0,
  unit TEXT NOT NULL DEFAULT 'ea',
  unit_cost NUMERIC(10,2) NOT NULL DEFAULT 0,
  labor_hours NUMERIC(8,2) DEFAULT 0,

  -- Auto-matched material catalog entry (if found)
  material_catalog_id UUID REFERENCES material_catalog(id) ON DELETE SET NULL,

  -- Status
  import_status TEXT NOT NULL DEFAULT 'imported'
    CHECK (import_status IN ('imported', 'modified', 'removed')),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ttel_company ON trade_tool_estimate_links(company_id);
CREATE INDEX idx_ttel_tool_result ON trade_tool_estimate_links(tool_result_id);
CREATE INDEX idx_ttel_estimate ON trade_tool_estimate_links(estimate_id);
CREATE INDEX idx_ttel_line_item ON trade_tool_estimate_links(estimate_line_item_id);
CREATE UNIQUE INDEX idx_ttel_unique_import ON trade_tool_estimate_links(tool_result_id, estimate_id, tool_output_item_index)
  WHERE import_status != 'removed';

ALTER TABLE trade_tool_estimate_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY ttel_select ON trade_tool_estimate_links FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY ttel_insert ON trade_tool_estimate_links FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY ttel_update ON trade_tool_estimate_links FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY ttel_delete ON trade_tool_estimate_links FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('trade_tool_estimate_links');
CREATE TRIGGER ttel_audit AFTER INSERT OR UPDATE OR DELETE ON trade_tool_estimate_links
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 7. MATERIALS MASTER — Unified material hub
--    Links material_catalog (rendering/specs) with
--    supplier_directory (pricing/availability)
--    Prevents duplication between VIZ textures and supplier products
-- ============================================================

CREATE TABLE IF NOT EXISTS materials_master (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Classification
  material_type TEXT NOT NULL DEFAULT 'general'
    CHECK (material_type IN ('viz_texture', 'supplier_product', 'both', 'general')),
  name TEXT NOT NULL,
  name_normalized TEXT NOT NULL,
  description TEXT,

  -- Trade & category
  trade TEXT NOT NULL,
  category TEXT NOT NULL,
  subcategory TEXT,

  -- Cross-references
  material_catalog_id UUID REFERENCES material_catalog(id) ON DELETE SET NULL,
  supplier_product_id UUID REFERENCES supplier_products(id) ON DELETE SET NULL,
  supplier_directory_id UUID REFERENCES supplier_directory(id) ON DELETE SET NULL,

  -- VIZ rendering data (populated when material_type = 'viz_texture' or 'both')
  pbr_texture_url TEXT,
  pbr_normal_url TEXT,
  pbr_roughness NUMERIC(3,2),
  color_hex VARCHAR(7),
  render_preview_url TEXT,

  -- Physical properties
  dimensions_json JSONB,  -- {width, height, depth, unit}
  weight_per_unit NUMERIC(10,4),
  weight_unit TEXT DEFAULT 'lbs',

  -- Identifiers
  upc TEXT,
  manufacturer_sku TEXT,
  manufacturer TEXT,

  -- Status
  is_verified BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_mm_name_norm ON materials_master(name_normalized) WHERE deleted_at IS NULL;
CREATE INDEX idx_mm_type ON materials_master(material_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_mm_trade ON materials_master(trade) WHERE deleted_at IS NULL;
CREATE INDEX idx_mm_category ON materials_master(trade, category) WHERE deleted_at IS NULL;
CREATE INDEX idx_mm_material_catalog ON materials_master(material_catalog_id) WHERE material_catalog_id IS NOT NULL;
CREATE INDEX idx_mm_supplier_product ON materials_master(supplier_product_id) WHERE supplier_product_id IS NOT NULL;
CREATE INDEX idx_mm_upc ON materials_master(upc) WHERE upc IS NOT NULL AND deleted_at IS NULL;

ALTER TABLE materials_master ENABLE ROW LEVEL SECURITY;

-- Readable by all authenticated users (master reference data)
CREATE POLICY mm_select ON materials_master FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

-- Only super_admin can modify the master registry
CREATE POLICY mm_admin ON materials_master FOR ALL TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin');

SELECT update_updated_at('materials_master');
CREATE TRIGGER mm_audit AFTER INSERT OR UPDATE OR DELETE ON materials_master
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 8. ADD RECON → TRADE TOOLS MEASUREMENT PRE-FILL COLUMNS
--    Recon scan measurements auto-populate calculator inputs
--    when launched from a property context
-- ============================================================

-- Add pre-computed measurement summary to property_scans for quick access
ALTER TABLE property_scans
  ADD COLUMN IF NOT EXISTS measurement_summary JSONB DEFAULT '{}'::jsonb;
  -- {roof_sqft, roof_pitch, wall_sqft_total, linear_ft_exterior,
  --  floor_sqft_per_floor: [{floor: 1, sqft: 1200}], total_sqft,
  --  window_count, door_count, room_count, stories, lot_sqft}

COMMENT ON COLUMN property_scans.measurement_summary IS
  'Pre-computed measurements from scan data for trade tool pre-fill. Updated by Recon scan pipeline.';


-- ============================================================
-- 9. HELPER: fn_link_tool_result_to_estimate
--    Imports all output items from a trade_tool_result into
--    an estimate, creating line items and bridge links
-- ============================================================

CREATE OR REPLACE FUNCTION fn_link_tool_result_to_estimate(
  p_tool_result_id UUID,
  p_estimate_id UUID,
  p_estimate_area_id UUID DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tool trade_tool_results;
  v_item JSONB;
  v_idx INTEGER := 0;
  v_line_item_id UUID;
  v_company_id UUID;
  v_count INTEGER := 0;
BEGIN
  -- Get the tool result
  SELECT * INTO v_tool FROM trade_tool_results WHERE id = p_tool_result_id AND deleted_at IS NULL;
  IF v_tool IS NULL THEN
    RAISE EXCEPTION 'Trade tool result not found: %', p_tool_result_id;
  END IF;

  v_company_id := v_tool.company_id;

  -- Verify estimate belongs to same company
  IF NOT EXISTS (
    SELECT 1 FROM estimates WHERE id = p_estimate_id AND company_id = v_company_id AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Estimate not found or company mismatch';
  END IF;

  -- Iterate output items
  FOR v_item IN SELECT * FROM jsonb_array_elements(v_tool.output_items)
  LOOP
    -- Create estimate line item
    INSERT INTO estimate_line_items (
      estimate_id,
      area_id,
      item_id,
      description,
      quantity,
      unit_price,
      company_id
    ) VALUES (
      p_estimate_id,
      p_estimate_area_id,
      (v_item ->> 'material_catalog_id')::uuid,
      COALESCE(v_item ->> 'name', 'Calculator item'),
      COALESCE((v_item ->> 'quantity')::numeric, 0),
      COALESCE((v_item ->> 'unit_cost')::numeric, 0),
      v_company_id
    )
    RETURNING id INTO v_line_item_id;

    -- Create bridge link
    INSERT INTO trade_tool_estimate_links (
      company_id,
      tool_result_id,
      estimate_id,
      estimate_line_item_id,
      tool_output_item_index,
      item_name,
      quantity,
      unit,
      unit_cost,
      labor_hours,
      material_catalog_id
    ) VALUES (
      v_company_id,
      p_tool_result_id,
      p_estimate_id,
      v_line_item_id,
      v_idx,
      COALESCE(v_item ->> 'name', 'Calculator item'),
      COALESCE((v_item ->> 'quantity')::numeric, 0),
      COALESCE(v_item ->> 'unit', 'ea'),
      COALESCE((v_item ->> 'unit_cost')::numeric, 0),
      COALESCE((v_item ->> 'labor_hours')::numeric, 0),
      (v_item ->> 'material_catalog_id')::uuid
    );

    v_idx := v_idx + 1;
    v_count := v_count + 1;
  END LOOP;

  -- Mark tool result as added
  UPDATE trade_tool_results
    SET added_to_estimate = true, updated_at = now()
    WHERE id = p_tool_result_id;

  RETURN v_count;
END;
$$;


-- ============================================================
-- 10. HELPER: fn_prefill_tool_from_recon
--     Given a property_scan_id and tool_key, returns measurement
--     data relevant to that calculator for input pre-population
-- ============================================================

CREATE OR REPLACE FUNCTION fn_prefill_tool_from_recon(
  p_scan_id UUID,
  p_tool_key TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_scan property_scans;
  v_result JSONB := '{}'::jsonb;
  v_roof RECORD;
BEGIN
  SELECT * INTO v_scan FROM property_scans WHERE id = p_scan_id AND deleted_at IS NULL;
  IF v_scan IS NULL THEN RETURN v_result; END IF;

  -- Start with measurement_summary if available
  IF v_scan.measurement_summary IS NOT NULL AND v_scan.measurement_summary != '{}'::jsonb THEN
    v_result := v_scan.measurement_summary;
  END IF;

  -- Add roof measurements if tool needs them
  IF p_tool_key IN ('roofing_calculator', 'gutter_calculator', 'solar_calculator', 'insulation_calculator') THEN
    SELECT total_area_sqft, predominant_pitch, facet_count, total_ridge_length_ft,
           total_eave_length_ft, total_valley_length_ft
    INTO v_roof
    FROM roof_measurements WHERE scan_id = p_scan_id LIMIT 1;

    IF FOUND THEN
      v_result := v_result || jsonb_build_object(
        'roof_sqft', v_roof.total_area_sqft,
        'roof_pitch', v_roof.predominant_pitch,
        'facet_count', v_roof.facet_count,
        'ridge_length_ft', v_roof.total_ridge_length_ft,
        'eave_length_ft', v_roof.total_eave_length_ft,
        'valley_length_ft', v_roof.total_valley_length_ft
      );
    END IF;
  END IF;

  -- Add scan metadata
  v_result := v_result || jsonb_build_object(
    'scan_id', v_scan.id,
    'address', v_scan.address,
    'latitude', v_scan.latitude,
    'longitude', v_scan.longitude,
    'scan_confidence', v_scan.confidence_score,
    'scan_sources', v_scan.scan_sources
  );

  RETURN v_result;
END;
$$;
