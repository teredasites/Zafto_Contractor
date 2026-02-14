-- G2 Security Audit: Fix 3 tables missing RLS
-- user_sessions (HIGH RISK — has company_id, was exposed)
-- login_attempts (LOW RISK — audit log)
-- iicrc_equipment_factors (LOW RISK — reference data)

-- ============================================================
-- 1. user_sessions — company-scoped + owner/admin or own user
-- ============================================================
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_sessions_select ON user_sessions
  FOR SELECT USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND (
      (auth.jwt() -> 'app_metadata' ->> 'role') IN ('owner', 'admin', 'super_admin')
      OR user_id = auth.uid()
    )
  );

CREATE POLICY user_sessions_insert ON user_sessions
  FOR INSERT WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND user_id = auth.uid()
  );

CREATE POLICY user_sessions_update ON user_sessions
  FOR UPDATE USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND user_id = auth.uid()
  );

CREATE POLICY user_sessions_delete ON user_sessions
  FOR DELETE USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND (
      (auth.jwt() -> 'app_metadata' ->> 'role') IN ('owner', 'admin', 'super_admin')
      OR user_id = auth.uid()
    )
  );

-- ============================================================
-- 2. login_attempts — super_admin read-only, service role insert
-- ============================================================
ALTER TABLE login_attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY login_attempts_select ON login_attempts
  FOR SELECT USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin'
  );

-- Inserts happen via service role (auth triggers), no user policy needed
-- Service role bypasses RLS

-- ============================================================
-- 3. iicrc_equipment_factors — authenticated read, super_admin write
-- ============================================================
ALTER TABLE iicrc_equipment_factors ENABLE ROW LEVEL SECURITY;

CREATE POLICY iicrc_equipment_factors_select ON iicrc_equipment_factors
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY iicrc_equipment_factors_insert ON iicrc_equipment_factors
  FOR INSERT WITH CHECK (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin'
  );

CREATE POLICY iicrc_equipment_factors_update ON iicrc_equipment_factors
  FOR UPDATE USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin'
  );
