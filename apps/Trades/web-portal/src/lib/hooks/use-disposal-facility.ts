'use client';

// DEPTH36: Disposal & Dump Finder CRM Hook (Web Portal)
// Facilities, dump receipts, scrap prices, waste type reference.

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

export type DataSource =
  | 'epa_frs'
  | 'state_agency'
  | 'county_directory'
  | 'contractor_submitted'
  | 'google_places'
  | 'manual';

export type PaymentMethod =
  | 'cash'
  | 'check'
  | 'credit_card'
  | 'company_account'
  | 'prepaid'
  | 'other';

export interface DisposalFacility {
  id: string;
  companyId: string | null;
  name: string;
  address: string | null;
  city: string | null;
  stateCode: string | null;
  zipCode: string | null;
  latitude: number | null;
  longitude: number | null;
  phone: string | null;
  website: string | null;
  hoursJson: Record<string, unknown>;
  facilityType: FacilityType;
  acceptedWasteTypes: unknown[];
  pricingJson: unknown[];
  weightLimitTons: number | null;
  permitRequired: boolean;
  permitDetails: string | null;
  specialInstructions: string | null;
  dataSource: DataSource | null;
  externalId: string | null;
  verified: boolean;
  verifiedAt: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
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
  source: string | null;
  effectiveDate: string;
  createdAt: string;
}

export interface WasteTypeReference {
  id: string;
  code: string;
  label: string;
  category: string;
  trades: unknown[];
  disposalNotes: string | null;
  requiresPermit: boolean;
  createdAt: string;
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapFacility(r: Record<string, unknown>): DisposalFacility {
  return {
    id: r.id as string,
    companyId: r.company_id as string | null,
    name: r.name as string,
    address: r.address as string | null,
    city: r.city as string | null,
    stateCode: r.state_code as string | null,
    zipCode: r.zip_code as string | null,
    latitude: r.latitude != null ? Number(r.latitude) : null,
    longitude: r.longitude != null ? Number(r.longitude) : null,
    phone: r.phone as string | null,
    website: r.website as string | null,
    hoursJson: (r.hours_json as Record<string, unknown>) ?? {},
    facilityType: r.facility_type as FacilityType,
    acceptedWasteTypes: Array.isArray(r.accepted_waste_types) ? r.accepted_waste_types : [],
    pricingJson: Array.isArray(r.pricing_json) ? r.pricing_json : [],
    weightLimitTons: r.weight_limit_tons != null ? Number(r.weight_limit_tons) : null,
    permitRequired: (r.permit_required as boolean) ?? false,
    permitDetails: r.permit_details as string | null,
    specialInstructions: r.special_instructions as string | null,
    dataSource: r.data_source as DataSource | null,
    externalId: r.external_id as string | null,
    verified: (r.verified as boolean) ?? false,
    verifiedAt: r.verified_at as string | null,
    isActive: (r.is_active as boolean) ?? true,
    createdAt: r.created_at as string,
    updatedAt: r.updated_at as string,
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
    source: r.source as string | null,
    effectiveDate: r.effective_date as string,
    createdAt: r.created_at as string,
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
    createdAt: r.created_at as string,
  };
}

// ============================================================================
// FACILITIES HOOK
// ============================================================================

export function useDisposalFacilities(opts?: {
  facilityType?: FacilityType;
  stateCode?: string;
}) {
  const [facilities, setFacilities] = useState<DisposalFacility[]>([]);
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

  const createFacility = useCallback(async (payload: Partial<DisposalFacility>) => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('disposal_facilities')
      .insert({
        company_id: payload.companyId,
        name: payload.name,
        address: payload.address,
        city: payload.city,
        state_code: payload.stateCode,
        zip_code: payload.zipCode,
        latitude: payload.latitude,
        longitude: payload.longitude,
        phone: payload.phone,
        website: payload.website,
        hours_json: payload.hoursJson ?? {},
        facility_type: payload.facilityType,
        accepted_waste_types: payload.acceptedWasteTypes ?? [],
        pricing_json: payload.pricingJson ?? [],
        weight_limit_tons: payload.weightLimitTons,
        permit_required: payload.permitRequired ?? false,
        permit_details: payload.permitDetails,
        special_instructions: payload.specialInstructions,
        data_source: payload.dataSource ?? 'contractor_submitted',
        external_id: payload.externalId,
      })
      .select()
      .single();
    if (err) throw err;
    const mapped = mapFacility(data);
    setFacilities((prev) => [...prev, mapped].sort((a, b) => a.name.localeCompare(b.name)));
    return mapped;
  }, []);

  const updateFacility = useCallback(async (id: string, payload: Partial<DisposalFacility>) => {
    const supabase = getSupabase();
    const updates: Record<string, unknown> = {};
    if (payload.name !== undefined) updates.name = payload.name;
    if (payload.address !== undefined) updates.address = payload.address;
    if (payload.city !== undefined) updates.city = payload.city;
    if (payload.stateCode !== undefined) updates.state_code = payload.stateCode;
    if (payload.zipCode !== undefined) updates.zip_code = payload.zipCode;
    if (payload.latitude !== undefined) updates.latitude = payload.latitude;
    if (payload.longitude !== undefined) updates.longitude = payload.longitude;
    if (payload.phone !== undefined) updates.phone = payload.phone;
    if (payload.website !== undefined) updates.website = payload.website;
    if (payload.hoursJson !== undefined) updates.hours_json = payload.hoursJson;
    if (payload.facilityType !== undefined) updates.facility_type = payload.facilityType;
    if (payload.acceptedWasteTypes !== undefined) updates.accepted_waste_types = payload.acceptedWasteTypes;
    if (payload.pricingJson !== undefined) updates.pricing_json = payload.pricingJson;
    if (payload.weightLimitTons !== undefined) updates.weight_limit_tons = payload.weightLimitTons;
    if (payload.permitRequired !== undefined) updates.permit_required = payload.permitRequired;
    if (payload.permitDetails !== undefined) updates.permit_details = payload.permitDetails;
    if (payload.specialInstructions !== undefined) updates.special_instructions = payload.specialInstructions;
    if (payload.isActive !== undefined) updates.is_active = payload.isActive;

    const { data, error: err } = await supabase
      .from('disposal_facilities')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    if (err) throw err;
    const mapped = mapFacility(data);
    setFacilities((prev) => prev.map((f) => (f.id === id ? mapped : f)));
    return mapped;
  }, []);

  const deleteFacility = useCallback(async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('disposal_facilities')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    setFacilities((prev) => prev.filter((f) => f.id !== id));
  }, []);

  const searchFacilities = useCallback(async (query: string) => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('disposal_facilities')
      .select('*')
      .is('deleted_at', null)
      .eq('is_active', true)
      .or(`name.ilike.%${query}%,city.ilike.%${query}%,address.ilike.%${query}%`)
      .order('name');
    if (err) throw err;
    return (data ?? []).map(mapFacility);
  }, []);

  return { facilities, loading, error, refetch: fetch, createFacility, updateFacility, deleteFacility, searchFacilities };
}

// ============================================================================
// DUMP RECEIPTS HOOK
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

  const updateReceipt = useCallback(async (id: string, payload: Partial<DumpReceipt>) => {
    const supabase = getSupabase();
    const updates: Record<string, unknown> = {};
    if (payload.facilityId !== undefined) updates.facility_id = payload.facilityId;
    if (payload.jobId !== undefined) updates.job_id = payload.jobId;
    if (payload.workOrderId !== undefined) updates.work_order_id = payload.workOrderId;
    if (payload.receiptDate !== undefined) updates.receipt_date = payload.receiptDate;
    if (payload.facilityName !== undefined) updates.facility_name = payload.facilityName;
    if (payload.wasteType !== undefined) updates.waste_type = payload.wasteType;
    if (payload.weightTons !== undefined) updates.weight_tons = payload.weightTons;
    if (payload.volumeYards !== undefined) updates.volume_yards = payload.volumeYards;
    if (payload.cost !== undefined) updates.cost = payload.cost;
    if (payload.tax !== undefined) updates.tax = payload.tax;
    if (payload.totalCost !== undefined) updates.total_cost = payload.totalCost;
    if (payload.paymentMethod !== undefined) updates.payment_method = payload.paymentMethod;
    if (payload.receiptPhotoUrl !== undefined) updates.receipt_photo_url = payload.receiptPhotoUrl;
    if (payload.notes !== undefined) updates.notes = payload.notes;

    const { data, error: err } = await supabase
      .from('dump_receipts')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    if (err) throw err;
    const mapped = mapReceipt(data);
    setReceipts((prev) => prev.map((r) => (r.id === id ? mapped : r)));
    return mapped;
  }, []);

  const deleteReceipt = useCallback(async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('dump_receipts')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    setReceipts((prev) => prev.filter((r) => r.id !== id));
  }, []);

  return { receipts, loading, error, refetch: fetch, createReceipt, updateReceipt, deleteReceipt };
}

// ============================================================================
// SCRAP PRICES HOOK (read-only reference)
// ============================================================================

export function useScrapPrices(material?: string) {
  const [prices, setPrices] = useState<ScrapPriceIndex[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      let query = supabase
        .from('scrap_price_index')
        .select('*')
        .is('deleted_at', null)
        .order('material')
        .order('effective_date', { ascending: false });

      if (material) query = query.eq('material', material);

      const { data, error: err } = await query;
      if (err) throw err;

      if (!material) {
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
      } else {
        setPrices((data ?? []).map(mapScrapPrice));
      }
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load scrap prices');
    } finally {
      setLoading(false);
    }
  }, [material]);

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
