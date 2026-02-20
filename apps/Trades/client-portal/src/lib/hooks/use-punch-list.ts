'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface PunchListItemData {
  id: string;
  jobId: string;
  title: string;
  description: string;
  category: string;
  priority: 'low' | 'normal' | 'high' | 'urgent';
  status: 'open' | 'in_progress' | 'completed' | 'skipped';
  dueDate: string | null;
  completedAt: string | null;
  createdAt: string;
}

function mapPunchListItem(row: Record<string, unknown>): PunchListItemData {
  return {
    id: row.id as string,
    jobId: (row.job_id as string) || '',
    title: (row.title as string) || '',
    description: (row.description as string) || '',
    category: (row.category as string) || '',
    priority: (row.priority as PunchListItemData['priority']) || 'normal',
    status: (row.status as PunchListItemData['status']) || 'open',
    dueDate: (row.due_date as string) || null,
    completedAt: (row.completed_at as string) || null,
    createdAt: (row.created_at as string) || '',
  };
}

/**
 * Client-facing punch list hook — read-only.
 * Homeowners can see remaining items on their project but cannot add/edit/delete.
 * Fetches punch list items for jobs linked to the authenticated client's customer record.
 */
export function usePunchList(jobId: string) {
  const [items, setItems] = useState<PunchListItemData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchItems = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('punch_list_items')
        .select('id, job_id, title, description, category, priority, status, due_date, completed_at, created_at')
        .eq('job_id', jobId)
        .is('deleted_at', null)
        .order('sort_order', { ascending: true });
      if (err) throw err;
      setItems((data || []).map(mapPunchListItem));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load punch list');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetchItems();
    const supabase = getSupabase();
    const channel = supabase
      .channel('client-punch-list')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'punch_list_items', filter: `job_id=eq.${jobId}` }, () => fetchItems())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchItems, jobId]);

  const openItems = items.filter(i => i.status === 'open' || i.status === 'in_progress');
  const completedItems = items.filter(i => i.status === 'completed' || i.status === 'skipped');
  const progress = items.length > 0 ? Math.round((completedItems.length / items.length) * 100) : 0;

  return { items, openItems, completedItems, progress, loading, error };
}
