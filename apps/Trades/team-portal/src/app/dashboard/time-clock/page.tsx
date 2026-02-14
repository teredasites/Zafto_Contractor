'use client';

import { Suspense, useState, useEffect } from 'react';
import { useSearchParams } from 'next/navigation';
import {
  Play, Square, Pause, Clock, Briefcase, ChevronDown, MapPin,
} from 'lucide-react';
import { useTimeClock } from '@/lib/hooks/use-time-clock';
import { useMyJobs } from '@/lib/hooks/use-jobs';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { cn, formatTime } from '@/lib/utils';

function LiveTimer({ since }: { since: string }) {
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

  return <span className="font-mono text-4xl sm:text-5xl font-bold text-main">{elapsed}</span>;
}

function TimeClockSkeleton() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div className="skeleton h-7 w-32 rounded-lg" />
      <div className="skeleton h-64 w-full rounded-xl" />
      <div className="skeleton h-48 w-full rounded-xl" />
    </div>
  );
}

function TimeClockContent() {
  const searchParams = useSearchParams();
  const preselectedJobId = searchParams.get('jobId');

  const { entries, activeEntry, todayHours, clockIn, clockOut, loading: clockLoading } = useTimeClock();
  const { jobs, loading: jobsLoading } = useMyJobs();
  const [selectedJobId, setSelectedJobId] = useState<string>(preselectedJobId || '');
  const [actionLoading, setActionLoading] = useState(false);
  const [showJobPicker, setShowJobPicker] = useState(false);

  const loading = clockLoading || jobsLoading;

  // Set preselected job once jobs load
  useEffect(() => {
    if (preselectedJobId && jobs.length > 0 && !selectedJobId) {
      setSelectedJobId(preselectedJobId);
    }
  }, [preselectedJobId, jobs, selectedJobId]);

  const activeJobs = jobs.filter(
    (j) => j.status !== 'completed' && j.status !== 'cancelled' && j.status !== 'invoiced'
  );

  const selectedJob = jobs.find((j) => j.id === selectedJobId);

  const handleClockIn = async () => {
    setActionLoading(true);
    await clockIn(selectedJobId || undefined);
    setActionLoading(false);
  };

  const handleClockOut = async () => {
    setActionLoading(true);
    await clockOut();
    setActionLoading(false);
  };

  if (loading) return <TimeClockSkeleton />;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-semibold text-main">Time Clock</h1>
        <p className="text-sm text-muted mt-0.5">Track your work hours</p>
      </div>

      {/* Main Clock Card */}
      <Card>
        <CardContent className="py-8">
          <div className="text-center space-y-6">
            {/* Timer Display */}
            {activeEntry ? (
              <>
                <div className="space-y-2">
                  <div className="inline-flex items-center gap-2 px-3 py-1 bg-emerald-100 dark:bg-emerald-900/30 rounded-full">
                    <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                    <span className="text-xs font-medium text-emerald-700 dark:text-emerald-300">Active</span>
                  </div>
                  <div>
                    <LiveTimer since={activeEntry.clockIn} />
                  </div>
                  {activeEntry.jobTitle && (
                    <p className="text-sm text-secondary">
                      <Briefcase size={14} className="inline mr-1.5 align-text-bottom" />
                      {activeEntry.jobTitle}
                    </p>
                  )}
                  <p className="text-xs text-muted">
                    Started at {formatTime(activeEntry.clockIn)}
                  </p>
                  {activeEntry.locationPings.length > 0 && (
                    <div className="inline-flex items-center gap-1 px-2 py-0.5 bg-green-100 dark:bg-green-900/30 rounded-full">
                      <MapPin size={12} className="text-green-600 dark:text-green-400" />
                      <span className="text-xs text-green-700 dark:text-green-300">GPS Verified</span>
                    </div>
                  )}
                </div>

                {/* Clock Out Button */}
                <Button
                  variant="danger"
                  size="lg"
                  onClick={handleClockOut}
                  loading={actionLoading}
                  className="w-full max-w-xs mx-auto h-16 text-base font-semibold"
                >
                  <Square size={20} />
                  Clock Out
                </Button>
              </>
            ) : (
              <>
                <div className="space-y-3">
                  <div className="w-16 h-16 rounded-full bg-secondary flex items-center justify-center mx-auto">
                    <Clock size={28} className="text-muted" />
                  </div>
                  <p className="text-sm text-muted">Not currently clocked in</p>
                </div>

                {/* Job Selector */}
                <div className="max-w-xs mx-auto">
                  <div className="relative">
                    <button
                      onClick={() => setShowJobPicker(!showJobPicker)}
                      className={cn(
                        'w-full flex items-center justify-between gap-2 px-4 py-3 bg-secondary border border-main rounded-lg text-sm min-h-[48px]',
                        'hover:bg-surface-hover transition-colors text-left'
                      )}
                    >
                      <span className={selectedJob ? 'text-main' : 'text-muted'}>
                        {selectedJob ? selectedJob.title : 'Select a job (optional)'}
                      </span>
                      <ChevronDown size={16} className={cn('text-muted transition-transform', showJobPicker && 'rotate-180')} />
                    </button>

                    {showJobPicker && (
                      <div className="absolute z-10 top-full mt-1 w-full bg-surface border border-main rounded-lg shadow-lg max-h-60 overflow-y-auto">
                        <button
                          onClick={() => { setSelectedJobId(''); setShowJobPicker(false); }}
                          className={cn(
                            'w-full px-4 py-3 text-left text-sm hover:bg-surface-hover transition-colors',
                            !selectedJobId ? 'text-accent font-medium' : 'text-muted'
                          )}
                        >
                          No specific job
                        </button>
                        {activeJobs.map((job) => (
                          <button
                            key={job.id}
                            onClick={() => { setSelectedJobId(job.id); setShowJobPicker(false); }}
                            className={cn(
                              'w-full px-4 py-3 text-left text-sm hover:bg-surface-hover transition-colors border-t border-light',
                              selectedJobId === job.id ? 'text-accent font-medium' : 'text-main'
                            )}
                          >
                            <p className="truncate">{job.title}</p>
                            <p className="text-xs text-muted truncate">{job.customerName}</p>
                          </button>
                        ))}
                        {activeJobs.length === 0 && (
                          <div className="px-4 py-3 text-sm text-muted">No active jobs</div>
                        )}
                      </div>
                    )}
                  </div>
                </div>

                {/* Clock In Button */}
                <Button
                  size="lg"
                  onClick={handleClockIn}
                  loading={actionLoading}
                  className="w-full max-w-xs mx-auto h-16 text-base font-semibold"
                >
                  <Play size={20} />
                  Clock In
                </Button>
              </>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Today's Summary */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Today&apos;s Entries</CardTitle>
            <span className="text-sm font-semibold text-accent">{todayHours.toFixed(1)} hrs</span>
          </div>
        </CardHeader>
        <CardContent>
          {entries.length === 0 ? (
            <p className="text-sm text-muted text-center py-4">No entries for today</p>
          ) : (
            <div className="space-y-3">
              {entries.map((entry) => {
                const isActive = !entry.clockOut;
                return (
                  <div
                    key={entry.id}
                    className={cn(
                      'flex items-center gap-3 p-3 rounded-lg',
                      isActive ? 'bg-emerald-50 dark:bg-emerald-900/10 border border-emerald-200 dark:border-emerald-800' : 'bg-secondary'
                    )}
                  >
                    <div className={cn(
                      'w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0',
                      isActive
                        ? 'bg-emerald-100 dark:bg-emerald-900/30'
                        : 'bg-surface'
                    )}>
                      <Clock size={16} className={isActive ? 'text-accent' : 'text-muted'} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-medium text-main">
                          {formatTime(entry.clockIn)}
                          {entry.clockOut ? ` - ${formatTime(entry.clockOut)}` : ''}
                        </p>
                        {isActive && (
                          <Badge variant="success">Active</Badge>
                        )}
                      </div>
                      {entry.jobTitle && (
                        <p className="text-xs text-muted truncate">{entry.jobTitle}</p>
                      )}
                    </div>
                    {entry.locationPings.length > 0 && (
                      <MapPin size={14} className="text-green-500 flex-shrink-0" />
                    )}
                    <div className="text-right flex-shrink-0">
                      <p className="text-sm font-medium text-main">{entry.totalHours.toFixed(1)} hrs</p>
                      {entry.breakMinutes > 0 && (
                        <p className="text-xs text-muted">{entry.breakMinutes}m break</p>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

export default function TimeClockPage() {
  return (
    <Suspense fallback={<TimeClockSkeleton />}>
      <TimeClockContent />
    </Suspense>
  );
}
