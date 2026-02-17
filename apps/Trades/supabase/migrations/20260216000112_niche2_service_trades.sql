-- NICHE2: Service Trades — Locksmith, Garage Door, Appliance Repair
-- Sprint NICHE2 — Three service-call trades with diagnostic flows

-- ─────────────────────────────────────────────
-- 1. LOCKSMITH SERVICE LOGS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS locksmith_service_logs (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES companies(id),
  job_id          uuid REFERENCES jobs(id),
  property_id     uuid REFERENCES properties(id),

  -- Service details
  service_type    text NOT NULL CHECK (service_type IN (
    'rekey', 'lockout', 'lock_change', 'master_key', 'safe',
    'automotive_lockout', 'transponder_key', 'high_security', 'access_control',
    'key_duplication', 'lock_repair', 'deadbolt_install', 'commercial_lockout'
  )),
  lock_brand      text,
  lock_type       text CHECK (lock_type IN (
    'deadbolt', 'knob', 'lever', 'padlock', 'mortise', 'rim', 'cam',
    'electronic', 'smart', 'automotive', 'cabinet', 'mailbox', 'safe'
  )),
  key_type        text CHECK (key_type IN (
    'standard', 'restricted', 'high_security', 'transponder', 'proximity',
    'smart', 'tubular', 'dimple', 'skeleton', 'magnetic'
  )),

  -- Lock specifics
  pins            int,
  bitting_code    text,
  master_key_system_id text,
  keyway          text,

  -- Automotive
  vin_number      text,
  vehicle_year    int,
  vehicle_make    text,
  vehicle_model   text,

  -- Diagnosis & work
  diagnosis       text,
  work_performed  text,
  parts_used      jsonb DEFAULT '[]'::jsonb,
  photos          jsonb DEFAULT '[]'::jsonb,
  diagnostic_steps jsonb DEFAULT '[]'::jsonb,
  labor_minutes   int,
  parts_cost      numeric(10,2),
  labor_cost      numeric(10,2),
  total_cost      numeric(10,2),

  -- Metadata
  technician_name text,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  deleted_at      timestamptz
);

ALTER TABLE locksmith_service_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "locksmith_select" ON locksmith_service_logs FOR SELECT
  USING (company_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY "locksmith_insert" ON locksmith_service_logs FOR INSERT
  WITH CHECK (company_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY "locksmith_update" ON locksmith_service_logs FOR UPDATE
  USING (company_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY "locksmith_delete" ON locksmith_service_logs FOR DELETE
  USING (company_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid);

CREATE INDEX idx_locksmith_company ON locksmith_service_logs(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_locksmith_job ON locksmith_service_logs(job_id) WHERE deleted_at IS NULL;
CREATE TRIGGER locksmith_updated BEFORE UPDATE ON locksmith_service_logs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER locksmith_audit AFTER INSERT OR UPDATE OR DELETE ON locksmith_service_logs
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ─────────────────────────────────────────────
-- 2. GARAGE DOOR SERVICE LOGS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS garage_door_service_logs (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES companies(id),
  job_id          uuid REFERENCES jobs(id),
  property_id     uuid REFERENCES properties(id),

  -- Door specs
  door_type       text NOT NULL CHECK (door_type IN (
    'sectional', 'roll_up', 'tilt_up', 'slide', 'commercial_rolling_steel',
    'carriage', 'modern_aluminum', 'full_view'
  )),
  door_width_inches  numeric(6,1),
  door_height_inches numeric(6,1),
  panel_material  text CHECK (panel_material IN (
    'steel', 'aluminum', 'wood', 'composite', 'fiberglass', 'vinyl', 'glass'
  )),
  insulation_r_value numeric(4,1),
  track_type      text CHECK (track_type IN (
    'standard_lift', 'low_headroom', 'high_lift', 'vertical_lift', 'follow_roof'
  )),

  -- Opener
  opener_brand    text,
  opener_model    text,
  opener_type     text CHECK (opener_type IN (
    'chain_drive', 'belt_drive', 'screw_drive', 'jackshaft', 'direct_drive', 'none'
  )),
  opener_hp       numeric(3,1),

  -- Springs
  spring_type     text CHECK (spring_type IN (
    'torsion', 'extension', 'torquemaster', 'ez_set', 'wayne_dalton'
  )),
  spring_wire_size    numeric(5,3),
  spring_length       numeric(6,1),
  spring_inside_diameter numeric(5,2),
  spring_cycles_rating int,
  spring_wind_direction text CHECK (spring_wind_direction IN ('left', 'right')),

  -- Service details
  service_type    text NOT NULL CHECK (service_type IN (
    'spring_replacement', 'opener_repair', 'opener_install', 'panel_replacement',
    'cable_repair', 'track_alignment', 'roller_replacement', 'weatherseal',
    'safety_sensor', 'full_door_install', 'balance_adjustment', 'annual_maintenance'
  )),
  symptoms        jsonb DEFAULT '[]'::jsonb,
  safety_sensor_status text CHECK (safety_sensor_status IN ('pass', 'fail', 'not_tested')),
  balance_test_result text CHECK (balance_test_result IN ('pass', 'fail', 'not_tested')),
  force_setting_up   numeric(4,1),
  force_setting_down numeric(4,1),

  -- Diagnosis & work
  diagnosis       text,
  work_performed  text,
  parts_used      jsonb DEFAULT '[]'::jsonb,
  photos          jsonb DEFAULT '[]'::jsonb,
  diagnostic_steps jsonb DEFAULT '[]'::jsonb,
  labor_minutes   int,
  parts_cost      numeric(10,2),
  labor_cost      numeric(10,2),
  total_cost      numeric(10,2),

  -- Metadata
  technician_name text,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  deleted_at      timestamptz
);

ALTER TABLE garage_door_service_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "garage_door_select" ON garage_door_service_logs FOR SELECT
  USING (company_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY "garage_door_insert" ON garage_door_service_logs FOR INSERT
  WITH CHECK (company_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY "garage_door_update" ON garage_door_service_logs FOR UPDATE
  USING (company_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY "garage_door_delete" ON garage_door_service_logs FOR DELETE
  USING (company_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid);

CREATE INDEX idx_garage_door_company ON garage_door_service_logs(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_garage_door_job ON garage_door_service_logs(job_id) WHERE deleted_at IS NULL;
CREATE TRIGGER garage_door_updated BEFORE UPDATE ON garage_door_service_logs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER garage_door_audit AFTER INSERT OR UPDATE OR DELETE ON garage_door_service_logs
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ─────────────────────────────────────────────
-- 3. APPLIANCE SERVICE LOGS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS appliance_service_logs (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES companies(id),
  job_id          uuid REFERENCES jobs(id),
  property_id     uuid REFERENCES properties(id),

  -- Appliance identity
  appliance_type  text NOT NULL CHECK (appliance_type IN (
    'refrigerator', 'washer', 'dryer', 'dishwasher', 'oven', 'range',
    'microwave', 'garbage_disposal', 'ice_maker', 'wine_cooler',
    'trash_compactor', 'range_hood', 'freezer', 'cooktop'
  )),
  brand           text,
  model_number    text,
  serial_number   text,
  manufacture_date text,
  purchase_date   text,
  warranty_status text CHECK (warranty_status IN (
    'in_warranty', 'extended_warranty', 'expired', 'unknown'
  )),

  -- Diagnosis
  error_code      text,
  error_description text,
  symptoms        jsonb DEFAULT '[]'::jsonb,
  diagnostic_steps jsonb DEFAULT '[]'::jsonb,
  diagnosis       text,

  -- Repair work
  work_performed  text,
  parts_used      jsonb DEFAULT '[]'::jsonb,
  repair_vs_replace text CHECK (repair_vs_replace IN (
    'repair', 'replace', 'customer_choice', 'not_economical'
  )),
  estimated_remaining_life_years int,
  estimated_repair_cost  numeric(10,2),
  estimated_replace_cost numeric(10,2),
  photos          jsonb DEFAULT '[]'::jsonb,
  labor_minutes   int,
  parts_cost      numeric(10,2),
  labor_cost      numeric(10,2),
  total_cost      numeric(10,2),

  -- Metadata
  technician_name text,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  deleted_at      timestamptz
);

ALTER TABLE appliance_service_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "appliance_select" ON appliance_service_logs FOR SELECT
  USING (company_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY "appliance_insert" ON appliance_service_logs FOR INSERT
  WITH CHECK (company_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY "appliance_update" ON appliance_service_logs FOR UPDATE
  USING (company_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY "appliance_delete" ON appliance_service_logs FOR DELETE
  USING (company_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid);

CREATE INDEX idx_appliance_company ON appliance_service_logs(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_appliance_job ON appliance_service_logs(job_id) WHERE deleted_at IS NULL;
CREATE TRIGGER appliance_updated BEFORE UPDATE ON appliance_service_logs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER appliance_audit AFTER INSERT OR UPDATE OR DELETE ON appliance_service_logs
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ─────────────────────────────────────────────
-- 4. SEED DATA: Common error codes by brand
-- ─────────────────────────────────────────────

-- Locksmith: common lock pin counts and keyway reference
INSERT INTO line_items (id, company_id, name, description, unit, unit_price, category, trade)
SELECT gen_random_uuid(), '00000000-0000-0000-0000-000000000000', name, description, unit, price, 'locksmith', 'locksmith'
FROM (VALUES
  ('Rekey - Standard Pin Tumbler', 'Rekey single lock cylinder to new key', 'each', 15.00),
  ('Rekey - High Security', 'Rekey high-security cylinder (Medeco, Mul-T-Lock, Abloy)', 'each', 35.00),
  ('Deadbolt Install - Residential', 'Install new deadbolt lock including hardware', 'each', 85.00),
  ('Lockout - Residential', 'Gain entry to locked residential door, non-destructive', 'each', 75.00),
  ('Lockout - Automotive', 'Gain entry to locked vehicle, non-destructive', 'each', 65.00),
  ('Transponder Key - Standard', 'Cut and program standard transponder key', 'each', 120.00),
  ('Transponder Key - Push Start', 'Program push-to-start proximity key fob', 'each', 250.00),
  ('Master Key System Setup', 'Design and implement master key system per lock', 'each', 45.00),
  ('Safe Opening - Electronic', 'Open electronic safe via bypass or manipulation', 'each', 150.00),
  ('Access Control Panel Install', 'Install electronic access control panel + wiring', 'each', 350.00),
  ('Smart Lock Install', 'Install and program smart lock (customer-supplied)', 'each', 95.00),
  ('Commercial Lockout', 'Gain entry to locked commercial space', 'each', 125.00)
) AS t(name, description, unit, price)
ON CONFLICT DO NOTHING;

INSERT INTO line_items (id, company_id, name, description, unit, unit_price, category, trade)
SELECT gen_random_uuid(), '00000000-0000-0000-0000-000000000000', name, description, unit, price, 'garage_door', 'garage_door'
FROM (VALUES
  ('Torsion Spring Replacement - Single', 'Replace single torsion spring, includes winding', 'each', 175.00),
  ('Torsion Spring Replacement - Pair', 'Replace both torsion springs (recommended)', 'pair', 275.00),
  ('Extension Spring Replacement - Pair', 'Replace pair of extension springs with safety cables', 'pair', 185.00),
  ('Opener Install - Chain Drive 1/2 HP', 'Install chain drive opener including rail and hardware', 'each', 250.00),
  ('Opener Install - Belt Drive 3/4 HP', 'Install belt drive opener (quieter operation)', 'each', 350.00),
  ('Cable Replacement - Pair', 'Replace lift cables both sides', 'pair', 135.00),
  ('Roller Replacement - Set of 10', 'Replace all rollers (nylon or steel)', 'set', 95.00),
  ('Panel Replacement - Steel', 'Replace single damaged steel panel section', 'each', 250.00),
  ('Track Alignment', 'Realign and secure garage door tracks', 'each', 85.00),
  ('Safety Sensor Replacement - Pair', 'Replace photo-eye safety sensors', 'pair', 75.00),
  ('Weatherseal - Bottom', 'Replace bottom weatherseal/astragal', 'each', 55.00),
  ('Annual Maintenance Package', 'Lube, adjust, safety test, tighten hardware', 'each', 95.00)
) AS t(name, description, unit, price)
ON CONFLICT DO NOTHING;

INSERT INTO line_items (id, company_id, name, description, unit, unit_price, category, trade)
SELECT gen_random_uuid(), '00000000-0000-0000-0000-000000000000', name, description, unit, price, 'appliance_repair', 'appliance_repair'
FROM (VALUES
  ('Diagnostic Fee', 'On-site diagnosis and testing, applied to repair', 'each', 89.00),
  ('Refrigerator Compressor Replace', 'Replace compressor including refrigerant recharge', 'each', 450.00),
  ('Washer Drum Bearing Replace', 'Replace main bearing and seal kit', 'each', 275.00),
  ('Dryer Heating Element Replace', 'Replace heating element or gas igniter', 'each', 165.00),
  ('Dishwasher Pump Replace', 'Replace wash or drain pump motor', 'each', 195.00),
  ('Oven Igniter Replace', 'Replace hot surface igniter or spark module', 'each', 145.00),
  ('Range Burner Element Replace', 'Replace surface burner element or valve', 'each', 115.00),
  ('Microwave Magnetron Replace', 'Replace magnetron tube (if cost-effective)', 'each', 225.00),
  ('Garbage Disposal Replace', 'Remove old, install new disposal + wiring', 'each', 175.00),
  ('Ice Maker Module Replace', 'Replace ice maker module or water valve', 'each', 155.00),
  ('Control Board Replace', 'Replace main electronic control board', 'each', 325.00),
  ('Water Inlet Valve Replace', 'Replace water inlet valve (washer, dishwasher, fridge)', 'each', 125.00)
) AS t(name, description, unit, price)
ON CONFLICT DO NOTHING;
