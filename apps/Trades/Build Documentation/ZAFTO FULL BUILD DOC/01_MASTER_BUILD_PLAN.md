# ZAFTO MASTER BUILD PLAN — NO DRIFT
## Single Source of Truth — Every Feature, Every Phase, Every Decision
### Last Updated: February 11, 2026 (Session 97)

---

## WHAT IS ZAFTO

Complete business-in-a-box for trades. One subscription replaces 12+ tools. Stripe-level quality for blue-collar professionals. Multi-trade platform that scales by uploading knowledge, not building screens.

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
| **Buy more AI usage** | Clean dollar amounts, no units: **$10 \| $25 \| $50 \| $100 \| $500 \| $1,000**. User taps a dollar amount, meter refills proportionally, AI turns back on. No token counts, no "you purchased X credits." Just dollars in, AI back on. Internal system maps dollars to AI capacity based on Sonnet token costs + margin. User never sees that math. |
| **Upgrade option** | Below the dollar buttons: "Or upgrade your plan for higher monthly limits." Links to plan upgrade flow. User is never FORCED to upgrade — buying more usage is always an option. |
| **Business/Enterprise** | Unlimited AI. No meter shown. Never restricted. |
| **Internal tracking** | Ops portal tracks AI cost per company, dollar top-up revenue, margin per customer. User never sees this. |
| **Model choice** | **Opus 4.6** for all AI features (Z Intelligence, Blueprint Analyzer, AI Scanner, trade tools). Sonnet 4.5 only for trivial background tasks (classification, routing). Anything the user sees or that generates revenue documents = Opus. No compromises. |
| **Old system** | The `user_credits`, `credit_purchases`, `scan_logs` tables and `subscription-credits` EF from FM migration are DEPRECATED. Will be replaced during Phase E with tier-based usage tracking + dollar top-ups. RevenueCat IAP credit products (`zafto_credits_*`) are KILLED. |

**This replaces ALL previous credit/scan-count/package pricing models across all docs and code.**

---

## ARCHITECTURE

```
                        ZAFTO PLATFORM
    ┌──────────────────────────────────────────────────┐
    │                  SUPABASE                         │
    │  PostgreSQL + Auth + Storage + Realtime + Edge Fn │
    │  RLS on every table. 6-layer security.           │
    ├──────────────────────────────────────────────────┤
    │  Stripe    Claude API    Cloudflare    Sentry    │
    │  SignalWire SendGrid     Plaid         RevenueCat│
    └────────────┬──────┬──────┬──────┬────────────────┘
                 │      │      │      │
         ┌───────┘  ┌───┘  ┌───┘  ┌───┘
         ▼          ▼      ▼      ▼
    ┌─────────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐
    │ Mobile  │ │ Web  │ │Employee│ │Client│ │ Ops  │
    │ App     │ │ CRM  │ │Field  │ │Portal│ │Portal│
    │ Flutter │ │Next.js│ │Next.js│ │Next.js│ │Next.js│
    │ Field   │ │Office│ │Team   │ │Home  │ │Founder│
    └─────────┘ └──────┘ └──────┘ └──────┘ └──────┘
         │
    ┌─────────┐
    │PowerSync│  Offline-first (SQLite <-> PostgreSQL)
    └─────────┘
```

**URLs:**
- `zafto.app` — Marketing landing page
- `team.zafto.cloud` — Employee Field Portal (techs, apprentices, field crews)
- `zafto.cloud` — Contractor CRM (owner, admin, office manager)
- `client.zafto.cloud` — Client/Homeowner Portal
- `ops.zafto.cloud` — Founder OS (internal, super_admin)

---

## CURRENT STATE (February 11, 2026 — Session 97)

| What | Built | Wired | End-to-End |
|------|:-----:|:-----:|:----------:|
| Mobile App (R1 remake — 33 role screens) | YES | YES | YES (Supabase) |
| Mobile Field Tools (19 total) | YES | YES (B2+B3) | YES (all 19 wired) |
| Web CRM (107 routes, 68 hooks) | YES | YES | YES (Supabase) |
| Client Portal (38 routes, 21 hooks) | YES | YES | YES (Supabase) |
| Employee Field Portal (36 routes, 22 hooks) | YES | YES | YES (Supabase) |
| Ops Portal (26 routes) | YES | YES | YES (Supabase) |
| Database (Supabase) | ~173 tables | RLS + audit on all | 48 migrations |
| Edge Functions | 53 directories | 32 pre-F + 21 F/FM | Needs ANTHROPIC_API_KEY |
| RBAC | Enforced | Middleware on all portals | RLS per table |
| Ledger (QB replacement) | YES | YES (13 hooks, 13 pages, 5 EFs) | YES |
| Property Management | YES | YES (11 hooks, 14 pages, 10 Flutter screens) | YES (D5, S71-S77, 18 tables) |
| Insurance/Restoration | YES | YES (7 tables, all 5 apps) | YES |
| D8 Estimates | YES | YES (D8a-D8j, 10 tables, 5 EFs) | DONE (S85-S89) |
| Phase F Platform (F1-F10) | YES (code) | YES (hooks+pages) | ALL CODE COMPLETE (S90) |
| **Phase E AI (PREMATURE)** | **YES (code exists)** | **PAUSED** | **NOT TESTED — AI goes LAST** |
| **Phase T: Programs** | **COMPLETE** | **YES** | **S104: T1-T10 done. 11 migrations, 58 EFs, ~192 tables, all portals** |
| **Phase P: Recon** | **COMPLETE** | **YES** | **S105: P1-P10 done. 11 tables, 7 EFs, 5 CRM routes, 1 ops route, Flutter screens** |
| **Phase SK: Sketch Engine** | **COMPLETE** | **YES** | **S109: SK1-SK14 all done. 6 tables, 62 migrations. Export (PDF/PNG/DXF/FML/SVG), 3D view, site plan mode (exterior trades), trade formulas (8 trades), templates, snap guides, collaboration foundation. Auto-estimate wired to D8.** |
| **Phase GC: Schedule** | **COMPLETE** | **YES** | **S110: GC1-GC11 all done. 12 tables, 10 EFs (schedule-*), 9 CRM pages, Flutter screens, Mini Gantt widgets, CPM/resource leveling, EVM cost loading, weather integration, portfolio view, field sync, reminders cron.** |
| **Phase U: Unification** | **COMPLETE** | **YES** | **S111-S114: U1-U23 ALL DONE. Nav redesign, permission engine, ledger completion, dashboard restoration, PDF/email, payment flow, metric verification, ops CRUD, forgot password, i18n, universal trade, GPS walkthrough, dispatch board, data import, subcontractors, calendar sync, phone system config (6-tab settings, 3 hooks, 5 trade presets). ~448 hrs total.** |
| **Phase W: Warranty** | **COMPLETE** | **YES** | **S113 chain: W1 warranty intelligence, hooks + pages across 4 portals.** |
| **Phase J: Job Intelligence** | **COMPLETE** | **YES** | **S113 chain: J1-J2 smart pricing + job analytics, hooks + pages.** |
| **Phase L: Legal/Permits** | **COMPLETE** | **YES** | **S113 chain: L1-L9 permit intelligence, jurisdictions, compliance, liens, CE tracker. 5 migrations.** |
| **Phase INS: Inspector Deep Buildout** | **COMPLETE** | **YES** | **S121-S122: INS1-INS8 all done (~52h). 19 inspection types, template-driven checklists, weighted scoring, deficiency tracking w/ photos, PDF reports, GPS capture, reinspection diffs, code reference (61 NEC/IBC/IRC/OSHA/NFPA sections), compliance calendar, permit tracker, CRM templates hook+page, inspection detail, ops metrics, team inspections.** |
| **Phase G: QA/Hardening** | **IN PROGRESS** | **PARTIAL** | **S113: G1-G5 automated sprints DONE. G6-G10 manual QA PENDING.** |
| **Plan Review** | **SPEC'D (S97)** | **NO** | Phase E feature (BA1-BA8, ~128 hrs) |

**ALL PHASES A-F + T + P + SK + GC + U + W + J + L + INS COMPLETE. D5-PV DONE (S117). Tech App DONE (S118-S120). Phase INS DONE (S121-S122). Phase G automated DONE (G1-G5), manual QA pending (G6-G10). ~201 tables. 68 migrations. 70 Edge Functions. 126 CRM routes. 36 team routes. 39 client routes. 29 ops routes. Next: G6-G10 manual QA → E (AI LAST: E-review → BA1-BA8 → E1-E4) → LAUNCH. F2 + F8 post-launch.**

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

### PHASE G: DEBUG, QA & HARDENING

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| G1 | Full platform debug | ~100-150 | Every screen, every edge case, every role, real data |
| G2 | Security audit | ~20-30 | Pen testing, RLS verification, credential rotation |
| G3 | Performance optimization | ~20-30 | Load testing, query optimization, caching |
| G4 | Security hardening | ~4 | Email migration, Bitwarden changeover, 2FA, YubiKeys |

### PHASE T: TPA PROGRAM MANAGEMENT MODULE (NEXT — after F)

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

### PHASE P: PROPERTY INTELLIGENCE ENGINE (Recon) — after T

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

### PHASE SK: CAD-GRADE SKETCH ENGINE (after P)

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

### PHASE U: UNIFICATION & FEATURE COMPLETION (after SK, before G)

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

### PHASE E: AI LAYER (REBUILD — after T + P + SK + U + G)

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| E-review | Audit all premature E work | ~8 | Deep spec session with owner. AI must know every feature, table, screen — including TPA module + Recon + Sketch Engine + Phase U unification. Rebuild with full platform context. |
| BA1-BA8 | Plan Review | ~128 | AI blueprint reading + automated takeoff. 6 tables, 3 EFs. Hybrid CV+LLM pipeline (MitUNet segmentation + YOLOv12 detection + Claude intelligence). RunPod Serverless GPU. Trade intelligence, assembly expansion, estimate + material order generation, revision comparison, SK floor plan generation. Spec: `Expansion/47_BLUEPRINT_ANALYZER_SPEC.md` |
| E1-E4 | Full AI implementation | TBD | Universal AI, Dashboard, Command Center, Growth Advisor. Every feature AI-enhanced. Rebuilt with full platform knowledge including BA. |

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

### Web CRM (107 routes, 68 hooks) — ALL WIRED TO SUPABASE
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

### Client Portal (38 routes, 21 hooks) — ALL WIRED TO SUPABASE
| Tab | Routes | Status | Phase |
|-----|:------:|--------|-------|
| Auth + Home | 2 | **DONE** — Magic link auth | B6 |
| Projects (List, Detail, Estimate, Agreement, Live Tracker) | 5 | **DONE** | B6 |
| Payments (Invoices, Detail, History, Methods) | 4 | **DONE** | B6 |
| My Home (Profile, Equipment, Service History, Maintenance) | 4+ | **DONE** | B6/F7 |
| Menu (Messages, Documents, Request, Referrals, Review, Settings) | 6 | **DONE** | B6 |
| F-phase (SMS, Meetings, Booking, Home Portal, Get Quotes, Find a Pro) | 8+ | **DONE** | F1/F3/F7 |
| Walkthroughs + Estimates | 3+ | **DONE** | E6/D8 |

### Employee Field Portal (team.zafto.cloud) — 36 ROUTES, ALL WIRED
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

### Ops Portal (26 routes Phase 1 DONE, 54 routes Phases 2-4 POST-LAUNCH)
| Section | Routes | Status | Phase |
|---------|:------:|--------|-------|
| Command Center, Inbox, Accounts, Support, Health, Revenue, Services, AI | 18 | **DONE** | C3 |
| Phone/Meeting Analytics, Payroll, Fleet, Hiring, Email, Marketplace analytics | 8 | **DONE** | F1-F9 |
| Marketing Engine, Growth CRM, Treasury, AI Sandbox | 23 | POST-LAUNCH | F8 |
| Legal, Dev Terminal, Ads, SEO, Vault, Referrals, Analytics | 23 | POST-LAUNCH | F8 |
| Marketplace Ops | 8 | POST-LAUNCH | F8 |

### Expansion Features — EVERY ONE ACCOUNTED FOR
| Feature | Source | Hours | Status | Phase |
|---------|--------|:-----:|--------|-------|
| Job Type System (3 types) | Locked/37 | ~69 | **DONE** (S62) | D1 |
| Restoration/Insurance Module | Locked/36 | ~78 | **DONE** (S63-64,68) | D2 |
| Insurance Verticals (4) | Expansion/38 | ~107 | **DONE** (S69) | D3 |
| Ledger (full accounting) | 07_SPRINT_SPECS D4a-D4p | ~80+ | **DONE** (S70) | D4 |
| Property Management System | 07_SPRINT_SPECS D5a-D5j | ~80+ | **DONE** (S71-S77, 18 tables) | D5 |
| Enterprise Foundation | Expansion | ~20 | **DONE** (S65-66) | D6 |
| Certification System | Expansion | ~12 | **DONE** (S67-68) | D7 |
| Estimates (Two-Mode) | 07_SPRINT_SPECS D8a-D8j | ~100+ | **DONE** (S85-S89, 10 tables, 5 EFs) | D8 |
| Universal AI Architecture (6 layers) | Expansion/35 | TBD | PAUSED (Phase E) | E1 |
| Dashboard + Artifacts | Expansion/41 | TBD | PAUSED (Phase E) | E2 |
| Dashboard (7 concepts) | Expansion/40_UNIFIED_COMMAND_CENTER | TBD | PAUSED (Phase E) | E3 |
| Growth Advisor | Expansion/39_GROWTH_ADVISOR | ~88 | PAUSED (Phase E, uncommitted) | E4 |
| Calls (SignalWire VoIP/SMS/Fax) | Expansion/31 | ~40-55 | **DONE** (S90) | F1 |
| Website Builder V2 | Expansion/28_WEBSITE_BUILDER_V2 | TBD | POST-LAUNCH (S94 directive) | F2 |
| Meetings | Expansion/42 | ~55-70 | **DONE** (S90) | F3 |
| Mobile Field Toolkit (24 tools) | Expansion/43 | ~89-107 | **DONE** (S90) | F4 |
| Integrations (9 systems) | Expansion/27 | ~180+ | **DONE** (S90) | F5 |
| Marketplace | Expansion/33 | ~80-120 | **DONE** (S90) | F6 |
| Home Portal | Expansion/16_ZAFTO_HOME_PLATFORM | ~140-180 | **DONE** (S90) | F7 |
| Ops Portal Phases 2-4 | Locked/34 | ~111 | POST-LAUNCH | F8 |
| Multi-Channel Hiring System | Expansion/44_HIRING_SYSTEM | ~18-22 | **DONE** (S90) | F9 |
| ZForge (PDF-first) | Master Plan | TBD | **DONE** (S90) | F10 |
| **Programs Module** | **Expansion/39_TPA_MODULE_SPEC** | **~80** | **SPEC'D — NEXT** | **T** |
| **Recon / Property Intelligence** | **Expansion/40_PROPERTY_INTELLIGENCE_SPEC** | **~96** | **SPEC'D** | **P** |
| **CAD-Grade Sketch Engine** | **Expansion/46_SKETCH_ENGINE_SPEC** | **~176** | **IN PROGRESS (SK1-SK8 done)** | **SK** |
| **Gantt & CPM Scheduling Engine** | **Expansion/48_GANTT_CPM_SCHEDULER_SPEC** | **~124** | **SPEC'D (S97)** | **GC** |
| **Unification & Feature Completion** | **NEEDS SPEC SESSION** | **~120** | **PLANNED** | **U** |
| **Plan Review (AI Takeoff)** | **Expansion/47_BLUEPRINT_ANALYZER_SPEC** | **~128** | **SPEC'D (S97)** | **E/BA** |

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

## SUBSCRIPTION TIERS

| Feature | Solo | Team | Business | Enterprise |
|---------|:----:|:----:|:--------:|:----------:|
| Dashboard, Jobs, Invoices, Customers | Y | Y | Y | Y |
| PDF invoices, Price book | Y | Y | Y | Y |
| Command palette | Y | Y | Y | Y |
| Ledger (full accounting) | Y | Y | Y | Y |
| Dashboard (persistent AI) | Y | Y | Y | Y |
| Team members | 1 | 5 | 15 | Unlimited |
| AI bid generator | 5/mo | 50/mo | Unlimited | Unlimited |
| Dispatch board + Live map | — | — | Y | Y |
| Calls lines | 1 | 5 | 15 | Unlimited |
| Fax (send/receive) | Y | Y | Y | Y |
| Website Builder | — | $19.99/mo | $19.99/mo | Included |
| Estimates (Regular Bids) | Y | Y | Y | Y |
| Insurance Claims Module + ESX Export | — | Y | Y | Y |
| Property Management | — | 10 units | 100 units | Unlimited |
| Meetings | Y | Y | Y | Y |
| Custom roles | — | — | — | Y |
| API access | — | — | — | Y |

---

## DATABASE

### Supabase PostgreSQL (2 projects: dev + prod)

**Core tables (deploy first):** companies, users, customers, jobs, invoices, bids, time_entries, employees, vehicles, vendors, purchase_orders
**Security tables:** audit_log, user_sessions, login_attempts, role_permissions, company_encryption_keys
**Expansion tables:** Deploy per phase as needed (50+ additional tables across all systems)

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
15. **BUILD ORDER: A → B → C → D → F → T → P → SK → GC → U → G → E (E-review → BA1-BA8 → E1-E4) → LAUNCH** — Platform first. Build all features (T+P+SK+GC). Unify portals + complete features (U). QA/Harden everything at once (G). AI last (E), including Plan Review (BA).

---

CLAUDE: This is the single source of truth. Update it. Never create parallel docs.
