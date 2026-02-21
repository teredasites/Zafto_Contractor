'use client';

// DEPTH35: Mold Remediation Hook (Team Portal)
// Field technicians: record moisture readings, log equipment deployments,
// collect lab samples, view assessment details. Read-only for state licensing.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type MoistureReadingType =
  | 'surface_pin'
  | 'relative_humidity'
  | 'dew_point'
  | 'wood_moisture_content';

export type MoistureSeverity = 'normal' | 'concern' | 'saturation';

export type MoldEquipmentType =
  | 'dehumidifier'
  | 'air_scrubber'
  | 'negative_air_machine'
  | 'air_mover'
  | 'moisture_meter'
  | 'thermo_hygrometer'
  | 'hepa_vacuum'
  | 'sprayer'
  | 'other';

export type LabSampleType =
  | 'air_cassette'
  | 'tape_lift'
  | 'bulk_swab'
  | 'surface_wipe';

export type LabSampleStatus = 'pending' | 'sent' | 'received' | 'results_in';

export interface MoldAssessmentSummary {
  id: string;
  propertyId: string | null;
  jobId: string | null;
  assessmentDate: string;
  suspectedCause: string;
  affectedAreaSqft: number | null;
  remediationLevel: number | null;
  overallNotes: string | null;
}

export interface MoldMoistureReading {
  id: string;
  assessmentId: string;
  roomName: string;
  locationDetail: string | null;
  readingType: MoistureReadingType;
  readingValue: number;
  readingUnit: string;
  severity: MoistureSeverity | null;
  meterModel: string | null;
  notes: string | null;
  createdAt: string;
}

export interface MoldEquipmentDeployment {
  id: string;
  remediationId: string | null;
  equipmentType: MoldEquipmentType;
  modelName: string | null;
  serialNumber: string | null;
  placementLocation: string | null;
  deployedAt: string;
  retrievedAt: string | null;
  runtimeHours: number | null;
  notes: string | null;
  updatedAt: string;
}

export interface MoldStateLicensing {
  id: string;
  stateCode: string;
  stateName: string;
  licenseRequired: boolean;
  licenseTypes: unknown[];
  issuingAgency: string | null;
  agencyUrl: string | null;
  notes: string | null;
}

// ============================================================================
// HELPERS
// ============================================================================

function snakeToCamel(row: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(row)) {
    const camelKey = key.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
    result[camelKey] = value;
  }
  return result;
}

function mapRows<T>(rows: Record<string, unknown>[]): T[] {
  return rows.map((row: Record<string, unknown>) => snakeToCamel(row) as unknown as T);
}

// ============================================================================
// HOOK: useMoldFieldWork — field tech mold operations
// ============================================================================

export function useMoldFieldWork(assessmentId: string) {
  const [assessment, setAssessment] = useState<MoldAssessmentSummary | null>(null);
  const [readings, setReadings] = useState<MoldMoistureReading[]>([]);
  const [equipment, setEquipment] = useState<MoldEquipmentDeployment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!assessmentId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const [assessRes, readingsRes] = await Promise.all([
        supabase
          .from('mold_assessments')
          .select('id, property_id, job_id, assessment_date, suspected_cause, affected_area_sqft, remediation_level, overall_notes')
          .eq('id', assessmentId)
          .is('deleted_at', null)
          .single(),
        supabase
          .from('mold_moisture_readings')
          .select()
          .eq('assessment_id', assessmentId)
          .order('created_at', { ascending: false }),
      ]);

      if (assessRes.error) throw assessRes.error;
      if (readingsRes.error) throw readingsRes.error;

      setAssessment(snakeToCamel(assessRes.data) as unknown as MoldAssessmentSummary);
      setReadings(mapRows<MoldMoistureReading>(readingsRes.data ?? []));

      // Load equipment if there's a remediation plan
      const { data: planData } = await supabase
        .from('mold_remediation_plans')
        .select('id')
        .eq('assessment_id', assessmentId)
        .is('deleted_at', null)
        .limit(1)
        .maybeSingle();

      if (planData) {
        const { data: eqData, error: eqErr } = await supabase
          .from('mold_equipment_deployments')
          .select()
          .eq('remediation_id', planData.id)
          .order('deployed_at', { ascending: false });
        if (!eqErr) setEquipment(mapRows<MoldEquipmentDeployment>(eqData ?? []));
      }
    } catch (e) {
      console.error('Failed to load mold field data:', e);
      setError('Could not load mold assessment data.');
    } finally {
      setLoading(false);
    }
  }, [assessmentId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const recordMoistureReading = useCallback(
    async (reading: {
      companyId: string;
      roomName: string;
      locationDetail?: string;
      readingType: MoistureReadingType;
      readingValue: number;
      readingUnit?: string;
      severity?: MoistureSeverity;
      meterModel?: string;
      notes?: string;
    }) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_moisture_readings')
        .insert({
          company_id: reading.companyId,
          assessment_id: assessmentId,
          room_name: reading.roomName,
          location_detail: reading.locationDetail ?? null,
          reading_type: reading.readingType,
          reading_value: reading.readingValue,
          reading_unit: reading.readingUnit ?? '%',
          severity: reading.severity ?? null,
          meter_model: reading.meterModel ?? null,
          notes: reading.notes ?? null,
        });
      if (err) throw err;
      await loadData();
    },
    [assessmentId, loadData]
  );

  const deployEquipment = useCallback(
    async (deployment: {
      companyId: string;
      remediationId: string;
      equipmentType: MoldEquipmentType;
      modelName?: string;
      serialNumber?: string;
      capacity?: string;
      placementLocation?: string;
      notes?: string;
    }) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_equipment_deployments')
        .insert({
          company_id: deployment.companyId,
          remediation_id: deployment.remediationId,
          equipment_type: deployment.equipmentType,
          model_name: deployment.modelName ?? null,
          serial_number: deployment.serialNumber ?? null,
          capacity: deployment.capacity ?? null,
          placement_location: deployment.placementLocation ?? null,
          deployed_at: new Date().toISOString(),
          notes: deployment.notes ?? null,
        });
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const retrieveEquipment = useCallback(
    async (id: string, updatedAt: string, runtimeHours?: number) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_equipment_deployments')
        .update({
          retrieved_at: new Date().toISOString(),
          runtime_hours: runtimeHours ?? null,
        })
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const collectLabSample = useCallback(
    async (sample: {
      companyId: string;
      sampleType: LabSampleType;
      sampleLocation: string;
      roomName?: string;
      labName?: string;
      notes?: string;
    }) => {
      const supabase = getSupabase();
      const {
        data: { user },
      } = await supabase.auth.getUser();

      const { error: err } = await supabase
        .from('mold_lab_samples')
        .insert({
          company_id: sample.companyId,
          assessment_id: assessmentId,
          sample_type: sample.sampleType,
          sample_location: sample.sampleLocation,
          room_name: sample.roomName ?? null,
          date_collected: new Date().toISOString().split('T')[0],
          collected_by: user?.id ?? null,
          lab_name: sample.labName ?? null,
          status: 'pending',
          notes: sample.notes ?? null,
        });
      if (err) throw err;
    },
    [assessmentId]
  );

  return {
    assessment,
    readings,
    equipment,
    loading,
    error,
    reload: loadData,
    recordMoistureReading,
    deployEquipment,
    retrieveEquipment,
    collectLabSample,
  };
}

// ============================================================================
// HOOK: useMoldLicensing — state licensing reference
// ============================================================================

export function useMoldLicensing() {
  const [states, setStates] = useState<MoldStateLicensing[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('mold_state_licensing')
        .select('id, state_code, state_name, license_required, license_types, issuing_agency, agency_url, notes')
        .order('state_name');
      if (err) throw err;
      setStates(mapRows<MoldStateLicensing>(data ?? []));
    } catch (e) {
      console.error('Failed to load mold licensing:', e);
      setError('Could not load state licensing data.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  return { states, loading, error, reload: loadData };
}
