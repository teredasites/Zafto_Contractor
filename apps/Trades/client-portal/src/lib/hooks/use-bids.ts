'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import { mapBid, type BidData } from './mappers';

export function useBids() {
  const { profile } = useAuth();
  const [bids, setBids] = useState<BidData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchBids = useCallback(async () => {
    if (!profile?.customerId) { setLoading(false); return; }
    const supabase = getSupabase();

    const { data, error: fetchError } = await supabase
      .from('bids')
      .select('*')
      .eq('customer_id', profile.customerId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    if (fetchError) {
      setError(fetchError.message);
    } else {
      setBids((data || []).map(mapBid));
    }
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
    if (!profile?.customerId) {
      setError('Not authenticated');
      return;
    }
    const supabase = getSupabase();
    // Ownership check: only update if bid belongs to this customer
    const { error: updateError, count } = await supabase
      .from('bids')
      .update({
        status: 'accepted',
        accepted_at: new Date().toISOString(),
      })
      .eq('id', bidId)
      .eq('customer_id', profile.customerId);

    if (updateError) {
      setError(updateError.message);
      return;
    }
    if (count === 0) {
      setError('Bid not found or access denied');
      return;
    }
    fetchBids();
  };

  const rejectBid = async (bidId: string) => {
    if (!profile?.customerId) {
      setError('Not authenticated');
      return;
    }
    const supabase = getSupabase();
    // Ownership check: only update if bid belongs to this customer
    const { error: updateError, count } = await supabase
      .from('bids')
      .update({
        status: 'rejected',
        rejected_at: new Date().toISOString(),
      })
      .eq('id', bidId)
      .eq('customer_id', profile.customerId);

    if (updateError) {
      setError(updateError.message);
      return;
    }
    if (count === 0) {
      setError('Bid not found or access denied');
      return;
    }
    fetchBids();
  };

  return { bids, loading, error, acceptBid, rejectBid };
}
