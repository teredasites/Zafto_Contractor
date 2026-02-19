-- SEC-AUDIT-1: Emergency Security Fixes
-- Addresses CRITICAL vulnerabilities from S138 full project audit (103 findings)
-- Migration: 115

-- ============================================================================
-- 1. REMOVE user_credits UPDATE POLICY (prevents credit manipulation exploit)
-- Users could set paid_credits to 99999 via direct Supabase client call
-- ============================================================================
DROP POLICY IF EXISTS "Users can update own credits" ON user_credits;

-- ============================================================================
-- 2. ATOMIC CREDIT RPC FUNCTIONS (SECURITY DEFINER — only callable by service_role)
-- Prevents race conditions and unauthorized credit manipulation
-- ============================================================================
CREATE OR REPLACE FUNCTION increment_user_credits(p_user_id UUID, p_amount INT)
RETURNS SETOF user_credits
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE user_credits
  SET paid_credits = paid_credits + p_amount
  WHERE user_id = p_user_id
  RETURNING *;
$$;

CREATE OR REPLACE FUNCTION decrement_user_credits(p_user_id UUID, p_amount INT)
RETURNS SETOF user_credits
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE user_credits
  SET paid_credits = paid_credits - p_amount,
      total_scans = total_scans + 1,
      last_scan_at = now()
  WHERE user_id = p_user_id
    AND paid_credits + free_credits >= p_amount
  RETURNING *;
$$;

-- Revoke direct access — only service_role can call these
REVOKE EXECUTE ON FUNCTION increment_user_credits(UUID, INT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION increment_user_credits(UUID, INT) TO service_role;

REVOKE EXECUTE ON FUNCTION decrement_user_credits(UUID, INT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION decrement_user_credits(UUID, INT) TO service_role;

-- ============================================================================
-- 3. CREATE bank_credentials TABLE (isolates Plaid access tokens)
-- Old: plaid_access_token in bank_accounts (readable by company members via RLS)
-- New: separate table, NO user-facing RLS policies (service_role only)
-- Expand-contract: old column kept for now, removed in future migration
-- ============================================================================
CREATE TABLE IF NOT EXISTS bank_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_account_id UUID NOT NULL REFERENCES bank_accounts(id) ON DELETE CASCADE UNIQUE,
  company_id UUID NOT NULL REFERENCES companies(id),
  plaid_access_token TEXT NOT NULL,
  plaid_item_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_bank_credentials_account ON bank_credentials(bank_account_id);
CREATE INDEX idx_bank_credentials_company ON bank_credentials(company_id);

ALTER TABLE bank_credentials ENABLE ROW LEVEL SECURITY;
-- NO user-facing policies. Only service_role bypasses RLS. This is intentional.
-- Plaid access tokens are high-value secrets that should never reach the frontend.

-- Backfill from existing bank_accounts data
INSERT INTO bank_credentials (bank_account_id, company_id, plaid_access_token, plaid_item_id)
SELECT id, company_id, plaid_access_token, plaid_item_id
FROM bank_accounts
WHERE plaid_access_token IS NOT NULL
ON CONFLICT (bank_account_id) DO NOTHING;

-- Audit trigger
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'bank_credentials_audit') THEN
    CREATE TRIGGER bank_credentials_audit
      AFTER INSERT OR UPDATE OR DELETE ON bank_credentials
      FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
  END IF;
END $$;

-- Updated_at trigger
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_bank_credentials_updated') THEN
    CREATE TRIGGER trg_bank_credentials_updated
      BEFORE UPDATE ON bank_credentials
      FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  END IF;
END $$;

-- ============================================================================
-- 4. FIX companies INSERT POLICY (prevents unrestricted company creation)
-- Old: WITH CHECK (true) — anyone could create a company
-- New: WITH CHECK (false) — only service_role can create companies
-- Company creation happens via signup/invite-team-member Edge Functions
-- ============================================================================
DROP POLICY IF EXISTS "companies_insert" ON companies;
CREATE POLICY "companies_insert" ON companies
  FOR INSERT WITH CHECK (false);

-- ============================================================================
-- 5. FIX payment_intents INSERT POLICY (add company_id scoping)
-- Old: only checked user_id = auth.uid() — no company scoping
-- New: also requires company_id matches JWT app_metadata
-- ============================================================================
DROP POLICY IF EXISTS "Authenticated users can create payment intents" ON payment_intents;
CREATE POLICY "Authenticated users can create payment intents"
  ON payment_intents FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );
