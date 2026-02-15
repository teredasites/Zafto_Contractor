# ZAFTO CIRCUIT BLUEPRINT
## Complete System Wiring Map — What Connects, What Doesn't, What's Missing
### February 4, 2026 — Pre-Wiring Audit (Session 28)
### Updated February 5, 2026 — Database Migration Decision (Session 29)
### Updated February 5, 2026 — MASTER MERGE (18-Document Consolidation)

---

> **DATABASE STACK (FINAL — Session 29+):**
> **Firebase `zafto-2b563` is FULLY DECOMMISSIONED. Everything on Supabase.**
> - **Database:** Supabase (PostgreSQL)
> - **Auth:** Supabase Auth (email/password, Google OAuth, Apple OAuth, phone OTP, magic links, biometric)
> - **Storage:** Supabase Storage
> - **Real-Time:** Supabase Realtime
> - **Offline Sync:** PowerSync (SQLite on device <-> PostgreSQL)
> - **Edge Functions:** Supabase Edge Functions (replacing all Cloud Functions)
> - **Security:** PostgreSQL Row-Level Security (RLS) with tenant isolation via `company_id`
> See `Locked/29_DATABASE_MIGRATION.md` for full migration spec.
> See `Locked/30_SECURITY_ARCHITECTURE.md` for security (RLS, audit, encryption).

---

## WHY THIS DOCUMENT EXISTS

You don't rough-in a house without a print. This is the print.

Before wiring Supabase across 90+ screens, we need to know exactly where every pipe goes,
which ones are connected, which ones dead-end into nothing, and which ones don't exist yet.
This document is the single source of truth for the ENTIRE data flow across all applications
(Mobile, Web Portal, Client Portal, Ops Portal, ZAFTO Home) and the Supabase backend.

**Read this BEFORE writing any wiring code.**

---

## SYSTEM OVERVIEW — FIVE VIEWS, ONE DATABASE

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    SUPABASE (PostgreSQL + Auth + Storage + Realtime)             │
│                                                                                 │
│   PostgreSQL Tables    Supabase Storage     Edge Functions (11 live + 70+ spec) │
│   ┌──────────────┐    ┌──────────────┐     ┌──────────────────────┐            │
│   │ companies    │    │ photos/      │     │ analyzePanel         │ LIVE       │
│   │ users        │    │ files/       │     │ analyzeNameplate     │ LIVE       │
│   │ jobs         │    │ receipts/    │     │ analyzeWire          │ LIVE       │
│   │ invoices     │    │ sigs/        │     │ analyzeViolation     │ LIVE       │
│   │ customers    │    │ voice_notes/ │     │ smartScan            │ LIVE       │
│   │ bids         │    │ documents/   │     │ getCredits           │ LIVE       │
│   │ employees    │    │ markups/     │     │ addCredits           │ LIVE       │
│   │ time_entries │    │ websites/    │     │ revenueCatWH         │ LIVE       │
│   │ vehicles     │    │              │     │ createPaymentIntent  │ LIVE       │
│   │ vendors      │    │              │     │ stripeWebhook        │ LIVE       │
│   │ audit_log    │    │              │     │ getPaymentStatus     │ LIVE       │
│   │ +80 more     │    │              │     │ ai-chat (unified)    │ SPEC       │
│   └──────────────┘    └──────────────┘     │ +70 more planned     │            │
│                                             └──────────────────────┘            │
└─────────────────────────┬───────────────────────────────────────────────────────┘
                          │
           ┌──────────────┼──────────────┬────────────────┬────────────────┐
           ▼              ▼              ▼                ▼                ▼
  ┌──────────────┐ ┌──────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────┐
  │  MOBILE APP  │ │ WEB CRM  │ │CLIENT PORTAL │ │  OPS PORTAL  │ │ZAFTO HOME│
  │  (Flutter)   │ │ (Next.js)│ │  (Next.js)   │ │  (Next.js)   │ │ (Next.js)│
  │  Field Tech  │ │  Office  │ │  Homeowner   │ │   Founder    │ │ Consumer │
  │  14+ tools   │ │ 40 pages │ │  21 pages    │ │  72 pages    │ │ Property │
  └──────────────┘ └──────────┘ └──────────────┘ └──────────────┘ └──────────┘
```

---

## SECTION 1: CONNECTION STATUS — EVERY WIRE IN THE SYSTEM

### Legend
```
🟢 LIVE    — Code exists, connected, functional
🟡 BUILT   — Code exists, NOT connected to backend (UI shell / mock data)
🔴 MISSING — Does not exist in codebase at all
⚫ SPEC    — Defined in documentation, zero code
```

---

### 1A. MOBILE APP — FIELD TECH INTERFACE

#### Business Screens (Hard-coded in home_screen_v2.dart, NOT in screen registry)

| Screen | UI | Service | Supabase | Status |
|--------|:--:|:-------:|:--------:|:------:|
| Home Dashboard (RIGHT NOW) | 🟡 | 🟡 Mock | 🔴 | UI reads from Riverpod state, state has mock data |
| Bids List | 🟡 | 🟡 bid_service.dart | 🔴 | Hive local, Supabase TODO |
| Bid Detail | 🟡 | 🟡 | 🔴 | Same |
| Bid Create/Builder | 🟡 | 🟡 | 🔴 | Same |
| Jobs List | 🟡 | 🟡 job_service.dart | 🔴 | Hive local, business_firestore_service exists but not wired |
| Job Detail | 🟡 | 🟡 | 🔴 | "Add Photos" button = `() {}` empty callback |
| Job Create | 🟡 | 🟡 | 🔴 | Same |
| Invoices List | 🟡 | 🟡 invoice_service.dart | 🔴 | Same pattern |
| Invoice Detail | 🟡 | 🟡 | 🔴 | PDF generation exists locally |
| Invoice Create | 🟡 | 🟡 | 🔴 | Can pre-fill from job (job->invoice link works locally) |
| Customers List | 🟡 | 🟡 customer_service.dart | 🔴 | Same |
| Customer Detail | 🟡 | 🟡 | 🔴 | Same |
| Calendar | 🟡 | 🟡 calendar_service.dart | 🔴 | Same |
| Time Clock | 🟡 | 🟡 time_clock_service.dart | 🔴 | GPS tracking code exists, no sync |
| Contract Analyzer | 🟡 | 🟡 | 🟢 | Uses Claude API cloud function |
| AI Chat | 🟡 | 🟡 | 🟢 | Uses Claude API cloud function |
| AI Scanner | 🟡 | 🟡 | 🟢 | 5 cloud functions (panel/nameplate/wire/violation/smart) |
| Command Palette (Cmd+K) | 🟡 | N/A | N/A | Only searches registry = only calculators/reference |
| Onboarding | 🟡 | 🔴 | 🔴 | UI only, doesn't create company in Supabase |

#### Field Tools (14 tools — all in lib/screens/field_tools/)

**Hub Launch:** `home_screen_v2.dart` line 672 -> `FieldToolsHubScreen()` — NO jobId passed.
**Hub Design:** Hub accepts `jobId` parameter, passes it to all child tools. But home screen doesn't provide one.
**Job Detail Launch:** "Add Photos" button -> `() {}` — does nothing.

| # | Tool | File | UI | Saves Data | Links to Job | Backend | Critical Issue |
|---|------|------|:--:|:----------:|:------------:|:-------:|----------------|
| 1 | Job Site Photos | job_site_photos_screen.dart (651 lines) | 🟡 | 🔴 | 🔴 | `// TODO: BACKEND` | `_saveAllPhotos()` shows SnackBar, data in memory only. Photos evaporate on exit. |
| 2 | Before/After | before_after_screen.dart | 🟡 | 🔴 | 🔴 | `// TODO: BACKEND` | `_saveComparison()` and `_exportComparison()` both TODO |
| 3 | Defect Markup | defect_markup_screen.dart | 🟡 | 🔴 | 🔴 | `// TODO: BACKEND` | `_saveMarkup()` is TODO |
| 4 | Voice Notes | voice_notes_screen.dart | 🟡 | 🔴 | 🔴 | `// TODO: BACKEND` | `_playNote()` = "coming soon". `_transcribeNote()` = fakes it. `_saveAllNotes()` = TODO |
| 5 | Mileage Tracker | mileage_tracker_screen.dart | 🟡 | 🔴 | 🔴 | `// TODO: BACKEND` | `_exportReport()` = TODO |
| 6 | LOTO Logger | loto_logger_screen.dart | 🟡 | 🔴 | 🔴 | `// TODO: BACKEND` | No save at all |
| 7 | Incident Report | incident_report_screen.dart | 🟡 | 🔴 | 🔴 | `// TODO: BACKEND` | `_submitReport()` = fake delay + SnackBar. No PDF generation. |
| 8 | Safety Briefing | safety_briefing_screen.dart | 🟡 | 🔴 | 🔴 | `// TODO: BACKEND` | `_showPastBriefings()` = "coming soon". No crew records saved. |
| 9 | Sun Position | sun_position_screen.dart | 🟡 | N/A | 🔴 | Standalone OK | Utility tool — standalone is acceptable |
| 11 | Confined Space | confined_space_timer_screen.dart | 🟡 | 🔴 | 🔴 | `// TODO: BACKEND` | `_generateReport()` = TODO. No OSHA compliance logging. |
| 12 | Client Signature | client_signature_screen.dart (831 lines) | 🟡 | 🔴 | 🔴 | `// TODO: BACKEND` | Captures signature image, `Future.delayed(1s)` fake save, nowhere uploaded |
| 13 | Receipt Scanner | receipt_scanner_screen.dart (936 lines) | 🟡 | 🔴 | 🔴 | `// TODO: BACKEND` | `_processReceipt()` = fake OCR delay, no actual OCR. `_exportReceipts()` = TODO |
| 14 | Level & Plumb | level_plumb_screen.dart | 🟡 | 🔴 | 🔴 | `// TODO: BACKEND` | `_saveReading()` = TODO |

**Summary: 14 tools built. 0 save data. 0 link to jobs. 0 sync to cloud. 0 flow to CRM.**

#### Content Layer — REMOVED

**Static content (calculators, diagrams, reference guides, NEC tables, exam questions) is being removed during the app revamp for each trade. Claude AI handles all calculations, code lookups, exam generation, and reference queries natively. See `Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md`.**

#### What's NOT in Screen Registry (business features — invisible to Cmd+K search)

| Screen | In Registry | In Cmd+K | Notes |
|--------|:-----------:|:-----:|-------|
| Bids (list/detail/create) | 🔴 | 🔴 | Hard-coded nav in home_screen_v2.dart |
| Jobs (list/detail/create) | 🔴 | 🔴 | Same |
| Invoices (list/detail/create) | 🔴 | 🔴 | Same |
| Customers (list/detail) | 🔴 | 🔴 | Same |
| Field Tools (all 14) | 🔴 | 🔴 | Same |
| Time Clock | 🔴 | 🔴 | Same |
| Calendar | 🔴 | 🔴 | Same |
| AI Chat | 🔴 | 🔴 | Same |
| AI Scanner | 🔴 | 🔴 | Same |
| Contract Analyzer | 🔴 | 🔴 | Same |

**The "tools" in the registry are reference content. The actual money-making business features are invisible to unified search.**

---

### 1B. SERVICES LAYER — THE PLUMBING BETWEEN UI AND SUPABASE

| Service File | What It Does | Connected To Supabase | Actually Used By |
|--------------|-------------|:---------------------:|------------------|
| `firestore_service.dart` (311 lines) | Users, exam progress, favorites, calc history, AI credits, settings | 🟢 Yes | Exam screens, calc history, favorites, AI |
| `business_firestore_service.dart` (676 lines) | Jobs, invoices, customers, bids CRUD | 🟡 Code exists, uses flat collections not company-scoped | Referenced by job/invoice/customer/bid services but data is mock |
| `photo_service.dart` (492 lines) | Photo upload to Storage + DB record | 🟡 Code exists, proper company-scoped paths, RBAC checks | **NOTHING uses it.** Field tools have their own camera code. |
| `sync_service.dart` (411 lines) | Offline queue (Hive) -> Supabase sync | 🟡 Only syncs: examProgress, favorites, calcHistory, settings, aiCredits. `jobDocuments` = TODO | Exam screens, favorites only |
| `job_service.dart` (358 lines) | Job CRUD with Hive local storage | 🟡 Hive works, Supabase push = partially wired | Job screens |
| `invoice_service.dart` | Invoice CRUD | 🟡 Same pattern | Invoice screens |
| `bid_service.dart` | Bid CRUD | 🟡 Same pattern | Bid screens |
| `customer_service.dart` | Customer CRUD | 🟡 Same pattern | Customer screens |
| `time_clock_service.dart` | Clock in/out, GPS | 🟡 Local only | Time clock screen |
| `auth_service.dart` | Supabase Auth | 🟢 Works | Login, all auth-gated features |
| `permission_service.dart` | RBAC permission checks | 🟡 Code exists, not enforced anywhere | PhotoService references it, nothing else |
| `offline_queue_service.dart` | Pending operations queue | 🟡 Exists | Not connected to field tools |
| `field_camera_service.dart` | Camera capture with stamps | 🟡 Works locally | Job Site Photos only (others use direct image_picker) |

**Critical finding:** `photo_service.dart` is a COMPLETE Storage upload service with RBAC — but zero field tools use it. They all have their own local-only camera code.

---

### 1C. WEB PORTAL CRM — OFFICE INTERFACE (40 pages at zafto.cloud)

**All 40 pages use mock data. Zero Supabase queries. Every page needs wiring.**

| Group | Pages | Mock Data | Supabase | Notes |
|-------|:-----:|:---------:|:--------:|-------|
| Dashboard (1) | Overview | 🟡 | 🔴 | Hardcoded stats |
| Leads (1) | List | 🟡 | 🔴 | Mock leads array |
| Bids (3) | List, Detail, New | 🟡 | 🔴 | Templates exist, mock bids |
| Jobs (3) | List, Detail, New | 🟡 | 🔴 | **Detail page has NO field tool data display** |
| Change Orders (1) | List | 🟡 | 🔴 | Mock data |
| Invoices (3) | List, Detail, New | 🟡 | 🔴 | Mock invoices |
| Calendar (1) | Monthly view | 🟡 | 🔴 | Mock events |
| Inspections (1) | List | 🟡 | 🔴 | Mock |
| Permits (1) | List | 🟡 | 🔴 | Mock |
| Time Clock (1) | Dashboard | 🟡 | 🔴 | Mock entries |
| Customers (3) | List, Detail, New | 🟡 | 🔴 | Mock customers |
| Communications (1) | Messages | 🟡 | 🔴 | Mock |
| Service Agreements (1) | List | 🟡 | 🔴 | Mock |
| Warranties (1) | List | 🟡 | 🔴 | Mock |
| Team (1) | Members | 🟡 | 🔴 | Mock |
| Equipment (1) | List | 🟡 | 🔴 | Mock |
| Inventory (1) | List | 🟡 | 🔴 | Mock — **no mobile tool feeds this** |
| Vendors (1) | List | 🟡 | 🔴 | Mock |
| Purchase Orders (1) | List | 🟡 | 🔴 | Mock |
| Books (1) | Financial overview | 🟡 | 🔴 | Mock — **no receipt data feeds this** |
| Price Book (1) | Services/rates | 🟡 | 🔴 | Mock |
| Documents (1) | File manager | 🟡 | 🔴 | Mock |
| Reports (1) | Analytics | 🟡 | 🔴 | Mock |
| Automations (1) | Workflows | 🟡 | 🔴 | Mock |
| Z Intelligence (6) | AI, Voice, Bid Brain, Job Cost Radar, Equipment Memory, Revenue Autopilot | 🟡 | 🔴 | All mock |
| Settings (1) | Company config | 🟡 | 🔴 | Mock |
| Login (1) | Auth | 🟡 | 🟡 | Supabase Auth configured but not tested |

---

### 1D. CLIENT PORTAL — HOMEOWNER INTERFACE (21 pages at client.zafto.cloud)

**All 21 pages use mock data. Zero Supabase queries. Same situation as web portal.**

| Tab | Pages | Mock Data | Supabase | Notes |
|-----|:-----:|:---------:|:--------:|-------|
| Auth (1) | Login | 🟡 | 🔴 | No auth flow |
| Home (1) | Action Center | 🟡 | 🔴 | Mock actions |
| Projects (5) | List, Detail, Estimate, Agreement, Live Tracker | 🟡 | 🔴 | **No field photos/updates flow here** |
| Payments (4) | Invoices, Detail, History, Methods | 🟡 | 🔴 | Mock invoices |
| My Home (3) | Profile, Equipment List, Equipment Detail | 🟡 | 🔴 | **ZAFTO Home — no equipment data flows from jobs** |
| Menu (6) | Messages, Documents, Request Service, Referrals, Review Builder, Settings | 🟡 | 🔴 | All mock |

---

### 1E. OPS PORTAL — FOUNDER INTERFACE (72 pages at ops.zafto.cloud) [Source: Doc 34]

**Status: SPEC ONLY. Zero code. Build LAST after all customer-facing features.**

| Section | Pages | Status | Purpose |
|---------|:-----:|:------:|---------|
| Command Center | 1 | ⚫ SPEC | Morning briefing, real-time metrics, action queue |
| Unified Inbox | 3 | ⚫ SPEC | All email accounts, AI triage, email-to-action |
| Accounts | 5 | ⚫ SPEC | Company directory, company detail, user directory |
| Support Center | 4 | ⚫ SPEC | Ticket queue, AI drafting, auto-resolution, KB manager |
| Platform Health | 4 | ⚫ SPEC | System status, errors, performance, infra costs |
| Revenue | 4 | ⚫ SPEC | Dashboard, subscriptions, failed payments, churn |
| Banking/Treasury | 3 | ⚫ SPEC | Plaid-connected bank accounts, categorization |
| Legal | 3 | ⚫ SPEC | Entity management, compliance tracker, document vault |
| Dev Terminal | 4 | ⚫ SPEC | Claude Code, GitHub integration, deploy manager |
| AI Operations | 3 | ⚫ SPEC | Usage, cost tracking, model management |
| Content Management | 3 | ⚫ SPEC | Calculator verification, knowledge base, trade content |
| Marketing Engine | 12 | ⚫ SPEC | Contractor discovery, campaigns, ads, SEO, landing pages, referrals |
| Growth CRM | 4 | ⚫ SPEC | Prospect pipeline, outreach, demo scheduling |
| Service Hub | 3 | ⚫ SPEC | App Store/Play Store, domain health, email delivery |
| Marketplace Ops | 3 | ⚫ SPEC | Listings, transactions, disputes |
| Communications Hub | 3 | ⚫ SPEC | Announcements, in-app messaging, changelog |
| Analytics | 3 | ⚫ SPEC | Cohort analysis, funnel, feature usage |
| Document Vault | 2 | ⚫ SPEC | Contracts, certificates, compliance docs |
| Ops AI Assistant | 1 | ⚫ SPEC | Private Claude instance with full business context |
| AI Support Sandbox | 2 | ⚫ SPEC | Test AI responses, verify calculators, reproduce bugs |

---

### 1F. UNIFIED COMMAND CENTER — EXPANSION CONCEPTS (Doc 40) [DRAFT]

| Concept | Status | Description |
|---------|:------:|-------------|
| Unified Lead Inbox | ⚫ SPEC | Multi-channel lead aggregation (Google, FB, SMS, email, web form) |
| Lead-to-Job Pipeline | ⚫ SPEC | Kanban sales pipeline with aging alerts |
| Service Catalog | ⚫ SPEC | Contractor-managed service catalog for homeowner browsing |
| Showcase Engine | ⚫ SPEC | Auto-generate marketing from completed job photos |
| Command Dashboard | ⚫ SPEC | Revenue, pipeline, collection, leads, response time, win rate |
| Review Engine | ⚫ SPEC | Automated review requests post-payment, monitoring |
| Cross-Channel Identity | ⚫ SPEC | Unified customer record across SMS, email, FB, Instagram |

---

### 1G. Z CONSOLE + ARTIFACT SYSTEM (Doc 41) [DRAFT]

| Component | Status | Description |
|-----------|:------:|-------------|
| Z Console — Pulse State | ⚫ SPEC | 40x40 floating Z mark, proactive insight surfacing |
| Z Console — Bar State | ⚫ SPEC | 18-22% viewport, frosted glass, contextual quick-action chips |
| Z Console — Full State | ⚫ SPEC | 65-70% viewport, artifact window, deep work mode |
| Artifact Templates | ⚫ SPEC | Strict template system for bids, invoices, follow-ups, scopes |
| Artifact Approval | ⚫ SPEC | Mandatory human sign-off, immutable event logging |
| Homeowner Console | ⚫ SPEC | Simplified Z Console for ZAFTO Home users |

---

### 1H. PHONE SYSTEM (Doc 31) [Source: Doc 31]

| Component | Status | Description |
|-----------|:------:|-------------|
| Telnyx VoIP Integration | ⚫ SPEC | Business phone with WebRTC + CallKit/ConnectionService |
| Auto-Attendant | ⚫ SPEC | Configurable IVR with business hours routing |
| Ring Groups | ⚫ SPEC | Simultaneous/sequential/round-robin distribution |
| Call Recording | ⚫ SPEC | Automatic recording with RBAC on playback |
| E2E Encryption | ⚫ SPEC | Internal calls encrypted end-to-end |
| Voicemail Transcription | ⚫ SPEC | AI transcription of voicemails |

---

### 1I. INSURANCE & WARRANTY SYSTEMS (Docs 37 + 38)

| Component | Status | Description |
|-----------|:------:|-------------|
| Job Type System (3 types) | ⚫ SPEC | standard, insurance_claim, warranty_dispatch with progressive disclosure |
| Warranty Companies | ⚫ SPEC | warranty_companies + company_warranty_relationships tables |
| Warranty Dispatches | ⚫ SPEC | 10-stage workflow from receive to payment |
| Insurance Verticals (4) | ⚫ SPEC | Storm/CAT Roofing, Reconstruction, Commercial Claims, Home Warranty |

---

### 1J. GROWTH ADVISOR (Doc 39)

| Component | Status | Description |
|-----------|:------:|-------------|
| Opportunity Knowledge Base | ⚫ SPEC | growth_opportunities table (curated, per trade, per state) |
| Opportunity Interactions | ⚫ SPEC | growth_opportunity_interactions table (per contractor tracking) |
| Dashboard Widget | ⚫ SPEC | Top 2 recommendations on main dashboard |
| "Grow" Tab | ⚫ SPEC | Full opportunity browser with filters |
| Z AI Proactive Triggers | ⚫ SPEC | 6 trigger types for proactive opportunity surfacing |

---

### 1K. MARKETPLACE (Doc 33)

| Component | Status | Description |
|-----------|:------:|-------------|
| Equipment Diagnostics | ⚫ SPEC | AI-powered equipment scan for homeowners |
| Lead Generation | ⚫ SPEC | Diagnostic results -> contractor leads |
| Contractor Bidding | ⚫ SPEC | Contractors bid on marketplace leads |
| Equipment Knowledge | ⚫ SPEC | Equipment database for AI diagnostics |

---

## SECTION 2: DATA FLOW ANALYSIS — WHERE THE PIPES ARE BROKEN

### 2A. THE FIELD TECH WORKFLOW (What Should Happen vs What Actually Happens)

```
WHAT SHOULD HAPPEN:
═══════════════════
Tech clocks in (GPS tracked)
     |
     v
Selects job from assigned list
     |
     v
Opens field tools -> auto-linked to job
     |
     +-->  Takes before photos -> saved to job record
     +-->  Logs safety briefing -> saved to compliance log
     +-->  Records voice note -> attached to job
     +-->  Scans receipts -> flows to job costs + Books
     +-->  Captures client signature -> attached to job
     +-->  Marks tasks complete -> job progress updates
     |
     v
Office sees real-time: photos, costs, progress, status
     |
     v
Client portal sees: live tracker, photos, completion %
```

```
WHAT ACTUALLY HAPPENS:
══════════════════════
Tech opens app
     |
     v
Taps "Field Tools" on home screen
     |
     v
FieldToolsHubScreen() <- NO jobId passed
     |
     +-->  Takes photos -> held in memory -> GONE on screen exit
     +-->  Records voice note -> "playback coming soon" -> GONE
     +-->  Scans receipt -> fake OCR delay -> GONE
     +-->  Captures signature -> 1-second fake delay -> GONE
     +-->  Files incident report -> fake submit -> GONE
     |
     v
Office sees: nothing (no data left the phone)
     |
     v
Client portal sees: nothing
```

---

### 2B. BROKEN CONNECTIONS — SPECIFIC PIPES THAT DON'T EXIST

#### Pipe 1: Field Photos -> Job Record -> Web Portal -> Client Portal
```
CURRENT STATE:
JobSitePhotosScreen -> captures to memory -> evaporates
PhotoService (exists, ready) -> NEVER CALLED
Web Portal Job Detail -> no photo section
Client Portal Live Tracker -> no photo feed

WHAT'S NEEDED:
JobSitePhotosScreen._saveAllPhotos() -> PhotoService.uploadPhoto()
PhotoService -> Supabase Storage + photos table
Web Portal Job Detail -> query photos where job_id == X
Client Portal Live Tracker -> same query, filtered by client_visible flag
```

#### Pipe 2: Client Signature -> Job/Invoice Record -> Client Portal
```
CURRENT STATE:
ClientSignatureScreen -> generates image -> fake 1s delay -> nowhere
No signatures table in schema

WHAT'S NEEDED:
ClientSignatureScreen._saveSignature() -> SignatureService.upload()
-> Supabase Storage (signature image)
-> signatures table (metadata + job link)
-> Web Portal shows signature on job/invoice detail
-> Client Portal shows signed documents
```

#### Pipe 3: Receipt Scanner -> Job Costs -> ZAFTO Books -> Tax Export
```
CURRENT STATE:
ReceiptScannerScreen -> fake OCR -> manual entry -> nowhere
No receipts table in schema
No connection to Books page on web portal

WHAT'S NEEDED:
ReceiptScannerScreen._processReceipt() -> OCR service (Claude Vision)
-> Supabase Storage (receipt image)
-> receipts table (amount, vendor, job link, category)
-> Web Portal Books page pulls receipts for P&L
-> Export to accountant (CSV/PDF)
```

#### Pipe 4: Time Clock -> Job Hours -> Invoice Line Items -> Payroll
```
CURRENT STATE:
TimeClockScreen -> local state -> nowhere
Web Portal Time Clock page -> mock data

WHAT'S BEEN BUILT (Session 28):
time_entry.dart updated with:
   - LocationPing class (continuous GPS tracking)
   - LocationTrackingConfig (pingInterval, distanceFilter, accuracy)
   - locationPings [] on ClockEntry
   - hourlyRate, laborCost, overtimeHours fields
   - totalMilesDriven (calculated from pings)

location_tracking_service.dart (449 lines) created with:
   - startTracking() / stopTracking() on clock in/out
   - pauseForBreak() / resumeAfterBreak()
   - Periodic pings (configurable: default 5 min)
   - Distance-based pings (movement detection)
   - Battery level + charging status tracking
   - Activity detection (stationary/walking/driving)
   - Hive local storage with sync queue
   - Supabase sync (push pending pings)

time_clock_service.dart integrated with location tracking

WHAT'S STILL NEEDED:
TimeClockScreen._clockIn() -> time_entries table
-> Linked to job_id + user_id
-> Continuous GPS pings flow to location_pings JSONB
-> Web Portal Time Clock shows all entries with approval workflow
-> Web Portal Live Map shows all clocked-in techs (Mapbox)
-> Invoice creation can auto-calculate labor from time entries
-> Mileage report from totalMilesDriven
-> Payroll export (hours x rate per employee)
-> Geofencing alerts (tech too far from job site)
```

#### Pipe 5: Safety Tools -> Compliance Log -> OSHA Exports
```
CURRENT STATE:
LOTO Logger -> no save
Incident Report -> fake submit
Safety Briefing -> no crew records
Confined Space Timer -> no entry log
WHAT'S NEEDED:
Each tool -> compliance_logs table
-> Web Portal Reports page shows safety compliance dashboard
-> PDF export for OSHA audits
```

#### Pipe 6: Job Completion -> Equipment Passport -> ZAFTO Home
```
CURRENT STATE:
Job status changes to "completed" -> that's it
No record of WHAT was installed
Client Portal "My Home" -> mock data

WHAT'S NEEDED:
Job completion checklist -> records equipment installed
-> equipment table (linked to property + job)
-> Client Portal "My Home" -> auto-populated equipment list
-> ZAFTO Home AI advisor has context of what's in the house
```

---

## SECTION 3: MISSING TOOLS — WHAT DOESN'T EXIST THAT THE CRM NEEDS

### 3A. Materials / Equipment Tracker -- DOES NOT EXIST
### 3B. Daily Job Log / Work Log -- DOES NOT EXIST
### 3C. Punch List / Task Checklist -- DOES NOT EXIST
### 3D. Change Order Capture -- DOES NOT EXIST

(See original document for full data model specs for each missing tool.)

---

## SECTION 4: SUPABASE TABLE GAP — WHAT'S DEFINED VS WHAT'S NEEDED

> **UPDATED: All Firestore references converted to Supabase PostgreSQL tables per Doc 29.**

### 4A. Core Schema (from Doc 29 — Locked/29_DATABASE_MIGRATION.md)

```sql
-- LIVE TABLES (defined in migration, RLS enabled)
companies         -- Tenant root, trade, subscription
users             -- Auth-linked, company_id, role
customers         -- Company-scoped CRM contacts
jobs              -- Work orders with status workflow
invoices          -- Billing with line items (JSONB)
time_entries      -- Clock in/out with GPS pings (JSONB)
bids              -- Estimates with acceptance tracking
employees         -- HR extension of users
vehicles          -- Fleet management
cpa_firms         -- External accountant firms
cpa_clients       -- CPA-to-company linkage
vendors           -- Supplier management
purchase_orders   -- PO workflow
```

### 4B. Security Tables (from Doc 30)

```sql
audit_log           -- Append-only, every data change
user_sessions       -- Device tracking, session management
login_attempts      -- Brute force protection
role_permissions    -- Customizable RBAC per company
```

### 4C. Tables That SHOULD Exist But DON'T (from expansion docs)

| Table | Fed By | Consumed By | Priority | Source Doc |
|-------|--------|-------------|:--------:|:----------:|
| `photos` | Field tools (all photo types) | Job detail, Client Portal, Showcase | P0 | 25 |
| `signatures` | Client Signature tool | Job/Invoice records, Client Portal | P0 | 25 |
| `receipts` | Receipt Scanner tool | Job costs, ZAFTO Books, Tax export | P0 | 25 |
| `voice_notes` | Voice Notes tool | Job record, transcription | P1 | 25 |
| `safety_briefings` | Safety Briefing tool | Compliance dashboard, OSHA exports | P1 | 25 |
| `incident_reports` | Incident Report tool | Insurance exports, compliance log | P1 | 25 |
| `loto_records` | LOTO Logger tool | Safety compliance, audit trail | P1 | 25 |
| `confined_space_entries` | Confined Space Timer | OSHA compliance log | P2 | 25 |
| `mileage_trips` | Mileage Tracker | Expense reports, tax deductions | P1 | 25 |
| `markup_documents` | Defect Markup tool | Job record, estimates, inspections | P1 | 25 |
| `comparisons` | Before/After tool | Job record, client sharing | P1 | 25 |
| `material_entries` | **Materials Tracker (NOT BUILT)** | Job costing, Books, Equipment Passport | P0 | 25 |
| `daily_job_logs` | **Daily Job Log (NOT BUILT)** | Job progress, client tracker | P0 | 25 |
| `job_tasks` | **Punch List (NOT BUILT)** | Job progress %, task tracking | P0 | 25 |
| `change_orders` | **Change Order (NOT BUILT)** | Bid/invoice reconciliation | P0 | 25 |
| `equipment` | Materials Tracker (installed items) | ZAFTO Home Equipment Passport | P1 | 16 |
| `warranty_companies` | Admin setup | Warranty dispatch workflow | P1 | 37 |
| `company_warranty_relationships` | Company settings | Warranty matching | P1 | 37 |
| `warranty_dispatches` | Warranty intake | 10-stage workflow | P1 | 37 |
| `leads` | Unified inbox channels | Sales pipeline | P2 | 40 |
| `customer_contacts` | Multi-channel matching | Unified customer identity | P2 | 40 |
| `customer_communications` | All channels | Conversation threading | P2 | 40 |
| `service_catalog` | Company settings | Client portal browsing | P2 | 40 |
| `project_showcases` | Auto from completed jobs | Marketing, profile | P2 | 40 |
| `review_requests` | Post-payment trigger | Review solicitation | P2 | 40 |
| `reviews` | Platform monitoring | Reputation management | P2 | 40 |
| `artifacts` | Z Console generation | Bid/invoice/follow-up delivery | P2 | 41 |
| `artifact_templates` | System + company | Template engine | P2 | 41 |
| `artifact_events` | Every artifact action | Immutable compliance audit | P2 | 41 |
| `growth_opportunities` | Tereda curation | Growth Advisor recommendations | P2 | 39 |
| `growth_opportunity_interactions` | Contractor activity | Dismiss/progress tracking | P2 | 39 |
| `code_references` | Knowledge curation | Deep-link citations in AI responses | P2 | 35 |
| `ai_user_memory` | Post-conversation analysis | Persistent AI memory (Layer 3) | P2 | 35 |
| `intelligence_patterns` | Nightly aggregation pipelines | Compounding intel (Layer 5) | P2 | 35 |
| `equipment_scans` | Marketplace diagnostics | AI equipment analysis | P3 | 33 |
| `marketplace_leads` | Diagnostic results | Contractor lead generation | P3 | 33 |
| `marketplace_bids` | Contractor responses | Marketplace bidding | P3 | 33 |
| `marketplace_contractors` | Contractor enrollment | Marketplace profiles | P3 | 33 |

---

## SECTION 5: ARCHITECTURE ISSUES TO RESOLVE BEFORE WIRING

### Issue 1: Flat vs Nested — RESOLVED
**Decision (Doc 29):** Flat tables with `company_id` field + RLS. PostgreSQL RLS auto-filters by `company_id`. No nested subcollections needed.

### Issue 2: Field Tools Don't Use Existing Services
`photo_service.dart` is complete but zero field tools use it.
**Fix:** Field camera service captures -> feeds into PhotoService for upload.

### Issue 3: Screen Registry Only Has Content
Business screens not registered. Command palette can't find "Create New Job."
**Fix:** Add business screens to registry with a `ScreenType.business` category.

### Issue 4: No Job Context Flow
Home screen launches field tools with no job context.
**Fix:** Two entry points: from job detail (auto-linked) and from home screen (job picker first).

### Issue 5: No Job Completion Workflow
**Fix:** Configurable completion requirements (photos, signature, tasks complete, daily log, materials logged).

---

## SECTION 6: REVISED WIRING ORDER — WHAT TO CONNECT FIRST

### Phase W1: Core Business Pipeline (WIRE FIRST)
**Goal:** A tech can create data that flows to the office.
~23 hours

### Phase W2: Field Tools -> Backend (WIRE SECOND)
**Goal:** Field tech data persists and flows to CRM.
~29 hours

### Phase W3: Missing Tools (BUILD THIRD)
**Goal:** CRM pipeline has all the data it needs.
~22 hours

### Phase W4: Web Portal Data Display (WIRE FOURTH)
**Goal:** Office sees everything the field captured.
~18 hours

### Phase W5: Client Portal Pipeline (WIRE FIFTH)
**Goal:** Homeowner sees their project + property data.
~13 hours

### Phase W6: Polish & Registry (LAST for core)
~19 hours

**Total W1-W6: ~120 hours of core wiring work.**

---

### Phase W7: CPA Portal [Source: Doc 27]
**Goal:** CPAs access client financials, multi-client dashboard.
~20 hours

### Phase W8: Payroll + HR Suite [Source: Doc 27]
**Goal:** Time entries -> paychecks, taxes, direct deposit, W-2/1099.
~30 hours

### Phase W9: Fleet + Route Optimization [Source: Doc 27]
**Goal:** Vehicle tracking, maintenance, AI dispatch, ETA updates.
~25 hours

### Phase W10: Procurement + Inventory [Source: Doc 27]
**Goal:** PO workflow, vendor management, truck/warehouse inventory.
~20 hours

### Phase W11: Communications (VoIP + Email Marketing) [Source: Docs 27 + 31]
**Goal:** Telnyx VoIP business phone + email campaign engine.
~25 hours

### Phase W12: Document Templates [Source: Doc 27]
**Goal:** Contracts, proposals, lien notices, e-signatures, clause library.
~15 hours

### Phase W13: Website Builder V2 [Source: Doc 28]
**Goal:** Full websites, Cloudflare Registrar API, AI templates, CRM sync.
~25 hours

### Phase W14: Insurance + Warranty Job Types [Source: Docs 37 + 38]
**Goal:** 3 job types, warranty dispatch workflow, insurance verticals.
~20 hours (69 hours per Doc 37 full spec)

### Phase W15: Unified Command Center + Z Console [Source: Docs 40 + 41]
**Goal:** Unified lead inbox, sales pipeline, showcase engine, Z Console with artifact system.
~40 hours

### Phase W16: ZAFTO Home + Marketplace [Source: Docs 16 + 33]
**Goal:** Property intelligence, equipment passport, AI diagnostics, marketplace leads.
~30 hours

### Phase W17: Growth Advisor [Source: Doc 39]
**Goal:** Opportunity knowledge base, matching logic, dashboard widget, "Grow" tab.
~22 hours (Phase 1) + 26 hours (Phase 2) + 40 hours (Phase 3) = ~88 hours total

### Phase W18: AI Architecture Full Build [Source: Doc 35]
**Goal:** 6-layer AI architecture, memory system, compounding intelligence, RBAC filter.
~60 hours

### Phase W19: Ops Portal [Source: Doc 34]
**Goal:** 72-page founder OS. Build LAST.
~80 hours

**Total W7-W19 (Expansion): ~525 hours estimated**
**Total All Phases (W1-W19): ~645 hours estimated**

---

## SECTION 7: MASTER CONNECTION MAP — THE FULL CIRCUIT

```
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                              MOBILE APP (Field Tech)                                ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                      ║
║  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                ║
║  │ Time Clock  │  │    Jobs     │  │   Invoices  │  │    Bids     │                ║
║  │ (clock in/  │  │ (view/edit  │  │ (create/    │  │ (create/    │                ║
║  │  out, GPS)  │  │  assigned)  │  │  send)      │  │  send)      │                ║
║  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                ║
║         │                │                │                │                        ║
║  ┌──────┴──────────────────────────────────┴────────────────┘                        ║
║  │  ┌──────────────────── FIELD TOOLS (14 + 4 NEW) ──────────────────┐             ║
║  │  │  DOCUMENTATION      BUSINESS        SAFETY        UTILITY       │             ║
║  │  │  Photos             Receipts        LOTO          Level         │             ║
║  │  │  Before/After       Mileage         Incident      Sun Position  │             ║
║  │  │  Markup             Signature       Briefing                    │             ║
║  │  │  Voice Notes        *Materials*     Confined                    │             ║
║  │  │  NEW: *Daily Log*   *Change Order*  *Job Complete*             │             ║
║  │  │                     *Punch List*                               │             ║
║  │  └────────────────────────────────────────────────────────────────┘             ║
║  │                                                                                  ║
║  │  ┌──── Z CONSOLE (persistent overlay, 3 states) ────┐                           ║
║  │  │  Pulse -> Bar -> Full | Artifacts | Voice Input   │                           ║
║  │  └───────────────────────────────────────────────────┘                           ║
║  │                                                                                  ║
║  │  ┌──── GROWTH ADVISOR ────┐  ┌──── PHONE SYSTEM ────┐                           ║
║  │  │  Dashboard widget      │  │  Telnyx VoIP          │                           ║
║  │  │  "Grow" tab            │  │  WebRTC calls          │                           ║
║  │  │  Z proactive triggers  │  │  Call recording        │                           ║
║  │  └────────────────────────┘  └────────────────────────┘                           ║
║  │                                                                                  ║
╚══╪══════════════════════════════════════════════════════════════════════════════════╝
   │
   │                    ALL DATA FLOWS DOWN
   │
   ▼
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                         SUPABASE BACKEND                                             ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                      ║
║  POSTGRESQL TABLES (100+)        SUPABASE STORAGE         EDGE FUNCTIONS             ║
║  ┌───────────────────────┐      ┌────────────────┐       ┌─────────────────────┐    ║
║  │ companies             │ RLS  │ /photos/       │       │ AI Scan (5)    LIVE │    ║
║  │ users                 │ RLS  │ /signatures/   │       │ Credits (2)    LIVE │    ║
║  │ jobs                  │ RLS  │ /receipts/     │       │ Payments (3)   LIVE │    ║
║  │ invoices              │ RLS  │ /voice_notes/  │       │ ai-chat        SPEC │    ║
║  │ customers             │ RLS  │ /markups/      │       │ ops-sandbox    SPEC │    ║
║  │ bids                  │ RLS  │ /documents/    │       │ +70 more       SPEC │    ║
║  │ employees             │ RLS  │ /websites/     │       └─────────────────────┘    ║
║  │ time_entries          │ RLS  └────────────────┘                                  ║
║  │ vehicles              │ RLS                                                      ║
║  │ vendors               │ RLS   POWERSYNC (Offline)                                ║
║  │ purchase_orders       │ RLS   ┌────────────────┐                                ║
║  │ audit_log             │ RLS   │ SQLite on device│                                ║
║  │ artifacts             │ RLS   │ Auto-sync to PG │                                ║
║  │ artifact_templates    │ RLS   │ Works offline   │                                ║
║  │ artifact_events       │ RLS   └────────────────┘                                ║
║  │ leads                 │ RLS                                                      ║
║  │ warranty_companies    │ RLS                                                      ║
║  │ warranty_dispatches   │ RLS                                                      ║
║  │ growth_opportunities  │ READ                                                     ║
║  │ ai_user_memory        │ RLS                                                      ║
║  │ intelligence_patterns │ RLS                                                      ║
║  │ code_references       │ READ                                                     ║
║  │ +60 more tables       │ RLS                                                      ║
║  └───────────────────────┘                                                          ║
╚══════╪═══════════════════════╪══════════════╪════════════╪═══════════╪══════════════╝
       │                       │              │            │           │
       ▼                       ▼              ▼            ▼           ▼
╔═══════════════╗  ╔═══════════════╗  ╔═══════════╗  ╔═══════════╗  ╔════════════╗
║  WEB CRM      ║  ║ CLIENT PORTAL ║  ║ OPS PORTAL║  ║ZAFTO HOME ║  ║ MARKETPLACE║
║  40 pages     ║  ║ 21 pages      ║  ║ 72 pages  ║  ║ Property  ║  ║ Equipment  ║
║  ALL MOCK     ║  ║ ALL MOCK      ║  ║ ALL SPEC  ║  ║ ALL SPEC  ║  ║ ALL SPEC   ║
╚═══════════════╝  ╚═══════════════╝  ╚═══════════╝  ╚═══════════╝  ╚════════════╝
```

---

## SECTION 8: SCORECARD — HONEST NUMBERS

### What's Built
| Category | Count | Backend Wired | Actually Works End-to-End |
|----------|:-----:|:-------------:|:-------------------------:|
| Mobile Business Screens | 15 | 0 | 0 |
| Field Tools | 14 | 0 | 0 |
| Web Portal Pages | 40 | 0 | 0 |
| Client Portal Pages | 21 | 0 | 0 |
| Ops Portal Pages | 72 | 0 (spec only) | 0 |
| Cloud Functions | 11 | 11 | 11 (AI scan + payments) |
| Content Items | 6,421 | 6,421 | 6,421 (being removed - AI replaces) |
| **TOTAL UI** | **163+ screens** | **0 business screens wired** | **0 business flows work** |

### Bottom Line
- **90 business screens** are polished UI shells with zero data persistence
- **72 Ops Portal pages** are spec only (zero code)
- **14 field tools** capture data that evaporates when you leave the screen
- **5 critical operational tools** don't exist (Materials, Daily Log, Punch List, Change Orders, Equipment Install)
- **~100+ tables** need to be created across all expansion systems
- **~120 hours** core wiring (W1-W6) before the platform functions as a connected system
- **~525 hours** expansion wiring (W7-W19) for complete Business OS
- **~645 hours** total estimated wiring work

---

## SECTION 9: FUTURE-PROOF SCHEMA — EVERY FEATURE ON THE ROADMAP

(Original Section 9 content preserved — includes 9A through 9K with ZAFTO Home, Website Builder, Books, Business Operations, Client Communication, AI Features, Multi-Trade, Schema Additions, Cloud Functions Roadmap, Storage Buckets, and Business OS Expansion summary.)

---

## SECTION 10: DECISION LOG

| # | Decision | Options | Affects | Recommendation |
|---|----------|---------|---------|----------------|
| 1 | Flat vs nested collections | A: Flat with company_id, B: Nested | All queries, security, multi-tenant | **A: Flat** — matches code, RLS handles isolation |
| 2 | jobTasks storage | A: Separate table, B: Array in jobs | Punch list, completion %, real-time | **A: Separate table** — independent updates |
| 3 | dailyJobLogs storage | A: Linked to jobs, B: Top-level | Query patterns, reporting | **B: Top-level** — enables cross-job queries |
| 4 | Property records creation | A: On job completion, B: On signup, C: Both | ZAFTO Home pipeline | **C: Both** |
| 5 | SMS provider | Twilio vs FCM | Customer comms | **Telnyx** — same provider as VoIP (Doc 31) |
| 6 | Financial data structure | A: Embedded, B: Separate ledger | Books, QB sync, tax | **B: Separate ledger** |
| 7 | Photo storage pattern | A: Per-tool, B: Unified with type | Queries, gallery features | **B: Unified** — PhotoService already works this way |
| 8 | Payroll provider | A: Build, B: Partner API | Complexity, compliance | **B: Partner** — Check.com or Gusto Embedded |
| 9 | VoIP provider | Twilio vs Vonage vs Telnyx | Quality, features | **Telnyx** — WebRTC, E2E encryption, excellent pricing (Doc 31) |
| 10 | Email service | SendGrid vs Mailgun | Deliverability | **SendGrid** — best deliverability |
| 11 | Fleet GPS | Device vs app | Accuracy, battery | **Hybrid** — app GPS + optional OBD-II |
| 12 | E-signature provider | Build vs DocuSign | Compliance, UX | **C: Hybrid** — built-in + DocuSign for enterprise |
| 13 | CPA Portal approach | Separate app vs role | Dev effort, UX | **A: Standalone** — cpa.zafto.cloud |
| 14 | Inventory tracking | Real-time vs periodic | Complexity, accuracy | **A: Real-time with offline queue** |
| 15 | Route optimization engine | Build vs Google OR-Tools vs API | Cost, quality | **B: Google OR-Tools** — open source, no per-request cost |
| 16 | Website domain handling | Subdomain vs BYOD vs Cloudflare Registrar | UX, complexity | **C: Cloudflare Registrar API** (Doc 28) |
| 17 | Website template flexibility | Full drag-drop vs strict vs hybrid | Quality, support | **B: Strict templates with AI assistant** (Doc 28) |
| 18 | Database architecture | Firebase vs Supabase | Scale, cost, queries | **B: Supabase + PostgreSQL + PowerSync** (Doc 29) |
| 19 | AI content strategy | Host code text vs deep links | Copyright, legal | **Option B: Factual knowledge + deep links** (Doc 35) |
| 20 | On-device LLM | Phi-4 Mini vs embedding model | Size, quality, battery | **SCRAPPED** — 50MB embedding model + fuzzy search (Doc 35) |
| 21 | AI memory architecture | LLM rewrites profile vs observation extraction | Safety at scale | **Observation extraction** — Haiku gate -> Sonnet extract -> deterministic merge (Doc 35) |
| 22 | Insurance job types | Separate tables vs JSONB metadata | Schema complexity | **JSONB metadata** — no new tables for verticals (Doc 38) |
| 23 | Phone encryption | Standard vs E2E for all | Complexity, security | **3-tier** — standard external, E2E internal, encrypted storage (Doc 31) |

---

## SECTION 11: AI ACCESS PATTERNS — WHAT EACH AI FEATURE READS

### 11A. AI SERVICE ACCOUNT

```
Role: ai_service
Permissions:
  READ:  ALL tables (full cross-functional awareness)
  WRITE: ONLY these tables:
    - ai_sessions           (save conversation history)
    - ai_user_memory        (Layer 3 persistent memory)
    - contract_reviews      (save analysis results)
    - compliance_checks     (save analysis results)
    - lead_scores           (write computed scores)
    - notifications         (trigger alerts/recommendations)
    - intelligence_patterns (Layer 5 aggregation output)
  NEVER WRITES:
    - jobs, invoices, customers, bids  (AI suggests, human approves)
    - financial data (transactions, accounts)
    - safety records (incidents, loto)
    - signatures, receipts (legal documents)
    - artifacts (Z Console artifact system handles this with human approval)
```

### 11B. Z INTELLIGENCE FEATURE -> TABLE ACCESS MAP

```
Z INTELLIGENCE FEATURE               TABLES IT READS
──────────────────────────────────   ─────────────────────────────────
Bid Brain                            bids, jobs, customers, price_book,
                                     material_entries, intelligence_patterns

Job Cost Radar                       jobs, time_entries, material_entries,
                                     receipts, invoices, labor_rates, change_orders

Equipment Memory                     equipment, jobs, customers, warranties,
                                     properties (ZAFTO Home)

Revenue Autopilot                    invoices, jobs, transactions, customers,
                                     bids, time_entries

Z AI (General Chat)                  ALL tables (full context)

Z Console Artifact Generation        company profile, customers, jobs, bids,
                                     invoices, artifact_templates, ai_user_memory

Growth Advisor                       companies, jobs, growth_opportunities,
                                     growth_opportunity_interactions

Lead Intelligence (Command Center)   leads, customers, customer_communications,
                                     intelligence_patterns

Showcase Engine                      jobs, photos, companies

Phone System AI (Voicemail)          call_recordings, customers, voicemail_transcripts

Marketplace Diagnostics              equipment_scans, equipment_knowledge,
                                     marketplace_leads
```

### 11C. OFFLINE INTELLIGENCE — TIERED APPROACH

```
TIER 1: FUZZY SEARCH (zero download, instant)
  Search calculator names, descriptions, tags. Always available.

TIER 2: SEMANTIC EMBEDDING (~30-50MB, download once)
  Small sentence embedding model. Handles intent mismatch.

TIER 3: CLAUDE API (when online)
  Full conversational AI. Explanations, reasoning, business intelligence.

SAFETY: RED-tier questions ALWAYS require Claude (Tier 3). Never answered locally.
```

### 11D. WIRING CHECKLIST FOR AI READINESS

Every table needs: `company_id`, `created_at`, `updated_at`, `status`, human-readable description/notes, relationship IDs for graph traversal.

---

## SECTION 12: COMPLETE DATABASE SCHEMA REGISTRY [NEW — Sources: Docs 29, 30, 37, 39, 40, 41, 33, 35]

### 12A. Core Tables (Doc 29 — Locked)

```sql
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL, trade TEXT NOT NULL, phone TEXT, email TEXT,
  address JSONB, logo_url TEXT, website_id UUID,
  subscription_tier TEXT DEFAULT 'free',
  trades TEXT[],                    -- Multi-trade support
  ai_visibility_settings JSONB DEFAULT '{}', -- Layer 6 RBAC (Doc 35)
  insurance_module_enabled BOOLEAN DEFAULT FALSE,
  warranty_module_enabled BOOLEAN DEFAULT FALSE,
  metadata JSONB DEFAULT '{}',     -- Licenses, certs, team size (Doc 39)
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  company_id UUID REFERENCES companies(id),
  email TEXT NOT NULL, name TEXT, role TEXT NOT NULL,
  phone TEXT, avatar_url TEXT, permissions JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  name TEXT NOT NULL, email TEXT, phone TEXT, address JSONB,
  type TEXT DEFAULT 'residential', source TEXT, notes TEXT, tags TEXT[],
  property_id UUID,                -- ZAFTO Home link
  portal_user_id UUID,             -- Client portal auth
  lead_score INTEGER,              -- AI lead scoring
  preferred_contact_method TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  customer_id UUID REFERENCES customers(id) NOT NULL,
  assigned_to UUID REFERENCES users(id),
  title TEXT NOT NULL, description TEXT,
  status TEXT DEFAULT 'scheduled',
  priority TEXT DEFAULT 'normal', trade TEXT,
  job_type TEXT DEFAULT 'standard', -- standard, insurance_claim, warranty_dispatch (Doc 37)
  type_metadata JSONB DEFAULT '{}', -- Progressive disclosure fields (Doc 37)
  property_id UUID,                -- ZAFTO Home link
  scheduled_start TIMESTAMPTZ, scheduled_end TIMESTAMPTZ,
  actual_start TIMESTAMPTZ, actual_end TIMESTAMPTZ,
  address JSONB, total DECIMAL(10,2), notes TEXT, tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  customer_id UUID REFERENCES customers(id) NOT NULL,
  job_id UUID REFERENCES jobs(id),
  invoice_number TEXT NOT NULL, status TEXT DEFAULT 'draft',
  subtotal DECIMAL(10,2), tax DECIMAL(10,2), total DECIMAL(10,2),
  due_date DATE, paid_at TIMESTAMPTZ, line_items JSONB DEFAULT '[]',
  notes TEXT, signature_id UUID, trade TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE time_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  user_id UUID REFERENCES users(id) NOT NULL,
  job_id UUID REFERENCES jobs(id),
  clock_in TIMESTAMPTZ NOT NULL, clock_out TIMESTAMPTZ,
  break_minutes INTEGER DEFAULT 0, total_hours DECIMAL(5,2),
  hourly_rate DECIMAL(8,2), labor_cost DECIMAL(10,2),
  overtime_hours DECIMAL(5,2), total_miles_driven DECIMAL(8,2),
  notes TEXT, location_pings JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE bids (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  customer_id UUID REFERENCES customers(id) NOT NULL,
  job_id UUID REFERENCES jobs(id),
  bid_number TEXT NOT NULL, status TEXT DEFAULT 'draft',
  subtotal DECIMAL(10,2), tax DECIMAL(10,2), total DECIMAL(10,2),
  valid_until DATE, line_items JSONB DEFAULT '[]', notes TEXT,
  trade TEXT, accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  user_id UUID REFERENCES users(id), name TEXT NOT NULL,
  email TEXT, phone TEXT, role TEXT, department TEXT,
  hire_date DATE, hourly_rate DECIMAL(8,2), salary DECIMAL(12,2),
  pay_type TEXT, status TEXT DEFAULT 'active',
  emergency_contact JSONB, documents JSONB DEFAULT '[]',
  ssn_encrypted BYTEA, bank_account_encrypted BYTEA, routing_number_encrypted BYTEA,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  make TEXT, model TEXT, year INTEGER, vin TEXT, license_plate TEXT,
  status TEXT DEFAULT 'active', current_mileage INTEGER,
  assigned_to UUID REFERENCES employees(id),
  insurance_expiry DATE, registration_expiry DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  name TEXT NOT NULL, contact_name TEXT, email TEXT, phone TEXT,
  address JSONB, payment_terms TEXT, notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE purchase_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  vendor_id UUID REFERENCES vendors(id) NOT NULL,
  job_id UUID REFERENCES jobs(id),
  po_number TEXT NOT NULL, status TEXT DEFAULT 'draft',
  total DECIMAL(10,2), line_items JSONB DEFAULT '[]', notes TEXT,
  ordered_at TIMESTAMPTZ, received_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE cpa_firms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL, email TEXT, phone TEXT, address JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE cpa_clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cpa_firm_id UUID REFERENCES cpa_firms(id) NOT NULL,
  company_id UUID REFERENCES companies(id) NOT NULL,
  access_level TEXT DEFAULT 'read',
  added_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(cpa_firm_id, company_id)
);
```

### 12B. Security Tables (Doc 30)

```sql
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID, company_id UUID, action TEXT NOT NULL,
  resource_type TEXT, resource_id UUID, old_data JSONB, new_data JSONB,
  ip_address INET, user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
-- IMMUTABLE: No UPDATE or DELETE. Append-only.

CREATE TABLE user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  device_id TEXT, device_name TEXT, ip_address INET, user_agent TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(), last_active_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL, is_revoked BOOLEAN DEFAULT FALSE,
  revoked_reason TEXT, mfa_verified BOOLEAN DEFAULT FALSE
);

CREATE TABLE login_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL, ip_address INET NOT NULL,
  success BOOLEAN NOT NULL, failure_reason TEXT,
  attempted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  role TEXT NOT NULL, resource TEXT NOT NULL,
  can_create BOOLEAN DEFAULT FALSE, can_read BOOLEAN DEFAULT FALSE,
  can_read_own BOOLEAN DEFAULT FALSE, can_update BOOLEAN DEFAULT FALSE,
  can_update_own BOOLEAN DEFAULT FALSE, can_delete BOOLEAN DEFAULT FALSE,
  can_export BOOLEAN DEFAULT FALSE, field_restrictions TEXT[],
  UNIQUE(company_id, role, resource)
);
```

### 12C. Warranty/Insurance Tables (Doc 37)

```sql
CREATE TABLE warranty_companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL, code TEXT UNIQUE NOT NULL,
  dispatch_method TEXT NOT NULL, -- 'portal', 'email', 'phone', 'api'
  portal_url TEXT, contact_phone TEXT, contact_email TEXT,
  payment_terms TEXT, avg_payment_days INTEGER,
  service_categories TEXT[], coverage_states TEXT[],
  is_active BOOLEAN DEFAULT TRUE,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE company_warranty_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  warranty_company_id UUID REFERENCES warranty_companies(id) NOT NULL,
  contractor_id_with_warranty TEXT, service_categories TEXT[],
  coverage_area JSONB, is_active BOOLEAN DEFAULT TRUE,
  avg_jobs_per_month INTEGER, avg_revenue_per_job DECIMAL(10,2),
  rating DECIMAL(3,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(company_id, warranty_company_id)
);

CREATE TABLE warranty_dispatches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  warranty_company_id UUID REFERENCES warranty_companies(id) NOT NULL,
  job_id UUID REFERENCES jobs(id),
  dispatch_number TEXT NOT NULL, -- Warranty company's reference
  status TEXT DEFAULT 'received',
  -- 10 stages: received, accepted, scheduled, diagnosed, auth_requested,
  -- authorized, work_in_progress, completed, invoiced, paid
  homeowner_name TEXT, homeowner_phone TEXT, homeowner_email TEXT,
  property_address JSONB, service_category TEXT,
  problem_description TEXT, authorization_number TEXT,
  authorized_amount DECIMAL(10,2), actual_amount DECIMAL(10,2),
  diagnosis_notes TEXT, work_performed TEXT,
  parts_used JSONB DEFAULT '[]',
  received_at TIMESTAMPTZ, scheduled_for TIMESTAMPTZ,
  completed_at TIMESTAMPTZ, invoiced_at TIMESTAMPTZ, paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 12D. Growth Advisor Tables (Doc 39)

```sql
CREATE TABLE growth_opportunities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trades TEXT[] NOT NULL, states TEXT[],
  min_team_size INTEGER DEFAULT 1, max_team_size INTEGER,
  requires_insurance_module BOOLEAN DEFAULT FALSE,
  requires_warranty_module BOOLEAN DEFAULT FALSE,
  prerequisite_certifications TEXT[],
  title TEXT NOT NULL, category TEXT NOT NULL,
  summary TEXT NOT NULL, revenue_potential TEXT,
  difficulty TEXT NOT NULL, time_to_revenue TEXT,
  action_type TEXT NOT NULL, action_url TEXT, action_steps JSONB,
  why_it_matters TEXT, common_objections JSONB, success_metrics TEXT,
  is_seasonal BOOLEAN DEFAULT FALSE,
  season_start_month INTEGER, season_end_month INTEGER, season_prep_weeks INTEGER,
  is_active BOOLEAN DEFAULT TRUE, priority INTEGER DEFAULT 50,
  last_verified DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- No RLS — public read-only content. Personalization in matching logic.

CREATE TABLE growth_opportunity_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  opportunity_id UUID NOT NULL REFERENCES growth_opportunities(id),
  status TEXT NOT NULL DEFAULT 'surfaced',
  dismissed_reason TEXT, dismiss_until TIMESTAMPTZ, notes TEXT,
  surfaced_at TIMESTAMPTZ DEFAULT NOW(), viewed_at TIMESTAMPTZ,
  dismissed_at TIMESTAMPTZ, completed_at TIMESTAMPTZ,
  UNIQUE(company_id, opportunity_id)
);
ALTER TABLE growth_opportunity_interactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "growth_interactions_isolation" ON growth_opportunity_interactions
  USING (company_id = current_setting('app.company_id')::UUID);
```

### 12E. Command Center Tables (Doc 40)

```sql
CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  customer_id UUID REFERENCES customers(id),
  source_channel TEXT NOT NULL, source_raw JSONB,
  contact_name TEXT, contact_phone TEXT, contact_email TEXT,
  message TEXT, service_requested TEXT,
  status TEXT DEFAULT 'new', assigned_to UUID REFERENCES employees(id),
  auto_response_sent BOOLEAN DEFAULT false, auto_response_text TEXT,
  first_response_at TIMESTAMPTZ, converted_to_job_id UUID REFERENCES jobs(id),
  lost_reason TEXT, priority TEXT DEFAULT 'normal',
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE customer_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id) NOT NULL,
  contact_type TEXT NOT NULL, contact_value TEXT NOT NULL,
  is_primary BOOLEAN DEFAULT false, verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(contact_type, contact_value)
);

CREATE TABLE customer_communications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id),
  lead_id UUID REFERENCES leads(id),
  channel TEXT NOT NULL, direction TEXT NOT NULL,
  content TEXT NOT NULL, attachments JSONB,
  sent_by TEXT, ai_generated BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ, created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE service_catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  trade TEXT NOT NULL, service_name TEXT NOT NULL, description TEXT,
  price_type TEXT DEFAULT 'range', price_min DECIMAL, price_max DECIMAL,
  price_fixed DECIMAL, display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true, is_featured BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE project_showcases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  job_id UUID REFERENCES jobs(id) NOT NULL,
  trade TEXT NOT NULL, title TEXT NOT NULL, description TEXT,
  before_photos TEXT[], after_photos TEXT[],
  published_to JSONB DEFAULT '{}', published_at TIMESTAMPTZ,
  is_draft BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE review_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  customer_id UUID REFERENCES customers(id) NOT NULL,
  job_id UUID REFERENCES jobs(id) NOT NULL,
  invoice_id UUID REFERENCES invoices(id),
  status TEXT DEFAULT 'pending', request_count INTEGER DEFAULT 0,
  last_sent_at TIMESTAMPTZ, review_received BOOLEAN DEFAULT false,
  review_platform TEXT, review_rating INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  customer_id UUID REFERENCES customers(id),
  platform TEXT NOT NULL, platform_review_id TEXT,
  rating INTEGER NOT NULL, review_text TEXT, reviewer_name TEXT,
  response_text TEXT, response_sent_at TIMESTAMPTZ,
  ai_suggested_response TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 12F. Z Console / Artifact Tables (Doc 41)

```sql
CREATE TABLE artifact_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),
  template_type TEXT NOT NULL, template_name TEXT NOT NULL,
  trade TEXT, version INTEGER DEFAULT 1, is_default BOOLEAN DEFAULT false,
  structure JSONB NOT NULL, styling JSONB DEFAULT '{}',
  required_sections TEXT[] NOT NULL, ai_editable_sections TEXT[],
  requires_approval BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE artifacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  created_by UUID REFERENCES users(id) NOT NULL,
  approved_by UUID REFERENCES users(id),
  template_id UUID REFERENCES artifact_templates(id),
  template_version INTEGER,
  artifact_type TEXT NOT NULL, status TEXT DEFAULT 'draft',
  content JSONB NOT NULL, rendered_html TEXT, content_hash TEXT,
  job_id UUID REFERENCES jobs(id), customer_id UUID REFERENCES customers(id),
  bid_id UUID REFERENCES bids(id), invoice_id UUID REFERENCES invoices(id),
  lead_id UUID REFERENCES leads(id), conversation_id UUID,
  recipient_name TEXT, recipient_email TEXT, recipient_phone TEXT,
  delivery_method TEXT[], sent_at TIMESTAMPTZ, delivered_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,
  ai_model_used TEXT, ai_generated_sections TEXT[],
  ai_edit_count INTEGER DEFAULT 0, human_edit_count INTEGER DEFAULT 0,
  review_duration_seconds INTEGER,
  version INTEGER DEFAULT 1, previous_version_id UUID REFERENCES artifacts(id),
  revision_count INTEGER DEFAULT 0,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE artifact_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  artifact_id UUID REFERENCES artifacts(id) NOT NULL,
  company_id UUID REFERENCES companies(id) NOT NULL,
  user_id UUID REFERENCES users(id) NOT NULL,
  employee_id UUID REFERENCES employees(id),
  event_type TEXT NOT NULL, event_data JSONB NOT NULL,
  ip_address INET, user_agent TEXT, device_type TEXT, platform TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
-- IMMUTABLE: No UPDATE or DELETE. Retention: indefinite.
```

### 12G. AI Architecture Tables (Doc 35)

```sql
CREATE TABLE code_references (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_body TEXT NOT NULL, edition TEXT NOT NULL, section TEXT NOT NULL,
  title TEXT, topic_tags TEXT[], deep_link_url TEXT NOT NULL,
  trade TEXT NOT NULL, adopted_states TEXT[],
  state_amendment_notes JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(code_body, edition, section)
);

CREATE TABLE ai_user_memory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  company_id UUID REFERENCES companies(id),
  persona TEXT NOT NULL, memory_profile JSONB NOT NULL,
  version INTEGER DEFAULT 1, last_interaction_at TIMESTAMPTZ,
  interaction_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, persona)
);

CREATE TABLE intelligence_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pattern_type TEXT NOT NULL, trade TEXT NOT NULL,
  region TEXT, job_category TEXT,
  data JSONB NOT NULL, sample_size INTEGER NOT NULL,
  confidence FLOAT, min_sample_threshold INTEGER DEFAULT 25,
  last_computed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(pattern_type, trade, region, job_category)
);
```

### 12H. Marketplace Tables (Doc 33)

```sql
CREATE TABLE equipment_scans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID, homeowner_id UUID,
  equipment_type TEXT, brand TEXT, model TEXT,
  photos TEXT[], ai_diagnosis JSONB,
  urgency TEXT, recommended_action TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE marketplace_leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_id UUID REFERENCES equipment_scans(id),
  service_type TEXT, location JSONB,
  status TEXT DEFAULT 'open', budget_range TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE marketplace_bids (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id UUID REFERENCES marketplace_leads(id),
  contractor_company_id UUID REFERENCES companies(id),
  amount DECIMAL(10,2), message TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE marketplace_contractors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),
  trades TEXT[], service_area JSONB,
  rating DECIMAL(3,2), review_count INTEGER DEFAULT 0,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 12I. Ops Portal Tables (Doc 34)

```sql
CREATE TABLE support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),
  user_id UUID, subject TEXT, description TEXT,
  category TEXT, priority TEXT DEFAULT 'medium',
  status TEXT DEFAULT 'new', assigned_to TEXT,
  ai_draft_response TEXT, ai_category TEXT,
  resolution_notes TEXT, satisfaction_score INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE support_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES support_tickets(id),
  sender TEXT NOT NULL, content TEXT NOT NULL,
  attachments JSONB, is_internal BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE knowledge_base (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL, content TEXT NOT NULL,
  category TEXT, tags TEXT[], trade TEXT,
  view_count INTEGER DEFAULT 0, helpful_count INTEGER DEFAULT 0,
  is_published BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Total Table Count: ~100+ tables across all expansion systems.**

---

## SECTION 13: MASTER EDGE FUNCTION REGISTRY [NEW — Sources: Docs 27, 29, 31, 34, 35, 37, 40]

### 13A. LIVE Edge Functions (11)

| Function | Trigger | Purpose | Status |
|----------|---------|---------|:------:|
| `analyzePanel` | HTTP | AI panel analysis | LIVE |
| `analyzeNameplate` | HTTP | AI nameplate reading | LIVE |
| `analyzeWire` | HTTP | AI wire identification | LIVE |
| `analyzeViolation` | HTTP | AI violation detection | LIVE |
| `smartScan` | HTTP | Universal AI scanner | LIVE |
| `getCredits` | HTTP | AI credit balance | LIVE |
| `addCredits` | HTTP | Purchase AI credits | LIVE |
| `revenueCatWebhook` | HTTP | Subscription management | LIVE |
| `createPaymentIntent` | HTTP | Stripe payment | LIVE |
| `stripeWebhook` | HTTP | Payment confirmation | LIVE |
| `getPaymentStatus` | HTTP | Check payment | LIVE |

### 13B. Core Wiring Phase Functions (W1-W6)

| Function | Phase | Purpose |
|----------|:-----:|---------|
| `receiptOCR` | W2 | Claude Vision receipt scanning |
| `generatePDF` | W2 | Safety reports, compliance docs |
| `onJobComplete` | W3 | Auto-create equipment passport entries |
| `calculateOvertimeHours` | W1 | 8hr/day and 40hr/week rules |
| `syncTimeClock` | W1 | Batch sync GPS pings |
| `geofenceAlert` | W1 | Tech >1mi from job for >15min |
| `timesheetReminder` | W1 | Push notification for forgotten clock-out |
| `payrollExport` | W1 | CSV/PDF for payroll period |

### 13C. AI Architecture Functions (Doc 35)

| Function | Purpose |
|----------|---------|
| `ai-chat` | **Unified AI brain** — single entry point for all AI interactions, all 6 layers |
| `ai-memory-gate` | Haiku gate check: worth remembering? |
| `ai-memory-extract` | Sonnet observation extraction |
| `ai-memory-consolidate` | Weekly profile consolidation |
| `compute-job-duration-patterns` | Nightly: Layer 5 job duration aggregation |
| `compute-bid-pricing-patterns` | Nightly: Layer 5 bid pricing aggregation |
| `compute-equipment-lifespan` | Weekly: Layer 5 equipment lifespan |
| `compute-material-cost-patterns` | Nightly: Layer 5 material cost aggregation |
| `compute-failure-patterns` | Weekly: Layer 5 failure pattern analysis |

### 13D. Business OS Functions (Doc 27)

| Function | System | Purpose |
|----------|--------|---------|
| `cpaClientInvite` | CPA Portal | Send invite email |
| `cpaGenerateTaxPackage` | CPA Portal | Year-end tax docs |
| `cpaGenerate1099s` | CPA Portal | 1099-NEC generation |
| `calculatePaycheck` | Payroll | Tax calculations |
| `processDirectDeposit` | Payroll | ACH batch submission |
| `generatePayStub` | Payroll | PDF pay stub |
| `generate941` | Payroll | Quarterly 941 form |
| `generateW2s` | Payroll | Year-end W-2s |
| `syncFuelCards` | Fleet | WEX/Fuelman import |
| `checkVehicleRecalls` | Fleet | NHTSA recall check |
| `optimizeRoutes` | Route | AI route optimization |
| `sendETAUpdate` | Route | Customer ETA notification |
| `vendorInsuranceAlert` | Procurement | Expiring vendor insurance |
| `inventoryReorderAlert` | Procurement | Low stock alerts |
| `purchaseOrderToVendor` | Procurement | Email/fax PO |

### 13E. Ops Portal Functions (Doc 34)

| Function | Purpose |
|----------|---------|
| `ops-sandbox-execute` | AI support sandbox execution |
| `ops-calculator-verify` | Verify calculator accuracy |
| `ops-exam-verify` | Verify exam question accuracy |
| `ops-bug-reproduce` | Reproduce reported bugs |
| `ops-sandbox-metrics` | Sandbox usage metrics |

### 13F. Communications Functions (Doc 31)

| Function | Purpose |
|----------|---------|
| `telnyx-inbound-call` | Handle incoming calls |
| `telnyx-outbound-call` | Initiate outgoing calls |
| `telnyx-voicemail-transcribe` | AI voicemail transcription |
| `telnyx-sms-inbound` | Receive SMS |
| `telnyx-sms-outbound` | Send SMS |

**Total Edge Functions: 11 LIVE + ~70 SPEC = ~81 total**

---

## SECTION 14: SECURITY ARCHITECTURE INTEGRATION [NEW — Source: Doc 30]

### 14A. The 6 Security Layers

```
Layer 1: AUTHENTICATION    — Supabase Auth (email/password, Google, Apple, OTP, biometric, magic links)
Layer 2: AUTHORIZATION     — RBAC (Owner/Admin/Office/Tech/CPA/Client) with permission matrix
Layer 3: TENANT ISOLATION  — PostgreSQL RLS on EVERY table, auto-filtered by company_id
Layer 4: DATA PROTECTION   — AES-256 at rest, TLS 1.3 in transit, field-level pgcrypto for PII
Layer 5: AUDIT & MONITORING — Append-only audit_log, login tracking, anomaly alerts
Layer 6: NETWORK           — Cloudflare WAF, rate limiting, DDoS protection, CSP headers
```

### 14B. RLS Master Functions

```sql
CREATE OR REPLACE FUNCTION get_user_company_id() RETURNS UUID AS $$
  SELECT company_id FROM users WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_user_role() RETURNS TEXT AS $$
  SELECT role FROM users WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;
```

### 14C. Key RLS Policies

- **Company isolation** on all business tables: `company_id = get_user_company_id()`
- **Tech sees assigned only** on jobs: `assigned_to = auth.uid()` for tech role
- **CPA cross-company read**: via `cpa_clients` linkage table
- **Client portal**: via `portal_user_id` matching on customers table
- **Ops super_admin**: cross-tenant READ access for platform operations

### 14D. Encryption Strategy

- **At rest:** AES-256 (Supabase automatic)
- **In transit:** TLS 1.3, certificate pinning on mobile
- **Field-level (pgcrypto):** SSNs, bank accounts, routing numbers, EINs, driver's licenses
- **Envelope encryption:** Per-company encryption keys (HSM-backed for enterprise tier)
- **VoIP E2E:** Internal calls encrypted end-to-end, external calls standard TLS (Doc 31)

### 14E. Session Timeouts

| Platform | Timeout |
|----------|---------|
| Mobile | 30 days (with biometric refresh) |
| Web CRM | 8 hours idle |
| CPA Portal | 4 hours idle |
| Client Portal | 30 days |
| Ops Portal | 4 hours (MFA required, hardware key recommended) |

---

## SECTION 15: AI ARCHITECTURE INTEGRATION [NEW — Source: Doc 35]

### 15A. The 6 AI Layers

```
Layer 1: Identity Context      — Who are you? (role, trade, state, company from DB)
Layer 2: Knowledge Retrieval   — RAG with factual reference data + deep-link citations
Layer 3: Persistent Memory     — ai_user_memory table, observation extraction pipeline
Layer 4: Session Context       — Current screen, navigation history, inferred intent
Layer 5: Compounding Intel     — intelligence_patterns table, nightly aggregation
Layer 6: RBAC Intelligence     — ai_visibility_settings per company, role-based filtering
```

### 15B. Four AI Personas

| Persona | Context | Behavior |
|---------|---------|----------|
| **Field Professional** | Trade, certs, active job, company prefs | Trade peer, cites code, shows work, safety-first |
| **Homeowner** | Property, equipment, preferred contractor | Plain English, never undermines contractor, no pricing |
| **Business Owner** | Full company data, metrics, market context | Strategic + technical, pricing guidance, comparables |
| **Office Manager** | Ops data, schedule, pipeline, customer comms | Operational focus, drafts comms, pipeline velocity |

### 15C. Memory Pipeline

```
Conversation ends ->
  Step 1: Haiku gate check (is this worth remembering?) ~60-70% filtered out
  Step 2: Sonnet observation extraction (structured JSON observations)
  Step 3: Deterministic merge (TypeScript, ~100 lines, never corrupts profile)
  Step 4: JSON schema validation -> upsert to ai_user_memory
  Weekly: Profile consolidation (Sonnet reviews, prunes stale data)
  Cost: ~$0.17/month per user
```

### 15D. Compounding Intelligence Pipelines

| Pipeline | Schedule | What It Computes |
|----------|----------|-----------------|
| `compute_job_duration_patterns` | Nightly 2:00 AM | Median/p25/p75 durations, estimate accuracy |
| `compute_bid_pricing_patterns` | Nightly 2:30 AM | Pricing ranges, win rates by quartile |
| `compute_equipment_lifespan` | Weekly Sun 3:00 AM | Brand/model lifespan distributions |
| `compute_material_cost_patterns` | Nightly 3:00 AM | Regional pricing, 6-month trends |
| `compute_failure_patterns` | Weekly Sun 4:00 AM | Common failures by equipment type/age |

**Confidence thresholds:** <25 samples = silent, 25-99 = with uncertainty, 100-499 = moderate, 500+ = confident.

### 15E. RBAC Visibility Matrix (Layer 6)

| Intelligence Type | Owner | Admin | Office | Tech | Homeowner |
|-------------------|:-----:|:-----:|:------:|:----:|:---------:|
| Pricing intelligence | Y | Y | N | N | N |
| Time benchmarks | Y | Y | N | N | N |
| Margin / profitability | Y | N | N | N | N |
| Bid win/loss rates | Y | Y | Y | N | N |
| Material cost patterns | Y | Y | N | N | N |
| Equipment lifespan | Y | Y | Y | Y | Y |
| Failure/diagnostic intel | Y | Y | Y | Y | Y |
| Code compliance | Y | Y | Y | Y | Context |

---

## SECTION 16: INSURANCE & JOB TYPE WIRING [NEW — Sources: Docs 37 + 38]

### 16A. Three Job Types (Progressive Disclosure)

| Type | Description | Extra Fields |
|------|-------------|-------------|
| `standard` | Regular jobs (default) | None — base job schema |
| `insurance_claim` | Insurance restoration work | claim_number, carrier, adjuster, policy_number, deductible, supplements |
| `warranty_dispatch` | Home warranty company dispatches | dispatch_number, warranty_company_id, authorization_number, authorized_amount |

All extra fields stored in `jobs.type_metadata` JSONB column. No schema changes needed to add fields.

### 16B. Warranty Dispatch Workflow (10 Stages)

```
received -> accepted -> scheduled -> diagnosed -> auth_requested ->
authorized -> work_in_progress -> completed -> invoiced -> paid
```

### 16C. Four Insurance Verticals (Doc 38)

| Vertical | Target Trades | Implementation |
|----------|---------------|---------------|
| Storm/Catastrophe Roofing | Roofing, GC | Workflow config via Dart class, JSONB metadata |
| Property Reconstruction | GC, Remodeler | Extended job phases, permit tracking |
| Commercial Property Claims | All trades | Carrier relationship management |
| Home Warranty Network | HVAC, Plumbing, Electrical | warranty_companies + warranty_dispatches tables |

**Key decision:** Insurance verticals use JSONB metadata on existing tables, NOT new tables per vertical.

---

## SECTION 17: EXPANSION SYSTEM WIRING [NEW — Sources: Docs 27, 28, 16, 31, 33, 39, 40, 41]

### 17A. Business OS — 9 Core Systems (Doc 27)

| # | System | New Tables | New Functions | Lock-In Moat |
|---|--------|:----------:|:------------:|-------------|
| 1 | CPA Portal | 4 | 6 | CPAs bring 50-500 contractor clients |
| 2 | Payroll | 6 | 8 | Tax filings, mid-year switch impossible |
| 3 | Fleet Management | 7 | 7 | Years of vehicle history, predictive data |
| 4 | Route Optimization | 5 | 5 | AI trained on YOUR techs/jobs/territory |
| 5 | Procurement/Vendors | 7 | 6 | Vendor relationships, pricing history |
| 6 | Email Marketing | 5 | 7 | Campaign/automation refinement |
| 7 | VoIP Call Center | 5 | 8 | Business phone number lives here |
| 8 | HR Suite | 7 | 6 | Employee files, training records |
| 9 | Document Templates | 4 | 7 | Custom legal docs, signed archive |
| | **TOTALS** | **~50** | **~60** | |

### 17B. Integration Web

```
Time Clock -> Payroll -> ZAFTO Books -> CPA Portal
Fleet GPS -> Route Optimizer -> Jobs -> Invoices
VoIP Calls -> Customers -> Jobs -> Email Marketing
HR Certs -> Job Assignment -> Performance -> Payroll
Procurement -> Inventory -> Jobs -> Job Costing
Templates -> Contracts -> Jobs -> ZAFTO Books
```

### 17C. Website Builder V2 (Doc 28)

- Cloudflare Registrar API for domain purchase/management
- Strict locked templates (AI assistant for modifications)
- CRM live sync (pricing, reviews, portfolio auto-update)
- $19.99/mo + $14.99/yr domain

### 17D. ZAFTO Home Platform (Doc 16)

- Property intelligence: equipment tracking, maintenance schedules
- Free tier (basic equipment log) + Premium tier (AI advisor)
- Contractor Trust Architecture: verified contractor profiles
- Bridge between homeowner and contractor ecosystems

### 17E. Marketplace (Doc 33)

- AI equipment diagnostics for homeowners
- Diagnostic results generate contractor leads
- Contractors bid on marketplace leads with AI-powered equipment knowledge

### 17F. Unified Command Center (Doc 40)

- 7 concepts: Unified Inbox, Sales Pipeline, Service Catalog, Showcase Engine, Command Dashboard, Review Engine, Customer Identity
- Multi-channel lead aggregation (Google, FB, Instagram, SMS, email, web form)
- Z AI auto-response and lead intelligence

### 17G. Z Console + Artifact System (Doc 41)

- 3 states: Pulse (minimized), Bar (conversational), Full (deep work)
- Persistent across navigation, never unmounts
- Template-based artifact generation with mandatory human approval
- Immutable event logging for compliance

### 17H. Growth Advisor (Doc 39)

- Curated opportunity knowledge base per trade per state
- 3 layers: Contractor Profile (automatic), Opportunity KB (curated), Z Intelligence (AI matching)
- Categories: warranty_network, carrier_program, certification, government_program, seasonal, revenue_stream
- Phase 1: ~22 hours, Phase 2: ~26 hours, Phase 3: ~40 hours

---

## SECTION 18: DOC 36 — RESOLVED

**`Locked/36_RESTORATION_INSURANCE_MODULE.md`** — **RECONSTRUCTED Feb 6, 2026** (756 lines, ~78 hrs). Previously missing from disk, now reconstructed from cross-references in Docs 37, 38, 39. Contains: Restoration as 9th trade, insurance claims schema (5 new tables: insurance_claims, claim_supplements, xactimate_estimate_lines, moisture_readings, restoration_equipment), per-trade workflows (17 stages restoration, 13 roofing, 10 general), Xactimate/ESX interop, carrier management, supplement engine, cross-trade insurance mode, three-payer accounting. **LOCKED.**

---

## SECTION 19: DEVOPS & INFRASTRUCTURE WIRING [NEW — Source: Doc 32]

### 19A. Three Environments

| Environment | URL | Purpose |
|-------------|-----|---------|
| `zafto-dev` | Dev Supabase project | Break things, test features |
| `zafto-staging` | Staging Supabase project | Mirror of prod, pre-launch validation |
| `zafto-prod` | Prod Supabase project | Real customers, real data |

**Rule:** NEVER develop against prod. Schema changes: dev -> staging -> prod.

### 19B. Secrets Management

All API keys (Stripe, Anthropic, Telnyx, Supabase service role) stored in Supabase Vault (prod) or Dashboard env vars (dev/staging). Service role key NEVER in client-side code.

### 19C. CI/CD Pipeline (GitHub Actions)

```
Push to main or PR ->
  Step 1: Run Flutter tests
  Step 2: Run calculator tests (ALL formulas)
  Step 3: Run Next.js tests (web portal)
  Step 4: Run Next.js tests (client portal)
  Step 5: Run RLS policy tests (pgTAP)
  Step 6: Build apps
  Step 7: Auto-deploy to staging
  Step 8: Manual approval -> deploy to prod
```

### 19D. Monitoring Stack

| Tool | Purpose | Involvement |
|------|---------|-------------|
| Dependabot | Weekly dependency scanning, auto-PRs | Review + merge (~2 min each) |
| Sentry | Crash reporting, performance, error tracking | Check email on alert |
| GitHub Actions | Automated testing, deployment | Push code, pipeline handles rest |
| Supabase Audit Log | Every data change, login, permission check | Review on incidents only |
| RLS Policies | Tenant isolation enforcement | Automatic, can't be bypassed |

### 19E. Implementation Phases

| Phase | When | Effort |
|-------|------|--------|
| Phase 1 | NOW | ~2 hours: 3 environments, secrets, Dependabot |
| Phase 2 | During wiring | ~8-12 hours: Sentry, tests, CI/CD, incident response |
| Phase 3 | Pre-enterprise | Varies: SOC 2, DNSSEC/DMARC, pen testing |

### 19F. Test Requirements

- **Calculator tests:** 100% coverage (safety liability)
- **RLS tests:** 100% coverage (data breach prevention)
- **Business logic:** 80%+ coverage
- **Integration tests:** Offline/online sync scenarios

---

## DOCUMENT HISTORY

| Date | Session | Author | Changes |
|------|---------|--------|---------|
| Feb 4, 2026 | 28 | Claude | Created — full system audit, circuit map, wiring plan |
| Feb 5, 2026 | 29 | Claude | Database migration decision, expanded schema, Business OS summary |
| Feb 5, 2026 | MERGE | Claude | **MASTER MERGE — 18 documents consolidated. Added Sections 12-19. Updated Sections 1, 4, 6, 7, 8, 10, 11. All Supabase references corrected.** |

---

**END OF CIRCUIT BLUEPRINT — LAST UPDATED FEBRUARY 5, 2026 (Master Merge)**
**THIS IS THE WIRING DIAGRAM. UPDATE AS CONNECTIONS ARE MADE.**

**SOURCE DOCUMENTS MERGED:**
- `Locked/11_DESIGN_SYSTEM.md` — Design system (referenced)
- `Locked/29_DATABASE_MIGRATION.md` — Complete Supabase schema (Section 12A)
- `Locked/30_SECURITY_ARCHITECTURE.md` — 6-layer security model (Section 14)
- `Locked/32_DEVOPS_INFRASTRUCTURE.md` — DevOps & CI/CD (Section 19)
- `Locked/34_OPS_PORTAL.md` — Ops Portal wiring (Sections 1E, 12I, 13E)
- `Locked/37_JOB_TYPE_SYSTEM.md` — Job types & warranty (Sections 12C, 16)
- `Expansion/16_ZAFTO_HOME_PLATFORM.md` — Property intelligence (Section 17D)
- `Expansion/23_AI_INTEGRATION_SPEC.md` — AI service patterns (referenced in Section 11)
- `Expansion/26_FIELD_APP_GAP_ANALYSIS.md` — Field tool gaps (Section 1A, 3)
- `Expansion/27_BUSINESS_OS_EXPANSION.md` — 9 core systems (Sections 13D, 17A)
- `Expansion/28_WEBSITE_BUILDER_V2.md` — Website platform (Section 17C)
- `Expansion/31_PHONE_SYSTEM.md` — Telnyx VoIP (Sections 1H, 13F, 14D)
- `Expansion/33_ZAFTO_MARKETPLACE.md` — AI diagnostics marketplace (Sections 12H, 17E)
- `Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md` — 6-layer AI (Sections 12G, 13C, 15)
- `Expansion/38_INSURANCE_CONTRACTOR_VERTICALS.md` — Insurance verticals (Section 16C)
- `Expansion/39_GROWTH_ADVISOR.md` — Revenue expansion (Sections 1J, 12D, 17H)
- `Expansion/40_UNIFIED_COMMAND_CENTER.md` — Command center concepts (Sections 1F, 12E, 17F)
- `Expansion/41_Z_CONSOLE_ARTIFACT_SYSTEM.md` — Z Console + artifacts (Sections 1G, 12F, 17G)
