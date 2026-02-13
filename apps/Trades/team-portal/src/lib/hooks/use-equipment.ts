'use client';

import { useState, useEffect, useCallback } from 'react';
import { createClient } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface FieldEquipmentData {
  id: string;
  jobId: string;
  equipmentType: string;
  equipmentName: string;
  serialNumber: string | null;
  areaDeployed: string;
  dailyRate: number;
  deployedAt: string;
  removedAt: string | null;
  status: string;
}

export interface DeployEquipmentInput {
  jobId: string;
  equipmentType: string;
  equipmentName: string;
  serialNumber?: string;
  areaDeployed: string;
  dailyRate?: number;
}

// ============================================================================
// HOOK: useFieldEquipment — for field technicians
// ============================================================================

export function useFieldEquipment(jobId: string) {
  const [equipment, setEquipment] = useState<FieldEquipmentData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchEquipment = useCallback(async () => {
    if (!jobId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = createClient();
      const { data, error: err } = await supabase
        .from('restoration_equipment')
        .select('*')
        .eq('job_id', jobId)
        .is('deleted_at', null)
        .order('deployed_at', { ascending: false });

      if (err) throw err;

      setEquipment((data || []).map((row: Record<string, unknown>) => ({
        id: row.id as string,
        jobId: row.job_id as string,
        equipmentType: row.equipment_type as string,
        equipmentName: row.equipment_name as string,
        serialNumber: row.serial_number as string | null,
        areaDeployed: row.area_deployed as string,
        dailyRate: Number(row.daily_rate) || 0,
        deployedAt: row.deployed_at as string,
        removedAt: row.removed_at as string | null,
        status: row.status as string,
      })));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load equipment');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetchEquipment();
  }, [fetchEquipment]);

  const deployEquipment = useCallback(async (input: DeployEquipmentInput) => {
    try {
      const supabase = createClient();
      const { error: err } = await supabase.from('restoration_equipment').insert({
        job_id: input.jobId,
        equipment_type: input.equipmentType,
        equipment_name: input.equipmentName,
        serial_number: input.serialNumber || null,
        area_deployed: input.areaDeployed,
        daily_rate: input.dailyRate || 0,
        deployed_at: new Date().toISOString(),
        status: 'deployed',
      });
      if (err) throw err;
      await fetchEquipment();
      return true;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to deploy equipment');
      return false;
    }
  }, [fetchEquipment]);

  const removeEquipment = useCallback(async (id: string) => {
    try {
      const supabase = createClient();
      const { error: err } = await supabase
        .from('restoration_equipment')
        .update({ removed_at: new Date().toISOString(), status: 'removed' })
        .eq('id', id);
      if (err) throw err;
      await fetchEquipment();
      return true;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to remove equipment');
      return false;
    }
  }, [fetchEquipment]);

  const deployedCount = equipment.filter((e) => e.status === 'deployed').length;

  return {
    equipment,
    loading,
    error,
    refetch: fetchEquipment,
    deployEquipment,
    removeEquipment,
    deployedCount,
  };
}
