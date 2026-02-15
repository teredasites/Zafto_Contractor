# 50 — Business Completion Systems

> **Created**: Session 102 (2026-02-13)
> **Status**: SPEC'D — Not yet scheduled
> **Total New Tables**: ~18
> **Total New Edge Functions**: ~4
> **Total Estimated Hours**: ~180
> **API Cost at Launch**: $0/month
> **Phase Assignment**: Most fit into Phase U (Unification) or new Phase L (Legal/Compliance)

---

## Overview

Six systems that complete the "run your entire business from one app" promise. These are not intelligence engines — they are **operational systems** that every contractor needs but currently does in Excel, paper, or separate apps. Each one eliminates a tool from the contractor's stack.

### Tools These Replace
| System | Replaces | Typical Cost |
|--------|----------|-------------|
| Mechanic's Lien Engine | Levelset / LienTracker / attorney | $50-500/month |
| Customer Financing | Separate Wisetack/GreenSky portal | $0 (but contractor loses 3-20% dealer fee without integration) |
| CE/License Tracker | Spreadsheet + memory | $0 (but one expired license = shutdown) |
| Material Procurement | Separate PO system + Excel | $30-100/month |
| Daily Job Log | Raken / paper | $30-150/month |
| Change Order Engine | Clearstory / paper / email | $50-200/month |

**Combined replacement value**: $160-1,150/month in separate tools. Zafto: included.

---

## SYSTEM 1: MECHANIC'S LIEN ENGINE

### What It Does
Protects contractors from non-payment. Tracks preliminary notice deadlines by state, auto-generates notice/lien documents from job data, tracks lien status through resolution. State-by-state rules database.

### Why This Matters
Contractors lose **billions annually** in unpaid work. A single $15,000 unpaid job can mean missing payroll. Most contractors don't even know their lien rights exist, or miss the filing deadline by days.

### How It Connects to Existing Systems
- **Jobs** → Every job over a configurable threshold auto-creates a lien tracking record
- **Customers** → Payment history flags high-risk customers
- **Invoices** → Overdue invoice triggers lien deadline countdown
- **Properties** → Property address required for lien filing
- **ZBooks (D4)** → Unpaid receivables drive lien alerts
- **Documents** → Generated lien documents stored in documents bucket
- **Notifications** → Auto-alerts at deadline milestones

### State-by-State Complexity
Every US state has different lien laws:
| Requirement | Range |
|------------|-------|
| Preliminary notice deadline | 10-30 days from first work (some states: not required) |
| Lien filing deadline | 60-180 days from last work or completion |
| Suit filing deadline | 6-24 months from lien filing |
| Notice recipients | Owner only, or owner + GC + lender |
| Notarization required | Some states yes, some no |
| Licensed contractor required | Most states — must have valid license to lien |

### Tables (3 new)
```sql
-- NEW: State lien rules database
CREATE TABLE lien_rules_by_state (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  state_code CHAR(2) NOT NULL UNIQUE,
  preliminary_notice_required BOOLEAN NOT NULL,
  preliminary_notice_deadline_days INTEGER, -- days from first work
  preliminary_notice_recipients TEXT[], -- ['owner', 'gc', 'lender']
  lien_filing_deadline_days INTEGER NOT NULL, -- days from last work
  lien_filing_deadline_from TEXT NOT NULL CHECK (lien_filing_deadline_from IN (
    'last_work', 'completion', 'last_material_delivery', 'notice_of_completion'
  )),
  suit_deadline_months INTEGER NOT NULL, -- months from lien filing
  notarization_required BOOLEAN DEFAULT false,
  license_required_to_lien BOOLEAN DEFAULT true,
  bond_claim_available BOOLEAN DEFAULT false, -- for public projects
  lien_amount_limit TEXT, -- 'contract_price', 'labor_and_materials', 'no_limit'
  special_rules TEXT, -- state-specific nuances
  source_url TEXT, -- link to state statute
  last_verified DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: public read, super_admin write
-- SEED: All 50 states + DC

-- NEW: Lien tracking per job
CREATE TABLE lien_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  customer_id UUID NOT NULL REFERENCES customers(id),
  property_address TEXT NOT NULL,
  state_code CHAR(2) NOT NULL REFERENCES lien_rules_by_state(state_code),
  contract_amount NUMERIC(10,2),
  amount_owed NUMERIC(10,2),
  -- Key dates
  first_work_date DATE,
  last_work_date DATE,
  completion_date DATE,
  -- Preliminary notice
  prelim_notice_deadline DATE,
  prelim_notice_sent_date DATE,
  prelim_notice_document_path TEXT,
  prelim_notice_status TEXT DEFAULT 'not_required' CHECK (prelim_notice_status IN (
    'not_required', 'pending', 'sent', 'confirmed_received'
  )),
  -- Lien
  lien_filing_deadline DATE,
  lien_filed_date DATE,
  lien_document_path TEXT,
  lien_recording_number TEXT,
  lien_status TEXT DEFAULT 'monitoring' CHECK (lien_status IN (
    'monitoring', 'prelim_sent', 'demand_sent', 'lien_filed',
    'suit_filed', 'settled', 'released', 'expired'
  )),
  -- Resolution
  demand_letter_sent_date DATE,
  demand_letter_document_path TEXT,
  payment_received_date DATE,
  lien_release_date DATE,
  lien_release_document_path TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
-- INDEX: company_id, lien_status, lien_filing_deadline

-- NEW: Lien document templates
CREATE TABLE lien_document_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  state_code CHAR(2) NOT NULL,
  document_type TEXT NOT NULL CHECK (document_type IN (
    'preliminary_notice', 'demand_letter', 'mechanics_lien',
    'lien_release', 'notice_of_intent'
  )),
  template_content TEXT NOT NULL, -- HTML template with {{placeholders}}
  placeholders JSONB NOT NULL, -- [{key, description, source}]
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: public read
```

### Edge Functions (1)
| Function | Purpose | Cost |
|----------|---------|------|
| `lien-deadline-monitor` | CRON daily: Check all active lien records. Alert at 30/14/7/3/1 days before each deadline. Auto-calculate deadlines when job dates change. | $0 |

### Flutter Screens (2)
- `lib/screens/liens/lien_dashboard_screen.dart` — All active liens, sorted by approaching deadline. Red/yellow/green status.
- `lib/screens/liens/lien_detail_screen.dart` — Per-job lien timeline: prelim notice → demand → lien → release. Generate documents.

### Web CRM Pages (3)
- `web-portal/src/app/lien-protection/page.tsx` — Dashboard: at-risk jobs, approaching deadlines, total protected amount
- `web-portal/src/app/lien-protection/[jobId]/page.tsx` — Per-job detail with document generation
- `web-portal/src/app/lien-protection/rules/page.tsx` — Browse state lien rules reference

### Hooks (1)
- `use-lien-protection.ts` — CRUD + deadline calculations + document generation

### Sprint Estimate: ~36 hours
| Sprint | Work | Hours |
|--------|------|-------|
| L-LIEN1 | Tables + migration + RLS + seed all 50 states | 10 |
| L-LIEN2 | Document template engine (HTML → PDF via pdf-lib) | 8 |
| L-LIEN3 | Deadline monitor EF + Flutter screens | 8 |
| L-LIEN4 | Web CRM pages + hook | 6 |
| L-LIEN5 | Testing + template refinement | 4 |

### API Cost: $0/month
- pdf-lib (MIT) for document generation
- State lien data: publicly available statutes, manually curated

---

## SYSTEM 2: CUSTOMER FINANCING ENGINE

### What It Does
Embeds financing offers directly into estimates and proposals. Customer applies from the Client Portal. Contractor gets paid in full by the financing company. Tracks which jobs had financing offered vs accepted, and the impact on close rate.

### Why This Matters
Average ticket size increases 30-40% when financing is offered. Jobs over $3,000 close at 73% with financing vs 41% without. Financing companies pay the contractor in full — zero cost to the contractor.

### Financing Partners (all free APIs)
| Provider | Max Amount | Approval Rate | Dealer Fee | API |
|----------|-----------|--------------|------------|-----|
| Wisetack | $25,000 | ~80% | 0-9% | REST API (free) |
| GreenSky | $100,000 | ~75% | 3-20% | REST API (free) |
| Hearth | $250,000 | ~70% | 0% (!) | REST API (free) |

### How It Connects to Existing Systems
- **Estimates (D8)** → "Offer Financing" button on estimate, shows monthly payment
- **Invoices** → Financing-paid invoices auto-marked (financing company pays contractor)
- **Client Portal** → Financing application form, status tracking
- **ZBooks (D4)** → Revenue tracked, dealer fee as expense
- **Job Cost Autopsy** (Engine 2) → Financing impact on profitability tracked

### Tables (2 new)
```sql
-- NEW: Financing offers
CREATE TABLE financing_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  estimate_id UUID REFERENCES estimates(id),
  invoice_id UUID REFERENCES invoices(id),
  customer_id UUID NOT NULL REFERENCES customers(id),
  job_id UUID REFERENCES jobs(id),
  provider TEXT NOT NULL CHECK (provider IN ('wisetack', 'greensky', 'hearth', 'other')),
  amount NUMERIC(10,2) NOT NULL,
  term_months INTEGER,
  monthly_payment NUMERIC(8,2),
  apr NUMERIC(5,2),
  offer_presented_at TIMESTAMPTZ DEFAULT now(),
  customer_action TEXT DEFAULT 'pending' CHECK (customer_action IN (
    'pending', 'applied', 'approved', 'funded', 'declined', 'expired'
  )),
  provider_application_id TEXT, -- ID from financing provider
  provider_status TEXT,
  funded_amount NUMERIC(10,2),
  funded_date DATE,
  dealer_fee_pct NUMERIC(4,2),
  dealer_fee_amount NUMERIC(8,2),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()

-- NEW: Financing settings per company
CREATE TABLE financing_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) UNIQUE,
  enabled BOOLEAN DEFAULT false,
  default_provider TEXT,
  wisetack_merchant_id TEXT,
  greensky_merchant_id TEXT,
  hearth_merchant_id TEXT,
  auto_offer_threshold NUMERIC(10,2) DEFAULT 3000, -- auto-show financing for jobs over this amount
  show_monthly_payment_on_estimate BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
```

### Edge Functions (1)
| Function | Purpose | Cost |
|----------|---------|------|
| `financing-offer-proxy` | Proxy API calls to Wisetack/GreenSky/Hearth. Contractor's merchant credentials stored server-side. Returns pre-qualified terms. | $0 (all provider APIs are free) |

### Sprint Estimate: ~24 hours
| Sprint | Work | Hours |
|--------|------|-------|
| U-FIN1 | Tables + migration + RLS + settings UI | 6 |
| U-FIN2 | Estimate integration: monthly payment display + "Apply" button | 6 |
| U-FIN3 | Client Portal financing application flow | 6 |
| U-FIN4 | Financing analytics + provider API integration + testing | 6 |

### API Cost: $0/month
- Wisetack API: free for merchants
- GreenSky API: free for merchants
- Hearth API: free for merchants (zero dealer fee option)

---

## SYSTEM 3: CE / LICENSE RENEWAL TRACKER

### What It Does
Extends existing Certifications module (D7a) to track Continuing Education credits, license renewal deadlines, and per-employee compliance status. Per-state CE requirements database. Auto-alerts before renewals.

### How It Connects to Existing Systems
- **Certifications (D7a)** → DIRECTLY EXTENDS. Already has expiry tracking, renewal reminders, certification types from `certification_types` table. This adds CE credit tracking and state requirements.
- **Team Portal** → Employee sees their CE status, hours remaining
- **HR (F5)** → `hr_documents` for uploaded CE certificates
- **Regulatory Compliance** (Engine 8) → CE tracking feeds into company-wide compliance view

### Tables (2 new, 1 extended)
```sql
-- Extend certification_types to include CE requirements
ALTER TABLE certification_types ADD COLUMN IF NOT EXISTS
  ce_credits_required INTEGER, -- total CE hours needed per renewal period
  renewal_period_months INTEGER DEFAULT 24, -- how often renewal happens
  state_code CHAR(2), -- state-specific requirement (NULL = national)
  governing_body TEXT, -- "State Licensing Board", "NFPA", "EPA"
  ce_categories JSONB; -- [{category: "safety", hours_required: 4}, {category: "code_update", hours_required: 8}]

-- NEW: CE credit log per employee
CREATE TABLE ce_credit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  user_id UUID NOT NULL REFERENCES users(id),
  certification_id UUID NOT NULL REFERENCES certifications(id), -- which cert this CE applies to
  course_name TEXT NOT NULL,
  provider TEXT, -- "NFPA", "ICC", "State Board", etc.
  credit_hours NUMERIC(4,1) NOT NULL,
  ce_category TEXT, -- matches categories from certification_types
  completion_date DATE NOT NULL,
  certificate_document_path TEXT, -- uploaded proof
  verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
-- INDEX: user_id, certification_id, completion_date

-- NEW: License renewal tracking
CREATE TABLE license_renewals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  certification_id UUID NOT NULL REFERENCES certifications(id),
  user_id UUID NOT NULL REFERENCES users(id),
  renewal_due_date DATE NOT NULL,
  ce_credits_required INTEGER NOT NULL,
  ce_credits_completed INTEGER DEFAULT 0,
  ce_credits_remaining INTEGER GENERATED ALWAYS AS (ce_credits_required - ce_credits_completed) STORED,
  renewal_status TEXT DEFAULT 'in_progress' CHECK (renewal_status IN (
    'in_progress', 'credits_complete', 'submitted', 'renewed', 'lapsed'
  )),
  renewal_fee NUMERIC(8,2),
  renewal_fee_paid BOOLEAN DEFAULT false,
  submitted_date DATE,
  renewed_date DATE,
  new_expiry_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
```

### Sprint Estimate: ~20 hours
| Sprint | Work | Hours |
|--------|------|-------|
| L-CE1 | Table extensions + new tables + migration + RLS | 6 |
| L-CE2 | Flutter: CE log entry + renewal status view | 6 |
| L-CE3 | CRM: employee compliance dashboard + CE tracking | 4 |
| L-CE4 | Team Portal: my CE status + upload certificates + testing | 4 |

### API Cost: $0/month

---

## SYSTEM 4: MATERIAL PROCUREMENT & PRICE TRACKING

### What It Does
Auto-generates material lists from estimates/sketches. Tracks purchase prices over time. Supplier comparison. Purchase order generation. Receipt matching. Auto-markup calculator.

### How It Connects to Existing Systems
- **Estimates (D8)** → Material list auto-populated from estimate line items
- **Sketch Engine (SK)** → Auto-estimate generates material quantities
- **Receipts** → Receipt photos matched to POs
- **ZBooks (D4)** → Material purchases flow into job costing
- **Job Cost Autopsy** (Engine 2) → Estimated vs actual material cost
- **Vendors** → Already have vendor tables from PM module
- **Purchase Orders (F5)** → `purchase_orders` and `purchase_order_items` tables already exist!
- **Unwrangle API** → HD/Lowe's pricing (API key already stored)

### Tables (2 new, existing PO tables extended)
```sql
-- Extend existing purchase_order_items
ALTER TABLE purchase_order_items ADD COLUMN IF NOT EXISTS
  estimated_unit_price NUMERIC(10,2),
  actual_unit_price NUMERIC(10,2),
  markup_pct NUMERIC(5,2),
  supplier_name TEXT,
  supplier_sku TEXT;

-- NEW: Material price history (track prices over time)
CREATE TABLE material_price_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  material_name TEXT NOT NULL,
  material_category TEXT, -- 'wire', 'pipe', 'lumber', 'fittings', 'fixtures'
  unit TEXT NOT NULL, -- 'ft', 'each', 'box', 'roll', 'yard'
  supplier_name TEXT,
  unit_price NUMERIC(10,2) NOT NULL,
  recorded_date DATE NOT NULL DEFAULT CURRENT_DATE,
  source TEXT DEFAULT 'manual' CHECK (source IN ('manual', 'receipt_scan', 'api', 'purchase_order')),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
-- INDEX: company_id, material_name, recorded_date

-- NEW: Material lists per job (auto-generated or manual)
CREATE TABLE job_material_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  estimate_id UUID REFERENCES estimates(id),
  line_items JSONB NOT NULL, -- [{material_name, quantity, unit, estimated_price, actual_price, purchased}]
  total_estimated NUMERIC(10,2),
  total_actual NUMERIC(10,2),
  markup_total NUMERIC(10,2),
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'ordering', 'partial', 'complete')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
```

### Sprint Estimate: ~28 hours
| Sprint | Work | Hours |
|--------|------|-------|
| U-MAT1 | Tables + migration + RLS + PO extension | 6 |
| U-MAT2 | Material list generation from estimates | 8 |
| U-MAT3 | Price history tracking + Unwrangle API integration | 6 |
| U-MAT4 | PO generation + receipt matching + supplier comparison | 4 |
| U-MAT5 | CRM dashboard: material costs, price trends + testing | 4 |

### API Cost: $0/month
- Unwrangle (HD/Lowe's pricing): API key already stored, free tier
- All other processing local

---

## SYSTEM 5: DAILY JOB LOG

### What It Does
Per-job daily documentation: weather, crew on-site, hours worked, work performed, materials used, photos, visitor log, safety incidents, delays. Auto-populates from time clock and photos already in the system. Digital supervisor signature.

### Why This Matters
The daily log is the **legal record** that wins lawsuits and insurance disputes. "We documented every day of work with photos, weather, crew, and progress notes." vs "We don't have records of that." This is the difference between winning and losing a $50,000 dispute.

### How It Connects to Existing Systems
- **Jobs** → One log per day per active job
- **Time Clock** → Auto-populates crew on-site and hours from time entries
- **Photos** → Photos taken that day auto-linked to daily log
- **Weather** (Engine 5) → Auto-captures weather conditions
- **Permits** (Engine 3) → Inspector visits auto-logged
- **Materials** (System 4) → Materials used that day
- **Team Portal** → Field techs fill in daily log from the field
- **Client Portal** → Owner/GC can view daily logs for transparency
- **Change Orders** (System 6) → Delay documentation feeds CO justification

### Tables (2 new)
```sql
-- NEW: Daily job logs
CREATE TABLE daily_job_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  log_date DATE NOT NULL,
  -- Weather (auto or manual)
  weather_conditions TEXT, -- 'clear', 'rain', 'snow', 'overcast', 'windy'
  weather_temp_high INTEGER,
  weather_temp_low INTEGER,
  weather_source TEXT DEFAULT 'manual' CHECK (weather_source IN ('manual', 'auto')),
  -- Crew
  crew_members JSONB, -- [{user_id, name, role, hours_worked}] — auto from time clock
  total_crew_hours NUMERIC(6,1),
  -- Work performed
  work_description TEXT NOT NULL,
  work_areas TEXT[], -- room/area names where work was done
  percent_complete INTEGER CHECK (percent_complete BETWEEN 0 AND 100),
  -- Materials
  materials_used JSONB, -- [{material, quantity, unit}]
  -- Visitors
  visitors JSONB, -- [{name, company, purpose, time_in, time_out}]
  -- Safety
  safety_incidents JSONB, -- [{description, severity, reported_to}] — hopefully empty
  safety_toolbox_talk TEXT, -- topic of daily safety briefing
  -- Delays
  delays JSONB, -- [{cause: 'weather'|'material'|'owner'|'inspection'|'other', hours, description}]
  -- Photos (auto-linked from photos taken that day for this job)
  photo_count INTEGER DEFAULT 0,
  -- Signature
  submitted_by UUID REFERENCES users(id),
  supervisor_signature_path TEXT,
  submitted_at TIMESTAMPTZ,
  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved')),
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
-- UNIQUE: (company_id, job_id, log_date) — one log per day per job
-- INDEX: job_id, log_date

-- NEW: Daily log templates (pre-fill common entries)
CREATE TABLE daily_log_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  template_name TEXT NOT NULL,
  trade_type TEXT,
  default_work_areas TEXT[],
  default_safety_talk_topics TEXT[],
  default_materials JSONB,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
```

### Edge Functions (1)
| Function | Purpose | Cost |
|----------|---------|------|
| `daily-log-auto-populate` | When creating a new daily log, auto-fills: weather from Open-Meteo, crew from time entries, photos from that day's uploads, previous day's percent_complete. | $0 |

### Flutter Screens (2)
- `lib/screens/daily_log/daily_log_screen.dart` — Fill in daily log: mostly pre-populated, tech adds work description + materials
- `lib/screens/daily_log/daily_log_history_screen.dart` — Browse past daily logs per job

### Web CRM Pages (2)
- `web-portal/src/app/daily-logs/page.tsx` — All daily logs across jobs, filterable
- `web-portal/src/app/daily-logs/[jobId]/page.tsx` — Per-job daily log timeline

### Team Portal (1)
- `team-portal/src/app/daily-log/page.tsx` — Field tech fills in daily log for assigned job

### Client Portal (1)
- `client-portal/src/app/project/[id]/daily-logs/page.tsx` — Owner/GC views daily progress (optional share)

### Sprint Estimate: ~32 hours
| Sprint | Work | Hours |
|--------|------|-------|
| U-LOG1 | Tables + migration + RLS + auto-populate EF | 8 |
| U-LOG2 | Flutter screens + Team Portal daily log entry | 8 |
| U-LOG3 | Web CRM pages + hooks | 8 |
| U-LOG4 | Client Portal view + templates + testing | 8 |

### API Cost: $0/month
- Weather from Open-Meteo (free)
- All other data from existing system

---

## SYSTEM 6: CHANGE ORDER ENGINE

### What It Does
Structured change order workflow: request → scope → price → customer approval → revised contract. Tracks cumulative cost impact. Photo documentation per CO. Customer approval via Client Portal. Auto-adjusts schedule impact.

### How It Connects to Existing Systems
- **Jobs** → Change orders modify job scope and total
- **Estimates (D8)** → Original estimate vs revised estimate
- **Schedule (GC)** → CO may extend timeline
- **Invoices** → Revised invoice reflects all approved COs
- **Client Portal** → Customer reviews and approves/rejects COs digitally
- **Documents** → CO documents stored in documents bucket
- **Signatures** → Digital signature on CO approval
- **ZBooks (D4)** → Revenue tracking includes CO amounts
- **Job Cost Autopsy** (Engine 2) → CO impact on profitability
- **Daily Job Log** (System 5) → Delay documentation justifies COs
- **Note**: `change_orders` functionality may already exist in web hooks (`use-change-orders.ts` exists in CRM + Team Portal). This spec builds the FULL engine with document generation, Client Portal approval, and cumulative tracking.

### Tables (2 new)
```sql
-- NEW: Change orders (if not already existing — check existing hooks)
CREATE TABLE change_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  change_order_number INTEGER NOT NULL, -- sequential per job: CO#1, CO#2, etc.
  -- Scope
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  reason TEXT CHECK (reason IN (
    'owner_request', 'unforeseen_condition', 'design_change',
    'code_requirement', 'material_substitution', 'error_correction', 'other'
  )),
  -- Financial
  cost_impact NUMERIC(10,2) NOT NULL, -- positive = addition, negative = credit
  original_contract_amount NUMERIC(10,2),
  revised_contract_amount NUMERIC(10,2),
  -- Schedule
  schedule_impact_days INTEGER DEFAULT 0,
  -- Documentation
  photos TEXT[], -- paths to before/after photos
  supporting_documents TEXT[], -- paths to docs (sketches, specs, etc.)
  -- Approval
  status TEXT DEFAULT 'draft' CHECK (status IN (
    'draft', 'submitted', 'customer_review', 'approved', 'rejected', 'voided'
  )),
  submitted_at TIMESTAMPTZ,
  customer_viewed_at TIMESTAMPTZ,
  customer_decision TEXT CHECK (customer_decision IN ('approved', 'rejected', 'negotiate')),
  customer_notes TEXT,
  customer_signature_path TEXT,
  approved_at TIMESTAMPTZ,
  -- Metadata
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
-- UNIQUE: (company_id, job_id, change_order_number)

-- NEW: Change order line items
CREATE TABLE change_order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  change_order_id UUID NOT NULL REFERENCES change_orders(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity NUMERIC(8,2) DEFAULT 1,
  unit TEXT DEFAULT 'each',
  unit_price NUMERIC(10,2) NOT NULL,
  total NUMERIC(10,2) NOT NULL,
  item_type TEXT DEFAULT 'addition' CHECK (item_type IN ('addition', 'credit', 'no_change')),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: via change_order join
```

### Edge Functions (1)
| Function | Purpose | Cost |
|----------|---------|------|
| `change-order-notify` | When CO submitted for customer review, sends notification via SMS/email with link to Client Portal approval page. | $0 (existing SignalWire/SendGrid) |

### Client Portal (1)
- `client-portal/src/app/project/[id]/change-orders/page.tsx` — Customer views CO details, line items, photos. Approve/reject with digital signature.

### Sprint Estimate: ~28 hours
| Sprint | Work | Hours |
|--------|------|-------|
| U-CO1 | Tables + migration + RLS (check existing change_orders first) | 6 |
| U-CO2 | Flutter: CO creation, line items, photo attachment | 8 |
| U-CO3 | CRM: CO management, cumulative tracking, document generation | 6 |
| U-CO4 | Client Portal: CO review + approval + signature | 4 |
| U-CO5 | Notifications + testing | 4 |

### API Cost: $0/month

---

## IMPORTANT NOTES

### Existing Hooks to Check
Before building, verify these existing hooks and their completeness:
- `web-portal/src/lib/hooks/use-change-orders.ts` — May already have partial CO implementation
- `team-portal/src/lib/hooks/use-change-orders.ts` — Team side may exist
- `client-portal/src/lib/hooks/use-change-orders.ts` — Client side may exist

If COs already have tables/hooks, this spec EXTENDS them rather than replacing.

### Xactimate Legal Warning
**NEVER generate .ESX files.** Verisk (Xactimate parent company) owns the proprietary format and has pursued legal action against reverse-engineering. Safe alternatives:
- Store Xactimate-compatible line item codes (already done: `xactimate_estimate_lines` table)
- Export scope as PDF/CSV that adjusters can manually enter into Xactimate
- Future: Integrate with Symbility/CoreLogic API (open alternative)

---

## GRAND TOTALS

| System | Phase | Tables | EFs | Hours |
|--------|-------|--------|-----|-------|
| 1. Mechanic's Lien Engine | L | 3 | 1 | 36 |
| 2. Customer Financing | U-ext | 2 | 1 | 24 |
| 3. CE/License Tracker | L | 2+ext | 0 | 20 |
| 4. Material Procurement | U-ext | 2+ext | 0 | 28 |
| 5. Daily Job Log | U-ext | 2 | 1 | 32 |
| 6. Change Order Engine | U-ext | 2 | 1 | 28 |
| **TOTALS** | | **~18** | **~4** | **~168** |
