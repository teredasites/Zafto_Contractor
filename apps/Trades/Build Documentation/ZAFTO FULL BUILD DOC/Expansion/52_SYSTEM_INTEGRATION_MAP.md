# 52: SYSTEM INTEGRATION MAP

> **Created:** Session 103 (February 2026)
> **Last Updated:** Session 133 (February 18, 2026) — S132-S133 pure research. No new wiring. Pricing finalized. 9 Opus research agents completed. ECO3+ECO4+ECO7+ECO8 spec'd (~48h). BLS/Davis-Bacon/FRED APIs confirmed $0/month. CSI MasterFormat copyrighted — Zafto builds own codes.
> **Purpose:** Master wiring document ensuring every system connects properly. Every sprint MUST check this map before marking complete.

---

## HOW TO USE THIS DOCUMENT

1. **Before starting any sprint**: Look up the system being built in the matrix below
2. **Check every "YES" column**: Verify the sprint spec includes tasks for each required connection
3. **After completing a sprint**: Mark connections as WIRED in the tracker at the bottom
4. **If a connection is missing from sprint specs**: Add integration tasks BEFORE proceeding

---

## SYSTEM CLASSIFICATION

### Hub Systems (touched by most other systems — break these, break everything)
| Hub | Role | Tables | Used By |
|-----|------|--------|---------|
| **Jobs** | Central work record | jobs, job_* | Every system |
| **Estimates** | Financial scope | estimates, estimate_* | Pricing, materials, invoices, financing |
| **Schedule (GC)** | Time coordination | schedule_* | Every time-sensitive system |
| **Notifications** | Alert routing | notification_* | Every system with deadlines/events |
| **ZBooks (Ledger)** | Financial truth | gl_*, journal_*, accounts | Every money-touching system |

### Spoke Systems (connect to hubs only)
| Spoke | Connects To |
|-------|-------------|
| Trade-Specific Tools (Spec 51) | Jobs, Team Portal |
| CE/License Tracker | Team Portal, Notifications |
| Reputation Autopilot | Jobs, Phone/SMS, Client Portal |
| Regulatory Compliance | Jobs, Team Portal, Notifications |

### Bridge Systems (connect two domains)
| Bridge | Domains Connected |
|--------|-------------------|
| Job Cost Autopsy | Estimates ↔ Actuals (ZBooks) |
| Change Order Engine | Scope (Estimates) ↔ Schedule ↔ Invoices |
| Material Procurement | Estimates ↔ Purchase Orders ↔ ZBooks |
| Daily Job Log | Time Clock ↔ Photos ↔ Materials ↔ Weather |
| Property Intelligence (Recon) | Address ↔ Measurements ↔ Estimates |

---

## MASTER CONNECTIVITY MATRIX

### Legend
- **REQ** = Required connection (sprint MUST include integration tasks)
- **OPT** = Optional connection (nice-to-have, not blocking)
- **N/A** = Not applicable
- **WIRED** = Connection implemented and verified

### Core Phase Systems

| System | Jobs | Estimates | ZBooks | Schedule | Client Portal | Team Portal | Notifications | Sketch Engine | Phone/SMS | Recon |
|--------|:----:|:---------:|:------:|:--------:|:-------------:|:-----------:|:-------------:|:-------------:|:---------:|:-----:|
| **T: TPA/Programs** | REQ | REQ | REQ | REQ | REQ | REQ | REQ | N/A | REQ | N/A |
| **P: Property Recon** | REQ | REQ | N/A | N/A | OPT | OPT | OPT | REQ | N/A | N/A |
| **SK: Sketch Engine** | REQ | REQ | N/A | REQ | REQ | REQ | N/A | N/A | N/A | REQ |
| **GC: Scheduler** | REQ | REQ | N/A | N/A | REQ | REQ | REQ | OPT | N/A | N/A |
| **BA: Plan Review** | REQ | REQ | N/A | REQ | REQ | N/A | N/A | REQ | N/A | N/A |

### Business Intelligence Engines (Spec 49)

| Engine | Jobs | Estimates | ZBooks | Schedule | Client Portal | Team Portal | Notifications | Sketch Engine | Phone/SMS | Recon |
|--------|:----:|:---------:|:------:|:--------:|:-------------:|:-----------:|:-------------:|:-------------:|:---------:|:-----:|
| **Warranty Intelligence** | REQ | REQ | REQ | N/A | REQ | N/A | REQ | N/A | REQ | N/A |
| **Job Cost Autopsy** | REQ | REQ | REQ | N/A | OPT | N/A | OPT | N/A | N/A | N/A |
| **Permit & Inspection** | REQ | REQ | N/A | REQ | REQ | REQ | REQ | REQ | OPT | N/A |
| **Property Digital Twin** | REQ | N/A | N/A | N/A | REQ | N/A | N/A | REQ | N/A | REQ |
| **Weather-Aware Schedule** | REQ | N/A | N/A | REQ | REQ | REQ | REQ | N/A | OPT | N/A |
| **Reputation Autopilot** | REQ | N/A | N/A | N/A | REQ | REQ | REQ | N/A | REQ | N/A |
| **Smart Pricing** | REQ | REQ | REQ | REQ | N/A | N/A | OPT | N/A | N/A | N/A |
| **Regulatory Compliance** | REQ | N/A | N/A | N/A | OPT | REQ | REQ | N/A | N/A | N/A |
| **Predictive Maintenance** | REQ | N/A | REQ | REQ | REQ | N/A | REQ | N/A | REQ | N/A |
| **Subcontractor Network** | REQ | REQ | REQ | REQ | N/A | N/A | REQ | REQ | OPT | N/A |

### Business Completion Systems (Spec 50)

| System | Jobs | Estimates | ZBooks | Schedule | Client Portal | Team Portal | Notifications | Sketch Engine | Phone/SMS | Recon |
|--------|:----:|:---------:|:------:|:--------:|:-------------:|:-----------:|:-------------:|:-------------:|:---------:|:-----:|
| **Mechanic's Lien Engine** | REQ | N/A | REQ | N/A | OPT | N/A | REQ | N/A | N/A | N/A |
| **Customer Financing** | N/A | REQ | REQ | N/A | REQ | N/A | REQ | N/A | N/A | N/A |
| **CE/License Tracker** | N/A | N/A | N/A | N/A | N/A | REQ | REQ | N/A | N/A | N/A |
| **Material Procurement** | REQ | REQ | REQ | N/A | N/A | REQ | REQ | REQ | N/A | N/A |
| **Daily Job Log** | REQ | N/A | REQ | N/A | REQ | REQ | N/A | N/A | N/A | N/A |
| **Change Order Engine** | REQ | REQ | REQ | REQ | REQ | REQ | REQ | N/A | N/A | N/A |

### Trade-Specific Tools (Spec 51)

All 19 trade tools share the same connection pattern:
| Connection | Required? | Notes |
|-----------|:---------:|-------|
| Jobs | REQ | Every tool record links to a job |
| Team Portal | REQ | Field techs use tools on-site |
| CRM | REQ | Office staff view/manage tool records |
| Client Portal | OPT | Some tools generate client-facing docs (AIA billing, backflow tests) |
| Estimates | OPT | Tool outputs can inform line items |
| Notifications | OPT | Compliance tools (refrigerant, backflow) may trigger alerts |

---

## CRITICAL INTEGRATION BRIDGES

These are the 8 connections identified as missing from current sprint specs. Each MUST be added before the relevant phase ships.

### Bridge 1: TPA → Schedule (Phase T)
**Problem:** TPA jobs have strict SLA deadlines (2hr first contact, 24hr onsite, 24hr estimate) but don't block schedule capacity.
**Solution:** When a TPA assignment is accepted:
- Auto-create schedule task with SLA deadline as constraint
- Block technician capacity for estimated duration
- Show SLA countdown on schedule view
**Add to:** Sprint T2 (Assignment Tracking) or T9 (Portal Integration)

### Bridge 2: TPA → Client Portal (Phase T)
**Problem:** Homeowners on insurance jobs can't see TPA job progress.
**Solution:** Client Portal shows:
- TPA program name, claim number
- SLA status (met/approaching/overdue)
- Documentation checklist progress
- Adjuster contact info (if contractor shares it)
**Add to:** Sprint T9 (Portal Integration)

### Bridge 3: TPA → Notifications (Phase T)
**Problem:** SLA deadlines don't trigger alerts.
**Solution:** Auto-notifications at:
- Assignment received (push + SMS)
- 30 min before SLA deadline
- At SLA deadline (escalation)
- SLA overdue (alert owner + admin)
**Add to:** Sprint T2 or T5

### Bridge 4: Recon → Estimates (Phase P)
**Problem:** Property scan measurements don't auto-populate estimate line items.
**Solution:**
- Add `property_scan_id` FK to estimates table
- "Create Estimate from Scan" button on property scan detail
- Auto-populate: roof area → roofing line items, wall area → siding/painting, sq ft → flooring
- Measurements flow into estimate's quantity fields
**Add to:** Sprint P4 (Estimate Integration) — ALREADY PARTIALLY SPEC'D, verify completeness

### Bridge 5: Sketch → Schedule (Phase SK)
**Problem:** Floor plan complexity doesn't inform task duration estimates.
**Solution:**
- Sketch auto-calculates total sq ft, room count, multi-story flag
- When creating schedule task from a job with sketches, suggest duration based on sq ft × trade multiplier
- Trade multipliers configurable per company (e.g., painting = 200 sq ft/hr, electrical rough-in = 150 sq ft/hr)
**Add to:** Sprint SK8 (Auto-Estimate Pipeline) or GC10 (ZAFTO Integration Wiring)

### Bridge 6: Blueprint Analyzer → Schedule (Phase BA)
**Problem:** AI-generated task lists from plan review don't export to scheduler.
**Solution:**
- BA output includes: task name, trade, dependencies, estimated duration
- "Import to Schedule" button creates schedule_tasks from BA output
- Dependencies map to schedule predecessors
- Durations come from AI + historical job cost data
**Add to:** Sprint BA6 (Estimate + Material Order Generation) or GC10

### Bridge 7: Reputation → Client Portal
**Problem:** Review requests go via SMS, no in-platform review submission.
**Solution:**
- Client Portal "Leave a Review" page
- Star rating + text review form
- Routes to Google/Yelp/BBB or stores internally if no platform link
- Satisfaction gate: if < 4 stars, routes to private feedback instead
**Add to:** Sprint U-REP2 (Review Request Flow)

### Bridge 8: Job Cost Autopsy → Client Portal
**Problem:** No transparency option for completed job cost analysis.
**Solution:**
- Optional "Cost Transparency" toggle per job (default OFF)
- When ON, Client Portal shows: original estimate vs final invoice, change order summary, variance % with explanation
- Contractor controls what the client sees
**Add to:** Sprint J4 (Job Intelligence Web CRM) — add Client Portal section

---

## UNIVERSAL INTEGRATION CHECKLIST

**Copy this into every sprint spec. Check every item before marking sprint complete.**

```
## Integration Checklist
- [ ] Jobs: Does this system read/write job records? FK exists?
- [ ] Estimates: Does this system affect pricing/scope? Connected?
- [ ] ZBooks: Does this system create revenue/expense? GL entries wired?
- [ ] Schedule: Does this system affect project timeline? Tasks created?
- [ ] Client Portal: Does the customer need to see this? View exists?
- [ ] Team Portal: Does field staff use this? View exists?
- [ ] Notifications: Are there time-sensitive events? Triggers defined?
- [ ] Sketch Engine: Does this system use spatial data? FK exists?
- [ ] Phone/SMS: Does this system communicate with customers? Hooks wired?
- [ ] Recon (Property): Does this system use property measurements? FK exists?
- [ ] Supabase RLS: company_id scoping? Policies created (SELECT/INSERT/UPDATE/DELETE)?
- [ ] Audit trigger: audit_trigger_fn on new tables?
- [ ] Soft delete: deleted_at column? WHERE deleted_at IS NULL in queries?
```

---

## SUPABASE SYNCHRONY RULES

### Migration Ordering
Phases MUST be migrated in build order. Each phase's tables may reference previous phase tables:
```
T tables → P tables (property_scans.job_id → jobs from T context)
P tables → SK tables (sketch_plans.property_scan_id → property_scans)
SK tables → GC tables (schedule_tasks may reference sketch measurements)
GC tables → U tables (U17 data flow wiring connects everything)
U tables → W tables (warranty_records.job_id, warranty_records.estimate_id)
W tables → J tables (job_cost_autopsies.warranty_callbacks)
J tables → L tables (permit_records.job_id, lien_records.job_id)
```

### RLS Pattern (same for every table)
```sql
ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;
CREATE POLICY "<table>_select" ON <table> FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "<table>_insert" ON <table> FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "<table>_update" ON <table> FOR UPDATE USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "<table>_delete" ON <table> FOR DELETE USING (company_id = auth.company_id() AND auth.user_role() IN ('owner', 'admin'));
```

### Realtime Channel Strategy
Do NOT create one channel per table. Use multiplexed channels:
```typescript
// GOOD: One channel, multiple table subscriptions
const channel = supabase.channel('job-updates')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'jobs' }, handler)
  .on('postgres_changes', { event: '*', schema: 'public', table: 'job_notes' }, handler)
  .on('postgres_changes', { event: '*', schema: 'public', table: 'job_photos' }, handler)
  .subscribe();

// BAD: Three separate channels
const ch1 = supabase.channel('jobs').on(...)
const ch2 = supabase.channel('job-notes').on(...)
const ch3 = supabase.channel('job-photos').on(...)
```

### Edge Function Auth Pattern (same for every function)
```typescript
const authHeader = req.headers.get('Authorization')!;
const { data: { user }, error } = await supabase.auth.getUser(
  authHeader.replace('Bearer ', '')
);
if (error || !user) return new Response('Unauthorized', { status: 401 });
const companyId = user.app_metadata.company_id;
const role = user.app_metadata.role;
```

---

## WIRING TRACKER

Update this section as sprints are completed. Mark each connection as it's verified working.

### Phase T (Programs/TPA)
| Connection | Sprint | Status |
|-----------|--------|--------|
| T → Jobs | T1-T2 | PARTIAL (T1: ALTER jobs + tpa_assignment_id/tpa_program_id/is_tpa_job columns + indexes. T2 will wire assignment→job creation) |
| T → Estimates | T8 | PENDING |
| T → ZBooks | T6 | PENDING |
| T → Schedule | T2/T9 (Bridge 1) | PENDING |
| T → Client Portal | T9 (Bridge 2) | PENDING |
| T → Team Portal | T9 | PENDING |
| T → Notifications | T2/T5 (Bridge 3) | PENDING |
| T → Phone/SMS | T5 | PENDING |

### Phase P (Property Intelligence)
| Connection | Sprint | Status |
|-----------|--------|--------|
| P → Jobs | P1 | WIRED (S105) |
| P → Estimates | P4 (Bridge 4) | WIRED (S105) |
| P → Sketch Engine | P7 | WIRED (S105) |
| P → Client Portal | P8 | WIRED (S105) |
| P → Team Portal | P8 | WIRED (S105) |
| P → Ops Portal | P10 | WIRED (S105) |
| P → Mobile App | P7 | WIRED (S105) |

### Phase SK (Sketch Engine) — COMPLETE (S109)
| Connection | Sprint | Status |
|-----------|--------|--------|
| SK → Jobs | SK1 | WIRED (S106) |
| SK → Estimates | SK8 | WIRED (S108) — floor_plan_estimate_links bridge, room_measurement_calculator, estimate_area_generator, line_item_suggester, GenerateEstimateModal |
| SK → Schedule | GC10 (Bridge 5) | PENDING |
| SK → Client Portal | SK11 | WIRED (S109) — read-only viewer, base plan only (no trade layers) |
| SK → Team Portal | SK11 | WIRED (S109) — read-only viewer with layer toggles + photo pins |
| SK → Recon | SK1 | WIRED (S106) |
| SK → Export | SK9 | WIRED (S109) — PDF/PNG/DXF/FML/SVG (Flutter + Web) |
| SK → 3D View | SK10 | WIRED (S109) — three.js/R3F wall extrusion, orbit controls |
| SK → Site Plan | SK12 | WIRED (S109) — exterior trades, 17 tools, 8 layers, trade formulas |
| SK → Collaboration | SK14 | WIRED (S109) — cursor/presence types, element locks, snap guides |

### Phase GC (Scheduler)
| Connection | Sprint | Status |
|-----------|--------|--------|
| GC → Jobs | GC1+GC10 | WIRED (S110) — schedule_projects.job_id FK, job detail mini Gantt, field progress sync |
| GC → Estimates | GC10 | WIRED (S110) — EVM cost loading from Ledger, budgeted vs actual tracking |
| GC → Client Portal | GC8 | WIRED (S110) — client schedule viewer (read-only Gantt + task list) |
| GC → Team Portal | GC8 | WIRED (S110) — team schedule viewer (task list + progress update) |
| GC → Notifications | GC10 | WIRED (S110) — schedule-reminders cron EF (24h task, 48h milestone, delay, trade overlap) |
| GC → Team/Resources | GC10 | WIRED (S110) — schedule_resources.user_id → users.id, team member picker |
| GC → Field Tools | GC10 | WIRED (S110) — schedule-sync-progress EF (daily_log, photo, punch_list, job_status) |
| GC → Weather | GC5 | WIRED (S110) — weather integration, outdoor task delay detection |
| GC → Sketch | GC10 | WIRED (S110) — sq ft duration suggestions from sketch measurements |

### Phase U (Unification) — COMPLETE (S111-S114)
| Connection | Sprint | Status |
|-----------|--------|--------|
| U → Nav (all portals) | U2 | WIRED (S111) — Supabase-style sidebar, Z button, hover-expand, role-based nav |
| U → Permissions | U3 | WIRED (S111) — role presets, enterprise tiers, Good/Better/Best |
| U → Ledger (budget vs actual) | U4 | WIRED (S111) — job_budgets table, P&L, approval workflows |
| U → Dashboard (real data) | U5 | WIRED (S111) — live GPS map, real-time clock, mock data eliminated |
| U → PDF/Email | U6 | WIRED (S111) — export-bid-pdf + export-invoice-pdf EFs, SendGrid |
| U → Stripe Connect | U7 | WIRED (S111) — payment flow, permits, SAs, reviews, system health |
| U → Revenue Metrics | U8 | WIRED (S112) — paid-only filter, bid conversion fix, cross-portal verified |
| U → Ops CRUD | U9 | WIRED (S112) — company tier/suspend, user role/disable/reset, KB delete |
| U → Auth Flows | U9 | WIRED (S112) — forgot password on web/team/ops portals |
| U → i18n | U13 | WIRED (S114) — Flutter ARB localization, 10 languages |
| U → Trade Support | U14 | WIRED (S114) — universal trade type system, 16+ trades |
| U → GPS Walkthrough | U15c | WIRED (S114) — altitude, accuracy, path tracking, photo clustering |
| U → Dispatch Board | U18 | WIRED (S114) — drag-drop assignment, haversine ETA, customer SMS, map view |
| U → Data Import | U19 | WIRED (pre-S114) — CSV/IIF parser, duplicate detection, batch undo |
| U → Subcontractors | U20 | WIRED (pre-S114) — subs management, 1099 export |
| U → Calendar Sync | U21 | WIRED (pre-S114) — Google Calendar, notification triggers |
| U → Phone Config | U23 | WIRED (S114) — 6-tab settings page, 3 hooks, 5 trade presets, IVR builder, ring groups, AI receptionist config |

### Phase D5-PV (Payment Verification + Government Programs) — COMPLETE (S117)
| Connection | Sprint | Status |
|-----------|--------|--------|
| D5-PV → Rent Payments | D5-PV1 | WIRED (S117) — ALTER rent_payments: 14 payment methods, verification workflow columns, payment source tracking |
| D5-PV → Government Programs | D5-PV1 | WIRED (S117) — government_payment_programs table: Section 8 HCV, VASH, public housing, voucher tracking, HAP amounts, recertification dates |
| D5-PV → Audit Trail | D5-PV1 | WIRED (S117) — payment_verification_log immutable table (INSERT only): reported/verified/disputed/rejected/updated/proof_uploaded |
| D5-PV → Invoices | D5-PV1 | WIRED (S117) — ALTER invoices: last_payment_method, last_payment_source, last_payment_reference |
| D5-PV → Client Portal | D5-PV2 | WIRED (S117) — tenant self-report form (9 offline methods), proof upload to receipts bucket, verification status badges |
| D5-PV → Web CRM | D5-PV3 | WIRED (S117) — owner verify/dispute/reject, government program CRUD, expanded recordPayment, pending verification queue |
| D5-PV → Flutter Mobile | D5-PV4 | WIRED (S117) — RentPayment model rewrite, GovernmentPaymentProgram model, verification repo methods |
| D5-PV → Notifications | D5-PV5 | WIRED (S117) — 6 types: payment_reported, payment_verified, payment_disputed, payment_rejected, hap_payment_due, recertification_upcoming |

### Tech App Buildout (S119-S120)
| Connection | Sprint | Status |
|-----------|--------|--------|
| Tech → Jobs | S119-S120 | WIRED — tech_jobs_screen reads jobsProvider, tech_schedule_screen filters by scheduledStart, tap→JobDetailScreen |
| Tech → Walkthrough | S120 | WIRED — tech_walkthrough_screen reads walkthroughsProvider, CTA→WalkthroughStartScreen, recent list→CaptureScreen/SummaryScreen |
| Tech → Time Clock | S119 | WIRED — tech_home_screen CLOCK IN button→TimeClockScreen, My Hours→TechTimesheetScreen |
| Tech → Role System | S120 | WIRED — roleOverrideProvider (override > JWT auth > fallback), role_switcher_screen uses override |
| Tech → Contact | S119 | WIRED — job_detail_screen: Call (tel:), Text (sms:), Directions (maps URL) via url_launcher |

### Phase INS (Inspector Deep Buildout) — COMPLETE (S121-S124)
| Connection | Sprint | Status |
|-----------|--------|--------|
| INS → Inspection Templates | INS1-INS2+INS9 | WIRED (S121-S123) — template-driven checklists (25 templates, 1,147 items, 173 sections), 19 inspection types, weighted scoring, section grouping. INS9: depth rewrite 13→25 templates with real building code refs |
| INS → Deficiency Tracking | INS3 | WIRED (S121) — photo proof, severity levels, code citations, resolution workflow |
| INS → PDF Reports | INS4 | WIRED (S121) — inspection summary generation, deficiency appendix, score breakdown |
| INS → GPS Location | INS5-INS6 | WIRED (S122) — geolocator 11.x, location capture on start/complete, reinspection diffs |
| INS → Code Reference | INS7+INS9 | WIRED (S122-S123) — 61 offline code sections (NEC/IBC/IRC/OSHA/NFPA), search, filter, citation copy, pickMode. INS9: multi-select code ref search sheet, code_refs JSONB on pm_inspection_items, wired into execution save/load |
| INS → Compliance Calendar | INS7 | WIRED (S122) — overdue/today/week/upcoming grouping, stats row, visual timeline |
| INS → Permit Tracker | INS7 | WIRED (S122) — 8 permit types with inspection stages, CO eligibility, expiration warnings |
| INS → Time Clock | INS6 | WIRED (S122) — home screen clock status via activeClockEntryProvider, hours via timeClockStatsProvider |
| INS → Web CRM | INS8 | WIRED (S122) — use-inspection-templates hook (CRUD+realtime), templates page, inspection [id] detail |
| INS → Ops Portal | INS8 | WIRED (S122) — inspector-metrics page (platform-wide analytics, inspections by type, deficiencies by severity) |
| INS → Team Portal | INS8 | WIRED (S122) — inspections page (upcoming/history, stats, pass rate, per-user filtering) |
| INS → Tools Screen | INS7 | WIRED (S122) — Code Reference, Compliance Calendar, Permit Tracker in tools carousel |

### Phase W (Warranty + Lifecycle) — COMPLETE (S113 chain)
| Connection | Sprint | Status |
|-----------|--------|--------|
| W → Jobs | W1 | WIRED (S113) — warranty_claims.job_id FK, job detail warranty tab |
| W → Estimates | W1 | WIRED (S113) — warranty data flows to estimate context |
| W → ZBooks | W1 | WIRED (S113) — warranty cost tracking in ledger hooks |
| W → Client Portal | W1 | WIRED (S113) — warranty intelligence page in client portal |
| W → Notifications | W1 | WIRED (S113) — outreach log for expiry/maintenance/recall alerts |
| W → CRM | W1 | WIRED (S113) — warranty intelligence dashboard, equipment lifecycle |

### Phase J (Job Intelligence) — COMPLETE (S113 chain)
| Connection | Sprint | Status |
|-----------|--------|--------|
| J → Jobs | J1 | WIRED (S113) — smart pricing hooks, job analytics |
| J → Estimates | J1 | WIRED (S113) — pricing intelligence feeds estimate engine |
| J → ZBooks | J2 | WIRED (S113) — financial analytics integration |
| J → Schedule | J2 | WIRED (S113) — job timeline intelligence |
| J → Client Portal | J2 | WIRED (S113) — job analytics visible in client portal |

### Phase L (Permits + Compliance) — COMPLETE (S113 chain)
| Connection | Sprint | Status |
|-----------|--------|--------|
| L → Jobs | L1 | WIRED (S113) — permit_applications.job_id FK, job detail permits tab |
| L → Jurisdictions | L2 | WIRED (S113) — jurisdiction lookup, PostGIS boundary matching |
| L → Compliance | L3 | WIRED (S113) — compliance_checklist_items per job, auto-requirements |
| L → Client Portal | L9 | WIRED (S113) — permits + compliance views in client portal |
| L → Team Portal | L9 | WIRED (S113) — field compliance checklist in team portal |
| L → Liens | L5 | WIRED (S113) — lien_filings + lien_payments, deadline tracking |
| L → CE Tracker | L8 | WIRED (S113) — ce_courses + ce_credits + ce_requirements per employee |

### Phase G (QA/Hardening) — IN PROGRESS (S113)
| Connection | Sprint | Status |
|-----------|--------|--------|
| G → RLS (all tables) | G2 | WIRED (S113) — 263/266 tables with RLS, 3 gaps fixed via migration |
| G → Security Headers | G4 | WIRED (S113) — X-Frame-Options, X-Content-Type-Options, etc. on all 4 portals |
| G → CI/CD | G5 | WIRED (S113) — codemagic.yaml with 3 workflows |

### Phase RE (Realtor Platform) — SPEC'D (S129)
| Connection | Sprint | Status |
|-----------|--------|--------|
| RE → Auth (magic link + password) | RE1 | PENDING — brokerage RBAC (8 roles), company_type column, role-based routing |
| RE → Recon (Property Intelligence) | RE2+RE5 | PENDING — realtors get full Recon scan, CMA engine consumes property data |
| RE → Sketch Engine | RE7 | PENDING — realtors get LiDAR/AR sketch for staging, measurement |
| RE → Estimates | RE5 | PENDING — CMA engine uses contractor estimation engine for repair cost accuracy |
| RE → Jobs/Dispatch | RE3 | PENDING — dispatch engine creates work orders, contractor bid collection |
| RE → Inspectors | RE3 | PENDING — realtor dispatches inspectors using same INS infrastructure |
| RE → Commission Engine | RE4 | PENDING — commission plans, split tracking, 1099 generation |
| RE → Transaction Engine | RE5+RE6 | PENDING — deal lifecycle: lead→listing→pending→closed, document management |
| RE → CRM (contacts/pipeline) | RE2 | PENDING — contact database, deal pipeline, activity timeline |
| RE → Lead Gen Pipeline | RE8 | PENDING — Socrata, public records, skip tracing, DNC compliance |
| RE → Marketing Factory | RE9 | PENDING — listing materials, social templates, email campaigns |
| RE → Seller Finder Engine | RE10 | PENDING — pre-market lead identification via public data signals |
| RE → Brokerage Admin | RE11 | PENDING — agent roster, onboarding, compliance dashboard |
| RE → Cross-Platform Sharing | RE12 | PENDING — Zafto Contractor ↔ Zafto Realtor intelligence sharing |
| RE → Field Tools (contractor) | RE3 | PENDING — dispatched contractors get same 35+ calculators/tools |
| RE → Jurisdiction (JUR4) | JUR4 | PENDING — 50-state disclosures, agency rules, attorney states, commission regs |
| RE → AI (Phase E) | Phase E | PENDING — same AI chat/analysis as contractor side |
| RE → Ops Portal | RE15 | PENDING — realtor metrics, platform health |
| RE → Client Portal | RE14 | PENDING — buyer/seller portal with transaction tracking |
| RE → Realtor Portal | RE1-RE20 | PENDING — 6th portal: realtor.zafto.cloud (~85-100 routes) |
| G → XSS Protection | G2 | WIRED (S113) — DOMPurify in ZDocs rendering |
| G → Webhook Security | G2 | WIRED (S113) — SignalWire webhook secret verification added |
| G → Manual QA | G6-G10 | PENDING — requires running app + manual testing |

### Phase SEC (Security Hardening) — COMPLETE (SEC1+SEC6-8, S131)
| Connection | Sprint | Status |
|-----------|--------|--------|
| SEC → Storage RLS | SEC1 | WIRED (S131) — 8 buckets, company-scoped policies, delete protection |
| SEC → Rate Limiter | SEC1 | WIRED (S131) — rate_limit_buckets table, atomic RPC, pg_cron cleanup |
| SEC → EF Auth | SEC6-8 | WIRED (S131) — auth + CORS + request validation on all 94 EFs |

### Phase FIELD (Field Operations) — COMPLETE (FIELD1-5, S131)
| Connection | Sprint | Status |
|-----------|--------|--------|
| FIELD → Messaging | FIELD1 | WIRED (S131) — conversations + messages + members tables, Flutter screens, CRM/team pages |
| FIELD → Equipment | FIELD2 | WIRED (S131) — equipment_items + checkouts, auto-holder trigger, Flutter + CRM + team pages |
| FIELD → Team Photos/Voice/Sig | FIELD3 | WIRED (S131) — gallery upload, voice player, signature viewer in team portal |
| FIELD → Laser Meter | FIELD4 | WIRED (S131) — 5 brand adapters, Web Bluetooth, Sketch Engine integration |
| FIELD → BYOC Phone | FIELD5 | WIRED (S131) — company_phone_numbers, phone config, ops billing page |

### Phase REST (Restoration Trades) — COMPLETE (REST1-2, S131)
| Connection | Sprint | Status |
|-----------|--------|--------|
| REST → Fire Restoration | REST1 | WIRED (S131) — 6 tables, 1 EF, Flutter (4 screens, 2 models), CRM + team + client pages, 55 seed line items |
| REST → Mold Remediation | REST2 | WIRED (S131) — 4 tables, 1 EF, Flutter (5 screens), CRM + team + client pages, IICRC S520, 50-state regs |

### Phase NICHE (Niche Trade Modules) — COMPLETE (NICHE1-2, S131)
| Connection | Sprint | Status |
|-----------|--------|--------|
| NICHE → Pest Control | NICHE1 | WIRED (S131) — 3 tables, 1 EF, Flutter (4 screens, 2 models), CRM + team + client pages, NPMA-33 WDI |
| NICHE → Locksmith | NICHE2 | WIRED (S131) — locksmith_service_logs, Flutter model/repo/screen, CRM page + hook, in team + client combined views |
| NICHE → Garage Door | NICHE2 | WIRED (S131) — garage_door_service_logs, Flutter model/repo/screen, CRM page + hook, in team + client combined views |
| NICHE → Appliance Repair | NICHE2 | WIRED (S131) — appliance_service_logs, Flutter model/repo/screen, CRM page + hook, in team + client combined views |

### Phase DEPTH (Depth Audit) — DEPTH1 COMPLETE (S131)
| Connection | Sprint | Status |
|-----------|--------|--------|
| DEPTH → Core Business | DEPTH1 | WIRED (S131) — customer ID fix, CRM mapper, team portal contact card, client CO buttons, Tasks→schedule_tasks, Materials→job_materials, invoice fields, customer edit/delete/create |

### Phase SEC-AUDIT — Security Hardening (S141-S142)
| Connection | Sprint | Status |
|-----------|--------|--------|
| SEC-AUDIT → RLS/Auth/Soft-Delete | SEC-AUDIT-1→6 | WIRED (S141-S142) — 20 CRITICAL + 31 HIGH findings fixed, 60+ RLS policies, 30 audit triggers, credit race conditions, webhook auth, soft deletes |

### Phase A11Y — Accessibility (S142-S143)
| Connection | Sprint | Status |
|-----------|--------|--------|
| A11Y → All 4 Portals | A11Y-1→3 | WIRED (S142-S143) — skip links, ARIA landmarks, focus management, color contrast AA, reduced motion, screen reader, keyboard nav, PDF accessibility, WCAG 2.1 AA compliance |

### Phase LEGAL — Legal Defense (S143)
| Connection | Sprint | Status |
|-----------|--------|--------|
| LEGAL → Disclaimers | LEGAL-1 | WIRED (S143) — legal_disclaimers table, system_settings, disclaimer acceptance tracking |
| LEGAL → TOS/Privacy | LEGAL-3 | WIRED (S143) — TOS/privacy policy scaffold pages in all 4 portals |
| LEGAL → Reference Registry | LEGAL-4 | WIRED (S143) — legal_reference_registry (46 entries), compliance health dashboard, system_alerts, freshness cron |
| LEGAL → Contextual Defense | LEGAL-2 | PARTIAL — disclaimers table exists, per-calculator wiring deferred to DEPTH sprints |

### Phase INFRA — Infrastructure (S143)
| Connection | Sprint | Status |
|-----------|--------|--------|
| INFRA → Performance | INFRA-4 | WIRED (S143) — 30 B-tree + 8 BRIN + 7 partial + 5 GIN indexes, 2 materialized views, STABLE auth funcs |
| INFRA → Full-Text Search | INFRA-4 | WIRED (S143) — TSVECTOR + GIN on 6 tables, global-search EF |
| INFRA → Utilities | INFRA-5 | WIRED (S143) — webhook_events, idempotency, feature-flags (5-min cache), optimistic-lock, health-check EF, structured logger |
| INFRA → All 4 Portals (utils) | INFRA-5 | WIRED (S143) — feature-flags.ts + optimistic-lock.ts copied to all 4 portals |
| INFRA → Environments | INFRA-1→3 | PENDING — Supabase production setup, branching, Vercel Pro multi-app (NEEDS OWNER) |

### Phase TEST-INFRA — Testing (S143)
| Connection | Sprint | Status |
|-----------|--------|--------|
| TI → Vitest | TI-3 | WIRED (S143) — vitest.config.ts, setup.ts, supabase-mock.ts in all 4 portals, 9 tests passing |

### Phase INTEG — Ecosystem Integration (S132: INTEG2-8 ADDED)
| Connection | Sprint | Status |
|-----------|--------|--------|
| INTEG → National Portals | INTEG1 | PENDING — per-national format templates, one-click export, verification bundles |
| INTEG → Engine-to-Engine (VIZ↔SK, Trade Tools→Estimate) | INTEG2 | PENDING (S132) — VIZ↔SK bidirectional, VIZ→Estimate, Trade Tools→Estimate bridge, property_scans unification, material catalog unification |
| INTEG → Client Portal Activation | INTEG3 | PENDING (S132) — estimate approval, invoice payment, VIZ 3D viewer, Recon intel, restoration progress, customer bridge |
| INTEG → Weather Engine | INTEG4 | PENDING (S132) — NOAA scheduling overlay, dispatch weather layer, field tools context, shared storm processor |
| INTEG → Three-Sided Marketplace | INTEG5 | PENDING (S132) — job completion effects, realtor dispatch VIZ/SK, post-close onboarding, reputation matching, seller leads |
| INTEG → Deduplication | INTEG6 | PENDING (S132) — RE26/CLIENT3 maintenance unification, FLIP2/RE3 comp analysis, storm data single pipeline |
| INTEG → Calculator Bridge | INTEG7 | PENDING (S132) — 1,139 calcs → estimate + sketch + permit connections |
| INTEG → Free API Enrichment | INTEG8 | PENDING (S132) — BLS/PPI, FEMA, EPA, ENERGY STAR, Rewiring America, Census |

### S132 Ecosystem Audit: 10 Critical Failures (see `memory/s132-ecosystem-audit.md`)
| # | Failure | Impact |
|---|---------|--------|
| 1 | VIZ Engine is an island — 202h built, ZERO outbound connections | All 3 platforms can't see 3D |
| 2 | 1,139 calculators are a dead end — results vanish | No business document integration |
| 3 | Client portal is receive-only | No approve/pay/view in portal |
| 4 | Sketch Engine is office-only — field workers can't access | LiDAR tool inaccessible to scanners |
| 5 | Weather completely absent from production | Zero NOAA integration despite spec |
| 6 | RE26/CLIENT3 duplicate maintenance engine | Two independent identical systems |
| 7 | FLIP2/RE3 duplicate comp analysis | Two independent comp engines |
| 8 | Storm data pulled independently by 4+ systems | Wasteful, inconsistent |
| 9 | Job completion has zero downstream effects | Three-sided flywheel broken |
| 10 | Integration map had zero RE/FLIP/CLIENT/VIZ rows | No developer checks these |

### Pending Wiring Sections (S132 — to be built)
**Realtor Platform (RE1-RE30):** 30 sprints, ~744h. Not yet built. Rows will be added as RE sprints complete.
**Homeowner Platform (CLIENT1-17):** 17 sprints, ~378h. In masterfile. Rows will be added as CLIENT sprints complete.
**FLIP-It Engine (FLIP1-6):** 6 sprints, ~92h. Not yet built. Rows will be added as FLIP sprints complete.
**VIZ Engine (VIZ1-VIZ14):** 14 sprints, ~202h. In masterfile. Rows will be added as VIZ sprints complete.

---

## DOCUMENT MAINTENANCE

This document is updated:
1. **At sprint completion** — mark connections as WIRED in tracker
2. **When new systems are added** — add row to connectivity matrix
3. **When gaps are discovered** — add to Critical Integration Bridges section
4. **At session end** — verify tracker matches actual state
5. **S132 addition:** When RE/FLIP/CLIENT/VIZ sprints complete, add wiring rows to tracker

**Owner:** Every build session must reference this document.
