'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface TimeOffRequest {
  id: string;
  requestType: string;
  startDate: string;
  endDate: string;
  notes: string;
  status: 'pending' | 'approved' | 'denied' | 'cancelled';
  reviewNotes: string | null;
  createdAt: string;
}

export function useTimeOff() {
  const [requests, setRequests] = useState<TimeOffRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchRequests = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const { data, error: err } = await supabase
        .from('time_off_requests')
        .select('*')
        .eq('user_id', user.id)
        .is('deleted_at', null)
        .order('start_date', { ascending: false });

      if (err) throw err;

      setRequests((data || []).map((r: Record<string, unknown>) => ({
        id: r.id as string,
        requestType: r.request_type as string,
        startDate: r.start_date as string,
        endDate: r.end_date as string,
        notes: (r.notes as string) || '',
        status: r.status as TimeOffRequest['status'],
        reviewNotes: (r.review_notes as string) || null,
        createdAt: r.created_at as string,
      })));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load requests');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchRequests();
    const supabase = getSupabase();
    const channel = supabase.channel('time-off')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'time_off_requests' }, () => fetchRequests())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchRequests]);

  const submitRequest = async (data: { requestType: string; startDate: string; endDate: string; notes: string }) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const companyId = user.app_metadata?.company_id;
      const { error: err } = await supabase.from('time_off_requests').insert({
        company_id: companyId,
        user_id: user.id,
        request_type: data.requestType,
        start_date: data.startDate,
        end_date: data.endDate,
        notes: data.notes || null,
        status: 'pending',
      });

      if (err) throw err;
      fetchRequests();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to submit request';
      setError(msg);
      throw e;
    }
  };

  const cancelRequest = async (id: string) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('time_off_requests')
        .update({ status: 'cancelled' })
        .eq('id', id);

      if (err) throw err;
      fetchRequests();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to cancel request');
    }
  };

  return { requests, loading, error, submitRequest, cancelRequest };
}
