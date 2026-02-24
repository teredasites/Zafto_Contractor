'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface TpaFinancialData {
  id: string;
  companyId: string;
  tpaProgramId: string;
  periodMonth: number;
  periodYear: number;
  // Assignment counts
  assignmentsReceived: number;
  assignmentsCompleted: number;
  assignmentsDeclined: number;
  assignmentsInProgress: number;
  // Revenue
  grossRevenue: number;
  supplementRevenue: number;
  totalRevenue: number;
  // Costs
  laborCost: number;
  materialCost: number;
  equipmentCost: number;
  subcontractorCost: number;
  referralFeesPaid: number;
  totalCost: number;
  // Margins
  grossMargin: number;
  grossMarginPercent: number;
  netMargin: number;
  netMarginPercent: number;
  // AR aging
  arCurrent: number;
  ar30Day: number;
  ar60Day: number;
  ar90Plus: number;
  avgPaymentDays: number;
  // Supplement performance
  supplementsSubmitted: number;
  supplementsApproved: number;
  supplementsDenied: number;
  supplementApprovalRate: number;
  avgSupplementAmount: number;
  // Scoring
  avgScorecardRating: number | null;
  slaViolationsCount: number;
  avgCycleTimeDays: number;
  // Metadata
  calculatedAt: string;
  createdAt: string;
  updatedAt: string;
}

export interface ProgramFinancialSummary {
  programId: string;
  programName: string;
  programType: string;
  totalRevenue: number;
  totalCost: number;
  grossMarginPercent: number;
  assignmentsReceived: number;
  assignmentsCompleted: number;
  referralFeesPaid: number;
  avgScorecardRating: number | null;
  slaViolationsCount: number;
  supplementApprovalRate: number;
  arTotal: number;
}

export interface FinancialOverview {
  totalRevenue: number;
  totalCost: number;
  totalGrossMargin: number;
  avgGrossMarginPercent: number;
  totalAssignmentsReceived: number;
  totalAssignmentsCompleted: number;
  totalReferralFees: number;
  totalArOutstanding: number;
  totalSlaViolations: number;
  avgSupplementApprovalRate: number;
  programSummaries: ProgramFinancialSummary[];
}

// ============================================================================
// MAPPER
// ============================================================================

function mapFinancial(row: Record<string, unknown>): TpaFinancialData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    tpaProgramId: row.tpa_program_id as string,
    periodMonth: row.period_month as number,
    periodYear: row.period_year as number,
    assignmentsReceived: Number(row.assignments_received) || 0,
    assignmentsCompleted: Number(row.assignments_completed) || 0,
    assignmentsDeclined: Number(row.assignments_declined) || 0,
    assignmentsInProgress: Number(row.assignments_in_progress) || 0,
    grossRevenue: Number(row.gross_revenue) || 0,
    supplementRevenue: Number(row.supplement_revenue) || 0,
    totalRevenue: Number(row.total_revenue) || 0,
    laborCost: Number(row.labor_cost) || 0,
    materialCost: Number(row.material_cost) || 0,
    equipmentCost: Number(row.equipment_cost) || 0,
    subcontractorCost: Number(row.subcontractor_cost) || 0,
    referralFeesPaid: Number(row.referral_fees_paid) || 0,
    totalCost: Number(row.total_cost) || 0,
    grossMargin: Number(row.gross_margin) || 0,
    grossMarginPercent: Number(row.gross_margin_percent) || 0,
    netMargin: Number(row.net_margin) || 0,
    netMarginPercent: Number(row.net_margin_percent) || 0,
    arCurrent: Number(row.ar_current) || 0,
    ar30Day: Number(row.ar_30_day) || 0,
    ar60Day: Number(row.ar_60_day) || 0,
    ar90Plus: Number(row.ar_90_plus) || 0,
    avgPaymentDays: Number(row.avg_payment_days) || 0,
    supplementsSubmitted: Number(row.supplements_submitted) || 0,
    supplementsApproved: Number(row.supplements_approved) || 0,
    supplementsDenied: Number(row.supplements_denied) || 0,
    supplementApprovalRate: Number(row.supplement_approval_rate) || 0,
    avgSupplementAmount: Number(row.avg_supplement_amount) || 0,
    avgScorecardRating: row.avg_scorecard_rating != null ? Number(row.avg_scorecard_rating) : null,
    slaViolationsCount: Number(row.sla_violations_count) || 0,
    avgCycleTimeDays: Number(row.avg_cycle_time_days) || 0,
    calculatedAt: row.calculated_at as string,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

// ============================================================================
// HOOK: useTpaFinancials
// ============================================================================

export function useTpaFinancials(periodMonth?: number, periodYear?: number) {
  const [financials, setFinancials] = useState<TpaFinancialData[]>([]);
  const [programs, setPrograms] = useState<Record<string, { name: string; tpaType: string }>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const now = new Date();
  const month = periodMonth ?? now.getMonth() + 1;
  const year = periodYear ?? now.getFullYear();

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();

      // Fetch programs for name mapping
      const { data: programRows, error: pErr } = await supabase
        .from('tpa_programs')
        .select('id, name, tpa_type')
        .is('deleted_at', null);

      if (pErr) throw pErr;

      const programMap: Record<string, { name: string; tpaType: string }> = {};
      for (const p of programRows || []) {
        programMap[p.id] = { name: p.name, tpaType: p.tpa_type };
      }
      setPrograms(programMap);

      // Fetch financials for the period
      const { data: rows, error: fErr } = await supabase
        .from('tpa_program_financials')
        .select('*')
        .eq('period_month', month)
        .eq('period_year', year)
        .order('total_revenue', { ascending: false });

      if (fErr) throw fErr;
      setFinancials((rows || []).map(mapFinancial));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load financial data');
    } finally {
      setLoading(false);
    }
  }, [month, year]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Computed overview
  const overview = useMemo((): FinancialOverview => {
    const summaries: ProgramFinancialSummary[] = financials.map((f) => ({
      programId: f.tpaProgramId,
      programName: programs[f.tpaProgramId]?.name ?? 'Unknown',
      programType: programs[f.tpaProgramId]?.tpaType ?? 'unknown',
      totalRevenue: f.totalRevenue,
      totalCost: f.totalCost,
      grossMarginPercent: f.grossMarginPercent,
      assignmentsReceived: f.assignmentsReceived,
      assignmentsCompleted: f.assignmentsCompleted,
      referralFeesPaid: f.referralFeesPaid,
      avgScorecardRating: f.avgScorecardRating,
      slaViolationsCount: f.slaViolationsCount,
      supplementApprovalRate: f.supplementApprovalRate,
      arTotal: f.arCurrent + f.ar30Day + f.ar60Day + f.ar90Plus,
    }));

    const totalRevenue = financials.reduce((s, f) => s + f.totalRevenue, 0);
    const totalCost = financials.reduce((s, f) => s + f.totalCost, 0);
    const totalGrossMargin = totalRevenue - totalCost;
    const avgGrossMarginPercent = totalRevenue > 0 ? (totalGrossMargin / totalRevenue) * 100 : 0;

    return {
      totalRevenue,
      totalCost,
      totalGrossMargin,
      avgGrossMarginPercent: Math.round(avgGrossMarginPercent * 100) / 100,
      totalAssignmentsReceived: financials.reduce((s, f) => s + f.assignmentsReceived, 0),
      totalAssignmentsCompleted: financials.reduce((s, f) => s + f.assignmentsCompleted, 0),
      totalReferralFees: financials.reduce((s, f) => s + f.referralFeesPaid, 0),
      totalArOutstanding: summaries.reduce((s, p) => s + p.arTotal, 0),
      totalSlaViolations: financials.reduce((s, f) => s + f.slaViolationsCount, 0),
      avgSupplementApprovalRate:
        financials.length > 0
          ? Math.round(financials.reduce((s, f) => s + f.supplementApprovalRate, 0) / financials.length)
          : 0,
      programSummaries: summaries,
    };
  }, [financials, programs]);

  // Trigger recalculation via Edge Function
  const recalculate = useCallback(
    async (tpaProgramId?: string) => {
      try {
        const supabase = getSupabase();
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) throw new Error('Not authenticated');

        const res = await fetch(
          `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/tpa-financial-rollup`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${session.access_token}`,
            },
            body: JSON.stringify({ month, year, tpa_program_id: tpaProgramId }),
          }
        );

        if (!res.ok) {
          const body = await res.json().catch(() => ({}));
          throw new Error(body.error || 'Recalculation failed');
        }

        await fetchData();
        return true;
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Recalculation failed');
        return false;
      }
    },
    [month, year, fetchData]
  );

  return {
    financials,
    programs,
    overview,
    loading,
    error,
    refetch: fetchData,
    recalculate,
  };
}

// ============================================================================
// HELPER: Format currency
// ============================================================================

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

export function formatPercent(value: number): string {
  return `${Math.round(value * 100) / 100}%`;
}
