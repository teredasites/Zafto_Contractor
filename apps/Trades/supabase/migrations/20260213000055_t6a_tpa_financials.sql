-- T6a: TPA Financial Analytics — Monthly rollup per program
-- Phase T (Programs/TPA Module) — Sprint T6
-- Per-TPA profitability, referral fee tracking, AR aging, supplement performance

-- ============================================================================
-- TABLE: TPA PROGRAM FINANCIALS — Monthly rollup
-- ============================================================================

CREATE TABLE tpa_program_financials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  tpa_program_id UUID NOT NULL REFERENCES tpa_programs(id),
  -- Period
  period_month INTEGER NOT NULL CHECK (period_month BETWEEN 1 AND 12),
  period_year INTEGER NOT NULL CHECK (period_year >= 2020),
  -- Assignment counts
  assignments_received INTEGER DEFAULT 0,
  assignments_completed INTEGER DEFAULT 0,
  assignments_declined INTEGER DEFAULT 0,
  assignments_in_progress INTEGER DEFAULT 0,
  -- Revenue
  gross_revenue NUMERIC(12,2) DEFAULT 0,
  supplement_revenue NUMERIC(12,2) DEFAULT 0,
  total_revenue NUMERIC(12,2) DEFAULT 0,
  -- Costs
  labor_cost NUMERIC(12,2) DEFAULT 0,
  material_cost NUMERIC(12,2) DEFAULT 0,
  equipment_cost NUMERIC(12,2) DEFAULT 0,
  subcontractor_cost NUMERIC(12,2) DEFAULT 0,
  referral_fees_paid NUMERIC(12,2) DEFAULT 0,
  total_cost NUMERIC(12,2) DEFAULT 0,
  -- Margins
  gross_margin NUMERIC(12,2) DEFAULT 0,
  gross_margin_percent NUMERIC(5,2) DEFAULT 0,
  net_margin NUMERIC(12,2) DEFAULT 0,
  net_margin_percent NUMERIC(5,2) DEFAULT 0,
  -- AR aging
  ar_current NUMERIC(12,2) DEFAULT 0,  -- 0-30 days
  ar_30_day NUMERIC(12,2) DEFAULT 0,   -- 31-60 days
  ar_60_day NUMERIC(12,2) DEFAULT 0,   -- 61-90 days
  ar_90_plus NUMERIC(12,2) DEFAULT 0,  -- 90+ days
  avg_payment_days INTEGER DEFAULT 0,
  -- Supplement performance
  supplements_submitted INTEGER DEFAULT 0,
  supplements_approved INTEGER DEFAULT 0,
  supplements_denied INTEGER DEFAULT 0,
  supplement_approval_rate NUMERIC(5,2) DEFAULT 0,
  avg_supplement_amount NUMERIC(10,2) DEFAULT 0,
  -- Scoring
  avg_scorecard_rating NUMERIC(4,2),
  sla_violations_count INTEGER DEFAULT 0,
  avg_cycle_time_days NUMERIC(6,1) DEFAULT 0,
  -- Metadata
  calculated_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  -- Unique constraint: one record per program per month
  UNIQUE (company_id, tpa_program_id, period_year, period_month)
);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE tpa_program_financials ENABLE ROW LEVEL SECURITY;

CREATE POLICY tpa_financials_company ON tpa_program_financials
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_tpa_fin_company ON tpa_program_financials(company_id);
CREATE INDEX idx_tpa_fin_program ON tpa_program_financials(tpa_program_id);
CREATE INDEX idx_tpa_fin_period ON tpa_program_financials(period_year, period_month);
CREATE INDEX idx_tpa_fin_company_period ON tpa_program_financials(company_id, period_year, period_month);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER tpa_financials_updated BEFORE UPDATE ON tpa_program_financials FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tpa_financials_audit AFTER INSERT OR UPDATE OR DELETE ON tpa_program_financials FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
