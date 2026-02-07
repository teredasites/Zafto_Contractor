'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import { mapBid, type BidData } from './mappers';

export function useBids() {
  const { profile } = useAuth();
  const [bids, setBids] = useState<BidData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchBids = useCallback(async () => {
    if (!profile?.customerId) { setLoading(false); return; }
    const supabase = getSupabase();

    const { data } = await supabase
      .from('bids')
      .select('*')
      .eq('customer_id', profile.customerId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    setBids((data || []).map(mapBid));
    setLoading(false);
  }, [profile?.customerId]);

  useEffect(() => {
    fetchBids();
    if (!profile?.customerId) return;

    const supabase = getSupabase();
    const channel = supabase.channel('client-bids')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bids' }, () => fetchBids())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchBids, profile?.customerId]);

  const acceptBid = async (bidId: string) => {
    const supabase = getSupabase();
    await supabase.from('bids').update({
      status: 'accepted',
      accepted_at: new Date().toISOString(),
    }).eq('id', bidId);
    fetchBids();
  };

  const rejectBid = async (bidId: string) => {
    const supabase = getSupabase();
    await supabase.from('bids').update({
      status: 'rejected',
      rejected_at: new Date().toISOString(),
    }).eq('id', bidId);
    fetchBids();
  };

  return { bids, loading, acceptBid, rejectBid };
}
