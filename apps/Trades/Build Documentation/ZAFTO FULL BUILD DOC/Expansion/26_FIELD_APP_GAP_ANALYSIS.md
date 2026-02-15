# ZAFTO FIELD APP — WHAT'S MISSING
## Complete Gap Analysis: Built vs Needed vs Spec'd
### February 4, 2026 — Session 28

---

> **⚠️ DATABASE MIGRATION NOTE (Session 29):**
> All "Firestore" references → Supabase PostgreSQL. All "Hive" offline → PowerSync.
> See `Locked/29_DATABASE_MIGRATION.md`. Firebase fully decommissioned.

---

## THE HONEST PICTURE

**What exists:** 14 field tools (UI only, save nothing), 15 business screens (mock data),
content layer (1,186 calculators, 111 diagrams, 5,080 exam Qs — DONE and working),
3 AI features wired to cloud (Chat, Scanner, Contract Analyzer).

**What doesn't exist:** Everything that makes a tech's day actually work.

---

## SECTION 1: WHAT'S BUILT (AND WHAT IT ACTUALLY DOES)

### 1A. Field Tools — 14 Built, 0 Functional

Every one of these is a UI shell. They capture data into memory. When the user
leaves the screen, the data is gone. None save to Firestore. None link to jobs.
None sync to the web portal. None appear in the client portal.

| # | Tool | Lines | What It Does | What It Should Do |
|---|------|:-----:|-------------|-------------------|
| 1 | Job Site Photos | 651 | Takes photos to memory → gone on exit | Save to Firebase Storage, link to job, flow to CRM + client portal |
| 2 | Before/After | — | Compares two photos in memory → gone | Save comparison, attach to job, share with client |
| 3 | Defect Markup | — | Annotates photo in memory → gone | Generate PDF, attach to job/estimate |
| 4 | Voice Notes | — | "Playback coming soon." Fake transcription | Record, attach to job, transcribe, searchable |
| 5 | Mileage Tracker | — | Tracks trip in local state → gone | Save trips, link to jobs, export for tax deduction |
| 6 | LOTO Logger | — | No save at all | Photo proof + timestamp + equipment ID → compliance log |
| 7 | Incident Report | — | Fake submit delay + SnackBar → gone | Guided form → PDF → job record → insurance export |
| 8 | Safety Briefing | — | "Past briefings coming soon" → gone | Crew sign-in, topics covered → compliance dashboard |
| 9 | Sun Position | — | Standalone utility (acceptable) | Works as-is for Solar/Landscaping |
| 11 | Confined Space | — | No report generation → gone | Track time, alert on limits, OSHA log |
| 12 | Client Signature | 831 | Captures signature → 1s fake save → gone | Upload to Storage, link to job/invoice, legal record |
| 13 | Receipt Scanner | 936 | Fake OCR delay → manual entry → gone | Real OCR, categorize, link to job costs → Books |
| 14 | Level & Plumb | — | No save → gone | Save readings to job (low priority) |

### 1B. Business Screens — 15 Built, 0 Wired

| Screen | Service Exists | Firestore | Real Data |
|--------|:--------------:|:---------:|:---------:|
| Home Dashboard | Mock Riverpod | ❌ | Hardcoded stats |
| Bids (list/detail/create) | bid_service.dart (Hive) | ❌ | Local only, no sync |
| Jobs (list/detail/create) | job_service.dart (Hive) | ❌ | Local only, no sync |
| Invoices (list/detail/create) | invoice_service.dart (Hive) | ❌ | Local only, PDF works |
| Customers (list/detail) | customer_service.dart (Hive) | ❌ | Local only, no sync |
| Calendar | calendar_service.dart | ❌ | Mock events |
| Time Clock | time_clock_service.dart | ❌ | GPS code exists, no sync |
| Onboarding | None | ❌ | Doesn't create company |

### 1C. What's Actually Working End-to-End

| Feature | Status |
|---------|--------|
| 1,186 Calculators | ✅ DONE — deterministic Dart code, all functional |
| 111 Wiring Diagrams | ✅ DONE — standalone content |
| 21 Reference Guides | ✅ DONE — standalone content |
| 9 NEC Tables | ✅ DONE — standalone content |
| 5,080 Exam Questions | ✅ DONE — syncs to Firestore (examProgress) |
| AI Chat (Claude API) | ✅ WIRED — cloud function works |
| AI Scanner (5 modes) | ✅ WIRED — 5 cloud functions |
| Contract Analyzer | ✅ WIRED — cloud function works |
| Firebase Auth | ✅ WIRED — login works |
| Command Palette (⌘K) | ✅ WORKS — but only searches content, not business features |

---

## SECTION 2: WHAT'S MISSING — CRITICAL TOOLS THAT DON'T EXIST

These tools have ZERO code. No screen, no service, no model. The web CRM has pages
that expect data from these tools, but no mobile screen creates that data.

### 2A. LAUNCH BLOCKERS — Can't Ship Without These (P0)

These are the tools required for the core workflow: tech goes to job → does work →
data flows to office → client sees progress. Without them the CRM is a shell.

| # | Missing Tool | Why It's a Blocker | CRM Pages That Need It | Est. |
|---|-------------|-------------------|----------------------|:----:|
| 1 | **Materials/Equipment Tracker** | No material costs → can't calculate job profit → Books page empty → Equipment Passport empty → client portal "My Home" permanently blank | Web: Inventory, Books, Equipment, Job Detail | 6 hrs |
| 2 | **Daily Job Log** | Manager sees "in progress" with zero detail. Client portal "Live Tracker" has nothing to show. No way to prove what was done on what day. | Web: Job Detail (activity tab), Client Portal: Live Tracker | 4 hrs |
| 3 | **Punch List / Task Checklist** | Jobs have ONE status field. No task-level tracking = no completion %, no "what's left," no granularity for client or manager | Web: Job Detail (tasks tab), Client Portal: progress | 5 hrs |
| 4 | **Change Order Capture** | Scope changes in the field with no documentation = bid vs invoice mismatch, disputes, lost revenue. Web CRM has Change Orders page — nothing feeds it | Web: Change Orders page | 4 hrs |
| 5 | **Job Completion Workflow** | Job goes from "in progress" → "completed" with one tap. No required photos, no signature, no checklist, no validation. Zero accountability. | All three apps | 3 hrs |

**Total P0 missing tools: 5 screens, ~22 hours to build**

### 2B. LAUNCH EXPECTED — Users Will Ask "Where Is This?" (P1)

Not technically blockers, but any contractor evaluating the app will expect these.
Shipping without them makes the app feel half-finished.

| # | Missing Tool | Why Users Expect It | Est. |
|---|-------------|-------------------|:----:|
| 6 | **Two-Way SMS (Twilio)** | Every contractor texts clients. "On my way," "Running late," "Job complete." Without it they leave the app to text. | 8 hrs |
| 7 | **Permit Tracker** | Contractors track permits constantly. Applied/pending/approved/rejected + expiration alerts. The CRM has a Permits page with mock data. | 4 hrs |
| 8 | **License & Insurance Tracker** | Store licenses/certs, expiration alerts 90/60/30 days, digital proof on phone. Required for bids in many jurisdictions. | 4 hrs |
| 9 | **Warranty Tracker** | Track warranties on installed equipment. Manufacturer info, expiration, callback scheduling. Feeds client portal "My Home." | 3 hrs |
| 10 | **Price Book (mobile)** | Web CRM has Price Book page. Mobile needs to read it for bid creation. Without sync, bid prices are made up on the spot. | 3 hrs |
| 11 | **Inventory/Truck Stock** | "What's on my truck?" Basic counts + low stock alerts. Web CRM has Inventory page — nothing feeds it. | 5 hrs |
| 12 | **Automated Job Updates** | "Tech is 30 min away" / "Job complete" triggered by status changes. SMS + push notification. | 4 hrs |
| 13 | **Review Request Automation** | Auto-send Google/Yelp review link after job completion. Huge for marketing. | 2 hrs |

**Total P1 missing tools: 8 features, ~33 hours to build**

### 2C. POST-LAUNCH — Phase 2+ (P2)

Good features. Not needed at launch. Build after the core pipeline works.

| # | Feature | Notes | Est. |
|---|---------|-------|:----:|
| 14 | Document Editor (Tiptap) | Contracts, proposals, scope of work. Templates with variables. | 12 hrs |
| 15 | Blueprint/Plan Viewer | View PDFs on job site, pinch-zoom, markup, attach to job. | 8 hrs |
| 16 | 1099 Subcontractor Manager | Sub profiles, W-9 storage, year-end 1099 prep. | 6 hrs |
| 17 | Equipment Rental Tracker | Rental items, return dates, daily costs, job assignment. | 4 hrs |
| 18 | COI Generator | Generate Certificates of Insurance on demand. | 3 hrs |
| 19 | Accounts Payable Tracker | Bills you owe — suppliers, subs, due dates. | 5 hrs |
| 20 | Lien Deadline Calendar | State-by-state lien deadlines, preliminary notices. | 5 hrs |
| 21 | Worksheets/Spreadsheets | Excel-like grid for estimates, takeoffs. LAST to build. | 15 hrs |
| 22 | Labor Rate Tables | Standard/emergency/weekend rates, per-tech overrides. | 3 hrs |
| 23 | Material List Generator (AI) | AI shopping lists from job descriptions. | 4 hrs |
| 24 | Geofencing System | Auto-detect arrival/departure, trigger status updates. | 8 hrs |
| 25 | Team Chat | Internal crew messaging, job channels, @mentions. | 12 hrs |
| 26 | Client Portal Messaging | Secure messages, file sharing, read receipts. | 6 hrs |
| 27 | Route Optimization | Multi-job day optimal driving order. Google Maps API. | 6 hrs |
| 28 | Dispatch Board (web only) | Drag-drop scheduling, tech rows, time blocks. | 10 hrs |
| 29 | Live Tech Map (web only) | Real-time tech locations on map. Needs geofencing first. | 8 hrs |
| 30 | AI Command Bar (web only) | Natural language queries on CRM data. Needs wired data first. | 6 hrs |

**Total P2: 17 features, ~121 hours**

### 2D. GAME CHANGERS — The Moat (P3)

These are the features that make ZAFTO different from Jobber/ServiceTitan/Housecall Pro.
Don't build until core is solid and real users are on the platform.

| # | Feature | Status | Dependency |
|---|---------|--------|-----------|
| 31 | Market Pricing Intelligence | Zero code | Needs real bid/invoice data at scale |
| 32 | Instant Client Financing | Zero code | Needs Wisetack/Greensky API integration |
| 33 | Labor Marketplace | Zero code | Needs verified user base |
| 34 | Supplier Price Comparison | Zero code | Needs supplier API partnerships |
| 35 | QuickBooks/Xero Sync | Zero code | Needs Books pipeline working first |
| 36 | Quarterly Tax Estimator | Zero code | Needs real financial data |
| 37 | Lead Scoring (AI) | Zero code | Needs real lead/conversion data |

---

## SECTION 3: THE WIRING GAP (Existing Tools That Save Nothing)

This is separate from missing tools. These tools EXIST but are non-functional.
The 120-hour wiring roadmap in `25_CIRCUIT_BLUEPRINT.md` covers this.

### Firestore Collections That Don't Exist

| Collection | Fed By (Mobile) | Consumed By (CRM/Portal) | Priority |
|------------|-----------------|--------------------------|:--------:|
| `timeEntries/` | Time Clock | Web: Time Clock, Invoice labor, Payroll | P0 |
| `signatures/` | Client Signature | Job/Invoice records, Client Portal docs | P0 |
| `receipts/` | Receipt Scanner | Job costs, Books, Tax export | P0 |
| `materialEntries/` | **Materials Tracker (NOT BUILT)** | Job costing, Books, Equipment Passport | P0 |
| `dailyJobLogs/` | **Daily Job Log (NOT BUILT)** | Job progress, client tracker | P0 |
| `jobTasks/` | **Punch List (NOT BUILT)** | Job progress %, task tracking | P0 |
| `changeOrders/` | **Change Order (NOT BUILT)** | Bid/invoice reconciliation | P0 |
| `voiceNotes/` | Voice Notes | Job record, transcription | P1 |
| `mileageTrips/` | Mileage Tracker | Expense reports, tax deductions | P1 |
| `safetyBriefings/` | Safety Briefing | Compliance dashboard | P1 |
| `incidentReports/` | Incident Report | Insurance exports | P1 |
| `lotoRecords/` | LOTO Logger | Safety compliance | P1 |
| `markupDocuments/` | Defect Markup | Job record, estimates | P1 |
| `comparisons/` | Before/After | Job record, client sharing | P1 |
| `equipment/` | Materials Tracker (installs) | Home Portal, Client Portal | P1 |
| `confinedSpaceEntries/` | Confined Space Timer | OSHA compliance | P2 |
| `levelReadings/` | Level & Plumb | Job documentation | P3 |
| `sunAnalyses/` | Sun Position | Job documentation | P3 |

### Services That Don't Exist

| Service | For What |
|---------|----------|
| `material_service.dart` | Materials/Equipment Tracker → Firestore |
| `daily_log_service.dart` | Daily Job Log → Firestore |
| `task_service.dart` | Punch List/Tasks → Firestore |
| `change_order_service.dart` | Change Orders → Firestore |
| `signature_service.dart` | Client Signature → Firebase Storage + Firestore |
| `receipt_service.dart` | Receipt Scanner → OCR + Firestore |
| `voice_note_service.dart` | Voice Notes → Firebase Storage + Firestore |
| `mileage_service.dart` | Mileage Tracker → Firestore |
| `safety_service.dart` | All safety tools → Firestore compliance collections |
| `sms_service.dart` | Two-Way SMS via Twilio |
| `notification_service.dart` | Push notifications + automated job updates |

### Broken Pipes (Data That Can't Flow)

```
Field Photo → ??? → CRM never sees it → Client never sees it
Receipt Scan → ??? → Books page has no data → No job profit calc
Time Clock → ??? → Web portal shows mock hours → Can't bill labor
Client Sig → ??? → Invoice has no proof → Disputes unresolvable
Voice Note → ??? → Transcription faked → Searchable notes impossible
Safety Log → ??? → Compliance dashboard empty → OSHA audit = trouble
Materials → TOOL DOESN'T EXIST → Equipment Passport empty → "My Home" blank
Daily Log → TOOL DOESN'T EXIST → Manager blind → Client tracker empty
Tasks → TOOL DOESN'T EXIST → No completion % → Progress unknowable
Change Order → TOOL DOESN'T EXIST → Bid ≠ Invoice → Revenue leaks
```

---

## SECTION 4: SUMMARY SCOREBOARD

| Category | Spec'd | Built (UI) | Wired | Working E2E |
|----------|:------:|:----------:|:-----:|:-----------:|
| Field Tools | 14 | 14 | 0 | 0 |
| Missing P0 Tools | 5 | 0 | 0 | 0 |
| Business Screens | 15 | 15 | 0 | 0 |
| Web CRM Pages | 40 | 40 | 0 | 0 |
| Client Portal Pages | 21 | 21 | 0 | 0 |
| Content (calcs/diagrams/etc) | — | — | — | ✅ ALL |
| AI Features (Chat/Scan/Contract) | 3 | 3 | 3 | ✅ 3 |
| Firestore Collections Needed | 19 | 0 | 0 | 0 |
| Services Needed | 11 | 0 | 0 | 0 |
| P1 Features | 8 | 0 | 0 | 0 |
| P2 Features | 17 | 0 | 0 | 0 |
| P3 Game Changers | 7 | 0 | 0 | 0 |

### The Numbers

| Metric | Count |
|--------|:-----:|
| Total screens built (all apps) | 90 |
| Screens wired to Firestore | 0 (business), 3 (AI) |
| Screens working end-to-end | Content layer + 3 AI |
| Missing P0 mobile tools (zero code) | 5 |
| Missing P1 features (zero code) | 8 |
| Missing Firestore collections | 19 |
| Missing services | 11 |
| Wiring work (existing screens) | ~120 hours |
| P0 missing tools build | ~22 hours |
| P1 features build | ~33 hours |
| **Total to functional MVP** | **~175 hours** |

---

## SECTION 5: WHAT TO BUILD NEXT (PRIORITY ORDER)

**This is the build sequence. Do not skip steps.**

```
PHASE 1: WIRE EXISTING (120 hrs — see 25_CIRCUIT_BLUEPRINT.md W1-W6)
  ├── W1: Core business CRUD (jobs, bids, invoices, customers, time clock)
  ├── W2: Field tools → backend (photos, signatures, receipts, voice, safety)
  ├── W3: Missing P0 tools (materials, daily log, punch list, change orders)
  ├── W4: Web portal data display (all 40 pages reading real data)
  ├── W5: Client portal pipeline (auth, projects, payments, My Home)
  └── W6: Polish (registry, ⌘K, offline sync, debug)

PHASE 2: P1 FEATURES (33 hrs)
  ├── Two-Way SMS (Twilio)
  ├── Automated Job Updates
  ├── Permit Tracker
  ├── License & Insurance Tracker
  ├── Warranty Tracker
  ├── Price Book sync (web → mobile)
  ├── Inventory/Truck Stock
  └── Review Request Automation

PHASE 3: P2 FEATURES (121 hrs)
  ├── Document Editor, Blueprint Viewer
  ├── 1099 Manager, AP Tracker, Lien Calendar
  ├── Dispatch Board, Live Tech Map
  ├── Team Chat, Client Messaging
  ├── Geofencing, Route Optimization
  └── AI Command Bar, Worksheets

PHASE 4: GAME CHANGERS (TBD)
  ├── Market Pricing Intelligence
  ├── Instant Client Financing
  ├── Labor Marketplace
  ├── Supplier Price Comparison
  └── QuickBooks/Xero Sync
```

---

## REFERENCE: WHERE THIS LIVES

| Document | What It Covers |
|----------|---------------|
| `25_CIRCUIT_BLUEPRINT.md` | Wiring roadmap (W1-W6), connection status, data flow, architecture decisions |
| `21_FULL_LAUNCH_SCOPE.md` | Complete feature inventory (what the platform should be at full launch) |
| `17_TOOLBOX_INVENTORY.md` | Detailed spec for all 14 field tools |
| `Expansion/16_ZAFTO_HOME_PLATFORM.md` | Master platform spec (7,620 lines, 11 appendices) |
| `00_LIVE_STATUS.md` | Current honest assessment |

---

**END OF GAP ANALYSIS — FEBRUARY 4, 2026 (Session 28)**
