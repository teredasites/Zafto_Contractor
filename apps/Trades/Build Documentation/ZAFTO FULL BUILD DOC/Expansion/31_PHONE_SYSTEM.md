# ZAFTO BUSINESS PHONE SYSTEM
## Complete VoIP Phone Replacement for Contractors
### February 5, 2026 — Session 30

---

> **DATABASE:** Supabase PostgreSQL. See `Locked/29_DATABASE_MIGRATION.md`.
> **INFRASTRUCTURE:** Telnyx Programmable Voice + WebRTC (Twilio as fallback).
> **PLATFORM:** Flutter (iOS CallKit + Android ConnectionService).
> **ENCRYPTION:** See `Locked/30_SECURITY_ARCHITECTURE.md` Layer 4B.

---

## EXECUTIVE SUMMARY

This is not a "click-to-call" button. This is a **full business phone system** that runs through the ZAFTO app.

Every employee gets a real phone number. Calls ring on their personal phone through the app — looks and feels like a native call. Customers see the business number, never the personal one. Internal calls are free. External calls cost pennies. When someone quits, their number stays with the company.

**What this replaces:**
- Company cell phones ($50-80/month per line)
- Separate work phones that techs lose/break
- Techs giving customers their personal number
- Lost business when someone leaves and takes "their" number
- Expensive business phone services (RingCentral, Grasshopper, etc.)

**What this costs:**
- Telnyx phone number: ~$1/month per line
- Voice minutes: ~$0.004/min (half of Twilio)
- Internal calls: $0 (VoIP over data/WiFi)
- 5-person company, moderate usage: ~$15-25/month total
- vs. 5 company phones: $250-400/month

---

## WHY TELNYX OVER TWILIO

```
PROVIDER COMPARISON:
────────────────────
                    TELNYX              TWILIO              BANDWIDTH
Voice (per min):    $0.004              $0.0085             $0.005
SMS (per msg):      $0.004              $0.0079             $0.005
Phone number:       $1/month            $1/month            $0.50/month
Network:            OWN carrier         Reseller            OWN carrier
Call quality:       Superior (direct)   Good (middleman)    Superior (direct)
WebRTC support:     Full SDK            Full SDK            Limited
Flutter SDK:        telnyx_flutter      twilio_voice        N/A
Uptime SLA:         99.999%             99.95%              99.999%

WHY TELNYX:
• Owns their own carrier network — no middlemen = better quality, lower cost
• Half the cost of Twilio for voice
• Same developer experience / API quality
• Direct carrier = lower latency calls
• telnyx_flutter package exists and is maintained

ARCHITECTURE NOTE:
We abstract the carrier behind our own Edge Functions.
If Telnyx ever becomes a problem, we swap to Twilio or Bandwidth
without touching a single line of app code. The app talks to OUR API.
Our API talks to whatever carrier we choose.
```

---

## HOW IT WORKS (User Experience)

### For The Owner (Setup)

```
CRM → PHONE SYSTEM

Step 1: "Get a business number"
        → Search local numbers by area code
        → Pick one: (203) 555-0100
        → This is the MAIN COMPANY LINE

Step 2: "Add lines for your team"
        → Robert Smith (Owner): (203) 555-0101  — DIRECT LINE
        → Sarah Johnson (Office): (203) 555-0102  — DIRECT LINE
        → Mike Torres (Lead Tech): (203) 555-0103  — DIRECT LINE
        → Jake Williams (Tech): (203) 555-0104  — DIRECT LINE
        → Tyler Chen (Apprentice): (203) 555-0105  — DIRECT LINE

Step 3: "Set up your main line"
        → Auto-attendant ON
        → "Thank you for calling Powers Electric.
           Press 1 for scheduling, Press 2 for billing,
           Press 3 to reach a specific person."
        → 1 → rings Sarah (Office)
        → 2 → rings Sarah (Office)
        → 3 → company directory
        → After hours → voicemail → transcribed → emailed

Done. Full business phone system. 5 minutes.
```

### For The Tech (Daily Use)

```
SCENARIO 1: Customer calls the company
──────────────────────────────────────
Customer dials (203) 555-0100 (main line)
  → Auto-attendant: "Press 1 for scheduling..."
  → Customer presses 1
  → Sarah's phone RINGS through ZAFTO app
  → Looks like a normal phone call (full screen, green answer)
  → Sarah answers from her personal iPhone
  → Customer has NO IDEA it's an app — sounds like a normal call
  → Call logged in CRM under that customer's record

SCENARIO 2: Tech needs to call a customer
──────────────────────────────────────────
Mike opens ZAFTO → goes to Job #4201 → taps customer phone number
  → Call goes out from (203) 555-0103 (Mike's business line)
  → Customer sees "Powers Electric" on caller ID
  → NOT Mike's personal (917) 555-8822
  → Call logged in CRM under that job

SCENARIO 3: Internal call (tech to tech)
────────────────────────────────────────
Jake needs to ask Mike a question
  → ZAFTO → Team → Mike Torres → [Call]
  → VoIP call over data/WiFi
  → E2E ENCRYPTED (Signal-level, see encryption section)
  → FREE — no Telnyx minutes used
  → Rings through ZAFTO app on Mike's phone

SCENARIO 4: Customer texts the business
────────────────────────────────────────
Customer texts (203) 555-0100: "Running 10 min late"
  → Text appears in ZAFTO app (not personal Messages)
  → Routed to whoever is assigned to that job today
  → Tech replies from ZAFTO → customer sees reply from business number
  → Text thread logged in CRM under customer record

SCENARIO 5: After hours call
─────────────────────────────
Customer calls at 9:30 PM
  → Auto-attendant: "You've reached Powers Electric.
     Our office hours are Monday-Friday 7am-5pm.
     For emergencies, press 1. Otherwise, leave a message."
  → Emergency → rings on-call tech's phone
  → Non-emergency → voicemail → AI transcribes → emails owner + office
```

### What The Phone Screen Looks Like (iOS)

```
When a business call comes in, iOS shows EXACTLY like a real call:

┌──────────────────────────────────────┐
│                                      │
│           ZAFTO                      │
│                                      │
│     Powers Electric                  │
│     (203) 555-0100                   │
│                                      │
│     John Smith                       │ ← pulled from CRM contacts
│     Customer                         │
│                                      │
│     Re: Job #4201 - Panel Upgrade    │ ← if linked to active job
│                                      │
│                                      │
│    [Decline]          [Accept]       │
│                                      │
└──────────────────────────────────────┘

This appears even when the phone is LOCKED.
Thanks to iOS CallKit + VoIP push notifications.

THE PHONE HAS TWO LINES:
Personal: (917) 555-8822  ← their AT&T/Verizon number
Business: (203) 555-0103  ← their ZAFTO line

Recent calls show both with clear labels.
Contacts from CRM appear in business call history.
It genuinely feels like dual-SIM — two separate phone identities.
```

---

## TECHNICAL ARCHITECTURE

### Core Stack

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  ZAFTO App   │     │  Supabase Edge   │     │     TELNYX       │
│  (Flutter)   │◄───►│  Functions       │◄───►│  Programmable    │
│              │     │                  │     │  Voice + SMS     │
│  WebRTC      │     │  Call routing    │     │                  │
│  CallKit     │     │  TwiML/TeXML    │     │  Phone numbers   │
│  VoIP Push   │     │  Webhooks       │     │  PSTN gateway    │
│              │     │  Call logging    │     │  Recording       │
└──────────────┘     └──────────────────┘     └──────────────────┘
       │                     │                        │
       │                     ▼                        │
       │              ┌──────────────┐                │
       │              │  Supabase    │                │
       └─────────────►│  PostgreSQL  │◄───────────────┘
                      │              │
                      │  Call logs   │
                      │  Voicemails  │
                      │  Recordings  │
                      │  Config      │
                      └──────────────┘

CARRIER ABSTRACTION LAYER:
Our Edge Functions wrap the carrier API.
App calls: /api/phone/make-call
Edge Function translates to Telnyx API.
If we switch carriers → update Edge Functions only.
App code never changes.
```

### How VoIP Calling Works

```
OUTBOUND CALL (Tech calls customer):
─────────────────────────────────────
1. Tech taps "Call" in ZAFTO app
2. App connects to Telnyx via WebRTC (data/WiFi)
3. Telnyx bridges to PSTN (real phone network)
4. Customer's phone rings — caller ID shows business number
5. Audio flows: App ←WebRTC→ Telnyx ←PSTN→ Customer phone
6. Call ends → logged in Supabase with duration, recording (if enabled)

INBOUND CALL (Customer calls business):
───────────────────────────────────────
1. Customer dials (203) 555-0100
2. Telnyx receives call on that number
3. Telnyx hits our webhook: /api/phone/incoming
4. Edge Function checks routing rules:
   - Business hours? → Auto-attendant or ring group
   - After hours? → Voicemail or on-call routing
   - Direct line? → Ring that specific person
5. Telnyx sends VoIP push notification to target user's device
6. iOS CallKit / Android ConnectionService shows incoming call screen
7. User answers → WebRTC connection established
8. Audio flows: Customer ←PSTN→ Telnyx ←WebRTC→ App
9. Call ends → logged in Supabase

INTERNAL CALL (Employee to employee):
──────────────────────────────────────
1. User taps team member's name → Call
2. App establishes direct WebRTC peer connection
3. Audio flows: App ←WebRTC (E2E encrypted)→ App
4. NO Telnyx minutes used — pure data
5. Even ZAFTO servers cannot hear this call
6. Call logged locally (metadata only, no recording possible)
```

### iOS CallKit + Android ConnectionService

```
iOS (CallKit):
- Calls appear on the lock screen like real calls
- Full-screen incoming call UI (green/red buttons)
- Appears in phone's recent call log
- Works with CarPlay and Bluetooth
- Works with Apple Watch
- Works when app is in background (VoIP push notifications)
- Do Not Disturb rules still apply

FLUTTER PACKAGES:
- flutter_callkit_incoming (for CallKit UI)
- telnyx_flutter (Telnyx's official Flutter SDK)
- flutter_webrtc (for WebRTC peer connections)

VoIP PUSH NOTIFICATIONS:
- iOS: Apple Push Notification Service (APNs) VoIP push type
  → Wakes app from background/killed state
  → Shows native incoming call screen
- Android: FCM high-priority push
  → ConnectionService shows incoming call screen
  → Works with car Bluetooth, Android Auto

NOTE ON FCM: This is Google's push DELIVERY service, not Firebase the database.
Just a notification pipeline. Same as how Signal uses FCM to tell your phone
"hey, you have a call" — the actual call is encrypted end-to-end.
```

---

## ENCRYPTION ARCHITECTURE

### The Three Tiers

```
TIER 1: INTERNAL CALLS (Employee ↔ Employee)
═════════════════════════════════════════════
ENCRYPTION: END-TO-END (Signal-level)
PROTOCOL: WebRTC DTLS-SRTP + optional Signal Protocol double ratchet

How it works:
- WebRTC establishes direct peer-to-peer connection
- DTLS handshake creates unique session encryption keys
- SRTP encrypts every audio packet
- Keys exist ONLY on the two devices
- ZAFTO servers relay signaling (who's calling whom) but NEVER audio
- Even if ZAFTO's entire infrastructure is compromised, internal calls are safe

Can ZAFTO listen? NO. Physically impossible. Audio never touches our servers.
Can a hacker intercept? NO. Encrypted end-to-end with per-session keys.
Can law enforcement wiretap? They'd need physical access to one of the devices.

INTERNAL MESSAGES (Employee ↔ Employee):
Same architecture. End-to-end encrypted.
Signal Protocol double ratchet for perfect forward secrecy.
Every message encrypted with a unique key.
Compromise one key → only one message exposed.


TIER 2: EXTERNAL CALLS (↔ Customer phone numbers)
══════════════════════════════════════════════════
ENCRYPTION: ENCRYPTED IN TRANSIT (TLS + SRTP)

Reality check: The public phone network (PSTN) is unencrypted.
When Mike calls a customer's cell phone, the audio MUST be decoded
at the carrier bridge to reach the phone network. No VoIP provider
on earth — not Telnyx, not Twilio, not Signal — can E2EE a call
to a regular phone number. That's physics, not a limitation.

What we DO:
- App → Telnyx: WebRTC with DTLS-SRTP (encrypted)
- Telnyx → PSTN: TLS + SRTP to carrier interconnect (encrypted in transit)
- Carrier → Customer phone: standard cellular (carrier-level encryption)

This is the SAME security level as every business phone system.
RingCentral, Grasshopper, Vonage — same architecture. We match them.

EXTERNAL SMS:
SMS is inherently unencrypted at the carrier level.
App → Telnyx: TLS 1.3 (encrypted in transit)
Telnyx → Carrier: carrier protocols
We encrypt stored message history (see Tier 3).


TIER 3: STORED DATA (Recordings, Voicemails, Logs, Transcripts)
═══════════════════════════════════════════════════════════════
ENCRYPTION: AES-256-GCM (per-company key, from Layer 4B)

Every call recording: encrypted with company key before storage
Every voicemail: encrypted with company key before storage
Every AI transcript: encrypted at rest in PostgreSQL
Every text message log: encrypted at rest

Follows the same envelope encryption architecture from 30_SECURITY_ARCHITECTURE.md:
- Company key encrypted by root key (HSM)
- Company key decrypts recordings on-demand
- Decryption happens on device, not server
- Even a full database breach reveals encrypted blobs

CALL METADATA (call log entries):
- NOT end-to-end encrypted (needed for querying/filtering)
- Protected by RLS (company_id isolation)
- Standard database encryption at rest
- Contains: who called whom, when, duration — NOT audio content
```

### Encryption Summary Table

```
CHANNEL                                ENCRYPTION LEVEL         CAN ZAFTO LISTEN?
──────────────────────────────────    ──────────────────────    ─────────────────
Internal voice (employee ↔ employee)  E2E (Signal-level)        ❌ No
Internal text (employee ↔ employee)   E2E (Signal-level)        ❌ No
External voice (↔ customer phone)     Encrypted in transit       ⚠️ At carrier bridge only
External SMS (↔ customer phone)       Encrypted in transit       ⚠️ At carrier bridge only
Stored recordings                     AES-256-GCM at rest        ❌ No (company key required)
Stored voicemails                     AES-256-GCM at rest        ❌ No (company key required)
Stored transcripts                    AES-256 at rest            ❌ No (encrypted in DB)
Call metadata (logs)                  RLS + DB encryption        ✅ Yes (needed for support)
```

### Marketing This

```
WHAT WE CAN HONESTLY SAY:
─────────────────────────
"Internal team calls and messages are encrypted end-to-end.
Even ZAFTO can't listen to your team's conversations."

"All call recordings and voicemails are encrypted with your
company's unique encryption key. Your data is your data."

"External calls are encrypted in transit using industry-standard
TLS and SRTP — the same security used by every major business
phone provider."

WHAT WE CANNOT SAY:
────────────────────
❌ "All calls are end-to-end encrypted" (external calls can't be)
❌ "Unhackable" (nothing is unhackable)
❌ "NSA-proof" (let's not go there)

WHAT COMPETITORS OFFER:
───────────────────────
RingCentral: TLS in transit, encryption at rest. NO E2E for internal.
Grasshopper: Basic TLS. No E2E. No per-company keys.
Google Voice: TLS in transit. Google can read everything.
Vonage: TLS + SRTP. No E2E for internal.

WE BEAT EVERY COMPETITOR on internal security.
We MATCH every competitor on external security.
We EXCEED every competitor on storage security (per-company keys).
```

---

## PHONE SYSTEM FEATURES

### 1. Business Phone Numbers

```
TYPES OF NUMBERS:
- Main company line: (203) 555-0100
  → The number on the truck, website, business cards
  → Routes to auto-attendant or ring group

- Direct lines (per employee): (203) 555-0101, 0102, etc.
  → Each person has their own business number
  → Name + role assigned from HR module
  → Optional: share direct number with customers or keep internal-only

- Department lines (optional):
  → (203) 555-0110 = "Scheduling"
  → (203) 555-0111 = "Billing"
  → Each rings a specific person or group

NUMBER SELECTION:
- Search by area code
- Search by pattern (vanity numbers if available)
- Local numbers (same area code as business)
- Toll-free option (800/888/877)
- Port existing numbers from other carriers

LINE ASSIGNMENT (from HR module):
When an employee is added to the system:
→ Owner assigns them a line from available numbers
→ Name + role from HR auto-populates caller ID
→ "Mike Torres — Lead Technician, Powers Electric"
→ When employee is terminated → line is deactivated
→ Number stays with company, can be reassigned
→ All call history for that number remains in CRM
```

### 2. Auto-Attendant (IVR)

```
PROFESSIONAL GREETING:
"Thank you for calling Powers Electric, serving Fairfield County
since 2015. For scheduling, press 1. For billing, press 2.
To reach a team member, press 3. For our business hours and
location, press 4."

CONFIGURATION (CRM → Phone → Auto-Attendant):
┌──────────────────────────────────────────────────────────────────┐
│  📞 Auto-Attendant                                               │
│                                                                  │
│  Greeting:                                                       │
│  ○ AI-generated (Opus writes script + text-to-speech)           │
│  ○ Record your own (record from phone or upload audio file)      │
│  ☑ Text-to-speech (type your greeting, pick a voice)            │
│                                                                  │
│  Voice: [Professional Female ▾]                                  │
│  (Options: Professional Female, Professional Male,               │
│   Friendly Female, Friendly Male, Custom uploaded)               │
│  Preview: [▶ Play]                                              │
│                                                                  │
│  Menu options:                                                   │
│  ┌─────┬───────────────────────┬──────────────────────────────┐ │
│  │ Key │ Label                 │ Action                        │ │
│  ├─────┼───────────────────────┼──────────────────────────────┤ │
│  │  1  │ Scheduling            │ Ring: Sarah Johnson           │ │
│  │  2  │ Billing               │ Ring: Sarah Johnson           │ │
│  │  3  │ Company directory     │ Spell-by-name directory       │ │
│  │  4  │ Hours & location      │ Play recorded info            │ │
│  │  0  │ Operator              │ Ring: Office ring group       │ │
│  └─────┴───────────────────────┴──────────────────────────────┘ │
│                                                                  │
│  If no answer after [30 seconds ▾]: → Voicemail                 │
│                                                                  │
│  After hours:                                                    │
│  → Play after-hours greeting → Voicemail                         │
│  ☑ Emergency option (press 1) → ring on-call tech              │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 3. Ring Groups

```
CONCEPT: Multiple phones ring at once. First to answer gets it.

"Office" ring group → Sarah + Robert ring simultaneously
"Emergency" ring group → Mike (lead tech) + Robert
"All techs" ring group → every tech's phone rings

RING STRATEGIES:
- Simultaneous: all phones ring at once (first answer wins)
- Sequential: ring one by one in order (escalation)
- Round-robin: rotate who rings first (load balance)
```

### 4. Voicemail + AI Transcription

```
1. Caller hears voicemail greeting (per-employee or per-company)
2. Caller leaves message → Telnyx records
3. Recording encrypted with company key → Supabase Storage
4. Opus transcribes (speech-to-text)
5. Notification to employee:
   - Push: "New voicemail from (203) 555-1234"
   - SMS (optional): transcript
   - Email (optional): audio + transcript

IN THE APP:
┌──────────────────────────────────────────────────────┐
│  📬 Voicemail                                        │
│                                                      │
│  🔴 NEW — John Smith — (203) 555-1234               │
│  2 min ago │ 0:34                                    │
│  "Hi, this is John. I was calling about getting      │
│  an estimate for a panel upgrade at my house on       │
│  Oak Street. Can you call me back? Thanks."           │
│  [▶ Play]  [📞 Call Back]  [💬 Text Back]            │
│  [→ Create Lead]  [→ Link to Customer]               │
│                                                      │
└──────────────────────────────────────────────────────┘

CRM INTEGRATION:
- Known caller → voicemail linked to their customer record
- Unknown → option to create new lead from voicemail
- Opus extracts intent: "Wants panel upgrade estimate at Oak Street"
```

### 5. SMS / Text Messaging

```
EVERY BUSINESS NUMBER CAN SEND/RECEIVE TEXTS.

USE CASES:
- "On my way, ETA 15 minutes" → from business number
- "Your appointment is tomorrow at 9am" → automated reminder
- Customer texts "Running late" → appears in ZAFTO, not personal Messages
- "Invoice #4201 is ready" → with payment link

IN THE APP: Full conversation view (like iMessage but for business)
- Quick replies: [On my way] [Running late] [Job complete]
- All texts logged in CRM under customer/job record

AUTOMATED TEXTS (configurable):
- Appointment reminders (24hr + 1hr before)
- "Tech is on the way" (auto-triggered from dispatch)
- "Job complete" summary
- Invoice sent notification
- Review request (after job closed)
- Payment confirmation
```

### 6. Call Recording + AI Summaries

```
TOGGLE: Per-company (some states require consent)

OPTIONS:
- OFF: No recording
- ALL: Record every external call (with consent announcement)
- ON-DEMAND: Tech taps button during call to start
- INBOUND ONLY: Record incoming calls

LEGAL COMPLIANCE:
- ZAFTO detects company's state from profile
- Two-party consent states: auto-plays "This call may be recorded"
- One-party states: no announcement required
- Configurable per-state if company operates in multiple states

RECORDINGS:
- Encrypted with company key (AES-256-GCM) before storage
- Signed URLs with 1-hour expiry
- Auto-delete after retention period (default 90 days, configurable)
- Access logged in audit_log

AI CALL SUMMARY (Premium):
- Opus listens to recording after call ends
- Summary: "Customer called about flickering lights. Scheduled Thursday 2/6 9am.
  Also wants estimate for hot tub circuit."
- Summary attached to call log in CRM
- Owner sees every call's purpose without listening
```

### 7. Business Hours + Smart Routing

```
BUSINESS HOURS: Monday-Friday 7am-5pm (configurable per day + holidays)

DURING HOURS:
  Main line → Auto-attendant → route to selection
  Direct lines → Ring that person → if no answer → voicemail

AFTER HOURS:
  Main line → After-hours greeting → Voicemail
  ☑ Emergency option → rings on-call tech
  Direct lines → Voicemail (with after-hours note)

ON-CALL ROTATION:
  This week: Mike Torres
  Next week: Jake Williams
  Configurable schedule, auto-rotates

SMART ROUTING:
  Known customer with active job → route to their assigned tech
  Known customer with open invoice → route to billing/office
  Unknown number → standard auto-attendant
```

### 8. Call Transfer, Hold & Conference

```
DURING AN ACTIVE CALL:

[🔇 Mute]  [🔊 Speaker]  [⏸️ Hold]
[↗️ Transfer]  [👥 Conference]  [⏺️ Record]
[🔴 End Call]

TRANSFER:
- Blind transfer: send directly to another person
- Warm transfer: hold → talk to recipient → connect
- Transfer to voicemail: send to someone's voicemail box

HOLD: Professional hold music/message (configurable)

CONFERENCE: Add up to 5 participants (tech + customer + supplier)
```

### 9. Company Directory

```
INTERNAL DIRECTORY (from auto-attendant):
"Spell the last name..." → T-O-R → "Mike Torres. Press 1 to connect."

IN-APP DIRECTORY (with presence):
🟢 Robert Smith (Owner)           → Available
🟢 Sarah Johnson (Office Manager) → Available
🟡 Mike Torres (Lead Technician)  → On a call
🔴 Jake Williams (Technician)     → Do Not Disturb
⚪ Tyler Chen (Apprentice)         → Offline

Names + roles pulled from HR module.
Status auto-detected (on call, in job, DND, offline).
```

### 10. CRM-Integrated Caller ID

```
INBOUND CALL FROM KNOWN CUSTOMER:
Phone shows: "John Smith" | Customer since 2023
             "Active Job: #4201 Panel Upgrade"
             "Last contact: 2 days ago"

You know WHO and WHY before you answer.

INBOUND CALL FROM UNKNOWN:
Phone shows: "(203) 555-1234" | Unknown
After call: "Save as customer?" → one tap → CRM record created

OUTBOUND CALLER ID:
- Default: company main number
- Option: employee's direct line
- NEVER shows personal cell number
```

### 11. AI Receptionist (Premium Add-On)

```
CONCEPT: AI answers the phone when nobody can.
NOT a chatbot. An actual AI VOICE.

Customer calls → nobody answers after 30 seconds →

AI: "Hi, thanks for calling Powers Electric! I'm the virtual
assistant. How can I help you today?"

Customer: "I need an estimate for some electrical work."

AI: "I'd be happy to help set that up! Can I get your name?"
[... natural conversation continues ...]

→ Lead created in CRM: name, phone, what they need
→ Notification to Owner/Office
→ Recording + transcript available

USES SAME KNOWLEDGE AS WEBSITE AI CHAT:
- Company info, services, hours, service areas
- Same contractor-controlled toggles (prices on/off, etc.)
- Same custom rules from website_chat_config

TECHNOLOGY:
- Speech-to-text (Telnyx/Deepgram) → text to Claude → text-to-speech
- Low latency: <1 second response time
- Natural conversation flow

CONFIGURATION:
- Toggle: ON/OFF
- When: After X rings, after hours only, or always
- Same knowledge/behavior settings as website AI chat
```

---

## PHONE SYSTEM IN THE CRM

### Phone Tab Layout

```
CRM → PHONE TAB

┌──────────────────────────────────────────────────────────────────────────┐
│  📞 Calls                                                         │
│                                                                         │
│  ┌───────┬─────────┬──────────┬─────────┬──────────┬─────────────────┐ │
│  │ Calls │Messages │Voicemail │Directory│Analytics │   Settings      │ │
│  └───────┴─────────┴──────────┴─────────┴──────────┴─────────────────┘ │
│                                                                         │
│  Quick Stats:                                                           │
│  Calls today: 23  │  Missed: 2  │  Avg duration: 3:12                 │
│  Texts today: 47  │  Voicemails: 3 (2 new)                            │
│                                                                         │
└──────────────────────────────────────────────────────────────────────────┘

SUB-TABS:
CALLS      → Call log, recordings, AI summaries, missed call follow-up
MESSAGES   → SMS threads, automated templates, quick replies
VOICEMAIL  → Transcriptions, listen/callback/create lead
DIRECTORY  → Team list with presence, internal calling
ANALYTICS  → Call volume, peak hours, missed rate, avg response time
SETTINGS   → Numbers, auto-attendant, routing, hours, recording, AI receptionist
```

### Call Log View

```
┌──────────────────────────────────────────────────────────────────────┐
│  📞 Recent Calls                                [Filter ▾] [Search] │
│                                                                      │
│  ↙️ John Smith           (203) 555-1234    2:14 PM   3:42   📞→💰  │
│     Panel upgrade inquiry — Job #4201 created                        │
│     [▶ Play]  [📄 AI Summary]                                      │
│                                                                      │
│  ↗️ Home Depot Supply    (800) 555-0199    1:30 PM   1:15           │
│     Ordered 200A panel for Smith job                                 │
│                                                                      │
│  ↙️ ❌ Missed Call       (203) 555-5678    12:45 PM                 │
│     Unknown — no voicemail left                                      │
│     [📞 Call Back]  [💬 Text]  [→ Create Lead]                      │
│                                                                      │
│  ↔️ Mike Torres (internal)                  10:05 AM   0:42          │
│     (E2E encrypted — no recording available)                         │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

ICONS: ↙️ Inbound  ↗️ Outbound  ↔️ Internal  ❌ Missed  📞→💰 Converted
```

---

## NUMBER PORTING

### Bring Your Existing Number

```
Many contractors already have a business number.
They KEEP it and bring it to ZAFTO.

PORTING FLOW:
1. Contractor enters existing number
2. ZAFTO submits port request to Telnyx
3. Telnyx coordinates with current carrier
4. Port completes in 1-2 weeks
5. Number now rings through ZAFTO app
6. Zero downtime — current carrier works until port completes

During porting: temporary ZAFTO number assigned immediately.
When port completes: seamless switchover.

PORT-OUT (If They Leave):
Same as domain — they own the number.
We port it out to their chosen carrier.
No hostage situations. Ethical.
```

---

## PRICING

### Cost to ZAFTO (Telnyx Rates)

```
Phone number:      $1.00/month per number
Outbound calls:    $0.004/min (US)
Inbound calls:     $0.004/min (US)
Outbound SMS:      $0.004/message
Inbound SMS:       $0.004/message
Call recording:     $0.002/min
Transcription:     Use Opus (included in our Claude API costs)
```

### What We Charge

```
RECOMMENDED: PER-LINE PRICING
──────────────────────────────
$4.99/line/month
Includes:
- Dedicated business phone number
- Unlimited internal calls (VoIP, E2E encrypted)
- 500 external minutes/month
- 500 texts/month
- Voicemail with AI transcription
- CRM integration
- Call logging + metadata

Overage: $0.03/min, $0.02/text

EXAMPLE: 5-person company
5 × $4.99 = $24.95/month
vs. 5 company phones = $250-400/month
SAVINGS: ~$225-375/month (90%+)

PREMIUM ADD-ONS:
- AI Receptionist: +$9.99/month (90% margin)
- Call Recording + AI Summaries: +$4.99/month (80% margin)
- Toll-free number: +$2.99/month
- Additional lines beyond plan: $4.99/each

ALTERNATIVE: Bundle into subscription tiers
- ZAFTO Pro: includes 3 lines
- ZAFTO Business: includes 10 lines
- Additional: $4.99/each
```

### Margin Analysis

```
5-person company, moderate usage (2000 min/month external):

Revenue: 5 × $4.99 = $24.95/month
Costs: 5 numbers ($5) + 2000 min ($8) + 500 texts ($2) = $15
Margin: ~$10/month (40%)

With premium add-ons:
+ AI Receptionist ($9.99) + Recording ($4.99) = +$14.98
Add-on costs: ~$2/month
Add-on margin: ~$13/month (87%)

Total with add-ons: $39.93/month revenue, ~$22 margin (55%)

AT SCALE (1000 companies):
Telnyx volume discounts: 30-50% reduction
Margin improves to 60-70%
```

---

## RBAC: PHONE SYSTEM PERMISSIONS

```
ACTION                              OWNER    ADMIN    OFFICE    TECH
──────────────────────────────      ─────    ─────    ──────    ────
Make/receive calls on own line        ✅       ✅       ✅        ✅
Send/receive texts on own line        ✅       ✅       ✅        ✅
View own call history                 ✅       ✅       ✅        ✅
View own voicemails                   ✅       ✅       ✅        ✅
View ALL call history                 ✅       ✅       ✅        ❌
Listen to ANY recording               ✅       ✅       ❌        ❌
Configure auto-attendant              ✅       ✅       ❌        ❌
Manage phone numbers/lines            ✅       ❌       ❌        ❌
Configure routing/hours               ✅       ✅       ❌        ❌
Enable/disable call recording         ✅       ❌       ❌        ❌
Configure AI receptionist             ✅       ✅       ❌        ❌
View phone analytics                  ✅       ✅       ✅        ❌
Add/remove lines                      ✅       ❌       ❌        ❌
Port numbers in/out                   ✅       ❌       ❌        ❌
Set on-call rotation                  ✅       ✅       ❌        ❌
Assign names/roles to lines           ✅       ✅       ❌        ❌
Transfer calls to other employees     ✅       ✅       ✅        ✅
Set own DND status                    ✅       ✅       ✅        ✅
```

---

## DATABASE SCHEMA

```sql
-- Phone system configuration
CREATE TABLE phone_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) UNIQUE,
  business_hours JSONB NOT NULL DEFAULT '{
    "monday": {"open": "07:00", "close": "17:00"},
    "tuesday": {"open": "07:00", "close": "17:00"},
    "wednesday": {"open": "07:00", "close": "17:00"},
    "thursday": {"open": "07:00", "close": "17:00"},
    "friday": {"open": "07:00", "close": "17:00"},
    "saturday": null, "sunday": null
  }',
  holidays JSONB DEFAULT '[]',
  auto_attendant_enabled BOOLEAN DEFAULT true,
  greeting_type TEXT DEFAULT 'tts',  -- 'tts', 'recorded', 'ai_generated'
  greeting_text TEXT,
  greeting_audio_path TEXT,
  greeting_voice TEXT DEFAULT 'professional_female',
  after_hours_greeting_text TEXT,
  after_hours_greeting_audio_path TEXT,
  menu_options JSONB DEFAULT '[]',   -- [{key, label, action, target_user_id/ring_group_id}]
  emergency_enabled BOOLEAN DEFAULT false,
  emergency_ring_group_id UUID,
  call_recording_mode TEXT DEFAULT 'off',  -- off, all, on_demand, inbound_only
  recording_consent_state TEXT,             -- for auto-detecting two-party consent
  recording_retention_days INTEGER DEFAULT 90,
  ai_receptionist_enabled BOOLEAN DEFAULT false,
  ai_receptionist_config_id UUID,          -- links to website_chat_config for shared knowledge
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Phone lines (numbers assigned to people)
CREATE TABLE phone_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  user_id UUID REFERENCES users(id),           -- null = unassigned
  phone_number TEXT NOT NULL UNIQUE,            -- E.164 format: +12035550101
  telnyx_connection_id TEXT,                    -- Telnyx SIP connection
  line_type TEXT DEFAULT 'direct',             -- main, direct, department
  display_name TEXT,                            -- "Mike Torres"
  display_role TEXT,                            -- "Lead Technician"
  caller_id_name TEXT,                          -- "Powers Electric"
  is_active BOOLEAN DEFAULT true,
  voicemail_enabled BOOLEAN DEFAULT true,
  voicemail_greeting_path TEXT,
  dnd_enabled BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'offline',               -- online, busy, dnd, offline
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Ring groups
CREATE TABLE phone_ring_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  strategy TEXT DEFAULT 'simultaneous',        -- simultaneous, sequential, round_robin
  ring_duration_seconds INTEGER DEFAULT 30,
  no_answer_action TEXT DEFAULT 'voicemail',    -- voicemail, next_group, specific_user
  no_answer_target UUID,
  member_user_ids UUID[] NOT NULL,
  last_round_robin_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- On-call rotation
CREATE TABLE phone_on_call_schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  user_id UUID NOT NULL REFERENCES users(id),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Call log
CREATE TABLE phone_calls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  telnyx_call_id TEXT,
  direction TEXT NOT NULL,                      -- inbound, outbound, internal
  from_number TEXT NOT NULL,
  to_number TEXT NOT NULL,
  from_user_id UUID REFERENCES users(id),
  to_user_id UUID REFERENCES users(id),
  customer_id UUID REFERENCES customers(id),    -- if matched to CRM
  job_id UUID REFERENCES jobs(id),              -- if linked to active job
  status TEXT NOT NULL,                         -- completed, missed, voicemail, failed
  duration_seconds INTEGER DEFAULT 0,
  recording_path TEXT,                          -- encrypted in Supabase Storage
  recording_encryption_iv BYTEA,               -- IV for AES-256-GCM decryption
  ai_summary TEXT,                              -- Opus-generated call summary
  ai_transcript TEXT,                           -- full transcript (encrypted at rest)
  started_at TIMESTAMPTZ NOT NULL,
  answered_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Voicemails
CREATE TABLE phone_voicemails (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  call_id UUID NOT NULL REFERENCES phone_calls(id),
  line_id UUID NOT NULL REFERENCES phone_lines(id),
  from_number TEXT NOT NULL,
  customer_id UUID REFERENCES customers(id),
  audio_path TEXT NOT NULL,                     -- encrypted in Supabase Storage
  audio_encryption_iv BYTEA,
  transcript TEXT,                              -- AI transcription
  ai_intent TEXT,                               -- "Wants panel upgrade estimate"
  duration_seconds INTEGER,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Text messages
CREATE TABLE phone_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  telnyx_message_id TEXT,
  direction TEXT NOT NULL,                      -- inbound, outbound
  from_number TEXT NOT NULL,
  to_number TEXT NOT NULL,
  from_user_id UUID REFERENCES users(id),
  customer_id UUID REFERENCES customers(id),
  job_id UUID REFERENCES jobs(id),
  body TEXT NOT NULL,                           -- message content
  media_urls TEXT[],                            -- MMS attachments
  is_automated BOOLEAN DEFAULT false,
  automation_type TEXT,                         -- reminder, eta, review_request, etc.
  status TEXT DEFAULT 'sent',                   -- sent, delivered, failed
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Automated message templates
CREATE TABLE phone_message_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,                           -- "Appointment Reminder"
  trigger_event TEXT,                           -- 'appointment_24hr', 'tech_dispatched', etc.
  body_template TEXT NOT NULL,                  -- "Hi {customer_name}, reminder: {tech_name}..."
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: All tables filtered by company_id
-- phone_lines, phone_calls, phone_messages: tech can see own, admin/owner see all
-- phone_config: owner/admin only
-- phone_voicemails: user can see own line's voicemails
```

---

## SUPABASE EDGE FUNCTIONS

```
PHONE SYSTEM EDGE FUNCTIONS:

| Function                   | Trigger    | Purpose                                    |
|----------------------------|------------|---------------------------------------------|
| phoneIncomingCall          | Webhook    | Telnyx incoming call → routing logic        |
| phoneOutboundCall          | HTTP       | Initiate outbound call via Telnyx           |
| phoneCallStatus            | Webhook    | Call answered/ended/failed → update log     |
| phoneRecordingComplete     | Webhook    | Recording ready → encrypt + store + transcribe |
| phoneVoicemailReceived     | Webhook    | Voicemail → encrypt + store + transcribe    |
| phoneSMSIncoming           | Webhook    | Inbound text → route to assigned user       |
| phoneSMSSend               | HTTP       | Send text from business number              |
| phoneAutoReminder          | Scheduled  | Send appointment reminders                  |
| phoneAIReceptionist        | Webhook    | AI answers call → STT → Claude → TTS       |
| phoneProvisionNumber       | HTTP       | Purchase number from Telnyx                 |
| phonePortNumber            | HTTP       | Initiate number port request                |
| phoneConfigureRouting      | HTTP       | Update auto-attendant/routing rules         |
| phoneTranscribeCall        | Background | Opus transcribes recording → AI summary     |
```

---

## IMPLEMENTATION CHECKLIST

```
CORE INFRASTRUCTURE:
- [ ] Telnyx account + API integration
- [ ] Carrier abstraction layer (Edge Functions wrap Telnyx API)
- [ ] Phone number provisioning flow
- [ ] Number porting system
- [ ] phone_config table + RLS
- [ ] phone_lines table + RLS

iOS / ANDROID INTEGRATION:
- [ ] telnyx_flutter SDK integration
- [ ] iOS CallKit implementation (incoming + outgoing)
- [ ] Android ConnectionService implementation
- [ ] VoIP push notifications (APNs + FCM)
- [ ] Dual-line experience (business vs personal)
- [ ] Background call handling (app killed/backgrounded)
- [ ] CarPlay / Android Auto / Bluetooth integration

CALL FEATURES:
- [ ] Outbound calling (app → Telnyx → PSTN)
- [ ] Inbound calling (PSTN → Telnyx → webhook → VoIP push → app)
- [ ] Internal calling (app ↔ app via WebRTC, E2E encrypted)
- [ ] Call transfer (blind + warm)
- [ ] Call hold with music/message
- [ ] Conference calling (up to 5)
- [ ] Mute / speaker toggle
- [ ] phone_calls table + RLS

AUTO-ATTENDANT:
- [ ] IVR menu system (DTMF input handling)
- [ ] Text-to-speech greeting generation
- [ ] Custom audio upload for greetings
- [ ] AI-generated greeting scripts (Opus)
- [ ] Company directory (spell-by-name)
- [ ] Business hours routing logic
- [ ] After-hours routing + emergency bypass

RING GROUPS + ROUTING:
- [ ] Ring group configuration UI
- [ ] Simultaneous / sequential / round-robin strategies
- [ ] On-call rotation schedule
- [ ] Smart routing (known customer → assigned tech)
- [ ] phone_ring_groups table
- [ ] phone_on_call_schedule table

VOICEMAIL:
- [ ] Voicemail recording (Telnyx)
- [ ] AES-256 encryption before storage
- [ ] AI transcription (Opus)
- [ ] AI intent extraction
- [ ] Push notification on new voicemail
- [ ] Voicemail inbox UI (play, callback, create lead)
- [ ] phone_voicemails table + RLS

SMS / TEXT:
- [ ] Send/receive SMS via Telnyx
- [ ] Conversation thread UI
- [ ] Quick reply buttons
- [ ] Automated message templates
- [ ] Appointment reminders (24hr + 1hr)
- [ ] "Tech on the way" auto-text from dispatch
- [ ] Review request after job closed
- [ ] phone_messages + phone_message_templates tables + RLS

CALL RECORDING:
- [ ] Per-company recording toggle
- [ ] State-based consent detection
- [ ] Consent announcement auto-play
- [ ] AES-256 encryption before storage
- [ ] Signed URL playback (1-hour expiry)
- [ ] Auto-delete after retention period
- [ ] Audit logging on recording access

AI FEATURES:
- [ ] AI voicemail transcription
- [ ] AI call summary generation
- [ ] AI receptionist (STT → Claude → TTS)
- [ ] AI receptionist lead capture flow
- [ ] Shared knowledge config with website AI chat

CRM INTEGRATION:
- [ ] Caller ID lookup against CRM contacts
- [ ] Call log linked to customer/job records
- [ ] "Create lead" from missed call / voicemail
- [ ] SMS threads linked to customer records
- [ ] Phone tab in CRM (calls, messages, voicemail, directory, analytics, settings)

ENCRYPTION:
- [ ] Internal calls: WebRTC DTLS-SRTP (E2E, automatic)
- [ ] Internal messages: Signal Protocol double ratchet
- [ ] External calls: TLS + SRTP (encrypted in transit)
- [ ] Recordings: AES-256-GCM with company key before storage
- [ ] Voicemails: AES-256-GCM with company key before storage
- [ ] Transcripts: encrypted at rest in PostgreSQL
- [ ] SMS history: encrypted at rest
- [ ] Key management via Layer 4B envelope encryption

ANALYTICS:
- [ ] Call volume (daily/weekly/monthly)
- [ ] Peak hours heatmap
- [ ] Missed call rate
- [ ] Average response time
- [ ] Average call duration
- [ ] Calls per employee
- [ ] Texts per employee
- [ ] AI receptionist conversion rate
- [ ] Revenue attribution (call → lead → job → invoice)
```

---

## COMPETITIVE POSITIONING

```
FEATURE                          ZAFTO     RINGCENTRAL   GRASSHOPPER   GOOGLE VOICE
──────────────────────────      ─────     ───────────   ───────────   ────────────
Price per line                  $4.99     $20-35        $14-80        $10-30
E2E encrypted internal calls    ✅         ❌             ❌             ❌
Per-company encryption keys     ✅         ❌             ❌             ❌
CRM integration (built-in)      ✅         ❌ (plugin)    ❌             ❌
Caller ID from CRM data         ✅         ❌             ❌             ❌
AI voicemail transcription      ✅         ✅             ✅             ✅
AI call summaries               ✅         ❌             ❌             ❌
AI receptionist                 ✅         ❌             ❌             ❌
Auto-attendant                  ✅         ✅             ✅             ❌
SMS + automated texts           ✅         ✅             ✅             ✅
Call recording + compliance     ✅         ✅             ✅             ❌
Number porting                  ✅         ✅             ✅             ✅
Revenue attribution             ✅         ❌             ❌             ❌
On-call rotation                ✅         ✅             ❌             ❌
Data export / full backup       ✅         ❌             ❌             ❌

THE KILLER: CRM + Phone as ONE system.
"This call from the yard sign QR code became a $4,200 panel upgrade."
Nobody else connects phone → lead → job → revenue.
```

---

**END OF PHONE SYSTEM SPEC — FEBRUARY 5, 2026 (Session 30)**
**Provider: Telnyx (carrier abstraction layer allows swap to Twilio/Bandwidth)**
**Encryption: E2E internal, encrypted transit external, AES-256 storage (Layer 4B)**
**SEE ALSO: 30_SECURITY_ARCHITECTURE.md (Layer 4B: Encryption, Layer 4C: Data Export)**
**SEE ALSO: 28_WEBSITE_BUILDER_V2.md (AI Chat shares knowledge config with AI Receptionist)**
