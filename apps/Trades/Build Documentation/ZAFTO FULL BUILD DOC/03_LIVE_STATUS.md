# ZAFTO LIVE STATUS
## UPDATE THIS EVERY SESSION

**Last Updated:** February 8, 2026 (Session 89 — D8j portal integration COMPLETE. D8 Estimate Engine ALL DONE.)
**Current Phase:** BUILD — **Phases A-D ALL COMPLETE (including D8 Estimate Engine).** R1 COMPLETE. Phase E PAUSED. 102 tables. 30 migrations. 32 Edge Functions.
**Next Action:** FM (Firebase→Supabase migration) → F1 (Phone System).

---

## QUICK STATE

| Field | Value |
|-------|-------|
| **Phase** | BUILD — **Phases A-D ALL COMPLETE (including D8 Estimate Engine: D8a-D8j ALL DONE).** R1 COMPLETE. E1-E6 COMPLETE (PAUSED). 102 tables. 30 migrations. 32 Edge Functions deployed. Next: FM (Firebase Migration) → F1 (Phone System). |
| **Mobile App (Flutter)** | **R1 App Remake (S78):** 33 role-based screens, design system (8 widgets), AppShell with role switching. **E3c (S80):** ai_service.dart + z_chat_sheet.dart + ai_photo_analyzer.dart, Z FAB in AppShell. **E5f (S79):** Estimate entry screens. **E6b (S79):** 12 walkthrough screens + 4 annotation files + 4 sketch editor files. ALL core business wired. ALL 19 field tools wired. D2 Insurance: 3 screens. D5f Properties: 10 screens. `dart analyze` passes 0 errors. |
| **Web CRM (Next.js)** | **71 routes built.** 50+ pages wired to Supabase. 40+ hook files + 22 Z Console files. Auth+middleware DONE. UI Polish DONE. **D8d (S86):** use-estimates.ts hook + estimates list page + estimate editor (room-by-room, item browser, O&P/tax calc, insurance mode, preview). Sidebar: Estimates moved to OPERATIONS. **E2 (S78):** Z Console wired to z-intelligence. **E5b (S79):** Import + pricing pages. **E6f (S79):** Walkthrough list/detail/bid/workflow settings. **E4 (S80, UNCOMMITTED):** revenue-insights, growth, bid optimizer, equipment insights (4 pages + 4 hooks + sidebar updated). **D8i UI overhaul (S88):** collapsible sidebar groups, ZAFTO wordmark fix, Z FAB ambient glow, artifact side-by-side with chat, persistent new chat button, drag-to-resize panels. `npm run build` passes (71 routes, 0 errors). |
| **Client Portal (Next.js)** | **29 routes. 12 pages wired to Supabase. 12 hooks + mappers (6 base + 5 tenant + 1 AI).** Magic link auth. **E3d (S80):** AI chat widget (floating Z + slide-up panel) + use-ai-assistant.ts hook. `npm run build` passes (29 routes, 0 errors). `client.zafto.cloud`. |
| **Employee Field Portal (Next.js)** | **27 routes. 15 Supabase hooks. PWA-ready.** `team.zafto.app`. **D8j (S89):** Estimate hook (use-estimates.ts) + estimates list + estimate detail pages. **E3b (S80):** AI Troubleshooting Center — troubleshoot/page.tsx (1,364 lines, 5-tab UI: Diagnose/Photo/Code/Parts/Repair) + use-ai-troubleshoot.ts hook (254 lines). `npm run build` passes (27 routes, 0 errors). |
| **Ops Portal (Next.js)** | **18 dashboard pages + login. 20 routes. `npm run build` passes (0 errors).** `ops.zafto.cloud`. Deep navy/teal theme. super_admin role gate. **D8h:** Code contributions admin (filter/search/verify/reject/promote). **D8i:** Pricing engine admin (MSA regions, pricing ingestion). **D8j:** Estimate analytics dashboard (platform-wide stats, type breakdown, code DB health). |
| **Field Tools** | **19 total. ALL wired.** 14 original (B2a-d) + 2 new (B3a: Materials+DailyLog) + 3 new (B3b: PunchList+ChangeOrders+JobCompletion). 0 remaining. |
| **Database** | Supabase (PostgreSQL). 2 projects (dev + prod). **102 tables DEPLOYED** (79 D-phase + 10 D8 Estimate Engine + 1 D8i msa_regions + 2 E1 AI + 5 E5 Xactimate + 5 E6 Walkthrough). RLS + audit on all. 30 migration files. Supabase CLI linked to dev. 3 test users + 1 company seeded. 55 COA accounts + 26 tax categories + 77 Xactimate codes + 14 walkthrough templates + 86 estimate categories + 216 estimate items + 16 estimate units + 28 labor rates + 5,616 estimate_pricing rows (national + 25 MSAs) seeded. fn_zip_to_msa + fn_get_item_pricing Postgres functions. |
| **Edge Functions** | **32 DEPLOYED:** ZBooks (5), PM (3), z-intelligence (1, 14 tools), Xactimate (6), Walkthrough (4), AI Troubleshooting (4), D8 estimate (5: export-estimate-pdf + import-esx + export-esx + code-verify + pricing-ingest), plus 3 crowd-source/pricing. **5 LOCAL (E4, uncommitted):** ai-revenue-insights, ai-customer-insights, ai-bid-optimizer, ai-equipment-insights, ai-growth-actions (2,133 lines total). **2 NOT DEPLOYED:** dead-man-switch (SMS), send-notification. |
| **Backend Connected** | Auth + Customers + Jobs + Invoices + Bids + Time Clock + Calendar ALL wired. ALL 19 field tools wired. D2 Insurance: 7 tables. D4 ZBooks: GL engine + 15 tables. D5 PM: 18 tables. E1 AI: z_threads + z_messages. E5 Xactimate: 5 tables. E6 Walkthrough: 5 tables. |
| **DevOps** | **C1 DONE (S58):** Sentry in all 4 apps. CI/CD: 4 workflows. 154 model tests. **C2 NEAR COMPLETE (S60-S61):** RBAC middleware on all portals. **C3 DONE (S59):** Ops Portal. **C5 DONE (S59):** Incident response. |
| **Blocker** | **Phase E PAUSED.** AI goes last — after F+G. Phase F sprint specs need writing. API signups 10 active (Supabase, Unwrangle, Plaid, Google, SignalWire, LiveKit, Mapbox, Stripe, Anthropic, RevenueCat). **3 need migration from Firebase→Supabase** (Stripe, Anthropic keys in Firebase secrets). Sentry DSN empty. **Xactimate: DECIDED** — Two-mode estimate engine (D8). Clean room spec at `SPRINT/07_ESTIMATE_ENGINE_SPEC.md`. |
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
| 12 | Debug & QA with real data | ~20-30 | **NEAR COMPLETE (S60-S61)** |
| 13 | Ops Portal Phase 1 (18 pages, pre-launch) | ~40 | **DONE (S59)** |
| 14 | Security hardening (email migration, passwords, YubiKeys) | ~4 | PENDING |
| 15 | Revenue Engine: Job Types + Insurance + Enterprise | ~217 | **ALL DONE (S62-S69)** — D1+D2+D3+D6+D7a complete. |
| 16 | Revenue Engine: ZBooks (QB replacement) | TBD | **DONE (S70)** |
| 17 | Revenue Engine: Property Management System | TBD | **DONE (S71-S77)** |
| 18 | R1: Flutter App Remake | ~16 | **DONE (S78)** — 33 role screens, design system, AppShell. |
| 19 | AI Layer: E1-E2 Universal Architecture + Z Console Wiring | ~40 | **DONE (S78)** — 2 tables, z-intelligence (14 tools), Z Console wired. |
| 20 | AI Layer: E5 Xactimate Estimate Engine | ~50 | **DONE (S79)** — 5 tables, 6 Edge Functions, Flutter + Web CRM + portals. |
| 21 | AI Layer: E6 Bid Walkthrough Engine | ~50 | **DONE (S79)** — 5 tables, 4 Edge Functions, 12 Flutter screens, Web CRM + portals. |
| 22 | AI Layer: E3 Employee AI + Mobile AI | ~22 | **DONE (S80)** — 4 Edge Functions, team portal troubleshoot, Flutter AI chat, client portal widget. |
| 23 | AI Layer: E4 Growth Advisor | ~36 | **IN PROGRESS (S80)** — 5 Edge Functions + 4 hooks + 4 pages written. Uncommitted. Need deploy + test. |
| 24 | **D8: Estimate Engine** | ~100+ | **DONE (S85-S89)** — D8a-D8j all complete. 10 tables, 5 EFs, all 5 apps wired. |
| 25 | Firebase→Supabase Migration | ~8-12 | PENDING — 11 Cloud Functions (Stripe, RevenueCat, AI scans) |
| 26 | R1j: Mobile Backend Rewire | ~8-12 | PENDING — Connect 33 R1 screens to live data |
| 27 | F1: Phone System (SignalWire) | ~40-55 | PENDING — Voice, SMS, Fax, AI receptionist |
| 28 | F3: Meeting Rooms (LiveKit) | ~70 | PENDING — Context-aware video, booking, AI transcription |
| 29 | F4: Mobile Toolkit + Sketch/Bid + OSHA | ~120-140 | PENDING — 25 tools, sketch→bid flow, OSHA compliance |
| 30 | F5: Business OS + Lead Aggregation | ~180+ | PENDING — 9 systems + free API lead sources |
| 31 | F6: Marketplace | ~80-120 | PENDING — Equipment AI, lead gen, contractor bidding |
| 32 | F7: ZAFTO Home | ~140-180 | PENDING — Homeowner property intelligence |
| 33 | F9: Hiring System | ~18-22 | PENDING — Indeed/LinkedIn/ZipRecruiter, Checkr, E-Verify |
| 34 | F10: ZDocs | TBD | PENDING — PDF-first doc suite (second to last) |
| 35 | G: Debug, QA & Hardening | ~100-200 | PENDING |
| 36 | E: AI Layer Rebuild | TBD | PENDING — Deep spec session, full platform knowledge |
| 37 | F2: Website Builder (after AI) | ~60-90 | PENDING — AI content generation, templates |
| 38 | F8: Ops Portal 2-4 (truly last) | ~111 | PENDING — Marketing, treasury, legal, dev |
| 39 | **LAUNCH** | — | — |

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
- ~~14 field tools = UI shells~~ → ALL 19 field tools wired to Supabase (B2+B3)
- **Dead Man Switch** = SAFETY CRITICAL. Timer + compliance record saves. **SMS Edge Function still TODO.**
- ~~5 tools missing~~ → ALL 5 built: Materials Tracker, Daily Log, Punch List, Change Orders, Job Completion
- ~~90 screens, 0 wired end-to-end~~ → 33 role-based screens (R1 remake), core business + all field tools wired

## DOCS STATUS (All 8 Complete)

| Doc | Status |
|-----|--------|
| `00_HANDOFF.md` | COMPLETE — updated every session |
| `01_MASTER_BUILD_PLAN.md` | COMPLETE (Session 35) |
| `02_CIRCUIT_BLUEPRINT.md` | COMPLETE — updated S88 (102 tables, 32 Edge Functions, D8i pricing engine) |
| `03_LIVE_STATUS.md` | COMPLETE (this file — updated S88) |
| `04_EXPANSION_SPECS.md` | COMPLETE (Session 36 — all 14 specs consolidated) |
| `05_EXECUTION_PLAYBOOK.md` | COMPLETE (Session 37 — session protocol, methodology, quality gates) |
| `06_ARCHITECTURE_PATTERNS.md` | COMPLETE (Session 37 — 14 code patterns with full examples) |
| `07_SPRINT_SPECS.md` | COMPLETE — 6,600+ lines, Phases A through E fully detailed |

---

CLAUDE: UPDATE THIS FILE AT END OF EVERY SESSION.
