'use client';

import { useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface PhotoCluster {
  cluster_id: number;
  center_lat: number;
  center_lng: number;
  avg_heading: number;
  floor_level: string | null;
  photo_count: number;
  photo_ids: string[];
}

export function usePhotoClusters() {
  const [clusters, setClusters] = useState<PhotoCluster[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const clusterPhotos = useCallback(
    async (walkthroughId: string, radiusMeters: number = 3.0) => {
      try {
        setLoading(true);
        setError(null);

        const supabase = getSupabase();
        const { data, error: err } = await supabase.rpc(
          'cluster_walkthrough_photos',
          {
            p_walkthrough_id: walkthroughId,
            p_radius_meters: radiusMeters,
          }
        );

        if (err) throw err;
        setClusters((data as PhotoCluster[]) || []);
        return (data as PhotoCluster[]) || [];
      } catch (e: unknown) {
        const msg =
          e instanceof Error ? e.message : 'Failed to cluster photos';
        setError(msg);
        return [];
      } finally {
        setLoading(false);
      }
    },
    []
  );

  return { clusters, loading, error, clusterPhotos };
}
