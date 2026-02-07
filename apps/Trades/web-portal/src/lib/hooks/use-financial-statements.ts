'use client';

import { useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Financial Statements hook
// Aggregates journal_entry_lines + chart_of_accounts data
// for P&L, Balance Sheet, Cash Flow, Aging, GL Detail, Trial Balance
// ============================================================

export interface AccountBalance {
  accountId: string;
  accountNumber: string;
  accountName: string;
  accountType: string;
  normalBalance: string;
  debits: number;
  credits: number;
  balance: number;
}

export interface JournalDetail {
  id: string;
  entryDate: string;
  memo: string;
  debit: number;
  credit: number;
  runningBalance: number;
  entryId: string;
  entryReference: string;
}

export interface AgingRow {
  id: string;
  name: string;
  current: number;
  days1to30: number;
  days31to60: number;
  days61to90: number;
  days90plus: number;
  total: number;
}

// Account type ranges
const ACCOUNT_TYPE_RANGES: Record<string, [number, number]> = {
  asset: [1000, 1999],
  liability: [2000, 2999],
  equity: [3000, 3999],
  revenue: [4000, 4999],
  cogs: [5000, 5999],
  expense: [6000, 7999],
};

export function useFinancialStatements() {
  const [loading, setLoading] = useState(false);
  const supabase = getSupabase();

  // Fetch all account balances for a date range (or as-of date)
  const fetchAccountBalances = useCallback(async (
    startDate?: string,
    endDate?: string,
  ): Promise<AccountBalance[]> => {
    setLoading(true);

    // Get all active accounts
    const { data: accounts, error: accErr } = await supabase
      .from('chart_of_accounts')
      .select('id, account_number, account_name, account_type, normal_balance')
      .eq('is_active', true)
      .order('account_number');

    if (accErr || !accounts) {
      setLoading(false);
      return [];
    }

    // Get aggregated journal entry line totals per account
    let query = supabase
      .from('journal_entry_lines')
      .select('account_id, debit_amount, credit_amount, journal_entries!inner(entry_date, status)');

    // Only include posted entries
    query = query.eq('journal_entries.status', 'posted');

    if (startDate) {
      query = query.gte('journal_entries.entry_date', startDate);
    }
    if (endDate) {
      query = query.lte('journal_entries.entry_date', endDate);
    }

    const { data: lines, error: lineErr } = await query;

    setLoading(false);

    if (lineErr) {
      console.error('Failed to fetch journal lines:', lineErr);
      return [];
    }

    // Aggregate by account
    const totals: Record<string, { debits: number; credits: number }> = {};
    for (const line of (lines || []) as Record<string, unknown>[]) {
      const accountId = line.account_id as string;
      if (!totals[accountId]) {
        totals[accountId] = { debits: 0, credits: 0 };
      }
      totals[accountId].debits += Number(line.debit_amount) || 0;
      totals[accountId].credits += Number(line.credit_amount) || 0;
    }

    const typedAccounts = accounts as { id: string; account_number: string; account_name: string; account_type: string; normal_balance: string }[];

    return typedAccounts.map(acct => {
      const t = totals[acct.id] || { debits: 0, credits: 0 };
      const balance = acct.normal_balance === 'debit'
        ? t.debits - t.credits
        : t.credits - t.debits;
      return {
        accountId: acct.id,
        accountNumber: acct.account_number,
        accountName: acct.account_name,
        accountType: acct.account_type,
        normalBalance: acct.normal_balance,
        debits: Math.round(t.debits * 100) / 100,
        credits: Math.round(t.credits * 100) / 100,
        balance: Math.round(balance * 100) / 100,
      };
    });
  }, [supabase]);

  // P&L: Revenue - COGS - Expenses
  const fetchProfitAndLoss = useCallback(async (
    startDate: string,
    endDate: string,
  ) => {
    const balances = await fetchAccountBalances(startDate, endDate);

    const revenue = balances.filter(a => a.accountType === 'revenue');
    const cogs = balances.filter(a => a.accountType === 'cogs');
    const expenses = balances.filter(a => a.accountType === 'expense');

    const totalRevenue = revenue.reduce((s, a) => s + a.balance, 0);
    const totalCogs = cogs.reduce((s, a) => s + a.balance, 0);
    const grossProfit = totalRevenue - totalCogs;
    const totalExpenses = expenses.reduce((s, a) => s + a.balance, 0);
    const netIncome = grossProfit - totalExpenses;

    return {
      revenue,
      cogs,
      expenses,
      totalRevenue: Math.round(totalRevenue * 100) / 100,
      totalCogs: Math.round(totalCogs * 100) / 100,
      grossProfit: Math.round(grossProfit * 100) / 100,
      totalExpenses: Math.round(totalExpenses * 100) / 100,
      netIncome: Math.round(netIncome * 100) / 100,
    };
  }, [fetchAccountBalances]);

  // Balance Sheet: A = L + E
  const fetchBalanceSheet = useCallback(async (asOfDate: string) => {
    const balances = await fetchAccountBalances(undefined, asOfDate);

    const assets = balances.filter(a => a.accountType === 'asset');
    const liabilities = balances.filter(a => a.accountType === 'liability');
    const equity = balances.filter(a => a.accountType === 'equity');

    // Current year net income goes into equity
    const yearStart = asOfDate.substring(0, 4) + '-01-01';
    const pnl = await fetchProfitAndLoss(yearStart, asOfDate);

    const totalAssets = assets.reduce((s, a) => s + a.balance, 0);
    const totalLiabilities = liabilities.reduce((s, a) => s + a.balance, 0);
    const totalEquity = equity.reduce((s, a) => s + a.balance, 0) + pnl.netIncome;
    const isBalanced = Math.abs(totalAssets - (totalLiabilities + totalEquity)) < 0.01;

    return {
      assets,
      liabilities,
      equity,
      currentYearNetIncome: pnl.netIncome,
      totalAssets: Math.round(totalAssets * 100) / 100,
      totalLiabilities: Math.round(totalLiabilities * 100) / 100,
      totalEquity: Math.round(totalEquity * 100) / 100,
      isBalanced,
    };
  }, [fetchAccountBalances, fetchProfitAndLoss]);

  // Cash Flow (simplified indirect method)
  const fetchCashFlow = useCallback(async (startDate: string, endDate: string) => {
    const pnl = await fetchProfitAndLoss(startDate, endDate);
    const balances = await fetchAccountBalances(startDate, endDate);

    // AR change (asset account 1200)
    const arAccounts = balances.filter(a => a.accountNumber.startsWith('12'));
    const arChange = arAccounts.reduce((s, a) => s + a.balance, 0);

    // AP change (liability account 2000)
    const apAccounts = balances.filter(a => a.accountNumber.startsWith('20'));
    const apChange = apAccounts.reduce((s, a) => s + a.balance, 0);

    // Equipment/vehicle (asset 1500-1599)
    const equipAccounts = balances.filter(a => {
      const num = parseInt(a.accountNumber);
      return num >= 1500 && num <= 1599;
    });
    const investingActivities = equipAccounts.reduce((s, a) => s + a.balance, 0);

    // Loan/equity changes (2100+ liabilities, 3000+ equity)
    const loanAccounts = balances.filter(a => {
      const num = parseInt(a.accountNumber);
      return num >= 2100 && num <= 2999;
    });
    const equityAccounts = balances.filter(a => a.accountType === 'equity');
    const financingActivities = loanAccounts.reduce((s, a) => s + a.balance, 0)
      + equityAccounts.reduce((s, a) => s + a.balance, 0);

    const operatingActivities = pnl.netIncome - arChange + apChange;
    const netCashChange = operatingActivities - investingActivities + financingActivities;

    return {
      netIncome: pnl.netIncome,
      arChange: Math.round(arChange * 100) / 100,
      apChange: Math.round(apChange * 100) / 100,
      operatingActivities: Math.round(operatingActivities * 100) / 100,
      investingActivities: Math.round(investingActivities * 100) / 100,
      financingActivities: Math.round(financingActivities * 100) / 100,
      netCashChange: Math.round(netCashChange * 100) / 100,
    };
  }, [fetchAccountBalances, fetchProfitAndLoss]);

  // AR Aging
  const fetchARaging = useCallback(async (): Promise<AgingRow[]> => {
    const { data, error } = await supabase
      .from('invoices')
      .select('id, customer_name, total, due_date, status')
      .in('status', ['sent', 'overdue']);

    if (error || !data) return [];

    const today = new Date();
    const byCustomer: Record<string, AgingRow> = {};

    for (const inv of data as { id: string; customer_name: string; total: number; due_date: string; status: string }[]) {
      const dueDate = new Date(inv.due_date);
      const daysPast = Math.floor((today.getTime() - dueDate.getTime()) / (1000 * 60 * 60 * 24));
      const amount = Number(inv.total) || 0;

      if (!byCustomer[inv.customer_name]) {
        byCustomer[inv.customer_name] = {
          id: inv.customer_name,
          name: inv.customer_name,
          current: 0,
          days1to30: 0,
          days31to60: 0,
          days61to90: 0,
          days90plus: 0,
          total: 0,
        };
      }

      const row = byCustomer[inv.customer_name];
      row.total += amount;

      if (daysPast <= 0) row.current += amount;
      else if (daysPast <= 30) row.days1to30 += amount;
      else if (daysPast <= 60) row.days31to60 += amount;
      else if (daysPast <= 90) row.days61to90 += amount;
      else row.days90plus += amount;
    }

    return Object.values(byCustomer).sort((a, b) => b.total - a.total);
  }, [supabase]);

  // AP Aging
  const fetchAPaging = useCallback(async (): Promise<AgingRow[]> => {
    const { data, error } = await supabase
      .from('expense_records')
      .select('id, description, total, expense_date, status, vendors(vendor_name)')
      .in('status', ['draft', 'approved']);

    if (error || !data) return [];

    const today = new Date();
    const byVendor: Record<string, AgingRow> = {};

    for (const exp of data as Record<string, unknown>[]) {
      const vendor = exp.vendors as { vendor_name: string } | null;
      const vendorName = vendor?.vendor_name || 'Unknown Vendor';
      const expDate = new Date(exp.expense_date as string);
      const daysPast = Math.floor((today.getTime() - expDate.getTime()) / (1000 * 60 * 60 * 24));
      const amount = Number(exp.total) || 0;

      if (!byVendor[vendorName]) {
        byVendor[vendorName] = {
          id: vendorName,
          name: vendorName,
          current: 0,
          days1to30: 0,
          days31to60: 0,
          days61to90: 0,
          days90plus: 0,
          total: 0,
        };
      }

      const row = byVendor[vendorName];
      row.total += amount;

      if (daysPast <= 0) row.current += amount;
      else if (daysPast <= 30) row.days1to30 += amount;
      else if (daysPast <= 60) row.days31to60 += amount;
      else if (daysPast <= 90) row.days61to90 += amount;
      else row.days90plus += amount;
    }

    return Object.values(byVendor).sort((a, b) => b.total - a.total);
  }, [supabase]);

  // General Ledger Detail for a specific account
  const fetchGLDetail = useCallback(async (
    accountId: string,
    startDate: string,
    endDate: string,
  ): Promise<{ entries: JournalDetail[]; openingBalance: number; closingBalance: number }> => {
    // Get account info
    const { data: acct } = await supabase
      .from('chart_of_accounts')
      .select('normal_balance')
      .eq('id', accountId)
      .single();

    const isDebitNormal = acct?.normal_balance === 'debit';

    // Get opening balance (all entries before start date)
    const { data: priorLines } = await supabase
      .from('journal_entry_lines')
      .select('debit_amount, credit_amount, journal_entries!inner(entry_date, status)')
      .eq('account_id', accountId)
      .eq('journal_entries.status', 'posted')
      .lt('journal_entries.entry_date', startDate);

    let openingBalance = 0;
    for (const line of (priorLines || []) as Record<string, unknown>[]) {
      const d = Number(line.debit_amount) || 0;
      const c = Number(line.credit_amount) || 0;
      openingBalance += isDebitNormal ? (d - c) : (c - d);
    }

    // Get entries in range
    const { data: rangeLines } = await supabase
      .from('journal_entry_lines')
      .select('id, debit_amount, credit_amount, journal_entries!inner(id, entry_date, memo, reference_number, status)')
      .eq('account_id', accountId)
      .eq('journal_entries.status', 'posted')
      .gte('journal_entries.entry_date', startDate)
      .lte('journal_entries.entry_date', endDate)
      .order('journal_entries(entry_date)', { ascending: true });

    let runningBalance = openingBalance;
    const entries: JournalDetail[] = [];

    for (const line of (rangeLines || []) as Record<string, unknown>[]) {
      const entry = line.journal_entries as Record<string, unknown>;
      const d = Number(line.debit_amount) || 0;
      const c = Number(line.credit_amount) || 0;
      runningBalance += isDebitNormal ? (d - c) : (c - d);

      entries.push({
        id: line.id as string,
        entryDate: entry.entry_date as string,
        memo: (entry.memo as string) || '',
        debit: d,
        credit: c,
        runningBalance: Math.round(runningBalance * 100) / 100,
        entryId: entry.id as string,
        entryReference: (entry.reference_number as string) || '',
      });
    }

    return {
      entries,
      openingBalance: Math.round(openingBalance * 100) / 100,
      closingBalance: Math.round(runningBalance * 100) / 100,
    };
  }, [supabase]);

  // Trial Balance (all accounts, debits must equal credits)
  const fetchTrialBalance = useCallback(async (asOfDate: string) => {
    const balances = await fetchAccountBalances(undefined, asOfDate);

    const totalDebits = balances.reduce((s, a) =>
      s + (a.normalBalance === 'debit' ? a.balance : 0) + (a.normalBalance === 'credit' && a.balance < 0 ? -a.balance : 0), 0);
    const totalCredits = balances.reduce((s, a) =>
      s + (a.normalBalance === 'credit' ? a.balance : 0) + (a.normalBalance === 'debit' && a.balance < 0 ? -a.balance : 0), 0);

    // Simple: sum all debit-balance accounts vs all credit-balance accounts
    let debitTotal = 0;
    let creditTotal = 0;
    for (const a of balances) {
      if (a.balance >= 0) {
        if (a.normalBalance === 'debit') debitTotal += a.balance;
        else creditTotal += a.balance;
      } else {
        // Contra: negative debit-normal = credit, negative credit-normal = debit
        if (a.normalBalance === 'debit') creditTotal += Math.abs(a.balance);
        else debitTotal += Math.abs(a.balance);
      }
    }

    return {
      accounts: balances.filter(a => a.debits > 0 || a.credits > 0 || a.balance !== 0),
      debitTotal: Math.round(debitTotal * 100) / 100,
      creditTotal: Math.round(creditTotal * 100) / 100,
      isBalanced: Math.abs(debitTotal - creditTotal) < 0.01,
    };
  }, [fetchAccountBalances]);

  return {
    loading,
    fetchAccountBalances,
    fetchProfitAndLoss,
    fetchBalanceSheet,
    fetchCashFlow,
    fetchARaging,
    fetchAPaging,
    fetchGLDetail,
    fetchTrialBalance,
  };
}
