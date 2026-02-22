-- ============================================================
-- DEPTH38 — Time Clock Permission-Based Adjustment
-- Manager/admin can adjust employee clock-in/out times.
-- Full audit trail with before/after values, reason required.
-- ============================================================

-- ── timeclock_adjustments ──
-- Audit trail for every time entry adjustment
CREATE TABLE timeclock_adjustments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  time_entry_id uuid NOT NULL REFERENCES time_entries(id) ON DELETE CASCADE,
  adjusted_by uuid NOT NULL REFERENCES auth.users(id),
  employee_id uuid NOT NULL REFERENCES auth.users(id),

  -- Original values
  original_clock_in timestamptz NOT NULL,
  original_clock_out timestamptz,
  original_break_minutes int,

  -- Adjusted values
  adjusted_clock_in timestamptz NOT NULL,
  adjusted_clock_out timestamptz,
  adjusted_break_minutes int,

  -- Reason is mandatory — can't adjust without explaining
  reason text NOT NULL CHECK (char_length(reason) >= 5),

  -- Metadata
  adjustment_type text NOT NULL DEFAULT 'manual'
    CHECK (adjustment_type IN ('manual', 'correction', 'missed_punch', 'break_adjustment', 'job_reassignment')),
  ip_address text,
  user_agent text,

  -- Notification tracking
  employee_notified boolean NOT NULL DEFAULT false,
  employee_acknowledged_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE timeclock_adjustments ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_timeclock_adj_company ON timeclock_adjustments (company_id);
CREATE INDEX idx_timeclock_adj_entry ON timeclock_adjustments (time_entry_id);
CREATE INDEX idx_timeclock_adj_employee ON timeclock_adjustments (company_id, employee_id);
CREATE INDEX idx_timeclock_adj_by ON timeclock_adjustments (adjusted_by);
CREATE INDEX idx_timeclock_adj_created ON timeclock_adjustments (created_at DESC);

CREATE TRIGGER timeclock_adjustments_audit
  AFTER INSERT OR UPDATE OR DELETE ON timeclock_adjustments
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- RLS: Company-scoped, only managers can insert, everyone in company can view
CREATE POLICY "timeclock_adj_select" ON timeclock_adjustments
  FOR SELECT USING (company_id = requesting_company_id());

CREATE POLICY "timeclock_adj_insert" ON timeclock_adjustments
  FOR INSERT WITH CHECK (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'office_manager', 'super_admin')
  );

-- No update/delete — adjustments are immutable audit records

-- ── Add deleted_at to time_entries if missing ──
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'time_entries' AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE time_entries ADD COLUMN deleted_at timestamptz;
    CREATE INDEX idx_time_entries_deleted ON time_entries (deleted_at) WHERE deleted_at IS NULL;
  END IF;
END $$;

-- ── Add last_adjusted_at and last_adjusted_by to time_entries ──
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'time_entries' AND column_name = 'last_adjusted_at'
  ) THEN
    ALTER TABLE time_entries ADD COLUMN last_adjusted_at timestamptz;
    ALTER TABLE time_entries ADD COLUMN last_adjusted_by uuid REFERENCES auth.users(id);
  END IF;
END $$;
