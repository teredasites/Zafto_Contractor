'use client';

import { useEffect, useState } from 'react';
import { getSupabase } from '@/lib/supabase';

type DataSource =
  | 'nec_codes'
  | 'ibc_codes'
  | 'irc_codes'
  | 'osha_standards'
  | 'nfpa_codes'
  | 'bls_labor_rates'
  | 'material_pricing'
  | 'google_solar_api'
  | 'public_records'
  | 'weather_data'
  | 'iicrc_standards'
  | 'tax_tables'
  | 'state_licensing';

interface DataFreshnessState {
  /** All freshness dates as a map */
  dates: Record<string, string>;
  /** Get formatted date for a specific source */
  getDate: (source: DataSource) => string | null;
  /** Get formatted "as of" string for a specific source */
  getAsOf: (source: DataSource) => string;
  loading: boolean;
  error: string | null;
}

/**
 * useDataFreshness — LEGAL-3
 *
 * Returns the last-updated dates for all tracked data sources.
 * Used by disclaimers to dynamically show "NEC 2023 codes as of Dec 2025"
 * instead of hardcoded dates.
 *
 * Usage:
 * ```tsx
 * const { getAsOf } = useDataFreshness();
 * <p>{getAsOf('nec_codes')}</p> // "as of Dec 2025"
 * ```
 */
export function useDataFreshness(): DataFreshnessState {
  const [dates, setDates] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        const supabase = getSupabase();
        const { data, error: fetchError } = await supabase
          .from('system_settings')
          .select('value')
          .eq('key', 'data_freshness')
          .single();

        if (cancelled) return;

        if (fetchError) {
          setError(fetchError.message);
          setLoading(false);
          return;
        }

        setDates((data?.value as Record<string, string>) || {});
        setLoading(false);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : 'Failed to load data freshness');
          setLoading(false);
        }
      }
    }

    load();
    return () => { cancelled = true; };
  }, []);

  function getDate(source: DataSource): string | null {
    return dates[source] || null;
  }

  function getAsOf(source: DataSource): string {
    const date = dates[source];
    if (!date) return '';
    try {
      const d = new Date(date);
      return `as of ${d.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}`;
    } catch {
      return `as of ${date}`;
    }
  }

  return { dates, getDate, getAsOf, loading, error };
}
