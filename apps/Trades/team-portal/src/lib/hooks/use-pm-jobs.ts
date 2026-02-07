'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapJob, type JobData } from './mappers';

// Property maintenance jobs = jobs WHERE property_id IS NOT NULL
export function usePmJobs() {
  const [jobs, setJobs] = useState<JobData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchJobs = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const { data, error: err } = await supabase
        .from('jobs')
        .select('*')
        .contains('assigned_user_ids', [user.id])
        .not('property_id', 'is', null)
        .is('deleted_at', null)
        .order('scheduled_start', { ascending: true, nullsFirst: false });

      if (err) throw err;
      setJobs((data || []).map(mapJob));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load property jobs';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchJobs();
    const supabase = getSupabase();
    const channel = supabase.channel('team-pm-jobs')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'jobs' }, () => fetchJobs())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchJobs]);

  return { jobs, loading, error };
}

// Fetch property + unit + tenant info for a specific job
export interface JobPropertyContext {
  propertyName: string;
  propertyAddress: string;
  unitNumber: string | null;
  tenantName: string | null;
  tenantPhone: string | null;
  tenantEmail: string | null;
  maintenanceRequest: {
    id: string;
    title: string;
    description: string;
    category: string;
    urgency: string;
    status: string;
    photos: string[];
    createdAt: string;
  } | null;
  assets: {
    id: string;
    assetType: string;
    brand: string;
    model: string;
    condition: string;
    lastServiceDate: string | null;
  }[];
}

export function useJobPropertyContext(jobId: string | null, propertyId: string | null) {
  const [context, setContext] = useState<JobPropertyContext | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!jobId || !propertyId) { setLoading(false); return; }

    let ignore = false;

    async function fetchContext() {
      try {
        const supabase = getSupabase();

        // Parallel queries: property + maintenance request
        const [propertyRes, requestRes] = await Promise.all([
          supabase
            .from('properties')
            .select('name, address, city, state')
            .eq('id', propertyId)
            .single(),
          supabase
            .from('maintenance_requests')
            .select('id, title, description, category, urgency, status, photos, created_at, unit_id, units(unit_number), tenants(name, phone, email)')
            .eq('job_id', jobId)
            .limit(1)
            .maybeSingle(),
        ]);

        if (ignore) return;

        // Assets query needs unit_id from request, so it runs after
        const assetsRes = await supabase
          .from('property_assets')
          .select('id, asset_type, brand, model, condition, last_service_date')
          .eq('property_id', propertyId!)
          .limit(10);

        if (ignore) return;

        const property = propertyRes.data;
        const request = requestRes.data;
        const unit = request?.units as Record<string, unknown> | null;
        const tenant = request?.tenants as Record<string, unknown> | null;

        setContext({
          propertyName: (property?.name as string) || '',
          propertyAddress: [property?.address, property?.city, property?.state].filter(Boolean).join(', '),
          unitNumber: (unit?.unit_number as string) || null,
          tenantName: (tenant?.name as string) || null,
          tenantPhone: (tenant?.phone as string) || null,
          tenantEmail: (tenant?.email as string) || null,
          maintenanceRequest: request ? {
            id: request.id as string,
            title: (request.title as string) || '',
            description: (request.description as string) || '',
            category: (request.category as string) || '',
            urgency: (request.urgency as string) || 'normal',
            status: (request.status as string) || 'new',
            photos: (request.photos as string[]) || [],
            createdAt: (request.created_at as string) || '',
          } : null,
          assets: (assetsRes.data || []).map((a: Record<string, unknown>) => ({
            id: a.id as string,
            assetType: (a.asset_type as string) || '',
            brand: (a.brand as string) || '',
            model: (a.model as string) || '',
            condition: (a.condition as string) || '',
            lastServiceDate: (a.last_service_date as string) || null,
          })),
        });
      } catch {
        // Non-critical — job detail still works without property context
      } finally {
        if (!ignore) setLoading(false);
      }
    }

    fetchContext();
    return () => { ignore = true; };
  }, [jobId, propertyId]);

  return { context, loading };
}
