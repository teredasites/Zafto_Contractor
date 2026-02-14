# 52: SYSTEM INTEGRATION MAP

> **Created:** Session 103 (February 2026)
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

### Phase U (Unification) — IN PROGRESS (S111-S112)
| Connection | Sprint | Status |
|-----------|--------|--------|
| U → Nav (all portals) | U2 | WIRED (S111) — Supabase-style sidebar, Z button, hover-expand, role-based nav |
| U → Permissions | U3 | WIRED (S111) — role presets, enterprise tiers, Good/Better/Best |
| U → Ledger (budget vs actual) | U4 | WIRED (S111) — job_budgets table, P&L, approval workflows |
| U → Dashboard (real data) | U5 | WIRED (S111) — live GPS map, real-time clock, mock data eliminated |
| U → PDF/Email | U6 | WIRED (S111) — export-bid-pdf + export-invoice-pdf EFs, SendGrid |
| U → Stripe Connect | U7 | WIRED (S111) — payment flow, permits, SAs, reviews, system health |
| U → Revenue Metrics | U8 | WIRED (S112) — paid-only filter, bid conversion fix, cross-portal verified |
| U → Ops CRUD | U9 | PARTIAL (S112) — company tier/suspend, user role/disable/reset, KB delete |
| U → Auth Flows | U9 | WIRED (S112) — forgot password on web/team/ops portals |
Remaining U10-U22 connections verified during U22 (Isolated Feature Wiring).

### Phase W (Warranty + Lifecycle)
| Connection | Sprint | Status |
|-----------|--------|--------|
| W → Jobs | W1 | PENDING |
| W → Estimates | W1 | PENDING |
| W → ZBooks | W3 | PENDING |
| W → Client Portal | W4 | PENDING |
| W → Notifications | W4 | PENDING |
| W → Phone/SMS | W4 | PENDING |

### Phase J (Job Intelligence)
| Connection | Sprint | Status |
|-----------|--------|--------|
| J → Jobs | J1 | PENDING |
| J → Estimates | J1 | PENDING |
| J → ZBooks | J2 | PENDING |
| J → Schedule | J5 | PENDING |
| J → Client Portal | J4 (Bridge 8) | PENDING |

### Phase L (Permits + Compliance)
| Connection | Sprint | Status |
|-----------|--------|--------|
| L → Jobs | L1 | PENDING |
| L → Estimates | L2 | PENDING |
| L → Schedule | L2 | PENDING |
| L → Client Portal | L9 | PENDING |
| L → Team Portal | L9 | PENDING |
| L → Notifications | L8 | PENDING |
| L → Sketch Engine | L2 | PENDING |

---

## DOCUMENT MAINTENANCE

This document is updated:
1. **At sprint completion** — mark connections as WIRED in tracker
2. **When new systems are added** — add row to connectivity matrix
3. **When gaps are discovered** — add to Critical Integration Bridges section
4. **At session end** — verify tracker matches actual state

**Owner:** Every build session must reference this document.
