'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Banking hook — Plaid-connected bank accounts + transactions
// Calls Edge Functions for Plaid API operations (server-side)
// ============================================================

export interface BankAccountData {
  id: string;
  accountName: string;
  institutionName: string | null;
  accountType: 'checking' | 'savings' | 'credit_card';
  mask: string | null;
  currentBalance: number;
  availableBalance: number | null;
  lastSyncedAt: string | null;
  isActive: boolean;
  createdAt: string;
}

export interface BankTransactionData {
  id: string;
  bankAccountId: string;
  transactionDate: string;
  postedDate: string | null;
  description: string;
  merchantName: string | null;
  amount: number;
  category: string;
  categoryConfidence: number | null;
  isIncome: boolean;
  matchedInvoiceId: string | null;
  matchedExpenseId: string | null;
  isReviewed: boolean;
  isReconciled: boolean;
  notes: string | null;
}

const ACCOUNT_TYPE_LABELS: Record<string, string> = {
  checking: 'Checking',
  savings: 'Savings',
  credit_card: 'Credit Card',
};

const CATEGORY_LABELS: Record<string, string> = {
  materials: 'Materials',
  labor: 'Labor',
  fuel: 'Fuel',
  tools: 'Tools',
  equipment: 'Equipment',
  vehicle: 'Vehicle',
  insurance: 'Insurance',
  permits: 'Permits',
  advertising: 'Advertising',
  office: 'Office',
  utilities: 'Utilities',
  subcontractor: 'Subcontractor',
  income: 'Income',
  refund: 'Refund',
  transfer: 'Transfer',
  uncategorized: 'Uncategorized',
};

export { ACCOUNT_TYPE_LABELS, CATEGORY_LABELS };

function mapAccountFromDb(row: Record<string, unknown>): BankAccountData {
  return {
    id: row.id as string,
    accountName: row.account_name as string,
    institutionName: row.institution_name as string | null,
    accountType: row.account_type as 'checking' | 'savings' | 'credit_card',
    mask: row.mask as string | null,
    currentBalance: Number(row.current_balance) || 0,
    availableBalance: row.available_balance != null ? Number(row.available_balance) : null,
    lastSyncedAt: row.last_synced_at as string | null,
    isActive: row.is_active as boolean,
    createdAt: row.created_at as string,
  };
}

function mapTransactionFromDb(row: Record<string, unknown>): BankTransactionData {
  return {
    id: row.id as string,
    bankAccountId: row.bank_account_id as string,
    transactionDate: row.transaction_date as string,
    postedDate: row.posted_date as string | null,
    description: row.description as string,
    merchantName: row.merchant_name as string | null,
    amount: Number(row.amount) || 0,
    category: row.category as string,
    categoryConfidence: row.category_confidence != null ? Number(row.category_confidence) : null,
    isIncome: row.is_income as boolean,
    matchedInvoiceId: row.matched_invoice_id as string | null,
    matchedExpenseId: row.matched_expense_id as string | null,
    isReviewed: row.is_reviewed as boolean,
    isReconciled: row.is_reconciled as boolean,
    notes: row.notes as string | null,
  };
}

export function useBanking() {
  const [accounts, setAccounts] = useState<BankAccountData[]>([]);
  const [transactions, setTransactions] = useState<BankTransactionData[]>([]);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState<string | null>(null);

  const supabase = getSupabase();

  const fetchAccounts = useCallback(async () => {
    // Use bank_accounts_safe view (excludes plaid_access_token)
    const { data, error } = await supabase
      .from('bank_accounts_safe')
      .select('*')
      .eq('is_active', true)
      .order('created_at', { ascending: true });

    if (!error && data) {
      setAccounts(data.map((row: Record<string, unknown>) => mapAccountFromDb(row)));
    }
  }, [supabase]);

  const fetchTransactions = useCallback(async (bankAccountId?: string) => {
    let query = supabase
      .from('bank_transactions')
      .select('*')
      .order('transaction_date', { ascending: false })
      .limit(200);

    if (bankAccountId) {
      query = query.eq('bank_account_id', bankAccountId);
    }

    const { data, error } = await query;
    if (!error && data) {
      setTransactions(data.map((row: Record<string, unknown>) => mapTransactionFromDb(row)));
    }
  }, [supabase]);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      await Promise.all([fetchAccounts(), fetchTransactions()]);
      setLoading(false);
    };
    load();
  }, [fetchAccounts, fetchTransactions]);

  // Create Plaid Link token (calls Edge Function)
  const createLinkToken = useCallback(async (): Promise<string | null> => {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return null;

    const res = await supabase.functions.invoke('plaid-create-link-token', {
      headers: { Authorization: `Bearer ${session.access_token}` },
    });

    if (res.error || !res.data?.link_token) {
      console.error('Failed to create link token:', res.error);
      return null;
    }

    return res.data.link_token as string;
  }, [supabase]);

  // Exchange public token after Plaid Link success
  const exchangeToken = useCallback(async (
    publicToken: string,
    institution: { name: string; institution_id: string } | null
  ): Promise<boolean> => {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return false;

    const res = await supabase.functions.invoke('plaid-exchange-token', {
      headers: { Authorization: `Bearer ${session.access_token}` },
      body: { public_token: publicToken, institution },
    });

    if (res.error) {
      console.error('Token exchange failed:', res.error);
      return false;
    }

    await fetchAccounts();
    return true;
  }, [supabase, fetchAccounts]);

  // Sync transactions for a bank account
  const syncTransactions = useCallback(async (bankAccountId: string): Promise<{ synced: number; matched: number } | null> => {
    setSyncing(bankAccountId);
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      setSyncing(null);
      return null;
    }

    const res = await supabase.functions.invoke('plaid-sync-transactions', {
      headers: { Authorization: `Bearer ${session.access_token}` },
      body: { bank_account_id: bankAccountId },
    });

    setSyncing(null);

    if (res.error) {
      console.error('Sync failed:', res.error);
      return null;
    }

    await Promise.all([fetchAccounts(), fetchTransactions(bankAccountId)]);
    return {
      synced: res.data?.transactions_synced || 0,
      matched: res.data?.invoices_matched || 0,
    };
  }, [supabase, fetchAccounts, fetchTransactions]);

  // Refresh balance for a bank account
  const refreshBalance = useCallback(async (bankAccountId: string): Promise<boolean> => {
    setSyncing(bankAccountId);
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      setSyncing(null);
      return false;
    }

    const res = await supabase.functions.invoke('plaid-get-balance', {
      headers: { Authorization: `Bearer ${session.access_token}` },
      body: { bank_account_id: bankAccountId },
    });

    setSyncing(null);

    if (res.error) {
      console.error('Balance refresh failed:', res.error);
      return false;
    }

    await fetchAccounts();
    return true;
  }, [supabase, fetchAccounts]);

  // Disconnect (deactivate) a bank account
  const disconnectAccount = useCallback(async (bankAccountId: string): Promise<boolean> => {
    const { error } = await supabase
      .from('bank_accounts')
      .update({ is_active: false })
      .eq('id', bankAccountId);

    if (error) {
      console.error('Disconnect failed:', error);
      return false;
    }

    await fetchAccounts();
    return true;
  }, [supabase, fetchAccounts]);

  // Update transaction category
  const categorizeTransaction = useCallback(async (
    txnId: string,
    category: string,
  ): Promise<boolean> => {
    const { error } = await supabase
      .from('bank_transactions')
      .update({
        category,
        category_confidence: 1.0,
        is_reviewed: true,
      })
      .eq('id', txnId);

    if (error) {
      console.error('Categorize failed:', error);
      return false;
    }

    setTransactions(prev => prev.map(t =>
      t.id === txnId ? { ...t, category, categoryConfidence: 1.0, isReviewed: true } : t
    ));
    return true;
  }, [supabase]);

  // Mark transaction as reviewed
  const reviewTransaction = useCallback(async (txnId: string): Promise<boolean> => {
    const { error } = await supabase
      .from('bank_transactions')
      .update({ is_reviewed: true })
      .eq('id', txnId);

    if (error) return false;

    setTransactions(prev => prev.map(t =>
      t.id === txnId ? { ...t, isReviewed: true } : t
    ));
    return true;
  }, [supabase]);

  // Summary stats
  const totalBalance = accounts.reduce((s, a) => s + a.currentBalance, 0);
  const unreviewedCount = transactions.filter(t => !t.isReviewed).length;

  return {
    accounts,
    transactions,
    loading,
    syncing,
    totalBalance,
    unreviewedCount,
    createLinkToken,
    exchangeToken,
    syncTransactions,
    refreshBalance,
    disconnectAccount,
    categorizeTransaction,
    reviewTransaction,
    fetchTransactions,
  };
}
