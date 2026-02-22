-- ============================================================
-- RE1: Portal Scaffold + Auth + RBAC
-- Migration 000156
--
-- Foundation for the entire Zafto Realtor platform.
-- Adds company_type to companies table, extends user roles,
-- creates realtor teams, portal settings, and RBAC tables.
--
-- New tables:
--   realtor_teams             (team hierarchy under brokerage)
--   realtor_team_members      (user↔team membership)
--   realtor_portal_settings   (brokerage branding/config, 1:1 with companies)
--   realtor_role_permissions  (per-company granular permission matrix)
--
-- Alters:
--   companies   (add company_type column)
--   users       (expand role CHECK to include 7 realtor roles)
-- ============================================================

-- ============================================================
-- 1. ADD company_type TO companies
--    All existing companies default to 'contractor'.
--    Nine entity types supported.
-- ============================================================

ALTER TABLE companies ADD COLUMN IF NOT EXISTS company_type TEXT NOT NULL DEFAULT 'contractor'
  CHECK (company_type IN (
    'contractor', 'realtor_solo', 'realtor_team', 'brokerage',
    'inspector', 'adjuster', 'preservation', 'homeowner', 'hybrid'
  ));

CREATE INDEX IF NOT EXISTS idx_companies_company_type ON companies (company_type);


-- ============================================================
-- 2. EXTEND users.role CHECK to include 7 new realtor roles
--    Existing: owner, admin, office_manager, technician, apprentice, cpa, super_admin
--    New: brokerage_owner, managing_broker, team_lead, realtor, tc, isa, office_admin
--    Also add: inspector, adjuster, preservation_tech, homeowner
--    for future entity types.
-- ============================================================

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (
  role IN (
    -- Existing contractor roles
    'owner', 'admin', 'office_manager', 'technician', 'apprentice', 'cpa', 'super_admin',
    -- Realtor roles (7 new)
    'brokerage_owner', 'managing_broker', 'team_lead', 'realtor', 'tc', 'isa', 'office_admin',
    -- Future entity type roles
    'inspector', 'adjuster', 'preservation_tech', 'homeowner'
  )
);


-- ============================================================
-- 3. REALTOR TEAMS
--    Team hierarchy under a brokerage. Supports nested teams
--    via parent_team_id self-reference.
-- ============================================================

CREATE TABLE IF NOT EXISTS realtor_teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  name TEXT NOT NULL,
  description TEXT,
  team_lead_user_id UUID REFERENCES auth.users(id),
  parent_team_id UUID REFERENCES realtor_teams(id),

  -- Team config
  is_active BOOLEAN NOT NULL DEFAULT true,
  settings JSONB DEFAULT '{}'::jsonb,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_realtor_teams_company ON realtor_teams(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_realtor_teams_lead ON realtor_teams(team_lead_user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_realtor_teams_parent ON realtor_teams(parent_team_id) WHERE deleted_at IS NULL;

ALTER TABLE realtor_teams ENABLE ROW LEVEL SECURITY;

CREATE POLICY rt_select ON realtor_teams FOR SELECT TO authenticated
  USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY rt_insert ON realtor_teams FOR INSERT TO authenticated
  WITH CHECK (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'brokerage_owner', 'managing_broker', 'team_lead')
  );
CREATE POLICY rt_update ON realtor_teams FOR UPDATE TO authenticated
  USING (
    company_id = requesting_company_id() AND deleted_at IS NULL
    AND requesting_user_role() IN ('owner', 'admin', 'brokerage_owner', 'managing_broker', 'team_lead')
  );
CREATE POLICY rt_delete ON realtor_teams FOR DELETE TO authenticated
  USING (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'brokerage_owner', 'managing_broker')
  );

SELECT update_updated_at('realtor_teams');
CREATE TRIGGER realtor_teams_audit AFTER INSERT OR UPDATE OR DELETE ON realtor_teams
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 4. REALTOR TEAM MEMBERS
--    Junction: user ↔ team. One user can belong to one team.
--    Role within team: lead, member, isa, tc, admin.
-- ============================================================

CREATE TABLE IF NOT EXISTS realtor_team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES realtor_teams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  role TEXT NOT NULL DEFAULT 'member'
    CHECK (role IN ('lead', 'member', 'isa', 'tc', 'admin')),

  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  left_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT true,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,

  UNIQUE(team_id, user_id)
);

CREATE INDEX idx_rtm_company ON realtor_team_members(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_rtm_user ON realtor_team_members(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_rtm_team ON realtor_team_members(team_id) WHERE deleted_at IS NULL;

ALTER TABLE realtor_team_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY rtm_select ON realtor_team_members FOR SELECT TO authenticated
  USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY rtm_insert ON realtor_team_members FOR INSERT TO authenticated
  WITH CHECK (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'brokerage_owner', 'managing_broker', 'team_lead')
  );
CREATE POLICY rtm_update ON realtor_team_members FOR UPDATE TO authenticated
  USING (
    company_id = requesting_company_id() AND deleted_at IS NULL
    AND requesting_user_role() IN ('owner', 'admin', 'brokerage_owner', 'managing_broker', 'team_lead')
  );
CREATE POLICY rtm_delete ON realtor_team_members FOR DELETE TO authenticated
  USING (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'brokerage_owner', 'managing_broker')
  );

SELECT update_updated_at('realtor_team_members');
CREATE TRIGGER rtm_audit AFTER INSERT OR UPDATE OR DELETE ON realtor_team_members
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 5. REALTOR PORTAL SETTINGS
--    One-to-one with companies (UNIQUE on company_id).
--    Brokerage branding, MLS config, office details,
--    feature flags, business hours.
-- ============================================================

CREATE TABLE IF NOT EXISTS realtor_portal_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE UNIQUE,

  -- Brokerage identity
  brokerage_name TEXT,
  brokerage_license_number TEXT,
  brokerage_license_state TEXT,
  designated_broker_user_id UUID REFERENCES auth.users(id),

  -- Branding
  primary_color TEXT DEFAULT '#0a0a0a',
  accent_color TEXT DEFAULT '#3b82f6',
  logo_url TEXT,
  dark_logo_url TEXT,
  email_signature_html TEXT,

  -- Commission
  default_commission_rate DECIMAL(5,3) DEFAULT 3.000,

  -- MLS / service areas
  mls_ids TEXT[] DEFAULT '{}',
  service_areas TEXT[] DEFAULT '{}',

  -- Office details
  office_phone TEXT,
  office_address TEXT,
  office_city TEXT,
  office_state TEXT,
  office_zip TEXT,
  timezone TEXT DEFAULT 'America/New_York',

  -- Business hours (JSONB per day)
  business_hours JSONB DEFAULT '{
    "mon": {"start": "09:00", "end": "17:00"},
    "tue": {"start": "09:00", "end": "17:00"},
    "wed": {"start": "09:00", "end": "17:00"},
    "thu": {"start": "09:00", "end": "17:00"},
    "fri": {"start": "09:00", "end": "17:00"}
  }'::jsonb,

  -- Feature flags
  features_enabled JSONB DEFAULT '{
    "cma": true,
    "transactions": true,
    "seller_finder": true,
    "dispatch": true,
    "marketing": true,
    "showings": true,
    "lead_gen": true,
    "brokerage_admin": true
  }'::jsonb,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE realtor_portal_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY rps_select ON realtor_portal_settings FOR SELECT TO authenticated
  USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY rps_insert ON realtor_portal_settings FOR INSERT TO authenticated
  WITH CHECK (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'brokerage_owner', 'managing_broker')
  );
CREATE POLICY rps_update ON realtor_portal_settings FOR UPDATE TO authenticated
  USING (
    company_id = requesting_company_id() AND deleted_at IS NULL
    AND requesting_user_role() IN ('owner', 'admin', 'brokerage_owner', 'managing_broker')
  );
CREATE POLICY rps_delete ON realtor_portal_settings FOR DELETE TO authenticated
  USING (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'brokerage_owner')
  );

SELECT update_updated_at('realtor_portal_settings');
CREATE TRIGGER rps_audit AFTER INSERT OR UPDATE OR DELETE ON realtor_portal_settings
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 6. REALTOR ROLE PERMISSIONS
--    Granular permission matrix: 7 roles x N permission keys.
--    Each company can override defaults.
--    UNIQUE(company_id, role_name, permission_key).
-- ============================================================

CREATE TABLE IF NOT EXISTS realtor_role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  role_name TEXT NOT NULL
    CHECK (role_name IN (
      'brokerage_owner', 'managing_broker', 'team_lead',
      'realtor', 'tc', 'isa', 'office_admin'
    )),

  permission_key TEXT NOT NULL,
  is_granted BOOLEAN NOT NULL DEFAULT false,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(company_id, role_name, permission_key)
);

CREATE INDEX idx_rrp_company_role ON realtor_role_permissions(company_id, role_name);

ALTER TABLE realtor_role_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY rrp_select ON realtor_role_permissions FOR SELECT TO authenticated
  USING (company_id = requesting_company_id());
CREATE POLICY rrp_insert ON realtor_role_permissions FOR INSERT TO authenticated
  WITH CHECK (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'brokerage_owner')
  );
CREATE POLICY rrp_update ON realtor_role_permissions FOR UPDATE TO authenticated
  USING (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'brokerage_owner')
  );
CREATE POLICY rrp_delete ON realtor_role_permissions FOR DELETE TO authenticated
  USING (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'brokerage_owner')
  );

SELECT update_updated_at('realtor_role_permissions');
CREATE TRIGGER rrp_audit AFTER INSERT OR UPDATE OR DELETE ON realtor_role_permissions
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 7. SEED FUNCTION: seed_realtor_default_permissions()
--    Inserts the default permission matrix for all 7 realtor
--    roles. Called when a realtor/brokerage company is created.
--    49 permission keys x 7 roles = 343 rows per company.
-- ============================================================

CREATE OR REPLACE FUNCTION seed_realtor_default_permissions(p_company_id UUID)
RETURNS void AS $$
DECLARE
  v_role TEXT;
  v_perm TEXT;
  v_granted BOOLEAN;

  -- Permission keys (49 total across 7 categories)
  v_all_permissions TEXT[] := ARRAY[
    -- Leads (7)
    'leads.view_own', 'leads.view_team', 'leads.view_all',
    'leads.create', 'leads.edit', 'leads.delete', 'leads.assign',
    -- Contacts (6)
    'contacts.view_own', 'contacts.view_all',
    'contacts.create', 'contacts.edit', 'contacts.delete', 'contacts.import',
    -- Transactions (7)
    'transactions.view_own', 'transactions.view_team', 'transactions.view_all',
    'transactions.create', 'transactions.edit', 'transactions.delete', 'transactions.close',
    -- Listings (6)
    'listings.view_own', 'listings.view_all',
    'listings.create', 'listings.edit', 'listings.delete', 'listings.publish',
    -- Showings (5)
    'showings.view_own', 'showings.view_all',
    'showings.manage', 'showings.schedule', 'showings.feedback',
    -- Commission (5)
    'commission.view_own', 'commission.view_team', 'commission.view_all',
    'commission.edit', 'commission.approve',
    -- CMA (3)
    'cma.view', 'cma.create', 'cma.export',
    -- Marketing (4)
    'marketing.view', 'marketing.create', 'marketing.edit', 'marketing.publish',
    -- Reports (3)
    'reports.view_own', 'reports.view_team', 'reports.view_all',
    -- Admin (3)
    'admin.manage_users', 'admin.manage_settings', 'admin.manage_billing'
  ];

  -- Role → permission grant matrix
  -- TRUE = granted by default, FALSE = denied by default
  v_role_grants JSONB := '{
    "brokerage_owner": {
      "leads.view_own": true, "leads.view_team": true, "leads.view_all": true,
      "leads.create": true, "leads.edit": true, "leads.delete": true, "leads.assign": true,
      "contacts.view_own": true, "contacts.view_all": true,
      "contacts.create": true, "contacts.edit": true, "contacts.delete": true, "contacts.import": true,
      "transactions.view_own": true, "transactions.view_team": true, "transactions.view_all": true,
      "transactions.create": true, "transactions.edit": true, "transactions.delete": true, "transactions.close": true,
      "listings.view_own": true, "listings.view_all": true,
      "listings.create": true, "listings.edit": true, "listings.delete": true, "listings.publish": true,
      "showings.view_own": true, "showings.view_all": true,
      "showings.manage": true, "showings.schedule": true, "showings.feedback": true,
      "commission.view_own": true, "commission.view_team": true, "commission.view_all": true,
      "commission.edit": true, "commission.approve": true,
      "cma.view": true, "cma.create": true, "cma.export": true,
      "marketing.view": true, "marketing.create": true, "marketing.edit": true, "marketing.publish": true,
      "reports.view_own": true, "reports.view_team": true, "reports.view_all": true,
      "admin.manage_users": true, "admin.manage_settings": true, "admin.manage_billing": true
    },
    "managing_broker": {
      "leads.view_own": true, "leads.view_team": true, "leads.view_all": true,
      "leads.create": true, "leads.edit": true, "leads.delete": true, "leads.assign": true,
      "contacts.view_own": true, "contacts.view_all": true,
      "contacts.create": true, "contacts.edit": true, "contacts.delete": true, "contacts.import": true,
      "transactions.view_own": true, "transactions.view_team": true, "transactions.view_all": true,
      "transactions.create": true, "transactions.edit": true, "transactions.delete": false, "transactions.close": true,
      "listings.view_own": true, "listings.view_all": true,
      "listings.create": true, "listings.edit": true, "listings.delete": true, "listings.publish": true,
      "showings.view_own": true, "showings.view_all": true,
      "showings.manage": true, "showings.schedule": true, "showings.feedback": true,
      "commission.view_own": true, "commission.view_team": true, "commission.view_all": true,
      "commission.edit": true, "commission.approve": true,
      "cma.view": true, "cma.create": true, "cma.export": true,
      "marketing.view": true, "marketing.create": true, "marketing.edit": true, "marketing.publish": true,
      "reports.view_own": true, "reports.view_team": true, "reports.view_all": true,
      "admin.manage_users": true, "admin.manage_settings": true, "admin.manage_billing": false
    },
    "team_lead": {
      "leads.view_own": true, "leads.view_team": true, "leads.view_all": false,
      "leads.create": true, "leads.edit": true, "leads.delete": false, "leads.assign": true,
      "contacts.view_own": true, "contacts.view_all": false,
      "contacts.create": true, "contacts.edit": true, "contacts.delete": false, "contacts.import": true,
      "transactions.view_own": true, "transactions.view_team": true, "transactions.view_all": false,
      "transactions.create": true, "transactions.edit": true, "transactions.delete": false, "transactions.close": true,
      "listings.view_own": true, "listings.view_all": false,
      "listings.create": true, "listings.edit": true, "listings.delete": false, "listings.publish": true,
      "showings.view_own": true, "showings.view_all": false,
      "showings.manage": true, "showings.schedule": true, "showings.feedback": true,
      "commission.view_own": true, "commission.view_team": true, "commission.view_all": false,
      "commission.edit": false, "commission.approve": false,
      "cma.view": true, "cma.create": true, "cma.export": true,
      "marketing.view": true, "marketing.create": true, "marketing.edit": true, "marketing.publish": false,
      "reports.view_own": true, "reports.view_team": true, "reports.view_all": false,
      "admin.manage_users": false, "admin.manage_settings": false, "admin.manage_billing": false
    },
    "realtor": {
      "leads.view_own": true, "leads.view_team": false, "leads.view_all": false,
      "leads.create": true, "leads.edit": true, "leads.delete": false, "leads.assign": false,
      "contacts.view_own": true, "contacts.view_all": false,
      "contacts.create": true, "contacts.edit": true, "contacts.delete": false, "contacts.import": true,
      "transactions.view_own": true, "transactions.view_team": false, "transactions.view_all": false,
      "transactions.create": true, "transactions.edit": true, "transactions.delete": false, "transactions.close": false,
      "listings.view_own": true, "listings.view_all": false,
      "listings.create": true, "listings.edit": true, "listings.delete": false, "listings.publish": false,
      "showings.view_own": true, "showings.view_all": false,
      "showings.manage": false, "showings.schedule": true, "showings.feedback": true,
      "commission.view_own": true, "commission.view_team": false, "commission.view_all": false,
      "commission.edit": false, "commission.approve": false,
      "cma.view": true, "cma.create": true, "cma.export": true,
      "marketing.view": true, "marketing.create": true, "marketing.edit": true, "marketing.publish": false,
      "reports.view_own": true, "reports.view_team": false, "reports.view_all": false,
      "admin.manage_users": false, "admin.manage_settings": false, "admin.manage_billing": false
    },
    "tc": {
      "leads.view_own": false, "leads.view_team": false, "leads.view_all": false,
      "leads.create": false, "leads.edit": false, "leads.delete": false, "leads.assign": false,
      "contacts.view_own": true, "contacts.view_all": true,
      "contacts.create": true, "contacts.edit": true, "contacts.delete": false, "contacts.import": false,
      "transactions.view_own": true, "transactions.view_team": true, "transactions.view_all": true,
      "transactions.create": true, "transactions.edit": true, "transactions.delete": false, "transactions.close": true,
      "listings.view_own": false, "listings.view_all": true,
      "listings.create": false, "listings.edit": false, "listings.delete": false, "listings.publish": false,
      "showings.view_own": true, "showings.view_all": true,
      "showings.manage": true, "showings.schedule": true, "showings.feedback": false,
      "commission.view_own": false, "commission.view_team": false, "commission.view_all": false,
      "commission.edit": false, "commission.approve": false,
      "cma.view": false, "cma.create": false, "cma.export": false,
      "marketing.view": false, "marketing.create": false, "marketing.edit": false, "marketing.publish": false,
      "reports.view_own": true, "reports.view_team": false, "reports.view_all": false,
      "admin.manage_users": false, "admin.manage_settings": false, "admin.manage_billing": false
    },
    "isa": {
      "leads.view_own": true, "leads.view_team": true, "leads.view_all": true,
      "leads.create": true, "leads.edit": true, "leads.delete": false, "leads.assign": true,
      "contacts.view_own": true, "contacts.view_all": true,
      "contacts.create": true, "contacts.edit": true, "contacts.delete": false, "contacts.import": true,
      "transactions.view_own": false, "transactions.view_team": false, "transactions.view_all": false,
      "transactions.create": false, "transactions.edit": false, "transactions.delete": false, "transactions.close": false,
      "listings.view_own": false, "listings.view_all": true,
      "listings.create": false, "listings.edit": false, "listings.delete": false, "listings.publish": false,
      "showings.view_own": true, "showings.view_all": false,
      "showings.manage": false, "showings.schedule": true, "showings.feedback": false,
      "commission.view_own": false, "commission.view_team": false, "commission.view_all": false,
      "commission.edit": false, "commission.approve": false,
      "cma.view": true, "cma.create": false, "cma.export": false,
      "marketing.view": true, "marketing.create": false, "marketing.edit": false, "marketing.publish": false,
      "reports.view_own": true, "reports.view_team": false, "reports.view_all": false,
      "admin.manage_users": false, "admin.manage_settings": false, "admin.manage_billing": false
    },
    "office_admin": {
      "leads.view_own": true, "leads.view_team": true, "leads.view_all": true,
      "leads.create": true, "leads.edit": true, "leads.delete": false, "leads.assign": true,
      "contacts.view_own": true, "contacts.view_all": true,
      "contacts.create": true, "contacts.edit": true, "contacts.delete": true, "contacts.import": true,
      "transactions.view_own": true, "transactions.view_team": true, "transactions.view_all": true,
      "transactions.create": true, "transactions.edit": true, "transactions.delete": false, "transactions.close": false,
      "listings.view_own": true, "listings.view_all": true,
      "listings.create": true, "listings.edit": true, "listings.delete": false, "listings.publish": false,
      "showings.view_own": true, "showings.view_all": true,
      "showings.manage": true, "showings.schedule": true, "showings.feedback": false,
      "commission.view_own": true, "commission.view_team": true, "commission.view_all": true,
      "commission.edit": false, "commission.approve": false,
      "cma.view": true, "cma.create": false, "cma.export": true,
      "marketing.view": true, "marketing.create": true, "marketing.edit": true, "marketing.publish": false,
      "reports.view_own": true, "reports.view_team": true, "reports.view_all": true,
      "admin.manage_users": true, "admin.manage_settings": true, "admin.manage_billing": false
    }
  }'::jsonb;
BEGIN
  -- Iterate all roles × all permissions
  FOREACH v_role IN ARRAY ARRAY['brokerage_owner', 'managing_broker', 'team_lead', 'realtor', 'tc', 'isa', 'office_admin']
  LOOP
    FOREACH v_perm IN ARRAY v_all_permissions
    LOOP
      v_granted := COALESCE((v_role_grants -> v_role ->> v_perm)::boolean, false);

      INSERT INTO realtor_role_permissions (company_id, role_name, permission_key, is_granted)
      VALUES (p_company_id, v_role, v_perm, v_granted)
      ON CONFLICT (company_id, role_name, permission_key) DO NOTHING;
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- 8. HELPER: has_realtor_permission()
--    Quick RLS/app check: does user's role have a given perm
--    in their company? Falls back to false if no row.
-- ============================================================

CREATE OR REPLACE FUNCTION has_realtor_permission(p_permission_key TEXT)
RETURNS BOOLEAN AS $$
  SELECT COALESCE(
    (SELECT is_granted FROM realtor_role_permissions
     WHERE company_id = requesting_company_id()
       AND role_name = requesting_user_role()
       AND permission_key = p_permission_key
     LIMIT 1),
    false
  );
$$ LANGUAGE sql STABLE;
