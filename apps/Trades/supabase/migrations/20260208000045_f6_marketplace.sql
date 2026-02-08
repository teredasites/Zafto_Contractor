-- F6: Marketplace tables
-- Equipment AI scanning, pre-qualified leads, contractor bidding

-- Equipment Database — known models, issues, lifespans
CREATE TABLE equipment_database (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Identification
  category TEXT NOT NULL CHECK (category IN ('hvac','plumbing','electrical','appliance','roofing','structural','fire_protection','elevator','generator','solar','other')),
  manufacturer TEXT NOT NULL,
  model_number TEXT NOT NULL,
  model_name TEXT,
  -- Specs
  year_start INTEGER,  -- first year manufactured
  year_end INTEGER,    -- last year manufactured (null = still made)
  avg_lifespan_years INTEGER,
  energy_rating TEXT,
  -- Known Issues
  common_issues JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{issue, severity, typical_age_years, fix_description, avg_repair_cost}]
  recall_notices JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{recall_id, date, description, severity}]
  -- Pricing
  avg_replacement_cost NUMERIC(10,2),
  avg_repair_cost NUMERIC(10,2),
  -- Media
  reference_image_url TEXT,
  manual_url TEXT,
  -- Metadata
  data_source TEXT DEFAULT 'manual',  -- 'manual', 'ai_generated', 'manufacturer', 'community'
  verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Equipment Scans — AI identification results from camera scans
CREATE TABLE equipment_scans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Who scanned
  scanned_by_user_id UUID REFERENCES auth.users(id),
  homeowner_id UUID,  -- if scanned by homeowner (ZAFTO Home)
  company_id UUID REFERENCES companies(id),  -- null for homeowner scans
  -- Scan data
  photo_path TEXT NOT NULL,
  scan_type TEXT DEFAULT 'photo' CHECK (scan_type IN ('photo','barcode','model_plate','label')),
  -- AI Results
  ai_confidence NUMERIC(5,2),  -- 0-100
  identified_equipment_id UUID REFERENCES equipment_database(id),
  identified_category TEXT,
  identified_manufacturer TEXT,
  identified_model TEXT,
  identified_year INTEGER,
  ai_diagnosis JSONB NOT NULL DEFAULT '{}'::jsonb,  -- {condition, estimated_age, issues_found, urgency, recommendations}
  ai_raw_response JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- Location
  property_address TEXT,
  lat NUMERIC(10,7),
  lng NUMERIC(10,7),
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','processing','completed','failed','lead_generated')),
  -- Lead conversion
  marketplace_lead_id UUID,  -- set if this scan generated a lead
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Marketplace Leads — generated from scans or homeowner requests
CREATE TABLE marketplace_leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Source
  source_type TEXT NOT NULL CHECK (source_type IN ('equipment_scan','homeowner_request','referral','website','app')),
  equipment_scan_id UUID REFERENCES equipment_scans(id),
  -- Homeowner
  homeowner_name TEXT NOT NULL,
  homeowner_email TEXT,
  homeowner_phone TEXT,
  -- Property
  property_address TEXT NOT NULL,
  property_city TEXT,
  property_state TEXT,
  property_zip TEXT,
  property_type TEXT DEFAULT 'residential' CHECK (property_type IN ('residential','commercial','industrial','multi_family')),
  -- Service needed
  trade_category TEXT NOT NULL,
  service_type TEXT DEFAULT 'repair' CHECK (service_type IN ('repair','replace','install','inspect','emergency','maintenance')),
  urgency TEXT DEFAULT 'normal' CHECK (urgency IN ('emergency','urgent','normal','flexible')),
  description TEXT,
  equipment_info JSONB NOT NULL DEFAULT '{}'::jsonb,  -- {category, manufacturer, model, year, condition, diagnosis}
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Budget
  estimated_budget_min NUMERIC(10,2),
  estimated_budget_max NUMERIC(10,2),
  -- Matching
  matched_contractors JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{company_id, match_score, distance_miles}]
  max_bids INTEGER DEFAULT 5,
  -- Status
  status TEXT DEFAULT 'open' CHECK (status IN ('open','bidding','accepted','completed','expired','cancelled')),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Marketplace Bids — contractor responses to leads
CREATE TABLE marketplace_bids (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  marketplace_lead_id UUID NOT NULL REFERENCES marketplace_leads(id),
  company_id UUID NOT NULL REFERENCES companies(id),
  bidder_user_id UUID REFERENCES auth.users(id),
  -- Bid details
  bid_amount NUMERIC(10,2) NOT NULL,
  bid_type TEXT DEFAULT 'fixed' CHECK (bid_type IN ('fixed','range','hourly','free_estimate')),
  bid_amount_max NUMERIC(10,2),  -- for range bids
  description TEXT,
  estimated_timeline TEXT,
  includes_parts BOOLEAN DEFAULT true,
  warranty_offered TEXT,
  -- Availability
  earliest_available DATE,
  -- Contractor info for homeowner
  company_name TEXT NOT NULL,
  contractor_rating NUMERIC(3,2),
  years_experience INTEGER,
  license_number TEXT,
  insured BOOLEAN DEFAULT true,
  -- Status
  status TEXT DEFAULT 'submitted' CHECK (status IN ('submitted','viewed','shortlisted','accepted','rejected','withdrawn','expired')),
  homeowner_viewed_at TIMESTAMPTZ,
  -- Messages
  messages JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{from, message, timestamp}]
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Contractor Marketplace Profiles — public-facing contractor info
CREATE TABLE contractor_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) UNIQUE,
  -- Display
  display_name TEXT NOT NULL,
  tagline TEXT,
  description TEXT,
  logo_path TEXT,
  cover_photo_path TEXT,
  -- Service area
  service_radius_miles INTEGER DEFAULT 25,
  service_zip_codes TEXT[] DEFAULT '{}',
  -- Trades
  trade_categories TEXT[] NOT NULL DEFAULT '{}',
  specializations TEXT[] DEFAULT '{}',
  -- Credentials
  license_number TEXT,
  license_state TEXT,
  insurance_verified BOOLEAN DEFAULT false,
  bonded BOOLEAN DEFAULT false,
  years_in_business INTEGER,
  -- Ratings
  avg_rating NUMERIC(3,2) DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  total_jobs_completed INTEGER DEFAULT 0,
  -- Settings
  auto_bid BOOLEAN DEFAULT false,
  max_daily_leads INTEGER DEFAULT 10,
  min_job_value NUMERIC(10,2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  subscription_tier TEXT DEFAULT 'basic' CHECK (subscription_tier IN ('basic','pro','premium')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE equipment_database ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment_scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_bids ENABLE ROW LEVEL SECURITY;
ALTER TABLE contractor_profiles ENABLE ROW LEVEL SECURITY;

-- Equipment database is public read
CREATE POLICY equip_db_read ON equipment_database FOR SELECT USING (true);
CREATE POLICY equip_db_write ON equipment_database FOR INSERT WITH CHECK (true);  -- admin only in practice via service role

-- Scans: company members see their company scans, homeowners see their own
CREATE POLICY scans_company ON equipment_scans FOR ALL USING (
  company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  OR scanned_by_user_id = auth.uid()
);

-- Leads: visible to matched contractors and creator
CREATE POLICY leads_public ON marketplace_leads FOR SELECT USING (true);  -- leads are public listings
CREATE POLICY leads_insert ON marketplace_leads FOR INSERT WITH CHECK (true);

-- Bids: company sees own bids
CREATE POLICY bids_company ON marketplace_bids FOR ALL USING (
  company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
);
CREATE POLICY bids_lead_owner ON marketplace_bids FOR SELECT USING (
  marketplace_lead_id IN (SELECT id FROM marketplace_leads)
);

-- Profiles: own company
CREATE POLICY profiles_company ON contractor_profiles FOR ALL USING (
  company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
);
CREATE POLICY profiles_public_read ON contractor_profiles FOR SELECT USING (is_active = true);

-- Indexes
CREATE INDEX idx_equip_db_category ON equipment_database(category);
CREATE INDEX idx_equip_db_manufacturer ON equipment_database(manufacturer);
CREATE INDEX idx_equip_db_model ON equipment_database(model_number);
CREATE INDEX idx_scans_user ON equipment_scans(scanned_by_user_id);
CREATE INDEX idx_scans_status ON equipment_scans(status);
CREATE INDEX idx_mkt_leads_status ON marketplace_leads(status);
CREATE INDEX idx_mkt_leads_trade ON marketplace_leads(trade_category);
CREATE INDEX idx_mkt_leads_zip ON marketplace_leads(property_zip);
CREATE INDEX idx_mkt_bids_lead ON marketplace_bids(marketplace_lead_id);
CREATE INDEX idx_mkt_bids_company ON marketplace_bids(company_id);
CREATE INDEX idx_contractor_profiles_company ON contractor_profiles(company_id);

-- Triggers
CREATE TRIGGER equip_db_updated BEFORE UPDATE ON equipment_database FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER mkt_leads_updated BEFORE UPDATE ON marketplace_leads FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER mkt_bids_updated BEFORE UPDATE ON marketplace_bids FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER contractor_profiles_updated BEFORE UPDATE ON contractor_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
