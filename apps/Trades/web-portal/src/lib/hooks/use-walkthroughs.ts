'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ==================== INTERFACES ====================

export interface Walkthrough {
  id: string;
  companyId: string;
  createdBy: string;
  customerId: string | null;
  jobId: string | null;
  bidId: string | null;
  propertyId: string | null;
  name: string;
  walkthroughType: string;
  propertyType: string;
  address: string;
  city: string;
  state: string;
  zipCode: string;
  latitude: number | null;
  longitude: number | null;
  templateId: string | null;
  status: 'in_progress' | 'completed' | 'uploaded' | 'bid_generated' | 'archived';
  startedAt: string | null;
  completedAt: string | null;
  notes: string;
  weatherConditions: WeatherConditions | null;
  totalRooms: number;
  totalPhotos: number;
  metadata: Record<string, unknown> | null;
  createdAt: string;
  updatedAt: string;
}

export interface WeatherConditions {
  temperature?: number;
  humidity?: number;
  conditions?: string;
  windSpeed?: number;
}

export interface WalkthroughRoom {
  id: string;
  walkthroughId: string;
  name: string;
  roomType: string;
  floorLevel: string;
  sortOrder: number;
  dimensions: RoomDimensions | null;
  conditionTags: string[];
  materialTags: string[];
  notes: string;
  voiceNoteUrl: string | null;
  voiceNoteTranscript: string | null;
  photoCount: number;
  metadata: Record<string, unknown> | null;
  createdAt: string;
  updatedAt: string;
}

export interface RoomDimensions {
  length?: number;
  width?: number;
  height?: number;
  area?: number;
  perimeter?: number;
}

export interface WalkthroughPhoto {
  id: string;
  walkthroughId: string;
  roomId: string | null;
  storagePath: string;
  thumbnailPath: string | null;
  caption: string;
  photoType: 'general' | 'damage' | 'before' | 'after' | 'detail' | 'wide' | 'exterior' | 'selfie';
  annotations: Record<string, unknown>[] | null;
  aiAnalysis: Record<string, unknown> | null;
  sortOrder: number;
  metadata: Record<string, unknown> | null;
  createdAt: string;
}

export interface FloorPlan {
  id: string;
  companyId: string;
  propertyId: string | null;
  walkthroughId: string | null;
  name: string;
  floorLevel: string;
  planData: FloorPlanData | null;
  thumbnailPath: string | null;
  source: string;
  metadata: Record<string, unknown> | null;
  createdAt: string;
  updatedAt: string;
}

export interface FloorPlanData {
  walls?: Array<{ x1: number; y1: number; x2: number; y2: number }>;
  doors?: Array<{ x: number; y: number; width: number; rotation: number }>;
  windows?: Array<{ x: number; y: number; width: number; rotation: number }>;
  fixtures?: Array<{ x: number; y: number; type: string; label?: string }>;
  rooms?: Array<{ id: string; name: string; points: Array<{ x: number; y: number }>; label?: { x: number; y: number } }>;
  dimensions?: Array<{ x1: number; y1: number; x2: number; y2: number; value: string }>;
  width?: number;
  height?: number;
}

// ==================== MAPPERS ====================

export function mapWalkthroughFromDb(row: Record<string, unknown>): Walkthrough {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    createdBy: (row.created_by as string) || '',
    customerId: (row.customer_id as string) || null,
    jobId: (row.job_id as string) || null,
    bidId: (row.bid_id as string) || null,
    propertyId: (row.property_id as string) || null,
    name: (row.name as string) || '',
    walkthroughType: (row.walkthrough_type as string) || '',
    propertyType: (row.property_type as string) || '',
    address: (row.address as string) || '',
    city: (row.city as string) || '',
    state: (row.state as string) || '',
    zipCode: (row.zip_code as string) || '',
    latitude: row.latitude != null ? Number(row.latitude) : null,
    longitude: row.longitude != null ? Number(row.longitude) : null,
    templateId: (row.template_id as string) || null,
    status: (row.status as Walkthrough['status']) || 'in_progress',
    startedAt: (row.started_at as string) || null,
    completedAt: (row.completed_at as string) || null,
    notes: (row.notes as string) || '',
    weatherConditions: (row.weather_conditions as WeatherConditions) || null,
    totalRooms: Number(row.room_count) || 0,
    totalPhotos: Number(row.photo_count) || 0,
    metadata: (row.metadata as Record<string, unknown>) || null,
    createdAt: (row.created_at as string) || '',
    updatedAt: (row.updated_at as string) || '',
  };
}

export function mapWalkthroughToDb(data: Partial<Walkthrough>): Record<string, unknown> {
  const result: Record<string, unknown> = {};

  if (data.name !== undefined) result.name = data.name;
  if (data.walkthroughType !== undefined) result.walkthrough_type = data.walkthroughType;
  if (data.propertyType !== undefined) result.property_type = data.propertyType;
  if (data.address !== undefined) result.address = data.address;
  if (data.city !== undefined) result.city = data.city;
  if (data.state !== undefined) result.state = data.state;
  if (data.zipCode !== undefined) result.zip_code = data.zipCode;
  if (data.latitude !== undefined) result.latitude = data.latitude;
  if (data.longitude !== undefined) result.longitude = data.longitude;
  if (data.templateId !== undefined) result.template_id = data.templateId;
  if (data.status !== undefined) result.status = data.status;
  if (data.startedAt !== undefined) result.started_at = data.startedAt;
  if (data.completedAt !== undefined) result.completed_at = data.completedAt;
  if (data.notes !== undefined) result.notes = data.notes;
  if (data.weatherConditions !== undefined) result.weather_conditions = data.weatherConditions;
  if (data.totalRooms !== undefined) result.room_count = data.totalRooms;
  if (data.totalPhotos !== undefined) result.photo_count = data.totalPhotos;
  if (data.metadata !== undefined) result.metadata = data.metadata;
  if (data.customerId !== undefined) result.customer_id = data.customerId;
  if (data.jobId !== undefined) result.job_id = data.jobId;
  if (data.bidId !== undefined) result.bid_id = data.bidId;
  if (data.propertyId !== undefined) result.property_id = data.propertyId;

  return result;
}

function mapRoomFromDb(row: Record<string, unknown>): WalkthroughRoom {
  return {
    id: row.id as string,
    walkthroughId: (row.walkthrough_id as string) || '',
    name: (row.name as string) || '',
    roomType: (row.room_type as string) || '',
    floorLevel: (row.floor_level as string) || '',
    sortOrder: Number(row.sort_order) || 0,
    dimensions: (row.dimensions as RoomDimensions) || null,
    conditionTags: (row.condition_tags as string[]) || [],
    materialTags: (row.material_tags as string[]) || [],
    notes: (row.notes as string) || '',
    voiceNoteUrl: (row.voice_note_url as string) || null,
    voiceNoteTranscript: (row.voice_note_transcript as string) || null,
    photoCount: Number(row.photo_count) || 0,
    metadata: (row.metadata as Record<string, unknown>) || null,
    createdAt: (row.created_at as string) || '',
    updatedAt: (row.updated_at as string) || '',
  };
}

function mapPhotoFromDb(row: Record<string, unknown>): WalkthroughPhoto {
  return {
    id: row.id as string,
    walkthroughId: (row.walkthrough_id as string) || '',
    roomId: (row.room_id as string) || null,
    storagePath: (row.storage_path as string) || '',
    thumbnailPath: (row.thumbnail_path as string) || null,
    caption: (row.caption as string) || '',
    photoType: (row.photo_type as WalkthroughPhoto['photoType']) || 'general',
    annotations: (row.annotations as Record<string, unknown>[]) || null,
    aiAnalysis: (row.ai_analysis as Record<string, unknown>) || null,
    sortOrder: Number(row.sort_order) || 0,
    metadata: (row.metadata as Record<string, unknown>) || null,
    createdAt: (row.created_at as string) || '',
  };
}

function mapFloorPlanFromDb(row: Record<string, unknown>): FloorPlan {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    propertyId: (row.property_id as string) || null,
    walkthroughId: (row.walkthrough_id as string) || null,
    name: (row.name as string) || '',
    floorLevel: (row.floor_level as string) || '',
    planData: (row.plan_data as FloorPlanData) || null,
    thumbnailPath: (row.thumbnail_path as string) || null,
    source: (row.source as string) || '',
    metadata: (row.metadata as Record<string, unknown>) || null,
    createdAt: (row.created_at as string) || '',
    updatedAt: (row.updated_at as string) || '',
  };
}

// ==================== HOOKS ====================

export function useWalkthroughs() {
  const [walkthroughs, setWalkthroughs] = useState<Walkthrough[]>([]);
  const [rooms, setRooms] = useState<WalkthroughRoom[]>([]);
  const [photos, setPhotos] = useState<WalkthroughPhoto[]>([]);
  const [floorPlans, setFloorPlans] = useState<FloorPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchWalkthroughs = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('walkthroughs')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      const rows: Record<string, unknown>[] = data || [];
      setWalkthroughs(rows.map(mapWalkthroughFromDb));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load walkthroughs';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchWalkthroughs();

    const supabase = getSupabase();
    const channel = supabase
      .channel('walkthroughs-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'walkthroughs' }, () => {
        fetchWalkthroughs();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchWalkthroughs]);

  const fetchRooms = useCallback(async (walkthroughId: string) => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('walkthrough_rooms')
        .select('*')
        .eq('walkthrough_id', walkthroughId)
        .order('sort_order', { ascending: true });

      if (err) throw err;
      const rows: Record<string, unknown>[] = data || [];
      setRooms(rows.map(mapRoomFromDb));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load rooms';
      setError(msg);
    }
  }, []);

  const fetchPhotos = useCallback(async (walkthroughId: string) => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('walkthrough_photos')
        .select('*')
        .eq('walkthrough_id', walkthroughId)
        .order('sort_order', { ascending: true });

      if (err) throw err;
      const rows: Record<string, unknown>[] = data || [];
      setPhotos(rows.map(mapPhotoFromDb));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load photos';
      setError(msg);
    }
  }, []);

  const fetchFloorPlans = useCallback(async (walkthroughId: string) => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('property_floor_plans')
        .select('*')
        .eq('walkthrough_id', walkthroughId)
        .order('floor_level', { ascending: true });

      if (err) throw err;
      const rows: Record<string, unknown>[] = data || [];
      setFloorPlans(rows.map(mapFloorPlanFromDb));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load floor plans';
      setError(msg);
    }
  }, []);

  const createWalkthrough = async (data: Partial<Walkthrough>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const insertData = {
      company_id: companyId,
      created_by: user.id,
      customer_id: data.customerId || null,
      job_id: data.jobId || null,
      bid_id: data.bidId || null,
      property_id: data.propertyId || null,
      name: data.name || 'Untitled Walkthrough',
      walkthrough_type: data.walkthroughType || 'general',
      property_type: data.propertyType || 'residential',
      address: data.address || '',
      city: data.city || '',
      state: data.state || '',
      zip_code: data.zipCode || '',
      latitude: data.latitude || null,
      longitude: data.longitude || null,
      template_id: data.templateId || null,
      status: 'in_progress',
      started_at: new Date().toISOString(),
      notes: data.notes || '',
      weather_conditions: data.weatherConditions || null,
      room_count: 0,
      photo_count: 0,
      metadata: data.metadata || null,
    };

    const { data: result, error: err } = await supabase
      .from('walkthroughs')
      .insert(insertData)
      .select('id')
      .single();

    if (err) throw err;
    const row = result as { id: string };
    return row.id;
  };

  const updateWalkthrough = async (id: string, data: Partial<Walkthrough>) => {
    const supabase = getSupabase();
    const updateData = mapWalkthroughToDb(data);

    const { error: err } = await supabase
      .from('walkthroughs')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;
  };

  const deleteWalkthrough = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('walkthroughs')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);

    if (err) throw err;
  };

  const archiveWalkthrough = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('walkthroughs')
      .update({ status: 'archived' })
      .eq('id', id);

    if (err) throw err;
  };

  return {
    walkthroughs,
    rooms,
    photos,
    floorPlans,
    loading,
    error,
    fetchWalkthroughs,
    fetchRooms,
    fetchPhotos,
    fetchFloorPlans,
    createWalkthrough,
    updateWalkthrough,
    deleteWalkthrough,
    archiveWalkthrough,
  };
}

export function useWalkthrough(id: string | undefined) {
  const [walkthrough, setWalkthrough] = useState<Walkthrough | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) {
      setLoading(false);
      return;
    }

    let ignore = false;

    const fetchWalkthrough = async () => {
      try {
        setLoading(true);
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('walkthroughs')
          .select('*')
          .eq('id', id)
          .single();

        if (ignore) return;
        if (err) throw err;
        const row = data as Record<string, unknown> | null;
        setWalkthrough(row ? mapWalkthroughFromDb(row) : null);
      } catch (e: unknown) {
        if (ignore) return;
        const msg = e instanceof Error ? e.message : 'Walkthrough not found';
        setError(msg);
      } finally {
        if (!ignore) setLoading(false);
      }
    };

    fetchWalkthrough();
    return () => { ignore = true; };
  }, [id]);

  return { walkthrough, loading, error };
}
