-- ============================================================
-- DEPTH41 — Backup Fortress: Multi-Location Redundancy
-- Triple redundancy: Supabase native + Cloudflare R2 + Backblaze B2
-- Immutable backups, automated verification, ops dashboard
-- ============================================================

-- ── backup_jobs — tracks all backup executions ──
CREATE TABLE backup_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- What backup
  backup_type text NOT NULL CHECK (backup_type IN (
    'supabase_pitr', 'pgdump_r2', 'pgdump_b2', 'storage_mirror_r2'
  )),
  schedule text NOT NULL DEFAULT 'nightly' CHECK (schedule IN ('nightly', 'weekly', 'monthly', 'manual')),

  -- Status
  status text NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'running', 'completed', 'failed', 'verified', 'expired'
  )),
  started_at timestamptz,
  completed_at timestamptz,
  failed_at timestamptz,
  error_message text,

  -- Backup details
  storage_provider text NOT NULL CHECK (storage_provider IN ('supabase', 'cloudflare_r2', 'backblaze_b2')),
  storage_bucket text,
  storage_key text, -- object key/path in bucket
  file_size_bytes bigint,
  compressed_size_bytes bigint,
  encryption_algorithm text DEFAULT 'AES-256-GCM',
  encryption_key_id text, -- reference to key management
  checksum_sha256 text,

  -- Immutability
  immutable_until timestamptz, -- object lock expiry
  retention_days int NOT NULL DEFAULT 90,
  is_immutable boolean NOT NULL DEFAULT true,

  -- Metadata
  table_count int,
  row_count_snapshot jsonb, -- {"companies": 150, "jobs": 12000, ...}
  database_size_bytes bigint,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_backup_jobs_type ON backup_jobs (backup_type, status);
CREATE INDEX idx_backup_jobs_date ON backup_jobs (created_at DESC);
CREATE INDEX idx_backup_jobs_status ON backup_jobs (status) WHERE status IN ('running', 'failed');
CREATE INDEX idx_backup_jobs_retention ON backup_jobs (immutable_until) WHERE status = 'completed';

CREATE TRIGGER backup_jobs_updated
  BEFORE UPDATE ON backup_jobs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── backup_verifications — monthly restore test results ──
CREATE TABLE backup_verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  backup_job_id uuid NOT NULL REFERENCES backup_jobs(id),

  -- Verification status
  status text NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'running', 'passed', 'failed', 'partial'
  )),
  started_at timestamptz,
  completed_at timestamptz,

  -- Verification details
  restore_target text, -- test database identifier
  table_counts_match boolean,
  table_count_expected int,
  table_count_actual int,
  row_count_mismatches jsonb DEFAULT '[]'::jsonb, -- [{table, expected, actual}]
  data_integrity_check boolean, -- recent records exist
  restore_time_seconds int, -- how long restore took
  error_details text,

  -- Summary
  overall_health text NOT NULL DEFAULT 'unknown' CHECK (overall_health IN (
    'green', 'yellow', 'red', 'unknown'
  )),
  notes text,

  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_backup_verifications_job ON backup_verifications (backup_job_id);
CREATE INDEX idx_backup_verifications_date ON backup_verifications (created_at DESC);

-- ── backup_storage_metrics — daily storage usage tracking ──
CREATE TABLE backup_storage_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_date date NOT NULL,
  storage_provider text NOT NULL CHECK (storage_provider IN ('supabase', 'cloudflare_r2', 'backblaze_b2')),

  -- Sizes
  total_size_bytes bigint NOT NULL DEFAULT 0,
  backup_count int NOT NULL DEFAULT 0,
  oldest_backup_at timestamptz,
  newest_backup_at timestamptz,

  -- Cost tracking (in cents)
  estimated_cost_cents int NOT NULL DEFAULT 0,

  created_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (metric_date, storage_provider)
);

CREATE INDEX idx_backup_metrics_date ON backup_storage_metrics (metric_date DESC);

-- ── disaster_recovery_runbook — step-by-step procedures stored in DB ──
CREATE TABLE disaster_recovery_runbook (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario text NOT NULL UNIQUE, -- 'database_corruption', 'supabase_outage', 'storage_loss', etc.
  severity text NOT NULL DEFAULT 'critical' CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  title text NOT NULL,
  description text,

  -- Steps as ordered JSONB
  steps jsonb NOT NULL DEFAULT '[]'::jsonb, -- [{order, title, instructions, estimated_minutes, requires_admin}]

  -- Recovery metrics
  estimated_recovery_time_minutes int,
  max_data_loss_minutes int, -- RPO
  last_tested_at timestamptz,
  last_test_result text CHECK (last_test_result IN ('passed', 'failed', 'partial', NULL)),

  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER dr_runbook_updated
  BEFORE UPDATE ON disaster_recovery_runbook
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Seed disaster recovery runbook entries
INSERT INTO disaster_recovery_runbook (scenario, severity, title, description, estimated_recovery_time_minutes, max_data_loss_minutes, steps) VALUES
  ('database_corruption', 'critical', 'Database Corruption Recovery',
   'Full database corruption requiring restore from backup. Use PITR first, fall back to R2/B2 pg_dump.',
   30, 2,
   '[{"order":1,"title":"Assess damage scope","instructions":"Check Supabase dashboard for error logs. Identify which tables are affected. If partial, consider table-level restore.","estimated_minutes":5,"requires_admin":true},{"order":2,"title":"Enable maintenance mode","instructions":"Set maintenance page active on Cloudflare Pages. Notify users via push notification if SignalWire is available.","estimated_minutes":2,"requires_admin":true},{"order":3,"title":"Attempt Supabase PITR","instructions":"Supabase dashboard → Database → Point-in-time recovery. Select timestamp before corruption. This is the fastest option (RPO: 2 minutes).","estimated_minutes":10,"requires_admin":true},{"order":4,"title":"If PITR fails: Restore from R2","instructions":"Download latest nightly pg_dump from Cloudflare R2. Decrypt with AES-256-GCM key. pg_restore to new Supabase project or direct restore.","estimated_minutes":20,"requires_admin":true},{"order":5,"title":"Verify restore","instructions":"Run backup verification checks: table counts, recent data exists, auth works. Test one full user flow end-to-end.","estimated_minutes":10,"requires_admin":true},{"order":6,"title":"Disable maintenance mode","instructions":"Remove maintenance redirect. Monitor error rates for 1 hour.","estimated_minutes":2,"requires_admin":true}]'
  ),
  ('supabase_outage', 'critical', 'Supabase Platform Outage',
   'Complete Supabase outage affecting database, auth, storage, and edge functions. Flutter app should work offline via PowerSync.',
   5, 0,
   '[{"order":1,"title":"Confirm outage","instructions":"Check status.supabase.com. If regional, check if project can be migrated. If global, wait for resolution.","estimated_minutes":2,"requires_admin":false},{"order":2,"title":"Enable maintenance page","instructions":"Cloudflare Pages maintenance page auto-activates on health check failure (or manual: set DNS redirect).","estimated_minutes":1,"requires_admin":true},{"order":3,"title":"Notify users","instructions":"Push notification via Firebase/RevenueCat (not dependent on Supabase): System is experiencing issues, your offline data is safe.","estimated_minutes":2,"requires_admin":true},{"order":4,"title":"Monitor recovery","instructions":"Watch status.supabase.com. When resolved, verify all endpoints respond. Check PowerSync sync queue processes correctly.","estimated_minutes":0,"requires_admin":false},{"order":5,"title":"Post-incident review","instructions":"Document: duration, data loss (should be 0 with PowerSync), user complaints, areas for improvement.","estimated_minutes":30,"requires_admin":true}]'
  ),
  ('storage_loss', 'high', 'Storage Bucket Data Loss',
   'Photos, documents, or signatures lost from Supabase storage. Restore from nightly R2 mirror.',
   60, 1440,
   '[{"order":1,"title":"Identify scope","instructions":"Which bucket(s) affected? photos, documents, signatures, voice-notes? Check Supabase storage dashboard.","estimated_minutes":5,"requires_admin":true},{"order":2,"title":"Restore from R2 mirror","instructions":"Nightly mirror on Cloudflare R2 has all storage files. Download affected bucket contents. Re-upload to Supabase storage preserving paths.","estimated_minutes":45,"requires_admin":true},{"order":3,"title":"Verify file integrity","instructions":"Spot-check 10 random files from each bucket. Verify signatures are valid, photos display, documents render.","estimated_minutes":10,"requires_admin":true}]'
  ),
  ('data_breach', 'critical', 'Suspected Data Breach',
   'Unauthorized access to user data. Immediate containment, investigation, notification.',
   120, 0,
   '[{"order":1,"title":"Immediate containment","instructions":"Rotate all API keys: Supabase service_role key, anon key, JWT secret. This invalidates all sessions immediately.","estimated_minutes":5,"requires_admin":true},{"order":2,"title":"Audit access logs","instructions":"Check Supabase auth logs for unusual login patterns. Check Edge Function logs for unusual API calls. Check audit_log table for suspicious data access.","estimated_minutes":30,"requires_admin":true},{"order":3,"title":"Assess scope","instructions":"What data was accessed? Check RLS policies are intact. Verify company_id scoping. Check if any policies were bypassed.","estimated_minutes":30,"requires_admin":true},{"order":4,"title":"Legal notification","instructions":"If PII was exposed: GDPR requires 72-hour notification. CCPA requires prompt notification. Document everything for legal counsel.","estimated_minutes":15,"requires_admin":true},{"order":5,"title":"User notification","instructions":"If breach confirmed: notify affected users with clear language about what happened, what data was exposed, and what we are doing about it.","estimated_minutes":30,"requires_admin":true},{"order":6,"title":"Post-incident hardening","instructions":"Fix the vulnerability. Add monitoring for the attack vector. Review all similar code paths. Add to security audit checklist.","estimated_minutes":60,"requires_admin":true}]'
  ),
  ('vercel_deployment_failure', 'medium', 'Vercel Deployment Failure',
   'All 4 web portals fail to deploy or serve errors after deployment.',
   15, 0,
   '[{"order":1,"title":"Rollback deployment","instructions":"Vercel dashboard → Project → Deployments → click previous working deployment → Promote to Production. Repeat for all 4 portals.","estimated_minutes":5,"requires_admin":true},{"order":2,"title":"Investigate failure","instructions":"Check Vercel build logs. Common causes: env var missing, dependency issue, TypeScript error, memory limit exceeded.","estimated_minutes":10,"requires_admin":true},{"order":3,"title":"Fix and redeploy","instructions":"Fix the issue locally, verify build passes, push to trigger new deployment.","estimated_minutes":30,"requires_admin":false}]'
  ),
  ('encryption_key_compromise', 'critical', 'Encryption Key Compromise',
   'Backup encryption keys may be compromised. Re-encrypt all backups with new keys.',
   180, 0,
   '[{"order":1,"title":"Generate new encryption keys","instructions":"Generate new AES-256-GCM keys. Store in Supabase Vault or environment variables (NEVER in code).","estimated_minutes":5,"requires_admin":true},{"order":2,"title":"Re-encrypt active backups","instructions":"Download all R2 and B2 backups. Decrypt with old key, re-encrypt with new key, re-upload. Verify checksums.","estimated_minutes":120,"requires_admin":true},{"order":3,"title":"Update Edge Functions","instructions":"Update backup Edge Functions with new key references. Deploy.","estimated_minutes":10,"requires_admin":true},{"order":4,"title":"Revoke old keys","instructions":"After all backups re-encrypted, securely destroy old keys. Document in security audit log.","estimated_minutes":5,"requires_admin":true}]'
  )
ON CONFLICT (scenario) DO NOTHING;

-- ── backup_alerts — notification log for backup issues ──
CREATE TABLE backup_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type text NOT NULL CHECK (alert_type IN (
    'backup_failed', 'verification_failed', 'storage_full',
    'retention_expiring', 'restore_needed', 'key_rotation_due'
  )),
  severity text NOT NULL DEFAULT 'high' CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  backup_job_id uuid REFERENCES backup_jobs(id),
  message text NOT NULL,
  details jsonb DEFAULT '{}'::jsonb,

  -- Resolution
  acknowledged_at timestamptz,
  acknowledged_by text,
  resolved_at timestamptz,
  resolution_notes text,

  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_backup_alerts_unresolved ON backup_alerts (created_at DESC) WHERE resolved_at IS NULL;
CREATE INDEX idx_backup_alerts_type ON backup_alerts (alert_type, severity);
