# ZAFTO GROWTH ADVISOR
## AI-Powered Revenue Expansion Engine for Contractors
### February 5, 2026 — EXPANSION SPECIFICATION

---

## ONE SENTENCE

ZAFTO analyzes each contractor's trade, location, current job mix, and revenue
profile, then surfaces personalized opportunities to expand into insurance work,
warranty networks, certification programs, preferred vendor lists, and
government-funded programs — turning ZAFTO from a tool they use into a
platform that actively grows their business.

---

## WHY THIS MATTERS

```
Most contractors leave money on the table because they don't know
what's available to them. Not because they can't do the work —
because nobody told them the opportunity existed.

A plumber doesn't know American Home Shield is desperate for
contractors in their zip code.

A roofer doesn't know that a HAAG certification doubles their
credibility with insurance adjusters.

An HVAC tech doesn't know their state's weatherization program
pays $3,500 per home for energy upgrades.

An electrician doesn't know that getting on State Farm's preferred
vendor list means steady referral volume.

ZAFTO knows their trade, their state, their licenses, their
current revenue mix, and their capacity. ZAFTO connects the dots.

The contractor grows. ZAFTO gets stickier. Everybody wins.
```

---

## RELATIONSHIP TO EXISTING SPECS

```
This document USES:
  37_JOB_TYPE_SYSTEM.md       → Recommends enabling insurance/warranty modules
  36_RESTORATION_MODULE.md    → Recommends Xactimate TPI, carrier programs
  38_INSURANCE_VERTICALS.md   → Recommends warranty networks, storm work
  35_UNIVERSAL_AI_ARCH.md     → Z Intelligence powers contextual recommendations
  27_BUSINESS_OS_EXPANSION.md → Revenue data from Zafto Books feeds analysis

This document DOES NOT modify any locked schemas.
No new tables required. Runs entirely on existing company profile,
job history, and a curated content knowledge base.
```

---

## HOW IT WORKS

### The Three Layers

```
LAYER 1: CONTRACTOR PROFILE (Automatic)
  Built from data already in ZAFTO:
  - Trade(s) registered
  - State / service area
  - Licenses on file
  - Insurance/warranty modules enabled or not
  - Job history (count, types, avg value, revenue)
  - Certifications listed in profile
  - Team size
  - Time on platform

LAYER 2: OPPORTUNITY KNOWLEDGE BASE (Curated)
  A structured database of opportunities per trade per state:
  - Warranty company contractor enrollment programs
  - Insurance carrier preferred vendor programs
  - Industry certifications and what they unlock
  - State and federal contractor programs
  - Trade-specific revenue streams
  - Seasonal opportunities (storm season, weatherization, etc.)

LAYER 3: Z INTELLIGENCE (AI Matching)
  Matches Layer 1 against Layer 2 to surface relevant,
  timely, personalized recommendations. Filters out noise.
  Ranks by estimated revenue impact and ease of entry.
```


### Contractor Profile Data Model (No New Tables)

```
All profile data lives in existing structures:

  companies.trades[]                → Which trades they operate
  companies.state / service_area    → Where they work
  companies.insurance_module_enabled → Already doing insurance work?
  companies.warranty_module_enabled  → Already doing warranty work?
  companies.metadata                → {
                                        "licenses": ["CT-E1-29485", "CT-P2-11203"],
                                        "certifications": ["IICRC-WRT", "EPA-608"],
                                        "team_size": 6,
                                        "years_in_business": 8
                                      }

  Derived from jobs table:
    - Total jobs last 90 days
    - Revenue by job_type (standard / insurance / warranty)
    - Revenue by trade
    - Avg job value by type
    - Capacity utilization (jobs per week trend)
    - Growth trajectory (this quarter vs last)
```

### Opportunity Knowledge Base Schema

```sql
-- ============================================================
-- GROWTH ADVISOR — OPPORTUNITY KNOWLEDGE BASE
-- Curated content, not user-generated. Managed by Tereda team.
-- Lives in Supabase but is READ-ONLY for contractors.
-- ============================================================

CREATE TABLE growth_opportunities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Targeting
  trades TEXT[] NOT NULL,                    -- Which trades this applies to
  states TEXT[],                             -- Which states (NULL = nationwide)
  min_team_size INTEGER DEFAULT 1,           -- Minimum team to qualify
  max_team_size INTEGER,                     -- NULL = no cap
  requires_insurance_module BOOLEAN DEFAULT FALSE,
  requires_warranty_module BOOLEAN DEFAULT FALSE,
  prerequisite_certifications TEXT[],         -- Must have these first

  -- Content
  title TEXT NOT NULL,                       -- "Join American Home Shield's Contractor Network"
  category TEXT NOT NULL,                    -- warranty_network, carrier_program, certification,
                                             -- government_program, seasonal, revenue_stream
  summary TEXT NOT NULL,                     -- 2-3 sentence elevator pitch
  revenue_potential TEXT,                    -- "$2,000-4,000/month additional revenue"
  difficulty TEXT NOT NULL,                  -- easy, moderate, advanced
  time_to_revenue TEXT,                      -- "2-4 weeks after approval"

  -- Action
  action_type TEXT NOT NULL,                 -- apply_external, enable_module, get_certified,
                                             -- contact_program, seasonal_prep
  action_url TEXT,                           -- External link (application, enrollment, etc.)
  action_steps JSONB,                        -- Step-by-step guide
  -- Structure: [
  --   { "step": 1, "title": "Check license requirements",
  --     "detail": "Connecticut requires...", "link": "https://..." },
  --   { "step": 2, "title": "Submit application",
  --     "detail": "Apply through their contractor portal...", "link": "..." },
  -- ]

  -- Context
  why_it_matters TEXT,                       -- "HVAC is the #1 warranty dispatch category..."
  common_objections JSONB,                   -- Contractor concerns + responses
  -- Structure: [
  --   { "objection": "Warranty work pays too little",
  --     "response": "Average AHS HVAC dispatch nets $385. At 10/month that's..." },
  -- ]

  success_metrics TEXT,                      -- "Top warranty HVAC contractors do 40+ dispatches/month"

  -- Seasonality
  is_seasonal BOOLEAN DEFAULT FALSE,
  season_start_month INTEGER,                -- 1-12
  season_end_month INTEGER,
  season_prep_weeks INTEGER,                 -- How far ahead to surface this

  -- Management
  is_active BOOLEAN DEFAULT TRUE,
  priority INTEGER DEFAULT 50,               -- 1-100, higher = surface more prominently
  last_verified DATE,                        -- When Tereda last confirmed info is current
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- No RLS needed — this is public read-only content.
-- All contractors see the same opportunity database.
-- Personalization happens in the matching logic, not in row filtering.
```

### Opportunity Dismissals (Per Contractor)

```sql
-- Track which opportunities a contractor has seen, dismissed, or acted on

CREATE TABLE growth_opportunity_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  opportunity_id UUID NOT NULL REFERENCES growth_opportunities(id),

  status TEXT NOT NULL DEFAULT 'surfaced',
  -- surfaced:    Shown to contractor
  -- viewed:      Contractor tapped to read details
  -- dismissed:   "Not interested" / "Not now"
  -- in_progress: Contractor started the steps
  -- completed:   Contractor finished (enrolled, certified, etc.)

  dismissed_reason TEXT,                     -- "not_now", "not_relevant", "already_doing"
  dismiss_until TIMESTAMPTZ,                 -- Re-surface after this date (for "not now")
  notes TEXT,                                -- Contractor's own notes

  surfaced_at TIMESTAMPTZ DEFAULT NOW(),
  viewed_at TIMESTAMPTZ,
  dismissed_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  UNIQUE(company_id, opportunity_id)
);

ALTER TABLE growth_opportunity_interactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "growth_interactions_isolation" ON growth_opportunity_interactions
  USING (company_id = current_setting('app.company_id')::UUID);
```


---

## THE OPPORTUNITIES BY TRADE

### Electrical

```
WARRANTY NETWORKS
  ● American Home Shield — panels, wiring, outlets, ceiling fans
  ● Frontdoor — electrical systems, smart home devices
  ● Choice Home Warranty — electrical components
  Revenue potential: $1,500-3,000/month at 8-15 dispatches

CARRIER PREFERRED VENDOR
  ● State Farm SELECT Service — fire/storm electrical damage restoration
  ● Allstate Good Hands Repair Network
  ● USAA preferred contractor list
  Revenue potential: $3,000-8,000/month (higher per-job value)

CERTIFICATIONS THAT UNLOCK WORK
  ● IICRC FSRT (Fire & Smoke Restoration Technician)
    Unlocks: Insurance fire damage electrical work
    Cost: ~$500 | Time: 3-day course
  ● OSHA 30 Construction
    Unlocks: Commercial and government job sites
    Cost: ~$200 | Time: 30 hours online

GOVERNMENT PROGRAMS
  ● State Weatherization Assistance Program (WAP)
    Federal DOE funding distributed through state agencies
    Electrical upgrades for low-income homes
    Revenue: $800-2,500 per home, steady volume
  ● IRA Home Electrification Rebate Program
    Up to $14,000 per household for electrical upgrades
    Panel upgrades, wiring for heat pumps, EV charger circuits
    Revenue: $2,000-6,000 per home
  ● State energy efficiency programs (varies by state)
    Utility-sponsored rebate programs need licensed electricians

SEASONAL
  ● Storm season prep (March-September depending on region)
    Get on insurance carrier lists BEFORE storm season
    Emergency board-up and generator hookup work
```

### Plumbing

```
WARRANTY NETWORKS (Highest Volume After HVAC)
  ● American Home Shield — water heaters, pipes, fixtures, sewer
  ● Frontdoor — full plumbing systems
  ● Fidelity National — plumbing, water heaters, sewer/septic
  ● Choice — pipes, fixtures, water heaters
  Revenue potential: $2,000-4,000/month at 10-20 dispatches

CARRIER PREFERRED VENDOR
  ● Water damage is the #1 homeowner insurance claim
  ● Every carrier needs plumbers for emergency mitigation
  ● State Farm, Allstate, Farmers, Liberty Mutual all have networks
  Revenue potential: $4,000-12,000/month (emergency rates)

CERTIFICATIONS
  ● IICRC WRT (Water Restoration Technician)
    Unlocks: Insurance water damage mitigation work
    Cost: ~$400 | Time: 3-day course
    THIS IS THE SINGLE HIGHEST-ROI CERT FOR A PLUMBER
  ● Backflow Prevention Certification
    Required by many municipalities, steady annual testing revenue
    Revenue: $75-150 per test, 100+ tests/year possible

GOVERNMENT PROGRAMS
  ● Lead Service Line Replacement (EPA mandate)
    $15B federal funding for lead pipe replacement
    Every municipality needs licensed plumbers
    Revenue: Massive — multi-year contracts available
  ● State WAP — plumbing repairs for low-income homes
  ● Municipal sewer lateral programs

REVENUE STREAMS
  ● Sewer camera inspection service
    $150-500 per inspection, sells repair work
    Equipment ROI in 2-3 months
  ● Water heater maintenance plans
    Recurring revenue from annual flushes + anode rod replacement
```

### HVAC

```
WARRANTY NETWORKS (Single Biggest Category)
  ● American Home Shield — AC, furnace, heat pump, ductwork
  ● Frontdoor — HVAC systems (their #1 dispatch category)
  ● Every warranty company prioritizes HVAC contractors
  Revenue potential: $3,000-6,000/month at 15-30 dispatches
  A busy warranty HVAC tech does 40+ dispatches/month

CARRIER PREFERRED VENDOR
  ● Fire damage HVAC cleaning and replacement
  ● Storm damage system replacement
  ● Smoke damage ductwork cleaning
  Revenue potential: $2,000-5,000/month

CERTIFICATIONS
  ● EPA 608 Universal (required for refrigerant handling)
    Already have it? Good. Don't? Can't do warranty HVAC work.
  ● NATE Certification
    Unlocks: Higher-tier warranty work, carrier preferred lists
    Cost: ~$300 | Time: Self-study + exam
  ● IICRC FSRT (Fire & Smoke)
    Unlocks: Insurance HVAC cleaning after fire/smoke events

GOVERNMENT PROGRAMS
  ● IRA Home Energy Rebate Program
    Up to $8,000 per household for heat pump installation
    States distributing funds 2024-2032
    Revenue: $4,000-12,000 per install (heat pump + ductwork)
  ● State Weatherization Assistance Program
    Furnace replacement, duct sealing for low-income homes
    Revenue: $2,000-5,000 per home
  ● Utility rebate program partnerships
    Become an approved installer for utility company rebates
    Steady lead flow from utility's customer base

SEASONAL
  ● Pre-summer AC rush — warranty companies desperate for HVAC
    Join networks in March, dispatches flood in June
  ● Pre-winter furnace season — same pattern
```

### Roofing

```
INSURANCE WORK (Massive Opportunity)
  ● Storm/hail damage is the bread and butter
  ● Average insurance roof replacement: $8,000-15,000
  ● Average retail roof replacement: $6,000-12,000
  ● Insurance work pays MORE because supplements

CERTIFICATIONS
  ● HAAG Certified Inspector (Residential or Commercial)
    THE credential for insurance roofing
    Adjusters take you seriously, carriers trust your inspections
    Cost: ~$1,000 | Time: 2-day course
    Revenue impact: Dramatically higher supplement approval rates
  ● GAF Master Elite / Owens Corning Platinum Preferred
    Manufacturer certifications unlock extended warranty offerings
    Homeowners prefer certified installers
    Revenue impact: Higher close rate, premium pricing

CARRIER PROGRAMS
  ● State Farm SELECT Service — storm damage roofing
  ● Allstate repair network
  ● USAA preferred roofer list
  ● Farmers contractor program

SEASONAL
  ● Hail season (March-August, Central US)
  ● Hurricane season (June-November, Gulf/East Coast)
  ● PREP: Get carrier relationships + supplementing skills
    BEFORE storm season, not during
```

### Restoration

```
Already deep in insurance — Growth Advisor focuses on EXPANSION:

CERTIFICATIONS (IICRC Stack)
  ● WRT — Water Restoration Technician (baseline)
  ● ASD — Applied Structural Drying (advanced drying)
  ● AMRT — Applied Microbial Remediation Technician (mold)
  ● FSRT — Fire & Smoke Restoration Technician
  ● OCT — Odor Control Technician
  ● CCT — Carpet Cleaning Technician
  Each cert unlocks new service lines and higher billing rates

CARRIER EXPANSION
  ● Get on more carrier preferred vendor lists
  ● Each carrier relationship = new referral stream
  ● TPAs (Third Party Administrators) to target:
    Alacrity, Contractor Connection, Sedgwick

REVENUE STREAMS
  ● Content cleaning (pack-out + clean + return)
    High-margin add-on to water/fire jobs
  ● Mold testing and remediation
    Requires AMRT cert, $5K-50K per job
  ● Biohazard/trauma cleanup
    Requires IICRC S540, OSHA BBP training
    Low volume but $3,000-15,000 per job
  ● Commercial restoration
    Bigger losses, bigger checks, longer timelines
```

### GC / Remodeler

```
INSURANCE RECONSTRUCTION
  ● After mitigation, someone rebuilds — that's you
  ● Same insurance claim, separate scope and estimate
  ● Supplement opportunities on hidden damage found during demo
  ● Upgrade upselling (homeowner pays difference for better finishes)

CERTIFICATIONS
  ● IICRC WRT — understand water damage even if you don't mitigate
  ● Lead RRP (Renovation, Repair, Painting) — EPA required for pre-1978 homes
    REQUIRED for insurance reconstruction on older homes
    Cost: ~$300 | Time: 1-day course
  ● OSHA 30 — unlocks commercial reconstruction

REVENUE STREAMS
  ● Emergency board-up and tarping services
    First on scene after storm/fire = first in line for reconstruction
    Low skill, high urgency, premium pricing
  ● Insurance reconstruction preferred vendor lists
    Restoration companies need GC partners — be their go-to
```

### Solar

```
INSURANCE WORK
  ● Storm/hail damage to existing solar installations
  ● Panel replacement under homeowner insurance
  ● Growing category as solar adoption increases

GOVERNMENT PROGRAMS (Huge for Solar)
  ● Federal ITC (Investment Tax Credit) — 30% through 2032
  ● State solar rebate programs (varies widely)
  ● Low-income solar programs (community solar, LIHEAP crossover)
  ● Net metering advocacy (know your state's policy)

CERTIFICATIONS
  ● NABCEP (North American Board of Certified Energy Practitioners)
    THE gold standard for solar installers
    Unlocks: Premium projects, commercial work, utility-scale
    Revenue impact: 20-40% higher project values
```

### Landscaping

```
INSURANCE WORK
  ● Storm damage tree removal and cleanup
  ● Emergency services after hurricane/tornado/ice storm
  ● Erosion and drainage repair from flooding

GOVERNMENT PROGRAMS
  ● Municipal contracts for public space maintenance
  ● State DOT roadside maintenance programs
  ● Stormwater management / rain garden programs
  ● FEMA debris removal after declared disasters

SEASONAL
  ● Pre-storm season: Get on carrier emergency service lists
  ● Post-disaster: FEMA debris removal contracts (registration required)
    Register at SAM.gov BEFORE disaster season
```


---

## UI DESIGN

### Where Growth Advisor Lives

```
NOT a separate app section. NOT a buried settings page.

Growth Advisor surfaces in THREE places:

1. DASHBOARD WIDGET — "Growth Opportunities"
   A card on the main dashboard showing top 1-2 recommendations.
   Contextual, rotates based on seasonality and profile.
   Tap to expand. Dismiss to hide for 30 days.

2. DEDICATED TAB — "Grow" (in main navigation)
   Full opportunity browser organized by category.
   Filter by: trade, category, difficulty, revenue potential.
   Track progress on opportunities you've started.
   See what you've dismissed and revisit.

3. Z AI PROACTIVE SUGGESTIONS
   During normal AI conversations:
   "I noticed you're doing 15 warranty dispatches/month for AHS
   but you're not on Frontdoor's network yet. That could add
   another 8-10 dispatches. Want me to show you how to apply?"

   After completing a job:
   "That was your 10th insurance claim this quarter. Have you
   considered getting HAAG certified? It would strengthen your
   supplement approval rate significantly."
```

### Dashboard Widget

```
┌─────────────────────────────────────────────────────────────┐
│  💡 GROWTH OPPORTUNITIES                           [See All] │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Join Frontdoor's HVAC Contractor Network            │    │
│  │  Est. +$3,200/month · Easy · 2-3 weeks to start      │    │
│  │                                                       │    │
│  │  You're already doing warranty work with AHS.         │    │
│  │  Frontdoor is the #2 warranty company and they're     │    │
│  │  actively recruiting HVAC contractors in your area.   │    │
│  │                                                       │    │
│  │  [Show Me How]              [Not Now]  [Not Relevant] │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  🎓 Get IICRC WRT Certified                          │    │
│  │  Unlocks insurance water damage work · $400 · 3 days  │    │
│  │                                                       │    │
│  │  [Learn More]               [Not Now]  [Not Relevant] │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Full Opportunity Detail View

```
┌─────────────────────────────────────────────────────────────┐
│  ← Back                                                      │
│                                                              │
│  JOIN AMERICAN HOME SHIELD'S CONTRACTOR NETWORK              │
│  Warranty Network · Easy · Est. +$2,200/month                │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  WHY THIS MATTERS FOR YOU                                    │
│  You're a licensed plumber in Connecticut doing 100% retail   │
│  work. AHS is actively recruiting plumbing contractors in     │
│  your zip codes. Warranty plumbers average 10-15 dispatches   │
│  per month at $180-280 per job. That's $2,200/month in new   │
│  revenue with zero marketing spend — they send you the work.  │
│                                                              │
│  WHAT YOU NEED                                               │
│  ✓ Active plumbing license (you have CT-P2-11203)            │
│  ✓ General liability insurance ($1M+ recommended)            │
│  ✓ Workers comp (if you have employees)                      │
│  ✓ Smartphone with photo capability (ZAFTO handles this)     │
│  ○ Background check (part of application)                    │
│  ○ Drug test (some markets)                                  │
│                                                              │
│  HOW TO GET STARTED                                          │
│                                                              │
│  Step 1: Apply Online                                        │
│  Visit contractor.ahs.com and submit your application.       │
│  Have your license number and insurance COI ready.            │
│  [Open AHS Contractor Portal →]                              │
│                                                              │
│  Step 2: Complete Onboarding                                 │
│  AHS reviews application (typically 1-2 weeks).              │
│  Complete their online orientation training.                  │
│  Set your service area and available trades.                  │
│                                                              │
│  Step 3: Enable Warranty Module in ZAFTO                     │
│  Settings → Modules → Warranty Dispatch → ON                 │
│  Add AHS as a warranty company relationship.                  │
│  Start receiving dispatches and managing them in ZAFTO.       │
│  [Enable Warranty Module →]                                   │
│                                                              │
│  COMMON CONCERNS                                             │
│                                                              │
│  "Warranty work doesn't pay enough"                          │
│  Average AHS plumbing dispatch nets $220 after parts.         │
│  At 10 dispatches/month that's $2,200 with zero acquisition   │
│  cost. Your retail marketing costs you $50-100 per lead.     │
│  Warranty work has $0 lead cost.                              │
│                                                              │
│  "I'll lose my retail customers"                             │
│  Warranty work fills schedule gaps. Slow Tuesday? Take a      │
│  dispatch. Retail stays priority. And every warranty           │
│  homeowner becomes a retail prospect for future work.          │
│                                                              │
│  [Mark as In Progress]  [Dismiss]  [Save for Later]          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Z INTELLIGENCE MATCHING LOGIC

### Opportunity Scoring

```dart
// lib/services/growth_advisor_service.dart

class GrowthAdvisorService {

  /// Score and rank opportunities for a specific company
  List<ScoredOpportunity> getRecommendations(
    Company company,
    List<Job> recentJobs,
    List<GrowthOpportunityInteraction> interactions,
  ) {
    final opportunities = fetchActiveOpportunities();
    final scored = <ScoredOpportunity>[];

    for (final opp in opportunities) {
      // Skip dismissed or completed
      if (interactions.isDismissed(opp.id)) continue;
      if (interactions.isCompleted(opp.id)) continue;

      double score = opp.priority / 100.0; // Base: editorial priority

      // Trade match (required)
      if (!opp.trades.any((t) => company.trades.contains(t))) continue;

      // State match (if specified)
      if (opp.states != null && !opp.states!.contains(company.state)) continue;

      // Team size match
      if (company.teamSize < opp.minTeamSize) continue;
      if (opp.maxTeamSize != null && company.teamSize > opp.maxTeamSize!) continue;

      // Prerequisite certs
      if (opp.prerequisiteCertifications != null &&
          !opp.prerequisiteCertifications!.every(
            (c) => company.certifications.contains(c))) continue;

      // BOOST: Category they're not doing yet
      if (opp.category == 'warranty_network' && !company.warrantyModuleEnabled) {
        score += 0.3; // High value — new revenue stream
      }
      if (opp.category == 'carrier_program' && !company.insuranceModuleEnabled) {
        score += 0.3;
      }

      // BOOST: Seasonal timing
      if (opp.isSeasonal && _isInPrepWindow(opp)) {
        score += 0.25; // Time-sensitive, surface now
      }

      // BOOST: Revenue gap detected
      final revenueByType = _calculateRevenueByType(recentJobs);
      if (revenueByType['warranty'] == 0 && opp.category == 'warranty_network') {
        score += 0.2; // They're leaving money on the table
      }
      if (revenueByType['insurance'] == 0 && opp.category == 'carrier_program') {
        score += 0.2;
      }

      // BOOST: Low difficulty for newer contractors
      if (opp.difficulty == 'easy' && company.monthsOnPlatform < 6) {
        score += 0.15; // Quick wins build trust in the feature
      }

      // REDUCE: Already doing similar work
      if (opp.category == 'warranty_network' &&
          company.warrantyRelationships.length >= 3) {
        score -= 0.2; // Already well-networked
      }

      scored.add(ScoredOpportunity(opportunity: opp, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(10).toList(); // Top 10 recommendations
  }
}
```

### Proactive AI Triggers

```
Z AI checks Growth Advisor signals during natural conversation:

TRIGGER: Contractor asks about slow periods
  "Business is slow this month, what should I do?"
  → Z AI surfaces warranty network opportunities
  → "Have you considered joining a home warranty network?
     You'd get dispatches sent directly to you during slow periods."

TRIGGER: Contractor completes milestone
  10th insurance claim completed
  → Surface HAAG certification for roofers
  → Surface IICRC advanced certs for restoration

TRIGGER: Seasonal window approaching
  6 weeks before hail season in contractor's region
  → Surface carrier preferred vendor applications
  → Surface storm prep checklist

TRIGGER: Revenue concentration risk
  90%+ revenue from single source (e.g., all retail)
  → Surface diversification opportunities
  → "Your business is 94% retail. Adding warranty dispatches
     could add $2K-4K/month with zero marketing spend."

TRIGGER: New trade added
  Contractor adds a second trade to their profile
  → Surface opportunities specific to that trade
  → Show cross-trade revenue potential

TRIGGER: Competitor comparison
  Contractor asks "how do I compete with [larger company]"
  → Surface certifications and programs that level the field
```


---

## CONTENT MANAGEMENT

### How the Knowledge Base Gets Built

```
This is NOT AI-generated content thrown at contractors.
This is curated, verified, actionable intelligence.

INITIAL BUILD (Pre-Launch):
  1. Research top 5 opportunities per trade (8 trades × 5 = 40 entries)
  2. Verify all application URLs and requirements
  3. Confirm state-specific licensing requirements
  4. Write step-by-step guides with actual links
  5. Add revenue potential estimates from industry data
  6. Seed the growth_opportunities table

ONGOING MAINTENANCE:
  - Quarterly verification of all external links and requirements
  - Seasonal updates (storm season, weatherization program cycles)
  - New program additions as federal/state programs launch
  - User feedback integration (which opportunities actually worked)
  - Revenue tracking for contractors who followed recommendations

CONTENT QUALITY RULES:
  - Every opportunity must have a verified external link
  - Revenue estimates must cite source or methodology
  - Step-by-step guides must be tested (actually go through the process)
  - State-specific content must specify which states
  - Seasonal content must have accurate date windows
  - NEVER give legal, tax, or financial advice — only point to resources
```

### Content Categories

```
warranty_network     — Warranty company enrollment programs
carrier_program      — Insurance carrier preferred vendor lists
certification        — Industry certifications that unlock work
government_program   — Federal, state, municipal contractor programs
seasonal             — Time-sensitive opportunities (storm season, etc.)
revenue_stream       — New service lines to add (sewer camera, maint plans, etc.)
```

---

## THE BUSINESS CASE FOR TEREDA

### Why Growth Advisor Is Strategic

```
1. ACTIVATION
   A contractor who enables insurance or warranty modules after
   a Growth Advisor recommendation has 3x the retention rate of
   one who only uses standard jobs. More modules = more switching cost.

2. EXPANSION REVENUE
   Contractor grows from Solo ($X/mo) to Pro ($XX/mo) to Team ($XXX/mo)
   because Growth Advisor showed them how to scale. ZAFTO's revenue
   grows with the contractor's business.

3. WORD OF MOUTH
   "ZAFTO showed me how to get on AHS and now I'm making an extra
   $3K a month" is the most powerful marketing possible.
   Growth Advisor turns users into evangelists.

4. DATA MOAT
   Over time, ZAFTO accumulates data on which opportunities
   actually produce revenue for which contractor profiles.
   That signal gets fed back into the scoring algorithm.
   The recommendations get better with scale.
   No competitor can replicate this without the same data.

5. PARTNERSHIP LEVERAGE
   When ZAFTO drives contractor enrollment to AHS, Frontdoor, State Farm:
   "We sent you 500 new contractors last quarter."
   That's leverage for co-marketing deals, API access, preferred status.
   Growth Advisor becomes a contractor acquisition channel for
   warranty companies and carriers — they'll want to be listed.
```

### Future Revenue Opportunity: Promoted Listings

```
Phase 1 (Launch): All opportunities are organic, curated by Tereda.
Phase 2 (Scale):  Warranty companies and carriers can PAY to be
                  featured in Growth Advisor recommendations.

"American Home Shield is actively recruiting HVAC contractors
in your area" — AHS pays for that placement.

This is the Indeed/LinkedIn model: the platform that connects
workers to opportunities monetizes the connection.

NOT AT LAUNCH. Build trust with organic content first.
Monetize later when the contractor base is large enough
to make promoted listings valuable to partners.
```

---

## IMPLEMENTATION PRIORITY

### Phase 1 — Launch (Seed Content + Basic UI)

| Feature | Effort |
|---------|--------|
| Create growth_opportunities table | 30 min |
| Create growth_opportunity_interactions table | 15 min |
| Seed initial 40 opportunities (5 per trade) | 8 hours |
| Dashboard widget (top 2 recommendations) | 4 hours |
| Opportunity detail view | 4 hours |
| Basic matching logic (trade + state + eligibility) | 3 hours |
| Dismiss / save / in-progress tracking | 2 hours |
| **Total** | **~22 hours** |

### Phase 2 — Intelligence (3 Months Post-Launch)

| Feature | Effort |
|---------|--------|
| Full scoring algorithm with revenue gap analysis | 6 hours |
| Z AI proactive triggers (6 trigger types) | 8 hours |
| Seasonal content rotation | 3 hours |
| "Grow" tab with full browser + filters | 6 hours |
| Progress tracking (started → completed) | 3 hours |
| **Total** | **~26 hours** |

### Phase 3 — Data Loop (6+ Months)

| Feature | Effort |
|---------|--------|
| Revenue impact tracking (did the opportunity actually produce?) | 8 hours |
| Recommendation quality scoring | 4 hours |
| Content expansion to 100+ opportunities | 12 hours |
| Promoted listings infrastructure (future monetization) | 16 hours |
| **Total** | **~40 hours** |

```
TOTAL ALL PHASES:

Phase 1 (launch):      ~22 hours
Phase 2 (intelligence): ~26 hours
Phase 3 (data loop):    ~40 hours
─────────────────────────────────
TOTAL:                  ~88 hours
```

---

## WHAT GROWTH ADVISOR IS NOT

```
NOT a compliance tool.
  We don't calculate prevailing wages, generate certified payroll,
  or file Davis-Bacon reports. We TELL you the program exists
  and LINK you to the enrollment page.

NOT legal advice.
  We don't interpret licensing requirements. We SHOW you your
  state's licensing board website and TELL you what cert is typically
  needed. "Consult your state licensing board for current requirements."

NOT financial advice.
  Revenue estimates are industry averages, not guarantees.
  "Based on industry data, warranty HVAC contractors average..."
  not "You WILL make $3,000/month."

NOT a lead generation service.
  We don't send you warranty dispatches or insurance claims.
  We show you how to get yourself into the networks that do.
  ZAFTO manages the work once you get it.

The line is clear: ZAFTO is the map, not the territory.
We show you the doors. You walk through them.
```

---

## DEPENDENCIES

| This Document | Depends On |
|---------------|------------|
| Module enable detection | `Locked/37_JOB_TYPE_SYSTEM.md` — insurance/warranty toggle |
| Insurance opportunities | `Locked/36_RESTORATION_INSURANCE_MODULE.md` — carrier programs |
| Warranty opportunities | `38_INSURANCE_VERTICALS.md` — warranty network detail |
| AI triggers | `35_UNIVERSAL_AI_ARCHITECTURE.md` — Z Intelligence |
| Revenue analysis | `27_BUSINESS_OS_EXPANSION.md` — Zafto Books data |
| Database | `Locked/29_DATABASE_MIGRATION.md` — new tables in migration |

---

## CHANGELOG

| Date | Change |
|------|--------|
| 2026-02-05 | Initial specification. Growth Advisor with opportunity KB, matching logic, UI design, per-trade opportunity catalog, and Z AI integration. |

---

*ZAFTO doesn't just manage your business. It grows your business.
Every contractor who follows a Growth Advisor recommendation becomes
stickier, more profitable, and a louder evangelist.
That's not a feature. That's a flywheel.*
