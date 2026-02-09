-- F4a: Mobile Field Toolkit — Communication + Inspection tables
-- Tables: walkie_talkie_channels, walkie_talkie_messages, team_messages, team_message_reads,
--         inspection_templates, inspection_results, osha_standards
-- Note: moisture_readings, drying_logs, restoration_equipment already exist (D2)
-- Note: walkthroughs, walkthrough_rooms, walkthrough_photos, walkthrough_templates, property_floor_plans already exist (E6a)

-- ============================================================================
-- 1. WALKIE-TALKIE CHANNELS (LiveKit audio rooms for PTT)
-- ============================================================================
CREATE TABLE walkie_talkie_channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),
  name TEXT NOT NULL,
  channel_type TEXT NOT NULL CHECK (channel_type IN ('job', 'crew', 'company', 'direct')),
  livekit_room_name TEXT,
  member_user_ids UUID[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  logging_mode TEXT DEFAULT 'ephemeral' CHECK (logging_mode IN ('ephemeral', 'recent', 'full_logging', 'audio_logging')),
  max_participants INTEGER DEFAULT 20,
  auto_archive_on_job_complete BOOLEAN DEFAULT true,
  archived_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_walkie_channels_company ON walkie_talkie_channels(company_id, is_active);
CREATE INDEX idx_walkie_channels_job ON walkie_talkie_channels(job_id) WHERE job_id IS NOT NULL;

-- ============================================================================
-- 2. WALKIE-TALKIE MESSAGES (PTT voice logs)
-- ============================================================================
CREATE TABLE walkie_talkie_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  channel_id UUID NOT NULL REFERENCES walkie_talkie_channels(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id),
  sender_id UUID NOT NULL REFERENCES users(id),
  sender_name TEXT NOT NULL,
  duration_seconds INTEGER,
  transcript TEXT,
  audio_path TEXT,
  sent_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_ptt_messages_channel ON walkie_talkie_messages(channel_id, sent_at DESC);
CREATE INDEX idx_ptt_messages_job ON walkie_talkie_messages(job_id) WHERE job_id IS NOT NULL;

-- ============================================================================
-- 3. TEAM MESSAGES (text chat between team members)
-- ============================================================================
CREATE TABLE team_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  channel_type TEXT NOT NULL CHECK (channel_type IN ('job', 'crew', 'company', 'direct')),
  channel_id TEXT NOT NULL,
  job_id UUID REFERENCES jobs(id),
  sender_id UUID NOT NULL REFERENCES users(id),
  sender_name TEXT NOT NULL,
  message_text TEXT,
  attachment_path TEXT,
  attachment_type TEXT CHECK (attachment_type IN ('image', 'document', 'voice_note')),
  mentioned_user_ids UUID[] DEFAULT '{}',
  is_edited BOOLEAN DEFAULT false,
  edited_at TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_team_messages_channel ON team_messages(company_id, channel_type, channel_id, created_at DESC);
CREATE INDEX idx_team_messages_job ON team_messages(job_id, created_at DESC) WHERE job_id IS NOT NULL;

-- ============================================================================
-- 4. TEAM MESSAGE READS (read receipts)
-- ============================================================================
CREATE TABLE team_message_reads (
  user_id UUID NOT NULL REFERENCES users(id),
  channel_type TEXT NOT NULL,
  channel_id TEXT NOT NULL,
  last_read_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, channel_type, channel_id)
);

-- ============================================================================
-- 5. INSPECTION TEMPLATES (configurable checklists)
-- ============================================================================
CREATE TABLE inspection_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),
  trade TEXT,
  category TEXT DEFAULT 'inspection' CHECK (category IN ('inspection', 'safety', 'quality', 'survey')),
  name TEXT NOT NULL,
  description TEXT,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_system BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_inspection_templates_company ON inspection_templates(company_id) WHERE company_id IS NOT NULL;
CREATE INDEX idx_inspection_templates_system ON inspection_templates(is_system) WHERE is_system = true;

-- ============================================================================
-- 6. INSPECTION RESULTS (completed inspections)
-- ============================================================================
CREATE TABLE inspection_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),
  template_id UUID REFERENCES inspection_templates(id),
  title TEXT NOT NULL,
  inspector_id UUID NOT NULL REFERENCES users(id),
  inspector_name TEXT NOT NULL,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  total_items INTEGER DEFAULT 0,
  passed_items INTEGER DEFAULT 0,
  failed_items INTEGER DEFAULT 0,
  na_items INTEGER DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'signed')),
  completed_at TIMESTAMPTZ,
  signature_path TEXT,
  overall_result TEXT CHECK (overall_result IN ('pass', 'fail', 'conditional')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_inspection_results_company ON inspection_results(company_id);
CREATE INDEX idx_inspection_results_job ON inspection_results(job_id) WHERE job_id IS NOT NULL;

-- ============================================================================
-- 7. OSHA STANDARDS (cached regulatory data)
-- ============================================================================
CREATE TABLE osha_standards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  standard_number TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  part TEXT NOT NULL,
  subpart TEXT,
  section TEXT,
  trade_tags TEXT[] DEFAULT '{}',
  sic_codes TEXT[] DEFAULT '{}',
  naics_codes TEXT[] DEFAULT '{}',
  is_frequently_cited BOOLEAN DEFAULT false,
  penalty_range_min NUMERIC(10,2),
  penalty_range_max NUMERIC(10,2),
  effective_date DATE,
  last_updated DATE,
  full_text TEXT,
  url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_osha_standards_number ON osha_standards(standard_number);
CREATE INDEX idx_osha_trade_tags ON osha_standards USING gin(trade_tags);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================
ALTER TABLE walkie_talkie_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE walkie_talkie_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_message_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE inspection_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE inspection_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE osha_standards ENABLE ROW LEVEL SECURITY;

-- Walkie channels: company-scoped
CREATE POLICY "walkie_channels_select" ON walkie_talkie_channels FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "walkie_channels_insert" ON walkie_talkie_channels FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "walkie_channels_update" ON walkie_talkie_channels FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- Walkie messages: company-scoped
CREATE POLICY "walkie_messages_select" ON walkie_talkie_messages FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "walkie_messages_insert" ON walkie_talkie_messages FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- Team messages: company-scoped
CREATE POLICY "team_messages_select" ON team_messages FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "team_messages_insert" ON team_messages FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "team_messages_update" ON team_messages FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- Team message reads: user's own reads
CREATE POLICY "team_reads_select" ON team_message_reads FOR SELECT
  USING (user_id = auth.uid());
CREATE POLICY "team_reads_upsert" ON team_message_reads FOR INSERT
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "team_reads_update" ON team_message_reads FOR UPDATE
  USING (user_id = auth.uid());

-- Inspection templates: company-scoped + system templates visible to all
CREATE POLICY "inspection_templates_select" ON inspection_templates FOR SELECT
  USING (is_system = true OR company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "inspection_templates_insert" ON inspection_templates FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "inspection_templates_update" ON inspection_templates FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- Inspection results: company-scoped
CREATE POLICY "inspection_results_select" ON inspection_results FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "inspection_results_insert" ON inspection_results FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "inspection_results_update" ON inspection_results FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- OSHA standards: readable by all authenticated users
CREATE POLICY "osha_standards_select" ON osha_standards FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- ============================================================================
-- TRIGGERS
-- ============================================================================
CREATE TRIGGER set_walkie_channels_updated_at
  BEFORE UPDATE ON walkie_talkie_channels
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_inspection_templates_updated_at
  BEFORE UPDATE ON inspection_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_inspection_results_updated_at
  BEFORE UPDATE ON inspection_results
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_osha_standards_updated_at
  BEFORE UPDATE ON osha_standards
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
