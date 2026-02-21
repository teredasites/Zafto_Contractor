'use client';

// DEPTH31: Crowdsourced Material Pricing Hook (Team Portal)
// Read-only access for field technicians: supplier directory browsing,
// price index lookup, and receipt viewing (no CRUD on receipts/alerts).

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface SupplierDirectoryEntry {
  id: string;
  name: string;
  nameNormalized: string;
  supplierType: string;
  tradesServed: string[];
  website: string | null;
  phone: string | null;
  pricingTier: string;
  hasApi: boolean;
  isVerified: boolean;
}

export interface MaterialPriceIndexEntry {
  id: string;
  productNameNormalized: string;
  materialCategory: string;
  trade: string | null;
  brand: string | null;
  unit: string;
  avgPriceNational: number | null;
  priceLow: number | null;
  priceHigh: number | null;
  priceMedian: number | null;
  sampleCount: number;
  trend30dPct: number | null;
}

export interface MaterialReceipt {
  id: string;
  supplierNameRaw: string | null;
  receiptDate: string | null;
  total: number | null;
  processingStatus: string;
  source: string;
  createdAt: string;
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

// ============================================================================
// HOOK: useSupplierLookup (team portal — read-only)
// ============================================================================

export function useSupplierLookup(trade?: string) {
  const [suppliers, setSuppliers] = useState<SupplierDirectoryEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadSuppliers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let query = supabase
        .from('supplier_directory')
        .select('*')
        .order('name');

      if (trade) {
        query = query.contains('trades_served', [trade]);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setSuppliers(
        (data ?? []).map((row: Record<string, unknown>) => snakeToCamel(row) as unknown as SupplierDirectoryEntry)
      );
    } catch (e) {
      console.error('Failed to load suppliers:', e);
      setError('Could not load supplier directory.');
    } finally {
      setLoading(false);
    }
  }, [trade]);

  useEffect(() => {
    loadSuppliers();
  }, [loadSuppliers]);

  return { suppliers, loading, error, reload: loadSuppliers };
}

// ============================================================================
// HOOK: usePriceLookup (team portal — read-only)
// ============================================================================

export function usePriceLookup() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const searchPrices = useCallback(async (query: string) => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('material_price_index')
        .select('*')
        .eq('is_published', true)
        .ilike('product_name_normalized', `%${query}%`)
        .order('sample_count', { ascending: false })
        .limit(20);

      if (err) throw err;
      return (data ?? []).map((row: Record<string, unknown>) =>
        snakeToCamel(row) as unknown as MaterialPriceIndexEntry
      );
    } catch (e) {
      console.error('Failed to search prices:', e);
      setError('Could not search material prices.');
      return [];
    } finally {
      setLoading(false);
    }
  }, []);

  return { loading, error, searchPrices };
}

// ============================================================================
// HOOK: useTeamReceipts (team portal — read-only list)
// ============================================================================

export function useTeamReceipts() {
  const [receipts, setReceipts] = useState<MaterialReceipt[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadReceipts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('material_receipts')
        .select('id, supplier_name_raw, receipt_date, total, processing_status, source, created_at')
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(50);
      if (err) throw err;
      setReceipts(
        (data ?? []).map((row: Record<string, unknown>) => snakeToCamel(row) as unknown as MaterialReceipt)
      );
    } catch (e) {
      console.error('Failed to load receipts:', e);
      setError('Could not load receipts.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadReceipts();
  }, [loadReceipts]);

  return { receipts, loading, error, reload: loadReceipts };
}
