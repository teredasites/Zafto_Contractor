# ZAFTO MASTER BUILD PLAN
## The Complete Roadmap - Mobile App to Full Platform
### February 6, 2026 (Updated Session 34+ — Full Expansion Merge: Docs 11, 16, 23, 26-41 incl. Doc 36 Reconstructed)

---

## EXECUTIVE SUMMARY

**Zafto is the complete business-in-a-box for trades. One subscription. Everything.**

| Metric | Value |
|--------|-------|
| **Field Tools** | 14/14 (UI ONLY — 0 have backend) |
| **Features To Build** | 65 remaining + ~120 hrs wiring + ~610-670 hrs expansion |
| **Design Philosophy** | "Linear meets Stripe for Trades" |
| **Database** | **Supabase (PostgreSQL)** — migrating from Firebase. See `Locked/29_DATABASE_MIGRATION.md` |
| **Security** | **6-layer architecture** — RLS, audit, encryption. See `Locked/30_SECURITY_ARCHITECTURE.md` |
| **Offline Sync** | **PowerSync** (SQLite <-> PostgreSQL) |
| **AI Architecture** | **Universal 6-layer AI** — 1 brain, 4 personas, hive intelligence. See `Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md` |
| **Job Types** | **3 types** — standard, insurance_claim, warranty_dispatch. See `Locked/37_JOB_TYPE_SYSTEM.md` |
| **Circuit Blueprint** | `25_CIRCUIT_BLUEPRINT.md` — READ BEFORE WIRING |

---

## CURRENT STATE (February 5, 2026) - AUDITED SESSION 34

### COMPLETED

| Phase | What | Status |
|-------|------|--------|
| **P0** | Core Business System (Bid/Job/Invoice/Calendar) | DONE (Mobile UI — Hive local, NO backend) |
| **P2** | Field Tools (14 iPhone hardware tools) | UI DONE — ALL have `// TODO: BACKEND`, zero persistence |
| **-** | Design System v2.6 | LOCKED |
| **-** | Database: Supabase PostgreSQL | MIGRATION SPEC'D — execute before wiring |
| **-** | Offline-First Architecture | PowerSync (SQLite <-> PostgreSQL) — replaces Hive + manual sync |
| **-** | Mobile Time Clock + GPS Tracking | UI DONE — NO backend sync |
| **-** | Cloud Functions (11 deployed) | Migrating to Supabase Edge Functions |
| **-** | Stripe Webhook | DONE |
| **P1** | Web Portal CRM (40 pages, mock data) | DONE (UI only, ALL mock data) |
| **P1** | 5 AI Moat Features (Z Intelligence) | DONE (UI shells, mock data) |
| **P1** | Client Portal (21 pages, mock data, fully styled) | DONE (UI only, ALL mock data) |
| **-** | Circuit Blueprint Audit | DONE (Session 28 — `25_CIRCUIT_BLUEPRINT.md`) |
| **-** | Supabase Migration Spec | DONE — `Locked/29_DATABASE_MIGRATION.md` |
| **-** | Security Architecture | DONE — `Locked/30_SECURITY_ARCHITECTURE.md` (6 layers + encrypted storage + data export) |
| **-** | DevOps Infrastructure Spec | DONE — `Locked/32_DEVOPS_INFRASTRUCTURE.md` (CI/CD, 3 environments, Sentry) |
| **-** | Business OS Expansion Spec | DONE — `Expansion/27_BUSINESS_OS_EXPANSION.md` (9 systems, 50 collections) |
| **-** | Website Builder V2 Spec | DONE — `Expansion/28_WEBSITE_BUILDER_V2.md` (2,894 lines — full digital presence OS) |
| **-** | Phone System Spec | DONE — `Expansion/31_PHONE_SYSTEM.md` (1,223 lines — Telnyx VoIP, E2E encryption) |
| **-** | Ops Portal / Founder OS Spec | DONE — `Locked/34_OPS_PORTAL.md` (72 pages, ~163 hrs, 4 phases) |
| **-** | Universal AI Architecture Spec | DONE — `Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md` (6 layers, 4 personas) |
| **-** | Restoration/Insurance Module Spec | DONE — `Locked/36_RESTORATION_INSURANCE_MODULE.md` (756 lines, reconstructed, ~78 hrs) |
| **-** | Job Type System Spec | DONE — `Locked/37_JOB_TYPE_SYSTEM.md` (3 types, progressive disclosure, ~69 hrs) |
| **-** | Insurance Contractor Verticals Spec | DONE — `Expansion/38_INSURANCE_CONTRACTOR_VERTICALS.md` (4 verticals, ~107 hrs) |
| **-** | Growth Advisor Spec | DONE — `Expansion/39_GROWTH_ADVISOR.md` (3 layers, ~88 hrs) |
| **-** | Unified Command Center Spec | DRAFT — `Expansion/40_UNIFIED_COMMAND_CENTER.md` (7 concepts, 12 phases) |
| **-** | Z Console + Artifact System Spec | DRAFT — `Expansion/41_Z_CONSOLE_ARTIFACT_SYSTEM.md` (3-state console, 14 artifacts, 12 phases) |
| **-** | Meeting Room System Spec | DONE — `Expansion/42_MEETING_ROOM_SYSTEM.md` (6 meeting types, Smart Room, AI intelligence, scheduling, ~55-70 hrs) |
| **-** | Mobile Field Toolkit Spec | DONE — `Expansion/43_MOBILE_FIELD_TOOLKIT.md` (24 tools, walkie-talkie/PTT, inspections, restoration, ~89-107 hrs) |

### CRITICAL FINDINGS (Session 28)
- **90 business screens** built — **0** connected end-to-end
- **14 field tools** capture data that evaporates on screen exit
- **PhotoService** (492 lines, complete) exists but nothing uses it
- **17 database tables** need to be created from scratch in Supabase
- **5 operational tools** missing: Materials Tracker, Daily Log, Punch List, Change Orders, Job Completion
- **Architecture mismatch**: resolved — migrating to Supabase PostgreSQL with proper schema
- **Screen registry** only has content — business features invisible to Cmd+K search
- **~120 hours** estimated to wire everything. See `25_CIRCUIT_BLUEPRINT.md`.

### NOT YET BUILT

| Item | Status | Notes |
|------|--------|-------|
| Wire Firestore | NEXT | Replace all mock data in both apps |
| RBAC Enforcement | NOT DONE | Models exist, **enforcement missing** |
| Mobile Calendar Permissions | NOT DONE | Shows all jobs, needs filtering |
| Debug & Polish | AFTER WIRING | Debug with real data, not mock data |
| ZAFTO Home Features | SPEC COMPLETE | Build after Supabase wired + debugged |

### NEXT UP

| Phase | What | Priority |
|-------|------|----------|
| **Sprint 5** | Database migration (Supabase + Security + PowerSync) | **CRITICAL — DO FIRST** |
| **Sprint 6** | Wire Supabase (both apps, 6 phases) | CRITICAL |
| **Sprint 7** | Debug & polish with real data (all 90 screens) | HIGH |
| **Sprint 8** | RBAC enforcement (UI + RLS queries) | HIGH |
| **Sprint 8+** | Business OS Expansion (9 systems) | STRATEGIC |
| **Future** | ZAFTO Home platform features | STRATEGIC |
| **Future** | Website Builder V2 | MEDIUM |
| **Future** | Phone System (Telnyx VoIP) | MEDIUM |
| **Future** | Ops Portal / Founder OS | BUILD LAST |
| **Future** | Insurance Contractor Verticals | STRATEGIC |
| **Future** | Growth Advisor | STRATEGIC |
| **Future** | Unified Command Center | STRATEGIC |
| **Future** | Z Console + Artifact System | STRATEGIC |
| **Future** | Meeting Room System (LiveKit video) | STRATEGIC |
| **Future** | Mobile Field Toolkit (24 tools, walkie-talkie) | STRATEGIC |

---

## ARCHITECTURE OVERVIEW

```
                    ZAFTO PLATFORM ARCHITECTURE

    +-------------------------------------------------------------------+
    |                        CLOUD LAYER                                |
    |  Supabase (PostgreSQL)     Stripe    Claude/Opus 4.5             |
    |  - Database + RLS          - Payments - AI Mentor                |
    |  - Auth (MFA)              - Webhooks - Contract Analyzer        |
    |  - Edge Functions          - Billing  - Bid Generation           |
    |  - Storage (signed URLs)             - Property Advisor (Home)   |
    |  - Realtime subscriptions            - Universal 6-Layer AI      |
    |                                                                   |
    |  Cloudflare               Telnyx/Twilio/SendGrid                 |
    |  - WAF/CDN/DDoS           - VoIP Phone System (Telnyx primary)   |
    |  - Domain registrar       - SMS (two-way texting)                |
    |  - Website hosting        - Call recording + E2E encryption      |
    |                           - Email campaigns (SendGrid)           |
    +-------------------------------------------------------------------+
                              |
    +---------------+---------+---------+---------------+
    |               |                   |               |
    v               v                   v               v
+---------+  +-------------+      +-------------+  +-------------+
| iOS App |  | Android App |      | Web Portal  |  | ZAFTO HOME  |
| (Field) |  |   (Field)   |      |  (Office)   |  | (Homeowner) |
+---------+  +-------------+      +-------------+  +-------------+
    |               |                   |               |
    +---------------+---------+---------+---------------+
                              |
                              v
              +-------------------+
              |  OPS PORTAL       |
              |  (Founder OS)     |
              |  ops.zafto.cloud  |
              +-------------------+
                              |
    +-----------------------------------------------------+
    |                   OFFLINE LAYER                      |
    |  PowerSync (SQLite <-> PostgreSQL)                   |
    |  Full SQL offline    Automatic conflict resolution   |
    |  Cached Content      Real-time sync on reconnect     |
    +-----------------------------------------------------+

    +-----------------------------------------------------+
    |                  SECURITY LAYER                      |
    |  Row-Level Security (every table)                    |
    |  6 roles: Owner/Admin/Office/Tech/CPA/Client        |
    |  + super_admin (Ops Portal only)                    |
    |  Append-only audit log   Field-level encryption     |
    |  Envelope encryption (per-company keys, HSM)        |
    |  See: 30_SECURITY_ARCHITECTURE.md                   |
    +-----------------------------------------------------+

    +-----------------------------------------------------+
    |              UNIVERSAL AI LAYER                      |
    |  1 AI Brain — 6 Layers — 4 Personas                |
    |  L1: Identity Context (role, trade, state)          |
    |  L2: Knowledge Retrieval (RAG, code books)          |
    |  L3: Persistent Memory (cross-session)              |
    |  L4: Session Context (current workflow)             |
    |  L5: Compounding Intel (platform patterns)          |
    |  L6: RBAC Filter (role-based AI output)             |
    |  See: 35_UNIVERSAL_AI_ARCHITECTURE.md               |
    +-----------------------------------------------------+

              +-----------------------------+
              |   ZAFTO HOME MARKETPLACE    |
              |  (Future - Phase 3 launch)  |
              |                             |
              |  Homeowner <-> Contractor   |
              |  AI equipment diagnostics,  |
              |  pre-qualified leads,       |
              |  service requests, quotes   |
              +-----------------------------+
```

**NO FIREBASE. Everything runs on Supabase. One system. Zero split infrastructure.**

### URL Structure
```
zafto.app              -> Marketing landing page
zafto.cloud            -> Contractor CRM (web portal)
client.zafto.cloud     -> ZAFTO Home (homeowner portal)
ops.zafto.cloud        -> Founder OS (internal operations — Doc 34)
status.zafto.app       -> Public status page (auto-generated from health checks — Doc 34)
home.zafto.app         -> ZAFTO Home marketing (future)
yourco.zafto.cloud     -> Contractor websites (Website Builder V2 — Doc 28)
```

---

## PHASE 1: CLOUD FUNCTIONS (Enables Everything)

**Priority:** CRITICAL - Must deploy before any payment/AI features work
**Estimated Build:** 4-6 hours

### Cloud Functions — Migrating to Supabase Edge Functions

```
All 11 existing Firebase functions will be rewritten as Supabase Edge Functions
during the database migration. Same HTTP endpoints, same logic, new home.

Functions to migrate:
- AI scans (analyzePanel, analyzeNameplate, analyzeWire, analyzeViolation, smartScan)
- Credits (getCredits, addCredits)
- Payments (createPaymentIntent, stripeWebhook, getPaymentStatus)
- IAP (revenueCatWebhook)
```

### Stripe Setup (Remaining Steps)

```bash
# Stripe webhooks will point to Supabase Edge Functions after migration
# Endpoint: https://YOUR_PROJECT.supabase.co/functions/v1/stripe-webhook
# Same events: payment_intent.succeeded, payment_intent.payment_failed
```

---

## PHASE 2: WEB PORTAL (zafto.app / app.zafto.app)

**Design:** "Linear meets Stripe for Trades"
**Tech Stack:** Next.js 14, Tailwind CSS, Firebase, TanStack Query
**Estimated Build:** ~52 hours (23 sub-phases)

### Design DNA

| Inspiration | What We Take |
|-------------|--------------|
| **Linear** | Command palette (Cmd+K), keyboard-first, buttery animations |
| **Vercel** | Clean data viz, real-time status updates |
| **Stripe** | Information density done right, professional but not boring |
| **Raycast** | Speed, dark mode that slaps, instant search |
| **Apple** | Attention to detail, spacing, typography |

### Build Order

| # | Phase | Hours | Features |
|---|-------|:-----:|----------|
| 1 | Foundation | 2 | Next.js setup, Tailwind, Firebase SDK, auth flow |
| 2 | Dashboard | 2 | Stats cards, action items, today's schedule, activity feed |
| 3 | Jobs Module | 2 | List, detail, create/edit, filtering |
| 4 | Invoices Module | 1.5 | List, detail, create, payment tracking |
| 5 | Customers Module | 1 | List, detail, history, tags |
| 6 | Dispatch Board + Live Map | 5 | Drag-drop calendar, tech locations, geofencing |
| 7 | Team Management | 1.5 | Members, invites, roles, presence |
| 8 | Reports | 2 | Revenue, jobs, team performance, exports |
| 9 | Settings | 1.5 | Company, user, subscription, branding, integrations |
| 10 | Marketing Landing | 2 | Hero, features, pricing, comparison |
| 11 | Command Palette | 2 | Cmd+K search, keyboard shortcuts |
| 12 | AI Command Bar | 2 | Natural language queries |
| 13 | Real-Time Updates | 1.5 | Supabase Realtime subscriptions, optimistic UI |
| 14 | Animations & Polish | 1.5 | Transitions, micro-interactions, skeletons |
| 15 | AI Bid Generator | 3 | Job description -> structured bid |
| 16 | Price Book | 3 | Categories, items, markup, supplier import, AI-referenced |
| 17 | Material List AI | 2 | Shopping lists from job descriptions |
| 18 | Labor Rate Tables | 1.5 | Standard, emergency, per-tech rates |
| 19 | Bid Templates/PDF | 2 | Templates, PDF generation, tracking |
| 20 | Zafto Docs | 2.5 | Tiptap editor, proposals, contracts, PDF-first export |
| 21 | Zafto Sheets | 3.5 | Handsontable, formulas, PDF/XLSX/CSV export |
| 22 | Customer Notifications | 3 | SMS (Twilio), email, templates |
| 23 | Time Tracking | 3 | Clock in/out, job time, timesheets |
| 24 | **Zafto Books (Full Accounting)** | 15-20 | 30 features — see `Expansion/16_ZAFTO_HOME_PLATFORM.md` Appendices G, H, I, J |
| 25 | **Z AI Assistant** | 5 | Full tool access, action tiers, confirmations, audit log |
| | **TOTAL** | **~60** | |

### Feature Matrix by Tier

| Feature | Solo | Team | Business | Enterprise |
|---------|:----:|:----:|:--------:|:----------:|
| Dashboard | Y | Y | Y | Y |
| Jobs/Invoices/Customers | Y | Y | Y | Y |
| PDF invoices | Y | Y | Y | Y |
| Price book | Y | Y | Y | Y |
| AI bid generator | 5/mo | 50/mo | Unlimited | Unlimited |
| Material list AI | 5/mo | 50/mo | Unlimited | Unlimited |
| Bid templates | 3 | Unlimited | Unlimited | Unlimited |
| Command palette | Y | Y | Y | Y |
| AI command bar | - | Y | Y | Y |
| Team members | - | 5 | 15 | Unlimited |
| Dispatch board | - | - | Y | Y |
| Live map + location | - | - | Y | Y |
| Geofencing | - | - | Y | Y |
| Custom roles | - | - | - | Y |
| Advanced reports | - | - | Y | Y |
| API access | - | - | - | Y |
| **Zafto Books (Full Accounting)** | Y | Y | Y | Y |
| Bank connections (Plaid) | 1 account | 3 accounts | Unlimited | Unlimited |
| P&L / Balance Sheet / Cash Flow | Y | Y | Y | Y |
| Tax prep + CPA export (QBO/CSV/PDF) | Y | Y | Y | Y |
| CPA Accountant Portal access | - | Y | Y | Y |
| Multi-entity accounting | - | - | Y | Y |
| **Zafto Docs** | Y | Y | Y | Y |
| **Zafto Sheets** | Y | Y | Y | Y |
| Document templates | 5 | Unlimited | Unlimited | Unlimited |
| AI document generation | 5/mo | 50/mo | Unlimited | Unlimited |
| PDF export | Y | Y | Y | Y |
| DOCX/XLSX export | Y | Y | Y | Y |
| **Phone System (VoIP)** | 1 line | 5 lines | 15 lines | Unlimited |
| **Website Builder** | - | Y ($19.99/mo add-on) | Y ($19.99/mo add-on) | Included |
| **Insurance Claims Module** | - | Y | Y | Y |
| **Warranty Dispatch Module** | - | Y | Y | Y |
| **Growth Advisor** | - | Y | Y | Y |
| **Z Console (Persistent AI)** | Y | Y | Y | Y |
| **Meeting Rooms (Video)** | Y | Y | Y | Y |

---

## PHASE 3: CLIENT PORTAL -> ZAFTO HOME (client.zafto.cloud)

**Status:** CLIENT PORTAL COMPLETE (21 pages, fully styled) — Built Sessions 27A/B/C
**Full spec:** `15_CLIENT_PORTAL.md`
**Platform vision:** `Expansion/16_ZAFTO_HOME_PLATFORM.md`
**Location:** `apps/Trades/client-portal/`
**Design:** Stripe purple (#635bff), Offset Echo Z logo, dark/light mode, Tailwind v4 @theme

### What's Built (21 Pages)

| Tab | Pages | Status |
|-----|-------|--------|
| Auth | Login | DONE |
| Home | Action Center (smart cards) | DONE |
| Projects | List, Detail, Estimate (G/B/B), Agreement (e-sign), Live Tracker (Uber-style) | DONE |
| Payments | Invoices, Invoice Detail, History, Methods | DONE |
| My Home | Property Profile, Equipment List, Equipment Detail (Passport) | DONE |
| Menu | Messages, Documents, Request Service, Referrals, Review Builder, Settings | DONE |

### ZAFTO Home Platform Vision (STRATEGIC — Future Build)

The Client Portal evolves into a homeowner-owned property intelligence platform:

| Tier | What | Revenue |
|------|------|---------|
| Free | Property record, equipment passport, service history | Network growth |
| Premium ($7.99/mo) | AI property advisor, smart alerts, quote context | Homeowner sub |
| Marketplace | Lead gen for unattached homeowners | Per-lead fees |

**Critical constraint:** Contractor Trust Architecture must be implemented first.
Six principles protect contractor relationships (full spec in `Expansion/16_ZAFTO_HOME_PLATFORM.md`):
1. Live loyalty dashboard | 2. Kill switch toggle | 3. Revenue opportunity alerts
4. Published public rules | 5. Contractor advisory board | 6. Launch through contractors first

### Security
- Homeowner authentication (email/password or SSO)
- Account independent of contractor relationship
- Multiple contractors can link to one property
- Homeowner can revoke contractor access anytime

---

## WEB PORTAL PHASE 24: ZAFTO BOOKS (Full QuickBooks Replacement)

> **FULL SPEC MOVED -> `Expansion/16_ZAFTO_HOME_PLATFORM.md` Appendices G, H, I, J**
> This section is a summary. The complete 30-feature spec with UI mockups, data models,
> chart of accounts, RBAC matrix, and implementation details lives in doc 16.
> **DO NOT BUILD FROM THIS SUMMARY. READ THE APPENDICES.**

**Purpose:** Complete trade-native accounting system that REPLACES QuickBooks — not a lightweight add-on
**Strategy:** REPLACEMENT, not integration. No live QuickBooks sync. Export compatibility only (QBO, CSV, PDF, JSON). ZAFTO is the system of record.

### What It Is (30 Features Across 4 Appendices)

| Appendix | Scope | Features |
|----------|-------|:--------:|
| **G** — Full Accounting System | Chart of accounts, receipt scanning, auto-categorization, P&L, balance sheet, tax deductions, bank reconciliation (Plaid), vendor analysis, labor allocation, year-end workflow | 14 |
| **H** — Late Payment Escalation | 7-stage escalation engine, state law database (all 50 states), mechanics lien generation, document templates, bad debt tracking | 5 |
| **I** — Contractor Relationships | GC/Sub management, pay application generator (AIA G702/G703), retainage tracking, back-charge defense, compliance vault, prevailing wage automation | 8 |
| **J** — Advanced Accounting | Forensic audit trail (hash-chained), depreciation/asset management, CPA Accountant Portal, sales tax intelligence, budget vs actual, financial KPIs, multi-entity support, loan tracking | 13 |

**Total: 30 features. 20+ are things QuickBooks fundamentally cannot do.**

### What Changed From Original Plan (February 4, 2026)

| Original Plan Said | Doc 16 Now Says | Why |
|-------------------|-----------------|-----|
| "Leave balance sheets to CPAs" | ZAFTO generates balance sheets automatically | Data already exists from jobs/invoices/expenses — the accounting happens as a byproduct |
| "Leave depreciation to CPAs" | Full asset/depreciation management with Section 179 advisor | Equipment Fleet View already tracks every asset — depreciation is just a calculation on top |
| "Multi-entity is enterprise edge case" | Multi-entity support for common contractor structures | Most established contractors have 2-3 LLCs (operating, real estate, holding) — this is normal, not edge case |
| "QuickBooks/Xero sync required for Enterprise" | Export compatibility only, no live sync | Live sync positions QB as system of record — backwards. ZAFTO has data QB never will. |
| "Simplified bookkeeping" | Full professional accounting with forensic audit trail | The contractor never sees complexity — they run their business, ZAFTO handles the accounting automatically |

### The Core Insight

QuickBooks asks the contractor to translate their business into accounting language. ZAFTO Books speaks contractor language and handles the accounting behind the scenes. Zero double-entry — complete a job -> invoice exists. Buy materials -> expense linked to job. Pay crew -> labor cost allocated. The accounting is a byproduct of running the business.

### CPA Accountant Portal (Distribution Channel)

Each CPA gets their own ZAFTO login to manage ALL their contractor clients in one dashboard. Every CPA who joins is a channel for 10-30 new contractor signups. Convert 5 CPAs in year one = potentially 150-250 contractors via trusted professional recommendation.

### Why QuickBooks Loses

| Where ZAFTO Wins | Where QB Still Wins |
|-------------------|---------------------|
| Trade-specific chart of accounts (pre-configured) | Ecosystem (750+ app integrations) |
| Zero double-entry (accounting from business operations) | Brand trust (40 years, millions of users) |
| Job-linked expenses, receipt AI, auto-categorization | Neither of these are about product quality |
| Real-time job costing, bid-to-profit feedback loop | |
| State-specific sales tax intelligence for trades | |
| Mechanics lien generation, collections automation | |
| CPA portal as distribution channel | |
| 30 features vs QB's ~12-15 core features | |

---

## WEB PORTAL PHASES 20-21: ZAFTO DOCS & SHEETS (PDF-First Office Suite)

**Philosophy:** Contractors don't need Microsoft Office. They need to create professional documents and send them. PDF is king.

### Zafto Docs (Document Editor)

**Technology:** Tiptap (same engine as Notion)
**Estimated Build:** 2.5 hours

| Feature | Description |
|---------|-------------|
| **Rich Text Editing** | Bold, italic, lists, headers, blockquotes |
| **Tables** | Simple tables for pricing, scope items |
| **Images** | Embed photos, auto-resize |
| **Company Letterhead** | Auto-applied from company settings |
| **Template Variables** | `{{customer_name}}`, `{{job_address}}`, `{{total}}` |
| **Signature Blocks** | Built-in signature lines |
| **Professional Templates** | Proposal, Contract, Scope of Work, Change Order |
| **AI Generation** | "Write a proposal for this job" |

**Export Strategy:**
| Format | Priority | Reliability | Use Case |
|--------|:--------:|:-----------:|----------|
| **PDF** | PRIMARY | 100% | Customer viewing, signing, printing |
| **DOCX** | Secondary | 85-90% | When customer demands editable |
| **Link** | Alternative | 100% | View in Client Portal |

### Zafto Sheets (Spreadsheet)

**Technology:** Handsontable (Excel-like grid)
**Estimated Build:** 3.5 hours

| Feature | Description |
|---------|-------------|
| **Grid Editing** | Click, type, tab navigation |
| **Basic Formulas** | `=SUM()`, `=AVERAGE()`, `=A1*B1` |
| **Number Formatting** | Currency, percentage, decimals |
| **Copy/Paste** | Works from Excel |
| **Professional Templates** | Estimate, Material List, Job Costing, Panel Schedule |
| **AI Generation** | "Create an estimate for this job" |

**Export Strategy:**
| Format | Priority | Reliability | Use Case |
|--------|:--------:|:-----------:|----------|
| **PDF** | PRIMARY | 100% | Customer-facing documents |
| **CSV** | Data | 100% | Data transfer, accounting import |
| **XLSX** | Secondary | 85-90% | When they need to edit in Excel |

### Microsoft Office Embedding — SCRAPPED (February 4, 2026)

**Decision:** MS Office embedding is permanently off the table. Conversion fidelity between third-party editors (OnlyOffice, Google Docs, LibreOffice) and actual .docx/.xlsx is unreliable — simple docs are fine but complex GC contracts with tracked changes, form fields, and custom formatting can break. We cannot ship anything that's not bulletproof. If a contractor opens a document and one table is shifted, ZAFTO looks amateur. That's worse than not having Office at all.

**The replacement strategy:** ZAFTO Docs and ZAFTO Sheets (above) are structured, templated document tools where WE control every pixel. Contractors don't need Word — they need to create estimates, contracts, proposals, and punch lists without leaving ZAFTO. Output is clean PDF every time. No conversion, no drift, no holes.

**IMPORTANT — BUILD ORDER:** These document tools should be the LAST feature built, after every other ZAFTO feature is confirmed and locked. The document builders need to know every template type, every field, every output format the platform requires. Building them before the feature set is final means rework. Build everything else first, then build the document suite to serve every feature that exists.

**No alternative embedding (OnlyOffice, Google, etc.) will be pursued.** PDF-first, ZAFTO-controlled, zero third-party conversion risk.

---

## WEB PORTAL PHASE 25: Z AI ASSISTANT (Full Tool Access)

**Purpose:** AI assistant with access to all business data and tools
**Estimated Build:** 5 hours
**Available on:** Web Portal + Mobile App
**Full Architecture:** See `Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md` (6 layers, 4 personas)
**Console Interface:** See `Expansion/41_Z_CONSOLE_ARTIFACT_SYSTEM.md` (3-state persistent UI)

### Action Tiers (Guardrails)

| Tier | Actions | Confirmation |
|:----:|---------|--------------|
| **GREEN** | Read data, search, calculate, answer questions | None - auto-execute |
| **YELLOW** | Create/edit jobs, invoices, bids, customers, documents | Preview + [Confirm] [Cancel] |
| **RED** | Delete, send invoices, process payments, modify settings | Hard confirm with warning |
| **NEVER** | Access other companies, modify auth, raw database access | Blocked completely |

### Soft Delete Architecture (Nothing Ever Truly Gone)

All "deleted" items are soft-deleted:
- `deletedAt: timestamp` flag (not actual deletion)
- Moves to user's "Trash"
- User can restore anytime
- Auto-purge after 30 days (Cloud Function)
- User can manually empty trash

```
Delete -> Soft delete (flag) -> Trash (30 days) -> User can restore
                                    |
                            Auto-purge after 30 days
```

### AI Personality Guidelines

**The AI is:**
- Professional, efficient, work-focused
- Concise - contractors are busy
- Knowledgeable about trades (uses Intel folder)
- Helpful - always looking to take action

**The AI is NOT:**
- A therapist or companion chatbot
- A cop that lectures about staying on topic
- Restrictive or refusing reasonable questions

**Off-topic handling (soft steering, not blocking):**
```
User: "How's it going?"
AI: "Ready to work! What do you need?"

User: "I'm stressed about this project"
AI: "Let's break it down. What's the main blocker?"

User: "Tell me a joke"
AI: "Why did the electrician break up with the outlet? No spark.
     What can I help you with?"
```

### API Usage Limits (Soft, Not Hard)

| Tier | Monthly Limit | At Limit |
|------|:-------------:|----------|
| Solo | 100 queries | Soft warning, can still use app manually |
| Team | 500 queries | Soft warning |
| Business | 2,000 queries | Soft warning |
| Enterprise | Unlimited | No limit |

**At limit behavior:** User sees warning but can still use all Zafto features manually. Not a hard block.

### Audit Log

Every AI action logged:
- Timestamp, user, company
- User message
- Tools called
- Actions performed
- Previous state (for undo)

Stored in: `companies/{companyId}/aiAuditLogs/{logId}`

### Intel Folder Integration

Z AI has access to:
- All user business data (jobs, invoices, customers, bids)
- NEC/Plumbing/HVAC code references
- Best practices by trade
- Contract red flag patterns
- State-specific lien laws

### The Key Insight

```
TRADITIONAL FLOW (Complex, error-prone):
Contractor -> Creates in Word -> Saves .docx -> Emails -> Customer opens in Word -> Edits? -> Confusion

ZAFTO FLOW (Simple, bulletproof):
Contractor -> Creates in Zafto -> Sends link OR PDF -> Customer views in browser -> Signs -> Done
```

---

## PHASE 4: WEBSITE BUILDER (yourco.zafto.cloud)

**Purpose:** AI-generated contractor websites
**Estimated Build:** 15-20 hours
**Full Spec (V2):** See `Expansion/28_WEBSITE_BUILDER_V2.md` — Cloudflare Registrar API, strict templates, $19.99/mo
**Original Spec (V1):** See `20_WEBSITE_BUILDER.md` (superseded by V2)

### Core Features

| Feature | Description |
|---------|-------------|
| **AI Generation** | Opus 4.5 creates site from trade + business name |
| **40 Templates** | Trade-specific, multiple styles per trade |
| **Logo Creator** | Icon library, layouts, colors, fonts |
| **Subdomain Hosting** | yourcompany.zafto.cloud |
| **Custom Domain** | $14.99/yr via Cloudflare Registrar API (zero external accounts) |
| **Opus Editor** | AI-powered content editing |
| **Live CRM Sync** | Website pulls real data from contractor's CRM |
| **Zero Maintenance** | SSL, DNS, renewal — all automatic |

> **Source: Doc 28.** V2 uses Cloudflare Registrar API. User never creates an account anywhere.
> User never touches DNS. Search, click, pay, done. Site live in 60 seconds.
> Domain ownership belongs to customer. Price: $19.99/mo + $14.99/yr custom domain.

### Template Count by Trade

| Trade | Templates |
|-------|:---------:|
| Electrical | 4 |
| Plumbing | 4 |
| HVAC | 4 |
| Solar | 4 |
| Roofing | 4 |
| GC | 4 |
| Remodeler | 4 |
| Landscaping | 4 |
| Auto Mechanic | 4 |
| Welding | 2 |
| Pool/Spa | 2 |
| **Total** | **40** |

---

## PHASE 5+: BUSINESS OPERATIONS & GAME CHANGERS

### Business Operations (16 Features)

| # | Feature | Phase | Description |
|---|---------|:-----:|-------------|
| 1 | License & Insurance Tracker | P4 | Expiration alerts, digital proof |
| 2 | Warranty Tracker | P4 | Equipment warranties, callbacks |
| 3 | Permit Tracker | P4 | Status tracking, documents |
| 4 | Time Clock & Timesheets | P4 | Clock in/out, payroll export |
| 5 | COI Generator | P10 | Certificate of Insurance on demand |
| 6 | Inventory/Truck Stock | P5 | Stock levels, low alerts |
| 7 | Equipment Rental Tracker | P10 | Rentals, return dates, costs |
| 8 | 1099 Subcontractor Manager | P5 | Sub payments, W-9, 1099 prep |
| 9 | Lien Deadline Calendar | P10 | State-specific deadlines |
| 10 | Zafto Docs | P1 | Tiptap editor, templates, PDF-first, DOCX secondary |
| 11 | Zafto Sheets | P1 | Handsontable, formulas, PDF/XLSX/CSV export |
| 12 | Blueprint/Plan Viewer | P6 | PDF viewer, markup, offline |
| 13 | Accounts Payable | P5 | Bills, due dates, cash flow |
| 14 | Material List AI | P6 | Shopping lists from job desc |
| 15 | Labor Rate Tables | P6 | Standard, emergency, per-tech |
| 16 | Geofencing | P6 | Auto arrival/departure |

### Client Communication (5 Features)

| # | Feature | Phase | Description |
|---|---------|:-----:|-------------|
| 1 | Two-Way SMS | P2 | Twilio, conversations logged |
| 2 | Automated Job Updates | P2 | Status-triggered messages |
| 3 | Review Request Automation | P3 | Post-job review links |
| 4 | Client Portal Messaging | P6 | Secure file sharing |
| 5 | Team Chat | P6 | Internal messaging |

### Financial Tools - "Zafto Books" (Full QuickBooks Replacement)

> **FULL SPEC -> `Expansion/16_ZAFTO_HOME_PLATFORM.md` Appendices G, H, I, J (30 features)**

**Philosophy:** ZAFTO Books replaces QuickBooks entirely. The contractor runs their business — the accounting happens automatically as a byproduct. No double-entry. No translation into accounting language. Export to CPA in QBO/CSV/PDF format. No live sync.

| # | Feature | Phase | Description |
|---|---------|:-----:|-------------|
| 1 | **Trade-Specific Chart of Accounts** | P1 | Pre-configured for trades, contractor never touches it |
| 2 | **Receipt Scanning + AI Categorization** | P1 | Photo -> OCR -> auto-linked to job -> auto-categorized |
| 3 | **Bank Connections (Plaid)** | P1 | Auto-import, auto-match to ZAFTO invoices/expenses |
| 4 | **P&L + Balance Sheet + Cash Flow** | P1 | Trade-native reports, not generic accounting |
| 5 | **Tax Deduction Intelligence** | P1 | Proactive identification (home office, mileage, tools, CE) |
| 6 | **Late Payment Escalation (7-stage)** | P1 | Auto-reminders -> mechanics liens -> collections |
| 7 | **State Law Database (50 states)** | P1 | Lien deadlines, late fee rules, filing requirements |
| 8 | **GC/Sub Management + Pay Apps** | P1 | AIA G702/G703, retainage tracking, back-charge defense |
| 9 | **Forensic Audit Trail** | P1 | Hash-chained, tamper-evident, IRS-grade |
| 10 | **Depreciation + Asset Management** | P1 | Auto from Equipment Fleet View, Section 179 advisor |
| 11 | **CPA Accountant Portal** | P1 | CPA manages all contractor clients in one dashboard |
| 12 | **Sales Tax Intelligence** | P1 | State-specific trade rules (CT lump-sum vs separated) |
| 13 | **Budget vs Actual** | P1 | AI-suggested budgets from real data, variance tracking |
| 14 | **Financial KPIs** | P1 | Trade-specific: revenue/job, bid conversion, backlog coverage |
| 15 | **Multi-Entity Support** | P1 | Operating LLC + real estate LLC + holding — one dashboard |
| 16 | **Loan Tracking** | P1 | Auto-split principal/interest, amortization, payoff strategy |
| 17-30 | See doc 16 Appendices G-J | P1 | Vendor analysis, labor allocation, 1099s, year-end workflow, prevailing wage, compliance vault, and more |

**The Pitch:** "Stop paying $60-200/month for software that doesn't understand your business. Your CPA gets cleaner data than they've ever seen from QuickBooks."

---

## EXPANSION SYSTEM: DEVOPS INFRASTRUCTURE (Source: Doc 32)

**Purpose:** CI/CD, environments, monitoring, testing, secrets management, compliance
**Full Spec:** `Locked/32_DEVOPS_INFRASTRUCTURE.md`

| Phase | When | Effort | What |
|-------|------|--------|------|
| **Phase 1** | Before database migration (Sprint 5) | ~2 hours | Dev/staging/prod environments, secrets management, Dependabot |
| **Phase 2** | During wiring (Sprint 6) + Launch prep | ~8-12 hours | Crash reporting (Sentry), automated tests, CI/CD pipeline (GitHub Actions), incident response |
| **Phase 3** | Pre-enterprise sales | Varies | SOC 2 audit, DNSSEC/DMARC/SPF/DKIM, pen testing |

**Key decisions:**
- 3 Supabase projects: `zafto-dev`, `zafto-staging`, `zafto-prod` (same schema, same RLS, different data)
- Secrets in Supabase Vault (prod), env vars (dev/staging)
- Service role key NEVER in client-side code
- Schema changes: dev -> staging -> prod (never skip staging)

---

## EXPANSION SYSTEM: OPS PORTAL / FOUNDER OS (Source: Doc 34)

**Purpose:** Single sign-in command center for running the entire ZAFTO operation
**URL:** `ops.zafto.cloud`
**Full Spec:** `Locked/34_OPS_PORTAL.md` (2,083 lines)
**Tech:** Next.js 15, TypeScript, Tailwind CSS, Supabase
**Auth:** `super_admin` role — cross-tenant read access, restricted write permissions
**AI:** Private Claude instance with full platform + business context (NOT customer-facing Z Intelligence)
**Design accent:** Deep navy/teal (distinct from contractor orange and client Stripe purple)
**Total: 72 pages, ~163 hours, 4 phases**

| Phase | Pages | Hours | When |
|-------|:-----:|:-----:|------|
| Phase 1: Foundation | 18 | ~40 | Before launch (Sprint 7B) |
| Phase 2: Growth Engine | 23 | ~57 | Post-launch, month 1 |
| Phase 3: Enterprise Suite | 23 | ~49 | Month 2-3 |
| Phase 4: Marketplace Ops | 8 | ~17 | Marketplace launch |
| **TOTAL** | **72** | **~163** | |

**20 sections including:** Command Center, Unified Inbox, Account Management, Support Center, Platform Health, Revenue Dashboard, Contractor Discovery Engine, Campaign Engine, Growth CRM, Banking & Treasury, Legal Department, Dev Terminal, Ad Manager, SEO Command Center, and more.

**Replaces 17+ tools:** Supabase Dashboard, Stripe Dashboard, Sentry, Gmail/Zendesk, Mailchimp, Google Analytics, Google Ads, Meta Ads, Ahrefs, Notion, HubSpot, bank websites, QuickBooks (for Tereda), GitHub Desktop, LegalZoom, 1Password, Apple/Google developer consoles.

**Key Dart/service classes:** N/A (Next.js web app — no Flutter classes)
**Key DB additions:** 16 new Supabase tables, 25 Edge Functions

---

## EXPANSION SYSTEM: UNIVERSAL AI ARCHITECTURE (Source: Doc 35)

**Purpose:** One AI brain across every trade, every role, every context, every app
**Full Spec:** `Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md`
**Status:** DRAFT (reviewed, exam system scrapped, code strategy finalized Option B)

### The Six Layers

| Layer | Name | Purpose |
|:-----:|------|---------|
| 1 | Identity Context | Who are you? (role, trade, state, company) |
| 2 | Knowledge Retrieval | What does the AI reference? (RAG, code books, standards) |
| 3 | Persistent Memory | What does Z remember about YOU? (cross-session intelligence) |
| 4 | Session Context | What are you doing RIGHT NOW? (cross-feature awareness) |
| 5 | Compounding Intel | What has the PLATFORM learned? (aggregate patterns) |
| 6 | RBAC Intelligence | What is Z ALLOWED to reveal to this role? |

### Four Personas

| Persona | Who | Key Behavior |
|---------|-----|-------------|
| **Field Professional** | Technician/Journeyman/Apprentice | Speaks as senior tradesperson, cites codes, safety-first |
| **Homeowner** | Property owner | Plain English, never undermines contractor, never gives DIY safety advice |
| **Business Owner** | Admin/Owner | Full data access, strategic advice, growth recommendations |
| **Office Manager** | Office staff | Operational focus, scheduling, customer communication |

### Strategic Content Overhaul (Doc 35)

| Content | Count | Decision |
|---------|:-----:|----------|
| Standalone Calculators | 1,186 | REMOVED — Claude knows every formula |
| Exam Questions | 5,080 | REMOVED / SCRAPPED — not part of product direction |
| Diagrams | 111 | EVALUATE — some visual references may still add value |
| Reference Guides | 21 | REMOVED — AI answers reference questions contextually |
| Field Tools | 14 | KEEP — data capture workflows need real UI |
| ZAFTO-Connected Tools | -- | KEEP — any tool integrating with ZAFTO ecosystem stays |

**Key insight:** Adding a new trade is no longer a 6-month content buildout. It is a knowledge corpus upload that takes days. The AI handles everything else.

---

## EXPANSION SYSTEM: JOB TYPE SYSTEM (Source: Doc 37)

**Purpose:** Every job has a type that controls workflow, fields, and integrations
**Full Spec:** `Locked/37_JOB_TYPE_SYSTEM.md` (LOCKED)
**Total Build: ~69 hours**

### Three Job Types

| Type | Who Uses It | Payer | Workflow Source |
|------|-------------|-------|----------------|
| `standard` | Every contractor, every trade | Customer pays directly | Trade default pipeline |
| `insurance_claim` | Restoration, roofing, GC, remodeler, any trade | Carrier pays + homeowner deductible | Insurance pipeline (from Doc 36) |
| `warranty_dispatch` | Plumbing, HVAC, electrical, roofing, appliance | Warranty company pays (minus service fee) | Warranty pipeline (Doc 37) |

### Progressive Disclosure (4 Levels)

| Level | What Happens |
|-------|-------------|
| 0 — New Contractor | Job type selector HIDDEN. All jobs are standard. Simplest experience. |
| 1 — Insurance Enabled | Selector shows Standard / Insurance Claim. Carrier management in Settings. |
| 2 — Warranty Enabled | Selector shows Standard / Warranty Dispatch. Warranty company directory in Settings. |
| 3 — Both Enabled | All three options. Dashboard shows revenue by type. Calendar color-codes by type. |

### Build Phases

| Phase | Scope | Hours |
|-------|-------|:-----:|
| Schema (migration) | DB tables for warranty dispatch | ~2 |
| Phase 1 — Warranty Dispatch UI | Job type selector, workflow, warranty panels | ~18 |
| Phase 2 — Dashboard + Books Integration | Revenue-by-type widget, three-payer accounting | ~13 |
| Phase 3 — Warranty Company Integrations | API research, auto-import, auto-submit (future) | ~36 |
| **TOTAL** | | **~69** |

### Three-Payer Accounting Model
Jobs can now have three payers: customer (standard), carrier + homeowner deductible (insurance), warranty company minus service fee (warranty). Zafto Books handles all three models in a unified receivables system.

---

## EXPANSION SYSTEM: INSURANCE CONTRACTOR VERTICALS (Source: Doc 38)

**Purpose:** Four insurance-adjacent verticals beyond core restoration
**Full Spec:** `Expansion/38_INSURANCE_CONTRACTOR_VERTICALS.md`
**Extends:** Doc 37 (Job Type System) + Doc 36 (Restoration Module)
**Total Build: ~107 hours across 3 phases**

### The Four Verticals

| Vertical | Who | Job Type | Trade |
|----------|-----|----------|-------|
| **Storm/Cat Roofing** | Roofers following hail/wind storms | insurance_claim | Roofing |
| **Property Reconstruction** | GCs/remodelers who rebuild after mitigation | insurance_claim | GC or Remodeler |
| **Commercial Claims** | Multi-trade teams on large commercial losses | insurance_claim | Any (multi-trade) |
| **Home Warranty Network** | Plumbers, HVAC, electricians dispatched by warranty companies | warranty_dispatch | Plumbing, HVAC, Electrical, Roofing |

### Key Dart Classes

- `StormRoofingWorkflow` — extends `TradeWorkflowConfig` for roofing + storm mode (canvassing, mass lead pipeline, adjuster scheduling, multi-state ops)
- `ReconstructionWorkflow` — extends `TradeWorkflowConfig` for reconstruction (scope writing, upgrade tracking, carrier/deductible/upgrade three-section invoicing)
- `VerticalDetectionService` — auto-detects which vertical a contractor fits based on company profile

### Build Phases

| Phase | Scope | Hours |
|-------|-------|:-----:|
| Phase 1 — Launch (ships with Docs 36+37) | Upgrade tracking, three-section invoice, unified revenue dashboard | ~15 |
| Phase 2 — Post-Launch (first 3 months) | Storm event tagging, canvassing, multi-company dispatch, vertical detection | ~29 |
| Phase 3 — Scale (6+ months) | Territory mapping, commercial multi-trade, warranty API integrations | ~63 |
| **TOTAL** | | **~107** |

---

## EXPANSION SYSTEM: GROWTH ADVISOR (Source: Doc 39)

**Purpose:** AI-powered revenue expansion engine for contractors
**Full Spec:** `Expansion/39_GROWTH_ADVISOR.md`
**Total Build: ~88 hours across 3 phases**

### How It Works — Three Layers

| Layer | Name | Source |
|-------|------|--------|
| 1 | Contractor Profile | Automatic — built from data already in ZAFTO (trade, state, licenses, job history, team size) |
| 2 | Opportunity Knowledge Base | Curated — structured DB of opportunities per trade per state (warranty networks, carrier programs, certifications, government programs) |
| 3 | Z Intelligence | AI Matching — matches L1 against L2, filters noise, ranks by revenue impact and ease of entry |

### Key Features
- Per-trade opportunity catalogs for 8+ trades (plumbing, HVAC, electrical, roofing, GC, remodeler, restoration, solar)
- 6 proactive AI triggers (new opportunity match, seasonal timing, certification unlocks, revenue gap detection, warranty network opening, government program deadline)
- 3 UI surfaces: Dashboard widget (top 2 recommendations), "Grow" tab (full browser), Z Console proactive surfacing
- Scoring algorithm: revenue potential (40%) + ease of entry (25%) + seasonal relevance (20%) + strategic fit (15%)

### Key Dart Classes
- `GrowthAdvisorService` — scoring algorithm, opportunity matching, proactive trigger evaluation

### DB Tables
- `growth_opportunities` — curated content, READ-ONLY for contractors, managed by Tereda team
- `growth_opportunity_interactions` — tracks contractor engagement (viewed, saved, started, completed, dismissed)

### Build Phases

| Phase | Scope | Hours |
|-------|-------|:-----:|
| Phase 1 — Launch (seed content + basic UI) | Seed 40 opportunities, dashboard widget, detail view, basic matching | ~22 |
| Phase 2 — Intelligence (3 months post-launch) | Full scoring algorithm, Z AI triggers, seasonal rotation, "Grow" tab | ~26 |
| Phase 3 — Data Loop (6+ months) | Revenue impact tracking, quality scoring, content expansion, promoted listings | ~40 |
| **TOTAL** | | **~88** |

---

## EXPANSION SYSTEM: UNIFIED COMMAND CENTER (Source: Doc 40)

**Purpose:** Contractor operations hub — one inbox, one pipeline, one dashboard
**Full Spec:** `Expansion/40_UNIFIED_COMMAND_CENTER.md` (DRAFT)
**Inspiration:** Meta Business Suite operational philosophy, adapted for trade businesses

### Seven Concepts

| # | Concept | Summary |
|---|---------|---------|
| 1 | **Unified Lead Inbox** | Every channel (Google, Facebook, Instagram, SMS, email, Thumbtack, Angi, voicemail, web form, Nextdoor, Yelp) in one stream — 12 channels total |
| 2 | **Lead-to-Job Pipeline** | Visual Kanban board: New Lead -> Responded -> Estimate Scheduled -> Estimate Sent -> Accepted -> Job Created |
| 3 | **Service Catalog** | Company's services with pricing (range/fixed/quote-only) — powers auto-response, website, and client portal |
| 4 | **Project Showcase Engine** | Auto-generate before/after content from completed jobs, publish to Google/Facebook/Instagram/ZAFTO profile |
| 5 | **Business Command Dashboard** | Real-time KPIs: revenue today/week/month, close rate, avg response time, job pipeline value, overdue invoices |
| 6 | **Review & Reputation Engine** | Auto-send review requests post-job, monitor Google/Facebook/Yelp reviews, track ratings over time |
| 7 | **Cross-Channel Customer Identity** | Match leads across channels to single customer record (phone, email, name fuzzy matching) |

### Build Phases (12 Phases)

| Phase | What | Dependencies |
|-------|------|-------------|
| Phase 1 | Unified inbox — SMS + web form + manual entry | Twilio, webhook system |
| Phase 2 | Meta integration — Facebook + Instagram + Messenger | Meta Graph API approval |
| Phase 3 | Google Business Profile integration | Google Business API |
| Phase 4 | Z auto-response in inbox | Doc 35 Layer 1 + edge function |
| Phase 5 | Visual sales pipeline (Kanban) | Existing bids table |
| Phase 6 | Service catalog + client portal integration | Doc 16 ZAFTO Home |
| Phase 7 | Showcase engine — auto-generate from job photos | Meta Graph API, Google API |
| Phase 8 | Command dashboard with Z insights | All existing data + Doc 35 L5 |
| Phase 9 | Review request automation | Google/Facebook review links |
| Phase 10 | Cross-channel customer identity matching | customer_contacts schema |
| Phase 11 | Email/Thumbtack/Angi integrations | IMAP, email parsing |
| Phase 12 | Voicemail transcription integration | Whisper/Deepgram |

### Key DB Tables (New)
- `leads` — unified inbox leads before they become customers/jobs
- `service_catalog` — company services with pricing
- `project_showcases` — auto-generated from completed jobs
- `review_requests` — post-job review request tracking
- `reviews` — monitored reviews across platforms

---

## EXPANSION SYSTEM: Z CONSOLE + ARTIFACT SYSTEM (Source: Doc 41)

**Purpose:** Persistent 3-state AI interface that travels with the user across every screen
**Full Spec:** `Expansion/41_Z_CONSOLE_ARTIFACT_SYSTEM.md` (DRAFT)
**Cross-References:** Doc 35 (Universal AI Architecture), Doc 40 (Unified Command Center)

### Three States

| State | Name | Viewport | Description |
|-------|------|----------|-------------|
| 1 | **The Pulse** | 40x40px floating | Offset Echo Z mark, bottom-right, subtle glow pulse. Proactive insights slide left as frosted glass pills. |
| 2 | **The Console Bar** | 18-22% height | Frosted glass bar from bottom. Last 2-3 messages, contextual quick-action chips per screen, text + voice input. Page behind fully interactive. |
| 3 | **The Full Console** | 65-70% height | Deep work mode. Full conversation, artifact rendering, side-by-side document preview. |

### 14 Artifact Types
Bids, invoices, follow-up emails, scope of work, change orders, proposals, contracts, punch lists, daily reports, certificates of completion, warranty letters, lien notices, thank-you notes, review requests.

### Key Design Rules (15 Rules from Doc 41)
1. Z travels with you — console never unmounts, never loses state
2. Three states, fluid transitions — Pulse -> Bar -> Full
3. Glass, not walls — translucent backgrounds maintain spatial context
4. Templates are law — Z fills templates, Z does not invent document structures
5. Nothing ships without human approval — every outgoing artifact requires Confirm & Send
6. Every approval is logged forever — artifact_events is immutable
7. Edits reset approval — any change returns to draft
8. Conversation drives editing — contractors talk to Z to modify artifacts
9. Artifacts are always readable — light background, clean typography, print-ready
10. Design is invisible — if the user notices the UI, it is too loud
11. RBAC on artifacts — who can create, edit, approve, send
12. Proactive, not pushy — one insight at a time, no notification storms
13. Homeowner console is simpler — same architecture, different personality
14. Event logs protect everyone — immutable record
15. Speed is design — under 300ms transitions, under 2s artifact generation

### Build Phases (12 Phases)

| Phase | What | Dependencies |
|-------|------|-------------|
| Phase 1 | Console shell — three states, transitions, persistence | Root layout architecture |
| Phase 2 | Conversation UI — message rendering, input, voice | Edge function (Doc 35 Phase 1) |
| Phase 3 | Session context chips — per-screen quick actions | Layer 4 (Doc 35 Phase 2) |
| Phase 4 | Pulse — proactive insight surfacing | Realtime subscription |
| Phase 5 | Artifact rendering engine — template -> document | Template system + schema |
| Phase 6 | Conversational artifact editing | Edge function + artifact state management |
| Phase 7 | Approval flow + confirmation UI | Artifact events logging |
| Phase 8 | Event logging (immutable audit trail) | artifact_events table + RLS |
| Phase 9 | Default templates — bid, invoice, follow-up, scope | Template authoring |
| Phase 10 | Template customization UI | Settings screens |
| Phase 11 | Homeowner console variant | ZAFTO Home integration |
| Phase 12 | Visual polish — glass effects, animations, responsive | Design QA |

---

## EXPANSION SYSTEM: MEETING ROOM SYSTEM (Source: Doc 42)

**Purpose:** Context-aware video rooms built for trade professionals, not another Zoom clone
**Full Spec:** `Expansion/42_MEETING_ROOM_SYSTEM.md`
**Infrastructure:** LiveKit (open-source WebRTC SFU) + Deepgram (real-time transcription) + Claude API (meeting intelligence)
**Total Build: ~55-70 hours across 6 phases**

### Six Meeting Types

| Type | Purpose | Key Features |
|------|---------|-------------|
| **Site Walk** | Remote inspection, real-time camera + annotations | Rear camera, freeze-frame, flashlight, annotation tools |
| **Virtual Estimate** | Remote assessments instead of driving 45 minutes | Job context sidebar, live photo capture to gallery |
| **Document Review** | Review contracts, blueprints, estimates on-screen | Shared view, in-call markup, e-signature |
| **Team Huddle** | Internal crew standup, daily context | Auto-loads today's schedule + open items |
| **Insurance Conference** | Adjuster + contractor + homeowner | Role-based views (adjuster can't see margins) |
| **Async Video** | Loom-style walkthroughs with AI summary | Record, share link, view count tracking, reply threads |

### Key Features
- **Smart Room Context Engine:** Every room pre-loaded with job details, customer info, photos, estimates — role-based views per participant type
- **AI Meeting Intelligence:** Deepgram transcription → Claude summaries → action items → follow-up drafts → auto-update job record
- **Built-in Scheduling Engine:** Booking types, availability from calendar, public booking pages (replaces Calendly)
- **Phone-to-Video Escalation:** Telnyx SIP → LiveKit bridge — phone call escalates to video seamlessly
- **Zero-Download Client Join:** Browser link at `meet.zafto.cloud/{roomCode}` — no app, no account, no download

### Build Phases

| Phase | Scope | Hours |
|-------|-------|:-----:|
| Phase 1 — Core Video | LiveKit integration, 1-on-1 calls, browser join, basic recording | ~20 |
| Phase 2 — Smart Room + Site Walk | Context panel, freeze-frame + annotation, rear camera mode | ~15 |
| Phase 3 — Scheduling + Booking | Booking types, availability, public booking page, reminders | ~10 |
| Phase 4 — AI + Async | Transcription, summaries, action items, async video recording | ~12 |
| Phase 5 — Advanced | Multi-party, insurance conferences, phone escalation, in-call e-sign | ~8 |
| Phase 6 — Polish | Recording playback, meeting history, client portal embed, RBAC | ~5 |
| **TOTAL** | | **~55-70** |

### DB Tables (5 new)
- `meetings` — room records with LiveKit references, AI intelligence fields, scheduling
- `meeting_participants` — participant identity, role-based permissions, join tracking
- `meeting_captures` — freeze-frames, photos, annotations during calls
- `meeting_booking_types` — scheduling engine configuration (availability, duration, approval)
- `async_videos` — Loom-style videos with AI summary, share tokens, reply threads

### Edge Functions (13)
createMeetingRoom, generateMeetingToken, endMeeting, processRecording, transcribeMeeting, generateMeetingSummary, scheduleMeeting, getBookingAvailability, bookMeeting, sendMeetingReminder, processAsyncVideo, escalatePhoneToVideo, saveMeetingCapture

---

## EXPANSION SYSTEM: PHONE SYSTEM (Source: Doc 31)

**Purpose:** Full business phone system that runs through the ZAFTO app
**Full Spec:** `Expansion/31_PHONE_SYSTEM.md`
**Infrastructure:** Telnyx Programmable Voice + WebRTC (Twilio as fallback)
**Platform:** Flutter (iOS CallKit + Android ConnectionService)

### What This Replaces
- Company cell phones ($50-80/month per line)
- Separate work phones that techs lose/break
- Techs giving customers their personal number
- Expensive business phone services (RingCentral, Grasshopper, etc.)

### What This Costs
- Telnyx phone number: ~$1/month per line
- Voice minutes: ~$0.004/min (half of Twilio)
- Internal calls: $0 (VoIP over data/WiFi)
- 5-person company, moderate usage: ~$15-25/month total vs. 5 company phones at $250-400/month

### Why Telnyx Over Twilio
- Owns their own carrier network — no middlemen = better quality, lower cost
- Half the cost of Twilio for voice
- Direct carrier = lower latency calls
- `telnyx_flutter` package exists and is maintained
- Architecture: carrier abstracted behind Edge Functions. Swap to Twilio or Bandwidth without touching app code.

---

## EXPANSION SYSTEM: MARKETPLACE (Source: Doc 33)

**Purpose:** AI equipment diagnostics + pre-qualified lead generation
**Full Spec:** `Expansion/33_ZAFTO_MARKETPLACE.md`

### How It Works
1. Homeowner scans equipment (camera or model number entry)
2. AI identifies make, model, age, known failure patterns
3. Guided symptom capture with AI questions
4. Diagnosis delivered: probable issues ranked, urgency level, cost expectations
5. "Get quotes" generates pre-qualified lead with full equipment context

### Why This Is Different
- Angi/Thumbtack: homeowner says "I need help," contractor pays $25-75 for blind lead with zero context
- ZAFTO: lead includes exact equipment model, age, known issues, symptoms, photos, location
- Close rates go up. Lead value goes up. Contractor satisfaction goes up.

### The Trojan Horse
Contractors do not need to be on the platform to receive their first lead. They get an email ("Zafto Lead") with the pre-diagnosed work order. At the bottom: "Bid on this job through ZAFTO." They click, see the platform, see the CRM — and they sign up because revenue is already waiting.

### Existing Infrastructure Leveraged
- 5 AI scan functions (LIVE)
- Client Portal (21 pages — becomes ZAFTO Home)
- Equipment Passport (Doc 16 — digital twin)
- PhotoService (492 lines, built, unused)
- Claude API integration (configured)

---

## EXPANSION SYSTEM: BUSINESS OS (Source: Doc 27)

**Purpose:** 9 new core systems that transform ZAFTO from "CRM + Field Tools" into an inescapable business operating system
**Full Spec:** `Expansion/27_BUSINESS_OS_EXPANSION.md`

### The 9 Systems

| # | System | Key Moat |
|---|--------|----------|
| 1 | CPA/Accountant Portal | Distribution channel — every CPA brings 10-30 contractor clients |
| 2 | Payroll | Auto from time clock data, Check.com/Gusto processing |
| 3 | HR Suite | Employee records, onboarding, compliance, certifications |
| 4 | Training Platform | Trade-specific courses, certification tracking, LMS |
| 5 | Fleet Management | Vehicle tracking, maintenance schedules, fuel tracking |
| 6 | Route Optimization | Google Maps API, job clustering, drive time minimization |
| 7 | Procurement | Vendor management, PO generation, price comparison |
| 8 | VoIP Phone System | Telnyx-powered, full business phone (see Doc 31) |
| 9 | Email Marketing | SendGrid, campaigns, drip sequences, re-engagement |

**The lock-in:** Once a contractor uses payroll + fleet + procurement + phone + HR + marketing + accounting, the switching cost is infinite.

---

## EXPANSION SYSTEM: FIELD APP GAP ANALYSIS (Source: Doc 26)

**Purpose:** Complete audit of what is built vs. what is needed vs. what is spec'd
**Full Spec:** `Expansion/26_FIELD_APP_GAP_ANALYSIS.md`

### The Honest Picture

| Category | Status |
|----------|--------|
| 14 field tools | UI ONLY — save nothing, data evaporates on exit |
| 15 business screens | Mock data — no backend sync |
| Content layer | WORKING — 1,186 calculators, 111 diagrams, 5,080 exam Qs |
| 3 AI features | WIRED — Chat, Scanner, Contract Analyzer |
| 5 missing P0 tools | ~22 hrs — Materials Tracker, Daily Log, Punch List, Change Orders, Job Completion |

---

## DOC 36 — RESOLVED

> **`Locked/36_RESTORATION_INSURANCE_MODULE.md`** — **RECONSTRUCTED Feb 6, 2026** (756 lines). File was missing during Session 34 merge audit. Reconstructed from cross-references in Docs 37, 38, 39, and Master Build Plan. Contains: Restoration as 9th trade, insurance claims schema + per-trade workflows (17 stages restoration, 13 roofing, 10 general), Xactimate/ESX interop, carrier management, supplement engine, moisture monitoring, equipment tracking, drying logs (immutable legal documents), cross-trade insurance mode, three-payer accounting. 5 new tables (insurance_claims, claim_supplements, xactimate_estimate_lines, moisture_readings, restoration_equipment). ~78 hours across 3 phases + schema. **LOCKED.**

---

## DATA FLOW: THE SEAMLESS BUSINESS SYSTEM

```
+-------------------------------------------------------------------+
|                    SEAMLESS BUSINESS FLOW                          |
+-------------------------------------------------------------------+
|                                                                    |
|  +---------+     E-Sign      +---------+    Complete    +---------+
|  |   BID   | --------------> |   JOB   | -------------> | INVOICE |
|  +---------+                 +---------+                +---------+
|       |                           |                          |    |
|       | Deposit                   | Schedule                 |    |
|       v                           v                          v    |
|  +---------+               +----------+              +---------+  |
|  | STRIPE  |               | CALENDAR |              | STRIPE  |  |
|  +---------+               +----------+              +---------+  |
|       |                           |                          |    |
|       |                           v                          |    |
|       |                    +----------+                      |    |
|       +------------------->|   HOME   |<---------------------+    |
|         Stats              |  SCREEN  |         Stats             |
|                            +----------+                           |
|                                  |                                |
|                                  v                                |
|                           +----------+                            |
|                           | CONTRACT |  <-- Upload/Scan           |
|                           | ANALYZER |                            |
|                           +----------+                            |
|                                                                    |
+-------------------------------------------------------------------+
```

---

## PRICE BOOK (Company-Specific)

**Purpose:** Every company has their own pricing. AI must use it.

### Data Model

```
companies/{companyId}/priceBook/{itemId}
+-- id: string
+-- name: "1/2\" EMT Conduit"
+-- description: "10ft stick"
+-- category: "electrical_conduit"
+-- sku: "EMT-050-10"
|
+-- suppliers: [
|   { name: "Ferguson", partNumber: "12345", lastPrice: 4.50, lastUpdated: date },
|   { name: "Home Depot", partNumber: "SKU-789", lastPrice: 5.25, lastUpdated: date },
|   ]
|
+-- defaultCost: 4.50              // What you pay
+-- defaultPrice: 7.00             // What you charge
+-- markupPercent: 55
+-- unit: "each"
|
+-- trade: "electrical"
+-- tags: ["conduit", "emt", "raceway"]
+-- isActive: true
+-- lastUpdated: timestamp
+-- updatedBy: userId
```

### Import Methods

| Method | How It Works |
|--------|--------------|
| **CSV Import** | Upload spreadsheet from supplier |
| **PDF Scan** | AI extracts items/prices from price sheets |
| **Photo Scan** | Take photo of price list, AI reads it |
| **Manual Entry** | Add items one by one |
| **Duplicate & Edit** | Copy from templates, adjust prices |

### AI Integration (Critical)

When AI generates bids, estimates, or material lists:

```
1. AI identifies needed materials
2. AI searches company's Price Book first
3. If found -> use company's pricing
4. If not found -> suggest adding to Price Book
5. Never make up prices
```

**Context injection for AI:**
```dart
// When AI is helping with bids/estimates
final priceBookContext = await PriceBookService.search(
  companyId: company.id,
  query: identifiedMaterials,
);

// AI prompt includes:
"Use these prices from the company's Price Book:
${priceBookContext.map((item) => '${item.name}: \$${item.defaultPrice}/${item.unit}').join('\n')}

If a material isn't in the Price Book, note it as 'PRICE NEEDED' and suggest the user add it."
```

### Price Book UI

```
+-------------------------------------------------------------+
|  PRICE BOOK                        [+ Add Item] [Import]    |
+-------------------------------------------------------------+
|  Search: [conduit                    ]  Category: [All v]    |
+-------------------------------------------------------------+
|                                                              |
|  ELECTRICAL > CONDUIT                                        |
|  +-----------------------------------------------------+    |
|  | 1/2" EMT Conduit (10ft)                              |    |
|  | Cost: $4.50  ->  Price: $7.00  (55% markup)          |    |
|  | Ferguson, Home Depot         Updated: 2 days ago     |    |
|  +-----------------------------------------------------+    |
|  +-----------------------------------------------------+    |
|  | 3/4" EMT Conduit (10ft)                              |    |
|  | Cost: $6.25  ->  Price: $9.75  (56% markup)          |    |
|  | Ferguson                     Updated: 1 week ago     |    |
|  +-----------------------------------------------------+    |
|                                                              |
|  Items need attention:                                       |
|  WARNING: 12 items not updated in 30+ days                   |
|                                                              |
+-------------------------------------------------------------+
```

---

### Enterprise Tier Note

Enterprise customers (50+ employees) typically have:
- Dedicated accounting staff or CPA firms
- Existing accounting software they may want to keep
- Complex tax situations requiring professional oversight

**Strategy:** ZAFTO Books is the system of record for ALL tiers including Enterprise. Enterprise gets multi-entity support, CPA Accountant Portal, and full export capability (QBO, CSV, PDF, JSON) so their CPA or accounting firm can import into whatever they use. No live sync — export compatibility. If an Enterprise client's CPA insists on QuickBooks, ZAFTO exports clean QBO files monthly (auto-scheduled). The CPA gets better data from ZAFTO's export than they'd ever get from the contractor manually entering into QuickBooks.

### Game Changers (8 Features)

| # | Feature | Phase | Description |
|---|---------|:-----:|-------------|
| 1 | AI Field Mentor | P7 | Voice + camera assistant |
| 2 | Market Pricing Intelligence | P7 | Area pricing data |
| 3 | Instant Client Financing | P8 | Built into bids |
| 4 | Labor Marketplace | P8 | Uber for trade labor |
| 5 | Supplier Price Comparison | P9 | Compare all suppliers |
| 6 | AI Code Compliance | P9 | Photo -> code check |
| 7 | AI Calculator (Hybrid) | P7 | Natural language calcs (Claude-powered) |
| 8 | AI Contract Review | P0 | DONE - Red flags, analysis |

---

## CONSOLIDATED MASTER BUILD ORDER

> **Source: Docs 32, 34, 37, 38, 39 build phases merged into unified sequence.**

```
MASTER BUILD SEQUENCE:
======================================================================

PRE-LAUNCH (CRITICAL PATH):
----------------------------------------------------------------------
1.  DevOps Phase 1 (environments + secrets)                    ~2 hrs       [Doc 32]
2.  Database Migration (Supabase + RLS + PowerSync)             ~17-25 hrs   [Doc 29]
3.  Wire W1-W6 (core business -> field tools -> CRM -> portal)  ~120 hrs     [Doc 25]
4.  DevOps Phase 2 (Sentry + tests + CI/CD)                    ~8-12 hrs    [Doc 32]
5.  Job Type System — Schema + Phase 1 UI                       ~20 hrs      [Doc 37]
6.  Insurance Verticals — Phase 1 (ships with 36+37)            ~15 hrs      [Doc 38]
7.  OPS PORTAL PHASE 1 (accounts + support + inbox + health)    ~40 hrs      [Doc 34]

LAUNCH
----------------------------------------------------------------------

POST-LAUNCH MONTH 1:
----------------------------------------------------------------------
8.  Job Type System — Phase 2 (dashboard + Books integration)   ~13 hrs      [Doc 37]
9.  Insurance Verticals — Phase 2 (storm, canvassing, warranty) ~29 hrs      [Doc 38]
10. Growth Advisor — Phase 1 (seed content + basic UI)          ~22 hrs      [Doc 39]
11. OPS PORTAL PHASE 2 (marketing engine + growth + treasury)   ~45-57 hrs   [Doc 34]

MONTHS 2-3:
----------------------------------------------------------------------
12. Growth Advisor — Phase 2 (intelligence + Z triggers)        ~26 hrs      [Doc 39]
13. Business OS Expansion (9 systems)                           Ongoing      [Doc 27]
14. Unified Command Center (12 phases)                          TBD          [Doc 40]
15. Z Console + Artifact System (12 phases)                     TBD          [Doc 41]
16. OPS PORTAL PHASE 3 (legal + dev terminal + ads + analytics) ~45-49 hrs   [Doc 34]

MONTHS 6+:
----------------------------------------------------------------------
17. Insurance Verticals — Phase 3 (territory, APIs)             ~63 hrs      [Doc 38]
18. Job Type System — Phase 3 (warranty company APIs)           ~36 hrs      [Doc 37]
19. Growth Advisor — Phase 3 (data loop + monetization)         ~40 hrs      [Doc 39]
20. Phone System (Telnyx VoIP)                                  TBD          [Doc 31]
20.5 Meeting Room System (context-aware video)                   ~55-70 hrs   [Doc 42]
21. Website Builder V2 (Cloudflare Registrar)                   ~15-20 hrs   [Doc 28]
22. ZAFTO Home Platform Features                                TBD          [Doc 16]
23. Marketplace Launch                                          TBD          [Doc 33]
24. OPS PORTAL PHASE 4 (marketplace ops)                        ~17 hrs      [Doc 34]

======================================================================
ESTIMATED TOTAL HOURS:
  Core wiring + DevOps + launch:              ~167-179 hrs
  Job Types + Insurance + Growth (launch):    ~57 hrs
  Ops Portal (all 4 phases):                  ~163 hrs
  Insurance Verticals (all 3 phases):         ~107 hrs
  Job Type System (all 3 phases):             ~69 hrs
  Growth Advisor (all 3 phases):              ~88 hrs
  Website Builder V2:                         ~15-20 hrs
  Meeting Room System:                        ~55-70 hrs
  Mobile Field Toolkit:                       ~89-107 hrs
  Command Center + Z Console + Phone:         TBD (draft specs)
  Business OS (9 systems):                    TBD (ongoing)
  -------------------------------------------------------
  KNOWN TOTAL:                                ~810-902+ hrs
======================================================================
```

---

## BUILD PRIORITY SUMMARY

| Phase | Focus | Status |
|-------|-------|--------|
| **P0** | Core Business (Bid/Job/Invoice/Calendar/Contract Analyzer) | DONE |
| **P1** | Cloud Functions + Web Portal + Client Portal | CRM DONE, CLIENT PORTAL DONE |
| **P1** | Debug & Polish (CRM + Client Portal) | AFTER WIRING |
| **P1** | Wire Supabase | NEXT — execute `Locked/29_DATABASE_MIGRATION.md` first |
| **--** | DevOps Phase 1 (environments + secrets) | DO FIRST (~2 hrs) — Doc 32 |
| **--** | ZAFTO Home Platform (homeowner features) | SPEC COMPLETE — `Expansion/16_ZAFTO_HOME_PLATFORM.md` |
| **P2** | Field Tools (14) + Logo Creator + Two-Way SMS | DONE (tools) / TODO (rest) |
| **P3** | Website Builder + 40 Templates + Review Automation | PLANNED |
| **P4** | License/Insurance, Permit, Warranty, Time Clock | PLANNED |
| **P5** | Inventory, Accounts Payable, Subcontractor Management | PLANNED |
| **P6** | Blueprint Viewer, Team Chat | PLANNED |
| **P7** | AI Field Mentor, Market Intel, Lead Scoring | PLANNED |
| **P8** | Financing, Labor Marketplace, Route Optimization | PLANNED |
| **P9** | Supplier Integration, Code Compliance Checker | PLANNED |
| **P10** | Lien Calendar, COI Generator, Equipment Rental, Tax Estimator | PLANNED |
| **EXP** | Job Type System (standard/insurance/warranty) | SPEC LOCKED — Doc 37 (~69 hrs) |
| **EXP** | Insurance Contractor Verticals (4 verticals) | SPEC DONE — Doc 38 (~107 hrs) |
| **EXP** | Growth Advisor (AI revenue expansion) | SPEC DONE — Doc 39 (~88 hrs) |
| **EXP** | Unified Command Center (7 concepts) | DRAFT — Doc 40 |
| **EXP** | Z Console + Artifacts (3-state persistent AI) | DRAFT — Doc 41 |
| **EXP** | Phone System (Telnyx VoIP) | SPEC DONE — Doc 31 |
| **EXP** | Universal AI Architecture (6 layers) | SPEC DONE (draft reviewed) — Doc 35 |
| **EXP** | Meeting Room System (context-aware video) | SPEC DONE — Doc 42 (~55-70 hrs) |
| **EXP** | Mobile Field Toolkit (24 tools, walkie-talkie) | SPEC DONE — Doc 43 (~89-107 hrs) |
| **EXP** | Marketplace (AI diagnostics + leads) | SPEC DONE — Doc 33 |
| **EXP** | Business OS (9 systems) | SPEC DONE — Doc 27 |
| **LAST** | Ops Portal / Founder OS (72 pages) | SPEC LOCKED — Doc 34 (~163 hrs) |

---

## INTEGRATIONS

| Integration | Purpose | Phase |
|-------------|---------|:-----:|
| **Stripe** | Payments (deposits, invoices, subscriptions) | P1 |
| **Supabase** | Database, Auth, Edge Functions, Storage, Realtime | MIGRATION PENDING |
| **Plaid** | Bank connections for Zafto Books | P1 |
| **Cloudflare** | DNS, website hosting, WAF, domain registrar (V2) | P3 |
| **Claude/Opus 4.5** | AI features (Universal 6-layer architecture — Doc 35) | P0+ |
| **Telnyx** | VoIP phone system (primary carrier — Doc 31) | FUTURE |
| **Twilio** | SMS (two-way texting, job updates) + VoIP fallback | P2 |
| **SendGrid** | Email campaigns, transactional email | P2+ |
| **QuickBooks/Xero** | Export compatibility only (QBO/CSV) — NO live sync | P1 |
| **Google Maps** | Route optimization, address validation | P8 |
| **Financing API** | Wisetack/Greensky | P8 |
| **Supplier APIs** | Pricing and ordering | P9 |
| **Meta Graph API** | Facebook/Instagram integration (Command Center — Doc 40) | FUTURE |
| **Google Business API** | Google Business Profile integration (Command Center — Doc 40) | FUTURE |
| **Whisper/Deepgram** | Voicemail transcription (Command Center — Doc 40) + Meeting transcription (Doc 42) | FUTURE |
| **LiveKit** | WebRTC video rooms (Meeting Room System — Doc 42) — open-source SFU, self-hostable | FUTURE |
| **Check.com / Gusto** | Payroll processing (Business OS — Doc 27) | FUTURE |

### Plaid Integration Details

**Purpose:** Bank account connections for built-in financial tracking
**Pricing:** ~$0.30-$1.50 per connected account/month (volume discounts)
**Effort:** 1-2 days to integrate

```
User Flow:
1. User taps "Connect Bank" in Settings -> Integrations
2. Plaid Link opens (their pre-built UI)
3. User selects bank, logs in
4. Transactions flow into Zafto automatically

Data We Get:
- Transaction history (typically 2 years)
- Account balances
- Transaction categories (Plaid auto-categorizes)
- Merchant names
```

---

## PRICING MODEL

| Tier | Price | Users | Includes |
|------|-------|:-----:|----------|
| **Solo** | $19.99 one-time | 1 | App, basic website, local storage |
| **Pro** | $29.99/month | 1 | Cloud sync, web portal, all templates |
| **Team** | $79.99/month | 5 | Multi-user, basic roles, dispatch |
| **Business** | $149.99/month | 15 | Full roles, live map, geofencing, advanced reports |
| **Enterprise** | Custom | Unlimited | Custom permissions, API, SSO, dedicated support |

**Add-ons:**
- Custom domain: $14.99/yr (via Cloudflare Registrar — Doc 28)
- Website builder: $19.99/mo (Doc 28)
- Additional trades: $9.99 each

---

## USER ROLES & PERMISSIONS

### 6 Roles (Updated — Doc 30)

| Role | Who | Access Level |
|------|-----|--------------|
| **Owner** | Business owner | Everything + billing + delete company |
| **Admin** | Partner, manager | Everything except billing |
| **Office** | Office staff | Customers, bids, jobs, invoices (no costs/margins) |
| **Field Tech** | Employee technician | Assigned jobs + calculators + field tools |
| **Subcontractor** | External sub | Their assigned work only |
| **CPA** | External accountant | Financial data across their contractor clients (Doc 27) |

> **Note:** `super_admin` role exists for Ops Portal only (Doc 34). Cross-tenant read, restricted write, MFA required.

### Permission Matrix

| Feature | Owner | Admin | Office | Field Tech | Sub | CPA |
|---------|:-----:|:-----:|:------:|:----------:|:---:|:---:|
| View all jobs | Y | Y | Y | N | N | N |
| View assigned jobs | Y | Y | Y | Y | Y | N |
| Create/edit jobs | Y | Y | Y | N | N | N |
| View all customers | Y | Y | Y | N | N | N |
| View assigned customer | Y | Y | Y | Y | Y | N |
| Create customers | Y | Y | Y | N | N | N |
| Create/send bids | Y | Y | Y | N | N | N |
| View/send invoices | Y | Y | Y | N | N | N |
| View costs/margins | Y | Y | N | N | N | Y |
| View reports | Y | Y | Limited | N | N | Y |
| Manage team | Y | Y | N | N | N | N |
| Company settings | Y | Y | N | N | N | N |
| Billing/subscription | Y | N | N | N | N | N |
| Calculators | Y | Y | Y | Y | Y | N |
| Field tools | Y | Y | Y | Y | Y | N |
| AI assistant | Y | Y | Y | Y | Limited | N |
| Financial data (Books) | Y | Y | N | N | N | Y |

### Company-Level Settings (Owner/Admin Controls)

```
Settings -> Team Permissions

Field Techs can see:
  [x] Job total value
  [ ] Cost breakdown
  [ ] Profit margin
  [ ] Customer phone/email (beyond assigned)

Subcontractors can see:
  [ ] Job total value
  [ ] Customer contact info
  [ ] Other team members on job

Office Staff can see:
  [x] Revenue totals
  [ ] Cost breakdown
  [ ] Profit margins
```

### Progressive Disclosure

| Tier | Team Features Visible |
|------|----------------------|
| Solo | None - clean single-user experience |
| Pro | None - still single user |
| Team | Invite + simple role picker |
| Business | Full team management + custom permissions |
| Enterprise | Custom roles + API user management |

---

## KEY FILES INDEX

### Services (Mobile App)
| File | Purpose |
|------|---------|
| `lib/services/bid_service.dart` | Bid CRUD + sync |
| `lib/services/job_service.dart` | Job CRUD + sync |
| `lib/services/invoice_service.dart` | Invoice CRUD + sync |
| `lib/services/customer_service.dart` | Customer CRUD + sync |
| `lib/services/calendar_service.dart` | Schedule aggregation |
| `lib/services/stripe_service.dart` | Payment processing |
| `lib/services/pdf_service.dart` | PDF generation |
| `lib/services/contract_analyzer_service.dart` | AI contract review |
| `lib/services/field_camera_service.dart` | Camera + GPS |

### Screens (Mobile App)
| Path | Purpose |
|------|---------|
| `lib/screens/bids/` | Bid hub, create, detail, builder |
| `lib/screens/jobs/` | Job hub, detail |
| `lib/screens/invoices/` | Invoice hub, create, detail |
| `lib/screens/calendar/` | Calendar views |
| `lib/screens/field_tools/` | 14 field tools |
| `lib/screens/contract_analyzer/` | Contract review UI |
| `lib/screens/home_screen_v2.dart` | Main dashboard |

### Documentation
| File | Purpose |
|------|---------|
| `00_MASTER_BUILD_PLAN.md` | THIS FILE - Single source of truth |
| `00_LIVE_STATUS.md` | Quick status updates |
| `05_HANDOFF.md` | Session continuity — full page inventory |
| `03_BUILD_STATUS.md` | Detailed progress |
| `Locked/11_DESIGN_SYSTEM.md` | Design system v2.6 (LOCKED) — Offset Echo Z logo, 10 themes, SF Pro Display, Lucide icons |
| `15_CLIENT_PORTAL.md` | Client Portal spec (21 pages) |
| **`Expansion/16_ZAFTO_HOME_PLATFORM.md`** | **ZAFTO Home — Homeowner platform + Contractor Trust Architecture + Zafto Books Appendices G-J** |
| `17_TOOLBOX_INVENTORY.md` | Field tools spec |
| `20_WEBSITE_BUILDER.md` | Website builder spec (V1 — superseded by V2) |
| `22_COMPETITIVE_ANALYSIS.md` | Competitor research |
| **`Expansion/23_AI_INTEGRATION_SPEC.md`** | **Z AI - Original architecture (threads, tiers, tools, context). See also Doc 35 for updated 6-layer architecture.** |
| `24_UNIVERSAL_BID_SYSTEM.md` | Bid system spec |
| **`25_CIRCUIT_BLUEPRINT.md`** | **WIRING DIAGRAM — Every screen, every pipe. UPDATE AS YOU WIRE.** |
| **`Expansion/26_FIELD_APP_GAP_ANALYSIS.md`** | **Field app built vs missing vs spec'd. 14 tools UI only, 5 missing P0 tools.** |
| **`Expansion/27_BUSINESS_OS_EXPANSION.md`** | **9 systems, 50 collections, 60 functions. The inescapable business OS.** |
| **`Expansion/28_WEBSITE_BUILDER_V2.md`** | **Cloudflare Registrar, strict templates, $19.99/mo. Supersedes Doc 20.** |
| **`Locked/29_DATABASE_MIGRATION.md`** | **LOCKED. Firebase -> Supabase/PostgreSQL. Schema, RLS, PowerSync. ~17-25 hrs.** |
| **`Locked/30_SECURITY_ARCHITECTURE.md`** | **LOCKED. 6 layers. RLS, audit, encryption. Permission matrix. 6 roles + super_admin.** |
| **`Expansion/31_PHONE_SYSTEM.md`** | **Telnyx VoIP. Full business phone replacement. ~$0.004/min.** |
| **`Locked/32_DEVOPS_INFRASTRUCTURE.md`** | **LOCKED. CI/CD, 3 environments, Sentry, GitHub Actions. ~10-14 hrs.** |
| **`Expansion/33_ZAFTO_MARKETPLACE.md`** | **AI equipment diagnostics + lead generation. Trojan horse for contractor acquisition.** |
| **`Locked/34_OPS_PORTAL.md`** | **LOCKED. Founder OS. 72 pages, ~163 hrs, 4 phases. ops.zafto.cloud. Build LAST.** |
| **`Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md`** | **DRAFT (reviewed). 1 AI, 6 layers, 4 personas. Content overhaul: calcs/exams removed.** |
| **`Locked/36_RESTORATION_INSURANCE_MODULE.md`** | **LOCKED (RECONSTRUCTED). Restoration as 9th trade + cross-trade insurance engine. 756 lines, ~78 hrs. 5 tables (insurance_claims, claim_supplements, xactimate_estimate_lines, moisture_readings, restoration_equipment).** |
| **`Locked/37_JOB_TYPE_SYSTEM.md`** | **LOCKED. 3 job types, progressive disclosure, warranty dispatch. ~69 hrs.** |
| **`Expansion/38_INSURANCE_CONTRACTOR_VERTICALS.md`** | **4 verticals (storm, reconstruction, commercial, warranty). ~107 hrs. Extends Docs 36+37.** |
| **`Expansion/39_GROWTH_ADVISOR.md`** | **AI revenue expansion. 3 layers, per-trade opportunity catalogs. ~88 hrs.** |
| **`Expansion/40_UNIFIED_COMMAND_CENTER.md`** | **DRAFT. 7 concepts, 12 phases. Unified lead inbox (12 channels). Meta Business Suite philosophy.** |
| **`Expansion/41_Z_CONSOLE_ARTIFACT_SYSTEM.md`** | **DRAFT. Persistent 3-state AI console + 14 artifact types. 12 phases. 15 design rules.** |
| **`Expansion/42_MEETING_ROOM_SYSTEM.md`** | **Context-aware video rooms. 6 meeting types, Smart Room context, AI intelligence (Deepgram + Claude), scheduling engine, phone-to-video (Telnyx SIP → LiveKit). ~55-70 hrs.** |
| **`Expansion/43_MOBILE_FIELD_TOOLKIT.md`** | **25 mobile tools for multi-trade platform. Walkie-talkie/PTT, team chat, inspection checklists, moisture logger, drying logs, site survey, field measurements. ~89-107 hrs.** |

---

## SUCCESS CRITERIA

### Before App Store Launch
- [x] All 1,186 calculators working
- [x] All 14 field tools working
- [x] Bid -> Job -> Invoice flow complete (mobile)
- [x] Calendar displaying jobs (basic - needs permission filtering)
- [x] PDF generation working
- [x] Stripe payments working
- [x] Time clock with GPS working
- [ ] DevOps Phase 1 complete (environments + secrets — Doc 32)
- [ ] Database migration to Supabase complete
- [ ] RLS policies verified (tenant isolation)
- [ ] RBAC enforcement (assigned jobs only for field techs)
- [ ] Offline mode tested (PowerSync)
- [ ] Job type system working (standard + insurance + warranty — Doc 37)
- [ ] Flutter build iOS successful
- [ ] Flutter build Android successful

### Before Web Portal Launch
- [ ] Wire Supabase (replace mock data)
- [x] Build all CRM pages (40 pages complete)
- [x] Build Client Portal (21 pages complete)
- [ ] RBAC enforcement (UI + RLS query filtering)
- [x] Command palette works (Cmd+K)
- [x] Theme system (light/dark — both apps)
- [ ] Real-time sync with mobile data (Supabase Realtime)
- [ ] Responsive (tablet + desktop)
- [ ] Sub-2-second page loads
- [ ] DevOps Phase 2 complete (Sentry + CI/CD — Doc 32)

### Before Expansion Launch
- [ ] Universal AI Architecture functional (6 layers — Doc 35)
- [ ] Z Console operational (3 states — Doc 41)
- [ ] Unified Lead Inbox live (at least SMS + web form — Doc 40)
- [ ] Insurance claims workflow functional (Doc 37 + Doc 38)
- [ ] Warranty dispatch workflow functional (Doc 37)
- [ ] Growth Advisor Phase 1 live (seed content + basic matching — Doc 39)
- [ ] Phone system operational (Telnyx VoIP — Doc 31)
- [ ] Website Builder V2 operational (Cloudflare Registrar — Doc 28)
- [ ] Meeting Room System operational (LiveKit video, scheduling, AI intelligence — Doc 42)

### Before Ops Portal Launch
- [ ] Ops Portal Phase 1 complete (accounts + support + health — Doc 34)
- [ ] super_admin role configured with cross-tenant read + audit logging
- [ ] All 17+ replaced tools accessible from ops.zafto.cloud

---

## CRITICAL RULES

1. **This document (00_MASTER_BUILD_PLAN.md) is the single source of truth**
2. **NO EMOJIS** - Lucide icons only
3. **Design System v2.6 is LOCKED** - No changes. 10 themes, Offset Echo Z logo. See `Locked/11_DESIGN_SYSTEM.md`.
4. **Offline-first architecture** - PowerSync (SQLite <-> PostgreSQL)
5. **iOS app first** - Web portal enhances, not replaces
6. **"Linear meets Stripe for Trades"** - Premium feel, not cheap
7. **Database: Supabase PostgreSQL. No Firebase. Fully decommissioned.**
8. **Build order:** DEVOPS PHASE 1 -> MIGRATE DATABASE -> WIRE SUPABASE -> DEBUG WITH REAL DATA
9. **Security: Built into migration.** RLS on every table. 6 layers. See `Locked/30_SECURITY_ARCHITECTURE.md`.
10. **`Locked/29_DATABASE_MIGRATION.md`** — Execute BEFORE any wiring begins.
11. **Job types control everything.** `standard`, `insurance_claim`, `warranty_dispatch`. Progressive disclosure. See `Locked/37_JOB_TYPE_SYSTEM.md`.
12. **One AI brain, six layers.** All AI goes through single edge function. See `Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md`.
13. **Nothing ships without human approval.** Every AI-generated artifact requires Confirm & Send. See `Expansion/41_Z_CONSOLE_ARTIFACT_SYSTEM.md`.
14. **Ops Portal builds LAST.** All customer-facing features wired + debugged first. See `Locked/34_OPS_PORTAL.md`.
15. **Carrier abstracted.** Telnyx is primary VoIP but abstracted behind Edge Functions. Swap carriers without touching app code. See `Expansion/31_PHONE_SYSTEM.md`.
16. **Website templates are strict.** Cannot be made ugly. AI fills content, not structure. See `Expansion/28_WEBSITE_BUILDER_V2.md`.
17. **Contractor Trust Architecture before ZAFTO Home.** Six principles protect contractor relationships. See `Expansion/16_ZAFTO_HOME_PLATFORM.md`.
18. **Doc 36 RESOLVED.** Reconstructed Feb 6 — `Locked/36_RESTORATION_INSURANCE_MODULE.md` (756 lines, ~78 hrs). LOCKED.
19. **LOCKED docs cannot be modified** without explicit session approval: Docs 11, 29, 30, 32, 34, 36, 37.
20. **Draft docs (35, 40, 41) require review** before implementation begins. Do not build from drafts without consolidation.

---

## CHANGELOG

| Date | Change |
|------|--------|
| 2026-02-06 | **Doc 43 CREATED.** `Expansion/43_MOBILE_FIELD_TOOLKIT.md` — 25 mobile tools for multi-trade platform. 12 universal (6 existing + 6 new), 5 communication (phone, video, walkie-talkie/PTT, team chat, client messaging), 5 insurance/restoration (moisture logger, drying log, equipment tracker, claim camera, Xactimate viewer), 3 inspection (checklist, safety, site survey). Walkie-talkie: LiveKit audio rooms, persistent floating PTT button, job/crew/company/direct channels, 4 logging modes. 8 new tables, 8 Edge Functions. ~89-107 hrs across 6 phases. |
| 2026-02-06 | **Doc 42 CREATED.** `Expansion/42_MEETING_ROOM_SYSTEM.md` — context-aware video rooms for trades. 6 meeting types, Smart Room context engine, AI meeting intelligence (Deepgram + Claude), built-in scheduling engine, phone-to-video escalation (Telnyx SIP → LiveKit), zero-download browser join. 5 tables, 13 Edge Functions. ~55-70 hrs across 6 phases. Added to all root docs. Multi-channel job posting & hiring system added to Doc 28 (Website Builder V2). |
| 2026-02-06 | **Doc 36 RESOLVED.** `Locked/36_RESTORATION_INSURANCE_MODULE.md` reconstructed (756 lines, ~78 hrs) from cross-references in Docs 37, 38, 39. Doc 36 gap note resolved across all root docs (Handoff, Live Status, Circuit Blueprint, Master Build Plan). Locked/ file count updated from 4 to 7. Build hours updated. |
| 2026-02-05 | **Session 34: FULL EXPANSION MERGE.** Merged ALL content from 18 source documents (Docs 11, 16, 23, 26-35, 37-41) into this Master Build Plan. Added URL structure updates (ops.zafto.cloud, status.zafto.app). Added 11 new expansion system sections (DevOps, Ops Portal, Universal AI, Job Types, Insurance Verticals, Growth Advisor, Command Center, Z Console, Phone System, Marketplace, Business OS, Field App Gap Analysis). Updated Key Files Index with ALL docs 29-41. Added Doc 36 gap note (file referenced but not found on disk). Created consolidated master build order with ALL hours (~666-725+ hrs known). Updated Feature Matrix with phone, website, insurance, warranty, growth, Z Console. Updated roles to 6 (added CPA). Updated Critical Rules from 10 to 20. Updated Success Criteria with expansion milestones. |
| 2026-02-05 | **Session 30: RESTORATION & INSURANCE MODULE.** Added Restoration/Mitigation as 9th trade. Created `Locked/36_RESTORATION_INSURANCE_MODULE.md` — complete spec for insurance claims module (cross-trade), Xactimate ESX file interoperability (import/export), moisture mapping, drying logs, supplement engine, 45 calculators, equipment tracking. ESX interop is the crown jewel — DMCA 1201(f) legal basis. Full Supabase schema with RLS. Competitive kill chart shows ZAFTO replaces $450-750/month in restoration software stack. Waiting on Robert to retrieve XML files + raw ESX for decryption tool recreation. |
| 2026-02-05 | **Session 29: DATABASE MIGRATION + SECURITY ARCHITECTURE.** Firebase fully decommissioned — everything moves to Supabase/PostgreSQL. Created `Locked/29_DATABASE_MIGRATION.md` (full schema, RLS, PowerSync, security tables). Created `Locked/30_SECURITY_ARCHITECTURE.md` (6 layers, permission matrix, attack prevention). Created `Expansion/27_BUSINESS_OS_EXPANSION.md` (9 systems, 50 collections, 60 functions). Created `Expansion/28_WEBSITE_BUILDER_V2.md` (Cloudflare Registrar, strict templates, $19.99/mo). Updated architecture diagram, build order, success criteria, all Firebase references removed. |
| 2026-02-04 | **Session 27C: CLIENT PORTAL REDESIGN + ZAFTO HOME SPEC.** Replaced orange branding with Stripe purple (#635bff). Built Offset Echo Z logo component. Added dark/light mode. Full CSS variable theme system. Tailwind v4 @theme remaps auto-theme all 21 pages. Created `Expansion/16_ZAFTO_HOME_PLATFORM.md` — homeowner-owned property intelligence platform with Contractor Trust Architecture. Updated architecture diagram, Phase 3, and all status docs. |
| 2026-02-04 | **Session 27B: CLIENT PORTAL PAGES 9-21.** Built remaining 13 pages. Fixed Tailwind CSS v4 configuration. |
| 2026-02-04 | **Session 27A: CLIENT PORTAL SPEC + PAGES 1-8.** Created `15_CLIENT_PORTAL.md`. Scaffolded Next.js project. Built first 8 pages. |
| 2026-02-04 | **Session 26B: 5 AI MOAT FEATURES.** Built Z Voice, Bid Brain, Job Cost Radar, Equipment Memory, Revenue Autopilot. Total CRM pages: 35 -> 40. |
| 2026-02-03 | **Session 26: AUTOMATIONS + SIDEBAR.** Complete Automations page. 13 new sidebar items. 6 grouped sections. |
| 2026-02-03 | **Session 25: 13 NEW CRM PAGES.** Leads, POs, Vendors, Inventory, Equipment, Comms, Docs, Service Agreements, Warranties, Permits, Change Orders, Inspections. |
| 2026-02-03 | **Session 24: FULL CODEBASE AUDIT.** Corrected major doc errors. Time Clock IS built. Web Portal uses 100% mock data. RBAC models exist but enforcement missing. |

---

*This is Zafto. The most comprehensive trade platform ever built. Nothing else comes close.*
