'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface MarketplaceLead {
  id: string;
  sourceType: string;
  equipmentScanId: string | null;
  homeownerName: string;
  homeownerEmail: string | null;
  homeownerPhone: string | null;
  propertyAddress: string | null;
  propertyCity: string | null;
  propertyState: string | null;
  propertyZip: string | null;
  propertyType: string | null;
  tradeCategory: string | null;
  serviceType: string | null;
  urgency: string | null;
  description: string | null;
  equipmentInfo: Record<string, unknown> | null;
  photos: Record<string, unknown>[] | null;
  estimatedBudgetMin: number | null;
  estimatedBudgetMax: number | null;
  matchedContractors: Record<string, unknown>[] | null;
  maxBids: number | null;
  status: string;
  expiresAt: string | null;
  createdAt: string;
  updatedAt: string | null;
}

export interface MarketplaceBid {
  id: string;
  marketplaceLeadId: string;
  companyId: string;
  bidderUserId: string;
  bidAmount: number;
  bidType: string | null;
  bidAmountMax: number | null;
  description: string | null;
  estimatedTimeline: string | null;
  includesParts: boolean;
  warrantyOffered: string | null;
  earliestAvailable: string | null;
  companyName: string | null;
  contractorRating: number | null;
  yearsExperience: number | null;
  licenseNumber: string | null;
  insured: boolean;
  status: string;
  homeownerViewedAt: string | null;
  messages: Record<string, unknown>[] | null;
  createdAt: string;
  updatedAt: string | null;
  // joined lead info (optional, populated via nested select)
  lead?: MarketplaceLead | null;
}

export interface ContractorProfile {
  id: string;
  companyId: string;
  displayName: string | null;
  tagline: string | null;
  description: string | null;
  logoPath: string | null;
  coverPhotoPath: string | null;
  serviceRadiusMiles: number | null;
  serviceZipCodes: string[] | null;
  tradeCategories: string[] | null;
  specializations: string[] | null;
  licenseNumber: string | null;
  licenseState: string | null;
  insuranceVerified: boolean;
  bonded: boolean;
  yearsInBusiness: number | null;
  avgRating: number | null;
  totalReviews: number | null;
  totalJobsCompleted: number | null;
  autoBid: boolean;
  maxDailyLeads: number | null;
  minJobValue: number | null;
  isActive: boolean;
  subscriptionTier: string | null;
  createdAt: string;
  updatedAt: string | null;
}

// ---------------------------------------------------------------------------
// Mappers (snake_case DB row -> camelCase TS)
// ---------------------------------------------------------------------------

/* eslint-disable @typescript-eslint/no-explicit-any */

function mapLead(row: any): MarketplaceLead {
  return {
    id: row.id,
    sourceType: row.source_type ?? '',
    equipmentScanId: row.equipment_scan_id ?? null,
    homeownerName: row.homeowner_name ?? '',
    homeownerEmail: row.homeowner_email ?? null,
    homeownerPhone: row.homeowner_phone ?? null,
    propertyAddress: row.property_address ?? null,
    propertyCity: row.property_city ?? null,
    propertyState: row.property_state ?? null,
    propertyZip: row.property_zip ?? null,
    propertyType: row.property_type ?? null,
    tradeCategory: row.trade_category ?? null,
    serviceType: row.service_type ?? null,
    urgency: row.urgency ?? null,
    description: row.description ?? null,
    equipmentInfo: row.equipment_info ?? null,
    photos: row.photos ?? null,
    estimatedBudgetMin: row.estimated_budget_min ?? null,
    estimatedBudgetMax: row.estimated_budget_max ?? null,
    matchedContractors: row.matched_contractors ?? null,
    maxBids: row.max_bids ?? null,
    status: row.status ?? 'open',
    expiresAt: row.expires_at ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at ?? null,
  };
}

function mapBid(row: any): MarketplaceBid {
  return {
    id: row.id,
    marketplaceLeadId: row.marketplace_lead_id,
    companyId: row.company_id,
    bidderUserId: row.bidder_user_id,
    bidAmount: row.bid_amount ?? 0,
    bidType: row.bid_type ?? null,
    bidAmountMax: row.bid_amount_max ?? null,
    description: row.description ?? null,
    estimatedTimeline: row.estimated_timeline ?? null,
    includesParts: row.includes_parts ?? false,
    warrantyOffered: row.warranty_offered ?? null,
    earliestAvailable: row.earliest_available ?? null,
    companyName: row.company_name ?? null,
    contractorRating: row.contractor_rating ?? null,
    yearsExperience: row.years_experience ?? null,
    licenseNumber: row.license_number ?? null,
    insured: row.insured ?? false,
    status: row.status ?? 'pending',
    homeownerViewedAt: row.homeowner_viewed_at ?? null,
    messages: row.messages ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at ?? null,
    lead: row.marketplace_leads ? mapLead(row.marketplace_leads) : null,
  };
}

function mapProfile(row: any): ContractorProfile {
  return {
    id: row.id,
    companyId: row.company_id,
    displayName: row.display_name ?? null,
    tagline: row.tagline ?? null,
    description: row.description ?? null,
    logoPath: row.logo_path ?? null,
    coverPhotoPath: row.cover_photo_path ?? null,
    serviceRadiusMiles: row.service_radius_miles ?? null,
    serviceZipCodes: row.service_zip_codes ?? null,
    tradeCategories: row.trade_categories ?? null,
    specializations: row.specializations ?? null,
    licenseNumber: row.license_number ?? null,
    licenseState: row.license_state ?? null,
    insuranceVerified: row.insurance_verified ?? false,
    bonded: row.bonded ?? false,
    yearsInBusiness: row.years_in_business ?? null,
    avgRating: row.avg_rating ?? null,
    totalReviews: row.total_reviews ?? null,
    totalJobsCompleted: row.total_jobs_completed ?? null,
    autoBid: row.auto_bid ?? false,
    maxDailyLeads: row.max_daily_leads ?? null,
    minJobValue: row.min_job_value ?? null,
    isActive: row.is_active ?? true,
    subscriptionTier: row.subscription_tier ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at ?? null,
  };
}

/* eslint-enable @typescript-eslint/no-explicit-any */

// ---------------------------------------------------------------------------
// Hook
// ---------------------------------------------------------------------------

export function useMarketplace() {
  const [leads, setLeads] = useState<MarketplaceLead[]>([]);
  const [bids, setBids] = useState<MarketplaceBid[]>([]);
  const [profile, setProfile] = useState<ContractorProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // ---- helpers to get auth context ----
  const getAuthContext = useCallback(async () => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId: string | undefined = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');
    return { supabase, user, companyId };
  }, []);

  // ---- fetch leads ----
  const fetchLeads = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('marketplace_leads')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(200);

      if (err) throw err;
      setLeads((data || []).map(mapLead));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load marketplace leads';
      setError(msg);
    }
  }, []);

  // ---- fetch bids for own company ----
  const fetchBids = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      const companyId: string | undefined = user?.app_metadata?.company_id;
      if (!companyId) {
        setBids([]);
        return;
      }

      const { data, error: err } = await supabase
        .from('marketplace_bids')
        .select('*, marketplace_leads(*)')
        .eq('company_id', companyId)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setBids((data || []).map(mapBid));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load bids';
      setError(msg);
    }
  }, []);

  // ---- fetch contractor profile ----
  const fetchProfile = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      const companyId: string | undefined = user?.app_metadata?.company_id;
      if (!companyId) {
        setProfile(null);
        return;
      }

      const { data, error: err } = await supabase
        .from('contractor_profiles')
        .select('*')
        .eq('company_id', companyId)
        .maybeSingle();

      if (err) throw err;
      setProfile(data ? mapProfile(data) : null);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load contractor profile';
      setError(msg);
    }
  }, []);

  // ---- initial fetch + real-time ----
  useEffect(() => {
    const loadAll = async () => {
      setLoading(true);
      setError(null);
      await Promise.all([fetchLeads(), fetchBids(), fetchProfile()]);
      setLoading(false);
    };

    loadAll();

    const supabase = getSupabase();

    const leadsChannel = supabase
      .channel('marketplace-leads-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'marketplace_leads' }, () => {
        fetchLeads();
      })
      .subscribe();

    const bidsChannel = supabase
      .channel('marketplace-bids-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'marketplace_bids' }, () => {
        fetchBids();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(leadsChannel);
      supabase.removeChannel(bidsChannel);
    };
  }, [fetchLeads, fetchBids, fetchProfile]);

  // ---- mutations ----

  const createBid = async (input: {
    marketplaceLeadId: string;
    bidAmount: number;
    bidType?: string;
    bidAmountMax?: number;
    description?: string;
    estimatedTimeline?: string;
    includesParts?: boolean;
    warrantyOffered?: string;
    earliestAvailable?: string;
  }): Promise<string> => {
    const { supabase, user, companyId } = await getAuthContext();

    // Pull company profile info for denormalized fields
    const { data: profileRow } = await supabase
      .from('contractor_profiles')
      .select('display_name, avg_rating, years_in_business, license_number, insurance_verified')
      .eq('company_id', companyId)
      .maybeSingle();

    const { data: result, error: err } = await supabase
      .from('marketplace_bids')
      .insert({
        marketplace_lead_id: input.marketplaceLeadId,
        company_id: companyId,
        bidder_user_id: user.id,
        bid_amount: input.bidAmount,
        bid_type: input.bidType || 'fixed',
        bid_amount_max: input.bidAmountMax || null,
        description: input.description || null,
        estimated_timeline: input.estimatedTimeline || null,
        includes_parts: input.includesParts ?? false,
        warranty_offered: input.warrantyOffered || null,
        earliest_available: input.earliestAvailable || null,
        company_name: profileRow?.display_name || null,
        contractor_rating: profileRow?.avg_rating || null,
        years_experience: profileRow?.years_in_business || null,
        license_number: profileRow?.license_number || null,
        insured: profileRow?.insurance_verified ?? false,
        status: 'pending',
        messages: [],
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateBidStatus = async (bidId: string, status: string) => {
    const { supabase } = await getAuthContext();
    const { error: err } = await supabase
      .from('marketplace_bids')
      .update({ status })
      .eq('id', bidId);
    if (err) throw err;
  };

  const withdrawBid = async (bidId: string) => {
    await updateBidStatus(bidId, 'withdrawn');
  };

  const updateContractorProfile = async (data: Partial<ContractorProfile>) => {
    const { supabase, companyId } = await getAuthContext();

    const updateData: Record<string, unknown> = {};
    if (data.displayName !== undefined) updateData.display_name = data.displayName;
    if (data.tagline !== undefined) updateData.tagline = data.tagline;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.serviceRadiusMiles !== undefined) updateData.service_radius_miles = data.serviceRadiusMiles;
    if (data.serviceZipCodes !== undefined) updateData.service_zip_codes = data.serviceZipCodes;
    if (data.tradeCategories !== undefined) updateData.trade_categories = data.tradeCategories;
    if (data.specializations !== undefined) updateData.specializations = data.specializations;
    if (data.licenseNumber !== undefined) updateData.license_number = data.licenseNumber;
    if (data.licenseState !== undefined) updateData.license_state = data.licenseState;
    if (data.insuranceVerified !== undefined) updateData.insurance_verified = data.insuranceVerified;
    if (data.bonded !== undefined) updateData.bonded = data.bonded;
    if (data.yearsInBusiness !== undefined) updateData.years_in_business = data.yearsInBusiness;
    if (data.autoBid !== undefined) updateData.auto_bid = data.autoBid;
    if (data.maxDailyLeads !== undefined) updateData.max_daily_leads = data.maxDailyLeads;
    if (data.minJobValue !== undefined) updateData.min_job_value = data.minJobValue;
    if (data.isActive !== undefined) updateData.is_active = data.isActive;

    // Upsert — create if no profile exists yet
    const { data: existing } = await supabase
      .from('contractor_profiles')
      .select('id')
      .eq('company_id', companyId)
      .maybeSingle();

    if (existing) {
      const { error: err } = await supabase
        .from('contractor_profiles')
        .update(updateData)
        .eq('company_id', companyId);
      if (err) throw err;
    } else {
      const { error: err } = await supabase
        .from('contractor_profiles')
        .insert({ company_id: companyId, ...updateData });
      if (err) throw err;
    }

    await fetchProfile();
  };

  // ---- computed values ----

  const openLeads = useMemo(
    () => leads.filter((l) => l.status === 'open'),
    [leads]
  );

  const myActiveBids = useMemo(
    () => bids.filter((b) => b.status === 'pending' || b.status === 'submitted'),
    [bids]
  );

  const wonBids = useMemo(
    () => bids.filter((b) => b.status === 'accepted'),
    [bids]
  );

  const avgBidAmount = useMemo(() => {
    if (bids.length === 0) return 0;
    const total = bids.reduce((sum, b) => sum + b.bidAmount, 0);
    return total / bids.length;
  }, [bids]);

  return {
    leads,
    bids,
    profile,
    loading,
    error,
    // mutations
    createBid,
    updateBidStatus,
    withdrawBid,
    updateContractorProfile,
    // computed
    openLeads,
    myActiveBids,
    wonBids,
    avgBidAmount,
    // refetch
    refetch: useCallback(async () => {
      await Promise.all([fetchLeads(), fetchBids(), fetchProfile()]);
    }, [fetchLeads, fetchBids, fetchProfile]),
  };
}
