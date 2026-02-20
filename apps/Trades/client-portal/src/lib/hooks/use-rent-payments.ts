'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import { useTenant } from './use-tenant';
import {
  mapRentCharge, mapRentPayment,
  type RentChargeData, type RentPaymentData,
  type PaymentMethodType,
} from './tenant-mappers';

export function useRentCharges() {
  const { user } = useAuth();
  const { tenant } = useTenant();
  const [charges, setCharges] = useState<RentChargeData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchCharges = useCallback(async () => {
    if (!user || !tenant) { setLoading(false); return; }
    const supabase = getSupabase();

    // RLS rent_charges_tenant filters by tenant's auth_user_id
    const { data } = await supabase
      .from('rent_charges')
      .select('*')
      .eq('tenant_id', tenant.id)
      .is('deleted_at', null)
      .order('due_date', { ascending: false });

    setCharges((data || []).map(mapRentCharge));
    setLoading(false);
  }, [user, tenant]);

  useEffect(() => {
    fetchCharges();
    if (!user || !tenant) return;

    const supabase = getSupabase();
    const channel = supabase.channel('tenant-rent-charges')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'rent_charges' }, () => fetchCharges())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchCharges, user, tenant]);

  // Compute balance
  const balance = charges
    .filter(c => c.status === 'pending' || c.status === 'partial' || c.status === 'overdue')
    .reduce((sum, c) => sum + (c.amount - c.paidAmount), 0);

  const overdueCount = charges.filter(c => c.status === 'overdue').length;

  return { charges, balance, overdueCount, loading, refresh: fetchCharges };
}

export function useRentPayments(chargeId: string) {
  const { user } = useAuth();
  const { tenant } = useTenant();
  const [charge, setCharge] = useState<RentChargeData | null>(null);
  const [payments, setPayments] = useState<RentPaymentData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetch() {
      if (!user) { setLoading(false); return; }
      const supabase = getSupabase();

      const [chargeRes, paymentsRes] = await Promise.all([
        supabase.from('rent_charges').select('*').eq('id', chargeId).is('deleted_at', null).single(),
        supabase.from('rent_payments').select('*').eq('rent_charge_id', chargeId).is('deleted_at', null).order('created_at', { ascending: false }),
      ]);

      if (chargeRes.data) setCharge(mapRentCharge(chargeRes.data));
      setPayments((paymentsRes.data || []).map(mapRentPayment));
      setLoading(false);
    }
    fetch();
  }, [chargeId, user]);

  // Report an offline payment (tenant self-report → pending verification)
  const reportPayment = async (report: {
    amount: number;
    paymentMethod: PaymentMethodType;
    paymentDate: string;
    reference?: string;
    proofUrl?: string;
    notes?: string;
  }): Promise<{ success: boolean; error?: string }> => {
    if (!user || !tenant || !charge) return { success: false, error: 'Not authenticated' };
    const supabase = getSupabase();

    const { error } = await supabase.from('rent_payments').insert({
      company_id: charge.companyId,
      rent_charge_id: chargeId,
      tenant_id: tenant.id,
      amount: report.amount,
      payment_method: report.paymentMethod,
      payment_date: report.paymentDate,
      source_reference: report.reference || null,
      proof_document_url: report.proofUrl || null,
      notes: report.notes || null,
      reported_by: user.id,
      verification_status: 'pending_verification',
      payment_source: 'tenant',
      status: 'pending',
    });

    if (error) return { success: false, error: error.message };

    // Refresh payments list
    const { data: refreshed } = await supabase
      .from('rent_payments')
      .select('*')
      .eq('rent_charge_id', chargeId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });
    if (refreshed) setPayments(refreshed.map(mapRentPayment));

    return { success: true };
  };

  // Upload proof document to storage
  const uploadProof = async (file: File): Promise<string | null> => {
    if (!user || !tenant) return null;
    const supabase = getSupabase();
    const ext = file.name.split('.').pop() || 'jpg';
    const path = `${tenant.id}/payment-proof/${Date.now()}.${ext}`;

    const { error } = await supabase.storage
      .from('receipts')
      .upload(path, file, { upsert: false });

    if (error) return null;

    const { data: urlData } = supabase.storage
      .from('receipts')
      .getPublicUrl(path);

    return urlData?.publicUrl || path;
  };

  return { charge, payments, loading, reportPayment, uploadProof };
}
