-- ============================================================
-- S135-ENTITY: Contractor Operations (ROUTE1 + CHEM1 + DRAW1 + SEL1)
-- Migration 000153
--
-- 4 sprints, ~56h, adoption-blocking for service trades
-- Tables: route_plans, route_stops, route_templates,
--         chemical_applications, chemical_inventory, technician_certifications,
--         draw_schedules, draw_milestones, draw_payments,
--         selection_categories, selection_options, selection_choices
-- ============================================================

-- ============================================================
-- ROUTE1: Route Optimization Engine
-- ============================================================

-- route_templates must be created BEFORE route_plans (FK dependency)
CREATE TABLE IF NOT EXISTS route_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  description TEXT,
  technician_id UUID REFERENCES team_members(id),
  recurrence_type TEXT NOT NULL CHECK (recurrence_type IN ('daily','weekly','biweekly','monthly','custom')),
  recurrence_days INTEGER[] DEFAULT '{}',
  recurrence_week_of_month INTEGER,
  start_address TEXT,
  start_lat NUMERIC(10,7),
  start_lng NUMERIC(10,7),
  end_address TEXT,
  end_lat NUMERIC(10,7),
  end_lng NUMERIC(10,7),
  template_stops JSONB NOT NULL DEFAULT '[]',
  total_stops INTEGER DEFAULT 0,
  estimated_total_minutes INTEGER,
  is_active BOOLEAN DEFAULT true,
  last_generated_date DATE,
  next_generation_date DATE,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_route_templates_company ON route_templates(company_id);
CREATE INDEX idx_route_templates_active ON route_templates(company_id, is_active) WHERE is_active = true;
CREATE INDEX idx_route_templates_tech ON route_templates(technician_id) WHERE technician_id IS NOT NULL;
CREATE INDEX idx_route_templates_next ON route_templates(next_generation_date) WHERE is_active = true;

ALTER TABLE route_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY rt_select ON route_templates FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY rt_insert ON route_templates FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY rt_update ON route_templates FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY rt_delete ON route_templates FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('route_templates');
CREATE TRIGGER rt_audit AFTER INSERT OR UPDATE OR DELETE ON route_templates
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


CREATE TABLE IF NOT EXISTS route_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  technician_id UUID NOT NULL REFERENCES team_members(id),
  route_date DATE NOT NULL,
  route_template_id UUID REFERENCES route_templates(id),
  name TEXT,
  start_address TEXT,
  start_lat NUMERIC(10,7),
  start_lng NUMERIC(10,7),
  end_address TEXT,
  end_lat NUMERIC(10,7),
  end_lng NUMERIC(10,7),
  optimized_order JSONB DEFAULT '[]',
  total_stops INTEGER DEFAULT 0,
  total_distance_miles NUMERIC(8,2),
  total_drive_time_minutes INTEGER,
  total_service_time_minutes INTEGER,
  estimated_start_time TIME,
  estimated_end_time TIME,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','optimized','in_progress','completed','cancelled')),
  optimization_algorithm TEXT DEFAULT 'nearest_neighbor',
  optimization_score NUMERIC(5,2),
  notes TEXT,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_route_plans_company ON route_plans(company_id);
CREATE INDEX idx_route_plans_tech_date ON route_plans(company_id, technician_id, route_date);
CREATE INDEX idx_route_plans_date ON route_plans(company_id, route_date);
CREATE INDEX idx_route_plans_status ON route_plans(company_id, status);

ALTER TABLE route_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY rp2_select ON route_plans FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY rp2_insert ON route_plans FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY rp2_update ON route_plans FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY rp2_delete ON route_plans FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('route_plans');
CREATE TRIGGER rp2_audit AFTER INSERT OR UPDATE OR DELETE ON route_plans
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


CREATE TABLE IF NOT EXISTS route_stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_plan_id UUID NOT NULL REFERENCES route_plans(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),
  customer_id UUID REFERENCES customers(id),
  property_id UUID REFERENCES properties(id),
  stop_order INTEGER NOT NULL,
  address TEXT NOT NULL,
  lat NUMERIC(10,7),
  lng NUMERIC(10,7),
  customer_name TEXT,
  customer_phone TEXT,
  service_type TEXT,
  estimated_service_minutes INTEGER DEFAULT 30,
  scheduled_arrival TIMESTAMPTZ,
  scheduled_departure TIMESTAMPTZ,
  actual_arrival TIMESTAMPTZ,
  actual_departure TIMESTAMPTZ,
  drive_time_from_prev_minutes INTEGER,
  distance_from_prev_miles NUMERIC(8,2),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','en_route','arrived','in_progress','completed','skipped','rescheduled')),
  skip_reason TEXT,
  check_in_lat NUMERIC(10,7),
  check_in_lng NUMERIC(10,7),
  check_out_lat NUMERIC(10,7),
  check_out_lng NUMERIC(10,7),
  notes TEXT,
  customer_notes TEXT,
  access_instructions TEXT,
  priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
  time_window_start TIME,
  time_window_end TIME,
  photos JSONB DEFAULT '[]',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_route_stops_plan ON route_stops(route_plan_id);
CREATE INDEX idx_route_stops_company ON route_stops(company_id);
CREATE INDEX idx_route_stops_job ON route_stops(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX idx_route_stops_order ON route_stops(route_plan_id, stop_order);

ALTER TABLE route_stops ENABLE ROW LEVEL SECURITY;
CREATE POLICY rs_select ON route_stops FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY rs_insert ON route_stops FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY rs_update ON route_stops FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY rs_delete ON route_stops FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('route_stops');
CREATE TRIGGER rs_audit AFTER INSERT OR UPDATE OR DELETE ON route_stops
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- CHEM1: Chemical & Regulatory Compliance Tracking
-- ============================================================

CREATE TABLE IF NOT EXISTS chemical_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),
  property_id UUID REFERENCES properties(id),
  customer_id UUID REFERENCES customers(id),
  technician_id UUID NOT NULL REFERENCES team_members(id),
  chemical_name TEXT NOT NULL,
  epa_registration_number TEXT,
  active_ingredient TEXT,
  manufacturer TEXT,
  application_method TEXT CHECK (application_method IN ('spray','bait','dust','fog','granule','injection','pour','wipe','other')),
  quantity_used NUMERIC(10,3) NOT NULL,
  quantity_unit TEXT NOT NULL CHECK (quantity_unit IN ('oz','fl_oz','lbs','gal','ml','liters','kg','grams','each')),
  target_pest_or_purpose TEXT,
  application_area_sqft NUMERIC(10,2),
  application_area_description TEXT,
  wind_speed_mph NUMERIC(5,1),
  temperature_f NUMERIC(5,1),
  humidity_pct NUMERIC(5,1),
  weather_conditions TEXT,
  reentry_interval_hours NUMERIC(6,1),
  signal_word TEXT CHECK (signal_word IN ('DANGER','WARNING','CAUTION','none')),
  ppe_required JSONB DEFAULT '[]',
  mix_ratio TEXT,
  dilution_rate TEXT,
  restricted_use_product BOOLEAN DEFAULT false,
  applicator_cert_number TEXT,
  applicator_cert_state TEXT,
  notes TEXT,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  photo_paths JSONB DEFAULT '[]',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_chem_apps_company ON chemical_applications(company_id);
CREATE INDEX idx_chem_apps_job ON chemical_applications(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX idx_chem_apps_tech ON chemical_applications(technician_id);
CREATE INDEX idx_chem_apps_date ON chemical_applications(company_id, applied_at DESC);

ALTER TABLE chemical_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY ca_select ON chemical_applications FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY ca_insert ON chemical_applications FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY ca_update ON chemical_applications FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY ca_delete ON chemical_applications FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('chemical_applications');
CREATE TRIGGER ca_audit AFTER INSERT OR UPDATE OR DELETE ON chemical_applications
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


CREATE TABLE IF NOT EXISTS chemical_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  chemical_name TEXT NOT NULL,
  epa_registration_number TEXT,
  active_ingredient TEXT,
  manufacturer TEXT,
  product_type TEXT CHECK (product_type IN ('pesticide','herbicide','fungicide','rodenticide','insecticide','antimicrobial','refrigerant','foam_chemical','cleaning_agent','other')),
  quantity_on_hand NUMERIC(10,3) NOT NULL DEFAULT 0,
  quantity_unit TEXT NOT NULL,
  storage_location TEXT,
  sds_document_path TEXT,
  purchase_date DATE,
  expiration_date DATE,
  lot_number TEXT,
  cost_per_unit NUMERIC(10,2),
  reorder_threshold NUMERIC(10,3),
  restricted_use BOOLEAN DEFAULT false,
  signal_word TEXT CHECK (signal_word IN ('DANGER','WARNING','CAUTION','none')),
  ppe_required JSONB DEFAULT '[]',
  storage_requirements TEXT,
  disposal_instructions TEXT,
  notes TEXT,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_chem_inv_company ON chemical_inventory(company_id);
CREATE INDEX idx_chem_inv_name ON chemical_inventory(company_id, chemical_name);
CREATE INDEX idx_chem_inv_expiry ON chemical_inventory(expiration_date) WHERE expiration_date IS NOT NULL;

ALTER TABLE chemical_inventory ENABLE ROW LEVEL SECURITY;
CREATE POLICY ci_select ON chemical_inventory FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY ci_insert ON chemical_inventory FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY ci_update ON chemical_inventory FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY ci_delete ON chemical_inventory FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('chemical_inventory');
CREATE TRIGGER ci_audit AFTER INSERT OR UPDATE OR DELETE ON chemical_inventory
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


CREATE TABLE IF NOT EXISTS technician_certifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  team_member_id UUID NOT NULL REFERENCES team_members(id),
  certification_type TEXT NOT NULL,
  certification_number TEXT NOT NULL,
  issuing_authority TEXT NOT NULL,
  state TEXT,
  issue_date DATE,
  expiration_date DATE,
  is_expired BOOLEAN GENERATED ALWAYS AS (
    CASE WHEN expiration_date IS NULL THEN false
         WHEN expiration_date < CURRENT_DATE THEN true
         ELSE false END
  ) STORED,
  renewal_reminder_days INTEGER DEFAULT 60,
  document_path TEXT,
  verification_url TEXT,
  notes TEXT,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_tech_certs_company ON technician_certifications(company_id);
CREATE INDEX idx_tech_certs_member ON technician_certifications(team_member_id);
CREATE INDEX idx_tech_certs_expiry ON technician_certifications(expiration_date) WHERE expiration_date IS NOT NULL AND deleted_at IS NULL;

ALTER TABLE technician_certifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY tc_select ON technician_certifications FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY tc_insert ON technician_certifications FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY tc_update ON technician_certifications FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY tc_delete ON technician_certifications FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('technician_certifications');
CREATE TRIGGER tc2_audit AFTER INSERT OR UPDATE OR DELETE ON technician_certifications
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- DRAW1: Draw Schedule & Milestone Payment Management
-- ============================================================

CREATE TABLE IF NOT EXISTS draw_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  customer_id UUID REFERENCES customers(id),
  estimate_id UUID REFERENCES estimates(id),
  name TEXT NOT NULL DEFAULT 'Draw Schedule',
  total_contract_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_drawn NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_remaining NUMERIC(12,2) GENERATED ALWAYS AS (total_contract_amount - total_drawn) STORED,
  retention_pct NUMERIC(5,2) DEFAULT 0,
  retention_amount NUMERIC(12,2) DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','paused','completed','cancelled')),
  notes TEXT,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_draw_schedules_company ON draw_schedules(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_draw_schedules_job ON draw_schedules(job_id) WHERE deleted_at IS NULL;

ALTER TABLE draw_schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY ds_select ON draw_schedules FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY ds_insert ON draw_schedules FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY ds_update ON draw_schedules FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY ds_delete ON draw_schedules FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('draw_schedules');
CREATE TRIGGER ds_audit AFTER INSERT OR UPDATE OR DELETE ON draw_schedules
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


CREATE TABLE IF NOT EXISTS draw_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  draw_schedule_id UUID NOT NULL REFERENCES draw_schedules(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id),
  milestone_number INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  percentage_of_total NUMERIC(5,2),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','in_progress','ready_for_draw','submitted','approved','paid','disputed')),
  completion_criteria TEXT,
  completion_photos JSONB DEFAULT '[]',
  completed_at TIMESTAMPTZ,
  completed_by UUID REFERENCES auth.users(id),
  -- Draw request
  draw_requested_at TIMESTAMPTZ,
  draw_requested_by UUID REFERENCES auth.users(id),
  draw_approved_at TIMESTAMPTZ,
  draw_approved_by UUID REFERENCES auth.users(id),
  draw_paid_at TIMESTAMPTZ,
  draw_payment_method TEXT,
  draw_payment_reference TEXT,
  -- Inspection (if required)
  inspection_required BOOLEAN DEFAULT false,
  inspection_passed BOOLEAN,
  inspection_date DATE,
  inspection_notes TEXT,
  -- Lien waiver
  lien_waiver_required BOOLEAN DEFAULT false,
  lien_waiver_signed BOOLEAN DEFAULT false,
  lien_waiver_document_path TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_draw_milestones_schedule ON draw_milestones(draw_schedule_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_draw_milestones_company ON draw_milestones(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_draw_milestones_status ON draw_milestones(status) WHERE deleted_at IS NULL;

ALTER TABLE draw_milestones ENABLE ROW LEVEL SECURITY;
CREATE POLICY dm_select ON draw_milestones FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY dm_insert ON draw_milestones FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY dm_update ON draw_milestones FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY dm_delete ON draw_milestones FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('draw_milestones');
CREATE TRIGGER dm_audit AFTER INSERT OR UPDATE OR DELETE ON draw_milestones
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- SEL1: Client Selections Management Portal
-- ============================================================

CREATE TABLE IF NOT EXISTS selection_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),  -- NULL = system default
  name TEXT NOT NULL,
  description TEXT,
  trade TEXT,
  icon TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_selcat_company ON selection_categories(company_id) WHERE deleted_at IS NULL;

ALTER TABLE selection_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY sc_select ON selection_categories FOR SELECT TO authenticated
  USING ((company_id IS NULL OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid) AND deleted_at IS NULL);
CREATE POLICY sc_insert ON selection_categories FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY sc_update ON selection_categories FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

SELECT update_updated_at('selection_categories');


CREATE TABLE IF NOT EXISTS selection_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  category_id UUID NOT NULL REFERENCES selection_categories(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id),
  name TEXT NOT NULL,
  description TEXT,
  tier TEXT DEFAULT 'standard' CHECK (tier IN ('economy','standard','premium','luxury')),
  -- Pricing from estimate_pricing / material_catalog — NOT hardcoded
  material_catalog_id UUID REFERENCES material_catalog(id),
  unit_cost NUMERIC(10,2) NOT NULL DEFAULT 0,
  upgrade_cost NUMERIC(10,2) DEFAULT 0,  -- additional cost vs base allowance
  photo_urls JSONB DEFAULT '[]',
  spec_sheet_url TEXT,
  supplier TEXT,
  lead_time_days INTEGER,
  is_default BOOLEAN NOT NULL DEFAULT false,
  is_available BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_selopt_company ON selection_options(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_selopt_category ON selection_options(category_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_selopt_job ON selection_options(job_id) WHERE job_id IS NOT NULL AND deleted_at IS NULL;

ALTER TABLE selection_options ENABLE ROW LEVEL SECURITY;
CREATE POLICY so_select ON selection_options FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY so_insert ON selection_options FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY so_update ON selection_options FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY so_delete ON selection_options FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('selection_options');
CREATE TRIGGER so_audit AFTER INSERT OR UPDATE OR DELETE ON selection_options
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


CREATE TABLE IF NOT EXISTS selection_choices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  customer_id UUID REFERENCES customers(id),
  category_id UUID NOT NULL REFERENCES selection_categories(id),
  selected_option_id UUID NOT NULL REFERENCES selection_options(id),
  -- Decision
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','selected','approved','ordered','received','installed','changed')),
  selected_by UUID REFERENCES auth.users(id),
  selected_at TIMESTAMPTZ,
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  -- Cost impact
  base_allowance NUMERIC(10,2) DEFAULT 0,
  selected_cost NUMERIC(10,2) DEFAULT 0,
  upgrade_delta NUMERIC(10,2) GENERATED ALWAYS AS (selected_cost - base_allowance) STORED,
  -- Notes
  customer_notes TEXT,
  contractor_notes TEXT,
  -- Change tracking
  previous_option_id UUID REFERENCES selection_options(id),
  change_reason TEXT,
  -- Deadline
  due_date DATE,
  is_overdue BOOLEAN GENERATED ALWAYS AS (
    CASE WHEN due_date IS NULL THEN false
         WHEN due_date < CURRENT_DATE AND status = 'pending' THEN true
         ELSE false END
  ) STORED,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_selch_company ON selection_choices(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_selch_job ON selection_choices(job_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_selch_customer ON selection_choices(customer_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_selch_status ON selection_choices(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_selch_overdue ON selection_choices(due_date) WHERE status = 'pending' AND deleted_at IS NULL;

ALTER TABLE selection_choices ENABLE ROW LEVEL SECURITY;
CREATE POLICY sch_select ON selection_choices FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY sch_insert ON selection_choices FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY sch_update ON selection_choices FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY sch_delete ON selection_choices FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('selection_choices');
CREATE TRIGGER sch_audit AFTER INSERT OR UPDATE OR DELETE ON selection_choices
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- SEED: Default selection categories (system-wide)
-- ============================================================

INSERT INTO selection_categories (company_id, name, description, trade, sort_order) VALUES
  (NULL, 'Flooring', 'Floor material selections (hardwood, tile, carpet, vinyl, laminate)', 'flooring', 1),
  (NULL, 'Countertops', 'Kitchen and bathroom countertop materials', 'remodeling', 2),
  (NULL, 'Cabinets', 'Kitchen and bathroom cabinet styles and finishes', 'remodeling', 3),
  (NULL, 'Lighting Fixtures', 'Interior and exterior lighting selections', 'electrical', 4),
  (NULL, 'Plumbing Fixtures', 'Faucets, showers, tubs, toilets', 'plumbing', 5),
  (NULL, 'Paint Colors', 'Interior and exterior paint color selections', 'painting', 6),
  (NULL, 'Tile', 'Backsplash, shower, and floor tile selections', 'tile', 7),
  (NULL, 'Hardware', 'Door handles, cabinet pulls, hinges', 'remodeling', 8),
  (NULL, 'Appliances', 'Kitchen and laundry appliance selections', 'remodeling', 9),
  (NULL, 'HVAC Equipment', 'Heating and cooling system selections', 'hvac', 10),
  (NULL, 'Roofing Materials', 'Shingle, metal, tile, flat roof material selections', 'roofing', 11),
  (NULL, 'Windows & Doors', 'Window and exterior door selections', 'remodeling', 12),
  (NULL, 'Siding & Exterior', 'Exterior cladding material selections', 'siding', 13),
  (NULL, 'Decking', 'Deck and patio material selections', 'carpentry', 14)
ON CONFLICT DO NOTHING;
