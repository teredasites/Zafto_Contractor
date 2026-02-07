'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import { mapChangeOrder, type ChangeOrderData } from './mappers';

export function useChangeOrders() {
  const { profile } = useAuth();
  const [orders, setOrders] = useState<ChangeOrderData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchOrders = useCallback(async () => {
    if (!profile?.customerId) { setLoading(false); return; }
    const supabase = getSupabase();

    // Get jobs for this customer, then change orders for those jobs
    const { data: jobs } = await supabase
      .from('jobs')
      .select('id')
      .eq('customer_id', profile.customerId);

    if (!jobs || jobs.length === 0) {
      setOrders([]);
      setLoading(false);
      return;
    }

    const jobIds = jobs.map((j: { id: string }) => j.id);
    const { data } = await supabase
      .from('change_orders')
      .select('*, jobs(title)')
      .in('job_id', jobIds)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    setOrders((data || []).map(mapChangeOrder));
    setLoading(false);
  }, [profile?.customerId]);

  useEffect(() => {
    fetchOrders();
  }, [fetchOrders]);

  const approveOrder = async (orderId: string) => {
    const supabase = getSupabase();
    await supabase.from('change_orders').update({
      status: 'approved',
      approved_at: new Date().toISOString(),
    }).eq('id', orderId);
    fetchOrders();
  };

  const rejectOrder = async (orderId: string) => {
    const supabase = getSupabase();
    await supabase.from('change_orders').update({
      status: 'rejected',
    }).eq('id', orderId);
    fetchOrders();
  };

  return { orders, loading, approveOrder, rejectOrder };
}
