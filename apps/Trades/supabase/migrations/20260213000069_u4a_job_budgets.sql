-- U4a: Job Budgets for Budget vs Actual Reporting
-- Sprint U4, Session 110

-- Job budgets: line-item budgets per job per category
CREATE TABLE IF NOT EXISTS job_budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('materials', 'labor', 'equipment', 'subcontractor', 'permits', 'overhead', 'other')),
  description TEXT,
  budgeted_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_job_budgets_company ON job_budgets(company_id);
CREATE INDEX idx_job_budgets_job ON job_budgets(job_id);
CREATE INDEX idx_job_budgets_job_category ON job_budgets(job_id, category);

-- Enable RLS
ALTER TABLE job_budgets ENABLE ROW LEVEL SECURITY;

-- RLS policies (company-scoped)
CREATE POLICY "job_budgets_select" ON job_budgets FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "job_budgets_insert" ON job_budgets FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "job_budgets_update" ON job_budgets FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "job_budgets_delete" ON job_budgets FOR DELETE USING (company_id = requesting_company_id());

-- Updated_at trigger
CREATE TRIGGER update_job_budgets_updated_at
  BEFORE UPDATE ON job_budgets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit trigger
CREATE TRIGGER job_budgets_audit
  AFTER INSERT OR UPDATE OR DELETE ON job_budgets
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
