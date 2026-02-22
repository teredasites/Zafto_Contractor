'use client';

// DEPTH29: Geographic Labor Rate Hook
// Provides BLS-backed labor rates by trade and location (ZIP → MSA → national).
// Burdened rate calculator includes payroll taxes, insurance, and benefits.

import { useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface LaborRateResult {
  trade: string;
  socCode: string | null; // BLS Standard Occupational Classification
  baseHourlyRate: number; // BLS median hourly wage
  burdenMultiplier: number; // payroll taxes + insurance + benefits
  burdenedRate: number; // base * burden
  regionCode: string | null; // CBSA MSA code
  regionName: string | null;
  source: 'msa' | 'national' | 'company'; // where the rate came from
}

export interface BurdenBreakdown {
  fica: number; // 7.65%
  futa: number; // ~0.6%
  suta: number; // ~2.5% (varies by state)
  workersComp: number; // ~5-15% (varies by trade)
  generalLiability: number; // ~2-5%
  healthInsurance: number; // ~$3-6/hr equivalent
  otherBenefits: number; // PTO, retirement, etc.
  totalMultiplier: number; // total burden as multiplier (e.g., 1.35 = 35% overhead)
}

// Trade → BLS SOC code mapping
const TRADE_SOC_MAP: Record<string, { soc: string; wcRate: number }> = {
  roofing: { soc: '47-2181', wcRate: 0.12 },
  siding: { soc: '47-2031', wcRate: 0.08 },
  painting: { soc: '47-2141', wcRate: 0.06 },
  electrical: { soc: '47-2111', wcRate: 0.05 },
  plumbing: { soc: '47-2152', wcRate: 0.06 },
  hvac: { soc: '49-9021', wcRate: 0.05 },
  carpentry: { soc: '47-2031', wcRate: 0.07 },
  concrete: { soc: '47-2051', wcRate: 0.10 },
  drywall: { soc: '47-2081', wcRate: 0.07 },
  flooring: { soc: '47-2042', wcRate: 0.05 },
  landscaping: { soc: '37-3011', wcRate: 0.08 },
  demolition: { soc: '47-5051', wcRate: 0.14 },
  insulation: { soc: '47-2131', wcRate: 0.07 },
  waterproofing: { soc: '47-2199', wcRate: 0.09 },
  gutters: { soc: '47-2181', wcRate: 0.10 },
  fencing: { soc: '47-4031', wcRate: 0.08 },
  solar: { soc: '47-2231', wcRate: 0.06 },
  general: { soc: '47-2061', wcRate: 0.07 },
};

// ============================================================================
// BURDEN CALCULATOR
// ============================================================================

export function calculateBurden(trade: string, state?: string): BurdenBreakdown {
  const tradeInfo = TRADE_SOC_MAP[trade] || TRADE_SOC_MAP.general;

  // Standard burden components (US averages)
  const fica = 0.0765; // Social Security 6.2% + Medicare 1.45%
  const futa = 0.006; // Federal unemployment
  const suta = 0.025; // State unemployment (varies, ~1-5%)
  const workersComp = tradeInfo.wcRate; // Trade-specific
  const generalLiability = 0.03; // General liability insurance
  const healthInsurance = 0.08; // ~$3-6/hr as percentage of ~$50/hr avg
  const otherBenefits = 0.04; // PTO, 401k match, etc.

  const totalMultiplier = 1 + fica + futa + suta + workersComp + generalLiability + healthInsurance + otherBenefits;

  return {
    fica,
    futa,
    suta,
    workersComp,
    generalLiability,
    healthInsurance,
    otherBenefits,
    totalMultiplier,
  };
}

// ============================================================================
// HOOK: useLaborRates
// ============================================================================

export function useLaborRates() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [rates, setRates] = useState<LaborRateResult[]>([]);

  // Lookup labor rates for a ZIP code and set of trades
  const lookupRates = useCallback(async (zip: string, trades: string[]) => {
    if (!zip || trades.length === 0) return;
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();

      // Step 1: ZIP → MSA region
      let regionCode: string | null = null;
      let regionName: string | null = null;

      const { data: msaResult } = await supabase.rpc('fn_zip_to_msa', { zip });
      if (msaResult && msaResult.length > 0) {
        regionCode = String(msaResult[0].cbsa_code);
        regionName = msaResult[0].cbsa_title || null;
      }

      // Step 2: Look up company-specific rates first
      const { data: { session } } = await supabase.auth.getSession();
      const companyId = session?.user?.app_metadata?.company_id;

      const results: LaborRateResult[] = [];

      for (const trade of trades) {
        const tradeInfo = TRADE_SOC_MAP[trade] || TRADE_SOC_MAP.general;
        const burden = calculateBurden(trade);
        let baseRate = 0;
        let source: 'msa' | 'national' | 'company' = 'national';

        // Company override?
        if (companyId) {
          const { data: companyRate } = await supabase
            .from('estimate_pricing')
            .select('labor_rate')
            .eq('company_id', companyId)
            .ilike('trade', trade)
            .limit(1)
            .maybeSingle();

          if (companyRate?.labor_rate) {
            baseRate = Number(companyRate.labor_rate);
            source = 'company';
          }
        }

        // Regional (MSA) rate?
        if (baseRate === 0 && regionCode) {
          const { data: regionalRate } = await supabase
            .from('estimate_pricing')
            .select('labor_rate')
            .is('company_id', null)
            .eq('region_code', regionCode)
            .ilike('trade', trade)
            .limit(1)
            .maybeSingle();

          if (regionalRate?.labor_rate) {
            baseRate = Number(regionalRate.labor_rate);
            source = 'msa';
          }
        }

        // National average fallback
        if (baseRate === 0) {
          const { data: nationalRate } = await supabase
            .from('estimate_pricing')
            .select('labor_rate')
            .is('company_id', null)
            .is('region_code', null)
            .ilike('trade', trade)
            .limit(1)
            .maybeSingle();

          if (nationalRate?.labor_rate) {
            baseRate = Number(nationalRate.labor_rate);
            source = 'national';
          }
        }

        results.push({
          trade,
          socCode: tradeInfo.soc,
          baseHourlyRate: baseRate,
          burdenMultiplier: burden.totalMultiplier,
          burdenedRate: baseRate * burden.totalMultiplier,
          regionCode,
          regionName,
          source,
        });
      }

      setRates(results);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to lookup labor rates');
    } finally {
      setLoading(false);
    }
  }, []);

  // Get rate for a specific trade (from cached results)
  const getRate = useCallback((trade: string): LaborRateResult | null => {
    return rates.find(r => r.trade === trade) || null;
  }, [rates]);

  return {
    rates,
    loading,
    error,
    lookupRates,
    getRate,
    calculateBurden,
  };
}
