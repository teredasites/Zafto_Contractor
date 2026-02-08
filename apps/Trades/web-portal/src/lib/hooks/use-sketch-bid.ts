'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface BidSketch {
  id: string;
  companyId: string;
  jobId: string | null;
  jobTitle?: string;
  estimateId: string | null;
  title: string;
  description: string | null;
  status: string;
  totalSqft: number;
  totalRooms: number;
  sketchData: Record<string, unknown>;
  metadata: Record<string, unknown>;
  locationLat: number | null;
  locationLng: number | null;
  address: string | null;
  createdByUserId: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface SketchRoom {
  id: string;
  companyId: string;
  sketchId: string;
  roomName: string;
  roomType: string;
  floorLevel: string;
  sortOrder: number;
  lengthFt: number | null;
  widthFt: number | null;
  heightFt: number | null;
  sqft: number | null;
  ceilingType: string;
  windowCount: number;
  doorCount: number;
  hasDamage: boolean;
  damageAreas: Array<{ type: string; severity: string; location: string; notes?: string }>;
  damageClass: string | null;
  damageCategory: string | null;
  linkedItems: Array<{ item_id: string; zafto_code: string; quantity: number; unit: string; action: string }>;
  estimatedTotal: number;
  photos: Array<{ path: string; caption?: string }>;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

function mapSketch(row: Record<string, unknown>): BidSketch {
  const job = row.jobs as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    jobId: (row.job_id as string) || null,
    jobTitle: (job?.title as string) || undefined,
    estimateId: (row.estimate_id as string) || null,
    title: row.title as string,
    description: (row.description as string) || null,
    status: row.status as string,
    totalSqft: (row.total_sqft as number) || 0,
    totalRooms: (row.total_rooms as number) || 0,
    sketchData: (row.sketch_data as Record<string, unknown>) || {},
    metadata: (row.metadata as Record<string, unknown>) || {},
    locationLat: (row.location_lat as number) || null,
    locationLng: (row.location_lng as number) || null,
    address: (row.address as string) || null,
    createdByUserId: (row.created_by_user_id as string) || null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapRoom(row: Record<string, unknown>): SketchRoom {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    sketchId: row.sketch_id as string,
    roomName: row.room_name as string,
    roomType: (row.room_type as string) || 'room',
    floorLevel: (row.floor_level as string) || 'main',
    sortOrder: (row.sort_order as number) || 0,
    lengthFt: (row.length_ft as number) || null,
    widthFt: (row.width_ft as number) || null,
    heightFt: (row.height_ft as number) || null,
    sqft: (row.sqft as number) || null,
    ceilingType: (row.ceiling_type as string) || 'flat',
    windowCount: (row.window_count as number) || 0,
    doorCount: (row.door_count as number) || 0,
    hasDamage: (row.has_damage as boolean) || false,
    damageAreas: (row.damage_areas as SketchRoom['damageAreas']) || [],
    damageClass: (row.damage_class as string) || null,
    damageCategory: (row.damage_category as string) || null,
    linkedItems: (row.linked_items as SketchRoom['linkedItems']) || [],
    estimatedTotal: (row.estimated_total as number) || 0,
    photos: (row.photos as SketchRoom['photos']) || [],
    notes: (row.notes as string) || null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

export function useSketchBid() {
  const [sketches, setSketches] = useState<BidSketch[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSketches = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: fetchError } = await supabase
        .from('bid_sketches')
        .select('*, jobs(title)')
        .order('created_at', { ascending: false })
        .limit(100);

      if (fetchError) throw fetchError;
      setSketches((data || []).map(mapSketch));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load sketches');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSketches();

    const supabase = getSupabase();
    const channel = supabase
      .channel('bid-sketches-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bid_sketches' }, () => fetchSketches())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchSketches]);

  const getRooms = async (sketchId: string): Promise<SketchRoom[]> => {
    const supabase = getSupabase();
    const { data, error: fetchError } = await supabase
      .from('sketch_rooms')
      .select('*')
      .eq('sketch_id', sketchId)
      .order('sort_order');
    if (fetchError) throw fetchError;
    return (data || []).map(mapRoom);
  };

  const createSketch = async (sketch: { title: string; jobId?: string; estimateId?: string; address?: string; description?: string }) => {
    const supabase = getSupabase();
    const { data, error: insertError } = await supabase
      .from('bid_sketches')
      .insert({
        title: sketch.title,
        job_id: sketch.jobId || null,
        estimate_id: sketch.estimateId || null,
        address: sketch.address || null,
        description: sketch.description || null,
      })
      .select()
      .single();
    if (insertError) throw insertError;
    await fetchSketches();
    return mapSketch(data);
  };

  const addRoom = async (sketchId: string, room: { roomName: string; roomType: string; floorLevel?: string; lengthFt?: number; widthFt?: number; heightFt?: number }) => {
    const supabase = getSupabase();
    const sqft = room.lengthFt && room.widthFt ? room.lengthFt * room.widthFt : null;
    const { error: insertError } = await supabase
      .from('sketch_rooms')
      .insert({
        sketch_id: sketchId,
        room_name: room.roomName,
        room_type: room.roomType,
        floor_level: room.floorLevel || 'main',
        length_ft: room.lengthFt || null,
        width_ft: room.widthFt || null,
        height_ft: room.heightFt || 8.0,
        sqft,
      });
    if (insertError) throw insertError;
  };

  const updateSketchStatus = async (sketchId: string, status: string) => {
    const supabase = getSupabase();
    const { error: updateError } = await supabase
      .from('bid_sketches')
      .update({ status })
      .eq('id', sketchId);
    if (updateError) throw updateError;
    await fetchSketches();
  };

  const drafts = sketches.filter(s => s.status === 'draft');
  const inProgress = sketches.filter(s => s.status === 'in_progress');
  const completed = sketches.filter(s => s.status === 'completed' || s.status === 'submitted');

  return {
    sketches, drafts, inProgress, completed,
    loading, error, fetchSketches,
    getRooms, createSketch, addRoom, updateSketchStatus,
  };
}
