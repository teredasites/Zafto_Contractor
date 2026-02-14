'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Completion Checklists Hook — trade-specific completion checklists
// ============================================================

export interface ChecklistItem {
  key: string;
  label: string;
  required: boolean;
  category: string;
}

export interface CompletionChecklist {
  id: string;
  companyId: string;
  tradeType: string;
  name: string;
  description: string | null;
  items: ChecklistItem[];
  isSystem: boolean;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

interface RawChecklist {
  id: string;
  company_id: string;
  trade_type: string;
  name: string;
  description: string | null;
  items: ChecklistItem[];
  is_system: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

function mapChecklist(raw: RawChecklist): CompletionChecklist {
  return {
    id: raw.id,
    companyId: raw.company_id,
    tradeType: raw.trade_type,
    name: raw.name,
    description: raw.description,
    items: raw.items || [],
    isSystem: raw.is_system,
    isActive: raw.is_active,
    createdAt: raw.created_at,
    updatedAt: raw.updated_at,
  };
}

export function useCompletionChecklists(tradeType?: string) {
  const [checklists, setChecklists] = useState<CompletionChecklist[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchChecklists = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      let query = supabase
        .from('completion_checklists')
        .select('*')
        .is('deleted_at', null)
        .order('trade_type', { ascending: true });

      if (tradeType) {
        query = query.eq('trade_type', tradeType);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setChecklists((data || []).map((r: RawChecklist) => mapChecklist(r)));
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load checklists');
    } finally {
      setLoading(false);
    }
  }, [tradeType]);

  useEffect(() => {
    fetchChecklists();
  }, [fetchChecklists]);

  const createChecklist = useCallback(async (input: {
    tradeType: string;
    name: string;
    description?: string;
    items: ChecklistItem[];
  }) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { data, error: err } = await supabase
      .from('completion_checklists')
      .insert({
        company_id: companyId,
        trade_type: input.tradeType,
        name: input.name,
        description: input.description || null,
        items: input.items,
      })
      .select()
      .single();
    if (err) throw err;
    return mapChecklist(data);
  }, []);

  const updateChecklist = useCallback(async (id: string, updates: Partial<{
    name: string;
    description: string | null;
    items: ChecklistItem[];
    isActive: boolean;
  }>) => {
    const supabase = getSupabase();
    const payload: Record<string, unknown> = {};
    if (updates.name !== undefined) payload.name = updates.name;
    if (updates.description !== undefined) payload.description = updates.description;
    if (updates.items !== undefined) payload.items = updates.items;
    if (updates.isActive !== undefined) payload.is_active = updates.isActive;

    const { error: err } = await supabase
      .from('completion_checklists')
      .update(payload)
      .eq('id', id);
    if (err) throw err;
  }, []);

  const deleteChecklist = useCallback(async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('completion_checklists')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  }, []);

  return {
    checklists,
    loading,
    error,
    createChecklist,
    updateChecklist,
    deleteChecklist,
    refetch: fetchChecklists,
  };
}
