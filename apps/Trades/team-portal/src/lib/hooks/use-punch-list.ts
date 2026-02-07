'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapPunchListItem, type PunchListItemData } from './mappers';

export function usePunchList(jobId?: string) {
  const [items, setItems] = useState<PunchListItemData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchItems = useCallback(async () => {
    const supabase = getSupabase();
    let query = supabase.from('punch_list_items').select('*').is('deleted_at', null).order('created_at', { ascending: false });
    if (jobId) query = query.eq('job_id', jobId);
    const { data } = await query;
    setItems((data || []).map(mapPunchListItem));
    setLoading(false);
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
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    await supabase.from('punch_list_items').insert({
      job_id: data.jobId, company_id: user.app_metadata?.company_id,
      created_by_user_id: user.id, title: data.title,
      description: data.description || '', category: data.category || '',
      priority: data.priority || 'normal', status: 'open',
    });
    fetchItems();
  };

  const toggleComplete = async (itemId: string, currentStatus: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (currentStatus === 'completed') {
      await supabase.from('punch_list_items').update({ status: 'open', completed_at: null, completed_by: null }).eq('id', itemId);
    } else {
      await supabase.from('punch_list_items').update({ status: 'completed', completed_at: new Date().toISOString(), completed_by: user?.id }).eq('id', itemId);
    }
    fetchItems();
  };

  const openCount = items.filter(i => i.status !== 'completed' && i.status !== 'skipped').length;
  const completedCount = items.filter(i => i.status === 'completed' || i.status === 'skipped').length;

  return { items, loading, addItem, toggleComplete, openCount, completedCount };
}
