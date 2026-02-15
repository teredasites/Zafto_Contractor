# ZAFTO INSURANCE CONTRACTOR VERTICALS
## Storm · Reconstruction · Commercial · Warranty Network
### February 5, 2026 — EXPANSION SPECIFICATION

---

## ONE SENTENCE

Beyond core restoration and standard insurance claims, ZAFTO serves four additional
insurance-adjacent verticals — storm/catastrophe roofing, property reconstruction,
commercial multi-trade claims, and home warranty network — all running on the same
job type system defined in `37_JOB_TYPE_SYSTEM.md` without adding complexity for
contractors who don't need them.

---

## RELATIONSHIP TO EXISTING SPECS

```
This document EXTENDS:
  37_JOB_TYPE_SYSTEM.md    → Same three job types, new workflow configs per vertical
  36_RESTORATION_MODULE.md → Same insurance claims schema, same TPI integration

This document DOES NOT modify locked schemas.
All verticals use existing tables: insurance_claims, warranty_dispatches,
claim_supplements, xactimate_estimate_lines, TradeWorkflowConfig.

New content = workflow configurations, UI presets, vertical-specific
business logic, and go-to-market for each segment.
```

---

## THE FOUR VERTICALS


```
VERTICAL 1 — STORM / CATASTROPHE ROOFING
  Who:      Roofers who follow hail and wind storms across states
  Scale:    Hundreds of claims per season, multi-state operations
  Job Type: insurance_claim (from 37_JOB_TYPE_SYSTEM.md)
  Trade:    Roofing

VERTICAL 2 — PROPERTY RECONSTRUCTION
  Who:      GCs and remodelers who rebuild after mitigation
  Scale:    Same insurance claim, different contractor, different scope
  Job Type: insurance_claim
  Trade:    GC or Remodeler

VERTICAL 3 — COMMERCIAL PROPERTY CLAIMS
  Who:      Multi-trade teams on large commercial losses
  Scale:    Single claim, multiple trades, multiple contractors
  Job Type: insurance_claim
  Trade:    Any (multi-trade coordination)

VERTICAL 4 — HOME WARRANTY NETWORK
  Who:      Plumbers, HVAC, electricians dispatched by warranty companies
  Scale:    Ongoing volume from multiple warranty company relationships
  Job Type: warranty_dispatch (from 37_JOB_TYPE_SYSTEM.md)
  Trade:    Plumbing, HVAC, Electrical, Roofing
```

---

## VERTICAL 1: STORM / CATASTROPHE ROOFING

### The Business

Storm chasers are almost their own industry. Roofing crews follow hail and wind
events across multiple states, running canvassing operations door-to-door, scheduling
adjuster meetings at scale, and managing dozens of simultaneous insurance claims per
crew. A typical storm chasing operation processes 50-200 claims per hail season
across 3-5 states.

### What Makes This Different from a Local Insurance Roofer

A local roofer doing 5 insurance jobs a year uses the standard insurance claim
workflow from 36_RESTORATION_INSURANCE_MODULE.md and that's plenty.

A storm operation needs mass-scale tools on top of that same workflow:

```
CANVASSING MANAGEMENT
  - Territory mapping (assign blocks/neighborhoods to canvassers)
  - Door knock tracking (knocked, no answer, interested, signed, declined)
  - Contingency agreement capture (digital signature at the door)
  - Storm date + damage type tagging per lead
  - Canvasser leaderboard (doors knocked, agreements signed, close rate)

MASS LEAD PIPELINE
  - Import hundreds of leads from canvassing in one batch
  - Auto-tag with storm event, date of loss, territory
  - Bulk status updates (all leads in ZIP 73102 → "adjuster scheduled")
  - Filter/sort by: storm event, territory, status, assigned crew, carrier

ADJUSTER MEETING SCHEDULER
  - Calendar view showing all scheduled adjuster meetings across jobs
  - Route optimization (cluster meetings by geography per day)
  - Adjuster no-show tracking and auto-reschedule
  - Multiple meetings per day per sales rep (5-8 is normal)

MULTI-STATE OPERATIONS
  - State licensing compliance tracking (contractor license per state)
  - Tax jurisdiction management per job location
  - Crew deployment tracking (which crew is in which state)
  - Per-storm-event P&L (profitability by storm, not just by job)
```

### Storm Roofing Workflow Config

```dart
// Extends TradeWorkflowConfig for roofing + storm mode

class StormRoofingWorkflow extends TradeWorkflowConfig {
  @override
  String get tradeId => 'roofing';

  @override
  List<WorkflowStage> get stages => [
    // Pre-claim (canvassing phase)
    WorkflowStage(id: 'canvassed', label: 'Canvassed',
      automations: ['send_followup_sms_24hr']),
    WorkflowStage(id: 'agreement_signed', label: 'Agreement Signed',
      requiredFields: ['contingency_agreement']),
    WorkflowStage(id: 'inspection_scheduled', label: 'Inspection Scheduled'),
    WorkflowStage(id: 'inspection_complete', label: 'Inspection Complete',
      requiredFields: ['roof_photos', 'damage_report']),

    // Insurance claim phase (same as 36 spec)
    WorkflowStage(id: 'claim_filed', label: 'Claim Filed',
      requiredFields: ['carrier_id', 'claim_number']),
    WorkflowStage(id: 'adjuster_scheduled', label: 'Adjuster Scheduled',
      slaTarget: Duration(days: 7)),
    WorkflowStage(id: 'adjuster_meeting', label: 'Adjuster Meeting'),
    WorkflowStage(id: 'estimate_received', label: 'Estimate Received'),
    WorkflowStage(id: 'supplement_pending', label: 'Supplement Pending'),
    WorkflowStage(id: 'approved', label: 'Approved'),

    // Production phase
    WorkflowStage(id: 'materials_ordered', label: 'Materials Ordered'),
    WorkflowStage(id: 'production_scheduled', label: 'Production Scheduled'),
    WorkflowStage(id: 'in_progress', label: 'In Progress'),
    WorkflowStage(id: 'final_inspection', label: 'Final Inspection',
      requiresApproval: true),

    // Close phase
    WorkflowStage(id: 'certificate_of_completion', label: 'COC Issued'),
    WorkflowStage(id: 'insurance_paid', label: 'Insurance Paid'),
    WorkflowStage(id: 'deductible_collected', label: 'Deductible Collected'),
    WorkflowStage(id: 'closed', label: 'Closed'),
  ];
}
```

### Storm-Specific Data (Uses Existing Schema — No New Tables)

```
All storm data maps to EXISTING fields:

  jobs.source         → 'canvass' (new enum value)
  jobs.tags           → ['storm:2026-hail-okc', 'territory:73102']
  jobs.metadata       → {
                           "storm_event": "2026-OKC-Hail",
                           "canvasser_id": "uuid",
                           "doors_knocked": 47,
                           "agreement_signed_at": "2026-04-15T14:30:00Z",
                           "contingency_agreement_url": "storage://...",
                           "territory_zone": "NW-OKC-Zone-3"
                         }

  insurance_claims.*  → Standard claim fields from 36 spec
  xactimate_estimate_lines.* → Imported estimate from TPI

No new tables needed. The storm workflow is a CONFIGURATION
on top of existing infrastructure, not a schema change.
```

### Storm Event Dashboard Widget

```
┌─────────────────────────────────────────────────────────────┐
│  STORM EVENT: 2026 OKC Hail — April 12                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Leads:        347 canvassed · 89 agreements · 26% close     │
│  Claims Filed: 72                                            │
│  Approved:     41  ($485K total approved)                    │
│  In Production: 18                                           │
│  Complete:      23  ($271K collected)                        │
│  Pipeline:      $214K remaining                              │
│                                                              │
│  Avg Supplement: +$2,840 per claim (34 supplemented)         │
│  Avg Cycle Time: 31 days (canvass → paid)                    │
│                                                              │
│  Crews Deployed: 3 (OKC metro)                               │
│  Canvassers Active: 6                                        │
│                                                              │
│  [View All Jobs] [Canvasser Report] [Storm P&L]             │
└─────────────────────────────────────────────────────────────┘
```


---

## VERTICAL 2: PROPERTY RECONSTRUCTION

### The Business

After the restoration company finishes mitigation and drying, someone has to rebuild.
New drywall, paint, flooring, cabinets, trim — the full reconstruction back to
pre-loss condition. This is usually a GC or remodeler working under the SAME insurance
claim but with a separate scope and often a separate estimate.

The reconstruction contractor faces unique challenges:

```
1. They inherit someone else's claim — carrier relationship already established
2. The mitigation scope and reconstruction scope often conflict
3. Supplements are even more common on reconstruction (hidden damage revealed during demo)
4. They need the Xactimate estimate for reconstruction scope, not mitigation
5. Payment is split: carrier pays approved amount, homeowner pays deductible + upgrades
6. Homeowner often wants upgrades beyond pre-loss condition (better flooring, new layout)
   and that becomes an out-of-pocket add-on to the insurance scope
```

### How ZAFTO Handles Reconstruction

```
SCENARIO: Water damage claim. Restoration company did mitigation.
GC picks up the reconstruction phase.

1. GC creates job in ZAFTO → selects "Insurance Claim" job type
2. Enters existing claim number from carrier
3. Imports reconstruction Xactimate estimate via TPI
   (separate estimate from the mitigation estimate — same claim number)
4. ZAFTO links to the claim but tracks reconstruction scope separately
5. If homeowner wants upgrades:
   - Insurance-covered scope tracked against Xactimate import
   - Upgrade scope tracked as separate line items (out-of-pocket)
   - Invoice splits: carrier portion + deductible + upgrades

This is all handled by existing schema:
  insurance_claims.claim_number  → same claim, different job
  xactimate_estimate_lines.*    → reconstruction estimate import
  The job itself is independent — different company, different job record
```

### Reconstruction Workflow Config

```dart
class ReconstructionWorkflow extends TradeWorkflowConfig {
  @override
  String get tradeId => 'gc'; // or 'remodeler'

  @override
  List<WorkflowStage> get stages => [
    WorkflowStage(id: 'scope_review', label: 'Scope Review',
      requiredFields: ['xactimate_estimate_imported']),
    WorkflowStage(id: 'homeowner_selections', label: 'Selections',
      automations: ['send_selection_portal_link']),
    WorkflowStage(id: 'materials_ordered', label: 'Materials Ordered'),
    WorkflowStage(id: 'demo_complete', label: 'Demo Complete',
      requiredFields: ['demo_photos']),
    WorkflowStage(id: 'rough_in', label: 'Rough-In'),
    WorkflowStage(id: 'inspection', label: 'Inspection'),
    WorkflowStage(id: 'finish_work', label: 'Finish Work'),
    WorkflowStage(id: 'final_walkthrough', label: 'Final Walkthrough',
      requiresApproval: true),
    WorkflowStage(id: 'supplement_pending', label: 'Supplement Pending'),
    WorkflowStage(id: 'insurance_paid', label: 'Insurance Paid'),
    WorkflowStage(id: 'deductible_collected', label: 'Deductible Collected'),
    WorkflowStage(id: 'upgrades_collected', label: 'Upgrades Collected'),
    WorkflowStage(id: 'closed', label: 'Closed'),
  ];
}
```

### Upgrade Tracking (Insurance Scope vs Homeowner Upgrades)

```
This is the key differentiator for reconstruction contractors.

EXAMPLE:
  Insurance approved: LVP flooring, builder-grade, 800 SF    = $4,800
  Homeowner wants:    Engineered hardwood, premium, 800 SF    = $8,200
  Insurance pays:     $4,800 (approved estimate)
  Homeowner pays:     $3,400 (upgrade difference) + $1,000 (deductible)

ZAFTO tracks this with existing fields:
  xactimate_estimate_lines  → imported insurance scope (what carrier approved)
  jobs.metadata             → { "upgrade_items": [...] }  upgrade selections
  Invoice line items        → carrier portion / deductible / upgrade charges

The invoice auto-generates three sections:
  Section 1: Insurance-covered work     → billed to carrier
  Section 2: Deductible                 → billed to homeowner
  Section 3: Upgrades beyond pre-loss   → billed to homeowner

No new tables. The existing invoice and line item system handles this
with a payment_source field on each line: 'carrier', 'deductible', 'upgrade'.
```

---

## VERTICAL 3: COMMERCIAL PROPERTY CLAIMS

### The Business

Commercial losses are residential claims scaled up with more complexity. A flooded
office building, a fire-damaged warehouse, a storm-hit retail strip — these involve
multiple trades, multiple contractors, higher dollar amounts, different carriers
(commercial vs personal lines), and more rigorous documentation requirements.

### What Makes Commercial Different

```
SCALE
  - Larger square footage, more rooms/zones, more equipment deployed
  - Higher dollar estimates ($50K-500K+ vs residential $5K-50K)
  - Longer project timelines (weeks/months vs days/weeks)

COORDINATION
  - Multiple trades on one loss (plumbing, electrical, HVAC, GC, restoration)
  - Multiple subcontractors under one GC
  - Building management company as additional stakeholder
  - Tenant vs building owner vs insurance carrier (three-party dynamic)

DOCUMENTATION
  - Business interruption calculations (lost revenue during restoration)
  - Code upgrade requirements (bring to current code, not just pre-loss)
  - Environmental compliance (asbestos, lead, mold in commercial = stricter)
  - ADA compliance for rebuilt spaces
  - Certificate of occupancy required before reoccupation

CARRIERS
  - Commercial carriers: Zurich, Chubb, Hartford, Travelers, Liberty Mutual
  - Different claims process than personal lines
  - Often use third-party administrators (TPAs)
  - Public adjusters more common on commercial losses
```

### How ZAFTO Handles Commercial Claims

```
ZAFTO's multi-trade architecture is uniquely positioned here.

SCENARIO: Office flood — burst sprinkler pipe

Trade 1: RESTORATION (mitigation)
  - Emergency water extraction
  - Drying 12,000 SF across 3 floors
  - Equipment: 24 air movers, 6 LGR dehumidifiers, 2 air scrubbers
  - 8-day drying operation
  → Job type: insurance_claim, trade: restoration

Trade 2: PLUMBING
  - Repair burst sprinkler line
  - Replace damaged pipe sections
  → Job type: insurance_claim, trade: plumbing

Trade 3: ELECTRICAL
  - Inspect and replace water-damaged panels, outlets, wiring
  - Ensure safe to energize after water exposure
  → Job type: insurance_claim, trade: electrical

Trade 4: GC (reconstruction)
  - Rebuild drywall, flooring, ceiling tiles, paint
  - ADA-compliant restroom rebuild
  - Code upgrade items
  → Job type: insurance_claim, trade: gc

ALL FOUR JOBS reference the SAME claim number.
All four import their respective Xactimate estimates via TPI.
Each contractor manages their scope independently in ZAFTO.

If the GC is the prime contractor managing all four trades:
  - GC's ZAFTO account has their own job for reconstruction
  - Subcontractor coordination via existing team/sub management
  - Single documentation package across all trades for carrier
```

### Commercial-Specific Fields (Metadata — No New Tables)

```
All commercial claim specifics live in jobs.metadata and
insurance_claims fields that already exist:

  insurance_claims.property_type    → 'commercial' (existing field)
  insurance_claims.loss_category    → 'cat' or 'non_cat' (existing)

  jobs.metadata → {
    "commercial": {
      "building_type": "office",
      "total_sf": 12000,
      "floors_affected": [1, 2, 3],
      "tenant_count": 4,
      "building_manager": {
        "name": "Apex Property Management",
        "contact": "Jane Smith",
        "phone": "405-555-1234"
      },
      "business_interruption": {
        "tracking": true,
        "estimated_daily_loss": 8500,
        "days_interrupted": 14
      },
      "code_upgrades_required": true,
      "environmental_concerns": ["asbestos_ceiling_tiles"],
      "certificate_of_occupancy_required": true
    }
  }

No new tables. The metadata JSONB field handles commercial-specific
data without bloating the schema for residential contractors who
never see any of this.
```

---

## VERTICAL 4: HOME WARRANTY NETWORK

### The Business

Home warranty companies dispatch contractors from their network to service
homeowner warranty claims. The major players:

```
COMPANY                         SERVICE CALLS/YEAR   CONTRACTOR NETWORK
American Home Shield (AHS)      ~4 million           ~15,000 contractors
Frontdoor (HSA, OneGuard)       ~3.6 million         ~18,000 contractors
Choice Home Warranty             ~1.5 million         ~8,000 contractors
Select Home Warranty             ~800K                ~5,000 contractors
First American Home Warranty     ~600K                ~4,000 contractors
Fidelity National (FNHW)        ~500K                ~3,000 contractors
Old Republic Home Protection     ~400K                ~2,500 contractors

TOTAL MARKET: $3.9B (2023) → projected $13.6B by 2030
```

### The Trades That Do Warranty Work

```
TRADE          WARRANTY VOLUME    COMMON ITEMS
HVAC           Highest            AC units, furnaces, heat pumps, ductwork
Plumbing       High               Water heaters, pipes, fixtures, sewer lines
Electrical     Medium             Panels, wiring, outlets, ceiling fans
Roofing        Low-Medium         Roof leaks (some warranty companies cover)
Appliance*     High               Washers, dryers, dishwashers, refrigerators
                                  *Not a ZAFTO trade yet but relevant

HVAC is the single biggest warranty dispatch category.
A warranty plumber/HVAC tech might do 80% warranty work.
```

### The Warranty Contractor's Pain Points

```
PROBLEM 1: MANAGING MULTIPLE WARRANTY COMPANIES
  A plumber might be in the network for AHS, Choice, AND Frontdoor.
  Each has their own portal, their own dispatch system, their own
  invoice format, their own authorization process.
  Currently: three browser tabs, three logins, three processes.
  ZAFTO: one inbox, unified dispatch view, all companies.

PROBLEM 2: WARRANTY + RETAIL IN ONE BUSINESS
  That same plumber does 60% warranty and 40% retail.
  Warranty dispatches come in through warranty portals.
  Retail leads come from Google, referrals, phone calls.
  Currently: warranty management in warranty portal + retail in CRM.
  ZAFTO: both job types in one platform, one calendar, one team.

PROBLEM 3: SERVICE FEE COLLECTION
  Homeowner owes $75-150 service fee at the door.
  Tracking who paid, who didn't, chasing uncollected fees.
  Currently: clipboard, cash box, or Square terminal with no link to job.
  ZAFTO: service fee tracked on the dispatch, collected via payment link
  or on-site terminal, auto-reconciled in Zafto Books.

PROBLEM 4: RECALL MANAGEMENT
  Warranty company sends contractor back if fix didn't hold.
  No additional service fee. Original dispatch linked.
  Currently: paper trail nightmare.
  ZAFTO: recall linked to original dispatch, full history visible.

PROBLEM 5: AUTHORIZATION LIMITS
  Each dispatch has a dollar cap. Exceed it → call for pre-auth.
  Contractor needs to know the limit before buying parts.
  Currently: printed dispatch sheet, easily lost.
  ZAFTO: authorization limit displayed on job, alert if approaching.

PROBLEM 6: CONVERTING WARRANTY CUSTOMERS TO RETAIL
  Every warranty homeowner is a potential retail customer later.
  "Hey, while I'm here for the warranty repair, I noticed your
  water heater is 15 years old. I can quote a replacement."
  Currently: no CRM linking warranty visits to retail opportunities.
  ZAFTO: same customer record, warranty history visible, upsell tracking.
```

### Warranty Network Strategy (Integration Path)

The warranty dispatch schema is already defined in `37_JOB_TYPE_SYSTEM.md`.
The go-to-market for warranty company integration follows the same
philosophy as Xactimate: integrate, don't replace.

```
PHASE 1 — MANUAL ENTRY (Launch Day)
  Contractor receives dispatch from warranty company portal.
  Creates warranty dispatch job in ZAFTO manually.
  Enters: dispatch #, warranty company, authorization limit, homeowner info.
  Manages the job lifecycle in ZAFTO.
  Invoices via warranty company portal (manual).
  VALUE: Unified calendar, one platform for warranty + retail, Zafto Books tracking.

PHASE 2 — PORTAL SCRAPING / EMAIL PARSING (3-6 Months Post-Launch)
  Most warranty companies send dispatch notifications via email.
  ZAFTO parses incoming dispatch emails and auto-creates jobs.
  Contractor confirms with one tap instead of manual data entry.
  VALUE: Reduced data entry, faster response time (SLA compliance).

PHASE 3 — API INTEGRATION (6-12 Months Post-Launch)
  Apply to warranty company contractor integration programs.
  Priority targets: AHS (largest), Frontdoor (most tech-forward).
  Auto-receive dispatches, auto-submit invoices, auto-sync status.
  VALUE: Zero-touch dispatch management, automated billing.
```

### Warranty Company Seed Data

```sql
-- Pre-populate the warranty_companies table from 37_JOB_TYPE_SYSTEM.md

INSERT INTO warranty_companies (name, short_name, type, service_fee_default, website, contractor_portal_url) VALUES
('American Home Shield', 'AHS', 'home_warranty', 100.00, 'https://www.ahs.com', 'https://contractor.ahs.com'),
('Frontdoor (HSA/OneGuard)', 'Frontdoor', 'home_warranty', 75.00, 'https://www.frontdoorhome.com', 'https://pro.frontdoorhome.com'),
('Choice Home Warranty', 'CHW', 'home_warranty', 85.00, 'https://www.choicehomewarranty.com', NULL),
('Select Home Warranty', 'SHW', 'home_warranty', 75.00, 'https://www.selecthomewarranty.com', NULL),
('First American Home Warranty', 'FAHW', 'home_warranty', 75.00, 'https://homewarranty.firstam.com', NULL),
('Fidelity National Home Warranty', 'FNHW', 'home_warranty', 75.00, 'https://www.fidelityhomewarranty.com', NULL),
('Old Republic Home Protection', 'ORHP', 'home_warranty', 85.00, 'https://www.orhp.com', NULL),
('2-10 Home Buyers Warranty', '2-10', 'home_warranty', 75.00, 'https://www.2-10.com', NULL),
('HMS Home Warranty', 'HMS', 'home_warranty', 100.00, 'https://www.hmsnational.com', NULL),
('Landmark Home Warranty', 'LHW', 'home_warranty', 70.00, 'https://www.landmarkhw.com', NULL),
('Liberty Home Guard', 'LHG', 'home_warranty', 80.00, 'https://www.libertyhomeguard.com', NULL),
('Cinch Home Services', 'Cinch', 'home_warranty', 75.00, 'https://www.cinchhomeservices.com', NULL),
('ServicePlus Home Warranty', 'SP', 'home_warranty', 75.00, 'https://www.serviceplus.com', NULL),
('Total Home Protection', 'THP', 'home_warranty', 75.00, 'https://www.totalhomeprotection.com', NULL),
('America''s Preferred Home Warranty', 'APHW', 'home_warranty', 75.00, 'https://www.aphw.com', NULL);
```


---

## PROGRESSIVE DISCLOSURE — HOW VERTICALS SURFACE

### The Core Principle

```
VERTICALS ARE NOT FEATURES. THEY ARE WORKFLOW CONFIGURATIONS.

A storm chaser doesn't enable a "storm chaser module."
They enable insurance claims (37_JOB_TYPE_SYSTEM.md),
select roofing as their trade, and start creating
insurance claim jobs with canvassing sources.

The storm-specific dashboard widgets, canvassing views,
and storm event grouping activate automatically when the
system detects the usage pattern:
  - Trade = roofing
  - Insurance module = enabled
  - Multiple jobs tagged with same storm event
  - Jobs sourced from canvassing

Same for every vertical. The system reads the data
and surfaces the right tools. No configuration wizard.
No "select your business type" dropdown.
```

### Detection Logic

```dart
// lib/services/vertical_detection_service.dart

class VerticalDetectionService {

  /// Determines which UI enhancements to show based on actual usage
  VerticalProfile detectVerticals(Company company, List<Job> recentJobs) {

    final profile = VerticalProfile();

    // Storm/Cat Roofing: roofing trade + insurance enabled + storm tags
    if (company.trades.contains('roofing') &&
        company.insuranceModuleEnabled &&
        recentJobs.where((j) =>
          j.jobType == 'insurance_claim' &&
          j.tags.any((t) => t.startsWith('storm:'))
        ).length >= 5) {
      profile.enableStormDashboard = true;
      profile.enableCanvassingView = true;
    }

    // Reconstruction: GC/remodeler + insurance enabled + claim imports
    if ((company.trades.contains('gc') || company.trades.contains('remodeler')) &&
        company.insuranceModuleEnabled &&
        recentJobs.where((j) =>
          j.jobType == 'insurance_claim' &&
          j.metadata?['reconstruction'] == true
        ).length >= 3) {
      profile.enableReconstructionView = true;
      profile.enableUpgradeTracking = true;
    }

    // Commercial: any trade + insurance + commercial property type
    if (company.insuranceModuleEnabled &&
        recentJobs.where((j) =>
          j.jobType == 'insurance_claim' &&
          j.metadata?['commercial'] != null
        ).length >= 2) {
      profile.enableCommercialDashboard = true;
    }

    // Warranty Network: warranty enabled + multiple warranty company relationships
    if (company.warrantyModuleEnabled &&
        company.warrantyRelationships.length >= 2) {
      profile.enableWarrantyNetworkView = true;
      profile.enableMultiCompanyDispatchView = true;
    }

    return profile;
  }
}
```

---

## UNIFIED DASHBOARD — ALL VERTICALS

### Revenue View (Multi-Type Contractor)

```
┌─────────────────────────────────────────────────────────────────┐
│  REVENUE BREAKDOWN — Last 90 Days                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ████████████████████████░░░░░░░░░░░░░░  $142,000 total         │
│                                                                  │
│  Retail Jobs          $58,200   41%  ████████████░░░░░░░░░░░░   │
│  Insurance Claims     $52,800   37%  ██████████░░░░░░░░░░░░░░   │
│  Warranty Dispatches  $31,000   22%  ███████░░░░░░░░░░░░░░░░░   │
│                                                                  │
│  Insurance Breakdown:                                            │
│    Restoration         $28,400  (54% of insurance)               │
│    Storm Roofing       $18,200  (34% of insurance)               │
│    Reconstruction      $6,200   (12% of insurance)               │
│                                                                  │
│  Warranty Breakdown:                                             │
│    AHS                 $14,200  (46% of warranty)                │
│    Frontdoor           $9,800   (32% of warranty)                │
│    Choice              $7,000   (22% of warranty)                │
│                                                                  │
│  Avg Job Value:                                                  │
│    Retail:     $2,425                                            │
│    Insurance:  $4,400                                            │
│    Warranty:   $385                                              │
│                                                                  │
│  [Full P&L Report] [By Trade] [By Carrier] [By Warranty Co]     │
└─────────────────────────────────────────────────────────────────┘

This is the view that locks contractors in permanently.
No other platform shows all revenue streams in one place.
```

---

## IMPLEMENTATION PRIORITY

### What Already Exists (From 36 + 37 Specs)

```
✅ job_type field (standard / insurance_claim / warranty_dispatch)
✅ Insurance claims schema (carrier, adjuster, claim tracking)
✅ Warranty dispatch schema (warranty company, authorization, service fee)
✅ Xactimate TPI integration architecture
✅ Supplement engine
✅ Progressive disclosure (module enable toggles)
✅ Three-payer accounting model
✅ Cross-trade insurance mode
✅ Restoration tools (moisture, drying, equipment)
```

### What This Spec Adds (Configuration + UI Only)

| Feature | Vertical | Effort | Priority |
|---------|----------|--------|----------|
| Storm event tagging on jobs | Storm Roofing | 2 hours | MEDIUM |
| Canvassing lead source tracking | Storm Roofing | 4 hours | MEDIUM |
| Storm event dashboard widget | Storm Roofing | 4 hours | MEDIUM |
| Canvasser performance view | Storm Roofing | 3 hours | LOW |
| Territory mapping UI | Storm Roofing | 6 hours | LOW |
| Reconstruction workflow config | Reconstruction | 2 hours | MEDIUM |
| Upgrade tracking (insurance vs OOP) | Reconstruction | 4 hours | HIGH |
| Three-section invoice (carrier/deductible/upgrade) | Reconstruction | 4 hours | HIGH |
| Commercial metadata fields | Commercial | 2 hours | LOW |
| Commercial multi-trade claim view | Commercial | 6 hours | LOW |
| Warranty company seed data | Warranty | 1 hour | HIGH |
| Multi-company dispatch inbox | Warranty | 6 hours | MEDIUM |
| Warranty-to-retail upsell tracking | Warranty | 3 hours | MEDIUM |
| Dispatch email parsing (Phase 2) | Warranty | 12 hours | FUTURE |
| Vertical detection service | All | 4 hours | MEDIUM |
| Unified revenue dashboard | All | 6 hours | HIGH |

### Phasing

```
PHASE 1 — LAUNCH (Ships with 36 + 37)
  Warranty company seed data           1 hour
  Upgrade tracking for reconstruction  4 hours
  Three-section invoice                4 hours
  Unified revenue dashboard            6 hours
  ──────────────────────────────────────────
  TOTAL:                               15 hours

PHASE 2 — POST-LAUNCH (First 3 Months)
  Storm event tagging + dashboard      10 hours
  Canvassing lead source               4 hours
  Multi-company dispatch inbox         6 hours
  Reconstruction workflow config       2 hours
  Warranty-to-retail upsell tracking   3 hours
  Vertical detection service           4 hours
  ──────────────────────────────────────────
  TOTAL:                               29 hours

PHASE 3 — SCALE (6+ Months)
  Territory mapping UI                 6 hours
  Commercial multi-trade view          6 hours
  Canvasser performance view           3 hours
  Dispatch email parsing               12 hours
  Warranty company API integrations    36 hours
  ──────────────────────────────────────────
  TOTAL:                               63 hours
```

---

## THE COMPLETE PICTURE

```
When all verticals are live, ZAFTO covers every way a contractor
touches insurance or warranty work:

TRADE           RETAIL    INSURANCE             WARRANTY
────────────    ──────    ──────────────────    ────────────────
Electrical      ✓         Fire/storm damage     AHS, Frontdoor
Plumbing        ✓         Water damage claims   AHS, Choice, FNHW
HVAC            ✓         Storm/fire damage     AHS, Frontdoor (biggest)
Solar           ✓         Storm/hail damage     Rare
Roofing         ✓         Storm chasing (mass)  Some warranty cos
GC              ✓         Reconstruction        Rare
Remodeler       ✓         Reconstruction        Rare
Landscaping     ✓         Storm cleanup         Rare
Restoration     ✓         Primary (always)      Rare

Every cell in that grid is a contractor who needs ZAFTO.
No competitor covers more than one row.
ZAFTO covers the entire grid.
```

---

## DEPENDENCIES

| This Document | Depends On |
|---------------|------------|
| All verticals | `Locked/37_JOB_TYPE_SYSTEM.md` — job_type field, progressive disclosure |
| Insurance verticals | `Locked/36_RESTORATION_INSURANCE_MODULE.md` — claims schema, TPI, supplements |
| Accounting integration | `Expansion/27_BUSINESS_OS_EXPANSION.md` — Zafto Books |
| AI features | `Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md` — Z Intelligence |
| Database schema | `Locked/29_DATABASE_MIGRATION.md` — all tables referenced |

---

## CHANGELOG

| Date | Change |
|------|--------|
| 2026-02-05 | Initial specification. Four insurance contractor verticals defined. |

---

*Every contractor touches insurance or warranty work. ZAFTO is the only platform
that handles all of it — alongside their retail business — in one place.
That's not a feature. That's a moat.*
