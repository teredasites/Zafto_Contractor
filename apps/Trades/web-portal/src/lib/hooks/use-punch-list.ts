'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface PunchListItemData {
  id: string;
  companyId: string;
  jobId: string;
  title: string;
  description: string;
  category: string;
  priority: 'low' | 'normal' | 'high' | 'urgent';
  status: 'open' | 'in_progress' | 'completed' | 'skipped';
  assignedToUserId: string | null;
  assignedToName: string | null;
  dueDate: string | null;
  photoIds: string[];
  sortOrder: number;
  completedAt: string | null;
  completedByUserId: string | null;
  createdByUserId: string;
  createdAt: string;
  updatedAt: string;
}

function mapPunchListItem(row: Record<string, unknown>): PunchListItemData {
  const assignee = row.assigned_user as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    jobId: (row.job_id as string) || '',
    title: (row.title as string) || '',
    description: (row.description as string) || '',
    category: (row.category as string) || '',
    priority: (row.priority as PunchListItemData['priority']) || 'normal',
    status: (row.status as PunchListItemData['status']) || 'open',
    assignedToUserId: (row.assigned_to_user_id as string) || null,
    assignedToName: assignee ? (assignee.full_name as string) || (assignee.email as string) || null : null,
    dueDate: (row.due_date as string) || null,
    photoIds: (row.photo_ids as string[]) || [],
    sortOrder: (row.sort_order as number) || 0,
    completedAt: (row.completed_at as string) || null,
    completedByUserId: (row.completed_by_user_id as string) || null,
    createdByUserId: (row.created_by_user_id as string) || '',
    createdAt: (row.created_at as string) || '',
    updatedAt: (row.updated_at as string) || '',
  };
}

export function usePunchList(jobId?: string) {
  const [items, setItems] = useState<PunchListItemData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchItems = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      let query = supabase
        .from('punch_list_items')
        .select('*, assigned_user:assigned_to_user_id(full_name, email)')
        .is('deleted_at', null)
        .order('sort_order', { ascending: true });
      if (jobId) query = query.eq('job_id', jobId);
      const { data, error: err } = await query;
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
      .channel('crm-punch-list')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'punch_list_items' }, () => fetchItems())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchItems]);

  const addItem = async (data: {
    jobId: string;
    title: string;
    description?: string;
    category?: string;
    priority?: PunchListItemData['priority'];
    assignedToUserId?: string;
    dueDate?: string;
  }) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { error: err } = await supabase.from('punch_list_items').insert({
        job_id: data.jobId,
        company_id: user.app_metadata?.company_id,
        created_by_user_id: user.id,
        title: data.title,
        description: data.description || '',
        category: data.category || '',
        priority: data.priority || 'normal',
        status: 'open',
        assigned_to_user_id: data.assignedToUserId || null,
        due_date: data.dueDate || null,
        sort_order: items.length,
      });
      if (err) throw err;
      await fetchItems();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to add punch list item');
      throw e;
    }
  };

  const updateItem = async (itemId: string, updates: Partial<{
    title: string;
    description: string;
    category: string;
    priority: PunchListItemData['priority'];
    status: PunchListItemData['status'];
    assignedToUserId: string | null;
    dueDate: string | null;
  }>) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const payload: Record<string, unknown> = {};
      if (updates.title !== undefined) payload.title = updates.title;
      if (updates.description !== undefined) payload.description = updates.description;
      if (updates.category !== undefined) payload.category = updates.category;
      if (updates.priority !== undefined) payload.priority = updates.priority;
      if (updates.status !== undefined) payload.status = updates.status;
      if (updates.assignedToUserId !== undefined) payload.assigned_to_user_id = updates.assignedToUserId;
      if (updates.dueDate !== undefined) payload.due_date = updates.dueDate;

      const { error: err } = await supabase
        .from('punch_list_items')
        .update(payload)
        .eq('id', itemId);
      if (err) throw err;
      await fetchItems();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to update punch list item');
      throw e;
    }
  };

  const toggleComplete = async (itemId: string) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      const item = items.find(i => i.id === itemId);
      if (!item) return;

      if (item.status === 'completed') {
        const { error: err } = await supabase.from('punch_list_items')
          .update({ status: 'open', completed_at: null, completed_by_user_id: null })
          .eq('id', itemId);
        if (err) throw err;
      } else {
        const { error: err } = await supabase.from('punch_list_items')
          .update({ status: 'completed', completed_at: new Date().toISOString(), completed_by_user_id: user?.id })
          .eq('id', itemId);
        if (err) throw err;
      }
      await fetchItems();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to toggle punch list item');
      throw e;
    }
  };

  const deleteItem = async (itemId: string) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('punch_list_items')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', itemId);
      if (err) throw err;
      await fetchItems();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to delete punch list item');
      throw e;
    }
  };

  const openItems = items.filter(i => i.status === 'open' || i.status === 'in_progress');
  const completedItems = items.filter(i => i.status === 'completed' || i.status === 'skipped');
  const urgentItems = items.filter(i => i.priority === 'urgent' && i.status !== 'completed');
  const overdueItems = items.filter(i => {
    if (!i.dueDate || i.status === 'completed' || i.status === 'skipped') return false;
    return new Date(i.dueDate) < new Date();
  });
  const progress = items.length > 0 ? Math.round((completedItems.length / items.length) * 100) : 0;

  return {
    items,
    loading,
    error,
    addItem,
    updateItem,
    toggleComplete,
    deleteItem,
    openItems,
    completedItems,
    urgentItems,
    overdueItems,
    progress,
    refresh: fetchItems,
  };
}
