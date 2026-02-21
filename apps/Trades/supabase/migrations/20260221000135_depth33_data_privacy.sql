-- DEPTH33: Data Privacy Controls & AI Training Consent
-- GDPR/CCPA compliant consent management, data export requests,
-- data deletion requests, consent audit trail.
-- Default all data-sharing/AI consents to OFF (opt-in only).

-- ============================================================================
-- USER CONSENT (audit trail — never delete, only add new records)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_consent (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL REFERENCES auth.users(id),
  company_id        uuid NOT NULL REFERENCES companies(id),
  consent_type      text NOT NULL
    CHECK (consent_type IN (
      'pricing_data_sharing',
      'ai_training',
      'analytics',
      'marketing_emails',
      'push_notifications'
    )),
  granted           boolean NOT NULL DEFAULT false,
  granted_at        timestamptz,
  revoked_at        timestamptz,
  consent_version   text NOT NULL DEFAULT '1.0',
  ip_address        inet,
  user_agent        text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_user_consent_user ON user_consent (user_id, consent_type);
CREATE INDEX idx_user_consent_company ON user_consent (company_id);
CREATE INDEX idx_user_consent_type_granted ON user_consent (consent_type, granted)
  WHERE granted = true;

ALTER TABLE user_consent ENABLE ROW LEVEL SECURITY;

-- Users can see/modify their own consents
CREATE POLICY "user_consent_select" ON user_consent
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "user_consent_insert" ON user_consent
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_consent_update" ON user_consent
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Owners/admins can view company-wide consent status (aggregate only)
CREATE POLICY "user_consent_company_select" ON user_consent
  FOR SELECT TO authenticated
  USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND (auth.jwt() -> 'app_metadata' ->> 'role') IN ('owner', 'admin', 'super_admin')
  );

SELECT update_updated_at('user_consent');
SELECT audit_trigger_fn('user_consent');

-- ============================================================================
-- DATA EXPORT REQUESTS (GDPR Article 15 / CCPA)
-- ============================================================================

CREATE TABLE IF NOT EXISTS data_export_requests (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL REFERENCES auth.users(id),
  company_id        uuid NOT NULL REFERENCES companies(id),
  status            text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'expired')),
  export_format     text NOT NULL DEFAULT 'json'
    CHECK (export_format IN ('json', 'csv')),
  download_url      text,
  download_expires  timestamptz,
  requested_at      timestamptz NOT NULL DEFAULT now(),
  completed_at      timestamptz,
  file_size_bytes   bigint,
  error_message     text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_data_export_user ON data_export_requests (user_id, created_at DESC);
CREATE INDEX idx_data_export_status ON data_export_requests (status)
  WHERE status IN ('pending', 'processing');

ALTER TABLE data_export_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "data_export_select" ON data_export_requests
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "data_export_insert" ON data_export_requests
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Service role for processing
CREATE POLICY "data_export_system" ON data_export_requests
  FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('data_export_requests');
SELECT audit_trigger_fn('data_export_requests');

-- ============================================================================
-- DATA DELETION REQUESTS (GDPR Article 17 / CCPA)
-- ============================================================================

CREATE TABLE IF NOT EXISTS data_deletion_requests (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL REFERENCES auth.users(id),
  company_id        uuid NOT NULL REFERENCES companies(id),
  status            text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'processing', 'completed', 'cancelled')),
  confirmation_code text,
  confirmed_at      timestamptz,
  grace_period_ends timestamptz,
  processed_at      timestamptz,
  scope             text NOT NULL DEFAULT 'user_data'
    CHECK (scope IN ('user_data', 'company_data')),
  reason            text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_data_deletion_user ON data_deletion_requests (user_id, created_at DESC);
CREATE INDEX idx_data_deletion_status ON data_deletion_requests (status)
  WHERE status IN ('pending', 'confirmed', 'processing');
CREATE INDEX idx_data_deletion_grace ON data_deletion_requests (grace_period_ends)
  WHERE status = 'confirmed';

ALTER TABLE data_deletion_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "data_deletion_select" ON data_deletion_requests
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "data_deletion_insert" ON data_deletion_requests
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "data_deletion_update" ON data_deletion_requests
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Service role for processing
CREATE POLICY "data_deletion_system" ON data_deletion_requests
  FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('data_deletion_requests');
SELECT audit_trigger_fn('data_deletion_requests');

-- ============================================================================
-- PRIVACY POLICY VERSIONS (track TOS/privacy changes)
-- ============================================================================

CREATE TABLE IF NOT EXISTS privacy_policy_versions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  version       text NOT NULL UNIQUE,
  title         text NOT NULL,
  summary       text,
  effective_at  timestamptz NOT NULL,
  content_url   text,
  changes       text[],
  created_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE privacy_policy_versions ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read policy versions
CREATE POLICY "privacy_policy_select" ON privacy_policy_versions
  FOR SELECT TO authenticated USING (true);

-- Service role only writes
CREATE POLICY "privacy_policy_system" ON privacy_policy_versions
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- SEED: Initial privacy policy version
-- ============================================================================

INSERT INTO privacy_policy_versions (version, title, summary, effective_at, changes)
VALUES (
  '1.0',
  'Zafto Privacy Policy v1.0',
  'Initial privacy policy covering data collection, consent management, AI training opt-in, pricing data sharing opt-in, analytics, GDPR/CCPA compliance.',
  now(),
  ARRAY[
    'Initial release',
    'Pricing data sharing: opt-in only, anonymized aggregates from 5+ companies',
    'AI training: opt-in only, anonymized aggregated patterns only',
    'Analytics: opt-out available, anonymous usage data only',
    'Data export: available on request, delivered within 24 hours',
    'Data deletion: 30-day grace period, then permanent removal'
  ]
)
ON CONFLICT DO NOTHING;
