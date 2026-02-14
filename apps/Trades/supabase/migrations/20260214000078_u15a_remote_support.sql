-- ============================================================
-- U15a: Remote-In Support Tool — admin impersonation audit trail
-- ============================================================

-- Admin audit log — immutable INSERT-only table
CREATE TABLE IF NOT EXISTS admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID NOT NULL REFERENCES auth.users(id),
  admin_email TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN (
    'impersonate_start', 'impersonate_end', 'view_company',
    'modify_data', 'view_user', 'system_action'
  )),
  target_company_id UUID REFERENCES companies(id),
  target_company_name TEXT,
  details JSONB DEFAULT '{}'::jsonb,
  ip_address TEXT,
  user_agent TEXT,
  session_id UUID,  -- groups start/end of impersonation session
  created_at TIMESTAMPTZ DEFAULT now()
);

-- NO UPDATE/DELETE policies — immutable log
ALTER TABLE admin_audit_log ENABLE ROW LEVEL SECURITY;

-- Only super_admin can read
CREATE POLICY "admin_audit_log_select" ON admin_audit_log
  FOR SELECT USING (requesting_user_role() = 'super_admin');

-- Only super_admin can insert
CREATE POLICY "admin_audit_log_insert" ON admin_audit_log
  FOR INSERT WITH CHECK (requesting_user_role() = 'super_admin');

-- NO UPDATE or DELETE policies — this table is immutable

-- Index for querying by company and admin
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_company ON admin_audit_log (target_company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_admin ON admin_audit_log (admin_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_session ON admin_audit_log (session_id);

-- ============================================================
-- U15b: Data integrity — orphan detection function
-- ============================================================
CREATE OR REPLACE FUNCTION check_data_integrity(p_company_id UUID DEFAULT NULL)
RETURNS TABLE (
  check_name TEXT,
  entity_table TEXT,
  orphan_count BIGINT,
  details TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Photos without job_id
  RETURN QUERY
  SELECT 'photos_no_job'::TEXT, 'photos'::TEXT, COUNT(*)::BIGINT,
    'Photos not linked to any job'::TEXT
  FROM photos
  WHERE job_id IS NULL AND deleted_at IS NULL
    AND (p_company_id IS NULL OR company_id = p_company_id);

  -- Time entries without job_id
  RETURN QUERY
  SELECT 'time_entries_no_job'::TEXT, 'time_entries'::TEXT, COUNT(*)::BIGINT,
    'Time entries not linked to any job'::TEXT
  FROM time_entries
  WHERE job_id IS NULL AND deleted_at IS NULL
    AND (p_company_id IS NULL OR company_id = p_company_id);

  -- Expenses without job_id (only those that should have one)
  RETURN QUERY
  SELECT 'expenses_no_job'::TEXT, 'expenses'::TEXT, COUNT(*)::BIGINT,
    'Job-linked expenses missing job_id'::TEXT
  FROM expenses
  WHERE job_id IS NULL AND deleted_at IS NULL AND category != 'overhead'
    AND (p_company_id IS NULL OR company_id = p_company_id);

  -- Invoices without customer_id
  RETURN QUERY
  SELECT 'invoices_no_customer'::TEXT, 'invoices'::TEXT, COUNT(*)::BIGINT,
    'Invoices without customer'::TEXT
  FROM invoices
  WHERE customer_id IS NULL AND deleted_at IS NULL
    AND (p_company_id IS NULL OR company_id = p_company_id);

  -- Jobs without customer_id
  RETURN QUERY
  SELECT 'jobs_no_customer'::TEXT, 'jobs'::TEXT, COUNT(*)::BIGINT,
    'Jobs without customer'::TEXT
  FROM jobs
  WHERE customer_id IS NULL AND deleted_at IS NULL
    AND (p_company_id IS NULL OR company_id = p_company_id);

  -- Bids without customer_id
  RETURN QUERY
  SELECT 'bids_no_customer'::TEXT, 'bids'::TEXT, COUNT(*)::BIGINT,
    'Bids without customer'::TEXT
  FROM bids
  WHERE customer_id IS NULL AND deleted_at IS NULL
    AND (p_company_id IS NULL OR company_id = p_company_id);

  -- Users without company_id in metadata
  RETURN QUERY
  SELECT 'users_no_company'::TEXT, 'users'::TEXT, COUNT(*)::BIGINT,
    'Users without company_id in JWT metadata'::TEXT
  FROM users
  WHERE company_id IS NULL AND deleted_at IS NULL;

  -- Companies with no owner
  RETURN QUERY
  SELECT 'companies_no_owner'::TEXT, 'companies'::TEXT, COUNT(*)::BIGINT,
    'Companies without owner_user_id'::TEXT
  FROM companies
  WHERE owner_user_id IS NULL AND deleted_at IS NULL;
END;
$$;
