-- ============================================================
-- U14: Universal Trade Support — job types, completion checklists
-- ============================================================

-- ============================================================
-- 1. Trade-specific job types (expand beyond standard/insurance/warranty)
-- ============================================================
-- Add job_type column if not already flexible enough
-- The jobs table already has 'job_type' — let's ensure it accepts all types
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS jobs_job_type_check;
-- No constraint — let it be free-text so companies can customize via company_config

-- ============================================================
-- 2. Completion checklists per trade type
-- ============================================================
CREATE TABLE IF NOT EXISTS completion_checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  trade_type TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{key, label, required, category}]
  is_system BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE completion_checklists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "completion_checklists_select" ON completion_checklists
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "completion_checklists_insert" ON completion_checklists
  FOR INSERT WITH CHECK (company_id = requesting_company_id() AND requesting_user_role() IN ('owner','admin','office_manager'));
CREATE POLICY "completion_checklists_update" ON completion_checklists
  FOR UPDATE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner','admin','office_manager'));
CREATE POLICY "completion_checklists_delete" ON completion_checklists
  FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner','admin'));

CREATE TRIGGER completion_checklists_updated_at
  BEFORE UPDATE ON completion_checklists
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 3. Seed trade-specific completion checklists
-- ============================================================
CREATE OR REPLACE FUNCTION seed_trade_checklists(p_company_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM completion_checklists WHERE company_id = p_company_id LIMIT 1) THEN
    RETURN;
  END IF;

  INSERT INTO completion_checklists (company_id, trade_type, name, description, items, is_system) VALUES
  -- Electrical
  (p_company_id, 'electrical', 'Electrical Job Completion', 'Standard checklist for electrical work', '[
    {"key":"panel_labeled","label":"Panel labeled per NEC","required":true,"category":"code"},
    {"key":"gfci_tested","label":"All GFCI outlets tested","required":true,"category":"safety"},
    {"key":"afci_tested","label":"Arc-fault breakers tested","required":true,"category":"safety"},
    {"key":"permit_posted","label":"Permit posted on site","required":true,"category":"permit"},
    {"key":"inspection_scheduled","label":"Final inspection scheduled","required":true,"category":"permit"},
    {"key":"wire_secured","label":"All wiring properly secured","required":true,"category":"code"},
    {"key":"covers_installed","label":"All outlet/switch covers installed","required":false,"category":"finish"},
    {"key":"debris_cleaned","label":"Work area cleaned","required":true,"category":"cleanup"},
    {"key":"customer_walkthrough","label":"Customer walkthrough completed","required":false,"category":"closeout"},
    {"key":"photos_taken","label":"Completion photos taken","required":true,"category":"documentation"}
  ]'::jsonb, true),

  -- Plumbing
  (p_company_id, 'plumbing', 'Plumbing Job Completion', 'Standard checklist for plumbing work', '[
    {"key":"pressure_test","label":"Pressure test passed","required":true,"category":"testing"},
    {"key":"drain_test","label":"Drain flow test passed","required":true,"category":"testing"},
    {"key":"leak_check","label":"No leaks at all connections","required":true,"category":"testing"},
    {"key":"hot_cold_correct","label":"Hot/cold lines correct","required":true,"category":"verification"},
    {"key":"shutoff_accessible","label":"Shutoff valves accessible","required":true,"category":"code"},
    {"key":"inspection_passed","label":"Inspection passed","required":true,"category":"permit"},
    {"key":"fixtures_secure","label":"All fixtures secured","required":true,"category":"finish"},
    {"key":"cleanup","label":"Work area cleaned","required":true,"category":"cleanup"},
    {"key":"customer_demo","label":"Customer shown shutoff locations","required":false,"category":"closeout"},
    {"key":"photos_taken","label":"Completion photos taken","required":true,"category":"documentation"}
  ]'::jsonb, true),

  -- HVAC
  (p_company_id, 'hvac', 'HVAC Job Completion', 'Standard checklist for HVAC work', '[
    {"key":"system_balanced","label":"System balanced and tested","required":true,"category":"testing"},
    {"key":"filters_installed","label":"Filters installed","required":true,"category":"finish"},
    {"key":"thermostat_programmed","label":"Thermostat programmed","required":true,"category":"finish"},
    {"key":"refrigerant_logged","label":"Refrigerant charge logged","required":true,"category":"documentation"},
    {"key":"airflow_verified","label":"Airflow at all registers verified","required":true,"category":"testing"},
    {"key":"condensate_drain","label":"Condensate drain clear","required":true,"category":"verification"},
    {"key":"electrical_connections","label":"Electrical connections tight","required":true,"category":"safety"},
    {"key":"duct_sealed","label":"All duct connections sealed","required":true,"category":"verification"},
    {"key":"inspection_scheduled","label":"Inspection scheduled","required":true,"category":"permit"},
    {"key":"warranty_registered","label":"Warranty registered","required":false,"category":"closeout"},
    {"key":"customer_trained","label":"Customer trained on thermostat","required":false,"category":"closeout"}
  ]'::jsonb, true),

  -- Roofing
  (p_company_id, 'roofing', 'Roofing Job Completion', 'Standard checklist for roofing work', '[
    {"key":"flashing_sealed","label":"All flashing sealed","required":true,"category":"waterproofing"},
    {"key":"drip_edge","label":"Drip edge installed","required":true,"category":"materials"},
    {"key":"ridge_vent","label":"Ridge vent installed/intact","required":true,"category":"ventilation"},
    {"key":"valleys_sealed","label":"Valleys properly sealed","required":true,"category":"waterproofing"},
    {"key":"boots_sealed","label":"Pipe boots/penetrations sealed","required":true,"category":"waterproofing"},
    {"key":"ice_water_shield","label":"Ice & water shield verified","required":true,"category":"materials"},
    {"key":"nails_flush","label":"All nails flush/sealed","required":true,"category":"finish"},
    {"key":"gutters_clear","label":"Gutters cleaned","required":true,"category":"cleanup"},
    {"key":"ground_cleanup","label":"Ground cleanup complete","required":true,"category":"cleanup"},
    {"key":"magnetic_sweep","label":"Magnetic nail sweep done","required":true,"category":"cleanup"},
    {"key":"inspection_passed","label":"Final inspection passed","required":true,"category":"permit"},
    {"key":"photos_taken","label":"Before/after photos taken","required":true,"category":"documentation"}
  ]'::jsonb, true),

  -- Painting
  (p_company_id, 'painting', 'Painting Job Completion', 'Standard checklist for painting work', '[
    {"key":"primer_verified","label":"Primer coat applied/verified","required":true,"category":"prep"},
    {"key":"coats_applied","label":"All finish coats applied","required":true,"category":"application"},
    {"key":"touchup_complete","label":"Touch-up complete","required":true,"category":"finish"},
    {"key":"masking_removed","label":"All masking/tape removed","required":true,"category":"cleanup"},
    {"key":"drop_cloths_removed","label":"Drop cloths removed","required":true,"category":"cleanup"},
    {"key":"hardware_reinstalled","label":"Hardware reinstalled","required":false,"category":"finish"},
    {"key":"edges_clean","label":"Clean lines at edges/trim","required":true,"category":"quality"},
    {"key":"area_cleaned","label":"Work area cleaned","required":true,"category":"cleanup"},
    {"key":"leftover_paint","label":"Leftover paint labeled for customer","required":false,"category":"closeout"},
    {"key":"color_codes_recorded","label":"Color codes documented","required":true,"category":"documentation"}
  ]'::jsonb, true),

  -- General/Remodel
  (p_company_id, 'general', 'General Completion Checklist', 'Universal completion checklist', '[
    {"key":"scope_complete","label":"All scope items completed","required":true,"category":"verification"},
    {"key":"punch_list_clear","label":"Punch list items resolved","required":true,"category":"quality"},
    {"key":"permits_closed","label":"All permits closed out","required":true,"category":"permit"},
    {"key":"inspections_passed","label":"All inspections passed","required":true,"category":"permit"},
    {"key":"cleanup_complete","label":"Site cleanup complete","required":true,"category":"cleanup"},
    {"key":"debris_hauled","label":"Debris hauled off","required":true,"category":"cleanup"},
    {"key":"customer_walkthrough","label":"Final walkthrough with customer","required":true,"category":"closeout"},
    {"key":"warranty_docs","label":"Warranty documentation provided","required":false,"category":"closeout"},
    {"key":"final_photos","label":"Final photos taken","required":true,"category":"documentation"},
    {"key":"final_invoice","label":"Final invoice sent","required":true,"category":"billing"}
  ]'::jsonb, true),

  -- Concrete
  (p_company_id, 'concrete', 'Concrete Job Completion', 'Standard checklist for concrete work', '[
    {"key":"forms_removed","label":"Forms removed","required":true,"category":"finish"},
    {"key":"finish_applied","label":"Finish applied (broom/stamp/smooth)","required":true,"category":"finish"},
    {"key":"expansion_joints","label":"Expansion joints cut","required":true,"category":"code"},
    {"key":"curing_compound","label":"Curing compound applied","required":true,"category":"materials"},
    {"key":"grade_correct","label":"Grade/slope verified","required":true,"category":"quality"},
    {"key":"rebar_covered","label":"Rebar properly covered","required":true,"category":"code"},
    {"key":"cleanup","label":"Site cleanup complete","required":true,"category":"cleanup"},
    {"key":"cure_instructions","label":"Cure time instructions given to customer","required":true,"category":"closeout"}
  ]'::jsonb, true),

  -- Solar
  (p_company_id, 'solar', 'Solar Installation Completion', 'Standard checklist for solar installations', '[
    {"key":"panels_secured","label":"All panels secured to racking","required":true,"category":"installation"},
    {"key":"wiring_complete","label":"DC/AC wiring complete","required":true,"category":"electrical"},
    {"key":"inverter_mounted","label":"Inverter mounted and connected","required":true,"category":"installation"},
    {"key":"grounding","label":"System properly grounded","required":true,"category":"safety"},
    {"key":"disconnect_installed","label":"AC/DC disconnects installed","required":true,"category":"code"},
    {"key":"monitoring_setup","label":"Monitoring system configured","required":true,"category":"finish"},
    {"key":"utility_interconnect","label":"Utility interconnection approved","required":true,"category":"permit"},
    {"key":"pto_received","label":"Permission to Operate received","required":true,"category":"permit"},
    {"key":"customer_trained","label":"Customer trained on system","required":true,"category":"closeout"},
    {"key":"warranty_registered","label":"Manufacturer warranty registered","required":true,"category":"closeout"}
  ]'::jsonb, true);
END;
$$;

-- Audit trigger
CREATE TRIGGER audit_completion_checklists
  AFTER INSERT OR UPDATE OR DELETE ON completion_checklists
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
