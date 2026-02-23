'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  Building2,
  GitCompareArrows,
  TrendingUp,
  TrendingDown,
  DollarSign,
  Loader2,
  ArrowLeft,
  CheckSquare,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import {
  useBranchFinancials,
} from '@/lib/hooks/use-branch-financials';
import type {
  BranchPnL,
  BranchPerformance,
  BranchComparison,
} from '@/lib/hooks/use-branch-financials';
import { TierGate } from '@/components/permission-gate';
import { useTranslation } from '@/lib/translations';

// Ledger Navigation
const zbooksNav = [
  { label: 'Overview', href: '/dashboard/books', active: false },
  { label: 'Chart of Accounts', href: '/dashboard/books/accounts', active: false },
  { label: 'Reports', href: '/dashboard/books/reports', active: false },
  { label: 'Periods', href: '/dashboard/books/periods', active: false },
  { label: 'Branches', href: '/dashboard/books/branches', active: true },
];

function getDefaultDateRange(): { start: string; end: string } {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth();
  const start = new Date(year, month, 1);
  const end = new Date(year, month + 1, 0);
  return {
    start: start.toISOString().split('T')[0],
    end: end.toISOString().split('T')[0],
  };
}

const fmt = (n: number) =>
  n.toLocaleString();

export default function BranchFinancialsPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const {
    branches,
    selectedBranchId,
    setBranchId,
    fetchBranchPnL,
    fetchBranchPerformance,
    fetchBranchComparison,
    loading: branchesLoading,
    error: branchesError,
  } = useBranchFinancials();

  // Date range
  const defaults = getDefaultDateRange();
  const [startDate, setStartDate] = useState(defaults.start);
  const [endDate, setEndDate] = useState(defaults.end);

  // Data states
  const [performance, setPerformance] = useState<BranchPerformance[]>([]);
  const [branchPnL, setBranchPnL] = useState<BranchPnL | null>(null);
  const [comparison, setComparison] = useState<BranchComparison[]>([]);
  const [dataLoading, setDataLoading] = useState(false);

  // Comparison mode
  const [compareMode, setCompareMode] = useState(false);
  const [compareBranchIds, setCompareBranchIds] = useState<string[]>([]);

  // Load data when branch selection or date range changes
  useEffect(() => {
    if (branchesLoading) return;

    let cancelled = false;

    const loadData = async () => {
      setDataLoading(true);

      try {
        if (selectedBranchId) {
          // Specific branch selected -- fetch branch P&L
          const pnl = await fetchBranchPnL(selectedBranchId, startDate, endDate);
          if (!cancelled) {
            setBranchPnL(pnl);
            setPerformance([]);
          }
        } else {
          // All branches -- fetch performance overview
          const perf = await fetchBranchPerformance(startDate, endDate);
          if (!cancelled) {
            setPerformance(perf);
            setBranchPnL(null);
          }
        }
      } catch {
        // Gracefully handle errors
      } finally {
        if (!cancelled) setDataLoading(false);
      }
    };

    loadData();
    return () => { cancelled = true; };
  }, [selectedBranchId, startDate, endDate, branchesLoading, fetchBranchPnL, fetchBranchPerformance]);

  // Load comparison data
  useEffect(() => {
    if (!compareMode || compareBranchIds.length < 2) {
      setComparison([]);
      return;
    }

    let cancelled = false;

    const loadComparison = async () => {
      setDataLoading(true);
      try {
        const result = await fetchBranchComparison(compareBranchIds, startDate, endDate);
        if (!cancelled) setComparison(result);
      } catch {
        // Gracefully handle
      } finally {
        if (!cancelled) setDataLoading(false);
      }
    };

    loadComparison();
    return () => { cancelled = true; };
  }, [compareMode, compareBranchIds, startDate, endDate, fetchBranchComparison]);

  // Toggle branch in comparison multi-select (max 3)
  const toggleCompareBranch = (branchId: string) => {
    setCompareBranchIds((prev) => {
      if (prev.includes(branchId)) {
        return prev.filter((id) => id !== branchId);
      }
      if (prev.length >= 3) return prev;
      return [...prev, branchId];
    });
  };

  // Performance totals
  const totalRevenue = performance.reduce((s, b) => s + b.revenue, 0);
  const totalExpenses = performance.reduce((s, b) => s + b.expenses, 0);
  const totalNetIncome = performance.reduce((s, b) => s + b.netIncome, 0);
  const totalProfitMargin = totalRevenue > 0
    ? Math.round(((totalNetIncome / totalRevenue) * 100) * 10) / 10
    : 0;

  const selectedBranch = branches.find(b => b.id === selectedBranchId);

  return (
    <TierGate minimumTier="business" fallback={
      <div className="space-y-8 animate-fade-in">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('booksBranches.title')}</h1>
          <p className="text-[13px] text-muted mt-1">Multi-branch P&L and performance comparison</p>
        </div>
        <Card>
          <CardContent className="text-center py-12">
            <Building2 size={40} className="mx-auto mb-3 text-muted opacity-40" />
            <h3 className="text-lg font-semibold text-main">Business Plan Feature</h3>
            <p className="text-sm text-muted mt-2 max-w-md mx-auto">
              Multi-branch financial reporting with consolidated P&L, performance comparison, and branch benchmarking is available on the Business plan ($249.99/mo).
            </p>
            <Button variant="secondary" className="mt-6">Upgrade Plan</Button>
          </CardContent>
        </Card>
      </div>
    }>
    <div className="space-y-6 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={() => router.push('/dashboard/books')}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
          >
            <ArrowLeft size={18} className="text-muted" />
          </button>
          <div>
            <h1 className="text-2xl font-semibold text-main">Branch Financials</h1>
            <p className="text-muted mt-0.5">
              {selectedBranch
                ? `P&L for ${selectedBranch.name}`
                : 'Consolidated multi-branch performance'}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant="purple">Enterprise</Badge>
          {!compareMode && (
            <Button
              variant="secondary"
              onClick={() => {
                setCompareMode(true);
                setBranchId(null);
                setCompareBranchIds([]);
              }}
            >
              <GitCompareArrows size={16} />
              Compare Branches
            </Button>
          )}
          {compareMode && (
            <Button
              variant="secondary"
              onClick={() => {
                setCompareMode(false);
                setCompareBranchIds([]);
                setComparison([]);
              }}
            >
              <X size={16} />
              Exit Compare
            </Button>
          )}
        </div>
      </div>

      {/* Ledger Navigation Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
        {zbooksNav.map((tab) => (
          <button
            key={tab.label}
            onClick={() => {
              if (!tab.active) router.push(tab.href);
            }}
            className={cn(
              'px-4 py-2 text-sm font-medium rounded-lg transition-colors whitespace-nowrap',
              tab.active
                ? 'bg-accent text-white'
                : 'bg-secondary text-muted hover:text-main'
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Controls: Branch Selector + Date Range */}
      <Card>
        <CardContent className="p-4">
          <div className="flex items-end gap-4 flex-wrap">
            {!compareMode && (
              <div>
                <label className="text-xs text-muted block mb-1">Branch</label>
                <select
                  value={selectedBranchId || ''}
                  onChange={(e) => setBranchId(e.target.value || null)}
                  className="px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main focus:outline-none focus:ring-1 focus:ring-accent min-w-[220px]"
                >
                  <option value="">All Branches (Consolidated)</option>
                  {branches.map((b) => (
                    <option key={b.id} value={b.id}>
                      {b.name}
                      {b.code ? ` (${b.code})` : ''}
                    </option>
                  ))}
                </select>
              </div>
            )}
            <div>
              <label className="text-xs text-muted block mb-1">{t('common.startDate')}</label>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main focus:outline-none focus:ring-1 focus:ring-accent"
              />
            </div>
            <div>
              <label className="text-xs text-muted block mb-1">{t('common.endDate')}</label>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main focus:outline-none focus:ring-1 focus:ring-accent"
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Error State */}
      {branchesError && (
        <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-700 dark:text-red-300 text-sm">
          {branchesError}
        </div>
      )}

      {/* Loading State */}
      {(branchesLoading || dataLoading) && (
        <div className="flex items-center justify-center py-12">
          <Loader2 size={24} className="animate-spin text-muted" />
          <span className="ml-3 text-muted text-sm">Loading branch financial data...</span>
        </div>
      )}

      {/* ============================================================ */}
      {/* COMPARISON MODE */}
      {/* ============================================================ */}
      {compareMode && !branchesLoading && !dataLoading && (
        <>
          {/* Branch multi-select */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Select Branches to Compare (2-3)</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex flex-wrap gap-2">
                {branches.map((b) => {
                  const isSelected = compareBranchIds.includes(b.id);
                  return (
                    <button
                      key={b.id}
                      onClick={() => toggleCompareBranch(b.id)}
                      className={cn(
                        'flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors border',
                        isSelected
                          ? 'bg-accent text-white border-accent'
                          : 'bg-secondary text-muted hover:text-main border-default'
                      )}
                    >
                      {isSelected && <CheckSquare size={14} />}
                      <Building2 size={14} />
                      {b.name}
                      {b.code ? ` (${b.code})` : ''}
                    </button>
                  );
                })}
              </div>
              {branches.length === 0 && (
                <p className="text-sm text-muted py-4 text-center">
                  No branches found. Create branches in Enterprise settings first.
                </p>
              )}
            </CardContent>
          </Card>

          {/* Comparison Table */}
          {comparison.length >= 2 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Side-by-Side P&L Comparison</CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-default">
                        <th className="text-left px-4 py-3 text-muted font-medium">Metric</th>
                        {comparison.map((c) => (
                          <th key={c.branchId} className="text-right px-4 py-3 text-muted font-medium">
                            {c.branchName}
                          </th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      <tr className="border-b border-default hover:bg-secondary/50">
                        <td className="px-4 py-3 text-main font-medium">Revenue</td>
                        {comparison.map((c) => (
                          <td key={c.branchId} className="px-4 py-3 text-right tabular-nums text-emerald-600 font-medium">
                            {fmt(c.revenue)}
                          </td>
                        ))}
                      </tr>
                      <tr className="border-b border-default hover:bg-secondary/50">
                        <td className="px-4 py-3 text-main font-medium">Expenses</td>
                        {comparison.map((c) => (
                          <td key={c.branchId} className="px-4 py-3 text-right tabular-nums text-red-600 font-medium">
                            {fmt(c.expenses)}
                          </td>
                        ))}
                      </tr>
                      <tr className="border-b border-default hover:bg-secondary/50">
                        <td className="px-4 py-3 text-main font-medium">Net Income</td>
                        {comparison.map((c) => (
                          <td key={c.branchId} className={cn(
                            'px-4 py-3 text-right tabular-nums font-semibold',
                            c.netIncome >= 0 ? 'text-emerald-600' : 'text-red-600'
                          )}>
                            {fmt(c.netIncome)}
                          </td>
                        ))}
                      </tr>
                      <tr className="hover:bg-secondary/50">
                        <td className="px-4 py-3 text-main font-medium">Profit Margin</td>
                        {comparison.map((c) => (
                          <td key={c.branchId} className={cn(
                            'px-4 py-3 text-right tabular-nums font-semibold',
                            c.profitMargin >= 0 ? 'text-emerald-600' : 'text-red-600'
                          )}>
                            {c.profitMargin.toFixed(1)}%
                          </td>
                        ))}
                      </tr>
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>
          )}

          {compareBranchIds.length < 2 && compareBranchIds.length > 0 && (
            <div className="text-center py-8 text-sm text-muted">
              Select at least 2 branches to compare.
            </div>
          )}
        </>
      )}

      {/* ============================================================ */}
      {/* ALL BRANCHES (CONSOLIDATED) VIEW */}
      {/* ============================================================ */}
      {!compareMode && !selectedBranchId && !branchesLoading && !dataLoading && (
        <>
          {/* Summary KPI Cards */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-emerald-100 dark:bg-emerald-900/30 rounded-xl">
                    <TrendingUp size={20} className="text-emerald-600 dark:text-emerald-400" />
                  </div>
                </div>
                <p className="text-sm text-muted">{t('common.revenue')}</p>
                <p className="text-2xl font-bold text-main mt-1 tabular-nums">
                  {formatCurrency(totalRevenue)}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-red-100 dark:bg-red-900/30 rounded-xl">
                    <TrendingDown size={20} className="text-red-600 dark:text-red-400" />
                  </div>
                </div>
                <p className="text-sm text-muted">{t('common.expenses')}</p>
                <p className="text-2xl font-bold text-main mt-1 tabular-nums">
                  {formatCurrency(totalExpenses)}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-blue-100 dark:bg-blue-900/30 rounded-xl">
                    <DollarSign size={20} className="text-blue-600 dark:text-blue-400" />
                  </div>
                </div>
                <p className="text-sm text-muted">{t('common.netIncome')}</p>
                <p className={cn(
                  'text-2xl font-bold mt-1 tabular-nums',
                  totalNetIncome >= 0 ? 'text-emerald-600' : 'text-red-600'
                )}>
                  {formatCurrency(totalNetIncome)}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-purple-100 dark:bg-purple-900/30 rounded-xl">
                    <Building2 size={20} className="text-purple-600 dark:text-purple-400" />
                  </div>
                </div>
                <p className="text-sm text-muted">{t('common.profitMargin')}</p>
                <p className={cn(
                  'text-2xl font-bold mt-1 tabular-nums',
                  totalProfitMargin >= 0 ? 'text-emerald-600' : 'text-red-600'
                )}>
                  {totalProfitMargin.toFixed(1)}%
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Branch Performance Table */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Branch Performance</CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-default">
                      <th className="text-left px-4 py-3 text-muted font-medium">Branch</th>
                      <th className="text-right px-4 py-3 text-muted font-medium">Revenue</th>
                      <th className="text-right px-4 py-3 text-muted font-medium">Expenses</th>
                      <th className="text-right px-4 py-3 text-muted font-medium">Net Income</th>
                      <th className="text-right px-4 py-3 text-muted font-medium">Margin</th>
                    </tr>
                  </thead>
                  <tbody>
                    {performance.length === 0 ? (
                      <tr>
                        <td colSpan={5} className="px-4 py-12 text-center text-muted">
                          <Building2 size={32} className="mx-auto mb-3 text-muted" />
                          <p className="text-sm">No branch data available.</p>
                          <p className="text-xs text-muted mt-1">
                            Create branches in Enterprise settings and assign journal entries to branches.
                          </p>
                        </td>
                      </tr>
                    ) : (
                      <>
                        {performance.map((b) => (
                          <tr
                            key={b.branchId}
                            className="border-b border-default last:border-b-0 hover:bg-secondary/50 cursor-pointer"
                            onClick={() => setBranchId(b.branchId)}
                          >
                            <td className="px-4 py-3">
                              <div className="flex items-center gap-2">
                                <Building2 size={14} className="text-muted" />
                                <span className="font-medium text-main">{b.branchName}</span>
                              </div>
                            </td>
                            <td className="px-4 py-3 text-right tabular-nums text-emerald-600 font-medium">
                              {formatCurrency(b.revenue)}
                            </td>
                            <td className="px-4 py-3 text-right tabular-nums text-red-600 font-medium">
                              {formatCurrency(b.expenses)}
                            </td>
                            <td className={cn(
                              'px-4 py-3 text-right tabular-nums font-semibold',
                              b.netIncome >= 0 ? 'text-emerald-600' : 'text-red-600'
                            )}>
                              {formatCurrency(b.netIncome)}
                            </td>
                            <td className={cn(
                              'px-4 py-3 text-right tabular-nums font-semibold',
                              b.profitMargin >= 0 ? 'text-emerald-600' : 'text-red-600'
                            )}>
                              {b.profitMargin.toFixed(1)}%
                            </td>
                          </tr>
                        ))}
                        {/* Totals Row */}
                        <tr className="border-t-2 border-default font-bold bg-secondary/30">
                          <td className="px-4 py-3 text-main">Total</td>
                          <td className="px-4 py-3 text-right tabular-nums text-emerald-600">
                            {formatCurrency(totalRevenue)}
                          </td>
                          <td className="px-4 py-3 text-right tabular-nums text-red-600">
                            {formatCurrency(totalExpenses)}
                          </td>
                          <td className={cn(
                            'px-4 py-3 text-right tabular-nums',
                            totalNetIncome >= 0 ? 'text-emerald-600' : 'text-red-600'
                          )}>
                            {formatCurrency(totalNetIncome)}
                          </td>
                          <td className={cn(
                            'px-4 py-3 text-right tabular-nums',
                            totalProfitMargin >= 0 ? 'text-emerald-600' : 'text-red-600'
                          )}>
                            {totalProfitMargin.toFixed(1)}%
                          </td>
                        </tr>
                      </>
                    )}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        </>
      )}

      {/* ============================================================ */}
      {/* SPECIFIC BRANCH VIEW */}
      {/* ============================================================ */}
      {!compareMode && selectedBranchId && branchPnL && !branchesLoading && !dataLoading && (
        <>
          {/* Branch P&L Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
            <Card>
              <CardContent className="p-4">
                <p className="text-xs text-muted uppercase tracking-wide">{t('common.revenue')}</p>
                <p className="text-lg font-semibold text-emerald-600 mt-1 tabular-nums">
                  {formatCurrency(branchPnL.revenue)}
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4">
                <p className="text-xs text-muted uppercase tracking-wide">COGS</p>
                <p className="text-lg font-semibold text-amber-600 mt-1 tabular-nums">
                  {formatCurrency(branchPnL.cogs)}
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4">
                <p className="text-xs text-muted uppercase tracking-wide">{t('common.grossProfit')}</p>
                <p className={cn(
                  'text-lg font-semibold mt-1 tabular-nums',
                  branchPnL.grossProfit >= 0 ? 'text-emerald-600' : 'text-red-600'
                )}>
                  {formatCurrency(branchPnL.grossProfit)}
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4">
                <p className="text-xs text-muted uppercase tracking-wide">{t('common.expenses')}</p>
                <p className="text-lg font-semibold text-red-600 mt-1 tabular-nums">
                  {formatCurrency(branchPnL.expenses)}
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4">
                <p className="text-xs text-muted uppercase tracking-wide">{t('common.netIncome')}</p>
                <p className={cn(
                  'text-lg font-semibold mt-1 tabular-nums',
                  branchPnL.netIncome >= 0 ? 'text-emerald-600' : 'text-red-600'
                )}>
                  {formatCurrency(branchPnL.netIncome)}
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Branch P&L Detail Card */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-base">
                  Profit & Loss -- {selectedBranch?.name || 'Branch'}
                </CardTitle>
                <Badge
                  variant={branchPnL.netIncome >= 0 ? 'success' : 'error'}
                >
                  {branchPnL.netIncome >= 0 ? 'Profitable' : 'Net Loss'}
                </Badge>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {/* Revenue */}
                <div className="flex items-center justify-between py-2 px-3 bg-emerald-50 dark:bg-emerald-900/10 rounded-lg">
                  <span className="text-sm font-medium text-main">{t('common.revenue')}</span>
                  <span className="text-sm font-semibold text-emerald-600 tabular-nums">
                    {formatCurrency(branchPnL.revenue)}
                  </span>
                </div>

                {/* COGS */}
                <div className="flex items-center justify-between py-2 px-3">
                  <span className="text-sm text-muted">Cost of Goods Sold</span>
                  <span className="text-sm font-medium text-amber-600 tabular-nums">
                    ({formatCurrency(branchPnL.cogs)})
                  </span>
                </div>

                {/* Gross Profit */}
                <div className="flex items-center justify-between py-2 px-3 bg-secondary/50 rounded-lg border-t border-b border-default">
                  <span className="text-sm font-semibold text-main">{t('common.grossProfit')}</span>
                  <span className={cn(
                    'text-sm font-semibold tabular-nums',
                    branchPnL.grossProfit >= 0 ? 'text-emerald-600' : 'text-red-600'
                  )}>
                    {formatCurrency(branchPnL.grossProfit)}
                  </span>
                </div>

                {/* Expenses */}
                <div className="flex items-center justify-between py-2 px-3">
                  <span className="text-sm text-muted">Operating Expenses</span>
                  <span className="text-sm font-medium text-red-600 tabular-nums">
                    ({formatCurrency(branchPnL.expenses)})
                  </span>
                </div>

                {/* Net Income */}
                <div className="flex items-center justify-between py-3 px-3 bg-accent/10 rounded-lg border border-accent/20">
                  <span className="text-base font-bold text-main">{t('common.netIncome')}</span>
                  <span className={cn(
                    'text-base font-bold tabular-nums',
                    branchPnL.netIncome >= 0 ? 'text-emerald-600' : 'text-red-600'
                  )}>
                    {formatCurrency(branchPnL.netIncome)}
                  </span>
                </div>

                {/* Profit Margin */}
                {branchPnL.revenue > 0 && (
                  <div className="flex items-center justify-between py-2 px-3">
                    <span className="text-sm text-muted">{t('common.profitMargin')}</span>
                    <span className={cn(
                      'text-sm font-semibold tabular-nums',
                      branchPnL.netIncome >= 0 ? 'text-emerald-600' : 'text-red-600'
                    )}>
                      {((branchPnL.netIncome / branchPnL.revenue) * 100).toFixed(1)}%
                    </span>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </>
      )}

      {/* Empty state when no branches exist */}
      {!branchesLoading && !dataLoading && branches.length === 0 && !branchesError && (
        <Card>
          <CardContent className="p-12 text-center">
            <Building2 size={48} className="mx-auto text-muted mb-4" />
            <h2 className="text-lg font-semibold text-main mb-2">No Branches Configured</h2>
            <p className="text-sm text-muted max-w-md mx-auto">
              Branch financials require the Enterprise tier with multi-branch support enabled.
              Set up branches in your Enterprise settings to see branch-level P&L and comparisons.
            </p>
          </CardContent>
        </Card>
      )}
    </div>
    </TierGate>
  );
}
