'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface FaxRecord {
  id: string;
  companyId: string;
  direction: 'inbound' | 'outbound';
  fromNumber: string;
  toNumber: string;
  fromUserId: string | null;
  customerId: string | null;
  customerName?: string;
  jobId: string | null;
  jobTitle?: string;
  pages: number;
  documentPath: string | null;
  documentUrl: string | null;
  sourceType: string | null;
  sourceId: string | null;
  status: string;
  errorMessage: string | null;
  createdAt: string;
}

function mapFax(row: Record<string, unknown>): FaxRecord {
  const customer = row.customers as Record<string, unknown> | null;
  const job = row.jobs as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    direction: row.direction as FaxRecord['direction'],
    fromNumber: row.from_number as string,
    toNumber: row.to_number as string,
    fromUserId: (row.from_user_id as string) || null,
    customerId: (row.customer_id as string) || null,
    customerName: (customer?.name as string) || undefined,
    jobId: (row.job_id as string) || null,
    jobTitle: (job?.title as string) || undefined,
    pages: (row.pages as number) || 0,
    documentPath: (row.document_path as string) || null,
    documentUrl: (row.document_url as string) || null,
    sourceType: (row.source_type as string) || null,
    sourceId: (row.source_id as string) || null,
    status: row.status as string,
    errorMessage: (row.error_message as string) || null,
    createdAt: row.created_at as string,
  };
}

export function useFax() {
  const [faxes, setFaxes] = useState<FaxRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchFaxes = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('phone_faxes')
        .select('*, customers(name), jobs(title)')
        .order('created_at', { ascending: false })
        .limit(100);

      if (err) throw err;
      setFaxes((data || []).map(mapFax));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load faxes';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchFaxes();

    const supabase = getSupabase();
    const channel = supabase
      .channel('fax-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_faxes' }, () => fetchFaxes())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchFaxes]);

  const sendFax = async (toNumber: string, documentUrl: string, opts?: {
    customerId?: string;
    jobId?: string;
    sourceType?: string;
    sourceId?: string;
  }) => {
    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) throw new Error('Not authenticated');

    const response = await supabase.functions.invoke('signalwire-fax', {
      body: {
        action: 'send',
        toNumber,
        documentUrl,
        customerId: opts?.customerId,
        jobId: opts?.jobId,
        sourceType: opts?.sourceType,
        sourceId: opts?.sourceId,
      },
    });

    if (response.error) throw new Error(response.error.message);
    return response.data;
  };

  const inbound = faxes.filter(f => f.direction === 'inbound');
  const outbound = faxes.filter(f => f.direction === 'outbound');

  return { faxes, inbound, outbound, loading, error, refetch: fetchFaxes, sendFax };
}
