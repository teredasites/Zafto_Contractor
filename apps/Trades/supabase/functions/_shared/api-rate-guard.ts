/**
 * External API Rate Guard
 * Checks and enforces rate limits for external API calls using `api_rate_limits` table.
 *
 * This is DIFFERENT from `rate-limiter.ts` which limits user requests to Edge Functions.
 * This module limits outbound API calls to external services (Google, ATTOM, Overpass, etc.)
 * to prevent hitting provider quotas and incurring overage charges.
 *
 * Uses hourly windows. If at limit, returns false — caller should use cached/degraded result.
 *
 * Fail-open: if the DB is unreachable, allows the call (don't break features over rate tracking).
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

/** Known API rate limits (requests per hour) */
export const API_LIMITS: Record<string, number> = {
  'google_geocoding': 2500,   // $5/1000 after free tier
  'google_solar': 100,        // Limited free tier
  'usgs_3dep': 10000,         // Effectively unlimited
  'overpass': 10000,           // Fair-use, but generous
  'attom': 50,                // Paid — conservative
  'regrid': 50,               // Paid — conservative
  'nominatim': 3600,          // 1 req/sec = 3600/hr
  'noaa': 5000,               // Very generous
  'unwrangle': 100,           // Paid — conservative
}

export interface RateGuardResult {
  allowed: boolean
  remaining: number
  window_start: string
}

/**
 * Check if an external API call is within rate limits.
 * If allowed, increments the counter atomically.
 * If at limit, returns { allowed: false } — caller should degrade gracefully.
 */
export async function checkApiRateLimit(
  supabase: SupabaseClient,
  companyId: string,
  apiName: string,
): Promise<RateGuardResult> {
  const maxRequests = API_LIMITS[apiName] ?? 100
  const windowStart = new Date()
  windowStart.setMinutes(0, 0, 0) // Truncate to current hour
  const windowKey = windowStart.toISOString()

  try {
    // Try to read existing entry for this window
    const { data: existing } = await supabase
      .from('api_rate_limits')
      .select('id, request_count, max_requests')
      .eq('company_id', companyId)
      .eq('api_name', apiName)
      .eq('window_start', windowKey)
      .maybeSingle()

    if (!existing) {
      // First request in this window — create entry
      await supabase.from('api_rate_limits').insert({
        company_id: companyId,
        api_name: apiName,
        window_start: windowKey,
        request_count: 1,
        max_requests: maxRequests,
      })
      return { allowed: true, remaining: maxRequests - 1, window_start: windowKey }
    }

    if (existing.request_count >= (existing.max_requests || maxRequests)) {
      return { allowed: false, remaining: 0, window_start: windowKey }
    }

    // Increment counter
    await supabase
      .from('api_rate_limits')
      .update({ request_count: existing.request_count + 1 })
      .eq('id', existing.id)

    const remaining = (existing.max_requests || maxRequests) - existing.request_count - 1
    return { allowed: true, remaining, window_start: windowKey }
  } catch (err) {
    console.error('[api-rate-guard] Error checking rate limit:', err)
    // Fail open — don't block API calls due to rate tracking issues
    return { allowed: true, remaining: maxRequests, window_start: windowKey }
  }
}
