'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapApprovalRecord, mapApprovalThreshold } from './pm-mappers';
import type { ApprovalRecordData, ApprovalThresholdData } from './pm-mappers';

export function useApprovals() {
  const [approvals, setApprovals] = useState<ApprovalRecordData[]>([]);
  const [thresholds, setThresholds] = useState<ApprovalThresholdData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchApprovals = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Fetch approvals and active thresholds in parallel
      const [approvalsRes, thresholdsRes] = await Promise.all([
        supabase
          .from('approval_records')
          .select('*')
          .order('created_at', { ascending: false }),
        supabase
          .from('approval_thresholds')
          .select('*')
          .eq('is_active', true)
          .order('entity_type', { ascending: true }),
      ]);

      if (approvalsRes.error) throw approvalsRes.error;
      if (thresholdsRes.error) throw thresholdsRes.error;

      setApprovals((approvalsRes.data || []).map(mapApprovalRecord));
      setThresholds((thresholdsRes.data || []).map(mapApprovalThreshold));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load approvals';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchApprovals();

    const supabase = getSupabase();
    const channel = supabase
      .channel('approval-records-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'approval_records' }, () => {
        fetchApprovals();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'approval_thresholds' }, () => {
        fetchApprovals();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchApprovals]);

  const requestApproval = async (data: {
    entityType: string;
    entityId: string;
    thresholdAmount: number;
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('approval_records')
      .insert({
        company_id: companyId,
        entity_type: data.entityType,
        entity_id: data.entityId,
        requested_by: user.id,
        requested_at: new Date().toISOString(),
        threshold_amount: data.thresholdAmount,
        status: 'pending',
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const approveRequest = async (id: string, notes?: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error: err } = await supabase
      .from('approval_records')
      .update({
        status: 'approved',
        decided_by: user.id,
        decided_at: new Date().toISOString(),
        notes: notes || null,
      })
      .eq('id', id);

    if (err) throw err;
  };

  const rejectRequest = async (id: string, notes?: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error: err } = await supabase
      .from('approval_records')
      .update({
        status: 'rejected',
        decided_by: user.id,
        decided_at: new Date().toISOString(),
        notes: notes || null,
      })
      .eq('id', id);

    if (err) throw err;
  };

  const getThresholds = async (): Promise<ApprovalThresholdData[]> => {
    const supabase = getSupabase();

    const { data, error: err } = await supabase
      .from('approval_thresholds')
      .select('*')
      .eq('is_active', true)
      .order('entity_type', { ascending: true });

    if (err) throw err;
    return (data || []).map(mapApprovalThreshold);
  };

  const updateThreshold = async (id: string, data: {
    thresholdAmount?: number;
    requiresRole?: string;
    isActive?: boolean;
  }) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.thresholdAmount !== undefined) updateData.threshold_amount = data.thresholdAmount;
    if (data.requiresRole !== undefined) updateData.requires_role = data.requiresRole;
    if (data.isActive !== undefined) updateData.is_active = data.isActive;

    const { error: err } = await supabase
      .from('approval_thresholds')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;
  };

  const createThreshold = async (data: {
    entityType: string;
    thresholdAmount: number;
    requiresRole: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('approval_thresholds')
      .insert({
        company_id: companyId,
        entity_type: data.entityType,
        threshold_amount: data.thresholdAmount,
        requires_role: data.requiresRole,
        is_active: true,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const checkNeedsApproval = async (entityType: string, amount: number): Promise<{
    needsApproval: boolean;
    threshold: ApprovalThresholdData | null;
  }> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data, error: err } = await supabase
      .from('approval_thresholds')
      .select('*')
      .eq('company_id', companyId)
      .eq('entity_type', entityType)
      .eq('is_active', true)
      .lte('threshold_amount', amount)
      .order('threshold_amount', { ascending: false })
      .limit(1);

    if (err) throw err;

    if (data && data.length > 0) {
      return {
        needsApproval: true,
        threshold: mapApprovalThreshold(data[0]),
      };
    }

    return { needsApproval: false, threshold: null };
  };

  const getPendingApprovals = async (): Promise<ApprovalRecordData[]> => {
    const supabase = getSupabase();

    const { data, error: err } = await supabase
      .from('approval_records')
      .select('*')
      .eq('status', 'pending')
      .order('created_at', { ascending: false });

    if (err) throw err;
    return (data || []).map(mapApprovalRecord);
  };

  return {
    approvals,
    thresholds,
    loading,
    error,
    refetch: fetchApprovals,
    requestApproval,
    approveRequest,
    rejectRequest,
    getThresholds,
    updateThreshold,
    createThreshold,
    checkNeedsApproval,
    getPendingApprovals,
  };
}
