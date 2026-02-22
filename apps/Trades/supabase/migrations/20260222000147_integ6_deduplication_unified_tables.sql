-- INTEG6: Deduplication Fixes — Unified Table Sets
-- (1) RE26/CLIENT3 maintenance engine unification
-- (2) FLIP2/RE3 comp analysis unification
-- (3) Storm/weather data single pipeline
-- All future sprints reference these shared tables instead of creating duplicates.

-- ============================================================================
-- PART 1: Unified Home Maintenance Tables (RE26 + CLIENT3)
-- RE26 = realtor-facing (portfolio of clients' homes)
-- CLIENT3 = homeowner-facing (my home)
-- Same backend, role-based frontend.
-- ============================================================================

-- Climate zones for maintenance task scheduling
CREATE TYPE public.climate_zone_type AS ENUM (
  'HOT_HUMID', 'HOT_DRY', 'MIXED_HUMID', 'MIXED_DRY',
  'COLD', 'VERY_COLD', 'SUBARCTIC', 'MARINE', 'TROPICAL'
);

-- Unified maintenance tasks — shared by realtor and homeowner views
CREATE TABLE IF NOT EXISTS public.home_maintenance_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Property linkage (shared across entity types)
  property_id uuid, -- Links to properties table (nullable for template tasks)
  -- Company scoping
  company_id uuid NOT NULL REFERENCES public.companies(id),
  -- Task details
  title text NOT NULL,
  description text,
  category varchar(50) NOT NULL, -- HVAC, Plumbing, Electrical, Roofing, Exterior, Interior, Landscaping, Safety, Seasonal, Appliance
  subcategory varchar(50), -- e.g. 'Filter Change', 'Gutter Clean', 'Smoke Detector'
  -- Scheduling
  frequency varchar(30) NOT NULL DEFAULT 'annually', -- monthly, quarterly, semi_annually, annually, biennial, as_needed, one_time
  season varchar(20), -- spring, summer, fall, winter, any
  climate_zones public.climate_zone_type[], -- Which climate zones this task applies to
  -- Equipment linkage
  equipment_id uuid, -- Links to client_equipment_items if equipment-specific
  equipment_type varchar(100), -- 'HVAC', 'Water Heater', 'Roof' etc. for template matching
  -- Task type
  is_diy boolean NOT NULL DEFAULT true, -- Can homeowner do this themselves?
  estimated_cost_min int DEFAULT 0, -- Min cost in cents (from DB, not hardcoded)
  estimated_cost_max int DEFAULT 0, -- Max cost in cents
  estimated_duration_minutes int DEFAULT 30,
  difficulty varchar(20) DEFAULT 'easy', -- easy, moderate, hard, professional_only
  -- Status
  is_template boolean NOT NULL DEFAULT false, -- System template vs user-created
  is_active boolean NOT NULL DEFAULT true,
  -- Source tracking
  source varchar(50) DEFAULT 'system', -- system, user, realtor, hud_eul, weather_triggered
  source_reference text, -- HUD EUL table reference, weather alert ID, etc.
  -- Priority
  priority varchar(20) DEFAULT 'normal', -- low, normal, high, critical
  -- Audit
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Maintenance completions — log of when tasks were completed
CREATE TABLE IF NOT EXISTS public.home_maintenance_completions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES public.home_maintenance_tasks(id),
  property_id uuid NOT NULL,
  company_id uuid NOT NULL REFERENCES public.companies(id),
  -- Completion details
  completed_at timestamptz NOT NULL DEFAULT now(),
  completed_by uuid REFERENCES auth.users(id),
  completed_by_type varchar(20) NOT NULL DEFAULT 'homeowner', -- homeowner, contractor, realtor
  -- Cost tracking
  actual_cost_cents int DEFAULT 0,
  -- Notes and evidence
  notes text,
  photo_urls text[], -- Evidence photos
  receipt_url text, -- Receipt/invoice
  -- Contractor linkage (if professional)
  contractor_company_id uuid, -- The contractor company that did the work
  job_id uuid, -- Links to jobs table if dispatched via Zafto
  -- Quality
  satisfaction_rating int CHECK (satisfaction_rating BETWEEN 1 AND 5),
  -- Audit
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Maintenance reminders — scheduled notifications
CREATE TABLE IF NOT EXISTS public.home_maintenance_reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES public.home_maintenance_tasks(id),
  property_id uuid NOT NULL,
  company_id uuid NOT NULL REFERENCES public.companies(id),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  -- Scheduling
  remind_at timestamptz NOT NULL,
  reminder_type varchar(20) NOT NULL DEFAULT 'push', -- push, email, sms, in_app
  -- Status
  status varchar(20) NOT NULL DEFAULT 'pending', -- pending, sent, dismissed, completed
  sent_at timestamptz,
  -- Audit
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Home system profiles — equipment/systems in a home (shared between RE26 and CLIENT3)
CREATE TABLE IF NOT EXISTS public.home_system_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL,
  company_id uuid NOT NULL REFERENCES public.companies(id),
  -- System details
  system_type varchar(50) NOT NULL, -- HVAC, Water_Heater, Roof, Electrical_Panel, Plumbing, Appliance, etc.
  system_name text NOT NULL, -- 'Central A/C', 'Tankless Water Heater', etc.
  manufacturer varchar(100),
  model_number varchar(100),
  serial_number varchar(100),
  -- Age and lifecycle
  install_date date,
  manufacture_year int,
  expected_lifespan_years int, -- From HUD EUL data
  warranty_expiration date,
  -- Current state
  condition varchar(20) DEFAULT 'good', -- excellent, good, fair, poor, critical, replaced
  last_service_date date,
  next_service_date date,
  -- Cost tracking
  replacement_cost_cents int DEFAULT 0, -- From pricing DB
  annual_maintenance_cost_cents int DEFAULT 0,
  -- Notes
  notes text,
  photo_url text,
  -- Audit
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Indexes
CREATE INDEX idx_maintenance_tasks_property ON public.home_maintenance_tasks(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_maintenance_tasks_company ON public.home_maintenance_tasks(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_maintenance_tasks_template ON public.home_maintenance_tasks(is_template) WHERE is_template = true AND deleted_at IS NULL;
CREATE INDEX idx_maintenance_tasks_category ON public.home_maintenance_tasks(category) WHERE deleted_at IS NULL;
CREATE INDEX idx_maintenance_tasks_climate ON public.home_maintenance_tasks USING gin(climate_zones) WHERE deleted_at IS NULL;

CREATE INDEX idx_maintenance_completions_task ON public.home_maintenance_completions(task_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_maintenance_completions_property ON public.home_maintenance_completions(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_maintenance_completions_company ON public.home_maintenance_completions(company_id) WHERE deleted_at IS NULL;

CREATE INDEX idx_maintenance_reminders_user ON public.home_maintenance_reminders(user_id, remind_at) WHERE deleted_at IS NULL AND status = 'pending';
CREATE INDEX idx_maintenance_reminders_company ON public.home_maintenance_reminders(company_id) WHERE deleted_at IS NULL;

CREATE INDEX idx_home_systems_property ON public.home_system_profiles(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_home_systems_company ON public.home_system_profiles(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_home_systems_warranty ON public.home_system_profiles(warranty_expiration) WHERE deleted_at IS NULL AND warranty_expiration IS NOT NULL;

-- RLS
ALTER TABLE public.home_maintenance_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.home_maintenance_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.home_maintenance_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.home_system_profiles ENABLE ROW LEVEL SECURITY;

-- RLS policies: company_id scoping
CREATE POLICY maint_tasks_select ON public.home_maintenance_tasks
  FOR SELECT USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    OR is_template = true
  );
CREATE POLICY maint_tasks_insert ON public.home_maintenance_tasks
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY maint_tasks_update ON public.home_maintenance_tasks
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY maint_tasks_delete ON public.home_maintenance_tasks
  FOR DELETE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY maint_completions_select ON public.home_maintenance_completions
  FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY maint_completions_insert ON public.home_maintenance_completions
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY maint_completions_update ON public.home_maintenance_completions
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY maint_reminders_select ON public.home_maintenance_reminders
  FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY maint_reminders_insert ON public.home_maintenance_reminders
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY maint_reminders_update ON public.home_maintenance_reminders
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY home_systems_select ON public.home_system_profiles
  FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY home_systems_insert ON public.home_system_profiles
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY home_systems_update ON public.home_system_profiles
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Audit triggers
CREATE TRIGGER home_maintenance_tasks_updated BEFORE UPDATE ON public.home_maintenance_tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER home_maintenance_completions_updated BEFORE UPDATE ON public.home_maintenance_completions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER home_maintenance_reminders_updated BEFORE UPDATE ON public.home_maintenance_reminders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER home_system_profiles_updated BEFORE UPDATE ON public.home_system_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- PART 2: Unified Comp Analysis Tables (FLIP2 + RE3)
-- FLIP2 = flip ARV calculator (flip-specific fields: rehab cost, ARV formula)
-- RE3 = realtor CMA engine (realtor-specific fields: listing price guidance, seller CMA format)
-- Same comp engine, different presentation layers.
-- ============================================================================

-- Comparable sales — shared comp data
CREATE TABLE IF NOT EXISTS public.comparable_sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id),
  -- Subject property linkage
  subject_property_id uuid, -- Links to properties table
  subject_address text NOT NULL,
  subject_lat decimal(10,7),
  subject_lng decimal(10,7),
  subject_sqft int,
  subject_beds int,
  subject_baths decimal(3,1),
  subject_year_built int,
  subject_lot_sqft int,
  subject_property_type varchar(30), -- single_family, condo, townhouse, multi_family
  -- Comp property
  comp_address text NOT NULL,
  comp_lat decimal(10,7),
  comp_lng decimal(10,7),
  comp_sale_price int NOT NULL, -- In cents
  comp_sale_date date NOT NULL,
  comp_sqft int,
  comp_beds int,
  comp_baths decimal(3,1),
  comp_year_built int,
  comp_lot_sqft int,
  comp_property_type varchar(30),
  comp_condition varchar(20), -- excellent, good, fair, poor, distressed
  comp_has_garage boolean DEFAULT false,
  comp_has_pool boolean DEFAULT false,
  comp_stories int DEFAULT 1,
  -- Source
  data_source varchar(50) NOT NULL, -- redfin_csv, county_recorder, zillow_research, manual
  source_url text,
  -- Similarity scoring
  distance_miles decimal(5,2),
  similarity_score decimal(5,2), -- 0-100, computed
  -- Status
  is_selected boolean NOT NULL DEFAULT false, -- User selected this comp for the analysis
  selection_rank int, -- 1, 2, 3... order in the report
  -- Audit
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Comp adjustments — appraiser-style line-item adjustments per comp
CREATE TABLE IF NOT EXISTS public.comp_adjustments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  comp_id uuid NOT NULL REFERENCES public.comparable_sales(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id),
  -- Adjustment details
  adjustment_type varchar(50) NOT NULL, -- sqft, bedrooms, bathrooms, garage, pool, lot_size, condition, location, age, view, basement, custom
  adjustment_label text NOT NULL, -- Display label: 'Square Footage (+200 sqft)'
  adjustment_amount_cents int NOT NULL, -- Positive = comp worth more, Negative = comp worth less
  -- Calculation basis
  unit_value_cents int, -- e.g. $50/sqft
  unit_difference decimal(10,2), -- e.g. +200 sqft
  -- Source
  adjustment_source varchar(30) DEFAULT 'manual', -- manual, auto_calculated, ai_suggested
  -- Audit
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- CMA/ARV reports — the analysis output
CREATE TABLE IF NOT EXISTS public.comp_analysis_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id),
  -- Subject property
  subject_property_id uuid,
  subject_address text NOT NULL,
  -- Report type
  report_type varchar(20) NOT NULL, -- cma (realtor), arv (flipper), appraisal_review
  -- Valuation results
  adjusted_median_value_cents int, -- Method 1: adjusted comp median
  price_per_sqft_value_cents int, -- Method 2: $/sqft method
  avm_value_cents int, -- Method 3: AVM cross-reference
  final_value_cents int, -- Weighted blend
  confidence varchar(10), -- high, medium, low
  confidence_score int CHECK (confidence_score BETWEEN 0 AND 100),
  -- Flip-specific fields (FLIP2)
  rehab_cost_cents int, -- Total estimated rehab from estimation engine
  arv_minus_rehab_cents int, -- ARV - rehab = max acquisition price
  target_profit_pct decimal(5,2), -- e.g. 15%
  max_purchase_price_cents int, -- ARV × (1 - profit%) - rehab - holding - closing
  -- Realtor-specific fields (RE3)
  suggested_list_price_cents int,
  price_range_low_cents int,
  price_range_high_cents int,
  days_on_market_estimate int,
  -- Report sharing
  share_url text, -- Public shareable link
  share_token varchar(64), -- Auth token for share link
  view_count int DEFAULT 0,
  -- Versioning
  version int NOT NULL DEFAULT 1,
  parent_report_id uuid REFERENCES public.comp_analysis_reports(id),
  -- Status
  status varchar(20) NOT NULL DEFAULT 'draft', -- draft, final, shared, archived
  -- Audit
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Report-to-comp linkage
CREATE TABLE IF NOT EXISTS public.comp_analysis_report_comps (
  report_id uuid NOT NULL REFERENCES public.comp_analysis_reports(id) ON DELETE CASCADE,
  comp_id uuid NOT NULL REFERENCES public.comparable_sales(id),
  selection_rank int NOT NULL DEFAULT 1,
  PRIMARY KEY (report_id, comp_id)
);

-- Indexes
CREATE INDEX idx_comps_company ON public.comparable_sales(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_comps_subject ON public.comparable_sales(subject_property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_comps_sale_date ON public.comparable_sales(comp_sale_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_comps_selected ON public.comparable_sales(is_selected) WHERE is_selected = true AND deleted_at IS NULL;
CREATE INDEX idx_comps_location ON public.comparable_sales(comp_lat, comp_lng) WHERE deleted_at IS NULL;

CREATE INDEX idx_comp_adj_comp ON public.comp_adjustments(comp_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_comp_adj_company ON public.comp_adjustments(company_id) WHERE deleted_at IS NULL;

CREATE INDEX idx_comp_reports_company ON public.comp_analysis_reports(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_comp_reports_type ON public.comp_analysis_reports(report_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_comp_reports_share ON public.comp_analysis_reports(share_token) WHERE share_token IS NOT NULL AND deleted_at IS NULL;

-- RLS
ALTER TABLE public.comparable_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comp_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comp_analysis_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comp_analysis_report_comps ENABLE ROW LEVEL SECURITY;

CREATE POLICY comps_select ON public.comparable_sales
  FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY comps_insert ON public.comparable_sales
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY comps_update ON public.comparable_sales
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY comps_delete ON public.comparable_sales
  FOR DELETE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY comp_adj_select ON public.comp_adjustments
  FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY comp_adj_insert ON public.comp_adjustments
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY comp_adj_update ON public.comp_adjustments
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY comp_reports_select ON public.comp_analysis_reports
  FOR SELECT USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    OR (share_token IS NOT NULL AND status = 'shared') -- Public share access
  );
CREATE POLICY comp_reports_insert ON public.comp_analysis_reports
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY comp_reports_update ON public.comp_analysis_reports
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY comp_report_comps_select ON public.comp_analysis_report_comps
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM public.comp_analysis_reports r
    WHERE r.id = report_id
    AND (r.company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
         OR (r.share_token IS NOT NULL AND r.status = 'shared'))
  ));
CREATE POLICY comp_report_comps_insert ON public.comp_analysis_report_comps
  FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM public.comp_analysis_reports r
    WHERE r.id = report_id
    AND r.company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  ));

-- Audit triggers
CREATE TRIGGER comparable_sales_updated BEFORE UPDATE ON public.comparable_sales
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER comp_adjustments_updated BEFORE UPDATE ON public.comp_adjustments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER comp_analysis_reports_updated BEFORE UPDATE ON public.comp_analysis_reports
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- PART 3: Unified Storm/Weather Events Pipeline
-- Single source of truth for all weather/storm data.
-- RE30, CLIENT5, CLIENT11, RE25, Recon P9 all subscribe to this.
-- Feeds from NOAA SPC, NWS Alerts, FEMA Disasters.
-- ============================================================================

-- Unified storm events — single pipeline for all weather-related features
CREATE TABLE IF NOT EXISTS public.storm_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Event identification
  event_type varchar(50) NOT NULL, -- tornado, hail, wind, flood, hurricane, winter_storm, wildfire, earthquake
  event_subtype varchar(50), -- EF0-EF5, Cat1-Cat5, etc.
  severity varchar(20) NOT NULL DEFAULT 'moderate', -- minor, moderate, severe, extreme, catastrophic
  -- Location
  lat decimal(10,7) NOT NULL,
  lng decimal(10,7) NOT NULL,
  affected_radius_miles decimal(6,2),
  state varchar(2),
  county varchar(100),
  city varchar(100),
  zip varchar(10),
  fips_code varchar(5),
  -- Timing
  event_start timestamptz NOT NULL,
  event_end timestamptz,
  reported_at timestamptz NOT NULL DEFAULT now(),
  -- Damage assessment
  estimated_damage_cents bigint,
  damage_category varchar(20), -- none, minor, moderate, major, catastrophic
  injuries int DEFAULT 0,
  fatalities int DEFAULT 0,
  -- Weather details
  wind_speed_mph decimal(5,1),
  hail_size_inches decimal(3,1),
  rainfall_inches decimal(5,2),
  snowfall_inches decimal(5,2),
  flood_depth_feet decimal(5,2),
  -- Source tracking
  source_api varchar(50) NOT NULL, -- noaa_spc, nws_alerts, fema_disasters, weather_gov
  source_event_id varchar(100), -- External event ID for dedup
  source_url text,
  raw_data jsonb, -- Original API response
  -- Processing
  is_verified boolean NOT NULL DEFAULT false,
  verified_at timestamptz,
  -- Audit
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_storm_event_source UNIQUE (source_api, source_event_id)
);

-- Storm event impacts — which properties/clients are affected
CREATE TABLE IF NOT EXISTS public.storm_event_impacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  storm_event_id uuid NOT NULL REFERENCES public.storm_events(id),
  -- What's affected
  property_id uuid,
  company_id uuid NOT NULL REFERENCES public.companies(id),
  -- Impact assessment
  distance_miles decimal(6,2),
  impact_level varchar(20) NOT NULL DEFAULT 'potential', -- direct_hit, nearby, potential, monitoring
  -- Response tracking
  notification_sent boolean NOT NULL DEFAULT false,
  notification_sent_at timestamptz,
  response_status varchar(20) DEFAULT 'unreviewed', -- unreviewed, reviewed, claim_filed, claim_approved, repaired, dismissed
  -- Linkage to other systems
  insurance_claim_id uuid, -- Links to insurance claims if filed
  job_id uuid, -- Links to repair job if created
  -- Audit
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Indexes
CREATE INDEX idx_storm_events_type ON public.storm_events(event_type);
CREATE INDEX idx_storm_events_time ON public.storm_events(event_start DESC);
CREATE INDEX idx_storm_events_location ON public.storm_events(lat, lng);
CREATE INDEX idx_storm_events_state ON public.storm_events(state);
CREATE INDEX idx_storm_events_severity ON public.storm_events(severity);
CREATE INDEX idx_storm_events_source ON public.storm_events(source_api, source_event_id);

CREATE INDEX idx_storm_impacts_event ON public.storm_event_impacts(storm_event_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_storm_impacts_property ON public.storm_event_impacts(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_storm_impacts_company ON public.storm_event_impacts(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_storm_impacts_status ON public.storm_event_impacts(response_status) WHERE deleted_at IS NULL;

-- RLS
ALTER TABLE public.storm_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.storm_event_impacts ENABLE ROW LEVEL SECURITY;

-- Storm events are public data — anyone can read
CREATE POLICY storm_events_select ON public.storm_events
  FOR SELECT USING (true);
-- Only service_role can write storm events (from ingestion pipeline)
CREATE POLICY storm_events_insert ON public.storm_events
  FOR INSERT WITH CHECK (auth.jwt() ->> 'role' = 'service_role');
CREATE POLICY storm_events_update ON public.storm_events
  FOR UPDATE USING (auth.jwt() ->> 'role' = 'service_role');

-- Storm impacts are company-scoped
CREATE POLICY storm_impacts_select ON public.storm_event_impacts
  FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY storm_impacts_insert ON public.storm_event_impacts
  FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY storm_impacts_update ON public.storm_event_impacts
  FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Audit triggers
CREATE TRIGGER storm_events_updated BEFORE UPDATE ON public.storm_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER storm_event_impacts_updated BEFORE UPDATE ON public.storm_event_impacts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
