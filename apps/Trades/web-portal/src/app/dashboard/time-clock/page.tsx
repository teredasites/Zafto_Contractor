'use client';

import { useState, useMemo } from 'react';
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
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatsCard } from '@/components/ui/stats-card';
import { Button } from '@/components/ui/button';
import { Avatar } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import { useTeam } from '@/lib/hooks/use-jobs';
import { useTimeClock, type TimeEntry } from '@/lib/hooks/use-time-clock';
import { useTranslation } from '@/lib/translations';

type TimeEntryStatus = 'active' | 'completed' | 'approved' | 'rejected';

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
  const { t, formatDate } = useTranslation();
  const { team } = useTeam();
  const [currentWeek, setCurrentWeek] = useState(new Date());
  const [selectedUser, setSelectedUser] = useState<string | null>(null);
  const [view, setView] = useState<'week' | 'list'>('week');

  const weekRange = getWeekRange(currentWeek);
  const { entries: allEntries, summary, loading, error, approveEntry, rejectEntry } = useTimeClock(weekRange.start);

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
  }, [weekRange.start]);

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
    return new Date(isoStr).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true });
  };

  const formatHours = (minutes?: number | null) => {
    if (minutes === undefined || minutes === null) return '-';
    const h = Math.floor(minutes / 60);
    const m = Math.round(minutes % 60);
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

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          title={t('timeClock.onTheClockNow')}
          value={summary.activeNow.toString()}
          icon={<Play size={20} className="text-green-500" />}
          trend="neutral"
          changeLabel={t('timeClock.activeEmployees')}
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
          <Button variant="ghost" size="sm" onClick={() => setCurrentWeek(new Date())} className="text-accent">
            {t('scheduling.today')}
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

          <div className="flex rounded-lg border border-main overflow-hidden">
            <button onClick={() => setView('week')}
              className={cn('px-3 py-2 text-sm font-medium transition-colors', view === 'week' ? 'bg-accent text-white' : 'bg-surface text-muted hover:bg-surface-hover')}>
              {t('scheduling.week')}
            </button>
            <button onClick={() => setView('list')}
              className={cn('px-3 py-2 text-sm font-medium transition-colors', view === 'list' ? 'bg-accent text-white' : 'bg-surface text-muted hover:bg-surface-hover')}>
              {t('scheduling.list')}
            </button>
          </div>
        </div>
      </div>

      {/* Empty state */}
      {weekEntries.length === 0 && (
        <Card>
          <CardContent className="py-16 text-center">
            <Clock className="h-12 w-12 text-muted mx-auto mb-3 opacity-40" />
            <p className="text-muted">{t('timeClock.noEntries')}</p>
            <p className="text-xs text-muted mt-1">{t('timeClock.noEntriesDesc')}</p>
          </CardContent>
        </Card>
      )}

      {/* Week View */}
      {view === 'week' && weekEntries.length > 0 && (
        <Card>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-main">
                    <th className="text-left px-4 py-3 text-xs font-semibold text-muted uppercase tracking-wider w-48">Employee</th>
                    {weekDays.map((day, i) => {
                      const isToday = day.toDateString() === new Date().toDateString();
                      const isWeekend = day.getDay() === 0 || day.getDay() === 6;
                      return (
                        <th key={i} className={cn('text-center px-2 py-3 text-xs font-semibold uppercase tracking-wider min-w-[100px]', isToday ? 'bg-accent/5 text-accent' : 'text-muted', isWeekend && 'opacity-50')}>
                          <div>{day.toLocaleDateString('en-US', { weekday: 'short' })}</div>
                          <div className="text-lg font-bold">{day.getDate()}</div>
                        </th>
                      );
                    })}
                    <th className="text-center px-4 py-3 text-xs font-semibold text-muted uppercase tracking-wider w-24">Total</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-main">
                  {Object.entries(entriesByUser).map(([userId, entries]) => {
                    const weekTotal = entries.reduce((sum, e) => sum + (e.totalMinutes || 0), 0);

                    return (
                      <tr key={userId} className="hover:bg-surface-hover">
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-3">
                            <Avatar name={entries[0]?.userName || 'Unknown'} size="sm" />
                            <div>
                              <p className="font-medium text-main">{entries[0]?.userName}</p>
                            </div>
                          </div>
                        </td>
                        {weekDays.map((day, i) => {
                          const dayEntry = entries.find(e => new Date(e.clockIn).toDateString() === day.toDateString());
                          const isWeekend = day.getDay() === 0 || day.getDay() === 6;

                          return (
                            <td key={i} className={cn('text-center px-2 py-3', isWeekend && 'bg-secondary/50')}>
                              {dayEntry ? (
                                <div className="space-y-1">
                                  <p className="text-sm font-semibold text-main">{formatHours(dayEntry.totalMinutes)}</p>
                                  <span className={cn('inline-block px-1.5 py-0.5 text-[10px] font-medium rounded', getStatusColor(dayEntry.status))}>
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
      {view === 'list' && weekEntries.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Time Entries</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y divide-main">
              {weekEntries.map((entry) => (
                <div key={entry.id} className="flex items-center gap-4 px-6 py-4 hover:bg-surface-hover transition-colors">
                  <Avatar name={entry.userName} size="md" />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <p className="font-medium text-main">{entry.userName}</p>
                      <span className={cn('px-2 py-0.5 text-xs font-medium rounded', getStatusColor(entry.status))}>
                        {getStatusLabel(entry.status)}
                      </span>
                    </div>
                    <p className="text-sm text-muted">
                      {formatDate(entry.clockIn)}
                    </p>
                    {entry.jobTitle && (
                      <p className="text-sm text-muted flex items-center gap-1 mt-0.5">
                        <MapPin size={12} />
                        {entry.jobTitle}
                      </p>
                    )}
                  </div>
                  <div className="text-right">
                    <p className="text-xs text-muted">
                      {formatTime(entry.clockIn)} - {entry.clockOut ? formatTime(entry.clockOut) : 'Active'}
                    </p>
                    <p className="text-lg font-bold text-main mt-1">{formatHours(entry.totalMinutes)}</p>
                    {entry.breakMinutes > 0 && (
                      <p className="text-xs text-muted flex items-center justify-end gap-1">
                        <Coffee size={10} />
                        {entry.breakMinutes}m break
                      </p>
                    )}
                  </div>
                  {entry.status === 'completed' && (
                    <div className="flex items-center gap-2">
                      <Button size="sm" variant="ghost" onClick={() => approveEntry(entry.id)} className="text-green-500 hover:bg-green-500/10">
                        <Check size={16} />
                      </Button>
                      <Button size="sm" variant="ghost" onClick={() => rejectEntry(entry.id)} className="text-red-500 hover:bg-red-500/10">
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
      {summary.pendingApproval > 0 && (
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
                <Button variant="secondary" size="sm" onClick={() => setView('list')}>{t('timeClock.reviewAll')}</Button>
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
