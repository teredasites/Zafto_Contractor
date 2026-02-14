'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface RingGroup {
  id: string;
  companyId: string;
  name: string;
  strategy: 'simultaneous' | 'sequential' | 'round_robin';
  ringDurationSeconds: number;
  noAnswerAction: 'voicemail' | 'next_group' | 'specific_user';
  noAnswerTarget: string | null;
  memberUserIds: string[];
  createdAt: string;
}

function mapGroup(row: Record<string, unknown>): RingGroup {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    name: row.name as string,
    strategy: (row.strategy as RingGroup['strategy']) || 'simultaneous',
    ringDurationSeconds: Number(row.ring_duration_seconds) || 30,
    noAnswerAction: (row.no_answer_action as RingGroup['noAnswerAction']) || 'voicemail',
    noAnswerTarget: row.no_answer_target as string | null,
    memberUserIds: (row.member_user_ids as string[]) || [],
    createdAt: row.created_at as string,
  };
}

export function useRingGroups() {
  const [groups, setGroups] = useState<RingGroup[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchGroups = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('phone_ring_groups')
        .select('*')
        .order('name');

      if (err) throw err;
      setGroups((data || []).map(mapGroup));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load ring groups');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchGroups();
  }, [fetchGroups]);

  const createGroup = async (data: {
    name: string;
    strategy?: RingGroup['strategy'];
    ringDurationSeconds?: number;
    noAnswerAction?: RingGroup['noAnswerAction'];
    memberUserIds?: string[];
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    const companyId = user?.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { data: result, error: err } = await supabase
      .from('phone_ring_groups')
      .insert({
        company_id: companyId,
        name: data.name,
        strategy: data.strategy || 'simultaneous',
        ring_duration_seconds: data.ringDurationSeconds || 30,
        no_answer_action: data.noAnswerAction || 'voicemail',
        member_user_ids: data.memberUserIds || [],
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchGroups();
    return result.id;
  };

  const updateGroup = async (id: string, updates: Partial<Record<string, unknown>>) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('phone_ring_groups')
      .update(updates)
      .eq('id', id);
    if (err) throw err;
    await fetchGroups();
  };

  const deleteGroup = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('phone_ring_groups')
      .delete()
      .eq('id', id);
    if (err) throw err;
    await fetchGroups();
  };

  const addMember = async (groupId: string, userId: string) => {
    const group = groups.find((g) => g.id === groupId);
    if (!group || group.memberUserIds.includes(userId)) return;

    await updateGroup(groupId, {
      member_user_ids: [...group.memberUserIds, userId],
    });
  };

  const removeMember = async (groupId: string, userId: string) => {
    const group = groups.find((g) => g.id === groupId);
    if (!group) return;

    await updateGroup(groupId, {
      member_user_ids: group.memberUserIds.filter((id) => id !== userId),
    });
  };

  return {
    groups,
    loading,
    error,
    createGroup,
    updateGroup,
    deleteGroup,
    addMember,
    removeMember,
    refetch: fetchGroups,
  };
}
