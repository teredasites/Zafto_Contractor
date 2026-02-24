'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapCustomer, joinName } from './mappers';
import type { Customer } from '@/types';

export function useCustomers() {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchCustomers = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('customers')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setCustomers((data || []).map(mapCustomer));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load customers';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchCustomers();

    const supabase = getSupabase();
    const channel = supabase
      .channel('customers-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'customers' }, () => {
        fetchCustomers();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchCustomers]);

  const createCustomer = async (data: Partial<Customer>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('customers')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        name: joinName(data.firstName || '', data.lastName || ''),
        email: data.email || null,
        phone: data.phone || null,
        address: data.address?.street || null,
        city: data.address?.city || null,
        state: data.address?.state || null,
        zip_code: data.address?.zip || null,
        type: data.customerType || 'residential',
        tags: data.tags || [],
        notes: data.notes || null,
        referred_by: data.source || null,
        alternate_phone: data.alternatePhone || null,
        access_instructions: data.accessInstructions || null,
        email_opt_in: data.emailOptIn ?? true,
        sms_opt_in: data.smsOptIn ?? false,
      })
      .select('id')
      .single();

    if (err) throw err;
    fetchCustomers();
    return result.id;
  };

  const updateCustomer = async (id: string, data: Partial<Customer>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.firstName !== undefined || data.lastName !== undefined) {
      updateData.name = joinName(data.firstName || '', data.lastName || '');
    }
    if (data.email !== undefined) updateData.email = data.email;
    if (data.phone !== undefined) updateData.phone = data.phone;
    if (data.address) {
      updateData.address = data.address.street;
      updateData.city = data.address.city;
      updateData.state = data.address.state;
      updateData.zip_code = data.address.zip;
    }
    if (data.tags) updateData.tags = data.tags;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.alternatePhone !== undefined) updateData.alternate_phone = data.alternatePhone;
    if (data.accessInstructions !== undefined) updateData.access_instructions = data.accessInstructions;
    if (data.customerType !== undefined) updateData.type = data.customerType;
    if (data.preferredContactMethod !== undefined) updateData.preferred_contact_method = data.preferredContactMethod;
    if (data.emailOptIn !== undefined) updateData.email_opt_in = data.emailOptIn;
    if (data.smsOptIn !== undefined) updateData.sms_opt_in = data.smsOptIn;
    if (data.companyName !== undefined) updateData.company_name = data.companyName;

    const { error: err } = await supabase.from('customers').update(updateData).eq('id', id);
    if (err) throw err;
    fetchCustomers();
  };

  const deleteCustomer = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('customers')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    fetchCustomers();
  };

  const mergeCustomers = async (keepId: string, mergeId: string) => {
    const supabase = getSupabase();

    // Re-link all jobs, bids, invoices from mergeId to keepId
    const tables = [
      'jobs', 'bids', 'invoices', 'estimates', 'service_agreements',
      'phone_calls', 'phone_messages', 'emails', 'documents', 'site_surveys',
      'walkthroughs', 'properties',
    ];

    for (const table of tables) {
      try {
        await supabase.from(table).update({ customer_id: keepId }).eq('customer_id', mergeId);
      } catch {
        // Table may not exist — non-blocking
      }
    }

    // Merge tags from both customers
    const keep = customers.find(c => c.id === keepId);
    const merge = customers.find(c => c.id === mergeId);
    if (keep && merge) {
      const mergedTags = [...new Set([...keep.tags, ...merge.tags])];
      await supabase.from('customers').update({ tags: mergedTags }).eq('id', keepId);
    }

    // Soft-delete the merged customer
    await supabase.from('customers').update({ deleted_at: new Date().toISOString() }).eq('id', mergeId);

    fetchCustomers();
  };

  return { customers, loading, error, createCustomer, updateCustomer, deleteCustomer, mergeCustomers, refetch: fetchCustomers };
}

export function useCustomer(id: string | undefined) {
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [ver, setVer] = useState(0);

  useEffect(() => {
    if (!id) {
      setLoading(false);
      return;
    }

    let ignore = false;

    const fetchCustomer = async () => {
      try {
        setLoading(true);
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('customers')
          .select('*')
          .eq('id', id)
          .is('deleted_at', null)
          .single();

        if (ignore) return;
        if (err) throw err;
        setCustomer(data ? mapCustomer(data) : null);
      } catch (e: unknown) {
        if (ignore) return;
        const msg = e instanceof Error ? e.message : 'Customer not found';
        setError(msg);
      } finally {
        if (!ignore) setLoading(false);
      }
    };

    fetchCustomer();
    return () => { ignore = true; };
  }, [id, ver]);

  const refetch = useCallback(() => setVer((v) => v + 1), []);

  return { customer, loading, error, refetch };
}
