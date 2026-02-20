-- SEC-AUDIT-5 | Session 140 — Database Infrastructure Hardening
-- 1. Audit triggers on 30 high-priority tables missing them
-- 2. company_id B-tree indexes on ALL tables missing them (dynamic)
-- 3. deleted_at columns on 13 business tables missing them
-- 4. SECURITY DEFINER on 3 functions
-- 5. Consolidate fn_update_timestamp → update_updated_at
-- 6. Credit RPCs already exist (SEC-AUDIT-1) — no changes needed
-- 7. fn_get_item_pricing + fn_zip_to_msa already STABLE — no changes needed

-- ============================================================================
-- 1. AUDIT TRIGGERS on 30 high-priority tables
-- These tables handle financial/communication/HR data but lack audit trails
-- ============================================================================

-- Financial tables
DROP TRIGGER IF EXISTS audit_trigger ON payment_intents;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON payment_intents
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON payments;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON payments
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON credit_purchases;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON credit_purchases
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON user_credits;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON user_credits
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON bank_transactions;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON bank_transactions
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON expense_records;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON expense_records
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON pay_periods;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON pay_periods
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON pay_stubs;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON pay_stubs
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON bank_reconciliations;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON bank_reconciliations
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON vendor_payments;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON vendor_payments
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON recurring_transactions;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON recurring_transactions
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Communication tables
DROP TRIGGER IF EXISTS audit_trigger ON phone_calls;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON phone_calls
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON phone_messages;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON phone_messages
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON phone_faxes;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON phone_faxes
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON email_sends;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON email_sends
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON email_campaigns;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON email_campaigns
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Document tables
DROP TRIGGER IF EXISTS audit_trigger ON documents;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON documents
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON document_folders;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON document_folders
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Fleet tables
DROP TRIGGER IF EXISTS audit_trigger ON vehicles;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON vehicles
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON vehicle_maintenance;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON vehicle_maintenance
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON fuel_logs;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON fuel_logs
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Marketplace tables
DROP TRIGGER IF EXISTS audit_trigger ON marketplace_leads;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON marketplace_leads
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON marketplace_bids;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON marketplace_bids
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Schedule change tracking
DROP TRIGGER IF EXISTS audit_trigger ON schedule_task_changes;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON schedule_task_changes
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- HR tables
DROP TRIGGER IF EXISTS audit_trigger ON employee_records;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON employee_records
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON performance_reviews;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON performance_reviews
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON training_records;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON training_records
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

DROP TRIGGER IF EXISTS audit_trigger ON onboarding_checklists;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON onboarding_checklists
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Profile tables
DROP TRIGGER IF EXISTS audit_trigger ON contractor_profiles;
CREATE TRIGGER audit_trigger AFTER INSERT OR UPDATE OR DELETE ON contractor_profiles
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ============================================================================
-- 2. DYNAMIC: Add company_id B-tree indexes on ALL tables missing them
-- Finds every public table with company_id column that lacks an index
-- ============================================================================
DO $$
DECLARE
  tbl RECORD;
  idx_name TEXT;
BEGIN
  FOR tbl IN
    SELECT c.table_name
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.column_name = 'company_id'
      AND NOT EXISTS (
        SELECT 1
        FROM pg_indexes i
        WHERE i.schemaname = 'public'
          AND i.tablename = c.table_name
          AND (i.indexdef LIKE '%company_id%' OR i.indexdef LIKE '%company\_id%')
      )
  LOOP
    idx_name := 'idx_' || tbl.table_name || '_company_id';
    -- Truncate index name if too long (PostgreSQL 63-char limit)
    IF length(idx_name) > 63 THEN
      idx_name := 'idx_' || left(tbl.table_name, 55) || '_cid';
    END IF;
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON public.%I (company_id)', idx_name, tbl.table_name);
    RAISE NOTICE 'Created index % on %.company_id', idx_name, tbl.table_name;
  END LOOP;
END $$;

-- ============================================================================
-- 3. Add deleted_at to 13 business tables missing it
-- ============================================================================
ALTER TABLE claim_supplements ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE leads ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE branches ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE custom_roles ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE certifications ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE api_keys ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE bank_accounts ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE bank_transactions ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE pay_periods ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE notification_triggers ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE punch_list_items ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE change_orders ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE daily_logs ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- ============================================================================
-- 4. SECURITY DEFINER on 3 functions that need privileged access
-- ============================================================================
ALTER FUNCTION update_conversation_last_message() SECURITY DEFINER;
ALTER FUNCTION mark_conversation_read(UUID, UUID) SECURITY DEFINER;
ALTER FUNCTION update_inspection_deficiency_count() SECURITY DEFINER;

-- ============================================================================
-- 5. Consolidate fn_update_timestamp → update_updated_at
-- Replace triggers on the 2 tables using the duplicate function
-- ============================================================================
DO $$
BEGIN
  -- Replace trigger on payment_methods (if table exists)
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'payment_methods') THEN
    DROP TRIGGER IF EXISTS update_timestamp ON payment_methods;
    CREATE TRIGGER update_timestamp BEFORE UPDATE ON payment_methods FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  END IF;

  -- Replace trigger on user_credits (if table exists)
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_credits') THEN
    DROP TRIGGER IF EXISTS update_timestamp ON user_credits;
    CREATE TRIGGER update_timestamp BEFORE UPDATE ON user_credits FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  END IF;
END $$;

-- Drop the duplicate function
DROP FUNCTION IF EXISTS fn_update_timestamp();

-- ============================================================================
-- 6. Atomic credit deduction RPC (free-first-then-paid, row-locked)
-- Fixes race condition in subscription-credits EF (TOCTOU: read→calc→write)
-- ============================================================================
CREATE OR REPLACE FUNCTION deduct_credits_atomic(p_user_id UUID, p_amount INT)
RETURNS TABLE(new_free_credits INT, new_paid_credits INT, new_total_scans INT, user_company_id UUID) AS $$
DECLARE
  rec RECORD;
  calc_free INT;
  calc_paid INT;
BEGIN
  -- Lock the row to prevent concurrent deductions
  SELECT uc.free_credits, uc.paid_credits, uc.total_scans, uc.company_id
  INTO rec
  FROM user_credits uc
  WHERE uc.user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_CREDITS_RECORD';
  END IF;

  IF rec.free_credits + rec.paid_credits < p_amount THEN
    RAISE EXCEPTION 'INSUFFICIENT_CREDITS';
  END IF;

  -- Free credits first, then paid
  IF rec.free_credits >= p_amount THEN
    calc_free := rec.free_credits - p_amount;
    calc_paid := rec.paid_credits;
  ELSE
    calc_free := 0;
    calc_paid := rec.paid_credits - (p_amount - rec.free_credits);
  END IF;

  UPDATE user_credits
  SET free_credits = calc_free,
      paid_credits = calc_paid,
      total_scans = user_credits.total_scans + 1,
      last_scan_at = now()
  WHERE user_id = p_user_id;

  RETURN QUERY SELECT calc_free, calc_paid, rec.total_scans + 1, rec.company_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Only callable via service_role
REVOKE EXECUTE ON FUNCTION deduct_credits_atomic(UUID, INT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION deduct_credits_atomic(UUID, INT) FROM authenticated;
GRANT EXECUTE ON FUNCTION deduct_credits_atomic(UUID, INT) TO service_role;
