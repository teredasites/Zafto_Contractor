'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import {
  mapEstimate, mapEstimateArea, mapEstimateLineItem,
  type EstimateData, type EstimateAreaData, type EstimateLineItemData,
  type EstimateType,
} from './mappers';

// List all estimates for the company (field techs see their assigned jobs' estimates)
export function useEstimates() {
  const { profile } = useAuth();
  const [estimates, setEstimates] = useState<EstimateData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchEstimates = useCallback(async () => {
    if (!profile?.companyId) { setLoading(false); return; }
    const supabase = getSupabase();

    const { data } = await supabase
      .from('estimates')
      .select('*')
      .eq('company_id', profile.companyId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    setEstimates((data || []).map(mapEstimate));
    setLoading(false);
  }, [profile?.companyId]);

  useEffect(() => {
    fetchEstimates();
    if (!profile?.companyId) return;

    const supabase = getSupabase();
    const channel = supabase.channel('team-estimates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'estimates' }, () => fetchEstimates())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchEstimates, profile?.companyId]);

  return { estimates, loading, refetch: fetchEstimates };
}

// Single estimate with areas + line items
export function useEstimate(estimateId: string | null) {
  const [estimate, setEstimate] = useState<EstimateData | null>(null);
  const [areas, setAreas] = useState<EstimateAreaData[]>([]);
  const [lineItems, setLineItems] = useState<EstimateLineItemData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchAll = useCallback(async () => {
    if (!estimateId) { setLoading(false); return; }
    const supabase = getSupabase();

    const [estRes, areasRes, linesRes] = await Promise.all([
      supabase.from('estimates').select('*').eq('id', estimateId).single(),
      supabase.from('estimate_areas').select('*').eq('estimate_id', estimateId).order('sort_order'),
      supabase.from('estimate_line_items').select('*').eq('estimate_id', estimateId).order('sort_order'),
    ]);

    if (estRes.data) setEstimate(mapEstimate(estRes.data));
    setAreas((areasRes.data || []).map(mapEstimateArea));
    setLineItems((linesRes.data || []).map(mapEstimateLineItem));
    setLoading(false);
  }, [estimateId]);

  useEffect(() => {
    fetchAll();
    if (!estimateId) return;

    const supabase = getSupabase();
    const channel = supabase.channel(`team-estimate-${estimateId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'estimates' }, () => fetchAll())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'estimate_areas' }, () => fetchAll())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'estimate_line_items' }, () => fetchAll())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [estimateId, fetchAll]);

  return { estimate, areas, lineItems, loading, refetch: fetchAll };
}

// Create estimate (simplified for field use)
export async function createFieldEstimate(input: {
  companyId: string;
  userId: string;
  title: string;
  estimateType: EstimateType;
  jobId?: string;
  customerName?: string;
  propertyAddress?: string;
}): Promise<string | null> {
  const supabase = getSupabase();

  // Auto-number: EST-YYYYMMDD-NNN
  const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const { data: lastEst } = await supabase
    .from('estimates')
    .select('estimate_number')
    .eq('company_id', input.companyId)
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

  const { data, error } = await supabase
    .from('estimates')
    .insert({
      company_id: input.companyId,
      created_by: input.userId,
      estimate_number: estimateNumber,
      title: input.title,
      estimate_type: input.estimateType,
      status: 'draft',
      customer_name: input.customerName || '',
      property_address: input.propertyAddress || '',
      job_id: input.jobId || null,
      overhead_percent: 10,
      profit_percent: 10,
    })
    .select('id')
    .single();

  if (error) { console.error('Create estimate failed:', error); return null; }
  return data?.id || null;
}

// Add area to estimate
export async function addEstimateArea(input: {
  estimateId: string;
  name: string;
  lengthFt?: number;
  widthFt?: number;
  heightFt?: number;
  sortOrder?: number;
}): Promise<string | null> {
  const supabase = getSupabase();

  const lengthFt = input.lengthFt || 0;
  const widthFt = input.widthFt || 0;
  const floorSf = lengthFt * widthFt;

  const { data, error } = await supabase
    .from('estimate_areas')
    .insert({
      estimate_id: input.estimateId,
      name: input.name,
      length_ft: lengthFt,
      width_ft: widthFt,
      height_ft: input.heightFt || 8,
      floor_sf: floorSf,
      sort_order: input.sortOrder || 0,
    })
    .select('id')
    .single();

  if (error) { console.error('Add area failed:', error); return null; }
  return data?.id || null;
}

// Add line item to estimate
export async function addEstimateLineItem(input: {
  estimateId: string;
  areaId?: string;
  zaftoCode?: string;
  description: string;
  actionType?: string;
  quantity: number;
  unitCode?: string;
  unitPrice: number;
  sortOrder?: number;
}): Promise<string | null> {
  const supabase = getSupabase();

  const lineTotal = input.quantity * input.unitPrice;

  const { data, error } = await supabase
    .from('estimate_line_items')
    .insert({
      estimate_id: input.estimateId,
      area_id: input.areaId || null,
      zafto_code: input.zaftoCode || '',
      description: input.description,
      action_type: input.actionType || 'replace',
      quantity: input.quantity,
      unit_code: input.unitCode || 'EA',
      unit_price: input.unitPrice,
      line_total: lineTotal,
      sort_order: input.sortOrder || 0,
    })
    .select('id')
    .single();

  if (error) { console.error('Add line item failed:', error); return null; }
  return data?.id || null;
}

// Recalculate estimate totals from line items
export async function recalculateEstimateTotals(estimateId: string): Promise<void> {
  const supabase = getSupabase();

  // Fetch current estimate for O&P/tax percentages
  const { data: est } = await supabase
    .from('estimates')
    .select('overhead_percent, profit_percent, tax_percent')
    .eq('id', estimateId)
    .single();

  if (!est) return;

  // Sum all line items
  const { data: lines } = await supabase
    .from('estimate_line_items')
    .select('line_total')
    .eq('estimate_id', estimateId);

  const lineRows: { line_total: number }[] = (lines || []) as { line_total: number }[];
  const subtotal = lineRows.reduce((sum, l) => sum + Number(l.line_total || 0), 0);
  const overheadPct = Number(est.overhead_percent || 0);
  const profitPct = Number(est.profit_percent || 0);
  const taxPct = Number(est.tax_percent || 0);

  const overheadAmount = subtotal * (overheadPct / 100);
  const profitAmount = subtotal * (profitPct / 100);
  const afterOp = subtotal + overheadAmount + profitAmount;
  const taxAmount = afterOp * (taxPct / 100);
  const grandTotal = afterOp + taxAmount;

  const { error } = await supabase
    .from('estimates')
    .update({
      subtotal,
      overhead_amount: overheadAmount,
      profit_amount: profitAmount,
      tax_amount: taxAmount,
      grand_total: grandTotal,
    })
    .eq('id', estimateId);

  if (error) console.error('Recalculate totals failed:', error);
}
