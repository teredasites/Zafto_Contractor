# ZAFTO MEETINGS
## Context-Aware Video for Trades — Not Another Zoom Clone
### February 6, 2026

---

> **DATABASE:** Supabase PostgreSQL. See `Locked/29_DATABASE_MIGRATION.md`.
> **VIDEO INFRASTRUCTURE:** LiveKit (open-source WebRTC SFU) — self-hosted on Cloudflare.
> **AUDIO FALLBACK:** Telnyx PSTN (same provider as Calls, Doc 31).
> **ENCRYPTION:** WebRTC DTLS-SRTP (in transit) + AES-256-GCM (recordings). See `Locked/30_SECURITY_ARCHITECTURE.md`.
> **TRANSCRIPTION:** Deepgram (real-time streaming ASR) or Whisper via Edge Function.
> **AI:** Claude API for summaries, action items, and meeting intelligence.

---

## EXECUTIVE SUMMARY

Every meeting tool on the planet was designed for office workers sitting at desks sharing PowerPoints. That's not what a contractor does.

A contractor is standing in a flooded basement holding their phone with one hand, trying to show an insurance adjuster the damage while explaining the scope of work to a homeowner who doesn't understand what they're looking at.

ZAFTO Meetings are **context-aware video rooms** built for trade professionals. Every room knows who's in the call, what job it's about, and what documents are relevant. The call generates documentation automatically. When the meeting ends, the job record is already updated.

**What this replaces:**
- Zoom/Google Meet/Teams for client calls ($0-20/mo per user)
- FaceTime for "hey look at this" job site calls
- Calendly for appointment scheduling ($12-16/mo)
- Loom for async video walkthroughs ($12.50/mo)
- Driving 45 minutes for a 10-minute initial assessment
- "Can you send me photos?" email chains
- Adjuster meetings where nobody can see what the contractor sees

**What this costs to run:**
- LiveKit Cloud: ~$0.006/min/participant (or self-host for ~$0)
- Deepgram transcription: ~$0.0043/min
- Supabase Storage for recordings: pennies/GB
- 5-person company, 20 meetings/month: ~$5-15/month total
- vs. Zoom Business + Calendly + Loom: ~$45-65/month per user

---

## WHY THIS IS NOT ZOOM

```
WHAT ZOOM DOES:                      WHAT ZAFTO MEETINGS DO:
───────────────────────────────────── ──────────────────────────────────────────────
Generic video call                    Smart room pre-loaded with job context
Share your screen                     Share live job site camera feed
Recording saved... somewhere          Recording linked to job record + encrypted
No idea who the customer is           Customer info, history, equipment in sidebar
Take notes manually                   AI transcribes, summarizes, extracts action items
Schedule via separate tool            Book directly from CRM, Client Portal, or website
Everyone sees same thing              Role-based views (contractor sees costs, client doesn't)
Can't capture photos during call      Freeze-frame → annotate → save to job photos
Meeting ends, nothing happens         Meeting ends → summary posted, tasks created,
                                        follow-up drafted, estimate started
Phone call and video are separate     Escalate any phone call to video with one tap
Client needs Zoom account/app         Client joins from browser link. Zero downloads.
Desktop-first design                  Mobile-first. One-handed. Job site optimized.
```

---

## THE CORE INSIGHT: CONTEXT IS THE MOAT

Every ZAFTO meeting room is a **Smart Room**. When a meeting is created from a job, the room automatically loads:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  SMART ROOM — Job #1247: Kitchen Rewire                                      │
│                                                                              │
│  ┌─────────────────────────────────┐  ┌─────────────────────────────────┐   │
│  │                                 │  │  CONTEXT PANEL                  │   │
│  │                                 │  │                                 │   │
│  │         LIVE VIDEO              │  │  Customer: Sarah Johnson        │   │
│  │                                 │  │  Address: 42 Oak St, Fairfield  │   │
│  │   (contractor's camera          │  │  Phone: (203) 555-1234          │   │
│  │    showing the job site)        │  │                                 │   │
│  │                                 │  │  JOB INFO:                      │   │
│  │                                 │  │  Status: In Progress            │   │
│  │                                 │  │  Estimate: $12,400              │   │
│  │                                 │  │  Paid: $6,200 (50%)             │   │
│  │                                 │  │  Materials: $3,100 ordered      │   │
│  │                                 │  │                                 │   │
│  │                                 │  │  PHOTOS (12):                   │   │
│  │                                 │  │  [thumb] [thumb] [thumb] [more] │   │
│  │                                 │  │                                 │   │
│  │                                 │  │  DOCUMENTS:                     │   │
│  │                                 │  │  ▸ Estimate_v2.pdf              │   │
│  │                                 │  │  ▸ Contract_signed.pdf          │   │
│  │                                 │  │  ▸ Permit_approved.pdf          │   │
│  │                                 │  │                                 │   │
│  │  [Freeze ■] [Annotate ✎]       │  │  AI ASSISTANT:                  │   │
│  │  [Photo 📷] [Record ●]         │  │  "Customer asked about timeline │   │
│  │                                 │  │   on Feb 3. Panel inspection is │   │
│  │                                 │  │   scheduled for Feb 12."        │   │
│  └─────────────────────────────────┘  └─────────────────────────────────┘   │
│                                                                              │
│  [Mute 🎤]  [Camera 📹]  [Share 🖥️]  [Docs 📄]  [Chat 💬]  [End ☎️]      │
└──────────────────────────────────────────────────────────────────────────────┘

The context panel is ONLY visible to the contractor (and their team).
The client sees: clean video feed + shared documents.
The adjuster sees: video feed + relevant claim docs.

NOBODY sees data they shouldn't — same RBAC as the rest of ZAFTO.
```

---

## MEETING TYPES

### 1. SITE WALK (The Killer Feature)

```
USE CASE:
Contractor is on a job site. Needs to show someone what they're looking at.
- Show homeowner progress remotely
- Show insurance adjuster damage without waiting 3 weeks for them to visit
- Show office manager/owner a problem for approval
- Show a sub-contractor what needs to be done before they arrive
- Show a supplier the exact part/equipment needed

HOW IT WORKS:
1. Contractor taps "Start Site Walk" from the job detail screen
2. Rear camera activates (not selfie cam — they're showing the job site)
3. ZAFTO generates a join link
4. Contractor shares link via SMS, email, or in-app to participants
5. Participants join from browser — zero app download
6. Contractor walks the site. Participants see live feed.

SITE WALK SUPERPOWERS:

FREEZE + ANNOTATE:
  Any participant can tap "Freeze" → video pauses on current frame
  → Draw circles, arrows, text on the frozen frame
  → "See this crack right here?" [circles it]
  → Screenshot auto-saves to job photos with annotation overlay
  → Resume live video

LIVE PHOTO CAPTURE:
  Tap camera icon → captures still from video feed
  → Auto-saved to job photos
  → GPS-tagged, timestamped, linked to job record
  → Same photo appears in Client Portal, CRM, Equipment Passport

LASER POINTER:
  Participant taps and holds → red dot appears on contractor's screen
  → "Look over to the left, see that pipe?"
  → Helps guide the contractor's camera to the right spot

FLASHLIGHT:
  Toggle phone flashlight during video call
  → Crawlspace, attic, under-sink — dark spaces are the norm

MEASUREMENT OVERLAY (future — AR):
  Use phone's LiDAR (iPhone Pro) to overlay measurements
  → Rough dimensions captured during video walkthrough
  → Feeds into estimate

RECORDING:
  Toggle recording on/off
  → Stored in Supabase Storage, linked to job
  → Encrypted with company key (per Doc 30 Layer 4B)
  → State-based consent compliance (same as phone recordings, Doc 31)
  → AI processes recording after call → summary + screenshots extracted
```

---

### 2. VIRTUAL ESTIMATE

```
USE CASE:
Homeowner has a problem. Instead of driving 45 minutes for a 10-minute look,
contractor does a video consultation first.

- Saves a truck roll ($50-100 in time/gas per visit)
- Qualifies the lead before committing to an in-person visit
- Provides instant value to the homeowner (they feel helped immediately)
- Captures everything needed to build a preliminary estimate

HOW IT WORKS:

HOMEOWNER SIDE (Client Portal or ZAFTO Website):

  client.zafto.cloud/request → "Request Video Consultation"

  ┌──────────────────────────────────────────────────────────────────┐
  │  SCHEDULE A VIDEO CONSULTATION                                   │
  │                                                                  │
  │  What do you need help with?                                     │
  │  [Describe your issue briefly ____________________________]      │
  │                                                                  │
  │  Can you show us on video? ◉ Yes  ○ No (phone call instead)    │
  │                                                                  │
  │  Pick a time:                                                    │
  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐                │
  │  │ Mon  │ │ Tue  │ │ Wed  │ │ Thu  │ │ Fri  │                │
  │  │ Feb 9│ │Feb 10│ │Feb 11│ │Feb 12│ │Feb 13│                │
  │  ├──────┤ ├──────┤ ├──────┤ ├──────┤ ├──────┤                │
  │  │ 9:00 │ │10:00 │ │ 9:00 │ │      │ │ 9:00 │                │
  │  │10:00 │ │11:00 │ │10:00 │ │      │ │10:00 │                │
  │  │ 2:00 │ │ 2:00 │ │      │ │      │ │ 1:00 │                │
  │  │ 3:00 │ │      │ │      │ │      │ │      │                │
  │  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘                │
  │                                                                  │
  │  (Availability pulled from contractor's ZAFTO calendar.          │
  │   Blocked time, jobs, existing meetings excluded automatically.) │
  │                                                                  │
  │  [Book Consultation →]                                           │
  └──────────────────────────────────────────────────────────────────┘

  After booking:
  → Homeowner gets confirmation email + calendar invite with join link
  → Contractor gets notification + calendar event in ZAFTO
  → Reminder SMS/push 15 min before call

CONTRACTOR SIDE (during the call):

  Smart Room auto-loads with:
  - Customer profile (if existing) or lead info (if new)
  - Property address + any equipment on file
  - Previous job history (if returning customer)

  DURING THE CALL:
  - Homeowner shows the problem on their camera
  - Contractor can freeze-frame + annotate
  - Photos captured auto-attach to a DRAFT estimate
  - Contractor can pull up price book to give ballpark range
  - If scope is clear: start building estimate DURING the call
  - If complex: schedule in-person visit with context already captured

  AFTER THE CALL:
  → AI summary generated
  → Photos organized in job record
  → Draft estimate ready to finalize
  → Follow-up email auto-drafted: "Great talking with you, Sarah.
     Based on what I saw, here's what we're looking at..."
  → If new customer: lead record created in CRM automatically

THE ROI:
A plumber doing 5 virtual estimates/week saves ~5 truck rolls.
At $75/truck roll (time + gas): $375/week saved = $19,500/year.
That's not a feature — that's a business transformation.
```

---

### 3. DOCUMENT REVIEW

```
USE CASE:
Contractor needs to walk a client through an estimate, contract, or change order.
Instead of emailing a PDF and hoping they read it, review it together on screen.

HOW IT WORKS:
1. Contractor opens a meeting from the job
2. Shares a document (estimate, contract, invoice, blueprint)
3. Both parties see the same document, same page, same scroll position
4. Contractor can highlight sections in real-time
5. Client can ask questions about specific line items
6. Client can E-SIGN THE DOCUMENT DURING THE CALL
   → No more "I'll send you the DocuSign link after the call"
   → Signed right there, witnessed on video, recorded

SYNCHRONIZED DOCUMENT VIEW:
┌──────────────────────────────────────────────────────────────────┐
│  ESTIMATE — Job #1247: Kitchen Rewire                            │
│                                                                  │
│  ┌────────────────────────────────┐  ┌────────────────────────┐ │
│  │  [Contractor video - small]    │  │  ESTIMATE              │ │
│  │  [Client video - small]        │  │                        │ │
│  │                                │  │  Line Items:           │ │
│  │                                │  │  Panel upgrade  $2,800 │ │
│  │                                │  │  20 new circuits $4,200│ │
│  │                                │  │  Permits        $450   │ │
│  │                                │  │  ──────────────────    │ │
│  │                                │  │  TOTAL: $12,400        │ │
│  │                                │  │                        │ │
│  │                                │  │  ┌──────────────────┐  │ │
│  │                                │  │  │ [Sign Here ✍️]   │  │ │
│  │                                │  │  └──────────────────┘  │ │
│  └────────────────────────────────┘  └────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

SUPPORTED DOCUMENTS:
- Estimates / bids (from ZAFTO)
- Contracts (from ZAFTO, with e-signature)
- Invoices (with "Pay Now" button during call)
- Change orders
- Blueprints / plans (PDF viewer with zoom/pan)
- Photos (swipe through job photos together)
- Insurance claim documents (for adjuster meetings)

THE CLOSE RATE IMPACT:
Walking a customer through an estimate face-to-face (even virtually)
has 3-5x higher close rate than emailing a PDF.
The e-sign during call is the cherry on top — no follow-up needed.
```

---

### 4. TEAM HUDDLE

```
USE CASE:
Morning standup. Quick crew briefing. End-of-day recap.
Not a formal meeting — a 5-minute sync that keeps everyone aligned.

HOW IT WORKS:
1. Owner/Admin taps "Start Huddle" from Dashboard
2. All online team members get notification: "Huddle starting"
3. Join with one tap
4. Room pre-loads with TODAY's context

SMART HUDDLE CONTEXT:
┌──────────────────────────────────────────────────────────────────┐
│  MORNING HUDDLE — February 6, 2026                               │
│                                                                  │
│  ┌──── TODAY'S JOBS ────────────────────────────────────────┐   │
│  │                                                            │   │
│  │  9:00  Kitchen Rewire — 42 Oak St (Mike + Dave)           │   │
│  │  10:30 Panel Upgrade — 15 Elm (Robert)                    │   │
│  │  1:00  Service Call — 88 Pine (Mike)                      │   │
│  │  2:30  Estimate — 201 Birch (Robert) ← NEW LEAD          │   │
│  │                                                            │   │
│  │  WEATHER: 34°F, light snow expected after noon             │   │
│  │  MATERIALS: Home Depot delivery arriving ~11am             │   │
│  │  ALERTS: Permit for 42 Oak expires Feb 10 — RENEW         │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  [Video feeds of all participants at bottom]                     │
│                                                                  │
│  AI: "Good morning. 4 jobs scheduled today across 2 techs.      │
│   Mike has back-to-back at 9 and 1 — travel time is tight.      │
│   The permit on Oak St needs renewal by Monday."                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

AFTER HUDDLE:
→ AI summary: "Discussed moving Mike's 1pm to 2pm for travel time.
   Robert taking the 2:30 estimate. Permit renewal assigned to Sarah."
→ Action items auto-created as tasks
→ Calendar updated if schedule changes were discussed
→ Total time: 4 minutes. Everyone aligned.
```

---

### 5. INSURANCE CONFERENCE

```
USE CASE:
Contractor + insurance adjuster + homeowner need to be on the same page.
This is where ZAFTO obliterates the competition.

PARTICIPANTS (role-based views):
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  CONTRACTOR (Owner/Admin) sees:                                  │
│  - Full job record, costs, margin, internal notes                │
│  - Claim details (carrier, adjuster, claim #, amounts)           │
│  - Xactimate estimate lines                                     │
│  - Supplement history                                            │
│  - All job photos + moisture readings                            │
│  - Equipment tracking                                            │
│                                                                  │
│  INSURANCE ADJUSTER (external guest) sees:                       │
│  - Video feed only                                               │
│  - Shared documents (estimate, photos, drying logs)              │
│  - NOTHING about contractor's costs, margin, or internal notes   │
│                                                                  │
│  HOMEOWNER (client) sees:                                        │
│  - Video feed                                                    │
│  - Shared documents relevant to them                             │
│  - NOTHING about claim amounts, deductibles (until contractor    │
│    explicitly shares)                                            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

INSURANCE CONFERENCE SUPERPOWERS:

LIVE DAMAGE DOCUMENTATION:
  Contractor walks the property on camera.
  Adjuster can freeze-frame + annotate remotely.
  Every freeze-frame saves as timestamped evidence.
  "I can see the water line on the drywall at approximately 18 inches."
  → Photo saved with annotation + adjuster's comment.

SUPPLEMENT JUSTIFICATION:
  Contractor discovers hidden damage during work.
  Starts an Insurance Conference with adjuster.
  Shows the damage live → freeze-frame → annotate.
  → Evidence package auto-generated for supplement submission.
  → Reduces supplement cycle from 2-4 weeks to same-day.

DRYING LOG REVIEW (Restoration):
  Share moisture readings dashboard during call.
  Walk through each zone with live video of current conditions.
  Adjuster can confirm drying progress without site visit.
  → Faster equipment removal approval = lower equipment rental costs.

RECORDING AS LEGAL DOCUMENTATION:
  With consent: entire call recorded.
  Recording linked to insurance claim record.
  Timestamped, encrypted, immutable after recording ends.
  If adjuster says "yes, that's approved" on video — it's documented.
  State consent compliance: same engine as phone recording (Doc 31).

THE BUSINESS IMPACT:
- Adjuster meetings typically take 2-4 weeks to schedule in person
- Video conferences can happen in 24-48 hours
- Faster adjuster approval = faster start = faster payment
- Supplement approval with video evidence vs. "just photos" = higher approval rate
- One restoration contractor doing 10 claims/month saves ~40 hours/month in adjuster scheduling
```

---

### 6. ASYNC VIDEO MESSAGE

```
USE CASE:
Can't get everyone on a live call? Record a video message instead.
Like Loom, but built into the CRM and tied to job records.

SCENARIOS:
- Contractor records a walkthrough of completed work for the homeowner
- Tech records a problem they found for the owner to review
- Owner records instructions for a tech before they arrive at a job
- Contractor records supplement justification for an adjuster to review
- Homeowner records their issue for the contractor to evaluate

HOW IT WORKS:

RECORDING:
  CRM → Job #1247 → "Record Video Message"

  ┌──────────────────────────────────────────────────────────────┐
  │  RECORD VIDEO MESSAGE                                        │
  │                                                              │
  │  For: Job #1247 — Kitchen Rewire                             │
  │  To: Sarah Johnson (homeowner)                               │
  │                                                              │
  │  ┌────────────────────────────────────────────────────────┐ │
  │  │                                                        │ │
  │  │              [LIVE CAMERA PREVIEW]                      │ │
  │  │                                                        │ │
  │  │              ● REC  02:34                               │ │
  │  │                                                        │ │
  │  └────────────────────────────────────────────────────────┘ │
  │                                                              │
  │  [Pause ⏸]  [Annotate ✎]  [Photo 📷]  [Stop ■]            │
  │                                                              │
  │  During recording:                                           │
  │  - Tap Annotate to freeze + draw on current frame           │
  │  - Tap Photo to capture a still (saved to job)              │
  │  - Switch cameras (front/rear)                              │
  │  - Toggle flashlight                                        │
  └──────────────────────────────────────────────────────────────┘

AFTER RECORDING:
  ┌──────────────────────────────────────────────────────────────┐
  │  VIDEO MESSAGE READY                                         │
  │                                                              │
  │  Duration: 2:34                                              │
  │  [▶ Preview]                                                 │
  │                                                              │
  │  AI Summary: "Showed completed panel upgrade in kitchen.     │
  │  Demonstrated new circuit breakers, GFCI outlets in          │
  │  countertop area, and dedicated appliance circuits.          │
  │  All work per approved estimate."                            │
  │                                                              │
  │  Add a message: [Great news Sarah — your kitchen rewire     │
  │  is done! Here's a quick walkthrough of everything we did.  │
  │  Give it a look and let me know if you have questions.    ] │
  │                                                              │
  │  Send via:                                                   │
  │  ☑ Client Portal notification                               │
  │  ☑ Email (with watch link)                                  │
  │  ☐ SMS (with watch link)                                    │
  │                                                              │
  │  [Send →]  [Re-record]  [Delete]                            │
  └──────────────────────────────────────────────────────────────┘

VIEWING:
  Recipient gets a link → opens in browser (no app/account needed)
  → Can reply with their own video or text
  → Reply threads back to job record

REPLY:
  "Thanks! Looks great. One question — is that outlet by the
   sink on its own circuit? Here's what I mean..."
  [Homeowner records 15-second reply video pointing at outlet]
  → Reply attached to same thread in job record

THE MOAT:
  Every async video is tied to a job. After 6 months, a contractor has
  hundreds of video walkthroughs documenting their work quality.
  That's a portfolio that builds itself. That's proof of craftsmanship
  for reviews, for insurance disputes, for warranty claims.
  You can't export that to another platform.
```

---

## PHONE-TO-VIDEO ESCALATION

```
This is where the Calls (Doc 31) and Meetings converge.

SCENARIO:
  Tech is on a phone call with the office. Finds something they need to show.

  "Hey Robert, I'm at the Johnson job and there's knob-and-tube wiring
   behind this wall that wasn't in the original scope."

  Robert: "Show me."

  Tech taps [Escalate to Video →] in the call UI.
  → Phone call seamlessly upgrades to video call.
  → Both parties now see each other's camera.
  → Tech switches to rear camera, shows the knob-and-tube.
  → Robert freeze-frames, annotates, saves to job record.
  → Decision made in 30 seconds instead of driving to the site.

TECHNICAL:
  Same WebRTC session, just add video media stream.
  Telnyx call → pause PSTN → switch to WebRTC video → or bridge both.
  User experience: one button tap. No second link. No "join a meeting."
```

---

## SCHEDULING ENGINE (Built-In Calendly Killer)

```
NO EXTERNAL SCHEDULING TOOL NEEDED.

Booking is built into 3 surfaces:

1. CLIENT PORTAL:
   client.zafto.cloud/request → Schedule Consultation
   → Shows contractor's real-time availability from ZAFTO calendar
   → Books directly, sends confirmations, adds to both calendars

2. CONTRACTOR WEBSITE:
   powerselectrical.com/book
   → Same availability engine
   → "Book a Free Video Estimate" CTA
   → Lead capture if new customer

3. CRM (internal):
   Job detail → "Schedule Meeting with Client"
   → Pick time from availability
   → Client gets invite with join link
   → Reminder automation (SMS/email/push at 24h, 1h, 15min)

AVAILABILITY RULES:
- Syncs from ZAFTO calendar (jobs, meetings, blocked time)
- Configurable booking hours (e.g., estimates only 9am-11am, 2pm-4pm)
- Buffer time between bookings (e.g., 15 min between calls)
- Max bookings per day (e.g., 4 video estimates max)
- Instant booking vs. approval required (contractor's choice)
- Booking page branded with company logo/colors

BOOKING TYPES (contractor configures):
┌──────────────────────────────────────────────────────────────────┐
│  BOOKING TYPES                            [+ New Booking Type]   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Video Estimate                                  15 min    │ │
│  │  "Free video consultation to assess your project"          │ │
│  │  Available: Mon-Fri 9am-11am, 2pm-4pm                     │ │
│  │  [Edit]  [Toggle Off]  [Copy Link]                        │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │  Project Check-In                                10 min    │ │
│  │  "Quick update on your active project"                     │ │
│  │  Available: Mon-Fri 12pm-1pm                              │ │
│  │  [Edit]  [Toggle Off]  [Copy Link]                        │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │  Insurance Conference                            30 min    │ │
│  │  "Multi-party call with adjuster"                          │ │
│  │  Available: By approval only                              │ │
│  │  [Edit]  [Toggle Off]  [Copy Link]                        │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

---

## AI MEETING INTELLIGENCE

```
Every meeting has an AI layer running silently in the background.
The contractor sees the benefits after the call — zero effort during.

1. REAL-TIME TRANSCRIPTION:
   - Deepgram streaming ASR (or Whisper via Edge Function)
   - Speaker identification (who said what)
   - Trade terminology trained (knows "romex" not "romax")
   - Transcript saved to meeting record

2. AUTO-SUMMARY:
   After call ends, Claude processes transcript + context:

   "Meeting with Sarah Johnson re: Kitchen Rewire (Job #1247).
    Discussed completed panel upgrade. Sarah confirmed satisfaction
    with outlet placement. Requested additional outlet in pantry
    (not in original scope). Robert agreed to send change order
    for $350. Final walkthrough scheduled for Feb 12."

3. ACTION ITEMS EXTRACTED:
   → Task created: "Send change order for pantry outlet — $350"
     Assigned to: Robert | Due: Feb 7
   → Task created: "Schedule final walkthrough with Sarah"
     Assigned to: Sarah (Office) | Due: Feb 10
   → Calendar event: "Final Walkthrough — 42 Oak St"
     Date: Feb 12

4. FOLLOW-UP DRAFT:
   AI drafts a follow-up email based on meeting content:

   "Hi Sarah, great talking with you today! As discussed, I'll send
    over a change order for the additional pantry outlet ($350).
    I have us down for a final walkthrough on February 12.
    Let me know if that still works! — Robert, Powers Electrical"

   → Contractor reviews, edits if needed, sends with one tap
   → NEVER auto-sends (same rule as Dashboard, Doc 41)

5. ESTIMATE INTELLIGENCE (Virtual Estimates only):
   During a virtual estimate, AI listens to the conversation and:
   - Suggests relevant line items from price book
   - Flags things the contractor mentioned but didn't price
   - "You discussed GFCI outlets in the bathroom but haven't
      added them to the estimate yet."
   - Owner/Admin only — never visible to client

6. MEETING ANALYTICS (over time):
   - Average meeting duration by type
   - Virtual estimate → job conversion rate
   - Time saved vs. in-person visits
   - Most common client questions (helps improve templates)
   - Best times for client availability (optimize booking slots)
```

---

## TECHNICAL ARCHITECTURE

```
WHY LIVEKIT (not Telnyx Video, not Twilio Video, not Daily):

PROVIDER COMPARISON:
─────────────────────
                 LIVEKIT          DAILY.CO         TWILIO VIDEO
Type:            Open source SFU  Hosted SaaS      Hosted SaaS
Self-host:       YES              No               No
Cloud option:    YES              YES              YES
Cost (cloud):    $0.006/min/p     $0.004/min/p     $0.0015/min/p
Cost (self):     ~$0 (infra)     N/A              N/A
Recording:       Built-in         Built-in         Built-in
Screen share:    YES              YES              YES
Flutter SDK:     livekit_client   daily_co (web)   twilio_video
Web SDK:         YES              YES              YES
Annotations:     Plugin system    No               No
Max participants: 100+            200+             50

WHY LIVEKIT:
• Open source — no vendor lock-in, ever
• Self-hostable on Cloudflare Workers / Fly.io (cost → ~$0)
• Flutter SDK is maintained and actively developed
• Plugin architecture supports custom features (annotations, freeze-frame)
• Egress API for server-side recording (no client-side recording needed)
• Room-level and track-level permissions (perfect for role-based views)
• Scales from 1:1 calls to 100-person rooms
• Already used by major platforms (built by ex-Twilio engineers)

FALLBACK:
Same as phone system — abstraction layer. If LiveKit ever fails,
swap to Daily.co or Twilio Video without touching app code.


ARCHITECTURE:

┌────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ ZAFTO App  │     │  Supabase Edge   │     │  LiveKit Cloud   │
│ (Flutter)  │◄───►│  Functions       │◄───►│  (or self-host)  │
│            │     │                  │     │                  │
│ livekit_   │     │ createRoom       │     │  WebRTC SFU      │
│ client     │     │ generateToken    │     │  Recording       │
│ package    │     │ endRoom          │     │  Egress          │
│            │     │ processRecording │     │                  │
└────────────┘     └──────────────────┘     └──────────────────┘
                           │
                   ┌───────▼──────────┐
                   │  Supabase        │
                   │  - meetings table │
                   │  - Storage       │
                   │  - Realtime      │
                   └──────────────────┘

┌────────────┐     ┌──────────────────┐
│ Web Client │     │  Deepgram        │
│ (browser)  │◄───►│  Streaming ASR   │
│            │     │  (transcription) │
│ livekit.js │     └──────────────────┘
│ No download│
│ needed     │
└────────────┘

PHONE ESCALATION BRIDGE:
┌──────────────┐     ┌──────────────────┐
│ Telnyx PSTN  │◄───►│  SIP-to-WebRTC   │
│ (phone call) │     │  Bridge (LiveKit) │
└──────────────┘     └──────────────────┘
When a phone call escalates to video:
1. PSTN audio bridges into LiveKit room via SIP
2. Video track added from app
3. Seamless transition — no dropped audio
```

---

## ZERO-DOWNLOAD CLIENT EXPERIENCE

```
THE MOST IMPORTANT DESIGN DECISION:

Homeowners are NOT downloading an app for a 15-minute video estimate.
Adjusters are NOT downloading an app for a quick site review.

EVERY external participant joins from a BROWSER LINK:

  https://meet.zafto.cloud/{roomCode}

  ┌──────────────────────────────────────────────────────────────────┐
  │  [Company Logo]                                                   │
  │                                                                  │
  │  Powers Electrical                                               │
  │  Video Consultation                                              │
  │                                                                  │
  │  ┌────────────────────────────────────────────────────────────┐ │
  │  │              [Camera Preview]                              │ │
  │  │                                                            │ │
  │  │  Your name: [Sarah Johnson    ]                           │ │
  │  │                                                            │ │
  │  │  Camera:   [✓ On]   Microphone: [✓ On]                   │ │
  │  │                                                            │ │
  │  │              [Join Meeting →]                              │ │
  │  └────────────────────────────────────────────────────────────┘ │
  │                                                                  │
  │  Powered by ZAFTO                                                │
  └──────────────────────────────────────────────────────────────────┘

  - Works on iPhone Safari, Android Chrome, any desktop browser
  - Camera/mic permission prompt only
  - Company branded (logo + colors)
  - No account creation, no app download, no sign-in
  - LiveKit's web SDK handles all WebRTC negotiation
  - Mobile-optimized (most homeowners join from their phone)
```

---

## RECORDING + COMPLIANCE

```
SAME ARCHITECTURE AS PHONE SYSTEM (Doc 31):

CONSENT:
- One-party states: contractor consent sufficient, auto-record option
- Two-party / all-party states: announcement plays at start of recording
  "This meeting is being recorded for documentation purposes."
- Consent tracked per participant in meeting record
- State detected from company profile location

STORAGE:
- LiveKit Egress API handles server-side recording (no client resources used)
- Recording uploaded to Supabase Storage: {company_id}/meetings/{meeting_id}/
- Encrypted with company encryption key (AES-256-GCM, per Doc 30 Layer 4B)
- Linked to job record and meeting record

RETENTION:
- Default: 90 days (configurable per company)
- Insurance-linked recordings: 7 years (carrier audit period)
- Auto-delete after retention period (with 30-day warning)

ACCESS:
- Owner/Admin: all recordings
- Office: recordings they participated in
- Tech: recordings they participated in
- Client: only if contractor explicitly shares a recording
- Adjuster/Guest: no access after call (unless shared)
```

---

## DATABASE SCHEMA

```sql
-- ============================================================
-- MEETING ROOM SYSTEM — SUPABASE SCHEMA
-- ============================================================

CREATE TABLE meetings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id),                   -- NULL for non-job meetings (huddles)
  claim_id UUID REFERENCES insurance_claims(id),     -- For insurance conferences

  -- Meeting info
  title TEXT NOT NULL,                               -- "Virtual Estimate — Sarah Johnson"
  meeting_type TEXT NOT NULL,                        -- site_walk, virtual_estimate, document_review,
                                                     -- team_huddle, insurance_conference, async_video
  room_code TEXT NOT NULL UNIQUE,                    -- Short code for join URL (e.g., "abc-xyz-123")

  -- Scheduling
  scheduled_at TIMESTAMPTZ,                          -- NULL for instant meetings
  duration_minutes INTEGER DEFAULT 30,               -- Expected duration
  started_at TIMESTAMPTZ,                            -- Actual start
  ended_at TIMESTAMPTZ,                              -- Actual end
  actual_duration_minutes INTEGER,                   -- Computed on end

  -- LiveKit
  livekit_room_name TEXT,                            -- LiveKit room identifier
  livekit_room_sid TEXT,                             -- LiveKit session ID

  -- Recording
  is_recorded BOOLEAN DEFAULT false,
  recording_path TEXT,                               -- Supabase Storage path
  recording_duration_seconds INTEGER,
  consent_type TEXT DEFAULT 'none',                  -- none, one_party, all_party
  consent_acknowledged JSONB DEFAULT '[]',           -- [{participant_id, acknowledged_at}]

  -- AI Intelligence
  transcript TEXT,                                   -- Full transcript (from Deepgram/Whisper)
  ai_summary TEXT,                                   -- Claude-generated summary
  ai_action_items JSONB DEFAULT '[]',                -- [{description, assigned_to, due_date, task_id}]
  ai_follow_up_draft TEXT,                           -- Draft follow-up email

  -- Booking (if scheduled via booking engine)
  booking_type_id UUID REFERENCES meeting_booking_types(id),
  booked_by_name TEXT,                               -- External booker name
  booked_by_email TEXT,                              -- External booker email
  booked_by_phone TEXT,

  -- Status
  status TEXT NOT NULL DEFAULT 'scheduled',          -- scheduled, in_progress, completed, cancelled, no_show
  cancelled_at TIMESTAMPTZ,
  cancel_reason TEXT,

  -- Metadata
  metadata JSONB DEFAULT '{}',                       -- Meeting-type-specific data
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id)
);

ALTER TABLE meetings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "meeting_isolation" ON meetings
  USING (company_id = current_setting('app.company_id')::UUID);
CREATE INDEX idx_meetings_company_status ON meetings(company_id, status);
CREATE INDEX idx_meetings_job ON meetings(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX idx_meetings_scheduled ON meetings(company_id, scheduled_at)
  WHERE status = 'scheduled';

CREATE TABLE meeting_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,

  -- Participant identity
  user_id UUID REFERENCES users(id),                 -- NULL for external guests
  participant_type TEXT NOT NULL,                     -- host, team_member, client, adjuster, guest
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,

  -- Access control
  can_see_context_panel BOOLEAN DEFAULT false,        -- Job details sidebar
  can_see_financials BOOLEAN DEFAULT false,           -- Costs, margins, amounts
  can_annotate BOOLEAN DEFAULT true,
  can_record BOOLEAN DEFAULT false,                   -- Only host by default
  can_share_documents BOOLEAN DEFAULT false,

  -- Participation
  join_method TEXT,                                   -- app, browser, phone_bridge
  joined_at TIMESTAMPTZ,
  left_at TIMESTAMPTZ,
  duration_seconds INTEGER,

  -- LiveKit
  livekit_token TEXT,                                -- Generated JWT for this participant

  -- Recording consent
  consent_acknowledged BOOLEAN DEFAULT false,
  consent_acknowledged_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE meeting_participants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "participant_isolation" ON meeting_participants
  USING (company_id = current_setting('app.company_id')::UUID);

CREATE TABLE meeting_captures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id),

  -- Capture info
  capture_type TEXT NOT NULL,                        -- freeze_frame, photo, annotation, document_shared
  timestamp_in_meeting INTEGER,                      -- Seconds from meeting start
  file_path TEXT,                                    -- Supabase Storage path
  thumbnail_path TEXT,
  annotation_data JSONB,                             -- Drawing data overlay (circles, arrows, text)
  note TEXT,                                         -- Optional text note with capture
  captured_by UUID REFERENCES users(id),

  -- Auto-link to job photos
  linked_to_job_photos BOOLEAN DEFAULT true,         -- Auto-add to job photo gallery

  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE meeting_captures ENABLE ROW LEVEL SECURITY;
CREATE POLICY "capture_isolation" ON meeting_captures
  USING (company_id = current_setting('app.company_id')::UUID);
CREATE INDEX idx_captures_meeting ON meeting_captures(meeting_id);
CREATE INDEX idx_captures_job ON meeting_captures(job_id) WHERE job_id IS NOT NULL;

CREATE TABLE meeting_booking_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Booking type config
  name TEXT NOT NULL,                                -- "Video Estimate"
  slug TEXT NOT NULL,                                -- "video-estimate" (for URL)
  description TEXT,                                  -- Shown on booking page
  duration_minutes INTEGER NOT NULL DEFAULT 15,
  meeting_type TEXT NOT NULL DEFAULT 'virtual_estimate',

  -- Availability rules
  available_days JSONB DEFAULT '["mon","tue","wed","thu","fri"]',
  available_hours JSONB DEFAULT '[{"start":"09:00","end":"17:00"}]',
  buffer_minutes INTEGER DEFAULT 15,                 -- Gap between bookings
  max_per_day INTEGER DEFAULT 4,                     -- Max bookings per day
  advance_notice_hours INTEGER DEFAULT 2,            -- Min hours in advance to book
  max_advance_days INTEGER DEFAULT 30,               -- Max days in advance to book

  -- Approval
  requires_approval BOOLEAN DEFAULT false,           -- Instant vs. approval required
  auto_confirm BOOLEAN DEFAULT true,

  -- Display
  is_active BOOLEAN DEFAULT true,
  show_on_website BOOLEAN DEFAULT true,              -- Show on ZAFTO website booking page
  show_on_client_portal BOOLEAN DEFAULT true,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(company_id, slug)
);

ALTER TABLE meeting_booking_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "booking_type_isolation" ON meeting_booking_types
  USING (company_id = current_setting('app.company_id')::UUID);

CREATE TABLE async_videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id),

  -- Video info
  title TEXT,
  video_path TEXT NOT NULL,                          -- Supabase Storage
  thumbnail_path TEXT,
  duration_seconds INTEGER,
  file_size_bytes BIGINT,

  -- Sender
  sent_by UUID REFERENCES users(id),
  sent_by_name TEXT NOT NULL,

  -- Recipient
  recipient_type TEXT NOT NULL,                      -- client, team_member, adjuster
  recipient_user_id UUID REFERENCES users(id),       -- NULL for external
  recipient_name TEXT,
  recipient_email TEXT,

  -- Message
  message TEXT,                                      -- Text message accompanying video
  share_token TEXT NOT NULL UNIQUE,                  -- For external viewing URL

  -- AI
  ai_summary TEXT,
  captures JSONB DEFAULT '[]',                       -- Stills captured during recording

  -- Tracking
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  viewed_at TIMESTAMPTZ,                             -- First view
  view_count INTEGER DEFAULT 0,

  -- Reply thread
  reply_to_id UUID REFERENCES async_videos(id),      -- Reply chain

  -- Delivery
  delivered_via JSONB DEFAULT '[]',                  -- ["client_portal", "email", "sms"]

  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE async_videos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "async_video_isolation" ON async_videos
  USING (company_id = current_setting('app.company_id')::UUID);
CREATE INDEX idx_async_videos_job ON async_videos(job_id) WHERE job_id IS NOT NULL;
```

---

## EDGE FUNCTIONS

| Function | Trigger | Purpose |
|----------|---------|---------|
| `createMeetingRoom` | HTTP | Create LiveKit room, generate join tokens per participant |
| `generateMeetingToken` | HTTP | Generate LiveKit JWT for a participant (role-based permissions) |
| `endMeeting` | HTTP/Webhook | Close LiveKit room, trigger recording processing |
| `processRecording` | Webhook | Download from LiveKit Egress, encrypt, store in Supabase |
| `transcribeMeeting` | Async | Send recording to Deepgram → save transcript |
| `generateMeetingSummary` | Async | Claude processes transcript → summary + action items + follow-up |
| `scheduleMeeting` | HTTP | Create meeting from booking, send confirmations |
| `getBookingAvailability` | HTTP | Return available slots from calendar (public endpoint) |
| `bookMeeting` | HTTP | External booking → create meeting + send confirmations |
| `sendMeetingReminder` | Scheduled | Push + SMS + email reminders at 24h, 1h, 15min |
| `processAsyncVideo` | Webhook | Encode, thumbnail, encrypt, AI summary |
| `escalatePhoneToVideo` | HTTP | Bridge Telnyx PSTN call into LiveKit room via SIP |
| `saveMeetingCapture` | HTTP | Save freeze-frame/annotation to Storage + job photos |

---

## IMPLEMENTATION PHASES

```
TOTAL ESTIMATE: ~55-70 HOURS

PHASE 1 — Core Video Rooms (~20 hrs)
  - LiveKit integration (room creation, token generation, join flow)
  - 1-on-1 video calls (contractor ↔ client)
  - Browser join page (zero-download for clients)
  - Basic recording (with consent flow)
  - Meeting record in database + linked to job
  - meetings + meeting_participants tables
  - CRM: start meeting from job detail

PHASE 2 — Smart Room + Site Walk (~15 hrs)
  - Context panel (job info sidebar during call)
  - Freeze-frame + annotation system
  - Live photo capture → save to job photos
  - Rear camera optimization (mobile site walk mode)
  - Flashlight toggle during call
  - Laser pointer for remote participants
  - meeting_captures table

PHASE 3 — Scheduling + Booking (~10 hrs)
  - Booking type configuration (CRM settings)
  - Availability engine (calendar integration)
  - Public booking page (website + client portal)
  - Confirmation + reminder automation
  - meeting_booking_types table
  - getBookingAvailability + bookMeeting Edge Functions

PHASE 4 — AI Intelligence + Async (~12 hrs)
  - Deepgram transcription integration
  - Claude meeting summary generation
  - Action item extraction → task creation
  - Follow-up email drafting
  - Async video recording + sharing
  - async_videos table
  - Video reply threads

PHASE 5 — Advanced Features (~8 hrs)
  - Multi-party rooms (3+ participants)
  - Insurance conference role-based views
  - Phone-to-video escalation (Telnyx SIP bridge)
  - Document review + in-call e-signature
  - Team huddle with daily context
  - Meeting analytics dashboard

PHASE 6 — Polish (~5 hrs)
  - Meeting history/search in CRM
  - Recording playback with transcript sync
  - Async video embed in Client Portal
  - Website "Book a Consultation" widget
  - RBAC enforcement across all meeting types
```

---

## THE MOAT

```
WHAT ZOOM WILL NEVER HAVE:

1. JOB CONTEXT — Zoom doesn't know the customer, the job, the estimate,
   the photos, the claim number. ZAFTO rooms are pre-loaded with everything.

2. TRADE-SPECIFIC TOOLS — Freeze-frame + annotate on a live camera feed.
   Designed for "look at this crack in the foundation" not "let me share
   my screen."

3. AUTOMATIC DOCUMENTATION — Meeting ends, job record is updated.
   Photos saved, summary posted, tasks created, follow-up drafted.
   Zoom meeting ends and nothing happens.

4. BUILT-IN SCHEDULING — No Calendly, no separate tool. Book from the
   website, client portal, or CRM. Availability is real-time from the
   actual calendar.

5. ROLE-BASED VIEWS — Adjuster can't see your margins. Client can't see
   your internal notes. Each participant sees exactly what they should.

6. DATA GRAVITY — After 6 months, a contractor has:
   - 50+ meeting recordings documenting quality work
   - 200+ annotated photos from video walkthroughs
   - Complete history of every client interaction
   - AI-generated summaries of every conversation
   - Proof of every verbal agreement on video
   That data is locked into ZAFTO. Zoom has nothing.

7. ONE PLATFORM — Phone calls, video meetings, text messages, AI chat,
   email — all in one app. All linked to the same job. All searchable.
   No switching between 5 tools to communicate with one customer.
```

---

## DEPENDENCIES

| This System | Depends On |
|-------------|-----------|
| Job context | Core database migration (`Locked/29_DATABASE_MIGRATION.md`) |
| Recording encryption | Security architecture (`Locked/30_SECURITY_ARCHITECTURE.md`) Layer 4B |
| Phone escalation | Phone system (`Expansion/31_PHONE_SYSTEM.md`) |
| Booking on website | Website builder (`Expansion/28_WEBSITE_BUILDER_V2.md`) |
| Client Portal booking | Client portal (wired to Supabase) |
| Insurance conferences | Restoration/insurance module (`Locked/36_RESTORATION_INSURANCE_MODULE.md`) |
| AI intelligence | Universal AI architecture (`Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md`) |
| Calendar availability | CRM calendar (wired to Supabase) |
| E-signature in call | Digital Contract system (Doc 16 Appendix K, Moat Feature #2) |

---

## CHANGELOG

| Date | Change |
|------|--------|
| 2026-02-06 | Created. 6 meeting types, Smart Room context engine, AI meeting intelligence, scheduling engine, async video, phone-to-video escalation. LiveKit for WebRTC. ~55-70 hours across 6 phases. |
