-- DATA-ARCH3: Runtime API Gateway + Caching + Fallback Chain
-- api_cache table with TTL-based auto-cleanup.
-- Rate limit tracking is built into data_sources (from DATA-ARCH1).
-- api_gateway_metrics already exists (DATA-ARCH1).
-- pg_cron cache cleanup function (scheduler registered via Supabase dashboard).

-- ============================================================================
-- api_cache — Unified response cache for all realtime API calls
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.api_cache (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cache_key varchar(500) NOT NULL,
  source_key varchar(100) NOT NULL REFERENCES public.data_sources(source_key),
  request_params_hash varchar(64) NOT NULL, -- SHA-256 of normalized request params
  response_data jsonb NOT NULL,
  response_size_bytes int GENERATED ALWAYS AS (octet_length(response_data::text)) STORED,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  hit_count int NOT NULL DEFAULT 0,
  last_hit_at timestamptz,
  -- Company scoping: NULL = public/shared cache (weather, compliance), non-NULL = company-specific
  company_id uuid REFERENCES public.companies(id),
  CONSTRAINT uq_api_cache_key UNIQUE (cache_key)
);

-- Indexes
CREATE INDEX idx_api_cache_expires ON public.api_cache(expires_at);
CREATE INDEX idx_api_cache_source ON public.api_cache(source_key);
CREATE INDEX idx_api_cache_company ON public.api_cache(company_id) WHERE company_id IS NOT NULL;
CREATE INDEX idx_api_cache_key_lookup ON public.api_cache(cache_key, expires_at);

-- RLS
ALTER TABLE public.api_cache ENABLE ROW LEVEL SECURITY;

-- Service role can do everything (Edge Functions operate as service_role)
CREATE POLICY api_cache_service_all ON public.api_cache
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Authenticated users can read their company's cache + shared cache
CREATE POLICY api_cache_select ON public.api_cache
  FOR SELECT USING (
    company_id IS NULL
    OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

-- Audit trigger
CREATE TRIGGER api_cache_updated
  BEFORE UPDATE ON public.api_cache
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- fn_api_cache_cleanup — Delete expired cache entries
-- Called by pg_cron hourly: SELECT fn_api_cache_cleanup()
-- ============================================================================
CREATE OR REPLACE FUNCTION public.fn_api_cache_cleanup()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted int;
  v_total_before int;
  v_total_after int;
BEGIN
  SELECT count(*) INTO v_total_before FROM public.api_cache;

  DELETE FROM public.api_cache
  WHERE expires_at < now() - interval '1 day';

  GET DIAGNOSTICS v_deleted = ROW_COUNT;

  SELECT count(*) INTO v_total_after FROM public.api_cache;

  RETURN jsonb_build_object(
    'deleted', v_deleted,
    'total_before', v_total_before,
    'total_after', v_total_after,
    'cleaned_at', now()
  );
END;
$$;

-- ============================================================================
-- fn_api_cache_lookup — Check cache before external call
-- Returns cached response if valid, NULL if miss/expired
-- ============================================================================
CREATE OR REPLACE FUNCTION public.fn_api_cache_lookup(
  p_cache_key varchar(500)
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
  v_id uuid;
BEGIN
  SELECT id, response_data INTO v_id, v_result
  FROM public.api_cache
  WHERE cache_key = p_cache_key
    AND expires_at > now()
  LIMIT 1;

  IF v_id IS NOT NULL THEN
    -- Increment hit counter
    UPDATE public.api_cache
    SET hit_count = hit_count + 1,
        last_hit_at = now()
    WHERE id = v_id;

    RETURN jsonb_build_object(
      'hit', true,
      'data', v_result,
      'cached', true
    );
  END IF;

  RETURN NULL;
END;
$$;

-- ============================================================================
-- fn_api_cache_lookup_stale — Get last cached response even if expired
-- Used in fallback chain when primary + fallback both fail
-- ============================================================================
CREATE OR REPLACE FUNCTION public.fn_api_cache_lookup_stale(
  p_cache_key varchar(500)
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
  v_cached_at timestamptz;
  v_expired_at timestamptz;
BEGIN
  SELECT response_data, created_at, expires_at
  INTO v_result, v_cached_at, v_expired_at
  FROM public.api_cache
  WHERE cache_key = p_cache_key
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_result IS NOT NULL THEN
    RETURN jsonb_build_object(
      'hit', true,
      'data', v_result,
      'stale', true,
      'cached_at', v_cached_at,
      'expired_at', v_expired_at
    );
  END IF;

  RETURN NULL;
END;
$$;

-- ============================================================================
-- fn_api_cache_set — Store a response in cache
-- ============================================================================
CREATE OR REPLACE FUNCTION public.fn_api_cache_set(
  p_cache_key varchar(500),
  p_source_key varchar(100),
  p_params_hash varchar(64),
  p_response jsonb,
  p_ttl_seconds int DEFAULT 3600,
  p_company_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.api_cache (
    cache_key, source_key, request_params_hash,
    response_data, expires_at, company_id
  ) VALUES (
    p_cache_key, p_source_key, p_params_hash,
    p_response, now() + (p_ttl_seconds || ' seconds')::interval, p_company_id
  )
  ON CONFLICT (cache_key) DO UPDATE SET
    response_data = EXCLUDED.response_data,
    expires_at = EXCLUDED.expires_at,
    hit_count = 0,
    last_hit_at = NULL,
    created_at = now();
END;
$$;

-- ============================================================================
-- fn_check_rate_limit — Check if we can make an external call
-- Returns true if OK, false if rate-limited. Decrements remaining on OK.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.fn_check_rate_limit(
  p_source_key varchar(100)
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_remaining int;
  v_resets_at timestamptz;
  v_per_minute int;
  v_per_day int;
BEGIN
  SELECT rate_limit_remaining, rate_limit_resets_at,
         rate_limit_per_minute, rate_limit_per_day
  INTO v_remaining, v_resets_at, v_per_minute, v_per_day
  FROM public.data_sources
  WHERE source_key = p_source_key
    AND is_active = true
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('allowed', false, 'reason', 'source_not_found');
  END IF;

  -- If reset time has passed, reset the counter
  IF v_resets_at IS NOT NULL AND v_resets_at <= now() THEN
    UPDATE public.data_sources
    SET rate_limit_remaining = rate_limit_per_day,
        rate_limit_resets_at = now() + interval '1 day'
    WHERE source_key = p_source_key;
    v_remaining := v_per_day;
  END IF;

  IF v_remaining <= 0 THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'rate_limited',
      'resets_at', v_resets_at,
      'per_day', v_per_day
    );
  END IF;

  -- Decrement remaining
  UPDATE public.data_sources
  SET rate_limit_remaining = rate_limit_remaining - 1
  WHERE source_key = p_source_key;

  RETURN jsonb_build_object(
    'allowed', true,
    'remaining', v_remaining - 1,
    'per_day', v_per_day
  );
END;
$$;

-- ============================================================================
-- fn_update_gateway_metrics — Atomic upsert for daily metrics
-- ============================================================================
CREATE OR REPLACE FUNCTION public.fn_update_gateway_metrics(
  p_source_key varchar(100),
  p_cache_hit boolean DEFAULT false,
  p_external_call boolean DEFAULT false,
  p_failure boolean DEFAULT false,
  p_response_ms int DEFAULT 0
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today date := current_date;
BEGIN
  INSERT INTO public.api_gateway_metrics (
    source_key, metric_date, total_requests,
    cache_hits, cache_misses, external_calls,
    failures, avg_response_ms, p95_response_ms
  ) VALUES (
    p_source_key, v_today, 1,
    CASE WHEN p_cache_hit THEN 1 ELSE 0 END,
    CASE WHEN NOT p_cache_hit THEN 1 ELSE 0 END,
    CASE WHEN p_external_call THEN 1 ELSE 0 END,
    CASE WHEN p_failure THEN 1 ELSE 0 END,
    p_response_ms,
    p_response_ms
  )
  ON CONFLICT (source_key, metric_date) DO UPDATE SET
    total_requests = api_gateway_metrics.total_requests + 1,
    cache_hits = api_gateway_metrics.cache_hits + CASE WHEN p_cache_hit THEN 1 ELSE 0 END,
    cache_misses = api_gateway_metrics.cache_misses + CASE WHEN NOT p_cache_hit THEN 1 ELSE 0 END,
    external_calls = api_gateway_metrics.external_calls + CASE WHEN p_external_call THEN 1 ELSE 0 END,
    failures = api_gateway_metrics.failures + CASE WHEN p_failure THEN 1 ELSE 0 END,
    avg_response_ms = (api_gateway_metrics.avg_response_ms * api_gateway_metrics.total_requests + p_response_ms)
                      / (api_gateway_metrics.total_requests + 1),
    p95_response_ms = GREATEST(api_gateway_metrics.p95_response_ms, p_response_ms);
END;
$$;

-- Need UNIQUE constraint on api_gateway_metrics for the upsert
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'uq_gateway_metrics_source_date'
  ) THEN
    ALTER TABLE public.api_gateway_metrics
      ADD CONSTRAINT uq_gateway_metrics_source_date UNIQUE (source_key, metric_date);
  END IF;
END $$;

-- ============================================================================
-- Grant execute on all functions to authenticated + service_role
-- ============================================================================
GRANT EXECUTE ON FUNCTION public.fn_api_cache_cleanup() TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_api_cache_lookup(varchar) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.fn_api_cache_lookup_stale(varchar) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.fn_api_cache_set(varchar, varchar, varchar, jsonb, int, uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_check_rate_limit(varchar) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_update_gateway_metrics(varchar, boolean, boolean, boolean, int) TO service_role;
