'use client';

// DEPTH40 — Marketplace Aggregator (Team Portal)
// Field employees can browse listings and save favorites.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface MarketplaceListing {
  id: string;
  sourceId: string;
  externalUrl: string;
  title: string;
  description: string | null;
  priceCents: number | null;
  currency: string;
  condition: string | null;
  sellerName: string | null;
  city: string | null;
  state: string | null;
  photos: Array<{ url: string; thumbnail_url?: string }>;
  photoCount: number;
  tradeCategory: string | null;
  itemCategory: string | null;
  brand: string | null;
  model: string | null;
  recallFound: boolean;
  recallDescription: string | null;
  status: string;
  createdAt: string;
}

export interface MySavedListing {
  id: string;
  listingId: string;
  savedType: string;
  notes: string | null;
  createdAt: string;
}

function mapListing(row: Record<string, unknown>): MarketplaceListing {
  return {
    id: row.id as string,
    sourceId: row.source_id as string,
    externalUrl: row.external_url as string,
    title: row.title as string,
    description: row.description as string | null,
    priceCents: row.price_cents as number | null,
    currency: (row.currency as string) || 'USD',
    condition: row.condition as string | null,
    sellerName: row.seller_name as string | null,
    city: row.city as string | null,
    state: row.state as string | null,
    photos: (row.photos as Array<{ url: string; thumbnail_url?: string }>) || [],
    photoCount: (row.photo_count as number) || 0,
    tradeCategory: row.trade_category as string | null,
    itemCategory: row.item_category as string | null,
    brand: row.brand as string | null,
    model: row.model as string | null,
    recallFound: (row.recall_found as boolean) || false,
    recallDescription: row.recall_description as string | null,
    status: (row.status as string) || 'active',
    createdAt: row.created_at as string,
  };
}

export function useTeamMarketplace(tradeCategory?: string) {
  const [listings, setListings] = useState<MarketplaceListing[]>([]);
  const [savedIds, setSavedIds] = useState<Set<string>>(new Set());
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

      // Fetch active listings
      let query = supabase
        .from('marketplace_listings')
        .select('*')
        .eq('company_id', companyId)
        .eq('status', 'active')
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(50);

      if (tradeCategory) {
        query = query.eq('trade_category', tradeCategory);
      }

      const { data: listingsData, error: listErr } = await query;
      if (listErr) throw listErr;

      // Fetch user's saved listing IDs
      const { data: savedData } = await supabase
        .from('marketplace_saved_listings')
        .select('listing_id')
        .eq('company_id', companyId)
        .eq('user_id', user.id);

      const savedSet = new Set<string>(
        (savedData || []).map((r: Record<string, unknown>) => r.listing_id as string)
      );

      setListings((listingsData || []).map((r: Record<string, unknown>) => mapListing(r)));
      setSavedIds(savedSet);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load marketplace');
    } finally {
      setLoading(false);
    }
  }, [tradeCategory]);

  useEffect(() => { fetch(); }, [fetch]);

  useEffect(() => {
    const supabase = getSupabase();
    const channel = supabase
      .channel('team-marketplace')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'marketplace_listings' }, () => fetch())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetch]);

  const toggleSave = useCallback(async (listingId: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    if (savedIds.has(listingId)) {
      // Unsave
      const { error: err } = await supabase
        .from('marketplace_saved_listings')
        .delete()
        .eq('user_id', user.id)
        .eq('listing_id', listingId);
      if (err) throw err;
    } else {
      // Save
      const listing = listings.find(l => l.id === listingId);
      const { error: err } = await supabase
        .from('marketplace_saved_listings')
        .insert({
          company_id: companyId,
          user_id: user.id,
          listing_id: listingId,
          saved_type: 'favorite',
          price_at_save: listing?.priceCents || null,
        });
      if (err) throw err;
    }
    await fetch();
  }, [savedIds, listings, fetch]);

  return {
    listings,
    savedIds,
    loading,
    error,
    toggleSave,
    refresh: fetch,
  };
}
