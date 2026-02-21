'use client';

// DEPTH32: Material Finder Hook (CRM Portal)
// Supplier product search, price comparison, affiliate click tracking,
// product favorites, recently viewed products.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface SupplierProduct {
  id: string;
  supplierId: string;
  externalProductId: string | null;
  name: string;
  description: string | null;
  brand: string | null;
  modelNumber: string | null;
  sku: string | null;
  upc: string | null;
  categoryPath: string | null;
  trade: string | null;
  materialCategory: string | null;
  price: number | null;
  salePrice: number | null;
  saleEndDate: string | null;
  inStock: boolean;
  imageUrl: string | null;
  productUrl: string | null;
  affiliateNetwork: string | null;
  commissionRate: number | null;
  lastFeedUpdate: string | null;
  priceHistory: Record<string, unknown>[];
  specs: Record<string, unknown>;
  rating: number | null;
  reviewCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface AffiliateClick {
  id: string;
  companyId: string;
  userId: string;
  productId: string | null;
  supplierId: string | null;
  productName: string | null;
  supplierName: string | null;
  priceAtClick: number | null;
  affiliateNetwork: string | null;
  clickUrl: string | null;
  converted: boolean;
  conversionAmount: number | null;
  commissionEarned: number | null;
  createdAt: string;
}

export interface ProductFavorite {
  id: string;
  companyId: string;
  userId: string;
  productId: string;
  notes: string | null;
  createdAt: string;
}

export interface ProductView {
  id: string;
  companyId: string;
  userId: string;
  productId: string;
  viewedAt: string;
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
// HOOK: useProductSearch — full-text + filtered product search
// ============================================================================

export function useProductSearch() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [results, setResults] = useState<SupplierProduct[]>([]);

  const searchProducts = useCallback(
    async (
      query: string,
      filters?: {
        trade?: string;
        materialCategory?: string;
        supplierId?: string;
        minPrice?: number;
        maxPrice?: number;
        inStockOnly?: boolean;
        limit?: number;
      }
    ) => {
      setLoading(true);
      setError(null);
      try {
        const supabase = getSupabase();
        let q = supabase
          .from('supplier_products')
          .select('*')
          .is('deleted_at', null)
          .textSearch('name', query, { type: 'websearch' });

        if (filters?.trade) q = q.eq('trade', filters.trade);
        if (filters?.materialCategory)
          q = q.eq('material_category', filters.materialCategory);
        if (filters?.supplierId) q = q.eq('supplier_id', filters.supplierId);
        if (filters?.minPrice != null) q = q.gte('price', filters.minPrice);
        if (filters?.maxPrice != null) q = q.lte('price', filters.maxPrice);
        if (filters?.inStockOnly) q = q.eq('in_stock', true);

        const { data, error: err } = await q
          .order('rating', { ascending: false })
          .limit(filters?.limit ?? 30);

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
    },
    []
  );

  const browseProducts = useCallback(
    async (filters: {
      trade?: string;
      materialCategory?: string;
      supplierId?: string;
      brand?: string;
      inStockOnly?: boolean;
      limit?: number;
    }) => {
      setLoading(true);
      setError(null);
      try {
        const supabase = getSupabase();
        let q = supabase
          .from('supplier_products')
          .select('*')
          .is('deleted_at', null);

        if (filters.trade) q = q.eq('trade', filters.trade);
        if (filters.materialCategory)
          q = q.eq('material_category', filters.materialCategory);
        if (filters.supplierId) q = q.eq('supplier_id', filters.supplierId);
        if (filters.brand) q = q.eq('brand', filters.brand);
        if (filters.inStockOnly) q = q.eq('in_stock', true);

        const { data, error: err } = await q
          .order('name')
          .limit(filters.limit ?? 50);

        if (err) throw err;
        const mapped = (data ?? []).map(
          (row: Record<string, unknown>) =>
            snakeToCamel(row) as unknown as SupplierProduct
        );
        setResults(mapped);
        return mapped;
      } catch (e) {
        console.error('Product browse failed:', e);
        setError('Could not browse products.');
        return [];
      } finally {
        setLoading(false);
      }
    },
    []
  );

  const getProductByUpc = useCallback(async (upc: string) => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('supplier_products')
        .select('*')
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
      setError('Could not look up UPC.');
      return [];
    } finally {
      setLoading(false);
    }
  }, []);

  const comparePrices = useCallback(async (productName: string) => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('supplier_products')
        .select('*')
        .is('deleted_at', null)
        .ilike('name', `%${productName}%`)
        .not('price', 'is', null)
        .order('price', { ascending: true })
        .limit(20);
      if (err) throw err;
      const mapped = (data ?? []).map(
        (row: Record<string, unknown>) =>
          snakeToCamel(row) as unknown as SupplierProduct
      );
      setResults(mapped);
      return mapped;
    } catch (e) {
      console.error('Price comparison failed:', e);
      setError('Could not compare prices.');
      return [];
    } finally {
      setLoading(false);
    }
  }, []);

  return {
    results,
    loading,
    error,
    searchProducts,
    browseProducts,
    getProductByUpc,
    comparePrices,
  };
}

// ============================================================================
// HOOK: useProductFavorites — save/unsave products
// ============================================================================

export function useProductFavorites() {
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
        .select('*')
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

  const addFavorite = useCallback(
    async (productId: string, notes?: string) => {
      try {
        const supabase = getSupabase();
        const {
          data: { user },
        } = await supabase.auth.getUser();
        if (!user) throw new Error('Not authenticated');

        const companyId = user.app_metadata?.company_id;
        const { error: err } = await supabase
          .from('product_favorites')
          .upsert(
            {
              company_id: companyId,
              user_id: user.id,
              product_id: productId,
              notes: notes ?? null,
            },
            { onConflict: 'user_id,product_id' }
          );
        if (err) throw err;
        await loadFavorites();
      } catch (e) {
        console.error('Failed to add favorite:', e);
        setError('Could not add favorite.');
      }
    },
    [loadFavorites]
  );

  const removeFavorite = useCallback(
    async (id: string) => {
      try {
        const supabase = getSupabase();
        // Physical delete — junction table exception (Rule #14)
        const { error: err } = await supabase
          .from('product_favorites')
          .delete()
          .eq('id', id);
        if (err) throw err;
        await loadFavorites();
      } catch (e) {
        console.error('Failed to remove favorite:', e);
        setError('Could not remove favorite.');
      }
    },
    [loadFavorites]
  );

  return { favorites, loading, error, addFavorite, removeFavorite, reload: loadFavorites };
}

// ============================================================================
// HOOK: useRecentlyViewed — track product view history
// ============================================================================

export function useRecentlyViewed() {
  const [views, setViews] = useState<ProductView[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadViews = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('product_views')
        .select('*')
        .order('viewed_at', { ascending: false })
        .limit(20);
      if (err) throw err;
      setViews(
        (data ?? []).map(
          (row: Record<string, unknown>) =>
            snakeToCamel(row) as unknown as ProductView
        )
      );
    } catch (e) {
      console.error('Failed to load recent views:', e);
      setError('Could not load recently viewed.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadViews();
  }, [loadViews]);

  const recordView = useCallback(
    async (productId: string) => {
      try {
        const supabase = getSupabase();
        const {
          data: { user },
        } = await supabase.auth.getUser();
        if (!user) return;

        const companyId = user.app_metadata?.company_id;
        await supabase.from('product_views').insert({
          company_id: companyId,
          user_id: user.id,
          product_id: productId,
        });
        // Don't await reload — fire-and-forget for view tracking
      } catch (e) {
        console.error('Failed to record view:', e);
      }
    },
    []
  );

  return { views, loading, error, recordView, reload: loadViews };
}

// ============================================================================
// HOOK: useAffiliateTracking — record outbound clicks
// ============================================================================

export function useAffiliateTracking() {
  const [loading, setLoading] = useState(false);

  const recordClick = useCallback(
    async (params: {
      productId?: string;
      supplierId?: string;
      productName?: string;
      supplierName?: string;
      priceAtClick?: number;
      affiliateNetwork?: string;
      clickUrl?: string;
    }) => {
      setLoading(true);
      try {
        const supabase = getSupabase();
        const {
          data: { user },
        } = await supabase.auth.getUser();
        if (!user) return;

        const companyId = user.app_metadata?.company_id;
        await supabase.from('affiliate_clicks').insert({
          company_id: companyId,
          user_id: user.id,
          product_id: params.productId ?? null,
          supplier_id: params.supplierId ?? null,
          product_name: params.productName ?? null,
          supplier_name: params.supplierName ?? null,
          price_at_click: params.priceAtClick ?? null,
          affiliate_network: params.affiliateNetwork ?? null,
          click_url: params.clickUrl ?? null,
        });
      } catch (e) {
        console.error('Failed to record affiliate click:', e);
      } finally {
        setLoading(false);
      }
    },
    []
  );

  return { recordClick, loading };
}
