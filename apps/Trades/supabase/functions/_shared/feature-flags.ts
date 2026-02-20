/**
 * Feature flag utility — INFRA-5
 *
 * Reads from company_feature_flags table with 5-minute in-memory cache.
 * Used in Edge Functions to gate features behind rollout percentages.
 *
 * Usage:
 * ```ts
 * import { isFeatureEnabled } from '../_shared/feature-flags.ts'
 *
 * if (await isFeatureEnabled(supabase, companyId, 'ai_estimation')) {
 *   // Feature is enabled for this company
 * }
 * ```
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface CacheEntry {
  flags: Map<string, { enabled: boolean; rollout: number }>
  timestamp: number
}

const CACHE_TTL_MS = 5 * 60 * 1000 // 5 minutes
const cache = new Map<string, CacheEntry>()

export async function isFeatureEnabled(
  supabase: SupabaseClient,
  companyId: string,
  flagName: string,
): Promise<boolean> {
  const now = Date.now()
  const cached = cache.get(companyId)

  if (cached && now - cached.timestamp < CACHE_TTL_MS) {
    const flag = cached.flags.get(flagName)
    if (!flag) return false
    return flag.enabled && flag.rollout >= 100
  }

  // Fetch all flags for this company
  try {
    const { data, error } = await supabase
      .from('company_feature_flags')
      .select('flag_name, enabled, rollout_percentage')
      .eq('company_id', companyId)

    if (error) {
      console.error('[feature-flags] Fetch error:', error.message)
      return false // Fail closed — feature not available if flags can't be read
    }

    const flags = new Map<string, { enabled: boolean; rollout: number }>()
    for (const row of data || []) {
      flags.set(row.flag_name, {
        enabled: row.enabled,
        rollout: row.rollout_percentage || 100,
      })
    }

    cache.set(companyId, { flags, timestamp: now })

    const flag = flags.get(flagName)
    if (!flag) return false
    return flag.enabled && flag.rollout >= 100
  } catch (err) {
    console.error('[feature-flags] Unexpected error:', err)
    return false // Fail closed
  }
}

/**
 * Clear the cache for a specific company or all companies.
 * Useful after updating feature flags.
 */
export function clearFlagCache(companyId?: string): void {
  if (companyId) {
    cache.delete(companyId)
  } else {
    cache.clear()
  }
}
