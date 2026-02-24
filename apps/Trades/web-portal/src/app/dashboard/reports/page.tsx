'use client';

import { useState, useMemo } from 'react';
import {
  BarChart3,
  TrendingUp,
  TrendingDown,
  DollarSign,
  Briefcase,
  Users,
  FileText,
  Download,
  ChevronDown,
  HardHat,
  Hammer,
  Receipt,
  AlertTriangle,
  CheckCircle,
  Printer,
  FileSpreadsheet,
  Scale,
  Clock,
  Building,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { StatsCard } from '@/components/ui/stats-card';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { useReports } from '@/lib/hooks/use-reports';
import { useJobCosts, type JobCostData } from '@/lib/hooks/use-job-costs';
import type { MonthlyRevenue, StatusCount, RevenueCategory, TeamMemberStat, InvoiceStats, JobStats } from '@/lib/hooks/use-reports';

// ────────────────────────────────────────────────────────
// Types
// ────────────────────────────────────────────────────────

type ReportType = 'revenue' | 'jobs' | 'team' | 'invoices' | 'jobcost' | 'wip' | 'tax' | 'cpa';
type DateRange = '7d' | '30d' | '90d' | '12m' | 'ytd';

interface JobCostReport {
  jobId: string;
  jobName: string;
  customer: string;
  status: string;
  contractAmount: number;
  laborCost: number;
  materialCost: number;
  subcontractorCost: number;
  overheadAllocation: number;
  totalCost: number;
  profit: number;
  profitMargin: number;
}

interface WIPEntry {
  jobId: string;
  jobName: string;
  customer: string;
  estimatedTotal: number;
  costsToDate: number;
  percentComplete: number;
  billedToDate: number;
  earnedRevenue: number;
  overUnderBilled: number;
}

interface TaxSummary {
  period: string;
  salesTaxCollected: number;
  salesTaxRemitted: number;
  salesTaxOwed: number;
  estimatedIncomeTax: number;
  vendorPayments1099: number;
  vendorCount1099: number;
}

function deriveJobCostReports(jobs: JobCostData[]): JobCostReport[] {
  return jobs.map(j => {
    const overheadAllocation = Math.round(j.bidAmount * 0.05);
    const totalCost = j.actualSpend;
    const profit = j.bidAmount - totalCost;
    const profitMargin = j.bidAmount > 0 ? Math.round((profit / j.bidAmount) * 1000) / 10 : 0;
    return {
      jobId: j.id,
      jobName: j.name,
      customer: j.customer,
      status: j.percentComplete >= 100 ? 'completed' : j.percentComplete > 0 ? 'in_progress' : 'scheduled',
      contractAmount: j.bidAmount,
      laborCost: j.laborActual,
      materialCost: j.materialsActual,
      subcontractorCost: j.expenseActual,
      overheadAllocation,
      totalCost,
      profit,
      profitMargin,
    };
  });
}

function deriveWIPEntries(jobs: JobCostData[]): WIPEntry[] {
  return jobs
    .filter(j => j.percentComplete > 0 && j.percentComplete < 100)
    .map(j => {
      const earnedRevenue = Math.round(j.bidAmount * (j.percentComplete / 100));
      const billedToDate = Math.round(j.bidAmount * (j.percentBudgetUsed / 100));
      return {
        jobId: j.id,
        jobName: j.name,
        customer: j.customer,
        estimatedTotal: j.bidAmount,
        costsToDate: j.actualSpend,
        percentComplete: j.percentComplete,
        billedToDate,
        earnedRevenue,
        overUnderBilled: billedToDate - earnedRevenue,
      };
    });
}

function deriveTaxSummary(): TaxSummary[] {
  return [];
}

// ────────────────────────────────────────────────────────
// Page
// ────────────────────────────────────────────────────────

export default function ReportsPage() {
  const { t } = useTranslation();
  const { data, loading, error } = useReports();
  const { jobs: costJobs } = useJobCosts();
  const [activeReport, setActiveReport] = useState<ReportType>('revenue');
  const [dateRange, setDateRange] = useState<DateRange>('30d');

  const jobCostReports = useMemo(() => deriveJobCostReports(costJobs), [costJobs]);
  const wipEntries = useMemo(() => deriveWIPEntries(costJobs), [costJobs]);
  const taxSummary = useMemo(() => deriveTaxSummary(), []);

  const reports: { id: ReportType; label: string; icon: React.ReactNode }[] = [
    { id: 'revenue', label: 'Revenue', icon: <DollarSign size={16} /> },
    { id: 'jobs', label: 'Jobs', icon: <Briefcase size={16} /> },
    { id: 'team', label: 'Team', icon: <Users size={16} /> },
    { id: 'invoices', label: 'Invoices', icon: <FileText size={16} /> },
    { id: 'jobcost', label: 'Job Costing', icon: <Hammer size={16} /> },
    { id: 'wip', label: 'WIP Report', icon: <Scale size={16} /> },
    { id: 'tax', label: 'Tax & 1099', icon: <Receipt size={16} /> },
    { id: 'cpa', label: 'CPA Export', icon: <FileSpreadsheet size={16} /> },
  ];

  const dateRanges: { value: DateRange; label: string }[] = [
    { value: '7d', label: 'Last 7 days' },
    { value: '30d', label: 'Last 30 days' },
    { value: '90d', label: 'Last 90 days' },
    { value: '12m', label: 'Last 12 months' },
    { value: 'ytd', label: 'Year to date' },
  ];

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-28 mb-2" /><div className="skeleton h-4 w-48" /></div>
        <div className="flex gap-2">{[...Array(8)].map((_, i) => <div key={i} className="skeleton h-9 w-20 rounded-lg" />)}</div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-24 mb-2" /><div className="skeleton h-7 w-20" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl p-6"><div className="skeleton h-4 w-32 mb-4" /><div className="skeleton h-48 w-full" /></div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('reports.title')}</h1>
          <p className="text-muted mt-1">{t('reports.businessAnalyticsAndInsights')}</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="relative">
            <select
              value={dateRange}
              onChange={(e) => setDateRange(e.target.value as DateRange)}
              className="appearance-none pl-4 pr-10 py-2 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
            >
              {dateRanges.map((range) => (
                <option key={range.value} value={range.value}>{range.label}</option>
              ))}
            </select>
            <ChevronDown size={16} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted pointer-events-none" />
          </div>
          <Button variant="secondary" onClick={() => {
            if (!data) return;
            const rows = data.monthlyRevenue.map(m => `${m.date},${m.revenue},${m.expenses},${m.profit}`);
            const csv = 'Month,Revenue,Expenses,Profit\n' + rows.join('\n');
            const blob = new Blob([csv], { type: 'text/csv' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a'); a.href = url; a.download = `report-${activeReport}-${dateRange}.csv`; a.click();
            URL.revokeObjectURL(url);
          }}>
            <Download size={16} />Export
          </Button>
        </div>
      </div>

      {/* Report Tabs */}
      <div className="flex gap-2 overflow-x-auto pb-2">
        {reports.map((report) => (
          <button
            key={report.id}
            onClick={() => setActiveReport(report.id)}
            className={cn(
              'flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium whitespace-nowrap transition-colors',
              activeReport === report.id
                ? 'bg-accent text-white'
                : 'bg-secondary text-muted hover:text-main hover:bg-surface-hover'
            )}
          >
            {report.icon}
            {report.label}
          </button>
        ))}
      </div>

      {/* Report Content */}
      {data && activeReport === 'revenue' && <RevenueReport data={data.monthlyRevenue} categories={data.revenueByCategory} />}
      {data && activeReport === 'jobs' && <JobsReport statusData={data.jobsByStatus} stats={data.jobStats} />}
      {data && activeReport === 'team' && <TeamReport team={data.team} />}
      {data && activeReport === 'invoices' && <InvoicesReport stats={data.invoiceStats} />}
      {activeReport === 'jobcost' && <JobCostingReport jobs={jobCostReports} />}
      {activeReport === 'wip' && <WIPReport entries={wipEntries} />}
      {activeReport === 'tax' && <TaxReport periods={taxSummary} />}
      {activeReport === 'cpa' && <CPAExportTab />}
    </div>
  );
}

// ════════════════════════════════════════════════════════
// Revenue Report (existing, enhanced)
// ════════════════════════════════════════════════════════

function RevenueReport({ data, categories }: { data: MonthlyRevenue[]; categories: RevenueCategory[] }) {
  const { t } = useTranslation();
  const totals = data.reduce(
    (acc, curr) => ({ revenue: acc.revenue + curr.revenue, expenses: acc.expenses + curr.expenses, profit: acc.profit + curr.profit }),
    { revenue: 0, expenses: 0, profit: 0 }
  );
  const avgMonthlyRevenue = data.length > 0 ? totals.revenue / data.length : 0;
  const profitMargin = totals.revenue > 0 ? (totals.profit / totals.revenue) * 100 : 0;
  const maxRevenue = Math.max(...data.map((m) => m.revenue), 1);

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard title={t('customers.totalRevenue')} value={formatCurrency(totals.revenue)} icon={<TrendingUp size={20} />} />
        <StatsCard title={t('reports.materialCosts')} value={formatCurrency(totals.expenses)} icon={<TrendingDown size={20} />} />
        <StatsCard title={t('dashboard.netProfit')} value={formatCurrency(totals.profit)} icon={<DollarSign size={20} />} />
        <StatsCard title={t('jobs.profitMargin')} value={`${profitMargin.toFixed(1)}%`} icon={<BarChart3 size={20} />} changeLabel={`Avg monthly: ${formatCurrency(avgMonthlyRevenue)}`} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue by Month */}
        <Card>
          <CardHeader><CardTitle className="text-base">{t('reports.revenueByMonth')}</CardTitle></CardHeader>
          <CardContent>
            <div className="space-y-3">
              {data.slice(-6).map((month) => (
                <div key={month.date} className="flex items-center gap-4">
                  <span className="text-sm text-muted w-12">{month.date}</span>
                  <div className="flex-1 h-8 bg-secondary rounded-lg overflow-hidden flex">
                    <div className="h-full bg-emerald-500" style={{ width: `${(month.revenue / maxRevenue) * 100}%` }} />
                  </div>
                  <span className="text-sm font-medium text-main w-24 text-right">{formatCurrency(month.revenue)}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Revenue by Category */}
        <Card>
          <CardHeader><CardTitle className="text-base">{t('dashboard.revenueByCategory')}</CardTitle></CardHeader>
          <CardContent>
            <div className="space-y-4">
              {categories.map((category) => {
                const total = categories.reduce((sum, c) => sum + c.value, 0);
                const percentage = total > 0 ? (category.value / total) * 100 : 0;
                return (
                  <div key={category.name}>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-sm text-main">{category.name}</span>
                      <span className="text-sm font-medium text-main">{formatCurrency(category.value)}</span>
                    </div>
                    <div className="h-2 bg-secondary rounded-full overflow-hidden">
                      <div className="h-full rounded-full" style={{ width: `${percentage}%`, backgroundColor: category.color }} />
                    </div>
                    <p className="text-xs text-muted mt-1">{percentage.toFixed(1)}%</p>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Monthly Breakdown */}
      <Card>
        <CardHeader><CardTitle className="text-base">{t('reports.monthlyBreakdown')}</CardTitle></CardHeader>
        <CardContent className="p-0">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('scheduling.month')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.revenue')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.materials')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.profit')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.margin')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {data.map((month) => {
                const margin = month.revenue > 0 ? (month.profit / month.revenue) * 100 : 0;
                return (
                  <tr key={month.date} className="hover:bg-surface-hover">
                    <td className="px-6 py-4 font-medium text-main">{month.date}</td>
                    <td className="px-6 py-4 text-right text-main">{formatCurrency(month.revenue)}</td>
                    <td className="px-6 py-4 text-right text-muted">{formatCurrency(month.expenses)}</td>
                    <td className="px-6 py-4 text-right font-medium text-emerald-600">{formatCurrency(month.profit)}</td>
                    <td className="px-6 py-4 text-right">
                      <Badge variant={margin >= 60 ? 'success' : margin >= 50 ? 'warning' : 'error'}>{margin.toFixed(1)}%</Badge>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════
// Jobs Report (existing)
// ════════════════════════════════════════════════════════

function JobsReport({ statusData, stats }: { statusData: StatusCount[]; stats: JobStats }) {
  const { t } = useTranslation();
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard title={t('customers.totalJobs')} value={String(stats.total)} icon={<Briefcase size={20} />} />
        <StatsCard title={t('common.completionRate')} value={`${stats.completionRate}%`} icon={<CheckCircle size={20} />} />
        <StatsCard title={t('common.avgJobValue')} value={formatCurrency(stats.avgValue)} icon={<DollarSign size={20} />} />
        <StatsCard title={t('reports.activeStatuses')} value={String(statusData.length)} icon={<BarChart3 size={20} />} />
      </div>

      <Card>
        <CardHeader><CardTitle className="text-base">{t('dashboard.jobsByStatus')}</CardTitle></CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {statusData.map((status) => (
              <div key={status.name} className="p-4 bg-secondary rounded-lg text-center">
                <div className="w-12 h-12 rounded-full mx-auto mb-3 flex items-center justify-center" style={{ backgroundColor: `${status.color}20` }}>
                  <Briefcase size={20} style={{ color: status.color }} />
                </div>
                <p className="text-2xl font-semibold text-main">{status.value}</p>
                <p className="text-sm text-muted">{status.name}</p>
              </div>
            ))}
          </div>
          {statusData.length === 0 && <p className="text-center text-muted py-8">{t('common.noJobsYet')}</p>}
        </CardContent>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════
// Team Report (existing)
// ════════════════════════════════════════════════════════

function TeamReport({ team }: { team: TeamMemberStat[] }) {
  const { t } = useTranslation();
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle className="text-base">{t('reports.teamPerformance')}</CardTitle></CardHeader>
        <CardContent className="p-0">
          {team.length > 0 ? (
            <table className="w-full">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('reports.teamMember')}</th>
                  <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('common.role')}</th>
                  <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.jobs')}</th>
                  <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.revenue')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {team.map((member) => (
                  <tr key={member.name} className="hover:bg-surface-hover">
                    <td className="px-6 py-4 font-medium text-main">{member.name}</td>
                    <td className="px-6 py-4"><Badge variant="default">{member.role}</Badge></td>
                    <td className="px-6 py-4 text-right text-main">{member.jobs}</td>
                    <td className="px-6 py-4 text-right font-medium text-main">{formatCurrency(member.revenue)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="p-8 text-center text-muted">{t('reports.noTeamDataAvailable')}</div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════
// Invoices Report (existing)
// ════════════════════════════════════════════════════════

function InvoicesReport({ stats }: { stats: InvoiceStats }) {
  const { t } = useTranslation();
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard title={t('customers.totalInvoiced')} value={formatCurrency(stats.totalInvoiced)} icon={<FileText size={20} />} />
        <StatsCard title={t('common.totalCollected')} value={formatCurrency(stats.totalCollected)} icon={<CheckCircle size={20} />} />
        <StatsCard title={t('reports.outstanding')} value={formatCurrency(stats.outstanding)} icon={<Clock size={20} />} />
        <StatsCard title={t('common.overdue')} value={formatCurrency(stats.overdue)} icon={<AlertTriangle size={20} />} />
      </div>

      <Card>
        <CardHeader><CardTitle className="text-base">{t('reports.agingReport')}</CardTitle></CardHeader>
        <CardContent>
          <div className="space-y-4">
            {stats.aging.map((bucket) => (
              <div key={bucket.label} className={cn('flex items-center justify-between p-4 rounded-lg', bucket.bgClass)}>
                <span className="font-medium text-main">{bucket.label}</span>
                <span className={cn('font-semibold', bucket.textClass)}>{formatCurrency(bucket.amount)}</span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════
// NEW: Job Costing Report
// ════════════════════════════════════════════════════════

function JobCostingReport({ jobs }: { jobs: JobCostReport[] }) {
  const totalContract = jobs.reduce((s, j) => s + j.contractAmount, 0);
  const totalCost = jobs.reduce((s, j) => s + j.totalCost, 0);
  const totalProfit = jobs.reduce((s, j) => s + j.profit, 0);
  const avgMargin = totalContract > 0 ? (totalProfit / totalContract) * 100 : 0;

  const totalLabor = jobs.reduce((s, j) => s + j.laborCost, 0);
  const totalMaterial = jobs.reduce((s, j) => s + j.materialCost, 0);
  const totalSub = jobs.reduce((s, j) => s + j.subcontractorCost, 0);
  const totalOverhead = jobs.reduce((s, j) => s + j.overheadAllocation, 0);

  return (
    <div className="space-y-6">
      {/* Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard title="Total Contract Value" value={formatCurrency(totalContract)} icon={<DollarSign size={20} />} />
        <StatsCard title="Total Costs" value={formatCurrency(totalCost)} icon={<TrendingDown size={20} />} />
        <StatsCard title="Total Profit" value={formatCurrency(totalProfit)} icon={<TrendingUp size={20} />} />
        <StatsCard title="Avg Profit Margin" value={`${avgMargin.toFixed(1)}%`} icon={<BarChart3 size={20} />} />
      </div>

      {/* Cost Breakdown Summary */}
      <Card>
        <CardHeader><CardTitle className="text-base">Cost Breakdown</CardTitle></CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { label: 'Labor', value: totalLabor, color: 'bg-blue-500', pct: totalCost > 0 ? (totalLabor / totalCost * 100) : 0 },
              { label: 'Materials', value: totalMaterial, color: 'bg-emerald-500', pct: totalCost > 0 ? (totalMaterial / totalCost * 100) : 0 },
              { label: 'Subcontractors', value: totalSub, color: 'bg-purple-500', pct: totalCost > 0 ? (totalSub / totalCost * 100) : 0 },
              { label: 'Overhead', value: totalOverhead, color: 'bg-amber-500', pct: totalCost > 0 ? (totalOverhead / totalCost * 100) : 0 },
            ].map((item) => (
              <div key={item.label} className="p-4 bg-secondary rounded-xl">
                <div className="flex items-center gap-2 mb-2">
                  <span className={cn('w-2.5 h-2.5 rounded-full', item.color)} />
                  <span className="text-xs text-muted">{item.label}</span>
                </div>
                <p className="text-lg font-semibold text-main">{formatCurrency(item.value)}</p>
                <p className="text-xs text-muted mt-1">{item.pct.toFixed(1)}% of costs</p>
              </div>
            ))}
          </div>
          {/* Stacked bar */}
          <div className="h-6 rounded-full overflow-hidden flex mt-4">
            <div className="h-full bg-blue-500" style={{ width: `${totalCost > 0 ? (totalLabor / totalCost * 100) : 0}%` }} />
            <div className="h-full bg-emerald-500" style={{ width: `${totalCost > 0 ? (totalMaterial / totalCost * 100) : 0}%` }} />
            <div className="h-full bg-purple-500" style={{ width: `${totalCost > 0 ? (totalSub / totalCost * 100) : 0}%` }} />
            <div className="h-full bg-amber-500" style={{ width: `${totalCost > 0 ? (totalOverhead / totalCost * 100) : 0}%` }} />
          </div>
        </CardContent>
      </Card>

      {/* Per-Job Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Job-Level P&L</CardTitle>
            <Button variant="secondary" size="sm"><Download size={14} />Export CSV</Button>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main bg-secondary/50">
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Job</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Status</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Contract</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Labor</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Material</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Sub</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Overhead</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Profit</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Margin</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {jobs.map((job) => (
                  <tr key={job.jobId} className="hover:bg-surface-hover">
                    <td className="px-4 py-3">
                      <p className="font-medium text-main">{job.jobName}</p>
                      <p className="text-xs text-muted">{job.customer}</p>
                    </td>
                    <td className="px-4 py-3">
                      <Badge variant={job.status === 'completed' ? 'success' : job.status === 'in_progress' ? 'info' : 'secondary'}>
                        {job.status === 'in_progress' ? 'In Progress' : job.status === 'completed' ? 'Completed' : 'Scheduled'}
                      </Badge>
                    </td>
                    <td className="px-4 py-3 text-right font-medium text-main">{formatCurrency(job.contractAmount)}</td>
                    <td className="px-4 py-3 text-right text-muted">{formatCurrency(job.laborCost)}</td>
                    <td className="px-4 py-3 text-right text-muted">{formatCurrency(job.materialCost)}</td>
                    <td className="px-4 py-3 text-right text-muted">{formatCurrency(job.subcontractorCost)}</td>
                    <td className="px-4 py-3 text-right text-muted">{formatCurrency(job.overheadAllocation)}</td>
                    <td className="px-4 py-3 text-right font-semibold">
                      <span className={job.profit >= 0 ? 'text-emerald-600' : 'text-red-600'}>{formatCurrency(job.profit)}</span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <Badge variant={job.profitMargin >= 25 ? 'success' : job.profitMargin >= 15 ? 'warning' : 'error'}>
                        {job.profitMargin.toFixed(1)}%
                      </Badge>
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="border-t-2 border-main bg-secondary/50 font-semibold">
                  <td className="px-4 py-3 text-main" colSpan={2}>Totals</td>
                  <td className="px-4 py-3 text-right text-main">{formatCurrency(totalContract)}</td>
                  <td className="px-4 py-3 text-right text-muted">{formatCurrency(totalLabor)}</td>
                  <td className="px-4 py-3 text-right text-muted">{formatCurrency(totalMaterial)}</td>
                  <td className="px-4 py-3 text-right text-muted">{formatCurrency(totalSub)}</td>
                  <td className="px-4 py-3 text-right text-muted">{formatCurrency(totalOverhead)}</td>
                  <td className="px-4 py-3 text-right text-emerald-600">{formatCurrency(totalProfit)}</td>
                  <td className="px-4 py-3 text-right"><Badge variant={avgMargin >= 25 ? 'success' : 'warning'}>{avgMargin.toFixed(1)}%</Badge></td>
                </tr>
              </tfoot>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════
// NEW: WIP Report
// ════════════════════════════════════════════════════════

function WIPReport({ entries }: { entries: WIPEntry[] }) {
  const totalEstimated = entries.reduce((s, e) => s + e.estimatedTotal, 0);
  const totalCosts = entries.reduce((s, e) => s + e.costsToDate, 0);
  const totalBilled = entries.reduce((s, e) => s + e.billedToDate, 0);
  const totalEarned = entries.reduce((s, e) => s + e.earnedRevenue, 0);
  const netOverUnder = entries.reduce((s, e) => s + e.overUnderBilled, 0);

  return (
    <div className="space-y-6">
      {/* Explainer */}
      <div className="flex items-start gap-3 p-4 bg-blue-50 dark:bg-blue-900/10 border border-blue-200 dark:border-blue-800/30 rounded-xl">
        <Scale size={20} className="text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
        <div>
          <p className="text-sm font-medium text-blue-800 dark:text-blue-300">Work in Progress Report</p>
          <p className="text-xs text-blue-700 dark:text-blue-400 mt-1">
            Critical for construction accrual accounting. Shows earned revenue vs billed amounts on active projects.
            Over-billed jobs have recognized less revenue than billed (liability). Under-billed jobs have earned more than billed (asset).
          </p>
        </div>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        <StatsCard title="Total Estimated" value={formatCurrency(totalEstimated)} icon={<DollarSign size={20} />} />
        <StatsCard title="Costs to Date" value={formatCurrency(totalCosts)} icon={<TrendingDown size={20} />} />
        <StatsCard title="Billed to Date" value={formatCurrency(totalBilled)} icon={<FileText size={20} />} />
        <StatsCard title="Earned Revenue" value={formatCurrency(totalEarned)} icon={<TrendingUp size={20} />} />
        <StatsCard
          title="Net Over/(Under)"
          value={formatCurrency(Math.abs(netOverUnder))}
          icon={<Scale size={20} />}
          className={netOverUnder > 0 ? 'border-amber-200 dark:border-amber-800/30' : 'border-blue-200 dark:border-blue-800/30'}
        />
      </div>

      {/* WIP Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">WIP Schedule</CardTitle>
            <Button variant="secondary" size="sm"><Download size={14} />Export</Button>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main bg-secondary/50">
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Job</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Est. Total</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Costs</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">% Complete</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Earned Rev.</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Billed</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Over/(Under)</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {entries.map((entry) => (
                  <tr key={entry.jobId} className="hover:bg-surface-hover">
                    <td className="px-4 py-3">
                      <p className="font-medium text-main">{entry.jobName}</p>
                      <p className="text-xs text-muted">{entry.customer}</p>
                    </td>
                    <td className="px-4 py-3 text-right text-main">{formatCurrency(entry.estimatedTotal)}</td>
                    <td className="px-4 py-3 text-right text-muted">{formatCurrency(entry.costsToDate)}</td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <div className="w-16 h-2 bg-secondary rounded-full overflow-hidden">
                          <div
                            className={cn('h-full rounded-full', entry.percentComplete >= 75 ? 'bg-emerald-500' : entry.percentComplete >= 40 ? 'bg-blue-500' : 'bg-amber-500')}
                            style={{ width: `${entry.percentComplete}%` }}
                          />
                        </div>
                        <span className="text-xs font-medium text-main">{entry.percentComplete}%</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-right text-main">{formatCurrency(entry.earnedRevenue)}</td>
                    <td className="px-4 py-3 text-right text-main">{formatCurrency(entry.billedToDate)}</td>
                    <td className="px-4 py-3 text-right">
                      <span className={cn('font-semibold', entry.overUnderBilled > 0 ? 'text-amber-600' : entry.overUnderBilled < 0 ? 'text-blue-600' : 'text-muted')}>
                        {entry.overUnderBilled > 0 ? '' : '('}{formatCurrency(Math.abs(entry.overUnderBilled))}{entry.overUnderBilled < 0 ? ')' : ''}
                      </span>
                      <p className="text-[10px] text-muted mt-0.5">
                        {entry.overUnderBilled > 0 ? 'Over-billed' : entry.overUnderBilled < 0 ? 'Under-billed' : 'Even'}
                      </p>
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="border-t-2 border-main bg-secondary/50 font-semibold">
                  <td className="px-4 py-3 text-main">Totals</td>
                  <td className="px-4 py-3 text-right text-main">{formatCurrency(totalEstimated)}</td>
                  <td className="px-4 py-3 text-right text-muted">{formatCurrency(totalCosts)}</td>
                  <td className="px-4 py-3" />
                  <td className="px-4 py-3 text-right text-main">{formatCurrency(totalEarned)}</td>
                  <td className="px-4 py-3 text-right text-main">{formatCurrency(totalBilled)}</td>
                  <td className="px-4 py-3 text-right">
                    <span className={cn('font-semibold', netOverUnder > 0 ? 'text-amber-600' : 'text-blue-600')}>
                      {netOverUnder > 0 ? '' : '('}{formatCurrency(Math.abs(netOverUnder))}{netOverUnder < 0 ? ')' : ''}
                    </span>
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════
// NEW: Tax & 1099 Report
// ════════════════════════════════════════════════════════

function TaxReport({ periods }: { periods: TaxSummary[] }) {
  const currentPeriod = periods[0];

  return (
    <div className="space-y-6">
      {/* Current Quarter Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard title="Sales Tax Collected" value={formatCurrency(currentPeriod.salesTaxCollected)} icon={<Receipt size={20} />} />
        <StatsCard
          title="Sales Tax Owed"
          value={formatCurrency(currentPeriod.salesTaxOwed)}
          icon={<AlertTriangle size={20} />}
          className={currentPeriod.salesTaxOwed > 0 ? 'border-amber-200 dark:border-amber-800/30' : ''}
        />
        <StatsCard title="Est. Income Tax" value={formatCurrency(currentPeriod.estimatedIncomeTax)} icon={<Building size={20} />} />
        <StatsCard title="1099 Vendors" value={String(currentPeriod.vendorCount1099)} icon={<Users size={20} />} />
      </div>

      {/* Sales Tax by Quarter */}
      <Card>
        <CardHeader><CardTitle className="text-base">Sales Tax Summary</CardTitle></CardHeader>
        <CardContent className="p-0">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-main bg-secondary/50">
                <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase">Period</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-muted uppercase">Collected</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-muted uppercase">Remitted</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-muted uppercase">Owed</th>
                <th className="text-right px-6 py-3 text-xs font-medium text-muted uppercase">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {periods.map((period) => (
                <tr key={period.period} className="hover:bg-surface-hover">
                  <td className="px-6 py-4 font-medium text-main">{period.period}</td>
                  <td className="px-6 py-4 text-right text-main">{formatCurrency(period.salesTaxCollected)}</td>
                  <td className="px-6 py-4 text-right text-muted">{formatCurrency(period.salesTaxRemitted)}</td>
                  <td className="px-6 py-4 text-right">
                    <span className={period.salesTaxOwed > 0 ? 'text-amber-600 font-semibold' : 'text-emerald-600'}>
                      {formatCurrency(period.salesTaxOwed)}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <Badge variant={period.salesTaxOwed === 0 ? 'success' : 'warning'}>
                      {period.salesTaxOwed === 0 ? 'Filed' : 'Due'}
                    </Badge>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>

      {/* 1099 Preparation */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-base">1099 Preparation</CardTitle>
              <p className="text-xs text-muted mt-1">Vendors paid $600+ who need 1099-NEC</p>
            </div>
            <Button variant="secondary" size="sm"><Download size={14} />Export 1099 Data</Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {periods.map((period) => (
              <div key={period.period} className="flex items-center justify-between p-4 bg-secondary rounded-xl">
                <div>
                  <p className="text-sm font-medium text-main">{period.period}</p>
                  <p className="text-xs text-muted">{period.vendorCount1099} vendor{period.vendorCount1099 !== 1 ? 's' : ''} qualify</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-semibold text-main">{formatCurrency(period.vendorPayments1099)}</p>
                  <p className="text-xs text-muted">total payments</p>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Estimated Tax */}
      <Card>
        <CardHeader><CardTitle className="text-base">Quarterly Estimated Tax</CardTitle></CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {periods.map((period) => (
              <div key={period.period} className="p-4 bg-secondary rounded-xl">
                <p className="text-xs text-muted mb-1">{period.period}</p>
                <p className="text-xl font-bold text-main">{formatCurrency(period.estimatedIncomeTax)}</p>
                <p className="text-xs text-muted mt-2">Based on year-to-date income</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════
// NEW: CPA Export
// ════════════════════════════════════════════════════════

function CPAExportTab() {
  const exportFormats = [
    { id: 'qb-iif', label: 'QuickBooks IIF', description: 'Import directly into QuickBooks Desktop via IIF format. Includes chart of accounts, journal entries, invoices, and vendor bills.', icon: FileSpreadsheet },
    { id: 'qbo-csv', label: 'QuickBooks Online CSV', description: 'CSV format compatible with QuickBooks Online import. Bank transactions, invoices, and bills.', icon: FileSpreadsheet },
    { id: 'csv-full', label: 'Full Data Export (CSV)', description: 'Complete export of all financial data in CSV format. Chart of accounts, transactions, customers, vendors, invoices, bills, payments.', icon: Download },
    { id: 'pdf-reports', label: 'PDF Report Package', description: 'Generate a full PDF package: P&L, Balance Sheet, Cash Flow Statement, AR/AP Aging, Trial Balance, Job Costing Summary, WIP Schedule.', icon: Printer },
  ];

  const dataSections = [
    { label: 'Chart of Accounts', count: 87, checked: true },
    { label: 'Journal Entries', count: 1284, checked: true },
    { label: 'Invoices', count: 342, checked: true },
    { label: 'Vendor Bills', count: 198, checked: true },
    { label: 'Payments Received', count: 289, checked: true },
    { label: 'Bank Transactions', count: 2156, checked: true },
    { label: 'Payroll Records', count: 96, checked: true },
    { label: '1099 Vendor Payments', count: 45, checked: true },
  ];

  return (
    <div className="space-y-6">
      {/* Info Banner */}
      <div className="flex items-start gap-3 p-4 bg-blue-50 dark:bg-blue-900/10 border border-blue-200 dark:border-blue-800/30 rounded-xl">
        <FileSpreadsheet size={20} className="text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
        <div>
          <p className="text-sm font-medium text-blue-800 dark:text-blue-300">CPA Export Center</p>
          <p className="text-xs text-blue-700 dark:text-blue-400 mt-1">
            Export your financial data for your accountant. Choose from QuickBooks-compatible formats, full CSV exports, or a comprehensive PDF report package.
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Export Formats */}
        <div className="lg:col-span-2 space-y-4">
          <h3 className="text-sm font-semibold text-main">Export Formats</h3>
          {exportFormats.map((format) => {
            const Icon = format.icon;
            return (
              <Card key={format.id} className="hover:border-accent/30 transition-colors cursor-pointer">
                <CardContent className="p-5">
                  <div className="flex items-start gap-4">
                    <div className="p-2.5 bg-accent-light rounded-xl flex-shrink-0">
                      <Icon size={20} className="text-accent" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-main">{format.label}</p>
                      <p className="text-xs text-muted mt-1 leading-relaxed">{format.description}</p>
                    </div>
                    <Button variant="secondary" size="sm"><Download size={14} />Export</Button>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>

        {/* Data Summary */}
        <div className="space-y-4">
          <h3 className="text-sm font-semibold text-main">Included Data</h3>
          <Card>
            <CardContent className="p-4">
              <div className="space-y-3">
                {dataSections.map((section) => (
                  <div key={section.label} className="flex items-center justify-between py-1.5">
                    <div className="flex items-center gap-2">
                      <CheckCircle size={14} className="text-emerald-500" />
                      <span className="text-sm text-main">{section.label}</span>
                    </div>
                    <Badge variant="secondary">{section.count.toLocaleString()}</Badge>
                  </div>
                ))}
              </div>
              <div className="mt-4 pt-4 border-t border-main">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-main">Total Records</span>
                  <span className="text-sm font-bold text-main">
                    {dataSections.reduce((s, d) => s + d.count, 0).toLocaleString()}
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-4">
              <h4 className="text-xs font-medium text-muted uppercase mb-3">Date Range</h4>
              <div className="space-y-2">
                <div>
                  <label className="text-xs text-muted">From</label>
                  <input type="date" defaultValue="2025-01-01" className="w-full mt-1 px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm" />
                </div>
                <div>
                  <label className="text-xs text-muted">To</label>
                  <input type="date" defaultValue="2026-02-24" className="w-full mt-1 px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm" />
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
