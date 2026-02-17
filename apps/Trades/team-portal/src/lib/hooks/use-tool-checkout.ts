'use client';

// ZAFTO Team Portal — Tool Checkout Hook
// Created: Sprint FIELD2 (Session 131)
//
// Equipment checkout/return for field employees.
// Uses equipment_items + equipment_checkouts tables.
// Separate from use-equipment.ts (restoration-specific).

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ════════════════════════════════════════════════════════════════
// TYPES
// ════════════════════════════════════════════════════════════════

export type EquipmentCategory =
  | 'hand_tool' | 'power_tool' | 'testing_equipment'
  | 'safety_equipment' | 'vehicle_mounted' | 'specialty';

export type EquipmentCondition = 'new' | 'good' | 'fair' | 'poor' | 'damaged' | 'retired';

export interface ToolItem {
  id: string;
  name: string;
  category: EquipmentCategory;
  serialNumber: string | null;
  barcode: string | null;
  manufacturer: string | null;
  modelNumber: string | null;
  condition: EquipmentCondition;
  currentHolderId: string | null;
  storageLocation: string | null;
  photoUrl: string | null;
}

export interface ToolCheckout {
  id: string;
  equipmentItemId: string;
  checkedOutBy: string;
  checkedOutAt: string;
  expectedReturnDate: string | null;
  checkedInAt: string | null;
  checkoutCondition: EquipmentCondition;
  checkinCondition: EquipmentCondition | null;
  jobId: string | null;
  notes: string | null;
  equipmentName?: string;
}

export const CATEGORY_LABELS: Record<EquipmentCategory, string> = {
  hand_tool: 'Hand Tool',
  power_tool: 'Power Tool',
  testing_equipment: 'Testing Equipment',
  safety_equipment: 'Safety Equipment',
  vehicle_mounted: 'Vehicle Mounted',
  specialty: 'Specialty',
};

export const CONDITION_LABELS: Record<EquipmentCondition, string> = {
  new: 'New',
  good: 'Good',
  fair: 'Fair',
  poor: 'Poor',
  damaged: 'Damaged',
  retired: 'Retired',
};

// ════════════════════════════════════════════════════════════════
// MAPPERS
// ════════════════════════════════════════════════════════════════

function mapItem(row: Record<string, unknown>): ToolItem {
  return {
    id: row.id as string,
    name: (row.name as string) || '',
    category: (row.category as EquipmentCategory) || 'hand_tool',
    serialNumber: (row.serial_number as string) || null,
    barcode: (row.barcode as string) || null,
    manufacturer: (row.manufacturer as string) || null,
    modelNumber: (row.model_number as string) || null,
    condition: (row.condition as EquipmentCondition) || 'good',
    currentHolderId: (row.current_holder_id as string) || null,
    storageLocation: (row.storage_location as string) || null,
    photoUrl: (row.photo_url as string) || null,
  };
}

function mapCheckout(row: Record<string, unknown>): ToolCheckout {
  const equipItem = row.equipment_items as Record<string, unknown> | undefined;
  return {
    id: row.id as string,
    equipmentItemId: (row.equipment_item_id as string) || '',
    checkedOutBy: (row.checked_out_by as string) || '',
    checkedOutAt: row.checked_out_at as string,
    expectedReturnDate: (row.expected_return_date as string) || null,
    checkedInAt: (row.checked_in_at as string) || null,
    checkoutCondition: (row.checkout_condition as EquipmentCondition) || 'good',
    checkinCondition: (row.checkin_condition as EquipmentCondition) || null,
    jobId: (row.job_id as string) || null,
    notes: (row.notes as string) || null,
    equipmentName: equipItem?.name as string | undefined,
  };
}

// ════════════════════════════════════════════════════════════════
// HOOKS
// ════════════════════════════════════════════════════════════════

/** All company tools (for browsing / checkout). */
export function useToolItems() {
  const [items, setItems] = useState<ToolItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('equipment_items')
        .select('*')
        .eq('is_active', true)
        .is('deleted_at', null)
        .order('name');

      if (err) throw err;
      setItems((data || []).map((row: Record<string, unknown>) => mapItem(row)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load tools');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetch();

    const supabase = getSupabase();
    const channel = supabase
      .channel('team-equipment-items')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'equipment_items' }, () => fetch())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetch]);

  return { items, loading, error, refetch: fetch };
}

/** My active (unreturned) checkouts. */
export function useMyCheckouts() {
  const [checkouts, setCheckouts] = useState<ToolCheckout[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [userId, setUserId] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      setUserId(user.id);

      const { data, error: err } = await supabase
        .from('equipment_checkouts')
        .select('*, equipment_items(name, category)')
        .eq('checked_out_by', user.id)
        .is('checked_in_at', null)
        .is('deleted_at', null)
        .order('checked_out_at', { ascending: false });

      if (err) throw err;
      setCheckouts((data || []).map((row: Record<string, unknown>) => mapCheckout(row)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load checkouts');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetch();

    const supabase = getSupabase();
    const channel = supabase
      .channel('team-my-checkouts')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'equipment_checkouts' }, () => fetch())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetch]);

  const overdueCheckouts = checkouts.filter((co) => {
    if (!co.expectedReturnDate) return false;
    return new Date(co.expectedReturnDate) < new Date();
  });

  return { checkouts, overdueCheckouts, loading, error, userId, refetch: fetch };
}

// ════════════════════════════════════════════════════════════════
// ACTIONS
// ════════════════════════════════════════════════════════════════

export async function checkoutTool(input: {
  equipmentItemId: string;
  condition: EquipmentCondition;
  expectedReturnDate?: string;
  jobId?: string;
  notes?: string;
}): Promise<void> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');
  const companyId = user.app_metadata?.company_id;
  if (!companyId) throw new Error('No company');

  const { error } = await supabase
    .from('equipment_checkouts')
    .insert({
      company_id: companyId,
      equipment_item_id: input.equipmentItemId,
      checked_out_by: user.id,
      checkout_condition: input.condition,
      expected_return_date: input.expectedReturnDate || null,
      job_id: input.jobId || null,
      notes: input.notes || null,
    });

  if (error) throw error;
}

export async function returnTool(input: {
  checkoutId: string;
  condition: EquipmentCondition;
  notes?: string;
}): Promise<void> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { error } = await supabase
    .from('equipment_checkouts')
    .update({
      checked_in_at: new Date().toISOString(),
      checked_in_by: user.id,
      checkin_condition: input.condition,
      notes: input.notes || null,
    })
    .eq('id', input.checkoutId);

  if (error) throw error;
}
