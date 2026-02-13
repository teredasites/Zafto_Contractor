-- SK8: Auto-Estimate Pipeline
-- Adds: property_floor_plan_id on estimates (links estimate to source floor plan)
--        wall_sf, ceiling_sf, baseboard_lf on estimate_areas (precise measurements from sketch)

-- ============================================================================
-- ALTER estimates — add floor plan source link
-- ============================================================================

ALTER TABLE estimates
  ADD COLUMN IF NOT EXISTS property_floor_plan_id UUID
    REFERENCES property_floor_plans(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_estimates_floor_plan
  ON estimates(property_floor_plan_id) WHERE property_floor_plan_id IS NOT NULL;

-- ============================================================================
-- ALTER estimate_areas — add wall/ceiling/baseboard measurement columns
-- ============================================================================

ALTER TABLE estimate_areas
  ADD COLUMN IF NOT EXISTS wall_sf DECIMAL(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS ceiling_sf DECIMAL(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS baseboard_lf DECIMAL(10,2) DEFAULT 0;

COMMENT ON COLUMN estimate_areas.wall_sf IS 'Total wall square footage (net of door/window openings)';
COMMENT ON COLUMN estimate_areas.ceiling_sf IS 'Ceiling square footage (flat assumption, same as floor area)';
COMMENT ON COLUMN estimate_areas.baseboard_lf IS 'Baseboard linear footage (perimeter minus door widths)';
COMMENT ON COLUMN estimates.property_floor_plan_id IS 'Source floor plan that auto-generated this estimate (SK8)';
