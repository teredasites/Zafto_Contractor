'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// ────────────────────────────────────────────────────────
// Types — read-only client view of home_equipment + warranties
// ────────────────────────────────────────────────────────

export type WarrantyType = 'manufacturer' | 'extended' | 'labor' | 'parts_labor' | 'home_warranty';

export interface EquipmentWarranty {
  id: string;
  name: string;
  manufacturer: string | null;
  modelNumber: string | null;
  serialNumber: string | null;
  category: string | null;
  warrantyStartDate: string | null;
  warrantyEndDate: string | null;
  warrantyType: WarrantyType | null;
  warrantyProvider: string | null;
  recallStatus: string | null;
  // Computed
  daysRemaining: number | null;
  status: 'active' | 'expiring_soon' | 'expired' | 'no_warranty';
}

export interface WarrantyClaim {
  id: string;
  equipmentId: string;
  claimDate: string;
  claimReason: string;
  claimStatus: string;
  amountClaimed: number | null;
  amountApproved: number | null;
  resolutionNotes: string | null;
  equipmentName: string | null;
}

function computeStatus(endDate: string | null): { daysRemaining: number | null; status: EquipmentWarranty['status'] } {
  if (!endDate) return { daysRemaining: null, status: 'no_warranty' };
  const days = Math.ceil((new Date(endDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
  if (days < 0) return { daysRemaining: days, status: 'expired' };
  if (days <= 90) return { daysRemaining: days, status: 'expiring_soon' };
  return { daysRemaining: days, status: 'active' };
}

function mapEquipment(row: Record<string, unknown>): EquipmentWarranty {
  const endDate = row.warranty_end_date as string | null;
  const computed = computeStatus(endDate);
  return {
    id: row.id as string,
    name: (row.name as string) || 'Equipment',
    manufacturer: row.manufacturer as string | null,
    modelNumber: row.model_number as string | null,
    serialNumber: row.serial_number as string | null,
    category: row.category as string | null,
    warrantyStartDate: row.warranty_start_date as string | null,
    warrantyEndDate: endDate,
    warrantyType: row.warranty_type as WarrantyType | null,
    warrantyProvider: row.warranty_provider as string | null,
    recallStatus: row.recall_status as string | null,
    ...computed,
  };
}

function mapClaim(row: Record<string, unknown>): WarrantyClaim {
  const eq = row.home_equipment as Record<string, unknown> | null;
  return {
    id: row.id as string,
    equipmentId: row.equipment_id as string,
    claimDate: row.claim_date as string,
    claimReason: row.claim_reason as string,
    claimStatus: (row.claim_status as string) || 'submitted',
    amountClaimed: row.amount_claimed as number | null,
    amountApproved: row.amount_approved as number | null,
    resolutionNotes: row.resolution_notes as string | null,
    equipmentName: eq?.name as string | null ?? null,
  };
}

// ────────────────────────────────────────────────────────
// Hook: useWarrantyPortfolio (read-only for homeowners)
// ────────────────────────────────────────────────────────

export function useWarrantyPortfolio() {
  const { profile } = useAuth();
  const [equipment, setEquipment] = useState<EquipmentWarranty[]>([]);
  const [claims, setClaims] = useState<WarrantyClaim[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const customerId = profile?.customerId;

  const fetchData = useCallback(async () => {
    if (!customerId) return;
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const [eqRes, claimRes] = await Promise.all([
        supabase
          .from('home_equipment')
          .select('id, name, manufacturer, model_number, serial_number, category, warranty_start_date, warranty_end_date, warranty_type, warranty_provider, recall_status')
          .eq('customer_id', customerId)
          .is('deleted_at', null)
          .order('warranty_end_date', { ascending: true }),
        supabase
          .from('warranty_claims')
          .select('*, home_equipment(name)')
          .eq('customer_id', customerId)
          .is('deleted_at', null)
          .order('claim_date', { ascending: false }),
      ]);

      if (eqRes.error) throw eqRes.error;
      setEquipment((eqRes.data || []).map((r: Record<string, unknown>) => mapEquipment(r)));

      // Claims table might not have customer_id — filter by equipment IDs
      if (!claimRes.error && claimRes.data) {
        setClaims((claimRes.data || []).map((r: Record<string, unknown>) => mapClaim(r)));
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load warranty data');
    } finally {
      setLoading(false);
    }
  }, [customerId]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const activeCount = useMemo(() => equipment.filter(e => e.status === 'active').length, [equipment]);
  const expiringCount = useMemo(() => equipment.filter(e => e.status === 'expiring_soon').length, [equipment]);
  const recallCount = useMemo(() => equipment.filter(e => e.recallStatus === 'active').length, [equipment]);

  return {
    equipment,
    claims,
    loading,
    error,
    activeCount,
    expiringCount,
    recallCount,
    refresh: fetchData,
  };
}
