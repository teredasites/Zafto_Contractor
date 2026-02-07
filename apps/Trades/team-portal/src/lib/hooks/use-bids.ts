'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapBid, type BidData } from './mappers';

export function useBids() {
  const [bids, setBids] = useState<BidData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchBids = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const { data, error: err } = await supabase
        .from('bids')
        .select('*')
        .eq('created_by_user_id', user.id)
        .is('deleted_at', null)
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
    const channel = supabase.channel('team-bids')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bids' }, () => fetchBids())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchBids]);

  const createBid = async (data: { customerName: string; title: string; totalAmount: number; description?: string }) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const today = new Date().toISOString().split('T')[0].replace(/-/g, '');
      const { data: lastBid, error: lastBidErr } = await supabase.from('bids')
        .select('bid_number').ilike('bid_number', `BID-${today}-%`)
        .order('created_at', { ascending: false }).limit(1);

      if (lastBidErr) throw lastBidErr;

      let seq = 1;
      if (lastBid && lastBid.length > 0) {
        const match = (lastBid[0].bid_number as string).match(/-(\d+)$/);
        if (match) seq = parseInt(match[1], 10) + 1;
      }

      const { error: err } = await supabase.from('bids').insert({
        company_id: user.app_metadata?.company_id,
        created_by_user_id: user.id,
        bid_number: `BID-${today}-${String(seq).padStart(3, '0')}`,
        customer_name: data.customerName, title: data.title,
        total: data.totalAmount, scope_of_work: data.description || '',
        status: 'draft',
      });

      if (err) throw err;
      fetchBids();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to create bid';
      setError(msg);
      throw e;
    }
  };

  return { bids, loading, error, createBid };
}
