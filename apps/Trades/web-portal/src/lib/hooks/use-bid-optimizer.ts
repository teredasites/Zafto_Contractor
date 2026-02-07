'use client';

import { useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ==================== TYPES ====================

export interface PriceRange {
  low: number;
  optimal: number;
  high: number;
}

export interface ScopeSuggestion {
  title: string;
  description: string;
  estimated_value: number;
  priority: 'high' | 'medium' | 'low';
  rationale: string;
}

export interface PricingAdjustment {
  item: string;
  current_price: number;
  suggested_price: number;
  reason: string;
  impact: 'positive' | 'negative' | 'neutral';
}

export interface RiskFactor {
  category: string;
  description: string;
  severity: 'high' | 'medium' | 'low';
  mitigation: string;
}

export interface HistoricalStats {
  total_bids: number;
  accepted: number;
  rejected: number;
  win_rate: number;
  avg_amount: number;
  avg_accepted_amount: number;
  avg_rejected_amount: number;
  median_amount: number;
}

export interface BidOptimization {
  success: boolean;
  bid_id: string | null;
  company_id: string;
  win_probability: number;
  recommended_price_range: PriceRange;
  scope_suggestions: ScopeSuggestion[];
  pricing_adjustments: PricingAdjustment[];
  competitive_analysis: string;
  risk_factors: RiskFactor[];
  historical_stats: HistoricalStats;
  token_usage: { input: number; output: number };
  model: string;
}

// ==================== HOOK ====================

export function useBidOptimizer() {
  const [result, setResult] = useState<BidOptimization | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const optimize = useCallback(async (bidId: string) => {
    try {
      setLoading(true);
      setError(null);
      setResult(null);

      const supabase = getSupabase();

      // Get current user + session
      const { data: { session }, error: sessionErr } = await supabase.auth.getSession();
      if (sessionErr || !session) throw new Error('Not authenticated');

      const companyId = session.user.app_metadata?.company_id;
      if (!companyId) throw new Error('No company associated');

      // Call the Edge Function
      const { data, error: fnErr } = await supabase.functions.invoke('ai-bid-optimizer', {
        body: {
          company_id: companyId,
          bid_id: bidId,
        },
      });

      if (fnErr) throw fnErr;

      if (data?.error) {
        throw new Error(data.error);
      }

      setResult(data as BidOptimization);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to optimize bid';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  const reset = useCallback(() => {
    setResult(null);
    setError(null);
    setLoading(false);
  }, []);

  return {
    optimize,
    result,
    loading,
    error,
    reset,
  };
}
