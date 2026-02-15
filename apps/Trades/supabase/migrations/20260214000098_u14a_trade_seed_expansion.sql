-- ============================================================
-- U14a: Universal Trade Support — Expanded units, categories, line items
-- ============================================================

-- ============================================================
-- 1. Add missing measurement units (16 → 25+)
-- ============================================================
INSERT INTO estimate_units (code, name, abbreviation) VALUES
  ('BDL', 'Bundle', 'bdl'),
  ('PLT', 'Pallet', 'plt'),
  ('PNL', 'Panel', 'pnl'),
  ('SHT', 'Sheet', 'sht'),
  ('YD', 'Yard', 'yd'),
  ('BX', 'Box', 'box'),
  ('BG', 'Bag', 'bag'),
  ('CN', 'Can', 'can'),
  ('TN', 'Ton', 'ton'),
  ('FT', 'Foot', 'ft')
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- 2. Add missing estimate categories
-- ============================================================
INSERT INTO estimate_categories (code, name, labor_pct, material_pct, equipment_pct) VALUES
  ('SLR', 'Solar', 40, 50, 10),
  ('FNC', 'Fencing', 55, 40, 5),
  ('PVG', 'Paving', 40, 45, 15),
  ('GRM', 'General Remodel', 55, 35, 10),
  ('WND', 'Windows & Doors', 40, 55, 5),
  ('SPF', 'Spray Foam', 45, 45, 10),
  ('FRS', 'Fire/Smoke Restoration', 50, 30, 20),
  ('MLB', 'Mold Remediation', 55, 20, 25),
  ('TRM', 'Trim & Millwork', 60, 35, 5)
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- 3. Add line items for new categories
-- Pricing is separate (estimate_pricing table) — items are descriptive only
-- ============================================================
INSERT INTO estimate_items (zafto_code, category_id, description, unit_code, trade, is_common, source)
SELECT v.zafto_code, ec.id, v.description, v.unit_code, v.trade, true, 'zafto'
FROM (VALUES
  -- Solar (SLR)
  ('Z-SLR-001', 'SLR', 'Solar Panel — 400W Monocrystalline', 'EA', 'solar'),
  ('Z-SLR-002', 'SLR', 'Roof Racking System — Rail Mount', 'LF', 'solar'),
  ('Z-SLR-003', 'SLR', 'String Inverter — 7.6kW', 'EA', 'solar'),
  ('Z-SLR-004', 'SLR', 'Microinverter — Per Panel', 'EA', 'solar'),
  ('Z-SLR-005', 'SLR', 'Battery Storage — 10kWh', 'EA', 'solar'),
  ('Z-SLR-006', 'SLR', 'AC/DC Disconnect Switch', 'EA', 'solar'),
  ('Z-SLR-007', 'SLR', 'Conduit Run — EMT', 'LF', 'solar'),
  ('Z-SLR-008', 'SLR', 'Meter/Net Metering Setup', 'EA', 'solar'),
  ('Z-SLR-009', 'SLR', 'Roof Penetration Flashing', 'EA', 'solar'),
  ('Z-SLR-010', 'SLR', 'Monitoring System Setup', 'EA', 'solar'),
  -- Fencing (FNC)
  ('Z-FNC-001', 'FNC', 'Wood Privacy Fence — 6ft Cedar', 'LF', 'fencing'),
  ('Z-FNC-002', 'FNC', 'Wood Picket Fence — 4ft', 'LF', 'fencing'),
  ('Z-FNC-003', 'FNC', 'Vinyl Privacy Fence — 6ft', 'LF', 'fencing'),
  ('Z-FNC-004', 'FNC', 'Chain Link Fence — 4ft', 'LF', 'fencing'),
  ('Z-FNC-005', 'FNC', 'Chain Link Fence — 6ft', 'LF', 'fencing'),
  ('Z-FNC-006', 'FNC', 'Wrought Iron Fence — 4ft', 'LF', 'fencing'),
  ('Z-FNC-007', 'FNC', 'Aluminum Fence Panel — 4ft', 'LF', 'fencing'),
  ('Z-FNC-008', 'FNC', 'Fence Post — Wood 4x4', 'EA', 'fencing'),
  ('Z-FNC-009', 'FNC', 'Fence Post — Steel', 'EA', 'fencing'),
  ('Z-FNC-010', 'FNC', 'Gate — Standard Walk', 'EA', 'fencing'),
  ('Z-FNC-011', 'FNC', 'Gate — Double Drive', 'EA', 'fencing'),
  ('Z-FNC-012', 'FNC', 'Fence Removal — Existing', 'LF', 'fencing'),
  -- Paving (PVG)
  ('Z-PVG-001', 'PVG', 'Asphalt Paving — Driveway', 'SF', 'paving'),
  ('Z-PVG-002', 'PVG', 'Asphalt Seal Coat', 'SF', 'paving'),
  ('Z-PVG-003', 'PVG', 'Concrete Pavers — Standard', 'SF', 'paving'),
  ('Z-PVG-004', 'PVG', 'Brick Pavers — Herringbone', 'SF', 'paving'),
  ('Z-PVG-005', 'PVG', 'Paver Base Prep — Gravel + Sand', 'SF', 'paving'),
  ('Z-PVG-006', 'PVG', 'Edging — Paver Restraint', 'LF', 'paving'),
  ('Z-PVG-007', 'PVG', 'Polymeric Sand — Joint Fill', 'SF', 'paving'),
  ('Z-PVG-008', 'PVG', 'Asphalt Patch/Repair', 'SF', 'paving'),
  -- General Remodel (GRM)
  ('Z-GRM-001', 'GRM', 'Project Management — Per Week', 'EA', 'general'),
  ('Z-GRM-002', 'GRM', 'Permit Filing + Fee', 'EA', 'general'),
  ('Z-GRM-003', 'GRM', 'Temporary Protection — Floors', 'SF', 'general'),
  ('Z-GRM-004', 'GRM', 'Temporary Protection — Walls', 'SF', 'general'),
  ('Z-GRM-005', 'GRM', 'Dust Barrier / Containment', 'EA', 'general'),
  ('Z-GRM-006', 'GRM', 'Dumpster Rental — 20yd', 'DA', 'general'),
  ('Z-GRM-007', 'GRM', 'Dumpster Rental — 30yd', 'DA', 'general'),
  ('Z-GRM-008', 'GRM', 'Final Clean — Post-Construction', 'SF', 'general'),
  -- Windows & Doors (WND)
  ('Z-WND-001', 'WND', 'Vinyl Window — Double Hung Standard', 'EA', 'windows_doors'),
  ('Z-WND-002', 'WND', 'Vinyl Window — Sliding', 'EA', 'windows_doors'),
  ('Z-WND-003', 'WND', 'Vinyl Window — Picture/Fixed', 'EA', 'windows_doors'),
  ('Z-WND-004', 'WND', 'Egress Window — Basement', 'EA', 'windows_doors'),
  ('Z-WND-005', 'WND', 'Entry Door — Fiberglass', 'EA', 'windows_doors'),
  ('Z-WND-006', 'WND', 'Entry Door — Steel', 'EA', 'windows_doors'),
  ('Z-WND-007', 'WND', 'Sliding Patio Door', 'EA', 'windows_doors'),
  ('Z-WND-008', 'WND', 'French Door Set', 'EA', 'windows_doors'),
  ('Z-WND-009', 'WND', 'Storm Door', 'EA', 'windows_doors'),
  ('Z-WND-010', 'WND', 'Window Trim — Interior', 'LF', 'windows_doors'),
  -- Fire/Smoke Restoration (FRS)
  ('Z-FRS-001', 'FRS', 'Smoke/Soot Cleaning — Walls', 'SF', 'fire_restoration'),
  ('Z-FRS-002', 'FRS', 'Smoke/Soot Cleaning — Ceiling', 'SF', 'fire_restoration'),
  ('Z-FRS-003', 'FRS', 'Thermal Fogging — Odor', 'SF', 'fire_restoration'),
  ('Z-FRS-004', 'FRS', 'Ozone Treatment — Room', 'EA', 'fire_restoration'),
  ('Z-FRS-005', 'FRS', 'Contents Pack-Out', 'EA', 'fire_restoration'),
  ('Z-FRS-006', 'FRS', 'Structural Char Removal', 'SF', 'fire_restoration'),
  ('Z-FRS-007', 'FRS', 'Air Scrubber — HEPA', 'DA', 'fire_restoration'),
  ('Z-FRS-008', 'FRS', 'Board-Up Service', 'EA', 'fire_restoration'),
  -- Mold Remediation (MLB)
  ('Z-MLB-001', 'MLB', 'Mold Assessment — Visual + Moisture', 'EA', 'mold'),
  ('Z-MLB-002', 'MLB', 'Air Quality Testing', 'EA', 'mold'),
  ('Z-MLB-003', 'MLB', 'Containment Setup — Full', 'EA', 'mold'),
  ('Z-MLB-004', 'MLB', 'Mold Removal — Surface', 'SF', 'mold'),
  ('Z-MLB-005', 'MLB', 'Mold Removal — Behind Walls', 'SF', 'mold'),
  ('Z-MLB-006', 'MLB', 'HEPA Vacuuming', 'SF', 'mold'),
  ('Z-MLB-007', 'MLB', 'Antimicrobial Treatment', 'SF', 'mold'),
  ('Z-MLB-008', 'MLB', 'Post-Remediation Verification', 'EA', 'mold'),
  -- Landscaping expanded items (LND already exists)
  ('Z-LND-010', 'LND', 'Sod Installation', 'SF', 'landscaping'),
  ('Z-LND-011', 'LND', 'Mulch — Bed Coverage', 'CY', 'landscaping'),
  ('Z-LND-012', 'LND', 'Retaining Wall — Block', 'SF', 'landscaping'),
  ('Z-LND-013', 'LND', 'French Drain', 'LF', 'landscaping'),
  ('Z-LND-014', 'LND', 'Irrigation System — Per Zone', 'EA', 'landscaping'),
  ('Z-LND-015', 'LND', 'Tree Removal — Small (<12in)', 'EA', 'landscaping'),
  ('Z-LND-016', 'LND', 'Tree Removal — Large (>24in)', 'EA', 'landscaping'),
  ('Z-LND-017', 'LND', 'Grading — Rough', 'SF', 'landscaping'),
  -- Gutters expanded items (GUT already exists)
  ('Z-GUT-005', 'GUT', 'Seamless Aluminum Gutter — 5in', 'LF', 'gutters'),
  ('Z-GUT-006', 'GUT', 'Seamless Aluminum Gutter — 6in', 'LF', 'gutters'),
  ('Z-GUT-007', 'GUT', 'Copper Gutter — Half Round', 'LF', 'gutters'),
  ('Z-GUT-008', 'GUT', 'Gutter Guard — Mesh', 'LF', 'gutters'),
  ('Z-GUT-009', 'GUT', 'Downspout Extension', 'EA', 'gutters'),
  ('Z-GUT-010', 'GUT', 'Gutter Cleaning', 'LF', 'gutters')
) AS v(zafto_code, cat_code, description, unit_code, trade)
JOIN estimate_categories ec ON ec.code = v.cat_code
WHERE NOT EXISTS (
  SELECT 1 FROM estimate_items ei WHERE ei.zafto_code = v.zafto_code AND ei.company_id IS NULL
);

-- ============================================================
-- 4. Add labor rates for new trades (estimate_labor_components)
-- ============================================================
INSERT INTO estimate_labor_components (code, trade, description, base_rate, markup, burden_pct, source)
SELECT v.code, v.trade, v.description, v.base_rate, v.markup, v.burden_pct, 'public'
FROM (VALUES
  ('SLR-BASE', 'solar', 'Solar installer', 26.00::decimal, 14.00::decimal, 0.3200::decimal),
  ('SLR-ELEC', 'solar', 'Solar electrician', 32.00, 16.00, 0.3200),
  ('FNC-BASE', 'fencing', 'Fence installer', 22.00, 12.00, 0.3200),
  ('PVG-BASE', 'paving', 'Paving crew', 24.00, 13.00, 0.3200),
  ('PVG-OPER', 'paving', 'Equipment operator', 28.00, 15.00, 0.3200),
  ('GRM-PM', 'general', 'Project manager', 35.00, 18.00, 0.3200),
  ('GRM-LEAD', 'general', 'Lead carpenter', 30.00, 16.00, 0.3200),
  ('FRS-BASE', 'fire_restoration', 'Fire restoration tech', 24.00, 13.00, 0.3200),
  ('FRS-CERT', 'fire_restoration', 'Certified fire restoration', 30.00, 16.00, 0.3200),
  ('MLB-BASE', 'mold', 'Mold remediation tech', 25.00, 14.00, 0.3200),
  ('MLB-CERT', 'mold', 'Certified mold specialist', 32.00, 17.00, 0.3200)
) AS v(code, trade, description, base_rate, markup, burden_pct)
WHERE NOT EXISTS (
  SELECT 1 FROM estimate_labor_components elc WHERE elc.code = v.code AND elc.company_id IS NULL
);

-- ============================================================
-- 5. Add additional completion checklists for missing trades
-- ============================================================
ALTER FUNCTION seed_trade_checklists(UUID) RENAME TO seed_trade_checklists_v1;

CREATE OR REPLACE FUNCTION seed_trade_checklists(p_company_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Call original if it exists
  PERFORM seed_trade_checklists_v1(p_company_id);

  -- Add new trade checklists if not already present
  IF NOT EXISTS (SELECT 1 FROM completion_checklists WHERE company_id = p_company_id AND trade_type = 'fencing') THEN
    INSERT INTO completion_checklists (company_id, trade_type, name, description, items, is_system) VALUES
    (p_company_id, 'fencing', 'Fencing Job Completion', 'Standard checklist for fence installation', '[
      {"key":"posts_plumb","label":"All posts plumb and set","required":true,"category":"installation"},
      {"key":"posts_depth","label":"Post depth meets code (min 24in)","required":true,"category":"code"},
      {"key":"panels_level","label":"Panels level and aligned","required":true,"category":"quality"},
      {"key":"gate_operates","label":"Gate(s) operate smoothly","required":true,"category":"verification"},
      {"key":"hardware_secure","label":"All hardware/latches secure","required":true,"category":"finish"},
      {"key":"concrete_set","label":"Post concrete fully set","required":true,"category":"materials"},
      {"key":"property_line","label":"Fence within property lines verified","required":true,"category":"legal"},
      {"key":"cleanup","label":"Site cleanup complete","required":true,"category":"cleanup"},
      {"key":"photos_taken","label":"Completion photos taken","required":true,"category":"documentation"}
    ]'::jsonb, true),

    (p_company_id, 'flooring', 'Flooring Job Completion', 'Standard checklist for flooring work', '[
      {"key":"subfloor_prepped","label":"Subfloor properly prepped","required":true,"category":"prep"},
      {"key":"acclimated","label":"Material acclimated (if required)","required":true,"category":"prep"},
      {"key":"pattern_correct","label":"Pattern/layout correct","required":true,"category":"quality"},
      {"key":"transitions_installed","label":"Transitions installed","required":true,"category":"finish"},
      {"key":"baseboards_installed","label":"Baseboards reinstalled/installed","required":true,"category":"finish"},
      {"key":"seams_tight","label":"All seams tight, no gaps","required":true,"category":"quality"},
      {"key":"cleanup","label":"Floor cleaned and inspected","required":true,"category":"cleanup"},
      {"key":"photos_taken","label":"Completion photos taken","required":true,"category":"documentation"}
    ]'::jsonb, true),

    (p_company_id, 'landscaping', 'Landscaping Job Completion', 'Standard checklist for landscaping work', '[
      {"key":"grade_correct","label":"Grading slopes away from structure","required":true,"category":"quality"},
      {"key":"drainage_verified","label":"Drainage flow verified","required":true,"category":"quality"},
      {"key":"plants_watered","label":"All plants watered in","required":true,"category":"finish"},
      {"key":"mulch_applied","label":"Mulch/ground cover applied","required":true,"category":"finish"},
      {"key":"irrigation_tested","label":"Irrigation system tested","required":false,"category":"testing"},
      {"key":"hardscape_level","label":"Hardscape surfaces level","required":true,"category":"quality"},
      {"key":"debris_removed","label":"All debris removed","required":true,"category":"cleanup"},
      {"key":"care_instructions","label":"Care instructions provided","required":true,"category":"closeout"},
      {"key":"photos_taken","label":"Before/after photos taken","required":true,"category":"documentation"}
    ]'::jsonb, true),

    (p_company_id, 'drywall', 'Drywall Job Completion', 'Standard checklist for drywall work', '[
      {"key":"seams_smooth","label":"All seams smooth (no ridges)","required":true,"category":"quality"},
      {"key":"corners_sharp","label":"Corners sharp and straight","required":true,"category":"quality"},
      {"key":"finish_level","label":"Finish level matches spec (L3/L4/L5)","required":true,"category":"quality"},
      {"key":"texture_uniform","label":"Texture uniform throughout","required":true,"category":"quality"},
      {"key":"nail_pops","label":"No nail pops visible","required":true,"category":"quality"},
      {"key":"sanded_smooth","label":"Sanded smooth, no dust residue","required":true,"category":"finish"},
      {"key":"primed","label":"Primed (if in scope)","required":false,"category":"finish"},
      {"key":"cleanup","label":"Dust cleanup complete","required":true,"category":"cleanup"},
      {"key":"photos_taken","label":"Completion photos taken","required":true,"category":"documentation"}
    ]'::jsonb, true),

    (p_company_id, 'insulation', 'Insulation Job Completion', 'Standard checklist for insulation work', '[
      {"key":"r_value_met","label":"R-value meets specification","required":true,"category":"code"},
      {"key":"coverage_complete","label":"Full coverage, no gaps","required":true,"category":"quality"},
      {"key":"vapor_barrier","label":"Vapor barrier installed correctly","required":true,"category":"code"},
      {"key":"electrical_clearance","label":"Clearance around electrical/heat sources","required":true,"category":"safety"},
      {"key":"fire_stops","label":"Fire stops in place","required":true,"category":"code"},
      {"key":"attic_baffles","label":"Attic baffles installed (if applicable)","required":false,"category":"ventilation"},
      {"key":"inspection_passed","label":"Inspection passed","required":true,"category":"permit"},
      {"key":"photos_taken","label":"Completion photos taken","required":true,"category":"documentation"}
    ]'::jsonb, true),

    (p_company_id, 'siding', 'Siding Job Completion', 'Standard checklist for siding work', '[
      {"key":"housewrap_complete","label":"House wrap properly installed","required":true,"category":"waterproofing"},
      {"key":"flashing_installed","label":"All flashing installed","required":true,"category":"waterproofing"},
      {"key":"joints_sealed","label":"All joints/transitions sealed","required":true,"category":"waterproofing"},
      {"key":"penetrations_sealed","label":"Penetrations caulked/sealed","required":true,"category":"waterproofing"},
      {"key":"trim_complete","label":"All trim pieces installed","required":true,"category":"finish"},
      {"key":"color_consistent","label":"Color/pattern consistent","required":true,"category":"quality"},
      {"key":"cleanup","label":"Site cleanup complete","required":true,"category":"cleanup"},
      {"key":"photos_taken","label":"Completion photos taken","required":true,"category":"documentation"}
    ]'::jsonb, true);
  END IF;
END;
$$;
