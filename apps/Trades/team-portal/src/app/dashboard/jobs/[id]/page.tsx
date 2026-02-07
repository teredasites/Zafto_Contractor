'use client';

import { useParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft, MapPin, Calendar, Clock, FileText, Wrench,
  CheckSquare, Package, Play, ClipboardList,
} from 'lucide-react';
import { useJob } from '@/lib/hooks/use-jobs';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge } from '@/components/ui/badge';
import { formatDate, formatTime, formatCurrency } from '@/lib/utils';

function JobDetailSkeleton() {
  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center gap-3">
        <div className="skeleton h-9 w-9 rounded-lg" />
        <div className="skeleton h-6 w-48 rounded-lg" />
      </div>
      <div className="skeleton h-8 w-64 rounded-lg" />
      <div className="skeleton h-40 w-full rounded-xl" />
      <div className="skeleton h-48 w-full rounded-xl" />
      <div className="grid grid-cols-2 gap-3">
        <div className="skeleton h-14 rounded-xl" />
        <div className="skeleton h-14 rounded-xl" />
        <div className="skeleton h-14 rounded-xl" />
        <div className="skeleton h-14 rounded-xl" />
      </div>
    </div>
  );
}

export default function JobDetailPage() {
  const params = useParams();
  const jobId = params.id as string;
  const { job, loading } = useJob(jobId);

  if (loading) return <JobDetailSkeleton />;

  if (!job) {
    return (
      <div className="space-y-6 animate-fade-in">
        <Link
          href="/dashboard/jobs"
          className="inline-flex items-center gap-2 text-sm text-muted hover:text-main transition-colors"
        >
          <ArrowLeft size={16} />
          Back to Jobs
        </Link>
        <Card>
          <CardContent className="py-12 text-center">
            <ClipboardList size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">Job not found</p>
            <p className="text-sm text-muted mt-1">This job may have been removed or you no longer have access.</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  const fullAddress = [job.address, job.city, job.state].filter(Boolean).join(', ');

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Back navigation */}
      <Link
        href="/dashboard/jobs"
        className="inline-flex items-center gap-2 text-sm text-muted hover:text-main transition-colors min-h-[44px]"
      >
        <ArrowLeft size={16} />
        Back to Jobs
      </Link>

      {/* Job Header */}
      <div className="flex flex-col sm:flex-row sm:items-start gap-3">
        <div className="flex-1 min-w-0">
          <h1 className="text-xl font-semibold text-main">{job.title}</h1>
          <p className="text-sm text-secondary mt-0.5">{job.customerName}</p>
        </div>
        <StatusBadge status={job.status} className="self-start" />
      </div>

      {/* Job Info */}
      <Card>
        <CardContent className="py-4 space-y-4">
          {/* Address */}
          {fullAddress && (
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
                <MapPin size={16} className="text-muted" />
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wide font-medium">Address</p>
                <p className="text-sm text-main mt-0.5">{fullAddress}</p>
              </div>
            </div>
          )}

          {/* Scheduled Date */}
          {job.scheduledStart && (
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
                <Calendar size={16} className="text-muted" />
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wide font-medium">Scheduled</p>
                <p className="text-sm text-main mt-0.5">
                  {formatDate(job.scheduledStart)} at {formatTime(job.scheduledStart)}
                  {job.scheduledEnd && (
                    <span className="text-muted"> - {formatTime(job.scheduledEnd)}</span>
                  )}
                </p>
              </div>
            </div>
          )}

          {/* Estimated Amount */}
          {job.estimatedAmount > 0 && (
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
                <FileText size={16} className="text-muted" />
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wide font-medium">Estimated</p>
                <p className="text-sm text-main mt-0.5">{formatCurrency(job.estimatedAmount)}</p>
              </div>
            </div>
          )}

          {/* Type */}
          <div className="flex items-start gap-3">
            <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
              <Wrench size={16} className="text-muted" />
            </div>
            <div>
              <p className="text-xs text-muted uppercase tracking-wide font-medium">Type</p>
              <p className="text-sm text-main mt-0.5 capitalize">{job.type.replace(/_/g, ' ')}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Description */}
      {job.description && (
        <Card>
          <CardHeader>
            <CardTitle>Description</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-secondary whitespace-pre-wrap leading-relaxed">{job.description}</p>
          </CardContent>
        </Card>
      )}

      {/* Quick Actions */}
      <div>
        <h2 className="text-[15px] font-semibold text-main mb-3">Quick Actions</h2>
        <div className="grid grid-cols-2 gap-3">
          <Link href={`/dashboard/time-clock?jobId=${job.id}`}>
            <Button variant="secondary" size="lg" className="w-full min-h-[56px] flex-col gap-1 py-3">
              <Play size={20} />
              <span className="text-xs">Clock In</span>
            </Button>
          </Link>
          <Link href={`/dashboard/field-tools?jobId=${job.id}`}>
            <Button variant="secondary" size="lg" className="w-full min-h-[56px] flex-col gap-1 py-3">
              <Wrench size={20} />
              <span className="text-xs">Field Tools</span>
            </Button>
          </Link>
          <Link href={`/dashboard/punch-list?jobId=${job.id}`}>
            <Button variant="secondary" size="lg" className="w-full min-h-[56px] flex-col gap-1 py-3">
              <CheckSquare size={20} />
              <span className="text-xs">Punch List</span>
            </Button>
          </Link>
          <Link href={`/dashboard/materials?jobId=${job.id}`}>
            <Button variant="secondary" size="lg" className="w-full min-h-[56px] flex-col gap-1 py-3">
              <Package size={20} />
              <span className="text-xs">Materials</span>
            </Button>
          </Link>
        </div>
      </div>
    </div>
  );
}
