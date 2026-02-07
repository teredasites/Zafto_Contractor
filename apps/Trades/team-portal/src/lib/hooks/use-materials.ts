'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapMaterial, type MaterialData } from './mappers';

export function useMaterials(jobId?: string) {
  const [materials, setMaterials] = useState<MaterialData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchMaterials = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      let query = supabase.from('job_materials').select('*').is('deleted_at', null).order('created_at', { ascending: false });
      if (jobId) query = query.eq('job_id', jobId);
      const { data, error: err } = await query;

      if (err) throw err;
      setMaterials((data || []).map(mapMaterial));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load materials';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetchMaterials();
    const supabase = getSupabase();
    const channel = supabase.channel('team-materials')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'job_materials' }, () => fetchMaterials())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchMaterials]);

  const addMaterial = async (data: Partial<MaterialData> & { jobId: string }) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const { error: err } = await supabase.from('job_materials').insert({
        job_id: data.jobId,
        company_id: user.app_metadata?.company_id,
        added_by_user_id: user.id,
        name: data.name, description: data.description || '',
        category: data.category || 'material', quantity: data.quantity || 1,
        unit: data.unit || 'each', unit_cost: data.unitCost || 0,
        is_billable: data.isBillable ?? true, vendor: data.vendor || '',
      });

      if (err) throw err;
      fetchMaterials();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to add material';
      setError(msg);
      throw e;
    }
  };

  const totalCost = materials.reduce((sum, m) => sum + m.totalCost, 0);

  return { materials, loading, error, addMaterial, totalCost };
}
