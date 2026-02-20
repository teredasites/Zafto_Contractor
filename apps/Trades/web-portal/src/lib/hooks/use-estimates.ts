'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──

export type EstimateType = 'regular' | 'insurance';
export type EstimateStatus = 'draft' | 'sent' | 'approved' | 'declined' | 'revised' | 'completed';

export interface Estimate {
  id: string;
  companyId: string;
  jobId: string | null;
  customerId: string | null;
  customerName: string;
  customerEmail: string;
  customerPhone: string;
  propertyAddress: string;
  propertyCity: string;
  propertyState: string;
  propertyZip: string;
  estimateNumber: string;
  title: string;
  estimateType: EstimateType;
  status: EstimateStatus;
  notes: string;
  internalNotes: string;
  subtotal: number;
  overheadPercent: number;
  overheadAmount: number;
  profitPercent: number;
  profitAmount: number;
  taxPercent: number;
  taxAmount: number;
  grandTotal: number;
  // Insurance
  claimNumber: string;
  policyNumber: string;
  carrierName: string;
  adjusterName: string;
  adjusterEmail: string;
  adjusterPhone: string;
  deductible: number;
  dateOfLoss: string | null;
  rcvTotal: number;
  depreciationTotal: number;
  acvTotal: number;
  netClaim: number;
  // Dates
  validUntil: string | null;
  sentAt: string | null;
  approvedAt: string | null;
  declinedAt: string | null;
  completedAt: string | null;
  templateId: string | null;
  propertyScanId: string | null;
  propertyFloorPlanId: string | null;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
}

export interface EstimateArea {
  id: string;
  estimateId: string;
  name: string;
  description: string;
  floorNumber: number;
  lengthFt: number;
  widthFt: number;
  heightFt: number;
  perimeterLf: number;
  floorSf: number;
  wallSf: number;
  ceilingSf: number;
  windowCount: number;
  doorCount: number;
  sortOrder: number;
}

export interface EstimateLineItem {
  id: string;
  estimateId: string;
  areaId: string | null;
  itemId: string | null;
  zaftoCode: string;
  description: string;
  actionType: string;
  quantity: number;
  unitCode: string;
  materialCost: number;
  laborCost: number;
  equipmentCost: number;
  unitPrice: number;
  lineTotal: number;
  sortOrder: number;
  notes: string;
}

export interface EstimateItem {
  id: string;
  companyId: string | null;
  zaftoCode: string;
  trade: string;
  categoryId: string | null;
  name: string;
  description: string;
  defaultUnit: string;
  materialCost: number;
  laborCost: number;
  equipmentCost: number;
  basePrice: number;
  isCommon: boolean;
  tags: string[];
  source: string;
  categoryCode?: string;
  categoryName?: string;
}

// ── Mappers ──

function mapEstimate(row: Record<string, unknown>): Estimate {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    jobId: row.job_id as string | null,
    customerId: row.customer_id as string | null,
    customerName: (row.customer_name as string) || '',
    customerEmail: (row.customer_email as string) || '',
    customerPhone: (row.customer_phone as string) || '',
    propertyAddress: (row.property_address as string) || '',
    propertyCity: (row.property_city as string) || '',
    propertyState: (row.property_state as string) || '',
    propertyZip: (row.property_zip as string) || '',
    estimateNumber: (row.estimate_number as string) || '',
    title: (row.title as string) || '',
    estimateType: (row.estimate_type as EstimateType) || 'regular',
    status: (row.status as EstimateStatus) || 'draft',
    notes: (row.notes as string) || '',
    internalNotes: (row.internal_notes as string) || '',
    subtotal: Number(row.subtotal || 0),
    overheadPercent: Number(row.overhead_percent || 0),
    overheadAmount: Number(row.overhead_amount || 0),
    profitPercent: Number(row.profit_percent || 0),
    profitAmount: Number(row.profit_amount || 0),
    taxPercent: Number(row.tax_percent || 0),
    taxAmount: Number(row.tax_amount || 0),
    grandTotal: Number(row.grand_total || 0),
    claimNumber: (row.claim_number as string) || '',
    policyNumber: (row.policy_number as string) || '',
    carrierName: (row.carrier_name as string) || '',
    adjusterName: (row.adjuster_name as string) || '',
    adjusterEmail: (row.adjuster_email as string) || '',
    adjusterPhone: (row.adjuster_phone as string) || '',
    deductible: Number(row.deductible || 0),
    dateOfLoss: row.date_of_loss as string | null,
    rcvTotal: Number(row.rcv_total || 0),
    depreciationTotal: Number(row.depreciation_total || 0),
    acvTotal: Number(row.acv_total || 0),
    netClaim: Number(row.net_claim || 0),
    validUntil: row.valid_until as string | null,
    sentAt: row.sent_at as string | null,
    approvedAt: row.approved_at as string | null,
    declinedAt: row.declined_at as string | null,
    completedAt: row.completed_at as string | null,
    templateId: row.template_id as string | null,
    propertyScanId: row.property_scan_id as string | null,
    propertyFloorPlanId: row.property_floor_plan_id as string | null,
    createdBy: (row.created_by as string) || '',
    createdAt: (row.created_at as string) || '',
    updatedAt: (row.updated_at as string) || '',
  };
}

function mapArea(row: Record<string, unknown>): EstimateArea {
  return {
    id: row.id as string,
    estimateId: row.estimate_id as string,
    name: (row.name as string) || '',
    description: (row.description as string) || '',
    floorNumber: Number(row.floor_number || 1),
    lengthFt: Number(row.length_ft || 0),
    widthFt: Number(row.width_ft || 0),
    heightFt: Number(row.height_ft || 8),
    perimeterLf: Number(row.perimeter_ft || 0),
    floorSf: Number(row.area_sf || 0),
    wallSf: Number(row.wall_sf || 0),
    ceilingSf: Number(row.ceiling_sf || 0),
    windowCount: Number(row.window_count || 0),
    doorCount: Number(row.door_count || 0),
    sortOrder: Number(row.sort_order || 0),
  };
}

function mapLineItem(row: Record<string, unknown>): EstimateLineItem {
  return {
    id: row.id as string,
    estimateId: row.estimate_id as string,
    areaId: row.area_id as string | null,
    itemId: row.item_id as string | null,
    zaftoCode: (row.zafto_code as string) || '',
    description: (row.description as string) || '',
    actionType: (row.action_type as string) || 'replace',
    quantity: Number(row.quantity || 1),
    unitCode: (row.unit_code as string) || 'EA',
    materialCost: Number(row.material_cost || 0),
    laborCost: Number(row.labor_cost || 0),
    equipmentCost: Number(row.equipment_cost || 0),
    unitPrice: Number(row.unit_price || 0),
    lineTotal: Number(row.line_total || 0),
    sortOrder: Number(row.sort_order || 0),
    notes: (row.notes as string) || '',
  };
}

function mapItem(row: Record<string, unknown>): EstimateItem {
  const cat = row.estimate_categories as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string | null,
    zaftoCode: (row.zafto_code as string) || '',
    trade: (row.trade as string) || '',
    categoryId: row.category_id as string | null,
    name: (row.name as string) || '',
    description: (row.description as string) || '',
    defaultUnit: (row.default_unit as string) || 'EA',
    materialCost: Number(row.material_cost || 0),
    laborCost: Number(row.labor_cost || 0),
    equipmentCost: Number(row.equipment_cost || 0),
    basePrice: Number(row.base_price || 0),
    isCommon: (row.is_common as boolean) || false,
    tags: (row.tags as string[]) || [],
    source: (row.source as string) || 'zafto',
    categoryCode: cat?.code as string | undefined,
    categoryName: cat?.name as string | undefined,
  };
}

// ── Hook: Estimates List ──

export function useEstimates() {
  const [estimates, setEstimates] = useState<Estimate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchEstimates = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { data: profile } = await supabase
        .from('users')
        .select('company_id')
        .eq('id', user.id)
        .single();

      if (!profile?.company_id) throw new Error('No company');

      const { data, error: err } = await supabase
        .from('estimates')
        .select('*')
        .eq('company_id', profile.company_id)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setEstimates((data || []).map(mapEstimate));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load estimates');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchEstimates();
  }, [fetchEstimates]);

  // Real-time
  useEffect(() => {
    const supabase = getSupabase();
    const channel = supabase
      .channel('estimates-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'estimates' }, () => {
        fetchEstimates();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchEstimates]);

  const createEstimate = useCallback(async (data: {
    title: string;
    estimateType: EstimateType;
    customerName?: string;
    customerEmail?: string;
    customerPhone?: string;
    propertyAddress?: string;
    propertyCity?: string;
    propertyState?: string;
    propertyZip?: string;
    jobId?: string;
    customerId?: string;
    overheadPercent?: number;
    profitPercent?: number;
    taxPercent?: number;
    claimNumber?: string;
    policyNumber?: string;
    carrierName?: string;
    adjusterName?: string;
    deductible?: number;
    dateOfLoss?: string;
    propertyFloorPlanId?: string;
  }): Promise<string | null> => {
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;

      const { data: profile } = await supabase
        .from('users')
        .select('company_id')
        .eq('id', user.id)
        .single();

      if (!profile?.company_id) return null;

      // Auto-number: EST-YYYYMMDD-NNN
      const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
      const { data: lastEst } = await supabase
        .from('estimates')
        .select('estimate_number')
        .eq('company_id', profile.company_id)
        .like('estimate_number', `EST-${today}-%`)
        .order('estimate_number', { ascending: false })
        .limit(1)
        .single();

      let seq = 1;
      if (lastEst?.estimate_number) {
        const parts = (lastEst.estimate_number as string).split('-');
        seq = (parseInt(parts[2] || '0', 10) || 0) + 1;
      }
      const estimateNumber = `EST-${today}-${String(seq).padStart(3, '0')}`;

      const { data: result, error: err } = await supabase
        .from('estimates')
        .insert({
          company_id: profile.company_id,
          created_by: user.id,
          estimate_number: estimateNumber,
          title: data.title,
          estimate_type: data.estimateType,
          status: 'draft',
          customer_name: data.customerName || '',
          customer_email: data.customerEmail || '',
          customer_phone: data.customerPhone || '',
          property_address: data.propertyAddress || '',
          property_city: data.propertyCity || '',
          property_state: data.propertyState || '',
          property_zip: data.propertyZip || '',
          job_id: data.jobId || null,
          customer_id: data.customerId || null,
          overhead_percent: data.overheadPercent ?? 10,
          profit_percent: data.profitPercent ?? 10,
          tax_percent: data.taxPercent ?? 0,
          claim_number: data.claimNumber || '',
          policy_number: data.policyNumber || '',
          carrier_name: data.carrierName || '',
          adjuster_name: data.adjusterName || '',
          deductible: data.deductible || 0,
          date_of_loss: data.dateOfLoss || null,
          property_floor_plan_id: data.propertyFloorPlanId || null,
        })
        .select('id')
        .single();

      if (err) throw err;
      return result?.id || null;
    } catch (e: unknown) {
      console.error('Create estimate failed:', e);
      return null;
    }
  }, []);

  const deleteEstimate = useCallback(async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('estimates')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) console.error('Delete estimate failed:', err);
    else fetchEstimates();
  }, [fetchEstimates]);

  // Create estimate from walkthrough — reads rooms, creates estimate + areas
  const createEstimateFromWalkthrough = useCallback(async (walkthroughId: string): Promise<string | null> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;
    const companyId = user.app_metadata?.company_id;
    if (!companyId) return null;

    // Fetch walkthrough
    const { data: wt, error: wtErr } = await supabase
      .from('walkthroughs')
      .select('*')
      .eq('id', walkthroughId)
      .single();
    if (wtErr || !wt) throw new Error('Walkthrough not found');

    // Fetch walkthrough rooms
    const { data: rooms } = await supabase
      .from('walkthrough_rooms')
      .select('*')
      .eq('walkthrough_id', walkthroughId)
      .order('sort_order', { ascending: true });

    // Create estimate
    const { data: est, error: estErr } = await supabase
      .from('estimates')
      .insert({
        company_id: companyId,
        title: (wt.name as string) || 'From Walkthrough',
        estimate_type: 'regular',
        customer_id: wt.customer_id || null,
        job_id: wt.job_id || null,
        property_address: wt.address || null,
        property_city: wt.city || null,
        property_state: wt.state || null,
        property_zip: wt.zip_code || null,
        status: 'draft',
        created_by: user.id,
      })
      .select('id')
      .single();
    if (estErr || !est) throw new Error('Failed to create estimate');

    // Create estimate areas from rooms
    if (rooms && rooms.length > 0) {
      const areaInserts = rooms.map((room: Record<string, unknown>, idx: number) => {
        const dims = room.dimensions as Record<string, number> | null;
        const length = dims?.length || 0;
        const width = dims?.width || 0;
        const height = dims?.height || 8;
        return {
          estimate_id: est.id,
          company_id: companyId,
          name: (room.name as string) || `Room ${idx + 1}`,
          description: (room.notes as string) || null,
          length_ft: length,
          width_ft: width,
          height_ft: height,
          perimeter_lf: 2 * (length + width),
          floor_sf: length * width,
          wall_sf: 2 * (length + width) * height,
          ceiling_sf: length * width,
          sort_order: idx,
        };
      });
      await supabase.from('estimate_areas').insert(areaInserts);
    }

    fetchEstimates();
    return est.id;
  }, [fetchEstimates]);

  // U22: Send estimate email via SendGrid
  const sendEstimate = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('estimates')
      .update({ status: 'sent', sent_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;

    try {
      await supabase.functions.invoke('sendgrid-email', {
        body: { action: 'send_estimate', entityId: id },
      });
    } catch {
      // Best-effort
    }
  };

  return { estimates, loading, error, fetchEstimates, createEstimate, createEstimateFromWalkthrough, sendEstimate, deleteEstimate };
}

// ── Hook: Single Estimate with Areas + Line Items ──

export function useEstimate(estimateId: string | null) {
  const [estimate, setEstimate] = useState<Estimate | null>(null);
  const [areas, setAreas] = useState<EstimateArea[]>([]);
  const [lineItems, setLineItems] = useState<EstimateLineItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAll = useCallback(async () => {
    if (!estimateId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const [estRes, areasRes, linesRes] = await Promise.all([
        supabase.from('estimates').select('*').eq('id', estimateId).single(),
        supabase.from('estimate_areas').select('*').eq('estimate_id', estimateId).order('sort_order'),
        supabase.from('estimate_line_items').select('*').eq('estimate_id', estimateId).order('sort_order'),
      ]);

      if (estRes.error) throw estRes.error;
      setEstimate(mapEstimate(estRes.data));
      setAreas((areasRes.data || []).map(mapArea));
      setLineItems((linesRes.data || []).map(mapLineItem));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load estimate');
    } finally {
      setLoading(false);
    }
  }, [estimateId]);

  useEffect(() => {
    fetchAll();
  }, [fetchAll]);

  // ── Estimate Updates ──

  const updateEstimate = useCallback(async (updates: Record<string, unknown>) => {
    if (!estimateId) return;
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('estimates')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', estimateId);
    if (err) console.error('Update estimate failed:', err);
    else fetchAll();
  }, [estimateId, fetchAll]);

  // ── Area CRUD ──

  const addArea = useCallback(async (name: string, description?: string) => {
    if (!estimateId) return;
    const supabase = getSupabase();
    const nextSort = areas.length;
    const { error: err } = await supabase
      .from('estimate_areas')
      .insert({
        estimate_id: estimateId,
        name,
        description: description || '',
        sort_order: nextSort,
      });
    if (err) console.error('Add area failed:', err);
    else fetchAll();
  }, [estimateId, areas.length, fetchAll]);

  const updateArea = useCallback(async (areaId: string, updates: Record<string, unknown>) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('estimate_areas')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', areaId);
    if (err) console.error('Update area failed:', err);
    else fetchAll();
  }, [fetchAll]);

  const deleteArea = useCallback(async (areaId: string) => {
    const supabase = getSupabase();
    await supabase.from('estimate_line_items').update({ deleted_at: new Date().toISOString() }).eq('area_id', areaId);
    const { error: err } = await supabase.from('estimate_areas').update({ deleted_at: new Date().toISOString() }).eq('id', areaId);
    if (err) console.error('Delete area failed:', err);
    else fetchAll();
  }, [fetchAll]);

  // ── Line Item CRUD ──

  const addLineItem = useCallback(async (data: {
    areaId?: string;
    itemId?: string;
    zaftoCode?: string;
    description: string;
    actionType?: string;
    quantity: number;
    unitCode: string;
    materialCost?: number;
    laborCost?: number;
    equipmentCost?: number;
    unitPrice: number;
    notes?: string;
  }) => {
    if (!estimateId) return;
    const supabase = getSupabase();
    const nextSort = lineItems.filter(li => li.areaId === (data.areaId || null)).length;
    const lineTotal = data.quantity * data.unitPrice;
    const { error: err } = await supabase
      .from('estimate_line_items')
      .insert({
        estimate_id: estimateId,
        area_id: data.areaId || null,
        item_id: data.itemId || null,
        zafto_code: data.zaftoCode || '',
        description: data.description,
        action_type: data.actionType || 'replace',
        quantity: data.quantity,
        unit_code: data.unitCode,
        material_cost: data.materialCost || 0,
        labor_cost: data.laborCost || 0,
        equipment_cost: data.equipmentCost || 0,
        unit_price: data.unitPrice,
        line_total: lineTotal,
        sort_order: nextSort,
        notes: data.notes || '',
      });
    if (err) console.error('Add line item failed:', err);
    else fetchAll();
  }, [estimateId, lineItems, fetchAll]);

  const updateLineItem = useCallback(async (lineId: string, updates: Record<string, unknown>) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('estimate_line_items')
      .update(updates)
      .eq('id', lineId);
    if (err) console.error('Update line item failed:', err);
    else fetchAll();
  }, [fetchAll]);

  const deleteLineItem = useCallback(async (lineId: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('estimate_line_items')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', lineId);
    if (err) console.error('Delete line item failed:', err);
    else fetchAll();
  }, [fetchAll]);

  // ── Recalculate Totals ──

  const recalculateTotals = useCallback(async () => {
    if (!estimateId || !estimate) return;
    const subtotal = lineItems.reduce((sum, li) => sum + li.lineTotal, 0);
    const overheadAmount = subtotal * (estimate.overheadPercent / 100);
    const profitAmount = subtotal * (estimate.profitPercent / 100);
    const taxableAmount = subtotal + overheadAmount + profitAmount;
    const taxAmount = taxableAmount * (estimate.taxPercent / 100);
    const grandTotal = taxableAmount + taxAmount;

    await updateEstimate({
      subtotal,
      overhead_amount: overheadAmount,
      profit_amount: profitAmount,
      tax_amount: taxAmount,
      grand_total: grandTotal,
    });
  }, [estimateId, estimate, lineItems, updateEstimate]);

  // ── Import from Recon ──
  // Reads trade_bid_data for a given scan_id + trade, creates line items from material list

  const importFromRecon = useCallback(async (scanId: string, trade: string) => {
    if (!estimateId) return 0;
    const supabase = getSupabase();

    // Fetch trade bid data
    const { data: bidData, error: bidErr } = await supabase
      .from('trade_bid_data')
      .select('*')
      .eq('scan_id', scanId)
      .eq('trade', trade)
      .limit(1)
      .maybeSingle();

    if (bidErr || !bidData) {
      console.error('No trade bid data found for', trade);
      return 0;
    }

    const materialList = (bidData.material_list as Array<{
      item: string;
      quantity: number;
      unit: string;
      waste_pct: number;
      total_with_waste: number;
    }>) || [];

    if (materialList.length === 0) return 0;

    // Link scan to estimate
    await supabase
      .from('estimates')
      .update({ property_scan_id: scanId })
      .eq('id', estimateId);

    // Build line items from material list
    const currentCount = lineItems.length;
    const unitMap: Record<string, string> = {
      SQ: 'EA', bundles: 'EA', rolls: 'EA', pcs: 'EA', panels: 'EA',
      set: 'EA', unit: 'EA', systems: 'EA', LF: 'LF', ft: 'LF',
      sqft: 'SF', 'sq ft': 'SF', 'cubic yards': 'EA', 'bags (50lb)': 'EA',
      gallons: 'EA', quarts: 'EA', tubes: 'EA', lbs: 'EA', sheets: 'EA',
    };

    const rows = materialList.map((mat, i) => ({
      estimate_id: estimateId,
      area_id: null,
      item_id: null,
      zafto_code: '',
      description: `${mat.item} (Recon: ${trade})`,
      action_type: 'replace',
      quantity: mat.total_with_waste,
      unit_code: unitMap[mat.unit] || 'EA',
      material_cost: 0,
      labor_cost: 0,
      equipment_cost: 0,
      unit_price: 0,
      line_total: 0,
      sort_order: currentCount + i,
      notes: `Auto-imported from Recon scan. Original qty: ${mat.quantity} ${mat.unit}, waste: ${mat.waste_pct}%`,
    }));

    const { error: insertErr } = await supabase
      .from('estimate_line_items')
      .insert(rows);

    if (insertErr) {
      console.error('Import from Recon failed:', insertErr);
      return 0;
    }

    await fetchAll();
    return materialList.length;
  }, [estimateId, lineItems, fetchAll]);

  return {
    estimate, areas, lineItems, loading, error,
    fetchAll, updateEstimate,
    addArea, updateArea, deleteArea,
    addLineItem, updateLineItem, deleteLineItem,
    recalculateTotals, importFromRecon,
  };
}

// ── Hook: Estimate Items (Code Database Search) ──

export function useEstimateItems() {
  const [items, setItems] = useState<EstimateItem[]>([]);
  const [loading, setLoading] = useState(false);

  const searchItems = useCallback(async (query: string, trade?: string, commonOnly?: boolean) => {
    setLoading(true);
    try {
      const supabase = getSupabase();
      let dbQuery = supabase
        .from('estimate_items')
        .select('*, estimate_categories(code, name)')
        .is('deleted_at', null);

      if (query) {
        dbQuery = dbQuery.or(
          `name.ilike.%${query}%,zafto_code.ilike.%${query}%,description.ilike.%${query}%`
        );
      }
      if (trade) {
        dbQuery = dbQuery.eq('trade', trade);
      }
      if (commonOnly) {
        dbQuery = dbQuery.eq('is_common', true);
      }

      const { data, error } = await dbQuery
        .order('trade')
        .order('zafto_code')
        .limit(100);

      if (error) throw error;
      setItems((data || []).map(mapItem));
    } catch (e: unknown) {
      console.error('Item search failed:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  return { items, loading, searchItems };
}

// ── Utility: Format currency ──

export const fmtCurrency = (n: number) =>
  n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
