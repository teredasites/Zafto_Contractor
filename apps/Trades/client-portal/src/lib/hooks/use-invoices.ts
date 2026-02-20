'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import { mapInvoice, type InvoiceData } from './mappers';

export function useInvoices() {
  const { profile } = useAuth();
  const [invoices, setInvoices] = useState<InvoiceData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchInvoices = useCallback(async () => {
    if (!profile?.customerId) { setLoading(false); return; }
    const supabase = getSupabase();

    try {
      const { data, error: fetchError } = await supabase
        .from('invoices')
        .select('*, jobs(title)')
        .eq('customer_id', profile.customerId)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (fetchError) {
        setError(fetchError.message);
      } else {
        setInvoices((data || []).map(mapInvoice));
        setError(null);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load invoices');
    } finally {
      setLoading(false);
    }
  }, [profile?.customerId]);

  useEffect(() => {
    fetchInvoices();
    if (!profile?.customerId) return;

    const supabase = getSupabase();
    const channel = supabase.channel('client-invoices')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'invoices' }, () => fetchInvoices())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchInvoices, profile?.customerId]);

  const outstanding = invoices.filter((i: InvoiceData) => i.status === 'due' || i.status === 'overdue' || i.status === 'partial');
  const totalOwed = outstanding.reduce((sum: number, i: InvoiceData) => sum + i.amountDue, 0);

  return { invoices, loading, error, outstanding, totalOwed };
}

export function useInvoice(id: string) {
  const { profile } = useAuth();
  const [invoice, setInvoice] = useState<InvoiceData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetch() {
      if (!profile?.customerId) {
        setError('Not authenticated');
        setLoading(false);
        return;
      }
      const supabase = getSupabase();
      const { data, error: fetchError } = await supabase
        .from('invoices')
        .select('*, jobs(title)')
        .eq('id', id)
        .eq('customer_id', profile.customerId)
        .is('deleted_at', null)
        .single();

      if (fetchError) {
        setError(fetchError.message);
      } else if (data) {
        setInvoice(mapInvoice(data));
      }
      setLoading(false);
    }
    fetch();
  }, [id, profile?.customerId]);

  return { invoice, loading, error };
}
