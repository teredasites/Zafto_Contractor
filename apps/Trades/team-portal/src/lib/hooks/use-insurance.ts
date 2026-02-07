'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import {
  mapInsuranceClaim, mapMoistureReading, mapDryingLog,
  mapRestorationEquipment, mapTpiInspection,
  type InsuranceClaimSummary, type MoistureReadingData,
  type DryingLogData, type RestorationEquipmentData,
  type TpiInspectionData, type MaterialMoistureType,
  type ReadingUnit, type DryingLogType, type EquipmentType,
} from './mappers';

// Fetch insurance claim + all restoration data for a job
export function useJobInsurance(jobId: string | null) {
  const [claim, setClaim] = useState<InsuranceClaimSummary | null>(null);
  const [moisture, setMoisture] = useState<MoistureReadingData[]>([]);
  const [dryingLogs, setDryingLogs] = useState<DryingLogData[]>([]);
  const [equipment, setEquipment] = useState<RestorationEquipmentData[]>([]);
  const [tpiInspections, setTpiInspections] = useState<TpiInspectionData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetch = useCallback(async () => {
    if (!jobId) { setLoading(false); return; }
    const supabase = getSupabase();

    // First get claim for this job
    const { data: claimData } = await supabase
      .from('insurance_claims')
      .select('*')
      .eq('job_id', jobId)
      .is('deleted_at', null)
      .maybeSingle();

    if (!claimData) {
      setClaim(null);
      setLoading(false);
      return;
    }

    const claimId = claimData.id as string;
    setClaim(mapInsuranceClaim(claimData));

    // Fetch all related data in parallel
    const [moistureRes, dryingRes, equipRes, tpiRes] = await Promise.all([
      supabase.from('moisture_readings').select('*').eq('job_id', jobId).order('recorded_at', { ascending: false }),
      supabase.from('drying_logs').select('*').eq('job_id', jobId).order('recorded_at', { ascending: false }),
      supabase.from('restoration_equipment').select('*').eq('job_id', jobId).order('deployed_at', { ascending: false }),
      supabase.from('tpi_scheduling').select('*').eq('claim_id', claimId).order('scheduled_date', { ascending: false }),
    ]);

    setMoisture((moistureRes.data || []).map(mapMoistureReading));
    setDryingLogs((dryingRes.data || []).map(mapDryingLog));
    setEquipment((equipRes.data || []).map(mapRestorationEquipment));
    setTpiInspections((tpiRes.data || []).map(mapTpiInspection));
    setLoading(false);
  }, [jobId]);

  useEffect(() => {
    fetch();
    if (!jobId) return;

    const supabase = getSupabase();
    const channel = supabase.channel(`team-insurance-${jobId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'insurance_claims' }, () => fetch())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'moisture_readings' }, () => fetch())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'drying_logs' }, () => fetch())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'restoration_equipment' }, () => fetch())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tpi_scheduling' }, () => fetch())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [jobId, fetch]);

  return { claim, moisture, dryingLogs, equipment, tpiInspections, loading, refetch: fetch };
}

// ==================== MUTATIONS ====================

export async function addMoistureReading(input: {
  jobId: string;
  claimId?: string;
  areaName: string;
  materialType: MaterialMoistureType;
  readingValue: number;
  readingUnit?: ReadingUnit;
  targetValue?: number;
  isDry?: boolean;
}): Promise<void> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { error } = await supabase.from('moisture_readings').insert({
    company_id: user.app_metadata?.company_id,
    job_id: input.jobId,
    claim_id: input.claimId || null,
    area_name: input.areaName,
    material_type: input.materialType,
    reading_value: input.readingValue,
    reading_unit: input.readingUnit || 'percent',
    target_value: input.targetValue || null,
    is_dry: input.isDry || false,
    recorded_by_user_id: user.id,
    recorded_at: new Date().toISOString(),
  });
  if (error) throw error;
}

export async function addDryingLog(input: {
  jobId: string;
  claimId?: string;
  logType: DryingLogType;
  summary: string;
  equipmentCount?: number;
  dehumidifiersRunning?: number;
  airMoversRunning?: number;
  airScrubbersRunning?: number;
  indoorTempF?: number;
  indoorHumidity?: number;
}): Promise<void> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { error } = await supabase.from('drying_logs').insert({
    company_id: user.app_metadata?.company_id,
    job_id: input.jobId,
    claim_id: input.claimId || null,
    log_type: input.logType,
    summary: input.summary,
    equipment_count: input.equipmentCount || 0,
    dehumidifiers_running: input.dehumidifiersRunning || 0,
    air_movers_running: input.airMoversRunning || 0,
    air_scrubbers_running: input.airScrubbersRunning || 0,
    indoor_temp_f: input.indoorTempF || null,
    indoor_humidity: input.indoorHumidity || null,
    recorded_by_user_id: user.id,
    recorded_at: new Date().toISOString(),
  });
  if (error) throw error;
}

export async function deployEquipment(input: {
  jobId: string;
  claimId?: string;
  equipmentType: EquipmentType;
  serialNumber?: string;
  areaDeployed: string;
  dailyRate?: number;
}): Promise<void> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { error } = await supabase.from('restoration_equipment').insert({
    company_id: user.app_metadata?.company_id,
    job_id: input.jobId,
    claim_id: input.claimId || null,
    equipment_type: input.equipmentType,
    serial_number: input.serialNumber || null,
    area_deployed: input.areaDeployed,
    daily_rate: input.dailyRate || 0,
    deployed_at: new Date().toISOString(),
    status: 'deployed',
  });
  if (error) throw error;
}

export async function removeEquipment(equipmentId: string): Promise<void> {
  const supabase = getSupabase();
  const { error } = await supabase
    .from('restoration_equipment')
    .update({ status: 'removed', removed_at: new Date().toISOString() })
    .eq('id', equipmentId);
  if (error) throw error;
}
