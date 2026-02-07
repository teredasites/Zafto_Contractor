'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapChangeOrder, type ChangeOrderData, type ChangeOrderItem } from './mappers';

export function useChangeOrders(jobId?: string) {
  const [orders, setOrders] = useState<ChangeOrderData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchOrders = useCallback(async () => {
    const supabase = getSupabase();
    let query = supabase.from('change_orders').select('*, jobs(title)').is('deleted_at', null).order('created_at', { ascending: false });
    if (jobId) query = query.eq('job_id', jobId);
    const { data } = await query;
    setOrders((data || []).map(mapChangeOrder));
    setLoading(false);
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
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    // Auto CO number
    const { data: lastCO } = await supabase.from('change_orders')
      .select('order_number').eq('job_id', data.jobId)
      .order('created_at', { ascending: false }).limit(1);

    let nextNum = 1;
    if (lastCO && lastCO.length > 0) {
      const match = (lastCO[0].order_number as string).match(/CO-(\d+)/);
      if (match) nextNum = parseInt(match[1], 10) + 1;
    }

    const totalAmount = data.items.reduce((sum, i) => sum + i.quantity * i.unitPrice, 0);

    await supabase.from('change_orders').insert({
      job_id: data.jobId, company_id: user.app_metadata?.company_id,
      created_by_user_id: user.id,
      order_number: `CO-${String(nextNum).padStart(3, '0')}`,
      title: data.title, description: data.description, reason: data.reason,
      amount: totalAmount, line_items: data.items, status: 'draft',
    });
    fetchOrders();
  };

  const submitForApproval = async (orderId: string) => {
    const supabase = getSupabase();
    await supabase.from('change_orders').update({ status: 'pending_approval' }).eq('id', orderId);
    fetchOrders();
  };

  return { orders, loading, createOrder, submitForApproval };
}
