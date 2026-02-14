-- U7c: Stripe Connect + Review Requests + Automation Executions + System Health

-- ══════════════════════════════════════════════
-- STRIPE CONNECT — add columns to companies
-- ══════════════════════════════════════════════
ALTER TABLE companies ADD COLUMN IF NOT EXISTS stripe_account_id text;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS stripe_connect_status text DEFAULT 'not_connected'
  CHECK (stripe_connect_status IN ('not_connected', 'onboarding_incomplete', 'active', 'restricted', 'disabled'));
ALTER TABLE companies ADD COLUMN IF NOT EXISTS stripe_connect_onboarded_at timestamptz;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS review_settings jsonb DEFAULT '{}';
-- review_settings: { enabled, delay_days, default_channel, google_review_url, yelp_review_url,
--   facebook_review_url, auto_send, minimum_rating_to_request, template_sms, template_email }

-- ══════════════════════════════════════════════
-- REVIEW REQUESTS
-- ══════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS review_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  customer_id uuid REFERENCES customers(id),
  created_by uuid REFERENCES auth.users(id),
  channel text NOT NULL DEFAULT 'email' CHECK (channel IN ('sms', 'email', 'both')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'opened', 'completed', 'skipped', 'failed')),
  review_platform text DEFAULT 'google' CHECK (review_platform IN ('google', 'yelp', 'facebook', 'custom')),
  review_url text,
  rating_received integer CHECK (rating_received IS NULL OR (rating_received >= 1 AND rating_received <= 5)),
  feedback_text text,
  sent_at timestamptz,
  opened_at timestamptz,
  completed_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE review_requests ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_review_requests_company ON review_requests (company_id);
CREATE INDEX idx_review_requests_customer ON review_requests (customer_id);
CREATE INDEX idx_review_requests_status ON review_requests (company_id, status);
CREATE TRIGGER review_requests_updated_at BEFORE UPDATE ON review_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER review_requests_audit AFTER INSERT OR UPDATE OR DELETE ON review_requests FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "review_requests_select" ON review_requests FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "review_requests_insert" ON review_requests FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "review_requests_update" ON review_requests FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "review_requests_delete" ON review_requests FOR DELETE USING (company_id = requesting_company_id());

-- ══════════════════════════════════════════════
-- AUTOMATION EXECUTIONS (immutable log)
-- ══════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS automation_executions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  automation_id uuid NOT NULL REFERENCES automations(id) ON DELETE CASCADE,
  trigger_event jsonb NOT NULL DEFAULT '{}',
  actions_executed jsonb NOT NULL DEFAULT '[]',
  status text NOT NULL DEFAULT 'success' CHECK (status IN ('success', 'partial', 'failed')),
  error_message text,
  executed_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE automation_executions ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_automation_executions_company ON automation_executions (company_id);
CREATE INDEX idx_automation_executions_automation ON automation_executions (automation_id);
CREATE POLICY "automation_executions_select" ON automation_executions FOR SELECT USING (company_id = requesting_company_id());
-- Insert only via service role (automation engine EF)

-- ══════════════════════════════════════════════
-- SYSTEM HEALTH CHECKS (ops portal)
-- ══════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS system_health_checks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name text NOT NULL,
  status text NOT NULL DEFAULT 'unknown' CHECK (status IN ('healthy', 'degraded', 'down', 'unknown')),
  latency_ms integer,
  response_code integer,
  error_message text,
  checked_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE system_health_checks ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_system_health_checks_service ON system_health_checks (service_name, checked_at DESC);
-- Only super_admin can view
CREATE POLICY "system_health_checks_select" ON system_health_checks FOR SELECT
  USING ((SELECT raw_app_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'super_admin');
