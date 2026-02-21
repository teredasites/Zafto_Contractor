'use client';

// DEPTH29: Material Catalog Hook
// Manages material catalog (system defaults + company overrides),
// tier-based material swapping, and supplier price comparisons.

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
  model: string | null;
  sku: string | null;
  tier: MaterialTier;
  unit: string;
  costPerUnit: number;
  wasteFactorPct: number;
  laborHoursPerUnit: number;
  laborDifficultyMultiplier: number;
  warrantyYears: number | null;
  description: string | null;
  specsJson: Record<string, unknown>;
  photoUrl: string | null;
  supplierUrls: Array<{ supplier: string; url: string; price: number }>;
  isFavorite: boolean;
  isDisabled: boolean;
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
    model: row.model as string | null,
    sku: row.sku as string | null,
    tier: row.tier as MaterialTier,
    unit: row.unit as string,
    costPerUnit: Number(row.cost_per_unit) || 0,
    wasteFactorPct: Number(row.waste_factor_pct) || 10,
    laborHoursPerUnit: Number(row.labor_hours_per_unit) || 0,
    laborDifficultyMultiplier: Number(row.labor_difficulty_multiplier) || 1.0,
    warrantyYears: row.warranty_years != null ? Number(row.warranty_years) : null,
    description: row.description as string | null,
    specsJson: (row.specs_json as Record<string, unknown>) || {},
    photoUrl: row.photo_url as string | null,
    supplierUrls: (row.supplier_urls as Array<{ supplier: string; url: string; price: number }>) || [],
    isFavorite: row.is_favorite === true,
    isDisabled: row.is_disabled === true,
    isSystemDefault: row.company_id === null,
  };
}

// ============================================================================
// HOOK: useMaterialCatalog
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
        .order('tier')
        .order('name');

      if (trade) {
        query = query.eq('trade', trade);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setMaterials((data || []).map(mapMaterial));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load material catalog');
    } finally {
      setLoading(false);
    }
  }, [trade]);

  useEffect(() => { fetchMaterials(); }, [fetchMaterials]);

  // Get materials by tier
  const getMaterialsByTier = useCallback((tier: MaterialTier) => {
    return materials.filter(m => m.tier === tier);
  }, [materials]);

  // Get tier equivalents for a specific material
  const getTierEquivalents = useCallback((materialId: string) => {
    const material = materials.find(m => m.id === materialId);
    if (!material) return [];
    return materials.filter(
      m => m.trade === material.trade && m.category === material.category && m.id !== materialId
    );
  }, [materials]);

  // Get unique trades in catalog
  const trades = [...new Set(materials.map(m => m.trade))].sort();

  // Get unique categories for a trade
  const getCategories = useCallback((t: string) => {
    return [...new Set(materials.filter(m => m.trade === t).map(m => m.category))].sort();
  }, [materials]);

  // Add company-specific material
  const addMaterial = useCallback(async (input: {
    trade: string;
    category: string;
    name: string;
    brand?: string;
    tier: MaterialTier;
    unit: string;
    costPerUnit: number;
    wasteFactorPct?: number;
    laborHoursPerUnit?: number;
    warrantyYears?: number;
    description?: string;
  }) => {
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const companyId = session.user.app_metadata?.company_id;
      if (!companyId) throw new Error('No company context');

      const { error: err } = await supabase.from('material_catalog').insert({
        company_id: companyId,
        trade: input.trade,
        category: input.category,
        name: input.name,
        brand: input.brand || null,
        tier: input.tier,
        unit: input.unit,
        cost_per_unit: input.costPerUnit,
        waste_factor_pct: input.wasteFactorPct ?? 10,
        labor_hours_per_unit: input.laborHoursPerUnit ?? 0,
        warranty_years: input.warrantyYears ?? null,
        description: input.description || null,
      });

      if (err) throw err;
      await fetchMaterials();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to add material');
    }
  }, [fetchMaterials]);

  // Update a company material
  const updateMaterial = useCallback(async (id: string, updates: Partial<{
    name: string;
    brand: string;
    tier: MaterialTier;
    costPerUnit: number;
    wasteFactorPct: number;
    laborHoursPerUnit: number;
    warrantyYears: number;
    description: string;
    isFavorite: boolean;
    isDisabled: boolean;
  }>) => {
    try {
      const supabase = getSupabase();
      const dbUpdates: Record<string, unknown> = {};
      if (updates.name !== undefined) dbUpdates.name = updates.name;
      if (updates.brand !== undefined) dbUpdates.brand = updates.brand;
      if (updates.tier !== undefined) dbUpdates.tier = updates.tier;
      if (updates.costPerUnit !== undefined) dbUpdates.cost_per_unit = updates.costPerUnit;
      if (updates.wasteFactorPct !== undefined) dbUpdates.waste_factor_pct = updates.wasteFactorPct;
      if (updates.laborHoursPerUnit !== undefined) dbUpdates.labor_hours_per_unit = updates.laborHoursPerUnit;
      if (updates.warrantyYears !== undefined) dbUpdates.warranty_years = updates.warrantyYears;
      if (updates.description !== undefined) dbUpdates.description = updates.description;
      if (updates.isFavorite !== undefined) dbUpdates.is_favorite = updates.isFavorite;
      if (updates.isDisabled !== undefined) dbUpdates.is_disabled = updates.isDisabled;

      const { error: err } = await supabase
        .from('material_catalog')
        .update(dbUpdates)
        .eq('id', id);

      if (err) throw err;
      await fetchMaterials();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to update material');
    }
  }, [fetchMaterials]);

  // Soft delete
  const deleteMaterial = useCallback(async (id: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('material_catalog')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);

      if (err) throw err;
      await fetchMaterials();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to delete material');
    }
  }, [fetchMaterials]);

  return {
    materials,
    trades,
    loading,
    error,
    refetch: fetchMaterials,
    getMaterialsByTier,
    getTierEquivalents,
    getCategories,
    addMaterial,
    updateMaterial,
    deleteMaterial,
  };
}
