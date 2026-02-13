-- T8a: Restoration Line Items — ZAFTO's own line item database
-- Phase T (Programs/TPA Module) — Sprint T8
-- Z-WTR-xxx codes, own descriptions + pricing, Xactimate category/selector mapping

-- ============================================================================
-- TABLE: RESTORATION LINE ITEMS
-- ============================================================================

CREATE TABLE restoration_line_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),  -- NULL = system default
  -- ZAFTO code system
  zafto_code TEXT NOT NULL,  -- e.g., Z-WTR-001, Z-DEM-005, Z-DRY-010
  category TEXT NOT NULL CHECK (category IN (
    'water_extraction', 'demolition', 'drying_equipment', 'cleaning_treatment',
    'monitoring', 'contents', 'hazmat', 'temporary_repairs', 'reconstruction',
    'mold_remediation', 'fire_restoration', 'general', 'labor', 'equipment_rental'
  )),
  -- Description
  name TEXT NOT NULL,
  description TEXT,
  -- Pricing
  unit TEXT NOT NULL DEFAULT 'SF' CHECK (unit IN (
    'SF', 'LF', 'SY', 'EA', 'HR', 'DY', 'WK', 'MO', 'CY', 'GAL', 'LS'
  )),
  default_price NUMERIC(10,2) NOT NULL DEFAULT 0,
  min_price NUMERIC(10,2),
  max_price NUMERIC(10,2),
  -- Xactimate mapping (for export reference only — NOT generating ESX)
  xact_category TEXT,      -- e.g., 'WTR', 'DEM', 'CLN'
  xact_selector TEXT,      -- e.g., 'WTREXSM', 'DEMMDF'
  xact_description TEXT,   -- Xactimate's description for cross-reference
  -- Metadata
  is_system BOOLEAN DEFAULT false,  -- system defaults vs company custom
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  trade_categories TEXT[] DEFAULT '{}',  -- which trades can use this
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE restoration_line_items ENABLE ROW LEVEL SECURITY;

-- System items (company_id IS NULL) are visible to all
CREATE POLICY rli_select ON restoration_line_items
  FOR SELECT USING (
    company_id IS NULL
    OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

-- Only company items can be inserted/updated/deleted
CREATE POLICY rli_insert ON restoration_line_items
  FOR INSERT WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY rli_update ON restoration_line_items
  FOR UPDATE USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY rli_delete ON restoration_line_items
  FOR DELETE USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_rli_company ON restoration_line_items(company_id);
CREATE INDEX idx_rli_category ON restoration_line_items(category);
CREATE INDEX idx_rli_code ON restoration_line_items(zafto_code);
CREATE INDEX idx_rli_xact ON restoration_line_items(xact_category, xact_selector);
CREATE INDEX idx_rli_active ON restoration_line_items(is_active) WHERE is_active = true;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER rli_updated BEFORE UPDATE ON restoration_line_items FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER rli_audit AFTER INSERT OR UPDATE OR DELETE ON restoration_line_items FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ============================================================================
-- SEED: ~50 system restoration line items
-- ============================================================================

INSERT INTO restoration_line_items (company_id, zafto_code, category, name, description, unit, default_price, xact_category, xact_selector, is_system, sort_order) VALUES
-- Water Extraction (Z-WTR)
(NULL, 'Z-WTR-001', 'water_extraction', 'Water extraction - carpet', 'Extract standing water from carpet using truck-mounted or portable extractor', 'SF', 0.65, 'WTR', 'WTREXCPT', true, 1),
(NULL, 'Z-WTR-002', 'water_extraction', 'Water extraction - hard surface', 'Extract standing water from hard surface flooring (tile, wood, concrete)', 'SF', 0.55, 'WTR', 'WTREXHS', true, 2),
(NULL, 'Z-WTR-003', 'water_extraction', 'Water extraction - sub-floor', 'Extract water from sub-floor via injection/extraction method', 'SF', 1.25, 'WTR', 'WTREXSF', true, 3),
(NULL, 'Z-WTR-004', 'water_extraction', 'Water extraction - contents', 'Extract water from affected contents and personal property', 'HR', 45.00, 'WTR', NULL, true, 4),
(NULL, 'Z-WTR-005', 'water_extraction', 'Emergency water extraction', 'After-hours or emergency extraction service', 'HR', 85.00, 'WTR', NULL, true, 5),

-- Demolition (Z-DEM)
(NULL, 'Z-DEM-001', 'demolition', 'Remove wet carpet', 'Remove water-damaged carpet and pad, bag and dispose', 'SF', 1.10, 'DEM', 'DEMCPT', true, 10),
(NULL, 'Z-DEM-002', 'demolition', 'Remove wet drywall - 2ft flood cut', 'Remove drywall 2ft above water line, controlled demolition', 'LF', 3.50, 'DEM', 'DEMDW2', true, 11),
(NULL, 'Z-DEM-003', 'demolition', 'Remove wet drywall - 4ft flood cut', 'Remove drywall 4ft above water line, controlled demolition', 'LF', 5.75, 'DEM', 'DEMDW4', true, 12),
(NULL, 'Z-DEM-004', 'demolition', 'Remove wet insulation', 'Remove wet insulation from wall cavities or attic space', 'SF', 0.85, 'DEM', 'DEMINS', true, 13),
(NULL, 'Z-DEM-005', 'demolition', 'Remove baseboard/trim', 'Carefully remove baseboard, shoe mold, or trim for drying access', 'LF', 1.25, 'DEM', 'DEMBB', true, 14),
(NULL, 'Z-DEM-006', 'demolition', 'Remove vinyl/laminate flooring', 'Remove water-damaged vinyl or laminate flooring', 'SF', 1.50, 'DEM', 'DEMVNL', true, 15),
(NULL, 'Z-DEM-007', 'demolition', 'Remove hardwood flooring', 'Remove water-damaged hardwood flooring', 'SF', 2.25, 'DEM', 'DEMHWD', true, 16),
(NULL, 'Z-DEM-008', 'demolition', 'Remove cabinetry', 'Detach and remove water-damaged base cabinetry', 'LF', 8.50, 'DEM', 'DEMCAB', true, 17),

-- Drying Equipment (Z-DRY)
(NULL, 'Z-DRY-001', 'drying_equipment', 'Dehumidifier - LGR', 'Low-grain refrigerant dehumidifier setup and monitoring', 'DY', 85.00, 'DRY', 'DRYLGR', true, 20),
(NULL, 'Z-DRY-002', 'drying_equipment', 'Dehumidifier - desiccant', 'Desiccant dehumidifier for specialty/cold-weather drying', 'DY', 175.00, 'DRY', 'DRYDES', true, 21),
(NULL, 'Z-DRY-003', 'drying_equipment', 'Air mover', 'High-velocity air mover placement and monitoring', 'DY', 35.00, 'DRY', 'DRYAM', true, 22),
(NULL, 'Z-DRY-004', 'drying_equipment', 'Air scrubber - HEPA', 'HEPA air scrubber for particulate and odor control', 'DY', 95.00, 'DRY', 'DRYAS', true, 23),
(NULL, 'Z-DRY-005', 'drying_equipment', 'Injectidry system', 'Wall cavity drying system setup and monitoring', 'DY', 125.00, 'DRY', 'DRYINJ', true, 24),
(NULL, 'Z-DRY-006', 'drying_equipment', 'Negative air machine', 'Negative air/containment air filtration device', 'DY', 110.00, 'DRY', 'DRYNEG', true, 25),

-- Cleaning & Treatment (Z-CLN)
(NULL, 'Z-CLN-001', 'cleaning_treatment', 'Antimicrobial application', 'Apply EPA-registered antimicrobial to affected surfaces', 'SF', 0.35, 'CLN', 'CLNANTI', true, 30),
(NULL, 'Z-CLN-002', 'cleaning_treatment', 'HEPA vacuum - surfaces', 'HEPA vacuum all affected surfaces post-demolition', 'SF', 0.25, 'CLN', 'CLNHEPA', true, 31),
(NULL, 'Z-CLN-003', 'cleaning_treatment', 'Deodorization - ozone', 'Ozone treatment for odor removal', 'DY', 150.00, 'CLN', 'CLNOZ', true, 32),
(NULL, 'Z-CLN-004', 'cleaning_treatment', 'Deodorization - hydroxyl', 'Hydroxyl generator for safe occupied-space deodorization', 'DY', 125.00, 'CLN', 'CLNHYD', true, 33),
(NULL, 'Z-CLN-005', 'cleaning_treatment', 'Thermal fogging', 'Thermal fogging for fire/smoke odor penetration', 'SF', 0.20, 'CLN', 'CLNTF', true, 34),
(NULL, 'Z-CLN-006', 'cleaning_treatment', 'Soda blasting', 'Soda blasting for soot/smoke residue removal', 'SF', 3.50, 'CLN', 'CLNSODA', true, 35),

-- Monitoring (Z-MON)
(NULL, 'Z-MON-001', 'monitoring', 'Moisture mapping - initial', 'Initial moisture mapping and documentation of all affected areas', 'EA', 250.00, 'MON', NULL, true, 40),
(NULL, 'Z-MON-002', 'monitoring', 'Daily moisture monitoring', 'Daily moisture reading documentation per IICRC S500', 'DY', 75.00, 'MON', NULL, true, 41),
(NULL, 'Z-MON-003', 'monitoring', 'Psychrometric logging', 'Temperature and humidity logging for drying verification', 'DY', 25.00, 'MON', NULL, true, 42),
(NULL, 'Z-MON-004', 'monitoring', 'Thermal imaging survey', 'Infrared thermal imaging to identify hidden moisture', 'EA', 175.00, 'MON', NULL, true, 43),

-- Contents (Z-CON)
(NULL, 'Z-CON-001', 'contents', 'Contents manipulation - light', 'Move/protect unaffected contents (furniture, boxes)', 'HR', 40.00, 'CON', NULL, true, 50),
(NULL, 'Z-CON-002', 'contents', 'Contents manipulation - heavy', 'Move heavy furniture, appliances requiring 2+ crew', 'HR', 55.00, 'CON', NULL, true, 51),
(NULL, 'Z-CON-003', 'contents', 'Contents cleaning - light', 'Clean affected personal property (wiping, HEPA)', 'HR', 45.00, 'CON', NULL, true, 52),
(NULL, 'Z-CON-004', 'contents', 'Contents pack-out', 'Full contents pack-out, inventory, and storage', 'HR', 50.00, 'CON', NULL, true, 53),

-- Hazmat (Z-HAZ)
(NULL, 'Z-HAZ-001', 'hazmat', 'Containment setup', 'Poly containment barrier with negative air', 'LF', 4.50, 'HAZ', NULL, true, 60),
(NULL, 'Z-HAZ-002', 'hazmat', 'Asbestos testing', 'Collect and send samples for asbestos analysis', 'EA', 45.00, 'HAZ', NULL, true, 61),
(NULL, 'Z-HAZ-003', 'hazmat', 'Lead paint testing', 'XRF or swab testing for lead-based paint', 'EA', 35.00, 'HAZ', NULL, true, 62),
(NULL, 'Z-HAZ-004', 'hazmat', 'Biohazard cleaning', 'Category 3 water / sewage contamination cleaning', 'SF', 2.50, 'HAZ', NULL, true, 63),

-- Temporary Repairs (Z-TMP)
(NULL, 'Z-TMP-001', 'temporary_repairs', 'Board-up window', 'Emergency board-up per window opening', 'EA', 75.00, 'TMP', NULL, true, 70),
(NULL, 'Z-TMP-002', 'temporary_repairs', 'Tarp roof', 'Emergency tarp application to damaged roof area', 'SQ', 125.00, 'TMP', NULL, true, 71),
(NULL, 'Z-TMP-003', 'temporary_repairs', 'Temporary power', 'Generator rental and setup for drying equipment', 'DY', 200.00, 'TMP', NULL, true, 72),
(NULL, 'Z-TMP-004', 'temporary_repairs', 'Temporary plumbing repair', 'Temporary water shut-off or pipe cap', 'EA', 150.00, 'TMP', NULL, true, 73),

-- Reconstruction (Z-REC)
(NULL, 'Z-REC-001', 'reconstruction', 'Drywall replacement - hang', 'Hang new drywall (material + labor)', 'SF', 2.75, 'REC', NULL, true, 80),
(NULL, 'Z-REC-002', 'reconstruction', 'Drywall replacement - finish', 'Tape, mud, texture, prime drywall', 'SF', 2.25, 'REC', NULL, true, 81),
(NULL, 'Z-REC-003', 'reconstruction', 'Paint - 2 coats', 'Prime and 2 coats paint on repaired surfaces', 'SF', 1.85, 'REC', NULL, true, 82),
(NULL, 'Z-REC-004', 'reconstruction', 'Baseboard replacement', 'Install new baseboard trim to match existing', 'LF', 3.50, 'REC', NULL, true, 83),
(NULL, 'Z-REC-005', 'reconstruction', 'Insulation replacement', 'Install new insulation in wall cavities', 'SF', 1.15, 'REC', NULL, true, 84),
(NULL, 'Z-REC-006', 'reconstruction', 'Carpet replacement', 'Supply and install replacement carpet and pad', 'SF', 4.50, 'REC', NULL, true, 85),

-- Mold Remediation (Z-MLD)
(NULL, 'Z-MLD-001', 'mold_remediation', 'Mold testing - air sample', 'Collect air samples for mold spore analysis', 'EA', 150.00, 'MLD', NULL, true, 90),
(NULL, 'Z-MLD-002', 'mold_remediation', 'Mold remediation - surface', 'HEPA vacuum + antimicrobial treatment of mold-affected surfaces', 'SF', 4.50, 'MLD', NULL, true, 91),
(NULL, 'Z-MLD-003', 'mold_remediation', 'Mold remediation - structural', 'Remove and replace mold-damaged structural materials', 'SF', 8.00, 'MLD', NULL, true, 92);

-- SQ unit was used but not in check — add it
-- Note: SQ (roofing square = 100 SF) was used for tarp roof. This is handled as a known unit.
-- If needed, alter the CHECK constraint:
ALTER TABLE restoration_line_items DROP CONSTRAINT restoration_line_items_unit_check;
ALTER TABLE restoration_line_items ADD CONSTRAINT restoration_line_items_unit_check
  CHECK (unit IN ('SF', 'LF', 'SY', 'EA', 'HR', 'DY', 'WK', 'MO', 'CY', 'GAL', 'LS', 'SQ'));

-- Also add xact_code_mapping column to estimate_line_items for export reference
-- (Only if estimate_line_items table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'estimate_line_items') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'estimate_line_items' AND column_name = 'xact_code') THEN
      ALTER TABLE estimate_line_items ADD COLUMN xact_code TEXT;
      ALTER TABLE estimate_line_items ADD COLUMN restoration_line_item_id UUID REFERENCES restoration_line_items(id);
    END IF;
  END IF;
END $$;
