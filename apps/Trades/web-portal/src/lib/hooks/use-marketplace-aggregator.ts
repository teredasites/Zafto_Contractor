'use client';

// DEPTH40 — Universal Marketplace Aggregator
// Browse tools, trucks, equipment across 15+ marketplaces.
// CPSC recall checking, save/watch, trade-relevant search.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──

export interface MarketplaceSource {
  id: string;
  name: string;
  slug: string;
  sourceType: string;
  baseUrl: string | null;
  apiConfig: Record<string, unknown>;
  isActive: boolean;
  iconName: string | null;
  createdAt: string;
}

export interface AggregatorListing {
  id: string;
  companyId: string;
  sourceId: string;
  externalId: string | null;
  externalUrl: string;
  title: string;
  description: string | null;
  priceCents: number | null;
  currency: string;
  condition: string | null;
  sellerName: string | null;
  sellerLocation: string | null;
  sellerRating: number | null;
  latitude: number | null;
  longitude: number | null;
  city: string | null;
  state: string | null;
  zipCode: string | null;
  distanceMiles: number | null;
  photos: Array<{ url: string; thumbnail_url?: string }>;
  photoCount: number;
  tradeCategory: string | null;
  itemCategory: string | null;
  brand: string | null;
  model: string | null;
  year: number | null;
  recallChecked: boolean;
  recallFound: boolean;
  recallId: string | null;
  recallDescription: string | null;
  status: string;
  importedAt: string;
  rawData: Record<string, unknown> | null;
  createdAt: string;
  updatedAt: string;
}

export interface SavedAggregatorListing {
  id: string;
  companyId: string;
  userId: string;
  listingId: string;
  savedType: string;
  notes: string | null;
  priceAtSave: number | null;
  priceAlertThreshold: number | null;
  createdAt: string;
}

export interface AggregatorSearchRecord {
  id: string;
  companyId: string;
  userId: string;
  name: string;
  query: string | null;
  tradeCategory: string | null;
  itemCategory: string | null;
  minPriceCents: number | null;
  maxPriceCents: number | null;
  conditionFilter: string[] | null;
  maxDistanceMiles: number | null;
  sourceFilter: string[] | null;
  brandFilter: string[] | null;
  alertEnabled: boolean;
  alertFrequency: string;
  lastAlertAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface CpscRecall {
  id: string;
  recallNumber: string;
  productName: string;
  description: string | null;
  hazard: string | null;
  remedy: string | null;
  manufacturer: string | null;
  productType: string | null;
  categories: string[];
  images: string[];
  recallDate: string | null;
}

export interface MarketplaceTradeCategory {
  id: string;
  trade: string;
  itemCategories: string[];
  keywords: string[];
}

// ── Mappers ──

function mapSource(row: Record<string, unknown>): MarketplaceSource {
  return {
    id: row.id as string,
    name: row.name as string,
    slug: row.slug as string,
    sourceType: row.source_type as string,
    baseUrl: row.base_url as string | null,
    apiConfig: (row.api_config as Record<string, unknown>) || {},
    isActive: row.is_active as boolean,
    iconName: row.icon_name as string | null,
    createdAt: row.created_at as string,
  };
}

function mapListing(row: Record<string, unknown>): AggregatorListing {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    sourceId: row.source_id as string,
    externalId: row.external_id as string | null,
    externalUrl: row.external_url as string,
    title: row.title as string,
    description: row.description as string | null,
    priceCents: row.price_cents as number | null,
    currency: (row.currency as string) || 'USD',
    condition: row.condition as string | null,
    sellerName: row.seller_name as string | null,
    sellerLocation: row.seller_location as string | null,
    sellerRating: row.seller_rating as number | null,
    latitude: row.latitude as number | null,
    longitude: row.longitude as number | null,
    city: row.city as string | null,
    state: row.state as string | null,
    zipCode: row.zip_code as string | null,
    distanceMiles: row.distance_miles as number | null,
    photos: (row.photos as Array<{ url: string; thumbnail_url?: string }>) || [],
    photoCount: (row.photo_count as number) || 0,
    tradeCategory: row.trade_category as string | null,
    itemCategory: row.item_category as string | null,
    brand: row.brand as string | null,
    model: row.model as string | null,
    year: row.year as number | null,
    recallChecked: (row.recall_checked as boolean) || false,
    recallFound: (row.recall_found as boolean) || false,
    recallId: row.recall_id as string | null,
    recallDescription: row.recall_description as string | null,
    status: (row.status as string) || 'active',
    importedAt: row.imported_at as string,
    rawData: row.raw_data as Record<string, unknown> | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapSaved(row: Record<string, unknown>): SavedAggregatorListing {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    userId: row.user_id as string,
    listingId: row.listing_id as string,
    savedType: (row.saved_type as string) || 'favorite',
    notes: row.notes as string | null,
    priceAtSave: row.price_at_save as number | null,
    priceAlertThreshold: row.price_alert_threshold as number | null,
    createdAt: row.created_at as string,
  };
}

function mapSearch(row: Record<string, unknown>): AggregatorSearchRecord {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    userId: row.user_id as string,
    name: row.name as string,
    query: row.query as string | null,
    tradeCategory: row.trade_category as string | null,
    itemCategory: row.item_category as string | null,
    minPriceCents: row.min_price_cents as number | null,
    maxPriceCents: row.max_price_cents as number | null,
    conditionFilter: row.condition_filter as string[] | null,
    maxDistanceMiles: row.max_distance_miles as number | null,
    sourceFilter: row.source_filter as string[] | null,
    brandFilter: row.brand_filter as string[] | null,
    alertEnabled: (row.alert_enabled as boolean) ?? true,
    alertFrequency: (row.alert_frequency as string) || 'daily',
    lastAlertAt: row.last_alert_at as string | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

// ── Hook: useMarketplaceSources ──

export function useMarketplaceSources() {
  const [sources, setSources] = useState<MarketplaceSource[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('marketplace_sources')
        .select('*')
        .eq('is_active', true)
        .order('name');

      if (err) throw err;
      setSources((data || []).map((r: Record<string, unknown>) => mapSource(r)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load sources');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetch(); }, [fetch]);

  return { sources, loading, error, refresh: fetch };
}

// ── Hook: useAggregatorListings ──

export interface AggregatorFilters {
  tradeCategory?: string;
  itemCategory?: string;
  sourceId?: string;
  brand?: string;
  maxPriceCents?: number;
  status?: string;
  searchQuery?: string;
}

export function useAggregatorListings(filters?: AggregatorFilters) {
  const [listings, setListings] = useState<AggregatorListing[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const companyId = user.app_metadata?.company_id;
      if (!companyId) { setLoading(false); return; }

      let query = supabase
        .from('marketplace_listings')
        .select('*')
        .eq('company_id', companyId)
        .is('deleted_at', null)
        .eq('status', filters?.status || 'active')
        .order('created_at', { ascending: false })
        .limit(100);

      if (filters?.tradeCategory) {
        query = query.eq('trade_category', filters.tradeCategory);
      }
      if (filters?.itemCategory) {
        query = query.eq('item_category', filters.itemCategory);
      }
      if (filters?.sourceId) {
        query = query.eq('source_id', filters.sourceId);
      }
      if (filters?.brand) {
        query = query.ilike('brand', `%${filters.brand}%`);
      }
      if (filters?.maxPriceCents) {
        query = query.lte('price_cents', filters.maxPriceCents);
      }
      if (filters?.searchQuery) {
        query = query.or(
          `title.ilike.%${filters.searchQuery}%,description.ilike.%${filters.searchQuery}%,brand.ilike.%${filters.searchQuery}%`
        );
      }

      const { data, error: err } = await query;
      if (err) throw err;

      setListings((data || []).map((r: Record<string, unknown>) => mapListing(r)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load listings');
    } finally {
      setLoading(false);
    }
  }, [
    filters?.tradeCategory,
    filters?.itemCategory,
    filters?.sourceId,
    filters?.brand,
    filters?.maxPriceCents,
    filters?.status,
    filters?.searchQuery,
  ]);

  useEffect(() => { fetch(); }, [fetch]);

  useEffect(() => {
    const supabase = getSupabase();
    const channel = supabase
      .channel('aggregator-listings')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'marketplace_listings' }, () => fetch())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetch]);

  const createListing = useCallback(async (data: {
    sourceId: string;
    externalUrl: string;
    title: string;
    description?: string;
    priceCents?: number;
    condition?: string;
    tradeCategory?: string;
    itemCategory?: string;
    brand?: string;
    model?: string;
    year?: number;
    city?: string;
    state?: string;
    zipCode?: string;
    photos?: Array<{ url: string; thumbnail_url?: string }>;
  }) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { error: err } = await supabase
      .from('marketplace_listings')
      .insert({
        company_id: companyId,
        source_id: data.sourceId,
        external_url: data.externalUrl,
        title: data.title,
        description: data.description || null,
        price_cents: data.priceCents || null,
        condition: data.condition || 'unknown',
        trade_category: data.tradeCategory || null,
        item_category: data.itemCategory || null,
        brand: data.brand || null,
        model: data.model || null,
        year: data.year || null,
        city: data.city || null,
        state: data.state || null,
        zip_code: data.zipCode || null,
        photos: data.photos || [],
        photo_count: data.photos?.length || 0,
      });

    if (err) throw err;
    await fetch();
  }, [fetch]);

  const updateListingStatus = useCallback(async (listingId: string, status: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('marketplace_listings')
      .update({ status })
      .eq('id', listingId);
    if (err) throw err;
    await fetch();
  }, [fetch]);

  const deleteListing = useCallback(async (listingId: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('marketplace_listings')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', listingId);
    if (err) throw err;
    await fetch();
  }, [fetch]);

  const recallCount = listings.filter(l => l.recallFound).length;
  const avgPrice = listings.filter(l => l.priceCents != null).length > 0
    ? listings.filter(l => l.priceCents != null).reduce((sum, l) => sum + (l.priceCents || 0), 0) /
      listings.filter(l => l.priceCents != null).length
    : 0;

  return {
    listings,
    loading,
    error,
    totalCount: listings.length,
    recallCount,
    avgPriceCents: Math.round(avgPrice),
    createListing,
    updateListingStatus,
    deleteListing,
    refresh: fetch,
  };
}

// ── Hook: useSavedAggregatorListings ──

export function useSavedAggregatorListings(savedType?: string) {
  const [saved, setSaved] = useState<SavedAggregatorListing[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const companyId = user.app_metadata?.company_id;
      if (!companyId) { setLoading(false); return; }

      let query = supabase
        .from('marketplace_saved_listings')
        .select('*')
        .eq('company_id', companyId)
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (savedType) {
        query = query.eq('saved_type', savedType);
      }

      const { data, error: err } = await query;
      if (err) throw err;

      setSaved((data || []).map((r: Record<string, unknown>) => mapSaved(r)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load saved listings');
    } finally {
      setLoading(false);
    }
  }, [savedType]);

  useEffect(() => { fetch(); }, [fetch]);

  useEffect(() => {
    const supabase = getSupabase();
    const channel = supabase
      .channel('aggregator-saved')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'marketplace_saved_listings' }, () => fetch())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetch]);

  const saveListing = useCallback(async (data: {
    listingId: string;
    savedType?: string;
    notes?: string;
    priceAtSave?: number;
    priceAlertThreshold?: number;
  }) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { error: err } = await supabase
      .from('marketplace_saved_listings')
      .insert({
        company_id: companyId,
        user_id: user.id,
        listing_id: data.listingId,
        saved_type: data.savedType || 'favorite',
        notes: data.notes || null,
        price_at_save: data.priceAtSave || null,
        price_alert_threshold: data.priceAlertThreshold || null,
      });

    if (err) throw err;
    await fetch();
  }, [fetch]);

  // Physical delete is acceptable here: marketplace_saved_listings is a
  // bookmark/junction table with UNIQUE(user_id, listing_id) and no deleted_at
  // column. Unsaving is semantically a removal, not archival. Soft delete would
  // break the unique constraint if the user re-saves the same listing.
  const unsaveListing = useCallback(async (savedId: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('marketplace_saved_listings')
      .delete()
      .eq('id', savedId);
    if (err) throw err;
    await fetch();
  }, [fetch]);

  return {
    saved,
    loading,
    error,
    favoriteCount: saved.filter(s => s.savedType === 'favorite').length,
    watchCount: saved.filter(s => s.savedType === 'watch').length,
    saveListing,
    unsaveListing,
    refresh: fetch,
  };
}

// ── Hook: useAggregatorSearches ──

export function useAggregatorSearches() {
  const [searches, setSearches] = useState<AggregatorSearchRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const companyId = user.app_metadata?.company_id;
      if (!companyId) { setLoading(false); return; }

      const { data, error: err } = await supabase
        .from('marketplace_searches')
        .select('*')
        .eq('company_id', companyId)
        .eq('user_id', user.id)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;

      setSearches((data || []).map((r: Record<string, unknown>) => mapSearch(r)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load saved searches');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetch(); }, [fetch]);

  const createSearch = useCallback(async (data: {
    name: string;
    query?: string;
    tradeCategory?: string;
    itemCategory?: string;
    minPriceCents?: number;
    maxPriceCents?: number;
    conditionFilter?: string[];
    maxDistanceMiles?: number;
    sourceFilter?: string[];
    brandFilter?: string[];
    alertFrequency?: string;
  }) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { error: err } = await supabase
      .from('marketplace_searches')
      .insert({
        company_id: companyId,
        user_id: user.id,
        name: data.name,
        query: data.query || null,
        trade_category: data.tradeCategory || null,
        item_category: data.itemCategory || null,
        min_price_cents: data.minPriceCents || null,
        max_price_cents: data.maxPriceCents || null,
        condition_filter: data.conditionFilter || null,
        max_distance_miles: data.maxDistanceMiles || null,
        source_filter: data.sourceFilter || null,
        brand_filter: data.brandFilter || null,
        alert_frequency: data.alertFrequency || 'daily',
      });

    if (err) throw err;
    await fetch();
  }, [fetch]);

  const updateSearch = useCallback(async (searchId: string, data: {
    name?: string;
    alertEnabled?: boolean;
    alertFrequency?: string;
  }) => {
    const supabase = getSupabase();
    const update: Record<string, unknown> = {};
    if (data.name !== undefined) update.name = data.name;
    if (data.alertEnabled !== undefined) update.alert_enabled = data.alertEnabled;
    if (data.alertFrequency !== undefined) update.alert_frequency = data.alertFrequency;

    const { error: err } = await supabase
      .from('marketplace_searches')
      .update(update)
      .eq('id', searchId);

    if (err) throw err;
    await fetch();
  }, [fetch]);

  const deleteSearch = useCallback(async (searchId: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('marketplace_searches')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', searchId);
    if (err) throw err;
    await fetch();
  }, [fetch]);

  return {
    searches,
    loading,
    error,
    activeAlertCount: searches.filter(s => s.alertEnabled).length,
    createSearch,
    updateSearch,
    deleteSearch,
    refresh: fetch,
  };
}

// ── Hook: useCpscRecallCheck ──

export function useCpscRecallCheck() {
  const [recalls, setRecalls] = useState<CpscRecall[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const searchRecalls = useCallback(async (query: string) => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('cpsc_recall_cache')
        .select('*')
        .or(`product_name.ilike.%${query}%,manufacturer.ilike.%${query}%`)
        .order('recall_date', { ascending: false })
        .limit(20);

      if (err) throw err;

      const mapped: CpscRecall[] = (data || []).map((row: Record<string, unknown>) => ({
        id: row.id as string,
        recallNumber: row.recall_number as string,
        productName: row.product_name as string,
        description: row.description as string | null,
        hazard: row.hazard as string | null,
        remedy: row.remedy as string | null,
        manufacturer: row.manufacturer as string | null,
        productType: row.product_type as string | null,
        categories: (row.categories as string[]) || [],
        images: (row.images as string[]) || [],
        recallDate: row.recall_date as string | null,
      }));

      setRecalls(mapped);
      return mapped;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Recall search failed');
      return [];
    } finally {
      setLoading(false);
    }
  }, []);

  return { recalls, loading, error, searchRecalls };
}

// ── Hook: useMarketplaceTradeCategories ──

export function useMarketplaceTradeCategories() {
  const [categories, setCategories] = useState<MarketplaceTradeCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('marketplace_trade_categories')
        .select('*')
        .order('trade');

      if (err) throw err;

      setCategories((data || []).map((row: Record<string, unknown>) => ({
        id: row.id as string,
        trade: row.trade as string,
        itemCategories: (row.item_categories as string[]) || [],
        keywords: (row.keywords as string[]) || [],
      })));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load trade categories');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetch(); }, [fetch]);

  return { categories, loading, error, refresh: fetch };
}
