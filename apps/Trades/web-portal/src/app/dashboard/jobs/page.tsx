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
import { mockJobs, mockTeam, mockDashboardStats } from '@/lib/mock-data';
import type { Job } from '@/types';

export default function JobsPage() {
  const router = useRouter();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [view, setView] = useState<'list' | 'board'>('list');

  const stats = mockDashboardStats.jobs;

  const filteredJobs = mockJobs.filter((job) => {
    const matchesSearch =
      job.title.toLowerCase().includes(search.toLowerCase()) ||
      job.customer?.firstName.toLowerCase().includes(search.toLowerCase()) ||
      job.customer?.lastName.toLowerCase().includes(search.toLowerCase());

    const matchesStatus = statusFilter === 'all' || job.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

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
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Jobs</h1>
          <p className="text-muted mt-1">Manage your jobs and track progress</p>
        </div>
        <Button onClick={() => router.push('/dashboard/jobs/new')}>
          <Plus size={16} />
          New Job
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
                <p className="text-sm text-muted">Scheduled</p>
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
                <p className="text-sm text-muted">In Progress</p>
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
                <p className="text-sm text-muted">Completed</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-slate-100 dark:bg-slate-800 rounded-lg">
                <Briefcase size={20} className="text-slate-600 dark:text-slate-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.completedThisMonth}</p>
                <p className="text-sm text-muted">This Month</p>
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
          placeholder="Search jobs..."
          className="sm:w-80"
        />
        <Select
          options={statusOptions}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
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
            List
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
            Board
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
                <p>No jobs found</p>
              </div>
            ) : (
              <div className="divide-y divide-main">
                {filteredJobs.map((job) => (
                  <JobRow
                    key={job.id}
                    job={job}
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

function JobRow({ job, onClick }: { job: Job; onClick: () => void }) {
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
              const member = mockTeam.find((t) => t.id === id);
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

function JobCard({ job, onClick }: { job: Job; onClick: () => void }) {
  return (
    <Card hover onClick={onClick} className="p-4">
      <div className="flex items-start justify-between gap-2 mb-2">
        <h4 className="font-medium text-main text-sm line-clamp-2">{job.title}</h4>
        {job.priority === 'urgent' && (
          <Badge variant="error" size="sm">!</Badge>
        )}
      </div>
      <p className="text-xs text-muted mb-3">
        {job.customer?.firstName} {job.customer?.lastName}
      </p>
      <div className="flex items-center justify-between">
        <AvatarGroup
          avatars={job.assignedTo.map((id) => {
            const member = mockTeam.find((t) => t.id === id);
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
