'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  RefreshCw,
  TrendingUp,
  FileText,
  BarChart3,
  Users,
  Building,
  BookOpen,
  Scale,
  Briefcase,
  Download,
  CheckCircle,
  AlertCircle,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import { useFinancialStatements } from '@/lib/hooks/use-financial-statements';
import type { AccountBalance, AgingRow, JournalDetail } from '@/lib/hooks/use-financial-statements';
import { useAccounts } from '@/lib/hooks/use-accounts';
import { useProperties } from '@/lib/hooks/use-properties';
import { useTranslation } from '@/lib/translations';

// Ledger Navigation
const zbooksNav = [
  { label: 'Overview', href: '/dashboard/books', active: false },
  { label: 'Banking', href: '/dashboard/books/banking', active: false },
  { label: 'Reconciliation', href: '/dashboard/books/reconciliation', active: false },
  { label: 'Reports', href: '/dashboard/books/reports', active: true },
];

type ReportTab = 'pnl' | 'balance_sheet' | 'cash_flow' | 'ar_aging' | 'ap_aging' | 'gl_detail' | 'trial_balance' | 'schedule_e' | 'job_costing';

const reportTabs: { key: ReportTab; label: string; icon: typeof TrendingUp }[] = [
  { key: 'pnl', label: 'P&L', icon: TrendingUp },
  { key: 'balance_sheet', label: 'Balance Sheet', icon: Scale },
  { key: 'cash_flow', label: 'Cash Flow', icon: BarChart3 },
  { key: 'ar_aging', label: 'AR Aging', icon: Users },
  { key: 'ap_aging', label: 'AP Aging', icon: Building },
  { key: 'gl_detail', label: 'GL Detail', icon: BookOpen },
  { key: 'trial_balance', label: 'Trial Balance', icon: FileText },
  { key: 'schedule_e', label: 'Schedule E', icon: Building },
  { key: 'job_costing', label: 'Job Costing', icon: Briefcase },
];

function getDateRange(period: string): { start: string; end: string } {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth();

  switch (period) {
    case 'this_month': {
      const start = new Date(year, month, 1);
      const end = new Date(year, month + 1, 0);
      return { start: start.toISOString().split('T')[0], end: end.toISOString().split('T')[0] };
    }
    case 'this_quarter': {
      const qStart = Math.floor(month / 3) * 3;
      const start = new Date(year, qStart, 1);
      const end = new Date(year, qStart + 3, 0);
      return { start: start.toISOString().split('T')[0], end: end.toISOString().split('T')[0] };
    }
    case 'this_year': {
      return { start: `${year}-01-01`, end: `${year}-12-31` };
    }
    case 'last_month': {
      const start = new Date(year, month - 1, 1);
      const end = new Date(year, month, 0);
      return { start: start.toISOString().split('T')[0], end: end.toISOString().split('T')[0] };
    }
    case 'last_year': {
      return { start: `${year - 1}-01-01`, end: `${year - 1}-12-31` };
    }
    default:
      return { start: `${year}-01-01`, end: now.toISOString().split('T')[0] };
  }
}

// Account Section component for P&L and Balance Sheet
function AccountSection({ title, accounts, className }: {
  title: string;
  accounts: AccountBalance[];
  className?: string;
}) {
  const total = accounts.reduce((s, a) => s + a.balance, 0);
  if (accounts.length === 0) return null;
  return (
    <div className={className}>
      <h3 className="text-sm font-semibold text-main mb-2">{title}</h3>
      {accounts.map(a => (
        <div key={a.accountId} className="flex items-center justify-between py-1.5 px-2 hover:bg-secondary/50 rounded text-sm">
          <span className="text-muted tabular-nums mr-3">{a.accountNumber}</span>
          <span className="flex-1 text-main">{a.accountName}</span>
          <span className="tabular-nums text-main font-medium">{formatCurrency(a.balance)}</span>
        </div>
      ))}
      <div className="flex items-center justify-between py-2 px-2 border-t border-default mt-1 font-semibold text-sm">
        <span className="text-main">Total {title}</span>
        <span className="tabular-nums text-main">{formatCurrency(total)}</span>
      </div>
    </div>
  );
}

// Aging Table
function AgingTable({ rows, entityLabel }: { rows: AgingRow[]; entityLabel: string }) {
  const totals = rows.reduce((t, r) => ({
    current: t.current + r.current,
    days1to30: t.days1to30 + r.days1to30,
    days31to60: t.days31to60 + r.days31to60,
    days61to90: t.days61to90 + r.days61to90,
    days90plus: t.days90plus + r.days90plus,
    total: t.total + r.total,
  }), { current: 0, days1to30: 0, days31to60: 0, days61to90: 0, days90plus: 0, total: 0 });

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-default">
            <th className="text-left px-3 py-2 text-muted font-medium">{entityLabel}</th>
            <th className="text-right px-3 py-2 text-muted font-medium">Current</th>
            <th className="text-right px-3 py-2 text-muted font-medium">1-30</th>
            <th className="text-right px-3 py-2 text-muted font-medium">31-60</th>
            <th className="text-right px-3 py-2 text-muted font-medium">61-90</th>
            <th className="text-right px-3 py-2 text-muted font-medium">90+</th>
            <th className="text-right px-3 py-2 text-muted font-medium">Total</th>
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 ? (
            <tr>
              <td colSpan={7} className="px-3 py-8 text-center text-muted">No outstanding balances</td>
            </tr>
          ) : (
            <>
              {rows.map(r => (
                <tr key={r.id} className="border-b border-default last:border-b-0 hover:bg-secondary/50">
                  <td className="px-3 py-2 text-main font-medium">{r.name}</td>
                  <td className="px-3 py-2 text-right tabular-nums text-main">{r.current > 0 ? formatCurrency(r.current) : '-'}</td>
                  <td className="px-3 py-2 text-right tabular-nums text-main">{r.days1to30 > 0 ? formatCurrency(r.days1to30) : '-'}</td>
                  <td className="px-3 py-2 text-right tabular-nums text-amber-600">{r.days31to60 > 0 ? formatCurrency(r.days31to60) : '-'}</td>
                  <td className="px-3 py-2 text-right tabular-nums text-orange-600">{r.days61to90 > 0 ? formatCurrency(r.days61to90) : '-'}</td>
                  <td className="px-3 py-2 text-right tabular-nums text-red-500 font-medium">{r.days90plus > 0 ? formatCurrency(r.days90plus) : '-'}</td>
                  <td className="px-3 py-2 text-right tabular-nums text-main font-semibold">{formatCurrency(r.total)}</td>
                </tr>
              ))}
              <tr className="border-t-2 border-default font-semibold">
                <td className="px-3 py-2 text-main">Total</td>
                <td className="px-3 py-2 text-right tabular-nums text-main">{formatCurrency(totals.current)}</td>
                <td className="px-3 py-2 text-right tabular-nums text-main">{formatCurrency(totals.days1to30)}</td>
                <td className="px-3 py-2 text-right tabular-nums text-amber-600">{formatCurrency(totals.days31to60)}</td>
                <td className="px-3 py-2 text-right tabular-nums text-orange-600">{formatCurrency(totals.days61to90)}</td>
                <td className="px-3 py-2 text-right tabular-nums text-red-500">{formatCurrency(totals.days90plus)}</td>
                <td className="px-3 py-2 text-right tabular-nums text-main">{formatCurrency(totals.total)}</td>
              </tr>
            </>
          )}
        </tbody>
      </table>
    </div>
  );
}

interface ScheduleEPropertyReport {
  propertyId: string;
  propertyAddress: string;
  income: number;
  expenses: Record<string, number>;
  totalExpenses: number;
  netIncome: number;
}

interface ScheduleEData {
  properties: ScheduleEPropertyReport[];
  totalIncome: number;
  totalExpenses: number;
  totalNet: number;
}

interface JobCostingLine {
  jobId: string;
  jobName: string;
  revenue: number;
  costs: number;
  profit: number;
  margin: number;
}

interface JobCostingData {
  jobs: JobCostingLine[];
  totalRevenue: number;
  totalCosts: number;
  totalProfit: number;
  overallMargin: number;
}

const SCHEDULE_E_CATEGORIES: { key: string; label: string }[] = [
  { key: 'advertising', label: 'Advertising' },
  { key: 'auto_and_travel', label: 'Auto and travel' },
  { key: 'cleaning_maintenance', label: 'Cleaning and maintenance' },
  { key: 'commissions', label: 'Commissions' },
  { key: 'insurance', label: 'Insurance' },
  { key: 'legal_professional', label: 'Legal and other professional fees' },
  { key: 'management_fees', label: 'Management fees' },
  { key: 'mortgage_interest', label: 'Mortgage interest paid' },
  { key: 'other_interest', label: 'Other interest' },
  { key: 'repairs', label: 'Repairs' },
  { key: 'supplies', label: 'Supplies' },
  { key: 'taxes', label: 'Taxes' },
  { key: 'utilities', label: 'Utilities' },
  { key: 'depreciation', label: 'Depreciation expense or depletion' },
  { key: 'other', label: 'Other expenses' },
];

export default function FinancialReportsPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const {
    loading,
    fetchProfitAndLoss,
    fetchBalanceSheet,
    fetchCashFlow,
    fetchARaging,
    fetchAPaging,
    fetchGLDetail,
    fetchTrialBalance,
  } = useFinancialStatements();

  const { accounts } = useAccounts();

  const [activeTab, setActiveTab] = useState<ReportTab>('pnl');
  const [period, setPeriod] = useState('this_year');
  const [asOfDate, setAsOfDate] = useState(new Date().toISOString().split('T')[0]);
  const [customStart, setCustomStart] = useState('');
  const [customEnd, setCustomEnd] = useState('');

  // GL Detail state
  const [selectedAccountId, setSelectedAccountId] = useState('');

  // Report data
  const [pnlData, setPnlData] = useState<Awaited<ReturnType<typeof fetchProfitAndLoss>> | null>(null);
  const [bsData, setBsData] = useState<Awaited<ReturnType<typeof fetchBalanceSheet>> | null>(null);
  const [cfData, setCfData] = useState<Awaited<ReturnType<typeof fetchCashFlow>> | null>(null);
  const [arData, setArData] = useState<AgingRow[]>([]);
  const [apData, setApData] = useState<AgingRow[]>([]);
  const [glData, setGlData] = useState<{ entries: JournalDetail[]; openingBalance: number; closingBalance: number } | null>(null);
  const [tbData, setTbData] = useState<Awaited<ReturnType<typeof fetchTrialBalance>> | null>(null);
  const [scheduleEData, setScheduleEData] = useState<ScheduleEData | null>(null);
  const [jobCostingData, setJobCostingData] = useState<JobCostingData | null>(null);
  const [reportLoading, setReportLoading] = useState(false);

  const runReport = async () => {
    setReportLoading(true);
    const range = period === 'custom'
      ? { start: customStart, end: customEnd }
      : getDateRange(period);

    switch (activeTab) {
      case 'pnl':
        setPnlData(await fetchProfitAndLoss(range.start, range.end));
        break;
      case 'balance_sheet':
        setBsData(await fetchBalanceSheet(asOfDate));
        break;
      case 'cash_flow':
        setCfData(await fetchCashFlow(range.start, range.end));
        break;
      case 'ar_aging':
        setArData(await fetchARaging());
        break;
      case 'ap_aging':
        setApData(await fetchAPaging());
        break;
      case 'gl_detail':
        if (selectedAccountId) {
          setGlData(await fetchGLDetail(selectedAccountId, range.start, range.end));
        }
        break;
      case 'trial_balance':
        setTbData(await fetchTrialBalance(asOfDate));
        break;
      case 'schedule_e': {
        const supabase = getSupabase();
        // Get rent payments (income) by property
        const { data: rentData } = await supabase
          .from('rent_payments')
          .select('amount, rent_charges(property_id, properties(address_line1))')
          .gte('payment_date', range.start)
          .lte('payment_date', range.end);

        // Get expenses allocated to properties
        const { data: expData } = await supabase
          .from('expense_records')
          .select('total, property_id, schedule_e_category, properties(address_line1)')
          .not('property_id', 'is', null)
          .gte('expense_date', range.start)
          .lte('expense_date', range.end)
          .eq('status', 'posted');

        // Aggregate by property
        const propMap = new Map<string, ScheduleEPropertyReport>();

        for (const row of (rentData || []) as Record<string, unknown>[]) {
          const charge = row.rent_charges as Record<string, unknown> | null;
          if (!charge) continue;
          const propId = charge.property_id as string;
          const prop = charge.properties as Record<string, unknown> | null;
          if (!propMap.has(propId)) {
            propMap.set(propId, {
              propertyId: propId,
              propertyAddress: (prop?.address_line1 as string) || 'Unknown',
              income: 0,
              expenses: {},
              totalExpenses: 0,
              netIncome: 0,
            });
          }
          const entry = propMap.get(propId)!;
          entry.income += Number(row.amount || 0);
        }

        for (const row of (expData || []) as Record<string, unknown>[]) {
          const propId = row.property_id as string;
          const prop = row.properties as Record<string, unknown> | null;
          if (!propMap.has(propId)) {
            propMap.set(propId, {
              propertyId: propId,
              propertyAddress: (prop?.address_line1 as string) || 'Unknown',
              income: 0,
              expenses: {},
              totalExpenses: 0,
              netIncome: 0,
            });
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
        setScheduleEData({
          properties: propArray,
          totalIncome: propArray.reduce((s, p) => s + p.income, 0),
          totalExpenses: propArray.reduce((s, p) => s + p.totalExpenses, 0),
          totalNet: propArray.reduce((s, p) => s + p.netIncome, 0),
        });
        break;
      }
      case 'job_costing': {
        const supabase = getSupabase();

        // Revenue: invoices linked to jobs
        const { data: invData } = await supabase
          .from('invoices')
          .select('job_id, total, jobs!inner(id, name)')
          .not('job_id', 'is', null)
          .in('status', ['sent', 'paid', 'partial', 'overdue'])
          .gte('issue_date', range.start)
          .lte('issue_date', range.end);

        // Costs: expenses linked to jobs
        const { data: costData } = await supabase
          .from('expense_records')
          .select('job_id, amount, jobs!inner(id, name)')
          .not('job_id', 'is', null)
          .in('status', ['approved', 'posted'])
          .gte('expense_date', range.start)
          .lte('expense_date', range.end);

        // Aggregate by job
        const jobMap = new Map<string, { name: string; revenue: number; costs: number }>();

        for (const row of (invData || []) as Record<string, unknown>[]) {
          const jid = row.job_id as string;
          const jobObj = row.jobs as { name: string } | null;
          if (!jobMap.has(jid)) {
            jobMap.set(jid, { name: jobObj?.name || 'Unknown Job', revenue: 0, costs: 0 });
          }
          jobMap.get(jid)!.revenue += Number(row.total || 0);
        }

        for (const row of (costData || []) as Record<string, unknown>[]) {
          const jid = row.job_id as string;
          const jobObj = row.jobs as { name: string } | null;
          if (!jobMap.has(jid)) {
            jobMap.set(jid, { name: jobObj?.name || 'Unknown Job', revenue: 0, costs: 0 });
          }
          jobMap.get(jid)!.costs += Number(row.amount || 0);
        }

        const jobLines: JobCostingLine[] = [...jobMap.entries()].map(([jobId, { name, revenue, costs }]) => {
          const profit = revenue - costs;
          const margin = revenue > 0 ? (profit / revenue) * 100 : 0;
          return { jobId, jobName: name, revenue, costs, profit, margin };
        });

        // Sort by revenue descending
        jobLines.sort((a, b) => b.revenue - a.revenue);

        const totalRevenue = jobLines.reduce((s, j) => s + j.revenue, 0);
        const totalCosts = jobLines.reduce((s, j) => s + j.costs, 0);
        const totalProfit = totalRevenue - totalCosts;
        const overallMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;

        setJobCostingData({ jobs: jobLines, totalRevenue, totalCosts, totalProfit, overallMargin });
        break;
      }
    }
    setReportLoading(false);
  };

  // Auto-run on tab change
  useEffect(() => {
    runReport();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab]);

  const needsDateRange = ['pnl', 'cash_flow', 'gl_detail', 'schedule_e', 'job_costing'].includes(activeTab);
  const needsAsOfDate = ['balance_sheet', 'trial_balance'].includes(activeTab);
  const needsAccountSelect = activeTab === 'gl_detail';

  return (
    <div className="p-8 space-y-6 max-w-[1400px] mx-auto">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('booksReports.title')}</h1>
          <p className="text-muted mt-1">Generate and review financial statements</p>
        </div>
        <Button variant="secondary" onClick={() => window.print()}>
          <Download size={16} />
          Print / PDF
        </Button>
      </div>

      {/* Ledger Navigation */}
      <div className="flex items-center gap-2">
        {zbooksNav.map((tab) => (
          <button
            key={tab.label}
            onClick={() => { if (!tab.active) router.push(tab.href); }}
            className={cn(
              'px-4 py-2 text-sm font-medium rounded-lg transition-colors',
              tab.active
                ? 'bg-accent text-white'
                : 'bg-secondary text-muted hover:text-main'
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Report Type Tabs */}
      <div className="flex items-center gap-1 flex-wrap">
        {reportTabs.map(({ key, label, icon: Icon }) => (
          <button
            key={key}
            onClick={() => setActiveTab(key)}
            className={cn(
              'flex items-center gap-1.5 px-3 py-2 text-sm font-medium rounded-lg transition-colors',
              activeTab === key
                ? 'bg-accent text-white'
                : 'bg-secondary text-muted hover:text-main'
            )}
          >
            <Icon size={14} />
            {label}
          </button>
        ))}
      </div>

      {/* Controls */}
      <Card>
        <CardContent className="p-4">
          <div className="flex items-end gap-4 flex-wrap">
            {needsDateRange && (
              <>
                <div>
                  <label className="text-xs text-muted block mb-1">Period</label>
                  <select
                    value={period}
                    onChange={(e) => setPeriod(e.target.value)}
                    className="px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main focus:outline-none focus:ring-1 focus:ring-accent"
                  >
                    <option value="this_month">{t('common.thisMonth')}</option>
                    <option value="last_month">Last Month</option>
                    <option value="this_quarter">This Quarter</option>
                    <option value="this_year">This Year</option>
                    <option value="last_year">Last Year</option>
                    <option value="custom">Custom</option>
                  </select>
                </div>
                {period === 'custom' && (
                  <>
                    <div>
                      <label className="text-xs text-muted block mb-1">Start</label>
                      <input type="date" value={customStart} onChange={(e) => setCustomStart(e.target.value)}
                        className="px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main focus:outline-none focus:ring-1 focus:ring-accent" />
                    </div>
                    <div>
                      <label className="text-xs text-muted block mb-1">End</label>
                      <input type="date" value={customEnd} onChange={(e) => setCustomEnd(e.target.value)}
                        className="px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main focus:outline-none focus:ring-1 focus:ring-accent" />
                    </div>
                  </>
                )}
              </>
            )}
            {needsAsOfDate && (
              <div>
                <label className="text-xs text-muted block mb-1">As of Date</label>
                <input type="date" value={asOfDate} onChange={(e) => setAsOfDate(e.target.value)}
                  className="px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main focus:outline-none focus:ring-1 focus:ring-accent" />
              </div>
            )}
            {needsAccountSelect && (
              <div className="flex-1">
                <label className="text-xs text-muted block mb-1">Account</label>
                <select
                  value={selectedAccountId}
                  onChange={(e) => setSelectedAccountId(e.target.value)}
                  className="w-full px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main focus:outline-none focus:ring-1 focus:ring-accent"
                >
                  <option value="">Select account...</option>
                  {accounts.map(a => (
                    <option key={a.id} value={a.id}>{a.accountNumber} — {a.accountName}</option>
                  ))}
                </select>
              </div>
            )}
            <Button onClick={runReport} disabled={reportLoading}>
              {reportLoading ? <RefreshCw size={14} className="animate-spin" /> : <BarChart3 size={14} />}
              Run Report
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Report Content */}
      {reportLoading ? (
        <Card>
          <CardContent className="p-12 flex items-center justify-center">
            <RefreshCw size={24} className="animate-spin text-muted" />
          </CardContent>
        </Card>
      ) : (
        <>
          {/* P&L */}
          {activeTab === 'pnl' && pnlData && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Profit & Loss Statement</CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                <AccountSection title="Revenue" accounts={pnlData.revenue} />
                <AccountSection title="Cost of Goods Sold" accounts={pnlData.cogs} />
                <div className="flex items-center justify-between py-3 px-2 bg-secondary/50 rounded-lg font-semibold text-sm">
                  <span className="text-main">{t('common.grossProfit')}</span>
                  <span className={cn('tabular-nums', pnlData.grossProfit >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                    {formatCurrency(pnlData.grossProfit)}
                  </span>
                </div>
                <AccountSection title="Operating Expenses" accounts={pnlData.expenses} />
                <div className="flex items-center justify-between py-4 px-3 bg-accent/10 rounded-lg font-bold text-base border border-accent/20">
                  <span className="text-main">{t('common.netIncome')}</span>
                  <span className={cn('tabular-nums', pnlData.netIncome >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                    {formatCurrency(pnlData.netIncome)}
                  </span>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Balance Sheet */}
          {activeTab === 'balance_sheet' && bsData && (
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle className="text-base">{t('common.balanceSheet')}</CardTitle>
                  <Badge variant={bsData.isBalanced ? 'success' : 'error'}>
                    {bsData.isBalanced ? 'Balanced' : 'Out of Balance'}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent className="space-y-6">
                <AccountSection title="Assets" accounts={bsData.assets} />
                <div className="flex items-center justify-between py-3 px-2 bg-secondary/50 rounded-lg font-semibold text-sm">
                  <span className="text-main">{t('common.totalAssets')}</span>
                  <span className="tabular-nums text-main">{formatCurrency(bsData.totalAssets)}</span>
                </div>

                <AccountSection title="Liabilities" accounts={bsData.liabilities} />
                <AccountSection title="Equity" accounts={bsData.equity} />
                {bsData.currentYearNetIncome !== 0 && (
                  <div className="flex items-center justify-between py-1.5 px-2 text-sm">
                    <span className="text-muted italic">Current Year Net Income</span>
                    <span className="tabular-nums text-main">{formatCurrency(bsData.currentYearNetIncome)}</span>
                  </div>
                )}
                <div className="flex items-center justify-between py-3 px-2 bg-secondary/50 rounded-lg font-semibold text-sm">
                  <span className="text-main">Total Liabilities + Equity</span>
                  <span className="tabular-nums text-main">
                    {formatCurrency(bsData.totalLiabilities + bsData.totalEquity)}
                  </span>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Cash Flow */}
          {activeTab === 'cash_flow' && cfData && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Cash Flow Statement</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div>
                    <h3 className="text-sm font-semibold text-main mb-2">Operating Activities</h3>
                    <div className="space-y-1 text-sm">
                      <div className="flex justify-between px-2 py-1"><span className="text-muted">{t('common.netIncome')}</span><span className="tabular-nums text-main">{formatCurrency(cfData.netIncome)}</span></div>
                      <div className="flex justify-between px-2 py-1"><span className="text-muted">AR Change</span><span className="tabular-nums text-main">{formatCurrency(-cfData.arChange)}</span></div>
                      <div className="flex justify-between px-2 py-1"><span className="text-muted">AP Change</span><span className="tabular-nums text-main">{formatCurrency(cfData.apChange)}</span></div>
                      <div className="flex justify-between px-2 py-2 border-t border-default font-semibold"><span className="text-main">Net Operating</span><span className="tabular-nums text-main">{formatCurrency(cfData.operatingActivities)}</span></div>
                    </div>
                  </div>
                  <div>
                    <h3 className="text-sm font-semibold text-main mb-2">Investing Activities</h3>
                    <div className="flex justify-between px-2 py-2 text-sm font-semibold"><span className="text-main">Equipment / Vehicles</span><span className="tabular-nums text-main">{formatCurrency(-cfData.investingActivities)}</span></div>
                  </div>
                  <div>
                    <h3 className="text-sm font-semibold text-main mb-2">Financing Activities</h3>
                    <div className="flex justify-between px-2 py-2 text-sm font-semibold"><span className="text-main">Loans / Equity</span><span className="tabular-nums text-main">{formatCurrency(cfData.financingActivities)}</span></div>
                  </div>
                  <div className="flex items-center justify-between py-4 px-3 bg-accent/10 rounded-lg font-bold text-base border border-accent/20">
                    <span className="text-main">Net Change in Cash</span>
                    <span className={cn('tabular-nums', cfData.netCashChange >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                      {formatCurrency(cfData.netCashChange)}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* AR Aging */}
          {activeTab === 'ar_aging' && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Accounts Receivable Aging</CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                <AgingTable rows={arData} entityLabel="Customer" />
              </CardContent>
            </Card>
          )}

          {/* AP Aging */}
          {activeTab === 'ap_aging' && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Accounts Payable Aging</CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                <AgingTable rows={apData} entityLabel="Vendor" />
              </CardContent>
            </Card>
          )}

          {/* GL Detail */}
          {activeTab === 'gl_detail' && glData && (
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle className="text-base">General Ledger Detail</CardTitle>
                  <div className="text-sm text-muted">
                    Opening: <span className="font-medium text-main tabular-nums">{formatCurrency(glData.openingBalance)}</span>
                    {' | '}
                    Closing: <span className="font-medium text-main tabular-nums">{formatCurrency(glData.closingBalance)}</span>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="p-0">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-default">
                      <th className="text-left px-3 py-2 text-muted font-medium">{t('common.date')}</th>
                      <th className="text-left px-3 py-2 text-muted font-medium">Reference</th>
                      <th className="text-left px-3 py-2 text-muted font-medium">Memo</th>
                      <th className="text-right px-3 py-2 text-muted font-medium">Debit</th>
                      <th className="text-right px-3 py-2 text-muted font-medium">Credit</th>
                      <th className="text-right px-3 py-2 text-muted font-medium">Balance</th>
                    </tr>
                  </thead>
                  <tbody>
                    {glData.entries.length === 0 ? (
                      <tr><td colSpan={6} className="px-3 py-8 text-center text-muted">No entries for this period</td></tr>
                    ) : (
                      glData.entries.map(e => (
                        <tr key={e.id} className="border-b border-default last:border-b-0 hover:bg-secondary/50">
                          <td className="px-3 py-2 text-main tabular-nums">{e.entryDate}</td>
                          <td className="px-3 py-2 text-muted">{e.entryReference || '-'}</td>
                          <td className="px-3 py-2 text-main truncate max-w-[300px]">{e.memo || '-'}</td>
                          <td className="px-3 py-2 text-right tabular-nums text-main">{e.debit > 0 ? formatCurrency(e.debit) : ''}</td>
                          <td className="px-3 py-2 text-right tabular-nums text-main">{e.credit > 0 ? formatCurrency(e.credit) : ''}</td>
                          <td className="px-3 py-2 text-right tabular-nums text-main font-medium">{formatCurrency(e.runningBalance)}</td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </CardContent>
            </Card>
          )}

          {/* Trial Balance */}
          {activeTab === 'trial_balance' && tbData && (
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle className="text-base">{t('common.trialBalance')}</CardTitle>
                  <div className="flex items-center gap-2">
                    {tbData.isBalanced ? (
                      <Badge variant="success"><CheckCircle size={12} className="mr-1" />Balanced</Badge>
                    ) : (
                      <Badge variant="error"><AlertCircle size={12} className="mr-1" />Out of Balance</Badge>
                    )}
                  </div>
                </div>
              </CardHeader>
              <CardContent className="p-0">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-default">
                      <th className="text-left px-3 py-2 text-muted font-medium">Account #</th>
                      <th className="text-left px-3 py-2 text-muted font-medium">Account Name</th>
                      <th className="text-right px-3 py-2 text-muted font-medium">Debit</th>
                      <th className="text-right px-3 py-2 text-muted font-medium">Credit</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tbData.accounts.map(a => {
                      const isDebit = (a.normalBalance === 'debit' && a.balance >= 0) || (a.normalBalance === 'credit' && a.balance < 0);
                      const absBalance = Math.abs(a.balance);
                      return (
                        <tr key={a.accountId} className="border-b border-default last:border-b-0 hover:bg-secondary/50">
                          <td className="px-3 py-2 text-muted tabular-nums">{a.accountNumber}</td>
                          <td className="px-3 py-2 text-main">{a.accountName}</td>
                          <td className="px-3 py-2 text-right tabular-nums text-main">{isDebit ? formatCurrency(absBalance) : ''}</td>
                          <td className="px-3 py-2 text-right tabular-nums text-main">{!isDebit ? formatCurrency(absBalance) : ''}</td>
                        </tr>
                      );
                    })}
                    <tr className="border-t-2 border-default font-bold">
                      <td className="px-3 py-3" colSpan={2}>Totals</td>
                      <td className="px-3 py-3 text-right tabular-nums text-main">{formatCurrency(tbData.debitTotal)}</td>
                      <td className="px-3 py-3 text-right tabular-nums text-main">{formatCurrency(tbData.creditTotal)}</td>
                    </tr>
                  </tbody>
                </table>
              </CardContent>
            </Card>
          )}

          {/* Schedule E */}
          {activeTab === 'schedule_e' && scheduleEData && (
            <div className="space-y-6">
              {/* Summary */}
              <div className="grid grid-cols-3 gap-4">
                <Card><CardContent className="p-4 text-center">
                  <p className="text-xs text-muted uppercase">Total Rental Income</p>
                  <p className="text-xl font-semibold text-main mt-1 tabular-nums">{formatCurrency(scheduleEData.totalIncome)}</p>
                </CardContent></Card>
                <Card><CardContent className="p-4 text-center">
                  <p className="text-xs text-muted uppercase">{t('common.expenses')}</p>
                  <p className="text-xl font-semibold text-main mt-1 tabular-nums">{formatCurrency(scheduleEData.totalExpenses)}</p>
                </CardContent></Card>
                <Card><CardContent className="p-4 text-center">
                  <p className="text-xs text-muted uppercase">Net Rental Income</p>
                  <p className={cn('text-xl font-semibold mt-1 tabular-nums', scheduleEData.totalNet >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                    {formatCurrency(scheduleEData.totalNet)}
                  </p>
                </CardContent></Card>
              </div>

              {/* Per-property breakdown */}
              {scheduleEData.properties.map((prop) => (
                <Card key={prop.propertyId}>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0">
                    <CardTitle className="text-base">{prop.propertyAddress}</CardTitle>
                    <span className={cn('text-sm font-semibold tabular-nums', prop.netIncome >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                      Net: {formatCurrency(prop.netIncome)}
                    </span>
                  </CardHeader>
                  <CardContent className="p-0">
                    <table className="w-full text-sm">
                      <tbody>
                        <tr className="bg-secondary/50">
                          <td className="px-3 py-1.5 font-semibold text-main" colSpan={2}>Rental Income</td>
                        </tr>
                        <tr className="border-b border-default">
                          <td className="px-3 py-1.5 text-muted pl-6">Rents received</td>
                          <td className="px-3 py-1.5 text-right tabular-nums text-main">{formatCurrency(prop.income)}</td>
                        </tr>
                        <tr className="bg-secondary/50">
                          <td className="px-3 py-1.5 font-semibold text-main" colSpan={2}>Expenses</td>
                        </tr>
                        {SCHEDULE_E_CATEGORIES.map(cat => {
                          const amount = prop.expenses[cat.key] || 0;
                          if (amount === 0) return null;
                          return (
                            <tr key={cat.key} className="border-b border-default">
                              <td className="px-3 py-1.5 text-muted pl-6">{cat.label}</td>
                              <td className="px-3 py-1.5 text-right tabular-nums text-main">{formatCurrency(amount)}</td>
                            </tr>
                          );
                        })}
                        <tr className="border-t-2 border-default font-semibold">
                          <td className="px-3 py-2 text-main">Total Expenses</td>
                          <td className="px-3 py-2 text-right tabular-nums text-main">{formatCurrency(prop.totalExpenses)}</td>
                        </tr>
                      </tbody>
                    </table>
                  </CardContent>
                </Card>
              ))}

              {scheduleEData.properties.length === 0 && (
                <Card>
                  <CardContent className="p-12 text-center text-muted">
                    <Building size={40} className="mx-auto mb-2 opacity-50" />
                    <p>No property income or expenses found for this period</p>
                    <p className="text-xs mt-1">Allocate expenses to properties in Ledger Expenses</p>
                  </CardContent>
                </Card>
              )}
            </div>
          )}

          {/* Job Costing P&L */}
          {activeTab === 'job_costing' && jobCostingData && (
            <div className="space-y-6">
              {/* Summary Cards */}
              <div className="grid grid-cols-4 gap-4">
                <Card><CardContent className="p-4 text-center">
                  <p className="text-xs text-muted uppercase">{t('common.revenue')}</p>
                  <p className="text-xl font-semibold text-main mt-1 tabular-nums">{formatCurrency(jobCostingData.totalRevenue)}</p>
                </CardContent></Card>
                <Card><CardContent className="p-4 text-center">
                  <p className="text-xs text-muted uppercase">Total Costs</p>
                  <p className="text-xl font-semibold text-main mt-1 tabular-nums">{formatCurrency(jobCostingData.totalCosts)}</p>
                </CardContent></Card>
                <Card><CardContent className="p-4 text-center">
                  <p className="text-xs text-muted uppercase">Total Profit</p>
                  <p className={cn('text-xl font-semibold mt-1 tabular-nums', jobCostingData.totalProfit >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                    {formatCurrency(jobCostingData.totalProfit)}
                  </p>
                </CardContent></Card>
                <Card><CardContent className="p-4 text-center">
                  <p className="text-xs text-muted uppercase">Overall Margin</p>
                  <p className={cn('text-xl font-semibold mt-1 tabular-nums', jobCostingData.overallMargin >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                    {jobCostingData.overallMargin.toFixed(1)}%
                  </p>
                </CardContent></Card>
              </div>

              {/* Per-Job Table */}
              <Card>
                <CardHeader>
                  <CardTitle className="text-base">Job-Level Profitability</CardTitle>
                </CardHeader>
                <CardContent className="p-0">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-default">
                        <th className="text-left px-3 py-2 text-muted font-medium">{t('common.job')}</th>
                        <th className="text-right px-3 py-2 text-muted font-medium">Revenue</th>
                        <th className="text-right px-3 py-2 text-muted font-medium">Costs</th>
                        <th className="text-right px-3 py-2 text-muted font-medium">Profit</th>
                        <th className="text-right px-3 py-2 text-muted font-medium">Margin</th>
                      </tr>
                    </thead>
                    <tbody>
                      {jobCostingData.jobs.length === 0 ? (
                        <tr>
                          <td colSpan={5} className="px-3 py-8 text-center text-muted">
                            <Briefcase size={32} className="mx-auto mb-2 opacity-50" />
                            <p>No job revenue or costs found for this period</p>
                            <p className="text-xs mt-1">Create invoices and log expenses against jobs to see profitability</p>
                          </td>
                        </tr>
                      ) : (
                        <>
                          {jobCostingData.jobs.map(job => (
                            <tr key={job.jobId} className="border-b border-default last:border-b-0 hover:bg-secondary/50">
                              <td className="px-3 py-2 text-main font-medium">{job.jobName}</td>
                              <td className="px-3 py-2 text-right tabular-nums text-main">{formatCurrency(job.revenue)}</td>
                              <td className="px-3 py-2 text-right tabular-nums text-main">{formatCurrency(job.costs)}</td>
                              <td className={cn('px-3 py-2 text-right tabular-nums font-medium', job.profit >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                                {formatCurrency(job.profit)}
                              </td>
                              <td className="px-3 py-2 text-right">
                                <div className="flex items-center justify-end gap-2">
                                  <div className="w-16 h-1.5 bg-secondary rounded-full overflow-hidden">
                                    <div
                                      className={cn(
                                        'h-full rounded-full transition-all',
                                        job.margin < 0 ? 'bg-red-500' : job.margin < 15 ? 'bg-amber-400' : 'bg-emerald-500'
                                      )}
                                      style={{ width: `${Math.min(Math.max(job.margin, 0), 100)}%` }}
                                    />
                                  </div>
                                  <span className={cn('text-xs tabular-nums w-12 text-right', job.margin < 0 ? 'text-red-500' : 'text-muted')}>
                                    {job.margin.toFixed(1)}%
                                  </span>
                                </div>
                              </td>
                            </tr>
                          ))}
                          <tr className="border-t-2 border-default font-bold">
                            <td className="px-3 py-3 text-main">Totals</td>
                            <td className="px-3 py-3 text-right tabular-nums text-main">{formatCurrency(jobCostingData.totalRevenue)}</td>
                            <td className="px-3 py-3 text-right tabular-nums text-main">{formatCurrency(jobCostingData.totalCosts)}</td>
                            <td className={cn('px-3 py-3 text-right tabular-nums', jobCostingData.totalProfit >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                              {formatCurrency(jobCostingData.totalProfit)}
                            </td>
                            <td className={cn('px-3 py-3 text-right tabular-nums', jobCostingData.overallMargin >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                              {jobCostingData.overallMargin.toFixed(1)}%
                            </td>
                          </tr>
                        </>
                      )}
                    </tbody>
                  </table>
                </CardContent>
              </Card>
            </div>
          )}
        </>
      )}
    </div>
  );
}
