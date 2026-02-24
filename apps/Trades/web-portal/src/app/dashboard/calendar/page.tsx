'use client';

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  ChevronLeft,
  ChevronRight,
  Plus,
  Calendar as CalendarIcon,
  Clock,
  MapPin,
  User,
  AlertTriangle,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarGroup } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { formatTime, cn } from '@/lib/utils';
import { useSchedule, useTeam } from '@/lib/hooks/use-jobs';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

export default function CalendarPage() {
  const router = useRouter();
  const { t } = useTranslation();
  const { schedule } = useSchedule();
  const { team } = useTeam();
  const [currentDate, setCurrentDate] = useState(new Date());
  const [view, setView] = useState<'month' | 'week' | 'day'>('month');
  const [selectedDate, setSelectedDate] = useState<Date | null>(new Date());
  const [showNewEvent, setShowNewEvent] = useState(false);

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  const goToPreviousMonth = () => {
    setCurrentDate(new Date(year, month - 1, 1));
  };

  const goToNextMonth = () => {
    setCurrentDate(new Date(year, month + 1, 1));
  };

  const goToToday = () => {
    setCurrentDate(new Date());
    setSelectedDate(new Date());
  };

  // Get calendar days
  const firstDayOfMonth = new Date(year, month, 1);
  const lastDayOfMonth = new Date(year, month + 1, 0);
  const startDate = new Date(firstDayOfMonth);
  startDate.setDate(startDate.getDate() - startDate.getDay());

  const days: Date[] = [];
  const current = new Date(startDate);
  for (let i = 0; i < 42; i++) {
    days.push(new Date(current));
    current.setDate(current.getDate() + 1);
  }

  // Get events for selected date
  const selectedDateEvents = selectedDate
    ? schedule.filter((event) => {
        const eventDate = new Date(event.start);
        return eventDate.toDateString() === selectedDate.toDateString();
      })
    : [];

  // Get events for a day (for calendar dots)
  const getEventsForDay = (date: Date) => {
    return schedule.filter((event) => {
      const eventDate = new Date(event.start);
      return eventDate.toDateString() === date.toDateString();
    });
  };

  // Navigation for week/day views
  const goToPreviousWeek = () => setCurrentDate(new Date(year, month, currentDate.getDate() - 7));
  const goToNextWeek = () => setCurrentDate(new Date(year, month, currentDate.getDate() + 7));
  const goToPreviousDay = () => setCurrentDate(new Date(year, month, currentDate.getDate() - 1));
  const goToNextDay = () => setCurrentDate(new Date(year, month, currentDate.getDate() + 1));

  // Week days for week view
  const weekStart = new Date(currentDate);
  weekStart.setDate(weekStart.getDate() - weekStart.getDay());
  const weekDays: Date[] = [];
  for (let i = 0; i < 7; i++) {
    weekDays.push(new Date(weekStart.getFullYear(), weekStart.getMonth(), weekStart.getDate() + i));
  }

  // Day view hours
  const dayHours = Array.from({ length: 14 }, (_, i) => i + 6); // 6 AM to 7 PM

  // Conflict detection — find overlapping events on same day with same assignees
  const conflicts = useMemo(() => {
    const result: Array<{ event1: string; event2: string; date: string }> = [];
    for (let i = 0; i < schedule.length; i++) {
      for (let j = i + 1; j < schedule.length; j++) {
        const a = schedule[i];
        const b = schedule[j];
        const aStart = new Date(a.start).getTime();
        const aEnd = new Date(a.end).getTime();
        const bStart = new Date(b.start).getTime();
        const bEnd = new Date(b.end).getTime();
        if (aStart < bEnd && bStart < aEnd) {
          // Check if any assignee overlaps
          const sharedAssignees = a.assignedTo.filter((id: string) => b.assignedTo.includes(id));
          if (sharedAssignees.length > 0) {
            result.push({ event1: a.title, event2: b.title, date: new Date(a.start).toLocaleDateString() });
          }
        }
      }
    }
    return result;
  }, [schedule]);

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('calendar.title')}</h1>
          <p className="text-muted mt-1">{t('calendar.manageDesc')}</p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="secondary" onClick={() => setShowNewEvent(true)}>
            <Plus size={16} />
            New Event
          </Button>
          <Button onClick={() => router.push('/dashboard/jobs/new')}>
            <Plus size={16} />
            {t('jobs.newJob')}
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Calendar */}
        <div className="lg:col-span-2">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-4">
              <div className="flex items-center gap-4">
                <Button variant="secondary" size="sm" onClick={goToToday}>
                  {t('scheduling.today')}
                </Button>
                <div className="flex items-center gap-1">
                  <button
                    onClick={goToPreviousMonth}
                    className="p-1.5 hover:bg-surface-hover rounded-lg transition-colors"
                  >
                    <ChevronLeft size={20} className="text-muted" />
                  </button>
                  <button
                    onClick={goToNextMonth}
                    className="p-1.5 hover:bg-surface-hover rounded-lg transition-colors"
                  >
                    <ChevronRight size={20} className="text-muted" />
                  </button>
                </div>
                <h2 className="text-lg font-semibold text-main">
                  {MONTHS[month]} {year}
                </h2>
              </div>
              <div className="flex items-center gap-1 p-1 bg-secondary rounded-lg">
                {(['day', 'week', 'month'] as const).map((v) => (
                  <button
                    key={v}
                    onClick={() => setView(v)}
                    className={cn(
                      'px-3 py-1.5 text-sm rounded-md transition-colors',
                      view === v
                        ? 'bg-surface text-main shadow-sm'
                        : 'text-muted hover:text-main'
                    )}
                  >
                    {v.charAt(0).toUpperCase() + v.slice(1)}
                  </button>
                ))}
              </div>
            </CardHeader>
            <CardContent>
              {/* Days of week header */}
              <div className="grid grid-cols-7 gap-1 mb-2">
                {DAYS.map((day) => (
                  <div
                    key={day}
                    className="text-center text-xs font-medium text-muted py-2"
                  >
                    {day}
                  </div>
                ))}
              </div>

              {/* Calendar grid */}
              <div className="grid grid-cols-7 gap-1">
                {days.map((day, index) => {
                  const isCurrentMonth = day.getMonth() === month;
                  const isToday = day.toDateString() === new Date().toDateString();
                  const isSelected = selectedDate && day.toDateString() === selectedDate.toDateString();
                  const dayEvents = getEventsForDay(day);

                  return (
                    <button
                      key={index}
                      onClick={() => setSelectedDate(day)}
                      className={cn(
                        'aspect-square p-1 rounded-lg transition-colors relative',
                        isCurrentMonth
                          ? 'text-main hover:bg-surface-hover'
                          : 'text-muted/50',
                        isToday && 'bg-accent-light',
                        isSelected && 'ring-2 ring-accent bg-accent-light'
                      )}
                    >
                      <span
                        className={cn(
                          'text-sm',
                          isToday && 'font-semibold text-accent'
                        )}
                      >
                        {day.getDate()}
                      </span>
                      {dayEvents.length > 0 && (
                        <div className="absolute bottom-1 left-1/2 -translate-x-1/2 flex items-center gap-0.5">
                          {dayEvents.slice(0, 3).map((event, i) => (
                            <span
                              key={i}
                              className="w-1.5 h-1.5 rounded-full"
                              style={{ backgroundColor: event.color }}
                            />
                          ))}
                        </div>
                      )}
                    </button>
                  );
                })}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Selected Day Events */}
        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>
                {selectedDate ? (
                  <span>
                    {formatDateLocale(selectedDate)}
                  </span>
                ) : (
                  t('calendar.selectDay')
                )}
              </CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              {selectedDateEvents.length === 0 ? (
                <div className="px-6 py-8 text-center text-muted">
                  <CalendarIcon size={40} className="mx-auto mb-2 opacity-50" />
                  <p>{t('calendar.noEvents')}</p>
                </div>
              ) : (
                <div className="divide-y divide-main">
                  {selectedDateEvents.map((event) => (
                    <div
                      key={event.id}
                      className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
                      onClick={() => event.jobId && router.push(`/dashboard/jobs/${event.jobId}`)}
                    >
                      <div className="flex items-start gap-3">
                        <div
                          className="w-1 h-full min-h-[50px] rounded-full flex-shrink-0"
                          style={{ backgroundColor: event.color }}
                        />
                        <div className="flex-1 min-w-0">
                          <h4 className="font-medium text-main">{event.title}</h4>
                          <div className="flex items-center gap-3 mt-2 text-sm text-muted">
                            <span className="flex items-center gap-1">
                              <Clock size={14} />
                              {formatTime(event.start)} - {formatTime(event.end)}
                            </span>
                          </div>
                          {event.assignedTo.length > 0 && (
                            <div className="mt-2">
                              <AvatarGroup
                                avatars={event.assignedTo.map((id) => {
                                  const member = team.find((t) => t.id === id);
                                  return { name: member?.name || 'Unknown' };
                                })}
                                size="sm"
                              />
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Quick Stats */}
          <Card>
            <CardHeader>
              <CardTitle>{t('calendar.thisWeek')}</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted">{t('calendar.scheduledJobs')}</span>
                  <span className="font-semibold text-main">
                    {schedule.filter((e) => e.type === 'job').length}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted">{t('calendar.appointments')}</span>
                  <span className="font-semibold text-main">
                    {schedule.filter((e) => e.type === 'appointment').length}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted">{t('calendar.teamMembers')}</span>
                  <span className="font-semibold text-main">
                    {team.filter((t) => t.isActive).length} active
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Legend */}
          <Card>
            <CardHeader>
              <CardTitle>{t('calendar.legend')}</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                <div className="flex items-center gap-2 text-sm">
                  <span className="w-3 h-3 rounded-full bg-blue-500" />
                  <span className="text-muted">{t('calendar.clientJobs')}</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="w-3 h-3 rounded-full bg-emerald-500" />
                  <span className="text-muted">{t('calendar.maintenanceJobs')}</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="w-3 h-3 rounded-full bg-amber-500" />
                  <span className="text-muted">Inspections</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="w-3 h-3 rounded-full bg-purple-500" />
                  <span className="text-muted">Appointments</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Conflict Alert */}
          {conflicts.length > 0 && (
            <Card className="border-amber-500/30">
              <CardContent className="p-4">
                <div className="flex items-start gap-2">
                  <AlertTriangle size={16} className="text-amber-500 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="text-sm font-medium text-main">Schedule Conflicts</p>
                    {conflicts.slice(0, 3).map((c, i) => (
                      <p key={i} className="text-xs text-muted mt-1">
                        {c.date}: &quot;{c.event1}&quot; overlaps with &quot;{c.event2}&quot;
                      </p>
                    ))}
                    {conflicts.length > 3 && (
                      <p className="text-xs text-muted mt-1">+{conflicts.length - 3} more conflicts</p>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* New Event Modal */}
      {showNewEvent && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={() => setShowNewEvent(false)}>
          <div className="bg-surface border border-main rounded-xl shadow-2xl w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold text-main">Create Event</h3>
              <button onClick={() => setShowNewEvent(false)} className="p-1 hover:bg-surface-hover rounded-lg">
                <X size={18} className="text-muted" />
              </button>
            </div>
            <p className="text-sm text-muted">
              To create a scheduled event, create or edit a job and set the scheduled date.
              All jobs with scheduled dates appear on this calendar automatically.
            </p>
            <div className="flex gap-2">
              <Button variant="secondary" onClick={() => setShowNewEvent(false)}>Cancel</Button>
              <Button onClick={() => { setShowNewEvent(false); router.push('/dashboard/jobs/new'); }}>
                <Plus size={16} />
                Create Job
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
