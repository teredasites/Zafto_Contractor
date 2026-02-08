'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapMoistureReading, mapDryingLog, mapRestorationEquipment } from './mappers';
import type { MoistureReadingData, DryingLogData, RestorationEquipmentData, MaterialMoistureType, ReadingUnit, DryingLogType, EquipmentType as RestEquipmentType, EquipmentStatus } from '@/types';

// Extended types with job name from joined query
export interface MoistureReadingWithJob extends MoistureReadingData {
  jobName: string;
}

export interface DryingLogWithJob extends DryingLogData {
  jobName: string;
}

export interface RestorationEquipmentWithJob extends RestorationEquipmentData {
  jobName: string;
}

export interface RestorationStats {
  activeEquipment: number;
  dailyRateTotal: number;
  overdueReadings: number;
  dryingInProgress: number;
  totalReadings: number;
  totalLogs: number;
  totalEquipment: number;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapReadingWithJob(row: any): MoistureReadingWithJob {
  const base = mapMoistureReading(row);
  const jobData = row.jobs as { title?: string } | null;
  return { ...base, jobName: jobData?.title || '' };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapDryingLogWithJob(row: any): DryingLogWithJob {
  const base = mapDryingLog(row);
  const jobData = row.jobs as { title?: string } | null;
  return { ...base, jobName: jobData?.title || '' };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapEquipmentWithJob(row: any): RestorationEquipmentWithJob {
  const base = mapRestorationEquipment(row);
  const jobData = row.jobs as { title?: string } | null;
  return { ...base, jobName: jobData?.title || '' };
}

export function useRestorationTools() {
  const [readings, setReadings] = useState<MoistureReadingWithJob[]>([]);
  const [dryingLogs, setDryingLogs] = useState<DryingLogWithJob[]>([]);
  const [equipment, setEquipment] = useState<RestorationEquipmentWithJob[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAll = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const [readingsRes, logsRes, equipRes] = await Promise.all([
        supabase
          .from('moisture_readings')
          .select('*, jobs(title)')
          .order('recorded_at', { ascending: false })
          .limit(200),
        supabase
          .from('drying_logs')
          .select('*, jobs(title)')
          .order('recorded_at', { ascending: false })
          .limit(200),
        supabase
          .from('restoration_equipment')
          .select('*, jobs(title)')
          .order('deployed_at', { ascending: false })
          .limit(200),
      ]);

      if (readingsRes.error) throw readingsRes.error;
      if (logsRes.error) throw logsRes.error;
      if (equipRes.error) throw equipRes.error;

      setReadings((readingsRes.data || []).map(mapReadingWithJob));
      setDryingLogs((logsRes.data || []).map(mapDryingLogWithJob));
      setEquipment((equipRes.data || []).map(mapEquipmentWithJob));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load restoration data';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAll();

    const supabase = getSupabase();
    const channel = supabase
      .channel('restoration-tools-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'moisture_readings' }, () => { fetchAll(); })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'drying_logs' }, () => { fetchAll(); })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'restoration_equipment' }, () => { fetchAll(); })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchAll]);

  // Computed: active equipment (status=deployed)
  const activeEquipment = useMemo(
    () => equipment.filter((e) => e.status === 'deployed'),
    [equipment]
  );

  // Computed stats
  const stats = useMemo<RestorationStats>(() => {
    const deployed = equipment.filter((e) => e.status === 'deployed');
    const dailyRateTotal = deployed.reduce((sum, e) => sum + (e.dailyRate || 0), 0);

    // Overdue readings: jobs where the most recent reading is > 24hrs old
    const now = Date.now();
    const twentyFourHours = 24 * 60 * 60 * 1000;
    const jobLastReading = new Map<string, number>();
    for (const r of readings) {
      const ts = new Date(r.recordedAt).getTime();
      const existing = jobLastReading.get(r.jobId);
      if (!existing || ts > existing) {
        jobLastReading.set(r.jobId, ts);
      }
    }
    let overdueReadings = 0;
    for (const [, lastTs] of jobLastReading) {
      if (now - lastTs > twentyFourHours) overdueReadings++;
    }

    // Drying in progress: count of unique jobs that have logs but no completion log
    const jobsWithCompletion = new Set<string>();
    const jobsWithLogs = new Set<string>();
    for (const log of dryingLogs) {
      jobsWithLogs.add(log.jobId);
      if (log.logType === 'completion') jobsWithCompletion.add(log.jobId);
    }
    const dryingInProgress = [...jobsWithLogs].filter((j) => !jobsWithCompletion.has(j)).length;

    return {
      activeEquipment: deployed.length,
      dailyRateTotal,
      overdueReadings,
      dryingInProgress,
      totalReadings: readings.length,
      totalLogs: dryingLogs.length,
      totalEquipment: equipment.length,
    };
  }, [readings, dryingLogs, equipment]);

  // Mutations
  const addMoistureReading = async (input: {
    jobId: string;
    claimId?: string;
    areaName: string;
    floorLevel?: string;
    materialType: MaterialMoistureType;
    readingValue: number;
    readingUnit: ReadingUnit;
    targetValue?: number;
    meterType?: string;
    meterModel?: string;
    ambientTempF?: number;
    ambientHumidity?: number;
    isDry: boolean;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data, error: err } = await supabase
      .from('moisture_readings')
      .insert({
        company_id: companyId,
        job_id: input.jobId,
        claim_id: input.claimId || null,
        area_name: input.areaName,
        floor_level: input.floorLevel || null,
        material_type: input.materialType,
        reading_value: input.readingValue,
        reading_unit: input.readingUnit,
        target_value: input.targetValue ?? null,
        meter_type: input.meterType || null,
        meter_model: input.meterModel || null,
        ambient_temp_f: input.ambientTempF ?? null,
        ambient_humidity: input.ambientHumidity ?? null,
        is_dry: input.isDry,
        recorded_by_user_id: user.id,
        recorded_at: new Date().toISOString(),
      })
      .select('id')
      .single();

    if (err) throw err;
    return data.id;
  };

  const addDryingLog = async (input: {
    jobId: string;
    claimId?: string;
    logType: DryingLogType;
    summary: string;
    details?: string;
    equipmentCount?: number;
    dehumidifiersRunning?: number;
    airMoversRunning?: number;
    airScrubbersRunning?: number;
    outdoorTempF?: number;
    outdoorHumidity?: number;
    indoorTempF?: number;
    indoorHumidity?: number;
    photos?: Record<string, unknown>[];
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data, error: err } = await supabase
      .from('drying_logs')
      .insert({
        company_id: companyId,
        job_id: input.jobId,
        claim_id: input.claimId || null,
        log_type: input.logType,
        summary: input.summary,
        details: input.details || null,
        equipment_count: input.equipmentCount || 0,
        dehumidifiers_running: input.dehumidifiersRunning || 0,
        air_movers_running: input.airMoversRunning || 0,
        air_scrubbers_running: input.airScrubbersRunning || 0,
        outdoor_temp_f: input.outdoorTempF ?? null,
        outdoor_humidity: input.outdoorHumidity ?? null,
        indoor_temp_f: input.indoorTempF ?? null,
        indoor_humidity: input.indoorHumidity ?? null,
        photos: input.photos || [],
        recorded_by_user_id: user.id,
        recorded_at: new Date().toISOString(),
      })
      .select('id')
      .single();

    if (err) throw err;
    return data.id;
  };

  const addEquipment = async (input: {
    jobId: string;
    claimId?: string;
    equipmentType: RestEquipmentType;
    make?: string;
    model?: string;
    serialNumber?: string;
    assetTag?: string;
    areaDeployed: string;
    dailyRate: number;
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data, error: err } = await supabase
      .from('restoration_equipment')
      .insert({
        company_id: companyId,
        job_id: input.jobId,
        claim_id: input.claimId || null,
        equipment_type: input.equipmentType,
        make: input.make || null,
        model: input.model || null,
        serial_number: input.serialNumber || null,
        asset_tag: input.assetTag || null,
        area_deployed: input.areaDeployed,
        deployed_at: new Date().toISOString(),
        daily_rate: input.dailyRate,
        status: 'deployed',
        notes: input.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return data.id;
  };

  const updateEquipment = async (
    id: string,
    updates: {
      status?: EquipmentStatus;
      areaDeployed?: string;
      removedAt?: string;
      dailyRate?: number;
      notes?: string;
    }
  ): Promise<void> => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};
    if (updates.status !== undefined) updateData.status = updates.status;
    if (updates.areaDeployed !== undefined) updateData.area_deployed = updates.areaDeployed;
    if (updates.removedAt !== undefined) updateData.removed_at = updates.removedAt;
    if (updates.dailyRate !== undefined) updateData.daily_rate = updates.dailyRate;
    if (updates.notes !== undefined) updateData.notes = updates.notes;

    const { error: err } = await supabase
      .from('restoration_equipment')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;
  };

  return {
    readings,
    dryingLogs,
    equipment,
    activeEquipment,
    stats,
    loading,
    error,
    addMoistureReading,
    addDryingLog,
    addEquipment,
    updateEquipment,
    refetch: fetchAll,
  };
}
