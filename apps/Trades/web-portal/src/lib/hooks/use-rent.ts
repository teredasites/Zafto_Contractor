'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapRentCharge, mapRentPayment } from './pm-mappers';
import type { RentChargeData, RentPaymentData } from './pm-mappers';

export interface RentRoll {
  totalDue: number;
  totalCollected: number;
  delinquentCount: number;
  outstandingBalance: number;
}

export function useRent() {
  const [charges, setCharges] = useState<RentChargeData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchCharges = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('rent_charges')
        .select('*, tenants(first_name, last_name), units(unit_number), properties(address_line1)')
        .order('due_date', { ascending: false });

      if (err) throw err;
      setCharges((data || []).map(mapRentCharge));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load rent charges';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchCharges();

    const supabase = getSupabase();
    const chargesChannel = supabase
      .channel('rent-charges-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'rent_charges' }, () => {
        fetchCharges();
      })
      .subscribe();

    const paymentsChannel = supabase
      .channel('rent-payments-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'rent_payments' }, () => {
        fetchCharges();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(chargesChannel);
      supabase.removeChannel(paymentsChannel);
    };
  }, [fetchCharges]);

  const createCharge = async (data: {
    leaseId: string;
    unitId: string;
    tenantId: string;
    propertyId: string;
    chargeType?: RentChargeData['chargeType'];
    description?: string;
    amount: number;
    dueDate: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('rent_charges')
      .insert({
        company_id: companyId,
        lease_id: data.leaseId,
        unit_id: data.unitId,
        tenant_id: data.tenantId,
        property_id: data.propertyId,
        charge_type: data.chargeType || 'rent',
        description: data.description || null,
        amount: data.amount,
        due_date: data.dueDate,
        status: 'pending',
        paid_amount: 0,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const recordPayment = async (chargeId: string, data: {
    tenantId: string;
    amount: number;
    paymentMethod: RentPaymentData['paymentMethod'];
    stripePaymentIntentId?: string;
    processingFee?: number;
    feePaidBy?: RentPaymentData['feePaidBy'];
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Fetch current charge to calculate new paid amount
    const { data: charge, error: fetchErr } = await supabase
      .from('rent_charges')
      .select('amount, paid_amount')
      .eq('id', chargeId)
      .single();

    if (fetchErr) throw fetchErr;
    if (!charge) throw new Error('Rent charge not found');

    const currentPaid = Number(charge.paid_amount) || 0;
    const totalAmount = Number(charge.amount) || 0;
    const newPaidAmount = currentPaid + data.amount;
    const newStatus: RentChargeData['status'] = newPaidAmount >= totalAmount ? 'paid' : 'partial';

    // Insert the payment record
    const { data: paymentResult, error: payErr } = await supabase
      .from('rent_payments')
      .insert({
        company_id: companyId,
        rent_charge_id: chargeId,
        tenant_id: data.tenantId,
        amount: data.amount,
        payment_method: data.paymentMethod,
        stripe_payment_intent_id: data.stripePaymentIntentId || null,
        processing_fee: data.processingFee || 0,
        fee_paid_by: data.feePaidBy || 'landlord',
        status: 'completed',
        paid_at: new Date().toISOString(),
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (payErr) throw payErr;

    // Update the charge with new paid amount and status
    const chargeUpdate: Record<string, unknown> = {
      paid_amount: newPaidAmount,
      status: newStatus,
    };
    if (newStatus === 'paid') {
      chargeUpdate.paid_at = new Date().toISOString();
    }

    const { error: updateErr } = await supabase
      .from('rent_charges')
      .update(chargeUpdate)
      .eq('id', chargeId);

    if (updateErr) throw updateErr;

    // Wire: rent payment → Ledger journal entry (debit Cash, credit Rental Income)
    try {
      // Fetch the charge's property for journal tagging
      const { data: fullCharge } = await supabase
        .from('rent_charges')
        .select('property_id, lease_id')
        .eq('id', chargeId)
        .single();

      // Find Cash and Rental Income accounts
      const { data: accounts } = await supabase
        .from('chart_of_accounts')
        .select('id, account_name, account_type')
        .eq('company_id', companyId)
        .in('account_name', ['Cash', 'Rental Income']);

      const cashAcct = accounts?.find((a: { account_name: string }) => a.account_name === 'Cash');
      const incomeAcct = accounts?.find((a: { account_name: string }) => a.account_name === 'Rental Income');

      if (cashAcct && incomeAcct) {
        const { data: je } = await supabase
          .from('journal_entries')
          .insert({
            company_id: companyId,
            entry_date: new Date().toISOString().split('T')[0],
            description: `Rent payment received — Charge ${chargeId}`,
            source: 'rent_payment',
            source_id: paymentResult.id,
            status: 'posted',
            created_by_user_id: user.id,
          })
          .select('id')
          .single();

        if (je) {
          await supabase.from('journal_entry_lines').insert([
            {
              journal_entry_id: je.id,
              account_id: cashAcct.id,
              debit: data.amount,
              credit: 0,
              description: 'Rent payment — Cash',
              property_id: fullCharge?.property_id || null,
            },
            {
              journal_entry_id: je.id,
              account_id: incomeAcct.id,
              debit: 0,
              credit: data.amount,
              description: 'Rent payment — Rental Income',
              property_id: fullCharge?.property_id || null,
            },
          ]);
        }
      }
    } catch {
      // Non-critical — payment still recorded even if journal fails
      console.error('Failed to create Ledger journal entry for rent payment');
    }

    return paymentResult.id;
  };

  const getPaymentsForCharge = async (chargeId: string): Promise<RentPaymentData[]> => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('rent_payments')
      .select('*')
      .eq('rent_charge_id', chargeId)
      .order('paid_at', { ascending: false });

    if (err) throw err;
    return (data || []).map(mapRentPayment);
  };

  const generateMonthlyCharges = async (propertyId: string, month: number, year: number): Promise<string[]> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Query active leases for this property
    const { data: activeLeases, error: leaseErr } = await supabase
      .from('leases')
      .select('id, tenant_id, unit_id, property_id, rent_amount, rent_due_day')
      .eq('property_id', propertyId)
      .eq('status', 'active')
      .is('deleted_at', null);

    if (leaseErr) throw leaseErr;
    if (!activeLeases || activeLeases.length === 0) return [];

    const chargeIds: string[] = [];

    for (const lease of activeLeases) {
      const dueDay = Number(lease.rent_due_day) || 1;
      // Clamp due day to valid range for the month
      const lastDayOfMonth = new Date(year, month, 0).getDate();
      const clampedDay = Math.min(dueDay, lastDayOfMonth);
      const dueDate = `${year}-${String(month).padStart(2, '0')}-${String(clampedDay).padStart(2, '0')}`;

      // Check if a charge already exists for this lease/month to prevent duplicates
      const { data: existing, error: checkErr } = await supabase
        .from('rent_charges')
        .select('id', { count: 'exact', head: true })
        .eq('lease_id', lease.id)
        .eq('charge_type', 'rent')
        .eq('due_date', dueDate);

      if (checkErr) throw checkErr;
      if (existing && existing.length > 0) continue; // Already generated

      const { data: result, error: insertErr } = await supabase
        .from('rent_charges')
        .insert({
          company_id: companyId,
          lease_id: lease.id,
          unit_id: lease.unit_id,
          tenant_id: lease.tenant_id,
          property_id: lease.property_id,
          charge_type: 'rent',
          description: `Rent for ${String(month).padStart(2, '0')}/${year}`,
          amount: Number(lease.rent_amount) || 0,
          due_date: dueDate,
          status: 'pending',
          paid_amount: 0,
        })
        .select('id')
        .single();

      if (insertErr) throw insertErr;
      chargeIds.push(result.id);
    }

    return chargeIds;
  };

  const getOverdueCharges = async (): Promise<RentChargeData[]> => {
    const supabase = getSupabase();
    const nowStr = new Date().toISOString().split('T')[0];

    const { data, error: err } = await supabase
      .from('rent_charges')
      .select('*, tenants(first_name, last_name), units(unit_number), properties(address_line1)')
      .lt('due_date', nowStr)
      .inFilter('status', ['pending', 'partial'])
      .order('due_date', { ascending: true });

    if (err) throw err;
    return (data || []).map(mapRentCharge);
  };

  const getRentRoll = async (propertyId?: string): Promise<RentRoll> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    let query = supabase
      .from('rent_charges')
      .select('amount, paid_amount, status, due_date')
      .eq('company_id', companyId);

    if (propertyId) {
      query = query.eq('property_id', propertyId);
    }

    const { data, error: err } = await query;
    if (err) throw err;

    const rows = data || [];
    const nowStr = new Date().toISOString().split('T')[0];

    const totalDue = rows.reduce(
      (sum: number, r: { amount: number }) => sum + (Number(r.amount) || 0),
      0
    );

    const totalCollected = rows.reduce(
      (sum: number, r: { paid_amount: number }) => sum + (Number(r.paid_amount) || 0),
      0
    );

    const delinquentCount = rows.filter(
      (r: { status: string; due_date: string }) =>
        (r.status === 'pending' || r.status === 'partial') && r.due_date < nowStr
    ).length;

    const outstandingBalance = totalDue - totalCollected;

    return {
      totalDue,
      totalCollected,
      delinquentCount,
      outstandingBalance: Math.max(0, outstandingBalance),
    };
  };

  return {
    charges,
    loading,
    error,
    createCharge,
    recordPayment,
    getPaymentsForCharge,
    generateMonthlyCharges,
    getOverdueCharges,
    getRentRoll,
    refetch: fetchCharges,
  };
}
