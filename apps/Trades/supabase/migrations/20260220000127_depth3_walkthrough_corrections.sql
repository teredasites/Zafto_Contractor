-- DEPTH3: Walkthrough engine corrections
-- Fixes: walkthrough_templates missing deleted_at, RLS soft-delete filter

-- 1. Add deleted_at to walkthrough_templates (soft delete compliance — Critical Rule #14)
ALTER TABLE walkthrough_templates ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- 2. Update walkthrough_templates RLS to filter soft-deleted records
-- Current policy from fix_rls migration: walkthrough_templates_access FOR ALL
DROP POLICY IF EXISTS walkthrough_templates_access ON walkthrough_templates;

-- SELECT: system templates (visible to all) + company templates (not deleted)
CREATE POLICY "walkthrough_templates_select" ON walkthrough_templates FOR SELECT USING (
  (is_system = true AND deleted_at IS NULL)
  OR (company_id = requesting_company_id() AND deleted_at IS NULL)
);

-- INSERT: only to own company
CREATE POLICY "walkthrough_templates_insert" ON walkthrough_templates FOR INSERT WITH CHECK (
  company_id = requesting_company_id()
);

-- UPDATE: only own company templates (not system)
CREATE POLICY "walkthrough_templates_update" ON walkthrough_templates FOR UPDATE USING (
  company_id = requesting_company_id() AND is_system = false
);

-- DELETE: only own company templates (not system) — for soft delete UPDATE
CREATE POLICY "walkthrough_templates_delete" ON walkthrough_templates FOR DELETE USING (
  company_id = requesting_company_id() AND is_system = false
);

-- 3. Add audit trigger on walkthrough_templates (was missing)
CREATE TRIGGER audit_walkthrough_templates
  AFTER INSERT OR UPDATE OR DELETE ON walkthrough_templates
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- 4. Index for deleted_at filter on walkthrough_templates
CREATE INDEX IF NOT EXISTS idx_walkthrough_templates_deleted
  ON walkthrough_templates (deleted_at) WHERE deleted_at IS NULL;
