'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ────────────────────────────────────────────────────────
// Types — maps to W1 tables: home_equipment, warranty_claims,
// warranty_outreach_log, product_recalls
// ────────────────────────────────────────────────────────

export type WarrantyType = 'manufacturer' | 'extended' | 'labor' | 'parts_labor' | 'home_warranty';
export type RecallStatus = 'none' | 'active' | 'resolved';
export type ClaimStatus = 'submitted' | 'under_review' | 'approved' | 'denied' | 'resolved' | 'closed';
export type OutreachType = 'warranty_expiring' | 'maintenance_reminder' | 'recall_notice' | 'upsell_extended' | 'seasonal_check';
export type ResponseStatus = 'pending' | 'opened' | 'clicked' | 'booked' | 'declined' | 'no_response';
export type RecallSeverity = 'low' | 'medium' | 'high' | 'critical';

export interface EquipmentWarranty {
  id: string;
  companyId: string;
  customerId: string | null;
  name: string;
  manufacturer: string | null;
  modelNumber: string | null;
  serialNumber: string | null;
  warrantyStartDate: string | null;
  warrantyEndDate: string | null;
  warrantyType: WarrantyType | null;
  warrantyProvider: string | null;
  recallStatus: RecallStatus;
  installedByJobId: string | null;
  // Joined
  customerName: string | null;
  customerEmail: string | null;
  customerPhone: string | null;
  // Computed
  daysRemaining: number | null;
  warrantyStatus: 'active' | 'expiring_soon' | 'expired' | 'no_warranty';
}

export interface WarrantyClaim {
  id: string;
  companyId: string;
  equipmentId: string;
  jobId: string | null;
  claimDate: string;
  claimReason: string;
  claimStatus: ClaimStatus;
  manufacturerClaimNumber: string | null;
  amountClaimed: number | null;
  amountApproved: number | null;
  resolutionNotes: string | null;
  createdAt: string;
  // Joined
  equipmentName: string | null;
  customerName: string | null;
}

export interface OutreachLog {
  id: string;
  companyId: string;
  equipmentId: string;
  customerId: string;
  outreachType: OutreachType;
  outreachTrigger: string | null;
  messageContent: string | null;
  sentAt: string | null;
  responseStatus: ResponseStatus | null;
  resultingJobId: string | null;
  createdAt: string;
  // Joined
  equipmentName: string | null;
  customerName: string | null;
}

export interface ProductRecall {
  id: string;
  manufacturer: string;
  modelPattern: string | null;
  recallTitle: string;
  recallDescription: string | null;
  recallDate: string;
  severity: RecallSeverity;
  sourceUrl: string | null;
  affectedSerialRange: string | null;
  isActive: boolean;
  createdAt: string;
}

// ────────────────────────────────────────────────────────
// Mappers
// ────────────────────────────────────────────────────────

function computeWarrantyFields(endDate: string | null): { daysRemaining: number | null; warrantyStatus: EquipmentWarranty['warrantyStatus'] } {
  if (!endDate) return { daysRemaining: null, warrantyStatus: 'no_warranty' };
  const now = new Date();
  const expiry = new Date(endDate);
  const days = Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  if (days < 0) return { daysRemaining: days, warrantyStatus: 'expired' };
  if (days <= 90) return { daysRemaining: days, warrantyStatus: 'expiring_soon' };
  return { daysRemaining: days, warrantyStatus: 'active' };
}

function mapEquipment(row: Record<string, unknown>): EquipmentWarranty {
  const customer = row.customers as Record<string, unknown> | null;
  const endDate = row.warranty_end_date as string | null;
  const computed = computeWarrantyFields(endDate);
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    customerId: row.customer_id as string | null,
    name: (row.name as string) || 'Unknown Equipment',
    manufacturer: row.manufacturer as string | null,
    modelNumber: row.model_number as string | null,
    serialNumber: row.serial_number as string | null,
    warrantyStartDate: row.warranty_start_date as string | null,
    warrantyEndDate: endDate,
    warrantyType: row.warranty_type as WarrantyType | null,
    warrantyProvider: row.warranty_provider as string | null,
    recallStatus: (row.recall_status as RecallStatus) || 'none',
    installedByJobId: row.installed_by_job_id as string | null,
    customerName: customer?.name as string | null ?? null,
    customerEmail: customer?.email as string | null ?? null,
    customerPhone: customer?.phone as string | null ?? null,
    ...computed,
  };
}

function mapClaim(row: Record<string, unknown>): WarrantyClaim {
  const equipment = row.home_equipment as Record<string, unknown> | null;
  const customer = (equipment as Record<string, unknown> | null)?.customers as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    equipmentId: row.equipment_id as string,
    jobId: row.job_id as string | null,
    claimDate: row.claim_date as string,
    claimReason: row.claim_reason as string,
    claimStatus: (row.claim_status as ClaimStatus) || 'submitted',
    manufacturerClaimNumber: row.manufacturer_claim_number as string | null,
    amountClaimed: row.amount_claimed as number | null,
    amountApproved: row.amount_approved as number | null,
    resolutionNotes: row.resolution_notes as string | null,
    createdAt: row.created_at as string,
    equipmentName: equipment?.name as string | null ?? null,
    customerName: customer?.name as string | null ?? null,
  };
}

function mapOutreach(row: Record<string, unknown>): OutreachLog {
  const equipment = row.home_equipment as Record<string, unknown> | null;
  const customer = row.customers as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    equipmentId: row.equipment_id as string,
    customerId: row.customer_id as string,
    outreachType: row.outreach_type as OutreachType,
    outreachTrigger: row.outreach_trigger as string | null,
    messageContent: row.message_content as string | null,
    sentAt: row.sent_at as string | null,
    responseStatus: row.response_status as ResponseStatus | null,
    resultingJobId: row.resulting_job_id as string | null,
    createdAt: row.created_at as string,
    equipmentName: equipment?.name as string | null ?? null,
    customerName: customer?.name as string | null ?? null,
  };
}

function mapRecall(row: Record<string, unknown>): ProductRecall {
  return {
    id: row.id as string,
    manufacturer: row.manufacturer as string,
    modelPattern: row.model_pattern as string | null,
    recallTitle: row.recall_title as string,
    recallDescription: row.recall_description as string | null,
    recallDate: row.recall_date as string,
    severity: (row.severity as RecallSeverity) || 'medium',
    sourceUrl: row.source_url as string | null,
    affectedSerialRange: row.affected_serial_range as string | null,
    isActive: (row.is_active as boolean) ?? true,
    createdAt: row.created_at as string,
  };
}

// ────────────────────────────────────────────────────────
// Hook: useWarrantyIntelligence
// ────────────────────────────────────────────────────────

export function useWarrantyIntelligence() {
  const [equipment, setEquipment] = useState<EquipmentWarranty[]>([]);
  const [claims, setClaims] = useState<WarrantyClaim[]>([]);
  const [outreach, setOutreach] = useState<OutreachLog[]>([]);
  const [recalls, setRecalls] = useState<ProductRecall[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // ── Fetch all data ────────────────────────────────────
  const fetchAll = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const [eqRes, claimRes, outreachRes, recallRes] = await Promise.all([
        supabase
          .from('home_equipment')
          .select('*, customers(name, email, phone)')
          .is('deleted_at', null)
          .order('warranty_end_date', { ascending: true }),
        supabase
          .from('warranty_claims')
          .select('*, home_equipment(name, customers(name))')
          .is('deleted_at', null)
          .order('claim_date', { ascending: false }),
        supabase
          .from('warranty_outreach_log')
          .select('*, home_equipment(name), customers(name)')
          .order('created_at', { ascending: false })
          .limit(100),
        supabase
          .from('product_recalls')
          .select('*')
          .eq('is_active', true)
          .order('recall_date', { ascending: false }),
      ]);

      if (eqRes.error) throw eqRes.error;
      if (claimRes.error) throw claimRes.error;
      if (outreachRes.error) throw outreachRes.error;
      if (recallRes.error) throw recallRes.error;

      setEquipment((eqRes.data || []).map((r: Record<string, unknown>) => mapEquipment(r)));
      setClaims((claimRes.data || []).map((r: Record<string, unknown>) => mapClaim(r)));
      setOutreach((outreachRes.data || []).map((r: Record<string, unknown>) => mapOutreach(r)));
      setRecalls((recallRes.data || []).map((r: Record<string, unknown>) => mapRecall(r)));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load warranty data');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAll();

    // Real-time subscription for warranty claims updates
    const supabase = getSupabase();
    const channel = supabase
      .channel('warranty-intelligence')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'warranty_claims' }, () => fetchAll())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'warranty_outreach_log' }, () => fetchAll())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchAll]);

  // ── Computed stats ────────────────────────────────────
  const stats = useMemo(() => {
    const totalEquipment = equipment.length;
    const activeWarranties = equipment.filter(e => e.warrantyStatus === 'active').length;
    const expiringSoon = equipment.filter(e => e.warrantyStatus === 'expiring_soon').length;
    const expired = equipment.filter(e => e.warrantyStatus === 'expired').length;
    const noWarranty = equipment.filter(e => e.warrantyStatus === 'no_warranty').length;
    const activeRecalls = equipment.filter(e => e.recallStatus === 'active').length;
    const openClaims = claims.filter(c => c.claimStatus === 'submitted' || c.claimStatus === 'under_review').length;
    const approvedClaimValue = claims
      .filter(c => c.amountApproved != null)
      .reduce((sum, c) => sum + (c.amountApproved || 0), 0);
    const outreachBookedCount = outreach.filter(o => o.responseStatus === 'booked').length;
    const outreachPendingCount = outreach.filter(o => !o.sentAt || o.responseStatus === 'pending').length;

    return {
      totalEquipment,
      activeWarranties,
      expiringSoon,
      expired,
      noWarranty,
      activeRecalls,
      openClaims,
      approvedClaimValue,
      outreachBookedCount,
      outreachPendingCount,
    };
  }, [equipment, claims, outreach]);

  // ── Create claim ──────────────────────────────────────
  const createClaim = useCallback(async (data: {
    equipmentId: string;
    claimReason: string;
    amountClaimed?: number;
    jobId?: string;
  }) => {
    const supabase = getSupabase();
    const { error: err } = await supabase.from('warranty_claims').insert({
      equipment_id: data.equipmentId,
      claim_reason: data.claimReason,
      claim_status: 'submitted',
      claim_date: new Date().toISOString().split('T')[0],
      amount_claimed: data.amountClaimed ?? null,
      job_id: data.jobId ?? null,
    });
    if (err) throw new Error(err.message);
    await fetchAll();
  }, [fetchAll]);

  // ── Update claim status ───────────────────────────────
  const updateClaimStatus = useCallback(async (
    claimId: string,
    status: ClaimStatus,
    opts?: { resolutionNotes?: string; amountApproved?: number }
  ) => {
    const supabase = getSupabase();
    const updates: Record<string, unknown> = { claim_status: status };
    if (opts?.resolutionNotes) updates.resolution_notes = opts.resolutionNotes;
    if (opts?.amountApproved != null) updates.amount_approved = opts.amountApproved;
    const { error: err } = await supabase.from('warranty_claims').update(updates).eq('id', claimId);
    if (err) throw new Error(err.message);
    await fetchAll();
  }, [fetchAll]);

  // ── Log outreach manually ─────────────────────────────
  const logOutreach = useCallback(async (data: {
    equipmentId: string;
    customerId: string;
    outreachType: OutreachType;
    messageContent?: string;
  }) => {
    const supabase = getSupabase();
    const { error: err } = await supabase.from('warranty_outreach_log').insert({
      equipment_id: data.equipmentId,
      customer_id: data.customerId,
      outreach_type: data.outreachType,
      message_content: data.messageContent ?? null,
      outreach_trigger: 'manual',
      sent_at: new Date().toISOString(),
      response_status: 'pending',
    });
    if (err) throw new Error(err.message);
    await fetchAll();
  }, [fetchAll]);

  // ── Get equipment by ID ───────────────────────────────
  const getEquipmentById = useCallback((id: string) => {
    return equipment.find(e => e.id === id) ?? null;
  }, [equipment]);

  // ── Expiring equipment (next 90 days) sorted by urgency
  const expiringEquipment = useMemo(() => {
    return equipment
      .filter(e => e.warrantyStatus === 'expiring_soon')
      .sort((a, b) => (a.daysRemaining ?? 999) - (b.daysRemaining ?? 999));
  }, [equipment]);

  // ── Equipment with active recalls ─────────────────────
  const recalledEquipment = useMemo(() => {
    return equipment.filter(e => e.recallStatus === 'active');
  }, [equipment]);

  return {
    equipment,
    claims,
    outreach,
    recalls,
    loading,
    error,
    stats,
    expiringEquipment,
    recalledEquipment,
    createClaim,
    updateClaimStatus,
    logOutreach,
    getEquipmentById,
    refresh: fetchAll,
  };
}
