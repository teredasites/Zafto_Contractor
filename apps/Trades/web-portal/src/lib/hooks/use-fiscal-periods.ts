'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Fiscal Period Management & Year-End Close Hook
// D4k — Period lifecycle, year-end closing journal entries,
// and audit log queries for Ledger fiscal period management.
// ============================================================

export interface FiscalPeriodData {
  id: string;
  companyId: string;
  periodName: string;
  periodType: 'month' | 'quarter' | 'year';
  startDate: string;
  endDate: string;
  isClosed: boolean;
  closedAt: string | null;
  closedByUserId: string | null;
  retainedEarningsPosted: boolean;
  createdAt: string;
}

export interface AuditLogEntry {
  id: string;
  userId: string | null;
  action: string;
  tableName: string;
  recordId: string;
  previousValues: Record<string, unknown> | null;
  newValues: Record<string, unknown> | null;
  changeSummary: string | null;
  createdAt: string;
}

interface AccountBalance {
  accountId: string;
  accountNumber: string;
  accountName: string;
  accountType: string;
  balance: number;
}

const MONTH_NAMES = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

function mapPeriodFromDb(row: Record<string, unknown>): FiscalPeriodData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    periodName: row.period_name as string,
    periodType: row.period_type as 'month' | 'quarter' | 'year',
    startDate: row.start_date as string,
    endDate: row.end_date as string,
    isClosed: row.is_closed as boolean,
    closedAt: row.closed_at as string | null,
    closedByUserId: row.closed_by_user_id as string | null,
    retainedEarningsPosted: row.retained_earnings_posted as boolean,
    createdAt: row.created_at as string,
  };
}

function mapAuditLogFromDb(row: Record<string, unknown>): AuditLogEntry {
  return {
    id: row.id as string,
    userId: row.user_id as string | null,
    action: row.action as string,
    tableName: row.table_name as string,
    recordId: row.record_id as string,
    previousValues: row.previous_values as Record<string, unknown> | null,
    newValues: row.new_values as Record<string, unknown> | null,
    changeSummary: row.change_summary as string | null,
    createdAt: row.created_at as string,
  };
}

// Last day of month helper (0-indexed month)
function lastDayOfMonth(year: number, month: number): number {
  return new Date(year, month + 1, 0).getDate();
}

// Format YYYY-MM-DD
function fmtDate(year: number, month: number, day: number): string {
  const m = String(month + 1).padStart(2, '0');
  const d = String(day).padStart(2, '0');
  return `${year}-${m}-${d}`;
}

export function useFiscalPeriods() {
  const [periods, setPeriods] = useState<FiscalPeriodData[]>([]);
  const [loading, setLoading] = useState(true);

  const supabase = getSupabase();

  // ----------------------------------------------------------
  // Fetch all fiscal periods
  // ----------------------------------------------------------
  const fetchPeriods = useCallback(async () => {
    const { data, error } = await supabase
      .from('fiscal_periods')
      .select('*')
      .order('start_date', { ascending: false });

    if (!error && data) {
      setPeriods(data.map((row: Record<string, unknown>) => mapPeriodFromDb(row)));
    }
    setLoading(false);
  }, [supabase]);

  useEffect(() => {
    fetchPeriods();
  }, [fetchPeriods]);

  // ----------------------------------------------------------
  // Generate periods for a given year
  // Creates 12 monthly + 4 quarterly + 1 yearly period.
  // Uses upsert on (company_id, period_name) unique constraint.
  // ----------------------------------------------------------
  const generatePeriodsForYear = useCallback(async (year: number): Promise<boolean> => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const companyId = user.app_metadata?.company_id;
      if (!companyId) throw new Error('No company associated');

      const rows: {
        company_id: string;
        period_name: string;
        period_type: string;
        start_date: string;
        end_date: string;
      }[] = [];

      // 12 monthly periods
      for (let m = 0; m < 12; m++) {
        rows.push({
          company_id: companyId,
          period_name: `${MONTH_NAMES[m]} ${year}`,
          period_type: 'month',
          start_date: fmtDate(year, m, 1),
          end_date: fmtDate(year, m, lastDayOfMonth(year, m)),
        });
      }

      // 4 quarterly periods
      for (let q = 0; q < 4; q++) {
        const startMonth = q * 3;
        const endMonth = startMonth + 2;
        rows.push({
          company_id: companyId,
          period_name: `Q${q + 1} ${year}`,
          period_type: 'quarter',
          start_date: fmtDate(year, startMonth, 1),
          end_date: fmtDate(year, endMonth, lastDayOfMonth(year, endMonth)),
        });
      }

      // 1 yearly period
      rows.push({
        company_id: companyId,
        period_name: `FY ${year}`,
        period_type: 'year',
        start_date: fmtDate(year, 0, 1),
        end_date: fmtDate(year, 11, 31),
      });

      const { error } = await supabase
        .from('fiscal_periods')
        .upsert(rows, { onConflict: 'company_id,period_name' });

      if (error) {
        console.error('Failed to generate fiscal periods:', error);
        return false;
      }

      await fetchPeriods();
      return true;
    } catch (e) {
      console.error('Failed to generate fiscal periods:', e);
      return false;
    }
  }, [supabase, fetchPeriods]);

  // ----------------------------------------------------------
  // Close a fiscal period
  // ----------------------------------------------------------
  const closePeriod = useCallback(async (id: string): Promise<boolean> => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const companyId = user.app_metadata?.company_id;

      // Fetch current state
      const { data: period } = await supabase
        .from('fiscal_periods')
        .select('*')
        .eq('id', id)
        .single();

      if (!period) throw new Error('Period not found');
      if (period.is_closed) return false; // Already closed

      const { error: updateErr } = await supabase
        .from('fiscal_periods')
        .update({
          is_closed: true,
          closed_at: new Date().toISOString(),
          closed_by_user_id: user.id,
        })
        .eq('id', id);

      if (updateErr) throw updateErr;

      // Audit log
      await supabase.from('zbooks_audit_log').insert({
        company_id: companyId,
        user_id: user.id,
        action: 'period_closed',
        table_name: 'fiscal_periods',
        record_id: id,
        previous_values: { is_closed: false },
        new_values: { is_closed: true, closed_by: user.id },
        change_summary: `Closed fiscal period: ${period.period_name}`,
      });

      await fetchPeriods();
      return true;
    } catch (e) {
      console.error('Failed to close period:', e);
      return false;
    }
  }, [supabase, fetchPeriods]);

  // ----------------------------------------------------------
  // Reopen a fiscal period (with reason)
  // ----------------------------------------------------------
  const reopenPeriod = useCallback(async (id: string, reason: string): Promise<boolean> => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const companyId = user.app_metadata?.company_id;

      const { data: period } = await supabase
        .from('fiscal_periods')
        .select('*')
        .eq('id', id)
        .single();

      if (!period) throw new Error('Period not found');
      if (!period.is_closed) return false; // Already open

      const { error: updateErr } = await supabase
        .from('fiscal_periods')
        .update({
          is_closed: false,
          closed_at: null,
          closed_by_user_id: null,
        })
        .eq('id', id);

      if (updateErr) throw updateErr;

      // Audit log
      await supabase.from('zbooks_audit_log').insert({
        company_id: companyId,
        user_id: user.id,
        action: 'period_reopened',
        table_name: 'fiscal_periods',
        record_id: id,
        previous_values: { is_closed: true },
        new_values: { is_closed: false, reopen_reason: reason },
        change_summary: `Reopened fiscal period: ${period.period_name}. Reason: ${reason}`,
      });

      await fetchPeriods();
      return true;
    } catch (e) {
      console.error('Failed to reopen period:', e);
      return false;
    }
  }, [supabase, fetchPeriods]);

  // ----------------------------------------------------------
  // Year-End Close — the big procedure
  // 1. Verify all monthly periods for the year are closed
  // 2. Aggregate revenue + expense/cogs balances from posted JEs
  // 3. Create closing journal entry zeroing temp accounts
  // 4. Net to Retained Earnings (3200)
  // 5. Mark year period retained_earnings_posted=true
  // 6. Audit log
  // ----------------------------------------------------------
  const yearEndClose = useCallback(async (year: number): Promise<{ success: boolean; error?: string; closingEntryId?: string }> => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const companyId = user.app_metadata?.company_id;
      if (!companyId) throw new Error('No company associated');

      // Step 1: Get all monthly periods for the year and check all are closed
      const yearStart = `${year}-01-01`;
      const yearEnd = `${year}-12-31`;

      const { data: monthlyPeriods } = await supabase
        .from('fiscal_periods')
        .select('*')
        .eq('period_type', 'month')
        .gte('start_date', yearStart)
        .lte('end_date', yearEnd)
        .order('start_date');

      const typedMonthly = (monthlyPeriods || []) as { id: string; period_name: string; is_closed: boolean }[];

      if (typedMonthly.length === 0) {
        return { success: false, error: 'No monthly periods found for this year. Generate periods first.' };
      }

      const openPeriods = typedMonthly.filter((p) => !p.is_closed);
      if (openPeriods.length > 0) {
        const names = openPeriods.map((p) => p.period_name).join(', ');
        return { success: false, error: `Cannot close year. Open periods: ${names}` };
      }

      // Step 2: Query revenue accounts (type='revenue')
      const { data: revenueAccounts } = await supabase
        .from('chart_of_accounts')
        .select('id, account_number, account_name, account_type')
        .eq('account_type', 'revenue')
        .eq('is_active', true);

      const typedRevenue = (revenueAccounts || []) as { id: string; account_number: string; account_name: string; account_type: string }[];

      // Query expense + cogs accounts
      const { data: expenseAccounts } = await supabase
        .from('chart_of_accounts')
        .select('id, account_number, account_name, account_type')
        .in('account_type', ['expense', 'cogs'])
        .eq('is_active', true);

      const typedExpense = (expenseAccounts || []) as { id: string; account_number: string; account_name: string; account_type: string }[];

      // Step 3: Get balances from journal_entry_lines for posted entries in this year
      const allAccountIds = [...typedRevenue, ...typedExpense].map((a) => a.id);

      if (allAccountIds.length === 0) {
        return { success: false, error: 'No revenue or expense accounts found in chart of accounts.' };
      }

      const { data: lineData } = await supabase
        .from('journal_entry_lines')
        .select('account_id, debit_amount, credit_amount, journal_entries!inner(status, entry_date)')
        .eq('journal_entries.status', 'posted')
        .gte('journal_entries.entry_date', yearStart)
        .lte('journal_entries.entry_date', yearEnd)
        .in('account_id', allAccountIds);

      const typedLines = (lineData || []) as { account_id: string; debit_amount: number; credit_amount: number }[];

      // Aggregate per account
      const debitMap = new Map<string, number>();
      const creditMap = new Map<string, number>();
      for (const line of typedLines) {
        debitMap.set(line.account_id, (debitMap.get(line.account_id) || 0) + Number(line.debit_amount));
        creditMap.set(line.account_id, (creditMap.get(line.account_id) || 0) + Number(line.credit_amount));
      }

      // Build balance list for revenue accounts (normal balance = credit, so balance = credits - debits)
      const revenueBalances: AccountBalance[] = typedRevenue.map((acct) => {
        const debits = debitMap.get(acct.id) || 0;
        const credits = creditMap.get(acct.id) || 0;
        return {
          accountId: acct.id,
          accountNumber: acct.account_number,
          accountName: acct.account_name,
          accountType: acct.account_type,
          balance: credits - debits, // positive = net revenue
        };
      }).filter((a) => Math.abs(a.balance) > 0.005);

      // Build balance list for expense/cogs accounts (normal balance = debit, so balance = debits - credits)
      const expenseBalances: AccountBalance[] = typedExpense.map((acct) => {
        const debits = debitMap.get(acct.id) || 0;
        const credits = creditMap.get(acct.id) || 0;
        return {
          accountId: acct.id,
          accountNumber: acct.account_number,
          accountName: acct.account_name,
          accountType: acct.account_type,
          balance: debits - credits, // positive = net expense
        };
      }).filter((a) => Math.abs(a.balance) > 0.005);

      // Step 4: Verify Retained Earnings account (3200) exists
      const { data: retainedEarningsAcct } = await supabase
        .from('chart_of_accounts')
        .select('id, account_number')
        .eq('account_number', '3200')
        .eq('is_active', true)
        .single();

      if (!retainedEarningsAcct) {
        return { success: false, error: 'Retained Earnings account (3200) not found. Create it in Chart of Accounts first.' };
      }

      // Step 5: Build closing journal entry lines
      // Revenue accounts: DR each revenue account for its balance (zeroing it out)
      // Expense/COGS accounts: CR each expense account for its balance (zeroing it out)
      // Net to Retained Earnings

      const closingLines: { account_id: string; debit_amount: number; credit_amount: number; description: string }[] = [];

      let totalRevenueClose = 0;
      let totalExpenseClose = 0;

      // Close revenue accounts: DR revenue (reduce credit balance to zero)
      for (const rev of revenueBalances) {
        closingLines.push({
          account_id: rev.accountId,
          debit_amount: Number(Math.abs(rev.balance).toFixed(2)),
          credit_amount: 0,
          description: `Close ${rev.accountNumber} ${rev.accountName}`,
        });
        totalRevenueClose += Math.abs(rev.balance);
      }

      // Close expense/cogs accounts: CR expense (reduce debit balance to zero)
      for (const exp of expenseBalances) {
        closingLines.push({
          account_id: exp.accountId,
          debit_amount: 0,
          credit_amount: Number(Math.abs(exp.balance).toFixed(2)),
          description: `Close ${exp.accountNumber} ${exp.accountName}`,
        });
        totalExpenseClose += Math.abs(exp.balance);
      }

      // Net income = total revenue closed - total expense closed
      const netIncome = Number((totalRevenueClose - totalExpenseClose).toFixed(2));

      // Retained Earnings line: CR if net income (positive), DR if net loss (negative)
      if (netIncome >= 0) {
        // Net income: CR Retained Earnings
        closingLines.push({
          account_id: retainedEarningsAcct.id,
          debit_amount: 0,
          credit_amount: Number(netIncome.toFixed(2)),
          description: `Net income to Retained Earnings - FY ${year}`,
        });
      } else {
        // Net loss: DR Retained Earnings
        closingLines.push({
          account_id: retainedEarningsAcct.id,
          debit_amount: Number(Math.abs(netIncome).toFixed(2)),
          credit_amount: 0,
          description: `Net loss to Retained Earnings - FY ${year}`,
        });
      }

      if (closingLines.length === 0) {
        return { success: false, error: 'No revenue or expense balances to close for this year.' };
      }

      // Generate entry number
      const entryNumber = `YE-${year}`;
      const entryDate = `${year}-12-31`;

      // Find fiscal period for the year
      const { data: yearPeriodData } = await supabase
        .from('fiscal_periods')
        .select('id')
        .eq('period_name', `FY ${year}`)
        .single();

      // Create the closing journal entry
      const { data: closingEntry, error: jeError } = await supabase
        .from('journal_entries')
        .insert({
          company_id: companyId,
          entry_number: entryNumber,
          entry_date: entryDate,
          description: `Year-end closing entry - FY ${year}`,
          status: 'posted',
          source_type: 'year_end_close',
          posted_at: new Date().toISOString(),
          posted_by_user_id: user.id,
          memo: `Year-end closing entry - FY ${year}. Revenue closed: ${totalRevenueClose.toFixed(2)}, Expenses closed: ${totalExpenseClose.toFixed(2)}, Net income: ${netIncome.toFixed(2)}`,
          reference_number: entryNumber,
          fiscal_period_id: yearPeriodData?.id || null,
          created_by_user_id: user.id,
        })
        .select('id')
        .single();

      if (jeError || !closingEntry) {
        return { success: false, error: `Failed to create closing journal entry: ${jeError?.message || 'Unknown error'}` };
      }

      // Insert closing lines
      const lineInserts = closingLines.map((line) => ({
        journal_entry_id: closingEntry.id,
        account_id: line.account_id,
        debit_amount: line.debit_amount,
        credit_amount: line.credit_amount,
        description: line.description,
      }));

      const { error: linesErr } = await supabase
        .from('journal_entry_lines')
        .insert(lineInserts);

      if (linesErr) {
        return { success: false, error: `Failed to create closing entry lines: ${linesErr.message}` };
      }

      // Step 6: Mark year period as retained_earnings_posted
      if (yearPeriodData) {
        await supabase
          .from('fiscal_periods')
          .update({ retained_earnings_posted: true })
          .eq('id', yearPeriodData.id);
      }

      // Step 7: Audit log
      await supabase.from('zbooks_audit_log').insert({
        company_id: companyId,
        user_id: user.id,
        action: 'period_closed',
        table_name: 'journal_entries',
        record_id: closingEntry.id,
        new_values: {
          entry_number: entryNumber,
          year,
          revenue_closed: totalRevenueClose,
          expenses_closed: totalExpenseClose,
          net_income: netIncome,
          retained_earnings_account: '3200',
          lines_count: closingLines.length,
        },
        change_summary: `Year-end close FY ${year}: Revenue ${totalRevenueClose.toFixed(2)}, Expenses ${totalExpenseClose.toFixed(2)}, Net income ${netIncome.toFixed(2)} posted to Retained Earnings`,
      });

      await fetchPeriods();
      return { success: true, closingEntryId: closingEntry.id };
    } catch (e) {
      console.error('Year-end close failed:', e);
      return { success: false, error: e instanceof Error ? e.message : 'Year-end close failed' };
    }
  }, [supabase, fetchPeriods]);

  // ----------------------------------------------------------
  // Fetch audit log entries for fiscal period actions
  // ----------------------------------------------------------
  const fetchAuditLog = useCallback(async (periodId?: string): Promise<AuditLogEntry[]> => {
    try {
      let query = supabase
        .from('zbooks_audit_log')
        .select('*')
        .in('action', ['period_closed', 'period_reopened'])
        .order('created_at', { ascending: false })
        .limit(100);

      if (periodId) {
        query = query.eq('record_id', periodId);
      }

      const { data, error } = await query;
      if (error || !data) return [];
      return data.map((row: Record<string, unknown>) => mapAuditLogFromDb(row));
    } catch (_) {
      return [];
    }
  }, [supabase]);

  return {
    periods,
    loading,
    generatePeriodsForYear,
    closePeriod,
    reopenPeriod,
    yearEndClose,
    fetchAuditLog,
    refetch: fetchPeriods,
  };
}
