-- DATA-ARCH1: Data Source Registry + Ingestion Framework (S135)
-- Foundation: every API gets registered, every ingestion follows one pattern.

-- ============================================================================
-- data_sources — Master registry of all external data APIs
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.data_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_key varchar(100) UNIQUE NOT NULL, -- e.g. 'bls_oews', 'nws_weather', 'usps_address'
  display_name varchar(200) NOT NULL,
  description text,
  category varchar(50) NOT NULL DEFAULT 'general', -- 'weather', 'compliance', 'market', 'property', 'utility'
  tier smallint NOT NULL DEFAULT 2, -- 1=critical, 2=important, 3=nice-to-have
  -- API connection
  base_url text NOT NULL,
  auth_method varchar(30) NOT NULL DEFAULT 'none', -- 'none', 'api_key', 'bearer', 'basic', 'oauth2'
  auth_config jsonb DEFAULT '{}', -- encrypted ref or vault key path
  -- Rate limits
  rate_limit_per_minute int DEFAULT 0, -- 0 = unlimited
  rate_limit_per_day int DEFAULT 0,
  rate_limit_remaining int DEFAULT 0,
  rate_limit_resets_at timestamptz,
  -- Refresh schedule
  refresh_frequency interval NOT NULL DEFAULT '24 hours',
  next_refresh_at timestamptz DEFAULT now(),
  last_refreshed_at timestamptz,
  last_status varchar(30) DEFAULT 'PENDING', -- PENDING, SUCCESS, PARTIAL_FAILURE, FAILED, STALE, DISABLED
  last_error text,
  -- Cost tracking ($0/mo target)
  monthly_cost_cents int DEFAULT 0,
  cost_notes text, -- e.g. 'Free tier: 500/day'
  -- Fallback
  fallback_source_key varchar(100) REFERENCES public.data_sources(source_key),
  -- Metadata
  license varchar(50), -- 'MIT', 'Apache-2.0', 'public_domain', 'government', 'proprietary'
  documentation_url text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_data_sources_source_key ON public.data_sources(source_key);
CREATE INDEX idx_data_sources_category ON public.data_sources(category);
CREATE INDEX idx_data_sources_next_refresh ON public.data_sources(next_refresh_at) WHERE is_active = true AND deleted_at IS NULL;
CREATE INDEX idx_data_sources_status ON public.data_sources(last_status);

-- Trigger
CREATE TRIGGER update_data_sources_updated_at
  BEFORE UPDATE ON public.data_sources
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE public.data_sources ENABLE ROW LEVEL SECURITY;

-- Super admin + ops can read/manage data sources
CREATE POLICY data_sources_select ON public.data_sources
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR (auth.jwt() -> 'app_metadata' ->> 'role') IN ('super_admin', 'owner', 'admin')
  );

CREATE POLICY data_sources_insert ON public.data_sources
  FOR INSERT WITH CHECK (
    auth.jwt() ->> 'role' = 'service_role'
    OR (auth.jwt() -> 'app_metadata' ->> 'role') IN ('super_admin')
  );

CREATE POLICY data_sources_update ON public.data_sources
  FOR UPDATE USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR (auth.jwt() -> 'app_metadata' ->> 'role') IN ('super_admin')
  );

-- ============================================================================
-- data_ingestion_log — Track every ingestion run
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.data_ingestion_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_key varchar(100) NOT NULL REFERENCES public.data_sources(source_key),
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  duration_ms int,
  status varchar(30) NOT NULL DEFAULT 'RUNNING', -- RUNNING, SUCCESS, PARTIAL_FAILURE, FAILED
  records_fetched int DEFAULT 0,
  records_upserted int DEFAULT 0,
  records_skipped int DEFAULT 0,
  error_message text,
  error_details jsonb,
  triggered_by varchar(20) NOT NULL DEFAULT 'CRON', -- CRON, MANUAL, WEBHOOK, STARTUP
  triggered_by_user_id uuid,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_ingestion_log_source ON public.data_ingestion_log(source_key);
CREATE INDEX idx_ingestion_log_started ON public.data_ingestion_log(started_at DESC);
CREATE INDEX idx_ingestion_log_status ON public.data_ingestion_log(status);

-- RLS
ALTER TABLE public.data_ingestion_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY ingestion_log_select ON public.data_ingestion_log
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR (auth.jwt() -> 'app_metadata' ->> 'role') IN ('super_admin', 'owner', 'admin')
  );

CREATE POLICY ingestion_log_insert ON public.data_ingestion_log
  FOR INSERT WITH CHECK (
    auth.jwt() ->> 'role' = 'service_role'
    OR (auth.jwt() -> 'app_metadata' ->> 'role') IN ('super_admin')
  );

-- ============================================================================
-- api_gateway_metrics — Per-source daily metrics
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.api_gateway_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_key varchar(100) NOT NULL REFERENCES public.data_sources(source_key),
  metric_date date NOT NULL DEFAULT CURRENT_DATE,
  total_requests int DEFAULT 0,
  cache_hits int DEFAULT 0,
  cache_misses int DEFAULT 0,
  external_calls int DEFAULT 0,
  failures int DEFAULT 0,
  avg_response_ms numeric(10,2) DEFAULT 0,
  p95_response_ms numeric(10,2) DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(source_key, metric_date)
);

CREATE INDEX idx_gateway_metrics_date ON public.api_gateway_metrics(metric_date DESC);
CREATE INDEX idx_gateway_metrics_source ON public.api_gateway_metrics(source_key);

-- RLS
ALTER TABLE public.api_gateway_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY gateway_metrics_select ON public.api_gateway_metrics
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR (auth.jwt() -> 'app_metadata' ->> 'role') IN ('super_admin', 'owner', 'admin')
  );

CREATE POLICY gateway_metrics_upsert ON public.api_gateway_metrics
  FOR INSERT WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY gateway_metrics_update ON public.api_gateway_metrics
  FOR UPDATE USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================================================
-- SEED: Tier 1 + Tier 2 data sources (16 APIs, all $0/mo)
-- ============================================================================
INSERT INTO public.data_sources (source_key, display_name, description, category, tier, base_url, auth_method, rate_limit_per_day, refresh_frequency, monthly_cost_cents, cost_notes, license) VALUES
  -- Tier 1 (critical)
  ('usps_address', 'USPS Address Validation', 'USPS Web Tools API for address standardization and ZIP+4 lookup', 'utility', 1, 'https://secure.shippingapis.com/ShippingAPI.dll', 'api_key', 0, '0 seconds', 0, 'Free with registration', 'government'),
  ('nominatim_geocoder', 'Nominatim Geocoder', 'OpenStreetMap Nominatim for forward/reverse geocoding', 'utility', 1, 'https://nominatim.openstreetmap.org', 'none', 0, '0 seconds', 0, 'Free, 1 req/sec rate limit', 'ODbL'),
  ('nws_weather', 'NWS Weather', 'National Weather Service API for forecasts, alerts, conditions', 'weather', 1, 'https://api.weather.gov', 'none', 0, '1 hour', 0, 'Free, no auth required', 'government'),
  ('api_ninjas_sales_tax', 'API Ninjas Sales Tax', 'US sales tax rates by ZIP code', 'market', 1, 'https://api.api-ninjas.com/v1/salestax', 'api_key', 10000, '30 days', 0, 'Free: 10K/month', 'proprietary'),
  ('fcm_push', 'Firebase Cloud Messaging', 'Push notifications for Flutter mobile app', 'utility', 1, 'https://fcm.googleapis.com/v1/projects', 'bearer', 0, '0 seconds', 0, 'Free tier generous', 'proprietary'),
  ('resend_email', 'Resend Email', 'Transactional email API', 'utility', 1, 'https://api.resend.com', 'api_key', 3000, '0 seconds', 0, 'Free: 3K emails/month, 100/day', 'proprietary'),
  ('noaa_spc_storms', 'NOAA SPC Storm Events', 'Storm Prediction Center severe weather reports', 'weather', 1, 'https://www.spc.noaa.gov/climo/reports', 'none', 0, '6 hours', 0, 'Free, no auth', 'government'),
  ('cpsc_recalls', 'CPSC Product Recalls', 'Consumer Product Safety Commission recall database', 'compliance', 1, 'https://www.saferproducts.gov/RestWebServices', 'none', 0, '24 hours', 0, 'Free public API', 'government'),
  -- Tier 2 (important)
  ('osrm_routing', 'OSRM Route Optimizer', 'Open Source Routing Machine for driving directions and distance matrix', 'utility', 2, 'https://router.project-osrm.org', 'none', 0, '0 seconds', 0, 'Free public demo server, self-host for production', 'BSD-2'),
  ('docuseal_esign', 'DocuSeal E-Signatures', 'Open-source document signing API', 'utility', 2, 'https://api.docuseal.co', 'api_key', 0, '0 seconds', 0, 'Self-hosted = free', 'AGPL-3.0'),
  ('walkscore', 'Walk Score', 'Walkability, transit, and bike score by location', 'property', 2, 'https://api.walkscore.com', 'api_key', 5000, '30 days', 0, 'Free: 5K/day', 'proprietary'),
  ('nhtsa_vin', 'NHTSA VIN Decoder', 'Vehicle identification number decoder for fleet/equipment', 'utility', 2, 'https://vpic.nhtsa.dot.gov/api', 'none', 0, '0 seconds', 0, 'Free, no auth, no limit', 'government'),
  ('fema_nfhl', 'FEMA Flood Zones', 'National Flood Hazard Layer for flood zone determination', 'property', 2, 'https://hazards.fema.gov/gis/nfhl/rest/services', 'none', 0, '7 days', 0, 'Free ArcGIS REST services', 'government'),
  ('bls_oews', 'BLS OEWS Wages', 'Bureau of Labor Statistics occupational wage data by MSA', 'market', 2, 'https://api.bls.gov/publicAPI/v2', 'api_key', 500, '90 days', 0, 'Free: 500/day with key', 'government'),
  ('bls_ppi', 'BLS PPI Materials', 'Producer Price Index for construction materials', 'market', 2, 'https://api.bls.gov/publicAPI/v2', 'api_key', 500, '30 days', 0, 'Free: shared with OEWS key', 'government'),
  ('fred_economic', 'FRED Economic Data', 'Federal Reserve economic data (interest rates, housing starts, etc.)', 'market', 2, 'https://api.stlouisfed.org/fred', 'api_key', 120, '7 days', 0, 'Free: 120 req/min', 'government')
ON CONFLICT (source_key) DO NOTHING;

-- ============================================================================
-- fn_check_stale_sources — Detect stale data sources
-- ============================================================================
CREATE OR REPLACE FUNCTION public.fn_check_stale_sources()
RETURNS TABLE(source_key varchar, display_name varchar, last_refreshed timestamptz, staleness_hours numeric)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    ds.source_key,
    ds.display_name,
    ds.last_refreshed_at,
    EXTRACT(EPOCH FROM (now() - ds.last_refreshed_at)) / 3600 AS staleness_hours
  FROM public.data_sources ds
  WHERE ds.is_active = true
    AND ds.deleted_at IS NULL
    AND ds.refresh_frequency > '0 seconds'::interval
    AND (
      ds.last_refreshed_at IS NULL
      OR ds.last_refreshed_at < now() - (ds.refresh_frequency * 2)
    )
  ORDER BY staleness_hours DESC NULLS FIRST;
END;
$$;
