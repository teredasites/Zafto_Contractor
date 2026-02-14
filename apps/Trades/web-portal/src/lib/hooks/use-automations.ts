'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Automations Hook — CRUD + Real-time
// ============================================================

export type AutomationStatus = 'active' | 'paused' | 'draft';
export type TriggerType = 'job_status' | 'invoice_overdue' | 'lead_idle' | 'time_based' | 'customer_event' | 'bid_event';
export type ActionType = 'send_email' | 'send_sms' | 'create_task' | 'notify_team' | 'update_status' | 'create_followup';

export interface AutomationAction {
  type: ActionType;
  label: string;
  config: Record<string, string>;
}

export interface AutomationData {
  id: string;
  companyId: string;
  createdBy: string | null;
  name: string;
  description: string | null;
  status: AutomationStatus;
  triggerType: TriggerType;
  triggerConfig: Record<string, unknown>;
  delayMinutes: number;
  actions: AutomationAction[];
  lastRunAt: string | null;
  runCount: number;
  createdAt: string;
  updatedAt: string;
}

function mapAutomation(row: Record<string, unknown>): AutomationData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    createdBy: row.created_by as string | null,
    name: row.name as string,
    description: row.description as string | null,
    status: (row.status as AutomationStatus) || 'draft',
    triggerType: row.trigger_type as TriggerType,
    triggerConfig: (row.trigger_config as Record<string, unknown>) || {},
    delayMinutes: Number(row.delay_minutes || 0),
    actions: Array.isArray(row.actions) ? row.actions as AutomationAction[] : [],
    lastRunAt: row.last_run_at as string | null,
    runCount: Number(row.run_count || 0),
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

export function useAutomations() {
  const [automations, setAutomations] = useState<AutomationData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAutomations = useCallback(async () => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('automations')
      .select('*')
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    if (err) { setError(err.message); setLoading(false); return; }
    setAutomations((data || []).map(mapAutomation));
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchAutomations();

    const supabase = getSupabase();
    const channel = supabase.channel('automations-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'automations' }, () => fetchAutomations())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchAutomations]);

  const createAutomation = async (data: Partial<AutomationData>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { data: result, error: err } = await supabase
      .from('automations')
      .insert({
        company_id: companyId,
        created_by: user.id,
        name: data.name || 'Untitled Automation',
        description: data.description || null,
        status: data.status || 'draft',
        trigger_type: data.triggerType || 'job_status',
        trigger_config: data.triggerConfig || {},
        delay_minutes: data.delayMinutes || 0,
        actions: data.actions || [],
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateAutomation = async (id: string, data: Partial<AutomationData>) => {
    const supabase = getSupabase();
    const updates: Record<string, unknown> = {};
    if (data.name !== undefined) updates.name = data.name;
    if (data.description !== undefined) updates.description = data.description;
    if (data.status !== undefined) updates.status = data.status;
    if (data.triggerType !== undefined) updates.trigger_type = data.triggerType;
    if (data.triggerConfig !== undefined) updates.trigger_config = data.triggerConfig;
    if (data.delayMinutes !== undefined) updates.delay_minutes = data.delayMinutes;
    if (data.actions !== undefined) updates.actions = data.actions;

    const { error: err } = await supabase.from('automations').update(updates).eq('id', id);
    if (err) throw err;
  };

  const deleteAutomation = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase.from('automations').update({ deleted_at: new Date().toISOString() }).eq('id', id);
    if (err) throw err;
  };

  const toggleAutomation = async (id: string, enabled: boolean) => {
    await updateAutomation(id, { status: enabled ? 'active' : 'paused' });
  };

  return { automations, loading, error, createAutomation, updateAutomation, deleteAutomation, toggleAutomation };
}
