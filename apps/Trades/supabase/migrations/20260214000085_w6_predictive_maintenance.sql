-- W6: Predictive Maintenance Foundation
-- Equipment lifecycle data + prediction engine tables

-- ══════════════════════════════════════════════════════════
-- equipment_lifecycle_data — reference data for lifespan/maintenance intervals
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS equipment_lifecycle_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_category TEXT NOT NULL,           -- e.g., 'water_heater', 'ac_condenser', 'furnace'
  manufacturer TEXT,                          -- optional, for manufacturer-specific data
  avg_lifespan_years NUMERIC(5,1) NOT NULL,  -- average lifespan in years
  maintenance_interval_months INT NOT NULL DEFAULT 12,
  common_failure_modes JSONB DEFAULT '[]'::jsonb,  -- [{mode, probability, typical_age_years}]
  seasonal_maintenance TEXT[],                -- e.g., ['spring_check', 'fall_winterize']
  source TEXT,                                -- where data came from
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Public read for lifecycle reference data (no company scoping needed)
ALTER TABLE equipment_lifecycle_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read lifecycle data"
  ON equipment_lifecycle_data FOR SELECT
  USING (true);

CREATE POLICY "Service role can manage lifecycle data"
  ON equipment_lifecycle_data FOR ALL
  USING (auth.role() = 'service_role');

-- ══════════════════════════════════════════════════════════
-- maintenance_predictions — generated predictions per equipment
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS maintenance_predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  equipment_id UUID NOT NULL REFERENCES home_equipment(id),
  customer_id UUID REFERENCES customers(id),
  prediction_type TEXT NOT NULL CHECK (prediction_type IN (
    'maintenance_due', 'end_of_life', 'seasonal_check', 'filter_replacement', 'inspection_recommended'
  )),
  predicted_date DATE NOT NULL,
  confidence_score NUMERIC(3,2) DEFAULT 0.5 CHECK (confidence_score BETWEEN 0 AND 1),
  recommended_action TEXT NOT NULL,
  estimated_cost NUMERIC(10,2),
  outreach_status TEXT DEFAULT 'pending' CHECK (outreach_status IN (
    'pending', 'sent', 'booked', 'declined', 'completed'
  )),
  resulting_job_id UUID REFERENCES jobs(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE maintenance_predictions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company members read own predictions"
  ON maintenance_predictions FOR SELECT
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "Company members insert predictions"
  ON maintenance_predictions FOR INSERT
  WITH CHECK (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "Company members update own predictions"
  ON maintenance_predictions FOR UPDATE
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "Company members delete own predictions"
  ON maintenance_predictions FOR DELETE
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

-- Indexes
CREATE INDEX idx_maintenance_predictions_company ON maintenance_predictions(company_id);
CREATE INDEX idx_maintenance_predictions_equipment ON maintenance_predictions(equipment_id);
CREATE INDEX idx_maintenance_predictions_customer ON maintenance_predictions(customer_id);
CREATE INDEX idx_maintenance_predictions_date ON maintenance_predictions(predicted_date);
CREATE INDEX idx_maintenance_predictions_status ON maintenance_predictions(outreach_status);

-- Updated_at trigger
CREATE TRIGGER update_maintenance_predictions_updated_at
  BEFORE UPDATE ON maintenance_predictions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit trigger
CREATE TRIGGER maintenance_predictions_audit
  AFTER INSERT OR UPDATE OR DELETE ON maintenance_predictions
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ══════════════════════════════════════════════════════════
-- Seed: 50+ equipment lifecycle entries
-- ══════════════════════════════════════════════════════════
INSERT INTO equipment_lifecycle_data (equipment_category, manufacturer, avg_lifespan_years, maintenance_interval_months, common_failure_modes, seasonal_maintenance, source) VALUES
  -- HVAC
  ('ac_condenser', NULL, 15.0, 12, '[{"mode":"compressor_failure","probability":0.15,"typical_age_years":12},{"mode":"refrigerant_leak","probability":0.20,"typical_age_years":8},{"mode":"fan_motor_burnout","probability":0.10,"typical_age_years":10}]', '{"spring_check","fall_winterize"}', 'HVAC industry averages'),
  ('furnace_gas', NULL, 20.0, 12, '[{"mode":"heat_exchanger_crack","probability":0.10,"typical_age_years":15},{"mode":"ignitor_failure","probability":0.25,"typical_age_years":8},{"mode":"blower_motor","probability":0.15,"typical_age_years":12}]', '{"fall_tune_up"}', 'DOE statistics'),
  ('furnace_electric', NULL, 20.0, 12, '[{"mode":"heating_element","probability":0.20,"typical_age_years":10},{"mode":"thermostat_failure","probability":0.10,"typical_age_years":8}]', '{"fall_tune_up"}', 'DOE statistics'),
  ('heat_pump', NULL, 15.0, 6, '[{"mode":"compressor_failure","probability":0.15,"typical_age_years":10},{"mode":"reversing_valve","probability":0.10,"typical_age_years":8},{"mode":"defrost_control","probability":0.10,"typical_age_years":7}]', '{"spring_check","fall_check"}', 'HVAC industry averages'),
  ('mini_split', NULL, 20.0, 6, '[{"mode":"compressor_failure","probability":0.10,"typical_age_years":12},{"mode":"fan_motor","probability":0.10,"typical_age_years":10}]', '{"spring_clean","fall_clean"}', 'Manufacturer data'),
  ('air_handler', NULL, 15.0, 6, '[{"mode":"blower_motor","probability":0.15,"typical_age_years":10},{"mode":"evaporator_coil_leak","probability":0.10,"typical_age_years":12}]', '{"spring_check","fall_check"}', 'HVAC industry averages'),
  ('thermostat', NULL, 10.0, 0, '[{"mode":"sensor_drift","probability":0.10,"typical_age_years":7},{"mode":"display_failure","probability":0.05,"typical_age_years":8}]', NULL, 'General'),

  -- Plumbing
  ('water_heater_tank', NULL, 10.0, 12, '[{"mode":"anode_rod_depletion","probability":0.30,"typical_age_years":5},{"mode":"tank_corrosion","probability":0.20,"typical_age_years":8},{"mode":"thermostat_failure","probability":0.10,"typical_age_years":6}]', NULL, 'DOE statistics'),
  ('water_heater_tankless', NULL, 20.0, 12, '[{"mode":"scale_buildup","probability":0.25,"typical_age_years":5},{"mode":"flow_sensor","probability":0.10,"typical_age_years":8},{"mode":"heat_exchanger","probability":0.10,"typical_age_years":12}]', '{"annual_descale"}', 'Manufacturer data'),
  ('sump_pump', NULL, 10.0, 6, '[{"mode":"float_switch_failure","probability":0.25,"typical_age_years":5},{"mode":"motor_burnout","probability":0.15,"typical_age_years":7},{"mode":"check_valve","probability":0.10,"typical_age_years":4}]', '{"spring_test"}', 'Plumbing industry data'),
  ('garbage_disposal', NULL, 12.0, 0, '[{"mode":"motor_burnout","probability":0.15,"typical_age_years":8},{"mode":"blade_wear","probability":0.10,"typical_age_years":10}]', NULL, 'General'),
  ('water_softener', NULL, 15.0, 3, '[{"mode":"resin_bed_depletion","probability":0.20,"typical_age_years":10},{"mode":"valve_failure","probability":0.10,"typical_age_years":8}]', NULL, 'Manufacturer data'),
  ('sewer_line', NULL, 50.0, 24, '[{"mode":"root_intrusion","probability":0.15,"typical_age_years":25},{"mode":"pipe_collapse","probability":0.10,"typical_age_years":40}]', NULL, 'Plumbing industry data'),

  -- Electrical
  ('electrical_panel', NULL, 40.0, 60, '[{"mode":"breaker_failure","probability":0.10,"typical_age_years":25},{"mode":"bus_bar_corrosion","probability":0.05,"typical_age_years":30}]', NULL, 'NEC guidelines'),
  ('generator_standby', NULL, 25.0, 6, '[{"mode":"battery_failure","probability":0.20,"typical_age_years":3},{"mode":"fuel_system","probability":0.10,"typical_age_years":10},{"mode":"transfer_switch","probability":0.10,"typical_age_years":15}]', '{"spring_test","fall_test"}', 'EGSA guidelines'),
  ('ev_charger', NULL, 10.0, 12, '[{"mode":"connector_wear","probability":0.10,"typical_age_years":5},{"mode":"circuit_board","probability":0.05,"typical_age_years":7}]', NULL, 'Manufacturer data'),
  ('surge_protector_whole_home', NULL, 5.0, 12, '[{"mode":"degradation","probability":0.30,"typical_age_years":3}]', NULL, 'IEEE guidelines'),
  ('smoke_detector', NULL, 10.0, 6, '[{"mode":"sensor_degradation","probability":0.20,"typical_age_years":7}]', '{"spring_test","fall_test"}', 'NFPA guidelines'),
  ('co_detector', NULL, 7.0, 6, '[{"mode":"sensor_degradation","probability":0.25,"typical_age_years":5}]', '{"spring_test","fall_test"}', 'NFPA guidelines'),

  -- Roofing
  ('roof_asphalt_shingle', NULL, 25.0, 12, '[{"mode":"shingle_granule_loss","probability":0.20,"typical_age_years":15},{"mode":"flashing_deterioration","probability":0.15,"typical_age_years":10},{"mode":"ice_dam_damage","probability":0.10,"typical_age_years":8}]', '{"spring_inspection","fall_inspection"}', 'NRCA guidelines'),
  ('roof_metal', NULL, 50.0, 24, '[{"mode":"fastener_corrosion","probability":0.10,"typical_age_years":20},{"mode":"sealant_failure","probability":0.15,"typical_age_years":10}]', '{"spring_inspection"}', 'NRCA guidelines'),
  ('roof_flat_tpo', NULL, 20.0, 12, '[{"mode":"membrane_puncture","probability":0.10,"typical_age_years":10},{"mode":"seam_separation","probability":0.15,"typical_age_years":12}]', '{"spring_inspection","fall_inspection"}', 'NRCA guidelines'),
  ('gutter_system', NULL, 20.0, 6, '[{"mode":"clogging","probability":0.40,"typical_age_years":1},{"mode":"joint_separation","probability":0.10,"typical_age_years":10}]', '{"spring_clean","fall_clean"}', 'General'),

  -- Appliances
  ('refrigerator', NULL, 13.0, 0, '[{"mode":"compressor_failure","probability":0.15,"typical_age_years":10},{"mode":"thermostat","probability":0.10,"typical_age_years":8},{"mode":"ice_maker","probability":0.20,"typical_age_years":5}]', NULL, 'Consumer Reports'),
  ('dishwasher', NULL, 10.0, 0, '[{"mode":"pump_failure","probability":0.15,"typical_age_years":7},{"mode":"door_seal","probability":0.10,"typical_age_years":5}]', NULL, 'Consumer Reports'),
  ('washer', NULL, 11.0, 0, '[{"mode":"pump_failure","probability":0.15,"typical_age_years":7},{"mode":"bearing_failure","probability":0.10,"typical_age_years":8},{"mode":"door_seal","probability":0.10,"typical_age_years":5}]', NULL, 'Consumer Reports'),
  ('dryer', NULL, 13.0, 12, '[{"mode":"heating_element","probability":0.15,"typical_age_years":8},{"mode":"drum_roller","probability":0.10,"typical_age_years":10},{"mode":"lint_buildup","probability":0.30,"typical_age_years":2}]', '{"annual_vent_clean"}', 'Consumer Reports'),
  ('oven_range', NULL, 15.0, 0, '[{"mode":"ignitor","probability":0.15,"typical_age_years":8},{"mode":"heating_element","probability":0.10,"typical_age_years":10}]', NULL, 'Consumer Reports'),
  ('microwave', NULL, 10.0, 0, '[{"mode":"magnetron","probability":0.10,"typical_age_years":7},{"mode":"door_switch","probability":0.10,"typical_age_years":5}]', NULL, 'General'),

  -- Solar/Renewable
  ('solar_panel', NULL, 30.0, 12, '[{"mode":"inverter_failure","probability":0.15,"typical_age_years":10},{"mode":"cell_degradation","probability":0.05,"typical_age_years":20},{"mode":"wiring_degradation","probability":0.05,"typical_age_years":15}]', '{"annual_inspection"}', 'NREL data'),
  ('solar_inverter', NULL, 12.0, 12, '[{"mode":"capacitor_failure","probability":0.20,"typical_age_years":8},{"mode":"fan_failure","probability":0.10,"typical_age_years":6}]', NULL, 'NREL data'),
  ('battery_storage', NULL, 10.0, 12, '[{"mode":"cell_degradation","probability":0.15,"typical_age_years":7},{"mode":"bms_failure","probability":0.05,"typical_age_years":5}]', NULL, 'Manufacturer data'),

  -- Pool/Spa
  ('pool_pump', NULL, 10.0, 3, '[{"mode":"motor_burnout","probability":0.15,"typical_age_years":7},{"mode":"seal_failure","probability":0.20,"typical_age_years":4},{"mode":"impeller_wear","probability":0.10,"typical_age_years":6}]', '{"spring_startup","fall_winterize"}', 'Pool industry data'),
  ('pool_heater', NULL, 8.0, 12, '[{"mode":"heat_exchanger","probability":0.15,"typical_age_years":5},{"mode":"ignitor","probability":0.10,"typical_age_years":4}]', '{"spring_startup"}', 'Pool industry data'),
  ('pool_filter', NULL, 7.0, 3, '[{"mode":"media_degradation","probability":0.20,"typical_age_years":4},{"mode":"valve_failure","probability":0.10,"typical_age_years":5}]', '{"spring_clean","fall_clean"}', 'Pool industry data'),
  ('pool_salt_cell', NULL, 5.0, 3, '[{"mode":"calcium_buildup","probability":0.30,"typical_age_years":2},{"mode":"cell_plate_degradation","probability":0.20,"typical_age_years":3}]', '{"spring_inspect"}', 'Pool industry data'),

  -- Landscaping/Irrigation
  ('irrigation_system', NULL, 15.0, 6, '[{"mode":"valve_failure","probability":0.15,"typical_age_years":8},{"mode":"pipe_leak","probability":0.10,"typical_age_years":10},{"mode":"controller_failure","probability":0.10,"typical_age_years":7}]', '{"spring_startup","fall_winterize"}', 'Irrigation association'),
  ('sprinkler_head', NULL, 10.0, 6, '[{"mode":"clogging","probability":0.20,"typical_age_years":3},{"mode":"seal_wear","probability":0.15,"typical_age_years":5}]', '{"spring_check"}', 'General'),

  -- Fire Protection
  ('fire_sprinkler_system', NULL, 40.0, 12, '[{"mode":"corrosion","probability":0.05,"typical_age_years":20},{"mode":"valve_stuck","probability":0.05,"typical_age_years":15}]', '{"annual_inspection"}', 'NFPA 25'),
  ('fire_alarm_panel', NULL, 15.0, 12, '[{"mode":"battery_failure","probability":0.20,"typical_age_years":3},{"mode":"circuit_board","probability":0.05,"typical_age_years":10}]', '{"annual_inspection"}', 'NFPA 72'),
  ('fire_extinguisher', NULL, 12.0, 12, '[{"mode":"pressure_loss","probability":0.10,"typical_age_years":6}]', '{"annual_inspection"}', 'NFPA 10'),

  -- Windows/Doors
  ('window_double_pane', NULL, 20.0, 0, '[{"mode":"seal_failure","probability":0.15,"typical_age_years":12},{"mode":"hardware_failure","probability":0.10,"typical_age_years":15}]', NULL, 'AAMA guidelines'),
  ('garage_door_opener', NULL, 12.0, 12, '[{"mode":"motor_failure","probability":0.10,"typical_age_years":8},{"mode":"gear_strip","probability":0.15,"typical_age_years":6},{"mode":"sensor_misalign","probability":0.20,"typical_age_years":3}]', '{"annual_lubrication"}', 'IDA guidelines'),

  -- Insulation/Weatherization
  ('insulation_attic', NULL, 40.0, 60, '[{"mode":"settling","probability":0.15,"typical_age_years":15},{"mode":"moisture_damage","probability":0.10,"typical_age_years":10}]', NULL, 'DOE guidelines'),
  ('weatherstripping', NULL, 5.0, 12, '[{"mode":"compression_set","probability":0.30,"typical_age_years":3},{"mode":"cracking","probability":0.20,"typical_age_years":4}]', '{"fall_inspection"}', 'General'),

  -- General/Misc
  ('septic_system', NULL, 25.0, 36, '[{"mode":"drain_field_failure","probability":0.10,"typical_age_years":15},{"mode":"tank_crack","probability":0.05,"typical_age_years":20}]', NULL, 'EPA guidelines'),
  ('well_pump', NULL, 15.0, 12, '[{"mode":"motor_burnout","probability":0.15,"typical_age_years":10},{"mode":"pressure_switch","probability":0.10,"typical_age_years":5}]', NULL, 'NGWA guidelines'),
  ('radon_mitigation', NULL, 25.0, 24, '[{"mode":"fan_failure","probability":0.15,"typical_age_years":8},{"mode":"pipe_seal","probability":0.05,"typical_age_years":12}]', NULL, 'EPA guidelines'),
  ('whole_house_fan', NULL, 15.0, 12, '[{"mode":"motor_failure","probability":0.10,"typical_age_years":10},{"mode":"shutter_malfunction","probability":0.10,"typical_age_years":7}]', '{"spring_check"}', 'General'),
  ('dehumidifier', NULL, 8.0, 6, '[{"mode":"compressor_failure","probability":0.15,"typical_age_years":5},{"mode":"humidity_sensor","probability":0.10,"typical_age_years":4}]', NULL, 'Consumer Reports'),
  ('humidifier_whole_house', NULL, 10.0, 12, '[{"mode":"pad_clogging","probability":0.40,"typical_age_years":1},{"mode":"solenoid_valve","probability":0.10,"typical_age_years":5}]', '{"fall_pad_replace"}', 'General');

-- Index for lifecycle lookups
CREATE INDEX idx_lifecycle_category ON equipment_lifecycle_data(equipment_category);
CREATE INDEX idx_lifecycle_manufacturer ON equipment_lifecycle_data(manufacturer) WHERE manufacturer IS NOT NULL;
