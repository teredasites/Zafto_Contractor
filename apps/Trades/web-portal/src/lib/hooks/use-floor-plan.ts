'use client';

// ZAFTO Floor Plan Hook — Supabase CRUD (SK6)
// CRUD for property_floor_plans + floor_plan_layers + floor_plan_rooms.
// Real-time subscription on plan row. Debounced save (500ms).

import { useState, useEffect, useCallback, useRef } from 'react';
import { getSupabase } from '@/lib/supabase';
import type { RealtimePostgresChangesPayload } from '@supabase/supabase-js';
import type { FloorPlanData } from '@/lib/sketch-engine/types';
import { createEmptyFloorPlan } from '@/lib/sketch-engine/types';

// =============================================================================
// INTERFACES
// =============================================================================

export interface FloorPlan {
  id: string;
  companyId: string;
  propertyId: string | null;
  jobId: string | null;
  estimateId: string | null;
  name: string;
  floorLevel: number;
  floorNumber: number;
  status: string;
  planData: FloorPlanData;
  syncVersion: number;
  lastSyncedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface FloorPlanLayer {
  id: string;
  floorPlanId: string;
  companyId: string;
  layerType: string;
  layerName: string;
  layerOrder: number;
  visible: boolean;
  locked: boolean;
  opacity: number;
  layerData: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export interface FloorPlanRoom {
  id: string;
  floorPlanId: string;
  companyId: string;
  name: string;
  roomType: string;
  floorAreaSf: number;
  wallAreaSf: number;
  perimeterLf: number;
  ceilingHeightInches: number;
  damageClass: string | null;
  iicrcCategory: string | null;
  metadata: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

// =============================================================================
// MAPPERS
// =============================================================================

function mapFloorPlan(row: Record<string, unknown>): FloorPlan {
  const rawData = row.plan_data as Record<string, unknown> | null;
  let planData: FloorPlanData;

  try {
    planData = rawData
      ? (rawData as unknown as FloorPlanData)
      : createEmptyFloorPlan();
  } catch {
    planData = createEmptyFloorPlan();
  }

  return {
    id: row.id as string,
    companyId: row.company_id as string,
    propertyId: (row.property_id as string) || null,
    jobId: (row.job_id as string) || null,
    estimateId: (row.estimate_id as string) || null,
    name: (row.name as string) || 'Untitled',
    floorLevel: (row.floor_level as number) || 1,
    floorNumber: (row.floor_number as number) || 1,
    status: (row.status as string) || 'draft',
    planData,
    syncVersion: (row.sync_version as number) || 1,
    lastSyncedAt: (row.last_synced_at as string) || null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

// =============================================================================
// HOOK
// =============================================================================

export function useFloorPlan(planId: string | null) {
  const [plan, setPlan] = useState<FloorPlan | null>(null);
  const [layers, setLayers] = useState<FloorPlanLayer[]>([]);
  const [rooms, setRooms] = useState<FloorPlanRoom[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const saveTimerRef = useRef<NodeJS.Timeout | null>(null);
  const latestPlanDataRef = useRef<FloorPlanData | null>(null);
  const syncVersionRef = useRef(1);

  // =========================================================================
  // FETCH
  // =========================================================================

  const fetchPlan = useCallback(async () => {
    if (!planId) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: fetchError } = await supabase
        .from('property_floor_plans')
        .select('*')
        .eq('id', planId)
        .single();

      if (fetchError) throw fetchError;
      if (data) setPlan(mapFloorPlan(data));

      // Fetch layers
      const { data: layerData } = await supabase
        .from('floor_plan_layers')
        .select('*')
        .eq('floor_plan_id', planId)
        .order('layer_order');

      if (layerData) {
        setLayers(
          layerData.map((r: Record<string, unknown>) => ({
            id: r.id as string,
            floorPlanId: r.floor_plan_id as string,
            companyId: r.company_id as string,
            layerType: r.layer_type as string,
            layerName: r.layer_name as string,
            layerOrder: (r.layer_order as number) || 0,
            visible: (r.visible as boolean) ?? true,
            locked: (r.locked as boolean) ?? false,
            opacity: (r.opacity as number) ?? 1.0,
            layerData: (r.layer_data as Record<string, unknown>) || {},
            createdAt: r.created_at as string,
            updatedAt: r.updated_at as string,
          })),
        );
      }

      // Fetch rooms
      const { data: roomData } = await supabase
        .from('floor_plan_rooms')
        .select('*')
        .eq('floor_plan_id', planId)
        .is('deleted_at', null);

      if (roomData) {
        setRooms(
          roomData.map((r: Record<string, unknown>) => ({
            id: r.id as string,
            floorPlanId: r.floor_plan_id as string,
            companyId: r.company_id as string,
            name: (r.name as string) || 'Room',
            roomType: (r.room_type as string) || 'room',
            floorAreaSf: (r.floor_area_sf as number) || 0,
            wallAreaSf: (r.wall_area_sf as number) || 0,
            perimeterLf: (r.perimeter_lf as number) || 0,
            ceilingHeightInches: (r.ceiling_height_inches as number) || 96,
            damageClass: (r.damage_class as string) || null,
            iicrcCategory: (r.iicrc_category as string) || null,
            metadata: (r.metadata as Record<string, unknown>) || {},
            createdAt: r.created_at as string,
            updatedAt: r.updated_at as string,
          })),
        );
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load plan');
    } finally {
      setLoading(false);
    }
  }, [planId]);

  useEffect(() => {
    fetchPlan();
  }, [fetchPlan]);

  // Keep sync version ref current to avoid stale closures in debounced save
  useEffect(() => {
    if (plan) syncVersionRef.current = plan.syncVersion;
  }, [plan]);

  // =========================================================================
  // REAL-TIME SUBSCRIPTION
  // =========================================================================

  useEffect(() => {
    if (!planId) return;
    const supabase = getSupabase();

    const channel = supabase
      .channel(`floor_plan_${planId}`)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'property_floor_plans',
          filter: `id=eq.${planId}`,
        },
        (payload: RealtimePostgresChangesPayload<Record<string, unknown>>) => {
          if (payload.new && typeof payload.new === 'object') {
            setPlan(mapFloorPlan(payload.new as Record<string, unknown>));
          }
        },
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [planId]);

  // =========================================================================
  // DEBOUNCED SAVE
  // =========================================================================

  const savePlanData = useCallback(
    (data: FloorPlanData) => {
      if (!planId) return;

      latestPlanDataRef.current = data;

      // Clear existing timer
      if (saveTimerRef.current) {
        clearTimeout(saveTimerRef.current);
      }

      // Debounce 500ms
      saveTimerRef.current = setTimeout(async () => {
        const dataToSave = latestPlanDataRef.current;
        if (!dataToSave) return;

        try {
          setSaving(true);
          const supabase = getSupabase();
          const nextVersion = syncVersionRef.current + 1;

          const { error: saveError } = await supabase
            .from('property_floor_plans')
            .update({
              plan_data: dataToSave as unknown as Record<string, unknown>,
              sync_version: nextVersion,
              last_synced_at: new Date().toISOString(),
            })
            .eq('id', planId);

          if (saveError) throw saveError;

          syncVersionRef.current = nextVersion;
          setPlan((prev) =>
            prev
              ? {
                  ...prev,
                  planData: dataToSave,
                  syncVersion: nextVersion,
                }
              : prev,
          );
        } catch (err) {
          setError(
            err instanceof Error ? err.message : 'Failed to save plan',
          );
        } finally {
          setSaving(false);
        }
      }, 500);
    },
    [planId],
  );

  // =========================================================================
  // MUTATIONS
  // =========================================================================

  const createPlan = useCallback(
    async (input: {
      name: string;
      propertyId?: string;
      jobId?: string;
    }) => {
      try {
        const supabase = getSupabase();

        // Get company_id from JWT — required NOT NULL column
        const { data: { user } } = await supabase.auth.getUser();
        const companyId = user?.app_metadata?.company_id;
        if (!companyId) {
          setError('No company context — please log in again');
          return null;
        }

        const { data, error: createError } = await supabase
          .from('property_floor_plans')
          .insert({
            company_id: companyId,
            name: input.name,
            property_id: input.propertyId || null,
            job_id: input.jobId || null,
            plan_data: createEmptyFloorPlan() as unknown as Record<
              string,
              unknown
            >,
            status: 'draft',
            floor_level: 1,
            floor_number: 1,
          })
          .select()
          .single();

        if (createError) throw createError;
        return data?.id as string;
      } catch (err) {
        setError(
          err instanceof Error ? err.message : 'Failed to create plan',
        );
        return null;
      }
    },
    [],
  );

  const updatePlanName = useCallback(
    async (name: string) => {
      if (!planId) return;
      const supabase = getSupabase();
      await supabase
        .from('property_floor_plans')
        .update({ name })
        .eq('id', planId);
    },
    [planId],
  );

  const deletePlan = useCallback(
    async (id?: string) => {
      const targetId = id || planId;
      if (!targetId) return false;
      try {
        const supabase = getSupabase();
        const { error: deleteError } = await supabase
          .from('property_floor_plans')
          .update({ deleted_at: new Date().toISOString() })
          .eq('id', targetId);
        if (deleteError) throw deleteError;
        return true;
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to delete plan');
        return false;
      }
    },
    [planId],
  );

  const duplicatePlan = useCallback(
    async (id?: string) => {
      const targetId = id || planId;
      if (!targetId) return null;
      try {
        const supabase = getSupabase();
        // Fetch source plan
        const { data: source, error: fetchErr } = await supabase
          .from('property_floor_plans')
          .select('*')
          .eq('id', targetId)
          .single();
        if (fetchErr || !source) throw fetchErr || new Error('Plan not found');
        // Create copy
        const { data: copy, error: copyErr } = await supabase
          .from('property_floor_plans')
          .insert({
            company_id: source.company_id,
            name: `${source.name} (Copy)`,
            property_id: source.property_id,
            job_id: source.job_id,
            plan_data: source.plan_data,
            status: 'draft',
            floor_level: source.floor_level,
            floor_number: source.floor_number,
          })
          .select()
          .single();
        if (copyErr) throw copyErr;
        return copy?.id as string;
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to duplicate plan');
        return null;
      }
    },
    [planId],
  );

  const updatePlanJob = useCallback(
    async (jobId: string | null, targetId?: string) => {
      const id = targetId || planId;
      if (!id) return;
      const supabase = getSupabase();
      await supabase
        .from('property_floor_plans')
        .update({ job_id: jobId })
        .eq('id', id);
    },
    [planId],
  );

  // Cleanup
  useEffect(() => {
    return () => {
      if (saveTimerRef.current) {
        clearTimeout(saveTimerRef.current);
      }
    };
  }, []);

  return {
    plan,
    layers,
    rooms,
    loading,
    error,
    saving,
    savePlanData,
    createPlan,
    updatePlanName,
    deletePlan,
    duplicatePlan,
    updatePlanJob,
    refetch: fetchPlan,
  };
}

// =============================================================================
// LIST HOOK — All floor plans for current company
// =============================================================================

export interface FloorPlanListItem {
  id: string;
  name: string;
  status: string;
  floorLevel: number;
  wallCount: number;
  roomCount: number;
  jobId: string | null;
  propertyId: string | null;
  createdAt: string;
  updatedAt: string;
}

export function useFloorPlanList() {
  const [plans, setPlans] = useState<FloorPlanListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPlans = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: fetchError } = await supabase
        .from('property_floor_plans')
        .select('id, name, status, floor_level, plan_data, job_id, property_id, created_at, updated_at')
        .is('deleted_at', null)
        .order('updated_at', { ascending: false })
        .limit(100);

      if (fetchError) throw fetchError;

      setPlans(
        (data || []).map((row: Record<string, unknown>) => {
          const pd = row.plan_data as Record<string, unknown> | null;
          const walls = pd?.walls as unknown[] | undefined;
          const rooms = pd?.rooms as unknown[] | undefined;
          return {
            id: row.id as string,
            name: (row.name as string) || 'Untitled',
            status: (row.status as string) || 'draft',
            floorLevel: (row.floor_level as number) || 1,
            wallCount: walls?.length ?? 0,
            roomCount: rooms?.length ?? 0,
            jobId: (row.job_id as string) || null,
            propertyId: (row.property_id as string) || null,
            createdAt: row.created_at as string,
            updatedAt: row.updated_at as string,
          };
        }),
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load plans');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPlans();

    const supabase = getSupabase();
    const channel = supabase
      .channel('floor-plans-list')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'property_floor_plans' },
        () => fetchPlans(),
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchPlans]);

  return { plans, loading, error, refetch: fetchPlans };
}
