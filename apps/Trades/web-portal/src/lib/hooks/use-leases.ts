'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapLease, mapLeaseDocument } from './pm-mappers';
import type { LeaseData, LeaseDocumentData } from './pm-mappers';

export function useLeases() {
  const [leases, setLeases] = useState<LeaseData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchLeases = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('leases')
        .select('*, properties(address_line1), units(unit_number), tenants(first_name, last_name)')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setLeases((data || []).map(mapLease));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load leases';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchLeases();

    const supabase = getSupabase();
    const channel = supabase
      .channel('leases-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'leases' }, () => {
        fetchLeases();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchLeases]);

  const createLease = async (data: Partial<LeaseData>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    if (!data.propertyId) throw new Error('Property ID is required');
    if (!data.unitId) throw new Error('Unit ID is required');
    if (!data.tenantId) throw new Error('Tenant ID is required');

    const { data: result, error: err } = await supabase
      .from('leases')
      .insert({
        company_id: companyId,
        property_id: data.propertyId,
        unit_id: data.unitId,
        tenant_id: data.tenantId,
        lease_type: data.leaseType || 'fixed',
        start_date: data.startDate || new Date().toISOString().split('T')[0],
        end_date: data.endDate || null,
        rent_amount: data.rentAmount || 0,
        rent_due_day: data.rentDueDay || 1,
        deposit_amount: data.depositAmount || 0,
        deposit_held: data.depositHeld ?? false,
        grace_period_days: data.gracePeriodDays || 5,
        late_fee_type: data.lateFeeType || 'none',
        late_fee_amount: data.lateFeeAmount || 0,
        auto_renew: data.autoRenew ?? false,
        payment_processor_fee: data.paymentProcessorFee || 'landlord',
        partial_payments_allowed: data.partialPaymentsAllowed ?? true,
        auto_pay_required: data.autoPayRequired ?? false,
        terms_notes: data.termsNotes || null,
        status: data.status || 'draft',
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateLease = async (id: string, data: Partial<LeaseData>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.propertyId !== undefined) updateData.property_id = data.propertyId;
    if (data.unitId !== undefined) updateData.unit_id = data.unitId;
    if (data.tenantId !== undefined) updateData.tenant_id = data.tenantId;
    if (data.leaseType !== undefined) updateData.lease_type = data.leaseType;
    if (data.startDate !== undefined) updateData.start_date = data.startDate;
    if (data.endDate !== undefined) updateData.end_date = data.endDate;
    if (data.rentAmount !== undefined) updateData.rent_amount = data.rentAmount;
    if (data.rentDueDay !== undefined) updateData.rent_due_day = data.rentDueDay;
    if (data.depositAmount !== undefined) updateData.deposit_amount = data.depositAmount;
    if (data.depositHeld !== undefined) updateData.deposit_held = data.depositHeld;
    if (data.gracePeriodDays !== undefined) updateData.grace_period_days = data.gracePeriodDays;
    if (data.lateFeeType !== undefined) updateData.late_fee_type = data.lateFeeType;
    if (data.lateFeeAmount !== undefined) updateData.late_fee_amount = data.lateFeeAmount;
    if (data.autoRenew !== undefined) updateData.auto_renew = data.autoRenew;
    if (data.paymentProcessorFee !== undefined) updateData.payment_processor_fee = data.paymentProcessorFee;
    if (data.partialPaymentsAllowed !== undefined) updateData.partial_payments_allowed = data.partialPaymentsAllowed;
    if (data.autoPayRequired !== undefined) updateData.auto_pay_required = data.autoPayRequired;
    if (data.termsNotes !== undefined) updateData.terms_notes = data.termsNotes;
    if (data.status !== undefined) updateData.status = data.status;

    const { error: err } = await supabase.from('leases').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const terminateLease = async (id: string, reason: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();

    // Fetch lease details before terminating (need property_id, unit_id, tenant_id)
    const { data: lease } = await supabase
      .from('leases')
      .select('property_id, unit_id, tenant_id, company_id')
      .eq('id', id)
      .single();

    const { error: err } = await supabase
      .from('leases')
      .update({
        status: 'terminated',
        terminated_at: new Date().toISOString(),
        termination_reason: reason,
      })
      .eq('id', id);
    if (err) throw err;

    // Wire: lease termination → auto-create unit turn
    if (lease?.unit_id) {
      try {
        await supabase.from('unit_turns').insert({
          company_id: lease.company_id,
          property_id: lease.property_id,
          unit_id: lease.unit_id,
          previous_tenant_id: lease.tenant_id,
          move_out_date: new Date().toISOString().split('T')[0],
          status: 'pending',
          created_by_user_id: user?.id || null,
          notes: `Auto-created from lease termination: ${reason}`,
        });
      } catch {
        // Non-critical — lease still terminated even if unit turn fails
        console.error('Failed to auto-create unit turn from lease termination');
      }
    }
  };

  const getExpiringLeases = async (daysAhead: number): Promise<LeaseData[]> => {
    const supabase = getSupabase();
    const now = new Date();
    const futureDate = new Date(now.getTime() + daysAhead * 24 * 60 * 60 * 1000);

    const nowStr = now.toISOString().split('T')[0];
    const futureStr = futureDate.toISOString().split('T')[0];

    const { data, error: err } = await supabase
      .from('leases')
      .select('*, properties(address_line1), units(unit_number), tenants(first_name, last_name)')
      .eq('status', 'active')
      .is('deleted_at', null)
      .gte('end_date', nowStr)
      .lte('end_date', futureStr)
      .order('end_date', { ascending: true });

    if (err) throw err;
    return (data || []).map(mapLease);
  };

  const renewLease = async (id: string): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Fetch the current lease
    const { data: currentLease, error: fetchErr } = await supabase
      .from('leases')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchErr) throw fetchErr;
    if (!currentLease) throw new Error('Lease not found');

    // Mark current lease as renewed
    const { error: updateErr } = await supabase
      .from('leases')
      .update({ status: 'renewed' })
      .eq('id', id);

    if (updateErr) throw updateErr;

    // Calculate new dates: new start = old end + 1 day, new end = old end + original term length
    const oldStart = new Date(currentLease.start_date as string);
    const oldEnd = currentLease.end_date ? new Date(currentLease.end_date as string) : new Date();
    const termLengthMs = oldEnd.getTime() - oldStart.getTime();

    const newStart = new Date(oldEnd.getTime() + 24 * 60 * 60 * 1000);
    const newEnd = new Date(newStart.getTime() + termLengthMs);

    const newStartStr = newStart.toISOString().split('T')[0];
    const newEndStr = newEnd.toISOString().split('T')[0];

    // Create new lease with same terms + new dates
    const { data: newLease, error: insertErr } = await supabase
      .from('leases')
      .insert({
        company_id: companyId,
        property_id: currentLease.property_id,
        unit_id: currentLease.unit_id,
        tenant_id: currentLease.tenant_id,
        lease_type: currentLease.lease_type,
        start_date: newStartStr,
        end_date: newEndStr,
        rent_amount: currentLease.rent_amount,
        rent_due_day: currentLease.rent_due_day,
        deposit_amount: currentLease.deposit_amount,
        deposit_held: currentLease.deposit_held,
        grace_period_days: currentLease.grace_period_days,
        late_fee_type: currentLease.late_fee_type,
        late_fee_amount: currentLease.late_fee_amount,
        auto_renew: currentLease.auto_renew,
        payment_processor_fee: currentLease.payment_processor_fee,
        partial_payments_allowed: currentLease.partial_payments_allowed,
        auto_pay_required: currentLease.auto_pay_required,
        terms_notes: currentLease.terms_notes,
        status: 'active',
      })
      .select('id')
      .single();

    if (insertErr) throw insertErr;
    return newLease.id;
  };

  const getLeaseDocuments = async (leaseId: string): Promise<LeaseDocumentData[]> => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('lease_documents')
      .select('*')
      .eq('lease_id', leaseId)
      .order('created_at', { ascending: false });

    if (err) throw err;
    return (data || []).map(mapLeaseDocument);
  };

  const uploadLeaseDocument = async (leaseId: string, data: {
    documentType: LeaseDocumentData['documentType'];
    title: string;
    storagePath: string;
    signedByTenant?: boolean;
    signedByLandlord?: boolean;
    signedAt?: string;
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('lease_documents')
      .insert({
        company_id: companyId,
        lease_id: leaseId,
        document_type: data.documentType,
        title: data.title,
        storage_path: data.storagePath,
        signed_by_tenant: data.signedByTenant ?? false,
        signed_by_landlord: data.signedByLandlord ?? false,
        signed_at: data.signedAt || null,
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  return {
    leases,
    loading,
    error,
    createLease,
    updateLease,
    terminateLease,
    getExpiringLeases,
    renewLease,
    getLeaseDocuments,
    uploadLeaseDocument,
    refetch: fetchLeases,
  };
}

export function useLease(id: string | undefined) {
  const [lease, setLease] = useState<LeaseData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) {
      setLoading(false);
      return;
    }

    let ignore = false;

    const fetchLease = async () => {
      try {
        setLoading(true);
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('leases')
          .select('*, properties(address_line1), units(unit_number), tenants(first_name, last_name)')
          .eq('id', id)
          .single();

        if (ignore) return;
        if (err) throw err;
        setLease(data ? mapLease(data) : null);
      } catch (e: unknown) {
        if (ignore) return;
        const msg = e instanceof Error ? e.message : 'Lease not found';
        setError(msg);
      } finally {
        if (!ignore) setLoading(false);
      }
    };

    fetchLease();
    return () => { ignore = true; };
  }, [id]);

  return { lease, loading, error };
}
