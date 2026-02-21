'use client';

// DEPTH30: Recon-to-Estimate Pipeline Hook
// Connects property recon data to the estimate engine.
// Manages measurement mappings, material recommendations,
// estimate bundles, cross-trade dependencies, and auto-generation.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface ReconEstimateMapping {
  id: string;
  companyId: string | null;
  trade: string;
  measurementType: string;
  lineDescription: string;
  materialCategory: string | null;
  defaultMaterialTier: string;
  unitCode: string;
  quantityFormula: string;
  wasteFactorPct: number;
  roundUpTo: number | null;
  laborTaskName: string | null;
  sortOrder: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export type RecommendationSeverity = 'info' | 'warning' | 'critical';

export interface ReconMaterialRecommendation {
  id: string;
  companyId: string | null;
  trade: string;
  conditionField: string;
  conditionOperator: string;
  conditionValue: string;
  recommendationText: string;
  suggestedMaterialCategory: string | null;
  suggestedMaterialTier: string | null;
  addLineDescription: string | null;
  addLineUnit: string | null;
  addLineQuantityFormula: string | null;
  severity: RecommendationSeverity;
  isCodeRequired: boolean;
  sortOrder: number;
  isActive: boolean;
}

export interface EstimateBundle {
  id: string;
  companyId: string;
  customerId: string | null;
  propertyAddress: string | null;
  scanId: string | null;
  title: string | null;
  bundleDiscountPct: number;
  combinedTotal: number;
  discountedTotal: number;
  notes: string | null;
  dependencyWarnings: Array<{ primaryTrade: string; dependentTrade: string; warning: string; severity: string }>;
  createdBy: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface CrossTradeDependency {
  id: string;
  primaryTrade: string;
  dependentTrade: string;
  dependencyType: 'before' | 'after' | 'concurrent';
  warningText: string;
  severity: string;
  sortOrder: number;
}

export type ConfidenceLevel = 'manual' | 'low' | 'medium' | 'high';

export interface GeneratedLineItem {
  description: string;
  materialCategory: string | null;
  unitCode: string;
  quantity: number;
  wasteFactorPct: number;
  laborTaskName: string | null;
  confidenceLevel: ConfidenceLevel;
  measurementSource: string;
  measurementValue: number;
}

export interface PipelineRecommendation {
  recommendation: ReconMaterialRecommendation;
  matched: boolean;
  propertyValue: unknown;
}

export interface PipelineResult {
  lineItems: GeneratedLineItem[];
  recommendations: PipelineRecommendation[];
  dependencyWarnings: CrossTradeDependency[];
  overallConfidence: ConfidenceLevel;
  confidenceDetail: Record<string, ConfidenceLevel>;
}

// ============================================================================
// HELPERS
// ============================================================================

function snakeToCamel(row: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(row)) {
    const camelKey = key.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
    result[camelKey] = value;
  }
  return result;
}

/** Evaluate a simple quantity formula: 'measurement', 'measurement * X', 'measurement / X', or a constant */
function evaluateFormula(formula: string, measurementValue: number): number {
  const f = formula.trim().toLowerCase();
  if (f === 'measurement') return measurementValue;

  const constant = parseFloat(f);
  if (!isNaN(constant)) return constant;

  if (f.startsWith('measurement')) {
    const rest = f.substring('measurement'.length).trim();
    if (rest.startsWith('*')) {
      const multiplier = parseFloat(rest.substring(1).trim());
      return isNaN(multiplier) ? measurementValue : measurementValue * multiplier;
    }
    if (rest.startsWith('/')) {
      const divisor = parseFloat(rest.substring(1).trim());
      return isNaN(divisor) || divisor === 0 ? 0 : measurementValue / divisor;
    }
  }

  return measurementValue;
}

/** Calculate final quantity with waste and rounding */
function calculateQuantity(formula: string, measurementValue: number, wastePct: number, roundUpTo: number | null): number {
  let qty = evaluateFormula(formula, measurementValue);
  if (wastePct > 0) qty *= (1 + wastePct / 100);
  if (roundUpTo && roundUpTo > 0) qty = Math.ceil(qty / roundUpTo) * roundUpTo;
  return qty;
}

/** Evaluate a condition against a property value */
function evaluateCondition(operator: string, propertyValue: unknown, conditionValue: string): boolean {
  if (propertyValue == null || propertyValue === undefined) return false;

  const pvStr = String(propertyValue).toLowerCase();
  const cvStr = conditionValue.toLowerCase();

  switch (operator) {
    case 'eq': return pvStr === cvStr;
    case 'ne': return pvStr !== cvStr;
    case 'gt': return parseFloat(pvStr) > parseFloat(cvStr);
    case 'lt': return parseFloat(pvStr) < parseFloat(cvStr);
    case 'gte': return parseFloat(pvStr) >= parseFloat(cvStr);
    case 'lte': return parseFloat(pvStr) <= parseFloat(cvStr);
    case 'in': {
      const allowed = cvStr.split(',').map(s => s.trim());
      return allowed.includes(pvStr);
    }
    case 'contains': return pvStr.includes(cvStr);
    default: return false;
  }
}

// ============================================================================
// HOOK: useReconEstimatePipeline
// ============================================================================

export function useReconEstimatePipeline(trade?: string) {
  const [mappings, setMappings] = useState<ReconEstimateMapping[]>([]);
  const [recommendations, setRecommendations] = useState<ReconMaterialRecommendation[]>([]);
  const [bundles, setBundles] = useState<EstimateBundle[]>([]);
  const [dependencies, setDependencies] = useState<CrossTradeDependency[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // ── Load mappings for trade ──
  const loadMappings = useCallback(async (t: string) => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('recon_estimate_mappings')
        .select('*')
        .eq('trade', t)
        .eq('is_active', true)
        .is('deleted_at', null)
        .order('sort_order');

      if (err) throw err;
      setMappings((data ?? []).map(row => snakeToCamel(row) as unknown as ReconEstimateMapping));
    } catch (e) {
      console.error('Failed to load mappings:', e);
      setError('Could not load estimate mapping rules.');
    }
  }, []);

  // ── Load recommendations for trade ──
  const loadRecommendations = useCallback(async (t: string) => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('recon_material_recommendations')
        .select('*')
        .or(`trade.eq.${t},trade.eq.general`)
        .eq('is_active', true)
        .is('deleted_at', null)
        .order('sort_order');

      if (err) throw err;
      setRecommendations((data ?? []).map(row => snakeToCamel(row) as unknown as ReconMaterialRecommendation));
    } catch (e) {
      console.error('Failed to load recommendations:', e);
    }
  }, []);

  // ── Load bundles ──
  const loadBundles = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('estimate_bundles')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setBundles((data ?? []).map(row => snakeToCamel(row) as unknown as EstimateBundle));
    } catch (e) {
      console.error('Failed to load bundles:', e);
    }
  }, []);

  // ── Load cross-trade dependencies ──
  const loadDependencies = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('cross_trade_dependencies')
        .select('*')
        .order('sort_order');

      if (err) throw err;
      setDependencies((data ?? []).map(row => snakeToCamel(row) as unknown as CrossTradeDependency));
    } catch (e) {
      console.error('Failed to load dependencies:', e);
    }
  }, []);

  // ── Initial load ──
  useEffect(() => {
    const load = async () => {
      setLoading(true);
      setError(null);
      const promises: Promise<void>[] = [loadBundles(), loadDependencies()];
      if (trade) {
        promises.push(loadMappings(trade), loadRecommendations(trade));
      }
      await Promise.all(promises);
      setLoading(false);
    };
    load();
  }, [trade, loadMappings, loadRecommendations, loadBundles, loadDependencies]);

  // ── Generate estimate line items from recon measurements ──
  const generateFromRecon = useCallback((
    measurements: Record<string, number>,
    propertyData: Record<string, unknown>,
    scanConfidence: Record<string, ConfidenceLevel>,
  ): PipelineResult => {
    // 1. Generate line items from mappings + measurements
    const lineItems: GeneratedLineItem[] = [];
    const confidenceDetail: Record<string, ConfidenceLevel> = {};

    for (const mapping of mappings) {
      const measValue = measurements[mapping.measurementType];
      if (measValue == null || measValue === 0) continue;

      const quantity = calculateQuantity(
        mapping.quantityFormula,
        measValue,
        mapping.wasteFactorPct,
        mapping.roundUpTo,
      );

      const conf = scanConfidence[mapping.measurementType] ?? 'low';
      confidenceDetail[mapping.measurementType] = conf;

      lineItems.push({
        description: mapping.lineDescription,
        materialCategory: mapping.materialCategory,
        unitCode: mapping.unitCode,
        quantity: Math.round(quantity * 100) / 100,
        wasteFactorPct: mapping.wasteFactorPct,
        laborTaskName: mapping.laborTaskName,
        confidenceLevel: conf,
        measurementSource: mapping.measurementType,
        measurementValue: measValue,
      });
    }

    // 2. Evaluate material recommendations against property data
    const recResults: PipelineRecommendation[] = recommendations.map(rec => {
      const propVal = propertyData[rec.conditionField];
      const matched = evaluateCondition(rec.conditionOperator, propVal, rec.conditionValue);
      return { recommendation: rec, matched, propertyValue: propVal };
    });

    // 3. Add auto-generated line items from matched recommendations
    for (const r of recResults) {
      if (r.matched && r.recommendation.addLineDescription) {
        const formulaVal = r.recommendation.addLineQuantityFormula
          ? evaluateFormula(r.recommendation.addLineQuantityFormula, 1)
          : 1;
        lineItems.push({
          description: r.recommendation.addLineDescription,
          materialCategory: r.recommendation.suggestedMaterialCategory ?? null,
          unitCode: r.recommendation.addLineUnit ?? 'EA',
          quantity: formulaVal,
          wasteFactorPct: 0,
          laborTaskName: null,
          confidenceLevel: 'medium',
          measurementSource: `condition:${r.recommendation.conditionField}`,
          measurementValue: 0,
        });
      }
    }

    // 4. Find relevant cross-trade dependency warnings
    const relevantDeps = dependencies.filter(d =>
      d.primaryTrade === trade || d.dependentTrade === trade
    );

    // 5. Calculate overall confidence
    const confValues = Object.values(confidenceDetail);
    let overallConfidence: ConfidenceLevel = 'manual';
    if (confValues.length > 0) {
      const hasLow = confValues.includes('low');
      const hasMedium = confValues.includes('medium');
      if (hasLow) overallConfidence = 'low';
      else if (hasMedium) overallConfidence = 'medium';
      else overallConfidence = 'high';
    }

    return {
      lineItems,
      recommendations: recResults,
      dependencyWarnings: relevantDeps,
      overallConfidence,
      confidenceDetail,
    };
  }, [mappings, recommendations, dependencies, trade]);

  // ── Bundle CRUD ──
  const createBundle = useCallback(async (data: {
    customerId?: string;
    propertyAddress?: string;
    scanId?: string;
    title?: string;
    bundleDiscountPct?: number;
    notes?: string;
  }) => {
    try {
      const supabase = getSupabase();
      const { data: result, error: err } = await supabase
        .from('estimate_bundles')
        .insert({
          customer_id: data.customerId ?? null,
          property_address: data.propertyAddress ?? null,
          scan_id: data.scanId ?? null,
          title: data.title ?? null,
          bundle_discount_pct: data.bundleDiscountPct ?? 0,
          notes: data.notes ?? null,
        })
        .select()
        .single();

      if (err) throw err;
      await loadBundles();
      return snakeToCamel(result) as unknown as EstimateBundle;
    } catch (e) {
      console.error('Failed to create bundle:', e);
      setError('Could not create estimate bundle.');
      return null;
    }
  }, [loadBundles]);

  const updateBundle = useCallback(async (id: string, updates: {
    title?: string;
    bundleDiscountPct?: number;
    combinedTotal?: number;
    discountedTotal?: number;
    notes?: string;
    dependencyWarnings?: unknown[];
  }) => {
    try {
      const supabase = getSupabase();
      const dbUpdates: Record<string, unknown> = {};
      if (updates.title !== undefined) dbUpdates.title = updates.title;
      if (updates.bundleDiscountPct !== undefined) dbUpdates.bundle_discount_pct = updates.bundleDiscountPct;
      if (updates.combinedTotal !== undefined) dbUpdates.combined_total = updates.combinedTotal;
      if (updates.discountedTotal !== undefined) dbUpdates.discounted_total = updates.discountedTotal;
      if (updates.notes !== undefined) dbUpdates.notes = updates.notes;
      if (updates.dependencyWarnings !== undefined) dbUpdates.dependency_warnings = updates.dependencyWarnings;

      const { error: err } = await supabase
        .from('estimate_bundles')
        .update(dbUpdates)
        .eq('id', id);

      if (err) throw err;
      await loadBundles();
    } catch (e) {
      console.error('Failed to update bundle:', e);
      setError('Could not update estimate bundle.');
    }
  }, [loadBundles]);

  const deleteBundle = useCallback(async (id: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('estimate_bundles')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);

      if (err) throw err;
      await loadBundles();
    } catch (e) {
      console.error('Failed to delete bundle:', e);
      setError('Could not remove estimate bundle.');
    }
  }, [loadBundles]);

  // ── Mapping CRUD (company overrides) ──
  const addMapping = useCallback(async (data: Partial<ReconEstimateMapping>) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('recon_estimate_mappings')
        .insert({
          trade: data.trade,
          measurement_type: data.measurementType,
          line_description: data.lineDescription,
          material_category: data.materialCategory ?? null,
          default_material_tier: data.defaultMaterialTier ?? 'standard',
          unit_code: data.unitCode ?? 'SF',
          quantity_formula: data.quantityFormula ?? 'measurement',
          waste_factor_pct: data.wasteFactorPct ?? 0,
          round_up_to: data.roundUpTo ?? null,
          labor_task_name: data.laborTaskName ?? null,
          sort_order: data.sortOrder ?? 0,
        });

      if (err) throw err;
      if (trade) await loadMappings(trade);
    } catch (e) {
      console.error('Failed to add mapping:', e);
      setError('Could not add mapping rule.');
    }
  }, [trade, loadMappings]);

  const deleteMapping = useCallback(async (id: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('recon_estimate_mappings')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);

      if (err) throw err;
      if (trade) await loadMappings(trade);
    } catch (e) {
      console.error('Failed to delete mapping:', e);
      setError('Could not remove mapping rule.');
    }
  }, [trade, loadMappings]);

  return {
    // Data
    mappings,
    recommendations,
    bundles,
    dependencies,
    loading,
    error,
    // Pipeline
    generateFromRecon,
    // Bundle CRUD
    createBundle,
    updateBundle,
    deleteBundle,
    // Mapping CRUD
    addMapping,
    deleteMapping,
    // Reload
    reload: () => {
      const promises: Promise<void>[] = [loadBundles(), loadDependencies()];
      if (trade) {
        promises.push(loadMappings(trade), loadRecommendations(trade));
      }
      return Promise.all(promises);
    },
  };
}
