'use client';

import { useState, useEffect, useCallback } from 'react';
import { createClient } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface TpaJobData {
  id: string;
  jobId: string;
  jobTitle: string;
  jobAddress: string;
  tpaProgramName: string;
  claimNumber: string | null;
  insuredName: string | null;
  lossType: string | null;
  status: string;
  // SLA data
  slaFirstContactDeadline: string | null;
  slaOnsiteDeadline: string | null;
  slaEstimateDeadline: string | null;
  slaCompletionDeadline: string | null;
  slaDeadline: string | null;
  // Timestamps
  createdAt: string;
  acceptedAt: string | null;
  contactedAt: string | null;
}

export interface SlaStatus {
  label: string;
  color: 'green' | 'amber' | 'red' | 'zinc';
  hoursRemaining: number | null;
  isOverdue: boolean;
}

// ============================================================================
// HELPERS
// ============================================================================

export function getSlaCountdown(deadline: string | null): SlaStatus {
  if (!deadline) return { label: 'No SLA', color: 'zinc', hoursRemaining: null, isOverdue: false };

  const now = new Date();
  const dl = new Date(deadline);
  const diffMs = dl.getTime() - now.getTime();
  const hoursRemaining = diffMs / (1000 * 60 * 60);

  if (hoursRemaining < 0) {
    return { label: 'OVERDUE', color: 'red', hoursRemaining, isOverdue: true };
  }
  if (hoursRemaining < 4) {
    const mins = Math.round(hoursRemaining * 60);
    return { label: `${mins}m left`, color: 'red', hoursRemaining, isOverdue: false };
  }
  if (hoursRemaining < 24) {
    return { label: `${Math.round(hoursRemaining)}h left`, color: 'amber', hoursRemaining, isOverdue: false };
  }
  const days = Math.round(hoursRemaining / 24);
  return { label: `${days}d left`, color: 'green', hoursRemaining, isOverdue: false };
}

// ============================================================================
// HOOK: useTpaJobs — TPA-assigned jobs for the current technician
// ============================================================================

export function useTpaJobs() {
  const [jobs, setJobs] = useState<TpaJobData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchJobs = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = createClient();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      // Get TPA assignments for jobs assigned to this user
      const { data, error: err } = await supabase
        .from('tpa_assignments')
        .select(`
          id, status, claim_number, insured_name, loss_type,
          sla_first_contact_deadline, sla_onsite_deadline,
          sla_estimate_deadline, sla_completion_deadline, sla_deadline,
          created_at, accepted_at, contacted_at,
          job_id,
          jobs!inner(id, title, address),
          tpa_programs(name)
        `)
        .is('deleted_at', null)
        .not('status', 'in', '("completed","paid","declined","cancelled")')
        .order('sla_deadline', { ascending: true, nullsFirst: false });

      if (err) throw err;

      const mapped: TpaJobData[] = (data || []).map((row: Record<string, unknown>) => {
        const job = row.jobs as Record<string, unknown>;
        const program = row.tpa_programs as Record<string, unknown> | null;
        return {
          id: row.id as string,
          jobId: row.job_id as string,
          jobTitle: (job?.title as string) || '',
          jobAddress: (job?.address as string) || '',
          tpaProgramName: (program?.name as string) || 'Unknown',
          claimNumber: row.claim_number as string | null,
          insuredName: row.insured_name as string | null,
          lossType: row.loss_type as string | null,
          status: row.status as string,
          slaFirstContactDeadline: row.sla_first_contact_deadline as string | null,
          slaOnsiteDeadline: row.sla_onsite_deadline as string | null,
          slaEstimateDeadline: row.sla_estimate_deadline as string | null,
          slaCompletionDeadline: row.sla_completion_deadline as string | null,
          slaDeadline: row.sla_deadline as string | null,
          createdAt: row.created_at as string,
          acceptedAt: row.accepted_at as string | null,
          contactedAt: row.contacted_at as string | null,
        };
      });

      setJobs(mapped);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load TPA jobs');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchJobs();
  }, [fetchJobs]);

  return { jobs, loading, error, refetch: fetchJobs };
}
