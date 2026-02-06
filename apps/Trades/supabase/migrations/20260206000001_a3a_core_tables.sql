-- ============================================================
-- ZAFTO CORE SCHEMA — A3a: Auth Foundation
-- Sprint A3a | Session 39
--
-- Run against: dev first, then staging, then prod
-- Tables: companies, users, audit_log, user_sessions, login_attempts
-- ============================================================

-- Helper functions for RLS
CREATE OR REPLACE FUNCTION auth.company_id() RETURNS uuid AS $$
  SELECT (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.user_role() RETURNS text AS $$
  SELECT auth.jwt() -> 'app_metadata' ->> 'role';
$$ LANGUAGE sql STABLE;

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- COMPANIES TABLE
-- ============================================================
CREATE TABLE companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  trade text NOT NULL DEFAULT 'electrical',
  trades text[] DEFAULT '{}',
  owner_user_id uuid,  -- set after first user created
  phone text,
  email text,
  address text,
  city text,
  state text,
  zip_code text,
  website text,
  license_number text,
  license_state text,
  logo_url text,
  subscription_tier text NOT NULL DEFAULT 'solo' CHECK (subscription_tier IN ('solo', 'team', 'business', 'enterprise')),
  subscription_status text NOT NULL DEFAULT 'trialing' CHECK (subscription_status IN ('trialing', 'active', 'past_due', 'cancelled')),
  stripe_customer_id text,
  stripe_subscription_id text,
  max_users int NOT NULL DEFAULT 1,
  settings jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS: Users can read their own company
CREATE POLICY "companies_select" ON companies FOR SELECT USING (id = auth.company_id());
-- RLS: Only owner/admin can update company
CREATE POLICY "companies_update" ON companies FOR UPDATE USING (
  id = auth.company_id() AND auth.user_role() IN ('owner', 'admin')
);
-- RLS: Anyone can insert (onboarding creates company)
CREATE POLICY "companies_insert" ON companies FOR INSERT WITH CHECK (true);

-- ============================================================
-- USERS TABLE
-- ============================================================
CREATE TABLE users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text NOT NULL,
  phone text,
  role text NOT NULL DEFAULT 'owner' CHECK (role IN ('owner', 'admin', 'office_manager', 'technician', 'apprentice')),
  avatar_url text,
  trade text,
  is_active boolean NOT NULL DEFAULT true,
  last_login_at timestamptz,
  settings jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS: Users see their own company members
CREATE POLICY "users_select" ON users FOR SELECT USING (company_id = auth.company_id());
-- RLS: Owner/admin can manage users, or user can update self
CREATE POLICY "users_update" ON users FOR UPDATE USING (
  company_id = auth.company_id() AND (auth.user_role() IN ('owner', 'admin') OR id = auth.uid())
);
CREATE POLICY "users_insert" ON users FOR INSERT WITH CHECK (company_id = auth.company_id());

-- ============================================================
-- AUDIT LOG TABLE (append-only, immutable)
-- ============================================================
CREATE TABLE audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name text NOT NULL,
  record_id uuid NOT NULL,
  action text NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  old_data jsonb,
  new_data jsonb,
  user_id uuid,
  company_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_log_company_time ON audit_log (company_id, created_at DESC);
CREATE INDEX idx_audit_log_table_record ON audit_log (table_name, record_id);

ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit_select" ON audit_log FOR SELECT USING (company_id = auth.company_id());

-- Audit trigger function (attached to every business table)
CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO audit_log (table_name, record_id, action, old_data, user_id, company_id)
    VALUES (TG_TABLE_NAME, OLD.id, TG_OP, to_jsonb(OLD), auth.uid(), OLD.company_id);
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, user_id, company_id)
    VALUES (TG_TABLE_NAME, NEW.id, TG_OP, to_jsonb(OLD), to_jsonb(NEW), auth.uid(), NEW.company_id);
    RETURN NEW;
  ELSIF TG_OP = 'INSERT' THEN
    INSERT INTO audit_log (table_name, record_id, action, new_data, user_id, company_id)
    VALUES (TG_TABLE_NAME, NEW.id, TG_OP, to_jsonb(NEW), auth.uid(), NEW.company_id);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach audit triggers to companies and users
CREATE TRIGGER companies_audit AFTER INSERT OR UPDATE OR DELETE ON companies FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER users_audit AFTER INSERT OR UPDATE OR DELETE ON users FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ============================================================
-- SECURITY TABLES
-- ============================================================
CREATE TABLE user_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id),
  device_info jsonb,
  ip_address inet,
  started_at timestamptz NOT NULL DEFAULT now(),
  last_active_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz
);

CREATE TABLE login_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL,
  ip_address inet,
  success boolean NOT NULL,
  failure_reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_login_attempts_email ON login_attempts (email, created_at DESC);

-- ============================================================
-- JWT CLAIMS TRIGGER (sets company_id + role on JWT after user creation)
-- This is CRITICAL — all RLS policies depend on auth.company_id()
-- ============================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE auth.users
  SET raw_app_meta_data = raw_app_meta_data || jsonb_build_object(
    'company_id', NEW.company_id::text,
    'role', NEW.role
  )
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_user_created
  AFTER INSERT ON public.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Also update JWT claims when role changes
CREATE OR REPLACE FUNCTION handle_user_role_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    UPDATE auth.users
    SET raw_app_meta_data = raw_app_meta_data || jsonb_build_object(
      'role', NEW.role
    )
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_user_role_changed
  AFTER UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION handle_user_role_change();
