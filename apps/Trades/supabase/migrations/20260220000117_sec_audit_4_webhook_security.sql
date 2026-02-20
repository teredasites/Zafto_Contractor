-- SEC-AUDIT-4 | Session 140 — Webhook Security Hardening
-- 1. pg_cron job to clean stale impersonation sessions (>30 min)
-- 2. No new tables needed — changes are all in Edge Functions

-- ============================================================================
-- Impersonation TTL cleanup function
-- Finds users with stale impersonation sessions and restores their metadata
-- ============================================================================
CREATE OR REPLACE FUNCTION clean_stale_impersonation_sessions()
RETURNS void AS $$
DECLARE
  stale_user RECORD;
  restored_meta jsonb;
BEGIN
  FOR stale_user IN
    SELECT id, email, raw_app_meta_data
    FROM auth.users
    WHERE raw_app_meta_data->>'impersonation_started_at' IS NOT NULL
      AND (raw_app_meta_data->>'impersonation_started_at')::timestamptz < now() - interval '30 minutes'
  LOOP
    -- Build restored metadata: swap back to original company/role, null out impersonation fields
    restored_meta := stale_user.raw_app_meta_data;
    restored_meta := jsonb_set(restored_meta, '{company_id}', COALESCE(stale_user.raw_app_meta_data->'original_company_id', '"null"'::jsonb));
    restored_meta := jsonb_set(restored_meta, '{role}', COALESCE(stale_user.raw_app_meta_data->'original_role', '"super_admin"'::jsonb));
    restored_meta := restored_meta - 'original_company_id' - 'original_role' - 'impersonation_session_id' - 'impersonation_started_at';

    UPDATE auth.users
    SET raw_app_meta_data = restored_meta
    WHERE id = stale_user.id;

    -- Log the auto-expiry (best effort — don't fail if table doesn't exist)
    BEGIN
      INSERT INTO public.admin_audit_log (admin_user_id, admin_email, action, details)
      VALUES (
        stale_user.id,
        COALESCE(stale_user.email, 'unknown'),
        'impersonate_auto_expired',
        jsonb_build_object('expired_at', now()::text, 'cleanup_source', 'pg_cron')
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Could not log impersonation expiry for user %: %', stale_user.id, SQLERRM;
    END;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule cleanup every 5 minutes (pg_cron already enabled from SEC-AUDIT-1 rate limiter)
SELECT cron.schedule(
  'clean-stale-impersonation-sessions',
  '*/5 * * * *',
  'SELECT clean_stale_impersonation_sessions()'
);
