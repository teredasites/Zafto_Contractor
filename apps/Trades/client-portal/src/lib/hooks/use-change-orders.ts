'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import { mapChangeOrder, type ChangeOrderData } from './mappers';

export function useChangeOrders() {
  const { profile } = useAuth();
  const [orders, setOrders] = useState<ChangeOrderData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchOrders = useCallback(async () => {
    if (!profile?.customerId) { setLoading(false); return; }
    const supabase = getSupabase();

    // Get jobs for this customer, then change orders for those jobs
    const { data: jobs, error: jobsError } = await supabase
      .from('jobs')
      .select('id')
      .eq('customer_id', profile.customerId)
      .is('deleted_at', null);

    if (jobsError) {
      setError(jobsError.message);
      setLoading(false);
      return;
    }

    if (!jobs || jobs.length === 0) {
      setOrders([]);
      setLoading(false);
      return;
    }

    const jobIds = jobs.map((j: { id: string }) => j.id);
    const { data, error: fetchError } = await supabase
      .from('change_orders')
      .select('*, jobs(title)')
      .in('job_id', jobIds)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    if (fetchError) {
      setError(fetchError.message);
    } else {
      setOrders((data || []).map(mapChangeOrder));
    }
    setLoading(false);
  }, [profile?.customerId]);

  useEffect(() => {
    fetchOrders();
  }, [fetchOrders]);

  // Verify change order belongs to a job owned by this customer
  const verifyOwnership = async (orderId: string): Promise<boolean> => {
    if (!profile?.customerId) return false;
    const supabase = getSupabase();

    // Fetch the change order with its parent job's customer_id
    const { data, error: fetchError } = await supabase
      .from('change_orders')
      .select('id, job_id, jobs(customer_id)')
      .eq('id', orderId)
      .is('deleted_at', null)
      .single();

    if (fetchError || !data) return false;

    const job = data.jobs as unknown as { customer_id: string } | null;
    return job?.customer_id === profile.customerId;
  };

  const approveOrder = async (orderId: string) => {
    if (!profile?.customerId) {
      setError('Not authenticated');
      return;
    }

    const isOwner = await verifyOwnership(orderId);
    if (!isOwner) {
      setError('Change order not found or access denied');
      return;
    }

    const supabase = getSupabase();
    const { error: updateError } = await supabase
      .from('change_orders')
      .update({
        status: 'approved',
        approved_at: new Date().toISOString(),
      })
      .eq('id', orderId);

    if (updateError) {
      setError(updateError.message);
      return;
    }
    fetchOrders();
  };

  const rejectOrder = async (orderId: string) => {
    if (!profile?.customerId) {
      setError('Not authenticated');
      return;
    }

    const isOwner = await verifyOwnership(orderId);
    if (!isOwner) {
      setError('Change order not found or access denied');
      return;
    }

    const supabase = getSupabase();
    const { error: updateError } = await supabase
      .from('change_orders')
      .update({
        status: 'rejected',
      })
      .eq('id', orderId);

    if (updateError) {
      setError(updateError.message);
      return;
    }
    fetchOrders();
  };

  return { orders, loading, error, approveOrder, rejectOrder };
}
