# ZAFTO UNIFIED COMMAND CENTER — Contractor Operations Hub
## Created: February 5, 2026 (Session 33)
## Status: DRAFT — To be reviewed and consolidated
## Inspiration: Meta Business Suite operational philosophy, adapted for trade businesses

---

## PURPOSE

Every trade contractor is drowning in fragmented tools. Leads come from 6-8 different
channels. Messages scatter across texts, emails, DMs, and voicemails. Jobs live in one
app, invoices in another, and the schedule on a whiteboard. Marketing is an afterthought
because there's no time.

Meta Business Suite solved this for social media businesses: one dashboard, one inbox,
one content engine, one analytics view. ZAFTO applies the same philosophy to running
a trade business — but with Z Intelligence sitting in the middle connecting every
data point, surfacing insights, and driving action.

**ZAFTO is not a social media tool. ZAFTO is the contractor's command center.**

Everything that follows builds on the existing ZAFTO ecosystem (jobs, bids, invoices,
customers, field tools, AI) and extends it with concepts proven by Meta's approach
but purpose-built for trades.

---

## CONCEPT 1: UNIFIED LEAD INBOX

### The Problem

Contractors receive inbound leads from:
- Google Business Profile messages and calls
- Facebook page DMs and Messenger
- Instagram DMs
- Thumbtack / Angi / HomeAdvisor lead notifications
- Website contact forms
- Direct phone calls and voicemails
- Text messages
- Email inquiries
- Nextdoor recommendations and messages
- Yelp messages

Most contractors check 6-8 apps throughout the day. Leads fall through cracks.
Response time suffers. The contractor who responds first wins the job — data from
Layer 5 compounding intelligence shows same-day response closes at 68% vs 23% after 4+ days.

### The Solution: One Inbox, Every Channel

All inbound communications flow into a single stream inside ZAFTO. The contractor
opens one app, sees every lead, every message, every inquiry — regardless of source.

**Channel integrations (phased rollout):**

| Channel | Integration Method | Priority |
|---------|-------------------|----------|
| Google Business Profile | Google Business API | Phase 1 |
| Facebook / Messenger | Meta Graph API (via Meta Business Suite) | Phase 1 |
| Instagram DMs | Meta Graph API (same integration) | Phase 1 |
| Website contact forms | ZAFTO webhook / embeddable form widget | Phase 1 |
| SMS / Text messages | Twilio or similar SMS gateway | Phase 1 |
| Email | IMAP/SMTP integration or dedicated inbox | Phase 2 |
| Thumbtack | Thumbtack API (if available) or email parsing | Phase 2 |
| Angi / HomeAdvisor | Email parsing (no public API) | Phase 2 |
| Voicemail | Transcription via Whisper/Deepgram → text in inbox | Phase 2 |
| Nextdoor | Email notification parsing | Phase 3 |
| Yelp | Email notification parsing | Phase 3 |

**Inbox UI (Mobile App):**

```
┌─────────────────────────────────────────────┐
│  LEADS & MESSAGES                    [Filter]│
│─────────────────────────────────────────────│
│  🔴 NEW  Sarah Johnson              2m ago  │
│  Google Business · "Need electrician for     │
│  panel upgrade, 1950s home"                  │
│  [Reply]  [Create Job]  [Ask Z]             │
│─────────────────────────────────────────────│
│  🔴 NEW  Mike Torres                15m ago │
│  Facebook · "Do you guys do EV charger      │
│  installs? What's the ballpark?"             │
│  [Reply]  [Create Job]  [Ask Z]             │
│─────────────────────────────────────────────│
│  🟡 PENDING  Lisa Chen              1h ago  │
│  Website Form · Bathroom remodel estimate    │
│  Z auto-replied: confirmation + availability │
│  [View Thread]  [Create Job]                │
│─────────────────────────────────────────────│
│  ✅ REPLIED  James Wright           3h ago  │
│  Text Message · "When can you come look at   │
│  the leak under the kitchen sink?"           │
│  [View Thread]  [Schedule]                  │
│─────────────────────────────────────────────│
│                                             │
│  📊 Today: 4 new leads · 1 auto-replied     │
│     Avg response time: 12 minutes           │
└─────────────────────────────────────────────┘
```

**Inbox features:**
- Source icon on every message (Google, Facebook, text, email, etc.)
- Status tracking: New → Replied → Scheduled → Converted to Job → Won/Lost
- One-tap actions: Reply, Create Job, Schedule Estimate, Ask Z
- Conversation threading across channels (if same customer texts AND emails)
- Customer matching: if the lead matches an existing customer, show their history
- Priority sorting: new leads on top, then pending, then replied

### Z Intelligence in the Inbox

This is where ZAFTO leapfrogs everything else on the market. Z isn't just organizing
the inbox — Z is actively working every lead.

**AI Auto-Response (instant, company-branded):**

When a lead comes in, Z can auto-respond within seconds. Not a generic template —
a response generated from the company's Layer 1 profile:

```
Lead (Google): "Do you install tankless water heaters?"

Z auto-response (within 30 seconds):
"Hi! Yes — [Company Name] installs and services tankless water heaters
including Navien, Rinnin, and Rheem. We serve the [service area] area
and would be happy to provide a free estimate. What's a good time for
a quick call or site visit?

— [Company Name] Team"
```

This response was NOT pre-written. Z generated it from:
- Company profile: services offered, brands carried (Layer 1)
- Service area from company settings
- Communication style from company preferences
- Trade-appropriate language

**Auto-response rules (owner-configurable):**

```
Settings → Z Intelligence → Auto-Response

┌─────────────────────────────────────────────┐
│  Z Auto-Response Settings                   │
│                                             │
│  ☑ Enable auto-response for new leads       │
│                                             │
│  Response timing:                           │
│  ○ Instant (within 30 seconds)              │
│  ● After 2 minutes (feels more natural)     │
│  ○ Only outside business hours              │
│  ○ Disabled (I'll respond manually)         │
│                                             │
│  Auto-response scope:                       │
│  ☑ Confirm receipt + ask for details        │
│  ☑ Answer common service questions          │
│  ☐ Provide pricing ranges (if enabled)      │
│  ☑ Suggest scheduling next step             │
│                                             │
│  Channels:                                  │
│  ☑ Google Business  ☑ Facebook  ☑ Website   │
│  ☑ Text messages    ☐ Email                 │
│                                             │
│  Always notify me when Z auto-responds      │
│  ☑ Push notification  ☑ In-app badge        │
└─────────────────────────────────────────────┘
```

**Z Lead Intelligence (proactive nudges):**

Z monitors the inbox and surfaces actionable insights:

```
"You have 3 leads from this morning that haven't been responded to.
Your close rate drops 40% after the first hour. Want me to draft replies?"

"Sarah Johnson's panel upgrade inquiry — her address shows a 1950s home.
Likely 100A fuse box → 200A panel upgrade. Average bid in your area:
$2,800-3,600. Want me to pre-build a scope?"

"Mike Torres asked about EV charger installs. You've done 4 this quarter.
Your average bid was $1,800. Want me to draft a response with your
typical range?"
```

These insights pull from:
- Layer 1: company profile, service offerings
- Layer 4: current inbox state and timing
- Layer 5: compounding intelligence (pricing, response time data, close rates)
- Layer 6: only shown to Owner/Admin

---

## CONCEPT 2: LEAD-TO-JOB PIPELINE

### The Problem

Meta shows leads flowing: Ad → Click → Message → Conversion. Simple funnel.
Contractors have a similar pipeline that lives in their heads or on sticky notes:

```
Lead In → Estimate Scheduled → Site Visit → Bid Sent → Follow-Up → Won/Lost
```

Most contractors have no visibility into where their deals stand, how long bids
have been sitting, or where they're losing jobs.

### The Solution: Visual Sales Pipeline

A Kanban-style pipeline view that shows every opportunity at a glance:

```
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ NEW LEADS │ │ ESTIMATE │ │  SITE    │ │   BID    │ │ FOLLOW   │ │   WON    │
│    (7)    │ │SCHEDULED │ │  VISIT   │ │  SENT    │ │   UP     │ │   (3)    │
│           │ │   (3)    │ │   (2)    │ │   (12)   │ │   (5)    │ │          │
│ ┌───────┐ │ │ ┌───────┐ │ │ ┌───────┐ │ │ ┌───────┐ │ │ ┌───────┐ │ │ ┌───────┐ │
│ │Johnson│ │ │ │ Chen  │ │ │ │Torres │ │ │ │Wright │ │ │ │Adams  │ │ │ │Baker  │ │
│ │Panel  │ │ │ │Bath   │ │ │ │EV Chg │ │ │ │Leak   │ │ │ │Rewire │ │ │ │Panel  │ │
│ │$3.2K  │ │ │ │$15K   │ │ │ │$1.8K  │ │ │ │$450   │ │ │ │$8K    │ │ │ │$3.4K  │ │
│ │2m ago │ │ │ │Tue 2p │ │ │ │Today  │ │ │ │5 days │ │ │ │12 days│ │ │ │Signed │ │
│ └───────┘ │ │ └───────┘ │ │ └───────┘ │ │ └───────┘ │ │ └───────┘ │ │ └───────┘ │
│ ┌───────┐ │ │          │ │          │ │ 🔴 3 bids │ │ 🔴 2 over│ │          │
│ │Torres │ │ │          │ │          │ │ over 7d   │ │ 14 days  │ │          │
│ │EV Chrg│ │ │          │ │          │ │           │ │          │ │          │
│ └───────┘ │ │          │ │          │ │           │ │          │ │          │
└──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘

Pipeline Value: $47,200  |  Avg Days to Close: 8.3  |  Win Rate: 52%
```

**Pipeline features:**
- Drag-and-drop cards between stages (mobile: swipe actions)
- Color-coded aging warnings (green < 3 days, yellow 3-7, red 7+)
- Pipeline value totals per stage and overall
- One-tap to open job detail, send follow-up, or ask Z
- Filter by trade, date range, assignee, value range
- Lost deals tracked separately with loss reasons for pattern analysis

### Z Intelligence in the Pipeline

```
"Your pipeline has $47,200 in open opportunities. 3 bids are over 7 days
old — your win rate drops to 29% in that range. Want me to draft follow-ups?"

"You're closing 52% of bids this month, up from 44% last month. The
biggest factor: your average response time dropped from 4 hours to 45
minutes since you enabled auto-response."

"Adams rewire has been in follow-up for 12 days with no response. Based
on patterns, this one is likely lost. Want me to send a final check-in
or move it to lost?"
```

---

## CONCEPT 3: SERVICE CATALOG + CLIENT PORTAL

### Meta's Product Catalog → ZAFTO's Service Catalog

Meta lets businesses tag products in posts for tap-to-buy. ZAFTO's equivalent:
a service catalog that lives in the client portal (Home Portal) where homeowners
can browse services, request estimates, and self-schedule.

### How It Works

**Contractor side (setup):**

```
Settings → Service Catalog

┌─────────────────────────────────────────────┐
│  YOUR SERVICES                              │
│                                             │
│  ☑ Panel Upgrades           [$2,500-4,000]  │
│  ☑ EV Charger Installation  [$1,200-2,500]  │
│  ☑ Whole-Home Rewiring      [$8,000-15,000] │
│  ☑ Ceiling Fan Installation [$150-300]      │
│  ☑ Outlet/Switch Repair     [$100-200]      │
│  ☑ Emergency Electrical     [Call for quote] │
│  ☑ Electrical Inspection    [$200-350]      │
│                                             │
│  Pricing display:                           │
│  ● Show ranges (builds trust)               │
│  ○ "Request Estimate" only                  │
│  ○ Hide catalog (leads only through inbox)  │
│                                             │
│  + Add Service                              │
└─────────────────────────────────────────────┘
```

**Homeowner side (Home Portal / Client Portal):**

```
┌─────────────────────────────────────────────┐
│  BRIGHT WIRE ELECTRICAL                     │
│  ⭐ 4.9 (127 reviews) · Serving Greater CT  │
│                                             │
│  SERVICES                                   │
│                                             │
│  ⚡ Panel Upgrades              $2,500-4,000 │
│     Upgrade your electrical panel to modern  │
│     200A service. Includes permit.           │
│     [Request Estimate]                       │
│                                             │
│  🔌 EV Charger Installation    $1,200-2,500 │
│     Level 2 charger install for Tesla,       │
│     Ford, and all major EVs.                 │
│     [Request Estimate]                       │
│                                             │
│  🏠 Whole-Home Rewiring        $8,000-15,000│
│     Complete rewiring for older homes.       │
│     [Request Estimate]                       │
│                                             │
│  RECENT WORK                                │
│  [Before/After Gallery — see Concept 4]     │
└─────────────────────────────────────────────┘
```

**When homeowner taps "Request Estimate":**

The lead hits the unified inbox already pre-qualified:
- Service type selected (Panel Upgrade)
- Customer's property profile (if they have a Home Portal account)
- Equipment age and history (if tracked)
- Z has already drafted a preliminary scope based on the service + property data

```
INBOX — New Lead:
Sarah Johnson · Home Portal · Panel Upgrade Request
Property: 45 Oak St, 1952 colonial, current 100A fuse box
Equipment: GE fuse panel, est. 1960s, no previous upgrades on file

Z pre-draft: "Based on the property profile, this is likely a 100A fuse
box → 200A panel upgrade. Typical scope: new 200A panel, 200A main
breaker, meter socket if required by utility, permit + inspection.
Standard bid range for your area: $2,800-3,600."
```

The contractor didn't have to ask a single qualifying question. The ecosystem
already had the context.

---

## CONCEPT 4: PROJECT SHOWCASE ENGINE (Automated Marketing)

### The Problem

Meta Business Suite's content engine is about scheduling posts and reels.
Contractors don't need to schedule tweets. They need to showcase their work.
But marketing is always the last priority because there's no time.

### The Solution: Job Completion → Auto-Generated Showcase

ZAFTO already captures job photos through field tools. The showcase engine
turns completed jobs into marketing assets as a byproduct of doing the work.

**The flow:**

```
1. Tech takes before/after photos during the job (already happens via field tools)
2. Job marked complete in ZAFTO
3. Z detects: completed job + photos available
4. Z prompts the contractor:

   "Nice work on the panel upgrade at Oak Street. Want me to create a
    before/after showcase from your job photos?

    [Yes, create showcase]  [Not this one]  [Settings]"

5. If yes → Z generates:
   - Before/after photo grid (auto-cropped, enhanced)
   - Caption: "200A panel upgrade replacing a 1960s fuse box. Modern
     Square D panel with whole-home surge protection. Safe, clean, up
     to code. #electrician #panelupgrade #[city]"
   - Formatted for each platform (square for Instagram, landscape for FB)

6. Contractor reviews and approves with one tap

7. Showcase publishes to:
   ☑ Facebook page (via Meta Graph API)
   ☑ Instagram (via Meta Graph API)
   ☑ ZAFTO public profile / portfolio
   ☑ Google Business Profile (via Google API)
   ☐ Nextdoor (manual — no API)
```

**Portfolio on ZAFTO profile:**

```
BRIGHT WIRE ELECTRICAL — Recent Work

┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ Before/After│ │ Before/After│ │ Before/After│
│  [photos]   │ │  [photos]   │ │  [photos]   │
│             │ │             │ │             │
│ 200A Panel  │ │ EV Charger  │ │ Whole-Home  │
│ Upgrade     │ │ Install     │ │ Rewire      │
│ Jan 2026    │ │ Jan 2026    │ │ Dec 2025    │
└─────────────┘ └─────────────┘ └─────────────┘
```

**Why this matters:**

Contractors who showcase their work consistently get 2-3x more inbound leads.
But most never do it because it's a separate workflow. ZAFTO makes it automatic —
the marketing happens as a side effect of closing jobs. Zero extra effort.

**Z Intelligence in the showcase engine:**

```
"You've completed 8 jobs this month but only showcased 2. Your profile
with regular showcases gets 3x more profile views. Want me to create
showcases for the other 6?"

"Your panel upgrade showcases get the most engagement. Consider featuring
that service more prominently in your catalog."
```

---

## CONCEPT 5: BUSINESS COMMAND DASHBOARD

### Meta's Analytics → ZAFTO's Operations Dashboard

Meta gives you reach, engagement, followers. Vanity metrics for most businesses.
Contractors need to see what actually drives revenue and operations.

### One Screen, Everything That Matters

```
┌─────────────────────────────────────────────────────────────────┐
│  DASHBOARD — February 2026                          Good morning│
│─────────────────────────────────────────────────────────────────│
│                                                                 │
│  REVENUE          PIPELINE           COLLECTION                 │
│  $24,800          $47,200            $12,400                    │
│  ↑ 12% vs Jan     12 open bids       outstanding               │
│                                      ↑ 30% vs Jan ⚠️           │
│                                                                 │
│  LEADS            RESPONSE TIME      WIN RATE                   │
│  18 this month    45 min avg         52%                        │
│  ↑ from 12 Jan    ↓ from 4hr Jan ✅  ↑ from 44% Jan            │
│                                                                 │
│─────────────────────────────────────────────────────────────────│
│  THIS WEEK                                                      │
│                                                                 │
│  Mon: Torres EV charger (9am) · Chen bath estimate (2pm)        │
│  Tue: Wright leak repair (8am) · Inspection @ Oak St (1pm)      │
│  Wed: [open] · [open]                                           │
│  Thu: Adams rewire start (all day)                              │
│  Fri: [open]                                                    │
│                                                                 │
│─────────────────────────────────────────────────────────────────│
│  Z INSIGHTS                                                     │
│                                                                 │
│  💰 "Revenue is up 12% but receivables are up 30% — you're     │
│      doing more work but collecting slower. Your 3 oldest       │
│      invoices: Wright ($450, 22 days), Chen ($2,100, 18 days),  │
│      Park ($890, 15 days). Want me to send reminders?"          │
│                                                                 │
│  📋 "3 bids over 7 days old. Win rate drops to 29% past 7      │
│      days. Draft follow-ups?"                                   │
│                                                                 │
│  📸 "You completed 4 jobs this week with photos. Only 1         │
│      showcased. Create showcases for the others?"               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Dashboard data sources (all from existing ZAFTO ecosystem):**

| Metric | Source |
|--------|--------|
| Revenue | Invoices table (paid this period) |
| Pipeline value | Bids table (open/pending status) |
| Outstanding receivables | Invoices table (unpaid, aging) |
| Leads | Unified inbox (new this period) |
| Response time | Inbox timestamps (lead in → first reply) |
| Win rate | Bids table (won vs total closed) |
| Schedule | Jobs table + calendar |
| Z Insights | Layers 1-6 intelligence synthesis |

**Key difference from Meta:** Meta shows you metrics. ZAFTO shows you metrics
AND tells you what to do about them. Every insight has an action button.
"Your receivables are up" → [Send Reminders]. "Bids are aging" → [Draft Follow-ups].
"Jobs not showcased" → [Create Showcases]. Z turns data into action.

---

## CONCEPT 6: REVIEW & REPUTATION ENGINE

### The Problem

Reviews drive 70%+ of homeowner decisions on which contractor to hire. Most
contractors forget to ask, or feel awkward asking. The ones who systematically
request reviews dominate their local market.

### The Solution: Automated Review Requests

```
Job completed → Invoice paid → Z triggers review request sequence:

Day 0 (payment received):
  "Hi Sarah — thanks for choosing Bright Wire for your panel upgrade!
   If you have a moment, a quick review would mean the world to us.
   [Leave a Google Review] [Leave a Facebook Review]"

Day 3 (if no review):
  "Hi Sarah — just a gentle reminder. Your feedback helps other homeowners
   find reliable electricians. Takes less than a minute!
   [Leave a Review]"

Day 7 (final):
  "Last reminder — we'd love to hear how your panel upgrade is working
   out. [Leave a Review]"
```

**Z generates the request based on:**
- Customer name and job type (personalized, not generic)
- Correct review links for the contractor's Google and Facebook profiles
- Timing based on payment confirmation (not job completion — you want them
  happy about the final product AND the billing experience)

**Review monitoring:**
- New reviews across Google, Facebook, Yelp surfaced in the dashboard
- Z alerts: "New 5-star review from Sarah Johnson on Google. Want to
  reply with a thank you?"
- Z drafts reply: "Thank you Sarah! Glad the new panel is working great.
  Don't hesitate to reach out if you need anything."
- Negative review alert with suggested response strategy

**Review analytics:**
- Total reviews across platforms
- Average rating trend
- Review velocity (reviews per month)
- Comparison to local competitors (if available from public data)

---

## CONCEPT 7: CROSS-CHANNEL CUSTOMER IDENTITY

### The Problem

A homeowner texts on Monday, DMs on Facebook on Wednesday, and emails on Friday.
Most contractors treat these as three separate conversations. Meta solved this for
their platforms — one person, one thread, regardless of channel.

### The Solution: Unified Customer Record

```sql
-- Customer contact methods (extends existing customers table)
CREATE TABLE customer_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id) NOT NULL,
  contact_type TEXT NOT NULL,     -- 'phone', 'email', 'facebook', 'instagram', 'google'
  contact_value TEXT NOT NULL,    -- The actual phone/email/profile ID
  is_primary BOOLEAN DEFAULT false,
  verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(contact_type, contact_value)
);

-- All communications linked to customer regardless of channel
CREATE TABLE customer_communications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id),
  lead_id UUID REFERENCES leads(id),           -- If from inbox before customer match
  channel TEXT NOT NULL,          -- 'sms', 'email', 'facebook', 'instagram', 'google', 'phone', 'web_form'
  direction TEXT NOT NULL,        -- 'inbound', 'outbound'
  content TEXT NOT NULL,
  attachments JSONB,
  sent_by TEXT,                   -- 'customer', 'owner', 'tech', 'z_auto'
  ai_generated BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Matching logic:**
1. New lead comes in from Facebook with name "Sarah Johnson"
2. System checks customer_contacts for matching Facebook profile ID
3. If match → thread into existing customer record
4. If no match → check by phone number or email (if provided in message)
5. If still no match → create new lead, prompt contractor to link or create customer
6. Z assists: "This lead looks like Sarah Johnson at 45 Oak St based on the
   name and service area. Same person? [Yes, link] [No, new customer]"

**Result:** The contractor sees one unified conversation thread per customer,
regardless of whether they texted, DM'd, emailed, or called. Full history
in one place.

---

## INTEGRATION WITH EXISTING ZAFTO ARCHITECTURE

### How These Concepts Map to Existing Systems

| New Concept | Existing ZAFTO Component | Relationship |
|-------------|-------------------------|--------------|
| Unified Inbox | Jobs, Customers tables | Leads flow into existing job pipeline |
| Sales Pipeline | Bids table | Visual layer on existing bid data |
| Service Catalog | Company profile, services | Extends existing company settings |
| Showcase Engine | Field tool photos, job records | Automated content from existing data |
| Command Dashboard | All existing tables | Aggregation layer, no new data needed |
| Review Engine | Customers, invoices | Triggered by existing payment events |
| Customer Identity | Customers table | Extends with multi-channel contacts |

### How These Concepts Map to AI Architecture (Doc 35)

| Concept | AI Layers Used | How |
|---------|---------------|-----|
| Inbox auto-response | L1 (identity) + L5 (response time data) | Company profile drives personalized responses |
| Lead intelligence | L1 + L4 (session) + L5 (pricing/timing patterns) | Z surfaces insights from pipeline state |
| Service catalog pre-qualification | L1 + L3 (customer memory) | Property data enriches lead context |
| Showcase generation | L1 (company) + L4 (job context) | Z creates captions from job + company data |
| Dashboard insights | L1 + L5 (all compounding patterns) + L6 (RBAC) | Owner sees everything, techs see their schedule |
| Review request drafting | L1 + L3 (customer memory) | Personalized requests from customer relationship |

---

## COMPETITIVE POSITIONING

| Feature | ServiceTitan | Jobber | Housecall Pro | ZAFTO |
|---------|:----------:|:-----:|:------------:|:-----:|
| Unified multi-channel inbox | ⚠️ | ❌ | ⚠️ | ✅ |
| AI auto-response (contextual) | ❌ | ❌ | ❌ | ✅ |
| AI-powered lead intelligence | ❌ | ❌ | ❌ | ✅ |
| Visual sales pipeline | ✅ | ✅ | ✅ | ✅ |
| Service catalog for homeowners | ⚠️ | ⚠️ | ⚠️ | ✅ |
| Auto-generated project showcases | ❌ | ❌ | ❌ | ✅ |
| Cross-platform social publishing | ❌ | ❌ | ❌ | ✅ |
| AI business insights on dashboard | ❌ | ❌ | ❌ | ✅ |
| Automated review requests | ✅ | ✅ | ✅ | ✅ |
| Cross-channel customer identity | ⚠️ | ❌ | ⚠️ | ✅ |
| Compounding intelligence (L5) | ❌ | ❌ | ❌ | ✅ |

✅ = Full feature  ⚠️ = Partial/limited  ❌ = Not available

**The moat:** Everyone has pipelines and review requests. Nobody has an AI that
auto-responds to leads using your company profile, pre-qualifies leads from
property data, generates marketing from completed jobs, and tells you where
you're losing money — all from one ecosystem where everything feeds everything else.

---

## BUILD PHASES

| Phase | What | Dependencies |
|-------|------|-------------|
| **Phase 1** | Unified inbox — SMS + web form + manual entry | Twilio, webhook system |
| **Phase 2** | Meta integration — Facebook + Instagram + Messenger | Meta Graph API approval |
| **Phase 3** | Google Business Profile integration | Google Business API |
| **Phase 4** | Z auto-response in inbox | Doc 35 Layer 1 + edge function |
| **Phase 5** | Visual sales pipeline (Kanban) | Existing bids table |
| **Phase 6** | Service catalog + client portal integration | Doc 16 Home Portal |
| **Phase 7** | Showcase engine — auto-generate from job photos | Meta Graph API, Google API |
| **Phase 8** | Command dashboard with Z insights | All existing data + Doc 35 L5 |
| **Phase 9** | Review request automation | Google/Facebook review links |
| **Phase 10** | Cross-channel customer identity matching | customer_contacts schema |
| **Phase 11** | Email/Thumbtack/Angi integrations | IMAP, email parsing |
| **Phase 12** | Voicemail transcription integration | Whisper/Deepgram |

---

## SCHEMA ADDITIONS

```sql
-- Unified inbox leads (before they become customers/jobs)
CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  customer_id UUID REFERENCES customers(id),  -- Linked after identification
  source_channel TEXT NOT NULL,    -- 'google', 'facebook', 'instagram', 'sms', 'email', 'web_form', 'thumbtack', etc.
  source_raw JSONB,               -- Raw payload from source API
  contact_name TEXT,
  contact_phone TEXT,
  contact_email TEXT,
  message TEXT,
  service_requested TEXT,          -- Matched to service catalog if possible
  status TEXT DEFAULT 'new',       -- 'new', 'auto_replied', 'replied', 'scheduled', 'converted', 'lost'
  assigned_to UUID REFERENCES employees(id),
  auto_response_sent BOOLEAN DEFAULT false,
  auto_response_text TEXT,
  first_response_at TIMESTAMPTZ,  -- For response time tracking
  converted_to_job_id UUID REFERENCES jobs(id),
  lost_reason TEXT,
  priority TEXT DEFAULT 'normal',  -- 'urgent', 'normal', 'low'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Service catalog
CREATE TABLE service_catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  trade TEXT NOT NULL,
  service_name TEXT NOT NULL,
  description TEXT,
  price_type TEXT DEFAULT 'range', -- 'range', 'fixed', 'quote_only'
  price_min DECIMAL,
  price_max DECIMAL,
  price_fixed DECIMAL,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Project showcases (auto-generated from completed jobs)
CREATE TABLE project_showcases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  job_id UUID REFERENCES jobs(id) NOT NULL,
  trade TEXT NOT NULL,
  title TEXT NOT NULL,              -- "200A Panel Upgrade"
  description TEXT,                 -- AI-generated caption
  before_photos TEXT[],             -- Storage URLs
  after_photos TEXT[],              -- Storage URLs
  published_to JSONB DEFAULT '{}', -- {"facebook": true, "instagram": true, "google": false, "zafto_profile": true}
  published_at TIMESTAMPTZ,
  is_draft BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Review tracking
CREATE TABLE review_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  customer_id UUID REFERENCES customers(id) NOT NULL,
  job_id UUID REFERENCES jobs(id) NOT NULL,
  invoice_id UUID REFERENCES invoices(id),
  status TEXT DEFAULT 'pending',   -- 'pending', 'sent', 'reminded', 'completed', 'declined'
  request_count INTEGER DEFAULT 0,
  last_sent_at TIMESTAMPTZ,
  review_received BOOLEAN DEFAULT false,
  review_platform TEXT,            -- 'google', 'facebook', 'yelp'
  review_rating INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reviews received (monitored across platforms)
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  customer_id UUID REFERENCES customers(id),
  platform TEXT NOT NULL,          -- 'google', 'facebook', 'yelp'
  platform_review_id TEXT,         -- ID from the platform
  rating INTEGER NOT NULL,
  review_text TEXT,
  reviewer_name TEXT,
  response_text TEXT,              -- Contractor's reply
  response_sent_at TIMESTAMPTZ,
  ai_suggested_response TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_leads_company_status ON leads(company_id, status);
CREATE INDEX idx_leads_company_created ON leads(company_id, created_at DESC);
CREATE INDEX idx_communications_customer ON customer_communications(customer_id, created_at DESC);
CREATE INDEX idx_showcases_company ON project_showcases(company_id, published_at DESC);
CREATE INDEX idx_reviews_company ON reviews(company_id, created_at DESC);
```

---

## RULES

1. **One inbox, every channel.** A lead from any source hits the same stream. No exceptions.
2. **Z auto-response is opt-in and transparent.** Owner controls timing, scope, and channels.
   Customers are NEVER deceived — auto-responses come from "[Company] Team", not a fake human.
3. **Speed wins leads.** Every UX decision optimizes for faster response time. One-tap reply,
   pre-drafted responses, auto-response — all designed to close the response gap.
4. **Marketing is a byproduct of work.** Showcases are generated from job photos that were
   already captured. Zero extra workflow for the contractor.
5. **Ecosystem feeds ecosystem.** Leads become jobs, jobs create invoices, invoices trigger
   review requests, reviews drive more leads. The loop is closed.
6. **RBAC applies here too.** Techs see their schedule and assigned leads. Pipeline value,
   pricing, win rates, financials — Owner/Admin only per Doc 35 Layer 6.
7. **Customer identity is sacred.** One customer, one record, regardless of channel.
   Z helps match but never auto-merges without contractor confirmation.
8. **Showcase approval required.** Z drafts, contractor approves. Nothing publishes
   without explicit human confirmation. Never auto-post.
9. **Data belongs to the contractor.** All lead, communication, and customer data is
   company-scoped. RLS enforced. No cross-tenant leakage. If a contractor leaves
   ZAFTO, their data is exportable.
10. **Layer 5 compounds from these interactions.** Response time data, close rates,
    pricing patterns, review velocity — all feed into compounding intelligence
    for the entire platform.

---

**This document is a DRAFT. To be consolidated with existing expansion documentation.
Do not begin implementation until reviewed and prioritized against current sprint work.**
