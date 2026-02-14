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
INSERT INTO estimate_categories (code, name, description, labor_percent, material_percent, equipment_percent) VALUES
  ('SLR', 'Solar', 'Solar panel installation, inverters, battery systems', 40, 50, 10),
  ('FNC', 'Fencing', 'Fence installation — wood, vinyl, chain-link, iron', 55, 40, 5),
  ('PVG', 'Paving', 'Asphalt, pavers, brick paving', 40, 45, 15),
  ('GRM', 'General Remodel', 'Full home remodel, multi-trade projects', 55, 35, 10),
  ('WND', 'Windows & Doors', 'Window and door replacement/installation', 40, 55, 5),
  ('SPF', 'Spray Foam', 'Spray foam insulation (open/closed cell)', 45, 45, 10),
  ('FRS', 'Fire/Smoke Restoration', 'Fire and smoke damage restoration', 50, 30, 20),
  ('MLB', 'Mold Remediation', 'Mold assessment and remediation', 55, 20, 25),
  ('TRM', 'Trim & Millwork', 'Interior trim, crown molding, baseboards', 60, 35, 5)
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- 3. Add line items for new categories
-- ============================================================
INSERT INTO estimate_items (zafto_code, category_code, description, unit_code, default_unit_price, material_cost_default, labor_cost_default, equipment_cost_default) VALUES
  -- Solar (SLR)
  ('Z-SLR-001', 'SLR', 'Solar Panel — 400W Monocrystalline', 'EA', 350.00, 250.00, 80.00, 20.00),
  ('Z-SLR-002', 'SLR', 'Roof Racking System — Rail Mount', 'LF', 18.00, 12.00, 5.00, 1.00),
  ('Z-SLR-003', 'SLR', 'String Inverter — 7.6kW', 'EA', 2200.00, 1800.00, 350.00, 50.00),
  ('Z-SLR-004', 'SLR', 'Microinverter — Per Panel', 'EA', 280.00, 200.00, 60.00, 20.00),
  ('Z-SLR-005', 'SLR', 'Battery Storage — 10kWh', 'EA', 8500.00, 7000.00, 1200.00, 300.00),
  ('Z-SLR-006', 'SLR', 'AC/DC Disconnect Switch', 'EA', 185.00, 120.00, 55.00, 10.00),
  ('Z-SLR-007', 'SLR', 'Conduit Run — EMT', 'LF', 8.50, 3.50, 4.00, 1.00),
  ('Z-SLR-008', 'SLR', 'Meter/Net Metering Setup', 'EA', 450.00, 150.00, 250.00, 50.00),
  ('Z-SLR-009', 'SLR', 'Roof Penetration Flashing', 'EA', 35.00, 15.00, 15.00, 5.00),
  ('Z-SLR-010', 'SLR', 'Monitoring System Setup', 'EA', 200.00, 100.00, 80.00, 20.00),

  -- Fencing (FNC)
  ('Z-FNC-001', 'FNC', 'Wood Privacy Fence — 6ft Cedar', 'LF', 38.00, 22.00, 14.00, 2.00),
  ('Z-FNC-002', 'FNC', 'Wood Picket Fence — 4ft', 'LF', 28.00, 16.00, 10.00, 2.00),
  ('Z-FNC-003', 'FNC', 'Vinyl Privacy Fence — 6ft', 'LF', 42.00, 28.00, 12.00, 2.00),
  ('Z-FNC-004', 'FNC', 'Chain Link Fence — 4ft', 'LF', 18.00, 10.00, 6.00, 2.00),
  ('Z-FNC-005', 'FNC', 'Chain Link Fence — 6ft', 'LF', 24.00, 14.00, 8.00, 2.00),
  ('Z-FNC-006', 'FNC', 'Wrought Iron Fence — 4ft', 'LF', 55.00, 35.00, 15.00, 5.00),
  ('Z-FNC-007', 'FNC', 'Aluminum Fence Panel — 4ft', 'LF', 45.00, 30.00, 12.00, 3.00),
  ('Z-FNC-008', 'FNC', 'Fence Post — Wood 4x4', 'EA', 25.00, 12.00, 10.00, 3.00),
  ('Z-FNC-009', 'FNC', 'Fence Post — Steel', 'EA', 35.00, 20.00, 12.00, 3.00),
  ('Z-FNC-010', 'FNC', 'Gate — Standard Walk', 'EA', 175.00, 100.00, 60.00, 15.00),
  ('Z-FNC-011', 'FNC', 'Gate — Double Drive', 'EA', 450.00, 280.00, 140.00, 30.00),
  ('Z-FNC-012', 'FNC', 'Fence Removal — Existing', 'LF', 5.00, 0.00, 4.00, 1.00),

  -- Paving (PVG)
  ('Z-PVG-001', 'PVG', 'Asphalt Paving — Driveway', 'SF', 5.50, 2.50, 1.50, 1.50),
  ('Z-PVG-002', 'PVG', 'Asphalt Seal Coat', 'SF', 0.85, 0.35, 0.30, 0.20),
  ('Z-PVG-003', 'PVG', 'Concrete Pavers — Standard', 'SF', 14.00, 8.00, 4.50, 1.50),
  ('Z-PVG-004', 'PVG', 'Brick Pavers — Herringbone', 'SF', 18.00, 10.00, 6.00, 2.00),
  ('Z-PVG-005', 'PVG', 'Paver Base Prep — Gravel + Sand', 'SF', 3.50, 1.50, 1.00, 1.00),
  ('Z-PVG-006', 'PVG', 'Edging — Paver Restraint', 'LF', 4.00, 2.00, 1.50, 0.50),
  ('Z-PVG-007', 'PVG', 'Polymeric Sand — Joint Fill', 'SF', 1.20, 0.70, 0.30, 0.20),
  ('Z-PVG-008', 'PVG', 'Asphalt Patch/Repair', 'SF', 8.00, 3.00, 3.00, 2.00),

  -- General Remodel (GRM)
  ('Z-GRM-001', 'GRM', 'Project Management — Per Week', 'EA', 1500.00, 0.00, 1500.00, 0.00),
  ('Z-GRM-002', 'GRM', 'Permit Filing + Fee', 'EA', 500.00, 350.00, 150.00, 0.00),
  ('Z-GRM-003', 'GRM', 'Temporary Protection — Floors', 'SF', 0.75, 0.50, 0.20, 0.05),
  ('Z-GRM-004', 'GRM', 'Temporary Protection — Walls', 'SF', 0.50, 0.30, 0.15, 0.05),
  ('Z-GRM-005', 'GRM', 'Dust Barrier / Containment', 'EA', 350.00, 150.00, 180.00, 20.00),
  ('Z-GRM-006', 'GRM', 'Dumpster Rental — 20yd', 'DA', 450.00, 400.00, 50.00, 0.00),
  ('Z-GRM-007', 'GRM', 'Dumpster Rental — 30yd', 'DA', 550.00, 500.00, 50.00, 0.00),
  ('Z-GRM-008', 'GRM', 'Final Clean — Post-Construction', 'SF', 0.50, 0.10, 0.35, 0.05),

  -- Windows & Doors (WND)
  ('Z-WND-001', 'WND', 'Vinyl Window — Double Hung Standard', 'EA', 450.00, 300.00, 130.00, 20.00),
  ('Z-WND-002', 'WND', 'Vinyl Window — Sliding', 'EA', 400.00, 260.00, 120.00, 20.00),
  ('Z-WND-003', 'WND', 'Vinyl Window — Picture/Fixed', 'EA', 350.00, 230.00, 100.00, 20.00),
  ('Z-WND-004', 'WND', 'Egress Window — Basement', 'EA', 2800.00, 1800.00, 800.00, 200.00),
  ('Z-WND-005', 'WND', 'Entry Door — Fiberglass', 'EA', 1200.00, 800.00, 350.00, 50.00),
  ('Z-WND-006', 'WND', 'Entry Door — Steel', 'EA', 900.00, 600.00, 250.00, 50.00),
  ('Z-WND-007', 'WND', 'Sliding Patio Door', 'EA', 1500.00, 1000.00, 400.00, 100.00),
  ('Z-WND-008', 'WND', 'French Door Set', 'EA', 2200.00, 1500.00, 600.00, 100.00),
  ('Z-WND-009', 'WND', 'Storm Door', 'EA', 450.00, 300.00, 130.00, 20.00),
  ('Z-WND-010', 'WND', 'Window Trim — Interior', 'LF', 6.00, 3.00, 2.50, 0.50),

  -- Fire/Smoke Restoration (FRS)
  ('Z-FRS-001', 'FRS', 'Smoke/Soot Cleaning — Walls', 'SF', 3.50, 0.50, 2.50, 0.50),
  ('Z-FRS-002', 'FRS', 'Smoke/Soot Cleaning — Ceiling', 'SF', 4.00, 0.50, 3.00, 0.50),
  ('Z-FRS-003', 'FRS', 'Thermal Fogging — Odor', 'SF', 1.50, 0.50, 0.50, 0.50),
  ('Z-FRS-004', 'FRS', 'Ozone Treatment — Room', 'EA', 350.00, 50.00, 100.00, 200.00),
  ('Z-FRS-005', 'FRS', 'Contents Pack-Out', 'EA', 2500.00, 200.00, 2000.00, 300.00),
  ('Z-FRS-006', 'FRS', 'Structural Char Removal', 'SF', 5.00, 0.50, 3.50, 1.00),
  ('Z-FRS-007', 'FRS', 'Air Scrubber — HEPA', 'DA', 75.00, 0.00, 15.00, 60.00),
  ('Z-FRS-008', 'FRS', 'Board-Up Service', 'EA', 500.00, 200.00, 250.00, 50.00),

  -- Mold Remediation (MLB)
  ('Z-MLB-001', 'MLB', 'Mold Assessment — Visual + Moisture', 'EA', 450.00, 50.00, 350.00, 50.00),
  ('Z-MLB-002', 'MLB', 'Air Quality Testing', 'EA', 350.00, 100.00, 200.00, 50.00),
  ('Z-MLB-003', 'MLB', 'Containment Setup — Full', 'EA', 800.00, 300.00, 400.00, 100.00),
  ('Z-MLB-004', 'MLB', 'Mold Removal — Surface', 'SF', 8.00, 1.00, 5.50, 1.50),
  ('Z-MLB-005', 'MLB', 'Mold Removal — Behind Walls', 'SF', 18.00, 2.00, 12.00, 4.00),
  ('Z-MLB-006', 'MLB', 'HEPA Vacuuming', 'SF', 2.00, 0.20, 1.00, 0.80),
  ('Z-MLB-007', 'MLB', 'Antimicrobial Treatment', 'SF', 2.50, 0.80, 1.20, 0.50),
  ('Z-MLB-008', 'MLB', 'Post-Remediation Verification', 'EA', 400.00, 100.00, 250.00, 50.00),

  -- Landscaping expanded items (LND already exists)
  ('Z-LND-010', 'LND', 'Sod Installation', 'SF', 2.50, 1.50, 0.80, 0.20),
  ('Z-LND-011', 'LND', 'Mulch — Bed Coverage', 'CY', 85.00, 45.00, 30.00, 10.00),
  ('Z-LND-012', 'LND', 'Retaining Wall — Block', 'SF', 35.00, 18.00, 12.00, 5.00),
  ('Z-LND-013', 'LND', 'French Drain', 'LF', 25.00, 10.00, 10.00, 5.00),
  ('Z-LND-014', 'LND', 'Irrigation System — Per Zone', 'EA', 650.00, 350.00, 250.00, 50.00),
  ('Z-LND-015', 'LND', 'Tree Removal — Small (<12in)', 'EA', 350.00, 0.00, 250.00, 100.00),
  ('Z-LND-016', 'LND', 'Tree Removal — Large (>24in)', 'EA', 1500.00, 0.00, 900.00, 600.00),
  ('Z-LND-017', 'LND', 'Grading — Rough', 'SF', 1.50, 0.00, 0.50, 1.00),

  -- Gutters expanded items (GUT already exists)
  ('Z-GUT-005', 'GUT', 'Seamless Aluminum Gutter — 5in', 'LF', 12.00, 6.00, 5.00, 1.00),
  ('Z-GUT-006', 'GUT', 'Seamless Aluminum Gutter — 6in', 'LF', 15.00, 8.00, 6.00, 1.00),
  ('Z-GUT-007', 'GUT', 'Copper Gutter — Half Round', 'LF', 40.00, 28.00, 10.00, 2.00),
  ('Z-GUT-008', 'GUT', 'Gutter Guard — Mesh', 'LF', 10.00, 6.00, 3.50, 0.50),
  ('Z-GUT-009', 'GUT', 'Downspout Extension', 'EA', 25.00, 12.00, 10.00, 3.00),
  ('Z-GUT-010', 'GUT', 'Gutter Cleaning', 'LF', 2.50, 0.00, 2.00, 0.50)
ON CONFLICT (zafto_code) DO NOTHING;

-- ============================================================
-- 4. Add labor rates for new trades
-- ============================================================
INSERT INTO estimate_labor_rates (code, trade, description, base_rate, markup_rate, burden_percent) VALUES
  ('SLR-BASE', 'solar', 'Solar installer', 26.00, 14.00, 32.0),
  ('SLR-ELEC', 'solar', 'Solar electrician', 32.00, 16.00, 32.0),
  ('FNC-BASE', 'fencing', 'Fence installer', 22.00, 12.00, 32.0),
  ('PVG-BASE', 'paving', 'Paving crew', 24.00, 13.00, 32.0),
  ('PVG-OPER', 'paving', 'Equipment operator', 28.00, 15.00, 32.0),
  ('GRM-PM', 'general', 'Project manager', 35.00, 18.00, 32.0),
  ('GRM-LEAD', 'general', 'Lead carpenter', 30.00, 16.00, 32.0),
  ('FRS-BASE', 'fire_restoration', 'Fire restoration tech', 24.00, 13.00, 32.0),
  ('FRS-CERT', 'fire_restoration', 'Certified fire restoration', 30.00, 16.00, 32.0),
  ('MLB-BASE', 'mold', 'Mold remediation tech', 25.00, 14.00, 32.0),
  ('MLB-CERT', 'mold', 'Certified mold specialist', 32.00, 17.00, 32.0)
ON CONFLICT (code) DO NOTHING;

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
