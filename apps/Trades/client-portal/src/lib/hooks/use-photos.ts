'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export type PhotoCategory = 'general' | 'before' | 'after' | 'defect' | 'markup' | 'receipt' | 'inspection' | 'completion';

export interface PhotoData {
  id: string;
  jobId: string;
  storagePath: string;
  fileName: string;
  category: PhotoCategory;
  caption: string;
  takenAt: string | null;
  createdAt: string;
  signedUrl?: string;
}

function mapPhoto(row: Record<string, unknown>): PhotoData {
  return {
    id: row.id as string,
    jobId: (row.job_id as string) || '',
    storagePath: (row.storage_path as string) || '',
    fileName: (row.file_name as string) || '',
    category: (row.category as PhotoCategory) || 'general',
    caption: (row.caption as string) || '',
    takenAt: (row.taken_at as string) || null,
    createdAt: (row.created_at as string) || '',
  };
}

/**
 * Client-facing photo gallery — read-only, client-visible photos only.
 * Homeowners can see before/after photos and progress documentation.
 */
export function usePhotos(jobId: string) {
  const [photos, setPhotos] = useState<PhotoData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPhotos = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('photos')
        .select('id, job_id, storage_path, file_name, category, caption, taken_at, created_at')
        .eq('job_id', jobId)
        .eq('is_client_visible', true)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });
      if (err) throw err;

      const mapped = (data || []).map(mapPhoto);

      // Generate signed URLs
      const withUrls = await Promise.all(
        mapped.map(async (p: PhotoData) => {
          try {
            if (!p.storagePath) return p;
            const { data: urlData } = await supabase.storage
              .from('photos')
              .createSignedUrl(p.storagePath, 3600);
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
  }, [fetchPhotos]);

  const byCategory = (category: PhotoCategory) =>
    photos.filter(p => p.category === category);

  const beforePhotos = byCategory('before');
  const afterPhotos = byCategory('after');

  return { photos, loading, error, byCategory, beforePhotos, afterPhotos, refresh: fetchPhotos };
}
