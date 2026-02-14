-- J1: Job Cost Autopsy Foundation
-- Job profitability analysis, autopsy insights, and estimate adjustments

-- ══════════════════════════════════════════════════════════
-- job_cost_autopsies — per-job actual vs estimated cost breakdown
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS job_cost_autopsies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),

  -- Estimated (snapshot from estimate at time of job creation)
  estimated_labor_hours NUMERIC(8,2),
  estimated_labor_cost NUMERIC(10,2),
  estimated_material_cost NUMERIC(10,2),
  estimated_total NUMERIC(10,2),

  -- Actual (calculated from time_entries, receipts, mileage)
  actual_labor_hours NUMERIC(8,2),
  actual_labor_cost NUMERIC(10,2),
  actual_material_cost NUMERIC(10,2),
  actual_drive_time_hours NUMERIC(6,2) DEFAULT 0,
  actual_drive_cost NUMERIC(8,2) DEFAULT 0,
  actual_callbacks INT DEFAULT 0,
  actual_change_order_cost NUMERIC(10,2) DEFAULT 0,
  actual_total NUMERIC(10,2),

  -- Profitability
  revenue NUMERIC(10,2),
  gross_profit NUMERIC(10,2),
  gross_margin_pct NUMERIC(5,2),
  variance_pct NUMERIC(5,2),  -- (actual - estimated) / estimated * 100

  -- Metadata
  job_type TEXT,
  trade_type TEXT,
  primary_tech_id UUID REFERENCES users(id),
  completed_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,

  CONSTRAINT unique_job_autopsy UNIQUE(job_id)
);

ALTER TABLE job_cost_autopsies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company members read own autopsies"
  ON job_cost_autopsies FOR SELECT
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "Company members insert autopsies"
  ON job_cost_autopsies FOR INSERT
  WITH CHECK (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "Company members update own autopsies"
  ON job_cost_autopsies FOR UPDATE
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "Company members delete own autopsies"
  ON job_cost_autopsies FOR DELETE
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE INDEX idx_autopsies_company ON job_cost_autopsies(company_id);
CREATE INDEX idx_autopsies_job ON job_cost_autopsies(job_id);
CREATE INDEX idx_autopsies_job_type ON job_cost_autopsies(job_type);
CREATE INDEX idx_autopsies_trade_type ON job_cost_autopsies(trade_type);
CREATE INDEX idx_autopsies_completed ON job_cost_autopsies(completed_at);
CREATE INDEX idx_autopsies_margin ON job_cost_autopsies(gross_margin_pct);

CREATE TRIGGER update_job_cost_autopsies_updated_at
  BEFORE UPDATE ON job_cost_autopsies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER job_cost_autopsies_audit
  AFTER INSERT OR UPDATE OR DELETE ON job_cost_autopsies
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ══════════════════════════════════════════════════════════
-- autopsy_insights — aggregated intelligence from autopsies
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS autopsy_insights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  insight_type TEXT NOT NULL CHECK (insight_type IN (
    'profitability_by_job_type', 'profitability_by_tech', 'profitability_by_season',
    'variance_trend', 'callback_rate', 'top_performers', 'underperforming_types',
    'material_overrun_pattern', 'labor_overrun_pattern'
  )),
  insight_key TEXT NOT NULL,            -- e.g., 'hvac_install', 'tech_abc123', 'Q1_2026'
  insight_data JSONB NOT NULL,          -- flexible data per insight type
  sample_size INT NOT NULL DEFAULT 0,
  confidence_score NUMERIC(3,2) DEFAULT 0.5 CHECK (confidence_score BETWEEN 0 AND 1),
  period_start DATE,
  period_end DATE,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE autopsy_insights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company members read own insights"
  ON autopsy_insights FOR SELECT
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "Company members manage insights"
  ON autopsy_insights FOR ALL
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE INDEX idx_insights_company ON autopsy_insights(company_id);
CREATE INDEX idx_insights_type ON autopsy_insights(insight_type);
CREATE INDEX idx_insights_key ON autopsy_insights(insight_key);

CREATE TRIGGER update_autopsy_insights_updated_at
  BEFORE UPDATE ON autopsy_insights
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
-- estimate_adjustments — suggested pricing corrections
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS estimate_adjustments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_type TEXT NOT NULL,
  trade_type TEXT,
  adjustment_type TEXT NOT NULL CHECK (adjustment_type IN (
    'labor_hours_multiplier', 'material_cost_multiplier', 'total_cost_multiplier',
    'flat_add_labor', 'flat_add_material', 'drive_time_add'
  )),
  suggested_multiplier NUMERIC(5,3),    -- e.g., 1.15 = 15% increase
  suggested_flat_amount NUMERIC(10,2),  -- for flat adjustments
  based_on_jobs INT NOT NULL DEFAULT 0,
  avg_variance_pct NUMERIC(5,2),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'dismissed', 'applied')),
  applied_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE estimate_adjustments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company members read own adjustments"
  ON estimate_adjustments FOR SELECT
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "Company members manage adjustments"
  ON estimate_adjustments FOR ALL
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE INDEX idx_adjustments_company ON estimate_adjustments(company_id);
CREATE INDEX idx_adjustments_job_type ON estimate_adjustments(job_type);
CREATE INDEX idx_adjustments_status ON estimate_adjustments(status);

CREATE TRIGGER update_estimate_adjustments_updated_at
  BEFORE UPDATE ON estimate_adjustments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER estimate_adjustments_audit
  AFTER INSERT OR UPDATE OR DELETE ON estimate_adjustments
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
