'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  DollarSign,
  TrendingUp,
  TrendingDown,
  CreditCard,
  Building,
  ArrowRight,
  AlertCircle,
  AlertTriangle,
  FileText,
  PiggyBank,
  Wallet,
  Receipt,
  Users,
  Landmark,
  BarChart3,
  Calculator,
  Clock,
  CalendarCheck,
  Repeat,
  Loader2,
  BookOpen,
  Scale,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SimpleBarChart, DonutChart, DonutLegend } from '@/components/ui/charts';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { useBanking } from '@/lib/hooks/use-banking';
import { useFinancialStatements } from '@/lib/hooks/use-financial-statements';
import type { AgingRow, AccountBalance } from '@/lib/hooks/use-financial-statements';
import { useReconciliation } from '@/lib/hooks/use-reconciliation';

// Expense category colors for donut chart
const EXPENSE_COLORS = [
  '#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899',
  '#06b6d4', '#ef4444', '#84cc16', '#f97316', '#64748b',
];

// Navigation tabs for Ledger
const BOOKS_TABS = [
  { label: 'Overview', href: '/dashboard/books', active: true },
  { label: 'Chart of Accounts', href: '/dashboard/books/accounts', active: false },
  { label: 'Expenses', href: '/dashboard/books/expenses', active: false },
  { label: 'Vendors', href: '/dashboard/books/vendors', active: false },
  { label: 'Banking', href: '/dashboard/books/banking', active: false },
  { label: 'Reports', href: '/dashboard/books/reports', active: false },
  { label: 'Tax & 1099', href: '/dashboard/books/tax-settings', active: false },
  { label: 'Recurring', href: '/dashboard/books/recurring', active: false },
  { label: 'Periods', href: '/dashboard/books/periods', active: false },
];

// Quick links for Ledger sub-pages
const QUICK_LINKS = [
  { label: 'Chart of Accounts', href: '/dashboard/books/accounts', icon: BookOpen },
  { label: 'Expenses', href: '/dashboard/books/expenses', icon: Receipt },
  { label: 'Vendors', href: '/dashboard/books/vendors', icon: Users },
  { label: 'Vendor Payments', href: '/dashboard/books/vendor-payments', icon: CreditCard },
  { label: 'Banking', href: '/dashboard/books/banking', icon: Landmark },
  { label: 'Reconciliation', href: '/dashboard/books/reconciliation', icon: Calculator },
  { label: 'Reports', href: '/dashboard/books/reports', icon: BarChart3 },
  { label: 'Tax & 1099', href: '/dashboard/books/tax-settings', icon: FileText },
  { label: 'Recurring', href: '/dashboard/books/recurring', icon: Repeat },
  { label: 'Periods', href: '/dashboard/books/periods', icon: CalendarCheck },
  { label: 'Budget vs Actual', href: '/dashboard/books/budgets', icon: Scale },
];

interface PnLData {
  revenue: AccountBalance[];
  cogs: AccountBalance[];
  expenses: AccountBalance[];
  totalRevenue: number;
  totalCogs: number;
  grossProfit: number;
  totalExpenses: number;
  netIncome: number;
}

export default function BooksPage() {
  const router = useRouter();

  // Hooks
  const {
    accounts: bankAccounts,
    totalBalance,
    unreviewedCount,
    loading: bankingLoading,
  } = useBanking();

  const {
    fetchProfitAndLoss,
    fetchARaging,
    fetchAPaging,
    loading: statementsLoading,
  } = useFinancialStatements();

  const {
    reconciliations,
    loading: reconciliationLoading,
  } = useReconciliation();

  // Local state for fetched data
  const [pnlData, setPnlData] = useState<PnLData | null>(null);
  const [arAging, setArAging] = useState<AgingRow[]>([]);
  const [apAging, setApAging] = useState<AgingRow[]>([]);
  const [dataLoaded, setDataLoaded] = useState(false);

  // Fetch P&L, AR aging, AP aging on mount
  useEffect(() => {
    let cancelled = false;

    const loadData = async () => {
      const now = new Date();
      const monthStart = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
      const monthEnd = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

      const [pnl, ar, ap] = await Promise.all([
        fetchProfitAndLoss(monthStart, monthEnd),
        fetchARaging(),
        fetchAPaging(),
      ]);

      if (!cancelled) {
        setPnlData(pnl);
        setArAging(ar);
        setApAging(ap);
        setDataLoaded(true);
      }
    };

    loadData();
    return () => { cancelled = true; };
  }, [fetchProfitAndLoss, fetchARaging, fetchAPaging]);

  // Derived values
  const totalAR = arAging.reduce((s, r) => s + r.total, 0);
  const totalAP = apAging.reduce((s, r) => s + r.total, 0);
  const netIncome = pnlData?.netIncome ?? 0;
  const totalRevenue = pnlData?.totalRevenue ?? 0;
  const profitMargin = totalRevenue > 0 ? (netIncome / totalRevenue) * 100 : 0;

  // AR overdue (90+ days)
  const overdueARRows = arAging.filter(r => r.days90plus > 0);
  const overdueARTotal = arAging.reduce((s, r) => s + r.days90plus, 0);

  // AP current (due bills)
  const apCurrentTotal = apAging.reduce((s, r) => s + r.current, 0);

  // Unreconciled: accounts where last sync > 30 days ago
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const unreconciledAccounts = bankAccounts.filter(acct => {
    if (!acct.lastSyncedAt) return true;
    return new Date(acct.lastSyncedAt) < thirtyDaysAgo;
  });

  // Expense breakdown for donut chart
  const expenseChartData = (pnlData?.expenses ?? [])
    .filter(a => a.balance > 0)
    .sort((a, b) => b.balance - a.balance)
    .map((a, i) => ({
      name: a.accountName,
      value: a.balance,
      color: EXPENSE_COLORS[i % EXPENSE_COLORS.length],
    }));

  // P&L summary bar chart data
  const pnlBarData = pnlData
    ? [
        { label: 'Revenue', value: pnlData.totalRevenue, color: '#10b981' },
        { label: 'COGS', value: pnlData.totalCogs, color: '#f59e0b' },
        { label: 'Expenses', value: pnlData.totalExpenses, color: '#ef4444' },
        { label: 'Net Income', value: Math.max(pnlData.netIncome, 0), color: '#3b82f6' },
      ]
    : [];

  const isLoading = bankingLoading || statementsLoading || reconciliationLoading || !dataLoaded;

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Ledger</h1>
          <p className="text-muted mt-1">Financial dashboard</p>
        </div>
        <div className="flex items-center gap-3">
          <Button
            variant="secondary"
            onClick={() => router.push('/dashboard/books/expenses')}
          >
            <Receipt size={16} />
            Record Expense
          </Button>
          <Button onClick={() => router.push('/dashboard/books/reports')}>
            <BarChart3 size={16} />
            Run P&L
          </Button>
        </div>
      </div>

      {/* Ledger Navigation Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
        {BOOKS_TABS.map((tab) => (
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

      {/* Loading State */}
      {isLoading && (
        <div className="flex items-center justify-center py-12">
          <Loader2 size={24} className="animate-spin text-muted" />
          <span className="ml-3 text-muted text-sm">Loading financial data...</span>
        </div>
      )}

      {!isLoading && (
        <>
          {/* KPI Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            {/* Cash Position */}
            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-emerald-100 dark:bg-emerald-900/30 rounded-xl">
                    <Wallet size={20} className="text-emerald-600 dark:text-emerald-400" />
                  </div>
                </div>
                <p className="text-sm text-muted">Cash Position</p>
                <p className="text-2xl font-bold text-main mt-1">
                  {formatCurrency(totalBalance)}
                </p>
                <p className="text-xs text-muted mt-2">
                  {bankAccounts.length} account{bankAccounts.length !== 1 ? 's' : ''}
                </p>
              </CardContent>
            </Card>

            {/* Accounts Receivable */}
            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-blue-100 dark:bg-blue-900/30 rounded-xl">
                    <TrendingUp size={20} className="text-blue-600 dark:text-blue-400" />
                  </div>
                </div>
                <p className="text-sm text-muted">Accounts Receivable</p>
                <p className="text-2xl font-bold text-main mt-1">
                  {formatCurrency(totalAR)}
                </p>
                <p className="text-xs text-muted mt-2">
                  {arAging.length} customer{arAging.length !== 1 ? 's' : ''}
                </p>
              </CardContent>
            </Card>

            {/* Accounts Payable */}
            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-amber-100 dark:bg-amber-900/30 rounded-xl">
                    <TrendingDown size={20} className="text-amber-600 dark:text-amber-400" />
                  </div>
                </div>
                <p className="text-sm text-muted">Accounts Payable</p>
                <p className="text-2xl font-bold text-main mt-1">
                  {formatCurrency(totalAP)}
                </p>
                <p className="text-xs text-muted mt-2">
                  {apAging.length} vendor{apAging.length !== 1 ? 's' : ''}
                </p>
              </CardContent>
            </Card>

            {/* Net Income (MTD) */}
            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-purple-100 dark:bg-purple-900/30 rounded-xl">
                    <DollarSign size={20} className="text-purple-600 dark:text-purple-400" />
                  </div>
                </div>
                <p className="text-sm text-muted">Net Income (MTD)</p>
                <p className={cn(
                  'text-2xl font-bold mt-1',
                  netIncome >= 0 ? 'text-emerald-600' : 'text-red-600'
                )}>
                  {formatCurrency(netIncome)}
                </p>
                <p className="text-xs text-muted mt-2">
                  {formatCurrency(totalRevenue)} revenue
                </p>
              </CardContent>
            </Card>

            {/* Profit Margin */}
            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-indigo-100 dark:bg-indigo-900/30 rounded-xl">
                    <PiggyBank size={20} className="text-indigo-600 dark:text-indigo-400" />
                  </div>
                </div>
                <p className="text-sm text-muted">Profit Margin</p>
                <p className={cn(
                  'text-2xl font-bold mt-1',
                  profitMargin >= 0 ? 'text-emerald-600' : 'text-red-600'
                )}>
                  {profitMargin.toFixed(1)}%
                </p>
                <p className="text-xs text-muted mt-2">
                  Net income / revenue
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Charts Row */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* P&L Summary Bar Chart */}
            <Card className="lg:col-span-2">
              <CardHeader className="flex flex-row items-center justify-between space-y-0">
                <div>
                  <CardTitle>Profit & Loss Summary</CardTitle>
                  <p className="text-sm text-muted mt-1">Current month-to-date</p>
                </div>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => router.push('/dashboard/books/reports')}
                >
                  Full Report
                  <ArrowRight size={14} />
                </Button>
              </CardHeader>
              <CardContent>
                {pnlBarData.length > 0 && (pnlData?.totalRevenue ?? 0) > 0 ? (
                  <div className="space-y-4">
                    <div className="h-52">
                      <SimpleBarChart
                        data={pnlBarData}
                        height={208}
                        formatValue={(v) => formatCurrency(v)}
                      />
                    </div>
                    <div className="grid grid-cols-4 gap-3 pt-2 border-t border-main">
                      {pnlBarData.map((item) => (
                        <div key={item.label} className="text-center">
                          <p className="text-xs text-muted">{item.label}</p>
                          <p className="text-sm font-semibold text-main mt-0.5">
                            {formatCurrency(item.value)}
                          </p>
                        </div>
                      ))}
                    </div>
                  </div>
                ) : (
                  <div className="flex flex-col items-center justify-center py-12 text-center">
                    <BarChart3 size={32} className="text-muted mb-3" />
                    <p className="text-sm text-muted">
                      No P&L data for this period yet.
                    </p>
                    <p className="text-xs text-muted mt-1">
                      Revenue and expenses will appear here once journal entries are posted.
                    </p>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Expenses by Category Donut */}
            <Card>
              <CardHeader>
                <CardTitle>Expenses by Category</CardTitle>
                <p className="text-sm text-muted mt-1">MTD breakdown</p>
              </CardHeader>
              <CardContent>
                {expenseChartData.length > 0 ? (
                  <>
                    <div className="flex items-center justify-center mb-4">
                      <DonutChart
                        data={expenseChartData}
                        size={140}
                        thickness={20}
                        centerValue={formatCurrency(pnlData?.totalExpenses ?? 0)}
                        centerLabel="Total"
                      />
                    </div>
                    <DonutLegend
                      data={expenseChartData.slice(0, 6)}
                      formatValue={(v) => formatCurrency(v)}
                    />
                  </>
                ) : (
                  <div className="flex flex-col items-center justify-center py-12 text-center">
                    <Receipt size={32} className="text-muted mb-3" />
                    <p className="text-sm text-muted">No expenses recorded yet.</p>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Alerts Section */}
          <div>
            <h2 className="text-lg font-semibold text-main mb-4">Alerts & Action Items</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              {/* Overdue AR */}
              <Card className={cn(
                overdueARRows.length > 0 && 'border-red-200 dark:border-red-900/40'
              )}>
                <CardContent className="p-5">
                  <div className="flex items-start gap-3">
                    <div className={cn(
                      'p-2 rounded-lg',
                      overdueARRows.length > 0
                        ? 'bg-red-100 dark:bg-red-900/30'
                        : 'bg-secondary'
                    )}>
                      <AlertCircle size={18} className={cn(
                        overdueARRows.length > 0
                          ? 'text-red-600 dark:text-red-400'
                          : 'text-muted'
                      )} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-main">Overdue AR (90+ days)</p>
                      {overdueARRows.length > 0 ? (
                        <>
                          <p className="text-lg font-bold text-red-600 mt-1">
                            {formatCurrency(overdueARTotal)}
                          </p>
                          <p className="text-xs text-muted mt-1">
                            {overdueARRows.length} customer{overdueARRows.length !== 1 ? 's' : ''}
                          </p>
                        </>
                      ) : (
                        <p className="text-sm text-emerald-600 mt-1">All clear</p>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Unreviewed Transactions */}
              <Card className={cn(
                unreviewedCount > 0 && 'border-amber-200 dark:border-amber-900/40'
              )}>
                <CardContent className="p-5">
                  <div className="flex items-start gap-3">
                    <div className={cn(
                      'p-2 rounded-lg',
                      unreviewedCount > 0
                        ? 'bg-amber-100 dark:bg-amber-900/30'
                        : 'bg-secondary'
                    )}>
                      <Clock size={18} className={cn(
                        unreviewedCount > 0
                          ? 'text-amber-600 dark:text-amber-400'
                          : 'text-muted'
                      )} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-main">Unreviewed Transactions</p>
                      {unreviewedCount > 0 ? (
                        <>
                          <p className="text-lg font-bold text-amber-600 mt-1">
                            {unreviewedCount}
                          </p>
                          <p className="text-xs text-muted mt-1">
                            Need categorization
                          </p>
                        </>
                      ) : (
                        <p className="text-sm text-emerald-600 mt-1">All reviewed</p>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Unreconciled Accounts */}
              <Card className={cn(
                unreconciledAccounts.length > 0 && 'border-amber-200 dark:border-amber-900/40'
              )}>
                <CardContent className="p-5">
                  <div className="flex items-start gap-3">
                    <div className={cn(
                      'p-2 rounded-lg',
                      unreconciledAccounts.length > 0
                        ? 'bg-amber-100 dark:bg-amber-900/30'
                        : 'bg-secondary'
                    )}>
                      <AlertTriangle size={18} className={cn(
                        unreconciledAccounts.length > 0
                          ? 'text-amber-600 dark:text-amber-400'
                          : 'text-muted'
                      )} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-main">Unreconciled Accounts</p>
                      {unreconciledAccounts.length > 0 ? (
                        <>
                          <p className="text-lg font-bold text-amber-600 mt-1">
                            {unreconciledAccounts.length}
                          </p>
                          <p className="text-xs text-muted mt-1">
                            Last sync &gt; 30 days ago
                          </p>
                        </>
                      ) : (
                        <p className="text-sm text-emerald-600 mt-1">All reconciled</p>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Due Bills (AP Current) */}
              <Card className={cn(
                apCurrentTotal > 0 && 'border-blue-200 dark:border-blue-900/40'
              )}>
                <CardContent className="p-5">
                  <div className="flex items-start gap-3">
                    <div className={cn(
                      'p-2 rounded-lg',
                      apCurrentTotal > 0
                        ? 'bg-blue-100 dark:bg-blue-900/30'
                        : 'bg-secondary'
                    )}>
                      <FileText size={18} className={cn(
                        apCurrentTotal > 0
                          ? 'text-blue-600 dark:text-blue-400'
                          : 'text-muted'
                      )} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-main">Due Bills</p>
                      {apCurrentTotal > 0 ? (
                        <>
                          <p className="text-lg font-bold text-blue-600 mt-1">
                            {formatCurrency(apCurrentTotal)}
                          </p>
                          <p className="text-xs text-muted mt-1">
                            Current payables
                          </p>
                        </>
                      ) : (
                        <p className="text-sm text-emerald-600 mt-1">No bills due</p>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>

          {/* Quick Links Grid */}
          <Card>
            <CardHeader>
              <CardTitle>Quick Links</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
                {QUICK_LINKS.map((link) => {
                  const Icon = link.icon;
                  return (
                    <button
                      key={link.href}
                      onClick={() => router.push(link.href)}
                      className="p-4 bg-secondary rounded-xl hover:bg-surface-hover cursor-pointer transition-colors group text-left"
                    >
                      <div className="flex items-center gap-3 mb-1.5">
                        <div className="p-2 bg-accent-light rounded-lg text-accent group-hover:bg-accent group-hover:text-white transition-colors">
                          <Icon size={18} />
                        </div>
                      </div>
                      <p className="text-sm font-medium text-main">{link.label}</p>
                    </button>
                  );
                })}
              </div>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}
