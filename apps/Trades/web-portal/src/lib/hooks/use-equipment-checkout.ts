'use client';

// ZAFTO Equipment Checkout Hook (CRM)
// Created: Sprint FIELD2 (Session 131)
//
// CRUD for equipment_items + equipment_checkouts tables.
// General-purpose tool/equipment checkout for ALL trades.
// Separate from use-equipment-inventory.ts (restoration-specific).

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ════════════════════════════════════════════════════════════════
// TYPES
// ════════════════════════════════════════════════════════════════

export type EquipmentCategory =
  | 'hand_tool' | 'power_tool' | 'testing_equipment'
  | 'safety_equipment' | 'vehicle_mounted' | 'specialty';

export type EquipmentCondition = 'new' | 'good' | 'fair' | 'poor' | 'damaged' | 'retired';

export interface EquipmentItemData {
  id: string;
  companyId: string;
  name: string;
  category: EquipmentCategory;
  serialNumber: string | null;
  barcode: string | null;
  manufacturer: string | null;
  modelNumber: string | null;
  purchaseDate: string | null;
  purchaseCost: number | null;
  condition: EquipmentCondition;
  currentHolderId: string | null;
  storageLocation: string | null;
  photoUrl: string | null;
  lastInspectionDate: string | null;
  nextCalibrationDate: string | null;
  warrantyExpiry: string | null;
  notes: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface EquipmentCheckoutData {
  id: string;
  companyId: string;
  equipmentItemId: string;
  checkedOutBy: string;
  checkedOutAt: string;
  expectedReturnDate: string | null;
  checkedInAt: string | null;
  checkedInBy: string | null;
  checkoutCondition: EquipmentCondition;
  checkinCondition: EquipmentCondition | null;
  jobId: string | null;
  notes: string | null;
  photoOutUrl: string | null;
  photoInUrl: string | null;
  // Joined
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

function mapItem(row: Record<string, unknown>): EquipmentItemData {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    name: (row.name as string) || '',
    category: (row.category as EquipmentCategory) || 'hand_tool',
    serialNumber: (row.serial_number as string) || null,
    barcode: (row.barcode as string) || null,
    manufacturer: (row.manufacturer as string) || null,
    modelNumber: (row.model_number as string) || null,
    purchaseDate: (row.purchase_date as string) || null,
    purchaseCost: row.purchase_cost != null ? Number(row.purchase_cost) : null,
    condition: (row.condition as EquipmentCondition) || 'good',
    currentHolderId: (row.current_holder_id as string) || null,
    storageLocation: (row.storage_location as string) || null,
    photoUrl: (row.photo_url as string) || null,
    lastInspectionDate: (row.last_inspection_date as string) || null,
    nextCalibrationDate: (row.next_calibration_date as string) || null,
    warrantyExpiry: (row.warranty_expiry as string) || null,
    notes: (row.notes as string) || null,
    isActive: (row.is_active as boolean) ?? true,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapCheckout(row: Record<string, unknown>): EquipmentCheckoutData {
  const equipItem = row.equipment_items as Record<string, unknown> | undefined;

  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    equipmentItemId: (row.equipment_item_id as string) || '',
    checkedOutBy: (row.checked_out_by as string) || '',
    checkedOutAt: row.checked_out_at as string,
    expectedReturnDate: (row.expected_return_date as string) || null,
    checkedInAt: (row.checked_in_at as string) || null,
    checkedInBy: (row.checked_in_by as string) || null,
    checkoutCondition: (row.checkout_condition as EquipmentCondition) || 'good',
    checkinCondition: (row.checkin_condition as EquipmentCondition) || null,
    jobId: (row.job_id as string) || null,
    notes: (row.notes as string) || null,
    photoOutUrl: (row.photo_out_url as string) || null,
    photoInUrl: (row.photo_in_url as string) || null,
    equipmentName: equipItem?.name as string | undefined,
  };
}

// ════════════════════════════════════════════════════════════════
// EQUIPMENT ITEMS HOOK
// ════════════════════════════════════════════════════════════════

export function useEquipmentItems() {
  const [items, setItems] = useState<EquipmentItemData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchItems = useCallback(async () => {
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
      setItems((data || []).map(mapItem));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load equipment');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchItems();

    const supabase = getSupabase();
    const channel = supabase
      .channel('crm-equipment-items')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'equipment_items' }, () => fetchItems())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchItems]);

  return { items, loading, error, refetch: fetchItems };
}

// ════════════════════════════════════════════════════════════════
// ACTIVE CHECKOUTS HOOK
// ════════════════════════════════════════════════════════════════

export function useActiveCheckouts() {
  const [checkouts, setCheckouts] = useState<EquipmentCheckoutData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchCheckouts = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('equipment_checkouts')
        .select('*, equipment_items(name, category)')
        .is('checked_in_at', null)
        .is('deleted_at', null)
        .order('checked_out_at', { ascending: false });

      if (err) throw err;
      setCheckouts((data || []).map(mapCheckout));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load checkouts');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchCheckouts();

    const supabase = getSupabase();
    const channel = supabase
      .channel('crm-equipment-checkouts')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'equipment_checkouts' }, () => fetchCheckouts())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchCheckouts]);

  // Derived: overdue
  const overdueCheckouts = checkouts.filter(co => {
    if (!co.expectedReturnDate) return false;
    return new Date(co.expectedReturnDate) < new Date();
  });

  return { checkouts, overdueCheckouts, loading, error, refetch: fetchCheckouts };
}

// ════════════════════════════════════════════════════════════════
// ACTIONS
// ════════════════════════════════════════════════════════════════

export async function createEquipmentItem(input: {
  name: string;
  category: EquipmentCategory;
  serialNumber?: string;
  barcode?: string;
  manufacturer?: string;
  modelNumber?: string;
  purchaseDate?: string;
  purchaseCost?: number;
  condition?: EquipmentCondition;
  storageLocation?: string;
  notes?: string;
}): Promise<EquipmentItemData> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');
  const companyId = user.app_metadata?.company_id;
  if (!companyId) throw new Error('No company');

  const { data, error } = await supabase
    .from('equipment_items')
    .insert({
      company_id: companyId,
      name: input.name,
      category: input.category,
      serial_number: input.serialNumber || null,
      barcode: input.barcode || null,
      manufacturer: input.manufacturer || null,
      model_number: input.modelNumber || null,
      purchase_date: input.purchaseDate || null,
      purchase_cost: input.purchaseCost || null,
      condition: input.condition || 'good',
      storage_location: input.storageLocation || null,
      notes: input.notes || null,
    })
    .select()
    .single();

  if (error) throw error;
  return mapItem(data);
}

export async function checkoutEquipment(input: {
  equipmentItemId: string;
  condition: EquipmentCondition;
  expectedReturnDate?: string;
  jobId?: string;
  notes?: string;
}): Promise<EquipmentCheckoutData> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');
  const companyId = user.app_metadata?.company_id;
  if (!companyId) throw new Error('No company');

  const { data, error } = await supabase
    .from('equipment_checkouts')
    .insert({
      company_id: companyId,
      equipment_item_id: input.equipmentItemId,
      checked_out_by: user.id,
      checkout_condition: input.condition,
      expected_return_date: input.expectedReturnDate || null,
      job_id: input.jobId || null,
      notes: input.notes || null,
    })
    .select()
    .single();

  if (error) throw error;
  return mapCheckout(data);
}

export async function checkinEquipment(input: {
  checkoutId: string;
  condition: EquipmentCondition;
  notes?: string;
}): Promise<EquipmentCheckoutData> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { data, error } = await supabase
    .from('equipment_checkouts')
    .update({
      checked_in_at: new Date().toISOString(),
      checked_in_by: user.id,
      checkin_condition: input.condition,
      notes: input.notes || null,
    })
    .eq('id', input.checkoutId)
    .select()
    .single();

  if (error) throw error;
  return mapCheckout(data);
}

export async function updateEquipmentItem(
  itemId: string,
  updates: Partial<Pick<EquipmentItemData, 'name' | 'category' | 'serialNumber' | 'barcode' | 'manufacturer' | 'modelNumber' | 'storageLocation' | 'condition' | 'notes'>>,
): Promise<EquipmentItemData> {
  const supabase = getSupabase();
  const dbUpdates: Record<string, unknown> = {};

  if (updates.name !== undefined) dbUpdates.name = updates.name;
  if (updates.category !== undefined) dbUpdates.category = updates.category;
  if (updates.serialNumber !== undefined) dbUpdates.serial_number = updates.serialNumber;
  if (updates.barcode !== undefined) dbUpdates.barcode = updates.barcode;
  if (updates.manufacturer !== undefined) dbUpdates.manufacturer = updates.manufacturer;
  if (updates.modelNumber !== undefined) dbUpdates.model_number = updates.modelNumber;
  if (updates.storageLocation !== undefined) dbUpdates.storage_location = updates.storageLocation;
  if (updates.condition !== undefined) dbUpdates.condition = updates.condition;
  if (updates.notes !== undefined) dbUpdates.notes = updates.notes;

  const { data, error } = await supabase
    .from('equipment_items')
    .update(dbUpdates)
    .eq('id', itemId)
    .select()
    .single();

  if (error) throw error;
  return mapItem(data);
}

export async function deleteEquipmentItem(itemId: string): Promise<void> {
  const supabase = getSupabase();
  const { error } = await supabase
    .from('equipment_items')
    .update({ deleted_at: new Date().toISOString(), is_active: false })
    .eq('id', itemId);

  if (error) throw error;
}
