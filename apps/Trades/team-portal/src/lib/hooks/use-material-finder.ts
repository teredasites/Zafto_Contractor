'use client';

// DEPTH32: Material Finder Hook (Team Portal)
// Read-only product search for field technicians:
// browse products, search by name/UPC, view favorites.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface SupplierProduct {
  id: string;
  supplierId: string;
  name: string;
  description: string | null;
  brand: string | null;
  modelNumber: string | null;
  sku: string | null;
  upc: string | null;
  trade: string | null;
  materialCategory: string | null;
  price: number | null;
  salePrice: number | null;
  inStock: boolean;
  imageUrl: string | null;
  productUrl: string | null;
  rating: number | null;
  reviewCount: number;
}

export interface ProductFavorite {
  id: string;
  productId: string;
  notes: string | null;
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
// HOOK: useProductBrowse (team portal — read-only search & browse)
// ============================================================================

export function useProductBrowse() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [results, setResults] = useState<SupplierProduct[]>([]);

  const searchProducts = useCallback(async (query: string, trade?: string) => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let q = supabase
        .from('supplier_products')
        .select(
          'id, supplier_id, name, description, brand, model_number, sku, upc, trade, material_category, price, sale_price, in_stock, image_url, product_url, rating, review_count'
        )
        .is('deleted_at', null)
        .textSearch('name', query, { type: 'websearch' });

      if (trade) q = q.eq('trade', trade);

      const { data, error: err } = await q
        .order('rating', { ascending: false })
        .limit(30);

      if (err) throw err;
      const mapped = (data ?? []).map(
        (row: Record<string, unknown>) =>
          snakeToCamel(row) as unknown as SupplierProduct
      );
      setResults(mapped);
      return mapped;
    } catch (e) {
      console.error('Product search failed:', e);
      setError('Could not search products.');
      return [];
    } finally {
      setLoading(false);
    }
  }, []);

  const lookupByUpc = useCallback(async (upc: string) => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('supplier_products')
        .select(
          'id, supplier_id, name, description, brand, model_number, sku, upc, trade, material_category, price, sale_price, in_stock, image_url, product_url, rating, review_count'
        )
        .eq('upc', upc)
        .is('deleted_at', null);
      if (err) throw err;
      const mapped = (data ?? []).map(
        (row: Record<string, unknown>) =>
          snakeToCamel(row) as unknown as SupplierProduct
      );
      setResults(mapped);
      return mapped;
    } catch (e) {
      console.error('UPC lookup failed:', e);
      setError('Could not look up barcode.');
      return [];
    } finally {
      setLoading(false);
    }
  }, []);

  return { results, loading, error, searchProducts, lookupByUpc };
}

// ============================================================================
// HOOK: useTeamFavorites (team portal — read-only favorites list)
// ============================================================================

export function useTeamFavorites() {
  const [favorites, setFavorites] = useState<ProductFavorite[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadFavorites = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('product_favorites')
        .select('id, product_id, notes, created_at')
        .order('created_at', { ascending: false });
      if (err) throw err;
      setFavorites(
        (data ?? []).map(
          (row: Record<string, unknown>) =>
            snakeToCamel(row) as unknown as ProductFavorite
        )
      );
    } catch (e) {
      console.error('Failed to load favorites:', e);
      setError('Could not load favorites.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadFavorites();
  }, [loadFavorites]);

  return { favorites, loading, error, reload: loadFavorites };
}
