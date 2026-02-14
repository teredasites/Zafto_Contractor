'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// ────────────────────────────────────────────────────────
// Types — read-only client view of maintenance predictions
// ────────────────────────────────────────────────────────

export interface MaintenancePrediction {
  id: string;
  predictionType: string;
  predictedDate: string;
  recommendedAction: string;
  estimatedCost: number | null;
  confidenceScore: number;
  outreachStatus: string;
  equipmentName: string | null;
  equipmentManufacturer: string | null;
  daysUntil: number;
}

function mapPrediction(row: Record<string, unknown>): MaintenancePrediction {
  const equipment = row.home_equipment as Record<string, unknown> | null;
  const predictedDate = row.predicted_date as string;
  const daysUntil = Math.ceil((new Date(predictedDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24));

  return {
    id: row.id as string,
    predictionType: row.prediction_type as string,
    predictedDate,
    recommendedAction: row.recommended_action as string,
    estimatedCost: row.estimated_cost as number | null,
    confidenceScore: (row.confidence_score as number) ?? 0.5,
    outreachStatus: (row.outreach_status as string) || 'pending',
    equipmentName: equipment?.name as string | null ?? null,
    equipmentManufacturer: equipment?.manufacturer as string | null ?? null,
    daysUntil,
  };
}

export function useMaintenancePredictions() {
  const { profile } = useAuth();
  const [predictions, setPredictions] = useState<MaintenancePrediction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const customerId = profile?.customerId;

  const fetchPredictions = useCallback(async () => {
    if (!customerId) return;
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('maintenance_predictions')
        .select('*, home_equipment(name, manufacturer)')
        .eq('customer_id', customerId)
        .is('deleted_at', null)
        .neq('outreach_status', 'completed')
        .order('predicted_date', { ascending: true });

      if (err) throw err;
      setPredictions((data || []).map((r: Record<string, unknown>) => mapPrediction(r)));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load predictions');
    } finally {
      setLoading(false);
    }
  }, [customerId]);

  useEffect(() => {
    fetchPredictions();
  }, [fetchPredictions]);

  return { predictions, loading, error, refresh: fetchPredictions };
}
