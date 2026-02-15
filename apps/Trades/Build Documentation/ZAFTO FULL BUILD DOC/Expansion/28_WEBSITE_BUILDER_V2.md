# ZAFTO WEBSITE BUILDER V2
## Full-Scale Contractor Website Platform
### February 5, 2026 — Session 29

---

> **⚠️ DATABASE MIGRATION NOTE (Session 29):**
> All "Firestore" collections → Supabase PostgreSQL tables. All "Cloud Functions" → Supabase Edge Functions.
> See `Locked/29_DATABASE_MIGRATION.md`. Firebase fully decommissioned.

---

## EXECUTIVE SUMMARY

This is not a "website builder add-on." This is a full-scale website platform that:
- Looks like a $10,000 agency built it
- Requires zero technical knowledge
- Syncs live with CRM data
- Handles domains without external accounts
- Cannot be made ugly (strict templates)
- Has AI assistant trained on every template

**Price: $19.99/month** (includes hosting, SSL, subdomain)
**Custom Domain: +$14.99/year** (purchased through ZAFTO, zero external accounts)

---

## DOMAIN STRATEGY: OPTION C (LOCKED)

### The Decision

**Cloudflare Registrar API Integration**

User never creates an account anywhere. User never touches DNS. User never configures anything.
They search, click, pay, done. Site is live on their custom domain in 60 seconds.

### What The User Experiences

```
WHAT THEY DO:                           WHAT THEY DON'T DO:
─────────────                           ──────────────────
1. Search domain in ZAFTO               ❌ Create Cloudflare account
2. Click "Get It"                       ❌ Create GoDaddy account
3. Enter their business info            ❌ Learn what DNS is
4. Pay through ZAFTO checkout           ❌ Configure nameservers
5. Done. Site is live.                  ❌ Add CNAME records
                                        ❌ Provision SSL
TIME: 2 minutes                         ❌ Remember to renew
CONFUSION: Zero                         ❌ Deal with registrar support
```

### Technical Flow (Behind The Scenes)

```
USER CLICKS "GET IT"
       │
       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  ZAFTO CLOUD FUNCTION: purchaseDomain                                   │
│                                                                         │
│  1. Charge customer's card (Stripe)                                     │
│  2. Call Cloudflare API: POST /registrar/domains                        │
│     - Domain: teredaelectric.com                                        │
│     - Registrant: Customer's business info                              │
│     - Account: ZAFTO's Cloudflare account                               │
│  3. Cloudflare purchases domain from ICANN                              │
│  4. Call Cloudflare API: Create DNS zone                                │
│  5. Call Cloudflare API: Add A/CNAME records → our servers              │
│  6. SSL auto-provisioned by Cloudflare (free, automatic)                │
│  7. Update Firestore: companies/{id}/website.customDomain               │
│  8. Trigger website rebuild with new domain                             │
│  9. Done. Live in ~60 seconds.                                          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

USER SEES: "Your site is now live at teredaelectric.com 🎉"
```

### Zero Maintenance Guarantee

| Task | Who Handles It | Manual Work |
|------|----------------|:-----------:|
| Domain purchase | Cloudflare API | Zero |
| DNS configuration | Cloudflare API (auto) | Zero |
| SSL certificate | Cloudflare (auto, free) | Zero |
| SSL renewal | Cloudflare (auto, forever) | Zero |
| Domain renewal | Our billing + Cloudflare API | Zero |
| WHOIS privacy | Cloudflare (auto, free) | Zero |
| Website hosting | Cloudflare Pages (auto) | Zero |
| Site updates | User edits in ZAFTO → auto-publish | Zero |

**Nobody on ZAFTO team ever touches DNS. Ever.**

### Domain Ownership (Legal)

```
REGISTRANT (Legal Owner):     THE CUSTOMER
──────────────────────────────────────────
WHOIS shows:
  Registrant: Robert Smith
  Organization: Tereda Electric LLC
  Email: robert@teredaelectric.com

MANAGED BY:                   ZAFTO (via Cloudflare)
───────────────────────────────────────────
The domain lives in ZAFTO's Cloudflare account
We control DNS, SSL, renewals
Customer never logs into anything

IF CUSTOMER LEAVES ZAFTO:
─────────────────────────
They legally own the domain. We MUST transfer it to them.
Process:
1. Customer requests transfer
2. We unlock domain via Cloudflare API
3. We send auth code to customer
4. Customer transfers to their own registrar
5. Done. No hostage situation.

THIS IS ETHICAL AND CORRECT.
We manage it, they own it.
```

### Auto-Renewal Flow

```
DAY -30:  Push notification + email
          "Your domain teredaelectric.com renews in 30 days ($14.99)"
          [Auto-renew is ON ✓]

DAY -7:   Reminder if auto-renew is OFF
          "Your domain expires in 7 days! Enable auto-renew?"

DAY -1:   Charge card via Stripe
          Call Cloudflare API to confirm renewal
          Email receipt

DAY 0:    Domain renewed. Customer did nothing. Site stays up.

IF PAYMENT FAILS:
─────────────────
- Retry 3x over 7 days
- Email + SMS warnings
- Site stays up during grace period (Cloudflare gives ~30 days)
- If still unpaid, domain falls back to subdomain (site doesn't die)
- Domain enters redemption period (customer can still recover)
```

### Cloudflare API Endpoints We Use

```
POST /registrar/domains/check     → Check if domain available
POST /registrar/domains           → Purchase domain
GET  /zones/{id}/dns_records      → Manage DNS
POST /zones/{id}/dns_records      → Add records
PUT  /registrar/domains/{id}      → Update settings
POST /registrar/domains/{id}/unlock → Unlock for transfer

PRICING (at-cost from Cloudflare):
.com = $9.15/year
.net = $10.11/year
.org = $9.93/year
.co  = $11.31/year

WE CHARGE: $14.99/year (domain) + $19.99/mo (hosting/builder)
OUR MARGIN: ~$5/year on domain + $19.99/mo recurring
```

### Domain Tiers

| Tier | Domain | Monthly | What They Get |
|------|--------|:-------:|---------------|
| **Free** | yourcompany.zafto.cloud | $0 | Subdomain, full website features |
| **Pro** | teredaelectric.com | $19.99 | Custom domain, purchased through ZAFTO |

---

## TEMPLATE PHILOSOPHY: STRICT BY DESIGN (LOCKED)

### Why Strict Templates

```
WIX/SQUARESPACE APPROACH:
─────────────────────────
"Here's a blank canvas! Drag things around! Be creative!"

RESULT:
• Logo stretched weird
• 17 different fonts
• Colors that clash
• Phone number hidden at the bottom
• Stock photos of smiling people in suits (for a plumber)
• "Welcome to our website" as headline
• Wall of text nobody reads
• Looks like it was built in 2009

WHY: Contractors aren't designers. Too much freedom = bad decisions.
```

### The ZAFTO Approach

```
WHAT'S LOCKED (User cannot change):          WHAT'S FLEXIBLE (User controls):
─────────────────────────────────            ────────────────────────────────
• Layout structure                           • Logo (upload or create)
• Typography hierarchy                       • Brand colors (from palette)
• Spacing/padding                            • Photos (their work)
• Mobile responsiveness                      • Copy (AI writes, they edit)
• Section order (mostly)                     • Services listed
• CTA button placement                       • Contact info
• Navigation structure                       • Service areas
• Footer layout                              • Which sections to show/hide

RESULT: Every site looks professional. Impossible to make it ugly.
```

### Quality Bar

**These templates should look like a $10,000 agency built them.**

Not "good for DIY." Not "pretty good for the price."

**Legitimately impressive.** The kind of site where the contractor's competitor sees it and thinks "who did they hire?"

---

## AI TEMPLATE ASSISTANT (LOCKED)

### Concept

Claude is trained on every single template. Knows:
- Every template's structure
- What's safe to modify
- What will break
- Alternative templates that solve the user's actual need
- Color theory, typography rules, accessibility requirements

### Example Interactions

```
USER: "I want my phone number to be bigger and at the top"

AI KNOWS:
• This template (BOLT_MODERN_DARK)
• Phone is in header, right side, 18px
• Safe to increase to 22px, add to sticky header
• WON'T break mobile, WON'T break layout

AI DOES: Makes the change. Shows preview. "How's this?"
```

```
USER: "I want a completely different layout for my services"

AI KNOWS:
• Current template has 3-column service grid
• User wants something different
• Template CIRCUIT_MINIMAL has a list layout
• Template WATTS_BOLD has a card carousel

AI RESPONDS: "I can't change the layout within this template — it would
break the design. But check out these alternatives:"
[Shows previews of templates with different service layouts]
"Want to switch? Your content will transfer automatically."
```

```
USER: "The orange is too bright"

AI KNOWS:
• Template uses #FF6B00 (Safety Orange)
• Color palette has 5 orange variants
• Can swap to #E85D04 (deeper orange) without breaking contrast ratios

AI DOES: Shows all 5 variants. User picks. Done.
```

### What AI Prevents

- Breaking mobile layout
- Breaking accessibility (contrast, font size)
- Color combinations that clash
- Typography that doesn't work
- "I changed one thing and now it looks terrible"

---

## DATA FLOW: CRM ↔ WEBSITE (LOCKED)

### Two Paths, One Experience

```
PATH A: NEW USER (No CRM Data Yet)          PATH B: EXISTING USER (Has Data)
─────────────────────────────────           ──────────────────────────────────

Questionnaire collects:                     Auto-pull from CRM:
• Company name, phone, email                • Company profile
• Trade(s) offered                          • Services from Price Book
• Services (checklist)                      • Team from HR/Employees
• Service area (zip codes)                  • Portfolio from Job Photos
• Years in business                         • Reviews from Google sync
• License numbers                           • Certifications from HR
• "Tell us about your company"              • Service areas from Jobs map

Opus generates content from answers         Opus generates from REAL data

                      ↓                                     ↓
                      └──────────────┬──────────────────────┘
                                     ▼
                           SAME OUTPUT: Website
```

### Live Sync (Once CRM Has Data)

```
┌─────────────────┐         ┌─────────────────┐
│ Add service to  │ ──────► │ Service appears │  (if auto-sync on)
│ Price Book      │         │ on website      │
└─────────────────┘         └─────────────────┘

┌─────────────────┐         ┌─────────────────┐
│ New team member │ ──────► │ Team page       │  (if auto-sync on)
│ in HR           │         │ updates         │
└─────────────────┘         └─────────────────┘

┌─────────────────┐         ┌─────────────────┐
│ Tech marks photo│ ──────► │ Owner/Admin     │  (notification)
│ "website ☆"    │         │ reviews + ✅    │
└─────────────────┘         └─────────────────┘
                                    │
                            ┌───────▼─────────┐
                            │ Portfolio adds  │  (if approved + auto-sync on)
                            │ the image       │
                            └─────────────────┘

┌─────────────────┐         ┌─────────────────┐
│ Get new Google  │ ──────► │ Reviews section │  (if approved)
│ review          │         │ updates         │
└─────────────────┘         └─────────────────┘

User controls: "Auto-sync" toggle per section, or manual "Publish Changes"
```

---

## COMPETITIVE POSITIONING (LOCKED)

### Price Comparison

**Generic Website Builders:**
| Platform | Price | What You Get |
|----------|:-----:|--------------|
| Wix | $16-45/mo | Generic drag-drop. No CRM. No trade knowledge. |
| Squarespace | $16-49/mo | Pretty templates. No CRM. No trade knowledge. |
| GoDaddy Builder | $10-25/mo | Garbage templates. No CRM. Upsells everywhere. |
| Weebly | $10-26/mo | Basic. No CRM. No trade knowledge. |

**Contractor-Specific:**
| Platform | Price | What You Get |
|----------|:-----:|--------------|
| Jobber | $69+/mo | Basic site included. Their CRM. Locked in. |
| Housecall Pro | $49+/mo | Basic site included. Their CRM. Locked in. |
| Contractor Gorilla | $99/mo | Templates. No CRM integration. |
| Footbridge Media | $199/mo | "Done for you." Still no live CRM sync. |
| Agencies | $500-2000/mo | Agency builds it. Static. No data sync. |

**ZAFTO: $19.99/mo**

### Feature Comparison

```
FEATURE                              ZAFTO    WIX    JOBBER   AGENCIES
───────────────────────────────────  ─────    ───    ──────   ────────
AI-generated trade-specific copy      ✅       ❌      ❌        ❌
40 trade-specific templates           ✅       ❌      ❌        ❌
Logo creator built-in                 ✅       ❌      ❌        ❌

LIVE CRM SYNC:
Services from Price Book → Site       ✅       ❌      ❌        ❌
Team from HR → Site                   ✅       ❌      ❌        ❌
Job Photos → Portfolio auto           ✅       ❌      ❌        ❌
Google Reviews → Site                 ✅       ❌      ❌        ❌
Certifications → Site                 ✅       ❌      ❌        ❌

LEAD CAPTURE:
Contact form → CRM Lead               ✅       ❌      ✅        ❌
Lead → Bid → Job → Invoice pipeline   ✅       ❌      ✅        ❌
Which page generated which lead       ✅       ❌      ❌        ❌
Lead → Actual revenue attribution     ✅       ❌      ❌        ❌

BOOKING:
Online booking widget                 ✅       ❌      ✅        ❌
→ Syncs to dispatch/calendar          ✅       ❌      ✅        ❌
→ Shows REAL tech availability        ✅       ❌      ❌        ❌

SEO:
Auto-generated service area pages     ✅       ❌      ❌        ⚠️ Manual
Schema markup for contractors         ✅       ❌      ❌        ⚠️ Manual
AI blog content by trade              ✅       ❌      ❌        ⚠️ $$$

DOMAIN:
Subdomain free                        ✅       ✅      ✅        ❌
Custom domain (no external account)   ✅       ❌      ❌        ❌
Zero DNS knowledge required           ✅       ❌      ❌        ✅

PRICE                                $19.99   $27+   $69+     $500+
```

### The Killer Differentiator

```
COMPETITOR REALITY:
──────────────────
Contractor has Wix site
Contact form comes in → goes to email
Contractor manually enters lead in CRM
Contractor manually updates site when services change
Contractor manually uploads photos
Contractor has no idea which page generated which customer
Two systems. Constant manual sync. Data gaps everywhere.

ZAFTO REALITY:
─────────────
Contractor has ZAFTO site
Contact form comes in → LEAD IN CRM (auto)
Lead → Bid → Job → Invoice (tracked)
Add service to Price Book → SITE UPDATES (auto)
Mark job photo "portfolio" → SITE UPDATES (auto)
Complete job → Ask for review → SITE UPDATES (auto)
One system. Zero manual sync. Complete data picture.

"This lead from the EV Charger page became a $4,200 job."
← Nobody else can tell you that.
```

---

## TEMPLATE RESEARCH METHODOLOGY (LOCKED)

### Research Tiers

```
TIER 1: Premium Contractor Sites ($50k+ builds)
───────────────────────────────────────────────
• Large electrical/HVAC companies
• Multi-location contractors
• What do they have that works?
• Service area pages, team pages, project galleries
• How do they handle trust signals?

TIER 2: Mid-Market Sites (Agency-built, $5-15k)
───────────────────────────────────────────────
• Regional contractors with real marketing
• What elements convert?
• CTA placement, form design, mobile experience

TIER 3: Best DIY Sites (Rare but exist)
───────────────────────────────────────
• Contractors who figured it out themselves
• What did they get right by accident?

TIER 4: Garbage Sites (Learn what NOT to do)
────────────────────────────────────────────
• The "my nephew built it" disasters
• Common mistakes to prevent in our templates
```

### Research By Trade

```
• Electrical (commercial vs residential feel different)
• Plumbing (emergency focus vs planned work)
• HVAC (seasonal, comfort messaging)
• Solar (ROI calculators, environmental angle)
• Roofing (storm damage, insurance, trust)
• GC (portfolio-heavy, project galleries)
• Remodeler (before/after is everything)
• Landscaping (visual, seasonal, outdoor imagery)
```

### 5 Style Archetypes

```
1. Bold/Industrial (dark, strong, masculine)
2. Clean/Professional (light, minimal, trust)
3. Modern/Tech (sleek, innovative, premium)
4. Warm/Friendly (approachable, family-owned feel)
5. Premium/Luxury (high-end, affluent markets)

Each trade gets templates in 2-3 of these styles.
```

---

## TEMPLATE DEVELOPMENT PROCESS (LOCKED)

```
PHASE 1: Research (Robert + Claude)
────────────────────────────────────
• Pull 50-100 real contractor websites
• Categorize by trade, quality tier, style
• Identify patterns that work
• Document the "rules" (what makes these good?)

PHASE 2: Template Specs (Robert + Claude)
─────────────────────────────────────────
• Define sections for each template
• Spec out every element, every interaction
• Mobile-first design requirements
• Accessibility requirements

PHASE 3: Wireframes (Robert + Claude)
─────────────────────────────────────
• Layout each template page by page
• Desktop AND mobile
• Define the "bones" before any visual design

PHASE 4: Visual Design
──────────────────────
• Apply visual treatment to wireframes
• Color palettes per trade
• Typography pairings
• Icon sets, button styles, form designs

PHASE 5: Build (Code)
─────────────────────
• HTML/Tailwind templates
• Mustache/Handlebars variables for content injection
• Mobile-responsive, accessibility compliant
• Performance optimized

PHASE 6: AI Training
────────────────────
• Train Claude on every template's structure
• What's modifiable, what's locked
• Common user requests and how to handle them
• Edge cases and guardrails
```

---

## FEATURES TO BUILD (LOCKED)

### Core Website Builder
- [ ] Template selection UI
- [ ] Logo creator (from Doc 20)
- [ ] Website creation questionnaire
- [ ] Opus content generation
- [ ] Preview system
- [ ] Publish flow
- [ ] Website editor in CRM

### Domain Management
- [ ] Domain search UI
- [ ] Cloudflare Registrar API integration
- [ ] Domain purchase flow
- [ ] DNS auto-configuration
- [ ] SSL auto-provisioning
- [ ] Domain renewal billing
- [ ] Transfer out flow

### CRM Data Sync
- [ ] Services sync from Price Book
- [ ] Team sync from HR/Employees
- [ ] Portfolio sync from Job Photos (**approval-gated** — see Photo Management System section)
- [ ] Reviews sync from Google
- [ ] Certifications sync from HR
- [ ] Auto-sync toggles per section
- [ ] Manual publish option

### AI Template Assistant
- [ ] Template-aware Claude integration
- [ ] Safe modification detection
- [ ] Template switching with content transfer
- [ ] Color palette management
- [ ] Edge case handling

### Lead Capture
- [ ] Contact form → CRM Lead
- [ ] Source attribution (which page)
- [ ] Lead → Bid → Job → Invoice tracking
- [ ] Revenue attribution

### SEO
- [ ] Service area page generation
- [ ] Schema markup for contractors
- [ ] Meta tags auto-generation
- [ ] Sitemap generation
- [ ] AI blog content engine

### Booking Integration
- [ ] Online booking widget
- [ ] Calendar/dispatch sync
- [ ] Real-time availability
- [ ] Confirmation flow

### Analytics
- [ ] Traffic dashboard
- [ ] Lead conversion tracking
- [ ] Revenue attribution
- [ ] Source analysis

---

## CRM WEBSITE MANAGER TAB

### This Is Not a Separate Product

```
The Website Builder creates the site.
The CRM Website Manager TAB runs it day-to-day.

Owner/Secretary/Office Manager opens CRM → clicks "Website" tab →
manages EVERYTHING about their live site without ever leaving ZAFTO.

This is where the magic happens. The website isn't a "set it and forget it" thing.
It's a living extension of their business that they control from the same place
they manage jobs, invoices, and customers.
```

### Website Manager Tab Layout

```
CRM → WEBSITE TAB

┌──────────────────────────────────────────────────────────────────────────┐
│  🌐 Website Manager                              [View Live Site ↗]    │
│                                                                         │
│  ┌──────┬──────────┬────────┬───────┬──────┬──────────┬──────────────┐ │
│  │Photos│Promotions│AI Chat │Content│ SEO  │Analytics │  Settings    │ │
│  └──────┴──────────┴────────┴───────┴──────┴──────────┴──────────────┘ │
│                                                                         │
│  [Currently viewing: Photos]                                            │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                                                                  │  │
│  │  (Sub-tab content renders here)                                  │  │
│  │                                                                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  Quick Stats:                                                           │
│  Visitors: 342 this month  │  Leads: 12  │  Revenue: $18,400          │
│                                                                         │
└──────────────────────────────────────────────────────────────────────────┘

SUB-TABS:
─────────
PHOTOS       → Full Photo Manager (see Photo Management System section)
PROMOTIONS   → Seasonal banners, specials, scheduled campaigns
AI CHAT      → Bot configuration, knowledge control, conversation history
CONTENT      → Edit pages, services, about, team, legal pages
SEO          → Meta tags, service area pages, blog, sitemap
ANALYTICS    → Traffic, leads, revenue attribution, source tracking
SETTINGS     → Domain, email, colors, template, sync toggles, trust badges
```

### RBAC: Website Manager Permissions

```
ACTION                              OWNER    ADMIN    OFFICE    TECH
──────────────────────────────      ─────    ─────    ──────    ────
View website analytics                ✅       ✅       ✅        ❌
Edit website content/pages            ✅       ✅       ✅        ❌
Manage photos (approve/reject)        ✅       ✅       ✅        ❌
Create/edit promotions                ✅       ✅       ✅        ❌
Configure AI chat bot                 ✅       ✅       ❌        ❌
Change template/colors/branding       ✅       ✅       ❌        ❌
Manage domain/email settings          ✅       ❌       ❌        ❌
View AI chat conversations            ✅       ✅       ✅        ❌
Publish changes to live site          ✅       ✅       ✅        ❌
Manage SEO/blog content               ✅       ✅       ✅        ❌
Edit legal pages                      ✅       ❌       ❌        ❌
Toggle Price Book visibility          ✅       ✅       ❌        ❌
```

---

## AI WEBSITE CHAT WIDGET

### The Concept

```
NOT a generic chatbot. NOT a scripted FAQ.

This is Claude — with access to THIS CONTRACTOR'S actual business data.

Homeowner lands on website. Chat bubble in corner.
"Do you install EV chargers?"
→ AI checks Price Book → "Yes! We offer Level 2 and DC fast charger installation.
   Would you like a free estimate?"

"Are you licensed in Connecticut?"
→ AI checks company profile → "Yes, we hold CT E-1 License #ELC.0123456,
   fully insured with $2M liability coverage."

"What areas do you serve?"
→ AI checks service areas → "We serve all of Fairfield County including
   Stamford, Greenwich, Norwalk, and Danbury."

"How much does a panel upgrade cost?"
→ AI checks Price Book visibility settings → BLOCKED
→ "Panel upgrades vary by project. I'd love to get you a free estimate!
   Can I grab your name and phone number?"

The chat captures the lead. Name, email, phone, what they need.
Straight into CRM as a website lead with source attribution.
```

### The Critical Part: CONTRACTOR CONTROLS EVERYTHING

```
This is the #1 design requirement. The contractor must have FULL control
over what the AI does and doesn't share. Period.

A plumber might be fine showing prices. An electrician might not.
A GC might want the bot to push toward estimates. A roofer might want
it to push toward inspections. Every business is different.

THE AI DOES NOT DECIDE WHAT TO SHARE. THE CONTRACTOR DECIDES.
```

### AI Chat Configuration Panel (CRM → Website → AI Chat)

```
┌──────────────────────────────────────────────────────────────────────┐
│  🤖 Website AI Chat Configuration                                    │
│                                                                      │
│  MASTER TOGGLE                                                       │
│  AI Chat Widget: [ON ▾]                                             │
│  ☐ Show on all pages  ☑ Show on specific pages: [Services, Contact] │
│                                                                      │
│  ─────────────────────────────────────────────────────────────────── │
│                                                                      │
│  📋 KNOWLEDGE SOURCES                                               │
│  What can the AI access and share?                                   │
│                                                                      │
│  ┌────────────────────────┬─────────┬────────────────────────────┐  │
│  │ Source                 │ Enabled │ Notes                       │  │
│  ├────────────────────────┼─────────┼────────────────────────────┤  │
│  │ Company name/phone     │  ✅ ON  │ Always on (it's your site) │  │
│  │ Services offered       │  ✅ ON  │ From Price Book             │  │
│  │ Service areas          │  ✅ ON  │ From company profile        │  │
│  │ Business hours         │  ✅ ON  │ From company profile        │  │
│  │ Licenses/certs         │  ✅ ON  │ From HR module              │  │
│  │ Insurance coverage     │  ✅ ON  │ From HR module              │  │
│  │ Years in business      │  ✅ ON  │ From company profile        │  │
│  │ Team/staff names       │  ⚠️ OFF │ Some don't want this public│  │
│  │ PRICES (Price Book)    │  ⚠️ OFF │ DEFAULT OFF — opt-in only  │  │
│  │ Availability/schedule  │  ⚠️ OFF │ From calendar               │  │
│  │ Job history/portfolio  │  ☐ OFF  │ What past work to mention   │  │
│  │ Google reviews         │  ✅ ON  │ Public anyway               │  │
│  └────────────────────────┴─────────┴────────────────────────────┘  │
│                                                                      │
│  ─────────────────────────────────────────────────────────────────── │
│                                                                      │
│  💰 PRICE VISIBILITY (if Prices toggle is ON)                       │
│                                                                      │
│  ☐ Show all prices from Price Book                                   │
│  ☑ Show only these categories:                                       │
│    ☑ Maintenance/tune-ups                                            │
│    ☐ Installations (hide — want in-person estimate)                  │
│    ☐ Emergency services (hide — varies too much)                     │
│    ☑ Inspections                                                     │
│                                                                      │
│  Price display mode:                                                 │
│  ○ Exact prices ("Panel upgrade: $2,800")                           │
│  ☑ Ranges ("Panel upgrades typically $2,500 – $4,000")              │
│  ○ Starting at ("Panel upgrades starting at $2,500")                │
│                                                                      │
│  ─────────────────────────────────────────────────────────────────── │
│                                                                      │
│  🎯 BEHAVIOR SETTINGS                                               │
│                                                                      │
│  Primary goal:                                                       │
│  ○ Answer questions (informational)                                  │
│  ☑ Capture leads (push toward booking/estimate)                     │
│  ○ Both equally                                                      │
│                                                                      │
│  When AI can't answer:                                               │
│  ☑ "I'd recommend calling us at (203) 555-1234"                    │
│  ○ "Let me get your info and we'll call you back"                   │
│  ○ Both options                                                      │
│                                                                      │
│  Lead capture asks for:                                              │
│  ☑ Name   ☑ Phone   ☑ Email   ☐ Address   ☑ What they need        │
│                                                                      │
│  Tone:                                                               │
│  ○ Professional/formal                                               │
│  ☑ Friendly/casual                                                   │
│  ○ Direct/efficient                                                  │
│                                                                      │
│  ─────────────────────────────────────────────────────────────────── │
│                                                                      │
│  🚫 CUSTOM RULES (Contractor types their own rules)                 │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ • Never quote prices for emergency work                      │   │
│  │ • Always mention we offer free estimates                     │   │
│  │ • If someone asks about solar, say we're adding it Q3 2026  │   │
│  │ • Don't mention we do residential — commercial only          │   │
│  │ • Always ask for their address early in the conversation     │   │
│  │ • Mention our A+ BBB rating if trust comes up               │   │
│  │                                                              │   │
│  │ [+ Add rule]                                                 │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ─────────────────────────────────────────────────────────────────── │
│                                                                      │
│  💬 CONVERSATION HISTORY                                            │
│                                                                      │
│  [View All Conversations (47 this month)]                            │
│                                                                      │
│  Recent:                                                             │
│  • "EV charger install" — John D. — Feb 5, 2:14pm — ✅ Lead captured │
│  • "Do you serve Norwalk" — Sarah — Feb 5, 11:02am — ❌ No lead    │
│  • "Panel upgrade cost" — Mike R. — Feb 4, 4:30pm — ✅ Lead captured│
│                                                                      │
│  [Export conversations]  [Clear history]                              │
│                                                                      │
│  ─────────────────────────────────────────────────────────────────── │
│                                                                      │
│  📊 AI CHAT ANALYTICS                                               │
│                                                                      │
│  This month:                                                         │
│  Conversations: 47  │  Leads captured: 12  │  Conversion: 25.5%     │
│  Top question: "What areas do you serve?" (asked 14 times)           │
│  Questions AI couldn't answer: 3 (see unanswered log)                │
│                                                                      │
│  [View unanswered questions]  ← Add answers to improve the bot      │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### AI Chat: How It Actually Works Under The Hood

```
ARCHITECTURE:

Website visitor types message
       │
       ▼
Supabase Edge Function: websiteChatMessage
       │
       ▼
Build Claude prompt from:
  1. System instructions (tone, goal, rules)
  2. Company data (filtered by contractor's toggle settings)
  3. Custom rules (contractor's own instructions)
  4. Conversation history (this session)
  5. "You are a helpful assistant for {Company Name}..."
       │
       ▼
Claude API → Response
       │
       ▼
Response sent to visitor + stored in chat_sessions table
       │
       ▼
If lead info captured → create website_leads record → notify contractor

CRITICAL: The Edge Function checks toggle settings BEFORE building the prompt.
If "Prices" is OFF, price data is NEVER sent to Claude. Not "hidden" — ABSENT.
Claude can't leak what it doesn't have.
```

### AI Chat: Lead Capture Flow

```
VISITOR: "How much for a panel upgrade?"

AI (Prices OFF): "Panel upgrades depend on your current panel, service
capacity, and any code requirements. We offer free on-site estimates!
Would you like to schedule one?"

VISITOR: "Yeah sure"

AI: "Great! Can I get your name and phone number so we can set that up?"

VISITOR: "Mike Reynolds, 203-555-8901"

AI: "Perfect, Mike! We'll reach out within one business day to schedule
your free panel estimate. Is there anything else I can help with?"

BEHIND THE SCENES:
→ CRM Lead created:
  - Name: Mike Reynolds
  - Phone: 203-555-8901
  - Source: Website AI Chat
  - Source page: /services/electrical
  - Interest: Panel upgrade
  - Chat transcript attached
→ Push notification to Owner/Admin: "New lead from website chat: Mike Reynolds"
→ If auto-assign rules exist: Lead assigned to next available tech
```

### Database Schema Addition

```sql
-- AI Chat configuration per company
CREATE TABLE website_chat_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) UNIQUE,
  
  -- Master toggle
  enabled BOOLEAN DEFAULT false,
  show_on_pages TEXT[] DEFAULT ARRAY['all'],  -- ['all'] or ['/services', '/contact']
  
  -- Knowledge source toggles
  share_services BOOLEAN DEFAULT true,
  share_service_areas BOOLEAN DEFAULT true,
  share_hours BOOLEAN DEFAULT true,
  share_licenses BOOLEAN DEFAULT true,
  share_insurance BOOLEAN DEFAULT true,
  share_years BOOLEAN DEFAULT true,
  share_team_names BOOLEAN DEFAULT false,
  share_prices BOOLEAN DEFAULT false,
  share_availability BOOLEAN DEFAULT false,
  share_portfolio BOOLEAN DEFAULT false,
  share_reviews BOOLEAN DEFAULT true,
  
  -- Price visibility (if share_prices = true)
  price_categories TEXT[],           -- which categories to show
  price_display_mode TEXT DEFAULT 'range',  -- 'exact', 'range', 'starting_at'
  
  -- Behavior
  primary_goal TEXT DEFAULT 'capture_leads',  -- 'informational', 'capture_leads', 'both'
  fallback_action TEXT DEFAULT 'suggest_call',
  lead_capture_fields TEXT[] DEFAULT ARRAY['name', 'phone', 'email', 'need'],
  tone TEXT DEFAULT 'friendly',  -- 'professional', 'friendly', 'direct'
  
  -- Custom rules (contractor's own instructions)
  custom_rules TEXT[],              -- array of rule strings
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Chat sessions
CREATE TABLE website_chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  
  visitor_id TEXT,                   -- anonymous session ID
  source_page TEXT,                  -- which page chat started on
  messages JSONB NOT NULL DEFAULT '[]',  -- [{role, content, timestamp}]
  
  -- Lead capture
  lead_captured BOOLEAN DEFAULT false,
  lead_id UUID REFERENCES website_leads(id),
  visitor_name TEXT,
  visitor_email TEXT,
  visitor_phone TEXT,
  visitor_need TEXT,
  
  -- Analytics
  message_count INTEGER DEFAULT 0,
  started_at TIMESTAMPTZ DEFAULT now(),
  ended_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: company_id isolation
```

---

## PROFESSIONAL EMAIL (Cloudflare Email Routing)

### The Problem

```
Contractor buys custom domain through ZAFTO: powerslandscaping.com
Their email: powerslandscaping@gmail.com

That's embarrassing. And it's a missed branding opportunity.
```

### The Solution: Free Email Forwarding

```
Cloudflare Email Routing is FREE. We already own the DNS.
One MX record + one routing rule. Done.

WHAT CONTRACTOR GETS:
info@powerslandscaping.com     → forwards to their Gmail
billing@powerslandscaping.com  → forwards to their Gmail
support@powerslandscaping.com  → forwards to their Gmail

They RECEIVE email at the professional address.
They REPLY from Gmail (with "Send As" configured — one-time setup).
Or they just reply from Gmail and nobody cares.

COST TO US: $0
COST TO THEM: $0
VALUE: Enormous. Professional email is the first thing customers judge.
```

### Setup Flow (CRM → Website → Settings → Email)

```
┌────────────────────────────────────────────────────────────────┐
│  📧 Professional Email                                         │
│                                                                │
│  Your domain: powerslandscaping.com                            │
│                                                                │
│  Email addresses:                                              │
│  ┌─────────────────────────────────┬───────────────────────┐  │
│  │ Professional Address            │ Forwards To           │  │
│  ├─────────────────────────────────┼───────────────────────┤  │
│  │ info@powerslandscaping.com      │ mike@gmail.com        │  │
│  │ billing@powerslandscaping.com   │ sarah@gmail.com       │  │
│  │ jobs@powerslandscaping.com      │ mike@gmail.com        │  │
│  └─────────────────────────────────┴───────────────────────┘  │
│                                                                │
│  [+ Add email address]                                         │
│                                                                │
│  Suggested addresses:                                          │
│  [+ info@]  [+ billing@]  [+ support@]  [+ jobs@]            │
│                                                                │
│  ───────────────────────────────────────────────────────────── │
│  💡 These addresses forward to your existing email.            │
│  Customers see info@powerslandscaping.com — you receive it     │
│  in your regular inbox.                                        │
│                                                                │
│  Want to SEND from your professional address?                  │
│  [Setup guide for Gmail "Send As" →]                           │
│  [Setup guide for Outlook →]                                   │
└────────────────────────────────────────────────────────────────┘
```

### Technical Implementation

```
BEHIND THE SCENES:

1. When custom domain is purchased, auto-create:
   - info@domain.com → company's primary email
   - MX record: route1.mx.cloudflare.net (priority 86)
   - MX record: route2.mx.cloudflare.net (priority 11)
   - TXT record: SPF for Cloudflare

2. Cloudflare API calls:
   POST /zones/{zone_id}/email/routing/rules
   {
     "name": "info forward",
     "enabled": true,
     "matchers": [{ "type": "literal", "field": "to", "value": "info@domain.com" }],
     "actions": [{ "type": "forward", "value": ["owner@gmail.com"] }]
   }

3. Optional: Catch-all rule (anything@domain.com → owner's email)

COST: $0 (included in Cloudflare free tier)
SETUP TIME: ~2 seconds (API call during domain purchase)
```

---

## LEGAL PAGES (Auto-Generated)

### The Problem

```
Every business website legally needs:
• Privacy Policy
• Terms of Service/Use

Most contractors don't have these. At all.
Some have copy-pasted ones from random websites that reference the wrong company.
Some have ones from 2015 that don't mention GDPR, CCPA, or modern requirements.

ZAFTO generates them automatically from company data.
```

### Auto-Generated Legal Pages

```
GENERATED AT WEBSITE CREATION:

1. PRIVACY POLICY
   - Company name, address, contact info (from profile)
   - What data is collected (contact forms, cookies, analytics)
   - How data is used
   - Third-party services (Google Analytics, Stripe)
   - Cookie policy
   - State-specific requirements:
     * California: CCPA disclosure
     * Connecticut: CTDPA disclosure
     * Other states as laws pass
   - Data retention, deletion rights
   - Contact for privacy questions

2. TERMS OF SERVICE
   - Company info
   - Service descriptions (from Price Book)
   - Liability limitations
   - Dispute resolution
   - Payment terms (if online booking/payment enabled)
   - Intellectual property
   - Cancellation/refund policy

3. ACCESSIBILITY STATEMENT (Optional but recommended)
   - WCAG 2.1 AA compliance statement
   - Contact for accessibility issues
   - Known limitations (if any)

AUTO-UPDATE: When company data changes, legal pages regenerate.
Contractor reviews and approves changes before publishing.
```

### How Opus Generates Legal Pages

```
INPUT (auto-pulled from CRM):
- Company legal name, EIN state, address
- State of incorporation (determines which privacy laws apply)
- Services offered (from Price Book)
- Whether online payments are accepted
- Whether booking widget is enabled
- What data is collected (forms, chat, analytics)
- Third-party services used

OUTPUT:
- Professional, legally-structured privacy policy
- Professional terms of service
- Plain English summaries (not just legalese)

DISCLAIMER: Footer note on all legal pages:
"This policy was auto-generated and should be reviewed by a legal professional.
ZAFTO is not a law firm and this does not constitute legal advice."
```

---

## TRUST BADGES & CREDENTIALS

### Auto-Pulled From CRM Data

```
CRM → Website → Settings → Trust Badges

┌──────────────────────────────────────────────────────────────────┐
│  🏅 Trust Badges & Credentials                                   │
│                                                                  │
│  AUTO-DETECTED FROM YOUR DATA:                                   │
│  ┌────────────────────────────────────────────┬────────┐        │
│  │ Badge                                      │ Show?  │        │
│  ├────────────────────────────────────────────┼────────┤        │
│  │ ⚡ Licensed Electrician (CT E-1 #0123456) │  ✅    │        │
│  │ 🛡️ Insured ($2M General Liability)        │  ✅    │        │
│  │ ⭐ 4.9★ Rating (127 Google Reviews)       │  ✅    │        │
│  │ 📅 Established 2015 (11 Years)            │  ✅    │        │
│  │ 👷 5 Licensed Technicians                 │  ✅    │        │
│  │ 🏆 Master Electrician Certified           │  ☐     │        │
│  └────────────────────────────────────────────┴────────┘        │
│                                                                  │
│  MANUAL BADGES (upload logo/image):                              │
│  ┌────────────────────────────────────────────┬────────┐        │
│  │ Badge                                      │ Show?  │        │
│  ├────────────────────────────────────────────┼────────┤        │
│  │ BBB A+ Accredited                         │  ✅    │        │
│  │ NECA Member                               │  ✅    │        │
│  │ Angi Super Service Award 2025             │  ☐     │        │
│  │ [+ Add badge]                             │        │        │
│  └────────────────────────────────────────────┴────────┘        │
│                                                                  │
│  DISPLAY:                                                        │
│  ☑ Show in website header bar                                    │
│  ☑ Show on homepage hero section                                 │
│  ☑ Show on contact/estimate page                                 │
│  ☐ Show on every page footer                                     │
│                                                                  │
│  Preview: [Licensed & Insured] [4.9★ 127 Reviews] [Est. 2015]  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

DATA SOURCES:
- License numbers → License/Insurance module (HR)
- Insurance coverage → Insurance module (HR)
- Star rating + review count → Google Business sync
- Years in business → Company profile (created year)
- Team size → Employee count from HR
- Certifications → Certification module (HR)

AUTO-UPDATE: When license renews, review count changes, or new cert
is added, trust badges update automatically (if auto-sync on).
```

---

## SERVICE AREA MAP

### Interactive Map on Website

```
Homeowner lands on site → immediately sees "Yes, they serve my area."

MAP SOURCES (auto-generated, no manual entry):
1. Zip codes from company profile (primary)
2. GPS data from completed jobs (secondary — shows actual coverage)
3. Manual override: contractor adds/removes specific areas

MAP DISPLAY:
- Shaded region showing service area
- Pin for office/shop location
- Interactive: homeowner can enter their zip and get instant yes/no
```

### Service Area Page Generation (SEO)

```
For each city/town in service area, auto-generate a page:

powerslandscaping.com/service-areas/stamford-ct/
powerslandscaping.com/service-areas/greenwich-ct/
powerslandscaping.com/service-areas/norwalk-ct/

EACH PAGE CONTAINS:
- "{Company} in {City}, {State}" heading
- AI-generated content specific to that city
- Services offered with local context
- Map showing coverage in that area
- Contact form with city pre-filled
- Schema markup (LocalBusiness + Service + AreaServed)

WHY: These pages rank for "[trade] in [city]" searches.
"Electrician in Stamford CT" — that's how homeowners search.
Every service area page is a new chance to rank in Google.

AUTO-GENERATED: Opus writes unique content per city (no duplicate content penalty).
AUTO-UPDATED: New city added to service area → new page generated.
```

### Configuration (CRM → Website → SEO → Service Areas)

```
┌────────────────────────────────────────────────────────────────┐
│  📍 Service Area Pages                                         │
│                                                                │
│  Auto-generate city pages: [ON ▾]                              │
│                                                                │
│  Service area source:                                          │
│  ☑ From company profile zip codes                              │
│  ☑ From completed job locations                                │
│  ☐ Manual only                                                 │
│                                                                │
│  Generated pages (23):                                         │
│  ✅ Stamford, CT          /service-areas/stamford-ct/          │
│  ✅ Greenwich, CT         /service-areas/greenwich-ct/         │
│  ✅ Norwalk, CT           /service-areas/norwalk-ct/           │
│  ✅ Danbury, CT           /service-areas/danbury-ct/           │
│  ⏳ New Canaan, CT        [Generating...]                      │
│  ...                                                           │
│                                                                │
│  [+ Add city manually]  [Regenerate all]  [Preview any page]  │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## PAY YOUR INVOICE (Online Payment Portal)

### The Flow

```
CONTRACTOR SENDS INVOICE (from ZAFTO invoicing)
       │
       ▼
CLIENT GETS EMAIL:
"You have a new invoice from Powers Landscaping"
[View & Pay Invoice →]
       │
       ▼
LANDS ON: powerslandscaping.com/pay/INV-2026-0142
       │
       ▼
┌─────────────────────────────────────────────────┐
│  POWERS LANDSCAPING                              │
│                                                  │
│  Invoice #INV-2026-0142                         │
│  Date: February 5, 2026                          │
│                                                  │
│  Kitchen remodel — final payment                 │
│                                                  │
│  ┌──────────────────────────────────────┐       │
│  │ Labor                    $3,200.00   │       │
│  │ Materials                $1,847.50   │       │
│  │ Permit fees              $  250.00   │       │
│  │ ──────────────────────────────────── │       │
│  │ Total                    $5,297.50   │       │
│  │ Deposit paid            -$1,500.00   │       │
│  │ ══════════════════════════════════   │       │
│  │ AMOUNT DUE               $3,797.50   │       │
│  └──────────────────────────────────────┘       │
│                                                  │
│  [Pay with Card]  [Pay with Bank (ACH)]         │
│                                                  │
│  Powered by Stripe │ Secure │ 256-bit encrypted  │
└─────────────────────────────────────────────────┘
       │
       ▼
STRIPE CHECKOUT
       │
       ▼
PAYMENT RECEIVED → Invoice marked PAID in CRM → Receipt emailed

THE ENTIRE FLOW IS ON THE CONTRACTOR'S DOMAIN.
Not a Stripe page. Not a ZAFTO page. THEIR website.
Builds trust. Looks professional.
```

### Implementation

```
ROUTE: {domain}/pay/{invoice_id}
- Supabase Edge Function verifies invoice belongs to this company
- Renders invoice details
- Stripe Elements embedded (card + ACH)
- Payment → Stripe webhook → update invoice status in CRM
- Receipt emailed to client + contractor notified

SECURITY:
- Invoice links are signed with expiring tokens
- Can only view/pay own invoices (no enumeration)
- Payment goes to contractor's Stripe Connect account
- ZAFTO never touches the money
```

---

## QR CODE GENERATOR

### Trackable QR Codes for Physical Marketing

```
CRM → Website → Settings → QR Codes

┌──────────────────────────────────────────────────────────────────┐
│  📱 QR Code Generator                                            │
│                                                                  │
│  Generate QR codes for:                                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Source Name      │ URL                    │ QR     │ Scans│   │
│  ├──────────────────┼────────────────────────┼────────┼──────┤   │
│  │ Business Card    │ site.com/?src=card     │ [img]  │  42  │   │
│  │ Truck Wrap       │ site.com/?src=truck    │ [img]  │  89  │   │
│  │ Yard Sign        │ site.com/?src=yard     │ [img]  │  23  │   │
│  │ Door Hanger      │ site.com/?src=door     │ [img]  │  11  │   │
│  │ Mailer           │ site.com/?src=mailer   │ [img]  │   7  │   │
│  │ Invoice Footer   │ site.com/?src=invoice  │ [img]  │  31  │   │
│  └──────────────────┴────────────────────────┴────────┴──────┘   │
│                                                                  │
│  [+ New QR Code]                                                 │
│                                                                  │
│  For each: [Download PNG] [Download SVG] [Download PDF]          │
│  Sizes: [1×1 in] [2×2 in] [3×3 in] [Custom]                    │
│  Style: [Standard ▾] (standard, rounded, with logo)             │
│                                                                  │
│  ───────────────────────────────────────────────────────────     │
│  📊 This month: 203 total scans                                 │
│  Top source: Truck Wrap (89 scans → 6 leads → $12,400 revenue) │
│  "Your truck wrap generated $12,400 in revenue this month."     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Each QR code has a unique UTM source.
When someone scans → lands on site → fills out form → lead created with source.
Lead → Bid → Job → Invoice = full revenue attribution.

"That yard sign at 42 Oak Street generated 3 leads worth $8,200."
← Nobody else can tell a contractor that.
```

---

## JOB POSTING & MULTI-CHANNEL HIRING SYSTEM

### The Problem

```
CURRENT REALITY FOR CONTRACTORS HIRING:
1. Write a job listing on a piece of paper or in their head
2. Manually post to Indeed (create account, learn interface)
3. Manually post to Craigslist (figure out categories, pay $25)
4. Manually post to Facebook (type it out again, hope people see it)
5. Maybe post to ZipRecruiter (another account, another interface)
6. Forget to post to Google Jobs (don't even know it exists)
7. Applications come to 5 different inboxes
8. Lose track of who applied where
9. Ghost half the applicants because it's too scattered

ZAFTO REALITY:
1. Create ONE listing in CRM
2. Click "Distribute"
3. Listing goes to 6+ channels simultaneously
4. ALL applications funnel to ONE inbox (CRM or email — their choice)
5. Track every applicant through a hiring pipeline
6. Done in 5 minutes
```

### The Core Concept

Contractor creates **ONE job listing** in the CRM → ZAFTO formats it for each platform
→ auto-distributes to every enabled channel → all applications route back to **ONE place**
(CRM applicant inbox OR contractor's email, based on their preference).

### How It Works

```
                        ZAFTO CRM
                    ┌─────────────────┐
                    │  CREATE LISTING  │
                    │  (one form)      │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ FORMAT ENGINE    │
                    │ (one listing →   │
                    │  6 formats)      │
                    └────────┬────────┘
                             │
        ┌──────────┬─────────┼──────────┬──────────┬──────────┐
        ▼          ▼         ▼          ▼          ▼          ▼
   ┌─────────┐ ┌───────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
   │ ZAFTO   │ │GOOGLE │ │ INDEED │ │  ZIP   │ │FACEBOOK│ │CRAIGS- │
   │ WEBSITE │ │ JOBS  │ │        │ │RECRUITER│ │  POST  │ │ LIST   │
   │(careers)│ │(free) │ │(feed)  │ │(feed)  │ │(share) │ │(copy)  │
   └────┬────┘ └───┬───┘ └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘
        │          │         │          │          │          │
        └──────────┴─────────┴──────────┴──────────┴──────────┘
                             │
                    ┌────────▼────────┐
                    │ UNIVERSAL APP   │
                    │ apply.zafto.    │
                    │ cloud/{co}/{id} │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼                             ▼
     ┌────────────────┐           ┌────────────────┐
     │ CRM APPLICANT  │           │  CONTRACTOR    │
     │ INBOX (default)│           │  EMAIL         │
     │ with pipeline  │           │ (if preferred) │
     └────────────────┘           └────────────────┘
```

---

### Channel Breakdown

```
CHANNEL              │ METHOD                    │ COST   │ REACH         │ SETUP
─────────────────────┼───────────────────────────┼────────┼───────────────┼──────────
ZAFTO Website        │ Auto-publish to /careers   │ Free   │ Direct        │ Zero
Google for Jobs      │ JSON-LD structured data    │ Free   │ Massive       │ Zero
Indeed               │ XML feed (Indeed crawls)   │ Free*  │ Massive       │ One-time
ZipRecruiter         │ XML feed partner program   │ Free*  │ Large         │ One-time
Facebook             │ Share-ready post generator │ Free   │ Local/social  │ Zero
Craigslist           │ Formatted text + one-click │ Free†  │ Local         │ Zero
                     │ copy to clipboard          │        │               │

* Free organic listing. Paid sponsorship available but not required.
† Most trades/jobs categories are free. Some metro areas charge $10-25.

NOT INCLUDED (yet):
LinkedIn             │ API requires paid recruiter license ($500+/mo). Not worth it
                     │ for a plumber hiring an apprentice. Add as premium tier later.
                     │ For now: generate shareable link they can post manually.
```

---

### 1. ZAFTO Website — Careers Page (Auto-Published)

```
WHEN: Contractor marks a position as "Open" in CRM Hiring tab
→ Position auto-appears on their ZAFTO website careers page
→ JSON-LD JobPosting structured data auto-injected (Google indexes it)

powerselectrical.com/careers/

┌──────────────────────────────────────────────────────────────────┐
│  JOIN OUR TEAM                                                    │
│                                                                  │
│  Powers Electrical is growing! We're looking for talented        │
│  professionals to join our crew.                                 │
│                                                                  │
│  OPEN POSITIONS:                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Licensed Electrician                            FULL-TIME  │ │
│  │ $35-45/hr │ Fairfield County, CT                          │ │
│  │ Benefits: Health, dental, 401k, company vehicle            │ │
│  │ Posted 3 days ago                                          │ │
│  │ [View Details & Apply →]                                   │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │ Apprentice Electrician                          FULL-TIME  │ │
│  │ $20-28/hr │ Fairfield County, CT                          │ │
│  │ Benefits: Health, dental, paid training                    │ │
│  │ Posted 1 week ago                                          │ │
│  │ [View Details & Apply →]                                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  WHY WORK WITH US:                                               │
│  ✓ 11 years in business    ✓ Benefits from day 1                │
│  ✓ Company vehicles        ✓ Paid training/certifications       │
│  ✓ Steady year-round work  ✓ Growth opportunities               │
│                                                                  │
│  (auto-populated from company profile + HR module data)          │
└──────────────────────────────────────────────────────────────────┘

LISTING DETAIL PAGE (powerselectrical.com/careers/licensed-electrician):
┌──────────────────────────────────────────────────────────────────┐
│  LICENSED ELECTRICIAN                                             │
│  Powers Electrical │ Fairfield County, CT │ Full-time            │
│                                                                  │
│  COMPENSATION: $35-45/hr (based on experience)                   │
│                                                                  │
│  ABOUT THIS ROLE:                                                │
│  [AI-enhanced description from contractor's input]               │
│                                                                  │
│  REQUIREMENTS:                                                   │
│  • Valid journeyman or master electrician license                │
│  • 3+ years commercial/residential experience                   │
│  • Valid driver's license                                        │
│  • Own hand tools                                                │
│                                                                  │
│  BENEFITS:                                                       │
│  • Health + dental insurance                                     │
│  • 401k with company match                                      │
│  • Company vehicle                                               │
│  • Paid holidays + PTO                                           │
│  • Tool allowance                                                │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  APPLY NOW                                                  │ │
│  │  Name: [_______________]  Phone: [______________]          │ │
│  │  Email: [______________]                                    │ │
│  │  Resume: [Upload PDF/DOC]                                   │ │
│  │  Years of experience: [___]                                 │ │
│  │  Licenses/certs: [_______________]                          │ │
│  │  Availability: [_______________]                            │ │
│  │  How did you hear about us? [Dropdown ▼]                   │ │
│  │          [Submit Application →]                             │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

TOGGLES (per company):
- Show/hide entire careers page
- Show/hide salary ranges per listing
- Show/hide benefits per listing
- Show/hide "Why Work With Us" section
```

---

### 2. Google for Jobs — JSON-LD (FREE, Automatic)

```
THIS IS THE BIGGEST WIN. ZERO EFFORT, MASSIVE REACH.

When someone Googles "electrician jobs near me" or "plumber hiring Fairfield CT",
Google shows a dedicated Jobs panel at the top of search results.
Getting into that panel requires ONE thing: valid JSON-LD on a public page.

ZAFTO auto-injects this into every active listing's detail page:

<script type="application/ld+json">
{
  "@context": "https://schema.org/",
  "@type": "JobPosting",
  "title": "Licensed Electrician",
  "description": "Powers Electrical is hiring a Licensed Electrician...",
  "datePosted": "2026-02-06",
  "validThrough": "2026-04-06",
  "employmentType": "FULL_TIME",
  "hiringOrganization": {
    "@type": "Organization",
    "name": "Powers Electrical",
    "sameAs": "https://powerselectrical.com",
    "logo": "https://powerselectrical.com/logo.png"
  },
  "jobLocation": {
    "@type": "Place",
    "address": {
      "@type": "PostalAddress",
      "addressLocality": "Fairfield",
      "addressRegion": "CT",
      "postalCode": "06824",
      "addressCountry": "US"
    }
  },
  "baseSalary": {
    "@type": "MonetaryAmount",
    "currency": "USD",
    "value": {
      "@type": "QuantitativeValue",
      "minValue": 35,
      "maxValue": 45,
      "unitText": "HOUR"
    }
  },
  "applicantLocationRequirements": {
    "@type": "Country",
    "name": "US"
  },
  "directApply": true
}
</script>

WHAT HAPPENS:
1. Contractor publishes listing in ZAFTO
2. Careers page + detail page auto-generate with JSON-LD
3. Google crawls the page (within 24-48 hrs for established domains)
4. Listing appears in Google Jobs panel
5. Applicant clicks "Apply" → lands on ZAFTO application form
6. Application routes to CRM inbox or email

NO API KEY. NO ACCOUNT. NO COST. Just valid structured data on a public page.
Google does all the indexing automatically.

FOR SUBDOMAIN USERS (yourco.zafto.cloud):
Same JSON-LD, same crawling. Works identically.
Google indexes subdomains the same as custom domains.
```

---

### 3. Indeed — XML Feed (FREE Organic)

```
Indeed is the #1 job board in the US. They offer a free XML feed program
where Indeed crawls a structured XML feed URL and indexes the listings.

ZAFTO generates a per-company XML feed at:
  https://zafto.cloud/api/jobs-feed/{companySlug}/indeed.xml

FEED FORMAT (Indeed XML Specification):
<?xml version="1.0" encoding="utf-8"?>
<source>
  <publisher>ZAFTO</publisher>
  <publisherurl>https://zafto.app</publisherurl>
  <lastBuildDate>Thu, 06 Feb 2026 12:00:00 GMT</lastBuildDate>
  <job>
    <title>Licensed Electrician</title>
    <date>Thu, 06 Feb 2026 12:00:00 GMT</date>
    <referencenumber>job_abc123</referencenumber>
    <url>https://apply.zafto.cloud/powers-electrical/job_abc123</url>
    <company>Powers Electrical</company>
    <city>Fairfield</city>
    <state>CT</state>
    <country>US</country>
    <postalcode>06824</postalcode>
    <description><![CDATA[Full job description HTML...]]></description>
    <salary>$35-45/hr</salary>
    <jobtype>fulltime</jobtype>
    <category>Construction & Extraction</category>
    <experience>3+ years</experience>
  </job>
</source>

SETUP (one-time per ZAFTO platform, not per contractor):
1. Register as Indeed XML Feed Partner (free)
2. Submit feed URL pattern: zafto.cloud/api/jobs-feed/{slug}/indeed.xml
3. Indeed crawls all feeds automatically on schedule
4. Listings appear in Indeed search results — free organic placement

CONTRACTOR DOES: Nothing. ZAFTO handles the feed automatically.

INDEED SPONSORED (optional, future):
- Contractors can optionally pay to boost visibility via Indeed Sponsored Jobs API
- Budget set in CRM, billed through ZAFTO
- This is a future monetization opportunity (ZAFTO takes margin on ad spend)
```

---

### 4. ZipRecruiter — XML Feed (FREE Organic)

```
Same concept as Indeed. ZipRecruiter has an XML partner feed program.

Feed URL: https://zafto.cloud/api/jobs-feed/{companySlug}/ziprecruiter.xml

ZipRecruiter uses a similar XML format to Indeed (minor field differences).
Same feed engine, different output format. ~1 hour additional work.

SETUP: Register as ZipRecruiter partner (free), submit feed URL pattern.
```

---

### 5. Facebook — Share-Ready Post Generator

```
Facebook sunset their dedicated Jobs product in Feb 2023.
But sharing job posts to a business page is still the #1 way trades hire locally.

ZAFTO APPROACH: Generate a perfectly formatted, share-ready post.

CRM → Hiring → [listing] → "Share" → Facebook

┌──────────────────────────────────────────────────────────────────┐
│  SHARE TO FACEBOOK                                               │
│                                                                  │
│  Preview:                                                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  🔧 WE'RE HIRING: Licensed Electrician                     │ │
│  │                                                            │ │
│  │  Powers Electrical is looking for a Licensed Electrician   │ │
│  │  to join our growing team in Fairfield, CT.                │ │
│  │                                                            │ │
│  │  💰 $35-45/hr                                              │ │
│  │  📍 Fairfield County, CT                                   │ │
│  │  🕐 Full-time                                              │ │
│  │                                                            │ │
│  │  Benefits: Health, dental, 401k, company vehicle           │ │
│  │                                                            │ │
│  │  Apply here: https://apply.zafto.cloud/powers/abc123       │ │
│  │                                                            │ │
│  │  Know someone who'd be great? Tag them! 👇                 │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  [Copy to Clipboard]  [Open Facebook →]                         │
│                                                                  │
│  Also generate for:                                              │
│  [Instagram]  [Nextdoor]  [LinkedIn]  [X/Twitter]               │
└──────────────────────────────────────────────────────────────────┘

Each platform gets a slightly different format:
- Facebook: longer, conversational, emoji-friendly, tag encouragement
- Instagram: shorter, visual-first (pair with a branded hiring graphic)
- Nextdoor: neighborhood-focused, emphasize "local company"
- LinkedIn: professional tone, emphasize growth/career
- X/Twitter: under 280 chars with apply link

All link back to the universal application page.
```

---

### 6. Craigslist — Formatted Text Generator

```
Craigslist has no API. Millions of people still use it for trade jobs.

ZAFTO generates Craigslist-optimized text with one click:

CRM → Hiring → [listing] → "Share" → Craigslist

┌──────────────────────────────────────────────────────────────────┐
│  POST TO CRAIGSLIST                                              │
│                                                                  │
│  Category: skilled trades/artisan                                │
│  Title: Licensed Electrician - $35-45/hr - Fairfield CT         │
│                                                                  │
│  Body (pre-formatted):                                           │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  LICENSED ELECTRICIAN — Powers Electrical                   │ │
│  │                                                            │ │
│  │  We're hiring a Licensed Electrician for our growing       │ │
│  │  team in Fairfield County, CT.                             │ │
│  │                                                            │ │
│  │  PAY: $35-45/hr based on experience                       │ │
│  │  TYPE: Full-time                                           │ │
│  │  LOCATION: Fairfield County, CT                            │ │
│  │                                                            │ │
│  │  REQUIREMENTS:                                             │ │
│  │  - Valid journeyman or master electrician license          │ │
│  │  - 3+ years experience                                    │ │
│  │  - Valid driver's license                                  │ │
│  │                                                            │ │
│  │  BENEFITS:                                                 │ │
│  │  - Health + dental insurance                               │ │
│  │  - 401k with company match                                │ │
│  │  - Company vehicle                                        │ │
│  │  - Paid holidays + PTO                                    │ │
│  │                                                            │ │
│  │  APPLY: https://apply.zafto.cloud/powers/abc123            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  [Copy Title]  [Copy Body]  [Open Craigslist →]                 │
│                                                                  │
│  Tip: Select "skilled trades/artisan" under "jobs"              │
└──────────────────────────────────────────────────────────────────┘

ONE CLICK copies both title and body. Contractor pastes into Craigslist.
The apply link routes back to ZAFTO.
```

---

### Universal Application Page

```
Every channel's application URL points to:
  https://apply.zafto.cloud/{companySlug}/{listingId}

This is a clean, mobile-optimized, standalone application page:

┌──────────────────────────────────────────────────────────────────┐
│  [Company Logo]                                                   │
│                                                                  │
│  APPLY: Licensed Electrician                                     │
│  Powers Electrical │ Fairfield, CT │ Full-time │ $35-45/hr      │
│                                                                  │
│  ─────────────────────────────────────────────────────────────   │
│                                                                  │
│  First Name: [_______________]  Last Name: [_______________]    │
│  Phone: [_______________]       Email: [___________________]    │
│                                                                  │
│  Resume/CV: [Upload File ↑] (PDF, DOC, DOCX — max 10MB)       │
│                                                                  │
│  Years of Experience: [___]                                      │
│                                                                  │
│  Do you hold any trade licenses? [Yes / No]                     │
│    If yes: [_______________] State: [__] License #: [________]  │
│                                                                  │
│  Do you have reliable transportation? [Yes / No]                │
│  Do you have your own tools? [Yes / No]                         │
│                                                                  │
│  Earliest start date: [_______________]                          │
│                                                                  │
│  How did you hear about this position?                          │
│  [▼ Google / Indeed / ZipRecruiter / Facebook / Craigslist /    │
│     Friend/Referral / Company Website / Other ]                 │
│                                                                  │
│  Anything else you'd like us to know? (optional)                │
│  [__________________________________________________]           │
│  [__________________________________________________]           │
│                                                                  │
│            [Submit Application →]                                │
│                                                                  │
│  Powered by ZAFTO                                                │
└──────────────────────────────────────────────────────────────────┘

AFTER SUBMIT:
→ Thank you page with company branding
→ Application stored in job_applications table
→ Resume uploaded to Supabase Storage (company_id/applications/{id}/)
→ Notification sent to contractor (push + email)
→ Source channel tracked (UTM or dropdown selection)

THE APPLICATION PAGE IS:
- Company branded (logo, colors from CRM)
- Mobile-first (most trade applicants apply from phone)
- Fast (static page, no JS framework required — Cloudflare Workers)
- Accessible (WCAG 2.1 AA)
- Multi-language (if contractor has Spanish enabled)
```

---

### Response Routing (Contractor's Choice)

```
CRM → Settings → Hiring Preferences

┌──────────────────────────────────────────────────────────────────┐
│  HIRING PREFERENCES                                              │
│                                                                  │
│  Where should applications go?                                   │
│                                                                  │
│  ◉ ZAFTO Applicant Inbox (recommended)                          │
│    All applications appear in CRM → Team → Hiring → Applications │
│    Full pipeline tracking, notes, status updates, team collab    │
│                                                                  │
│  ○ Email Only                                                    │
│    Forward all applications to: [robert@powerselectrical.com]   │
│    (You'll still see them in CRM as backup)                     │
│                                                                  │
│  ○ Both (CRM Inbox + Email Notification)                        │
│    Application in CRM + email summary with resume attached      │
│                                                                  │
│  ─────────────────────────────────────────────────────────────   │
│                                                                  │
│  Notification preferences:                                       │
│  ☑ Push notification on new application                         │
│  ☑ Email summary on new application                             │
│  ☐ Daily digest instead of individual notifications             │
│  ☑ Notify on application from Indeed/ZipRecruiter               │
│  ☑ Notify on application from website                           │
│                                                                  │
│  Who receives hiring notifications?                              │
│  ☑ Robert (Owner)                                               │
│  ☑ Sarah (Admin)                                                │
│  ☐ Mike (Office)                                                │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

REGARDLESS of routing preference, every application creates a record
in job_applications. Even "Email Only" users have a backup in CRM.
This protects against lost emails and gives pipeline tracking if they
ever switch to CRM Inbox mode.
```

---

### CRM Hiring Tab (Applicant Pipeline)

```
CRM → Team → Hiring

┌──────────────────────────────────────────────────────────────────┐
│  HIRING                                    [+ New Job Listing]   │
│                                                                  │
│  ACTIVE LISTINGS (2)                                             │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Licensed Electrician         12 applicants │ 3 new today   │ │
│  │ Posted Feb 1 │ Active on: Website, Google, Indeed, Zip     │ │
│  │ [View Applicants]  [Edit]  [Pause]  [Share ▼]  [Close]   │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │ Apprentice Electrician       4 applicants │ 0 new today    │ │
│  │ Posted Feb 3 │ Active on: Website, Google, Indeed          │ │
│  │ [View Applicants]  [Edit]  [Pause]  [Share ▼]  [Close]   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  APPLICANT PIPELINE (Licensed Electrician):                      │
│                                                                  │
│  NEW (5)      │ REVIEWED (3)  │ INTERVIEW (2)│ OFFERED (1) │   │
│  ┌─────────┐  │ ┌─────────┐  │ ┌─────────┐  │ ┌─────────┐ │   │
│  │ John D. │  │ │ Mike R. │  │ │ Sarah T.│  │ │ Alex P. │ │   │
│  │ Indeed  │  │ │ Website │  │ │ Indeed  │  │ │ Google  │ │   │
│  │ 3 yrs   │  │ │ 7 yrs   │  │ │ 5 yrs   │  │ │ 10 yrs  │ │   │
│  │ ⭐⭐⭐    │  │ │ ⭐⭐⭐⭐   │  │ │ ⭐⭐⭐⭐   │  │ │ ⭐⭐⭐⭐⭐ │ │   │
│  └─────────┘  │ └─────────┘  │ └─────────┘  │ └─────────┘ │   │
│  ┌─────────┐  │ ┌─────────┐  │ ┌─────────┐  │             │   │
│  │ Lisa M. │  │ │ Tom K.  │  │ │ Chris W.│  │  HIRED (1)  │   │
│  │ Facebook│  │ │ ZipRecr │  │ │ Referral│  │ ┌─────────┐ │   │
│  │ 1 yr    │  │ │ 4 yrs   │  │ │ 8 yrs   │  │ │ Dave R. │ │   │
│  │ ⭐⭐      │  │ │ ⭐⭐⭐    │  │ │ ⭐⭐⭐⭐⭐  │  │ │ Started │ │   │
│  └─────────┘  │ └─────────┘  │ └─────────┘  │ │ Feb 10  │ │   │
│  ┌─────────┐  │ ┌─────────┐  │              │ └─────────┘ │   │
│  │ Ray S.  │  │ │ Kim L.  │  │              │             │   │
│  │ Craigs  │  │ │ Google  │  │   REJECTED   │             │   │
│  └─────────┘  │ └─────────┘  │   (3)        │             │   │
│  ...          │              │              │             │   │
│               │              │              │             │   │
└──────────────────────────────────────────────────────────────────┘

APPLICANT DETAIL VIEW:
┌──────────────────────────────────────────────────────────────────┐
│  JOHN DOE                                    Status: [NEW ▼]    │
│  Applied: Feb 6 via Indeed                                      │
│                                                                  │
│  Phone: (203) 555-1234  │  Email: john@email.com               │
│  Experience: 3 years    │  License: CT JE-12345                │
│  Has transportation: Yes │  Has own tools: Yes                 │
│  Available: Feb 15                                              │
│                                                                  │
│  Resume: [View PDF ↓]  [Download]                               │
│                                                                  │
│  NOTES:                                                          │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Robert (Feb 6): "Strong background, schedule a call"       │ │
│  │ Sarah (Feb 6): "Called, meeting Thursday 2pm"              │ │
│  └────────────────────────────────────────────────────────────┘ │
│  [Add Note _______________________________________________]     │
│                                                                  │
│  ACTIONS:                                                        │
│  [Move to Reviewed]  [Schedule Interview]  [Reject]  [Hire →]  │
│                                                                  │
│  QUICK ACTIONS:                                                  │
│  [Send "We Received Your Application" Email]                    │
│  [Send "Schedule Interview" Email with Calendar Link]           │
│  [Send "Position Filled" Email]                                 │
└──────────────────────────────────────────────────────────────────┘

APPLICANT STATUSES:
new → reviewed → phone_screen → interview → offered → hired
                                                    → rejected (at any stage)

RBAC:
- Owner/Admin: full access (create listings, manage applicants, hire)
- Office: view applicants, add notes, schedule interviews
- Tech: no access to hiring (default — Owner can grant)
```

---

### Job Listing Creation — AI-Assisted

```
CRM → Team → Hiring → [+ New Job Listing]

┌──────────────────────────────────────────────────────────────────┐
│  CREATE JOB LISTING                                              │
│                                                                  │
│  BASICS:                                                         │
│  Position Title: [Licensed Electrician          ]               │
│  Employment Type: [Full-time ▼]  (Full/Part/Contract/Temp)      │
│  Location: [Fairfield County, CT] (from company profile)        │
│  Remote: [No ▼]  (No / Hybrid / Yes)                           │
│                                                                  │
│  COMPENSATION:                                                   │
│  Pay Type: [Hourly ▼]  (Hourly / Salary / Commission)          │
│  Range: [$35] — [$45] per [hour ▼]                             │
│  Show range on listing? [Yes ▼]                                 │
│                                                                  │
│  DESCRIPTION:                                                    │
│  [Write a few bullet points and Z will write the full listing]  │
│  • Need licensed electrician for residential + commercial       │
│  • Must have own tools and reliable transportation              │
│  • 3+ years experience preferred                                │
│                                                                  │
│  [Generate Full Description with Z →]                           │
│                                                                  │
│  ┌── AI-GENERATED DESCRIPTION ──────────────────────────────┐   │
│  │  Powers Electrical is seeking an experienced Licensed      │   │
│  │  Electrician to join our team serving Fairfield County,    │   │
│  │  CT. You'll work on residential and commercial projects    │   │
│  │  ranging from panel upgrades to full-building wiring...    │   │
│  │                                                            │   │
│  │  [Edit]  [Regenerate]  [Accept →]                         │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  REQUIREMENTS: (checkboxes — auto-formats into listing)         │
│  ☑ Trade license required  Type: [Journeyman/Master ▼]         │
│  ☑ Years of experience     Minimum: [3]                         │
│  ☑ Driver's license required                                    │
│  ☑ Own tools required                                           │
│  ☐ Drug test required                                           │
│  ☐ Background check required                                    │
│  ☐ OSHA certification required                                  │
│  [+ Add custom requirement]                                     │
│                                                                  │
│  BENEFITS: (check all that apply)                               │
│  ☑ Health insurance        ☑ Dental insurance                   │
│  ☑ 401k / retirement      ☑ Company vehicle                    │
│  ☑ Paid time off          ☑ Paid holidays                      │
│  ☐ Vision insurance        ☐ Life insurance                    │
│  ☐ Tool allowance          ☐ Gas card                          │
│  ☐ Continuing education    ☐ Uniform provided                  │
│  [+ Add custom benefit]                                         │
│                                                                  │
│  APPLICATION SETTINGS:                                           │
│  Custom questions: (optional, max 3)                            │
│  1. [Are you comfortable working at heights?    ]               │
│  2. [Do you have experience with 3-phase systems?]              │
│  3. [___________________________________________]               │
│                                                                  │
│  Auto-close after: [60 days ▼]  (30/60/90/Never)               │
│                                                                  │
│  DISTRIBUTION:                                                   │
│  ☑ ZAFTO Website (careers page)                                 │
│  ☑ Google for Jobs (JSON-LD — automatic, free)                  │
│  ☑ Indeed (XML feed — automatic, free)                          │
│  ☑ ZipRecruiter (XML feed — automatic, free)                    │
│  ☐ Facebook (generate shareable post)                           │
│  ☐ Craigslist (generate formatted text)                         │
│  ☐ LinkedIn / Instagram / Nextdoor / X (generate share text)   │
│                                                                  │
│  [Save as Draft]  [Publish & Distribute →]                      │
└──────────────────────────────────────────────────────────────────┘

AI DESCRIPTION GENERATION:
- Contractor types 3-5 bullet points
- Z (Claude) generates professional job description
- Tone matches company profile (friendly small shop vs professional enterprise)
- Auto-includes trade-specific language and requirements
- Contractor reviews, edits if needed, approves
- NEVER posts without contractor approval (same as Dashboard rule)
```

---

### Hiring Analytics

```
CRM → Team → Hiring → Analytics

┌──────────────────────────────────────────────────────────────────┐
│  HIRING ANALYTICS                                    Last 90 days│
│                                                                  │
│  OVERVIEW:                                                       │
│  Total Applications: 47    │  Positions Filled: 2               │
│  Avg Time to Hire: 18 days │  Open Positions: 2                 │
│                                                                  │
│  APPLICATIONS BY SOURCE:                                         │
│  Indeed          ████████████████████  22 (47%)                  │
│  Google          ████████████         14 (30%)                   │
│  Website         ███                   4 (9%)                    │
│  Facebook        ██                    3 (6%)                    │
│  ZipRecruiter    ██                    2 (4%)                    │
│  Craigslist      █                     1 (2%)                    │
│  Referral        █                     1 (2%)                    │
│                                                                  │
│  CONVERSION FUNNEL:                                              │
│  Applied: 47 → Reviewed: 31 → Interviewed: 8 → Offered: 3 →    │
│  Hired: 2                                                        │
│  Conversion rate: 4.3%                                           │
│                                                                  │
│  BEST PERFORMING CHANNEL:                                        │
│  Indeed — highest volume + 2/2 hires came from Indeed            │
│                                                                  │
│  COST PER HIRE: $0 (all organic channels)                       │
└──────────────────────────────────────────────────────────────────┘

This data compounds. After 6 months, a contractor KNOWS which channels
work for their trade in their area. That intelligence is locked into ZAFTO.
```

---

### Quick-Action Emails (Template-Based)

```
AUTOMATED APPLICANT EMAILS (sent via contractor's email or ZAFTO):

1. APPLICATION RECEIVED (auto-send on submit):
   "Hi [Name], thanks for applying for the [Position] role at [Company].
    We've received your application and will review it shortly.
    — [Company Name]"

2. SCHEDULE INTERVIEW (one-click from applicant detail):
   "Hi [Name], we'd like to schedule an interview for the [Position] role.
    Please select a time that works: [Calendar Link]
    — [Company Name]"

3. POSITION FILLED (one-click from listing):
   "Hi [Name], thank you for your interest in [Company]. The [Position]
    role has been filled. We'll keep your application on file for future
    openings. — [Company Name]"

4. OFFER (generated from applicant detail):
   "Hi [Name], we're pleased to offer you the [Position] role at
    [Company] at [Pay Rate]. Please reply to confirm your start date.
    — [Company Name]"

All emails:
- Sent from contractor's email (via SendGrid or Cloudflare Email Routing)
- Use contractor's company branding
- Are templates — contractor can customize before sending
- Logged in applicant timeline
- NEVER auto-send without contractor action (except #1 if enabled)
```

---

### Implementation Estimate

```
TOTAL: ~18-22 HOURS

SCHEMA + BACKEND:
- job_listings table + RLS                              1 hr
- job_applications table + RLS                          1 hr
- job_listing_distributions table + RLS                 30 min
- publishJobListing Edge Function                       2 hrs
- generateJobsFeed Edge Function (Indeed/Zip XML)       3 hrs
- processJobApplication Edge Function                   2 hrs
  (already partially exists as processCareerApplication)
- generateJobDescription Edge Function (AI)             1.5 hrs
- sendApplicantEmail Edge Function                      1 hr

CRM UI:
- Hiring tab (listing management + pipeline board)      4 hrs
- Listing creation form (with AI description)           2 hrs
- Applicant detail view                                 1.5 hrs
- Social share generators (FB/CL/LI/IG/X)              1.5 hrs
- Hiring preferences (settings)                         1 hr
- Hiring analytics                                      1.5 hrs

WEBSITE:
- Careers page template (already partially spec'd)      1 hr
  (expand with JSON-LD + detail pages)
- Universal application page (apply.zafto.cloud)        2 hrs

PHASE BREAKDOWN:
Phase 1 (ship with Website Builder):
  - Job listing CRUD + careers page + application form
  - Google Jobs JSON-LD (automatic, zero effort)
  - CRM applicant inbox + pipeline
  - Response routing (CRM vs email)
  - ~12 hrs

Phase 2 (month 1 post-launch):
  - Indeed XML feed integration
  - ZipRecruiter XML feed integration
  - Social share generators (FB/CL/LI/etc.)
  - AI description generation
  - Quick-action applicant emails
  - Hiring analytics
  - ~10 hrs
```

---

## MULTI-LANGUAGE SUPPORT

### AI-Powered Translation

```
CRM → Website → Settings → Language

┌──────────────────────────────────────────────────────────────────┐
│  🌐 Website Languages                                            │
│                                                                  │
│  Primary language: English                                       │
│                                                                  │
│  Additional languages:                                           │
│  ☑ Spanish (Español)     [Preview →]   Status: ✅ Published     │
│  ☐ Portuguese (Português) [Add →]                                │
│  ☐ French (Français)     [Add →]                                │
│  ☐ Chinese (中文)         [Add →]                                │
│                                                                  │
│  Translation method: AI (Claude) — personalized, not generic     │
│                                                                  │
│  Language switcher on website: [EN | ES] (top right corner)     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

HOW IT WORKS:
1. Contractor enables Spanish
2. Opus translates ALL website content:
   - Not Google Translate (generic, awkward)
   - Personalized translation from their actual content
   - Trade terminology translated correctly
   - Service descriptions, about page, team, everything
3. Contractor (or bilingual employee) can review/edit translations
4. Language switcher appears on website
5. AI Chat also responds in visitor's language

WHY THIS MATTERS:
- Texas, Florida, California, Arizona, Nevada, New Jersey, New York
- 30%+ of homeowners speak Spanish in many metro areas
- Competitors don't offer this
- One toggle → entire site translated → massive market expansion

SEO BONUS:
Spanish pages get their own URLs: /es/servicios/, /es/contacto/
Rank for "electricista en Stamford CT" — zero competition.
```

---

## SEASONAL/PROMOTIONAL BANNERS

### Scheduled Marketing Campaigns

```
CRM → Website → Promotions

┌──────────────────────────────────────────────────────────────────┐
│  🎯 Promotions & Banners                                        │
│                                                                  │
│  ACTIVE NOW:                                                     │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ 🔥 "Spring AC Tune-Up — $50 Off"                        │   │
│  │ Shows: March 1 – May 31, 2026                            │   │
│  │ Pages: Homepage, HVAC Services                            │   │
│  │ Style: Top banner (yellow)                                │   │
│  │ Clicks: 47  │  Leads from promo: 8                       │   │
│  │ [Edit] [Pause] [End Early]                                │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  SCHEDULED:                                                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ ❄️ "Winter Generator Special — Free Transfer Switch"     │   │
│  │ Shows: October 1 – December 31, 2026                      │   │
│  │ Status: Scheduled (starts in 7 months)                    │   │
│  │ [Edit] [Delete]                                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  PAST:                                                           │
│  • "Holiday Lighting Installation" — Nov-Dec 2025 — 14 leads   │
│  • "Emergency Generator Promo" — Sep 2025 — 6 leads            │
│                                                                  │
│  [+ Create New Promotion]                                        │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

CREATE PROMOTION:
┌──────────────────────────────────────────────────────────────────┐
│  New Promotion                                                    │
│                                                                  │
│  Headline: [Spring AC Tune-Up — $50 Off              ]          │
│  Details:  [Schedule before May 31 and save!          ]          │
│  CTA button: [Book Now ▾]  → links to: [Contact form ▾]        │
│                                                                  │
│  Schedule:                                                       │
│  Start: [March 1, 2026]    End: [May 31, 2026]                 │
│  ☑ Auto-remove after end date                                    │
│                                                                  │
│  Display:                                                        │
│  Style: [Top banner ▾] (top banner / hero overlay / popup)      │
│  Color: [From brand palette ▾]                                   │
│  Pages: [☑ Homepage] [☑ HVAC Services] [☐ All pages]           │
│                                                                  │
│  Tracking:                                                       │
│  ☑ Track clicks                                                  │
│  ☑ Track leads with promo code: [SPRING50]                      │
│                                                                  │
│  AI Suggest:                                                     │
│  [💡 Suggest seasonal promotions for my trade →]                │
│                                                                  │
│  [Preview]  [Save as Draft]  [Schedule]                          │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

AI PROMOTION SUGGESTIONS (by trade + season):
─────────────────────────────────────────────
Opus knows trade seasonality:
- HVAC: AC tune-ups spring, heating fall, emergency generator storm season
- Electrical: Holiday lighting fall, generator before hurricane season, EV spring
- Plumbing: Winterization fall, water heater flush spring
- Roofing: Post-storm inspections, spring maintenance
- Landscaping: Spring cleanup, fall leaf removal, holiday lighting

Contractor clicks "Suggest" → gets 3-4 promotion ideas with copy ready to go.
```

---

## PRINT MARKETING TEMPLATES

### Branded Collateral Export

```
CRM → Website → Settings → Print Marketing

All templates auto-populated with:
- Logo (from Logo Creator)
- Brand colors
- Phone number
- Website URL
- QR code (with source tracking)

TEMPLATES AVAILABLE:
┌──────────────────────────────────────────────────────────────────┐
│  🖨️ Print Marketing                                             │
│                                                                  │
│  All templates use your logo, colors, and contact info.          │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │BUSINESS  │  │ YARD     │  │ DOOR     │  │ TRUCK    │      │
│  │  CARD    │  │  SIGN    │  │ HANGER   │  │  WRAP    │      │
│  │ 3.5×2"  │  │ 18×24"  │  │ 4.25×11" │  │ Custom  │      │
│  │[Preview] │  │[Preview] │  │[Preview] │  │[Preview] │      │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘      │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ POSTCARD │  │  FLYER   │  │ESTIMATE  │  │ SOCIAL   │      │
│  │ MAILER   │  │  8.5×11" │  │ FOLDER   │  │  MEDIA   │      │
│  │ 6×4"    │  │          │  │          │  │ TEMPLATES│      │
│  │[Preview] │  │[Preview] │  │[Preview] │  │[Preview] │      │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘      │
│                                                                  │
│  Each template:                                                  │
│  [Download PDF (Print-Ready)]  [Download PNG]  [Edit Text →]   │
│                                                                  │
│  ☑ Include QR code with tracking                                 │
│  Source name for QR: [Business Card ▾]                           │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

TEMPLATES PER TRADE:
- Business cards (2-3 styles per trade)
- Yard signs (standard sizes for sign shops)
- Door hangers (standard print size)
- Truck/van wrap templates (side panel, rear, full wrap outlines)
- Postcard mailers (USPS standard sizes)
- Flyers (8.5×11, quarter-page)
- Estimate/proposal folders
- Social media templates (FB cover, IG post, IG story, Google Business)

ALL VECTOR (SVG/PDF): Contractor downloads, sends to print shop.
Print shop gets a professional, print-ready file. No "can you send it bigger?"
```

---

## ACCESSIBILITY (WCAG 2.1 AA)

### Built Into Templates, Not Bolted On

```
ZAFTO'S APPROACH:
Templates are WCAG 2.1 AA compliant BY DESIGN.
The contractor cannot break accessibility because they can't modify structure.

WHAT'S ENFORCED:
✅ Color contrast ratios (4.5:1 minimum for text, 3:1 for large text)
   → Color picker PREVENTS choosing non-compliant combinations
   → "That yellow text on white won't be readable. Try this darker shade."

✅ Alt text on all images
   → AI auto-generates alt text for portfolio photos
   → Editable by contractor in Photo Manager

✅ Keyboard navigation
   → All interactive elements focusable and operable via keyboard
   → Skip-to-content link on every page
   → Focus indicators visible

✅ Screen reader compatibility
   → Proper heading hierarchy (H1 → H2 → H3, no skipping)
   → ARIA labels on all interactive elements
   → Form labels properly associated
   → Meaningful link text (no "click here")

✅ Mobile accessibility
   → Touch targets minimum 44×44px
   → No horizontal scrolling
   → Pinch-to-zoom not disabled

✅ Content accessibility
   → Reading level appropriate (Opus writes at 8th grade level)
   → No text in images (all text is real text)
   → Video captions if video is ever added

WHY THIS MATTERS:
- ADA website lawsuits against small businesses: ~4,000/year and growing
- Average settlement: $5,000-$25,000
- ZAFTO templates = automatic protection
- Contractor can tell customers "Our website is ADA compliant"
- Another trust signal / competitive advantage
```

---

## UPDATED FEATURES CHECKLIST

### All New Features

```
AI WEBSITE CHAT WIDGET:
- [ ] Chat widget component (website embed)
- [ ] Chat configuration panel (CRM → Website → AI Chat)
- [ ] Knowledge source toggles (what AI can/can't share)
- [ ] Price visibility controls (categories, display mode)
- [ ] Behavior settings (goal, tone, lead capture fields)
- [ ] Custom rules system (contractor writes own instructions)
- [ ] Conversation storage and history viewer
- [ ] Lead capture flow (chat → CRM lead)
- [ ] Unanswered question log
- [ ] Chat analytics (conversations, leads, conversion rate)
- [ ] Multi-language chat (respond in visitor's language)
- [ ] websiteChatMessage Edge Function
- [ ] website_chat_config table + RLS
- [ ] website_chat_sessions table + RLS

PROFESSIONAL EMAIL:
- [ ] Email setup UI (CRM → Website → Settings → Email)
- [ ] Cloudflare Email Routing API integration
- [ ] Auto-create info@ on domain purchase
- [ ] Add/remove email forwarding rules
- [ ] Catch-all toggle
- [ ] Gmail "Send As" setup guide link

LEGAL PAGES:
- [ ] Auto-generate privacy policy from company data
- [ ] Auto-generate terms of service
- [ ] Auto-generate accessibility statement
- [ ] State-specific privacy law detection (CCPA, CTDPA, etc.)
- [ ] Review/approve flow before publishing
- [ ] Auto-update when company data changes

TRUST BADGES:
- [ ] Auto-detect badges from CRM data (licenses, insurance, reviews, years)
- [ ] Manual badge upload (BBB, trade associations)
- [ ] Toggle per badge (show/hide)
- [ ] Display location options (header, hero, contact, footer)
- [ ] Auto-update from live data

SERVICE AREA MAP:
- [ ] Interactive map component on website
- [ ] Auto-populate from company zip codes
- [ ] Auto-populate from completed job GPS data
- [ ] "Do you serve my area?" zip code checker
- [ ] Service area page auto-generation (per city)
- [ ] Opus unique content per city page
- [ ] Schema markup per service area page
- [ ] Configuration UI (CRM → Website → SEO)

PAY YOUR INVOICE:
- [ ] Invoice payment page ({domain}/pay/{invoice_id})
- [ ] Stripe Elements embedded (card + ACH)
- [ ] Signed URL tokens for invoice links
- [ ] Payment → webhook → update invoice status
- [ ] Receipt email to client
- [ ] Payment notification to contractor
- [ ] Mobile-optimized payment page

QR CODE GENERATOR:
- [ ] QR code creation UI with source name
- [ ] UTM parameter injection per QR code
- [ ] Download PNG/SVG/PDF at multiple sizes
- [ ] Style options (standard, rounded, with logo center)
- [ ] Scan tracking + analytics
- [ ] Revenue attribution from QR source → lead → job → invoice

JOB POSTING & MULTI-CHANNEL HIRING SYSTEM:
- [ ] job_listings table + RLS
- [ ] job_applications table + RLS
- [ ] job_listing_distributions table + RLS
- [ ] Hiring tab in CRM (Team → Hiring)
- [ ] Job listing creation form with AI description generation
- [ ] Requirement checkboxes + benefits checkboxes (structured data)
- [ ] Distribution channel toggles (Website, Google, Indeed, Zip, FB, CL)
- [ ] publishJobListing Edge Function (format + distribute)
- [ ] generateJobsFeed Edge Function (Indeed XML + ZipRecruiter XML feeds)
- [ ] Dynamic careers page on ZAFTO website (auto-publish from CRM)
- [ ] Listing detail pages with JSON-LD JobPosting structured data (Google Jobs)
- [ ] Universal application page (apply.zafto.cloud/{company}/{listing})
- [ ] processJobApplication Edge Function (store, notify, route)
- [ ] Response routing preferences (CRM inbox / email / both)
- [ ] Applicant pipeline board (new → reviewed → interview → offered → hired/rejected)
- [ ] Applicant detail view (resume, notes, status, timeline)
- [ ] Social share post generators (Facebook, Instagram, LinkedIn, Nextdoor, X, Craigslist)
- [ ] generateJobDescription Edge Function (AI-assisted from bullet points)
- [ ] Quick-action applicant emails (received, schedule, filled, offer)
- [ ] sendApplicantEmail Edge Function
- [ ] Hiring analytics (source breakdown, funnel, time-to-hire, cost-per-hire)
- [ ] Notification preferences (who gets notified, push/email/digest)
- [ ] Auto-close listings after configurable days (30/60/90)
- [ ] RBAC: Owner/Admin full access, Office limited, Tech no access by default

MULTI-LANGUAGE:
- [ ] Language configuration UI
- [ ] Opus translation of all website content
- [ ] Per-page translation review/edit
- [ ] Language switcher component on website
- [ ] Spanish (priority), Portuguese, French, Chinese
- [ ] Translated URLs for SEO (/es/servicios/)
- [ ] AI Chat responds in visitor's language

SEASONAL PROMOTIONS:
- [ ] Promotion creation UI (headline, details, CTA, schedule)
- [ ] Auto-show/auto-hide by date range
- [ ] Display options (top banner, hero overlay, popup)
- [ ] Click and lead tracking per promotion
- [ ] Promo code support
- [ ] AI seasonal promotion suggestions by trade
- [ ] Promotion history with performance data

PRINT MARKETING:
- [ ] Business card templates (2-3 per trade)
- [ ] Yard sign templates
- [ ] Door hanger templates
- [ ] Truck wrap outline templates
- [ ] Postcard/mailer templates
- [ ] Flyer templates
- [ ] Social media templates (FB, IG, Google Business)
- [ ] Auto-populate from logo, colors, contact info
- [ ] QR code with source tracking on each
- [ ] PDF export (print-ready, vector)
- [ ] PNG export

ACCESSIBILITY:
- [ ] WCAG 2.1 AA compliance in all templates
- [ ] Color contrast enforcement in color picker
- [ ] Auto-generated alt text for photos (AI)
- [ ] Keyboard navigation on all templates
- [ ] Screen reader testing per template
- [ ] Accessibility statement page
- [ ] ARIA labels audit

CRM WEBSITE MANAGER TAB:
- [ ] Tab layout with sub-navigation
- [ ] Photos sub-tab (links to Photo Manager)
- [ ] Promotions sub-tab
- [ ] AI Chat sub-tab
- [ ] Content sub-tab (page editor)
- [ ] Careers sub-tab (links to Team → Hiring, shows website careers page preview)
- [ ] SEO sub-tab (meta, service areas, blog)
- [ ] Analytics sub-tab
- [ ] Settings sub-tab (domain, email, template, sync, trust badges)
- [ ] Quick stats bar (visitors, leads, revenue)
- [ ] RBAC enforcement on all sub-tabs
```

## DATABASE TABLES (Supabase PostgreSQL)

> **NOTE:** Photo schema in Photo Management System section. Logo schema in Logo Creator section.
> AI Chat schema in AI Website Chat Widget section. All use standard company_id RLS.

```sql
-- Core website config
CREATE TABLE websites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) UNIQUE,
  template_id TEXT NOT NULL,
  subdomain TEXT NOT NULL UNIQUE,
  custom_domain TEXT,
  domain_status TEXT DEFAULT 'subdomain_only',
  status TEXT DEFAULT 'draft',
  published_at TIMESTAMPTZ,
  hero_headline TEXT, hero_subhead TEXT, about_text TEXT, services_intro TEXT,
  custom_sections JSONB DEFAULT '[]',
  primary_color TEXT, secondary_color TEXT,
  seo_title TEXT, seo_description TEXT, google_analytics_id TEXT,
  auto_sync_services BOOLEAN DEFAULT true,
  auto_sync_team BOOLEAN DEFAULT true,
  auto_sync_portfolio BOOLEAN DEFAULT false,
  auto_sync_reviews BOOLEAN DEFAULT true,
  auto_sync_certs BOOLEAN DEFAULT true,
  auto_sync_careers BOOLEAN DEFAULT true,            -- Auto-publish job listings to careers page
  primary_language TEXT DEFAULT 'en',
  enabled_languages TEXT[] DEFAULT ARRAY['en'],
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE website_pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  website_id UUID NOT NULL REFERENCES websites(id),
  slug TEXT NOT NULL, title TEXT NOT NULL,
  content JSONB, is_published BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  page_type TEXT DEFAULT 'custom',
  translations JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(website_id, slug)
);

CREATE TABLE website_domains (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) UNIQUE,
  domain TEXT NOT NULL UNIQUE,
  cloudflare_domain_id TEXT, cloudflare_zone_id TEXT,
  registrant_info JSONB,
  purchased_at TIMESTAMPTZ, expires_at TIMESTAMPTZ,
  auto_renew BOOLEAN DEFAULT true, whois_privacy BOOLEAN DEFAULT true,
  status TEXT DEFAULT 'active',
  last_renewal_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE website_email_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  domain_id UUID NOT NULL REFERENCES website_domains(id),
  local_part TEXT NOT NULL,
  forward_to TEXT NOT NULL,
  enabled BOOLEAN DEFAULT true,
  cloudflare_rule_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(domain_id, local_part)
);

CREATE TABLE website_leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  source TEXT NOT NULL,
  source_page TEXT, source_campaign TEXT, promo_code TEXT,
  name TEXT, email TEXT, phone TEXT, message TEXT, address TEXT,
  language TEXT DEFAULT 'en',
  converted_to_customer_id UUID, converted_to_bid_id UUID,
  converted_to_job_id UUID,
  revenue_generated DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE website_promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  headline TEXT NOT NULL, details TEXT,
  cta_text TEXT DEFAULT 'Learn More', cta_link TEXT DEFAULT '/contact',
  promo_code TEXT,
  start_date DATE NOT NULL, end_date DATE NOT NULL,
  display_style TEXT DEFAULT 'top_banner',
  display_color TEXT, display_pages TEXT[] DEFAULT ARRAY['home'],
  is_active BOOLEAN DEFAULT true,
  click_count INTEGER DEFAULT 0, lead_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE website_qr_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  source_name TEXT NOT NULL, utm_source TEXT NOT NULL,
  target_url TEXT NOT NULL,
  style TEXT DEFAULT 'standard',
  scan_count INTEGER DEFAULT 0, lead_count INTEGER DEFAULT 0,
  revenue_attributed DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE website_trust_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  badge_type TEXT NOT NULL, label TEXT NOT NULL,
  icon_url TEXT, source_module TEXT,
  is_visible BOOLEAN DEFAULT true,
  display_locations TEXT[] DEFAULT ARRAY['hero'],
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- JOB POSTING & MULTI-CHANNEL HIRING SYSTEM
-- Replaces basic website_careers/website_applications tables
-- ============================================================

CREATE TABLE job_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Position details
  title TEXT NOT NULL,                               -- "Licensed Electrician"
  slug TEXT NOT NULL,                                -- "licensed-electrician" (URL-safe)
  description TEXT NOT NULL,                         -- Full job description (AI-generated or manual)
  description_bullets JSONB DEFAULT '[]',            -- Original bullet points (used for AI regeneration)
  employment_type TEXT NOT NULL DEFAULT 'full_time', -- full_time, part_time, contract, temporary
  location TEXT NOT NULL,                            -- "Fairfield County, CT" (from company profile)
  remote_type TEXT DEFAULT 'no',                     -- no, hybrid, yes

  -- Compensation
  pay_type TEXT NOT NULL DEFAULT 'hourly',           -- hourly, salary, commission
  pay_min DECIMAL(10,2),                             -- Minimum pay
  pay_max DECIMAL(10,2),                             -- Maximum pay
  pay_unit TEXT DEFAULT 'HOUR',                      -- HOUR, YEAR (for schema.org)
  show_pay BOOLEAN DEFAULT true,                     -- Show pay range on listing

  -- Requirements (structured for schema.org + UI checkboxes)
  requirements JSONB DEFAULT '[]',                   -- [{type: "license", label: "Journeyman", required: true}, ...]
  min_experience_years INTEGER,
  requires_drivers_license BOOLEAN DEFAULT false,
  requires_own_tools BOOLEAN DEFAULT false,
  requires_drug_test BOOLEAN DEFAULT false,
  requires_background_check BOOLEAN DEFAULT false,
  custom_requirements JSONB DEFAULT '[]',            -- Free-form additional requirements

  -- Benefits (structured for UI checkboxes)
  benefits JSONB DEFAULT '[]',                       -- ["health_insurance", "dental", "401k", "company_vehicle", ...]
  custom_benefits JSONB DEFAULT '[]',                -- Free-form additional benefits
  show_benefits BOOLEAN DEFAULT true,

  -- Custom application questions (max 3)
  custom_questions JSONB DEFAULT '[]',               -- ["Comfortable at heights?", "3-phase experience?"]

  -- Distribution settings
  distribute_website BOOLEAN DEFAULT true,           -- Auto-publish to ZAFTO website careers page
  distribute_google BOOLEAN DEFAULT true,            -- JSON-LD structured data (auto, free)
  distribute_indeed BOOLEAN DEFAULT true,            -- Include in Indeed XML feed
  distribute_ziprecruiter BOOLEAN DEFAULT true,      -- Include in ZipRecruiter XML feed

  -- Status + lifecycle
  status TEXT NOT NULL DEFAULT 'draft',              -- draft, active, paused, closed
  published_at TIMESTAMPTZ,
  auto_close_days INTEGER DEFAULT 60,                -- Auto-close after N days (null = never)
  closes_at TIMESTAMPTZ,                             -- Computed: published_at + auto_close_days
  closed_at TIMESTAMPTZ,
  close_reason TEXT,                                 -- filled, expired, cancelled

  -- Metrics (denormalized for fast display)
  total_applications INTEGER DEFAULT 0,
  new_applications INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id),

  UNIQUE(company_id, slug)
);

ALTER TABLE job_listings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "job_listing_isolation" ON job_listings
  USING (company_id = current_setting('app.company_id')::UUID);
CREATE INDEX idx_job_listings_company_status ON job_listings(company_id, status);
CREATE INDEX idx_job_listings_active ON job_listings(company_id) WHERE status = 'active';

CREATE TABLE job_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES job_listings(id) ON DELETE CASCADE,

  -- Applicant info
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,

  -- Qualifications
  resume_path TEXT,                                  -- Supabase Storage: {company_id}/applications/{id}/resume.pdf
  years_experience INTEGER,
  has_trade_license BOOLEAN DEFAULT false,
  license_type TEXT,                                 -- "Journeyman", "Master"
  license_state TEXT,
  license_number TEXT,
  has_transportation BOOLEAN,
  has_own_tools BOOLEAN,
  earliest_start_date DATE,

  -- Custom question answers
  custom_answers JSONB DEFAULT '{}',                 -- {q1: "Yes", q2: "3 years", q3: "..."}

  -- Source tracking
  source_channel TEXT NOT NULL DEFAULT 'website',    -- website, google, indeed, ziprecruiter, facebook, craigslist, referral, other
  source_detail TEXT,                                -- UTM campaign, specific referrer, etc.
  how_heard TEXT,                                    -- Applicant's self-reported "how did you hear"

  -- Pipeline status
  status TEXT NOT NULL DEFAULT 'new',                -- new, reviewed, phone_screen, interview, offered, hired, rejected
  status_changed_at TIMESTAMPTZ DEFAULT NOW(),
  rejection_reason TEXT,                             -- Optional: why rejected (internal note)

  -- Notes (team collaboration)
  notes JSONB DEFAULT '[]',                          -- [{user_id, text, created_at}, ...]

  -- Notification routing
  email_sent_to_contractor BOOLEAN DEFAULT false,    -- Was the email notification sent
  routed_to TEXT DEFAULT 'crm',                      -- crm, email, both

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "job_application_isolation" ON job_applications
  USING (company_id = current_setting('app.company_id')::UUID);
CREATE INDEX idx_job_applications_listing ON job_applications(listing_id, status);
CREATE INDEX idx_job_applications_company ON job_applications(company_id, status);
CREATE INDEX idx_job_applications_new ON job_applications(company_id) WHERE status = 'new';

CREATE TABLE job_listing_distributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES job_listings(id) ON DELETE CASCADE,

  channel TEXT NOT NULL,                             -- website, google, indeed, ziprecruiter, facebook, craigslist, linkedin, etc.
  distributed_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'active',                      -- active, paused, removed
  external_id TEXT,                                  -- Indeed job ID, ZipRecruiter ID, etc. (if returned by feed)
  external_url TEXT,                                 -- Direct link to listing on external platform
  applications_from_channel INTEGER DEFAULT 0,       -- Denormalized count

  UNIQUE(listing_id, channel)
);

ALTER TABLE job_listing_distributions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "job_distribution_isolation" ON job_listing_distributions
  USING (company_id = current_setting('app.company_id')::UUID);

CREATE TABLE website_service_areas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  city TEXT NOT NULL, state TEXT NOT NULL, slug TEXT NOT NULL,
  content TEXT, schema_markup JSONB,
  is_published BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(company_id, slug)
);

CREATE TABLE website_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL, description TEXT,
  trade TEXT, style TEXT,
  preview_url TEXT, html_template TEXT NOT NULL,
  default_pages JSONB, color_palette JSONB,
  modifiable_elements JSONB, ai_instructions TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: All company-scoped tables filtered by company_id
-- website_templates is read-only for all authenticated users
```

### Legacy Reference (Pre-Migration Firestore Structure)

> The following was the original Firestore structure. Retained for migration reference only.
> All data now lives in the PostgreSQL tables above.

```
companies/{companyId}/website/
  ├── templateId
  ├── subdomain (yourcompany.zafto.cloud)
  ├── customDomain (nullable)
  ├── domainStatus: "subdomain_only" | "custom_pending" | "custom_active"
  ├── publishedAt
  ├── status: "draft" | "published" | "suspended"
  │
  ├── CONTENT
  │   ├── heroHeadline, heroSubhead
  │   ├── aboutText
  │   ├── servicesIntro
  │   └── customSections []
  │
  ├── SETTINGS
  │   ├── primaryColor, secondaryColor
  │   ├── logoUrl
  │   ├── faviconUrl
  │   ├── seoTitle, seoDescription
  │   └── googleAnalyticsId
  │
  ├── SYNC SETTINGS
  │   ├── autoSyncServices: bool
  │   ├── autoSyncTeam: bool
  │   ├── autoSyncPortfolio: bool
  │   ├── autoSyncReviews: bool
  │   └── autoSyncCerts: bool
  │
  └── PAGES
      └── pages [] { slug, title, content, isPublished, sortOrder }

companies/{companyId}/websiteDomain/
  ├── domain
  ├── cloudflareDomainId
  ├── cloudflareZoneId
  ├── registrantInfo {}
  ├── purchasedAt
  ├── expiresAt
  ├── autoRenew: bool
  ├── whoisPrivacy: bool
  ├── status: "active" | "pending_transfer" | "expired"
  └── lastRenewalAt

companies/{companyId}/websiteLeads/{leadId}/
  ├── source: "contact_form" | "booking" | "chat"
  ├── sourcePage (which page/URL)
  ├── name, email, phone, message
  ├── createdAt
  ├── convertedToCustomerId (nullable)
  ├── convertedToBidId (nullable)
  ├── convertedToJobId (nullable)
  └── revenueGenerated (calculated from job)

websiteTemplates/{templateId}/
  ├── name, description
  ├── trade
  ├── style: "bold" | "clean" | "modern" | "warm" | "premium"
  ├── previewUrl
  ├── htmlTemplate
  ├── defaultPages []
  ├── colorPalette []
  ├── modifiableElements []
  └── aiInstructions (for template assistant)
```

---

## SUPABASE EDGE FUNCTIONS

| Function | Trigger | Purpose |
|----------|---------|---------|
| `checkDomainAvailability` | HTTP | Query Cloudflare for domain availability |
| `purchaseDomain` | HTTP | Buy domain via Cloudflare API |
| `configureDomainDNS` | HTTP | Set up DNS records + email routing |
| `renewDomain` | Scheduled | Auto-renew domains before expiry |
| `domainExpiryReminder` | Scheduled | Email/push reminders |
| `transferDomainOut` | HTTP | Unlock and generate auth code |
| `generateWebsiteContent` | HTTP | Opus generates copy |
| `publishWebsite` | HTTP | Build and deploy to Cloudflare Pages |
| `syncWebsiteData` | DB webhook | Sync CRM data to website |
| `websiteLeadCapture` | HTTP | Contact form submission |
| `generateServiceAreaPages` | HTTP | Auto-create city pages for SEO |
| `generateBlogPost` | HTTP | AI blog content |
| `websiteChatMessage` | HTTP | AI chat — builds prompt from config, calls Claude |
| `processWebsitePhoto` | DB webhook | Resize, WebP, EXIF strip, blur hash |
| `generateLegalPages` | HTTP | Opus generates privacy policy + ToS |
| `translateWebsiteContent` | HTTP | Opus translates all content to target language |
| `setupEmailRouting` | HTTP | Cloudflare Email Routing API |
| `publishJobListing` | HTTP | Format listing for all channels, inject JSON-LD, update feeds |
| `generateJobsFeed` | HTTP | Generate Indeed XML + ZipRecruiter XML feeds per company |
| `processJobApplication` | HTTP | Store application + resume, route to CRM/email, notify |
| `generateJobDescription` | HTTP | AI (Claude) generates full description from bullet points |
| `sendApplicantEmail` | HTTP | Template-based emails (received, schedule, filled, offer) |
| `generateQRCode` | HTTP | Create tracked QR code with UTM |
| `invoicePaymentPage` | HTTP | Render invoice + Stripe Elements |

---

## PRICING STRUCTURE (LOCKED)

| Tier | Domain | Monthly | Annual Domain | Features |
|------|--------|:-------:|:-------------:|----------|
| **Included** | yourcompany.zafto.cloud | $0 | $0 | Full website builder, all features |
| **Custom Domain** | yourcompany.com | $19.99/mo | $14.99/year | Domain purchased through ZAFTO |

**Margin Analysis:**
- Cloudflare domain cost: ~$9-11/year
- Our domain charge: $14.99/year
- Domain margin: ~$5/year
- Hosting revenue: $19.99/mo × 12 = $239.88/year
- **Total revenue per custom domain customer: ~$255/year**

---

## PHOTO MANAGEMENT SYSTEM

### The Problem

```
CURRENT REALITY:
Contractor takes 47 photos on a job. Some are progress shots for the customer.
Some are code violations for the inspector. Some are measurements for ordering.
Some are the finished product that would look AMAZING on their website.

Without a system: ALL 47 photos go everywhere, or NONE go anywhere.

WHAT WE NEED:
Every photo gets tagged at capture time. Only photos explicitly marked
"website-worthy" ever touch the website. This is a DELIBERATE action,
not an automatic dump.
```

### Photo Pipeline: Mobile → CRM → Website

```
CAPTURE (Mobile App)                    MANAGE (CRM Web Portal)                DISPLAY (Website)
──────────────────                      ──────────────────────                 ─────────────────
Tech takes photo                        Office/Owner reviews photos            Website gallery shows
  ↓                                       ↓                                    ONLY approved photos
Photo saved with metadata               Can approve/reject for website           ↓
  - job_id                              Can add to albums                      Auto-optimized
  - category (see below)                Can set as hero/featured               WebP, responsive sizes
  - taken_by (user_id)                  Can reorder gallery                    Lazy-loaded
  - timestamp                           Can add captions/alt text              SEO alt text
  - GPS coordinates                     Can create before/after pairs
  ↓                                       ↓
Syncs to Supabase Storage              "Publish to Website" = deliberate
via PowerSync queue                     permission-gated action
```

### Photo Categories (Tagged at Capture)

```
CATEGORY              PURPOSE                        WEBSITE ELIGIBLE?
─────────────────     ──────────────────────────     ─────────────────
portfolio             Showcase finished work          ✅ YES — primary gallery source
before_after          Before/after transformation     ✅ YES — paired display
team                  Team/crew photos                ✅ YES — team page
equipment             Equipment/fleet photos          ✅ YES — about page
office                Office/shop/facility            ✅ YES — about page
progress              Job progress documentation      ❌ NO — internal only
inspection            Code compliance/violations      ❌ NO — internal only
measurement           Dimensions/specifications       ❌ NO — internal only
receipt               Material receipts               ❌ NO — internal only
damage                Pre-existing damage (CYA)       ❌ NO — internal only
safety                Safety briefing documentation   ❌ NO — internal only
other                 Uncategorized                   ❌ NO — until recategorized
```

### RBAC: Who Can Do What With Photos

```
ACTION                              OWNER    ADMIN    OFFICE    TECH    CLIENT
──────────────────────────────      ─────    ─────    ──────    ────    ──────
Take/upload photos                    ✅       ✅       ✅        ✅       ❌
Tag category at capture               ✅       ✅       ✅        ✅       ❌
Mark "website candidate"              ✅       ✅       ✅        ✅       ❌
APPROVE for website (publish)         ✅       ✅       ✅        ❌       ❌
REMOVE from website                   ✅       ✅       ✅        ❌       ❌
Set as hero/featured image            ✅       ✅       ❌        ❌       ❌
Manage website gallery order          ✅       ✅       ✅        ❌       ❌
Delete photos permanently             ✅       ✅       ❌        ❌       ❌
Edit captions/alt text                ✅       ✅       ✅        ❌       ❌
Create before/after pairs             ✅       ✅       ✅        ❌       ❌
View job photos                       ✅       ✅       ✅        ✅*      ✅**

* Tech: Only photos from their assigned jobs
** Client: Only photos from their projects (via Client Portal)
```

**KEY PERMISSION: Techs can SUGGEST photos for the website. Only Owner/Admin/Office can APPROVE.**

### The Approval Flow

```
STEP 1: CAPTURE
Tech takes photo on job site → tags as "portfolio" → marks "website candidate" ☆

STEP 2: NOTIFICATION
Owner/Admin/Office gets notification:
"3 new photos from [Job Name] suggested for website"

STEP 3: REVIEW (CRM → Job Photos tab OR Website Builder → Photo Manager)
Reviewer sees:
┌──────────────────────────────────────────────────────┐
│  📷 New Website Candidates (3)                       │
│                                                      │
│  [Photo 1]  [Photo 2]  [Photo 3]                   │
│                                                      │
│  Job: Smith Kitchen Remodel                          │
│  Taken by: Mike (Tech)                               │
│  Date: Feb 5, 2026                                   │
│                                                      │
│  For each photo:                                     │
│  [✅ Approve for Website]  [❌ Reject]  [📝 Caption] │
│                                                      │
│  Album:  [Kitchen ▾]    Before/After: [Pair with ▾] │
│  Feature: [☐ Hero Image]  [☐ Featured]              │
└──────────────────────────────────────────────────────┘

STEP 4: PUBLISH
Approved photos appear in Website Builder gallery
If auto-sync ON → website updates automatically
If auto-sync OFF → Owner clicks "Publish Changes" when ready
```

### Website Builder: Photo Manager UI

```
WEBSITE BUILDER → PHOTOS TAB

┌─────────────────────────────────────────────────────────────────┐
│  Gallery Manager                                    [+ Upload]  │
│                                                                 │
│  Albums:  [All] [Kitchen] [Bathroom] [Exterior] [Team] [+ New] │
│                                                                 │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐          │
│  │         │  │         │  │ BEFORE/ │  │         │          │
│  │  img 1  │  │  img 2  │  │  AFTER  │  │  img 4  │          │
│  │         │  │         │  │  PAIR   │  │         │          │
│  │ ⭐ Hero │  │         │  │         │  │         │          │
│  ├─────────┤  ├─────────┤  ├─────────┤  ├─────────┤          │
│  │ Kitchen │  │ Kitchen │  │Bathroom │  │Exterior │          │
│  │ Caption │  │ Caption │  │ Caption │  │ Caption │          │
│  │ [Edit]  │  │ [Edit]  │  │ [Edit]  │  │ [Edit]  │          │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘          │
│                                                                 │
│  Drag to reorder  │  ⭐ = Hero image  │  Pairs show side-by-side│
│                                                                 │
│  PENDING APPROVAL (2)                                           │
│  ┌─────────┐  ┌─────────┐                                     │
│  │ NEW ☆  │  │ NEW ☆  │   [Approve All]  [Review]           │
│  └─────────┘  └─────────┘                                     │
│                                                                 │
│  [Auto-sync: ON ▾]        [Publish Changes]                    │
└─────────────────────────────────────────────────────────────────┘

FEATURES:
• Drag-and-drop reordering
• Album organization (auto-created from job type, or manual)
• Before/after pairing (select two photos → "Create Before/After Pair")
• Hero image designation (one per page — shown large at top)
• Featured photos (shown in homepage gallery)
• Caption + alt text editing (AI can suggest based on job data)
• Pending approval queue (photos techs have suggested)
• Manual upload (for non-job photos: office, equipment, headshots)
• Bulk actions (approve all, move to album, delete)
```

### Photo Processing Pipeline

```
ORIGINAL UPLOAD (Supabase Storage)
  ↓
PROCESSING (Supabase Edge Function: processWebsitePhoto)
  ↓
  ├── Thumbnail:  200×200   (gallery grid)
  ├── Medium:     800×600   (gallery lightbox)
  ├── Large:      1600×1200 (hero/featured)
  ├── WebP:       All sizes converted (40-60% smaller)
  ├── EXIF:       Strip GPS/personal data from public copies
  └── Blur hash:  Generate placeholder for lazy loading
  ↓
STORAGE STRUCTURE:
  company-photos/
    {company_id}/
      website/
        originals/    ← full resolution, private bucket
        thumbnails/   ← 200×200, public CDN
        medium/       ← 800×600, public CDN
        large/        ← 1600×1200, public CDN
      jobs/
        {job_id}/     ← all job photos, private bucket
      team/           ← team headshots, public CDN
```

### Database Schema (Supabase PostgreSQL)

```sql
-- Photo metadata
CREATE TABLE photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),
  uploaded_by UUID NOT NULL REFERENCES users(id),
  
  -- Classification
  category TEXT NOT NULL DEFAULT 'other',  -- portfolio, before_after, team, etc.
  album TEXT,                               -- user-created album name
  
  -- Website publishing
  website_candidate BOOLEAN DEFAULT false,  -- tech suggested for website
  website_approved BOOLEAN DEFAULT false,   -- owner/admin/office approved
  website_approved_by UUID REFERENCES users(id),
  website_approved_at TIMESTAMPTZ,
  website_published BOOLEAN DEFAULT false,  -- actually live on website
  
  -- Display
  caption TEXT,
  alt_text TEXT,                            -- SEO alt text
  display_order INTEGER DEFAULT 0,          -- gallery sort order
  is_hero BOOLEAN DEFAULT false,            -- hero image for a page
  is_featured BOOLEAN DEFAULT false,        -- homepage gallery
  
  -- Before/After pairing
  before_after_pair_id UUID,               -- links two photos as a pair
  before_after_type TEXT,                  -- 'before' or 'after'
  
  -- Storage
  storage_path TEXT NOT NULL,              -- Supabase Storage path
  thumbnail_path TEXT,
  medium_path TEXT,
  large_path TEXT,
  file_size INTEGER,
  width INTEGER,
  height INTEGER,
  mime_type TEXT,
  blur_hash TEXT,
  
  -- Metadata
  taken_at TIMESTAMPTZ,                    -- EXIF date or upload date
  gps_lat DECIMAL(10, 8),                 -- from EXIF (private, never on website)
  gps_lng DECIMAL(11, 8),
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: Standard company isolation + tech sees own job photos only
-- Audit: All approve/publish/delete actions logged

-- Website gallery view (what the website queries)
CREATE VIEW website_gallery AS
SELECT p.*, j.title as job_title, j.job_type
FROM photos p
LEFT JOIN jobs j ON p.job_id = j.id
WHERE p.website_published = true
ORDER BY p.display_order, p.created_at DESC;
```

### Mobile App: Photo Capture Enhancement

```
CURRENT STATE:
PhotoService exists (492 lines, complete capture logic)
but NOTHING in the app actually uses it.
No tagging. No categorization. No sync.

WHAT NEEDS TO BE BUILT:

1. CAPTURE FLOW (when tech takes a photo on a job)
   ┌──────────────────────────────────────────┐
   │  📷 Photo Captured                       │
   │                                          │
   │  Category:  [Portfolio ▾]                │
   │                                          │
   │  ☐ Suggest for website  ☆               │
   │                                          │
   │  Caption (optional): [                 ] │
   │                                          │
   │  [Save]              [Save & Take More]  │
   └──────────────────────────────────────────┘

   - Category picker defaults based on context:
     * On active job → "progress"
     * Job marked complete → "portfolio"
     * In safety briefing → "safety"
     * Manual override always available

2. JOB PHOTOS TAB (on each job detail screen)
   - Grid view of all photos for this job
   - Filter by category
   - ☆ toggle to suggest for website
   - Tech can see which photos were approved/published

3. QUICK CAPTURE (floating camera button on job screen)
   - One tap → camera → auto-tagged to current job
   - Category defaults to "progress"
   - Minimal friction for field workers
```

### CRM: Job Photos Integration

```
JOB DETAIL → PHOTOS TAB

┌──────────────────────────────────────────────────────┐
│  Photos (23)                           [+ Upload]    │
│                                                      │
│  Filter: [All ▾] [Portfolio] [Progress] [Inspection] │
│                                                      │
│  ☆ Website Candidates (3 pending approval)           │
│  ┌────┐ ┌────┐ ┌────┐                              │
│  │ ☆ │ │ ☆ │ │ ☆ │  [Approve All] [Review]       │
│  └────┘ └────┘ └────┘                              │
│                                                      │
│  All Photos                                          │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ...          │
│  │    │ │    │ │    │ │    │ │    │               │
│  └────┘ └────┘ └────┘ └────┘ └────┘               │
│                                                      │
│  ✅ On Website (5)  │  ☆ Pending (3)  │  📷 All (23)│
└──────────────────────────────────────────────────────┘

Actions per photo:
- View full size
- Edit category
- Edit caption
- ☆ Suggest for website (if not already)
- ✅ Approve for website (Owner/Admin/Office only)
- ❌ Remove from website
- 🗑️ Delete (Owner/Admin only)
- Create before/after pair
```

### Implementation Checklist

```
MOBILE APP (Flutter):
- [ ] Wire PhotoService to actual UI (it exists but nothing calls it)
- [ ] Photo capture → category picker → save to Supabase Storage
- [ ] "Suggest for website" toggle on capture
- [ ] Job Photos tab on job detail screen
- [ ] Quick capture floating button on job screens
- [ ] Photo sync via PowerSync queue
- [ ] Category defaults based on context
- [ ] Bulk photo capture mode (take multiple, tag after)

CRM WEB PORTAL:
- [ ] Job detail → Photos tab
- [ ] Website candidate approval queue
- [ ] Photo approval/rejection with notification back to tech
- [ ] Caption and alt text editing
- [ ] Before/after pair creation
- [ ] Photo category management
- [ ] Bulk approve/reject/delete

WEBSITE BUILDER:
- [ ] Photo Manager tab (full gallery management UI)
- [ ] Album creation and organization
- [ ] Drag-and-drop reorder
- [ ] Hero image designation
- [ ] Featured photos selection
- [ ] Before/after display component
- [ ] Manual upload for non-job photos
- [ ] Pending approval queue
- [ ] Auto-sync toggle
- [ ] "Publish Changes" button

BACKEND (Supabase):
- [ ] photos table with RLS (company isolation + tech job restriction)
- [ ] website_gallery view
- [ ] processWebsitePhoto Edge Function (resize, WebP, blur hash, EXIF strip)
- [ ] Photo approval audit logging
- [ ] Storage buckets (private originals, public CDN for website sizes)
- [ ] Signed URLs for private photos (job/internal)
- [ ] Public CDN URLs for website photos
```

---

| Connects To | How |
|-------------|-----|
| Price Book | Services sync to website |
| HR/Employees | Team page sync |
| Job Photos | Portfolio sync — **approval-gated**, RBAC-controlled (see Photo Management System) |
| Google Business | Reviews sync |
| Certifications | Credentials display |
| Calendar/Dispatch | Booking widget |
| Customers | Lead → Customer flow |
| Bids | Lead → Bid flow |
| Jobs | Lead → Job → Revenue attribution |
| Invoices | Revenue attribution |
| Email Marketing | Website leads trigger sequences |
| Analytics | Traffic, conversion, revenue |

---

| Email Marketing | Website leads trigger sequences |
| Analytics | Traffic, conversion, revenue |
| **Logo Creator** | Logo → website header, favicon, invoice, bid, client portal, business card |

---

## LOGO CREATOR

### Philosophy

```
NOT building: Canva, Figma, or any freeform design tool.
NOT using: AI image generation (Opus/GPT/Midjourney = blurry text, unusable).

BUILDING: Template engine + icon library + typography system.
Same philosophy as the Website Builder: constrained choices → professional results.
Contractor picks a layout, enters their name, picks colors, picks an icon. Done.
3 minutes. Looks like they paid a designer $500.
```

### How It Works

```
STEP 1: TRADE + NAME
┌─────────────────────────────────────────────────┐
│  Create Your Logo                               │
│                                                 │
│  Company Name: [Powers Landscaping LLC        ] │
│  Trade: [Landscaping ▾]                         │
│                                                 │
│  [Continue →]                                   │
└─────────────────────────────────────────────────┘

STEP 2: AI RECOMMENDS → USER PICKS
AI analyzes: name length, trade, # of words, LLC/Inc presence
AI recommends: top 8 templates that work best for this specific name

┌─────────────────────────────────────────────────┐
│  Pick a Style                                   │
│                                                 │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐       │
│  │ POWERS  │  │ POWERS  │  │   🌿    │       │
│  │LANDSCAP-│  │  ━━━━   │  │ POWERS  │       │
│  │  ING    │  │LANDSCA- │  │LANDSCA- │       │
│  │  🌿    │  │ PING    │  │ PING    │       │
│  │ Badge   │  │Underline│  │Icon Top │       │
│  └─────────┘  └─────────┘  └─────────┘       │
│                                                 │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐       │
│  │P|L      │  │◆ POWERS │  │POWERS   │       │
│  │ Mono    │  │  Shield │  │Stacked  │       │
│  └─────────┘  └─────────┘  └─────────┘       │
│                                                 │
│  [Show More Layouts]                            │
└─────────────────────────────────────────────────┘

STEP 3: CUSTOMIZE
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  ┌──────────────────────┐   COLORS                      │
│  │                      │   [■ Dark Green] Primary       │
│  │      POWERS          │   [■ Gold     ] Accent        │
│  │    LANDSCAPING       │   [■ White    ] Background    │
│  │       🌿             │   [From brand palette ▾]      │
│  │                      │                                │
│  │    Live Preview      │   ICON                         │
│  │                      │   [🌿] [🌳] [🍃] [✂️] [🏡]    │
│  └──────────────────────┘   [More icons →]               │
│                                                          │
│                             FONT                         │
│                             [Montserrat ▾]               │
│                             Weight: [Bold ▾]             │
│                                                          │
│                             TAGLINE (optional)           │
│                             [Est. 2019              ]    │
│                                                          │
│                             [✓ Save Logo]                │
└──────────────────────────────────────────────────────────┘

Everything updates live as they change options.
```

### Template Architecture

```
TEMPLATE = SVG with variable slots

<svg viewBox="0 0 400 200">
  <!-- Layout: Badge style -->
  <rect ... fill="{{primary_color}}" />          ← brand color slot
  <text ... font-family="{{font}}">              ← font slot
    {{company_name}}                              ← name slot (auto-sized)
  </text>
  <text ... >{{tagline}}</text>                  ← tagline slot
  <g transform="...">{{icon_svg}}</g>            ← icon slot (swappable SVG)
</svg>

TEMPLATE TYPES (10-12 layouts):
1. Badge         — name inside a shape (circle, shield, rectangle)
2. Underline     — name with decorative line below
3. Icon Top      — icon above name
4. Icon Left     — icon to the left of name
5. Monogram      — large first letters + small full name
6. Shield        — name inside shield/crest shape
7. Stacked       — company name large, trade small below
8. Horizontal    — everything in one line (for headers)
9. Circular      — text around a circle with icon center
10. Minimal      — just text, perfect typography, no icon
11. Stamp        — vintage/seal look
12. Modern       — geometric shapes + text

Each template has responsive logic:
- Short name ("ABC Electric"): normal spacing
- Medium name ("Powers Landscaping"): adjusted kerning
- Long name ("Northeastern CT Mechanical Services LLC"): auto-wrap or abbreviate
```

### Icon Library

```
PER TRADE (30-50 icons each, curated SVG):

ELECTRICAL:        ⚡ 🔌 💡 🔧 circuit, bolt, panel, wire, outlet, breaker,
                   meter, conduit, transformer, LED, EV charger, solar+wire

PLUMBING:          🔧 🚿 💧 pipe, wrench, faucet, valve, drain, water heater,
                   toilet, sink, flame+pipe, pressure gauge, sewer

HVAC:              ❄️ 🔥 🌡️ snowflake, flame, thermostat, duct, compressor,
                   fan, air flow, heat pump, furnace, refrigerant

SOLAR:             ☀️ ⚡ panel, sun, roof+panel, battery, inverter, grid,
                   leaf+sun, house+panel, meter, EV+solar

ROOFING:           🏠 roof line, shingle, hammer, ridge, gutter, chimney,
                   house silhouette, nail, slate, peak

GENERAL CONTRACTOR: 🏗️ 🔨 hammer, blueprint, hardhat, crane, level, house frame,
                   tape measure, saw, brick, beam

REMODELER:         🏠 ✨ paintbrush, roller, floor plan, cabinet, tile,
                   before/after arrows, crown molding, window, door

LANDSCAPING:       🌿 🌳 leaf, tree, mower, shovel, flower, fence, stone path,
                   irrigation, sun+plant, hedge trimmer

UNIVERSAL:         ★ ◆ ● shield, banner, ribbon, wreath, check mark,
                   tools crossed, est. badge, location pin

SOURCE: Open-source SVG libraries (Lucide, Heroicons, trade-specific sets)
All icons normalized to same viewBox, stroke width, style.
Single color — fills with the user's brand color.
```

### Smart Typography

```
THE HARD PART OF LOGOS: Making text look good at every name length.

FONT LIBRARY (15 curated, pre-loaded):
─────────────────────────────────────
BOLD/IMPACT:     Montserrat Bold, Oswald, Bebas Neue, Anton
PROFESSIONAL:    Inter, Source Sans Pro, Raleway, Nunito Sans
CLASSIC:         Playfair Display, Merriweather, Lora
TRADE/RUGGED:    Barlow Condensed, Teko, Russo One, Archivo Black

AUTO-SIZING LOGIC:
1. Measure text width at default size
2. If text overflows template bounds:
   a. Reduce font size (down to minimum threshold)
   b. If still too wide: split into two lines at logical break
   c. If company has "LLC/Inc/Corp": move to smaller subtitle line
   d. Adjust letter-spacing proportionally
3. If text is very short: increase letter-spacing for visual balance

Example:
"ABC Electric"                → large text, generous letter-spacing
"Powers Landscaping LLC"      → medium text, "LLC" drops to subtitle
"Northeastern CT Mechanical   → two lines, condensed font auto-selected
 Services LLC"
```

### Where the Logo Lives (System-Wide Integration)

```
ONE LOGO → EVERYWHERE:

LOCATION                    FORMAT          SIZE
──────────────────          ──────          ─────────────
Website header              SVG             auto-scaled
Website favicon             PNG             32×32, 16×16
Invoice header              PNG             high-res (300 DPI)
Bid/Proposal header         PNG             high-res (300 DPI)
Client Portal header        SVG             auto-scaled
Email signature             PNG             200px wide
Business card export        SVG + PDF       3.5" × 2"
Social media profile        PNG             500×500 square
Social media cover          PNG             1500×500 wide
Truck wrap template         SVG + PDF       vector, any size
Letterhead                  PNG             high-res header
App splash screen           SVG             centered
Crew t-shirt template       SVG + PDF       vector, any size

STORAGE:
company_assets/
  {company_id}/
    logo/
      source.svg            ← full vector (master)
      favicon-32.png
      favicon-16.png
      header-200.png
      header-400.png
      print-300dpi.png
      square-500.png
      cover-1500x500.png
      logo.pdf              ← print-ready vector
```

### Export & Download

```
EXPORT OPTIONS (from Logo Manager screen):

┌─────────────────────────────────────────────────────┐
│  Your Logo                          [Edit Logo]     │
│                                                     │
│  ┌───────────────────┐                             │
│  │                   │                             │
│  │   POWERS          │                             │
│  │  LANDSCAPING      │                             │
│  │     🌿            │                             │
│  │                   │                             │
│  └───────────────────┘                             │
│                                                     │
│  Download:                                          │
│  [PNG - Web]  [PNG - Print (300 DPI)]  [SVG]  [PDF]│
│                                                     │
│  Sized for:                                         │
│  [Business Card]  [Social Media]  [Truck Wrap]     │
│  [Email Signature]  [Letterhead]  [All Sizes ZIP]  │
│                                                     │
│  Brand Colors:                                      │
│  ■ #2D5016  ■ #C4A946  ■ #FFFFFF                  │
│  [Copy hex codes]                                   │
│                                                     │
│  Font: Montserrat Bold                              │
│  [Download font file]                               │
└─────────────────────────────────────────────────────┘

"All Sizes ZIP" = every format/size in one download.
Contractors hand this to their sign shop, print shop, t-shirt vendor.
```

### AI Role (What Opus Actually Does)

```
NOT generating images. NOT drawing logos.

OPUS DOES:
1. RECOMMEND templates based on:
   - Trade (electricians get bold/technical, landscapers get organic/natural)
   - Name length (short names → more layout options, long names → filtered)
   - Style preference if stated ("modern", "classic", "bold")
   
2. RECOMMEND icon based on:
   - Trade
   - Services listed (if Price Book has data)
   - "You do solar installations — here are the solar-specific icons"

3. RECOMMEND colors based on:
   - Trade conventions (green for landscaping, blue for plumbing, etc.)
   - Or pull from brand colors if already set

4. GENERATE tagline suggestions:
   - "Powering Connecticut Since 2019"
   - "Licensed & Insured"
   - "Quality You Can Trust"
   - User picks or writes their own

5. CRITIQUE (optional):
   - "Your company name is long — the Badge layout will look cramped.
     Try the Stacked or Horizontal layout instead."
   - "White text on yellow background has poor contrast. Try dark green."
```

### Implementation Estimate: ~5 Hours

```
HOUR 1: Template Engine Core
- SVG rendering with variable slots in Flutter
- Color injection, font loading, icon swapping
- Live preview component
- Auto-text-sizing logic

HOUR 2: Templates + Icons
- Robert directs: pick 10-12 layouts, style them
- Load curated icon sets (Lucide + trade-specific)
- Normalize all icons to consistent viewBox/stroke

HOUR 3: Customization UI
- Color picker (from brand palette or custom)
- Font selector (15 curated fonts)
- Icon browser with trade filtering
- Tagline input
- Live preview updates

HOUR 4: Export Pipeline
- SVG → PNG at multiple sizes (flutter_svg + dart:ui)
- PDF export (vector, print-ready)
- Auto-generate all size variants
- Save to Supabase Storage (company_assets/{id}/logo/)
- ZIP download for "all sizes"

HOUR 5: Integration + AI
- Wire logo into website header, invoice, bid, client portal
- Opus recommendation endpoint (template + icon + color suggestions)
- Logo Manager screen (view, edit, download, brand colors)
- Favicon generation
```

### Database Schema

```sql
-- Company logo (one active logo per company)
CREATE TABLE company_logos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) UNIQUE,
  
  -- Template data (everything needed to re-render)
  template_id TEXT NOT NULL,               -- which layout template
  icon_id TEXT,                            -- which icon (nullable for text-only)
  company_name_display TEXT NOT NULL,      -- as displayed (may differ from legal name)
  tagline TEXT,
  
  -- Styling
  primary_color TEXT NOT NULL,             -- hex
  accent_color TEXT,                       -- hex
  background_color TEXT DEFAULT '#FFFFFF',
  font_family TEXT NOT NULL,
  font_weight TEXT DEFAULT 'bold',
  
  -- Generated assets (Supabase Storage paths)
  svg_path TEXT,                           -- master vector
  png_web_path TEXT,                       -- 400px wide
  png_print_path TEXT,                     -- 300 DPI
  png_square_path TEXT,                    -- 500×500
  png_favicon_path TEXT,                   -- 32×32
  pdf_path TEXT,                           -- print-ready vector
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: company_id isolation, Owner/Admin can edit
```

### Implementation Checklist

```
CORE ENGINE:
- [ ] SVG template renderer with variable slots
- [ ] Auto-text-sizing (short/medium/long company names)
- [ ] Live preview component (updates on every change)
- [ ] Color injection system
- [ ] Font loader (15 curated fonts, pre-bundled)

TEMPLATES:
- [ ] Design 10-12 layout templates (Badge, Underline, Icon Top, etc.)
- [ ] Responsive text logic per template
- [ ] Dark/light variant per template

ICON LIBRARY:
- [ ] Curate 30-50 icons per trade (8 trades = ~300 icons)
- [ ] Normalize all to consistent viewBox/stroke
- [ ] Organize by trade with search/filter
- [ ] Universal icons section (shields, banners, etc.)

CUSTOMIZATION UI:
- [ ] Step 1: Trade + company name input
- [ ] Step 2: AI-recommended template grid (top 8)
- [ ] Step 3: Customize (colors, icon, font, tagline)
- [ ] Live preview at every step
- [ ] "Show more layouts" for full template browser

EXPORT:
- [ ] SVG export (master vector)
- [ ] PNG export at web sizes (200, 400px)
- [ ] PNG export at print resolution (300 DPI)
- [ ] PNG square crop (500×500 for social)
- [ ] PNG favicon (32×32, 16×16)
- [ ] PDF export (vector, print-ready)
- [ ] "All Sizes" ZIP download
- [ ] Save all variants to Supabase Storage

INTEGRATION:
- [ ] Website header auto-populated from logo
- [ ] Favicon auto-generated
- [ ] Invoice/Bid header pulls company logo
- [ ] Client Portal header pulls company logo
- [ ] Email signature export
- [ ] Brand colors extracted and saved to company profile

AI (Opus):
- [ ] Template recommendation based on trade + name length
- [ ] Icon recommendation based on trade + services
- [ ] Color recommendation based on trade conventions
- [ ] Tagline generation (3-5 options)
- [ ] Layout critique (contrast, readability warnings)
```

---


**END OF WEBSITE BUILDER V2 SPEC — UPDATED FEBRUARY 5, 2026 (Session 29)**
**Added: Full Photo Management System (capture → approval → publish pipeline, RBAC, schema, processing)**
**Added: Logo Creator (template engine + icon library + typography + AI recommendations, ~5 hrs)**
**Added: CRM Website Manager Tab (full sub-tab architecture for day-to-day website management)**
**Added: AI Website Chat Widget (Claude-powered, fully contractor-configurable, lead capture)**
**Added: Professional Email (Cloudflare Email Routing, free, auto-setup)**
**Added: Legal Pages (auto-generated privacy policy, ToS, accessibility statement)**
**Added: Trust Badges & Credentials (auto-pulled from CRM data)**
**Added: Service Area Map + SEO pages (interactive map, auto-generated city pages)**
**Added: Pay Your Invoice portal (Stripe on contractor's domain)**
**Added: QR Code Generator (tracked, revenue-attributed physical marketing)**
**Added: Careers/Hiring Page (synced from HR module)**
**Added: Multi-Language Support (AI translation, Spanish priority)**
**Added: Seasonal/Promotional Banners (scheduled campaigns with tracking)**
**Added: Print Marketing Templates (business cards, yard signs, truck wraps, all branded)**
**Added: WCAG 2.1 AA Accessibility (built into templates, not bolted on)**
**Added: Full Supabase PostgreSQL schema (15 tables replacing Firestore collections)**
**Added: 8 new Edge Functions (chat, photos, legal, translate, email, QR, careers, payments)**
**NEXT: Template research with Robert**
