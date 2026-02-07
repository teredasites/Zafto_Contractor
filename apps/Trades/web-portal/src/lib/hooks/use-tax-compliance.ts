'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Tax & 1099 Compliance Hook — D4i
// Tax category mapping, 1099 vendor tracking, Schedule C
// ============================================================

export interface TaxCategory {
  id: string;
  categoryName: string;
  taxForm: string;
  taxLine: string | null;
  description: string | null;
  isSystem: boolean;
  sortOrder: number;
}

export interface AccountMapping {
  id: string;
  accountNumber: string;
  accountName: string;
  accountType: string;
  taxCategoryId: string | null;
  isActive: boolean;
  sortOrder: number;
}

export interface Vendor1099 {
  id: string;
  vendorName: string;
  taxId: string | null;
  is1099Eligible: boolean;
  ytdPayments: number;
}

export interface ScheduleCLine {
  line: string;
  label: string;
  amount: number;
  isComputed: boolean;
}

export interface ScheduleCData {
  year: number;
  lines: ScheduleCLine[];
  netProfit: number;
  seTax: number;
  estimatedQuarterlyTax: number;
}

function mapTaxCategory(row: Record<string, unknown>): TaxCategory {
  return {
    id: row.id as string,
    categoryName: row.category_name as string,
    taxForm: row.tax_form as string,
    taxLine: row.tax_line as string | null,
    description: row.description as string | null,
    isSystem: row.is_system as boolean,
    sortOrder: row.sort_order as number,
  };
}

function mapAccountMapping(row: Record<string, unknown>): AccountMapping {
  return {
    id: row.id as string,
    accountNumber: row.account_number as string,
    accountName: row.account_name as string,
    accountType: row.account_type as string,
    taxCategoryId: row.tax_category_id as string | null,
    isActive: row.is_active as boolean,
    sortOrder: row.sort_order as number,
  };
}

// Schedule C line definitions ordered by IRS line number
const SCHEDULE_C_LINES: { line: string; label: string; taxLine: string; type: 'revenue' | 'cogs' | 'expense' }[] = [
  { line: 'Line 1', label: 'Gross receipts or sales', taxLine: 'Line 1', type: 'revenue' },
  { line: 'Line 2', label: 'Returns and allowances', taxLine: 'Line 2', type: 'revenue' },
  { line: 'Line 4', label: 'Cost of goods sold', taxLine: 'Line 4', type: 'cogs' },
  { line: 'Line 8', label: 'Advertising', taxLine: 'Line 8', type: 'expense' },
  { line: 'Line 9', label: 'Car and truck expenses', taxLine: 'Line 9', type: 'expense' },
  { line: 'Line 10', label: 'Commissions and fees', taxLine: 'Line 10', type: 'expense' },
  { line: 'Line 11', label: 'Contract labor', taxLine: 'Line 11', type: 'expense' },
  { line: 'Line 13', label: 'Depreciation', taxLine: 'Line 13', type: 'expense' },
  { line: 'Line 15', label: 'Insurance (other than health)', taxLine: 'Line 15', type: 'expense' },
  { line: 'Line 16a', label: 'Interest (mortgage)', taxLine: 'Line 16a', type: 'expense' },
  { line: 'Line 16b', label: 'Interest (other)', taxLine: 'Line 16b', type: 'expense' },
  { line: 'Line 17', label: 'Legal and professional services', taxLine: 'Line 17', type: 'expense' },
  { line: 'Line 18', label: 'Office expense', taxLine: 'Line 18', type: 'expense' },
  { line: 'Line 20a', label: 'Rent — vehicles, machinery, equipment', taxLine: 'Line 20a', type: 'expense' },
  { line: 'Line 20b', label: 'Rent — other business property', taxLine: 'Line 20b', type: 'expense' },
  { line: 'Line 21', label: 'Repairs and maintenance', taxLine: 'Line 21', type: 'expense' },
  { line: 'Line 22', label: 'Supplies', taxLine: 'Line 22', type: 'expense' },
  { line: 'Line 23', label: 'Taxes and licenses', taxLine: 'Line 23', type: 'expense' },
  { line: 'Line 24a', label: 'Travel', taxLine: 'Line 24a', type: 'expense' },
  { line: 'Line 24b', label: 'Deductible meals', taxLine: 'Line 24b', type: 'expense' },
  { line: 'Line 25', label: 'Utilities', taxLine: 'Line 25', type: 'expense' },
  { line: 'Line 26', label: 'Wages', taxLine: 'Line 26', type: 'expense' },
  { line: 'Line 27a', label: 'Other expenses', taxLine: 'Line 27a', type: 'expense' },
];

export function useTaxCompliance() {
  const [taxCategories, setTaxCategories] = useState<TaxCategory[]>([]);
  const [accountMappings, setAccountMappings] = useState<AccountMapping[]>([]);
  const [allEligibleVendors, setAllEligibleVendors] = useState<Vendor1099[]>([]);
  const [scheduleCData, setScheduleCData] = useState<ScheduleCData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Vendors with $600+ payments
  const vendors1099 = allEligibleVendors.filter((v) => v.ytdPayments >= 600);

  // ── Fetch tax categories ──
  const fetchTaxCategories = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('tax_categories')
        .select('*')
        .order('sort_order');

      if (err) throw err;
      const rows = (data || []) as Record<string, unknown>[];
      setTaxCategories(rows.map(mapTaxCategory));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load tax categories');
    }
  }, []);

  // ── Fetch account mappings ──
  const fetchAccountMappings = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('chart_of_accounts')
        .select('id, account_number, account_name, account_type, tax_category_id, is_active, sort_order')
        .order('sort_order');

      if (err) throw err;
      const rows = (data || []) as Record<string, unknown>[];
      setAccountMappings(rows.map(mapAccountMapping));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load account mappings');
    }
  }, []);

  // ── Update tax category mapping for an account ──
  const updateAccountTaxCategory = useCallback(async (accountId: string, taxCategoryId: string | null) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('chart_of_accounts')
        .update({ tax_category_id: taxCategoryId })
        .eq('id', accountId);

      if (err) throw err;

      // Update local state immediately
      setAccountMappings((prev) =>
        prev.map((a) => (a.id === accountId ? { ...a, taxCategoryId } : a))
      );
    } catch (e: unknown) {
      throw new Error(e instanceof Error ? e.message : 'Failed to update tax mapping');
    }
  }, []);

  // ── Fetch 1099-eligible vendors with YTD payments ──
  const fetchVendors1099 = useCallback(async (year?: number) => {
    try {
      const supabase = getSupabase();
      const targetYear = year || new Date().getFullYear();
      const startOfYear = `${targetYear}-01-01`;
      const endOfYear = `${targetYear}-12-31`;

      // Get all 1099-eligible vendors
      const { data: vendorData, error: vendorErr } = await supabase
        .from('vendors')
        .select('id, vendor_name, tax_id, is_1099_eligible')
        .eq('is_1099_eligible', true)
        .is('deleted_at', null)
        .order('vendor_name');

      if (vendorErr) throw vendorErr;

      const vendors = (vendorData || []) as {
        id: string;
        vendor_name: string;
        tax_id: string | null;
        is_1099_eligible: boolean;
      }[];

      // Get YTD payments for the target year
      const { data: paymentData, error: payErr } = await supabase
        .from('vendor_payments')
        .select('vendor_id, amount')
        .gte('payment_date', startOfYear)
        .lte('payment_date', endOfYear);

      if (payErr) throw payErr;

      const payments = (paymentData || []) as { vendor_id: string; amount: number }[];
      const ytdMap = new Map<string, number>();
      for (const p of payments) {
        ytdMap.set(p.vendor_id, (ytdMap.get(p.vendor_id) || 0) + Number(p.amount));
      }

      const mapped: Vendor1099[] = vendors.map((v) => ({
        id: v.id,
        vendorName: v.vendor_name,
        taxId: v.tax_id,
        is1099Eligible: v.is_1099_eligible,
        ytdPayments: ytdMap.get(v.id) || 0,
      }));

      setAllEligibleVendors(mapped);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load 1099 vendors');
    }
  }, []);

  // ── Fetch Schedule C data ──
  const fetchScheduleC = useCallback(async (year: number) => {
    try {
      const supabase = getSupabase();
      const startOfYear = `${year}-01-01`;
      const endOfYear = `${year}-12-31`;

      // Fetch all posted journal entries for the year
      const { data: entryData, error: entryErr } = await supabase
        .from('journal_entries')
        .select('id')
        .eq('status', 'posted')
        .gte('entry_date', startOfYear)
        .lte('entry_date', endOfYear);

      if (entryErr) throw entryErr;

      const entryIds = ((entryData || []) as { id: string }[]).map((e) => e.id);

      if (entryIds.length === 0) {
        // No entries — return empty Schedule C
        const emptyLines: ScheduleCLine[] = [
          { line: 'Line 1', label: 'Gross receipts or sales', amount: 0, isComputed: false },
          { line: 'Line 3', label: 'Gross profit (before COGS)', amount: 0, isComputed: true },
          { line: 'Line 4', label: 'Cost of goods sold', amount: 0, isComputed: false },
          { line: 'Line 5', label: 'Gross profit', amount: 0, isComputed: true },
          { line: 'Line 31', label: 'Net profit (or loss)', amount: 0, isComputed: true },
        ];
        setScheduleCData({
          year,
          lines: emptyLines,
          netProfit: 0,
          seTax: 0,
          estimatedQuarterlyTax: 0,
        });
        return;
      }

      // Fetch journal entry lines with account info
      const { data: lineData, error: lineErr } = await supabase
        .from('journal_entry_lines')
        .select('account_id, debit_amount, credit_amount')
        .in('journal_entry_id', entryIds);

      if (lineErr) throw lineErr;

      const lines = (lineData || []) as {
        account_id: string;
        debit_amount: number;
        credit_amount: number;
      }[];

      // Fetch accounts with their tax category mapping
      const { data: accountData, error: accErr } = await supabase
        .from('chart_of_accounts')
        .select('id, account_type, tax_category_id');

      if (accErr) throw accErr;

      const accounts = (accountData || []) as {
        id: string;
        account_type: string;
        tax_category_id: string | null;
      }[];

      // Fetch tax categories for this company
      const { data: catData } = await supabase
        .from('tax_categories')
        .select('id, tax_line, tax_form')
        .eq('tax_form', 'schedule_c');

      const categories = (catData || []) as {
        id: string;
        tax_line: string | null;
        tax_form: string;
      }[];

      // Build account → tax_line map
      const accountTaxLineMap = new Map<string, string>();
      const accountTypeMap = new Map<string, string>();
      for (const acc of accounts) {
        accountTypeMap.set(acc.id, acc.account_type);
        if (acc.tax_category_id) {
          const cat = categories.find((c) => c.id === acc.tax_category_id);
          if (cat?.tax_line) {
            accountTaxLineMap.set(acc.id, cat.tax_line);
          }
        }
      }

      // Aggregate amounts by tax line
      const lineAmounts = new Map<string, number>();
      for (const line of lines) {
        const taxLine = accountTaxLineMap.get(line.account_id);
        const accType = accountTypeMap.get(line.account_id);

        if (!taxLine) {
          // Unmapped account — fallback by type
          if (accType === 'revenue') {
            const current = lineAmounts.get('Line 1') || 0;
            // Revenue accounts have credit normal balance
            lineAmounts.set('Line 1', current + Number(line.credit_amount) - Number(line.debit_amount));
          } else if (accType === 'cogs') {
            const current = lineAmounts.get('Line 4') || 0;
            lineAmounts.set('Line 4', current + Number(line.debit_amount) - Number(line.credit_amount));
          } else if (accType === 'expense') {
            const current = lineAmounts.get('Line 27a') || 0;
            lineAmounts.set('Line 27a', current + Number(line.debit_amount) - Number(line.credit_amount));
          }
          continue;
        }

        const current = lineAmounts.get(taxLine) || 0;
        if (accType === 'revenue') {
          lineAmounts.set(taxLine, current + Number(line.credit_amount) - Number(line.debit_amount));
        } else {
          // Expenses and COGS: debit is the natural balance
          lineAmounts.set(taxLine, current + Number(line.debit_amount) - Number(line.credit_amount));
        }
      }

      // Build the Schedule C lines
      const scheduleCLines: ScheduleCLine[] = [];

      // Line 1: Gross receipts
      const grossReceipts = lineAmounts.get('Line 1') || 0;
      scheduleCLines.push({ line: 'Line 1', label: 'Gross receipts or sales', amount: grossReceipts, isComputed: false });

      // Line 2: Returns and allowances
      const returns = lineAmounts.get('Line 2') || 0;
      scheduleCLines.push({ line: 'Line 2', label: 'Returns and allowances', amount: returns, isComputed: false });

      // Line 3: Subtract returns (Line 1 - Line 2)
      const line3 = grossReceipts - returns;
      scheduleCLines.push({ line: 'Line 3', label: 'Gross income', amount: line3, isComputed: true });

      // Line 4: COGS
      const cogs = lineAmounts.get('Line 4') || 0;
      scheduleCLines.push({ line: 'Line 4', label: 'Cost of goods sold', amount: cogs, isComputed: false });

      // Line 5: Gross profit (Line 3 - Line 4)
      const grossProfit = line3 - cogs;
      scheduleCLines.push({ line: 'Line 5', label: 'Gross profit', amount: grossProfit, isComputed: true });

      // Lines 8-27: Expense lines
      let totalExpenses = 0;
      for (const def of SCHEDULE_C_LINES) {
        if (def.type !== 'expense') continue;
        const amount = lineAmounts.get(def.taxLine) || 0;
        scheduleCLines.push({ line: def.line, label: def.label, amount, isComputed: false });
        totalExpenses += amount;
      }

      // Line 28: Total expenses
      scheduleCLines.push({ line: 'Line 28', label: 'Total expenses', amount: totalExpenses, isComputed: true });

      // Line 31: Net profit (Line 5 - Line 28)
      const netProfit = grossProfit - totalExpenses;
      scheduleCLines.push({ line: 'Line 31', label: 'Net profit (or loss)', amount: netProfit, isComputed: true });

      // Quarterly tax estimate
      // Self-employment tax: 15.3% of 92.35% of net profit
      const seNetEarnings = netProfit * 0.9235;
      const seTax = Math.max(0, seNetEarnings * 0.153);

      // Estimated income tax (simplified brackets for 2024+)
      let incomeTax = 0;
      if (netProfit > 0) {
        if (netProfit <= 11600) {
          incomeTax = netProfit * 0.10;
        } else if (netProfit <= 47150) {
          incomeTax = 1160 + (netProfit - 11600) * 0.12;
        } else if (netProfit <= 100525) {
          incomeTax = 5426 + (netProfit - 47150) * 0.22;
        } else if (netProfit <= 191950) {
          incomeTax = 17168.50 + (netProfit - 100525) * 0.24;
        } else if (netProfit <= 243725) {
          incomeTax = 39110.50 + (netProfit - 191950) * 0.32;
        } else if (netProfit <= 609350) {
          incomeTax = 55678.50 + (netProfit - 243725) * 0.35;
        } else {
          incomeTax = 183647.25 + (netProfit - 609350) * 0.37;
        }
      }

      const totalEstimatedTax = seTax + incomeTax;
      const estimatedQuarterlyTax = totalEstimatedTax / 4;

      setScheduleCData({
        year,
        lines: scheduleCLines,
        netProfit,
        seTax,
        estimatedQuarterlyTax,
      });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to compute Schedule C');
    }
  }, []);

  // ── Export 1099 CSV ──
  const export1099CSV = useCallback(() => {
    if (allEligibleVendors.length === 0) return;

    const threshold = allEligibleVendors.filter((v) => v.ytdPayments >= 600);
    if (threshold.length === 0) return;

    const headers = ['Vendor Name', 'Tax ID', 'YTD Payments', '1099 Required'];
    const rows = threshold.map((v) => [
      `"${v.vendorName}"`,
      v.taxId || 'MISSING',
      v.ytdPayments.toFixed(2),
      v.ytdPayments >= 600 ? 'Yes' : 'No',
    ]);

    const csvContent = [
      headers.join(','),
      ...rows.map((r) => r.join(',')),
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `1099_vendors_${new Date().getFullYear()}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  }, [allEligibleVendors]);

  // ── Initial load ──
  useEffect(() => {
    const load = async () => {
      setLoading(true);
      setError(null);
      try {
        await Promise.all([
          fetchTaxCategories(),
          fetchAccountMappings(),
          fetchVendors1099(),
        ]);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [fetchTaxCategories, fetchAccountMappings, fetchVendors1099]);

  return {
    taxCategories,
    accountMappings,
    vendors1099,
    allEligibleVendors,
    scheduleCData,
    loading,
    error,
    updateAccountTaxCategory,
    fetchVendors1099,
    fetchScheduleC,
    export1099CSV,
    refetch: async () => {
      await Promise.all([
        fetchTaxCategories(),
        fetchAccountMappings(),
        fetchVendors1099(),
      ]);
    },
  };
}
