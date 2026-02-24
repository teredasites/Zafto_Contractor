'use client';

// DEPTH34: Property Preservation Hook (CRM Portal)
// PP work orders, national companies, winterization, debris estimation,
// chargebacks, utility tracking, vendor apps, boiler/furnace DB,
// pricing matrices, stripped property estimates.

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

export type PhotoMode = 'quick' | 'standard' | 'full_protection';

export type PpWorkOrderCategory =
  | 'securing'
  | 'winterization'
  | 'debris'
  | 'lawn_snow'
  | 'inspection'
  | 'repair'
  | 'utility'
  | 'specialty';

export type DisputeStatus =
  | 'none'
  | 'submitted'
  | 'under_review'
  | 'resolved_won'
  | 'resolved_lost'
  | 'denied';

export type UtilityType = 'electric' | 'gas' | 'water' | 'oil' | 'propane';
export type UtilityStatus = 'on' | 'off' | 'meter_pulled' | 'winterized' | 'unknown';
export type EquipmentType = 'boiler' | 'furnace' | 'heat_pump' | 'water_heater';

export interface PpNationalCompany {
  id: string;
  name: string;
  nameNormalized: string;
  portalUrl: string | null;
  vendorSignupUrl: string | null;
  phone: string | null;
  email: string | null;
  photoNaming: string | null;
  photoOrientation: string | null;
  requiredShots: Record<string, unknown>;
  submissionDeadlineHours: number;
  paySchedule: string | null;
  insuranceMinimum: number | null;
  chargebackPolicy: string | null;
  notes: string | null;
  isActive: boolean;
}

export interface PpWorkOrderType {
  id: string;
  code: string;
  name: string;
  category: PpWorkOrderCategory;
  description: string | null;
  defaultChecklist: unknown[];
  requiredPhotos: unknown[];
  estimatedHours: number | null;
  notes: string | null;
}

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
  photoMode: PhotoMode;
  checklistProgress: Record<string, unknown>;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface PpChargeback {
  id: string;
  companyId: string;
  workOrderId: string | null;
  nationalCompanyId: string | null;
  propertyAddress: string | null;
  amount: number;
  reason: string;
  chargebackDate: string;
  disputeStatus: DisputeStatus;
  disputeSubmittedAt: string | null;
  disputeResolvedAt: string | null;
  evidenceNotes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface PpWinterizationRecord {
  id: string;
  companyId: string;
  workOrderId: string | null;
  propertyId: string | null;
  recordType: string;
  heatType: string | null;
  hasWell: boolean;
  hasSeptic: boolean;
  hasSprinkler: boolean;
  pressureTestStartPsi: number | null;
  pressureTestEndPsi: number | null;
  pressureTestDurationMin: number;
  pressureTestPassed: boolean | null;
  antifreezeGallons: number | null;
  fixtureCount: number | null;
  checklistData: Record<string, unknown>;
  completedBy: string | null;
  completedAt: string | null;
  certificateUrl: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface PpDebrisEstimate {
  id: string;
  companyId: string;
  workOrderId: string | null;
  propertyId: string | null;
  estimationMethod: string;
  roomsData: unknown[];
  propertySqft: number | null;
  cleanoutLevel: string | null;
  hoardingLevel: number | null;
  totalCubicYards: number | null;
  estimatedWeightLbs: number | null;
  recommendedDumpsterSize: number | null;
  dumpsterPulls: number;
  hudRatePerCy: number | null;
  estimatedRevenue: number | null;
  estimatedCost: number | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface PpUtilityTracking {
  id: string;
  companyId: string;
  propertyId: string | null;
  utilityType: UtilityType;
  status: UtilityStatus;
  providerName: string | null;
  accountNumber: string | null;
  contactPhone: string | null;
  lastChecked: string | null;
  nextAction: string | null;
  nextActionDate: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface PpVendorApplication {
  id: string;
  companyId: string;
  nationalCompanyId: string;
  status: string;
  appliedAt: string | null;
  approvedAt: string | null;
  rejectedAt: string | null;
  checklist: Record<string, unknown>;
  portalUsername: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface BoilerFurnaceModel {
  id: string;
  manufacturer: string;
  modelName: string;
  modelNumber: string | null;
  equipmentType: EquipmentType;
  fuelType: string | null;
  commonIssues: unknown[];
  errorCodes: Record<string, unknown>;
  winterizationNotes: string | null;
  serialDecoder: Record<string, unknown>;
  partsCommonlyNeeded: unknown[];
  approximateLifespanYears: number | null;
  isDiscontinued: boolean;
}

export interface PpPricingMatrix {
  id: string;
  stateCode: string;
  workOrderType: string;
  pricingSource: string;
  rate: number;
  rateUnit: string;
  conditions: string | null;
  effectiveDate: string;
}

export interface PpStrippedEstimate {
  id: string;
  companyId: string;
  workOrderId: string | null;
  propertyId: string | null;
  estimateType: string;
  inputData: Record<string, unknown>;
  materialsList: unknown[];
  materialCost: number | null;
  laborHours: number | null;
  laborCost: number | null;
  totalEstimate: number | null;
  hudAllowable: number | null;
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
// HOOK: usePpWorkOrders — work order CRUD
// ============================================================================

export function usePpWorkOrders(filters?: {
  status?: PpWorkOrderStatus;
  nationalCompanyId?: string;
  propertyId?: string;
  assignedTo?: string;
}) {
  const [workOrders, setWorkOrders] = useState<PpWorkOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadWorkOrders = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let q = supabase
        .from('pp_work_orders')
        .select()
        .is('deleted_at', null);

      if (filters?.status) q = q.eq('status', filters.status);
      if (filters?.nationalCompanyId) q = q.eq('national_company_id', filters.nationalCompanyId);
      if (filters?.propertyId) q = q.eq('property_id', filters.propertyId);
      if (filters?.assignedTo) q = q.eq('assigned_to', filters.assignedTo);

      const { data, error: err } = await q.order('created_at', { ascending: false });
      if (err) throw err;
      setWorkOrders(mapRows<PpWorkOrder>(data ?? []));
    } catch (e) {
      console.error('Failed to load PP work orders:', e);
      setError('Could not load work orders.');
    } finally {
      setLoading(false);
    }
  }, [filters?.status, filters?.nationalCompanyId, filters?.propertyId, filters?.assignedTo]);

  useEffect(() => {
    loadWorkOrders();
  }, [loadWorkOrders]);

  const createWorkOrder = useCallback(
    async (wo: Omit<PpWorkOrder, 'id' | 'createdAt' | 'updatedAt'>) => {
      const supabase = getSupabase();
      const payload: Record<string, unknown> = {
        company_id: wo.companyId,
        property_id: wo.propertyId,
        job_id: wo.jobId,
        national_company_id: wo.nationalCompanyId,
        work_order_type_id: wo.workOrderTypeId,
        external_order_id: wo.externalOrderId,
        status: wo.status ?? 'assigned',
        assigned_to: wo.assignedTo,
        due_date: wo.dueDate,
        bid_amount: wo.bidAmount,
        photo_mode: wo.photoMode ?? 'standard',
        notes: wo.notes,
      };
      const { error: err } = await supabase
        .from('pp_work_orders')
        .insert(payload);
      if (err) throw err;
      await loadWorkOrders();
    },
    [loadWorkOrders]
  );

  const updateWorkOrderStatus = useCallback(
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
      await loadWorkOrders();
    },
    [loadWorkOrders]
  );

  const deleteWorkOrder = useCallback(
    async (id: string, updatedAt: string) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('pp_work_orders')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadWorkOrders();
    },
    [loadWorkOrders]
  );

  return {
    workOrders,
    loading,
    error,
    reload: loadWorkOrders,
    createWorkOrder,
    updateWorkOrderStatus,
    deleteWorkOrder,
  };
}

// ============================================================================
// HOOK: usePpChargebacks — chargeback tracking & disputes
// ============================================================================

export function usePpChargebacks(filters?: {
  nationalCompanyId?: string;
  disputeStatus?: DisputeStatus;
}) {
  const [chargebacks, setChargebacks] = useState<PpChargeback[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadChargebacks = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let q = supabase
        .from('pp_chargebacks')
        .select()
        .is('deleted_at', null);

      if (filters?.nationalCompanyId) q = q.eq('national_company_id', filters.nationalCompanyId);
      if (filters?.disputeStatus) q = q.eq('dispute_status', filters.disputeStatus);

      const { data, error: err } = await q.order('chargeback_date', { ascending: false });
      if (err) throw err;
      setChargebacks(mapRows<PpChargeback>(data ?? []));
    } catch (e) {
      console.error('Failed to load PP chargebacks:', e);
      setError('Could not load chargebacks.');
    } finally {
      setLoading(false);
    }
  }, [filters?.nationalCompanyId, filters?.disputeStatus]);

  useEffect(() => {
    loadChargebacks();
  }, [loadChargebacks]);

  const createChargeback = useCallback(
    async (cb: Omit<PpChargeback, 'id' | 'createdAt' | 'updatedAt'>) => {
      const supabase = getSupabase();
      const { error: err } = await supabase.from('pp_chargebacks').insert({
        company_id: cb.companyId,
        work_order_id: cb.workOrderId,
        national_company_id: cb.nationalCompanyId,
        property_address: cb.propertyAddress,
        amount: cb.amount,
        reason: cb.reason,
        chargeback_date: cb.chargebackDate,
        dispute_status: cb.disputeStatus ?? 'none',
        evidence_notes: cb.evidenceNotes,
      });
      if (err) throw err;
      await loadChargebacks();
    },
    [loadChargebacks]
  );

  const submitDispute = useCallback(
    async (id: string, updatedAt: string, evidenceNotes: string) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('pp_chargebacks')
        .update({
          dispute_status: 'submitted',
          dispute_submitted_at: new Date().toISOString(),
          evidence_notes: evidenceNotes,
        })
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadChargebacks();
    },
    [loadChargebacks]
  );

  return { chargebacks, loading, error, reload: loadChargebacks, createChargeback, submitDispute };
}

// ============================================================================
// HOOK: usePpWinterization — winterization/dewinterization records
// ============================================================================

export function usePpWinterization(propertyId?: string) {
  const [records, setRecords] = useState<PpWinterizationRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadRecords = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let q = supabase
        .from('pp_winterization_records')
        .select()
        .is('deleted_at', null);

      if (propertyId) q = q.eq('property_id', propertyId);

      const { data, error: err } = await q.order('created_at', { ascending: false });
      if (err) throw err;
      setRecords(mapRows<PpWinterizationRecord>(data ?? []));
    } catch (e) {
      console.error('Failed to load winterization records:', e);
      setError('Could not load winterization records.');
    } finally {
      setLoading(false);
    }
  }, [propertyId]);

  useEffect(() => {
    loadRecords();
  }, [loadRecords]);

  const createRecord = useCallback(
    async (rec: Omit<PpWinterizationRecord, 'id' | 'createdAt' | 'updatedAt'>) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('pp_winterization_records')
        .insert({
          company_id: rec.companyId,
          work_order_id: rec.workOrderId,
          property_id: rec.propertyId,
          record_type: rec.recordType,
          heat_type: rec.heatType,
          has_well: rec.hasWell,
          has_septic: rec.hasSeptic,
          has_sprinkler: rec.hasSprinkler,
          pressure_test_start_psi: rec.pressureTestStartPsi,
          pressure_test_end_psi: rec.pressureTestEndPsi,
          pressure_test_duration_min: rec.pressureTestDurationMin ?? 30,
          pressure_test_passed: rec.pressureTestPassed,
          antifreeze_gallons: rec.antifreezeGallons,
          fixture_count: rec.fixtureCount,
          checklist_data: rec.checklistData,
          notes: rec.notes,
        });
      if (err) throw err;
      await loadRecords();
    },
    [loadRecords]
  );

  return { records, loading, error, reload: loadRecords, createRecord };
}

// ============================================================================
// HOOK: usePpDebris — debris estimation
// ============================================================================

export function usePpDebris(propertyId?: string) {
  const [estimates, setEstimates] = useState<PpDebrisEstimate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadEstimates = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let q = supabase
        .from('pp_debris_estimates')
        .select()
        .is('deleted_at', null);

      if (propertyId) q = q.eq('property_id', propertyId);

      const { data, error: err } = await q.order('created_at', { ascending: false });
      if (err) throw err;
      setEstimates(mapRows<PpDebrisEstimate>(data ?? []));
    } catch (e) {
      console.error('Failed to load debris estimates:', e);
      setError('Could not load debris estimates.');
    } finally {
      setLoading(false);
    }
  }, [propertyId]);

  useEffect(() => {
    loadEstimates();
  }, [loadEstimates]);

  const createEstimate = useCallback(
    async (est: Omit<PpDebrisEstimate, 'id' | 'createdAt' | 'updatedAt'>) => {
      const supabase = getSupabase();
      const { error: err } = await supabase.from('pp_debris_estimates').insert({
        company_id: est.companyId,
        work_order_id: est.workOrderId,
        property_id: est.propertyId,
        estimation_method: est.estimationMethod,
        rooms_data: est.roomsData,
        property_sqft: est.propertySqft,
        cleanout_level: est.cleanoutLevel,
        hoarding_level: est.hoardingLevel,
        total_cubic_yards: est.totalCubicYards,
        estimated_weight_lbs: est.estimatedWeightLbs,
        recommended_dumpster_size: est.recommendedDumpsterSize,
        dumpster_pulls: est.dumpsterPulls ?? 1,
        hud_rate_per_cy: est.hudRatePerCy,
        estimated_revenue: est.estimatedRevenue,
        estimated_cost: est.estimatedCost,
        notes: est.notes,
      });
      if (err) throw err;
      await loadEstimates();
    },
    [loadEstimates]
  );

  return { estimates, loading, error, reload: loadEstimates, createEstimate };
}

// ============================================================================
// HOOK: usePpUtilities — utility tracking per property
// ============================================================================

export function usePpUtilities(propertyId?: string) {
  const [utilities, setUtilities] = useState<PpUtilityTracking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadUtilities = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let q = supabase
        .from('pp_utility_tracking')
        .select()
        .is('deleted_at', null);

      if (propertyId) q = q.eq('property_id', propertyId);

      const { data, error: err } = await q.order('utility_type');
      if (err) throw err;
      setUtilities(mapRows<PpUtilityTracking>(data ?? []));
    } catch (e) {
      console.error('Failed to load PP utilities:', e);
      setError('Could not load utility tracking.');
    } finally {
      setLoading(false);
    }
  }, [propertyId]);

  useEffect(() => {
    loadUtilities();
  }, [loadUtilities]);

  const createUtility = useCallback(
    async (util: Omit<PpUtilityTracking, 'id' | 'createdAt' | 'updatedAt'>) => {
      const supabase = getSupabase();
      const { error: err } = await supabase.from('pp_utility_tracking').insert({
        company_id: util.companyId,
        property_id: util.propertyId,
        utility_type: util.utilityType,
        status: util.status ?? 'unknown',
        provider_name: util.providerName,
        account_number: util.accountNumber,
        contact_phone: util.contactPhone,
        next_action: util.nextAction,
        next_action_date: util.nextActionDate,
        notes: util.notes,
      });
      if (err) throw err;
      await loadUtilities();
    },
    [loadUtilities]
  );

  const updateUtility = useCallback(
    async (id: string, updatedAt: string, patch: Partial<PpUtilityTracking>) => {
      const supabase = getSupabase();
      const dbPatch: Record<string, unknown> = {};
      if (patch.status !== undefined) dbPatch.status = patch.status;
      if (patch.providerName !== undefined) dbPatch.provider_name = patch.providerName;
      if (patch.accountNumber !== undefined) dbPatch.account_number = patch.accountNumber;
      if (patch.contactPhone !== undefined) dbPatch.contact_phone = patch.contactPhone;
      if (patch.nextAction !== undefined) dbPatch.next_action = patch.nextAction;
      if (patch.nextActionDate !== undefined) dbPatch.next_action_date = patch.nextActionDate;
      if (patch.notes !== undefined) dbPatch.notes = patch.notes;
      dbPatch.last_checked = new Date().toISOString();

      const { error: err } = await supabase
        .from('pp_utility_tracking')
        .update(dbPatch)
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadUtilities();
    },
    [loadUtilities]
  );

  return { utilities, loading, error, reload: loadUtilities, createUtility, updateUtility };
}

// ============================================================================
// HOOK: usePpVendorApps — vendor application tracking
// ============================================================================

export function usePpVendorApps() {
  const [applications, setApplications] = useState<PpVendorApplication[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadApps = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('pp_vendor_applications')
        .select()
        .is('deleted_at', null)
        .order('created_at', { ascending: false });
      if (err) throw err;
      setApplications(mapRows<PpVendorApplication>(data ?? []));
    } catch (e) {
      console.error('Failed to load vendor apps:', e);
      setError('Could not load vendor applications.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadApps();
  }, [loadApps]);

  const upsertApplication = useCallback(
    async (app: Omit<PpVendorApplication, 'id' | 'createdAt' | 'updatedAt'>) => {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('pp_vendor_applications')
        .upsert(
          {
            company_id: app.companyId,
            national_company_id: app.nationalCompanyId,
            status: app.status ?? 'not_started',
            checklist: app.checklist,
            portal_username: app.portalUsername,
            notes: app.notes,
          },
          { onConflict: 'company_id,national_company_id' }
        );
      if (err) throw err;
      await loadApps();
    },
    [loadApps]
  );

  const updateAppStatus = useCallback(
    async (id: string, updatedAt: string, newStatus: string) => {
      const supabase = getSupabase();
      const now = new Date().toISOString();
      const patch: Record<string, unknown> = { status: newStatus };
      if (newStatus === 'submitted') patch.applied_at = now;
      else if (newStatus === 'approved') patch.approved_at = now;
      else if (newStatus === 'rejected') patch.rejected_at = now;

      const { error: err } = await supabase
        .from('pp_vendor_applications')
        .update(patch)
        .eq('id', id)
        .eq('updated_at', updatedAt);
      if (err) throw err;
      await loadApps();
    },
    [loadApps]
  );

  return { applications, loading, error, reload: loadApps, upsertApplication, updateAppStatus };
}

// ============================================================================
// HOOK: usePpReferenceData — national companies, WO types, boiler models, pricing
// ============================================================================

export function usePpReferenceData() {
  const [nationals, setNationals] = useState<PpNationalCompany[]>([]);
  const [woTypes, setWoTypes] = useState<PpWorkOrderType[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      setError(null);
      try {
        const supabase = getSupabase();
        const [nationalsRes, typesRes] = await Promise.all([
          supabase
            .from('pp_national_companies')
            .select()
            .eq('is_active', true)
            .is('deleted_at', null)
            .order('name'),
          supabase
            .from('pp_work_order_types')
            .select()
            .order('category')
            .order('name'),
        ]);
        if (nationalsRes.error) throw nationalsRes.error;
        if (typesRes.error) throw typesRes.error;
        setNationals(mapRows<PpNationalCompany>(nationalsRes.data ?? []));
        setWoTypes(mapRows<PpWorkOrderType>(typesRes.data ?? []));
      } catch (e) {
        console.error('Failed to load PP reference data:', e);
        setError('Could not load reference data.');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  return { nationals, woTypes, loading, error };
}

// ============================================================================
// HOOK: usePpBoilerModels — boiler/furnace model database
// ============================================================================

export function usePpBoilerModels(filters?: {
  equipmentType?: EquipmentType;
  fuelType?: string;
  manufacturer?: string;
  search?: string;
}) {
  const [models, setModels] = useState<BoilerFurnaceModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadModels = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let q = supabase.from('boiler_furnace_models').select();

      if (filters?.equipmentType) q = q.eq('equipment_type', filters.equipmentType);
      if (filters?.fuelType) q = q.eq('fuel_type', filters.fuelType);
      if (filters?.manufacturer) q = q.eq('manufacturer', filters.manufacturer);
      if (filters?.search) {
        q = q.or(`manufacturer.ilike.%${filters.search}%,model_name.ilike.%${filters.search}%`);
      }

      const { data, error: err } = await q.order('manufacturer').order('model_name');
      if (err) throw err;
      setModels(mapRows<BoilerFurnaceModel>(data ?? []));
    } catch (e) {
      console.error('Failed to load boiler models:', e);
      setError('Could not load equipment models.');
    } finally {
      setLoading(false);
    }
  }, [filters?.equipmentType, filters?.fuelType, filters?.manufacturer, filters?.search]);

  useEffect(() => {
    loadModels();
  }, [loadModels]);

  return { models, loading, error, reload: loadModels };
}

// ============================================================================
// HOOK: usePpPricing — HUD/Fannie/VA pricing matrices
// ============================================================================

export function usePpPricing(stateCode?: string) {
  const [pricing, setPricing] = useState<PpPricingMatrix[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadPricing = useCallback(async () => {
    if (!stateCode) {
      setPricing([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('pp_pricing_matrices')
        .select()
        .eq('state_code', stateCode)
        .is('deleted_at', null)
        .order('work_order_type');
      if (err) throw err;
      setPricing(mapRows<PpPricingMatrix>(data ?? []));
    } catch (e) {
      console.error('Failed to load PP pricing:', e);
      setError('Could not load pricing data.');
    } finally {
      setLoading(false);
    }
  }, [stateCode]);

  useEffect(() => {
    loadPricing();
  }, [loadPricing]);

  return { pricing, loading, error, reload: loadPricing };
}

// ============================================================================
// HOOK: usePpStrippedEstimates — stripped property estimates
// ============================================================================

export function usePpStrippedEstimates(propertyId?: string) {
  const [estimates, setEstimates] = useState<PpStrippedEstimate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadEstimates = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let q = supabase
        .from('pp_stripped_estimates')
        .select()
        .is('deleted_at', null);

      if (propertyId) q = q.eq('property_id', propertyId);

      const { data, error: err } = await q.order('created_at', { ascending: false });
      if (err) throw err;
      setEstimates(mapRows<PpStrippedEstimate>(data ?? []));
    } catch (e) {
      console.error('Failed to load stripped estimates:', e);
      setError('Could not load stripped estimates.');
    } finally {
      setLoading(false);
    }
  }, [propertyId]);

  useEffect(() => {
    loadEstimates();
  }, [loadEstimates]);

  const createEstimate = useCallback(
    async (est: Omit<PpStrippedEstimate, 'id' | 'createdAt' | 'updatedAt'>) => {
      const supabase = getSupabase();
      const { error: err } = await supabase.from('pp_stripped_estimates').insert({
        company_id: est.companyId,
        work_order_id: est.workOrderId,
        property_id: est.propertyId,
        estimate_type: est.estimateType,
        input_data: est.inputData,
        materials_list: est.materialsList,
        material_cost: est.materialCost,
        labor_hours: est.laborHours,
        labor_cost: est.laborCost,
        total_estimate: est.totalEstimate,
        hud_allowable: est.hudAllowable,
        notes: est.notes,
      });
      if (err) throw err;
      await loadEstimates();
    },
    [loadEstimates]
  );

  return { estimates, loading, error, reload: loadEstimates, createEstimate };
}
