'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export type PhotoCategory = 'general' | 'before' | 'after' | 'defect' | 'markup' | 'receipt' | 'inspection' | 'completion';

export interface PhotoData {
  id: string;
  companyId: string;
  jobId: string;
  uploadedByUserId: string;
  storagePath: string;
  thumbnailPath: string | null;
  fileName: string;
  fileSize: number;
  mimeType: string;
  width: number | null;
  height: number | null;
  category: PhotoCategory;
  caption: string;
  tags: string[];
  metadata: Record<string, unknown>;
  isClientVisible: boolean;
  takenAt: string | null;
  latitude: number | null;
  longitude: number | null;
  createdAt: string;
  signedUrl?: string;
}

function mapPhoto(row: Record<string, unknown>): PhotoData {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    jobId: (row.job_id as string) || '',
    uploadedByUserId: (row.uploaded_by_user_id as string) || '',
    storagePath: (row.storage_path as string) || '',
    thumbnailPath: (row.thumbnail_path as string) || null,
    fileName: (row.file_name as string) || '',
    fileSize: (row.file_size as number) || 0,
    mimeType: (row.mime_type as string) || '',
    width: (row.width as number) ?? null,
    height: (row.height as number) ?? null,
    category: (row.category as PhotoCategory) || 'general',
    caption: (row.caption as string) || '',
    tags: (row.tags as string[]) || [],
    metadata: (row.metadata as Record<string, unknown>) || {},
    isClientVisible: (row.is_client_visible as boolean) ?? false,
    takenAt: (row.taken_at as string) || null,
    latitude: (row.latitude as number) ?? null,
    longitude: (row.longitude as number) ?? null,
    createdAt: (row.created_at as string) || '',
  };
}

export function usePhotos(jobId?: string) {
  const [photos, setPhotos] = useState<PhotoData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPhotos = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      let query = supabase
        .from('photos')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });
      if (jobId) query = query.eq('job_id', jobId);
      const { data, error: err } = await query;
      if (err) throw err;

      const mapped = (data || []).map(mapPhoto);

      // Generate signed URLs for thumbnails or full images
      const withUrls = await Promise.all(
        mapped.map(async (p: PhotoData) => {
          try {
            const path = p.thumbnailPath || p.storagePath;
            if (!path) return p;
            const { data: urlData } = await supabase.storage
              .from('photos')
              .createSignedUrl(path, 3600);
            return { ...p, signedUrl: urlData?.signedUrl || '' };
          } catch {
            return p;
          }
        })
      );

      setPhotos(withUrls);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load photos');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetchPhotos();
    const supabase = getSupabase();
    const channel = supabase
      .channel('crm-photos')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'photos' }, () => fetchPhotos())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchPhotos]);

  const updatePhoto = async (photoId: string, updates: {
    caption?: string;
    category?: PhotoCategory;
    tags?: string[];
    isClientVisible?: boolean;
  }) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const payload: Record<string, unknown> = {};
      if (updates.caption !== undefined) payload.caption = updates.caption;
      if (updates.category !== undefined) payload.category = updates.category;
      if (updates.tags !== undefined) payload.tags = updates.tags;
      if (updates.isClientVisible !== undefined) payload.is_client_visible = updates.isClientVisible;

      const { error: err } = await supabase
        .from('photos')
        .update(payload)
        .eq('id', photoId);
      if (err) throw err;
      await fetchPhotos();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to update photo');
      throw e;
    }
  };

  const deletePhoto = async (photoId: string) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('photos')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', photoId);
      if (err) throw err;
      await fetchPhotos();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to delete photo');
      throw e;
    }
  };

  const toggleClientVisible = async (photoId: string, visible: boolean) => {
    return updatePhoto(photoId, { isClientVisible: visible });
  };

  const byCategory = (category: PhotoCategory) =>
    photos.filter(p => p.category === category);

  const beforePhotos = byCategory('before');
  const afterPhotos = byCategory('after');
  const defectPhotos = byCategory('defect');
  const clientVisiblePhotos = photos.filter(p => p.isClientVisible);

  return {
    photos,
    loading,
    error,
    updatePhoto,
    deletePhoto,
    toggleClientVisible,
    byCategory,
    beforePhotos,
    afterPhotos,
    defectPhotos,
    clientVisiblePhotos,
    refresh: fetchPhotos,
  };
}
