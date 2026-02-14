'use client';

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  Clock,
  ChevronLeft,
  ChevronRight,
  Download,
  Filter,
  Check,
  X,
  MapPin,
  Calendar,
  Users,
  Timer,
  Coffee,
  Play,
  AlertCircle,
  MoreHorizontal,
  CheckCircle2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatsCard } from '@/components/ui/stats-card';
import { Button } from '@/components/ui/button';
import { Avatar } from '@/components/ui/avatar';
import { DataTable } from '@/components/ui/data-table';
import { CommandPalette } from '@/components/command-palette';
import { cn, formatCurrency } from '@/lib/utils';
import { useTeam } from '@/lib/hooks/use-jobs';
import { getSupabase } from '@/lib/supabase';

// Time entry status
type TimeEntryStatus = 'active' | 'completed' | 'approved' | 'rejected';

// Time entry interface
interface TimeEntry {
  id: string;
  userId: string;
  userName: string;
  date: Date;
  clockIn: Date;
  clockOut?: Date;
  status: TimeEntryStatus;
  totalHours?: number;
  breakMinutes: number;
  location?: string;
  jobTitle?: string;
  notes?: string;
}

// Generate mock time entries for the past 2 weeks
const generateMockEntries = (): TimeEntry[] => {
  const entries: TimeEntry[] = [];
  const today = new Date();
  const users = [
    { id: 'team_1', name: 'Mike Johnson' },
    { id: 'team_2', name: 'Carlos Rivera' },
    { id: 'team_3', name: 'Sarah Williams' },
  ];

  users.forEach((user) => {
    for (let i = 0; i < 14; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);

      // Skip weekends
      if (date.getDay() === 0 || date.getDay() === 6) continue;

      const clockIn = new Date(date);
      clockIn.setHours(7 + Math.floor(Math.random() * 2), Math.floor(Math.random() * 30));

      const clockOut = new Date(date);
      clockOut.setHours(15 + Math.floor(Math.random() * 3), Math.floor(Math.random() * 60));

      const breakMins = 30 + Math.floor(Math.random() * 30);
      const totalHours = (clockOut.getTime() - clockIn.getTime()) / (1000 * 60 * 60) - breakMins / 60;

      const isToday = i === 0;
      const status: TimeEntryStatus = isToday
        ? user.id === 'team_3' ? 'completed' : 'active'
        : i < 3
        ? 'completed'
        : 'approved';

      entries.push({
        id: `time_${user.id}_${i}`,
        userId: user.id,
        userName: user.name,
        date,
        clockIn,
        clockOut: isToday && status === 'active' ? undefined : clockOut,
        status,
        totalHours: status === 'active' ? undefined : totalHours,
        breakMinutes: breakMins,
        location: ['1200 Chapel St, New Haven', '500 Main St, New Haven', 'Hartford Office'][Math.floor(Math.random() * 3)],
        jobTitle: ['Emergency Repair', 'Office Retrofit', 'Maintenance'][Math.floor(Math.random() * 3)],
      });
    }
  });

  return entries.sort((a, b) => b.date.getTime() - a.date.getTime());
};

const mockTimeEntries = generateMockEntries();

// Week navigation helper
const getWeekRange = (date: Date) => {
  const start = new Date(date);
  start.setDate(start.getDate() - start.getDay() + 1); // Monday
  const end = new Date(start);
  end.setDate(end.getDate() + 6); // Sunday
  return { start, end };
};

const formatWeekRange = (start: Date, end: Date) => {
  const options: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric' };
  return `${start.toLocaleDateString('en-US', options)} - ${end.toLocaleDateString('en-US', options)}, ${end.getFullYear()}`;
};

export default function TimeClockPage() {
  const router = useRouter();
  const { team } = useTeam();
  const [currentWeek, setCurrentWeek] = useState(new Date());
  const [selectedUser, setSelectedUser] = useState<string | null>(null);
  const [view, setView] = useState<'week' | 'list'>('week');

  const weekRange = getWeekRange(currentWeek);

  // Filter entries for current week
  const weekEntries = useMemo(() => {
    return mockTimeEntries.filter((entry) => {
      const entryDate = new Date(entry.date);
      const matchesWeek = entryDate >= weekRange.start && entryDate <= weekRange.end;
      const matchesUser = !selectedUser || entry.userId === selectedUser;
      return matchesWeek && matchesUser;
    });
  }, [currentWeek, selectedUser, weekRange.start, weekRange.end]);

  // Calculate stats
  const stats = useMemo(() => {
    const totalHours = weekEntries.reduce((sum, e) => sum + (e.totalHours || 0), 0);
    const activeNow = mockTimeEntries.filter((e) => e.status === 'active').length;
    const pendingApproval = mockTimeEntries.filter((e) => e.status === 'completed').length;
    const totalBreakHours = weekEntries.reduce((sum, e) => sum + e.breakMinutes / 60, 0);

    return {
      totalHours,
      activeNow,
      pendingApproval,
      totalBreakHours,
      avgHoursPerDay: weekEntries.length > 0 ? totalHours / Math.min(weekEntries.length, 5) : 0,
    };
  }, [weekEntries]);

  // Group entries by user for week view
  const entriesByUser = useMemo(() => {
    const grouped: Record<string, TimeEntry[]> = {};
    weekEntries.forEach((entry) => {
      if (!grouped[entry.userId]) {
        grouped[entry.userId] = [];
      }
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
  }, [weekRange.start]);

  const navigateWeek = (direction: 'prev' | 'next') => {
    const newDate = new Date(currentWeek);
    newDate.setDate(newDate.getDate() + (direction === 'next' ? 7 : -7));
    setCurrentWeek(newDate);
  };

  const handleApprove = async (entryId: string) => {
    const supabase = getSupabase();
    await supabase.from('time_entries').update({ status: 'approved', approved_at: new Date().toISOString() }).eq('id', entryId);
  };

  const handleReject = async (entryId: string) => {
    const supabase = getSupabase();
    await supabase.from('time_entries').update({ status: 'rejected' }).eq('id', entryId);
  };

  const handleExport = () => {
    const headers = ['Employee', 'Date', 'Clock In', 'Clock Out', 'Hours', 'Break (min)', 'Status', 'Job', 'Notes'];
    const rows = weekEntries.map(e => [
      e.userName, e.date.toLocaleDateString(), formatTime(e.clockIn),
      e.clockOut ? formatTime(e.clockOut) : '-', e.totalHours?.toFixed(2) || '-',
      e.breakMinutes.toString(), e.status, e.jobTitle || '-', e.notes || '',
    ]);
    const csv = [headers.join(','), ...rows.map(r => r.map(c => `"${c}"`).join(','))].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.download = `timesheet-${currentWeek.toISOString().slice(0, 10)}.csv`; a.click();
    URL.revokeObjectURL(url);
  };

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true });
  };

  const formatHours = (hours?: number) => {
    if (hours === undefined) return '-';
    const h = Math.floor(hours);
    const m = Math.round((hours - h) * 60);
    return `${h}h ${m}m`;
  };

  const getStatusColor = (status: TimeEntryStatus) => {
    switch (status) {
      case 'active':
        return 'bg-green-500/10 text-green-500';
      case 'completed':
        return 'bg-amber-500/10 text-amber-500';
      case 'approved':
        return 'bg-blue-500/10 text-blue-500';
      case 'rejected':
        return 'bg-red-500/10 text-red-500';
    }
  };

  const getStatusLabel = (status: TimeEntryStatus) => {
    switch (status) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
    }
  };

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Time Clock</h1>
          <p className="text-muted mt-1">Manage employee timesheets and approvals</p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="secondary" onClick={handleExport}>
            <Download size={16} />
            Export
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          title="On The Clock Now"
          value={stats.activeNow.toString()}
          icon={<Play size={20} className="text-green-500" />}
          trend="neutral"
          changeLabel="Active employees"
        />
        <StatsCard
          title="Total Hours This Week"
          value={formatHours(stats.totalHours)}
          icon={<Timer size={20} />}
          trend="neutral"
          changeLabel={`${Math.round(stats.totalHours / 8)} day equiv.`}
        />
        <StatsCard
          title="Pending Approval"
          value={stats.pendingApproval.toString()}
          icon={<AlertCircle size={20} className="text-amber-500" />}
          trend={stats.pendingApproval > 0 ? 'down' : 'neutral'}
          changeLabel="entries to review"
        />
        <StatsCard
          title="Break Time"
          value={formatHours(stats.totalBreakHours)}
          icon={<Coffee size={20} />}
          trend="neutral"
          changeLabel="total this week"
        />
      </div>

      {/* Week Navigation & Filters */}
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
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setCurrentWeek(new Date())}
            className="text-accent"
          >
            Today
          </Button>
        </div>

        <div className="flex items-center gap-3">
          {/* User Filter */}
          <select
            value={selectedUser || ''}
            onChange={(e) => setSelectedUser(e.target.value || null)}
            className="px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
          >
            <option value="">All Employees</option>
            {team.map((member) => (
              <option key={member.id} value={member.id}>
                {member.name}
              </option>
            ))}
          </select>

          {/* View Toggle */}
          <div className="flex rounded-lg border border-main overflow-hidden">
            <button
              onClick={() => setView('week')}
              className={cn(
                'px-3 py-2 text-sm font-medium transition-colors',
                view === 'week' ? 'bg-accent text-white' : 'bg-surface text-muted hover:bg-surface-hover'
              )}
            >
              Week
            </button>
            <button
              onClick={() => setView('list')}
              className={cn(
                'px-3 py-2 text-sm font-medium transition-colors',
                view === 'list' ? 'bg-accent text-white' : 'bg-surface text-muted hover:bg-surface-hover'
              )}
            >
              List
            </button>
          </div>
        </div>
      </div>

      {/* Week View */}
      {view === 'week' && (
        <Card>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-main">
                    <th className="text-left px-4 py-3 text-xs font-semibold text-muted uppercase tracking-wider w-48">
                      Employee
                    </th>
                    {weekDays.map((day, i) => {
                      const isToday = day.toDateString() === new Date().toDateString();
                      const isWeekend = day.getDay() === 0 || day.getDay() === 6;
                      return (
                        <th
                          key={i}
                          className={cn(
                            'text-center px-2 py-3 text-xs font-semibold uppercase tracking-wider min-w-[100px]',
                            isToday ? 'bg-accent/5 text-accent' : 'text-muted',
                            isWeekend && 'opacity-50'
                          )}
                        >
                          <div>{day.toLocaleDateString('en-US', { weekday: 'short' })}</div>
                          <div className="text-lg font-bold">{day.getDate()}</div>
                        </th>
                      );
                    })}
                    <th className="text-center px-4 py-3 text-xs font-semibold text-muted uppercase tracking-wider w-24">
                      Total
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-main">
                  {Object.entries(entriesByUser).map(([userId, entries]) => {
                    const user = team.find((m) => m.id === userId);
                    const weekTotal = entries.reduce((sum, e) => sum + (e.totalHours || 0), 0);

                    return (
                      <tr key={userId} className="hover:bg-surface-hover">
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-3">
                            <Avatar name={user?.name || 'Unknown'} size="sm" />
                            <div>
                              <p className="font-medium text-main">{user?.name}</p>
                              <p className="text-xs text-muted">{user?.role.replace('_', ' ')}</p>
                            </div>
                          </div>
                        </td>
                        {weekDays.map((day, i) => {
                          const dayEntry = entries.find(
                            (e) => new Date(e.date).toDateString() === day.toDateString()
                          );
                          const isWeekend = day.getDay() === 0 || day.getDay() === 6;

                          return (
                            <td
                              key={i}
                              className={cn(
                                'text-center px-2 py-3',
                                isWeekend && 'bg-secondary/50'
                              )}
                            >
                              {dayEntry ? (
                                <div className="space-y-1">
                                  <p className="text-sm font-semibold text-main">
                                    {formatHours(dayEntry.totalHours)}
                                  </p>
                                  <span
                                    className={cn(
                                      'inline-block px-1.5 py-0.5 text-[10px] font-medium rounded',
                                      getStatusColor(dayEntry.status)
                                    )}
                                  >
                                    {getStatusLabel(dayEntry.status)}
                                  </span>
                                </div>
                              ) : (
                                <span className="text-muted">-</span>
                              )}
                            </td>
                          );
                        })}
                        <td className="text-center px-4 py-3">
                          <p className="text-lg font-bold text-main">{formatHours(weekTotal)}</p>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {/* List View */}
      {view === 'list' && (
        <Card>
          <CardHeader>
            <CardTitle>Time Entries</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y divide-main">
              {weekEntries.map((entry) => (
                <div
                  key={entry.id}
                  className="flex items-center gap-4 px-6 py-4 hover:bg-surface-hover transition-colors"
                >
                  <Avatar name={entry.userName} size="md" />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <p className="font-medium text-main">{entry.userName}</p>
                      <span className={cn('px-2 py-0.5 text-xs font-medium rounded', getStatusColor(entry.status))}>
                        {getStatusLabel(entry.status)}
                      </span>
                    </div>
                    <p className="text-sm text-muted">
                      {entry.date.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' })}
                    </p>
                    {entry.jobTitle && (
                      <p className="text-sm text-muted flex items-center gap-1 mt-0.5">
                        <MapPin size={12} />
                        {entry.jobTitle} - {entry.location}
                      </p>
                    )}
                  </div>
                  <div className="text-right">
                    <p className="text-xs text-muted">
                      {formatTime(entry.clockIn)} - {entry.clockOut ? formatTime(entry.clockOut) : 'Active'}
                    </p>
                    <p className="text-lg font-bold text-main mt-1">{formatHours(entry.totalHours)}</p>
                    {entry.breakMinutes > 0 && (
                      <p className="text-xs text-muted flex items-center justify-end gap-1">
                        <Coffee size={10} />
                        {entry.breakMinutes}m break
                      </p>
                    )}
                  </div>
                  {entry.status === 'completed' && (
                    <div className="flex items-center gap-2">
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => handleApprove(entry.id)}
                        className="text-green-500 hover:bg-green-500/10"
                      >
                        <Check size={16} />
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => handleReject(entry.id)}
                        className="text-red-500 hover:bg-red-500/10"
                      >
                        <X size={16} />
                      </Button>
                    </div>
                  )}
                  {entry.status === 'approved' && (
                    <CheckCircle2 size={20} className="text-blue-500" />
                  )}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Bulk Actions for Pending */}
      {stats.pendingApproval > 0 && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <AlertCircle size={20} className="text-amber-500" />
                <div>
                  <p className="font-medium text-main">
                    {stats.pendingApproval} entries pending approval
                  </p>
                  <p className="text-sm text-muted">Review and approve employee time entries</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Button variant="secondary" size="sm" onClick={() => setView('list')}>
                  Review All
                </Button>
                <Button size="sm" onClick={async () => {
                  if (!confirm('Approve all pending time entries?')) return;
                  const pending = weekEntries.filter(e => e.status === 'completed');
                  for (const entry of pending) { await handleApprove(entry.id); }
                  window.location.reload();
                }}>
                  <Check size={16} />
                  Approve All
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
