'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Service Agreements Hook — CRUD + Real-time
// ============================================================

export type AgreementStatus = 'draft' | 'active' | 'expired' | 'cancelled' | 'pending_renewal';
export type AgreementType = 'maintenance' | 'service' | 'warranty' | 'support' | 'inspection' | 'other';
export type BillingFrequency = 'monthly' | 'quarterly' | 'semi_annual' | 'annual' | 'one_time';
export type RenewalType = 'auto' | 'manual' | 'none';

export interface AgreementService {
  name: string;
  description?: string;
  frequency?: string;
  included: boolean;
}

export interface ServiceAgreementData {
  id: string;
  companyId: string;
  customerId: string | null;
  createdBy: string | null;
  agreementNumber: string | null;
  title: string;
  status: AgreementStatus;
  agreementType: AgreementType;
  description: string | null;
  startDate: string | null;
  endDate: string | null;
  renewalType: RenewalType;
  billingFrequency: BillingFrequency;
  billingAmount: number;
  totalValue: number;
  services: AgreementService[];
  documents: { name: string; type: string; storagePath?: string; uploadedAt: string }[];
  notes: string | null;
  lastServiceDate: string | null;
  nextServiceDate: string | null;
  createdAt: string;
  updatedAt: string;
  // Joined
  customerName?: string;
}

function mapAgreement(row: Record<string, unknown>): ServiceAgreementData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    customerId: row.customer_id as string | null,
    createdBy: row.created_by as string | null,
    agreementNumber: row.agreement_number as string | null,
    title: row.title as string,
    status: (row.status as AgreementStatus) || 'draft',
    agreementType: (row.agreement_type as AgreementType) || 'maintenance',
    description: row.description as string | null,
    startDate: row.start_date as string | null,
    endDate: row.end_date as string | null,
    renewalType: (row.renewal_type as RenewalType) || 'manual',
    billingFrequency: (row.billing_frequency as BillingFrequency) || 'monthly',
    billingAmount: Number(row.billing_amount || 0),
    totalValue: Number(row.total_value || 0),
    services: Array.isArray(row.services) ? row.services as AgreementService[] : [],
    documents: Array.isArray(row.documents) ? row.documents as unknown[] as ServiceAgreementData['documents'] : [],
    notes: row.notes as string | null,
    lastServiceDate: row.last_service_date as string | null,
    nextServiceDate: row.next_service_date as string | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
    customerName: row.customers ? `${(row.customers as Record<string, unknown>).first_name || ''} ${(row.customers as Record<string, unknown>).last_name || ''}`.trim() : undefined,
  };
}

export function useServiceAgreements() {
  const [agreements, setAgreements] = useState<ServiceAgreementData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAgreements = useCallback(async () => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('service_agreements')
      .select('*, customers(first_name, last_name)')
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    if (err) { setError(err.message); setLoading(false); return; }
    setAgreements((data || []).map(mapAgreement));
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchAgreements();

    const supabase = getSupabase();
    const channel = supabase.channel('service-agreements-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'service_agreements' }, () => fetchAgreements())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchAgreements]);

  const createAgreement = async (data: Partial<ServiceAgreementData>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { data: result, error: err } = await supabase
      .from('service_agreements')
      .insert({
        company_id: companyId,
        created_by: user.id,
        customer_id: data.customerId || null,
        agreement_number: data.agreementNumber || null,
        title: data.title || 'Untitled Agreement',
        status: data.status || 'draft',
        agreement_type: data.agreementType || 'maintenance',
        description: data.description || null,
        start_date: data.startDate || null,
        end_date: data.endDate || null,
        renewal_type: data.renewalType || 'manual',
        billing_frequency: data.billingFrequency || 'monthly',
        billing_amount: data.billingAmount || 0,
        total_value: data.totalValue || 0,
        services: data.services || [],
        documents: data.documents || [],
        notes: data.notes || null,
        last_service_date: data.lastServiceDate || null,
        next_service_date: data.nextServiceDate || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    fetchAgreements();
    return result.id;
  };

  const updateAgreement = async (id: string, data: Partial<ServiceAgreementData>) => {
    const supabase = getSupabase();
    const updates: Record<string, unknown> = {};
    if (data.agreementNumber !== undefined) updates.agreement_number = data.agreementNumber;
    if (data.title !== undefined) updates.title = data.title;
    if (data.status !== undefined) updates.status = data.status;
    if (data.agreementType !== undefined) updates.agreement_type = data.agreementType;
    if (data.description !== undefined) updates.description = data.description;
    if (data.startDate !== undefined) updates.start_date = data.startDate;
    if (data.endDate !== undefined) updates.end_date = data.endDate;
    if (data.renewalType !== undefined) updates.renewal_type = data.renewalType;
    if (data.billingFrequency !== undefined) updates.billing_frequency = data.billingFrequency;
    if (data.billingAmount !== undefined) updates.billing_amount = data.billingAmount;
    if (data.totalValue !== undefined) updates.total_value = data.totalValue;
    if (data.services !== undefined) updates.services = data.services;
    if (data.documents !== undefined) updates.documents = data.documents;
    if (data.notes !== undefined) updates.notes = data.notes;
    if (data.customerId !== undefined) updates.customer_id = data.customerId;
    if (data.lastServiceDate !== undefined) updates.last_service_date = data.lastServiceDate;
    if (data.nextServiceDate !== undefined) updates.next_service_date = data.nextServiceDate;

    const { error: err } = await supabase.from('service_agreements').update(updates).eq('id', id);
    if (err) throw err;
    fetchAgreements();
  };

  const deleteAgreement = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase.from('service_agreements').update({ deleted_at: new Date().toISOString() }).eq('id', id);
    if (err) throw err;
    fetchAgreements();
  };

  return { agreements, loading, error, createAgreement, updateAgreement, deleteAgreement, refetch: fetchAgreements };
}
