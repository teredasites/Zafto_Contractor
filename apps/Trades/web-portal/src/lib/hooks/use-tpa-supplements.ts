'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type SupplementReason =
  | 'hidden_damage'
  | 'scope_change'
  | 'category_escalation'
  | 'additional_areas'
  | 'code_upgrade'
  | 'emergency_services'
  | 'contents'
  | 'additional_equipment'
  | 'extended_drying'
  | 'mold_discovered'
  | 'structural'
  | 'other';

export type SupplementStatus =
  | 'draft'
  | 'submitted'
  | 'under_review'
  | 'approved'
  | 'partially_approved'
  | 'denied'
  | 'resubmitted'
  | 'withdrawn';

export interface TpaSupplementData {
  id: string;
  companyId: string;
  tpaAssignmentId: string;
  createdByUserId: string | null;
  supplementNumber: number;
  title: string;
  description: string | null;
  reason: SupplementReason;
  reasonDetail: string | null;
  originalAmount: number;
  supplementAmount: number;
  approvedAmount: number | null;
  status: SupplementStatus;
  submittedAt: string | null;
  reviewedAt: string | null;
  reviewerName: string | null;
  reviewerNotes: string | null;
  denialReason: string | null;
  photoIds: string[];
  lineItemIds: string[];
  supportingDocs: { name: string; path: string; type: string }[];
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
}

export interface CreateSupplementInput {
  tpaAssignmentId: string;
  title: string;
  description?: string;
  reason: SupplementReason;
  reasonDetail?: string;
  originalAmount?: number;
  supplementAmount: number;
  photoIds?: string[];
  lineItemIds?: string[];
}

export interface UpdateSupplementInput {
  title?: string;
  description?: string;
  reason?: SupplementReason;
  reasonDetail?: string;
  supplementAmount?: number;
  photoIds?: string[];
  lineItemIds?: string[];
  supportingDocs?: { name: string; path: string; type: string }[];
}

// ============================================================================
// MAPPER
// ============================================================================

function mapSupplement(row: Record<string, unknown>): TpaSupplementData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    tpaAssignmentId: row.tpa_assignment_id as string,
    createdByUserId: row.created_by_user_id as string | null,
    supplementNumber: row.supplement_number as number,
    title: row.title as string,
    description: row.description as string | null,
    reason: row.reason as SupplementReason,
    reasonDetail: row.reason_detail as string | null,
    originalAmount: Number(row.original_amount) || 0,
    supplementAmount: Number(row.supplement_amount) || 0,
    approvedAmount: row.approved_amount != null ? Number(row.approved_amount) : null,
    status: row.status as SupplementStatus,
    submittedAt: row.submitted_at as string | null,
    reviewedAt: row.reviewed_at as string | null,
    reviewerName: row.reviewer_name as string | null,
    reviewerNotes: row.reviewer_notes as string | null,
    denialReason: row.denial_reason as string | null,
    photoIds: (row.photo_ids as string[]) || [],
    lineItemIds: (row.line_item_ids as string[]) || [],
    supportingDocs: (row.supporting_docs as { name: string; path: string; type: string }[]) || [],
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
    deletedAt: row.deleted_at as string | null,
  };
}

// ============================================================================
// HOOK: useTpaSupplements
// ============================================================================

export function useTpaSupplements(assignmentId: string) {
  const [supplements, setSupplements] = useState<TpaSupplementData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSupplements = useCallback(async () => {
    if (!assignmentId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('tpa_supplements')
        .select('*')
        .eq('tpa_assignment_id', assignmentId)
        .is('deleted_at', null)
        .order('supplement_number', { ascending: true });

      if (err) throw err;
      setSupplements((data || []).map(mapSupplement));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load supplements');
    } finally {
      setLoading(false);
    }
  }, [assignmentId]);

  useEffect(() => {
    fetchSupplements();
  }, [fetchSupplements]);

  // Real-time subscription
  useEffect(() => {
    if (!assignmentId) return;
    const supabase = getSupabase();
    const channel = supabase
      .channel(`supplements-${assignmentId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'tpa_supplements', filter: `tpa_assignment_id=eq.${assignmentId}` },
        () => fetchSupplements()
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [assignmentId, fetchSupplements]);

  // Create supplement
  const createSupplement = useCallback(async (input: CreateSupplementInput) => {
    try {
      const supabase = getSupabase();
      // Get next supplement number
      const nextNumber = supplements.length > 0
        ? Math.max(...supplements.map((s) => s.supplementNumber)) + 1
        : 1;

      const { data: { user } } = await supabase.auth.getUser();

      const { error: err } = await supabase.from('tpa_supplements').insert({
        tpa_assignment_id: input.tpaAssignmentId,
        created_by_user_id: user?.id,
        supplement_number: nextNumber,
        title: input.title,
        description: input.description || null,
        reason: input.reason,
        reason_detail: input.reasonDetail || null,
        original_amount: input.originalAmount || 0,
        supplement_amount: input.supplementAmount,
        photo_ids: input.photoIds || [],
        line_item_ids: input.lineItemIds || [],
        status: 'draft',
      });

      if (err) throw err;
      await fetchSupplements();
      return true;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to create supplement');
      return false;
    }
  }, [supplements, fetchSupplements]);

  // Update supplement
  const updateSupplement = useCallback(async (id: string, input: UpdateSupplementInput) => {
    try {
      const supabase = getSupabase();
      const updateData: Record<string, unknown> = {};
      if (input.title !== undefined) updateData.title = input.title;
      if (input.description !== undefined) updateData.description = input.description;
      if (input.reason !== undefined) updateData.reason = input.reason;
      if (input.reasonDetail !== undefined) updateData.reason_detail = input.reasonDetail;
      if (input.supplementAmount !== undefined) updateData.supplement_amount = input.supplementAmount;
      if (input.photoIds !== undefined) updateData.photo_ids = input.photoIds;
      if (input.lineItemIds !== undefined) updateData.line_item_ids = input.lineItemIds;
      if (input.supportingDocs !== undefined) updateData.supporting_docs = input.supportingDocs;

      const { error: err } = await supabase
        .from('tpa_supplements')
        .update(updateData)
        .eq('id', id);

      if (err) throw err;
      await fetchSupplements();
      return true;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to update supplement');
      return false;
    }
  }, [fetchSupplements]);

  // Submit supplement
  const submitSupplement = useCallback(async (id: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('tpa_supplements')
        .update({ status: 'submitted', submitted_at: new Date().toISOString() })
        .eq('id', id);

      if (err) throw err;
      await fetchSupplements();
      return true;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to submit supplement');
      return false;
    }
  }, [fetchSupplements]);

  // Review supplement (approve/deny)
  const reviewSupplement = useCallback(async (
    id: string,
    decision: 'approved' | 'partially_approved' | 'denied',
    reviewerName: string,
    notes?: string,
    approvedAmount?: number,
    denialReason?: string
  ) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('tpa_supplements')
        .update({
          status: decision,
          reviewed_at: new Date().toISOString(),
          reviewer_name: reviewerName,
          reviewer_notes: notes || null,
          approved_amount: decision === 'denied' ? 0 : (approvedAmount ?? null),
          denial_reason: decision === 'denied' ? (denialReason || null) : null,
        })
        .eq('id', id);

      if (err) throw err;
      await fetchSupplements();
      return true;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to review supplement');
      return false;
    }
  }, [fetchSupplements]);

  // Soft delete
  const deleteSupplement = useCallback(async (id: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('tpa_supplements')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);

      if (err) throw err;
      await fetchSupplements();
      return true;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to delete supplement');
      return false;
    }
  }, [fetchSupplements]);

  // Computed
  const totalRequested = supplements.reduce((s, sup) => s + sup.supplementAmount, 0);
  const totalApproved = supplements
    .filter((s) => s.status === 'approved' || s.status === 'partially_approved')
    .reduce((s, sup) => s + (sup.approvedAmount ?? sup.supplementAmount), 0);
  const pendingCount = supplements.filter((s) =>
    ['draft', 'submitted', 'under_review', 'resubmitted'].includes(s.status)
  ).length;

  return {
    supplements,
    loading,
    error,
    refetch: fetchSupplements,
    createSupplement,
    updateSupplement,
    submitSupplement,
    reviewSupplement,
    deleteSupplement,
    totalRequested,
    totalApproved,
    pendingCount,
  };
}

// ============================================================================
// CONSTANTS
// ============================================================================

export const SUPPLEMENT_REASON_LABELS: Record<SupplementReason, string> = {
  hidden_damage: 'Hidden Damage',
  scope_change: 'Scope Change',
  category_escalation: 'Category Escalation',
  additional_areas: 'Additional Areas',
  code_upgrade: 'Code Upgrade',
  emergency_services: 'Emergency Services',
  contents: 'Contents',
  additional_equipment: 'Additional Equipment',
  extended_drying: 'Extended Drying',
  mold_discovered: 'Mold Discovered',
  structural: 'Structural',
  other: 'Other',
};

export const SUPPLEMENT_STATUS_LABELS: Record<SupplementStatus, string> = {
  draft: 'Draft',
  submitted: 'Submitted',
  under_review: 'Under Review',
  approved: 'Approved',
  partially_approved: 'Partially Approved',
  denied: 'Denied',
  resubmitted: 'Resubmitted',
  withdrawn: 'Withdrawn',
};
