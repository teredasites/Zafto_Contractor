'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface TpaJobStatus {
  assignmentId: string;
  jobId: string;
  programName: string;
  claimNumber: string | null;
  status: string;
  lossType: string | null;
  lossDate: string | null;
  // SLA
  slaDeadline: string | null;
  slaStatus: 'on_track' | 'approaching' | 'overdue';
  // Documentation
  docItemsTotal: number;
  docItemsCompleted: number;
  docCompliancePercent: number;
}

// ============================================================================
// HOOK
// ============================================================================

export function useTpaStatus(jobId: string) {
  const [status, setStatus] = useState<TpaJobStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchStatus = useCallback(async () => {
    if (!jobId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();

      // Get TPA assignment for this job
      const { data: assignment, error: aErr } = await supabase
        .from('tpa_assignments')
        .select('id, status, claim_number, loss_type, loss_date, sla_deadline, tpa_programs(name)')
        .eq('job_id', jobId)
        .is('deleted_at', null)
        .limit(1)
        .maybeSingle();

      if (aErr) throw aErr;
      if (!assignment) {
        setStatus(null);
        return;
      }

      // Calculate SLA status
      let slaStatus: 'on_track' | 'approaching' | 'overdue' = 'on_track';
      if (assignment.sla_deadline) {
        const deadline = new Date(assignment.sla_deadline);
        const now = new Date();
        const hoursLeft = (deadline.getTime() - now.getTime()) / (1000 * 60 * 60);
        if (hoursLeft < 0) slaStatus = 'overdue';
        else if (hoursLeft < 24) slaStatus = 'approaching';
      }

      // Get documentation progress
      const { data: docProgress } = await supabase
        .from('job_doc_progress')
        .select('id, completed_at')
        .eq('job_id', jobId);

      const docs = docProgress || [];
      const total = docs.length;
      const completed = docs.filter((d: Record<string, unknown>) => d.completed_at != null).length;

      const program = assignment.tpa_programs as Record<string, unknown> | null;

      setStatus({
        assignmentId: assignment.id,
        jobId,
        programName: (program?.name as string) || 'Insurance Program',
        claimNumber: assignment.claim_number,
        status: assignment.status,
        lossType: assignment.loss_type,
        lossDate: assignment.loss_date,
        slaDeadline: assignment.sla_deadline,
        slaStatus,
        docItemsTotal: total,
        docItemsCompleted: completed,
        docCompliancePercent: total > 0 ? Math.round((completed / total) * 100) : 0,
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load TPA status');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetchStatus();
  }, [fetchStatus]);

  return { status, loading, error, refetch: fetchStatus };
}
