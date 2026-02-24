'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ==================== TYPES ====================

export type TpaProgramStatus = 'active' | 'inactive' | 'suspended' | 'pending_approval';
export type TpaProgramType = 'national' | 'regional' | 'carrier_direct' | 'independent';
export type ReferralFeeType = 'percentage' | 'flat' | 'tiered' | 'none';

export interface TpaProgramData {
  id: string;
  companyId: string;
  createdByUserId: string | null;
  name: string;
  tpaType: TpaProgramType;
  carrierNames: string[];
  referralFeeType: ReferralFeeType;
  referralFeePct: number | null;
  referralFeeFlat: number | null;
  paymentTermsDays: number;
  overheadPct: number;
  profitPct: number;
  slaFirstContactMinutes: number;
  slaOnsiteMinutes: number;
  slaEstimateMinutes: number;
  slaCompletionDays: number;
  portalUrl: string | null;
  portalUsername: string | null;
  primaryContactName: string | null;
  primaryContactPhone: string | null;
  primaryContactEmail: string | null;
  secondaryContactName: string | null;
  secondaryContactPhone: string | null;
  secondaryContactEmail: string | null;
  serviceArea: string | null;
  tradeCategories: string[];
  lossTypesCovered: string[];
  notes: string | null;
  status: TpaProgramStatus;
  enrolledAt: string | null;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
}

// ==================== MAPPER ====================

function mapTpaProgram(row: Record<string, unknown>): TpaProgramData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    createdByUserId: (row.created_by_user_id as string) ?? null,
    name: row.name as string,
    tpaType: (row.tpa_type as TpaProgramType) ?? 'national',
    carrierNames: (row.carrier_names as string[]) ?? [],
    referralFeeType: (row.referral_fee_type as ReferralFeeType) ?? 'percentage',
    referralFeePct: row.referral_fee_pct != null ? Number(row.referral_fee_pct) : null,
    referralFeeFlat: row.referral_fee_flat != null ? Number(row.referral_fee_flat) : null,
    paymentTermsDays: Number(row.payment_terms_days ?? 30),
    overheadPct: Number(row.overhead_pct ?? 10),
    profitPct: Number(row.profit_pct ?? 10),
    slaFirstContactMinutes: Number(row.sla_first_contact_minutes ?? 120),
    slaOnsiteMinutes: Number(row.sla_onsite_minutes ?? 1440),
    slaEstimateMinutes: Number(row.sla_estimate_minutes ?? 1440),
    slaCompletionDays: Number(row.sla_completion_days ?? 5),
    portalUrl: (row.portal_url as string) ?? null,
    portalUsername: (row.portal_username as string) ?? null,
    primaryContactName: (row.primary_contact_name as string) ?? null,
    primaryContactPhone: (row.primary_contact_phone as string) ?? null,
    primaryContactEmail: (row.primary_contact_email as string) ?? null,
    secondaryContactName: (row.secondary_contact_name as string) ?? null,
    secondaryContactPhone: (row.secondary_contact_phone as string) ?? null,
    secondaryContactEmail: (row.secondary_contact_email as string) ?? null,
    serviceArea: (row.service_area as string) ?? null,
    tradeCategories: (row.trade_categories as string[]) ?? [],
    lossTypesCovered: (row.loss_types_covered as string[]) ?? [],
    notes: (row.notes as string) ?? null,
    status: (row.status as TpaProgramStatus) ?? 'active',
    enrolledAt: (row.enrolled_at as string) ?? null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
    deletedAt: (row.deleted_at as string) ?? null,
  };
}

// ==================== PROGRAMS LIST ====================

export function useTpaPrograms() {
  const supabase = getSupabase();
  const [programs, setPrograms] = useState<TpaProgramData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPrograms = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data, error: err } = await supabase
        .from('tpa_programs')
        .select('*')
        .is('deleted_at', null)
        .order('name', { ascending: true });

      if (err) throw err;
      setPrograms((data || []).map(mapTpaProgram));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load TPA programs');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPrograms();

    const channel = supabase
      .channel('tpa-programs-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tpa_programs' }, () => {
        fetchPrograms();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchPrograms]);

  return { programs, loading, error, refetch: fetchPrograms };
}

// ==================== SINGLE PROGRAM ====================

export function useTpaProgram(programId: string | null) {
  const supabase = getSupabase();
  const [program, setProgram] = useState<TpaProgramData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchProgram = useCallback(async () => {
    if (!programId) { setLoading(false); return; }
    setLoading(true);
    setError(null);
    try {
      const { data, error: err } = await supabase
        .from('tpa_programs')
        .select('*')
        .eq('id', programId)
        .is('deleted_at', null)
        .single();

      if (err) throw err;
      setProgram(data ? mapTpaProgram(data) : null);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load TPA program');
    } finally {
      setLoading(false);
    }
  }, [programId]);

  useEffect(() => {
    fetchProgram();

    if (!programId) return;
    const channel = supabase
      .channel(`tpa-program-${programId}-changes`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tpa_programs', filter: `id=eq.${programId}` }, () => {
        fetchProgram();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [programId, fetchProgram]);

  return { program, loading, error, refetch: fetchProgram };
}

// ==================== COMPANY FEATURES ====================

export function useCompanyFeatures() {
  const supabase = getSupabase();
  const [features, setFeatures] = useState<Record<string, boolean>>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let ignore = false;

    (async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user || ignore) return;

        const companyId = user.app_metadata?.company_id;
        if (!companyId) return;

        const { data } = await supabase
          .from('companies')
          .select('features')
          .eq('id', companyId)
          .single();

        if (!ignore && data?.features) {
          setFeatures(data.features as Record<string, boolean>);
        }
      } catch {
        // Graceful degradation — features default to empty (all modules hidden)
      } finally {
        if (!ignore) setLoading(false);
      }
    })();

    return () => { ignore = true; };
  }, []);

  return { features, loading, isTpaEnabled: features.tpa_enabled === true };
}

// ==================== MUTATIONS ====================

export async function createTpaProgram(input: {
  name: string;
  tpaType?: TpaProgramType;
  carrierNames?: string[];
  referralFeeType?: ReferralFeeType;
  referralFeePct?: number;
  referralFeeFlat?: number;
  paymentTermsDays?: number;
  overheadPct?: number;
  profitPct?: number;
  slaFirstContactMinutes?: number;
  slaOnsiteMinutes?: number;
  slaEstimateMinutes?: number;
  slaCompletionDays?: number;
  portalUrl?: string;
  portalUsername?: string;
  primaryContactName?: string;
  primaryContactPhone?: string;
  primaryContactEmail?: string;
  secondaryContactName?: string;
  secondaryContactPhone?: string;
  secondaryContactEmail?: string;
  serviceArea?: string;
  tradeCategories?: string[];
  lossTypesCovered?: string[];
  notes?: string;
}): Promise<string> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');
  const companyId = user.app_metadata?.company_id;
  if (!companyId) throw new Error('No company associated');

  const { data, error } = await supabase
    .from('tpa_programs')
    .insert({
      company_id: companyId,
      created_by_user_id: user.id,
      name: input.name,
      tpa_type: input.tpaType || 'national',
      carrier_names: input.carrierNames || [],
      referral_fee_type: input.referralFeeType || 'percentage',
      referral_fee_pct: input.referralFeePct ?? null,
      referral_fee_flat: input.referralFeeFlat ?? null,
      payment_terms_days: input.paymentTermsDays ?? 30,
      overhead_pct: input.overheadPct ?? 10,
      profit_pct: input.profitPct ?? 10,
      sla_first_contact_minutes: input.slaFirstContactMinutes ?? 120,
      sla_onsite_minutes: input.slaOnsiteMinutes ?? 1440,
      sla_estimate_minutes: input.slaEstimateMinutes ?? 1440,
      sla_completion_days: input.slaCompletionDays ?? 5,
      portal_url: input.portalUrl || null,
      portal_username: input.portalUsername || null,
      primary_contact_name: input.primaryContactName || null,
      primary_contact_phone: input.primaryContactPhone || null,
      primary_contact_email: input.primaryContactEmail || null,
      secondary_contact_name: input.secondaryContactName || null,
      secondary_contact_phone: input.secondaryContactPhone || null,
      secondary_contact_email: input.secondaryContactEmail || null,
      service_area: input.serviceArea || null,
      trade_categories: input.tradeCategories || [],
      loss_types_covered: input.lossTypesCovered || [],
      notes: input.notes || null,
      status: 'active',
      enrolled_at: new Date().toISOString(),
    })
    .select('id')
    .single();

  if (error) throw error;
  return data.id;
}

export async function updateTpaProgram(programId: string, updates: {
  name?: string;
  tpaType?: TpaProgramType;
  carrierNames?: string[];
  referralFeeType?: ReferralFeeType;
  referralFeePct?: number | null;
  referralFeeFlat?: number | null;
  paymentTermsDays?: number;
  overheadPct?: number;
  profitPct?: number;
  slaFirstContactMinutes?: number;
  slaOnsiteMinutes?: number;
  slaEstimateMinutes?: number;
  slaCompletionDays?: number;
  portalUrl?: string | null;
  portalUsername?: string | null;
  primaryContactName?: string | null;
  primaryContactPhone?: string | null;
  primaryContactEmail?: string | null;
  secondaryContactName?: string | null;
  secondaryContactPhone?: string | null;
  secondaryContactEmail?: string | null;
  serviceArea?: string | null;
  tradeCategories?: string[];
  lossTypesCovered?: string[];
  notes?: string | null;
  status?: TpaProgramStatus;
}): Promise<void> {
  const supabase = getSupabase();
  const updateData: Record<string, unknown> = {};

  if (updates.name !== undefined) updateData.name = updates.name;
  if (updates.tpaType !== undefined) updateData.tpa_type = updates.tpaType;
  if (updates.carrierNames !== undefined) updateData.carrier_names = updates.carrierNames;
  if (updates.referralFeeType !== undefined) updateData.referral_fee_type = updates.referralFeeType;
  if (updates.referralFeePct !== undefined) updateData.referral_fee_pct = updates.referralFeePct;
  if (updates.referralFeeFlat !== undefined) updateData.referral_fee_flat = updates.referralFeeFlat;
  if (updates.paymentTermsDays !== undefined) updateData.payment_terms_days = updates.paymentTermsDays;
  if (updates.overheadPct !== undefined) updateData.overhead_pct = updates.overheadPct;
  if (updates.profitPct !== undefined) updateData.profit_pct = updates.profitPct;
  if (updates.slaFirstContactMinutes !== undefined) updateData.sla_first_contact_minutes = updates.slaFirstContactMinutes;
  if (updates.slaOnsiteMinutes !== undefined) updateData.sla_onsite_minutes = updates.slaOnsiteMinutes;
  if (updates.slaEstimateMinutes !== undefined) updateData.sla_estimate_minutes = updates.slaEstimateMinutes;
  if (updates.slaCompletionDays !== undefined) updateData.sla_completion_days = updates.slaCompletionDays;
  if (updates.portalUrl !== undefined) updateData.portal_url = updates.portalUrl;
  if (updates.portalUsername !== undefined) updateData.portal_username = updates.portalUsername;
  if (updates.primaryContactName !== undefined) updateData.primary_contact_name = updates.primaryContactName;
  if (updates.primaryContactPhone !== undefined) updateData.primary_contact_phone = updates.primaryContactPhone;
  if (updates.primaryContactEmail !== undefined) updateData.primary_contact_email = updates.primaryContactEmail;
  if (updates.secondaryContactName !== undefined) updateData.secondary_contact_name = updates.secondaryContactName;
  if (updates.secondaryContactPhone !== undefined) updateData.secondary_contact_phone = updates.secondaryContactPhone;
  if (updates.secondaryContactEmail !== undefined) updateData.secondary_contact_email = updates.secondaryContactEmail;
  if (updates.serviceArea !== undefined) updateData.service_area = updates.serviceArea;
  if (updates.tradeCategories !== undefined) updateData.trade_categories = updates.tradeCategories;
  if (updates.lossTypesCovered !== undefined) updateData.loss_types_covered = updates.lossTypesCovered;
  if (updates.notes !== undefined) updateData.notes = updates.notes;
  if (updates.status !== undefined) updateData.status = updates.status;

  const { error } = await supabase.from('tpa_programs').update(updateData).eq('id', programId);
  if (error) throw error;
}

export async function deleteTpaProgram(programId: string): Promise<void> {
  const supabase = getSupabase();
  const { error } = await supabase
    .from('tpa_programs')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', programId);
  if (error) throw error;
}

// ==================== FEATURE FLAG TOGGLE ====================

export async function toggleTpaFeature(enabled: boolean): Promise<void> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');
  const companyId = user.app_metadata?.company_id;
  if (!companyId) throw new Error('No company associated');

  // Read current features, merge tpa_enabled
  const { data: company } = await supabase
    .from('companies')
    .select('features')
    .eq('id', companyId)
    .single();

  const currentFeatures = (company?.features as Record<string, unknown>) || {};
  const updatedFeatures = { ...currentFeatures, tpa_enabled: enabled };

  const { error } = await supabase
    .from('companies')
    .update({ features: updatedFeatures })
    .eq('id', companyId);

  if (error) throw error;
}
