# ZAFTO CIRCUIT BLUEPRINT
## Living Wiring Diagram — What Connects, What Doesn't, What's Missing
### Last Updated: February 9, 2026 (Session 93 — Phase T (TPA) + Phase P (ZScan) spec'd. No code changes since S91.)

---

## PURPOSE

You don't rough-in a house without a print. This is the print. Maps every pipe, every broken connection, and every missing piece across all 5 apps + Supabase. **UPDATE THIS AS WIRING PROGRESSES.**

---

## SYSTEM OVERVIEW — FIVE APPS, ONE DATABASE

```
+-------------------------------------------------------------------+
|                SUPABASE (PostgreSQL + Auth + Storage + Realtime)    |
|                                                                    |
|  Tables (~173)                 Storage Buckets (7 PRIVATE)         |
|  +------------------+         +------------------+                 |
|  | PRE-F (102)      |         | photos           |                 |
|  |  CORE (5)        |         | signatures       |                 |
|  |  BUSINESS (5)    |         | voice-notes      |                 |
|  |  FIELD TOOLS (6) |         | receipts         |                 |
|  |  B3 NEW TOOLS (4)|         | documents        |                 |
|  |  OPS PORTAL (6)  |         | avatars          |                 |
|  |  D2 INSURANCE (7)|         | company-logos     |                 |
|  |  D6 ENTERPRISE(5)|         +------------------+                 |
|  |  D7 CERTS (2)    |                                              |
|  |  D4 ZBOOKS (15)  |         Edge Functions (53 directories)      |
|  |  D5 PM (18)      |                                              |
|  |  D8 ESTIMATE(11) |          Pre-F: 32                           |
|  |  E1 AI (2)       |           Plaid: 4, recurring: 1, PM: 3     |
|  |  E5 XACTIMATE(5) |           z-intelligence: 1, Xact: 2       |
|  |  E6 WALKTHROUGH(5)|          Walkthrough: 4, AI Troubleshoot: 4|
|  |  + leads, notifs |           D8: 5, estimate/scope: 2         |
|  |    client_portal  |           pricing-ingest: 1                |
|  |    warranty_cos   |           E4 (5, uncommitted)              |
|  |                   |                                             |
|  | F-PHASE (+71)    |          F-phase + FM: 21                   |
|  |  FM PAYMENTS (6) |           SignalWire: 5, LiveKit: 4         |
|  |  F1 PHONE (9)    |           walkie/chat/osha/lead: 4          |
|  |  F3 MEETINGS (5) |           sendgrid/payroll/equip/zdocs: 4   |
|  |  F4 TOOLKIT (10) |           stripe-pay/webhook: 2             |
|  |  F5 BIZ OS (25+) |           revenuecat/sub-credits: 2        |
|  |  F6 MARKET (5)   |                                              |
|  |  F7 HOME (5)     |         PowerSync (NOT SET UP)               |
|  |  F9 HIRING (3)   |                                              |
|  |  F10 ZDOCS (3)   |                                              |
|  +------------------+                                              |
|  48 migration files    3 test auth users + 1 company seeded       |
|                                                                    |
|  API Keys (Supabase Secrets):                                      |
|   UNWRANGLE_API_KEY (supplier pricing)                             |
|   PLAID_CLIENT_ID + PLAID_SECRET (bank feeds)                      |
|   GOOGLE_CLOUD_API_KEY (maps + calendar)                           |
|   SIGNALWIRE (VoIP/SMS/Fax), LIVEKIT (video/meetings)             |
|   In Firebase (migrate): Stripe, Anthropic, RevenueCat            |
|   Empty: Sentry DSN. Pending signup: DocuSign, Indeed, Checkr     |
+-----+------+----------+----------+----------+---------------------+
      |      |          |          |          |
      v      v          v          v          v
+--------+ +--------+ +---------+ +--------+ +--------+
| MOBILE | | WEB    | | TEAM    | | CLIENT | | OPS    |
| APP    | | CRM    | | PORTAL  | | PORTAL | | PORTAL |
| Flutter| | Next15 | | Next15  | | Next15 | | Next15 |
| 33 role| | 107    | | 33      | | 36     | | 26     |
| screens| | pages  | | pages   | | pages  | | pages  |
| R1+E3  | | 68     | | 22      | | 21     | | 2      |
| +E5+E6 | | hooks  | | hooks   | | hooks  | | hooks  |
+--------+ +--------+ +---------+ +--------+ +--------+
 zafto.app  zafto.     team.       client.    ops.zafto
 (mobile)   cloud      zafto.app   zafto.     .cloud
                                   cloud
```

---

## LEGEND

```
LIVE    -- Connected and functional
BUILT   -- Code exists, NOT connected to backend
MOCK    -- Placeholder, no backing tables
DEFERRED -- Specified but intentionally postponed
```

---

## SECTION 1: CONNECTION STATUS -- EVERY WIRE

### 1A. MOBILE APP -- FLUTTER

#### Business Screens
| Screen | UI | Service | Backend | Issue |
|--------|:--:|:-------:|:-------:|-------|
| Home Dashboard | BUILT | BUILT Mock | PARTIAL | Riverpod state, mock data. 1,859 lines. |
| Bids List/Detail/Create | LIVE | LIVE bid_service.dart | LIVE | **DONE (B1d S43)** -- Supabase CRUD via bid_repository.dart. 8 statuses. Options/addons/photos in JSONB. Soft delete. Search. |
| Jobs List/Detail/Create | LIVE | LIVE job_service.dart | LIVE | **DONE (B1c S42)** -- Supabase CRUD via job_repository.dart. Status machine (9 statuses). Soft delete. Search. **D1 (S62):** Job type selector (SegmentedButton), conditional insurance/warranty metadata fields, type badge on detail+list. |
| Invoices List/Detail/Create | LIVE | LIVE invoice_service.dart | LIVE | **DONE (B1d S43)** -- Supabase CRUD via invoice_repository.dart. 10 statuses. Auto invoice number (INV-YYYY-NNNN). Soft delete. Search. PDF gen preserved. |
| Customers List/Detail/Create | LIVE | LIVE customer_service.dart | LIVE | **DONE (B1b S41)** -- Supabase CRUD via customer_repository.dart. Soft delete. Search. |
| Calendar | LIVE | LIVE calendar_service.dart | LIVE | **DONE (B1e S43)** -- Reads from jobsProvider (Supabase-backed). Jobs -> ScheduledItem conversion. Day/week/month views. **D1 (S62):** Color-coded by job type (blue/amber/purple). |
| Time Clock | LIVE | LIVE time_clock_service.dart | LIVE | **DONE (B1e S43)** -- Supabase CRUD via time_entry_repository.dart. GPS pings stored in location_pings JSONB. Break tracking. Approval workflow. |
| Contract Analyzer | BUILT | BUILT | LIVE | Uses Claude API Cloud Function |
| AI Chat | BUILT | BUILT | LIVE | Uses Claude API Cloud Function |
| AI Scanner | BUILT | BUILT | LIVE | 5 Cloud Functions (panel/nameplate/wire/violation/smart) |
| Command Palette | LIVE | N/A | N/A | **DONE (B7 S57)** -- 76 commands in registry. Searches business screens + field tools. |
| Onboarding | LIVE | LIVE | LIVE | **DONE (B1a S41)** -- Creates company + user row + refreshes JWT. Routes to HomeScreenV2 on success. |
| Notifications | LIVE | LIVE | LIVE | **DONE (B7 S57)** -- Real-time Supabase notifications table. Unread count badge. Mark read/dismiss. |
| Claims Hub | LIVE | LIVE insurance_claim_service.dart | LIVE | **DONE (D2b S63-S64)** -- claims_hub_screen.dart. Status filters. List all insurance claims. |
| Claim Detail | LIVE | LIVE insurance_claim_service.dart + restoration_service.dart | LIVE | **DONE (D2b-D2g S63-S64)** -- claim_detail_screen.dart. 6 tabs: Overview, Supplements, TPI, Moisture, Drying, Equipment. |
| Claim Create | LIVE | LIVE insurance_claim_service.dart | LIVE | **DONE (D2b S63-S64)** -- claim_create_screen.dart. Create claim from insurance_claim job. |
| Certifications | LIVE | LIVE certification_service.dart | LIVE | **DONE (D7a S67-68)** -- certifications_screen.dart. CRUD with Supabase. Dynamic cert types from certification_types table. Status lifecycle. Expiry countdown. Add/edit/view detail. Renewal reminders. |
| Properties Hub | LIVE | LIVE property_service.dart | LIVE | **DONE (D5f S72)** -- Portfolio overview with stats + searchable property cards. Home screen carousel + more menu. Command palette registered. |
| Property Detail | LIVE | LIVE property_service.dart | LIVE | **DONE (D5f S72)** -- 5-tab detail: Overview, Units, Financials, Maintenance, Assets. |
| Unit Detail | LIVE | LIVE property_service.dart | LIVE | **DONE (D5f S72)** -- Unit specs, current tenant, lease info. |
| Tenant Detail | LIVE | LIVE property_service.dart | LIVE | **DONE (D5f S72)** -- Tenant profile, contact info, lease history. |
| Lease Detail | LIVE | LIVE property_service.dart | LIVE | **DONE (D5f S72)** -- Lease terms, dates, rent, renewal/terminate actions. |
| Rent Screen | LIVE | LIVE rent_service.dart | LIVE | **DONE (D5f S72)** -- Rent roll, payment recording with partial support. |
| Maintenance Screen | LIVE | LIVE pm_maintenance_service.dart | LIVE | **DONE (D5f S72)** -- Request list with urgency/status filtering. "I'll Handle It" moat. |
| Inspection Screen | LIVE | LIVE (direct Supabase) | LIVE | **DONE (D5f S72)** -- Inspection list with create dialog. |
| Asset Screen | LIVE | LIVE (direct Supabase) | LIVE | **DONE (D5f S72)** -- Asset tracker with condition/warranty/service info. |
| Unit Turn Screen | LIVE | LIVE (direct Supabase) | LIVE | **DONE (D5f S72)** -- Unit turnover tracker with task checklists. |

#### Field Tools (19 -- ALL WIRED)
| # | Tool | File | Backend | Status |
|---|------|------|:-------:|--------|
| 1 | Job Site Photos | job_site_photos_screen.dart | LIVE | **DONE (B2a S44)** -- Capture -> upload to Storage -> insert photos row. Signed URL display. Soft delete. Category selector. Job-linked. |
| 2 | Before/After | before_after_screen.dart | LIVE | **DONE (B2a S44)** -- Before/after pair upload with categories. Slider comparison preserved. |
| 3 | Defect Markup | defect_markup_screen.dart | LIVE | **DONE (B2a S44)** -- RepaintBoundary -> toImage -> upload markup PNG + original. Annotation data in metadata JSONB. |
| 4 | Voice Notes | voice_notes_screen.dart | LIVE | **DONE (B2d S47)** -- Long-press record -> upload .m4a to voice-notes bucket -> insert voice_notes row. Playback from signed URL. Auto-save on stop. Transcription deferred Phase E. |
| 5 | Mileage Tracker | mileage_tracker_screen.dart | LIVE | **DONE (B2c S46)** -- GPS trip tracking -> mileage_trips table. Start/stop with lat/lng/address. Purpose dialog -> UPDATE. IRS rate calc. |
| 6 | LOTO Logger | loto_logger_screen.dart | LIVE | **DONE (B2b S45)** -- Lockout + release events -> compliance_records (type=loto). JSONB: equipment, location, energy type, reason. |
| 7 | Incident Report | incident_report_screen.dart | LIVE | **DONE (B2b S45)** -- Full OSHA form -> compliance_records (type=incident_report). Severity, checkboxes, all 10 fields in JSONB. |
| 8 | Safety Briefing | safety_briefing_screen.dart | LIVE | **DONE (B2b S45)** -- Topic + hazards + PPE + crew attendance -> compliance_records (type=safety_briefing). Sign-off timestamps in JSONB. |
| 9 | Sun Position | sun_position_screen.dart | Standalone | Utility tool, no save needed |
| 11 | Confined Space Timer | confined_space_timer_screen.dart | LIVE | **DONE (B2b S45)** -- Full OSHA 1910.146 entry -> compliance_records (type=confined_space). Checklist, entrants, air readings (O2/LEL/CO/H2S), permit info in JSONB. |
| 12 | Client Signature | client_signature_screen.dart | LIVE | **DONE (B2c S46)** -- PictureRecorder -> PNG -> upload to signatures bucket -> insert signatures row. 7 purpose types. GPS location. Signer name/role/notes. |
| 13 | Receipt Scanner | receipt_scanner_screen.dart | LIVE | **DONE (B2c S46)** -- Capture -> upload to receipts bucket -> insert receipts row. 7 categories. Payment method. OCR Edge Function deferred Phase E. |
| 14 | Level & Plumb | level_plumb_screen.dart | LIVE | **DONE (B2d S47)** -- Save Reading -> compliance_records (type=inspection). JSONB: mode, x/y/total angles, is_level, threshold, calibration offsets. |
| 15 | Materials Tracker | materials_tracker_screen.dart | LIVE | **DONE (B3a S47)** -- NEW SCREEN. job_materials table. CRUD with soft delete. Cost summary (total/billable). Category chips (5 types). Unit dropdown (10 units). Swipe-to-delete. |
| 16 | Daily Log | daily_log_screen.dart | LIVE | **DONE (B3a S47)** -- NEW SCREEN. daily_logs table. One-per-day UNIQUE constraint. Two tabs (Today form + History). Weather, crew, hours, issues. Upsert pattern. |
| 17 | Punch List | punch_list_screen.dart | LIVE | **DONE (B3b S48)** -- NEW SCREEN. punch_list_items table. Status workflow (open->in_progress->completed/skipped). Priority levels. Progress bar. Filter chips. Swipe-to-delete. |
| 18 | Change Orders | change_order_screen.dart | LIVE | **DONE (B3b S48)** -- NEW SCREEN. change_orders table. Auto-numbering (CO-001). Line items (JSONB). Workflow (draft->pending->approved/rejected/voided). Approve/reject buttons. |
| 19 | Job Completion | job_completion_screen.dart | LIVE | **DONE (B3b S48)** -- NEW SCREEN. Auto-checks 7 requirements: punch list, photos, signature, time entries, materials, daily log, change orders. Progress indicator. Updates job status to completed. |

**Summary: ALL 19 tools wired. 0 remaining UI shells.**

#### Services Layer (35+ files)
| Service | Connected | Notes |
|---------|:---------:|-------|
| auth_service.dart | LIVE Supabase | **DONE (B1a S41)** -- Rewritten from Firebase. Same API surface. 16 consumers unchanged. |
| job_service.dart | LIVE Supabase | **DONE (B1c S42)** -- Rewritten. 11 consumers updated. **D1 (S62):** jobType + typeMetadata in model. |
| invoice_service.dart | LIVE Supabase | **DONE (B1d S43)** -- 10 statuses. Auto invoice number. Soft delete. |
| bid_service.dart | LIVE Supabase | **DONE (B1d S43)** -- 8 statuses. Options/addons in JSONB. Soft delete. |
| customer_service.dart | LIVE Supabase | **DONE (B1b S42)** -- 4 consumers updated. |
| time_clock_service.dart | LIVE Supabase | **DONE (B1e S43)** -- GPS pings in location_pings JSONB. Break tracking. |
| supabase_client.dart | LIVE | `lib/core/supabase_client.dart` -- init, auth getters. |
| errors.dart | LIVE | `lib/core/errors.dart` -- Sealed error hierarchy. |
| sentry_service.dart | LIVE | **DONE (C1a S58)** -- SentryFlutter.init() wrapping main.dart. Auth wired. |
| storage_service.dart | LIVE | Generic Supabase Storage upload/delete/signedUrl. |
| photo_service.dart + repo | LIVE | Photos + Storage. jobPhotosProvider, photoUploadProvider. |
| compliance_service.dart + repo | LIVE | INSERT-only Supabase CRUD (immutable audit trail). 6 types. |
| receipt_service.dart + repo | LIVE | Receipts bucket + table. OCR deferred Phase E. |
| signature_service.dart + repo | LIVE | Signatures bucket + table. 7 purpose types. |
| mileage_service.dart + repo | LIVE | mileage_trips table. GPS coords. Purpose UPDATE. |
| voice_note_service.dart + repo | LIVE | voice-notes bucket + table. Transcription deferred Phase E. |
| insurance_claim_service.dart | LIVE Supabase | **DONE (D2b S63-S64)** -- Claims CRUD, status transitions. 12+ Riverpod providers. |
| restoration_service.dart | LIVE Supabase | **DONE (D2d-D2g S63-S64)** -- Moisture, drying, equipment, TPI. Aggregates restoration sub-services. |
| certification_service.dart | LIVE Supabase | **DONE (D7a S67-S68)** -- Certifications CRUD. Modular types via certificationTypesProvider (loads from certification_types table). Expiry tracking. Renewal reminders. |
| ai_service.dart | LIVE Supabase | **DONE (E3c S80)** -- AiService (Edge Function client) + AiChatNotifier (chat state) + providers. Calls z-intelligence, ai-troubleshoot, ai-photo-diagnose Edge Functions. |
| walkthrough_service.dart | LIVE Supabase | **DONE (E6b S79)** -- Walkthrough CRUD + rooms + photos. 7 Riverpod providers. |
| estimate_engine_service.dart | LIVE Supabase | **DONE (D8c S86)** -- Full estimate CRUD, area management, line item operations, auto-numbering, totals recalc. 5 screens: list, builder, room editor, line item picker, preview. |
| firestore_service.dart | Firebase | Content layer -- being removed. 13 files still import cloud_firestore (Phase G cleanup). |
| location_tracking_service.dart | Local | **4 compile errors -- missing battery_plus package.** |

**Repositories:** auth, customer, job, invoice, bid, time_entry, photo, compliance, receipt, signature, mileage, voice_note, insurance_claim, claim_supplement, moisture_reading, drying_log, restoration_equipment, tpi_inspection, certification, zbooks_account, zbooks_journal, zbooks_expense, property, tenant, lease, rent, pm_maintenance, inspection, asset, walkthrough, estimate, estimate_engine (32 total)
**Models:** Photo, ComplianceRecord, Receipt, Signature, MileageTrip, VoiceNote, Job (with JobType enum), Customer, Invoice, Bid, TimeEntry, Notification, InsuranceClaim, ClaimSupplement, MoistureReading, DryingLog, RestorationEquipment, TpiInspection, Certification, CertificationTypeConfig, ZBooksAccount, ZBooksJournalEntry, ZBooksExpense, Property, Unit, Tenant, Lease, MaintenanceRequest, PropertyAsset, PmInspection, UnitTurn, Walkthrough, WalkthroughRoom, WalkthroughPhoto, WalkthroughTemplate, FloorPlan, XactimateCode, EstimateLine (35 Supabase models)
**ZBooks Flutter Screens (D4m S70):** zbooks_hub_screen.dart, journal_entry_screen.dart, expense_entry_screen.dart — all in lib/screens/zbooks/
**PM Flutter Screens (D5f S72):** 10 screens in lib/screens/properties/ — properties_hub, property_detail (5-tab), unit_detail, tenant_detail, lease_detail, rent, maintenance, inspection, asset, unit_turn
**R1 Flutter App Remake (S78):** 33 role-based screens. Design system (8 widgets). AppShell with role switching. Owner (5), Tech (5), Office+Inspector+CPA (10), Client+Tenant (8), walkthrough start+capture+summary+room_detail_sheet (4). Z FAB on AppShell.
**E3 Mobile AI (S80):** ai_service.dart (AiService + AiChatNotifier + providers), z_chat_sheet.dart (bottom sheet chat), ai_photo_analyzer.dart (vision defect detection). Z FAB tap → chat, long-press → quick actions.
**D8 Estimate Engine (S86):** 5 Flutter screens in lib/screens/estimates/ (list, builder, room editor, line item picker, preview). Models: estimate.dart + estimate_item.dart. Repo: estimate_engine_repository.dart. Service: estimate_engine_service.dart. Quick Actions: quick_actions_service.dart.
**E5 Xactimate (S79):** Dormant Flutter estimate screens (E5-era, superseded by D8c)
**E6 Walkthrough (S79):** 12 screens in lib/screens/walkthrough/ — list, start, capture, summary, room_detail_sheet + 4 annotation files + 4 sketch editor files
**State widgets (B7 S57):** ZaftoLoadingState, ZaftoEmptyState -- reusable across all screens
**Deleted in A1 (S37):** 8 dead files, 3,637 lines

#### Known Model Issues (Deferred -- not blocking)
| Issue | Status |
|-------|--------|
| Duplicate Job model (root vs business/) | Deferred -- both functional, root is canonical |
| Duplicate Invoice model | Deferred |
| Duplicate Customer model | Deferred |
| Firebase project refs (zafto-2b563, zafto-electrical) | Remove when Firebase fully decommissioned |
| screen_registry.dart (10,128 lines) | Functional. Split by trade is nice-to-have. |

---

### 1B. WEB CRM -- NEXT.JS (107 pages at zafto.cloud)

**107 page.tsx files. 68 hook files + 22 Z Console files. mock-data.ts DELETED. Firebase fully removed. `npm run build` passes (104 routes, 0 errors).**

| Group | Pages | Backend | Notes |
|-------|:-----:|:-------:|-------|
| Operations (Dashboard, Bids x4, Jobs x3, Invoices x3) | 11 | LIVE Supabase | **DONE (B4b S50)** -- useJobs/useBids/useInvoices/useCustomers/useStats hooks. Real-time subscriptions. **D1 (S62):** JobTypeBadge, type filter, conditional metadata. Calendar color-coded. Bids: +optimize page (E4c). |
| Customers (List, Detail, New) | 3 | LIVE Supabase | **DONE (B4b S50 + B4c S51)** -- useCustomers + useCustomer(id). |
| Scheduling (Calendar, Time Clock) | 2 | LIVE Supabase | **DONE (B4b S50)** -- useSchedule + useTeam. |
| Resources (Team) | 1 | LIVE Supabase | **DONE (B4b S50)** -- useTeam + useJobs. Dispatch board. |
| Change Orders | 1 | LIVE Supabase | **DONE (B4c S51)** -- useChangeOrders hook. |
| Inspections | 1 | LIVE Supabase | **DONE (B4c S51)** -- useInspections hook. |
| Settings (+ Walkthrough Workflows) | 2 | LIVE Supabase | **DONE (B4c S51)** -- useTeam for members. **E6h (S79):** Walkthrough workflows settings. |
| Leads | 1 | LIVE Supabase | **DONE (B4c S52)** -- useLeads hook. Dedicated leads table. 6 stages. |
| Reports | 1 | LIVE Supabase | **DONE (B4c S52)** -- useReports hook. Aggregates from 4 tables. |
| Job Cost Radar | 1 | LIVE Supabase | **DONE (B4c S52)** -- useJobCosts hook. Risk assessment + alerts. |
| Insurance (List, Detail) | 2 | LIVE Supabase | **DONE (D2b-D2g S63-S64)** -- use-insurance.ts hook. Claims pipeline + 6-tab detail. |
| Certifications | 1 | LIVE Supabase | **DONE (D7a S67-S68)** -- use-enterprise.ts hook. |
| Warranties | 1 | LIVE Supabase | **DONE** -- use-verticals.ts hook. |
| ZBooks (13 pages) | 13 | LIVE Supabase | **DONE (D4 S70)** -- 13 hooks, 13 pages. GL engine. Double-entry. 5 EFs. |
| Properties (14 pages) | 14 | LIVE Supabase | **DONE (D5b-D5d S71)** -- 11 hooks + 14 pages. Sidebar PROPERTIES section. |
| Estimates (4 pages) | 4 | LIVE Supabase | **DONE (D8d S86)** -- List, editor, import, pricing. use-estimates.ts hook. |
| Walkthroughs (3 pages) | 3 | LIVE Supabase | **DONE (E6f S79)** -- List, detail, bid view. use-walkthroughs.ts hook. |
| Revenue Insights (E4) | 1 | LIVE Supabase | **DONE (E4b S80)** -- use-revenue-insights.ts. UNCOMMITTED. |
| Growth / Revenue Autopilot (E4) | 1 | LIVE Supabase | **DONE (E4e S80)** -- use-growth-actions.ts. UNCOMMITTED. |
| Z (AI Chat + Voice) | 2 | LIVE Supabase | **Z Console (B4e S54):** 22 files. z-voice page. **E2 (S78):** Wired to z-intelligence EF. |
| **F1: Phone System (S90)** | 3 | LIVE Supabase | **DONE** -- phone/, phone/sms/, phone/fax/ pages. use-phone.ts + use-fax.ts hooks. SignalWire integration. |
| **F3: Meetings (S90)** | 4 | LIVE Supabase | **DONE** -- meetings/, meetings/room/, meetings/booking-types/, meetings/async-videos/ pages. use-meetings.ts + use-async-videos.ts hooks. LiveKit integration. |
| **F4: Field Toolkit (S90)** | 8 | LIVE Supabase | **DONE** -- inspection-engine, osha-standards, moisture-readings, drying-logs, equipment, site-surveys, sketch-bid, team-chat pages. 6 hooks (use-inspection-engine, use-osha-standards, use-restoration-tools, use-site-surveys, use-sketch-bid, use-team-chat). |
| **F5: Business OS (S90)** | 7 | LIVE Supabase | **DONE** -- payroll, fleet, hr, email, documents, vendors (rewired), purchase-orders (rewired) pages. 7 hooks (use-payroll, use-fleet, use-hr, use-email, use-documents, use-procurement, use-vendors rewired). |
| **F6: Marketplace (S90)** | 1 | LIVE Supabase | **DONE** -- marketplace/ page. use-marketplace.ts hook. |
| **F9: Hiring (S90)** | 1 | LIVE Supabase | **DONE** -- hiring/ page. use-hiring.ts hook. (was under F5 grouping). |
| **F10: ZDocs (S90)** | 1 | LIVE Supabase | **DONE** -- zdocs/ page. use-zdocs.ts hook (real-time + 7 mutations). 3 tabs: templates, generated, signatures. |
| Remaining Placeholders | 5 | MOCK | permits, communications, service-agreements, bid-brain, equipment-memory — no backing tables. |
| Office Placeholders | 3 | MOCK | price-book, automations, inventory — future-phase. |

**Key files:**
- `mock-data.ts` -- **DELETED (S52)**. Zero imports remaining.
- `permission-gate.tsx` (424 lines) -- RBAC with 40+ permissions
- `types/index.ts` -- TypeScript interfaces (Job, InsuranceMetadata, WarrantyMetadata, etc.)
- **68 hook files total:** mappers.ts (1) + 67 use-*.ts files in src/lib/hooks/. Full list: use-accounts, use-approvals, use-assets, use-async-videos, use-banking, use-bid-optimizer, use-bids, use-branch-financials, use-change-orders, use-construction-accounting, use-cpa-access, use-customers, use-documents, use-email, use-enterprise, use-equipment-insights, use-estimate-engine, use-estimates, use-expenses, use-fax, use-financial-statements, use-fiscal-periods, use-fleet, use-growth-actions, use-hiring, use-hr, use-inspection-engine, use-inspections, use-insurance, use-invoices, use-job-costs, use-jobs, use-leads, use-leases, use-marketplace, use-meetings, use-osha-standards, use-payroll, use-phone, use-pm-inspections, use-pm-maintenance, use-procurement, use-properties, use-reconciliation, use-recurring, use-rent, use-reports, use-restoration-tools, use-revenue-insights, use-scope-assist, use-site-surveys, use-sketch-bid, use-stats, use-tax-compliance, use-team-chat, use-tenants, use-unit-turns, use-units, use-vendors, use-verticals, use-walkthrough-templates, use-walkthroughs, use-z-artifacts, use-z-threads, use-zbooks-engine, use-zbooks, use-zdocs. + use-company.ts in src/hooks/.
- 22 Z Console files: 5 in src/lib/z-intelligence/ + 17 in src/components/z-console/
- firebase.ts DELETED (B4a S49). auth.ts + firestore.ts rewritten for Supabase.
- **UI Polish (B4d S53):** Collapsible sidebar (366 lines), skeleton loading (7 pages), chart bezier curves + draw-in animation, stagger animations, dark mode depth layers.
- **Sentry (C1a S58):** @sentry/nextjs wired. global-error.tsx. Auth wired.
- **RBAC middleware (C2 S61):** Role verification on every request (owner/admin/office_manager/cpa/super_admin).

---

### 1C. CLIENT PORTAL -- NEXT.JS (36 pages at client.zafto.cloud)

**Magic link auth. 36 page.tsx files. 21 hook files (mappers + tenant-mappers + 19 use-*.ts). `npm run build` passes (38 routes, 0 errors).**

| Tab | Pages | Backend | Notes |
|-----|:-----:|:-------:|-------|
| Auth | 1 | LIVE Supabase | **DONE (B6 S56)** -- Magic link auth (signInWithOtp). Password login added (S60). Middleware. AuthProvider. |
| Home | 1 | LIVE Supabase | **DONE (B6 S56)** -- Real project/payment data. **D5g (S73):** Tenant-aware. |
| Projects (List, Detail, Estimate, Agreement, Tracker) | 5 | LIVE Supabase | **DONE (B6 S56)** -- use-projects hook. **D2h (S68):** Insurance claim timeline. **D8j (S89):** Estimate review page (approve/reject, digital signature). |
| Payments (List, Detail, History, Methods) | 4 | LIVE Supabase | **DONE (B6 S56)** -- use-invoices + use-bids hooks. IDOR fix (S61). |
| Settings | 1 | LIVE Supabase | **DONE (B6 S56)** -- Profile settings. |
| Rent (List, Detail) | 2 | LIVE Supabase | **DONE (D5g S73)** -- rent balance + charge list + payment history. |
| Lease | 1 | LIVE Supabase | **DONE (D5g S73)** -- lease terms, expiry countdown. |
| Maintenance (List, Detail) | 2 | LIVE Supabase | **DONE (D5g S73)** -- submit form + request list + status timeline. |
| Inspections | 1 | LIVE Supabase | **DONE (D5g S73)** -- read-only completed inspection reports. |
| Menu | 1 | LIVE Supabase | **Updated (D5g S73)** -- tenant services section. |
| **F1: Messages (S90)** | 1 | LIVE Supabase | **DONE** -- SMS messaging page. use-messages.ts hook. SignalWire. |
| **F3: Meetings + Book (S90)** | 2 | LIVE Supabase | **DONE** -- meetings/ + book/ pages. use-meetings.ts hook. LiveKit. |
| **F7: My Home (S90)** | 5 | LIVE Supabase | **DONE** -- my-home/, my-home/equipment/, my-home/equipment/[id]/, my-home/service-history/, my-home/maintenance/, my-home/documents/ pages. use-home.ts + use-home-documents.ts hooks. ZAFTO Home platform. |
| **F-expansion: Documents (S90)** | 1 | LIVE Supabase | **DONE** -- documents/ page (portal-level). Separate from my-home/documents. |
| **F-expansion: Get Quotes (S90)** | 1 | LIVE Supabase | **DONE** -- get-quotes/ page. use-quotes.ts hook. |
| **F-expansion: Find a Pro (S90)** | 1 | LIVE Supabase | **DONE** -- find-a-pro/ page. use-contractors.ts hook. Marketplace consumer side. |
| Walkthroughs (List, Detail) | 2 | LIVE Supabase | **DONE (E6 S79)** -- use-walkthroughs.ts hook. |
| Estimates | 1 | LIVE Supabase | **DONE (D8j S89)** -- use-estimates.ts hook. Approve/reject. |
| AI Chat Widget (E3d S80) | — | LIVE Supabase | **DONE** -- Floating Z button + slide-up chat. use-ai-assistant.ts hook. Layout-level. |
| Remaining (Request, Referrals, Review) | 3 | MOCK | Future-phase placeholders. |

**Key files:**
- **21 hook files total:** mappers.ts, tenant-mappers.ts, use-ai-assistant.ts, use-bids.ts, use-change-orders.ts, use-contractors.ts, use-estimates.ts, use-home.ts, use-home-documents.ts, use-inspections-tenant.ts, use-insurance.ts, use-invoices.ts, use-maintenance.ts, use-meetings.ts, use-messages.ts, use-projects.ts, use-quotes.ts, use-rent-payments.ts, use-tenant.ts, use-walkthroughs.ts
- client_portal_users table (S60) -- links auth users to customers
- tenants.auth_user_id (D5a S71) -- links auth users to tenants.
- **Sentry (C1a S58):** @sentry/nextjs wired.
- **RBAC middleware (C2 S61):** client_portal_users + super_admin fallback.
- **IDOR fix (S61):** All hooks filter by customer_id for single-record fetches.

---

### 1D. EMPLOYEE FIELD PORTAL -- NEXT.JS (33 pages at team.zafto.app)

**DONE (B5 S55, D7a S67-68, D5h S76, F-expansion S90). 22 hook files. PWA-ready. Field-optimized UI (big touch targets). `npm run build` passes (34 routes, 0 errors).**

| Group | Pages | Backend | Notes |
|-------|:-----:|:-------:|-------|
| Auth + Dashboard | 2 | LIVE Supabase | Login + dashboard with today's jobs, active time clock, team status. |
| Jobs (list, detail) | 2 | LIVE Supabase | Assigned jobs with status badges. **D1 (S62):** Type badges. **D2h (S68):** Insurance restoration progress. **D5h (S76):** Property maintenance section. |
| Time Clock | 1 | LIVE Supabase | Clock in/out with GPS, break tracking. |
| Schedule | 1 | LIVE Supabase | Scheduled jobs view. Color accent by type. |
| Field Tools (hub + 5 tools) | 6 | LIVE Supabase | Photos, voice-notes, signatures, receipts, level. |
| Materials | 1 | LIVE Supabase | Job materials tracking. |
| Daily Log | 1 | LIVE Supabase | Daily log entries. |
| Punch List | 1 | LIVE Supabase | Status workflow. |
| Change Orders | 1 | LIVE Supabase | Change order tracking. |
| Bids (list, new) | 2 | LIVE Supabase | Field bid creation. |
| Notifications | 1 | LIVE Supabase | Notification center. |
| Settings | 1 | LIVE Supabase | Profile + preferences. |
| Certifications | 1 | LIVE Supabase | **DONE (D7a S67-68)** -- use-certifications.ts hook. Dynamic types. |
| Properties | 1 | LIVE Supabase | **DONE (D5h S76)** -- Maintenance requests. Status updates. |
| Walkthroughs (list, detail) | 2 | LIVE Supabase | **DONE (E6 S79)** -- use-walkthroughs.ts hook. |
| Estimates (list, detail) | 2 | LIVE Supabase | **DONE (D8j S89)** -- use-estimates.ts hook. Field estimate creation. |
| AI Troubleshooting | 1 | LIVE Supabase | **DONE (E3b S80)** -- use-ai-troubleshoot.ts. 5-tab UI. 4 Edge Functions. |
| **F1: Phone (S90)** | 1 | LIVE Supabase | **DONE** -- phone/ page. use-phone.ts hook. SignalWire. |
| **F3: Meetings (S90)** | 1 | LIVE Supabase | **DONE** -- meetings/ page. use-meetings.ts hook. LiveKit. |
| **F5: Pay Stubs (S90)** | 1 | LIVE Supabase | **DONE** -- pay-stubs/ page. use-pay-stubs.ts hook. MY STUFF sidebar. |
| **F5: My Vehicle (S90)** | 1 | LIVE Supabase | **DONE** -- my-vehicle/ page. use-my-vehicle.ts hook. Fleet data. |
| **F5: Training (S90)** | 1 | LIVE Supabase | **DONE** -- training/ page. use-my-training.ts hook. |
| **F5: My Documents (S90)** | 1 | LIVE Supabase | **DONE** -- my-documents/ page. use-my-documents.ts hook. |

**Key files:**
- **22 hook files total:** mappers.ts, use-ai-troubleshoot.ts, use-bids.ts, use-certifications.ts, use-change-orders.ts, use-daily-log.ts, use-estimates.ts, use-insurance.ts, use-jobs.ts, use-maintenance-requests.ts, use-materials.ts, use-meetings.ts, use-my-documents.ts, use-my-training.ts, use-my-vehicle.ts, use-pay-stubs.ts, use-phone.ts, use-pm-jobs.ts, use-punch-list.ts, use-time-clock.ts, use-walkthroughs.ts
- PWA manifest (installable on phone home screen)
- **Sidebar sections:** WORK, FIELD TOOLS, MY STUFF (new S90)
- **Sentry (C1a S58):** @sentry/nextjs wired (instrumentation pattern).
- **RBAC middleware (C2 S61):** owner/admin/office_manager/technician/super_admin.
- **Error handling (C2 S61):** hooks with error state, try/catch/finally.

---

### 1E. OPS PORTAL -- NEXT.JS (26 pages at ops.zafto.cloud)

**DONE (C3 S59, D8h-i S88, F-expansion S90). super_admin role gate. Deep navy/teal theme. `npm run build` passes (27 routes, 0 errors). 2 hooks (use-phone-analytics, use-meeting-analytics).**

| Group | Pages | Backend | Notes |
|-------|:-----:|:-------:|-------|
| Login | 1 | LIVE Supabase | Email/password with super_admin role gate. |
| Command Center | 1 | LIVE Supabase | Companies/users/tickets counts. Audit log feed. |
| Companies (list, detail) | 2 | LIVE Supabase | Company info + users + jobs count. |
| Users (list, detail) | 2 | LIVE Supabase | User info + role filter + audit activity. |
| Tickets (list, detail) | 2 | LIVE Supabase | Queue with status/priority filters. Message thread + reply form. |
| Knowledge Base (list, editor) | 2 | LIVE Supabase | Article grid with category filter. Upsert with auto-slug. |
| Revenue | 1 | PLACEHOLDER | "Connect Stripe" messaging (zeros, not fake data). |
| Subscriptions | 1 | PLACEHOLDER | Stripe API not wired. |
| Churn | 1 | PLACEHOLDER | Churn analysis placeholder. |
| System Status | 1 | PLACEHOLDER | 10 service health cards. Sentry/API not wired. |
| Errors | 1 | PLACEHOLDER | Sentry error dashboard placeholder. |
| Directory | 1 | LIVE Supabase | Service credentials + static fallback. |
| Code Contributions (D8h S88) | 1 | LIVE Supabase | **DONE** -- Stats, queue, verify/reject/promote. Super_admin gate. |
| Pricing Engine (D8i S88) | 1 | LIVE Supabase | **DONE** -- MSA pricing admin, BLS/FEMA/PPI data. |
| Estimates (D8j S89) | 1 | LIVE Supabase | **DONE** -- Estimate analytics dashboard. 6 stat cards. |
| **F1: Phone Analytics (S90)** | 1 | LIVE Supabase | **DONE** -- use-phone-analytics.ts hook. Call/SMS/fax metrics. PLATFORM sidebar. |
| **F3: Meeting Analytics (S90)** | 1 | LIVE Supabase | **DONE** -- use-meeting-analytics.ts hook. Meeting stats. PLATFORM sidebar. |
| **F5: Payroll Analytics (S90)** | 1 | LIVE Supabase | **DONE** -- Payroll metrics dashboard. PLATFORM sidebar. |
| **F5: Fleet Analytics (S90)** | 1 | LIVE Supabase | **DONE** -- Fleet utilization metrics. PLATFORM sidebar. |
| **F5: Email Analytics (S90)** | 1 | LIVE Supabase | **DONE** -- Email delivery metrics. PLATFORM sidebar. |
| **F6: Marketplace Analytics (S90)** | 1 | LIVE Supabase | **DONE** -- Marketplace engagement metrics. PLATFORM sidebar. |
| **F9: Hiring Analytics (S90)** | 1 | LIVE Supabase | **DONE** -- Hiring pipeline metrics. PLATFORM sidebar. |

**6 new DB tables (S59):** support_tickets, support_messages, knowledge_base, announcements, ops_audit_log, service_credentials
**All RLS-locked to super_admin role. ops_audit_log is INSERT-only (immutable).**
**generate_ticket_number() function: auto-incrementing TKT-YYYYMMDD-NNN format.**
**Sidebar sections:** OPERATIONS, DATA, PLATFORM (new S90)

---

## SECTION 1.5: FOUNDATION + BUILD STATUS

### Phase A: Foundation
| Step | Status | Details |
|------|--------|---------|
| A1: Code Cleanup | DONE (S37) | 8 dead files deleted, 3,637 lines. |
| A2: DevOps Phase 1 | DONE (S39) | Env config system. Dependabot. Gitignore hardened. |
| A3a-c: SQL Tables | DEPLOYED TO DEV | 16 core tables + RLS + audit triggers. |
| A3d: Storage Buckets | DONE (S40) | 7 private buckets. |
| A3e: PowerSync | NOT STARTED | Deferred. |

### Phase B: Wiring (ALL COMPLETE)
| Sprint | Status | Details |
|--------|--------|---------|
| B1: Core Business | DONE (S41-S43) | Auth + Customers + Jobs + Invoices + Bids + Time Clock + Calendar. |
| B2a-d: Field Tools | DONE (S44-S47) | ALL 14 original tools wired. |
| B3a-b: Missing Tools | DONE (S47-S48) | 5 new tools built from scratch. |
| B4a: CRM Infrastructure | DONE (S49) | Firebase -> Supabase. firebase.ts deleted. |
| B4b: CRM Core Pages | DONE (S50) | 12 core pages wired. 6 hooks. Real-time. |
| B4c: CRM Remaining | DONE (S51-S52) | 13 more pages. 11 hooks total. mock-data.ts DELETED. |
| B4d: UI Polish | DONE (S53) | Collapsible sidebar, skeleton loading, chart animations, dark mode. |
| B4e: Z Console | DONE (S54) | Persistent AI console. 22 files. 3 states. Mock AI flows. |
| B5: Employee Portal | DONE (S55) | 21 pages, 8 hooks, PWA-ready. |
| B6: Client Portal | DONE (S56) | Magic link auth, 6 pages wired, 5 hooks. |
| B7: Polish | DONE (S57) | 76 commands in registry. Notifications. State widgets. |

### Phase C: DevOps + QA
| Sprint | Status | Details |
|--------|--------|---------|
| C1a: Sentry | DONE (S58) | All 4 apps. DSN via env var. Auth wired. |
| C1b: CI/CD | DONE (S58) | 4 GitHub Actions workflows. Path-filtered. |
| C1c: Tests | DONE (S58) | 154 model tests (customer, job, invoice, notification). 0 failures. |
| C2: QA + Security | NEAR COMPLETE (S60-S61) | 21 schema mismatches fixed. 75 audit findings resolved. RBAC middleware on all portals. Client portal IDOR fix. Stale closure protection. Auth hardening (getUser). |
| C3: Ops Portal | DONE (S59) | 16 pages + login. 6 new tables. |
| C4: Security hardening | PENDING | Email migration, passwords, YubiKeys. |
| C5: Incident Response | DONE (S59) | 08_INCIDENT_RESPONSE.md (291 lines, 8 sections). |

### Phase D: Revenue Engine
| Sprint | Status | Details |
|--------|--------|---------|
| D1: Job Type System | DONE (S62) | 3 types (standard/insurance_claim/warranty_dispatch). Type metadata (InsuranceMetadata/WarrantyMetadata). Full UI across Flutter + 4 web portals. Calendar colors. Conditional forms. All 5 apps build clean. |
| D2: Insurance/Restoration | D2a-D2h DONE (S63-S64, S68). | 7 new tables deployed (36 total). Flutter: 18 new files + insurance completion checklist. Web CRM: 3 new files + completion tab. Team Portal: use-insurance.ts + job detail restoration progress. Client Portal: use-insurance.ts + claim timeline. |
| D3: Insurance Verticals | D3a-D3d DONE (S69) | Phase 1+2 COMPLETE. claim_category + JSONB vertical data. Storm/Recon/Commercial typed models + category forms across Flutter + Web CRM. Phase 3 deferred (6+ months). |
| D4: ZBooks | **ALL DONE (S70)** | 16 sub-steps (D4a-D4p). GL engine. Double-entry. 15 new tables. 13 hooks. 13 web pages. 5 Edge Functions. 3 Flutter screens (hub, journal entry, expenses). CPA portal access. Construction accounting (AIA G702/G703 progress billing + retention). 55 COA accounts + 26 tax categories seeded. zbooks_audit_log INSERT-only. |
| D5: Property Management | **ALL DONE (S71-S77)** | 18 new tables (79 total). 4 migrations. Web CRM: 14 pages, 11 hooks, sidebar section. Flutter: 10 screens, 7 repos, 3 services, 5 models. Client Portal: 5 tenant hooks, 6 new pages, home+menu tenant-aware. Team Portal: 3 PM hooks, properties page, job detail PM context. 3 Edge Functions (rent-charge, lease-reminders, asset-reminders). 157 model tests. Seed data. Integration wiring: maintenance→job, rent→ZBooks journal, lease termination→unit turn, job completion→request update, inspection→repair job, turn task→job. |
| D6: Enterprise Foundation | DONE (S65-66) | 5 new tables: branches, custom_roles, form_templates, certifications, api_keys. Multi-location, custom roles, configurable compliance forms, cert tracking, API key management. |
| D7a: Certifications | DONE (S67-68) | Cert tracker across Flutter + Web CRM + Team Portal. Modular types: certification_types table (25 system defaults, company-custom). Immutable audit log: certification_audit_log (INSERT-only). All 3 surfaces use dynamic types from DB with enum fallback. |

---

## SECTION 2: DATA FLOW -- CURRENT STATE

### What SHOULD Happen
```
Tech clocks in (GPS) -> Selects job -> Opens field tools (auto-linked to job)
    -> Takes photos -> saved to job + Storage
    -> Logs safety briefing -> saved to compliance
    -> Scans receipt -> flows to job costs + ZBooks
    -> Captures signature -> attached to job
    -> Marks tasks -> job progress updates
        -> Office sees real-time: photos, costs, progress
        -> Client portal sees: tracker, photos, completion %
        -> Team portal sees: assigned jobs, field data
```

### What ACTUALLY Happens (Post-B7 + C2 + D1)
```
Tech opens app -> Taps "Field Tools"
    -> Takes photos -> LIVE uploaded to Storage + photos table (B2a)
    -> Records voice -> LIVE .m4a uploaded to voice-notes bucket + voice_notes table (B2d)
    -> Scans receipt -> LIVE uploaded to receipts bucket + receipts table (B2c)
    -> Captures signature -> LIVE PNG uploaded to signatures bucket + signatures table (B2c)
    -> Tracks mileage -> LIVE GPS trip saved to mileage_trips table (B2c)
    -> Saves level reading -> LIVE compliance_records type=inspection (B2d)
    -> Safety tools (LOTO, incident, briefing, confined) -> LIVE compliance_records (B2b)
    -> Materials/Daily Log/Punch List/Change Orders -> LIVE their respective tables (B3)
    -> Job Completion -> LIVE auto-validates 7 requirements, updates job status (B3b)
        -> Office sees: ALL field data via Supabase queries + real-time subscriptions
        -> Client sees: projects, payments, bids, change orders (6 pages wired, B6 S56)
        -> Team sees: assigned jobs, field tools, time clock, materials (21 pages, B5 S55)
```

### Remaining Broken Pipes

**Pipe 1: Receipt Scanner -> OCR -> ZBooks**
- Receipt images saved. OCR not wired (Phase E).
- ZBooks fully built (D4 S70): GL engine, expenses, vendors, bank reconciliation, reports all LIVE.
- REMAINING: receipt-ocr Edge Function (Claude Vision) -> auto-categorization -> auto-create expense entries in ZBooks.

**Pipe 2: Time Clock GPS -> CRM Map**
- GPS pings captured in location_pings JSONB on time_entries.
- CRM has no live tech location display.
- REMAINING: PowerSync + CRM map component.

**Pipe 4: Voice Notes -> Transcription**
- .m4a files saved. Transcription not wired.
- REMAINING: transcribe-audio Edge Function (Phase E).

**Pipe 5: Client Signature -> Auto-Status Update**
- Signature saved with purpose/job_id.
- REMAINING: purpose=job_completion -> auto-update job status. purpose=invoice_approval -> auto-update invoice signed_at.

**Pipe 6: PowerSync Offline**
- All data flows require network. No offline queue.
- REMAINING: PowerSync account setup, sync rules, Flutter packages.

**Pipe 7: Property Management → Client Portal (D5g) — CONNECTED (S73)**
- PM tables (properties, units, tenants, leases, rent_charges, maintenance_requests) LIVE.
- CRM fully wired (14 pages, 11 hooks). Flutter fully wired (10 screens, 7 repos, 3 services).
- Client Portal: 5 tenant hooks (tenant-mappers, use-tenant, use-rent-payments, use-maintenance, use-inspections-tenant) + 6 pages (rent, rent/[id], lease, maintenance, maintenance/[id], inspections) + home/menu updated.
- RLS policies handle tenant auth automatically (tenants_self, leases_tenant, rent_charges_tenant, etc.).
- REMAINING: Stripe Edge Function for rent payments (Phase E). Webhook handler (Phase E).

**Pipe 8: PM Maintenance → Job (THE MOAT) — CONNECTED (S77)**
- "I'll Handle It" in Flutter creates a job from a maintenance request with propertyId/unitId/maintenanceRequestId.
- CRM: createJobFromRequest, createRepairFromInspection, createJobFromTurnTask — all wired.
- Job model has propertyId, unitId, maintenanceRequestId fields (D5i S77).
- completeMaintenanceJob updates request status + job status atomically.
- Rent payment → ZBooks journal entry (debit Cash, credit Rental Income, property-tagged).
- Lease termination → auto-create unit turn with move_out_date.
- Job completion from inspection → repair job auto-created.
- 3 Edge Functions: pm-rent-charge (daily rent + late fees), pm-lease-reminders (90/60/30 days), pm-asset-reminders (14 days).

---

## SECTION 3: DATABASE SCHEMA

### Deployed Tables (~173 total -- dev Supabase, 48 migration files)

**--- PRE-F TABLES (102) ---**
**Core (5 -- migration 000001):** companies, users, audit_log, user_sessions, login_attempts
**Business (5 -- migration 000002):** customers, jobs, invoices, bids, time_entries
**Field Tools (6 -- migration 000003):** photos, signatures, voice_notes, receipts, compliance_records, mileage_trips
**B3 New Tools (4 -- migration 000004):** job_materials, daily_logs, punch_list_items, change_orders
**Auth/Roles (1 -- migration 000009):** super_admin/cpa role additions
**Client Portal (1 -- migration 000010):** client_portal_users
**Ops Portal (6 -- migration 000008):** support_tickets, support_messages, knowledge_base, announcements, ops_audit_log, service_credentials
**Leads (1 -- migration 000005):** leads
**Additional:** notifications, warranty_companies (migrations 000006-000007)
**D2 Insurance (7 -- migration 000011+000012):** insurance_claims, claim_supplements, tpi_scheduling, xactimate_estimate_lines, moisture_readings, drying_logs, restoration_equipment
**D3 Insurance Verticals (0 new tables -- migration 000015+000016+000017):** claim_category column + JSONB data on insurance_claims. warranty_dispatch_companies table. jobs.source column.
**D6 Enterprise (5 -- migration 000013):** branches, custom_roles, form_templates, certifications, api_keys
**D7a Certifications Modular (2 -- migration 000014):** certification_types (25 seeded system defaults), certification_audit_log (INSERT-only)
**D4 ZBooks Core (6 -- migration 000018):** chart_of_accounts (55 seeded), journal_entries, journal_entry_lines, fiscal_periods, zbooks_audit_log (INSERT-only), tax_categories (26 seeded)
**D4 ZBooks Banking/Expense/Vendor (7 -- migration 000019):** bank_accounts, bank_transactions, bank_reconciliations, expenses, vendors, vendor_payments, recurring_templates
**D4 ZBooks Construction (2 -- migration 000020):** progress_billings (AIA G702/G703), retention_tracking
**D5 Property Management (18 -- migrations 000021-000024):** properties, units, tenants, leases, rent_charges, rent_payments, maintenance_requests, work_order_actions, pm_inspections, pm_inspection_items, property_assets, asset_service_records, pm_documents, unit_turns, unit_turn_tasks, vendors (PM), vendor_contacts, vendor_assignments. + expense_records gets property_id/schedule_e_category/property_allocation_pct columns (D5e).
**E1 AI Layer (2 -- migration 000025):** z_threads, z_messages
**E5 Xactimate (5 -- migrations 000026-000027):** xactimate_codes (77 seeded), pricing_entries, pricing_contributions, estimate_templates, esx_imports.
**E6 Walkthrough (5 -- migration 000028):** walkthroughs, walkthrough_rooms, walkthrough_photos, walkthrough_templates (14 seeded), property_floor_plans
**D8 Estimate Engine (11 -- migrations 000029-000031):** estimate_categories (86 seeded), estimate_units (16 seeded), estimate_items (216 seeded), estimate_pricing (5,616 rows seeded: national + 25 MSAs), estimate_labor_components (28 seeded), code_contributions, estimates, estimate_areas, estimate_line_items, estimate_photos, msa_regions (25 MSAs). fn_zip_to_msa + fn_get_item_pricing Postgres functions.

**--- F-PHASE + FM TABLES (+71) ---**
**FM Payments (6 -- migration 000032):** payment_intents, payments, payment_failures, user_credits, scan_logs, credit_purchases
**F1 Phone System (9 -- migration 000033):** phone_lines, call_logs, sms_messages, fax_documents, voicemails, call_recordings, auto_attendant_configs, phone_contacts, call_analytics
**F3 Meeting Rooms (5 -- migration 000034):** meeting_rooms, meetings, meeting_participants, meeting_recordings, booking_types
**F4 Field Toolkit (10 -- migrations 000035-000036):** inspection_templates, inspection_results, osha_standards, moisture_profiles, drying_protocols, equipment_inventory, site_surveys, survey_measurements, sketch_bids, walkie_channels
**F5 Business OS (25+ -- migrations 000037-000044):** lead_sources, lead_assignments, cpa_portal_access, cpa_reports, payroll_runs, payroll_items, tax_filings, fleet_vehicles, fleet_maintenance_logs, fleet_fuel_logs, fleet_gps_logs, purchase_orders, purchase_order_items, vendor_catalogs, hr_employees, hr_time_off, hr_documents, hr_performance, email_accounts, email_messages, email_templates, email_campaigns, document_folders, document_files, document_shares
**F6 Marketplace (5 -- migration 000045):** marketplace_listings, marketplace_reviews, marketplace_messages, marketplace_categories, marketplace_saved
**F7 ZAFTO Home (5 -- migration 000046):** home_profiles, home_equipment, home_service_history, home_maintenance_schedules, home_documents
**F9 Hiring (3 -- migration 000047):** job_postings, job_applications, hiring_pipelines
**F10 ZDocs (3 -- migration 000048):** zdoc_templates, zdoc_generated, zdoc_signatures

**Total: ~173 tables. 48 migration files. RLS on all. Audit triggers on all mutable tables. ~18 F-phase migrations NOT YET DEPLOYED (need `npx supabase db push`). Pre-F migrations all synced (local=remote).**

### D1 Job Type Columns (Already Deployed)
- `jobs.job_type` TEXT with CHECK constraint: 'standard', 'insurance_claim', 'warranty_dispatch'
- `jobs.type_metadata` JSONB -- stores InsuranceMetadata or WarrantyMetadata

### D2 Insurance Tables (7 -- DEPLOYED S63-S64)
- insurance_claims, claim_supplements, tpi_scheduling, xactimate_estimate_lines, moisture_readings, drying_logs, restoration_equipment
- 3 migration files: 20260207000011_d2_insurance_tables.sql + 20260207000012_d2_financial_depth.sql + 20260207000015_d3a_claim_categories.sql
- insurance_claims.claim_category: TEXT column with CHECK (restoration/storm/reconstruction/commercial). JSONB `data` field stores vertical-specific fields per category.
- Full SQL in `07_SPRINT_SPECS.md` Sprint D2a

### Test Data Seeded
- 3 auth users: admin@zafto.app (super_admin), tech@zafto.app (technician), client@test.com (client)
- 1 company: Tereda Electrical
- 1 client_portal_user (linked client@test.com -> Margaret Sullivan)
- 5 leads, 5 notifications, 3 support tickets
- 29 system form templates, 25 system cert types, 15 warranty companies
- 55 COA accounts (chart of accounts), 26 tax categories

---

## SECTION 4: WIRING PHASES

### W1: Core Business Pipeline -- DONE
- [x] Supabase Auth -- **DONE B1a S41**
- [x] Company creation in onboarding -- **DONE B1a S41**
- [x] Jobs CRUD -> Supabase -- **DONE B1c S42**
- [x] Customers CRUD -> Supabase -- **DONE B1b S41**
- [x] Bids CRUD -> Supabase -- **DONE B1d S43**
- [x] Invoices CRUD -> Supabase -- **DONE B1d S43**
- [x] Time Clock -> time_entries with GPS pings -- **DONE B1e S43**
- [x] Register business screens in screen_registry -- **DONE B7 S57** (76 commands)

### W2: Field Tools to Backend -- DONE
- [x] Wire 3 photo tools to Storage -- **DONE B2a S44**
- [x] Wire 4 safety tools to compliance_records -- **DONE B2b S45**
- [x] Wire 3 financial tools -- **DONE B2c S46**
- [x] Wire 2 remaining tools -- **DONE B2d S47**
- [x] Job linking (pass jobId from hub) -- hub passes jobId to all screens
- [x] Voice Notes -> real recording -- **DONE B2d S47**
- [x] Client Signature -> Storage upload + signatures table -- **DONE B2c S46**
- [ ] PowerSync offline queue -- DEFERRED
- [ ] Receipt Scanner -> real OCR -- DEFERRED (Phase E)

### W3: Missing Operational Tools -- DONE (B3a S47 + B3b S48)
- [x] Materials/Equipment Tracker -> job_materials table
- [x] Daily Job Log -> daily_logs table
- [x] Punch List -> punch_list_items table
- [x] Change Order Capture -> change_orders table
- [x] Job Completion Workflow -> auto-validates 7 requirements

### W4: Web CRM to Real Data -- DONE (B4a-e S49-S54)
- [x] Replace Firebase SDK with Supabase client -- **DONE B4a S49**
- [x] Wire 12 core operations pages -- **DONE B4b S50**
- [x] Wire 10 more pages -- **DONE B4c S51-S52**
- [x] Empty equipment/inventory/documents pages -- **DONE B4c S52**
- [x] Dashboard chart data from real aggregations -- **DONE S52**
- [x] UI Polish -- **DONE B4d S53** (sidebar, skeletons, animations)
- [x] Z Console + Artifact System -- **DONE B4e S54** (22 files, persistent)
- [x] ZBooks reads real bank/transaction data -- **DONE (D4 S70)** -- 13 hooks, 13 pages, 5 Edge Functions, GL engine, double-entry

### W5: Employee Field Portal -- DONE (B5 S55)
- [x] Scaffold team-portal (Next.js 15, React 19, TypeScript, Tailwind CSS)
- [x] Supabase Auth
- [x] Dashboard (today's jobs, schedule, active time clock, team status)
- [x] Job view (assigned jobs, detail)
- [x] Time clock (clock in/out with GPS, break tracking)
- [x] Field tools web versions (photos, voice notes, signatures, receipts)
- [x] Daily logs, punch lists, change orders, materials log
- [x] Bid creation from field
- [x] PWA manifest
- [x] AI Troubleshooting Center -- **DONE (E3b S80)** -- 5-tab UI (Diagnose/Photo/Code/Parts/Repair) + 4 Edge Functions

### W6: Client Portal to Real Data -- DONE (B6 S56)
- [x] Supabase Auth (magic link + password) -- **DONE S56/S60**
- [x] 6 pages wired (home, projects, projects/[id], payments, payments/[id], settings) -- **DONE S56**
- [x] 5 hooks + mappers -- **DONE S56**
- [x] IDOR fix (customer_id filtering) -- **DONE S61**
- [ ] Remaining 13 pages -- future-phase placeholders (no backing tables)

### W7: Polish & Registry -- DONE (B7 S57)
- [x] Screen registry includes all business screens (76 commands)
- [x] Notification system (notifications table + real-time UI)
- [x] ZaftoLoadingState + ZaftoEmptyState widgets
- [ ] Offline sync verified (PowerSync) -- DEFERRED
- [ ] Push notifications -- DEFERRED

### Phase C: DevOps -- MOSTLY DONE
- [x] C1a: Sentry in all 4 apps -- **DONE S58**
- [x] C1b: CI/CD (4 workflows) -- **DONE S58**
- [x] C1c: 154 model tests -- **DONE S58**
- [x] C2: QA (21 schema fixes + 75 audit findings) -- **NEAR COMPLETE S60-S61**
- [x] C3: Ops Portal Phase 1 (16 pages, 6 tables) -- **DONE S59**
- [ ] C4: Security hardening -- PENDING
- [x] C5: Incident Response Plan -- **DONE S59**
- [x] Codemagic CI/CD -- **PARTIAL (S91)** -- Android debug build PASSING (95 MB .aab). iOS compiles but needs code signing (Apple Developer API key in Codemagic). Bundle ID: app.zafto.mobile. Kotlin 2.2.0, sentry_flutter 9.x. No codemagic.yaml (UI workflow). Android release keystore NOT created.
- [x] Dependabot -- **DONE (S91)** -- 0 vulnerabilities. protobufjs override >=7.2.5, firebase-admin 12.x.

### Phase D: Revenue Engine -- COMPLETE
- [x] D1: Job Type System -- **DONE S62** (3 types across all 5 apps)
- [x] D2a-D2g: Insurance/Restoration Module -- **DONE S63-S64** (7 tables deployed, 36 total. Flutter: 3 screens, 6 models, 6 repos, 2 services. Web CRM: 2 pages, 1 hook. Claims CRUD + Supplements + Moisture + Drying + Equipment + TPI.)
- [x] D2f: Certificate of Completion -- **DONE S68**
- [x] D2h: Team/Client Portal Insurance Views -- **DONE (S68)** -- Team: restoration progress + inline recording. Client: claim timeline + status steps.
- [x] D3: Insurance Verticals -- **D3a-D3d DONE (S69)** -- claim_category + JSONB vertical data. Phase 3 deferred.
- [x] D4: ZBooks -- **ALL DONE (S70)** -- 16 sub-steps. 15 new tables. 13 hooks. 13 pages. 5 Edge Functions. 3 Flutter screens.
- [x] D5a-D5c: PM Database + Web CRM Hooks + Pages -- **DONE (S71)** -- 18 tables, 11 hooks, 14 pages, sidebar PROPERTIES section.
- [x] D5d: PM Dashboard Integration -- **DONE (S71)** -- Property stats on CRM dashboard.
- [x] D5e: ZBooks Schedule E + Expense Allocation -- **DONE (S72)** -- expense→property allocation columns, Schedule E categories.
- [x] D5f: Flutter Properties Hub + Screens -- **DONE (S72)** -- 5 models, 7 repos, 3 services, 10 screens. Home screen + command palette wired.
- [x] D5g: Client Portal Tenant Flows -- **DONE (S73)** -- 5 hooks, 6 pages, home+menu updated. 29 routes. Stripe deferred to Phase E.
- [x] D5h: Team Portal PM View -- **DONE (S76)** -- Properties page, job detail PM context, 3 hooks.
- [x] D5i: Integration Tests + Edge Functions -- **DONE (S77)** -- 157 tests, 3 Edge Functions, seed data, integration wiring.
- [x] D6: Enterprise Foundation -- **DONE S65-66** (branches, custom_roles, form_templates, certifications, api_keys — 5 tables, 41 total)
- [x] D7a: Certifications Modular -- **DONE S67-68** (certification_types + certification_audit_log — 2 tables, 43 total. 25 seeded system types. Configurable per company. Immutable audit trail. All 3 surfaces use dynamic DB types with enum fallback.)
- [x] D2f: Certificate of Completion -- **DONE S68** (Flutter: job_completion_screen.dart enhanced — detects insurance_claim jobs, adds 4 extra checks: moisture at target, equipment removed, drying complete, TPI final passed. Auto-transitions claim to work_complete. Web CRM: 7th "Completion" tab on claim detail with pre-flight checklist + status transition buttons.)

### Phase T: TPA Module -- SPEC'D (S92)
- [ ] T1-T10: 17 tables, 3 Edge Functions, ~80 hours. Builds after Phase G.
- Spec: `Expansion/39_TPA_MODULE_SPEC.md`

### Phase P: ZScan/Property Intelligence -- SPEC'D (S93)
- [ ] P1-P8: 8 tables, 4 Edge Functions, ~68 hours. Builds after Phase T.
- Spec: `Expansion/40_PROPERTY_INTELLIGENCE_SPEC.md`
- API keys needed: GOOGLE_SOLAR_API_KEY, ATTOM_API_KEY, REGRID_API_KEY

### Phase E: AI Layer -- PAUSED (S80 owner directive — AI goes TRULY LAST, after F+G+T+P)
- [x] E1: Universal AI Architecture -- **DONE (S78)** -- z_threads + z_messages tables, z-intelligence Edge Function (14 tools), Supabase AI API client.
- [x] E2: Z Console Wiring -- **DONE (S78)** -- Web CRM Z Console connected to z-intelligence Edge Function. 2 hooks (use-z-intelligence.ts, use-z-api.ts). Provider updated.
- [x] E3a: AI Troubleshooting Edge Functions -- **DONE (S80)** -- 4 functions (ai-troubleshoot, ai-photo-diagnose, ai-parts-identify, ai-repair-guide). 1,311 lines. All deployed.
- [x] E3b: Team Portal AI Troubleshooting -- **DONE (S80)** -- use-ai-troubleshoot.ts + troubleshoot/page.tsx (1,364 lines, 5-tab UI).
- [x] E3c: Mobile Z Button + AI Chat -- **DONE (S80)** -- ai_service.dart + z_chat_sheet.dart + ai_photo_analyzer.dart. Z FAB in AppShell.
- [x] E3d: Client Portal AI Chat Widget -- **DONE (S80)** -- use-ai-assistant.ts + ai-chat-widget.tsx. Floating Z + slide-up panel.
- [x] E5: Xactimate Estimate Engine -- **DONE (S79)** -- 5 tables, estimate writer (Web CRM + Flutter), PDF output, AI parsing, scope assistant, crowd-sourced pricing. 6 Edge Functions.
- [x] E6: Bid Walkthrough Engine -- **DONE (S79)** -- 5 tables, 12 Flutter screens, annotation system (7 tools), sketch editor (floor plans), CRM/portal viewers, AI bid generation. 4 Edge Functions.
- [ ] E4a-e: Growth Advisor -- **IN PROGRESS (S80)** -- 5 Edge Functions written (2,133 lines), 4 hooks (756 lines), 4 CRM pages (2,263 lines). All files created locally. NOT committed, NOT deployed. Web CRM builds clean with new pages.

### Phase F: Platform Completion -- ALL CODE COMPLETE (S89-S90)
- [x] FM: Firebase→Supabase Migration -- **CODE DONE (S89)** -- 6 tables, 4 EFs (stripe-payments, stripe-webhook, revenuecat-webhook, subscription-credits). Manual steps remain.
- [x] F1: Phone System -- **DONE (S90)** -- 9 tables, 5 EFs (SignalWire). CRM: 3 pages + 2 hooks. Team: 1 page + 1 hook. Client: 1 page + 1 hook. Ops: 1 page + 1 hook.
- [x] F3: Meeting Rooms -- **DONE (S90)** -- 5 tables, 4 EFs (LiveKit). CRM: 4 pages + 2 hooks. Team: 1 page + 1 hook. Client: 2 pages + 1 hook. Ops: 1 page + 1 hook.
- [x] F4: Mobile Field Toolkit -- **DONE (S90)** -- 10 tables, 3 EFs (osha-data-sync, equipment-scanner, walkie-talkie). CRM: 8 pages + 6 hooks. Flutter mobile deferred.
- [x] F5: Business OS Expansion -- **DONE (S90)** -- 25+ tables (8 migrations), 3 EFs (lead-aggregator, payroll-engine, sendgrid-email). CRM: 7 pages + 7 hooks. Team: 4 pages + 4 hooks (MY STUFF). Ops: 3 analytics pages.
- [x] F6: Marketplace -- **DONE (S90)** -- 5 tables, 1 EF. CRM: 1 page + 1 hook. Client: 2 pages + 2 hooks. Ops: 1 analytics page.
- [x] F7: ZAFTO Home Platform -- **DONE (S90)** -- 5 tables. Client: 5 pages + 2 hooks. Premium tier deferred to Phase E + RevenueCat.
- [x] F9: Hiring System -- **DONE (S90)** -- 3 tables. CRM: 1 page + 1 hook. Ops: 1 analytics page. Checkr/E-Verify API integration deferred.
- [x] F10: ZDocs + ZSheets -- **DONE (S90)** -- 3 tables, 1 EF (zdocs-render). CRM: 1 page + 1 hook. DocuSign integration deferred.
- [ ] F2: Website Builder V2 -- NOT BUILT -- After AI. Cloudflare Registrar, templates, AI content.
- [ ] F8: Ops Portal Phases 2-4 -- NOT BUILT -- After AI. Marketing, treasury, legal, dev terminal.

### Phase G: QA & Hardening -- NEXT (then T → P → E)
- [x] G1a: Consolidated Build Verification -- All 5 apps build clean (S90).
- [ ] G1b-e: Dead code cleanup, route verification, DB wiring audit, EF audit.
- [ ] G2: Security audit (RLS, auth, input validation).
- [ ] G3: Performance optimization.
- [ ] G4: Final hardening (Sentry DSN, security headers, deploy migrations).

---

## SECTION 5: CLOUD FUNCTIONS -> EDGE FUNCTIONS

### Firebase Cloud Functions (Still on Firebase -- to be deleted after FM manual steps)
| Function | Purpose | Status |
|----------|---------|--------|
| analyzePanel | Panel AI analysis | **REPLACED** by ai-photo-diagnose EF |
| analyzeNameplate | Nameplate AI analysis | **REPLACED** by ai-photo-diagnose EF |
| analyzeWire | Wire AI analysis | **REPLACED** by ai-photo-diagnose EF |
| analyzeViolation | NEC violation analysis | **REPLACED** by ai-photo-diagnose EF |
| smartScan | Auto-detect AI scan | **REPLACED** by ai-photo-diagnose EF |
| getCredits | Check scan credits | **REPLACED** by subscription-credits EF |
| addCredits | Add AI credits | **REPLACED** by subscription-credits EF |
| revenueCatWebhook | IAP processing | **REPLACED** by revenuecat-webhook EF |
| createPaymentIntent | Stripe payments | **REPLACED** by stripe-payments EF |
| stripeWebhook | Payment events | **REPLACED** by stripe-webhook EF |
| getPaymentStatus | Check payment status | **REPLACED** by stripe-payments EF |
**Manual steps remaining:** Retrieve Firebase secrets → set in Supabase → deploy EFs → update webhook URLs → test → delete Firebase code.

### Supabase Edge Functions (53 directories total -- VERIFIED from codebase)

**Banking/Accounting (5):**
| Function | Purpose | Phase |
|----------|---------|-------|
| plaid-create-link-token | Bank link token generation | D4 |
| plaid-exchange-token | Bank auth token exchange | D4 |
| plaid-get-balance | Bank balance retrieval | D4 |
| plaid-sync-transactions | Bank transaction sync | D4 |
| recurring-generate | Process recurring journal entries | D4 |

**Property Management (3):**
| Function | Purpose | Phase |
|----------|---------|-------|
| pm-rent-charge | Daily rent charge generation + late fees | D5i |
| pm-lease-reminders | Lease expiry notifications (90/60/30 days) | D5i |
| pm-asset-reminders | Asset service due notifications (14 days) | D5i |

**AI Core (1):**
| Function | Purpose | Phase |
|----------|---------|-------|
| z-intelligence | Universal AI — 14 tools (chat, summarize, bid draft, code lookup, etc.) | E1 |

**Xactimate/Estimates (7):**
| Function | Purpose | Phase |
|----------|---------|-------|
| xact-pricing-aggregate | Monthly pricing aggregation cron | E5a |
| xact-code-search | Full-text search on Xactimate codes + pricing | E5a |
| estimate-pdf | Generate Xactimate-style PDF estimates (dormant) | E5c |
| estimate-parse-pdf | Claude Vision PDF import → structured data | E5d |
| estimate-scope-assist | AI gap detection + supplement generator | E5e |
| export-estimate-pdf | D8 branded PDF export — 3 templates, company branding | D8e |
| import-esx | D8 ESX import — ZIP+XML parser, XACTDOC schema, code mapping | D8f |

**D8 Estimate Engine (3):**
| Function | Purpose | Phase |
|----------|---------|-------|
| export-esx | XACTDOC XML generation, ZIP+photos packaging | D8g |
| code-verify | Code contribution verify/reject/promote. Super_admin gate. | D8h |
| pricing-ingest | BLS + FEMA + PPI data ingestion, MSA pricing updates | D8i |

**Walkthrough (4):**
| Function | Purpose | Phase |
|----------|---------|-------|
| walkthrough-analyze | AI room analysis from photos + notes | E6g |
| walkthrough-transcribe | Voice note transcription for walkthroughs | E6g |
| walkthrough-generate-bid | AI bid generation from walkthrough data | E6g |
| walkthrough-bid-pdf | PDF output for walkthrough-generated bids | E6g |

**AI Troubleshooting (4):**
| Function | Purpose | Phase |
|----------|---------|-------|
| ai-troubleshoot | Multi-trade diagnostics (20 trades, NEC/IRC/IPC/IMC) | E3a |
| ai-photo-diagnose | Claude Vision defect detection (1-5 scale) | E3a |
| ai-parts-identify | Text+photo part ID (dual mode) | E3a |
| ai-repair-guide | Skill-adaptive repair guide (3 skill levels) | E3a |

**F1: Phone System — SignalWire (5):**
| Function | Purpose | Phase |
|----------|---------|-------|
| signalwire-voice | VoIP call management | F1 |
| signalwire-sms | SMS messaging | F1 |
| signalwire-fax | Fax send/receive | F1 |
| signalwire-webhook | SignalWire event processing | F1 |
| signalwire-ai-receptionist | AI-powered call handling | F1 |

**F3: Meeting Rooms — LiveKit (4):**
| Function | Purpose | Phase |
|----------|---------|-------|
| meeting-room | Video room management | F3 |
| meeting-recording | Meeting recording management | F3 |
| meeting-capture | Screen/whiteboard capture | F3 |
| meeting-booking | Booking type + scheduling | F3 |

**F4: Field Toolkit (3):**
| Function | Purpose | Phase |
|----------|---------|-------|
| walkie-talkie | Push-to-talk audio channels | F4 |
| team-chat | Team messaging | F4 |
| osha-data-sync | OSHA standards database sync | F4 |

**F5: Business OS (3):**
| Function | Purpose | Phase |
|----------|---------|-------|
| lead-aggregator | Multi-source lead intake (Angi, Thumbtack, etc.) | F5/F6 |
| sendgrid-email | Email send/receive via SendGrid | F5 |
| payroll-engine | Payroll calculation + tax filing | F5 |

**F4/F10: Additional (2):**
| Function | Purpose | Phase |
|----------|---------|-------|
| equipment-scanner | Barcode/QR equipment identification | F4 |
| zdocs-render | PDF document generation (6 actions, 5 templates) | F10 |

**FM: Firebase Migration (4):**
| Function | Purpose | Phase |
|----------|---------|-------|
| stripe-payments | createPaymentIntent + getPaymentStatus | FM |
| stripe-webhook | payment_intent.succeeded/failed → updates tables | FM |
| revenuecat-webhook | IAP purchases + refunds → user_credits | FM |
| subscription-credits | get/add/deduct credits → user_credits + scan_logs | FM |

**E4: Growth Advisor (5 — directories exist, code UNCOMMITTED):**
| Function | Purpose | Phase |
|----------|---------|-------|
| ai-revenue-insights | Profit margins, trends, recommendations | E4 |
| ai-customer-insights | CLV predictions, churn risk, upsell | E4 |
| ai-bid-optimizer | Win probability, competitive pricing | E4 |
| ai-equipment-insights | Lifecycle analysis from property equipment | E4 |
| ai-growth-actions | Follow-up, upsell, campaign suggestions | E4 |

**NOTE:** send-notification does NOT have a directory. It needs to be created.

**Secrets (Firebase → Supabase migration needed):** ANTHROPIC_API_KEY, STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET currently stored as Firebase secrets (`defineSecret` in `backend/functions/index.js`). When migrating to Supabase Edge Functions, set via `npx supabase secrets set`.

---

## SECTION 6: REMAINING CLEANUP

### Flutter App
- [ ] Consolidate duplicate models (Job/Invoice/Customer -- root vs business/). Not blocking, both functional.
- [ ] Remove Firebase project refs when Firebase fully decommissioned
- [ ] Fix 4 compile errors in location_tracking_service.dart (missing battery_plus)
- [ ] Split screen_registry.dart by trade (10,128 lines -- nice-to-have)

### Web CRM
- [x] Remove Firebase SDK -- **DONE B4a S49** (firebase.ts deleted)
- [x] Supabase client -- **DONE B4a S49**
- [ ] Add form validation (react-hook-form + Zod) -- nice-to-have

### Client Portal
- [x] Supabase Auth -- **DONE B6 S56** (magic link + password)
- [ ] Standardize color usage -- minor, not blocking

### All Portals
- [x] RBAC middleware -- **DONE C2 S61**
- [x] Sentry -- **DONE C1a S58**
- [ ] Dependabot weekly scans active -- **DONE C1b S58**

---

CLAUDE: UPDATE THIS FILE AS EVERY CONNECTION IS MADE. This is the living wiring diagram.
