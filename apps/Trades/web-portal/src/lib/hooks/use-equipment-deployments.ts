'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { createClient } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type EquipmentType =
  | 'dehumidifier' | 'air_mover' | 'air_scrubber' | 'heater'
  | 'moisture_meter' | 'thermal_camera' | 'hydroxyl_generator'
  | 'negative_air_machine' | 'injectidry' | 'other';

export type DeploymentStatus = 'deployed' | 'removed' | 'maintenance' | 'lost';

export interface EquipmentDeploymentData {
  id: string;
  companyId: string;
  jobId: string;
  tpaAssignmentId: string | null;
  equipmentInventoryId: string | null;
  equipmentType: EquipmentType;
  make: string | null;
  model: string | null;
  serialNumber: string | null;
  assetTag: string | null;
  areaDeployed: string;
  roomName: string | null;
  placementLocation: string | null;
  ahamPpd: number | null;
  ahamCfm: number | null;
  deployedAt: string;
  removedAt: string | null;
  dailyRate: number;
  status: DeploymentStatus;
  calculatedByFormula: boolean;
  notes: string | null;
  createdAt: string;
  // Computed
  billableDays: number;
  billableAmount: number;
}

export interface EquipmentCalculationData {
  id: string;
  jobId: string;
  roomName: string;
  roomLengthFt: number;
  roomWidthFt: number;
  roomHeightFt: number;
  floorSqft: number;
  wallLinearFt: number;
  cubicFt: number;
  waterClass: number;
  dehuUnitsRequired: number;
  amUnitsRequired: number;
  scrubberUnitsRequired: number;
  actualDehuPlaced: number;
  actualAmPlaced: number;
  actualScrubberPlaced: number;
  varianceNotes: string | null;
  createdAt: string;
}

export interface DeploymentSummary {
  totalDeployed: number;
  totalRemoved: number;
  dehumidifiers: number;
  airMovers: number;
  airScrubbers: number;
  heaters: number;
  other: number;
  dailyRateTotal: number;
  totalBillableDays: number;
  totalBillableAmount: number;
}

// ============================================================================
// MAPPERS
// ============================================================================

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapDeployment(row: any): EquipmentDeploymentData {
  const deployedAt = row.deployed_at;
  const removedAt = row.removed_at;
  const dailyRate = parseFloat(row.daily_rate) || 0;

  // Calculate billable days
  const startDate = new Date(deployedAt);
  const endDate = removedAt ? new Date(removedAt) : new Date();
  const diffMs = endDate.getTime() - startDate.getTime();
  const billableDays = Math.max(1, Math.ceil(diffMs / (1000 * 60 * 60 * 24)));

  return {
    id: row.id,
    companyId: row.company_id,
    jobId: row.job_id,
    tpaAssignmentId: row.tpa_assignment_id ?? null,
    equipmentInventoryId: row.equipment_inventory_id ?? null,
    equipmentType: row.equipment_type,
    make: row.make ?? null,
    model: row.model ?? null,
    serialNumber: row.serial_number ?? null,
    assetTag: row.asset_tag ?? null,
    areaDeployed: row.area_deployed,
    roomName: row.room_name ?? null,
    placementLocation: row.placement_location ?? null,
    ahamPpd: row.aham_ppd != null ? parseFloat(row.aham_ppd) : null,
    ahamCfm: row.aham_cfm != null ? parseFloat(row.aham_cfm) : null,
    deployedAt,
    removedAt: removedAt ?? null,
    dailyRate,
    status: row.status,
    calculatedByFormula: row.calculated_by_formula ?? false,
    notes: row.notes ?? null,
    createdAt: row.created_at,
    billableDays,
    billableAmount: billableDays * dailyRate,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapCalculation(row: any): EquipmentCalculationData {
  return {
    id: row.id,
    jobId: row.job_id,
    roomName: row.room_name,
    roomLengthFt: parseFloat(row.room_length_ft) || 0,
    roomWidthFt: parseFloat(row.room_width_ft) || 0,
    roomHeightFt: parseFloat(row.room_height_ft) || 0,
    floorSqft: parseFloat(row.floor_sqft) || 0,
    wallLinearFt: parseFloat(row.wall_linear_ft) || 0,
    cubicFt: parseFloat(row.cubic_ft) || 0,
    waterClass: row.water_class,
    dehuUnitsRequired: row.dehu_units_required ?? 0,
    amUnitsRequired: row.am_units_required ?? 0,
    scrubberUnitsRequired: row.scrubber_units_required ?? 0,
    actualDehuPlaced: row.actual_dehu_placed ?? 0,
    actualAmPlaced: row.actual_am_placed ?? 0,
    actualScrubberPlaced: row.actual_scrubber_placed ?? 0,
    varianceNotes: row.variance_notes ?? null,
    createdAt: row.created_at,
  };
}

// ============================================================================
// HOOKS
// ============================================================================

export function useEquipmentDeployments(jobId: string | null) {
  const [deployments, setDeployments] = useState<EquipmentDeploymentData[]>([]);
  const [calculations, setCalculations] = useState<EquipmentCalculationData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!jobId) { setDeployments([]); setCalculations([]); setLoading(false); return; }
    try {
      setLoading(true);
      setError(null);
      const supabase = createClient();
      const [deplRes, calcRes] = await Promise.all([
        supabase
          .from('restoration_equipment')
          .select('*')
          .eq('job_id', jobId)
          .order('deployed_at', { ascending: false }),
        supabase
          .from('equipment_calculations')
          .select('*')
          .eq('job_id', jobId)
          .order('room_name'),
      ]);

      if (deplRes.error) throw deplRes.error;
      if (calcRes.error) throw calcRes.error;

      setDeployments((deplRes.data || []).map(mapDeployment));
      setCalculations((calcRes.data || []).map(mapCalculation));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load equipment data');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetch();
    if (!jobId) return;
    const supabase = createClient();
    const channel = supabase
      .channel(`equip-deploy-${jobId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'restoration_equipment', filter: `job_id=eq.${jobId}` }, () => { fetch(); })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'equipment_calculations', filter: `job_id=eq.${jobId}` }, () => { fetch(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetch, jobId]);

  const summary = useMemo<DeploymentSummary>(() => {
    const deployed = deployments.filter(d => d.status === 'deployed');
    const removed = deployments.filter(d => d.status === 'removed');
    return {
      totalDeployed: deployed.length,
      totalRemoved: removed.length,
      dehumidifiers: deployed.filter(d => d.equipmentType === 'dehumidifier').length,
      airMovers: deployed.filter(d => d.equipmentType === 'air_mover').length,
      airScrubbers: deployed.filter(d => d.equipmentType === 'air_scrubber').length,
      heaters: deployed.filter(d => d.equipmentType === 'heater').length,
      other: deployed.filter(d => !['dehumidifier', 'air_mover', 'air_scrubber', 'heater'].includes(d.equipmentType)).length,
      dailyRateTotal: deployed.reduce((sum, d) => sum + d.dailyRate, 0),
      totalBillableDays: deployments.reduce((sum, d) => sum + d.billableDays, 0),
      totalBillableAmount: deployments.reduce((sum, d) => sum + d.billableAmount, 0),
    };
  }, [deployments]);

  const deployEquipment = async (input: {
    equipmentType: EquipmentType;
    areaDeployed: string;
    roomName?: string;
    placementLocation?: string;
    dailyRate: number;
    make?: string;
    model?: string;
    serialNumber?: string;
    assetTag?: string;
    ahamPpd?: number;
    ahamCfm?: number;
    equipmentInventoryId?: string;
    tpaAssignmentId?: string;
  }): Promise<string> => {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data, error: err } = await supabase
      .from('restoration_equipment')
      .insert({
        company_id: companyId,
        job_id: jobId,
        tpa_assignment_id: input.tpaAssignmentId ?? null,
        equipment_inventory_id: input.equipmentInventoryId ?? null,
        equipment_type: input.equipmentType,
        area_deployed: input.areaDeployed,
        room_name: input.roomName ?? null,
        placement_location: input.placementLocation ?? null,
        daily_rate: input.dailyRate,
        make: input.make ?? null,
        model: input.model ?? null,
        serial_number: input.serialNumber ?? null,
        asset_tag: input.assetTag ?? null,
        aham_ppd: input.ahamPpd ?? null,
        aham_cfm: input.ahamCfm ?? null,
        deployed_at: new Date().toISOString(),
        status: 'deployed',
      })
      .select('id')
      .single();

    if (err) throw err;

    // If linked to inventory, update inventory status
    if (input.equipmentInventoryId) {
      await supabase
        .from('equipment_inventory')
        .update({
          status: 'deployed',
          current_job_id: jobId,
          current_deployment_id: data.id,
        })
        .eq('id', input.equipmentInventoryId);
    }

    return data.id;
  };

  const removeEquipment = async (deploymentId: string): Promise<void> => {
    const supabase = createClient();
    const now = new Date().toISOString();

    const deployment = deployments.find(d => d.id === deploymentId);

    const { error: err } = await supabase
      .from('restoration_equipment')
      .update({ status: 'removed', removed_at: now })
      .eq('id', deploymentId);

    if (err) throw err;

    // If linked to inventory, mark as available
    if (deployment?.equipmentInventoryId) {
      await supabase
        .from('equipment_inventory')
        .update({
          status: 'available',
          current_job_id: null,
          current_deployment_id: null,
        })
        .eq('id', deployment.equipmentInventoryId);
    }
  };

  return { deployments, calculations, summary, loading, error, deployEquipment, removeEquipment, refetch: fetch };
}
