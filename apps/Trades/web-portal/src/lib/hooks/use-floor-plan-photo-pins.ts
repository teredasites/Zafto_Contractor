'use client';

// ZAFTO Floor Plan Photo Pins Hook — SK7
// CRUD for floor_plan_photo_pins table.
// Pin photos to specific x,y coordinates on the floor plan.
// Upload photos to Supabase Storage, link with position data.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// =============================================================================
// INTERFACES
// =============================================================================

export interface FloorPlanPhotoPin {
  id: string;
  floorPlanId: string;
  companyId: string;
  photoId: string | null;
  photoPath: string | null;
  positionX: number;
  positionY: number;
  roomId: string | null;
  label: string | null;
  pinType: string;
  createdBy: string | null;
  createdAt: string;
  updatedAt: string;
}

// =============================================================================
// MAPPER
// =============================================================================

function mapPhotoPin(row: Record<string, unknown>): FloorPlanPhotoPin {
  return {
    id: row.id as string,
    floorPlanId: row.floor_plan_id as string,
    companyId: row.company_id as string,
    photoId: (row.photo_id as string) || null,
    photoPath: (row.photo_path as string) || null,
    positionX: (row.position_x as number) || 0,
    positionY: (row.position_y as number) || 0,
    roomId: (row.room_id as string) || null,
    label: (row.label as string) || null,
    pinType: (row.pin_type as string) || 'photo',
    createdBy: (row.created_by as string) || null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

// =============================================================================
// HOOK
// =============================================================================

export function useFloorPlanPhotoPins(floorPlanId: string | null) {
  const [pins, setPins] = useState<FloorPlanPhotoPin[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // =========================================================================
  // FETCH
  // =========================================================================

  const fetchPins = useCallback(async () => {
    if (!floorPlanId) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: fetchError } = await supabase
        .from('floor_plan_photo_pins')
        .select('*')
        .eq('floor_plan_id', floorPlanId)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;
      setPins((data || []).map((r: Record<string, unknown>) => mapPhotoPin(r)));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load photo pins');
    } finally {
      setLoading(false);
    }
  }, [floorPlanId]);

  useEffect(() => {
    fetchPins();
  }, [fetchPins]);

  // =========================================================================
  // REAL-TIME
  // =========================================================================

  useEffect(() => {
    if (!floorPlanId) return;
    const supabase = getSupabase();

    const channel = supabase
      .channel(`photo_pins_${floorPlanId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'floor_plan_photo_pins',
          filter: `floor_plan_id=eq.${floorPlanId}`,
        },
        () => fetchPins(),
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [floorPlanId, fetchPins]);

  // =========================================================================
  // MUTATIONS
  // =========================================================================

  const createPin = useCallback(
    async (input: {
      positionX: number;
      positionY: number;
      roomId?: string;
      label?: string;
      pinType?: string;
    }) => {
      if (!floorPlanId) return null;

      try {
        const supabase = getSupabase();
        const { data: { user } } = await supabase.auth.getUser();
        const companyId = user?.app_metadata?.company_id;
        if (!companyId) return null;

        const { data, error: createError } = await supabase
          .from('floor_plan_photo_pins')
          .insert({
            floor_plan_id: floorPlanId,
            company_id: companyId,
            position_x: input.positionX,
            position_y: input.positionY,
            room_id: input.roomId || null,
            label: input.label || null,
            pin_type: input.pinType || 'photo',
          })
          .select()
          .single();

        if (createError) throw createError;
        if (data) {
          const pin = mapPhotoPin(data);
          setPins((prev) => [pin, ...prev]);
          return pin;
        }
        return null;
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to create pin');
        return null;
      }
    },
    [floorPlanId],
  );

  const uploadPhotoToPin = useCallback(
    async (pinId: string, file: File) => {
      try {
        const supabase = getSupabase();
        const { data: { user } } = await supabase.auth.getUser();
        const companyId = user?.app_metadata?.company_id;
        if (!companyId) return false;

        // Upload file to storage
        const timestamp = Date.now();
        const storagePath = `${companyId}/floor-plan-photos/${floorPlanId}/${timestamp}_${file.name}`;

        const { error: uploadError } = await supabase.storage
          .from('photos')
          .upload(storagePath, file, {
            cacheControl: '3600',
            upsert: false,
          });

        if (uploadError) throw uploadError;

        // Update pin with photo path
        const { error: updateError } = await supabase
          .from('floor_plan_photo_pins')
          .update({ photo_path: storagePath })
          .eq('id', pinId);

        if (updateError) throw updateError;

        setPins((prev) =>
          prev.map((p) =>
            p.id === pinId ? { ...p, photoPath: storagePath } : p,
          ),
        );

        return true;
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to upload photo');
        return false;
      }
    },
    [floorPlanId],
  );

  const updatePin = useCallback(
    async (pinId: string, updates: { label?: string; photoPath?: string }) => {
      try {
        const supabase = getSupabase();
        const updateData: Record<string, unknown> = {};
        if (updates.label !== undefined) updateData.label = updates.label;
        if (updates.photoPath !== undefined) updateData.photo_path = updates.photoPath;
        if (Object.keys(updateData).length === 0) return;

        const { error: updateError } = await supabase
          .from('floor_plan_photo_pins')
          .update(updateData)
          .eq('id', pinId);

        if (updateError) throw updateError;

        setPins((prev) =>
          prev.map((p) =>
            p.id === pinId ? { ...p, ...updates } : p,
          ),
        );
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to update pin');
      }
    },
    [],
  );

  const deletePin = useCallback(
    async (pinId: string) => {
      try {
        const supabase = getSupabase();
        const { error: deleteError } = await supabase
          .from('floor_plan_photo_pins')
          .update({ deleted_at: new Date().toISOString() })
          .eq('id', pinId);

        if (deleteError) throw deleteError;
        setPins((prev) => prev.filter((p) => p.id !== pinId));
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to delete pin');
      }
    },
    [],
  );

  const getPhotoUrl = useCallback(
    async (photoPath: string): Promise<string | null> => {
      try {
        const supabase = getSupabase();
        const { data } = await supabase.storage
          .from('photos')
          .createSignedUrl(photoPath, 3600);

        return data?.signedUrl || null;
      } catch {
        return null;
      }
    },
    [],
  );

  return {
    pins,
    loading,
    error,
    createPin,
    uploadPhotoToPin,
    updatePin,
    deletePin,
    getPhotoUrl,
    refetch: fetchPins,
  };
}
