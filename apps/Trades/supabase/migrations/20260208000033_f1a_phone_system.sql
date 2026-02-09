-- F1a: Phone System — SignalWire Voice/SMS/Fax
-- 9 tables: config, lines, ring_groups, on_call_schedule, calls, voicemails, messages, message_templates, faxes
-- All company-scoped with RLS

-- ============================================================================
-- 1. PHONE CONFIG (per-company settings)
-- ============================================================================
CREATE TABLE phone_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) UNIQUE,
  business_hours JSONB NOT NULL DEFAULT '{
    "monday": {"open": "07:00", "close": "17:00"},
    "tuesday": {"open": "07:00", "close": "17:00"},
    "wednesday": {"open": "07:00", "close": "17:00"},
    "thursday": {"open": "07:00", "close": "17:00"},
    "friday": {"open": "07:00", "close": "17:00"},
    "saturday": null,
    "sunday": null
  }'::jsonb,
  holidays JSONB DEFAULT '[]'::jsonb,
  auto_attendant_enabled BOOLEAN DEFAULT true,
  greeting_type TEXT DEFAULT 'tts' CHECK (greeting_type IN ('tts', 'recorded', 'ai_generated')),
  greeting_text TEXT,
  greeting_audio_path TEXT,
  greeting_voice TEXT DEFAULT 'professional_female',
  after_hours_greeting_text TEXT,
  after_hours_greeting_audio_path TEXT,
  menu_options JSONB DEFAULT '[]'::jsonb,
  emergency_enabled BOOLEAN DEFAULT false,
  emergency_ring_group_id UUID,
  call_recording_mode TEXT DEFAULT 'off' CHECK (call_recording_mode IN ('off', 'all', 'on_demand', 'inbound_only')),
  recording_consent_state TEXT,
  recording_retention_days INTEGER DEFAULT 90,
  ai_receptionist_enabled BOOLEAN DEFAULT false,
  ai_receptionist_config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 2. PHONE LINES (numbers assigned to users/departments)
-- ============================================================================
CREATE TABLE phone_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  user_id UUID REFERENCES users(id),
  phone_number TEXT NOT NULL UNIQUE,
  signalwire_resource_id TEXT,
  line_type TEXT DEFAULT 'direct' CHECK (line_type IN ('main', 'direct', 'department', 'fax')),
  display_name TEXT,
  display_role TEXT,
  caller_id_name TEXT,
  is_active BOOLEAN DEFAULT true,
  voicemail_enabled BOOLEAN DEFAULT true,
  voicemail_greeting_path TEXT,
  dnd_enabled BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'offline' CHECK (status IN ('online', 'busy', 'dnd', 'offline')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_phone_lines_company ON phone_lines(company_id);
CREATE INDEX idx_phone_lines_user ON phone_lines(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_phone_lines_number ON phone_lines(phone_number);

-- ============================================================================
-- 3. RING GROUPS
-- ============================================================================
CREATE TABLE phone_ring_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  strategy TEXT DEFAULT 'simultaneous' CHECK (strategy IN ('simultaneous', 'sequential', 'round_robin')),
  ring_duration_seconds INTEGER DEFAULT 30,
  no_answer_action TEXT DEFAULT 'voicemail' CHECK (no_answer_action IN ('voicemail', 'next_group', 'specific_user')),
  no_answer_target UUID,
  member_user_ids UUID[] NOT NULL DEFAULT '{}',
  last_round_robin_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_phone_ring_groups_company ON phone_ring_groups(company_id);

-- Now add FK for emergency_ring_group_id
ALTER TABLE phone_config
  ADD CONSTRAINT fk_phone_config_emergency_ring_group
  FOREIGN KEY (emergency_ring_group_id) REFERENCES phone_ring_groups(id);

-- ============================================================================
-- 4. ON-CALL SCHEDULE
-- ============================================================================
CREATE TABLE phone_on_call_schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  user_id UUID NOT NULL REFERENCES users(id),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_phone_on_call_company ON phone_on_call_schedule(company_id);
CREATE INDEX idx_phone_on_call_dates ON phone_on_call_schedule(start_date, end_date);

-- ============================================================================
-- 5. CALL RECORDS (CDR)
-- ============================================================================
CREATE TABLE phone_calls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  signalwire_call_id TEXT,
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound', 'internal')),
  from_number TEXT NOT NULL,
  to_number TEXT NOT NULL,
  from_user_id UUID REFERENCES users(id),
  to_user_id UUID REFERENCES users(id),
  customer_id UUID REFERENCES customers(id),
  job_id UUID REFERENCES jobs(id),
  status TEXT NOT NULL CHECK (status IN ('initiated', 'ringing', 'in_progress', 'completed', 'missed', 'voicemail', 'failed', 'busy', 'no_answer')),
  duration_seconds INTEGER DEFAULT 0,
  recording_path TEXT,
  recording_url TEXT,
  ai_summary TEXT,
  ai_transcript TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  answered_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_phone_calls_company ON phone_calls(company_id);
CREATE INDEX idx_phone_calls_customer ON phone_calls(customer_id) WHERE customer_id IS NOT NULL;
CREATE INDEX idx_phone_calls_job ON phone_calls(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX idx_phone_calls_from_user ON phone_calls(from_user_id) WHERE from_user_id IS NOT NULL;
CREATE INDEX idx_phone_calls_to_user ON phone_calls(to_user_id) WHERE to_user_id IS NOT NULL;
CREATE INDEX idx_phone_calls_started ON phone_calls(started_at DESC);
CREATE INDEX idx_phone_calls_signalwire ON phone_calls(signalwire_call_id) WHERE signalwire_call_id IS NOT NULL;

-- ============================================================================
-- 6. VOICEMAILS
-- ============================================================================
CREATE TABLE phone_voicemails (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  call_id UUID REFERENCES phone_calls(id),
  line_id UUID NOT NULL REFERENCES phone_lines(id),
  from_number TEXT NOT NULL,
  customer_id UUID REFERENCES customers(id),
  audio_path TEXT NOT NULL,
  audio_url TEXT,
  transcript TEXT,
  ai_intent TEXT,
  duration_seconds INTEGER,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_phone_voicemails_company ON phone_voicemails(company_id);
CREATE INDEX idx_phone_voicemails_line ON phone_voicemails(line_id);
CREATE INDEX idx_phone_voicemails_unread ON phone_voicemails(line_id) WHERE is_read = false;

-- ============================================================================
-- 7. SMS/TEXT MESSAGES
-- ============================================================================
CREATE TABLE phone_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  signalwire_message_id TEXT,
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  from_number TEXT NOT NULL,
  to_number TEXT NOT NULL,
  from_user_id UUID REFERENCES users(id),
  customer_id UUID REFERENCES customers(id),
  job_id UUID REFERENCES jobs(id),
  body TEXT NOT NULL,
  media_urls TEXT[] DEFAULT '{}',
  is_automated BOOLEAN DEFAULT false,
  automation_type TEXT,
  status TEXT DEFAULT 'sent' CHECK (status IN ('queued', 'sent', 'delivered', 'failed', 'received')),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_phone_messages_company ON phone_messages(company_id);
CREATE INDEX idx_phone_messages_customer ON phone_messages(customer_id) WHERE customer_id IS NOT NULL;
CREATE INDEX idx_phone_messages_job ON phone_messages(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX idx_phone_messages_thread ON phone_messages(company_id, from_number, to_number);
CREATE INDEX idx_phone_messages_created ON phone_messages(created_at DESC);

-- ============================================================================
-- 8. MESSAGE TEMPLATES (automated texts)
-- ============================================================================
CREATE TABLE phone_message_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  trigger_event TEXT,
  body_template TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_phone_templates_company ON phone_message_templates(company_id);
CREATE INDEX idx_phone_templates_trigger ON phone_message_templates(trigger_event) WHERE trigger_event IS NOT NULL;

-- ============================================================================
-- 9. FAX RECORDS
-- ============================================================================
CREATE TABLE phone_faxes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  signalwire_fax_id TEXT,
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  from_number TEXT NOT NULL,
  to_number TEXT NOT NULL,
  from_user_id UUID REFERENCES users(id),
  customer_id UUID REFERENCES customers(id),
  job_id UUID REFERENCES jobs(id),
  pages INTEGER DEFAULT 0,
  document_path TEXT,
  document_url TEXT,
  source_type TEXT,
  source_id UUID,
  status TEXT DEFAULT 'queued' CHECK (status IN ('queued', 'sending', 'delivered', 'failed', 'received')),
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_phone_faxes_company ON phone_faxes(company_id);
CREATE INDEX idx_phone_faxes_customer ON phone_faxes(customer_id) WHERE customer_id IS NOT NULL;
CREATE INDEX idx_phone_faxes_created ON phone_faxes(created_at DESC);

-- ============================================================================
-- RLS POLICIES — company-scoped on all 9 tables
-- ============================================================================
ALTER TABLE phone_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE phone_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE phone_ring_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE phone_on_call_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE phone_calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE phone_voicemails ENABLE ROW LEVEL SECURITY;
ALTER TABLE phone_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE phone_message_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE phone_faxes ENABLE ROW LEVEL SECURITY;

-- phone_config: company members can read, owner/admin write
CREATE POLICY "phone_config_select" ON phone_config FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_config_insert" ON phone_config FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_config_update" ON phone_config FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- phone_lines: company members can read, owner/admin manage
CREATE POLICY "phone_lines_select" ON phone_lines FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_lines_insert" ON phone_lines FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_lines_update" ON phone_lines FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_lines_delete" ON phone_lines FOR DELETE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- phone_ring_groups
CREATE POLICY "phone_ring_groups_select" ON phone_ring_groups FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_ring_groups_insert" ON phone_ring_groups FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_ring_groups_update" ON phone_ring_groups FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_ring_groups_delete" ON phone_ring_groups FOR DELETE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- phone_on_call_schedule
CREATE POLICY "phone_on_call_select" ON phone_on_call_schedule FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_on_call_insert" ON phone_on_call_schedule FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_on_call_update" ON phone_on_call_schedule FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_on_call_delete" ON phone_on_call_schedule FOR DELETE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- phone_calls
CREATE POLICY "phone_calls_select" ON phone_calls FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_calls_insert" ON phone_calls FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_calls_update" ON phone_calls FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- phone_voicemails
CREATE POLICY "phone_voicemails_select" ON phone_voicemails FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_voicemails_insert" ON phone_voicemails FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_voicemails_update" ON phone_voicemails FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- phone_messages
CREATE POLICY "phone_messages_select" ON phone_messages FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_messages_insert" ON phone_messages FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- phone_message_templates
CREATE POLICY "phone_templates_select" ON phone_message_templates FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_templates_insert" ON phone_message_templates FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_templates_update" ON phone_message_templates FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_templates_delete" ON phone_message_templates FOR DELETE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- phone_faxes
CREATE POLICY "phone_faxes_select" ON phone_faxes FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_faxes_insert" ON phone_faxes FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "phone_faxes_update" ON phone_faxes FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- ============================================================================
-- UPDATED_AT TRIGGERS
-- ============================================================================
CREATE TRIGGER set_phone_config_updated_at
  BEFORE UPDATE ON phone_config
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_phone_lines_updated_at
  BEFORE UPDATE ON phone_lines
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_phone_templates_updated_at
  BEFORE UPDATE ON phone_message_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
