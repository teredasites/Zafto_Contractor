'use client';

import { useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface StormPropertyResult {
  property_scan_id: string;
  probability: number;
  max_hail: number;
  max_wind: number;
  address?: string;
  city?: string | null;
  state?: string | null;
}

export interface StormAssessmentResult {
  // Single property fields
  property_scan_id?: string;
  storm_events_found: number;
  probability?: number;
  maxHailInches?: number;
  maxWindKnots?: number;
  nearestEventMiles?: number;
  // Area scan fields
  area_scan_id?: string;
  properties_assessed?: number;
  high_probability?: number;
  medium_probability?: number;
  low_probability?: number;
  results?: StormPropertyResult[];
}

// ============================================================================
// HOOK: useStormAssess
// ============================================================================

export function useStormAssess() {
  const [result, setResult] = useState<StormAssessmentResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const assessArea = useCallback(async (params: {
    area_scan_id: string;
    storm_date: string;
    state: string;
    county?: string;
  }) => {
    setLoading(true);
    setError(null);
    setResult(null);

    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-storm-assess`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify(params),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Storm assessment failed');

      // Enrich results with addresses from lead scores
      if (data.results && Array.isArray(data.results)) {
        const scanIds = data.results.map((r: StormPropertyResult) => r.property_scan_id);
        if (scanIds.length > 0) {
          const { data: scans } = await supabase
            .from('property_scans')
            .select('id, address, city, state')
            .in('id', scanIds)
            .is('deleted_at', null);

          if (scans) {
            const scanMap = new Map(scans.map((s: Record<string, unknown>) => [s.id as string, s]));
            data.results = data.results.map((r: StormPropertyResult) => {
              const scanRow = scanMap.get(r.property_scan_id) as Record<string, unknown> | undefined;
              return {
                ...r,
                address: scanRow?.address as string | undefined,
                city: scanRow?.city as string | null | undefined,
                state: scanRow?.state as string | null | undefined,
              };
            });
          }
        }
      }

      setResult(data as StormAssessmentResult);
      return data as StormAssessmentResult;
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Storm assessment failed';
      setError(msg);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  const assessProperty = useCallback(async (params: {
    property_scan_id: string;
    storm_date: string;
    state: string;
    county?: string;
  }) => {
    setLoading(true);
    setError(null);
    setResult(null);

    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-storm-assess`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify(params),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Storm assessment failed');

      setResult(data as StormAssessmentResult);
      return data as StormAssessmentResult;
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Storm assessment failed';
      setError(msg);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  const reset = useCallback(() => {
    setResult(null);
    setError(null);
  }, []);

  return { result, loading, error, assessArea, assessProperty, reset };
}
