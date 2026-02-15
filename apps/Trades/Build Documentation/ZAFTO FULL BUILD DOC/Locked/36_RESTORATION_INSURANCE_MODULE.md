# DOCUMENT 36: RESTORATION INSURANCE MODULE

> **Status**: LOCKED — RECONSTRUCTED
> **Created**: 2026-02-05 (original session unknown — file was missing from disk)
> **Reconstructed**: 2026-02-06 from cross-references in Docs 37, 38, 39, and 00_MASTER_BUILD_PLAN
> **Purpose**: Restoration as 9th trade + Insurance Claims Module + ESX Interop (Xactimate replacement)
>
> **⚠️ RECONSTRUCTION NOTE**: The original file `36_RESTORATION_INSURANCE_MODULE.md` was referenced
> in the Master Build Plan changelog and by Docs 37, 38, and 39 — but the file did not exist on disk.
> This reconstruction is assembled from every cross-reference found across the documentation set.
> Some implementation details may need to be re-specified in a future session.

---

## WHAT THIS DOCUMENT DEFINES

Per Doc 37 (lines 509-515), this document is the authoritative source for:

1. **Insurance claim schema + workflow** (per-trade pipeline stages)
2. **Xactimate / TPI integration** (ESX interop — Xactimate replacement)
3. **Carrier management** (insurance carrier tracking, adjuster scheduling)
4. **Supplement engine** (supplement tracking and submission)
5. **Restoration-specific tools** (moisture readers, drying equipment, monitoring)
6. **Restoration calculators + reference content**

Per Doc 38 (line 676-687), the following are considered "already existing from 36 + 37 specs":
- ✅ Insurance claims table and pipeline
- ✅ TPI scheduling
- ✅ Supplement tracking
- ✅ Carrier/adjuster management
- ✅ Xactimate interop (ESX)
- ✅ Progressive disclosure (module enable toggles)
- ✅ Three-payer accounting model
- ✅ Cross-trade insurance mode
- ✅ Restoration tools (moisture, drying, equipment)

---

## RESTORATION AS THE 9TH TRADE

Restoration is not a niche — it's a massive trade vertical. Every water damage, fire, storm,
and mold event needs a restoration contractor. These contractors deal with:

```
WHAT MAKES RESTORATION UNIQUE:
1. Emergency dispatch — 24/7 response required for water/fire/storm
2. Insurance is the PRIMARY payer, not the homeowner
3. Xactimate is the industry-standard estimating tool (carrier-mandated)
4. Multi-phase work — mitigation THEN reconstruction (often different contractors)
5. Third-Party Inspectors (TPI) verify scope and pricing
6. Supplement cycles — initial estimate is almost never final
7. Moisture monitoring — daily readings during drying (logged, timestamped)
8. Equipment tracking — dehumidifiers, air movers, air scrubbers (rental $ per day)
9. Certificate of Completion required before carrier releases final payment
10. Drying logs are LEGAL DOCUMENTS — carriers audit them

Average restoration job: $8,000-$45,000
Average insurance claim cycle: 30-90 days
Supplement rate: 60-80% of claims get supplemented
```

### Restoration-Specific Tools

```
MOISTURE MONITORING:
- Daily moisture readings logged per affected area
- Readings: material type, location, reading value, target value
- Auto-calculates drying progress (% to target)
- Photo documentation per reading point
- Drying log export (PDF) for carrier/adjuster

EQUIPMENT TRACKING:
- Equipment inventory per job (dehumidifiers, air movers, air scrubbers, heaters)
- Placement date, removal date, daily rate
- Auto-calculates equipment charges (units × days × daily rate)
- Equipment map (which room has what)
- Feeds into invoice line items automatically

DRYING LOG:
- Timestamped daily readings
- Humidity, temperature, moisture content per zone
- Target thresholds per material type
- Auto-flag when zone reaches dry standard
- Exportable as PDF for carrier submission
- IMMUTABLE — once logged, cannot be edited (legal document)

RESTORATION CALCULATORS:
- Psychrometric calculations (grain depression, GPP, specific humidity)
- Equipment placement calculator (CFM per sq ft, dehu capacity)
- Drying time estimator (based on material, saturation level, equipment)
- Content cleaning vs replacement threshold
- Mold risk assessment (time + humidity + temperature)
```

---

## DATABASE SCHEMA

### Insurance Claims Table (New)

```sql
-- ============================================================
-- INSURANCE CLAIMS MODULE — SUPABASE SCHEMA
-- Core insurance claim tracking for ALL trades
-- Referenced by: Doc 37, Doc 38, Doc 39
-- ============================================================

CREATE TABLE insurance_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,

  -- Claim identifiers
  claim_number TEXT NOT NULL,                   -- Insurance carrier's claim number
  policy_number TEXT,                           -- Homeowner's insurance policy number
  loss_date DATE,                               -- Date of loss event

  -- Carrier info
  carrier_id UUID,                              -- FK to a carriers lookup or JSONB
  carrier_name TEXT NOT NULL,                   -- "State Farm", "Allstate", "USAA", etc.
  carrier_phone TEXT,
  carrier_email TEXT,
  carrier_claim_portal_url TEXT,                -- Where to submit docs online

  -- Adjuster info
  adjuster_name TEXT,
  adjuster_phone TEXT,
  adjuster_email TEXT,
  adjuster_company TEXT,                        -- If independent adjuster (IA)
  adjuster_type TEXT DEFAULT 'staff',           -- 'staff', 'independent', 'public'

  -- Property info
  property_type TEXT DEFAULT 'residential',     -- 'residential', 'commercial', 'condo', 'townhome'
  property_address TEXT,                        -- May differ from company address
  property_year_built INTEGER,

  -- Loss details
  loss_type TEXT NOT NULL,                      -- 'water', 'fire', 'storm', 'mold', 'vandalism', 'other'
  loss_category TEXT DEFAULT 'non_cat',         -- 'cat' (catastrophe/storm) or 'non_cat'
  loss_description TEXT,
  affected_areas JSONB DEFAULT '[]',            -- Array of rooms/areas affected
  affected_sq_ft INTEGER,

  -- Estimates
  initial_estimate DECIMAL(12,2),               -- First Xactimate estimate submitted
  approved_amount DECIMAL(12,2),                -- What carrier approved
  supplement_total DECIMAL(12,2) DEFAULT 0,     -- Total supplements approved
  total_approved DECIMAL(12,2),                 -- approved_amount + supplement_total
  depreciation_held DECIMAL(12,2) DEFAULT 0,    -- Recoverable depreciation held back
  depreciation_released DECIMAL(12,2) DEFAULT 0,-- Recoverable depreciation paid out
  deductible DECIMAL(10,2),                     -- Homeowner's deductible amount
  deductible_collected BOOLEAN DEFAULT FALSE,
  deductible_collected_date TIMESTAMPTZ,

  -- Xactimate / ESX
  xactimate_file_url TEXT,                      -- Stored in Supabase Storage
  xactimate_version TEXT,                       -- "Xactimate X1", "XactAnalysis"
  tpi_required BOOLEAN DEFAULT FALSE,           -- Third-Party Inspector required
  tpi_name TEXT,
  tpi_company TEXT,
  tpi_phone TEXT,
  tpi_inspection_date TIMESTAMPTZ,
  tpi_report_url TEXT,                          -- Stored in Supabase Storage

  -- Status
  status TEXT NOT NULL DEFAULT 'filed',
  -- Varies per trade (see WORKFLOWS section below)
  -- Common statuses: filed, adjuster_scheduled, adjuster_meeting, estimate_submitted,
  --   supplement_pending, approved, in_progress, complete, certificate_issued,
  --   insurance_paid, deductible_collected, closed

  -- Dates
  filed_date TIMESTAMPTZ,
  adjuster_scheduled_date TIMESTAMPTZ,
  adjuster_meeting_date TIMESTAMPTZ,
  estimate_submitted_date TIMESTAMPTZ,
  approved_date TIMESTAMPTZ,
  completed_date TIMESTAMPTZ,
  certificate_date TIMESTAMPTZ,
  insurance_paid_date TIMESTAMPTZ,
  closed_date TIMESTAMPTZ,

  -- Metadata (for trade-specific and vertical-specific data)
  metadata JSONB DEFAULT '{}',
  -- Examples:
  -- Storm roofing: {"storm_event": "2026-OKC-Hail", "canvasser_id": "uuid", ...}
  -- Commercial: {"building_type": "office", "total_sf": 12000, ...}
  -- Restoration: {"moisture_monitoring": true, "equipment_tracking": true, ...}

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id)
);

ALTER TABLE insurance_claims ENABLE ROW LEVEL SECURITY;
CREATE POLICY "insurance_claim_isolation" ON insurance_claims
  USING (company_id = current_setting('app.company_id')::UUID);

CREATE INDEX idx_insurance_claims_company ON insurance_claims(company_id);
CREATE INDEX idx_insurance_claims_job ON insurance_claims(job_id);
CREATE INDEX idx_insurance_claims_status ON insurance_claims(company_id, status);
CREATE INDEX idx_insurance_claims_carrier ON insurance_claims(company_id, carrier_name);
```

### Claim Supplements Table (New)

```sql
-- Supplement tracking — most insurance claims get supplemented
CREATE TABLE claim_supplements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  claim_id UUID NOT NULL REFERENCES insurance_claims(id) ON DELETE CASCADE,

  supplement_number INTEGER NOT NULL,            -- 1, 2, 3... (sequential per claim)
  reason TEXT NOT NULL,                          -- Why the supplement is needed
  description TEXT,                              -- Detailed scope of additional work

  -- Financials
  amount_requested DECIMAL(12,2) NOT NULL,       -- What contractor is asking for
  amount_approved DECIMAL(12,2),                 -- What carrier approved
  amount_denied DECIMAL(12,2),                   -- What carrier denied

  -- Documentation
  xactimate_supplement_url TEXT,                 -- Supplement estimate file
  supporting_photos JSONB DEFAULT '[]',          -- Array of photo URLs
  supporting_docs JSONB DEFAULT '[]',            -- Additional documentation

  -- Status
  status TEXT NOT NULL DEFAULT 'draft',
  -- draft → submitted → under_review → approved → partially_approved → denied
  submitted_date TIMESTAMPTZ,
  reviewed_date TIMESTAMPTZ,
  reviewer_notes TEXT,                           -- Adjuster's notes on supplement

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id),

  UNIQUE(claim_id, supplement_number)
);

ALTER TABLE claim_supplements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "supplement_isolation" ON claim_supplements
  USING (company_id = current_setting('app.company_id')::UUID);
```

### Xactimate Estimate Lines Table (New)

```sql
-- Imported Xactimate estimate line items
-- ESX interop: parse Xactimate export files into structured data
CREATE TABLE xactimate_estimate_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  claim_id UUID NOT NULL REFERENCES insurance_claims(id) ON DELETE CASCADE,
  supplement_id UUID REFERENCES claim_supplements(id),  -- NULL = original estimate

  -- Xactimate line item data
  line_number INTEGER,
  category TEXT,                                -- 'WTR' (water), 'FIR' (fire), 'GEN' (general), etc.
  selector TEXT,                                -- Xactimate selector code (e.g., "DRY>EQUIPMNT")
  description TEXT NOT NULL,                    -- Line item description
  unit TEXT,                                    -- 'SF', 'LF', 'EA', 'HR', 'DA' (day)
  quantity DECIMAL(10,2),
  unit_price DECIMAL(10,2),                     -- Price per unit
  total DECIMAL(12,2),                          -- quantity × unit_price
  depreciation DECIMAL(12,2) DEFAULT 0,         -- Depreciation amount (ACV vs RCV)

  -- Room/area
  room TEXT,                                    -- Room or area assignment in Xactimate

  -- Overhead & Profit
  includes_overhead BOOLEAN DEFAULT TRUE,       -- O&P applied to this line
  overhead_pct DECIMAL(5,2) DEFAULT 10.00,      -- Typically 10%
  profit_pct DECIMAL(5,2) DEFAULT 10.00,        -- Typically 10%

  -- Status
  is_approved BOOLEAN DEFAULT TRUE,             -- Carrier approved this line
  denial_reason TEXT,                           -- If line was denied

  -- Import metadata
  import_source TEXT DEFAULT 'manual',          -- 'manual', 'esx_import', 'xactanalysis'
  imported_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE xactimate_estimate_lines ENABLE ROW LEVEL SECURITY;
CREATE POLICY "xactimate_line_isolation" ON xactimate_estimate_lines
  USING (company_id = current_setting('app.company_id')::UUID);

CREATE INDEX idx_xactimate_lines_claim ON xactimate_estimate_lines(claim_id);
```

### Restoration-Specific Tables

```sql
-- Moisture readings (drying log entries — IMMUTABLE after creation)
CREATE TABLE moisture_readings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  claim_id UUID REFERENCES insurance_claims(id),

  -- Reading data
  reading_date DATE NOT NULL,
  reading_time TIME NOT NULL,
  zone TEXT NOT NULL,                           -- Room/area identifier
  material_type TEXT NOT NULL,                  -- 'drywall', 'wood_framing', 'subfloor', 'concrete', 'carpet'
  location_description TEXT,                    -- "North wall, 3ft from floor"
  reading_value DECIMAL(5,1) NOT NULL,          -- Moisture content %
  target_value DECIMAL(5,1) NOT NULL,           -- Target dry standard for this material
  is_at_target BOOLEAN GENERATED ALWAYS AS (reading_value <= target_value) STORED,

  -- Environmental
  ambient_humidity DECIMAL(5,1),                -- Relative humidity %
  ambient_temperature DECIMAL(5,1),             -- Fahrenheit
  grain_depression DECIMAL(5,1),                -- GPP (grains per pound)

  -- Photo documentation
  photo_url TEXT,                               -- Photo of reading/meter at point
  notes TEXT,

  -- Audit
  recorded_by UUID REFERENCES users(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
  -- NOTE: No updated_at. Moisture readings are IMMUTABLE once created.
  -- This is a legal document. Carriers audit drying logs.
);

ALTER TABLE moisture_readings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "moisture_reading_isolation" ON moisture_readings
  USING (company_id = current_setting('app.company_id')::UUID);

CREATE INDEX idx_moisture_readings_job ON moisture_readings(job_id, reading_date);

-- Equipment placement tracking (dehumidifiers, air movers, etc.)
CREATE TABLE restoration_equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  claim_id UUID REFERENCES insurance_claims(id),

  -- Equipment info
  equipment_type TEXT NOT NULL,                  -- 'dehumidifier', 'air_mover', 'air_scrubber',
                                                 -- 'heater', 'moisture_meter', 'thermal_camera'
  brand TEXT,
  model TEXT,
  serial_number TEXT,                           -- For tracking owned vs rented units

  -- Placement
  zone TEXT NOT NULL,                           -- Room/area where placed
  placed_date DATE NOT NULL,
  placed_time TIME,
  removed_date DATE,
  removed_time TIME,

  -- Rental costs
  daily_rate DECIMAL(8,2),                      -- Cost per day (from Xactimate pricing)
  is_owned BOOLEAN DEFAULT TRUE,                -- Owned vs rented from equipment supplier
  total_days INTEGER GENERATED ALWAYS AS (
    CASE WHEN removed_date IS NOT NULL
    THEN (removed_date - placed_date) + 1
    ELSE NULL END
  ) STORED,

  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id)
);

ALTER TABLE restoration_equipment ENABLE ROW LEVEL SECURITY;
CREATE POLICY "restoration_equipment_isolation" ON restoration_equipment
  USING (company_id = current_setting('app.company_id')::UUID);
```

### Company Settings Addition

```sql
-- Add to companies table (also referenced in Doc 37)
ALTER TABLE companies ADD COLUMN insurance_module_enabled BOOLEAN DEFAULT FALSE;
-- warranty_module_enabled is defined in Doc 37
```

---

## INSURANCE CLAIM WORKFLOWS (Per Trade)

### Restoration Workflow (17 Stages)

```
Loss Report → Emergency Dispatch → Mitigation Active → Drying →
Drying Complete → Scope of Loss → Estimate Submitted → Adjuster Review →
Approved → Supplement Pending → Reconstruction Bid → Reconstruction Active →
Final Walkthrough → Certificate Issued → Insurance Paid →
Deductible Collected → Closed

STAGE DETAILS:

loss_report
  Homeowner or carrier reports water/fire/storm damage.
  Data captured: loss type, loss date, property info, initial photos.

emergency_dispatch
  24/7 response. Contractor dispatched to property.
  SLA: respond within 1-4 hours for water, immediate for fire.
  Mitigation authorization (verbal OK from carrier or homeowner).

mitigation_active
  Emergency work underway — water extraction, board-up, tarping, demo.
  Daily moisture readings BEGIN. Equipment placed and tracked.
  Photos logged daily.

drying
  Equipment running. Daily moisture readings logged.
  Drying log is the LEGAL RECORD.
  Auto-calculate drying progress per zone.

drying_complete
  All zones at or below target moisture levels.
  Final drying log generated (PDF export for carrier).
  Equipment removed, final equipment charges calculated.

scope_of_loss
  Full damage assessment. Room-by-room documentation.
  Xactimate estimate created for carrier submission.

estimate_submitted
  Xactimate estimate submitted to carrier/adjuster.
  TPI may be assigned to review scope and pricing.

adjuster_review
  Carrier adjuster (staff or independent) reviews estimate.
  May schedule property inspection.
  May request modifications to estimate.

approved
  Carrier approves scope and pricing.
  ACV (Actual Cash Value) payment issued.
  Depreciation held until work complete (recoverable depreciation).

supplement_pending
  Hidden damage found during work. Supplement estimate created.
  ~60-80% of restoration claims get supplemented.
  Supplement cycle: submit → review → approve/deny.

reconstruction_bid
  If reconstruction needed (separate from mitigation).
  May be same contractor or different (handed off to GC/remodeler).
  Reconstruction Xactimate estimate created.

reconstruction_active
  Rebuild work underway. Tracks against approved scope.
  Homeowner upgrade tracking (insurance portion vs out-of-pocket).

final_walkthrough
  Owner/homeowner signs off on completed work.
  Final photos documented.
  Certificate of Completion prepared.

certificate_issued
  Certificate of Satisfaction / Completion signed by homeowner.
  Submitted to carrier to release final payment + recoverable depreciation.

insurance_paid
  Carrier releases payment to contractor.
  Recoverable depreciation released upon completion proof.
  Auto-reconciles in ZAFTO Books.

deductible_collected
  Homeowner pays their deductible.
  Some states: contractor collects. Others: carrier deducts from payment.
  Track by state regulation.

closed
  All payments collected. Job archived.
  Drying logs, photos, estimates archived for 7+ years (carrier audit period).
```

### Roofing Insurance Workflow (13 Stages)

```
Inspection → Claim Filed → Adjuster Meeting → Estimate Submitted →
Supplement Pending → Approved → Materials Ordered → Scheduled →
In Progress → Complete → Insurance Paid → Deductible Collected → Closed
```

### General Insurance Workflow (10 Stages — for trades without specialized pipeline)

```
Claim Filed → Estimate Submitted → Adjuster Review → Approved →
Supplement Pending → In Progress → Complete → Insurance Paid →
Deductible Collected → Closed
```

---

## XACTIMATE / ESX INTEROP

```
WHAT IS XACTIMATE:
- Industry-standard estimating software used by insurance carriers
- Carrier adjusters write estimates in Xactimate
- Contractors must submit in Xactimate format for carrier payment
- Xactimate prices are set by the carrier (regional price lists)
- "ESX" = Xactimate's electronic data exchange format

ZAFTO'S APPROACH (ESX Interop — NOT a replacement):
- Import ESX files from Xactimate into ZAFTO
- Parse estimate lines into xactimate_estimate_lines table
- Overlay ZAFTO's project management, scheduling, invoicing on top
- Supplement generation references original estimate lines
- Export capabilities for carrier submission
- Track actual costs vs Xactimate allowances (margin analysis for Owner)

WORKFLOW:
1. Carrier/adjuster creates Xactimate estimate
2. Contractor receives ESX file (email, portal, or XactAnalysis)
3. Upload ESX file to ZAFTO → Edge Function parses into line items
4. ZAFTO creates structured view: rooms, categories, line items, totals
5. Contractor works the job using ZAFTO's tools
6. When supplement needed: ZAFTO helps build supplement with reference to original lines
7. Final invoice reconciles Xactimate approved amounts vs actual work

FUTURE — TPI INTEGRATION:
- Third-Party Inspectors (TPI) are assigned by carriers to verify scope/pricing
- Schedule TPI inspections within ZAFTO
- Track TPI reports and responses
- Auto-notify when TPI assigned to claim
```

---

## CARRIER MANAGEMENT

```
CARRIER DIRECTORY:
- Lookup table of major insurance carriers
- State Farm, Allstate, USAA, Liberty Mutual, Travelers, etc.
- Per-carrier: claim portal URL, phone, email, typical response times
- Per-carrier: which TPI companies they use
- Per-carrier: preferred Xactimate pricing list

CONTRACTOR-CARRIER RELATIONSHIPS:
- Which carriers the contractor works with
- Contractor's vendor ID per carrier
- Preferred vendor status tracking
- Historical performance metrics per carrier
- Payment terms per carrier
- Average cycle time per carrier

ADJUSTER TRACKING:
- Adjuster contact info per claim
- Adjuster meeting scheduling
- Staff adjuster vs Independent Adjuster (IA)
- Adjuster response time tracking
- Adjuster no-show tracking and auto-reschedule (from Doc 38)
```

---

## SUPPLEMENT ENGINE

```
SUPPLEMENTS ARE THE NORM, NOT THE EXCEPTION:
- 60-80% of restoration claims get supplemented
- Hidden damage revealed during demo/mitigation
- Initial Xactimate estimates rarely capture full scope
- Supplement approval adds $2,000-$8,000+ per claim average

ZAFTO SUPPLEMENT WORKFLOW:
1. Contractor discovers additional damage during work
2. Document with photos + detailed description
3. Reference original Xactimate line items that are affected
4. Generate supplement estimate (additional line items)
5. Submit to carrier/adjuster
6. Track supplement status (submitted → under_review → approved/denied/partial)
7. If partially approved: negotiate or accept
8. Approved amount added to claim total

AI-ASSISTED SUPPLEMENTING (via Doc 35 — Z Intelligence):
- Z reviews original estimate + found conditions
- Suggests commonly missed line items for this loss type
- Validates line items against Xactimate pricing
- Drafts supplement narrative (for Owner/Admin)
- This feature is RBAC-restricted: Owner/Admin only
```

---

## THREE-PAYER ACCOUNTING MODEL

Per Doc 37 (lines 525-529), this module feeds into ZAFTO Books:

```
INSURANCE CLAIM PAYERS:
1. Insurance carrier — pays approved estimate amount
2. Homeowner — pays deductible
3. Homeowner (optional) — pays out-of-pocket upgrades

ACCOUNTING FLOW:
- Invoice splits automatically by payer
- Carrier payment tracked via insurance_claims.insurance_paid_date
- Deductible tracked via insurance_claims.deductible_collected
- OOP upgrades tracked via standard invoicing
- Revenue-by-payer reporting in ZAFTO Books
- Receivables aging separated by payer type

DASHBOARD WIDGET:
- Insurance Revenue: $X (carrier payments)
- Deductibles Collected: $X
- Homeowner Upgrades: $X
- Outstanding from Carriers: $X (aging by carrier)
- Outstanding Deductibles: $X
```

---

## IMPLEMENTATION PRIORITY

### During Supabase Migration (Do Now)

| Action | Effort |
|--------|--------|
| Create `insurance_claims` table + indexes + RLS | 1 hour |
| Create `claim_supplements` table + RLS | 30 min |
| Create `xactimate_estimate_lines` table + RLS | 30 min |
| Create `moisture_readings` table + RLS | 30 min |
| Create `restoration_equipment` table + RLS | 30 min |
| Add `insurance_module_enabled` to companies | 5 min |
| **Total** | **~3 hours** |

### Phase 1 — Insurance Claims Core UI

| Feature | Effort |
|---------|--------|
| Insurance claim creation from job | 3 hours |
| Claim detail screen (carrier, adjuster, status) | 4 hours |
| Insurance pipeline view (Kanban by status) | 4 hours |
| Adjuster scheduling + calendar integration | 3 hours |
| Basic supplement creation + tracking | 4 hours |
| Deductible collection tracking | 2 hours |
| **Total** | **~20 hours** |

### Phase 2 — Xactimate + Restoration Tools

| Feature | Effort |
|---------|--------|
| ESX file import parser (Edge Function) | 8 hours |
| Xactimate estimate line viewer | 4 hours |
| Moisture reading entry + drying log | 6 hours |
| Equipment placement tracking | 4 hours |
| Drying log PDF export | 3 hours |
| Certificate of Completion generator | 2 hours |
| **Total** | **~27 hours** |

### Phase 3 — Intelligence + Supplements (Post-Launch)

| Feature | Effort |
|---------|--------|
| AI-assisted supplement suggestions | 8 hours |
| Carrier performance analytics | 4 hours |
| TPI integration (scheduling + tracking) | 6 hours |
| Restoration calculators (psychrometric, equipment sizing) | 6 hours |
| Cross-claim reporting (by carrier, by loss type) | 4 hours |
| **Total** | **~28 hours** |

```
TOTAL ALL PHASES:

Schema (migration):     ~3 hours
Phase 1 (core UI):     ~20 hours
Phase 2 (xactimate):   ~27 hours
Phase 3 (intelligence): ~28 hours
──────────────────────────────────
TOTAL:                  ~78 hours
```

---

## CROSS-TRADE INSURANCE MODE

```
Insurance claims are NOT restoration-only.
Any trade can have insurance work:

TRADE           | COMMON INSURANCE SCENARIOS
────────────────┼──────────────────────────────────────
Restoration     | Water damage, fire damage, mold, storm (PRIMARY)
Roofing         | Storm/hail damage, wind damage (MASS VOLUME)
GC              | Reconstruction after restoration
Remodeler       | Reconstruction after restoration
Plumbing        | Water damage source repairs
Electrical      | Fire damage, storm damage, rewiring
HVAC            | Storm damage, fire damage, equipment claims
Solar           | Hail/storm panel damage
Landscaping     | Storm cleanup, tree damage

The insurance_claims table + workflow is UNIVERSAL.
Trade-specific behavior is handled by:
1. Workflow stage configurations (TradeWorkflowConfig from Doc 38)
2. Metadata JSONB fields (trade-specific data without schema bloat)
3. UI progressive disclosure (only show relevant fields per trade)
```

---

## DEPENDENCIES

| This Document | Depends On |
|---------------|------------|
| Job type field | `Locked/37_JOB_TYPE_SYSTEM.md` — job_type = 'insurance_claim' |
| Accounting integration | `Expansion/27_BUSINESS_OS_EXPANSION.md` — ZAFTO Books |
| AI features | `Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md` — Z Intelligence |
| Insurance verticals | `Expansion/38_INSURANCE_CONTRACTOR_VERTICALS.md` — extends this spec |
| Growth opportunities | `Expansion/39_GROWTH_ADVISOR.md` — carrier program recommendations |
| Database schema | `Locked/29_DATABASE_MIGRATION.md` — all tables referenced |

---

## THE MOAT

```
Every restoration contractor currently uses:
  - Xactimate (carrier-mandated estimating) — $200+/mo
  - A CRM (ServiceMonster, PSA, or spreadsheets)
  - QuickBooks (accounting)
  - A drying log app (or paper)
  - Email/text for adjuster communication
  - A scheduling tool
  - Their phone's camera + a folder system

ZAFTO replaces everything except Xactimate (we interop with it instead).
One platform. One login. One set of books.

The drying log alone is a lock-in feature.
Once a contractor has 6 months of drying logs in ZAFTO,
they're not moving to another platform. That data is their legal record.
```

---

## CHANGELOG

| Date | Change |
|------|--------|
| 2026-02-06 | RECONSTRUCTED from cross-references. Original file was missing from disk. Assembled from Docs 37, 38, 39, and Master Build Plan references. |

---

*This is the spec that unlocks insurance work for every trade in ZAFTO.
Not just restoration — every contractor touches insurance somewhere.
Doc 37 defines the job types. Doc 38 defines the verticals.
This document defines the engine underneath both.*
