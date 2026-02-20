'use client';

import { useState, useEffect, useCallback } from 'react';
import { createClient } from '@/lib/supabase';
import { mapInsuranceClaim, mapClaimSupplement, mapTpiInspection, mapMoistureReading, mapDryingLog, mapRestorationEquipment } from './mappers';
import type { InsuranceClaimData, ClaimSupplementData, TpiInspectionData, MoistureReadingData, DryingLogData, RestorationEquipmentData, ClaimStatus, ClaimCategory, LossType, SupplementReason, SupplementStatus } from '@/types';

const supabase = createClient();

// ==================== CLAIMS LIST ====================

export function useClaims() {
  const [claims, setClaims] = useState<InsuranceClaimData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchClaims = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data, error: err } = await supabase
        .from('insurance_claims')
        .select('*, jobs(title, customer_name, address)')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setClaims((data || []).map(mapInsuranceClaim));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load claims');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchClaims();

    const channel = supabase
      .channel('insurance-claims-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'insurance_claims' }, () => {
        fetchClaims();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchClaims]);

  return { claims, loading, error, refetch: fetchClaims };
}

// ==================== SINGLE CLAIM ====================

export function useClaim(claimId: string | null) {
  const [claim, setClaim] = useState<InsuranceClaimData | null>(null);
  const [supplements, setSupplements] = useState<ClaimSupplementData[]>([]);
  const [tpiInspections, setTpiInspections] = useState<TpiInspectionData[]>([]);
  const [moistureReadings, setMoistureReadings] = useState<MoistureReadingData[]>([]);
  const [dryingLogs, setDryingLogs] = useState<DryingLogData[]>([]);
  const [equipment, setEquipment] = useState<RestorationEquipmentData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchClaim = useCallback(async () => {
    if (!claimId) return;
    setLoading(true);
    setError(null);
    try {
      // Fetch claim + all related data in parallel
      const [claimRes, suppRes, tpiRes, moistureRes, dryingRes, equipRes] = await Promise.all([
        supabase.from('insurance_claims').select('*, jobs(title, customer_name, address)').eq('id', claimId).is('deleted_at', null).single(),
        supabase.from('claim_supplements').select('*').eq('claim_id', claimId).order('supplement_number', { ascending: true }),
        supabase.from('tpi_scheduling').select('*').eq('claim_id', claimId).order('scheduled_date', { ascending: false }),
        supabase.from('moisture_readings').select('*').eq('claim_id', claimId).order('recorded_at', { ascending: false }),
        supabase.from('drying_logs').select('*').eq('claim_id', claimId).order('recorded_at', { ascending: false }),
        supabase.from('restoration_equipment').select('*').eq('claim_id', claimId).order('deployed_at', { ascending: false }),
      ]);

      if (claimRes.error) throw claimRes.error;
      setClaim(mapInsuranceClaim(claimRes.data));
      setSupplements((suppRes.data || []).map(mapClaimSupplement));
      setTpiInspections((tpiRes.data || []).map(mapTpiInspection));
      setMoistureReadings((moistureRes.data || []).map(mapMoistureReading));
      setDryingLogs((dryingRes.data || []).map(mapDryingLog));
      setEquipment((equipRes.data || []).map(mapRestorationEquipment));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load claim');
    } finally {
      setLoading(false);
    }
  }, [claimId]);

  useEffect(() => {
    fetchClaim();

    if (!claimId) return;
    const channel = supabase
      .channel(`claim-${claimId}-changes`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'insurance_claims', filter: `id=eq.${claimId}` }, () => { fetchClaim(); })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'claim_supplements', filter: `claim_id=eq.${claimId}` }, () => { fetchClaim(); })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tpi_scheduling', filter: `claim_id=eq.${claimId}` }, () => { fetchClaim(); })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'restoration_equipment', filter: `claim_id=eq.${claimId}` }, () => { fetchClaim(); })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [claimId, fetchClaim]);

  return { claim, supplements, tpiInspections, moistureReadings, dryingLogs, equipment, loading, error, refetch: fetchClaim };
}

// ==================== CLAIM BY JOB ====================

export function useClaimByJob(jobId: string | null) {
  const [claim, setClaim] = useState<InsuranceClaimData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!jobId) { setLoading(false); return; }
    (async () => {
      setLoading(true);
      const { data } = await supabase
        .from('insurance_claims')
        .select('*, jobs(title, customer_name, address)')
        .eq('job_id', jobId)
        .is('deleted_at', null)
        .maybeSingle();
      setClaim(data ? mapInsuranceClaim(data) : null);
      setLoading(false);
    })();
  }, [jobId]);

  return { claim, loading };
}

// ==================== MUTATIONS ====================

export async function createClaim(input: {
  jobId: string;
  insuranceCompany: string;
  claimNumber: string;
  policyNumber?: string;
  dateOfLoss: string;
  lossType?: LossType;
  claimCategory?: ClaimCategory;
  lossDescription?: string;
  adjusterName?: string;
  adjusterPhone?: string;
  adjusterEmail?: string;
  adjusterCompany?: string;
  deductible?: number;
  coverageLimit?: number;
  notes?: string;
}): Promise<string> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');
  const companyId = user.app_metadata?.company_id;
  if (!companyId) throw new Error('No company');

  const { data, error } = await supabase
    .from('insurance_claims')
    .insert({
      company_id: companyId,
      job_id: input.jobId,
      insurance_company: input.insuranceCompany,
      claim_number: input.claimNumber,
      policy_number: input.policyNumber || null,
      date_of_loss: input.dateOfLoss,
      loss_type: input.lossType || 'unknown',
      loss_description: input.lossDescription || null,
      adjuster_name: input.adjusterName || null,
      adjuster_phone: input.adjusterPhone || null,
      adjuster_email: input.adjusterEmail || null,
      adjuster_company: input.adjusterCompany || null,
      deductible: input.deductible || 0,
      coverage_limit: input.coverageLimit || null,
      notes: input.notes || null,
      claim_status: 'new',
      claim_category: input.claimCategory || 'restoration',
    })
    .select('id')
    .single();

  if (error) throw error;
  return data.id;
}

export async function updateClaimStatus(claimId: string, status: ClaimStatus): Promise<void> {
  const updateData: Record<string, unknown> = { claim_status: status };
  const now = new Date().toISOString();

  switch (status) {
    case 'scope_submitted': updateData.scope_submitted_at = now; break;
    case 'estimate_approved': updateData.estimate_approved_at = now; break;
    case 'work_in_progress': updateData.work_started_at = now; break;
    case 'work_complete': updateData.work_completed_at = now; break;
    case 'settled': updateData.settled_at = now; break;
  }

  const { error } = await supabase.from('insurance_claims').update(updateData).eq('id', claimId);
  if (error) throw error;
}

export async function updateClaim(claimId: string, updates: Record<string, unknown>): Promise<void> {
  const { error } = await supabase.from('insurance_claims').update(updates).eq('id', claimId);
  if (error) throw error;
}

export async function deleteClaim(claimId: string): Promise<void> {
  const { error } = await supabase
    .from('insurance_claims')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', claimId);
  if (error) throw error;
}

// ==================== SUPPLEMENT MUTATIONS ====================

export async function createSupplement(input: {
  claimId: string;
  title: string;
  description?: string;
  reason?: SupplementReason;
  amount?: number;
  rcvAmount?: number;
  acvAmount?: number;
  depreciationAmount?: number;
  lineItems?: Record<string, unknown>[];
}): Promise<string> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');
  const companyId = user.app_metadata?.company_id;
  if (!companyId) throw new Error('No company');

  // Auto-increment supplement number
  const { data: existing } = await supabase
    .from('claim_supplements')
    .select('supplement_number')
    .eq('claim_id', input.claimId)
    .order('supplement_number', { ascending: false })
    .limit(1);
  const nextNumber = (existing && existing.length > 0) ? (existing[0].supplement_number || 0) + 1 : 1;

  const { data, error } = await supabase
    .from('claim_supplements')
    .insert({
      company_id: companyId,
      claim_id: input.claimId,
      supplement_number: nextNumber,
      title: input.title,
      description: input.description || null,
      reason: input.reason || 'hidden_damage',
      amount: input.amount || 0,
      rcv_amount: input.rcvAmount || null,
      acv_amount: input.acvAmount || null,
      depreciation_amount: input.depreciationAmount || 0,
      status: 'draft',
      line_items: input.lineItems || [],
    })
    .select('id')
    .single();

  if (error) throw error;
  return data.id;
}

export async function updateSupplement(supplementId: string, updates: {
  title?: string;
  description?: string;
  reason?: SupplementReason;
  amount?: number;
  rcvAmount?: number;
  acvAmount?: number;
  depreciationAmount?: number;
  approvedAmount?: number;
  lineItems?: Record<string, unknown>[];
  reviewerNotes?: string;
}): Promise<void> {
  const updateData: Record<string, unknown> = {};
  if (updates.title !== undefined) updateData.title = updates.title;
  if (updates.description !== undefined) updateData.description = updates.description;
  if (updates.reason !== undefined) updateData.reason = updates.reason;
  if (updates.amount !== undefined) updateData.amount = updates.amount;
  if (updates.rcvAmount !== undefined) updateData.rcv_amount = updates.rcvAmount;
  if (updates.acvAmount !== undefined) updateData.acv_amount = updates.acvAmount;
  if (updates.depreciationAmount !== undefined) updateData.depreciation_amount = updates.depreciationAmount;
  if (updates.approvedAmount !== undefined) updateData.approved_amount = updates.approvedAmount;
  if (updates.lineItems !== undefined) updateData.line_items = updates.lineItems;
  if (updates.reviewerNotes !== undefined) updateData.reviewer_notes = updates.reviewerNotes;

  const { error } = await supabase.from('claim_supplements').update(updateData).eq('id', supplementId);
  if (error) throw error;
}

export async function updateSupplementStatus(supplementId: string, status: SupplementStatus): Promise<void> {
  const updateData: Record<string, unknown> = { status };
  const now = new Date().toISOString();

  if (status === 'submitted') updateData.submitted_at = now;
  if (['approved', 'denied', 'partially_approved', 'under_review'].includes(status)) updateData.reviewed_at = now;

  const { error } = await supabase.from('claim_supplements').update(updateData).eq('id', supplementId);
  if (error) throw error;
}

export async function deleteSupplement(supplementId: string): Promise<void> {
  const { error } = await supabase.from('claim_supplements').update({ deleted_at: new Date().toISOString() }).eq('id', supplementId);
  if (error) throw error;
}
