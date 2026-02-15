# ZAFTO Expansion Spec #39: Programs Module
## Created: February 9, 2026 (Session 92)

---

## OVERVIEW

Optional module for contractors who do TPA (Third Party Administrator) / insurance program work. Activated per-company in settings. When disabled, zero TPA UI surfaces anywhere. When enabled, TPA features integrate contextually into existing screens — not a separate app, not a separate section.

**Target market:** Restoration contractors (water, fire, mold), roofing contractors, and any trade contractor doing insurance claim work through managed repair programs.

**Value prop:** Replace $1,400+/month in fragmented software (DASH $595, Encircle $250, QuickBooks $200, equipment tracking $100, supplement tools $120) with one platform that also does things NO ONE else does (multi-TPA dashboard, per-TPA profitability, documentation validation, scorecard tracking).

---

## ARCHITECTURE PRINCIPLE: OPTIONAL MODULE, NOT IN EVERYONE'S FACE

The TPA module is a **company-level feature flag**. When `company.features.tpa_enabled = false`:
- No TPA-related UI elements appear anywhere
- No TPA sidebar items
- No TPA fields on jobs, estimates, or field tools
- Database tables exist but are never queried

When `company.features.tpa_enabled = true`:
- TPA fields appear contextually on existing screens
- TPA sidebar section appears in CRM
- TPA dashboard available
- TPA documentation requirements enforce on field tools

This mirrors how Property Management (D5) works — it's a module that surfaces only when the company uses it.

---

## LEGAL CONSTRAINTS (MUST FOLLOW — SEE memory/tpa-legal-assessment.md)

1. **NEVER scrape/automate TPA portals.** Manual data entry or official APIs only.
2. **NEVER copy Xactimate pricing data.** Build own pricing database independently.
3. **NEVER aggregate cross-contractor TPA fees.** Per-contractor private data only.
4. **Frame estimates as "contractor's scope of work and pricing"** — never "insurance claim estimate."
5. **Use own line item codes with mapping table** to Xactimate codes for export.
6. **TPA/carrier brand names OK in dropdowns** with nominative fair use disclaimer.
7. **IICRC formulas OK** — published freely. Category/class definitions = industry standard terms.
8. **ESX import (reading) OK.** ESX export needs Verisk partnership.
9. **FML export OK** — open format, freely documented.
10. **IP attorney opinion letter required** before shipping ESX export or line item mapping (deferred to revenue stage).

---

## DATABASE SCHEMA

### New Tables (~17 tables)

```sql
-- ============================================================
-- TPA MODULE TABLES
-- ============================================================

-- T1: TPA Programs (company's enrolled programs)
CREATE TABLE tpa_programs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  name text NOT NULL, -- e.g., "Contractor Connection", "Accuserve"
  tpa_type text NOT NULL DEFAULT 'managed_repair',
  -- CHECK (tpa_type IN ('managed_repair', 'home_warranty', 'direct_carrier', 'other'))
  carrier_names text[] DEFAULT '{}', -- carriers routed through this TPA
  referral_fee_percent numeric(5,2), -- e.g., 6.00 for 6%
  referral_fee_type text DEFAULT 'percentage',
  -- CHECK (referral_fee_type IN ('percentage', 'flat_per_job', 'tiered'))
  payment_terms_days integer, -- net 30, net 45, etc.
  portal_url text, -- URL to TPA's portal (for reference, NOT for scraping)
  portal_username text, -- contractor's own username (optional, for reference)
  contact_name text,
  contact_phone text,
  contact_email text,
  sla_first_contact_minutes integer DEFAULT 120, -- 2 hours
  sla_onsite_hours integer DEFAULT 24,
  sla_estimate_hours integer DEFAULT 24,
  sla_daily_monitoring boolean DEFAULT true,
  sla_final_estimate_hours integer DEFAULT 24,
  notes text,
  status text NOT NULL DEFAULT 'active',
  -- CHECK (status IN ('active', 'suspended', 'inactive', 'pending_enrollment'))
  enrolled_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- T2: TPA Assignments (jobs dispatched through TPA programs)
CREATE TABLE tpa_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  tpa_program_id uuid NOT NULL REFERENCES tpa_programs(id),
  job_id uuid REFERENCES jobs(id), -- linked to existing job
  assignment_number text, -- TPA's assignment/claim reference number
  claim_number text,
  policy_number text,
  carrier_name text,
  adjuster_name text,
  adjuster_phone text,
  adjuster_email text,
  loss_type text,
  -- CHECK (loss_type IN ('water', 'fire', 'mold', 'wind_hail', 'theft', 'vandalism', 'other'))
  loss_date timestamptz, -- aka "date of loss" — single field, no duplication
  policyholder_name text,
  policyholder_phone text,
  policyholder_email text,
  property_address text,
  -- Emergency Services Authorization (ESA)
  emergency_auth_amount numeric(12,2), -- not-to-exceed amount ($5K-$10K typical)
  emergency_auth_status text DEFAULT 'none',
  -- CHECK (emergency_auth_status IN ('none', 'requested', 'approved', 'denied'))
  emergency_auth_at timestamptz,
  emergency_auth_approved_by text, -- adjuster/TPA name who approved
  -- SLA tracking
  assigned_at timestamptz, -- when TPA dispatched
  first_contact_at timestamptz, -- when contractor called homeowner
  first_contact_deadline timestamptz, -- auto-calculated from SLA
  onsite_at timestamptz, -- when arrived on-site
  onsite_deadline timestamptz,
  estimate_submitted_at timestamptz,
  estimate_deadline timestamptz,
  job_started_at timestamptz,
  job_completed_at timestamptz,
  final_estimate_submitted_at timestamptz,
  final_estimate_deadline timestamptz,
  -- Status
  status text NOT NULL DEFAULT 'received',
  -- CHECK (status IN ('received', 'accepted', 'rejected', 'contacted', 'inspected', 'emergency_authorized', 'in_progress', 'drying', 'drying_complete', 'estimate_submitted', 'supplement_pending', 'supplement_submitted', 'reviewed', 'approved', 'work_complete', 'billing_pending', 'payment_pending', 'paid', 'closed', 'canceled'))
  -- Financial
  estimated_amount numeric(12,2),
  approved_amount numeric(12,2),
  supplement_amount numeric(12,2),
  referral_fee_amount numeric(12,2), -- calculated from program rate
  payment_received_amount numeric(12,2),
  payment_received_at timestamptz,
  invoice_sent_at timestamptz,
  payment_due_at timestamptz, -- auto-calculated from program payment_terms_days
  payment_aging_days integer, -- auto-calculated: today - invoice_sent_at
  payment_followup_count integer DEFAULT 0,
  last_followup_at timestamptz,
  -- Scoring
  customer_satisfaction_score numeric(3,1), -- 1-10 or 1-5
  cycle_time_days integer, -- auto-calculated
  sla_violations text[] DEFAULT '{}', -- list of SLA types violated
  -- Documentation tracking
  documentation_status text DEFAULT 'incomplete',
  -- CHECK (documentation_status IN ('incomplete', 'pending_review', 'complete', 'deficient'))
  documentation_checklist jsonb DEFAULT '{}',
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- T3: TPA Scorecard Entries (track scores over time)
CREATE TABLE tpa_scorecards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  tpa_program_id uuid NOT NULL REFERENCES tpa_programs(id),
  period_start date NOT NULL,
  period_end date NOT NULL,
  -- Metrics (names match industry standard scoring categories)
  overall_score numeric(5,2),
  response_time_score numeric(5,2),
  cycle_time_score numeric(5,2),
  customer_satisfaction_score numeric(5,2),
  documentation_score numeric(5,2),
  estimate_accuracy_score numeric(5,2),
  supplement_rate numeric(5,2), -- percentage
  sla_compliance_rate numeric(5,2), -- percentage
  assignment_volume integer, -- jobs received this period
  notes text,
  entered_by uuid REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- T4: Water Damage Classifications (per-job IICRC assessment)
CREATE TABLE water_damage_assessments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  job_id uuid NOT NULL REFERENCES jobs(id),
  tpa_assignment_id uuid REFERENCES tpa_assignments(id),
  assessed_by uuid REFERENCES users(id),
  assessed_at timestamptz NOT NULL DEFAULT now(),
  -- IICRC S500 Classifications
  water_category integer NOT NULL,
  -- CHECK (water_category IN (1, 2, 3))
  water_category_description text, -- "Clean", "Gray", "Black"
  water_class integer NOT NULL,
  -- CHECK (water_class IN (1, 2, 3, 4))
  water_class_description text, -- "Least", "Significant", "Greatest", "Specialty"
  -- Category can change over time
  category_changed boolean DEFAULT false,
  category_changed_at timestamptz,
  previous_category integer,
  category_change_reason text,
  -- Source identification
  source_of_loss text NOT NULL,
  source_details text,
  -- Affected areas
  affected_rooms text[] DEFAULT '{}',
  affected_materials text[] DEFAULT '{}', -- drywall, carpet, hardwood, concrete, etc.
  total_affected_sqft numeric(10,2),
  -- Pre-existing conditions
  pre_existing_conditions text,
  -- Notes
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- T5: Moisture Reading Logs (IICRC S500 daily monitoring)
CREATE TABLE moisture_readings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  job_id uuid NOT NULL REFERENCES jobs(id),
  tpa_assignment_id uuid REFERENCES tpa_assignments(id),
  recorded_by uuid REFERENCES users(id),
  recorded_at timestamptz NOT NULL DEFAULT now(),
  reading_day integer NOT NULL DEFAULT 1, -- Day 1, Day 2, etc.
  -- Location
  room_name text NOT NULL,
  material_type text NOT NULL, -- drywall, wood, concrete, carpet, pad, subfloor
  location_description text, -- "North wall, 24 inches from floor"
  location_number integer, -- mapped location number for tracking
  -- Readings
  moisture_content numeric(6,2), -- MC percentage
  reading_type text DEFAULT 'pin',
  -- CHECK (reading_type IN ('pin', 'pinless', 'thermo_hygrometer', 'calcium_chloride'))
  -- Reference standard
  dry_reference numeric(6,2), -- reading from unaffected similar material
  is_at_goal boolean DEFAULT false, -- has this location reached drying goal?
  -- Equipment used
  meter_brand text,
  meter_model text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- T6: Psychrometric Logs (IICRC S500 environmental monitoring)
CREATE TABLE psychrometric_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  job_id uuid NOT NULL REFERENCES jobs(id),
  tpa_assignment_id uuid REFERENCES tpa_assignments(id),
  recorded_by uuid REFERENCES users(id),
  recorded_at timestamptz NOT NULL DEFAULT now(),
  reading_day integer NOT NULL DEFAULT 1,
  -- Indoor readings
  indoor_temp_f numeric(5,1),
  indoor_rh numeric(5,1), -- relative humidity %
  indoor_gpp numeric(6,1), -- grains per pound (calculated)
  indoor_dew_point numeric(5,1), -- calculated
  -- Outdoor readings (for comparison)
  outdoor_temp_f numeric(5,1),
  outdoor_rh numeric(5,1),
  outdoor_gpp numeric(6,1),
  -- Dehumidifier readings
  dehu_inlet_temp numeric(5,1),
  dehu_inlet_rh numeric(5,1),
  dehu_outlet_temp numeric(5,1),
  dehu_outlet_rh numeric(5,1),
  dehu_outlet_gpp numeric(6,1),
  -- Room/area
  room_name text NOT NULL,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- T7: Equipment Deployment (track equipment at job sites)
CREATE TABLE equipment_deployments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  job_id uuid NOT NULL REFERENCES jobs(id),
  tpa_assignment_id uuid REFERENCES tpa_assignments(id),
  -- Equipment identification
  equipment_type text NOT NULL,
  -- CHECK (equipment_type IN ('dehumidifier_lgr', 'dehumidifier_conventional', 'dehumidifier_desiccant', 'air_mover', 'air_scrubber', 'negative_air_machine', 'hydroxyl_generator', 'ozone_generator', 'thermal_imaging', 'moisture_meter', 'thermo_hygrometer', 'other'))
  equipment_name text, -- "Dri-Eaz LGR 7000XLi"
  serial_number text,
  asset_tag text, -- internal company tag
  -- AHAM/performance ratings
  aham_ppd numeric(6,1), -- pints per day at AHAM conditions
  cfm_rating numeric(8,1), -- cubic feet per minute
  -- Placement
  room_name text NOT NULL,
  placement_description text, -- "Center of room, directed at north wall"
  -- Billing
  placed_at timestamptz NOT NULL,
  removed_at timestamptz,
  billable_days numeric(6,2), -- auto-calculated
  daily_rate numeric(8,2), -- contractor's rate
  total_charge numeric(10,2), -- auto-calculated
  -- Status
  status text NOT NULL DEFAULT 'deployed',
  -- CHECK (status IN ('deployed', 'operational', 'needs_attention', 'removed', 'retrieved'))
  is_operational boolean DEFAULT true,
  last_checked_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- T8: IICRC Equipment Calculations (stored per job)
CREATE TABLE equipment_calculations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  job_id uuid NOT NULL REFERENCES jobs(id),
  room_name text NOT NULL,
  -- Room dimensions
  length_ft numeric(8,2) NOT NULL,
  width_ft numeric(8,2) NOT NULL,
  height_ft numeric(8,2) NOT NULL DEFAULT 8,
  cubic_feet numeric(12,2), -- auto-calculated
  -- Water damage classification
  water_class integer NOT NULL, -- 1, 2, 3, or 4
  -- Dehumidifier calculation (IICRC formula)
  dehu_type text DEFAULT 'lgr', -- lgr, conventional, desiccant
  chart_factor integer, -- from IICRC table (Class 2 LGR = 50)
  total_ppd_needed numeric(8,1), -- cubic_feet / chart_factor
  dehu_unit_ppd numeric(8,1), -- AHAM rating of unit being used
  dehu_units_needed integer, -- rounded UP
  -- Air mover calculation (IICRC formula)
  affected_wall_lf numeric(8,2),
  affected_floor_sf numeric(10,2),
  affected_ceiling_sf numeric(10,2),
  air_movers_for_walls integer, -- wall_lf / 14, rounded up
  air_movers_for_floor integer, -- floor_sf / 50-70, rounded up
  air_movers_for_ceiling integer, -- ceiling_sf / 100-150, rounded up
  wall_insets integer DEFAULT 0, -- additional AM per inset >18"
  total_air_movers_needed integer,
  -- Air scrubber calculation
  target_ach numeric(4,1) DEFAULT 4, -- air changes per hour
  scrubber_cfm_needed numeric(8,1), -- cubic_feet / 60 * target_ach
  -- Actuals
  dehu_units_placed integer,
  air_movers_placed integer,
  scrubbers_placed integer,
  -- Over/under justification
  variance_notes text,
  calculated_by uuid REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- T9: TPA Documentation Checklists (configurable per TPA program)
CREATE TABLE tpa_doc_requirements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  tpa_program_id uuid NOT NULL REFERENCES tpa_programs(id),
  -- Requirement definition
  requirement_name text NOT NULL,
  requirement_category text NOT NULL,
  -- CHECK (requirement_category IN ('photo', 'moisture', 'equipment', 'form', 'estimate', 'report', 'signature', 'other'))
  description text,
  -- When required
  required_phase text NOT NULL,
  -- CHECK (required_phase IN ('initial_inspection', 'during_work', 'daily_monitoring', 'completion', 'closeout'))
  -- Timing
  due_within_hours integer, -- hours after phase starts
  is_mandatory boolean DEFAULT true,
  -- Photo specifics
  photo_min_count integer,
  photo_description text, -- "Equipment placement with serial numbers visible"
  -- Validation
  validation_type text DEFAULT 'manual',
  -- CHECK (validation_type IN ('manual', 'auto_photo_count', 'auto_reading_exists', 'auto_form_complete'))
  sort_order integer DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- T10: Supplement Tracking (for TPA claim supplements)
CREATE TABLE tpa_supplements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  tpa_assignment_id uuid NOT NULL REFERENCES tpa_assignments(id),
  job_id uuid NOT NULL REFERENCES jobs(id),
  supplement_number integer NOT NULL DEFAULT 1, -- S1, S2, S3...
  -- What changed
  reason text NOT NULL,
  description text,
  -- Financial
  original_amount numeric(12,2),
  supplement_amount numeric(12,2),
  approved_amount numeric(12,2),
  -- Status workflow
  status text NOT NULL DEFAULT 'draft',
  -- CHECK (status IN ('draft', 'submitted', 'under_review', 'approved', 'partially_approved', 'denied', 'appealed', 'resubmitted'))
  submitted_at timestamptz,
  reviewed_at timestamptz,
  approved_at timestamptz,
  denied_at timestamptz,
  denial_reason text,
  -- Linked documentation
  photo_ids uuid[] DEFAULT '{}', -- photos supporting the supplement
  line_items jsonb DEFAULT '[]', -- supplemental line items
  -- Adjuster interaction
  adjuster_notes text,
  contractor_response text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- T11: TPA Financial Summary (per-program rollup, auto-calculated)
-- This is a materialized view / summary table updated on job changes
CREATE TABLE tpa_program_financials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  tpa_program_id uuid NOT NULL REFERENCES tpa_programs(id),
  period_month date NOT NULL, -- first of month
  -- Revenue
  total_jobs integer DEFAULT 0,
  total_revenue numeric(14,2) DEFAULT 0,
  total_referral_fees numeric(14,2) DEFAULT 0,
  net_revenue numeric(14,2) DEFAULT 0, -- revenue - referral fees
  -- Costs (from Ledger job costing)
  total_labor_cost numeric(14,2) DEFAULT 0,
  total_material_cost numeric(14,2) DEFAULT 0,
  total_equipment_cost numeric(14,2) DEFAULT 0,
  total_subcontractor_cost numeric(14,2) DEFAULT 0,
  total_admin_cost numeric(14,2) DEFAULT 0, -- allocated admin overhead
  -- Profit
  gross_margin numeric(14,2) DEFAULT 0,
  gross_margin_percent numeric(5,2) DEFAULT 0,
  net_margin numeric(14,2) DEFAULT 0,
  net_margin_percent numeric(5,2) DEFAULT 0,
  -- Cash flow
  avg_payment_days numeric(6,1) DEFAULT 0,
  outstanding_ar numeric(14,2) DEFAULT 0,
  -- Supplement performance
  total_supplements integer DEFAULT 0,
  supplements_approved integer DEFAULT 0,
  supplements_denied integer DEFAULT 0,
  supplement_recovery_amount numeric(14,2) DEFAULT 0,
  -- Scoring
  avg_cycle_time_days numeric(6,1) DEFAULT 0,
  avg_satisfaction_score numeric(3,1) DEFAULT 0,
  sla_compliance_rate numeric(5,2) DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(company_id, tpa_program_id, period_month)
);

-- T12: ZAFTO Restoration Line Items (OWN codes, NOT Xactimate copies)
-- Maps to Xactimate codes for export but uses independent descriptions + pricing
CREATE TABLE restoration_line_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- ZAFTO's own code system
  zafto_code text NOT NULL UNIQUE, -- e.g., "Z-WTR-EXT-001"
  category text NOT NULL, -- "water_extraction", "demolition", "drying", "cleaning", etc.
  subcategory text,
  description text NOT NULL, -- OWN description, NOT copied from Xactimate
  -- Unit and measurement
  unit text NOT NULL, -- SF, LF, EA, HR, DY
  -- Mapping (for export interoperability)
  xactimate_category text, -- WTR, DRY, CLN, etc. (industry standard abbreviations)
  xactimate_selector text, -- WTREXT, WTRDRYW, etc.
  symbility_code text, -- if different
  -- Default pricing (ZAFTO's own, NOT Xactimate pricing)
  -- Pricing comes from independent market research
  default_price numeric(10,2),
  price_source text, -- "zafto_survey_2026", "contractor_submitted", etc.
  -- Metadata
  trade text, -- "restoration", "roofing", "general"
  applies_to text[] DEFAULT '{}', -- ["water", "fire", "mold"]
  notes text,
  is_active boolean DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- T13: Certificate of Completion
CREATE TABLE certificates_of_completion (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  job_id uuid NOT NULL REFERENCES jobs(id),
  tpa_assignment_id uuid REFERENCES tpa_assignments(id),
  -- Certification details
  certificate_number text,
  completion_date date NOT NULL,
  -- Scope summary
  scope_summary text,
  work_performed text,
  -- Signatures
  contractor_signature_id uuid REFERENCES signatures(id),
  customer_signature_id uuid REFERENCES signatures(id),
  contractor_signed_at timestamptz,
  customer_signed_at timestamptz,
  -- Status
  status text NOT NULL DEFAULT 'draft',
  -- CHECK (status IN ('draft', 'pending_signature', 'signed', 'submitted'))
  submitted_to_tpa_at timestamptz,
  -- Related forms
  lien_waiver_signed boolean DEFAULT false,
  satisfaction_survey_sent boolean DEFAULT false,
  -- PDF
  pdf_storage_path text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- T14: TPA Photo Requirements Tracking (links photos to documentation checklist)
CREATE TABLE tpa_photo_compliance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  tpa_assignment_id uuid NOT NULL REFERENCES tpa_assignments(id),
  photo_id uuid NOT NULL REFERENCES photos(id),
  -- Classification
  photo_phase text NOT NULL,
  -- CHECK (photo_phase IN ('before', 'during', 'after', 'equipment', 'moisture_reading', 'source', 'exterior', 'contents', 'pre_existing', 'thermal_imaging'))
  photo_type text, -- "equipment_placement", "damage_close_up", "wide_room", etc.
  room_name text,
  -- Metadata compliance
  has_timestamp boolean DEFAULT false,
  has_gps boolean DEFAULT false,
  -- TPA requirement link
  doc_requirement_id uuid REFERENCES tpa_doc_requirements(id),
  is_compliant boolean DEFAULT true,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- T15: Contents Inventory (pack-out, move, block tracking — 10-30% of water mitigation invoices)
CREATE TABLE contents_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  job_id uuid NOT NULL REFERENCES jobs(id),
  tpa_assignment_id uuid REFERENCES tpa_assignments(id),
  room_name text NOT NULL,
  item_description text NOT NULL,
  quantity integer DEFAULT 1,
  condition text,
  -- CHECK (condition IN ('undamaged', 'damaged', 'destroyed', 'salvageable', 'unknown'))
  action text NOT NULL,
  -- CHECK (action IN ('move_within_room', 'block_and_pad', 'pack_out', 'dispose', 'clean', 'no_action'))
  destination text, -- where moved to (storage, garage, another room)
  pre_loss_value numeric(10,2),
  photo_ids uuid[] DEFAULT '{}',
  notes text,
  packed_by uuid REFERENCES users(id),
  packed_at timestamptz,
  returned_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- T16: Equipment Warehouse Inventory (what's available vs deployed)
CREATE TABLE equipment_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  equipment_type text NOT NULL,
  -- CHECK (equipment_type IN ('dehumidifier_lgr', 'dehumidifier_conventional', 'dehumidifier_desiccant', 'air_mover', 'air_scrubber', 'negative_air_machine', 'hydroxyl_generator', 'ozone_generator', 'thermal_camera', 'moisture_meter', 'thermo_hygrometer', 'other'))
  name text NOT NULL, -- "Dri-Eaz LGR 7000XLi"
  serial_number text UNIQUE,
  asset_tag text, -- internal company tag
  aham_ppd numeric(6,1), -- dehu rating
  cfm_rating numeric(8,1), -- air mover/scrubber rating
  purchase_date date,
  purchase_price numeric(10,2),
  daily_rental_rate numeric(8,2), -- what contractor charges
  status text NOT NULL DEFAULT 'available',
  -- CHECK (status IN ('available', 'deployed', 'maintenance', 'retired', 'lost'))
  current_job_id uuid REFERENCES jobs(id), -- null if available
  current_deployment_id uuid REFERENCES equipment_deployments(id),
  last_maintenance_at timestamptz,
  next_maintenance_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

### Modifications to Existing Tables

```sql
-- Add TPA fields to jobs table
ALTER TABLE jobs ADD COLUMN tpa_assignment_id uuid REFERENCES tpa_assignments(id);
ALTER TABLE jobs ADD COLUMN tpa_program_id uuid REFERENCES tpa_programs(id);
ALTER TABLE jobs ADD COLUMN is_tpa_job boolean DEFAULT false;

-- Add TPA fields to estimates table (D8)
ALTER TABLE estimates ADD COLUMN tpa_assignment_id uuid REFERENCES tpa_assignments(id);
ALTER TABLE estimates ADD COLUMN supplement_number integer; -- null = original, 1 = S1, 2 = S2

-- Add company feature flag
ALTER TABLE companies ADD COLUMN features jsonb DEFAULT '{}';
-- features: { "tpa_enabled": false, "property_management_enabled": false, ... }
```

---

## D2 / D8 / TPA RECONCILIATION (CRITICAL — AVOID THREE PARALLEL SYSTEMS)

The existing codebase has overlapping insurance data structures that MUST be reconciled:

1. **D2 `insurance_claims`** — claim lifecycle, adjuster info, loss details (7 tables from S63-S64)
2. **D8 `estimates` + `estimate_line_items`** — full estimate engine with pricing, areas, line items (10 tables from S86-S89)
3. **TPA `tpa_assignments`** — TPA-specific assignment tracking, SLA, scoring (this spec)

**Resolution:**
- `tpa_assignments` layers ON TOP of `insurance_claims`. An insurance_claim exists for any insurance job. A tpa_assignment is optionally linked when that claim came through a TPA program.
- `tpa_assignments.claim_id` references `insurance_claims(id)` — assignment extends the claim, doesn't replace it.
- D8 `estimates` is THE estimate engine for all modes (regular + insurance + TPA). No separate estimate system.
- D2's `xactimate_estimate_lines` table is DEPRECATED in favor of D8's `estimate_line_items` with industry code mapping. During Phase T, migrate any xactimate_estimate_lines references to use estimate_line_items.
- D2's `moisture_readings`, `drying_logs`, `restoration_equipment` remain — TPA's new tables (T5/T7/T8) ENHANCE them with IICRC fields, not replace them.

---

## XACTIMATE INTEGRATION STRATEGY (REALISTIC)

**Day 1 (Launch):**
- PDF supplement output with Xactimate line item codes (Cat/Sel format). Contractor gives PDF to adjuster, adjuster enters into Xactimate manually. Zero legal risk. Works immediately.
- ESX import (reading contractor's own ESX files into ZAFTO). Already built.
- Multi-format estimate export: PDF, DOCX (via ZForge), FML (open format).

**Post-Traction (after proving market fit with real users):**
- Apply to Verisk Strategic Alliances for official ESX export + Xm8 API access.
- Apply as Third-Party Pricing partner (ZAFTO's pricing data feeds INTO Xactimate).
- Pre-revenue startup will NOT get approved. Need user base + revenue as leverage.
- Frame as "we help contractors use Xactimate better" — not "we replace Xactimate."

**Never:**
- No ESX workarounds. No disguised formats. No browser automation. Verisk controls Xactimate and can block anything.
- No Xactimate pricing copies. Our own pricing database from independent sources only.
- Xactimate checks .esx file extension — no alternative import path exists for structural line items.

**Key fact:** Xactimate pricing is NOT stored in ESX files. It applies the user's loaded regional price list on import. So if we eventually get ESX export, our files just need the right Cat/Sel codes and Xactimate auto-prices them. We never need to copy their pricing data.

---

## INTEGRATION WITH EXISTING FEATURES

### Jobs (existing)
- When TPA enabled + job type = insurance_claim: show TPA Program dropdown, Assignment Number, SLA deadlines
- SLA countdown badges on job cards (time remaining for first contact, estimate submission, etc.)
- Auto-calculate referral fee when job linked to TPA program
- "TPA" badge on job cards/lists (like existing type badges)

### Estimates (D8, existing — THE estimate system for TPA)
- Optional Xactimate code mapping column on line items (Cat/Sel reference for PDF output)
- Supplement workflow (S1, S2, S3 tracking via tpa_supplements table)
- O&P calculation (10 + 10 standard, configurable per TPA program)
- Export formats: PDF with Xactimate codes (Day 1), FML (open format), DOCX (ZForge)
- Import from ESX (read contractor's existing estimates — already built)
- ESX export: DEFERRED until Verisk partnership secured post-launch

### Field Tools (existing, contextual additions when TPA job)
- **Photos:** TPA phase tagging (before/during/after/equipment/moisture/source/thermal_imaging), auto-validate required photos against TPA checklist, **side-by-side before/after comparison view**
- **Moisture Readings (D2):** Enhanced with IICRC S500 format — location mapping, reference standards, daily tracking, drying goal tracking
- **Drying Logs (D2):** Enhanced with psychrometric data — temp, RH, GPP, dew point (indoor + outdoor + dehu). **GPP formula: Magnus approximation from temp + RH + atmospheric pressure**
- **Equipment Tracking (D2):** Billing clock (deployed_at → removed_at = billable days), IICRC placement calculator, serial number tracking, **warehouse inventory check** (what's available vs deployed)
- **Thermal Imaging:** Photo upload with thermal/FLIR camera images mapped to room locations alongside moisture readings
- **Contents Inventory:** Room-by-room item tracking (move, block, pack out, dispose) — billable service, 10-30% of water mitigation invoices
- **Daily Logs (B3a):** IICRC-compliant format with crew, hours, equipment status, psychrometric readings
- **Signatures (B2c):** Certificate of Completion signature flow
- **Sketch/Floor Plans (F4):** Connect sketch-bid tool to TPA documentation — room dimensions feed into equipment calculator and estimate areas

### Ledger (D4, existing)
- Per-TPA program P&L report (new report type)
- Referral fee auto-entry as expense when payment received
- Job cost tracking flows into TPA financial summary
- AR aging per TPA program

### Team Portal (existing)
- SLA countdown badges on assigned TPA jobs
- Documentation completeness indicator ("3 of 12 required photos uploaded")
- Equipment deployment quick-add from field

### Client Portal (existing)
- No TPA-specific changes. Homeowner sees projects/payments as usual.
- TPA internals are contractor-facing only.

### CRM Sidebar (existing)
- New collapsible "INSURANCE PROGRAMS" section (only when TPA enabled)
  - TPA Dashboard (overview of all programs)
  - Assignments (active TPA jobs)
  - Scorecards (performance tracking)
  - Program Settings (manage enrolled programs)

### Mobile App (existing)
- When TPA job selected: SLA countdown timer, documentation checklist overlay
- Equipment deployment screen: IICRC calculator, serial number entry, billing clock
- Moisture reading screen: enhanced with location mapping, reference standards
- Photo capture: auto-prompt for required TPA photos by phase

---

## WORKFLOWS (Matching Real Industry Workflows)

### Workflow 1: Water Mitigation TPA Job

**Step 1: Receive Assignment**
- Contractor manually enters assignment from TPA portal (no scraping)
- Fields: TPA program, assignment number, claim number, carrier, adjuster, policyholder info, loss type, loss date
- System auto-calculates SLA deadlines from program settings
- Creates job with type=insurance_claim, tpa_assignment linked

**Step 2: First Contact (SLA: program-defined, typically <2 hours)**
- Contractor calls homeowner, logs contact in assignment
- System records first_contact_at, checks against SLA deadline
- If deadline approaching: push notification to contractor + office

**Step 3: Initial Inspection**
- On-site assessment: source, category (1/2/3), class (1/2/3/4)
- Water damage assessment record created
- Moisture mapping: initial readings at all affected + reference locations
- Thermal imaging: FLIR photos mapped to rooms showing hidden moisture behind walls/ceilings
- Photo documentation: exterior, source, affected areas, pre-existing conditions
- Contents inventory: document items to move/block/pack out per room
- Documentation checklist auto-tracks: "6 of 12 initial inspection photos captured"

**Step 3.5: Emergency Services Authorization (ESA)**
- Request ESA from TPA/adjuster for emergency mitigation (typically $5K-$10K not-to-exceed)
- Log: amount, status (requested/approved/denied), approved_by, timestamp
- Work begins under ESA BEFORE full estimate is written — this is how real restoration works
- If no ESA required (e.g., direct carrier), skip to Step 4

**Step 4: Equipment Calculation & Placement**
- IICRC calculator: enter room dimensions + class → system calculates dehu/air mover/scrubber counts
- **Check warehouse inventory:** system shows available equipment vs what's needed
- Equipment deployment records: type, serial number, room, placement
- Billing clock starts at placed_at timestamp
- Photos: equipment in position with serial numbers visible

**Step 5: Preliminary Estimate (SLA: typically <24 hours after inspection)**
- Create estimate in ZAFTO estimate engine (D8 — THE estimate system)
- Map line items to restoration codes (with Xactimate Cat/Sel code reference for PDF output)
- Include contents manipulation charges (move, block, pack out from Step 3)
- Apply O&P calculation
- Submit: mark estimate_submitted_at in assignment

**Step 6: Daily Monitoring**
- Moisture readings: same mapped locations, MC values, compare to reference/goal
- Psychrometric log: indoor/outdoor temp+RH, dehu inlet/outlet, GPP calculation
  - GPP formula: Magnus approximation — Td = (b * alpha) / (a - alpha), where alpha = (a * T / (b + T)) + ln(RH/100)
  - Constants: a = 17.27, b = 237.7°C. GPP = 4354 / (Td + 459.67)
- Equipment check: all units operational, any moves/adjustments
- Photos: daily progress, equipment status, thermal imaging updates
- Daily log entry
- System auto-checks: "Day 3 monitoring complete. 2 of 8 locations at drying goal."
- **Category escalation check:** If conditions change (e.g., Cat 1 → Cat 2 after 48hrs, or sewage discovered):
  - System prompts for category reclassification
  - Auto-flags: new containment requirements, PPE upgrades, additional scope
  - Auto-creates supplement draft with additional line items for new category
  - New photos required documenting changed conditions

**Step 7: Drying Complete**
- All moisture readings at or below dry reference standard
- System validates: all locations reaching drying goal
- Equipment removal: update removed_at, calculate billable days, stop billing clock
- Photos: final readings, equipment removal, clean space

**Step 8: Supplement (if additional scope discovered)**
- Create supplement in ZAFTO (S1, S2, S3...)
- Document additional damage with photos + readings
- System tracks supplement status through workflow
- Link photos and line items to supplement

**Step 9: Certificate of Completion**
- Auto-generate COC from job data
- Customer signature capture (existing signature tool)
- Contractor signature
- PDF generation

**Step 10: Final Estimate & Closeout**
- Final estimate submitted (update final_estimate_submitted_at)
- Invoice generated (links to Ledger)
- Documentation package validated against TPA checklist
- System flags any missing items before "submit to TPA"
- Export: PDF with Xactimate codes (Day 1), FML floor plan (open format), full documentation package PDF
- Payment tracking: invoice amount, referral fee deduction, net payment, days outstanding
- **Payment aging alerts:** Auto-flag at 30/45/60/90 days overdue. Track followup count and dates.

---

## UI SPECS

### CRM: TPA Dashboard Page
- Program cards showing: name, status, active assignments count, avg score, avg cycle time
- Assignment pipeline: received → in progress → estimate submitted → payment pending → paid
- SLA violations this month (count + list)
- Financial summary: revenue, referral fees, net margin per program
- Alert badges: "3 assignments approaching SLA deadline"

### CRM: Assignments Page
- Table view with columns: Assignment #, Claim #, Carrier, Policyholder, Status, SLA Status, Amount
- Filter by: TPA program, status, loss type, SLA status (on track / at risk / violated)
- Status badges color-coded: green (on track), yellow (approaching), red (violated/overdue)
- Click → assignment detail (timeline view with all milestones and documentation status)

### CRM: Scorecards Page
- Select TPA program → see historical scores over time (line chart)
- Current period metrics with trend arrows
- Drill down into specific metrics
- Alert thresholds: contractor sets warning level, system alerts when approaching

### Mobile: TPA Job Overlay
- When a TPA job is selected, top banner shows:
  - TPA program name
  - Assignment # + Claim #
  - SLA countdown: "First contact: 1h 23m remaining" or "Estimate due: 18h remaining"
- Documentation checklist accessible via tab/button: shows required items by phase with completion status
- Equipment calculator: accessible from field tools

### Mobile: IICRC Equipment Calculator Screen
- Input: room dimensions (L x W x H), water class (1-4), dehu type (LGR/conventional/desiccant)
- Output: # dehumidifiers needed, # air movers needed (walls + floor + ceiling), # air scrubbers
- "Deploy" button creates equipment_deployment records
- Shows formula breakdown so contractor can justify to adjuster

### Mobile: Enhanced Moisture Reading Screen
- Grid/map view of room with numbered reading locations
- Each location: material type, today's reading, reference standard, trend (arrow up/down), at goal?
- Color coding: red (wet), yellow (drying), green (at goal)
- History: sparkline or chart showing reading over days
- "All Dry" validation: highlights when all locations at goal

---

## EDGE FUNCTIONS (3 new)

1. **tpa-equipment-calculator** — IICRC S500 equipment placement formulas. Input: room dimensions + class. Output: equipment counts + formula breakdown. Uses published IICRC calculation sheets.

2. **tpa-documentation-validator** — Given a job ID, checks all documentation against TPA program requirements. Returns: missing items, compliance percentage, deadline status.

3. **tpa-financial-rollup** — Monthly rollup of TPA program financials. Calculates revenue, referral fees, margins, AR aging, supplement performance per program.

---

## SEED DATA

### Default Restoration Line Items (ZAFTO's own codes, ~50 initial items)
Category groups: Water Extraction, Demolition, Drying Equipment, Cleaning/Treatment, Monitoring, Contents, Hazmat, Temporary Repairs, Reconstruction

### Default TPA Documentation Templates
- Water Mitigation checklist (20+ items across 5 phases)
- Fire Restoration checklist
- Mold Remediation checklist
- Roofing Claim checklist

### IICRC Equipment Chart Factors
- Class 1-4 factors for LGR, conventional, and desiccant dehumidifiers
- Air mover placement ratios

---

## BUILD ORDER (within Phase T)

### Sprint T1: Foundation (~8 hours)
- [ ] Migration: tpa_programs, tpa_assignments, tpa_scorecards tables + RLS
- [ ] Migration: companies.features JSONB column
- [ ] CRM: TPA settings page (manage programs)
- [ ] CRM hook: use-tpa-programs.ts
- [ ] Feature flag: conditionally show TPA sidebar section

### Sprint T2: Assignment Tracking (~12 hours)
- [ ] Migration: tpa_supplements, tpa_doc_requirements, tpa_photo_compliance tables + RLS
- [ ] CRM: Assignments page + detail view
- [ ] CRM hook: use-tpa-assignments.ts
- [ ] CRM: Assignment create/edit (manual entry from TPA portal)
- [ ] Job integration: tpa_assignment_id + tpa_program_id fields on jobs
- [ ] SLA deadline auto-calculation + countdown display

### Sprint T3: Water Damage Assessment + Moisture (~12 hours)
- [ ] Migration: water_damage_assessments, moisture_readings, psychrometric_logs tables + RLS
- [ ] Mobile: Water damage assessment screen (category/class picker)
- [ ] Mobile: Enhanced moisture reading screen (location mapping, reference standards, drying goals)
- [ ] Mobile: Psychrometric log entry (temp, RH, auto-calculate GPP/dew point)
- [ ] CRM hook: use-moisture-readings.ts
- [ ] CRM: Moisture/drying monitoring page (view readings over time per job)

### Sprint T4: Equipment Deployment + Calculator (~10 hours)
- [ ] Migration: equipment_deployments, equipment_calculations tables + RLS
- [ ] Edge Function: tpa-equipment-calculator (IICRC formulas)
- [ ] Mobile: Equipment calculator screen
- [ ] Mobile: Equipment deployment screen (place/remove with billing clock)
- [ ] CRM hook: use-equipment-deployments.ts
- [ ] CRM: Equipment deployment tracking on job detail

### Sprint T5: Documentation Validation (~8 hours)
- [ ] Migration: certificates_of_completion table + RLS
- [ ] Edge Function: tpa-documentation-validator
- [ ] Mobile: Documentation checklist overlay on TPA jobs
- [ ] CRM: Documentation completeness dashboard
- [ ] Seed: Default TPA documentation checklists (water, fire, mold, roofing)
- [ ] Photo phase tagging on photo upload (before/during/after/equipment/moisture/source)

### Sprint T6: Financial Analytics (~8 hours)
- [ ] Migration: tpa_program_financials table + RLS
- [ ] Edge Function: tpa-financial-rollup
- [ ] CRM: TPA Dashboard page (program cards, pipeline, financials)
- [ ] CRM hook: use-tpa-financials.ts
- [ ] CRM: Per-TPA P&L report (integrates with Ledger data)
- [ ] Referral fee auto-calculation on job close

### Sprint T7: Supplement Workflow + Scorecard (~8 hours)
- [ ] CRM: Supplement tracking UI (create, submit, track status, link photos)
- [ ] CRM hook: use-tpa-supplements.ts
- [ ] CRM: Scorecards page (enter/view scores, trend charts, alert thresholds)
- [ ] CRM hook: use-tpa-scorecards.ts
- [ ] Mobile: Supplement discovery workflow (flag additional scope from field)

### Sprint T8: Line Item Database + Export (~10 hours)
- [ ] Migration: restoration_line_items table + seed data (~50 initial items)
- [ ] Estimate engine integration: Xactimate code mapping column
- [ ] FML floor plan export (open format, Symbility-compatible)
- [ ] DXF floor plan export (universal CAD)
- [ ] PDF documentation package export (photos + readings + logs + estimate)
- [ ] ESX import capability (read contractor's ESX files into ZAFTO)

### Sprint T9: Portal Integration (~8 hours)
- [ ] Team Portal: SLA badges on TPA jobs, documentation checklist, equipment deployment
- [ ] Team Portal hooks: use-tpa-jobs.ts, use-equipment.ts
- [ ] Ops Portal: TPA analytics page (assignment volume, SLA compliance, program performance across all companies)
- [ ] CRM sidebar: INSURANCE PROGRAMS section (conditional on features.tpa_enabled)

### Sprint T10: Polish + Build Verification (~4 hours)
- [ ] All portals build clean
- [ ] Mobile: dart analyze passes
- [ ] Feature flag toggle: verify TPA UI hidden when disabled
- [ ] Documentation checklist validation end-to-end test
- [ ] IICRC calculator accuracy verification against published formulas

---

## ESTIMATED TOTALS

- **~15 new tables**
- **3 Edge Functions**
- **~10 CRM pages/routes**
- **~5 mobile screens (enhanced existing + new)**
- **~3 team portal pages**
- **~1 ops portal page**
- **~10 hooks**
- **~80 hours total**

---

## LEGAL DISCLAIMERS TO INCLUDE IN UI

1. Footer on any page referencing TPA names:
   "ZAFTO is not affiliated with, endorsed by, or sponsored by any TPA program, insurance carrier, or claims management company listed. All trademarks are property of their respective owners."

2. Estimate engine:
   "Estimates generated by ZAFTO represent the contractor's scope of work and pricing. They are not insurance claim estimates or adjustments."

3. IICRC references:
   "Equipment calculations are based on publicly available IICRC formulas. For authoritative guidance, refer to the current IICRC S500/S520/S700 standards."

4. Xactimate references (when ESX export ships):
   "Xactimate(R) is a registered trademark of Xactware Solutions, Inc., a Verisk business. ZAFTO is not affiliated with or endorsed by Xactware or Verisk."
