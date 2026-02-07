'use client';

import { useState, useEffect } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// Homeowner-friendly claim status
export type ClaimStatus =
  | 'new' | 'scope_requested' | 'scope_submitted' | 'estimate_pending'
  | 'estimate_approved' | 'supplement_submitted' | 'supplement_approved'
  | 'work_in_progress' | 'work_complete' | 'final_inspection'
  | 'settled' | 'closed' | 'denied';

export const CLAIM_STATUS_LABELS: Record<ClaimStatus, string> = {
  new: 'Claim Filed',
  scope_requested: 'Scope Review',
  scope_submitted: 'Scope Submitted',
  estimate_pending: 'Estimate Under Review',
  estimate_approved: 'Estimate Approved',
  supplement_submitted: 'Additional Work Submitted',
  supplement_approved: 'Additional Work Approved',
  work_in_progress: 'Restoration In Progress',
  work_complete: 'Work Complete',
  final_inspection: 'Final Inspection',
  settled: 'Claim Settled',
  closed: 'Claim Closed',
  denied: 'Claim Denied',
};

export const CLAIM_STATUS_DESCRIPTIONS: Record<ClaimStatus, string> = {
  new: 'Your insurance claim has been filed. We are coordinating with your insurance company.',
  scope_requested: 'The insurance company has requested a scope of work.',
  scope_submitted: 'We have submitted the scope of work to your insurance company for review.',
  estimate_pending: 'Your estimate is being reviewed by the insurance company.',
  estimate_approved: 'The insurance company has approved the estimate. Work will begin soon.',
  supplement_submitted: 'Additional work was discovered and submitted for approval.',
  supplement_approved: 'The additional work has been approved.',
  work_in_progress: 'Restoration work is actively underway at your property.',
  work_complete: 'All restoration work has been completed. Awaiting final inspection.',
  final_inspection: 'A final inspection is being scheduled to verify all work.',
  settled: 'Your claim has been settled. All work is complete and verified.',
  closed: 'Your claim is closed.',
  denied: 'Your claim was denied by the insurance company. Please contact us for next steps.',
};

// Timeline steps in order
export const CLAIM_TIMELINE_STEPS: { status: ClaimStatus; label: string }[] = [
  { status: 'new', label: 'Filed' },
  { status: 'estimate_approved', label: 'Approved' },
  { status: 'work_in_progress', label: 'Work Started' },
  { status: 'work_complete', label: 'Work Complete' },
  { status: 'final_inspection', label: 'Inspection' },
  { status: 'settled', label: 'Settled' },
];

// Status ordering for timeline progress
const STATUS_ORDER: ClaimStatus[] = [
  'new', 'scope_requested', 'scope_submitted', 'estimate_pending',
  'estimate_approved', 'supplement_submitted', 'supplement_approved',
  'work_in_progress', 'work_complete', 'final_inspection', 'settled', 'closed',
];

export function getStatusIndex(status: ClaimStatus): number {
  return STATUS_ORDER.indexOf(status);
}

export interface ClaimSummary {
  id: string;
  jobId: string;
  insuranceCompany: string;
  claimNumber: string;
  dateOfLoss: string;
  claimStatus: ClaimStatus;
  deductible: number;
  workStartedAt?: string;
  workCompletedAt?: string;
  settledAt?: string;
}

export function useProjectClaim(jobId: string | null) {
  const { profile } = useAuth();
  const [claim, setClaim] = useState<ClaimSummary | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!jobId || !profile?.customerId) {
      setLoading(false);
      return;
    }

    async function fetch() {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('insurance_claims')
        .select('id, job_id, insurance_company, claim_number, date_of_loss, claim_status, deductible, work_started_at, work_completed_at, settled_at')
        .eq('job_id', jobId)
        .is('deleted_at', null)
        .maybeSingle();

      if (data) {
        setClaim({
          id: data.id,
          jobId: data.job_id,
          insuranceCompany: data.insurance_company || '',
          claimNumber: data.claim_number || '',
          dateOfLoss: data.date_of_loss || '',
          claimStatus: (data.claim_status as ClaimStatus) || 'new',
          deductible: Number(data.deductible) || 0,
          workStartedAt: data.work_started_at || undefined,
          workCompletedAt: data.work_completed_at || undefined,
          settledAt: data.settled_at || undefined,
        });
      }
      setLoading(false);
    }

    fetch();

    const supabase = getSupabase();
    const channel = supabase.channel(`client-claim-${jobId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'insurance_claims' }, () => {
        fetch();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [jobId, profile?.customerId]);

  return { claim, loading };
}
