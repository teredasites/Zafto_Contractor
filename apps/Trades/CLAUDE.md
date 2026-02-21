# ZAFTO — Claude Code Instructions

## What Is This
Complete business-in-a-box for trades contractors. "Stripe for blue-collar." One subscription replaces 12+ tools. Multi-trade platform. Owner: Damian Tereda — Tereda Software LLC.

## Stack
- **Mobile**: Flutter/Dart, Riverpod state management, PowerSync offline-first (planned)
- **Web CRM**: Next.js 15, React 19, TypeScript, Tailwind CSS — `web-portal/` (120 routes)
- **Team Portal**: Next.js 15 — `team-portal/` (44 routes) — field employee PWA at team.zafto.cloud
- **Client Portal**: Next.js 15 — `client-portal/` (45 routes) — homeowner portal at client.zafto.cloud
- **Ops Portal**: Next.js 15 — `ops-portal/` (31 routes) — founder dashboard at ops.zafto.cloud
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Realtime + Edge Functions). Firebase fully removed S151.
- **Hosting**: Vercel Pro (all 4 Next.js apps), Cloudflare DNS
- **CI/CD**: Codemagic (Flutter), GitHub Actions
- **Icons**: Lucide only. No emojis anywhere.
- **Typography**: Inter
- **Git**: github.com/teredasites/Zafto_Contractor.git — push ONLY to TeredaDeveloper repos

## Directory Map
```
├── lib/                    # Flutter app
│   ├── core/               # env.dart, supabase_client.dart, errors.dart
│   ├── models/             # Dart models (103 Supabase models)
│   ├── repositories/       # 64 repos (PowerSync/Supabase)
│   ├── providers/          # Riverpod providers
│   ├── screens/            # 1,523 Flutter screen files
│   │   ├── estimates/      # D8 estimate engine (5 screens)
│   │   ├── properties/     # D5 property mgmt (10 screens)
│   │   ├── walkthrough/    # E6 walkthrough (12 screens)
│   │   └── zbooks/         # D4 accounting (3 screens)
│   └── widgets/            # Shared widgets (LoadingState, EmptyState, ErrorState)
├── web-portal/             # CRM (Next.js) — zafto.cloud
│   └── src/lib/hooks/      # 110 use-*.ts hook files + 2 mappers
├── team-portal/            # Employee portal (Next.js) — team.zafto.cloud
│   └── src/lib/hooks/      # 29 hook files + 1 mapper
├── client-portal/          # Client portal (Next.js) — client.zafto.cloud
│   └── src/lib/hooks/      # 26 hook files + 2 mappers
├── ops-portal/             # Founder ops (Next.js) — ops.zafto.cloud
├── supabase/
│   ├── functions/          # 92 Edge Functions (Deno/TypeScript)
│   └── migrations/         # 115 migration files
├── Build Documentation/    # DO NOT DELETE — full build docs
│   └── ZAFTO FULL BUILD DOC/
│       ├── 00_HANDOFF.md       # Entry point — read FIRST every session
│       ├── 01_MASTER_BUILD_PLAN.md
│       ├── 02_CIRCUIT_BLUEPRINT.md
│       ├── 03_LIVE_STATUS.md
│       ├── 06_ARCHITECTURE_PATTERNS.md  # 14 code patterns — follow exactly
│       └── 07_SPRINT_SPECS.md           # Execution tracker — checklists
└── android/, ios/, web/, windows/       # Platform dirs
```

## Current State (Session 138)
- **293 tables**, 115 migrations, 92 Edge Functions, 103 models, 64 repos, 1,523 screens
- **Phases A-F ALL COMPLETE**. R1 done. FM code done. Phase E PAUSED.
- **~155 sprints spec'd**, ~2,860h in execution order (~7,700h+ total including orphaned sprints)
- **Build order**: SEC-AUDIT→P-FIX1→A11Y→LEGAL→INFRA→TEST-INFRA→COLLAB-ARCH→DEPTH→INTEG→RE→FLIP→SEC→LAUNCH→G→JUR→E→APP-DEPTH→SHIP
- **Pricing**: Solo $69.99, Team $149.99, Business $249.99. Adjuster FREE. 30-day free trial (no CC). 100-day money-back guarantee.
- **Known debt**: Firebase fully removed (S151). 69+ models missing Equatable. S138 audit: 103 findings (20 CRITICAL, 31 HIGH). SEC-AUDIT sprint addresses all critical/high security issues.
- **Enterprise methodology (S138)**: 21 Critical Rules in CLAUDE.md. Mandatory security checklist per sprint. Webhook idempotency. Feature flags. Observability. Fail-closed auth. CI enforcement of soft delete + migration safety. Depth verification gate. i18n flawlessness. App parity.

## Critical Rules — NEVER VIOLATE

1. **AI GOES LAST** — Phase E is PAUSED. Do NOT resume AI work until ALL of T+P+SK+U+G are complete.
2. **SEQUENTIAL EXECUTION** — Follow `07_SPRINT_SPECS.md` checklists in order. Never skip.
3. **CHECK OFF AS YOU GO** — Mark `[x]` in sprint specs for each completed item.
4. **VERIFY BEFORE CLAIMING DONE** — Run `dart analyze`, `npm run build` per portal. Prove it.
5. **UPDATE DOCS AT SESSION END** — Update 07_SPRINT_SPECS.md, 00_HANDOFF.md, 03_LIVE_STATUS.md.
6. **NEVER CREATE PARALLEL DOCS** — One doc set. Update in place.
7. **HANDOFF IS THE ENTRY POINT** — Start at 00_HANDOFF.md every session.
8. **NO Co-Authored-By** — Never include `Co-Authored-By: Claude` in commits.
9. **EVERY SPRINT INCLUDES SECURITY VERIFICATION** — No sprint is complete without the Security Verification checklist fully checked. Copy from `Build Documentation/SPRINT_SECURITY_TEMPLATE.md` into every new sprint. Includes: RLS per-operation policies, company_id + index + audit trigger + deleted_at on all new tables, auth + CORS + input validation + rate limiting on all new EFs, soft delete + error state + deleted_at filter on all new hooks, 4-state screens in Flutter. NO EXCEPTIONS.
10. **3-LAYER ARCHITECTURE** — UI (screens/components) NEVER imports from data layer (supabase client, repositories, models directly). UI uses ONLY providers (Flutter) or hooks (Next.js). Providers/hooks are the stable contract between UI and data. Enforced by CI lint rules.
11. **EXPAND-CONTRACT MIGRATIONS** — Never destructive in a single migration. Add new → dual-write → backfill → remove old in next sprint. CI blocks `DROP COLUMN`, `DROP TABLE`, `ALTER.*TYPE`, `RENAME COLUMN` without the pattern.
12. **FEATURE FLAGS FOR MAJOR FEATURES** — New major features MUST be gated behind `company_feature_flags`. Roll out: 5% → monitor errors → 25% → 100%. Never deploy to all users at once.
13. **WEBHOOK IDEMPOTENCY** — Every webhook handler MUST check `webhook_events` table for duplicate `event_id` before processing. If already processed, return 200 and skip. Prevents double-processing on retries.
14. **SOFT DELETE ONLY** — NEVER use `.delete()` on business data. Always `.update({ deleted_at: new Date().toISOString() })`. Always filter lists with `.is('deleted_at', null)`. Enforced by CI lint rules. The ONLY exception is junction tables (e.g., tag assignments) where physical delete is semantically correct.
15. **FAIL CLOSED ON AUTH** — If an env var for a webhook secret is missing, REJECT all requests (return 500). Never skip auth because a secret isn't configured. If auth check fails for any reason, deny access. Never fail open.
16. **SHARED TYPE SYSTEM** — After EVERY migration change, run `npm run gen-types` in web-portal (uses `supabase gen types typescript`) and copy `database.types.ts` to all 4 portals. All hooks MUST import column types from `database.types.ts`, not manual interface definitions. This is the single source of truth for TypeScript types. CI verifies types are in sync with migrations.
17. **MOBILE BACKWARD COMPATIBILITY** — New database columns that Flutter writes to MUST be nullable with defaults for at least 2 app update cycles (~4 weeks). Never add `NOT NULL` without `DEFAULT` on Flutter-writable tables. Web portals deploy instantly via Vercel; Flutter goes through app stores. Users on older versions send the old `toJson()` without new columns — causes silent failures or crashes. See `Build Documentation/FLUTTER_WRITABLE_TABLES.md` for the list.
18. **OPTIMISTIC LOCKING ON SHARED ENTITIES** — All UPDATE operations on shared business entities (customers, jobs, invoices, estimates, schedules, properties) MUST check `updated_at` in the WHERE clause: `WHERE id = $1 AND updated_at = $2`. If 0 rows affected, return conflict error. Last-write-wins is NOT acceptable for multi-user companies. Show conflict dialog in UI: "This record was modified by another user. Reload and re-apply your changes?"
19. **DEPTH VERIFICATION GATE** — After completing EVERY sprint, stop and ask: "Would a real professional in this trade use this feature on a real job site on day one? Is EVERY sub-feature complete, not just scaffolded? Does it save data, link to jobs, produce useful output?" If the answer to ANY question is NO, the sprint is NOT done. We are building a one-stop shop, not an empty shell. No feature ships at surface level. This applies to ALL entity types equally: contractor, inspector, adjuster, realtor, homeowner, preservation.
20. **i18n FLAWLESSNESS** — Language switching MUST NOT break ANY feature, cause ANY UI overflow, or produce ANY visual artifacts. Every translation must use the correct professional dialect for each language — not Google Translate, not literal translation, but how a native-speaking tradesperson in that country would actually say it. Trade-specific terminology must be verified (e.g., Spanish "tablero" not "panel", Portuguese-BR construction terms not Portugal-PT). Layout must accommodate longer strings (Spanish ~20% longer, German ~30% longer). Number/date/currency formatting must be locale-correct. RTL-ready logical properties (start/end not left/right). Missing translation = build failure in CI. Every sprint that adds UI strings MUST add translations for all 10 locales before the sprint is complete.
21. **APP PARITY** — ALL entity type experiences (contractor, inspector, adjuster, realtor, homeowner, preservation, restoration) MUST have equal depth.
22. **NEVER HALLUCINATE** — If you don't know something, say so. Never invent file paths, API endpoints, table names, feature states, or account statuses. Always verify against actual code/docs/filesystem before stating facts. If a file "should" exist, check that it does. If a service "should" be configured, verify it. Wrong information causes drift and wastes hours. When in doubt, grep/read first, answer second. The contractor app is the gold standard — every other entity type must match its depth of features, seed data, templates, calculators, and workflows. If a contractor gets 1,194 calculators, inspectors get comprehensive inspection tools, adjusters get full claims workflow, realtors get full transaction engine, homeowners get full project tracking. No second-class citizens. APP-DEPTH sprint verifies parity after all entity-specific sprints are complete.
23. **DEPTH AUDIT FINDINGS MUST BE SPECCED AND EXECUTED** — When a DEPTH audit identifies gaps (features at 0% wiring, missing integrations, unwired infrastructure, stub features, trades below minimum score), those gaps MUST be added as explicit unchecked `[ ]` correction items in `07_SPRINT_SPECS.md` under that DEPTH sprint BEFORE the sprint can be marked complete. A sprint with unresolved audit findings is NOT complete — period. The audit phase documents what's wrong; the correction phase fixes it. Both phases must finish before the sprint gets checked off. NEVER mark a DEPTH sprint done if audit findings have 0% wiring. NEVER drift to the next DEPTH sprint leaving findings unexecuted. Document the gap AND fix it in the same sprint. If a fix is genuinely too large for the current sprint, explicitly spec a follow-up sprint with its own checklist items and add a blocking dependency note. Infrastructure that exists but is unwired to 0 out of N screens counts as 0% complete, not "done because the widget exists." Wiring IS the work.

## Build & Verify Commands
```bash
# Flutter
"C:/tools/flutter/bin/flutter.bat" analyze          # 0 errors required
"C:/tools/flutter/bin/flutter.bat" test              # Run tests
"C:/tools/flutter/bin/flutter.bat" build apk --debug # Android debug

# Web CRM
cd web-portal && npm run build      # Must pass with 0 errors

# Team Portal
cd team-portal && npm run build

# Client Portal
cd client-portal && npm run build

# Ops Portal
cd ops-portal && npm run build

# Supabase
npx supabase functions deploy <name>   # Deploy single EF
npx supabase db push                   # Push migrations
```

## Code Patterns (from 06_ARCHITECTURE_PATTERNS.md)

### Dart Models
- One model per file in `lib/models/`, immutable (`final` fields, `const` constructor)
- `toJson()` uses `snake_case` keys matching Supabase columns
- `fromJson()` reads `snake_case` from Supabase. Dart fields are `camelCase`
- Always include: `copyWith()`, `Equatable`, computed getters

### Dart Repositories
- One repo per table in `lib/repositories/`
- Abstract interface + concrete implementation
- Returns domain models, not raw maps. Throws typed errors from `core/errors.dart`

### Riverpod Providers
- Repository = `Provider` (singleton). Data = `StreamProvider`/`AsyncNotifierProvider` (reactive)
- `autoDispose` for screen-scoped. `.family` for parameterized (by ID)
- NEVER `ref.read` inside `build()` — use `ref.watch`

### Flutter Screens
- Every screen handles 4 states: loading, error, empty, data
- Use `ConsumerWidget`, `ref.watch()` for data, `ref.read()` for actions

### Next.js Hooks (Web)
- All hooks in `src/lib/hooks/use-*.ts`, client-side (`'use client'`)
- Supabase client via `createClient()` from `src/lib/supabase.ts`
- Real-time subscriptions on `postgres_changes` channel
- Return `{ data, loading, error, mutations... }`

### Supabase RLS
- Every table has `company_id`. RLS enabled on all. JWT `app_metadata.company_id` for scoping.
- Separate policies: SELECT, INSERT, UPDATE, DELETE
- `auth.company_id()` + `auth.user_role()` helper functions
- Audit trigger (`audit_trigger_fn`) on every business table

### Edge Functions
- Deno/TypeScript in `supabase/functions/<name>/index.ts`
- Auth via `supabase.auth.getUser()` from request Authorization header
- Always validate company_id from JWT

### General
- Soft delete everywhere (`deleted_at timestamptz`). Never physical delete business data.
- All timestamps: `timestamptz` (UTC), ISO 8601 strings, `update_updated_at()` trigger
- Commit format: `[PHASE] Description` (e.g., `[T1] TPA foundation tables`)

## Key Architecture Facts
- **RBAC roles**: owner, admin, office_manager, technician, apprentice, cpa, super_admin
- **5 apps, 1 database** — RLS handles all multi-tenancy
- **Supabase auth** — JWT with `app_metadata.company_id` and `app_metadata.role`
- **Magic link** auth for client portal, password for others
- **7 storage buckets** (all private): photos, signatures, voice-notes, receipts, documents, avatars, company-logos
- **Design**: "Stripe for Trades" — premium, clean, information-dense. CRM=dark, Client=light.
