'use client';

import { useState, useMemo, useEffect } from 'react';
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
  Users,
  Pause,
  DollarSign,
  FileText,
  Shield,
  ArrowRight,
  Briefcase,
  History,
  Pencil,
  Eye,
  CircleDot,
  Signal,
  Wifi,
  WifiOff,
  Hash,
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
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type TimeEntryStatus = 'active' | 'completed' | 'approved' | 'rejected';
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
  customerName: string;
  employees: { userId: string; userName: string; hours: number; rate: number; cost: number }[];
  totalHours: number;
  totalCost: number;
}

interface AdjustmentRecord {
  id: string;
  entryId: string;
  employeeName: string;
  date: string;
  originalClockIn: string;
  originalClockOut: string;
  adjustedClockIn: string;
  adjustedClockOut: string;
  reason: string;
  adjustedBy: string;
  adjustedAt: string;
  approved: boolean;
  approvedBy: string | null;
}

interface LiveEmployee {
  userId: string;
  userName: string;
  role: string;
  clockedInAt: string;
  elapsedMinutes: number;
  jobTitle: string | null;
  gpsVerified: boolean;
  gpsLocation: string | null;
  onBreak: boolean;
  breakStartedAt: string | null;
  breakMinutes: number;
}

// ---------------------------------------------------------------------------
// Demo data generators
// ---------------------------------------------------------------------------

const DEMO_LIVE_EMPLOYEES: LiveEmployee[] = [
  { userId: 'u1', userName: 'Marcus Rivera', role: 'Lead Technician', clockedInAt: new Date(Date.now() - 4.5 * 3600000).toISOString(), elapsedMinutes: 270, jobTitle: 'HVAC Install - 1420 Oak Ave', gpsVerified: true, gpsLocation: '1420 Oak Ave, Suite B', onBreak: false, breakStartedAt: null, breakMinutes: 30 },
  { userId: 'u2', userName: 'Sarah Chen', role: 'Apprentice', clockedInAt: new Date(Date.now() - 3.2 * 3600000).toISOString(), elapsedMinutes: 192, jobTitle: 'Duct Repair - 890 Pine St', gpsVerified: true, gpsLocation: '890 Pine St', onBreak: true, breakStartedAt: new Date(Date.now() - 0.15 * 3600000).toISOString(), breakMinutes: 0 },
  { userId: 'u3', userName: 'James Wilson', role: 'Technician', clockedInAt: new Date(Date.now() - 5.8 * 3600000).toISOString(), elapsedMinutes: 348, jobTitle: 'Commercial AC - 2200 Market Blvd', gpsVerified: true, gpsLocation: '2200 Market Blvd', onBreak: false, breakStartedAt: null, breakMinutes: 45 },
  { userId: 'u4', userName: 'Ana Rodriguez', role: 'Technician', clockedInAt: new Date(Date.now() - 2.1 * 3600000).toISOString(), elapsedMinutes: 126, jobTitle: null, gpsVerified: false, gpsLocation: null, onBreak: false, breakStartedAt: null, breakMinutes: 0 },
  { userId: 'u5', userName: 'David Park', role: 'Senior Technician', clockedInAt: new Date(Date.now() - 6.5 * 3600000).toISOString(), elapsedMinutes: 390, jobTitle: 'Furnace Replace - 3311 Cedar Ln', gpsVerified: true, gpsLocation: '3311 Cedar Ln', onBreak: false, breakStartedAt: null, breakMinutes: 30 },
];

const DEMO_TIMESHEET_ROWS: TimesheetRow[] = [
  { userId: 'u1', userName: 'Marcus Rivera', role: 'Lead Technician', dailyHours: [8.5, 9.0, 8.0, 8.5, 8.0, 4.0, null], dailyJobs: ['HVAC Install', 'HVAC Install', 'Duct Repair', 'HVAC Install', 'Commercial AC', 'Furnace Replace', null], dailyOt: [0.5, 1.0, 0, 0.5, 0, 0, null], weekTotal: 46.0, otTotal: 6.0, status: 'pending' },
  { userId: 'u2', userName: 'Sarah Chen', role: 'Apprentice', dailyHours: [8.0, 8.0, 8.0, 7.5, 8.0, null, null], dailyJobs: ['Duct Repair', 'HVAC Install', 'Duct Repair', 'Duct Repair', 'Commercial AC', null, null], dailyOt: [0, 0, 0, 0, 0, null, null], weekTotal: 39.5, otTotal: 0, status: 'approved' },
  { userId: 'u3', userName: 'James Wilson', role: 'Technician', dailyHours: [8.0, 10.0, 9.5, 8.0, 8.5, 5.0, null], dailyJobs: ['Commercial AC', 'Commercial AC', 'Commercial AC', 'Furnace Replace', 'Commercial AC', 'Furnace Replace', null], dailyOt: [0, 2.0, 1.5, 0, 0.5, 0, null], weekTotal: 49.0, otTotal: 9.0, status: 'pending' },
  { userId: 'u4', userName: 'Ana Rodriguez', role: 'Technician', dailyHours: [8.0, 8.0, 8.0, 8.0, 7.0, null, null], dailyJobs: ['Residential AC', 'Residential AC', 'Heat Pump', 'Heat Pump', 'Residential AC', null, null], dailyOt: [0, 0, 0, 0, 0, null, null], weekTotal: 39.0, otTotal: 0, status: 'approved' },
  { userId: 'u5', userName: 'David Park', role: 'Senior Technician', dailyHours: [9.0, 9.5, 8.0, 9.0, 8.5, 6.0, null], dailyJobs: ['Furnace Replace', 'Furnace Replace', 'Commercial AC', 'Furnace Replace', 'HVAC Install', 'Furnace Replace', null], dailyOt: [1.0, 1.5, 0, 1.0, 0.5, 0, null], weekTotal: 50.0, otTotal: 10.0, status: 'rejected' },
];

const DEMO_JOB_ALLOCATIONS: JobAllocationRow[] = [
  {
    jobId: 'j1', jobName: 'HVAC Install - 1420 Oak Ave', customerName: 'Thompson Residence',
    employees: [
      { userId: 'u1', userName: 'Marcus Rivera', hours: 26.0, rate: 45.00, cost: 1170.00 },
      { userId: 'u2', userName: 'Sarah Chen', hours: 8.0, rate: 22.00, cost: 176.00 },
      { userId: 'u5', userName: 'David Park', hours: 8.5, rate: 55.00, cost: 467.50 },
    ],
    totalHours: 42.5, totalCost: 1813.50,
  },
  {
    jobId: 'j2', jobName: 'Commercial AC - 2200 Market Blvd', customerName: 'Market Square LLC',
    employees: [
      { userId: 'u3', userName: 'James Wilson', hours: 36.0, rate: 38.00, cost: 1368.00 },
      { userId: 'u1', userName: 'Marcus Rivera', hours: 8.0, rate: 45.00, cost: 360.00 },
      { userId: 'u2', userName: 'Sarah Chen', hours: 8.0, rate: 22.00, cost: 176.00 },
      { userId: 'u5', userName: 'David Park', hours: 8.0, rate: 55.00, cost: 440.00 },
    ],
    totalHours: 60.0, totalCost: 2344.00,
  },
  {
    jobId: 'j3', jobName: 'Duct Repair - 890 Pine St', customerName: 'Garcia Family',
    employees: [
      { userId: 'u2', userName: 'Sarah Chen', hours: 23.5, rate: 22.00, cost: 517.00 },
      { userId: 'u1', userName: 'Marcus Rivera', hours: 8.0, rate: 45.00, cost: 360.00 },
    ],
    totalHours: 31.5, totalCost: 877.00,
  },
  {
    jobId: 'j4', jobName: 'Furnace Replace - 3311 Cedar Ln', customerName: 'Williams Estate',
    employees: [
      { userId: 'u5', userName: 'David Park', hours: 33.5, rate: 55.00, cost: 1842.50 },
      { userId: 'u3', userName: 'James Wilson', hours: 13.0, rate: 38.00, cost: 494.00 },
    ],
    totalHours: 46.5, totalCost: 2336.50,
  },
  {
    jobId: 'j5', jobName: 'Residential AC - 450 Elm Dr', customerName: 'Patterson Home',
    employees: [
      { userId: 'u4', userName: 'Ana Rodriguez', hours: 31.0, rate: 35.00, cost: 1085.00 },
    ],
    totalHours: 31.0, totalCost: 1085.00,
  },
  {
    jobId: 'j6', jobName: 'Heat Pump - 780 Birch Way', customerName: 'Nguyen Residence',
    employees: [
      { userId: 'u4', userName: 'Ana Rodriguez', hours: 16.0, rate: 35.00, cost: 560.00 },
    ],
    totalHours: 16.0, totalCost: 560.00,
  },
];

const DEMO_ADJUSTMENTS: AdjustmentRecord[] = [
  { id: 'adj1', entryId: 'te1', employeeName: 'Marcus Rivera', date: '2026-02-23', originalClockIn: '07:00 AM', originalClockOut: '04:30 PM', adjustedClockIn: '06:45 AM', adjustedClockOut: '04:30 PM', reason: 'Employee arrived early to prep job site, forgot to clock in on time', adjustedBy: 'Mike Torres (Manager)', adjustedAt: '2026-02-23T17:30:00Z', approved: true, approvedBy: 'Mike Torres' },
  { id: 'adj2', entryId: 'te2', employeeName: 'James Wilson', date: '2026-02-22', originalClockIn: '07:00 AM', originalClockOut: '06:00 PM', adjustedClockIn: '07:00 AM', adjustedClockOut: '05:30 PM', reason: 'System did not register clock-out. Employee confirmed 5:30 PM departure.', adjustedBy: 'Mike Torres (Manager)', adjustedAt: '2026-02-22T18:15:00Z', approved: true, approvedBy: 'Mike Torres' },
  { id: 'adj3', entryId: 'te3', employeeName: 'Sarah Chen', date: '2026-02-21', originalClockIn: '08:00 AM', originalClockOut: '04:00 PM', adjustedClockIn: '08:00 AM', adjustedClockOut: '04:30 PM', reason: 'Employee stayed 30 min extra for cleanup. Manager witnessed.', adjustedBy: 'Mike Torres (Manager)', adjustedAt: '2026-02-21T17:00:00Z', approved: true, approvedBy: 'Mike Torres' },
  { id: 'adj4', entryId: 'te4', employeeName: 'David Park', date: '2026-02-20', originalClockIn: '06:30 AM', originalClockOut: '05:00 PM', adjustedClockIn: '06:30 AM', adjustedClockOut: '04:00 PM', reason: 'Employee left early due to medical appointment. Time adjusted per policy.', adjustedBy: 'Mike Torres (Manager)', adjustedAt: '2026-02-20T16:30:00Z', approved: false, approvedBy: null },
  { id: 'adj5', entryId: 'te5', employeeName: 'Ana Rodriguez', date: '2026-02-19', originalClockIn: '07:30 AM', originalClockOut: '03:30 PM', adjustedClockIn: '07:00 AM', adjustedClockOut: '03:30 PM', reason: 'GPS verification delayed clock-in by 30 min. Employee was on site at 7:00 AM confirmed by lead.', adjustedBy: 'Mike Torres (Manager)', adjustedAt: '2026-02-19T16:00:00Z', approved: true, approvedBy: 'Mike Torres' },
  { id: 'adj6', entryId: 'te6', employeeName: 'James Wilson', date: '2026-02-18', originalClockIn: '07:00 AM', originalClockOut: '07:00 PM', adjustedClockIn: '07:00 AM', adjustedClockOut: '06:30 PM', reason: 'Break time not deducted. 30 min lunch added per company policy.', adjustedBy: 'Mike Torres (Manager)', adjustedAt: '2026-02-18T19:15:00Z', approved: true, approvedBy: 'Mike Torres' },
];

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
    const interval = setInterval(() => setNow(Date.now()), 30000); // every 30s
    return () => clearInterval(interval);
  }, [activeTab]);

  // Filter by selected user
  const weekEntries = useMemo(() => {
    if (!selectedUser) return allEntries;
    return allEntries.filter(e => e.userId === selectedUser);
  }, [allEntries, selectedUser]);

  // Group entries by user for week view
  const entriesByUser = useMemo(() => {
    const grouped: Record<string, TimeEntry[]> = {};
    weekEntries.forEach((entry) => {
      if (!grouped[entry.userId]) grouped[entry.userId] = [];
      grouped[entry.userId].push(entry);
    });
    return grouped;
  }, [weekEntries]);

  // Get days of the week
  const weekDays = useMemo(() => {
    const days: Date[] = [];
    for (let i = 0; i < 7; i++) {
      const day = new Date(weekRange.start);
      day.setDate(day.getDate() + i);
      days.push(day);
    }
    return days;
  }, [weekRange.start.toISOString()]);

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
      formatTime(e.clockIn),
      e.clockOut ? formatTime(e.clockOut) : '-',
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

  const formatTime = (isoStr: string) => {
    return formatTimeLocale(isoStr);
  };

  const formatHours = (minutes?: number | null) => {
    if (minutes === undefined || minutes === null) return '-';
    const h = Math.floor(minutes / 60);
    const m = Math.round(minutes % 60);
    return `${h}h ${m}m`;
  };

  const formatDecimalHours = (hours: number | null) => {
    if (hours === null || hours === undefined) return '-';
    return `${hours.toFixed(1)}h`;
  };

  const formatElapsed = (minutes: number) => {
    const h = Math.floor(minutes / 60);
    const m = Math.round(minutes % 60);
    if (h === 0) return `${m}m`;
    return `${h}h ${m}m`;
  };

  const getStatusColor = (status: TimeEntryStatus) => {
    switch (status) {
      case 'active': return 'bg-green-500/10 text-green-500';
      case 'completed': return 'bg-amber-500/10 text-amber-500';
      case 'approved': return 'bg-blue-500/10 text-blue-500';
      case 'rejected': return 'bg-red-500/10 text-red-500';
    }
  };

  const getStatusLabel = (status: TimeEntryStatus) => {
    switch (status) {
      case 'active': return 'Active';
      case 'completed': return 'Pending';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
    }
  };

  const getTimesheetBadgeVariant = (status: string): 'warning' | 'success' | 'error' => {
    if (status === 'approved') return 'success';
    if (status === 'rejected') return 'error';
    return 'warning';
  };

  // Aggregate stats for all tabs
  const liveCount = DEMO_LIVE_EMPLOYEES.length;
  const onBreakCount = DEMO_LIVE_EMPLOYEES.filter(e => e.onBreak).length;
  const totalAllocatedCost = DEMO_JOB_ALLOCATIONS.reduce((s, j) => s + j.totalCost, 0);

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
          value={summary.activeNow > 0 ? summary.activeNow.toString() : liveCount.toString()}
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
                <span className="text-sm font-medium text-main">{liveCount} employees clocked in</span>
              </div>
            </div>
            <p className="text-xs text-muted">Auto-refreshes every 30 seconds</p>
          </div>

          {/* Live employee cards */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {DEMO_LIVE_EMPLOYEES.map((emp) => {
              const elapsed = Math.round((now - new Date(emp.clockedInAt).getTime()) / 60000);
              return (
                <Card key={emp.userId} className={cn('relative overflow-hidden', emp.onBreak && 'border-amber-500/30')}>
                  {emp.onBreak && (
                    <div className="absolute top-0 left-0 right-0 h-1 bg-amber-500" />
                  )}
                  <CardContent className="p-5">
                    <div className="flex items-start gap-4">
                      <Avatar name={emp.userName} size="lg" showStatus isOnline={!emp.onBreak} />
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between mb-1">
                          <div>
                            <p className="font-semibold text-main">{emp.userName}</p>
                            <p className="text-xs text-muted">{emp.role}</p>
                          </div>
                          <div className="text-right">
                            <p className="text-2xl font-bold text-main tabular-nums">{formatElapsed(elapsed)}</p>
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

                        {/* Bottom row: GPS + Break + Clock times */}
                        <div className="flex items-center justify-between mt-3">
                          <div className="flex items-center gap-3">
                            {/* GPS Badge */}
                            {emp.gpsVerified ? (
                              <div className="flex items-center gap-1.5 px-2 py-1 rounded-md bg-green-500/10 text-green-500">
                                <MapPin size={12} />
                                <span className="text-xs font-medium">GPS Verified</span>
                              </div>
                            ) : (
                              <div className="flex items-center gap-1.5 px-2 py-1 rounded-md bg-red-500/10 text-red-500">
                                <WifiOff size={12} />
                                <span className="text-xs font-medium">No GPS</span>
                              </div>
                            )}

                            {/* Break indicator */}
                            {emp.onBreak ? (
                              <Badge variant="warning" dot>On Break</Badge>
                            ) : emp.breakMinutes > 0 ? (
                              <div className="flex items-center gap-1 text-xs text-muted">
                                <Coffee size={12} />
                                <span>{emp.breakMinutes}m break taken</span>
                              </div>
                            ) : null}
                          </div>

                          <div className="text-xs text-muted">
                            In: {formatTime(emp.clockedInAt)}
                          </div>
                        </div>

                        {/* GPS location detail */}
                        {emp.gpsLocation && (
                          <p className="text-xs text-muted mt-2 flex items-center gap-1">
                            <MapPin size={10} className="flex-shrink-0" />
                            {emp.gpsLocation}
                          </p>
                        )}
                      </div>
                    </div>

                    {/* Action buttons */}
                    <div className="flex items-center gap-2 mt-4 pt-4 border-t border-main">
                      {emp.onBreak ? (
                        <Button variant="outline" size="sm" className="flex-1">
                          <Play size={14} />
                          End Break
                        </Button>
                      ) : (
                        <Button variant="outline" size="sm" className="flex-1">
                          <Pause size={14} />
                          Start Break
                        </Button>
                      )}
                      <Button variant="danger" size="sm" className="flex-1">
                        <Clock size={14} />
                        Clock Out
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>

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
                    {DEMO_TIMESHEET_ROWS.map((row) => {
                      const hasOvertime = row.otTotal > 0;
                      return (
                        <tr key={row.userId} className="hover:bg-surface-hover group">
                          <td className="px-4 py-3 sticky left-0 bg-surface group-hover:bg-surface-hover z-10">
                            <div className="flex items-center gap-3">
                              <Avatar name={row.userName} size="sm" />
                              <div>
                                <p className="font-medium text-main text-sm">{row.userName}</p>
                                <p className="text-xs text-muted">{row.role}</p>
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
                                {hours !== null ? (
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
                                <button className="p-1.5 rounded-md hover:bg-green-500/10 text-green-500 transition-colors" title="Approve">
                                  <Check size={14} />
                                </button>
                                <button className="p-1.5 rounded-md hover:bg-red-500/10 text-red-500 transition-colors" title="Reject">
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
                        const dayTotal = DEMO_TIMESHEET_ROWS.reduce((s, r) => s + (r.dailyHours[i] || 0), 0);
                        return (
                          <td key={i} className="text-center px-3 py-3">
                            <p className="text-sm font-bold text-main">{dayTotal > 0 ? dayTotal.toFixed(1) : '-'}</p>
                          </td>
                        );
                      })}
                      <td className="text-center px-4 py-3">
                        <p className="text-lg font-bold text-accent">
                          {DEMO_TIMESHEET_ROWS.reduce((s, r) => s + r.weekTotal, 0).toFixed(1)}
                        </p>
                      </td>
                      <td className="text-center px-4 py-3">
                        <p className="text-sm font-bold text-orange-500">
                          {DEMO_TIMESHEET_ROWS.reduce((s, r) => s + r.otTotal, 0).toFixed(1)}h
                        </p>
                      </td>
                      <td colSpan={2} />
                    </tr>
                  </tfoot>
                </table>
              </div>
            </CardContent>
          </Card>

          {/* Overtime compliance summary */}
          <Card className="border-orange-500/20">
            <CardContent className="py-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <TrendingUp size={20} className="text-orange-500" />
                  <div>
                    <p className="font-medium text-main">Overtime Summary</p>
                    <p className="text-sm text-muted">
                      {DEMO_TIMESHEET_ROWS.filter(r => r.otTotal > 0).length} of {DEMO_TIMESHEET_ROWS.length} employees with overtime this week.
                      Daily OT threshold: 8h. Weekly OT threshold: 40h.
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-lg font-bold text-orange-500">
                    {DEMO_TIMESHEET_ROWS.reduce((s, r) => s + r.otTotal, 0).toFixed(1)}h
                  </p>
                  <p className="text-xs text-muted">total overtime</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Bulk approval bar */}
          {DEMO_TIMESHEET_ROWS.some(r => r.status === 'pending') && (
            <Card className="border-amber-500/30 bg-amber-500/5">
              <CardContent className="py-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <AlertCircle size={20} className="text-amber-500" />
                    <div>
                      <p className="font-medium text-main">
                        {DEMO_TIMESHEET_ROWS.filter(r => r.status === 'pending').length} timesheets pending approval
                      </p>
                      <p className="text-sm text-muted">Review hours and job allocations before approving</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button variant="secondary" size="sm">
                      <Eye size={14} />
                      Review All
                    </Button>
                    <Button size="sm">
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
              value={DEMO_JOB_ALLOCATIONS.length.toString()}
              icon={<Briefcase size={20} className="text-blue-500" />}
              trend="neutral"
              changeLabel="active jobs"
            />
            <StatsCard
              title="Total Allocated Hours"
              value={`${DEMO_JOB_ALLOCATIONS.reduce((s, j) => s + j.totalHours, 0).toFixed(1)}h`}
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
          <div className="space-y-4">
            {DEMO_JOB_ALLOCATIONS.map((job) => {
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
                          <p className="text-sm text-muted">{job.customerName}</p>
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
                                <td className="text-right px-4 py-3 text-sm text-muted">{formatCurrency(emp.rate)}/hr</td>
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
              {DEMO_ADJUSTMENTS.length} adjustments this period
            </Badge>
          </div>

          {/* Adjustments list */}
          <div className="space-y-3">
            {DEMO_ADJUSTMENTS.map((adj) => (
              <Card key={adj.id}>
                <CardContent className="p-5">
                  <div className="flex items-start gap-4">
                    {/* Status icon */}
                    <div className={cn(
                      'p-2.5 rounded-lg flex-shrink-0 mt-0.5',
                      adj.approved ? 'bg-green-500/10' : 'bg-amber-500/10'
                    )}>
                      {adj.approved ? (
                        <Shield size={18} className="text-green-500" />
                      ) : (
                        <AlertCircle size={18} className="text-amber-500" />
                      )}
                    </div>

                    <div className="flex-1 min-w-0">
                      {/* Top line: employee + date + status */}
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center gap-3">
                          <p className="font-semibold text-main">{adj.employeeName}</p>
                          <span className="text-sm text-muted">{adj.date}</span>
                          {adj.approved ? (
                            <Badge variant="success" size="sm">Approved</Badge>
                          ) : (
                            <Badge variant="warning" size="sm">Pending Approval</Badge>
                          )}
                        </div>
                      </div>

                      {/* Time comparison */}
                      <div className="grid grid-cols-2 gap-4 mt-3">
                        <div className="p-3 rounded-lg bg-red-500/5 border border-red-500/10">
                          <p className="text-xs font-medium text-red-500 uppercase tracking-wider mb-1.5">Original Time</p>
                          <div className="flex items-center gap-3">
                            <div>
                              <p className="text-xs text-muted">Clock In</p>
                              <p className="text-sm font-semibold text-main">{adj.originalClockIn}</p>
                            </div>
                            <ArrowRight size={14} className="text-muted" />
                            <div>
                              <p className="text-xs text-muted">Clock Out</p>
                              <p className="text-sm font-semibold text-main">{adj.originalClockOut}</p>
                            </div>
                          </div>
                        </div>
                        <div className="p-3 rounded-lg bg-green-500/5 border border-green-500/10">
                          <p className="text-xs font-medium text-green-500 uppercase tracking-wider mb-1.5">Adjusted Time</p>
                          <div className="flex items-center gap-3">
                            <div>
                              <p className="text-xs text-muted">Clock In</p>
                              <p className="text-sm font-semibold text-main">{adj.adjustedClockIn}</p>
                            </div>
                            <ArrowRight size={14} className="text-muted" />
                            <div>
                              <p className="text-xs text-muted">Clock Out</p>
                              <p className="text-sm font-semibold text-main">{adj.adjustedClockOut}</p>
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* Reason */}
                      <div className="mt-3 p-3 rounded-lg bg-secondary/50">
                        <p className="text-xs font-medium text-muted uppercase tracking-wider mb-1">Reason</p>
                        <p className="text-sm text-main">{adj.reason}</p>
                      </div>

                      {/* Audit trail */}
                      <div className="flex items-center gap-4 mt-3 text-xs text-muted">
                        <div className="flex items-center gap-1">
                          <Pencil size={10} />
                          <span>Adjusted by: <span className="font-medium text-main">{adj.adjustedBy}</span></span>
                        </div>
                        <span>|</span>
                        <div className="flex items-center gap-1">
                          <Calendar size={10} />
                          <span>{new Date(adj.adjustedAt).toLocaleString()}</span>
                        </div>
                        {adj.approved && adj.approvedBy && (
                          <>
                            <span>|</span>
                            <div className="flex items-center gap-1">
                              <UserCheck size={10} />
                              <span>Approved by: <span className="font-medium text-main">{adj.approvedBy}</span></span>
                            </div>
                          </>
                        )}
                      </div>
                    </div>

                    {/* Actions for pending */}
                    {!adj.approved && (
                      <div className="flex flex-col gap-2 flex-shrink-0">
                        <Button size="sm" variant="ghost" className="text-green-500 hover:bg-green-500/10">
                          <Check size={14} />
                          Approve
                        </Button>
                        <Button size="sm" variant="ghost" className="text-red-500 hover:bg-red-500/10">
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
