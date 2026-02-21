'use client';

// DEPTH35: Mold Remediation CRM Hook (Web Portal)
// Assessments, moisture readings, remediation plans, equipment deployments,
// lab samples, clearance tests, state licensing reference.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type MoldSuspectedCause =
  | 'water_intrusion'
  | 'hvac_issue'
  | 'plumbing_leak'
  | 'flooding'
  | 'condensation'
  | 'unknown'
  | 'roof_leak'
  | 'foundation_crack';

export type MoistureSourceStatus = 'active_leak' | 'resolved' | 'unknown';

export type OccupancyStatus = 'occupied' | 'vacant' | 'evacuated';

export type MoistureReadingType =
  | 'surface_pin'
  | 'relative_humidity'
  | 'dew_point'
  | 'wood_moisture_content';

export type MoistureSeverity = 'normal' | 'concern' | 'saturation';

export type RemediationPlanStatus =
  | 'planned'
  | 'in_progress'
  | 'completed'
  | 'on_hold';

export type ContainmentType = 'minimal' | 'limited' | 'full';

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

export type ClearanceResult = 'pass' | 'fail' | 'conditional';

export interface MoldStateLicensing {
  id: string;
  stateCode: string;
  stateName: string;
  licenseRequired: boolean;
  licenseTypes: unknown[];
  issuingAgency: string | null;
  agencyUrl: string | null;
  costRange: string | null;
  renewalPeriod: string | null;
  ceRequirements: string | null;
  reciprocityStates: unknown[];
  notes: string | null;
}

export interface MoldAssessment {
  id: string;
  companyId: string;
  propertyId: string | null;
  jobId: string | null;
  assessedBy: string | null;
  assessmentDate: string;
  suspectedCause: MoldSuspectedCause;
  affectedAreaSqft: number | null;
  affectedMaterials: unknown[];
  visibleMoldType: unknown[];
  moistureSourceStatus: MoistureSourceStatus;
  occupancyStatus: OccupancyStatus;
  remediationLevel: number | null;
  overallNotes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface MoldMoistureReading {
  id: string;
  companyId: string;
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

export interface MoldRemediationPlan {
  id: string;
  companyId: string;
  assessmentId: string;
  jobId: string | null;
  remediationLevel: number;
  containmentType: ContainmentType | null;
  scopeDescription: string | null;
  materialsToRemove: unknown[];
  checklistProgress: Record<string, unknown>;
  status: RemediationPlanStatus;
  startedAt: string | null;
  completedAt: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface MoldEquipmentDeployment {
  id: string;
  companyId: string;
  remediationId: string | null;
  equipmentType: MoldEquipmentType;
  modelName: string | null;
  serialNumber: string | null;
  capacity: string | null;
  placementLocation: string | null;
  deployedAt: string;
  retrievedAt: string | null;
  runtimeHours: number | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface MoldLabSample {
  id: string;
  companyId: string;
  assessmentId: string | null;
  sampleType: LabSampleType;
  sampleLocation: string;
  roomName: string | null;
  dateCollected: string;
  collectedBy: string | null;
  labName: string | null;
  labReference: string | null;
  status: LabSampleStatus;
  speciesFound: unknown[];
  sporeCount: number | null;
  sporeCountUnit: string;
  outdoorBaseline: number | null;
  passFail: string | null;
  resultsNotes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface MoldClearanceTest {
  id: string;
  companyId: string;
  remediationId: string | null;
  assessmentId: string | null;
  clearanceDate: string;
  assessorName: string | null;
  assessorCompany: string | null;
  assessorLicense: string | null;
  visualPass: boolean | null;
  moisturePass: boolean | null;
  airQualityPass: boolean | null;
  odorPass: boolean | null;
  overallResult: ClearanceResult | null;
  postMoistureReadings: unknown[];
  labResultsRef: string | null;
  certificateNumber: string | null;
  certificateUrl: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
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
// HOOK: useMoldStateLicensing — system reference data
// ============================================================================

export function useMoldStateLicensing() {
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
        .select()
        .order('state_name');
      if (err) throw err;
      setStates(mapRows<MoldStateLicensing>(data ?? []));
    } catch (e) {
      console.error('Failed to load mold state licensing:', e);
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

// ============================================================================
// HOOK: useMoldAssessments — CRUD for assessments
// ============================================================================

export function useMoldAssessments(companyId: string, propertyId?: string, jobId?: string) {
  const [assessments, setAssessments] = useState<MoldAssessment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!companyId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let query = supabase
        .from('mold_assessments')
        .select()
        .eq('company_id', companyId)
        .is('deleted_at', null)
        .order('assessment_date', { ascending: false });

      if (propertyId) query = query.eq('property_id', propertyId);
      if (jobId) query = query.eq('job_id', jobId);

      const { data, error: err } = await query;
      if (err) throw err;
      setAssessments(mapRows<MoldAssessment>(data ?? []));
    } catch (e) {
      console.error('Failed to load mold assessments:', e);
      setError('Could not load assessments.');
    } finally {
      setLoading(false);
    }
  }, [companyId, propertyId, jobId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const createAssessment = useCallback(
    async (assessment: Omit<MoldAssessment, 'id' | 'createdAt' | 'updatedAt'>) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_assessments')
        .insert({
          company_id: assessment.companyId,
          property_id: assessment.propertyId,
          job_id: assessment.jobId,
          assessed_by: assessment.assessedBy,
          assessment_date: assessment.assessmentDate,
          suspected_cause: assessment.suspectedCause,
          affected_area_sqft: assessment.affectedAreaSqft,
          affected_materials: assessment.affectedMaterials,
          visible_mold_type: assessment.visibleMoldType,
          moisture_source_status: assessment.moistureSourceStatus,
          occupancy_status: assessment.occupancyStatus,
          remediation_level: assessment.remediationLevel,
          overall_notes: assessment.overallNotes,
        });
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const updateAssessment = useCallback(
    async (
      id: string,
      updatedAt: string,
      patch: Partial<MoldAssessment>
    ) => {
      const supabase = getSupabase();
      const row: Record<string, unknown> = {};
      if (patch.suspectedCause !== undefined) row.suspected_cause = patch.suspectedCause;
      if (patch.affectedAreaSqft !== undefined) row.affected_area_sqft = patch.affectedAreaSqft;
      if (patch.affectedMaterials !== undefined) row.affected_materials = patch.affectedMaterials;
      if (patch.visibleMoldType !== undefined) row.visible_mold_type = patch.visibleMoldType;
      if (patch.moistureSourceStatus !== undefined) row.moisture_source_status = patch.moistureSourceStatus;
      if (patch.occupancyStatus !== undefined) row.occupancy_status = patch.occupancyStatus;
      if (patch.remediationLevel !== undefined) row.remediation_level = patch.remediationLevel;
      if (patch.overallNotes !== undefined) row.overall_notes = patch.overallNotes;

      const { error: err } = await supabase
        .from('mold_assessments')
        .update(row)
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const deleteAssessment = useCallback(
    async (id: string, updatedAt: string) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_assessments')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  return {
    assessments,
    loading,
    error,
    reload: loadData,
    createAssessment,
    updateAssessment,
    deleteAssessment,
  };
}

// ============================================================================
// HOOK: useMoldMoistureReadings — insert-only sensor data
// ============================================================================

export function useMoldMoistureReadings(assessmentId: string) {
  const [readings, setReadings] = useState<MoldMoistureReading[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!assessmentId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('mold_moisture_readings')
        .select()
        .eq('assessment_id', assessmentId)
        .order('created_at', { ascending: false });
      if (err) throw err;
      setReadings(mapRows<MoldMoistureReading>(data ?? []));
    } catch (e) {
      console.error('Failed to load moisture readings:', e);
      setError('Could not load moisture readings.');
    } finally {
      setLoading(false);
    }
  }, [assessmentId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const createReading = useCallback(
    async (reading: {
      companyId: string;
      assessmentId: string;
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
          assessment_id: reading.assessmentId,
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
    [loadData]
  );

  return { readings, loading, error, reload: loadData, createReading };
}

// ============================================================================
// HOOK: useMoldRemediationPlans — CRUD for remediation plans
// ============================================================================

export function useMoldRemediationPlans(assessmentId?: string, companyId?: string) {
  const [plans, setPlans] = useState<MoldRemediationPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!assessmentId && !companyId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let query = supabase
        .from('mold_remediation_plans')
        .select()
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (assessmentId) {
        query = query.eq('assessment_id', assessmentId);
      } else if (companyId) {
        query = query.eq('company_id', companyId);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setPlans(mapRows<MoldRemediationPlan>(data ?? []));
    } catch (e) {
      console.error('Failed to load remediation plans:', e);
      setError('Could not load remediation plans.');
    } finally {
      setLoading(false);
    }
  }, [assessmentId, companyId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const createPlan = useCallback(
    async (plan: {
      companyId: string;
      assessmentId: string;
      jobId?: string;
      remediationLevel: number;
      containmentType?: ContainmentType;
      scopeDescription?: string;
      materialsToRemove?: unknown[];
      notes?: string;
    }) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_remediation_plans')
        .insert({
          company_id: plan.companyId,
          assessment_id: plan.assessmentId,
          job_id: plan.jobId ?? null,
          remediation_level: plan.remediationLevel,
          containment_type: plan.containmentType ?? null,
          scope_description: plan.scopeDescription ?? null,
          materials_to_remove: plan.materialsToRemove ?? [],
          checklist_progress: {},
          status: 'planned',
          notes: plan.notes ?? null,
        });
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const updatePlan = useCallback(
    async (id: string, updatedAt: string, patch: Partial<MoldRemediationPlan>) => {
      const supabase = getSupabase();
      const row: Record<string, unknown> = {};
      if (patch.remediationLevel !== undefined) row.remediation_level = patch.remediationLevel;
      if (patch.containmentType !== undefined) row.containment_type = patch.containmentType;
      if (patch.scopeDescription !== undefined) row.scope_description = patch.scopeDescription;
      if (patch.materialsToRemove !== undefined) row.materials_to_remove = patch.materialsToRemove;
      if (patch.checklistProgress !== undefined) row.checklist_progress = patch.checklistProgress;
      if (patch.notes !== undefined) row.notes = patch.notes;

      const { error: err } = await supabase
        .from('mold_remediation_plans')
        .update(row)
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const updatePlanStatus = useCallback(
    async (id: string, updatedAt: string, status: RemediationPlanStatus) => {
      const supabase = getSupabase();
      const patch: Record<string, unknown> = { status };
      const now = new Date().toISOString();
      if (status === 'in_progress') patch.started_at = now;
      else if (status === 'completed') patch.completed_at = now;

      const { error: err } = await supabase
        .from('mold_remediation_plans')
        .update(patch)
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const deletePlan = useCallback(
    async (id: string, updatedAt: string) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_remediation_plans')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  return {
    plans,
    loading,
    error,
    reload: loadData,
    createPlan,
    updatePlan,
    updatePlanStatus,
    deletePlan,
  };
}

// ============================================================================
// HOOK: useMoldEquipment — deploy/retrieve equipment
// ============================================================================

export function useMoldEquipment(remediationId?: string, companyId?: string) {
  const [deployments, setDeployments] = useState<MoldEquipmentDeployment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!remediationId && !companyId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let query = supabase
        .from('mold_equipment_deployments')
        .select()
        .order('deployed_at', { ascending: false });

      if (remediationId) {
        query = query.eq('remediation_id', remediationId);
      } else if (companyId) {
        query = query.eq('company_id', companyId).is('retrieved_at', null);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setDeployments(mapRows<MoldEquipmentDeployment>(data ?? []));
    } catch (e) {
      console.error('Failed to load equipment deployments:', e);
      setError('Could not load equipment deployments.');
    } finally {
      setLoading(false);
    }
  }, [remediationId, companyId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const deployEquipment = useCallback(
    async (deployment: {
      companyId: string;
      remediationId?: string;
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
          remediation_id: deployment.remediationId ?? null,
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

  const updateDeployment = useCallback(
    async (id: string, updatedAt: string, patch: Partial<MoldEquipmentDeployment>) => {
      const supabase = getSupabase();
      const row: Record<string, unknown> = {};
      if (patch.placementLocation !== undefined) row.placement_location = patch.placementLocation;
      if (patch.notes !== undefined) row.notes = patch.notes;
      if (patch.capacity !== undefined) row.capacity = patch.capacity;

      const { error: err } = await supabase
        .from('mold_equipment_deployments')
        .update(row)
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  return {
    deployments,
    loading,
    error,
    reload: loadData,
    deployEquipment,
    retrieveEquipment,
    updateDeployment,
  };
}

// ============================================================================
// HOOK: useMoldLabSamples — CRUD for lab samples
// ============================================================================

export function useMoldLabSamples(assessmentId?: string, companyId?: string) {
  const [samples, setSamples] = useState<MoldLabSample[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!assessmentId && !companyId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let query = supabase
        .from('mold_lab_samples')
        .select()
        .is('deleted_at', null)
        .order('date_collected', { ascending: false });

      if (assessmentId) {
        query = query.eq('assessment_id', assessmentId);
      } else if (companyId) {
        query = query.eq('company_id', companyId);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setSamples(mapRows<MoldLabSample>(data ?? []));
    } catch (e) {
      console.error('Failed to load lab samples:', e);
      setError('Could not load lab samples.');
    } finally {
      setLoading(false);
    }
  }, [assessmentId, companyId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const createSample = useCallback(
    async (sample: {
      companyId: string;
      assessmentId?: string;
      sampleType: LabSampleType;
      sampleLocation: string;
      roomName?: string;
      dateCollected: string;
      collectedBy?: string;
      labName?: string;
      labReference?: string;
      notes?: string;
    }) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_lab_samples')
        .insert({
          company_id: sample.companyId,
          assessment_id: sample.assessmentId ?? null,
          sample_type: sample.sampleType,
          sample_location: sample.sampleLocation,
          room_name: sample.roomName ?? null,
          date_collected: sample.dateCollected,
          collected_by: sample.collectedBy ?? null,
          lab_name: sample.labName ?? null,
          lab_reference: sample.labReference ?? null,
          status: 'pending',
          notes: sample.notes ?? null,
        });
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const updateSampleStatus = useCallback(
    async (id: string, updatedAt: string, status: LabSampleStatus) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_lab_samples')
        .update({ status })
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const recordResults = useCallback(
    async (
      id: string,
      updatedAt: string,
      results: {
        speciesFound?: unknown[];
        sporeCount?: number;
        outdoorBaseline?: number;
        passFail?: string;
        resultsNotes?: string;
      }
    ) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_lab_samples')
        .update({
          status: 'results_in',
          species_found: results.speciesFound ?? [],
          spore_count: results.sporeCount ?? null,
          outdoor_baseline: results.outdoorBaseline ?? null,
          pass_fail: results.passFail ?? null,
          results_notes: results.resultsNotes ?? null,
        })
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const deleteSample = useCallback(
    async (id: string, updatedAt: string) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_lab_samples')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  return {
    samples,
    loading,
    error,
    reload: loadData,
    createSample,
    updateSampleStatus,
    recordResults,
    deleteSample,
  };
}

// ============================================================================
// HOOK: useMoldClearanceTests — CRUD for clearance tests
// ============================================================================

export function useMoldClearanceTests(remediationId?: string, assessmentId?: string) {
  const [tests, setTests] = useState<MoldClearanceTest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!remediationId && !assessmentId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let query = supabase
        .from('mold_clearance_tests')
        .select()
        .is('deleted_at', null)
        .order('clearance_date', { ascending: false });

      if (remediationId) {
        query = query.eq('remediation_id', remediationId);
      } else if (assessmentId) {
        query = query.eq('assessment_id', assessmentId);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setTests(mapRows<MoldClearanceTest>(data ?? []));
    } catch (e) {
      console.error('Failed to load clearance tests:', e);
      setError('Could not load clearance tests.');
    } finally {
      setLoading(false);
    }
  }, [remediationId, assessmentId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const createClearanceTest = useCallback(
    async (test: {
      companyId: string;
      remediationId?: string;
      assessmentId?: string;
      clearanceDate: string;
      assessorName?: string;
      assessorCompany?: string;
      assessorLicense?: string;
      visualPass?: boolean;
      moisturePass?: boolean;
      airQualityPass?: boolean;
      odorPass?: boolean;
      overallResult?: ClearanceResult;
      postMoistureReadings?: unknown[];
      labResultsRef?: string;
      certificateNumber?: string;
      notes?: string;
    }) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_clearance_tests')
        .insert({
          company_id: test.companyId,
          remediation_id: test.remediationId ?? null,
          assessment_id: test.assessmentId ?? null,
          clearance_date: test.clearanceDate,
          assessor_name: test.assessorName ?? null,
          assessor_company: test.assessorCompany ?? null,
          assessor_license: test.assessorLicense ?? null,
          visual_pass: test.visualPass ?? null,
          moisture_pass: test.moisturePass ?? null,
          air_quality_pass: test.airQualityPass ?? null,
          odor_pass: test.odorPass ?? null,
          overall_result: test.overallResult ?? null,
          post_moisture_readings: test.postMoistureReadings ?? [],
          lab_results_ref: test.labResultsRef ?? null,
          certificate_number: test.certificateNumber ?? null,
          notes: test.notes ?? null,
        });
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const updateClearanceTest = useCallback(
    async (id: string, updatedAt: string, patch: Partial<MoldClearanceTest>) => {
      const supabase = getSupabase();
      const row: Record<string, unknown> = {};
      if (patch.assessorName !== undefined) row.assessor_name = patch.assessorName;
      if (patch.assessorCompany !== undefined) row.assessor_company = patch.assessorCompany;
      if (patch.assessorLicense !== undefined) row.assessor_license = patch.assessorLicense;
      if (patch.visualPass !== undefined) row.visual_pass = patch.visualPass;
      if (patch.moisturePass !== undefined) row.moisture_pass = patch.moisturePass;
      if (patch.airQualityPass !== undefined) row.air_quality_pass = patch.airQualityPass;
      if (patch.odorPass !== undefined) row.odor_pass = patch.odorPass;
      if (patch.overallResult !== undefined) row.overall_result = patch.overallResult;
      if (patch.postMoistureReadings !== undefined) row.post_moisture_readings = patch.postMoistureReadings;
      if (patch.labResultsRef !== undefined) row.lab_results_ref = patch.labResultsRef;
      if (patch.certificateNumber !== undefined) row.certificate_number = patch.certificateNumber;
      if (patch.certificateUrl !== undefined) row.certificate_url = patch.certificateUrl;
      if (patch.notes !== undefined) row.notes = patch.notes;

      const { error: err } = await supabase
        .from('mold_clearance_tests')
        .update(row)
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const deleteClearanceTest = useCallback(
    async (id: string, updatedAt: string) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mold_clearance_tests')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  return {
    tests,
    loading,
    error,
    reload: loadData,
    createClearanceTest,
    updateClearanceTest,
    deleteClearanceTest,
  };
}
