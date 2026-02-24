'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Search,
  Briefcase,
  MapPin,
  Clock,
  MoreHorizontal,
  CheckCircle,
  PlayCircle,
  PauseCircle,
  Calendar,
  User,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge, Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { Avatar, AvatarGroup } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, getStatusLabel, cn } from '@/lib/utils';
import { useJobs, useTeam } from '@/lib/hooks/use-jobs';
import { useTranslation } from '@/lib/translations';
import { useStats } from '@/lib/hooks/use-stats';
import { JOB_TYPE_LABELS, JOB_TYPE_COLORS } from '@/lib/hooks/mappers';
import type { Job, JobType, TeamMember } from '@/types';

export default function JobsPage() {
  const router = useRouter();
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [stormFilter, setStormFilter] = useState('all');
  const [originFilter, setOriginFilter] = useState('all');
  const [sourceFilter, setSourceFilter] = useState('all');
  const [view, setView] = useState<'list' | 'board'>('list');
  const { jobs, loading: jobsLoading } = useJobs();
  const { team } = useTeam();
  const { stats: dashStats } = useStats();
  const stats = dashStats.jobs;

  if (jobsLoading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-28 mb-2" /><div className="skeleton h-4 w-48" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => <div key={i} className="px-6 py-4 flex items-center gap-4"><div className="flex-1"><div className="skeleton h-4 w-40 mb-2" /><div className="skeleton h-3 w-32" /></div><div className="skeleton h-4 w-20" /></div>)}
        </div>
      </div>
    );
  }

  const filteredJobs = jobs.filter((job) => {
    const matchesSearch =
      job.title.toLowerCase().includes(search.toLowerCase()) ||
      job.customer?.firstName?.toLowerCase().includes(search.toLowerCase()) ||
      job.customer?.lastName?.toLowerCase().includes(search.toLowerCase());

    const matchesStatus = statusFilter === 'all' || job.status === statusFilter;
    const matchesType = typeFilter === 'all' || job.jobType === typeFilter;
    const matchesStorm = stormFilter === 'all' || job.tags.some((t) => t === `storm:${stormFilter}`);
    const matchesSource = sourceFilter === 'all' || job.source === sourceFilter;
    const matchesOrigin = originFilter === 'all' ||
      (originFilter === 'client' && !job.propertyId) ||
      (originFilter === 'maintenance' && !!job.propertyId);

    return matchesSearch && matchesStatus && matchesType && matchesStorm && matchesSource && matchesOrigin;
  });

  // Extract unique storm events from job tags
  const stormEvents = [...new Set(
    jobs.flatMap((j) => j.tags.filter((t) => t.startsWith('storm:')).map((t) => t.replace('storm:', '')))
  )].sort();

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'lead', label: 'Lead' },
    { value: 'scheduled', label: 'Scheduled' },
    { value: 'in_progress', label: 'In Progress' },
    { value: 'on_hold', label: 'On Hold' },
    { value: 'completed', label: 'Completed' },
    { value: 'invoiced', label: 'Invoiced' },
    { value: 'paid', label: 'Paid' },
  ];

  // Group jobs by status for board view
  const jobsByStatus = {
    scheduled: filteredJobs.filter((j) => j.status === 'scheduled'),
    in_progress: filteredJobs.filter((j) => j.status === 'in_progress'),
    completed: filteredJobs.filter((j) => j.status === 'completed'),
    invoiced: filteredJobs.filter((j) => j.status === 'invoiced'),
  };

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('jobs.title')}</h1>
          <p className="text-muted mt-1">{t('jobs.manageDesc')}</p>
        </div>
        <Button onClick={() => router.push('/dashboard/jobs/new')}>
          <Plus size={16} />
          {t('jobs.newJob')}
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Calendar size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.scheduled}</p>
                <p className="text-sm text-muted">{t('jobs.statusScheduled')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg">
                <PlayCircle size={20} className="text-indigo-600 dark:text-indigo-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.inProgress}</p>
                <p className="text-sm text-muted">{t('jobs.statusInProgress')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.completed}</p>
                <p className="text-sm text-muted">{t('jobs.statusComplete')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-secondary rounded-lg">
                <Briefcase size={20} className="text-muted" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.completedThisMonth}</p>
                <p className="text-sm text-muted">{t('jobs.thisMonth')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder={t('jobs.searchJobs')}
          className="sm:w-80"
        />
        <Select
          options={statusOptions}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
        <Select
          options={[
            { value: 'all', label: 'All Types' },
            { value: 'standard', label: 'Standard' },
            { value: 'insurance_claim', label: 'Insurance Claim' },
            { value: 'warranty_dispatch', label: 'Warranty Dispatch' },
          ]}
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="sm:w-48"
        />
        {stormEvents.length > 0 && (
          <Select
            options={[
              { value: 'all', label: 'All Storm Events' },
              ...stormEvents.map((e) => ({ value: e, label: e })),
            ]}
            value={stormFilter}
            onChange={(e) => setStormFilter(e.target.value)}
            className="sm:w-48"
          />
        )}
        <Select
          options={[
            { value: 'all', label: 'All Jobs' },
            { value: 'client', label: 'Client Jobs' },
            { value: 'maintenance', label: 'Maintenance Jobs' },
          ]}
          value={originFilter}
          onChange={(e) => setOriginFilter(e.target.value)}
          className="sm:w-40"
        />
        <Select
          options={[
            { value: 'all', label: 'All Sources' },
            { value: 'direct', label: 'Direct' },
            { value: 'referral', label: 'Referral' },
            { value: 'canvass', label: 'Canvass' },
            { value: 'website', label: 'Website' },
            { value: 'phone', label: 'Phone' },
            { value: 'other', label: 'Other' },
          ]}
          value={sourceFilter}
          onChange={(e) => setSourceFilter(e.target.value)}
          className="sm:w-40"
        />
        <div className="flex items-center gap-1 p-1 bg-secondary rounded-lg ml-auto">
          <button
            onClick={() => setView('list')}
            className={cn(
              'px-3 py-1.5 text-sm rounded-md transition-colors',
              view === 'list'
                ? 'bg-surface text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
          >
            {t('jobs.viewList')}
          </button>
          <button
            onClick={() => setView('board')}
            className={cn(
              'px-3 py-1.5 text-sm rounded-md transition-colors',
              view === 'board'
                ? 'bg-surface text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
          >
            {t('jobs.viewBoard')}
          </button>
        </div>
      </div>

      {/* Jobs List or Board */}
      {view === 'list' ? (
        <Card>
          <CardContent className="p-0">
            {filteredJobs.length === 0 ? (
              <div className="py-12 text-center text-muted">
                <Briefcase size={40} className="mx-auto mb-2 opacity-50" />
                <p>{t('jobs.noJobs')}</p>
              </div>
            ) : (
              <div className="divide-y divide-main">
                {filteredJobs.map((job) => (
                  <JobRow
                    key={job.id}
                    job={job}
                    team={team}
                    onClick={() => router.push(`/dashboard/jobs/${job.id}`)}
                  />
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {Object.entries(jobsByStatus).map(([status, jobs]) => (
            <div key={status} className="space-y-3">
              <div className="flex items-center justify-between">
                <h3 className="font-medium text-main capitalize">
                  {getStatusLabel(status)}
                </h3>
                <span className="text-sm text-muted">{jobs.length}</span>
              </div>
              <div className="space-y-3">
                {jobs.map((job) => (
                  <JobCard
                    key={job.id}
                    job={job}
                    team={team}
                    onClick={() => router.push(`/dashboard/jobs/${job.id}`)}
                  />
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function JobRow({ job, team, onClick }: { job: Job; team: TeamMember[]; onClick: () => void }) {
  return (
    <div
      className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
      onClick={onClick}
    >
      <div className="flex items-center gap-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h4 className="font-medium text-main truncate">{job.title}</h4>
            <StatusBadge status={job.status} />
            {job.jobType !== 'standard' && (
              <JobTypeBadge type={job.jobType} />
            )}
            {job.priority === 'urgent' && (
              <Badge variant="error" size="sm">
                Urgent
              </Badge>
            )}
            {job.priority === 'high' && (
              <Badge variant="warning" size="sm">
                High
              </Badge>
            )}
          </div>
          <div className="flex items-center gap-4 mt-1 text-sm text-muted">
            <span className="flex items-center gap-1">
              <User size={14} />
              {job.customer?.firstName} {job.customer?.lastName}
            </span>
            <span className="flex items-center gap-1">
              <MapPin size={14} />
              {job.address.city}, {job.address.state}
            </span>
          </div>
        </div>
        <div className="flex items-center gap-4">
          <AvatarGroup
            avatars={job.assignedTo.map((id) => {
              const member = team.find((t) => t.id === id);
              return { name: member?.name || 'Unknown' };
            })}
            size="sm"
          />
          <div className="text-right">
            <p className="font-semibold text-main">{formatCurrency(job.estimatedValue)}</p>
            {job.scheduledStart && (
              <p className="text-sm text-muted">{formatDate(job.scheduledStart)}</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function JobTypeBadge({ type }: { type: JobType }) {
  const colors = JOB_TYPE_COLORS[type];
  return (
    <span className={cn('inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full', colors.bg, colors.text)}>
      <span className={cn('w-1.5 h-1.5 rounded-full', colors.dot)} />
      {JOB_TYPE_LABELS[type]}
    </span>
  );
}

function JobCard({ job, team, onClick }: { job: Job; team: TeamMember[]; onClick: () => void }) {
  return (
    <Card hover onClick={onClick} className="p-4">
      <div className="flex items-start justify-between gap-2 mb-2">
        <h4 className="font-medium text-main text-sm line-clamp-2">{job.title}</h4>
        <div className="flex items-center gap-1">
          {job.jobType !== 'standard' && (
            <JobTypeBadge type={job.jobType} />
          )}
          {job.priority === 'urgent' && (
            <Badge variant="error" size="sm">!</Badge>
          )}
        </div>
      </div>
      <p className="text-xs text-muted mb-3">
        {job.customer?.firstName} {job.customer?.lastName}
      </p>
      <div className="flex items-center justify-between">
        <AvatarGroup
          avatars={job.assignedTo.map((id) => {
            const member = team.find((t) => t.id === id);
            return { name: member?.name || 'Unknown' };
          })}
          size="sm"
          max={3}
        />
        <span className="text-sm font-medium text-main">
          {formatCurrency(job.estimatedValue)}
        </span>
      </div>
    </Card>
  );
}
