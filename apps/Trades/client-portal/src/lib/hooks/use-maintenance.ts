'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import { useTenant } from './use-tenant';
import {
  mapMaintenanceRequest, mapWorkOrderAction,
  type MaintenanceRequestData, type MaintenanceUrgency, type MaintenanceCategory,
  type WorkOrderActionData,
} from './tenant-mappers';

export function useMaintenanceRequests() {
  const { user } = useAuth();
  const { tenant, lease } = useTenant();
  const [requests, setRequests] = useState<MaintenanceRequestData[]>([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const fetchRequests = useCallback(async () => {
    if (!user || !tenant) { setLoading(false); return; }
    const supabase = getSupabase();

    // RLS maint_req_tenant_select filters by tenant's auth_user_id
    const { data } = await supabase
      .from('maintenance_requests')
      .select('*')
      .eq('tenant_id', tenant.id)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    setRequests((data || []).map(mapMaintenanceRequest));
    setLoading(false);
  }, [user, tenant]);

  useEffect(() => {
    fetchRequests();
    if (!user || !tenant) return;

    const supabase = getSupabase();
    const channel = supabase.channel('tenant-maintenance')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'maintenance_requests' }, () => fetchRequests())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchRequests, user, tenant]);

  const submitRequest = useCallback(async (input: {
    title: string;
    description: string;
    urgency: MaintenanceUrgency;
    category: MaintenanceCategory | null;
    preferredTimes: string[] | null;
  }) => {
    if (!tenant || !lease) throw new Error('No active tenant/lease');
    setSubmitting(true);

    const supabase = getSupabase();

    const { data, error } = await supabase
      .from('maintenance_requests')
      .insert({
        company_id: (await supabase.from('tenants').select('company_id').eq('id', tenant.id).single()).data?.company_id,
        property_id: lease.propertyId,
        unit_id: lease.unitId,
        tenant_id: tenant.id,
        title: input.title,
        description: input.description,
        urgency: input.urgency,
        category: input.category,
        preferred_times: input.preferredTimes,
        status: 'submitted',
      })
      .select()
      .single();

    setSubmitting(false);
    if (error) throw error;
    await fetchRequests();
    return data?.id as string;
  }, [tenant, lease, fetchRequests]);

  const activeCount = requests.filter(r =>
    r.status !== 'completed' && r.status !== 'cancelled'
  ).length;

  return { requests, activeCount, loading, submitting, submitRequest, refresh: fetchRequests };
}

export function useMaintenanceRequest(id: string) {
  const { user } = useAuth();
  const [request, setRequest] = useState<MaintenanceRequestData | null>(null);
  const [actions, setActions] = useState<WorkOrderActionData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetch() {
      if (!user) { setLoading(false); return; }
      const supabase = getSupabase();

      const { data: reqData } = await supabase
        .from('maintenance_requests')
        .select('*')
        .eq('id', id)
        .is('deleted_at', null)
        .single();

      if (reqData) {
        setRequest(mapMaintenanceRequest(reqData));

        // Get work order actions if a job is linked
        if (reqData.job_id) {
          const { data: actionsData } = await supabase
            .from('work_order_actions')
            .select('*')
            .eq('maintenance_request_id', id)
            .is('deleted_at', null)
            .order('created_at', { ascending: true });

          setActions((actionsData || []).map(mapWorkOrderAction));
        }
      }
      setLoading(false);
    }
    fetch();

    const supabase = getSupabase();
    const channel = supabase.channel(`maint-detail-${id}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'maintenance_requests', filter: `id=eq.${id}` }, () => fetch())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [id, user]);

  const submitRating = useCallback(async (rating: number, feedback: string) => {
    const supabase = getSupabase();
    await supabase
      .from('maintenance_requests')
      .update({ tenant_rating: rating, tenant_feedback: feedback })
      .eq('id', id);
  }, [id]);

  return { request, actions, loading, submitRating };
}
