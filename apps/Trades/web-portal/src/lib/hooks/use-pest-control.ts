'use client';

import { useEffect, useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──

export type PestServiceType = 'general_pest' | 'termite' | 'mosquito' | 'bed_bug' | 'wildlife' | 'fumigation' | 'rodent' | 'ant' | 'cockroach' | 'tick_flea' | 'spider' | 'wasp_bee' | 'bird' | 'exclusion';
export type TreatmentMethodType = 'spray' | 'bait' | 'trap' | 'fog' | 'dust' | 'granular' | 'heat' | 'fumigation' | 'exclusion' | 'monitoring';
export type ActivityLevel = 'none' | 'low' | 'moderate' | 'high' | 'critical';
export type WdiReportStatus = 'draft' | 'complete' | 'submitted' | 'accepted' | 'rejected';

export interface TreatmentLog {
  id: string;
  company_id: string;
  job_id: string | null;
  property_id: string | null;
  service_type: PestServiceType;
  treatment_type: TreatmentMethodType;
  target_pests: string[];
  chemical_name: string | null;
  epa_registration_number: string | null;
  active_ingredient: string | null;
  application_rate: string | null;
  dilution_ratio: string | null;
  amount_used: string | null;
  target_area_sqft: number | null;
  applicator_name: string | null;
  license_number: string | null;
  re_entry_time_hours: number | null;
  next_service_date: string | null;
  service_frequency: string | null;
  notes: string | null;
  created_at: string;
}

export interface BaitStation {
  id: string;
  company_id: string;
  property_id: string | null;
  station_number: string;
  station_type: string;
  location_description: string | null;
  placement_zone: string | null;
  bait_type: string | null;
  activity_level: ActivityLevel;
  last_serviced_at: string | null;
  install_date: string | null;
  created_at: string;
}

export interface WdiReport {
  id: string;
  company_id: string;
  job_id: string | null;
  report_type: string;
  report_number: string | null;
  property_address: string | null;
  inspector_name: string | null;
  inspector_license: string | null;
  inspection_date: string | null;
  infestation_found: boolean;
  damage_found: boolean;
  treatment_recommended: boolean;
  insects_identified: string[];
  recommendations: string | null;
  report_status: WdiReportStatus;
  report_pdf_url: string | null;
  created_at: string;
}

// ── Labels ──

export const SERVICE_TYPE_LABELS: Record<PestServiceType, string> = {
  general_pest: 'General Pest', termite: 'Termite', mosquito: 'Mosquito', bed_bug: 'Bed Bug',
  wildlife: 'Wildlife', fumigation: 'Fumigation', rodent: 'Rodent', ant: 'Ant',
  cockroach: 'Cockroach', tick_flea: 'Tick/Flea', spider: 'Spider', wasp_bee: 'Wasp/Bee',
  bird: 'Bird', exclusion: 'Exclusion',
};

export const TREATMENT_TYPE_LABELS: Record<TreatmentMethodType, string> = {
  spray: 'Spray', bait: 'Bait', trap: 'Trap', fog: 'Fog/ULV', dust: 'Dust',
  granular: 'Granular', heat: 'Heat', fumigation: 'Fumigation', exclusion: 'Exclusion', monitoring: 'Monitoring',
};

// ── Hooks ──

export function useTreatmentLogs() {
  const supabase = getSupabase();
  const [logs, setLogs] = useState<TreatmentLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const { data, error: err } = await supabase
        .from('treatment_logs')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });
      if (err) throw err;
      setLogs((data ?? []) as TreatmentLog[]);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  useEffect(() => {
    fetch();
    const channel = supabase
      .channel('treatment_logs_rt')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'treatment_logs' }, () => { fetch(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [supabase, fetch]);

  const create = useCallback(async (payload: Partial<TreatmentLog>) => {
    const { data, error: err } = await supabase.from('treatment_logs').insert(payload).select().single();
    if (err) throw err;
    return data as TreatmentLog;
  }, [supabase]);

  return { logs, loading, error, refetch: fetch, create };
}

export function useBaitStations(propertyId?: string) {
  const supabase = getSupabase();
  const [stations, setStations] = useState<BaitStation[]>([]);
  const [loading, setLoading] = useState(true);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      let query = supabase.from('bait_stations').select('*').is('deleted_at', null);
      if (propertyId) query = query.eq('property_id', propertyId);
      const { data, error: err } = await query.order('station_number');
      if (err) throw err;
      setStations((data ?? []) as BaitStation[]);
    } catch {
      // Degrade silently
    } finally {
      setLoading(false);
    }
  }, [supabase, propertyId]);

  useEffect(() => {
    fetch();
    const channel = supabase
      .channel('bait_stations_rt')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bait_stations' }, () => { fetch(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [supabase, fetch]);

  const create = useCallback(async (payload: Partial<BaitStation>) => {
    const { data, error: err } = await supabase.from('bait_stations').insert(payload).select().single();
    if (err) throw err;
    return data as BaitStation;
  }, [supabase]);

  const service = useCallback(async (id: string) => {
    const { error: err } = await supabase.from('bait_stations').update({
      last_serviced_at: new Date().toISOString(),
    }).eq('id', id);
    if (err) throw err;
  }, [supabase]);

  return { stations, loading, refetch: fetch, create, service };
}

export function useWdiReports() {
  const supabase = getSupabase();
  const [reports, setReports] = useState<WdiReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const { data, error: err } = await supabase
        .from('wdi_reports')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });
      if (err) throw err;
      setReports((data ?? []) as WdiReport[]);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  useEffect(() => {
    fetch();
    const channel = supabase
      .channel('wdi_reports_rt')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'wdi_reports' }, () => { fetch(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [supabase, fetch]);

  const create = useCallback(async (payload: Partial<WdiReport>) => {
    const { data, error: err } = await supabase.from('wdi_reports').insert(payload).select().single();
    if (err) throw err;
    return data as WdiReport;
  }, [supabase]);

  return { reports, loading, error, refetch: fetch, create };
}
