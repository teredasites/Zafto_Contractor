'use client';

import { useState, useEffect, useCallback } from 'react';
import { createClient } from '@/lib/supabase';
import type { TpaProgramData } from './use-tpa-programs';

// ==================== TYPES ====================

export type TpaAssignmentStatus =
  | 'received' | 'contacted' | 'scheduled' | 'onsite' | 'inspecting'
  | 'estimate_pending' | 'estimate_submitted' | 'approved'
  | 'in_progress' | 'supplement_pending' | 'supplement_submitted'
  | 'drying' | 'monitoring' | 'completed' | 'closed'
  | 'declined' | 'cancelled' | 'reassigned';

export type TpaLossType =
  | 'water' | 'fire' | 'smoke' | 'mold' | 'storm' | 'wind'
  | 'hail' | 'flood' | 'vandalism' | 'theft' | 'biohazard' | 'other';

export type SlaStatus = 'on_track' | 'approaching' | 'overdue';

export interface TpaAssignmentData {
  id: string;
  companyId: string;
  tpaProgramId: string;
  jobId: string | null;
  createdByUserId: string | null;
  assignmentNumber: string | null;
  claimNumber: string | null;
  policyNumber: string | null;
  carrierName: string | null;
  adjusterName: string | null;
  adjusterPhone: string | null;
  adjusterEmail: string | null;
  policyholderName: string | null;
  policyholderPhone: string | null;
  policyholderEmail: string | null;
  propertyAddress: string | null;
  propertyCity: string | null;
  propertyState: string | null;
  propertyZip: string | null;
  lossType: TpaLossType | null;
  lossDate: string | null;
  lossDescription: string | null;
  assignedAt: string;
  firstContactDeadline: string | null;
  onsiteDeadline: string | null;
  estimateDeadline: string | null;
  completionDeadline: string | null;
  firstContactAt: string | null;
  onsiteAt: string | null;
  estimateSubmittedAt: string | null;
  workStartedAt: string | null;
  workCompletedAt: string | null;
  esaRequested: boolean;
  esaAuthorized: boolean;
  esaAuthorizedAt: string | null;
  esaAmount: number | null;
  esaNotes: string | null;
  status: TpaAssignmentStatus;
  referralFeeAmount: number | null;
  totalEstimated: number;
  totalInvoiced: number;
  totalCollected: number;
  totalSupplements: number;
  paymentDueDate: string | null;
  lastPaymentFollowupAt: string | null;
  paymentFollowupCount: number;
  tpaScore: number | null;
  customerSatisfactionScore: number | null;
  internalNotes: string | null;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  // Joined data
  program?: { name: string; sla_first_contact_minutes: number; sla_onsite_minutes: number; sla_estimate_minutes: number };
  job?: { title: string; customer_name: string };
}

// ==================== HELPERS ====================

export function getSlaStatus(deadline: string | null, completedAt: string | null): SlaStatus {
  if (!deadline) return 'on_track';
  if (completedAt) return 'on_track'; // Already met
  const now = new Date();
  const dl = new Date(deadline);
  const remaining = dl.getTime() - now.getTime();
  const thirtyMin = 30 * 60 * 1000;
  if (remaining < 0) return 'overdue';
  if (remaining < thirtyMin) return 'approaching';
  return 'on_track';
}

export function formatTimeRemaining(deadline: string | null, completedAt: string | null): string {
  if (!deadline) return '--';
  if (completedAt) return 'Met';
  const now = new Date();
  const dl = new Date(deadline);
  const diff = dl.getTime() - now.getTime();
  if (diff < 0) {
    const overdue = Math.abs(diff);
    const hours = Math.floor(overdue / (1000 * 60 * 60));
    const mins = Math.floor((overdue % (1000 * 60 * 60)) / (1000 * 60));
    return hours > 0 ? `${hours}h ${mins}m overdue` : `${mins}m overdue`;
  }
  const hours = Math.floor(diff / (1000 * 60 * 60));
  const mins = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  return hours > 0 ? `${hours}h ${mins}m` : `${mins}m`;
}

// ==================== MAPPER ====================

function mapTpaAssignment(row: Record<string, unknown>): TpaAssignmentData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    tpaProgramId: row.tpa_program_id as string,
    jobId: (row.job_id as string) ?? null,
    createdByUserId: (row.created_by_user_id as string) ?? null,
    assignmentNumber: (row.assignment_number as string) ?? null,
    claimNumber: (row.claim_number as string) ?? null,
    policyNumber: (row.policy_number as string) ?? null,
    carrierName: (row.carrier_name as string) ?? null,
    adjusterName: (row.adjuster_name as string) ?? null,
    adjusterPhone: (row.adjuster_phone as string) ?? null,
    adjusterEmail: (row.adjuster_email as string) ?? null,
    policyholderName: (row.policyholder_name as string) ?? null,
    policyholderPhone: (row.policyholder_phone as string) ?? null,
    policyholderEmail: (row.policyholder_email as string) ?? null,
    propertyAddress: (row.property_address as string) ?? null,
    propertyCity: (row.property_city as string) ?? null,
    propertyState: (row.property_state as string) ?? null,
    propertyZip: (row.property_zip as string) ?? null,
    lossType: (row.loss_type as TpaLossType) ?? null,
    lossDate: (row.loss_date as string) ?? null,
    lossDescription: (row.loss_description as string) ?? null,
    assignedAt: row.assigned_at as string,
    firstContactDeadline: (row.first_contact_deadline as string) ?? null,
    onsiteDeadline: (row.onsite_deadline as string) ?? null,
    estimateDeadline: (row.estimate_deadline as string) ?? null,
    completionDeadline: (row.completion_deadline as string) ?? null,
    firstContactAt: (row.first_contact_at as string) ?? null,
    onsiteAt: (row.onsite_at as string) ?? null,
    estimateSubmittedAt: (row.estimate_submitted_at as string) ?? null,
    workStartedAt: (row.work_started_at as string) ?? null,
    workCompletedAt: (row.work_completed_at as string) ?? null,
    esaRequested: row.esa_requested === true,
    esaAuthorized: row.esa_authorized === true,
    esaAuthorizedAt: (row.esa_authorized_at as string) ?? null,
    esaAmount: row.esa_amount != null ? Number(row.esa_amount) : null,
    esaNotes: (row.esa_notes as string) ?? null,
    status: (row.status as TpaAssignmentStatus) ?? 'received',
    referralFeeAmount: row.referral_fee_amount != null ? Number(row.referral_fee_amount) : null,
    totalEstimated: Number(row.total_estimated ?? 0),
    totalInvoiced: Number(row.total_invoiced ?? 0),
    totalCollected: Number(row.total_collected ?? 0),
    totalSupplements: Number(row.total_supplements ?? 0),
    paymentDueDate: (row.payment_due_date as string) ?? null,
    lastPaymentFollowupAt: (row.last_payment_followup_at as string) ?? null,
    paymentFollowupCount: Number(row.payment_followup_count ?? 0),
    tpaScore: row.tpa_score != null ? Number(row.tpa_score) : null,
    customerSatisfactionScore: row.customer_satisfaction_score != null ? Number(row.customer_satisfaction_score) : null,
    internalNotes: (row.internal_notes as string) ?? null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
    deletedAt: (row.deleted_at as string) ?? null,
    program: row.tpa_programs as TpaAssignmentData['program'] ?? undefined,
    job: row.jobs as TpaAssignmentData['job'] ?? undefined,
  };
}

// ==================== ASSIGNMENTS LIST ====================

const supabase = createClient();

export function useTpaAssignments(filters?: { status?: TpaAssignmentStatus; programId?: string }) {
  const [assignments, setAssignments] = useState<TpaAssignmentData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAssignments = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      let query = supabase
        .from('tpa_assignments')
        .select('*, tpa_programs(name, sla_first_contact_minutes, sla_onsite_minutes, sla_estimate_minutes), jobs(title, customer_name)')
        .is('deleted_at', null)
        .order('assigned_at', { ascending: false });

      if (filters?.status) {
        query = query.eq('status', filters.status);
      }
      if (filters?.programId) {
        query = query.eq('tpa_program_id', filters.programId);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setAssignments((data || []).map(mapTpaAssignment));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load assignments');
    } finally {
      setLoading(false);
    }
  }, [filters?.status, filters?.programId]);

  useEffect(() => {
    fetchAssignments();

    const channel = supabase
      .channel('tpa-assignments-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tpa_assignments' }, () => {
        fetchAssignments();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchAssignments]);

  return { assignments, loading, error, refetch: fetchAssignments };
}

// ==================== SINGLE ASSIGNMENT ====================

export function useTpaAssignment(assignmentId: string | null) {
  const [assignment, setAssignment] = useState<TpaAssignmentData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAssignment = useCallback(async () => {
    if (!assignmentId) { setLoading(false); return; }
    setLoading(true);
    setError(null);
    try {
      const { data, error: err } = await supabase
        .from('tpa_assignments')
        .select('*, tpa_programs(name, sla_first_contact_minutes, sla_onsite_minutes, sla_estimate_minutes), jobs(title, customer_name)')
        .eq('id', assignmentId)
        .is('deleted_at', null)
        .single();

      if (err) throw err;
      setAssignment(data ? mapTpaAssignment(data) : null);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load assignment');
    } finally {
      setLoading(false);
    }
  }, [assignmentId]);

  useEffect(() => {
    fetchAssignment();

    if (!assignmentId) return;
    const channel = supabase
      .channel(`tpa-assignment-${assignmentId}-changes`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tpa_assignments', filter: `id=eq.${assignmentId}` }, () => {
        fetchAssignment();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [assignmentId, fetchAssignment]);

  return { assignment, loading, error, refetch: fetchAssignment };
}

// ==================== MUTATIONS ====================

export async function createTpaAssignment(input: {
  tpaProgramId: string;
  assignmentNumber?: string;
  claimNumber?: string;
  policyNumber?: string;
  carrierName?: string;
  adjusterName?: string;
  adjusterPhone?: string;
  adjusterEmail?: string;
  policyholderName?: string;
  policyholderPhone?: string;
  policyholderEmail?: string;
  propertyAddress?: string;
  propertyCity?: string;
  propertyState?: string;
  propertyZip?: string;
  lossType?: TpaLossType;
  lossDate?: string;
  lossDescription?: string;
  jobId?: string;
  internalNotes?: string;
}): Promise<string> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');
  const companyId = user.app_metadata?.company_id;
  if (!companyId) throw new Error('No company associated');

  // Fetch program SLA settings for auto-calculation
  const { data: program } = await supabase
    .from('tpa_programs')
    .select('sla_first_contact_minutes, sla_onsite_minutes, sla_estimate_minutes, sla_completion_days, referral_fee_type, referral_fee_pct, referral_fee_flat')
    .eq('id', input.tpaProgramId)
    .is('deleted_at', null)
    .single();

  const now = new Date();
  const assignedAt = now.toISOString();

  // Auto-calculate SLA deadlines from program settings
  const firstContactDeadline = program?.sla_first_contact_minutes
    ? new Date(now.getTime() + program.sla_first_contact_minutes * 60 * 1000).toISOString()
    : null;
  const onsiteDeadline = program?.sla_onsite_minutes
    ? new Date(now.getTime() + program.sla_onsite_minutes * 60 * 1000).toISOString()
    : null;
  const estimateDeadline = program?.sla_estimate_minutes
    ? new Date(now.getTime() + program.sla_estimate_minutes * 60 * 1000).toISOString()
    : null;
  const completionDeadline = program?.sla_completion_days
    ? new Date(now.getTime() + program.sla_completion_days * 24 * 60 * 60 * 1000).toISOString()
    : null;

  const { data, error } = await supabase
    .from('tpa_assignments')
    .insert({
      company_id: companyId,
      tpa_program_id: input.tpaProgramId,
      job_id: input.jobId || null,
      created_by_user_id: user.id,
      assignment_number: input.assignmentNumber || null,
      claim_number: input.claimNumber || null,
      policy_number: input.policyNumber || null,
      carrier_name: input.carrierName || null,
      adjuster_name: input.adjusterName || null,
      adjuster_phone: input.adjusterPhone || null,
      adjuster_email: input.adjusterEmail || null,
      policyholder_name: input.policyholderName || null,
      policyholder_phone: input.policyholderPhone || null,
      policyholder_email: input.policyholderEmail || null,
      property_address: input.propertyAddress || null,
      property_city: input.propertyCity || null,
      property_state: input.propertyState || null,
      property_zip: input.propertyZip || null,
      loss_type: input.lossType || null,
      loss_date: input.lossDate || null,
      loss_description: input.lossDescription || null,
      assigned_at: assignedAt,
      first_contact_deadline: firstContactDeadline,
      onsite_deadline: onsiteDeadline,
      estimate_deadline: estimateDeadline,
      completion_deadline: completionDeadline,
      status: 'received',
      internal_notes: input.internalNotes || null,
    })
    .select('id')
    .single();

  if (error) throw error;
  return data.id;
}

export async function updateTpaAssignment(assignmentId: string, updates: Record<string, unknown>): Promise<void> {
  const { error } = await supabase.from('tpa_assignments').update(updates).eq('id', assignmentId);
  if (error) throw error;
}

export async function updateAssignmentStatus(assignmentId: string, status: TpaAssignmentStatus): Promise<void> {
  const updateData: Record<string, unknown> = { status };
  const now = new Date().toISOString();

  // Auto-set milestone timestamps based on status transition
  switch (status) {
    case 'contacted': updateData.first_contact_at = now; break;
    case 'onsite': updateData.onsite_at = now; break;
    case 'estimate_submitted': updateData.estimate_submitted_at = now; break;
    case 'in_progress': updateData.work_started_at = now; break;
    case 'completed': updateData.work_completed_at = now; break;
  }

  const { error } = await supabase.from('tpa_assignments').update(updateData).eq('id', assignmentId);
  if (error) throw error;
}

export async function deleteTpaAssignment(assignmentId: string): Promise<void> {
  const { error } = await supabase
    .from('tpa_assignments')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', assignmentId);
  if (error) throw error;
}

// ==================== JOB INTEGRATION ====================

export async function createJobFromAssignment(assignmentId: string): Promise<string> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');
  const companyId = user.app_metadata?.company_id;
  if (!companyId) throw new Error('No company associated');

  // Fetch assignment data
  const { data: assignment, error: fetchErr } = await supabase
    .from('tpa_assignments')
    .select('*, tpa_programs(name)')
    .eq('id', assignmentId)
    .single();

  if (fetchErr || !assignment) throw new Error('Assignment not found');

  // Create job from assignment data
  const { data: job, error: jobErr } = await supabase
    .from('jobs')
    .insert({
      company_id: companyId,
      created_by_user_id: user.id,
      title: `${(assignment.tpa_programs as Record<string,unknown>)?.name ?? 'TPA'} - ${assignment.claim_number || assignment.assignment_number || 'Assignment'}`,
      customer_name: assignment.policyholder_name || '',
      customer_email: assignment.policyholder_email || null,
      customer_phone: assignment.policyholder_phone || null,
      address: assignment.property_address || '',
      city: assignment.property_city || null,
      state: assignment.property_state || null,
      zip_code: assignment.property_zip || null,
      status: 'scheduled',
      priority: 'high',
      job_type: 'insurance_claim',
      is_tpa_job: true,
      tpa_assignment_id: assignmentId,
      tpa_program_id: assignment.tpa_program_id,
    })
    .select('id')
    .single();

  if (jobErr) throw jobErr;

  // Link job back to assignment
  await supabase
    .from('tpa_assignments')
    .update({ job_id: job.id })
    .eq('id', assignmentId);

  return job.id;
}
