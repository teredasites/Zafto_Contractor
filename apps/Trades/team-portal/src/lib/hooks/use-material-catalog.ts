'use client';

// DEPTH29: Material Catalog Hook (Team Portal)
// Read-only access to material catalog for field technicians.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type MaterialTier = 'economy' | 'standard' | 'premium' | 'elite' | 'luxury';

export interface MaterialCatalogItem {
  id: string;
  companyId: string | null;
  trade: string;
  category: string;
  name: string;
  brand: string | null;
  tier: MaterialTier;
  unit: string;
  costPerUnit: number;
  wasteFactorPct: number;
  laborHoursPerUnit: number;
  description: string | null;
  isSystemDefault: boolean;
}

// ============================================================================
// MAPPER
// ============================================================================

function mapMaterial(row: Record<string, unknown>): MaterialCatalogItem {
  return {
    id: row.id as string,
    companyId: row.company_id as string | null,
    trade: row.trade as string,
    category: row.category as string,
    name: row.name as string,
    brand: row.brand as string | null,
    tier: row.tier as MaterialTier,
    unit: row.unit as string,
    costPerUnit: Number(row.cost_per_unit) || 0,
    wasteFactorPct: Number(row.waste_factor_pct) || 10,
    laborHoursPerUnit: Number(row.labor_hours_per_unit) || 0,
    description: row.description as string | null,
    isSystemDefault: row.company_id === null,
  };
}

// ============================================================================
// HOOK: useMaterialCatalog (Team — read-only)
// ============================================================================

export function useMaterialCatalog(trade?: string) {
  const [materials, setMaterials] = useState<MaterialCatalogItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchMaterials = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let query = supabase
        .from('material_catalog')
        .select('*')
        .is('deleted_at', null)
        .eq('is_disabled', false)
        .order('trade')
        .order('category')
        .order('name');

      if (trade) {
        query = query.eq('trade', trade);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setMaterials((data || []).map(mapMaterial));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load materials');
    } finally {
      setLoading(false);
    }
  }, [trade]);

  useEffect(() => { fetchMaterials(); }, [fetchMaterials]);

  // Get materials by tier
  const getMaterialsByTier = useCallback((tier: MaterialTier) => {
    return materials.filter(m => m.tier === tier);
  }, [materials]);

  // Get unique trades
  const trades = [...new Set(materials.map(m => m.trade))].sort();

  return {
    materials,
    trades,
    loading,
    error,
    refetch: fetchMaterials,
    getMaterialsByTier,
  };
}
