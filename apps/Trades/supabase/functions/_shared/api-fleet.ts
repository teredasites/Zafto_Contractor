/**
 * Shared API Fleet Management utilities.
 * DEPTH28: Usage tracking, rate limit checking, self-healing patterns.
 * Every external API call should use trackApiUsage() and checkApiAvailable().
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1'

function getServiceClient() {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
}

/**
 * Track an API call. Increments current_month_usage and logs to api_usage_log.
 */
export async function trackApiUsage(
  apiName: string,
  opts?: {
    companyId?: string
    edgeFunction?: string
    responseMs?: number
    statusCode?: number
    success?: boolean
  }
): Promise<void> {
  try {
    const supabase = getServiceClient()

    // Log usage
    await supabase.from('api_usage_log').insert({
      api_name: apiName,
      company_id: opts?.companyId || null,
      edge_function: opts?.edgeFunction || null,
      response_ms: opts?.responseMs || null,
      status_code: opts?.statusCode || null,
      success: opts?.success ?? true,
    })

    // Increment monthly counter
    await supabase.rpc('increment_api_usage', { api_name_param: apiName })
  } catch (_e) {
    // Never let tracking failure break the actual API call
    console.error(`[api-fleet] Failed to track usage for ${apiName}:`, _e)
  }
}

/**
 * Check if an API is available (not down, not over limit).
 * Returns { available, reason } — if not available, reason explains why.
 */
export async function checkApiAvailable(
  apiName: string
): Promise<{ available: boolean; reason?: string }> {
  try {
    const supabase = getServiceClient()

    const { data } = await supabase
      .from('api_registry')
      .select('status, current_month_usage, free_tier_limit')
      .eq('name', apiName)
      .single()

    if (!data) return { available: true } // Not in registry = no restrictions

    if (data.status === 'down') {
      return { available: false, reason: `API ${apiName} is currently down` }
    }
    if (data.status === 'key_invalid') {
      return { available: false, reason: `API ${apiName} key is invalid` }
    }
    if (data.status === 'over_limit') {
      return { available: false, reason: `API ${apiName} has exceeded free tier limit` }
    }
    if (data.free_tier_limit && data.current_month_usage >= data.free_tier_limit * 0.95) {
      return { available: false, reason: `API ${apiName} is at 95%+ of free tier limit` }
    }

    return { available: true }
  } catch (_e) {
    // If we can't check, assume available (don't block on tracking failure)
    return { available: true }
  }
}

/**
 * Fetch with exponential backoff for rate-limited APIs.
 * Retries on 429 with exponential backoff (1s, 2s, 4s, 8s, max 30s).
 */
export async function fetchWithBackoff(
  url: string,
  options?: RequestInit,
  maxRetries = 3,
): Promise<Response> {
  let lastError: Error | null = null

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const response = await fetch(url, {
        ...options,
        signal: AbortSignal.timeout(30000), // 30s timeout
      })

      if (response.status === 429 && attempt < maxRetries) {
        const backoff = Math.min(1000 * Math.pow(2, attempt), 30000)
        await new Promise(r => setTimeout(r, backoff))
        continue
      }

      return response
    } catch (e) {
      lastError = e instanceof Error ? e : new Error(String(e))
      if (attempt < maxRetries) {
        const backoff = Math.min(1000 * Math.pow(2, attempt), 30000)
        await new Promise(r => setTimeout(r, backoff))
      }
    }
  }

  throw lastError || new Error(`fetchWithBackoff failed after ${maxRetries} retries`)
}

/**
 * Smart API call with fleet management integration.
 * Checks availability, tracks usage, handles failures gracefully.
 */
export async function fleetFetch(
  apiName: string,
  url: string,
  options?: RequestInit & {
    companyId?: string
    edgeFunction?: string
  }
): Promise<{ response: Response | null; skipped: boolean; reason?: string }> {
  // Check availability
  const check = await checkApiAvailable(apiName)
  if (!check.available) {
    return { response: null, skipped: true, reason: check.reason }
  }

  const start = Date.now()
  try {
    const response = await fetchWithBackoff(url, options)
    const responseMs = Date.now() - start

    // Track usage (non-blocking)
    trackApiUsage(apiName, {
      companyId: options?.companyId,
      edgeFunction: options?.edgeFunction,
      responseMs,
      statusCode: response.status,
      success: response.ok,
    })

    return { response, skipped: false }
  } catch (e) {
    const responseMs = Date.now() - start

    // Track failed usage
    trackApiUsage(apiName, {
      companyId: options?.companyId,
      edgeFunction: options?.edgeFunction,
      responseMs,
      statusCode: 0,
      success: false,
    })

    console.error(`[api-fleet] ${apiName} call failed:`, e)
    return { response: null, skipped: false, reason: e instanceof Error ? e.message : 'Unknown error' }
  }
}
