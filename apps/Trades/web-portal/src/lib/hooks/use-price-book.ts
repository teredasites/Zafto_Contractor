'use client';

// DEPTH29: Price Book Hook (S130 Owner Directive)
// Company-specific known prices for one-click use in estimates/invoices.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface PriceBookItem {
  id: string;
  companyId: string;
  name: string;
  category: string | null;
  trade: string | null;
  unitPrice: number;
  unitOfMeasure: string;
  description: string | null;
  sku: string | null;
  supplier: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// ============================================================================
// MAPPER
// ============================================================================

function mapItem(row: Record<string, unknown>): PriceBookItem {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    name: row.name as string,
    category: row.category as string | null,
    trade: row.trade as string | null,
    unitPrice: Number(row.unit_price) || 0,
    unitOfMeasure: (row.unit_of_measure as string) || 'each',
    description: row.description as string | null,
    sku: row.sku as string | null,
    supplier: row.supplier as string | null,
    isActive: row.is_active !== false,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

// ============================================================================
// HOOK: usePriceBook
// ============================================================================

export function usePriceBook() {
  const [items, setItems] = useState<PriceBookItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchItems = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('price_book_items')
        .select('*')
        .is('deleted_at', null)
        .eq('is_active', true)
        .order('category')
        .order('name');

      if (err) throw err;
      setItems((data || []).map(mapItem));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load price book');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchItems(); }, [fetchItems]);

  // Search price book items
  const search = useCallback((query: string) => {
    const q = query.toLowerCase();
    return items.filter(
      i =>
        i.name.toLowerCase().includes(q) ||
        (i.category && i.category.toLowerCase().includes(q)) ||
        (i.sku && i.sku.toLowerCase().includes(q)) ||
        (i.description && i.description.toLowerCase().includes(q))
    );
  }, [items]);

  // Filter by trade
  const getByTrade = useCallback((trade: string) => {
    return items.filter(i => i.trade === trade);
  }, [items]);

  // Get unique categories
  const categories = [...new Set(items.filter(i => i.category).map(i => i.category!))].sort();

  // Add item
  const addItem = useCallback(async (input: {
    name: string;
    category?: string;
    trade?: string;
    unitPrice: number;
    unitOfMeasure?: string;
    description?: string;
    sku?: string;
    supplier?: string;
  }) => {
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const companyId = session.user.app_metadata?.company_id;
      if (!companyId) throw new Error('No company context');

      const { error: err } = await supabase.from('price_book_items').insert({
        company_id: companyId,
        name: input.name,
        category: input.category || null,
        trade: input.trade || null,
        unit_price: input.unitPrice,
        unit_of_measure: input.unitOfMeasure || 'each',
        description: input.description || null,
        sku: input.sku || null,
        supplier: input.supplier || null,
      });

      if (err) throw err;
      await fetchItems();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to add price book item');
    }
  }, [fetchItems]);

  // Update item
  const updateItem = useCallback(async (id: string, updates: Partial<{
    name: string;
    category: string;
    trade: string;
    unitPrice: number;
    unitOfMeasure: string;
    description: string;
    sku: string;
    supplier: string;
    isActive: boolean;
  }>) => {
    try {
      const supabase = getSupabase();
      const dbUpdates: Record<string, unknown> = {};
      if (updates.name !== undefined) dbUpdates.name = updates.name;
      if (updates.category !== undefined) dbUpdates.category = updates.category;
      if (updates.trade !== undefined) dbUpdates.trade = updates.trade;
      if (updates.unitPrice !== undefined) dbUpdates.unit_price = updates.unitPrice;
      if (updates.unitOfMeasure !== undefined) dbUpdates.unit_of_measure = updates.unitOfMeasure;
      if (updates.description !== undefined) dbUpdates.description = updates.description;
      if (updates.sku !== undefined) dbUpdates.sku = updates.sku;
      if (updates.supplier !== undefined) dbUpdates.supplier = updates.supplier;
      if (updates.isActive !== undefined) dbUpdates.is_active = updates.isActive;

      const { error: err } = await supabase
        .from('price_book_items')
        .update(dbUpdates)
        .eq('id', id);

      if (err) throw err;
      await fetchItems();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to update price book item');
    }
  }, [fetchItems]);

  // Soft delete
  const deleteItem = useCallback(async (id: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('price_book_items')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);

      if (err) throw err;
      await fetchItems();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to delete price book item');
    }
  }, [fetchItems]);

  return {
    items,
    categories,
    loading,
    error,
    refetch: fetchItems,
    search,
    getByTrade,
    addItem,
    updateItem,
    deleteItem,
  };
}
