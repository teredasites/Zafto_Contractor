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
  Calendar,
  ChevronDown,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { mockRevenueData, mockJobsByStatus, mockRevenueByCategory } from '@/lib/mock-data';

type ReportType = 'revenue' | 'jobs' | 'team' | 'invoices';
type DateRange = '7d' | '30d' | '90d' | '12m' | 'ytd' | 'custom';

export default function ReportsPage() {
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

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Reports</h1>
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
          <Button variant="secondary">
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
      {activeReport === 'revenue' && <RevenueReport />}
      {activeReport === 'jobs' && <JobsReport />}
      {activeReport === 'team' && <TeamReport />}
      {activeReport === 'invoices' && <InvoicesReport />}
    </div>
  );
}

function RevenueReport() {
  const totals = mockRevenueData.reduce(
    (acc, curr) => ({
      revenue: acc.revenue + curr.revenue,
      expenses: acc.expenses + curr.expenses,
      profit: acc.profit + curr.profit,
    }),
    { revenue: 0, expenses: 0, profit: 0 }
  );

  const avgMonthlyRevenue = totals.revenue / 12;
  const profitMargin = (totals.profit / totals.revenue) * 100;

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
            <p className="text-xs text-emerald-600 mt-2 flex items-center gap-1">
              <TrendingUp size={12} />
              +12.5% vs last period
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted">Total Expenses</p>
                <p className="text-2xl font-semibold text-main">{formatCurrency(totals.expenses)}</p>
              </div>
              <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg">
                <TrendingDown size={20} className="text-red-600" />
              </div>
            </div>
            <p className="text-xs text-red-600 mt-2 flex items-center gap-1">
              <TrendingUp size={12} />
              +8.2% vs last period
            </p>
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
            <p className="text-xs text-emerald-600 mt-2 flex items-center gap-1">
              <TrendingUp size={12} />
              +15.3% vs last period
            </p>
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
              {mockRevenueData.slice(-6).map((month) => (
                <div key={month.date} className="flex items-center gap-4">
                  <span className="text-sm text-muted w-12">{month.date}</span>
                  <div className="flex-1 h-8 bg-secondary rounded-lg overflow-hidden flex">
                    <div
                      className="h-full bg-emerald-500"
                      style={{ width: `${(month.revenue / 35000) * 100}%` }}
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
              {mockRevenueByCategory.map((category) => {
                const total = mockRevenueByCategory.reduce((sum, c) => sum + c.value, 0);
                const percentage = (category.value / total) * 100;
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
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">Revenue</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">Expenses</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">Profit</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">Margin</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {mockRevenueData.map((month) => {
                const margin = (month.profit / month.revenue) * 100;
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

function JobsReport() {
  const totalJobs = mockJobsByStatus.reduce((sum, s) => sum + s.value, 0);

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Total Jobs</p>
            <p className="text-2xl font-semibold text-main">{totalJobs}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Completion Rate</p>
            <p className="text-2xl font-semibold text-emerald-600">86%</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Avg. Job Value</p>
            <p className="text-2xl font-semibold text-main">{formatCurrency(2450)}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Avg. Duration</p>
            <p className="text-2xl font-semibold text-main">4.2 hrs</p>
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
            {mockJobsByStatus.map((status) => (
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
        </CardContent>
      </Card>
    </div>
  );
}

function TeamReport() {
  const teamStats = [
    { name: 'Mike Johnson', role: 'Admin', jobs: 45, revenue: 112500, avgRating: 4.9 },
    { name: 'Carlos Rivera', role: 'Field Tech', jobs: 38, revenue: 89200, avgRating: 4.8 },
    { name: 'James Wilson', role: 'Field Tech', jobs: 32, revenue: 76800, avgRating: 4.7 },
  ];

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Team Performance</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">Team Member</th>
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">Role</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">Jobs</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">Revenue</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">Avg Rating</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {teamStats.map((member) => (
                <tr key={member.name} className="hover:bg-surface-hover">
                  <td className="px-6 py-4 font-medium text-main">{member.name}</td>
                  <td className="px-6 py-4">
                    <Badge variant="default">{member.role}</Badge>
                  </td>
                  <td className="px-6 py-4 text-right text-main">{member.jobs}</td>
                  <td className="px-6 py-4 text-right font-medium text-main">{formatCurrency(member.revenue)}</td>
                  <td className="px-6 py-4 text-right">
                    <span className="text-amber-500">{member.avgRating}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  );
}

function InvoicesReport() {
  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Total Invoiced</p>
            <p className="text-2xl font-semibold text-main">{formatCurrency(285400)}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Total Collected</p>
            <p className="text-2xl font-semibold text-emerald-600">{formatCurrency(268750)}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Outstanding</p>
            <p className="text-2xl font-semibold text-amber-600">{formatCurrency(12450)}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-muted">Overdue</p>
            <p className="text-2xl font-semibold text-red-600">{formatCurrency(4200)}</p>
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
            <div className="flex items-center justify-between p-4 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg">
              <span className="font-medium text-main">Current (0-30 days)</span>
              <span className="font-semibold text-emerald-600">{formatCurrency(8250)}</span>
            </div>
            <div className="flex items-center justify-between p-4 bg-amber-50 dark:bg-amber-900/20 rounded-lg">
              <span className="font-medium text-main">31-60 days</span>
              <span className="font-semibold text-amber-600">{formatCurrency(2850)}</span>
            </div>
            <div className="flex items-center justify-between p-4 bg-orange-50 dark:bg-orange-900/20 rounded-lg">
              <span className="font-medium text-main">61-90 days</span>
              <span className="font-semibold text-orange-600">{formatCurrency(1350)}</span>
            </div>
            <div className="flex items-center justify-between p-4 bg-red-50 dark:bg-red-900/20 rounded-lg">
              <span className="font-medium text-main">90+ days</span>
              <span className="font-semibold text-red-600">{formatCurrency(2850)}</span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
