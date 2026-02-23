'use client';

// L4: Per-Job Permit Detail — permit cards + inspection timeline
// Shows all permits for a specific job with inspection status.

import { useParams } from 'next/navigation';
import { useState } from 'react';
import {
  FileCheck,
  Clock,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Calendar,
  User,
  Phone,
  DollarSign,
  ClipboardCheck,
  Send,
  ArrowLeft,
  RefreshCw,
  Camera,
} from 'lucide-react';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useJobPermitRecords, usePermitInspections, type JobPermitRecord, type PermitInspectionRecord } from '@/lib/hooks/use-permit-intelligence';
import { useTranslation } from '@/lib/translations';

function statusBadgeVariant(status: string): 'success' | 'error' | 'warning' | 'info' | 'secondary' | 'default' {
  switch (status) {
    case 'approved': case 'active': return 'success';
    case 'denied': return 'error';
    case 'expired': case 'corrections_needed': return 'warning';
    case 'applied': case 'pending_review': return 'info';
    default: return 'secondary';
  }
}

function resultBadgeVariant(result: string | null): 'success' | 'error' | 'warning' | 'info' | 'secondary' {
  switch (result) {
    case 'pass': return 'success';
    case 'fail': return 'error';
    case 'partial': return 'warning';
    case 'rescheduled': return 'info';
    default: return 'secondary';
  }
}

function InspectionTimeline({ jobPermitId }: { jobPermitId: string }) {
  const { t } = useTranslation();
  const { inspections, loading } = usePermitInspections(jobPermitId);

  if (loading) return <div className="p-4 text-center text-zinc-500 text-sm">{t('permits.loadingInspections')}</div>;
  if (!inspections.length) {
    return (
      <div className="p-6 text-center">
        <ClipboardCheck className="h-8 w-8 text-zinc-600 mx-auto mb-2" />
        <p className="text-zinc-500 text-sm">{t('permits.noInspectionsScheduled')}</p>
      </div>
    );
  }

  return (
    <div className="space-y-3 p-4">
      {inspections.map((insp: PermitInspectionRecord, i: number) => (
        <div key={insp.id} className="flex gap-3">
          {/* Timeline dot */}
          <div className="flex flex-col items-center">
            <div className={`w-3 h-3 rounded-full mt-1.5 ${
              insp.result === 'pass' ? 'bg-emerald-500' :
              insp.result === 'fail' ? 'bg-red-500' :
              insp.result ? 'bg-amber-500' : 'bg-zinc-600'
            }`} />
            {i < inspections.length - 1 && <div className="w-0.5 flex-1 bg-zinc-700 mt-1" />}
          </div>
          {/* Content */}
          <div className="flex-1 pb-4">
            <div className="flex items-center gap-2 mb-1">
              <span className="text-sm font-medium text-white">{insp.inspection_type}</span>
              <Badge variant={resultBadgeVariant(insp.result)} size="sm">
                {insp.result ? insp.result.charAt(0).toUpperCase() + insp.result.slice(1) : 'Scheduled'}
              </Badge>
            </div>
            <div className="space-y-1 text-xs text-zinc-400">
              {insp.scheduled_date && (
                <div className="flex items-center gap-1.5">
                  <Calendar className="h-3 w-3" />
                  <span>Scheduled: {new Date(insp.scheduled_date).toLocaleDateString()}</span>
                </div>
              )}
              {insp.completed_date && (
                <div className="flex items-center gap-1.5">
                  <CheckCircle className="h-3 w-3" />
                  <span>Completed: {new Date(insp.completed_date).toLocaleDateString()}</span>
                </div>
              )}
              {insp.inspector_name && (
                <div className="flex items-center gap-1.5">
                  <User className="h-3 w-3" />
                  <span>{insp.inspector_name}</span>
                </div>
              )}
              {insp.result === 'fail' && insp.failure_reason && (
                <div className="mt-2 p-2 bg-red-500/10 border border-red-500/20 rounded-md">
                  <p className="text-red-400 text-xs font-medium">Failure: {insp.failure_reason}</p>
                  {insp.correction_notes && <p className="text-red-300 text-xs mt-1">{insp.correction_notes}</p>}
                  {insp.correction_deadline && (
                    <p className="text-amber-400 text-xs mt-1 flex items-center gap-1">
                      <AlertTriangle className="h-3 w-3" />
                      Deadline: {new Date(insp.correction_deadline).toLocaleDateString()}
                    </p>
                  )}
                </div>
              )}
              {insp.reinspection_needed && (
                <div className="flex items-center gap-1.5 text-blue-400 mt-1">
                  <RefreshCw className="h-3 w-3" />
                  <span>{t('permits.reinspectionNeeded')}</span>
                </div>
              )}
              {insp.photos && insp.photos.length > 0 && (
                <div className="flex items-center gap-1.5 mt-1">
                  <Camera className="h-3 w-3" />
                  <span>{insp.photos.length} photo{insp.photos.length > 1 ? 's' : ''}</span>
                </div>
              )}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

export default function PermitDetailPage() {
  const { t, formatDate } = useTranslation();
  const params = useParams();
  const jobId = params.jobId as string;
  const { permits, loading, error } = useJobPermitRecords(jobId);
  const [expandedPermit, setExpandedPermit] = useState<string | null>(null);

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <Card>
          <CardContent className="p-8 text-center">
            <p className="text-red-400 mb-2">{t('permits.failedToLoadPermits')}</p>
            <p className="text-sm text-zinc-500">{error}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href="/dashboard/permits">
          <Button variant="ghost" size="sm">
            <ArrowLeft className="h-4 w-4 mr-1" /> Back
          </Button>
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-white">{t('permits.title')}</h1>
          <p className="text-sm text-zinc-400">{permits.length} permit{permits.length !== 1 ? 's' : ''} for this job</p>
        </div>
      </div>

      {permits.length === 0 ? (
        <Card>
          <CardContent className="p-8 text-center">
            <FileCheck className="h-12 w-12 text-zinc-600 mx-auto mb-3" />
            <p className="text-zinc-400">{t('permits.noPermitsForThisJob')}</p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {permits.map((permit: JobPermitRecord) => {
            const isExpanded = expandedPermit === permit.id;
            return (
              <Card key={permit.id}>
                {/* Permit Header */}
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-zinc-800">
                        <FileCheck className="h-5 w-5 text-zinc-400" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="text-base font-semibold text-white">{permit.permit_type}</h3>
                          <Badge variant={statusBadgeVariant(permit.status)}>
                            {permit.status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                          </Badge>
                        </div>
                        {permit.permit_number && (
                          <p className="text-xs text-zinc-500 mt-0.5">#{permit.permit_number}</p>
                        )}
                      </div>
                    </div>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setExpandedPermit(isExpanded ? null : permit.id)}
                    >
                      {isExpanded ? 'Collapse' : 'Inspections'}
                    </Button>
                  </div>

                  {/* Permit Details */}
                  <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mt-4 text-sm">
                    {permit.application_date && (
                      <div className="flex items-center gap-2 text-zinc-400">
                        <Send className="h-3.5 w-3.5 text-zinc-500" />
                        <span>Applied: {formatDate(permit.application_date)}</span>
                      </div>
                    )}
                    {permit.approval_date && (
                      <div className="flex items-center gap-2 text-emerald-400">
                        <CheckCircle className="h-3.5 w-3.5" />
                        <span>Approved: {formatDate(permit.approval_date)}</span>
                      </div>
                    )}
                    {permit.expiration_date && (
                      <div className="flex items-center gap-2 text-zinc-400">
                        <Clock className="h-3.5 w-3.5 text-zinc-500" />
                        <span>Expires: {formatDate(permit.expiration_date)}</span>
                      </div>
                    )}
                    {permit.fee_paid != null && (
                      <div className="flex items-center gap-2 text-zinc-400">
                        <DollarSign className="h-3.5 w-3.5 text-zinc-500" />
                        <span>Fee: ${permit.fee_paid.toFixed(2)}</span>
                      </div>
                    )}
                  </div>

                  {permit.notes && (
                    <p className="text-xs text-zinc-500 mt-3">{permit.notes}</p>
                  )}
                </CardContent>

                {/* Inspection Timeline (expanded) */}
                {isExpanded && (
                  <div className="border-t border-zinc-800">
                    <div className="px-4 pt-3 pb-1">
                      <h4 className="text-sm font-medium text-zinc-300">{t('permits.inspectionTimeline')}</h4>
                    </div>
                    <InspectionTimeline jobPermitId={permit.id} />
                  </div>
                )}
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
