'use client';

// ZAFTO Floor Plan Snapshots Hook — SK7
// CRUD for floor_plan_snapshots table.
// Auto-snapshot on session start, manual save, pre-change-order.
// Max 50 per plan (server-side enforcement).

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import type { FloorPlanData } from '@/lib/sketch-engine/types';

// =============================================================================
// INTERFACES
// =============================================================================

export interface FloorPlanSnapshot {
  id: string;
  floorPlanId: string;
  companyId: string;
  planData: FloorPlanData;
  snapshotReason: string;
  snapshotLabel: string | null;
  createdBy: string | null;
  createdAt: string;
}

// =============================================================================
// MAPPER
// =============================================================================

function mapSnapshot(row: Record<string, unknown>): FloorPlanSnapshot {
  return {
    id: row.id as string,
    floorPlanId: row.floor_plan_id as string,
    companyId: row.company_id as string,
    planData: (row.plan_data as unknown as FloorPlanData) || { walls: [], rooms: [], doors: [], windows: [], fixtures: [], labels: [], dimensions: [], arcWalls: [], units: 'imperial', gridSpacing: 12, snapThreshold: 6, tradeLayers: [] },
    snapshotReason: (row.snapshot_reason as string) || 'manual',
    snapshotLabel: (row.snapshot_label as string) || null,
    createdBy: (row.created_by as string) || null,
    createdAt: row.created_at as string,
  };
}

// =============================================================================
// HOOK
// =============================================================================

export function useFloorPlanSnapshots(floorPlanId: string | null) {
  const [snapshots, setSnapshots] = useState<FloorPlanSnapshot[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // =========================================================================
  // FETCH
  // =========================================================================

  const fetchSnapshots = useCallback(async () => {
    if (!floorPlanId) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: fetchError } = await supabase
        .from('floor_plan_snapshots')
        .select('*')
        .eq('floor_plan_id', floorPlanId)
        .order('created_at', { ascending: false })
        .limit(50);

      if (fetchError) throw fetchError;
      setSnapshots((data || []).map((r: Record<string, unknown>) => mapSnapshot(r)));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load snapshots');
    } finally {
      setLoading(false);
    }
  }, [floorPlanId]);

  useEffect(() => {
    fetchSnapshots();
  }, [fetchSnapshots]);

  // =========================================================================
  // MUTATIONS
  // =========================================================================

  const createSnapshot = useCallback(
    async (planData: FloorPlanData, reason: string, label?: string) => {
      if (!floorPlanId) return null;

      try {
        const supabase = getSupabase();
        const { data: { user } } = await supabase.auth.getUser();
        const companyId = user?.app_metadata?.company_id;
        if (!companyId) return null;

        const { data, error: createError } = await supabase
          .from('floor_plan_snapshots')
          .insert({
            floor_plan_id: floorPlanId,
            company_id: companyId,
            plan_data: planData as unknown as Record<string, unknown>,
            snapshot_reason: reason,
            snapshot_label: label || null,
          })
          .select()
          .single();

        if (createError) throw createError;

        if (data) {
          const snap = mapSnapshot(data);
          setSnapshots((prev) => [snap, ...prev].slice(0, 50));
          return snap;
        }
        return null;
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to create snapshot');
        return null;
      }
    },
    [floorPlanId],
  );

  const restoreSnapshot = useCallback(
    async (snapshot: FloorPlanSnapshot): Promise<FloorPlanData | null> => {
      if (!floorPlanId) return null;

      try {
        const supabase = getSupabase();

        // Overwrite current plan_data with snapshot data
        const { error: updateError } = await supabase
          .from('property_floor_plans')
          .update({
            plan_data: snapshot.planData as unknown as Record<string, unknown>,
            sync_version: Date.now(),
            last_synced_at: new Date().toISOString(),
          })
          .eq('id', floorPlanId);

        if (updateError) throw updateError;

        return snapshot.planData;
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to restore snapshot');
        return null;
      }
    },
    [floorPlanId],
  );

  const deleteSnapshot = useCallback(
    async (snapshotId: string) => {
      try {
        const supabase = getSupabase();
        const { error: deleteError } = await supabase
          .from('floor_plan_snapshots')
          .update({ deleted_at: new Date().toISOString() })
          .eq('id', snapshotId);

        if (deleteError) throw deleteError;

        setSnapshots((prev) => prev.filter((s) => s.id !== snapshotId));
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to delete snapshot');
      }
    },
    [],
  );

  return {
    snapshots,
    loading,
    error,
    createSnapshot,
    restoreSnapshot,
    deleteSnapshot,
    refetch: fetchSnapshots,
  };
}
