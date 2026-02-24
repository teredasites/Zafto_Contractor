-- ============================================================================
-- KIOSK TIME CLOCK — Tables, RLS, Indexes
-- Enables tablet/PC-based employee clock-in via custom kiosk URL
-- ============================================================================

-- ── 1. kiosk_configs ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.kiosk_configs (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name          text NOT NULL,                          -- e.g. "Shop Front Desk"
  access_token  text NOT NULL UNIQUE,                   -- URL-safe 32-char token
  is_active     boolean NOT NULL DEFAULT true,

  -- Auth methods the boss enables for this kiosk
  auth_methods  jsonb NOT NULL DEFAULT '{"pin": true, "password": false, "face": false, "name_tap": true}'::jsonb,

  -- Kiosk behavior settings
  settings      jsonb NOT NULL DEFAULT '{
    "auto_break_minutes": 0,
    "require_job_selection": false,
    "allowed_hours_start": null,
    "allowed_hours_end": null,
    "show_company_logo": true,
    "idle_timeout_seconds": 30,
    "allow_break_toggle": true,
    "restrict_ip_ranges": [],
    "greeting_message": null
  }'::jsonb,

  -- Custom branding
  branding      jsonb NOT NULL DEFAULT '{
    "primary_color": null,
    "logo_url": null,
    "background_url": null
  }'::jsonb,

  created_by    uuid REFERENCES auth.users(id),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  deleted_at    timestamptz
);

-- Indexes
CREATE INDEX idx_kiosk_configs_company ON public.kiosk_configs (company_id);
CREATE UNIQUE INDEX idx_kiosk_configs_token ON public.kiosk_configs (access_token) WHERE deleted_at IS NULL;
CREATE INDEX idx_kiosk_configs_active ON public.kiosk_configs (company_id, is_active) WHERE deleted_at IS NULL;

-- Auto-update updated_at
CREATE TRIGGER update_kiosk_configs_updated_at
  BEFORE UPDATE ON public.kiosk_configs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit
CREATE TRIGGER audit_kiosk_configs
  AFTER INSERT OR UPDATE OR DELETE ON public.kiosk_configs
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- RLS
ALTER TABLE public.kiosk_configs ENABLE ROW LEVEL SECURITY;

CREATE POLICY kiosk_configs_select ON public.kiosk_configs
  FOR SELECT USING (
    company_id = public.requesting_company_id()
    OR
    -- Allow anonymous token lookup for kiosk pages (no auth context)
    access_token IS NOT NULL
  );

CREATE POLICY kiosk_configs_insert ON public.kiosk_configs
  FOR INSERT WITH CHECK (
    company_id = public.requesting_company_id()
    AND public.requesting_user_role() IN ('owner', 'admin', 'office_manager', 'super_admin')
  );

CREATE POLICY kiosk_configs_update ON public.kiosk_configs
  FOR UPDATE USING (
    company_id = public.requesting_company_id()
    AND public.requesting_user_role() IN ('owner', 'admin', 'office_manager', 'super_admin')
  );

CREATE POLICY kiosk_configs_delete ON public.kiosk_configs
  FOR DELETE USING (
    company_id = public.requesting_company_id()
    AND public.requesting_user_role() IN ('owner', 'admin', 'super_admin')
  );


-- ── 2. employee_kiosk_pins ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.employee_kiosk_pins (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  pin_hash      text NOT NULL,                          -- SHA-256 hash of PIN
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),

  UNIQUE(company_id, user_id)
);

-- Indexes
CREATE INDEX idx_employee_kiosk_pins_company ON public.employee_kiosk_pins (company_id);

-- Auto-update updated_at
CREATE TRIGGER update_employee_kiosk_pins_updated_at
  BEFORE UPDATE ON public.employee_kiosk_pins
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit
CREATE TRIGGER audit_employee_kiosk_pins
  AFTER INSERT OR UPDATE OR DELETE ON public.employee_kiosk_pins
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- RLS
ALTER TABLE public.employee_kiosk_pins ENABLE ROW LEVEL SECURITY;

CREATE POLICY employee_kiosk_pins_select ON public.employee_kiosk_pins
  FOR SELECT USING (
    company_id = public.requesting_company_id()
  );

CREATE POLICY employee_kiosk_pins_insert ON public.employee_kiosk_pins
  FOR INSERT WITH CHECK (
    company_id = public.requesting_company_id()
    AND (
      public.requesting_user_role() IN ('owner', 'admin', 'office_manager', 'super_admin')
      OR auth.uid() = user_id  -- Employee can set own PIN
    )
  );

CREATE POLICY employee_kiosk_pins_update ON public.employee_kiosk_pins
  FOR UPDATE USING (
    company_id = public.requesting_company_id()
    AND (
      public.requesting_user_role() IN ('owner', 'admin', 'office_manager', 'super_admin')
      OR auth.uid() = user_id
    )
  );

CREATE POLICY employee_kiosk_pins_delete ON public.employee_kiosk_pins
  FOR DELETE USING (
    company_id = public.requesting_company_id()
    AND public.requesting_user_role() IN ('owner', 'admin', 'super_admin')
  );


-- ── 3. Add kiosk columns to time_entries ─────────────────────────────────────

ALTER TABLE public.time_entries
  ADD COLUMN IF NOT EXISTS kiosk_config_id uuid REFERENCES public.kiosk_configs(id),
  ADD COLUMN IF NOT EXISTS clock_in_method text DEFAULT 'app'
    CHECK (clock_in_method IN ('app', 'kiosk_pin', 'kiosk_face', 'kiosk_name_tap', 'kiosk_password', 'manual'));

CREATE INDEX idx_time_entries_kiosk ON public.time_entries (kiosk_config_id) WHERE kiosk_config_id IS NOT NULL;


-- ── 4. Edge Function for kiosk token verification (public, no auth) ──────────
-- This is handled by an Edge Function that:
--   1. Looks up kiosk_configs by access_token
--   2. Returns config + employee list for the company
--   3. Verifies PIN hashes
--   4. Inserts time_entries via service role
-- See: supabase/functions/kiosk-clock/index.ts


-- ── 5. Comments ──────────────────────────────────────────────────────────────

COMMENT ON TABLE public.kiosk_configs IS 'Per-company kiosk configurations for tablet/PC time clock stations';
COMMENT ON TABLE public.employee_kiosk_pins IS 'Hashed PINs for kiosk-based employee identification';
COMMENT ON COLUMN public.time_entries.kiosk_config_id IS 'Which kiosk station was used for this clock-in (null = app/manual)';
COMMENT ON COLUMN public.time_entries.clock_in_method IS 'How the employee clocked in: app, kiosk_pin, kiosk_face, kiosk_name_tap, kiosk_password, manual';
