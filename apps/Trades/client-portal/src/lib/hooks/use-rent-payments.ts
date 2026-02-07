'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import { useTenant } from './use-tenant';
import {
  mapRentCharge, mapRentPayment,
  type RentChargeData, type RentPaymentData,
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
  const [charge, setCharge] = useState<RentChargeData | null>(null);
  const [payments, setPayments] = useState<RentPaymentData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetch() {
      if (!user) { setLoading(false); return; }
      const supabase = getSupabase();

      const [chargeRes, paymentsRes] = await Promise.all([
        supabase.from('rent_charges').select('*').eq('id', chargeId).single(),
        supabase.from('rent_payments').select('*').eq('rent_charge_id', chargeId).order('created_at', { ascending: false }),
      ]);

      if (chargeRes.data) setCharge(mapRentCharge(chargeRes.data));
      setPayments((paymentsRes.data || []).map(mapRentPayment));
      setLoading(false);
    }
    fetch();
  }, [chargeId, user]);

  return { charge, payments, loading };
}
