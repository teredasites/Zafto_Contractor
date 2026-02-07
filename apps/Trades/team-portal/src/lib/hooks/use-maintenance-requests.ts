'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapMaintenanceRequest, type MaintenanceRequestData, type MaintenanceRequestStatus } from './mappers';

export function useMaintenanceRequests() {
  const [requests, setRequests] = useState<MaintenanceRequestData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchRequests = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const { data, error: err } = await supabase
        .from('maintenance_requests')
        .select('*, properties(name), units(unit_number), tenants(name, phone, email)')
        .contains('assigned_user_ids', [user.id])
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setRequests((data || []).map(mapMaintenanceRequest));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load maintenance requests';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchRequests();
    const supabase = getSupabase();
    const channel = supabase.channel('team-maintenance-requests')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'maintenance_requests' }, () => fetchRequests())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchRequests]);

  return { requests, loading, error, refetch: fetchRequests };
}

export async function updateRequestStatus(requestId: string, status: MaintenanceRequestStatus): Promise<void> {
  const supabase = getSupabase();
  const updates: Record<string, unknown> = { status };
  if (status === 'completed') {
    updates.completed_at = new Date().toISOString();
  }
  const { error } = await supabase
    .from('maintenance_requests')
    .update(updates)
    .eq('id', requestId);
  if (error) throw error;
}
