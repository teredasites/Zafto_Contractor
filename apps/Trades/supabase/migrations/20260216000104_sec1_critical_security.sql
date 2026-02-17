-- SEC1: Critical Security Fixes
-- Sprint: SEC1 (~6h) — Fix 3 vulnerabilities from S125 security scan + S130 audit additions
-- 1. Storage bucket RLS policies (cross-company file isolation)
-- 2. Persistent rate limiting table + RPC function (not in-memory — survives cold starts)
-- 3. Equipment database write policy fix (role-restricted)
-- 4. pg_cron cleanup for rate limit entries

-- ============================================================
-- 1. STORAGE BUCKET RLS POLICIES
-- ============================================================
-- All private buckets use folder structure: {bucket}/{company_id}/...
-- Policies scope access by company_id extracted from the first folder in the path.
-- This prevents cross-company file access via direct Supabase Storage API.
--
-- Buckets: photos, signatures, voice-notes, receipts, documents, avatars,
--          company-logos, estimate-photos (8 total)
--
-- RLS is already enabled on storage.objects by Supabase.
-- We add granular per-bucket policies.

-- Drop any existing overly-permissive storage policies
-- (Supabase default may include broad policies — clean slate for security)
DO $$
BEGIN
  -- Drop default policies if they exist (safe — no error if missing)
  DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
  DROP POLICY IF EXISTS "Allow authenticated select" ON storage.objects;
  DROP POLICY IF EXISTS "Allow authenticated update" ON storage.objects;
  DROP POLICY IF EXISTS "Allow authenticated delete" ON storage.objects;
  DROP POLICY IF EXISTS "Allow public select" ON storage.objects;
  DROP POLICY IF EXISTS "Give users access to own folder" ON storage.objects;
  -- Drop any previous SEC1 policies (idempotent re-run safety)
  DROP POLICY IF EXISTS "storage_photos_select" ON storage.objects;
  DROP POLICY IF EXISTS "storage_photos_insert" ON storage.objects;
  DROP POLICY IF EXISTS "storage_photos_update" ON storage.objects;
  DROP POLICY IF EXISTS "storage_photos_delete" ON storage.objects;
  DROP POLICY IF EXISTS "storage_signatures_select" ON storage.objects;
  DROP POLICY IF EXISTS "storage_signatures_insert" ON storage.objects;
  DROP POLICY IF EXISTS "storage_signatures_update" ON storage.objects;
  DROP POLICY IF EXISTS "storage_signatures_delete" ON storage.objects;
  DROP POLICY IF EXISTS "storage_voice_notes_select" ON storage.objects;
  DROP POLICY IF EXISTS "storage_voice_notes_insert" ON storage.objects;
  DROP POLICY IF EXISTS "storage_voice_notes_update" ON storage.objects;
  DROP POLICY IF EXISTS "storage_voice_notes_delete" ON storage.objects;
  DROP POLICY IF EXISTS "storage_receipts_select" ON storage.objects;
  DROP POLICY IF EXISTS "storage_receipts_insert" ON storage.objects;
  DROP POLICY IF EXISTS "storage_receipts_update" ON storage.objects;
  DROP POLICY IF EXISTS "storage_receipts_delete" ON storage.objects;
  DROP POLICY IF EXISTS "storage_documents_select" ON storage.objects;
  DROP POLICY IF EXISTS "storage_documents_insert" ON storage.objects;
  DROP POLICY IF EXISTS "storage_documents_update" ON storage.objects;
  DROP POLICY IF EXISTS "storage_documents_delete" ON storage.objects;
  DROP POLICY IF EXISTS "storage_avatars_select" ON storage.objects;
  DROP POLICY IF EXISTS "storage_avatars_insert" ON storage.objects;
  DROP POLICY IF EXISTS "storage_avatars_update" ON storage.objects;
  DROP POLICY IF EXISTS "storage_avatars_delete" ON storage.objects;
  DROP POLICY IF EXISTS "storage_company_logos_select" ON storage.objects;
  DROP POLICY IF EXISTS "storage_company_logos_insert" ON storage.objects;
  DROP POLICY IF EXISTS "storage_company_logos_update" ON storage.objects;
  DROP POLICY IF EXISTS "storage_company_logos_delete" ON storage.objects;
  DROP POLICY IF EXISTS "storage_estimate_photos_select" ON storage.objects;
  DROP POLICY IF EXISTS "storage_estimate_photos_insert" ON storage.objects;
  DROP POLICY IF EXISTS "storage_estimate_photos_update" ON storage.objects;
  DROP POLICY IF EXISTS "storage_estimate_photos_delete" ON storage.objects;
END $$;

-- ----------------------------------------
-- PHOTOS bucket — job photos, walkthrough photos, inspection photos
-- Path: photos/{company_id}/...
-- ----------------------------------------
CREATE POLICY "storage_photos_select" ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'photos'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_photos_insert" ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'photos'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_photos_update" ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'photos'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_photos_delete" ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'photos'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

-- ----------------------------------------
-- SIGNATURES bucket — customer/employee signatures
-- Path: signatures/{company_id}/...
-- ----------------------------------------
CREATE POLICY "storage_signatures_select" ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'signatures'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_signatures_insert" ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'signatures'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_signatures_update" ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'signatures'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_signatures_delete" ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'signatures'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

-- ----------------------------------------
-- VOICE-NOTES bucket — field voice memos
-- Path: voice-notes/{company_id}/...
-- ----------------------------------------
CREATE POLICY "storage_voice_notes_select" ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'voice-notes'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_voice_notes_insert" ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'voice-notes'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_voice_notes_update" ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'voice-notes'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_voice_notes_delete" ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'voice-notes'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

-- ----------------------------------------
-- RECEIPTS bucket — expense receipts, material receipts
-- Path: receipts/{company_id}/...
-- ----------------------------------------
CREATE POLICY "storage_receipts_select" ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_receipts_insert" ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_receipts_update" ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_receipts_delete" ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

-- ----------------------------------------
-- DOCUMENTS bucket — contracts, agreements, permits, compliance docs
-- Path: documents/{company_id}/...
-- ----------------------------------------
CREATE POLICY "storage_documents_select" ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_documents_insert" ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_documents_update" ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_documents_delete" ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

-- ----------------------------------------
-- AVATARS bucket — user profile pictures
-- Path: avatars/{company_id}/{user_id}/...
-- SELECT: company-scoped (team members can see each other's avatars)
-- INSERT/UPDATE/DELETE: only own avatar (owner = auth.uid())
-- ----------------------------------------
CREATE POLICY "storage_avatars_select" ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_avatars_insert" ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
    AND owner = auth.uid()
  );

CREATE POLICY "storage_avatars_update" ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
    AND owner = auth.uid()
  );

CREATE POLICY "storage_avatars_delete" ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
    AND owner = auth.uid()
  );

-- ----------------------------------------
-- COMPANY-LOGOS bucket — company branding
-- Path: company-logos/{company_id}/...
-- SELECT: company-scoped
-- INSERT/UPDATE/DELETE: owner/admin only
-- ----------------------------------------
CREATE POLICY "storage_company_logos_select" ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'company-logos'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_company_logos_insert" ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'company-logos'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'super_admin')
  );

CREATE POLICY "storage_company_logos_update" ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'company-logos'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'super_admin')
  );

CREATE POLICY "storage_company_logos_delete" ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'company-logos'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'super_admin')
  );

-- ----------------------------------------
-- ESTIMATE-PHOTOS bucket — photos attached to estimates
-- Path: estimate-photos/{company_id}/...
-- ----------------------------------------
CREATE POLICY "storage_estimate_photos_select" ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'estimate-photos'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_estimate_photos_insert" ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'estimate-photos'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_estimate_photos_update" ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'estimate-photos'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );

CREATE POLICY "storage_estimate_photos_delete" ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'estimate-photos'
    AND (storage.foldername(name))[1]::uuid = requesting_company_id()
  );


-- ============================================================
-- 2. RATE LIMITING — PERSISTENT TABLE-BASED (NOT IN-MEMORY)
-- ============================================================
-- In-memory rate limiting resets on Edge Function cold starts, creating a bypass.
-- Table-based persistence ensures rate limits survive cold starts, scaling events,
-- and function redeployments.

CREATE TABLE IF NOT EXISTS rate_limit_entries (
  key TEXT PRIMARY KEY,
  count INTEGER NOT NULL DEFAULT 1,
  window_start TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- No client access — only service_role from Edge Functions
ALTER TABLE rate_limit_entries ENABLE ROW LEVEL SECURITY;
-- No policies = no client access (service_role bypasses RLS)

-- Index for cleanup query performance
CREATE INDEX IF NOT EXISTS idx_rate_limit_window ON rate_limit_entries(window_start);

-- Atomic rate limit check function — prevents race conditions via FOR UPDATE row lock
-- Returns JSONB: { allowed: bool, remaining: int, retry_after: int }
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_key TEXT,
  p_max_requests INTEGER,
  p_window_seconds INTEGER
) RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INTEGER;
  v_window_start TIMESTAMPTZ;
  v_now TIMESTAMPTZ := now();
  v_window_cutoff TIMESTAMPTZ := v_now - make_interval(secs => p_window_seconds);
BEGIN
  -- Attempt to lock existing row
  SELECT count, window_start INTO v_count, v_window_start
  FROM rate_limit_entries
  WHERE key = p_key
  FOR UPDATE;

  IF NOT FOUND THEN
    -- First request — create entry
    INSERT INTO rate_limit_entries (key, count, window_start)
    VALUES (p_key, 1, v_now)
    ON CONFLICT (key) DO UPDATE
      SET count = 1, window_start = v_now;
    RETURN jsonb_build_object(
      'allowed', true,
      'remaining', p_max_requests - 1,
      'retry_after', 0
    );
  END IF;

  -- Window expired — reset
  IF v_window_start < v_window_cutoff THEN
    UPDATE rate_limit_entries
    SET count = 1, window_start = v_now
    WHERE key = p_key;
    RETURN jsonb_build_object(
      'allowed', true,
      'remaining', p_max_requests - 1,
      'retry_after', 0
    );
  END IF;

  -- Within window — check limit
  IF v_count >= p_max_requests THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'remaining', 0,
      'retry_after', EXTRACT(EPOCH FROM (
        v_window_start + make_interval(secs => p_window_seconds) - v_now
      ))::integer
    );
  END IF;

  -- Increment and allow
  UPDATE rate_limit_entries
  SET count = count + 1
  WHERE key = p_key;

  RETURN jsonb_build_object(
    'allowed', true,
    'remaining', p_max_requests - v_count - 1,
    'retry_after', 0
  );
END;
$$;

-- pg_cron cleanup: purge expired entries every 5 minutes
-- Keeps the table small even under heavy load. $0/month — uses existing Supabase.
-- Note: pg_cron is enabled by default on Supabase Pro plans.
-- If pg_cron is not available, Edge Functions will still work — old entries just accumulate
-- until manual cleanup. The check_rate_limit function handles expired windows regardless.
DO $$
BEGIN
  -- Only schedule if pg_cron extension is available
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'cleanup-rate-limits',
      '*/5 * * * *',
      $$DELETE FROM rate_limit_entries WHERE window_start < now() - interval '5 minutes'$$
    );
  END IF;
END $$;


-- ============================================================
-- 3. EQUIPMENT DATABASE WRITE POLICY FIX
-- ============================================================
-- Current policy: equip_db_write allows ANY authenticated user to INSERT.
-- Fix: restrict to owner/admin/super_admin only.

DROP POLICY IF EXISTS "equip_db_write" ON equipment_database;

CREATE POLICY "equip_db_write" ON equipment_database FOR INSERT
  TO authenticated
  WITH CHECK (
    requesting_user_role() IN ('owner', 'admin', 'super_admin')
  );

-- Also add UPDATE and DELETE policies (missing from original migration)
DROP POLICY IF EXISTS "equip_db_update" ON equipment_database;
DROP POLICY IF EXISTS "equip_db_delete" ON equipment_database;

CREATE POLICY "equip_db_update" ON equipment_database FOR UPDATE
  TO authenticated
  USING (
    requesting_user_role() IN ('owner', 'admin', 'super_admin')
  );

CREATE POLICY "equip_db_delete" ON equipment_database FOR DELETE
  TO authenticated
  USING (
    requesting_user_role() IN ('owner', 'admin', 'super_admin')
  );
