'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Chart of Accounts Hook — CRUD + balance queries
// ============================================================

export interface AccountData {
  id: string;
  accountNumber: string;
  accountName: string;
  accountType: string;
  normalBalance: string;
  parentAccountId: string | null;
  taxCategoryId: string | null;
  description: string | null;
  isActive: boolean;
  isSystem: boolean;
  sortOrder: number;
  createdAt: string;
}

export interface TaxCategoryData {
  id: string;
  name: string;
  scheduleLineRef: string | null;
  formType: string;
}

const ACCOUNT_TYPES = ['asset', 'liability', 'equity', 'revenue', 'cogs', 'expense'] as const;
export type AccountType = typeof ACCOUNT_TYPES[number];

export const ACCOUNT_TYPE_LABELS: Record<string, string> = {
  asset: 'Assets',
  liability: 'Liabilities',
  equity: 'Equity',
  revenue: 'Revenue',
  cogs: 'Cost of Goods Sold',
  expense: 'Expenses',
};

export function useAccounts() {
  const [accounts, setAccounts] = useState<AccountData[]>([]);
  const [taxCategories, setTaxCategories] = useState<TaxCategoryData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAccounts = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('chart_of_accounts')
        .select('*')
        .order('sort_order');

      if (err) throw err;

      const typed = (data || []) as {
        id: string; account_number: string; account_name: string;
        account_type: string; normal_balance: string; parent_account_id: string | null;
        tax_category_id: string | null; description: string | null;
        is_active: boolean; is_system: boolean; sort_order: number; created_at: string;
      }[];

      setAccounts(typed.map((row) => ({
        id: row.id,
        accountNumber: row.account_number,
        accountName: row.account_name,
        accountType: row.account_type,
        normalBalance: row.normal_balance,
        parentAccountId: row.parent_account_id,
        taxCategoryId: row.tax_category_id,
        description: row.description,
        isActive: row.is_active,
        isSystem: row.is_system,
        sortOrder: row.sort_order,
        createdAt: row.created_at,
      })));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load accounts');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchTaxCategories = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('tax_categories')
        .select('id, name, schedule_line_ref, form_type')
        .order('name');

      const typed = (data || []) as { id: string; name: string; schedule_line_ref: string | null; form_type: string }[];
      setTaxCategories(typed.map((row) => ({
        id: row.id,
        name: row.name,
        scheduleLineRef: row.schedule_line_ref,
        formType: row.form_type,
      })));
    } catch (_) {
      // Non-critical
    }
  }, []);

  useEffect(() => {
    fetchAccounts();
    fetchTaxCategories();
  }, [fetchAccounts, fetchTaxCategories]);

  const createAccount = async (data: {
    accountNumber: string;
    accountName: string;
    accountType: string;
    normalBalance: string;
    parentAccountId?: string | null;
    taxCategoryId?: string | null;
    description?: string | null;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Auto-calculate sort_order: max existing + 10
    const maxSort = accounts.reduce((max, a) => Math.max(max, a.sortOrder), 0);

    const { data: result, error: err } = await supabase
      .from('chart_of_accounts')
      .insert({
        company_id: companyId,
        account_number: data.accountNumber,
        account_name: data.accountName,
        account_type: data.accountType,
        normal_balance: data.normalBalance,
        parent_account_id: data.parentAccountId || null,
        tax_category_id: data.taxCategoryId || null,
        description: data.description || null,
        is_system: false,
        sort_order: maxSort + 10,
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchAccounts();
    return result.id;
  };

  const updateAccount = async (id: string, data: {
    accountName?: string;
    description?: string | null;
    taxCategoryId?: string | null;
    isActive?: boolean;
  }) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.accountName !== undefined) updateData.account_name = data.accountName;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.taxCategoryId !== undefined) updateData.tax_category_id = data.taxCategoryId;
    if (data.isActive !== undefined) updateData.is_active = data.isActive;

    const { error: err } = await supabase
      .from('chart_of_accounts')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;
    await fetchAccounts();
  };

  const checkAccountHasEntries = async (accountId: string): Promise<boolean> => {
    const supabase = getSupabase();
    const { count } = await supabase
      .from('journal_entry_lines')
      .select('*', { count: 'exact', head: true })
      .eq('account_id', accountId);

    return (count || 0) > 0;
  };

  const deactivateAccount = async (id: string) => {
    const hasEntries = await checkAccountHasEntries(id);
    if (hasEntries) {
      throw new Error('Cannot deactivate an account with journal entries. The account has existing transactions.');
    }
    await updateAccount(id, { isActive: false });
  };

  const reactivateAccount = async (id: string) => {
    await updateAccount(id, { isActive: true });
  };

  // Group accounts by type
  const groupedAccounts = ACCOUNT_TYPES.reduce((groups, type) => {
    groups[type] = accounts.filter((a) => a.accountType === type);
    return groups;
  }, {} as Record<string, AccountData[]>);

  return {
    accounts,
    groupedAccounts,
    taxCategories,
    loading,
    error,
    createAccount,
    updateAccount,
    deactivateAccount,
    reactivateAccount,
    checkAccountHasEntries,
    refetch: fetchAccounts,
  };
}
