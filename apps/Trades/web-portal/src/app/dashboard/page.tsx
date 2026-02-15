'use client';

import { useState, useEffect, useCallback } from 'react';
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
  Building2,
  DollarSign,
  CheckCircle2,
  Home,
  Send,
  Eye,
  MapPin,
  Phone,
  Plus,
  Radio,
  Shield,
  Satellite,
  PenTool,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatsCard } from '@/components/ui/stats-card';
import { StatusBadge } from '@/components/ui/badge';
import { Avatar, AvatarGroup } from '@/components/ui/avatar';
import { SimpleAreaChart, DonutChart, DonutLegend, SimpleBarChart } from '@/components/ui/charts';
import { Button } from '@/components/ui/button';
import { TeamMapWidget } from '@/components/ui/team-map';
import { ClockStatusWidget } from '@/components/time-clock/clock-status-widget';
import { usePermissions, ProModeGate } from '@/components/permission-gate';
import { getSupabase } from '@/lib/supabase';
import { formatCurrency, formatRelativeTime, formatDate, formatTime, cn } from '@/lib/utils';
import { useStats, useActivity } from '@/lib/hooks/use-stats';
import { useJobs, useSchedule, useTeam } from '@/lib/hooks/use-jobs';
import { useInvoices } from '@/lib/hooks/use-invoices';
import { useVerticalDetection } from '@/lib/hooks/use-verticals';
import { useBids } from '@/lib/hooks/use-bids';
import { useLeases } from '@/lib/hooks/use-leases';
import { usePmMaintenance } from '@/lib/hooks/use-pm-maintenance';
import { useProperties } from '@/lib/hooks/use-properties';
import { useRent } from '@/lib/hooks/use-rent';
import { useReports } from '@/lib/hooks/use-reports';
import { useUnits } from '@/lib/hooks/use-units';
import { JOB_TYPE_LABELS, JOB_TYPE_COLORS } from '@/lib/hooks/mappers';
import { useZConsole } from '@/components/z-console';
import { ZMark } from '@/components/z-console/z-mark';

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
  const verticals = useVerticalDetection();
  const { properties } = useProperties();
  const { units } = useUnits();
  const { charges } = useRent();
  const { requests: maintenanceRequests } = usePmMaintenance();
  const { leases } = useLeases();

  // PM stats
  const pmEnabled = properties.length > 0;
  const totalUnits = units.length;
  const occupiedUnits = units.filter(u => u.status === 'occupied').length;
  const occupancyRate = totalUnits > 0 ? Math.round((occupiedUnits / totalUnits) * 100) : 0;
  const now = new Date();
  const thisMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  const rentDueThisMonth = charges.filter(c => c.dueDate.startsWith(thisMonth)).reduce((sum, c) => sum + c.amount, 0);
  const rentCollectedThisMonth = charges.filter(c => c.dueDate.startsWith(thisMonth)).reduce((sum, c) => sum + c.paidAmount, 0);
  const openMaintenance = maintenanceRequests.filter(r => r.status === 'submitted' || r.status === 'in_progress').length;
  const thirtyDaysFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
  const expiringLeases = leases.filter(l => l.status === 'active' && l.endDate && l.endDate <= thirtyDaysFromNow).length;

  // REPS: Pull time entries for property-related jobs
  const [repsHours, setRepsHours] = useState(0);
  useEffect(() => {
    if (!pmEnabled) return;
    const fetchRepsHours = async () => {
      try {
        const supabase = getSupabase();
        const yearStart = `${new Date().getFullYear()}-01-01T00:00:00`;
        const { data } = await supabase
          .from('time_entries')
          .select('total_minutes, job_id, jobs!inner(property_id)')
          .not('jobs.property_id', 'is', null)
          .gte('clock_in', yearStart)
          .in('status', ['completed', 'approved']);

        const totalMinutes = (data || []).reduce((sum: number, entry: Record<string, unknown>) => {
          return sum + (Number(entry.total_minutes) || 0);
        }, 0);
        setRepsHours(Math.round(totalMinutes / 60));
      } catch {
        // Silent — REPS is informational
      }
    };
    fetchRepsHours();
  }, [pmEnabled]);

  const revenueData = reportData?.monthlyRevenue || [];
  const jobsByStatusData = reportData?.jobsByStatus || [];
  const revenueByCategoryData = reportData?.revenueByCategory || [];

  const handleToggleProMode = async () => {
    if (!companyId) return;
    const newMode = isProMode ? 'simple' : 'pro';
    try {
      const supabase = getSupabase();
      const { data: current } = await supabase.from('companies').select('settings').eq('id', companyId).single();
      const settings = (current?.settings as Record<string, unknown>) || {};
      await supabase.from('companies').update({ settings: { ...settings, ui_mode: newMode } }).eq('id', companyId);
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

      {/* Flagship Features */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card className="cursor-pointer hover:border-accent transition-colors group" onClick={() => router.push('/dashboard/recon')}>
          <CardContent className="p-5 flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-accent/10 flex items-center justify-center group-hover:bg-accent/20 transition-colors">
              <Satellite size={24} className="text-accent" />
            </div>
            <div className="flex-1 min-w-0">
              <h3 className="font-semibold text-main">Property Recon</h3>
              <p className="text-sm text-muted">Scan any address for instant roof, wall, and trade measurements</p>
            </div>
            <ArrowRight size={18} className="text-muted group-hover:text-accent transition-colors" />
          </CardContent>
        </Card>
        <Card className="cursor-pointer hover:border-accent transition-colors group" onClick={() => router.push('/dashboard/sketch-engine')}>
          <CardContent className="p-5 flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-emerald-500/10 flex items-center justify-center group-hover:bg-emerald-500/20 transition-colors">
              <PenTool size={24} className="text-emerald-500" />
            </div>
            <div className="flex-1 min-w-0">
              <h3 className="font-semibold text-main">Sketch Engine</h3>
              <p className="text-sm text-muted">CAD floor plans with trade layers, 3D view, and auto-generated estimates</p>
            </div>
            <ArrowRight size={18} className="text-muted group-hover:text-emerald-500 transition-colors" />
          </CardContent>
        </Card>
      </div>

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
                          {job.jobType !== 'standard' && (
                            <span className={cn('inline-flex items-center gap-1 px-1.5 py-0.5 text-[10px] font-medium rounded-full', JOB_TYPE_COLORS[job.jobType].bg, JOB_TYPE_COLORS[job.jobType].text)}>
                              {JOB_TYPE_LABELS[job.jobType]}
                            </span>
                          )}
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
          {/* Z Intelligence — inline dashboard widget */}
          <DashboardZWidget />

          {/* Team Live Map — always visible */}
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

          {/* PRO MODE: widgets grid */}
          <ProModeGate>
            <div className="grid grid-cols-2 gap-4">
              {/* Time Clock Widget */}
              <ClockStatusWidget
                teamMembers={team}
                variant="compact"
              />

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

            {/* Revenue by Job Type */}
            <RevenueByTypeWidget jobs={jobs} invoices={invoices} />

            {/* Vertical Detection Widgets — progressive disclosure */}
            {!verticals.loading && (
              <>
                {verticals.storm && (
                  <StormDashboardWidget jobs={jobs} invoices={invoices} />
                )}
                {verticals.reconstruction && (
                  <VerticalSummaryCard
                    title="Reconstruction Pipeline"
                    icon={<Briefcase size={14} className="text-orange-500" />}
                    description="Active reconstruction claims detected"
                    linkLabel="View Claims"
                    linkHref="/dashboard/insurance?category=reconstruction"
                  />
                )}
                {verticals.commercial && (
                  <VerticalSummaryCard
                    title="Commercial Claims"
                    icon={<MapPin size={14} className="text-indigo-500" />}
                    description="Commercial property claims active"
                    linkLabel="View Claims"
                    linkHref="/dashboard/insurance?category=commercial"
                  />
                )}
                {verticals.warranty && (
                  <VerticalSummaryCard
                    title="Warranty Network"
                    icon={<Shield size={14} className="text-purple-500" />}
                    description="Multiple warranty company relationships"
                    linkLabel="View Warranties"
                    linkHref="/dashboard/warranties"
                  />
                )}
              </>
            )}

            {/* Rental Portfolio */}
            {pmEnabled && (
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm flex items-center gap-2">
                    <Building2 size={14} className="text-teal-500" />
                    Rental Portfolio
                  </CardTitle>
                  <button
                    onClick={() => router.push('/dashboard/properties')}
                    className="text-xs text-accent hover:underline"
                  >
                    View All
                  </button>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="grid grid-cols-2 gap-3">
                    <div className="p-2 bg-secondary rounded-lg text-center">
                      <p className="text-lg font-semibold text-main">{properties.length}</p>
                      <p className="text-[10px] text-muted">Properties</p>
                    </div>
                    <div className="p-2 bg-secondary rounded-lg text-center">
                      <p className="text-lg font-semibold text-main">{occupancyRate}%</p>
                      <p className="text-[10px] text-muted">Occupancy</p>
                    </div>
                  </div>
                  <div className="space-y-1.5 text-xs">
                    <div className="flex justify-between">
                      <span className="text-muted">Rent Due (This Month)</span>
                      <span className="font-medium text-main">{formatCurrency(rentDueThisMonth)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted">Rent Collected</span>
                      <span className="font-medium text-emerald-600 dark:text-emerald-400">{formatCurrency(rentCollectedThisMonth)}</span>
                    </div>
                    {openMaintenance > 0 && (
                      <div className="flex justify-between">
                        <span className="text-muted">Open Maintenance</span>
                        <span className="font-medium text-amber-600 dark:text-amber-400">{openMaintenance}</span>
                      </div>
                    )}
                    {expiringLeases > 0 && (
                      <div className="flex justify-between">
                        <span className="text-muted">Leases Expiring (30d)</span>
                        <span className="font-medium text-red-500">{expiringLeases}</span>
                      </div>
                    )}
                  </div>
                  {/* Occupancy bar */}
                  <div>
                    <div className="flex justify-between text-[10px] text-muted mb-1">
                      <span>{occupiedUnits}/{totalUnits} units occupied</span>
                      <span>{occupancyRate}%</span>
                    </div>
                    <div className="h-2 bg-secondary rounded-full overflow-hidden">
                      <div className="h-full bg-teal-500 rounded-full" style={{ width: `${occupancyRate}%` }} />
                    </div>
                  </div>
                </CardContent>
              </Card>
            )}

            {/* REPS Hour Tracker */}
            {pmEnabled && (
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm flex items-center gap-2">
                    <Clock size={14} className="text-indigo-500" />
                    REPS Hour Tracker
                  </CardTitle>
                  <span className="text-[10px] text-muted">{new Date().getFullYear()} Tax Year</span>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="text-center">
                    <p className="text-2xl font-bold text-main">{repsHours.toLocaleString()}</p>
                    <p className="text-xs text-muted">of 750 hours</p>
                  </div>
                  <div className="h-2 bg-secondary rounded-full overflow-hidden">
                    <div
                      className={cn('h-full rounded-full', repsHours >= 750 ? 'bg-emerald-500' : repsHours >= 500 ? 'bg-amber-500' : 'bg-indigo-500')}
                      style={{ width: `${Math.min((repsHours / 750) * 100, 100)}%` }}
                    />
                  </div>
                  <div className="flex justify-between text-[10px] text-muted">
                    <span>{Math.max(0, 750 - repsHours)} hrs remaining</span>
                    <span>{repsHours >= 750 ? 'Qualified' : `${Math.round((repsHours / 750) * 100)}%`}</span>
                  </div>
                  {repsHours >= 750 && (
                    <div className="p-2 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg text-center">
                      <p className="text-xs font-medium text-emerald-700 dark:text-emerald-400">REPS Qualified</p>
                    </div>
                  )}
                </CardContent>
              </Card>
            )}
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

const JOB_TYPE_REVENUE_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
  standard: { label: 'Retail', color: 'text-blue-600 dark:text-blue-400', bg: 'bg-blue-500' },
  insurance_claim: { label: 'Insurance', color: 'text-amber-600 dark:text-amber-400', bg: 'bg-amber-500' },
  warranty_dispatch: { label: 'Warranty', color: 'text-purple-600 dark:text-purple-400', bg: 'bg-purple-500' },
  maintenance: { label: 'Maintenance', color: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-500' },
};

function RevenueByTypeWidget({ jobs, invoices }: { jobs: { id: string; jobType: string; estimatedValue: number }[]; invoices: { jobId?: string; total: number; status: string }[] }) {
  // Build job type lookup
  const jobTypeMap = new Map<string, string>();
  for (const job of jobs) {
    jobTypeMap.set(job.id, job.jobType);
  }

  // Sum invoice totals by job type (only paid invoices = real revenue)
  const typeRevenue: Record<string, number> = {};
  const typeCount: Record<string, number> = {};
  for (const inv of invoices) {
    if (!inv.jobId || inv.status !== 'paid') continue;
    const jt = jobTypeMap.get(inv.jobId) || 'standard';
    typeRevenue[jt] = (typeRevenue[jt] || 0) + inv.total;
    typeCount[jt] = (typeCount[jt] || 0) + 1;
  }

  // Also count jobs without invoices by estimated value
  for (const job of jobs) {
    if (!typeRevenue[job.jobType]) {
      typeRevenue[job.jobType] = (typeRevenue[job.jobType] || 0);
    }
  }

  const grandTotal = Object.values(typeRevenue).reduce((a, b) => a + b, 0);
  if (grandTotal === 0) return null;

  const types = Object.keys(typeRevenue).filter((k) => typeRevenue[k] > 0).sort((a, b) => typeRevenue[b] - typeRevenue[a]);

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm flex items-center gap-2">
          <Shield size={14} className="text-muted" />
          Revenue by Job Type
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {/* Stacked bar */}
        <div className="flex h-3 rounded-full overflow-hidden bg-secondary">
          {types.map((t) => (
            <div
              key={t}
              className={cn('h-full', JOB_TYPE_REVENUE_CONFIG[t]?.bg || 'bg-gray-400')}
              style={{ width: `${(typeRevenue[t] / grandTotal) * 100}%` }}
            />
          ))}
        </div>

        {/* Breakdown rows */}
        <div className="space-y-2">
          {types.map((t) => {
            const cfg = JOB_TYPE_REVENUE_CONFIG[t] || { label: t, color: 'text-main', bg: 'bg-gray-400' };
            const pct = ((typeRevenue[t] / grandTotal) * 100).toFixed(1);
            const avg = typeCount[t] ? typeRevenue[t] / typeCount[t] : 0;
            return (
              <div key={t} className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2">
                  <span className={cn('w-2 h-2 rounded-full', cfg.bg)} />
                  <span className="text-muted">{cfg.label}</span>
                  <span className="text-muted/60">{pct}%</span>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-muted/60">avg {formatCurrency(avg)}</span>
                  <span className={cn('font-medium', cfg.color)}>{formatCurrency(typeRevenue[t])}</span>
                </div>
              </div>
            );
          })}
        </div>

        {/* Total */}
        <div className="flex justify-between pt-2 border-t border-main text-sm font-semibold">
          <span>Total</span>
          <span>{formatCurrency(grandTotal)}</span>
        </div>
      </CardContent>
    </Card>
  );
}

function StormDashboardWidget({ jobs, invoices }: { jobs: { id: string; jobType: string; tags: string[]; status: string; estimatedValue: number }[]; invoices: { jobId?: string; total: number; status: string }[] }) {
  const router = useRouter();

  // Find storm-tagged jobs
  const stormJobs = jobs.filter((j) => j.tags.some((t) => t.startsWith('storm:')));
  if (stormJobs.length === 0) return null;

  // Extract unique storm events
  const events = [...new Set(stormJobs.flatMap((j) => j.tags.filter((t) => t.startsWith('storm:')).map((t) => t.replace('storm:', ''))))];

  // Pipeline metrics
  const jobIds = new Set(stormJobs.map((j) => j.id));
  const stormInvoices = invoices.filter((i) => i.jobId && jobIds.has(i.jobId));
  const pipeline = stormJobs.reduce((sum, j) => sum + j.estimatedValue, 0);
  const collected = stormInvoices.filter((i) => i.status === 'paid').reduce((sum, i) => sum + i.total, 0);

  const statusCounts: Record<string, number> = {};
  for (const j of stormJobs) {
    statusCounts[j.status] = (statusCounts[j.status] || 0) + 1;
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm flex items-center gap-2">
          <AlertCircle size={14} className="text-amber-500" />
          Storm Pipeline
        </CardTitle>
        <button
          onClick={() => router.push('/dashboard/jobs?type=insurance_claim')}
          className="text-xs text-accent hover:underline"
        >
          View All
        </button>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="grid grid-cols-2 gap-3">
          <div className="p-2 bg-secondary rounded-lg text-center">
            <p className="text-lg font-semibold text-main">{stormJobs.length}</p>
            <p className="text-[10px] text-muted">Total Jobs</p>
          </div>
          <div className="p-2 bg-secondary rounded-lg text-center">
            <p className="text-lg font-semibold text-main">{events.length}</p>
            <p className="text-[10px] text-muted">Storm Events</p>
          </div>
        </div>

        <div className="space-y-1.5 text-xs">
          <div className="flex justify-between">
            <span className="text-muted">Pipeline</span>
            <span className="font-medium text-main">{formatCurrency(pipeline)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-muted">Collected</span>
            <span className="font-medium text-emerald-600 dark:text-emerald-400">{formatCurrency(collected)}</span>
          </div>
          {statusCounts['in_progress'] && (
            <div className="flex justify-between">
              <span className="text-muted">In Production</span>
              <span className="font-medium text-blue-600 dark:text-blue-400">{statusCounts['in_progress']}</span>
            </div>
          )}
          {statusCounts['completed'] && (
            <div className="flex justify-between">
              <span className="text-muted">Complete</span>
              <span className="font-medium text-emerald-600 dark:text-emerald-400">{statusCounts['completed']}</span>
            </div>
          )}
        </div>

        {events.length > 0 && (
          <div className="pt-2 border-t border-main space-y-1">
            <p className="text-[10px] font-medium text-muted uppercase">Active Events</p>
            {events.slice(0, 3).map((evt) => (
              <div key={evt} className="text-xs text-main truncate">{evt}</div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function VerticalSummaryCard({ title, icon, description, linkLabel, linkHref }: {
  title: string;
  icon: React.ReactNode;
  description: string;
  linkLabel: string;
  linkHref: string;
}) {
  const router = useRouter();
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm flex items-center gap-2">
          {icon}
          {title}
        </CardTitle>
        <button
          onClick={() => router.push(linkHref)}
          className="text-xs text-accent hover:underline"
        >
          {linkLabel}
        </button>
      </CardHeader>
      <CardContent>
        <p className="text-xs text-muted">{description}</p>
      </CardContent>
    </Card>
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

// ── Dashboard Z Intelligence Widget ──────────────────
function DashboardZWidget() {
  const {
    currentThread,
    isThinking,
    quickActions,
    sendMessage,
    setConsoleState,
    consoleState,
  } = useZConsole();
  const [inputValue, setInputValue] = useState('');

  const messages = currentThread?.messages || [];
  const recentMessages = messages.slice(-4);

  const handleSend = () => {
    const trimmed = inputValue.trim();
    if (!trimmed || isThinking) return;
    sendMessage(trimmed);
    setInputValue('');
    if (consoleState === 'collapsed') {
      setConsoleState('open');
    }
  };

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm flex items-center gap-2">
          <ZMark size={16} />
          Z Intelligence
        </CardTitle>
        <kbd className="text-[10px] text-muted bg-secondary px-1.5 py-0.5 rounded border border-main">
          ⌘J
        </kbd>
      </CardHeader>
      <CardContent className="space-y-3">
        {/* Recent messages preview */}
        {recentMessages.length > 0 && (
          <div className="max-h-[160px] overflow-y-auto space-y-2 scrollbar-hide">
            {recentMessages.map((msg) => (
              <div
                key={msg.id}
                className={cn(
                  'text-xs p-2 rounded-lg',
                  msg.role === 'user'
                    ? 'bg-accent/5 text-main ml-4'
                    : 'bg-secondary text-main mr-4',
                )}
              >
                <p className="line-clamp-2">{msg.content}</p>
              </div>
            ))}
          </div>
        )}

        {/* Quick actions — shown when no conversation */}
        {messages.length === 0 && quickActions.length > 0 && (
          <div className="flex flex-wrap gap-1.5">
            {quickActions.slice(0, 4).map((action) => (
              <button
                key={action.id}
                onClick={() => {
                  sendMessage(action.prompt);
                  if (consoleState === 'collapsed') setConsoleState('open');
                }}
                className="text-[11px] px-2.5 py-1 rounded-full bg-secondary border border-main text-muted hover:text-main hover:border-accent/40 transition-colors"
              >
                {action.label}
              </button>
            ))}
          </div>
        )}

        {/* Input */}
        <div className="flex items-center gap-2">
          <input
            type="text"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                handleSend();
              }
            }}
            placeholder="Ask Z anything..."
            className="flex-1 text-[13px] bg-secondary border border-main rounded-lg px-3 py-2 text-main placeholder:text-muted outline-none focus:border-accent/40 transition-colors"
          />
          <button
            onClick={handleSend}
            disabled={!inputValue.trim() || isThinking}
            className={cn(
              'p-2 rounded-lg transition-colors flex-shrink-0',
              inputValue.trim()
                ? 'bg-accent text-white hover:bg-accent/90'
                : 'bg-secondary text-muted cursor-not-allowed',
            )}
          >
            <Send size={14} />
          </button>
        </div>

        {/* Thinking indicator */}
        {isThinking && (
          <div className="flex items-center gap-2 text-[11px] text-emerald-500">
            <span className="inline-flex gap-0.5">
              <span className="w-1 h-1 rounded-full bg-emerald-500 animate-bounce" style={{ animationDelay: '0ms' }} />
              <span className="w-1 h-1 rounded-full bg-emerald-500 animate-bounce" style={{ animationDelay: '150ms' }} />
              <span className="w-1 h-1 rounded-full bg-emerald-500 animate-bounce" style={{ animationDelay: '300ms' }} />
            </span>
            Z is thinking...
          </div>
        )}

        {/* Full console link */}
        {messages.length > 0 && (
          <button
            onClick={() => setConsoleState(consoleState === 'collapsed' ? 'open' : consoleState)}
            className="text-[11px] text-accent hover:underline"
          >
            Open full conversation
          </button>
        )}
      </CardContent>
    </Card>
  );
}
