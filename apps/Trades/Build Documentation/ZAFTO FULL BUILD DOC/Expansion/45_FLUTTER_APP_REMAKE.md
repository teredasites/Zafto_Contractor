# 45 — ZAFTO Mobile App Remake

## Expansion Spec — Sprint R1 (Remake)
### Created: Session 75 (Feb 7, 2026)
### Status: SPEC COMPLETE — Execute after Phase D completes, before Phase E

---

## 1. WHY A REMAKE

The current Flutter app was built as an electrical trade tool. It has:
- Dead Toolbox section (calculators, code reference, exam prep, tables & data) — all scrapped, Z Intelligence replaces them
- Static navigation (Home/Tools/Jobs/Invoices/More) that doesn't reflect the platform's actual feature set
- ~1,500 Dart files with backend wiring (insurance, property management, compliance, Ledger, photos, voice notes, materials, daily logs) buried under a shell that doesn't surface most of it
- No role-based experience — an Owner and a Tech see the same app
- Design language from 2024 that doesn't match the premium web CRM and portals

The app needs to be remade from the app shell level — new navigation, new home screens, new design system, role-based experiences, and Z Intelligence woven into every surface. The existing backend wiring (repositories, services, models) is kept and reused. This is a shell/UX remake, not a rewrite.

---

## 2. DESIGN PHILOSOPHY

### Apple-Crisp Premium

The app should feel like it was built by Apple's design team for contractors. Clean, minimal, confident. Every pixel earns its place.

**Visual language:**
- Light mode default, dark mode as user preference
- White/near-white backgrounds (#FAFAFA) with strategic dark elements
- Typography: system fonts (SF Pro on iOS, Roboto on Android) — clean hierarchy through size and weight, not color overload
- Generous whitespace — let content breathe
- Subtle elevation/shadows (no harsh drop shadows)
- ZAFTO accent color for primary actions only (not splashed everywhere)
- Monochrome iconography (Lucide icons, consistent stroke weight)
- No gradients, no glossy effects, no skeuomorphism
- Information density: dense enough to be powerful, spaced enough to be scannable

**Interaction design:**
- Haptic feedback on all primary actions (light tap on selection, medium on confirm, heavy on destructive)
- Spring physics animations (iOS-native feel, not linear)
- Bottom sheets for contextual menus (iOS pattern)
- Swipe gestures: swipe-to-act on list items (archive, complete, call)
- Pull-to-refresh everywhere
- Large touch targets (minimum 44pt)
- Smooth page transitions (shared element hero animations where meaningful)
- Skeleton loading states (not spinners)

**Typography scale:**
| Use | Size | Weight |
|-----|------|--------|
| Page title | 28pt | Bold |
| Section header | 20pt | Semibold |
| Card title | 17pt | Semibold |
| Body | 15pt | Regular |
| Caption/metadata | 13pt | Regular, secondary color |
| Badge/chip | 12pt | Medium |

**Color system:**
| Token | Light Mode | Dark Mode | Use |
|-------|-----------|-----------|-----|
| background | #FAFAFA | #0A0A0A | Page background |
| surface | #FFFFFF | #1A1A1A | Cards, sheets |
| surfaceElevated | #FFFFFF | #242424 | Elevated cards, modals |
| textPrimary | #1A1A1A | #FAFAFA | Primary text |
| textSecondary | #6B7280 | #9CA3AF | Secondary text, metadata |
| accent | #FF6B35 | #FF8555 | Primary actions, ZAFTO brand |
| accentSubtle | #FFF3ED | #2A1A10 | Accent backgrounds |
| success | #10B981 | #34D399 | Complete, positive |
| warning | #F59E0B | #FBBF24 | Attention needed |
| destructive | #EF4444 | #F87171 | Delete, error |
| border | #E5E7EB | #2D2D2D | Dividers, borders |

---

## 3. ROLE-BASED ARCHITECTURE

### One App, Seven Experiences

ZAFTO is one download from the App Store. After login, the app adapts entirely based on the user's role. Different navigation, different home screen, different tools, different Z Intelligence behavior.

### Role Determination Flow

```
User opens app
  |
  v
Login (Supabase Auth)
  |
  v
Query user profile: role, company, permissions
  |
  v
Role-based routing:
  - owner / admin  →  Owner Experience
  - office          →  Office Manager Experience
  - tech            →  Tech/Field Experience
  - inspector       →  Inspector Experience
  - cpa             →  CPA Experience
  - client          →  Homeowner Experience
  - tenant          →  Tenant Experience
```

### Permission Overrides

Within each role, the company Owner/Admin can grant or restrict specific tools per user:
- Tech A can do walkthroughs, Tech B cannot
- Office manager can access Ledger summaries, or not
- Inspector can create deficiency work orders, or just report

Stored in `custom_roles` table (D6) with granular `permissions` JSONB.

### Role Switching

Some users may have multiple roles (e.g., an Owner who also does field work). Support role switching:
- Long-press profile avatar → "Switch to Field Mode" / "Switch to Business Mode"
- Persists as user preference
- No re-authentication needed

---

## 4. NAVIGATION ARCHITECTURE

### Adaptive Navigation Per Role

Each role has its own bottom tab bar with 4-5 contextually relevant tabs. The "More" tab provides access to everything else.

**Owner/Admin Tabs:**
| Tab | Icon | Content |
|-----|------|---------|
| Home | house | Business dashboard — revenue, pipeline, team, alerts |
| Jobs | briefcase | All jobs — pipeline view, filters, create new |
| Money | dollar-sign | Invoices + Bids + Ledger quick access |
| Calendar | calendar | Schedule — day/week/month, team assignments |
| More | menu | Everything else — customers, team, insurance, properties, settings |

**Tech/Field Tabs:**
| Tab | Icon | Content |
|-----|------|---------|
| Home | house | Today's work — assigned jobs, clock, weather |
| Walkthrough | scan-line | New walkthrough + recent walkthroughs |
| Jobs | briefcase | My jobs — today, upcoming, recent |
| Tools | wrench | Field tools — photos, time, safety, materials |
| More | menu | Everything else — receipts, mileage, certs, profile |

**Office Manager Tabs:**
| Tab | Icon | Content |
|-----|------|---------|
| Home | house | Office dashboard — today's schedule, overdue, leads |
| Schedule | calendar | Calendar + dispatch — assign crew to jobs |
| Customers | users | Customer management + leads pipeline |
| Money | dollar-sign | Invoices + Bids + Payments |
| More | menu | Everything else — reports, insurance, settings |

**Inspector Tabs:**
| Tab | Icon | Content |
|-----|------|---------|
| Home | house | Today's inspections — assigned, scheduled |
| Inspect | clipboard-check | Active inspection — checklist, photos, scoring |
| History | folder-open | Past inspections — search, reports, follow-ups |
| Tools | wrench | Code lookup, measurement tools, floor plan viewer |
| More | menu | Profile, certifications, settings |

**CPA Tabs:**
| Tab | Icon | Content |
|-----|------|---------|
| Dashboard | layout-dashboard | Financial overview — P&L, cash flow, alerts |
| Accounts | book-open | Chart of accounts + journal entries |
| Reports | bar-chart-3 | Financial reports — Schedule C/E, 1099, custom |
| Review | file-search | Expense/invoice/receipt review queue |

**Homeowner/Client Tabs:**
| Tab | Icon | Content |
|-----|------|---------|
| Home | house | My property — active projects, upcoming work |
| Scan | camera | Home scanner — photograph issues, AI diagnosis |
| Projects | folder | All projects — bids, jobs, invoices, history |
| My Home | building | Property details — floor plan, systems, maintenance log |
| More | menu | Documents, payments, contractor contact, settings |

**Tenant Tabs:**
| Tab | Icon | Content |
|-----|------|---------|
| Home | house | Unit dashboard — rent balance, next due, alerts |
| Rent | credit-card | Rent payments — balance, history, pay now |
| Maintenance | tool | Submit + track maintenance requests |
| My Unit | building | Unit details, lease info, inspections |

---

## 5. Z INTELLIGENCE — NOT A CHATBOT

### The Problem With Chatbots

Every app in 2026 has the same thing: a little chat bubble in the corner that opens a generic conversation window. Type a question, get a response, scroll through history. It's the same UX whether you're using a banking app or a food delivery app. It's lazy. It's expected. It's forgettable.

ZAFTO doesn't have a chatbot. **Z is the intelligence layer of the entire app.** It's woven into every screen, every action, every moment. You don't go TO Z — Z is already there.

### Three Modes of Z Intelligence

#### Mode 1: Voice-First (Hands-Free Field Intelligence)

**The scenario:** A tech is on a job site. Hands are dirty, maybe wearing gloves. They need to do something in the app.

**The interaction:**
- Press and hold the Z button (floating, always accessible) → speak → release
- OR: "Hey Z" wake word (optional, configurable in settings)
- Z processes the voice command and executes the action
- Confirmation appears as a brief toast/banner — not a chat message
- If Z needs clarification, it speaks back (audio) AND shows selection chips

**Voice commands by context:**

On any screen:
- "Add 12 sheets of half-inch drywall to the Smith job" → adds to materials
- "Clock me in on the Johnson kitchen remodel" → starts time entry
- "What's the NEC requirement for bathroom GFCI spacing?" → answers with audio + card
- "Take a photo and tag it to the kitchen" → opens camera, auto-tags
- "Schedule the Wilson inspection for next Tuesday at 9" → creates appointment
- "How many hours have I worked this week?" → answers
- "Create a maintenance request for unit 3B — leaking faucet in kitchen" → creates request

During walkthrough:
- "Next room — master bathroom" → advances to new room, names it
- "Add a note — water stain on ceiling approximately 4 by 6 feet" → adds text note
- "Tag this room as damage and demo" → applies condition tags
- "What's the Xactimate code for removing wet drywall?" → answers, offers to add line item

**Technical implementation:**
- Speech-to-text: iOS Speech framework (on-device for privacy + speed)
- Intent parsing: Claude API (Edge Function) for complex commands, local pattern matching for simple ones
- Text-to-speech: iOS AVSpeechSynthesizer for Z responses
- Context injection: current screen, active job/walkthrough/inspection, user role

#### Mode 2: Camera-First (Point and Intelligence)

**The scenario:** A tech, inspector, or homeowner is looking at something and needs to understand it.

**The interaction:**
- Long-press the Z button → camera activates with Z overlay
- Point at the thing → Z analyzes in real-time
- Results appear as an overlay card on the camera view
- Action buttons below: "Add to job", "Save photo", "Learn more", "Create work order"

**Camera intelligence by context:**

**For Techs:**
- Point at an electrical panel → Z reads the label, identifies brand/model, lists circuit capacity, links to spec sheet
- Point at a water heater → Z identifies make/model/year, checks warranty status, suggests replacement if old
- Point at damage → Z assesses type (water/fire/mold/impact), severity, affected materials, suggests Xactimate scope
- Point at a receipt → Z reads vendor, amount, date, categorizes, offers "Add to job expenses"
- Point at a nameplate/label → Z reads specs (voltage, amperage, model, serial) and saves to asset record
- Point at a wire → Z identifies gauge, insulation type, offers code compliance check

**For Inspectors:**
- Point at a code violation → Z identifies the issue, cites the relevant code section, severity rating
- Point at equipment → Z reads nameplate, checks install date vs useful life, notes for report
- Point at construction → Z assesses workmanship, identifies potential deficiencies

**For Homeowners:**
- Point at a crack → Z identifies type (settling, structural, cosmetic), urgency level, recommended action
- Point at a stain → Z identifies likely cause (water, mold, smoke), suggests next steps
- Point at equipment → Z identifies what it is, maintenance schedule, when to replace
- Point at a bug → Z identifies species, whether it indicates a problem, treatment options
- Point at a plant/tree → Z identifies if roots could affect foundation, if branches threaten roof

**Technical implementation:**
- Claude Vision API via Edge Function
- On-device pre-processing: crop, enhance, compress before upload
- Caching: similar items in same session don't re-query
- Offline fallback: save photo with "Analyze when connected" flag

#### Mode 3: Ambient Intelligence (Contextual Awareness)

**The scenario:** The user is doing their normal work. Z notices things and offers help — but never interrupts.

**The interaction:**
- Small contextual chips appear at the top or bottom of relevant screens
- Subtle animation to draw attention without disrupting workflow
- Tap to act, swipe to dismiss
- Z learns from dismissals — stops suggesting things the user always ignores

**Ambient suggestions by role:**

**For Techs:**
- On jobs screen: "You haven't clocked in today" (if past usual start time)
- During walkthrough: "Kitchen has 2 photos — recommended: at least 4 angles"
- During walkthrough: "No moisture reading for this room" (if insurance workflow)
- On materials: "You usually use 10% waste factor on drywall — add 2 more sheets?"
- After completing job: "Take completion photos before leaving?"
- End of day: "You have 3 unsigned daily logs this week"

**For Owners:**
- On dashboard: "3 invoices overdue > 30 days — $12,400 outstanding"
- On jobs: "Smith job is 20% over budget — review materials spend?"
- On bids: "Your win rate this month: 40% (vs 55% average) — pricing issue?"
- On team: "Mike hasn't clocked in — expected at Johnson job at 8am"
- On calendar: "Tomorrow has 3 overlapping jobs — need another crew?"

**For Inspectors:**
- On active inspection: "Previous inspection for this property found 3 deficiencies — review?"
- During photos: "North wall not photographed yet"
- On scoring: "This item typically fails in buildings this age — check carefully"

**For Homeowners:**
- On home screen: "HVAC filter due for replacement (last changed 90 days ago)"
- On home screen: "Annual roof inspection recommended (last: 14 months ago)"
- After scan: "This issue matches 3 similar cases — here's what other homeowners did"
- Seasonal: "Winter prep checklist: 5 items for your home type"

**Technical implementation:**
- Suggestion engine runs locally (rule-based for simple triggers, Claude for complex analysis)
- Each suggestion has a `priority` (info/attention/action) and `context` (screen, data state)
- Dismiss tracking: after 3 dismissals of same suggestion type, stop showing
- Configurable: user can toggle ambient suggestions off entirely

### Z Button (The Universal Entry Point)

A floating action button present on every screen (except during full-screen modes like walkthrough capture and camera).

**Single tap:** Quick action menu (role-specific)
**Long press:** Camera-first Z (point and identify)
**Press and hold:** Voice command mode

**Quick action menu (examples for Tech role):**
```
+----------------------------------+
|  Z Quick Actions                 |
|                                  |
|  [camera] Take Job Photo         |
|  [mic] Voice Command             |
|  [clock] Clock In/Out            |
|  [scan] Start Walkthrough        |
|  [receipt] Scan Receipt          |
|                                  |
|  Recent:                         |
|  > Added drywall to Smith job    |
|  > Clocked in at 7:42am         |
+----------------------------------+
```

The quick actions adapt based on:
- User's role
- Current screen context
- Time of day (morning → clock in, evening → clock out)
- Active job/walkthrough
- Recent actions (show last 2-3)

---

## 6. OWNER/ADMIN EXPERIENCE

### Home Screen — Business Command Center

```
+------------------------------------------+
|  Good morning, Damian          [avatar]   |
|  ZAFTO                         [bell]     |
+------------------------------------------+
|                                           |
|  TODAY                                    |
|  +-------------------------------------+ |
|  | Revenue Today    |  Revenue MTD     | |
|  | $4,280           |  $67,420         | |
|  | +12% vs avg      |  82% of target   | |
|  +-------------------------------------+ |
|                                           |
|  +-------------------------------------+ |
|  | Active Jobs: 8   | Crew Out: 5/7    | |
|  | Bids Pending: 3  | Overdue: 2       | |
|  +-------------------------------------+ |
|                                           |
|  NEEDS ATTENTION                    (...) |
|  +-------------------------------------+ |
|  | ! Invoice #1042 — 45 days overdue   | |
|  | ! Bid response due tomorrow (Wilson) | |
|  | ! Tech cert expiring in 14 days     | |
|  +-------------------------------------+ |
|                                           |
|  TODAY'S SCHEDULE                   (...) |
|  +-------------------------------------+ |
|  | 8:00  Smith Kitchen — Mike, Carlos   | |
|  | 9:30  Wilson Inspection — You        | |
|  | 1:00  Johnson Panel Upgrade — Mike   | |
|  +-------------------------------------+ |
|                                           |
|  RECENT ACTIVITY                    (...) |
|  | Payment received: $3,200 (Garcia)    | |
|  | New lead: Sarah Chen (referral)      | |
|  | Job completed: Park bathroom         | |
|                                           |
|  [Z button - floating]                    |
+------------------------------------------+
|  Home  |  Jobs  |  Money  |  Cal  | More |
+------------------------------------------+
```

### Owner Tool Inventory

| Category | Tools |
|----------|-------|
| **Business Dashboard** | Revenue tracking, KPI cards, pipeline funnel, team utilization, alerts |
| **Job Management** | Create/assign/track jobs, status pipeline, job detail with all linked data, bulk operations |
| **Customer Management** | Full CRM — contacts, history, notes, tags, lifetime value, linked jobs/invoices/bids |
| **Bid Management** | Create bids (manual + AI walkthrough), 3-tier pricing, send/track, win/loss tracking |
| **Invoice Management** | Create/send/track invoices, payment recording, aging report, recurring invoices |
| **Calendar/Scheduling** | Day/week/month views, drag-assign crew, availability tracking, conflict detection |
| **Team Management** | Roster, roles, permissions, time tracking overview, performance metrics, certifications |
| **Insurance Claims** | Full claim lifecycle, Xactimate estimate lines, supplements, moisture/drying, TPI |
| **Property Management** | Portfolio dashboard, units, tenants, leases, rent tracking, maintenance, inspections, assets |
| **Ledger** | Full financial — P&L, balance sheet, cash flow, GL, journal entries, tax mapping, 1099, bank recon |
| **Walkthroughs** | Create field walkthroughs, review AI-generated bids, send to customers |
| **Reports** | Revenue, profitability, job cost, team performance, insurance, property P&L, custom |
| **Leads** | Pipeline management, follow-up tracking, source attribution, conversion analytics |
| **Settings** | Company profile, team permissions, workflow templates, integrations, billing, notification prefs |
| **Z Intelligence** | Full access — voice, camera, ambient. Generate bids, invoices, reports. Analyze anything. |

---

## 7. TECH/FIELD EXPERIENCE

### Home Screen — Today's Work

```
+------------------------------------------+
|  Hey Mike                      [avatar]   |
|  Tuesday, Feb 7              [bell] [Z]   |
+------------------------------------------+
|                                           |
|  +-------------------------------------+ |
|  |  NOT CLOCKED IN                      | |
|  |  [====== SLIDE TO CLOCK IN ======>]  | |
|  +-------------------------------------+ |
|                                           |
|  TODAY'S JOBS                       (3)   |
|  +-------------------------------------+ |
|  | 8:00  Smith Kitchen Remodel          | |
|  |       423 Oak St — 2.3 mi     [nav]  | |
|  |       Status: In Progress       [>]  | |
|  +-------------------------------------+ |
|  | 1:00  Johnson Panel Upgrade          | |
|  |       891 Pine Ave — 5.1 mi   [nav]  | |
|  |       Status: Scheduled         [>]  | |
|  +-------------------------------------+ |
|  | 3:30  Park Bathroom Rough-In         | |
|  |       156 Elm Dr — 3.7 mi     [nav]  | |
|  |       Status: Scheduled         [>]  | |
|  +-------------------------------------+ |
|                                           |
|  QUICK ACTIONS                            |
|  +------+ +------+ +------+ +------+     |
|  |camera| | mic  | |clock | | scan |     |
|  |Photo | |Voice | |Time  | |Walk- |     |
|  |      | |Note  | |      | |thru  |     |
|  +------+ +------+ +------+ +------+     |
|                                           |
|  THIS WEEK                                |
|  | Hours: 24.5 / 40      [||||||||   ]   | |
|  | Jobs completed: 4                     | |
|  | Miles: 87                             | |
|                                           |
+------------------------------------------+
| Home | Walk | Jobs | Tools | More         |
+------------------------------------------+
```

### Tech Tool Inventory

| Category | Tools |
|----------|-------|
| **My Jobs** | Today's assignments, upcoming, recent completed, job detail (scope, customer, location, linked data) |
| **Walkthrough/Bid Capture** | Full room-by-room walkthrough (see spec 44), LiDAR, photos, sketches, annotations |
| **Time Tracking** | Clock in/out per job, break tracking, daily summary, weekly total, GPS verification |
| **Job Site Photos** | Camera with auto-tagging to active job/room, annotation tools, before/after linking |
| **Voice Notes** | Record → auto-transcribe → attach to job/room, searchable, playback |
| **Materials Tracker** | Log materials used per job, barcode/photo scan to add, running cost total |
| **Daily Log** | End-of-day summary — work done, conditions, crew present, equipment used, notes |
| **Safety Compliance** | LOTO Logger (lock/unlock with photo proof), Safety Briefings (crew sign-in + topics), Incident Reports (guided form + photos → PDF), Confined Space Monitor (time tracking + air monitoring log) |
| **Receipts** | Camera capture → AI reads vendor/amount/date → categorize → attach to job |
| **Mileage** | GPS auto-tracking per trip, link to job, purpose tagging, tax export |
| **Level & Plumb** | Digital level using phone sensors, save readings to job/room |
| **Punch List** | View assigned punch items, mark complete with photo proof, add new items |
| **Change Orders** | View change orders for active jobs, acknowledge/sign, view scope changes |
| **Insurance Field Work** | Moisture readings (manual or meter Bluetooth), drying log entries, equipment deployment tracking |
| **Property Maintenance** | View assigned maintenance work orders with tenant/unit/property context |
| **Certifications** | View own certs, expiration dates, upload renewals |
| **Client Signatures** | Capture signatures on completion, change orders, safety docs — legal record |
| **Z Intelligence** | Voice-first for hands-free commands, camera-first for identification, ambient for suggestions |

### Tech Tools Screen Layout

```
+------------------------------------------+
|  Field Tools                              |
+------------------------------------------+
|                                           |
|  JOB SITE                                 |
|  +--------+ +--------+ +--------+        |
|  |[camera]| |  [mic] | |[ruler] |        |
|  | Photos | | Voice  | | Level  |        |
|  |        | | Notes  | | Plumb  |        |
|  +--------+ +--------+ +--------+        |
|  +--------+ +--------+ +--------+        |
|  |[boxes] | |[scroll]| |[pen]   |        |
|  |Material| | Daily  | | Punch  |        |
|  |Tracker | |  Log   | |  List  |        |
|  +--------+ +--------+ +--------+        |
|                                           |
|  SAFETY                                   |
|  +--------+ +--------+ +--------+        |
|  | [lock] | |[shield]| |[alert] |        |
|  |  LOTO  | | Safety | |Incident|        |
|  | Logger | |Briefing| | Report |        |
|  +--------+ +--------+ +--------+        |
|  +--------+                               |
|  |[clock] |                               |
|  |Confined|                               |
|  | Space  |                               |
|  +--------+                               |
|                                           |
|  FINANCIAL                                |
|  +--------+ +--------+ +--------+        |
|  |[receipt| |  [car] | |[pen-   |        |
|  |Scanner | |Mileage | | tool]  |        |
|  |        | |Tracker | |Signatur|        |
|  +--------+ +--------+ +--------+        |
|                                           |
|  INSURANCE (if job is insurance type)     |
|  +--------+ +--------+ +--------+        |
|  |[droplt]| |[thermo]| |[truck] |        |
|  |Moisture| | Drying | | Equip  |        |
|  |Reading | |  Log   | |Tracking|        |
|  +--------+ +--------+ +--------+        |
|                                           |
+------------------------------------------+
```

---

## 8. OFFICE MANAGER EXPERIENCE

### Home Screen — Office Command

```
+------------------------------------------+
|  Good morning, Sarah           [avatar]   |
|  ZAFTO Office                  [bell]     |
+------------------------------------------+
|                                           |
|  TODAY AT A GLANCE                        |
|  +-------------------------------------+ |
|  | Jobs Today: 6  | Crew Out: 5        | |
|  | Unassigned: 1  | Calls Due: 3       | |
|  +-------------------------------------+ |
|                                           |
|  ACTION REQUIRED                    (...) |
|  +-------------------------------------+ |
|  | ! New lead — Sarah Chen (web form)   | |
|  | ! Invoice #1042 — follow up today    | |
|  | ! Bid response due — Wilson kitchen   | |
|  | ! Schedule conflict — 2pm overlap     | |
|  +-------------------------------------+ |
|                                           |
|  TODAY'S SCHEDULE                   (...) |
|  | 8:00 Smith Kitchen — Mike, Carlos     | |
|  | 9:00 Wilson Estimate — (unassigned!)  | |
|  | 1:00 Johnson Panel — Mike             | |
|  | 2:00 Chen Consultation — You          | |
|  +-------------------------------------+ |
|                                           |
|  RECENT MESSAGES                    (...) |
|  | Garcia: "When will the crew arrive?"  | |
|  | Mike: "Running 15 min late to Smith"  | |
|                                           |
+------------------------------------------+
| Home | Sched | Cust | Money | More        |
+------------------------------------------+
```

### Office Manager Tool Inventory

| Category | Tools |
|----------|-------|
| **Office Dashboard** | Today's schedule, action items, unassigned jobs, overdue follow-ups, recent messages |
| **Calendar/Dispatch** | Full calendar (day/week/month), drag-assign crew, availability view, route map, conflict alerts |
| **Customer Management** | Full CRUD — contacts, communication history, notes, tags, preferences, linked jobs/bids/invoices |
| **Lead Management** | Pipeline view (stages), follow-up reminders, source tracking, convert lead → customer + job |
| **Bid Management** | Create/edit/send bids, track responses, follow up, clone templates, markup control |
| **Invoice Management** | Create/send invoices, record payments, aging tracking, reminders, recurring setup |
| **Job Overview** | View all jobs with filters, status tracking, basic editing (no field tools) |
| **Communications** | Call log, message history per customer, scheduled follow-ups, email/SMS templates |
| **Reports** | Revenue summary, job status, aging, lead conversion, basic financials |
| **Insurance Claims** | Claim status tracking, supplement submissions, communication log, TPI scheduling |
| **Z Intelligence** | Document generation (bids, invoices, emails), scheduling help, customer research, lead prioritization |

---

## 9. INSPECTOR EXPERIENCE

### Home Screen — Today's Inspections

```
+------------------------------------------+
|  Inspections Today              [avatar]  |
|  Tuesday, Feb 7                [bell]     |
+------------------------------------------+
|                                           |
|  ASSIGNED TODAY                      (4)  |
|  +-------------------------------------+ |
|  | 8:30  Electrical Rough-In            | |
|  |       Smith Kitchen — 423 Oak St     | |
|  |       Type: Code Compliance          | |
|  |       Checklist: 24 items     [GO >] | |
|  +-------------------------------------+ |
|  | 10:00  Final Inspection              | |
|  |       Park Bathroom — 156 Elm Dr     | |
|  |       Type: Final Sign-Off           | |
|  |       Checklist: 32 items     [GO >] | |
|  +-------------------------------------+ |
|  | 1:30  Property Condition             | |
|  |       Unit 3B — 890 Maple Ct        | |
|  |       Type: Move-Out                 | |
|  |       Checklist: 18 items     [GO >] | |
|  +-------------------------------------+ |
|  | 3:00  Insurance Re-Inspection        | |
|  |       Wilson Home — 67 Birch Ln      | |
|  |       Type: TPI Follow-Up            | |
|  |       Previous: 3 deficiencies [GO >]| |
|  +-------------------------------------+ |
|                                           |
|  THIS WEEK                                |
|  | Completed: 7  |  Pending: 4          | |
|  | Pass rate: 71% | Avg score: 84       | |
|                                           |
+------------------------------------------+
| Home | Inspect | History | Tools | More   |
+------------------------------------------+
```

### Inspector Tool Inventory

| Category | Tools |
|----------|-------|
| **My Inspections** | Today's assignments, upcoming schedule, assigned by company/region |
| **Active Inspection** | Full inspection workflow (see below) |
| **Inspection History** | Past inspections searchable by property/customer/date/type/result, re-inspection links |
| **Code Lookup** | AI-powered code reference — NEC, IRC, IPC, IMC, local amendments. Ask in natural language, get cited answers. |
| **Photo Documentation** | Camera with deficiency marking, annotation tools, auto-categorization, comparison to previous inspection |
| **Floor Plan Viewer** | View property floor plan, mark inspection points per room, pin deficiencies to locations |
| **Measurement Tools** | LiDAR dimensions, tape measure entry, clearance verification, spacing checks |
| **Report Generator** | Auto-generate professional inspection report from checklist + photos + notes |
| **Deficiency Tracker** | Track open deficiencies across inspections, follow-up status, link to corrective work orders |
| **Previous Inspections** | For re-inspections: side-by-side comparison, verify corrective work, photo before/after |
| **Z Intelligence** | Code questions (instant), photo analysis (is this up to code?), report writing, deficiency severity assessment |

### Active Inspection Workflow

The inspection screen is a purpose-built tool, not a generic form.

```
+------------------------------------------+
|  Electrical Rough-In Inspection           |
|  Smith Kitchen — 423 Oak St              |
|  Started: 8:34am            [pause] [X]  |
+------------------------------------------+
|  Progress: 8/24 items          33%       |
|  [========--------------------------]     |
+------------------------------------------+
|                                           |
|  GENERAL                           (3/3) |
|  [x] Permits posted and visible     PASS |
|  [x] Plans on site and current      PASS |
|  [x] Work area accessible           PASS |
|                                           |
|  PANEL / SERVICE                   (2/4) |
|  [x] Panel properly secured         PASS |
|  [x] Working clearance (30"x36")    PASS |
|  [ ] Grounding electrode system          |
|  [ ] Service disconnect accessible       |
|                                           |
|  BRANCH CIRCUITS                   (3/8) |
|  [x] Wire sizing matches breakers   PASS |
|  [!] Junction boxes accessible      FAIL |
|      Photo: [thumbnail]                  |
|      Note: "JB behind drywall at NW..."  |
|      Code: NEC 314.29                    |
|      Severity: [Major]                   |
|  [x] Proper wire support/stapling   PASS |
|  [ ] GFCI protection — kitchen           |
|  [ ] GFCI protection — bathroom          |
|  [ ] AFCI protection — bedrooms          |
|  [ ] Dedicated circuits (fridge, DW...)  |
|  [ ] Smoke/CO detector circuits          |
|                                           |
|  [Take Photo]  [Add Note]  [Code Lookup] |
+------------------------------------------+
```

**Per checklist item, the inspector can:**
1. **Pass** — tap once, checkmark, moves to next
2. **Fail** — tap to mark deficiency → camera opens → take photo → add note → cite code → set severity (minor/major/critical)
3. **N/A** — not applicable to this inspection
4. **Conditional** — passes with conditions noted
5. **Skip** — come back to it (tracked as incomplete)

**Checklists are configurable:**
- Company creates inspection templates in Web CRM (Settings > Inspection Templates)
- Templates per type: rough-in, final, property condition, insurance, annual, code compliance
- Trade-specific sections: electrical, plumbing, HVAC, structural, fire/safety, general
- Items can be required or optional
- Pass criteria can include measurement thresholds (e.g., "GFCI trips within 25ms")

**Deficiency workflow:**
```
Inspector marks item as FAIL
  |
  v
Camera opens → capture deficiency photo
  |
  v
Annotation tools → mark the specific issue on the photo
  |
  v
Z suggests: code citation, severity, corrective action
  |
  v
Inspector confirms/edits → deficiency saved
  |
  v
After inspection: deficiencies compiled into report
  |
  v
Option: "Create Work Order" → maintenance request or job created for each deficiency
  |
  v
Re-inspection scheduled → inspector sees previous deficiencies highlighted
```

**Scoring:**
- Auto-calculated from pass/fail/conditional counts
- Weighted scoring (critical items worth more than minor)
- Overall result: Pass / Conditional Pass / Fail
- Score thresholds configurable per template

---

## 10. HOMEOWNER/CLIENT EXPERIENCE

### Home Screen — My Property

```
+------------------------------------------+
|  Welcome home, Jessica         [avatar]   |
|  423 Oak St, Miami FL          [bell]     |
+------------------------------------------+
|                                           |
|  ACTIVE PROJECTS                    (1)   |
|  +-------------------------------------+ |
|  | Kitchen Remodel                      | |
|  | ZAFTO Electrical — In Progress       | |
|  | Est. completion: Feb 28              | |
|  | [||||||||||||--------]  65%          | |
|  |                           [View >]   | |
|  +-------------------------------------+ |
|                                           |
|  NEEDS YOUR ATTENTION               (2)  |
|  +-------------------------------------+ |
|  | Invoice #1042 — $3,200 due          | |
|  |                     [Pay Now]        | |
|  +-------------------------------------+ |
|  | New bid from ZAFTO — Panel Upgrade   | |
|  |              [View] [Approve]        | |
|  +-------------------------------------+ |
|                                           |
|  HOME HEALTH                              |
|  +-------------------------------------+ |
|  | [check] HVAC filter — Changed 45d   | |
|  | [warn]  Roof inspection — Due (14mo) | |
|  | [check] Water heater — 3 yrs old    | |
|  | [check] Smoke detectors — Tested 2mo | |
|  +-------------------------------------+ |
|                                           |
|  SCAN SOMETHING                           |
|  +-------------------------------------+ |
|  | [camera icon]                        | |
|  | See something wrong?                 | |
|  | Point your camera at it.             | |
|  |              [Open Scanner >]        | |
|  +-------------------------------------+ |
|                                           |
+------------------------------------------+
| Home | Scan | Projects | MyHome | More    |
+------------------------------------------+
```

### Homeowner Tool Inventory

| Category | Tools |
|----------|-------|
| **Property Dashboard** | Active projects, action items (invoices, bids), home health indicators |
| **Home Scanner** | Photograph issues → AI diagnosis → urgency → research → one-tap contractor request (see below) |
| **Project Tracking** | All jobs: active, upcoming, completed. Per-project: status, timeline, photos, invoices, crew info |
| **Bid Review** | View bids with full scope detail, option comparison (good/better/best), approve/reject/request changes |
| **Invoices & Payments** | View invoices, pay via Stripe, payment history, receipt download |
| **Maintenance Requests** | Submit new requests (photo + description + urgency), track existing, rate completed work |
| **My Home Profile** | Property details, floor plan viewer, system inventory (HVAC, water heater, panel, appliances), maintenance log |
| **Home Health Monitor** | AI-generated maintenance reminders, seasonal checklists, system age tracking, replacement planning |
| **Inspections** | View completed inspection reports for their property, deficiency status |
| **Insurance Claims** | Track claim status if applicable, view estimates, supplement history |
| **Documents** | Contracts, warranties, permits, receipts, inspection reports — all in one place |
| **Contractor Contact** | Direct communication with their ZAFTO contractor, schedule requests |
| **Z Intelligence** | Home diagnosis from scans, maintenance advice, cost estimates, "what is this?" tool, seasonal guidance |

### Home Scanner (Deep Dive)

The Home Scanner is the homeowner's most powerful tool. It turns their phone into a property diagnostic device.

**Flow:**
```
Homeowner sees something concerning
  |
  v
Opens Scanner (Scan tab or Z button long-press)
  |
  v
Points camera at the issue
  |
  v
Z analyzes in real-time:
  - Identifies the problem (crack, stain, leak, mold, pest, wear)
  - Assesses severity (cosmetic / monitor / needs attention / urgent)
  - Explains in plain language what it likely is
  |
  v
Result card appears:
  +---------------------------------------------+
  | WATER STAIN — Ceiling                        |
  |                                              |
  | Severity: NEEDS ATTENTION                    |
  | Likely cause: Roof leak or plumbing above    |
  |                                              |
  | What this means:                             |
  | Water is or was entering from above this     |
  | spot. The stain pattern suggests a slow      |
  | leak, not a burst pipe. Check for:           |
  | - Active dripping (is it wet now?)           |
  | - Soft/spongy drywall around the stain       |
  | - Similar stains in adjacent rooms           |
  |                                              |
  | [Save to Home Log]                           |
  | [Research This More]                         |
  | [Request Contractor Visit]  <-- ONE TAP      |
  +---------------------------------------------+
  |
  v
If "Request Contractor Visit":
  - Photo auto-attached
  - AI diagnosis included as note
  - Urgency pre-set from severity
  - Maintenance request created → sent to contractor
  |
  v
Contractor (ZAFTO user) sees request in their app/CRM
with the homeowner's photo and AI diagnosis already attached
```

**Research Mode:**
When the homeowner taps "Research This More":
- Z provides deeper information about the issue
- Common causes, typical repair costs, DIY vs professional assessment
- Similar cases from ZAFTO's data (anonymized)
- "Questions to ask your contractor"
- Related issues to check for
- Whether this is likely covered by homeowner's insurance

**Home Health Monitor:**
Z Intelligence runs periodic analysis on the homeowner's property data:
- System ages (water heater installed 2018 = 8 years old, typical life 10-12 years)
- Maintenance schedules (HVAC filter every 90 days, roof inspection every 2 years)
- Seasonal checklists (winterize irrigation, clean gutters, inspect weatherstripping)
- Pushed as ambient notifications, not intrusive
- Tapping a reminder → one-tap schedule with their ZAFTO contractor

**The retention engine:**
Every scan, every reminder, every maintenance log entry keeps the homeowner IN the ZAFTO ecosystem. When they need work done, they don't Google "electrician near me" — they tap "Request Contractor Visit" and it goes straight to their ZAFTO contractor. Zero customer acquisition cost for the contractor. Lifetime relationship maintained through the app.

---

## 11. CPA EXPERIENCE

### Home Screen — Financial Command

```
+------------------------------------------+
|  Ledger                        [avatar]   |
|  ZAFTO Electrical LLC          [period]   |
+------------------------------------------+
|                                           |
|  PERIOD: January 2026                     |
|                                           |
|  +-------------------------------------+ |
|  | Revenue      | Expenses    | Net     | |
|  | $142,680     | $98,430     | $44,250 | |
|  +-------------------------------------+ |
|                                           |
|  REVIEW QUEUE                        (7)  |
|  +-------------------------------------+ |
|  | 3 Expenses awaiting categorization   | |
|  | 2 Receipts awaiting review           | |
|  | 1 Bank transaction unreconciled      | |
|  | 1 1099 vendor needs TIN              | |
|  +-------------------------------------+ |
|                                           |
|  QUICK REPORTS                            |
|  +--------+ +--------+ +--------+        |
|  | P&L    | |Bal Sht | |Cash Fl |        |
|  | Income | |Assets/ | |In/Out  |        |
|  | Stmt   | |Liab    | |Flow    |        |
|  +--------+ +--------+ +--------+        |
|  +--------+ +--------+ +--------+        |
|  |Sched C | |Sched E | | 1099   |        |
|  |  Tax   | |Rental  | |Complnce|        |
|  +--------+ +--------+ +--------+        |
|                                           |
+------------------------------------------+
| Dash | Accounts | Reports | Review        |
+------------------------------------------+
```

### CPA Tool Inventory

| Category | Tools |
|----------|-------|
| **Financial Dashboard** | Period summary (revenue/expenses/net), review queue, alerts |
| **Chart of Accounts** | Browse/search all accounts, balances, drill into transactions |
| **Journal Entries** | View/create/search journal entries, reversing entries, adjustments |
| **Financial Reports** | P&L, Balance Sheet, Cash Flow, Trial Balance, GL Detail — all with date range/comparison |
| **Tax Reports** | Schedule C, Schedule E (rental), 1099 compliance, tax category mapping |
| **Expense Review** | Review queue for uncategorized expenses, approve/recategorize, attach receipts |
| **Invoice Review** | Read-only invoice list, aging report, payment status |
| **Receipt Review** | AI-read receipts awaiting confirmation, categorization, approval |
| **Bank Reconciliation** | Match bank transactions to journal entries, flag discrepancies |
| **Vendor Management** | 1099 vendors, TIN tracking, payment history, annual totals |

---

## 12. TENANT EXPERIENCE

### Home Screen — My Unit

```
+------------------------------------------+
|  423 Oak St, Unit 3B          [avatar]    |
|  Maple Court Apartments        [bell]     |
+------------------------------------------+
|                                           |
|  RENT                                     |
|  +-------------------------------------+ |
|  | Balance Due: $1,450.00               | |
|  | Due: February 15, 2026               | |
|  | Status: 8 days remaining             | |
|  |                          [Pay Now >] | |
|  +-------------------------------------+ |
|                                           |
|  MAINTENANCE                              |
|  +-------------------------------------+ |
|  | Active Request:                      | |
|  | Kitchen faucet dripping              | |
|  | Submitted: Feb 3 — In Progress       | |
|  | Tech: Mike R. — ETA: Tomorrow 10am   | |
|  |                           [Track >]  | |
|  +-------------------------------------+ |
|  |                  [New Request >]      | |
|                                           |
|  LEASE                                    |
|  +-------------------------------------+ |
|  | Lease expires: Aug 31, 2026          | |
|  | 205 days remaining                   | |
|  |                          [Details >] | |
|  +-------------------------------------+ |
|                                           |
+------------------------------------------+
| Home |  Rent  | Maintenance | My Unit     |
+------------------------------------------+
```

### Tenant Tool Inventory

| Category | Tools |
|----------|-------|
| **Unit Dashboard** | Rent balance, active maintenance, lease countdown |
| **Rent** | Current balance, charge history, payment history, pay via Stripe, receipt download |
| **Maintenance** | Submit request (photo + description + urgency), track status, timeline, rate completion |
| **Lease** | Lease terms, expiry date, documents, renewal info |
| **Unit Info** | Unit details, emergency contacts, building rules, parking info |
| **Inspections** | View completed move-in/move-out inspections |

---

## 13. REMOVED FEATURES

### Toolbox Section — REMOVED
- Calculators (36 trade tools) — REMOVED. Z Intelligence handles calculations conversationally.
- Code Reference (NEC 2023) — REMOVED. Z Intelligence provides code lookup with natural language.
- Tables & Data (ampacity, derating) — REMOVED. Z Intelligence retrieves and explains.
- Exam Prep (4,000+ questions) — REMOVED. Not core to the platform's mission.

**Replacement:** Z Intelligence (voice-first, camera-first, ambient) replaces all static reference tools with a dynamic, contextual, intelligent experience.

---

## 14. DATA ARCHITECTURE

### New Tables

**`app_user_preferences`** — Per-user app configuration
```sql
CREATE TABLE app_user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) UNIQUE,
  company_id UUID NOT NULL REFERENCES companies(id),
  -- App experience
  active_role TEXT NOT NULL DEFAULT 'tech',  -- Which role experience they're using
  theme TEXT NOT NULL DEFAULT 'light' CHECK (theme IN ('light','dark','system')),
  -- Z Intelligence
  z_voice_enabled BOOLEAN DEFAULT true,
  z_wake_word_enabled BOOLEAN DEFAULT false,
  z_ambient_suggestions BOOLEAN DEFAULT true,
  z_camera_enabled BOOLEAN DEFAULT true,
  -- Notifications
  notification_sound BOOLEAN DEFAULT true,
  notification_haptics BOOLEAN DEFAULT true,
  -- Navigation
  quick_actions JSONB DEFAULT '[]'::jsonb,  -- User's pinned quick actions
  recent_actions JSONB DEFAULT '[]'::jsonb, -- Last 10 Z actions
  -- Feature flags
  features_dismissed JSONB DEFAULT '[]'::jsonb, -- Ambient suggestions dismissed 3+ times
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: user can only access their own
```

**`inspection_templates`** — Configurable inspection checklists
```sql
CREATE TABLE inspection_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  inspection_type TEXT NOT NULL
    CHECK (inspection_type IN ('code_compliance','rough_in','final','property_condition',
      'move_in','move_out','annual','insurance','tpi','custom')),
  trade TEXT,  -- 'electrical','plumbing','hvac','general', NULL = all trades
  sections JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- sections: [{ name, items: [{ label, required, passThreshold?, measurementType? }] }]
  scoring_config JSONB DEFAULT '{}'::jsonb,
  -- { passingScore: 80, criticalItemsRequired: true, weightedScoring: false }
  is_system BOOLEAN DEFAULT false,
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company-scoped, is_system readable by all
```

**`inspection_results`** — Completed inspection data
```sql
CREATE TABLE inspection_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  inspector_id UUID NOT NULL REFERENCES auth.users(id),
  template_id UUID REFERENCES inspection_templates(id),
  -- Links
  property_id UUID REFERENCES properties(id),
  unit_id UUID REFERENCES units(id),
  job_id UUID REFERENCES jobs(id),
  customer_id UUID REFERENCES customers(id),
  walkthrough_id UUID REFERENCES walkthroughs(id),
  -- Results
  result TEXT NOT NULL DEFAULT 'pending'
    CHECK (result IN ('pending','in_progress','pass','conditional_pass','fail')),
  score NUMERIC(5,2),
  total_items INTEGER DEFAULT 0,
  passed_items INTEGER DEFAULT 0,
  failed_items INTEGER DEFAULT 0,
  conditional_items INTEGER DEFAULT 0,
  na_items INTEGER DEFAULT 0,
  -- Data
  checklist_data JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- [{ itemId, label, result, photo?, note?, codeRef?, severity?, deficiencyId? }]
  deficiency_count INTEGER DEFAULT 0,
  -- Re-inspection
  previous_inspection_id UUID REFERENCES inspection_results(id),
  re_inspection_of UUID REFERENCES inspection_results(id),
  -- Report
  report_url TEXT,  -- Generated PDF storage path
  -- Timestamps
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company-scoped
CREATE INDEX idx_inspection_results_property ON inspection_results(property_id);
CREATE INDEX idx_inspection_results_inspector ON inspection_results(inspector_id);
```

**`inspection_deficiencies`** — Individual deficiency records
```sql
CREATE TABLE inspection_deficiencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  inspection_id UUID NOT NULL REFERENCES inspection_results(id),
  -- Deficiency detail
  item_label TEXT NOT NULL,
  description TEXT NOT NULL,
  code_reference TEXT,           -- e.g., 'NEC 314.29'
  severity TEXT NOT NULL DEFAULT 'minor'
    CHECK (severity IN ('minor','major','critical')),
  -- Photos
  photo_urls TEXT[] DEFAULT '{}',
  annotated_photo_urls TEXT[] DEFAULT '{}',
  -- Location
  room_name TEXT,
  floor_plan_position JSONB,    -- Pin on floor plan
  -- Resolution
  status TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open','work_ordered','in_progress','resolved','waived')),
  work_order_job_id UUID REFERENCES jobs(id),
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES auth.users(id),
  resolution_notes TEXT,
  resolution_photo_urls TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company-scoped
CREATE INDEX idx_deficiencies_inspection ON inspection_deficiencies(inspection_id);
CREATE INDEX idx_deficiencies_status ON inspection_deficiencies(status) WHERE status != 'resolved';
```

**`home_scan_logs`** — Homeowner scan history
```sql
CREATE TABLE home_scan_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  property_id UUID REFERENCES properties(id),
  -- Scan data
  photo_url TEXT NOT NULL,
  annotated_photo_url TEXT,
  location_in_home TEXT,         -- 'kitchen ceiling', 'bathroom wall', etc.
  -- AI analysis
  ai_diagnosis JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- { issue, severity, likelyCause, explanation, recommendations, urgencyLevel }
  -- Action taken
  action TEXT DEFAULT 'logged'
    CHECK (action IN ('logged','researched','contractor_requested','resolved','dismissed')),
  maintenance_request_id UUID REFERENCES maintenance_requests(id),
  -- Timestamps
  scanned_at TIMESTAMPTZ DEFAULT now(),
  resolved_at TIMESTAMPTZ
);
-- RLS: user can only access their own
CREATE INDEX idx_home_scans_user ON home_scan_logs(user_id);
CREATE INDEX idx_home_scans_property ON home_scan_logs(property_id);
```

**`home_maintenance_reminders`** — AI-generated maintenance schedule
```sql
CREATE TABLE home_maintenance_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  property_id UUID REFERENCES properties(id),
  -- Reminder
  title TEXT NOT NULL,            -- 'Replace HVAC filter'
  description TEXT,               -- 'Recommended every 90 days for standard filters'
  category TEXT NOT NULL DEFAULT 'general'
    CHECK (category IN ('hvac','plumbing','electrical','roofing','exterior',
      'appliance','safety','seasonal','general')),
  -- Schedule
  frequency_days INTEGER,         -- NULL = one-time
  last_completed TIMESTAMPTZ,
  next_due TIMESTAMPTZ NOT NULL,
  -- Status
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','snoozed','completed','dismissed')),
  snooze_until TIMESTAMPTZ,
  -- Source
  source TEXT DEFAULT 'ai_generated'
    CHECK (source IN ('ai_generated','manual','system')),
  asset_id UUID REFERENCES property_assets(id),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: user can only access their own
CREATE INDEX idx_reminders_user_due ON home_maintenance_reminders(user_id, next_due)
  WHERE status = 'pending';
```

### Summary: New Tables for App Remake

| Table | Purpose | Role |
|-------|---------|------|
| `app_user_preferences` | Per-user app config, Z settings, theme | All |
| `inspection_templates` | Configurable inspection checklists | Inspector |
| `inspection_results` | Completed inspection data with scoring | Inspector |
| `inspection_deficiencies` | Individual deficiency records with resolution tracking | Inspector |
| `home_scan_logs` | Homeowner scan history with AI diagnosis | Homeowner |
| `home_maintenance_reminders` | AI-generated maintenance schedule | Homeowner |

**Total: 6 new tables**

---

## 15. BUILD PHASES

### Sprint R1a: Design System + App Shell (~12 hrs)
- [ ] Define Flutter design system: colors, typography, spacing, elevation, animation curves
- [ ] Create reusable component library: ZCard, ZButton, ZTextField, ZBottomSheet, ZChip, ZBadge, ZAvatar, ZSkeleton
- [ ] Build adaptive app shell with role-based routing
- [ ] Bottom navigation factory (returns correct tabs per role)
- [ ] Role switching mechanism (long-press avatar)
- [ ] Light/dark theme system
- [ ] Z button (floating action button) — tap/long-press/hold handlers
- [ ] Remove dead Toolbox section, all static content screens
- [ ] Commit: `[R1a] App remake — design system + adaptive shell`

### Sprint R1b: Owner/Admin Experience (~14 hrs)
- [ ] Owner home screen (revenue cards, needs attention, today's schedule, recent activity)
- [ ] Updated Jobs tab (pipeline view, filters, search)
- [ ] Money tab (invoices + bids + Ledger quick access)
- [ ] Calendar tab (day/week/month, team assignments)
- [ ] More menu (customers, team, insurance, properties, reports, leads, settings)
- [ ] All screens use new design system components
- [ ] Commit: `[R1b] Owner/Admin experience — business command center`

### Sprint R1c: Tech/Field Experience (~14 hrs)
- [ ] Tech home screen (clock in/out slider, today's jobs, quick actions, weekly stats)
- [ ] Updated Walkthrough tab (prominent entry point)
- [ ] Updated Jobs tab (my jobs only, today focus)
- [ ] Tools screen (organized by category: job site, safety, financial, insurance)
- [ ] Quick actions menu (role-aware, context-aware, recent actions)
- [ ] Rewire all existing field tools to new design system
- [ ] Commit: `[R1c] Tech/Field experience — field-first tools`

### Sprint R1d: Office Manager Experience (~10 hrs)
- [ ] Office home screen (today at a glance, action required, schedule, messages)
- [ ] Schedule tab (calendar + dispatch view)
- [ ] Customers tab (full CRM + leads)
- [ ] Money tab (invoices + bids + payments)
- [ ] Communications integration (call log, messages)
- [ ] Commit: `[R1d] Office Manager experience — office command`

### Sprint R1e: Inspector Experience (~14 hrs)
- [ ] Deploy `inspection_templates` + `inspection_results` + `inspection_deficiencies` tables
- [ ] Seed system inspection templates (code compliance, rough-in, final, property condition, etc.)
- [ ] Inspector home screen (today's inspections, weekly stats)
- [ ] Active inspection screen (checklist workflow with pass/fail/conditional per item)
- [ ] Deficiency capture flow (fail → photo → annotate → code cite → severity → save)
- [ ] Inspection history (search, filter, re-inspection links)
- [ ] Code lookup tool (Z-powered, natural language → cited code sections)
- [ ] Floor plan integration (mark inspection points, pin deficiencies)
- [ ] Report generation (auto-generate PDF from completed inspection)
- [ ] Deficiency tracker (open items across inspections, work order creation)
- [ ] Inspection hooks for Web CRM (view/manage inspections from office)
- [ ] Commit: `[R1e] Inspector experience — full inspection toolkit`

### Sprint R1f: Homeowner/Client Experience (~12 hrs)
- [ ] Deploy `home_scan_logs` + `home_maintenance_reminders` tables
- [ ] Homeowner home screen (active projects, needs attention, home health, scan CTA)
- [ ] Home Scanner (camera → Claude Vision → diagnosis card → actions)
- [ ] Research mode (deep information on scanned issues)
- [ ] One-tap contractor request from scan
- [ ] Projects screen (all jobs, bids, invoices per project)
- [ ] Bid review screen (view options, approve/reject, request changes)
- [ ] Invoice + payment screen (view, pay via Stripe, history)
- [ ] My Home screen (property profile, floor plan viewer, system inventory, maintenance log)
- [ ] Home Health Monitor (AI-generated reminders, seasonal checklists)
- [ ] Maintenance request submission (photo + description + urgency)
- [ ] Documents library (contracts, warranties, permits, receipts)
- [ ] Commit: `[R1f] Homeowner experience — property management + scanner`

### Sprint R1g: CPA Experience (~6 hrs)
- [ ] CPA home screen (financial overview, review queue, quick reports)
- [ ] Accounts screen (chart of accounts, balances, transaction drill-down)
- [ ] Reports screen (P&L, Balance Sheet, Cash Flow, Schedule C/E, 1099, GL Detail)
- [ ] Review screen (expense/receipt/invoice review queue)
- [ ] All read-only where appropriate (no creating jobs, no customer management)
- [ ] Commit: `[R1g] CPA experience — Ledger financial access`

### Sprint R1h: Tenant Experience (~4 hrs)
- [ ] Tenant home screen (rent balance, active maintenance, lease countdown)
- [ ] Rent screen (balance, charges, payments, pay now)
- [ ] Maintenance screen (submit + track requests, rate completion)
- [ ] My Unit screen (details, lease, inspections, emergency contacts)
- [ ] Commit: `[R1h] Tenant experience — unit management`

### Sprint R1i: Z Intelligence Integration (~16 hrs)
- [ ] Z button implementation (tap → quick actions, long-press → camera, hold → voice)
- [ ] Voice-first Z: speech-to-text → intent parsing → action execution → confirmation toast
- [ ] Camera-first Z: live camera with Claude Vision analysis → result card → action buttons
- [ ] Ambient Z: contextual suggestion engine → chips on screens → dismiss tracking → learning
- [ ] Quick action menu (role-aware, context-aware, time-aware, recent actions)
- [ ] Z actions per role: different available commands for each experience
- [ ] Voice command execution for top 20 actions (clock in, add material, take photo, create request, etc.)
- [ ] Camera identification for top 10 scenarios (equipment, damage, receipts, labels, nameplates, code violations)
- [ ] Ambient suggestions for each role (at least 10 suggestion types per role)
- [ ] Settings: Z preferences (voice on/off, wake word, ambient on/off, camera on/off)
- [ ] Commit: `[R1i] Z Intelligence — voice + camera + ambient across all roles`

### Sprint R1j: Cross-Role Integration + Testing (~8 hrs)
- [ ] Permission override system (company admin grants/restricts tools per user)
- [ ] Role switching (long-press avatar → switch experience)
- [ ] Deep linking (notifications open correct screen in correct role)
- [ ] Onboarding flow per role (first launch → role-specific tutorial)
- [ ] All 7 role experiences build and navigate correctly
- [ ] All existing backend wiring (repos, services) connected to new screens
- [ ] `dart analyze` passes
- [ ] Commit: `[R1j] App remake — cross-role integration + testing complete`

**Total estimated: ~110 hours across 10 sub-steps**
**New tables: 6**

---

## 16. MIGRATION STRATEGY

### What We Keep
- All models (insurance, property, compliance, Ledger, etc.)
- All repositories
- All services
- All Riverpod providers
- Supabase connection layer
- PowerSync offline layer
- Storage/photo upload logic
- Audio recording logic

### What We Rebuild
- App shell (main.dart routing, navigation)
- Home screens (7 new, role-specific)
- Screen layouts (new design system)
- Component library (new components replace old widgets)
- Theme system (new color/typography tokens)

### What We Remove
- Toolbox screens (calculators, code reference, exam prep, tables & data)
- All static content screens
- Old navigation structure (Home/Tools/Jobs/Invoices/More)
- Any remaining Firebase references (should be zero, but verify)

### Approach
**Incremental rebuild within the existing project** — NOT a separate app. We:
1. Build the new design system + component library alongside existing code
2. Build new app shell with role routing
3. Rebuild each role's screens using new components + existing services
4. Remove old screens once new ones are wired
5. Delete dead code at the end

This preserves all backend wiring while giving us a completely new frontend experience.

---

## 17. FEATURE CONNECTIVITY MAP

### How Everything Connects to the CRM

Every action in the mobile app creates or updates data that appears in the Web CRM:

| Mobile Action | CRM Visibility |
|---------------|----------------|
| Tech clocks in | Team dashboard shows "Mike clocked in at 7:42am" |
| Tech takes job photos | Photos appear on job detail page in CRM |
| Tech logs materials | Materials tab on job detail updates, job cost recalculates |
| Tech submits daily log | Daily log appears on job timeline |
| Tech finishes walkthrough | Notification to office, walkthrough + bid in CRM |
| Tech marks punch item done | Punch list in CRM updates |
| Tech captures moisture reading | Insurance claim moisture log updates |
| Inspector fails inspection item | Deficiency appears in CRM, work order option |
| Inspector completes inspection | Report generated, visible on property/job in CRM |
| Homeowner submits scan | Scan log visible in CRM under customer/property |
| Homeowner submits maintenance request | Request appears in CRM dispatch queue |
| Homeowner pays invoice | Payment recorded, Ledger journal entry auto-created |
| Homeowner approves bid | Bid status updates, job can be created |
| Tenant pays rent | Payment recorded, Ledger rental income entry created |
| Tenant submits maintenance request | Request in CRM + team portal queue |
| CPA categorizes expense | Ledger GL updated immediately |
| Owner creates job in CRM | Job appears on assigned tech's mobile app |
| Office sends invoice from CRM | Invoice appears in homeowner's mobile app |
| Office schedules job in CRM | Schedule appears on tech's mobile app |

**Everything is real-time.** Supabase real-time subscriptions ensure both sides see updates instantly.

---

**END OF SPEC**

**Sprint placement:** R1 executes after Phase D completes, before Phase E. The new app shell must exist before Z Intelligence (E1-E4) and Walkthrough Engine (E6) are built into it.

**Estimated total:** ~110 hours across 10 sub-steps.
**New tables:** 6 (app_user_preferences, inspection_templates, inspection_results, inspection_deficiencies, home_scan_logs, home_maintenance_reminders).
**Existing code reused:** All models, repositories, services, providers. Zero backend rewrite.
