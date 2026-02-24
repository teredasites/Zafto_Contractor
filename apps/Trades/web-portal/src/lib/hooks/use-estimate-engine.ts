'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──

export interface XactimateCode {
  id: string;
  categoryCode: string;
  categoryName: string;
  selectorCode: string;
  fullCode: string;
  description: string;
  unit: string;
  coverageGroup: 'structural' | 'contents' | 'other';
  hasMaterial: boolean;
  hasLabor: boolean;
  hasEquipment: boolean;
}

export interface PricingEntry {
  codeId: string;
  materialCost: number;
  laborCost: number;
  equipmentCost: number;
  totalCost: number;
  confidence: 'low' | 'medium' | 'high' | 'verified';
  sourceCount: number;
}

export interface EstimateLine {
  id: string;
  claimId: string;
  codeId: string | null;
  category: string;
  itemCode: string;
  description: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  total: number;
  materialCost: number;
  laborCost: number;
  equipmentCost: number;
  roomName: string;
  lineNumber: number;
  coverageGroup: 'structural' | 'contents' | 'other';
  isSupplement: boolean;
  supplementId: string | null;
  depreciationRate: number;
  acvAmount: number | null;
  rcvAmount: number | null;
  notes: string;
}

export interface EstimateTemplate {
  id: string;
  name: string;
  description: string;
  tradeType: string;
  lossType: string;
  lineItems: Array<{ code: string; description: string; qty: number; unit: string; notes?: string }>;
  isSystem: boolean;
  usageCount: number;
}

export interface EstimateSummary {
  structural: { rcv: number; depreciation: number; acv: number };
  contents: { rcv: number; depreciation: number; acv: number };
  other: { rcv: number; depreciation: number; acv: number };
  subtotal: number;
  overhead: number;
  profit: number;
  grandTotal: number;
}

// ── Mappers ──

function mapCode(row: Record<string, unknown>): XactimateCode {
  return {
    id: row.id as string,
    categoryCode: row.category_code as string,
    categoryName: row.category_name as string,
    selectorCode: row.selector_code as string,
    fullCode: row.full_code as string,
    description: row.description as string,
    unit: row.unit as string,
    coverageGroup: row.coverage_group as XactimateCode['coverageGroup'],
    hasMaterial: row.has_material as boolean,
    hasLabor: row.has_labor as boolean,
    hasEquipment: row.has_equipment as boolean,
  };
}

function mapLine(row: Record<string, unknown>): EstimateLine {
  return {
    id: row.id as string,
    claimId: row.claim_id as string,
    codeId: row.code_id as string | null,
    category: row.category as string,
    itemCode: row.item_code as string,
    description: row.description as string,
    quantity: Number(row.quantity || 1),
    unit: row.unit as string,
    unitPrice: Number(row.unit_price || 0),
    total: Number(row.total || 0),
    materialCost: Number(row.material_cost || 0),
    laborCost: Number(row.labor_cost || 0),
    equipmentCost: Number(row.equipment_cost || 0),
    roomName: (row.room_name as string) || '',
    lineNumber: Number(row.line_number || 0),
    coverageGroup: (row.coverage_group as EstimateLine['coverageGroup']) || 'structural',
    isSupplement: (row.is_supplement as boolean) || false,
    supplementId: row.supplement_id as string | null,
    depreciationRate: Number(row.depreciation_rate || 0),
    acvAmount: row.acv_amount !== null ? Number(row.acv_amount) : null,
    rcvAmount: row.rcv_amount !== null ? Number(row.rcv_amount) : null,
    notes: (row.notes as string) || '',
  };
}

function mapTemplate(row: Record<string, unknown>): EstimateTemplate {
  return {
    id: row.id as string,
    name: row.name as string,
    description: (row.description as string) || '',
    tradeType: (row.trade_type as string) || '',
    lossType: (row.loss_type as string) || '',
    lineItems: (row.line_items as EstimateTemplate['lineItems']) || [],
    isSystem: (row.is_system as boolean) || false,
    usageCount: Number(row.usage_count || 0),
  };
}

// ── Hook: Code Search ──

export function useXactCodes() {
  const [codes, setCodes] = useState<XactimateCode[]>([]);
  const [loading, setLoading] = useState(false);

  const searchCodes = useCallback(async (query: string, category?: string) => {
    setLoading(true);
    try {
      const supabase = getSupabase();
      let dbQuery = supabase
        .from('xactimate_codes')
        .select('*')
        .eq('deprecated', false);

      if (query) {
        dbQuery = dbQuery.or(
          `description.ilike.%${query}%,full_code.ilike.%${query}%`
        );
      }
      if (category) {
        dbQuery = dbQuery.eq('category_code', category.toUpperCase());
      }

      const { data, error } = await dbQuery
        .order('category_code')
        .order('selector_code')
        .limit(100);

      if (error) throw error;
      setCodes((data || []).map(mapCode));
    } catch (e: unknown) {
      console.error('Code search failed:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  const getCategories = useCallback(async (): Promise<Array<{ code: string; name: string }>> => {
    const supabase = getSupabase();
    const { data } = await supabase
      .from('xactimate_codes')
      .select('category_code, category_name')
      .eq('deprecated', false)
      .order('category_code');

    const seen = new Set<string>();
    return ((data || []) as { category_code: string; category_name: string }[])
      .filter((c) => {
        if (seen.has(c.category_code)) return false;
        seen.add(c.category_code);
        return true;
      })
      .map((c) => ({ code: c.category_code, name: c.category_name }));
  }, []);

  return { codes, loading, searchCodes, getCategories };
}

// ── Hook: Pricing Lookup ──

export function usePricingLookup() {
  const lookupPrice = useCallback(async (
    codeId: string,
    regionCode: string
  ): Promise<PricingEntry | null> => {
    const supabase = getSupabase();

    // First check company override, then global
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;

    const { data: profile } = await supabase
      .from('users')
      .select('company_id')
      .eq('id', user.id)
      .single();

    // Company override
    if (profile?.company_id) {
      const { data: companyPrice } = await supabase
        .from('pricing_entries')
        .select('*')
        .eq('code_id', codeId)
        .eq('region_code', regionCode)
        .eq('company_id', profile.company_id)
        .order('effective_date', { ascending: false })
        .limit(1)
        .single();

      if (companyPrice) {
        return {
          codeId,
          materialCost: Number(companyPrice.material_cost || 0),
          laborCost: Number(companyPrice.labor_cost || 0),
          equipmentCost: Number(companyPrice.equipment_cost || 0),
          totalCost: Number(companyPrice.total_cost || 0),
          confidence: companyPrice.confidence as PricingEntry['confidence'],
          sourceCount: Number(companyPrice.source_count || 0),
        };
      }
    }

    // Global price
    const { data: globalPrice } = await supabase
      .from('pricing_entries')
      .select('*')
      .eq('code_id', codeId)
      .eq('region_code', regionCode)
      .is('company_id', null)
      .order('effective_date', { ascending: false })
      .limit(1)
      .single();

    if (globalPrice) {
      return {
        codeId,
        materialCost: Number(globalPrice.material_cost || 0),
        laborCost: Number(globalPrice.labor_cost || 0),
        equipmentCost: Number(globalPrice.equipment_cost || 0),
        totalCost: Number(globalPrice.total_cost || 0),
        confidence: globalPrice.confidence as PricingEntry['confidence'],
        sourceCount: Number(globalPrice.source_count || 0),
      };
    }

    return null;
  }, []);

  return { lookupPrice };
}

// ── Hook: Estimate Lines CRUD ──

export function useEstimateLines(claimId: string | null) {
  const [lines, setLines] = useState<EstimateLine[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchLines = useCallback(async () => {
    if (!claimId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('xactimate_estimate_lines')
        .select('*')
        .eq('claim_id', claimId)
        .is('deleted_at', null)
        .order('room_name')
        .order('line_number');

      if (err) throw err;
      setLines((data || []).map(mapLine));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load lines');
    } finally {
      setLoading(false);
    }
  }, [claimId]);

  useEffect(() => {
    fetchLines();
  }, [fetchLines]);

  const addLine = useCallback(async (line: Omit<EstimateLine, 'id'>) => {
    if (!claimId) return;
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const { data: profile } = await supabase
      .from('users')
      .select('company_id')
      .eq('id', user.id)
      .single();

    const { error: err } = await supabase
      .from('xactimate_estimate_lines')
      .insert({
        company_id: profile?.company_id,
        claim_id: claimId,
        code_id: line.codeId,
        category: line.category,
        item_code: line.itemCode,
        description: line.description,
        quantity: line.quantity,
        unit: line.unit,
        unit_price: line.unitPrice,
        total: line.total,
        material_cost: line.materialCost,
        labor_cost: line.laborCost,
        equipment_cost: line.equipmentCost,
        room_name: line.roomName,
        line_number: line.lineNumber,
        coverage_group: line.coverageGroup,
        is_supplement: line.isSupplement,
        supplement_id: line.supplementId,
        depreciation_rate: line.depreciationRate,
        acv_amount: line.acvAmount,
        rcv_amount: line.rcvAmount,
        notes: line.notes,
      });

    if (err) console.error('Add line failed:', err);
    else fetchLines();
  }, [claimId, fetchLines]);

  const updateLine = useCallback(async (lineId: string, updates: Partial<EstimateLine>) => {
    const supabase = getSupabase();
    const dbUpdates: Record<string, unknown> = {};
    if (updates.quantity !== undefined) dbUpdates.quantity = updates.quantity;
    if (updates.unitPrice !== undefined) dbUpdates.unit_price = updates.unitPrice;
    if (updates.total !== undefined) dbUpdates.total = updates.total;
    if (updates.materialCost !== undefined) dbUpdates.material_cost = updates.materialCost;
    if (updates.laborCost !== undefined) dbUpdates.labor_cost = updates.laborCost;
    if (updates.equipmentCost !== undefined) dbUpdates.equipment_cost = updates.equipmentCost;
    if (updates.roomName !== undefined) dbUpdates.room_name = updates.roomName;
    if (updates.lineNumber !== undefined) dbUpdates.line_number = updates.lineNumber;
    if (updates.coverageGroup !== undefined) dbUpdates.coverage_group = updates.coverageGroup;
    if (updates.depreciationRate !== undefined) dbUpdates.depreciation_rate = updates.depreciationRate;
    if (updates.notes !== undefined) dbUpdates.notes = updates.notes;

    const { error: err } = await supabase
      .from('xactimate_estimate_lines')
      .update(dbUpdates)
      .eq('id', lineId);

    if (err) console.error('Update line failed:', err);
    else fetchLines();
  }, [fetchLines]);

  const deleteLine = useCallback(async (lineId: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('xactimate_estimate_lines')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', lineId);

    if (err) console.error('Delete line failed:', err);
    else fetchLines();
  }, [fetchLines]);

  // ── Summary Calculator ──
  const calculateSummary = useCallback((
    estimateLines: EstimateLine[],
    overheadRate: number = 10,
    profitRate: number = 10
  ): EstimateSummary => {
    const groups = { structural: { rcv: 0, depreciation: 0, acv: 0 }, contents: { rcv: 0, depreciation: 0, acv: 0 }, other: { rcv: 0, depreciation: 0, acv: 0 } };

    for (const line of estimateLines) {
      const group = groups[line.coverageGroup] || groups.structural;
      const rcv = line.total;
      const dep = rcv * (line.depreciationRate / 100);
      const acv = rcv - dep;

      group.rcv += rcv;
      group.depreciation += dep;
      group.acv += acv;
    }

    const subtotal = groups.structural.rcv + groups.contents.rcv + groups.other.rcv;
    const overhead = subtotal * (overheadRate / 100);
    const profit = subtotal * (profitRate / 100);
    const grandTotal = subtotal + overhead + profit;

    return { ...groups, subtotal, overhead, profit, grandTotal };
  }, []);

  return { lines, loading, error, fetchLines, addLine, updateLine, deleteLine, calculateSummary };
}

// ── Hook: Estimate Templates ──

export function useEstimateTemplates() {
  const [templates, setTemplates] = useState<EstimateTemplate[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchTemplates = useCallback(async () => {
    setLoading(true);
    try {
      const supabase = getSupabase();
      const { data, error } = await supabase
        .from('estimate_templates')
        .select('*')
        .order('usage_count', { ascending: false });

      if (error) throw error;
      setTemplates((data || []).map(mapTemplate));
    } catch (e: unknown) {
      console.error('Template fetch failed:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTemplates();
  }, [fetchTemplates]);

  const saveTemplate = useCallback(async (template: Omit<EstimateTemplate, 'id' | 'usageCount' | 'isSystem'>) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const { data: profile } = await supabase
      .from('users')
      .select('company_id')
      .eq('id', user.id)
      .single();

    const { error } = await supabase
      .from('estimate_templates')
      .insert({
        company_id: profile?.company_id,
        name: template.name,
        description: template.description,
        trade_type: template.tradeType,
        loss_type: template.lossType,
        line_items: template.lineItems,
      });

    if (error) console.error('Save template failed:', error);
    else fetchTemplates();
  }, [fetchTemplates]);

  return { templates, loading, fetchTemplates, saveTemplate };
}
