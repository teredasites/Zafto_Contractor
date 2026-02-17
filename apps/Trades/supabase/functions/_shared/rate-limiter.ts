/**
 * Persistent Rate Limiter for Supabase Edge Functions
 *
 * Uses Supabase table-based state (NOT in-memory). Survives cold starts,
 * scaling events, and function redeployments — no bypass possible.
 *
 * Usage in Edge Functions:
 * ```ts
 * import { checkRateLimit, rateLimitResponse } from '../_shared/rate-limiter.ts'
 *
 * const rateCheck = await checkRateLimit(supabaseAdmin, {
 *   key: `user:${user.id}:export-invoice`,
 *   maxRequests: 10,
 *   windowSeconds: 60,
 * })
 * if (!rateCheck.allowed) return rateLimitResponse(rateCheck.retryAfter!)
 * ```
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export interface RateLimitConfig {
  /** Unique key for this limit (e.g., `user:{uid}:export-invoice` or `company:{cid}:lead-aggregator`) */
  key: string
  /** Maximum requests allowed within the window */
  maxRequests: number
  /** Window duration in seconds */
  windowSeconds: number
}

export interface RateLimitResult {
  allowed: boolean
  remaining: number
  retryAfter?: number
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/**
 * Check rate limit against persistent Supabase table.
 * Atomic — uses FOR UPDATE row locking to prevent race conditions.
 * On DB error, gracefully allows the request (fail-open, not fail-closed)
 * to prevent rate limiter failures from breaking the application.
 */
export async function checkRateLimit(
  supabase: SupabaseClient,
  config: RateLimitConfig
): Promise<RateLimitResult> {
  try {
    const { data, error } = await supabase.rpc('check_rate_limit', {
      p_key: config.key,
      p_max_requests: config.maxRequests,
      p_window_seconds: config.windowSeconds,
    })

    if (error) {
      console.error('[rate-limiter] RPC error:', error.message)
      // Fail open — don't block users because of a DB issue
      return { allowed: true, remaining: config.maxRequests }
    }

    return {
      allowed: data.allowed as boolean,
      remaining: data.remaining as number,
      retryAfter: data.allowed ? undefined : (data.retry_after as number),
    }
  } catch (err) {
    console.error('[rate-limiter] Unexpected error:', err)
    // Fail open
    return { allowed: true, remaining: config.maxRequests }
  }
}

/**
 * Return a 429 Too Many Requests response with proper headers.
 */
export function rateLimitResponse(retryAfter: number): Response {
  return new Response(
    JSON.stringify({
      error: 'Too many requests. Please try again later.',
      retry_after: retryAfter,
    }),
    {
      status: 429,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'Retry-After': String(Math.ceil(retryAfter)),
      },
    }
  )
}
