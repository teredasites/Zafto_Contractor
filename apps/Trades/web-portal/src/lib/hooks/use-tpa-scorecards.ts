'use client';

import { useState, useEffect, useCallback } from 'react';
import { createClient } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type ScorecardSource = 'manual' | 'imported' | 'calculated';

export interface TpaScorecardData {
  id: string;
  companyId: string;
  tpaProgramId: string;
  periodStart: string;
  periodEnd: string;
  // Score categories (0-100)
  responseTimeScore: number | null;
  cycleTimeScore: number | null;
  customerSatisfactionScore: number | null;
  documentationScore: number | null;
  estimateAccuracyScore: number | null;
  supplementRateScore: number | null;
  slaComplianceScore: number | null;
  overallScore: number | null;
  // Volume
  totalAssignments: number;
  assignmentsCompleted: number;
  slaViolations: number;
  averageCycleDays: number | null;
  // Context
  notes: string | null;
  source: ScorecardSource;
  createdAt: string;
  updatedAt: string;
}

export interface CreateScorecardInput {
  tpaProgramId: string;
  periodStart: string;
  periodEnd: string;
  responseTimeScore?: number;
  cycleTimeScore?: number;
  customerSatisfactionScore?: number;
  documentationScore?: number;
  estimateAccuracyScore?: number;
  supplementRateScore?: number;
  slaComplianceScore?: number;
  overallScore?: number;
  totalAssignments?: number;
  assignmentsCompleted?: number;
  slaViolations?: number;
  averageCycleDays?: number;
  notes?: string;
  source?: ScorecardSource;
}

// ============================================================================
// MAPPER
// ============================================================================

function mapScorecard(row: Record<string, unknown>): TpaScorecardData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    tpaProgramId: row.tpa_program_id as string,
    periodStart: row.period_start as string,
    periodEnd: row.period_end as string,
    responseTimeScore: row.response_time_score != null ? Number(row.response_time_score) : null,
    cycleTimeScore: row.cycle_time_score != null ? Number(row.cycle_time_score) : null,
    customerSatisfactionScore: row.customer_satisfaction_score != null ? Number(row.customer_satisfaction_score) : null,
    documentationScore: row.documentation_score != null ? Number(row.documentation_score) : null,
    estimateAccuracyScore: row.estimate_accuracy_score != null ? Number(row.estimate_accuracy_score) : null,
    supplementRateScore: row.supplement_rate_score != null ? Number(row.supplement_rate_score) : null,
    slaComplianceScore: row.sla_compliance_score != null ? Number(row.sla_compliance_score) : null,
    overallScore: row.overall_score != null ? Number(row.overall_score) : null,
    totalAssignments: Number(row.total_assignments) || 0,
    assignmentsCompleted: Number(row.assignments_completed) || 0,
    slaViolations: Number(row.sla_violations) || 0,
    averageCycleDays: row.average_cycle_days != null ? Number(row.average_cycle_days) : null,
    notes: row.notes as string | null,
    source: (row.source as ScorecardSource) || 'manual',
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

// ============================================================================
// HOOK: useTpaScorecards
// ============================================================================

export function useTpaScorecards(programId?: string) {
  const [scorecards, setScorecards] = useState<TpaScorecardData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchScorecards = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = createClient();
      let query = supabase
        .from('tpa_scorecards')
        .select('*')
        .is('deleted_at', null)
        .order('period_start', { ascending: false });

      if (programId) {
        query = query.eq('tpa_program_id', programId);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setScorecards((data || []).map(mapScorecard));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load scorecards');
    } finally {
      setLoading(false);
    }
  }, [programId]);

  useEffect(() => {
    fetchScorecards();
  }, [fetchScorecards]);

  // Create scorecard
  const createScorecard = useCallback(async (input: CreateScorecardInput) => {
    try {
      const supabase = createClient();

      // Calculate overall if not provided
      const scores = [
        input.responseTimeScore,
        input.cycleTimeScore,
        input.customerSatisfactionScore,
        input.documentationScore,
        input.estimateAccuracyScore,
        input.supplementRateScore,
        input.slaComplianceScore,
      ].filter((s): s is number => s != null);

      const overall = input.overallScore ?? (scores.length > 0
        ? Math.round((scores.reduce((a, b) => a + b, 0) / scores.length) * 100) / 100
        : null);

      const { error: err } = await supabase.from('tpa_scorecards').insert({
        tpa_program_id: input.tpaProgramId,
        period_start: input.periodStart,
        period_end: input.periodEnd,
        response_time_score: input.responseTimeScore ?? null,
        cycle_time_score: input.cycleTimeScore ?? null,
        customer_satisfaction_score: input.customerSatisfactionScore ?? null,
        documentation_score: input.documentationScore ?? null,
        estimate_accuracy_score: input.estimateAccuracyScore ?? null,
        supplement_rate_score: input.supplementRateScore ?? null,
        sla_compliance_score: input.slaComplianceScore ?? null,
        overall_score: overall,
        total_assignments: input.totalAssignments ?? 0,
        assignments_completed: input.assignmentsCompleted ?? 0,
        sla_violations: input.slaViolations ?? 0,
        average_cycle_days: input.averageCycleDays ?? null,
        notes: input.notes ?? null,
        source: input.source ?? 'manual',
      });

      if (err) throw err;
      await fetchScorecards();
      return true;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to create scorecard');
      return false;
    }
  }, [fetchScorecards]);

  // Update scorecard
  const updateScorecard = useCallback(async (id: string, input: Partial<CreateScorecardInput>) => {
    try {
      const supabase = createClient();
      const updateData: Record<string, unknown> = {};
      if (input.responseTimeScore !== undefined) updateData.response_time_score = input.responseTimeScore;
      if (input.cycleTimeScore !== undefined) updateData.cycle_time_score = input.cycleTimeScore;
      if (input.customerSatisfactionScore !== undefined) updateData.customer_satisfaction_score = input.customerSatisfactionScore;
      if (input.documentationScore !== undefined) updateData.documentation_score = input.documentationScore;
      if (input.estimateAccuracyScore !== undefined) updateData.estimate_accuracy_score = input.estimateAccuracyScore;
      if (input.supplementRateScore !== undefined) updateData.supplement_rate_score = input.supplementRateScore;
      if (input.slaComplianceScore !== undefined) updateData.sla_compliance_score = input.slaComplianceScore;
      if (input.overallScore !== undefined) updateData.overall_score = input.overallScore;
      if (input.totalAssignments !== undefined) updateData.total_assignments = input.totalAssignments;
      if (input.assignmentsCompleted !== undefined) updateData.assignments_completed = input.assignmentsCompleted;
      if (input.slaViolations !== undefined) updateData.sla_violations = input.slaViolations;
      if (input.averageCycleDays !== undefined) updateData.average_cycle_days = input.averageCycleDays;
      if (input.notes !== undefined) updateData.notes = input.notes;

      // Recalculate overall if individual scores changed
      if (Object.keys(updateData).some((k) => k.endsWith('_score') && k !== 'overall_score') && input.overallScore === undefined) {
        // Fetch current to merge
        const { data: current } = await supabase.from('tpa_scorecards').select('*').eq('id', id).single();
        if (current) {
          const merged = { ...current, ...updateData };
          const scores = [
            merged.response_time_score, merged.cycle_time_score,
            merged.customer_satisfaction_score, merged.documentation_score,
            merged.estimate_accuracy_score, merged.supplement_rate_score,
            merged.sla_compliance_score,
          ].filter((s): s is number => s != null);
          if (scores.length > 0) {
            updateData.overall_score = Math.round((scores.reduce((a, b) => a + b, 0) / scores.length) * 100) / 100;
          }
        }
      }

      const { error: err } = await supabase
        .from('tpa_scorecards')
        .update(updateData)
        .eq('id', id);

      if (err) throw err;
      await fetchScorecards();
      return true;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to update scorecard');
      return false;
    }
  }, [fetchScorecards]);

  // Delete scorecard
  const deleteScorecard = useCallback(async (id: string) => {
    try {
      const supabase = createClient();
      const { error: err } = await supabase
        .from('tpa_scorecards')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);

      if (err) throw err;
      await fetchScorecards();
      return true;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to delete scorecard');
      return false;
    }
  }, [fetchScorecards]);

  // Trend data grouped by program
  const trendByProgram = scorecards.reduce<Record<string, TpaScorecardData[]>>((acc, sc) => {
    if (!acc[sc.tpaProgramId]) acc[sc.tpaProgramId] = [];
    acc[sc.tpaProgramId].push(sc);
    return acc;
  }, {});

  return {
    scorecards,
    loading,
    error,
    refetch: fetchScorecards,
    createScorecard,
    updateScorecard,
    deleteScorecard,
    trendByProgram,
  };
}

// ============================================================================
// CONSTANTS
// ============================================================================

export const SCORE_CATEGORIES = [
  { key: 'responseTimeScore', label: 'Response Time', dbKey: 'response_time_score' },
  { key: 'cycleTimeScore', label: 'Cycle Time', dbKey: 'cycle_time_score' },
  { key: 'customerSatisfactionScore', label: 'Customer Satisfaction', dbKey: 'customer_satisfaction_score' },
  { key: 'documentationScore', label: 'Documentation', dbKey: 'documentation_score' },
  { key: 'estimateAccuracyScore', label: 'Estimate Accuracy', dbKey: 'estimate_accuracy_score' },
  { key: 'supplementRateScore', label: 'Supplement Rate', dbKey: 'supplement_rate_score' },
  { key: 'slaComplianceScore', label: 'SLA Compliance', dbKey: 'sla_compliance_score' },
] as const;
