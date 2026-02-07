-- D4p: Enterprise Construction Accounting Tables
-- Progress Billing (AIA G702/G703) + Retention Tracking

-- ============================================================
-- 1. progress_billings — AIA G702/G703 Application for Payment
-- ============================================================
CREATE TABLE IF NOT EXISTS progress_billings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  application_number INTEGER NOT NULL,
  billing_period_start DATE NOT NULL,
  billing_period_end DATE NOT NULL,
  contract_amount NUMERIC(12,2) NOT NULL,
  change_orders_amount NUMERIC(12,2) DEFAULT 0,
  revised_contract NUMERIC(12,2) NOT NULL,
  schedule_of_values JSONB NOT NULL DEFAULT '[]'::jsonb,
  total_completed_to_date NUMERIC(12,2) DEFAULT 0,
  total_retainage NUMERIC(12,2) DEFAULT 0,
  less_previous_applications NUMERIC(12,2) DEFAULT 0,
  current_payment_due NUMERIC(12,2) DEFAULT 0,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'paid')),
  submitted_at TIMESTAMPTZ,
  approved_by TEXT,
  approved_at TIMESTAMPTZ,
  journal_entry_id UUID REFERENCES journal_entries(id),
  created_by_user_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Unique constraint: one application number per job
ALTER TABLE progress_billings ADD CONSTRAINT uq_progress_billing_job_app
  UNIQUE (company_id, job_id, application_number);

-- RLS
ALTER TABLE progress_billings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company members can view progress billings"
  ON progress_billings FOR SELECT
  USING (company_id IN (
    SELECT (raw_app_meta_data->>'company_id')::uuid FROM auth.users WHERE id = auth.uid()
  ));

CREATE POLICY "Company members can insert progress billings"
  ON progress_billings FOR INSERT
  WITH CHECK (company_id IN (
    SELECT (raw_app_meta_data->>'company_id')::uuid FROM auth.users WHERE id = auth.uid()
  ));

CREATE POLICY "Company members can update progress billings"
  ON progress_billings FOR UPDATE
  USING (company_id IN (
    SELECT (raw_app_meta_data->>'company_id')::uuid FROM auth.users WHERE id = auth.uid()
  ));

-- ============================================================
-- 2. retention_tracking — Retainage per job
-- ============================================================
CREATE TABLE IF NOT EXISTS retention_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  retention_rate NUMERIC(5,2) NOT NULL DEFAULT 10.00,
  total_billed NUMERIC(12,2) DEFAULT 0,
  total_retained NUMERIC(12,2) DEFAULT 0,
  total_released NUMERIC(12,2) DEFAULT 0,
  balance_held NUMERIC(12,2) DEFAULT 0,
  release_conditions TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'partially_released', 'fully_released')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- One retention record per job
ALTER TABLE retention_tracking ADD CONSTRAINT uq_retention_tracking_job
  UNIQUE (company_id, job_id);

-- RLS
ALTER TABLE retention_tracking ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company members can view retention tracking"
  ON retention_tracking FOR SELECT
  USING (company_id IN (
    SELECT (raw_app_meta_data->>'company_id')::uuid FROM auth.users WHERE id = auth.uid()
  ));

CREATE POLICY "Company members can insert retention tracking"
  ON retention_tracking FOR INSERT
  WITH CHECK (company_id IN (
    SELECT (raw_app_meta_data->>'company_id')::uuid FROM auth.users WHERE id = auth.uid()
  ));

CREATE POLICY "Company members can update retention tracking"
  ON retention_tracking FOR UPDATE
  USING (company_id IN (
    SELECT (raw_app_meta_data->>'company_id')::uuid FROM auth.users WHERE id = auth.uid()
  ));

-- Indexes
CREATE INDEX IF NOT EXISTS idx_progress_billings_job ON progress_billings(job_id);
CREATE INDEX IF NOT EXISTS idx_progress_billings_company ON progress_billings(company_id);
CREATE INDEX IF NOT EXISTS idx_progress_billings_status ON progress_billings(status);
CREATE INDEX IF NOT EXISTS idx_retention_tracking_job ON retention_tracking(job_id);
CREATE INDEX IF NOT EXISTS idx_retention_tracking_company ON retention_tracking(company_id);
