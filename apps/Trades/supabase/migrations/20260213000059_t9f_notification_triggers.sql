-- T9f: TPA Notification Triggers
-- Configurable notification rules for TPA events.
-- Push + SMS to assigned tech, escalation to owner/admin on SLA breach.

-- ============================================================================
-- TABLE: NOTIFICATION TRIGGERS — event-based notification rules
-- ============================================================================

CREATE TABLE notification_triggers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),  -- NULL = system-wide defaults
  -- Trigger identity
  trigger_key TEXT NOT NULL,  -- unique key, e.g., 'tpa_assignment_received'
  name TEXT NOT NULL,
  description TEXT,
  -- Event configuration
  event_type TEXT NOT NULL,  -- 'tpa_assignment', 'sla_warning', 'sla_breach', 'sla_overdue', etc.
  event_condition JSONB DEFAULT '{}'::jsonb,  -- optional conditions like {"loss_type": "water"}
  -- Timing
  timing TEXT DEFAULT 'immediate' CHECK (timing IN ('immediate', 'delayed', 'scheduled')),
  delay_minutes INTEGER DEFAULT 0,  -- for delayed triggers (e.g., 30 min before deadline)
  -- Recipients
  recipient_roles TEXT[] DEFAULT '{}',  -- e.g., ['technician', 'owner', 'admin']
  recipient_user_ids UUID[] DEFAULT '{}',  -- specific users
  notify_ops BOOLEAN DEFAULT false,  -- also flag in Ops Portal
  -- Channels
  push_enabled BOOLEAN DEFAULT true,
  sms_enabled BOOLEAN DEFAULT false,
  email_enabled BOOLEAN DEFAULT false,
  in_app_enabled BOOLEAN DEFAULT true,
  -- Template
  title_template TEXT NOT NULL,  -- supports {{variables}}
  body_template TEXT NOT NULL,
  -- State
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE notification_triggers ENABLE ROW LEVEL SECURITY;

CREATE POLICY nt_select ON notification_triggers
  FOR SELECT USING (
    company_id IS NULL
    OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY nt_modify ON notification_triggers
  FOR ALL USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_nt_company ON notification_triggers(company_id);
CREATE INDEX idx_nt_event ON notification_triggers(event_type);
CREATE INDEX idx_nt_key ON notification_triggers(trigger_key);
CREATE INDEX idx_nt_active ON notification_triggers(is_active) WHERE is_active = true;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER nt_updated BEFORE UPDATE ON notification_triggers FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- SEED: TPA notification triggers (system defaults)
-- ============================================================================

INSERT INTO notification_triggers (company_id, trigger_key, name, description, event_type, timing, delay_minutes, recipient_roles, notify_ops, push_enabled, sms_enabled, title_template, body_template) VALUES
-- Assignment received
(NULL, 'tpa_assignment_received', 'TPA Assignment Received', 'Notify when a new TPA assignment is received', 'tpa_assignment', 'immediate', 0,
 ARRAY['technician', 'owner', 'admin'], false, true, true,
 'New TPA Assignment: {{claim_number}}',
 '{{program_name}} — {{loss_type}} at {{address}}. SLA deadline: {{sla_deadline}}. Tap to view.'),

-- 30 min SLA warning
(NULL, 'tpa_sla_warning_30m', 'SLA Deadline Warning (30 min)', 'Alert 30 minutes before SLA deadline', 'sla_warning', 'delayed', 30,
 ARRAY['technician', 'office_manager'], false, true, true,
 'SLA Warning: 30 min remaining',
 'Assignment {{claim_number}} SLA deadline approaching. Current status: {{status}}. Take action now.'),

-- SLA deadline reached
(NULL, 'tpa_sla_deadline', 'SLA Deadline Reached', 'Escalation when SLA deadline is reached', 'sla_breach', 'immediate', 0,
 ARRAY['owner', 'admin'], true, true, true,
 'SLA BREACH: {{claim_number}}',
 'TPA assignment {{claim_number}} has breached its SLA deadline. Program: {{program_name}}. Status: {{status}}. Immediate action required.'),

-- SLA overdue
(NULL, 'tpa_sla_overdue', 'SLA Overdue Alert', 'Critical alert when SLA is past due', 'sla_overdue', 'immediate', 0,
 ARRAY['owner', 'admin', 'office_manager', 'technician'], true, true, true,
 'OVERDUE: {{claim_number}} past SLA',
 'Assignment {{claim_number}} is OVERDUE. SLA was {{sla_deadline}}. This may affect your scorecard. Resolve immediately.');
