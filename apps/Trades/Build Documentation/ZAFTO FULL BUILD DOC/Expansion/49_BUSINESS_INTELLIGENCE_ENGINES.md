# 49 — Business Intelligence Engines

> **Created**: Session 102 (2026-02-13)
> **Status**: SPEC'D — Not yet scheduled
> **Total New Tables**: ~38
> **Total New Edge Functions**: ~12
> **Total Estimated Hours**: ~340
> **API Cost at Launch**: $0/month (all free-tier or included)
> **Phase Assignment**: See per-engine breakdown below

---

## Overview

Ten intelligence engines that transform Zafto from "contractor CRM" into an autonomous business operating system. These are NOT features — they are **systems with feedback loops** that get smarter over time. Each creates a moat: the longer a contractor uses Zafto, the harder it is to leave.

### Moat Classification
| Moat Type | Engines | Why It Locks In |
|-----------|---------|-----------------|
| **Data Moat** | Job Cost Autopsy, Smart Pricing, Property Network | More data = smarter estimates/pricing. Leaving = starting from zero. |
| **Revenue Moat** | Warranty Intelligence, Predictive Maintenance, Reputation | Generates money automatically. Leaving = losing revenue streams. |
| **Operational Moat** | Permits, Compliance, Weather, Subcontractor Network | Handles complexity humans can't do manually. Leaving = operational chaos. |

### Build Order Integration
These engines slot into existing phases:
- **Phase U extensions**: Reputation Autopilot, Subcontractor Network
- **Phase GC extension**: Weather-Aware Scheduling
- **Phase P extension**: Property Intelligence Network (Digital Twin)
- **New Phase W** (post-U): Warranty Intelligence + Predictive Maintenance
- **New Phase J** (post-W): Job Cost Autopsy + Smart Pricing
- **New Phase L** (post-J): Permit Intelligence + Regulatory Compliance

**Revised build order**: T → P → SK → GC → U → W → J → L → G → E → LAUNCH

---

## ENGINE 1: WARRANTY INTELLIGENCE ENGINE

### What It Does
Tracks every product installed on every job — make, model, serial number, warranty period. Auto-calculates expiration dates across the entire customer base. Generates proactive outreach before warranties expire. Creates recurring revenue from past customers on autopilot.

### Why Nobody Has This
Warranty *dispatch* (incoming warranty jobs from home warranty companies) exists in many CRMs including Zafto (D1/D3). But tracking warranties on products YOU installed and using that data to generate callbacks? Zero competitors do this.

### How It Connects to Existing Systems
- **Jobs** → Every completed job can log installed products
- **Customers** → Warranty portfolio per customer
- **Properties** (F7 Home Portal) → `home_equipment` table gets warranty fields (extends existing)
- **Estimates** → Product from estimate auto-populates warranty record
- **Client Portal** → Homeowner sees their warranty portfolio, expiration dates
- **Notifications** → Auto-triggers at configurable intervals (6mo, 3mo, 1mo before expiry)
- **Phone/SMS (F1)** → Outreach via existing SignalWire system
- **ZBooks (D4)** → Warranty callbacks tracked as revenue in accounting

### Tables (3 new, 1 extended)
```sql
-- Extend existing home_equipment table
ALTER TABLE home_equipment ADD COLUMN IF NOT EXISTS
  warranty_start_date DATE,
  warranty_end_date DATE,
  warranty_type TEXT CHECK (warranty_type IN ('manufacturer', 'extended', 'labor', 'parts_and_labor')),
  warranty_provider TEXT,
  warranty_document_path TEXT,
  serial_number TEXT,
  model_number TEXT,
  manufacturer TEXT,
  installed_by_job_id UUID REFERENCES jobs(id),
  installed_by_company_id UUID REFERENCES companies(id),
  recall_status TEXT DEFAULT 'none' CHECK (recall_status IN ('none', 'active', 'resolved'));

-- NEW: Warranty outreach tracking
CREATE TABLE warranty_outreach_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  equipment_id UUID NOT NULL REFERENCES home_equipment(id),
  customer_id UUID NOT NULL REFERENCES customers(id),
  outreach_type TEXT NOT NULL CHECK (outreach_type IN ('sms', 'email', 'phone', 'in_app')),
  outreach_trigger TEXT NOT NULL CHECK (outreach_trigger IN ('expiry_6mo', 'expiry_3mo', 'expiry_1mo', 'recall', 'maintenance_due', 'manual')),
  message_content TEXT,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  response_status TEXT DEFAULT 'pending' CHECK (response_status IN ('pending', 'opened', 'clicked', 'booked', 'declined', 'no_response')),
  resulting_job_id UUID REFERENCES jobs(id),
  created_by UUID REFERENCES users(id)
);
-- RLS: company_id = auth.company_id()

-- NEW: Warranty claim tracking (for when warranties are used)
CREATE TABLE warranty_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  equipment_id UUID NOT NULL REFERENCES home_equipment(id),
  job_id UUID REFERENCES jobs(id),
  claim_date DATE NOT NULL,
  claim_reason TEXT NOT NULL,
  claim_status TEXT DEFAULT 'submitted' CHECK (claim_status IN ('submitted', 'approved', 'denied', 'in_progress', 'completed')),
  manufacturer_claim_number TEXT,
  resolution_notes TEXT,
  replacement_equipment_id UUID REFERENCES home_equipment(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()

-- NEW: Product recall database (seeded + community-sourced)
CREATE TABLE product_recalls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer TEXT NOT NULL,
  model_pattern TEXT NOT NULL, -- regex or LIKE pattern to match equipment
  recall_title TEXT NOT NULL,
  recall_description TEXT,
  recall_date DATE NOT NULL,
  severity TEXT CHECK (severity IN ('safety', 'performance', 'cosmetic')),
  source_url TEXT,
  affected_serial_range TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: public read, super_admin write
```

### Edge Functions (1)
| Function | Purpose | Cost |
|----------|---------|------|
| `warranty-outreach-scheduler` | CRON: Scans all equipment, finds approaching expirations, triggers outreach via SMS/email | $0 (Supabase CRON + existing SignalWire) |

### Flutter Screens (2)
- `lib/screens/warranty/warranty_portfolio_screen.dart` — List all installed products with warranty status (green/yellow/red by expiry)
- `lib/screens/warranty/warranty_detail_screen.dart` — Product detail, warranty docs, outreach history, claim history

### Web CRM Pages (2)
- `web-portal/src/app/warranty-intelligence/page.tsx` — Dashboard: expiring soon, outreach pipeline, revenue from callbacks
- `web-portal/src/app/warranty-intelligence/[id]/page.tsx` — Individual equipment warranty detail

### Client Portal (1)
- `client-portal/src/app/warranties/page.tsx` — "My Warranties" — homeowner sees all installed products, warranty status, documents

### Hooks (2)
- `use-warranty-intelligence.ts` — CRUD + real-time for warranty data, outreach log
- `use-warranty-portfolio.ts` (client portal) — Read-only warranty view for homeowners

### Sprint Estimate: ~32 hours
| Sprint | Work | Hours |
|--------|------|-------|
| W1 | Tables + migration + RLS + Dart models | 6 |
| W2 | Flutter screens + repository + providers | 8 |
| W3 | Web CRM dashboard + hook + outreach log | 8 |
| W4 | Client Portal warranty view + outreach scheduler EF | 6 |
| W5 | Testing + recall database seeding | 4 |

### API Cost: $0/month
- Outreach uses existing SignalWire (already paid for phone system)
- Recall data: CPSC API is free (Consumer Product Safety Commission)
- All processing on Supabase (existing infrastructure)

---

## ENGINE 2: JOB COST AUTOPSY ENGINE

### What It Does
After every job closes, automatically compares estimated vs actual: labor hours, material cost, drive time, callbacks, change orders. Shows true profit per job. Aggregates across job types and techs to reveal patterns. Feeds corrections back into the estimate engine.

### Why Nobody Has This
Accounting software tracks revenue. Job management tracks hours. Nobody COMBINES them into automatic post-mortem analysis with a feedback loop to improve future estimates.

### How It Connects to Existing Systems
- **Jobs** → Actual hours from time clock, actual materials from receipts/POs
- **Estimates (D8)** → Original estimate line items for comparison
- **ZBooks (D4)** → Actual costs from accounting entries
- **Time Clock** → Actual labor hours per tech per job
- **Receipts** → Actual material purchases linked to job
- **Mileage** → Drive time/distance per job
- **Callbacks** → Cost of return visits
- **Change Orders** (new, see spec 50) → Scope changes during job
- **Estimate Engine** → Feedback loop: "Adjust your bathroom rewire estimate up 12%"

### Tables (3 new)
```sql
-- NEW: Job cost autopsy — one per completed job
CREATE TABLE job_cost_autopsies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id) UNIQUE,
  -- Estimated values (snapshot from estimate at job start)
  estimated_labor_hours NUMERIC(8,2),
  estimated_labor_cost NUMERIC(10,2),
  estimated_material_cost NUMERIC(10,2),
  estimated_total NUMERIC(10,2),
  -- Actual values (calculated from time entries, receipts, mileage)
  actual_labor_hours NUMERIC(8,2),
  actual_labor_cost NUMERIC(10,2),
  actual_material_cost NUMERIC(10,2),
  actual_drive_time_hours NUMERIC(6,2),
  actual_drive_cost NUMERIC(8,2),
  actual_callback_count INTEGER DEFAULT 0,
  actual_callback_cost NUMERIC(8,2) DEFAULT 0,
  actual_change_order_total NUMERIC(10,2) DEFAULT 0,
  actual_total NUMERIC(10,2),
  -- Calculated
  gross_profit NUMERIC(10,2),
  gross_margin_pct NUMERIC(5,2),
  variance_pct NUMERIC(5,2), -- (actual - estimated) / estimated * 100
  -- Metadata
  job_type TEXT, -- denormalized for fast queries
  trade_type TEXT, -- denormalized
  primary_tech_id UUID REFERENCES users(id),
  completed_at TIMESTAMPTZ,
  autopsy_generated_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
-- INDEX: company_id, job_type, trade_type, completed_at, primary_tech_id

-- NEW: Autopsy insights — aggregated patterns
CREATE TABLE autopsy_insights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  insight_type TEXT NOT NULL CHECK (insight_type IN (
    'job_type_avg', 'tech_performance', 'seasonal_trend',
    'material_variance', 'estimate_accuracy', 'callback_rate'
  )),
  insight_key TEXT NOT NULL, -- e.g., "bathroom_rewire", "tech_mike", "Q4_2026"
  insight_data JSONB NOT NULL, -- flexible payload per insight type
  sample_size INTEGER NOT NULL,
  confidence_score NUMERIC(3,2), -- 0.00-1.00
  period_start DATE,
  period_end DATE,
  generated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
-- UNIQUE: (company_id, insight_type, insight_key, period_start)

-- NEW: Estimate adjustment suggestions
CREATE TABLE estimate_adjustments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_type TEXT NOT NULL,
  trade_type TEXT,
  adjustment_type TEXT NOT NULL CHECK (adjustment_type IN ('labor_hours', 'material_cost', 'total')),
  suggested_multiplier NUMERIC(4,2) NOT NULL, -- e.g., 1.12 = "increase 12%"
  based_on_jobs INTEGER NOT NULL, -- how many completed jobs inform this
  current_avg_variance_pct NUMERIC(5,2),
  status TEXT DEFAULT 'suggested' CHECK (status IN ('suggested', 'accepted', 'dismissed')),
  accepted_by UUID REFERENCES users(id),
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
```

### Edge Functions (1)
| Function | Purpose | Cost |
|----------|---------|------|
| `job-cost-autopsy-generator` | Triggered on job status → 'completed'. Pulls time entries, receipts, mileage, calculates autopsy. Runs insights aggregation monthly. | $0 (Supabase DB trigger + Edge Function) |

### Flutter Screens (2)
- `lib/screens/autopsy/job_autopsy_screen.dart` — Per-job breakdown: estimated vs actual bar charts, variance callouts
- `lib/screens/autopsy/autopsy_dashboard_screen.dart` — Aggregate view: profitability by job type, by tech, by month

### Web CRM Pages (3)
- `web-portal/src/app/job-intelligence/page.tsx` — Dashboard: overall profitability trends, top/bottom performers, seasonal patterns
- `web-portal/src/app/job-intelligence/[jobId]/page.tsx` — Per-job autopsy detail
- `web-portal/src/app/job-intelligence/adjustments/page.tsx` — Estimate adjustment suggestions: "Accept" to apply to future estimates

### Hooks (1)
- `use-job-intelligence.ts` — Autopsy data, insights, adjustments CRUD

### Sprint Estimate: ~36 hours
| Sprint | Work | Hours |
|--------|------|-------|
| J1 | Tables + migration + RLS + trigger function + Dart models | 8 |
| J2 | Edge Function: autopsy generator + insights aggregation | 8 |
| J3 | Flutter screens (job autopsy + dashboard) | 8 |
| J4 | Web CRM pages + hook + estimate adjustment flow | 8 |
| J5 | Testing + edge case handling (jobs with no estimate, partial data) | 4 |

### API Cost: $0/month
- All calculations are SQL aggregations on existing data
- No external APIs needed

---

## ENGINE 3: PERMIT & INSPECTION INTELLIGENCE ENGINE

### What It Does
Database of permit requirements by jurisdiction. Auto-determines what permits a job needs. Tracks permit status from application through final inspection. Records inspection outcomes and inspector notes. Community-sourced jurisdiction data gets smarter over time.

### Why Nobody Has This Integrated
PermitFlow ($$$) exists as a standalone. No contractor CRM has permit intelligence built into the job workflow. Contractors spend 2-5 hours per permitted job on phone with building departments.

### How It Connects to Existing Systems
- **Jobs** → Job type + scope auto-suggests required permits
- **Properties** → Property address determines jurisdiction
- **Schedule (GC)** → Inspection dates feed into project schedule
- **Documents** → Permit PDFs stored in documents bucket
- **Sketch Engine (SK)** → Floor plan attached to permit application
- **Estimates (D8)** → Permit fees auto-added to estimate
- **Daily Job Log** (new, see spec 50) → Inspector visits logged automatically
- **Client Portal** → Homeowner sees permit status for their project

### Tables (4 new)
```sql
-- NEW: Jurisdiction database (city/county/state rules)
CREATE TABLE permit_jurisdictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jurisdiction_name TEXT NOT NULL, -- "City of Boston", "Miami-Dade County"
  jurisdiction_type TEXT NOT NULL CHECK (jurisdiction_type IN ('city', 'county', 'state')),
  state_code CHAR(2) NOT NULL,
  county_fips TEXT,
  city_name TEXT,
  building_dept_phone TEXT,
  building_dept_url TEXT,
  online_submission_url TEXT,
  avg_permit_turnaround_days INTEGER,
  notes TEXT,
  contributed_by_company_id UUID REFERENCES companies(id), -- community-sourced
  verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: public read, any authenticated user can INSERT, super_admin can UPDATE verified

-- NEW: Permit requirements per jurisdiction per work type
CREATE TABLE permit_requirements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jurisdiction_id UUID NOT NULL REFERENCES permit_jurisdictions(id),
  work_type TEXT NOT NULL, -- 'electrical_service_upgrade', 'hvac_replacement', 'roof_replacement', etc.
  trade_type TEXT NOT NULL, -- 'electrical', 'plumbing', 'hvac', 'roofing', 'general'
  permit_required BOOLEAN DEFAULT true,
  permit_type TEXT, -- 'building', 'electrical', 'mechanical', 'plumbing'
  estimated_fee NUMERIC(8,2),
  fee_notes TEXT, -- "Based on job value: 1.5% of contract"
  inspections_required JSONB, -- ["rough_in", "final", "underground"]
  typical_documents TEXT[], -- ["plans", "load_calc", "contractor_license"]
  notes TEXT,
  contributed_by_company_id UUID REFERENCES companies(id),
  verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: public read, any authenticated user can INSERT

-- NEW: Job permits (per-job permit tracking)
CREATE TABLE job_permits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  jurisdiction_id UUID REFERENCES permit_jurisdictions(id),
  permit_type TEXT NOT NULL, -- 'electrical', 'building', 'mechanical', 'plumbing'
  permit_number TEXT,
  application_date DATE,
  approval_date DATE,
  expiration_date DATE,
  fee_amount NUMERIC(8,2),
  fee_paid BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'not_started' CHECK (status IN (
    'not_started', 'application_prepared', 'submitted', 'in_review',
    'approved', 'denied', 'expired', 'closed'
  )),
  document_path TEXT, -- path in documents bucket
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()

-- NEW: Inspection tracking
CREATE TABLE permit_inspections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_permit_id UUID NOT NULL REFERENCES job_permits(id),
  inspection_type TEXT NOT NULL, -- 'rough_in', 'final', 'underground', 'framing', etc.
  scheduled_date DATE,
  actual_date DATE,
  inspector_name TEXT,
  result TEXT CHECK (result IN ('passed', 'failed', 'partial', 'rescheduled', 'cancelled')),
  failure_reason TEXT,
  correction_notes TEXT,
  correction_completed BOOLEAN DEFAULT false,
  reinspection_date DATE,
  photos TEXT[], -- paths in documents bucket
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
```

### Edge Functions (1)
| Function | Purpose | Cost |
|----------|---------|------|
| `permit-requirement-lookup` | Given job address + work type, find jurisdiction + requirements. Geocode address → match to jurisdiction. | $0 (Supabase PostGIS + free geocoding via Nominatim OSM) |

### Flutter Screens (2)
- `lib/screens/permits/job_permits_screen.dart` — Per-job permit tracker: status timeline, inspection schedule, document upload
- `lib/screens/permits/inspection_result_screen.dart` — Log inspection result: pass/fail, notes, photos, correction needed

### Web CRM Pages (3)
- `web-portal/src/app/permits/page.tsx` — All active permits across all jobs, sortable by deadline
- `web-portal/src/app/permits/[jobId]/page.tsx` — Per-job permit detail + inspection timeline
- `web-portal/src/app/permits/jurisdictions/page.tsx` — Browse/contribute jurisdiction data

### Client Portal (1)
- `client-portal/src/app/project/[id]/permits/page.tsx` — Homeowner sees permit status for their project

### Hooks (2)
- `use-permits.ts` — CRUD for job permits, inspections, jurisdiction lookup
- `use-permit-status.ts` (client portal) — Read-only permit view

### Sprint Estimate: ~40 hours
| Sprint | Work | Hours |
|--------|------|-------|
| L1 | Tables + migration + RLS + PostGIS jurisdiction matching | 10 |
| L2 | Edge Function + jurisdiction seeding (top 50 US cities) | 8 |
| L3 | Flutter screens + repository + providers | 8 |
| L4 | Web CRM pages + hooks + jurisdiction contribution UI | 8 |
| L5 | Client Portal permit view + testing | 6 |

### API Cost: $0/month
- Nominatim (OpenStreetMap) geocoding: free, self-hostable
- PostGIS: included in Supabase PostgreSQL
- Jurisdiction data: community-sourced (gets better over time)

---

## ENGINE 4: PROPERTY INTELLIGENCE NETWORK (Digital Twin)

### What It Does
Every property Zafto touches accumulates intelligence. Electrical mapping, plumbing layout, HVAC routing, structural notes, permits, warranties, photos — all layered on a single property record. When ANY Zafto contractor returns to that property, they see everything that's been done before. Homeowner owns their property data.

### Why Nobody Has This
Single-contractor apps track YOUR work on a property. Nobody aggregates work from MULTIPLE contractors on the same property. This is a network effect play — the more contractors use Zafto in an area, the more valuable every property record becomes.

### How It Connects to Existing Systems
- **Properties (D5)** → Extends existing property tables with intelligence layers
- **Sketch Engine (SK)** → Floor plans are the visual layer of the digital twin
- **Jobs** → Every completed job adds a layer to the property
- **Photos** → All job photos geo-tagged to the property
- **Permits** (Engine 3) → Permit history per property
- **Warranties** (Engine 1) → Installed equipment per property
- **Home Portal (F7)** → `home_equipment`, `home_service_history` already exist — extend them
- **Phase P (Recon)** → Property data from scanning (ATTOM, Google Solar) feeds the twin
- **Client Portal** → Homeowner sees full property history, can share with any contractor

### Tables (3 new, 2 extended)
```sql
-- Extend existing properties table
ALTER TABLE properties ADD COLUMN IF NOT EXISTS
  property_intelligence_score INTEGER DEFAULT 0, -- 0-100, how much data we have
  year_built INTEGER,
  square_footage INTEGER,
  lot_size_sqft INTEGER,
  construction_type TEXT, -- 'wood_frame', 'masonry', 'steel', 'concrete'
  electrical_service_amps INTEGER,
  electrical_panel_type TEXT,
  plumbing_type TEXT, -- 'copper', 'pex', 'galvanized', 'cpvc', 'polybutylene'
  hvac_system_type TEXT,
  roof_type TEXT,
  roof_age_years INTEGER,
  known_issues JSONB DEFAULT '[]', -- [{issue, severity, reported_date, reported_by}]
  data_sources TEXT[] DEFAULT '{}'; -- ['attom', 'google_solar', 'contractor_input', 'homeowner_input']

-- Extend existing home_service_history
ALTER TABLE home_service_history ADD COLUMN IF NOT EXISTS
  performed_by_company_name TEXT,
  trade_type TEXT,
  work_summary TEXT,
  is_shared BOOLEAN DEFAULT false; -- homeowner opted to share with future contractors

-- NEW: Property intelligence layers (per-trade knowledge)
CREATE TABLE property_intelligence_layers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id),
  trade_type TEXT NOT NULL, -- 'electrical', 'plumbing', 'hvac', 'structural', 'roofing'
  layer_data JSONB NOT NULL, -- trade-specific structured data
  -- Electrical example: {panel_location, service_size, circuit_count, wire_type, known_issues}
  -- Plumbing example: {water_heater_type, pipe_material, main_shutoff_location, sewer_type}
  -- HVAC example: {system_type, tonnage, refrigerant_type, duct_material, filter_size}
  source_job_id UUID REFERENCES jobs(id),
  source_company_id UUID REFERENCES companies(id),
  contributed_by UUID REFERENCES users(id),
  verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: property owner can read all. Contributing company can read/write own. Other companies can read if homeowner has sharing enabled.
-- UNIQUE: (property_id, trade_type, source_company_id)

-- NEW: Property access permissions (who can see what)
CREATE TABLE property_data_sharing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id),
  homeowner_user_id UUID NOT NULL REFERENCES users(id),
  shared_with_company_id UUID REFERENCES companies(id), -- NULL = shared with all Zafto contractors
  share_level TEXT DEFAULT 'basic' CHECK (share_level IN ('none', 'basic', 'full')),
  -- basic = property facts only. full = all layers, photos, history
  granted_at TIMESTAMPTZ DEFAULT now(),
  revoked_at TIMESTAMPTZ
);
-- RLS: homeowner_user_id = auth.uid() for management. shared_with_company_id = auth.company_id() for reading.

-- NEW: Property age alerts (year_built + material type → proactive alerts)
CREATE TABLE property_age_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_rule_name TEXT NOT NULL, -- 'aluminum_wiring_pre_1978', 'polybutylene_pipe_1978_1995'
  condition_json JSONB NOT NULL, -- {year_built_before: 1978, or: {plumbing_type: 'polybutylene'}}
  alert_message TEXT NOT NULL,
  severity TEXT CHECK (severity IN ('info', 'warning', 'critical')),
  trade_type TEXT NOT NULL,
  recommendation TEXT,
  active BOOLEAN DEFAULT true
);
-- RLS: public read, super_admin write
```

### Edge Functions (1)
| Function | Purpose | Cost |
|----------|---------|------|
| `property-intelligence-score` | Recalculates intelligence score when new data added. Checks age alerts on property access. | $0 |

### Sprint Estimate: ~28 hours
| Sprint | Work | Hours |
|--------|------|-------|
| P-EXT1 | Table extensions + new tables + migration + RLS | 8 |
| P-EXT2 | Intelligence layer contribution flow (Flutter + Web) | 8 |
| P-EXT3 | Property detail enhancement (show layers, alerts, history) | 8 |
| P-EXT4 | Data sharing UI (Client Portal) + testing | 4 |

### API Cost: $0/month
- ATTOM property data: already planned for Phase P
- All processing on-device/Supabase

---

## ENGINE 5: WEATHER-AWARE SCHEDULING ENGINE

### What It Does
Integrates weather forecasts into the job schedule. Each trade/job type has weather rules (roofers can't work in rain, concrete can't cure below 40°F). Auto-flags at-risk jobs 3-5 days out. Suggests reschedule options. Tracks weather-related delays for job costing accuracy.

### How It Connects to Existing Systems
- **Schedule (GC Phase)** → Weather overlay on Gantt/calendar view
- **Jobs** → Job type determines weather sensitivity rules
- **Notifications** → Auto-alert techs/office when weather threatens
- **Job Cost Autopsy** (Engine 2) → Weather delays tracked as variance reason
- **Daily Job Log** (Spec 50) → Auto-captures weather conditions
- **Client Portal** → Customer notified of weather-related reschedule

### Tables (2 new)
```sql
-- NEW: Weather rules per trade/job type
CREATE TABLE weather_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id), -- NULL = system defaults
  trade_type TEXT NOT NULL,
  job_type_pattern TEXT, -- 'roof_replacement', 'concrete_pour', '*' for all
  rule_name TEXT NOT NULL,
  condition_json JSONB NOT NULL,
  -- Examples:
  -- {precipitation_probability_gt: 40, wind_speed_gt: null, temp_min: null}
  -- {precipitation_probability_gt: null, wind_speed_gt: 25, temp_min: null}
  -- {precipitation_probability_gt: null, wind_speed_gt: null, temp_min: 40, temp_min_duration_hours: 48}
  severity TEXT DEFAULT 'warning' CHECK (severity IN ('info', 'warning', 'block')),
  -- block = auto-flag for reschedule. warning = notify but allow. info = log only.
  message_template TEXT, -- "Rain forecast ({{probability}}%) — consider rescheduling"
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id() OR company_id IS NULL (system defaults readable by all)

-- NEW: Weather alerts on scheduled jobs
CREATE TABLE weather_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  scheduled_date DATE NOT NULL,
  rule_id UUID REFERENCES weather_rules(id),
  weather_data JSONB NOT NULL, -- {temp_high, temp_low, precipitation_pct, wind_mph, conditions}
  alert_level TEXT NOT NULL CHECK (alert_level IN ('info', 'warning', 'block')),
  alert_message TEXT NOT NULL,
  acknowledged BOOLEAN DEFAULT false,
  acknowledged_by UUID REFERENCES users(id),
  action_taken TEXT CHECK (action_taken IN ('proceed', 'reschedule', 'cancel')),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
```

### Edge Functions (1)
| Function | Purpose | Cost |
|----------|---------|------|
| `weather-schedule-scanner` | CRON (daily 6AM): Fetch 5-day forecast for all scheduled job locations. Evaluate rules. Create alerts. | $0 (Open-Meteo API: free, no API key, unlimited requests) |

### Sprint Estimate: ~20 hours
| Sprint | Work | Hours |
|--------|------|-------|
| GC-EXT1 | Tables + migration + RLS + weather rules seeding (10 trades) | 6 |
| GC-EXT2 | Edge Function: Open-Meteo integration + rule evaluation | 6 |
| GC-EXT3 | Schedule UI overlay (Flutter + Web) — weather icons on calendar | 4 |
| GC-EXT4 | Alert management + reschedule flow + testing | 4 |

### API Cost: $0/month
- **Open-Meteo**: Free, open-source, no API key, no rate limit, global coverage
- No paid weather APIs needed

---

## ENGINE 6: REPUTATION AUTOPILOT ENGINE

### What It Does
Auto-triggers review requests at the perfect moment (job complete + payment received + configurable delay). Sentiment gate: quick satisfaction check first — happy customers route to Google/Yelp, unhappy ones route to private feedback. Tracks review velocity, star averages, and ties reviews to specific jobs/techs.

### How It Connects to Existing Systems
- **Jobs** → Trigger after job status = 'completed' + invoice status = 'paid'
- **Customers** → Review history per customer
- **Phone/SMS (F1)** → Review request sent via SMS (highest open rate)
- **Team Portal** → Techs see their review scores
- **Phase U** → Already has "review system" planned — this replaces it with the FULL engine
- **Ops Portal** → Company-wide review analytics

### Tables (3 new)
```sql
-- NEW: Review requests sent
CREATE TABLE review_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  customer_id UUID NOT NULL REFERENCES customers(id),
  sent_via TEXT NOT NULL CHECK (sent_via IN ('sms', 'email', 'in_app')),
  sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  satisfaction_response INTEGER, -- 1-5 quick rating
  satisfaction_responded_at TIMESTAMPTZ,
  routed_to TEXT, -- 'google', 'yelp', 'private_feedback', NULL if no response
  external_review_confirmed BOOLEAN DEFAULT false,
  private_feedback TEXT,
  follow_up_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()

-- NEW: Review tracking (confirmed external reviews)
CREATE TABLE review_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  platform TEXT NOT NULL CHECK (platform IN ('google', 'yelp', 'facebook', 'bbb', 'angi', 'thumbtack', 'other')),
  reviewer_name TEXT,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  review_date DATE,
  linked_job_id UUID REFERENCES jobs(id),
  linked_tech_id UUID REFERENCES users(id),
  response_text TEXT,
  response_date DATE,
  source TEXT DEFAULT 'manual' CHECK (source IN ('manual', 'api', 'scrape')),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()

-- NEW: Review analytics (aggregated monthly)
CREATE TABLE review_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  period_month DATE NOT NULL, -- first of month
  total_reviews INTEGER DEFAULT 0,
  avg_rating NUMERIC(2,1),
  five_star_count INTEGER DEFAULT 0,
  one_star_count INTEGER DEFAULT 0,
  review_request_sent INTEGER DEFAULT 0,
  review_request_response_rate NUMERIC(4,2),
  platform_breakdown JSONB, -- {google: 5, yelp: 2, facebook: 1}
  top_tech_id UUID REFERENCES users(id),
  top_tech_avg NUMERIC(2,1),
  generated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
-- UNIQUE: (company_id, period_month)
```

### Edge Functions (1)
| Function | Purpose | Cost |
|----------|---------|------|
| `review-request-engine` | Trigger: job completed + paid + delay elapsed. Sends SMS/email. Routes based on satisfaction score. Monthly analytics aggregation. | $0 (uses existing SignalWire + SendGrid) |

### Sprint Estimate: ~28 hours
| Sprint | Work | Hours |
|--------|------|-------|
| U-REP1 | Tables + migration + RLS + review request trigger | 6 |
| U-REP2 | Review request flow: SMS → satisfaction gate → routing | 8 |
| U-REP3 | CRM dashboard: review velocity, tech scores, trends | 6 |
| U-REP4 | Team Portal: tech review scores. Manual review entry. | 4 |
| U-REP5 | Testing + analytics aggregation | 4 |

### API Cost: $0/month
- SMS via existing SignalWire
- Google Business Profile API: free (read reviews, post responses)
- Yelp Fusion API: free tier (read reviews)

---

## ENGINE 7: SMART PRICING ENGINE

### What It Does
Dynamic pricing suggestions based on demand (schedule fullness), season, drive distance, job complexity, and anonymous market rates from the Zafto network. Contractor sets rules and caps — system suggests, human approves. Not surge pricing — intelligent pricing that prevents leaving money on the table.

### How It Connects to Existing Systems
- **Estimates (D8)** → Pricing suggestions appear during estimate creation
- **Schedule** → Schedule fullness drives demand multiplier
- **Jobs** → Historical close rate at different price points
- **Mileage** → Drive distance auto-calculated
- **Job Cost Autopsy** (Engine 2) → Actual margin data feeds pricing decisions
- **ZBooks (D4)** → Revenue impact tracking

### Tables (2 new)
```sql
-- NEW: Pricing rules per company
CREATE TABLE pricing_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  rule_type TEXT NOT NULL CHECK (rule_type IN (
    'demand_multiplier', 'distance_surcharge', 'seasonal_adjustment',
    'urgency_tier', 'complexity_factor', 'market_adjustment'
  )),
  rule_config JSONB NOT NULL,
  -- demand_multiplier: {schedule_pct_threshold: 80, multiplier: 1.15, max_multiplier: 1.30}
  -- distance_surcharge: {base_miles: 15, per_mile_over: 1.50, max_surcharge: 75}
  -- seasonal_adjustment: {months: [6,7,8], trade: "hvac", multiplier: 1.20}
  -- urgency_tier: {emergency_2hr: 1.50, priority_same_day: 1.25, standard: 1.00}
  -- market_adjustment: {enabled: true, max_deviation_pct: 15}
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()

-- NEW: Pricing suggestions log (what was suggested, what was accepted)
CREATE TABLE pricing_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  estimate_id UUID REFERENCES estimates(id),
  job_id UUID REFERENCES jobs(id),
  base_price NUMERIC(10,2) NOT NULL,
  suggested_price NUMERIC(10,2) NOT NULL,
  factors_applied JSONB NOT NULL, -- [{rule_type, multiplier, reason}]
  final_price NUMERIC(10,2), -- what the contractor actually used
  accepted BOOLEAN,
  job_won BOOLEAN, -- did they close the deal?
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
```

### Sprint Estimate: ~28 hours
| Sprint | Work | Hours |
|--------|------|-------|
| J3 | Tables + migration + RLS + pricing rule defaults per trade | 6 |
| J4 | Pricing calculation engine (Edge Function or client-side) | 8 |
| J5 | Estimate UI integration: "Suggested price: $X" with breakdown | 8 |
| J6 | Settings: rule configuration + pricing history analytics | 6 |

### API Cost: $0/month
- All calculations local
- Market rates from anonymous Zafto network (opt-in aggregation)

---

## ENGINE 8: REGULATORY COMPLIANCE AUTOPILOT

### What It Does
Tracks ALL compliance across the company: business licenses, trade licenses per employee, insurance policies, bonds, vehicle registrations, OSHA certs, EPA certs, CE credits. Auto-alerts before expiration. Generates compliance packets for GC requirements.

### How It Connects to Existing Systems
- **Certifications (D7a)** → Extends existing certification tracking (already has expiry countdown, renewal reminders)
- **Fleet (F5)** → Vehicle registration tracking
- **Team Portal** → Employees see their compliance status
- **HR (F5)** → `hr_documents` table extended for compliance documents
- **Documents** → Compliance docs stored in documents bucket
- **Jobs** → "This job requires EPA lead-safe cert — Tech Mike has it, Tech Dave doesn't"

### Tables (2 new, 1 extended)
```sql
-- Extend existing certifications to be the unified compliance tracker
-- Already has: type, expiry, status. Add:
ALTER TABLE certifications ADD COLUMN IF NOT EXISTS
  compliance_category TEXT DEFAULT 'trade_license' CHECK (compliance_category IN (
    'trade_license', 'business_license', 'insurance_policy', 'bond',
    'vehicle_registration', 'osha_cert', 'epa_cert', 'ce_credit',
    'background_check', 'drug_test', 'first_aid', 'other'
  )),
  issuing_authority TEXT,
  policy_number TEXT,
  coverage_amount NUMERIC(12,2),
  renewal_cost NUMERIC(8,2),
  auto_renew BOOLEAN DEFAULT false,
  document_path TEXT;

-- NEW: Compliance requirements per job type
CREATE TABLE compliance_requirements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trade_type TEXT NOT NULL,
  job_type_pattern TEXT, -- 'lead_abatement', 'refrigerant_*', '*'
  required_compliance_category TEXT NOT NULL,
  required_certification_type TEXT, -- specific cert type name
  description TEXT,
  regulatory_reference TEXT, -- "EPA 40 CFR Part 745", "OSHA 29 CFR 1926"
  penalty_description TEXT, -- "Fine up to $44,539 per day"
  active BOOLEAN DEFAULT true
);
-- RLS: public read

-- NEW: Compliance packets (generated documents for GCs)
CREATE TABLE compliance_packets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  packet_name TEXT NOT NULL, -- "Insurance & License Packet for [GC Name]"
  requested_by TEXT, -- GC name or entity
  documents JSONB NOT NULL, -- [{cert_id, type, document_path}]
  generated_at TIMESTAMPTZ DEFAULT now(),
  shared_via TEXT, -- 'email', 'link', 'download'
  shared_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ
);
-- RLS: company_id = auth.company_id()
```

### Edge Functions (1)
| Function | Purpose | Cost |
|----------|---------|------|
| `compliance-scanner` | CRON weekly: Check all certs/licenses/policies for approaching expiration. Alert at 90/60/30 days. Check job assignments against compliance requirements. | $0 |

### Sprint Estimate: ~24 hours
| Sprint | Work | Hours |
|--------|------|-------|
| L3 | Table extensions + new tables + migration + RLS | 6 |
| L4 | Compliance dashboard (CRM) — all company compliance at a glance | 6 |
| L5 | Compliance packet generator + sharing | 4 |
| L6 | Job compliance checker + employee compliance view (Team Portal) | 4 |
| L7 | Testing + requirement seeding (EPA, OSHA, common state reqs) | 4 |

### API Cost: $0/month
- All local processing
- Compliance requirements: manually curated + community-sourced

---

## ENGINE 9: PREDICTIVE MAINTENANCE ENGINE (F7 Upgrade)

### What It Does
Based on installed equipment age, typical failure curves, and maintenance history — predicts when equipment will need service. Generates proactive outreach. Enables maintenance plan subscriptions. Turns past customers into recurring revenue.

### How It Connects to Existing Systems
- **Home Equipment (F7)** → Already has `home_equipment`, `home_maintenance_schedules` tables
- **Warranty Intelligence** (Engine 1) → Warranty data feeds prediction
- **Jobs** → Maintenance visits create new jobs
- **Phone/SMS (F1)** → Outreach via existing system
- **Client Portal** → Homeowner sees upcoming maintenance recommendations
- **ZBooks (D4)** → Maintenance plan revenue tracked

### Tables (2 new, extending F7)
```sql
-- NEW: Equipment failure curves (reference data)
CREATE TABLE equipment_lifecycle_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_category TEXT NOT NULL, -- 'water_heater_gas', 'hvac_condenser', 'electrical_panel'
  manufacturer TEXT, -- NULL for generic curves
  avg_lifespan_years NUMERIC(4,1) NOT NULL,
  maintenance_interval_months INTEGER, -- recommended maintenance frequency
  common_failure_modes JSONB, -- [{mode, typical_age_years, symptoms, urgency}]
  seasonal_maintenance TEXT[], -- ['spring', 'fall'] for HVAC tune-ups
  source TEXT, -- 'manufacturer', 'industry_avg', 'zafto_network'
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: public read, super_admin write

-- NEW: Maintenance predictions (generated per equipment)
CREATE TABLE maintenance_predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  equipment_id UUID NOT NULL REFERENCES home_equipment(id),
  customer_id UUID NOT NULL REFERENCES customers(id),
  prediction_type TEXT NOT NULL CHECK (prediction_type IN (
    'routine_maintenance', 'approaching_end_of_life', 'seasonal_service',
    'warranty_expiring', 'recall_alert'
  )),
  predicted_date DATE NOT NULL,
  confidence_score NUMERIC(3,2), -- 0.00-1.00
  recommended_action TEXT NOT NULL,
  estimated_cost NUMERIC(8,2),
  outreach_status TEXT DEFAULT 'pending' CHECK (outreach_status IN (
    'pending', 'sent', 'booked', 'declined', 'completed'
  )),
  resulting_job_id UUID REFERENCES jobs(id),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
```

### Edge Functions (1)
| Function | Purpose | Cost |
|----------|---------|------|
| `predictive-maintenance-engine` | CRON monthly: Scan all equipment, calculate age vs lifecycle curves, generate predictions, trigger outreach for upcoming items. | $0 |

### Sprint Estimate: ~24 hours
| Sprint | Work | Hours |
|--------|------|-------|
| W3 | Tables + migration + RLS + lifecycle data seeding (50+ equipment types) | 6 |
| W4 | Prediction engine Edge Function + outreach trigger | 8 |
| W5 | CRM dashboard: upcoming maintenance pipeline, revenue forecast | 6 |
| W6 | Client Portal: "Recommended Maintenance" section + testing | 4 |

### API Cost: $0/month
- All on-device calculation
- Lifecycle data: industry averages + manufacturer specs (publicly available)
- Outreach via existing SignalWire

---

## ENGINE 10: SUBCONTRACTOR NETWORK ENGINE

### What It Does
Verified sub network within Zafto. GCs and primes can send bid requests to subs with shared project data (sketch, scope, schedule). Sub performance ratings. Auto-generated sub agreements. Payment tracking for subs tied to main job billing.

### How It Connects to Existing Systems
- **Jobs** → Sub assigned to specific job or portion
- **Schedule (GC)** → Sub availability synced with project timeline
- **Sketch Engine (SK)** → Floor plans shared with subs (read-only)
- **Estimates** → Sub bid incorporated into main estimate
- **ZBooks (D4)** → Sub payments tracked as job costs
- **Mechanic's Lien** (Spec 50) → Lien waiver collection from subs
- **Compliance** (Engine 8) → Sub license/insurance verification
- **Phase U** → Already has "subcontractor management" planned — this replaces it with the FULL engine

### Tables (4 new)
```sql
-- NEW: Subcontractor profiles (companies registered as subs)
CREATE TABLE subcontractor_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id), -- the sub's company
  trade_types TEXT[] NOT NULL, -- ['plumbing', 'hvac']
  service_area_radius_miles INTEGER DEFAULT 50,
  service_area_center_lat NUMERIC(9,6),
  service_area_center_lng NUMERIC(9,6),
  hourly_rate NUMERIC(8,2),
  available_for_bids BOOLEAN DEFAULT true,
  license_verified BOOLEAN DEFAULT false,
  insurance_verified BOOLEAN DEFAULT false,
  insurance_expiry DATE,
  avg_rating NUMERIC(2,1),
  total_jobs_completed INTEGER DEFAULT 0,
  profile_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id() for write. visible profiles readable by all authenticated.

-- NEW: Sub bid requests
CREATE TABLE sub_bid_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requesting_company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  trade_type TEXT NOT NULL,
  scope_description TEXT NOT NULL,
  budget_range_low NUMERIC(10,2),
  budget_range_high NUMERIC(10,2),
  needed_by DATE,
  shared_documents JSONB, -- [{type: 'floor_plan', path: '...'}, {type: 'scope', path: '...'}]
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'reviewing', 'awarded', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ
);
-- RLS: requesting_company_id = auth.company_id() for write.

-- NEW: Sub bid responses
CREATE TABLE sub_bid_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bid_request_id UUID NOT NULL REFERENCES sub_bid_requests(id),
  sub_company_id UUID NOT NULL REFERENCES companies(id),
  bid_amount NUMERIC(10,2) NOT NULL,
  estimated_duration_days INTEGER,
  scope_notes TEXT,
  availability_start DATE,
  status TEXT DEFAULT 'submitted' CHECK (status IN ('submitted', 'shortlisted', 'awarded', 'rejected', 'withdrawn')),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: sub_company_id = auth.company_id() for write. requesting company can read.

-- NEW: Sub performance ratings
CREATE TABLE sub_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rated_company_id UUID NOT NULL REFERENCES companies(id), -- the sub being rated
  rating_company_id UUID NOT NULL REFERENCES companies(id), -- the GC/prime doing the rating
  job_id UUID NOT NULL REFERENCES jobs(id),
  quality_rating INTEGER CHECK (quality_rating BETWEEN 1 AND 5),
  timeliness_rating INTEGER CHECK (timeliness_rating BETWEEN 1 AND 5),
  communication_rating INTEGER CHECK (communication_rating BETWEEN 1 AND 5),
  overall_rating INTEGER CHECK (overall_rating BETWEEN 1 AND 5),
  would_hire_again BOOLEAN,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: rating_company_id = auth.company_id() for write. rated_company can read own ratings.
```

### Sprint Estimate: ~36 hours
| Sprint | Work | Hours |
|--------|------|-------|
| U-SUB1 | Tables + migration + RLS + sub profile registration flow | 8 |
| U-SUB2 | Bid request creation + sub discovery (search by trade/area) | 8 |
| U-SUB3 | Bid response flow + comparison + award | 8 |
| U-SUB4 | Sub payment tracking + lien waiver integration | 6 |
| U-SUB5 | Rating system + sub performance dashboard + testing | 6 |

### API Cost: $0/month
- PostGIS for geographic matching (included in Supabase)
- All processing local

---

## GRAND TOTALS

| Engine | Phase | Tables | EFs | Hours |
|--------|-------|--------|-----|-------|
| 1. Warranty Intelligence | W | 3+ext | 1 | 32 |
| 2. Job Cost Autopsy | J | 3 | 1 | 36 |
| 3. Permit & Inspection Intelligence | L | 4 | 1 | 40 |
| 4. Property Intelligence Network | P-ext | 3+ext | 1 | 28 |
| 5. Weather-Aware Scheduling | GC-ext | 2 | 1 | 20 |
| 6. Reputation Autopilot | U-ext | 3 | 1 | 28 |
| 7. Smart Pricing | J | 2 | 0 | 28 |
| 8. Regulatory Compliance | L | 2+ext | 1 | 24 |
| 9. Predictive Maintenance | W | 2 | 1 | 24 |
| 10. Subcontractor Network | U-ext | 4 | 0 | 36 |
| **TOTALS** | | **~38** | **~8** | **~296** |

### API Cost Summary: $0/month at launch
| API | Used By | Cost |
|-----|---------|------|
| Open-Meteo | Weather Engine | Free, no API key |
| Nominatim (OSM) | Permit Engine geocoding | Free, self-hostable |
| CPSC Recalls API | Warranty Engine | Free (US government) |
| Google Business Profile | Reputation Engine | Free tier |
| Yelp Fusion | Reputation Engine | Free tier |
| SignalWire | Outreach (Warranty, Reputation, Predictive) | Already paying for phone system |
| PostGIS | Sub Network, Permits | Included in Supabase |
| Supabase CRON | All scheduled engines | Included in plan |

---

## Phase Integration Map

```
EXISTING PHASES (already planned):
  T → P → SK → GC → U → G → E → LAUNCH

WITH ENGINE EXTENSIONS:
  T → P [+Digital Twin ext] → SK → GC [+Weather ext] → U [+Reputation +SubNetwork ext]
    → W [Warranty + Predictive] → J [Job Autopsy + Smart Pricing]
    → L [Permits + Compliance] → G → E → LAUNCH

TOTAL NEW HOURS: ~296
```

Each engine extension is designed to be built AFTER its parent phase, using existing tables and infrastructure. No engine requires AI (all are rule-based + data aggregation), so they respect the "AI goes LAST" rule.
