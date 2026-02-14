'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Warranties Hook — CRUD + Real-time
// ============================================================

export type WarrantyStatus = 'active' | 'expired' | 'claimed' | 'voided';
export type WarrantyType = 'labor' | 'parts' | 'full' | 'manufacturer' | 'extended' | 'other';

export interface WarrantyClaim {
  id: string;
  date: string;
  description: string;
  status: 'open' | 'resolved' | 'denied';
  resolution?: string;
  cost?: number;
}

export interface WarrantyData {
  id: string;
  companyId: string;
  customerId: string | null;
  jobId: string | null;
  createdBy: string | null;
  warrantyNumber: string | null;
  title: string;
  status: WarrantyStatus;
  warrantyType: WarrantyType;
  description: string | null;
  coverageDetails: string | null;
  startDate: string | null;
  endDate: string | null;
  durationMonths: number | null;
  terms: string | null;
  claims: WarrantyClaim[];
  documents: { name: string; type: string; storagePath?: string; uploadedAt: string }[];
  notes: string | null;
  createdAt: string;
  updatedAt: string;
  // Joined
  jobName?: string;
  customerName?: string;
}

function mapWarranty(row: Record<string, unknown>): WarrantyData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    customerId: row.customer_id as string | null,
    jobId: row.job_id as string | null,
    createdBy: row.created_by as string | null,
    warrantyNumber: row.warranty_number as string | null,
    title: row.title as string,
    status: (row.status as WarrantyStatus) || 'active',
    warrantyType: (row.warranty_type as WarrantyType) || 'labor',
    description: row.description as string | null,
    coverageDetails: row.coverage_details as string | null,
    startDate: row.start_date as string | null,
    endDate: row.end_date as string | null,
    durationMonths: row.duration_months as number | null,
    terms: row.terms as string | null,
    claims: Array.isArray(row.claims) ? row.claims as WarrantyClaim[] : [],
    documents: Array.isArray(row.documents) ? row.documents as unknown[] as WarrantyData['documents'] : [],
    notes: row.notes as string | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
    jobName: (row.jobs as Record<string, unknown>)?.title as string | undefined,
    customerName: row.customers ? `${(row.customers as Record<string, unknown>).first_name || ''} ${(row.customers as Record<string, unknown>).last_name || ''}`.trim() : undefined,
  };
}

export function useWarranties() {
  const [warranties, setWarranties] = useState<WarrantyData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchWarranties = useCallback(async () => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('warranties')
      .select('*, jobs(title), customers(first_name, last_name)')
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    if (err) { setError(err.message); setLoading(false); return; }
    setWarranties((data || []).map(mapWarranty));
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchWarranties();

    const supabase = getSupabase();
    const channel = supabase.channel('warranties-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'warranties' }, () => fetchWarranties())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchWarranties]);

  const createWarranty = async (data: Partial<WarrantyData>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { data: result, error: err } = await supabase
      .from('warranties')
      .insert({
        company_id: companyId,
        created_by: user.id,
        customer_id: data.customerId || null,
        job_id: data.jobId || null,
        warranty_number: data.warrantyNumber || null,
        title: data.title || 'Untitled Warranty',
        status: data.status || 'active',
        warranty_type: data.warrantyType || 'labor',
        description: data.description || null,
        coverage_details: data.coverageDetails || null,
        start_date: data.startDate || null,
        end_date: data.endDate || null,
        duration_months: data.durationMonths || null,
        terms: data.terms || null,
        claims: data.claims || [],
        documents: data.documents || [],
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateWarranty = async (id: string, data: Partial<WarrantyData>) => {
    const supabase = getSupabase();
    const updates: Record<string, unknown> = {};
    if (data.warrantyNumber !== undefined) updates.warranty_number = data.warrantyNumber;
    if (data.title !== undefined) updates.title = data.title;
    if (data.status !== undefined) updates.status = data.status;
    if (data.warrantyType !== undefined) updates.warranty_type = data.warrantyType;
    if (data.description !== undefined) updates.description = data.description;
    if (data.coverageDetails !== undefined) updates.coverage_details = data.coverageDetails;
    if (data.startDate !== undefined) updates.start_date = data.startDate;
    if (data.endDate !== undefined) updates.end_date = data.endDate;
    if (data.durationMonths !== undefined) updates.duration_months = data.durationMonths;
    if (data.terms !== undefined) updates.terms = data.terms;
    if (data.claims !== undefined) updates.claims = data.claims;
    if (data.documents !== undefined) updates.documents = data.documents;
    if (data.notes !== undefined) updates.notes = data.notes;
    if (data.customerId !== undefined) updates.customer_id = data.customerId;
    if (data.jobId !== undefined) updates.job_id = data.jobId;

    const { error: err } = await supabase.from('warranties').update(updates).eq('id', id);
    if (err) throw err;
  };

  const deleteWarranty = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase.from('warranties').update({ deleted_at: new Date().toISOString() }).eq('id', id);
    if (err) throw err;
  };

  return { warranties, loading, error, createWarranty, updateWarranty, deleteWarranty };
}
