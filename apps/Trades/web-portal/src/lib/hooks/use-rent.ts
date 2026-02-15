'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import {
  mapRentCharge, mapRentPayment, mapGovernmentProgram, mapVerificationLog,
  type PaymentMethodType, type PaymentSource, type VerificationStatus,
} from './pm-mappers';
import type { RentChargeData, RentPaymentData, GovernmentProgramData, PaymentVerificationLogData } from './pm-mappers';

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
    paymentMethod: PaymentMethodType;
    stripePaymentIntentId?: string;
    processingFee?: number;
    feePaidBy?: RentPaymentData['feePaidBy'];
    notes?: string;
    paymentSource?: PaymentSource;
    sourceName?: string;
    sourceReference?: string;
    proofDocumentUrl?: string;
    paymentDate?: string;
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

    // Insert the payment record (owner-recorded = auto_verified)
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
        verification_status: 'auto_verified',
        payment_source: data.paymentSource || 'tenant',
        source_name: data.sourceName || null,
        source_reference: data.sourceReference || null,
        proof_document_url: data.proofDocumentUrl || null,
        payment_date: data.paymentDate || new Date().toISOString().split('T')[0],
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

  // ==================== PAYMENT VERIFICATION ====================

  const getPendingVerifications = async (): Promise<RentPaymentData[]> => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('rent_payments')
      .select('*, tenants(first_name, last_name)')
      .eq('verification_status', 'pending_verification')
      .order('created_at', { ascending: false });

    if (err) throw err;
    return (data || []).map(mapRentPayment);
  };

  const verifyPayment = async (paymentId: string, notes?: string): Promise<void> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;

    // Get the payment to find charge info
    const { data: payment, error: fetchErr } = await supabase
      .from('rent_payments')
      .select('rent_charge_id, amount, verification_status')
      .eq('id', paymentId)
      .single();
    if (fetchErr || !payment) throw fetchErr || new Error('Payment not found');

    const oldStatus = payment.verification_status;

    // Update payment to verified + completed
    const { error: updateErr } = await supabase
      .from('rent_payments')
      .update({
        verification_status: 'verified',
        verified_by: user.id,
        verified_at: new Date().toISOString(),
        verification_notes: notes || null,
        status: 'completed',
        paid_at: new Date().toISOString(),
      })
      .eq('id', paymentId);
    if (updateErr) throw updateErr;

    // Update rent_charge paid amount
    const { data: charge } = await supabase
      .from('rent_charges')
      .select('amount, paid_amount')
      .eq('id', payment.rent_charge_id)
      .single();

    if (charge) {
      const newPaid = (Number(charge.paid_amount) || 0) + Number(payment.amount);
      const chargeTotal = Number(charge.amount) || 0;
      await supabase.from('rent_charges').update({
        paid_amount: newPaid,
        status: newPaid >= chargeTotal ? 'paid' : 'partial',
        ...(newPaid >= chargeTotal ? { paid_at: new Date().toISOString() } : {}),
      }).eq('id', payment.rent_charge_id);
    }

    // Log to verification audit trail
    await supabase.from('payment_verification_log').insert({
      company_id: companyId,
      payment_id: paymentId,
      payment_context: 'rent',
      action: 'verified',
      performed_by: user.id,
      old_status: oldStatus,
      new_status: 'verified',
      notes: notes || null,
    });
  };

  const disputePayment = async (paymentId: string, notes: string): Promise<void> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;

    const { data: payment } = await supabase
      .from('rent_payments')
      .select('verification_status')
      .eq('id', paymentId)
      .single();

    await supabase.from('rent_payments').update({
      verification_status: 'disputed',
      verification_notes: notes,
    }).eq('id', paymentId);

    await supabase.from('payment_verification_log').insert({
      company_id: companyId,
      payment_id: paymentId,
      payment_context: 'rent',
      action: 'disputed',
      performed_by: user.id,
      old_status: payment?.verification_status || 'pending_verification',
      new_status: 'disputed',
      notes,
    });
  };

  const rejectPayment = async (paymentId: string, notes: string): Promise<void> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;

    const { data: payment } = await supabase
      .from('rent_payments')
      .select('verification_status')
      .eq('id', paymentId)
      .single();

    await supabase.from('rent_payments').update({
      verification_status: 'rejected',
      verified_by: user.id,
      verified_at: new Date().toISOString(),
      verification_notes: notes,
      status: 'failed',
    }).eq('id', paymentId);

    await supabase.from('payment_verification_log').insert({
      company_id: companyId,
      payment_id: paymentId,
      payment_context: 'rent',
      action: 'rejected',
      performed_by: user.id,
      old_status: payment?.verification_status || 'pending_verification',
      new_status: 'rejected',
      notes,
    });
  };

  const getVerificationLog = async (paymentId: string): Promise<PaymentVerificationLogData[]> => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('payment_verification_log')
      .select('*')
      .eq('payment_id', paymentId)
      .order('created_at', { ascending: false });
    if (err) throw err;
    return (data || []).map(mapVerificationLog);
  };

  // ==================== GOVERNMENT PROGRAMS ====================

  const getGovernmentPrograms = async (tenantId: string): Promise<GovernmentProgramData[]> => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('government_payment_programs')
      .select('*')
      .eq('tenant_id', tenantId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });
    if (err) throw err;
    return (data || []).map(mapGovernmentProgram);
  };

  const createGovernmentProgram = async (program: Omit<GovernmentProgramData, 'id' | 'companyId' | 'createdAt' | 'updatedAt'>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;

    const { data, error: err } = await supabase
      .from('government_payment_programs')
      .insert({
        company_id: companyId,
        tenant_id: program.tenantId,
        program_type: program.programType,
        program_name: program.programName,
        authority_name: program.authorityName,
        authority_contact_name: program.authorityContactName,
        authority_phone: program.authorityPhone,
        authority_email: program.authorityEmail,
        authority_address: program.authorityAddress,
        voucher_number: program.voucherNumber,
        hap_contract_number: program.hapContractNumber,
        monthly_hap_amount: program.monthlyHapAmount,
        tenant_portion: program.tenantPortion,
        utility_allowance: program.utilityAllowance,
        payment_standard: program.paymentStandard,
        effective_date: program.effectiveDate,
        expiration_date: program.expirationDate,
        recertification_date: program.recertificationDate,
        inspection_date: program.inspectionDate,
        next_inspection_date: program.nextInspectionDate,
        is_active: program.isActive,
        notes: program.notes,
      })
      .select('id')
      .single();
    if (err) throw err;
    return data.id;
  };

  const updateGovernmentProgram = async (programId: string, updates: Partial<GovernmentProgramData>): Promise<void> => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};
    if (updates.programType !== undefined) updateData.program_type = updates.programType;
    if (updates.programName !== undefined) updateData.program_name = updates.programName;
    if (updates.authorityName !== undefined) updateData.authority_name = updates.authorityName;
    if (updates.authorityContactName !== undefined) updateData.authority_contact_name = updates.authorityContactName;
    if (updates.authorityPhone !== undefined) updateData.authority_phone = updates.authorityPhone;
    if (updates.authorityEmail !== undefined) updateData.authority_email = updates.authorityEmail;
    if (updates.authorityAddress !== undefined) updateData.authority_address = updates.authorityAddress;
    if (updates.voucherNumber !== undefined) updateData.voucher_number = updates.voucherNumber;
    if (updates.hapContractNumber !== undefined) updateData.hap_contract_number = updates.hapContractNumber;
    if (updates.monthlyHapAmount !== undefined) updateData.monthly_hap_amount = updates.monthlyHapAmount;
    if (updates.tenantPortion !== undefined) updateData.tenant_portion = updates.tenantPortion;
    if (updates.utilityAllowance !== undefined) updateData.utility_allowance = updates.utilityAllowance;
    if (updates.paymentStandard !== undefined) updateData.payment_standard = updates.paymentStandard;
    if (updates.effectiveDate !== undefined) updateData.effective_date = updates.effectiveDate;
    if (updates.expirationDate !== undefined) updateData.expiration_date = updates.expirationDate;
    if (updates.recertificationDate !== undefined) updateData.recertification_date = updates.recertificationDate;
    if (updates.inspectionDate !== undefined) updateData.inspection_date = updates.inspectionDate;
    if (updates.nextInspectionDate !== undefined) updateData.next_inspection_date = updates.nextInspectionDate;
    if (updates.isActive !== undefined) updateData.is_active = updates.isActive;
    if (updates.notes !== undefined) updateData.notes = updates.notes;

    const { error: err } = await supabase
      .from('government_payment_programs')
      .update(updateData)
      .eq('id', programId);
    if (err) throw err;
  };

  const deactivateGovernmentProgram = async (programId: string): Promise<void> => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('government_payment_programs')
      .update({ is_active: false, deleted_at: new Date().toISOString() })
      .eq('id', programId);
    if (err) throw err;
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
    // Payment verification
    getPendingVerifications,
    verifyPayment,
    disputePayment,
    rejectPayment,
    getVerificationLog,
    // Government programs
    getGovernmentPrograms,
    createGovernmentProgram,
    updateGovernmentProgram,
    deactivateGovernmentProgram,
  };
}
