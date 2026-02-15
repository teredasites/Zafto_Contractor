# ZAFTO EXPANSION SPECS — PHASES D, E, F FEATURES
## Consolidated from 14 Expansion + Locked Docs
### Last Updated: February 6, 2026

---

## HOW TO USE THIS DOC

This consolidates ALL expansion specs (Phases D, E, F) into one file. Original specs in `Expansion/` and `Locked/` folders are **DETAILED REFERENCE** — this is the summary source of truth for what gets built.

**Each feature includes:** Summary, key features, database tables, estimated hours, dependencies, integration points.

---

## EXPANSION ROADMAP (Build Order)

| Phase | System | Est. Hours | Priority |
|-------|--------|:----------:|----------|
| D1 | Job Type System (3 types) | ~69 | HIGH — unlocks insurance + warranty |
| D2 | Restoration/Insurance Module | ~78 | HIGH — 9th trade + claims |
| D3 | Insurance Contractor Verticals | ~70-100 | MEDIUM — 4 verticals |
| D4 | Ledger (full accounting) | TBD | HIGH — QB replacement |
| **D5** | **Property Management System** | **TBD** | **HIGH — NEW MOAT** |
| E1 | Universal AI Architecture | ~300-400 | MEDIUM — powers everything AI |
| E2 | Dashboard + Artifact System | ~90-120 | MEDIUM — persistent AI layer |
| E3 | Dashboard | ~100-150 | MEDIUM — lead inbox + marketing |
| E4 | Growth Advisor | ~88 | MEDIUM — revenue expansion |
| F1 | Calls (SignalWire VoIP/SMS/Fax) | ~40-55 | MEDIUM |
| F2 | Website Builder V2 | ~60-90 | MEDIUM |
| F3 | Meetings | ~70 | LOW |
| F4 | Mobile Field Toolkit (24 tools) | ~89-107 | MEDIUM |
| F5 | Integrations (9 systems) | ~180 | LOW — massive scope |
| F6 | Marketplace | ~80-120 | LOW |
| F7 | Home Portal | ~140-180 | LOW |
| F8 | Ops Portal Phases 2-4 | ~111 | LOW |
| F9 | Hiring System | ~18-22 | LOW |
| F10 | ZForge | TBD | BUILD LAST |

**Total Phases D-F: ~1,500-2,000+ hours**

---

## D1: JOB TYPE SYSTEM (LOCKED)
**Source:** `Locked/37_JOB_TYPE_SYSTEM.md` | **Est:** ~69 hrs | **Status:** Locked Specification

### Summary
Every job in ZAFTO has one of three types: `standard`, `insurance_claim`, or `warranty_dispatch`. Type controls which workflow, fields, and integrations appear. Progressive disclosure — contractors who don't use insurance/warranty never see those fields.

### Key Features
- Job Type selector (only shows if module enabled in company settings)
- Per-type workflow stages:
  - **Standard:** lead → bid → accepted → scheduled → in progress → complete → invoice → paid
  - **Insurance:** claim → scope → estimate → TPI → supplement → invoice → paid
  - **Warranty:** dispatch → intake → diagnosis → authorization → service → invoice → paid
- Per-type fields (insurance: carrier, claim #, date of loss, adjuster, deductible; warranty: dispatch #, auth limit, service fee)
- Dashboard revenue breakdown by type
- Calendar color-coding by type
- Three payment models in one ledger

### Database
- `jobs.job_type` enum: `standard`, `insurance_claim`, `warranty_dispatch`
- `TradeWorkflowConfig` — per-trade stage definitions per job type

### Dependencies
- Core job schema (existing)
- Trade pipeline definitions

### Integration
- Controls all insurance/warranty feature visibility
- Ledger recognizes three payment models
- All 4 insurance verticals (D3) apply configs per type

---

## D2: RESTORATION/INSURANCE MODULE (LOCKED)
**Source:** `Locked/36_RESTORATION_INSURANCE_MODULE.md` | **Est:** ~78 hrs | **Status:** Locked Specification

### Summary
Foundation for restoration as 9th trade + insurance claims + Xactimate TPI integration. Defines insurance claim schema, TPI workflow, supplement tracking, and restoration-specific tools (moisture readers, drying equipment logs, certificate of completion).

### Key Features
- Insurance claims table + per-trade pipeline stages
- Xactimate interop (ESX format, estimate line import)
- Carrier/adjuster management
- Supplement tracking + submission
- TPI scheduling + communication
- Moisture monitoring (daily readings, material type, target values)
- Drying logs (immutable, legal-compliant timestamped entries)
- Equipment tracking (dehumidifiers, air movers, daily rate billing)
- Certificate of Completion workflow
- Three-payer accounting (carrier + homeowner deductible + insured)

### Database
- `insurance_claims` — main claims table
- `claim_supplements` — supplement tracking
- `tpi_scheduling` — Third-Party Inspector appointments
- `xactimate_estimate_lines` — imported estimate data
- `moisture_readings` — daily logged readings
- `drying_logs` — immutable drying documentation
- `restoration_equipment` — deployed equipment, billing

### Dependencies
- Xactimate ESX API (carrier-specific)
- TPI vendor APIs (per carrier)
- Job Type System (D1)

### Integration
- Job Type System controls insurance_claim workflow
- Insurance Verticals (D3) configure per-vertical workflows
- Restoration tools available in Mobile Toolkit (F4)
- Insurance data flows to Ledger

---

## D3: INSURANCE CONTRACTOR VERTICALS
**Source:** `Expansion/38_INSURANCE_CONTRACTOR_VERTICALS.md` | **Est:** ~70-100 hrs

### Summary
Four specialized insurance verticals built on top of D1 + D2 schemas using JSONB configuration — no new tables needed. Each vertical customizes the claims pipeline, required documentation, and integration points.

### The 4 Verticals

**1. Storm/Weather Damage (~20-30 hrs)**
- Wind, hail, tree damage, flood
- Weather event correlation (date of loss → NOAA data)
- Batch claim creation (storm hits → multiple claims from same event)
- Adjuster scheduling by territory
- Aerial/drone photo workflows

**2. Reconstruction (~20-25 hrs)**
- Full structure rebuild after major damage
- Multi-phase scoping (demolition → framing → systems → finishes)
- Multi-contractor coordination
- Extended timelines (months not days)
- Draw schedules (payment milestones per phase)

**3. Commercial (~15-20 hrs)**
- Business income loss documentation
- Building owner vs tenant vs carrier complexity
- Emergency service authorization
- Larger scopes, compliance requirements

**4. Warranty Networks (~15-25 hrs)**
- AHS, Choice, Fidelity, First American, etc.
- Per-company auth limits and dispatch workflows
- Service fee tracking and collection
- Recall handling
- Warranty company API integrations

### Database
- Uses JSONB columns on existing `insurance_claims` and `jobs` tables
- No new tables required

### Dependencies
- D1 (Job Type System) + D2 (Restoration/Insurance Module)
- Per-carrier API access
- Warranty company APIs

---

## D4: ZBOOKS (FULL ACCOUNTING — QB REPLACEMENT)
**Source:** `Expansion/16_ZAFTO_HOME_PLATFORM.md` App G-J | **Est:** TBD

### Summary
Full double-entry accounting system that replaces QuickBooks. Receipt scanning, chart of accounts, P&L, balance sheet, bank sync via Plaid, CPA portal for accountant access. Revenue auto-categorizes from jobs/invoices. Three payment models (standard, insurance, warranty) reconcile automatically.

### Key Features
- Chart of accounts (standard trades COA template)
- Receipt scanning (AI-powered OCR → auto-categorize)
- Bank sync via Plaid (real-time transaction import)
- Auto-reconciliation (ZAFTO invoices → bank deposits)
- P&L, Balance Sheet, Cash Flow statements
- Tax-ready reports (1099 generation, Schedule C data)
- CPA Portal (read-only accountant access)
- Multi-entity support (if contractor has LLC + sole prop)
- Three-payer reconciliation (standard + insurance + warranty)

### Database
- `chart_of_accounts` — account types, codes, hierarchy
- `journal_entries` — double-entry ledger
- `bank_connections` — Plaid items
- `bank_transactions` — imported transactions
- `receipts` — scanned receipts with OCR data
- `tax_documents` — generated 1099s, W-2s
- `cpa_access` — accountant portal permissions

### Dependencies
- Plaid API (bank sync)
- OCR service (receipt scanning)
- Invoice/payment data from core platform
- Job Type System (D1) for payment model reconciliation

---

## D5: PROPERTY MANAGEMENT SYSTEM (NEW MOAT)
**Est:** TBD | **Status:** NEEDS DEDICATED SPEC SESSION

### The Moat
Most property management software (AppFolio, Buildium, TenantCloud) is built for property managers who HIRE contractors. ZAFTO is built for contractors who ARE the property owner. The maintenance loop closes internally:

**Tenant submits maintenance request → becomes a job in ZAFTO → contractor assigns to crew or does it themselves → no middleman, no external platform.**

### Core Features (to be spec'd in detail)
- Tenant management (lease terms, contact info, payment history)
- Lease tracking (start/end dates, renewal alerts, rent increases)
- Rent collection (Stripe, auto-charge, late fees, receipts)
- Maintenance requests → auto-create ZAFTO jobs
- Property financials (income/expenses per property, NOI, cap rate)
- Vacancy tracking + listing
- Tenant screening (credit/background check integration)
- Move-in/move-out inspections (ties to field tools)
- Property inspections (ties to Mobile Field Toolkit)
- Multi-property portfolio dashboard
- Tax documents (1099 for contractors, Schedule E data for Ledger)

### Scaling Tiers
| Tier | Units | Features |
|------|:-----:|---------|
| Solo landlord | 1-5 | Simple view, basic features |
| Small portfolio | 5-50 | Full property management |
| Large portfolio | 50-500+ | Multi-property analytics, team assignments, maintenance routing |

### Subscription Limits
- Solo tier: Not available
- Team tier: 10 units
- Business tier: 100 units
- Enterprise tier: Unlimited

### Database (preliminary)
- `properties` — address, type, units, value, acquisition date
- `units` — per-unit within multi-unit properties
- `tenants` — contact info, lease terms, payment history
- `leases` — start/end dates, rent amount, terms, renewals
- `rent_payments` — Stripe charges, receipts, late fees
- `maintenance_requests` — tenant-submitted, auto-links to jobs
- `property_inspections` — move-in/out, periodic, photos
- `property_financials` — income, expenses, NOI calculations

### Integration with ZAFTO Platform
| System | Integration |
|--------|------------|
| Ledger | Rental income/expenses auto-categorize |
| Calls | Tenant communication via business line |
| Website Builder | Property listing pages |
| Field Tools | Inspection documentation |
| Z Intelligence | Maintenance cost predictions, vacancy forecasting |
| Client Portal | Tenant portal (view lease, submit requests, pay rent) |

**NEEDS DEDICATED SPEC SESSION. Do NOT build without full spec.**

---

## E1: UNIVERSAL AI ARCHITECTURE
**Source:** `Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md` | **Est:** ~300-400 hrs

### Summary
6-layer AI architecture powering Z Intelligence across all ZAFTO surfaces. Not a chatbot — a persistent intelligent layer that knows the contractor's trade, history, customers, and patterns. Every interaction compounds knowledge.

### The 6 Layers
1. **Identity Layer** — Who is this person? Role, trade, permissions, company context
2. **Knowledge Layer** — Trade-specific knowledge retrieval (codes, specs, best practices, pricing)
3. **Memory Layer** — Persistent per-user memory (preferences, past conversations, learned patterns)
4. **Session Layer** — Current context (what screen, what job, what customer)
5. **Compounding Layer** — Platform-wide intelligence that improves from ALL contractors' usage
6. **RBAC Layer** — AI respects role permissions (tech vs admin vs owner)

### Key Features
- Claude API integration (streaming responses)
- Whisper API for voice-to-text
- Trade-specific knowledge bases (per-trade, per-state)
- Persistent memory per user (Supabase)
- Context injection from current screen/job/customer
- Compounding intelligence from anonymized aggregate data
- RBAC-filtered responses (owners see financials, techs see tasks only)

### Database
- `ai_conversations` — conversation history per user
- `ai_memory` — persistent memory entries per user
- `ai_knowledge_base` — curated trade knowledge entries
- `ai_compound_data` — anonymized aggregate insights

### Dependencies
- Claude API (Anthropic)
- Whisper API (OpenAI) or Deepgram
- Supabase (storage, real-time)
- Every core ZAFTO system (context provider)

---

## E2: Z CONSOLE + ARTIFACT SYSTEM
**Source:** `Expansion/41_Z_CONSOLE_ARTIFACT_SYSTEM.md` | **Est:** ~90-120 hrs

### Summary
Persistent intelligent layer across every screen. Not a chat widget — three states: Pulse (minimized 40x40 Z mark), Console Bar (frosted glass panel, 18-22% viewport), Full Screen (artifact review). Produces professional artifacts (bids, proposals, estimates, follow-ups) that require human approval before any action.

### Key Features
- Persistent floating Z button (never unmounts across navigation)
- Proactive insights ranked by priority (new lead > safety alert > aging bid > overdue invoice)
- Artifact generation in real-time (bids, proposals, estimates, emails, summaries)
- Approval workflow — nothing leaves platform without contractor review
- Context-specific quick actions per screen
- Homeowner version (same architecture, different artifacts)

### Database
- `z_console_state` — per-user session context
- `z_artifacts` — draft/approved/sent, linked to jobs/customers
- `z_insights` — proactive insights, dismissed or actioned

### Dependencies
- E1 (Universal AI Architecture)
- Flutter Stack architecture (console above Navigator)
- React context (web portal Z layer)

---

## E3: UNIFIED COMMAND CENTER
**Source:** `Expansion/40_UNIFIED_COMMAND_CENTER.md` | **Est:** ~100-150 hrs

### Summary
Meta Business Suite for trades. One inbox for all channels — Google Business, Facebook, Instagram, Thumbtack, Angi, SMS, email, website forms, Yelp, Nextdoor. Z auto-response (transparent, opt-in). Marketing becomes byproduct of work — project showcases auto-generated from completed job photos.

### Key Features
- Unified lead inbox (all channels → single stream)
- Channel integrations (phased: Google/Meta/SMS first, then Thumbtack/email/voicemail, then Yelp/Nextdoor)
- Z auto-response (opt-in, transparent, time-configurable)
- Project showcases (auto-generated from job photos, batch publish)
- Review monitoring (Google, Facebook, Yelp aggregated)
- Lead analytics (source tracking, close rate by channel, response time)
- Reply to any channel from one UI

### Database
- `leads` — unified inbox, source channel, status
- `customer_communications` — all messages linked to customer + lead
- `project_showcases` — auto-generated, publication status per platform
- `review_requests` — outbound review request tracking
- `reviews` — monitored reviews from all platforms

### Dependencies
- Google Business API, Meta Graph API
- SignalWire SMS (F1)
- E1 (AI for auto-response + suggested replies)

---

## E4: GROWTH ADVISOR
**Source:** `Expansion/39_GROWTH_ADVISOR.md` | **Est:** ~88 hrs (3 phases)

### Summary
AI-powered revenue expansion engine. Analyzes contractor's trade, location, job mix, certifications, and team size — then surfaces personalized opportunities: warranty network enrollment, carrier preferred vendor programs, certifications (HAAG, EPA), government programs (weatherization), seasonal work.

### Key Features
- Contractor profile analysis (auto-built from CRM data)
- Curated opportunity knowledge base (per trade, per state)
- AI matching (context-aware recommendations)
- Opportunity tracking (dismissed, saved, in-progress, completed)
- Revenue impact analytics
- Certification program integration
- Seasonal content rotation
- Z proactive triggers when contractor qualifies

### Database
- `growth_opportunities` — curated database (40 initial → 100+)
- `growth_opportunity_interactions` — per-contractor tracking
- `contractor_profile_metrics` — trade, state, revenue mix

### Dependencies
- CRM data (trades, licenses, certifications)
- E1 (AI Intelligence for recommendations)

---

## F1: CALLS (SIGNALWIRE)
**Source:** `Expansion/31_PHONE_SYSTEM.md` | **Est:** ~40-55 hrs

### Summary
Business phone system built into ZAFTO. Auto-attendant, voicemail with AI transcription, SMS, **fax (send/receive)**, call recording, E2E encryption. Replaces contractor's separate phone AND fax systems. SignalWire replaces Telnyx (Telnyx/Plivo unavailable).

### Key Features
- Business phone number (1 per user)
- Auto-attendant (IVR with business hours)
- Voicemail with Deepgram transcription
- SMS messaging (SignalWire)
- **Fax — send/receive via SignalWire API**
  - Send: upload PDF → fax to number (insurance carriers, permit offices, government)
  - Receive: inbound fax → auto-convert to PDF → store in Supabase Storage → notify user
  - Fax history log with status tracking (queued/sending/delivered/failed)
  - Fax from CRM: one-click fax estimates, invoices, permits, contracts
  - Fax from mobile: select document → enter fax number → send
- Call recording with consent
- Call escalation to video (Meetings, F3)
- Business hours routing
- E2E encryption
- SignalWire AI agent framework (SWML) for AI receptionist

### Database
- `phone_numbers` — assigned numbers per user
- `call_records` — CDR, recording path, transcription
- `voicemails` — audio + transcription
- `sms_messages` — sent/received
- `fax_records` — direction (in/out), status, from/to number, document_path, page_count, created_at

### Dependencies
- SignalWire API (Voice, SMS, Fax, Video)
- Deepgram (transcription) or SignalWire native transcription
- WebRTC

---

## F2: WEBSITE BUILDER V2
**Source:** `Expansion/28_WEBSITE_BUILDER_V2.md` | **Est:** ~60-90 hrs

### Summary
Professional contractor websites with custom domains via Cloudflare Registrar. Templates, AI content generation, booking integration, review display. $19.99/mo add-on.

### Key Features
- Cloudflare Registrar domain management
- Trade-specific templates
- AI content generation (service pages, about, blog)
- CRM sync (showcases, reviews auto-publish)
- Booking widget (ties to calendar)
- SEO optimization
- Contact forms → lead inbox (E3)

### Database
- `websites` — domain, template, settings
- `website_pages` — page content, SEO metadata
- `website_bookings` — booking widget submissions

### Dependencies
- Cloudflare API
- E1 (AI content generation)
- E3 (lead inbox for form submissions)

---

## F3: MEETINGS
**Source:** `Expansion/42_MEETING_ROOM_SYSTEM.md` | **Est:** ~70 hrs (6 phases)

### Summary
Context-aware video rooms for trades. Not Zoom — every room knows the job, customer, estimate, and insurance data. Freeze-frame + annotate, AI transcription + summary, phone-to-video escalation, booking integration.

### Phases
1. Core Video Rooms (~20 hrs) — LiveKit, 1-on-1 calls, browser join, recording
2. Smart Room + Site Walk (~15 hrs) — Context panel, freeze-frame, rear camera
3. Scheduling + Booking (~10 hrs) — Booking types, availability, public page
4. AI Intelligence + Async (~12 hrs) — Deepgram transcription, Claude summary, action items
5. Advanced (~8 hrs) — Multi-party, insurance roles, phone escalation
6. Polish (~5 hrs) — History, playback, Client Portal embed

### Database
- `meetings` — record, linked to job, recording path
- `meeting_participants` — who attended, role, join/leave time
- `meeting_captures` — annotated photos from video
- `meeting_booking_types` — scheduling configuration
- `async_videos` — recorded messages, reply threads

### Dependencies
- LiveKit (open-source WebRTC SFU)
- Deepgram (real-time transcription)
- Claude API (summary generation)
- SignalWire (SIP bridge for phone escalation, F1)

---

## F4: MOBILE FIELD TOOLKIT (25 TOOLS) + SKETCH/BID FLOW + OSHA
**Source:** `Expansion/43_MOBILE_FIELD_TOOLKIT.md` | **Est:** ~120-140 hrs (revised S85)

### Summary
Expands from 18 wired tools to 24 cross-trade tools with real backend persistence. Adds **Sketch + Bid Flow** (the killer feature) and **OSHA compliance integration**. Organized in 5 categories.

### Tool Categories

**Universal Tools (11):**
Level, Datestamp Camera, Photo/Video Doc, Time Clock + GPS, Daily Job Log, Materials Tracker, Punch List, Change Order Capture, Job Completion Workflow, Field Measurements, Voice Notes

**Communication Tools (5):**
Business Phone (F1 mobile UI), Meetings (F3 mobile UI), Walkie-Talkie/PTT, Team Chat, Client Messaging

**Insurance/Restoration Tools (5):**
Moisture Reading Logger, Drying Log, Equipment Tracker, Claim Documentation Camera, Xactimate Viewer

**Inspection/Documentation Tools (3):**
Inspection Checklist, Safety Checklist (OSHA auto-populated), Site Survey

### Sketch + Bid Flow (NEW — S85)
**The killer feature. Ties F4 + D8 (Estimates) together.**
1. Arrive at site → open "New Bid" on mobile, tablet, or team portal laptop
2. Walk rooms → take photos, enter dimensions (length, width, height, window sizes, window-to-ceiling gap)
3. Sketch editor → draw room outlines, annotate measurements, mark damage areas
4. AI code suggestion → photos + dimensions + job type → pull from D8 price book → suggested line items
5. Location-based pricing → ZIP → MSA → BLS wage data + regional material costs
6. Advanced: identify specific code from photo (Claude Vision → match to estimate_items)
7. Generate bid → rooms + codes + local pricing + sketch + photos = professional bid PDF or ESX export
8. Works everywhere: Flutter app (phone/tablet), team portal (laptop in truck), web CRM (office)

### OSHA Integration (NEW — S85)
**Free API.** [OSHA Enforcement Data](https://enforcedata.dol.gov/views/data_catalogs.php) + [ITA API](https://www.osha.gov/injuryreporting).
- Auto-populate safety briefings with relevant OSHA standards by trade/job type
- Pre-job safety checklist generated from OSHA requirements for work being performed
- Violation lookup (jobsite compliance, competitor research)
- OSHA training compliance tracking
- Makes ZAFTO look enterprise-grade to insurance companies and enterprise clients

### Database
- `field_logs` — daily job logs per technician
- `materials_logs` — materials consumed per job
- `punch_lists` — items, completion status
- `change_orders` — scope changes, photos, approval
- `job_completions` — final walkthrough, sign-off
- `field_measurements` — dimensions linked to job
- `walkie_channels` — PTT channel definitions
- `ptt_logs` — voice messages, transcription
- `moisture_readings` — daily readings
- `drying_logs` — immutable entries
- `restoration_equipment` — deployed equipment
- `inspections` — completed records, photos
- `bid_sketches` — sketch data per estimate/bid (NEW)
- `sketch_rooms` — room dimensions + annotations (NEW)
- `osha_standards` — cached OSHA reference data (NEW)

### Dependencies
- D8 (Estimates — price book, code database, estimates tables)
- F1 (Calls mobile UI)
- F3 (Meetings mobile UI)
- LiveKit (PTT audio channels)
- Deepgram (voice transcription)
- OSHA API (free)
- PowerSync (offline-first)
- E1 (AI voice assist, photo analysis — deferred to Phase E)

---

## F5: INTEGRATIONS (9 SYSTEMS)
**Source:** `Expansion/27_BUSINESS_OS_EXPANSION.md` | **Est:** ~180 hrs

### Summary
9 back-office systems that complete the business-in-a-box vision.

### The 9 Systems
1. **CPA Portal** — Accountant access to Ledger data
2. **Payroll** — Time clock → payroll calculations → direct deposit
3. **Fleet Management** — Vehicle tracking, maintenance, fuel
4. **Route Optimization** — Job scheduling + driving routes
5. **Procurement** — PO creation, vendor management, receiving
6. **HR Suite** — Employee records, onboarding, training, certifications
7. **Email System** — Business email (SendGrid transactional + marketing)
8. **Calls** — See F1 (SignalWire VoIP/SMS/Fax)
9. **Document Management** — File storage, templates, e-signatures

### Dependencies
- Bank APIs (payroll direct deposit)
- SignalWire (phone/SMS/fax)
- SendGrid (email)
- GPS/mapping APIs (fleet, route)

---

## F6: MARKETPLACE
**Source:** `Expansion/33_ZAFTO_MARKETPLACE.md` | **Est:** ~80-120 hrs

### Summary
AI equipment diagnostics, pre-qualified lead generation, contractor bidding. Homeowner scans equipment → AI identifies model, age, known issues → connects to qualified local contractors.

### Key Features
- Equipment scanning (camera → AI identification)
- Diagnostic engine (known issues per model/age)
- Lead generation (homeowner → contractor match)
- Contractor bidding on marketplace leads
- Service history tracking

### Database
- `equipment_scans` — AI identification results
- `marketplace_leads` — generated leads
- `marketplace_bids` — contractor responses
- `equipment_database` — known models, issues, lifespans

### Dependencies
- Claude API (AI identification)
- CRM integration (lead routing)
- E3 (Dashboard for lead delivery)

---

## F7: HOME PORTAL
**Source:** `Expansion/16_ZAFTO_HOME_PLATFORM.md` | **Est:** ~140-180 hrs

### Summary
Homeowner-facing property intelligence platform. Free tier: equipment tracking, service history. Premium ($7.99/mo): AI property advisor, maintenance predictions, contractor matching.

### Key Features
- Equipment passport (every system in the home, age, warranty, service history)
- Service history timeline
- Maintenance reminders (filter changes, HVAC servicing)
- AI property advisor (Z for homeowners)
- Contractor matching (from Marketplace, F6)
- Review system (post-service reviews)
- Document storage (warranties, manuals, permits)

### Database
- `homeowner_properties` — address, year built, sq ft
- `homeowner_equipment` — installed systems, model, age, warranty
- `service_history` — completed services linked to contractors
- `maintenance_schedules` — upcoming maintenance reminders
- `homeowner_documents` — warranties, manuals, permits

### Dependencies
- Client Portal (existing — becomes Home Portal)
- E1 (AI for homeowner Z assistant)
- F6 (Marketplace for contractor matching)
- F2 (Website Builder for contractor booking)

---

## F8: OPS PORTAL PHASES 2-4
**Source:** `Locked/34_OPS_PORTAL.md` | **Est:** ~111 hrs

### Summary
Internal founder operations dashboard. Phase 1 (18 pages) ships at launch. Phases 2-4 add marketing engine, treasury, legal, dev terminal, analytics.

### Phases 2-4 Pages (54 additional)
- Marketing engine (growth CRM, content, campaigns)
- Treasury (revenue analytics, churn, LTV)
- Legal (contracts, compliance, disputes)
- Dev terminal (deployment, feature flags, A/B testing)
- Ads + SEO management
- Vault (secrets management UI)
- Referral program management
- Advanced analytics

---

## F9: HIRING SYSTEM
**Source:** `Expansion/28_WEBSITE_BUILDER_V2.md` | **Est:** ~18-22 hrs

### Summary
Multi-channel job posting with applicant tracking pipeline. Post to Indeed, LinkedIn, website simultaneously. Track applications through stages.

### Key Features
- Job posting creation + multi-channel distribution
- Applicant tracking pipeline (applied → screening → interview → offer → hired)
- Resume parsing
- Interview scheduling
- Onboarding checklist integration

---

## F10: ZDOCS + ZSHEETS
**Source:** Master Build Plan | **Est:** TBD | **BUILD LAST**

### Summary
PDF-first document suite. Not Google Docs — focused on generating professional trade documents (proposals, contracts, change orders, inspection reports). Build after all features locked so document templates cover every scenario.

---

## INTEGRATION MAP

```
CORE PLATFORM (Pre-Launch)
├── CRM (jobs, bids, invoices, customers)
├── Mobile App (14 field tools → F4: 24 tools)
├── Web Portal (40 CRM pages)
├── Client Portal (21 pages → F7: Home Portal)
└── Database (Supabase PostgreSQL)

PHASE D: REVENUE ENGINE (D1-D5)
├── D1: Job Type System ──→ unlocks D2, D3
├── D2: Restoration/Insurance ──→ 9th trade
├── D3: Insurance Verticals ──→ 4 specializations
├── D4: Ledger ──→ QB replacement
└── D5: Property Management ──→ THE MOAT

PHASE E: AI LAYER (E1-E4)
├── E1: Universal AI ──→ powers EVERYTHING below
├── E2: Dashboard ──→ persistent AI on every screen
├── E3: Dashboard ──→ one inbox, all channels
└── E4: Growth Advisor ──→ revenue expansion AI

PRE-F: FOUNDATION
├── D8: Estimates ──→ price book, code DB, two-mode estimates
├── FM: Firebase Migration ──→ Stripe/RevenueCat/AI → Supabase Edge
└── R1-fix: Mobile Rewire ──→ 33 screens connected to live data

PHASE F: PLATFORM COMPLETION (F1→F3→F4→F5→F6→F7→F9→F10)
├── F1: Calls ──→ voice, SMS, FAX, AI receptionist
├── F3: Meetings ──→ context-aware video, booking
├── F4: Mobile Toolkit ──→ 24 tools + SKETCH/BID FLOW + OSHA
├── F5: Integrations ──→ 9 systems + LEAD AGGREGATION (free APIs)
├── F6: Marketplace ──→ equipment AI + lead gen
├── F7: Home Portal ──→ homeowner property intelligence
├── F9: Hiring System ──→ multi-channel + Checkr + E-Verify
└── F10: ZForge ──→ PDF-first doc suite (second to last)

PHASE G: QA & HARDENING
PHASE E: AI LAYER (rebuild with full platform knowledge)

POST-AI (truly last):
├── F2: Website Builder ──→ AI content generation, templates
└── F8: Ops Portal 2-4 ──→ marketing, treasury, legal, dev
```

### Critical Dependency Chain
```
D8 (Estimates) → F4 (Sketch/Bid Flow uses D8 price book)
D1 (Job Types) → D2 (Insurance) → D3 (Verticals)
F1 (Phone) → F3 (Meetings) + F4 (walkie-talkie)
F6 (Marketplace) → F7 (Home Portal)
G (QA) → E (AI) → F2 (Website Builder) + F8 (Ops Portal)
```

---

## TOTAL HOURS ESTIMATE

| Phase | Hours |
|-------|:-----:|
| Phase D: Revenue Engine (D1-D5) | ~220 + TBD |
| Phase E: AI Layer (E1-E4) | ~580-760 |
| Phase F: Platform Completion (F1-F10) | ~780-1,000 |
| Phase G: Debug, QA & Hardening | ~100-200 |
| **PHASES D-G TOTAL** | **~1,700-2,200+** |

---

## RULES

1. **Everything here is PRE-LAUNCH** — Phases D, E, F all ship before launch
2. **AI goes LAST** — wire core, confirm it works, then E1-E4
3. **D5 (Property Management) needs dedicated spec session** — do NOT build without full spec
4. **D1 unlocks D2 and D3** — must be built first in D-phase
5. **E1 powers E2, E3, E4** — must be built first in E-phase
6. **F10 (ZForge) builds LAST** — after all features locked
7. **No scope creep** — if it's not in this doc, it doesn't exist yet
8. **Update this doc** — when specs change or new features are identified

---

CLAUDE: This is the expansion source of truth. Update in place. Never create parallel docs.
