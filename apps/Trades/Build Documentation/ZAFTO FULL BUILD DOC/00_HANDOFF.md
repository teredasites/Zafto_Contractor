# ZAFTO SESSION HANDOFF
## THE ONLY DOC YOU READ FIRST — EVERY SESSION
### Last Updated: February 22, 2026 (Session 156+ — **DEPTH29-43 ALL COMPLETE + DATA-ARCH1-4 ALL COMPLETE.** DEPTH26: address-to-sketch, FEMA flood, tree canopy, satellite, utilities, roof plan, commercial detection, bidirectional recon sync. DEPTH27: crash recovery auto-save — `auto_save_entries` table, `auto-save-recover` EF, Flutter AutoSaveService+provider, CRM+team useAutoSave hooks, ops useAutoSaveOps hook. DEPTH28: Property Recon Mega-Expansion — 9 new tables (api_registry, api_health_events, api_health_reports, api_usage_log, property_profiles, permit_history, weather_intelligence, material_price_indices, trade_auto_scopes), 32 API seed data, 4 new EFs (api-health-check, recon-property-intelligence, recon-auto-scope, recon-storm-hunter), shared `_shared/api-fleet.ts` (fleetFetch pattern), 3 new CRM hooks + use-property-scan.ts expanded (30 trades), 2 team-portal hooks, 1 ops-portal hook (use-api-fleet-health), Flutter model+repo+provider. All builds clean. Commits: 60d5786→739ba1e. Previous: Session 152+ DEPTH8-25+SEC+PRICING. Previous: Session 152 — **DEPTH7 COMMUNICATION & NOTIFICATION DEPTH AUDIT + 8 CORRECTIONS.** Audited 25+ files across all 5 apps (14 EFs, 7 web hooks, 4 team hooks, 3 client hooks, Flutter mobile). 8 corrections applied: [SEC] fax webhook secret verification, [BUG] client-portal sendMessage missing toNumber, [BUG] team-portal voicemail FK, notification preference enforcement + 6 new trigger types (12 total), SMS unreadCount tracking, ring groups wired into signalwire-voice (3 strategies), email template auto-seeding. 2 deferred: campaign batch send (DEPTH8), push notifications (too large). All 3 portals build clean. Commit: a577866. Previous: Session 151 — Firebase removal. Previous: Session 150 — **ZAFTO FLIP STANDALONE PLATFORM RESEARCH + SPRINT SPEC.** 5 Opus agents (~250+ searches). PHASE FLIP-PORTAL: 11 sprints (~292h, 10 tables, ~8 EFs, ~47 routes, ~20 Flutter screens). flip.zafto.cloud + Flutter app. Solo $69.99/mo, Team $149.99/mo, NO free tier. Ecosystem wiring: Ledger, ZForge, Insurance Highway, messaging, Recon, Sketch, contractor flywheel, realtor handoff. 200 seed items, 50-state costs, i18n. Investor app rejected (market crowded). 63,182 lines. 2 commits. Previous: Session 149 — **COMM13+COMM14 REALTOR INSURANCE HIGHWAY + 7 HOMEOWNER WIRING FIXES.** Completed S148 crash leftovers: COMM13 (~24h, realtor claim access + disclosure reviews), COMM14 (~20h, 50-state disclosure intelligence + deadline engine), 7 homeowner wiring fixes across COMM2/6/8/9/11/CLIENT-HVN4/15. Insurance Highway now 10/10 all entities. 61,099 lines. Commit: 4e2ca04. Previous: Session 148 — **COMM1-12 + CLIENT + CLIENT-HVN SPEC ASSEMBLY + 69-FINDING AUDIT.** Assembled 3 new phases into 07_SPRINT_SPECS.md (40K→60K lines). PHASE CLIENT S146 expanded (17 sprints, ~466h), PHASE CLIENT-HVN S148 heaven layer (17 sprints, ~234h), PHASE COMM Insurance Highway (12 sprints, ~368h). 6 missing sprints written (COMM8-9, CLIENT-HVN8-10,14). Audit: 69 findings (16 CRITICAL, 27 HIGH). All fixes applied. 5 commits: bb45d91, 96d2938, 8eb6acc, 6fadd3b, 671625d. Previous: Session 147 — **ADJ1-ADJ12 FULL AUDIT + 178 FIXES.** 4 Opus audit + 4 Opus fix agents. 185 findings (21 CRIT, 60 HIGH). Commit: e2c31be. Previous: S146 — 5 parallel Opus audit agents reviewed all 10 realtor expansion sprints. Found 35 CRITICAL + 63 HIGH + 46 MEDIUM + 21 LOW issues. Average score: 6.5/10. Applied 44 fixes: `deleted_at IS NULL` added to ALL SELECT/UPDATE RLS policies (~40 policies), `NOT NULL` on all `created_at`/`updated_at`, RE27 FK reorder (voicemail_recordings before call_records), RE26 client portal RLS (4 new policies), RE27 missing `updated_at` columns, RE29 `document_findings` missing `updated_at`/`deleted_at`, RE30 `storm_outreach_messages` missing `updated_at`/`deleted_at`, RE23 `transaction_id` + `is_favorite` (S143), RE22 INSERT policy restricted, RE28 agent_user_id scoping + public SELECT policies, RE30 `storm_events` IF NOT EXISTS + UNIQUE dedup, RE24 AI dependency note. Phase Audit Summary hours corrected (~160h→~236h). Previous: S145 ZFORGE fixes + RE21-RE30 expansion. 127 migrations. ~222 tables. 98 EFs.)

---

## SESSION START PROTOCOL (MANDATORY — DO NOT SKIP ANY STEP)

1. **Read THIS doc completely** — understand current position, known gaps, rules
2. **Open `07_SPRINT_SPECS.md`** — go to the CURRENT EXECUTION POINT listed below
3. **Read the current sprint's checklist** — understand what's done [x] and what's next [ ]
4. **Check `Expansion/52_SYSTEM_INTEGRATION_MAP.md`** — verify current phase's required connections are in sprint spec
5. **Verify code matches** — run targeted checks (dart analyze, npm run build, grep for key files)
6. **Resume from the NEXT UNCHECKED `[ ]` ITEM** — not from memory, not from vibes, from the checklist

---

## CURRENT EXECUTION POINT

| Field | Value |
|-------|-------|
| **Sprint** | **S157: RECON LIVE IMPROVEMENTS (IN PROGRESS).** ATTOM API activated (free 30-day trial, 500 calls/day, key set as Supabase secret). Fixed ATTOM integration: split address format (address1=street, address2=city,state,zip — was passing full address as address1 with empty address2), corrected field paths (summary.yearbuilt, proper sub-object parsing), added real error logging. 5 prior RECON commits from S156+ crash session preserved (parallelize APIs, fire-and-forget storage, NWS alerts, census demographics, flood zone/external links). Vercel deploy discipline rule established: NO deploys unless owner asks, use bat file/npm run dev for local testing. Commit: f0ac1bb. **Previous:** S156+: DEPTH29-43 + DATA-ARCH1-4 ALL COMPLETE.** DATA-ARCH1: Data source registry (3 tables, 16 seeded APIs, orchestrator EF, ops hook). DATA-ARCH2: 5 canonical domain tables (addresses/weather/compliance/property_intel/market_data) + 5 normalization functions + computed columns (is_workable, is_stale). DATA-ARCH3: api_cache table, api-gateway EF (10 source adapters, fallback chain primary→fallback→stale→unavailable), rate limit tracking, cache functions. DATA-ARCH4: ops portal /dashboard/data-intelligence (source health, ingestion timeline, metrics, cost tracker, coverage map, manual controls). Commits: 8f9910c→066e466. |
| **Sub-step** | **S157: RECON LIVE IMPROVEMENTS (IN PROGRESS — pick up next session)** → ATTOM data needs visual verification (scan an address, confirm beds/baths/sqft/year appearing). Census data was empty on test — investigate. Then resume build order: **INTEG6(NEXT)** → INTEG2→3→4→7→8 → S135-ENTITY → RE1-20 → RE21-33 → ADJ1-12 → INTEG1 → FLIP1-6 → **FLIP-PORTAL1-11(S150)** → INTEG5 → SEC2-5 → LAUNCH2-6 → LAUNCH8 → G → JUR → E → FLIP5+DEPTH40-AI+DEPTH44 → SEC9-10 → ZERO1-9 → LAUNCH7 → LAUNCH-FLAVORS → APP-DEPTH → **[PITR ON]** → SHIP. |
| **Sprint Specs Location** | `07_SPRINT_SPECS.md` (37,565 lines) → Phases: W (~11200), J (~12314), L (~13223), U-REP/SUB/FIN/MAT/LOG/CO (~14759-16465), GC-WX (~16466), U-TT (~16941), P-DT (~18286), FIELD (~18956), REST (~19089), NICHE (~19137), ZFORGE-FRESH (~19295), SHARED (~19842), DEPTH (~21300), SEC (~29245), ZERO (~29511), LAUNCH (~29658), ROUTE/CHEM/DRAW/SEL (~31141-31878), RE21-RE30 (~32641-36700). Summary table at PHASE AUDIT SUMMARY (~37200+). |
| **Status** | Phases A-D + F + T + P + SK + GC + U + W + J + L ALL DONE. Phase INS COMPLETE. Phase G: G1-G5 auto DONE, G10 DONE. R1 DONE. FM code done. Phase E PAUSED. **~240 tables. 133 migration files.** 105 Edge Functions. **154 CRM routes. 45 team routes. 46 client routes. 34 ops routes. 135 CRM hooks. 31 team hooks. 7 ops hooks.** **SEC1+SEC6-8+SEC-AUDIT-1→6+Source Protection DONE. FIELD1-5 DONE. REST1+REST2 DONE. NICHE1+NICHE2 DONE. DEPTH1-43 ALL DONE (S131-S155+). DATA-ARCH1-4 ALL DONE (S155-S156). P-FIX1+A11Y-1→3+LEGAL-1+3+4+INFRA-4+5+TI-3 ALL DONE.** 25 CLAUDE.md rules (Rule #24: ZERO HARDCODED PRICING). **~281 sprints (~5,486h).** Next: INTEG6. |
| **Last Completed** | S153+: **DEPTH26-28 ALL COMPLETE.** DEPTH26: property blueprint lookup (address-to-sketch generation, FEMA flood zones, tree canopy, satellite import, utility auto-placement, roof plan, commercial detection, bidirectional recon sync). DEPTH27: crash recovery auto-save system (auto_save_entries table, auto-save-recover EF, Flutter AutoSaveService+provider, CRM+team useAutoSave hooks, ops useAutoSaveOps hook). DEPTH28: Property Recon Mega-Expansion (9 new tables, 32 API seed data, 4 EFs, shared api-fleet.ts with fleetFetch pattern, 3+1 CRM hooks expanded to 30 trades, 2 team hooks, 1 ops hook, Flutter model+repo+provider). All 4 portal builds clean + dart analyze clean. Commits: 60d5786→739ba1e. Previous: S152+: DEPTH8-25 ALL COMPLETE + SEC SOURCE PROTECTION + PRICING REWRITE. 19 corrections total across DEPTH8-14 (6+4+1 fixes). DEPTH15-24 all audited clean. DEPTH25: 120+ commercial symbols, 16 building templates (office/retail/warehouse/hospital/hotel/school/etc), flat roof engine, fire protection, ADA compliance, parking lot. SEC: 7-layer source protection shield on all 4 portals + right-click allow fix. **CLAUDE.md Rule #24: ZERO HARDCODED PRICING.** estimate-generator.ts completely rewritten — all pricing from DB via loadPricingMap() with company→MSA→national cascade. trade-formulas.ts costPerSqFt removed. Previous: S152 DEPTH7: 8 corrections (fax webhook, sendMessage, voicemail FK, notification prefs, ring groups, email templates). Commit: a577866. Previous: S151: Firebase removal — all services migrated to Supabase. Previous: S150: **ZAFTO FLIP STANDALONE PLATFORM RESEARCH + SPRINT SPEC.** FLIP-PORTAL1: Foundation (8 tables, auth, RBAC, portal scaffold). FLIP-PORTAL2: Flip Score engine + Carfax report + guided financial model + Reality Engine. FLIP-PORTAL3: Deal feed + Flip Radar map + alerts. FLIP-PORTAL4: Rehab scope builder + Sketch Engine + Recon + permits + contractor marketplace. FLIP-PORTAL5: Rehab tracker + budget + photos + holding cost death clock. FLIP-PORTAL6: Selling + settlement + tax calculator + portfolio. FLIP-PORTAL7: Education + contextual explainers + 50 civilian calculators. FLIP-PORTAL8: Flutter app (Quick Scan, Flip Radar, camera, offline). FLIP-PORTAL9: Ecosystem wiring (Ledger, ZForge 8 templates, Insurance Highway, messaging, notifications). FLIP-PORTAL10: Seed data (200 items, 50-state costs, financing terms, permits), team tier, CSV import, 10-locale i18n. FLIP-PORTAL11: Realtor handoff pipeline, contractor lead flywheel, reputation scores, integration map, onboarding wizard. 6 research files saved to memory. Investor standalone app evaluated and REJECTED (market crowded with 20+ funded free/cheap competitors — Stessa, Baselane, RentRedi). 07_SPRINT_SPECS.md: 62,569→63,182 lines. ~281 sprints (~5,486h). 2 commits: 319aa4f, 1eb8aac. Previous: S149: **COMM13+COMM14 REALTOR INSURANCE HIGHWAY + 7 HOMEOWNER WIRING FIXES.** COMM13 (~24h, 2 tables, 4 EFs, 4 Flutter, 6 web routes). COMM14 (~20h, 3 tables, 3 EFs, 50-state seed, 3 Flutter, 3 web routes). 7 homeowner wiring fixes (COMM2/6/8/9/11 + CLIENT-HVN4/15). Insurance Highway 10/10 all entities. RE31-33 realtor platform expansion: RE31 Listing Intelligence+Marketing (~32h, 5 tables, 4 EFs), RE32 Specialist Workflows+Daily Priority Engine (~24h, 3 tables, 3 EFs), RE33 Referral Network+Enterprise (~20h, 3 tables, 3 EFs). All wire into Insurance Highway. Commits: 4e2ca04, aeb1adc. Previous: S148: **COMM1-12 + CLIENT + CLIENT-HVN SPEC ASSEMBLY + 69-FINDING AUDIT.** Assembled 3 new phases into 07_SPRINT_SPECS.md via Python scripts (crash-proof). 6 missing sprints written manually (COMM8-9, CLIENT-HVN8-10,14). Full audit by 2 Opus agents: 69 findings (16 CRIT, 27 HIGH, 18 MED, 13 LOW). All fixes applied: CLIENT-HVN namespace rename (17 headers), COMM11 participant/urgent fixes, FK corrections (5 client_equipment refs), Security Verification sections (4 added), table collision annotations (4), COMM12 RLS/trigger/EF annotations (3), missing deleted_at annotations (16 COMM tables), company_id documentation. Re-audit: 9/9 PASS. 5 commits. Previous: S147: **ADJ1-ADJ12 FULL AUDIT + 178 FIXES.** 4 Opus audit agents (185 findings: 21 CRIT, 60 HIGH, avg 7.3/10). 4 Opus fix agents applied 178 checklist items + 10 inline SQL corrections. CRITICAL fixes: ADJ5 SECURITY DEFINER search_path + auth.uid(), ADJ10 system template SELECT deleted_at, ADJ11 RLS operator precedence + cross-company audit, ADJ12 EncryptedBox + push token expiry. Commit: e2c31be. Previous: S146: **RE21-RE30 FULL AUDIT + 135 FIXES (2 passes).** Pass 1 (44 fixes): `deleted_at IS NULL` in ~40 RLS policies, `NOT NULL` timestamps, RE27 FK reorder, RE26 client portal RLS (4 policies), RE27+RE29+RE30 missing columns, RE23 S143 compliance, RE22 INSERT restriction, RE28 agent scoping + public access, RE30 collision fix. Pass 2 (91 fixes): CORS on all user-facing EFs, 4-state on all ~40 Flutter screens, web hooks (`use-*.ts`) on all 10 sprints, rate limits, input validation, compound indexes, JSONB schemas, Sentry logging, optimistic locking, feature flag gating, DNC seed data, deployment status flow (RE28), privacy jurisdictions (RE22), INTEG6 dependency (RE26), cache specs, push notification channels. Phase Audit Summary corrected (~160h→~236h). 2 commits: bdf391e, 59cd007. Previous: S145 ZFORGE fixes + RE21-RE30 expansion. Previous: S144 contractor expansion+ZFORGE-FRESH+SHARED+CUST9+RE1-RE20. Previous: **CUST9 SPEC'D + RE1-RE20 FULLY SPEC'D.** CUST9: Custom App Builder module configuration engine (48h, 38 edge cases, 5 Opus research agents, entity-type agnostic). RE1-RE20: Full realtor platform expanded from 1-line stubs to enterprise checklists (594h, ~100 new tables, ~70 EFs, ~80 Flutter screens, 5,823 lines). Key features: Smart CMA Engine (RE3), Autonomous Transaction Engine (RE4-RE5), Seller Finder Engine (RE6-RE7), Commission Engine (RE8), Dispatch Engine with guest contractor flow (RE9), Listing Management with open house + lifecycle (RE10), Buyer Management with NAR compliance (RE11), Marketing Factory (RE12), Brokerage Admin (RE13), Lead Gen Pipeline (RE14), Cross-Platform Intelligence (RE15), Cascading Settings (RE16), Recon/Sketch/PM access (RE17), Mobile screens (RE18), Polish (RE19), QA+Security (RE20). UI decision: high-gloss near-black dark theme (Vercel-style). All legally defensive (NAR, Fair Housing, DNC/TCPA, CAN-SPAM hard gates). Previous: S143 continued: **DEPTH6 COMPLETE (calculator & template depth verification).** HVAC duct sizing formula fixed, disclaimer footer added to scaffold, 2 thin templates expanded. Audit: 1,073 calcs (avg 8.4/10 depth), 25 templates (code refs 100% accurate). Critical gap: 0 restoration calcs. Previous: DEPTH5 form depth verification — 39 CRM + 44 Flutter + 16 team + 7 client portal forms vs 28 DB tables (~519 fields). 3 critical forms fixed: Leads 35%→76%, Applicants 28%→60%, Change Orders 58%→83%. "Show all fields" toggle architectural gap documented. Previous: DEPTH3+4 complete, TI-3 complete. Previous: S142: **P-FIX1 COMPLETE.** 3 shared modules (lead-scoring.ts, api-cost-logger.ts, api-rate-guard.ts). scan_cache + api_cost_log + api_rate_limits wired into property-lookup. All 5 Recon EFs migrated to shared CORS. Abstract PropertyScanRepositoryInterface. 65 lines inline scoring replaced with shared module in area-scan. Dual serve() bug was FALSE ALARM. 2 commits. Previous: S138: **FULL PROJECT WEAKNESS AUDIT + ECOSYSTEM METHODOLOGY HARDENING (no code, all spec/doc work).** 5 Opus audit agents → 103 findings (20 CRITICAL, 31 HIGH). SEC-AUDIT-1→6 sprint spec (~28h). Enterprise methodology: CLAUDE.md 8→18 rules (security template, 3-layer, expand-contract, feature flags, webhook idempotency, soft delete CI, fail-closed auth, shared types, mobile compat, optimistic locking). 6 ecosystem gaps spec'd: shared type system (INFRA-3+5), mobile backward compat (INFRA-5), optimistic locking (INFRA-5), full-text search tsvector (INFRA-4), data lifecycle/GDPR/CCPA (LAUNCH8), performance budget (INFRA-4+ZERO1). INFRA: 8h→20h. LAUNCH8: 12h→20h. ZERO1: 8h→12h. Audit files: `memory/s138-*-audit.md` (6 files). 4 commits: f42c295, 945a3b6, c869b1b, 4e9f165. S137 (crashed): INFRA-1→5 spec + enterprise infrastructure research. Previous: S135: **API GAP RESEARCH + SPRINT SPECS (crashed at 3% context).** 16 entity gap sprints committed (ROUTE1, CHEM1, DRAW1, SEL1, TC1, SHOW1, ADJ-SUP1, ADJ-DESK1, INS-PHOTO1, INS-TEMPLATE1, INS-VOICE1, INS-FLOOR1, HO-MAINT1, HO-VENDOR1, HO-INSURE1, HO-LAND). 4 DATA-ARCH sprints committed. Master API registry: 395 APIs. Feature-API cross-reference: 187 gaps. S134: Entity workflow research (5 Opus, 104 types, crashed). S133: Pricing DB research. S132: Ecosystem audit. S131: **DEPTH1 COMPLETE + SEC1+SEC6-8 + FIELD1-5.** SEC1: Storage bucket RLS (8 buckets, company-scoped). Persistent rate limiter (table-based, atomic RPC, pg_cron cleanup). Equipment database write policy hardened. Rate limiter wired into 6 priority EFs. Auth added to lead-aggregator. Created `_shared/rate-limiter.ts` + `_shared/cors.ts`. SEC6-8: EF auth + CORS + request validation. FIELD1: Real-time messaging system — conversations + messages + conversation_members tables. 3 Flutter screens. CRM team-chat rewrite (conversation-based). Team portal messages page. Bottom nav Messages tab (owner/tech/inspector). "Message Team" on job detail. FIELD2: Equipment checkout — equipment_items + equipment_checkouts tables, RLS, auto-holder trigger. 4 Flutter screens + model + repo + provider. CRM /dashboard/tool-checkout page. Team portal /dashboard/tool-checkout. Sidebar wiring both portals. More menu links in Flutter. All builds pass. 5 commits. Previous: S130: **OWNER DIRECTIVES.** 27 items from owner's handwritten notes (lost in S129 crash, retyped). 8 new DEPTH sprints created (DEPTH37-44, ~140h total): tablet/mobile responsive overhaul, time clock permission adjustment, signature system + DocuSign replacement, universal marketplace aggregator (Phase E dep), backup fortress (triple redundancy), storage tiering + metering, sketch engine file compatibility, AI-gated features + ticket system (Phase E dep). 12 additions to existing sprints complementing (not overwriting) existing specs. Legal labeling standard from owner's legal analysis document integrated into SEC10. All items clearly labeled "S130 Owner Directive Additions." Phase audit summary updated: ~102 sprints, ~1,716h. Previous: S129: **FULL ZAFTO REALTOR PLATFORM SPEC.** 9 parallel Opus research agents covered competitors, APIs, MLS, brokerage management, CRM, proptech flagships, trust account legal risk. Created `Expansion/53_REALTOR_PLATFORM_SPEC.md` (28 sections, ~444h, 20 sprints RE1-RE20). 3 flagship engines: Smart CMA Engine (Redfin+FRED+Census+BLS = instant CMA with neighborhood story), Autonomous Transaction Engine (Domino's tracker + document management + compliance), Seller Finder Engine (public records + social signals → pre-market leads at ~$0.02/record vs competitors $99-500/mo). Brokerage RBAC (8 roles), commission tracking engine (NOT trust accounts — legal risk too high per research), cross-platform intelligence sharing with Zafto Contractor users, dispatched contractors get same field tools using realtor's AI budget. JUR4 sprint added (~14h) for 50-state real estate compliance: disclosures, agency rules, attorney states, commission regulations, license reciprocity. Revenue: Solo $99/mo, Team $299/mo, Brokerage $999/mo. REALTOR1-3 superseded. Previous: S128: **FLIP-IT REALITY ENGINE + DEEP RESEARCH.** Deep research (3 parallel agents) on real-world flip failures — ATTOM data shows median leveraged flip LOSES $40K after all costs, 22% failure rate, 70% first-timers break even or lose. FLIP4 reframed from "investor attraction" to "deal packaging + distribution." Created FLIP6 (~20h Reality Engine): true net P&L (full cost waterfall, every line item visible), tax impact calculator (dealer vs investor, SE tax warning), contractor labor advantage display (Zafto estimates vs national avg), financing comparison (cash vs hard money vs conventional vs BRRRR), 50% Rule alert (code compliance trap), code cascade predictor (property age × scope → forced upgrades), contingency auto-set by property age, over-improvement warning (neighborhood ceiling), multiple exit strategy analysis (sell/rent/price reduction with GREEN/YELLOW/RED), opportunity cost comparison (flip ROI vs S&P/rentals/passive), market health indicators, material tariff adjustment. Research saved to memory. Previous: S127: **PROPERTY PRESERVATION + MOLD REMEDIATION SPRINT SPECS.** Foreclosures up 14% YoY (367K filings 2025), 26% starts Jan 2026. Created DEPTH34 (~52h): full PP module — 25+ work order types, configurable smart photo system (Quick/Standard/Full Protection modes with GPS+timestamp, same-angle matching, auto-naming per national), national company profiles (Safeguard/MCS/Cyprexx/NFR/Xome), winterization assistant (dry/wet/steam + DIY pressure test gauge + 30-min timer + antifreeze calc), boiler/furnace troubleshooter (all major models, error code lookup, flowcharts, age decoder), sump pump install assistant, stripped property estimators (copper/PEX repipe, electrical rewire, HVAC, water heater), debris estimation calculator (room-by-room + sq ft + 5-level hoarding scale + weight + dumpster recommender + recon data integration), chargeback tracker + dispute system, payment tracking across nationals, utility/fuel coordination, vendor application helper, REO realtor finder, securing reference (Kwikset bank codes, MFS Supply sourcing), board-up calculator. Created DEPTH35 (~28h): mold remediation — IICRC S520 levels 1-3, moisture mapping with heat map, containment/remediation checklists, equipment tracking, lab sample tracking, clearance certificates (PDF), state licensing DB (50 states), scope of work templates, insurance claim format. Created DEPTH36 (~8h): disposal/dump finder — cheapest per ton for all waste types, scrap/recycling value finder, route optimization, receipt tracking + cost analytics. UX: job-context tool surfacing (PP job → PP tools appear) + pinned favorites system. Research: MFS Supply products, Kwikset KW-1 bank codes, pressure test procedures, HUD/Fannie/VA allowables by state, 5-level hoarding scale with CY matrices, dumpster sizing, company-specific portal requirements. |
| **Session Count** | 157 |
| **Tables** | ~240 (+9 from DATA-ARCH: data_sources, data_ingestion_log, api_gateway_metrics, api_cache, canonical_addresses, canonical_weather, canonical_compliance, canonical_property_intel, canonical_market_data). |
| **Migration Files** | 133 total. Latest: DATA-ARCH3 api_cache + gateway functions (migration 133). |

## CRITICAL: AI GOES LAST — BUILD ORDER CORRECTED (S80)

**Owner directive (S80):** Phase E (AI Layer) was started prematurely. AI must be built AFTER every platform feature exists (Phase F) and is debugged (Phase G). AI needs to know every feature like the back of its hand — every table, every screen, every workflow — so it can do literally anything a user asks within the program. Deep AI spec session required before resuming Phase E.

**Correct build order: A(DONE) → B(DONE) → C(DONE) → D(DONE — including D8 Estimates) → R1(DONE) → FM(CODE DONE, manual pending) → F(ALL CODE COMPLETE) → T(COMPLETE) → P(ZSCAN + DIGITAL TWIN EXT, SPEC'D, NEXT) → SK(SKETCH ENGINE, SPEC'D) → GC(GANTT/CPM + WEATHER EXT, SPEC'D) → U(UNIFICATION + REP + SUB + FIN + MAT + LOG + CO + TT EXTENSIONS) → W(WARRANTY + PREDICTIVE MAINTENANCE) → J(JOB INTELLIGENCE + SMART PRICING) → L(PERMITS + COMPLIANCE + LIENS + CE) → G(QA/HARDEN EVERYTHING) → JUR(JURISDICTION AWARENESS — state code adoptions, weekly scanner, retrofit all features) → E(AI LAST: E-review → BA1-BA8 Plan Review → E1-E4) → LAUNCH. F2 (Website Builder) DEFERRED TO POST-LAUNCH (S94 owner directive). F8 (Ops Portal 2-4) also post-launch.**

**Phase E premature work (committed, dormant in codebase):**
- E1-E2: z-intelligence EF (14 tools), Dashboard wired, z_threads/z_messages tables (S78)
- E3: 4 troubleshooting EFs, team portal troubleshoot page, Flutter AI chat, client portal widget (S80)
- E4: 5 growth advisor EFs + 4 CRM pages (S80, not deployed)
- E5: Xactimate estimate engine — 5 tables, 6 EFs, UI across all apps (S79)
- E6: Walkthrough engine — 5 tables, 4 EFs, 12 Flutter screens, CRM/portal viewers (S79)
- 26 Edge Functions deployed total. ANTHROPIC_API_KEY not set (functions are dormant).
- This code is additive (new files/tables only) — does NOT break existing functionality.

**Phase D summary (ALL DONE):**
- D1: Job Type System (S62). D2: Insurance/Restoration (S63-S64, S68). D3: Insurance Verticals (S69).
- D4: Ledger (S70) — 15 tables, 13 hooks, 13 pages, 5 EFs, 3 Flutter screens.
- D5: Property Management (S71-S77) — 18 tables, 14 CRM pages, 11 hooks, 10 Flutter screens, 3 EFs.
- D6: Enterprise Foundation (S65-66). D7a: Certifications (S67-68).
- R1: Flutter App Remake (S78) — 33 role screens, design system, AppShell.

**Next: Phase F (Platform Completion).** Order set by owner (S80):
**F1 → F3 → F4 → F5 → F6 → F7 → F8 → F9 → F10 → F2 (Website Builder LAST — huge feature)**
**PowerSync:** Moves to Phase G (after all tables exist, schema frozen, sync rules written once).

---

## KNOWN GAPS (Work that is incomplete or deferred)

| Gap | Status | Sprint | Details |
|-----|--------|--------|---------|
| **🚨 PITR (Point-in-Time Recovery)** | **LAUNCH BLOCKER** | Pre-launch | **$100/mo. WITHOUT IT: lose 24hr of customer data on crash. WITH IT: lose 2min.** Enable in Supabase Dashboard → Database → Backups → PITR. Requires Small compute minimum ($15/mo). Owner directive S137: "remind me 100 times before launch." **DO NOT SHIP WITHOUT PITR.** |
| **Enterprise Infrastructure** | **SPEC'D (S137)** | INFRA-1→5 | 4-environment pipeline (local/preview/staging/production). **Supabase Pro + Vercel Pro + Google Play ALL ALREADY ACTIVE (owner confirmed S138).** No manual upgrades needed — configure Pro features only. DB performance indexes. 3-layer architecture enforcement. Research: `memory/enterprise-infrastructure-research-s137.md`. |
| **Phase T: Programs** | **SPEC'D — NEXT** | T | Full spec in `Expansion/39_TPA_MODULE_SPEC.md`. ~17 tables, 3 EFs, ~80 hours. Legal assessment in `memory/tpa-legal-assessment.md`. Builds FIRST. |
| **Phase P: Recon/Property Intelligence** | **SPEC'D** | P | Full spec in `Expansion/40_PROPERTY_INTELLIGENCE_SPEC.md`. ~11 tables, 6 EFs, ~96 hours, 10 sprints. Lead scoring, batch area scanning, storm intelligence, supplement checklist, multi-structure detection, confidence scoring. API research in `memory/property-intelligence-research.md`. Builds after Phase T. |
| **Phase SK: Sketch Engine** | **EXPANDED (S101)** | SK | Full spec in `Expansion/46_SKETCH_ENGINE_SPEC.md` + sprint specs SK12-SK14. **~6 tables (was ~3), ~240 hours (was ~228), 14 sprints (SK1-SK14).** SK1-SK11: LiDAR scan, trade layers, Konva.js web editor, auto-estimate, export, 3D view. **S101 additions: multi-floor support (floor_number field + floor selector UI), version history snapshots (floor_plan_snapshots table), photo pin placement (floor_plan_photo_pins table), SVG export, team portal read-only viewer, client portal read-only viewer.** SK12: Site plan mode. SK13: Trade-specific measurements. SK14: Field UX + ARCore + multi-user collab. Deep research: `memory/sketch-engine-deep-research-s101.md`. $0/month API costs confirmed. Builds after Phase P. |
| **Phase GC: Schedule** | **COMPLETE (S110)** | GC | GC1-GC11 all done. 12 tables, 10 EFs, 9 CRM pages, Flutter screens. CPM critical path, resource leveling, weather delays, P6/MS Project import/export, DHTMLX Gantt web editor, portfolio dashboard, EVM cost loading, mini Gantt widgets, field progress sync, schedule reminders cron. |
| **Phase U: Unification & Feature Completion** | **EXPANDED (S100)** | U | 22 sprints (U1-U22, ~432 hrs). U1-U10: Portal unification, nav redesign, permission engine, Ledger completion, dashboard restoration, PDF/email/dead buttons, payment flow (expanded: **U7c Stripe Connect ~8h, U7d Review System ~6h, U7e Service Agreements ~12h, U7f Automation Engine Backend ~8h**), cross-system metrics, polish, embedded financing. U11-U15: Form depth, templates, i18n, trade support, S98 lost features. **U16-U22 (S100 additions): Onboarding Wizard (~8h), Data Flow Wiring (~16h — walkthrough→estimate→bid→job→invoice chain), Dispatch Board (~10h), Data Import (~8h — Jobber/HCP migration), Subcontractor Management (~12h), Calendar Sync + Notifications (~8h — Google/Outlook), Isolated Feature Wiring (~12h — phone/meetings/fleet/hiring connect to core).** |
| **Phase G: QA/Hardening** | **AFTER ALL BUILDING** | G | Comprehensive QA of ALL features (A-F + T + P + SK + U). Button-click audit, security, performance, cross-feature integration testing. |
| **Plan Review** | **SPEC'D (S97)** | E/BA | Full spec in `Expansion/47_BLUEPRINT_ANALYZER_SPEC.md`. AI-powered blueprint reading + automated takeoff. ~6 tables, 3 EFs, 8 sprints (BA1-BA8, ~128 hrs). Hybrid CV+LLM pipeline (MitUNet + YOLOv12 + Claude). RunPod serverless GPU. Research validated. Builds within Phase E (after E-review). |
| **Phase E AI (PAUSED)** | **DORMANT** | E | Code committed S78-S80. NOT to be resumed until after T+P+SK+GC+U+G. Deep spec session required. E-review + BA1-BA8 + E1-E4 sprint checklists all written. |
| **Home Warranty Module** | **RESEARCHED** | — | Deep workflow research in `memory/home-warranty-contractor-workflow.md`. Legal assessment in `memory/home-warranty-legal-assessment.md`. Expansion spec + sprint specs NOT yet written. |
| **CRM Dead Buttons** | **FIXED (S93)** | — | 24 dead buttons across bids, invoices, reports, sketch-bid pages. All wired to existing hook functions. Sketch-bid missing company_id on INSERT fixed. Build passes. |
| F1: Calls | **DONE** | F1 | 9 tables, 5 EFs, CRM+team+client+ops pages built. Manual deploy pending. |
| F2: Website Builder V2 | **DEFERRED POST-LAUNCH** | F2 | Owner directive S94: scrapped from pre-launch scope. Too much maintenance overhead for solo dev. Revisit post-launch with real contractor feedback + AI layer done. |
| F3: Meetings | **DONE** | F3 | 5 tables, 4 EFs, CRM+team+client+ops pages built. Manual deploy pending. |
| F4: Mobile Field Toolkit | **DONE** | F4 | 10 tables, 3 EFs, CRM pages. Flutter mobile deferred. |
| F5: Integrations | **DONE** | F5 | 8 migrations (25+ tables), 3 EFs, 8 CRM hooks+pages. CPA portal + route optimization deferred. |
| F6: Marketplace | **DONE** | F6 | 5 tables, 1 EF, CRM+client pages. AI scan = Phase E. |
| F7: Home Portal | **DONE** | F7 | 5 tables, client portal hook + 4 pages. Premium tier = Phase E + RevenueCat. |
| F8: Ops Portal Phases 2-4 | NOT BUILT | F8 | After AI. Marketing engine, treasury, legal, dev terminal. |
| F9: Hiring System | **DONE** | F9 | 3 tables, CRM hook+page. Checkr/E-Verify API deferred. |
| F10: ZForge | **DONE** | F10 | 3 tables, 1 EF, CRM hook+page, all portal expansion pages. |
| FM: Firebase Migration | **CODE DONE** | FM | Manual steps: retrieve Firebase secrets, deploy, update webhook URLs. |
| Codemagic CI/CD | **PARTIAL** | S91 | Android debug build PASSING. iOS needs Apple code signing in Codemagic. No `codemagic.yaml` — using UI workflow. Android release keystore not created. |
| C4: Security Hardening | PENDING | C4 | Email migration, passwords, YubiKeys. Pre-launch. |
| PowerSync Offline | NOT STARTED | — | SQLite <-> PostgreSQL offline sync. Phase G. |
| D6: company_documents table | NOT BUILT | D6a | Table + UI deferred. |
| D6: Flutter enterprise screens | NOT BUILT | D6b | Branch/roles/forms/API key screens for mobile. |
| External API integrations | PENDING | F-phase | Gusto (payroll), Checkr (background checks), E-Verify, DocuSign, Samsara/Geotab (fleet GPS), Unwrangle (supplier pricing). API keys needed. |
| SK: Bluetooth Laser Meter | **DEFERRED (S101)** | Post-launch | MagicPlan PrecisionLink supports 20+ devices (Bosch, Leica, DeWalt, Hilti, Stabila). HIGH bug risk — requires physical hardware testing, manufacturer BLE SDKs, device-specific pairing flows. Not confident in first-pass quality. Defer to post-launch hardware sprint with real device testing. Research in `memory/sketch-engine-deep-research-s101.md`. |
| SK → GC Scheduler Link | **DEFERRED to U-phase (S101)** | U17/U22 | Room data from sketch could auto-suggest scheduling tasks (e.g., "wire kitchen = 6 hrs"). Can't wire to Phase GC until it exists. Natural fit for U17 (data flow wiring) or U22 (isolated feature wiring). |
| **Calculator Save-to-Job** | **GAP (S116)** | Pre-launch | ~1,194 trade calculators (electrical, HVAC, plumbing, roofing, solar, welding, auto, GC, pool, landscaping, remodeler) have NO save functionality. Results are transient — calculate → display → gone. Infrastructure half-built: `ZaftoSaveToJobButton` widget exists (unused), `SavedCalculation` model exists in Hive (unused), `CalculationHistoryService` exists (unused), history screen exists (empty). Old infra syncs to Firestore (not Supabase). Need: Supabase `calculation_results` table, migrate from Hive/Firestore, wire `ZaftoSaveToJobButton` into all calculator screens, enable optional `job_id` linkage, populate history screen. Domain calculators (TPA equipment, Recon roof, SK room measurements) already save to Supabase correctly — only general trade calcs are affected. |

---

## DRIFT PREVENTION RULES (ENFORCED — VIOLATION = DRIFT)

1. **AI GOES TRULY LAST** — Phase E is PAUSED. Do NOT resume AI work until ALL of T + P + SK + GC + U + G are complete. AI must know every feature. Owner will initiate a deep spec session before any AI work resumes. This is the #1 rule.
2. **SEQUENTIAL EXECUTION** — Execute sprint sub-steps IN ORDER per `07_SPRINT_SPECS.md`. Never skip ahead.
3. **CHECK OFF AS YOU GO** — Mark `[x]` in `07_SPRINT_SPECS.md` for each item completed. If it's not checked, it's not done.
4. **NO OUT-OF-ORDER WORK** — If user requests work from a later sprint, discuss it first. If proceeding, add steps to sprint specs BEFORE coding.
5. **VERIFY BEFORE CLAIMING DONE** — Run `dart analyze`, `npm run build` (all portals), targeted code checks. No "should work" — prove it.
6. **UPDATE THESE DOCS AT SESSION END:**
   - `07_SPRINT_SPECS.md` — check off completed items, add new items if scope expanded
   - THIS doc (`00_HANDOFF.md`) — update CURRENT EXECUTION POINT table + add session log entry
   - `03_LIVE_STATUS.md` — update quick status snapshot
   - `02_CIRCUIT_BLUEPRINT.md` — update if any wiring changed
7. **NEVER CREATE PARALLEL DOCS** — One doc set. Update in place. No new tracking files.
8. **SPRINT SPECS IS THE EXECUTION TRACKER** — Not this doc. This doc points TO the sprint specs. The sprint specs have the checklists.
9. **HANDOFF IS THE ENTRY POINT** — Not the sprint specs, not the memory file, not CLAUDE.md. Start here, always.

---

## DOC MAP (What lives where)

| Doc | Purpose | When to read |
|-----|---------|-------------|
| `00_HANDOFF.md` (THIS) | Entry point. Current position. Rules. Session log. | FIRST — every session |
| `07_SPRINT_SPECS.md` | Execution tracker. Every step. Every checklist. | SECOND — find current sub-step |
| `01_MASTER_BUILD_PLAN.md` | High-level build order. Feature inventory. Architecture. | When planning new sprints |
| `02_CIRCUIT_BLUEPRINT.md` | Wiring diagram. What connects to what. All tables/EFs. | When wiring changes |
| `03_LIVE_STATUS.md` | Quick status snapshot. Table counts. Build state. | Quick reference |
| `04_EXPANSION_SPECS.md` | All 14 expansion + locked specs consolidated. | When referencing older specs |
| `05_EXECUTION_PLAYBOOK.md` | Session protocol. Quality gates. | Reference |
| `06_ARCHITECTURE_PATTERNS.md` | 14 code patterns with examples. | When implementing |
| `08_INCIDENT_RESPONSE.md` | Severity levels, breach response, key rotation, rollback. | Reference / incidents |
| `Expansion/` folder | Detailed feature specs (39_TPA, 40_PROPERTY_INTELLIGENCE, 46_SKETCH_ENGINE, 47_BLUEPRINT_ANALYZER, etc.) | When executing that sprint |
| `memory/` files | Research notes (TPA legal, property intelligence, Xactimate, API costs, etc.) | Reference / context |

---

## OUT-OF-ORDER EXECUTION LOG

These sprints were executed out of the original D1→D2→D3→D4→D5 order:

| Sprint | Original Position | Actually Executed | Reason |
|--------|------------------|-------------------|--------|
| D6 (Enterprise Foundation) | Not in original plan | S65 (before D3) | Added as new sprint |
| D7 (Certifications Modular) | Not in original plan | S66-S68 (before D3) | Enhancement to D6 certs |

---

## SESSION LOG (History — do NOT use for execution decisions, use CURRENT EXECUTION POINT above)

### Session 100 (Feb 13) — Comprehensive Build Plan Audit + All Holes Addressed

**S100: Comprehensive 4-Agent Audit (system connectivity, sketch engine, lead pipeline, data flow):**
- System connectivity: ~35% — data enters correctly but doesn't flow forward automatically.
- Lead pipeline: ~46% — architecture strong, automation engine = all mock data.
- Sketch engine: 4.5/10 as multi-trade tool (9/10 for interior electrical/plumbing/HVAC, 0/10 for exterior trades).
- 12 major holes found, 10 isolated features that connect to nothing, ~150-180 additional hours needed.

**S100: 12 Major Holes Identified & Addressed:**
1. No Stripe Connect onboarding — contractors can't get paid → U7c
2. No onboarding wizard — blank dashboard, high churn → U16
3. Automation engine = all mock data, zero backend → U7f
4. No review request system (non-AI) → U7d
5. Service agreements barely spec'd → U7e
6. No dispatch board → U18
7. No data import tools (can't migrate from Jobber/HCP) → U19
8. Change order workflow never fully built → U17
9. No customer communication timeline → U17
10. No subcontractor management → U20
11. No calendar sync (Google/Outlook) → U21
12. Sketch engine = interior only → SK12-SK14

**S100: Broken Data Flow Chains Identified → U17:**
- Walkthrough → Estimate (identical fields, no transfer function)
- Estimate → Bid (no conversion function)
- Estimate Approved → Job (customer approves, nothing happens)
- Job Completed → Invoice (no auto-draft)
- Job Cost Radar ignores time_entries (40-60% of costs)
- Client Signature → Status (fire and forget)
- Speed-to-lead auto_respond flag exists but never executes

**S100: Lead Pipeline Assessment (5th agent):**
- Fully wired sources: Manual CRM entry, AI Receptionist (SignalWire+Claude), Webhook normalizers (Angi/Thumbtack/Meta/Nextdoor)
- Stub sources: Google Business (placeholder), Yelp (reviews only), Google LSA (placeholder)
- Auto-assignment: REAL code, functional, minor round-robin counter bug (global vs per-rule)
- **Verdict: Adequate for launch with 3 pre-launch fixes:**
  1. Notifications write-only (records created but never delivered) — 4-8h fix
  2. `deleteLead` does hard DELETE (violates soft-delete rule) — 15min fix
  3. CRM manual leads bypass aggregator (no analytics, no auto-assignment) — 2-4h fix
- Post-launch: Google Business/Yelp/LSA stubs fine, webhook signature verification, phone-call-to-lead auto-creation

**S100: Phase SK Expanded (11 → 14 sprints, ~176h → ~228h):**
- SK12: Site Plan Mode — exterior trades (~20h). Property boundary, roof plan overlay, linear/area tools, elevation markers, site plan symbols.
- SK13: Trade-Specific Measurements & Templates (~16h). 8+ trade formulas (roofing/fencing/concrete/landscaping/siding/solar/gutters/painting). Pre-built templates by trade. One-click estimate generation.
- SK14: Field UX + Multi-User + Advanced (~16h). Glove mode, sunlight mode, voice input, ARCore Android, multi-user collab (Yjs), offline queue improvements.

**S100: Phase U Expanded (15 → 22 sprints, ~276h → ~432h):**
- U7c: Stripe Connect Onboarding (~8h)
- U7d: Review Request System (~6h)
- U7e: Service Agreements (~12h)
- U7f: Automation Engine Backend (~8h)
- U16: Contractor Onboarding Wizard (~8h)
- U17: Data Flow Wiring — walkthrough→estimate→bid→job→invoice chain (~16h)
- U18: Dispatch Board (~10h)
- U19: Data Import Tools — Jobber/HCP migration (~8h)
- U20: Subcontractor Management (~12h)
- U21: Calendar Sync + Notification Delivery (~8h)
- U22: Isolated Feature Wiring — phone/meetings/fleet/hiring connect to core (~12h)

**S100: Memory Files Created/Updated:**
- `s100-build-audit.md` — comprehensive audit findings summary.
- `zafto-system-knowledge.md` — Phase U/SK hour updates.

---

### Session 99 (Feb 13) — Full Depth Audit + Competitor Research + Phase U Expansion

**S99: Full Depth Audit (5 parallel agents):**
- Deep audit of all 5 apps (Flutter, Web CRM, Team Portal, Client Portal, Ops Portal) — every form, every field, every feature evaluated for completeness.
- Flutter: 15 findings (5 P0 blockers, 5 P1 shallow forms, 5 P2 missing features), ~72h remediation.
- Web CRM: 10 categories of hardcoded values, 12 entirely missing features.
- Team Portal: 6 deep / 6 shallow gaps (GPS, comms, time off all missing).
- Client Portal: 5 deep / 6 shallow (job tracker 100% mock data).
- Ops Portal: 1 deep / 8+ shallow (revenue/subs all $0, Stripe not connected).
- Cross-app: 62% of portal features incomplete.

**S99: Competitor Research (9 platforms scored):**
- Depth scores: ServiceTitan 84/90, Buildertrend 61, Jobber 47, HCP 43, FieldPulse 39.
- 12 market gaps NOBODY does well (multi-trade, offline-first, affordable depth, integrated accounting, client portal depth, trade calculators, AI plan review).
- ZAFTO unique advantages mapped: first mover in multi-trade, trade calculators, exam prep, AI plan review.
- Premium pricing unlocks identified ($200-400/mo tier justification features).

**S99: Contractor Complaint Research (Trustpilot/Capterra/G2/BBB/Reddit/forums):**
- Top 20 complaints ranked by frequency. Top 3: pricing too high, contract lock-in, customer support collapsed.
- Top 10 switching triggers. #1: true all-in-one that works.
- Key stats: 70% contractors experience payment delays, 52% rework from miscommunication ($31.3B/yr), 75% lose money from buddy punching.

**S99: Phase U Expanded (9 → 15 sprints, ~120h → ~276h):**
- U11: Form Depth Engine (~24h) — smart validation + form expansion across all apps. Includes: numeric-only for prices, email format validation, phone masking, required field enforcement, duplicate detection, double-submit prevention.
- U12: Template & Customization Engine (~16h) — configurable bid/invoice/agreement templates, custom fields, custom statuses, custom line item categories.
- U13: i18n 10 Languages (~24h) — EN, ES, PT-BR, PL, ZH, HT, RU, KO, VI, TL.
- U14: Universal Trade Support (~12h) — 20+ trade categories, trade-specific bid templates, trade-specific workflows.
- U15: S98 Lost Features (~16h) — remote-in support, data integrity audit, GPS-enhanced walkthrough data.

**S99: Phase G Expanded (+4 QA items):**
- G10h: Form Validation Stress Test — attempt invalid input on every form field in every app.
- G10i: Form Depth Verification — verify all form fields match database schema.
- G10j: i18n Verification — test all 10 languages across all apps.
- G10k: Trade Coverage Verification — test all 20+ trade categories.

**S99: Memory Files Created/Updated:**
- `full-app-audit-s99.md` — complete depth audit of all 5 apps.
- `competitor-research-s99.md` — 9 competitor depth scores + market gaps.
- `contractor-complaints-s99.md` — top 20 complaints + switching triggers + stats.
- `zafto-system-knowledge.md` — updated with all S99 findings.

---

### Session 98 (Feb 13) — Full-Stack Audit + Sprint Spec Gap Documentation + API Cost Strategy

**S98: Full-Stack Code Audit (3 parallel agents):**
- Audited entire codebase: Flutter app, 4 web portals, 53 Edge Functions, all hooks.
- Found **31 real gaps** not previously captured in sprint specs.
- 10 HIGH: core CRM console.log saves (bid/invoice/payment), fake AI, unauthenticated webhook.
- 4 MEDIUM: shell pages with mock data (Communications, Automations, Bid Brain, System Status).
- 8 Flutter Properties: unwired CRUD (unit turns, leases, inspections, assets, rent service).
- 6 fake services: contract analyzer, AI tools, subscription check, compression, purchase verification.
- 1 missing system: web portal notifications (Flutter has it, web doesn't).

**S98: Sprint Specs Updated (~65 new checklist items):**
- U6: +9 critical broken workflow items. U7: +3 shell page wirings. U9: +18 items (Properties, fake services, web notifications).
- G1b: Specific audit file list. G2c: +6 security items. G10: +20 stress test + UX audit items.
- Post-E: AI stress test + regression template added.

**S98: Architecture Verified:**
- Traced auth → middleware → hooks → Supabase → RLS → real-time across all 5 apps.
- All additions follow existing 14 code patterns from 06_ARCHITECTURE_PATTERNS.md.
- Circuit blueprint 10 broken pipes documented and assigned to sprints.

**S98: API Cost Strategy Established (standing rule for all phases):**
- Researched pricing for 14 property data APIs. Established free-first launch strategy.
- **$0/month launch stack:** Google Solar (10K free), Microsoft Footprints (free), USGS (free), NOAA (free), Mapbox (already have), OpenStreetMap (free).
- **Post-revenue additions:** ATTOM (~$500/mo), Regrid (~$80K/yr). Built but GATED behind feature flags.
- **Killed from roadmap:** Nearmap AI (enterprise-only), Beam AI (no API), SiteRecon (no public API), Hover ($999/yr min).
- Updated: 01_MASTER_BUILD_PLAN.md (global API cost principle), 07_SPRINT_SPECS.md (P2 split into free/paid, P5 lead scoring free fallback, P10 cost tracking), 40_PROPERTY_INTELLIGENCE_SPEC.md (tier restructure, lead scoring two-tier).
- **Rule applies to ALL expansion phases** — Phase P, SK, E, and any future work.
- Apple Developer Organization + Google Play accounts confirmed active — app store launches green-lit.

**S98: AI Monetization Model Locked:**
- **KILLED:** Credits, tokens, scan counts, packages, per-use pricing. All of it. Gone.
- **MODEL:** AI is a tier feature. Each tier includes AI usage. Visual meter in Settings (no numbers). When exceeded: buy more in dollar amounts ($10/$25/$50/$100/$500/$1,000) — meter refills, AI turns back on. Never forced to upgrade. Business/Enterprise = unlimited.
- **MODEL CHOICE:** Opus 4.6 for all user-facing AI (Z Intelligence, Blueprint Analyzer, AI Scanner, trade tools). Sonnet 4.5 only for trivial background routing/classification the user never sees.
- Added Sprint E0 (AI Usage Metering Infrastructure) to Phase E — builds before any AI goes live.
- Updated: 01_MASTER_BUILD_PLAN.md (AI Monetization standing rule), 07_SPRINT_SPECS.md (E0 sprint added), 47_BLUEPRINT_ANALYZER_SPEC.md (pricing section updated).
- Old `user_credits`/`credit_purchases`/`scan_logs` tables + `subscription-credits` EF + RevenueCat IAP credit products = DEPRECATED.

**S98: Recon Multi-Trade Audit (3 parallel agents):**
- Audited Phase P spec for multi-trade strength beyond roofing.
- Coverage: Roofing 95%, Gutters 90%, Solar 85%, Siding 70-80%, Landscaping 60-65%, HVAC 60%, Fencing 55%, Electrical 50%, Painting 45-50%, Concrete/Paving 40%, Plumbing 0%.
- Identified roofing-centric bias in: lead scoring (roof_age weight), storm intelligence (roof-only damage model), supplement checklist (roofing line items only).
- Multi-trade spec expansion pending — needs trade-specific lead scoring profiles, multi-trade storm damage models, non-roofing supplement items.

---

### Session 97 (Feb 11) — Plan Review Spec + Sprint Checklists + Research Validation

**S97: Plan Review Spec Created:**
- Full feature spec: `Expansion/47_BLUEPRINT_ANALYZER_SPEC.md` (680+ lines).
- AI-powered blueprint reading + automated takeoff engine. Hybrid CV+LLM pipeline.
- 6 new tables: blueprint_analyses, blueprint_sheets, blueprint_rooms, blueprint_elements, blueprint_takeoff_items, blueprint_revisions.
- 3 Edge Functions: blueprint-upload, blueprint-process, blueprint-compare.
- 8 sprints (BA1-BA8, ~128 hours). Phase E feature (builds after E-review).

**S97: Research Validated (3 deep research agents):**
- CV models: MitUNet (87.84% mIoU CubiCasa5K — outperforms U-Net++), YOLOv12 (attention-centric, better small object detection vs v8).
- Deployment: RunPod Serverless ($1.89-2.49/hr A100, 40-50% cheaper than Modal). ~$0.02-0.05/sheet at scale.
- Competitors: Togal ($2,700-3,588/yr, "basic measurement tool"), STACK ($1,899-5,499/yr), PlanSwift 2026 now cloud+AI, Bluebeam Max early 2026 with Anthropic Claude, Bild AI (YC), Kreo Caddie, ConX (Houzz acquisition). XactAI confirmed NOT takeoff. $3K-5K/yr competitor floor validated.

**S97: BA1-BA8 Sprint Checklists Written:**
- Full execution checklists added to `07_SPRINT_SPECS.md` inside Phase E section (after E-review, before E1-E4).
- ~200 checklist items across 8 sprints covering: data model, file ingestion, CV pipeline (RunPod), MitUNet segmentation, YOLOv12 detection, trade intelligence, assembly expansion, estimate integration, revision comparison, floor plan generation (SK integration), review mode, export, testing.

**S96: Phase U + CLAUDE.md (prior session):**
- Phase U (Unification & Feature Completion) added: 9 sprints (U1-U9, ~120 hours).
- CLAUDE.md created at repo root for Claude Code context.

---

### Session 95 (Feb 9) — Vercel Deployment + Login Redesign + Cloudflare DNS

**S95: All 4 Apps Deployed to Production (Vercel + Cloudflare):**
- Deployed all 4 Next.js apps to Vercel with production builds.
- Configured Cloudflare DNS: A records pointing to Vercel IP `76.76.21.21` for all 4 domains.
- Custom domains: `zafto.cloud` (CRM), `team.zafto.cloud` (Team), `client.zafto.cloud` (Client), `ops.zafto.cloud` (Ops).
- **DNS switch:** `team.zafto.app` → `team.zafto.cloud` (`.app` reserved for marketing site).
- Cleaned up old Porkbun DNS records on zafto.cloud (deleted 2 A records, www CNAME, wildcard CNAME).

**S95: Login Pages Redesigned (Stripe/Vercel Quality):**
- CRM: Split-panel layout (dark branding left, form right), show/hide password, theme toggle.
- Team: Centered card, emerald accent, clean form.
- Ops: Centered card, blue accent, "Founder OS" branding.
- Client: Centered card, indigo accent, magic link + password toggle.
- All 4: Animated Z offset echo logo (no boxes, `currentColor` for dark/light), subtle grid backgrounds, accent glow orbs, Sun/Moon theme toggle.

**S95: Dark Mode Defaults:**
- CRM, Team, Ops: Default to dark mode.
- Client Portal: Default to light mode (homeowner-facing).
- Created `client-portal/src/components/theme-provider.tsx` (new file).
- Fixed `useTheme()` SSR crash: returns defaults instead of throwing when context is undefined during prerender.

**S95: Supabase Auth Config Fixed:**
- Updated `site_url` from `http://localhost:3000` to `https://zafto.cloud`.
- Added 12 redirect URLs to `uri_allow_list` (all portals + Vercel URLs + localhost).
- Branded magic link email template (Stripe-quality HTML with Z logo).
- Admin account name changed: "Robert Tereda" → "Damian Tereda".

---

### Session 94 (Feb 9) — CAD-Grade Sketch Engine Spec

**S94: CAD-Grade Sketch Engine (SPEC COMPLETE):**
- Owner identified critical gap: existing sketch editor functional (1,329 lines, wall drawing, 7 door types, 25 fixtures) but doesn't replace professional sketch tools. No wall editing after draw, no trade layers, no LiDAR, no export, no auto-estimate, web CRM has zero canvas.
- Competitive research: magicplan, Xactimate Sketch, HOVER, ArcSite — none do the full pipeline (LiDAR scan → floor plan → multi-trade overlays → auto-estimate → export → job management → invoice) in one platform with mobile-to-web sync.
- Identified two disconnected table systems: `property_floor_plans` (geometric, E6a) + `bid_sketches`/`sketch_rooms` (business, F4f). D8 estimate engine has zero connection to either. Unified around property_floor_plans as single source of truth.
- Architecture decisions: Apple RoomPlan (Swift platform channel) for LiDAR, Konva.js (not tldraw/fabric.js) for web canvas, three.js for 3D visualization, FloorPlanDataV2 JSONB schema with V1 backward compat.
- Trade layer system: Electrical (15 symbols), Plumbing (12), HVAC (10), Damage (4 tools with IICRC classification). All toggleable overlays with visibility/lock/opacity.
- Auto-estimate pipeline: geometry → room measurements (shoelace formula) → estimate_areas → line item suggestions based on room type + trade → D8 pricing engine.
- Export: PDF (title block + plan + room schedule + legend), PNG (hi-res), DXF (AutoCAD interop), FML (open format for Symbility/Cotality). ESX export deferred pending legal.
- Created `Expansion/46_SKETCH_ENGINE_SPEC.md`: ~3 new tables, ~46 new files (21 Flutter, 25 web), 1 migration.
- Sprint specs SK1-SK11 (~176 hours) written to `07_SPRINT_SPECS.md`.
- Build order updated: G → T → P → SK → E → F2 → F8.
- All docs updated: 00_HANDOFF.md, 01_MASTER_BUILD_PLAN.md, 03_LIVE_STATUS.md, 07_SPRINT_SPECS.md.

---

### Session 93 (Feb 9) — Recon Property Intelligence Spec + Home Warranty Research + Contractor Verticals

**S93: Recon / Property Intelligence Engine (SPEC COMPLETE):**
- Owner requested "EagleView but better" — satellite-powered property measurement tool.
- Deep API research: Google Solar API ($0.01/call Building Insights, $0.075 Data Layers), ATTOM Property API, Regrid (149M parcels), Microsoft Building Footprints (1.4B free), USGS 3DEP (free LIDAR), Nearmap (post-traction Tier 2), HOVER API ($25/job with ESX export), Estated API.
- Created `Expansion/40_PROPERTY_INTELLIGENCE_SPEC.md` (~952 lines, expanded S97 to ~1200+ lines): originally 8 tables, 4 Edge Functions. **S97 expanded to 11 tables, 6 Edge Functions, P1-P10 (~96 hours)** — added lead scoring engine, batch area scanning, confidence scoring with imagery date transparency, multi-structure detection, insurance supplement checklist, storm intelligence with NOAA data + damage probability model.
- 10 trade-specific measurement pipelines (roofing, siding, gutters, solar, painting, landscaping, fencing, concrete, HVAC, electrical).
- Competitive matrix vs EagleView ($18-91/report), Roofr ($13-39), HOVER ($25/job), GAF QuickMeasure — Recon = $0 included. 6 features no competitor offers.
- Waste factor engine, material ordering pipeline (Unwrangle + ABC Supply), on-site verification workflow.
- Phase P sprint specs (P1-P10, ~96 hours) written to `07_SPRINT_SPECS.md` (expanded S97 from original P1-P8).
- API research saved to `memory/property-intelligence-research.md`.
- Build order updated: G → T → P → E → F2 → F8.

**S93: Home Warranty Module Deep Research (RESEARCH COMPLETE, SPEC PENDING):**
- Owner-initiated expansion research: home warranty contractor management module.
- Deep workflow research: 9-step dispatch-to-payment lifecycle for all 7 major warranty companies (AHS, Choice, Cinch, First American, 2-10, ORHP, Fidelity). Saved to `memory/home-warranty-contractor-workflow.md` (783 lines).
- Legal risk assessment: LOW risk (no Xactimate equivalent, no proprietary format risk, contractor's own data). Antitrust warning (RealPage/Optimal Blue precedent — NEVER aggregate cross-contractor data). Saved to `memory/home-warranty-legal-assessment.md`.
- Architecture overlap with TPA module: ~90% (same portal aggregation, payment tracking, scoring mechanics).
- **Expansion spec NOT yet written.** Sprint specs NOT yet added to `07_SPRINT_SPECS.md`.

**S93: Contractor Verticals Deep Research (COMPLETE):**
- Researched 9 contractor software verticals: home warranty, fire protection, HVAC, roofing, electrical, plumbing, general contractors (sub perspective), pest control, landscaping.
- Key findings: portal fatigue universal across all trades, ServiceTitan is common enemy ($250-400/tech/mo), 80% of pest control has ZERO software, home warranty module is highest-ROI expansion.
- Opportunity matrix saved to `memory/contractor-verticals-research.md`.
- Architecture principle: Build portal aggregation engine ONCE (TPA module), then stamp out vertical-specific adapters.

**S93: CRM Dead Button Audit + Fix (COMPLETE):**
- Owner reported: "New Sketch" button does nothing, many CRM pages have dead buttons and silent failures.
- **Root cause found:** `use-sketch-bid.ts` hook's `createSketch()` and `addRoom()` both missing `company_id` on INSERT — required NOT NULL column with no default. Insert fails silently (caught error but no UI feedback).
- **Root cause 2:** Floor level values in UI (`'2nd'`, `'3rd'`) didn't match DB CHECK constraint (`'upper'`, `'exterior'`). Fixed to match.
- **Sketch + Bid page fully rewritten:** Working New Sketch modal → creates sketch → auto-opens detail view. Working Add Room modal with room type (10 options), floor level, L×W×H dimensions, live sqft calculation. Status flow buttons (Draft→In Progress→Completed). Summary bar (rooms, sqft, damaged, estimated). Error display in both modals.
- **Full CRM button audit — 24 dead buttons found, all fixed:**
  - `bids/page.tsx`: 7 dead buttons → wired batch Send All, Export CSV, Delete. Dropdown View, Send, Delete wired. PDF = Phase G alert.
  - `bids/[id]/page.tsx`: 7 dead buttons → wired Send to Customer (`sendBid`), Convert to Job (`convertToJob` → navigates to new job), Duplicate, Client Portal Link (clipboard copy), Delete. Request Deposit + PDF = Phase G alert.
  - `invoices/page.tsx`: 3 dead buttons → wired Send Reminder (`sendInvoice`), Record Payment (prompt for amount → `recordPayment`), PDF = Phase G alert.
  - `reports/page.tsx`: 1 dead button → wired Export CSV (monthly revenue data).
- **All hooks already had the mutation functions** (`sendBid`, `deleteBid`, `convertToJob`, `sendInvoice`, `recordPayment`, `deleteInvoice`) — they just were never called from the UI pages.
- Build verified: `npm run build` PASSES (92/92 pages, 0 type errors).

---

### Session 92 (Feb 9) — Programs Deep Research + Spec + Legal Assessment

**S92: TPA (Third Party Administrator) Deep Research (COMPLETE):**
- Owner-initiated research into TPA managed repair networks (Contractor Connection, Accuserve, Sedgwick, Alacrity, OnCORE, Westhill, etc.).
- 6 parallel research agents: TPA landscape, contractor pain points, software gaps, IICRC standards, Xactimate codes/workflows, legal risks.
- Key findings: contractors pay $1,500-5,000+/month for 8-15 separate tools. Pain points: referral fees (5-20%), payment delays (80% wait 30+ days), 1-2 hours/job on documentation, 8-15 separate logins.
- Identified 7 features with ZERO competition: multi-TPA command center, per-TPA profitability analytics, documentation completeness validation, scorecard tracking, AI supplement intelligence, equipment-to-billing automation, AI estimate writing.
- Saved to `memory/tpa-research.md` (comprehensive industry landscape).

**S92: TPA Industry Standards Research (COMPLETE):**
- IICRC S500 (Water): Categories 1-3, Classes 1-4, equipment placement formulas (dehu PPD, air movers per LF/SF, scrubber ACH), drying goals, psychrometric monitoring.
- IICRC S520 (Mold): Conditions 1-3, containment levels, negative air.
- IICRC S700 (Fire/Smoke): Restoration Work Plan requirements.
- Xactimate structure: category codes (WTR, DRY, CLN), line item fields, ESX file format, XactAnalysis workflow, O&P standards.
- TPA job lifecycle: 10-step workflow from assignment receive through payment closeout.
- Saved to `memory/tpa-industry-standards.md` (comprehensive reference).

**S92: TPA Legal Assessment (COMPLETE):**
- 2 legal research agents: format legality (ESX/FML), module legal risks (trademarks, scraping, IICRC, UPPA, antitrust).
- 6 critical rules established: never install Xactimate on dev machines, never scrape TPA portals, never copy Xactimate pricing, never aggregate cross-contractor fees (RealPage antitrust), frame as "contractor scope of work" not "insurance claim estimate" (UPPA felony in FL), IP attorney before shipping ESX export.
- FML confirmed as OPEN FORMAT (Floorplanner) — safe to generate.
- ESX import (reading) = LOW risk. ESX export needs Verisk partnership or IP attorney.
- Trademark usage OK with nominative fair use disclaimer.
- IICRC formulas OK — publicly available calculation sheets.
- Saved to `memory/tpa-legal-assessment.md` (complete risk matrix with pre-launch legal checklist).

**S92: Programs Expansion Spec (COMPLETE):**
- Created `Expansion/39_TPA_MODULE_SPEC.md`: ~15 new database tables, 3 Edge Functions, ~10 CRM pages, ~5 mobile screens, ~3 team portal pages, ~1 ops portal page, ~10 hooks.
- Architecture: company-level feature flag (`features.tpa_enabled`), contextual integration into existing screens, not a separate app.
- Full water mitigation workflow matching real industry TPA job lifecycle (10 steps).
- IICRC S500 equipment calculator formulas built in.
- ZAFTO's own line item codes with Xactimate mapping table for export interop.
- Legal disclaimers specified for all third-party references.
- 10-sprint build plan (T1-T10, ~80 hours total).

**S92: Sprint Specs Updated:**
- Phase T (Programs) added to `07_SPRINT_SPECS.md` between Phase G and Phase E rebuild.
- 10 sprints with full checkbox checklists (T1-T10).
- Build order updated: G → T → E → F2 → F8 → LAUNCH.

---

### Session 91 (Feb 9) — Codemagic CI/CD + Dependabot Fixes

**S91: Codemagic CI/CD Setup (Android PASSING, iOS needs code signing):**
- Set up Codemagic CI/CD for Flutter builds (iOS + Android from cloud Mac Mini M2).
- Fixed 5 build failures across iterations:
  1. `env_dev.dart` gitignored → replaced with inline `String.fromEnvironment()` defaults in main.dart
  2. `DefaultFirebaseOptions` undefined → removed all Firebase imports from main.dart
  3. `FirebaseCrashlytics` → replaced with Sentry in error_service.dart
  4. `record_linux` 0.7.2 incompatible → upgraded record 5.x to 6.2.0
  5. Kotlin version mismatch (Codemagic has kotlin-stdlib 2.2.0) → set Kotlin 2.2.0 + sentry_flutter 9.x
- Firebase package cleanup: removed firebase_crashlytics, firebase_analytics, firebase_auth, firebase_storage from pubspec.yaml. Kept firebase_core/cloud_firestore/cloud_functions (13 files still import Firestore — Phase G cleanup).
- Bundle ID set to `app.zafto.mobile` across iOS + Android.
- Android `android/` directory recreated (was missing entirely).
- iOS Podfile committed with minimum deployment target 15.0 (cloud_firestore 6.x requires it).
- **Android debug build: PASSING** (95.53 MB .aab artifact on Codemagic).
- **iOS: Compiles but fails on code signing** — needs Apple Developer API key in Codemagic Distribution settings.
- `flutter analyze`: 0 errors (2,755 warnings/infos — all non-blocking).

**S91: Dependabot Vulnerability Fixes (0 vulnerabilities):**
- Both alerts were in legacy Firebase backend (`apps/Trades/backend/functions/`).
- `protobufjs`: added npm override to >=7.2.5 (fixes critical prototype pollution via nested google-gax dep).
- `fast-xml-parser`: upgraded firebase-admin 11.x → 12.x (pulls @google-cloud/storage with fast-xml-parser 5.x, fixes high severity RangeError DoS).
- `npm audit`: 0 vulnerabilities confirmed.
- All 4 portals + Flutter + Supabase edge functions were NOT affected (clean).

**S91: Commits:**
- `ee32404` — Codemagic build fix (Kotlin 2.2.0 + sentry 9.x + Firebase cleanup)
- `e2e17a2` — Dependabot vulnerability fixes
- `959a41f` — iOS Podfile with deployment target 15.0

---

### Session 90 (Feb 8) — PHASE F COMPLETE + Portal Expansion

**S90: Phase F ALL CODE COMPLETE:**
- F10 ZForge finished: migration 48 (3 tables), zdocs-render EF (6 actions, 5 system templates), use-zdocs hook, /dashboard/zdocs page (3 tabs).
- Web CRM: 107 routes. use-zdocs hook with real-time + 7 mutations. Templates grid + Generated Documents table + Signatures tracking.
- Team Portal: 4 new hooks (use-pay-stubs, use-my-vehicle, use-my-training, use-my-documents) + 4 new pages + MY STUFF sidebar section. 36 routes.
- Client Portal: 3 new hooks (use-home-documents, use-quotes, use-find-a-pro) + 3 new pages + nav links. Fixed TS implicit any errors. 38 routes.
- Ops Portal: 5 new analytics pages (payroll, fleet, hiring, email, marketplace) + PLATFORM sidebar section. 26 dashboard routes.
- ALL 4 portals build clean. Zero errors.
- F-phase totals: 17 migrations (71 tables including FM payments), 21 Edge Functions, 40+ CRM hooks, 107 CRM routes, 36 team routes, 38 client routes, 26 ops routes.
- Sprint specs fully updated. Phase G (QA/Hardening) is NEXT.

### Session 89 (Feb 8) — ESX Legal Assessment + Insurance Research + D8j

**S89: ESX Legal Risk Discussion (RESOLVED — ESX DEFERRED):**
- Extended legal analysis: DMCA 1201 vs copyright distinction. Clean-room protects against copyright claims only. DMCA 1201 anti-circumvention is separate — sole defense is 1201(f) interoperability exception.
- 1201(f) friction points: "lawfully obtained the program" requirement creates catch-22 (license = EULA risk, no license = "lawfully obtained" risk).
- Owner decision: ESX features too risky to ship now. "This software looks too good to risk." Door left open for post-revenue with IP attorney blessing.
- Owner directive: IP attorney deferred until revenue stage. Build zero-risk features now, lawyer before shipping ESX.
- Strategy docs updated (memory/xactimate-strategy.md, memory/xactimate-legal-risk-assessment.md, memory/MEMORY.md).

**S89: Insurance Workflow Deep Research (COMPLETE):**
- 3 parallel research agents: contractor claim lifecycle, supplement process, codebase audit.
- Full 10-step workflow documented: lead intake → emergency mitigation → documentation → initial scope → adjuster interaction → supplement process → O&P → ACV/RCV → payment → certificate of completion.
- Competitor landscape: Encircle Hydro, LEVLR, Restoration AI, HOVER, Symbility, XactAI.
- Key insight: "Adjusters re-write your estimate in Xactimate REGARDLESS. The supplement process is the real leverage point."
- Zero-risk feature roadmap: supplement engine, AI estimate writer, PDF import, pricing intelligence, photo→scope AI, code library expansion, O&P calculator, drying report PDF.
- Saved to memory/insurance-workflow-research.md (comprehensive).

**S89: FM — Firebase→Supabase Migration (CODE COMPLETE):**
- Migration: 6 new tables (payment_intents, payments, payment_failures, user_credits, scan_logs, credit_purchases). All with RLS, indexes, triggers.
- Edge Function: stripe-payments (createPaymentIntent + getPaymentStatus → Supabase tables)
- Edge Function: stripe-webhook (payment_intent.succeeded/failed → updates bids/invoices/payment_intents)
- Edge Function: revenuecat-webhook (IAP purchases + refunds → user_credits + credit_purchases)
- Edge Function: subscription-credits (get/add/deduct credits → user_credits + scan_logs)
- AI scan functions already migrated via Phase E (ai-photo-diagnose EF covers all 5 Firebase scan types)
- Manual steps remaining: retrieve Firebase secrets → set in Supabase → deploy migration + EFs → update webhook URLs → test → delete Firebase code
- 108 tables total (102 + 6 FM). 36 Edge Functions total (32 + 4 FM).

**S89: D8j — Portal Integration + Testing (DONE):**
- Team Portal: use-estimates.ts hook (createFieldEstimate, addArea, addLineItem, recalculate) + estimates list page + estimate detail page. Sidebar updated. 27 routes (+2).
- Client Portal: use-estimates.ts hook (approve/reject with ownership checks) + estimate review page rewritten from mock to production (604 lines). Digital signature (typed name + agreement checkbox). 29 routes.
- Ops Portal: estimate analytics dashboard (6 stat cards, type breakdown, filter tabs, recent estimates table, code DB health section). Sidebar updated. 20 routes (+1).
- All 5 apps build clean. D8 Estimates COMPLETE (all 10 sub-steps: D8a-D8j).
- Files: team-portal (mappers.ts, use-estimates.ts, estimates/page.tsx, estimates/[id]/page.tsx, sidebar.tsx), client-portal (mappers.ts, use-estimates.ts, estimate/page.tsx), ops-portal (estimates/page.tsx, sidebar.tsx).

---

### Session 87-88 (Feb 8) — D8e-D8i: Estimates (continued)

**S87: D8e+D8f+D8g — PDF Export + ESX Import/Export (ALL DONE):**
- export-estimate-pdf EF: 3 templates (standard/detailed/summary), company branding, insurance details, print CSS. Wired into Web CRM (PDF button + 3 template buttons in preview) + Flutter (functions.invoke → temp file → Share.shareXFiles).
- import-esx EF: Full XACTDOC parser (ZIP+XML), fflate for ZIP extraction with bomb detection, fast-xml-parser for XML. Parses XACTNET_INFO/CONTACTS/ADM/ESTIMATE. Code mapping to estimate_items via ilike. Unknown codes → code_contributions. Wired into Web CRM (Import .esx button) + Flutter (file_picker → MultipartRequest).
- export-esx EF: XACTDOC XML generation from D8 estimate data, ZIP packaging with photos from estimate-photos bucket. Wired into Web CRM (.esx button for insurance) + Flutter (Export .esx for insurance).
- All 3 Edge Functions deployed. 29 total.

**S88: D8h — Code Contribution Engine (DONE):**
- Fixed import-esx code_contributions insert: wrong column names (category_code→industry_code, item_code→industry_selector, contributed_by→user_id). Removed non-existent source/status columns.
- Added dedup logic: checks for existing industry_code+industry_selector, increments verification_count instead of duplicate insert.
- code-verify Edge Function: GET stats+queue (filter by all/pending/verified/promoted/ready, pagination). POST actions (verify, reject, promote-one, promote-all). Super_admin role gate. Promotes verified codes (3+ verifications) to estimate_items with source='contributed'.
- Ops Portal code-contributions admin page: stats cards (total/pending/ready/verified/promoted), filter tabs, search, verify/reject/promote buttons per row, bulk "Promote All" action. 18 routes total (+1).
- Sidebar updated: DATA section with Code Contributions link.
- import-esx redeployed with fix. code-verify deployed. Ops Portal builds clean (18 routes, 0 errors).

**S88: D8i — Pricing Engine Foundation (DONE):**
- pricing-ingest Edge Function: BLS + FEMA + PPI ingestion, ZIP→MSA lookup, batch pricing.
- msa_regions table: 25 MSAs with cost indices + ZIP prefixes.
- fn_zip_to_msa + fn_get_item_pricing Postgres functions.
- 5,616 estimate_pricing rows seeded (national + 25 MSAs).
- Ops Portal pricing-engine admin page. 19 routes total (+1).
- Web CRM UI overhaul: collapsible sidebar groups, ZAFTO wordmark fix, Z FAB ambient glow, artifact side-by-side with chat, persistent new chat button, drag-to-resize panels.

---

### Session 85-86 (Feb 7-8) — D8: Estimates

**S85: Doc updates + planning.**
- Updated all build docs with finalized Phase F build order.
- Added detailed sprint spec checklists for D8a-D8j and F-phase.
- Finalized build order: D8 → Firebase Migration → F1→F3→F4→F5→F6→F7→F9→F10→G→E→F2→F8.
- Audited API keys across all apps (Stripe/RevenueCat/Anthropic in Firebase backend need migration).

**S86: D8a — Estimates Database (DONE):**
- 10 tables: estimate_categories, estimate_units, estimate_items, estimate_pricing, estimate_labor_components, code_contributions, estimates, estimate_areas, estimate_line_items, estimate_photos.
- Enterprise RLS, GIN indexes, audit trigger, partial indexes. Migration made idempotent.
- Fixed COALESCE in UNIQUE constraint (PostgreSQL limitation) and index name collision with E5.
- Deployed: 101 total tables.

**S86: D8b — Seed Data (DONE):**
- 16 units, 86 categories with industry code mappings, 216 items across 15+ trades, 28 BLS labor rates.
- All verified via SQL counts.

**S86: D8c — Flutter Estimate CRUD (DONE):**
- Models: estimate.dart (Estimate, EstimateArea, EstimateLineItem, EstimatePhoto + 4 enums), estimate_item.dart (EstimateItem, EstimateCategory, EstimateUnit).
- estimate_engine_repository.dart — full CRUD, code search, auto-numbering (named "engine" to avoid E5 collision).
- estimate_engine_service.dart — 10 providers, EstimatesNotifier, EstimateStats, business logic (send/approve/reject/duplicate/recalculate).
- 5 screens: estimate_list_screen (stats bar, status+type filters, search), estimate_builder_screen (room-by-room editor, insurance toggle, O&P settings), room_editor_screen (dimensions, computed measurements, line items), line_item_picker_screen (code DB search, trade filters, manual entry), estimate_preview_screen (read-only summary, insurance totals, send action).
- dart analyze: 0 issues across all 9 D8c files.

---

### Session 80 (Feb 7) — E3: Employee Portal AI + Mobile AI

**E3a: AI Troubleshooting Edge Functions (DONE):**
- 4 Edge Functions: ai-troubleshoot (314L), ai-photo-diagnose (308L), ai-parts-identify (298L), ai-repair-guide (391L)
- All use Claude Sonnet 4.5, Supabase auth, structured JSON. 1,311 lines total.
- Commit: 876333e. All 4 deployed (26 Edge Functions total).

**E3b: Team Portal AI Troubleshooting Center (DONE):**
- use-ai-troubleshoot.ts hook (254 lines, 5 AI callers)
- troubleshoot/page.tsx (1,364 lines, 5-tab UI: Diagnose/Photo/Code/Parts/Repair)
- Commit: 91b287f. Build clean.

**E3c: Mobile Z Button + AI Chat (DONE):**
- ai_service.dart (AiService + AiChatNotifier + providers, Edge Function client)
- z_chat_sheet.dart (bottom sheet chat), ai_photo_analyzer.dart (vision defect detection)
- app_shell.dart Z FAB opens chat. Legacy aiService alias for backward compat.
- Commit: 839ea48. dart analyze: 0 issues.

**E3d: Client Portal AI (DONE):**
- use-ai-assistant.ts hook, ai-chat-widget.tsx (floating Z + slide-up panel)
- layout.tsx updated. Commit: e9dc070. Build clean.

**E4a-e: Growth Advisor (COMMITTED, not deployed):**
- 5 Edge Functions (2,133 lines), 4 hooks (756 lines), 4 CRM pages (2,263 lines).
- Commit: 6b57047. Web CRM builds clean (71 routes).

**INTEL folder deleted** by owner — static trade content replaced by Claude AI. Commit: 75266fe.

**PHASE E PAUSED (owner directive):**
- AI was built prematurely (S78-S80). Should come AFTER Phase F (Platform) + G (QA).
- All E code is additive (new files/tables). Does not break existing functionality.
- Build order corrected: A→B→C→D→R1→**F→G→E**
- Deep AI spec session required before resuming Phase E.
- All docs updated to reflect this (master build plan, handoff, circuit blueprint, live status, sprint specs).

**API Integration Strategy (RESEARCHED):**
- Comprehensive research completed: 40+ APIs across 11 categories to make ZAFTO feel like full ecosystem on first login.
- Full list saved to `memory/api-integrations.md`. Key APIs: Unwrangle (HD+Lowe's pricing), HD Pro Xtra (direct B2B ordering), RSMeans (construction cost DB), Angi/Thumbtack/Google LSA (lead aggregation), SignalWire (VoIP/SMS/Fax — replaces Telnyx+Plivo, both rejected), LiveKit (video), Indeed/LinkedIn/ZipRecruiter (hiring), Checkr (background checks), Gusto (embedded payroll), Plaid (bank feeds), DocuSign (e-sig), Samsara (fleet GPS).
- Architecture: 1 Edge Function per API → normalize to ZAFTO schema → insert into tables → audit log.
- Priority order maps directly to F-phase features.

**Next:** Phase F (Platform Completion). Owner to decide F1-F10 priority.

### Session 83 (Feb 7) — Xactimate Deep Research: Legal Risk + Market Assessment + IICRC Knowledge Audit

**Xactimate Legal Risk Assessment (4-agent deep research):**
- Deployed 4 parallel research agents: ESX Producers Legal Status, Adjuster ESX Acceptance, Verisk Litigation/DMCA Interop, Xactimate Alternatives Market
- **CRITICAL FINDING:** Every company producing ESX files does so through formal Verisk partnership. ZERO independent ESX producers exist commercially. magicplan, HOVER, Encircle, DocuSketch — ALL go through Verisk's Strategic Alliance program.
- **#1 RISK:** EULA breach of contract (SAS v. WPL: $79.1M damages trebled), NOT copyright or DMCA
- **ESX has NO DRM** — DMCA 1201 likely doesn't apply (nothing to "circumvent" in a ZIP file)
- **Circuit split unresolved** — 5th Cir (Vault) says EULA can't override copyright; Fed Cir (Bowers) + 8th Cir (BnetD) say it can
- **Key case law compiled:** Sega v. Accolade (RE for interop = fair use), Google v. Oracle (API reimplementation = fair use), Lotus v. Borland (menu hierarchy = uncopyrightable), Blizzard v. BnetD (EULA can waive interop rights), Compulife v. Newman (scraping pricing DB = trade secret)

**Risk Mitigation Strategy:**
1. NEVER accept Xactimate EULA on any dev machine (eliminates breach of contract)
2. Clean room methodology (Team A documents ESX structure, Team B implements)
3. Analyze customer-provided ESX files only (no EULA needed)
4. Build own pricing database (crowd-sourced from real ZAFTO user jobs)
5. IP attorney opinion letter before shipping ($5K-10K insurance)

**Three Viable Paths Identified:**
- **Path A: Verisk Partnership** — Apply through Strategic Alliance, get official API/XactNet access. Safe but under Verisk's control.
- **Path B: Independent Estimating** — Own pricing DB + line item codes, output professional PDFs (not ESX). Low adoption risk.
- **Path C: Clean Room ESX Interop** — Clean room from customer-provided ESX, own pricing DB, ESX-compatible output. First company to do this. Needs counsel.

**IICRC Knowledge Base Assessment (1,140 lines reviewed):**
- STRONG for restoration-specific insurance claims (~6 categories: WTR, HMR, TCR, CLN, FRE, DMO)
- Equipment calculation formulas, adjuster documentation requirements, insurance dispute strategies all solid
- MISSING: 64+ of 70+ Xactimate category codes, regional pricing (460+ ZIP regions), O&P rules by carrier, depreciation schedules, 27,000+ line items, non-restoration trades
- **Strategic implication:** Launch Xactimate competition with restoration contractors FIRST (where IICRC knowledge is strong), expand to construction trades later

**Adjuster Acceptance Intelligence (owner-provided, independently verified):**
- Adjusters WILL accept non-Xactimate ESX if: clean import, Xactimate-style structure, pricing within 10-15% of regional list, scope aligns with inspection
- Adjusters REJECT when: carrier requires Xactimate-only, ESX imports poorly, custom pricing, inexperienced adjuster
- **Key insight:** "Produces estimates that adjusters don't feel the need to rewrite" > "ESX compatible"
- Adjusters re-write estimates regardless. Supplement process is the real leverage point.

**Verisk Competitive Intelligence:**
- Competitive response playbook: Acquire (52 total) → Partner (130+) → Litigate ($375M EagleView) → Build AI (XactAI Sept 2025) → Ignore
- FTC actively opposing: blocked 2 acquisitions (EagleView 2014, AccuLynx 2025)
- Contractor frustration extreme: 100-200% above Xactimate pricing for small jobs
- Window is narrow: Verisk building XactAI to deepen moat

**Files Saved (memory, NOT in source code):**
- `memory/xactimate-legal-risk-assessment.md` — Full S83 research (risk matrix, case law, 3 paths)
- `memory/xactimate-deep-dive.md` — Updated with adjuster acceptance intelligence
- `memory/MEMORY.md` — Updated Xactimate strategy section

**PENDING: Owner to choose Path A/B/C. IP attorney opinion letter required before any ESX shipping.**

**Next:** Owner path decision → Finish remaining API signups → Write Phase F sprint specs.

---

### Session 82 (Feb 7) — Xactimate ESX Deep Dive: Decryption Tool Review + MCP Server

**ESX Decryption Tool Reviewed:**
- PowerShell script (`esx_decrypt.ps1`) using Xactimate's `Core.Sys.Zip.dll` → `DoubleZipProvider.Undo()` method
- Encryption: AES-128-ECB, 16-byte blocks, header `04 04 0A XX`, footer `FF FE FF FE`
- Requires Xactimate Desktop installed (DLLs at `C:\Program Files\Xactware\XactimateDesktop\CORE\`)
- **NOT available on current dev machine** — Xactimate Desktop not installed
- Two XACTDOC variants: plain XML (sketch-only) and encrypted ZIPXML (full estimates)

**MCP Server Prototype Reviewed:**
- REST API on localhost:8765 for ESX read/write/encrypt/decrypt
- Built for "Restoration Bid App" prototype (codename "Damians Mission")
- Can both read AND write ESX files including re-encryption via DoubleZipProvider.Do()
- Production limitation: requires local Xactimate DLL — can't run on Supabase Edge Functions

**DLL Exploration Scripts Reviewed:**
- `explore_xact_dlls.ps1` — inspects public types in Pricelist, EstimateData, XactDocs DLLs
- `explore_estdata.ps1` — deep dive into EstData class (constructors, methods, properties, factory)
- Key classes: `Core.Sys.Zip.DoubleZipProvider`, `Core.Sys.AESImplementation`, `Xm8.Busi.EstimateData.EstData`

**XACTDOC XML Schema (from cracked samples):**
- Root: `<XACTDOC>` with lastCalcGrandTotal, totalLineItems, usesRulesEngine attrs
- `<PROJECT_INFO>` — userID, userName, versionCreated
- `<LINE_ITEMS>` → `<ESTIMATE_ITEM>` — category, description, quantity, unit, unitPrice, total
- Sketch data: `<SKETCHDOCUMENT>` → `<SKETCHLEVEL>` → rooms/walls/vertices/openings
- Real samples tested: SHARON ($32,550.41, 52 items), KENNEDY ($3,366.43, 3 items)

**Production Path Options:**
1. Extract AES key from DLL → reimplement in TypeScript/Deno (most portable)
2. Sidecar Windows service with DLL (complex deployment)
3. Client-side decryption in Electron/desktop wrapper
4. WASM compilation of decryption logic
5. PDF parsing via Claude Vision (simplest, no DLL needed)

**Next:** Deep legal research on ESX interoperability risk.

---

### Session 81 (Feb 7) — API Signups + Security Policy + Xactimate Research

**API Signups (IN PROGRESS):**
- Unwrangle API key stored in Supabase secrets (trial, 100 credits)
- Plaid client_id + secret stored in Supabase secrets (sandbox — Auth, Balance, Identity, Income, Transactions)
- Google Cloud API key stored in Supabase secrets ($300 credit until May 9 2026, Maps + Calendar + Geocoding enabled)
- Telnyx: REJECTED (white-label appeal denied)
- Plivo: REJECTED (trial account denied)
- **SignalWire: ACTIVE (S85)** — VoIP + SMS + Fax + Video. Replaces Telnyx+Plivo. Keys in all env files + Supabase secrets.
- **LiveKit: ACTIVE (S85)** — Video/meetings. Keys in all env files + Supabase secrets.
- SendGrid: REJECTED — pivoted to MS Graph (free, already have MS 365)
- OpenWeatherMap: SKIPPED — using Open-Meteo (free, no key)
- Still need: DocuSign, Indeed, Checkr, LinkedIn, FMCSA
- Partnership applications needed: Gusto Embedded, ZipRecruiter
- **FIREBASE→SUPABASE MIGRATION NEEDED:** Stripe (STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET) + Anthropic (ANTHROPIC_API_KEY) keys exist in Firebase secrets (`backend/functions/index.js` via `defineSecret`). Full Stripe payment integration (PaymentIntents, webhooks) + RevenueCat webhook handler + AI scan credits all running on Firebase Cloud Functions against Firestore on `zafto-2b563`. Must be migrated to Supabase Edge Functions. See `02_CIRCUIT_BLUEPRINT.md` Section 5 for full list of 11 Firebase functions pending migration.
- **SENTRY DSN EMPTY** — SDK wired in all 4 web apps + Flutter, but DSN is empty string everywhere. Need to grab DSN from Sentry dashboard and fill into env files.
- **RevenueCat** — webhook handler exists in Firebase (`revenueCatWebhook`), but no SDK API key stored for mobile IAP integration

**Information Security Policy (CREATED):**
- `ZAFTO_Information_Security_Policy.docx` — 13-section enterprise security policy
- Covers: RBAC, RLS, MFA (WebAuthn/passkeys/biometrics + TOTP), encryption (TLS 1.2+, AES-256), incident response, data retention, vulnerability management
- Created for Plaid compliance questionnaire, reusable for all future API applications

**C4 Sprint Specs Updated:**
- Added steps 8-10: WebAuthn/passkeys in Supabase Auth, passkey enrollment UI in all apps, security policy update
- Added 3 verification checkboxes

**API Cost Reference:**
- Saved to `memory/api-costs.md` — Plaid per-call pricing, coding rules (no polling, cache aggressively, one-time calls stored forever)
- Est. API cost per contractor: ~$3-5/mo vs $49-99/mo subscription = 90%+ margin

**Xactimate:** Owner found decryption tool for ESX files. Discussion pending.

**Next:** Finish remaining 7 API signups → Xactimate decryption discussion → Write Phase F sprint specs.

---

### Session 79 (Feb 7) — E5 + E6: Xactimate Estimates + Bid Walkthrough Engine

**E5: Xactimate Estimates (DONE — built in S79 continuation):**
- E5a-E5d: DB tables (xactimate_codes, pricing_entries, estimate_templates, etc.), models, repos, services
- E5e-E5f: Flutter estimate entry screens, Web CRM estimate pages
- E5g-E5i: Pricing pipeline Edge Functions, portal viewers
- E5j: Testing verification — all apps build clean
- Commits: multiple (see git log)

**E6a: Walkthrough Engine Data Model (DONE):**
- Migration 000028: walkthroughs, walkthrough_rooms, walkthrough_photos, walkthrough_templates, property_floor_plans (5 tables, RLS, audit triggers, 14 seed templates)
- 92 tables total deployed. Commit: 648a329

**E6b: Flutter Walkthrough Capture Flow (DONE):**
- 5 models (walkthrough, room, photo, template, floor_plan) + 1 repository + 1 service (7 Riverpod providers)
- 5 screens: list (filter chips), start (template selector), capture (room tabs, photo capture, dimensions, condition rating, auto-save), summary (warnings, weather), room detail sheet
- 12 files, 5,659 lines. dart analyze: 0 issues. Commit: 8465b41

**E6c: Photo Annotation System (DONE):**
- 7 annotation tools (draw, arrow, circle, rectangle, text, measurement, stamp)
- AnnotationLayer with undo/redo, AnnotationPainter CustomPainter, full-screen editor, before/after viewer
- 4 files, 2,026 lines. dart analyze: 0 issues. Commit: 78efc26

**E6d: Sketch Editor + Floor Plan Engine (DONE):**
- FloorPlanData model: walls, doors (7 types), windows (6 types), fixtures (27 types), labels, dimensions, room detection
- Command pattern undo/redo (100 history), SketchGeometry utilities, SketchPainter CustomPainter
- Multi-floor support, angle/endpoint snapping, symbol library (7 categories)
- 4 files, 4,900 lines. dart analyze: 0 issues. Commit: a929ea7

**E6f: Walkthrough Viewers — All Apps (DONE):**
- Web CRM: use-walkthroughs hook (CRUD + real-time), list page, detail page (rooms/photos/floor plan/notes tabs), bid generation review page, sidebar nav updated
- Team Portal: use-walkthroughs hook (read + mark-complete), list + detail pages
- Client Portal: use-walkthroughs hook (read-only), list + report view with print
- 11 files, 4,076 lines. All 3 portals build clean. Commit: 71af9d6

**E6g: AI Bid Generation Pipeline (DONE):**
- 4 Edge Functions: walkthrough-analyze (Claude Vision), walkthrough-transcribe, walkthrough-generate-bid (6 formats), walkthrough-bid-pdf (HTML generation)
- 4 files, 1,976 lines. All deployed to Supabase (22 total Edge Functions). Commit: 11e4a4a

**E6h: Walkthrough Workflow Customization (DONE):**
- use-walkthrough-templates hook (CRUD + clone + real-time)
- Settings > Walkthrough Workflows page: system templates (read-only + clone), custom template editor with room builder, custom fields, checklists, AI instructions
- 2 files, 1,442 lines. Web portal builds clean. Commit: 50e644c

**Deferred:** E6e (LiDAR — requires ARKit evaluation), E6i (3D Viewer — Phase 2)
**Session stats:** 37 new files, 20,079 lines of code, 7 commits, 4 Edge Functions deployed, 92 tables

### Session 78 (Feb 7) — R1 + E1 + E2: Flutter App Remake + AI Layer Infrastructure

**R1a: Design System + App Shell (DONE):**
- z_components.dart: 8 reusable components (ZCard, ZButton, ZTextField, ZBottomSheet, ZChip, ZBadge, ZAvatar, ZSkeleton)
- UserRole enum (8 roles + extensions) in lib/core/user_role.dart
- AppShell (IndexedStack + BottomNavigationBar + Z FAB) in lib/navigation/app_shell.dart
- role_navigation.dart: TabConfig + getTabsForRole for all 7 roles
- Retained existing theme system v2.6 (10 themes, color tokens)
- Commit: edf22f7

**R1b-R1h: All 7 Role Experiences (DONE):**
- Owner/Admin: 5 screens (home, jobs, money, calendar, more) in lib/screens/owner/
- Tech: 5 screens (home, walkthrough, jobs, tools, more) in lib/screens/tech/
- Office: 5 screens (home, schedule, customers, money, more) in lib/screens/office/
- Inspector: 5 screens (home, inspect, history, tools, more) in lib/screens/inspector/
- CPA: 4 screens (dashboard, accounts, reports, review) in lib/screens/cpa/
- Client: 5 screens (home, scan, projects, my_home, more) in lib/screens/client/
- Tenant: 4 screens (home, rent, maintenance, unit) in lib/screens/tenant/
- All 33 screens wired into AppShell via _buildTabScreens switch
- dart analyze: 0 errors across all files
- Deferred to R1j: field tool rewiring, quick actions, inspector DB tables, client DB tables
- Deferred to Phase E: Z-powered code lookup, AI home scanner, home health monitor
- Commit: fc7303e

**R1j: Role Switching + Navigation (DONE):**
- Created role_provider.dart (Riverpod StateProvider for current role)
- Created role_switcher_screen.dart (8-role picker, grouped sections)
- Updated AppShell with Switch Role quick action in Z button sheet
- Commit: 53149ca

**E1: Universal AI Architecture (DONE):**
- E1a: z_threads + z_artifacts tables deployed (migration 000025, 81 tables total)
- E1b: z-intelligence Edge Function deployed — Claude API proxy with SSE streaming
- E1c: 14 tools (searchCustomers, getJob, calculateMargin, etc.) with Supabase queries
- E1d: Artifact parser — detects `<artifact>` tags, saves to z_artifacts, streams events
- E1e: use-z-threads.ts, use-z-artifacts.ts hooks + api-client.ts SSE parser
- Provider updated with 5 new reducer actions (ADD_PARTIAL_CONTENT, CLEAR_PARTIAL_CONTENT, UPDATE_TOOL_CALLS, SET_TOKEN_COUNT, UPDATE_THREAD_ID)
- Dual-mode: mock (default) or live API (NEXT_PUBLIC_Z_INTELLIGENCE_ENABLED)
- ANTHROPIC_API_KEY secret NOT set yet (user action required)

**E2: Dashboard → Claude API Wiring (DONE):**
- Built as part of E1 — api-client.ts replaces mock engine, provider wired to sendToZ
- Slash commands handled via system prompt (Claude routes naturally)
- Artifact lifecycle: generate/edit/approve/reject/save draft all functional
- Context-aware system prompts in Edge Function
- Error handling in api-client callbacks + provider
- All 5 apps build clean (web portal npm run build, dart analyze 0 errors)

### Session 77 (Feb 7) — D5i + D5j: Integration Wiring + Testing (D5 COMPLETE)

**D5i: Integration Wiring + Rent Auto-Charge (DONE):**
- Created 3 Edge Functions: `pm-rent-charge` (daily rent generation + late fees), `pm-lease-reminders` (90/60/30 day notifications), `pm-asset-reminders` (14-day service alerts)
- Extended Flutter Job model with propertyId, unitId, maintenanceRequestId fields
- Wired handleItMyself in pm_maintenance_service.dart (creates job with PM linkage)
- Added completeMaintenanceJob (updates request + job status atomically)
- Wired CRM integration: createJobFromRequest, createRepairFromInspection, createJobFromTurnTask
- Wired rent payment → Ledger journal entry (debit Cash, credit Rental Income, property-tagged)
- Wired lease termination → auto-create unit turn
- Added recordServiceFromJob standalone function in use-assets.ts

**D5j: Testing + Seed Data (DONE):**
- Created seed SQL: 2 properties, 3 units, 3 tenants, 3 leases, 5 maintenance requests, 2 inspections, 6 assets, 3 service records, 3 rent charges, 1 payment
- Created 157 model tests across 3 files: property_test.dart (67), maintenance_request_test.dart (46), property_asset_test.dart (44)
- All tests pass, all 5 apps build clean
- **D5 IS NOW FULLY COMPLETE** — 18 tables, 14 CRM pages, 11 hooks, 10 Flutter screens, 3 Edge Functions, 157 tests

---

### Session 76 (Feb 7) — D5h: Team Portal Property Maintenance View

**D5h: Team Portal — Property Maintenance View (DONE):**
- Created `use-pm-jobs.ts` — `usePmJobs()` hook (property jobs WHERE property_id IS NOT NULL) + `useJobPropertyContext()` hook (parallel queries for property, tenant, maintenance request, assets)
- Created `use-maintenance-requests.ts` — `useMaintenanceRequests()` hook with real-time subscription + `updateRequestStatus()` mutation
- Created `properties/page.tsx` — Full maintenance requests page: filter tabs (All/Open/In Progress/Completed), search, urgency badges, tenant contact, status update buttons (Start Work/Mark Complete), linked job navigation
- Updated `mappers.ts` — Added `propertyId` to JobData + mapJob. Added PM types (MaintenanceRequestData, PropertySummary, PropertyAssetData), mapper functions, URGENCY_COLORS, MAINTENANCE_STATUS_LABELS
- Updated `jobs/[id]/page.tsx` — PropertyMaintenanceSection component: property details, tenant contact (clickable phone/email), maintenance request with urgency/category/status, property assets with condition indicators
- Updated `sidebar.tsx` — Added "Properties" nav item with Building2 icon in OVERVIEW section
- Updated `badge.tsx` — Added optional `label` prop to StatusBadge + maintenance status entries (new, assigned, cancelled)
- Updated `utils.ts` — Added new/assigned/cancelled status colors
- `npm run build` passes (25 routes, 0 errors)
- Committed + pushed to GitHub: `[D5h] Team Portal — Property maintenance view` (3067a10)

---

### Session 75 (Feb 7) — Xactimate Estimates Spec (DOCS ONLY)

**Xactimate Estimates — Expansion Spec (DONE):**
- Created `Expansion/25_XACTIMATE_ESTIMATE_ENGINE.md` — comprehensive spec covering:
  - Problem statement (Verisk monopoly, $300/mo, 30-50% suppressed pricing)
  - Product architecture (4 engines: Estimate Writer, Pricing DB, ESX Import/Export, PDF Output)
  - Data architecture (5 new tables: xactimate_codes, pricing_entries, pricing_contributions, estimate_templates, esx_imports + 1 ALTER on xactimate_estimate_lines)
  - Full Xactimate code system (70+ categories, MAT/LAB/EQU, coverage groups, O&P, units)
  - ESX file format (ZIP + XACTDOC XML + images, XML schema documented)
  - Pricing strategy (crowd-sourced from real ZAFTO invoices, anonymized, regional, confidence levels)
  - AI integration (PDF parsing, photo-to-estimate, scope gap detection, supplement generator)
  - 10 build phases (E5a-E5j, ~68 hrs total, ESX blocked on legal)
  - Competitive analysis (Xactimate vs Symbility vs iScope vs ZAFTO)
  - Legal framework (DMCA 1201(f), Sega/Sony/Google precedents, clean room protocol)
  - Risk register (6 risks with mitigations)
- Added Sprint E5 (10 sub-steps) to `07_SPRINT_SPECS.md` between E4 and Phase F
- Updated memory/xactimate-strategy.md status to SPEC COMPLETE
- NO CODE CHANGES — spec only. All 5 apps remain build-clean.

**Bid Walkthrough Engine — Expansion Spec (DONE):**
- Created `Expansion/44_BID_WALKTHROUGH_ENGINE.md` — comprehensive spec covering:
  - Full field-to-bid pipeline: room-by-room walkthrough, LiDAR, photos, annotations, voice notes, sketches
  - Property Sketch Editor: draw/edit floor plans, wall snapping, symbol library (6 trade categories), multi-floor
  - 2D Floor Plan Viewer/Editor across all 4 apps (Flutter editor, Web/Client/Team viewers)
  - 3D Property Viewer/Editor (Phase 2): LiDAR mesh rendering, 2D↔3D sync, cross-section views
  - Living Asset Map: equipment pinned on floor plans, full lifecycle tracking
  - Photo System: smart capture, annotation tools (draw/arrow/text/measure/stamp), before/after linking
  - AI Bid Generation: Claude analyzes all walkthrough data → generates format-perfect bids
  - Every bid format: standard, 3-tier, Xactimate/insurance, AIA/commercial, trade-specific, inspection report
  - Customizable Workflows: per-company templates with custom fields, checklists, room presets, AI instructions
  - Offline support: full capture offline, background upload when reconnected
  - 5 new tables (walkthroughs, walkthrough_rooms, walkthrough_photos, property_floor_plans, walkthrough_templates) + 3 ALTERs
- Added Sprint E6 (10 sub-steps, ~96 hrs) to `07_SPRINT_SPECS.md`
- Noted Flutter app modernization needed (separate sprint, not blocking walkthrough)

**Flutter App Remake — Expansion Spec (DONE):**
- Created `Expansion/45_FLUTTER_APP_REMAKE.md` — complete app rebuild spec covering:
  - 7 role-based experiences: Owner/Admin, Tech/Field, Office Manager, Inspector, CPA, Homeowner/Client, Tenant
  - Apple-crisp design system (light default, dark option, SF Pro typography, generous whitespace, haptic feedback)
  - Z Intelligence — NOT a chatbot. Three modes: voice-first (hands-free), camera-first (point-and-identify), ambient (contextual suggestions)
  - Complete tool inventory per role (Owner: 15 categories, Tech: 17, Office: 11, Inspector: 11, Homeowner: 13, CPA: 10, Tenant: 6)
  - Inspector deep dive: configurable checklists, pass/fail/conditional scoring, deficiency tracking + work order creation, re-inspection linking
  - Homeowner deep dive: Home Scanner (AI diagnosis from photos), Home Health Monitor (maintenance reminders), one-tap contractor requests
  - Removed features: Toolbox/calculators/code ref/exam prep (replaced by Z Intelligence)
  - 6 new tables (app_user_preferences, inspection_templates, inspection_results, inspection_deficiencies, home_scan_logs, home_maintenance_reminders)
  - Feature connectivity map: every mobile action → CRM visibility
- Added Sprint R1 (10 sub-steps, ~110 hrs) to `07_SPRINT_SPECS.md` — executes AFTER Phase D, BEFORE Phase E
- **Next:** Resume D5h (Team Portal — Property Maintenance View)

---

### Session 73 (Feb 7) — D5g: Client Portal Tenant Flows

**D5g: Client Portal Tenant Flows (DONE):**
- 1 mapper file: tenant-mappers.ts (13 interfaces, 10 mappers, 11 display helpers)
- 4 hooks: use-tenant.ts (tenant+lease+property+unit from auth), use-rent-payments.ts (charges+balance+payments), use-maintenance.ts (submit+track+rating), use-inspections-tenant.ts (read-only inspections)
- 6 new pages: rent (balance+charges), rent/[id] (charge detail+payments), lease (terms+expiry countdown), maintenance (submit form+request list), maintenance/[id] (status timeline+rating), inspections (completed reports)
- Updated home page: tenant rental property card with balance, lease status, quick actions; rent/maintenance/lease-expiry action cards
- Updated menu page: tenant services section (rent payments, lease, maintenance, inspections) prepended when tenant detected
- Updated layout: isActive recognizes new routes under Menu tab
- Stripe payment: UI placeholder ("Online payment coming soon"), Edge Function deferred to Phase E
- Auth: RLS policies already deployed (tenants_self, leases_tenant, rent_charges_tenant, rent_payments_tenant, maint_req_tenant_select/insert) — no code needed
- `npm run build` passes (29 routes, 0 errors)

---

### Session 72 (Feb 7) — D5e-D5f: Dashboard Schedule E + Flutter Properties Hub

**D5e: Dashboard + Ledger Schedule E (DONE — commit 6bbcb93):**
- Dashboard integration: property stats card, CRM properties hook
- Ledger Schedule E: expense property allocation columns, expense hook updated
- Migration: expense_records gets property_id, schedule_e_category, property_allocation_pct

**D5f: Flutter Properties Hub + Screens (DONE — commit 499019f):**
- 5 models: property.dart (Property, Unit, Tenant, Lease + 6 enums), maintenance_request.dart, property_asset.dart, inspection.dart, unit_turn.dart
- 7 repositories: property, tenant, lease, rent, pm_maintenance, inspection, asset
- 3 services: property_service (PropertiesNotifier, UnitsNotifier, AllUnitsNotifier, PropertyStats), pm_maintenance_service (THE MOAT: handleItMyself creates job from maintenance request), rent_service (payment recording with partial support)
- 10 screens: properties_hub, property_detail (5-tab), unit_detail, tenant_detail, lease_detail, rent, maintenance, inspection, asset, unit_turn
- Home screen: Properties added to feature carousel + more menu
- Command palette: properties_hub command registered with CommandType.property
- ZaftoColors: added `success` and `border` convenience aliases
- Fixed 80+ initial screen errors (API mismatches), 6 service-repo mismatches
- dart analyze: 0 errors across all 29 files

---

### Session 71 (Feb 7) — D5a-D5d: Property Management database + CRM pages

**D5a-D5d combined (commit b57d833):**
- 18 new tables via migration (properties, units, tenants, leases, rent_charges, rent_payments, maintenance_requests, work_order_actions, inspections, inspection_items, property_assets, asset_service_records, pm_documents, unit_turns, unit_turn_tasks, vendors, vendor_contacts, vendor_assignments)
- 11 CRM hooks + pm-mappers.ts
- 14 web pages in Properties sidebar section
- npm run build passes

---

### Session 70 (Feb 7) — D3e-D3n: Warranty + Upgrade + Storm + Reconstruction + Upsell + Vertical Detection — D3 COMPLETE

**D3l: Reconstruction Workflow Config (DONE):**
- Flutter InsuranceClaim model: added `ReconstructionPhase` enum (5 phases) + `reconstructionStageLabel` getter
- Reconstruction claims display phase in claim detail/hub screens

**D3m: Warranty-to-Retail Upsell Tracking (DONE):**
- Web CRM DispatchInbox: parallel query for upsell jobs (type_metadata JSONB)
- Conversion rate emerald badge ("X upsells, Y% conversion")
- Upsell indicator on individual dispatch cards (ArrowUpRight icon)

**D3n: Vertical Detection Service (DONE):**
- `use-verticals.ts` hook: queries storm-tagged jobs (≥5), reconstruction claims (≥3), commercial claims (≥2), warranty relationships (≥2)
- Dashboard: vertical widgets gated by detection. StormDashboardWidget, VerticalSummaryCard for Reconstruction/Commercial/Warranty
- Progressive disclosure: no config wizard, detection runs automatically from data

**D3 Phase 1+2 COMPLETE.** All sub-steps D3a through D3n done. Phase 3 is future (6+ months post-launch).

**D3e: Warranty Company Tables (done in S69, logged here):**
- Migration 000016: warranty_companies, company_warranty_relationships, warranty_dispatches
- 15 companies seeded (Rheem, Carrier, Trane, etc.)
- RLS: warranty_companies readable by all authenticated, relationships/dispatches scoped by company_id

**D3f: Upgrade Tracking — Insurance vs Out-of-Pocket:**
- PaymentSource enum (standard/carrier/deductible/upgrade) added to Flutter Invoice model
- Flutter invoice_create_screen: insurance job detection via Supabase query, payment source chip selector per line item
- Flutter invoice_detail_screen: grouped display by payment source with color-coded section headers + subtotals
- Web CRM types/index.ts: PaymentSource type + paymentSource on InvoiceLineItem
- Web CRM mappers.ts: mapInvoice includes paymentSource from JSONB
- Web CRM invoices/new: payment source dropdown per row (visible for insurance/warranty jobs), default carrier
- Web CRM invoices/[id]: grouped table display with colored section headers
- Web CRM jobs/[id]: UpgradeTrackingSummary component — queries invoices, shows per-source breakdown card
- Fixed dead code warnings: removed `?? ''` on non-nullable customerName in both invoice screens
- Fixed dangling doc comments: `///` → `//` in both invoice screens
- `dart analyze` 0 issues, `npm run build` passes

**Next Steps:** D3g (Carrier Communication Log) → D3h → D3i → D3j → D3k → D3l → D3m → D3n → D4 (Ledger).

**D4 Ledger Spec (DONE):**
- Wrote comprehensive D4 spec (16 sub-steps D4a-D4p, ~78 hours) into sprint specs
- Tier 1 (all contractors): GAAP double-entry, audit trail, Schedule C tax mapping, 1099 compliance
- Tier 2 (enterprise): WIP tracking, AIA billing, retention, bonding, multi-entity

**D4a: Core Ledger Tables — Migration 000018 (DONE):**
- 6 tables: chart_of_accounts, fiscal_periods, journal_entries, journal_entry_lines, tax_categories, zbooks_audit_log
- 55 COA accounts seeded via `seed_chart_of_accounts()` trigger on company creation
- 26 tax categories seeded via `seed_tax_categories()` trigger
- All NUMERIC(12,2) for currency. INSERT-only audit log. RLS via `requesting_company_id()`

**D4b: Banking, Expenses & Vendors — Migration 000019 (DONE):**
- 7 tables: vendors, expense_records, vendor_payments, bank_accounts, bank_transactions, bank_reconciliations, recurring_transactions
- `bank_accounts_safe` view (excludes plaid_access_token from frontend)
- Partial indexes for unreviewed/unreconciled/1099 queries
- 59 total tables deployed

**D4c: GL Engine — Auto-Posting (DONE):**
- `use-zbooks-engine.ts`: Core GL engine with auto-posting functions (invoice→JE, payment→JE, expense→JE, vendor payment→JE, void→reversing entry, fiscal period management)
- `use-zbooks.ts`: Journal entry CRUD hooks + account balances + GL detail
- `zbooks_service.dart`: Flutter read-only service with Riverpod providers (JournalEntry, AccountBalance, FinancialSummary models)
- Wired into `use-invoices.ts`: sendInvoice() → createInvoiceJournal(), recordPayment() → createPaymentJournal()
- `dart analyze` 0 issues, `npm run build` passes

**D4d: Chart of Accounts UI (DONE):**
- Web CRM `/dashboard/books/accounts` page: grouped list by type (6 groups), search/filter, add/edit modal, deactivate with JE protection, system account lock, balance columns from GL
- `use-accounts.ts` hook: CRUD + tax categories + groupedAccounts helper + deactivation guard
- Books landing page: navigation tabs (Overview / Chart of Accounts)
- Flutter `screens/books/chart_of_accounts_screen.dart`: read-only COA list with type grouping, filter chips, search, GL balances, ZaftoColors design tokens
- `npm run build` passes, `dart analyze` 0 issues

**D4e: Vendor Management & Expense Tracking (DONE):**
- Web CRM `/dashboard/books/vendors`: Vendor CRUD, type/search filters, detail panel (contact, address, YTD payments, 1099 flag), payment terms
- Web CRM `/dashboard/books/expenses`: Expense CRUD, approval workflow (draft→approved→posted→voided), receipt upload to Storage, category/date/status filters, auto-JE on post, void with reversing entry
- Web CRM `/dashboard/books/vendor-payments`: Payment recording, auto-JE (DR AP, CR Cash), 1099 tracking, check number support
- `use-vendors.ts` hook: CRUD + YTD payment aggregation + 1099 detection
- `use-expenses.ts` hook: CRUD + approval/post/void workflow + receipt upload + auto-JE wiring
- Books landing page: 5 navigation tabs (Overview, Chart of Accounts, Expenses, Vendors, Vendor Payments)
- Flutter `expense_entry_screen.dart`: Quick expense entry with amount, category chips, payment method, date picker, receipt camera/gallery capture + Supabase upload
- Flutter `expense_list_screen.dart`: Expense list with status filter, summary card, category icons
- `npm run build` passes (48 routes), `dart analyze` 0 issues

**D4f: Bank Connection — Plaid Integration (DONE):**
- Edge Function `plaid-create-link-token`: Generates Plaid Link token (JWT auth, company_id from app_metadata)
- Edge Function `plaid-exchange-token`: Exchanges public_token → access_token, fetches accounts, upserts to bank_accounts via service role
- Edge Function `plaid-sync-transactions`: Fetches transactions from Plaid, auto-categorizes (21 Plaid→ZAFTO category mappings), invoice matching (amount + 5-day proximity), upserts to bank_transactions
- Edge Function `plaid-get-balance`: Refreshes current/available balance from Plaid
- `use-banking.ts` hook: Account CRUD via bank_accounts_safe view, Edge Function calls (createLinkToken, exchangeToken, syncTransactions, refreshBalance), transaction categorization + review workflow
- Web CRM `/dashboard/books/banking`: Plaid Link integration (react-plaid-link), connected accounts cards with sync/refresh/disconnect, transaction list with search/filter, category dropdown, review workflow
- Books landing page: 6 navigation tabs (added Banking)
- `plaid_access_token` security: service role only writes it, frontend reads `bank_accounts_safe` view (excludes token column)
- `npm run build` passes (49 routes), `dart analyze` 0 issues

**D4g: Bank Reconciliation (DONE):**
- `use-reconciliation.ts` hook: Start/resume/complete/void reconciliation workflow, transaction matching, save progress
- Web CRM `/dashboard/books/reconciliation`: Start form (select account, statement date/balance), transaction list with checkboxes, running difference calculation (green at $0, red otherwise), filter cleared/uncleared, "Finish Later" saves progress, "Complete" requires $0 difference, void un-reconciles all transactions
- Reconciliation history table with status badges, resume for in-progress, void for completed
- Books nav: 7 tabs (added Reconciliation)
- `npm run build` passes (50 routes)

**D4h: Financial Statements (DONE):**
- `use-financial-statements.ts` hook: P&L, Balance Sheet, Cash Flow, AR/AP Aging, GL Detail, Trial Balance — all from journal_entry_lines + chart_of_accounts aggregation
- Web CRM `/dashboard/books/reports`: 7 report tabs, date range / as-of-date / period selectors, account picker for GL Detail
- P&L: Revenue - COGS = Gross Profit - Expenses = Net Income, with account-level detail
- Balance Sheet: Assets = Liabilities + Equity validation, current year net income auto-calculated
- Cash Flow: Indirect method (net income + AR/AP changes + investing + financing = net cash change)
- AR Aging: By customer, 5 buckets (Current, 1-30, 31-60, 61-90, 90+), from open invoices
- AP Aging: By vendor, 5 buckets, from unpaid expenses
- GL Detail: Per-account journal entry list with running balance, opening/closing balance
- Trial Balance: All accounts, debit/credit columns, balanced validation
- Print/PDF via window.print()
- Books nav: 8 tabs (added Reports)
- `npm run build` passes (51 routes)

**D4i: Tax & 1099 Compliance (DONE):**
- `use-tax-compliance.ts` hook: Tax category mapping, 1099 auto-detection ($600+ threshold), Schedule C computation from journal entries, CSV export, quarterly tax estimates
- Web CRM `/dashboard/books/tax-settings`: 3-tab page — Tax Mapping (COA → tax category dropdowns), 1099 Vendors (masked tax IDs, YTD payments, status badges, CSV export), Schedule C (IRS line format, quarterly SE + income tax estimates)
- `npm run build` passes (52 routes)

**D4j: Recurring Transactions (DONE):**
- `use-recurring.ts` hook: Template CRUD, pause/resume, generateNow (creates expense/invoice from template_data, advances next_occurrence), generation history lookup
- Web CRM `/dashboard/books/recurring`: Template list with type/frequency/status badges, create/edit modal, Generate Now action, expandable generation history, summary cards (active/due/generated counts)
- Edge Function `recurring-generate`: Daily cron — queries due templates, creates expense_records/invoices, advances dates, auto-deactivates past end_date
- 5 frequency options: weekly, biweekly, monthly, quarterly, annually
- `npm run build` passes (53 routes)

**D4k: Fiscal Period Management & Year-End Close (DONE):**
- `use-fiscal-periods.ts` hook: Auto-generate 12 monthly periods, close/reopen individual periods, year-end close (verifies all periods closed, creates closing JEs to Retained Earnings 3200), audit log
- Web CRM `/dashboard/books/periods`: Year selector, period list with close/reopen, year-end close modal with requirements checklist, audit trail

**D4l: Ledger Dashboard Rewrite (DONE):**
- Rewrote `books/page.tsx` dashboard with live data from useBanking, useFinancialStatements, useReconciliation hooks
- 5 KPI cards, P&L bar chart placeholder, expense donut chart placeholder, 4 alert cards, quick links grid

**D4m: Flutter Mobile Ledger (DONE):**
- Models: `expense_record.dart` (enums: category/payment/OCR/status), `vendor.dart`
- Repositories: `expense_repository.dart`, `vendor_repository.dart` (full CRUD + soft delete)
- Services: `expense_service.dart` (ExpenseService + VendorService with auth-enriched CRUD + Riverpod providers)
- `zbooks_hub_screen.dart`: Financial summary card, quick actions, recent expenses list, COA link
- Wired Ledger into home_screen_v2.dart More menu (bookOpen icon → ZBooksHubScreen)
- `dart analyze` 0 new issues

**D4n: CPA Portal Access (DONE):**
- `use-cpa-access.ts` hook: CPA role detection, access logging, export package generation (P&L + BS + TB + 1099), CSV export utility
- Web CRM `/dashboard/books/cpa-export`: Date range selector, report summary cards, CSV downloads, export watermark

**D4o: Branch Financials (DONE):**
- `use-branch-financials.ts` hook: Branch P&L, consolidated view, comparison, performance metrics
- Web CRM `/dashboard/books/branches`: Branch selector, consolidated P&L, comparison mode, performance dashboard

**D4p: Construction Accounting (DONE):**
- Migration 000020: `progress_billings` (AIA G702/G703) + `retention_tracking` tables with RLS + indexes. 61 total tables.
- `use-construction-accounting.ts` hook: Progress billing CRUD, retention tracking with release workflow, WIP report, certified payroll WH-347
- Web CRM `/dashboard/books/construction`: Progress billing list, retention dashboard, WIP analysis, payroll viewer
- `npm run build` passes (54 routes, 0 errors)

**D4 ZBOOKS COMPLETE.** All 16 sub-steps (D4a-D4p) done. Next: D5 (Property Mgmt — needs spec session).

---

### Session 69 (Feb 7) — D3a-D3d: Insurance Verticals (Claim Categories + Vertical Data)

**D3a: Database Migration 000015 (claim_category column):**
- Added `claim_category TEXT NOT NULL DEFAULT 'restoration'` to insurance_claims
- CHECK constraint: 4 values (restoration, storm, reconstruction, commercial)
- Index: `idx_insurance_claims_category`
- JSONB `data` column documents vertical-specific structure per category

**D3b-D3d: Flutter Model (insurance_claim.dart — 3 new typed data classes):**
- `StormData`: weatherEventDate, stormSeverity (4 levels), weatherEventType (6 types), aerialAssessmentNeeded, emergencyTarped, temporaryRepairs, batchEventId, affectedUnits
- `ReconstructionData`: currentPhase (5 phases), phases[] with status/budget/completion%, multiContractor, expectedDurationMonths, permitsRequired, permitStatus
- `CommercialData`: propertyType (8 types), businessName, tenantName, tenantContact, businessIncomeLoss, businessInterruptionDays, emergencyAuthAmount, emergencyServiceAuthorized
- All 3 classes have `fromJson()` factory + `toJson()` method for JSONB serialization
- `InsuranceClaim` model has convenience getters: `stormData`, `reconstructionData`, `commercialData`

**Flutter Screens (3 files modified):**
- `claim_create_screen.dart`: Category selector (4 chips with description). Category-specific form sections: Storm (severity, event type, emergency tarped, aerial, temp repairs), Reconstruction (duration, permits, multi-contractor), Commercial (property type, business name, tenant, emergency auth). Data saved as JSONB via `_buildCategoryData()`.
- `claim_detail_screen.dart`: `_buildCategoryDataCard()` renders category icon + accent border + typed data rows. Storm shows severity + event type + tarped + aerial. Reconstruction shows phase + duration + permits + phase list. Commercial shows property + business + tenant + income loss + interruption days.
- `claims_hub_screen.dart`: Category filter chips row + `_filterCategory` state + `_buildCategoryBadge()` on claim cards.
- `insurance_claim_service.dart`: `createClaim()` accepts `data` parameter for JSONB.

**Web CRM Types (types/index.ts — 3 new interfaces):**
- `StormClaimData`, `ReconstructionClaimData`, `CommercialClaimData` with full type safety

**Web CRM Detail Page (insurance/[id]/page.tsx):**
- `CategoryDataCard` component with icon + accent border per category
- `StormDetails`: severity badge (color-coded), event type, tarped, aerial, temp repairs
- `ReconDetails`: current phase, duration, permits, multi-contractor, phase list with status badges
- `CommercialDetails`: property type, business name, tenant, income loss, interruption, emergency auth
- `DetailRow` value type widened to `React.ReactNode` for badge rendering

**Web CRM Hub Page (insurance/page.tsx):**
- Category filter buttons (All Types + 4 categories)
- Category badge on claim rows (non-restoration only)

**Team Portal (mappers.ts):**
- Added `ClaimCategory` type + `claimCategory` field to `InsuranceClaimSummary` + mapper

**Build Verification:**
- `dart analyze`: 0 errors
- `web-portal npm run build`: Passes (43 routes, 0 errors)
- `team-portal npm run build`: Passes (24 routes, 0 errors)
- `client-portal npm run build`: Passes (22 routes, 0 errors)
- Migration 000015: Deployed to dev

**Next Steps:** D3e (Warranty Networks) → D4 (Ledger) → Phase E (AI Layer).

---

### Session 68 (Feb 7) — D7a Modular: Configurable Cert Types + Immutable Audit Log

**Database Migration 000014 (2 new tables):**
- `certification_types`: Configurable certification types per company. 25 system defaults seeded across 6 categories (regulatory, safety, license, trade, environmental, specialty). Companies can add custom types without migrations. Fields: type_key, display_name, category, description, regulation_reference, applicable_trades TEXT[], applicable_regions TEXT[], required_fields JSONB, attachment_required, default_renewal_days, default_renewal_required, is_system, is_active, sort_order. UNIQUE(company_id, type_key). System types are read-only.
- `certification_audit_log`: INSERT-only immutable change tracking. No UPDATE/DELETE RLS policies. Fields: certification_id, action (created/updated/status_changed/deleted/renewed), changed_by, previous_values JSONB, new_values JSONB, change_summary TEXT, ip_address. Indexed on certification_id + created_at.

**Web CRM (use-enterprise.ts modified):**
- Added `CertificationTypeConfig` interface (17 fields) + `mapCertificationType()` mapper
- Added `useCertificationTypes()` hook — fetches from certification_types table, returns `{ types, typeMap, loading }`
- Added `writeCertAuditLog()` async helper — fire-and-forget INSERT to certification_audit_log
- Wired audit log into create/update/delete methods (3 actions logged)

**Web CRM (certifications page.tsx modified):**
- Removed hardcoded `CERTIFICATION_TYPES` array (26 entries) + `CERT_TYPE_MAP`
- Now loads types dynamically from `useCertificationTypes()` hook
- Modal auto-fills renewal settings from DB type config (defaultRenewalRequired, defaultRenewalDays)

**Team Portal (3 files modified):**
- `mappers.ts`: Added `CertificationTypeConfig` interface + `mapCertificationType()` mapper
- `use-certifications.ts`: Added `useCertificationTypes()` hook
- `certifications/page.tsx`: Removed hardcoded `CERT_TYPE_LABELS` (26 entries). Uses dynamic `typeMap[...].displayName`

**Flutter (3 files modified):**
- `certification.dart`: Added `CertificationTypeConfig` model class with `fromJson` factory
- `certification_service.dart`: Added `certificationTypesProvider` (FutureProvider.autoDispose) querying certification_types table
- `certifications_screen.dart`: Updated build() to watch `certificationTypesProvider`. Detail view + add cert dropdown + _CertCard all use dynamic labels with enum fallback.

**Build Verification:**
- `dart analyze`: 0 errors (4 pre-existing info warnings)
- `web-portal npm run build`: Passes (43 routes, 0 errors)
- `team-portal npm run build`: Passes (24 routes, 0 errors)
- Migration 000014: Pushed to dev Supabase successfully

**Circuit Blueprint updated.** 43 tables, 14 migrations, all counts corrected.

**D2f: Certificate of Completion — DONE:**

**Flutter (job_completion_screen.dart modified):**
- Detects `job_type == 'insurance_claim'` via Supabase query on initState
- Looks up linked `insurance_claims` record for TPI queries
- Adds 4 insurance-specific checks to the standard 7:
  - Moisture Readings at Target: all `moisture_readings.is_dry = true`
  - Equipment Removed: no `restoration_equipment` with status `deployed` or `maintenance`
  - Drying Complete: at least one `drying_logs` with `log_type = 'completion'`
  - TPI Final Passed: `tpi_scheduling` with `inspection_type = 'final_inspection'`, `status = 'completed'`, `result = 'passed'`
- On "Complete Job": also transitions `insurance_claims.claim_status` to `work_complete` and sets `work_completed_at`
- Title changes to "Insurance Completion" for insurance jobs
- Dialog message explains claim status advancement

**Web CRM (insurance/[id]/page.tsx modified):**
- Added 7th "Completion" tab (Award icon) with pre-flight checklist
- CompletionTab component computes 4 checks from existing hook data (no extra queries):
  - Moisture all dry, equipment all removed, drying completion logged, TPI final passed
- Progress bar + percentage + pass/fail per check
- Status-aware action buttons: "Mark Work Complete" (when work_in_progress + all checks pass), "Request Final Inspection" (when work_complete), "Settle Claim" (when final_inspection)
- Tab badge shows X/4 completion count (green when 4/4)
- Settled state shows confirmation card

**Build Verification:**
- `dart analyze`: 0 errors (5 pre-existing info warnings)
- `web-portal npm run build`: Passes (43 routes, 0 errors)
- One fix needed during build: TpiInspectionType uses `'final'` not `'final_inspection'` in TS types

**D2h: Team/Client Portal Insurance Views — DONE:**

**Team Portal (3 files created/modified):**
- `mappers.ts` — Added 16 insurance/restoration types (ClaimStatus, EquipmentStatus, EquipmentType, MaterialMoistureType, ReadingUnit, DryingLogType, TpiInspectionType, TpiStatus, TpiResult) + 6 interfaces (InsuranceClaimSummary, MoistureReadingData, DryingLogData, RestorationEquipmentData, TpiInspectionData) + 5 mapper functions
- `use-insurance.ts` (NEW) — `useJobInsurance(jobId)` hook fetches claim + moisture + drying + equipment + TPI with real-time subscriptions on 5 tables. 4 mutation functions: `addMoistureReading()`, `addDryingLog()`, `deployEquipment()`, `removeEquipment()`
- `jobs/[id]/page.tsx` — Enhanced job detail for insurance claims: RestorationProgress card (claim status banner, moisture readings with dry/wet summary + inline add form, drying status with latest log + inline add form, equipment deploy/remove with inline form, TPI inspection schedule). 3 inline form components: MoistureForm, DryingForm, EquipmentForm

**Client Portal (3 files created/modified):**
- `use-insurance.ts` (NEW) — `useProjectClaim(jobId)` hook fetches claim summary with real-time. Homeowner-friendly status labels (13 statuses mapped to plain English descriptions). Timeline steps. Privacy-safe (no adjuster contact info).
- `projects/[id]/page.tsx` — Insurance claim banner (company + claim # + date of loss). Claim Status tab replaces generic Timeline when insurance. Visual timeline with 6 steps (Filed→Approved→Work Started→Complete→Inspection→Settled), green dots for completed steps. Status description card. Insurance details in Details tab (company, claim #, deductible). Denied state handling.
- `projects/page.tsx` — Insurance badge (Shield icon) on project list cards

**Build Verification:**
- `team-portal npm run build`: Passes (24 routes, 0 errors)
- `client-portal npm run build`: Passes (22 routes, 0 errors)

**Next Steps:** D3 (Insurance Verticals) → D4 (Ledger) → Phase E (AI Layer).

---

### Session 67 (Feb 7) — D7a COMPLETE: Certification Tracker (All 3 Apps)

**Flutter Navigation Wiring (3 files modified):**
- `command_registry.dart`: Added `builder` function to certifications command + import. Cmd+K palette now launches CertificationsScreen.
- `command_palette.dart`: Added `'certifications'` case to `_navigateToCommand()` switch + import.
- `settings_screen.dart`: Added "CERTIFICATIONS & LICENSES" section with navigation tile (Award icon, EPA/OSHA/state subtitle).
- `home_screen_v2.dart`: Added certifications entry to "More" menu (Award icon).

**Web CRM Certifications Page (1 new file + 1 modified):**
- Created `dashboard/certifications/page.tsx` — Full management page:
  - 25 certification types matching Flutter enum (EPA 608, OSHA 10/30, state licenses, IICRC, CDL, etc.)
  - Summary cards (total, active, expiring, expired)
  - Search + 5-way status filter (all/active/expiring/expired/revoked)
  - Certification list with computed expiry status, days-until-expiry, employee name resolution
  - Create/Edit modal with: employee selector, type dropdown, auto-fill name/authority, dates, renewal settings (30/60/90 day reminder), status management, notes
  - Delete with confirmation
  - Permission-gated: `certifications.view` for page, `certifications.manage` for add/edit
  - Uses existing `useCertifications()` hook from `use-enterprise.ts` + `useTeam()` from `use-jobs.ts`
- Modified `sidebar.tsx`: Added "Certifications" nav item under RESOURCES (Award icon, permission-gated)
- Route: `/dashboard/certifications` (6.74 kB)

**Team Portal Certifications Page (3 new files + 2 modified):**
- Created `use-certifications.ts` hook — `useMyCertifications()` queries certifications filtered by `auth.uid()`. Real-time Supabase subscription.
- Added `CertificationData` interface + `mapCertification()` mapper to `mappers.ts`.
- Created `dashboard/certifications/page.tsx` — Employee self-service view:
  - Summary cards (active/expiring/expired counts)
  - Search + 4-way filter tabs
  - Expandable certification cards with detail view (issuer, number, dates, renewal reminder, notes)
  - Computed status with color coding (green/amber/red)
  - Read-only (admin manages via CRM, employee views here)
  - Skeleton loading state
- Modified `sidebar.tsx`: Added "Certifications" nav item under BUSINESS (Award icon)
- Route: `/dashboard/certifications` (6.02 kB)

**Build Verification:**
- `flutter analyze`: 0 errors (pre-existing warnings/infos only)
- `web-portal npm run build`: Passes (43 routes, 0 errors)
- `team-portal npm run build`: Passes (24 routes, 0 errors)

**Files Created (4 new):**
- `web-portal/src/app/dashboard/certifications/page.tsx`
- `team-portal/src/app/dashboard/certifications/page.tsx`
- `team-portal/src/lib/hooks/use-certifications.ts`

**Files Modified (6):**
- Flutter: `command_registry.dart`, `command_palette.dart`, `settings_screen.dart`, `home_screen_v2.dart`
- Web CRM: `sidebar.tsx`
- Team Portal: `sidebar.tsx`, `mappers.ts`

**D7a is now COMPLETE.** All 3 apps have certification tracking:
- Flutter: Full CRUD screen (609 lines) + 4 navigation paths (Cmd+K, settings, home More menu, command palette)
- Web CRM: Full management page with team assignment, 25 cert types, compliance-aware expiry tracking
- Team Portal: Employee self-service view with expandable detail cards

**Next Steps:** D2f (Certificate of Completion) → D2h (Team/Client Portal Insurance Views) → D3 (Insurance Verticals) → Phase E (AI Layer).

---

### Session 66 (Feb 7) — D6c Fixes + D7a Partial (Certification Tracker Flutter Screen)

**D6c Fixes (Web CRM settings page):**
- Added missing `getSupabase` import to settings/page.tsx (TradeModulesSettings calls getSupabase() directly).
- Fixed Badge variant `"outline"` → `"info"` (outline variant doesn't exist in ZAFTO's Badge component).
- `npm run build` passes clean (42 routes, 0 errors).

**D7a Partial (Flutter Certification Tracker Screen):**
- Created `lib/screens/certifications/certifications_screen.dart` (609 lines).
- Full CRUD UI: list view with status filter chips (all/active/expiring/expired), create bottom sheet (name, issuer, number, issue date, expiry, notes, type dropdown), detail view with renewal/delete actions.
- Uses existing certification_service.dart + certification_repository.dart + certification.dart from D6b.
- Fixed 2 compile errors: `borderLight` → `borderSubtle` (ZaftoColors API).
- Added command registry entry (id: 'certifications', type: settings, icon: award, 9 keywords).
- `dart analyze` passes (0 errors, 4 infos — non-blocking).

**NOT DONE (still pending for D7a):**
- Web CRM certifications page/tab (dedicated page or settings integration).
- Team Portal certifications view (employee sees their own certs).
- Navigation wiring (certifications screen not yet reachable from any UI — registry entry exists but no route/builder).

**Files Created/Modified:**
- Flutter (1 new): `lib/screens/certifications/certifications_screen.dart`
- Flutter (1 modified): `lib/services/command_registry.dart` (added certifications entry)
- Web CRM (1 modified): `src/app/dashboard/settings/page.tsx` (getSupabase import + Badge fix)

**Next Steps:** Finish D7a (navigation wiring, Web CRM page, Team Portal page) → D2f → D2h → D3.

---

### Session 65 (Feb 7) — Phase D6: Enterprise Foundation — D6a-D6c Complete

**D6a: Database Migration (5 new tables + ALTERs + seed data):**
- Migration `20260207000013_d6_enterprise_foundation.sql`: 5 new tables (branches, custom_roles, form_templates, certifications, api_keys).
- ALTERed users (branch_id, custom_role_id), jobs (branch_id), customers (branch_id), compliance_records (form_template_id).
- Extended compliance_records record_type CHECK constraint to include new enterprise types.
- Updated handle_new_user() and handle_user_role_change() triggers.
- Seeded 29 system form templates across 15 trades (electrical, plumbing, HVAC, roofing, etc.).
- Deployed to dev — 41 tables total, 13 migration files. All synced.

**D6b: Flutter Enterprise Models + Services (14 new files):**
- 5 models: branch.dart, custom_role.dart, form_template.dart, certification.dart, api_key.dart.
- 4 repositories: branch_repository.dart, custom_role_repository.dart, form_template_repository.dart, certification_repository.dart.
- 4 services with Riverpod providers: branch_service.dart, custom_role_service.dart, form_template_service.dart, certification_service.dart.
- Updated compliance_record.dart with formSubmission type + formTemplateId field.
- `flutter analyze` passes 0 errors.

**D6c: Web CRM Enterprise Permissions + Settings (extended + new files):**
- Extended permission-gate.tsx with 7 new enterprise permissions + custom role support.
- Updated auth-provider.tsx with customRoleId and branchId fields.
- Created use-enterprise.ts hook (5 hooks: useBranches, useCustomRoles, useFormTemplates, useCertifications, useApiKeys).
- Added 5 enterprise settings tabs (Branches, Trade Modules, Roles & Permissions, Compliance Forms, API Keys) with TierGate visibility.
- 13 hook files total in web-portal (was 12).
- `npm run build` passes 0 errors.

**Files Created/Modified:**
- SQL (1): 20260207000013_d6_enterprise_foundation.sql
- Flutter (14): 5 models, 4 repos, 4 services, 1 updated (compliance_record.dart)
- Web CRM (modified): permission-gate.tsx, auth-provider.tsx. Created: use-enterprise.ts, 5 enterprise settings tab components.

**Next Steps:** D7a (Certification Tracker) -> D2f (Certificate of Completion) -> D2h (Team/Client Portal Insurance Views) -> D3 (Insurance Verticals).

---

### Session 63-64 (Feb 7) — Phase D2: Insurance Claim Workflows — D2a-D2g Complete

**D2a: Database Migration (7 tables + financial depth columns):**
- Migration 20260207000011_d2_insurance_tables.sql: 7 new tables (insurance_claims, claim_supplements, tpi_scheduling, xactimate_estimate_lines, moisture_readings, drying_logs, restoration_equipment). Full RLS. Audit triggers. Indexes.
- Migration 20260207000012_d2_financial_depth.sql: Added depreciation_recovered + amount_collected to insurance_claims. Added rcv_amount + acv_amount + depreciation_amount to claim_supplements.
- 12 migration files total. 36 tables deployed to dev. All synced.

**D2b: Insurance Claims CRUD (Flutter + Web CRM):**
- Flutter: 3 screens — claims_hub_screen.dart (list with status filters), claim_detail_screen.dart (6 tabs: Overview, Supplements, TPI, Moisture, Drying, Equipment), claim_create_screen.dart (create from insurance_claim job).
- Web CRM: 2 pages — /dashboard/insurance/page.tsx (list + pipeline view), /dashboard/insurance/[id]/page.tsx (detail with 6 tabs + sidebar with adjuster info).
- Hook: use-insurance.ts (useClaims, useClaim, useClaimByJob, createClaim, updateClaimStatus, updateClaim, deleteClaim).
- Full claim status workflow: new -> scope_requested -> scope_submitted -> estimate_pending -> estimate_approved -> supplement_submitted -> supplement_approved -> work_in_progress -> work_complete -> final_inspection -> settled -> closed (or denied from any state).

**D2c: Supplement Tracking:**
- Flutter: Supplements tab in claim_detail with create bottom sheet, status badges, action buttons.
- Web CRM: SupplementsTab with summary bar, inline create form, status workflow (draft -> submitted -> under_review -> approved/denied/partially_approved).
- RCV/ACV/depreciation amount tracking per supplement.
- Hook additions: createSupplement, updateSupplement, updateSupplementStatus, deleteSupplement.

**D2d: Moisture Monitoring + Drying Logs:**
- Flutter: MoistureReading + DryingLog models and repos. Moisture + Drying tabs in claim_detail.
- Web CRM: Moisture table + Drying log entries in detail page.
- Material-specific targets (drywall 12%, wood 15%, concrete 17%). Visual is_dry indicator.
- Drying logs are immutable (INSERT-only, no edit/delete — legal compliance).

**D2e: Equipment Tracking:**
- Flutter: RestorationEquipment model + repo. Equipment tab in claim_detail.
- Web CRM: Equipment section in detail page. Deploy/remove actions.
- Daily rate * days calculation. 9 equipment types. Status: deployed/removed/maintenance/lost.

**D2g: TPI Scheduling:**
- Flutter: TpiInspection model + repo. TPI tab in claim_detail. Schedule, track, record results.
- Web CRM: TPI section in detail page. Status flow: pending -> scheduled -> confirmed -> in_progress -> completed/cancelled/rescheduled.
- 5 inspection types. Result recording with findings.

**NOT DONE (pending):**
- D2f: Certificate of Completion — insurance completion checklist, moisture/equipment/TPI validation.
- D2h: Team Portal + Client Portal Insurance Views — field tech claim job visibility, homeowner claim status.

**Files Created:**
- Flutter (18): 6 models (insurance_claim.dart, claim_supplement.dart, moisture_reading.dart, drying_log.dart, restoration_equipment.dart, tpi_inspection.dart), 6 repos, 2 services (insurance_claim_service.dart, restoration_service.dart), 3 screens (claims_hub, claim_create, claim_detail), 12+ Riverpod providers.
- Web CRM (3): 2 pages (insurance/page.tsx, insurance/[id]/page.tsx), 1 hook (use-insurance.ts).

**Next Steps:** D2f (Certificate of Completion) -> D2h (Team/Client Portal insurance views) -> D3 (Insurance Verticals).

---

### Session 62 (Feb 7) — Phase D1: Job Type System — Complete

**D1a: Type Metadata Structures (all 4 web portals):**
- Web CRM: Added `JobType`, `InsuranceMetadata`, `WarrantyMetadata` types to `types/index.ts`. Added `JOB_TYPE_LABELS`, `JOB_TYPE_COLORS` maps to `mappers.ts`. Updated `mapJob()`, `createJob()`, `updateJob()`, `useSchedule()` with job type support.
- Team Portal: Added type interfaces, labels, colors to `mappers.ts`. Updated `mapJob()`, `createJob()`, `updateJob()`.
- Client Portal: Added type support to `mappers.ts`, updated `mapProject()`.
- All builds pass (0 errors).

**D1b: Flutter Mobile UI:**
- Added `jobTypeLabel`, `isInsuranceClaim`, `isWarrantyDispatch`, `hasTypeMetadata` computed properties to Job model.
- Job Create: SegmentedButton type selector, conditional insurance fields (company, claim#, date of loss, adjuster, deductible), conditional warranty fields (company, dispatch#, auth limit, service fee, type).
- Job Detail: Type badge in status section + full metadata card with read-only display.
- Jobs Hub: Type badge on job list cards.
- `flutter analyze` passes (0 errors).

**D1c: Web CRM UI (3 pages):**
- Jobs list (`page.tsx`): `JobTypeBadge` component, type filter dropdown, badges on `JobRow` and `JobCard`.
- New Job (`new/page.tsx`): Job type selector (3 buttons: Standard/Insurance/Warranty), conditional insurance/warranty metadata fields, wired to `createJob()` hook (replaced `TODO: Save to Firestore`).
- Job Detail (`[id]/page.tsx`): Type badge in header, `TypeMetadataCard` in sidebar (insurance: company/claim/adjuster/deductible/approval status; warranty: company/dispatch#/type/auth limit/NTE).
- Dashboard (`page.tsx`): Type badges on Active Jobs section, calendar already color-coded via `useSchedule()`.
- `npm run build` passes (0 errors).

**D1d: Team Portal + Schedule Colors:**
- Jobs list: Type badge (small pill) next to status badge.
- Job detail: Colored type badge replacing plain text, `TypeMetadataSection` component for insurance/warranty metadata display.
- Dashboard: Color accent bar on job cards (left edge colored by type: blue/amber/purple).
- Schedule: Color accent bar on scheduled job cards by type.
- `npm run build` passes (0 errors).

**Summary: Job Type System fully deployed across all 5 apps (Flutter + 4 web portals). DB columns already existed (job_type, type_metadata). No migration needed. 3 types: standard, insurance_claim, warranty_dispatch. Color coding: blue/amber/purple. All builds clean.**

---

### Session 61 (Feb 7) — Phase C2: QA Phase 2 — Deep Security Audit + Hardening

**Deep Supabase Query Audit (75 findings across all portals):**
- 11 CRITICAL: Missing company_id filtering — mitigated by RLS (defense-in-depth only)
- 20 HIGH: Client portal IDOR, missing error handling, race conditions
- 28 MEDIUM: Middleware role checks, type safety gaps
- 16 LOW: Minor issues

**Security Fixes Applied:**
- **RBAC Middleware (all 3 portals):** web-portal (owner/admin/office_manager/cpa/super_admin), team-portal (owner/admin/office_manager/technician/super_admin), client-portal (client_portal_users + super_admin fallback). Role verified from `users` table on every request.
- **Client Portal IDOR fix:** All 4 hooks (use-projects, use-invoices, use-bids, use-change-orders) now filter by `customer_id` for single-record fetches. Mutations verify ownership before executing.
- **Stale Closure Protection:** 4 web-portal hooks (useCustomer, useJob, useInvoice, useBid) + team-portal useJob — added `let ignore = false` pattern with cleanup.
- **Auth Hardening:** web-portal `auth.ts` changed `getSession()` → `getUser()` (server-verified).
- **Error Handling:** 7 team-portal hooks now have error state, try/catch/finally, error surfacing.

**Seed Data Expanded:**
- client_portal_users: 1 (linked client@test.com → Margaret Sullivan)
- leads: 5 (Tom Henderson, Lisa Martinez, Northside Medical, Kevin Walsh, Harbor Point HOA)
- notifications: 5 (for admin user)
- support_tickets: 3 (TKT-20260207-001/002/003)

**Verification:** All 4 portals `npm run build` pass (0 errors). 104 total routes.

---

### Session 60 (Feb 7) — Phase C2: QA with Real Data — Schema Audit + Auth Fixes

**C2 QA — Schema Audit (21 mismatches found and fixed):**
- Ran automated audit: every Supabase `.select()/.insert()/.update()` call vs actual DB schema
- Team Portal (12 fixes): `assigned_to` → `assigned_user_ids`, `type` → `job_type`, `order_number` → `change_order_number`, `total_amount` → `total`, `created_by_user_id` → `author_user_id`/`added_by_user_id`, `completed_by` → `completed_by_user_id`, `assigned_to` → `assigned_to_user_id`, removed invalid `deleted_at` filters
- Client Portal (8 fixes): `order_number` → `change_order_number`, `total_amount` → `total` (bids + invoices), `expires_at` → `valid_until`, `description` → `scope_of_work`, removed `completion_percentage` + `company_name` refs, removed invalid `deleted_at` filter
- Ops Portal (3 fixes): `'open'` → `'new'` for ticket status, `entity_type/entity_id` → `table_name/record_id` in audit log
- Web CRM (2 fixes): `ui_mode` moved from non-existent column to `settings` JSONB, `permission-gate.tsx` now reads from `settings`

**Auth Fixes:**
- Fixed `createClient` → `createBrowserClient` (ops-portal + client-portal) — tokens stored in cookies for middleware SSR auth
- Fixed ops portal hydration error (ThemeProvider rendered nested `<html><body>` tags)
- Fixed ops portal redirect loop (unauthorized users signed out instead of infinite loop)
- Updated JWT `app_metadata` for all 3 test auth users (`company_id` + `role`)
- Added password login + show/hide toggle to client portal

**Database:**
- Created + deployed `client_portal_users` table (migration 20260207000010) — links auth users to customers for client portal
- Created + deployed `super_admin`/`cpa` role migration (20260207000009)
- 29 tables total (was 28)
- 3 test auth users created: admin@zafto.app (super_admin), tech@zafto.app (technician), client@test.com (client)
- 1 test company: Tereda Electrical

**DevEx:**
- Created `ZAFTO Dev.bat` on Desktop — menu launcher for all 4 portals (hidden background processes, logs at .dev-logs/)

**Verification:** All 4 portals `npm run build` pass (0 errors). 10 migration files synced. 29 tables deployed.

---

### Session 59 (Feb 7) — Phase C3: Ops Portal Phase 1 COMPLETE + C5: Incident Response COMPLETE

**Sprint C3a — Ops Portal Scaffold + Database (DONE):**
- Created `apps/Trades/ops-portal/` — Next.js 15, React 19, TypeScript, Tailwind CSS
- Deep navy/teal theme (`--accent: #0d9488`), CSS variable theming, skeleton-shimmer loading
- Auth: Supabase auth with `super_admin` role gate. AuthProvider + middleware redirect.
- Components: sidebar.tsx (6 nav sections), logo.tsx, theme-provider.tsx, Card/Badge/Button/Input UI
- SQL migration `20260207000008_c3_ops_portal_tables.sql` — DEPLOYED to dev
  - 6 new tables: support_tickets, support_messages, knowledge_base, announcements, ops_audit_log, service_credentials
  - All RLS-locked to `super_admin` role
  - ops_audit_log is INSERT-only (immutable audit trail)
  - generate_ticket_number() function: auto-incrementing TKT-YYYYMMDD-NNN format
  - 28 tables total now deployed (was 22)

**Sprint C3b — Dashboard Pages (DONE, 16 pages + login):**
- Command Center (`/dashboard`) — Real Supabase queries for companies/users/tickets counts. Audit log feed.
- Companies (`/dashboard/companies`) — List with search, status badges
- Company Detail (`/dashboard/companies/[id]`) — Company info + users + jobs count
- Users (`/dashboard/users`) — List with role filter badges
- User Detail (`/dashboard/users/[id]`) — User info + audit activity
- Tickets (`/dashboard/tickets`) — Queue with status/priority filters
- Ticket Detail (`/dashboard/tickets/[id]`) — Message thread + reply form (inserts to support_messages)
- Knowledge Base (`/dashboard/knowledge-base`) — Article grid with category filter
- KB Editor (`/dashboard/knowledge-base/[id]`) — Upsert with auto-slug generation
- Revenue (`/dashboard/revenue`) — Placeholder with "Connect Stripe" messaging (zeros, not fake data)
- Subscriptions (`/dashboard/subscriptions`) — Placeholder
- Churn (`/dashboard/churn`) — Churn analysis placeholder
- System Status (`/dashboard/system-status`) — 10 service health cards
- Errors (`/dashboard/errors`) — Sentry error dashboard placeholder
- Directory (`/dashboard/directory`) — Service credentials + static fallback
- Login (`/`) — Email/password with Suspense boundary for useSearchParams

**Sprint C5 — Incident Response Plan (DONE):**
- Created `08_INCIDENT_RESPONSE.md` (291 lines, 8 sections)
- Severity levels (SEV-1 through SEV-4 with response times)
- Data breach response procedure (7 steps)
- Key rotation procedures for 9 services (Supabase, Stripe, Sentry, Anthropic, etc.)
- Rollback procedures (DB, web apps, Flutter)
- Communication templates (internal + external)
- Contact tree, post-incident review template, emergency quick reference

**Files created (~35):**
- Ops Portal scaffold: package.json, next.config.js, tsconfig.json, tailwind.config.ts, postcss.config.js, .env.local, .env.example, .gitignore
- Lib: supabase.ts, supabase-server.ts, auth.ts, sentry.ts, utils.ts
- Components: auth-provider.tsx, theme-provider.tsx, sidebar.tsx, logo.tsx, ui/button.tsx, ui/card.tsx, ui/badge.tsx, ui/input.tsx
- Infrastructure: middleware.ts, app/layout.tsx, app/globals.css
- 16 dashboard page files + login page
- SQL migration: 20260207000008_c3_ops_portal_tables.sql
- Incident response: 08_INCIDENT_RESPONSE.md

**Verification:** `npm run build` passes (17 routes, 0 errors). 6 new tables deployed to dev Supabase (28 total). All 8 migration files synced.

---

### Session 58 (Feb 7) — Phase C1: DevOps — Sentry + CI/CD + Tests COMPLETE

**Sprint C1a — Sentry Integration (DONE):**
- Flutter: `sentry_flutter: ^8.12.0` added. `SentryFlutter.init()` wrapping main.dart appRunner. `sentry_service.dart` static helper (configureScope, captureException, addBreadcrumb). Auth wired (configureScope on login/logout).
- Web CRM: `@sentry/nextjs` installed. `sentry.client/server/edge.config.ts` + `global-error.tsx` + `src/lib/sentry.ts`. `next.config.js` wrapped with `withSentryConfig()`. Auth-provider wired (setSentryUser/clearSentryUser). Build passes (39 pages).
- Team Portal: Newer instrumentation pattern (`instrumentation.ts` + `instrumentation-client.ts`). `global-error.tsx` + `src/lib/sentry.ts`. Auth wired. Build passes (23 routes).
- Client Portal: Same pattern as Web CRM (`sentry.*.config.ts`). `global-error.tsx` + `src/lib/sentry.ts`. Auth wired. Build passes (22 routes).
- All 4 apps: DSN via env var (empty in dev = graceful no-op via `beforeSend` guard).

**Sprint C1b — CI/CD Pipeline (DONE):**
- `.github/workflows/flutter-ci.yml` — PR/push to main, path-filtered (apps/Trades/lib/**, test/**). `flutter analyze`, `flutter test --coverage`, `dart format --set-exit-if-changed`.
- `.github/workflows/web-crm-ci.yml` — Path-filtered (web-portal/**). `npm ci`, `tsc --noEmit`, `npm run build` with placeholder env vars.
- `.github/workflows/portals-ci.yml` — 2 parallel jobs (team-portal + client-portal). Same pattern as web-crm.
- `.github/workflows/deploy-staging.yml` — All 3 web apps. `if: false` (disabled until deployment targets configured). Uses GitHub secrets for staging env vars.
- `.github/dependabot.yml` — Expanded to 4 ecosystems (pub + 3 npm).

**Sprint C1c — Automated Test Suite (DONE):**
- `test/models/customer_test.dart` — 39 tests: fromJson (snake_case + camelCase + minimal), toInsertJson, toUpdateJson, copyWith, computed properties (displayName, fullAddress, initials, typeLabel, hasAddress, hasContactInfo, hasBalance), CustomerType enum.
- `test/models/job_test.dart` — 42 tests: fromJson (all fields, legacy mappings, status/type/priority fallbacks), toInsertJson (dbValue, excluded fields), copyWith, computed properties (displayTitle, statusLabel, isActive, canStart, canComplete, isEditable, fullAddress, isAssigned), JobType.dbValue, JobStatus enum, JobPriority.
- `test/models/invoice_test.dart` — 46 tests: InvoiceLineItem (fromJson, toJson, defaults, computed total, recalculate, copyWith), Invoice fromJson (JSONB line items, camelCase, null handling), toInsertJson, recalculate (tax, discount, empty items), computed properties (all 10 statuses, isPaid, isOverdue, isEditable, canSend, hasSigned, display helpers), InvoiceStatus enum, factory constructors (fromJob, create), copyWith.
- `test/models/notification_test.dart` — 27 tests: NotificationType (fromString, dbValue, roundtrip), AppNotification (fromJson, copyWith, timeAgo, isRecent, constructor defaults).
- **Total: 154 tests, 0 failures.**

**Files created (15+):**
- Flutter: `lib/core/sentry_service.dart`, `test/models/customer_test.dart`, `test/models/job_test.dart`, `test/models/invoice_test.dart`, `test/models/notification_test.dart`
- Web CRM: `sentry.client.config.ts`, `sentry.server.config.ts`, `sentry.edge.config.ts`, `src/app/global-error.tsx`, `src/lib/sentry.ts`
- Team Portal: `src/instrumentation.ts`, `src/instrumentation-client.ts`, `src/app/global-error.tsx`, `src/lib/sentry.ts`
- Client Portal: `sentry.client.config.ts`, `sentry.server.config.ts`, `sentry.edge.config.ts`, `src/app/global-error.tsx`, `src/lib/sentry.ts`
- CI/CD: `.github/workflows/flutter-ci.yml`, `web-crm-ci.yml`, `portals-ci.yml`, `deploy-staging.yml`

**Files modified (8+):**
- `apps/Trades/pubspec.yaml` — Added sentry_flutter
- `apps/Trades/lib/main.dart` — SentryFlutter.init() wrapping
- `apps/Trades/lib/services/auth_service.dart` — SentryService.configureScope on login/logout
- `web-portal/next.config.js` — withSentryConfig()
- `web-portal/src/components/auth-provider.tsx` — setSentryUser/clearSentryUser
- `team-portal/next.config.js` — withSentryConfig()
- `team-portal/src/components/auth-provider.tsx` — setSentryUser/clearSentryUser
- `client-portal/next.config.ts` — withSentryConfig()
- `client-portal/src/components/auth-provider.tsx` — setSentryUser/clearSentryUser
- `.github/dependabot.yml` — Added team-portal entry

**Verification:** Flutter: sentry added to pubspec (resolved 8.14.2). Web CRM: `npm run build` passes (39 pages). Team Portal: `npm run build` passes (23 routes). Client Portal: `npm run build` passes (22 routes). Tests: 154 passed, 0 failures.

---

### Session 57 (Feb 6) — Sprint B7: Polish — Registry + Notifications + State Widgets COMPLETE

**Screen registry expanded (B7a), notifications system built (B7b), reusable state widgets created (B7c).**

**Sprint B7a — Screen Registry + Command Palette (DONE):**
- Added 3 new CommandTypes: `fieldTool`, `bid`, `timeClock`
- Registered 21 new commands: 18 field tools + bids_hub + time_clock + calendar + field_tools_hub + new_bid + notifications
- Total commands: ~76 (was 53)
- New "Field Tools" filter chip in command palette
- All 22 new navigation routes wired in `_navigateToCommand()` switch
- Updated section headers, type colors, suggested commands

**Sprint B7b — Notifications (DONE):**
- SQL migration `20260206000007_b7b_notifications_table.sql` — DEPLOYED to dev (22 tables total)
- `lib/models/notification.dart` — AppNotification model, NotificationType enum (11 types with dbValue), timeAgo getter, copyWith, fromJson
- `lib/repositories/notification_repository.dart` — CRUD + real-time subscription (Supabase channel with PostgresChangeFilter)
- `lib/services/notification_service.dart` — notificationRepositoryProvider, notificationServiceProvider, userNotificationsProvider (StateNotifier with real-time INSERT), unreadNotificationCountProvider. AuthState import hidden from supabase_flutter to avoid collision.
- `lib/screens/notifications/notifications_screen.dart` — Full notification center: type icons + colors per notification type, unread dot, "Mark all read" button, ZaftoLoadingState + ZaftoEmptyState + ErrorStateWidget for all states

**Sprint B7c — Loading/Error/Empty State Widgets (DONE):**
- `lib/widgets/error_widgets.dart` — Added 2 new reusable widgets:
  - `ZaftoLoadingState` — ConsumerWidget with themed spinner + optional message. Replaces scattered `Center(child: CircularProgressIndicator())`
  - `ZaftoEmptyState` — ConsumerWidget with icon circle + title + subtitle + optional action button. Matches existing patterns from materials_tracker, jobs_hub, etc.
- Both integrate with `zaftoColorsProvider` for proper theming
- Existing `ErrorStateWidget`, `OfflineBanner`, `RetryButton`, `showErrorSnackbar`, `showSuccessSnackbar` unchanged

**Files created (5):**
- `supabase/migrations/20260206000007_b7b_notifications_table.sql`
- `lib/models/notification.dart`
- `lib/repositories/notification_repository.dart`
- `lib/services/notification_service.dart`
- `lib/screens/notifications/notifications_screen.dart`

**Files modified (3):**
- `lib/services/command_registry.dart` — +22 commands, 3 new CommandTypes
- `lib/widgets/command_palette.dart` — +19 imports, +22 navigation cases, new filter chip
- `lib/widgets/error_widgets.dart` — +ZaftoLoadingState, +ZaftoEmptyState

**Verification:** `flutter analyze` — 0 errors on all B7 files. Migration deployed.

---

### Session 56 (Feb 6) — Sprint B6: Client Portal Wiring COMPLETE

**Client Portal (client.zafto.cloud) fully wired to Supabase. Magic link auth. 6 pages wired to real data. 5 hooks + mappers. `npm run build` passes (22 routes, 0 errors).**

**Infrastructure created:**
- `client-portal/.env.local` — Real Supabase dev keys (onidzgatvndkhtiubbcw)
- `client-portal/src/lib/supabase.ts` — Browser client (singleton)
- `client-portal/src/lib/auth.ts` — Magic link auth (signInWithOtp, signOut)
- `client-portal/src/middleware.ts` — Protects (portal) routes, allows / and /auth/*
- `client-portal/src/app/auth/callback/route.ts` — Exchange auth code for session
- `client-portal/src/components/auth-provider.tsx` — AuthProvider with client_portal_users lookup, fallback to auth metadata

**5 hook files + mappers:**
- `lib/hooks/mappers.ts` — ProjectData, InvoiceData, BidData, ChangeOrderData, MessageData interfaces. Status maps (JOB_STATUS_MAP, INVOICE_STATUS_MAP). mapProject, mapInvoice, mapBid, mapChangeOrder. formatCurrency, formatDate, formatRelative helpers.
- `lib/hooks/use-projects.ts` — useProjects (list + real-time), useProject(id)
- `lib/hooks/use-invoices.ts` — useInvoices (list + real-time + outstanding + totalOwed), useInvoice(id)
- `lib/hooks/use-bids.ts` — useBids (list + real-time), acceptBid, rejectBid
- `lib/hooks/use-change-orders.ts` — useChangeOrders (via customer's jobs), approveOrder, rejectOrder

**6 pages wired to real Supabase data:**
- `home/page.tsx` — Dynamic action cards generated from overdue invoices (high), due invoices (high), pending bids (high), pending change orders (medium), active projects (low). Time-of-day greeting with auth profile name. Loading skeleton. Empty state ("You're all caught up!"). Property section + referral banner kept as placeholder.
- `projects/page.tsx` — useProjects() replaces 5 hardcoded mockProjects. Filter chips. Loading skeleton. Empty state.
- `projects/[id]/page.tsx` — useProject(id) + useChangeOrders() + useInvoices() for cost summary. Timeline → empty state placeholder. Documents → empty state. Crew → empty state.
- `payments/page.tsx` — useInvoices() replaces 5 hardcoded mockInvoices. Outstanding total from hook. Loading skeleton. Empty state.
- `payments/[id]/page.tsx` — useInvoice(id) with line items from DB. Payment card selection kept as mock (Stripe not wired). Loading skeleton.
- `settings/page.tsx` — useAuth() for profile name/email/initials. signOut wired. Magic link auth note in security section. Notification toggles + appearance kept as local state.

**Login page rewritten:**
- `page.tsx` (root) — Magic link auth via signInWithOtp. "Send Sign-In Link" button. Confirmation state showing "Check your email". No password field.

**Portal layout updated:**
- `(portal)/layout.tsx` — Wrapped with AuthProvider. Avatar initials from auth profile. Split into PortalShell + PortalLayout.

**Remaining pages (13, no backing tables — future-phase placeholders):**
- messages, documents, request, referrals, review, my-home, my-home/equipment, equipment/[id], projects/[id]/tracker, projects/[id]/estimate, projects/[id]/agreement, payments/history, payments/methods

**Verification:** `npm run build` — 22 routes, 0 errors. Next.js 16.1.6, Tailwind v4.

**B6 COMPLETE. Client Portal fully wired to Supabase.**

### Session 56 (Feb 6) — Phase E Docs + battery_plus Fix

**Phase E (AI Layer) fully documented in 07_SPRINT_SPECS.md:**
- **E1: Universal AI Architecture** — z_threads + z_artifacts tables (full SQL), Claude API Edge Function proxy (SSE streaming), 14 tool definitions (Supabase query specs), response parser + artifact detection protocol, system prompt template, rate limiting design, web CRM hooks (use-z-threads, use-z-artifacts), provider update plan.
- **E2: Dashboard → Claude API Wiring** — Replace mock engine with streaming SSE client, slash command → tool routing table, artifact lifecycle (generate → edit → approve → convert to real bid/invoice), context-aware system prompts per page, error handling matrix, 15-item verification checklist.
- **E3: Employee Portal AI + Mobile AI** — Outlined (troubleshooting center, photo diagnosis, code lookup, voice transcription, receipt OCR).
- **E4: Growth Advisor** — Outlined (revenue intelligence, bid brain, equipment memory, revenue autopilot).

**battery_plus fixed:**
- Added `battery_plus: ^6.0.3` to pubspec.yaml (resolved 6.2.3)
- `flutter analyze lib/services/location_tracking_service.dart` — 0 errors (was 4). Only 3 info/warnings remain (dangling doc comment, unused `_userId`, prefer_final_locals).

---

### Session 55 (Feb 6) — Sprint B5: Employee Field Portal (team.zafto.app) COMPLETE

**Entire Employee Field Portal scaffolded from scratch. 21 dashboard pages + login. 8 Supabase hooks. PWA manifest. Field-optimized UI. `npm run build` passes (23 routes, 0 errors).**

**Infrastructure created:**
- `team-portal/package.json` — Next.js 15, React 19, TypeScript, Tailwind CSS
- `team-portal/next.config.js`, `tsconfig.json`, `tailwind.config.ts`, `postcss.config.js`
- `team-portal/.env.local` — Real Supabase dev keys (onidzgatvndkhtiubbcw)
- `team-portal/src/lib/supabase.ts` — Browser client (singleton)
- `team-portal/src/lib/supabase-server.ts` — Server client with cookies
- `team-portal/src/lib/auth.ts` — signIn, signOut, onAuthChange
- `team-portal/src/lib/utils.ts` — cn, formatCurrency, formatDate, formatTime, formatRelativeTime, getInitials, getStatusColor, getStatusLabel
- `team-portal/src/middleware.ts` — Protects /dashboard/* routes
- `team-portal/src/app/globals.css` — CSS variables (light/dark), skeleton, fade-in animations
- `team-portal/public/manifest.json` — PWA manifest for "ZAFTO Team Portal"

**UI components (6):**
- `theme-provider.tsx` — Dark/light toggle with localStorage
- `auth-provider.tsx` — Supabase auth context with user profile from users table
- `button.tsx` — 4 variants (primary/secondary/ghost/danger), loading state
- `card.tsx` — Card/CardHeader/CardTitle/CardContent
- `badge.tsx` — Badge + StatusBadge with color system
- `input.tsx` — Form input with label and error

**Layout components:**
- `logo.tsx` — "ZAFTO.team" wordmark
- `sidebar.tsx` — Field-optimized nav (big touch targets, sections: OVERVIEW, CLOCK & TOOLS, DOCUMENTATION, BUSINESS), mobile overlay, sign out, theme toggle
- `src/app/layout.tsx` — Root layout with ThemeProvider
- `src/app/page.tsx` — Login page with Supabase signIn
- `src/app/dashboard/layout.tsx` — AuthProvider + Sidebar + responsive main content

**8 Supabase hooks:**
- `mappers.ts` — JobData, TimeEntryData, MaterialData, DailyLogData, PunchListItemData, ChangeOrderData, BidData, NotificationData + mapper functions
- `use-jobs.ts` — useMyJobs (assigned jobs), useJob(id)
- `use-time-clock.ts` — useTimeClock with clockIn/clockOut, todayHours
- `use-materials.ts` — useMaterials with addMaterial, totalCost
- `use-daily-log.ts` — useDailyLogs with saveLog (upsert), todayLog
- `use-punch-list.ts` — usePunchList with addItem, toggleComplete, openCount/completedCount
- `use-change-orders.ts` — useChangeOrders with createOrder (auto CO-001), submitForApproval
- `use-bids.ts` — useBids with createBid (auto BID-YYYYMMDD-NNN)

**21 dashboard pages:**
- `/dashboard` — Overview with stats cards (active jobs, today hours, open punch items, pending COs), recent jobs, quick actions
- `/dashboard/jobs` — Job list with status filters + search
- `/dashboard/jobs/[id]` — Job detail (info, team, materials, punch list, change orders, daily logs)
- `/dashboard/time-clock` — Clock in/out with job selector, live timer, today's entries (Suspense wrapped)
- `/dashboard/schedule` — 7-day lookahead with job cards grouped by day + unscheduled section
- `/dashboard/field-tools` — Hub page with 5 tool cards (photos, voice notes, signatures, receipts, level)
- `/dashboard/field-tools/photos` — Camera capture placeholder (Phase E: Supabase Storage upload)
- `/dashboard/field-tools/voice-notes` — Recording placeholder (Phase E: MediaRecorder + transcription)
- `/dashboard/field-tools/signatures` — Signature canvas placeholder (future sprint)
- `/dashboard/field-tools/receipts` — Receipt capture placeholder (Phase E: OCR Edge Function)
- `/dashboard/field-tools/level` — Level & plumb placeholder
- `/dashboard/materials` — Materials tracker with add form, category, cost summary
- `/dashboard/daily-log` — Daily log form with today/history tabs
- `/dashboard/punch-list` — Punch list with add/toggle/filter, progress counts
- `/dashboard/change-orders` — Change orders with create form, line items, status workflow
- `/dashboard/bids` — Bid list with status badges
- `/dashboard/bids/new` — Create bid form
- `/dashboard/notifications` — Notification center placeholder
- `/dashboard/settings` — Profile, appearance (dark mode), notifications toggles, about
- `/dashboard/troubleshoot` — AI Troubleshooting Center placeholder (Phase E: Z Intelligence)

**Type errors fixed:**
- `use-daily-log.ts:20` — Added explicit `(l: DailyLogData)` type annotation
- `use-time-clock.ts:28` — Added explicit `(e: TimeEntryData)` type annotation
- `time-clock/page.tsx` — Wrapped `useSearchParams()` in Suspense boundary (Next.js 15 requirement)
- `settings/page.tsx` — Removed unused `Phone` import

**Verification:** `npm run build` — 23 routes (21 dashboard + login + 404), 0 errors. npm install: 373 packages, 0 vulnerabilities.

**B5 COMPLETE. Employee Field Portal fully scaffolded with real Supabase hooks.**

---

### Session 54 (Feb 6) — Sprint B4e: Dashboard + Artifact System UI Shell COMPLETE

**Persistent AI console that lives across ALL 39 dashboard pages. Never unmounts, never loses state. Split-screen artifact system for bids, invoices, reports. `npm run build` passes (39 pages, 0 errors).**

**New files created (22 total — 17 components + 5 lib files):**

**Intelligence layer (5 files in `src/lib/z-intelligence/`):**
- `types.ts` — ZConsoleState ('collapsed'|'open'|'artifact'), ZMessage, ZArtifact, ZArtifactVersion, ZThread, ZToolCall, ZContextChip, ZQuickAction, ZSlashCommand, ZConsoleContextType
- `slash-commands.ts` — 6 slash commands: /bid, /invoice, /report, /analyze, /schedule, /customer
- `context-map.ts` — `getPageContext(pathname)` maps 15 routes + dynamic fallbacks → context label + quick actions
- `mock-responses.ts` — Simulated multi-step AI responses with delays, tool calls, artifact generation. Multi-turn bid flow (2 steps). Artifact edit detection.
- `artifact-templates.ts` — 3 full mock artifacts: bid (3-tier Good/Better/Best), invoice (line items + tax), report (revenue tables)

**Components (17 files in `src/components/z-console/`):**
- `index.ts` — Barrel exports: ZConsoleProvider, ZConsole, useZConsole
- `z-console-provider.tsx` — React context + useReducer. 12 action types. localStorage persistence (threads + currentThreadId, max 50). `usePathname()` context tracking. Cmd+J / Ctrl+J keyboard shortcut. `zConsoleToggle` window event for command palette. Mock response orchestration.
- `z-console.tsx` — Root shell: renders ZPulse (collapsed) / ZChatPanel (open) / ZArtifactSplit (artifact) per state
- `z-pulse.tsx` — Fixed bottom-6 right-6, 56px emerald circle, Sparkles icon, `.z-pulse-glow` animation, unread dot
- `z-chat-panel.tsx` — Fixed right-0, 420px wide, `.z-glass` frosted glass. Header (Sparkles + "Z Intelligence" + context chip). Thread history toggle. ZChatMessages + ZQuickActions + ZChatInput
- `z-chat-messages.tsx` — Scrollable message list with auto-scroll-to-bottom. Empty state with Z branding. Appends ZThinkingIndicator when thinking
- `z-chat-message.tsx` — User (right, emerald bg) / Assistant (left, secondary bg). Tool call badges (running spinner, complete check, error alert). Relative timestamps. ZMarkdown for assistant content
- `z-chat-input.tsx` — Auto-growing textarea (1-5 rows). Enter to send. `/` triggers slash command menu. `compact` prop for artifact split mode
- `z-artifact-split.tsx` — Fixed right-0, width `min(60vw, 800px)`. Top 70%: ZArtifactViewer. Bottom 30%: compact ZChatMessages + ZChatInput
- `z-artifact-viewer.tsx` — Always-white `.z-artifact-pane`. TypeBadge (bid/invoice/report/etc). ZMarkdown content rendering. `.z-artifact-reveal` animation during generation
- `z-artifact-toolbar.tsx` — Back button + title + status badge + version tabs. Save Draft (secondary) + Reject (ghost red) + Approve & Send (emerald primary)
- `z-thinking-indicator.tsx` — 3 emerald pulsing dots with staggered animation
- `z-context-chip.tsx` — "On: {label}" pill with MapPin icon
- `z-quick-actions.tsx` — Horizontal scrollable suggestion chips with Lucide icons
- `z-slash-command-menu.tsx` — Autocomplete dropdown above input. Arrow key navigation, Enter to select, Escape to dismiss
- `z-thread-history.tsx` — Past conversation list with title, message count, relative time. "New conversation" button
- `z-markdown.tsx` — Custom GFM markdown → React renderer (no external deps). Bold, italic, headers, lists, tables, code blocks, links, hr

**Files modified (4):**
- `src/app/dashboard/layout.tsx` — Wrapped with ZConsoleProvider inside PermissionProvider. Extracted DashboardShell inner component that reads `useZConsole()` for dynamic `marginRight` (page compresses when artifact is open). Added `<ZConsole />` as sibling to content wrapper.
- `src/app/dashboard/z/page.tsx` — Replaced standalone chat page → auto-opens persistent console on mount. Shows "Z is always available from any page" centered message.
- `src/app/dashboard/page.tsx` — Removed ZAIChat/ZAITrigger imports and floating widget. Removed Ask Z card. Removed showZChat/zChatMinimized state.
- `src/components/command-palette.tsx` — Z action changed from `router.push('/dashboard/z')` → `window.dispatchEvent(new CustomEvent('zConsoleToggle'))`.

**CSS (added in previous session, used now):**
- `.z-pulse-glow` — 2.5s emerald glow animation
- `.z-glass` / `.dark .z-glass` — frosted glass backdrop-filter
- `.z-panel-enter` / `.z-panel-active` — slide-in from right
- `.z-artifact-pane` / `.dark .z-artifact-pane` — always white background
- `.z-artifact-reveal` — content reveal animation
- `.z-thinking-dot` — 1.4s pulsing with staggered delays
- `.z-message-in` — message fade-in
- `.z-prose` — full markdown styling (both normal and artifact-pane variants)

**Three Dashboard states:**
| State | Desktop | How |
|-------|---------|-----|
| Pulse | 56px floating Z button, bottom-right, emerald glow | Click or Cmd+J to open |
| Chat Panel | 420px right-side slide-out, frosted glass | Type messages, / for commands |
| Artifact Split | Screen splits: page compresses left, artifact takes right min(60vw, 800px) | Auto-triggers when Z generates a document |

**Mock demo flow:** Z pulse → click → chat panel slides in → context chip shows page → quick actions → type `/bid` → slash commands → Z thinks → tool calls appear → Z generates bid → screen SPLITS → full 3-tier bid document → "change Better to $6,200" → version 2 created → Approve & Send → back to chat → navigate pages → console persists → Cmd+J toggles.

**Verification:** `npm run build` — 39 pages compiled, ZERO errors.

**B4e COMPLETE (UI Shell). Phase E will wire Claude API to replace mock responses.**

---

### Session 53 (Feb 6) — Sprint B4d: Web CRM UI Polish — Supabase-Level Professionalism COMPLETE

**Crash recovery from S52 mid-B4d. Rebuilt and completed all remaining polish. `npm run build` passes (39 pages, 0 errors).**

**Pre-crash work (recovered intact on disk — sidebar, charts, stats cards, globals.css):**
- `web-portal/src/components/sidebar.tsx` — NEW (366 lines). Extracted from layout. Collapsible icon rail (48px) → expanded (220px) on hover. Pin toggle with localStorage persistence. Mobile overlay with backdrop. Section headers (OPERATIONS, SCHEDULING, CUSTOMERS, RESOURCES, OFFICE, Z INTELLIGENCE). Active item left-border accent (2px). PanelLeftClose/PanelLeftOpen icons.
- `web-portal/src/app/dashboard/layout.tsx` — Rewritten (170 lines). Imports Sidebar. Dynamic padding `pl-[220px]`/`pl-12` based on pin state. Sticky top bar with backdrop blur. Search trigger (Cmd+K). Pro mode toggle.
- `web-portal/src/components/ui/charts.tsx` — Smooth cubic bezier curves (`smoothPath()` tension=0.3). SVG gradient fills (15%→0% opacity). Donut gaps with `strokeLinecap="round"`. Subtler grid (0.06 opacity). Empty state ring. Bar transitions.
- `web-portal/src/components/ui/stats-card.tsx` — `card-hover` class, padding p-5, title 13px, value 26px leading-tight, icon plain `text-muted` (no colored badge).

**Post-crash work (this session):**

**Visual restraint pass (dashboard):**
- "Ask Z" card: Toned down from full gradient bg + white text → subtle card with left accent border + accent icon badge. Clean and restrained.
- Activity icon colors: Removed purple (viewed → blue-400). Now only 2-3 accent colors visible: emerald (success), blue (info), red (alerts).
- Stats grid gap increased: `gap-4` → `gap-5`.
- Right column spacing adjusted.

**Typography and spacing hierarchy (14 pages):**
- Top-level container: `space-y-6` → `space-y-8` (32px) on all core pages: dashboard, customers, jobs, invoices, bids, leads, change-orders, inspections, calendar, team, time-clock, reports, books, settings.
- Page subtitles: `text-muted` → `text-[13px] text-muted` on key pages.
- CardTitle: `text-lg` (18px) → `text-[15px]` (15px) globally via card.tsx. Tighter, more Supabase-like.
- CardHeader padding: `py-4` → `py-3.5`. Slightly tighter.
- Main content grid: `gap-6` → `gap-8` on dashboard.
- Page content fade-in: `animate-fade-in` added to all 14 core page containers.

**Skeleton loading states (7 pages):**
- Dashboard, Customers, Jobs, Invoices, Change Orders, Inspections, Reports — all spinners replaced with contextual skeleton shimmer showing layout shape (header skeleton + stats grid skeleton + table rows skeleton).

**Micro-interactions:**
- `animate-fade-in`: Subtle 0.15s ease-out with 4px translateY for page content.
- `animate-stagger`: Staggered children animation (50ms delay each) on dashboard stats grid.
- `animate-draw-line`: Chart line draw-in animation (0.8s ease-out) on area chart SVG paths.
- `animate-slide-up`: 0.2s ease-out slide from 10px below.

**Dark mode depth layers (CSS variables):**
- Layer 1 (page): `#0a0a0a` (--bg) ✓
- Layer 2 (cards): `#141414` (--surface) ✓
- Layer 3 (elevated): `#1a1a1a` (--surface-hover) ✓
- Borders: `#262626` (--border) — subtle but visible ✓
- New utility: `bg-elevated` class for modal/dropdown backgrounds.
- New utility: `border-subtle` class for lighter borders.
- Card hover: translateY(-1px) + shadow-sm in both light/dark modes.

**globals.css additions:**
- `.sidebar-label` — opacity 150ms ease transition for sidebar labels
- `.card-hover` — translateY(-1px) + subtle shadow on hover, dark variant
- `.skeleton` — shimmer animation (gradient slide 1.5s infinite)
- `.animate-stagger` — staggered children (6 slots, 50ms each)
- `.animate-draw-line` — SVG line draw-in animation
- `bg-elevated`, `border-subtle` — new utility classes

**Verification:** `npm run build` — 39 pages compiled, ZERO errors.

**B4d COMPLETE. Next: B4e (Z Intelligence Chat) or B5 (Employee Field Portal).**

---

### Session 52 (Feb 6) — Sprint B4c Continued: 6 More Pages Wired, Leads Table Created, mock-data.ts Deleted

**Crash recovery from S51. 6 more pages wired. Leads table migration created. `mock-data.ts` deleted (zero imports remaining). 26 total pages wired. `npm run build` passes (39 pages, 0 errors).**

**New files created (3 hook files + 1 SQL migration):**
- `web-portal/src/lib/hooks/use-leads.ts` — useLeads() (list + real-time subscription from `leads` table). createLead (with company_id from JWT), updateLeadStage (auto-sets timestamps for contacted/won/lost), updateLead, deleteLead.
- `web-portal/src/lib/hooks/use-reports.ts` — useReports() (aggregates from invoices, jobs, users, job_materials). Returns monthlyRevenue (last 12 months), jobsByStatus, revenueByCategory (from job tags), team performance, invoiceStats (aging report), jobStats.
- `web-portal/src/lib/hooks/use-job-costs.ts` — useJobCosts() (active jobs + job_materials + change_orders). Risk assessment (on_track/at_risk/over_budget/critical). Portfolio stats. Burn rate projection. Alert generation.
- `supabase/migrations/20260206000006_b4c_leads_table.sql` — leads table with: name, email, phone, company_name, source (9 CHECK values), stage (6 stages: new→contacted→qualified→proposal→won/lost), value, address fields, follow-up dates, converted_to_job_id FK. RLS + audit + indexes.

**Files modified (mappers.ts expanded):**
- `web-portal/src/lib/hooks/mappers.ts` — Added LeadData interface (22 fields, stage enum, follow-up/won/lost dates, tags). Added mapLead mapper.

**Pages wired (6 pages):**
- `dashboard/leads/page.tsx` — useLeads(). Full pipeline management (6 stages). Create/edit/stage transitions. Pipeline visualization.
- `dashboard/reports/page.tsx` — useReports(). 4 report tabs (Revenue, Jobs, Team, Invoices). Loading spinner. Real data from aggregated queries.
- `dashboard/job-cost-radar/page.tsx` — useJobCosts(). Risk-based job cost tracking. Portfolio health stats. Materials/spend breakdown. Change order impact. Alert system.
- `dashboard/page.tsx` — useReports() for chart data (revenueData, jobsByStatusData, revenueByCategoryData). All 3 mock chart data arrays replaced with real aggregations.
- `dashboard/books/page.tsx` — useReports() for profit trend chart. Transactions/bankAccounts replaced with empty arrays (Ledger Phase F — no bank/transaction tables yet).
- `dashboard/z/page.tsx` — savedThreads replaced with empty array (AI Phase E — no threads table yet).

**Files deleted:**
- `web-portal/src/lib/mock-data.ts` — 820+ lines of mock data. Zero imports remaining. Dead code. DELETED.

**Key technical decisions:**
- Leads table: Dedicated `leads` table with full CRM pipeline (not shoehorned into jobs). Source tracking (9 sources), stage workflow (6 stages), follow-up scheduling, conversion tracking (converted_to_job_id FK to jobs).
- Reports hook: Aggregates from 4 tables in parallel (invoices, jobs, users, job_materials). Monthly revenue from paid invoices. Expenses from material costs. Revenue by category from first job tag.
- Job cost radar: Risk assessment formula based on budget burn rate vs completion %. Projected margin calculates from burn-rate extrapolation. Alerts auto-generated for overruns, burn rate gaps, change orders.
- Ledger/Z pages: Kept structurally intact but with empty data arrays. UI renders gracefully with no data. Will light up when Phase F (Ledger) and Phase E (AI) tables are created.

**Verification:** `npm run build` — 39 pages compiled, ZERO errors. `mock-data.ts` deleted with zero breakage.

**B4c COMPLETE. Equipment, inventory, documents mock data emptied (no backing tables — future phase).**

**Next action: B4d (UI Polish) or B5 (Employee Field Portal).**

**Remaining pages with inline mock data (~10 pages, all future-phase, no backing tables):**
- automations, bid-brain, communications, equipment-memory, permits, price-book, purchase-orders, service-agreements, vendors, warranties, z-voice, revenue-autopilot

---

### Session 51 (Feb 6) — Sprint B4c: Web CRM Remaining Pages — Change Orders, Inspections, Customers/New, Settings Wired

**4 more CRM pages wired to real Supabase data. New hooks for change orders + inspections. `npm run build` passes (39 pages, 0 errors).**

**New files created (2 hook files):**
- `web-portal/src/lib/hooks/use-change-orders.ts` — useChangeOrders() (list + real-time subscription from `change_orders` table with nested `jobs` join). createChangeOrder (auto CO number CO-YYYY-NNN), updateChangeOrderStatus.
- `web-portal/src/lib/hooks/use-inspections.ts` — useInspections() (list + real-time subscription from `compliance_records` WHERE record_type='inspection' with nested `jobs` join). createInspection (stores checklist/score/type in JSONB data field), updateInspectionStatus.

**Files modified (mappers.ts expanded):**
- `web-portal/src/lib/hooks/mappers.ts` — Added ChangeOrderData + ChangeOrderItem + InspectionData + InspectionChecklistItem types. Added mapChangeOrder (DB→TS with nested job join for jobName/customerName, line_items JSONB→items array). Added mapInspection (compliance_records→InspectionData, extracts checklist/score/type from JSONB data field).

**Pages wired (4 pages):**
- `dashboard/change-orders/page.tsx` — useChangeOrders(). Replaced all inline mock data. Status type updated to match DB (voided instead of completed). Removed fields not in DB (scheduledDaysImpact, originalJobTotal, newJobTotal, customerSignature). Loading spinner added.
- `dashboard/inspections/page.tsx` — useInspections(). Replaced all inline mock data. Type coercion for status/type config lookups (DB stores strings, not enums). Loading spinner added.
- `dashboard/customers/new/page.tsx` — useCustomers().createCustomer(). Replaced Firebase TODO with real Supabase insert. Saving state on submit button.
- `dashboard/settings/page.tsx` — TeamSettings section wired to useTeam() for real team member list. Other sections (profile, billing, notifications, appearance, security, integrations) remain with mock/localStorage data.

**Key technical decisions:**
- Change orders: DB has `change_orders` table with `amount` (single numeric), not separate originalJobTotal/newJobTotal. Simplified financial summary in detail modal.
- Inspections: DB uses `compliance_records` with `record_type='inspection'` and rich data in JSONB `data` field (checklist, score, type, assigned_to). Different from mobile Level & Plumb inspections (which store angles/calibration).
- Nested Supabase joins: `change_orders(*, jobs(title, customer_name))` and `compliance_records(*, jobs(title, customer_name, address, city, state))` for related job/customer data.

**Verification:** `npm run build` — 39 pages compiled, ZERO errors.

---

### Session 50 (Feb 6) — Sprint B4b: Web CRM 12 Core Operations Pages Wired to Supabase COMPLETE

**All 12 core CRM operations pages now read/write real Supabase data via custom React hooks. `npm run build` passes (39 pages, 0 errors).**

**New files created (7 hook files):**
- `web-portal/src/lib/hooks/mappers.ts` — Central DB→TS type mapping utility. Status maps (JOB_STATUS_FROM_DB, INVOICE_STATUS_FROM_DB, etc.), entity mappers (mapCustomer, mapJob, mapInvoice, mapBid, mapTeamMember, mapActivity), name split/join helpers. Handles snake_case→camelCase, single `name`→firstName/lastName, flat address→nested Address object.
- `web-portal/src/lib/hooks/use-customers.ts` — useCustomers() (list + real-time subscription), useCustomer(id), createCustomer, updateCustomer, deleteCustomer.
- `web-portal/src/lib/hooks/use-jobs.ts` — useJobs() (list + real-time), useJob(id), useSchedule() (derives ScheduledItem[] from jobs), useTeam() (fetches from users table), createJob, updateJob, updateJobStatus, deleteJob.
- `web-portal/src/lib/hooks/use-invoices.ts` — useInvoices() (list + real-time), useInvoice(id), createInvoice (auto invoice number INV-YYYY-NNNN), updateInvoice, recordPayment, sendInvoice, deleteInvoice.
- `web-portal/src/lib/hooks/use-bids.ts` — useBids() (list + real-time), useBid(id), createBid (auto bid number BID-YYYYMMDD-NNN), updateBid, sendBid, acceptBid, rejectBid, convertToJob, deleteBid.
- `web-portal/src/lib/hooks/use-stats.ts` — useStats() (parallel queries for job/bid/invoice counts + revenue), useActivity(limit) (from audit_log).

**Pages wired (12 core operations — mock-data imports replaced with hooks):**
- `dashboard/page.tsx` — 6 hook calls (useStats, useJobs, useInvoices, useBids, useSchedule, useTeam, useActivity). Chart data kept as mock intentionally.
- `dashboard/customers/page.tsx` — useCustomers() with loading spinner.
- `dashboard/customers/[id]/page.tsx` — useCustomer(id) + useBids + useJobs + useInvoices.
- `dashboard/customers/new/page.tsx` — Already Supabase-ready (no mock imports).
- `dashboard/jobs/page.tsx` — useJobs + useTeam + useStats. JobRow/JobCard take `team` prop.
- `dashboard/jobs/[id]/page.tsx` — useJob(id) + useTeam.
- `dashboard/jobs/new/page.tsx` — useCustomers + useTeam.
- `dashboard/invoices/page.tsx` — useInvoices + useStats with loading spinner.
- `dashboard/invoices/[id]/page.tsx` — useInvoice(id).
- `dashboard/invoices/new/page.tsx` — useCustomers + useJobs.
- `dashboard/bids/page.tsx` — useBids + useStats (removed entire Firestore subscription useEffect).
- `dashboard/bids/[id]/page.tsx` — useBid(id).
- `dashboard/bids/new/page.tsx` — useCustomers.

**Additional pages wired (scheduling + team — mock-data imports replaced):**
- `dashboard/calendar/page.tsx` — useSchedule + useTeam.
- `dashboard/time-clock/page.tsx` — useTeam (inline time entries stay mock — no time_entries web query yet).
- `dashboard/team/page.tsx` — useTeam + useJobs. Dispatch board + team grid.

**Pages intentionally keeping mock data (not B4b scope):**
- `books/page.tsx` — Ledger financial data (no table wired yet)
- `reports/page.tsx` — Chart aggregation data (complex queries deferred)
- `z/page.tsx` — AI threads (Phase E)
- `dashboard/page.tsx` — Chart data only (mockRevenueData, mockJobsByStatus, mockRevenueByCategory)

**Key technical decisions:**
- DB→TS mapping in `mappers.ts`: DB stores single `name`, TS expects `firstName`/`lastName` (splitName helper). DB uses snake_case statuses ('inProgress'), TS uses mixed ('in_progress'). Bidirectional status maps.
- Real-time: Supabase channels with `postgres_changes` for INSERT/UPDATE/DELETE on each table.
- Auth context: `user.app_metadata.company_id` from JWT for all mutations.
- Typed Supabase responses: Explicit type annotations on `.data` to prevent implicit `any` errors.

**Verification:** `npm run build` — 39 pages compiled, ZERO errors.

---

### Session 49 (Feb 6) — Sprint B4a: Web CRM Infrastructure — Firebase → Supabase COMPLETE

**Web CRM fully migrated from Firebase to Supabase. Auth, middleware, providers, permissions all rewritten. `npm run build` passes (39 pages, 0 errors).**

**New files created:**
- `web-portal/src/lib/supabase.ts` — Browser client (createBrowserClient + singleton getSupabase)
- `web-portal/src/lib/supabase-server.ts` — Server client with cookie handling for server components
- `web-portal/src/middleware.ts` — Protects /dashboard/* routes, refreshes tokens, redirects auth users

**Files rewritten:**
- `web-portal/src/lib/auth.ts` — Firebase Auth → Supabase Auth. signIn/signOut/onAuthChange. Proper error mapping.
- `web-portal/src/lib/firestore.ts` — Firebase Firestore → stub returning empty data. Pages still compile. Replace with Supabase queries in B4b.
- `web-portal/src/components/auth-provider.tsx` — Firebase listener → Supabase onAuthStateChange. Fetches user profile from `users` table.
- `web-portal/src/components/permission-gate.tsx` — Firebase doc listeners → Supabase queries. Role-based + tier-based + pro-mode gating. Reads from `companies` table.
- `web-portal/src/app/page.tsx` (login) — Firebase signIn → Supabase signIn with error handling.
- `web-portal/src/app/dashboard/layout.tsx` — Wrapped with AuthProvider + PermissionProvider. Uses Supabase auth.
- `web-portal/src/app/dashboard/page.tsx` — Updated for Supabase auth context.
- `web-portal/src/lib/mock-data.ts` — Added @ts-nocheck (temporary until B4b replaces with real data).

**Files deleted:**
- `web-portal/src/lib/firebase.ts` — Dead code, Firebase packages already removed.

**Bug fixes (pre-existing + crash recovery):**
- `revenue-autopilot/page.tsx` — Fixed broken JSX structure (missing right-column wrapper from crash)
- `bid-brain/page.tsx` — Fixed Badge variant="secondary" type error
- `bids/[id]/page.tsx` — Fixed depositRequired → depositAmount
- `service-agreements/page.tsx` — Fixed Lucide icon title prop → aria-label
- `badge.tsx` — Added "secondary" variant (used by 5+ pages)
- `button.tsx` — Added "default" variant alias (used by 11+ pages)

**Environment:**
- `.env.local` — Added NEXT_PUBLIC_SUPABASE_URL + NEXT_PUBLIC_SUPABASE_ANON_KEY (zafto-dev). Removed stale Firebase keys.

**Verification:** `npm run build` — 39 pages compiled, ZERO errors. Only warning: @next/swc version mismatch (cosmetic).

---

### Session 48 (Feb 6) — Sprint B3b: Punch List + Change Orders + Job Completion BUILT FROM SCRATCH

**3 entirely new field tools built from scratch with full Supabase persistence. ALL 5 missing operational tools now complete (B3a + B3b).**

**SQL migration created:**
- `supabase/migrations/20260206000005_b3b_punch_list_change_orders_tables.sql` — punch_list_items + change_orders tables. RLS with requesting_company_id(). Indexes on job_id + status. Audit triggers.

**New files created (8 foundation + 3 screens = 11 files):**
- `lib/models/punch_list_item.dart` — PunchListItem model. PunchListPriority enum (low/normal/high/urgent). PunchListStatus enum (open/in_progress/completed/skipped). isDone getter for completed+skipped.
- `lib/models/change_order.dart` — ChangeOrder model. ChangeOrderStatus enum (draft/pending_approval/approved/rejected/voided). ChangeOrderLineItem class (JSONB). computedAmount from line items. isResolved getter.
- `lib/repositories/punch_list_repository.dart` — CRUD for punch_list_items. completeItem (sets completed_at + completed_by). reopenItem. getProgress (total vs completed count). Hard delete.
- `lib/repositories/change_order_repository.dart` — CRUD for change_orders. getNextNumber (auto CO-001, CO-002). submitForApproval, approve, reject, voidOrder. getUnresolvedCount. getApprovedTotal.
- `lib/services/punch_list_service.dart` — Providers: punchListRepositoryProvider, punchListServiceProvider, jobPunchListProvider (StateNotifier with progressPercent/completedCount/openCount). Auth-enriched creates.
- `lib/services/change_order_service.dart` — Providers: changeOrderRepositoryProvider, changeOrderServiceProvider, jobChangeOrdersProvider (StateNotifier with approvedTotal/unresolvedCount). Auth-enriched creates with auto-numbering.
- `lib/screens/field_tools/punch_list_screen.dart` — NEW SCREEN. Progress bar (X of Y). Filter chips (All/Open/Done). Priority badges with color coding. Checkbox toggle (complete/reopen). Swipe-to-delete. Category + due date display. Overdue highlighting.
- `lib/screens/field_tools/change_order_screen.dart` — NEW SCREEN. Summary header (approved total + pending total). CO number badge. Status badge with color. Line items editor (add/remove rows with description, qty, unit price). Workflow buttons (Submit/Delete for drafts, Approve/Reject for pending). Create form with line items or flat amount.
- `lib/screens/field_tools/job_completion_screen.dart` — NEW SCREEN. Auto-checks 7 requirements against Supabase: punch list all done, photos exist, signature captured, no active clocks, materials logged, today's log submitted, change orders resolved. Progress indicator. "Complete Job" button (only enabled when all checks pass). Updates jobs.status to 'completed' + sets completed_at. Already-complete detection.

**Files modified:**
- `lib/screens/field_tools/field_tools_hub_screen.dart` — Added Punch List + Change Orders + Job Completion to Business & Tracking section. Tool count now 19.

**Tables to deploy:** Run migration `20260206000005_b3b_punch_list_change_orders_tables.sql` against Supabase dev.

**Verification:** `flutter analyze` — ZERO errors/warnings. Only info-level deprecations (withOpacity).

---

### Session 47 (Feb 6) — Sprint B3a: Materials Tracker + Daily Log BUILT FROM SCRATCH

**2 entirely new field tools built from scratch with full Supabase persistence.**

**SQL migration created:**
- `supabase/migrations/20260206000004_b3a_materials_daily_log_tables.sql` — job_materials + daily_logs tables. RLS, indexes, audit triggers, updated_at triggers. UNIQUE constraint on daily_logs(job_id, log_date) for one-log-per-day.

**New files created (8 foundation + 2 screens = 10 files):**
- `lib/models/job_material.dart` — JobMaterial model. MaterialCategory enum (5: material/equipment/tool/consumable/rental). computedTotal property. toInsertJson/toUpdateJson/fromJson/copyWith. Soft-delete.
- `lib/models/daily_log.dart` — DailyLog model. Maps to daily_logs table. Fields: weather, temperatureF, summary, workPerformed, issues, delays, visitors, crewMembers, crewCount, hoursWorked, photoIds, safetyNotes. isNew/hasIssues/hasDelays getters.
- `lib/repositories/job_material_repository.dart` — CRUD for job_materials. createMaterial, getMaterialsByJob, getMaterialsByCategory, updateMaterial, deleteMaterial (soft).
- `lib/repositories/daily_log_repository.dart` — CRUD for daily_logs. createLog, getLogsByJob, getTodaysLog, updateLog, upsertLog. Supports one-log-per-day pattern.
- `lib/services/job_material_service.dart` — Providers: jobMaterialRepositoryProvider, jobMaterialServiceProvider, jobMaterialsProvider (StateNotifier with totalCost/billableCost). Auth-enriched creates.
- `lib/services/daily_log_service.dart` — Providers: dailyLogRepositoryProvider, dailyLogServiceProvider, jobDailyLogsProvider (StateNotifier), todaysLogProvider. Auth-enriched creates.
- `lib/screens/field_tools/materials_tracker_screen.dart` — NEW SCREEN. Cost summary header (total/billable), material cards with category icons, swipe-to-delete with confirmation, bottom sheet form with category chips, unit dropdown (10 units), vendor field, serial number for equipment, billable toggle.
- `lib/screens/field_tools/daily_log_screen.dart` — NEW SCREEN. Two tabs: Today's Log (form) + History (list). Auto-loads existing log for today's date (edit mode). Fields: weather/temp, summary, work performed, issues, delays, crew/hours, visitors, safety notes. Save creates or updates. History shows past logs with weather, crew, hours, issue flags.

**Files modified:**
- `lib/screens/field_tools/field_tools_hub_screen.dart` — Added Materials Tracker + Daily Log to Business & Tracking section. Tool count now 16.

**Tables to deploy:** Run migration `20260206000004_b3a_materials_daily_log_tables.sql` against Supabase dev.

**Verification:** `flutter analyze` — ZERO errors/warnings. Only info-level deprecations.

---

### Session 47 (Feb 6) — Sprint B2d: Voice Notes + Level & Plumb Wired COMPLETE

**2 remaining field tools wired. ALL 14 field tools now have backend persistence.**

**New files created (3 foundation files):**
- `lib/models/voice_note.dart` — VoiceNote model. TranscriptionStatus enum (pending/processing/completed/failed). Maps to `voice_notes` table. Fields: storagePath, durationSeconds, fileSize, transcription, transcriptionStatus, tags (text[]), recordedAt. Soft-delete via deletedAt.
- `lib/repositories/voice_note_repository.dart` — Upload audio to `voice-notes` bucket + CRUD on voice_notes table. Content type: audio/m4a. Soft delete. Signed URL for playback.
- `lib/services/voice_note_service.dart` — Providers: voiceNoteRepositoryProvider, voiceNoteServiceProvider, jobVoiceNotesProvider (StateNotifier), recentVoiceNotesProvider. Auth-enriched creates.

**Packages added:**
- `record: ^5.1.2` (resolved 5.2.1) — Audio recording (AAC-LC, 128kbps)
- `audioplayers: ^6.1.0` (resolved 6.5.1) — Audio playback from signed URLs

**Files wired:**
- `lib/screens/field_tools/voice_notes_screen.dart` — Full rewrite. Long-press → real audio recording via `record` package to temp .m4a file → auto-save on stop (upload to voice-notes bucket + insert voice_notes row). Playback via `audioplayers` from signed URL. Soft delete in DB. Transcription deferred to Phase E (saves with transcription_status='pending'). Removed "Save All" button (each note auto-saves on stop). Shows "Saving..." badge until upload completes.
- `lib/screens/field_tools/level_plumb_screen.dart` — `_saveReading()` → compliance_records (type=inspection). JSONB data: tool='level_plumb', mode (surface/bullseye), x_angle, y_angle, total_angle, is_level, threshold_degrees, calibration offsets. Error handling with colored SnackBars.

**Deferred:**
- Audio transcription Edge Function (transcribe-audio) → Phase E (AI layer)
- Job linking infrastructure verification (hub already passes jobId to all 14 tools — verified)
- Active job state provider (activeJobProvider) → Phase B7 (Polish)

**Verification:** `flutter analyze` — ZERO new errors/warnings. Only pre-existing info-level (withOpacity deprecation).

---

### Session 46 (Feb 6) — Sprint B2c: Financial Tools Wired to Supabase COMPLETE

**3 financial tools wired from UI shells to persistent Supabase tables + Storage.**

**New files created (9 foundation files):**
- `lib/models/receipt.dart` — Receipt model. ReceiptCategory enum (7 values), OcrStatus enum (4 values). Maps to `receipts` table. Fields: vendorName, amount, category, description, receiptDate, ocrData (JSONB), ocrStatus, paymentMethod, storagePath. Soft-delete via deletedAt.
- `lib/models/signature.dart` — Signature model. SignaturePurpose enum (7 values: jobCompletion, invoiceApproval, changeOrder, inspection, safetyBriefing, workApproval, liabilityWaiver). Maps to `signatures` table. Fields: signerName, signerRole, storagePath, purpose, notes, location coords+address.
- `lib/models/mileage_trip.dart` — MileageTrip model. Maps to `mileage_trips` table. Fields: startAddress, endAddress, distanceMiles, purpose, routeData (JSONB), tripDate, start/end lat/lng, durationSeconds. IRS rate constant ($0.67/mi). Soft-delete.
- `lib/repositories/receipt_repository.dart` — Upload receipt image to `receipts` bucket + CRUD on receipts table. Soft delete. Signed URL access.
- `lib/repositories/signature_repository.dart` — Upload PNG to `signatures` bucket + CRUD on signatures table. Signed URL access.
- `lib/repositories/mileage_repository.dart` — CRUD for mileage_trips table. Date range queries for reports. Soft delete.
- `lib/services/receipt_service.dart` — Providers: receiptRepositoryProvider, receiptServiceProvider, jobReceiptsProvider (StateNotifier), recentReceiptsProvider. Auth-enriched creates.
- `lib/services/signature_service.dart` — Providers: signatureRepositoryProvider, signatureServiceProvider, jobSignaturesProvider (StateNotifier). Auth-enriched creates.
- `lib/services/mileage_service.dart` — Providers: mileageRepositoryProvider, mileageServiceProvider, userTripsProvider (StateNotifier), jobTripsProvider. Auth-enriched creates. Purpose update after trip stop.

**Files wired:**
- `lib/screens/field_tools/receipt_scanner_screen.dart` — `_saveReceipt()` → upload image to receipts bucket → insert receipts table row. Category maps from screen enum to model enum. OCR Edge Function deferred to Phase E (saves with ocr_status='pending'). Removed unused `dart:typed_data` import and `_isCapturing` field.
- `lib/screens/field_tools/client_signature_screen.dart` — `_saveSignature()` → generate PNG via PictureRecorder → upload to signatures bucket → insert signatures table row. Maps screen _SignatureType to model SignaturePurpose. GPS location captured at save time. Removed unused `dart:typed_data` import.
- `lib/screens/field_tools/mileage_tracker_screen.dart` — `_stopTracking()` → INSERT into mileage_trips table (distance, duration, start/end lat/lng/address). `_showPurposeDialog()` → UPDATE purpose on saved trip in Supabase. Fixed unnecessary string interpolation.

**Deferred:**
- Receipt OCR Edge Function (receipt-ocr using Claude Vision) → Phase E (AI layer)
- CSV/PDF export for receipts and mileage → Phase B3 or later

**Verification:** `flutter analyze` — ZERO errors/warnings on all 12 B2c files. Only pre-existing info-level (withOpacity deprecation).

---

### Session 45 (Feb 6) — Sprint B2b: Safety Tools Wired to compliance_records COMPLETE

**4 safety tools wired from UI shells to persistent Supabase compliance_records table.**

**New files created:**
- `lib/models/compliance_record.dart` — ComplianceRecord model. 5 types (safetyBriefing, incidentReport, loto, confinedSpace, inspection). Each with dbValue + label. JSONB data + attachments. INSERT-only immutable audit trail.
- `lib/repositories/compliance_repository.dart` — Supabase CRUD for compliance_records. createRecord, getRecordsByJob, getRecordsByType, getRecordsByJobAndType, getRecentRecords, getRecord. No update/delete (audit trail).
- `lib/services/compliance_service.dart` — Providers + notifier + service. complianceRepositoryProvider, complianceServiceProvider, jobComplianceProvider (StateNotifier.autoDispose.family), complianceByTypeProvider, recentComplianceProvider. Auth-enriched inserts (company_id, created_by_user_id).

**Files wired:**
- `lib/screens/field_tools/loto_logger_screen.dart` — `_createEntry()` and `_releaseEntry()` → compliance_records (type=loto). Lockout creates one record, release creates another (both events in audit trail). JSONB: action, equipment_id, location, energy_type, reason.
- `lib/screens/field_tools/incident_report_screen.dart` — `_submitReport()` → compliance_records (type=incident_report). Full OSHA form: severity, incident_type, description, injured_party, witnesses, immediate_action, root_cause, prevention_measures, checkboxes (medical/work_stoppage/osha_recordable/property_damage). Removed unused `dart:typed_data` import.
- `lib/screens/field_tools/safety_briefing_screen.dart` — `_submitBriefing()` → compliance_records (type=safety_briefing). JSONB: topic, hazards, ppe_required, crew_attendance (with sign-off timestamps), notes. Removed unused `dart:typed_data` import.
- `lib/screens/field_tools/confined_space_timer_screen.dart` — `_completeEntry()` → compliance_records (type=confined_space). Full OSHA 1910.146 data: permit_number, space_description, attendant, supervisor, checklist (8 items), entrants (with entry/exit timestamps), air_readings (O2/LEL/CO/H2S with timestamps), total_duration.

**Verification:** `flutter analyze` — ZERO new warnings/errors on all 8 B2b files. Only pre-existing info-level (withOpacity deprecation).

---

### Session 44 (Feb 6) — Sprint B2a: Photo Tools Wired to Supabase Storage COMPLETE

**3 photo tools wired from UI shells to persistent Supabase Storage + photos table.**

**New files created:**
- `lib/models/photo.dart` — Photo model. 8 categories (general/before/after/defect/markup/receipt/inspection/completion). Supabase serialization (toInsertJson/toUpdateJson/fromJson). Dual-format parsing. Computed properties (hasLocation, displayName, categoryLabel).
- `lib/services/storage_service.dart` — Generic Supabase Storage service. uploadFile, deleteFile, getSignedUrl. Path builder: `{companyId}/{jobId}/{category}/{timestamp}_{fileName}`. Thumbnail path builder.
- `lib/repositories/photo_repository.dart` — Supabase CRUD for photos table + Storage upload. uploadPhoto, getPhotosForJob, getPhotosByCategory, getPhoto, updatePhoto, deletePhoto (soft delete), getPhotoUrl (signed URL), getRecentPhotos.
- `lib/services/photo_service.dart` — Providers + notifier + service. photoRepositoryProvider, photoServiceProvider, jobPhotosProvider (StateNotifier.autoDispose.family), photosByCategoryProvider, photoUploadProvider. Auth-enriched uploads (company_id, uploaded_by_user_id from authState).

**Files rewritten:**
- `lib/screens/field_tools/job_site_photos_screen.dart` — Fully rewritten. Capture → immediate upload to Supabase Storage → insert photos row. Grid displays from DB (signed URLs with local byte cache for instant display of just-captured). Category selector (6 categories). Soft delete. No-job warning banner. Old `PhotoType` enum replaced with `PhotoCategory`.
- `lib/screens/field_tools/before_after_screen.dart` — `_saveComparison()` wired: uploads both before/after photos with correct categories. Refreshes jobPhotosProvider. Slider comparison UI preserved.
- `lib/screens/field_tools/defect_markup_screen.dart` — `_saveMarkup()` wired: renders RepaintBoundary to PNG via `toImage()`, uploads markup image (category=markup) + original base photo (category=defect). Annotation data (paths, text annotations) stored in photo.metadata JSONB for re-editing.

**Stale docs fixed:**
- 02_CIRCUIT_BLUEPRINT.md — Updated invoice/bid/time_clock services from stale Hive/Local to Supabase. Added B1d/B1e repositories. Updated W1/W2 checklists.
- 01_MASTER_BUILD_PLAN.md — Fixed "CURRENT STATE" table (was Session 35 stale data).
- 03_LIVE_STATUS.md — Fixed phase label and W1 build order status.

**Verification:** `flutter analyze` — ZERO new errors on all 7 B2a files. Only pre-existing warnings/infos (withOpacity deprecations, unused _isCapturing fields).

---

### Session 43 (Feb 6) — Sprint B1d + B1e: Invoices + Bids + Time Clock COMPLETE

**Sprint B1e — Time Clock + Calendar:**
- `lib/models/time_entry.dart` — Rewritten. Removed Equatable, cloud_firestore, Firestore Timestamp. Kept all sub-models (GpsLocation with dart:math Haversine, LocationPing, LocationTrackingConfig, BreakEntry). Extra fields (breaks, locations, trackingConfig, overtimeRate, mileage) stored in location_pings JSONB column. Dual-format fromJson. toInsertJson/toUpdateJson for Supabase.
- `lib/repositories/time_entry_repository.dart` — NEW. Supabase CRUD: getEntries, getActiveEntry(userId), getEntriesForUser/Job/Range, getClockedInEntries, getEntriesByStatus. createEntry, updateEntry, clockOut, updateStatus (approve/reject), updateLocationPings, deleteEntry (hard delete).
- `lib/services/time_clock_service.dart` — Rewritten. Removed Hive boxes, Firestore collection, connectivity_plus sync. Same provider names: timeClockServiceProvider, activeClockEntryProvider, userTimeEntriesProvider, companyTimeEntriesProvider, clockedInUsersProvider, timeClockStatsProvider, timeClockSyncStatusProvider. GPS integration preserved (startTracking/stopTracking/pauseForBreak/resumeAfterBreak).
- `lib/services/calendar_service.dart` — NO CHANGES NEEDED. Already reads from jobsProvider (Supabase-backed since B1c). All field names correct (scheduledStart, displayTitle, customerName, address, description, estimatedAmount).
- Zero import redirects needed — all consumers already import from correct paths.

**Verification:** `flutter analyze` — ZERO new errors.

---

### Session 43 (Feb 6) — Sprint B1d: Invoices + Bids CRUD COMPLETE

**All invoice and bid code rewritten from Hive/Firebase to Supabase.**

**Sprint B1d — Invoices CRUD:**
- `lib/models/invoice.dart` — Rewritten. Unified Supabase model. 10 statuses (draft, pendingApproval, approved, rejected, sent, viewed, partiallyPaid, paid, voided, overdue). Dual-format fromJson. toInsertJson/toUpdateJson for Supabase. dueDate now nullable. InvoiceLineItem with typedef LineItem alias.
- `lib/repositories/invoice_repository.dart` — NEW. Supabase CRUD + search + getByCustomer/Job/Status. Auto invoice number (INV-YYYY-NNNN, DB-queried sequence). Soft delete.
- `lib/services/invoice_service.dart` — Rewritten. Removed Hive/Firestore sync. Same provider names (invoicesProvider, invoiceServiceProvider, invoiceStatsProvider, overdueInvoicesProvider, unpaidInvoicesProvider, invoiceCountProvider).
- 6 screen/service imports redirected: invoices_hub_screen, invoice_detail_screen, invoice_create_screen, invoice_pdf_generator, customer_detail_screen, business_firestore_service.
- API fixes across screens: issueDate→createdAt, paidDate→paidAt, InvoiceStatus.cancelled→voided, nullable dueDate checks, 4 new enum cases in switches.

**Sprint B1d — Bids CRUD:**
- `lib/models/bid.dart` — Rewritten. Unified Supabase model. 8 statuses (draft, sent, viewed, accepted, rejected, expired, converted, cancelled) with dbValue getter for DB mapping. Options/addons/photos stored in line_items JSONB. Removed Equatable, cloud_firestore, accessToken/viewedByIp/deposit/convertedAt fields.
- `lib/repositories/bid_repository.dart` — NEW. Supabase CRUD + search + getByCustomer/Status. Auto bid number (BID-YYYYMMDD-NNN). Soft delete.
- `lib/services/bid_service.dart` — Rewritten. Removed Hive/Firestore sync. Same provider names (bidsProvider, bidServiceProvider, bidStatsProvider, draftBidsProvider, pendingBidsProvider, acceptedBidsProvider, bidCountProvider). Kept sendBid/acceptBid/rejectBid/convertToJob operations.
- 2 screen imports updated: bid_detail_screen, bids_hub_screen.
- API fixes: BidStatus.declined→rejected, respondedAt→acceptedAt/rejectedAt, removed depositPaid/convertedAt refs.

**Also fixed (from B1c):**
- `home_screen_v2.dart:273` — job.title (String?) → job.displayTitle (String)
- `system_prompt_builder.dart:159` — statusDisplay → statusLabel

**Verification:**
- `flutter analyze` — ZERO new errors (only pre-existing 4 battery_plus errors in location_tracking_service.dart)
- All consumer files compile without changes (same provider API surfaces preserved)

---

### Session 42 (Feb 6) — Sprint B1b + B1c: Customers + Jobs CRUD COMPLETE (crash recovery)

**Recovered from Session 41 crash mid-B1c. Verified B1b was complete, finished B1c.**

**Sprint B1b — Customers CRUD:**
- `lib/models/customer.dart` — Rewritten from Firebase to Supabase schema. Dual-format fromJson (snake_case + camelCase). Soft delete. toInsertJson/toUpdateJson for Supabase, toJson for legacy compat.
- `lib/repositories/customer_repository.dart` — NEW. Supabase CRUD (getCustomers, getCustomer, searchCustomers, createCustomer, updateCustomer, deleteCustomer via soft delete).
- `lib/services/customer_service.dart` — Rewritten. Removed Hive/Firestore sync. Direct Supabase via repository. Same provider names (customersProvider, customerServiceProvider, customerStatsProvider, customerCountProvider).
- 3 screen imports redirected: customers_hub_screen, customer_detail_screen, customer_create_screen.
- business_firestore_service.dart import redirected.

**Sprint B1c — Jobs CRUD:**
- `lib/models/job.dart` — Rewritten from Firebase to Supabase schema. New statuses: dispatched, enRoute, onHold. JobType enum with dbValue for snake_case DB. Legacy field mapping (lead→draft, scheduledDate→scheduledStart, completedDate→completedAt, notes→description).
- `lib/repositories/job_repository.dart` — NEW. Supabase CRUD + status updates + search + getByCustomer + getByStatus. Soft delete via deleted_at.
- `lib/services/job_service.dart` — Rewritten. Removed Hive/Firestore sync. Direct Supabase via repository. Same provider names (jobsProvider, jobServiceProvider, jobStatsProvider, activeJobsProvider). Added jobCountProvider.
- 9 screen imports redirected: jobs_hub_screen, job_detail_screen, job_create_screen, bid_detail_screen, time_clock_screen, customer_detail_screen, calendar_service, business_firestore_service, zafto_save_to_job.
- All screens updated for new API: JobStatus.lead→draft, .title→.displayTitle, .notes→.description, .scheduledDate→.scheduledStart, .completedDate→.completedAt, nullable→non-nullable customerName/address.
- Status machine expanded: draft→scheduled→dispatched→enRoute→inProgress→onHold→completed→invoiced (+ cancel paths).

**Verification:**
- `flutter analyze` — ZERO errors on all 12 B1c files
- All consumer files analyzed — ZERO new breakage (only pre-existing warnings)

---

### Session 41 (Feb 6) — Sprint B1a: Supabase Auth Flow COMPLETE

**Auth system fully rewritten from Firebase to Supabase. Same API surface — 16 consumer files unchanged.**

**New files created:**
- `lib/core/errors.dart` — Sealed error class hierarchy (AppError, AuthError, NetworkError, DatabaseError, ValidationError, NotFoundError, PermissionError)
- `lib/repositories/auth_repository.dart` — Pure Supabase auth operations: register, signIn, signOut, resetPassword, refreshSession, fetchUserProfile, createCompanyAndUser, recordLoginAttempt. Maps AuthException to typed AuthError with user-friendly messages.

**Files rewritten:**
- `lib/services/auth_service.dart` — Replaced Firebase Auth with Supabase Auth. Same API surface (AuthStatus, AuthState, ZaftoUser, authStateProvider, authServiceProvider). Added `needsOnboarding` status. Supabase types imported with `supa.` prefix to avoid AuthState collision. Guest mode returns error (business app requires auth).

**Files modified:**
- `lib/main.dart` — Added `await initSupabase(devConfig)` before Firebase init. Routes to CompanySetupScreen when authState.status == needsOnboarding.
- `lib/screens/onboarding/company_setup_screen.dart` — Made selectedTier and onComplete optional. Added fullName field + trade dropdown (11 trades). Standalone mode calls authNotifier.completeOnboarding(). Legacy callback mode preserved.

**Verification:**
- `flutter analyze` — ZERO issues on all 5 B1a files
- All 16 consumer files analyzed — ZERO new breakage (only pre-existing battery_plus errors)
- Auth flow: signUp → needsOnboarding → CompanySetupScreen → createCompanyAndUser → refresh JWT → authenticated → HomeScreenV2

---

### Session 40 (Feb 6) — Employee Field Portal Spec + A3 Verified Complete

**CRITICAL DOC FIX: A3a-A3c were already deployed to zafto-dev (16 tables verified via SQL Editor). Previous handoff incorrectly said "deploy pending." Env keys were also already filled. Fixed all docs.**

**Employee Field Portal (team.zafto.app) — fully spec'd and locked into master plan:**
- New portal for field employees (techs, apprentices, crew leads)
- ~25 pages: dashboard, jobs, time clock, field tools (web), daily logs, punch lists, change orders, materials, bid creation, meeting rooms, notifications, settings
- AI Troubleshooting Center (Phase E1): multi-trade diagnostics, photo-based diagnosis, code/compliance lookup, parts identification, repair guides, company knowledge base
- Permission-gated by owner/admin — fully customizable per-role and per-user
- No sensitive company financials exposed (no P&L, bank, revenue, payroll)
- PWA-capable, field-optimized UI (big touch targets, works on phone browsers)
- Same Supabase backend, RLS handles scoping
- Codebase: `apps/Trades/team-portal/`
- Build order updated: B5 = Employee Field Portal, B6 = Client Portal (shifted), B7 = Polish (shifted)

**Sprint A3d — Storage buckets DONE:**
- 7 private buckets created in Supabase dev: photos, signatures, voice-notes, receipts, documents, avatars, company-logos

**Docs updated:** 01_MASTER_BUILD_PLAN.md, 03_LIVE_STATUS.md, 00_HANDOFF.md, CLAUDE.md, MEMORY.md

---

### Session 39 (Feb 6) — Sprint A2: DevOps Phase 1 (Environments + Secrets + Dependabot)

**Sprint A2 executed — environment config system built:**
- `lib/core/env.dart` — EnvConfig class + Environment enum (committed)
- `lib/core/env_template.dart` — Placeholder template for copying (committed)
- `lib/core/env_dev.dart` / `env_staging.dart` / `env_prod.dart` — Real key files (gitignored)
- `web-portal/.env.example` — Supabase env template for Web CRM (committed)
- `client-portal/.env.example` — Supabase env template for Client Portal (committed)
- `.github/dependabot.yml` — Weekly dependency scans for pub + npm (web-portal + client-portal)

**Gitignore hardened:**
- Root `.gitignore` — Added negation rules for `.env.example` and `.env.local.example`
- `apps/Trades/.gitignore` — Replaced broad `env.dart` pattern with specific `lib/core/env_dev/staging/prod.dart` patterns
- `web-portal/.gitignore` — Added `.env.staging` and `.env.production` to ignore list
- `client-portal/.gitignore` — Added `!.env.example` negation so template can be committed
- All verified with `git check-ignore -v` — correct files ignored, correct files trackable

**Flutter analyze:** Zero issues on `lib/core/`

**Manual step required:** Create `zafto-staging` Supabase project + fill real keys into env files

**Sprint A3 SQL migration files created (ready to deploy):**
- `supabase/migrations/20260206000001_a3a_core_tables.sql` — companies, users, audit_log, user_sessions, login_attempts + RLS + JWT claims triggers
- `supabase/migrations/20260206000002_a3b_business_tables.sql` — customers, jobs, invoices, bids, time_entries + RLS + audit
- `supabase/migrations/20260206000003_a3c_field_tool_tables.sql` — photos, signatures, voice_notes, receipts, compliance_records, mileage_trips + RLS + audit

**Supabase client added:**
- `lib/core/supabase_client.dart` — Supabase initialization, auth convenience getters
- `supabase_flutter: ^2.8.0` added to pubspec.yaml (resolved to v2.12.0)
- `flutter analyze lib/core/` — zero issues
- Full `flutter analyze lib/` — 4 pre-existing errors in location_tracking_service.dart (missing battery_plus), 2716 infos

**Pre-existing issue found:** `location_tracking_service.dart` imports `battery_plus` which is not in pubspec.yaml — 4 compile errors. Predates Session 39.

---

### Session 38 (Feb 6) — Sprint Specs Expansion (Execution System Complete)

**Three execution system docs created (Session 37, expanded Session 38):**
- `05_EXECUTION_PLAYBOOK.md` — Session protocol, sprint methodology, quality gates, bug prevention, emergency procedures
- `06_ARCHITECTURE_PATTERNS.md` — 14 code patterns with full examples (Model, Repository, Error, Provider, Screen, RLS, Audit, PowerSync, Web CRM, Client Portal, Testing, Soft Delete, Timestamps)
- `07_SPRINT_SPECS.md` — **MASSIVELY EXPANDED**: 2,605 lines covering every sprint through launch

**Phase B fully detailed (16 sub-sprints):**
- B1a: Auth (Supabase Auth + JWT claims + onboarding + session management)
- B1b: Customers CRUD (model unification + repository + providers + screens)
- B1c: Jobs CRUD (status machine + repository + providers + home dashboard)
- B1d: Invoices + Bids CRUD (full lifecycle + conversion flows)
- B1e: Time Clock + Calendar (GPS tracking + time entries + schedule)
- B2a: Photo tools (3 tools: job site photos, before/after, defect markup → Storage)
- B2b: Safety tools (4 tools: LOTO, incidents, briefings, confined space)
- B2c: Financial tools (3 tools: receipt OCR via Claude Vision, signatures, mileage)
- B2d: Voice notes + Level/Plumb + job linking infrastructure for all tools
- B3a: Materials Tracker + Daily Job Log (NEW tables + screens)
- B3b: Punch List + Change Orders + Job Completion Workflow (NEW tables + screens)
- B4a: Web CRM infrastructure (replace Firebase with Supabase, auth, middleware)
- B4b: Web CRM operations pages (12 core pages wired to real data)
- B4c: Web CRM remaining pages (25+ pages: team, calendar, resources, settings)
- B4d: **UI Polish** — collapsible sidebar (icon rail → expand on hover), visual restraint (2-3 accent colors max), typography hierarchy (uppercase tracking-wide labels), chart upgrade (smooth Bezier curves, gradient fills), spacing pass (32-40px between sections), dark mode depth layers. Supabase dashboard as reference benchmark.
- B4e: **Z Intelligence Chat + Artifacts** — persistent right-side chat panel (survives page navigation), slash commands, contextual suggestions per page, artifact system (document/table/chart/code/action types), split-pane viewer, Apply/Edit/Discard toolbar, version diffs. Claude Desktop as reference benchmark but in ZAFTO design language.
- B5a: Client Portal auth (magic link, client_portal_users table, RLS for customers)
- B5b: Client Portal pages (21 pages wired to real data)
- B6a: Screen registry + Cmd+K entity search
- B6b: Push notifications + real-time indicators
- B6c: Offline polish + loading/error/empty states

**Phase C fully detailed (7 sub-sprints):**
- C1a: Sentry integration, C1b: CI/CD pipeline, C1c: Test suite
- C2: Full QA across all roles and scenarios
- C3: Ops Portal Phase 1 (18 pages, outlined for sub-sprint detail later)
- C4: Security hardening, C5: Incident response plan

**New database tables designed:**
- `job_materials` — materials/equipment installed per job
- `daily_logs` — daily job documentation
- `punch_list_items` — task checklists per job
- `change_orders` — scope change tracking with signatures
- `client_portal_users` — customer portal auth (separate from main users)
- `notifications` — push notification records

**New Edge Functions specified:**
- `receipt-ocr` — Claude Vision receipt parsing
- `transcribe-audio` — Voice note transcription
- `send-notification` — Push notification delivery

**Codebase exploration completed (2 parallel agents):**
- Flutter: all screens mapped, all services analyzed, all TODO:BACKEND comments cataloged
- Web CRM: 39 pages mapped with routes, mock data structures, 13 TODO comments, full TypeScript types
- Client Portal: 21 pages mapped, 100% static, fake auth confirmed

---

### Session 37 (Feb 6) — Code Cleanup (Phase A1)

**Dead code deleted (8 files, 3,637 lines):**
- `photo_service.dart` (491 lines) — complete but zero imports
- `email_service.dart` (707 lines) — email via Cloud Functions, zero imports
- `pdf_service.dart` (690 lines) — PDF generation, zero imports
- `stripe_service.dart` (341 lines) — payment processing, zero imports
- `firebase_config.dart` (13 lines) — dead duplicate config (project `zafto-5c3f2`)
- `offline_queue_service.dart` (376 lines) — offline queue, zero imports
- `role_service.dart` (514 lines) — role management, zero imports
- `user_service.dart` (505 lines) — user management, zero imports
- Empty `lib/config/` directory removed

**Duplicate models — DEFERRED to W1 wiring:**
- Root models and business models have incompatible APIs (different required fields, enum values, method names like toJson vs toMap, statusLabel vs statusDisplay)
- 24 files import from `models/business/` — all will be rewritten during W1 Supabase wiring
- Doing redirect now would double the work with zero benefit

**Firebase cleanup — partial (rest deferred to A3):**
- Dead config deleted (`firebase_config.dart`, project `zafto-5c3f2`)
- Active configs kept until Supabase migration: `firebase_options.dart` (zafto-2b563), `GoogleService-Info.plist` (zafto-electrical)

**Docs updated:**
- All POST-LAUNCH labels removed from `03_LIVE_STATUS.md` and `04_EXPANSION_SPECS.md`
- Everything is PRE-LAUNCH per user directive

---

### Session 36 (Feb 6) — Deep Code Audit + Expansion Specs + Firebase Discovery

**Deep code audit completed (3 parallel agents):**
- Flutter: Found 3 Firebase projects (not 2!): `zafto-5c3f2`, `zafto-2b563`, `zafto-electrical`
- Flutter: Confirmed duplicate models — root models are more complete in all 3 cases
- Flutter: 26 TODO:BACKEND comments verified, PhotoService confirmed 0 imports (dead code)
- Flutter: 42 service files, 26 with Firebase imports
- Web CRM: 13 TODOs (all Firestore), `.env.local` has Firebase + Mapbox keys, 3 @ts-nocheck files
- Client Portal: 100% frontend-only confirmed, zero TODOs, zero secrets, fake auth

**Docs created/updated:**
- `04_EXPANSION_SPECS.md` — ALL 14 expansion + locked specs consolidated into single doc
- `02_CIRCUIT_BLUEPRINT.md` — Updated Firebase project mismatch to reflect 3 projects
- Property Management System spec outlined (needs dedicated session)

**Key discovery — THREE Firebase projects:**
- `firebase_config.dart` → `zafto-5c3f2` (Web SDK config, Jan 29)
- `firebase_options.dart` → `zafto-2b563` (FlutterFire config, Jan 30)
- `ios/GoogleService-Info.plist` → `zafto-electrical` (original iOS config)
- Web CRM `.env.local` → uses `zafto-2b563` keys
- All irrelevant since migrating to Supabase — but need cleanup

---

### Session 35 (Feb 6) — Account Setup + No-Drift Doc System + Code Audit

**Accounts created/verified:**
- MS 365 Business Basic — 5 emails on zafto.app (admin, robert, support, legal, info)
- Supabase — 2 projects (zafto-dev, zafto-prod) on US East
- Sentry — free tier, account created
- RevenueCat — account created
- Bitwarden — existing, needs email migration to admin@zafto.app
- Stripe, GitHub, Apple Developer, Anthropic, Cloudflare — verified accessible

**Docs created:**
- `ZAFTO FULL BUILD DOC/` — new single-source-of-truth doc folder
- `00_HANDOFF.md` — this file
- `01_MASTER_BUILD_PLAN.md` — complete no-drift build plan
- `02_CIRCUIT_BLUEPRINT.md` — living wiring diagram (TODO: write)
- `03_LIVE_STATUS.md` — quick status snapshot
- `CLAUDE.md` — rewritten for max session effectiveness

**Code audit completed (3 parallel agents):**
- Flutter app: 1,517 Dart files, 161 Firebase refs, 0 Supabase refs, duplicate models
- Web CRM: 66 files, Firebase-only, 12 Firestore TODOs
- Client Portal: 25 pages, zero backend, completely static mockup

**New feature identified:**
- Property Management System — contractors who own rental properties. Maintenance loop closes internally through ZAFTO job system. Needs dedicated spec session.

**Design decisions confirmed:**
- "ZAFTO" wordmark (Stripe-style), not just Z
- Z reserved for AI/premium (Z Intelligence, Ledger, Dashboard)
- Ledger (not "ZAFTO Books")
- AI goes LAST after all functionality confirmed
- Stripe feel everywhere

---

## NEXT SESSION PRIORITIES (Updated S97)

1. **Phase T (Programs)** — NEXT to build. Full spec in `Expansion/39_TPA_MODULE_SPEC.md`. ~80 hours, 10 sprints, ~17 tables, 3 EFs.
2. **Phase P (Recon / Property Intelligence)** — After T. Full spec in `Expansion/40_PROPERTY_INTELLIGENCE_SPEC.md`. ~96 hours, 10 sprints. Lead scoring, batch area scanning, storm intelligence, supplement checklist, multi-structure detection, confidence scoring.
3. **Phase SK (Sketch Engine)** — After P. Full spec in `Expansion/46_SKETCH_ENGINE_SPEC.md`. ~176 hours, 11 sprints.
4. **Phase GC (Schedule)** — After SK. Full spec in `Expansion/48_GANTT_CPM_SCHEDULER_SPEC.md`. ~124 hours, 11 sprints.
5. **Phase U (Unification & Feature Completion)** — After GC. 9 sprints, ~120 hours. Needs full spec session.
6. **Phase G (QA/Hardening)** — After U. Full platform debug, security, performance.
7. **Phase E (AI Layer)** — LAST. E-review → BA1-BA8 Plan Review → E1-E4. Deep spec session required.

**Phases A-F ALL COMPLETE. R1 DONE. FM code done. ~173 tables. 48 migrations. 53 Edge Functions. 107 CRM routes. 36 team routes. 38 client routes. 26 ops routes. 4 CI workflows. All 19 field tools wired. Codemagic Android debug PASSING.**

---

## HOW TO VERIFY STATE (Run these checks)

### Quick verification commands:
```bash
# Flutter app — check for Firebase vs Supabase
grep -r "firebase" apps/Trades/lib/ --include="*.dart" | wc -l  # Should decrease over time
grep -r "supabase" apps/Trades/lib/ --include="*.dart" | wc -l  # Should increase

# Web CRM — check pages exist
ls apps/Trades/web-portal/src/app/dashboard/*/page.tsx | wc -l  # Should be 30+

# Client Portal — check pages exist
find apps/Trades/client-portal/src/app -name "page.tsx" | wc -l  # Should be 25+

# Check for duplicate models
ls apps/Trades/lib/models/business/  # Should be cleaned up eventually
```

---

## VERIFIED CODEBASE STATE

**NOTE: This section was a S35 snapshot. The data below reflects current state as of S97. For detailed wiring status, see `02_CIRCUIT_BLUEPRINT.md`.**

### Current State (S97)
| Metric | Value |
|--------|-------|
| **Flutter Mobile App** | 33 role-based screens (R1), 19 field tools wired, 35+ Supabase models, 32 repositories, Riverpod state. `dart analyze`: 0 errors. |
| **Web CRM** | 107 routes, 68 hooks, Supabase auth + RLS, `npm run build`: 0 errors. `zafto.cloud`. |
| **Team Portal** | 36 routes, 22 hooks, PWA-ready, `npm run build`: 0 errors. `team.zafto.cloud`. |
| **Client Portal** | 38 routes, 21 hooks, magic link auth, `npm run build`: 0 errors. `client.zafto.cloud`. |
| **Ops Portal** | 26 routes, super_admin role gate, `npm run build`: 0 errors. `ops.zafto.cloud`. |
| **Database** | ~173 Supabase PostgreSQL tables, 48 migrations, RLS + audit on all. |
| **Edge Functions** | 53 directories (32 pre-F + 21 F-phase/FM). 5 E4 uncommitted. |
| **Firebase refs remaining** | 13 files still import cloud_firestore (Phase G cleanup). |
| **Storage** | 7 private buckets (photos, signatures, voice-notes, receipts, documents, avatars, company-logos). |
| **CI/CD** | Codemagic Android debug PASSING. iOS needs code signing. 4 GitHub Actions workflows. |
| **Sentry** | SDK wired in all 4 web apps + Flutter. DSN is EMPTY — needs setup. |

---

## ACCOUNT INVENTORY

**See `03_LIVE_STATUS.md` ACCOUNTS STATUS section for the canonical, up-to-date account list. Key accounts below for quick reference:**

| Account | Status |
|---------|--------|
| MS 365 Business Basic | ACTIVE (5 emails on zafto.app) |
| Supabase | ACTIVE (2 projects: dev + prod) |
| Sentry | ACTIVE (free tier, DSN empty) |
| Stripe | ACTIVE (needs migration to admin@zafto.app) |
| GitHub (TeredaDeveloper) | ACTIVE (needs migration to admin@zafto.app) |
| Codemagic | ACTIVE (Android debug PASSING) |
| Cloudflare | ACTIVE (DNS for *.zafto.cloud) |
| Google Play | NOT CREATED (needed for launch) |
| ProtonMail | NOT CREATED (break-glass recovery) |
| YubiKeys | NOT PURCHASED |

---

## DOC STRUCTURE (ZAFTO FULL BUILD DOC/)

| File | Purpose | When to Read |
|------|---------|-------------|
| `00_HANDOFF.md` | THIS FILE — session resume, entry point | Every session start |
| `01_MASTER_BUILD_PLAN.md` | Complete no-drift build plan, architecture | When planning work |
| `02_CIRCUIT_BLUEPRINT.md` | Living wiring diagram, all tables/EFs/services | Before any wiring |
| `03_LIVE_STATUS.md` | Quick status snapshot | Quick state check |
| `04_EXPANSION_SPECS.md` | All 14 expansion + locked specs consolidated | When referencing older specs |
| `05_EXECUTION_PLAYBOOK.md` | Session protocol, methodology, quality gates | Every session start (before coding) |
| `06_ARCHITECTURE_PATTERNS.md` | 14 code patterns with examples | Before writing any code |
| `07_SPRINT_SPECS.md` | Every sprint, every step, every verification | When executing a sprint |
| `08_INCIDENT_RESPONSE.md` | Severity levels, breach response, rollback | Reference / incidents |
| `Expansion/` | Feature specs (39_TPA, 40_PROPERTY_INTELLIGENCE, 46_SKETCH_ENGINE, 47_BLUEPRINT_ANALYZER, etc.) | When executing that sprint |
| `Locked/` | Finalized specs (11_DESIGN_SYSTEM, 29_DB_MIGRATION, 30_SECURITY, 32_DEVOPS, 34_OPS_PORTAL, 36_RESTORATION, 37_JOB_TYPE) | Reference only — do not modify |

**Canonical doc location: `Build Documentation/ZAFTO FULL BUILD DOC/`. Old docs in `Build Documentation/` root are REFERENCE ONLY. Do not update them.**

---

## CRITICAL RULES

1. **NO DRIFT** — Update these docs, never create new parallel docs
2. **AI goes LAST** — Wire everything, confirm it works, then add AI
3. **ZAFTO wordmark** — Not just the Z. Z is for AI/premium features.
4. **Ledger** — Not "ZAFTO Books"
5. **Stripe feel** — Premium, clean, professional
6. **Database: Supabase PostgreSQL** — No Firebase
7. **Offline-first** — PowerSync (SQLite <-> PostgreSQL)
8. **RLS on every table** — Tenant isolation at database level
9. **Test during wiring** — Not as a separate phase
10. **Update Circuit Blueprint** as connections are made

---

CLAUDE: Read this file at the start of every session. Update it at the end.
