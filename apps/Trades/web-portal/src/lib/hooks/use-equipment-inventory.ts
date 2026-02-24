'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type InventoryEquipmentType =
  | 'dehumidifier' | 'air_mover' | 'air_scrubber' | 'heater'
  | 'moisture_meter' | 'thermal_camera' | 'hydroxyl_generator'
  | 'negative_air_machine' | 'injectidry' | 'other';

export type InventoryStatus = 'available' | 'deployed' | 'maintenance' | 'retired' | 'lost';

export interface EquipmentInventoryData {
  id: string;
  companyId: string;
  equipmentType: InventoryEquipmentType;
  name: string;
  make: string | null;
  model: string | null;
  serialNumber: string | null;
  assetTag: string | null;
  ahamPpd: number | null;
  ahamCfm: number | null;
  purchaseDate: string | null;
  purchasePrice: number | null;
  dailyRentalRate: number;
  status: InventoryStatus;
  currentJobId: string | null;
  currentDeploymentId: string | null;
  lastMaintenanceDate: string | null;
  nextMaintenanceDate: string | null;
  maintenanceNotes: string | null;
  totalDeployDays: number;
  photoStoragePath: string | null;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
}

export interface InventorySummary {
  total: number;
  available: number;
  deployed: number;
  maintenance: number;
  retired: number;
  lost: number;
  totalAssetValue: number;
  maintenanceDueSoon: number;
  byType: Record<string, number>;
}

// ============================================================================
// MAPPER
// ============================================================================

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapInventoryItem(row: any): EquipmentInventoryData {
  return {
    id: row.id,
    companyId: row.company_id,
    equipmentType: row.equipment_type,
    name: row.name,
    make: row.make ?? null,
    model: row.model ?? null,
    serialNumber: row.serial_number ?? null,
    assetTag: row.asset_tag ?? null,
    ahamPpd: row.aham_ppd != null ? parseFloat(row.aham_ppd) : null,
    ahamCfm: row.aham_cfm != null ? parseFloat(row.aham_cfm) : null,
    purchaseDate: row.purchase_date ?? null,
    purchasePrice: row.purchase_price != null ? parseFloat(row.purchase_price) : null,
    dailyRentalRate: parseFloat(row.daily_rental_rate) || 0,
    status: row.status,
    currentJobId: row.current_job_id ?? null,
    currentDeploymentId: row.current_deployment_id ?? null,
    lastMaintenanceDate: row.last_maintenance_date ?? null,
    nextMaintenanceDate: row.next_maintenance_date ?? null,
    maintenanceNotes: row.maintenance_notes ?? null,
    totalDeployDays: row.total_deploy_days ?? 0,
    photoStoragePath: row.photo_storage_path ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    deletedAt: row.deleted_at ?? null,
  };
}

// ============================================================================
// HOOK
// ============================================================================

export function useEquipmentInventory() {
  const [items, setItems] = useState<EquipmentInventoryData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('equipment_inventory')
        .select('*')
        .is('deleted_at', null)
        .order('name');

      if (err) throw err;
      setItems((data || []).map(mapInventoryItem));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load equipment inventory');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetch();
    const supabase = getSupabase();
    const channel = supabase
      .channel('equip-inventory')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'equipment_inventory' }, () => { fetch(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetch]);

  const summary = useMemo<InventorySummary>(() => {
    const active = items.filter(i => !i.deletedAt);
    const now = new Date();
    const sevenDaysOut = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const byType: Record<string, number> = {};
    for (const item of active) {
      byType[item.equipmentType] = (byType[item.equipmentType] || 0) + 1;
    }
    return {
      total: active.length,
      available: active.filter(i => i.status === 'available').length,
      deployed: active.filter(i => i.status === 'deployed').length,
      maintenance: active.filter(i => i.status === 'maintenance').length,
      retired: active.filter(i => i.status === 'retired').length,
      lost: active.filter(i => i.status === 'lost').length,
      totalAssetValue: active.reduce((sum, i) => sum + (i.purchasePrice || 0), 0),
      maintenanceDueSoon: active.filter(i =>
        i.nextMaintenanceDate && new Date(i.nextMaintenanceDate) <= sevenDaysOut && i.status !== 'retired'
      ).length,
      byType,
    };
  }, [items]);

  const addItem = async (input: {
    equipmentType: InventoryEquipmentType;
    name: string;
    make?: string;
    model?: string;
    serialNumber?: string;
    assetTag?: string;
    ahamPpd?: number;
    ahamCfm?: number;
    purchaseDate?: string;
    purchasePrice?: number;
    dailyRentalRate?: number;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data, error: err } = await supabase
      .from('equipment_inventory')
      .insert({
        company_id: companyId,
        equipment_type: input.equipmentType,
        name: input.name,
        make: input.make ?? null,
        model: input.model ?? null,
        serial_number: input.serialNumber ?? null,
        asset_tag: input.assetTag ?? null,
        aham_ppd: input.ahamPpd ?? null,
        aham_cfm: input.ahamCfm ?? null,
        purchase_date: input.purchaseDate ?? null,
        purchase_price: input.purchasePrice ?? null,
        daily_rental_rate: input.dailyRentalRate ?? 0,
        status: 'available',
      })
      .select('id')
      .single();

    if (err) throw err;
    return data.id;
  };

  const updateItem = async (id: string, updates: {
    name?: string;
    make?: string;
    model?: string;
    serialNumber?: string;
    assetTag?: string;
    ahamPpd?: number | null;
    ahamCfm?: number | null;
    dailyRentalRate?: number;
    maintenanceNotes?: string;
    nextMaintenanceDate?: string | null;
  }): Promise<void> => {
    const supabase = getSupabase();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const row: Record<string, any> = {};
    if (updates.name !== undefined) row.name = updates.name;
    if (updates.make !== undefined) row.make = updates.make;
    if (updates.model !== undefined) row.model = updates.model;
    if (updates.serialNumber !== undefined) row.serial_number = updates.serialNumber;
    if (updates.assetTag !== undefined) row.asset_tag = updates.assetTag;
    if (updates.ahamPpd !== undefined) row.aham_ppd = updates.ahamPpd;
    if (updates.ahamCfm !== undefined) row.aham_cfm = updates.ahamCfm;
    if (updates.dailyRentalRate !== undefined) row.daily_rental_rate = updates.dailyRentalRate;
    if (updates.maintenanceNotes !== undefined) row.maintenance_notes = updates.maintenanceNotes;
    if (updates.nextMaintenanceDate !== undefined) row.next_maintenance_date = updates.nextMaintenanceDate;

    const { error: err } = await supabase
      .from('equipment_inventory')
      .update(row)
      .eq('id', id);

    if (err) throw err;
  };

  const setStatus = async (id: string, status: InventoryStatus): Promise<void> => {
    const supabase = getSupabase();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const row: Record<string, any> = { status };
    if (status === 'available') {
      row.current_job_id = null;
      row.current_deployment_id = null;
    }
    if (status === 'maintenance') {
      row.last_maintenance_date = new Date().toISOString().split('T')[0];
    }

    const { error: err } = await supabase
      .from('equipment_inventory')
      .update(row)
      .eq('id', id);

    if (err) throw err;
  };

  const softDelete = async (id: string): Promise<void> => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('equipment_inventory')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);

    if (err) throw err;
  };

  return {
    items,
    summary,
    loading,
    error,
    addItem,
    updateItem,
    setStatus,
    softDelete,
    refetch: fetch,
  };
}
