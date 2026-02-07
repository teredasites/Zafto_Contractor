'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapBid, type BidData } from './mappers';

export function useBids() {
  const [bids, setBids] = useState<BidData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchBids = useCallback(async () => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setLoading(false); return; }

    const { data } = await supabase
      .from('bids')
      .select('*')
      .eq('created_by_user_id', user.id)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    setBids((data || []).map(mapBid));
    setLoading(false);
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
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const today = new Date().toISOString().split('T')[0].replace(/-/g, '');
    const { data: lastBid } = await supabase.from('bids')
      .select('bid_number').ilike('bid_number', `BID-${today}-%`)
      .order('created_at', { ascending: false }).limit(1);

    let seq = 1;
    if (lastBid && lastBid.length > 0) {
      const match = (lastBid[0].bid_number as string).match(/-(\d+)$/);
      if (match) seq = parseInt(match[1], 10) + 1;
    }

    await supabase.from('bids').insert({
      company_id: user.app_metadata?.company_id,
      created_by_user_id: user.id,
      bid_number: `BID-${today}-${String(seq).padStart(3, '0')}`,
      customer_name: data.customerName, title: data.title,
      total_amount: data.totalAmount, description: data.description || '',
      status: 'draft',
    });
    fetchBids();
  };

  return { bids, loading, createBid };
}
