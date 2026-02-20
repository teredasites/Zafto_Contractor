-- INFRA-5: Webhook idempotency + feature flag verification + materialized view refresh
-- S143: Prevents double-processing of webhook events

-- ============================================================
-- webhook_events — Deduplication table for all webhook handlers
-- ============================================================
CREATE TABLE IF NOT EXISTS webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id TEXT NOT NULL,
  source TEXT NOT NULL, -- 'stripe', 'revenuecat', 'signalwire', 'sendgrid'
  event_type TEXT,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  payload JSONB,
  UNIQUE (event_id, source)
);

-- No RLS — service_role only (webhooks use service key)
-- No company_id — webhooks are platform-level

CREATE INDEX IF NOT EXISTS idx_webhook_events_source ON webhook_events (source);
CREATE INDEX IF NOT EXISTS idx_webhook_events_processed ON webhook_events (processed_at DESC);

-- ============================================================
-- Cleanup: delete webhook_events older than 30 days
-- Schedule with pg_cron: SELECT cron.schedule('clean-webhook-events', '0 3 * * 0', $$DELETE FROM webhook_events WHERE processed_at < now() - interval '30 days'$$);
-- ============================================================

-- ============================================================
-- Verify company_feature_flags table exists (created in earlier migration)
-- If not, create it
-- ============================================================
CREATE TABLE IF NOT EXISTS company_feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  flag_name TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT false,
  rollout_percentage INT DEFAULT 100 CHECK (rollout_percentage BETWEEN 0 AND 100),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (company_id, flag_name)
);

ALTER TABLE company_feature_flags ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER company_feature_flags_updated_at BEFORE UPDATE ON company_feature_flags FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE POLICY "feature_flags_select" ON company_feature_flags FOR SELECT USING (
  company_id = requesting_company_id()
);
CREATE POLICY "feature_flags_admin" ON company_feature_flags FOR ALL USING (
  company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin', 'super_admin')
);

CREATE INDEX IF NOT EXISTS idx_feature_flags_company ON company_feature_flags (company_id);
CREATE INDEX IF NOT EXISTS idx_feature_flags_lookup ON company_feature_flags (company_id, flag_name);

-- ============================================================
-- pg_cron: Refresh materialized views every 15 minutes
-- Schedule: SELECT cron.schedule('refresh-mv', '*/15 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_company_revenue_summary; REFRESH MATERIALIZED VIEW CONCURRENTLY mv_job_pipeline;');
-- ============================================================
