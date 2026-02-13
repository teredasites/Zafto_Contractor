-- T1a: TPA Foundation — Programs, Assignments, Scorecards
-- Phase T (Programs/TPA Module) — Sprint T1
-- Core tables for Third-Party Administrator insurance program management

-- ============================================================================
-- TABLES
-- ============================================================================

-- TPA Programs — company enrollments in TPA networks (Contractor Connection, Accuserve, etc.)
CREATE TABLE tpa_programs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  created_by_user_id UUID REFERENCES auth.users(id),
  -- Program identity
  name TEXT NOT NULL,  -- e.g., "Contractor Connection", "Accuserve", "Sedgwick"
  tpa_type TEXT NOT NULL DEFAULT 'national' CHECK (tpa_type IN ('national','regional','carrier_direct','independent')),
  carrier_names TEXT[] DEFAULT '{}',  -- carriers served by this TPA
  -- Financial terms
  referral_fee_type TEXT DEFAULT 'percentage' CHECK (referral_fee_type IN ('percentage','flat','tiered','none')),
  referral_fee_pct NUMERIC(5,2),  -- e.g., 3.00 = 3%
  referral_fee_flat NUMERIC(10,2),  -- flat fee per job
  payment_terms_days INTEGER DEFAULT 30,
  overhead_pct NUMERIC(5,2) DEFAULT 10.00,  -- O&P overhead percentage
  profit_pct NUMERIC(5,2) DEFAULT 10.00,  -- O&P profit percentage
  -- SLA thresholds (in minutes)
  sla_first_contact_minutes INTEGER DEFAULT 120,  -- 2 hours
  sla_onsite_minutes INTEGER DEFAULT 1440,  -- 24 hours
  sla_estimate_minutes INTEGER DEFAULT 1440,  -- 24 hours
  sla_completion_days INTEGER DEFAULT 5,  -- 5 business days for standard mitigation
  -- Portal access (manual entry only — never scrape/automate)
  portal_url TEXT,
  portal_username TEXT,
  -- Contacts
  primary_contact_name TEXT,
  primary_contact_phone TEXT,
  primary_contact_email TEXT,
  secondary_contact_name TEXT,
  secondary_contact_phone TEXT,
  secondary_contact_email TEXT,
  -- Program details
  service_area TEXT,  -- geographic coverage description
  trade_categories TEXT[] DEFAULT '{}',  -- which trades this program covers
  loss_types_covered TEXT[] DEFAULT '{}',  -- water, fire, mold, storm, etc.
  notes TEXT,
  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active','inactive','suspended','pending_approval')),
  enrolled_at TIMESTAMPTZ,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- TPA Assignments — individual dispatched jobs from TPA programs
CREATE TABLE tpa_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  tpa_program_id UUID NOT NULL REFERENCES tpa_programs(id),
  job_id UUID REFERENCES jobs(id),
  created_by_user_id UUID REFERENCES auth.users(id),
  -- Assignment identifiers
  assignment_number TEXT,  -- TPA-provided assignment ID
  claim_number TEXT,
  policy_number TEXT,
  -- Carrier / adjuster
  carrier_name TEXT,
  adjuster_name TEXT,
  adjuster_phone TEXT,
  adjuster_email TEXT,
  -- Policyholder (homeowner)
  policyholder_name TEXT,
  policyholder_phone TEXT,
  policyholder_email TEXT,
  -- Property
  property_address TEXT,
  property_city TEXT,
  property_state TEXT,
  property_zip TEXT,
  -- Loss details
  loss_type TEXT CHECK (loss_type IN ('water','fire','smoke','mold','storm','wind','hail','flood','vandalism','theft','biohazard','other')),
  loss_date TIMESTAMPTZ,
  loss_description TEXT,
  -- SLA tracking (auto-calculated from program settings at creation)
  assigned_at TIMESTAMPTZ DEFAULT now(),
  first_contact_deadline TIMESTAMPTZ,
  onsite_deadline TIMESTAMPTZ,
  estimate_deadline TIMESTAMPTZ,
  completion_deadline TIMESTAMPTZ,
  -- SLA actuals (logged when milestones are met)
  first_contact_at TIMESTAMPTZ,
  onsite_at TIMESTAMPTZ,
  estimate_submitted_at TIMESTAMPTZ,
  work_started_at TIMESTAMPTZ,
  work_completed_at TIMESTAMPTZ,
  -- Emergency Services Authorization
  esa_requested BOOLEAN DEFAULT false,
  esa_authorized BOOLEAN DEFAULT false,
  esa_authorized_at TIMESTAMPTZ,
  esa_amount NUMERIC(12,2),
  esa_notes TEXT,
  -- Status workflow
  status TEXT DEFAULT 'received' CHECK (status IN (
    'received','contacted','scheduled','onsite','inspecting',
    'estimate_pending','estimate_submitted','approved',
    'in_progress','supplement_pending','supplement_submitted',
    'drying','monitoring','completed','closed',
    'declined','cancelled','reassigned'
  )),
  -- Financial summary
  referral_fee_amount NUMERIC(10,2),
  total_estimated NUMERIC(12,2) DEFAULT 0,
  total_invoiced NUMERIC(12,2) DEFAULT 0,
  total_collected NUMERIC(12,2) DEFAULT 0,
  total_supplements NUMERIC(12,2) DEFAULT 0,
  -- Payment aging
  payment_due_date TIMESTAMPTZ,
  last_payment_followup_at TIMESTAMPTZ,
  payment_followup_count INTEGER DEFAULT 0,
  -- TPA scoring (contractor's performance on this assignment)
  tpa_score NUMERIC(5,2),
  customer_satisfaction_score NUMERIC(5,2),
  -- Metadata
  internal_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- TPA Scorecards — periodic performance scores per TPA program
CREATE TABLE tpa_scorecards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  tpa_program_id UUID NOT NULL REFERENCES tpa_programs(id),
  -- Scoring period
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  -- Score categories (0-100 scale)
  response_time_score NUMERIC(5,2),
  cycle_time_score NUMERIC(5,2),
  customer_satisfaction_score NUMERIC(5,2),
  documentation_score NUMERIC(5,2),
  estimate_accuracy_score NUMERIC(5,2),
  supplement_rate_score NUMERIC(5,2),
  sla_compliance_score NUMERIC(5,2),
  overall_score NUMERIC(5,2),
  -- Volume metrics
  total_assignments INTEGER DEFAULT 0,
  assignments_completed INTEGER DEFAULT 0,
  sla_violations INTEGER DEFAULT 0,
  average_cycle_days NUMERIC(6,2),
  -- Context
  notes TEXT,
  source TEXT DEFAULT 'manual' CHECK (source IN ('manual','imported','calculated')),
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  -- Prevent duplicate scorecards for same program+period
  UNIQUE(company_id, tpa_program_id, period_start, period_end)
);

-- ============================================================================
-- ALTER EXISTING TABLES
-- ============================================================================

-- Companies: feature flag system for optional modules
ALTER TABLE companies ADD COLUMN IF NOT EXISTS features JSONB DEFAULT '{}'::jsonb;

-- Jobs: TPA linkage columns
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS tpa_assignment_id UUID REFERENCES tpa_assignments(id);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS tpa_program_id UUID REFERENCES tpa_programs(id);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_tpa_job BOOLEAN DEFAULT false;

-- Estimates: TPA supplement tracking
ALTER TABLE estimates ADD COLUMN IF NOT EXISTS tpa_assignment_id UUID REFERENCES tpa_assignments(id);
ALTER TABLE estimates ADD COLUMN IF NOT EXISTS supplement_number INTEGER;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE tpa_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE tpa_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tpa_scorecards ENABLE ROW LEVEL SECURITY;

CREATE POLICY tpa_programs_company ON tpa_programs
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY tpa_assignments_company ON tpa_assignments
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY tpa_scorecards_company ON tpa_scorecards
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- tpa_programs
CREATE INDEX idx_tpa_programs_company ON tpa_programs(company_id);
CREATE INDEX idx_tpa_programs_status ON tpa_programs(status) WHERE deleted_at IS NULL;

-- tpa_assignments
CREATE INDEX idx_tpa_assignments_company ON tpa_assignments(company_id);
CREATE INDEX idx_tpa_assignments_program ON tpa_assignments(tpa_program_id);
CREATE INDEX idx_tpa_assignments_job ON tpa_assignments(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX idx_tpa_assignments_status ON tpa_assignments(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_tpa_assignments_claim ON tpa_assignments(claim_number) WHERE claim_number IS NOT NULL;
CREATE INDEX idx_tpa_assignments_sla_contact ON tpa_assignments(first_contact_deadline) WHERE first_contact_at IS NULL AND status = 'received';
CREATE INDEX idx_tpa_assignments_sla_onsite ON tpa_assignments(onsite_deadline) WHERE onsite_at IS NULL AND status IN ('received','contacted','scheduled');
CREATE INDEX idx_tpa_assignments_payment ON tpa_assignments(payment_due_date) WHERE total_collected < total_invoiced AND deleted_at IS NULL;

-- tpa_scorecards
CREATE INDEX idx_tpa_scorecards_company ON tpa_scorecards(company_id);
CREATE INDEX idx_tpa_scorecards_program ON tpa_scorecards(tpa_program_id);
CREATE INDEX idx_tpa_scorecards_period ON tpa_scorecards(period_start, period_end);

-- ALTERed columns on existing tables
CREATE INDEX idx_jobs_tpa_assignment ON jobs(tpa_assignment_id) WHERE tpa_assignment_id IS NOT NULL;
CREATE INDEX idx_jobs_tpa_program ON jobs(tpa_program_id) WHERE tpa_program_id IS NOT NULL;
CREATE INDEX idx_jobs_is_tpa ON jobs(is_tpa_job) WHERE is_tpa_job = true;
CREATE INDEX idx_estimates_tpa_assignment ON estimates(tpa_assignment_id) WHERE tpa_assignment_id IS NOT NULL;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- updated_at auto-update
CREATE TRIGGER tpa_programs_updated BEFORE UPDATE ON tpa_programs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tpa_assignments_updated BEFORE UPDATE ON tpa_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tpa_scorecards_updated BEFORE UPDATE ON tpa_scorecards FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit trail on all TPA business tables
CREATE TRIGGER tpa_programs_audit AFTER INSERT OR UPDATE OR DELETE ON tpa_programs FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER tpa_assignments_audit AFTER INSERT OR UPDATE OR DELETE ON tpa_assignments FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER tpa_scorecards_audit AFTER INSERT OR UPDATE OR DELETE ON tpa_scorecards FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
