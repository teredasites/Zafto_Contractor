-- ============================================================
-- ZAFTO CORE SCHEMA — B4c: Leads Table
-- Sprint B4c | Session 51
--
-- Run against: dev first, then prod
-- Tables: leads
-- Depends on: A3a (companies, users)
-- ============================================================

CREATE TABLE leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  assigned_to_user_id uuid REFERENCES auth.users(id),
  name text NOT NULL,
  email text,
  phone text,
  company_name text,
  source text DEFAULT 'website' CHECK (source IN ('website', 'referral', 'google', 'yelp', 'facebook', 'instagram', 'nextdoor', 'homeadvisor', 'other')),
  stage text DEFAULT 'new' CHECK (stage IN ('new', 'contacted', 'qualified', 'proposal', 'won', 'lost')),
  value numeric(12,2) DEFAULT 0,
  notes text,
  address text,
  city text,
  state text,
  zip_code text,
  last_contacted_at timestamptz,
  next_follow_up timestamptz,
  won_at timestamptz,
  lost_at timestamptz,
  lost_reason text,
  converted_to_job_id uuid REFERENCES jobs(id),
  tags text[] DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_leads_company_stage ON leads (company_id, stage);
CREATE INDEX idx_leads_follow_up ON leads (company_id, next_follow_up) WHERE next_follow_up IS NOT NULL;
CREATE INDEX idx_leads_assigned ON leads (assigned_to_user_id) WHERE assigned_to_user_id IS NOT NULL;

CREATE TRIGGER leads_updated_at BEFORE UPDATE ON leads FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER leads_audit AFTER INSERT OR UPDATE OR DELETE ON leads FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "leads_select" ON leads FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "leads_insert" ON leads FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "leads_update" ON leads FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "leads_delete" ON leads FOR DELETE USING (company_id = requesting_company_id());
