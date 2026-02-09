-- F3a: Meeting Room System — LiveKit
-- 5 tables: meetings, meeting_participants, meeting_captures, meeting_booking_types, async_videos
-- Company-scoped RLS + participant access for external parties

-- ============================================================================
-- 1. MEETING BOOKING TYPES (configured by company)
-- ============================================================================
CREATE TABLE meeting_booking_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  description TEXT,
  duration_minutes INTEGER NOT NULL DEFAULT 15,
  meeting_type TEXT NOT NULL DEFAULT 'virtual_estimate'
    CHECK (meeting_type IN ('site_walk', 'virtual_estimate', 'document_review', 'team_huddle', 'insurance_conference', 'subcontractor_consult', 'expert_consult')),
  available_days JSONB DEFAULT '["mon","tue","wed","thu","fri"]'::jsonb,
  available_hours JSONB DEFAULT '[{"start":"09:00","end":"17:00"}]'::jsonb,
  buffer_minutes INTEGER DEFAULT 15,
  max_per_day INTEGER DEFAULT 4,
  advance_notice_hours INTEGER DEFAULT 2,
  max_advance_days INTEGER DEFAULT 30,
  requires_approval BOOLEAN DEFAULT false,
  auto_confirm BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  show_on_website BOOLEAN DEFAULT true,
  show_on_client_portal BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(company_id, slug)
);

CREATE INDEX idx_booking_types_company ON meeting_booking_types(company_id);

-- ============================================================================
-- 2. MEETINGS (core meeting records)
-- ============================================================================
CREATE TABLE meetings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),
  claim_id UUID REFERENCES insurance_claims(id),
  title TEXT NOT NULL,
  meeting_type TEXT NOT NULL CHECK (meeting_type IN (
    'site_walk', 'virtual_estimate', 'document_review',
    'team_huddle', 'insurance_conference', 'subcontractor_consult',
    'expert_consult', 'async_video'
  )),
  room_code TEXT NOT NULL UNIQUE,
  scheduled_at TIMESTAMPTZ,
  duration_minutes INTEGER DEFAULT 30,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  actual_duration_minutes INTEGER,
  livekit_room_name TEXT,
  livekit_room_sid TEXT,
  is_recorded BOOLEAN DEFAULT false,
  recording_path TEXT,
  recording_duration_seconds INTEGER,
  consent_type TEXT DEFAULT 'none' CHECK (consent_type IN ('none', 'one_party', 'all_party')),
  consent_acknowledged JSONB DEFAULT '[]'::jsonb,
  transcript TEXT,
  ai_summary TEXT,
  ai_action_items JSONB DEFAULT '[]'::jsonb,
  ai_follow_up_draft TEXT,
  booking_type_id UUID REFERENCES meeting_booking_types(id),
  booked_by_name TEXT,
  booked_by_email TEXT,
  booked_by_phone TEXT,
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN (
    'scheduled', 'in_progress', 'completed', 'cancelled', 'no_show'
  )),
  cancelled_at TIMESTAMPTZ,
  cancel_reason TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_meetings_company_status ON meetings(company_id, status);
CREATE INDEX idx_meetings_job ON meetings(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX idx_meetings_scheduled ON meetings(company_id, scheduled_at) WHERE status = 'scheduled';
CREATE INDEX idx_meetings_room_code ON meetings(room_code);

-- ============================================================================
-- 3. MEETING PARTICIPANTS
-- ============================================================================
CREATE TABLE meeting_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  participant_type TEXT NOT NULL CHECK (participant_type IN (
    'host', 'team_member', 'client', 'adjuster', 'guest', 'subcontractor'
  )),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  can_see_context_panel BOOLEAN DEFAULT false,
  can_see_financials BOOLEAN DEFAULT false,
  can_annotate BOOLEAN DEFAULT true,
  can_record BOOLEAN DEFAULT false,
  can_share_documents BOOLEAN DEFAULT false,
  join_method TEXT CHECK (join_method IN ('app', 'browser', 'phone_bridge')),
  joined_at TIMESTAMPTZ,
  left_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  livekit_token TEXT,
  consent_acknowledged BOOLEAN DEFAULT false,
  consent_acknowledged_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_participants_meeting ON meeting_participants(meeting_id);
CREATE INDEX idx_participants_user ON meeting_participants(user_id) WHERE user_id IS NOT NULL;

-- ============================================================================
-- 4. MEETING CAPTURES (freeze-frames, photos, annotations)
-- ============================================================================
CREATE TABLE meeting_captures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id),
  capture_type TEXT NOT NULL CHECK (capture_type IN (
    'freeze_frame', 'photo', 'annotation', 'document_shared'
  )),
  timestamp_in_meeting INTEGER,
  file_path TEXT,
  thumbnail_path TEXT,
  annotation_data JSONB,
  note TEXT,
  captured_by UUID REFERENCES users(id),
  linked_to_job_photos BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_captures_meeting ON meeting_captures(meeting_id);
CREATE INDEX idx_captures_job ON meeting_captures(job_id) WHERE job_id IS NOT NULL;

-- ============================================================================
-- 5. ASYNC VIDEOS (Loom-style record + send)
-- ============================================================================
CREATE TABLE async_videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),
  title TEXT,
  video_path TEXT NOT NULL,
  thumbnail_path TEXT,
  duration_seconds INTEGER,
  file_size_bytes BIGINT,
  sent_by UUID REFERENCES users(id),
  sent_by_name TEXT NOT NULL,
  recipient_type TEXT NOT NULL CHECK (recipient_type IN (
    'client', 'team_member', 'adjuster', 'subcontractor', 'guest'
  )),
  recipient_user_id UUID REFERENCES users(id),
  recipient_name TEXT,
  recipient_email TEXT,
  message TEXT,
  share_token TEXT NOT NULL UNIQUE,
  ai_summary TEXT,
  captures JSONB DEFAULT '[]'::jsonb,
  sent_at TIMESTAMPTZ DEFAULT now(),
  viewed_at TIMESTAMPTZ,
  view_count INTEGER DEFAULT 0,
  reply_to_id UUID REFERENCES async_videos(id),
  delivered_via JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_async_videos_company ON async_videos(company_id);
CREATE INDEX idx_async_videos_job ON async_videos(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX idx_async_videos_share ON async_videos(share_token);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================
ALTER TABLE meeting_booking_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE meeting_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE meeting_captures ENABLE ROW LEVEL SECURITY;
ALTER TABLE async_videos ENABLE ROW LEVEL SECURITY;

-- Booking types: company-scoped
CREATE POLICY "booking_types_select" ON meeting_booking_types FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "booking_types_insert" ON meeting_booking_types FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "booking_types_update" ON meeting_booking_types FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "booking_types_delete" ON meeting_booking_types FOR DELETE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- Meetings: company-scoped (participants access via token, not RLS)
CREATE POLICY "meetings_select" ON meetings FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "meetings_insert" ON meetings FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "meetings_update" ON meetings FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- Participants: company-scoped
CREATE POLICY "participants_select" ON meeting_participants FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "participants_insert" ON meeting_participants FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "participants_update" ON meeting_participants FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- Captures: company-scoped
CREATE POLICY "captures_select" ON meeting_captures FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "captures_insert" ON meeting_captures FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- Async videos: company-scoped
CREATE POLICY "async_videos_select" ON async_videos FOR SELECT
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "async_videos_insert" ON async_videos FOR INSERT
  WITH CHECK (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));
CREATE POLICY "async_videos_update" ON async_videos FOR UPDATE
  USING (company_id IN (SELECT company_id FROM users WHERE id = auth.uid()));

-- ============================================================================
-- TRIGGERS
-- ============================================================================
CREATE TRIGGER set_booking_types_updated_at
  BEFORE UPDATE ON meeting_booking_types
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_meetings_updated_at
  BEFORE UPDATE ON meetings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
