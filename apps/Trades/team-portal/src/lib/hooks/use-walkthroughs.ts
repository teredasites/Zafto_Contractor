'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// ==================== TYPES ====================

export interface WalkthroughData {
  id: string;
  companyId: string;
  createdBy: string;
  customerId: string | null;
  jobId: string | null;
  propertyId: string | null;
  name: string;
  walkthroughType: string;
  status: string;
  address: string;
  totalRooms: number;
  totalPhotos: number;
  notes: string;
  createdAt: string;
}

export interface WalkthroughRoomData {
  id: string;
  walkthroughId: string;
  name: string;
  roomType: string;
  floorLevel: string;
  dimensions: { length?: number; width?: number; height?: number; area?: number } | null;
  conditionRating: number | null;
  notes: string;
  status: string;
  photoCount: number;
}

export interface WalkthroughPhotoData {
  id: string;
  walkthroughId: string;
  roomId: string | null;
  storagePath: string;
  caption: string;
  photoType: string;
  annotations: Record<string, unknown>[] | null;
  sortOrder: number;
  signedUrl?: string;
}

// ==================== MAPPERS ====================

function mapWalkthrough(row: Record<string, unknown>): WalkthroughData {
  return {
    id: row.id as string,
    companyId: row.company_id as string || '',
    createdBy: row.created_by as string || '',
    customerId: row.customer_id as string || null,
    jobId: row.job_id as string || null,
    propertyId: row.property_id as string || null,
    name: row.name as string || '',
    walkthroughType: row.walkthrough_type as string || 'general',
    status: row.status as string || 'draft',
    address: row.address as string || '',
    totalRooms: (row.total_rooms as number) || 0,
    totalPhotos: (row.total_photos as number) || 0,
    notes: row.notes as string || '',
    createdAt: row.created_at as string || '',
  };
}

function mapRoom(row: Record<string, unknown>): WalkthroughRoomData {
  return {
    id: row.id as string,
    walkthroughId: row.walkthrough_id as string || '',
    name: row.name as string || '',
    roomType: row.room_type as string || '',
    floorLevel: row.floor_level as string || '',
    dimensions: row.dimensions as WalkthroughRoomData['dimensions'] || null,
    conditionRating: row.condition_rating as number | null,
    notes: row.notes as string || '',
    status: row.status as string || 'pending',
    photoCount: (row.photo_count as number) || 0,
  };
}

function mapPhoto(row: Record<string, unknown>): WalkthroughPhotoData {
  return {
    id: row.id as string,
    walkthroughId: row.walkthrough_id as string || '',
    roomId: row.room_id as string || null,
    storagePath: row.storage_path as string || '',
    caption: row.caption as string || '',
    photoType: row.photo_type as string || '',
    annotations: row.annotations as Record<string, unknown>[] || null,
    sortOrder: (row.sort_order as number) || 0,
  };
}

// ==================== HOOKS ====================

export function useWalkthroughs() {
  const { profile } = useAuth();
  const [walkthroughs, setWalkthroughs] = useState<WalkthroughData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchWalkthroughs = useCallback(async () => {
    if (!profile?.companyId) { setLoading(false); return; }
    try {
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('walkthroughs')
        .select('*')
        .eq('company_id', profile.companyId)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setWalkthroughs((data || []).map(mapWalkthrough));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load walkthroughs';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [profile?.companyId]);

  useEffect(() => {
    fetchWalkthroughs();
    if (!profile?.companyId) return;

    const supabase = getSupabase();
    const channel = supabase.channel('team-walkthroughs')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'walkthroughs' }, () => fetchWalkthroughs())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchWalkthroughs, profile?.companyId]);

  return { walkthroughs, loading, error };
}

export function useWalkthrough(id: string) {
  const { profile } = useAuth();
  const [walkthrough, setWalkthrough] = useState<WalkthroughData | null>(null);
  const [rooms, setRooms] = useState<WalkthroughRoomData[]>([]);
  const [photos, setPhotos] = useState<WalkthroughPhotoData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id || !profile?.companyId) { setLoading(false); return; }

    let ignore = false;

    async function fetch() {
      try {
        setError(null);
        const supabase = getSupabase();

        const [wtRes, roomsRes, photosRes] = await Promise.all([
          supabase.from('walkthroughs').select('*').eq('id', id).single(),
          supabase.from('walkthrough_rooms').select('*').eq('walkthrough_id', id).order('name'),
          supabase.from('walkthrough_photos').select('*').eq('walkthrough_id', id).order('sort_order'),
        ]);

        if (wtRes.error) throw wtRes.error;
        if (ignore) return;

        setWalkthrough(wtRes.data ? mapWalkthrough(wtRes.data) : null);
        setRooms((roomsRes.data || []).map(mapRoom));

        // Generate signed URLs for photos
        const mappedPhotos = (photosRes.data || []).map(mapPhoto);
        const withUrls = await Promise.all(
          mappedPhotos.map(async (photo: WalkthroughPhotoData) => {
            if (!photo.storagePath) return photo;
            try {
              const { data } = await supabase.storage
                .from('walkthrough-photos')
                .createSignedUrl(photo.storagePath, 3600);
              return { ...photo, signedUrl: data?.signedUrl || '' };
            } catch {
              return photo;
            }
          })
        );

        if (!ignore) setPhotos(withUrls);
      } catch (e: unknown) {
        if (!ignore) {
          const msg = e instanceof Error ? e.message : 'Failed to load walkthrough';
          setError(msg);
        }
      } finally {
        if (!ignore) setLoading(false);
      }
    }

    fetch();
    return () => { ignore = true; };
  }, [id, profile?.companyId]);

  return { walkthrough, rooms, photos, loading, error };
}

export async function markRoomCompleted(roomId: string): Promise<void> {
  const supabase = getSupabase();
  const { error } = await supabase
    .from('walkthrough_rooms')
    .update({ status: 'completed' })
    .eq('id', roomId);
  if (error) throw error;
}
