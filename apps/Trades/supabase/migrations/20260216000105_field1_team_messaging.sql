-- FIELD1: Team Messaging System
-- Sprint: FIELD1 (~14h) — Real-time chat between field crews and office.
-- Tables: conversations, messages
-- RLS: company_id scoped, participant-only access
-- Indexes: optimized for conversation list + message history queries

-- ============================================================
-- CONVERSATIONS
-- ============================================================
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'direct' CHECK (type IN ('direct', 'group', 'job')),
  title TEXT,  -- null for direct (auto-derive from participants), required for group/job
  participant_ids UUID[] NOT NULL DEFAULT '{}',  -- array of user IDs
  job_id UUID REFERENCES jobs(id) ON DELETE SET NULL,  -- link to job for job-type conversations
  last_message_at TIMESTAMPTZ,
  last_message_preview TEXT,  -- first 100 chars of last message for list view
  is_archived BOOLEAN NOT NULL DEFAULT false,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT conversations_type_check CHECK (
    (type = 'direct' AND array_length(participant_ids, 1) = 2)
    OR (type IN ('group', 'job'))
  )
);

-- ============================================================
-- MESSAGES
-- ============================================================
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id),
  content TEXT,  -- null for image/file-only messages
  message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system', 'voice')),
  -- File attachments
  file_url TEXT,
  file_name TEXT,
  file_size INTEGER,  -- bytes
  file_mime_type TEXT,
  -- Read tracking
  read_by UUID[] NOT NULL DEFAULT '{}',  -- array of user IDs who have read this message
  -- Metadata
  reply_to_id UUID REFERENCES messages(id),  -- threaded replies
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,  -- extensible: typing_indicator, link_preview, etc.
  edited_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- ============================================================
-- UNREAD COUNTS (materialized for performance)
-- ============================================================
CREATE TABLE conversation_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  unread_count INTEGER NOT NULL DEFAULT 0,
  last_read_at TIMESTAMPTZ,
  is_muted BOOLEAN NOT NULL DEFAULT false,
  is_pinned BOOLEAN NOT NULL DEFAULT false,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(conversation_id, user_id)
);

-- ============================================================
-- RLS
-- ============================================================
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_members ENABLE ROW LEVEL SECURITY;

-- Conversations: company-scoped, participant-only
CREATE POLICY "conversations_select" ON conversations FOR SELECT
  TO authenticated
  USING (
    company_id = requesting_company_id()
    AND deleted_at IS NULL
    AND auth.uid() = ANY(participant_ids)
  );

CREATE POLICY "conversations_insert" ON conversations FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id = requesting_company_id()
    AND auth.uid() = ANY(participant_ids)
  );

CREATE POLICY "conversations_update" ON conversations FOR UPDATE
  TO authenticated
  USING (
    company_id = requesting_company_id()
    AND auth.uid() = ANY(participant_ids)
  );

-- Messages: company-scoped, only if user is conversation participant
CREATE POLICY "messages_select" ON messages FOR SELECT
  TO authenticated
  USING (
    company_id = requesting_company_id()
    AND deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = messages.conversation_id
      AND auth.uid() = ANY(c.participant_ids)
      AND c.deleted_at IS NULL
    )
  );

CREATE POLICY "messages_insert" ON messages FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id = requesting_company_id()
    AND sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_id
      AND auth.uid() = ANY(c.participant_ids)
    )
  );

CREATE POLICY "messages_update" ON messages FOR UPDATE
  TO authenticated
  USING (
    company_id = requesting_company_id()
    AND sender_id = auth.uid()  -- only edit own messages
  );

-- Conversation members: own records only
CREATE POLICY "conv_members_select" ON conversation_members FOR SELECT
  TO authenticated
  USING (
    company_id = requesting_company_id()
    AND user_id = auth.uid()
  );

CREATE POLICY "conv_members_update" ON conversation_members FOR UPDATE
  TO authenticated
  USING (
    company_id = requesting_company_id()
    AND user_id = auth.uid()
  );

CREATE POLICY "conv_members_insert" ON conversation_members FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id = requesting_company_id()
  );

-- ============================================================
-- INDEXES
-- ============================================================
-- Conversation list: ordered by last_message_at, filtered by company
CREATE INDEX idx_conversations_company_last_msg ON conversations(company_id, last_message_at DESC)
  WHERE deleted_at IS NULL;

-- Participant lookup: find conversations a user is in
CREATE INDEX idx_conversations_participants ON conversations USING GIN(participant_ids)
  WHERE deleted_at IS NULL;

-- Job conversations: find conversation linked to a specific job
CREATE INDEX idx_conversations_job ON conversations(job_id)
  WHERE job_id IS NOT NULL AND deleted_at IS NULL;

-- Message history: ordered by created_at within a conversation
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- Unread tracking: messages not yet read by a specific user
CREATE INDEX idx_messages_read_by ON messages USING GIN(read_by);

-- Conversation members: fast lookup
CREATE INDEX idx_conv_members_user ON conversation_members(user_id, company_id);
CREATE INDEX idx_conv_members_conversation ON conversation_members(conversation_id);

-- ============================================================
-- TRIGGERS
-- ============================================================
CREATE TRIGGER conversations_updated BEFORE UPDATE ON conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER conversations_audit AFTER INSERT OR UPDATE OR DELETE ON conversations
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER messages_audit AFTER INSERT OR UPDATE OR DELETE ON messages
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Auto-update conversation's last_message_at when a new message is inserted
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET
    last_message_at = NEW.created_at,
    last_message_preview = LEFT(NEW.content, 100)
  WHERE id = NEW.conversation_id;

  -- Increment unread count for all participants except sender
  UPDATE conversation_members
  SET unread_count = unread_count + 1
  WHERE conversation_id = NEW.conversation_id
    AND user_id != NEW.sender_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER messages_update_conversation
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_last_message();

-- ============================================================
-- REALTIME
-- ============================================================
-- Enable Supabase Realtime on messages table for live chat
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE conversation_members;

-- ============================================================
-- RPC: Bulk mark messages as read
-- ============================================================
CREATE OR REPLACE FUNCTION mark_conversation_read(
  p_conversation_id UUID,
  p_user_id UUID
) RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  -- Add user to read_by array on all unread messages in this conversation
  UPDATE messages
  SET read_by = array_append(read_by, p_user_id)
  WHERE conversation_id = p_conversation_id
    AND deleted_at IS NULL
    AND NOT (p_user_id = ANY(read_by));

  -- Reset unread count
  UPDATE conversation_members
  SET unread_count = 0, last_read_at = now()
  WHERE conversation_id = p_conversation_id
    AND user_id = p_user_id;
END;
$$;
