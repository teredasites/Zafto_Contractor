'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──────────────────────────────────────────────────────────
export interface Subcontractor {
  id: string;
  name: string;
  companyName: string | null;
  email: string | null;
  phone: string | null;
  tradeTypes: string[];
  licenseNumber: string | null;
  licenseState: string | null;
  licenseExpiry: string | null;
  insuranceCarrier: string | null;
  insurancePolicyNumber: string | null;
  insuranceExpiry: string | null;
  w9OnFile: boolean;
  notes: string | null;
  status: 'active' | 'inactive' | 'suspended';
  rating: number | null;
  totalJobsAssigned: number;
  totalPaid: number;
  createdAt: string;
}

export interface JobSubcontractor {
  id: string;
  jobId: string;
  subcontractorId: string;
  subcontractorName?: string;
  scopeDescription: string | null;
  agreedAmount: number;
  paidAmount: number;
  status: 'assigned' | 'in_progress' | 'completed' | 'disputed';
  startDate: string | null;
  endDate: string | null;
  notes: string | null;
}

export interface ComplianceAlert {
  subcontractorId: string;
  name: string;
  type: 'insurance_expiring' | 'license_expiring' | 'missing_w9';
  expiryDate?: string;
  daysRemaining?: number;
}

export const TRADE_TYPE_OPTIONS = [
  'electrical', 'plumbing', 'hvac', 'roofing', 'painting', 'concrete',
  'framing', 'drywall', 'flooring', 'tile', 'masonry', 'landscaping',
  'demolition', 'excavation', 'insulation', 'siding', 'windows_doors',
  'fire_protection', 'solar', 'general',
] as const;

function mapSub(row: Record<string, unknown>): Subcontractor {
  return {
    id: row.id as string,
    name: row.name as string,
    companyName: row.company_name as string | null,
    email: row.email as string | null,
    phone: row.phone as string | null,
    tradeTypes: (row.trade_types as string[]) || [],
    licenseNumber: row.license_number as string | null,
    licenseState: row.license_state as string | null,
    licenseExpiry: row.license_expiry as string | null,
    insuranceCarrier: row.insurance_carrier as string | null,
    insurancePolicyNumber: row.insurance_policy_number as string | null,
    insuranceExpiry: row.insurance_expiry as string | null,
    w9OnFile: row.w9_on_file as boolean,
    notes: row.notes as string | null,
    status: row.status as Subcontractor['status'],
    rating: row.rating ? Number(row.rating) : null,
    totalJobsAssigned: Number(row.total_jobs_assigned) || 0,
    totalPaid: Number(row.total_paid) || 0,
    createdAt: row.created_at as string,
  };
}

function mapJobSub(row: Record<string, unknown>): JobSubcontractor {
  const sub = row.subcontractors as Record<string, unknown> | null;
  return {
    id: row.id as string,
    jobId: row.job_id as string,
    subcontractorId: row.subcontractor_id as string,
    subcontractorName: sub ? (sub.name as string) : undefined,
    scopeDescription: row.scope_description as string | null,
    agreedAmount: Number(row.agreed_amount) || 0,
    paidAmount: Number(row.paid_amount) || 0,
    status: row.status as JobSubcontractor['status'],
    startDate: row.start_date as string | null,
    endDate: row.end_date as string | null,
    notes: row.notes as string | null,
  };
}

// ── Main Hook ──────────────────────────────────────────────────────
export function useSubcontractors() {
  const [subs, setSubs] = useState<Subcontractor[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSubs = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('subcontractors')
        .select('*')
        .is('deleted_at', null)
        .order('name', { ascending: true });

      if (err) throw err;
      setSubs((data || []).map((r: Record<string, unknown>) => mapSub(r)));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load subcontractors');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSubs();

    const supabase = getSupabase();
    const channel = supabase
      .channel('subs-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'subcontractors' }, () => {
        fetchSubs();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchSubs]);

  // ── Create ─────────────────────────────────────────────────────
  const createSub = async (input: {
    name: string;
    companyName?: string;
    email?: string;
    phone?: string;
    tradeTypes: string[];
    licenseNumber?: string;
    licenseState?: string;
    licenseExpiry?: string;
    insuranceCarrier?: string;
    insurancePolicyNumber?: string;
    insuranceExpiry?: string;
    w9OnFile?: boolean;
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { data, error: err } = await supabase
      .from('subcontractors')
      .insert({
        company_id: companyId,
        name: input.name,
        company_name: input.companyName || null,
        email: input.email || null,
        phone: input.phone || null,
        trade_types: input.tradeTypes,
        license_number: input.licenseNumber || null,
        license_state: input.licenseState || null,
        license_expiry: input.licenseExpiry || null,
        insurance_carrier: input.insuranceCarrier || null,
        insurance_policy_number: input.insurancePolicyNumber || null,
        insurance_expiry: input.insuranceExpiry || null,
        w9_on_file: input.w9OnFile || false,
        notes: input.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return data.id;
  };

  // ── Update ─────────────────────────────────────────────────────
  const updateSub = async (id: string, input: Partial<Subcontractor>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};
    if (input.name !== undefined) updateData.name = input.name;
    if (input.companyName !== undefined) updateData.company_name = input.companyName;
    if (input.email !== undefined) updateData.email = input.email;
    if (input.phone !== undefined) updateData.phone = input.phone;
    if (input.tradeTypes !== undefined) updateData.trade_types = input.tradeTypes;
    if (input.licenseNumber !== undefined) updateData.license_number = input.licenseNumber;
    if (input.licenseState !== undefined) updateData.license_state = input.licenseState;
    if (input.licenseExpiry !== undefined) updateData.license_expiry = input.licenseExpiry;
    if (input.insuranceCarrier !== undefined) updateData.insurance_carrier = input.insuranceCarrier;
    if (input.insurancePolicyNumber !== undefined) updateData.insurance_policy_number = input.insurancePolicyNumber;
    if (input.insuranceExpiry !== undefined) updateData.insurance_expiry = input.insuranceExpiry;
    if (input.w9OnFile !== undefined) updateData.w9_on_file = input.w9OnFile;
    if (input.notes !== undefined) updateData.notes = input.notes;
    if (input.status !== undefined) updateData.status = input.status;
    if (input.rating !== undefined) updateData.rating = input.rating;

    const { error: err } = await supabase.from('subcontractors').update(updateData).eq('id', id);
    if (err) throw err;
  };

  // ── Delete (soft) ──────────────────────────────────────────────
  const deleteSub = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('subcontractors')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  // ── Assign sub to job ──────────────────────────────────────────
  const assignToJob = async (input: {
    jobId: string;
    subcontractorId: string;
    scopeDescription?: string;
    agreedAmount: number;
    startDate?: string;
    endDate?: string;
  }) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;

    const { error: err } = await supabase.from('job_subcontractors').insert({
      company_id: companyId,
      job_id: input.jobId,
      subcontractor_id: input.subcontractorId,
      scope_description: input.scopeDescription || null,
      agreed_amount: input.agreedAmount,
      start_date: input.startDate || null,
      end_date: input.endDate || null,
    });
    if (err) throw err;

    // Increment total_jobs_assigned
    await supabase.rpc('increment_field', {
      table_name: 'subcontractors',
      field_name: 'total_jobs_assigned',
      row_id: input.subcontractorId,
      amount: 1,
    }).then(() => {}).catch(() => {
      // Fallback: direct update
      const sub = subs.find((s) => s.id === input.subcontractorId);
      if (sub) {
        supabase.from('subcontractors')
          .update({ total_jobs_assigned: sub.totalJobsAssigned + 1 })
          .eq('id', input.subcontractorId);
      }
    });
  };

  // ── Record sub payment ─────────────────────────────────────────
  const recordSubPayment = async (jobSubId: string, amount: number) => {
    const supabase = getSupabase();

    // Get current job_subcontractor record
    const { data: js, error: fetchErr } = await supabase
      .from('job_subcontractors')
      .select('paid_amount, subcontractor_id')
      .eq('id', jobSubId)
      .is('deleted_at', null)
      .single();
    if (fetchErr) throw fetchErr;

    const newPaid = Number(js.paid_amount) + amount;
    const { error: updErr } = await supabase
      .from('job_subcontractors')
      .update({ paid_amount: newPaid })
      .eq('id', jobSubId);
    if (updErr) throw updErr;

    // Update sub total_paid
    const sub = subs.find((s) => s.id === js.subcontractor_id);
    if (sub) {
      await supabase
        .from('subcontractors')
        .update({ total_paid: sub.totalPaid + amount })
        .eq('id', js.subcontractor_id);
    }
  };

  // ── Get job subcontractors ─────────────────────────────────────
  const getJobSubs = async (jobId: string): Promise<JobSubcontractor[]> => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('job_subcontractors')
      .select('*, subcontractors(name)')
      .eq('job_id', jobId)
      .is('deleted_at', null)
      .order('created_at', { ascending: true });

    if (err) throw err;
    return (data || []).map((r: Record<string, unknown>) => mapJobSub(r));
  };

  // ── Compliance alerts ──────────────────────────────────────────
  const complianceAlerts: ComplianceAlert[] = [];
  const now = new Date();
  const thirtyDaysOut = new Date(now.getTime() + 30 * 86400000);

  for (const sub of subs) {
    if (sub.status === 'inactive') continue;

    if (!sub.w9OnFile) {
      complianceAlerts.push({
        subcontractorId: sub.id,
        name: sub.name,
        type: 'missing_w9',
      });
    }

    if (sub.insuranceExpiry) {
      const exp = new Date(sub.insuranceExpiry);
      if (exp <= thirtyDaysOut) {
        const days = Math.ceil((exp.getTime() - now.getTime()) / 86400000);
        complianceAlerts.push({
          subcontractorId: sub.id,
          name: sub.name,
          type: 'insurance_expiring',
          expiryDate: sub.insuranceExpiry,
          daysRemaining: Math.max(0, days),
        });
      }
    }

    if (sub.licenseExpiry) {
      const exp = new Date(sub.licenseExpiry);
      if (exp <= thirtyDaysOut) {
        const days = Math.ceil((exp.getTime() - now.getTime()) / 86400000);
        complianceAlerts.push({
          subcontractorId: sub.id,
          name: sub.name,
          type: 'license_expiring',
          expiryDate: sub.licenseExpiry,
          daysRemaining: Math.max(0, days),
        });
      }
    }
  }

  // ── 1099 Export ────────────────────────────────────────────────
  const export1099Data = async (year: number): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;

    // Get all subs with total paid > $600 for the year
    const { data, error: err } = await supabase
      .from('subcontractors')
      .select('name, company_name, email, phone, total_paid')
      .eq('company_id', companyId)
      .is('deleted_at', null)
      .gte('total_paid', 600);

    if (err) throw err;

    const lines = ['Name,Company,Email,Phone,Total Paid,1099 Required'];
    for (const s of data || []) {
      const paid = Number(s.total_paid) || 0;
      lines.push(`"${s.name}","${s.company_name || ''}","${s.email || ''}","${s.phone || ''}",${paid.toFixed(2)},${paid >= 600 ? 'Yes' : 'No'}`);
    }
    return lines.join('\n');
  };

  return {
    subs,
    loading,
    error,
    complianceAlerts,
    createSub,
    updateSub,
    deleteSub,
    assignToJob,
    recordSubPayment,
    getJobSubs,
    export1099Data,
    refetch: fetchSubs,
  };
}
