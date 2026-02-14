'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ────────────────────────────────────────────────────────
// Types
// ────────────────────────────────────────────────────────

export type PredictionType = 'maintenance_due' | 'end_of_life' | 'seasonal_check' | 'filter_replacement' | 'inspection_recommended';
export type OutreachStatus = 'pending' | 'sent' | 'booked' | 'declined' | 'completed';

export interface MaintenancePrediction {
  id: string;
  companyId: string;
  equipmentId: string;
  customerId: string | null;
  predictionType: PredictionType;
  predictedDate: string;
  confidenceScore: number;
  recommendedAction: string;
  estimatedCost: number | null;
  outreachStatus: OutreachStatus;
  resultingJobId: string | null;
  notes: string | null;
  createdAt: string;
  // Joined
  equipmentName: string | null;
  equipmentManufacturer: string | null;
  customerName: string | null;
  customerPhone: string | null;
  // Computed
  daysUntil: number;
  isOverdue: boolean;
}

function mapPrediction(row: Record<string, unknown>): MaintenancePrediction {
  const equipment = row.home_equipment as Record<string, unknown> | null;
  const customer = row.customers as Record<string, unknown> | null;
  const predictedDate = row.predicted_date as string;
  const daysUntil = Math.ceil((new Date(predictedDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24));

  return {
    id: row.id as string,
    companyId: row.company_id as string,
    equipmentId: row.equipment_id as string,
    customerId: row.customer_id as string | null,
    predictionType: row.prediction_type as PredictionType,
    predictedDate,
    confidenceScore: (row.confidence_score as number) ?? 0.5,
    recommendedAction: row.recommended_action as string,
    estimatedCost: row.estimated_cost as number | null,
    outreachStatus: (row.outreach_status as OutreachStatus) || 'pending',
    resultingJobId: row.resulting_job_id as string | null,
    notes: row.notes as string | null,
    createdAt: row.created_at as string,
    equipmentName: equipment?.name as string | null ?? null,
    equipmentManufacturer: equipment?.manufacturer as string | null ?? null,
    customerName: customer?.name as string | null ?? null,
    customerPhone: customer?.phone as string | null ?? null,
    daysUntil,
    isOverdue: daysUntil < 0 && (row.outreach_status as string) !== 'completed',
  };
}

// ────────────────────────────────────────────────────────
// Hook
// ────────────────────────────────────────────────────────

export function useMaintenancePredictions() {
  const [predictions, setPredictions] = useState<MaintenancePrediction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPredictions = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('maintenance_predictions')
        .select('*, home_equipment(name, manufacturer), customers(name, phone)')
        .is('deleted_at', null)
        .order('predicted_date', { ascending: true });

      if (err) throw err;

      setPredictions((data || []).map((r: Record<string, unknown>) => mapPrediction(r)));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load predictions');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPredictions();

    const supabase = getSupabase();
    const channel = supabase
      .channel('maintenance-predictions')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'maintenance_predictions' }, () => fetchPredictions())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchPredictions]);

  // ── Computed ──────────────────────────────────────────
  const stats = useMemo(() => {
    const upcoming = predictions.filter(p => p.daysUntil >= 0 && p.daysUntil <= 30);
    const overdue = predictions.filter(p => p.isOverdue);
    const booked = predictions.filter(p => p.outreachStatus === 'booked');
    const totalEstimatedRevenue = predictions
      .filter(p => p.outreachStatus !== 'declined' && p.outreachStatus !== 'completed')
      .reduce((sum, p) => sum + (p.estimatedCost || 0), 0);
    const byType = predictions.reduce((acc, p) => {
      acc[p.predictionType] = (acc[p.predictionType] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    return {
      total: predictions.length,
      upcoming: upcoming.length,
      overdue: overdue.length,
      booked: booked.length,
      totalEstimatedRevenue,
      byType,
    };
  }, [predictions]);

  const upcomingPredictions = useMemo(() => {
    return predictions.filter(p => p.daysUntil >= -7 && p.outreachStatus !== 'completed')
      .sort((a, b) => a.daysUntil - b.daysUntil);
  }, [predictions]);

  // ── Actions ───────────────────────────────────────────
  const updateOutreachStatus = useCallback(async (predictionId: string, status: OutreachStatus) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('maintenance_predictions')
      .update({ outreach_status: status })
      .eq('id', predictionId);
    if (err) throw new Error(err.message);
    await fetchPredictions();
  }, [fetchPredictions]);

  const linkJobToPrediction = useCallback(async (predictionId: string, jobId: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('maintenance_predictions')
      .update({ resulting_job_id: jobId, outreach_status: 'booked' })
      .eq('id', predictionId);
    if (err) throw new Error(err.message);
    await fetchPredictions();
  }, [fetchPredictions]);

  const triggerEngine = useCallback(async () => {
    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) throw new Error('Not authenticated');

    const response = await fetch(
      `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/predictive-maintenance-engine`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${session.access_token}`,
          'Content-Type': 'application/json',
        },
      }
    );
    const result = await response.json();
    if (!result.ok) throw new Error(result.error || 'Engine failed');
    await fetchPredictions();
    return result;
  }, [fetchPredictions]);

  return {
    predictions,
    upcomingPredictions,
    loading,
    error,
    stats,
    updateOutreachStatus,
    linkJobToPrediction,
    triggerEngine,
    refresh: fetchPredictions,
  };
}
