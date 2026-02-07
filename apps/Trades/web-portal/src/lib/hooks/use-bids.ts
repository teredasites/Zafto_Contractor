'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapBid } from './mappers';
import type { Bid } from '@/types';

export function useBids() {
  const [bids, setBids] = useState<Bid[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchBids = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('bids')
        .select('*')
        .order('created_at', { ascending: false });

      if (err) throw err;
      setBids((data || []).map(mapBid));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load bids';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchBids();

    const supabase = getSupabase();
    const channel = supabase
      .channel('bids-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bids' }, () => {
        fetchBids();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchBids]);

  const createBid = async (data: Partial<Bid>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Auto-generate bid number
    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const { count } = await supabase
      .from('bids')
      .select('*', { count: 'exact', head: true })
      .ilike('bid_number', `BID-${dateStr}-%`);

    const seq = String((count || 0) + 1).padStart(3, '0');
    const bidNumber = `BID-${dateStr}-${seq}`;

    const lineItemsJson = {
      options: data.options || [],
      addOns: data.addOns || [],
    };

    const { data: result, error: err } = await supabase
      .from('bids')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        customer_id: data.customerId || null,
        bid_number: bidNumber,
        title: data.title || '',
        customer_name: data.customerName || '',
        customer_email: data.customerEmail || null,
        customer_address: data.customerAddress?.street || null,
        line_items: lineItemsJson,
        scope_of_work: data.scopeOfWork || null,
        terms: data.termsAndConditions || null,
        subtotal: data.subtotal || 0,
        tax_rate: data.taxRate || 0,
        tax_amount: data.tax || 0,
        total: data.total || 0,
        valid_until: data.validUntil ? new Date(data.validUntil).toISOString() : null,
        status: 'draft',
        notes: null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateBid = async (id: string, data: Partial<Bid>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.title !== undefined) updateData.title = data.title;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.options !== undefined || data.addOns !== undefined) {
      updateData.line_items = { options: data.options || [], addOns: data.addOns || [] };
    }
    if (data.subtotal !== undefined) updateData.subtotal = data.subtotal;
    if (data.taxRate !== undefined) updateData.tax_rate = data.taxRate;
    if (data.tax !== undefined) updateData.tax_amount = data.tax;
    if (data.total !== undefined) updateData.total = data.total;
    if (data.scopeOfWork !== undefined) updateData.scope_of_work = data.scopeOfWork;
    if (data.termsAndConditions !== undefined) updateData.terms = data.termsAndConditions;
    if (data.validUntil !== undefined) {
      updateData.valid_until = data.validUntil ? new Date(data.validUntil).toISOString() : null;
    }

    const { error: err } = await supabase.from('bids').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const sendBid = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('bids')
      .update({ status: 'sent', sent_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  const acceptBid = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('bids')
      .update({ status: 'accepted', accepted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  const rejectBid = async (id: string, reason?: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('bids')
      .update({
        status: 'rejected',
        rejected_at: new Date().toISOString(),
        rejection_reason: reason || null,
      })
      .eq('id', id);
    if (err) throw err;
  };

  const convertToJob = async (bidId: string): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Fetch bid data
    const { data: bid, error: fetchErr } = await supabase.from('bids').select('*').eq('id', bidId).single();
    if (fetchErr) throw fetchErr;

    // Create job from bid
    const { data: job, error: jobErr } = await supabase
      .from('jobs')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        customer_id: bid.customer_id,
        title: bid.title || 'Job from bid',
        description: bid.scope_of_work || null,
        status: 'scheduled',
        priority: 'normal',
        address: bid.customer_address || '',
        customer_name: bid.customer_name || '',
        customer_email: bid.customer_email || null,
        customer_phone: null,
        estimated_amount: bid.total || 0,
        quote_id: bidId,
        tags: [],
      })
      .select('id')
      .single();

    if (jobErr) throw jobErr;

    // Update bid to converted
    await supabase
      .from('bids')
      .update({ status: 'accepted', job_id: job.id })
      .eq('id', bidId);

    return job.id;
  };

  const deleteBid = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('bids')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  return {
    bids,
    loading,
    error,
    createBid,
    updateBid,
    sendBid,
    acceptBid,
    rejectBid,
    convertToJob,
    deleteBid,
    refetch: fetchBids,
  };
}

export function useBid(id: string | undefined) {
  const [bid, setBid] = useState<Bid | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) {
      setLoading(false);
      return;
    }

    const fetchBid = async () => {
      try {
        setLoading(true);
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase.from('bids').select('*').eq('id', id).single();

        if (err) throw err;
        setBid(data ? mapBid(data) : null);
      } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Bid not found';
        setError(msg);
      } finally {
        setLoading(false);
      }
    };

    fetchBid();
  }, [id]);

  return { bid, loading, error };
}
