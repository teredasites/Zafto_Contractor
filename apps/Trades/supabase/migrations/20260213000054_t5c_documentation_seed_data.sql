-- T5c: Seed Data — Documentation Checklists + IICRC Equipment Chart Factors
-- Phase T (Programs/TPA Module) — Sprint T5
-- Default checklists: water mitigation, fire, mold, roofing + IICRC factors

-- ============================================================================
-- WATER MITIGATION CHECKLIST (22 items across 5 phases)
-- ============================================================================

INSERT INTO doc_checklist_templates (id, company_id, name, description, job_type, is_system_default) VALUES
  ('00000000-0000-0000-0000-000000000101', NULL, 'Water Mitigation Standard', 'IICRC S500 compliant water damage documentation', 'water_mitigation', true);

INSERT INTO doc_checklist_items (template_id, phase, item_name, description, is_required, evidence_type, min_count, sort_order) VALUES
  -- Initial Inspection (7 items)
  ('00000000-0000-0000-0000-000000000101', 'initial_inspection', 'Source identification photos', 'Photo of water source before mitigation begins', true, 'photo', 2, 1),
  ('00000000-0000-0000-0000-000000000101', 'initial_inspection', 'Affected area overview photos', 'Wide-angle photos of all affected areas', true, 'photo', 4, 2),
  ('00000000-0000-0000-0000-000000000101', 'initial_inspection', 'Water category determination', 'Document water category (1-3) with justification', true, 'form', 1, 3),
  ('00000000-0000-0000-0000-000000000101', 'initial_inspection', 'Water class determination', 'Document water class (1-4) per IICRC S500', true, 'form', 1, 4),
  ('00000000-0000-0000-0000-000000000101', 'initial_inspection', 'Initial moisture readings', 'Baseline moisture readings at all affected locations', true, 'reading', 5, 5),
  ('00000000-0000-0000-0000-000000000101', 'initial_inspection', 'Pre-existing damage documentation', 'Photos of any pre-existing damage or conditions', true, 'photo', 2, 6),
  ('00000000-0000-0000-0000-000000000101', 'initial_inspection', 'Scope of work authorization', 'Customer-signed work authorization form', true, 'signature', 1, 7),
  -- During Work (5 items)
  ('00000000-0000-0000-0000-000000000101', 'during_work', 'Equipment placement photos', 'Photos showing equipment placement per IICRC formulas', true, 'photo', 3, 10),
  ('00000000-0000-0000-0000-000000000101', 'during_work', 'Demolition documentation', 'Photos of materials removed (baseboards, drywall, padding)', true, 'photo', 4, 11),
  ('00000000-0000-0000-0000-000000000101', 'during_work', 'Containment setup photos', 'Photos of containment barriers if Category 2/3', false, 'photo', 2, 12),
  ('00000000-0000-0000-0000-000000000101', 'during_work', 'Anti-microbial application', 'Documentation of anti-microbial treatment applied', false, 'document', 1, 13),
  ('00000000-0000-0000-0000-000000000101', 'during_work', 'Contents move documentation', 'Photos and inventory of moved/packed contents', false, 'photo', 2, 14),
  -- Daily Monitoring (4 items)
  ('00000000-0000-0000-0000-000000000101', 'daily_monitoring', 'Daily moisture readings', 'Moisture readings at all monitoring locations', true, 'reading', 5, 20),
  ('00000000-0000-0000-0000-000000000101', 'daily_monitoring', 'Psychrometric readings', 'Temperature and humidity readings (indoor, outdoor, dehu)', true, 'reading', 3, 21),
  ('00000000-0000-0000-0000-000000000101', 'daily_monitoring', 'Equipment status verification', 'Confirm all equipment operational, document any changes', true, 'form', 1, 22),
  ('00000000-0000-0000-0000-000000000101', 'daily_monitoring', 'Daily drying log photos', 'Progress photos showing drying progress', false, 'photo', 2, 23),
  -- Completion (4 items)
  ('00000000-0000-0000-0000-000000000101', 'completion', 'Final moisture readings', 'All locations at or below drying goal', true, 'reading', 5, 30),
  ('00000000-0000-0000-0000-000000000101', 'completion', 'Completion photos', 'Final condition photos of all affected areas', true, 'photo', 4, 31),
  ('00000000-0000-0000-0000-000000000101', 'completion', 'Equipment removal documentation', 'Photos confirming all equipment removed', true, 'photo', 2, 32),
  ('00000000-0000-0000-0000-000000000101', 'completion', 'Drying verification report', 'IICRC-compliant drying verification summary', true, 'document', 1, 33),
  -- Closeout (2 items)
  ('00000000-0000-0000-0000-000000000101', 'closeout', 'Certificate of Completion', 'Signed COC with scope summary and satisfaction', true, 'signature', 1, 40),
  ('00000000-0000-0000-0000-000000000101', 'closeout', 'Lien waiver', 'Signed conditional or unconditional lien waiver', true, 'signature', 1, 41);

-- ============================================================================
-- FIRE RESTORATION CHECKLIST (18 items)
-- ============================================================================

INSERT INTO doc_checklist_templates (id, company_id, name, description, job_type, is_system_default) VALUES
  ('00000000-0000-0000-0000-000000000102', NULL, 'Fire Restoration Standard', 'Fire and smoke damage documentation per IICRC S520', 'fire_restoration', true);

INSERT INTO doc_checklist_items (template_id, phase, item_name, description, is_required, evidence_type, min_count, sort_order) VALUES
  ('00000000-0000-0000-0000-000000000102', 'initial_inspection', 'Fire origin area documentation', 'Photos of fire origin point and burn patterns', true, 'photo', 4, 1),
  ('00000000-0000-0000-0000-000000000102', 'initial_inspection', 'Smoke damage assessment photos', 'Photos showing smoke damage extent in each room', true, 'photo', 6, 2),
  ('00000000-0000-0000-0000-000000000102', 'initial_inspection', 'Structural damage assessment', 'Photos and notes on structural damage', true, 'photo', 4, 3),
  ('00000000-0000-0000-0000-000000000102', 'initial_inspection', 'Air quality baseline readings', 'Initial air quality and soot measurements', true, 'reading', 3, 4),
  ('00000000-0000-0000-0000-000000000102', 'initial_inspection', 'Contents inventory', 'Room-by-room contents inventory with condition', true, 'document', 1, 5),
  ('00000000-0000-0000-0000-000000000102', 'initial_inspection', 'Scope authorization', 'Customer-signed work authorization', true, 'signature', 1, 6),
  ('00000000-0000-0000-0000-000000000102', 'during_work', 'Demolition and debris removal', 'Photos of demolition process and debris', true, 'photo', 4, 10),
  ('00000000-0000-0000-0000-000000000102', 'during_work', 'Soot and smoke cleaning', 'Photos of cleaning process and chemical use', true, 'photo', 3, 11),
  ('00000000-0000-0000-0000-000000000102', 'during_work', 'Ozone/hydroxyl treatment', 'Documentation of deodorization treatment', false, 'document', 1, 12),
  ('00000000-0000-0000-0000-000000000102', 'during_work', 'Contents packout photos', 'Photos of items being packed and inventoried', false, 'photo', 3, 13),
  ('00000000-0000-0000-0000-000000000102', 'daily_monitoring', 'Air quality monitoring', 'Daily air quality readings during work', true, 'reading', 2, 20),
  ('00000000-0000-0000-0000-000000000102', 'daily_monitoring', 'Progress documentation', 'Daily progress photos showing restoration status', true, 'photo', 3, 21),
  ('00000000-0000-0000-0000-000000000102', 'completion', 'Post-cleaning verification', 'Photos showing restored areas after cleaning', true, 'photo', 6, 30),
  ('00000000-0000-0000-0000-000000000102', 'completion', 'Final air quality readings', 'Confirm air quality within acceptable range', true, 'reading', 3, 31),
  ('00000000-0000-0000-0000-000000000102', 'completion', 'Contents return documentation', 'Photos of contents returned and placed', false, 'photo', 3, 32),
  ('00000000-0000-0000-0000-000000000102', 'completion', 'Odor clearance test', 'Documentation of odor elimination verification', true, 'document', 1, 33),
  ('00000000-0000-0000-0000-000000000102', 'closeout', 'Certificate of Completion', 'Signed COC with full scope summary', true, 'signature', 1, 40),
  ('00000000-0000-0000-0000-000000000102', 'closeout', 'Lien waiver', 'Signed lien waiver', true, 'signature', 1, 41);

-- ============================================================================
-- MOLD REMEDIATION CHECKLIST (20 items)
-- ============================================================================

INSERT INTO doc_checklist_templates (id, company_id, name, description, job_type, is_system_default) VALUES
  ('00000000-0000-0000-0000-000000000103', NULL, 'Mold Remediation Standard', 'Mold remediation documentation per IICRC S520', 'mold_remediation', true);

INSERT INTO doc_checklist_items (template_id, phase, item_name, description, is_required, evidence_type, min_count, sort_order) VALUES
  ('00000000-0000-0000-0000-000000000103', 'initial_inspection', 'Mold assessment report', 'Third-party IEP mold assessment report', true, 'document', 1, 1),
  ('00000000-0000-0000-0000-000000000103', 'initial_inspection', 'Visible mold documentation', 'Photos of all visible mold growth areas', true, 'photo', 6, 2),
  ('00000000-0000-0000-0000-000000000103', 'initial_inspection', 'Moisture source identification', 'Photos and documentation of moisture source', true, 'photo', 3, 3),
  ('00000000-0000-0000-0000-000000000103', 'initial_inspection', 'Pre-remediation air samples', 'Air sample results from IEP', true, 'document', 1, 4),
  ('00000000-0000-0000-0000-000000000103', 'initial_inspection', 'Remediation protocol', 'Written remediation protocol per S520', true, 'document', 1, 5),
  ('00000000-0000-0000-0000-000000000103', 'initial_inspection', 'Scope authorization', 'Customer-signed work authorization', true, 'signature', 1, 6),
  ('00000000-0000-0000-0000-000000000103', 'during_work', 'Containment setup documentation', 'Photos of negative pressure containment', true, 'photo', 4, 10),
  ('00000000-0000-0000-0000-000000000103', 'during_work', 'HEPA filtration setup', 'Photos of air scrubber placement', true, 'photo', 2, 11),
  ('00000000-0000-0000-0000-000000000103', 'during_work', 'Material removal documentation', 'Photos of affected material removal process', true, 'photo', 4, 12),
  ('00000000-0000-0000-0000-000000000103', 'during_work', 'HEPA vacuuming documentation', 'Photos of HEPA vacuum cleaning process', true, 'photo', 2, 13),
  ('00000000-0000-0000-0000-000000000103', 'during_work', 'Anti-microbial treatment', 'Documentation of anti-microbial application', true, 'document', 1, 14),
  ('00000000-0000-0000-0000-000000000103', 'daily_monitoring', 'Containment integrity check', 'Daily verification that containment is intact', true, 'form', 1, 20),
  ('00000000-0000-0000-0000-000000000103', 'daily_monitoring', 'Negative pressure verification', 'Daily manometer readings showing negative pressure', true, 'reading', 1, 21),
  ('00000000-0000-0000-0000-000000000103', 'daily_monitoring', 'Worker PPE compliance', 'Photos showing proper PPE usage', true, 'photo', 1, 22),
  ('00000000-0000-0000-0000-000000000103', 'completion', 'Post-remediation photos', 'Photos of all remediated areas', true, 'photo', 6, 30),
  ('00000000-0000-0000-0000-000000000103', 'completion', 'Post-remediation air samples', 'Third-party post-remediation clearance air samples', true, 'document', 1, 31),
  ('00000000-0000-0000-0000-000000000103', 'completion', 'Clearance letter', 'IEP clearance letter confirming successful remediation', true, 'document', 1, 32),
  ('00000000-0000-0000-0000-000000000103', 'completion', 'Waste disposal manifests', 'Documentation of contaminated material disposal', true, 'document', 1, 33),
  ('00000000-0000-0000-0000-000000000103', 'closeout', 'Certificate of Completion', 'Signed COC with remediation summary', true, 'signature', 1, 40),
  ('00000000-0000-0000-0000-000000000103', 'closeout', 'Lien waiver', 'Signed lien waiver', true, 'signature', 1, 41);

-- ============================================================================
-- ROOFING CLAIM CHECKLIST (16 items)
-- ============================================================================

INSERT INTO doc_checklist_templates (id, company_id, name, description, job_type, is_system_default) VALUES
  ('00000000-0000-0000-0000-000000000104', NULL, 'Roofing Claim Standard', 'Storm/hail/wind roofing claim documentation', 'roofing_claim', true);

INSERT INTO doc_checklist_items (template_id, phase, item_name, description, is_required, evidence_type, min_count, sort_order) VALUES
  ('00000000-0000-0000-0000-000000000104', 'initial_inspection', 'Roof overview photos', 'Wide-angle photos from ground and aerial/ladder', true, 'photo', 4, 1),
  ('00000000-0000-0000-0000-000000000104', 'initial_inspection', 'Damage close-up photos', 'Close-up photos of each damage area with chalk circle', true, 'photo', 8, 2),
  ('00000000-0000-0000-0000-000000000104', 'initial_inspection', 'Interior damage documentation', 'Photos of any interior water damage from roof', true, 'photo', 3, 3),
  ('00000000-0000-0000-0000-000000000104', 'initial_inspection', 'Storm date verification', 'Weather report confirming storm event', true, 'document', 1, 4),
  ('00000000-0000-0000-0000-000000000104', 'initial_inspection', 'Roof measurement diagram', 'Roof measurement with squares calculation', true, 'document', 1, 5),
  ('00000000-0000-0000-0000-000000000104', 'initial_inspection', 'Customer authorization', 'Signed authorization to represent homeowner', true, 'signature', 1, 6),
  ('00000000-0000-0000-0000-000000000104', 'during_work', 'Old roof tear-off photos', 'Photos showing old roofing material removal', true, 'photo', 4, 10),
  ('00000000-0000-0000-0000-000000000104', 'during_work', 'Decking inspection photos', 'Photos of decking condition after tear-off', true, 'photo', 3, 11),
  ('00000000-0000-0000-0000-000000000104', 'during_work', 'Ice and water shield installation', 'Photos of underlayment installation', true, 'photo', 3, 12),
  ('00000000-0000-0000-0000-000000000104', 'during_work', 'Material delivery documentation', 'Photos of materials delivered, matching spec', false, 'photo', 2, 13),
  ('00000000-0000-0000-0000-000000000104', 'completion', 'Completed roof photos', 'Photos of finished roof from all angles', true, 'photo', 6, 30),
  ('00000000-0000-0000-0000-000000000104', 'completion', 'Flashing and detail photos', 'Photos of flashings, vents, pipe boots, ridge cap', true, 'photo', 4, 31),
  ('00000000-0000-0000-0000-000000000104', 'completion', 'Cleanup verification', 'Photos showing property cleanup and magnet sweep', true, 'photo', 2, 32),
  ('00000000-0000-0000-0000-000000000104', 'completion', 'Manufacturer warranty registration', 'Warranty registration documentation', false, 'document', 1, 33),
  ('00000000-0000-0000-0000-000000000104', 'closeout', 'Certificate of Completion', 'Signed COC with scope and materials used', true, 'signature', 1, 40),
  ('00000000-0000-0000-0000-000000000104', 'closeout', 'Lien waiver', 'Signed lien waiver', true, 'signature', 1, 41);

-- ============================================================================
-- IICRC EQUIPMENT CHART FACTORS — Reference data table
-- ============================================================================

CREATE TABLE IF NOT EXISTS iicrc_equipment_factors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_type TEXT NOT NULL CHECK (equipment_type IN ('dehumidifier_lgr', 'dehumidifier_conventional', 'dehumidifier_desiccant', 'air_mover', 'air_scrubber')),
  water_class INTEGER NOT NULL CHECK (water_class BETWEEN 1 AND 4),
  factor_name TEXT NOT NULL,
  factor_value NUMERIC(10,2) NOT NULL,
  unit TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO iicrc_equipment_factors (equipment_type, water_class, factor_name, factor_value, unit, notes) VALUES
  -- LGR Dehumidifier chart factors (cubic ft per unit of PPD capacity)
  ('dehumidifier_lgr', 1, 'chart_factor', 40, 'cf/ppd', 'Class 1: Least water absorption'),
  ('dehumidifier_lgr', 2, 'chart_factor', 40, 'cf/ppd', 'Class 2: Significant absorption'),
  ('dehumidifier_lgr', 3, 'chart_factor', 30, 'cf/ppd', 'Class 3: Most severe — wet ceiling'),
  ('dehumidifier_lgr', 4, 'chart_factor', 25, 'cf/ppd', 'Class 4: Specialty drying (hardwood, plaster)'),
  -- Conventional dehumidifier chart factors
  ('dehumidifier_conventional', 1, 'chart_factor', 50, 'cf/ppd', 'Conventional less efficient than LGR'),
  ('dehumidifier_conventional', 2, 'chart_factor', 50, 'cf/ppd', 'Conventional less efficient than LGR'),
  ('dehumidifier_conventional', 3, 'chart_factor', 40, 'cf/ppd', 'Conventional less efficient than LGR'),
  ('dehumidifier_conventional', 4, 'chart_factor', 30, 'cf/ppd', 'Often desiccant preferred for Class 4'),
  -- Desiccant dehumidifier chart factors
  ('dehumidifier_desiccant', 1, 'chart_factor', 35, 'cf/ppd', 'Desiccant: most aggressive'),
  ('dehumidifier_desiccant', 2, 'chart_factor', 35, 'cf/ppd', 'Desiccant: most aggressive'),
  ('dehumidifier_desiccant', 3, 'chart_factor', 25, 'cf/ppd', 'Desiccant: preferred for Class 3'),
  ('dehumidifier_desiccant', 4, 'chart_factor', 20, 'cf/ppd', 'Desiccant: preferred for Class 4'),
  -- Air mover floor divisors
  ('air_mover', 1, 'floor_divisor', 70, 'sqft/unit', 'Less aggressive for Class 1'),
  ('air_mover', 2, 'floor_divisor', 50, 'sqft/unit', 'Standard placement'),
  ('air_mover', 3, 'floor_divisor', 50, 'sqft/unit', 'Standard placement'),
  ('air_mover', 4, 'floor_divisor', 50, 'sqft/unit', 'Specialty but still aggressive'),
  -- Air mover ceiling divisors
  ('air_mover', 1, 'ceiling_divisor', 150, 'sqft/unit', 'Ceiling not typically affected in Class 1'),
  ('air_mover', 2, 'ceiling_divisor', 150, 'sqft/unit', 'Ceiling not typically affected in Class 2'),
  ('air_mover', 3, 'ceiling_divisor', 100, 'sqft/unit', 'Wet ceiling in Class 3'),
  ('air_mover', 4, 'ceiling_divisor', 100, 'sqft/unit', 'Specialty materials'),
  -- Air mover wall standard (same for all classes)
  ('air_mover', 1, 'wall_divisor', 14, 'lf/unit', '1 air mover per 14 linear feet of wall'),
  ('air_mover', 2, 'wall_divisor', 14, 'lf/unit', '1 air mover per 14 linear feet of wall'),
  ('air_mover', 3, 'wall_divisor', 14, 'lf/unit', '1 air mover per 14 linear feet of wall'),
  ('air_mover', 4, 'wall_divisor', 14, 'lf/unit', '1 air mover per 14 linear feet of wall'),
  -- Air scrubber ACH targets
  ('air_scrubber', 1, 'target_ach', 4, 'ach', 'Lower ACH for Category 1'),
  ('air_scrubber', 2, 'target_ach', 6, 'ach', 'Standard 6 ACH for Category 2'),
  ('air_scrubber', 3, 'target_ach', 6, 'ach', 'Standard 6 ACH for Category 3'),
  ('air_scrubber', 4, 'target_ach', 8, 'ach', 'Higher ACH for specialty');
