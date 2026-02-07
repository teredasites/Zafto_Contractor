'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  Clock, Briefcase, Play, Square, ChevronRight, Calendar,
  AlertCircle, MapPin, Timer,
} from 'lucide-react';
import { useAuth } from '@/components/auth-provider';
import { useMyJobs } from '@/lib/hooks/use-jobs';
import { useTimeClock } from '@/lib/hooks/use-time-clock';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge } from '@/components/ui/badge';
import { cn, formatDate, formatTime } from '@/lib/utils';
import { JOB_TYPE_COLORS } from '@/lib/hooks/mappers';
import type { JobType } from '@/lib/hooks/mappers';

function ElapsedTimer({ since }: { since: string }) {
  const [elapsed, setElapsed] = useState('00:00:00');

  useEffect(() => {
    const start = new Date(since).getTime();
    const tick = () => {
      const diff = Math.max(0, Date.now() - start);
      const h = Math.floor(diff / 3600000);
      const m = Math.floor((diff % 3600000) / 60000);
      const s = Math.floor((diff % 60000) / 1000);
      setElapsed(
        `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
      );
    };
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, [since]);

  return <span className="font-mono text-2xl font-bold text-accent">{elapsed}</span>;
}

function DashboardSkeleton() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div className="space-y-2">
        <div className="skeleton h-7 w-48 rounded-lg" />
        <div className="skeleton h-4 w-32 rounded-lg" />
      </div>
      <div className="skeleton h-32 w-full rounded-xl" />
      <div className="space-y-3">
        <div className="skeleton h-5 w-28 rounded-lg" />
        <div className="skeleton h-20 w-full rounded-xl" />
        <div className="skeleton h-20 w-full rounded-xl" />
      </div>
      <div className="grid grid-cols-3 gap-4">
        <div className="skeleton h-24 rounded-xl" />
        <div className="skeleton h-24 rounded-xl" />
        <div className="skeleton h-24 rounded-xl" />
      </div>
    </div>
  );
}

export default function DashboardPage() {
  const { profile, loading: authLoading } = useAuth();
  const { jobs, loading: jobsLoading } = useMyJobs();
  const { activeEntry, todayHours, clockIn, clockOut, loading: clockLoading } = useTimeClock();
  const [clockActionLoading, setClockActionLoading] = useState(false);

  const loading = authLoading || jobsLoading || clockLoading;

  const today = new Date();
  const todayStr = today.toISOString().split('T')[0];

  const todaysJobs = jobs.filter((j) => {
    if (!j.scheduledStart) return false;
    return j.scheduledStart.split('T')[0] === todayStr;
  });

  const activeJobs = jobs.filter(
    (j) => j.status === 'in_progress' || j.status === 'en_route' || j.status === 'dispatched'
  );

  const pendingItems = jobs.filter(
    (j) => j.status === 'scheduled' || j.status === 'dispatched'
  ).length;

  const greeting = (() => {
    const hour = today.getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  })();

  const handleClockIn = async () => {
    setClockActionLoading(true);
    await clockIn();
    setClockActionLoading(false);
  };

  const handleClockOut = async () => {
    setClockActionLoading(true);
    await clockOut();
    setClockActionLoading(false);
  };

  if (loading) return <DashboardSkeleton />;

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Greeting */}
      <div>
        <h1 className="text-xl font-semibold text-main">
          {greeting}, {profile?.displayName?.split(' ')[0] || 'Team Member'}
        </h1>
        <p className="text-sm text-muted mt-0.5">
          {today.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })}
        </p>
      </div>

      {/* Time Clock Status */}
      <Card>
        <CardContent className="py-5">
          {activeEntry ? (
            <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
              <div className="flex items-center gap-3 flex-1 min-w-0">
                <div className="w-10 h-10 rounded-full bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center flex-shrink-0">
                  <Timer size={20} className="text-accent" />
                </div>
                <div className="min-w-0">
                  <p className="text-sm text-muted">Clocked in</p>
                  <ElapsedTimer since={activeEntry.clockIn} />
                  {activeEntry.jobTitle && (
                    <p className="text-sm text-secondary mt-0.5 truncate">{activeEntry.jobTitle}</p>
                  )}
                </div>
              </div>
              <Button
                variant="danger"
                size="lg"
                onClick={handleClockOut}
                loading={clockActionLoading}
                className="w-full sm:w-auto min-h-[48px]"
              >
                <Square size={16} />
                Clock Out
              </Button>
            </div>
          ) : (
            <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
              <div className="flex items-center gap-3 flex-1">
                <div className="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center flex-shrink-0">
                  <Clock size={20} className="text-muted" />
                </div>
                <div>
                  <p className="text-sm text-muted">Not clocked in</p>
                  <p className="text-sm font-medium text-main">Start your day</p>
                </div>
              </div>
              <Button
                size="lg"
                onClick={handleClockIn}
                loading={clockActionLoading}
                className="w-full sm:w-auto min-h-[48px]"
              >
                <Play size={16} />
                Clock In
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Today's Jobs */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-[15px] font-semibold text-main">Today&apos;s Jobs</h2>
          <Link href="/dashboard/jobs" className="text-sm text-accent hover:text-accent-hover transition-colors flex items-center gap-1">
            View all <ChevronRight size={14} />
          </Link>
        </div>

        {todaysJobs.length === 0 && activeJobs.length === 0 ? (
          <Card>
            <CardContent className="py-8 text-center">
              <Calendar size={32} className="text-muted mx-auto mb-2" />
              <p className="text-sm text-muted">No jobs scheduled for today</p>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-2">
            {(todaysJobs.length > 0 ? todaysJobs : activeJobs).slice(0, 5).map((job) => (
              <Link key={job.id} href={`/dashboard/jobs/${job.id}`}>
                <Card className="hover:border-accent/30 transition-colors overflow-hidden">
                  <CardContent className="py-3.5 relative">
                    {job.jobType !== 'standard' && (
                      <div className={cn('absolute left-0 top-0 bottom-0 w-1', JOB_TYPE_COLORS[job.jobType as JobType].dot)} />
                    )}
                    <div className={cn('flex items-start justify-between gap-3', job.jobType !== 'standard' && 'ml-2')}>
                      <div className="min-w-0 flex-1">
                        <p className="text-sm font-medium text-main truncate">{job.title}</p>
                        <p className="text-sm text-muted truncate">{job.customerName}</p>
                        {job.address && (
                          <p className="text-xs text-muted flex items-center gap-1 mt-1">
                            <MapPin size={12} className="flex-shrink-0" />
                            <span className="truncate">{job.address}{job.city ? `, ${job.city}` : ''}</span>
                          </p>
                        )}
                        {job.scheduledStart && (
                          <p className="text-xs text-muted mt-1">
                            {formatTime(job.scheduledStart)}
                          </p>
                        )}
                      </div>
                      <StatusBadge status={job.status} />
                    </div>
                  </CardContent>
                </Card>
              </Link>
            ))}
          </div>
        )}
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-3 gap-3">
        <Card>
          <CardContent className="py-4 text-center">
            <Briefcase size={20} className="text-accent mx-auto mb-1.5" />
            <p className="text-xl font-bold text-main">{todaysJobs.length || activeJobs.length}</p>
            <p className="text-xs text-muted">Jobs Today</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4 text-center">
            <Clock size={20} className="text-accent mx-auto mb-1.5" />
            <p className="text-xl font-bold text-main">{todayHours.toFixed(1)}</p>
            <p className="text-xs text-muted">Hours Today</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4 text-center">
            <AlertCircle size={20} className="text-amber-500 mx-auto mb-1.5" />
            <p className="text-xl font-bold text-main">{pendingItems}</p>
            <p className="text-xs text-muted">Pending</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
