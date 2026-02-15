# ZAFTO UNIVERSAL AI ARCHITECTURE — Intelligence Layer
## Created: February 5, 2026 (Session 31)
## Refined: February 5, 2026 (Session 32 — Hive Intelligence Update)
## Revised: February 5, 2026 (Session 33 — Scope Fixes + Code Strategy)
## Status: DRAFT — REVIEWED. Exam system scrapped, code strategy finalized (Option B),
##         standalone calculators removed, ZAFTO-connected tools kept.

---

## PURPOSE

One AI. Every trade. Every role. Every context. Every app. One brain that gets smarter
with every interaction across the entire platform.

ZAFTO's intelligence layer is not a collection of tools. It is a single AI assistant
that knows who it's talking to, what they need, what they've needed before, what they're
doing right now, and what the collective intelligence of all ZAFTO users can teach it
about the question being asked.

The AI doesn't need separate training per trade. It needs the right CONTEXT per conversation,
MEMORY across conversations, AWARENESS of the current workflow, and ACCESS to patterns
learned from the entire platform.

---

## STRATEGIC DECISION: CONTENT OVERHAUL

| Content | Count | Decision | Rationale |
|---------|:-----:|----------|-----------|
| Standalone Calculators | 1,186 | **REMOVED** | Single-purpose calculators (wire sizing, conduit fill, voltage drop, etc.) are redundant. Claude already knows every formula, every code table. Z calculates anything on demand with context awareness. |
| Exam Questions | 5,080 | **REMOVED / SCRAPPED** | Entire exam system is cut from scope. Not part of the ZAFTO product direction. |
| Diagrams | 111 | **EVALUATE** | Some visual references may still add value as AI-referenced images. Decision TBD in review session. |
| Reference Guides | 21 | **REMOVED** | AI answers reference questions contextually, with citations, interactively. Static guides are inferior in every way. |
| Field Tools | 14 | **KEEP** | Data capture tools (photos, GPS, time clock, safety) need real UI. These aren't knowledge — they're workflows. |
| ZAFTO-Connected Tools | — | **KEEP** | Any tool that integrates with ZAFTO's ecosystem (AI scanning, job-linked tools, bid builders, equipment logs, etc.) stays. These are workflow tools, not standalone calculators. |

Adding a new trade is no longer a 6-month content buildout. It's a knowledge corpus
upload that takes days. The AI handles everything else.

---

## THE SIX LAYERS

The original architecture defined three layers. This refinement adds three more that
transform Z from "smart assistant" into "hive intelligence that compounds over time."

```
Layer 1: Identity Context     — Who are you? (role, trade, state, company)
Layer 2: Knowledge Retrieval  — What does the AI reference? (RAG, code books, standards)
Layer 3: Persistent Memory    — What does Z remember about YOU? (cross-session intelligence) [NEW]
Layer 4: Session Context      — What are you doing RIGHT NOW? (cross-feature awareness) [NEW]
Layer 5: Compounding Intel    — What has the PLATFORM learned? (aggregate patterns) [REBUILT]
Layer 6: RBAC Intelligence    — What is Z ALLOWED to reveal to this role? [NEW]
```

Every AI call flows through all six layers. The edge function assembles context from
each layer, builds the prompt, calls Claude, returns the response, and updates the
layers that learn (3 and 5).

---

### Layer 1: Identity Context — Who Are You?

Every AI interaction begins with a dynamically-built system prompt constructed from
the user's database profile. No two users get the same AI experience.

**Data sources (already exist in Supabase schema):**
- `users` table: name, role, email
- `companies` table: trade(s), state, license info, subscription tier, employee count
- `employees` table: role (Owner/Admin/Office/Tech), certifications, skills
- `customers` table: (for homeowner context) property info, equipment, contractor relationship
- `jobs` table: active job context (address, scope, status)
- State/jurisdiction: determines which code cycle, which amendments, which regulations

**Four primary personas:**

#### A. Field Professional (Technician/Journeyman/Apprentice)
```
Context injected:
- Their trade(s) and certification level
- Their state + applicable code cycle + local amendments
- Their active job (if any) — address, scope, customer
- Their role permissions (what they can/can't approve)
- Their company's preferences (preferred suppliers, safety protocols)

AI behavior:
- Speaks as a senior tradesperson to a peer
- Cites code sections, standards, manufacturer specs
- Shows work on calculations (step by step)
- Knows RBAC limits ("you'll need your boss to approve that PO")
- Safety-first on everything
- Can reference visual diagrams/photos when helpful
- NEVER reveals pricing intelligence, margin data, time benchmarks,
  or competitive bid comparisons (see Layer 6)
```

#### B. Homeowner / Property Owner
```
Context injected:
- Their property profile (address, age, type, size)
- Their equipment inventory (make, model, age, warranty status)
- Their preferred contractor (from contractor relationship)
- Their service history (past jobs, upcoming maintenance)

AI behavior:
- Plain English, no trade jargon
- NEVER undermines contractor relationship
- NEVER provides specific pricing
- NEVER recommends DIY for anything involving safety risk
- Explains what work involves so they're informed clients
- Routes to preferred contractor for action items
- Equipment health awareness ("your AC is 10 years old, typical lifespan is 12-15")
```

#### C. Business Owner / Admin
```
Context injected:
- Full company data access (jobs, invoices, bids, customers, employees, financials)
- Business metrics (revenue, outstanding invoices, cash position)
- Operational context (upcoming inspections, overdue items, employee schedules)
- Market context (their trade, their region, their competitive landscape)
- Full compounding intelligence access (pricing, time benchmarks, win rates)

AI behavior:
- Full technical trade knowledge + business operations
- Can discuss pricing strategy, bidding, profitability, hiring, scheduling
- Pulls live data from their account for business questions
- Financial advice caveated with "consult your CPA"
- Strategic thinking — "you've got 3 apprentices billing at journeyman rates,
  that's why margins are thin on residential jobs"
- Regional comparables: "jobs like this in your area bid $2,800-3,600"
- Time intelligence: "your average completion time on these is 4.2 hours"
```

#### D. Office Manager
```
Context injected:
- Operational data (schedule, pipeline, invoices, follow-ups)
- Customer communication history
- Team availability and capacity
- Company-level settings for what this role can see (owner-configured)

AI behavior:
- Operational focus: scheduling, follow-ups, customer communication
- Invoice aging, payment tracking, pipeline velocity
- Draft emails, appointment confirmations, follow-up reminders
- NEVER reveals margin data unless owner has enabled it for this role
- Sees time benchmarks only if owner has enabled it
```

---

### Layer 2: Knowledge Retrieval — What Does the AI Reference?

Claude's training data already contains NEC, IPC, IMC, IRC, OSHA, building codes,
manufacturer specifications, trade practices, business management, insurance, and more.

For ZAFTO to go beyond "AI says so" to "AI can cite its source and show its work,"
a retrieval layer provides verified reference material per trade.

#### CRITICAL: Code Content Strategy (Option B — Factual Knowledge + Deep Links)

Model codes (NEC, IPC, IMC, IRC, IBC, UPC) are copyrighted by private organizations
(NFPA, ICC, IAPMO). ZAFTO does NOT host, embed, or distribute copyrighted code text
in any form — including encoded, paraphrased line-by-line, or obfuscated versions.

Instead, ZAFTO's knowledge corpus is built from:

1. **ZAFTO's own structured factual reference data** — Engineering facts, ampacity
   ratings, derating factors, clearance requirements, sizing rules, etc. written in
   ZAFTO's own voice. Facts are not copyrightable. The ampacity of 2/0 copper is
   physics, not NFPA's intellectual property.

2. **Government-published content (public domain)** — OSHA regulations, EPA 608,
   state licensing requirements, government incentive programs (ITC solar credits,
   state rebates, utility programs), SBA resources, insurance regulations, workers
   comp requirements, lien laws, permit requirements. All free to ingest.

3. **State amendments to model codes (public documents)** — When a state amends
   the NEC/IPC/etc., that amendment is a government document. Fair game.

4. **Manufacturer specifications (freely published)** — Installation manuals, spec
   sheets, error codes, wiring diagrams from Carrier, Rheem, Square D, Eaton, etc.
   All publicly distributed by the manufacturers themselves.

5. **Claude's training knowledge** — Already contains massive trade code knowledge.
   Handles 90%+ of real field questions accurately without RAG supplementation.

6. **User corrections from licensed professionals** — The correction pipeline (see
   Feedback section below) continuously improves accuracy from real-world use.

When Z needs to reference the actual codebook language, it cites the section number
and **deep links the user directly to the publisher's free online viewer**:
- NFPA offers free read-only access to NEC at nfpa.org
- ICC offers free read-only access to IPC/IMC/IRC at codes.iccsafe.org

Z does the thinking. The official source does the verification. ZAFTO is the bridge.

**FUTURE UPGRADE PATH:** When ZAFTO has revenue and traction, pursue commercial
digital licensing from NFPA and ICC to embed actual code text natively in the RAG
pipeline. The architecture supports this — just swap better source material into the
same corpus structure. No code changes needed.

#### Deep-Link Citation System

Every AI response that references a code section includes a tappable citation that
opens the official code viewer. This is powered by a reference index:

```sql
CREATE TABLE code_references (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_body TEXT NOT NULL,        -- 'NEC', 'IPC', 'IMC', 'IRC', 'IBC', 'UPC'
  edition TEXT NOT NULL,          -- '2023', '2020'
  section TEXT NOT NULL,          -- '310.16', '210.12(A)', 'P2904.1'
  title TEXT,                     -- 'Ampacity Table', 'AFCI Protection'
  topic_tags TEXT[],              -- ['wire_sizing', 'ampacity', 'derating']
  deep_link_url TEXT NOT NULL,    -- Direct URL to free viewer section
  trade TEXT NOT NULL,            -- 'electrical', 'plumbing', 'hvac', etc.
  adopted_states TEXT[],          -- States that have adopted this edition
  state_amendment_notes JSONB,    -- Per-state amendment overrides
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(code_body, edition, section)
);

-- Index for fast lookup during AI response generation
CREATE INDEX idx_code_refs_lookup
  ON code_references(code_body, section, trade);
```

**How it works in Z's responses:**

```
User: "Do I need AFCI in this bedroom in Connecticut?"

Z: "Yes — AFCI protection is required in all habitable rooms including
    bedrooms. Note that CT adopted an exception for existing wiring in
    pre-2008 homes if the circuit isn't being modified.

    📖 NEC 210.12(A) — AFCI Protection [tap to view in official code]
    📖 CT State Amendment — Exception for existing wiring [link]"
```

The user gets a smart, contextual answer AND direct access to the official source.
No copyrighted text stored in ZAFTO. Clean.

#### Knowledge Corpus Structure

```
knowledge/
├── universal/
│   ├── app_help/              → How to use ZAFTO features
│   ├── business/              → Bidding, pricing, cash flow, hiring, growth
│   ├── safety/                → OSHA regulations (public domain, full text)
│   ├── insurance/             → GL, workers comp, bonding, certificates
│   ├── legal/                 → Licensing requirements, lien laws, contracts
│   └── government_programs/   → Federal/state incentives, SBA, rebates
│
├── electrical/
│   ├── factual_reference/     → ZAFTO-authored: ampacity, derating, fill, sizing
│   ├── state_amendments/      → Per-state amendments (public government docs)
│   ├── osha_electrical/       → OSHA electrical standards (public domain)
│   ├── equipment/             → Manufacturer specs, install guides, error codes
│   └── code_index/            → Section-to-deep-link mapping for NEC citations
│
├── plumbing/
│   ├── factual_reference/     → ZAFTO-authored: pipe sizing, fixture units, venting
│   ├── state_amendments/
│   ├── equipment/             → Manufacturer specs
│   └── code_index/            → Section-to-deep-link mapping for IPC/UPC
│
├── hvac/
│   ├── factual_reference/     → ZAFTO-authored: load calcs, refrigerant, duct sizing
│   ├── epa_608/               → EPA 608 regulations (public domain, full text)
│   ├── equipment/             → Major brands, error codes, refrigerant specs
│   └── code_index/            → Section-to-deep-link mapping for IMC
│
├── solar/
│   ├── factual_reference/     → ZAFTO-authored: system sizing, interconnection rules
│   ├── incentives/            → Federal ITC, state rebates, utility programs (public)
│   ├── equipment/             → Panel specs, inverter specs, battery specs
│   └── code_index/            → Deep links for NEC Art 690/705
│
├── roofing/
│   ├── factual_reference/     → ZAFTO-authored: slope, underlayment, fastening
│   ├── manufacturers/         → GAF, Owens Corning, CertainTeed install specs
│   └── code_index/            → Deep links for IRC Ch 9
│
├── general_contractor/
│   ├── factual_reference/     → ZAFTO-authored: structural, permitting, coordination
│   ├── project_management/    → Scheduling, sub coordination
│   └── code_index/            → Deep links for IRC/IBC
│
├── remodeler/
│   ├── factual_reference/     → ZAFTO-authored: existing structures, lead/asbestos
│   ├── epa_lead/              → EPA RRP Rule (public domain, full text)
│   └── code_index/            → Deep links for IRC existing structures
│
├── landscaping/
│   ├── factual_reference/     → ZAFTO-authored: grading, drainage, irrigation
│   ├── regional/              → Climate zones, hardiness, water restrictions
│   └── pesticide_regs/        → State pesticide applicator regs (public)
│
└── [future trades]/
    └── Same pattern — factual_reference, public_regs, equipment, code_index
```

**Retrieval mechanism:**
1. User sends a message
2. System identifies user's trade(s) from Layer 1
3. Query is embedded and matched against relevant knowledge corpus
4. Top matching documents injected into AI context alongside user message
5. AI responds with factual knowledge + code section citations
6. Citations auto-linked via code_references table deep links
7. Cross-trade queries pull from multiple corpora automatically

This is RAG (Retrieval-Augmented Generation) — standard pattern, well-understood,
no custom model training needed.

---

### Layer 3: Persistent Memory — What Does Z Remember About YOU? [NEW]

This is the layer that makes Z feel like it actually knows you. Not just your database
profile (Layer 1 handles that) — but a synthesized understanding of who you are as a
professional, how you work, what you struggle with, what you excel at, and how you
prefer to communicate.

**The difference between Layer 1 and Layer 3:**

```
Layer 1 (Identity):  "This is Mike, journeyman electrician, works at Bright Wire LLC
                      in CT, currently on Job #4521 at 45 Oak Street."

Layer 3 (Memory):    "Mike is strong on residential but asks a lot of questions about
                      commercial three-phase. He's studying for his master's exam and
                      struggles with grounding electrode systems. He prefers step-by-step
                      breakdowns over quick answers. He usually works alone. Last week
                      he asked about derating for a 200A panel upgrade — that job is
                      still active. He corrected Z on a CT state amendment last month
                      and that correction was valid."
```

Layer 1 is facts from the database. Layer 3 is understanding from relationship.

**Schema:**

```sql
CREATE TABLE ai_user_memory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  company_id UUID REFERENCES companies(id),
  persona TEXT NOT NULL,              -- 'contractor', 'homeowner', 'office'
  memory_profile JSONB NOT NULL,      -- The synthesized understanding
  version INTEGER DEFAULT 1,          -- Increments on each update
  last_interaction_at TIMESTAMPTZ,
  interaction_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, persona)
);
```

**Memory profile structure (JSONB):**

```json
{
  "professional": {
    "strengths": ["residential wiring", "panel upgrades", "troubleshooting"],
    "growth_areas": ["commercial three-phase", "grounding electrode systems"],
    "certification_pursuit": "CT Master Electrician",
    "experience_level": "mid-career journeyman, 6+ years",
    "work_style": "solo operator, methodical, asks detailed questions"
  },
  "communication": {
    "preferred_depth": "detailed step-by-step over quick answers",
    "jargon_comfort": "high — speaks fluent trade language",
    "response_format": "prefers numbered steps for procedures",
    "patience_level": "will ask follow-ups, doesn't want to be talked down to"
  },
  "corrections": [
    {
      "date": "2026-01-28",
      "topic": "CT state amendment to NEC 210.12",
      "original_response": "AFCI required in all habitable rooms",
      "correction": "CT adopted exception for existing wiring in pre-2008 homes",
      "validated": true
    }
  ],
  "active_threads": [
    {
      "topic": "200A panel upgrade at 45 Oak Street",
      "last_discussed": "2026-02-03",
      "key_context": "derating for 6 current-carrying conductors in 3/4 EMT"
    }
  ],
  "meta": {
    "total_interactions": 147,
    "first_interaction": "2026-01-15",
    "topics_discussed": 89,
    "corrections_submitted": 3
  }
}
```

**How memory updates:**

```
After each conversation ends (or after N messages if long conversation):

STEP 1 — GATE CHECK (Haiku — cheap, fast):
  Edge function sends conversation summary to Haiku with prompt:
  "Does this conversation contain anything worth remembering?
   Answer YES if: user revealed expertise/weakness, corrected Z,
   discussed an active project, showed communication preferences,
   or had a substantive multi-turn exchange.
   Answer NO if: simple lookup, one-off question, no personal signal."

  If NO → skip memory update entirely. Save the Sonnet call.
  (~60-70% of conversations are simple lookups that get filtered here)

STEP 2 — OBSERVATION EXTRACTION (Sonnet — reliable reasoning):
  Edge function sends to Claude Sonnet:
  - The conversation transcript
  - Prompt: "Extract observations from this conversation. Return a simple
    JSON array of observations, each with: category (strength, growth_area,
    correction, active_thread, communication_pref), content (text), and
    confidence (high/medium/low). Only include clear signals, not guesses.
    Return ONLY the observations array, nothing else."

  WHY SONNET FOR EXTRACTION, NOT FULL PROFILE REWRITE:
  - Asking an LLM to rewrite an entire structured JSONB profile risks
    schema drift, data corruption, and silent field drops at scale
  - Instead, Sonnet extracts OBSERVATIONS (simple, small, validatable)
  - A deterministic merge function handles the actual profile update
  - This is safer at 10K+ users — fewer corrupted profiles

  Example Sonnet output:
  [
    {"category": "strength", "content": "commercial three-phase wiring", "confidence": "medium"},
    {"category": "active_thread", "content": "200A panel upgrade at 45 Oak St", "confidence": "high"},
    {"category": "communication_pref", "content": "prefers step-by-step breakdowns", "confidence": "high"}
  ]

STEP 3 — DETERMINISTIC MERGE (Edge function logic, NOT LLM):
  The edge function receives Sonnet's observations and applies them
  to the existing memory_profile using deterministic rules:

  - strength observations → append to professional.strengths (deduplicate)
  - growth_area observations → append to professional.growth_areas (deduplicate)
  - correction observations → append to corrections array with date
  - active_thread observations → upsert to active_threads by topic similarity
  - communication_pref observations → update communication object fields
  - Low-confidence observations are stored but not surfaced until reinforced
  - Stale active_threads (>30 days) auto-pruned by date check
  - Profile capped at 2000 tokens — oldest low-confidence items trimmed first

  This merge function is ~100 lines of deterministic TypeScript.
  It NEVER corrupts the profile because it NEVER rewrites the whole thing.
  It only adds, updates, or prunes specific fields.

STEP 4 — Edge function validates merged profile against JSON schema
  If validation fails → log error, keep existing profile, alert for review
  If validation passes → upsert to ai_user_memory with version++
```

**Memory consolidation (scheduled — weekly):**

```
Profiles that exceed 1500 tokens get a consolidation pass:
- Sonnet reviews the full profile
- Merges redundant observations
- Removes stale data (old active_threads, outdated growth_areas if mastered)
- Ensures the profile stays tight and high-signal
- JSON schema validated before write
```

**Cost (revised):**

```
Gate check (Haiku):    ~100 tokens = ~$0.00005 per conversation
                       Runs on ALL conversations

Memory update (Sonnet): ~700 tokens = ~$0.003 per update
                        Runs on ~30-40% of conversations (passes gate)

At 5 conversations/day per user:
  Gate checks:    5 × $0.00005 = $0.00025/day
  Sonnet updates: 1.75 × $0.003 = $0.00525/day
  Total:          ~$0.17/month per user

On $29/mo plan = 0.6% of revenue
On $149/mo plan = 0.1% of revenue

Worth every penny for the thing that makes Z feel like it knows you.
```

**Cross-session continuity example:**

```
Monday: Mike asks about derating factors for a panel upgrade.
        Z gives detailed answer. Memory logs "active thread: 200A panel upgrade."

Thursday: Mike opens Z and says "hey, remember that panel job?"
          Z loads memory → sees the active thread → responds:
          "The 200A panel upgrade at Oak Street — last we talked you were working
          through derating for 6 conductors in the 3/4 EMT run. How's it going?"

No conversation_id needed. No scrolling back. Z just knows.
```

---

### Layer 4: Session Context Buffer — What Are You Doing RIGHT NOW? [NEW]

Layer 3 is long-term memory. Layer 4 is working memory. It answers: "what is this
user doing in the app right now, and what were they doing 30 seconds ago?"

Without this layer, every AI call is context-blind about the user's current workflow.
With it, Z maintains a running thread of intent across feature navigation within a
single app session.

**The problem it solves:**

```
Without session buffer:
  User is on Job #4521 detail screen → opens Z → "what wire size do I need?"
  Z: "I need more context. What amperage? What distance? What conduit?"

With session buffer:
  User is on Job #4521 (200A panel upgrade, 45 Oak St) → opens Z → "what wire size?"
  Z: "For the 200A panel upgrade at Oak Street — you'll need 2/0 copper or
  4/0 aluminum for the service entrance conductors per NEC 310.16. Are you
  running in conduit or SE cable?"
```

Z already knew the job. The user didn't have to repeat themselves.

**Implementation — App Side (per platform):**

Each app maintains a lightweight SessionContext object that tracks:

```dart
// Flutter (Mobile App) — ~80 lines of code
class SessionContext {
  String? currentScreen;           // "job_detail"
  List<String> screenHistory;      // ["dashboard", "job_list", "job_detail"]
  String? activeJobId;             // From job detail, bid screen, etc.
  String? activeCustomerId;        // From customer detail, job, bid
  String? activeBidId;             // From bid creation/editing
  String? activeInvoiceId;         // From invoice screen
  String? lastAiInteractionSummary; // "Discussed derating for panel upgrade"
  String? inferredIntent;          // "creating_bid", "reviewing_job", "studying"
  DateTime sessionStartedAt;
  DateTime lastActivityAt;
}
```

```typescript
// Next.js (Web CRM) — React context provider, ~60 lines
interface SessionContext {
  currentScreen: string;
  screenHistory: string[];
  activeJobId?: string;
  activeCustomerId?: string;
  activeBidId?: string;
  activeInvoiceId?: string;
  lastAiSummary?: string;
  inferredIntent?: string;
}
```

**Intent inference (simple, not ML):**

```
Navigation pattern → Inferred intent:

Job Detail → Calculator → Bid Screen     = "building_bid_for_job"
Dashboard → Customer List → Customer     = "reviewing_customer"
Exam Prep → Study → Quiz                 = "studying_for_certification"
Invoice List → Overdue filter            = "chasing_payments"
Schedule → Open slots                    = "scheduling_work"
Job Detail → Photos → AI Chat            = "documenting_or_diagnosing"
```

The inference doesn't need to be perfect. It's a hint that makes Z smarter.
If it's wrong, Z still works — it just asks one clarifying question instead
of zero. The fallback is always: send raw navigation context to Claude and
let it figure out intent. Opus handles that fine.

**How it flows to the edge function:**

```json
// Included in every AI request payload
{
  "session_context": {
    "current_screen": "bid_creation",
    "screen_history": ["dashboard", "job_list", "job_detail", "bid_creation"],
    "active_job_id": "uuid-4521",
    "active_customer_id": "uuid-johnson",
    "inferred_intent": "building_bid_for_job",
    "last_ai_summary": "Discussed derating factors for 200A panel upgrade",
    "session_duration_minutes": 12
  }
}
```

The edge function receives this, serializes relevant context into the prompt,
and Z responds with full awareness of what the user is doing.

**Session lifecycle:**
- Starts when user opens the app
- Updates on every screen navigation
- Persists across AI interactions within the session
- Clears when app is closed or after 30 minutes of inactivity
- NOT persisted to database (it's ephemeral working memory)
- Layer 3 (persistent memory) captures anything worth keeping long-term

---

### Layer 5: Compounding Intelligence — What Has the PLATFORM Learned? [REBUILT]

The original spec listed what compounds. This rebuild defines HOW it compounds —
the actual pipelines, schedules, confidence thresholds, and query patterns that
turn raw data into intelligence Z can use.

**The principle:** Every completed job, every won/lost bid, every equipment scan,
every drying log, every exam attempt across the entire platform feeds aggregate
patterns that make Z smarter for every individual user. No single company's data
is exposed. Only anonymized, aggregated patterns emerge.

**Schema:**

```sql
CREATE TABLE intelligence_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pattern_type TEXT NOT NULL,          -- 'job_duration', 'bid_pricing', 'equipment_lifespan',
                                       -- 'material_cost', 'bid_win_rate', 'failure_pattern'
  trade TEXT NOT NULL,                 -- 'electrical', 'plumbing', 'hvac', etc.
  region TEXT,                         -- State, or zip prefix for geo-specific patterns
  job_category TEXT,                   -- 'panel_upgrade', 'water_heater', 'furnace_replace'
  data JSONB NOT NULL,                 -- The actual pattern data (structure varies by type)
  sample_size INTEGER NOT NULL,        -- How many data points this is based on
  confidence FLOAT,                    -- 0.0-1.0, calculated from sample size + variance
  min_sample_threshold INTEGER DEFAULT 25, -- Don't surface until N data points exist
  last_computed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(pattern_type, trade, region, job_category)
);

-- Index for fast lookups during AI context building
CREATE INDEX idx_patterns_lookup
  ON intelligence_patterns(trade, region, pattern_type)
  WHERE sample_size >= min_sample_threshold;
```

**Pattern types and their data structures:**

```
PATTERN: job_duration
PURPOSE: How long jobs actually take vs estimates
DATA: {
  "median_hours": 4.2,
  "p25_hours": 3.1,
  "p75_hours": 5.8,
  "median_vs_estimate_ratio": 1.15,  // jobs take 15% longer than estimated
  "by_company_size": {
    "solo": { "median": 5.1 },
    "2-5": { "median": 4.0 },
    "6+": { "median": 3.4 }
  }
}
WHO SEES IT: Owner/Admin only (Layer 6 enforces)
```

```
PATTERN: bid_pricing
PURPOSE: What jobs like this actually bid at in this region
DATA: {
  "median_bid": 3200,
  "p25_bid": 2400,
  "p75_bid": 4100,
  "win_rate_by_quartile": {
    "below_p25": 0.78,    // cheap bids win more
    "p25_p50": 0.61,
    "p50_p75": 0.44,
    "above_p75": 0.29     // expensive bids win less
  },
  "material_pct_of_total": 0.35,
  "labor_pct_of_total": 0.55,
  "overhead_pct_of_total": 0.10
}
WHO SEES IT: Owner/Admin only
```

```
PATTERN: equipment_lifespan
PURPOSE: How long equipment actually lasts (from install to replacement data)
DATA: {
  "brand": "Carrier",
  "model_family": "24ACC6",
  "median_lifespan_years": 12.4,
  "p25_years": 9.1,
  "p75_years": 15.8,
  "common_failure_modes": ["compressor", "capacitor", "contactor"],
  "climate_zone_adjustment": { "hot_humid": -1.5, "cold": +0.8 }
}
WHO SEES IT: Everyone (not business-sensitive)
```

```
PATTERN: material_cost
PURPOSE: What materials actually cost in this region
DATA: {
  "item": "200A main breaker panel",
  "median_cost": 289,
  "p25_cost": 245,
  "p75_cost": 340,
  "trend_6mo": +0.04,    // prices up 4% in 6 months
  "common_brands": ["Square D", "Eaton", "Siemens"]
}
WHO SEES IT: Owner/Admin only (reveals cost structure)
```

```
PATTERN: bid_win_rate
PURPOSE: What affects whether bids get accepted
DATA: {
  "overall_win_rate": 0.52,
  "by_response_time": {
    "same_day": 0.68,
    "next_day": 0.55,
    "2-3_days": 0.41,
    "4+_days": 0.23
  },
  "by_follow_up": {
    "followed_up": 0.64,
    "no_follow_up": 0.38
  }
}
WHO SEES IT: Owner/Admin/Office (operational, not cost-revealing)
```

```
PATTERN: failure_pattern
PURPOSE: Common issues by equipment type, age, and conditions
DATA: {
  "equipment_type": "tankless_water_heater",
  "brand": "Navien",
  "common_at_age": "3-5 years",
  "issue": "flow sensor failure",
  "frequency": "high",
  "typical_repair_time_hours": 1.5,
  "parts_commonly_needed": ["flow sensor", "gasket kit"]
}
WHO SEES IT: Everyone (diagnostic intelligence, not business-sensitive)
```

**The pipelines (scheduled Edge Functions via pg_cron):**

```
PIPELINE: compute_job_duration_patterns
SCHEDULE: Nightly at 2:00 AM UTC
LOGIC:
  1. Query completed jobs from last 24 hours
  2. Group by (trade, region, job_category)
  3. For each group:
     a. Calculate median, p25, p75 duration
     b. Calculate estimate-vs-actual ratio
     c. Check sample_size >= min_sample_threshold (25)
     d. If yes: upsert into intelligence_patterns
     e. If no: skip (not enough data to be meaningful)
  4. Log: patterns updated, patterns skipped (insufficient data)
IDEMPOTENT: Yes — upsert on unique constraint, same input = same output
ERROR HANDLING: If pipeline fails, patterns remain at last-computed state. No dirty data.

PIPELINE: compute_bid_pricing_patterns
SCHEDULE: Nightly at 2:30 AM UTC
LOGIC: Same structure. Groups bids by (trade, region, job_category, won/lost).
SPECIAL: Bid win rates recomputed weekly (slower-moving metric).

PIPELINE: compute_equipment_lifespan_patterns
SCHEDULE: Weekly (Sunday 3:00 AM UTC)
LOGIC: Joins equipment installs with equipment replacements on same property.
       Calculates lifespan distributions per brand/model/climate zone.
       Requires 50+ data points per pattern (higher threshold — lifecycle data is noisy).

PIPELINE: compute_material_cost_patterns
SCHEDULE: Nightly at 3:00 AM UTC
LOGIC: Aggregates material line items from completed jobs.
       Geo-adjusts by region. Tracks 6-month price trends.

PIPELINE: compute_failure_patterns
SCHEDULE: Weekly (Sunday 4:00 AM UTC)
LOGIC: Analyzes service/repair jobs. Groups by equipment type, brand, age range.
       Identifies recurring failure modes. Requires 20+ data points per pattern.
```

**Confidence thresholds — when Z speaks vs stays quiet:**

```
Sample size < 25:     Z does NOT surface this pattern. Period.
                      "I don't have enough data to give you a reliable number."

Sample size 25-99:    Z surfaces with explicit uncertainty.
                      "Based on limited data (~50 similar jobs), these typically
                      run 3-5 hours. Take that with a grain of salt."

Sample size 100-499:  Z surfaces with moderate confidence.
                      "Based on a few hundred similar jobs in your region,
                      you're looking at $2,800-3,600 typically."

Sample size 500+:     Z surfaces confidently.
                      "Jobs like this in CT consistently bid $2,800-3,600.
                      Your close rate is highest when you're in the $3,000-3,200 range."
```

Z NEVER fabricates a pattern. If the data isn't there, Z says so. This is non-negotiable.
Bad intelligence is worse than no intelligence.

**Privacy — how aggregation stays anonymous:**

```
RULE 1: Patterns are computed from aggregate queries. No individual company's data
        is stored in intelligence_patterns. The SQL groups and averages — the output
        has no company_id, no job_id, no customer info.

RULE 2: Minimum sample sizes prevent reverse-engineering. If there are only 3 HVAC
        companies in a zip code, an aggregate could be identifying. The 25+ minimum
        threshold mitigates this. For small regions, patterns roll up to state level.

RULE 3: Companies can opt out. A toggle in settings: "Contribute anonymized data to
        improve Z Intelligence for all users." Default ON, but can be turned OFF.
        Opted-out companies still RECEIVE patterns — they just don't contribute.
        (This prevents a free-rider problem but respects choice.)

RULE 4: No cross-tenant data leakage. All existing RLS policies remain. The pipelines
        run as service role with read-only access to compute aggregates. They never
        write to company-scoped tables.
```

---

### Layer 6: RBAC Intelligence Filter — What Is Z ALLOWED To Reveal? [NEW]

This is the layer that makes the same brain safe for every role. Z knows everything.
Z doesn't tell everyone everything.

**The principle:** Z helps everyone do THEIR job better. Z does not help anyone do
someone ELSE's job. A field tech needs code compliance and scope accuracy. They do not
need to know what the boss charges, what the margin is, or how long the boss thinks
the job should take.

**Default visibility matrix (ships with these defaults, owner can customize):**

```
Intelligence Type          | Owner | Admin | Office | Tech  | Homeowner
─────────────────────────┼───────┼───────┼────────┼───────┼──────────
Pricing intelligence       |  ✅   |  ✅   |   ❌   |  ❌   |   ❌
Time benchmarks            |  ✅   |  ✅   |   ❌   |  ❌   |   ❌
Margin / profitability     |  ✅   |  ❌   |   ❌   |  ❌   |   ❌
Bid win/loss rates         |  ✅   |  ✅   |   ✅   |  ❌   |   ❌
Material cost patterns     |  ✅   |  ✅   |   ❌   |  ❌   |   ❌
Equipment lifespan data    |  ✅   |  ✅   |   ✅   |  ✅   |   ✅
Failure/diagnostic intel   |  ✅   |  ✅   |   ✅   |  ✅   |   ✅
Code compliance guidance   |  ✅   |  ✅   |   ✅   |  ✅   |   ⚠️
Customer payment history   |  ✅   |  ✅   |   ✅   |  ❌   |   ❌
Employee performance data  |  ✅   |  ❌   |   ❌   |  ❌   |   ❌
Revenue / financial data   |  ✅   |  ⚠️   |   ❌   |  ❌   |   ❌
Regional comparables       |  ✅   |  ✅   |   ❌   |  ❌   |   ❌

✅ = Always visible    ❌ = Never visible (default)    ⚠️ = Context-dependent
```

**Owner-configurable overrides:**

```
Settings → Z Intelligence → Role Visibility

The owner sees this panel:
┌─────────────────────────────────────────────┐
│  What can Z share with your team?           │
│                                             │
│  Field Technicians:                         │
│  ☐ Pricing intelligence                     │
│  ☐ Time benchmarks                          │
│  ☐ Material cost patterns                   │
│  ☐ Customer payment history                 │
│                                             │
│  Office Staff:                              │
│  ☐ Pricing intelligence                     │
│  ☐ Time benchmarks                          │
│  ☐ Material cost patterns                   │
│  ☐ Revenue / financial data                 │
│                                             │
│  Admin:                                     │
│  ☐ Margin / profitability                   │
│  ☐ Employee performance data                │
│  ☐ Revenue / financial data                 │
│                                             │
│  Defaults are conservative. Enable only     │
│  what your team needs.                      │
└─────────────────────────────────────────────┘
```

**Schema:**

```sql
-- Stored in companies table as JSONB column
-- companies.ai_visibility_settings JSONB DEFAULT '{}'

-- Structure:
{
  "tech": {
    "pricing_intelligence": false,
    "time_benchmarks": false,
    "material_costs": false,
    "customer_payment_history": false
  },
  "office": {
    "pricing_intelligence": false,
    "time_benchmarks": false,
    "material_costs": false,
    "revenue_data": false
  },
  "admin": {
    "margin_data": false,
    "employee_performance": false,
    "revenue_data": true
  }
}
-- Empty object = use defaults (conservative)
-- Owner always sees everything (hardcoded, not configurable)
```

**How it works in the edge function:**

```
Step 1: Load user role from Layer 1 (employees.role)
Step 2: Load company's ai_visibility_settings
Step 3: Merge defaults with overrides → produce visibility mask
Step 4: When building prompt context from Layer 5 patterns:
        - Check each pattern_type against visibility mask
        - Include only patterns this role is allowed to see
        - Add explicit instruction to system prompt:
          "DO NOT reveal pricing data, time benchmarks, margin information,
          or competitive comparables to this user. If they ask directly,
          respond: 'That information is managed by your company admin.
          I can help you with [relevant alternatives].'"
```

**What Z says when a tech asks for restricted info:**

```
Tech: "What should I price this panel upgrade at?"
Z:    "I can help you scope the job accurately — you'll need a 200A rated
       panel, 2/0 copper or 4/0 aluminum, and make sure you account for
       the 6-conductor derating. Your office handles pricing. Want me
       to help you build a thorough scope so the bid is accurate?"
```

Z doesn't say "I'm not allowed to tell you that." Z redirects to what it CAN help
with — which is making the tech better at their actual job. The restriction is invisible.
The helpfulness is obvious.

---

## THE EDGE FUNCTION — UNIFIED AI BRAIN

### Single Entry Point (Revised)

One Edge Function handles all AI interactions across all platforms.
All six layers converge here.

```
Edge Function: ai-chat

INPUT (from any app):
{
  user_id,                  // From auth (JWT)
  message,                  // User's text/voice input
  conversation_id,          // For multi-turn context within a chat session
  attachments,              // Photos, documents (optional)
  session_context: {        // From Layer 4 (app-side)
    current_screen,
    screen_history,
    active_job_id,
    active_customer_id,
    active_bid_id,
    inferred_intent,
    last_ai_summary
  },
  platform                  // "mobile", "web_crm", "client_portal", "ops_portal"
}

PROCESS:
1.  Auth check — validate JWT, extract user_id
2.  LAYER 1 — Load identity context
    → Query users, companies, employees tables
    → Determine persona (field_tech, homeowner, owner, admin, office)
    → Load trade(s), state, certifications, active job details
3.  LAYER 3 — Load persistent memory
    → Query ai_user_memory for this user_id + persona
    → Inject memory_profile into context
4.  LAYER 4 — Incorporate session context
    → Deserialize session_context from request payload
    → Enrich with active job/customer/bid details from DB if IDs provided
5.  LAYER 2 — Knowledge retrieval
    → Embed the user's message
    → Query vector store scoped to user's trade(s)
    → Retrieve top-K relevant knowledge documents
6.  LAYER 5 — Compounding intelligence
    → Determine which pattern_types are relevant to this query
    → Query intelligence_patterns for (trade, region, job_category)
    → Filter by confidence threshold (sample_size >= min_sample_threshold)
7.  LAYER 6 — RBAC intelligence filter
    → Load company's ai_visibility_settings
    → Apply role-based mask to Layer 5 patterns
    → Remove any patterns this role is not allowed to see
    → Add restriction instructions to system prompt
8.  BUILD PROMPT
    → System prompt: persona rules + trade context + RBAC restrictions
    → Context block: identity + memory + session + knowledge + patterns
    → Conversation history (last N messages from conversation_id)
    → User message + attachments
9.  CONTEXT BUDGET CHECK (see below)
10. MODEL ROUTING (see below)
11. Call Claude API
12. Return response + metadata (sources, suggested actions, confidence)
13. ASYNC POST-PROCESSING:
    → Log interaction to ai_conversations table
    → If conversation ended or 5+ messages: trigger memory update (Layer 3)
    → Log any user corrections to feedback pipeline (see below)

OUTPUT:
{
  response,                 // AI text response
  sources,                  // Code sections, standards cited
  suggested_actions,        // ["create_bid", "schedule_inspection"]
  model_used,               // "haiku", "sonnet", "opus"
  confidence                // Overall confidence indicator
}
```

### Context Window Budget Strategy

The prompt can't be infinite. With identity + memory + session + knowledge + patterns +
conversation history + the actual message, complex queries for power users could blow
past limits. A budget strategy ensures the most important context always gets priority.

```
TOTAL CONTEXT BUDGET: ~80K tokens (leaving room for response)

Allocation (adjustable per query complexity):

| Slot | Default % | Tokens | Contents |
|------|:---------:|:------:|----------|
| System prompt + persona | 5% | ~4K | Role rules, trade context, RBAC restrictions |
| Persistent memory (L3) | 5% | ~4K | User's memory_profile |
| Session context (L4) | 3% | ~2.4K | Current screen, active entities, intent |
| Knowledge retrieval (L2) | 25% | ~20K | RAG documents (code sections, standards) |
| Compounding intel (L5) | 10% | ~8K | Relevant patterns for this query |
| Conversation history | 20% | ~16K | Recent messages in this thread |
| User message + attachments | 15% | ~12K | Photos, documents, long questions |
| Response headroom | 17% | ~13.6K | Space for Claude's response |

DYNAMIC ADJUSTMENT:
- Simple lookup ("what's the derating factor for X?"):
  → Knowledge retrieval gets 40%, compounding intel drops to 2%
- Business question ("how's my profitability this quarter?"):
  → Knowledge retrieval drops to 5%, compounding intel gets 25%
- Long conversation (20+ messages):
  → Conversation history gets 30%, older messages summarized
- First interaction (no memory yet):
  → Memory slot redistributed to knowledge + patterns

If total context exceeds budget:
1. Summarize older conversation history (keep last 5 messages verbatim)
2. Reduce knowledge documents (keep top-3 instead of top-5)
3. Reduce compounding patterns (keep only highest-confidence)
4. NEVER cut: system prompt, memory, session context, user message
```

### Model Routing — Confidence-Based, Not Just Cost-Based

The original spec said "Haiku for simple, Opus for complex." That's a start,
but the routing should also consider confidence and stakes.

```
ROUTING DECISION MATRIX:

Query Type                          | Model   | Why
────────────────────────────────────┼─────────┼──────────────────────
Unit conversion, simple lookup      | Haiku   | Fast, cheap, no risk
"What's 3/4 EMT fill capacity?"    |         |

General trade question              | Sonnet  | Balanced speed/quality
"Best practice for GFCI placement"  |         |

Code interpretation with nuance     | Opus    | Must be right
"NEC requirements for this setup"   |         |

Business strategy / analysis        | Opus    | Complex reasoning
"Why are my margins dropping?"      |         |

Memory gate check (async)           | Haiku   | Background task, fast
Session intent inference            |         |

Knowledge retrieval re-ranking      | Haiku   | Pre-processing step

Photo analysis / equipment ID       | Sonnet  | Vision capability
                                    | → Opus  | If Sonnet uncertain

Multi-step calculation with work    | Opus    | Must show correct steps
```

**Confidence-based escalation:**

```
IF model returns response with low confidence indicators:
  - Hedging language ("I think", "possibly", "I'm not certain")
  - Conflicting information in retrieved knowledge
  - Query touches safety-critical topic (life safety, code compliance)

THEN:
  1. If Haiku → re-route to Sonnet
  2. If Sonnet → re-route to Opus
  3. If Opus → return response with explicit uncertainty flag
     "I'm not fully confident on this one. Here's what I believe is correct
     and why, but I'd recommend verifying with [specific resource]."

Cost impact: ~5% of queries escalate. Mostly Haiku→Sonnet.
Opus escalations are rare (<1%) and worth every token.
```

---

### User Feedback / Correction Loop

When Z gets something wrong, the user should be able to fix it — and that fix
should improve Z for that user (and optionally for everyone).

**UI implementation:**

```
Every AI response has two subtle controls:

  [AI Response text here]
  
  [👍]  [👎]  [✏️ Correct this]

👍 — Logs positive signal. No interruption.
👎 — Opens quick feedback: "What was wrong?"
     Options: [Inaccurate] [Irrelevant] [Unclear] [Other]
     Logs negative signal + category.

✏️ — Opens correction interface:
     "What should the answer be?"
     User provides the correction + optional code/standard reference.
```

**How corrections flow:**

```
1. User submits correction on a code interpretation
2. Correction stored in ai_corrections table:
   - user_id, conversation_id, original_response, correction_text,
     code_reference, trade, topic, submitted_at, validated (boolean, default null)

3. Immediate effect: User's persistent memory (Layer 3) gets updated:
   "User corrected Z on [topic]. Their correction: [text]. Validated: pending."
   Next time this topic comes up FOR THIS USER, Z defers to their correction.

4. Validation pipeline (weekly):
   - Corrections reviewed by Tereda (or trusted trade advisors in future)
   - If validated: correction feeds into knowledge corpus (Layer 2)
   - If validated + common: pattern feeds into compounding intel (Layer 5)
   - If rejected: user notified with explanation

5. Aggregate impact:
   - 10+ validated corrections on same topic = knowledge corpus update
   - Corrections per trade/topic tracked to identify weak spots in Z's knowledge
   - High-correction topics flagged for knowledge corpus reinforcement
```

**Schema:**

```sql
CREATE TABLE ai_corrections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  company_id UUID REFERENCES companies(id),
  conversation_id UUID,
  original_response TEXT NOT NULL,
  correction_text TEXT NOT NULL,
  code_reference TEXT,             -- "NEC 210.12(A) Exception"
  trade TEXT NOT NULL,
  topic TEXT,
  severity TEXT DEFAULT 'minor',   -- 'minor', 'major', 'safety_critical'
  validated BOOLEAN,               -- null = pending, true = confirmed, false = rejected
  validated_by TEXT,                -- 'tereda', 'trade_advisor', 'community'
  validated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ai_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  conversation_id UUID,
  message_index INTEGER,           -- Which message in the conversation
  signal TEXT NOT NULL,             -- 'positive', 'negative'
  category TEXT,                    -- 'inaccurate', 'irrelevant', 'unclear', 'other'
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## PER-APP INTEGRATION

One brain, four surfaces. Every app calls the same `ai-chat` edge function.
The apps are thin clients that provide their navigation context and display the response.

### Integration Diagram

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Mobile App  │  │   Web CRM    │  │Client Portal │  │  Ops Portal  │
│  (Flutter)   │  │  (Next.js)   │  │  (Next.js)   │  │  (Next.js)   │
│              │  │              │  │              │  │              │
│ SessionCtx   │  │ SessionCtx   │  │ SessionCtx   │  │ SessionCtx   │
│ (Dart class) │  │ (React ctx)  │  │ (React ctx)  │  │ (React ctx)  │
│  ~80 lines   │  │  ~60 lines   │  │  ~60 lines   │  │  ~60 lines   │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │                 │
       └────────┬────────┴────────┬────────┴────────┬────────┘
                │                 │                 │
                ▼                 ▼                 ▼
         ┌─────────────────────────────────────────────┐
         │            ai-chat Edge Function             │
         │                                             │
         │  L1: Identity   → users/companies/employees │
         │  L2: Knowledge  → vector store (RAG)        │
         │  L3: Memory     → ai_user_memory            │
         │  L4: Session    → from request payload      │
         │  L5: Compounding → intelligence_patterns    │
         │  L6: RBAC       → ai_visibility_settings    │
         │                                             │
         │  Context budget → Model routing → Claude    │
         │                                             │
         │  Async: memory update, feedback logging     │
         └─────────────────────────────────────────────┘
```

### Mobile App (Contractor — Flutter)

```
UI Elements:
- Floating Z button on every screen (bottom-right, above nav bar)
- Dedicated Z Intelligence tab in bottom navigation
- Voice input button (push-to-talk, hands-free)
- Photo-to-AI pipeline (camera → attach to message)
- Quick action chips: "Calculate" "Look up code" "Draft bid" "Log issue"

Session buffer tracks:
- Which screen the user is on (job detail, bid creation, customer, etc.)
- Active job/customer/bid IDs from current navigation
- Last 5 screens visited
- Inferred intent from navigation pattern

What Z does here:
- Code lookups, calculations, scope assistance (for everyone)
- Material selection, equipment identification (for everyone)
- Safety guidance, best practices (for everyone)
- Pricing help, time estimates, bid comparables (Owner/Admin only — Layer 6)

Voice-first:
- Field professionals don't type with dirty gloves
- Push-to-talk or wake word activation
- Speech-to-text → AI processes → text + optional TTS response
- Noise-cancelling preprocessing for construction sites
- Photo + voice combo: snap photo, say "what's wrong with this"
```

### Web CRM (Contractor — Next.js)

```
UI Elements:
- Side panel AI (right side, expandable/collapsible)
- Full keyboard experience
- Can display charts, data tables, formatted reports
- Drag-and-drop file attachment for documents

Session buffer tracks:
- Current page/section in CRM
- Active filters on lists (overdue invoices, open bids, etc.)
- Dashboard state (which metrics visible)
- Active job/customer/bid from current view

What Z does here (in addition to everything mobile does):
- Business analysis: revenue trends, profitability, close rates
- Bulk operations: "email all customers with overdue invoices"
- Report generation: "show me this month vs last month"
- Strategic guidance: "where am I losing money?"
- Full access to compounding intelligence (for Owner/Admin)
- Deeper conversation depth (desktop = more patience for long answers)
```

### Client Portal / Home Portal (Homeowner — Next.js)

```
UI Elements:
- Chat widget (bottom-right, expandable)
- Guided flow buttons: "Something's wrong" "Schedule service" "Ask about equipment"
- Equipment-aware: tap any equipment in property profile → "Ask Z about this"

Session buffer tracks:
- Which property/equipment the homeowner is viewing
- Active service request if any
- Recent messages with their contractor

What Z does here:
- Equipment questions in plain English ("what does this error code mean?")
- Maintenance guidance ("when should I replace my filter?")
- Issue triage: "my furnace is making a noise" → guided diagnosis
- Routes to preferred contractor for anything that needs professional work
- Equipment lifespan insights from compounding intelligence
  ("your water heater brand typically lasts 10-14 years, yours is at 8")

What Z NEVER does here:
- Provides specific pricing
- Undermines contractor relationship
- Recommends DIY for safety-risk work
- Suggests switching contractors
- Shares any contractor business data
```

### Ops Portal (Robert — Next.js)

```
UI Elements:
- Full co-founder AI (already spec'd in Ops Portal Section 19)
- Cross-tenant data access (platform-level intelligence)
- Strategic analysis, business planning, technical decisions

Session buffer tracks:
- Which dashboards Robert was viewing
- Which metrics, which tenants, which filters active
- Current strategic context

What Z does here:
- Platform-level analytics: "plumber signups in TX spiked 40% this week"
- Cross-tenant compounding intelligence (aggregate view)
- Strategic planning: marketing, pricing, feature prioritization
- Technical decisions: architecture, scaling, vendor choices
- Support escalation: understand user issues across the platform
- Financial modeling: unit economics, projections, scenario planning
```

---

## ~~ADAPTIVE EXAM / TRAINING SYSTEM~~ — SCRAPPED

**STATUS: REMOVED FROM SCOPE**

The exam/training system has been cut from the ZAFTO product direction entirely.
This includes AI-generated exams, adaptive learning, spaced repetition, and all
related schemas (training_progress, training_attempts). These tables should NOT
be created. Any references to exam functionality elsewhere in documentation should
be treated as deprecated.

---

## KNOWLEDGE CORPUS MANAGEMENT

### How Knowledge Gets Into the System

**Option A: ZAFTO-Authored Factual Reference Data (Primary)**
Robert + Z co-author structured factual reference content per trade — ampacity tables,
sizing rules, clearance requirements, derating factors, etc. Written in ZAFTO's own
voice using engineering facts (not copyrighted code text). This is ZAFTO's IP.

**Option B: Government / Public Domain Content (Bulk Ingest)**
OSHA regulations, EPA standards, state licensing requirements, government incentive
programs, state code amendments — all public domain. Upload full text into Supabase
Storage. Edge Function processes: chunks text, generates embeddings, stores in vector table.

**Option C: Manufacturer Specifications (Freely Published)**
Installation manuals, spec sheets, error codes, wiring diagrams from major manufacturers.
All publicly distributed. Organized by trade, brand, equipment type.

**Option D: Deep-Link Index (Code Citations)**
Build and maintain the code_references table mapping code sections to deep-link URLs
for NFPA, ICC, and IAPMO free online viewers. No copyrighted text stored.

**Option E: Community Contribution (Future)**
Verified trade professionals submit corrections, tips, local knowledge.
Moderated before inclusion. Feeds into Layer 5 correction pipeline.

**Option F: Licensed Code Text (Future — When Revenue Supports)**
Pursue NFPA/ICC commercial digital licensing to embed actual code text in RAG pipeline.
Architecture supports hot-swap — just replace factual summaries with licensed text
in the same corpus folders. No structural changes needed.

### Knowledge Freshness

| Content Type | Update Frequency | How |
|-------------|-----------------|-----|
| ZAFTO factual reference data | As codes update (every 3 years) | Manual review + update of ZAFTO-authored content |
| Deep-link URLs to code viewers | As publishers update sites | Automated link-check + manual fix |
| State amendments | Varies (annual check) | Per-state tracking, manual update (public docs) |
| Manufacturer specs | As released | Automated alerts + manual review |
| OSHA / EPA / govt regs | As published | Direct from government sources (public domain) |
| Equipment databases | Ongoing | Compounding from photo scans (L5) |
| Pricing intelligence | Real-time | Compounding from bid/job data (L5) |
| Government incentive programs | Quarterly review | Federal/state program tracking |

---

## WHAT THIS REPLACES

| Before | After |
|--------|-------|
| 1,186 standalone calculator screens | AI calculates anything, any trade, shows work, cites code with deep links to official sources |
| 5,080 static exam questions | SCRAPPED — Exam system removed from product scope |
| 111 static diagram viewers | AI references visuals contextually in conversation |
| 21 static reference guides | AI answers reference questions interactively |
| Per-trade content buildout (months) | Per-trade knowledge corpus upload (days) |
| Manual maintenance per code cycle | AI training data + deep-link citations to current code viewers |
| Text-only interaction | Voice + photo + text, context-aware |
| Every conversation starts cold | Persistent memory = Z knows you (Layer 3) |
| AI forgets when you change screens | Session buffer = Z follows your workflow (Layer 4) |
| Each user's AI is equally dumb | Compounding intelligence = Z gets smarter for everyone (Layer 5) |
| Same info shown to every role | RBAC filter = Z reveals what's appropriate (Layer 6) |
| ZAFTO-connected tools gone | KEPT — Field tools + ecosystem-integrated tools remain as workflow UI |

---

## IMPACT ON EXISTING SCREENS + CONTENT

### Mobile App Changes
- **Remove:** All standalone single-purpose calculator screens (1,186), reference guides
- **Keep:** Field tools (14), ZAFTO-connected/ecosystem tools, job/bid/invoice/customer pipeline, time clock, dashboard, settings
- **Replace with:** Single AI chat + floating Z button + dedicated Z tab
- **Add:** Voice input, photo-to-AI, SessionContext class (~80 lines Dart)

### Web CRM Changes
- **Remove:** N/A (CRM doesn't have calculators/exams)
- **Keep:** All 40 pages (business workflow, not content)
- **Enhance:** Z Intelligence side panel as primary AI interface
- **Add:** SessionContext React provider (~60 lines)

### Client Portal Changes
- **Remove:** N/A
- **Keep:** All 21 pages
- **Add:** AI chat widget, SessionContext provider (~60 lines)

### Ops Portal Changes
- **Keep:** All existing, including Section 19 AI
- **Enhance:** Full Layer 5 compounding intelligence at platform level
- **Add:** SessionContext provider (~60 lines)

---

## TRADE EXPANSION PROCESS

Adding a new trade after this architecture is in place:

| Step | Time | What |
|------|------|------|
| 1. Identify trade | — | Market research, demand analysis |
| 2. Author factual reference corpus | 2-3 days | ZAFTO-authored factual data (sizing, specs, requirements) — NO copyrighted code text |
| 3. Ingest public domain content | 1 day | OSHA regs, state amendments, govt programs, manufacturer specs |
| 4. Build deep-link index | 1 day | Map code sections → free viewer URLs for that trade's code body |
| 5. Configure trade profile | 1 day | Trade name, roles, license types per state, terminology |
| 6. Test AI responses | 2-3 days | Verify accuracy: common questions, edge cases, calcs, citation links |
| 7. Add trade to sign-up flow | 1 day | UI: add trade option, update RBAC if needed |
| 8. Launch | — | New trade live. Layer 5 starts compounding from day 1. |

**Total: ~1 week per new trade** (vs months for static content approach)

---

## OPEN QUESTIONS (For Review Session)

1. **Diagrams:** Keep 111 electrical diagrams as AI-referenced visuals, or let AI describe
   everything verbally? Wiring configurations are genuinely better as pictures.

2. **Offline AI:** Options when no signal:
   - Cached common Q&A pairs per trade (pre-downloaded)
   - PowerSync syncs recent AI responses for reference
   - Offline mode clearly indicates "Z needs connectivity"
   - Layer 3 memory could cache on-device for basic continuity

3. **AI Cost at Scale:** 10,000 users × 5 queries/day = 50,000 API calls/day.
   Model routing (Layer routing) keeps costs manageable — estimate ~$0.15-0.40
   per user per month with Haiku-heavy routing. Need formal cost model.

4. **Voice Quality:** Construction site noise. Evaluate STT accuracy in field conditions.
   May need noise-cancelling preprocessing before sending to Whisper/Deepgram.

5. **Liability:** Wrong code interpretation = whose liability? Legal review needed.
   Disclaimer: "AI assistance, not professional engineering advice." Every response.

6. ~~**Exam Accuracy:**~~ SCRAPPED — Exam system removed from scope.

7. **Knowledge Corpus Licensing:** RESOLVED for Phase 1 — Option B approach. ZAFTO
   builds factual knowledge corpus (not copyrighted text) + deep-links to NFPA/ICC
   free online viewers for official code language. No licensing needed at launch.
   FUTURE: Pursue NFPA/ICC commercial digital licensing when revenue supports it
   to embed actual code text in RAG pipeline. Architecture supports hot-swap.

8. **Layer 5 Cold Start:** Platform launches with zero compounding data. How long until
   patterns are useful? Estimate: 3-6 months at 500+ active users to hit meaningful
   sample sizes for common job types. Seed with industry averages where available.

9. **Cross-Persona Bridge (Parked):** Homeowner ↔ contractor intelligence sharing is
   high-value but legally/ethically complex. Requires explicit consent architecture,
   privacy review, and careful UX design. Not in Phase 1. Revisit when platform is
   established and legal counsel is available.

---

## BUILD PHASES (Revised)

| Phase | What | Layers | Effort |
|-------|------|--------|--------|
| **Phase 1** | Core AI chat with Layer 1 context injection (identity-aware) | L1 | During wiring |
| **Phase 2** | Session context buffer across all apps | L1+L4 | During wiring |
| **Phase 3** | RBAC intelligence filter + owner settings panel | L1+L4+L6 | During wiring |
| **Phase 4** | Knowledge retrieval (RAG) — factual corpus + deep-link citations for electrical | L1+L2+L4+L6 | Post-wiring |
| **Phase 5** | Voice input for field use | — | Post-wiring |
| **Phase 6** | Persistent memory system (observation extraction + deterministic merge) | L1-L4+L6+L3 | Month 1 |
| **Phase 7** | Remove standalone calculators, replace with AI interface | — | Month 1 |
| **Phase 8** | Compounding intelligence pipelines (Layer 5) | L5 | Month 2-3 |
| **Phase 9** | Feedback/correction loop | L3+L5 | Month 2-3 |
| **Phase 10** | Knowledge corpus for trades 2-8 (factual + deep links per trade) | L2 | Month 2-4 |
| **Phase 11** | Confidence-based model escalation + cost-tiered context budgets | — | Month 3-4 |
| **Phase 12** | Full six-layer integration tuning + cost optimization | All | Month 4-5 |

**NOTE: Exam/training system is SCRAPPED. No phases allocated.**

**Critical path:** Phases 1-3 are the foundation and can be wired in focused sessions.
RBAC (Layer 6) ships early because the wrong information leaking to the wrong role on
day one is worse than having no intelligence at all. Layer 5 (compounding) ships later
because it needs real user data to be meaningful — build the tables early so data
accumulates from day one, but don't expect it to be a selling point until you have
500+ active users feeding patterns.

**Context budget note:** Context window budget must be tiered by model. Don't send 80K
context to Opus for a question Sonnet handles at 20K. Haiku gets minimal context (~10K),
Sonnet gets moderate (~30K), Opus gets full budget (~80K) only for complex business
analysis. This keeps costs manageable at scale.

---

## RULES (Updated)

1. **One AI, dynamic context.** Never build trade-specific AI instances. One system, six layers.
2. **Claude already knows the trades.** RAG supplements, it doesn't replace. Deep-link citations verify.
3. **Show your work.** Every calculation, code ref, recommendation must be explainable + linked to source.
4. **Safety-first.** AI errs toward "call a professional" for life safety topics.
5. **Contractor trust architecture applies to AI.** Homeowner AI NEVER undermines contractor.
6. **Voice is not optional.** Field professionals need hands-free. Launch requirement.
7. **Smart model routing.** Haiku for simple, Sonnet for medium, Opus for complex.
   Escalate on low confidence. Never waste tokens, never sacrifice accuracy.
8. **Offline graceful degradation.** App works for data capture without signal. AI clearly
   indicates it needs connectivity. PowerSync handles data, not intelligence.
9. **No static calculators for new trades.** If adding a trade requires standalone calculator screens, wrong.
10. **The AI gets smarter, the product gets stickier.** Every interaction compounds. This is the moat.
11. **Z helps everyone do THEIR job. Not someone else's.** RBAC filter is non-negotiable. [NEW]
12. **Memory is a relationship, not a database dump.** Layer 3 synthesizes understanding,
    not raw data. Keep profiles tight, high-signal, and human-readable. [NEW]
13. **Silence is better than bad intelligence.** If Layer 5 doesn't have enough data,
    Z says "I don't have enough data" — never fabricates patterns. [NEW]
14. **Corrections make Z stronger.** Every user correction is a gift. Process it, validate it,
    feed it back into the system. Never ignore it, never argue with it. [NEW]
15. **Context budget is sacred.** Never blow the context window. Budget, prioritize, summarize.
    The user's message and Z's memory are never cut. Everything else is negotiable. [NEW]
16. **No copyrighted code text.** ZAFTO never hosts, embeds, or distributes copyrighted model
    code text (NEC, IPC, IMC, etc.) in any form. Factual knowledge + deep links to official
    free viewers. Upgrade to licensed text when revenue supports it. [NEW]
17. **Deep links are citations.** Every code reference Z makes includes a tappable link to
    the official source. Z thinks, the official code verifies. [NEW]
18. **Memory updates are deterministic.** LLMs extract observations, deterministic functions
    merge them into profiles. Never let an LLM rewrite a full JSONB profile. [NEW]
19. **ZAFTO-connected tools stay.** Only standalone single-purpose calculators are removed.
    Any tool that integrates with the ZAFTO ecosystem (jobs, bids, scanning, equipment
    logs, field capture) remains as workflow UI. [NEW]
20. **No exam system.** Scrapped from scope. Do not build, do not reference as a feature. [NEW]

---

**This document has been reviewed and revised (Session 33). Key decisions locked:
- Exam system: SCRAPPED
- Code strategy: Option B (factual knowledge + deep links, no copyrighted text)
- Standalone calculators: REMOVED (1,186)
- ZAFTO-connected tools: KEPT
- Memory updates: Observation extraction + deterministic merge (not full LLM rewrite)
- Context budgets: Tiered by model (Haiku ~10K, Sonnet ~30K, Opus ~80K)
Full architecture review for implementation readiness scheduled for next dedicated session.
Do not begin implementation until this doc is LOCKED.**
