# ZAFTO JOB TYPE SYSTEM
## Standard · Insurance Claim · Warranty Dispatch
### February 5, 2026 — LOCKED SPECIFICATION

---

## ONE SENTENCE

Every job in ZAFTO has a type — `standard`, `insurance_claim`, or `warranty_dispatch` — that
controls which workflow, fields, and integrations appear. Contractors who don't use insurance
or warranty work never see them. Contractors who do get everything in one place.

---

## THE RULE

```
The base experience is ALWAYS clean.

A solo electrician doing retail work sees:
  Lead → Bid → Accepted → Scheduled → In Progress → Complete → Invoice → Paid

That's it. No insurance fields. No warranty dropdowns. No carrier panels.
No clutter. No confusion. No "what is this?"

Insurance and warranty features activate PER JOB, not globally.
One field on the job record controls everything: job_type.
```

---

## JOB TYPES

| Type | Who Uses It | Payer | Workflow Source |
|------|-------------|-------|----------------|
| `standard` | Every contractor, every trade | Customer pays directly | Trade default pipeline |
| `insurance_claim` | Restoration, roofing, GC, remodeler, any trade | Carrier pays + homeowner deductible | Insurance pipeline (from 36_RESTORATION_INSURANCE_MODULE.md) |
| `warranty_dispatch` | Plumbing, HVAC, electrical, roofing, appliance | Warranty company pays (minus service fee) | Warranty pipeline (defined below) |

---

## HOW IT WORKS

### Job Creation Flow

```
Contractor taps [+ New Job]

Step 1: Customer info, address, trade, description
        (identical for all job types — clean, simple)

Step 2: Job Type selector (only if enabled in company settings)

        ┌─────────────────────────────────────────┐
        │  Job Type                                │
        │                                          │
        │  ● Standard Job                          │
        │  ○ Insurance Claim                       │
        │  ○ Warranty Dispatch                     │
        │                                          │
        └─────────────────────────────────────────┘

        If company has never enabled insurance or warranty:
        This selector doesn't appear. job_type defaults to "standard".
        Zero friction for contractors who don't need it.

Step 3: Type-specific fields expand BELOW the selector
        Standard:   Nothing extra. Done.
        Insurance:  Carrier, claim #, date of loss, adjuster, deductible
        Warranty:   Warranty company, dispatch #, authorization limit, service fee
```

### Progressive Disclosure

```
LEVEL 0 — NEW CONTRACTOR (default)
  Job type selector: HIDDEN
  All jobs are standard. Simplest possible experience.
  Company settings show: "Enable Insurance Claims" and "Enable Warranty Dispatch"
  toggles — both OFF by default.

LEVEL 1 — CONTRACTOR ENABLES INSURANCE
  Company Settings → Modules → Insurance Claims → ON
  Job type selector now shows: Standard | Insurance Claim
  Insurance carrier management appears in Settings
  Xactimate TPI connection available in Integrations

LEVEL 2 — CONTRACTOR ENABLES WARRANTY
  Company Settings → Modules → Warranty Dispatch → ON
  Job type selector now shows: Standard | Warranty Dispatch
  Warranty company directory appears in Settings
  (Can be enabled alongside insurance for all three types)

LEVEL 3 — BOTH ENABLED
  Job type selector shows all three options
  Dashboard shows revenue breakdown by type
  Calendar color-codes by job type
```

---

## SCHEMA

### Core Addition (to existing jobs table)

```sql
-- Add to jobs table (29_DATABASE_MIGRATION.md)
-- These fields exist on EVERY job but only populate when relevant

ALTER TABLE jobs ADD COLUMN job_type TEXT NOT NULL DEFAULT 'standard'
  CHECK (job_type IN ('standard', 'insurance_claim', 'warranty_dispatch'));

ALTER TABLE jobs ADD COLUMN is_insurance_claim BOOLEAN
  GENERATED ALWAYS AS (job_type = 'insurance_claim') STORED;

ALTER TABLE jobs ADD COLUMN is_warranty_dispatch BOOLEAN
  GENERATED ALWAYS AS (job_type = 'warranty_dispatch') STORED;
```

### Warranty Dispatch Tables (New)

```sql
-- ============================================================
-- WARRANTY DISPATCH MODULE — SUPABASE SCHEMA
-- Companion to insurance_claims in 36_RESTORATION_INSURANCE_MODULE.md
-- ============================================================

-- Warranty company directory (shared across all companies)
CREATE TABLE warranty_companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,                        -- "American Home Shield", "Frontdoor", etc.
  short_name TEXT,                           -- "AHS", "FNHW", "SHW"
  type TEXT DEFAULT 'home_warranty',         -- home_warranty, appliance_warranty, builder_warranty
  phone TEXT,
  email TEXT,
  website TEXT,
  contractor_portal_url TEXT,                -- Where contractors log in to manage dispatches
  payment_terms_days INTEGER DEFAULT 14,     -- Most warranty cos pay within 10-14 days
  service_fee_default DECIMAL(8,2),          -- Typical homeowner service call fee ($75-150)
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Company-specific warranty relationships
CREATE TABLE company_warranty_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  warranty_company_id UUID NOT NULL REFERENCES warranty_companies(id),

  -- Contractor's identity with this warranty company
  contractor_id_with_warranty TEXT,          -- Their vendor/contractor ID in the warranty system
  trades_registered TEXT[],                  -- Which trades they're approved for with this company
  service_area_zips TEXT[],                  -- Zip codes they cover for this warranty company

  -- Performance
  avg_response_hours DECIMAL(5,1),
  avg_completion_days DECIMAL(5,1),
  total_dispatches_completed INTEGER DEFAULT 0,
  total_revenue DECIMAL(12,2) DEFAULT 0,
  satisfaction_score DECIMAL(3,2),           -- From warranty company scorecards

  -- Status
  status TEXT DEFAULT 'active',              -- active, suspended, pending_approval
  approved_date DATE,

  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(company_id, warranty_company_id)
);

ALTER TABLE company_warranty_relationships ENABLE ROW LEVEL SECURITY;
CREATE POLICY "company_warranty_rel_isolation" ON company_warranty_relationships
  USING (company_id = current_setting('app.company_id')::UUID);

-- Warranty dispatches (linked to jobs — ONE dispatch per job)
CREATE TABLE warranty_dispatches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  warranty_company_id UUID REFERENCES warranty_companies(id),

  -- Dispatch identifiers
  dispatch_number TEXT,                      -- Warranty company's work order / dispatch ID
  claim_number TEXT,                         -- Warranty company's claim reference
  authorization_number TEXT,                 -- Pre-auth code for the work

  -- Homeowner (may differ from job contact if tenant vs owner)
  warranty_holder_name TEXT,
  warranty_holder_phone TEXT,
  warranty_holder_email TEXT,
  contract_number TEXT,                      -- Homeowner's warranty contract #
  contract_type TEXT,                        -- Plan tier (bronze, gold, platinum, etc.)

  -- Property
  property_type TEXT,                        -- residential, condo, townhome
  property_age_years INTEGER,

  -- Problem
  issue_type TEXT,                           -- plumbing, electrical, hvac, appliance, etc.
  issue_description TEXT,
  equipment_brand TEXT,                      -- Brand of the broken unit
  equipment_model TEXT,
  equipment_serial TEXT,
  equipment_age_years INTEGER,

  -- Authorization
  authorization_limit DECIMAL(10,2),         -- Max $ approved for repair
  requires_pre_auth BOOLEAN DEFAULT FALSE,   -- Need to call before exceeding limit
  pre_auth_threshold DECIMAL(10,2),          -- $ amount that triggers pre-auth call

  -- Diagnosis
  diagnosis TEXT,                            -- Contractor's finding
  diagnosis_date TIMESTAMPTZ,
  repair_or_replace TEXT,                    -- repair, replace, denied, not_covered
  denial_reason TEXT,                        -- If warranty company denies coverage

  -- Financials
  service_fee DECIMAL(8,2),                  -- Homeowner pays this at door ($75-150)
  service_fee_collected BOOLEAN DEFAULT FALSE,
  service_fee_collected_date TIMESTAMPTZ,
  parts_cost DECIMAL(10,2),
  labor_cost DECIMAL(10,2),
  total_invoice DECIMAL(10,2),               -- What warranty company pays contractor
  warranty_company_paid DECIMAL(10,2) DEFAULT 0,
  payment_date TIMESTAMPTZ,

  -- Out-of-pocket (work not covered by warranty)
  oop_amount DECIMAL(10,2) DEFAULT 0,        -- Homeowner pays for non-covered work
  oop_collected BOOLEAN DEFAULT FALSE,
  oop_description TEXT,                      -- What the extra charge covers

  -- Status
  status TEXT NOT NULL DEFAULT 'dispatched',
  -- dispatched → scheduled → diagnosed → authorized → in_progress →
  -- complete → invoiced → paid → closed
  -- also: denied, recalled, cancelled

  -- Dates
  dispatched_date TIMESTAMPTZ,
  scheduled_date TIMESTAMPTZ,
  diagnosed_date TIMESTAMPTZ,
  authorized_date TIMESTAMPTZ,
  completed_date TIMESTAMPTZ,
  invoiced_date TIMESTAMPTZ,
  paid_date TIMESTAMPTZ,

  -- Recall tracking (warranty company sends contractor back)
  is_recall BOOLEAN DEFAULT FALSE,
  original_dispatch_id UUID REFERENCES warranty_dispatches(id),
  recall_reason TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id),

  UNIQUE(company_id, job_id)
);

ALTER TABLE warranty_dispatches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "warranty_dispatch_isolation" ON warranty_dispatches
  USING (company_id = current_setting('app.company_id')::UUID);
```

### Company Settings Addition

```sql
-- Add to companies table or company_settings
ALTER TABLE companies ADD COLUMN insurance_module_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE companies ADD COLUMN warranty_module_enabled BOOLEAN DEFAULT FALSE;
```

---

## WORKFLOWS

### Standard Job (Default — 8 Stages)

```
Lead → Bid Sent → Accepted → Scheduled → In Progress → Complete → Invoiced → Paid
```

No changes. This is what exists today.

### Insurance Claim Workflow

Defined per-trade in `36_RESTORATION_INSURANCE_MODULE.md`. Examples:

```
Restoration (17 stages):
  Loss Report → Emergency Dispatch → Mitigation Active → Drying →
  Drying Complete → Scope of Loss → Estimate Submitted → Adjuster Review →
  Approved → Supplement Pending → Reconstruction Bid → Reconstruction Active →
  Final Walkthrough → Certificate Issued → Insurance Paid →
  Deductible Collected → Closed

Roofing Insurance (13 stages):
  Inspection → Claim Filed → Adjuster Meeting → Estimate Submitted →
  Supplement Pending → Approved → Materials Ordered → Scheduled →
  In Progress → Complete → Insurance Paid → Deductible Collected → Closed
```

### Warranty Dispatch Workflow (New — 10 Stages)

```
Dispatched → Scheduled → Diagnosed → Authorized → In Progress →
Complete → Invoiced → Paid → Closed

  Branch: Diagnosed → Denied (warranty doesn't cover it)
  Branch: Complete → Recalled (sent back to fix)
```

```
STAGE DETAILS:

dispatched
  Warranty company sends the job. ZAFTO creates it.
  Contractor sees: homeowner info, issue description, warranty plan type.
  SLA: Contact homeowner within 4 hours, schedule within 24 hours.

scheduled
  Contractor books appointment with homeowner.
  Calendar event auto-created. Homeowner notified via client portal.

diagnosed
  Contractor arrives, assesses the problem.
  Records: diagnosis, equipment brand/model/serial/age, photos.
  Determines: repair, replace, or not covered.

authorized
  If under authorization limit → auto-advance.
  If over limit → contractor calls warranty company for pre-auth.
  Authorization number recorded. Approved amount confirmed.

  (branch: denied)
  Warranty company says not covered.
  Contractor presents homeowner with retail repair option.
  Job can convert to standard type if homeowner wants to pay out of pocket.

in_progress
  Work being done. Parts ordered if needed.
  Photos of work in progress.

complete
  Work finished. Final photos taken.
  Service fee collected from homeowner at door.
  Homeowner signs completion confirmation.

  (branch: recalled)
  Warranty company sends contractor back — original fix didn't hold.
  New dispatch linked to original. No additional service fee.

invoiced
  Contractor submits invoice to warranty company.
  Parts + labor itemized per warranty company requirements.

paid
  Warranty company payment received.
  Auto-reconciles in Zafto Books.

closed
  Job complete. All payments collected. Archive.
```

---

## UI BEHAVIOR BY JOB TYPE

### Job Detail Screen

```
┌─────────────────────────────────────────────────────┐
│  UNIVERSAL HEADER (all job types)                    │
│  Customer name, address, trade, status, assignee     │
├─────────────────────────────────────────────────────┤
│                                                      │
│  WORKFLOW PROGRESS BAR                               │
│  (stages change based on job_type + trade)           │
│                                                      │
├─────────────────────────────────────────────────────┤
│                                                      │
│  STANDARD JOB shows:                                 │
│  - Scope of work                                     │
│  - Estimate / bid                                    │
│  - Schedule                                          │
│  - Photos                                            │
│  - Invoice                                           │
│  - Payments                                          │
│                                                      │
│  INSURANCE CLAIM adds:                               │
│  - Carrier panel (carrier, adjuster, claim #)        │
│  - Xactimate import button                           │
│  - Imported estimate lines                           │
│  - Supplement tracker                                │
│  - Split payment (carrier + deductible)              │
│  - Documentation package generator                   │
│  (+ restoration tools if trade = restoration)        │
│                                                      │
│  WARRANTY DISPATCH adds:                             │
│  - Warranty company panel (company, dispatch #)      │
│  - Authorization tracker (limit, pre-auth status)    │
│  - Diagnosis section (findings, repair/replace)      │
│  - Service fee collection                            │
│  - Warranty invoice builder                          │
│  - Recall history (if applicable)                    │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Dashboard

```
STANDARD CONTRACTOR (insurance + warranty disabled):
  Revenue:        $XX,XXX this month
  Active jobs:    12
  Pipeline chart: standard stages only

MULTI-TYPE CONTRACTOR (one or both enabled):
  Revenue breakdown:
    Retail:     $32,000  (58%)
    Insurance:  $14,500  (26%)
    Warranty:   $8,800   (16%)
  Active jobs by type:  18 retail · 6 insurance · 9 warranty
  Pipeline chart: color-coded by job type

  This single dashboard view is the lock-in.
  No other platform shows all three revenue streams together.
```

### Calendar

```
Color coding by job type:
  Standard:         Trade color (existing behavior)
  Insurance Claim:  Orange accent
  Warranty Dispatch: Purple accent

Contractor sees their full week — retail, insurance, and warranty
jobs all on one calendar. Their techs see one schedule.
Dispatchers assign from one pool.
```

---

## ACCOUNTING INTEGRATION (ZAFTO BOOKS)

### Three Payment Models in One Ledger

```
STANDARD JOB:
  Customer → pays contractor directly
  One receivable. Simple.

INSURANCE CLAIM:
  Carrier → pays bulk of approved amount
  Homeowner → pays deductible
  Depreciation → held by carrier, released on completion
  Three receivable lines per job. Split invoicing.

WARRANTY DISPATCH:
  Homeowner → pays service fee at door (collected on site)
  Warranty company → pays parts + labor invoice
  Out-of-pocket → homeowner pays for non-covered extras
  Two or three receivable lines per job.

ZAFTO BOOKS TRACKS ALL THREE AUTOMATICALLY:
  - Revenue by job type (retail / insurance / warranty)
  - Receivables aging by payer type (customer / carrier / warranty co)
  - Service fees collected vs outstanding
  - Carrier payments: submitted vs paid vs overdue
  - Warranty company payments: invoiced vs paid vs disputed
  - P&L breakdown showing true margin by job type
```

---

## WHAT EACH TRADE GETS

| Trade | Standard | Insurance | Warranty |
|-------|----------|-----------|----------|
| Electrical | ✓ Always | ✓ Fire/storm damage | ✓ Home warranty panels, wiring |
| Plumbing | ✓ Always | ✓ Water damage claims | ✓ Home warranty pipes, fixtures |
| HVAC | ✓ Always | ✓ Storm/fire damage | ✓ Home warranty systems (biggest volume) |
| Solar | ✓ Always | ✓ Storm/hail damage | ○ Rare |
| Roofing | ✓ Always | ✓ Storm/hail (huge) | ✓ Home warranty roof leaks |
| GC | ✓ Always | ✓ Reconstruction phase | ○ Rare |
| Remodeler | ✓ Always | ✓ Reconstruction phase | ○ Rare |
| Landscaping | ✓ Always | ✓ Storm cleanup | ○ Rare |
| Restoration | ✓ Always | ✓ Primary (always) | ○ Rare |

HVAC, Plumbing, and Electrical are the warranty trifecta.
Roofing, GC, and Restoration are the insurance trifecta.
Multi-trade companies get maximum value from all three types.

---

## RELATIONSHIP TO OTHER SPECS

```
This document DEFINES:
  - job_type field and its three values
  - Progressive disclosure rules
  - Warranty dispatch schema + workflow
  - UI behavior per job type
  - Accounting integration across types
  - Dashboard revenue breakdown

36_RESTORATION_INSURANCE_MODULE.md DEFINES:
  - Insurance claim schema + workflow (per trade)
  - Xactimate TPI integration
  - Carrier management
  - Supplement engine
  - Restoration-specific tools (moisture, drying, equipment)
  - Restoration calculators + reference

29_DATABASE_MIGRATION.md RECEIVES:
  - job_type column on jobs table
  - insurance_module_enabled on companies table
  - warranty_module_enabled on companies table
  - warranty_companies table
  - company_warranty_relationships table
  - warranty_dispatches table

27_BUSINESS_OS_EXPANSION.md (Zafto Books) RECEIVES:
  - Three-payer accounting model
  - Revenue-by-job-type reporting
  - Receivables aging by payer type
```

---

## IMPLEMENTATION PRIORITY

### During Supabase Migration (Do Now)

| Action | Effort |
|--------|--------|
| Add `job_type` column to jobs table | 5 min |
| Add module enable flags to companies table | 5 min |
| Create `warranty_companies` table + seed top 15 | 1 hour |
| Create `company_warranty_relationships` table | 15 min |
| Create `warranty_dispatches` table | 30 min |
| RLS policies on all new tables | 15 min |
| **Total** | **~2 hours** |

### Phase 1 — Warranty Dispatch UI

| Feature | Effort |
|---------|--------|
| Job type selector on job creation | 2 hours |
| Warranty dispatch workflow (10 stages) | 4 hours |
| Warranty company panel on job detail | 3 hours |
| Diagnosis + authorization UI | 3 hours |
| Service fee collection flow | 2 hours |
| Warranty invoice builder | 4 hours |
| **Total** | **~18 hours** |

### Phase 2 — Dashboard + Books Integration

| Feature | Effort |
|---------|--------|
| Revenue-by-type dashboard widget | 3 hours |
| Calendar color coding by type | 1 hour |
| Zafto Books three-payer model | 6 hours |
| Receivables aging by payer type | 3 hours |
| **Total** | **~13 hours** |

### Phase 3 — Warranty Company Integrations (Future)

| Feature | Effort |
|---------|--------|
| Research warranty company APIs/portals | 8 hours |
| Auto-import dispatches from warranty portals | 16 hours |
| Auto-submit invoices to warranty portals | 12 hours |
| **Total** | **~36 hours** |

```
TOTAL ALL PHASES:

Schema (migration):     ~2 hours
Phase 1 (core UI):     ~18 hours
Phase 2 (dashboard):   ~13 hours
Phase 3 (integrations): ~36 hours  (future — after launch)
──────────────────────────────────
TOTAL:                  ~69 hours
```

---

## THE MOAT

```
A plumber doing 30 retail jobs and 10 warranty dispatches per month
currently runs two systems. Or a spreadsheet and a system.
Or texts and memory.

The moment they manage both in ZAFTO:
  - One calendar for all jobs
  - One team schedule
  - One set of books
  - One dashboard showing $45K retail + $18K warranty
  - One client list (warranty homeowners become retail customers later)

They can't leave without ripping out everything.
No competitor handles all three job types in one platform.
That's the moat. Not a feature. A switching cost.
```

---

## CHANGELOG

| Date | Change |
|------|--------|
| 2026-02-05 | Initial specification. Three job types, warranty dispatch schema, progressive disclosure, accounting integration. |
