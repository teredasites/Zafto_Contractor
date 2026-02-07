-- ============================================================
-- CLIENT PORTAL USERS TABLE
-- Links Supabase auth users to customers for the client portal.
-- A contractor invites a client → row created here → client can see their projects/invoices.
-- ============================================================

CREATE TABLE IF NOT EXISTS client_portal_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  display_name text,
  permissions jsonb DEFAULT '{"view_projects": true, "view_invoices": true, "view_bids": true, "request_service": true}'::jsonb,
  invited_by uuid REFERENCES users(id),
  invited_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE(auth_user_id, company_id)
);

-- RLS
ALTER TABLE client_portal_users ENABLE ROW LEVEL SECURITY;

-- Clients can read their own row
CREATE POLICY client_portal_users_self_read ON client_portal_users
  FOR SELECT USING (auth_user_id = auth.uid());

-- Company staff (owner/admin/office) can manage client portal users
CREATE POLICY client_portal_users_company_manage ON client_portal_users
  FOR ALL USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid() AND role IN ('owner', 'admin', 'office_manager')
    )
  );

-- Super admin full access
CREATE POLICY client_portal_users_super_admin ON client_portal_users
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'super_admin')
  );

-- Updated_at trigger
CREATE TRIGGER set_updated_at_client_portal_users
  BEFORE UPDATE ON client_portal_users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
