-- ============================================================
-- S135-ENTITY: Inspector Operations + Homeowner Operations
-- Migration 000155
--
-- INS-PHOTO: Photo annotations schema on inspection_results
-- INS-TMPL:  Template versioning columns
-- INS-BOOK:  inspector_booking_profiles + booking_requests
-- INS-CRL:   repair_request_lists + repair_request_items
-- INS-PACK:  service_catalog + service_packages
-- HO-FIX:    fix_requests (concierge)
-- HO-LAND:   portfolio_properties (landlord analytics)
--
-- INS-VOICE: No new tables (Flutter speech_to_text package only)
-- ============================================================


-- ============================================================
-- 1. ALTER inspection_results — add photo/annotation support
--    Photos stored per-item in JSONB items array, but we add
--    top-level columns for aggregate tracking + gallery access
-- ============================================================
ALTER TABLE inspection_results
  ADD COLUMN IF NOT EXISTS total_photos INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS photos_with_annotations INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS gallery_paths JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS reinspection_of UUID REFERENCES inspection_results(id),
  ADD COLUMN IF NOT EXISTS property_id UUID REFERENCES properties(id),
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_ir_reinspection ON inspection_results(reinspection_of) WHERE reinspection_of IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ir_property ON inspection_results(property_id) WHERE property_id IS NOT NULL;


-- ============================================================
-- 2. ALTER inspection_templates — versioning for INS-TMPL
-- ============================================================
ALTER TABLE inspection_templates
  ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS parent_template_id UUID REFERENCES inspection_templates(id),
  ADD COLUMN IF NOT EXISTS is_published BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_shareable BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS share_category TEXT,
  ADD COLUMN IF NOT EXISTS download_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS avg_rating NUMERIC(3,2),
  ADD COLUMN IF NOT EXISTS conditional_logic JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS state_form_code TEXT,
  ADD COLUMN IF NOT EXISTS state_form_locked BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS estimated_duration_minutes INTEGER,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;


-- ============================================================
-- 3. INSPECTOR BOOKING PROFILES — public-facing inspector pages
-- ============================================================
CREATE TABLE IF NOT EXISTS inspector_booking_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  inspector_id UUID NOT NULL REFERENCES auth.users(id),

  -- Public profile
  public_url_slug TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  bio TEXT,
  photo_url TEXT,
  license_number TEXT,
  certifications TEXT[] DEFAULT '{}',

  -- Service area
  service_area_zip_codes TEXT[] DEFAULT '{}',
  service_area_radius_miles INTEGER DEFAULT 30,

  -- Offerings
  services_offered JSONB DEFAULT '[]'::jsonb,  -- [{service_id, name, description, price, duration_min}]
  pricing_notes TEXT,

  -- Availability rules
  availability_rules JSONB DEFAULT '{}'::jsonb,
  -- {monday: {start: "08:00", end: "17:00"}, tuesday: {...}, blocked_dates: ["2026-03-01"]}
  min_notice_hours INTEGER NOT NULL DEFAULT 24,
  max_advance_days INTEGER NOT NULL DEFAULT 60,
  buffer_minutes INTEGER NOT NULL DEFAULT 30,
  auto_confirm BOOLEAN NOT NULL DEFAULT false,

  -- Cancellation
  cancellation_policy TEXT,
  cancellation_fee NUMERIC(10,2),
  free_cancellation_hours INTEGER DEFAULT 24,

  -- Stats (denormalized for fast display)
  avg_rating NUMERIC(3,2),
  review_count INTEGER NOT NULL DEFAULT 0,
  total_bookings INTEGER NOT NULL DEFAULT 0,

  -- Status
  is_active BOOLEAN NOT NULL DEFAULT true,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_ibp_company ON inspector_booking_profiles(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ibp_inspector ON inspector_booking_profiles(inspector_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ibp_slug ON inspector_booking_profiles(public_url_slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_ibp_active ON inspector_booking_profiles(is_active) WHERE is_active = true AND deleted_at IS NULL;
CREATE INDEX idx_ibp_zips ON inspector_booking_profiles USING gin(service_area_zip_codes) WHERE deleted_at IS NULL;

ALTER TABLE inspector_booking_profiles ENABLE ROW LEVEL SECURITY;

-- Public read (for booking pages — no auth required path uses service_role)
CREATE POLICY ibp_select ON inspector_booking_profiles FOR SELECT TO authenticated
  USING (deleted_at IS NULL AND (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    OR is_active = true  -- allow cross-company read for booking
  ));
CREATE POLICY ibp_insert ON inspector_booking_profiles FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY ibp_update ON inspector_booking_profiles FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY ibp_delete ON inspector_booking_profiles FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('inspector_booking_profiles');
CREATE TRIGGER ibp_audit AFTER INSERT OR UPDATE OR DELETE ON inspector_booking_profiles
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 4. BOOKING REQUESTS — agent-submitted booking requests
-- ============================================================
CREATE TABLE IF NOT EXISTS booking_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  inspector_profile_id UUID NOT NULL REFERENCES inspector_booking_profiles(id) ON DELETE CASCADE,

  -- Requesting agent
  agent_name TEXT NOT NULL,
  agent_email TEXT NOT NULL,
  agent_phone TEXT,
  agent_company TEXT,
  agent_user_id UUID REFERENCES auth.users(id),

  -- Property details
  property_address TEXT NOT NULL,
  property_type TEXT CHECK (property_type IN (
    'single_family','condo','townhouse','multi_family','commercial',
    'manufactured','vacant_land','new_construction','other'
  )),
  sqft INTEGER,
  year_built INTEGER,
  bedrooms INTEGER,
  bathrooms NUMERIC(3,1),

  -- Services requested
  requested_services TEXT[] DEFAULT '{}',
  package_id UUID,  -- FK to service_packages if using a package

  -- Schedule
  preferred_dates JSONB DEFAULT '[]'::jsonb,  -- [{date, time_slot}]
  selected_date DATE,
  selected_time TIME,
  estimated_duration_minutes INTEGER,

  -- Pricing
  quoted_price NUMERIC(10,2),
  payment_status TEXT DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid','deposit_paid','paid_in_full','refunded')),

  -- Status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending','confirmed','rescheduled','in_progress','completed',
    'cancelled_by_agent','cancelled_by_inspector','no_show'
  )),
  confirmed_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  -- Instructions
  special_instructions TEXT,
  access_instructions TEXT,
  lockbox_code TEXT,
  gate_code TEXT,

  -- Follow-up
  inspection_result_id UUID REFERENCES inspection_results(id),
  feedback_sent BOOLEAN NOT NULL DEFAULT false,

  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_br_company ON booking_requests(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_br_profile ON booking_requests(inspector_profile_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_br_agent ON booking_requests(agent_email) WHERE deleted_at IS NULL;
CREATE INDEX idx_br_date ON booking_requests(selected_date) WHERE selected_date IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_br_status ON booking_requests(company_id, status) WHERE deleted_at IS NULL;

ALTER TABLE booking_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY br_select ON booking_requests FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY br_insert ON booking_requests FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY br_update ON booking_requests FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY br_delete ON booking_requests FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('booking_requests');
CREATE TRIGGER br_audit AFTER INSERT OR UPDATE OR DELETE ON booking_requests
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 5. REPAIR REQUEST LISTS — buyer negotiation documents from inspections
-- ============================================================
CREATE TABLE IF NOT EXISTS repair_request_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Inspection source
  inspection_id UUID NOT NULL REFERENCES inspection_results(id) ON DELETE CASCADE,

  -- Parties
  created_by UUID REFERENCES auth.users(id),
  property_address TEXT NOT NULL,
  buyer_name TEXT,
  seller_name TEXT,
  buyer_agent TEXT,
  seller_agent TEXT,

  -- Content
  title TEXT NOT NULL DEFAULT 'Repair Request List',
  total_items INTEGER NOT NULL DEFAULT 0,
  included_items INTEGER NOT NULL DEFAULT 0,
  estimated_total_cost NUMERIC(12,2) DEFAULT 0,

  -- Status
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
    'draft','sent','viewed','responded','negotiating',
    'agreed','completed','withdrawn'
  )),
  sent_at TIMESTAMPTZ,
  sent_to_email TEXT,
  viewed_at TIMESTAMPTZ,
  responded_at TIMESTAMPTZ,

  -- Document
  pdf_path TEXT,
  share_token TEXT UNIQUE,

  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_rrl_company ON repair_request_lists(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_rrl_inspection ON repair_request_lists(inspection_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_rrl_status ON repair_request_lists(company_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_rrl_token ON repair_request_lists(share_token) WHERE share_token IS NOT NULL;

ALTER TABLE repair_request_lists ENABLE ROW LEVEL SECURITY;

CREATE POLICY rrl_select ON repair_request_lists FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY rrl_insert ON repair_request_lists FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY rrl_update ON repair_request_lists FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY rrl_delete ON repair_request_lists FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('repair_request_lists');
CREATE TRIGGER rrl_audit AFTER INSERT OR UPDATE OR DELETE ON repair_request_lists
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 6. REPAIR REQUEST ITEMS — individual items in request list
-- ============================================================
CREATE TABLE IF NOT EXISTS repair_request_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_list_id UUID NOT NULL REFERENCES repair_request_lists(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Source from inspection
  inspection_item_index INTEGER,      -- index in inspection_results.items JSONB
  deficiency_id UUID REFERENCES inspection_deficiencies(id) ON DELETE SET NULL,

  -- Item details
  description TEXT NOT NULL,
  location TEXT,                      -- "Master Bathroom", "Kitchen", etc.
  severity TEXT CHECK (severity IN ('safety','major','minor','cosmetic','informational')),

  -- Cost estimation
  estimated_repair_cost NUMERIC(10,2),
  cost_source TEXT,                   -- 'manual', 'estimate_engine', 'contractor_quote'

  -- Request type
  request_type TEXT NOT NULL DEFAULT 'repair_before_closing' CHECK (request_type IN (
    'repair_before_closing','credit_at_closing','home_warranty_coverage',
    'seller_responsibility','informational_only','professional_evaluation'
  )),

  -- Contractor
  contractor_recommendation TEXT,

  -- Photos from inspection
  photo_urls TEXT[] DEFAULT '{}',

  -- Inclusion/priority
  included BOOLEAN NOT NULL DEFAULT true,
  buyer_priority INTEGER NOT NULL DEFAULT 5 CHECK (buyer_priority BETWEEN 1 AND 10),
  sort_order INTEGER NOT NULL DEFAULT 0,

  -- Seller response
  seller_response TEXT CHECK (seller_response IN ('agree','counter','decline','no_response')),
  seller_counter_amount NUMERIC(10,2),
  seller_notes TEXT,
  resolution TEXT,
  resolved_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_rri_list ON repair_request_items(request_list_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_rri_company ON repair_request_items(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_rri_deficiency ON repair_request_items(deficiency_id) WHERE deficiency_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_rri_included ON repair_request_items(request_list_id, included) WHERE included = true AND deleted_at IS NULL;
CREATE INDEX idx_rri_order ON repair_request_items(request_list_id, sort_order) WHERE deleted_at IS NULL;

ALTER TABLE repair_request_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY rri_select ON repair_request_items FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY rri_insert ON repair_request_items FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY rri_update ON repair_request_items FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY rri_delete ON repair_request_items FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('repair_request_items');
CREATE TRIGGER rri_audit AFTER INSERT OR UPDATE OR DELETE ON repair_request_items
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 7. SERVICE CATALOG — inspector's service offerings
-- ============================================================
CREATE TABLE IF NOT EXISTS service_catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Service definition
  service_name TEXT NOT NULL,
  service_type TEXT NOT NULL CHECK (service_type IN (
    'home_inspection','radon','mold','wdi','sewer_scope',
    'well_water','septic','pool_spa','chimney','roof_cert',
    'stucco','thermal','wind_mitigation','4_point',
    'new_construction','commercial','environmental','lead',
    'asbestos','indoor_air_quality','energy_audit','other'
  )),
  description TEXT,

  -- Pricing
  base_price NUMERIC(10,2) NOT NULL DEFAULT 0,
  price_per_sqft NUMERIC(8,4),
  sqft_tiers JSONB DEFAULT '[]'::jsonb,
  -- [{min_sqft: 0, max_sqft: 2000, price: 350}, {min_sqft: 2001, max_sqft: 3000, price: 400}, ...]
  age_adjustment JSONB DEFAULT '{}'::jsonb,
  -- {pre_1980: 50, pre_1960: 75} — surcharge for older homes

  -- Duration
  estimated_duration_minutes INTEGER NOT NULL DEFAULT 60,

  -- Requirements
  requires_certification TEXT[] DEFAULT '{}',  -- cert types needed
  requires_equipment TEXT[] DEFAULT '{}',

  -- Template link
  template_id UUID REFERENCES inspection_templates(id),

  -- Display
  is_addon BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_sc_company ON service_catalog(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_sc_type ON service_catalog(company_id, service_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_sc_active ON service_catalog(company_id, is_active) WHERE is_active = true AND deleted_at IS NULL;

ALTER TABLE service_catalog ENABLE ROW LEVEL SECURITY;

CREATE POLICY sc_select ON service_catalog FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY sc_insert ON service_catalog FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY sc_update ON service_catalog FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY sc_delete ON service_catalog FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('service_catalog');
CREATE TRIGGER sc_audit AFTER INSERT OR UPDATE OR DELETE ON service_catalog
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 8. SERVICE PACKAGES — bundled inspection offerings
-- ============================================================
CREATE TABLE IF NOT EXISTS service_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Package definition
  package_name TEXT NOT NULL,
  description TEXT,
  included_services JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- [{service_catalog_id, service_name, individual_price}]

  -- Pricing
  individual_total NUMERIC(10,2) NOT NULL DEFAULT 0,
  package_price NUMERIC(10,2) NOT NULL DEFAULT 0,
  discount_pct NUMERIC(5,2) GENERATED ALWAYS AS (
    CASE WHEN individual_total > 0
      THEN ROUND(((individual_total - package_price) / individual_total) * 100, 2)
      ELSE 0
    END
  ) STORED,
  savings_amount NUMERIC(10,2) GENERATED ALWAYS AS (
    individual_total - package_price
  ) STORED,

  -- Duration
  estimated_duration_minutes INTEGER NOT NULL DEFAULT 120,

  -- Stats
  booking_count INTEGER NOT NULL DEFAULT 0,
  total_revenue NUMERIC(12,2) NOT NULL DEFAULT 0,

  -- Display
  is_featured BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_sp_company ON service_packages(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_sp_active ON service_packages(company_id, is_active) WHERE is_active = true AND deleted_at IS NULL;
CREATE INDEX idx_sp_featured ON service_packages(company_id, is_featured) WHERE is_featured = true AND deleted_at IS NULL;

ALTER TABLE service_packages ENABLE ROW LEVEL SECURITY;

CREATE POLICY sp_select ON service_packages FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY sp_insert ON service_packages FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY sp_update ON service_packages FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY sp_delete ON service_packages FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('service_packages');
CREATE TRIGGER sp_audit AFTER INSERT OR UPDATE OR DELETE ON service_packages
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 9. FIX REQUESTS — homeowner concierge "fix it for me"
-- ============================================================
CREATE TABLE IF NOT EXISTS fix_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,

  -- Homeowner
  homeowner_id UUID NOT NULL REFERENCES auth.users(id),
  property_id UUID REFERENCES properties(id) ON DELETE SET NULL,

  -- Problem description
  category TEXT NOT NULL CHECK (category IN (
    'plumbing','electrical','hvac','roofing','appliance',
    'painting','flooring','drywall','door_window','pest',
    'landscaping','cleaning','general','other','emergency'
  )),
  subcategory TEXT,
  description TEXT NOT NULL,
  photos JSONB DEFAULT '[]'::jsonb,  -- [{storage_path, thumbnail_path, taken_at}]
  urgency TEXT NOT NULL DEFAULT 'routine' CHECK (urgency IN (
    'routine','soon','urgent','emergency'
  )),

  -- Schedule preferences
  preferred_dates JSONB DEFAULT '[]'::jsonb,
  preferred_time_of_day TEXT CHECK (preferred_time_of_day IN ('morning','afternoon','evening','anytime')),
  budget_range TEXT,  -- 'under_200', '200_500', '500_1000', '1000_plus', 'unsure'

  -- Matching
  matched_contractor_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  matched_at TIMESTAMPTZ,
  match_radius_miles INTEGER DEFAULT 25,
  contractors_notified INTEGER DEFAULT 0,
  contractors_declined INTEGER DEFAULT 0,

  -- Quote & approval
  quoted_price NUMERIC(10,2),
  quote_description TEXT,
  approved_at TIMESTAMPTZ,

  -- Job creation
  job_id UUID REFERENCES jobs(id) ON DELETE SET NULL,

  -- Completion
  completed_at TIMESTAMPTZ,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  feedback TEXT,
  rated_at TIMESTAMPTZ,

  -- Status
  status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN (
    'submitted','matching','matched','quoted','approved',
    'scheduled','in_progress','completed','rated',
    'cancelled','expired','no_match'
  )),

  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_fr_homeowner ON fix_requests(homeowner_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_fr_property ON fix_requests(property_id) WHERE property_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_fr_status ON fix_requests(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_fr_category ON fix_requests(category) WHERE deleted_at IS NULL;
CREATE INDEX idx_fr_urgency ON fix_requests(urgency) WHERE urgency IN ('urgent','emergency') AND deleted_at IS NULL;
CREATE INDEX idx_fr_contractor ON fix_requests(matched_contractor_id) WHERE matched_contractor_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_fr_job ON fix_requests(job_id) WHERE job_id IS NOT NULL AND deleted_at IS NULL;

ALTER TABLE fix_requests ENABLE ROW LEVEL SECURITY;

-- Homeowners see their own requests; contractors see matched requests
CREATE POLICY fr_select ON fix_requests FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL AND (
      homeowner_id = auth.uid()
      OR matched_contractor_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );
CREATE POLICY fr_insert ON fix_requests FOR INSERT TO authenticated
  WITH CHECK (homeowner_id = auth.uid());
CREATE POLICY fr_update ON fix_requests FOR UPDATE TO authenticated
  USING (
    deleted_at IS NULL AND (
      homeowner_id = auth.uid()
      OR matched_contractor_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );
-- No physical delete policy — soft delete only

SELECT update_updated_at('fix_requests');
CREATE TRIGGER fr_audit AFTER INSERT OR UPDATE OR DELETE ON fix_requests
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 10. PORTFOLIO PROPERTIES — landlord investment tracking
-- ============================================================
CREATE TABLE IF NOT EXISTS portfolio_properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  homeowner_id UUID NOT NULL REFERENCES auth.users(id),
  property_id UUID REFERENCES properties(id) ON DELETE SET NULL,

  -- Acquisition
  acquisition_date DATE,
  purchase_price NUMERIC(14,2),
  closing_costs NUMERIC(10,2),
  rehab_cost NUMERIC(12,2),
  total_invested NUMERIC(14,2) GENERATED ALWAYS AS (
    COALESCE(purchase_price, 0) + COALESCE(closing_costs, 0) + COALESCE(rehab_cost, 0)
  ) STORED,

  -- Current value
  current_value NUMERIC(14,2),
  value_source TEXT CHECK (value_source IN ('appraisal','zillow','manual','redfin','tax_assessment')),
  value_date DATE,

  -- Mortgage
  mortgage_balance NUMERIC(14,2),
  mortgage_rate NUMERIC(5,3),
  mortgage_payment NUMERIC(10,2),    -- monthly P&I
  mortgage_start_date DATE,
  mortgage_term_years INTEGER,

  -- Computed equity
  equity NUMERIC(14,2) GENERATED ALWAYS AS (
    COALESCE(current_value, 0) - COALESCE(mortgage_balance, 0)
  ) STORED,

  -- Operating expenses (monthly)
  insurance_annual NUMERIC(10,2),
  property_tax_annual NUMERIC(10,2),
  hoa_monthly NUMERIC(10,2),
  management_fee_pct NUMERIC(5,2),
  avg_maintenance_monthly NUMERIC(10,2),  -- auto-calculated from Zafto job costs

  -- Income
  monthly_rent NUMERIC(10,2),
  unit_count INTEGER NOT NULL DEFAULT 1,

  -- Computed cash flow (monthly)
  monthly_cash_flow NUMERIC(10,2) GENERATED ALWAYS AS (
    COALESCE(monthly_rent, 0)
    - COALESCE(mortgage_payment, 0)
    - COALESCE(insurance_annual / 12, 0)
    - COALESCE(property_tax_annual / 12, 0)
    - COALESCE(hoa_monthly, 0)
    - COALESCE(avg_maintenance_monthly, 0)
    - COALESCE(monthly_rent * management_fee_pct / 100, 0)
  ) STORED,

  -- Lease
  lease_start DATE,
  lease_end DATE,
  tenant_name TEXT,
  tenant_email TEXT,
  tenant_phone TEXT,

  -- Vacancy tracking
  vacancy_rate_pct NUMERIC(5,2),
  vacancy_days_ytd INTEGER DEFAULT 0,
  is_vacant BOOLEAN NOT NULL DEFAULT false,
  last_vacancy_start DATE,

  -- Status
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN (
    'active','vacant','renovation','for_sale','sold','inactive'
  )),

  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_pp_homeowner ON portfolio_properties(homeowner_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_property ON portfolio_properties(property_id) WHERE property_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_pp_status ON portfolio_properties(homeowner_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_pp_lease_end ON portfolio_properties(lease_end) WHERE lease_end IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_pp_vacant ON portfolio_properties(homeowner_id, is_vacant) WHERE is_vacant = true AND deleted_at IS NULL;

ALTER TABLE portfolio_properties ENABLE ROW LEVEL SECURITY;

-- Homeowners see own portfolio; property managers (company) see managed properties
CREATE POLICY pp_select ON portfolio_properties FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL AND (
      homeowner_id = auth.uid()
      OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );
CREATE POLICY pp_insert ON portfolio_properties FOR INSERT TO authenticated
  WITH CHECK (homeowner_id = auth.uid());
CREATE POLICY pp_update ON portfolio_properties FOR UPDATE TO authenticated
  USING (
    deleted_at IS NULL AND (
      homeowner_id = auth.uid()
      OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );

SELECT update_updated_at('portfolio_properties');
CREATE TRIGGER pp_audit AFTER INSERT OR UPDATE OR DELETE ON portfolio_properties
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
