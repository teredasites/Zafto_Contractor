'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { createClient } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type WaterCategory = 1 | 2 | 3;
export type WaterClass = 1 | 2 | 3 | 4;

export type WaterSourceType =
  | 'supply_line' | 'drain_line' | 'appliance' | 'toilet' | 'sewage'
  | 'roof_leak' | 'window_leak' | 'foundation' | 'storm' | 'flood'
  | 'fire_suppression' | 'hvac' | 'ice_dam' | 'unknown' | 'other';

export type AssessmentStatus = 'initial' | 'in_progress' | 'monitoring' | 'drying_complete' | 'closed';

export type ContentsAction = 'move' | 'block' | 'pack_out' | 'dispose' | 'clean' | 'restore' | 'no_action';
export type ContentsCondition = 'new' | 'good' | 'fair' | 'poor' | 'damaged' | 'destroyed' | 'unknown';
export type ContentsStatus = 'inventoried' | 'in_transit' | 'stored' | 'returned' | 'disposed' | 'claimed';

export interface AffectedArea {
  room: string;
  floorLevel?: string;
  sqftAffected: number;
  materialsAffected: string[];
  wallHeightWetInches?: number;
  ceilingWet: boolean;
  hasContents: boolean;
  preExistingDamage?: string;
  notes?: string;
}

export interface RecommendedEquipment {
  type: 'dehumidifier' | 'air_mover' | 'air_scrubber' | 'heater' | 'negative_air';
  quantity: number;
  area?: string;
  notes?: string;
}

export interface WaterDamageAssessmentData {
  id: string;
  companyId: string;
  jobId: string;
  tpaAssignmentId: string | null;
  createdByUserId: string | null;
  waterCategory: WaterCategory;
  waterClass: WaterClass;
  categoryCanEscalate: boolean;
  sourceType: WaterSourceType;
  sourceDescription: string | null;
  sourceLocationRoom: string | null;
  sourceStopped: boolean;
  sourceStoppedAt: string | null;
  sourceStoppedBy: string | null;
  lossDate: string;
  discoveredDate: string | null;
  affectedAreas: AffectedArea[];
  totalSqftAffected: number;
  floorsAffected: number;
  preExistingDamage: string | null;
  preExistingMold: boolean;
  emergencyServicesRequired: boolean;
  containmentRequired: boolean;
  asbestosSuspect: boolean;
  leadPaintSuspect: boolean;
  recommendedEquipment: RecommendedEquipment[];
  estimatedDryingDays: number | null;
  status: AssessmentStatus;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface PsychrometricLogData {
  id: string;
  companyId: string;
  jobId: string;
  tpaAssignmentId: string | null;
  waterDamageAssessmentId: string | null;
  recordedByUserId: string | null;
  indoorTempF: number;
  indoorRh: number;
  indoorGpp: number | null;
  indoorDewPointF: number | null;
  outdoorTempF: number | null;
  outdoorRh: number | null;
  outdoorGpp: number | null;
  outdoorDewPointF: number | null;
  dehuInletTempF: number | null;
  dehuInletRh: number | null;
  dehuInletGpp: number | null;
  dehuOutletTempF: number | null;
  dehuOutletRh: number | null;
  dehuOutletGpp: number | null;
  dehumidifiersRunning: number;
  airMoversRunning: number;
  airScrubbersRunning: number;
  heatersRunning: number;
  roomName: string | null;
  notes: string | null;
  recordedAt: string;
  createdAt: string;
}

export interface ContentsItemData {
  id: string;
  companyId: string;
  jobId: string;
  tpaAssignmentId: string | null;
  itemNumber: number;
  description: string;
  quantity: number;
  roomName: string;
  floorLevel: string | null;
  conditionBefore: ContentsCondition | null;
  conditionAfter: ContentsCondition | null;
  damageDescription: string | null;
  action: ContentsAction;
  destination: string | null;
  preLossValue: number | null;
  replacementValue: number | null;
  actualCashValue: number | null;
  photoStoragePaths: string[];
  packedByUserId: string | null;
  packedAt: string | null;
  returnedAt: string | null;
  returnedCondition: string | null;
  status: ContentsStatus;
  createdAt: string;
  updatedAt: string;
}

export interface MoistureLocationReading {
  id: string;
  jobId: string;
  locationNumber: number | null;
  areaName: string;
  floorLevel: string | null;
  materialType: string;
  readingValue: number;
  readingUnit: string;
  targetValue: number | null;
  referenceStandard: number | null;
  dryingGoalMc: number | null;
  isDry: boolean;
  recordedAt: string;
}

export interface DryingProgress {
  totalLocations: number;
  dryLocations: number;
  wetLocations: number;
  percentDry: number;
  allDry: boolean;
  latestReadingAt: string | null;
  readingsOverdue: boolean;
}

// ============================================================================
// MAPPERS
// ============================================================================

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapAssessment(row: any): WaterDamageAssessmentData {
  return {
    id: row.id,
    companyId: row.company_id,
    jobId: row.job_id,
    tpaAssignmentId: row.tpa_assignment_id ?? null,
    createdByUserId: row.created_by_user_id ?? null,
    waterCategory: row.water_category,
    waterClass: row.water_class,
    categoryCanEscalate: row.category_can_escalate ?? false,
    sourceType: row.source_type,
    sourceDescription: row.source_description ?? null,
    sourceLocationRoom: row.source_location_room ?? null,
    sourceStopped: row.source_stopped ?? false,
    sourceStoppedAt: row.source_stopped_at ?? null,
    sourceStoppedBy: row.source_stopped_by ?? null,
    lossDate: row.loss_date,
    discoveredDate: row.discovered_date ?? null,
    affectedAreas: row.affected_areas ?? [],
    totalSqftAffected: parseFloat(row.total_sqft_affected) || 0,
    floorsAffected: row.floors_affected ?? 1,
    preExistingDamage: row.pre_existing_damage ?? null,
    preExistingMold: row.pre_existing_mold ?? false,
    emergencyServicesRequired: row.emergency_services_required ?? false,
    containmentRequired: row.containment_required ?? false,
    asbestosSuspect: row.asbestos_suspect ?? false,
    leadPaintSuspect: row.lead_paint_suspect ?? false,
    recommendedEquipment: row.recommended_equipment ?? [],
    estimatedDryingDays: row.estimated_drying_days ?? null,
    status: row.status ?? 'initial',
    completedAt: row.completed_at ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapPsychrometricLog(row: any): PsychrometricLogData {
  return {
    id: row.id,
    companyId: row.company_id,
    jobId: row.job_id,
    tpaAssignmentId: row.tpa_assignment_id ?? null,
    waterDamageAssessmentId: row.water_damage_assessment_id ?? null,
    recordedByUserId: row.recorded_by_user_id ?? null,
    indoorTempF: parseFloat(row.indoor_temp_f) || 0,
    indoorRh: parseFloat(row.indoor_rh) || 0,
    indoorGpp: row.indoor_gpp != null ? parseFloat(row.indoor_gpp) : null,
    indoorDewPointF: row.indoor_dew_point_f != null ? parseFloat(row.indoor_dew_point_f) : null,
    outdoorTempF: row.outdoor_temp_f != null ? parseFloat(row.outdoor_temp_f) : null,
    outdoorRh: row.outdoor_rh != null ? parseFloat(row.outdoor_rh) : null,
    outdoorGpp: row.outdoor_gpp != null ? parseFloat(row.outdoor_gpp) : null,
    outdoorDewPointF: row.outdoor_dew_point_f != null ? parseFloat(row.outdoor_dew_point_f) : null,
    dehuInletTempF: row.dehu_inlet_temp_f != null ? parseFloat(row.dehu_inlet_temp_f) : null,
    dehuInletRh: row.dehu_inlet_rh != null ? parseFloat(row.dehu_inlet_rh) : null,
    dehuInletGpp: row.dehu_inlet_gpp != null ? parseFloat(row.dehu_inlet_gpp) : null,
    dehuOutletTempF: row.dehu_outlet_temp_f != null ? parseFloat(row.dehu_outlet_temp_f) : null,
    dehuOutletRh: row.dehu_outlet_rh != null ? parseFloat(row.dehu_outlet_rh) : null,
    dehuOutletGpp: row.dehu_outlet_gpp != null ? parseFloat(row.dehu_outlet_gpp) : null,
    dehumidifiersRunning: row.dehumidifiers_running ?? 0,
    airMoversRunning: row.air_movers_running ?? 0,
    airScrubbersRunning: row.air_scrubbers_running ?? 0,
    heatersRunning: row.heaters_running ?? 0,
    roomName: row.room_name ?? null,
    notes: row.notes ?? null,
    recordedAt: row.recorded_at,
    createdAt: row.created_at,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapContentsItem(row: any): ContentsItemData {
  return {
    id: row.id,
    companyId: row.company_id,
    jobId: row.job_id,
    tpaAssignmentId: row.tpa_assignment_id ?? null,
    itemNumber: row.item_number,
    description: row.description,
    quantity: row.quantity ?? 1,
    roomName: row.room_name,
    floorLevel: row.floor_level ?? null,
    conditionBefore: row.condition_before ?? null,
    conditionAfter: row.condition_after ?? null,
    damageDescription: row.damage_description ?? null,
    action: row.action,
    destination: row.destination ?? null,
    preLossValue: row.pre_loss_value != null ? parseFloat(row.pre_loss_value) : null,
    replacementValue: row.replacement_value != null ? parseFloat(row.replacement_value) : null,
    actualCashValue: row.actual_cash_value != null ? parseFloat(row.actual_cash_value) : null,
    photoStoragePaths: row.photo_storage_paths ?? [],
    packedByUserId: row.packed_by_user_id ?? null,
    packedAt: row.packed_at ?? null,
    returnedAt: row.returned_at ?? null,
    returnedCondition: row.returned_condition ?? null,
    status: row.status ?? 'inventoried',
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapMoistureLocation(row: any): MoistureLocationReading {
  return {
    id: row.id,
    jobId: row.job_id,
    locationNumber: row.location_number ?? null,
    areaName: row.area_name,
    floorLevel: row.floor_level ?? null,
    materialType: row.material_type,
    readingValue: parseFloat(row.reading_value) || 0,
    readingUnit: row.reading_unit ?? 'percent',
    targetValue: row.target_value != null ? parseFloat(row.target_value) : null,
    referenceStandard: row.reference_standard != null ? parseFloat(row.reference_standard) : null,
    dryingGoalMc: row.drying_goal_mc != null ? parseFloat(row.drying_goal_mc) : null,
    isDry: row.is_dry ?? false,
    recordedAt: row.recorded_at,
  };
}

// ============================================================================
// PSYCHROMETRIC CALCULATIONS
// ============================================================================

/** Calculate Grains Per Pound (GPP) from temp (F) and RH (%) */
export function calculateGpp(tempF: number, rh: number): number {
  const tempC = (tempF - 32) * 5 / 9;
  // Magnus formula for saturation vapor pressure (hPa)
  const es = 6.112 * Math.exp((17.67 * tempC) / (tempC + 243.5));
  // Actual vapor pressure
  const e = (rh / 100) * es;
  // Mixing ratio (g/kg) — approximation at sea level (1013.25 hPa)
  const w = 621.97 * (e / (1013.25 - e));
  // Convert g/kg to grains/lb (1 g/kg = 7 grains/lb)
  return Math.round(w * 7 * 100) / 100;
}

/** Calculate dew point (F) from temp (F) and RH (%) */
export function calculateDewPoint(tempF: number, rh: number): number {
  const tempC = (tempF - 32) * 5 / 9;
  const a = 17.67;
  const b = 243.5;
  const alpha = (a * tempC) / (b + tempC) + Math.log(rh / 100);
  const dewC = (b * alpha) / (a - alpha);
  return Math.round((dewC * 9 / 5 + 32) * 10) / 10;
}

// ============================================================================
// HOOKS
// ============================================================================

/** Hook for water damage assessments per job */
export function useWaterDamageAssessments(jobId: string | null) {
  const [assessments, setAssessments] = useState<WaterDamageAssessmentData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!jobId) { setAssessments([]); setLoading(false); return; }
    try {
      setLoading(true);
      setError(null);
      const supabase = createClient();
      const { data, error: err } = await supabase
        .from('water_damage_assessments')
        .select('*')
        .eq('job_id', jobId)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setAssessments((data || []).map(mapAssessment));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load assessments');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetch();
    if (!jobId) return;
    const supabase = createClient();
    const channel = supabase
      .channel(`wda-${jobId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'water_damage_assessments', filter: `job_id=eq.${jobId}` }, () => { fetch(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetch, jobId]);

  const createAssessment = async (input: {
    waterCategory: WaterCategory;
    waterClass: WaterClass;
    sourceType: WaterSourceType;
    sourceDescription?: string;
    sourceLocationRoom?: string;
    sourceStopped?: boolean;
    lossDate: string;
    discoveredDate?: string;
    affectedAreas?: AffectedArea[];
    totalSqftAffected?: number;
    floorsAffected?: number;
    preExistingDamage?: string;
    preExistingMold?: boolean;
    emergencyServicesRequired?: boolean;
    containmentRequired?: boolean;
    asbestosSuspect?: boolean;
    leadPaintSuspect?: boolean;
    recommendedEquipment?: RecommendedEquipment[];
    estimatedDryingDays?: number;
    tpaAssignmentId?: string;
  }): Promise<string> => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data, error: err } = await supabase
      .from('water_damage_assessments')
      .insert({
        company_id: companyId,
        job_id: jobId,
        tpa_assignment_id: input.tpaAssignmentId ?? null,
        created_by_user_id: user.id,
        water_category: input.waterCategory,
        water_class: input.waterClass,
        source_type: input.sourceType,
        source_description: input.sourceDescription ?? null,
        source_location_room: input.sourceLocationRoom ?? null,
        source_stopped: input.sourceStopped ?? false,
        loss_date: input.lossDate,
        discovered_date: input.discoveredDate ?? null,
        affected_areas: input.affectedAreas ?? [],
        total_sqft_affected: input.totalSqftAffected ?? 0,
        floors_affected: input.floorsAffected ?? 1,
        pre_existing_damage: input.preExistingDamage ?? null,
        pre_existing_mold: input.preExistingMold ?? false,
        emergency_services_required: input.emergencyServicesRequired ?? false,
        containment_required: input.containmentRequired ?? false,
        asbestos_suspect: input.asbestosSuspect ?? false,
        lead_paint_suspect: input.leadPaintSuspect ?? false,
        recommended_equipment: input.recommendedEquipment ?? [],
        estimated_drying_days: input.estimatedDryingDays ?? null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return data.id;
  };

  const updateAssessment = async (id: string, updates: Partial<{
    waterCategory: WaterCategory;
    waterClass: WaterClass;
    status: AssessmentStatus;
    sourceStopped: boolean;
    sourceStoppedAt: string;
    sourceStoppedBy: string;
    affectedAreas: AffectedArea[];
    totalSqftAffected: number;
    recommendedEquipment: RecommendedEquipment[];
    estimatedDryingDays: number;
    completedAt: string;
  }>): Promise<void> => {
    const supabase = createClient();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const row: Record<string, any> = {};
    if (updates.waterCategory !== undefined) row.water_category = updates.waterCategory;
    if (updates.waterClass !== undefined) row.water_class = updates.waterClass;
    if (updates.status !== undefined) row.status = updates.status;
    if (updates.sourceStopped !== undefined) row.source_stopped = updates.sourceStopped;
    if (updates.sourceStoppedAt !== undefined) row.source_stopped_at = updates.sourceStoppedAt;
    if (updates.sourceStoppedBy !== undefined) row.source_stopped_by = updates.sourceStoppedBy;
    if (updates.affectedAreas !== undefined) row.affected_areas = updates.affectedAreas;
    if (updates.totalSqftAffected !== undefined) row.total_sqft_affected = updates.totalSqftAffected;
    if (updates.recommendedEquipment !== undefined) row.recommended_equipment = updates.recommendedEquipment;
    if (updates.estimatedDryingDays !== undefined) row.estimated_drying_days = updates.estimatedDryingDays;
    if (updates.completedAt !== undefined) row.completed_at = updates.completedAt;

    const { error: err } = await supabase
      .from('water_damage_assessments')
      .update(row)
      .eq('id', id);

    if (err) throw err;
  };

  return { assessments, loading, error, createAssessment, updateAssessment, refetch: fetch };
}

/** Hook for moisture drying progress monitoring per job */
export function useDryingMonitor(jobId: string | null) {
  const [readings, setReadings] = useState<MoistureLocationReading[]>([]);
  const [psychLogs, setPsychLogs] = useState<PsychrometricLogData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!jobId) { setReadings([]); setPsychLogs([]); setLoading(false); return; }
    try {
      setLoading(true);
      setError(null);
      const supabase = createClient();
      const [readingsRes, psychRes] = await Promise.all([
        supabase
          .from('moisture_readings')
          .select('*')
          .eq('job_id', jobId)
          .order('recorded_at', { ascending: false })
          .limit(500),
        supabase
          .from('psychrometric_logs')
          .select('*')
          .eq('job_id', jobId)
          .order('recorded_at', { ascending: false })
          .limit(200),
      ]);

      if (readingsRes.error) throw readingsRes.error;
      if (psychRes.error) throw psychRes.error;

      setReadings((readingsRes.data || []).map(mapMoistureLocation));
      setPsychLogs((psychRes.data || []).map(mapPsychrometricLog));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load drying data');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetch();
    if (!jobId) return;
    const supabase = createClient();
    const channel = supabase
      .channel(`drying-monitor-${jobId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'moisture_readings', filter: `job_id=eq.${jobId}` }, () => { fetch(); })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'psychrometric_logs', filter: `job_id=eq.${jobId}` }, () => { fetch(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetch, jobId]);

  /** Drying progress computed from latest readings per unique location */
  const dryingProgress = useMemo<DryingProgress>(() => {
    if (readings.length === 0) {
      return { totalLocations: 0, dryLocations: 0, wetLocations: 0, percentDry: 0, allDry: false, latestReadingAt: null, readingsOverdue: false };
    }

    // Get latest reading per location (area + location_number)
    const locationMap = new Map<string, MoistureLocationReading>();
    for (const r of readings) {
      const key = `${r.areaName}|${r.locationNumber ?? 'x'}`;
      const existing = locationMap.get(key);
      if (!existing || new Date(r.recordedAt) > new Date(existing.recordedAt)) {
        locationMap.set(key, r);
      }
    }

    const latestReadings = Array.from(locationMap.values());
    const dryCount = latestReadings.filter(r => r.isDry || (r.targetValue != null && r.readingValue <= r.targetValue)).length;
    const wetCount = latestReadings.length - dryCount;
    const latestAt = readings.length > 0 ? readings[0].recordedAt : null;
    const overdue = latestAt ? (Date.now() - new Date(latestAt).getTime()) > 24 * 60 * 60 * 1000 : false;

    return {
      totalLocations: latestReadings.length,
      dryLocations: dryCount,
      wetLocations: wetCount,
      percentDry: latestReadings.length > 0 ? Math.round((dryCount / latestReadings.length) * 100) : 0,
      allDry: wetCount === 0 && latestReadings.length > 0,
      latestReadingAt: latestAt,
      readingsOverdue: overdue,
    };
  }, [readings]);

  /** Add a psychrometric log entry with auto-GPP/dew point calculation */
  const addPsychrometricLog = async (input: {
    indoorTempF: number;
    indoorRh: number;
    outdoorTempF?: number;
    outdoorRh?: number;
    dehuInletTempF?: number;
    dehuInletRh?: number;
    dehuOutletTempF?: number;
    dehuOutletRh?: number;
    dehumidifiersRunning?: number;
    airMoversRunning?: number;
    airScrubbersRunning?: number;
    heatersRunning?: number;
    roomName?: string;
    notes?: string;
    tpaAssignmentId?: string;
    waterDamageAssessmentId?: string;
  }): Promise<string> => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Auto-calculate GPP and dew point
    const indoorGpp = calculateGpp(input.indoorTempF, input.indoorRh);
    const indoorDewPoint = calculateDewPoint(input.indoorTempF, input.indoorRh);
    const outdoorGpp = input.outdoorTempF != null && input.outdoorRh != null
      ? calculateGpp(input.outdoorTempF, input.outdoorRh) : null;
    const outdoorDewPoint = input.outdoorTempF != null && input.outdoorRh != null
      ? calculateDewPoint(input.outdoorTempF, input.outdoorRh) : null;
    const dehuInletGpp = input.dehuInletTempF != null && input.dehuInletRh != null
      ? calculateGpp(input.dehuInletTempF, input.dehuInletRh) : null;
    const dehuOutletGpp = input.dehuOutletTempF != null && input.dehuOutletRh != null
      ? calculateGpp(input.dehuOutletTempF, input.dehuOutletRh) : null;

    const { data, error: err } = await supabase
      .from('psychrometric_logs')
      .insert({
        company_id: companyId,
        job_id: jobId,
        tpa_assignment_id: input.tpaAssignmentId ?? null,
        water_damage_assessment_id: input.waterDamageAssessmentId ?? null,
        recorded_by_user_id: user.id,
        indoor_temp_f: input.indoorTempF,
        indoor_rh: input.indoorRh,
        indoor_gpp: indoorGpp,
        indoor_dew_point_f: indoorDewPoint,
        outdoor_temp_f: input.outdoorTempF ?? null,
        outdoor_rh: input.outdoorRh ?? null,
        outdoor_gpp: outdoorGpp,
        outdoor_dew_point_f: outdoorDewPoint,
        dehu_inlet_temp_f: input.dehuInletTempF ?? null,
        dehu_inlet_rh: input.dehuInletRh ?? null,
        dehu_inlet_gpp: dehuInletGpp,
        dehu_outlet_temp_f: input.dehuOutletTempF ?? null,
        dehu_outlet_rh: input.dehuOutletRh ?? null,
        dehu_outlet_gpp: dehuOutletGpp,
        dehumidifiers_running: input.dehumidifiersRunning ?? 0,
        air_movers_running: input.airMoversRunning ?? 0,
        air_scrubbers_running: input.airScrubbersRunning ?? 0,
        heaters_running: input.heatersRunning ?? 0,
        room_name: input.roomName ?? null,
        notes: input.notes ?? null,
        recorded_at: new Date().toISOString(),
      })
      .select('id')
      .single();

    if (err) throw err;
    return data.id;
  };

  return { readings, psychLogs, dryingProgress, loading, error, addPsychrometricLog, refetch: fetch };
}

/** Hook for contents inventory per job */
export function useContentsInventory(jobId: string | null) {
  const [items, setItems] = useState<ContentsItemData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!jobId) { setItems([]); setLoading(false); return; }
    try {
      setLoading(true);
      setError(null);
      const supabase = createClient();
      const { data, error: err } = await supabase
        .from('contents_inventory')
        .select('*')
        .eq('job_id', jobId)
        .is('deleted_at', null)
        .order('room_name')
        .order('item_number');

      if (err) throw err;
      setItems((data || []).map(mapContentsItem));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load contents inventory');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetch();
    if (!jobId) return;
    const supabase = createClient();
    const channel = supabase
      .channel(`contents-${jobId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'contents_inventory', filter: `job_id=eq.${jobId}` }, () => { fetch(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetch, jobId]);

  const addItem = async (input: {
    description: string;
    quantity?: number;
    roomName: string;
    floorLevel?: string;
    conditionBefore?: ContentsCondition;
    action: ContentsAction;
    destination?: string;
    preLossValue?: number;
    replacementValue?: number;
    tpaAssignmentId?: string;
  }): Promise<string> => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Auto-increment item number
    const nextNumber = items.length > 0 ? Math.max(...items.map(i => i.itemNumber)) + 1 : 1;

    const { data, error: err } = await supabase
      .from('contents_inventory')
      .insert({
        company_id: companyId,
        job_id: jobId,
        tpa_assignment_id: input.tpaAssignmentId ?? null,
        item_number: nextNumber,
        description: input.description,
        quantity: input.quantity ?? 1,
        room_name: input.roomName,
        floor_level: input.floorLevel ?? null,
        condition_before: input.conditionBefore ?? null,
        action: input.action,
        destination: input.destination ?? null,
        pre_loss_value: input.preLossValue ?? null,
        replacement_value: input.replacementValue ?? null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return data.id;
  };

  const updateItem = async (id: string, updates: Partial<{
    conditionAfter: ContentsCondition;
    damageDescription: string;
    action: ContentsAction;
    destination: string;
    replacementValue: number;
    actualCashValue: number;
    status: ContentsStatus;
    returnedAt: string;
    returnedCondition: string;
  }>): Promise<void> => {
    const supabase = createClient();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const row: Record<string, any> = {};
    if (updates.conditionAfter !== undefined) row.condition_after = updates.conditionAfter;
    if (updates.damageDescription !== undefined) row.damage_description = updates.damageDescription;
    if (updates.action !== undefined) row.action = updates.action;
    if (updates.destination !== undefined) row.destination = updates.destination;
    if (updates.replacementValue !== undefined) row.replacement_value = updates.replacementValue;
    if (updates.actualCashValue !== undefined) row.actual_cash_value = updates.actualCashValue;
    if (updates.status !== undefined) row.status = updates.status;
    if (updates.returnedAt !== undefined) row.returned_at = updates.returnedAt;
    if (updates.returnedCondition !== undefined) row.returned_condition = updates.returnedCondition;

    const { error: err } = await supabase
      .from('contents_inventory')
      .update(row)
      .eq('id', id);

    if (err) throw err;
  };

  /** Group items by room for display */
  const itemsByRoom = useMemo(() => {
    const map = new Map<string, ContentsItemData[]>();
    for (const item of items) {
      const existing = map.get(item.roomName) || [];
      existing.push(item);
      map.set(item.roomName, existing);
    }
    return map;
  }, [items]);

  /** Financial summary */
  const financialSummary = useMemo(() => {
    let totalPreLoss = 0;
    let totalReplacement = 0;
    let totalAcv = 0;
    let disposedCount = 0;
    let packedOutCount = 0;
    for (const item of items) {
      if (item.preLossValue) totalPreLoss += item.preLossValue;
      if (item.replacementValue) totalReplacement += item.replacementValue;
      if (item.actualCashValue) totalAcv += item.actualCashValue;
      if (item.action === 'dispose') disposedCount++;
      if (item.action === 'pack_out') packedOutCount++;
    }
    return { totalPreLoss, totalReplacement, totalAcv, disposedCount, packedOutCount, totalItems: items.length };
  }, [items]);

  return { items, itemsByRoom, financialSummary, loading, error, addItem, updateItem, refetch: fetch };
}
