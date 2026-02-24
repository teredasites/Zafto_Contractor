'use client';

import { useState, useMemo, useEffect, useCallback } from 'react';
import {
  Clock,
  ChevronLeft,
  ChevronRight,
  Download,
  Check,
  X,
  MapPin,
  Calendar,
  Timer,
  Coffee,
  Play,
  AlertCircle,
  CheckCircle2,
  Pause,
  DollarSign,
  Shield,
  ArrowRight,
  Briefcase,
  History,
  Pencil,
  Eye,
  Signal,
  WifiOff,
  UserCheck,
  ClipboardCheck,
  ChevronDown,
  BarChart3,
  TrendingUp,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatsCard } from '@/components/ui/stats-card';
import { Button } from '@/components/ui/button';
import { Avatar } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import { useTeam } from '@/lib/hooks/use-jobs';
import { useTimeClock, type TimeEntry } from '@/lib/hooks/use-time-clock';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale, formatTimeLocale } from '@/lib/format-locale';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type TabKey = 'live' | 'timesheets' | 'allocation' | 'adjustments';

interface TimesheetRow {
  userId: string;
  userName: string;
  role: string;
  dailyHours: (number | null)[];       // Mon-Sun (7 entries)
  dailyJobs: (string | null)[];
  dailyOt: (number | null)[];
  weekTotal: number;
  otTotal: number;
  status: 'pending' | 'approved' | 'rejected';
}

interface JobAllocationRow {
  jobId: string;
  jobName: string;
  employees: { userId: string; userName: string; hours: number; rate: number; cost: number }[];
  totalHours: number;
  totalCost: number;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const getWeekRange = (date: Date) => {
  const start = new Date(date);
  start.setDate(start.getDate() - start.getDay() + 1); // Monday
  const end = new Date(start);
  end.setDate(end.getDate() + 6); // Sunday
  return { start, end };
};

const formatWeekRange = (start: Date, end: Date) => {
  return `${formatDateLocale(start)} - ${formatDateLocale(end)}, ${end.getFullYear()}`;
};

const TABS: { key: TabKey; label: string; icon: React.ReactNode }[] = [
  { key: 'live', label: 'Live Clock', icon: <Signal size={16} /> },
  { key: 'timesheets', label: 'Timesheets', icon: <ClipboardCheck size={16} /> },
  { key: 'allocation', label: 'Job Allocation', icon: <Briefcase size={16} /> },
  { key: 'adjustments', label: 'Adjustments', icon: <History size={16} /> },
];

const DAY_LABELS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

function getDayOfWeek(iso: string, weekStart: Date): number {
  const d = new Date(iso);
  const start = new Date(weekStart);
  const diff = Math.floor((d.getTime() - start.getTime()) / 86400000);
  return Math.max(0, Math.min(6, diff));
}

// ---------------------------------------------------------------------------
// Derived data builders — compute UI data from real entries
// ---------------------------------------------------------------------------

function buildLiveEmployees(entries: TimeEntry[], now: number) {
  return entries
    .filter(e => e.status === 'active' && !e.clockOut)
    .map(e => {
      const elapsed = Math.round((now - new Date(e.clockIn).getTime()) / 60000);
      return {
        userId: e.userId,
        userName: e.userName,
        avatar: e.userAvatar,
        role: '',
        clockedInAt: e.clockIn,
        elapsed,
        jobTitle: e.jobTitle,
        jobId: e.jobId,
        breakMinutes: e.breakMinutes,
        notes: e.notes,
        entryId: e.id,
      };
    });
}

function buildTimesheetRows(entries: TimeEntry[], weekStart: Date): TimesheetRow[] {
  const byUser = new Map<string, TimeEntry[]>();
  for (const e of entries) {
    const arr = byUser.get(e.userId) || [];
    arr.push(e);
    byUser.set(e.userId, arr);
  }

  const rows: TimesheetRow[] = [];
  for (const [userId, userEntries] of byUser) {
    const dailyHours: (number | null)[] = Array(7).fill(null);
    const dailyJobs: (string | null)[] = Array(7).fill(null);
    const dailyOt: (number | null)[] = Array(7).fill(null);

    for (const e of userEntries) {
      const dayIdx = getDayOfWeek(e.clockIn, weekStart);
      const hours = e.totalMinutes ? e.totalMinutes / 60 : 0;
      dailyHours[dayIdx] = (dailyHours[dayIdx] || 0) + hours;
      if (e.jobTitle) dailyJobs[dayIdx] = e.jobTitle;
      const ot = e.overtimeMinutes / 60;
      if (ot > 0) dailyOt[dayIdx] = (dailyOt[dayIdx] || 0) + ot;
    }

    const weekTotal = dailyHours.reduce((s, h) => s + (h || 0), 0);
    const otTotal = dailyOt.reduce((s, h) => s + (h || 0), 0);

    // Determine status: if any entry is rejected -> rejected, if all approved -> approved, else pending
    const hasRejected = userEntries.some(e => e.status === 'rejected');
    const allApproved = userEntries.every(e => e.status === 'approved');
    const status = hasRejected ? 'rejected' : allApproved ? 'approved' : 'pending';

    rows.push({
      userId,
      userName: userEntries[0]?.userName || 'Unknown',
      role: '',
      dailyHours,
      dailyJobs,
      dailyOt,
      weekTotal: Math.round(weekTotal * 10) / 10,
      otTotal: Math.round(otTotal * 10) / 10,
      status,
    });
  }

  return rows;
}

function buildJobAllocations(entries: TimeEntry[]): JobAllocationRow[] {
  const byJob = new Map<string, TimeEntry[]>();
  for (const e of entries) {
    if (!e.jobId) continue;
    const arr = byJob.get(e.jobId) || [];
    arr.push(e);
    byJob.set(e.jobId, arr);
  }

  const rows: JobAllocationRow[] = [];
  for (const [jobId, jobEntries] of byJob) {
    const byEmp = new Map<string, { userName: string; hours: number; rate: number; cost: number }>();
    for (const e of jobEntries) {
      const existing = byEmp.get(e.userId);
      const hours = e.totalMinutes ? e.totalMinutes / 60 : 0;
      const rate = e.hourlyRate || 0;
      const cost = e.laborCost || hours * rate;
      if (existing) {
        existing.hours += hours;
        existing.cost += cost;
        if (rate > 0) existing.rate = rate;
      } else {
        byEmp.set(e.userId, { userName: e.userName, hours, rate, cost });
      }
    }

    const employees = [...byEmp.entries()].map(([uid, data]) => ({
      userId: uid,
      userName: data.userName,
      hours: Math.round(data.hours * 10) / 10,
      rate: data.rate,
      cost: Math.round(data.cost * 100) / 100,
    }));

    rows.push({
      jobId,
      jobName: jobEntries[0]?.jobTitle || 'Unknown Job',
      employees,
      totalHours: Math.round(employees.reduce((s, e) => s + e.hours, 0) * 10) / 10,
      totalCost: Math.round(employees.reduce((s, e) => s + e.cost, 0) * 100) / 100,
    });
  }

  return rows.sort((a, b) => b.totalHours - a.totalHours);
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export default function TimeClockPage() {
  const { t, formatDate } = useTranslation();
  const { team } = useTeam();
  const [currentWeek, setCurrentWeek] = useState(new Date());
  const [selectedUser, setSelectedUser] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<TabKey>('live');
  const [expandedJob, setExpandedJob] = useState<string | null>(null);
  const [now, setNow] = useState(Date.now());

  const weekRange = getWeekRange(currentWeek);
  const { entries: allEntries, summary, loading, error, approveEntry, rejectEntry } = useTimeClock(weekRange.start);

  // Live tick for elapsed timers
  useEffect(() => {
    if (activeTab !== 'live') return;
    const interval = setInterval(() => setNow(Date.now()), 30000);
    return () => clearInterval(interval);
  }, [activeTab]);

  // Filter by selected user
  const weekEntries = useMemo(() => {
    if (!selectedUser) return allEntries;
    return allEntries.filter(e => e.userId === selectedUser);
  }, [allEntries, selectedUser]);

  // Derived data from real entries
  const liveEmployees = useMemo(() => buildLiveEmployees(allEntries, now), [allEntries, now]);
  const timesheetRows = useMemo(() => buildTimesheetRows(weekEntries, weekRange.start), [weekEntries, weekRange.start]);
  const jobAllocations = useMemo(() => buildJobAllocations(weekEntries), [weekEntries]);

  // Adjustment entries: completed entries that have notes or were recently modified
  const adjustmentEntries = useMemo(() => {
    return allEntries.filter(e => e.notes && e.notes.length > 0).slice(0, 20);
  }, [allEntries]);

  const navigateWeek = (direction: 'prev' | 'next') => {
    const newDate = new Date(currentWeek);
    newDate.setDate(newDate.getDate() + (direction === 'next' ? 7 : -7));
    setCurrentWeek(newDate);
  };

  const handleExport = () => {
    const headers = ['Employee', 'Date', 'Clock In', 'Clock Out', 'Hours', 'Break (min)', 'Status', 'Job', 'Notes'];
    const rows = weekEntries.map(e => [
      e.userName,
      formatDate(e.clockIn),
      formatTimeLocale(e.clockIn),
      e.clockOut ? formatTimeLocale(e.clockOut) : '-',
      e.totalMinutes ? (e.totalMinutes / 60).toFixed(2) : '-',
      e.breakMinutes.toString(),
      e.status,
      e.jobTitle || '-',
      e.notes || '',
    ]);
    const csv = [headers.join(','), ...rows.map(r => r.map(c => `"${c}"`).join(','))].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.download = `timesheet-${currentWeek.toISOString().slice(0, 10)}.csv`; a.click();
    URL.revokeObjectURL(url);
  };

  const formatElapsed = (minutes: number) => {
    const h = Math.floor(minutes / 60);
    const m = Math.round(minutes % 60);
    if (h === 0) return `${m}m`;
    return `${h}h ${m}m`;
  };

  const formatHours = (minutes?: number | null) => {
    if (minutes === undefined || minutes === null) return '-';
    const h = Math.floor(minutes / 60);
    const m = Math.round(minutes % 60);
    return `${h}h ${m}m`;
  };

  const getTimesheetBadgeVariant = (status: string): 'warning' | 'success' | 'error' => {
    if (status === 'approved') return 'success';
    if (status === 'rejected') return 'error';
    return 'warning';
  };

  const liveCount = liveEmployees.length;
  const onBreakCount = 0; // TODO: track break status in time_entries
  const totalAllocatedCost = jobAllocations.reduce((s, j) => s + j.totalCost, 0);

  // ---------------------------------------------------------------------------
  // Loading / Error states
  // ---------------------------------------------------------------------------

  if (loading) {
    return (
      <div className="space-y-6 animate-pulse">
        <div className="h-8 bg-surface rounded w-48" />
        <div className="grid grid-cols-4 gap-4">{[1, 2, 3, 4].map(i => <div key={i} className="h-24 bg-surface rounded-lg" />)}</div>
        <div className="h-64 bg-surface rounded-lg" />
      </div>
    );
  }

  if (error) {
    return (
      <Card><CardContent className="p-8 text-center"><p className="text-red-500">{error}</p></CardContent></Card>
    );
  }

  // ---------------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------------

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('timeClock.title')}</h1>
          <p className="text-muted mt-1">{t('timeClock.manageDesc')}</p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="secondary" onClick={handleExport}>
            <Download size={16} />
            {t('common.export')}
          </Button>
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          title={t('timeClock.onTheClockNow')}
          value={summary.activeNow.toString()}
          icon={<Play size={20} className="text-green-500" />}
          trend="neutral"
          changeLabel={`${onBreakCount} on break`}
        />
        <StatsCard
          title={t('timeClock.totalHoursThisWeek')}
          value={`${Math.floor(summary.totalHoursWeek)}h ${Math.round((summary.totalHoursWeek % 1) * 60)}m`}
          icon={<Timer size={20} />}
          trend="neutral"
          changeLabel={`${Math.round(summary.totalHoursWeek / 8)} day equiv.`}
        />
        <StatsCard
          title={t('timeClock.pendingApproval')}
          value={summary.pendingApproval.toString()}
          icon={<AlertCircle size={20} className="text-amber-500" />}
          trend={summary.pendingApproval > 0 ? 'down' : 'neutral'}
          changeLabel={t('timeClock.entriesToReview')}
        />
        <StatsCard
          title={t('timeClock.overtimeHours')}
          value={`${Math.floor(summary.totalOvertimeWeek)}h ${Math.round((summary.totalOvertimeWeek % 1) * 60)}m`}
          icon={<TrendingUp size={20} className="text-orange-500" />}
          trend="neutral"
          changeLabel="total this week"
        />
      </div>

      {/* Tab Bar */}
      <div className="flex items-center gap-1 border-b border-main">
        {TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={cn(
              'flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors -mb-px',
              activeTab === tab.key
                ? 'border-accent text-accent'
                : 'border-transparent text-muted hover:text-main hover:border-main/30'
            )}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      {/* ================================================================= */}
      {/* TAB 1: LIVE CLOCK                                                 */}
      {/* ================================================================= */}
      {activeTab === 'live' && (
        <div className="space-y-6">
          {/* Live header row */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-2">
                <span className="relative flex h-3 w-3">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75" />
                  <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500" />
                </span>
                <span className="text-sm font-medium text-main">{liveCount} employee{liveCount !== 1 ? 's' : ''} clocked in</span>
              </div>
            </div>
            <p className="text-xs text-muted">Auto-refreshes every 30 seconds</p>
          </div>

          {/* Live employee cards */}
          {liveEmployees.length === 0 ? (
            <Card>
              <CardContent className="py-16 text-center">
                <Clock className="w-10 h-10 text-muted mx-auto mb-3" />
                <p className="text-main font-medium mb-1">No employees clocked in</p>
                <p className="text-sm text-muted">Active time entries will appear here in real time</p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              {liveEmployees.map((emp) => (
                <Card key={emp.entryId} className="relative overflow-hidden">
                  <CardContent className="p-5">
                    <div className="flex items-start gap-4">
                      <Avatar name={emp.userName} size="lg" showStatus isOnline />
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between mb-1">
                          <div>
                            <p className="font-semibold text-main">{emp.userName}</p>
                            {emp.role && <p className="text-xs text-muted">{emp.role}</p>}
                          </div>
                          <div className="text-right">
                            <p className="text-2xl font-bold text-main tabular-nums">{formatElapsed(emp.elapsed)}</p>
                            <p className="text-xs text-muted">elapsed</p>
                          </div>
                        </div>

                        {/* Job assignment */}
                        {emp.jobTitle ? (
                          <div className="flex items-center gap-2 mt-3 px-3 py-2 rounded-lg bg-secondary/50">
                            <Briefcase size={14} className="text-muted flex-shrink-0" />
                            <p className="text-sm text-main truncate">{emp.jobTitle}</p>
                          </div>
                        ) : (
                          <div className="flex items-center gap-2 mt-3 px-3 py-2 rounded-lg bg-amber-500/5 border border-amber-500/20">
                            <AlertCircle size={14} className="text-amber-500 flex-shrink-0" />
                            <p className="text-sm text-amber-500">No job assigned</p>
                          </div>
                        )}

                        {/* Bottom row */}
                        <div className="flex items-center justify-between mt-3">
                          <div className="flex items-center gap-3">
                            {emp.breakMinutes > 0 && (
                              <div className="flex items-center gap-1 text-xs text-muted">
                                <Coffee size={12} />
                                <span>{emp.breakMinutes}m break taken</span>
                              </div>
                            )}
                          </div>
                          <div className="text-xs text-muted">
                            In: {formatTimeLocale(emp.clockedInAt)}
                          </div>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {/* Payroll / Job cost flow indicator */}
          <Card className="border-accent/20 bg-accent/5">
            <CardContent className="py-4">
              <div className="flex items-center gap-4">
                <div className="flex items-center gap-2 text-sm text-main">
                  <Clock size={16} className="text-accent" />
                  <span className="font-medium">Time Clock</span>
                </div>
                <ArrowRight size={16} className="text-muted" />
                <div className="flex items-center gap-2 text-sm text-main">
                  <DollarSign size={16} className="text-green-500" />
                  <span className="font-medium">Payroll</span>
                </div>
                <ArrowRight size={16} className="text-muted" />
                <div className="flex items-center gap-2 text-sm text-main">
                  <Briefcase size={16} className="text-blue-500" />
                  <span className="font-medium">Job Costing</span>
                </div>
                <div className="ml-auto text-xs text-muted">
                  Approved hours automatically flow to payroll and job cost reports
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* ================================================================= */}
      {/* TAB 2: TIMESHEETS                                                 */}
      {/* ================================================================= */}
      {activeTab === 'timesheets' && (
        <div className="space-y-6">
          {/* Week navigation */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <Button variant="ghost" size="sm" onClick={() => navigateWeek('prev')}>
                  <ChevronLeft size={18} />
                </Button>
                <div className="min-w-[200px] text-center">
                  <p className="font-semibold text-main">{formatWeekRange(weekRange.start, weekRange.end)}</p>
                </div>
                <Button variant="ghost" size="sm" onClick={() => navigateWeek('next')}>
                  <ChevronRight size={18} />
                </Button>
              </div>
              <Button variant="ghost" size="sm" onClick={() => setCurrentWeek(new Date())} className="text-accent">
                This Week
              </Button>
            </div>

            <div className="flex items-center gap-3">
              <select
                value={selectedUser || ''}
                onChange={(e) => setSelectedUser(e.target.value || null)}
                className="px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
              >
                <option value="">{t('timeClock.allEmployees')}</option>
                {team.map((member) => (
                  <option key={member.id} value={member.id}>{member.name}</option>
                ))}
              </select>
            </div>
          </div>

          {/* Timesheet Grid */}
          {timesheetRows.length === 0 ? (
            <Card>
              <CardContent className="py-16 text-center">
                <ClipboardCheck className="w-10 h-10 text-muted mx-auto mb-3" />
                <p className="text-main font-medium mb-1">No time entries this week</p>
                <p className="text-sm text-muted">Time entries will appear here once employees clock in</p>
              </CardContent>
            </Card>
          ) : (
            <Card>
              <CardContent className="p-0">
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b border-main">
                        <th className="text-left px-4 py-3 text-xs font-semibold text-muted uppercase tracking-wider w-56 sticky left-0 bg-surface z-10">Employee</th>
                        {DAY_LABELS.map((day, i) => {
                          const isWeekend = i >= 5;
                          return (
                            <th key={day} className={cn('text-center px-3 py-3 text-xs font-semibold uppercase tracking-wider min-w-[100px]', isWeekend ? 'text-muted/60' : 'text-muted')}>
                              {day}
                            </th>
                          );
                        })}
                        <th className="text-center px-4 py-3 text-xs font-semibold text-muted uppercase tracking-wider w-20">Total</th>
                        <th className="text-center px-4 py-3 text-xs font-semibold text-muted uppercase tracking-wider w-16">OT</th>
                        <th className="text-center px-4 py-3 text-xs font-semibold text-muted uppercase tracking-wider w-28">Status</th>
                        <th className="text-center px-4 py-3 text-xs font-semibold text-muted uppercase tracking-wider w-24">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-main">
                      {timesheetRows.map((row) => {
                        const hasOvertime = row.otTotal > 0;
                        return (
                          <tr key={row.userId} className="hover:bg-surface-hover group">
                            <td className="px-4 py-3 sticky left-0 bg-surface group-hover:bg-surface-hover z-10">
                              <div className="flex items-center gap-3">
                                <Avatar name={row.userName} size="sm" />
                                <div>
                                  <p className="font-medium text-main text-sm">{row.userName}</p>
                                  {row.role && <p className="text-xs text-muted">{row.role}</p>}
                                </div>
                              </div>
                            </td>
                            {row.dailyHours.map((hours, i) => {
                              const isWeekend = i >= 5;
                              const ot = row.dailyOt[i];
                              const job = row.dailyJobs[i];
                              const isOt = ot !== null && ot > 0;
                              return (
                                <td key={i} className={cn('text-center px-3 py-3', isWeekend && 'bg-secondary/30')}>
                                  {hours !== null && hours > 0 ? (
                                    <div className="space-y-0.5">
                                      <p className={cn('text-sm font-semibold', isOt ? 'text-orange-500' : 'text-main')}>
                                        {hours.toFixed(1)}h
                                      </p>
                                      {isOt && (
                                        <p className="text-[10px] text-orange-500 font-medium">+{ot.toFixed(1)} OT</p>
                                      )}
                                      {job && (
                                        <p className="text-[10px] text-muted truncate max-w-[90px] mx-auto">{job}</p>
                                      )}
                                    </div>
                                  ) : (
                                    <span className="text-muted text-sm">-</span>
                                  )}
                                </td>
                              );
                            })}
                            <td className="text-center px-4 py-3">
                              <p className={cn('text-lg font-bold', row.weekTotal > 40 ? 'text-orange-500' : 'text-main')}>
                                {row.weekTotal.toFixed(1)}
                              </p>
                            </td>
                            <td className="text-center px-4 py-3">
                              {hasOvertime ? (
                                <p className="text-sm font-bold text-orange-500">{row.otTotal.toFixed(1)}h</p>
                              ) : (
                                <span className="text-muted text-sm">-</span>
                              )}
                            </td>
                            <td className="text-center px-4 py-3">
                              <Badge variant={getTimesheetBadgeVariant(row.status)} dot>
                                {row.status === 'pending' ? 'Pending' : row.status === 'approved' ? 'Approved' : 'Rejected'}
                              </Badge>
                            </td>
                            <td className="text-center px-4 py-3">
                              {row.status === 'pending' && (
                                <div className="flex items-center justify-center gap-1">
                                  <button
                                    className="p-1.5 rounded-md hover:bg-green-500/10 text-green-500 transition-colors"
                                    title="Approve"
                                    onClick={async () => {
                                      const userEntries = weekEntries.filter(e => e.userId === row.userId && e.status === 'completed');
                                      for (const entry of userEntries) await approveEntry(entry.id);
                                    }}
                                  >
                                    <Check size={14} />
                                  </button>
                                  <button
                                    className="p-1.5 rounded-md hover:bg-red-500/10 text-red-500 transition-colors"
                                    title="Reject"
                                    onClick={async () => {
                                      const userEntries = weekEntries.filter(e => e.userId === row.userId && e.status === 'completed');
                                      for (const entry of userEntries) await rejectEntry(entry.id);
                                    }}
                                  >
                                    <X size={14} />
                                  </button>
                                </div>
                              )}
                              {row.status === 'approved' && (
                                <CheckCircle2 size={16} className="text-green-500 mx-auto" />
                              )}
                              {row.status === 'rejected' && (
                                <AlertCircle size={16} className="text-red-500 mx-auto" />
                              )}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                    {/* Summary footer */}
                    <tfoot>
                      <tr className="border-t-2 border-main bg-secondary/30">
                        <td className="px-4 py-3 sticky left-0 bg-secondary/30 z-10">
                          <p className="font-semibold text-sm text-main">Team Totals</p>
                        </td>
                        {DAY_LABELS.map((_, i) => {
                          const dayTotal = timesheetRows.reduce((s, r) => s + (r.dailyHours[i] || 0), 0);
                          return (
                            <td key={i} className="text-center px-3 py-3">
                              <p className="text-sm font-bold text-main">{dayTotal > 0 ? dayTotal.toFixed(1) : '-'}</p>
                            </td>
                          );
                        })}
                        <td className="text-center px-4 py-3">
                          <p className="text-lg font-bold text-accent">
                            {timesheetRows.reduce((s, r) => s + r.weekTotal, 0).toFixed(1)}
                          </p>
                        </td>
                        <td className="text-center px-4 py-3">
                          <p className="text-sm font-bold text-orange-500">
                            {timesheetRows.reduce((s, r) => s + r.otTotal, 0).toFixed(1)}h
                          </p>
                        </td>
                        <td colSpan={2} />
                      </tr>
                    </tfoot>
                  </table>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Overtime compliance summary */}
          {timesheetRows.some(r => r.otTotal > 0) && (
            <Card className="border-orange-500/20">
              <CardContent className="py-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <TrendingUp size={20} className="text-orange-500" />
                    <div>
                      <p className="font-medium text-main">Overtime Summary</p>
                      <p className="text-sm text-muted">
                        {timesheetRows.filter(r => r.otTotal > 0).length} of {timesheetRows.length} employees with overtime this week.
                        Daily OT threshold: 8h. Weekly OT threshold: 40h.
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-lg font-bold text-orange-500">
                      {timesheetRows.reduce((s, r) => s + r.otTotal, 0).toFixed(1)}h
                    </p>
                    <p className="text-xs text-muted">total overtime</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Bulk approval bar */}
          {timesheetRows.some(r => r.status === 'pending') && (
            <Card className="border-amber-500/30 bg-amber-500/5">
              <CardContent className="py-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <AlertCircle size={20} className="text-amber-500" />
                    <div>
                      <p className="font-medium text-main">
                        {timesheetRows.filter(r => r.status === 'pending').length} timesheets pending approval
                      </p>
                      <p className="text-sm text-muted">Review hours and job allocations before approving</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button variant="secondary" size="sm">
                      <Eye size={14} />
                      Review All
                    </Button>
                    <Button size="sm" onClick={async () => {
                      if (!confirm('Approve all pending timesheets?')) return;
                      const pending = weekEntries.filter(e => e.status === 'completed');
                      for (const entry of pending) { await approveEntry(entry.id); }
                    }}>
                      <Check size={14} />
                      Approve All Pending
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      )}

      {/* ================================================================= */}
      {/* TAB 3: JOB ALLOCATION                                             */}
      {/* ================================================================= */}
      {activeTab === 'allocation' && (
        <div className="space-y-6">
          {/* Summary cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <StatsCard
              title="Total Jobs This Week"
              value={jobAllocations.length.toString()}
              icon={<Briefcase size={20} className="text-blue-500" />}
              trend="neutral"
              changeLabel="active jobs"
            />
            <StatsCard
              title="Total Allocated Hours"
              value={`${jobAllocations.reduce((s, j) => s + j.totalHours, 0).toFixed(1)}h`}
              icon={<Timer size={20} className="text-accent" />}
              trend="neutral"
              changeLabel="across all jobs"
            />
            <StatsCard
              title="Total Labor Cost"
              value={formatCurrency(totalAllocatedCost)}
              icon={<DollarSign size={20} className="text-green-500" />}
              trend="neutral"
              changeLabel="this week"
            />
          </div>

          {/* Job allocation cards */}
          {jobAllocations.length === 0 ? (
            <Card>
              <CardContent className="py-16 text-center">
                <Briefcase className="w-10 h-10 text-muted mx-auto mb-3" />
                <p className="text-main font-medium mb-1">No job allocations this week</p>
                <p className="text-sm text-muted">Time entries linked to jobs will appear here</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-4">
              {jobAllocations.map((job) => {
                const isExpanded = expandedJob === job.jobId;
                return (
                  <Card key={job.jobId}>
                    <CardContent className="p-0">
                      {/* Job header row */}
                      <button
                        onClick={() => setExpandedJob(isExpanded ? null : job.jobId)}
                        className="w-full flex items-center justify-between px-6 py-4 hover:bg-surface-hover transition-colors text-left"
                      >
                        <div className="flex items-center gap-4">
                          <div className="p-2.5 rounded-lg bg-blue-500/10">
                            <Briefcase size={18} className="text-blue-500" />
                          </div>
                          <div>
                            <p className="font-semibold text-main">{job.jobName}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-8">
                          <div className="text-right">
                            <p className="text-sm text-muted">Hours</p>
                            <p className="text-lg font-bold text-main">{job.totalHours.toFixed(1)}h</p>
                          </div>
                          <div className="text-right">
                            <p className="text-sm text-muted">Labor Cost</p>
                            <p className="text-lg font-bold text-green-500">{formatCurrency(job.totalCost)}</p>
                          </div>
                          <div className="text-right">
                            <p className="text-sm text-muted">Crew</p>
                            <p className="text-lg font-bold text-main">{job.employees.length}</p>
                          </div>
                          <ChevronDown size={18} className={cn('text-muted transition-transform', isExpanded && 'rotate-180')} />
                        </div>
                      </button>

                      {/* Expanded employee breakdown */}
                      {isExpanded && (
                        <div className="border-t border-main">
                          <table className="w-full">
                            <thead>
                              <tr className="border-b border-main bg-secondary/30">
                                <th className="text-left px-6 py-2.5 text-xs font-semibold text-muted uppercase tracking-wider">Employee</th>
                                <th className="text-right px-4 py-2.5 text-xs font-semibold text-muted uppercase tracking-wider">Hours</th>
                                <th className="text-right px-4 py-2.5 text-xs font-semibold text-muted uppercase tracking-wider">Rate</th>
                                <th className="text-right px-6 py-2.5 text-xs font-semibold text-muted uppercase tracking-wider">Cost</th>
                              </tr>
                            </thead>
                            <tbody className="divide-y divide-main">
                              {job.employees.map((emp) => (
                                <tr key={emp.userId} className="hover:bg-surface-hover">
                                  <td className="px-6 py-3">
                                    <div className="flex items-center gap-3">
                                      <Avatar name={emp.userName} size="sm" />
                                      <p className="text-sm font-medium text-main">{emp.userName}</p>
                                    </div>
                                  </td>
                                  <td className="text-right px-4 py-3 text-sm font-semibold text-main">{emp.hours.toFixed(1)}h</td>
                                  <td className="text-right px-4 py-3 text-sm text-muted">{emp.rate > 0 ? `${formatCurrency(emp.rate)}/hr` : '-'}</td>
                                  <td className="text-right px-6 py-3 text-sm font-semibold text-green-500">{formatCurrency(emp.cost)}</td>
                                </tr>
                              ))}
                            </tbody>
                            <tfoot>
                              <tr className="border-t-2 border-main bg-secondary/30">
                                <td className="px-6 py-3 text-sm font-bold text-main">Total</td>
                                <td className="text-right px-4 py-3 text-sm font-bold text-main">{job.totalHours.toFixed(1)}h</td>
                                <td className="text-right px-4 py-3 text-sm text-muted">-</td>
                                <td className="text-right px-6 py-3 text-sm font-bold text-green-500">{formatCurrency(job.totalCost)}</td>
                              </tr>
                            </tfoot>
                          </table>
                        </div>
                      )}
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}

          {/* Cost flow indicator */}
          <Card className="border-green-500/20 bg-green-500/5">
            <CardContent className="py-4">
              <div className="flex items-center gap-4">
                <div className="flex items-center gap-2 text-sm text-main">
                  <Timer size={16} className="text-accent" />
                  <span className="font-medium">Allocated Hours</span>
                </div>
                <ArrowRight size={16} className="text-muted" />
                <div className="flex items-center gap-2 text-sm text-main">
                  <DollarSign size={16} className="text-green-500" />
                  <span className="font-medium">Employee Rate</span>
                </div>
                <ArrowRight size={16} className="text-muted" />
                <div className="flex items-center gap-2 text-sm text-main">
                  <BarChart3 size={16} className="text-blue-500" />
                  <span className="font-medium">Job Cost Report</span>
                </div>
                <div className="ml-auto text-xs text-muted">
                  Labor costs calculated at each employee's hourly rate
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* ================================================================= */}
      {/* TAB 4: ADJUSTMENTS                                                */}
      {/* ================================================================= */}
      {activeTab === 'adjustments' && (
        <div className="space-y-6">
          {/* Adjustments header */}
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted">
                All time clock adjustments are logged with original values, reasons, and approval chain.
                This audit trail ensures compliance and transparency.
              </p>
            </div>
            <Badge variant="info" dot>
              {adjustmentEntries.length} entries with notes
            </Badge>
          </div>

          {/* Entries with notes/adjustments */}
          {adjustmentEntries.length === 0 ? (
            <Card>
              <CardContent className="py-16 text-center">
                <History className="w-10 h-10 text-muted mx-auto mb-3" />
                <p className="text-main font-medium mb-1">No adjustments this period</p>
                <p className="text-sm text-muted">Time entry adjustments and notes will appear here</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-3">
              {adjustmentEntries.map((entry) => (
                <Card key={entry.id}>
                  <CardContent className="p-5">
                    <div className="flex items-start gap-4">
                      <div className={cn(
                        'p-2.5 rounded-lg flex-shrink-0 mt-0.5',
                        entry.status === 'approved' ? 'bg-green-500/10' : 'bg-amber-500/10'
                      )}>
                        {entry.status === 'approved' ? (
                          <Shield size={18} className="text-green-500" />
                        ) : (
                          <AlertCircle size={18} className="text-amber-500" />
                        )}
                      </div>

                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between mb-2">
                          <div className="flex items-center gap-3">
                            <p className="font-semibold text-main">{entry.userName}</p>
                            <span className="text-sm text-muted">{formatDate(entry.clockIn)}</span>
                            <Badge variant={entry.status === 'approved' ? 'success' : entry.status === 'rejected' ? 'error' : 'warning'} size="sm">
                              {entry.status === 'approved' ? 'Approved' : entry.status === 'rejected' ? 'Rejected' : 'Pending'}
                            </Badge>
                          </div>
                        </div>

                        {/* Time info */}
                        <div className="grid grid-cols-2 gap-4 mt-3">
                          <div className="p-3 rounded-lg bg-secondary/50">
                            <p className="text-xs font-medium text-muted uppercase tracking-wider mb-1.5">Time</p>
                            <div className="flex items-center gap-3">
                              <div>
                                <p className="text-xs text-muted">Clock In</p>
                                <p className="text-sm font-semibold text-main">{formatTimeLocale(entry.clockIn)}</p>
                              </div>
                              <ArrowRight size={14} className="text-muted" />
                              <div>
                                <p className="text-xs text-muted">Clock Out</p>
                                <p className="text-sm font-semibold text-main">{entry.clockOut ? formatTimeLocale(entry.clockOut) : 'Active'}</p>
                              </div>
                            </div>
                          </div>
                          <div className="p-3 rounded-lg bg-secondary/50">
                            <p className="text-xs font-medium text-muted uppercase tracking-wider mb-1.5">Duration</p>
                            <p className="text-sm font-semibold text-main">{formatHours(entry.totalMinutes)}</p>
                            {entry.breakMinutes > 0 && (
                              <p className="text-xs text-muted mt-1">{entry.breakMinutes}m break</p>
                            )}
                          </div>
                        </div>

                        {/* Notes */}
                        {entry.notes && (
                          <div className="mt-3 p-3 rounded-lg bg-secondary/50">
                            <p className="text-xs font-medium text-muted uppercase tracking-wider mb-1">Notes</p>
                            <p className="text-sm text-main">{entry.notes}</p>
                          </div>
                        )}

                        {/* Job info */}
                        {entry.jobTitle && (
                          <div className="flex items-center gap-2 mt-2 text-xs text-muted">
                            <Briefcase size={10} />
                            <span>{entry.jobTitle}</span>
                          </div>
                        )}
                      </div>

                      {/* Actions for pending */}
                      {entry.status === 'completed' && (
                        <div className="flex flex-col gap-2 flex-shrink-0">
                          <Button size="sm" variant="ghost" className="text-green-500 hover:bg-green-500/10" onClick={() => approveEntry(entry.id)}>
                            <Check size={14} />
                            Approve
                          </Button>
                          <Button size="sm" variant="ghost" className="text-red-500 hover:bg-red-500/10" onClick={() => rejectEntry(entry.id)}>
                            <X size={14} />
                            Reject
                          </Button>
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {/* Compliance note */}
          <Card className="border-blue-500/20 bg-blue-500/5">
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <Shield size={20} className="text-blue-500 flex-shrink-0" />
                <div>
                  <p className="font-medium text-main">Audit Compliance</p>
                  <p className="text-sm text-muted">
                    All time adjustments maintain a complete audit trail including original values, adjusted values,
                    reason for adjustment, who made the change, and who approved it. Records are retained per your
                    company's data retention policy and cannot be permanently deleted.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* ================================================================= */}
      {/* Bulk Actions for Pending (shown across applicable tabs)           */}
      {/* ================================================================= */}
      {activeTab === 'live' && summary.pendingApproval > 0 && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <AlertCircle size={20} className="text-amber-500" />
                <div>
                  <p className="font-medium text-main">{summary.pendingApproval} {t('timeClock.entriesPendingApproval')}</p>
                  <p className="text-sm text-muted">{t('timeClock.reviewAndApprove')}</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Button variant="secondary" size="sm" onClick={() => setActiveTab('timesheets')}>{t('timeClock.reviewAll')}</Button>
                <Button size="sm" onClick={async () => {
                  if (!confirm(t('timeClock.approveAllConfirm'))) return;
                  const pending = weekEntries.filter(e => e.status === 'completed');
                  for (const entry of pending) { await approveEntry(entry.id); }
                }}>
                  <Check size={16} />
                  {t('timeClock.approveAll')}
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
