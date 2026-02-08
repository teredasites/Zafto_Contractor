'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// ============================================================
// ZAFTO Find a Pro — Contractor directory + targeted lead creation
// Tables: contractor_profiles, marketplace_leads
// ============================================================

export type ContractorTrade =
  | 'electrical' | 'hvac' | 'plumbing' | 'roofing' | 'general'
  | 'painting' | 'flooring' | 'landscaping' | 'carpentry' | 'concrete'
  | 'fire_protection' | 'solar' | 'insulation' | 'windows_doors' | 'other';

export interface ContractorProfile {
  id: string;
  displayName: string;
  tagline: string | null;
  avgRating: number | null;
  reviewCount: number;
  tradeCategories: ContractorTrade[];
  yearsInBusiness: number | null;
  city: string | null;
  state: string | null;
  licenseVerified: boolean;
  insured: boolean;
  logoPath: string | null;
  serviceRadius: number | null;
}

function mapContractor(row: Record<string, unknown>): ContractorProfile {
  return {
    id: row.id as string,
    displayName: row.display_name as string,
    tagline: row.tagline as string | null,
    avgRating: row.avg_rating as number | null,
    reviewCount: (row.review_count as number) || 0,
    tradeCategories: (row.trade_categories as ContractorTrade[]) || [],
    yearsInBusiness: row.years_in_business as number | null,
    city: row.city as string | null,
    state: row.state as string | null,
    licenseVerified: (row.license_verified as boolean) || false,
    insured: (row.insured as boolean) || false,
    logoPath: row.logo_path as string | null,
    serviceRadius: row.service_radius as number | null,
  };
}

const ALL_TRADES: { value: ContractorTrade; label: string }[] = [
  { value: 'electrical', label: 'Electrical' },
  { value: 'hvac', label: 'HVAC' },
  { value: 'plumbing', label: 'Plumbing' },
  { value: 'roofing', label: 'Roofing' },
  { value: 'painting', label: 'Painting' },
  { value: 'flooring', label: 'Flooring' },
  { value: 'landscaping', label: 'Landscaping' },
  { value: 'carpentry', label: 'Carpentry' },
  { value: 'concrete', label: 'Concrete' },
  { value: 'fire_protection', label: 'Fire Protection' },
  { value: 'solar', label: 'Solar' },
  { value: 'insulation', label: 'Insulation' },
  { value: 'windows_doors', label: 'Windows & Doors' },
  { value: 'general', label: 'General Handyman' },
  { value: 'other', label: 'Other' },
];

export function useContractors() {
  const { user } = useAuth();
  const [contractors, setContractors] = useState<ContractorProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [requesting, setRequesting] = useState(false);

  const fetchContractors = useCallback(async () => {
    const supabase = getSupabase();
    const { data } = await supabase
      .from('contractor_profiles')
      .select('*')
      .eq('is_active', true)
      .order('avg_rating', { ascending: false, nullsFirst: false });

    setContractors((data || []).map(mapContractor));
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchContractors();
  }, [fetchContractors]);

  // Request service from a specific contractor (targeted marketplace lead)
  const requestService = async (input: {
    contractorId: string;
    tradeCategory: ContractorTrade;
    serviceType: string;
    description: string;
    propertyAddress: string;
  }) => {
    if (!user) throw new Error('Not authenticated');
    setRequesting(true);
    try {
      const supabase = getSupabase();
      const { error } = await supabase.from('marketplace_leads').insert({
        homeowner_user_id: user.id,
        homeowner_email: user.email,
        targeted_contractor_id: input.contractorId,
        trade_category: input.tradeCategory,
        service_type: input.serviceType,
        urgency: 'normal',
        description: input.description,
        property_address: input.propertyAddress,
        status: 'matched',
      });
      if (error) throw error;
    } finally {
      setRequesting(false);
    }
  };

  // Filter helpers
  const filterByTrade = (trade: ContractorTrade | 'all') => {
    if (trade === 'all') return contractors;
    return contractors.filter(c => c.tradeCategories.includes(trade));
  };

  const filterBySearch = (query: string) => {
    if (!query) return contractors;
    const q = query.toLowerCase();
    return contractors.filter(c =>
      c.displayName.toLowerCase().includes(q) ||
      (c.tagline && c.tagline.toLowerCase().includes(q)) ||
      (c.city && c.city.toLowerCase().includes(q)) ||
      c.tradeCategories.some(t => t.replace(/_/g, ' ').includes(q))
    );
  };

  const filterByRating = (minRating: number) => {
    return contractors.filter(c => (c.avgRating || 0) >= minRating);
  };

  return {
    contractors,
    loading,
    requesting,
    requestService,
    refetch: fetchContractors,
    filterByTrade,
    filterBySearch,
    filterByRating,
    ALL_TRADES,
  };
}
