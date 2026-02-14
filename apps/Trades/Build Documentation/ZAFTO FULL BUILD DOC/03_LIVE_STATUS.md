# ZAFTO LIVE STATUS
## UPDATE THIS EVERY SESSION

**Last Updated:** February 13, 2026 (Session 109 — **Phase SK COMPLETE (SK9-SK14 all done).** SK9: Export Pipeline (PDF/PNG/DXF/FML/SVG) Flutter+Web. SK10: 3D three.js view. SK11: Perf+error handling. SK12: Site Plan Mode (exterior property drawing — 8 layers, boundary/structures/roof/fence/concrete/lawn/landscape/symbols). SK13: Trade formulas (8 trades) + 10 templates. SK14: Snap guides + collaboration foundation. ~25 new files, ~5000 lines. `npm run build` 0 errors.)
**Current Phase:** BUILD — **Phases A-D + F + T + P + SK ALL COMPLETE.** R1 DONE. FM code done. Phase E PAUSED. ~180 tables. 62 migrations. 60 Edge Functions. 121 CRM routes. 36 team routes. 39 client routes. 28 ops routes.
**Next Action:** Phase GC (Schedule) + GC-WX weather extension → Phase U (Unification, ~432 hrs) + U extensions (REP, SUB, FIN, MAT, LOG, CO, TT = +196 hrs) → Phase W (Warranty+Lifecycle, ~56 hrs) → Phase J (Job Intelligence, ~64 hrs) → Phase L (Legal/Permits/Compliance, ~120 hrs) → Phase G (QA/Hardening) → Phase E (AI: E-review → BA1-BA8 Plan Review → E1-E4) → LAUNCH.

---

## QUICK STATE

| Field | Value |
|-------|-------|
| **Phase** | BUILD — **Phases A-D + F + T + P + SK ALL COMPLETE.** R1 DONE. FM code done. Phase E PAUSED. ~180 tables. 62 migrations. 60 Edge Functions. 121 CRM routes. 36 team routes. 39 client routes. 28 ops routes. **Codemagic Android PASSING (S91). Phase T COMPLETE (S104). Phase P COMPLETE (S105). Phase SK COMPLETE (S109, SK1-SK14 ALL DONE). Phase GC SPEC'D. Phase U EXPANDED (S100, U1-U22 ~432 hrs). Plan Review SPEC'D (S97, BA1-BA8 ~128 hrs).** Next: GC → U → G → E → LAUNCH. |
| **Mobile App (Flutter)** | **R1 App Remake (S78):** 33 role-based screens, design system (8 widgets), AppShell with role switching. **E3c (S80):** ai_service.dart + z_chat_sheet.dart + ai_photo_analyzer.dart, Z FAB in AppShell. **E5f (S79):** Estimate entry screens. **E6b (S79):** 12 walkthrough screens + 4 annotation files + 4 sketch editor files. ALL core business wired. ALL 18 field tools wired. D2 Insurance: 3 screens. D5f Properties: 10 screens. `dart analyze` passes 0 errors. |
| **Web CRM (Next.js)** | **121 routes built.** 73 hook files + 27 Dashboard files. Auth+middleware DONE. UI Polish DONE. **F-phase (S90):** 30+ hooks + pages for phone, fax, meetings, team-chat, inspection-engine, osha-standards, fleet, payroll, hr, email, marketplace, hiring, zdocs. **T-phase (S104):** TPA hooks + pages. **P-phase (S105):** use-property-scan + use-area-scan + use-storm-assess hooks. Recon pages: /dashboard/recon (list + detail with 5 tabs), /dashboard/recon/area-scans (list + new + detail). All wired to Supabase via real-time hooks. `npm run build` passes (121 routes, 0 errors). |
| **Client Portal (Next.js)** | **38 routes. 18+ hooks.** Magic link auth. **F7 (S90):** Home Portal — use-home hook + my-home/equipment/service-history/maintenance pages. **F1 (S90):** SMS messaging page. **F3 (S90):** Meetings + booking pages. **F-expansion (S90):** Documents, Get Quotes, Find a Pro pages. `npm run build` passes (38 routes, 0 errors). `client.zafto.cloud`. |
| **Employee Field Portal (Next.js)** | **36 routes. 21+ hooks. PWA-ready.** `team.zafto.cloud`. **F1 (S90):** Phone page. **F3 (S90):** Meetings page. **F5 (S90):** Pay stubs, my vehicle, training, my documents pages + MY STUFF sidebar section. `npm run build` passes (36 routes, 0 errors). |
| **Ops Portal (Next.js)** | **28 dashboard routes. `npm run build` passes (0 errors).** `ops.zafto.cloud`. Deep navy/teal theme. super_admin role gate. **F1/F3 (S90):** Phone analytics + meeting analytics pages. **F5-F9 (S90):** Payroll/fleet/hiring/email/marketplace analytics pages + PLATFORM sidebar section. **T-phase (S104):** TPA analytics page. **P-phase (S105):** API costs dashboard (/dashboard/api-costs). |
| **Field Tools** | **19 total. ALL wired.** 14 original (B2a-d) + 2 new (B3a: Materials+DailyLog) + 3 new (B3b: PunchList+ChangeOrders+JobCompletion). 0 remaining. |
| **Database** | Supabase (PostgreSQL). 2 projects (dev + prod). **~180 tables** across 62 migration files. Phases A-D: 102 tables. F-phase + FM: +71 tables. T-phase: +17 tables. P-phase: +11 tables (property_scans, roof_measurements, roof_facets, property_features, property_structures, parcel_boundaries, wall_measurements, trade_bid_data, property_lead_scores, area_scans, scan_history) + 4 config tables (company_feature_flags, scan_cache, api_cost_log, api_rate_limits). RLS + audit on all. Supabase CLI linked to dev. Seed data: 55 COA accounts, 26 tax categories, 77 Xactimate codes, 76 TPA document types, 50 restoration line items. |
| **Edge Functions** | **60 directories total.** Pre-F (32). F-phase + FM (21). **T-phase (3):** tpa-documentation-validator, tpa-financial-rollup, restoration-export. **P-phase (7):** recon-property-lookup, recon-roof-calculator, recon-trade-estimator, recon-lead-score, recon-area-scan, recon-material-order (GATED behind UNWRANGLE_API_KEY), recon-storm-assess. **5 in E4 dirs (uncommitted):** ai-revenue-insights, ai-customer-insights, ai-bid-optimizer, ai-equipment-insights, ai-growth-actions. |
| **Backend Connected** | Auth + Customers + Jobs + Invoices + Bids + Time Clock + Calendar ALL wired. ALL 18 field tools wired. D2 Insurance: 7 tables. D4 Ledger: GL engine + 15 tables. D5 PM: 18 tables. E1 AI: z_threads + z_messages. E5 Xactimate: 5 tables. E6 Walkthrough: 5 tables. |
| **DevOps** | **C1 DONE (S58):** Sentry in all 4 apps. CI/CD: 4 workflows. 154 model tests. **C2 NEAR COMPLETE (S60-S61):** RBAC middleware on all portals. **C3 DONE (S59):** Ops Portal. **C5 DONE (S59):** Incident response. **Codemagic (S91):** Android debug build PASSING (95 MB .aab). iOS needs code signing. Bundle ID: app.zafto.mobile. **Dependabot (S91):** 0 vulnerabilities. |
| **Blocker** | **Phase E PAUSED.** AI goes last — after T+P+SK+U+G. **Phase F ALL CODE COMPLETE — Phase T (Programs, ~80 hrs) is NEXT, then Phase P (Recon, ~96 hrs), then Phase SK (Sketch Engine, ~176 hrs), then Phase GC (Schedule, ~124 hrs), then Phase U (Unification, ~120 hrs), then Phase G (QA), then Phase E (AI: E-review → BA1-BA8 Plan Review ~128 hrs → E1-E4) → LAUNCH.** Plan Review needs RunPod account + GPU endpoint setup at BA2 time. Firebase migration manual steps pending (secrets, deploy, webhook URLs). Sentry DSN empty. External API integrations pending (Gusto, Checkr, DocuSign, Samsara). ~18 F-phase migrations need `npx supabase db push` deployment. iOS Codemagic needs Apple code signing. Android release keystore not created. Programs: IP attorney opinion letter needed before shipping ESX export (deferred to revenue stage). Recon: Google Solar API key + ATTOM API key + Regrid API key needed. Sketch Engine: Apple Developer account needed for RoomPlan testing on LiDAR devices. |
| **API Keys Stored** | **Supabase Secrets:** UNWRANGLE_API_KEY (supplier pricing), PLAID_CLIENT_ID + PLAID_SECRET (bank feeds, sandbox), GOOGLE_CLOUD_API_KEY (maps+calendar, $300 credit), SIGNALWIRE_* (VoIP/SMS/Fax — space URL + project ID + API token), LIVEKIT_* (video — URL + API key + secret). **Env files:** Mapbox (maps), SignalWire (all portals), LiveKit (all portals). **Firebase secrets (need migration to Supabase):** STRIPE_SECRET_KEY + STRIPE_WEBHOOK_SECRET (full payment integration in `backend/functions/index.js`), ANTHROPIC_API_KEY (AI). **RevenueCat:** webhook handler built (`revenueCatWebhook` in `backend/functions/`), uses header signature verification. **Sentry:** SDK wired in all apps, DSN is EMPTY — needs DSN from Sentry dashboard. **Stripe in source code:** `company.dart` has `stripeCustomerId`, `types/index.ts` has `stripeAccountId`, ops-portal references Stripe in revenue/subscriptions/directory pages. Pending: DocuSign, Indeed, Checkr, LinkedIn. |
| **Security Policy** | ZAFTO_Information_Security_Policy.docx CREATED — 13 sections, enterprise-grade. WebAuthn/passkeys/biometrics documented. Reusable for all API applications. |

---

## ACCOUNTS STATUS

| Account | Status | Email |
|---------|--------|-------|
| MS 365 Business Basic | ACTIVE (5 emails on zafto.app) | admin/robert/support/legal/info@zafto.app |
| Supabase | ACTIVE (2 projects: dev + prod) | admin@zafto.app |
| Sentry | ACTIVE (free tier) | admin@zafto.app |
| Stripe | ACTIVE | needs migration to admin@zafto.app |
| GitHub | ACTIVE (TeredaDeveloper) | needs migration to admin@zafto.app |
| Apple Developer | ACTIVE | needs migration to admin@zafto.app |
| Anthropic | ACTIVE | needs migration to admin@zafto.app |
| Cloudflare | ACTIVE | needs migration to admin@zafto.app |
| RevenueCat | ACTIVE | admin@zafto.app |
| Bitwarden | ACTIVE | needs migration to admin@zafto.app |
| Codemagic | ACTIVE (Android debug PASSING) | admin@zafto.app |
| Google Play | NOT CREATED (needed for launch — both iOS + Android) | — |
| ProtonMail | NOT CREATED (break-glass recovery — do before launch) | — |
| YubiKeys | NOT PURCHASED (do before launch) | — |

**Security hardening (email migration + password changeover + 2FA) — do before launch, not blocking build.**

---

## BUILD ORDER (Linear, No-Drift)

| # | Step | Est. Hours | Status |
|---|------|:----------:|--------|
| 1 | Code cleanup (remove dead code, Firebase refs, unused files) | ~4-8 | DONE (Session 37) |
| 2 | DevOps Phase 1 (Supabase environments + secrets + Dependabot) | ~2 | DONE (Session 39) |
| 3 | Database Migration (schema + RLS + storage buckets) | ~17-25 | DONE (16 tables deployed, 7 buckets created, env keys filled). PowerSync deferred. |
| 4 | Wire W1: Core Business (Jobs/Bids/Invoices/Customers/Auth/RBAC) | ~23 | DONE (S41-S43) |
| 5 | Wire W2: Field Tools to Backend (14 tools) | ~26 | **DONE (S44-S47)** |
| 6 | Wire W3: Missing Tools (Materials, Daily Log, Punch List, etc.) | ~22 | **DONE (S47-S48)** |
| 7 | Wire W4: Web CRM to real data (40 pages) | ~18 | **DONE (S49-S54)** — 71 routes total with E4/E5/E6 additions. |
| 8 | Wire W5: Employee Field Portal (team.zafto.app) | ~20-25 | **DONE (S55)** — 25 routes including E3b AI troubleshooting. |
| 9 | Wire W6: Client Portal to real data | ~13 | **DONE (S56)** — 29 routes including E3d AI chat widget. |
| 10 | Wire W7: Polish (registry, Cmd+K, offline sync, notifications) | ~19 | **DONE (S57)** |
| 11 | DevOps Phase 2 (Sentry wiring, tests, CI/CD) | ~8-12 | **DONE (S58)** |
| 12 | Debug & QA with real data | ~20-30 | **DONE (S60-S61)** — Initial QA pass. Full QA is Phase G (after T+P+SK+U). |
| 13 | Ops Portal Phase 1 (18 pages, pre-launch) | ~40 | **DONE (S59)** |
| 14 | Security hardening (email migration, passwords, YubiKeys) | ~4 | PENDING |
| 15 | Revenue Engine: Job Types + Insurance + Enterprise | ~217 | **ALL DONE (S62-S69)** — D1+D2+D3+D6+D7a complete. |
| 16 | Revenue Engine: Ledger (QB replacement) | TBD | **DONE (S70)** |
| 17 | Revenue Engine: Property Management System | TBD | **DONE (S71-S77)** |
| 18 | R1: Flutter App Remake | ~16 | **DONE (S78)** — 33 role screens, design system, AppShell. |
| 19 | AI Layer: E1-E2 Universal Architecture + Dashboard Wiring | ~40 | **DONE (S78)** — 2 tables, z-intelligence (14 tools), Dashboard wired. |
| 20 | AI Layer: E5 Xactimate Estimates | ~50 | **DONE (S79)** — 5 tables, 6 Edge Functions, Flutter + Web CRM + portals. |
| 21 | AI Layer: E6 Bid Walkthrough Engine | ~50 | **DONE (S79)** — 5 tables, 4 Edge Functions, 12 Flutter screens, Web CRM + portals. |
| 22 | AI Layer: E3 Employee AI + Mobile AI | ~22 | **DONE (S80)** — 4 Edge Functions, team portal troubleshoot, Flutter AI chat, client portal widget. |
| 23 | AI Layer: E4 Growth Advisor | ~36 | **PAUSED (S80)** — 5 Edge Functions + 4 hooks + 4 pages written. Uncommitted. Phase E paused — AI goes last. |
| 24 | **D8: Estimates** | ~100+ | **DONE (S85-S89)** — D8a-D8j all complete. 10 tables, 5 EFs, all 5 apps wired. |
| 25 | Firebase→Supabase Migration | ~8-12 | **CODE DONE (S89)** — 4 EFs built. Manual: secrets, deploy, webhook URLs. |
| 26 | R1j: Mobile Backend Rewire | ~8-12 | PENDING — Connect 33 R1 screens to live data |
| 27 | F1: Calls (SignalWire) | ~40-55 | **DONE (S90)** — 9 tables, 5 EFs, CRM+team+client+ops pages. |
| 28 | F3: Meetings (LiveKit) | ~70 | **DONE (S90)** — 5 tables, 4 EFs, CRM+team+client+ops pages. |
| 29 | F4: Mobile Toolkit + Sketch/Bid + OSHA | ~120-140 | **DONE (S90)** — 10 tables, 3 EFs, CRM pages. Flutter mobile deferred. |
| 30 | F5: Integrations + Lead Aggregation | ~180+ | **DONE (S90)** — 25+ tables, 3 EFs, 8 CRM hooks+pages. API integrations deferred. |
| 31 | F6: Marketplace | ~80-120 | **DONE (S90)** — 5 tables, 1 EF, CRM+client pages. |
| 32 | F7: Home Portal | ~140-180 | **DONE (S90)** — 5 tables, client portal hook + 4 pages. |
| 33 | F9: Hiring System | ~18-22 | **DONE (S90)** — 3 tables, CRM hook+page. |
| 34 | F10: ZForge | TBD | **DONE (S90)** — 3 tables, 1 EF, CRM hook+page, portal expansion pages. |
| 35 | T: Programs Module | ~80 | **SPEC'D (S92) — NEXT** — 17 tables, 3 EFs, 10 sprints. Expansion/39_TPA_MODULE_SPEC.md |
| 36 | P: Recon / Property Intelligence Engine | ~96 | **SPEC'D (S93, expanded S97)** — 11 tables, 6 EFs, 10 sprints. Lead scoring, batch area scanning, storm intelligence, supplement checklist, multi-structure detection, confidence scoring. Expansion/40_PROPERTY_INTELLIGENCE_SPEC.md |
| 37 | SK: CAD-Grade Sketch Engine | ~240 | **EXPANDED (S101)** — 6 tables (was 3), ~46+ files, 14 sprints (SK1-SK14). LiDAR scan, trade layers, Konva web editor, auto-estimate, export, 3D view + **S101: multi-floor support, version history snapshots, photo pin placement, SVG export, team/client portal viewers** + site plan mode (SK12), trade-specific measurements/templates (SK13), field UX/ARCore/multi-user (SK14). $0/mo API costs confirmed. MagicPlan comparison in `memory/sketch-engine-deep-research-s101.md`. Expansion/46_SKETCH_ENGINE_SPEC.md |
| 37a | GC: Gantt & CPM Scheduling Engine | ~124 | **SPEC'D (S97)** — 12 tables, 4 EFs, 11 sprints (GC1-GC11). Full CPM, resource leveling, P6/MS Project import/export, real-time collab. Expansion/48_GANTT_CPM_SCHEDULER_SPEC.md |
| 38 | U: Unification & Feature Completion | ~432 | **EXPANDED (S100)** — 22 sprints (U1-U22). Portal unification, nav redesign, permission engine, Ledger completion, dashboard restoration, PDF/email/dead buttons, payment flow (expanded: Stripe Connect U7c, review system U7d, service agreements U7e, automation backend U7f), cross-system metrics, polish, form depth engine (U11), template/customization engine (U12), i18n 10 languages (U13), universal trade support (U14), S98 lost features (U15), **+ S100 additions: onboarding wizard (U16), data flow wiring (U17), dispatch board (U18), data import (U19), subcontractor mgmt (U20), calendar sync + notifications (U21), isolated feature wiring (U22)**. |
| 39 | G: Debug, QA & Hardening | ~100-200 | PENDING — After ALL building (T+P+SK+U). Full button-click audit, security, performance, cross-feature integration testing. |
| 39a | E/BA: Plan Review (AI Takeoff) | ~128 | **SPEC'D (S97)** — 6 tables, 3 EFs, 8 sprints (BA1-BA8). MitUNet + YOLOv12 + Claude. RunPod GPU. Expansion/47_BLUEPRINT_ANALYZER_SPEC.md |
| 40 | E: AI Layer Rebuild | TBD | PENDING — Deep spec session, full platform knowledge (after T+P+SK+U+G). E-review → BA1-BA8 → E1-E4. |
| 41 | **LAUNCH** | — | — |
| — | *POST-LAUNCH: F2 Website Builder (~60-90h), F8 Ops Portal 2-4 (~111h)* | — | F2 deferred S94 (maintenance burden). F8 internal tooling. |

**TOTAL PRE-LAUNCH: ~2,000+ hours (all phases A through launch)**

---

## CRITICAL DISCOVERIES

**Session 39 — Sprint A2: DevOps Phase 1:**
- **Environment config system built:** `lib/core/env.dart` (EnvConfig class), `env_template.dart` (placeholder), `env_dev/staging/prod.dart` (gitignored, real keys)
- **Web + Client Portal env templates:** `.env.example` files with Supabase vars created for both Next.js apps
- **Dependabot configured:** `.github/dependabot.yml` — weekly scans for pub (Flutter), npm (web-portal), npm (client-portal)
- **Gitignore hardened:** Root + app-level gitignores fixed to properly ignore real env files while allowing templates through
- **Flutter SDK:** Located at `C:/tools/flutter/` (not in PATH — use full path)
- **Manual step needed:** Create `zafto-staging` Supabase project, fill real keys into env files

**Session 38 — Sprint Specs Expansion:**
- **Execution system complete:** 05_EXECUTION_PLAYBOOK.md + 06_ARCHITECTURE_PATTERNS.md + 07_SPRINT_SPECS.md = everything needed for autonomous building
- **07_SPRINT_SPECS.md expanded to 6,600+ lines:** Phases A through E fully detailed

**Session 37 — Code Cleanup:**
- **Deleted 8 dead files (3,637 lines):** photo_service, email_service, pdf_service, stripe_service, firebase_config, offline_queue_service, role_service, user_service
- **Removed empty `lib/config/` directory**

**Session 36 — Deep Audit Findings:**
- **THREE Firebase projects** in codebase: `zafto-5c3f2` (DELETED), `zafto-2b563`, `zafto-electrical` — remaining 2 need migration
- **Duplicate models confirmed:** root models are more complete (job: 475 vs 155 lines, invoice: 552 vs 157, customer: 318 vs 150)

**Session 28 — Original Findings (updated S80):**
- ~~14 field tools = UI shells~~ → ALL 18 field tools wired to Supabase (B2+B3)
- ~~5 tools missing~~ → ALL 5 built: Materials Tracker, Daily Log, Punch List, Change Orders, Job Completion
- ~~90 screens, 0 wired end-to-end~~ → 33 role-based screens (R1 remake), core business + all field tools wired

## DOCS STATUS (All 8 Complete)

| Doc | Status |
|-----|--------|
| `00_HANDOFF.md` | COMPLETE — updated every session |
| `01_MASTER_BUILD_PLAN.md` | COMPLETE (updated S97) |
| `02_CIRCUIT_BLUEPRINT.md` | COMPLETE — updated S91 (Codemagic CI/CD, Dependabot) |
| `03_LIVE_STATUS.md` | COMPLETE (this file — updated S97) |
| `04_EXPANSION_SPECS.md` | COMPLETE (Session 36 — all 14 specs consolidated) |
| `05_EXECUTION_PLAYBOOK.md` | COMPLETE (Session 37 — session protocol, methodology, quality gates) |
| `06_ARCHITECTURE_PATTERNS.md` | COMPLETE (Session 37 — 14 code patterns with full examples) |
| `07_SPRINT_SPECS.md` | COMPLETE — 11,500+ lines, 200 sprints (198 + U23 + E5), Phases A through L + E5 fully detailed. Integration bridges added S103. |
| `Expansion/52_SYSTEM_INTEGRATION_MAP.md` | CREATED S103 — Master wiring document. Connectivity matrix, integration checklist, wiring tracker. MUST be referenced every sprint. |

---

CLAUDE: UPDATE THIS FILE AT END OF EVERY SESSION.
