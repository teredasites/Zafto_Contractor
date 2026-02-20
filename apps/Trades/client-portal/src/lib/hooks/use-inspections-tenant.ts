'use client';

import { useState, useEffect } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import { useTenant } from './use-tenant';
import {
  mapInspection, mapInspectionItem,
  type InspectionData, type InspectionItemData,
} from './tenant-mappers';

export function useInspections() {
  const { user } = useAuth();
  const { tenant, lease } = useTenant();
  const [inspections, setInspections] = useState<InspectionData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetch() {
      if (!user || !tenant || !lease) { setLoading(false); return; }
      const supabase = getSupabase();

      // pm_inspections filtered by unit_id from current lease
      const { data } = await supabase
        .from('pm_inspections')
        .select('*')
        .eq('unit_id', lease.unitId)
        .in('status', ['completed'])
        .is('deleted_at', null)
        .order('inspection_date', { ascending: false });

      setInspections((data || []).map(mapInspection));
      setLoading(false);
    }
    fetch();
  }, [user, tenant, lease]);

  return { inspections, loading };
}

export function useInspection(id: string) {
  const { user } = useAuth();
  const [inspection, setInspection] = useState<InspectionData | null>(null);
  const [items, setItems] = useState<InspectionItemData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetch() {
      if (!user) { setLoading(false); return; }
      const supabase = getSupabase();

      const [inspRes, itemsRes] = await Promise.all([
        supabase.from('pm_inspections').select('*').eq('id', id).is('deleted_at', null).single(),
        supabase.from('pm_inspection_items').select('*').eq('inspection_id', id).is('deleted_at', null).order('area'),
      ]);

      if (inspRes.data) setInspection(mapInspection(inspRes.data));
      setItems((itemsRes.data || []).map(mapInspectionItem));
      setLoading(false);
    }
    fetch();
  }, [id, user]);

  return { inspection, items, loading };
}
