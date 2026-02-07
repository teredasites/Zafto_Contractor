-- ============================================================
-- ZAFTO CORE SCHEMA -- C3: Ops Portal Tables (Phase 1)
-- Sprint C3
--
-- Run against: dev first, then prod
-- Tables: support_tickets, support_messages, knowledge_base,
--          announcements, ops_audit_log, service_credentials
-- Depends on: A3a (companies, auth.users, update_updated_at)
-- ============================================================

-- ============================================================
-- HELPER: Auto-increment ticket number (TKT-YYYYMMDD-NNN)
-- ============================================================
CREATE OR REPLACE FUNCTION generate_ticket_number()
RETURNS text AS $$
DECLARE
  today_str text;
  seq_num integer;
  new_number text;
BEGIN
  today_str := to_char(now(), 'YYYYMMDD');
  SELECT COALESCE(MAX(
    CAST(NULLIF(split_part(ticket_number, '-', 3), '') AS integer)
  ), 0) + 1
  INTO seq_num
  FROM support_tickets
  WHERE ticket_number LIKE 'TKT-' || today_str || '-%';

  new_number := 'TKT-' || today_str || '-' || lpad(seq_num::text, 3, '0');
  RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- SUPPORT TICKETS
-- ============================================================
CREATE TABLE IF NOT EXISTS support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id),
  user_id uuid REFERENCES auth.users(id),
  ticket_number text UNIQUE NOT NULL DEFAULT generate_ticket_number(),
  subject text NOT NULL,
  description text NOT NULL,
  category text CHECK (category IN ('billing', 'bug', 'feature_request', 'how_to', 'account', 'emergency')),
  priority text DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  status text DEFAULT 'new' CHECK (status IN ('new', 'in_progress', 'waiting_customer', 'resolved', 'closed')),
  ai_category text,
  ai_priority text,
  ai_draft_response text,
  ai_root_cause text,
  resolved_at timestamptz,
  resolution_notes text,
  satisfaction_rating integer CHECK (satisfaction_rating BETWEEN 1 AND 5),
  satisfaction_comment text,
  source text DEFAULT 'in_app' CHECK (source IN ('in_app', 'email', 'chat', 'phone')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_support_tickets_company_status ON support_tickets (company_id, status, created_at DESC);

-- Updated_at trigger
CREATE TRIGGER support_tickets_updated_at BEFORE UPDATE ON support_tickets FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS: super_admin has full access
CREATE POLICY "ops_support_tickets_super_admin" ON support_tickets
  FOR ALL USING (
    (auth.jwt()->>'role')::text = 'super_admin'
  );

-- ============================================================
-- SUPPORT MESSAGES (conversation thread)
-- ============================================================
CREATE TABLE IF NOT EXISTS support_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  sender_type text NOT NULL CHECK (sender_type IN ('customer', 'admin', 'ai_auto')),
  sender_id uuid,
  message text NOT NULL,
  attachments jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE support_messages ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_support_messages_ticket ON support_messages (ticket_id, created_at);

-- RLS: super_admin has full access
CREATE POLICY "ops_support_messages_super_admin" ON support_messages
  FOR ALL USING (
    (auth.jwt()->>'role')::text = 'super_admin'
  );

-- ============================================================
-- KNOWLEDGE BASE ARTICLES
-- ============================================================
CREATE TABLE IF NOT EXISTS knowledge_base (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  content text NOT NULL,
  category text NOT NULL,
  tags jsonb DEFAULT '[]'::jsonb,
  is_published boolean DEFAULT false,
  view_count integer DEFAULT 0,
  helpful_count integer DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE knowledge_base ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_knowledge_base_slug ON knowledge_base (slug);
CREATE INDEX idx_knowledge_base_published ON knowledge_base (is_published) WHERE is_published = true;

-- Updated_at trigger
CREATE TRIGGER knowledge_base_updated_at BEFORE UPDATE ON knowledge_base FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS: super_admin has full access
CREATE POLICY "ops_knowledge_base_super_admin" ON knowledge_base
  FOR ALL USING (
    (auth.jwt()->>'role')::text = 'super_admin'
  );

-- ============================================================
-- PLATFORM ANNOUNCEMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  content text NOT NULL,
  target_audience jsonb DEFAULT '{"all": true}'::jsonb,
  is_pinned boolean DEFAULT false,
  published_at timestamptz,
  expires_at timestamptz,
  read_count integer DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- RLS: super_admin has full access
CREATE POLICY "ops_announcements_super_admin" ON announcements
  FOR ALL USING (
    (auth.jwt()->>'role')::text = 'super_admin'
  );

-- ============================================================
-- OPS AUDIT LOG (separate from customer audit_log)
-- Append-only — every ops action logged with reason
-- ============================================================
CREATE TABLE IF NOT EXISTS ops_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id uuid NOT NULL,
  action text NOT NULL,
  target_type text,
  target_id uuid,
  details jsonb,
  reason text,
  ip_address inet,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE ops_audit_log ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_ops_audit_log_admin ON ops_audit_log (admin_id, created_at DESC);

-- RLS: super_admin has full access (read + insert, no update/delete on audit)
CREATE POLICY "ops_audit_log_super_admin_select" ON ops_audit_log
  FOR SELECT USING (
    (auth.jwt()->>'role')::text = 'super_admin'
  );

CREATE POLICY "ops_audit_log_super_admin_insert" ON ops_audit_log
  FOR INSERT WITH CHECK (
    (auth.jwt()->>'role')::text = 'super_admin'
  );

-- ============================================================
-- SERVICE CREDENTIALS VAULT (encrypted at rest)
-- ============================================================
CREATE TABLE IF NOT EXISTS service_credentials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name text UNIQUE NOT NULL,
  credentials jsonb NOT NULL,
  last_rotated_at timestamptz,
  rotation_interval_days integer,
  next_rotation_at timestamptz,
  status text DEFAULT 'active' CHECK (status IN ('active', 'expired', 'revoked', 'rotating')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE service_credentials ENABLE ROW LEVEL SECURITY;

-- Updated_at trigger
CREATE TRIGGER service_credentials_updated_at BEFORE UPDATE ON service_credentials FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS: super_admin has full access
CREATE POLICY "ops_service_credentials_super_admin" ON service_credentials
  FOR ALL USING (
    (auth.jwt()->>'role')::text = 'super_admin'
  );
