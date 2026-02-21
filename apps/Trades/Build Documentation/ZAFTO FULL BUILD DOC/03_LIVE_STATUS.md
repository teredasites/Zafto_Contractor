# ZAFTO LIVE STATUS
## UPDATE THIS EVERY SESSION

**Last Updated:** February 20, 2026 (Session 147 — **ADJ1-ADJ12 FULL AUDIT + 178 FIXES.** 4 parallel Opus audit agents reviewed all 12 adjuster portal sprints (185 findings: 21 CRITICAL, 60 HIGH, 63 MEDIUM, 41 LOW, avg 7.3/10). 4 Opus fix agents applied 178 checklist items + 10 inline SQL corrections. Key CRITICAL fixes: ADJ5 SECURITY DEFINER `SET search_path = public` + `auth.uid()` NULL fix, ADJ10 system template SELECT `deleted_at IS NULL`, ADJ11 RLS operator precedence (parentheses) + cross-company audit trigger, ADJ12 Hive EncryptedBox + push token expiration. 07_SPRINT_SPECS.md now ~38,400 lines. Commit: e2c31be. Previous: Session 146 — **RE21-RE30 FULL AUDIT + 135 FIXES (2 passes).** 5 parallel Opus audit agents reviewed all 10 realtor expansion sprints. Found 35 CRITICAL + 63 HIGH + 46 MEDIUM + 21 LOW (avg 6.5/10). Applied 44 fixes: `deleted_at IS NULL` in ~40 SELECT/UPDATE RLS policies, `NOT NULL` on timestamps, RE27 FK reorder, RE26 client portal RLS (4 new policies), RE27+RE29+RE30 missing `updated_at`/`deleted_at` columns+triggers, RE23 `transaction_id`+`is_favorite` (S143), RE22 INSERT restricted, RE28 agent_user_id scoping + public SELECT, RE30 IF NOT EXISTS + UNIQUE dedup + FKs, RE24 AI dependency note. Phase Audit Summary: RE21-30 hours corrected ~160h→~236h, POST-LAUNCH list corrected. Previous: S144 CONTRACTOR SPEC EXPANSION + ZFORGE-FRESH + SHARED CROSS-APP + CUST9 + RE1-RE20. Previous: S143 continued — **DEPTH2-6 COMPLETE. TI-3 COMPLETE.** DEPTH6: Calculator & template depth audit — HVAC duct sizing formula fixed, disclaimer footer added to scaffold, 2 thin templates expanded. Audit: 1,073 calcs (avg 8.4/10 depth), 25 templates (code refs 100% accurate). Critical gap: 0 restoration calcs. Previous: DEPTH5 cross-entity form depth verification — 39 CRM + 44 Flutter + 16 team + 7 client forms audited vs 28 DB tables (~519 fields). 3 critical forms fixed: Leads 35%→76% (company, address, trade, urgency, follow-up), Applicants 28%→60% (trades, certs, portfolio), Change Orders 58%→83% (dynamic line items, wired to hook, real job dropdown). "Show all fields" toggle does not exist on any web portal — documented. DEPTH3: Walkthrough hook/schema audit found 5 data bugs across all 3 portals (column name mismatches causing room_count/photo_count to always show 0, condition_tags invisible, photo types wrong, templates hard delete, missing deleted_at filter). Migration 127. Fixed 8 files across web/team/client. Previous: DEPTH2: Full field tools audit (4 parallel Opus agents) — 9 features audited, 38+ gaps found, 15 CRITICAL. Corrections: migration 126 (daily_logs soft delete, mileage trip_type + GPS, punch_list soft delete, voice_notes updated_at, trade_data JSONB, 5 indexes), 5 web portal hooks (use-daily-logs, use-photos, use-punch-list, use-voice-notes, use-mileage), 2 client portal hooks (use-punch-list read-only, use-photos client-visible). TI-3: vitest in all 4 portals, 9 tests passing. 126 migrations. ~222 tables. Previous: A11Y-2+3 COMPLETE, LEGAL-1+3+4 COMPLETE, INFRA-4+5 COMPLETE (code parts). Previous: **A11Y-1 COMPLETE (2 commits: bf52ff4, 99f4306).** WCAG 2.2 AA foundation: axe-core + jest-axe in all 4 portals, Lighthouse CI gate, Flutter a11y_test.dart, prefers-reduced-motion/contrast/color-scheme CSS, sr-only utility, contrast fix (#737373→#808080). **Owner directive S142: ALL 252 sprints (~4,454h) are in-pipeline. NOTHING orphaned. Everything ships.** ~3 services moved to AWS (details TBD). Node.js LTS 20 rollback. Now executing A11Y-2. Previous: S139-S140: SEC-AUDIT-1→5 ALL COMPLETE (5 commits). S141: SEC-AUDIT-6 doc cleanup + P-FIX1 started. Previous: S138: FULL PROJECT WEAKNESS AUDIT + ECOSYSTEM METHODOLOGY HARDENING. 5 Opus audit agents scanned DB, Flutter, Next.js, Edge Functions, Sprint Specs: **103 findings (20 CRITICAL, 31 HIGH, 26 MEDIUM, 26 LOW).** Top 10 dangers: automation-engine zero auth, sendgrid-email open relay, user_credits exploit, plaid_access_token exposure, cross-tenant invoice export, fail-open webhooks, 25+ hard deletes, unrestricted company creation, missing deleted_at filters, sendgrid webhook unverified. **SEC-AUDIT-1→6 sprint spec written (~28h).** Enterprise methodology hardened: CLAUDE.md 8→18 critical rules. INFRA-5 expanded (observability, webhook idempotency, feature flags, rate limiting, CI enforcement). TI-7 expanded (cross-app integration tests, mandatory security template). LAUNCH8 expanded (incident response playbook, data lifecycle/retention — GDPR/CCPA). **6 ecosystem methodology gaps spec'd:** (1) shared type system → INFRA-3+5, (2) mobile backward compat → INFRA-5, (3) optimistic locking → INFRA-5, (4) full-text search → INFRA-4, (5) data lifecycle/retention → LAUNCH8, (6) performance budget → INFRA-4+ZERO1. INFRA: 8h→20h. LAUNCH8: 12h→20h. ZERO1: 8h→12h. **S138 continued: P-FIX1(~6h) + A11Y-1→3(~20h) + LEGAL-1→4(~26h) + LAUNCH-FLAVORS(~16h) + APP-DEPTH(~24h) spec'd. 21 CLAUDE.md rules (added: depth verification gate, i18n flawlessness, app parity). i18n hardening in LAUNCH4. Drift audit: execution orders synchronized, Phase Audit Summary updated, DEPTH1/SEC7 checkboxes fixed. Updated totals: ~155 sprints (~2,860h).** S137 (crashed): Enterprise infrastructure research complete, INFRA-1→5 spec written, PITR flagged as launch blocker. Previous: S136: Doc updates from S134-S135 crashes. NICHE2: Service trades — 3 tables (locksmith_service_logs, garage_door_service_logs, appliance_service_logs), 3 Flutter models + 3 repos + 3 screens with diagnostic flows, 3 CRM hooks + 3 pages, team portal combined page, client portal service-history page. 36 seed line items. NICHE1: Pest control — 3 tables, 1 EF, 4 screens, all portals. Circuit blueprint FULLY UPDATED (94 EFs, ~215 tables, 113 migrations). Previous: FIELD1: Real-time messaging system — conversations + messages + conversation_members tables, Flutter 3 screens, CRM team-chat rewrite, team portal messages page, bottom nav wiring. FIELD2: Equipment & tool checkout — equipment_items + equipment_checkouts tables, Flutter 4 screens + models + repo + providers, CRM tool-checkout page, team portal tool-checkout page, sidebar links. All builds pass. Previous: **SEC1 COMPLETE.** Storage bucket RLS (8 buckets, company-scoped). Persistent rate limiter (table-based, atomic RPC, pg_cron cleanup). Equipment database write policy hardened. Rate limiter wired into 6 priority EFs. Auth added to lead-aggregator. Created `_shared/rate-limiter.ts` + `_shared/cors.ts`. 1 migration, 8 files changed. Previous: Session 130 continued — **FULL SPRINT AUDIT COMPLETE.** 5 parallel Opus audit agents reviewed ALL 109 sprints. CRITICAL fixes: execution order corrected (DEPTH40/44 were missing, FLIP5 moved after Phase E), sprint count 102→109, ZERO1-ZERO8→ZERO1-ZERO9. NEW sprints: FIELD5 (BYOC phone ~10h), LAUNCH8 (deployment runbook + disaster recovery ~12h), LAUNCH9 (OPS PORTAL FORTRESS — IP whitelist hard lock, FIDO2 hardware key, Cloudflare Access zero-trust, incident response ~10h). REST1/REST2/NICHE1/NICHE2 all beefed up with database tables, RLS, web CRM hooks/pages, team/client portal, PDF generation, repositories. NICHE2 restructured: locksmith/garage door/appliance each get own subsection with diagnostic flows. Hour corrections on most underestimated sprints: DEPTH14 10h→28h, DEPTH43 16h→36h, LAUNCH4 14h→40h, LAUNCH5 10h→30h, SEC9 20h→36h, ZERO9 10h→24h. DEPTH grading rubric defined (DEEP/SHALLOW/STUB). Sign in with Apple added to LAUNCH7. ~109 sprints, ~1,832h listed (~2,100h realistic). Previous: S129: FULL ZAFTO REALTOR PLATFORM SPEC. Deep research (9 parallel Opus agents): competitor pricing, 30+ free APIs, MLS integration paths, brokerage management, CRM features, proptech flagships, trust account legal risk. **Created `Expansion/53_REALTOR_PLATFORM_SPEC.md` (~444h, 20 sprints RE1-RE20): full equal-depth platform to Zafto Contractor.** 3 flagship engines: Smart CMA Engine, Autonomous Transaction Engine, Seller Finder Engine. RBAC hierarchy (brokerage_owner → managing_broker → team_lead → realtor → tc → isa). Commission tracking (NOT trust accounts — legal risk). Cross-platform intelligence sharing with Zafto Contractor users. 6th portal: realtor.zafto.cloud (~85-100 routes). Same field tools/calculators for dispatched contractors/inspectors. **JUR4 added (~14h): realtor jurisdiction awareness — 50-state disclosures, agency rules, attorney states, commission regulations, license reciprocity.** REALTOR1-3 superseded by RE1-RE20. ~94 sprints, ~1,576h total.)
**Current Phase:** BUILD — **Phases A-D + F + T + P + SK + GC + U + W + J + L ALL COMPLETE. D5-PV DONE (S117). Phase INS COMPLETE (S121-S122, INS1-INS8). Phase G IN PROGRESS (G1-G5 automated DONE, G6-G10 manual QA PENDING). REST1+REST2 COMPLETE. NICHE1+NICHE2 ALL COMPLETE. DEPTH1-6 COMPLETE. SEC-AUDIT-1→6 COMPLETE. P-FIX1 COMPLETE. A11Y-1→3 COMPLETE. LEGAL-1+3+4 COMPLETE. INFRA-4+5 code COMPLETE. TI-3 COMPLETE.** R1 DONE. FM code done. Phase E PAUSED. ~222 tables. 127 migrations. 98 Edge Functions. 150 CRM routes. 43 team routes. 45 client routes. 31 ops routes.
**Next Action:** **DEPTH7(NEXT)** → DEPTH8-39 → DEPTH40-nonAI → DEPTH41-43 → DATA-ARCH1-4 → INTEG6→2→3→4→7→8 → S135-ENTITY → RE1-20 → RE21-30 → ADJ1-12 → INTEG1 → FLIP1-4 → INTEG5 → SEC2-5 → LAUNCH1-6 → LAUNCH8 → G → JUR → E → FLIP5+DEPTH40-AI+DEPTH44 → SEC9-10 → ZERO1-9 → LAUNCH7 → LAUNCH-FLAVORS → APP-DEPTH → **[PITR ON]** → SHIP. **S147: ADJ1-ADJ12 full audit + 178 fixes (4 Opus audit + 4 Opus fix agents). ADJ sprints are audit-clean. 07_SPRINT_SPECS.md now ~38,400 lines.**

---

## QUICK STATE

| Field | Value |
|-------|-------|
| **Phase** | BUILD — **Phases A-D + F + T + P + SK + GC + U + W + J + L ALL COMPLETE. Phase INS COMPLETE (S122). Phase G IN PROGRESS (G1-G5 automated DONE). SEC1+SEC6-8 COMPLETE. FIELD1-5 COMPLETE. REST1+REST2 COMPLETE. NICHE1+NICHE2 ALL COMPLETE. DEPTH1 COMPLETE (S131).** R1 DONE. FM code done. Phase E PAUSED. ~215 tables. 115 migrations. 92 Edge Functions. 150 CRM routes. 43 team routes. 45 client routes. 30 ops routes. **S138: Full project audit (103 findings) → SEC-AUDIT-1→6 + P-FIX1 + A11Y-1→3 + LEGAL-1→4 + LAUNCH-FLAVORS + APP-DEPTH spec'd. 21 CLAUDE.md rules (depth verification gate, i18n flawlessness, app parity). ~155 sprints, ~2,860h.** Next: SEC-AUDIT-1. |
| **Mobile App (Flutter)** | **R1 App Remake (S78):** 33 role-based screens, design system (8 widgets), AppShell with role switching. **E3c (S80):** ai_service.dart + z_chat_sheet.dart + ai_photo_analyzer.dart, Z FAB in AppShell. **E5f (S79):** Estimate entry screens. **E6b (S79):** 12 walkthrough screens + 4 annotation files + 4 sketch editor files. ALL core business wired. ALL 18 field tools wired. D2 Insurance: 3 screens. D5f Properties: 10 screens. **Tech App (S119-S120):** Real job list, contact+directions, timesheet, schedule, walkthrough, role override. **Inspector App (S121-S124, Phase INS COMPLETE):** 5 screens rewritten to premium pattern. InspectionService + providers. **INS1-INS10 all done:** 19 inspection types + Quick Checklist mode, template-driven checklists (25 templates, 1,147 items, 173 sections), weighted scoring, deficiency tracking with photo proof, PDF report generation, GPS location capture, reinspection diffs, code reference (61 sections: NEC/IBC/IRC/OSHA/NFPA), compliance calendar, permit inspection tracker, tools screen fully wired, code ref search sheet, Hive offline safety net (ChecklistCacheService + HiveCacheMixin + OfflineBanner). `dart analyze` passes 0 errors. |
| **Web CRM (Next.js)** | **126 routes built.** 79 hook files + 27 Dashboard files. Auth+middleware DONE. UI Polish DONE. **F-phase (S90):** 30+ hooks + pages for phone, fax, meetings, team-chat, inspection-engine, osha-standards, fleet, payroll, hr, email, marketplace, hiring, zdocs. **T-phase (S104):** TPA hooks + pages. **P-phase (S105):** use-property-scan + use-area-scan + use-storm-assess hooks. Recon pages. **INS8 (S122):** use-inspection-templates hook, inspection templates page, inspection detail page ([id]). All wired to Supabase via real-time hooks. `npm run build` passes (0 errors). |
| **Client Portal (Next.js)** | **38 routes. 18+ hooks.** Magic link auth. **F7 (S90):** Home Portal — use-home hook + my-home/equipment/service-history/maintenance pages. **F1 (S90):** SMS messaging page. **F3 (S90):** Meetings + booking pages. **F-expansion (S90):** Documents, Get Quotes, Find a Pro pages. `npm run build` passes (38 routes, 0 errors). `client.zafto.cloud`. |
| **Employee Field Portal (Next.js)** | **36 routes. 21+ hooks. PWA-ready.** `team.zafto.cloud`. **F1 (S90):** Phone page. **F3 (S90):** Meetings page. **F5 (S90):** Pay stubs, my vehicle, training, my documents pages + MY STUFF sidebar section. **INS8 (S122):** Inspector inspections page (upcoming/history, stats, pass rate). `npm run build` passes (36 routes, 0 errors). |
| **Ops Portal (Next.js)** | **29 dashboard routes. `npm run build` passes (0 errors).** `ops.zafto.cloud`. Deep navy/teal theme. super_admin role gate. **F1/F3 (S90):** Phone analytics + meeting analytics pages. **F5-F9 (S90):** Payroll/fleet/hiring/email/marketplace analytics pages + PLATFORM sidebar section. **T-phase (S104):** TPA analytics page. **P-phase (S105):** API costs dashboard (/dashboard/api-costs). **INS8 (S122):** Inspector metrics page (platform-wide analytics, deficiencies by severity). |
| **Field Tools** | **19 total. ALL wired.** 14 original (B2a-d) + 2 new (B3a: Materials+DailyLog) + 3 new (B3b: PunchList+ChangeOrders+JobCompletion). 0 remaining. |
| **Database** | Supabase (PostgreSQL). 2 projects (dev + prod). **~212 tables** across 112 migration files. Phases A-D: 102 tables. F-phase + FM: +71 tables. T-phase: +17 tables. P-phase: +11 tables (property_scans, roof_measurements, roof_facets, property_features, property_structures, parcel_boundaries, wall_measurements, trade_bid_data, property_lead_scores, area_scans, scan_history) + 4 config tables (company_feature_flags, scan_cache, api_cost_log, api_rate_limits). RLS + audit on all. Supabase CLI linked to dev. Seed data: 55 COA accounts, 26 tax categories, 77 Xactimate codes, 76 TPA document types, 50 restoration line items. |
| **Edge Functions** | **94 directories total.** Pre-F (32). F-phase + FM (21). **T-phase (3):** tpa-documentation-validator, tpa-financial-rollup, restoration-export. **P-phase (7):** recon-property-lookup, recon-roof-calculator, recon-trade-estimator, recon-lead-score, recon-area-scan, recon-material-order (GATED behind UNWRANGLE_API_KEY), recon-storm-assess. **_shared (5):** cors.ts, rate-limiter.ts, lead-scoring.ts, api-cost-logger.ts, api-rate-guard.ts *(P-FIX1 S142: +3 shared modules)*. **GC-phase (8):** schedule-calculate-cpm, schedule-level-resources, schedule-baseline-capture, schedule-import, schedule-export, schedule-clean-locks, schedule-sync-progress, schedule-reminders. **U-phase (2):** export-bid-pdf, export-invoice-pdf. **5 in E4 dirs (uncommitted):** ai-revenue-insights, ai-customer-insights, ai-bid-optimizer, ai-equipment-insights, ai-growth-actions. **Phone (F1):** signalwire-voice, signalwire-sms, signalwire-fax, signalwire-ai-receptionist, signalwire-webhook. |
| **Backend Connected** | Auth + Customers + Jobs + Invoices + Bids + Time Clock + Calendar ALL wired. ALL 18 field tools wired. D2 Insurance: 7 tables. D4 Ledger: GL engine + 15 tables. D5 PM: 18 tables. E1 AI: z_threads + z_messages. E5 Xactimate: 5 tables. E6 Walkthrough: 5 tables. |
| **DevOps** | **C1 DONE (S58):** Sentry in all 4 apps. CI/CD: 4 workflows. 154 model tests. **C2 NEAR COMPLETE (S60-S61):** RBAC middleware on all portals. **C3 DONE (S59):** Ops Portal. **C5 DONE (S59):** Incident response. **Codemagic (S91):** Android debug build PASSING (95 MB .aab). iOS needs code signing. Bundle ID: app.zafto.mobile. **Dependabot (S91):** 0 vulnerabilities. |
| **Blocker** | **Phase E PAUSED.** AI goes last — after G. **Phases A-F + T + P + SK + GC + U + W + J + L ALL COMPLETE. Phase G automated done (G1-G5), manual QA pending (G6-G10), then Phase E (AI: E-review → BA1-BA8 Plan Review ~128 hrs → E1-E4) → LAUNCH.** Plan Review needs RunPod account + GPU endpoint setup at BA2 time. Firebase migration manual steps pending (secrets, deploy, webhook URLs). Sentry DSN empty. External API integrations pending (Gusto, Checkr, DocuSign, Samsara). ~18 F-phase migrations need `npx supabase db push` deployment. iOS Codemagic needs Apple code signing. Android release keystore not created. Programs: IP attorney opinion letter needed before shipping ESX export (deferred to revenue stage). Recon: Google Solar API key + ATTOM API key + Regrid API key needed. Sketch Engine: Apple Developer account needed for RoomPlan testing on LiDAR devices. **🚨 PITR ($100/mo) = LAUNCH BLOCKER — Enable before go-live. Without it: lose 24hr of customer data on failure. With it: lose only 2min. Owner directive S137: "remind me 100 times." Enable in Supabase Dashboard → Database → Backups → PITR.** |
| **API Keys Stored** | **Supabase Secrets:** UNWRANGLE_API_KEY (supplier pricing), PLAID_CLIENT_ID + PLAID_SECRET (bank feeds, sandbox), GOOGLE_CLOUD_API_KEY (maps+calendar, $300 credit), SIGNALWIRE_* (VoIP/SMS/Fax — space URL + project ID + API token), LIVEKIT_* (video — URL + API key + secret). **Env files:** Mapbox (maps), SignalWire (all portals), LiveKit (all portals). **Firebase secrets (need migration to Supabase):** STRIPE_SECRET_KEY + STRIPE_WEBHOOK_SECRET (full payment integration in `backend/functions/index.js`), ANTHROPIC_API_KEY (AI). **RevenueCat:** webhook handler built (`revenueCatWebhook` in `backend/functions/`), uses header signature verification. **Sentry:** SDK wired in all apps, DSN is EMPTY — needs DSN from Sentry dashboard. **Stripe in source code:** `company.dart` has `stripeCustomerId`, `types/index.ts` has `stripeAccountId`, ops-portal references Stripe in revenue/subscriptions/directory pages. Pending: DocuSign, Indeed, Checkr, LinkedIn. |
| **Calculator Gap** | **~1,194 trade calculators have NO save functionality (S116).** Results are transient. Infrastructure half-built but 0% wired: `ZaftoSaveToJobButton` widget, `SavedCalculation` model (Hive), `CalculationHistoryService`, history screen — all exist but unused. Old infra uses Firestore (not Supabase). Need: Supabase table + migrate save infra + wire into all calc screens + optional job_id linkage. Domain calcs (TPA equipment, Recon roof, SK rooms) already save correctly. |
| **Security Policy** | ZAFTO_Information_Security_Policy.docx CREATED — 13 sections, enterprise-grade. WebAuthn/passkeys/biometrics documented. Reusable for all API applications. |

---

## ACCOUNTS STATUS

| Account | Status | Email |
|---------|--------|-------|
| MS 365 Business Basic | ACTIVE (5 emails on zafto.app) | admin/robert/support/legal/info@zafto.app |
| Supabase | ACTIVE — **PRO PLAN** (2 projects: dev + prod) | admin@zafto.app |
| Sentry | ACTIVE (free tier) | admin@zafto.app |
| Stripe | ACTIVE | needs migration to admin@zafto.app |
| GitHub | ACTIVE (TeredaDeveloper) | needs migration to admin@zafto.app |
| Apple Developer | ACTIVE | needs migration to admin@zafto.app |
| Anthropic | ACTIVE | needs migration to admin@zafto.app |
| Cloudflare | ACTIVE | needs migration to admin@zafto.app |
| RevenueCat | ACTIVE | admin@zafto.app |
| Bitwarden | ACTIVE | needs migration to admin@zafto.app |
| Codemagic | ACTIVE (Android debug PASSING) | admin@zafto.app |
| Google Play | **ACTIVE** (fully approved, owner confirmed S138) | admin@zafto.app |
| ProtonMail | NOT CREATED (break-glass recovery — do before launch) | — |
| YubiKeys | NOT PURCHASED (do before launch) | — |

**Security hardening (email migration + password changeover + 2FA) — do before launch, not blocking build.**

**🚨 PITR (Point-in-Time Recovery) — $100/mo — ABSOLUTE LAUNCH BLOCKER. Enable BEFORE first real user. Supabase Dashboard → Database → Backups → PITR. Without it: 24hr data loss window. With it: 2min data loss window. Owner directive S137.**

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
| 35 | T: Programs Module | ~80 | **COMPLETE** — 12-14 tables, 3 EFs, 4 CRM pages, 5 hooks. TPA programs, assignments, scorecards, supplements, water damage, equipment, financials, restoration line items. Expansion/39_TPA_MODULE_SPEC.md |
| 36 | P: Recon / Property Intelligence Engine | ~96 | **COMPLETE** — 14-15 tables, 7 EFs, 5 CRM pages, 2+ hooks. Property scans, roof measurements, lead scoring, area scans, storm assessment, trade estimation. Google Solar + ATTOM + Regrid APIs. Expansion/40_PROPERTY_INTELLIGENCE_SPEC.md |
| 37 | SK: CAD-Grade Sketch Engine | ~240 | **EXPANDED (S101)** — 6 tables (was 3), ~46+ files, 14 sprints (SK1-SK14). LiDAR scan, trade layers, Konva web editor, auto-estimate, export, 3D view + **S101: multi-floor support, version history snapshots, photo pin placement, SVG export, team/client portal viewers** + site plan mode (SK12), trade-specific measurements/templates (SK13), field UX/ARCore/multi-user (SK14). $0/mo API costs confirmed. MagicPlan comparison in `memory/sketch-engine-deep-research-s101.md`. Expansion/46_SKETCH_ENGINE_SPEC.md |
| 37a | GC: Gantt & CPM Scheduling Engine | ~124 | **COMPLETE (S110)** — 12 tables, 8 EFs, 11 sprints (GC1-GC11). Full CPM, resource leveling, P6/MS Project import/export, real-time collab, portfolio view, mini-Gantt widgets, EVM cost tracking, team/client/ops portal views. Expansion/48_GANTT_CPM_SCHEDULER_SPEC.md |
| 38 | U: Unification & Feature Completion | ~432 | **COMPLETE (S114)** — U1-U23 all done. Nav redesign, permission engine, ledger, dashboard, PDF+Email, payments, shell pages, Stripe Connect, system health, all dead buttons wired. |
| 39 | G: Debug, QA & Hardening | ~100-200 | **IN PROGRESS** — G1-G5 automated QA done (S113). G10 done (S114-S115). G6-G9 manual QA pending. S115: Fixed 10 migrations, RLS fix, Sketch Engine rename, UI overhaul. |
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
| `01_MASTER_BUILD_PLAN.md` | COMPLETE (updated S133 — 610→866 lines, all new phases added) |
| `02_CIRCUIT_BLUEPRINT.md` | COMPLETE — updated S91 (Codemagic CI/CD, Dependabot) |
| `03_LIVE_STATUS.md` | COMPLETE (this file — updated S133) |
| `04_EXPANSION_SPECS.md` | COMPLETE (Session 36 — all 14 specs consolidated) |
| `05_EXECUTION_PLAYBOOK.md` | COMPLETE (Session 37 — session protocol, methodology, quality gates) |
| `06_ARCHITECTURE_PATTERNS.md` | COMPLETE (Session 37 — 14 code patterns with full examples) |
| `07_SPRINT_SPECS.md` | COMPLETE — **~37,700 lines**, ~275+ sprints. Phases A through L + E5 fully detailed. **S146: RE21-RE30 audit + 135 fixes (all severity levels). Pass 1: RLS, timestamps, missing columns, FK reorder, client portal. Pass 2: CORS, 4-state, hooks, rate limits, indexes, JSONB schemas, validation. S145: RE21-RE30 expansion. S144: contractor expansion + RE1-RE20 + CUST9.** Total: ~5,006h+. |
| `Expansion/53_REALTOR_PLATFORM_SPEC.md` | CREATED S129 — Full Zafto Realtor Platform spec. 20 sprints (RE1-RE20), ~594h (expanded S144). 3 flagship engines, RBAC, commission, dispatch, CRM, cross-platform sharing. Supersedes REALTOR1-3. **S144: RE1-RE20 fully spec'd with enterprise checklists (was 1-line stubs). Guest contractor flow. High-gloss near-black UI.** |
| `Expansion/52_SYSTEM_INTEGRATION_MAP.md` | CREATED S103, **UPDATED S132** — Master wiring document. Connectivity matrix, integration checklist, wiring tracker. **S132: Added INTEG2-8 pending rows, 10 critical ecosystem failures table, RE/FLIP/CLIENT/VIZ placeholder sections.** MUST be referenced every sprint. |

---

CLAUDE: UPDATE THIS FILE AT END OF EVERY SESSION.
