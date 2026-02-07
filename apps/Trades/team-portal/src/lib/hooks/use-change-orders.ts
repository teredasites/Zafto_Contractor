'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapChangeOrder, type ChangeOrderData, type ChangeOrderItem } from './mappers';

export function useChangeOrders(jobId?: string) {
  const [orders, setOrders] = useState<ChangeOrderData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchOrders = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      let query = supabase.from('change_orders').select('*, jobs(title)').order('created_at', { ascending: false });
      if (jobId) query = query.eq('job_id', jobId);
      const { data, error: err } = await query;

      if (err) throw err;
      setOrders((data || []).map(mapChangeOrder));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load change orders';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetchOrders();
    const supabase = getSupabase();
    const channel = supabase.channel('team-co')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'change_orders' }, () => fetchOrders())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchOrders]);

  const createOrder = async (data: { jobId: string; title: string; description: string; reason: string; items: ChangeOrderItem[] }) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      // Auto CO number
      const { data: lastCO, error: lastCOErr } = await supabase.from('change_orders')
        .select('change_order_number').eq('job_id', data.jobId)
        .order('created_at', { ascending: false }).limit(1);

      if (lastCOErr) throw lastCOErr;

      let nextNum = 1;
      if (lastCO && lastCO.length > 0) {
        const match = (lastCO[0].change_order_number as string).match(/CO-(\d+)/);
        if (match) nextNum = parseInt(match[1], 10) + 1;
      }

      const totalAmount = data.items.reduce((sum, i) => sum + i.quantity * i.unitPrice, 0);

      const { error: err } = await supabase.from('change_orders').insert({
        job_id: data.jobId, company_id: user.app_metadata?.company_id,
        created_by_user_id: user.id,
        change_order_number: `CO-${String(nextNum).padStart(3, '0')}`,
        title: data.title, description: data.description, reason: data.reason,
        amount: totalAmount, line_items: data.items, status: 'draft',
      });

      if (err) throw err;
      fetchOrders();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to create change order';
      setError(msg);
      throw e;
    }
  };

  const submitForApproval = async (orderId: string) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { error: err } = await supabase.from('change_orders').update({ status: 'pending_approval' }).eq('id', orderId);

      if (err) throw err;
      fetchOrders();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to submit for approval';
      setError(msg);
      throw e;
    }
  };

  return { orders, loading, error, createOrder, submitForApproval };
}
