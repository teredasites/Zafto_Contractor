'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Permits Hook — CRUD + Real-time
// ============================================================

export type PermitStatus = 'draft' | 'applied' | 'in_review' | 'approved' | 'inspection_scheduled' | 'passed' | 'failed' | 'expired' | 'cancelled';
export type PermitType = 'electrical' | 'plumbing' | 'mechanical' | 'building' | 'roofing' | 'solar' | 'demolition' | 'fire' | 'other';

export interface PermitInspection {
  id: string;
  date: string;
  inspector?: string;
  result: 'pass' | 'fail' | 'partial' | 'scheduled';
  notes?: string;
  corrections?: string[];
}

export interface PermitDocument {
  name: string;
  type: string;
  storagePath?: string;
  uploadedAt: string;
}

export interface PermitData {
  id: string;
  companyId: string;
  jobId: string | null;
  customerId: string | null;
  createdBy: string | null;
  permitNumber: string | null;
  permitType: PermitType;
  status: PermitStatus;
  description: string | null;
  address: string | null;
  jurisdiction: string | null;
  fee: number;
  appliedDate: string | null;
  approvedDate: string | null;
  expirationDate: string | null;
  inspections: PermitInspection[];
  documents: PermitDocument[];
  notes: string | null;
  createdAt: string;
  updatedAt: string;
  // Joined
  jobName?: string;
  customerName?: string;
}

function mapPermit(row: Record<string, unknown>): PermitData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    jobId: row.job_id as string | null,
    customerId: row.customer_id as string | null,
    createdBy: row.created_by as string | null,
    permitNumber: row.permit_number as string | null,
    permitType: (row.permit_type as PermitType) || 'other',
    status: (row.status as PermitStatus) || 'draft',
    description: row.description as string | null,
    address: row.address as string | null,
    jurisdiction: row.jurisdiction as string | null,
    fee: Number(row.fee || 0),
    appliedDate: row.applied_date as string | null,
    approvedDate: row.approved_date as string | null,
    expirationDate: row.expiration_date as string | null,
    inspections: Array.isArray(row.inspections) ? row.inspections as PermitInspection[] : [],
    documents: Array.isArray(row.documents) ? row.documents as PermitDocument[] : [],
    notes: row.notes as string | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
    jobName: (row.jobs as Record<string, unknown>)?.title as string | undefined,
    customerName: row.customers ? `${(row.customers as Record<string, unknown>).first_name || ''} ${(row.customers as Record<string, unknown>).last_name || ''}`.trim() : undefined,
  };
}

export function usePermits() {
  const [permits, setPermits] = useState<PermitData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPermits = useCallback(async () => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('permits')
      .select('*, jobs(title), customers(first_name, last_name)')
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    if (err) { setError(err.message); setLoading(false); return; }
    setPermits((data || []).map(mapPermit));
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchPermits();

    const supabase = getSupabase();
    const channel = supabase.channel('permits-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'permits' }, () => fetchPermits())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchPermits]);

  const createPermit = async (data: Partial<PermitData>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { data: result, error: err } = await supabase
      .from('permits')
      .insert({
        company_id: companyId,
        created_by: user.id,
        job_id: data.jobId || null,
        customer_id: data.customerId || null,
        permit_number: data.permitNumber || null,
        permit_type: data.permitType || 'other',
        status: data.status || 'draft',
        description: data.description || null,
        address: data.address || null,
        jurisdiction: data.jurisdiction || null,
        fee: data.fee || 0,
        applied_date: data.appliedDate || null,
        approved_date: data.approvedDate || null,
        expiration_date: data.expirationDate || null,
        inspections: data.inspections || [],
        documents: data.documents || [],
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updatePermit = async (id: string, data: Partial<PermitData>) => {
    const supabase = getSupabase();
    const updates: Record<string, unknown> = {};
    if (data.permitNumber !== undefined) updates.permit_number = data.permitNumber;
    if (data.permitType !== undefined) updates.permit_type = data.permitType;
    if (data.status !== undefined) updates.status = data.status;
    if (data.description !== undefined) updates.description = data.description;
    if (data.address !== undefined) updates.address = data.address;
    if (data.jurisdiction !== undefined) updates.jurisdiction = data.jurisdiction;
    if (data.fee !== undefined) updates.fee = data.fee;
    if (data.appliedDate !== undefined) updates.applied_date = data.appliedDate;
    if (data.approvedDate !== undefined) updates.approved_date = data.approvedDate;
    if (data.expirationDate !== undefined) updates.expiration_date = data.expirationDate;
    if (data.inspections !== undefined) updates.inspections = data.inspections;
    if (data.documents !== undefined) updates.documents = data.documents;
    if (data.notes !== undefined) updates.notes = data.notes;
    if (data.jobId !== undefined) updates.job_id = data.jobId;
    if (data.customerId !== undefined) updates.customer_id = data.customerId;

    const { error: err } = await supabase.from('permits').update(updates).eq('id', id);
    if (err) throw err;
  };

  const deletePermit = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase.from('permits').update({ deleted_at: new Date().toISOString() }).eq('id', id);
    if (err) throw err;
  };

  return { permits, loading, error, createPermit, updatePermit, deletePermit };
}
