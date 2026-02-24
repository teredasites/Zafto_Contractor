'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Vendors Hook — CRUD + YTD payments + 1099 tracking
// ============================================================

export interface VendorData {
  id: string;
  vendorName: string;
  contactName: string | null;
  email: string | null;
  phone: string | null;
  address: string | null;
  city: string | null;
  state: string | null;
  zip: string | null;
  taxId: string | null;
  vendorType: string;
  defaultExpenseAccountId: string | null;
  is1099Eligible: boolean;
  paymentTerms: string;
  notes: string | null;
  isActive: boolean;
  createdAt: string;
  ytdPayments?: number;
}

export const VENDOR_TYPES = ['supplier', 'subcontractor', 'service_provider', 'utility', 'government'] as const;
export const VENDOR_TYPE_LABELS: Record<string, string> = {
  supplier: 'Supplier',
  subcontractor: 'Subcontractor',
  service_provider: 'Service Provider',
  utility: 'Utility',
  government: 'Government',
};

export const PAYMENT_TERMS = ['due_on_receipt', 'net_15', 'net_30', 'net_45', 'net_60'] as const;
export const PAYMENT_TERMS_LABELS: Record<string, string> = {
  due_on_receipt: 'Due on Receipt',
  net_15: 'Net 15',
  net_30: 'Net 30',
  net_45: 'Net 45',
  net_60: 'Net 60',
};

function mapVendor(row: Record<string, unknown>): VendorData {
  return {
    id: row.id as string,
    vendorName: row.vendor_name as string,
    contactName: row.contact_name as string | null,
    email: row.email as string | null,
    phone: row.phone as string | null,
    address: row.address as string | null,
    city: row.city as string | null,
    state: row.state as string | null,
    zip: row.zip as string | null,
    taxId: row.tax_id as string | null,
    vendorType: row.vendor_type as string,
    defaultExpenseAccountId: row.default_expense_account_id as string | null,
    is1099Eligible: row.is_1099_eligible as boolean,
    paymentTerms: row.payment_terms as string,
    notes: row.notes as string | null,
    isActive: row.is_active as boolean,
    createdAt: row.created_at as string,
  };
}

export function useVendors() {
  const [vendors, setVendors] = useState<VendorData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchVendors = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('vendors')
        .select('*')
        .is('deleted_at', null)
        .order('vendor_name');

      if (err) throw err;
      const mapped = (data || []).map((r: Record<string, unknown>) => mapVendor(r));

      // Fetch YTD payments per vendor
      const year = new Date().getFullYear();
      const startOfYear = `${year}-01-01`;
      const { data: paymentData } = await supabase
        .from('vendor_payments')
        .select('vendor_id, amount')
        .is('deleted_at', null)
        .gte('payment_date', startOfYear);

      const ytdMap = new Map<string, number>();
      for (const p of (paymentData || []) as { vendor_id: string; amount: number }[]) {
        ytdMap.set(p.vendor_id, (ytdMap.get(p.vendor_id) || 0) + Number(p.amount));
      }

      for (const v of mapped) {
        v.ytdPayments = ytdMap.get(v.id) || 0;
      }

      setVendors(mapped);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load vendors');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchVendors();
  }, [fetchVendors]);

  const createVendor = async (data: {
    vendorName: string;
    contactName?: string;
    email?: string;
    phone?: string;
    address?: string;
    city?: string;
    state?: string;
    zip?: string;
    taxId?: string;
    vendorType: string;
    defaultExpenseAccountId?: string;
    is1099Eligible?: boolean;
    paymentTerms?: string;
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('vendors')
      .insert({
        company_id: companyId,
        vendor_name: data.vendorName,
        contact_name: data.contactName || null,
        email: data.email || null,
        phone: data.phone || null,
        address: data.address || null,
        city: data.city || null,
        state: data.state || null,
        zip: data.zip || null,
        tax_id: data.taxId || null,
        vendor_type: data.vendorType,
        default_expense_account_id: data.defaultExpenseAccountId || null,
        is_1099_eligible: data.is1099Eligible ?? false,
        payment_terms: data.paymentTerms || 'net_30',
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchVendors();
    return result.id;
  };

  const updateVendor = async (id: string, data: Partial<{
    vendorName: string;
    contactName: string | null;
    email: string | null;
    phone: string | null;
    address: string | null;
    city: string | null;
    state: string | null;
    zip: string | null;
    taxId: string | null;
    vendorType: string;
    defaultExpenseAccountId: string | null;
    is1099Eligible: boolean;
    paymentTerms: string;
    notes: string | null;
    isActive: boolean;
  }>) => {
    const supabase = getSupabase();
    const update: Record<string, unknown> = {};
    if (data.vendorName !== undefined) update.vendor_name = data.vendorName;
    if (data.contactName !== undefined) update.contact_name = data.contactName;
    if (data.email !== undefined) update.email = data.email;
    if (data.phone !== undefined) update.phone = data.phone;
    if (data.address !== undefined) update.address = data.address;
    if (data.city !== undefined) update.city = data.city;
    if (data.state !== undefined) update.state = data.state;
    if (data.zip !== undefined) update.zip = data.zip;
    if (data.taxId !== undefined) update.tax_id = data.taxId;
    if (data.vendorType !== undefined) update.vendor_type = data.vendorType;
    if (data.defaultExpenseAccountId !== undefined) update.default_expense_account_id = data.defaultExpenseAccountId;
    if (data.is1099Eligible !== undefined) update.is_1099_eligible = data.is1099Eligible;
    if (data.paymentTerms !== undefined) update.payment_terms = data.paymentTerms;
    if (data.notes !== undefined) update.notes = data.notes;
    if (data.isActive !== undefined) update.is_active = data.isActive;

    const { error: err } = await supabase.from('vendors').update(update).eq('id', id);
    if (err) throw err;
    await fetchVendors();
  };

  const deleteVendor = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('vendors')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    await fetchVendors();
  };

  return { vendors, loading, error, createVendor, updateVendor, deleteVendor, refetch: fetchVendors };
}
