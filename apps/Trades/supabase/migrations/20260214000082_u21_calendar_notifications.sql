-- U21: Calendar Sync + Notification Triggers

-- Google Calendar tokens (user-level)
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_calendar_token jsonb;
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_calendar_connected boolean NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_calendar_email text;

-- Notification preferences (JSONB toggle per trigger type)
ALTER TABLE users ADD COLUMN IF NOT EXISTS notification_preferences jsonb NOT NULL DEFAULT '{
  "invoice_overdue": {"in_app": true, "email": false, "sms": false},
  "bid_expired": {"in_app": true, "email": false, "sms": false},
  "job_past_deadline": {"in_app": true, "email": false, "sms": false},
  "cert_expiring": {"in_app": true, "email": false, "sms": false},
  "service_visit_due": {"in_app": true, "email": false, "sms": false},
  "missed_clockout": {"in_app": true, "email": false, "sms": false}
}'::jsonb;

-- Notification log table (for in-app notifications)
CREATE TABLE IF NOT EXISTS notification_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  trigger_type text NOT NULL,
  title text NOT NULL,
  body text,
  action_url text,
  entity_type text,
  entity_id uuid,
  is_read boolean NOT NULL DEFAULT false,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE notification_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notif_select" ON notification_log FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "notif_insert" ON notification_log FOR INSERT WITH CHECK (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "notif_update" ON notification_log FOR UPDATE USING (user_id = auth.uid());

-- Indexes
CREATE INDEX idx_notif_log_user ON notification_log(user_id, is_read);
CREATE INDEX idx_notif_log_company ON notification_log(company_id);
CREATE INDEX idx_notif_log_created ON notification_log(created_at DESC);
