'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Ledger Hook — Journal entry queries, COA queries, GL data
// ============================================================

export interface JournalEntryData {
  id: string;
  entryNumber: string;
  entryDate: string;
  description: string;
  status: 'draft' | 'posted' | 'voided';
  sourceType: string | null;
  sourceId: string | null;
  postedAt: string | null;
  voidedAt: string | null;
  voidReason: string | null;
  reversingEntryId: string | null;
  memo: string | null;
  createdAt: string;
  lines: JournalEntryLineData[];
}

export interface JournalEntryLineData {
  id: string;
  accountId: string;
  accountNumber: string;
  accountName: string;
  debitAmount: number;
  creditAmount: number;
  description: string | null;
  jobId: string | null;
}

export interface AccountBalanceData {
  id: string;
  accountNumber: string;
  accountName: string;
  accountType: string;
  normalBalance: string;
  totalDebits: number;
  totalCredits: number;
  balance: number;
  isActive: boolean;
}

function mapJournalEntry(row: Record<string, unknown>): JournalEntryData {
  const lines = ((row.journal_entry_lines || []) as Record<string, unknown>[]).map((l) => {
    const acct = l.chart_of_accounts as Record<string, unknown> | null;
    return {
      id: l.id as string,
      accountId: l.account_id as string,
      accountNumber: acct?.account_number as string || '',
      accountName: acct?.account_name as string || '',
      debitAmount: Number(l.debit_amount || 0),
      creditAmount: Number(l.credit_amount || 0),
      description: l.description as string | null,
      jobId: l.job_id as string | null,
    };
  });

  return {
    id: row.id as string,
    entryNumber: row.entry_number as string,
    entryDate: row.entry_date as string,
    description: row.description as string,
    status: row.status as 'draft' | 'posted' | 'voided',
    sourceType: row.source_type as string | null,
    sourceId: row.source_id as string | null,
    postedAt: row.posted_at as string | null,
    voidedAt: row.voided_at as string | null,
    voidReason: row.void_reason as string | null,
    reversingEntryId: row.reversing_entry_id as string | null,
    memo: row.memo as string | null,
    createdAt: row.created_at as string,
    lines,
  };
}

// ============================================================
// Hook: Journal Entries list
// ============================================================
export function useJournalEntries(filters?: {
  status?: string;
  sourceType?: string;
  dateFrom?: string;
  dateTo?: string;
}) {
  const [entries, setEntries] = useState<JournalEntryData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchEntries = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      let query = supabase
        .from('journal_entries')
        .select('*, journal_entry_lines(*, chart_of_accounts(account_number, account_name))')
        .order('entry_date', { ascending: false })
        .order('created_at', { ascending: false });

      if (filters?.status) query = query.eq('status', filters.status);
      if (filters?.sourceType) query = query.eq('source_type', filters.sourceType);
      if (filters?.dateFrom) query = query.gte('entry_date', filters.dateFrom);
      if (filters?.dateTo) query = query.lte('entry_date', filters.dateTo);

      const { data, error: err } = await query;
      if (err) throw err;
      setEntries((data || []).map(mapJournalEntry));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load journal entries');
    } finally {
      setLoading(false);
    }
  }, [filters?.status, filters?.sourceType, filters?.dateFrom, filters?.dateTo]);

  useEffect(() => {
    fetchEntries();
  }, [fetchEntries]);

  return { entries, loading, error, refetch: fetchEntries };
}

// ============================================================
// Hook: Single journal entry
// ============================================================
export function useJournalEntry(id: string | undefined) {
  const [entry, setEntry] = useState<JournalEntryData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) { setLoading(false); return; }
    let ignore = false;

    const fetch = async () => {
      try {
        setLoading(true);
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('journal_entries')
          .select('*, journal_entry_lines(*, chart_of_accounts(account_number, account_name))')
          .eq('id', id)
          .single();

        if (ignore) return;
        if (err) throw err;
        setEntry(data ? mapJournalEntry(data) : null);
      } catch (_) {
        if (!ignore) setEntry(null);
      } finally {
        if (!ignore) setLoading(false);
      }
    };

    fetch();
    return () => { ignore = true; };
  }, [id]);

  return { entry, loading };
}

// ============================================================
// Hook: Account Balances (for COA page + reports)
// ============================================================
export function useAccountBalances(asOfDate?: string) {
  const [accounts, setAccounts] = useState<AccountBalanceData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchBalances = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();

      // Fetch all active accounts
      const { data: coaData, error: coaErr } = await supabase
        .from('chart_of_accounts')
        .select('id, account_number, account_name, account_type, normal_balance, is_active')
        .eq('is_active', true)
        .order('sort_order');

      if (coaErr) throw coaErr;
      const typedCoa = (coaData || []) as { id: string; account_number: string; account_name: string; account_type: string; normal_balance: string; is_active: boolean }[];

      // Fetch aggregated debit/credit per account from posted entries
      let lineQuery = supabase
        .from('journal_entry_lines')
        .select('account_id, debit_amount, credit_amount, journal_entries!inner(status, entry_date)')
        .eq('journal_entries.status', 'posted');

      if (asOfDate) {
        lineQuery = lineQuery.lte('journal_entries.entry_date', asOfDate);
      }

      const { data: lineData } = await lineQuery;

      // Aggregate per account
      const debitMap = new Map<string, number>();
      const creditMap = new Map<string, number>();
      for (const line of (lineData || []) as { account_id: string; debit_amount: number; credit_amount: number }[]) {
        debitMap.set(line.account_id, (debitMap.get(line.account_id) || 0) + Number(line.debit_amount));
        creditMap.set(line.account_id, (creditMap.get(line.account_id) || 0) + Number(line.credit_amount));
      }

      const result: AccountBalanceData[] = typedCoa.map((acct) => {
        const totalDebits = debitMap.get(acct.id) || 0;
        const totalCredits = creditMap.get(acct.id) || 0;
        // Balance depends on normal balance direction
        const balance = acct.normal_balance === 'debit'
          ? totalDebits - totalCredits
          : totalCredits - totalDebits;

        return {
          id: acct.id,
          accountNumber: acct.account_number,
          accountName: acct.account_name,
          accountType: acct.account_type,
          normalBalance: acct.normal_balance,
          totalDebits,
          totalCredits,
          balance,
          isActive: acct.is_active,
        };
      });

      setAccounts(result);
    } catch (_) {
      setAccounts([]);
    } finally {
      setLoading(false);
    }
  }, [asOfDate]);

  useEffect(() => {
    fetchBalances();
  }, [fetchBalances]);

  return { accounts, loading, refetch: fetchBalances };
}

// ============================================================
// Hook: GL Detail for a single account
// ============================================================
export function useGLDetail(accountId: string | undefined, dateFrom?: string, dateTo?: string) {
  const [lines, setLines] = useState<(JournalEntryLineData & { entryNumber: string; entryDate: string; entryStatus: string })[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!accountId) { setLoading(false); return; }
    let ignore = false;

    const fetch = async () => {
      try {
        setLoading(true);
        const supabase = getSupabase();

        let query = supabase
          .from('journal_entry_lines')
          .select('*, chart_of_accounts(account_number, account_name), journal_entries!inner(entry_number, entry_date, status)')
          .eq('account_id', accountId)
          .eq('journal_entries.status', 'posted')
          .order('created_at', { ascending: true });

        if (dateFrom) query = query.gte('journal_entries.entry_date', dateFrom);
        if (dateTo) query = query.lte('journal_entries.entry_date', dateTo);

        const { data } = await query;

        if (ignore) return;

        const result = (data || []).map((row: Record<string, unknown>) => {
          const je = row.journal_entries as Record<string, unknown>;
          const acct = row.chart_of_accounts as Record<string, unknown> | null;
          return {
            id: row.id as string,
            accountId: row.account_id as string,
            accountNumber: acct?.account_number as string || '',
            accountName: acct?.account_name as string || '',
            debitAmount: Number(row.debit_amount || 0),
            creditAmount: Number(row.credit_amount || 0),
            description: row.description as string | null,
            jobId: row.job_id as string | null,
            entryNumber: je?.entry_number as string || '',
            entryDate: je?.entry_date as string || '',
            entryStatus: je?.status as string || '',
          };
        });

        setLines(result);
      } catch (_) {
        if (!ignore) setLines([]);
      } finally {
        if (!ignore) setLoading(false);
      }
    };

    fetch();
    return () => { ignore = true; };
  }, [accountId, dateFrom, dateTo]);

  return { lines, loading };
}
