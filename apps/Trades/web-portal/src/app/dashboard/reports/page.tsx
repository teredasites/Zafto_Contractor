'use client';

import { useState } from 'react';
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
  Loader2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { useReports } from '@/lib/hooks/use-reports';
import type { MonthlyRevenue, StatusCount, RevenueCategory, TeamMemberStat, InvoiceStats, JobStats } from '@/lib/hooks/use-reports';

type ReportType = 'revenue' | 'jobs' | 'team' | 'invoices';
type DateRange = '7d' | '30d' | '90d' | '12m' | 'ytd' | 'custom';

export default function ReportsPage() {
  const { t } = useTranslation();
  const { data, loading, error } = useReports();
  const [activeReport, setActiveReport] = useState<ReportType>('revenue');
  const [dateRange, setDateRange] = useState<DateRange>('30d');

  const reports: { id: ReportType; label: string; icon: React.ReactNode }[] = [
    { id: 'revenue', label: 'Revenue', icon: <DollarSign size={18} /> },
    { id: 'jobs', label: 'Jobs', icon: <Briefcase size={18} /> },
    { id: 'team', label: 'Team Performance', icon: <Users size={18} /> },
    { id: 'invoices', label: 'Invoices', icon: <FileText size={18} /> },
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
        <div className="flex gap-2">{[...Array(4)].map((_, i) => <div key={i} className="skeleton h-9 w-24 rounded-lg" />)}</div>
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
          <p className="text-muted mt-1">Business analytics and insights</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="relative">
            <select
              value={dateRange}
              onChange={(e) => setDateRange(e.target.value as DateRange)}
              className="appearance-none pl-4 pr-10 py-2 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
            >
              {dateRanges.map((range) => (
                <option key={range.value} value={range.value}>
                  {range.label}
                </option>
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
            <Download size={16} />
            Export
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
    </div>
  );
}

function RevenueReport({ data, categories }: { data: MonthlyRevenue[]; categories: RevenueCategory[] }) {
  const { t } = useTranslation();
  const totals = data.reduce(
    (acc, curr) => ({
      revenue: acc.revenue + curr.revenue,
      expenses: acc.expenses + curr.expenses,
      profit: acc.profit + curr.profit,
    }),
    { revenue: 0, expenses: 0, profit: 0 }
  );

  const avgMonthlyRevenue = data.length > 0 ? totals.revenue / data.length : 0;
  const profitMargin = totals.revenue > 0 ? (totals.profit / totals.revenue) * 100 : 0;
  const maxRevenue = Math.max(...data.map((m) => m.revenue), 1);

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted">Total Revenue</p>
                <p className="text-2xl font-semibold text-main">{formatCurrency(totals.revenue)}</p>
              </div>
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <TrendingUp size={20} className="text-emerald-600" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted">Material Costs</p>
                <p className="text-2xl font-semibold text-main">{formatCurrency(totals.expenses)}</p>
              </div>
              <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg">
                <TrendingDown size={20} className="text-red-600" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted">Net Profit</p>
                <p className="text-2xl font-semibold text-main">{formatCurrency(totals.profit)}</p>
              </div>
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <DollarSign size={20} className="text-blue-600" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted">Profit Margin</p>
                <p className="text-2xl font-semibold text-main">{profitMargin.toFixed(1)}%</p>
              </div>
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <BarChart3 size={20} className="text-purple-600" />
              </div>
            </div>
            <p className="text-xs text-muted mt-2">
              Avg monthly: {formatCurrency(avgMonthlyRevenue)}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue by Month */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Revenue by Month</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {data.slice(-6).map((month) => (
                <div key={month.date} className="flex items-center gap-4">
                  <span className="text-sm text-muted w-12">{month.date}</span>
                  <div className="flex-1 h-8 bg-secondary rounded-lg overflow-hidden flex">
                    <div
                      className="h-full bg-emerald-500"
                      style={{ width: `${(month.revenue / maxRevenue) * 100}%` }}
                    />
                  </div>
                  <span className="text-sm font-medium text-main w-24 text-right">
                    {formatCurrency(month.revenue)}
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Revenue by Category */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Revenue by Category</CardTitle>
          </CardHeader>
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
                      <div
                        className="h-full rounded-full"
                        style={{ width: `${percentage}%`, backgroundColor: category.color }}
                      />
                    </div>
                    <p className="text-xs text-muted mt-1">{percentage.toFixed(1)}%</p>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Monthly Breakdown Table */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Monthly Breakdown</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">Month</th>
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
                      <Badge variant={margin >= 60 ? 'success' : margin >= 50 ? 'warning' : 'error'}>
                        {margin.toFixed(1)}%
                      </Badge>
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

function JobsReport({ statusData, stats }: { statusData: StatusCount[]; stats: JobStats }) {
  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Total Jobs</p>
            <p className="text-2xl font-semibold text-main">{stats.total}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Completion Rate</p>
            <p className="text-2xl font-semibold text-emerald-600">{stats.completionRate}%</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Avg. Job Value</p>
            <p className="text-2xl font-semibold text-main">{formatCurrency(stats.avgValue)}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Active Statuses</p>
            <p className="text-2xl font-semibold text-main">{statusData.length}</p>
          </CardContent>
        </Card>
      </div>

      {/* Jobs by Status */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Jobs by Status</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {statusData.map((status) => (
              <div key={status.name} className="p-4 bg-secondary rounded-lg text-center">
                <div
                  className="w-12 h-12 rounded-full mx-auto mb-3 flex items-center justify-center"
                  style={{ backgroundColor: `${status.color}20` }}
                >
                  <Briefcase size={20} style={{ color: status.color }} />
                </div>
                <p className="text-2xl font-semibold text-main">{status.value}</p>
                <p className="text-sm text-muted">{status.name}</p>
              </div>
            ))}
          </div>
          {statusData.length === 0 && (
            <p className="text-center text-muted py-8">No jobs yet</p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function TeamReport({ team }: { team: TeamMemberStat[] }) {
  const { t } = useTranslation();
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Team Performance</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {team.length > 0 ? (
            <table className="w-full">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">Team Member</th>
                  <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('common.role')}</th>
                  <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">Jobs</th>
                  <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.revenue')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {team.map((member) => (
                  <tr key={member.name} className="hover:bg-surface-hover">
                    <td className="px-6 py-4 font-medium text-main">{member.name}</td>
                    <td className="px-6 py-4">
                      <Badge variant="default">{member.role}</Badge>
                    </td>
                    <td className="px-6 py-4 text-right text-main">{member.jobs}</td>
                    <td className="px-6 py-4 text-right font-medium text-main">{formatCurrency(member.revenue)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="p-8 text-center text-muted">No team data available</div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function InvoicesReport({ stats }: { stats: InvoiceStats }) {
  const { t } = useTranslation();
  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Total Invoiced</p>
            <p className="text-2xl font-semibold text-main">{formatCurrency(stats.totalInvoiced)}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Total Collected</p>
            <p className="text-2xl font-semibold text-emerald-600">{formatCurrency(stats.totalCollected)}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Outstanding</p>
            <p className="text-2xl font-semibold text-amber-600">{formatCurrency(stats.outstanding)}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">{t('common.overdue')}</p>
            <p className="text-2xl font-semibold text-red-600">{formatCurrency(stats.overdue)}</p>
          </CardContent>
        </Card>
      </div>

      {/* Aging Report */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Aging Report</CardTitle>
        </CardHeader>
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
