'use client';

import { useEffect, useState } from 'react';
import { getSupabase } from '@/lib/supabase';

/**
 * useFeatureFlag — INFRA-5
 *
 * Reads from company_feature_flags table. Returns whether a flag is enabled.
 * Caches per-session. Used to gate features behind rollout percentages.
 *
 * Usage:
 * ```tsx
 * const aiEnabled = useFeatureFlag('ai_estimation');
 * if (!aiEnabled) return null; // Feature gated
 * ```
 */

const flagCache = new Map<string, boolean>();

export function useFeatureFlag(flagName: string): boolean {
  const [enabled, setEnabled] = useState(() => flagCache.get(flagName) ?? false);

  useEffect(() => {
    if (flagCache.has(flagName)) {
      setEnabled(flagCache.get(flagName)!);
      return;
    }

    let cancelled = false;

    async function check() {
      try {
        const supabase = getSupabase();
        const { data } = await supabase
          .from('company_feature_flags')
          .select('enabled, rollout_percentage')
          .eq('flag_name', flagName)
          .maybeSingle();

        if (cancelled) return;

        const isEnabled = data?.enabled === true && (data?.rollout_percentage ?? 100) >= 100;
        flagCache.set(flagName, isEnabled);
        setEnabled(isEnabled);
      } catch {
        if (!cancelled) setEnabled(false);
      }
    }

    check();
    return () => { cancelled = true; };
  }, [flagName]);

  return enabled;
}

/**
 * Clear all cached feature flags. Call after a feature flag is toggled.
 */
export function clearFeatureFlagCache(): void {
  flagCache.clear();
}
