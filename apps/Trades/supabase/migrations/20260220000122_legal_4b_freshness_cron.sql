-- LEGAL-4b: Freshness check function + system_alerts table
-- S143: Automated staleness detection for legal references

-- ============================================================
-- system_alerts — Platform-wide alert/notification queue for ops portal
-- ============================================================
CREATE TABLE IF NOT EXISTS system_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type TEXT NOT NULL, -- 'compliance_stale', 'system_error', 'usage_spike', etc.
  severity TEXT NOT NULL DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
  title TEXT NOT NULL,
  message TEXT,
  metadata JSONB DEFAULT '{}',
  acknowledged_at TIMESTAMPTZ,
  acknowledged_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE system_alerts ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER system_alerts_audit AFTER INSERT OR UPDATE OR DELETE ON system_alerts FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "system_alerts_select" ON system_alerts FOR SELECT USING (
  requesting_user_role() = 'super_admin'
);
CREATE POLICY "system_alerts_modify" ON system_alerts FOR ALL USING (
  requesting_user_role() = 'super_admin'
);

CREATE INDEX idx_system_alerts_type ON system_alerts (alert_type);
CREATE INDEX idx_system_alerts_created ON system_alerts (created_at DESC);
CREATE INDEX idx_system_alerts_unacked ON system_alerts (acknowledged_at) WHERE acknowledged_at IS NULL;

-- ============================================================
-- check_legal_freshness() — Called by pg_cron weekly
-- ============================================================
-- For each reference with a review cycle:
--   If NOW() - last_verified_at > next_review_cycle → status = 'review_due'
--   If NOW() - last_verified_at > next_review_cycle * 1.5 → status = 'outdated'
-- Inserts system_alerts for any newly stale references
-- ============================================================
CREATE OR REPLACE FUNCTION check_legal_freshness()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  ref RECORD;
  new_status legal_reference_status;
  alert_count INT := 0;
BEGIN
  FOR ref IN
    SELECT id, display_name, status, last_verified_at, next_review_cycle
    FROM legal_reference_registry
    WHERE next_review_cycle IS NOT NULL
      AND status NOT IN ('superseded')
  LOOP
    -- Determine new status based on staleness
    IF NOW() - ref.last_verified_at > ref.next_review_cycle * 1.5 THEN
      new_status := 'outdated';
    ELSIF NOW() - ref.last_verified_at > ref.next_review_cycle THEN
      new_status := 'review_due';
    ELSE
      new_status := 'current';
    END IF;

    -- Only update if status changed
    IF new_status != ref.status THEN
      UPDATE legal_reference_registry
      SET status = new_status, updated_at = now()
      WHERE id = ref.id;

      -- Insert alert for newly stale items
      IF new_status IN ('review_due', 'outdated') THEN
        INSERT INTO system_alerts (alert_type, severity, title, message, metadata)
        VALUES (
          'compliance_stale',
          CASE WHEN new_status = 'outdated' THEN 'critical' ELSE 'warning' END,
          'Legal reference needs review: ' || ref.display_name,
          'Last verified ' || EXTRACT(DAY FROM NOW() - ref.last_verified_at)::INT || ' days ago. Review cycle: ' || ref.next_review_cycle::TEXT,
          jsonb_build_object('reference_id', ref.id, 'new_status', new_status::TEXT)
        );
        alert_count := alert_count + 1;
      END IF;
    END IF;
  END LOOP;

  -- Log summary if any alerts were created
  IF alert_count > 0 THEN
    INSERT INTO system_alerts (alert_type, severity, title, message)
    VALUES (
      'compliance_check_complete',
      'info',
      'Weekly compliance check complete',
      alert_count || ' reference(s) flagged for review'
    );
  END IF;
END;
$$;

-- ============================================================
-- pg_cron schedule (run in Supabase Dashboard > Database > Extensions > pg_cron)
-- Schedule: SELECT cron.schedule('check-legal-freshness', '0 8 * * 1', 'SELECT check_legal_freshness()');
-- Runs every Monday at 8am UTC
-- ============================================================
-- NOTE: pg_cron must be enabled in Supabase Dashboard first.
-- The function above works standalone — can be called manually:
-- SELECT check_legal_freshness();
