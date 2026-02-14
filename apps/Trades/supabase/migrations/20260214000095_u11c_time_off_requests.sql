-- ============================================================
-- U11c: Time Off Requests Table
-- Sprint U11c | Portal Form Depth
-- ============================================================

CREATE TABLE time_off_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  request_type text NOT NULL DEFAULT 'vacation' CHECK (request_type IN ('vacation', 'sick', 'personal', 'bereavement', 'jury_duty', 'other')),
  start_date date NOT NULL,
  end_date date NOT NULL,
  notes text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied', 'cancelled')),
  reviewed_by uuid REFERENCES auth.users(id),
  reviewed_at timestamptz,
  review_notes text,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

ALTER TABLE time_off_requests ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_time_off_company ON time_off_requests(company_id);
CREATE INDEX idx_time_off_user ON time_off_requests(user_id);
CREATE INDEX idx_time_off_dates ON time_off_requests(start_date, end_date);
CREATE TRIGGER time_off_requests_updated_at BEFORE UPDATE ON time_off_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER time_off_requests_audit AFTER INSERT OR UPDATE OR DELETE ON time_off_requests FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- RLS: employees see own + managers see company
CREATE POLICY "time_off_select" ON time_off_requests FOR SELECT USING (
  company_id = requesting_company_id() AND (
    user_id = auth.uid() OR requesting_user_role() IN ('owner', 'admin', 'office_manager')
  )
);
CREATE POLICY "time_off_insert" ON time_off_requests FOR INSERT WITH CHECK (
  company_id = requesting_company_id() AND user_id = auth.uid()
);
CREATE POLICY "time_off_update" ON time_off_requests FOR UPDATE USING (
  company_id = requesting_company_id() AND (
    user_id = auth.uid() OR requesting_user_role() IN ('owner', 'admin', 'office_manager')
  )
);
