# 53 — ZAFTO REALTOR PLATFORM SPEC

**Created:** S129 (Feb 16, 2026)
**Owner Directive:** "Zafto Contractor + Zafto Realtor — equal depth. Same tools, same AI, same quality. Beat everything on the market and go further. Nothing corny. Real tools they pay thousands for."
**Research:** `memory/realtor-platform-deep-research-s129.md`, `memory/proptech-flagship-research-s128.md`

---

## TABLE OF CONTENTS

1. [Architecture Overview](#1-architecture-overview)
2. [RBAC Hierarchy & Permissions](#2-rbac-hierarchy--permissions)
3. [Portal Map — What Each Role Sees](#3-portal-map)
4. [Mobile App Integration (Flutter)](#4-mobile-app-integration)
5. [Realtor Portal (Next.js)](#5-realtor-portal)
6. [Flagship Engine 1: Smart CMA Engine](#6-smart-cma-engine)
7. [Flagship Engine 2: Autonomous Transaction Engine](#7-autonomous-transaction-engine)
8. [Flagship Engine 3: Seller Finder Engine](#8-seller-finder-engine)
9. [Full CRM — Contact & Lead Management](#9-full-crm)
10. [Commission Engine](#10-commission-engine)
11. [Listing Management](#11-listing-management)
12. [Buyer Management](#12-buyer-management)
13. [Dispatch Engine — Contractors & Inspectors](#13-dispatch-engine)
14. [Property Management (Shared from D5)](#14-property-management)
15. [Recon Integration](#15-recon-integration)
16. [Sketch Engine Access](#16-sketch-engine-access)
17. [Lead Generation Pipeline](#17-lead-generation-pipeline)
18. [Marketing Factory](#18-marketing-factory)
19. [Brokerage Admin Panel](#19-brokerage-admin-panel)
20. [Cross-Platform Intelligence Sharing](#20-cross-platform-sharing)
21. [AI Integration (Phase E)](#21-ai-integration)
22. [Zafto Ledger for Realtors](#22-zafto-ledger)
23. [Settings Architecture](#23-settings-architecture)
24. [Database Schema](#24-database-schema)
25. [Lifecycle Workflows](#25-lifecycle-workflows)
26. [MLS Integration Strategy](#26-mls-integration)
27. [Revenue Model](#27-revenue-model)
28. [Sprint Breakdown](#28-sprint-breakdown)

---

## 1. ARCHITECTURE OVERVIEW

### The Principle
Zafto Realtor is NOT a separate product bolted onto Zafto Contractor. It is the SAME platform with a different lens. One database. One auth system. One Flutter app. One Supabase backend. The realtor portal is a 6th Next.js app that shares the same database, same Edge Functions, same storage buckets as the contractor CRM.

### App Map (After Realtor Addition)

```
FLUTTER (Mobile — ONE app, role-based screens)
├── Contractor roles: owner, admin, office, tech, inspector, apprentice
├── Realtor roles: brokerage_owner, managing_broker, team_lead, realtor, tc, isa
├── Shared roles: cpa, client, tenant
└── Dispatched roles: contractor uses tech role scoped to realtor's company

NEXT.JS PORTALS (6 apps — one Supabase backend)
├── web-portal/       → Contractor CRM (zafto.cloud)
├── realtor-portal/   → Realtor CRM (realtor.zafto.cloud)      ← NEW
├── team-portal/      → Field employee PWA (team.zafto.cloud)
├── client-portal/    → Homeowner portal (client.zafto.cloud)
├── ops-portal/       → Founder dashboard (ops.zafto.cloud)
└── [future] investor-portal/ → Deal sharing (deals.zafto.cloud)

SUPABASE (ONE database, ONE auth, ONE storage)
├── ~201 existing tables (contractor side)
├── ~40-60 new tables (realtor features)
├── Shared tables: properties, users, companies, notifications, storage
└── RLS: company_id scoping (same pattern, same helpers)
```

### Why ONE App, Not Two
- Contractors and realtors work TOGETHER on the same properties
- A contractor dispatched by a realtor uses the SAME Flutter app with their field tools
- An inspector dispatched by a realtor uses the SAME inspection engine
- Cross-platform data sharing works because it's the SAME database
- Maintenance: one codebase, not two. One deploy, not two.

### Company Type Distinction
```sql
-- companies table gets a new column
ALTER TABLE companies ADD COLUMN company_type text NOT NULL DEFAULT 'contractor'
  CHECK (company_type IN ('contractor', 'realtor_solo', 'realtor_team', 'brokerage'));
```

This column drives:
- Which portal the company's users log into (contractor CRM vs realtor CRM)
- Which features are available
- Which onboarding flow runs
- Which subscription tier applies
- Which dashboard shows on mobile

---

## 2. RBAC HIERARCHY & PERMISSIONS

### Realtor Roles (New)

```dart
// Added to UserRole enum in lib/core/user_role.dart
enum UserRole {
  // Existing contractor roles
  owner, admin, office, tech, inspector, apprentice, cpa,

  // New realtor/brokerage roles
  brokerageOwner,    // Owns the brokerage. Billing, compliance, full access
  managingBroker,    // Designated broker. Compliance oversight, agent management
  teamLead,          // Team leader. Manages team pipeline, sees team data
  realtor,           // Individual agent. Own pipeline, own leads, own deals
  tc,                // Transaction coordinator. Manages closing workflows
  isa,               // Inside sales agent. Lead qualification, appointment setting
  officeAdmin,       // Office staff. Scheduling, paperwork, support

  // Shared roles (both sides)
  client, tenant,
}
```

### Permission Matrix (Realtor Side)

| Permission | Brokerage Owner | Managing Broker | Team Lead | Realtor | TC | ISA | Office Admin |
|------------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| **Company Settings** | W | R | - | - | - | - | - |
| **Billing/Subscription** | W | - | - | - | - | - | - |
| **Agent Management** | W | W | R (team) | - | - | - | R |
| **Commission Plans** | W | W | R | R (own) | - | - | R |
| **All Leads** | W | W | R | - | - | R | R |
| **Own Leads** | W | W | W | W | - | W | - |
| **Lead Routing Rules** | W | W | W (team) | - | - | - | - |
| **All Transactions** | R | W | R (team) | - | R | - | R |
| **Own Transactions** | W | W | W | W | W | - | - |
| **Compliance/Docs** | R | W | R (team) | R (own) | W | - | R |
| **Commission Reports** | W | W | R (team) | R (own) | - | - | R |
| **CMA Generation** | W | W | W | W | - | - | - |
| **Property Scans (Recon)** | W | W | W | W | - | - | - |
| **Sketch Engine** | W | W | W | W | - | - | - |
| **Dispatch Contractors** | W | W | W | W | - | - | W |
| **Dispatch Inspectors** | W | W | W | W | - | - | W |
| **Seller Finder Engine** | W | W | W | W | - | - | - |
| **Marketing Factory** | W | W | W | W | - | - | W |
| **Client Portal Config** | W | W | - | - | - | - | - |
| **Trust Account (read-only)** | R | R | - | - | - | - | - |
| **1099 / Tax Reporting** | W | W | - | - | - | - | R |
| **AI Chat / Tools** | W | W | W | W | W | W | W |
| **AI Budget Config** | W | W | - | - | - | - | - |
| **Territory/Farm Mgmt** | W | W | W (team) | W (own) | - | - | - |
| **Listing Management** | W | W | W | W | - | - | W |
| **Showing Management** | W | W | W | W | - | - | W |
| **Open House** | W | W | W | W | - | - | W |

W = Write (full CRUD), R = Read only, - = No access

### Hierarchy Enforcement
```
Brokerage Owner
  └── Managing Broker(s)
       └── Team Lead(s)
            └── Realtor(s)
            └── ISA(s)
       └── TC(s)
       └── Office Admin(s)
  └── Dispatched Contractors (tech role, limited scope)
  └── Dispatched Inspectors (inspector role, limited scope)
```

**Visibility rules:**
- Brokerage Owner sees EVERYTHING
- Managing Broker sees everything EXCEPT billing
- Team Lead sees only their team's data
- Realtor sees only their own data
- TC sees all transactions they're assigned to (across agents)
- ISA sees all leads in their assignment pool
- Office Admin sees operational data (showings, schedules, docs) but not financial

### Configurable Permissions
Every default permission is OVERRIDABLE at the company level. The brokerage owner can create custom roles (same as contractor side with `custom_role.dart`). Example: a brokerage might give senior agents access to team-level reporting, or restrict new agents from dispatching contractors without approval.

---

## 3. PORTAL MAP — What Each Role Sees

### Mobile App (Flutter) — Realtor Roles

**Brokerage Owner / Managing Broker:**
```
Bottom Tabs: Home | Pipeline | Agents | Listings | More
Home: Company dashboard (GCI, deals, agent activity)
Pipeline: All deals across all agents
Agents: Agent list, production, compliance status
Listings: All active listings, showings, feedback
More: Settings, commission plans, reports, AI, dispatch
```

**Team Lead:**
```
Bottom Tabs: Home | Pipeline | Team | Listings | More
Home: Team dashboard (team GCI, team pipeline)
Pipeline: Team deals
Team: My agents, assignments, production
Listings: Team listings, showings
More: Settings, reports, AI, tools
```

**Realtor (Individual Agent):**
```
Bottom Tabs: Home | Leads | Deals | Tools | More
Home: "What Should I Do Now?" priority screen
Leads: My leads, scored, pipeline stages
Deals: Active transactions, deadlines, parties
Tools: Recon, Sketch Engine, CMA, Calculators, Smart CMA
More: Listings, dispatch, marketing, AI, settings
```

**TC (Transaction Coordinator):**
```
Bottom Tabs: Home | Transactions | Tasks | Docs | More
Home: Today's deadlines, upcoming milestones
Transactions: All assigned deals, deal health scores
Tasks: Checklist items due today/this week
Docs: Document management, signatures, compliance
More: Templates, settings
```

**ISA (Inside Sales Agent):**
```
Bottom Tabs: Home | Call Queue | Leads | Scripts | More
Home: Today's call targets, response metrics
Call Queue: Prioritized dial list
Leads: Lead pool, qualification status
Scripts: Objection handlers, qualification scripts
More: Settings, reporting
```

### Realtor Portal (Next.js) — Full Feature Map

```
realtor.zafto.cloud/
├── /dashboard                    # Role-based dashboard
├── /leads                        # Lead management
│   ├── /leads/new                # New leads
│   ├── /leads/pipeline           # Pipeline view (Kanban)
│   ├── /leads/[id]               # Lead detail
│   └── /leads/import             # Import leads (CSV, API)
├── /contacts                     # Full contact database
│   ├── /contacts/[id]            # Contact detail
│   ├── /contacts/import          # Import
│   └── /contacts/tags            # Tag management
├── /transactions                 # Transaction management
│   ├── /transactions/active      # Active deals
│   ├── /transactions/[id]        # Deal detail + timeline
│   ├── /transactions/[id]/docs   # Deal documents
│   ├── /transactions/[id]/parties # All parties
│   └── /transactions/templates   # Checklist templates
├── /listings                     # Listing management
│   ├── /listings/active          # Active listings
│   ├── /listings/[id]            # Listing detail
│   ├── /listings/[id]/showings   # Showing schedule + feedback
│   ├── /listings/[id]/marketing  # Marketing materials
│   └── /listings/cma             # CMA generator
├── /buyers                       # Buyer management
│   ├── /buyers/[id]              # Buyer profile
│   ├── /buyers/[id]/searches     # Saved searches
│   ├── /buyers/[id]/tours        # Tour schedule
│   └── /buyers/[id]/offers       # Offer tracking
├── /dispatch                     # Contractor/Inspector dispatch
│   ├── /dispatch/work-orders     # Active work orders
│   ├── /dispatch/[id]            # Work order detail + bids
│   ├── /dispatch/contractors     # Contractor database
│   └── /dispatch/inspectors      # Inspector database
├── /recon                        # Property intelligence
│   ├── /recon/scan               # New property scan
│   ├── /recon/[id]               # Scan results
│   └── /recon/area               # Area scan
├── /sketch                       # Sketch engine
│   ├── /sketch/editor            # Konva web editor
│   └── /sketch/[id]              # Floor plan view
├── /seller-finder                # Seller Finder Engine
│   ├── /seller-finder/dashboard  # Territory overview
│   ├── /seller-finder/prospects  # Scored prospect list
│   └── /seller-finder/campaigns  # Outreach campaigns
├── /marketing                    # Marketing factory
│   ├── /marketing/campaigns      # Active campaigns
│   ├── /marketing/templates      # Design templates
│   ├── /marketing/social         # Social media scheduler
│   └── /marketing/mail           # Direct mail
├── /properties                   # Property management
│   ├── /properties/[id]          # Property detail
│   ├── /properties/units         # Unit management
│   └── /properties/maintenance   # Maintenance requests
├── /reports                      # Reporting & analytics
│   ├── /reports/production       # Agent production (GCI, units)
│   ├── /reports/pipeline         # Pipeline value
│   ├── /reports/lead-roi         # Lead source ROI
│   ├── /reports/commission       # Commission tracking
│   └── /reports/market           # Market reports
├── /settings                     # Settings
│   ├── /settings/company         # Brokerage settings
│   ├── /settings/roles           # Role & permission config
│   ├── /settings/commission      # Commission plan builder
│   ├── /settings/ai              # AI budget & config
│   ├── /settings/integrations    # MLS, social, email
│   ├── /settings/templates       # Email, SMS, doc templates
│   ├── /settings/branding        # Logo, colors, email signature
│   └── /settings/notifications   # Notification preferences
├── /agents                       # Agent management (broker+)
│   ├── /agents/roster            # Agent roster
│   ├── /agents/[id]              # Agent detail
│   ├── /agents/onboarding        # Onboarding workflow
│   ├── /agents/compliance        # License, CE, E&O tracking
│   └── /agents/recruiting        # Recruiting pipeline
├── /smart-cma                    # Smart CMA Engine
│   ├── /smart-cma/new            # Generate new CMA
│   └── /smart-cma/[id]           # CMA detail/edit
├── /ai                           # AI tools
│   ├── /ai/chat                  # Z-Intelligence chat
│   ├── /ai/photo                 # Photo analyzer
│   └── /ai/growth                # Growth advisor
└── /client-portal-config         # Client portal customization
```

**Estimated routes: ~85-100**

---

## 4. MOBILE APP INTEGRATION (Flutter)

### Same App, Different Experience
The Flutter app detects `company_type` from the company model and adjusts:
- Navigation tabs per role (Section 3)
- Available screens
- Tool access
- Dashboard content
- Onboarding flow

### Shared Components (Zero Duplication)
These existing Flutter components are REUSED as-is for realtor roles:

| Component | Contractor Use | Realtor Use |
|-----------|---------------|-------------|
| All 35+ calculators | Trade calculations | Same — dispatched contractors use them |
| Inspection engine (20 types) | Quality control | Property inspections, pre-listing inspections |
| Inspection templates (25+) | Trade-specific checklists | Home inspection checklists |
| Deficiency tracking | Punch lists | Inspection deficiencies |
| Photo capture + GPS | Job documentation | Property photos, damage flagging |
| Walkthrough engine | Bid walkthroughs | Property walkthroughs |
| Sketch Engine (LiDAR) | Floor plans for estimates | Floor plans for listings + CMAs |
| Recon scanner | Property intelligence | Property intelligence (same!) |
| Time clock | Technician hours | Agent activity tracking |
| Calendar | Job scheduling | Showing scheduling |
| Documents/Storage | Job documents | Transaction documents |
| Chat/Messaging | Team communication | Agent-client communication |
| PDF generation | Invoices, bids | CMA reports, marketing materials |

### New Flutter Screens (Realtor-Specific)

```
lib/screens/realtor/
├── realtor_home_screen.dart           # "What Should I Do Now?" priority engine
├── realtor_leads_screen.dart          # Lead pipeline (Kanban cards)
├── realtor_lead_detail_screen.dart    # Lead detail + activity timeline
├── realtor_deals_screen.dart          # Active transactions
├── realtor_deal_detail_screen.dart    # Deal detail + timeline + parties
├── realtor_deal_tracker_screen.dart   # Client-visible deal progress
├── realtor_cma_screen.dart            # Smart CMA generator
├── realtor_listing_screen.dart        # Listing management
├── realtor_showing_screen.dart        # Showing schedule + route
├── realtor_buyer_profile_screen.dart  # Buyer preferences + matching
├── realtor_dispatch_screen.dart       # Dispatch contractor/inspector
├── realtor_seller_finder_screen.dart  # Territory map + prospects
├── realtor_commission_screen.dart     # Commission tracking dashboard
├── realtor_marketing_screen.dart      # Marketing factory
├── realtor_more_screen.dart           # Settings, AI, tools

lib/screens/broker/
├── broker_dashboard_screen.dart       # Brokerage-wide dashboard
├── broker_agents_screen.dart          # Agent roster + production
├── broker_agent_detail_screen.dart    # Individual agent view
├── broker_compliance_screen.dart      # License, CE, E&O tracking
├── broker_commission_plans_screen.dart # Commission plan builder
├── broker_recruiting_screen.dart      # Recruiting pipeline
├── broker_reports_screen.dart         # Brokerage-wide reporting
├── broker_settings_screen.dart        # Brokerage settings

lib/screens/tc/
├── tc_dashboard_screen.dart           # Today's deadlines, milestones
├── tc_transaction_screen.dart         # Transaction workflow execution
├── tc_checklist_screen.dart           # Closing checklist + tasks
├── tc_documents_screen.dart           # Document management

lib/screens/isa/
├── isa_call_queue_screen.dart         # Prioritized dial list
├── isa_lead_qualify_screen.dart       # Lead qualification form
├── isa_scripts_screen.dart            # Scripts + objection handlers
```

---

## 5. REALTOR PORTAL (Next.js)

### Scaffold
```
realtor-portal/
├── src/
│   ├── app/                    # Next.js 15 app router
│   │   ├── layout.tsx          # Root layout (dark theme, Lucide icons, Inter)
│   │   ├── middleware.ts       # Auth + RBAC middleware
│   │   └── (dashboard)/        # Protected routes
│   ├── lib/
│   │   ├── supabase.ts         # Supabase client (same pattern as web-portal)
│   │   ├── hooks/              # use-*.ts hooks (same pattern)
│   │   └── mappers.ts          # snake_case → camelCase
│   ├── components/             # Shared UI components
│   └── types/                  # TypeScript types
├── public/
├── package.json
├── next.config.js
├── tailwind.config.ts
└── tsconfig.json
```

**Auth:** Password-based for agents/staff. Magic link for clients. Same Supabase Auth with `app_metadata.company_id` + `app_metadata.role`. Middleware checks `company_type = 'brokerage' | 'realtor_*'` before allowing access.

**Design:** Same premium dark theme as contractor CRM. "Stripe for Realtors" aesthetic. Information-dense, no wasted space. Lucide icons only. Inter typography.

---

## 6. FLAGSHIP ENGINE 1: SMART CMA ENGINE

### What It Is
The most sophisticated CMA tool ever built. Agent enters an address → engine generates a complete pricing analysis, negotiation dossier, and branded presentation in under 5 minutes. Beats Cloud CMA, RPR, MoxiPresent, and every Zestimate.

### Full Workflow

**Step 1: Address Entry**
- Agent types address or selects from recent properties
- System triggers Recon scan in background (if not already scanned)
- System queries public records: county assessor (ownership, tax history, deed history), permit records, flood/environmental, school ratings, crime data, walkability

**Step 2: Subject Property Profile (Auto-Generated)**
- Property details (beds, baths, sqft, lot, year built, style)
- Ownership history (chain of title, sale prices, holding periods)
- Tax assessment history (5-year trend)
- Permit history (all renovations — permitted and unpermitted risk)
- Structural age analysis: estimated roof age, HVAC age, water heater age based on permit dates + property age
- Flood zone, environmental hazards, climate risk
- School ratings, walkability, crime score
- Utility cost estimate (based on sqft + climate zone + utility rate data)

**Step 3: Comparable Sales (AI-Selected)**
- Auto-pull recent sales (3-6 months, expandable to 12) within 0.5-1 mile
- AI ranks comps by similarity score: sqft (weight 30%), beds/baths (20%), lot size (15%), year built (15%), condition (10%), proximity (10%)
- Agent can accept, reject, or add comps manually
- For each comp: sale price, sale date, DOM, sqft, beds/baths, lot, year built, condition assessment (from photos if available), distance from subject

**Step 4: AI-Powered Adjustments**
- Traditional adjustments auto-calculated: sqft (+/- $/sqft based on local market), beds/baths (+/- fixed amount), lot size, garage, pool, view
- **AI condition adjustment** (unique to Zafto): if property photos available (from Recon scan or MLS), Claude analyzes condition and applies C1-C6 rating adjustment. "Subject property kitchen is C4 (outdated but functional), Comp #2 kitchen is C2 (recently renovated) — adjustment: -$15,000"
- **Renovation value adjustment**: if permits show recent kitchen/bath remodel, AI estimates added value using Cost vs Value data. "Permitted kitchen remodel (2023) adds estimated $18,000-$24,000"
- **Market momentum adjustment**: if prices trending up/down in neighborhood, apply time-based appreciation/depreciation to older comps
- Agent can override ANY adjustment with manual value + notes

**Step 5: The Zafto Advantage — Repair Cost Integration**
This is what NO competitor can do. Using the contractor estimation engine:
- If property has identifiable deficiencies (from photos, inspection, or Recon), system generates repair cost estimates
- Line items with ZIP-specific pricing: "Roof replacement (2,400 sqft): $8,400-$12,600", "Kitchen remodel (standard): $22,000-$38,000"
- Three-tier pricing: Good/Better/Best
- ROI analysis per repair: cost vs added value
- **Listing presentation use case**: "If you invest $12,000 in these 3 repairs, your home could sell for $25,000 more. Net gain: $13,000."
- **Buyer negotiation use case**: "Based on contractor-grade estimates, these inspection items will cost $8,200-$14,600 to repair. Here's the data."

**Step 6: Pricing Strategy**
- **Recommended list price range** (low/mid/high) with rationale
- **Strategy options**:
  - "Price to generate offers" (5-7% below comps → multiple offers → over-ask)
  - "Price at market" (in line with comps → standard negotiation)
  - "Price for negotiation room" (3-5% above comps → room to negotiate)
- **Absorption rate analysis**: months of inventory → seller's/buyer's market indicator
- **Estimated DOM**: based on price point, condition, and current market velocity
- **Buyer pool estimate**: based on price point, how many active buyers are searching in this range in this area

**Step 7: Zillow Killer Counter-Report**
Unique section that shows exactly why the Zestimate is wrong:
- Pull current Zestimate for the property
- Side-by-side comparison: Zestimate vs Smart CMA value
- Specific data points the Zestimate misses: permitted renovations, condition, unique features, lot premium, view, school district nuance
- "Zillow's algorithm cannot see inside your home. It doesn't know about your $35,000 kitchen remodel, your new roof, or that your lot backs to the golf course. Here's what the data actually shows."
- This section alone wins listing appointments

**Step 8: Output Package**
- **Branded PDF** (agent logo, photo, contact, brokerage): Cover page → property profile → comps with photos → adjustment grid → pricing strategy → repair cost analysis (if applicable) → Zestimate counter → methodology note → agent credentials
- **Shareable web link** (`cma.zafto.cloud/[id]`) with view tracking
- **Client portal view** (buyer or seller sees their CMA in their portal)
- **One-click listing description** generated from CMA data
- **Social media graphics** (property highlight card for Instagram/Facebook)
- **Versioning**: v1 (AI-generated) → v2 (agent-edited) → v3 (post-inspection update)

### Data Sources
| Source | Data | Cost |
|--------|------|------|
| County assessor (Socrata/direct) | Ownership, tax, deed, sqft, beds/baths, year built | FREE |
| County recorder (Socrata/direct) | Permits, liens, title history | FREE |
| FEMA OpenFEMA | Flood zones | FREE |
| EPA Envirofacts | Environmental hazards | FREE |
| FBI Crime Data | Crime statistics | FREE |
| Walk Score | Walkability/transit/bike scores | FREE (5K/day) |
| GreatSchools | School ratings | FREE (15K/mo) |
| FRED | Mortgage rates, economic data | FREE |
| Census/BLS | Demographics, employment | FREE |
| Recon engine (existing) | Full property intelligence | Already built |
| Estimation engine (existing) | Repair cost estimates | Already built |
| RentCast (optional) | AVM, rent estimates | 50 free/mo |
| MLS (Phase 2) | Sold comps, active listings | $50-200/mo per MLS |

### Edge Functions
- `smart-cma-generate` — orchestrates data pull, AI analysis, comp selection, adjustments
- `smart-cma-export` — PDF generation with branding
- `smart-cma-share` — creates shareable link with view tracking

### Tables
- `cma_reports` — CMA records (company_id, property_id, agent_id, status, version, data JSON)
- `cma_comps` — selected comparables (cma_id, property_address, sale_price, sqft, adjustments JSON)
- `cma_shares` — share links with view tracking (cma_id, token, views, last_viewed_at)

---

## 7. FLAGSHIP ENGINE 2: AUTONOMOUS TRANSACTION ENGINE

### What It Is
AI-powered transaction coordinator that reads contracts, extracts deadlines, orchestrates all parties, predicts bottlenecks, and gives clients a FedEx-style tracker for their deal. Replaces 30 hours of administrative work per transaction.

### Full Workflow

**Step 1: Deal Creation**
- Agent creates a deal from: accepted offer, listing agreement, or manual entry
- Links to: property (from Recon/CRM), buyer contact, seller contact, both agents
- Sets: transaction type (purchase, listing, lease, commercial, referral)

**Step 2: Contract Upload + AI Parsing**
- Agent uploads purchase agreement (PDF or photo)
- Edge Function `transaction-parse-contract` sends to Claude:
  - Extracts: purchase price, earnest money amount + deadline, inspection contingency period, appraisal contingency, financing contingency, closing date, possession date, all parties (names + roles), special stipulations, included/excluded items, seller concessions
  - Returns structured JSON with confidence scores per field
  - Agent reviews extracted data → confirms or corrects
  - System auto-creates all deadline tasks from extracted dates

**Step 3: Timeline Generation**
- Based on contract type + state, system generates the full closing timeline
- **State-specific compliance** built in: which disclosure forms are required, attorney state vs title state, specific timing rules
- Each milestone gets:
  - Due date (calculated from contract dates)
  - Responsible party (buyer, seller, buyer's agent, listing agent, lender, title, inspector, appraiser, TC)
  - Auto-reminders at 7 days, 3 days, 1 day, and same-day
  - Status: pending → in_progress → completed → overdue
  - Dependencies: "Appraisal can't be ordered until inspection contingency is resolved"

**Step 4: Multi-Party Coordination**
- Each party gets a role-specific view:
  - **Agent view**: full deal dashboard with all milestones, documents, communication
  - **Client view** (via client portal): simplified progress tracker, upcoming tasks for them, documents to sign
  - **Lender view** (via email notifications): document requests, appraisal scheduling
  - **Title company view** (via email notifications): title search status, closing scheduling
  - **TC view**: full operational dashboard with all deals, deadlines, compliance
- Communication logged to deal record regardless of channel (email, text, call)

**Step 5: Deal Health Score**
- AI continuously monitors deal progress and calculates health:
  - **GREEN** (90-100): All milestones on track, no issues
  - **YELLOW** (60-89): Warning signs — approaching deadline, lender delay, inspection issue
  - **RED** (0-59): Critical — missed deadline, appraisal gap, financing risk, title issue
- **Predictive bottleneck detection**:
  - "This lender averages 38 days to clear-to-close. Your closing is in 32 days. Consider requesting a closing extension."
  - "Inspection contingency expires in 2 days but repair negotiations haven't started."
  - "Appraisal came in $15,000 below purchase price. Options: renegotiate, buyer covers gap, cancel."
- Health score visible on dashboard, push notifications on status changes

**Step 6: The Domino's Tracker (Client Portal)**
- Client logs into `client.zafto.cloud` → sees their deal
- Visual timeline showing: Contract Signed ✓ → Earnest Money Deposited ✓ → Inspection Scheduled → Inspection Complete → Appraisal Ordered → ... → Closing Day
- Each step shows: status (done/current/upcoming), responsible party, date, any documents
- "Your home purchase is 62% complete. Next: Home inspection on Thursday at 2 PM."
- Branded to the agent (agent's photo, logo, contact info)
- Push notifications on every milestone change

**Step 7: Document Management**
- All transaction documents in one place, organized by category
- Document checklist auto-generated per transaction type
- E-signature integration (DocuSign or built-in)
- Missing document alerts
- Compliance tracking: which disclosures are signed, which are outstanding
- Auto-archive at closing

**Step 8: Post-Close Automation**
- Deal marked complete → auto-triggers:
  - Thank you email/text to client
  - Request for review/testimonial (after 7 days)
  - "Just Sold" marketing automation
  - Contact moved to "Past Client" nurture sequence
  - Commission recorded in commission engine
  - File archived for compliance (state-specific retention period)
  - Branded vendor list auto-sent to buyer (from dispatch engine — contractors the agent trusts)

### Tables
- `transactions` — deal records (type, status, parties, dates, health_score, property_id)
- `transaction_milestones` — timeline items (transaction_id, name, due_date, responsible_party, status, dependencies)
- `transaction_parties` — people involved (transaction_id, user_id/contact_id, role, contact_info)
- `transaction_documents` — uploaded docs (transaction_id, name, category, file_path, signed_at)
- `transaction_templates` — closing checklist templates by type and state
- `transaction_notes` — communication log (transaction_id, author, content, channel)
- `transaction_health_log` — health score history (transaction_id, score, factors, timestamp)

### Edge Functions
- `transaction-parse-contract` — AI contract parsing (Claude)
- `transaction-health-check` — periodic health score recalculation (cron)
- `transaction-reminders` — deadline reminder notifications (cron)
- `transaction-milestone-notify` — multi-party notifications on status changes

---

## 8. FLAGSHIP ENGINE 3: SELLER FINDER ENGINE

### What It Is
Predictive prospecting engine that aggregates 20+ free data signals to identify homeowners likely to sell, scores them, enriches with contact info, and powers targeted outreach. Replaces $500+/mo tools (SmartZip, REDX, Vulcan7) with a $10-20/mo pipeline built from free public records.

### Full Workflow

**Step 1: Territory Claim**
- Agent draws polygon on map OR selects subdivision/ZIP/neighborhood
- System populates every property in the territory from county assessor records
- Dashboard: "847 homes in your farm. Building prospect intelligence..."

**Step 2: Data Ingestion (Automated, Scheduled)**
- **County assessor** (Socrata/direct): owner name, mailing address, property address, sqft, beds/baths, year built, assessed value, sale history, lot size
- **County recorder** (Socrata/direct): deed transfers, mortgages (amount, date, lender), liens, lis pendens (pre-foreclosure), NOD (notice of default)
- **Court records** (county portals): divorce filings, probate filings
- **Tax collector** (county): delinquent tax list
- **Municipal APIs** (Socrata): code violations, building permits
- **USPS** (via Recon): vacancy indicators, address changes
- **Census/ACS**: demographic trends, median income, population changes
- Data refreshed: weekly for court records, monthly for assessor/tax, quarterly for census

**Step 3: Propensity-to-Sell Scoring**
Every property gets a score (0-100) based on weighted signals:

| Signal | Weight | Source | Logic |
|--------|--------|--------|-------|
| Pre-foreclosure/Lis Pendens | +30 | County recorder | Active filing = highly motivated |
| Probate filing on owner | +30 | Court records | Estate must sell |
| Tax delinquent 2+ years | +25 | Tax collector | Financial distress |
| Divorce filing on owner | +25 | Court records | Life change = likely move |
| Active code violations | +20 | Municipal data | May want to sell vs fix |
| Vacant property (USPS) | +20 | USPS/Recon | Absentee + vacant = motivated |
| Absentee owner | +15 | Assessor | Mailing != property address |
| Ownership 15+ years | +15 | Assessor | Long-term = high equity, life changes |
| High equity (assessed > 2x purchase) | +10 | Assessor + recorder | Financial readiness |
| Recent building permit | +8 | Municipal data | Renovation = preparing to sell? |
| Property age 30+ years | +5 | Assessor | Aging property = more likely to move |
| Neighborhood turnover above avg | +5 | Recorder (sale frequency) | Market momentum |

**Categories:**
- 70-100 = HOT (contact immediately)
- 40-69 = WARM (add to nurture campaign)
- 0-39 = COLD (monitor, farm mailer)

**Step 4: Contact Enrichment**
- Owner name + mailing address from assessor (free)
- Phone + email via skip tracing API (Tracerfy at $0.02/record)
- DNC (Do Not Call) scrub included in skip trace
- Social media profile matching (name + location → LinkedIn/Facebook)
- Agent can enrich selectively (only HOT leads) or bulk

**Step 5: Territory Command Center**
- **Map view**: every property color-coded by score (red=HOT, orange=WARM, gray=COLD)
- **List view**: sortable by score, owner name, ownership length, equity, last contact
- **Dashboard metrics**:
  - Total properties in farm
  - Active listings (competitors)
  - HOT prospects count
  - Market share (agent's closed deals / total sales in territory)
  - Average days on market
  - Median sale price trend
  - Turnover rate (sales/year / total properties)
- **Goal tracking**: "Goal: 30% market share. Current: 22%. Need 8 more closings this year."

**Step 6: Outreach Engine**
- **Auto-generated outreach sequences** based on prospect motivation:
  - Pre-foreclosure → empathetic ("I help homeowners explore all options before foreclosure")
  - FSBO/Expired → educational ("90% of FSBOs fail. Here's what top agents do differently")
  - Probate → sensitive ("I specialize in estate sales and can handle the process for your family")
  - Equity-rich long-term owner → lifestyle ("Your home has appreciated $180K since you bought it. Curious what that means for your next chapter?")
  - Absentee → practical ("Managing a property from afar? I have investors and families looking in your neighborhood")
- **Channels**: direct mail (Lob API, $0.77/postcard), email (Mailgun), SMS (SignalWire, opt-in required), cold call queue (DNC-scrubbed)
- **Door-knock route planner**: optimized walking/driving route through HOT prospects with talking points per property

**Step 7: Weekly Hyperlocal Market Report**
- Auto-generated every Monday
- Content: new listings, price changes, sold properties, pending sales, market trends
- Branded to the agent (logo, photo, contact)
- Auto-distributed to every homeowner in the farm via selected channel
- "Your Neighborhood Market Update — brought to you by [Agent Name]"
- Agent becomes the recognized neighborhood authority

**Step 8: Tracking & Attribution**
- Every interaction logged: called, emailed, mailed, door-knocked, texted
- Conversion tracking: prospect → lead → client → closing
- Farm ROI: total spend (mail + skip trace) vs GCI from farm closings
- Attribution: "This closing ($8,400 GCI) came from a probate lead you identified 4 months ago. Total farm ROI: 340%."

### Tables
- `seller_finder_territories` — agent's claimed farm areas (company_id, agent_id, polygon GeoJSON, name)
- `seller_finder_prospects` — property-level prospect data (territory_id, property_address, owner_name, score, signals JSON, contact_info JSON, last_enriched_at)
- `seller_finder_interactions` — touchpoint log (prospect_id, agent_id, channel, type, notes, timestamp)
- `seller_finder_campaigns` — outreach campaigns (territory_id, type, status, template_id)
- `seller_finder_market_reports` — generated reports (territory_id, report_date, data JSON, distribution_status)

### Edge Functions
- `seller-finder-ingest` — scheduled data ingestion from county sources (cron, weekly)
- `seller-finder-score` — propensity scoring engine
- `seller-finder-enrich` — skip tracing API integration
- `seller-finder-market-report` — weekly report generation (cron)
- `seller-finder-outreach` — campaign execution (mail, email, SMS)

---

## 9. FULL CRM — CONTACT & LEAD MANAGEMENT

### Contact Model
```
contacts (extends existing customers table OR new table)
├── id, company_id (tenant scoping)
├── type: buyer | seller | investor | renter | past_client | soi | referral_partner | agent_referral | builder | relocation
├── source: zillow | realtor_com | facebook | google | sign_call | open_house | referral | door_knock | cold_call | fsbo | expired | direct_mail | text_code | website | seller_finder
├── score: 0-100 (AI-calculated)
├── score_category: hot | warm | cold
├── pipeline_stage: new | attempted | connected | qualified | appointment | showing | offer | under_contract | closed | past_client | lost | nurture
├── assigned_to: agent user_id
├── team_id: for team-based routing
├── first_name, last_name, email, phone, secondary_phone
├── address, city, state, zip
├── preferred_contact_method: call | text | email
├── preferred_language
├── buyer_preferences: JSON (beds, baths, sqft_min, sqft_max, price_min, price_max, neighborhoods, must_haves, deal_breakers, property_types, timeline)
├── seller_info: JSON (property_address, estimated_value, motivation, timeline)
├── pre_approved: boolean
├── pre_approval_amount: decimal
├── lender_name, lender_contact
├── tags: text[]
├── notes: text
├── last_contacted_at, next_follow_up_at
├── created_at, updated_at, deleted_at
```

### Lead Scoring Engine
Calculated automatically, updated on every interaction:

**Demographic Score (40%)**:
- Pre-approved buyer: +15
- Motivated seller (FSBO, expired, life event): +15
- Timeline < 30 days: +10
- Timeline 1-3 months: +5
- Budget aligns with agent's market: +5

**Behavioral Score (40%)**:
- Responded to outreach: +10
- Viewed properties (IDX/links): +5 per view
- Saved properties: +8 per save
- Requested showing: +15
- Attended open house: +10
- Return website visitor: +5
- Used mortgage calculator: +8
- Viewed same property 3+ times: +10
- Price range narrowed: +5

**Source Score (20%)**:
- Referral from past client: +20
- SOI warm lead: +15
- Open house sign-in: +10
- Website organic: +8
- Social media: +5
- Paid lead (Zillow/Realtor.com): +3
- Cold call/door knock: +2

### Speed-to-Lead System
- New lead enters system → within 60 seconds:
  - Auto-text: "Hi [Name], thanks for reaching out! I'm [Agent] with [Brokerage]. I'll be in touch shortly. In the meantime, here's a quick look at [relevant info based on source]."
  - Auto-email: branded welcome with agent photo, bio, next steps
  - Push notification to assigned agent with lead details + source
- If agent doesn't respond in 10 minutes → escalate to backup agent or team lead
- If no response in 30 minutes → flag as "uncontacted" with red warning
- All automated responses configurable in settings

### Lead Routing (Configurable)
- **Round robin**: sequential rotation among team members
- **Weighted**: top producers get more leads (configurable weights)
- **Geographic**: by ZIP code or territory
- **Price point**: high-value leads to senior agents
- **Source-based**: Zillow leads to Agent A, referrals to Agent B
- **Performance-based**: best conversion rate gets next lead
- **First-to-claim**: notification to all, first to respond wins
- **Language-based**: Spanish leads to bilingual agent
- All routing rules configurable in settings by brokerage owner/managing broker

---

## 10. COMMISSION ENGINE

### What We Build (Tracking Only — No Money Movement)

**Commission Plan Builder** (Settings → Commission Plans):
Every brokerage has different plans. System supports ALL models simultaneously:

```
commission_plans
├── id, company_id
├── name: "Standard Split", "Team Plan", "Veteran Plan"
├── plan_type: split | cap | flat_fee | hybrid
├── agent_split_pct: 70 (agent gets 70%)
├── broker_split_pct: 30 (broker gets 30%)
├── cap_amount: 16000 (agent caps after $16K to broker)
├── cap_period: anniversary | calendar_year
├── post_cap_split_agent: 100 (after cap, agent keeps 100%)
├── post_cap_split_broker: 0
├── franchise_fee_pct: 6 (KW model)
├── franchise_fee_cap: 3000
├── transaction_fee: 250 (per deal)
├── eao_fee: 40 (per deal)
├── eao_fee_cap: 500 (per year)
├── desk_fee_monthly: 500
├── tech_fee_monthly: 85
├── team_split_pct: 50 (team lead takes 50% of agent's share)
├── team_lead_id: (if team plan)
├── referral_fee_pct: 25 (default referral fee)
├── effective_date, end_date
├── is_default: boolean
```

**Per-Transaction Calculation**:
```
Input: sale_price, commission_rate, referral_fee (if any), agent_plan
Output:
  gross_commission = sale_price * commission_rate
  agent_side = gross_commission * listing_or_buyer_split
  referral_deduction = agent_side * referral_fee_pct (if referral)
  net_after_referral = agent_side - referral_deduction
  broker_share = net_after_referral * broker_split_pct
  franchise_fee = min(broker_share * franchise_fee_pct, remaining_franchise_cap)
  transaction_fee = plan.transaction_fee
  eao_fee = min(plan.eao_fee, remaining_eao_cap)
  agent_net = net_after_referral - broker_share - franchise_fee - transaction_fee - eao_fee

  // If team plan:
  team_lead_share = agent_net * team_split_pct
  agent_final = agent_net - team_lead_share
```

**CDA Generation**:
- Commission Disbursement Authorization document (PDF)
- Shows: sale price, commission rate, listing/buyer side split, referral fee, brokerage split, all fees, net to agent
- Signed by broker → sent to title/escrow company
- Title company disburses funds based on CDA (WE DO NOT MOVE MONEY)

**Agent Dashboard**:
- YTD GCI (gross commission income)
- YTD Net (after all splits/fees)
- Cap progress bar: "$12,400 of $16,000 cap used (77.5%)"
- Pending GCI (deals under contract)
- Commission forecast by month
- Per-transaction history with full breakdown
- 1099 data export (year-end)

### What We DO NOT Build
- Trust account management (too high risk — see legal research)
- Commission disbursement / ACH transfers (money transmitter licensing)
- Trust account reconciliation
- Escrow tracking

### Tables
- `commission_plans` — plan definitions
- `commission_records` — per-transaction calculations (transaction_id, plan_id, breakdown JSON)
- `commission_caps` — per-agent cap tracking (agent_id, period, amount_used, reset_date)

---

## 11-16: REMAINING SECTIONS (Summary — Full Detail in Sprint Specs)

### 11. Listing Management
- Listing creation from CMA data or manual entry
- Marketing automation: one-click launch → social + email + flyer + single-property website
- Showing management: scheduling, confirmation sequences, feedback collection (auto-request from buyer's agents)
- Open house: digital sign-in (QR code), auto-follow-up, seller report
- Price reduction intelligence: DOM vs market avg, timing recommendation, auto-notify past viewers
- Listing analytics: views, showings, feedback sentiment, days on market

### 12. Buyer Management
- Buyer preference profiles (beds, baths, sqft, price, neighborhoods, must-haves, deal-breakers)
- Saved search with auto-alerts (requires MLS integration Phase 2)
- Tour route optimization (Google Maps directions API, minimize drive time)
- Offer tracking across multiple properties
- Buyer tour sheets with property details + talking points

### 13. Dispatch Engine — Contractors & Inspectors
- Realtor dispatches work → contractor/inspector gets invited to platform
- **Same Flutter app**, role = `technician` or `inspector`, scoped to realtor's company
- Contractor gets ALL field tools (35+ calculators, all trade tools) — same as contractor CRM
- Inspector gets FULL inspection engine (20 types, templates, deficiency tracking, reports)
- AI usage draws from realtor/brokerage's AI bucket (configurable in settings: per-agent allocation or shared pool)
- Work order tracking: dispatched → bid received → contractor selected → scheduled → in progress → documentation → complete → rated
- Two-way rating system (realtor rates contractor + contractor rates realtor)
- Contractor landing page for bid submission (`jobs.zafto.cloud/[id]`)
- Staggered email dispatch (SendGrid/Mailgun, 200 per job, batched, warm-up, engagement scoring)

### 14. Property Management (Shared from D5)
- Full PM module already built (D5, 18 tables, 14 CRM pages, 10 Flutter screens)
- Realtors who manage rentals get the SAME PM features: units, tenants, leases, maintenance, inspections
- Tenant portal (client.zafto.cloud) already built — tenants submit maintenance requests
- Realtor dispatches maintenance to contractors via dispatch engine
- Rent tracking, lease management, move-in/move-out inspections (using inspector engine)

### 15. Recon Integration
- Full Recon engine already built (Phase P, 14 tables, 7 EFs)
- Realtors get SAME Recon features: property scan, roof measurements, lead scoring, area scans, storm assessment
- Recon data feeds into: Smart CMA, Seller Finder, property reports, listing presentations
- No code changes needed — just role-based access to existing screens/hooks

### 16. Sketch Engine Access
- Full Sketch Engine already built (Phase SK, 6 tables, 14 sprints)
- Realtors get: LiDAR scan, trade layers, Konva web editor, floor plan export
- Use cases: listing photos with floor plans, measurement verification, renovation planning
- Web editor available in realtor portal (same Konva component)
- No code changes needed — just role-based access

---

## 17. LEAD GENERATION PIPELINE

5-layer pipeline built from free data:

**Layer 1 — Data Ingestion**: County assessor, recorder, tax, probate, civil court, municipal code violations, building permits — all via Socrata SODA API. Cost: $0/month.

**Layer 2 — Processing**: ETL normalization, propensity scoring (Seller Finder Engine), equity estimation, ownership duration calculation, signal stacking.

**Layer 3 — Contact Enrichment**: Skip tracing via Tracerfy API ($0.02/record), DNC scrub included.

**Layer 4 — CRM & Outreach**: Auto-segmentation (HOT/WARM/COLD), multi-channel campaigns (email via Mailgun, direct mail via Lob, SMS via SignalWire with opt-in, cold call queue with DNC scrub).

**Layer 5 — Organic Amplifiers**: Google Business Profile, open house digitization, social media automation, website lead capture.

**Total cost: ~$10-20/month for 500 scored leads with contact info.** Competitors: $99-500+/month.

---

## 18. MARKETING FACTORY

One-click listing marketing engine. Agent enters listing → system generates:
1. AI listing description (Claude, compliance-checked)
2. Social media posts (Instagram, Facebook, TikTok, LinkedIn — all free APIs)
3. Print-ready flyer (PDF, using Canva Connect API — free)
4. Single-property website (hosted page with lead capture)
5. Email blast template (to agent's database)
6. Virtual staging (Decor8 AI — has Dart SDK, $0.24/image)
7. Video slideshow from photos
8. Direct mail postcard (Lob API, $0.77/piece)

All from a single property data entry. This alone replaces $100-200/month in marketing tools.

---

## 19. BROKERAGE ADMIN PANEL

Broker/managing broker exclusive features:

- **Agent roster**: all agents, status, production, compliance
- **Agent onboarding**: 18-step workflow (license verify, ICA signed, W-9, NAR/MLS membership, E&O, system access, training)
- **Compliance dashboard**: license expiration dates, CE credit tracking, E&O insurance status, MLS membership — auto-alerts 30/60/90 days before expiration
- **Agent production leaderboard**: GCI, units, volume, ranked
- **Commission plan management**: create/edit plans, assign to agents
- **Lead routing configuration**: rules engine for lead distribution
- **Recruiting pipeline**: prospect agents, track conversations, send value propositions
- **Brokerage reporting**: revenue, agent count, market share, pipeline value
- **1099 year-end**: one-click generation for all agents

---

## 20. CROSS-PLATFORM INTELLIGENCE SHARING

### The Network Effect Play
If a realtor uses Zafto AND their contractor uses Zafto → they can OPTIONALLY link and share data bidirectionally. This is unprecedented.

### How It Works

**Linking:**
- Realtor dispatches work order to Zafto contractor (matched by email or Zafto ID)
- System detects: "This contractor has a Zafto Contractor account"
- Both parties prompted: "Link your Zafto accounts to share property data, inspection reports, and estimates? You control exactly what's shared."
- Both must opt-in. Either can revoke at any time.

**What Can Be Shared (All Optional, Granular Controls):**
| Data | Direction | Value |
|------|-----------|-------|
| Property scan (Recon) | Realtor → Contractor | Contractor sees property intel before arriving |
| Inspection report | Inspector → Realtor | Realtor gets professional inspection data for CMAs |
| Repair estimates | Contractor → Realtor | Realtor uses contractor-grade pricing in Smart CMA |
| Floor plans (Sketch) | Bidirectional | Both use same floor plan |
| Work order status | Contractor → Realtor | Real-time progress tracking |
| Reviews/ratings | Bidirectional | Reputation builds on both platforms |
| Job photos | Contractor → Realtor | Before/after for marketing |
| Material costs | Contractor → Realtor | Actual costs for future estimates |

**Privacy Controls:**
- Share settings configurable per contractor relationship
- Can share with Company A but not Company B
- Can share property data but not financial data
- Can revoke sharing at any time (data access removed, not deleted)
- All sharing logged in audit trail

### Tables
- `cross_company_links` — link records (company_a_id, company_b_id, status, linked_at, linked_by)
- `cross_company_shares` — granular share permissions (link_id, data_type, direction, enabled)
- `cross_company_share_log` — audit trail (link_id, action, data_type, timestamp, user_id)

---

## 21. AI INTEGRATION (Phase E)

### Same AI Layer, Different Training
When Phase E executes, Zafto Realtor gets the FULL AI suite:

| AI Feature | Contractor Version | Realtor Version |
|------------|-------------------|-----------------|
| Z-Intelligence (14 tools) | Trade-specific analysis | Real estate analysis |
| AI Chat Sheet | "How do I wire a 200A panel?" | "How should I price this listing?" |
| Photo Analyzer | Damage assessment, material ID | Property condition, staging suggestions |
| Growth Advisor | Business growth for contractors | Production growth for agents |
| Troubleshooting | "My HVAC won't heat" | "My deal is stalled at appraisal" |
| Document Analysis | Blueprint reading, takeoff | Contract parsing, disclosure review |

### AI Budget Configuration (Settings → AI)
- **Pool mode**: brokerage has one AI budget, all agents share it
- **Per-agent mode**: each agent gets allocated tokens/month
- **Overflow**: what happens when budget is exceeded (block, charge overage, alert broker)
- **Dispatched contractor/inspector**: their AI usage draws from the dispatching realtor's budget
- **Usage dashboard**: who used how much, which features, cost breakdown

---

## 22. ZAFTO LEDGER FOR REALTORS

### What We Build: Commission Tracking + Operating Accounting
- Extend existing Zafto Ledger (D4, 15 tables, GL engine) for brokerage OPERATING accounting
- Commission engine (Section 10) tracks splits, caps, fees, generates CDAs, 1099 data
- Brokerage P&L: revenue from commission splits, expenses (marketing, office, tech fees)
- Agent expense tracking (mileage, marketing, dues — for tax deduction purposes)
- Tax estimate calculator (self-employment tax for agents)

### What We DO NOT Build
- **Trust account management** — regulated fiduciary accounts, 50 different state rules, 57% audit failure rate in California, broker can't shift blame to software. LEGAL RISK TOO HIGH.
- **Money disbursement** — money transmitter licensing in 49 states, $500K+ compliance cost
- **Escrow tracking** — handled by title companies, not our domain

### Future Integration (Post-Launch)
- Optional integration with Lone Wolf Back Office or QuickBooks for brokerages that need trust accounting
- Read-only trust account dashboard that pulls data from external accounting system
- CSV/QBO export for agent data → broker's existing accounting software

---

## 23. SETTINGS ARCHITECTURE

### Hierarchy: Company → Office → Team → Agent
Settings cascade downward. Higher levels set defaults, lower levels can override (if permitted).

```
Company Settings (Brokerage Owner only)
├── General: company name, logo, branding colors, timezone, default language
├── Subscription: plan tier, billing, add-ons
├── Roles & Permissions: role templates, custom roles, permission overrides
├── Commission: default plan, plan library, franchise fees, cap settings
├── AI: budget allocation mode (pool vs per-agent), total budget, overflow behavior
├── Lead Routing: default rules, assignment method, escalation timers
├── Notifications: company-wide notification preferences
├── Integrations: MLS connections, social media accounts, email provider
├── Branding: email templates, report templates, marketing templates
├── Compliance: required disclosures by state, document retention rules (→ Phase JUR4 seeds all 50-state data: disclosure forms, agency rules, attorney states, commission rules, license reciprocity, document retention periods)
├── Dispatch: contractor database settings, email dispatch settings, bid thresholds
├── Client Portal: what clients can see, branding, notification settings
│
├── Office Settings (Managing Broker, per-office)
│   ├── Office name, address, phone
│   ├── Office-specific lead routing overrides
│   ├── Office-specific commission plan overrides
│   ├── Office agent roster
│   │
│   ├── Team Settings (Team Lead, per-team)
│   │   ├── Team name, members
│   │   ├── Team commission structure
│   │   ├── Team lead routing rules
│   │   ├── Team pipeline visibility
│   │   │
│   │   └── Agent Settings (Individual, per-agent)
│   │       ├── Personal branding (headshot, bio, credentials)
│   │       ├── Commission plan assignment
│   │       ├── AI budget allocation
│   │       ├── Territory/farm assignments
│   │       ├── Notification preferences
│   │       ├── Social media connections
│   │       ├── Signature / email template
│   │       ├── Availability schedule
│   │       └── Auto-response templates (text, email)
```

---

## 24. DATABASE SCHEMA (New Tables — Estimated ~45-60)

### Core
- `realtor_contacts` — CRM contacts (or extend existing customers)
- `realtor_leads` — lead-specific data (score, source, pipeline stage)
- `realtor_lead_activities` — activity log per lead
- `realtor_lead_routing_rules` — configurable routing
- `realtor_automations` — drip campaign definitions
- `realtor_automation_steps` — individual steps in drip sequences
- `realtor_automation_enrollments` — contacts enrolled in automations

### Transactions
- `transactions` — deal records
- `transaction_milestones` — timeline items
- `transaction_parties` — people involved
- `transaction_documents` — uploaded docs
- `transaction_templates` — closing checklists by type/state
- `transaction_notes` — communication log
- `transaction_health_log` — health score history

### Listings
- `listings` — active/sold listings
- `listing_showings` — showing schedule
- `listing_feedback` — feedback from buyer's agents
- `listing_marketing` — marketing materials generated
- `listing_open_houses` — open house events
- `listing_open_house_signins` — sign-in records

### Smart CMA
- `cma_reports` — CMA records
- `cma_comps` — selected comparables
- `cma_shares` — share links

### Commission
- `commission_plans` — plan definitions
- `commission_records` — per-transaction calculations
- `commission_caps` — per-agent cap tracking
- `commission_1099` — year-end tax data

### Seller Finder
- `seller_finder_territories` — farm areas
- `seller_finder_prospects` — property-level prospect data
- `seller_finder_interactions` — touchpoint log
- `seller_finder_campaigns` — outreach campaigns
- `seller_finder_market_reports` — generated reports

### Dispatch
- `dispatch_work_orders` — work order records
- `dispatch_bids` — contractor bids
- `dispatch_contractor_directory` — contractor database (shared)
- `dispatch_email_events` — delivery tracking
- `dispatch_ratings` — two-way ratings

### Brokerage Admin
- `agent_compliance` — license, CE, E&O tracking
- `agent_onboarding` — onboarding workflow status
- `recruiting_prospects` — recruiting pipeline

### Cross-Platform
- `cross_company_links` — account linking
- `cross_company_shares` — share permissions
- `cross_company_share_log` — audit trail

### Marketing
- `marketing_campaigns` — campaign records
- `marketing_templates` — design templates
- `marketing_social_posts` — scheduled social posts

### Settings
- `realtor_settings` — company/office/team/agent level settings (JSON)

---

## 25. LIFECYCLE WORKFLOWS

### Workflow 1: Listing Lifecycle (Seller Side)
```
1. Seller Finder identifies prospect (or referral/cold call)
2. Agent contacts prospect → qualifies → sets listing appointment
3. Agent generates Smart CMA for listing presentation
4. Listing appointment → CMA presented → listing agreement signed
5. Listing created in system
6. Marketing Factory fires: photos → description → social → email → flyer → website
7. Showings scheduled, feedback collected
8. Offers received → compared → accepted
9. Transaction Engine takes over: contract parsed → timeline generated → parties coordinated
10. Deal Health monitored throughout (GREEN/YELLOW/RED)
11. Client Tracker keeps seller informed
12. Closing → commission recorded → CDA generated → 1099 tracked
13. Post-close: Just Sold marketing → review request → past client nurture
14. Agent's farm market share increases → Seller Finder captures this
```

### Workflow 2: Buyer Lifecycle
```
1. Lead enters system (website, ad, referral, open house, Zillow)
2. Speed-to-lead: auto-text within 60 seconds
3. Lead scored → routed to agent (based on rules)
4. Agent qualifies: timeline, budget, pre-approval, preferences
5. Buyer profile created with preferences
6. Saved search + listing alerts activated (MLS Phase 2, or manual)
7. Showings scheduled → route optimized
8. Buyer tour executed → feedback collected per property
9. Offer written → submitted → negotiated
10. If inspection needed: inspector dispatched via dispatch engine
11. If repairs identified: repair costs from estimation engine → negotiation leverage
12. Transaction Engine: contract parsed → timeline → parties → health monitoring
13. Client Tracker keeps buyer informed
14. Closing → commission → CDA → 1099
15. Post-close: branded vendor list sent → review request → past client nurture
```

### Workflow 3: Dispatch-to-Contractor Lifecycle
```
1. Realtor identifies repair need (from inspection, CMA, client request)
2. Creates work order: photos, description, trade needed, address, urgency
3. AI enhances description (if AI budget allows — Sonnet for quick jobs, Opus for full scans)
4. System matches contractors: 200 trade-matched within 50 miles
5. Staggered email dispatch (batches of 20 every 3 minutes)
6. Contractors click → view job detail page → submit bid
7. If contractor has no Zafto account: creates one (30 seconds, email + company + trade)
8. Contractor gets full field tools access (35+ calculators, all trade tools)
9. Bids collected → realtor compares (side-by-side, up to 3)
10. Realtor accepts bid → contractor notified → project enters tracking
11. Contractor updates status + uploads GPS-stamped photos
12. Realtor monitors progress → client notified of updates
13. Work complete → contractor submits documentation → realtor approves
14. Both parties rate each other
15. If cross-platform linked: repair costs, photos, estimates shared to CMA/reports
```

### Workflow 4: Brokerage Agent Lifecycle
```
1. Recruiting: prospect identified → value proposition sent → conversations tracked
2. Agent joins: onboarding workflow triggered (18 steps)
3. License verified, ICA signed, W-9 collected, MLS/NAR membership confirmed
4. Commission plan assigned, system access provisioned
5. Agent begins: leads routed, territory assigned, AI budget allocated
6. Ongoing: production tracked, compliance monitored (license/CE/E&O auto-alerts)
7. Performance: leaderboard ranking, cap progress, GCI tracking
8. If agent leaves: offboarding workflow, data ownership transfer, contact portability
```

---

## 26. MLS INTEGRATION STRATEGY

### Phase 1: Zero Cost (Launch)
- Public records for property data (county assessor APIs — free)
- Manual agent input for specific listings
- Deep links to Zillow/Redfin for full listing details
- Smart CMA uses public records + Recon data (no MLS needed)
- Cost: $0/month

### Phase 2: Target Markets ($200-500/month)
- Apply as technology vendor to 3-5 large MLSs in target markets
- Use Spark API ($50/MLS) or SimplyRETS ($49-99/mo base) as normalization layer
- Agents must be MLS members — their membership endorses vendor application
- Unlocks: sold comps in Smart CMA, listing alerts for buyers, agent production stats

### Phase 3: Scale (Post-Revenue)
- Repliers ($199-399/mo) or Trestle for broader coverage
- Add MLSs based on user demand (where agents are signing up)
- VOW license for full sold data access

### What We NEVER Do
- Screen scrape MLS websites
- Use agent credentials to access MLS data
- Build on RETS (deprecated standard)
- Try for nationwide coverage at launch

---

## 27. REVENUE MODEL

| Tier | Monthly | What's Included |
|------|---------|-----------------|
| **Solo Agent** | $99/mo | Full CRM, Smart CMA (5/mo), Seller Finder (1 territory), Recon, Sketch Engine, dispatch, marketing factory, 15 AI scans/mo, transaction management |
| **Team** (up to 10) | $299/mo | Everything in Solo + team pipeline, lead routing, team reporting, commission tracking, 50 AI scans/mo |
| **Brokerage** (unlimited agents) | $999/mo | Everything in Team + unlimited agents, brokerage admin, compliance dashboard, recruiting, custom roles, 200 AI scans/mo, priority support |
| **Enterprise** (100+ agents) | Custom | Everything + dedicated success manager, custom integrations, SLA, white-label options |

**Add-ons:**
- Additional AI scans: $2/scan after monthly allotment
- Additional territories (Seller Finder): $29/territory/mo
- MLS integration (Phase 2): $49/MLS/mo pass-through
- FLIP module access: $49/mo (paid add-on, same as contractor)

**Free trial:** 3 work order dispatches, 1 Smart CMA, 1 territory scan — no credit card required

**Comparison to current agent spend:**
- Solo agent replaces: $352-675/mo of tools → saves $253-576/mo
- Brokerage of 50 agents replaces: $13,800-24,000/mo → saves $12,800-23,000/mo

---

## 28. SPRINT BREAKDOWN (Estimated)

| Sprint | Description | Est Hours |
|--------|-------------|-----------|
| **RE1** | Portal scaffold + auth + RBAC (brokerage roles, permissions, company_type) | ~24h |
| **RE2** | CRM foundation — contacts, leads, pipeline, lead scoring, speed-to-lead | ~28h |
| **RE3** | Smart CMA Engine — data pipeline, AI analysis, comp selection, adjustments, Zillow counter, PDF/web output | ~32h |
| **RE4** | Transaction Engine — contract parsing, timeline generation, milestone tracking, multi-party, deal health | ~32h |
| **RE5** | Transaction Engine 2 — client tracker (Domino's view), document management, post-close automation, state compliance | ~24h |
| **RE6** | Seller Finder Engine — territory claiming, data ingestion, scoring, contact enrichment, command center | ~28h |
| **RE7** | Seller Finder 2 — outreach engine, market reports, door-knock routes, campaign tracking, attribution | ~20h |
| **RE8** | Commission Engine — plan builder, per-transaction calculation, CDA generation, cap tracking, 1099 data, agent dashboard | ~20h |
| **RE9** | Dispatch Engine — work orders, contractor DB, email dispatch, bid collection, landing pages, tracking, ratings | ~24h |
| **RE10** | Listing Management — CMA integration, marketing automation, showing management, feedback, open house, price intelligence | ~24h |
| **RE11** | Buyer Management — preference profiles, saved searches, tour routing, offer tracking, buyer tour sheets | ~16h |
| **RE12** | Marketing Factory — listing description AI, social posts, flyers, property website, virtual staging, direct mail, video | ~24h |
| **RE13** | Brokerage Admin — agent roster, onboarding workflow, compliance dashboard, commission plans, 1099 generation | ~24h |
| **RE14** | Lead Gen Pipeline — Socrata data ingestion, skip tracing integration, outreach automation, DNC compliance | ~20h |
| **RE15** | Cross-Platform Sharing — account linking, granular permissions, data sharing, audit trail | ~16h |
| **RE16** | Settings Architecture — cascading settings (company→office→team→agent), notification config, branding, integrations | ~16h |
| **RE17** | Recon + Sketch + PM access — role-based access to existing features, realtor-specific views, portal hooks | ~12h |
| **RE18** | Mobile Screens — all realtor/broker/TC/ISA Flutter screens, navigation, dashboards | ~28h |
| **RE19** | Portal Polish — responsive design, loading/empty/error states, keyboard shortcuts, search | ~16h |
| **RE20** | QA + Security — RLS audit on all new tables, permission testing, cross-company isolation verification | ~16h |
| **TOTAL** | | **~444h** |

**Note:** AI features (Z-Intelligence for realtors, AI chat, photo analysis, growth advisor) are built during Phase E — not included in these sprints. The portal is built AI-READY so Phase E slots in without code changes.

---

## LEGAL DISCLAIMERS (Must Include)

### Commission Engine
- "This software is a calculation tool. It does not provide financial, legal, or accounting advice."
- "All calculations should be verified by the user before use in any financial transaction."
- "Zafto does not handle, hold, or disburse any funds."

### Smart CMA
- "Property valuations are estimates based on public data and should not be relied upon as appraisals."
- "A licensed appraiser should be consulted for lending or legal purposes."

### Lead Generation
- "Users are responsible for compliance with all applicable telemarketing, email, and SMS regulations including TCPA, CAN-SPAM, and state-specific Do Not Call laws."
- "Zafto does not guarantee the accuracy of public records data."

### General
- Standard "AS IS" warranty disclaimer
- Liability capped at 12 months of fees
- User indemnification clause

---

*End of spec. This document is the foundation for Zafto Realtor — a full platform equal in depth to Zafto Contractor. Every feature must be comprehensive, every workflow must be complete, every tool must be professional-grade. Depth is non-negotiable.*
