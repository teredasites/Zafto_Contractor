'use client';

// DEPTH34: Property Preservation Hook (Team Portal)
// Field technicians: view assigned WOs, update status, record winterization,
// debris estimates, utility checks. Read-only for reference data.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type PpWorkOrderStatus =
  | 'assigned'
  | 'in_progress'
  | 'completed'
  | 'submitted'
  | 'approved'
  | 'rejected'
  | 'disputed';

export interface PpWorkOrder {
  id: string;
  companyId: string;
  propertyId: string | null;
  jobId: string | null;
  nationalCompanyId: string | null;
  workOrderTypeId: string;
  externalOrderId: string | null;
  status: PpWorkOrderStatus;
  assignedTo: string | null;
  assignedAt: string | null;
  startedAt: string | null;
  completedAt: string | null;
  submittedAt: string | null;
  dueDate: string | null;
  bidAmount: number | null;
  approvedAmount: number | null;
  photoMode: string;
  checklistProgress: Record<string, unknown>;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface PpWorkOrderType {
  id: string;
  code: string;
  name: string;
  category: string;
  description: string | null;
  defaultChecklist: unknown[];
  requiredPhotos: unknown[];
  estimatedHours: number | null;
}

export interface PpNationalCompany {
  id: string;
  name: string;
  photoOrientation: string | null;
  requiredShots: Record<string, unknown>;
  submissionDeadlineHours: number;
}

export interface BoilerFurnaceModel {
  id: string;
  manufacturer: string;
  modelName: string;
  modelNumber: string | null;
  equipmentType: string;
  fuelType: string | null;
  commonIssues: unknown[];
  winterizationNotes: string | null;
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
// HOOK: useMyPpWorkOrders — field tech's assigned work orders
// ============================================================================

export function useMyPpWorkOrders() {
  const [workOrders, setWorkOrders] = useState<PpWorkOrder[]>([]);
  const [woTypes, setWoTypes] = useState<PpWorkOrderType[]>([]);
  const [nationals, setNationals] = useState<PpNationalCompany[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const [woRes, typesRes, nationalsRes] = await Promise.all([
        supabase
          .from('pp_work_orders')
          .select()
          .eq('assigned_to', user.id)
          .is('deleted_at', null)
          .order('due_date', { ascending: true }),
        supabase
          .from('pp_work_order_types')
          .select('id, code, name, category, description, default_checklist, required_photos, estimated_hours')
          .order('category'),
        supabase
          .from('pp_national_companies')
          .select('id, name, photo_orientation, required_shots, submission_deadline_hours')
          .eq('is_active', true)
          .is('deleted_at', null)
          .order('name'),
      ]);

      if (woRes.error) throw woRes.error;
      if (typesRes.error) throw typesRes.error;
      if (nationalsRes.error) throw nationalsRes.error;

      setWorkOrders(mapRows<PpWorkOrder>(woRes.data ?? []));
      setWoTypes(mapRows<PpWorkOrderType>(typesRes.data ?? []));
      setNationals(mapRows<PpNationalCompany>(nationalsRes.data ?? []));
    } catch (e) {
      console.error('Failed to load PP work orders:', e);
      setError('Could not load work orders.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const updateStatus = useCallback(
    async (id: string, updatedAt: string, newStatus: PpWorkOrderStatus) => {
      const supabase = getSupabase();
      const now = new Date().toISOString();
      const patch: Record<string, unknown> = { status: newStatus };

      if (newStatus === 'in_progress') patch.started_at = now;
      else if (newStatus === 'completed') patch.completed_at = now;
      else if (newStatus === 'submitted') patch.submitted_at = now;

      const { error: err } = await supabase
        .from('pp_work_orders')
        .update(patch)
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  const updateChecklist = useCallback(
    async (id: string, updatedAt: string, checklistProgress: Record<string, unknown>) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('pp_work_orders')
        .update({ checklist_progress: checklistProgress })
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadData();
    },
    [loadData]
  );

  return {
    workOrders,
    woTypes,
    nationals,
    loading,
    error,
    reload: loadData,
    updateStatus,
    updateChecklist,
  };
}

// ============================================================================
// HOOK: usePpFieldTools — winterization, debris, boiler lookup for field
// ============================================================================

export function usePpFieldTools() {
  const [boilerModels, setBoilerModels] = useState<BoilerFurnaceModel[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const searchBoilerModels = useCallback(async (query: string) => {
    if (!query || query.length < 2) {
      setBoilerModels([]);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('boiler_furnace_models')
        .select('id, manufacturer, model_name, model_number, equipment_type, fuel_type, common_issues, winterization_notes')
        .or(`manufacturer.ilike.%${query}%,model_name.ilike.%${query}%`)
        .order('manufacturer')
        .limit(20);
      if (err) throw err;
      setBoilerModels(mapRows<BoilerFurnaceModel>(data ?? []));
    } catch (e) {
      console.error('Failed to search boiler models:', e);
      setError('Could not search equipment models.');
    } finally {
      setLoading(false);
    }
  }, []);

  const recordWinterization = useCallback(
    async (rec: {
      companyId: string;
      workOrderId?: string;
      propertyId?: string;
      recordType: string;
      heatType?: string;
      hasWell?: boolean;
      hasSeptic?: boolean;
      hasSprinkler?: boolean;
      pressureTestStartPsi?: number;
      pressureTestEndPsi?: number;
      pressureTestDurationMin?: number;
      pressureTestPassed?: boolean;
      antifreezeGallons?: number;
      fixtureCount?: number;
      checklistData?: Record<string, unknown>;
      notes?: string;
    }) => {
      const supabase = getSupabase();
      const {
        data: { user },
      } = await supabase.auth.getUser();

      const { error: err } = await supabase
        .from('pp_winterization_records')
        .insert({
          company_id: rec.companyId,
          work_order_id: rec.workOrderId ?? null,
          property_id: rec.propertyId ?? null,
          record_type: rec.recordType,
          heat_type: rec.heatType ?? 'none',
          has_well: rec.hasWell ?? false,
          has_septic: rec.hasSeptic ?? false,
          has_sprinkler: rec.hasSprinkler ?? false,
          pressure_test_start_psi: rec.pressureTestStartPsi ?? null,
          pressure_test_end_psi: rec.pressureTestEndPsi ?? null,
          pressure_test_duration_min: rec.pressureTestDurationMin ?? 30,
          pressure_test_passed: rec.pressureTestPassed ?? null,
          antifreeze_gallons: rec.antifreezeGallons ?? null,
          fixture_count: rec.fixtureCount ?? null,
          checklist_data: rec.checklistData ?? {},
          completed_by: user?.id ?? null,
          completed_at: new Date().toISOString(),
          notes: rec.notes ?? null,
        });
      if (err) throw err;
    },
    []
  );

  const recordDebrisEstimate = useCallback(
    async (est: {
      companyId: string;
      workOrderId?: string;
      propertyId?: string;
      estimationMethod: string;
      roomsData?: unknown[];
      propertySqft?: number;
      cleanoutLevel?: string;
      hoardingLevel?: number;
      totalCubicYards?: number;
      estimatedWeightLbs?: number;
      recommendedDumpsterSize?: number;
      dumpsterPulls?: number;
      notes?: string;
    }) => {
      const supabase = getSupabase();
      const { error: err } = await supabase.from('pp_debris_estimates').insert({
        company_id: est.companyId,
        work_order_id: est.workOrderId ?? null,
        property_id: est.propertyId ?? null,
        estimation_method: est.estimationMethod,
        rooms_data: est.roomsData ?? [],
        property_sqft: est.propertySqft ?? null,
        cleanout_level: est.cleanoutLevel ?? null,
        hoarding_level: est.hoardingLevel ?? null,
        total_cubic_yards: est.totalCubicYards ?? null,
        estimated_weight_lbs: est.estimatedWeightLbs ?? null,
        recommended_dumpster_size: est.recommendedDumpsterSize ?? null,
        dumpster_pulls: est.dumpsterPulls ?? 1,
        notes: est.notes ?? null,
      });
      if (err) throw err;
    },
    []
  );

  return {
    boilerModels,
    loading,
    error,
    searchBoilerModels,
    recordWinterization,
    recordDebrisEstimate,
  };
}
