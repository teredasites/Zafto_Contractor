-- ============================================================================
-- P10: Feature Flags, Caching, and Cost Tracking for Property Intelligence
-- Phase P Sprint P10 — Polish & Launch Readiness
-- ============================================================================

-- ============================================================================
-- 1. FEATURE FLAG: property_intelligence_enabled
-- Added to company_settings as a JSONB field for flexibility
-- ============================================================================

-- Company-level feature flags (if company_settings doesn't exist yet)
CREATE TABLE IF NOT EXISTS public.company_feature_flags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  feature_key text NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  config jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(company_id, feature_key)
);

ALTER TABLE public.company_feature_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "company_feature_flags_select" ON public.company_feature_flags
  FOR SELECT USING (company_id = auth.company_id());

CREATE POLICY "company_feature_flags_manage" ON public.company_feature_flags
  FOR ALL USING (
    company_id = auth.company_id()
    AND auth.user_role() IN ('owner', 'admin', 'super_admin')
  );

CREATE INDEX IF NOT EXISTS idx_company_feature_flags_lookup
  ON public.company_feature_flags(company_id, feature_key);

CREATE TRIGGER set_updated_at_company_feature_flags
  BEFORE UPDATE ON public.company_feature_flags
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- 2. SCAN CACHE TABLE
-- Caches property scan results for 30 days per address to avoid redundant
-- API calls. Keyed on normalized address hash.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.scan_cache (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  address_hash text NOT NULL, -- SHA256 of normalized address
  address_normalized text NOT NULL,
  scan_data jsonb NOT NULL DEFAULT '{}',
  source_apis text[] NOT NULL DEFAULT '{}',
  cached_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '30 days'),
  hit_count int NOT NULL DEFAULT 0,
  UNIQUE(company_id, address_hash)
);

ALTER TABLE public.scan_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "scan_cache_company" ON public.scan_cache
  FOR ALL USING (company_id = auth.company_id());

CREATE INDEX IF NOT EXISTS idx_scan_cache_lookup
  ON public.scan_cache(company_id, address_hash)
  WHERE expires_at > now();

CREATE INDEX IF NOT EXISTS idx_scan_cache_expiry
  ON public.scan_cache(expires_at);

-- ============================================================================
-- 3. API COST TRACKING
-- Tracks per-call costs for paid APIs (ATTOM, Regrid, Unwrangle).
-- Used by ops portal cost dashboard.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.api_cost_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  api_name text NOT NULL, -- 'google_solar', 'attom', 'regrid', 'unwrangle', 'noaa', 'nominatim', 'overpass'
  endpoint text,
  cost_cents int NOT NULL DEFAULT 0, -- 0 for free APIs
  request_payload jsonb,
  response_status int,
  latency_ms int,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

ALTER TABLE public.api_cost_log ENABLE ROW LEVEL SECURITY;

-- Only super_admin and company owners can view cost logs
CREATE POLICY "api_cost_log_select" ON public.api_cost_log
  FOR SELECT USING (
    company_id = auth.company_id()
    AND auth.user_role() IN ('owner', 'admin', 'super_admin')
  );

-- Service role inserts (Edge Functions use service role)
CREATE POLICY "api_cost_log_insert" ON public.api_cost_log
  FOR INSERT WITH CHECK (company_id = auth.company_id());

CREATE INDEX IF NOT EXISTS idx_api_cost_log_company_date
  ON public.api_cost_log(company_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_api_cost_log_api
  ON public.api_cost_log(api_name, created_at DESC);

-- ============================================================================
-- 4. API RATE LIMITING TABLE
-- Per-company rate limit tracking to enforce fair use.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.api_rate_limits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  api_name text NOT NULL,
  window_start timestamptz NOT NULL DEFAULT date_trunc('hour', now()),
  request_count int NOT NULL DEFAULT 1,
  max_requests int NOT NULL DEFAULT 100,
  UNIQUE(company_id, api_name, window_start)
);

ALTER TABLE public.api_rate_limits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "api_rate_limits_company" ON public.api_rate_limits
  FOR ALL USING (company_id = auth.company_id());

-- ============================================================================
-- 5. ADD storm_damage_probability TO property_lead_scores IF MISSING
-- (May already exist from P5 migration — use IF NOT EXISTS pattern)
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'property_lead_scores'
      AND column_name = 'storm_damage_probability'
  ) THEN
    ALTER TABLE public.property_lead_scores
      ADD COLUMN storm_damage_probability int DEFAULT 0;
  END IF;
END $$;

-- ============================================================================
-- 6. DATA ATTRIBUTION TRACKING
-- Tracks which data sources contributed to each scan for compliance.
-- ============================================================================

ALTER TABLE public.property_scans
  ADD COLUMN IF NOT EXISTS data_attributions jsonb DEFAULT '[]';

-- Example: [{"source":"google_solar","date":"2026-01-15","license":"terms_url"}]

COMMENT ON COLUMN public.property_scans.data_attributions IS
  'Array of data source attributions with source name, access date, and license reference';

-- ============================================================================
-- 7. AUDIT TRIGGERS on new tables
-- ============================================================================

CREATE TRIGGER audit_company_feature_flags
  AFTER INSERT OR UPDATE OR DELETE ON public.company_feature_flags
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_scan_cache
  AFTER INSERT OR UPDATE OR DELETE ON public.scan_cache
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
