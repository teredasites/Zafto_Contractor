# ZAFTO Z CONSOLE — Persistent AI Interface + Artifact System
## Created: February 5, 2026 (Session 33)
## Status: DRAFT — To be reviewed and consolidated
## Cross-References: Doc 35 (Universal AI Architecture), Doc 40 (Dashboard)

---

## PURPOSE

Z is not a chat widget. Z is not a sidebar. Z is not a page. Z is a persistent
intelligent layer that travels with the user across every screen, maintains state
across navigation, and produces professional artifacts that the contractor must
review and approve before anything leaves the platform.

No AI interface like this exists today. Every current approach — chat bubbles,
sidebars, full-page takeovers — forces a context switch. The user either leaves
what they're doing to talk to AI, or the AI is so small it can't show meaningful
output. The Dashboard solves both problems simultaneously.

**Design philosophy: Stripe-level restraint. Apple-level polish. Nothing else like it.**

---

## THE Z CONSOLE — THREE STATES

The console is a single persistent UI component that lives outside the page routing
layer. It never unmounts. It never re-renders on navigation. It never loses state.
Pages swap underneath it. Z rides on top.

### State 1: The Pulse (Minimized)

The Offset Echo Z mark, 40x40px, floating bottom-right. Not a chat bubble. A presence.

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                   [ Page Content ]                   │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                              [Z]    │  ← 40x40, soft glow
└─────────────────────────────────────────────────────┘
```

**Visual treatment:**
- Offset Echo Z mark in brand color
- Subtle ambient glow pulse — barely perceptible, 4-second cycle
- Glow brightens when Z has a proactive insight to surface
- On insight: single-line preview slides left from the mark, frosted glass pill:

```
                              ┌──────────────────────────────────┐
                              │ 3 bids aging past 7 days         │ [Z]
                              └──────────────────────────────────┘
```

- Preview auto-dismisses after 8 seconds if not tapped
- No red badges. No notification counts. No urgency theater.
- Tap the Z mark → expands to State 2
- Tap the preview pill → expands to State 2 with that topic loaded

**Rules for proactive surfacing (priority-ranked, one at a time):**
1. New inbound lead (from unified inbox)
2. Safety-critical alert (schedule conflict, overdue inspection)
3. Aging bid threshold crossed (7 days)
4. Overdue invoice threshold crossed (14 days)
5. Z-generated showcase ready for review
6. Review request ready to send
7. Performance insight (weekly summary, trend alert)

Z never stacks notifications. One thing at a time. Most important first.
If ignored, it fades and resurfaces on the dashboard during next visit.

---

### State 2: The Console Bar (Conversational)

Tap the pulse → bar rises from bottom, 18-22% of viewport height.
Frosted glass. Translucent. Page content visible and interactive above.

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                   [ Page Content ]                   │
│              (fully interactive, scrollable)         │
│                                                     │
│                                                     │
│                                                     │
├─────────────────────────────────────────────────────┤
│ ░░░░░░░░░░░░░ Z CONSOLE (frosted glass) ░░░░░░░░░░ │
│                                                     │
│  Z: "The Oak Street panel upgrade bid has been      │
│      sitting for 5 days. Want me to draft a         │
│      follow-up?"                                    │
│                                                     │
│  [Draft follow-up]  [Check code]  [Message customer]│
│                                                     │
│  ┌─────────────────────────────────────┐  [🎤] [↑] │
│  │ Type a message...                   │            │
│  └─────────────────────────────────────┘            │
│                                                     │
│  ── ── ── (drag handle — swipe up for full) ── ── ──│
└─────────────────────────────────────────────────────┘
```

**Visual treatment:**
- Background: `backdrop-filter: blur(20px) saturate(180%)` + rgba overlay
  - Dark mode: `rgba(15, 15, 20, 0.85)`
  - Light mode: `rgba(245, 245, 250, 0.88)`
- 1px top border: subtle separator, brand accent at 15% opacity
- Border radius: 20px top-left, 20px top-right (sheet-style)
- Shadow: `0 -4px 30px rgba(0,0,0,0.12)` — soft upward cast
- Transition in: 280ms cubic-bezier(0.32, 0.72, 0, 1) — fast start, smooth land
- Transition out: 220ms ease-in — quick retract

**Content:**
- Last 2-3 conversation messages visible (scrollable within bar)
- Contextual quick-action chips change per screen (Layer 4 driven):

  | Current Screen | Quick Actions |
  |---------------|---------------|
  | Dashboard | `[Revenue summary]` `[Chase overdue]` `[Today's schedule]` |
  | Job Detail | `[Draft bid]` `[Check code]` `[Scope this job]` |
  | Invoice List | `[Aging report]` `[Send reminders]` `[Export]` |
  | Customer Detail | `[Service history]` `[Schedule follow-up]` `[Equipment check]` |
  | Bid Creation | `[Price guidance]` `[Material list]` `[Competitor range]` |
  | Inbox | `[Draft replies]` `[Qualify leads]` `[Response stats]` |
  | Schedule | `[Optimize route]` `[Open slots]` `[Conflicts]` |

- Text input with mic button (voice input)
- Expand arrow (↑) or swipe-up gesture → State 3
- Tap outside console or swipe down → State 1

**Interaction model:**
- Page behind remains fully interactive (scroll, tap, navigate)
- If user navigates to a different screen, chips update silently
- Conversation persists — navigating doesn't clear the thread
- Z acknowledges context shifts naturally in conversation:
  "I see you opened the Torres EV charger job. Want to continue with
  the invoice follow-ups, or pivot to this?"

---

### State 3: The Full Console (Deep Work)

Swipe up on the bar → console slides up to 65-70% of viewport.
Underlying page visible in top 30-35%, slightly blurred.

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│          [ Page Content — blurred 30% ]             │
│              (tap to collapse console)              │
│                                                     │
├─────────────────────────────────────────────────────┤
│ ░░░░░░░░░░ Z CONSOLE — FULL (frosted glass) ░░░░░░ │
│  ── ── ── (drag handle — swipe down to shrink) ── ──│
│                                                     │
│  Z: "Here's the bid for the Torres EV charger       │
│      installation. I used your company template      │
│      and priced it based on your recent EV jobs."    │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │                                               │  │
│  │           [ ARTIFACT WINDOW ]                 │  │
│  │                                               │  │
│  │   (Bid document, invoice preview, scope       │  │
│  │    sheet, follow-up email, code reference,    │  │
│  │    photo analysis — rendered inline)          │  │
│  │                                               │  │
│  │                                               │  │
│  │                                               │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  [✏️ Edit]  [✅ Approve & Send]  [❌ Reject]        │
│                                                     │
│  ┌─────────────────────────────────────┐  [🎤] [↓] │
│  │ Type a message...                   │            │
│  └─────────────────────────────────────┘            │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Visual treatment:**
- Same frosted glass as State 2, deeper blur on underlying page
- Page content behind: `filter: blur(6px) brightness(0.7)`
- Tap the blurred page area → collapses back to State 2
- Drag handle at top for continuous resize (snap points at 50%, 65%, 85%)
- Max height: 85% viewport (always shows some page context)
- Artifact window has its own scroll, separate from conversation scroll

**This is where artifacts live — see ARTIFACT SYSTEM section below.**

---

### State Transitions

```
                    tap Z mark
    [PULSE] ──────────────────────→ [CONSOLE BAR]
       ↑                                  │  ↑
       │          swipe down /            │  │
       │          tap outside             │  │  swipe down /
       └──────────────────────────────────┘  │  drag handle
                                             │
                    swipe up /               │
                    expand button            │
                         ↓                   │
                   [FULL CONSOLE] ───────────┘
```

All transitions: 220-280ms, cubic-bezier(0.32, 0.72, 0, 1)
No jarring cuts. No modals. No overlays. Fluid mechanical motion.

---

## THE ARTIFACT SYSTEM

### What Artifacts Are

Artifacts are structured, templated documents that Z generates inside the console.
They are NOT free-form AI text. They are professional business documents rendered
from strict templates that Z fills with contextual data.

Artifacts are the bridge between "Z said something useful" and "the contractor
took action." Every artifact that leaves the platform — a bid, an invoice, a
follow-up email, a review request — goes through the artifact system.

### Artifact Types

| Type | Template Required | Approval Required | Leaves Platform |
|------|:-----------------:|:-----------------:|:---------------:|
| Bid / Estimate | ✅ | ✅ MANDATORY | ✅ (to customer) |
| Invoice | ✅ | ✅ MANDATORY | ✅ (to customer) |
| Follow-up Message | ✅ | ✅ MANDATORY | ✅ (to customer) |
| Change Order | ✅ | ✅ MANDATORY | ✅ (to customer) |
| Scope of Work | ✅ | ✅ MANDATORY | ✅ (to customer) |
| Review Request | ✅ | ✅ MANDATORY | ✅ (to customer) |
| Project Showcase | ✅ | ✅ MANDATORY | ✅ (to social/profile) |
| Auto-Response Draft | ✅ | ⚠️ (if auto-send enabled) | ✅ (to lead) |
| Code Reference | ❌ (rendered inline) | ❌ | ❌ (internal) |
| Calculation Breakdown | ❌ (rendered inline) | ❌ | ❌ (internal) |
| Job Scope Draft | ✅ | ❌ (internal draft) | ❌ (until attached to bid) |
| Material List | ❌ (rendered inline) | ❌ | ❌ (internal) |
| Business Report | ✅ | ❌ (internal) | ❌ (internal) |
| Photo Analysis | ❌ (rendered inline) | ❌ | ❌ (internal) |

**The rule is absolute: NOTHING generated by Z that touches a customer, lead,
or public platform ships without the contractor reviewing and approving it
in the artifact window.**

---

### Artifact Window Behavior

When Z produces an artifact, it renders inside the console in the artifact window —
a contained, scrollable pane with a distinct visual boundary from the conversation.

**Rendering:**

```
┌─────────────────────────────────────────────────────┐
│ Z CONSOLE — FULL                                    │
│                                                     │
│  Z: "I've drafted the bid for Torres EV charger     │
│      install. Used your Standard Residential         │
│      template. Review and approve when ready."       │
│                                                     │
│  ┌─ ARTIFACT ──────────────────────────────── ▢ ─┐  │
│  │                                               │  │
│  │  ╔═══════════════════════════════════════════╗ │  │
│  │  ║   BRIGHT WIRE ELECTRICAL LLC              ║ │  │
│  │  ║   ESTIMATE #2026-0234                     ║ │  │
│  │  ║                                           ║ │  │
│  │  ║   Prepared for: Mike Torres               ║ │  │
│  │  ║   Property: 88 Elm Street, Stamford CT    ║ │  │
│  │  ║   Date: February 5, 2026                  ║ │  │
│  │  ║                                           ║ │  │
│  │  ║   SCOPE OF WORK                           ║ │  │
│  │  ║   Level 2 EV Charger Installation         ║ │  │
│  │  ║   - ChargePoint Home Flex (50A, hardwired)║ │  │
│  │  ║   - Dedicated 50A circuit from panel      ║ │  │
│  │  ║   - Up to 30ft conduit run to garage      ║ │  │
│  │  ║   - All permits and inspection            ║ │  │
│  │  ║                                           ║ │  │
│  │  ║   PRICING                                 ║ │  │
│  │  ║   Labor .......................... $850    ║ │  │
│  │  ║   Materials ...................... $680    ║ │  │
│  │  ║   Permit + Inspection ........... $175    ║ │  │
│  │  ║   ─────────────────────────────────────   ║ │  │
│  │  ║   TOTAL ......................... $1,705  ║ │  │
│  │  ║                                           ║ │  │
│  │  ║   Valid for 30 days from date above.      ║ │  │
│  │  ║                                           ║ │  │
│  │  ╚═══════════════════════════════════════════╝ │  │
│  │                                               │  │
│  │  ⚠️ Review required before sending            │  │
│  │                                               │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  [✏️ Edit]  [💬 "Change the price to..."]           │
│  [✅ Approve & Send]  [📋 Save as Draft]  [❌ Discard]│
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Artifact window features:**
- Distinct border treatment: subtle elevated card with 1px border, slight shadow
- Separate scroll from conversation (artifact scrolls independently)
- Expand button (▢) → artifact takes over full console width for detailed review
- Pinch-to-zoom on mobile for fine detail review
- Light/dark mode independent of console theme (documents always light background
  for readability and print-accuracy)

**Conversational editing:**
Instead of form fields and edit buttons, the contractor talks to Z to modify:

```
Contractor: "Change the total to $1,850, I need to add wire cost"
Z: Updates artifact in real-time, highlights what changed
Z: "Updated. Added $145 to materials for additional wire run.
    New total: $1,850. Anything else?"

Contractor: "Add a note that this doesn't include drywall patching"
Z: Adds exclusion line to the scope section
Z: "Added exclusion: 'Drywall patching/repair not included.'
    Ready to approve?"
```

The artifact re-renders live as Z makes changes. No save button. No refresh.
Changes appear in the document as the conversation flows. The contractor sees
exactly what the customer will see, with every edit reflected immediately.

---

### Template System

Z does NOT freestyle business documents. Every outgoing artifact is rendered
from a strict template. Z fills the template with contextual data and can adjust
content within the template's defined sections — but it cannot invent new sections,
remove required sections, or change the document structure.

**Template structure (stored in Supabase):**

```sql
CREATE TABLE artifact_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),  -- NULL = system default
  template_type TEXT NOT NULL,     -- 'bid', 'invoice', 'follow_up', 'scope',
                                   -- 'change_order', 'review_request', 'showcase'
  template_name TEXT NOT NULL,     -- "Standard Residential Estimate"
  trade TEXT,                      -- NULL = universal, or specific trade
  version INTEGER DEFAULT 1,
  is_default BOOLEAN DEFAULT false,
  structure JSONB NOT NULL,        -- Template definition (see below)
  styling JSONB DEFAULT '{}',     -- Company branding overrides
  required_sections TEXT[] NOT NULL, -- Sections that CANNOT be removed
  ai_editable_sections TEXT[],    -- Sections Z is allowed to modify
  requires_approval BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Template structure JSONB example (bid):**

```json
{
  "document_type": "estimate",
  "sections": [
    {
      "id": "header",
      "type": "company_header",
      "required": true,
      "ai_editable": false,
      "fields": ["company_name", "logo", "license_number", "phone", "email", "address"]
    },
    {
      "id": "meta",
      "type": "document_meta",
      "required": true,
      "ai_editable": true,
      "fields": ["estimate_number", "date", "valid_until", "customer_name",
                 "customer_address", "job_address"]
    },
    {
      "id": "scope",
      "type": "rich_text",
      "required": true,
      "ai_editable": true,
      "label": "Scope of Work",
      "min_length": 50,
      "max_length": 2000
    },
    {
      "id": "line_items",
      "type": "line_item_table",
      "required": true,
      "ai_editable": true,
      "columns": ["description", "quantity", "unit_price", "total"],
      "show_subtotal": true,
      "show_tax": true,
      "show_total": true
    },
    {
      "id": "exclusions",
      "type": "bullet_list",
      "required": false,
      "ai_editable": true,
      "label": "Exclusions & Conditions"
    },
    {
      "id": "terms",
      "type": "static_text",
      "required": true,
      "ai_editable": false,
      "label": "Terms & Conditions",
      "content": "{{company.default_terms}}"
    },
    {
      "id": "acceptance",
      "type": "signature_block",
      "required": true,
      "ai_editable": false,
      "fields": ["customer_signature", "date", "printed_name"]
    },
    {
      "id": "footer",
      "type": "company_footer",
      "required": true,
      "ai_editable": false,
      "fields": ["license_number", "insurance_info", "disclaimer"]
    }
  ],
  "disclaimer": "This estimate is provided for informational purposes. Final pricing may vary based on site conditions discovered during work.",
  "ai_instructions": "Fill scope with specific, trade-accurate description of work. Use line items that match the company's typical pricing structure. Include all permits and inspections as separate line items. Add relevant exclusions based on job type."
}
```

**What Z CAN do within a template:**
- Fill in customer/job/company data from the database
- Write scope descriptions using trade knowledge
- Set line items and pricing (guided by Layer 5 compounding data if available)
- Add/remove optional sections (exclusions, notes)
- Adjust language and tone based on company preferences (Layer 3)

**What Z CANNOT do:**
- Remove required sections (header, terms, acceptance, footer, disclaimer)
- Modify static sections (terms & conditions, legal disclaimers)
- Skip the approval step
- Send without the contractor's explicit sign-off
- Change the document structure or add sections not in the template
- Override company branding or formatting

**Company-customizable templates:**

```
Settings → Templates

┌─────────────────────────────────────────────────────┐
│  YOUR TEMPLATES                                     │
│                                                     │
│  Estimates                                          │
│  ├── Standard Residential Estimate ★ (default)      │
│  ├── Commercial Estimate                            │
│  └── Emergency Service Estimate                     │
│                                                     │
│  Invoices                                           │
│  ├── Standard Invoice ★ (default)                   │
│  └── Progress Billing Invoice                       │
│                                                     │
│  Follow-ups                                         │
│  ├── Bid Follow-up (3 day) ★ (default)              │
│  ├── Bid Follow-up (7 day)                          │
│  └── Post-Job Follow-up                             │
│                                                     │
│  [+ Create Template]  [Import from ZAFTO Library]   │
│                                                     │
│  ZAFTO provides default templates for every trade.  │
│  Customize or create your own.                      │
└─────────────────────────────────────────────────────┘
```

The company can customize their templates: add their terms, adjust sections,
set default pricing structures, upload their logo. Z uses whatever template
is set as default for that document type, or the contractor can specify:
"Use the commercial template for this one."

---

### Approval & Sign-Off System (MANDATORY)

This is the compliance layer that protects Tereda Software LLC. Every artifact
that leaves the platform requires explicit contractor action.

**Approval flow:**

```
Z generates artifact
        │
        ▼
┌─────────────────────┐
│ ARTIFACT RENDERED    │
│ in console window    │
│                      │
│ Status: DRAFT        │
│ ⚠️ "Review required  │
│    before sending"   │
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
[✏️ Edit]    [✅ Approve]
     │           │
     │           ▼
     │    ┌──────────────────┐
     │    │ CONFIRMATION     │
     │    │                  │
     │    │ "You're about to │
     │    │  send this bid   │
     │    │  to Mike Torres  │
     │    │  for $1,850.     │
     │    │                  │
     │    │  By approving,   │
     │    │  you confirm     │
     │    │  this document   │
     │    │  is accurate."   │
     │    │                  │
     │    │ [Confirm & Send] │
     │    │ [Go Back]        │
     │    └────────┬─────────┘
     │             │
     │             ▼
     │    ┌──────────────────┐
     │    │ APPROVAL LOGGED  │
     │    │                  │
     │    │ Event recorded:  │
     │    │ - Who approved   │
     │    │ - Exact content  │
     │    │ - Timestamp      │
     │    │ - IP / device    │
     │    │ - Recipient      │
     │    │ - Template used  │
     │    │                  │
     │    │ Status: SENT ✅  │
     │    └──────────────────┘
     │
     ▼
[Continue editing via conversation]
"Change the price to $1,900"
→ Artifact updates live
→ Returns to DRAFT status
→ Requires re-approval
```

**CRITICAL: Any edit after approval resets the artifact to DRAFT status.**
The contractor must re-approve. There is no way to silently modify a sent document.

**Approval confirmation UI:**

The confirmation is not a tiny checkbox. It's a full interaction moment —
a brief overlay within the artifact window:

```
┌───────────────────────────────────────────────┐
│                                               │
│   ✅ Ready to send?                           │
│                                               │
│   Sending: Estimate #2026-0234                │
│   To: Mike Torres (mike@email.com)            │
│   Amount: $1,850.00                           │
│   Via: Email + Home Portal notification        │
│                                               │
│   By confirming, you verify this document     │
│   is accurate and authorized for delivery.    │
│                                               │
│   ┌─────────────────────────────────────────┐ │
│   │         Confirm & Send                  │ │
│   └─────────────────────────────────────────┘ │
│                                               │
│   [← Go Back and Edit]                        │
│                                               │
└───────────────────────────────────────────────┘
```

The confirm button is prominent. The go-back option is clear. No ambiguity.
No accidental sends. No "are you sure?" chains. One clear moment of decision.

---

### Artifact Event Logging (Compliance + Liability)

Every artifact interaction is logged immutably. This protects Tereda, protects
the contractor, and creates an audit trail for disputes.

**Schema:**

```sql
CREATE TABLE artifact_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  artifact_id UUID REFERENCES artifacts(id) NOT NULL,
  company_id UUID REFERENCES companies(id) NOT NULL,
  user_id UUID REFERENCES users(id) NOT NULL,
  employee_id UUID REFERENCES employees(id),
  event_type TEXT NOT NULL,
  event_data JSONB NOT NULL,
  ip_address INET,
  user_agent TEXT,
  device_type TEXT,                -- 'mobile_ios', 'mobile_android', 'web', 'desktop'
  platform TEXT,                   -- 'mobile_app', 'web_crm', 'client_portal'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Immutable: no UPDATE or DELETE allowed on this table
-- RLS: company can read own events, Tereda admin can read all
-- Retention: indefinite (legal compliance)

CREATE INDEX idx_artifact_events_artifact ON artifact_events(artifact_id, created_at);
CREATE INDEX idx_artifact_events_company ON artifact_events(company_id, created_at DESC);
CREATE INDEX idx_artifact_events_type ON artifact_events(event_type, created_at DESC);
```

**Event types logged:**

| Event Type | When | Data Captured |
|-----------|------|---------------|
| `artifact_created` | Z generates the artifact | template_id, template_version, ai_model_used, initial_content_hash |
| `artifact_viewed` | Contractor opens/views artifact in console | view_duration_seconds |
| `artifact_edited_by_ai` | Z modifies artifact via conversation | field_changed, old_value, new_value, user_instruction |
| `artifact_edited_manual` | Contractor directly edits a field | field_changed, old_value, new_value |
| `artifact_approved` | Contractor taps Confirm & Send | full_content_snapshot, recipient, delivery_method, approval_timestamp |
| `artifact_rejected` | Contractor discards | reason (if provided) |
| `artifact_saved_draft` | Contractor saves without sending | content_snapshot |
| `artifact_sent` | System delivers to recipient | delivery_method, recipient_address, delivery_status |
| `artifact_delivered` | Recipient receives/opens | open_timestamp (if trackable) |
| `artifact_revised` | Edit after previous approval | previous_version_id, changes_made |
| `artifact_re_approved` | Re-approval after revision | full_content_snapshot, revision_count |
| `artifact_customer_signed` | Customer signs (if signature required) | signature_data, signer_ip, timestamp |
| `artifact_disputed` | Customer or contractor flags an issue | dispute_type, notes |

**The `artifact_approved` event is the critical legal record:**

```json
{
  "event_type": "artifact_approved",
  "event_data": {
    "artifact_type": "estimate",
    "template_id": "uuid-standard-residential",
    "template_version": 3,
    "content_snapshot": {
      "full_rendered_html": "...",
      "full_rendered_text": "...",
      "content_hash": "sha256:a1b2c3...",
      "line_items": [...],
      "total_amount": 1850.00,
      "scope_text": "Level 2 EV Charger Installation..."
    },
    "recipient": {
      "name": "Mike Torres",
      "email": "mike@email.com",
      "phone": "+1-203-555-0142"
    },
    "delivery_method": ["email", "zafto_home_notification"],
    "approval_confirmation_text": "By confirming, you verify this document is accurate and authorized for delivery.",
    "ai_involvement": {
      "model_used": "claude-sonnet-4-5-20250929",
      "ai_generated_sections": ["scope", "line_items", "exclusions"],
      "ai_edits_made": 2,
      "human_edits_made": 1,
      "final_review_duration_seconds": 45
    }
  },
  "user_id": "uuid-contractor",
  "ip_address": "72.34.56.78",
  "device_type": "mobile_ios",
  "platform": "mobile_app",
  "created_at": "2026-02-05T14:32:18.000Z"
}
```

**What this protects against:**

1. **"I never sent that bid"** → Event log shows exact approval timestamp,
   IP, device, and full content snapshot of what was approved.

2. **"The AI made a mistake in the price"** → Event log shows every AI edit,
   every human edit, and the final human approval with content snapshot.
   The contractor approved the final version — they own it.

3. **"ZAFTO sent that without my permission"** → Event log proves every
   outgoing document required explicit Confirm & Send action. No auto-sends
   on documents that touch customers (except auto-responses if enabled,
   which have their own separate consent flow in settings).

4. **"The bid I received was different from what was approved"** → Content
   hash comparison between approved snapshot and delivered document.
   If they match, no tampering occurred.

5. **"My employee sent an unauthorized bid"** → Event log shows which
   employee approved, their role, and whether they had RBAC permission
   to send bids. Layer 6 can restrict bid approval to Owner/Admin only.

---

### Artifacts Table (Master Record)

```sql
CREATE TABLE artifacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) NOT NULL,
  created_by UUID REFERENCES users(id) NOT NULL,
  approved_by UUID REFERENCES users(id),
  template_id UUID REFERENCES artifact_templates(id),
  template_version INTEGER,

  -- Type and status
  artifact_type TEXT NOT NULL,      -- 'estimate', 'invoice', 'follow_up', etc.
  status TEXT DEFAULT 'draft',      -- 'draft', 'pending_review', 'approved', 'sent',
                                    -- 'delivered', 'signed', 'rejected', 'revised'

  -- Content
  content JSONB NOT NULL,           -- Structured content per template sections
  rendered_html TEXT,               -- Final rendered HTML for delivery
  content_hash TEXT,                -- SHA-256 of rendered content at approval

  -- Relationships
  job_id UUID REFERENCES jobs(id),
  customer_id UUID REFERENCES customers(id),
  bid_id UUID REFERENCES bids(id),
  invoice_id UUID REFERENCES invoices(id),
  lead_id UUID REFERENCES leads(id),
  conversation_id UUID,             -- The Z conversation that produced this

  -- Delivery
  recipient_name TEXT,
  recipient_email TEXT,
  recipient_phone TEXT,
  delivery_method TEXT[],           -- ['email', 'sms', 'zafto_home']
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,

  -- AI metadata
  ai_model_used TEXT,
  ai_generated_sections TEXT[],
  ai_edit_count INTEGER DEFAULT 0,
  human_edit_count INTEGER DEFAULT 0,
  review_duration_seconds INTEGER,

  -- Versioning
  version INTEGER DEFAULT 1,
  previous_version_id UUID REFERENCES artifacts(id),
  revision_count INTEGER DEFAULT 0,

  -- Timestamps
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_artifacts_company_type ON artifacts(company_id, artifact_type, status);
CREATE INDEX idx_artifacts_customer ON artifacts(customer_id, created_at DESC);
CREATE INDEX idx_artifacts_job ON artifacts(job_id);
```

---

## TECHNICAL ARCHITECTURE — PERSISTENCE

### Why It Never Refreshes

The Dashboard is mounted once at the root layout level, outside the routing system.

**Next.js (Web CRM / Client Portal / Ops Portal):**

```tsx
// app/layout.tsx — Root layout, wraps everything
export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <ZConsoleProvider>          {/* State lives here — never unmounts */}
          <SessionContextProvider>  {/* Tracks current page/entities */}
            <main>{children}</main> {/* THIS swaps on navigation */}
          </SessionContextProvider>
          <ZConsole />              {/* THIS never unmounts */}
        </ZConsoleProvider>
      </body>
    </html>
  );
}
```

Page navigations via Next.js router swap the `{children}` content.
`<ZConsole />` is a sibling, not a child. It never re-renders on route change.

**Flutter (Mobile App):**

```dart
// main.dart — Dashboard as persistent overlay above Navigator
class ZaftoApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ZConsoleState()),
        ChangeNotifierProvider(create: (_) => SessionContext()),
      ],
      child: MaterialApp(
        builder: (context, child) {
          return Stack(
            children: [
              child!,              // Navigator stack — routes swap here
              const ZConsole(),    // Persistent overlay — never disposed
            ],
          );
        },
      ),
    );
  }
}
```

The `ZConsole` widget sits in a `Stack` above the `Navigator`. Route pushes
and pops happen underneath. The console's state is held in a root-level
`ChangeNotifierProvider` that outlives all route transitions.

### Connection Persistence

```
App opens
    │
    ▼
ZConsoleProvider initializes
    │
    ├── Opens WebSocket to Supabase Realtime
    │   (or dedicated WebSocket for AI streaming)
    │
    ├── Loads last conversation from local cache (Hive/SharedPreferences)
    │   (user sees their last few messages immediately, no loading state)
    │
    ├── Loads persistent memory profile (Layer 3) from Supabase
    │
    └── Subscribes to real-time events:
        ├── New inbound leads (for pulse notifications)
        ├── Artifact status updates (delivery confirmations)
        └── Z proactive insights (scheduled from edge functions)
```

The WebSocket connection is maintained for the entire app session.
Network interruptions → automatic reconnect with exponential backoff.
Conversation state cached locally → survives app backgrounding on mobile.

---

## HOMEOWNER VERSION — ZAFTO HOME CONSOLE

Same architecture. Same three states. Different personality, different actions,
different artifact types.

### Pulse Behavior (Homeowner)

- Equipment maintenance reminders: "Your AC filter is due for replacement"
- Service updates: "Your electrician completed the panel upgrade today"
- Seasonal tips: "Winter prep — have your furnace inspected before November"
- Appointment reminders: "Plumber arriving tomorrow 9am-11am"

### Console Bar Quick Actions (Homeowner)

| Screen | Quick Actions |
|--------|---------------|
| Equipment page | `[Ask about this]` `[Schedule service]` `[Warranty check]` |
| Service history | `[What was done?]` `[Is this normal?]` `[When's next service?]` |
| Service catalog | `[Get estimate]` `[Compare options]` `[What does this involve?]` |
| Active service request | `[Check status]` `[Message contractor]` `[Reschedule]` |

### Homeowner Artifacts

| Type | Example | Approval Required |
|------|---------|:-----------------:|
| Service Request | "Request estimate for EV charger" | ✅ (confirm before sending to contractor) |
| Appointment Confirmation | Calendar event + details | ❌ (informational) |
| Equipment Report | "Your home equipment summary" | ❌ (informational) |
| Payment | Invoice payment through portal | ✅ (confirm payment amount) |
| Review | Star rating + review text | ✅ (confirm before posting) |

Homeowner artifacts are simpler. No bids, no invoices, no scopes.
The approval system still applies for anything that creates an action
(service request, payment, review).

---

## VISUAL DESIGN SPECIFICATIONS

### Glass Effect

```css
/* Dark mode console background */
.z-console {
  background: rgba(15, 15, 20, 0.85);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 20px 20px 0 0;
  box-shadow: 0 -4px 30px rgba(0, 0, 0, 0.15);
}

/* Light mode console background */
.z-console--light {
  background: rgba(250, 250, 252, 0.88);
  backdrop-filter: blur(20px) saturate(180%);
  border-top: 1px solid rgba(0, 0, 0, 0.06);
  box-shadow: 0 -4px 30px rgba(0, 0, 0, 0.08);
}

/* Underlying page blur when full console is open */
.page-content--blurred {
  filter: blur(6px) brightness(0.7);
  transition: filter 280ms cubic-bezier(0.32, 0.72, 0, 1);
  pointer-events: none;  /* Tap blurred area = collapse console */
}

/* Artifact window within console */
.artifact-window {
  background: #FFFFFF;  /* Always light for document readability */
  border: 1px solid rgba(0, 0, 0, 0.08);
  border-radius: 12px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
  margin: 12px;
  overflow-y: auto;
  max-height: 60%;  /* Of console height, not viewport */
}
```

### Typography

```css
/* Console conversation text */
.z-message {
  font-family: 'Inter', -apple-system, sans-serif;  /* Or ZAFTO brand font */
  font-size: 15px;
  line-height: 1.5;
  color: rgba(255, 255, 255, 0.92);  /* Dark mode */
  letter-spacing: -0.01em;
}

/* Quick action chips */
.z-chip {
  font-size: 13px;
  font-weight: 500;
  padding: 6px 14px;
  border-radius: 100px;
  background: rgba(255, 255, 255, 0.08);
  color: rgba(255, 255, 255, 0.72);
  border: 1px solid rgba(255, 255, 255, 0.06);
  transition: all 180ms ease;
}

.z-chip:hover {
  background: rgba(255, 255, 255, 0.14);
  color: rgba(255, 255, 255, 0.95);
  border-color: rgba(255, 255, 255, 0.12);
}

/* Artifact document text (always light mode) */
.artifact-text {
  font-family: 'Inter', sans-serif;
  font-size: 14px;
  line-height: 1.6;
  color: #1a1a1a;
}
```

### Animation

```css
/* Console state transitions */
.z-console-enter {
  transform: translateY(100%);
}
.z-console-enter-active {
  transform: translateY(0);
  transition: transform 280ms cubic-bezier(0.32, 0.72, 0, 1);
}
.z-console-exit-active {
  transform: translateY(100%);
  transition: transform 220ms ease-in;
}

/* Pulse glow */
@keyframes z-pulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(var(--brand-rgb), 0); }
  50% { box-shadow: 0 0 12px 4px rgba(var(--brand-rgb), 0.15); }
}
.z-mark { animation: z-pulse 4s ease-in-out infinite; }

/* Pulse glow — active insight */
.z-mark--active {
  animation: z-pulse-active 2s ease-in-out infinite;
}
@keyframes z-pulse-active {
  0%, 100% { box-shadow: 0 0 0 0 rgba(var(--brand-rgb), 0); }
  50% { box-shadow: 0 0 16px 6px rgba(var(--brand-rgb), 0.3); }
}

/* Artifact appearance */
.artifact-window-enter {
  opacity: 0;
  transform: scale(0.96) translateY(8px);
}
.artifact-window-enter-active {
  opacity: 1;
  transform: scale(1) translateY(0);
  transition: all 300ms cubic-bezier(0.32, 0.72, 0, 1);
}
```

### Design Principles (Non-Negotiable)

1. **No bouncing.** No spring physics on UI elements. Smooth ease curves only.
2. **No decorative elements.** Every pixel earns its place through function.
3. **No attention-seeking.** The pulse is subtle. Notifications don't scream.
4. **No color overload.** Brand accent used sparingly — 95% neutral palette.
5. **No emoji in Z responses.** Z communicates with words, not icons.
   (UI elements can use icons — Z's text does not.)
6. **Transitions under 300ms.** Anything longer feels sluggish.
7. **Artifact documents are always clean.** Light background, clear typography,
   generous whitespace. They're professional business documents, not chat messages.
8. **Glass effect is subtle.** If you notice the blur, it's too strong.
   It should feel like looking through quality tinted glass, not a filter.

---

## INTEGRATION WITH DOC 35 (AI ARCHITECTURE)

| Console Feature | AI Layer | How |
|----------------|----------|-----|
| Quick action chips | Layer 4 (Session Context) | Chips generated from current screen + navigation history |
| Proactive insights | Layer 5 (Compounding Intel) | Aging thresholds, response patterns, revenue trends |
| Artifact generation | Layer 1 (Identity) + Layer 2 (Knowledge) | Company profile + trade knowledge fill templates |
| Conversational editing | Layer 3 (Memory) | Z remembers pricing preferences, past edits, style |
| RBAC on artifacts | Layer 6 (RBAC Filter) | Tech can't approve bids unless owner enables it |
| Context-aware responses | Layer 4 (Session) | Z knows what screen you're on, what entity is active |
| Auto-response drafts | Layer 1 + Layer 5 | Company profile + response timing intelligence |

### Edge Function Integration

The console maintains a single persistent connection to the `ai-chat` edge function
(defined in Doc 35). Every message from the console includes session_context from
Layer 4, which now also includes:

```json
{
  "session_context": {
    "current_screen": "job_detail",
    "active_job_id": "uuid-4521",
    "console_state": "full",
    "active_artifact": {
      "artifact_id": "uuid-artifact-234",
      "artifact_type": "estimate",
      "status": "draft",
      "template_id": "uuid-standard-residential"
    },
    "conversation_length": 8,
    "last_artifact_action": "edited_line_items"
  }
}
```

The edge function knows the console state. If an artifact is active, Z's responses
are focused on that artifact. If no artifact is active, Z operates in general
assistant mode. The transition is seamless.

---

## BUILD PHASES

| Phase | What | Dependencies |
|-------|------|-------------|
| **Phase 1** | Console shell — three states, transitions, persistence | Root layout architecture |
| **Phase 2** | Conversation UI — message rendering, input, voice | Edge function (Doc 35 Phase 1) |
| **Phase 3** | Session context chips — per-screen quick actions | Layer 4 (Doc 35 Phase 2) |
| **Phase 4** | Pulse — proactive insight surfacing | Realtime subscription |
| **Phase 5** | Artifact rendering engine — template → document | Template system + schema |
| **Phase 6** | Conversational artifact editing | Edge function + artifact state management |
| **Phase 7** | Approval flow + confirmation UI | Artifact events logging |
| **Phase 8** | Event logging (immutable audit trail) | artifact_events table + RLS |
| **Phase 9** | Default templates — bid, invoice, follow-up, scope | Template authoring |
| **Phase 10** | Template customization UI | Settings screens |
| **Phase 11** | Homeowner console variant | Home Portal integration |
| **Phase 12** | Visual polish — glass effects, animations, responsive | Design QA |

---

## RULES

1. **Z travels with you.** Console never unmounts, never loses state, never refreshes.
2. **Three states, fluid transitions.** Pulse → Bar → Full. No modals. No popups.
3. **Glass, not walls.** Translucent backgrounds maintain spatial context. The user
   never feels disconnected from the page they're on.
4. **Templates are law.** Z fills templates, Z does not invent document structures.
   Required sections cannot be removed. Static sections cannot be edited by AI.
5. **Nothing ships without human approval.** Every outgoing artifact requires explicit
   Confirm & Send. No exceptions. No auto-sends on customer-facing documents.
6. **Every approval is logged forever.** artifact_events is immutable. Full content
   snapshot at approval. This is the legal record.
7. **Edits reset approval.** Any change after approval returns artifact to draft.
   Must re-approve. No silent modifications to sent documents.
8. **Conversation drives editing.** Contractors talk to Z to modify artifacts, not
   fill out form fields. Z updates the document live in the artifact window.
9. **Artifacts are always readable.** Light background, clean typography, print-ready.
   They're business documents, not chat outputs.
10. **Design is invisible.** If the user notices the UI, it's too loud. The console
    should feel like it's always been there. Stripe-level restraint.
11. **RBAC on artifacts.** Who can create, edit, approve, and send each artifact type
    is governed by Layer 6. Owner configures permissions per role.
12. **Proactive, not pushy.** Z surfaces one insight at a time. No notification storms.
    If ignored, it fades and resurfaces contextually later.
13. **Homeowner console is simpler.** Same architecture, different personality, fewer
    artifact types, no business intelligence. Z helps them be informed clients.
14. **Event logs protect everyone.** Tereda, the contractor, and the customer all
    benefit from an immutable record of what was created, reviewed, approved, and sent.
15. **Speed is design.** Under 300ms for transitions. Under 100ms for input response.
    Under 2 seconds for artifact generation. If it feels slow, it's broken.

---

**This document is a DRAFT. To be consolidated with expansion documentation.
Cross-references Doc 35 (Universal AI Architecture) and Doc 40 (Dashboard).
Do not begin implementation until reviewed and prioritized against current sprint work.**
