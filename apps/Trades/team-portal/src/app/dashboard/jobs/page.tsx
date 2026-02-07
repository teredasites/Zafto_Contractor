'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Briefcase, MapPin, Calendar, Search, ChevronRight } from 'lucide-react';
import { useMyJobs } from '@/lib/hooks/use-jobs';
import { Card, CardContent } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/badge';
import { cn, formatDate, formatTime } from '@/lib/utils';
import { JOB_TYPE_LABELS, JOB_TYPE_COLORS } from '@/lib/hooks/mappers';
import type { JobType } from '@/lib/hooks/mappers';

type FilterTab = 'all' | 'active' | 'scheduled' | 'completed';

const FILTER_TABS: { key: FilterTab; label: string }[] = [
  { key: 'all', label: 'All' },
  { key: 'active', label: 'Active' },
  { key: 'scheduled', label: 'Scheduled' },
  { key: 'completed', label: 'Completed' },
];

const ACTIVE_STATUSES = new Set(['in_progress', 'en_route', 'dispatched']);
const SCHEDULED_STATUSES = new Set(['scheduled', 'draft']);
const COMPLETED_STATUSES = new Set(['completed', 'invoiced']);

function JobsListSkeleton() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div className="skeleton h-7 w-32 rounded-lg" />
      <div className="flex gap-2">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="skeleton h-9 w-24 rounded-lg" />
        ))}
      </div>
      <div className="space-y-3">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="skeleton h-24 w-full rounded-xl" />
        ))}
      </div>
    </div>
  );
}

export default function JobsListPage() {
  const { jobs, loading } = useMyJobs();
  const [filter, setFilter] = useState<FilterTab>('all');
  const [search, setSearch] = useState('');

  const filteredJobs = jobs.filter((job) => {
    // Filter by tab
    if (filter === 'active' && !ACTIVE_STATUSES.has(job.status)) return false;
    if (filter === 'scheduled' && !SCHEDULED_STATUSES.has(job.status)) return false;
    if (filter === 'completed' && !COMPLETED_STATUSES.has(job.status)) return false;

    // Filter by search
    if (search) {
      const q = search.toLowerCase();
      return (
        job.title.toLowerCase().includes(q) ||
        job.customerName.toLowerCase().includes(q) ||
        job.address.toLowerCase().includes(q)
      );
    }

    return true;
  });

  const counts: Record<FilterTab, number> = {
    all: jobs.length,
    active: jobs.filter((j) => ACTIVE_STATUSES.has(j.status)).length,
    scheduled: jobs.filter((j) => SCHEDULED_STATUSES.has(j.status)).length,
    completed: jobs.filter((j) => COMPLETED_STATUSES.has(j.status)).length,
  };

  if (loading) return <JobsListSkeleton />;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-semibold text-main">My Jobs</h1>
        <p className="text-sm text-muted mt-0.5">
          {jobs.length} job{jobs.length !== 1 ? 's' : ''} assigned to you
        </p>
      </div>

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
        <input
          type="text"
          placeholder="Search jobs..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className={cn(
            'w-full pl-10 pr-4 py-3 bg-secondary border border-main rounded-lg text-main',
            'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
            'text-[15px]'
          )}
        />
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2 overflow-x-auto pb-1 -mx-1 px-1">
        {FILTER_TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setFilter(tab.key)}
            className={cn(
              'flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors min-h-[40px]',
              filter === tab.key
                ? 'bg-accent text-white'
                : 'bg-secondary text-muted hover:text-main hover:bg-surface-hover border border-main'
            )}
          >
            {tab.label}
            <span className={cn(
              'text-xs px-1.5 py-0.5 rounded-full',
              filter === tab.key
                ? 'bg-white/20 text-white'
                : 'bg-surface text-muted'
            )}>
              {counts[tab.key]}
            </span>
          </button>
        ))}
      </div>

      {/* Jobs List */}
      {filteredJobs.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <Briefcase size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">No jobs found</p>
            <p className="text-sm text-muted mt-1">
              {search
                ? 'Try adjusting your search'
                : filter !== 'all'
                ? 'No jobs match this filter'
                : 'You have no assigned jobs yet'}
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {filteredJobs.map((job) => (
            <Link key={job.id} href={`/dashboard/jobs/${job.id}`}>
              <Card className="hover:border-accent/30 transition-colors">
                <CardContent className="py-3.5">
                  <div className="flex items-start gap-3">
                    <div className="min-w-0 flex-1">
                      <div className="flex items-start justify-between gap-2">
                        <p className="text-sm font-medium text-main truncate">{job.title}</p>
                        <div className="flex items-center gap-1.5 flex-shrink-0">
                          {job.jobType !== 'standard' && (
                            <span className={cn('inline-flex items-center gap-1 px-1.5 py-0.5 text-[10px] font-medium rounded-full', JOB_TYPE_COLORS[job.jobType as JobType].bg, JOB_TYPE_COLORS[job.jobType as JobType].text)}>
                              {JOB_TYPE_LABELS[job.jobType as JobType]}
                            </span>
                          )}
                          <StatusBadge status={job.status} />
                        </div>
                      </div>
                      <p className="text-sm text-secondary mt-0.5">{job.customerName}</p>

                      <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-2">
                        {job.address && (
                          <span className="text-xs text-muted flex items-center gap-1">
                            <MapPin size={12} className="flex-shrink-0" />
                            <span className="truncate max-w-[200px]">
                              {job.address}{job.city ? `, ${job.city}` : ''}
                            </span>
                          </span>
                        )}
                        {job.scheduledStart && (
                          <span className="text-xs text-muted flex items-center gap-1">
                            <Calendar size={12} className="flex-shrink-0" />
                            {formatDate(job.scheduledStart)} at {formatTime(job.scheduledStart)}
                          </span>
                        )}
                      </div>
                    </div>
                    <ChevronRight size={16} className="text-muted flex-shrink-0 mt-1" />
                  </div>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
