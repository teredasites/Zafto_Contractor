// Supabase Edge Function: api-gateway
// DATA-ARCH3 — Unified runtime API proxy with caching + fallback chain.
// Client sends: { source: "nhtsa-vin", params: { vin: "..." } }
// Gateway: cache check → rate limit check → external call → cache set → return.
// Fallback: primary → fallback_source → stale cache → { unavailable: true }.
// NEVER crashes, NEVER returns blank.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts'

// ── Types ──

interface GatewayRequest {
  source: string          // data_sources.source_key
  params: Record<string, unknown>
  company_id?: string     // For company-scoped cache
  bypass_cache?: boolean  // Force fresh fetch
}

interface GatewayResponse {
  data: unknown
  source: string
  cached: boolean
  stale: boolean
  unavailable: boolean
  message?: string
  cached_at?: string
  response_ms: number
}

interface SourceConfig {
  source_key: string
  base_url: string
  auth_method: string
  rate_limit_remaining: number
  rate_limit_per_day: number
  fallback_source_key: string | null
  is_active: boolean
  refresh_frequency: string
}

// ── Source-specific request builders ──
// Each source has a URL builder + response extractor.
// New API = new entry here. Everything else is shared.

interface SourceAdapter {
  buildUrl: (baseUrl: string, params: Record<string, unknown>) => string
  extractData: (response: unknown) => unknown
  ttlSeconds: number
  headers?: Record<string, string>
}

const SOURCE_ADAPTERS: Record<string, SourceAdapter> = {
  // NHTSA VIN Decoder — free, no key, 5 requests/sec
  'nhtsa-vin': {
    buildUrl: (base, params) =>
      `${base}/vehicles/DecodeVin/${params.vin}?format=json`,
    extractData: (resp: unknown) => {
      const r = resp as { Results?: unknown[] }
      return r?.Results || resp
    },
    ttlSeconds: 86400 * 30, // VIN data doesn't change — cache 30 days
  },

  // USPS Address Validation (via Nominatim as free fallback)
  'nominatim-geocode': {
    buildUrl: (base, params) => {
      const q = encodeURIComponent(String(params.address || ''))
      return `${base}/search?q=${q}&format=json&limit=1&countrycodes=us`
    },
    extractData: (resp: unknown) => {
      const results = resp as Array<Record<string, unknown>>
      if (!results?.length) return null
      const r = results[0]
      return {
        lat: parseFloat(String(r.lat)),
        lng: parseFloat(String(r.lon)),
        display_name: r.display_name,
        type: r.type,
        importance: r.importance,
      }
    },
    ttlSeconds: 86400 * 7, // Addresses rarely change — cache 7 days
    headers: { 'User-Agent': 'ZaftoApp/1.0 (https://zafto.cloud)' },
  },

  // NWS Weather — free, no key
  'nws-weather': {
    buildUrl: (base, params) => {
      if (params.grid_id && params.grid_x && params.grid_y) {
        return `${base}/gridpoints/${params.grid_id}/${params.grid_x},${params.grid_y}/forecast`
      }
      return `${base}/points/${params.lat},${params.lng}`
    },
    extractData: (resp: unknown) => {
      const r = resp as { properties?: unknown }
      return r?.properties || resp
    },
    ttlSeconds: 1800, // Weather: cache 30 min
  },

  // CPSC Product Recalls — free, no key
  'cpsc-recalls': {
    buildUrl: (base, params) => {
      const q = encodeURIComponent(String(params.query || ''))
      return `${base}/Recall?format=json&RecallTitle=${q}`
    },
    extractData: (resp: unknown) => resp,
    ttlSeconds: 86400, // Recalls: cache 1 day
  },

  // NOAA SPC Storm Reports — free
  'noaa-spc-storms': {
    buildUrl: (base, params) => {
      const date = params.date || new Date().toISOString().slice(0, 10).replace(/-/g, '')
      return `${base}/${date}_rpts_raw_torn.csv`
    },
    extractData: (resp: unknown) => resp,
    ttlSeconds: 3600, // Storm reports: cache 1 hour
  },

  // UPCitemdb — Barcode to product lookup, free tier
  'upcitemdb-lookup': {
    buildUrl: (base, params) =>
      `${base}/prod/trial/lookup?upc=${params.upc}`,
    extractData: (resp: unknown) => {
      const r = resp as { items?: unknown[] }
      return r?.items?.[0] || null
    },
    ttlSeconds: 86400 * 30, // Product info: cache 30 days
  },

  // FEMA Flood Zones — free
  'fema-nfhl': {
    buildUrl: (base, params) =>
      `${base}/arcgis/rest/services/public/NFHL/MapServer/28/query?` +
      `geometry=${params.lng},${params.lat}&geometryType=esriGeometryPoint` +
      `&spatialRel=esriSpatialRelIntersects&outFields=*&returnGeometry=false&f=json`,
    extractData: (resp: unknown) => {
      const r = resp as { features?: Array<{ attributes: unknown }> }
      return r?.features?.[0]?.attributes || null
    },
    ttlSeconds: 86400 * 30, // Flood zones rarely change
  },

  // Walk Score — free tier (5,000/day)
  'walkscore': {
    buildUrl: (base, params) => {
      const key = Deno.env.get('WALKSCORE_API_KEY') || ''
      return `${base}/score?format=json&lat=${params.lat}&lon=${params.lng}&wsapikey=${key}`
    },
    extractData: (resp: unknown) => resp,
    ttlSeconds: 86400 * 7, // Walk scores: cache 7 days
  },

  // FRED Economic Data — free (120 requests/min)
  'fred-series': {
    buildUrl: (base, params) => {
      const key = Deno.env.get('FRED_API_KEY') || ''
      return `${base}/series/observations?series_id=${params.series_id}` +
        `&api_key=${key}&file_type=json&sort_order=desc&limit=${params.limit || 10}`
    },
    extractData: (resp: unknown) => {
      const r = resp as { observations?: unknown[] }
      return r?.observations || []
    },
    ttlSeconds: 86400, // Economic data: cache 1 day
  },

  // BLS OEWS — free (500/day v2)
  'bls-oews': {
    buildUrl: (base, params) => {
      // BLS v2 uses POST, but we build the URL for cache key purposes
      return `${base}/publicAPI/v2/timeseries/data/${params.series_id}`
    },
    extractData: (resp: unknown) => {
      const r = resp as { Results?: { series?: Array<{ data?: unknown[] }> } }
      return r?.Results?.series?.[0]?.data || []
    },
    ttlSeconds: 86400 * 7, // BLS data: cache 7 days (updated quarterly)
  },

  // Generic fallback — for any registered source without a specific adapter
  '_generic': {
    buildUrl: (base, params) => {
      const queryParts = Object.entries(params)
        .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
        .join('&')
      return queryParts ? `${base}?${queryParts}` : base
    },
    extractData: (resp: unknown) => resp,
    ttlSeconds: 3600, // Default: cache 1 hour
  },
}

// ── Utility: Build cache key ──
function buildCacheKey(source: string, params: Record<string, unknown>, companyId?: string): string {
  const sortedParams = Object.keys(params).sort()
    .map(k => `${k}=${JSON.stringify(params[k])}`)
    .join('&')
  const base = `${source}:${sortedParams}`
  return companyId ? `${companyId}:${base}` : base
}

// ── Utility: SHA-256 hash ──
async function sha256(data: string): Promise<string> {
  const encoder = new TextEncoder()
  const hashBuffer = await crypto.subtle.digest('SHA-256', encoder.encode(data))
  return Array.from(new Uint8Array(hashBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('')
}

// ── Core: Execute gateway request ──
async function executeGateway(
  supabase: ReturnType<typeof createClient>,
  req: GatewayRequest
): Promise<GatewayResponse> {
  const startMs = Date.now()
  const cacheKey = buildCacheKey(req.source, req.params, req.company_id)
  const paramsHash = await sha256(JSON.stringify(req.params))

  // Step 1: Check cache (unless bypassed)
  if (!req.bypass_cache) {
    const { data: cached } = await supabase.rpc('fn_api_cache_lookup', {
      p_cache_key: cacheKey,
    })

    if (cached?.hit) {
      // Track metric: cache hit
      await supabase.rpc('fn_update_gateway_metrics', {
        p_source_key: req.source,
        p_cache_hit: true,
        p_response_ms: Date.now() - startMs,
      })

      return {
        data: cached.data,
        source: req.source,
        cached: true,
        stale: false,
        unavailable: false,
        response_ms: Date.now() - startMs,
      }
    }
  }

  // Step 2: Load source config
  const { data: sourceConfig } = await supabase
    .from('data_sources')
    .select('source_key, base_url, auth_method, rate_limit_remaining, rate_limit_per_day, fallback_source_key, is_active, refresh_frequency')
    .eq('source_key', req.source)
    .is('deleted_at', null)
    .single()

  if (!sourceConfig) {
    return {
      data: null,
      source: req.source,
      cached: false,
      stale: false,
      unavailable: true,
      message: `Unknown source: ${req.source}`,
      response_ms: Date.now() - startMs,
    }
  }

  if (!sourceConfig.is_active) {
    return {
      data: null,
      source: req.source,
      cached: false,
      stale: false,
      unavailable: true,
      message: `Source "${req.source}" is currently disabled`,
      response_ms: Date.now() - startMs,
    }
  }

  // Step 3: Try primary source
  const primaryResult = await tryFetchSource(
    supabase, sourceConfig as SourceConfig, req.params, cacheKey, paramsHash, req.company_id
  )

  if (primaryResult.success) {
    // Track metric: external call success
    await supabase.rpc('fn_update_gateway_metrics', {
      p_source_key: req.source,
      p_cache_hit: false,
      p_external_call: true,
      p_response_ms: Date.now() - startMs,
    })

    return {
      data: primaryResult.data,
      source: req.source,
      cached: false,
      stale: false,
      unavailable: false,
      response_ms: Date.now() - startMs,
    }
  }

  // Step 4: Try fallback source
  if (sourceConfig.fallback_source_key) {
    const { data: fallbackConfig } = await supabase
      .from('data_sources')
      .select('source_key, base_url, auth_method, rate_limit_remaining, rate_limit_per_day, fallback_source_key, is_active, refresh_frequency')
      .eq('source_key', sourceConfig.fallback_source_key)
      .is('deleted_at', null)
      .single()

    if (fallbackConfig?.is_active) {
      const fallbackCacheKey = buildCacheKey(
        fallbackConfig.source_key, req.params, req.company_id
      )
      const fallbackResult = await tryFetchSource(
        supabase, fallbackConfig as SourceConfig, req.params, fallbackCacheKey, paramsHash, req.company_id
      )

      if (fallbackResult.success) {
        await supabase.rpc('fn_update_gateway_metrics', {
          p_source_key: req.source,
          p_cache_hit: false,
          p_external_call: true,
          p_response_ms: Date.now() - startMs,
        })

        return {
          data: fallbackResult.data,
          source: fallbackConfig.source_key,
          cached: false,
          stale: false,
          unavailable: false,
          message: `Served by fallback: ${fallbackConfig.source_key}`,
          response_ms: Date.now() - startMs,
        }
      }
    }
  }

  // Step 5: Return stale cache if available
  const { data: staleCache } = await supabase.rpc('fn_api_cache_lookup_stale', {
    p_cache_key: cacheKey,
  })

  if (staleCache?.hit) {
    await supabase.rpc('fn_update_gateway_metrics', {
      p_source_key: req.source,
      p_cache_hit: true,
      p_failure: true,
      p_response_ms: Date.now() - startMs,
    })

    return {
      data: staleCache.data,
      source: req.source,
      cached: true,
      stale: true,
      unavailable: false,
      cached_at: staleCache.cached_at,
      message: 'Data may be outdated — served from stale cache',
      response_ms: Date.now() - startMs,
    }
  }

  // Step 6: Fully unavailable
  await supabase.rpc('fn_update_gateway_metrics', {
    p_source_key: req.source,
    p_failure: true,
    p_response_ms: Date.now() - startMs,
  })

  return {
    data: null,
    source: req.source,
    cached: false,
    stale: false,
    unavailable: true,
    message: `${req.source} is temporarily unavailable. ${primaryResult.error || ''}`.trim(),
    response_ms: Date.now() - startMs,
  }
}

// ── Try fetching from a single source ──
async function tryFetchSource(
  supabase: ReturnType<typeof createClient>,
  config: SourceConfig,
  params: Record<string, unknown>,
  cacheKey: string,
  paramsHash: string,
  companyId?: string
): Promise<{ success: boolean; data?: unknown; error?: string }> {
  try {
    // Check rate limit
    const { data: rateLimitResult } = await supabase.rpc('fn_check_rate_limit', {
      p_source_key: config.source_key,
    })

    if (!rateLimitResult?.allowed) {
      return {
        success: false,
        error: `Rate limited: ${rateLimitResult?.reason || 'unknown'}`,
      }
    }

    // Get adapter
    const adapter = SOURCE_ADAPTERS[config.source_key] || SOURCE_ADAPTERS['_generic']
    const url = adapter.buildUrl(config.base_url, params)

    // Build headers
    const headers: Record<string, string> = {
      'Accept': 'application/json',
      ...(adapter.headers || {}),
    }

    // Auth methods
    if (config.auth_method === 'api_key') {
      const key = Deno.env.get(`${config.source_key.toUpperCase().replace(/-/g, '_')}_API_KEY`)
      if (key) headers['Authorization'] = `Bearer ${key}`
    }

    // Fetch with timeout (5 seconds)
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 5000)

    let response: Response
    try {
      // BLS uses POST for v2
      if (config.source_key === 'bls-oews' || config.source_key === 'bls-ppi') {
        response = await fetch(config.base_url + '/publicAPI/v2/timeseries/data/', {
          method: 'POST',
          headers: { ...headers, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            seriesid: [params.series_id],
            startyear: params.start_year || String(new Date().getFullYear() - 1),
            endyear: params.end_year || String(new Date().getFullYear()),
            registrationkey: Deno.env.get('BLS_API_KEY') || '',
          }),
          signal: controller.signal,
        })
      } else {
        response = await fetch(url, { headers, signal: controller.signal })
      }
    } finally {
      clearTimeout(timeoutId)
    }

    if (!response.ok) {
      return {
        success: false,
        error: `HTTP ${response.status}: ${response.statusText}`,
      }
    }

    const contentType = response.headers.get('content-type') || ''
    let rawData: unknown

    if (contentType.includes('json')) {
      rawData = await response.json()
    } else {
      rawData = await response.text()
    }

    // Extract relevant data via adapter
    const extracted = adapter.extractData(rawData)

    // Cache the response
    await supabase.rpc('fn_api_cache_set', {
      p_cache_key: cacheKey,
      p_source_key: config.source_key,
      p_params_hash: paramsHash,
      p_response: typeof extracted === 'string' ? JSON.stringify(extracted) : extracted,
      p_ttl_seconds: adapter.ttlSeconds,
      p_company_id: companyId || null,
    })

    return { success: true, data: extracted }
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    // AbortError means timeout
    if (message.includes('abort')) {
      return { success: false, error: 'Request timed out (5s)' }
    }
    return { success: false, error: message }
  }
}

// ── HTTP handler ──
serve(async (req: Request) => {
  const origin = req.headers.get('Origin')
  if (req.method === 'OPTIONS') return corsResponse(origin)

  const headers = {
    ...getCorsHeaders(origin),
    'Content-Type': 'application/json',
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // Auth: require valid JWT
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return errorResponse('Missing Authorization header', 401, origin)
    }

    const supabase = createClient(supabaseUrl, serviceKey, {
      global: { headers: { Authorization: authHeader } },
    })

    // Verify user
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (authError || !user) {
      return errorResponse('Invalid or expired token', 401, origin)
    }

    const companyId = user.app_metadata?.company_id as string | undefined

    if (req.method === 'POST') {
      const body = await req.json() as GatewayRequest

      if (!body.source) {
        return errorResponse('Missing "source" in request body', 400, origin)
      }
      if (!body.params || typeof body.params !== 'object') {
        return errorResponse('Missing or invalid "params" in request body', 400, origin)
      }

      // Use service_role client for cache operations
      const serviceClient = createClient(supabaseUrl, serviceKey)

      const result = await executeGateway(serviceClient, {
        source: body.source,
        params: body.params,
        company_id: body.company_id || companyId,
        bypass_cache: body.bypass_cache,
      })

      return new Response(JSON.stringify(result), { headers })
    }

    if (req.method === 'GET') {
      // GET /api-gateway?action=sources — list available sources
      const url = new URL(req.url)
      const action = url.searchParams.get('action')

      const serviceClient = createClient(supabaseUrl, serviceKey)

      if (action === 'sources') {
        const { data: sources } = await serviceClient
          .from('data_sources')
          .select('source_key, display_name, category, tier, is_active, last_status, rate_limit_remaining, rate_limit_per_day')
          .is('deleted_at', null)
          .order('tier')
          .order('category')

        return new Response(JSON.stringify({ sources: sources || [] }), { headers })
      }

      if (action === 'cache-stats') {
        const { data: stats } = await serviceClient.rpc('fn_api_cache_cleanup')
        const { count } = await serviceClient
          .from('api_cache')
          .select('*', { count: 'exact', head: true })

        return new Response(JSON.stringify({
          total_cached: count || 0,
          last_cleanup: stats,
        }), { headers })
      }

      return new Response(JSON.stringify({
        service: 'api-gateway',
        version: '1.0.0',
        endpoints: {
          'POST /': 'Execute API gateway request { source, params, bypass_cache? }',
          'GET /?action=sources': 'List available API sources',
          'GET /?action=cache-stats': 'Cache statistics',
        },
      }), { headers })
    }

    return errorResponse('Method not allowed', 405, origin)
  } catch (err) {
    console.error('API Gateway error:', err)
    return errorResponse(
      err instanceof Error ? err.message : 'Internal gateway error',
      500,
      origin
    )
  }
})
