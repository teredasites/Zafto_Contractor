'use client';

import { useState, useEffect } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface VerticalDetection {
  storm: boolean;
  reconstruction: boolean;
  commercial: boolean;
  warranty: boolean;
  loading: boolean;
}

// Detection rules (thresholds):
// Storm: jobs tagged with storm events >= 5
// Reconstruction: insurance claims with category='reconstruction' >= 3
// Commercial: insurance claims with category='commercial' >= 2
// Warranty: warranty company relationships >= 2

export function useVerticalDetection(): VerticalDetection {
  const [result, setResult] = useState<VerticalDetection>({
    storm: false,
    reconstruction: false,
    commercial: false,
    warranty: false,
    loading: true,
  });

  useEffect(() => {
    let cancelled = false;
    async function detect() {
      try {
        const supabase = getSupabase();

        const [stormRes, claimsRes, warrantyRes] = await Promise.all([
          // Storm: count jobs with storm:* tags
          supabase
            .from('jobs')
            .select('id', { count: 'exact', head: true })
            .contains('tags', ['storm:']),
          // Claims by category
          supabase
            .from('insurance_claims')
            .select('claim_category'),
          // Warranty relationships
          supabase
            .from('company_warranty_relationships')
            .select('id', { count: 'exact', head: true }),
        ]);

        if (cancelled) return;

        // Storm detection: use tag-based query, but contains won't partial-match.
        // Fallback: query jobs with tags and check client-side
        const stormFallback = await supabase
          .from('jobs')
          .select('tags')
          .not('tags', 'eq', '{}');
        const stormCount = (stormFallback.data || []).filter(
          (j: { tags: string[] }) => j.tags?.some((t: string) => t.startsWith('storm:'))
        ).length;

        const claims = (claimsRes.data || []) as { claim_category: string }[];
        const reconCount = claims.filter((c) => c.claim_category === 'reconstruction').length;
        const commercialCount = claims.filter((c) => c.claim_category === 'commercial').length;

        const warrantyCount = warrantyRes.count || 0;

        if (!cancelled) {
          setResult({
            storm: stormCount >= 5,
            reconstruction: reconCount >= 3,
            commercial: commercialCount >= 2,
            warranty: warrantyCount >= 2,
            loading: false,
          });
        }
      } catch (_) {
        if (!cancelled) {
          setResult((prev) => ({ ...prev, loading: false }));
        }
      }
    }
    detect();
    return () => { cancelled = true; };
  }, []);

  return result;
}
