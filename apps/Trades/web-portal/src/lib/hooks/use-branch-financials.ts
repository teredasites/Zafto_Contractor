'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// TYPES
// ============================================================

export interface BranchSummary {
  id: string;
  name: string;
  code: string | null;
  isActive: boolean;
}

export interface BranchPnL {
  revenue: number;
  cogs: number;
  grossProfit: number;
  expenses: number;
  netIncome: number;
}

export interface BranchComparison {
  branchId: string;
  branchName: string;
  revenue: number;
  expenses: number;
  netIncome: number;
  profitMargin: number;
}

export interface BranchPerformance {
  branchId: string;
  branchName: string;
  revenue: number;
  expenses: number;
  netIncome: number;
  profitMargin: number;
}

// ============================================================
// MAPPERS
// ============================================================

function mapBranchSummary(row: Record<string, unknown>): BranchSummary {
  return {
    id: row.id as string,
    name: row.name as string,
    code: row.code as string | null,
    isActive: (row.is_active as boolean) ?? true,
  };
}

// ============================================================
// HOOK
// ============================================================

export function useBranchFinancials() {
  const [branches, setBranches] = useState<BranchSummary[]>([]);
  const [selectedBranchId, setSelectedBranchId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch branches on mount
  const fetchBranches = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('branches')
        .select('id, name, code, is_active')
        .eq('is_active', true)
        .order('name');

      if (err) throw err;

      const rows: Record<string, unknown>[] = data || [];
      setBranches(rows.map(mapBranchSummary));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load branches';
      setError(msg);
      setBranches([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchBranches();
  }, [fetchBranches]);

  // Set selected branch
  const setBranchId = useCallback((id: string | null) => {
    setSelectedBranchId(id);
  }, []);

  // Fetch P&L for a single branch
  const fetchBranchPnL = useCallback(async (
    branchId: string,
    startDate: string,
    endDate: string,
  ): Promise<BranchPnL> => {
    try {
      const supabase = getSupabase();

      // Get journal entry lines filtered by branch_id, joined to chart_of_accounts for account_type
      // and to journal_entries for entry_date + status filtering
      const { data, error: err } = await supabase
        .from('journal_entry_lines')
        .select('debit_amount, credit_amount, branch_id, chart_of_accounts!inner(account_type), journal_entries!inner(entry_date, status)')
        .eq('branch_id', branchId)
        .eq('journal_entries.status', 'posted')
        .gte('journal_entries.entry_date', startDate)
        .lte('journal_entries.entry_date', endDate);

      if (err) throw err;

      const lines: Record<string, unknown>[] = data || [];

      let revenue = 0;
      let cogs = 0;
      let expenses = 0;

      for (const line of lines) {
        const account = line.chart_of_accounts as Record<string, unknown>;
        const accountType = account?.account_type as string;
        const debit = Number(line.debit_amount) || 0;
        const credit = Number(line.credit_amount) || 0;

        // Revenue: credit-normal, so balance = credits - debits
        if (accountType === 'revenue') {
          revenue += credit - debit;
        } else if (accountType === 'cogs') {
          cogs += debit - credit;
        } else if (accountType === 'expense') {
          expenses += debit - credit;
        }
      }

      const grossProfit = revenue - cogs;
      const netIncome = grossProfit - expenses;

      return {
        revenue: Math.round(revenue * 100) / 100,
        cogs: Math.round(cogs * 100) / 100,
        grossProfit: Math.round(grossProfit * 100) / 100,
        expenses: Math.round(expenses * 100) / 100,
        netIncome: Math.round(netIncome * 100) / 100,
      };
    } catch {
      return { revenue: 0, cogs: 0, grossProfit: 0, expenses: 0, netIncome: 0 };
    }
  }, []);

  // Fetch comparison for multiple branches in parallel
  const fetchBranchComparison = useCallback(async (
    branchIds: string[],
    startDate: string,
    endDate: string,
  ): Promise<BranchComparison[]> => {
    try {
      const results = await Promise.all(
        branchIds.map(async (branchId) => {
          const pnl = await fetchBranchPnL(branchId, startDate, endDate);
          const branch = branches.find(b => b.id === branchId);
          const totalExpenses = pnl.cogs + pnl.expenses;
          const profitMargin = pnl.revenue > 0
            ? (pnl.netIncome / pnl.revenue) * 100
            : 0;

          return {
            branchId,
            branchName: branch?.name || 'Unknown Branch',
            revenue: pnl.revenue,
            expenses: totalExpenses,
            netIncome: pnl.netIncome,
            profitMargin: Math.round(profitMargin * 10) / 10,
          };
        })
      );

      return results;
    } catch {
      return [];
    }
  }, [branches, fetchBranchPnL]);

  // Fetch performance for all branches
  const fetchBranchPerformance = useCallback(async (
    startDate: string,
    endDate: string,
  ): Promise<BranchPerformance[]> => {
    try {
      if (branches.length === 0) return [];

      const results = await Promise.all(
        branches.map(async (branch) => {
          const pnl = await fetchBranchPnL(branch.id, startDate, endDate);
          const totalExpenses = pnl.cogs + pnl.expenses;
          const profitMargin = pnl.revenue > 0
            ? (pnl.netIncome / pnl.revenue) * 100
            : 0;

          return {
            branchId: branch.id,
            branchName: branch.name,
            revenue: pnl.revenue,
            expenses: totalExpenses,
            netIncome: pnl.netIncome,
            profitMargin: Math.round(profitMargin * 10) / 10,
          };
        })
      );

      // Sort by revenue descending
      return results.sort((a, b) => b.revenue - a.revenue);
    } catch {
      return [];
    }
  }, [branches, fetchBranchPnL]);

  return {
    branches,
    selectedBranchId,
    setBranchId,
    fetchBranchPnL,
    fetchBranchComparison,
    fetchBranchPerformance,
    loading,
    error,
    refresh: fetchBranches,
  };
}
