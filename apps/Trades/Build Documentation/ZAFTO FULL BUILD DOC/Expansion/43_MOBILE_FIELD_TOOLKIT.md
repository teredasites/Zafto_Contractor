# ZAFTO MOBILE FIELD TOOLKIT
## Every Tool a Trade Professional Needs — In Their Pocket
### February 6, 2026

---

> **DATABASE:** Supabase PostgreSQL. See `Locked/29_DATABASE_MIGRATION.md`.
> **SECURITY:** 6-layer architecture. See `Locked/30_SECURITY_ARCHITECTURE.md`.
> **OFFLINE:** PowerSync (SQLite ↔ PostgreSQL). Every tool works offline, syncs when connected.
> **AI:** Claude API for intelligent assist across all tools. See `Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md`.
> **PHONE:** Telnyx VoIP. See `Expansion/31_PHONE_SYSTEM.md`.
> **VIDEO:** LiveKit WebRTC. See `Expansion/42_MEETING_ROOM_SYSTEM.md`.

---

## EXECUTIVE SUMMARY

The current mobile app has 14 field tools — all electrical-focused, all UI shells with zero backend. The platform now serves electricians, plumbers, HVAC techs, roofers, GCs, remodelers, solar installers, restoration/mitigation crews, inspectors, and more. The toolbox needs to match.

This document specs every tool that belongs on a trade professional's phone. Not calculators (Claude handles those). Not code references (Claude handles those). Real workflow tools that capture data, use phone hardware, and feed the business system.

**What's in this doc:**
- 12 universal field tools (6 existing + 6 new)
- 5 communication tools (phone, video, walkie-talkie, team chat, client messaging)
- 5 insurance/restoration tools
- 3 inspection/documentation tools
- Role-based and trade-based tool visibility
- Full database schema for new tools
- Implementation phases

**What this replaces:**
- Separate walkie-talkie radios ($50-200 per unit, break constantly, range limits)
- "Can you text me photos?" workflows
- Paper inspection checklists
- Separate moisture meter logging apps
- "I'll write it down later" daily logs that never get written
- Driving to the office to check the punch list

**Total new tools: ~25 (from current ~6 working)**
**Estimated hours: ~60-77 hrs (new tools only — phone/video/gap analysis tools counted elsewhere)**

---

## TOOL CATEGORIES

```
ZAFTO MOBILE TOOLKIT
├── UNIVERSAL TOOLS (11)
│   ├── Level ........................ EXISTS — hardware tool
│   ├── Datestamp Camera ............. EXISTS — GPS + timestamp photos
│   ├── Photo/Video Documentation .... EXISTS (PhotoService) — needs connection
│   ├── Time Clock + GPS ............. EXISTS — needs wiring
│   ├── Z AI Assistant ............... EXISTS — needs 6-layer upgrade
│   ├── Daily Job Log ................ NEW (Gap Analysis P0)
│   ├── Materials Tracker ............ NEW (Gap Analysis P0)
│   ├── Punch List ................... NEW (Gap Analysis P0)
│   ├── Change Order Capture ......... NEW (Gap Analysis P0)
│   ├── Job Completion Workflow ...... NEW (Gap Analysis P0)
│   └── Field Measurements ........... NEW
│
├── COMMUNICATION TOOLS (5)
│   ├── Business Phone ............... NEW mobile UI (spec in Doc 31)
│   ├── Meetings ................. NEW mobile UI (spec in Doc 42)
│   ├── Walkie-Talkie / PTT ......... NEW — full spec below
│   ├── Team Chat .................... NEW
│   └── Client Messaging ............. NEW mobile UI (spec in Docs 31, 40)
│
├── INSURANCE / RESTORATION TOOLS (5)
│   ├── Moisture Reading Logger ...... NEW (referenced in Doc 36)
│   ├── Drying Log ................... NEW (referenced in Doc 36)
│   ├── Restoration Equipment Tracker  NEW (referenced in Doc 36)
│   ├── Claim Documentation Camera ... NEW (referenced in Doc 36)
│   └── Xactimate Viewer ............ NEW (referenced in Doc 36)
│
└── INSPECTION / DOCUMENTATION TOOLS (3)
    ├── Inspection Checklist ......... NEW
    ├── Safety Checklist ............. NEW (variant of inspection)
    └── Site Survey .................. NEW
```

---

## UNIVERSAL TOOLS

### 1. Level (EXISTS)

**Status:** Working. Uses device accelerometer/gyroscope.
**What it does:** Digital spirit level using phone sensors.
**What needs to happen:** Nothing — this tool is functional as-is. May want to add ability to save a reading to a job record (photo of level + reading value).
**Priority:** Low — works fine.

**Roles:** Tech, Subcontractor
**Trades:** All

---

### 3. Datestamp Camera (EXISTS)

**Status:** UI exists. Saves locally only.
**What it does:** Camera that overlays GPS coordinates, timestamp, job info, and company branding on photos.
**What needs to happen:** Wire to Supabase Storage via PhotoService. Auto-link to current job. Support insurance-required metadata (EXIF preservation for legal documentation).
**Priority:** P1 — core documentation tool.

**Roles:** All field roles
**Trades:** All — especially insurance/restoration (legal documentation requirements)

---

### 4. Photo/Video Documentation (EXISTS — PhotoService unused)

**Status:** `photo_service.dart` (492 lines) is complete with Firebase Storage, RBAC, thumbnails, company-scoped paths. NOTHING in the app uses it.
**What it does:** Categorized photo and video capture linked to jobs.
**What needs to happen:** Migrate PhotoService to Supabase Storage. Connect to all field tools. Add video capture. Add category system.

**Photo Categories:**
| Category | Website Eligible | Internal Only |
|----------|:---------------:|:-------------:|
| Before work | YES | |
| During work | YES | |
| After / completed | YES | |
| Team / crew | YES | |
| Equipment | YES | |
| Damage documentation | | YES |
| Safety hazard | | YES |
| Moisture reading | | YES |
| Inspector notes | | YES |
| Insurance evidence | | YES |
| Code violation | | YES |
| Material/receipt | | YES |

**Roles:** All field roles + Office (viewing)
**Trades:** All

---

### 5. Time Clock + GPS (EXISTS)

**Status:** UI exists with `LocationTrackingService` (449 lines). Saves locally only.
**What it does:** Clock in/out with continuous GPS tracking, break management, activity detection.
**What needs to happen:** Wire to Supabase. PowerSync for offline clock-in. GPS pings stored in `time_entries` with `location_pings` JSONB array.
**Priority:** P0 — required for payroll, labor cost tracking, geofencing.

**Features already coded:**
- `LocationPing` class (timestamp, lat/lng, accuracy, speed, heading, altitude, activity, battery)
- Configurable ping interval (default 5 min)
- Activity detection (stationary, walking, driving)
- Break tracking (pause/resume GPS)
- Mileage calculation

**Roles:** Tech, Subcontractor (clock themselves), Office/Admin (view team)
**Trades:** All

---

### 6. Z AI Assistant (EXISTS)

**Status:** AI chat exists. Cloud Functions deployed. Needs Universal AI upgrade (Doc 35).
**What it does:** AI assistant with trade knowledge, business data access, voice input.
**What needs to happen:** Upgrade to 6-layer architecture (Doc 35). Connect to all business data. Add tool-calling for actions (create job, update status, look up customer). Voice-first for field use.
**Priority:** P1 — already partially working, needs the full architecture.

**Roles:** All (role-based AI output per Doc 35 Layer 6)
**Trades:** All (trade-specific knowledge per Doc 35 Layer 2)

---

### 7. Daily Job Log (NEW — Gap Analysis P0)

**Status:** Does not exist. CRM only knows job status, not what was actually done.
**What it does:** End-of-day documentation of work performed, hours, conditions, issues.

```
DAILY JOB LOG SCREEN:
┌──────────────────────────────────────────────────────┐
│  Daily Log — 123 Oak Street                          │
│  February 6, 2026                                    │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Work Performed Today                                │
│  ┌──────────────────────────────────────────────────┐│
│  │ Completed rough-in for kitchen remodel.          ││
│  │ Installed 4 new 20A circuits. Pulled wire        ││
│  │ through attic to panel. Drywall team needs       ││
│  │ to wait 48hrs for inspection.                    ││
│  └──────────────────────────────────────────────────┘│
│                                                      │
│  [🎤 Voice to Text]                                  │
│                                                      │
│  Crew On Site                                        │
│  [✓] Mike Rodriguez (8 hrs)                          │
│  [✓] James Chen (6.5 hrs)                            │
│                                                      │
│  Materials Used                                      │
│  • 250ft 12/2 Romex — $87.50                         │
│  • 4x 20A breakers — $48.00                          │
│  • [+ Add Material]                                  │
│                                                      │
│  Photos (3)                                          │
│  [📷] [📷] [📷] [+ Add Photo]                        │
│                                                      │
│  Weather Conditions                                  │
│  [Auto-filled from location] 42°F, Clear             │
│                                                      │
│  Issues / Notes                                      │
│  ┌──────────────────────────────────────────────────┐│
│  │ Found knob-and-tube in attic wall. Client        ││
│  │ needs to decide on remediation scope.            ││
│  └──────────────────────────────────────────────────┘│
│                                                      │
│  [Save Draft]              [Submit Log →]            │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**Key features:**
- Voice-to-text for hands-free logging (dusty/wet hands)
- Auto-fill crew from time clock data (who was clocked in at this job today)
- Auto-fill weather from GPS location
- Photo attachment from job photos
- Materials used (auto-links to materials tracker and job costing)
- Saved to job record — visible in CRM job detail
- AI summary generation (optional — Z AI can clean up voice notes into professional log)
- Offline capable (PowerSync)

**Roles:** Tech (create), Admin/Owner/Office (view in CRM)
**Trades:** All
**Hours:** ~4-5 hrs

---

### 8. Materials Tracker (NEW — Gap Analysis P0)

**Status:** Does not exist. No way to log what was installed, breaking job costing and Equipment Passport.
**What it does:** Log materials and equipment used on a job.

**Key features:**
- Scan barcode/receipt to auto-populate (camera + AI extraction)
- Manual entry with search from Price Book
- Quantity, unit cost, markup
- Auto-link to job record and job costing
- Track installed equipment for Equipment Passport (feeds Home Portal)
- Receipt photo attachment
- Offline capable (PowerSync)

**Data flows to:**
- Job costing (CRM)
- Equipment Passport (Home Portal)
- Inventory deduction (if inventory module active)
- Invoice line items (auto-suggest)
- ZAFTO Books (expense categorization)

**Roles:** Tech (log), Office/Admin/Owner (view, approve)
**Trades:** All
**Hours:** ~4-5 hrs

---

### 9. Punch List (NEW — Gap Analysis P0)

**Status:** Does not exist. Jobs have 1 status, reality has 20 tasks.
**What it does:** Task checklist per job — what needs to be done, what's done, what's left.

**Key features:**
- Create from template (trade-specific templates) or blank
- Check off tasks as completed
- Photo per task (before/after)
- Assign tasks to specific crew members
- Progress percentage auto-calculated
- Client-visible version (share subset via Client Portal)
- AI can generate punch list from job description or scope of work
- Offline capable (PowerSync)

**Roles:** Tech (execute), Admin/Owner/Office (create, view, manage)
**Trades:** All — especially GCs and remodelers
**Hours:** ~5-6 hrs

---

### 10. Change Order Capture (NEW — Gap Analysis P0)

**Status:** Does not exist. Scope changes go undocumented, bid/invoice out of sync.
**What it does:** Document scope changes in the field with customer acknowledgment.

**Key features:**
- Describe the change (text + voice-to-text)
- Cost impact (additional materials + labor)
- Photo documentation of why change is needed
- Customer signature on device (e-signature pad)
- Auto-updates job scope and creates line item for invoice
- PDF generation for records
- Linked to job record in CRM
- Offline capable — customer signs on device, syncs when connected

**Roles:** Tech/Admin (create in field), Owner (approve if over threshold), Client (acknowledge/sign)
**Trades:** All — especially GCs, remodelers, restoration
**Hours:** ~4-5 hrs

---

### 11. Job Completion Workflow (NEW — Gap Analysis P0)

**Status:** Does not exist. Currently one-tap complete with no required steps.
**What it does:** Structured job close-out process ensuring nothing is missed.

**Configurable steps (toggle per company):**
1. Final photos (before/after comparison)
2. Punch list 100% complete
3. Customer walkthrough (checkbox or signature)
4. Final inspection passed (if applicable)
5. Equipment/tools removed from site
6. Job site cleaned
7. Customer satisfaction (quick rating)
8. Auto-generate invoice (from job data)
9. Auto-trigger review request (timed delay)
10. Schedule follow-up (if warranty work)

**Roles:** Tech (execute), Admin/Owner (configure required steps)
**Trades:** All
**Hours:** ~4 hrs

---

### 12. Field Measurements (NEW)

**Status:** Does not exist.
**What it does:** Log room/area measurements and dimensions tied to a job.

**Key features:**
- Room-by-room measurement entry
- Length, width, height, area auto-calculated
- Sketch pad for rough floor plans (finger drawing)
- Photo attachment per room
- Export measurements to bid/estimate
- Share with team via job record
- Offline capable

**Use cases:**
- HVAC: room volumes for load calculations (Z AI can calculate from measurements)
- Electrical: wire run distances
- Roofing: roof dimensions
- Remodeling: room dimensions for material estimates
- Restoration: affected area documentation

**Roles:** Tech (measure), Admin/Owner/Office (view)
**Trades:** All
**Hours:** ~5-6 hrs

---

## COMMUNICATION TOOLS

### 13. Business Phone (Mobile UI for Doc 31)

**Status:** Spec complete in `Expansion/31_PHONE_SYSTEM.md`. Mobile UI not built.
**What it does:** Full business phone through the app. Personal number never exposed.

**Mobile-specific features:**
- iOS CallKit / Android ConnectionService integration (native call experience)
- Caller ID from CRM contacts ("Sarah Johnson — 123 Oak St — Panel Upgrade")
- One-tap call from job detail, customer detail, or contact card
- Call recording toggle with state-based consent
- Voicemail with AI transcription
- SMS/text from business number

**This tool is the mobile access point for the full phone system. See Doc 31 for complete spec.**

**Roles:** All (per-employee phone lines)
**Trades:** All
**Hours:** Counted in Doc 31

---

### 14. Meetings (Mobile UI for Doc 42)

**Status:** Spec complete in `Expansion/42_MEETING_ROOM_SYSTEM.md`. Mobile UI not built.
**What it does:** Start/join video calls from the field. Site walk mode with rear camera.

**Mobile-specific features:**
- Start meeting from job detail ("Video call with customer")
- Site walk mode: rear camera with flashlight, freeze-frame, annotations
- Phone-to-video escalation (phone call → tap to add video)
- Bandwidth-adaptive (auto-reduce quality on poor cellular)
- Background audio continues when switching apps

**This tool is the mobile access point for the full meeting room system. See Doc 42 for complete spec.**

**Roles:** All field roles (start/join), Client/Adjuster (join via browser link)
**Trades:** All
**Hours:** Counted in Doc 42

---

### 15. Walkie-Talkie / Push-to-Talk (NEW)

**Status:** Not specced anywhere. Brand new feature.
**What it does:** Instant push-to-talk communication across your team. Like a radio, but unlimited range, zero hardware cost, built into the app you already use.

```
THE PITCH:

Every job site with 2+ people uses radios. Every single one.
- Motorola Talkabout: $50-80 per pair, 2-mile range, batteries die
- Motorola RM Series (commercial): $150-250 each, fragile, lost constantly
- 10-person crew: $1,500-2,500 in radios that break, get lost, and have range limits

ZAFTO Walkie-Talkie:
- $0 hardware (uses the phone they already carry)
- Unlimited range (works over WiFi + cellular)
- Every message optionally logged and linked to the job
- Channels per job site, per crew, or company-wide
- Works alongside every other ZAFTO tool
- Toggle on/off (respect personal phone boundaries)
```

### Architecture

```
INFRASTRUCTURE: LiveKit Audio Rooms (same provider as Meetings, Doc 42)

WHY LIVEKIT:
- Already integrated for meeting rooms — zero additional provider cost
- Audio-only rooms are extremely lightweight (~$0.002/min/participant)
- Sub-100ms latency (faster than actual radios over distance)
- Works on WiFi + cellular seamlessly
- Handles network transitions (WiFi → cellular) without dropping

COST:
- 5-person crew, 30 min actual talk time per person per day:
  5 × 30 × $0.002 = $0.30/day = ~$6.60/month
- vs. $1,500+ in radio hardware that depreciates

FALLBACK:
Same carrier abstraction as meeting rooms. If LiveKit ever fails,
swap to Daily.co or Twilio without touching app code.
```

### How It Works

```
PERSISTENT FLOATING PTT BUTTON:

When a user joins a channel, a floating button appears on screen.
It stays on top of EVERYTHING — job details, field tools, photos, maps.
It never goes away until you leave the channel.

┌─────────────────────────────────────────────────────────┐
│                                                         │
│   (whatever screen the user is on)                      │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
│                                               ┌──────┐  │
│                                               │ PTT  │  │
│                                               │  🎙   │  │
│                                               └──────┘  │
│                                                         │
│   [Home]  [Tools]  [Jobs]  [Invoices]  [More]           │
└─────────────────────────────────────────────────────────┘

PRESS AND HOLD → Talk (button turns red, vibrate on press)
RELEASE → Stop talking (button returns to idle)
TAP (don't hold) → Expand channel panel

EXPANDED VIEW:
┌─────────────────────────────────────────────────────────┐
│  ┌───────────────────────────────────────────────────┐  │
│  │  🔊 123 Oak Street — Kitchen Remodel              │  │
│  │                                                   │  │
│  │  Online (3):                                      │  │
│  │  ● Mike Rodriguez        (idle)                   │  │
│  │  ● James Chen            (idle)                   │  │
│  │  ● You                   (idle)                   │  │
│  │                                                   │  │
│  │  Recent:                                          │  │
│  │  Mike: "Wire's pulled, ready for panel" (2m ago)  │  │
│  │  You: "Copy, heading up now" (1m ago)             │  │
│  │                                                   │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │         [ PUSH TO TALK ]                    │  │  │
│  │  │              🎙                              │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │                                                   │  │
│  │  [Switch Channel ▾]  [Mute 🔇]  [Leave Channel]  │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│   [Home]  [Tools]  [Jobs]  [Invoices]  [More]           │
└─────────────────────────────────────────────────────────┘
```

### Channel System

```
CHANNEL TYPES:

1. JOB CHANNEL (auto-created)
   - Created automatically when 2+ team members are assigned to a job
   - Named after the job: "123 Oak Street — Kitchen Remodel"
   - Only assigned crew can join
   - Auto-archived when job completes

2. CREW CHANNEL (manual)
   - Created by Admin/Owner for a standing team
   - "Crew A", "Electrical Team", "Install Crew"
   - Persists across jobs
   - Members managed in CRM Settings → Team

3. COMPANY CHANNEL (always exists)
   - "All Hands" — every employee
   - Owner/Admin can broadcast company-wide
   - Used for emergency comms, weather delays, announcements

4. DIRECT (1-on-1)
   - Quick PTT to a single person
   - Like a walkie-talkie with a private channel
   - No channel setup needed — just tap the person

CHANNEL RULES:
- Max 20 participants per channel (LiveKit room limit is higher, but 20 is practical)
- Channels auto-mute when user is on a phone call or in a video meeting
- Background audio: PTT audio plays through phone speaker even when app is backgrounded
- Do Not Disturb: respects device DND settings
- Notification: vibrate + brief tone when someone talks on your channel
```

### Voice Message Logging (Optional)

```
LOGGING MODES (configured per company in Settings):

1. EPHEMERAL (default)
   - Audio plays in real-time, not stored
   - Like a real walkie-talkie — hear it or miss it
   - Zero storage cost
   - Maximum privacy

2. RECENT HISTORY
   - Last 30 minutes of messages cached locally on device
   - Replay what you missed
   - Auto-deleted after 30 minutes
   - Not synced to server

3. FULL LOGGING
   - All voice messages transcribed (Deepgram) and stored as text
   - Linked to job record
   - Searchable in CRM
   - Useful for: dispute resolution, accountability, training
   - Storage: text only (transcripts), not audio files
   - Retention: follows company recording retention policy

4. AUDIO LOGGING
   - Full audio clips stored in Supabase Storage
   - Encrypted with company key (Doc 30 Layer 4B)
   - Linked to job record
   - Maximum accountability
   - Higher storage cost
   - Consent: follows same state-based rules as phone recording (Doc 31)
```

### PTT Button Behavior

```
STATES:

IDLE (gray/dark):
  - Channel connected, nobody talking
  - Small badge shows channel name

LISTENING (blue pulse):
  - Someone else is talking
  - Speaker name shown above button
  - Audio plays through phone speaker

TALKING (red, enlarged):
  - User is holding PTT button
  - Haptic feedback on press
  - Visual broadcast indicator
  - Timer shows talk duration

MUTED (crossed out):
  - User muted — won't hear incoming
  - PTT still works to transmit

OFFLINE (dimmed):
  - No network connection
  - Shows "Offline — PTT unavailable"
  - Auto-reconnects when network returns

BACKGROUND BEHAVIOR:
- App backgrounded: audio still plays through speaker
- Phone locked: audio still plays (background audio session)
- On a call: PTT auto-mutes, visual indicator in call UI
- In meeting room: PTT auto-mutes
- User can manually unmute in any scenario
```

### Quick Actions

```
FROM JOB DETAIL SCREEN:
  [📞 Call]  [📹 Video]  [🎙 PTT]  [💬 Chat]

Tapping PTT from a job detail:
  → Auto-joins that job's channel
  → If already in a different channel, shows "Switch to 123 Oak St?"
  → Floating PTT button appears

FROM TEAM SCREEN:
  Tap any team member → [Call]  [PTT]  [Message]
  → Direct PTT to that person (1-on-1 channel)

FROM NOTIFICATION:
  "Mike is talking on 123 Oak Street channel"
  → Tap to open expanded PTT view
```

**Roles:** Tech, Subcontractor, Admin, Owner (configurable per company)
**Trades:** All — especially GCs (multi-crew coordination), restoration (multi-room jobs), roofing (ground-to-roof comms)

### Database

```sql
CREATE TABLE walkie_talkie_channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id),               -- NULL for crew/company channels

  -- Channel info
  name TEXT NOT NULL,                             -- "123 Oak Street" or "Crew A" or "All Hands"
  channel_type TEXT NOT NULL,                     -- job, crew, company, direct
  livekit_room_name TEXT,                         -- LiveKit room identifier (created on first join)

  -- Members
  member_user_ids UUID[] DEFAULT '{}',            -- Explicit members (crew/company channels)
                                                  -- Job channels: derived from job assignments

  -- Config
  is_active BOOLEAN DEFAULT true,
  logging_mode TEXT DEFAULT 'ephemeral',          -- ephemeral, recent, full_logging, audio_logging
  max_participants INTEGER DEFAULT 20,

  -- Auto-management
  auto_archive_on_job_complete BOOLEAN DEFAULT true,
  archived_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES users(id)
);

ALTER TABLE walkie_talkie_channels ENABLE ROW LEVEL SECURITY;
CREATE POLICY "channel_isolation" ON walkie_talkie_channels
  USING (company_id = current_setting('app.company_id')::UUID);
CREATE INDEX idx_channels_company ON walkie_talkie_channels(company_id, is_active);
CREATE INDEX idx_channels_job ON walkie_talkie_channels(job_id) WHERE job_id IS NOT NULL;

CREATE TABLE walkie_talkie_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  channel_id UUID NOT NULL REFERENCES walkie_talkie_channels(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id),

  -- Message
  sender_id UUID NOT NULL REFERENCES users(id),
  sender_name TEXT NOT NULL,
  duration_seconds INTEGER,                       -- Talk duration
  transcript TEXT,                                -- Deepgram transcription (if logging enabled)
  audio_path TEXT,                                -- Supabase Storage path (if audio logging)

  -- Metadata
  sent_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE walkie_talkie_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "message_isolation" ON walkie_talkie_messages
  USING (company_id = current_setting('app.company_id')::UUID);
CREATE INDEX idx_ptt_messages_channel ON walkie_talkie_messages(channel_id, sent_at DESC);
CREATE INDEX idx_ptt_messages_job ON walkie_talkie_messages(job_id) WHERE job_id IS NOT NULL;
```

### Edge Functions

| Function | Trigger | Purpose |
|----------|---------|---------|
| `createPTTChannel` | HTTP | Create LiveKit audio room for a channel |
| `joinPTTChannel` | HTTP | Generate LiveKit token for participant (audio-only, PTT mode) |
| `leavePTTChannel` | HTTP | Remove participant, close room if empty |
| `transcribePTTMessage` | Webhook | Deepgram transcription of voice clip (if logging enabled) |

### Implementation

| Phase | What | Hours |
|-------|------|:-----:|
| Phase 1 | Core PTT (LiveKit audio rooms, floating button, press-to-talk, job channels) | ~8 |
| Phase 2 | Channel system (crew, company, direct) + expanded UI + channel switching | ~5 |
| Phase 3 | Logging modes (transcription, audio storage) + CRM integration | ~5 |
| **TOTAL** | | **~18** |

**Hours:** ~18 hrs
**Dependencies:** LiveKit integration (from Doc 42 Phase 1), Telnyx (from Doc 31)

---

### 16. Team Chat (NEW)

**Status:** Not specced as standalone mobile tool.
**What it does:** Text messaging between team members, organized by channels and job threads.

**Key features:**
- Job-linked threads (every job gets a chat thread automatically)
- Team channels (same structure as walkie-talkie: crew, company)
- Direct messages (1-on-1)
- Photo/file sharing in chat
- @mentions with push notifications
- Read receipts
- Offline: messages queue locally, send when connected (PowerSync)
- Chat history searchable in CRM

```
NOT building Slack. Building simple, fast team messaging:
- No reactions, no threads-within-threads, no apps, no integrations
- Just: type message, send, done
- Organized by: job, crew, company, direct
- Everything linked to business context
```

**Database:**

```sql
CREATE TABLE team_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Context
  channel_type TEXT NOT NULL,                     -- job, crew, company, direct
  channel_id TEXT NOT NULL,                       -- job_id, crew channel name, "company", or recipient user_id
  job_id UUID REFERENCES jobs(id),               -- Set if channel_type = 'job'

  -- Message
  sender_id UUID NOT NULL REFERENCES users(id),
  sender_name TEXT NOT NULL,
  message_text TEXT,
  attachment_path TEXT,                           -- File/photo in Supabase Storage
  attachment_type TEXT,                           -- image, document, voice_note

  -- Mentions
  mentioned_user_ids UUID[] DEFAULT '{}',

  -- Status
  is_edited BOOLEAN DEFAULT false,
  edited_at TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT false,              -- Soft delete

  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE team_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "message_isolation" ON team_messages
  USING (company_id = current_setting('app.company_id')::UUID);
CREATE INDEX idx_team_messages_channel ON team_messages(company_id, channel_type, channel_id, created_at DESC);
CREATE INDEX idx_team_messages_job ON team_messages(job_id, created_at DESC) WHERE job_id IS NOT NULL;

CREATE TABLE team_message_reads (
  user_id UUID NOT NULL REFERENCES users(id),
  channel_type TEXT NOT NULL,
  channel_id TEXT NOT NULL,
  last_read_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, channel_type, channel_id)
);

ALTER TABLE team_message_reads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "read_isolation" ON team_message_reads
  USING (user_id = auth.uid());
```

**Roles:** All internal roles (Tech, Admin, Owner, Office)
**Trades:** All
**Hours:** ~8-10 hrs

---

### 17. Client Messaging (Mobile UI for Docs 31, 40)

**Status:** SMS spec'd in Doc 31 (Calls), cross-channel in Doc 40 (Dashboard). Mobile UI not built.
**What it does:** Text/SMS customers from within job context. Business number, not personal.

**Mobile-specific features:**
- Send SMS from job detail screen ("Text customer about ETA")
- Template messages (running late, on my way, job complete, review request)
- Auto-link messages to customer record and job record
- Photo sharing via MMS
- Two-way: customer replies come back to the app
- Uses business phone number (Telnyx, Doc 31), not personal

**Roles:** Tech (from assigned jobs), Office/Admin/Owner (any customer)
**Trades:** All
**Hours:** Counted in Docs 31 and 40

---

## INSURANCE / RESTORATION TOOLS

> **All tools in this section are activated via progressive disclosure (Doc 37).**
> A solo electrician never sees these. They appear when insurance_claim or restoration
> features are enabled for the company.

### 18. Moisture Reading Logger (NEW — referenced in Doc 36)

**Status:** Referenced in `Locked/36_RESTORATION_INSURANCE_MODULE.md` but no mobile UI spec.
**What it does:** Log moisture meter readings by location in a structure, track drying progress over time, generate legally required drying documentation.

```
MOISTURE LOGGER SCREEN:
┌──────────────────────────────────────────────────────┐
│  Moisture Readings — 456 Elm Ave (Water Loss)        │
│  Day 3 of Drying                                     │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Room: Kitchen          Material: Hardwood Floor     │
│                                                      │
│  Current Reading: [  18.5  ] %                       │
│  Dry Standard:     12.0%                             │
│  Status:           ● DRYING (above standard)         │
│                                                      │
│  Reading History:                                    │
│  ┌────────────────────────────────────────────────┐  │
│  │  📈                                            │  │
│  │       ·                                        │  │
│  │         ·                                      │  │
│  │           ·    ·                               │  │
│  │  ─────────────────── 12.0% (dry standard)     │  │
│  │                                                │  │
│  │  Day 1  Day 2  Day 3                           │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  [📍 Mark on Floor Plan]  [📷 Photo]                 │
│                                                      │
│  All Readings Today (14 of 32 points):               │
│  ✓ Kitchen / Hardwood — 18.5% (was 32.1%)           │
│  ✓ Kitchen / Subfloor — 22.3% (was 41.0%)           │
│  ✓ Kitchen / Drywall N — 15.2% (was 28.7%)          │
│  ○ Kitchen / Drywall S — not yet measured            │
│  ○ Kitchen / Cabinet base — not yet measured         │
│  ...                                                 │
│                                                      │
│  [Save Reading]         [Complete Room →]            │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**Key features:**
- Define measurement points per room (floor, walls, ceiling, cabinets, etc.)
- Log readings at each point per day
- Track drying curve over time (graph visualization)
- Compare against dry standard per material type
- Photo per reading point
- Floor plan markup (optional)
- Generate drying report (PDF — legally required for insurance claims)
- Auto-populate from previous day's points (just update readings)
- Flag readings that are rising (potential problem)
- Offline capable (critical — basements have no signal)

**Uses existing table:** `moisture_readings` from Doc 36

**Roles:** Tech (restoration crew), Admin/Owner (view/manage)
**Trades:** Restoration/Mitigation, Plumbing (water damage)
**Hours:** ~6-8 hrs

---

### 19. Drying Log (NEW — referenced in Doc 36)

**Status:** Referenced in Doc 36. No mobile UI spec.
**What it does:** Daily equipment placement and environmental documentation required by insurance carriers and IICRC S500 standard.

**Key features:**
- Log all drying equipment placement per room (dehumidifiers, air movers, injectidry)
- Record environmental conditions (temperature, humidity, GPP)
- Capture equipment runtime hours
- Photo documentation of equipment placement
- Daily sign-off (tech signature)
- Generates IICRC-compliant drying log report (PDF)
- Required by insurance carriers for claim payment
- These documents are LEGAL records — immutable after sign-off

**Uses existing table:** Part of `moisture_readings` + job metadata from Doc 36

**Roles:** Tech (restoration crew), Admin/Owner (review, countersign)
**Trades:** Restoration/Mitigation
**Hours:** ~4-5 hrs

---

### 20. Restoration Equipment Tracker (NEW — referenced in Doc 36)

**Status:** Referenced in Doc 36. No mobile UI spec.
**What it does:** Track what drying/restoration equipment is deployed where, runtime hours, and pickup scheduling.

**Key features:**
- Equipment inventory (dehumidifiers, air movers, injectidry, hydroxyl generators, etc.)
- Deploy equipment to a job (assign units to rooms)
- Log runtime hours per unit per day
- Schedule pickup when drying complete
- Equipment maintenance tracking (filter changes, calibration)
- Revenue tracking per unit (equipment rental billing to insurance)
- Barcode/QR scan for quick check-in/check-out
- Map view: where is all our equipment right now?

**Uses existing table:** `restoration_equipment` from Doc 36

**Roles:** Tech (deploy, log hours), Admin/Owner (manage inventory, billing)
**Trades:** Restoration/Mitigation
**Hours:** ~5-6 hrs

---

### 21. Claim Documentation Camera (NEW — referenced in Doc 36)

**Status:** Datestamp Camera exists but doesn't have insurance-specific features.
**What it does:** Specialized camera mode for insurance claim documentation.

**Key features beyond standard datestamp camera:**
- Insurance-specific photo categories:
  - Source of loss
  - Affected areas (per room)
  - Equipment damage
  - Pre-existing conditions
  - Repair progress
  - Completed repairs
- Auto-tag with claim number and adjuster info
- EXIF data preservation (legally required for evidence)
- Sequential numbering per claim
- Generate photo report (PDF with descriptions per photo — adjusters love this)
- Carrier-specific report formats (if known)

**Roles:** Tech (capture), Admin/Owner (manage, share with adjuster)
**Trades:** Restoration, Roofing, GC (any insurance claim work)
**Hours:** ~3-4 hrs (extends existing datestamp camera)

---

### 22. Xactimate Viewer (NEW — referenced in Doc 36)

**Status:** Referenced in Doc 36 for ESX interop. No mobile UI spec.
**What it does:** View and reference Xactimate estimate line items in the field.

**Key features:**
- Import Xactimate ESX file (uploaded via CRM or email)
- Browse line items by room/category
- See scope of work per room while on site
- Compare actual work against estimate line items
- Flag items that need supplement (scope change discovered in field)
- Offline capable (estimate data cached locally)

**Note:** This is READ-ONLY viewing of Xactimate data. Full Xactimate interop (export, ESX generation) is handled in the CRM per Doc 36.

**Roles:** Tech (view), Admin/Owner (upload, manage)
**Trades:** Restoration, Roofing (insurance work)
**Hours:** ~4-5 hrs

---

## INSPECTION / DOCUMENTATION TOOLS

### 23. Inspection Checklist (NEW)

**Status:** Does not exist.
**What it does:** Configurable checklists for inspections, quality checks, and compliance verification.

```
INSPECTION CHECKLIST SCREEN:
┌──────────────────────────────────────────────────────┐
│  Rough-In Electrical Inspection                      │
│  123 Oak Street — Kitchen Remodel                    │
│  Inspector: Mike Rodriguez                           │
├──────────────────────────────────────────────────────┤
│                                                      │
│  WIRING                                    4/6 ✓     │
│  ├── [✓] Wire properly secured (within 12" of box)  │
│  ├── [✓] Correct wire gauge for circuit amperage     │
│  ├── [✓] Ground wires properly connected             │
│  ├── [✗] Junction boxes accessible (FAIL)            │
│  │       📷 Photo attached                           │
│  │       Note: "Box behind cabinet, needs relocation"│
│  ├── [✓] Wire fill within conduit limits             │
│  └── [ ] Nail plates installed where required        │
│                                                      │
│  BOXES & PANELS                            0/4       │
│  ├── [ ] Panel clearance (36" front, 30" wide)      │
│  ├── [ ] Box fill calculations correct               │
│  ├── [ ] Knockouts properly sealed                   │
│  └── [ ] Panel directory updated                     │
│                                                      │
│  Progress: 4 of 10 checked (40%)                     │
│  Failures: 1                                         │
│                                                      │
│  [Save Draft]         [Complete Inspection →]        │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**Key features:**
- Template library per trade (electrical rough-in, plumbing rough-in, HVAC, roofing, final, etc.)
- Custom template builder (Admin/Owner can create)
- Pass / Fail / N/A per item
- Required photo on failure
- Notes per item
- Digital signature on completion
- Generates inspection report (PDF)
- Linked to job record
- Pass/fail summary visible in CRM job detail
- AI can suggest relevant checklist based on job type and trade
- Offline capable

**Database:**

```sql
CREATE TABLE inspection_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),       -- NULL for system templates
  trade TEXT,                                      -- electrical, plumbing, hvac, roofing, general, etc.
  name TEXT NOT NULL,                              -- "Rough-In Electrical Inspection"
  description TEXT,
  items JSONB NOT NULL DEFAULT '[]',              -- [{section, title, description, requires_photo_on_fail}]
  is_system BOOLEAN DEFAULT false,                 -- System-provided templates
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE inspection_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "template_isolation" ON inspection_templates
  USING (company_id IS NULL OR company_id = current_setting('app.company_id')::UUID);

CREATE TABLE inspection_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id),
  template_id UUID REFERENCES inspection_templates(id),

  -- Inspection info
  title TEXT NOT NULL,
  inspector_id UUID NOT NULL REFERENCES users(id),
  inspector_name TEXT NOT NULL,

  -- Results
  items JSONB NOT NULL DEFAULT '[]',              -- [{item_title, status: pass|fail|na, note, photo_path}]
  total_items INTEGER DEFAULT 0,
  passed_items INTEGER DEFAULT 0,
  failed_items INTEGER DEFAULT 0,
  na_items INTEGER DEFAULT 0,

  -- Completion
  status TEXT NOT NULL DEFAULT 'in_progress',     -- in_progress, completed, signed
  completed_at TIMESTAMPTZ,
  signature_path TEXT,                             -- Inspector signature image

  -- Overall result
  overall_result TEXT,                             -- pass, fail, conditional

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE inspection_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY "inspection_isolation" ON inspection_results
  USING (company_id = current_setting('app.company_id')::UUID);
CREATE INDEX idx_inspections_job ON inspection_results(job_id) WHERE job_id IS NOT NULL;
```

**Roles:** Tech/Inspector (execute), Admin/Owner (create templates, view results), Office (view results)
**Trades:** All
**Hours:** ~8-10 hrs

---

### 24. Safety Checklist (NEW — variant of Inspection Checklist)

**Status:** Does not exist.
**What it does:** OSHA and job site safety documentation. Uses the same inspection engine with safety-specific templates.

**Pre-built safety templates:**
- Daily Job Site Safety (general)
- Confined Space Entry
- Hot Work Permit
- Fall Protection Verification
- Electrical Safety / Lockout-Tagout
- Excavation / Trench Safety
- Scaffolding Inspection
- Ladder Inspection

**Key additions beyond standard inspection:**
- Safety incident logging (near-miss, injury, property damage)
- Toolbox talk documentation (brief safety meeting record)
- Emergency contact quick-access
- Safety certification verification (is this person certified for this task?)
- Linked to company's safety compliance record

**Uses same tables as Inspection Checklist** (inspection_templates + inspection_results with `category = 'safety'`)

**Roles:** All field roles (execute), Admin/Owner (manage, compliance reporting)
**Trades:** All — especially GCs (OSHA requirements), restoration (confined spaces), roofing (fall protection)
**Hours:** ~3-4 hrs (shares engine with Inspection Checklist)

---

### 25. Site Survey (NEW)

**Status:** Does not exist.
**What it does:** Structured initial assessment of a job site before work begins.

**Key features:**
- Trade-specific survey templates (electrical assessment, plumbing assessment, etc.)
- Room-by-room walkthrough with notes and photos
- Existing conditions documentation
- Access issues, hazards, special requirements
- Measurements integration (links to Field Measurements tool)
- Auto-generates preliminary scope of work for bidding
- Customer can sign acknowledging existing conditions (liability protection)
- Feeds directly into bid generation (Z AI can create bid from survey data)

**Roles:** Tech/Admin (conduct survey), Owner (review)
**Trades:** All
**Hours:** ~4-5 hrs

---

## TOOL VISIBILITY BY ROLE

| Tool | Owner | Admin | Office | Tech | Sub | CPA |
|------|:-----:|:-----:|:------:|:----:|:---:|:---:|
| Level | Y | Y | - | Y | Y | - |
| Datestamp Camera | Y | Y | - | Y | Y | - |
| Photo/Video Documentation | Y | Y | View | Y | Y | - |
| Time Clock + GPS | Y | Y | View | Y | Y | - |
| Z AI Assistant | Y | Y | Y | Y | Limited | - |
| Daily Job Log | Y | Y | View | Y | - | - |
| Materials Tracker | Y | Y | View | Y | - | - |
| Punch List | Y | Y | Y | Y | View | - |
| Change Order Capture | Y | Y | View | Y | - | - |
| Job Completion | Y | Y | View | Y | - | - |
| Field Measurements | Y | Y | View | Y | Y | - |
| Business Phone | Y | Y | Y | Y | - | - |
| Meetings | Y | Y | Y | Y | - | - |
| Walkie-Talkie | Y | Y | - | Y | Y | - |
| Team Chat | Y | Y | Y | Y | - | - |
| Client Messaging | Y | Y | Y | Y* | - | - |
| Moisture Logger | Y | Y | - | Y | - | - |
| Drying Log | Y | Y | - | Y | - | - |
| Equipment Tracker | Y | Y | View | Y | - | - |
| Claim Camera | Y | Y | - | Y | - | - |
| Xactimate Viewer | Y | Y | View | Y | - | - |
| Inspection Checklist | Y | Y | View | Y | Y | - |
| Safety Checklist | Y | Y | View | Y | Y | - |
| Site Survey | Y | Y | View | Y | - | - |

*Tech: client messaging only for assigned jobs

---

## TOOL VISIBILITY BY TRADE

Not every trade sees every tool. Progressive disclosure by trade:

| Tool | All | Electrical | Plumbing | HVAC | Roofing | GC | Restoration | Solar |
|------|:---:|:----------:|:--------:|:----:|:-------:|:--:|:-----------:|:-----:|
| Level | Y | | | | | | | |
| Datestamp Camera | Y | | | | | | | |
| Photo/Video | Y | | | | | | | |
| Time Clock | Y | | | | | | | |
| Z AI | Y | | | | | | | |
| Daily Job Log | Y | | | | | | | |
| Materials Tracker | Y | | | | | | | |
| Punch List | Y | | | | | | | |
| Change Orders | Y | | | | | | | |
| Job Completion | Y | | | | | | | |
| Measurements | Y | | | | | | | |
| Phone / Video / PTT | Y | | | | | | | |
| Team Chat | Y | | | | | | | |
| Client Messaging | Y | | | | | | | |
| Inspection Checklist | Y | | | | | | | |
| Safety Checklist | Y | | | | | | | |
| Site Survey | Y | | | | | | | |
| Moisture Logger | - | - | Y | - | - | - | Y | - |
| Drying Log | - | - | - | - | - | - | Y | - |
| Equipment Tracker | - | - | - | - | - | - | Y | - |
| Claim Camera | - | - | - | - | Y | Y | Y | - |
| Xactimate Viewer | - | - | - | - | Y | Y | Y | - |

**Rule:** All universal tools visible to all trades. Insurance/restoration tools visible only when `insurance_claim` or `restoration` features are enabled for the company (progressive disclosure per Doc 37).

---

## TOTAL HOURS SUMMARY

| Category | Tools | New Hours | Notes |
|----------|:-----:|:---------:|-------|
| Universal Tools (existing) | 6 | 0 | Already built — need wiring (counted in W1-W2) |
| Universal Tools (new) | 6 | ~26-32 | Daily log, materials, punch list, change orders, completion, measurements |
| Communication — Walkie-Talkie | 1 | ~18 | Full spec above |
| Communication — Team Chat | 1 | ~8-10 | Text messaging with channels |
| Communication — Phone/Video/Client | 3 | 0 | Counted in Docs 31, 42, 40 |
| Insurance/Restoration Tools | 5 | ~22-28 | Moisture, drying, equipment, claim camera, Xactimate |
| Inspection/Documentation | 3 | ~15-19 | Inspection checklist, safety, site survey |
| **TOTAL** | **25** | **~89-107** | |

**Note:** The 5 Gap Analysis P0 tools (daily log, materials, punch list, change orders, job completion) were previously estimated at ~22 hrs in Doc 26. This spec refines those estimates and adds the measurement tool, bringing the universal new tools total to ~26-32 hrs. The difference (~4-10 hrs) accounts for the richer feature set now specced (voice-to-text, AI assist, receipt scanning, etc.).

---

## NEW DATABASE TABLES (This Doc Only)

| Table | Purpose | Category |
|-------|---------|----------|
| `walkie_talkie_channels` | PTT channel definitions per company | Communication |
| `walkie_talkie_messages` | Voice message logging (if enabled) | Communication |
| `team_messages` | Team chat messages | Communication |
| `team_message_reads` | Read receipts per user per channel | Communication |
| `inspection_templates` | Checklist templates per trade | Inspection |
| `inspection_results` | Completed inspection records | Inspection |
| `field_measurements` | Room/area measurement records | Universal |
| `site_surveys` | Site assessment records | Documentation |

**Tables from other docs used by tools in this doc:**
- `moisture_readings` (Doc 36)
- `restoration_equipment` (Doc 36)
- `meetings`, `meeting_participants` (Doc 42)
- `walkie_talkie_channels` uses same LiveKit infrastructure as `meetings`

---

## NEW EDGE FUNCTIONS (This Doc Only)

| Function | Trigger | Purpose |
|----------|---------|---------|
| `createPTTChannel` | HTTP | Create LiveKit audio room for walkie-talkie channel |
| `joinPTTChannel` | HTTP | Generate audio-only LiveKit token for PTT participant |
| `leavePTTChannel` | HTTP | Remove participant, close room if empty |
| `transcribePTTMessage` | Webhook | Deepgram transcription of voice clip (if logging enabled) |
| `sendTeamMessage` | HTTP | Send team chat message, trigger push notification |
| `generateInspectionReport` | HTTP | Generate PDF inspection report from results |
| `generateDryingReport` | HTTP | Generate IICRC-compliant drying documentation PDF |
| `generateSurveyScope` | HTTP | AI generates preliminary scope of work from site survey data |

---

## IMPLEMENTATION PHASES

```
TOTAL ESTIMATE: ~89-107 HOURS (new tools only)

PHASE 1 — Core Field Tools (~22 hrs)
  ├── Daily Job Log (voice-to-text, crew auto-fill, weather)
  ├── Materials Tracker (barcode scan, Price Book search, receipt photo)
  ├── Punch List (templates, assignments, progress tracking)
  ├── Change Order Capture (e-signature, cost impact, PDF)
  └── Job Completion Workflow (configurable steps, auto-invoice)

PHASE 2 — Walkie-Talkie (~18 hrs)
  ├── Phase 2A: Core PTT (LiveKit audio rooms, floating button, PTT)
  ├── Phase 2B: Channel system (job/crew/company/direct, switching)
  └── Phase 2C: Logging (transcription, audio storage, CRM integration)

PHASE 3 — Insurance/Restoration Tools (~22-28 hrs)
  ├── Moisture Reading Logger (measurement points, drying curves, reports)
  ├── Drying Log (equipment placement, environmental conditions, IICRC compliance)
  ├── Restoration Equipment Tracker (deploy, runtime, pickup, billing)
  ├── Claim Documentation Camera (insurance categories, EXIF, photo reports)
  └── Xactimate Viewer (ESX import, line item browser, supplement flagging)

PHASE 4 — Inspection & Documentation (~15-19 hrs)
  ├── Inspection Checklist (template engine, pass/fail/photo, PDF reports)
  ├── Safety Checklist (OSHA templates, incident logging, toolbox talks)
  ├── Site Survey (room walkthrough, conditions documentation, AI scope gen)
  └── Field Measurements (room dimensions, sketch pad, bid export)

PHASE 5 — Team Chat (~8-10 hrs)
  ├── Message channels (job, crew, company, direct)
  ├── Photo/file sharing
  ├── Push notifications + @mentions
  └── Offline queue (PowerSync)

PHASE 6 — Polish & Integration (~4-5 hrs)
  ├── Tool discovery (role-based, trade-based visibility)
  ├── Cross-tool navigation (e.g., from inspection failure → create punch list item)
  ├── Unified search across all tool data
  └── CRM integration (all tool data visible in job detail)
```

---

## DEPENDENCIES

| This System | Depends On |
|-------------|-----------|
| All tools (offline) | PowerSync setup (`Locked/29_DATABASE_MIGRATION.md`) |
| All tools (storage) | Supabase Storage (`Locked/29_DATABASE_MIGRATION.md`) |
| Walkie-Talkie | LiveKit integration (`Expansion/42_MEETING_ROOM_SYSTEM.md` Phase 1) |
| Walkie-Talkie transcription | Deepgram (`Expansion/42_MEETING_ROOM_SYSTEM.md` Phase 4) |
| Business Phone UI | Phone system (`Expansion/31_PHONE_SYSTEM.md`) |
| Meetings UI | Meeting room system (`Expansion/42_MEETING_ROOM_SYSTEM.md`) |
| Client Messaging | Phone system SMS (`Expansion/31_PHONE_SYSTEM.md`) |
| Voice-to-text (daily log) | Deepgram or device speech-to-text |
| Moisture Logger | Restoration module (`Locked/36_RESTORATION_INSURANCE_MODULE.md`) |
| Drying Log | Restoration module (`Locked/36_RESTORATION_INSURANCE_MODULE.md`) |
| Equipment Tracker | Restoration module (`Locked/36_RESTORATION_INSURANCE_MODULE.md`) |
| Claim Camera | Insurance claims (`Locked/36_RESTORATION_INSURANCE_MODULE.md`) |
| Xactimate Viewer | ESX interop (`Locked/36_RESTORATION_INSURANCE_MODULE.md`) |
| Materials → Price Book | Price Book (in `00_MASTER_BUILD_PLAN.md`) |
| Materials → Inventory | Inventory module (`Expansion/27_BUSINESS_OS_EXPANSION.md`) |
| AI scope generation | Universal AI (`Expansion/35_UNIVERSAL_AI_ARCHITECTURE.md`) |
| Inspection templates | Trade-specific content curation by Tereda |

---

## THE COMPLETE MOBILE TOOLKIT

```
BEFORE (electrical app):                 AFTER (multi-trade business OS):
─────────────────────────               ────────────────────────────────
14 electrical field tools                24 tools for every trade
0 communication tools                    5 communication tools (phone, video,
                                           PTT, chat, client messaging)
0 insurance tools                        5 insurance/restoration tools
0 inspection tools                       3 inspection/documentation tools
All UI shells, 0 backend                 All wired, all offline-capable
Calculators (removed)                    Z AI handles calculations
Exam prep (removed)                      Scrapped
Code references (removed)               Z AI handles via RAG
One trade (electrical)                   8+ trades, role-based, progressive disclosure

TOTAL: 6 working tools → 24 tools, all connected to the business system
```

---

## CHANGELOG

| Date | Change |
|------|--------|
| 2026-02-06 | Created. 25 mobile tools across 4 categories. Walkie-talkie with persistent floating PTT button, job/crew/company channels, 4 logging modes. Insurance/restoration tools (moisture, drying, equipment, claim camera, Xactimate). Inspection engine with trade-specific templates. Team chat. 8 new tables, 8 new Edge Functions. ~89-107 hours across 6 phases. |
