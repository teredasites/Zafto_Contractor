'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ────────────────────────────────────────────────────────
// Types
// ────────────────────────────────────────────────────────

export type PeriodType = 'weekly' | 'biweekly' | 'semimonthly' | 'monthly';
export type PeriodStatus = 'draft' | 'processing' | 'approved' | 'paid' | 'voided';
export type PaymentMethod = 'direct_deposit' | 'check' | 'cash';

export interface PayPeriod {
  id: string;
  companyId: string;
  periodType: PeriodType;
  startDate: string;
  endDate: string;
  payDate: string;
  status: PeriodStatus;
  approvedByUserId: string | null;
  approvedAt: string | null;
  totalGross: number;
  totalNet: number;
  totalTaxes: number;
  totalDeductions: number;
  employeeCount: number;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface PayStub {
  id: string;
  companyId: string;
  payPeriodId: string;
  userId: string;
  hoursRegular: number;
  hoursOvertime: number;
  hoursPto: number;
  hoursHoliday: number;
  rateRegular: number;
  rateOvertime: number;
  grossPay: number;
  federalTax: number;
  stateTax: number;
  localTax: number;
  socialSecurity: number;
  medicare: number;
  healthInsurance: number;
  dentalInsurance: number;
  visionInsurance: number;
  retirement401k: number;
  otherDeductions: number;
  totalDeductions: number;
  netPay: number;
  ytdGross: number;
  ytdFederalTax: number;
  ytdStateTax: number;
  ytdSocialSecurity: number;
  ytdMedicare: number;
  ytdNet: number;
  paymentMethod: PaymentMethod;
  checkNumber: string | null;
  gustoPayrollId: string | null;
  notes: string | null;
  createdAt: string;
}

export interface PayrollTaxConfig {
  id: string;
  companyId: string;
  taxYear: number;
  state: string;
  futaRate: number;
  sutaRate: number;
  sutaWageBase: number;
  workersCompRate: number;
  workersCompClassCode: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// ────────────────────────────────────────────────────────
// Mappers (snake_case DB → camelCase TS)
// ────────────────────────────────────────────────────────

function mapPayPeriod(row: Record<string, unknown>): PayPeriod {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    periodType: (row.period_type as PeriodType) || 'biweekly',
    startDate: (row.start_date as string) || '',
    endDate: (row.end_date as string) || '',
    payDate: (row.pay_date as string) || '',
    status: (row.status as PeriodStatus) || 'draft',
    approvedByUserId: (row.approved_by_user_id as string) || null,
    approvedAt: (row.approved_at as string) || null,
    totalGross: Number(row.total_gross || 0),
    totalNet: Number(row.total_net || 0),
    totalTaxes: Number(row.total_taxes || 0),
    totalDeductions: Number(row.total_deductions || 0),
    employeeCount: Number(row.employee_count || 0),
    notes: (row.notes as string) || null,
    createdAt: (row.created_at as string) || '',
    updatedAt: (row.updated_at as string) || '',
  };
}

function mapPayStub(row: Record<string, unknown>): PayStub {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    payPeriodId: (row.pay_period_id as string) || '',
    userId: (row.user_id as string) || '',
    hoursRegular: Number(row.hours_regular || 0),
    hoursOvertime: Number(row.hours_overtime || 0),
    hoursPto: Number(row.hours_pto || 0),
    hoursHoliday: Number(row.hours_holiday || 0),
    rateRegular: Number(row.rate_regular || 0),
    rateOvertime: Number(row.rate_overtime || 0),
    grossPay: Number(row.gross_pay || 0),
    federalTax: Number(row.federal_tax || 0),
    stateTax: Number(row.state_tax || 0),
    localTax: Number(row.local_tax || 0),
    socialSecurity: Number(row.social_security || 0),
    medicare: Number(row.medicare || 0),
    healthInsurance: Number(row.health_insurance || 0),
    dentalInsurance: Number(row.dental_insurance || 0),
    visionInsurance: Number(row.vision_insurance || 0),
    retirement401k: Number(row.retirement_401k || 0),
    otherDeductions: Number(row.other_deductions || 0),
    totalDeductions: Number(row.total_deductions || 0),
    netPay: Number(row.net_pay || 0),
    ytdGross: Number(row.ytd_gross || 0),
    ytdFederalTax: Number(row.ytd_federal_tax || 0),
    ytdStateTax: Number(row.ytd_state_tax || 0),
    ytdSocialSecurity: Number(row.ytd_social_security || 0),
    ytdMedicare: Number(row.ytd_medicare || 0),
    ytdNet: Number(row.ytd_net || 0),
    paymentMethod: (row.payment_method as PaymentMethod) || 'direct_deposit',
    checkNumber: (row.check_number as string) || null,
    gustoPayrollId: (row.gusto_payroll_id as string) || null,
    notes: (row.notes as string) || null,
    createdAt: (row.created_at as string) || '',
  };
}

// ────────────────────────────────────────────────────────
// Hook
// ────────────────────────────────────────────────────────

export function usePayroll() {
  const [payPeriods, setPayPeriods] = useState<PayPeriod[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('pay_periods')
        .select('*')
        .order('pay_date', { ascending: false });

      if (err) throw err;
      setPayPeriods((data || []).map(mapPayPeriod));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load payroll data';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();

    const supabase = getSupabase();
    const channel = supabase
      .channel('pay-periods-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'pay_periods' }, () => {
        fetchData();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchData]);

  // ── Fetch stubs for a specific period ──

  const getStubsForPeriod = useCallback(async (periodId: string): Promise<PayStub[]> => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('pay_stubs')
      .select('*')
      .eq('pay_period_id', periodId)
      .order('created_at', { ascending: true });

    if (err) throw err;
    return (data || []).map(mapPayStub);
  }, []);

  // ── Mutations ──

  const createPayPeriod = async (data: Partial<PayPeriod>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('pay_periods')
      .insert({
        company_id: companyId,
        period_type: data.periodType || 'biweekly',
        start_date: data.startDate,
        end_date: data.endDate,
        pay_date: data.payDate,
        status: 'draft',
        total_gross: 0,
        total_net: 0,
        total_taxes: 0,
        total_deductions: 0,
        employee_count: 0,
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updatePayPeriodStatus = async (id: string, status: PeriodStatus) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = { status };

    if (status === 'approved') {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        updateData.approved_by_user_id = user.id;
        updateData.approved_at = new Date().toISOString();
      }
    }

    const { error: err } = await supabase.from('pay_periods').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const createPayStub = async (data: Partial<PayStub>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const grossPay = data.grossPay || 0;
    const totalDeductions = data.totalDeductions || 0;

    const { data: result, error: err } = await supabase
      .from('pay_stubs')
      .insert({
        company_id: companyId,
        pay_period_id: data.payPeriodId,
        user_id: data.userId,
        hours_regular: data.hoursRegular || 0,
        hours_overtime: data.hoursOvertime || 0,
        hours_pto: data.hoursPto || 0,
        hours_holiday: data.hoursHoliday || 0,
        rate_regular: data.rateRegular || 0,
        rate_overtime: data.rateOvertime || 0,
        gross_pay: grossPay,
        federal_tax: data.federalTax || 0,
        state_tax: data.stateTax || 0,
        local_tax: data.localTax || 0,
        social_security: data.socialSecurity || 0,
        medicare: data.medicare || 0,
        health_insurance: data.healthInsurance || 0,
        dental_insurance: data.dentalInsurance || 0,
        vision_insurance: data.visionInsurance || 0,
        retirement_401k: data.retirement401k || 0,
        other_deductions: data.otherDeductions || 0,
        total_deductions: totalDeductions,
        net_pay: data.netPay || (grossPay - totalDeductions),
        ytd_gross: data.ytdGross || 0,
        ytd_federal_tax: data.ytdFederalTax || 0,
        ytd_state_tax: data.ytdStateTax || 0,
        ytd_social_security: data.ytdSocialSecurity || 0,
        ytd_medicare: data.ytdMedicare || 0,
        ytd_net: data.ytdNet || 0,
        payment_method: data.paymentMethod || 'direct_deposit',
        check_number: data.checkNumber || null,
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  // ── Computed values ──

  const currentPeriod = useMemo(
    () => payPeriods.find((p) => p.status !== 'paid' && p.status !== 'voided') || null,
    [payPeriods]
  );

  const totalPayroll = useMemo(
    () => currentPeriod?.totalGross || 0,
    [currentPeriod]
  );

  const pendingApproval = useMemo(
    () => payPeriods.filter((p) => p.status === 'draft' || p.status === 'processing').length,
    [payPeriods]
  );

  return {
    payPeriods,
    loading,
    error,
    getStubsForPeriod,
    createPayPeriod,
    updatePayPeriodStatus,
    createPayStub,
    currentPeriod,
    totalPayroll,
    pendingApproval,
    refetch: fetchData,
  };
}
