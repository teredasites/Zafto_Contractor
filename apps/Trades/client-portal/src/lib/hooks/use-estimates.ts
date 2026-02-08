'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import {
  mapEstimate, mapEstimateArea, mapEstimateLineItem,
  type EstimateData, type EstimateAreaData, type EstimateLineItemData,
} from './mappers';

export function useEstimates() {
  const { profile } = useAuth();
  const [estimates, setEstimates] = useState<EstimateData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchEstimates = useCallback(async () => {
    if (!profile?.customerId) { setLoading(false); return; }
    const supabase = getSupabase();

    const { data, error: fetchError } = await supabase
      .from('estimates')
      .select('*')
      .eq('customer_id', profile.customerId)
      .is('deleted_at', null)
      .in('status', ['sent', 'approved', 'declined', 'revised', 'completed'])
      .order('created_at', { ascending: false });

    if (fetchError) {
      setError(fetchError.message);
    } else {
      setEstimates((data || []).map(mapEstimate));
    }
    setLoading(false);
  }, [profile?.customerId]);

  useEffect(() => {
    fetchEstimates();
    if (!profile?.customerId) return;

    const supabase = getSupabase();
    const channel = supabase.channel('client-estimates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'estimates' }, () => fetchEstimates())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchEstimates, profile?.customerId]);

  const approveEstimate = async (estimateId: string) => {
    if (!profile?.customerId) {
      setError('Not authenticated');
      return;
    }
    const supabase = getSupabase();
    // Ownership check: only update if estimate belongs to this customer
    const { error: updateError, count } = await supabase
      .from('estimates')
      .update({
        status: 'approved',
        approved_at: new Date().toISOString(),
      })
      .eq('id', estimateId)
      .eq('customer_id', profile.customerId);

    if (updateError) {
      setError(updateError.message);
      return;
    }
    if (count === 0) {
      setError('Estimate not found or access denied');
      return;
    }
    fetchEstimates();
  };

  const rejectEstimate = async (estimateId: string) => {
    if (!profile?.customerId) {
      setError('Not authenticated');
      return;
    }
    const supabase = getSupabase();
    // Ownership check: only update if estimate belongs to this customer
    const { error: updateError, count } = await supabase
      .from('estimates')
      .update({
        status: 'declined',
        declined_at: new Date().toISOString(),
      })
      .eq('id', estimateId)
      .eq('customer_id', profile.customerId);

    if (updateError) {
      setError(updateError.message);
      return;
    }
    if (count === 0) {
      setError('Estimate not found or access denied');
      return;
    }
    fetchEstimates();
  };

  return { estimates, loading, error, approveEstimate, rejectEstimate };
}

export function useEstimateDetail(estimateId: string | null) {
  const [estimate, setEstimate] = useState<EstimateData | null>(null);
  const [areas, setAreas] = useState<EstimateAreaData[]>([]);
  const [lineItems, setLineItems] = useState<EstimateLineItemData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchAll = useCallback(async () => {
    if (!estimateId) { setLoading(false); return; }
    const supabase = getSupabase();

    const [estRes, areasRes, linesRes] = await Promise.all([
      supabase.from('estimates').select('*').eq('id', estimateId).single(),
      supabase.from('estimate_areas').select('*').eq('estimate_id', estimateId).order('sort_order'),
      supabase.from('estimate_line_items').select('*').eq('estimate_id', estimateId).order('sort_order'),
    ]);

    if (estRes.data) setEstimate(mapEstimate(estRes.data));
    setAreas((areasRes.data || []).map(mapEstimateArea));
    setLineItems((linesRes.data || []).map(mapEstimateLineItem));
    setLoading(false);
  }, [estimateId]);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  return { estimate, areas, lineItems, loading, refetch: fetchAll };
}

export function useProjectEstimate(jobId: string | null) {
  const { profile } = useAuth();
  const [estimateId, setEstimateId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function lookup() {
      if (!jobId || !profile?.customerId) { setLoading(false); return; }
      const supabase = getSupabase();

      const { data } = await supabase
        .from('estimates')
        .select('id')
        .eq('job_id', jobId)
        .eq('customer_id', profile.customerId)
        .is('deleted_at', null)
        .in('status', ['sent', 'approved', 'declined', 'revised', 'completed'])
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      if (data) setEstimateId(data.id as string);
      setLoading(false);
    }
    lookup();
  }, [jobId, profile?.customerId]);

  return { estimateId, loading };
}
