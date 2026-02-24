'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapChangeOrder } from './mappers';
import type { ChangeOrderData } from './mappers';

export function useChangeOrders() {
  const [changeOrders, setChangeOrders] = useState<ChangeOrderData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchChangeOrders = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('change_orders')
        .select('*, jobs(title, customer_name)')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setChangeOrders((data || []).map(mapChangeOrder));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load change orders';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchChangeOrders();

    const supabase = getSupabase();
    const channel = supabase
      .channel('change-orders-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'change_orders' }, () => {
        fetchChangeOrders();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchChangeOrders]);

  const createChangeOrder = async (input: {
    jobId: string;
    title: string;
    description: string;
    reason?: string;
    items?: { description: string; quantity: number; unitPrice: number; total: number }[];
    amount: number;
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Auto-number: query last CO for this company
    const { data: lastCO } = await supabase
      .from('change_orders')
      .select('change_order_number')
      .eq('company_id', companyId)
      .order('created_at', { ascending: false })
      .limit(1);

    let nextNum = 1;
    if (lastCO && lastCO.length > 0) {
      const match = (lastCO[0].change_order_number as string).match(/(\d+)$/);
      if (match) nextNum = parseInt(match[1], 10) + 1;
    }
    const coNumber = `CO-${new Date().getFullYear()}-${String(nextNum).padStart(3, '0')}`;

    const lineItems = (input.items || []).map((item) => ({
      description: item.description,
      quantity: item.quantity,
      unit_price: item.unitPrice,
      total: item.total,
    }));

    const { data: result, error: err } = await supabase
      .from('change_orders')
      .insert({
        company_id: companyId,
        job_id: input.jobId,
        created_by_user_id: user.id,
        change_order_number: coNumber,
        title: input.title,
        description: input.description,
        reason: input.reason || null,
        line_items: lineItems,
        amount: input.amount,
        status: 'draft',
        notes: input.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateChangeOrderStatus = async (id: string, status: string, approvedByName?: string) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = { status };
    if (status === 'approved' && approvedByName) {
      updateData.approved_by_name = approvedByName;
      updateData.approved_at = new Date().toISOString();
    }
    const { error: err } = await supabase.from('change_orders').update(updateData).eq('id', id);
    if (err) throw err;

    // DB trigger fn_apply_change_order_to_job handles updating job.estimated_amount
    // on approval. Refetch to reflect updated data.
    fetchChangeOrders();
  };

  return { changeOrders, loading, error, createChangeOrder, updateChangeOrderStatus, refetch: fetchChangeOrders };
}
