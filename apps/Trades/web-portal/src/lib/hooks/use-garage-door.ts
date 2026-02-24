'use client';

import { useEffect, useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface GarageDoorServiceLog {
  id: string;
  company_id: string;
  job_id: string | null;
  property_id: string | null;
  door_type: string;
  door_width_inches: number | null;
  door_height_inches: number | null;
  panel_material: string | null;
  insulation_r_value: number | null;
  track_type: string | null;
  opener_brand: string | null;
  opener_model: string | null;
  opener_type: string | null;
  opener_hp: number | null;
  spring_type: string | null;
  spring_wire_size: number | null;
  spring_length: number | null;
  spring_inside_diameter: number | null;
  spring_cycles_rating: number | null;
  spring_wind_direction: string | null;
  service_type: string;
  symptoms: string[];
  safety_sensor_status: string | null;
  balance_test_result: string | null;
  force_setting_up: number | null;
  force_setting_down: number | null;
  diagnosis: string | null;
  work_performed: string | null;
  parts_used: Record<string, unknown>[];
  photos: string[];
  labor_minutes: number | null;
  parts_cost: number | null;
  labor_cost: number | null;
  total_cost: number | null;
  technician_name: string | null;
  notes: string | null;
  created_at: string;
}

export const GARAGE_DOOR_SERVICE_LABELS: Record<string, string> = {
  spring_replacement: 'Spring Replacement', opener_repair: 'Opener Repair',
  opener_install: 'Opener Install', panel_replacement: 'Panel Replacement',
  cable_repair: 'Cable Repair', track_alignment: 'Track Alignment',
  roller_replacement: 'Roller Replacement', weatherseal: 'Weatherseal',
  safety_sensor: 'Safety Sensor', full_door_install: 'Full Door Install',
  balance_adjustment: 'Balance Adjustment', annual_maintenance: 'Annual Maintenance',
};

export const DOOR_TYPE_LABELS: Record<string, string> = {
  sectional: 'Sectional', roll_up: 'Roll-Up', tilt_up: 'Tilt-Up',
  slide: 'Slide', commercial_rolling_steel: 'Commercial Rolling Steel',
  carriage: 'Carriage', modern_aluminum: 'Modern Aluminum', full_view: 'Full View',
};

export function useGarageDoorLogs() {
  const supabase = getSupabase();
  const [logs, setLogs] = useState<GarageDoorServiceLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const { data, error: err } = await supabase
        .from('garage_door_service_logs')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });
      if (err) throw err;
      setLogs((data ?? []) as GarageDoorServiceLog[]);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  useEffect(() => {
    fetch();
    const channel = supabase
      .channel('garage_door_rt')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'garage_door_service_logs' }, () => { fetch(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [supabase, fetch]);

  const create = useCallback(async (payload: Partial<GarageDoorServiceLog>) => {
    const { data, error: err } = await supabase.from('garage_door_service_logs').insert(payload).select().single();
    if (err) throw err;
    return data as GarageDoorServiceLog;
  }, [supabase]);

  return { logs, loading, error, refetch: fetch, create };
}
