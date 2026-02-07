# ZAFTO MASTER BUILD PLAN — NO DRIFT
## Single Source of Truth — Every Feature, Every Phase, Every Decision
### Last Updated: February 7, 2026 (Session 80)

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
| Z mark | Reserved for AI/premium features: Z Intelligence, ZBooks, Z Console |
| CRM accent | Per Design System v2.6 |
| Client Portal accent | Stripe purple `#635bff` |
| Ops Portal accent | Deep navy/teal (distinct from both) |
| Icons | Lucide only. No emojis anywhere. |
| Typography | Inter. Clean, readable, professional. |
| Inspiration | Linear (keyboard-first), Stripe (density), Vercel (data viz), Apple (detail) |

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
    │  Telnyx    SendGrid      Plaid         RevenueCat│
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
- `team.zafto.app` — Employee Field Portal (techs, apprentices, field crews)
- `zafto.cloud` — Contractor CRM (owner, admin, office manager)
- `client.zafto.cloud` — Client/Homeowner Portal
- `ops.zafto.cloud` — Founder OS (internal, super_admin)

---

## CURRENT STATE (February 7, 2026 — Session 80)

| What | Built | Wired | End-to-End |
|------|:-----:|:-----:|:----------:|
| Mobile App (R1 remake — 33 role screens) | YES | YES | YES (Supabase) |
| Mobile Field Tools (19 total) | YES | YES (B2+B3) | YES (all 19 wired) |
| Web CRM (71 routes) | YES | YES (39+ hooks) | YES (Supabase) |
| Client Portal (29 routes) | YES | YES (11 hooks) | YES (Supabase) |
| Employee Field Portal (25 routes) | YES | YES (14 hooks) | YES (Supabase) |
| Ops Portal Phase 1 (17 routes) | YES | YES | YES (Supabase) |
| Database (Supabase) | 92 tables deployed to dev | RLS + audit on all | 28 migrations |
| Edge Functions | 26 deployed | All active | Needs ANTHROPIC_API_KEY |
| RBAC | Enforced | Middleware on all portals | RLS per table |
| ZBooks (QB replacement) | YES | YES (13 hooks, 13 pages, 5 EFs) | YES |
| Property Management | YES | YES (11 hooks, 14 pages, 10 Flutter screens) | YES |
| Insurance/Restoration | YES | YES (7 tables, all 5 apps) | YES |
| **Phase E AI (PREMATURE)** | **YES (code exists)** | **PAUSED** | **NOT TESTED — AI goes LAST** |
| **Phase F Platform** | **NOT STARTED** | **NO** | **NEXT** |

**Phases A-D ALL COMPLETE. R1 App Remake COMPLETE. Phase E AI was started prematurely (S78-S80) — code exists but is PAUSED. Correct next step: Phase F (Platform Completion), then G (QA), then E (AI layer built LAST with full platform knowledge).**

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
| B5 | Wire W5: Employee Field Portal | ~20-25 | team.zafto.app — jobs, schedule, time clock, field tools, materials, change orders, AI troubleshooting. Permission-gated by owner. No sensitive financials. |
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
| D4 | ZBooks (QB replacement) | TBD | Full accounting: chart of accounts, receipt scan, P&L, bank sync (Plaid), CPA portal |
| D5 | Property Management System | TBD | NEW — Contractor-owned properties. Tenant mgmt, leases, rent, maintenance loop. THE MOAT. |

### PHASE E: AI LAYER — MOVED TO AFTER PHASE F + G (AI GOES TRULY LAST)

**STATUS: PAUSED.** Some E work was built prematurely in S78-S80 (Edge Functions, hooks, UI). Code committed but DORMANT. AI must be built LAST after every platform feature exists so it can know and control the entire system. Deep AI spec session required before resuming.

**Premature E work (exists in codebase, dormant):**
- E1-E2: z-intelligence Edge Function (14 tools), Z Console wired, z_threads/z_messages tables
- E3: 4 troubleshooting Edge Functions, team portal troubleshoot page, Flutter AI chat, client portal widget
- E4: 5 growth advisor Edge Functions, 4 CRM pages (not deployed)
- E5: Xactimate estimate engine (5 tables, 6 Edge Functions, UI across all apps)
- E6: Bid walkthrough engine (5 tables, 4 Edge Functions, 12 Flutter screens)

**When we return to Phase E (after F+G):**

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| E1 | Universal AI Architecture | ~300-400 | 6-layer AI: Identity, Knowledge, Memory, Session, Compounding, RBAC. Must understand EVERY feature. Deep spec session first. |
| E2 | Z Console + Artifacts | ~90-120 | 3-state persistent AI console. Template-based artifacts. Human approval required. |
| E3 | Unified Command Center | ~100-150 | Lead inbox, pipeline, service catalog, showcases, reviews |
| E4 | Growth Advisor | ~88 | AI revenue expansion engine. Curated opportunity KB. |
| E-review | Audit premature E work | TBD | Review/rebuild all S78-S80 AI code with full platform context. Ensure AI knows every F-phase feature. |

### PHASE F: PLATFORM COMPLETION

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| F1 | Phone System (Telnyx VoIP) | ~35-50 | Business phone, AI receptionist, SMS, call recording, E2E encryption |
| F2 | Website Builder V2 | ~60-90 | Cloudflare Registrar, templates, AI content, $19.99/mo |
| F3 | Meeting Room System | ~70 | LiveKit video, 6 meeting types, AI transcription, scheduling |
| F4 | Mobile Field Toolkit | ~89-107 | 25 tools: walkie-talkie/PTT, inspections, restoration tools |
| F5 | Business OS Expansion | ~180 | CPA Portal, Payroll, Fleet, Route, Procurement, HR, Docs |
| F6 | Marketplace | ~80-120 | AI equipment diagnostics, lead gen, contractor bidding |
| F7 | ZAFTO Home Platform | ~140-180 | Homeowner property intelligence, free + premium ($7.99/mo) |
| F8 | Ops Portal Phases 2-4 | ~111 | Marketing engine, treasury, legal, dev terminal, analytics |
| F9 | Hiring System | ~18-22 | Multi-channel job posting, applicant pipeline |
| F10 | ZDocs + ZSheets | TBD | PDF-first document suite. BUILD LAST after all features locked. |

### PHASE G: DEBUG, QA & HARDENING

| # | Task | Hours | Details |
|---|------|:-----:|---------|
| G1 | Full platform debug | ~100-150 | Every screen, every edge case, every role, real data |
| G2 | Security audit | ~20-30 | Pen testing, RLS verification, credential rotation |
| G3 | Performance optimization | ~20-30 | Load testing, query optimization, caching |
| G4 | Security hardening | ~4 | Email migration, Bitwarden changeover, 2FA, YubiKeys |

### >>> LAUNCH <<<

---

## FEATURE INVENTORY — EVERY FEATURE ACCOUNTED FOR

### Mobile App Features
| Feature | Status | Phase |
|---------|--------|-------|
| Home Dashboard | UI only, mock data | B1 |
| Bids (list/detail/create) | UI only, Hive local | B1 |
| Jobs (list/detail/create) | UI only, Hive local | B1 |
| Invoices (list/detail/create) | UI only, Hive local | B1 |
| Customers (list/detail) | UI only, Hive local | B1 |
| Calendar | UI only, mock data | B1 |
| Time Clock + GPS | UI only, local state | B1 |
| RBAC (role.dart models) | Models exist, not enforced | B1 |
| Onboarding | UI only, no company creation | B1 |
| Command Palette (Cmd+K) | Only searches old registry | B6 |
| AI Chat | Works (Cloud Function) | E1 |
| AI Scanner (5 functions) | Works (Cloud Functions) | E1 |
| Contract Analyzer | Works (Cloud Function) | E1 |

### Field Tools (14) — ALL UI SHELLS
| # | Tool | Status | Phase |
|---|------|--------|-------|
| 1 | Job Site Photos | UI only, data evaporates | B2 |
| 2 | Before/After | UI only, data evaporates | B2 |
| 3 | Defect Markup | UI only, data evaporates | B2 |
| 4 | Voice Notes | UI only, fake playback | B2 |
| 5 | Mileage Tracker | UI only, data evaporates | B2 |
| 6 | LOTO Logger | UI only, no save | B2 |
| 7 | Incident Report | UI only, fake submit | B2 |
| 8 | Safety Briefing | UI only, no records | B2 |
| 9 | Sun Position | Standalone utility (OK) | — |
| 10 | Dead Man Switch | **SAFETY CRITICAL — cannot alert anyone** | B2 |
| 11 | Confined Space Timer | UI only, no OSHA logging | B2 |
| 12 | Client Signature | UI only, fake save | B2 |
| 13 | Receipt Scanner | UI only, fake OCR | B2 |
| 14 | Level & Plumb | UI only, no save | B2 |

### Missing Tools (Build from scratch)
| Tool | Purpose | Phase |
|------|---------|-------|
| Materials/Equipment Tracker | Log what was installed | B3 |
| Daily Job Log | Task-level documentation | B3 |
| Punch List / Task Checklist | Multi-task job tracking | B3 |
| Change Order Capture | Scope change documentation | B3 |
| Job Completion Workflow | Required steps before closing | B3 |

### Web CRM (40 pages) — ALL MOCK DATA
| Group | Pages | Phase |
|-------|:-----:|-------|
| Operations (Dashboard, Leads, Bids x3, Jobs x3, Change Orders, Invoices x3) | 12 | B4 |
| Scheduling (Calendar, Inspections, Permits, Time Clock) | 4 | B4 |
| Customers (Customers x3, Comms, Service Agreements, Warranties) | 6 | B4 |
| Resources (Team, Equipment, Inventory, Vendors, Purchase Orders) | 5 | B4 |
| Office (ZBooks, Price Book, Documents, Reports, Automations) | 5 | B4/D4 |
| Z Intelligence (AI, Voice, Bid Brain, Job Cost Radar, Equip Memory, Revenue Autopilot) | 6 | E1 |
| Settings + Auth | 2 | B4 |

### Client Portal (21 pages) — ALL MOCK DATA
| Tab | Pages | Phase |
|-----|:-----:|-------|
| Auth + Home | 2 | B6 |
| Projects (List, Detail, Estimate, Agreement, Live Tracker) | 5 | B6 |
| Payments (Invoices, Detail, History, Methods) | 4 | B6 |
| My Home (Profile, Equipment List, Equipment Detail) | 3 | B6 |
| Menu (Messages, Documents, Request Service, Referrals, Review Builder, Settings) | 6 | B6 |

### Employee Field Portal (team.zafto.app) — NOT BUILT
| Group | Pages | Phase |
|-------|:-----:|-------|
| Auth + Dashboard (login, home, schedule view) | 3 | B5 |
| Jobs (assigned jobs, job detail, time clock, GPS check-in) | 4 | B5 |
| Field Tools (photos, voice notes, signatures, receipts, level — web versions) | 5 | B5 |
| Documents (change orders, daily logs, punch lists, materials log) | 4 | B5 |
| AI Troubleshooting Center (multi-trade diagnostics, code lookup, photo diagnosis, step-by-step repair guides, parts ID) | 3 | E1 |
| Collaboration (meeting rooms, team chat, notifications) | 3 | B5/F3 |
| Bids (field bid creation, AI bid assist, estimate builder) | 2 | B5/E1 |
| Settings (profile, preferences, notification settings) | 1 | B5 |

### Ops Portal (72 pages) — SPEC ONLY
| Section | Pages | Phase |
|---------|:-----:|-------|
| Command Center, Inbox, Accounts, Support, Health, Revenue, Services, AI | 18 | C3 |
| Marketing Engine, Growth CRM, Treasury, AI Sandbox | 23 | F8 |
| Legal, Dev Terminal, Ads, SEO, Vault, Referrals, Analytics | 23 | F8 |
| Marketplace Ops | 8 | F8 |

### Expansion Features — EVERY ONE ACCOUNTED FOR
| Feature | Source | Hours | Phase |
|---------|--------|:-----:|-------|
| Job Type System (3 types) | Locked/37 | ~69 | D1 |
| Restoration/Insurance Module | Locked/36 | ~78 | D2 |
| Insurance Verticals (4) | Expansion/38 | ~107 | D3 |
| ZBooks (full accounting, QB replacement) | Expansion/16 App G-J | TBD | D4 |
| **Property Management System** | **NEW** | **TBD** | **D5** |
| Universal AI Architecture (6 layers) | Expansion/35 | TBD | E1 |
| Z Console + Artifacts | Expansion/41 | TBD | E2 |
| Unified Command Center (7 concepts) | Expansion/40 | TBD | E3 |
| Growth Advisor | Expansion/39 | ~88 | E4 |
| Phone System (Telnyx VoIP) | Expansion/31 | TBD | F1 |
| Website Builder V2 | Expansion/28 | TBD | F2 |
| Meeting Room System | Expansion/42 | ~55-70 | F3 |
| Mobile Field Toolkit (25 tools) | Expansion/43 | ~89-107 | F4 |
| Business OS Expansion (9 systems) | Expansion/27 | TBD | F5 |
| Marketplace | Expansion/33 | TBD | F6 |
| ZAFTO Home Platform | Expansion/16 | TBD | F7 |
| Ops Portal Phases 2-4 | Locked/34 | ~111 | F8 |
| Multi-Channel Hiring System | Expansion/28 | ~18-22 | F9 |
| ZDocs + ZSheets (PDF-first) | Master Plan | TBD | F10 |

---

## EMPLOYEE FIELD PORTAL (team.zafto.app)

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
| Meeting Rooms | Join team meetings, safety briefings, training sessions |
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
- Meeting room access
- Customer contact info visibility

### Tech Stack
- Next.js 15, React 19, TypeScript, Tailwind CSS
- Same Supabase backend as all other portals
- RLS scopes all queries to `company_id` + role permissions
- PWA-capable (installable on phone home screen)

### Codebase Path
`apps/Trades/team-portal/`

---

## PROPERTY MANAGEMENT SYSTEM (NEW — Spec needed)

### The Moat
Most property management software (AppFolio, Buildium, TenantCloud) is built for property managers who HIRE contractors. ZAFTO is built for contractors who ARE the property owner. The maintenance loop closes internally:

**Tenant submits maintenance request → becomes a job in ZAFTO → contractor assigns to crew or does it themselves → no middleman, no external platform.**

### Core Features (to be spec'd)
- Tenant management (lease terms, contact info, payment history)
- Lease tracking (start/end dates, renewal alerts, rent increases)
- Rent collection (Stripe, auto-charge, late fees, receipts)
- Maintenance requests → auto-create ZAFTO jobs
- Property financials (income/expenses per property, NOI, cap rate)
- Vacancy tracking + listing
- Tenant screening (credit/background check integration)
- Move-in/move-out inspections (ties to field tools)
- Property inspections (ties to Mobile Field Toolkit)
- Multi-property portfolio dashboard
- Tax documents (1099 for contractors, Schedule E data for ZBooks)

### Scaling
- Solo landlord (1-5 units): Simple view, basic features
- Small portfolio (5-50 units): Full property management
- Large portfolio (50-500+ units): Multi-property analytics, team assignments, maintenance routing

### Integration with ZAFTO
- ZBooks: Rental income/expenses auto-categorize
- Phone System: Tenant communication via business line
- Website Builder: Property listing pages
- Field Tools: Inspection documentation
- Z Intelligence: Maintenance cost predictions, vacancy forecasting

**NEEDS DEDICATED SPEC SESSION. Do NOT build without full spec.**

---

## SUBSCRIPTION TIERS

| Feature | Solo | Team | Business | Enterprise |
|---------|:----:|:----:|:--------:|:----------:|
| Dashboard, Jobs, Invoices, Customers | Y | Y | Y | Y |
| PDF invoices, Price book | Y | Y | Y | Y |
| Command palette | Y | Y | Y | Y |
| ZBooks (full accounting) | Y | Y | Y | Y |
| Z Console (persistent AI) | Y | Y | Y | Y |
| Team members | 1 | 5 | 15 | Unlimited |
| AI bid generator | 5/mo | 50/mo | Unlimited | Unlimited |
| Dispatch board + Live map | — | — | Y | Y |
| Phone System lines | 1 | 5 | 15 | Unlimited |
| Website Builder | — | $19.99/mo | $19.99/mo | Included |
| Insurance Claims Module | — | Y | Y | Y |
| Property Management | — | 10 units | 100 units | Unlimited |
| Meeting Rooms | Y | Y | Y | Y |
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
2. **AI goes TRULY LAST** — After ALL of Phase F + G. Not after D. After EVERYTHING. AI must know every feature, every table, every screen. Deep spec session before building. NEVER again start AI before platform is complete.
3. **ZAFTO wordmark** — NOT just the Z. Z is for AI/premium.
4. **ZBooks** — Not "ZAFTO Books"
5. **Stripe feel** — Premium, clean, professional everywhere
6. **RLS on every table** — Tenant isolation at database level
7. **Test during wiring** — Not separately
8. **Circuit Blueprint is LIVING** — Update as connections are made
9. **Property Management** — DONE (D5, S71-S77). 18 tables, full moat.
10. **MS Office: SCRAPPED** — ZDocs/ZSheets only, build LAST (F10)
11. **Static content: REMOVED** — Claude AI handles natively
12. **Offline-first** — PowerSync (SQLite <-> PostgreSQL)
13. **Progressive disclosure** — Clean by default, complexity activates per-need
14. **Nothing ships without human approval** — Every AI artifact needs contractor review
15. **BUILD ORDER: A → B → C → D → F → G → E** — Platform first. Debug second. AI last.

---

CLAUDE: This is the single source of truth. Update it. Never create parallel docs.
