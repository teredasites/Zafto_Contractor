'use client';

// Customer Financing hook — CRUD for financing applications & providers
// Real-time subscriptions, status pipeline, provider management.

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──

export type ApplicationStatus = 'offered' | 'applied' | 'approved' | 'denied' | 'funded' | 'expired' | 'cancelled';

export interface FinancingApplication {
  id: string;
  companyId: string;
  customerId: string | null;
  jobId: string | null;
  providerId: string | null;
  customerName: string;
  jobName: string | null;
  amount: number;
  monthlyPayment: number | null;
  termMonths: number | null;
  interestRate: number | null;
  providerName: string | null;
  status: ApplicationStatus;
  externalApplicationId: string | null;
  fundedAt: string | null;
  dateApplied: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface FinancingProvider {
  id: string;
  companyId: string;
  providerName: string;
  providerSlug: string;
  connected: boolean;
  apiKeyConfigured: boolean;
  merchantFeePct: number;
  minAmount: number;
  maxAmount: number;
  availableTerms: number[];
  settings: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export interface FinancingSummary {
  totalApplications: number;
  totalFunded: number;
  totalFundedAmount: number;
  activeApplications: number;
  avgFinancedAmount: number;
}

// ── Mappers ──

function mapApplication(row: Record<string, unknown>): FinancingApplication {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    customerId: row.customer_id as string | null,
    jobId: row.job_id as string | null,
    providerId: row.provider_id as string | null,
    customerName: row.customer_name as string,
    jobName: row.job_name as string | null,
    amount: Number(row.amount) || 0,
    monthlyPayment: row.monthly_payment ? Number(row.monthly_payment) : null,
    termMonths: row.term_months as number | null,
    interestRate: row.interest_rate ? Number(row.interest_rate) : null,
    providerName: row.provider_name as string | null,
    status: row.status as ApplicationStatus,
    externalApplicationId: row.external_application_id as string | null,
    fundedAt: row.funded_at as string | null,
    dateApplied: row.date_applied as string | null,
    notes: row.notes as string | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapProvider(row: Record<string, unknown>): FinancingProvider {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    providerName: row.provider_name as string,
    providerSlug: row.provider_slug as string,
    connected: Boolean(row.connected),
    apiKeyConfigured: Boolean(row.api_key_configured),
    merchantFeePct: Number(row.merchant_fee_pct) || 0,
    minAmount: Number(row.min_amount) || 500,
    maxAmount: Number(row.max_amount) || 100000,
    availableTerms: (row.available_terms as number[]) || [12, 24, 36, 48, 60],
    settings: (row.settings as Record<string, unknown>) || {},
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

// ── Main Hook ──

export function useFinancing() {
  const supabase = getSupabase();
  const [applications, setApplications] = useState<FinancingApplication[]>([]);
  const [providers, setProviders] = useState<FinancingProvider[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAll = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const [appsRes, provsRes] = await Promise.all([
        supabase
          .from('financing_applications')
          .select('*')
          .is('deleted_at', null)
          .order('created_at', { ascending: false }),
        supabase
          .from('financing_providers')
          .select('*')
          .is('deleted_at', null)
          .order('provider_name'),
      ]);

      if (appsRes.error) throw appsRes.error;
      if (provsRes.error) throw provsRes.error;

      setApplications((appsRes.data || []).map((r: Record<string, unknown>) => mapApplication(r)));
      setProviders((provsRes.data || []).map((r: Record<string, unknown>) => mapProvider(r)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load financing data');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  // Real-time subscriptions
  useEffect(() => {
    const channel = supabase
      .channel('financing-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'financing_applications' }, () => fetchAll())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'financing_providers' }, () => fetchAll())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchAll]);

  // ── Summary ──
  const summary = useMemo<FinancingSummary>(() => {
    const funded = applications.filter(a => a.status === 'funded');
    const active = applications.filter(a => a.status === 'applied' || a.status === 'approved');
    const totalFundedAmount = funded.reduce((s, a) => s + a.amount, 0);
    return {
      totalApplications: applications.length,
      totalFunded: funded.length,
      totalFundedAmount,
      activeApplications: active.length,
      avgFinancedAmount: applications.length > 0
        ? applications.reduce((s, a) => s + a.amount, 0) / applications.length
        : 0,
    };
  }, [applications]);

  // ── Mutations ──

  const createApplication = useCallback(async (input: {
    customerId?: string;
    jobId?: string;
    customerName: string;
    jobName?: string;
    amount: number;
    monthlyPayment?: number;
    termMonths?: number;
    interestRate?: number;
    providerId?: string;
    providerName?: string;
  }) => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company context');

    const { data, error: err } = await supabase
      .from('financing_applications')
      .insert({
        company_id: companyId,
        customer_id: input.customerId || null,
        job_id: input.jobId || null,
        customer_name: input.customerName,
        job_name: input.jobName || null,
        amount: input.amount,
        monthly_payment: input.monthlyPayment || null,
        term_months: input.termMonths || null,
        interest_rate: input.interestRate || null,
        provider_id: input.providerId || null,
        provider_name: input.providerName || null,
        status: 'offered',
      })
      .select()
      .single();

    if (err) throw err;
    return mapApplication(data as Record<string, unknown>);
  }, []);

  const updateApplicationStatus = useCallback(async (id: string, status: ApplicationStatus, updatedAt: string) => {
    const updateData: Record<string, unknown> = { status, updated_at: updatedAt };
    if (status === 'funded') updateData.funded_at = new Date().toISOString();
    if (status === 'applied') updateData.date_applied = new Date().toISOString();

    const { error: err, count } = await supabase
      .from('financing_applications')
      .update(updateData)
      .eq('id', id)
      .eq('updated_at', updatedAt);

    if (err) throw err;
    if (count === 0) throw new Error('Record was modified by another user. Please reload and try again.');
  }, []);

  const deleteApplication = useCallback(async (id: string) => {
    const { error: err } = await supabase
      .from('financing_applications')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  }, []);

  const createProvider = useCallback(async (input: {
    providerName: string;
    merchantFeePct?: number;
    minAmount?: number;
    maxAmount?: number;
    availableTerms?: number[];
  }) => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company context');

    const { data, error: err } = await supabase
      .from('financing_providers')
      .insert({
        company_id: companyId,
        provider_name: input.providerName,
        provider_slug: input.providerName.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
        merchant_fee_pct: input.merchantFeePct || 0,
        min_amount: input.minAmount || 500,
        max_amount: input.maxAmount || 100000,
        available_terms: input.availableTerms || [12, 24, 36, 48, 60],
      })
      .select()
      .single();

    if (err) throw err;
    return mapProvider(data as Record<string, unknown>);
  }, []);

  const updateProvider = useCallback(async (id: string, input: Partial<{
    connected: boolean;
    apiKeyConfigured: boolean;
    merchantFeePct: number;
    minAmount: number;
    maxAmount: number;
    availableTerms: number[];
    settings: Record<string, unknown>;
  }>) => {
    const updateData: Record<string, unknown> = {};
    if (input.connected !== undefined) updateData.connected = input.connected;
    if (input.apiKeyConfigured !== undefined) updateData.api_key_configured = input.apiKeyConfigured;
    if (input.merchantFeePct !== undefined) updateData.merchant_fee_pct = input.merchantFeePct;
    if (input.minAmount !== undefined) updateData.min_amount = input.minAmount;
    if (input.maxAmount !== undefined) updateData.max_amount = input.maxAmount;
    if (input.availableTerms !== undefined) updateData.available_terms = input.availableTerms;
    if (input.settings !== undefined) updateData.settings = input.settings;

    const { error: err } = await supabase
      .from('financing_providers')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;
  }, []);

  return {
    applications,
    providers,
    summary,
    loading,
    error,
    refresh: fetchAll,
    createApplication,
    updateApplicationStatus,
    deleteApplication,
    createProvider,
    updateProvider,
  };
}
