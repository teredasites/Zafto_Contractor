'use client';

// DEPTH29: Estimate Versions & Change Orders Hook
// Manages version history, change orders, and tier-based estimate regeneration.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface EstimateVersion {
  id: string;
  estimateId: string;
  versionNumber: number;
  label: string | null;
  snapshotData: Record<string, unknown>;
  createdBy: string | null;
  createdAt: string;
}

export type ChangeOrderStatus = 'draft' | 'sent' | 'approved' | 'rejected';

export interface EstimateChangeOrder {
  id: string;
  estimateId: string;
  changeOrderNumber: number;
  title: string;
  description: string | null;
  status: ChangeOrderStatus;
  itemsAdded: Array<Record<string, unknown>>;
  itemsModified: Array<Record<string, unknown>>;
  itemsRemoved: Array<Record<string, unknown>>;
  subtotalChange: number;
  taxChange: number;
  totalChange: number;
  newEstimateTotal: number;
  approvedAt: string | null;
  signedAt: string | null;
  createdAt: string;
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapVersion(row: Record<string, unknown>): EstimateVersion {
  return {
    id: row.id as string,
    estimateId: row.estimate_id as string,
    versionNumber: Number(row.version_number) || 1,
    label: row.label as string | null,
    snapshotData: (row.snapshot_data as Record<string, unknown>) || {},
    createdBy: row.created_by as string | null,
    createdAt: row.created_at as string,
  };
}

function mapChangeOrder(row: Record<string, unknown>): EstimateChangeOrder {
  return {
    id: row.id as string,
    estimateId: row.estimate_id as string,
    changeOrderNumber: Number(row.change_order_number) || 1,
    title: row.title as string,
    description: row.description as string | null,
    status: row.status as ChangeOrderStatus,
    itemsAdded: (row.items_added as Array<Record<string, unknown>>) || [],
    itemsModified: (row.items_modified as Array<Record<string, unknown>>) || [],
    itemsRemoved: (row.items_removed as Array<Record<string, unknown>>) || [],
    subtotalChange: Number(row.subtotal_change) || 0,
    taxChange: Number(row.tax_change) || 0,
    totalChange: Number(row.total_change) || 0,
    newEstimateTotal: Number(row.new_estimate_total) || 0,
    approvedAt: row.approved_at as string | null,
    signedAt: row.signed_at as string | null,
    createdAt: row.created_at as string,
  };
}

// ============================================================================
// HOOK: useEstimateVersions
// ============================================================================

export function useEstimateVersions(estimateId?: string) {
  const [versions, setVersions] = useState<EstimateVersion[]>([]);
  const [changeOrders, setChangeOrders] = useState<EstimateChangeOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAll = useCallback(async () => {
    if (!estimateId) {
      setVersions([]);
      setChangeOrders([]);
      setLoading(false);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();

      const [versionRes, coRes] = await Promise.all([
        supabase
          .from('estimate_versions')
          .select('*')
          .eq('estimate_id', estimateId)
          .order('version_number', { ascending: false }),
        supabase
          .from('estimate_change_orders')
          .select('*')
          .eq('estimate_id', estimateId)
          .is('deleted_at', null)
          .order('change_order_number'),
      ]);

      if (versionRes.error) throw versionRes.error;
      if (coRes.error) throw coRes.error;

      setVersions((versionRes.data || []).map(mapVersion));
      setChangeOrders((coRes.data || []).map(mapChangeOrder));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load estimate history');
    } finally {
      setLoading(false);
    }
  }, [estimateId]);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  // Create a version snapshot
  const createVersion = useCallback(async (label?: string, snapshotData?: Record<string, unknown>) => {
    if (!estimateId) return;
    try {
      const supabase = getSupabase();
      const nextVersion = versions.length > 0 ? versions[0].versionNumber + 1 : 1;

      const { error: err } = await supabase.from('estimate_versions').insert({
        estimate_id: estimateId,
        version_number: nextVersion,
        label: label || `Version ${nextVersion}`,
        snapshot_data: snapshotData || {},
      });

      if (err) throw err;

      // Also update estimate's version number
      await supabase
        .from('estimates')
        .update({ version_number: nextVersion })
        .eq('id', estimateId);

      await fetchAll();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to create version');
    }
  }, [estimateId, versions, fetchAll]);

  // Create a change order
  const createChangeOrder = useCallback(async (input: {
    title: string;
    description?: string;
    itemsAdded?: Array<Record<string, unknown>>;
    itemsModified?: Array<Record<string, unknown>>;
    itemsRemoved?: Array<Record<string, unknown>>;
    subtotalChange: number;
    taxChange: number;
    totalChange: number;
    newEstimateTotal: number;
  }) => {
    if (!estimateId) return;
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const nextCo = changeOrders.length > 0
        ? Math.max(...changeOrders.map(co => co.changeOrderNumber)) + 1
        : 1;

      const { error: err } = await supabase.from('estimate_change_orders').insert({
        estimate_id: estimateId,
        change_order_number: nextCo,
        title: input.title,
        description: input.description || null,
        items_added: input.itemsAdded || [],
        items_modified: input.itemsModified || [],
        items_removed: input.itemsRemoved || [],
        subtotal_change: input.subtotalChange,
        tax_change: input.taxChange,
        total_change: input.totalChange,
        new_estimate_total: input.newEstimateTotal,
        created_by: session.user.id,
      });

      if (err) throw err;

      // Update estimate's change_order_total
      await supabase
        .from('estimates')
        .update({ change_order_total: input.newEstimateTotal })
        .eq('id', estimateId);

      await fetchAll();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to create change order');
    }
  }, [estimateId, changeOrders, fetchAll]);

  // Approve a change order
  const approveChangeOrder = useCallback(async (coId: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('estimate_change_orders')
        .update({
          status: 'approved',
          approved_at: new Date().toISOString(),
        })
        .eq('id', coId);

      if (err) throw err;
      await fetchAll();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to approve change order');
    }
  }, [fetchAll]);

  // Computed: total change orders amount
  const totalChangeOrderAmount = changeOrders
    .filter(co => co.status === 'approved')
    .reduce((sum, co) => sum + co.totalChange, 0);

  return {
    versions,
    changeOrders,
    loading,
    error,
    refetch: fetchAll,
    createVersion,
    createChangeOrder,
    approveChangeOrder,
    totalChangeOrderAmount,
  };
}
