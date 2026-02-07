'use client';

import { useRouter } from 'next/navigation';
import {
  FileText,
  Briefcase,
  Receipt,
  Users,
  TrendingUp,
  TrendingDown,
  Clock,
  AlertCircle,
  Calendar,
  ArrowRight,
  DollarSign,
  CheckCircle2,
  Send,
  Eye,
  MapPin,
  Phone,
  Plus,
  Radio,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatsCard } from '@/components/ui/stats-card';
import { StatusBadge } from '@/components/ui/badge';
import { Avatar, AvatarGroup } from '@/components/ui/avatar';
import { SimpleAreaChart, DonutChart, DonutLegend, SimpleBarChart } from '@/components/ui/charts';
import { Button } from '@/components/ui/button';
import { CommandPalette } from '@/components/command-palette';
import { TeamMapWidget } from '@/components/ui/team-map';
import { ClockStatusWidget } from '@/components/time-clock/clock-status-widget';
import { usePermissions, ProModeGate } from '@/components/permission-gate';
import { getSupabase } from '@/lib/supabase';
import { formatCurrency, formatRelativeTime, formatDate, formatTime, cn } from '@/lib/utils';
import { useStats, useActivity } from '@/lib/hooks/use-stats';
import { useJobs, useSchedule, useTeam } from '@/lib/hooks/use-jobs';
import { useInvoices } from '@/lib/hooks/use-invoices';
import { useBids } from '@/lib/hooks/use-bids';
import { useReports } from '@/lib/hooks/use-reports';

export default function DashboardPage() {
  const router = useRouter();
  const { isProMode, companyId, loading: permLoading } = usePermissions();

  const { stats, loading: statsLoading } = useStats();
  const { jobs } = useJobs();
  const { invoices } = useInvoices();
  const { bids } = useBids();
  const { schedule } = useSchedule();
  const { team } = useTeam();
  const { activity } = useActivity();
  const { data: reportData } = useReports();

  const revenueData = reportData?.monthlyRevenue || [];
  const jobsByStatusData = reportData?.jobsByStatus || [];
  const revenueByCategoryData = reportData?.revenueByCategory || [];

  const handleToggleProMode = async () => {
    if (!companyId) return;
    const newMode = isProMode ? 'simple' : 'pro';
    try {
      const supabase = getSupabase();
      await supabase.from('companies').update({ ui_mode: newMode }).eq('id', companyId);
    } catch (e) {
      console.error('Failed to toggle mode:', e);
    }
  };

  const todayJobs = schedule.filter((s) => {
    const today = new Date();
    const itemDate = new Date(s.start);
    return itemDate.toDateString() === today.toDateString();
  });

  const upcomingJobs = jobs.filter(
    (j) => j.status === 'scheduled' || j.status === 'in_progress'
  ).slice(0, 5);

  const overdueInvoices = invoices.filter((i) => i.status === 'overdue');
  const recentActivity = activity.slice(0, 6);

  // Chart data
  const revenueChartData = revenueData.map((d) => ({
    date: d.date,
    value: d.revenue,
  }));

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Command Palette */}
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Dashboard</h1>
          <p className="text-[13px] text-muted mt-1">
            Welcome back. Here's what's happening today.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="secondary" onClick={() => router.push('/dashboard/calendar')}>
            <Calendar size={16} />
            View Calendar
          </Button>
          <Button onClick={() => router.push('/dashboard/bids/new')}>
            <Plus size={16} />
            New Bid
          </Button>
        </div>
      </div>

      {/* Stats Grid */}
      {statsLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-5">
              <div className="skeleton h-3 w-24 mb-3" />
              <div className="skeleton h-7 w-16 mb-2" />
              <div className="skeleton h-3 w-20" />
            </div>
          ))}
        </div>
      ) : (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5 animate-stagger">
        <StatsCard
          title="Revenue This Month"
          value={formatCurrency(stats.revenue.thisMonth)}
          change={stats.revenue.monthOverMonthChange}
          icon={<DollarSign size={20} />}
        />
        <StatsCard
          title="Active Bids"
          value={stats.bids.sent}
          changeLabel={`${stats.bids.conversionRate}% win rate`}
          icon={<FileText size={20} />}
          trend="up"
        />
        <StatsCard
          title="Jobs In Progress"
          value={stats.jobs.inProgress}
          changeLabel={`${stats.jobs.scheduled} scheduled`}
          icon={<Briefcase size={20} />}
          trend="neutral"
        />
        <StatsCard
          title="Overdue Invoices"
          value={stats.invoices.overdue}
          changeLabel={formatCurrency(stats.invoices.overdueAmount)}
          icon={<AlertCircle size={20} />}
          trend={stats.invoices.overdue > 0 ? 'down' : 'neutral'}
        />
      </div>
      )}

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
        {/* Left Column - Revenue Chart & Jobs */}
        <div className="lg:col-span-2 space-y-6">
          {/* Revenue Chart - PRO FEATURE */}
          <ProModeGate>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <div>
                  <CardTitle>Revenue Overview</CardTitle>
                  <p className="text-sm text-muted mt-1">Monthly revenue for the past year</p>
                </div>
                <div className="flex items-center gap-4 text-sm">
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-3 rounded-full bg-blue-500" />
                    <span className="text-muted">Revenue</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-3 rounded-full bg-emerald-500" />
                    <span className="text-muted">Profit</span>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  <SimpleAreaChart data={revenueChartData} height={256} />
                </div>
                <div className="grid grid-cols-3 gap-4 mt-4 pt-4 border-t border-main">
                  <div>
                    <p className="text-sm text-muted">Total Revenue</p>
                    <p className="text-xl font-semibold text-main">
                      {formatCurrency(revenueData.reduce((sum, d) => sum + d.revenue, 0))}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted">Total Expenses</p>
                    <p className="text-xl font-semibold text-main">
                      {formatCurrency(revenueData.reduce((sum, d) => sum + d.expenses, 0))}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted">Net Profit</p>
                    <p className="text-xl font-semibold text-emerald-600">
                      {formatCurrency(revenueData.reduce((sum, d) => sum + d.profit, 0))}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </ProModeGate>

          {/* Today's Schedule */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0">
              <CardTitle>Today's Schedule</CardTitle>
              <Button variant="ghost" size="sm" onClick={() => router.push('/dashboard/calendar')}>
                View All
                <ArrowRight size={14} />
              </Button>
            </CardHeader>
            <CardContent className="p-0">
              {todayJobs.length === 0 ? (
                <div className="px-6 py-8 text-center text-muted">
                  <Calendar size={40} className="mx-auto mb-2 opacity-50" />
                  <p>No jobs scheduled for today</p>
                </div>
              ) : (
                <div className="divide-y divide-main">
                  {todayJobs.map((item) => (
                    <div
                      key={item.id}
                      className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
                      onClick={() => router.push(`/dashboard/jobs/${item.jobId}`)}
                    >
                      <div className="flex items-start gap-4">
                        <div
                          className="w-1 h-full min-h-[60px] rounded-full"
                          style={{ backgroundColor: item.color }}
                        />
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center justify-between gap-2">
                            <h4 className="font-medium text-main truncate">{item.title}</h4>
                            <span className="text-sm text-muted whitespace-nowrap">
                              {formatTime(item.start)} - {formatTime(item.end)}
                            </span>
                          </div>
                          {item.description && (
                            <p className="text-sm text-muted mt-1 truncate">{item.description}</p>
                          )}
                          <div className="flex items-center gap-4 mt-2">
                            <AvatarGroup
                              avatars={item.assignedTo.map((id) => {
                                const member = team.find((t) => t.id === id);
                                return { name: member?.name || 'Unknown' };
                              })}
                              size="sm"
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Upcoming Jobs */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0">
              <CardTitle>Active Jobs</CardTitle>
              <Button variant="ghost" size="sm" onClick={() => router.push('/dashboard/jobs')}>
                View All
                <ArrowRight size={14} />
              </Button>
            </CardHeader>
            <CardContent className="p-0">
              <div className="divide-y divide-main">
                {upcomingJobs.map((job) => (
                  <div
                    key={job.id}
                    className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
                    onClick={() => router.push(`/dashboard/jobs/${job.id}`)}
                  >
                    <div className="flex items-center justify-between gap-4">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <h4 className="font-medium text-main truncate">{job.title}</h4>
                          <StatusBadge status={job.status} />
                        </div>
                        <p className="text-sm text-muted mt-1">
                          {job.customer?.firstName} {job.customer?.lastName}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="font-medium text-main">
                          {formatCurrency(job.estimatedValue)}
                        </p>
                        {job.scheduledStart && (
                          <p className="text-sm text-muted">
                            {formatDate(job.scheduledStart)}
                          </p>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Right Column - Activity, Charts, Quick Actions */}
        <div className="space-y-5">
          {/* PRO MODE: 2-column grid for widgets */}
          <ProModeGate>
            <div className="grid grid-cols-2 gap-4">
              {/* Time Clock Widget */}
              <ClockStatusWidget
                teamMembers={team}
                variant="compact"
              />

              {/* Team Live Map Widget */}
              <Card>
                <CardHeader className="p-4 pb-2">
                  <CardTitle className="text-sm flex items-center gap-2">
                    <Radio size={14} className="text-emerald-500" />
                    Team Live
                  </CardTitle>
                </CardHeader>
                <CardContent className="p-4 pt-0">
                  <TeamMapWidget
                    members={team}
                    onViewAll={() => router.push('/dashboard/team')}
                  />
                </CardContent>
              </Card>

              {/* Jobs by Status Chart */}
              <Card>
                <CardHeader className="p-4 pb-2">
                  <CardTitle className="text-sm">Jobs by Status</CardTitle>
                </CardHeader>
                <CardContent className="p-4 pt-0">
                  <div className="flex items-center justify-center">
                    <DonutChart
                      data={jobsByStatusData}
                      size={100}
                      thickness={18}
                      centerValue={jobsByStatusData.reduce((sum, d) => sum + d.value, 0).toString()}
                      centerLabel="Total"
                    />
                  </div>
                  <DonutLegend
                    data={jobsByStatusData}
                    className="mt-2 text-xs"
                    formatValue={(v) => v.toString()}
                  />
                </CardContent>
              </Card>

              {/* Revenue by Category */}
              <Card>
                <CardHeader className="p-4 pb-2">
                  <CardTitle className="text-sm">Revenue by Category</CardTitle>
                </CardHeader>
                <CardContent className="p-4 pt-0">
                  <DonutLegend
                    data={revenueByCategoryData}
                    className="text-xs"
                    formatValue={(v) => formatCurrency(v)}
                  />
                  <div className="mt-2">
                    <SimpleBarChart
                      data={revenueByCategoryData.map((d) => ({
                        label: d.name,
                        value: d.value,
                        color: d.color,
                      }))}
                      height={60}
                    />
                  </div>
                </CardContent>
              </Card>
            </div>
          </ProModeGate>

          {/* Overdue Invoices Alert */}
          {overdueInvoices.length > 0 && (
            <Card className="border-red-200 dark:border-red-900/50 bg-red-50 dark:bg-red-900/10">
              <CardContent className="p-4">
                <div className="flex items-start gap-3">
                  <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg">
                    <AlertCircle size={20} className="text-red-600 dark:text-red-400" />
                  </div>
                  <div className="flex-1">
                    <h4 className="font-medium text-red-900 dark:text-red-100">
                      {overdueInvoices.length} Overdue Invoice{overdueInvoices.length > 1 ? 's' : ''}
                    </h4>
                    <p className="text-sm text-red-700 dark:text-red-300 mt-1">
                      {formatCurrency(overdueInvoices.reduce((sum, i) => sum + i.amountDue, 0))} outstanding
                    </p>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="mt-2 text-red-700 dark:text-red-300 hover:text-red-900 hover:bg-red-100 dark:hover:bg-red-900/30 p-0"
                      onClick={() => router.push('/dashboard/invoices?status=overdue')}
                    >
                      View Invoices
                      <ArrowRight size={14} />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Recent Activity - PRO FEATURE */}
          <ProModeGate>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0">
                <CardTitle>Recent Activity</CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                <div className="divide-y divide-main">
                  {recentActivity.map((activity) => (
                    <div key={activity.id} className="px-6 py-3">
                      <div className="flex items-start gap-3">
                        <Avatar name={activity.userName} size="sm" />
                        <div className="flex-1 min-w-0">
                          <p className="text-sm text-main">
                            <span className="font-medium">{activity.userName}</span>{' '}
                            <span className="text-muted">{activity.description}</span>
                          </p>
                          <p className="text-xs text-muted mt-0.5">
                            {formatRelativeTime(activity.createdAt)}
                          </p>
                        </div>
                        <ActivityIcon type={activity.type} />
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </ProModeGate>
        </div>
      </div>

    </div>
  );
}

function ActivityIcon({ type }: { type: string }) {
  const icons: Record<string, { icon: React.ReactNode; color: string }> = {
    created: { icon: <FileText size={14} />, color: 'text-blue-500' },
    paid: { icon: <DollarSign size={14} />, color: 'text-emerald-500' },
    completed: { icon: <CheckCircle2 size={14} />, color: 'text-emerald-500' },
    sent: { icon: <Send size={14} />, color: 'text-blue-500' },
    viewed: { icon: <Eye size={14} />, color: 'text-blue-400' },
    accepted: { icon: <CheckCircle2 size={14} />, color: 'text-emerald-500' },
  };

  const { icon, color } = icons[type] || { icon: <Clock size={14} />, color: 'text-muted' };

  return <span className={color}>{icon}</span>;
}
