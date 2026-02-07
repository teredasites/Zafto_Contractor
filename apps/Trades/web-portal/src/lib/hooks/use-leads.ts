'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapLead } from './mappers';
import type { LeadData } from './mappers';

export function useLeads() {
  const [leads, setLeads] = useState<LeadData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchLeads = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('leads')
        .select('*')
        .order('created_at', { ascending: false });

      if (err) throw err;
      setLeads((data || []).map(mapLead));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load leads';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchLeads();

    const supabase = getSupabase();
    const channel = supabase
      .channel('leads-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'leads' }, () => {
        fetchLeads();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchLeads]);

  const createLead = async (input: {
    name: string;
    email?: string;
    phone?: string;
    companyName?: string;
    source?: string;
    value?: number;
    notes?: string;
    address?: { street: string; city: string; state: string; zip: string };
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('leads')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        name: input.name,
        email: input.email || null,
        phone: input.phone || null,
        company_name: input.companyName || null,
        source: input.source?.toLowerCase() || 'website',
        stage: 'new',
        value: input.value || 0,
        notes: input.notes || null,
        address: input.address?.street || null,
        city: input.address?.city || null,
        state: input.address?.state || null,
        zip_code: input.address?.zip || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateLeadStage = async (id: string, stage: string) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = { stage };
    if (stage === 'contacted') updateData.last_contacted_at = new Date().toISOString();
    if (stage === 'won') updateData.won_at = new Date().toISOString();
    if (stage === 'lost') updateData.lost_at = new Date().toISOString();
    const { error: err } = await supabase.from('leads').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const updateLead = async (id: string, data: Partial<LeadData>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.email !== undefined) updateData.email = data.email;
    if (data.phone !== undefined) updateData.phone = data.phone;
    if (data.companyName !== undefined) updateData.company_name = data.companyName;
    if (data.source !== undefined) updateData.source = data.source;
    if (data.value !== undefined) updateData.value = data.value;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.nextFollowUp !== undefined) updateData.next_follow_up = data.nextFollowUp ? data.nextFollowUp.toISOString() : null;
    if (data.assignedToUserId !== undefined) updateData.assigned_to_user_id = data.assignedToUserId;
    const { error: err } = await supabase.from('leads').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const deleteLead = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase.from('leads').delete().eq('id', id);
    if (err) throw err;
  };

  return { leads, loading, error, createLead, updateLeadStage, updateLead, deleteLead, refetch: fetchLeads };
}
