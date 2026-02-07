'use client';

import { useMemo } from 'react';
import Link from 'next/link';
import { Calendar, MapPin, ChevronRight } from 'lucide-react';
import { useMyJobs } from '@/lib/hooks/use-jobs';
import { Card, CardContent } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/badge';
import { cn, formatTime } from '@/lib/utils';
import type { JobData } from '@/lib/hooks/mappers';
import { JOB_TYPE_COLORS } from '@/lib/hooks/mappers';
import type { JobType } from '@/lib/hooks/mappers';

function ScheduleSkeleton() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div className="skeleton h-7 w-32 rounded-lg" />
      <div className="space-y-6">
        {[1, 2, 3, 4, 5].map((i) => (
          <div key={i} className="space-y-2">
            <div className="skeleton h-5 w-40 rounded-lg" />
            <div className="skeleton h-20 w-full rounded-xl" />
          </div>
        ))}
      </div>
    </div>
  );
}

interface DaySchedule {
  date: Date;
  dateStr: string;
  label: string;
  isToday: boolean;
  jobs: JobData[];
}

export default function SchedulePage() {
  const { jobs, loading } = useMyJobs();

  const weekDays = useMemo(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStr = today.toISOString().split('T')[0];

    const days: DaySchedule[] = [];

    for (let i = 0; i < 7; i++) {
      const date = new Date(today);
      date.setDate(today.getDate() + i);
      const dateStr = date.toISOString().split('T')[0];

      const dayJobs = jobs.filter((j) => {
        if (!j.scheduledStart) return false;
        return j.scheduledStart.split('T')[0] === dateStr;
      });

      // Sort by scheduled time
      dayJobs.sort((a, b) => {
        const aTime = a.scheduledStart ? new Date(a.scheduledStart).getTime() : 0;
        const bTime = b.scheduledStart ? new Date(b.scheduledStart).getTime() : 0;
        return aTime - bTime;
      });

      const isToday = dateStr === todayStr;

      const label = isToday
        ? 'Today'
        : i === 1
        ? 'Tomorrow'
        : date.toLocaleDateString('en-US', { weekday: 'long' });

      days.push({ date, dateStr, label, isToday, jobs: dayJobs });
    }

    return days;
  }, [jobs]);

  const totalScheduled = weekDays.reduce((sum, day) => sum + day.jobs.length, 0);

  if (loading) return <ScheduleSkeleton />;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-semibold text-main">Schedule</h1>
        <p className="text-sm text-muted mt-0.5">
          {totalScheduled} job{totalScheduled !== 1 ? 's' : ''} in the next 7 days
        </p>
      </div>

      {/* Week View */}
      <div className="space-y-5">
        {weekDays.map((day) => (
          <div key={day.dateStr}>
            {/* Day Header */}
            <div className={cn(
              'flex items-center gap-3 mb-2 px-1',
            )}>
              <div className={cn(
                'flex items-center justify-center w-10 h-10 rounded-xl text-sm font-bold flex-shrink-0',
                day.isToday
                  ? 'bg-accent text-white'
                  : 'bg-secondary text-main'
              )}>
                {day.date.getDate()}
              </div>
              <div>
                <p className={cn(
                  'text-sm font-semibold',
                  day.isToday ? 'text-accent' : 'text-main'
                )}>
                  {day.label}
                </p>
                <p className="text-xs text-muted">
                  {day.date.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
                </p>
              </div>
              {day.jobs.length > 0 && (
                <span className={cn(
                  'ml-auto text-xs font-medium px-2 py-0.5 rounded-full',
                  day.isToday
                    ? 'bg-accent/10 text-accent'
                    : 'bg-secondary text-muted'
                )}>
                  {day.jobs.length} job{day.jobs.length !== 1 ? 's' : ''}
                </span>
              )}
            </div>

            {/* Day's Jobs */}
            {day.jobs.length === 0 ? (
              <div className={cn(
                'ml-[52px] py-3 text-sm text-muted border-l-2 pl-4',
                day.isToday ? 'border-accent/20' : 'border-light'
              )}>
                No jobs scheduled
              </div>
            ) : (
              <div className="ml-[52px] space-y-2">
                {day.jobs.map((job) => (
                  <Link key={job.id} href={`/dashboard/jobs/${job.id}`}>
                    <Card className={cn(
                      'hover:border-accent/30 transition-colors overflow-hidden',
                      day.isToday && 'border-accent/20'
                    )}>
                      <CardContent className="py-3 relative">
                        {job.jobType !== 'standard' && (
                          <div className={cn('absolute left-0 top-0 bottom-0 w-1', JOB_TYPE_COLORS[job.jobType as JobType].dot)} />
                        )}
                        <div className={cn('flex items-start gap-3', job.jobType !== 'standard' && 'ml-2')}>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-start justify-between gap-2">
                              <p className="text-sm font-medium text-main truncate">{job.title}</p>
                              <StatusBadge status={job.status} className="flex-shrink-0" />
                            </div>

                            <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1.5">
                              {job.scheduledStart && (
                                <span className="text-xs font-medium text-secondary flex items-center gap-1">
                                  <Calendar size={11} className="flex-shrink-0" />
                                  {formatTime(job.scheduledStart)}
                                  {job.scheduledEnd && (
                                    <span className="text-muted"> - {formatTime(job.scheduledEnd)}</span>
                                  )}
                                </span>
                              )}
                              {job.address && (
                                <span className="text-xs text-muted flex items-center gap-1">
                                  <MapPin size={11} className="flex-shrink-0" />
                                  <span className="truncate max-w-[180px]">
                                    {job.address}{job.city ? `, ${job.city}` : ''}
                                  </span>
                                </span>
                              )}
                            </div>
                          </div>
                          <ChevronRight size={14} className="text-muted flex-shrink-0 mt-0.5" />
                        </div>
                      </CardContent>
                    </Card>
                  </Link>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Unscheduled Jobs */}
      {(() => {
        const unscheduled = jobs.filter(
          (j) => !j.scheduledStart && j.status !== 'completed' && j.status !== 'cancelled' && j.status !== 'invoiced'
        );
        if (unscheduled.length === 0) return null;

        return (
          <div>
            <div className="flex items-center gap-2 mb-3 px-1">
              <Calendar size={16} className="text-muted" />
              <p className="text-sm font-semibold text-muted">Unscheduled ({unscheduled.length})</p>
            </div>
            <div className="space-y-2">
              {unscheduled.map((job) => (
                <Link key={job.id} href={`/dashboard/jobs/${job.id}`}>
                  <Card className="hover:border-accent/30 transition-colors">
                    <CardContent className="py-3">
                      <div className="flex items-center gap-3">
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-main truncate">{job.title}</p>
                          <p className="text-xs text-muted">{job.customerName}</p>
                        </div>
                        <StatusBadge status={job.status} />
                        <ChevronRight size={14} className="text-muted flex-shrink-0" />
                      </div>
                    </CardContent>
                  </Card>
                </Link>
              ))}
            </div>
          </div>
        );
      })()}
    </div>
  );
}
