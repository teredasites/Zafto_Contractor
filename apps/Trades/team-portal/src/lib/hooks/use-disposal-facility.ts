'use client';

// DEPTH36: Disposal & Dump Finder Hook (Team Portal)
// Field techs: find nearest facility, log dump receipts, view scrap prices.
// Read-only for facilities + waste types + scrap prices.
// Write for dump receipts (capture receipts in the field).

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type FacilityType =
  | 'landfill'
  | 'transfer_station'
  | 'recycling_center'
  | 'scrap_yard'
  | 'hazmat_facility'
  | 'composting_facility'
  | 'concrete_recycler'
  | 'e_waste_facility'
  | 'tire_recycler'
  | 'asbestos_disposal'
  | 'biohazard_facility'
  | 'metal_recycler'
  | 'other';

export type PaymentMethod =
  | 'cash'
  | 'check'
  | 'credit_card'
  | 'company_account'
  | 'prepaid'
  | 'other';

export interface DisposalFacilitySummary {
  id: string;
  name: string;
  address: string | null;
  city: string | null;
  stateCode: string | null;
  zipCode: string | null;
  latitude: number | null;
  longitude: number | null;
  phone: string | null;
  facilityType: FacilityType;
  acceptedWasteTypes: unknown[];
  pricingJson: unknown[];
  weightLimitTons: number | null;
  permitRequired: boolean;
  specialInstructions: string | null;
  hoursJson: Record<string, unknown>;
}

export interface DumpReceipt {
  id: string;
  companyId: string;
  facilityId: string | null;
  jobId: string | null;
  workOrderId: string | null;
  capturedBy: string | null;
  receiptDate: string;
  facilityName: string | null;
  wasteType: string | null;
  weightTons: number | null;
  volumeYards: number | null;
  cost: number | null;
  tax: number | null;
  totalCost: number | null;
  paymentMethod: PaymentMethod | null;
  receiptPhotoUrl: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ScrapPriceIndex {
  id: string;
  material: string;
  grade: string | null;
  pricePerLb: number | null;
  pricePerTon: number | null;
  unit: string;
  region: string;
  effectiveDate: string;
}

export interface WasteTypeReference {
  id: string;
  code: string;
  label: string;
  category: string;
  trades: unknown[];
  disposalNotes: string | null;
  requiresPermit: boolean;
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapFacility(r: Record<string, unknown>): DisposalFacilitySummary {
  return {
    id: r.id as string,
    name: r.name as string,
    address: r.address as string | null,
    city: r.city as string | null,
    stateCode: r.state_code as string | null,
    zipCode: r.zip_code as string | null,
    latitude: r.latitude != null ? Number(r.latitude) : null,
    longitude: r.longitude != null ? Number(r.longitude) : null,
    phone: r.phone as string | null,
    facilityType: r.facility_type as FacilityType,
    acceptedWasteTypes: Array.isArray(r.accepted_waste_types) ? r.accepted_waste_types : [],
    pricingJson: Array.isArray(r.pricing_json) ? r.pricing_json : [],
    weightLimitTons: r.weight_limit_tons != null ? Number(r.weight_limit_tons) : null,
    permitRequired: (r.permit_required as boolean) ?? false,
    specialInstructions: r.special_instructions as string | null,
    hoursJson: (r.hours_json as Record<string, unknown>) ?? {},
  };
}

function mapReceipt(r: Record<string, unknown>): DumpReceipt {
  return {
    id: r.id as string,
    companyId: r.company_id as string,
    facilityId: r.facility_id as string | null,
    jobId: r.job_id as string | null,
    workOrderId: r.work_order_id as string | null,
    capturedBy: r.captured_by as string | null,
    receiptDate: r.receipt_date as string,
    facilityName: r.facility_name as string | null,
    wasteType: r.waste_type as string | null,
    weightTons: r.weight_tons != null ? Number(r.weight_tons) : null,
    volumeYards: r.volume_yards != null ? Number(r.volume_yards) : null,
    cost: r.cost != null ? Number(r.cost) : null,
    tax: r.tax != null ? Number(r.tax) : null,
    totalCost: r.total_cost != null ? Number(r.total_cost) : null,
    paymentMethod: r.payment_method as PaymentMethod | null,
    receiptPhotoUrl: r.receipt_photo_url as string | null,
    notes: r.notes as string | null,
    createdAt: r.created_at as string,
    updatedAt: r.updated_at as string,
  };
}

function mapScrapPrice(r: Record<string, unknown>): ScrapPriceIndex {
  return {
    id: r.id as string,
    material: r.material as string,
    grade: r.grade as string | null,
    pricePerLb: r.price_per_lb != null ? Number(r.price_per_lb) : null,
    pricePerTon: r.price_per_ton != null ? Number(r.price_per_ton) : null,
    unit: (r.unit as string) ?? 'lb',
    region: (r.region as string) ?? 'national',
    effectiveDate: r.effective_date as string,
  };
}

function mapWasteType(r: Record<string, unknown>): WasteTypeReference {
  return {
    id: r.id as string,
    code: r.code as string,
    label: r.label as string,
    category: r.category as string,
    trades: Array.isArray(r.trades) ? r.trades : [],
    disposalNotes: r.disposal_notes as string | null,
    requiresPermit: (r.requires_permit as boolean) ?? false,
  };
}

// ============================================================================
// FACILITIES HOOK (read-only for field techs)
// ============================================================================

export function useDisposalFacilities(opts?: {
  facilityType?: FacilityType;
  stateCode?: string;
}) {
  const [facilities, setFacilities] = useState<DisposalFacilitySummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      let query = supabase
        .from('disposal_facilities')
        .select('*')
        .is('deleted_at', null)
        .eq('is_active', true)
        .order('name');

      if (opts?.facilityType) query = query.eq('facility_type', opts.facilityType);
      if (opts?.stateCode) query = query.eq('state_code', opts.stateCode);

      const { data, error: err } = await query;
      if (err) throw err;
      setFacilities((data ?? []).map(mapFacility));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load facilities');
    } finally {
      setLoading(false);
    }
  }, [opts?.facilityType, opts?.stateCode]);

  useEffect(() => { fetch(); }, [fetch]);

  const searchFacilities = useCallback(async (q: string) => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('disposal_facilities')
      .select('*')
      .is('deleted_at', null)
      .eq('is_active', true)
      .or(`name.ilike.%${q}%,city.ilike.%${q}%,address.ilike.%${q}%`)
      .order('name');
    if (err) throw err;
    return (data ?? []).map(mapFacility);
  }, []);

  return { facilities, loading, error, refetch: fetch, searchFacilities };
}

// ============================================================================
// DUMP RECEIPTS HOOK (field techs can create + view)
// ============================================================================

export function useDumpReceipts(companyId: string, jobId?: string) {
  const [receipts, setReceipts] = useState<DumpReceipt[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!companyId) return;
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      let query = supabase
        .from('dump_receipts')
        .select('*')
        .eq('company_id', companyId)
        .is('deleted_at', null)
        .order('receipt_date', { ascending: false });

      if (jobId) query = query.eq('job_id', jobId);

      const { data, error: err } = await query;
      if (err) throw err;
      setReceipts((data ?? []).map(mapReceipt));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load receipts');
    } finally {
      setLoading(false);
    }
  }, [companyId, jobId]);

  useEffect(() => { fetch(); }, [fetch]);

  const createReceipt = useCallback(async (payload: Partial<DumpReceipt>) => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('dump_receipts')
      .insert({
        company_id: payload.companyId ?? companyId,
        facility_id: payload.facilityId,
        job_id: payload.jobId,
        work_order_id: payload.workOrderId,
        captured_by: payload.capturedBy,
        receipt_date: payload.receiptDate ?? new Date().toISOString().split('T')[0],
        facility_name: payload.facilityName,
        waste_type: payload.wasteType,
        weight_tons: payload.weightTons,
        volume_yards: payload.volumeYards,
        cost: payload.cost,
        tax: payload.tax,
        total_cost: payload.totalCost,
        payment_method: payload.paymentMethod,
        receipt_photo_url: payload.receiptPhotoUrl,
        notes: payload.notes,
      })
      .select()
      .single();
    if (err) throw err;
    const mapped = mapReceipt(data);
    setReceipts((prev) => [mapped, ...prev]);
    return mapped;
  }, [companyId]);

  return { receipts, loading, error, refetch: fetch, createReceipt };
}

// ============================================================================
// SCRAP PRICES HOOK (read-only reference)
// ============================================================================

export function useScrapPrices() {
  const [prices, setPrices] = useState<ScrapPriceIndex[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('scrap_price_index')
        .select('*')
        .order('material')
        .order('effective_date', { ascending: false });
      if (err) throw err;

      // Deduplicate: keep most recent per material+grade
      const seen = new Set<string>();
      const unique: ScrapPriceIndex[] = [];
      for (const row of data ?? []) {
        const mapped = mapScrapPrice(row);
        const key = `${mapped.material}|${mapped.grade ?? ''}`;
        if (!seen.has(key)) {
          seen.add(key);
          unique.push(mapped);
        }
      }
      setPrices(unique);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load scrap prices');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetch(); }, [fetch]);

  return { prices, loading, error, refetch: fetch };
}

// ============================================================================
// WASTE TYPES HOOK (read-only reference)
// ============================================================================

export function useWasteTypes(category?: string) {
  const [wasteTypes, setWasteTypes] = useState<WasteTypeReference[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      let query = supabase
        .from('waste_type_reference')
        .select('*')
        .order('category')
        .order('label');

      if (category) query = query.eq('category', category);

      const { data, error: err } = await query;
      if (err) throw err;
      setWasteTypes((data ?? []).map(mapWasteType));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load waste types');
    } finally {
      setLoading(false);
    }
  }, [category]);

  useEffect(() => { fetch(); }, [fetch]);

  return { wasteTypes, loading, error, refetch: fetch };
}
