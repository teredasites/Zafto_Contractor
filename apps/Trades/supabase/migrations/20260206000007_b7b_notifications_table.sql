-- ============================================================
-- ZAFTO CORE SCHEMA — B7b: Notifications Table
-- Sprint B7b | Session 55
--
-- Run against: dev first, then prod
-- Tables: notifications
-- Depends on: A3a (companies, auth.users, audit_trigger_fn)
-- ============================================================

CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text NOT NULL,
  type text NOT NULL CHECK (type IN (
    'job_assigned',
    'invoice_paid',
    'bid_accepted',
    'bid_rejected',
    'change_order_approved',
    'change_order_rejected',
    'time_entry_approved',
    'time_entry_rejected',
    'customer_message',
    'dead_man_switch',
    'system'
  )),
  entity_type text,  -- 'job', 'invoice', 'bid', 'change_order', 'time_entry', etc.
  entity_id uuid,
  is_read boolean NOT NULL DEFAULT false,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_notifications_user_unread ON notifications (user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_company ON notifications (company_id, created_at DESC);

-- Audit trigger (tracks inserts + updates via audit_log)
CREATE TRIGGER notifications_audit AFTER INSERT OR UPDATE OR DELETE ON notifications FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- RLS: Users can only see their own notifications
CREATE POLICY "notifications_select" ON notifications FOR SELECT USING (user_id = auth.uid());

-- RLS: Users can only update their own notifications (mark as read)
CREATE POLICY "notifications_update" ON notifications FOR UPDATE USING (user_id = auth.uid());

-- RLS: Insert scoped to company (service role or edge functions insert on behalf of users)
CREATE POLICY "notifications_insert" ON notifications FOR INSERT WITH CHECK (company_id = requesting_company_id());
