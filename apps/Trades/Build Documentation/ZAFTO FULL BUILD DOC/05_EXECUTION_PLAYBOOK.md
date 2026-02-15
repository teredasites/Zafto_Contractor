# ZAFTO EXECUTION PLAYBOOK
## How Claude Executes — Session Protocol, Decision Rules, Quality Gates
### Created: February 6, 2026 (Session 37)

---

## PURPOSE

This document is the OPERATING SYSTEM for building ZAFTO. Every Claude session reads this to know:
1. What to do first
2. How to pick up work
3. How to execute a sprint
4. How to verify quality
5. How to hand off to the next session

**This + `06_ARCHITECTURE_PATTERNS.md` + `07_SPRINT_SPECS.md` = everything needed to build autonomously.**

---

## SESSION PROTOCOL

### Session Start (Do This Every Time)

```
1. Read 00_HANDOFF.md (what happened last, what's next)
2. Read 03_LIVE_STATUS.md (quick state check)
3. Read 05_EXECUTION_PLAYBOOK.md (this file — how to work)
4. Check which sprint is NEXT in 07_SPRINT_SPECS.md
5. Read 06_ARCHITECTURE_PATTERNS.md if writing code
6. Begin work — no user input needed unless blocked
```

### Session End (Do This Every Time)

```
1. Update 03_LIVE_STATUS.md — current phase, what changed
2. Update 00_HANDOFF.md — what happened, next priorities
3. Update 07_SPRINT_SPECS.md — mark completed sprints, add findings
4. Git commit with descriptive message
5. Verify app compiles (flutter analyze / npm run build)
```

### Mid-Session Checkpoints

After completing each sprint step:
1. Run `flutter analyze` (Dart) or `npm run build` (Next.js) — MUST pass
2. Run any tests written during the sprint
3. Commit working code before moving to next step
4. Update sprint status in 07_SPRINT_SPECS.md

---

## SPRINT EXECUTION METHODOLOGY

### How to Execute a Sprint

```
PHASE 1: PREP (5 min)
├── Read the sprint spec in 07_SPRINT_SPECS.md
├── Read relevant architecture pattern in 06_ARCHITECTURE_PATTERNS.md
├── Verify prerequisites are met (previous sprints complete)
└── Identify all files that will be created/modified

PHASE 2: DATABASE (if applicable)
├── Write SQL migration file
├── Write RLS policies
├── Write audit triggers
├── Test with sample data mentally (will data flow correctly?)
└── Document any schema decisions

PHASE 3: BACKEND (models, repositories, services)
├── Create/update models (match Supabase schema exactly)
├── Create repository (Supabase + PowerSync wrapper)
├── Create/update service (business logic on top of repository)
├── Create Riverpod providers
└── Write unit tests for service logic

PHASE 4: FRONTEND (screens, widgets)
├── Update screen to use real providers (replace mock data)
├── Add loading states (AsyncValue handling)
├── Add error states (user-friendly messages)
├── Add empty states (no data yet)
├── Handle offline state (PowerSync indicator)
└── Write widget tests for critical flows

PHASE 5: VERIFY
├── flutter analyze — zero errors, zero warnings
├── Run all tests — 100% pass
├── Manual trace: does data flow end-to-end?
├── Security check: is RLS enforced? Audit trail working?
└── Commit with descriptive message
```

### Sprint Sizing

Each sprint should be completable in ONE Claude session (~2-4 hours of focused work). If a sprint is too large, split it into sub-sprints (e.g., B1a, B1b, B1c).

---

## DECISION RULES

### If Something Breaks
```
1. Do NOT move forward with broken code
2. Fix it immediately
3. Run flutter analyze again
4. If fix requires architectural change → document in 06_ARCHITECTURE_PATTERNS.md
5. If fix reveals a bug pattern → add to COMMON_BUG_PATTERNS section below
```

### If a Sprint Is Blocked
```
1. Document the blocker in 07_SPRINT_SPECS.md
2. Check if a later sprint can be done first (independent work)
3. If truly blocked → note in 00_HANDOFF.md for user
4. Never skip a sprint silently
```

### If Architecture Docs Conflict with Reality
```
1. Reality wins. Code is truth.
2. Update the docs to match reality.
3. Document WHY in the sprint spec.
```

### If I'm Unsure About a Design Decision
```
1. Choose the simpler option
2. Make it easy to change later
3. Document the decision and alternatives in sprint spec
4. Prefer: fewer tables > more tables
5. Prefer: simple RLS > complex RLS
6. Prefer: explicit code > clever abstractions
```

---

## QUALITY GATES

### Gate 1: Pre-Sprint
- [ ] Previous sprint fully complete and verified
- [ ] All prerequisite sprints are done
- [ ] App compiles cleanly (zero errors)

### Gate 2: Post-Database
- [ ] Migration SQL is valid
- [ ] RLS policies cover all CRUD operations
- [ ] Audit trigger attached
- [ ] No table allows unscoped access (every table has company_id or is a system table)

### Gate 3: Post-Backend
- [ ] Models match Supabase schema exactly
- [ ] Repository handles all CRUD + real-time subscriptions
- [ ] Service layer has business validation
- [ ] Providers properly dispose/refresh
- [ ] Unit tests pass

### Gate 4: Post-Frontend
- [ ] Screens show loading, error, empty, and data states
- [ ] No hardcoded mock data remains (except test fixtures)
- [ ] Offline behavior works (data visible without network)
- [ ] Navigation flows correctly
- [ ] Widget tests pass

### Gate 5: Pre-Commit
- [ ] `flutter analyze` — zero errors, zero warnings
- [ ] All tests pass
- [ ] No TODO:BACKEND comments remain for wired features
- [ ] No secrets/keys in committed code
- [ ] Commit message describes what changed and why

---

## COMMON BUG PREVENTION PATTERNS

### Pattern 1: Null Safety
```
RULE: Never use `!` operator unless you've verified non-null in the same scope.
INSTEAD: Use `?.`, `??`, or conditional checks.
WHY: `!` is the #1 source of runtime crashes in Flutter.
```

### Pattern 2: Race Conditions
```
RULE: All async state updates go through Riverpod notifiers, never directly.
RULE: Dispose streams and subscriptions in provider onDispose.
RULE: Check mounted/active before updating state after async gaps.
WHY: Stale state updates cause "setState after dispose" crashes.
```

### Pattern 3: Infinite Rebuilds
```
RULE: Never create objects inside build() that are used as provider parameters.
RULE: Use ref.watch() for reactive state, ref.read() for one-shot actions.
RULE: Memoize expensive computations with select().
WHY: Object identity changes cause infinite rebuild loops.
```

### Pattern 4: Offline Data Conflicts
```
RULE: PowerSync handles sync. Never manually manage sync queues.
RULE: Use server timestamps, not client timestamps, for ordering.
RULE: Conflict resolution: server wins for shared data, client wins for drafts.
WHY: Manual sync is the #1 source of data corruption in offline-first apps.
```

### Pattern 5: RLS Bypass
```
RULE: NEVER use service_role key in client code.
RULE: All client queries go through anon key with JWT.
RULE: Test RLS with two different company accounts.
WHY: One RLS bypass = full data breach.
```

### Pattern 6: Memory Leaks (Flutter)
```
RULE: Cancel all StreamSubscriptions in dispose().
RULE: Use autoDispose on Riverpod providers for screen-scoped state.
RULE: Never hold references to BuildContext across async gaps.
WHY: Memory leaks accumulate and crash the app during long field sessions.
```

### Pattern 7: Input Validation
```
RULE: Validate at the UI level (user feedback) AND at the service level (data integrity).
RULE: Never trust form data — sanitize before database insert.
RULE: Phone numbers, emails, dates — always parse and validate format.
WHY: Bad data in the database poisons everything downstream.
```

### Pattern 8: Error Boundaries
```
RULE: Every screen has a top-level error handler.
RULE: Network errors show retry button, not stack traces.
RULE: Auth errors redirect to login, not crash.
RULE: Unknown errors log to Sentry with context.
WHY: Unhandled errors kill user trust instantly.
```

---

## FILE NAMING CONVENTIONS

### Flutter (Dart)
```
lib/
├── models/           # Data models (match Supabase tables)
│   ├── job.dart     # One model per file, snake_case
│   └── models.dart  # Barrel file re-exports all
├── repositories/     # Data access layer (NEW — add during A3)
│   ├── job_repository.dart
│   └── base_repository.dart
├── services/         # Business logic
│   ├── job_service.dart
│   └── auth_service.dart
├── providers/        # Riverpod providers (NEW — add during B1)
│   ├── job_providers.dart
│   └── auth_providers.dart
├── screens/          # UI screens
│   ├── jobs/
│   │   ├── jobs_hub_screen.dart
│   │   ├── job_detail_screen.dart
│   │   └── job_create_screen.dart
│   └── field_tools/
├── widgets/          # Reusable widgets
│   ├── loading_state.dart
│   ├── error_state.dart
│   └── empty_state.dart
└── core/             # Cross-cutting (NEW — add during A3)
    ├── errors.dart   # AppError sealed class
    ├── extensions.dart
    └── constants.dart
```

### Web CRM (Next.js)
```
web-portal/src/
├── app/dashboard/    # Pages (App Router)
├── lib/              # Utilities
│   ├── supabase.ts  # Supabase client (REPLACE firebase.ts)
│   ├── types.ts     # TypeScript types matching Supabase
│   └── hooks/       # Custom React hooks
├── components/       # Shared components
└── styles/           # Tailwind config
```

### Client Portal (Next.js)
```
client-portal/src/
├── app/              # Pages (App Router)
├── lib/              # Utilities
│   ├── supabase.ts  # Supabase client
│   └── types.ts     # TypeScript types
└── components/       # Shared components
```

---

## GIT WORKFLOW

```
BRANCH: main (single branch for now — add feature branches at Phase C1)
COMMITS: After every sprint step that passes quality gates
MESSAGE FORMAT: "[Phase.Sprint] Description — what changed and why"
EXAMPLES:
  "[A3] Deploy core database schema — 14 tables, RLS, audit triggers"
  "[B1a] Wire job CRUD to Supabase — repository + providers + screens"
  "[B2] Wire field tools to backend — photos, signatures, voice notes persist"
```

---

## TESTING STRATEGY

### Unit Tests (run every sprint)
- Model serialization/deserialization
- Service business logic (validation, calculations)
- Provider state transitions

### Integration Tests (run every phase)
- Auth flow (register → login → access → logout)
- Job lifecycle (create → assign → start → complete → invoice)
- Offline sync (create offline → reconnect → verify sync)

### RLS Tests (run after every schema change)
- Company A cannot see Company B's data
- Role X cannot perform action Y
- Audit log captures all mutations

### Performance Tests (Phase G)
- Query performance with 10K+ rows
- App startup time
- Screen load time
- Sync performance with large datasets

---

## ARCHITECTURE DECISION LOG

| # | Decision | Rationale | Date |
|---|----------|-----------|------|
| 1 | Supabase over Firebase | PostgreSQL RLS, offline-first via PowerSync, no vendor lock-in | Session 29 |
| 2 | PowerSync for offline | Only production-ready SQLite<->PostgreSQL sync. Replaces Firestore offline. | Session 29 |
| 3 | Riverpod for state | Already in codebase. AsyncNotifier perfect for Supabase streams. | Session 35 |
| 4 | Repository pattern | Decouples data access from business logic. Makes testing and migration easy. | Session 37 |
| 5 | Flat tables with company_id | PostgreSQL RLS auto-filters. No nested collections needed. | Session 29 |
| 6 | JSONB for flexible fields | Insurance/warranty data varies per vertical. JSONB avoids table sprawl. | Session 36 |
| 7 | Audit trail on every table | Enterprise compliance. Immutable append-only log. | Session 30 |
| 8 | Edge Functions over Cloud Functions | Supabase-native. Deno runtime. No Firebase dependency. | Session 29 |
| 9 | Models use toJson/fromJson | Matches Supabase response format. Business models will be unified to root models during B1. | Session 37 |
| 10 | Progressive disclosure | Show only what's needed. Insurance/warranty fields hidden until enabled. | Session 36 |

---

## EMERGENCY PROCEDURES

### If the App Won't Compile
```
1. git stash (save current changes)
2. git checkout -- . (restore last working state)
3. flutter clean && flutter pub get
4. Identify what broke by applying changes one file at a time
5. Fix the issue
6. git stash pop (re-apply changes)
```

### If Supabase Is Down
```
1. Work on frontend-only changes
2. PowerSync should handle offline gracefully
3. Do NOT modify database schema while Supabase is unreachable
```

### If Tests Fail Unexpectedly
```
1. Run the specific failing test in isolation
2. Check if it's a test environment issue (missing setup)
3. Check if a recent change broke an assumption
4. Fix the code (not the test) unless the test is wrong
```

---

CLAUDE: Read this at the start of every session. It's your operating manual.
