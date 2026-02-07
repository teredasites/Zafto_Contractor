'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapPmInspection, mapPmInspectionItem } from './pm-mappers';
import type { PmInspectionData, PmInspectionItemData } from './pm-mappers';

export function usePmInspections() {
  const [inspections, setInspections] = useState<PmInspectionData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchInspections = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('pm_inspections')
        .select('*, properties(address_line1), units(unit_number), pm_inspection_items(*)')
        .order('inspection_date', { ascending: false });

      if (err) throw err;
      setInspections((data || []).map(mapPmInspection));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load inspections';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchInspections();

    const supabase = getSupabase();
    const channel = supabase
      .channel('pm-inspections-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'pm_inspections' }, () => {
        fetchInspections();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchInspections]);

  const createInspection = async (data: {
    propertyId: string;
    unitId?: string;
    leaseId?: string;
    inspectionType: PmInspectionData['inspectionType'];
    inspectionDate: string;
    inspectedBy?: string;
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('pm_inspections')
      .insert({
        company_id: companyId,
        property_id: data.propertyId,
        unit_id: data.unitId || null,
        lease_id: data.leaseId || null,
        inspection_type: data.inspectionType,
        inspection_date: data.inspectionDate,
        inspected_by: data.inspectedBy || user.id,
        notes: data.notes || null,
        status: 'scheduled',
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateInspection = async (id: string, data: {
    inspectionType?: PmInspectionData['inspectionType'];
    inspectionDate?: string;
    inspectedBy?: string;
    notes?: string;
    status?: PmInspectionData['status'];
  }) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.inspectionType !== undefined) updateData.inspection_type = data.inspectionType;
    if (data.inspectionDate !== undefined) updateData.inspection_date = data.inspectionDate;
    if (data.inspectedBy !== undefined) updateData.inspected_by = data.inspectedBy;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.status !== undefined) updateData.status = data.status;

    const { error: err } = await supabase
      .from('pm_inspections')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;
  };

  const completeInspection = async (id: string, overallCondition: PmInspectionData['overallCondition']) => {
    const supabase = getSupabase();

    const { error: err } = await supabase
      .from('pm_inspections')
      .update({
        status: 'completed',
        overall_condition: overallCondition,
        completed_at: new Date().toISOString(),
      })
      .eq('id', id);

    if (err) throw err;
  };

  const addInspectionItem = async (inspectionId: string, data: {
    area: string;
    item: string;
    condition: PmInspectionItemData['condition'];
    notes?: string;
    photos?: string[];
    requiresRepair?: boolean;
    repairCostEstimate?: number;
    depositDeduction?: number;
  }): Promise<string> => {
    const supabase = getSupabase();

    const { data: result, error: err } = await supabase
      .from('pm_inspection_items')
      .insert({
        inspection_id: inspectionId,
        area: data.area,
        item: data.item,
        condition: data.condition,
        notes: data.notes || null,
        photos: data.photos || [],
        requires_repair: data.requiresRepair || false,
        repair_cost_estimate: data.repairCostEstimate || null,
        deposit_deduction: data.depositDeduction || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateInspectionItem = async (itemId: string, data: {
    area?: string;
    item?: string;
    condition?: PmInspectionItemData['condition'];
    notes?: string;
    photos?: string[];
    requiresRepair?: boolean;
    repairCostEstimate?: number;
    depositDeduction?: number;
  }) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.area !== undefined) updateData.area = data.area;
    if (data.item !== undefined) updateData.item = data.item;
    if (data.condition !== undefined) updateData.condition = data.condition;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.photos !== undefined) updateData.photos = data.photos;
    if (data.requiresRepair !== undefined) updateData.requires_repair = data.requiresRepair;
    if (data.repairCostEstimate !== undefined) updateData.repair_cost_estimate = data.repairCostEstimate;
    if (data.depositDeduction !== undefined) updateData.deposit_deduction = data.depositDeduction;

    const { error: err } = await supabase
      .from('pm_inspection_items')
      .update(updateData)
      .eq('id', itemId);

    if (err) throw err;
  };

  const getInspectionsByProperty = async (propertyId: string): Promise<PmInspectionData[]> => {
    const supabase = getSupabase();

    const { data, error: err } = await supabase
      .from('pm_inspections')
      .select('*, properties(address_line1), units(unit_number), pm_inspection_items(*)')
      .eq('property_id', propertyId)
      .order('inspection_date', { ascending: false });

    if (err) throw err;
    return (data || []).map(mapPmInspection);
  };

  return {
    inspections,
    loading,
    error,
    refetch: fetchInspections,
    createInspection,
    updateInspection,
    completeInspection,
    addInspectionItem,
    updateInspectionItem,
    getInspectionsByProperty,
  };
}
