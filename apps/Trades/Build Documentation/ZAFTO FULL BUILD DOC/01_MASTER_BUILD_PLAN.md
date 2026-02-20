# ZAFTO MASTER BUILD PLAN — NO DRIFT
## Single Source of Truth — Every Feature, Every Phase, Every Decision
### Last Updated: February 19, 2026 (Session 138 — Full project audit (103 findings), SEC-AUDIT + P-FIX1 + A11Y + LEGAL + LAUNCH-FLAVORS + APP-DEPTH spec'd. 21 CLAUDE.md rules. Drift synchronized. ~155 sprints, ~2,860h.)

---

## WHAT IS ZAFTO

Complete business-in-a-box for trades. One subscription replaces 12+ tools. Stripe-level quality for blue-collar professionals. Multi-trade platform that scales by uploading knowledge, not building screens. **Three-sided marketplace:** Contractor ↔ Homeowner ↔ Realtor, with a free Adjuster Portal as a Trojan horse into the $35B insurance claims ecosystem.

**Owner:** Damian Tereda — Tereda Software LLC (DBA: ZAFTO)

---

## DESIGN PHILOSOPHY

**"Stripe for Trades"** — Premium, clean, information-dense, professional.

| Principle | Rule |
|-----------|------|
| Logo | "ZAFTO" wordmark (like Stripe uses "stripe"). NOT just the Z. |
| Z mark | Reserved for AI/premium features: Z Intelligence, Ledger, Dashboard |
| CRM accent | Per Design System v2.6 |
| Client Portal accent | Stripe purple `#635bff` |
| Ops Portal accent | Deep navy/teal (distinct from both) |
| Icons | Lucide only. No emojis anywhere. |
| Typography | Inter. Clean, readable, professional. |
| Inspiration | Linear (keyboard-first), Stripe (density), Vercel (data viz), Apple (detail) |

---

## API COST PRINCIPLE — STANDING RULE FOR ALL PHASES

**Launch with $0/month external API costs.** Use only free and freemium APIs (within free tiers) at launch. Paid APIs are post-revenue additions — only integrate when monthly subscription revenue justifies the cost.

| Rule | Detail |
|------|--------|
| **Free-first** | Every feature must have a free-tier fallback that still delivers value |
| **Feature flags** | Paid API integrations are built but GATED behind Supabase secret presence (no key = graceful skip) |
| **No enterprise APIs at launch** | APIs with no free tier and enterprise-only pricing are NOT on the roadmap until post-traction |
| **Cost tracking** | Every API call logged with cost. Ops portal dashboard shows monthly API spend |
| **Upgrade path** | Adding a paid API key auto-enables the enriched features — no code changes needed |

**This applies to:** Phase P (Recon), Phase SK (Sketch Engine), Phase E (AI), and ALL future expansion phases.

---

## AI MONETIZATION MODEL — STANDING RULE

**AI is a tier feature, not a separate product.** No credits, no tokens, no scan counts, no packages. AI just works.

| Rule | Detail |
|------|--------|
| **No credits/tokens/packages** | KILLED. No credit packs, no tokens, no "buy 50 scans," no game currency. None of that. |
| **No visible counts** | User never sees "74 of 100 remaining." No numbers. No scan limits on pricing page. |
| **Usage meter** | Settings shows a clean visual usage bar (no numbers). Fills up with use. Resets monthly with billing cycle. |
| **Tier thresholds** | Each tier has an internal cost threshold (invisible to user). Solo < Team < Business. Exact thresholds set during Phase G when real token costs are measurable. |
| **Cutoff behavior** | When threshold exceeded: AI features blocked, everything else works. User sees: "You've reached your AI usage for this month." Then two options: buy more or upgrade. |
| **Buy more AI usage** | Clean dollar amounts, no units: **$10 \| $25 \| $50 \| $100**. User taps a dollar amount, meter refills proportionally, AI turns back on. No token counts, no "you purchased X credits." Just dollars in, AI back on. Internal system maps dollars to AI capacity at ~4x markup over raw token costs. User never sees that math. |
| **Upgrade option** | Below the dollar buttons: "Or upgrade your plan for higher monthly limits." Links to plan upgrade flow. User is never FORCED to upgrade — buying more usage is always an option. |
| **Business/Enterprise** | Unlimited AI. No meter shown. Never restricted. |
| **Internal tracking** | Ops portal tracks AI cost per company, dollar top-up revenue, margin per customer. User never sees this. |
| **Model choice** | **Opus 4.6** for all user-facing AI features (Z Intelligence, Blueprint Analyzer, AI Scanner, trade tools). Sonnet 4.5 only for trivial background tasks (classification, routing). Anything the user sees or that generates revenue documents = Opus. No compromises. |
| **AI budget split** | 10-15% of subscription revenue = passive AI reserve (background Sonnet tasks: classification, auto-tagging, cron jobs). Remaining 85-90% = active AI budget for Opus 4.6 user-facing features. Buy-more at ~4x markup over raw token costs. |
| **Old system** | The `user_credits`, `credit_purchases`, `scan_logs` tables and `subscription-credits` EF from FM migration are DEPRECATED. Will be replaced during Phase E with tier-based usage tracking + dollar top-ups. RevenueCat IAP credit products (`zafto_credits_*`) are KILLED. |

**This replaces ALL previous credit/scan-count/package pricing models across all docs and code.**

---

## ARCHITECTURE

```
                          ZAFTO PLATFORM
    ┌────────────────────────────────────────────────────────┐
    │                      SUPABASE                           │
    │  PostgreSQL + Auth + Storage + Realtime + Edge Functions│
    │  RLS on every table. ~215 tables. 94 Edge Functions.   │
    ├────────────────────────────────────────────────────────┤
    │  Stripe   Claude API  Cloudflare  Sentry  RevenueCat  │
    │  SignalWire  SendGrid  Plaid  LiveKit  250+ Free APIs  │
    └──┬────┬────┬────┬────┬────┬────┬──────────────────────┘
       │    │    │    │    │    │    │
       ▼    ▼    ▼    ▼    ▼    ▼    ▼
    ┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐
    │Mobile││ Web  ││Team  ││Client││ Ops  ││Realtor││Adjust│
    │ App  ││ CRM  ││Portal││Portal││Portal││Portal ││Portal│
    │Flutter││Next.js││Next.js││Next.js││Next.js││Next.js││(Free)│
    │Field ││Office││Field ││Home  ││Found.││Agent ││Claims│
    └──────┘└──────┘└──────┘└──────┘└──────┘└──────┘└──────┘
       │
    ┌──────┐
    │Power │  Offline-first (SQLite <-> PostgreSQL)
    │Sync  │
    └──────┘
```

**URLs:**
- `zafto.app` — Marketing landing page
- `zafto.cloud` — Contractor CRM (owner, admin, office manager)
- `team.zafto.cloud` — Employee Field Portal (techs, apprentices, field crews)
- `client.zafto.cloud` — Client/Homeowner Portal (free + $49.99/mo premium)
- `ops.zafto.cloud` — Founder OS (internal, super_admin)
- `realtor.zafto.cloud` — Realtor Portal (Phase RE, ~85-100 routes)
- Adjuster Portal — Public share links + free dashboard (Phase ECO, no dedicated subdomain needed)

---

## CURRENT STATE (February 19, 2026 — Session 138)

| What | Built | Wired | End-to-End |
|------|:-----:|:-----:|:----------:|
| Mobile App (R1 remake — 33 role screens) | YES | YES | YES (Supabase) |
| Mobile Field Tools (19 total) | YES | YES (B2+B3) | YES (all 19 wired) |
| Web CRM (~150 routes, 79+ hooks) | YES | YES | YES (Supabase) |
| Client Portal (45 routes, 21+ hooks) | YES | YES | YES (Supabase) |
| Employee Field Portal (43 routes, 22+ hooks) | YES | YES | YES (Supabase) |
| Ops Portal (30 routes) | YES | YES | YES (Supabase) |
| Database (Supabase) | ~215 tables | RLS + audit on all | 115 migrations |
| Edge Functions | 94 directories | All wired | Needs ANTHROPIC_API_KEY for AI |
| RBAC | Enforced | Middleware on all portals | RLS per table |
| Ledger (QB replacement) | YES | YES (13 hooks, 13 pages, 5 EFs) | YES |
| Property Management | YES | YES (11 hooks, 14 pages, 10 Flutter screens) | YES (D5, S71-S77, 18 tables) |
| Insurance/Restoration | YES | YES (7 tables, all 5 apps) | YES |
| D8 Estimates | YES | YES (D8a-D8j, 10 tables, 5 EFs) | DONE (S85-S89) |
| Phase F Platform (F1-F10) | YES (code) | YES (hooks+pages) | ALL CODE COMPLETE (S90) |
| Phase T: Programs | COMPLETE | YES | S104: T1-T10 done |
| Phase P: Recon | COMPLETE | YES | S105: P1-P10 done |
| Phase SK: Sketch Engine | COMPLETE | YES | S109: SK1-SK14 done |
| Phase GC: Schedule | COMPLETE | YES | S110: GC1-GC11 done |
| Phase U: Unification | COMPLETE | YES | S111-S114: U1-U23 done |
| Phase W: Warranty | COMPLETE | YES | S113: W1 done. **S144: W1-W8 fully spec'd (~56h enterprise checklists, 8 audit fixes)** |
| Phase J: Job Intelligence | COMPLETE | YES | S113: J1-J2 done. **S144: J1-J6 fully spec'd (~64h enterprise checklists)** |
| Phase L: Legal/Permits | COMPLETE | YES | S113: L1-L9 done. **S144: L1-L9+GC-WX1-3 fully spec'd (~176h enterprise checklists, 7 audit fixes)** |
| Phase INS: Inspector | COMPLETE | YES | S121-S124: INS1-INS10 done (~66h) |
| Phase G: QA/Hardening | IN PROGRESS | PARTIAL | G1-G5 automated DONE, G6-G10 manual QA PENDING |
| SEC: Security Hardening | PARTIAL | YES | SEC1+SEC6-8 DONE (S131). SEC2-5+SEC9-10 PENDING |
| FIELD: Field Infrastructure | COMPLETE | YES | FIELD1-5 ALL DONE (S131). Messaging, equipment, laser meter, BYOC phone |
| REST: Restoration Depth | COMPLETE | YES | REST1+REST2 DONE (S131). Fire + mold |
| NICHE: Niche Trades | COMPLETE | YES | NICHE1+NICHE2 DONE (S131). Pest control + service trades |
| DEPTH: Feature Depth Audit | IN PROGRESS | PARTIAL | DEPTH1 DONE (S131). DEPTH2-44 PENDING (~38 sprints) |
| LAUNCH: Launch Prep | PARTIAL | PARTIAL | LAUNCH1+LAUNCH9 DONE. LAUNCH2-8 PENDING |
| **Phase E AI (PREMATURE)** | **Code exists** | **PAUSED** | **NOT TESTED — AI goes LAST** |
| **Phase JUR: Jurisdiction** | PLANNED | NO | JUR1-JUR4 (~54-64h). Pre-AI |
| **Phase RE: Realtor Platform** | **FULLY SPEC'D (S129+S144)** | NO | RE1-RE30, ~894h, 30 sprints. RE1-RE20 fully spec'd with enterprise checklists (594h, S144). RE21-RE30 spec'd (300h, S132). 6th portal |
| **Phase INTEG: Integration** | SPEC'D (S132) | NO | INTEG1-8, ~312h. Ecosystem wiring |
| **Phase FLIP: Flip-It Engine** | SPEC'D (S127-S128) | NO | FLIP1-6, ~112h. Investment property |
| **Phase MOV: Moving Company** | SPEC'D (S131) | NO | MOV1-8, ~80h. Full moving trade |
| **Phase CLIENT: Homeowner** | SPEC'D (S132) | NO | CLIENT1-17, ~378h. Free + $49.99/mo premium |
| **Phase CUST: Customization** | SPEC'D (S132) | NO | CUST1-8, ~190h. Enterprise customization |
| **Phase ECO: Ecosystem** | SPEC'D (S133) | NO | ECO3+ECO4+ECO7+ECO8, ~48h. Adjuster portal + pricing |
| **Phase VIZ: 3D Visualization** | RESEARCHED (S132) | NO | VIZ1, ~40h. 3D Gaussian Splatting engine |
| **ZFORGE-FRESH: Doc Freshness** | SPEC'D (S144) | NO | ZFORGE-FRESH1-5, ~26h. Template versioning, staleness CRON, regulatory monitoring, ops alerts |
| **SHARED: Cross-App Packages** | SPEC'D (S144) | NO | SHARED-PKG1-3+RECON-MOBILE1-3+SKETCH1-2, ~62h. Shared Recon/Sketch Flutter packages, entity configs |
| **ZFORGE: Document Engine** | RESEARCHED (S144) | NO | ZFORGE1-10, ~388h. 354 document types, pdfme WYSIWYG, e-signatures, 50-state lien waivers |
| **Contractor Spec Expansion** | **COMPLETE (S144)** | N/A | ~70 stubs → enterprise specs. W+J+L+GC-WX+U-subsystems+U-TT+P-DT+ROUTE+CHEM+DRAW+SEL. +9,758 lines |
| **Plan Review (AI)** | SPEC'D (S97) | NO | Phase E feature (BA1-BA8, ~128 hrs) |

**SUMMARY: ALL PHASES A-F + T + P + SK + GC + U + W + J + L + INS COMPLETE.** Phase G automated DONE (G1-G5), manual QA pending (G6-G10). SEC1+SEC6-8 DONE. FIELD1-5 DONE. REST1+REST2 DONE. NICHE1+NICHE2 DONE. DEPTH1 DONE. LAUNCH1+LAUNCH9 DONE. S132: Research + ecosystem audit (INTEG2-8 added). S133: Pricing update + adjuster portal deep research. **~215 tables. 114 migrations. 94 EFs. ~150 CRM routes. 43 team routes. 45 client routes. 30 ops routes. ~160+ sprints total (~3,000h listed, ~3,300h realistic). Next: DEPTH2-39 → DEPTH40-nonAI → DEPTH41-43 → INTEG2-4+INTEG6-8 → RE1-20 → INTEG1 → FLIP1-4 → INTEG5 → SEC2-5 → LAUNCH2-6 → LAUNCH8 → G → JUR → E (AI LAST) → FLIP5+DEPTH40-AI+DEPTH44 → SEC9-10 → ZERO1-9 → LAUNCH7 → SHIP.**

---

## NO-DRIFT BUILD ORDER

### PHASE A: FOUNDATION (Before any features)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| A1 | Code cleanup | ~4-8 | Remove dead code, Firebase refs, unused imports, stale files |
| A2 | DevOps Phase 1 | ~2 | Configure Supabase dev+prod env vars, secrets in Vault, Dependabot |
| A3 | Database Migration | ~17-25 | Deploy schema, RLS policies, audit triggers, auth config, storage buckets |
| A4 | PowerSync Setup | ~2-3 | Offline sync between SQLite and PostgreSQL |

### PHASE B: CORE WIRING (Make what exists actually work)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| B1 | Wire W1: Core Business | ~23 | Jobs, Bids, Invoices, Customers, Time Clock, Auth, RBAC → Supabase |
| B2 | Wire W2: Field Tools | ~26 | 14 tools: capture → PowerSync offline → Supabase + Storage |
| B3 | Wire W3: Missing Tools | ~22 | Materials Tracker, Daily Log, Punch List, Change Orders, Job Completion |
| B4 | Wire W4: Web CRM + Polish | ~30-36 | 40 pages read real Supabase data, field data flows to CRM. B4d: UI polish (collapsible sidebar, visual restraint, chart upgrade, Supabase-level professionalism). B4e: Z Intelligence chat panel + artifact system UI shell. |
| B5 | Wire W5: Employee Field Portal | ~20-25 | team.zafto.cloud — jobs, schedule, time clock, field tools, materials, change orders, AI troubleshooting. Permission-gated by owner. No sensitive financials. |
| B6 | Wire W6: Client Portal | ~13 | 21 pages read real data, Equipment Passport, Live Tracker |
| B7 | Wire W7: Polish | ~19 | Screen registry, Cmd+K for business, notifications, offline sync |

### PHASE C: LAUNCH PREP

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| C1 | DevOps Phase 2 | ~8-12 | Sentry wiring, automated tests, CI/CD pipeline, RLS tests |
| C2 | Debug & QA | ~20-30 | Test with real data across all 90 screens |
| C3 | Ops Portal Phase 1 | ~40 | Command center, inbox, accounts, support, health, revenue (18 pages) |
| C4 | Security Hardening | ~4 | Email migration, Bitwarden changeover, 2FA, ProtonMail, YubiKeys |
| C5 | Incident Response Plan | ~2-3 | Document: severity levels, breach response, key rotation, rollback |

### PHASE D: REVENUE ENGINE

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| D1 | Job Type System | ~69 | Standard + insurance_claim + warranty_dispatch. Progressive disclosure. |
| D2 | Restoration/Insurance Module | ~78 | 9th trade, Xactimate/ESX, carrier mgmt, moisture/drying logs |
| D3 | Insurance Verticals | ~107 | Storm, reconstruction, commercial, warranty network (JSONB, no new tables) |
| D4 | Ledger (QB replacement) | TBD | Full accounting: chart of accounts, receipt scan, P&L, bank sync (Plaid), CPA portal |
| D5 | Property Management System | TBD | NEW — Contractor-owned properties. Tenant mgmt, leases, rent, maintenance loop. THE MOAT. |
| D6 | Enterprise Foundation | ~20 | Multi-location, custom roles, form templates, API keys, certifications |
| D7 | Certification System | ~12 | Modular cert types, immutable audit log, dynamic type registry |
| D8 | Estimates | ~100+ | Two-mode: Regular Bids (all contractors, PDF) + Insurance Estimates (ESX). Own code DB, crowdsource, regional pricing. See `07_SPRINT_SPECS.md (D8a-D8j)` |

### PHASE E: AI LAYER — MOVED TO AFTER PHASE U + G (AI GOES TRULY LAST)

**STATUS: PAUSED.** Some E work was built prematurely in S78-S80 (Edge Functions, hooks, UI). Code committed but DORMANT. AI must be built LAST after every platform feature exists so it can know and control the entire system. Deep AI spec session required before resuming.

**Premature E work (exists in codebase, dormant):**
- E1-E2: z-intelligence Edge Function (14 tools), Dashboard wired, z_threads/z_messages tables
- E3: 4 troubleshooting Edge Functions, team portal troubleshoot page, Flutter AI chat, client portal widget
- E4: 5 growth advisor Edge Functions, 4 CRM pages (not deployed)
- E5: Xactimate estimate engine (5 tables, 6 Edge Functions, UI across all apps) — **SUPERSEDED by D8 (clean-room estimate engine). E5 code dormant. D8 uses independent spec: `07_SPRINT_SPECS.md (D8a-D8j)`**
- E6: Bid walkthrough engine (5 tables, 4 Edge Functions, 12 Flutter screens)

**When we return to Phase E (after T+P+SK+U+G):**

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| E1 | Universal AI Architecture | ~300-400 | 6-layer AI: Identity, Knowledge, Memory, Session, Compounding, RBAC. Must understand EVERY feature. Deep spec session first. |
| E2 | Dashboard + Artifacts | ~90-120 | 3-state persistent AI console. Template-based artifacts. Human approval required. |
| E3 | Dashboard | ~100-150 | Lead inbox, pipeline, service catalog, showcases, reviews |
| E4 | Growth Advisor | ~88 | AI revenue expansion engine. Curated opportunity KB. |
| E-review | Audit premature E work | TBD | Review/rebuild all S78-S80 AI code with full platform context. Ensure AI knows every F-phase feature. |

### PRE-F: FOUNDATION FOR PLATFORM

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| D8 | Estimates | ~100+ | Two-mode (Regular Bids + Insurance ESX). Own code DB, crowdsource, regional pricing. Clean-room. See `07_SPRINT_SPECS.md` D8a-D8j. |
| FM | Firebase→Supabase Migration | ~8-12 | Migrate 11 Cloud Functions (Stripe payments, RevenueCat, AI scans) from `backend/functions/` to Supabase Edge Functions. |
| R1j | Mobile Backend Rewire | ~8-12 | Connect R1's 33 new screens to existing Phase B wired data (jobs, invoices, customers, field tools). |

### PHASE F: PLATFORM COMPLETION

**Build order: F1→F3→F4→F5→F6→F7→F9→F10. Then T (Programs), then P (Recon), then SK (Sketch Engine), then U (Unification & Feature Completion), then G (QA/Harden everything), then E → LAUNCH. F2+F8 post-launch.**

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| F1 | Calls (SignalWire) | ~40-55 | Business phone, AI receptionist, SMS, **fax send/receive**, call recording, E2E encryption. SignalWire SWML AI agent framework. |
| F3 | Meetings (LiveKit) | ~70 | Context-aware video (knows job/estimate/customer), 6 meeting types, freeze-frame annotate, AI transcription, booking, async video. |
| F4 | Mobile Field Toolkit + Sketch/Bid | ~120-140 | 24 tools (walkie-talkie/PTT, restoration, inspections). **Sketch + Bid Flow** (room photos → dimensions → AI code suggestion → price book → bid PDF/ESX). **OSHA API** (free — safety standards, compliance auto-populate). R1c/R1e deferred items. |
| F5 | Integrations + Lead Aggregation | ~180+ | 9 systems (CPA Portal, Payroll, Fleet, Route, Procurement, HR, Email, Phone, Docs). **Lead API aggregation** (Google Business Profile, Google LSA, Meta/Facebook, Nextdoor, Yelp, BuildZoom — all free). Single inbox for all lead sources. |
| F6 | Marketplace | ~80-120 | Equipment AI diagnostics, pre-qualified lead gen, contractor bidding. Camera scan → AI model identification → contractor match. |
| F7 | Home Portal | ~140-180 | Homeowner property intelligence. Free: equipment passport, service history, docs. Premium ($7.99/mo): AI advisor, predictive maintenance, contractor matching. R1f deferred items. |
| F9 | Hiring System | ~18-22 | Multi-channel (Indeed/LinkedIn/ZipRecruiter), applicant pipeline, Checkr background checks, E-Verify (free), onboarding integration. |
| F10 | ZForge | TBD | PDF-first document suite. Templates for all trade documents. E-signatures (DocuSign). SECOND TO LAST. |

### PHASE G: DEBUG, QA & HARDENING — G1-G5 AUTOMATED DONE (S113), G6-G10 MANUAL QA PENDING

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| G1-G5 | Automated QA (lint, type check, RLS, migration, build) | ~40 | **DONE** (S113). G10 done (S114-S115). |
| G6 | Manual cross-feature testing | ~30 | Every screen, every edge case, every role, real data. |
| G7 | Security audit | ~20 | Pen testing, RLS verification, credential rotation. |
| G8 | Performance optimization | ~20 | Load testing, query optimization, caching. |
| G9 | Cross-app integration testing | ~20 | Verify all 5 apps work together seamlessly. |
| G10 | UI/UX polish pass | ~10 | **DONE** (S114-S115). Fixed 10 migrations, RLS fix, UI overhaul. |

### PHASE T: TPA PROGRAM MANAGEMENT MODULE — COMPLETE (S104)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| T1 | TPA Foundation | ~8 | Core tables (tpa_programs, tpa_assignments, tpa_scorecards), feature flag, CRM settings. |
| T2 | Assignment Tracking | ~12 | Assignment lifecycle, SLA countdown, supplement/doc requirement tables. |
| T3 | Water Damage Assessment + Moisture | ~12 | IICRC S500 classifications, moisture mapping, psychrometric monitoring. |
| T4 | Equipment Deployment + Calculator | ~10 | IICRC equipment formulas, billing clock, deployment tracking. |
| T5 | Documentation Validation | ~8 | Completeness checking, COC generation, configurable checklists per TPA. |
| T6 | Financial Analytics | ~8 | Per-TPA profitability, referral fee tracking, AR aging, margin analysis. |
| T7 | Supplement Workflow + Scorecard | ~8 | Supplement S1/S2/S3 tracking, TPA performance scoring over time. |
| T8 | Restoration Line Items + Export | ~10 | ZAFTO line item DB with Xactimate mapping, FML/DXF/PDF export. |
| T9 | Portal Integration | ~8 | Team portal (SLA badges, equipment), ops portal (TPA analytics), CRM sidebar. |
| T10 | Polish + Build Verification | ~4 | Feature flag toggle test, IICRC formula verification, legal disclaimers. |

*Full spec: `Expansion/39_TPA_MODULE_SPEC.md` | Legal: `memory/tpa-legal-assessment.md`*

### PHASE P: PROPERTY INTELLIGENCE ENGINE (Recon) — COMPLETE (S105)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| P1 | Foundation + Google Solar + Confidence Engine | ~12 | Core tables (property_scans, roof_measurements, roof_facets), Google Solar API, confidence scoring, imagery date transparency, CRM card. |
| P2 | Property Data + Parcel + Multi-Structure | ~10 | ATTOM + Regrid + Microsoft footprints + USGS elevation + multi-structure detection. Full property report with structure selector. |
| P3 | Walls + Trade Data | ~10 | Wall derivation, 10 trade pipelines (roofing/siding/gutters/solar/painting/landscaping/fencing/concrete/HVAC/electrical). Per-structure measurements. |
| P4 | Estimate Integration + Supplement Checklist | ~10 | Recon → D8 estimate engine. Auto-populate estimates. Insurance supplement checklist (auto-detect missed items: starter, ridge cap, drip edge, I&W, flashing, pipe boots, O&P). TPA integration. |
| P5 | Lead Scoring + Batch Area Scanning | ~10 | Lead pre-qualification (0-100 score, Hot/Warm/Cold). Batch area scan (draw polygon → scan all parcels → ranked lead list). CSV export. |
| P6 | Material Ordering | ~8 | Measurements → material list → Unwrangle/ABC Supply pricing → one-click order. |
| P7 | Mobile + Verification | ~10 | Mobile scan screen, swipeable results, on-site verification workflow, lead score display. |
| P8 | Portal Integration | ~8 | Team/Client/CRM/Ops portal integration. Recon sidebar section. Analytics. |
| P9 | Storm Assessment + Area Intelligence | ~10 | NOAA weather data, damage probability model, storm heat maps, canvass optimization, TPA claim pipeline. |
| P10 | Polish + Build + Accuracy Benchmarking | ~8 | Caching, rate limiting, attribution, disclaimers, accuracy benchmarking (20+ properties), clean builds. |

*Full spec: `Expansion/40_PROPERTY_INTELLIGENCE_SPEC.md` | API research: `memory/property-intelligence-research.md`*

### PHASE SK: CAD-GRADE SKETCH ENGINE — COMPLETE (S109)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| SK1 | Unified Data Model + Migration | ~16 | Merge property_floor_plans + bid_sketches. FloorPlanDataV2 schema. 3 new tables + 2 ALTER. |
| SK2 | Flutter Editor Upgrades Part 1 | ~16 | Wall editing after draw, thickness control, fixture rotation, imperial/metric toggle. |
| SK3 | Flutter Editor Upgrades Part 2 | ~12 | Arc walls, copy/paste, multi-select lasso, smart auto-dimensions. |
| SK4 | Trade Layers System | ~20 | Electrical (15), plumbing (12), HVAC (10), damage (4). Layer panel + per-trade toolbars. |
| SK5 | LiDAR Scanning (Apple RoomPlan) | ~20 | Swift platform channel, 3D→2D converter, guided scan UX, non-LiDAR fallback. |
| SK6 | Web CRM Canvas Editor (Konva.js) | ~24 | TypeScript port of geometry engine. Full canvas editor replacing sketch-bid form. |
| SK7 | Sync Pipeline | ~12 | Hive offline-first, Supabase real-time, thumbnail generation, conflict resolution. |
| SK8 | Auto-Estimate Pipeline | ~16 | Geometry→measurements→estimate areas→D8 line items. "Generate Estimate" button. |
| SK9 | Export Pipeline | ~12 | PDF (title block + plan + schedule), PNG (hi-res), DXF (AutoCAD), FML (open format). |
| SK10 | 3D Visualization (three.js) | ~16 | Wall extrusion, door/window openings, orbit controls, 2D/3D toggle. Web CRM only. |
| SK11 | Polish + Testing + Button Audit | ~12 | Round-trip tests, performance (60fps web, 30fps mobile), every-button audit. |

*Full spec: `Expansion/46_SKETCH_ENGINE_SPEC.md`*

### PHASE U: UNIFICATION & FEATURE COMPLETION — COMPLETE (S111-S114)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| U1 | Portal Unification | ~16 | Merge team+client portals into web-portal at zafto.cloud. Single codebase, role-based routing. |
| U2 | Nav Redesign | ~14 | Supabase-style sidebar across all portals. Z button rethink. |
| U3 | Permission Engine + Enterprise Customization | ~16 | Granular permission system. Enterprise feature toggles. |
| U4 | Ledger Completion | ~14 | Complete Ledger to replace QuickBooks. Bank sync, reconciliation, full GL. |
| U5 | Dashboard Restoration + Reports | ~12 | Live data dashboards replacing mock data. Real-time reports. |
| U6 | PDF Generation + Email Sending + Dead Buttons | ~14 | Invoice/bid/estimate PDF generation. SendGrid email delivery. Wire remaining dead buttons. |
| U7 | Payment Flow + Shell Pages | ~12 | Stripe payment flow completion. Fill remaining shell pages with real functionality. |
| U8 | Cross-System Metric Verification | ~10 | Verify data flows correctly across all 5 apps. Metric consistency checks. |
| U9 | Polish + Missing Features | ~12 | Final polish pass. Fill any remaining gaps before QA phase. |

### PHASE W: WARRANTY INTELLIGENCE (after U) — COMPLETE (S113)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| W1 | Warranty Intelligence Engine | ~12 | Warranty tracking, predictive maintenance, hooks + pages across 4 portals. |

### PHASE J: JOB INTELLIGENCE (after W) — COMPLETE (S113)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| J1 | Smart Pricing Engine | ~10 | AI-powered pricing suggestions based on job history, market data. |
| J2 | Job Analytics Dashboard | ~8 | Profitability analysis, job completion metrics, trend tracking. |

### PHASE L: LEGAL/PERMITS (after J) — COMPLETE (S113)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| L1-L9 | Permit Intelligence + Compliance | ~40 | Permit tracking, jurisdiction rules, compliance monitoring, lien management, CE tracker. 5 migrations. |

### PHASE INS: INSPECTOR DEEP BUILDOUT — COMPLETE (S121-S124)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| INS1-INS10 | Full Inspector Platform | ~66 | 19 inspection types + Quick Checklist, 25 templates (1,147 items, 173 sections), weighted scoring, deficiency tracking with photos, PDF reports, GPS capture, reinspection diffs, code reference (61 NEC/IBC/IRC/OSHA/NFPA sections), compliance calendar, permit tracker, CRM hooks, ops metrics, Hive offline safety net. |

### PHASE SEC: SECURITY HARDENING (~100h total)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| SEC1 | Storage + Rate Limiter + EF Auth | ~12 | **DONE (S131).** Bucket RLS, persistent rate limiter, EF auth hardening. |
| SEC2 | Input Validation + XSS | ~12 | Sanitize all user inputs, CSP headers, output encoding. |
| SEC3 | API Security | ~12 | Rate limiting per endpoint, request signing, CORS lockdown. |
| SEC4 | Data Encryption | ~10 | Encrypt PII at rest, key rotation, company encryption keys. |
| SEC5 | Penetration Testing | ~14 | OWASP top 10 audit, SQL injection testing, auth bypass attempts. |
| SEC6-8 | EF Auth + CORS + Validation | ~12 | **DONE (S131).** Edge Function auth, CORS, request validation. |
| SEC9 | Audit + Compliance | ~36 | SOC2 prep, audit trail verification, compliance reporting. |
| SEC10 | Legal Labeling | ~12 | Owner's legal analysis document standards integrated. |

### PHASE FIELD: FIELD INFRASTRUCTURE (~50h total) — ALL COMPLETE (S131)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| FIELD1 | Real-Time Messaging | ~12 | **DONE.** Conversations + messages + members tables, Flutter 3 screens, CRM team-chat, team portal. |
| FIELD2 | Equipment Checkout | ~10 | **DONE.** Equipment items + checkouts, RLS, 4 Flutter screens, CRM + team portal pages. |
| FIELD3 | Receipt Scanner Depth | ~8 | **DONE.** Enhanced receipt scanning with OCR. |
| FIELD4 | Laser Meter Integration | ~10 | **DONE.** Bug reporting, device integration. |
| FIELD5 | BYOC Phone | ~10 | **DONE.** Company phone numbers, bring-your-own-carrier support. |

### PHASE REST: RESTORATION DEPTH (~28h total) — ALL COMPLETE (S131)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| REST1 | Fire Restoration | ~16 | **DONE.** 6 tables (fire assessments, damage areas, structural, smoke/odor, contents cleaning, line items). All portals. |
| REST2 | Mold Remediation | ~12 | **DONE.** 4 tables (mold assessments, samples, state regs, labs). IICRC S520 compliance. |

### PHASE NICHE: NICHE TRADES (~20h total) — ALL COMPLETE (S131)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| NICHE1 | Pest Control | ~12 | **DONE.** 3 tables, 1 EF, 4 screens, treatment logs, bait stations, WDI reports. |
| NICHE2 | Service Trades | ~8 | **DONE.** 3 tables (locksmith, garage door, appliance service logs), diagnostic flows, 36 seed items. |

### PHASE DEPTH: FEATURE DEPTH AUDIT (~800h total, 44 sprints)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| DEPTH1 | Core Business Depth | ~16 | **DONE (S131).** Invoice fields, voice notes, receipt fixes. |
| DEPTH2-13 | Field Tools Depth | ~180 | Photo system, voice notes, mileage, LOTO, incident, safety, level/plumb, confined space, signatures, receipt scanner, materials tracker, daily log. |
| DEPTH14 | Punch List / Task Engine | ~28 | Dependencies, due dates, templates, approval workflows, photos per item. |
| DEPTH15-24 | Business Feature Depth | ~200 | Customers, jobs, calendar, time clock, bids, invoices, accounting, price book, change orders, documents. |
| DEPTH25 | Commercial Building Module | ~36 | 1,400+ commercial elements, 16 building types, multi-floor. |
| DEPTH26 | Blueprint/CAD Enhancement | ~20 | Enhanced blueprint reading, layer management. |
| DEPTH27 | Walkthrough Depth | ~14 | Photo annotation, checklists, templates per trade. |
| DEPTH28 | Recon Mega Enhancement | ~36 | Roof data display fix, accuracy improvements, new data sources. |
| DEPTH29 | Estimate Overhaul | ~28 | Labor hours by trade, G/B/B analysis, template library. |
| DEPTH30 | Recon-to-Estimate Pipeline | ~20 | Auto-populate estimates from recon data, supplement auto-detect. |
| DEPTH31-32 | Material/Supplier Depth | ~24 | Supplier pricing, material waste factors, order management. |
| DEPTH33 | Home Warranty Module | ~20 | Warranty dispatch, claim workflow, service agreements. |
| DEPTH34 | Property Preservation | ~52 | 25+ work order types, winterization, debris estimation, national company profiles, chargeback tracking. |
| DEPTH35 | Mold Remediation Depth | ~28 | IICRC S520 levels, containment checklists, clearance certificates, state licensing DB. |
| DEPTH36 | Disposal/Dump Finder | ~8 | Waste type pricing, scrap values, route optimization. |
| DEPTH37-39 | Tablet Responsive + Time Clock + Signatures | ~40 | Mobile/tablet responsive overhaul, time clock permissions, DocuSign replacement. |
| DEPTH40 | Marketplace Aggregator | ~20 | Non-AI: data pipeline. AI portion: Phase E dependent. |
| DEPTH41-43 | Backup + Storage + Sketch Compat | ~72 | Triple redundancy backup, storage tiering, sketch file compatibility. |
| DEPTH44 | AI-Gated Features | ~16 | Phase E dependent. AI ticket system. |

### PHASE FLIP: FLIP-IT REALITY ENGINE (~112h, S127-S128)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| FLIP1 | Flip Foundation | ~16 | Deal analysis tables, property acquisition workflow. |
| FLIP2 | Renovation Scope Engine | ~20 | Auto-scope from recon data, cost estimation, timeline generation. |
| FLIP3 | Financial Modeling | ~16 | Full cost waterfall, exit strategy analysis, financing comparison. |
| FLIP4 | Deal Packaging | ~20 | Investor presentation PDFs, comps, market data. |
| FLIP5 | AI Deal Scoring | ~20 | Phase E dependent. AI-powered deal evaluation. |
| FLIP6 | Reality Engine | ~20 | True net P&L, tax impact calculator, over-improvement warning, market health indicators. |

### PHASE MOV: MOVING COMPANY (~80h, S131)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| MOV1-MOV8 | Full Moving Trade | ~80 | Inventory system, cubic ft estimation, truck load planning, move-day workflow, storage tracking, valuation/claims, crew management, estimate templates. |

### PHASE ZERO: ZERO-DAY TRADE FOUNDATION (~150h)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| ZERO1-ZERO9 | Trade Scaffold System | ~150 | Universal trade registration, calculator framework, certification engine, field tool mapping, estimate template system, scope-of-work generator, material list generator, code reference system, trade onboarding wizard. |

### PHASE LAUNCH: LAUNCH PREPARATION (~180h)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| LAUNCH1 | App Store Prep | ~12 | **DONE.** Screenshots, descriptions, metadata for iOS + Android. |
| LAUNCH2 | Marketing Website | ~16 | Landing page at zafto.app. Feature showcase, pricing, signup flow. |
| LAUNCH3 | Onboarding Flow | ~14 | First-run experience, company setup wizard, trade selection. |
| LAUNCH4 | Payment Integration | ~40 | Stripe subscription flow, plan selection, upgrade/downgrade, billing portal. |
| LAUNCH5 | Data Migration Tools | ~30 | Import from Jobber, HCP, ServiceTitan. CSV import, field mapping. |
| LAUNCH6 | Documentation | ~12 | Help center, API docs, video tutorials. |
| LAUNCH7 | App Store Submission | ~20 | Sign in with Apple, review compliance, certificate setup. |
| LAUNCH8 | Deployment Runbook | ~12 | Disaster recovery, rollback procedures, incident response playbook. |
| LAUNCH9 | Ops Portal Fortress | ~10 | **DONE.** IP whitelist, FIDO2 hardware key, Cloudflare Access zero-trust. |

### PHASE INTEG: ECOSYSTEM INTEGRATION (~312h, S127+S132)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| INTEG1 | National Portal Submission | ~12 | PP national company portal API integration. After FLIP. |
| INTEG2 | Engine Wiring | ~40 | Connect 10 business intelligence engines to real data streams. |
| INTEG3 | Client Portal Activation | ~36 | Wire CLIENT1-17 homeowner features to live data. |
| INTEG4 | Weather Engine | ~28 | NWS/NOAA/Open-Meteo auto-attached to jobs, recon, scheduling. |
| INTEG5 | Three-Sided Marketplace | ~48 | After RE+FLIP. Contractor↔Homeowner↔Realtor cross-referral engine. |
| INTEG6 | Marketplace Wiring | ~36 | Equipment marketplace, lead marketplace, subcontractor matching. |
| INTEG7 | Calculator Bridge | ~40 | Wire ~1,194 trade calculators to save-to-job + Supabase. |
| INTEG8 | Free API Enrichment | ~72 | 250+ free APIs ($0/mo) — BLS, Davis-Bacon, OSHA, NWS, FEMA, EPA, Census, NREL, etc. |

### PHASE RE: REALTOR PLATFORM (~744h, 30 sprints, S129+S132)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| RE1-RE20 | Core Realtor Platform | ~594 | **FULLY SPEC'D (S144).** 6th portal (realtor.zafto.cloud). ~100 new tables, ~70 EFs, ~80 Flutter screens, 5,823 lines. Smart CMA Engine, Autonomous Transaction Engine, Seller Finder Engine. Brokerage RBAC (8 roles). Commission engine. Dispatch with guest contractor flow. Listing lifecycle + open house. Buyer management + NAR compliance. Marketing factory. Cross-platform sharing. High-gloss near-black UI. Checklists: `07_SPRINT_SPECS.md` lines 13952-19773. |
| RE21-RE30 | Realtor Expansion (S132) | ~300 | Negotiation AI, agent departure prediction, rental analysis, HOA health, insurance estimation, power dialer, IDX websites, inspection AI, storm alerts. Spec: `memory/s132-realtor-10-gaps-spec.md` |

### PHASE CLIENT: HOMEOWNER PLATFORM (~378h, 17 sprints, S132)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| CLIENT1-CLIENT17 | Full Homeowner Platform | ~378 | Free tier (equipment passport, maintenance calendar, marketplace, project tracking). Premium $49.99/mo (3D scan, renovation viz, AI troubleshoot, rehab estimates, insurance tools, tax tools). ~75 tables. Three-sided marketplace participant. Spec: `memory/s132-homeowner-platform-research.md` |

### PHASE CUST: ENTERPRISE CUSTOMIZATION (~190h, 8 sprints, S132)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| CUST1-CUST8 | Enterprise Customization | ~190 | 14 realtor types, 7 brokerage models, 50-state regs, cascading JSONB settings, custom fields, automation engine, 100 customization points. Spec: `memory/s132-enterprise-customization-research.md` |

### PHASE ECO: ECOSYSTEM/MARKETPLACE (~48h, 4 sprints, S133)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| ECO3 | Adjuster Portal Foundation | ~16 | Adjuster user type, share tokens, public evidence viewer, email delivery. Trojan horse into insurance ecosystem. |
| ECO4 | Adjuster Communication | ~12 | Per-item approve/flag, supplement diff view, messaging thread, audit trail. |
| ECO7 | AI Budget Engine | ~12 | Usage tracking, tier thresholds, visual meter, buy-more flow, passive reserve allocation. |
| ECO8 | Pricing/Subscription Update | ~8 | Solo $69.99, Team $149.99, Business $249.99, Enterprise custom. Homeowner free + $49.99 premium. Adjuster free. |

### PHASE JUR: JURISDICTION AWARENESS (~54-64h, pre-AI)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| JUR1 | State Code Adoptions | ~14 | state_code_adoptions table + seed (50 states × 8 code families). |
| JUR2 | Weekly Adoption Scanner | ~12 | Automated code adoption update checking. |
| JUR3 | Full Feature Retrofit | ~14 | Retrofit jurisdiction awareness into all existing features. |
| JUR4 | Realtor Jurisdiction | ~14 | 50-state disclosures, agency rules, attorney states, commission regs, license reciprocity. |

### PHASE E: AI LAYER (REBUILD — after ALL non-AI phases + G + JUR complete)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| E-review | Audit all premature E work | ~8 | Deep spec session with owner. AI must know every feature, table, screen — ~215 tables, 94 EFs, 7 portals, every workflow. Rebuild with full platform context. |
| BA1-BA8 | Plan Review | ~128 | AI blueprint reading + automated takeoff. 6 tables, 3 EFs. Hybrid CV+LLM pipeline (MitUNet segmentation + YOLOv12 detection + Claude Opus). RunPod Serverless GPU. Spec: `Expansion/47_BLUEPRINT_ANALYZER_SPEC.md` |
| E1-E4 | Full AI implementation | TBD | Universal AI, Dashboard, Command Center, Growth Advisor. Every feature AI-enhanced. All Opus 4.6. |

### >>> LAUNCH <<<

### POST-LAUNCH FEATURES

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| F2 | Website Builder V2 | ~60-90 | **DEFERRED POST-LAUNCH (S94 owner directive).** Too much maintenance for solo dev (hosting, custom domains, WYSIWYG, SSL, SEO support). Revisit with real contractor feedback + AI layer. Consider white-label (Duda) or template-only approach. |
| F8 | Ops Portal Phases 2-4 | ~111 | Marketing engine, treasury, legal, dev terminal, analytics. 54 additional pages. Internal tool, doesn't affect product. |

---

## FEATURE INVENTORY — EVERY FEATURE ACCOUNTED FOR

### Mobile App Features
| Feature | Status | Phase |
|---------|--------|-------|
| Home Dashboard | **DONE** — R1 remake, role-based | B1 |
| Bids (list/detail/create) | **DONE** — Supabase wired | B1 |
| Jobs (list/detail/create) | **DONE** — Supabase wired | B1 |
| Invoices (list/detail/create) | **DONE** — Supabase wired | B1 |
| Customers (list/detail) | **DONE** — Supabase wired | B1 |
| Calendar | **DONE** — Supabase wired | B1 |
| Time Clock + GPS | **DONE** — Supabase wired | B1 |
| RBAC (role.dart models) | **DONE** — Enforced, 7 roles | B1 |
| Onboarding | **DONE** — Company creation wired | B1 |
| Command Palette (Cmd+K) | **DONE** — Business context wired | B6 |
| AI Chat | DONE (S80) — PAUSED (Phase E) | E1 |
| AI Scanner (5 functions) | DONE (S80) — PAUSED (Phase E) | E1 |
| Contract Analyzer | DONE (S80) — PAUSED (Phase E) | E1 |

### Field Tools (19) — ALL WIRED TO SUPABASE
| # | Tool | Status | Phase |
|---|------|--------|-------|
| 1 | Job Site Photos | **DONE** — Supabase + Storage | B2 |
| 2 | Before/After | **DONE** — Supabase + Storage | B2 |
| 3 | Defect Markup | **DONE** — Supabase + Storage | B2 |
| 4 | Voice Notes | **DONE** — Supabase + Storage | B2 |
| 5 | Mileage Tracker | **DONE** — Supabase wired | B2 |
| 6 | LOTO Logger | **DONE** — Supabase wired | B2 |
| 7 | Incident Report | **DONE** — Supabase wired | B2 |
| 8 | Safety Briefing | **DONE** — Supabase wired | B2 |
| 9 | Sun Position | **DONE** — Standalone utility | — |
| 10 | Level & Plumb | **DONE** — Supabase wired | B2 |
| 11 | Confined Space Timer | **DONE** — Supabase wired | B2 |
| 12 | Client Signature | **DONE** — Supabase + Storage | B2 |
| 13 | Receipt Scanner | **DONE** — Supabase + Storage | B2 |
| 14 | Materials/Equipment Tracker | **DONE** — Built from scratch | B3 |
| 15 | Daily Job Log | **DONE** — Built from scratch | B3 |
| 16 | Punch List / Task Checklist | **DONE** — Built from scratch | B3 |
| 17 | Change Order Capture | **DONE** — Built from scratch | B3 |
| 18 | Job Completion Workflow | **DONE** — Built from scratch | B3 |
| 19 | Field Tool Hub | **DONE** — All tools accessible | B2 |

### Web CRM (~150 routes, 79+ hooks) — ALL WIRED TO SUPABASE
| Group | Routes | Status | Phase |
|-------|:------:|--------|-------|
| Operations (Dashboard, Leads, Bids, Jobs, Change Orders, Invoices) | 12 | **DONE** | B4 |
| Scheduling (Calendar, Inspections, Permits, Time Clock) | 4 | **DONE** | B4 |
| Customers (List, Detail, Create, Comms, Agreements, Warranties) | 6 | **DONE** | B4 |
| Resources (Team, Equipment, Inventory, Vendors, Purchase Orders) | 5 | **DONE** | B4 |
| Office (Ledger, Price Book, Documents, Reports, Automations, ZForge) | 6+ | **DONE** | B4/D4/F10 |
| Insurance/Claims | 4+ | **DONE** | D2/D3 |
| Certifications | 2+ | **DONE** | D7 |
| Property Management | 14 | **DONE** | D5 |
| Estimates | 5+ | **DONE** | D8 |
| Walkthroughs | 3+ | **DONE** | E6 |
| F-phase (Phone, Meetings, Toolkit, Integrations, Marketplace, Hiring) | 30+ | **DONE** | F1-F10 |
| Z Intelligence (AI panels) | 6 | DONE — PAUSED (Phase E) | E1 |
| Settings + Auth | 2 | **DONE** | B4 |

### Client Portal (45 routes, 21+ hooks) — ALL WIRED TO SUPABASE
| Tab | Routes | Status | Phase |
|-----|:------:|--------|-------|
| Auth + Home | 2 | **DONE** — Magic link auth | B6 |
| Projects (List, Detail, Estimate, Agreement, Live Tracker) | 5 | **DONE** | B6 |
| Payments (Invoices, Detail, History, Methods) | 4 | **DONE** | B6 |
| My Home (Profile, Equipment, Service History, Maintenance) | 4+ | **DONE** | B6/F7 |
| Menu (Messages, Documents, Request, Referrals, Review, Settings) | 6 | **DONE** | B6 |
| F-phase (SMS, Meetings, Booking, Home Portal, Get Quotes, Find a Pro) | 8+ | **DONE** | F1/F3/F7 |
| Walkthroughs + Estimates | 3+ | **DONE** | E6/D8 |

### Employee Field Portal (team.zafto.cloud) — 43 ROUTES, ALL WIRED
| Group | Routes | Status | Phase |
|-------|:------:|--------|-------|
| Auth + Dashboard (login, home, schedule view) | 3 | **DONE** | B5 |
| Jobs (assigned jobs, job detail, time clock, GPS check-in) | 4 | **DONE** | B5 |
| Field Tools (photos, voice notes, signatures, receipts, level — web versions) | 5 | **DONE** | B5 |
| Documents (change orders, daily logs, punch lists, materials log) | 4 | **DONE** | B5 |
| AI Troubleshooting Center | 3 | DONE — PAUSED (Phase E) | E1 |
| Collaboration (meetings, team chat, notifications) | 3 | **DONE** | B5/F3 |
| F-phase (Phone, Pay Stubs, My Vehicle, Training, My Documents) | 5+ | **DONE** | F1/F5 |
| Bids (field bid creation, estimate builder) | 2 | **DONE** | B5 |
| Settings (profile, preferences, notification settings) | 1 | **DONE** | B5 |

### Ops Portal (30 routes Phase 1 DONE, 54 routes Phases 2-4 POST-LAUNCH)
| Section | Routes | Status | Phase |
|---------|:------:|--------|-------|
| Command Center, Inbox, Accounts, Support, Health, Revenue, Services, AI | 18 | **DONE** | C3 |
| Phone/Meeting Analytics, Payroll, Fleet, Hiring, Email, Marketplace analytics | 8 | **DONE** | F1-F9 |
| Marketing Engine, Growth CRM, Treasury, AI Sandbox | 23 | POST-LAUNCH | F8 |
| Legal, Dev Terminal, Ads, SEO, Vault, Referrals, Analytics | 23 | POST-LAUNCH | F8 |
| Marketplace Ops | 8 | POST-LAUNCH | F8 |

### Expansion Features — EVERY ONE ACCOUNTED FOR

#### COMPLETED PHASES
| Feature | Hours | Status | Phase |
|---------|:-----:|--------|-------|
| Job Type System (3 types) | ~69 | **DONE** (S62) | D1 |
| Restoration/Insurance Module | ~78 | **DONE** (S63-64,68) | D2 |
| Insurance Verticals (4) | ~107 | **DONE** (S69) | D3 |
| Ledger (full accounting) | ~80+ | **DONE** (S70) | D4 |
| Property Management System | ~80+ | **DONE** (S71-S77, 18 tables) | D5 |
| Enterprise Foundation | ~20 | **DONE** (S65-66) | D6 |
| Certification System | ~12 | **DONE** (S67-68) | D7 |
| Estimates (Two-Mode) | ~100+ | **DONE** (S85-S89, 10 tables, 5 EFs) | D8 |
| Calls (SignalWire VoIP/SMS/Fax) | ~40-55 | **DONE** (S90) | F1 |
| Meetings | ~55-70 | **DONE** (S90) | F3 |
| Mobile Field Toolkit | ~89-107 | **DONE** (S90) | F4 |
| Integrations (9 systems) | ~180+ | **DONE** (S90) | F5 |
| Marketplace | ~80-120 | **DONE** (S90) | F6 |
| Home Portal | ~140-180 | **DONE** (S90) | F7 |
| Hiring System | ~18-22 | **DONE** (S90) | F9 |
| ZForge (PDF-first) | TBD | **DONE** (S90) | F10 |
| Programs Module | ~80 | **DONE** (S104) | T |
| Recon / Property Intelligence | ~96 | **DONE** (S105) | P |
| CAD-Grade Sketch Engine | ~240 | **DONE** (S109, SK1-SK14) | SK |
| Gantt & CPM Scheduling | ~124 | **DONE** (S110, GC1-GC11) | GC |
| Unification & Feature Completion | ~448 | **DONE** (S111-S114, U1-U23) | U |
| Warranty Intelligence | ~12 | **DONE** (S113) | W |
| Job Intelligence | ~18 | **DONE** (S113) | J |
| Legal/Permits | ~40 | **DONE** (S113, L1-L9) | L |
| Inspector Deep Buildout | ~66 | **DONE** (S121-S124, INS1-INS10) | INS |
| Security Hardening (partial) | ~24 | **DONE** (S131, SEC1+SEC6-8) | SEC |
| Field Infrastructure | ~50 | **DONE** (S131, FIELD1-5) | FIELD |
| Restoration Depth | ~28 | **DONE** (S131, REST1+REST2) | REST |
| Niche Trades | ~20 | **DONE** (S131, NICHE1+NICHE2) | NICHE |
| Feature Depth (partial) | ~16 | **DONE** (S131, DEPTH1) | DEPTH |
| Launch Prep (partial) | ~22 | **DONE** (LAUNCH1+LAUNCH9) | LAUNCH |

#### PENDING PHASES (Execution Order)
| Feature | Source | Hours | Status | Phase |
|---------|--------|:-----:|--------|-------|
| Feature Depth Audit (remaining) | 07_SPRINT_SPECS | ~784 | DEPTH2-44 NEXT | DEPTH |
| Ecosystem Integration | Expansion/52 + 07_SPRINT_SPECS | ~312 | SPEC'D (S127+S132) | INTEG |
| Realtor Platform | Expansion/53 + 07_SPRINT_SPECS | ~894 | **FULLY SPEC'D (S129+S132+S144)** | RE |
| Flip-It Reality Engine | 07_SPRINT_SPECS + memory | ~112 | SPEC'D (S127-S128) | FLIP |
| Moving Company Trade | 07_SPRINT_SPECS | ~80 | SPEC'D (S131) | MOV |
| Security Hardening (remaining) | 07_SPRINT_SPECS | ~76 | SEC2-5+SEC9-10 PENDING | SEC |
| Launch Preparation (remaining) | 07_SPRINT_SPECS | ~158 | LAUNCH2-8 PENDING | LAUNCH |
| Homeowner Platform | memory/s132-homeowner-platform | ~378 | SPEC'D (S132) | CLIENT |
| Enterprise Customization | memory/s132-enterprise-custom | ~190 | SPEC'D (S132) | CUST |
| Ecosystem/Marketplace | memory/ecosystem-pricing-spec | ~48 | SPEC'D (S133) | ECO |
| 3D Visualization Engine | memory/3d-visualization-research | ~40 | RESEARCHED (S132) | VIZ |
| Zero-Day Trade Foundation | 07_SPRINT_SPECS | ~150 | SPEC'D | ZERO |
| Jurisdiction Awareness | 07_SPRINT_SPECS | ~54-64 | PLANNED (S124+S129) | JUR |
| Phase G Manual QA | 07_SPRINT_SPECS | ~100 | G6-G10 PENDING | G |
| Plan Review (AI Takeoff) | Expansion/47 | ~128 | SPEC'D (S97) | E/BA |
| AI Layer (full rebuild) | Expansion/35+39+40+41 | TBD | PAUSED — AI LAST | E |

#### POST-LAUNCH
| Feature | Hours | Status | Phase |
|---------|:-----:|--------|-------|
| Website Builder V2 | ~60-90 | POST-LAUNCH (S94 directive) | F2 |
| Ops Portal Phases 2-4 | ~111 | POST-LAUNCH | F8 |

---

## EMPLOYEE FIELD PORTAL (team.zafto.cloud)

### What It Is
A full-powered web portal for field employees (technicians, apprentices, crew leads). Not a dumbed-down view — a purpose-built field operations suite. Everything a tech needs in the field, nothing they shouldn't see.

### Design Principles
- **Permission-gated by owner** — Owner/admin controls exactly what each role sees. Fully customizable per-employee.
- **No sensitive company data** — No P&L, no bank accounts, no revenue numbers, no payroll, no subscription billing. Financial data stays in the CRM.
- **AI-first troubleshooting** — State-of-the-art diagnostic center. Any trade, any problem. Photo-based diagnosis, code lookup, step-by-step guides, parts identification.
- **Field-optimized UI** — Big touch targets, works on phone browsers, fast load on cell data, dark mode for attics/crawl spaces.
- **Same Supabase backend** — RLS handles permission scoping. No separate database.

### Core Features (Phase B5)
| Feature | Description |
|---------|-------------|
| Dashboard | Today's jobs, schedule, weather, active time clock, team status |
| Job View | Assigned job details, customer info (name/address/phone only), job notes, status updates |
| Time Clock | Clock in/out with GPS, break tracking, daily hours summary |
| Field Tools (Web) | Photo capture, voice notes, digital signatures, receipt upload, level tool |
| Daily Log | Task-by-task documentation of work performed |
| Punch List | Checklist items per job, mark complete, add photos |
| Change Orders | Create/submit change orders from field, capture scope changes with photos + signatures |
| Materials Log | Log materials/equipment used per job, scan barcodes, track quantities |
| Bid Creation | Build estimates in the field, add line items, capture photos for scope |
| Meetings | Join team meetings, safety briefings, training sessions |
| Notifications | Push + in-app: new job assignments, schedule changes, messages from office |
| Profile/Settings | Personal info, notification preferences, theme, language |

### AI Troubleshooting Center (Phase E1)
| Feature | Description |
|---------|-------------|
| Multi-Trade Diagnostics | Describe a problem (text, voice, or photo) → AI walks through diagnosis step-by-step |
| Code Lookup | NEC, IPC, IMC, IRC, OSHA — instant code compliance checking by jurisdiction |
| Photo Diagnosis | Take a photo of a panel, pipe, unit → AI identifies components, issues, next steps |
| Parts Identification | Photo a part → AI identifies manufacturer, model, specs, where to buy |
| Repair Guides | Step-by-step procedures for common repairs, customized to the equipment on-site |
| Company Knowledge Base | Past solutions from this company's job history. AI learns from every resolved issue. |
| Safety Procedures | LOTO steps, confined space entry, PPE requirements — auto-pulled per job type |
| Wiring/Piping Diagrams | AI-generated reference diagrams based on job description and equipment |

### Permission Model
Owner/admin sets per-role or per-user:
- Which jobs they can see (assigned only vs. all company jobs)
- Whether they can create bids (or just view)
- Whether they can approve change orders (or just create/submit)
- Access to AI troubleshooting (tier-gated by subscription)
- Meetings access
- Customer contact info visibility

### Tech Stack
- Next.js 15, React 19, TypeScript, Tailwind CSS
- Same Supabase backend as all other portals
- RLS scopes all queries to `company_id` + role permissions
- PWA-capable (installable on phone home screen)

### Codebase Path
`apps/Trades/team-portal/`

---

## PROPERTY MANAGEMENT SYSTEM — DONE (D5, S71-S77)

### The Moat
Most property management software (AppFolio, Buildium, TenantCloud) is built for property managers who HIRE contractors. ZAFTO is built for contractors who ARE the property owner. The maintenance loop closes internally:

**Tenant submits maintenance request → becomes a job in ZAFTO → contractor assigns to crew or does it themselves → no middleman, no external platform.**

### Built (18 tables, 14 CRM pages, 11 hooks, 10 Flutter screens, 3 EFs)
- Tenant management (lease terms, contact info, payment history)
- Lease tracking (start/end dates, renewal alerts, rent increases)
- Rent collection (Stripe integration deferred to Phase U payment flow)
- Maintenance requests → auto-create ZAFTO jobs
- Property financials (income/expenses per property, NOI, cap rate)
- Vacancy tracking + listing
- Move-in/move-out inspections (ties to field tools)
- Property inspections (ties to Mobile Field Toolkit)
- Multi-property portfolio dashboard

### Integration with ZAFTO
- Ledger: Rental income/expenses auto-categorize
- Calls: Tenant communication via business line
- Field Tools: Inspection documentation
- Z Intelligence: Maintenance cost predictions, vacancy forecasting (Phase E)

---

## SUBSCRIPTION TIERS (Updated S133)

### Professional Tiers (Contractor, Realtor, Inspector)

| Feature | Solo ($69.99/mo) | Team ($149.99/mo) | Business ($249.99/mo) | Enterprise (Custom) |
|---------|:-:|:-:|:-:|:-:|
| Full platform (dashboard, jobs, invoices, customers, ledger) | Y | Y | Y | Y |
| Z Intelligence AI + visual usage meter | Y | Y | Y | Y (unlimited) |
| Sketch Engine (CAD-grade floor plans) | Y | Y | Y | Y |
| Unlimited Recon (property intelligence) | Y | Y | Y | Y |
| Estimate engine (own code DB, crowdsource) | Y | Y | Y | Y |
| 19 field tools (photos, voice notes, signatures, etc.) | Y | Y | Y | Y |
| Full accounting with bank sync (Plaid) | Y | Y | Y | Y |
| Business phone line | 1 | 5 | 15 | Unlimited |
| Fax (send/receive) | Y | Y | Y | Y |
| Video meetings | Y | Y | Y | Y |
| Client portal | Y | Y | Y | Y |
| Blueprint scans/mo | 5 | 25 | Unlimited | Unlimited |
| Customer financing | Y | Y | Y | Y |
| Team members | 1 | 5 | 15 | Unlimited |
| Insurance claims module | — | Y | Y | Y |
| Property Management units | — | 10 | 100 | Unlimited |
| Employee portal + team chat | — | Y | Y | Y |
| Dispatch board + live map | — | — | Y | Y |
| Payroll/direct deposit + HR/hiring/fleet | — | — | Y | Y |
| Construction accounting (WIP, AIA) | — | — | — | Y |
| Custom roles/permissions + API access | — | — | — | Y |
| Multi-branch + SSO/SAML | — | — | — | Y |

### Homeowner Tier

| Feature | Free ($0) | Premium ($49.99/mo) |
|---------|:-:|:-:|
| Equipment passport, maintenance calendar | Y | Y |
| Contractor marketplace access | Y | Y |
| Project tracking, view contractor progress/photos | Y | Y |
| Basic property profile | Y | Y |
| 3D property scan + renovation visualization | — | Y |
| AI troubleshoot + rehab estimates | — | Y |
| Premium reports, insurance tools, tax tools | — | Y |

### Adjuster Tier

| Feature | Free ($0) |
|---------|:-:|
| Evidence package viewer (3D scans, photos, floor plans, weather data) | Y |
| Claims dashboard (all Zafto contractor submissions) | Y |
| Per-item approve/flag, supplement diff | Y |
| Contractor messaging thread | Y |
| PDF export, audit trail | Y |

**Adjuster portal is 100% free. No premium tier. No paywall. Pure acquisition funnel — every adjuster on the platform = claims flowing to paying contractors. See ECO3-ECO4 sprint specs.**

---

## DATABASE

### Supabase PostgreSQL (2 projects: dev + prod)

**~215 tables across 114 migrations.** Core (companies, users, customers, jobs, invoices, bids, time_entries, employees) + Revenue (D1-D8: 40+ tables) + Platform (F1-F10: 70+ tables) + Programs (T: 17 tables) + Recon (P: 15 tables) + Sketch (SK: 6 tables) + Schedule (GC: 12 tables) + Field (FIELD: 6 tables) + Restoration (REST: 10 tables) + Niche (NICHE: 6 tables) + Security (audit_log, rate_limits, etc.)
**RLS + audit triggers on all business tables. company_id scoping. JWT-based RBAC.**

See Circuit Blueprint for complete schema mapping.

---

## LOCKED SPECS (decided, do not modify)

| Doc | What | Location |
|-----|------|----------|
| Design System v2.6 | 10 themes, ZAFTO wordmark, typography, spacing | Locked/11 |
| Database Migration | Supabase schema, RLS, PowerSync, cost comparison | Locked/29 |
| Security Architecture | 6-layer security, RBAC matrix, encryption, audit, data export | Locked/30 |
| DevOps Infrastructure | CI/CD, environments, secrets, Sentry, testing | Locked/32 |
| Ops Portal (Founder OS) | 72 pages, 20 sections, 4 phases | Locked/34 |
| Restoration/Insurance Module | 9th trade, insurance claims, Xactimate | Locked/36 |
| Job Type System | 3 types, progressive disclosure | Locked/37 |

---

## CRITICAL RULES

1. **NO DRIFT** — Update these docs, never create new ones
2. **AI goes TRULY LAST** — After ALL of T + P + SK + GC + U + G. Not after D. After EVERYTHING. AI must know every feature, every table, every screen. Deep spec session before building. NEVER again start AI before platform is complete.
3. **ZAFTO wordmark** — NOT just the Z. Z is for AI/premium.
4. **Ledger** — Not "ZAFTO Books"
5. **Stripe feel** — Premium, clean, professional everywhere
6. **RLS on every table** — Tenant isolation at database level
7. **Test during wiring** — Not separately
8. **Circuit Blueprint is LIVING** — Update as connections are made
9. **Property Management** — DONE (D5, S71-S77). 18 tables, full moat.
10. **MS Office: SCRAPPED** — ZForge only, build LAST (F10)
11. **Static content: REMOVED** — Claude AI handles natively
12. **Offline-first** — PowerSync (SQLite <-> PostgreSQL)
13. **Progressive disclosure** — Clean by default, complexity activates per-need
14. **Nothing ships without human approval** — Every AI artifact needs contractor review
15. **BUILD ORDER (S133):** A(DONE) → B(DONE) → C(DONE) → D(DONE) → F(DONE) → T(DONE) → P(DONE) → SK(DONE) → GC(DONE) → U(DONE) → W(DONE) → J(DONE) → L(DONE) → INS(DONE) → **DEPTH2-39** → DEPTH40-nonAI → DEPTH41-43 → **INTEG2-4+INTEG6-8** → RE1-20 → INTEG1 → FLIP1-4 → **INTEG5** → SEC2-5 → LAUNCH2-6 → LAUNCH8 → G(G6-G10) → JUR → **E (AI LAST: E-review → BA1-BA8 → E1-E4)** → FLIP5+DEPTH40-AI+DEPTH44 → SEC9-10 → ZERO1-9 → LAUNCH7 → SHIP. Post-launch: F2+F8+RE21-30+CLIENT1-17+CUST1-8+ECO3-8+VIZ1+MOV1-8.
16. **DEPTH IS NON-NEGOTIABLE** — Every feature must be comprehensive. System defaults must impress on first use. No shallow implementations. Owner directive S122.
17. **ADJUSTER PORTAL IS FREE** — No premium tier. No paywall. Pure acquisition funnel. Trojan horse into insurance ecosystem. Owner directive S133.
18. **$0/MONTH API COST AT LAUNCH** — 250+ free APIs cataloged. Paid APIs gated behind feature flags. Post-revenue only.
19. **NEVER GENERATE .ESX FILES** — Verisk proprietary format. Legal risk. Owner directive S132.
20. **ONLY OPUS 4.6 WRITES CODE** — Never delegate code writing to inferior models. Owner directive S128.

---

CLAUDE: This is the single source of truth. Update it. Never create parallel docs.
