'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { createExpenseJournal, voidJournalEntry } from './use-zbooks-engine';

// ============================================================
// Expenses Hook — CRUD + approval workflow + receipt upload
// ============================================================

export interface ExpenseData {
  id: string;
  vendorId: string | null;
  vendorName: string | null;
  expenseDate: string;
  description: string;
  amount: number;
  taxAmount: number;
  total: number;
  category: string;
  accountId: string | null;
  jobId: string | null;
  jobTitle: string | null;
  paymentMethod: string;
  checkNumber: string | null;
  receiptUrl: string | null;
  receiptStoragePath: string | null;
  status: 'draft' | 'approved' | 'posted' | 'voided';
  approvedByUserId: string | null;
  approvedAt: string | null;
  journalEntryId: string | null;
  notes: string | null;
  createdByUserId: string | null;
  createdAt: string;
  propertyId: string | null;
  propertyAddress: string | null;
  scheduleECategory: string | null;
  propertyAllocationPct: number;
}

export const EXPENSE_CATEGORIES = [
  'materials', 'labor', 'fuel', 'tools', 'equipment', 'vehicle',
  'insurance', 'permits', 'advertising', 'office', 'utilities',
  'subcontractor', 'uncategorized',
] as const;

export const EXPENSE_CATEGORY_LABELS: Record<string, string> = {
  materials: 'Materials', labor: 'Labor', fuel: 'Fuel',
  tools: 'Tools', equipment: 'Equipment', vehicle: 'Vehicle',
  insurance: 'Insurance', permits: 'Permits', advertising: 'Advertising',
  office: 'Office', utilities: 'Utilities', subcontractor: 'Subcontractor',
  uncategorized: 'Uncategorized',
};

export const PAYMENT_METHODS = ['cash', 'check', 'credit_card', 'bank_transfer', 'other'] as const;
export const PAYMENT_METHOD_LABELS: Record<string, string> = {
  cash: 'Cash', check: 'Check', credit_card: 'Credit Card',
  bank_transfer: 'Bank Transfer', other: 'Other',
};

function mapExpense(row: Record<string, unknown>): ExpenseData {
  const vendor = row.vendors as Record<string, unknown> | null;
  const job = row.jobs as Record<string, unknown> | null;
  const property = row.properties as Record<string, unknown> | null;
  return {
    id: row.id as string,
    vendorId: row.vendor_id as string | null,
    vendorName: vendor?.vendor_name as string | null ?? null,
    expenseDate: row.expense_date as string,
    description: row.description as string,
    amount: Number(row.amount || 0),
    taxAmount: Number(row.tax_amount || 0),
    total: Number(row.total || 0),
    category: row.category as string,
    accountId: row.account_id as string | null,
    jobId: row.job_id as string | null,
    jobTitle: job?.title as string | null ?? null,
    paymentMethod: row.payment_method as string,
    checkNumber: row.check_number as string | null,
    receiptUrl: row.receipt_url as string | null,
    receiptStoragePath: row.receipt_storage_path as string | null,
    status: row.status as ExpenseData['status'],
    approvedByUserId: row.approved_by_user_id as string | null,
    approvedAt: row.approved_at as string | null,
    journalEntryId: row.journal_entry_id as string | null,
    notes: row.notes as string | null,
    createdByUserId: row.created_by_user_id as string | null,
    createdAt: row.created_at as string,
    propertyId: row.property_id as string | null,
    propertyAddress: property?.address_line1 as string | null ?? null,
    scheduleECategory: row.schedule_e_category as string | null,
    propertyAllocationPct: Number(row.property_allocation_pct ?? 100),
  };
}

export function useExpenses(filters?: {
  status?: string;
  category?: string;
  vendorId?: string;
  dateFrom?: string;
  dateTo?: string;
}) {
  const [expenses, setExpenses] = useState<ExpenseData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchExpenses = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      let query = supabase
        .from('expense_records')
        .select('*, vendors(vendor_name), jobs(title), properties(address_line1)')
        .is('deleted_at', null)
        .order('expense_date', { ascending: false });

      if (filters?.status) query = query.eq('status', filters.status);
      if (filters?.category) query = query.eq('category', filters.category);
      if (filters?.vendorId) query = query.eq('vendor_id', filters.vendorId);
      if (filters?.dateFrom) query = query.gte('expense_date', filters.dateFrom);
      if (filters?.dateTo) query = query.lte('expense_date', filters.dateTo);

      const { data, error: err } = await query;
      if (err) throw err;
      setExpenses((data || []).map((r: Record<string, unknown>) => mapExpense(r)));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load expenses');
    } finally {
      setLoading(false);
    }
  }, [filters?.status, filters?.category, filters?.vendorId, filters?.dateFrom, filters?.dateTo]);

  useEffect(() => {
    fetchExpenses();
  }, [fetchExpenses]);

  const createExpense = async (data: {
    vendorId?: string;
    expenseDate: string;
    description: string;
    amount: number;
    taxAmount?: number;
    category: string;
    accountId?: string;
    jobId?: string;
    propertyId?: string;
    scheduleECategory?: string;
    propertyAllocationPct?: number;
    paymentMethod: string;
    checkNumber?: string;
    notes?: string;
    receiptFile?: File;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const total = data.amount + (data.taxAmount || 0);

    // Upload receipt if provided
    let receiptStoragePath: string | null = null;
    let receiptUrl: string | null = null;
    if (data.receiptFile) {
      const ext = data.receiptFile.name.split('.').pop() || 'jpg';
      const path = `${companyId}/${Date.now()}.${ext}`;
      const { error: uploadErr } = await supabase.storage
        .from('receipts')
        .upload(path, data.receiptFile, { contentType: data.receiptFile.type });
      if (!uploadErr) {
        receiptStoragePath = path;
        const { data: urlData } = await supabase.storage
          .from('receipts')
          .createSignedUrl(path, 60 * 60 * 24 * 365);
        receiptUrl = urlData?.signedUrl || null;
      }
    }

    const { data: result, error: err } = await supabase
      .from('expense_records')
      .insert({
        company_id: companyId,
        vendor_id: data.vendorId || null,
        expense_date: data.expenseDate,
        description: data.description,
        amount: data.amount,
        tax_amount: data.taxAmount || 0,
        total,
        category: data.category,
        account_id: data.accountId || null,
        job_id: data.jobId || null,
        property_id: data.propertyId || null,
        schedule_e_category: data.scheduleECategory || null,
        property_allocation_pct: data.propertyAllocationPct ?? 100,
        payment_method: data.paymentMethod,
        check_number: data.checkNumber || null,
        receipt_storage_path: receiptStoragePath,
        receipt_url: receiptUrl,
        ocr_status: receiptStoragePath ? 'pending' : 'none',
        status: 'draft',
        notes: data.notes || null,
        created_by_user_id: user.id,
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchExpenses();
    return result.id;
  };

  const updateExpense = async (id: string, data: Partial<{
    vendorId: string | null;
    expenseDate: string;
    description: string;
    amount: number;
    taxAmount: number;
    category: string;
    accountId: string | null;
    jobId: string | null;
    paymentMethod: string;
    checkNumber: string | null;
    notes: string | null;
  }>) => {
    const supabase = getSupabase();
    const update: Record<string, unknown> = {};
    if (data.vendorId !== undefined) update.vendor_id = data.vendorId;
    if (data.expenseDate !== undefined) update.expense_date = data.expenseDate;
    if (data.description !== undefined) update.description = data.description;
    if (data.amount !== undefined) update.amount = data.amount;
    if (data.taxAmount !== undefined) update.tax_amount = data.taxAmount;
    if (data.category !== undefined) update.category = data.category;
    if (data.accountId !== undefined) update.account_id = data.accountId;
    if (data.jobId !== undefined) update.job_id = data.jobId;
    if (data.paymentMethod !== undefined) update.payment_method = data.paymentMethod;
    if (data.checkNumber !== undefined) update.check_number = data.checkNumber;
    if (data.notes !== undefined) update.notes = data.notes;

    // Recalculate total if amount or tax changed
    if (data.amount !== undefined || data.taxAmount !== undefined) {
      const amt = data.amount ?? 0;
      const tax = data.taxAmount ?? 0;
      update.total = amt + tax;
    }

    const { error: err } = await supabase.from('expense_records').update(update).eq('id', id);
    if (err) throw err;
    await fetchExpenses();
  };

  const approveExpense = async (id: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error: err } = await supabase
      .from('expense_records')
      .update({
        status: 'approved',
        approved_by_user_id: user.id,
        approved_at: new Date().toISOString(),
      })
      .eq('id', id);
    if (err) throw err;
    await fetchExpenses();
  };

  const postExpense = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('expense_records')
      .update({ status: 'posted' })
      .eq('id', id);
    if (err) throw err;

    // Auto-post journal entry
    await createExpenseJournal(id);
    await fetchExpenses();
  };

  const voidExpense = async (id: string, reason: string) => {
    const supabase = getSupabase();

    // Get journal entry to void
    const { data: expense } = await supabase
      .from('expense_records')
      .select('journal_entry_id')
      .eq('id', id)
      .single();

    if (expense?.journal_entry_id) {
      await voidJournalEntry(expense.journal_entry_id, reason);
    }

    const { error: err } = await supabase
      .from('expense_records')
      .update({ status: 'voided' })
      .eq('id', id);
    if (err) throw err;
    await fetchExpenses();
  };

  // Summary calculations
  const totalByCategory = expenses.reduce((acc, e) => {
    if (e.status !== 'voided') {
      acc[e.category] = (acc[e.category] || 0) + e.total;
    }
    return acc;
  }, {} as Record<string, number>);

  const grandTotal = expenses.filter((e) => e.status !== 'voided').reduce((s, e) => s + e.total, 0);

  return {
    expenses, loading, error,
    createExpense, updateExpense, approveExpense, postExpense, voidExpense,
    totalByCategory, grandTotal,
    refetch: fetchExpenses,
  };
}
