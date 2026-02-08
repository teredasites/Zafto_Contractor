'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// ============================================================
// ZAFTO Get Quotes — Homeowner marketplace entry point (F6)
// Tables: marketplace_leads, marketplace_bids, contractor_profiles
// ============================================================

export type TradeCategory =
  | 'electrical' | 'hvac' | 'plumbing' | 'roofing' | 'general'
  | 'painting' | 'flooring' | 'landscaping' | 'carpentry' | 'concrete'
  | 'fire_protection' | 'solar' | 'insulation' | 'windows_doors' | 'other';

export type ServiceType = 'repair' | 'replace' | 'install' | 'inspect';
export type UrgencyLevel = 'normal' | 'soon' | 'urgent' | 'emergency';
export type LeadStatus = 'open' | 'matched' | 'quoted' | 'accepted' | 'completed' | 'cancelled';

export interface MarketplaceLead {
  id: string;
  tradeCategory: TradeCategory;
  serviceType: ServiceType;
  urgency: UrgencyLevel;
  description: string;
  propertyAddress: string;
  status: LeadStatus;
  createdAt: string;
  bids: MarketplaceBid[];
}

export interface MarketplaceBid {
  id: string;
  leadId: string;
  contractorId: string;
  contractorName: string;
  contractorRating: number | null;
  bidAmount: number;
  estimatedTimeline: string | null;
  description: string | null;
  status: string;
  createdAt: string;
}

function mapLead(row: Record<string, unknown>): Omit<MarketplaceLead, 'bids'> {
  return {
    id: row.id as string,
    tradeCategory: row.trade_category as TradeCategory,
    serviceType: row.service_type as ServiceType,
    urgency: row.urgency as UrgencyLevel,
    description: row.description as string,
    propertyAddress: row.property_address as string,
    status: row.status as LeadStatus,
    createdAt: row.created_at as string,
  };
}

function mapBid(row: Record<string, unknown>): MarketplaceBid {
  const contractor = row.contractor_profiles as Record<string, unknown> | null;
  return {
    id: row.id as string,
    leadId: row.lead_id as string,
    contractorId: row.contractor_id as string,
    contractorName: contractor?.display_name as string || 'Contractor',
    contractorRating: contractor?.avg_rating as number | null,
    bidAmount: (row.bid_amount as number) || 0,
    estimatedTimeline: row.estimated_timeline as string | null,
    description: row.description as string | null,
    status: row.status as string,
    createdAt: row.created_at as string,
  };
}

const TRADE_OPTIONS: { value: TradeCategory; label: string }[] = [
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

const SERVICE_TYPE_OPTIONS: { value: ServiceType; label: string }[] = [
  { value: 'repair', label: 'Repair' },
  { value: 'replace', label: 'Replace' },
  { value: 'install', label: 'New Installation' },
  { value: 'inspect', label: 'Inspection' },
];

const URGENCY_OPTIONS: { value: UrgencyLevel; label: string; desc: string }[] = [
  { value: 'normal', label: 'Normal', desc: 'Within a few weeks' },
  { value: 'soon', label: 'Soon', desc: 'Within a week' },
  { value: 'urgent', label: 'Urgent', desc: 'Within 48 hours' },
  { value: 'emergency', label: 'Emergency', desc: 'ASAP' },
];

export function useQuotes() {
  const { user } = useAuth();
  const [leads, setLeads] = useState<MarketplaceLead[]>([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const fetchLeads = useCallback(async () => {
    if (!user) { setLoading(false); return; }
    const supabase = getSupabase();

    // Fetch leads for this homeowner
    const { data: leadRows } = await supabase
      .from('marketplace_leads')
      .select('*')
      .eq('homeowner_user_id', user.id)
      .order('created_at', { ascending: false });

    const mappedLeads = (leadRows || []).map(mapLead);

    if (mappedLeads.length === 0) {
      setLeads([]);
      setLoading(false);
      return;
    }

    // Fetch bids for all leads with contractor profiles
    const leadIds = mappedLeads.map((l: Omit<MarketplaceLead, 'bids'>) => l.id);
    const { data: bidRows } = await supabase
      .from('marketplace_bids')
      .select('*, contractor_profiles(display_name, avg_rating)')
      .in('lead_id', leadIds)
      .order('created_at', { ascending: false });

    const bids = (bidRows || []).map(mapBid);

    // Attach bids to leads
    const leadsWithBids: MarketplaceLead[] = mappedLeads.map((lead: Omit<MarketplaceLead, 'bids'>) => ({
      ...lead,
      bids: bids.filter((b: MarketplaceBid) => b.leadId === lead.id),
    }));

    setLeads(leadsWithBids);
    setLoading(false);
  }, [user]);

  useEffect(() => {
    fetchLeads();
    if (!user) return;

    const supabase = getSupabase();
    const channel = supabase.channel('marketplace-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'marketplace_leads' }, () => fetchLeads())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'marketplace_bids' }, () => fetchLeads())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchLeads, user]);

  // Submit a new quote request
  const submitQuoteRequest = async (input: {
    tradeCategory: TradeCategory;
    serviceType: ServiceType;
    urgency: UrgencyLevel;
    description: string;
    propertyAddress: string;
  }) => {
    if (!user) throw new Error('Not authenticated');
    setSubmitting(true);
    try {
      const supabase = getSupabase();
      const { error } = await supabase.from('marketplace_leads').insert({
        homeowner_user_id: user.id,
        homeowner_email: user.email,
        trade_category: input.tradeCategory,
        service_type: input.serviceType,
        urgency: input.urgency,
        description: input.description,
        property_address: input.propertyAddress,
        status: 'open',
      });
      if (error) throw error;
    } finally {
      setSubmitting(false);
    }
  };

  // Accept a bid
  const acceptBid = async (bidId: string, leadId: string) => {
    if (!user) throw new Error('Not authenticated');
    const supabase = getSupabase();
    // Update bid status
    const { error: bidErr } = await supabase.from('marketplace_bids')
      .update({ status: 'accepted' })
      .eq('id', bidId);
    if (bidErr) throw bidErr;
    // Update lead status
    const { error: leadErr } = await supabase.from('marketplace_leads')
      .update({ status: 'accepted' })
      .eq('id', leadId);
    if (leadErr) throw leadErr;
  };

  // Cancel a lead
  const cancelLead = async (leadId: string) => {
    if (!user) throw new Error('Not authenticated');
    const supabase = getSupabase();
    const { error } = await supabase.from('marketplace_leads')
      .update({ status: 'cancelled' })
      .eq('id', leadId);
    if (error) throw error;
  };

  return {
    leads,
    loading,
    submitting,
    submitQuoteRequest,
    acceptBid,
    cancelLead,
    refetch: fetchLeads,
    TRADE_OPTIONS,
    SERVICE_TYPE_OPTIONS,
    URGENCY_OPTIONS,
  };
}
