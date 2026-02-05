'use client';

import { useState } from 'react';
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
  Sparkles,
  Plus,
  Radio,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatsCard } from '@/components/ui/stats-card';
import { StatusBadge } from '@/components/ui/badge';
import { Avatar, AvatarGroup } from '@/components/ui/avatar';
import { SimpleAreaChart, DonutChart, DonutLegend, SimpleBarChart } from '@/components/ui/charts';
import { Button } from '@/components/ui/button';
import { ZAIChat, ZAITrigger } from '@/components/z-ai-chat';
import { CommandPalette } from '@/components/command-palette';
import { TeamMapWidget } from '@/components/ui/team-map';
import { ClockStatusWidget } from '@/components/time-clock/clock-status-widget';
import { usePermissions, ProModeGate } from '@/components/permission-gate';
import { doc, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { formatCurrency, formatRelativeTime, formatDate, formatTime, cn } from '@/lib/utils';
import {
  mockDashboardStats,
  mockJobs,
  mockInvoices,
  mockBids,
  mockActivity,
  mockSchedule,
  mockTeam,
  mockRevenueData,
  mockJobsByStatus,
  mockRevenueByCategory,
} from '@/lib/mock-data';

export default function DashboardPage() {
  const router = useRouter();
  const [showZChat, setShowZChat] = useState(false);
  const [zChatMinimized, setZChatMinimized] = useState(false);
  const { isProMode, companyId, loading: permLoading } = usePermissions();

  const handleToggleProMode = async () => {
    if (!companyId) return;
    const newMode = isProMode ? 'simple' : 'pro';
    try {
      await updateDoc(doc(db, 'companies', companyId), {
        uiMode: newMode,
        updatedAt: new Date().toISOString(),
      });
    } catch (e) {
      console.error('Failed to toggle mode:', e);
    }
  };

  const stats = mockDashboardStats;
  const todayJobs = mockSchedule.filter((s) => {
    const today = new Date();
    const itemDate = new Date(s.start);
    return itemDate.toDateString() === today.toDateString();
  });

  const upcomingJobs = mockJobs.filter(
    (j) => j.status === 'scheduled' || j.status === 'in_progress'
  ).slice(0, 5);

  const overdueInvoices = mockInvoices.filter((i) => i.status === 'overdue');
  const recentActivity = mockActivity.slice(0, 6);

  // Chart data
  const revenueChartData = mockRevenueData.map((d) => ({
    date: d.date,
    value: d.revenue,
  }));

  return (
    <div className="space-y-6">
      {/* Command Palette */}
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Dashboard</h1>
          <p className="text-muted mt-1">
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
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
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

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
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
                      {formatCurrency(mockRevenueData.reduce((sum, d) => sum + d.revenue, 0))}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted">Total Expenses</p>
                    <p className="text-xl font-semibold text-main">
                      {formatCurrency(mockRevenueData.reduce((sum, d) => sum + d.expenses, 0))}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted">Net Profit</p>
                    <p className="text-xl font-semibold text-emerald-600">
                      {formatCurrency(mockRevenueData.reduce((sum, d) => sum + d.profit, 0))}
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
                                const member = mockTeam.find((t) => t.id === id);
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
        <div className="space-y-6">
          {/* Quick Actions - Ask Z */}
          <Card className="bg-gradient-to-br from-[var(--accent)] to-[color-mix(in_srgb,var(--accent),black_20%)] text-white border-0">
            <CardContent className="p-5">
              <div className="flex items-center gap-3 mb-3">
                <Sparkles size={20} />
                <div>
                  <h3 className="font-semibold">Ask Z</h3>
                  <p className="text-white/80 text-xs">Your business assistant</p>
                </div>
              </div>
              <div className="space-y-1.5">
                <button
                  onClick={() => setShowZChat(true)}
                  className="w-full text-left px-3 py-2 bg-white/10 hover:bg-white/20 rounded-lg transition-colors text-sm"
                >
                  "Create a bid for panel upgrade"
                </button>
                <button
                  onClick={() => setShowZChat(true)}
                  className="w-full text-left px-3 py-2 bg-white/10 hover:bg-white/20 rounded-lg transition-colors text-sm"
                >
                  "What's my schedule tomorrow?"
                </button>
              </div>
            </CardContent>
          </Card>

          {/* PRO MODE: 2-column grid for widgets */}
          <ProModeGate>
            <div className="grid grid-cols-2 gap-4">
              {/* Time Clock Widget */}
              <ClockStatusWidget
                teamMembers={mockTeam}
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
                    members={mockTeam}
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
                      data={mockJobsByStatus}
                      size={100}
                      thickness={18}
                      centerValue={mockJobsByStatus.reduce((sum, d) => sum + d.value, 0).toString()}
                      centerLabel="Total"
                    />
                  </div>
                  <DonutLegend
                    data={mockJobsByStatus}
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
                    data={mockRevenueByCategory}
                    className="text-xs"
                    formatValue={(v) => formatCurrency(v)}
                  />
                  <div className="mt-2">
                    <SimpleBarChart
                      data={mockRevenueByCategory.map((d) => ({
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

      {/* Z AI Chat */}
      {showZChat ? (
        <ZAIChat
          isOpen={showZChat}
          onClose={() => setShowZChat(false)}
          isMinimized={zChatMinimized}
          onToggleMinimize={() => setZChatMinimized(!zChatMinimized)}
        />
      ) : (
        <ZAITrigger onClick={() => setShowZChat(true)} />
      )}
    </div>
  );
}

function ActivityIcon({ type }: { type: string }) {
  const icons: Record<string, { icon: React.ReactNode; color: string }> = {
    created: { icon: <FileText size={14} />, color: 'text-blue-500' },
    paid: { icon: <DollarSign size={14} />, color: 'text-emerald-500' },
    completed: { icon: <CheckCircle2 size={14} />, color: 'text-emerald-500' },
    sent: { icon: <Send size={14} />, color: 'text-blue-500' },
    viewed: { icon: <Eye size={14} />, color: 'text-purple-500' },
    accepted: { icon: <CheckCircle2 size={14} />, color: 'text-emerald-500' },
  };

  const { icon, color } = icons[type] || { icon: <Clock size={14} />, color: 'text-muted' };

  return <span className={color}>{icon}</span>;
}
