-- ============================================================
-- D8b: Seed Data — Initial Code Database
-- Migration 000030
-- Seeds: estimate_units, estimate_categories, estimate_items,
--        estimate_labor_components
-- All data from publicly available sources
-- ============================================================


-- ============================================================
-- 1. UNITS OF MEASURE
-- ============================================================
INSERT INTO estimate_units (code, name, abbreviation) VALUES
('SF', 'Square Foot', 'sq ft'),
('LF', 'Linear Foot', 'lin ft'),
('EA', 'Each', 'ea'),
('SQ', 'Square (100 SF)', 'sq'),
('HR', 'Hour', 'hr'),
('BF', 'Board Foot', 'bd ft'),
('CY', 'Cubic Yard', 'cu yd'),
('GA', 'Gallon', 'gal'),
('LB', 'Pound', 'lb'),
('RL', 'Roll', 'roll'),
('CT', 'Cartridge/Tube', 'cart'),
('MO', 'Month', 'mo'),
('DA', 'Day', 'day'),
('SY', 'Square Yard', 'sq yd'),
('CF', 'Cubic Foot', 'cu ft'),
('LS', 'Lump Sum', 'ls')
ON CONFLICT (code) DO NOTHING;


-- ============================================================
-- 2. ESTIMATE CATEGORIES (90+ industry categories)
-- Code format: 3-letter ZAFTO code
-- industry_code maps to standard Xactimate category codes
-- labor/material/equipment percentages are typical trade splits
-- ============================================================
INSERT INTO estimate_categories (code, industry_code, name, labor_pct, material_pct, equipment_pct, sort_order) VALUES
-- Demolition & Cleanup
('DMO', 'DMO', 'Demolition', 80, 5, 15, 10),
('CLN', 'CLN', 'Cleaning', 70, 20, 10, 20),
('WTR', 'WTR', 'Water Extraction/Remediation', 40, 10, 50, 30),
('HAZ', NULL, 'Hazardous Material Abatement', 60, 15, 25, 35),
-- Structural
('FRM', 'FRM', 'Framing', 60, 35, 5, 100),
('CNC', 'CNC', 'Concrete', 45, 40, 15, 110),
('MAS', 'MAS', 'Masonry', 50, 45, 5, 120),
('STL', 'STL', 'Steel/Metal Framing', 50, 40, 10, 130),
('STR', 'STR', 'Structural Repair', 55, 35, 10, 135),
-- Roofing & Exterior
('RFG', 'RFG', 'Roofing', 45, 50, 5, 200),
('SDG', 'SDG', 'Siding', 50, 45, 5, 210),
('GUT', NULL, 'Gutters/Downspouts', 55, 40, 5, 220),
('FEN', 'FEN', 'Fencing', 50, 45, 5, 230),
('DEC', NULL, 'Decking', 50, 45, 5, 240),
('LND', 'LND', 'Landscaping', 60, 30, 10, 250),
('EXC', 'EXC', 'Excavation', 30, 5, 65, 260),
-- Doors & Windows
('DOR', 'DOR', 'Doors', 40, 55, 5, 300),
('WDW', 'WDW', 'Windows', 35, 60, 5, 310),
('GLS', 'GLS', 'Glass/Mirrors', 40, 55, 5, 320),
('AWN', 'AWN', 'Awnings', 45, 50, 5, 325),
-- Drywall & Interior Surfaces
('DRY', 'DRY', 'Drywall', 55, 40, 5, 400),
('PLA', 'PLA', 'Plaster', 55, 35, 10, 410),
('STU', 'STU', 'Stucco', 50, 40, 10, 420),
('PNL', 'PNL', 'Paneling', 45, 50, 5, 430),
('ACT', 'ACT', 'Acoustical Tile/Ceiling', 40, 55, 5, 440),
-- Painting & Finishing
('PNT', 'PNT', 'Painting', 70, 25, 5, 500),
('WPR', 'WPR', 'Wallpaper', 55, 40, 5, 510),
('PTG', 'PTG', 'Protective Coatings', 55, 35, 10, 520),
('POL', 'POL', 'Polish/Refinishing', 60, 30, 10, 530),
-- Flooring
('FCV', 'FCV', 'Floor Covering - Vinyl/Resilient', 40, 55, 5, 600),
('FCT', 'FCT', 'Floor Covering - Tile', 45, 50, 5, 610),
('FCW', 'FCW', 'Floor Covering - Wood', 40, 55, 5, 620),
('FCC', 'FCC', 'Floor Covering - Carpet', 35, 60, 5, 630),
('FCR', 'FCR', 'Floor Covering - Stone', 45, 50, 5, 640),
('FCS', 'FCS', 'Floor Covering - Special', 45, 50, 5, 645),
-- Tile
('TIL', 'TIL', 'Tile', 50, 45, 5, 650),
-- Cabinets & Countertops
('CAB', 'CAB', 'Cabinets', 35, 60, 5, 700),
('CNT', NULL, 'Countertops', 35, 60, 5, 710),
-- Plumbing
('PLM', 'PLM', 'Plumbing', 55, 40, 5, 800),
-- Electrical
('ELE', 'ELE', 'Electrical', 60, 35, 5, 900),
('ELS', 'ELS', 'Electrical - Low Voltage/Smart', 55, 40, 5, 910),
('LIT', 'LIT', 'Lighting', 40, 55, 5, 920),
-- HVAC
('HVC', 'HVC', 'HVAC', 45, 40, 15, 1000),
-- Insulation
('INS', 'INS', 'Insulation', 40, 55, 5, 1100),
-- Appliances & Equipment
('APP', 'APP', 'Appliances', 15, 80, 5, 1200),
('EQA', 'EQA', 'Equipment - Appliance', 20, 75, 5, 1210),
('EQC', 'EQC', 'Equipment - Commercial', 25, 65, 10, 1220),
-- Contents & Moving
('CON', 'CON', 'Contents', 70, 20, 10, 1300),
('MBL', 'MBL', 'Movable/Contents - General', 65, 25, 10, 1310),
-- Fireplace
('FPL', 'FPL', 'Fireplace', 45, 50, 5, 1400),
('FPS', 'FPS', 'Fireplace - Stone', 45, 50, 5, 1410),
-- Trim & Millwork
('TMB', 'TMB', 'Trim/Baseboard', 45, 50, 5, 1500),
('MSD', 'MSD', 'Moldings - Special/Decorative', 40, 55, 5, 1510),
('SCF', 'SCF', 'Soffit/Fascia', 50, 45, 5, 1520),
('STJ', 'STJ', 'Staircase/Stair Components', 45, 50, 5, 1530),
-- Scaffolding & Temporary
('SFG', 'SFG', 'Scaffolding', 30, 10, 60, 1600),
('TMP', 'TMP', 'Temporary/Protective Measures', 50, 35, 15, 1610),
('SPR', 'SPR', 'Sprinkler System', 50, 45, 5, 1620),
-- Specialty
('ARC', 'ARC', 'Architectural Detailing', 50, 45, 5, 1700),
('FRP', 'FRP', 'Fiberglass', 45, 50, 5, 1710),
('ORI', 'ORI', 'Ornamental Iron', 50, 45, 5, 1720),
('VTC', 'VTC', 'Vinyl/Thermal Ceilings', 40, 55, 5, 1730),
('WDA', 'WDA', 'Window - Awning', 35, 60, 5, 1740),
('WDP', 'WDP', 'Window - Picture', 35, 60, 5, 1750),
('WDR', 'WDR', 'Window - Double/Single Hung', 35, 60, 5, 1760),
('WDS', 'WDS', 'Window - Sliding', 35, 60, 5, 1770),
('WDT', 'WDT', 'Window - Trim/Casing', 45, 50, 5, 1780),
('WDV', 'WDV', 'Window - Vinyl', 30, 65, 5, 1790),
-- Metal Panels & Roofing
('MTL', 'MTL', 'Metal Roofing/Panels', 45, 50, 5, 1800),
-- Permits & Fees
('FEE', 'FEE', 'Fees/Permits', 0, 0, 0, 1900),
('PRM', 'PRM', 'Permits', 0, 100, 0, 1910),
-- Labor Only
('LAB', 'LAB', 'General Labor', 100, 0, 0, 2000),
('SPE', 'SPE', 'Special/Custom', 50, 40, 10, 2010),
-- Insurance Specific
('INM', 'INM', 'Insurance - Misc', 50, 40, 10, 2100),
('OBS', 'OBS', 'Overhead & Storage', 40, 40, 20, 2110),
('MPR', 'MPR', 'Moisture Protection', 50, 40, 10, 2120),
-- Miscellaneous
('TCR', 'TCR', 'Temporary Climate/Repair', 40, 30, 30, 2200),
('TBA', 'TBA', 'To Be Assessed', 50, 40, 10, 2210),
('USR', 'USR', 'User Defined', 50, 40, 10, 2220),
('XST', 'XST', 'Existing Structure', 50, 40, 10, 2230),
('HMR', 'HMR', 'Home/Building Repair - General', 50, 40, 10, 2240),
-- Equipment Rental
('EQU', 'EQU', 'Equipment Rental', 10, 5, 85, 2300),
('FNC', 'FNC', 'Finish Carpentry', 55, 40, 5, 2400),
('FNH', 'FNH', 'Finish Hardware', 30, 65, 5, 2410),
('CSF', 'CSF', 'Ceiling - Special/Flat', 50, 45, 5, 2420),
('MSK', 'MSK', 'Masking/Protection', 60, 35, 5, 2430)
ON CONFLICT (code) DO NOTHING;


-- ============================================================
-- 3. ESTIMATE ITEMS (~200 common items across 11 priority trades)
-- ZAFTO codes: Z-{TRADE}-{SEQ} format
-- Maps to industry codes where known
-- source='zafto' = system-seeded, readable by all companies
-- ============================================================

-- Helper: get category IDs dynamically
DO $$
DECLARE
    cat_rfg UUID; cat_dry UUID; cat_plm UUID; cat_ele UUID;
    cat_pnt UUID; cat_dmo UUID; cat_wtr UUID; cat_frm UUID;
    cat_ins UUID; cat_sdg UUID; cat_hvc UUID; cat_fcv UUID;
    cat_fct UUID; cat_fcw UUID; cat_fcc UUID; cat_til UUID;
    cat_cab UUID; cat_dor UUID; cat_wdw UUID; cat_cln UUID;
    cat_cnt UUID; cat_cnc UUID; cat_mas UUID; cat_gls UUID;
    cat_app UUID; cat_con UUID; cat_lab UUID; cat_fee UUID;
    cat_tmb UUID; cat_gut UUID; cat_dec UUID; cat_fpl UUID;
    cat_spr UUID;
BEGIN
    SELECT id INTO cat_rfg FROM estimate_categories WHERE code = 'RFG';
    SELECT id INTO cat_dry FROM estimate_categories WHERE code = 'DRY';
    SELECT id INTO cat_plm FROM estimate_categories WHERE code = 'PLM';
    SELECT id INTO cat_ele FROM estimate_categories WHERE code = 'ELE';
    SELECT id INTO cat_pnt FROM estimate_categories WHERE code = 'PNT';
    SELECT id INTO cat_dmo FROM estimate_categories WHERE code = 'DMO';
    SELECT id INTO cat_wtr FROM estimate_categories WHERE code = 'WTR';
    SELECT id INTO cat_frm FROM estimate_categories WHERE code = 'FRM';
    SELECT id INTO cat_ins FROM estimate_categories WHERE code = 'INS';
    SELECT id INTO cat_sdg FROM estimate_categories WHERE code = 'SDG';
    SELECT id INTO cat_hvc FROM estimate_categories WHERE code = 'HVC';
    SELECT id INTO cat_fcv FROM estimate_categories WHERE code = 'FCV';
    SELECT id INTO cat_fct FROM estimate_categories WHERE code = 'FCT';
    SELECT id INTO cat_fcw FROM estimate_categories WHERE code = 'FCW';
    SELECT id INTO cat_fcc FROM estimate_categories WHERE code = 'FCC';
    SELECT id INTO cat_til FROM estimate_categories WHERE code = 'TIL';
    SELECT id INTO cat_cab FROM estimate_categories WHERE code = 'CAB';
    SELECT id INTO cat_dor FROM estimate_categories WHERE code = 'DOR';
    SELECT id INTO cat_wdw FROM estimate_categories WHERE code = 'WDW';
    SELECT id INTO cat_cln FROM estimate_categories WHERE code = 'CLN';
    SELECT id INTO cat_cnt FROM estimate_categories WHERE code = 'CNT';
    SELECT id INTO cat_cnc FROM estimate_categories WHERE code = 'CNC';
    SELECT id INTO cat_mas FROM estimate_categories WHERE code = 'MAS';
    SELECT id INTO cat_gls FROM estimate_categories WHERE code = 'GLS';
    SELECT id INTO cat_app FROM estimate_categories WHERE code = 'APP';
    SELECT id INTO cat_con FROM estimate_categories WHERE code = 'CON';
    SELECT id INTO cat_lab FROM estimate_categories WHERE code = 'LAB';
    SELECT id INTO cat_fee FROM estimate_categories WHERE code = 'FEE';
    SELECT id INTO cat_tmb FROM estimate_categories WHERE code = 'TMB';
    SELECT id INTO cat_gut FROM estimate_categories WHERE code = 'GUT';
    SELECT id INTO cat_dec FROM estimate_categories WHERE code = 'DEC';
    SELECT id INTO cat_fpl FROM estimate_categories WHERE code = 'FPL';
    SELECT id INTO cat_spr FROM estimate_categories WHERE code = 'SPR';

    -- ========================================
    -- ROOFING (RFG) — 18 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_rfg, 'Z-RFG-001', 'RFG', 'SHGL', 'Asphalt shingles - 3 tab', 'SQ', '{add,replace}', 'RFG', true, 'zafto', '{roofing,shingles,asphalt}'),
    (cat_rfg, 'Z-RFG-002', 'RFG', 'SHGL', 'Asphalt shingles - architectural/dimensional', 'SQ', '{add,replace}', 'RFG', true, 'zafto', '{roofing,shingles,architectural}'),
    (cat_rfg, 'Z-RFG-003', 'RFG', 'FELT', 'Roofing felt/underlayment - 15 lb', 'SQ', '{add,replace}', 'RFG', true, 'zafto', '{roofing,underlayment,felt}'),
    (cat_rfg, 'Z-RFG-004', 'RFG', 'FELT', 'Synthetic underlayment', 'SQ', '{add,replace}', 'RFG', true, 'zafto', '{roofing,underlayment,synthetic}'),
    (cat_rfg, 'Z-RFG-005', 'RFG', 'FLASH', 'Step flashing', 'LF', '{add,replace}', 'RFG', true, 'zafto', '{roofing,flashing,step}'),
    (cat_rfg, 'Z-RFG-006', 'RFG', 'FLASH', 'Valley flashing', 'LF', '{add,replace}', 'RFG', true, 'zafto', '{roofing,flashing,valley}'),
    (cat_rfg, 'Z-RFG-007', 'RFG', 'RIDGE', 'Ridge cap shingles', 'LF', '{add,replace}', 'RFG', true, 'zafto', '{roofing,ridge,cap}'),
    (cat_rfg, 'Z-RFG-008', 'RFG', 'DRIP', 'Drip edge - aluminum', 'LF', '{add,replace}', 'RFG', true, 'zafto', '{roofing,drip,edge}'),
    (cat_rfg, 'Z-RFG-009', 'RFG', NULL, 'Ice & water shield', 'SQ', '{add}', 'RFG', true, 'zafto', '{roofing,ice,water,shield}'),
    (cat_rfg, 'Z-RFG-010', 'RFG', NULL, 'Roof vent - box/static', 'EA', '{add,replace}', 'RFG', true, 'zafto', '{roofing,vent,box}'),
    (cat_rfg, 'Z-RFG-011', 'RFG', NULL, 'Ridge vent - continuous', 'LF', '{add,replace}', 'RFG', true, 'zafto', '{roofing,vent,ridge}'),
    (cat_rfg, 'Z-RFG-012', 'RFG', NULL, 'Pipe boot/flashing', 'EA', '{add,replace}', 'RFG', true, 'zafto', '{roofing,pipe,boot}'),
    (cat_rfg, 'Z-RFG-013', 'RFG', NULL, 'Starter strip', 'LF', '{add}', 'RFG', true, 'zafto', '{roofing,starter}'),
    (cat_rfg, 'Z-RFG-014', NULL, NULL, 'Metal roofing panel - standing seam', 'SQ', '{add,replace}', 'RFG', false, 'zafto', '{roofing,metal,standing,seam}'),
    (cat_rfg, 'Z-RFG-015', NULL, NULL, 'Roof tear-off - 1 layer', 'SQ', '{remove}', 'RFG', true, 'zafto', '{roofing,tearoff,demo}'),
    (cat_rfg, 'Z-RFG-016', NULL, NULL, 'Roof tear-off - 2 layers', 'SQ', '{remove}', 'RFG', false, 'zafto', '{roofing,tearoff,demo}'),
    (cat_rfg, 'Z-RFG-017', NULL, NULL, 'Skylight installation', 'EA', '{add,replace}', 'RFG', false, 'zafto', '{roofing,skylight}'),
    (cat_rfg, 'Z-RFG-018', NULL, NULL, 'Chimney flashing', 'EA', '{add,replace}', 'RFG', false, 'zafto', '{roofing,chimney,flashing}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- DRYWALL (DRY) — 14 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_dry, 'Z-DRY-001', 'DRY', 'HANG12', 'Drywall - 1/2" standard', 'SF', '{add,replace}', 'DRY', true, 'zafto', '{drywall,hang,half}'),
    (cat_dry, 'Z-DRY-002', 'DRY', 'HANG58', 'Drywall - 5/8" fire-rated', 'SF', '{add,replace}', 'DRY', true, 'zafto', '{drywall,hang,fire,rated}'),
    (cat_dry, 'Z-DRY-003', 'DRY', NULL, 'Drywall - moisture resistant (green board)', 'SF', '{add,replace}', 'DRY', true, 'zafto', '{drywall,moisture,greenboard}'),
    (cat_dry, 'Z-DRY-004', 'DRY', 'TAPE', 'Tape, float & finish - level 4', 'SF', '{add}', 'DRY', true, 'zafto', '{drywall,tape,float,finish}'),
    (cat_dry, 'Z-DRY-005', 'DRY', NULL, 'Tape, float & finish - level 5', 'SF', '{add}', 'DRY', false, 'zafto', '{drywall,tape,float,smooth}'),
    (cat_dry, 'Z-DRY-006', 'DRY', 'TEXTURE', 'Texture - knockdown', 'SF', '{add}', 'DRY', true, 'zafto', '{drywall,texture,knockdown}'),
    (cat_dry, 'Z-DRY-007', 'DRY', 'TEXTURE', 'Texture - orange peel', 'SF', '{add}', 'DRY', true, 'zafto', '{drywall,texture,orange,peel}'),
    (cat_dry, 'Z-DRY-008', 'DRY', 'TEXTURE', 'Texture - popcorn ceiling', 'SF', '{add}', 'DRY', false, 'zafto', '{drywall,texture,popcorn,ceiling}'),
    (cat_dry, 'Z-DRY-009', 'DRY', NULL, 'Drywall patch - small (up to 4")', 'EA', '{repair}', 'DRY', true, 'zafto', '{drywall,patch,repair,small}'),
    (cat_dry, 'Z-DRY-010', 'DRY', NULL, 'Drywall patch - medium (4"-12")', 'EA', '{repair}', 'DRY', true, 'zafto', '{drywall,patch,repair,medium}'),
    (cat_dry, 'Z-DRY-011', 'DRY', NULL, 'Drywall patch - large (12"+)', 'EA', '{repair}', 'DRY', false, 'zafto', '{drywall,patch,repair,large}'),
    (cat_dry, 'Z-DRY-012', NULL, NULL, 'Popcorn ceiling removal', 'SF', '{remove}', 'DRY', true, 'zafto', '{drywall,popcorn,removal,demo}'),
    (cat_dry, 'Z-DRY-013', NULL, NULL, 'Corner bead installation', 'LF', '{add,replace}', 'DRY', true, 'zafto', '{drywall,corner,bead}'),
    (cat_dry, 'Z-DRY-014', NULL, NULL, 'Ceiling drywall - 1/2"', 'SF', '{add,replace}', 'DRY', true, 'zafto', '{drywall,ceiling}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- PLUMBING (PLM) — 16 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_plm, 'Z-PLM-001', 'PLM', 'TOILET', 'Toilet - standard', 'EA', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,toilet,standard}'),
    (cat_plm, 'Z-PLM-002', 'PLM', 'SINK', 'Bathroom sink - vanity mount', 'EA', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,sink,bathroom,vanity}'),
    (cat_plm, 'Z-PLM-003', 'PLM', 'SINK', 'Kitchen sink - stainless steel', 'EA', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,sink,kitchen}'),
    (cat_plm, 'Z-PLM-004', 'PLM', 'FAUCET', 'Faucet - kitchen', 'EA', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,faucet,kitchen}'),
    (cat_plm, 'Z-PLM-005', 'PLM', 'FAUCET', 'Faucet - bathroom', 'EA', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,faucet,bathroom}'),
    (cat_plm, 'Z-PLM-006', 'PLM', 'WATERHEATER', 'Water heater - 40 gal gas', 'EA', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,water,heater,gas}'),
    (cat_plm, 'Z-PLM-007', 'PLM', 'WATERHEATER', 'Water heater - 50 gal electric', 'EA', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,water,heater,electric}'),
    (cat_plm, 'Z-PLM-008', 'PLM', NULL, 'Tankless water heater', 'EA', '{add,replace}', 'PLM', false, 'zafto', '{plumbing,water,heater,tankless}'),
    (cat_plm, 'Z-PLM-009', 'PLM', NULL, 'Bathtub - standard acrylic', 'EA', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,bathtub,acrylic}'),
    (cat_plm, 'Z-PLM-010', 'PLM', NULL, 'Shower valve & trim', 'EA', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,shower,valve}'),
    (cat_plm, 'Z-PLM-011', 'PLM', NULL, 'Garbage disposal', 'EA', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,disposal}'),
    (cat_plm, 'Z-PLM-012', 'PLM', NULL, 'Supply line - copper', 'LF', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,supply,copper}'),
    (cat_plm, 'Z-PLM-013', 'PLM', NULL, 'Supply line - PEX', 'LF', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,supply,pex}'),
    (cat_plm, 'Z-PLM-014', 'PLM', NULL, 'Drain line - PVC', 'LF', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,drain,pvc}'),
    (cat_plm, 'Z-PLM-015', 'PLM', NULL, 'Shut-off valve', 'EA', '{add,replace}', 'PLM', true, 'zafto', '{plumbing,valve,shutoff}'),
    (cat_plm, 'Z-PLM-016', 'PLM', NULL, 'Sump pump', 'EA', '{add,replace}', 'PLM', false, 'zafto', '{plumbing,sump,pump}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- ELECTRICAL (ELE) — 16 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_ele, 'Z-ELE-001', 'ELE', 'OUTLET', 'Outlet - standard duplex 15A', 'EA', '{add,replace}', 'ELE', true, 'zafto', '{electrical,outlet,duplex}'),
    (cat_ele, 'Z-ELE-002', 'ELE', 'OUTLET', 'Outlet - GFCI 20A', 'EA', '{add,replace}', 'ELE', true, 'zafto', '{electrical,outlet,gfci}'),
    (cat_ele, 'Z-ELE-003', 'ELE', 'SWITCH', 'Switch - single pole', 'EA', '{add,replace}', 'ELE', true, 'zafto', '{electrical,switch,single}'),
    (cat_ele, 'Z-ELE-004', 'ELE', 'SWITCH', 'Switch - 3-way', 'EA', '{add,replace}', 'ELE', true, 'zafto', '{electrical,switch,three,way}'),
    (cat_ele, 'Z-ELE-005', 'ELE', 'SWITCH', 'Dimmer switch', 'EA', '{add,replace}', 'ELE', true, 'zafto', '{electrical,switch,dimmer}'),
    (cat_ele, 'Z-ELE-006', 'ELE', 'LIGHT', 'Light fixture - standard ceiling', 'EA', '{add,replace}', 'ELE', true, 'zafto', '{electrical,light,ceiling}'),
    (cat_ele, 'Z-ELE-007', 'ELE', 'LIGHT', 'Recessed light (can light)', 'EA', '{add,replace}', 'ELE', true, 'zafto', '{electrical,light,recessed,can}'),
    (cat_ele, 'Z-ELE-008', 'ELE', NULL, 'Ceiling fan with light', 'EA', '{add,replace}', 'ELE', true, 'zafto', '{electrical,fan,ceiling}'),
    (cat_ele, 'Z-ELE-009', 'ELE', 'PANEL', 'Electrical panel - 200A main', 'EA', '{add,replace}', 'ELE', false, 'zafto', '{electrical,panel,main}'),
    (cat_ele, 'Z-ELE-010', 'ELE', 'PANEL', 'Electrical sub-panel', 'EA', '{add}', 'ELE', false, 'zafto', '{electrical,panel,sub}'),
    (cat_ele, 'Z-ELE-011', 'ELE', 'WIRE', 'Wire - 14/2 NM-B (Romex)', 'LF', '{add}', 'ELE', true, 'zafto', '{electrical,wire,romex,14}'),
    (cat_ele, 'Z-ELE-012', 'ELE', 'WIRE', 'Wire - 12/2 NM-B (Romex)', 'LF', '{add}', 'ELE', true, 'zafto', '{electrical,wire,romex,12}'),
    (cat_ele, 'Z-ELE-013', 'ELE', NULL, 'Smoke detector - hardwired', 'EA', '{add,replace}', 'ELE', true, 'zafto', '{electrical,smoke,detector}'),
    (cat_ele, 'Z-ELE-014', 'ELE', NULL, 'Bathroom exhaust fan', 'EA', '{add,replace}', 'ELE', true, 'zafto', '{electrical,exhaust,fan,bathroom}'),
    (cat_ele, 'Z-ELE-015', 'ELE', NULL, 'Dedicated circuit - 20A', 'EA', '{add}', 'ELE', true, 'zafto', '{electrical,circuit,dedicated}'),
    (cat_ele, 'Z-ELE-016', 'ELE', NULL, 'Outdoor lighting - LED', 'EA', '{add,replace}', 'ELE', false, 'zafto', '{electrical,light,outdoor,led}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- PAINTING (PNT) — 12 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_pnt, 'Z-PNT-001', 'PNT', 'WALL', 'Paint interior walls - 2 coats', 'SF', '{add}', 'PNT', true, 'zafto', '{painting,interior,wall}'),
    (cat_pnt, 'Z-PNT-002', 'PNT', 'CEILING', 'Paint ceiling - 2 coats', 'SF', '{add}', 'PNT', true, 'zafto', '{painting,ceiling}'),
    (cat_pnt, 'Z-PNT-003', 'PNT', 'TRIM', 'Paint trim/baseboard', 'LF', '{add}', 'PNT', true, 'zafto', '{painting,trim,baseboard}'),
    (cat_pnt, 'Z-PNT-004', 'PNT', 'DOOR', 'Paint door - both sides', 'EA', '{add}', 'PNT', true, 'zafto', '{painting,door}'),
    (cat_pnt, 'Z-PNT-005', 'PNT', NULL, 'Paint exterior walls', 'SF', '{add}', 'PNT', true, 'zafto', '{painting,exterior,wall}'),
    (cat_pnt, 'Z-PNT-006', 'PNT', NULL, 'Paint exterior trim', 'LF', '{add}', 'PNT', true, 'zafto', '{painting,exterior,trim}'),
    (cat_pnt, 'Z-PNT-007', 'PNT', NULL, 'Primer coat - interior', 'SF', '{add}', 'PNT', true, 'zafto', '{painting,primer,interior}'),
    (cat_pnt, 'Z-PNT-008', 'PNT', NULL, 'Primer coat - stain blocking', 'SF', '{add}', 'PNT', true, 'zafto', '{painting,primer,stain,block}'),
    (cat_pnt, 'Z-PNT-009', 'PNT', NULL, 'Stain/seal wood - clear coat', 'SF', '{add}', 'PNT', false, 'zafto', '{painting,stain,seal,wood}'),
    (cat_pnt, 'Z-PNT-010', 'PNT', NULL, 'Cabinet refinishing', 'LF', '{add}', 'PNT', false, 'zafto', '{painting,cabinet,refinish}'),
    (cat_pnt, 'Z-PNT-011', NULL, NULL, 'Paint prep - scrape & sand', 'SF', '{add}', 'PNT', true, 'zafto', '{painting,prep,scrape,sand}'),
    (cat_pnt, 'Z-PNT-012', NULL, NULL, 'Caulking - interior', 'LF', '{add}', 'PNT', true, 'zafto', '{painting,caulk,interior}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- DEMOLITION (DMO) — 12 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_dmo, 'Z-DMO-001', 'DMO', 'DRYWALL', 'Remove drywall', 'SF', '{remove}', 'DMO', true, 'zafto', '{demo,drywall,remove}'),
    (cat_dmo, 'Z-DMO-002', 'DMO', 'BASEBOARD', 'Remove baseboard/trim', 'LF', '{remove}', 'DMO', true, 'zafto', '{demo,baseboard,trim,remove}'),
    (cat_dmo, 'Z-DMO-003', 'DMO', 'FLOORING', 'Remove flooring - hardwood/vinyl', 'SF', '{remove}', 'DMO', true, 'zafto', '{demo,flooring,remove}'),
    (cat_dmo, 'Z-DMO-004', 'DMO', 'CARPET', 'Remove carpet & pad', 'SF', '{remove}', 'DMO', true, 'zafto', '{demo,carpet,pad,remove}'),
    (cat_dmo, 'Z-DMO-005', 'DMO', 'CABINETRY', 'Remove cabinets', 'LF', '{remove}', 'DMO', true, 'zafto', '{demo,cabinet,remove}'),
    (cat_dmo, 'Z-DMO-006', 'DMO', 'INSULATION', 'Remove insulation', 'SF', '{remove}', 'DMO', true, 'zafto', '{demo,insulation,remove}'),
    (cat_dmo, 'Z-DMO-007', 'DMO', NULL, 'Remove tile - wall/floor', 'SF', '{remove}', 'DMO', true, 'zafto', '{demo,tile,remove}'),
    (cat_dmo, 'Z-DMO-008', 'DMO', NULL, 'Remove toilet', 'EA', '{remove,detach_reset}', 'DMO', true, 'zafto', '{demo,toilet,remove}'),
    (cat_dmo, 'Z-DMO-009', 'DMO', NULL, 'Remove vanity/sink', 'EA', '{remove,detach_reset}', 'DMO', true, 'zafto', '{demo,vanity,sink,remove}'),
    (cat_dmo, 'Z-DMO-010', 'DMO', NULL, 'Remove bathtub', 'EA', '{remove}', 'DMO', false, 'zafto', '{demo,bathtub,remove}'),
    (cat_dmo, 'Z-DMO-011', NULL, NULL, 'Haul-off/debris removal - truck load', 'EA', '{remove}', 'DMO', true, 'zafto', '{demo,haul,debris,disposal}'),
    (cat_dmo, 'Z-DMO-012', NULL, NULL, 'Dumpster rental - 20 yd', 'DA', '{add}', 'DMO', true, 'zafto', '{demo,dumpster,rental}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- WATER EXTRACTION/REMEDIATION (WTR) — 10 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_wtr, 'Z-WTR-001', 'WTR', 'EXTRACT', 'Water extraction - standing water', 'SF', '{add}', 'WTR', true, 'zafto', '{water,extraction,standing}'),
    (cat_wtr, 'Z-WTR-002', 'WTR', 'DRY', 'Structural drying', 'SF', '{add}', 'WTR', true, 'zafto', '{water,drying,structural}'),
    (cat_wtr, 'Z-WTR-003', 'WTR', 'DEHU', 'Dehumidifier - per day', 'DA', '{add}', 'WTR', true, 'zafto', '{water,dehumidifier,equipment}'),
    (cat_wtr, 'Z-WTR-004', 'WTR', 'AIRMOVER', 'Air mover - per day', 'DA', '{add}', 'WTR', true, 'zafto', '{water,air,mover,equipment}'),
    (cat_wtr, 'Z-WTR-005', 'WTR', NULL, 'HEPA air scrubber - per day', 'DA', '{add}', 'WTR', true, 'zafto', '{water,air,scrubber,hepa}'),
    (cat_wtr, 'Z-WTR-006', 'WTR', NULL, 'Antimicrobial treatment', 'SF', '{add}', 'WTR', true, 'zafto', '{water,antimicrobial,treatment}'),
    (cat_wtr, 'Z-WTR-007', 'WTR', NULL, 'Moisture testing/monitoring', 'EA', '{add}', 'WTR', true, 'zafto', '{water,moisture,testing}'),
    (cat_wtr, 'Z-WTR-008', 'WTR', NULL, 'Containment/barrier setup', 'LF', '{add}', 'WTR', true, 'zafto', '{water,containment,barrier}'),
    (cat_wtr, 'Z-WTR-009', NULL, NULL, 'Mold remediation - surface', 'SF', '{add}', 'WTR', false, 'zafto', '{water,mold,remediation,surface}'),
    (cat_wtr, 'Z-WTR-010', NULL, NULL, 'Mold remediation - structural', 'SF', '{add}', 'WTR', false, 'zafto', '{water,mold,remediation,structural}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- FRAMING (FRM) — 10 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_frm, 'Z-FRM-001', 'FRM', 'WALL24', 'Frame wall - 2x4', 'LF', '{add,replace}', 'FRM', true, 'zafto', '{framing,wall,2x4}'),
    (cat_frm, 'Z-FRM-002', 'FRM', 'WALL26', 'Frame wall - 2x6', 'LF', '{add,replace}', 'FRM', true, 'zafto', '{framing,wall,2x6}'),
    (cat_frm, 'Z-FRM-003', 'FRM', 'HEADER', 'Install header - doubled 2x8', 'EA', '{add,replace}', 'FRM', true, 'zafto', '{framing,header}'),
    (cat_frm, 'Z-FRM-004', 'FRM', NULL, 'Sister/reinforce joist', 'LF', '{repair}', 'FRM', true, 'zafto', '{framing,joist,sister,repair}'),
    (cat_frm, 'Z-FRM-005', 'FRM', NULL, 'Replace stud', 'EA', '{replace}', 'FRM', true, 'zafto', '{framing,stud,replace}'),
    (cat_frm, 'Z-FRM-006', 'FRM', NULL, 'Subfloor - 3/4" plywood', 'SF', '{add,replace}', 'FRM', true, 'zafto', '{framing,subfloor,plywood}'),
    (cat_frm, 'Z-FRM-007', 'FRM', NULL, 'Subfloor - OSB', 'SF', '{add,replace}', 'FRM', true, 'zafto', '{framing,subfloor,osb}'),
    (cat_frm, 'Z-FRM-008', 'FRM', NULL, 'Roof sheathing - 1/2" plywood', 'SF', '{add,replace}', 'FRM', true, 'zafto', '{framing,roof,sheathing,plywood}'),
    (cat_frm, 'Z-FRM-009', 'FRM', NULL, 'Truss/rafter repair', 'EA', '{repair}', 'FRM', false, 'zafto', '{framing,truss,rafter,repair}'),
    (cat_frm, 'Z-FRM-010', 'FRM', NULL, 'Blocking/fire stopping', 'LF', '{add}', 'FRM', true, 'zafto', '{framing,blocking,firestop}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- INSULATION (INS) — 8 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_ins, 'Z-INS-001', 'INS', 'BATT', 'Batt insulation - R-13 (2x4 wall)', 'SF', '{add,replace}', 'INS', true, 'zafto', '{insulation,batt,r13}'),
    (cat_ins, 'Z-INS-002', 'INS', 'BATT', 'Batt insulation - R-19 (2x6 wall)', 'SF', '{add,replace}', 'INS', true, 'zafto', '{insulation,batt,r19}'),
    (cat_ins, 'Z-INS-003', 'INS', 'BATT', 'Batt insulation - R-30 (attic)', 'SF', '{add,replace}', 'INS', true, 'zafto', '{insulation,batt,r30,attic}'),
    (cat_ins, 'Z-INS-004', 'INS', 'BLOWN', 'Blown insulation - attic', 'SF', '{add}', 'INS', true, 'zafto', '{insulation,blown,attic}'),
    (cat_ins, 'Z-INS-005', 'INS', NULL, 'Spray foam - open cell', 'SF', '{add}', 'INS', false, 'zafto', '{insulation,spray,foam,open}'),
    (cat_ins, 'Z-INS-006', 'INS', NULL, 'Spray foam - closed cell', 'SF', '{add}', 'INS', false, 'zafto', '{insulation,spray,foam,closed}'),
    (cat_ins, 'Z-INS-007', 'INS', NULL, 'Rigid foam board', 'SF', '{add}', 'INS', false, 'zafto', '{insulation,rigid,foam,board}'),
    (cat_ins, 'Z-INS-008', 'INS', NULL, 'Vapor barrier - 6 mil poly', 'SF', '{add}', 'INS', true, 'zafto', '{insulation,vapor,barrier}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- SIDING (SDG) — 8 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_sdg, 'Z-SDG-001', 'SDG', 'VINYL', 'Vinyl siding', 'SF', '{add,replace}', 'SDG', true, 'zafto', '{siding,vinyl}'),
    (cat_sdg, 'Z-SDG-002', 'SDG', NULL, 'Fiber cement siding (HardiePlank)', 'SF', '{add,replace}', 'SDG', true, 'zafto', '{siding,fiber,cement,hardie}'),
    (cat_sdg, 'Z-SDG-003', 'SDG', 'WOOD', 'Wood siding - lap/clapboard', 'SF', '{add,replace}', 'SDG', true, 'zafto', '{siding,wood,lap}'),
    (cat_sdg, 'Z-SDG-004', 'SDG', NULL, 'T1-11 panel siding', 'SF', '{add,replace}', 'SDG', false, 'zafto', '{siding,panel,t111}'),
    (cat_sdg, 'Z-SDG-005', 'SDG', NULL, 'House wrap (Tyvek)', 'SF', '{add}', 'SDG', true, 'zafto', '{siding,housewrap,tyvek}'),
    (cat_sdg, 'Z-SDG-006', NULL, NULL, 'Soffit - vinyl', 'LF', '{add,replace}', 'SDG', true, 'zafto', '{siding,soffit,vinyl}'),
    (cat_sdg, 'Z-SDG-007', NULL, NULL, 'Fascia board', 'LF', '{add,replace}', 'SDG', true, 'zafto', '{siding,fascia}'),
    (cat_sdg, 'Z-SDG-008', NULL, NULL, 'Siding removal', 'SF', '{remove}', 'SDG', true, 'zafto', '{siding,remove,demo}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- HVAC (HVC) — 12 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_hvc, 'Z-HVC-001', 'HVC', 'FURNACE', 'Furnace - gas, 80% AFUE', 'EA', '{add,replace}', 'HVC', true, 'zafto', '{hvac,furnace,gas}'),
    (cat_hvc, 'Z-HVC-002', 'HVC', 'FURNACE', 'Furnace - gas, 95%+ high efficiency', 'EA', '{add,replace}', 'HVC', false, 'zafto', '{hvac,furnace,gas,high,efficiency}'),
    (cat_hvc, 'Z-HVC-003', 'HVC', 'CONDENSER', 'AC condenser - 2.5 ton', 'EA', '{add,replace}', 'HVC', true, 'zafto', '{hvac,condenser,ac}'),
    (cat_hvc, 'Z-HVC-004', 'HVC', 'CONDENSER', 'AC condenser - 3.5 ton', 'EA', '{add,replace}', 'HVC', true, 'zafto', '{hvac,condenser,ac}'),
    (cat_hvc, 'Z-HVC-005', 'HVC', NULL, 'Heat pump - split system', 'EA', '{add,replace}', 'HVC', false, 'zafto', '{hvac,heat,pump,split}'),
    (cat_hvc, 'Z-HVC-006', 'HVC', 'DUCT', 'Ductwork - flex duct', 'LF', '{add,replace}', 'HVC', true, 'zafto', '{hvac,duct,flex}'),
    (cat_hvc, 'Z-HVC-007', 'HVC', 'DUCT', 'Ductwork - sheet metal', 'LF', '{add,replace}', 'HVC', true, 'zafto', '{hvac,duct,metal}'),
    (cat_hvc, 'Z-HVC-008', 'HVC', NULL, 'Register/grille', 'EA', '{add,replace}', 'HVC', true, 'zafto', '{hvac,register,grille}'),
    (cat_hvc, 'Z-HVC-009', 'HVC', NULL, 'Thermostat - programmable', 'EA', '{add,replace}', 'HVC', true, 'zafto', '{hvac,thermostat}'),
    (cat_hvc, 'Z-HVC-010', 'HVC', NULL, 'Refrigerant line set', 'LF', '{add,replace}', 'HVC', true, 'zafto', '{hvac,refrigerant,lineset}'),
    (cat_hvc, 'Z-HVC-011', 'HVC', NULL, 'Mini split - ductless', 'EA', '{add}', 'HVC', false, 'zafto', '{hvac,mini,split,ductless}'),
    (cat_hvc, 'Z-HVC-012', 'HVC', NULL, 'Duct cleaning', 'EA', '{clean}', 'HVC', false, 'zafto', '{hvac,duct,cleaning}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- FLOORING (FCV + FCT + FCW + FCC) — 16 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    -- Vinyl/Resilient
    (cat_fcv, 'Z-FCV-001', 'FCV', 'LVP', 'Luxury vinyl plank (LVP)', 'SF', '{add}', 'FCV', true, 'zafto', '{flooring,vinyl,lvp,plank}'),
    (cat_fcv, 'Z-FCV-002', 'FCV', NULL, 'Luxury vinyl tile (LVT)', 'SF', '{add}', 'FCV', true, 'zafto', '{flooring,vinyl,lvt,tile}'),
    (cat_fcv, 'Z-FCV-003', 'FCV', NULL, 'Sheet vinyl', 'SF', '{add}', 'FCV', true, 'zafto', '{flooring,vinyl,sheet}'),
    (cat_fcv, 'Z-FCV-004', 'FCV', NULL, 'Underlayment - vinyl flooring', 'SF', '{add}', 'FCV', true, 'zafto', '{flooring,underlayment,vinyl}'),
    -- Tile
    (cat_fct, 'Z-FCT-001', 'FCT', 'CERAMIC', 'Ceramic tile - floor', 'SF', '{add}', 'FCT', true, 'zafto', '{flooring,tile,ceramic}'),
    (cat_fct, 'Z-FCT-002', 'FCT', NULL, 'Porcelain tile - floor', 'SF', '{add}', 'FCT', true, 'zafto', '{flooring,tile,porcelain}'),
    (cat_fct, 'Z-FCT-003', 'FCT', NULL, 'Tile backer board (Durock/Hardiebacker)', 'SF', '{add}', 'FCT', true, 'zafto', '{flooring,tile,backer,board}'),
    (cat_fct, 'Z-FCT-004', 'FCT', NULL, 'Grout - sanded', 'SF', '{add}', 'FCT', true, 'zafto', '{flooring,tile,grout}'),
    -- Wood
    (cat_fcw, 'Z-FCW-001', 'FCW', 'HARDWOOD', 'Hardwood flooring - solid oak', 'SF', '{add}', 'FCW', true, 'zafto', '{flooring,hardwood,oak,solid}'),
    (cat_fcw, 'Z-FCW-002', 'FCW', NULL, 'Engineered hardwood', 'SF', '{add}', 'FCW', true, 'zafto', '{flooring,hardwood,engineered}'),
    (cat_fcw, 'Z-FCW-003', 'FCW', NULL, 'Hardwood refinish - sand & finish', 'SF', '{add}', 'FCW', true, 'zafto', '{flooring,hardwood,refinish,sand}'),
    (cat_fcw, 'Z-FCW-004', 'FCW', NULL, 'Laminate flooring', 'SF', '{add}', 'FCW', true, 'zafto', '{flooring,laminate}'),
    -- Carpet
    (cat_fcc, 'Z-FCC-001', 'FCC', 'CARPET', 'Carpet - standard grade', 'SY', '{add}', 'FCC', true, 'zafto', '{flooring,carpet,standard}'),
    (cat_fcc, 'Z-FCC-002', 'FCC', NULL, 'Carpet - premium grade', 'SY', '{add}', 'FCC', false, 'zafto', '{flooring,carpet,premium}'),
    (cat_fcc, 'Z-FCC-003', 'FCC', NULL, 'Carpet pad - 8 lb', 'SY', '{add}', 'FCC', true, 'zafto', '{flooring,carpet,pad}'),
    (cat_fcc, 'Z-FCC-004', 'FCC', NULL, 'Carpet transition strip', 'LF', '{add}', 'FCC', true, 'zafto', '{flooring,carpet,transition}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- TILE (TIL) — 8 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_til, 'Z-TIL-001', 'TIL', 'WALL', 'Wall tile - ceramic', 'SF', '{add}', 'TIL', true, 'zafto', '{tile,wall,ceramic}'),
    (cat_til, 'Z-TIL-002', 'TIL', 'SHOWER', 'Shower tile - porcelain', 'SF', '{add}', 'TIL', true, 'zafto', '{tile,shower,porcelain}'),
    (cat_til, 'Z-TIL-003', 'TIL', NULL, 'Tile backsplash', 'SF', '{add}', 'TIL', true, 'zafto', '{tile,backsplash,kitchen}'),
    (cat_til, 'Z-TIL-004', 'TIL', NULL, 'Shower pan - mortar/mud bed', 'EA', '{add}', 'TIL', true, 'zafto', '{tile,shower,pan,mortar}'),
    (cat_til, 'Z-TIL-005', 'TIL', NULL, 'Waterproof membrane (Kerdi/RedGard)', 'SF', '{add}', 'TIL', true, 'zafto', '{tile,waterproof,membrane}'),
    (cat_til, 'Z-TIL-006', 'TIL', NULL, 'Tile bullnose/edge trim', 'LF', '{add}', 'TIL', true, 'zafto', '{tile,bullnose,edge}'),
    (cat_til, 'Z-TIL-007', 'TIL', NULL, 'Tile niche/recessed shelf', 'EA', '{add}', 'TIL', false, 'zafto', '{tile,niche,shelf}'),
    (cat_til, 'Z-TIL-008', 'TIL', NULL, 'Grout sealing', 'SF', '{add}', 'TIL', true, 'zafto', '{tile,grout,seal}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- CABINETS & COUNTERTOPS (CAB + CNT) — 10 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_cab, 'Z-CAB-001', 'CAB', 'BASE', 'Base cabinet - standard', 'LF', '{add,replace}', 'CAB', true, 'zafto', '{cabinet,base,standard}'),
    (cat_cab, 'Z-CAB-002', 'CAB', 'WALL', 'Wall cabinet - standard', 'LF', '{add,replace}', 'CAB', true, 'zafto', '{cabinet,wall,upper}'),
    (cat_cab, 'Z-CAB-003', 'CAB', NULL, 'Vanity cabinet - bathroom', 'EA', '{add,replace}', 'CAB', true, 'zafto', '{cabinet,vanity,bathroom}'),
    (cat_cab, 'Z-CAB-004', 'CAB', NULL, 'Cabinet hardware - knobs', 'EA', '{add,replace}', 'CAB', true, 'zafto', '{cabinet,hardware,knob}'),
    (cat_cab, 'Z-CAB-005', 'CAB', NULL, 'Cabinet hardware - pulls', 'EA', '{add,replace}', 'CAB', true, 'zafto', '{cabinet,hardware,pull}'),
    (cat_cnt, 'Z-CNT-001', 'CAB', 'COUNTERTOP', 'Countertop - laminate', 'LF', '{add,replace}', 'CAB', true, 'zafto', '{countertop,laminate}'),
    (cat_cnt, 'Z-CNT-002', NULL, NULL, 'Countertop - granite', 'SF', '{add,replace}', 'CAB', false, 'zafto', '{countertop,granite,stone}'),
    (cat_cnt, 'Z-CNT-003', NULL, NULL, 'Countertop - quartz', 'SF', '{add,replace}', 'CAB', false, 'zafto', '{countertop,quartz}'),
    (cat_cnt, 'Z-CNT-004', NULL, NULL, 'Countertop - butcher block', 'SF', '{add,replace}', 'CAB', false, 'zafto', '{countertop,butcher,block,wood}'),
    (cat_cnt, 'Z-CNT-005', NULL, NULL, 'Backsplash - subway tile', 'SF', '{add}', 'CAB', true, 'zafto', '{countertop,backsplash,tile}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- DOORS (DOR) — 8 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_dor, 'Z-DOR-001', 'DOR', 'INT', 'Interior door - hollow core, pre-hung', 'EA', '{add,replace}', 'DOR', true, 'zafto', '{door,interior,hollow,prehung}'),
    (cat_dor, 'Z-DOR-002', 'DOR', 'INT', 'Interior door - solid core, pre-hung', 'EA', '{add,replace}', 'DOR', true, 'zafto', '{door,interior,solid,prehung}'),
    (cat_dor, 'Z-DOR-003', 'DOR', 'EXT', 'Exterior door - steel, pre-hung', 'EA', '{add,replace}', 'DOR', true, 'zafto', '{door,exterior,steel,prehung}'),
    (cat_dor, 'Z-DOR-004', 'DOR', 'EXT', 'Exterior door - fiberglass, pre-hung', 'EA', '{add,replace}', 'DOR', true, 'zafto', '{door,exterior,fiberglass}'),
    (cat_dor, 'Z-DOR-005', 'DOR', NULL, 'Sliding patio door', 'EA', '{add,replace}', 'DOR', true, 'zafto', '{door,patio,sliding}'),
    (cat_dor, 'Z-DOR-006', 'DOR', NULL, 'Door hardware - lockset', 'EA', '{add,replace}', 'DOR', true, 'zafto', '{door,hardware,lockset}'),
    (cat_dor, 'Z-DOR-007', 'DOR', NULL, 'Door casing/trim', 'LF', '{add,replace}', 'DOR', true, 'zafto', '{door,casing,trim}'),
    (cat_dor, 'Z-DOR-008', 'DOR', NULL, 'Garage door - single 9x7', 'EA', '{add,replace}', 'DOR', false, 'zafto', '{door,garage,single}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- WINDOWS (WDW) — 8 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_wdw, 'Z-WDW-001', 'WDW', 'STD', 'Window - double hung, vinyl', 'EA', '{add,replace}', 'WDW', true, 'zafto', '{window,double,hung,vinyl}'),
    (cat_wdw, 'Z-WDW-002', 'WDW', 'SLIDER', 'Window - sliding, vinyl', 'EA', '{add,replace}', 'WDW', true, 'zafto', '{window,sliding,vinyl}'),
    (cat_wdw, 'Z-WDW-003', 'WDW', NULL, 'Window - casement', 'EA', '{add,replace}', 'WDW', true, 'zafto', '{window,casement}'),
    (cat_wdw, 'Z-WDW-004', 'WDW', NULL, 'Window - picture/fixed', 'EA', '{add,replace}', 'WDW', false, 'zafto', '{window,picture,fixed}'),
    (cat_wdw, 'Z-WDW-005', 'WDW', NULL, 'Window screen', 'EA', '{add,replace}', 'WDW', true, 'zafto', '{window,screen}'),
    (cat_wdw, 'Z-WDW-006', 'WDW', NULL, 'Window trim/casing - interior', 'LF', '{add,replace}', 'WDW', true, 'zafto', '{window,trim,casing}'),
    (cat_wdw, 'Z-WDW-007', 'WDW', NULL, 'Window sill', 'LF', '{add,replace}', 'WDW', true, 'zafto', '{window,sill}'),
    (cat_wdw, 'Z-WDW-008', NULL, NULL, 'Window film/tinting', 'SF', '{add}', 'WDW', false, 'zafto', '{window,film,tint}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- CLEANING (CLN) — 6 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_cln, 'Z-CLN-001', 'CLN', 'GENERAL', 'Final clean - construction', 'SF', '{clean}', 'CLN', true, 'zafto', '{cleaning,final,construction}'),
    (cat_cln, 'Z-CLN-002', 'CLN', 'CARPET', 'Carpet cleaning - hot water extraction', 'SF', '{clean}', 'CLN', true, 'zafto', '{cleaning,carpet,extraction}'),
    (cat_cln, 'Z-CLN-003', 'CLN', NULL, 'Window cleaning', 'EA', '{clean}', 'CLN', true, 'zafto', '{cleaning,window}'),
    (cat_cln, 'Z-CLN-004', 'CLN', NULL, 'Pressure washing', 'SF', '{clean}', 'CLN', true, 'zafto', '{cleaning,pressure,wash}'),
    (cat_cln, 'Z-CLN-005', 'CLN', NULL, 'HVAC duct cleaning', 'EA', '{clean}', 'CLN', false, 'zafto', '{cleaning,hvac,duct}'),
    (cat_cln, 'Z-CLN-006', 'CLN', 'MOLD', 'Mold cleaning - surface treatment', 'SF', '{clean}', 'CLN', false, 'zafto', '{cleaning,mold,treatment}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- CONCRETE & MASONRY (CNC + MAS) — 8 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    (cat_cnc, 'Z-CNC-001', 'CNC', 'SLAB', 'Concrete slab - 4"', 'SF', '{add}', 'CNC', true, 'zafto', '{concrete,slab,pour}'),
    (cat_cnc, 'Z-CNC-002', 'CNC', NULL, 'Concrete sidewalk', 'SF', '{add,replace}', 'CNC', true, 'zafto', '{concrete,sidewalk}'),
    (cat_cnc, 'Z-CNC-003', 'CNC', NULL, 'Concrete driveway', 'SF', '{add,replace}', 'CNC', true, 'zafto', '{concrete,driveway}'),
    (cat_cnc, 'Z-CNC-004', 'CNC', NULL, 'Foundation repair - crack seal', 'LF', '{repair}', 'CNC', true, 'zafto', '{concrete,foundation,repair,crack}'),
    (cat_mas, 'Z-MAS-001', 'MAS', 'BRICK', 'Brick veneer', 'SF', '{add}', 'MAS', true, 'zafto', '{masonry,brick,veneer}'),
    (cat_mas, 'Z-MAS-002', 'MAS', NULL, 'Block wall - CMU', 'SF', '{add}', 'MAS', true, 'zafto', '{masonry,block,cmu}'),
    (cat_mas, 'Z-MAS-003', 'MAS', NULL, 'Stone veneer', 'SF', '{add}', 'MAS', false, 'zafto', '{masonry,stone,veneer}'),
    (cat_mas, 'Z-MAS-004', 'MAS', NULL, 'Tuckpointing/repointing', 'SF', '{repair}', 'MAS', true, 'zafto', '{masonry,tuckpoint,repoint,mortar}')
    ON CONFLICT DO NOTHING;

    -- ========================================
    -- GENERAL & MISC (LAB, FEE, TMB, GUT, etc.) — 16 items
    -- ========================================
    INSERT INTO estimate_items (category_id, zafto_code, industry_code, industry_selector, description, unit_code, action_types, trade, is_common, source, tags) VALUES
    -- Trim/Baseboard
    (cat_tmb, 'Z-TMB-001', 'TMB', NULL, 'Baseboard - MDF/paint grade', 'LF', '{add,replace}', 'FNC', true, 'zafto', '{trim,baseboard,mdf}'),
    (cat_tmb, 'Z-TMB-002', 'TMB', NULL, 'Baseboard - oak/stain grade', 'LF', '{add,replace}', 'FNC', true, 'zafto', '{trim,baseboard,oak}'),
    (cat_tmb, 'Z-TMB-003', 'TMB', NULL, 'Crown molding', 'LF', '{add,replace}', 'FNC', true, 'zafto', '{trim,crown,molding}'),
    (cat_tmb, 'Z-TMB-004', 'TMB', NULL, 'Quarter round/shoe mold', 'LF', '{add,replace}', 'FNC', true, 'zafto', '{trim,quarter,round,shoe}'),
    -- Gutters
    (cat_gut, 'Z-GUT-001', NULL, NULL, 'Gutters - 5" aluminum K-style', 'LF', '{add,replace}', 'RFG', true, 'zafto', '{gutter,aluminum,k-style}'),
    (cat_gut, 'Z-GUT-002', NULL, NULL, 'Downspout - aluminum', 'LF', '{add,replace}', 'RFG', true, 'zafto', '{gutter,downspout,aluminum}'),
    (cat_gut, 'Z-GUT-003', NULL, NULL, 'Gutter guard/screen', 'LF', '{add}', 'RFG', false, 'zafto', '{gutter,guard,screen}'),
    -- Appliances
    (cat_app, 'Z-APP-001', 'APP', 'FRIDGE', 'Refrigerator - standard', 'EA', '{add,replace}', 'APP', true, 'zafto', '{appliance,refrigerator}'),
    (cat_app, 'Z-APP-002', 'APP', 'RANGE', 'Range/stove - gas', 'EA', '{add,replace}', 'APP', true, 'zafto', '{appliance,range,stove,gas}'),
    (cat_app, 'Z-APP-003', 'APP', 'DISHWASHER', 'Dishwasher - standard', 'EA', '{add,replace}', 'APP', true, 'zafto', '{appliance,dishwasher}'),
    (cat_app, 'Z-APP-004', 'APP', 'WASHER', 'Washing machine', 'EA', '{add,replace}', 'APP', true, 'zafto', '{appliance,washer}'),
    (cat_app, 'Z-APP-005', 'APP', 'DRYER', 'Dryer - electric', 'EA', '{add,replace}', 'APP', true, 'zafto', '{appliance,dryer}'),
    -- General Labor & Fees
    (cat_lab, 'Z-LAB-001', 'LAB', NULL, 'General labor - skilled', 'HR', '{add}', 'LAB', true, 'zafto', '{labor,skilled,general}'),
    (cat_lab, 'Z-LAB-002', 'LAB', NULL, 'General labor - unskilled', 'HR', '{add}', 'LAB', true, 'zafto', '{labor,unskilled,helper}'),
    (cat_fee, 'Z-FEE-001', 'FEE', NULL, 'Building permit', 'LS', '{add}', 'FEE', true, 'zafto', '{fee,permit,building}'),
    (cat_fee, 'Z-FEE-002', 'FEE', NULL, 'Dumpster permit', 'EA', '{add}', 'FEE', false, 'zafto', '{fee,permit,dumpster}')
    ON CONFLICT DO NOTHING;

END $$;


-- ============================================================
-- 4. BASE LABOR RATES (from BLS public data — May 2024 estimates)
-- Source: Bureau of Labor Statistics — Occupational Employment and Wage Statistics
-- These are national median hourly wages; regional adjustments applied via estimate_pricing
-- ============================================================
INSERT INTO estimate_labor_components (code, trade, description, base_rate, markup, burden_pct, source) VALUES
-- Rates from BLS OES May 2024 national estimates (publicly published)
('RFG-BASE', 'RFG', 'Roofer - journeyman', 24.50, 15.00, 0.3200, 'bls'),
('RFG-APPR', 'RFG', 'Roofer - apprentice', 17.00, 10.00, 0.3200, 'bls'),
('DRY-BASE', 'DRY', 'Drywall installer - journeyman', 25.80, 15.00, 0.3200, 'bls'),
('DRY-TAPER', 'DRY', 'Drywall taper/finisher', 27.50, 15.00, 0.3200, 'bls'),
('PLM-BASE', 'PLM', 'Plumber - journeyman', 30.50, 20.00, 0.3500, 'bls'),
('PLM-APPR', 'PLM', 'Plumber - apprentice', 19.50, 12.00, 0.3500, 'bls'),
('ELE-BASE', 'ELE', 'Electrician - journeyman', 31.00, 20.00, 0.3500, 'bls'),
('ELE-APPR', 'ELE', 'Electrician - apprentice', 19.00, 12.00, 0.3500, 'bls'),
('PNT-BASE', 'PNT', 'Painter - journeyman', 22.50, 12.00, 0.3000, 'bls'),
('PNT-APPR', 'PNT', 'Painter - apprentice', 16.00, 8.00, 0.3000, 'bls'),
('DMO-BASE', 'DMO', 'Demolition worker', 20.00, 10.00, 0.3000, 'bls'),
('WTR-BASE', 'WTR', 'Water restoration tech', 23.00, 15.00, 0.3200, 'bls'),
('WTR-CERT', 'WTR', 'Water restoration tech - IICRC certified', 28.00, 18.00, 0.3200, 'bls'),
('FRM-BASE', 'FRM', 'Carpenter/framer - journeyman', 26.50, 15.00, 0.3200, 'bls'),
('FRM-APPR', 'FRM', 'Carpenter/framer - apprentice', 18.00, 10.00, 0.3200, 'bls'),
('INS-BASE', 'INS', 'Insulation installer', 21.50, 12.00, 0.3000, 'bls'),
('SDG-BASE', 'SDG', 'Siding installer', 23.00, 12.00, 0.3000, 'bls'),
('HVC-BASE', 'HVC', 'HVAC technician - journeyman', 28.50, 18.00, 0.3500, 'bls'),
('HVC-APPR', 'HVC', 'HVAC technician - apprentice', 18.50, 10.00, 0.3500, 'bls'),
('TIL-BASE', 'TIL', 'Tile setter - journeyman', 24.00, 14.00, 0.3000, 'bls'),
('FLR-BASE', 'FCV', 'Floor layer - journeyman', 23.50, 14.00, 0.3000, 'bls'),
('CAB-BASE', 'CAB', 'Cabinet installer', 24.50, 14.00, 0.3000, 'bls'),
('CNC-BASE', 'CNC', 'Concrete worker', 24.00, 14.00, 0.3200, 'bls'),
('MAS-BASE', 'MAS', 'Mason - journeyman', 27.00, 16.00, 0.3200, 'bls'),
('CLN-BASE', 'CLN', 'Cleaning worker', 16.50, 8.00, 0.2800, 'bls'),
('GEN-LABOR', 'LAB', 'General laborer', 18.00, 8.00, 0.2800, 'bls'),
('GEN-SUPER', 'LAB', 'General superintendent', 38.00, 25.00, 0.3500, 'bls'),
('GEN-PM', 'LAB', 'Project manager', 42.00, 28.00, 0.3500, 'bls')
ON CONFLICT DO NOTHING;
