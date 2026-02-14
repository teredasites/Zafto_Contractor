-- L8: CE Tracker + Compliance Packets
-- ALTER certification_types for CE fields.
-- CREATE ce_credit_log for tracking continuing education.
-- CREATE license_renewals for renewal workflow.

-- ── ALTER certification_types ───────────────────────────
ALTER TABLE certification_types
  ADD COLUMN IF NOT EXISTS ce_credits_required numeric(6,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS renewal_period_months int DEFAULT 12,
  ADD COLUMN IF NOT EXISTS state_code text,
  ADD COLUMN IF NOT EXISTS governing_body text,
  ADD COLUMN IF NOT EXISTS ce_categories jsonb DEFAULT '[]'::jsonb;

COMMENT ON COLUMN certification_types.ce_credits_required IS 'Total CE credits needed for renewal';
COMMENT ON COLUMN certification_types.renewal_period_months IS 'Months between renewals';
COMMENT ON COLUMN certification_types.ce_categories IS 'JSON array of accepted CE category types';

-- ── ce_credit_log ───────────────────────────────────────
CREATE TABLE ce_credit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  certification_id uuid REFERENCES certifications(id),
  course_name text NOT NULL,
  provider text,
  credit_hours numeric(6,2) NOT NULL,
  ce_category text,
  completion_date date NOT NULL,
  certificate_document_path text,
  verified boolean DEFAULT false,
  verified_by uuid REFERENCES auth.users(id),
  verified_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE ce_credit_log ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER ce_credit_log_updated BEFORE UPDATE ON ce_credit_log
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER ce_credit_log_audit AFTER INSERT OR UPDATE OR DELETE ON ce_credit_log
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE INDEX idx_ce_credit_company ON ce_credit_log (company_id);
CREATE INDEX idx_ce_credit_user ON ce_credit_log (user_id);
CREATE INDEX idx_ce_credit_cert ON ce_credit_log (certification_id);

CREATE POLICY ce_credit_select ON ce_credit_log
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY ce_credit_insert ON ce_credit_log
  FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY ce_credit_update ON ce_credit_log
  FOR UPDATE USING (company_id = requesting_company_id() AND (
    requesting_user_role() IN ('owner', 'admin', 'office_manager') OR user_id = auth.uid()
  ));

-- ── license_renewals ────────────────────────────────────
CREATE TABLE license_renewals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  certification_id uuid NOT NULL REFERENCES certifications(id),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  renewal_due_date date NOT NULL,
  ce_credits_required numeric(6,2) DEFAULT 0,
  ce_credits_completed numeric(6,2) DEFAULT 0,
  ce_credits_remaining numeric(6,2) GENERATED ALWAYS AS (GREATEST(ce_credits_required - ce_credits_completed, 0)) STORED,
  status text NOT NULL DEFAULT 'upcoming' CHECK (status IN (
    'upcoming', 'in_progress', 'pending_approval', 'completed', 'overdue', 'waived'
  )),
  renewal_fee numeric(10,2),
  fee_paid boolean DEFAULT false,
  submitted_date date,
  approved_date date,
  new_expiration_date date,
  document_path text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE license_renewals ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER license_renewals_updated BEFORE UPDATE ON license_renewals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER license_renewals_audit AFTER INSERT OR UPDATE OR DELETE ON license_renewals
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE INDEX idx_renewals_company ON license_renewals (company_id);
CREATE INDEX idx_renewals_user ON license_renewals (user_id);
CREATE INDEX idx_renewals_cert ON license_renewals (certification_id);
CREATE INDEX idx_renewals_due ON license_renewals (renewal_due_date);

CREATE POLICY renewals_select ON license_renewals
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY renewals_insert ON license_renewals
  FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY renewals_update ON license_renewals
  FOR UPDATE USING (company_id = requesting_company_id());

-- ── Aggregation function: CE credits by user/certification ──
CREATE OR REPLACE FUNCTION get_ce_credits_summary(
  p_user_id uuid,
  p_certification_id uuid DEFAULT NULL
)
RETURNS TABLE (
  total_credits numeric,
  credit_count bigint,
  categories jsonb
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(SUM(cl.credit_hours), 0)::numeric AS total_credits,
    COUNT(cl.id) AS credit_count,
    COALESCE(jsonb_agg(DISTINCT jsonb_build_object(
      'category', cl.ce_category,
      'hours', cl.credit_hours
    )) FILTER (WHERE cl.ce_category IS NOT NULL), '[]'::jsonb) AS categories
  FROM ce_credit_log cl
  WHERE cl.user_id = p_user_id
    AND (p_certification_id IS NULL OR cl.certification_id = p_certification_id)
    AND cl.verified = true;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_ce_credits_summary TO authenticated;
