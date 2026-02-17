'use client';

// ZAFTO — BYOC Phone Hook
// Created: Sprint FIELD5 (Session 131)
//
// Manages Bring Your Own Carrier phone numbers.
// CRUD for company_phone_numbers table + verification flow.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// =============================================================================
// TYPES
// =============================================================================

export interface CompanyPhoneNumber {
  id: string;
  companyId: string;
  phoneNumber: string;
  displayLabel: string | null;
  verificationStatus: 'pending' | 'code_sent' | 'verified' | 'failed' | 'expired';
  forwardingType: 'sip_trunk' | 'call_forward' | 'port_in';
  carrierDetected: string | null;
  forwardingInstructions: string | null;
  forwardingTarget: string | null;
  portStatus: 'none' | 'requested' | 'foc_received' | 'porting' | 'complete' | 'rejected' | 'cancelled';
  portFocDate: string | null;
  portRequestId: string | null;
  callerIdName: string | null;
  callerIdRegistered: boolean;
  isActive: boolean;
  isPrimary: boolean;
  sipCredentials: SipCredentials | null;
  createdAt: string;
  updatedAt: string;
}

export interface SipCredentials {
  sip_endpoint: string;
  username: string;
  password: string;
  realm: string;
}

export interface AddPhoneNumberInput {
  phoneNumber: string;
  displayLabel?: string;
  forwardingType: 'sip_trunk' | 'call_forward' | 'port_in';
  carrierDetected?: string;
}

// =============================================================================
// CARRIER INSTRUCTIONS
// =============================================================================

export const CARRIER_FORWARDING_INSTRUCTIONS: Record<string, {
  name: string;
  forward: string;
  cancel: string;
}> = {
  verizon: {
    name: 'Verizon',
    forward: 'Dial *72, then enter your Zafto number, then press #',
    cancel: 'Dial *73 to cancel forwarding',
  },
  att: {
    name: 'AT&T',
    forward: 'Dial *72, then enter your Zafto number, then press #',
    cancel: 'Dial *73 to cancel forwarding',
  },
  tmobile: {
    name: 'T-Mobile',
    forward: 'Dial **21*[Zafto number]# and press Send',
    cancel: 'Dial ##21# and press Send to cancel',
  },
  spectrum: {
    name: 'Spectrum',
    forward: 'Dial *72, then enter your Zafto number, wait for confirmation tone',
    cancel: 'Dial *73 to cancel forwarding',
  },
  comcast: {
    name: 'Comcast/Xfinity',
    forward: 'Dial *72, then enter your Zafto number, then press #',
    cancel: 'Dial *73 to cancel forwarding',
  },
  other: {
    name: 'Other Carrier',
    forward: 'Dial *72, then enter your Zafto number (works for most carriers)',
    cancel: 'Dial *73 to cancel forwarding',
  },
};

// =============================================================================
// MAPPER
// =============================================================================

function mapRow(row: Record<string, unknown>): CompanyPhoneNumber {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    phoneNumber: row.phone_number as string,
    displayLabel: (row.display_label as string) || null,
    verificationStatus: (row.verification_status as CompanyPhoneNumber['verificationStatus']) || 'pending',
    forwardingType: (row.forwarding_type as CompanyPhoneNumber['forwardingType']) || 'call_forward',
    carrierDetected: (row.carrier_detected as string) || null,
    forwardingInstructions: (row.forwarding_instructions as string) || null,
    forwardingTarget: (row.forwarding_target as string) || null,
    portStatus: (row.port_status as CompanyPhoneNumber['portStatus']) || 'none',
    portFocDate: (row.port_foc_date as string) || null,
    portRequestId: (row.port_request_id as string) || null,
    callerIdName: (row.caller_id_name as string) || null,
    callerIdRegistered: (row.caller_id_registered as boolean) || false,
    isActive: (row.is_active as boolean) || false,
    isPrimary: (row.is_primary as boolean) || false,
    sipCredentials: row.sip_credentials as SipCredentials | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

// =============================================================================
// HOOK
// =============================================================================

export function useByocPhone() {
  const [numbers, setNumbers] = useState<CompanyPhoneNumber[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchNumbers = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { data, error: err } = await supabase
        .from('company_phone_numbers')
        .select('*')
        .eq('company_id', user.app_metadata?.company_id)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setNumbers((data || []).map((row: Record<string, unknown>) => mapRow(row)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load phone numbers');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchNumbers();
  }, [fetchNumbers]);

  // Realtime subscription
  useEffect(() => {
    const supabase = getSupabase();
    const channel = supabase
      .channel('byoc-phone-changes')
      .on(
        'postgres_changes' as 'system',
        {
          event: '*',
          schema: 'public',
          table: 'company_phone_numbers',
        } as Record<string, unknown>,
        () => {
          fetchNumbers();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchNumbers]);

  const addNumber = async (input: AddPhoneNumberInput): Promise<void> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Normalize phone to E.164
    let normalized = input.phoneNumber.replace(/[^\d+]/g, '');
    if (!normalized.startsWith('+')) {
      if (normalized.length === 10) normalized = `+1${normalized}`;
      else if (normalized.length === 11 && normalized.startsWith('1')) normalized = `+${normalized}`;
    }

    const carrier = input.carrierDetected || 'other';
    const instructions = CARRIER_FORWARDING_INSTRUCTIONS[carrier]?.forward || '';

    const { error: err } = await supabase.from('company_phone_numbers').insert({
      company_id: user.app_metadata?.company_id,
      phone_number: normalized,
      display_label: input.displayLabel || null,
      forwarding_type: input.forwardingType,
      carrier_detected: CARRIER_FORWARDING_INSTRUCTIONS[carrier]?.name || carrier,
      forwarding_instructions: instructions,
      verification_status: 'pending',
      is_primary: numbers.length === 0,
    });

    if (err) throw err;
    await fetchNumbers();
  };

  const sendVerification = async (numberId: string): Promise<void> => {
    const supabase = getSupabase();
    const code = String(100000 + Math.floor(Math.random() * 900000));

    const { error: err } = await supabase
      .from('company_phone_numbers')
      .update({
        verification_code: code,
        verification_status: 'code_sent',
        verification_sent_at: new Date().toISOString(),
      })
      .eq('id', numberId);

    if (err) throw err;
    await fetchNumbers();
    // In production, this would trigger an SMS via SignalWire EF
  };

  const verifyCode = async (numberId: string, code: string): Promise<boolean> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();

    const { data } = await supabase
      .from('company_phone_numbers')
      .select('verification_code')
      .eq('id', numberId)
      .single();

    if (data?.verification_code !== code) return false;

    const { error: err } = await supabase
      .from('company_phone_numbers')
      .update({
        verification_status: 'verified',
        verified_at: new Date().toISOString(),
        verified_by_user_id: user?.id,
        is_active: true,
      })
      .eq('id', numberId);

    if (err) throw err;
    await fetchNumbers();
    return true;
  };

  const deleteNumber = async (numberId: string): Promise<void> => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('company_phone_numbers')
      .update({
        deleted_at: new Date().toISOString(),
        is_active: false,
      })
      .eq('id', numberId);

    if (err) throw err;
    await fetchNumbers();
  };

  const updateCallerIdName = async (numberId: string, name: string): Promise<void> => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('company_phone_numbers')
      .update({
        caller_id_name: name.substring(0, 15), // CNAM limit: 15 chars
      })
      .eq('id', numberId);

    if (err) throw err;
    await fetchNumbers();
  };

  const setPrimaryNumber = async (numberId: string): Promise<void> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Unset current primary
    await supabase
      .from('company_phone_numbers')
      .update({ is_primary: false })
      .eq('company_id', user.app_metadata?.company_id)
      .eq('is_primary', true);

    // Set new primary
    const { error: err } = await supabase
      .from('company_phone_numbers')
      .update({ is_primary: true })
      .eq('id', numberId);

    if (err) throw err;
    await fetchNumbers();
  };

  return {
    numbers,
    loading,
    error,
    refetch: fetchNumbers,
    addNumber,
    sendVerification,
    verifyCode,
    deleteNumber,
    updateCallerIdName,
    setPrimaryNumber,
  };
}

// =============================================================================
// HELPERS
// =============================================================================

/** Format E.164 number for display: +1XXXXXXXXXX → (XXX) XXX-XXXX */
export function formatPhoneDisplay(phone: string): string {
  if (phone.startsWith('+1') && phone.length === 12) {
    return `(${phone.substring(2, 5)}) ${phone.substring(5, 8)}-${phone.substring(8)}`;
  }
  return phone;
}
