'use client';

// DEPTH30: Recon-to-Estimate Pipeline Hook (Team Portal)
// Read-only access for field technicians to view estimate mappings,
// material recommendations, and cross-trade dependencies.
// Field techs can view generated estimate line items from scan data.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface ReconEstimateMapping {
  id: string;
  trade: string;
  measurementType: string;
  lineDescription: string;
  materialCategory: string | null;
  unitCode: string;
  quantityFormula: string;
  wasteFactorPct: number;
  sortOrder: number;
}

export type RecommendationSeverity = 'info' | 'warning' | 'critical';

export interface ReconMaterialRecommendation {
  id: string;
  trade: string;
  conditionField: string;
  conditionOperator: string;
  conditionValue: string;
  recommendationText: string;
  severity: RecommendationSeverity;
  isCodeRequired: boolean;
}

export interface CrossTradeDependency {
  id: string;
  primaryTrade: string;
  dependentTrade: string;
  dependencyType: 'before' | 'after' | 'concurrent';
  warningText: string;
  severity: string;
}

// ============================================================================
// HELPERS
// ============================================================================

function snakeToCamel(row: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(row)) {
    const camelKey = key.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
    result[camelKey] = value;
  }
  return result;
}

// ============================================================================
// HOOK: useReconEstimatePipeline (read-only for team portal)
// ============================================================================

export function useReconEstimatePipeline(trade?: string) {
  const [mappings, setMappings] = useState<ReconEstimateMapping[]>([]);
  const [recommendations, setRecommendations] = useState<ReconMaterialRecommendation[]>([]);
  const [dependencies, setDependencies] = useState<CrossTradeDependency[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();

      // Load cross-trade dependencies (always)
      const { data: depsData } = await supabase
        .from('cross_trade_dependencies')
        .select('*')
        .order('sort_order');

      setDependencies(
        (depsData ?? []).map((row: Record<string, unknown>) => snakeToCamel(row) as unknown as CrossTradeDependency)
      );

      // Load trade-specific data
      if (trade) {
        const [mappingsResult, recsResult] = await Promise.all([
          supabase
            .from('recon_estimate_mappings')
            .select('*')
            .eq('trade', trade)
            .eq('is_active', true)
            .is('deleted_at', null)
            .order('sort_order'),
          supabase
            .from('recon_material_recommendations')
            .select('*')
            .or(`trade.eq.${trade},trade.eq.general`)
            .eq('is_active', true)
            .is('deleted_at', null)
            .order('sort_order'),
        ]);

        setMappings(
          (mappingsResult.data ?? []).map((row: Record<string, unknown>) => snakeToCamel(row) as unknown as ReconEstimateMapping)
        );
        setRecommendations(
          (recsResult.data ?? []).map((row: Record<string, unknown>) => snakeToCamel(row) as unknown as ReconMaterialRecommendation)
        );
      }
    } catch (e) {
      console.error('Failed to load recon-estimate data:', e);
      setError('Could not load estimate pipeline data.');
    } finally {
      setLoading(false);
    }
  }, [trade]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  return {
    mappings,
    recommendations,
    dependencies,
    loading,
    error,
    reload: loadData,
  };
}
