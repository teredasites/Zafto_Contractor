'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Download,
  FileText,
  Loader2,
  Package,
  Shield,
  TrendingUp,
  Scale,
  BookOpen,
  Users,
  Calendar,
  CheckCircle,
  AlertCircle,
  Building2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import { useCPAAccess } from '@/lib/hooks/use-cpa-access';
import type { ExportPackageData } from '@/lib/hooks/use-cpa-access';

// Ledger Navigation
const zbooksNav = [
  { label: 'Overview', href: '/dashboard/books', active: false },
  { label: 'Chart of Accounts', href: '/dashboard/books/accounts', active: false },
  { label: 'Expenses', href: '/dashboard/books/expenses', active: false },
  { label: 'Vendors', href: '/dashboard/books/vendors', active: false },
  { label: 'Banking', href: '/dashboard/books/banking', active: false },
  { label: 'Reports', href: '/dashboard/books/reports', active: false },
  { label: 'Tax & 1099', href: '/dashboard/books/tax-settings', active: false },
  { label: 'CPA Export', href: '/dashboard/books/cpa-export', active: true },
];

export default function CPAExportPage() {
  const router = useRouter();
  const { isCPA, isReadOnly, userEmail, loading: accessLoading, exportPackage, exportCSV } = useCPAAccess();

  const currentYear = new Date().getFullYear();
  const [startDate, setStartDate] = useState(`${currentYear}-01-01`);
  const [endDate, setEndDate] = useState(`${currentYear}-12-31`);
  const [packageData, setPackageData] = useState<(ExportPackageData & { scheduleE?: { properties: { propertyAddress: string; income: number; expenses: Record<string, number>; totalExpenses: number; netIncome: number }[]; totalIncome: number; totalExpenses: number; totalNet: number } }) | null>(null);
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleGeneratePackage = async () => {
    if (!startDate || !endDate) return;

    setGenerating(true);
    setError(null);
    setPackageData(null);

    const result = await exportPackage({ startDate, endDate });

    if (result) {
      // Calculate Schedule E data
      const supabase = getSupabase();
      const { data: rentData } = await supabase
        .from('rent_payments')
        .select('amount, rent_charges(property_id, properties(address_line1))')
        .gte('payment_date', startDate)
        .lte('payment_date', endDate);

      const { data: expData } = await supabase
        .from('expense_records')
        .select('total, property_id, schedule_e_category, properties(address_line1)')
        .not('property_id', 'is', null)
        .gte('expense_date', startDate)
        .lte('expense_date', endDate)
        .eq('status', 'posted');

      const propMap = new Map<string, { propertyAddress: string; income: number; expenses: Record<string, number>; totalExpenses: number; netIncome: number }>();

      for (const row of (rentData || []) as Record<string, unknown>[]) {
        const charge = row.rent_charges as Record<string, unknown> | null;
        if (!charge) continue;
        const propId = charge.property_id as string;
        const prop = charge.properties as Record<string, unknown> | null;
        if (!propMap.has(propId)) {
          propMap.set(propId, { propertyAddress: (prop?.address_line1 as string) || 'Unknown', income: 0, expenses: {}, totalExpenses: 0, netIncome: 0 });
        }
        propMap.get(propId)!.income += Number(row.amount || 0);
      }

      for (const row of (expData || []) as Record<string, unknown>[]) {
        const propId = row.property_id as string;
        const prop = row.properties as Record<string, unknown> | null;
        if (!propMap.has(propId)) {
          propMap.set(propId, { propertyAddress: (prop?.address_line1 as string) || 'Unknown', income: 0, expenses: {}, totalExpenses: 0, netIncome: 0 });
        }
        const entry = propMap.get(propId)!;
        const cat = (row.schedule_e_category as string) || 'other';
        entry.expenses[cat] = (entry.expenses[cat] || 0) + Number(row.total || 0);
        entry.totalExpenses += Number(row.total || 0);
      }

      for (const entry of propMap.values()) {
        entry.netIncome = entry.income - entry.totalExpenses;
      }

      const propArray = [...propMap.values()];

      setPackageData({
        ...result,
        scheduleE: {
          properties: propArray,
          totalIncome: propArray.reduce((s, p) => s + p.income, 0),
          totalExpenses: propArray.reduce((s, p) => s + p.totalExpenses, 0),
          totalNet: propArray.reduce((s, p) => s + p.netIncome, 0),
        },
      });
    } else {
      setError('Failed to generate export package. Please try again.');
    }
    setGenerating(false);
  };

  const downloadPnLCSV = () => {
    if (!packageData) return;
    const { pnl } = packageData;

    const allRows = [
      ...pnl.revenue.map(a => ({ ...a, section: 'Revenue' })),
      ...pnl.cogs.map(a => ({ ...a, section: 'Cost of Goods Sold' })),
      ...pnl.expenses.map(a => ({ ...a, section: 'Operating Expenses' })),
    ];

    const headers = [
      { key: 'section', label: 'Section' },
      { key: 'accountNumber', label: 'Account Number' },
      { key: 'accountName', label: 'Account Name' },
      { key: 'debits', label: 'Debits' },
      { key: 'credits', label: 'Credits' },
      { key: 'balance', label: 'Balance' },
    ];

    exportCSV(allRows, headers, `pnl_${startDate}_to_${endDate}.csv`);
  };

  const downloadBalanceSheetCSV = () => {
    if (!packageData) return;
    const { balanceSheet } = packageData;

    const allRows = [
      ...balanceSheet.assets.map(a => ({ ...a, section: 'Assets' })),
      ...balanceSheet.liabilities.map(a => ({ ...a, section: 'Liabilities' })),
      ...balanceSheet.equity.map(a => ({ ...a, section: 'Equity' })),
    ];

    const headers = [
      { key: 'section', label: 'Section' },
      { key: 'accountNumber', label: 'Account Number' },
      { key: 'accountName', label: 'Account Name' },
      { key: 'debits', label: 'Debits' },
      { key: 'credits', label: 'Credits' },
      { key: 'balance', label: 'Balance' },
    ];

    exportCSV(allRows, headers, `balance_sheet_as_of_${endDate}.csv`);
  };

  const downloadTrialBalanceCSV = () => {
    if (!packageData) return;
    const { trialBalance } = packageData;

    const headers = [
      { key: 'accountNumber', label: 'Account Number' },
      { key: 'accountName', label: 'Account Name' },
      { key: 'accountType', label: 'Account Type' },
      { key: 'debits', label: 'Total Debits' },
      { key: 'credits', label: 'Total Credits' },
      { key: 'balance', label: 'Balance' },
    ];

    exportCSV(trialBalance.accounts, headers, `trial_balance_as_of_${endDate}.csv`);
  };

  const downloadVendors1099CSV = () => {
    if (!packageData) return;
    const { vendors1099 } = packageData;

    const headers = [
      { key: 'vendorName', label: 'Vendor Name' },
      { key: 'taxId', label: 'Tax ID' },
      { key: 'ytdPayments', label: 'YTD Payments' },
      { key: 'is1099Required', label: '1099 Required' },
    ];

    exportCSV(vendors1099.vendors, headers, `1099_vendors_${startDate.substring(0, 4)}.csv`);
  };

  const downloadScheduleECSV = () => {
    if (!packageData?.scheduleE) return;
    const rows = packageData.scheduleE.properties.flatMap((p: { propertyAddress: string; income: number; expenses: Record<string, number>; totalExpenses: number; netIncome: number }) => [
      { property: p.propertyAddress, category: 'Rental Income', amount: p.income },
      ...Object.entries(p.expenses).map(([cat, amt]) => ({
        property: p.propertyAddress,
        category: cat.replace(/_/g, ' '),
        amount: -amt,
      })),
      { property: p.propertyAddress, category: 'Net Income', amount: p.netIncome },
    ]);

    const headers = [
      { key: 'property', label: 'Property' },
      { key: 'category', label: 'Category' },
      { key: 'amount', label: 'Amount' },
    ];

    exportCSV(rows, headers, `schedule_e_${startDate}_to_${endDate}.csv`);
  };

  const downloadAllCSVs = () => {
    downloadPnLCSV();
    // Small delays to avoid browser blocking multiple downloads
    setTimeout(() => downloadBalanceSheetCSV(), 200);
    setTimeout(() => downloadTrialBalanceCSV(), 400);
    setTimeout(() => downloadVendors1099CSV(), 600);
    setTimeout(() => downloadScheduleECSV(), 800);
  };

  if (accessLoading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[400px]">
        <Loader2 size={24} className="animate-spin text-muted" />
        <span className="ml-3 text-muted text-sm">Checking access...</span>
      </div>
    );
  }

  return (
    <div className="p-8 space-y-6 max-w-[1400px] mx-auto">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">CPA Export Package</h1>
          <p className="text-muted mt-1">Generate and download financial reports for your accountant</p>
        </div>
        <div className="flex items-center gap-3">
          {isCPA && (
            <Badge variant="purple">
              <Shield size={12} className="mr-1" />
              CPA Read-Only Access
            </Badge>
          )}
          {packageData && (
            <Button onClick={downloadAllCSVs}>
              <Download size={16} />
              Download All as CSV
            </Button>
          )}
        </div>
      </div>

      {/* Ledger Navigation */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
        {zbooksNav.map((tab) => (
          <button
            key={tab.label}
            onClick={() => { if (!tab.active) router.push(tab.href); }}
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

      {/* CPA Access Badge (for non-CPA users) */}
      {!isCPA && !accessLoading && (
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3 text-sm">
              <Shield size={16} className="text-muted" />
              <span className="text-muted">
                You are viewing this page with full access. CPA users will see read-only views.
              </span>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Date Range Selector */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Calendar size={16} />
            Report Period
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-end gap-4 flex-wrap">
            <div>
              <label className="text-xs text-muted block mb-1">Start Date</label>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                disabled={isReadOnly && generating}
                className="px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main focus:outline-none focus:ring-1 focus:ring-accent"
              />
            </div>
            <div>
              <label className="text-xs text-muted block mb-1">End Date</label>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                disabled={isReadOnly && generating}
                className="px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main focus:outline-none focus:ring-1 focus:ring-accent"
              />
            </div>
            <Button onClick={handleGeneratePackage} disabled={generating || !startDate || !endDate}>
              {generating ? <Loader2 size={14} className="animate-spin" /> : <Package size={14} />}
              Generate Export Package
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Error */}
      {error && (
        <Card className="border-red-200 dark:border-red-900/40">
          <CardContent className="p-4">
            <div className="flex items-center gap-3 text-sm text-red-600 dark:text-red-400">
              <AlertCircle size={16} />
              <span>{error}</span>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Loading State */}
      {generating && (
        <div className="flex items-center justify-center py-12">
          <Loader2 size={24} className="animate-spin text-muted" />
          <span className="ml-3 text-muted text-sm">Generating export package...</span>
        </div>
      )}

      {/* Export Package Results */}
      {packageData && !generating && (
        <>
          {/* Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            {/* P&L Summary */}
            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-emerald-100 dark:bg-emerald-900/30 rounded-xl">
                    <TrendingUp size={20} className="text-emerald-600 dark:text-emerald-400" />
                  </div>
                  <Button variant="ghost" size="sm" onClick={downloadPnLCSV}>
                    <Download size={14} />
                  </Button>
                </div>
                <p className="text-sm font-medium text-main">Profit & Loss</p>
                <div className="mt-3 space-y-1.5">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Revenue</span>
                    <span className="tabular-nums text-main">{formatCurrency(packageData.pnl.totalRevenue)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Expenses</span>
                    <span className="tabular-nums text-main">{formatCurrency(packageData.pnl.totalExpenses + packageData.pnl.totalCogs)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm font-semibold pt-1.5 border-t border-default">
                    <span className="text-main">Net Income</span>
                    <span className={cn('tabular-nums', packageData.pnl.netIncome >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                      {formatCurrency(packageData.pnl.netIncome)}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Balance Sheet Summary */}
            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-blue-100 dark:bg-blue-900/30 rounded-xl">
                    <Scale size={20} className="text-blue-600 dark:text-blue-400" />
                  </div>
                  <Button variant="ghost" size="sm" onClick={downloadBalanceSheetCSV}>
                    <Download size={14} />
                  </Button>
                </div>
                <p className="text-sm font-medium text-main">Balance Sheet</p>
                <div className="mt-3 space-y-1.5">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Assets</span>
                    <span className="tabular-nums text-main">{formatCurrency(packageData.balanceSheet.totalAssets)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Liabilities</span>
                    <span className="tabular-nums text-main">{formatCurrency(packageData.balanceSheet.totalLiabilities)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm font-semibold pt-1.5 border-t border-default">
                    <span className="text-main">Equity</span>
                    <span className="tabular-nums text-main">{formatCurrency(packageData.balanceSheet.totalEquity)}</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Trial Balance Summary */}
            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-purple-100 dark:bg-purple-900/30 rounded-xl">
                    <BookOpen size={20} className="text-purple-600 dark:text-purple-400" />
                  </div>
                  <Button variant="ghost" size="sm" onClick={downloadTrialBalanceCSV}>
                    <Download size={14} />
                  </Button>
                </div>
                <p className="text-sm font-medium text-main">Trial Balance</p>
                <div className="mt-3 space-y-1.5">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Total Debits</span>
                    <span className="tabular-nums text-main">{formatCurrency(packageData.trialBalance.debitTotal)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Total Credits</span>
                    <span className="tabular-nums text-main">{formatCurrency(packageData.trialBalance.creditTotal)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm pt-1.5 border-t border-default">
                    <span className="text-main font-semibold">Status</span>
                    {packageData.trialBalance.isBalanced ? (
                      <Badge variant="success">
                        <CheckCircle size={12} className="mr-1" />
                        Balanced
                      </Badge>
                    ) : (
                      <Badge variant="error">
                        <AlertCircle size={12} className="mr-1" />
                        Unbalanced
                      </Badge>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* 1099 Vendors Summary */}
            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-amber-100 dark:bg-amber-900/30 rounded-xl">
                    <Users size={20} className="text-amber-600 dark:text-amber-400" />
                  </div>
                  <Button variant="ghost" size="sm" onClick={downloadVendors1099CSV}>
                    <Download size={14} />
                  </Button>
                </div>
                <p className="text-sm font-medium text-main">1099 Vendors</p>
                <div className="mt-3 space-y-1.5">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Vendors (600+)</span>
                    <span className="tabular-nums text-main">{packageData.vendors1099.vendorCount}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm font-semibold pt-1.5 border-t border-default">
                    <span className="text-main">Total Payments</span>
                    <span className="tabular-nums text-main">{formatCurrency(packageData.vendors1099.totalPayments)}</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Schedule E Summary */}
            <Card>
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="p-2.5 bg-teal-100 dark:bg-teal-900/30 rounded-xl">
                    <Building2 size={20} className="text-teal-600 dark:text-teal-400" />
                  </div>
                  <Button variant="ghost" size="sm" onClick={downloadScheduleECSV}>
                    <Download size={14} />
                  </Button>
                </div>
                <p className="text-sm font-medium text-main">Schedule E</p>
                <div className="mt-3 space-y-1.5">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Rental Income</span>
                    <span className="tabular-nums text-main">{formatCurrency(packageData?.scheduleE?.totalIncome || 0)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Expenses</span>
                    <span className="tabular-nums text-main">{formatCurrency(packageData?.scheduleE?.totalExpenses || 0)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm font-semibold pt-1.5 border-t border-default">
                    <span className="text-main">Net Rental</span>
                    <span className={cn('tabular-nums', (packageData?.scheduleE?.totalNet || 0) >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                      {formatCurrency(packageData?.scheduleE?.totalNet || 0)}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Detailed Tables */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* P&L Detail */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0">
                <CardTitle className="text-base">P&L Detail</CardTitle>
                <Button variant="ghost" size="sm" onClick={downloadPnLCSV}>
                  <FileText size={14} />
                  CSV
                </Button>
              </CardHeader>
              <CardContent className="p-0">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-default">
                      <th className="text-left px-3 py-2 text-muted font-medium">Account</th>
                      <th className="text-right px-3 py-2 text-muted font-medium">Balance</th>
                    </tr>
                  </thead>
                  <tbody>
                    {packageData.pnl.revenue.length > 0 && (
                      <>
                        <tr className="bg-secondary/50">
                          <td colSpan={2} className="px-3 py-1.5 text-xs font-semibold text-muted uppercase tracking-wider">Revenue</td>
                        </tr>
                        {packageData.pnl.revenue.map(a => (
                          <tr key={a.accountNumber} className="border-b border-default last:border-b-0 hover:bg-secondary/50">
                            <td className="px-3 py-1.5">
                              <span className="text-muted tabular-nums mr-2">{a.accountNumber}</span>
                              <span className="text-main">{a.accountName}</span>
                            </td>
                            <td className="px-3 py-1.5 text-right tabular-nums text-main">{formatCurrency(a.balance)}</td>
                          </tr>
                        ))}
                      </>
                    )}
                    {packageData.pnl.cogs.length > 0 && (
                      <>
                        <tr className="bg-secondary/50">
                          <td colSpan={2} className="px-3 py-1.5 text-xs font-semibold text-muted uppercase tracking-wider">Cost of Goods Sold</td>
                        </tr>
                        {packageData.pnl.cogs.map(a => (
                          <tr key={a.accountNumber} className="border-b border-default last:border-b-0 hover:bg-secondary/50">
                            <td className="px-3 py-1.5">
                              <span className="text-muted tabular-nums mr-2">{a.accountNumber}</span>
                              <span className="text-main">{a.accountName}</span>
                            </td>
                            <td className="px-3 py-1.5 text-right tabular-nums text-main">{formatCurrency(a.balance)}</td>
                          </tr>
                        ))}
                      </>
                    )}
                    {packageData.pnl.expenses.length > 0 && (
                      <>
                        <tr className="bg-secondary/50">
                          <td colSpan={2} className="px-3 py-1.5 text-xs font-semibold text-muted uppercase tracking-wider">Operating Expenses</td>
                        </tr>
                        {packageData.pnl.expenses.map(a => (
                          <tr key={a.accountNumber} className="border-b border-default last:border-b-0 hover:bg-secondary/50">
                            <td className="px-3 py-1.5">
                              <span className="text-muted tabular-nums mr-2">{a.accountNumber}</span>
                              <span className="text-main">{a.accountName}</span>
                            </td>
                            <td className="px-3 py-1.5 text-right tabular-nums text-main">{formatCurrency(a.balance)}</td>
                          </tr>
                        ))}
                      </>
                    )}
                    <tr className="border-t-2 border-default font-bold">
                      <td className="px-3 py-2 text-main">Net Income</td>
                      <td className={cn('px-3 py-2 text-right tabular-nums', packageData.pnl.netIncome >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                        {formatCurrency(packageData.pnl.netIncome)}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </CardContent>
            </Card>

            {/* Balance Sheet Detail */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0">
                <CardTitle className="text-base">Balance Sheet Detail</CardTitle>
                <Button variant="ghost" size="sm" onClick={downloadBalanceSheetCSV}>
                  <FileText size={14} />
                  CSV
                </Button>
              </CardHeader>
              <CardContent className="p-0">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-default">
                      <th className="text-left px-3 py-2 text-muted font-medium">Account</th>
                      <th className="text-right px-3 py-2 text-muted font-medium">Balance</th>
                    </tr>
                  </thead>
                  <tbody>
                    {packageData.balanceSheet.assets.length > 0 && (
                      <>
                        <tr className="bg-secondary/50">
                          <td colSpan={2} className="px-3 py-1.5 text-xs font-semibold text-muted uppercase tracking-wider">Assets</td>
                        </tr>
                        {packageData.balanceSheet.assets.map(a => (
                          <tr key={a.accountNumber} className="border-b border-default last:border-b-0 hover:bg-secondary/50">
                            <td className="px-3 py-1.5">
                              <span className="text-muted tabular-nums mr-2">{a.accountNumber}</span>
                              <span className="text-main">{a.accountName}</span>
                            </td>
                            <td className="px-3 py-1.5 text-right tabular-nums text-main">{formatCurrency(a.balance)}</td>
                          </tr>
                        ))}
                        <tr className="border-b border-default font-semibold">
                          <td className="px-3 py-1.5 text-main">Total Assets</td>
                          <td className="px-3 py-1.5 text-right tabular-nums text-main">{formatCurrency(packageData.balanceSheet.totalAssets)}</td>
                        </tr>
                      </>
                    )}
                    {packageData.balanceSheet.liabilities.length > 0 && (
                      <>
                        <tr className="bg-secondary/50">
                          <td colSpan={2} className="px-3 py-1.5 text-xs font-semibold text-muted uppercase tracking-wider">Liabilities</td>
                        </tr>
                        {packageData.balanceSheet.liabilities.map(a => (
                          <tr key={a.accountNumber} className="border-b border-default last:border-b-0 hover:bg-secondary/50">
                            <td className="px-3 py-1.5">
                              <span className="text-muted tabular-nums mr-2">{a.accountNumber}</span>
                              <span className="text-main">{a.accountName}</span>
                            </td>
                            <td className="px-3 py-1.5 text-right tabular-nums text-main">{formatCurrency(a.balance)}</td>
                          </tr>
                        ))}
                      </>
                    )}
                    {packageData.balanceSheet.equity.length > 0 && (
                      <>
                        <tr className="bg-secondary/50">
                          <td colSpan={2} className="px-3 py-1.5 text-xs font-semibold text-muted uppercase tracking-wider">Equity</td>
                        </tr>
                        {packageData.balanceSheet.equity.map(a => (
                          <tr key={a.accountNumber} className="border-b border-default last:border-b-0 hover:bg-secondary/50">
                            <td className="px-3 py-1.5">
                              <span className="text-muted tabular-nums mr-2">{a.accountNumber}</span>
                              <span className="text-main">{a.accountName}</span>
                            </td>
                            <td className="px-3 py-1.5 text-right tabular-nums text-main">{formatCurrency(a.balance)}</td>
                          </tr>
                        ))}
                      </>
                    )}
                    <tr className="border-t-2 border-default font-bold">
                      <td className="px-3 py-2 text-main">Total L + E</td>
                      <td className="px-3 py-2 text-right tabular-nums text-main">
                        {formatCurrency(packageData.balanceSheet.totalLiabilities + packageData.balanceSheet.totalEquity)}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </CardContent>
            </Card>
          </div>

          {/* 1099 Vendors Table */}
          {packageData.vendors1099.vendors.length > 0 && (
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0">
                <CardTitle className="text-base">1099 Vendors (Payments $600+)</CardTitle>
                <Button variant="ghost" size="sm" onClick={downloadVendors1099CSV}>
                  <FileText size={14} />
                  CSV
                </Button>
              </CardHeader>
              <CardContent className="p-0">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-default">
                      <th className="text-left px-3 py-2 text-muted font-medium">Vendor Name</th>
                      <th className="text-left px-3 py-2 text-muted font-medium">Tax ID</th>
                      <th className="text-right px-3 py-2 text-muted font-medium">YTD Payments</th>
                      <th className="text-center px-3 py-2 text-muted font-medium">1099 Required</th>
                    </tr>
                  </thead>
                  <tbody>
                    {packageData.vendors1099.vendors.map(v => (
                      <tr key={v.vendorName} className="border-b border-default last:border-b-0 hover:bg-secondary/50">
                        <td className="px-3 py-2 text-main font-medium">{v.vendorName}</td>
                        <td className="px-3 py-2 text-muted tabular-nums">{v.taxId || 'MISSING'}</td>
                        <td className="px-3 py-2 text-right tabular-nums text-main">{formatCurrency(v.ytdPayments)}</td>
                        <td className="px-3 py-2 text-center">
                          {v.is1099Required ? (
                            <Badge variant="warning">Required</Badge>
                          ) : (
                            <Badge variant="secondary">No</Badge>
                          )}
                        </td>
                      </tr>
                    ))}
                    <tr className="border-t-2 border-default font-bold">
                      <td className="px-3 py-2 text-main" colSpan={2}>
                        Total ({packageData.vendors1099.vendorCount} vendor{packageData.vendors1099.vendorCount !== 1 ? 's' : ''})
                      </td>
                      <td className="px-3 py-2 text-right tabular-nums text-main">{formatCurrency(packageData.vendors1099.totalPayments)}</td>
                      <td />
                    </tr>
                  </tbody>
                </table>
              </CardContent>
            </Card>
          )}

          {/* Watermark */}
          <div className="text-center py-4 border-t border-default">
            <p className="text-xs text-muted">{packageData.watermark}</p>
            <p className="text-xs text-muted mt-1">
              Period: {packageData.dateRange.startDate} to {packageData.dateRange.endDate}
            </p>
          </div>
        </>
      )}
    </div>
  );
}
