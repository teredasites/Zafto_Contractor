/**
 * DEPTH28: API Health Check Edge Function
 * Cron-triggered (every 6 hours via pg_cron).
 * Probes all registered APIs and updates health status.
 * Also handles monthly usage counter reset and health report generation.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1'
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts'

const PROBE_TIMEOUT_MS = 10000 // 10s per probe
const DEGRADED_THRESHOLD_MS = 5000 // >5s = degraded

interface ApiRecord {
  id: string
  name: string
  display_name: string
  base_url: string
  auth_type: string
  key_env_var: string | null
  probe_endpoint: string | null
  probe_method: string
  status: string
  free_tier_limit: number | null
  current_month_usage: number
}

interface ProbeResult {
  apiId: string
  name: string
  oldStatus: string
  newStatus: string
  responseMs: number
  statusCode: number
  errorMessage: string | null
}

Deno.serve(async (req) => {
  const origin = req.headers.get('Origin')
  if (req.method === 'OPTIONS') return corsResponse(origin)

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Fetch all registered APIs
    const { data: apis, error: fetchErr } = await supabase
      .from('api_registry')
      .select('*')
      .order('name')

    if (fetchErr || !apis) {
      return errorResponse('Failed to fetch API registry', 500, origin)
    }

    const results: ProbeResult[] = []

    // Probe each API
    for (const api of apis as ApiRecord[]) {
      const result = await probeApi(api)
      results.push(result)

      // Update api_registry
      const updates: Record<string, unknown> = {
        status: result.newStatus,
        last_check_at: new Date().toISOString(),
        avg_response_ms: result.responseMs > 0 ? result.responseMs : null,
      }

      if (result.newStatus === 'healthy') {
        updates.last_success_at = new Date().toISOString()
      } else {
        updates.last_error_at = new Date().toISOString()
        updates.last_error_message = result.errorMessage
      }

      await supabase
        .from('api_registry')
        .update(updates)
        .eq('id', api.id)

      // Log status change event
      if (result.oldStatus !== result.newStatus) {
        await supabase.from('api_health_events').insert({
          api_id: api.id,
          old_status: result.oldStatus,
          new_status: result.newStatus,
          response_ms: result.responseMs > 0 ? result.responseMs : null,
          status_code: result.statusCode > 0 ? result.statusCode : null,
          error_message: result.errorMessage,
        })
      }
    }

    // Check for monthly usage reset (1st of month)
    const now = new Date()
    const firstOfMonth = now.getDate() === 1 && now.getHours() < 6
    if (firstOfMonth) {
      await supabase
        .from('api_registry')
        .update({
          current_month_usage: 0,
          usage_reset_at: new Date().toISOString(),
        })
        .neq('id', '00000000-0000-0000-0000-000000000000') // update all

      // Generate monthly health report for previous month
      const prevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1)
      const reportMonth = `${prevMonth.getFullYear()}-${String(prevMonth.getMonth() + 1).padStart(2, '0')}`

      const totalCalls = (apis as ApiRecord[]).reduce((sum, a) => sum + (a.current_month_usage || 0), 0)
      const apisWithIncidents = results.filter(r => r.newStatus !== 'healthy').length

      await supabase.from('api_health_reports').insert({
        report_month: reportMonth,
        total_calls: totalCalls,
        avg_uptime_pct: 100, // Will be calculated from events over time
        apis_with_incidents: apisWithIncidents,
        total_cost_usd: 0, // $0/month forever
        details: {
          apis_checked: results.length,
          healthy: results.filter(r => r.newStatus === 'healthy').length,
          degraded: results.filter(r => r.newStatus === 'degraded').length,
          down: results.filter(r => r.newStatus === 'down').length,
        },
      })
    }

    const summary = {
      checked: results.length,
      healthy: results.filter(r => r.newStatus === 'healthy').length,
      degraded: results.filter(r => r.newStatus === 'degraded').length,
      down: results.filter(r => r.newStatus === 'down').length,
      over_limit: results.filter(r => r.newStatus === 'over_limit').length,
      key_invalid: results.filter(r => r.newStatus === 'key_invalid').length,
      status_changes: results.filter(r => r.oldStatus !== r.newStatus).length,
    }

    return new Response(
      JSON.stringify({ ok: true, summary, results }),
      {
        status: 200,
        headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
      }
    )
  } catch (e) {
    console.error('[api-health-check] Fatal error:', e)
    return errorResponse(
      e instanceof Error ? e.message : 'Health check failed',
      500,
      origin,
    )
  }
})

/**
 * Probe a single API and determine its health status.
 */
async function probeApi(api: ApiRecord): Promise<ProbeResult> {
  const result: ProbeResult = {
    apiId: api.id,
    name: api.name,
    oldStatus: api.status || 'unknown',
    newStatus: 'unknown',
    responseMs: 0,
    statusCode: 0,
    errorMessage: null,
  }

  // Check usage limits first
  if (api.free_tier_limit && api.current_month_usage >= api.free_tier_limit) {
    result.newStatus = 'over_limit'
    result.errorMessage = `Usage ${api.current_month_usage}/${api.free_tier_limit} (at limit)`
    return result
  }

  if (!api.probe_endpoint) {
    // No probe configured — keep current status or mark unknown
    result.newStatus = api.status === 'unknown' ? 'unknown' : api.status
    return result
  }

  // Build probe URL
  let probeUrl = api.probe_endpoint.startsWith('http')
    ? api.probe_endpoint
    : `${api.base_url}${api.probe_endpoint}`

  // Append API key if needed
  if (api.auth_type === 'api_key' && api.key_env_var) {
    const key = Deno.env.get(api.key_env_var)
    if (!key) {
      result.newStatus = 'key_invalid'
      result.errorMessage = `Missing env var: ${api.key_env_var}`
      return result
    }
    // Append key to URL if probe URL ends with 'key=' pattern
    if (probeUrl.endsWith('key=') || probeUrl.endsWith('api_key=') || probeUrl.endsWith('access_token=')) {
      probeUrl += key
    } else if (probeUrl.includes('?')) {
      probeUrl += `&key=${key}`
    } else {
      probeUrl += `?key=${key}`
    }
  }

  // Build headers
  const headers: Record<string, string> = {
    'User-Agent': 'Zafto-HealthCheck/1.0',
  }

  if (api.auth_type === 'bearer' && api.key_env_var) {
    const key = Deno.env.get(api.key_env_var)
    if (!key) {
      result.newStatus = 'key_invalid'
      result.errorMessage = `Missing env var: ${api.key_env_var}`
      return result
    }
    headers['Authorization'] = `Bearer ${key}`
  }

  // Execute probe
  const start = Date.now()
  try {
    const response = await fetch(probeUrl, {
      method: api.probe_method || 'GET',
      headers,
      signal: AbortSignal.timeout(PROBE_TIMEOUT_MS),
    })

    result.responseMs = Date.now() - start
    result.statusCode = response.status

    if (response.ok) {
      result.newStatus = result.responseMs > DEGRADED_THRESHOLD_MS ? 'degraded' : 'healthy'
    } else if (response.status === 401 || response.status === 403) {
      result.newStatus = 'key_invalid'
      result.errorMessage = `Auth failed: HTTP ${response.status}`
    } else if (response.status === 429) {
      result.newStatus = 'degraded'
      result.errorMessage = 'Rate limited (429)'
    } else {
      result.newStatus = 'down'
      result.errorMessage = `HTTP ${response.status}`
    }
  } catch (e) {
    result.responseMs = Date.now() - start
    result.newStatus = 'down'
    result.errorMessage = e instanceof Error ? e.message : 'Probe failed'
  }

  return result
}
