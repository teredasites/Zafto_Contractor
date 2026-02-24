'use client';

// DEPTH31: Crowdsourced Material Pricing Intelligence Hook (CRM)
// Full CRUD for material receipts, supplier directory browsing,
// price index search, distributor account management, price alerts,
// and contributor status management.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type SupplierType =
  | 'big_box'
  | 'specialty_distributor'
  | 'supply_house'
  | 'online'
  | 'local_yard'
  | 'manufacturer_direct'
  | 'equipment_rental'
  | 'unknown';

export type PricingTier = 'retail' | 'wholesale' | 'account_only' | 'mixed';
export type ReceiptStatus = 'pending' | 'processing' | 'processed' | 'needs_review' | 'failed';
export type AlertType = 'below_price' | 'price_drop_pct' | 'back_in_stock';
export type ConnectionStatus = 'pending' | 'connected' | 'disconnected' | 'error' | 'expired';
export type ContributorBadge = 'none' | 'bronze' | 'silver' | 'gold' | 'platinum';

export interface SupplierDirectoryEntry {
  id: string;
  name: string;
  nameNormalized: string;
  aliases: string[];
  supplierType: SupplierType;
  tradesServed: string[];
  website: string | null;
  phone: string | null;
  locationsApproximate: string[];
  pricingTier: PricingTier;
  avgDiscountFromRetailPct: number | null;
  receiptCount: number;
  hasApi: boolean;
  apiType: string | null;
  affiliateNetwork: string | null;
  isVerified: boolean;
}

export interface MaterialReceipt {
  id: string;
  companyId: string;
  uploadedBy: string;
  supplierId: string | null;
  supplierNameRaw: string | null;
  supplierAddress: string | null;
  receiptDate: string | null;
  subtotal: number | null;
  tax: number | null;
  total: number | null;
  paymentMethod: string | null;
  receiptImageUrl: string | null;
  ocrConfidence: number | null;
  processingStatus: ReceiptStatus;
  reviewedBy: string | null;
  reviewedAt: string | null;
  linkedJobId: string | null;
  source: string;
  createdAt: string;
  updatedAt: string;
}

export interface MaterialReceiptItem {
  id: string;
  receiptId: string;
  companyId: string;
  descriptionRaw: string | null;
  descriptionNormalized: string | null;
  sku: string | null;
  upc: string | null;
  brand: string | null;
  productNameNormalized: string | null;
  materialCategory: string | null;
  trade: string | null;
  quantity: number;
  unit: string;
  unitPrice: number | null;
  total: number | null;
  ocrConfidence: number | null;
  manuallyCorrected: boolean;
}

export interface MaterialPriceIndexEntry {
  id: string;
  productNameNormalized: string;
  materialCategory: string;
  trade: string | null;
  brand: string | null;
  unit: string;
  avgPriceNational: number | null;
  avgPriceByMetro: Record<string, number>;
  priceLow: number | null;
  priceHigh: number | null;
  priceMedian: number | null;
  sampleCount: number;
  isPublished: boolean;
  trend30dPct: number | null;
  trend90dPct: number | null;
  trend12mPct: number | null;
}

export interface DistributorAccount {
  id: string;
  companyId: string;
  supplierId: string;
  accountNumber: string | null;
  connectionStatus: ConnectionStatus;
  lastSyncAt: string | null;
  syncError: string | null;
  useAccountPricing: boolean;
  createdAt: string;
}

export interface PriceAlert {
  id: string;
  companyId: string;
  userId: string;
  productQuery: string;
  productName: string | null;
  materialCategory: string | null;
  targetPrice: number | null;
  currentPrice: number | null;
  alertType: AlertType;
  dropPctThreshold: number | null;
  isActive: boolean;
  triggeredAt: string | null;
  createdAt: string;
}

export interface ContributorStatus {
  id: string;
  companyId: string;
  isContributor: boolean;
  receiptCount: number;
  itemsContributed: number;
  badgeLevel: ContributorBadge;
  lastContributionAt: string | null;
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
// HOOK: useMaterialReceipts
// ============================================================================

export function useMaterialReceipts(statusFilter?: ReceiptStatus) {
  const [receipts, setReceipts] = useState<MaterialReceipt[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadReceipts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let query = supabase
        .from('material_receipts')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (statusFilter) {
        query = query.eq('processing_status', statusFilter);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setReceipts(
        (data ?? []).map((row: Record<string, unknown>) => snakeToCamel(row) as unknown as MaterialReceipt)
      );
    } catch (e) {
      console.error('Failed to load receipts:', e);
      setError('Could not load material receipts.');
    } finally {
      setLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    loadReceipts();
  }, [loadReceipts]);

  // ── Create receipt ──
  const createReceipt = useCallback(async (data: Record<string, unknown>) => {
    try {
      const supabase = getSupabase();
      const { data: row, error: err } = await supabase
        .from('material_receipts')
        .insert(data)
        .select()
        .single();
      if (err) throw err;
      const receipt = snakeToCamel(row) as unknown as MaterialReceipt;
      setReceipts(prev => [receipt, ...prev]);
      return receipt;
    } catch (e) {
      console.error('Failed to create receipt:', e);
      throw e;
    }
  }, []);

  // ── Update receipt ──
  const updateReceipt = useCallback(async (id: string, updates: Record<string, unknown>) => {
    try {
      const supabase = getSupabase();
      const { data: row, error: err } = await supabase
        .from('material_receipts')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
      if (err) throw err;
      const updated = snakeToCamel(row) as unknown as MaterialReceipt;
      setReceipts(prev => prev.map(r => r.id === id ? updated : r));
      return updated;
    } catch (e) {
      console.error('Failed to update receipt:', e);
      throw e;
    }
  }, []);

  // ── Delete receipt (soft) ──
  const deleteReceipt = useCallback(async (id: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('material_receipts')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);
      if (err) throw err;
      setReceipts(prev => prev.filter(r => r.id !== id));
    } catch (e) {
      console.error('Failed to delete receipt:', e);
      throw e;
    }
  }, []);

  return {
    receipts,
    loading,
    error,
    reload: loadReceipts,
    createReceipt,
    updateReceipt,
    deleteReceipt,
  };
}

// ============================================================================
// HOOK: useReceiptItems
// ============================================================================

export function useReceiptItems(receiptId: string | null) {
  const [items, setItems] = useState<MaterialReceiptItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadItems = useCallback(async () => {
    if (!receiptId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('material_receipt_items')
        .select('*')
        .eq('receipt_id', receiptId)
        .is('deleted_at', null)
        .order('created_at');
      if (err) throw err;
      setItems(
        (data ?? []).map((row: Record<string, unknown>) => snakeToCamel(row) as unknown as MaterialReceiptItem)
      );
    } catch (e) {
      console.error('Failed to load receipt items:', e);
      setError('Could not load receipt line items.');
    } finally {
      setLoading(false);
    }
  }, [receiptId]);

  useEffect(() => {
    loadItems();
  }, [loadItems]);

  // ── Update item (manual correction) ──
  const updateItem = useCallback(async (itemId: string, updates: Record<string, unknown>) => {
    try {
      const supabase = getSupabase();
      const { data: row, error: err } = await supabase
        .from('material_receipt_items')
        .update({ ...updates, manually_corrected: true })
        .eq('id', itemId)
        .select()
        .single();
      if (err) throw err;
      const updated = snakeToCamel(row) as unknown as MaterialReceiptItem;
      setItems(prev => prev.map(i => i.id === itemId ? updated : i));
      return updated;
    } catch (e) {
      console.error('Failed to update receipt item:', e);
      throw e;
    }
  }, []);

  // ── Delete item (soft) ──
  const deleteItem = useCallback(async (itemId: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('material_receipt_items')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', itemId);
      if (err) throw err;
      setItems(prev => prev.filter(i => i.id !== itemId));
    } catch (e) {
      console.error('Failed to delete receipt item:', e);
      throw e;
    }
  }, []);

  return { items, loading, error, reload: loadItems, updateItem, deleteItem };
}

// ============================================================================
// HOOK: useSupplierDirectory
// ============================================================================

export function useSupplierDirectory(trade?: string) {
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
        .is('deleted_at', null)
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

  // ── Search suppliers ──
  const searchSuppliers = useCallback(async (query: string) => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('supplier_directory')
        .select('*')
        .is('deleted_at', null)
        .or(`name.ilike.%${query}%,name_normalized.ilike.%${query}%`)
        .order('receipt_count', { ascending: false })
        .limit(20);
      if (err) throw err;
      return (data ?? []).map((row: Record<string, unknown>) => snakeToCamel(row) as unknown as SupplierDirectoryEntry);
    } catch (e) {
      console.error('Failed to search suppliers:', e);
      return [];
    }
  }, []);

  return { suppliers, loading, error, reload: loadSuppliers, searchSuppliers };
}

// ============================================================================
// HOOK: useMaterialPriceIndex
// ============================================================================

export function useMaterialPriceIndex() {
  const [results, setResults] = useState<MaterialPriceIndexEntry[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // ── Search price index ──
  const searchPrices = useCallback(async (query: string, filters?: {
    materialCategory?: string;
    trade?: string;
  }) => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let q = supabase
        .from('material_price_index')
        .select('*')
        .eq('is_published', true);

      if (query) {
        q = q.ilike('product_name_normalized', `%${query}%`);
      }
      if (filters?.materialCategory) {
        q = q.eq('material_category', filters.materialCategory);
      }
      if (filters?.trade) {
        q = q.eq('trade', filters.trade);
      }

      const { data, error: err } = await q
        .order('sample_count', { ascending: false })
        .limit(50);

      if (err) throw err;
      const entries = (data ?? []).map((row: Record<string, unknown>) =>
        snakeToCamel(row) as unknown as MaterialPriceIndexEntry
      );
      setResults(entries);
      return entries;
    } catch (e) {
      console.error('Failed to search price index:', e);
      setError('Could not search material prices.');
      return [];
    } finally {
      setLoading(false);
    }
  }, []);

  // ── Get price for specific product ──
  const getProductPrice = useCallback(async (productName: string) => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('material_price_index')
        .select('*')
        .eq('product_name_normalized', productName)
        .eq('is_published', true)
        .limit(1);
      if (err) throw err;
      if (!data || data.length === 0) return null;
      return snakeToCamel(data[0] as Record<string, unknown>) as unknown as MaterialPriceIndexEntry;
    } catch (e) {
      console.error('Failed to get product price:', e);
      return null;
    }
  }, []);

  return { results, loading, error, searchPrices, getProductPrice };
}

// ============================================================================
// HOOK: useDistributorAccounts
// ============================================================================

export function useDistributorAccounts() {
  const [accounts, setAccounts] = useState<DistributorAccount[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadAccounts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('distributor_accounts')
        .select('*')
        .is('deleted_at', null)
        .order('created_at');
      if (err) throw err;
      setAccounts(
        (data ?? []).map((row: Record<string, unknown>) => snakeToCamel(row) as unknown as DistributorAccount)
      );
    } catch (e) {
      console.error('Failed to load distributor accounts:', e);
      setError('Could not load linked supplier accounts.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadAccounts();
  }, [loadAccounts]);

  // ── Link account ──
  const linkAccount = useCallback(async (data: Record<string, unknown>) => {
    try {
      const supabase = getSupabase();
      const { data: row, error: err } = await supabase
        .from('distributor_accounts')
        .insert(data)
        .select()
        .single();
      if (err) throw err;
      const account = snakeToCamel(row) as unknown as DistributorAccount;
      setAccounts(prev => [...prev, account]);
      return account;
    } catch (e) {
      console.error('Failed to link distributor account:', e);
      throw e;
    }
  }, []);

  // ── Update account ──
  const updateAccount = useCallback(async (id: string, updates: Record<string, unknown>) => {
    try {
      const supabase = getSupabase();
      const { data: row, error: err } = await supabase
        .from('distributor_accounts')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
      if (err) throw err;
      const updated = snakeToCamel(row) as unknown as DistributorAccount;
      setAccounts(prev => prev.map(a => a.id === id ? updated : a));
      return updated;
    } catch (e) {
      console.error('Failed to update distributor account:', e);
      throw e;
    }
  }, []);

  // ── Unlink account (soft delete) ──
  const unlinkAccount = useCallback(async (id: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('distributor_accounts')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);
      if (err) throw err;
      setAccounts(prev => prev.filter(a => a.id !== id));
    } catch (e) {
      console.error('Failed to unlink distributor account:', e);
      throw e;
    }
  }, []);

  return { accounts, loading, error, reload: loadAccounts, linkAccount, updateAccount, unlinkAccount };
}

// ============================================================================
// HOOK: usePriceAlerts
// ============================================================================

export function usePriceAlerts() {
  const [alerts, setAlerts] = useState<PriceAlert[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadAlerts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('price_alerts')
        .select('*')
        .eq('is_active', true)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });
      if (err) throw err;
      setAlerts(
        (data ?? []).map((row: Record<string, unknown>) => snakeToCamel(row) as unknown as PriceAlert)
      );
    } catch (e) {
      console.error('Failed to load price alerts:', e);
      setError('Could not load price alerts.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadAlerts();
  }, [loadAlerts]);

  // ── Create alert ──
  const createAlert = useCallback(async (data: Record<string, unknown>) => {
    try {
      const supabase = getSupabase();
      const { data: row, error: err } = await supabase
        .from('price_alerts')
        .insert(data)
        .select()
        .single();
      if (err) throw err;
      const alert = snakeToCamel(row) as unknown as PriceAlert;
      setAlerts(prev => [alert, ...prev]);
      return alert;
    } catch (e) {
      console.error('Failed to create price alert:', e);
      throw e;
    }
  }, []);

  // ── Delete alert (soft) ──
  const deleteAlert = useCallback(async (id: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('price_alerts')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);
      if (err) throw err;
      setAlerts(prev => prev.filter(a => a.id !== id));
    } catch (e) {
      console.error('Failed to delete price alert:', e);
      throw e;
    }
  }, []);

  return { alerts, loading, error, reload: loadAlerts, createAlert, deleteAlert };
}

// ============================================================================
// HOOK: useContributorStatus
// ============================================================================

export function useContributorStatus() {
  const [status, setStatus] = useState<ContributorStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadStatus = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('pricing_contributor_status')
        .select('*')
        .limit(1);
      if (err) throw err;
      if (data && data.length > 0) {
        setStatus(snakeToCamel(data[0] as Record<string, unknown>) as unknown as ContributorStatus);
      }
    } catch (e) {
      console.error('Failed to load contributor status:', e);
      setError('Could not load pricing contributor status.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadStatus();
  }, [loadStatus]);

  // ── Toggle contribution ──
  const toggleContribution = useCallback(async (companyId: string, contribute: boolean) => {
    try {
      const supabase = getSupabase();
      const { data: row, error: err } = await supabase
        .from('pricing_contributor_status')
        .upsert({
          company_id: companyId,
          is_contributor: contribute,
          opted_out_at: contribute ? null : new Date().toISOString(),
        }, { onConflict: 'company_id' })
        .select()
        .single();
      if (err) throw err;
      setStatus(snakeToCamel(row) as unknown as ContributorStatus);
    } catch (e) {
      console.error('Failed to update contributor status:', e);
      throw e;
    }
  }, []);

  return { status, loading, error, reload: loadStatus, toggleContribution };
}
