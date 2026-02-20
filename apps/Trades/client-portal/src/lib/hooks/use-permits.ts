'use client';

// L9: Client Permit Status — customer sees permit status for their projects
// Scoped by customer_id from auth profile.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '../supabase';
import { useAuth } from '@/components/auth-provider';

const supabase = getSupabase();

export interface ClientPermit {
  id: string;
  jobId: string;
  jobName: string;
  propertyAddress: string;
  permitType: string;
  permitNumber: string | null;
  status: string;
  issuedDate: string | null;
  expirationDate: string | null;
  inspectionsPassed: number;
  inspectionsTotal: number;
  lastInspectionDate: string | null;
  lastInspectionResult: string | null;
  notes: string | null;
}

export function useClientPermits() {
  const { profile } = useAuth();
  const [permits, setPermits] = useState<ClientPermit[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPermits = useCallback(async () => {
    if (!profile?.customerId) { setLoading(false); return; }

    try {
      setLoading(true);

      // Get customer's jobs first
      const { data: jobs, error: jobErr } = await supabase
        .from('jobs')
        .select('id, name, property_address')
        .eq('customer_id', profile.customerId)
        .is('deleted_at', null);

      if (jobErr) throw jobErr;
      if (!jobs?.length) { setPermits([]); setLoading(false); return; }

      const jobIds = jobs.map((j: { id: string }) => j.id);
      const jobMap = new Map<string, { id: string; name: string; property_address: string }>(
        jobs.map((j: { id: string; name: string; property_address: string }) => [j.id, j])
      );

      // Get permits for those jobs
      const { data: permitData, error: permitErr } = await supabase
        .from('permits')
        .select('*')
        .in('job_id', jobIds)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (permitErr) throw permitErr;

      // Get inspection counts per permit
      const permitIds = (permitData || []).map((p: { id: string }) => p.id);
      let inspectionMap = new Map<string, { passed: number; total: number; lastDate: string | null; lastResult: string | null }>();

      if (permitIds.length > 0) {
        const { data: inspections } = await supabase
          .from('permit_inspections')
          .select('permit_id, result, inspection_date')
          .in('permit_id', permitIds)
          .is('deleted_at', null)
          .order('inspection_date', { ascending: false });

        for (const insp of inspections || []) {
          const existing = inspectionMap.get(insp.permit_id);
          if (!existing) {
            inspectionMap.set(insp.permit_id, {
              passed: insp.result === 'passed' ? 1 : 0,
              total: 1,
              lastDate: insp.inspection_date,
              lastResult: insp.result,
            });
          } else {
            existing.total++;
            if (insp.result === 'passed') existing.passed++;
          }
        }
      }

      const mapped: ClientPermit[] = (permitData || []).map((p: Record<string, unknown>) => {
        const job = jobMap.get(p.job_id as string);
        const insp = inspectionMap.get(p.id as string);
        return {
          id: p.id as string,
          jobId: p.job_id as string,
          jobName: (job?.name || 'Unknown Job') as string,
          propertyAddress: (job?.property_address || '') as string,
          permitType: (p.permit_type || p.type || 'General') as string,
          permitNumber: p.permit_number as string | null,
          status: (p.status || 'pending') as string,
          issuedDate: p.issued_date as string | null,
          expirationDate: p.expiration_date as string | null,
          inspectionsPassed: insp?.passed || 0,
          inspectionsTotal: insp?.total || 0,
          lastInspectionDate: insp?.lastDate || null,
          lastInspectionResult: insp?.lastResult || null,
          notes: p.notes as string | null,
        };
      });

      setPermits(mapped);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load permits');
    } finally {
      setLoading(false);
    }
  }, [profile?.customerId]);

  useEffect(() => { fetchPermits(); }, [fetchPermits]);

  useEffect(() => {
    const channel = supabase
      .channel('client-permits-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'permits' }, () => fetchPermits())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchPermits]);

  return { permits, loading, error, refresh: fetchPermits };
}
