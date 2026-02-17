'use client';

import { useEffect, useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase';

export interface ApplianceServiceLog {
  id: string;
  company_id: string;
  job_id: string | null;
  property_id: string | null;
  appliance_type: string;
  brand: string | null;
  model_number: string | null;
  serial_number: string | null;
  manufacture_date: string | null;
  purchase_date: string | null;
  warranty_status: string | null;
  error_code: string | null;
  error_description: string | null;
  symptoms: string[];
  diagnostic_steps: Record<string, unknown>[];
  diagnosis: string | null;
  work_performed: string | null;
  parts_used: Record<string, unknown>[];
  repair_vs_replace: string | null;
  estimated_remaining_life_years: number | null;
  estimated_repair_cost: number | null;
  estimated_replace_cost: number | null;
  photos: string[];
  labor_minutes: number | null;
  parts_cost: number | null;
  labor_cost: number | null;
  total_cost: number | null;
  technician_name: string | null;
  notes: string | null;
  created_at: string;
}

export const APPLIANCE_TYPE_LABELS: Record<string, string> = {
  refrigerator: 'Refrigerator', washer: 'Washer', dryer: 'Dryer',
  dishwasher: 'Dishwasher', oven: 'Oven', range: 'Range',
  microwave: 'Microwave', garbage_disposal: 'Garbage Disposal',
  ice_maker: 'Ice Maker', wine_cooler: 'Wine Cooler',
  trash_compactor: 'Trash Compactor', range_hood: 'Range Hood',
  freezer: 'Freezer', cooktop: 'Cooktop',
};

export const REPAIR_VS_REPLACE_LABELS: Record<string, string> = {
  repair: 'Repair', replace: 'Replace',
  customer_choice: 'Customer Choice', not_economical: 'Not Economical',
};

export function useApplianceRepairLogs() {
  const supabase = createClient();
  const [logs, setLogs] = useState<ApplianceServiceLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const { data, error: err } = await supabase
        .from('appliance_service_logs')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });
      if (err) throw err;
      setLogs((data ?? []) as ApplianceServiceLog[]);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  useEffect(() => {
    fetch();
    const channel = supabase
      .channel('appliance_rt')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'appliance_service_logs' }, () => { fetch(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [supabase, fetch]);

  const create = useCallback(async (payload: Partial<ApplianceServiceLog>) => {
    const { data, error: err } = await supabase.from('appliance_service_logs').insert(payload).select().single();
    if (err) throw err;
    return data as ApplianceServiceLog;
  }, [supabase]);

  return { logs, loading, error, refetch: fetch, create };
}
