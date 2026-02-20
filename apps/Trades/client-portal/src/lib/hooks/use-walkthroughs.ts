'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// ==================== TYPES ====================

export interface WalkthroughData {
  id: string;
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
  conditionTags: string[];
  materialTags: string[];
  notes: string;
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
    name: row.name as string || '',
    walkthroughType: row.walkthrough_type as string || 'general',
    status: row.status as string || 'draft',
    address: row.address as string || '',
    totalRooms: (row.room_count as number) || 0,
    totalPhotos: (row.photo_count as number) || 0,
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
    conditionTags: (row.condition_tags as string[]) || [],
    materialTags: (row.material_tags as string[]) || [],
    notes: row.notes as string || '',
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

  const fetchWalkthroughs = useCallback(async () => {
    if (!profile?.customerId) { setLoading(false); return; }
    const supabase = getSupabase();

    const { data } = await supabase
      .from('walkthroughs')
      .select('*')
      .eq('customer_id', profile.customerId)
      .is('deleted_at', null)
      .in('status', ['completed', 'uploaded', 'reviewed'])
      .order('created_at', { ascending: false });

    setWalkthroughs((data || []).map(mapWalkthrough));
    setLoading(false);
  }, [profile?.customerId]);

  useEffect(() => {
    fetchWalkthroughs();
  }, [fetchWalkthroughs]);

  return { walkthroughs, loading };
}

export function useWalkthrough(id: string) {
  const { profile } = useAuth();
  const [walkthrough, setWalkthrough] = useState<WalkthroughData | null>(null);
  const [rooms, setRooms] = useState<WalkthroughRoomData[]>([]);
  const [photos, setPhotos] = useState<WalkthroughPhotoData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetch() {
      if (!profile?.customerId) {
        setError('Not authenticated');
        setLoading(false);
        return;
      }
      const supabase = getSupabase();

      const [wtRes, roomsRes, photosRes] = await Promise.all([
        supabase.from('walkthroughs').select('*').eq('id', id).eq('customer_id', profile.customerId).single(),
        supabase.from('walkthrough_rooms').select('*').eq('walkthrough_id', id).order('name'),
        supabase.from('walkthrough_photos').select('*').eq('walkthrough_id', id).order('sort_order'),
      ]);

      if (wtRes.error) {
        setError(wtRes.error.message);
        setLoading(false);
        return;
      }

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

      setPhotos(withUrls);
      setLoading(false);
    }
    fetch();
  }, [id, profile?.customerId]);

  return { walkthrough, rooms, photos, loading, error };
}
