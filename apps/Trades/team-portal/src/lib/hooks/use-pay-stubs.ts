'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface PayStubDeductions {
  federalTax: number;
  stateTax: number;
  socialSecurity: number;
  medicare: number;
  healthInsurance: number;
  dentalInsurance: number;
  visionInsurance: number;
  retirement401k: number;
  otherDeductions: number;
}

export interface PayStubData {
  id: string;
  userId: string;
  companyId: string;
  payPeriodStart: string;
  payPeriodEnd: string;
  payDate: string;
  grossPay: number;
  netPay: number;
  totalDeductions: number;
  deductions: PayStubDeductions;
  regularHours: number;
  overtimeHours: number;
  regularRate: number;
  overtimeRate: number;
  bonuses: number;
  reimbursements: number;
  documentUrl: string | null;
  status: 'draft' | 'processed' | 'paid';
  createdAt: string;
}

// ============================================================================
// MAPPER
// ============================================================================

function mapPayStub(row: Record<string, unknown>): PayStubData {
  const deductionsData = (row.deductions as Record<string, unknown>) || {};
  const deductions: PayStubDeductions = {
    federalTax: Number(deductionsData.federal_tax || 0),
    stateTax: Number(deductionsData.state_tax || 0),
    socialSecurity: Number(deductionsData.social_security || 0),
    medicare: Number(deductionsData.medicare || 0),
    healthInsurance: Number(deductionsData.health_insurance || 0),
    dentalInsurance: Number(deductionsData.dental_insurance || 0),
    visionInsurance: Number(deductionsData.vision_insurance || 0),
    retirement401k: Number(deductionsData.retirement_401k || 0),
    otherDeductions: Number(deductionsData.other_deductions || 0),
  };

  return {
    id: row.id as string,
    userId: row.user_id as string,
    companyId: row.company_id as string,
    payPeriodStart: (row.pay_period_start as string) || '',
    payPeriodEnd: (row.pay_period_end as string) || '',
    payDate: (row.pay_date as string) || '',
    grossPay: Number(row.gross_pay || 0),
    netPay: Number(row.net_pay || 0),
    totalDeductions: Number(row.total_deductions || 0),
    deductions,
    regularHours: Number(row.regular_hours || 0),
    overtimeHours: Number(row.overtime_hours || 0),
    regularRate: Number(row.regular_rate || 0),
    overtimeRate: Number(row.overtime_rate || 0),
    bonuses: Number(row.bonuses || 0),
    reimbursements: Number(row.reimbursements || 0),
    documentUrl: (row.document_url as string) || null,
    status: (row.status as PayStubData['status']) || 'processed',
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

// ============================================================================
// HOOK: usePayStubs (team portal — scoped to current user)
// ============================================================================

export function usePayStubs() {
  const [payStubs, setPayStubs] = useState<PayStubData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPayStubs = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const { data, error: err } = await supabase
        .from('pay_stubs')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setPayStubs((data || []).map((row: Record<string, unknown>) => mapPayStub(row)));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load pay stubs';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPayStubs();

    const supabase = getSupabase();
    const channel = supabase
      .channel('team-pay-stubs')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'pay_stubs' }, () => fetchPayStubs())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchPayStubs]);

  // YTD totals
  const ytdTotals = useMemo(() => {
    const currentYear = new Date().getFullYear();
    const thisYearStubs = payStubs.filter(s => {
      const payDate = new Date(s.payDate);
      return payDate.getFullYear() === currentYear;
    });

    return {
      grossPay: thisYearStubs.reduce((sum, s) => sum + s.grossPay, 0),
      netPay: thisYearStubs.reduce((sum, s) => sum + s.netPay, 0),
      totalDeductions: thisYearStubs.reduce((sum, s) => sum + s.totalDeductions, 0),
      federalTax: thisYearStubs.reduce((sum, s) => sum + s.deductions.federalTax, 0),
      stateTax: thisYearStubs.reduce((sum, s) => sum + s.deductions.stateTax, 0),
      socialSecurity: thisYearStubs.reduce((sum, s) => sum + s.deductions.socialSecurity, 0),
      medicare: thisYearStubs.reduce((sum, s) => sum + s.deductions.medicare, 0),
      healthInsurance: thisYearStubs.reduce((sum, s) => sum + s.deductions.healthInsurance, 0),
      retirement401k: thisYearStubs.reduce((sum, s) => sum + s.deductions.retirement401k, 0),
      totalHours: thisYearStubs.reduce((sum, s) => sum + s.regularHours + s.overtimeHours, 0),
      stubCount: thisYearStubs.length,
    };
  }, [payStubs]);

  return { payStubs, ytdTotals, loading, error, refetch: fetchPayStubs };
}
