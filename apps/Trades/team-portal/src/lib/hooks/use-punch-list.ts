'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapPunchListItem, type PunchListItemData } from './mappers';

export function usePunchList(jobId?: string) {
  const [items, setItems] = useState<PunchListItemData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchItems = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      let query = supabase.from('punch_list_items').select('*').order('created_at', { ascending: false });
      if (jobId) query = query.eq('job_id', jobId);
      const { data, error: err } = await query;

      if (err) throw err;
      setItems((data || []).map(mapPunchListItem));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load punch list';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetchItems();
    const supabase = getSupabase();
    const channel = supabase.channel('team-punch')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'punch_list_items' }, () => fetchItems())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchItems]);

  const addItem = async (data: { jobId: string; title: string; description?: string; category?: string; priority?: string }) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const { error: err } = await supabase.from('punch_list_items').insert({
        job_id: data.jobId, company_id: user.app_metadata?.company_id,
        created_by_user_id: user.id, title: data.title,
        description: data.description || '', category: data.category || '',
        priority: data.priority || 'normal', status: 'open',
      });

      if (err) throw err;
      fetchItems();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to add punch list item';
      setError(msg);
      throw e;
    }
  };

  const toggleComplete = async (itemId: string, currentStatus: string) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();

      if (currentStatus === 'completed') {
        const { error: err } = await supabase.from('punch_list_items').update({ status: 'open', completed_at: null, completed_by_user_id: null }).eq('id', itemId);
        if (err) throw err;
      } else {
        const { error: err } = await supabase.from('punch_list_items').update({ status: 'completed', completed_at: new Date().toISOString(), completed_by_user_id: user?.id }).eq('id', itemId);
        if (err) throw err;
      }
      fetchItems();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to update punch list item';
      setError(msg);
      throw e;
    }
  };

  const openCount = items.filter(i => i.status !== 'completed' && i.status !== 'skipped').length;
  const completedCount = items.filter(i => i.status === 'completed' || i.status === 'skipped').length;

  return { items, loading, error, addItem, toggleComplete, openCount, completedCount };
}
