# ZAFTO MARKETPLACE — AI Equipment Diagnostics + Lead Generation
## Created: February 5, 2026 (Session 30)

---

## THE CONCEPT

Homeowners scan their equipment (furnace, boiler, AC, water heater, electrical panel, etc.) using their phone camera or by entering the model number. ZAFTO's AI identifies the exact make, model, and approximate age, then cross-references known failure patterns for that unit. The homeowner gets a free diagnosis. When they want service, the system generates a pre-qualified lead with full equipment context and distributes it to contractors — not a "I need a plumber" garbage lead, but a work order with equipment model, probable issue, photos, and location.

**What exists today:** Angi, Thumbtack, Yelp — homeowner says "I need help," contractor pays $25-75 for a blind lead with zero context. Close rates are low. Contractors hate these platforms.

**What ZAFTO does differently:** The lead includes the exact equipment model, age, known issues for that unit, homeowner-confirmed symptoms, photos, and location. The contractor knows what they're walking into before they respond. Close rates go up. Lead value goes up. Contractor satisfaction goes up.

**The Trojan horse:** Contractors don't need to be on the platform to receive their first lead. They get an email ("Zafto Lead") with the pre-diagnosed work order. At the bottom: "Bid on this job through ZAFTO." They click, see the platform, see the CRM — and they're signing up because revenue is already waiting, not because of a sales pitch.

---

## WHAT ALREADY EXISTS (leverage, don't rebuild)

| Component | Status | How It Connects |
|-----------|--------|----------------|
| AI scan functions (5 deployed) | LIVE | `analyzePanel`, `analyzeNameplate`, `analyzeWire`, `analyzeViolation`, `smartScan` — extend for homeowner equipment |
| Client Portal (21 pages) | UI DONE | Becomes Home Portal — add equipment scanning + service request flow |
| Equipment Passport (Doc 16) | SPEC'D | Digital twin of every piece of equipment in the home |
| Client Lifecycle Intelligence (Doc 16 Appendix K) | SPEC'D | Predicts replacement needs from equipment age + known failure data |
| Contractor Trust Architecture (Doc 16 Appendix A) | SPEC'D | 6 principles protecting contractor relationships in marketplace |
| PhotoService (492 lines) | BUILT (unused) | Ready for equipment photo upload + processing |
| Claude API integration | CONFIGURED | Powers the diagnostic engine |

---

## SYSTEM ARCHITECTURE

### Flow: Homeowner → Diagnosis → Lead → Contractor

```
HOMEOWNER SIDE (Home Portal PWA)
┌─────────────────────────────────┐
│ 1. Scan equipment               │
│    - Camera scan (nameplate)    │
│    - Manual model number entry  │
│    - Photo of the unit          │
│                                 │
│ 2. AI identifies equipment      │
│    - Make, model, serial        │
│    - Manufacture date / age     │
│    - Equipment category         │
│    - Known issues for this unit │
│                                 │
│ 3. Symptom capture              │
│    - AI asks guided questions   │
│    - "Is it making noise?"      │
│    - "When did it start?"       │
│    - "Is it still running?"     │
│    - Homeowner confirms/adds    │
│                                 │
│ 4. Diagnosis delivered          │
│    - Probable issue(s) ranked   │
│    - Urgency level (routine /   │
│      soon / urgent / emergency) │
│    - What to expect cost-wise   │
│    - Safety warnings if needed  │
│                                 │
│ 5. "Get quotes" (optional)      │
│    - Homeowner requests service │
│    - Lead generated             │
└─────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│ LEAD GENERATION ENGINE          │
│                                 │
│ Lead package includes:          │
│ - Equipment: make, model, age   │
│ - AI diagnosis: probable issue  │
│ - Symptoms: homeowner-confirmed │
│ - Photos: unit + nameplate      │
│ - Location: city, zip           │
│ - Urgency: routine → emergency  │
│ - Category: HVAC/Plumbing/etc   │
│ - Homeowner: name, contact      │
│                                 │
│ Lead routing:                   │
│ 1. Preferred contractor first   │
│    (if homeowner has one)       │
│ 2. ZAFTO subscribers in area    │
│ 3. Non-subscriber contractors   │
│    (email-only, "Zafto Lead")   │
└─────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│ CONTRACTOR SIDE                 │
│                                 │
│ Subscriber (in-app):           │
│ - Lead appears in dashboard     │
│ - Full equipment context        │
│ - One-tap bid submission        │
│ - Chat with homeowner           │
│                                 │
│ Non-subscriber (email):         │
│ - "Zafto Lead" email            │
│ - Equipment details + photos    │
│ - "Bid on this job" CTA         │
│ - Links to ZAFTO signup         │
│ - THIS IS THE GROWTH ENGINE     │
└─────────────────────────────────┘
```

---

## AI DIAGNOSTIC ENGINE

### Equipment Knowledge Base

The AI needs a structured knowledge base for each equipment type. This compounds over time — every scan adds data.

**Per equipment model, the system knows:**

```sql
-- Equipment scanned by homeowners
CREATE TABLE equipment_scans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  homeowner_id UUID REFERENCES users(id),
  property_id UUID REFERENCES properties(id),
  
  -- Equipment identification
  category TEXT NOT NULL, -- 'hvac', 'plumbing', 'electrical', 'appliance', 'structural'
  subcategory TEXT, -- 'furnace', 'water_heater', 'ac_unit', 'boiler', 'panel', etc.
  make TEXT,
  model TEXT,
  serial_number TEXT,
  manufacture_date DATE,
  installation_date DATE,
  estimated_age_years INTEGER,
  
  -- Scan data
  scan_method TEXT NOT NULL, -- 'camera_nameplate', 'camera_unit', 'manual_entry'
  scan_photos JSONB DEFAULT '[]', -- array of storage paths
  nameplate_photo TEXT, -- storage path
  unit_photo TEXT, -- storage path
  raw_scan_result JSONB, -- full AI response
  
  -- AI diagnosis
  ai_diagnosis JSONB, -- { probable_issues: [], confidence: float, urgency: string }
  symptoms JSONB DEFAULT '[]', -- homeowner-confirmed symptoms
  symptom_answers JSONB DEFAULT '{}', -- full Q&A flow responses
  health_score INTEGER, -- 0-100
  known_issues JSONB DEFAULT '[]', -- from knowledge base for this model
  
  -- Equipment lifecycle
  expected_lifespan_years INTEGER,
  warranty_status TEXT, -- 'active', 'expired', 'unknown'
  warranty_expiry DATE,
  last_service_date DATE,
  next_recommended_service DATE,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Leads generated from equipment scans
CREATE TABLE marketplace_leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  homeowner_id UUID REFERENCES users(id),
  equipment_scan_id UUID REFERENCES equipment_scans(id),
  property_id UUID REFERENCES properties(id),
  
  -- Lead details
  trade TEXT NOT NULL, -- 'hvac', 'plumbing', 'electrical', 'solar', 'roofing', 'general', 'remodeler', 'landscaping'
  category TEXT NOT NULL, -- 'repair', 'replacement', 'maintenance', 'inspection', 'installation'
  title TEXT NOT NULL, -- "Furnace Repair — Inducer Motor"
  description TEXT, -- homeowner's additional notes
  urgency TEXT NOT NULL DEFAULT 'routine', -- 'routine', 'soon', 'urgent', 'emergency'
  
  -- AI context (from equipment scan)
  equipment_make TEXT,
  equipment_model TEXT,
  equipment_age_years INTEGER,
  ai_diagnosis_summary TEXT,
  probable_issue TEXT,
  confidence_score FLOAT,
  estimated_cost_low INTEGER,
  estimated_cost_high INTEGER,
  
  -- Location (zip-level, not exact address until contractor accepted)
  city TEXT,
  state TEXT,
  zip_code TEXT,
  latitude FLOAT,
  longitude FLOAT,
  
  -- Lead quality
  quality_score INTEGER, -- 0-100 calculated from factors
  photos_included BOOLEAN DEFAULT false,
  model_confirmed BOOLEAN DEFAULT false,
  symptoms_complete BOOLEAN DEFAULT false,
  payment_method_on_file BOOLEAN DEFAULT false,
  
  -- Routing
  preferred_contractor_id UUID REFERENCES companies(id), -- null if no preferred
  preferred_contractor_notified_at TIMESTAMPTZ,
  preferred_contractor_expired_at TIMESTAMPTZ, -- 24hr exclusive window
  tier1_released_at TIMESTAMPTZ, -- when opened to subscribers
  tier2_released_at TIMESTAMPTZ, -- when opened to non-subscribers
  
  -- Status
  status TEXT NOT NULL DEFAULT 'open', -- 'open', 'bidding', 'accepted', 'expired', 'cancelled'
  bids_count INTEGER DEFAULT 0,
  accepted_bid_id UUID, -- REFERENCES marketplace_bids(id)
  converted_job_id UUID, -- REFERENCES jobs(id) when bid accepted
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ -- leads expire after 7 days with no bids
);

-- Bids from contractors on marketplace leads
CREATE TABLE marketplace_bids (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id UUID REFERENCES marketplace_leads(id),
  
  -- Contractor (may or may not be a ZAFTO subscriber)
  contractor_company_id UUID REFERENCES companies(id), -- null if non-subscriber
  contractor_name TEXT NOT NULL,
  contractor_company_name TEXT NOT NULL,
  contractor_email TEXT NOT NULL,
  contractor_phone TEXT,
  contractor_license_number TEXT,
  contractor_is_subscriber BOOLEAN DEFAULT false,
  
  -- Bid details
  estimate_low INTEGER NOT NULL,
  estimate_high INTEGER NOT NULL,
  availability TEXT, -- "Tomorrow morning", "Thursday", etc.
  note TEXT, -- contractor's message to homeowner
  estimated_duration TEXT, -- "2-3 hours"
  includes_parts BOOLEAN DEFAULT true,
  warranty_offered TEXT, -- "1 year parts and labor"
  
  -- Contractor profile (pulled from ZAFTO if subscriber, self-reported if not)
  years_experience INTEGER,
  rating FLOAT, -- from ZAFTO reviews
  review_count INTEGER,
  is_licensed BOOLEAN DEFAULT false,
  is_insured BOOLEAN DEFAULT false,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'submitted', -- 'submitted', 'viewed', 'accepted', 'rejected', 'withdrawn'
  homeowner_viewed_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  rejected_at TIMESTAMPTZ,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Non-subscriber contractors discovered via public licensing databases
CREATE TABLE marketplace_contractors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Contact info (from public licensing databases)
  name TEXT NOT NULL,
  company_name TEXT,
  email TEXT,
  phone TEXT,
  
  -- Licensing (from state board)
  license_number TEXT,
  license_state TEXT,
  license_type TEXT, -- 'electrical', 'plumbing', 'hvac', 'general', etc.
  license_status TEXT, -- 'active', 'expired', 'suspended'
  license_expiry DATE,
  
  -- Service area
  city TEXT,
  state TEXT,
  zip_codes JSONB DEFAULT '[]', -- service area zip codes
  
  -- ZAFTO engagement
  leads_sent INTEGER DEFAULT 0,
  leads_responded INTEGER DEFAULT 0,
  leads_won INTEGER DEFAULT 0,
  first_lead_sent_at TIMESTAMPTZ,
  last_lead_sent_at TIMESTAMPTZ,
  converted_to_subscriber BOOLEAN DEFAULT false,
  converted_at TIMESTAMPTZ,
  subscriber_company_id UUID REFERENCES companies(id), -- linked when they sign up
  
  -- Email preferences
  email_opted_out BOOLEAN DEFAULT false,
  email_opted_out_at TIMESTAMPTZ,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Equipment knowledge base (compounds over time)
CREATE TABLE equipment_knowledge (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Equipment identification
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  model_variant TEXT, -- sub-models
  category TEXT NOT NULL, -- 'hvac', 'plumbing', 'electrical', 'appliance'
  subcategory TEXT NOT NULL, -- 'furnace', 'water_heater', 'ac_unit', etc.
  
  -- Specs
  manufacture_year_start INTEGER,
  manufacture_year_end INTEGER, -- null if still in production
  fuel_type TEXT, -- 'gas', 'electric', 'oil', 'propane', 'dual'
  capacity TEXT, -- "80,000 BTU", "50 gallon", "200 amp"
  efficiency_rating TEXT, -- "96% AFUE", "16 SEER"
  
  -- Lifecycle
  expected_lifespan_years INTEGER,
  warranty_years_parts INTEGER,
  warranty_years_labor INTEGER,
  
  -- Known issues (THE GOLD MINE)
  known_issues JSONB DEFAULT '[]',
  -- Each: { issue, typical_age_years, frequency: 'common'|'occasional'|'rare', 
  --         symptoms: [], typical_cost_low, typical_cost_high, severity, parts: [] }
  
  -- Recalls
  recalls JSONB DEFAULT '[]',
  -- Each: { recall_id, date, description, remedy, cpsc_url }
  
  -- Replacement info
  successor_model TEXT,
  discontinued BOOLEAN DEFAULT false,
  parts_availability TEXT, -- 'readily_available', 'limited', 'scarce', 'unavailable'
  
  -- ZAFTO's own data (builds over time)
  total_scans INTEGER DEFAULT 0,
  total_repairs INTEGER DEFAULT 0,
  avg_repair_cost FLOAT,
  most_common_issue TEXT,
  actual_avg_lifespan FLOAT, -- calculated from real replacement data
  regional_cost_data JSONB DEFAULT '{}', -- { "CT": { avg_repair: 550 }, "NY": { avg_repair: 680 } }
  
  -- Source tracking
  data_sources JSONB DEFAULT '[]', -- 'manufacturer', 'cpsc', 'energy_star', 'zafto_repairs', 'contractor_feedback'
  last_verified_at TIMESTAMPTZ,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Homeowner properties (extends the existing Home Portal concept)
CREATE TABLE properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  homeowner_id UUID REFERENCES users(id),
  
  -- Address
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  zip_code TEXT NOT NULL,
  latitude FLOAT,
  longitude FLOAT,
  
  -- Property details
  property_type TEXT, -- 'single_family', 'condo', 'townhouse', 'multi_family'
  year_built INTEGER,
  square_footage INTEGER,
  bedrooms INTEGER,
  bathrooms FLOAT,
  
  -- Home Portal scores
  overall_health_score INTEGER, -- 0-100, calculated from equipment scores
  last_scored_at TIMESTAMPTZ,
  
  -- Status
  is_primary BOOLEAN DEFAULT true,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Smart alerts for homeowners (premium feature)
CREATE TABLE equipment_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  homeowner_id UUID REFERENCES users(id),
  equipment_scan_id UUID REFERENCES equipment_scans(id),
  property_id UUID REFERENCES properties(id),
  
  -- Alert details
  alert_type TEXT NOT NULL, -- 'age_warning', 'recall', 'maintenance_due', 'service_bulletin', 'seasonal_prep', 'replacement_soon'
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  urgency TEXT NOT NULL DEFAULT 'info', -- 'info', 'attention', 'warning', 'critical'
  
  -- Action
  action_type TEXT, -- 'schedule_service', 'view_recall', 'view_details', 'get_quotes'
  action_data JSONB, -- context for the action
  
  -- Status
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'viewed', 'acted', 'dismissed'
  viewed_at TIMESTAMPTZ,
  acted_at TIMESTAMPTZ,
  dismissed_at TIMESTAMPTZ,
  
  -- Lead conversion
  generated_lead_id UUID REFERENCES marketplace_leads(id), -- if homeowner clicked "Get Quotes"
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  scheduled_for TIMESTAMPTZ, -- when to show the alert
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Lead analytics (tracks the growth engine)
CREATE TABLE lead_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id UUID REFERENCES marketplace_leads(id),
  
  -- Funnel tracking
  scan_to_lead_seconds INTEGER, -- how long from scan to requesting quotes
  lead_to_first_bid_seconds INTEGER,
  lead_to_accepted_seconds INTEGER,
  total_bids INTEGER,
  winning_bid_amount INTEGER,
  
  -- Contractor conversion
  non_subscriber_emails_sent INTEGER,
  non_subscriber_bids_received INTEGER,
  new_subscriber_conversions INTEGER, -- contractors who signed up from this lead
  
  -- Revenue attribution
  lead_source TEXT, -- 'equipment_scan', 'smart_alert', 'seasonal_campaign', 'referral'
  subscription_revenue_attributed FLOAT, -- MRR from contractors who converted via this lead chain
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### RLS Policies

```sql
-- Homeowners see only their own equipment and leads
CREATE POLICY equipment_scans_homeowner ON equipment_scans
  FOR ALL USING (homeowner_id = auth.uid());

-- Homeowners see only their own properties
CREATE POLICY properties_homeowner ON properties
  FOR ALL USING (homeowner_id = auth.uid());

-- Homeowners see their own leads
CREATE POLICY leads_homeowner ON marketplace_leads
  FOR SELECT USING (homeowner_id = auth.uid());

-- Contractors see leads in their area/trade (Tier 1: subscribers only see after release)
CREATE POLICY leads_contractor ON marketplace_leads
  FOR SELECT USING (
    status IN ('open', 'bidding')
    AND tier1_released_at IS NOT NULL
    AND tier1_released_at <= NOW()
    AND EXISTS (
      SELECT 1 FROM companies c
      WHERE c.id = auth.jwt()->>'company_id'
      AND c.trades @> ARRAY[marketplace_leads.trade]
      AND c.service_zip_codes @> ARRAY[marketplace_leads.zip_code]
    )
  );

-- Contractors see only their own bids
CREATE POLICY bids_contractor ON marketplace_bids
  FOR ALL USING (
    contractor_company_id = (auth.jwt()->>'company_id')::UUID
  );

-- Homeowners see all bids on their leads
CREATE POLICY bids_homeowner ON marketplace_bids
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM marketplace_leads ml
      WHERE ml.id = marketplace_bids.lead_id
      AND ml.homeowner_id = auth.uid()
    )
  );

-- Equipment knowledge is read-only for all authenticated users
CREATE POLICY equipment_knowledge_read ON equipment_knowledge
  FOR SELECT USING (true);

-- Alerts visible only to the homeowner
CREATE POLICY alerts_homeowner ON equipment_alerts
  FOR ALL USING (homeowner_id = auth.uid());
```

---

## EDGE FUNCTIONS

| Function | Trigger | What It Does |
|----------|---------|-------------|
| `scan-equipment` | Homeowner submits photo/model | Calls Claude API with nameplate photo, identifies make/model/age, returns equipment card |
| `diagnose-equipment` | After scan + symptom capture | Cross-references equipment_knowledge + symptoms, returns diagnosis with confidence |
| `generate-lead` | Homeowner taps "Get Quotes" | Creates marketplace_lead, calculates quality score, starts routing |
| `route-lead` | After lead generated | Checks preferred contractor → Tier 1 → schedules Tier 2 release |
| `send-zafto-lead-email` | Lead routed to Tier 2 | Sends "Zafto Lead" email to non-subscriber contractors |
| `submit-bid` | Contractor submits bid | Creates marketplace_bid, notifies homeowner, updates lead status |
| `accept-bid` | Homeowner accepts bid | Updates bid/lead status, creates job in contractor's CRM if subscriber |
| `score-equipment-health` | Periodic / after new data | Recalculates health scores for all equipment based on age, known issues, maintenance |
| `generate-smart-alerts` | Daily cron | Checks equipment library for age warnings, maintenance due, seasonal prep |
| `sync-recall-database` | Weekly cron | Pulls latest recalls from CPSC API, matches against scanned equipment |
| `build-knowledge-base` | After each completed repair job | Updates equipment_knowledge with actual repair data, costs, outcomes |
| `contractor-discovery` | When lead needs Tier 2 routing | Searches state licensing databases for contractors in the area |
| `lead-expiry` | Daily cron | Expires leads with no bids after 7 days, notifies homeowner |

---

## PRICING MODEL

| Who | What They Pay | What They Get |
|-----|--------------|--------------|
| **Homeowner (free)** | $0 | Equipment scanning, AI diagnosis, equipment library, basic alerts |
| **Homeowner (premium)** | $7.99/mo | Smart alerts, predictive maintenance, cost comparison, priority matching |
| **Contractor (subscriber)** | $29-149/mo (existing ZAFTO subscription) | Leads included in subscription, in-app bidding, full CRM |
| **Contractor (non-subscriber)** | Free first 3 leads | Bid via email, limited profile, no CRM access |
| **Contractor (lead-only tier)** | $19.99/mo (new tier?) | Marketplace leads + bidding only, no CRM features |

**Revenue math at scale (example: 10,000 homeowner scans/month):**
- ~30% request quotes = 3,000 leads/month
- ~60% get at least one bid = 1,800 active leads
- ~40% convert to jobs = 720 jobs/month
- Average 2.5 bids per lead × non-subscriber conversion rate 15% = ~675 new contractor trials/month
- Trial to paid conversion 10% = ~68 new subscribers/month × $79 avg = $5,372 new MRR/month
- PLUS homeowner premium conversions: 10,000 users × 8% conversion × $7.99 = $6,392/month

**The flywheel:** More scans → better AI → better leads → more contractors → more homeowners hear about it → more scans.

---

## COMPETITIVE DIFFERENTIATION

| Feature | Angi/Thumbtack | ZAFTO Marketplace |
|---------|---------------|-------------------|
| Lead context | "I need a plumber" | Exact equipment model, age, AI diagnosis, photos, symptoms |
| Contractor knows what to bring | No | Yes — parts list, model-specific tools |
| Lead quality scoring | No | Yes — 0-100 score based on 10+ factors |
| Equipment history | No | Full history from Home Portal equipment library |
| AI diagnosis before service call | No | Yes — homeowner knows probable issue before contractor arrives |
| Preferred contractor priority | No | Yes — existing relationships protected (Trust Architecture) |
| Contractor CRM integration | No | Lead → bid → accepted → job created automatically in CRM |
| Cost intelligence | None | Regional averages by equipment model, compounding data |
| Repeat business built-in | One-off leads | Equipment library generates ongoing alerts and leads for same homeowner |
| Data moat | Reviews only | Equipment knowledge base deepens with every scan and repair |

---

## INTEGRATION WITH EXISTING SYSTEMS

### Home Portal (Client Portal PWA)
- Add "Scan Equipment" button on My Home tab
- Equipment Library on My Home → Equipment page (already built, needs scan integration)
- "Get Quotes" flow on diagnosis result screen
- Bids/quotes visible on Projects tab
- Accepted bid → appears as new project with live tracker

### ZAFTO Contractor (Mobile App)
- New "Marketplace Leads" section in dashboard (role: Owner, Admin, Office)
- Lead detail screen with equipment context
- One-tap bid submission
- Accepted lead auto-creates job with equipment data pre-filled
- Field tech sees job with AI diagnosis and equipment info

### ZAFTO CRM (Web Portal)
- Leads tab in sidebar (new)
- Lead queue with filtering by trade, urgency, quality score
- Bid management
- Conversion tracking (lead → bid → job → invoice → paid)
- Revenue attribution from marketplace

### Equipment Knowledge Base
- Shared across all homeowners and contractors
- Populated initially from public data sources
- Enriched by every scan, every diagnosis, every completed repair
- This is the long-term data moat — nobody else has this

---

## RULES

1. **Trust Architecture compliance is NON-NEGOTIABLE.** Preferred contractors get 24-hour exclusive. AI never recommends switching contractors. Read Doc 16 Appendix A.
2. **AI never gives definitive diagnoses.** Always "probable issue" with confidence level. Always recommend professional inspection for safety-critical systems.
3. **Homeowner safety first.** Gas leaks, carbon monoxide risks, electrical hazards = emergency routing to ALL tiers simultaneously. No 24-hour wait.
4. **Equipment knowledge base is the moat.** Every scan, every repair, every contractor feedback enriches it. Design every interaction to capture data.
5. **"Zafto Lead" email is the #1 growth channel.** Treat it like a product — test subject lines, optimize layout, track open/click/bid rates.
6. **First 3 leads free for non-subscribers.** This is the drug dealer model — first taste is free because the product sells itself.
7. **Never sell homeowner data.** The business model is subscriptions and lead flow, not data brokering. This is a trust platform.
8. **Cold start: homeowner scanning works standalone.** Don't gate the free value behind marketplace availability.
9. **Lead expiry: 7 days.** Stale leads degrade trust. Expire them, notify homeowner, suggest re-submitting.
10. **Contractor CRM integration is automatic.** Accepted bid → job created with all equipment data. Zero manual entry. This is why they pay for the subscription.

---

## BUILD ORDER

This is a Phase 3-4 feature per the go-to-market plan in Doc 16. Do NOT build until:
- [ ] Database migration complete (Sprint 5)
- [ ] Core wiring complete (Sprint 6, W1-W3 minimum)
- [ ] Home Portal PWA functional with real data
- [ ] Equipment Passport working in client portal

Then:
1. Equipment scanning AI (extend existing scan functions)
2. Equipment knowledge base (seed with public data)
3. Diagnostic conversation flow
4. Equipment library in Home Portal
5. Lead generation engine
6. "Zafto Lead" email system
7. Contractor bidding flow (email-based first)
8. In-app bidding for subscribers
9. Smart alerts (premium feature)
10. Contractor discovery from public licensing databases
