/**
 * Shared API Cost Logger
 * Logs every external API call to `api_cost_log` table for monitoring and budgeting.
 *
 * Used by all Recon Edge Functions that call external APIs:
 * - recon-property-lookup (Google Geocoding, Google Solar, USGS, Overpass, ATTOM, Regrid)
 * - recon-area-scan (Overpass, Nominatim)
 * - recon-storm-assess (NOAA)
 * - recon-material-order (Unwrangle)
 *
 * Non-blocking: errors are logged but never thrown. API cost tracking
 * should never break the feature that's making the API call.
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export interface ApiCallLog {
  /** Company making the request */
  company_id: string
  /** API name: 'google_geocoding', 'google_solar', 'usgs_3dep', 'overpass', 'attom', 'regrid', 'nominatim', 'noaa', 'unwrangle' */
  api_name: string
  /** Full endpoint URL or path */
  endpoint: string
  /** HTTP status code returned */
  response_status: number
  /** Request latency in milliseconds */
  latency_ms: number
  /** Cost in cents (0 for free APIs) */
  cost_cents?: number
  /** Optional request payload (truncated for large payloads) */
  request_payload?: Record<string, unknown>
  /** User who triggered the request */
  created_by?: string
}

/**
 * Log an API call to the api_cost_log table.
 * Non-blocking — catches all errors silently to avoid breaking the calling function.
 */
export async function logApiCall(
  supabase: SupabaseClient,
  log: ApiCallLog,
): Promise<void> {
  try {
    await supabase.from('api_cost_log').insert({
      company_id: log.company_id,
      api_name: log.api_name,
      endpoint: log.endpoint,
      response_status: log.response_status,
      latency_ms: log.latency_ms,
      cost_cents: log.cost_cents ?? 0,
      request_payload: log.request_payload ?? null,
      created_by: log.created_by ?? null,
    })
  } catch (err) {
    console.error('[api-cost-logger] Failed to log API call:', err)
    // Non-blocking — never throw
  }
}

/**
 * Helper to time a fetch call and log it.
 * Returns the fetch Response and logs the call automatically.
 */
export async function timedFetch(
  supabase: SupabaseClient,
  url: string,
  options: RequestInit,
  logInfo: Omit<ApiCallLog, 'endpoint' | 'response_status' | 'latency_ms'>,
): Promise<Response> {
  const start = performance.now()
  let response: Response
  try {
    response = await fetch(url, options)
  } catch (err) {
    const latency = Math.round(performance.now() - start)
    await logApiCall(supabase, {
      ...logInfo,
      endpoint: url,
      response_status: 0,
      latency_ms: latency,
    })
    throw err
  }
  const latency = Math.round(performance.now() - start)
  await logApiCall(supabase, {
    ...logInfo,
    endpoint: url,
    response_status: response.status,
    latency_ms: latency,
  })
  return response
}
