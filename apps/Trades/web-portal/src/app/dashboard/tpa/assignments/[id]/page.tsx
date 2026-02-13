'use client';

import { useState, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  Clock,
  CheckCircle2,
  AlertTriangle,
  Phone,
  Mail,
  MapPin,
  DollarSign,
  FileText,
  Users,
  ExternalLink,
  Briefcase,
  AlertCircle,
  Droplets,
  Flame,
  Wind,
  CloudRain,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import {
  useTpaAssignment,
  updateAssignmentStatus,
  createJobFromAssignment,
  getSlaStatus,
  formatTimeRemaining,
  type TpaAssignmentStatus,
} from '@/lib/hooks/use-tpa-assignments';

// ==================== CONSTANTS ====================

const STATUS_LABELS: Record<TpaAssignmentStatus, string> = {
  received: 'Received', contacted: 'Contacted', scheduled: 'Scheduled',
  onsite: 'On Site', inspecting: 'Inspecting', estimate_pending: 'Estimate Pending',
  estimate_submitted: 'Estimate Submitted', approved: 'Approved', in_progress: 'In Progress',
  supplement_pending: 'Supplement Pending', supplement_submitted: 'Supplement Submitted',
  drying: 'Drying', monitoring: 'Monitoring', completed: 'Completed', closed: 'Closed',
  declined: 'Declined', cancelled: 'Cancelled', reassigned: 'Reassigned',
};

const STATUS_FLOW: TpaAssignmentStatus[] = [
  'received', 'contacted', 'scheduled', 'onsite', 'inspecting',
  'estimate_pending', 'estimate_submitted', 'approved', 'in_progress',
  'drying', 'monitoring', 'completed', 'closed',
];

const SLA_COLORS: Record<string, string> = {
  on_track: 'text-emerald-400', approaching: 'text-amber-400', overdue: 'text-red-400',
};
const SLA_BG: Record<string, string> = {
  on_track: 'bg-emerald-500/10 border-emerald-500/20', approaching: 'bg-amber-500/10 border-amber-500/20', overdue: 'bg-red-500/10 border-red-500/20',
};

// ==================== PAGE COMPONENT ====================

export default function TpaAssignmentDetailPage() {
  const params = useParams();
  const router = useRouter();
  const assignmentId = params.id as string;
  const { assignment, loading, error, refetch } = useTpaAssignment(assignmentId);
  const [updatingStatus, setUpdatingStatus] = useState(false);
  const [creatingJob, setCreatingJob] = useState(false);

  const handleStatusUpdate = useCallback(async (newStatus: TpaAssignmentStatus) => {
    setUpdatingStatus(true);
    try {
      await updateAssignmentStatus(assignmentId, newStatus);
      refetch();
    } catch {
      // Real-time will refresh
    } finally {
      setUpdatingStatus(false);
    }
  }, [assignmentId, refetch]);

  const handleCreateJob = useCallback(async () => {
    setCreatingJob(true);
    try {
      const jobId = await createJobFromAssignment(assignmentId);
      refetch();
      router.push(`/dashboard/jobs/${jobId}`);
    } catch {
      // Error handling — graceful degradation
    } finally {
      setCreatingJob(false);
    }
  }, [assignmentId, refetch, router]);

  // Loading
  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="w-6 h-6 border-2 border-accent border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // Error
  if (error || !assignment) {
    return (
      <div className="space-y-4">
        <Link href="/dashboard/tpa/assignments" className="flex items-center gap-2 text-sm text-muted hover:text-main transition-colors">
          <ArrowLeft size={16} /> Back to Assignments
        </Link>
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-16 text-center">
            <AlertCircle size={48} className="text-red-400/50 mb-4" />
            <h3 className="text-lg font-semibold text-main">Assignment Not Found</h3>
            <p className="text-sm text-muted mt-1">{error || 'This assignment may have been deleted.'}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  // SLA statuses
  const contactSla = getSlaStatus(assignment.firstContactDeadline, assignment.firstContactAt);
  const onsiteSla = getSlaStatus(assignment.onsiteDeadline, assignment.onsiteAt);
  const estimateSla = getSlaStatus(assignment.estimateDeadline, assignment.estimateSubmittedAt);

  // Next status in workflow
  const currentIdx = STATUS_FLOW.indexOf(assignment.status);
  const nextStatus = currentIdx >= 0 && currentIdx < STATUS_FLOW.length - 1 ? STATUS_FLOW[currentIdx + 1] : null;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/dashboard/tpa/assignments" className="p-1.5 rounded-md text-muted hover:text-main hover:bg-surface-hover transition-colors">
            <ArrowLeft size={18} />
          </Link>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-semibold text-main">
                {assignment.claimNumber || assignment.assignmentNumber || 'Assignment'}
              </h1>
              <Badge variant="secondary" className="text-xs">
                {STATUS_LABELS[assignment.status]}
              </Badge>
            </div>
            <p className="text-sm text-muted mt-0.5">
              {assignment.program?.name} {assignment.carrierName ? `- ${assignment.carrierName}` : ''}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {!assignment.jobId && (
            <Button variant="outline" onClick={handleCreateJob} disabled={creatingJob}>
              <Briefcase size={16} className="mr-2" />
              {creatingJob ? 'Creating...' : 'Create Job'}
            </Button>
          )}
          {assignment.jobId && (
            <Link href={`/dashboard/jobs/${assignment.jobId}`}>
              <Button variant="outline">
                <Briefcase size={16} className="mr-2" />
                View Job
              </Button>
            </Link>
          )}
          {nextStatus && (
            <Button onClick={() => handleStatusUpdate(nextStatus)} disabled={updatingStatus}>
              <CheckCircle2 size={16} className="mr-2" />
              {updatingStatus ? 'Updating...' : `Mark ${STATUS_LABELS[nextStatus]}`}
            </Button>
          )}
        </div>
      </div>

      {/* SLA Dashboard */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {[
          { label: 'First Contact', deadline: assignment.firstContactDeadline, completed: assignment.firstContactAt, sla: contactSla },
          { label: 'Onsite Visit', deadline: assignment.onsiteDeadline, completed: assignment.onsiteAt, sla: onsiteSla },
          { label: 'Estimate Due', deadline: assignment.estimateDeadline, completed: assignment.estimateSubmittedAt, sla: estimateSla },
          { label: 'Completion', deadline: assignment.completionDeadline, completed: assignment.workCompletedAt, sla: getSlaStatus(assignment.completionDeadline, assignment.workCompletedAt) },
        ].map(item => (
          <Card key={item.label} className={cn('border', SLA_BG[item.sla])}>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <p className="text-xs text-muted uppercase tracking-wide">{item.label}</p>
                {item.completed ? (
                  <CheckCircle2 size={14} className="text-emerald-400" />
                ) : item.sla === 'overdue' ? (
                  <AlertTriangle size={14} className="text-red-400" />
                ) : (
                  <Clock size={14} className={SLA_COLORS[item.sla]} />
                )}
              </div>
              <p className={cn('text-lg font-semibold mt-1', SLA_COLORS[item.sla])}>
                {formatTimeRemaining(item.deadline, item.completed)}
              </p>
              {item.deadline && (
                <p className="text-[11px] text-muted mt-0.5">
                  {item.completed ? 'Completed' : `Due: ${new Date(item.deadline).toLocaleString()}`}
                </p>
              )}
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left column — Assignment details */}
        <div className="lg:col-span-2 space-y-6">
          {/* Timeline */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2"><Clock size={16} /> Status Timeline</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {STATUS_FLOW.map((status, i) => {
                  const isActive = assignment.status === status;
                  const isPast = currentIdx > i;
                  const isFuture = currentIdx < i;

                  return (
                    <div key={status} className="flex items-center gap-3">
                      <div className={cn(
                        'w-6 h-6 rounded-full flex items-center justify-center flex-shrink-0 border',
                        isPast ? 'bg-emerald-500/20 border-emerald-500/40 text-emerald-400'
                          : isActive ? 'bg-accent/20 border-accent/40 text-accent'
                          : 'bg-surface-hover border-main/30 text-muted/40',
                      )}>
                        {isPast ? <CheckCircle2 size={12} /> : <span className="text-[10px] font-medium">{i + 1}</span>}
                      </div>
                      <span className={cn(
                        'text-sm font-medium',
                        isPast ? 'text-muted' : isActive ? 'text-main' : 'text-muted/40',
                      )}>
                        {STATUS_LABELS[status]}
                      </span>
                      {isActive && <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-accent/10 text-accent font-medium">Current</span>}
                    </div>
                  );
                })}
              </div>
            </CardContent>
          </Card>

          {/* Financial Summary */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2"><DollarSign size={16} /> Financial Summary</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div>
                  <p className="text-xs text-muted uppercase tracking-wide">Estimated</p>
                  <p className="text-lg font-semibold text-main mt-0.5">${assignment.totalEstimated.toLocaleString()}</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wide">Invoiced</p>
                  <p className="text-lg font-semibold text-main mt-0.5">${assignment.totalInvoiced.toLocaleString()}</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wide">Collected</p>
                  <p className="text-lg font-semibold text-emerald-400 mt-0.5">${assignment.totalCollected.toLocaleString()}</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wide">Supplements</p>
                  <p className="text-lg font-semibold text-main mt-0.5">${assignment.totalSupplements.toLocaleString()}</p>
                </div>
              </div>
              {assignment.referralFeeAmount != null && assignment.referralFeeAmount > 0 && (
                <div className="mt-4 pt-4 border-t border-main/20">
                  <p className="text-xs text-muted">Referral Fee: <span className="text-main font-medium">${assignment.referralFeeAmount.toLocaleString()}</span></p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Loss Details */}
          {assignment.lossDescription && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2"><FileText size={16} /> Loss Details</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 gap-4 mb-4">
                  {assignment.lossType && (
                    <div>
                      <p className="text-xs text-muted uppercase tracking-wide">Type</p>
                      <p className="text-sm text-main mt-0.5 capitalize">{assignment.lossType}</p>
                    </div>
                  )}
                  {assignment.lossDate && (
                    <div>
                      <p className="text-xs text-muted uppercase tracking-wide">Date of Loss</p>
                      <p className="text-sm text-main mt-0.5">{new Date(assignment.lossDate).toLocaleDateString()}</p>
                    </div>
                  )}
                </div>
                <p className="text-sm text-muted">{assignment.lossDescription}</p>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Right column — Contacts + info */}
        <div className="space-y-6">
          {/* Policyholder */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Policyholder</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              {assignment.policyholderName && (
                <p className="text-sm font-medium text-main">{assignment.policyholderName}</p>
              )}
              {assignment.policyholderPhone && (
                <a href={`tel:${assignment.policyholderPhone}`} className="flex items-center gap-2 text-sm text-accent hover:underline">
                  <Phone size={13} /> {assignment.policyholderPhone}
                </a>
              )}
              {assignment.policyholderEmail && (
                <a href={`mailto:${assignment.policyholderEmail}`} className="flex items-center gap-2 text-sm text-accent hover:underline">
                  <Mail size={13} /> {assignment.policyholderEmail}
                </a>
              )}
              {!assignment.policyholderName && <p className="text-sm text-muted">No policyholder info</p>}
            </CardContent>
          </Card>

          {/* Adjuster */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Adjuster</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              {assignment.adjusterName && (
                <p className="text-sm font-medium text-main">{assignment.adjusterName}</p>
              )}
              {assignment.adjusterPhone && (
                <a href={`tel:${assignment.adjusterPhone}`} className="flex items-center gap-2 text-sm text-accent hover:underline">
                  <Phone size={13} /> {assignment.adjusterPhone}
                </a>
              )}
              {assignment.adjusterEmail && (
                <a href={`mailto:${assignment.adjusterEmail}`} className="flex items-center gap-2 text-sm text-accent hover:underline">
                  <Mail size={13} /> {assignment.adjusterEmail}
                </a>
              )}
              {!assignment.adjusterName && <p className="text-sm text-muted">No adjuster info</p>}
            </CardContent>
          </Card>

          {/* Property */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2"><MapPin size={16} /> Property</CardTitle>
            </CardHeader>
            <CardContent>
              {assignment.propertyAddress ? (
                <div className="text-sm text-main">
                  <p>{assignment.propertyAddress}</p>
                  <p>{assignment.propertyCity}{assignment.propertyState ? `, ${assignment.propertyState}` : ''} {assignment.propertyZip}</p>
                </div>
              ) : (
                <p className="text-sm text-muted">No property address</p>
              )}
            </CardContent>
          </Card>

          {/* ESA */}
          {assignment.esaRequested && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Emergency Authorization</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <Badge variant={assignment.esaAuthorized ? 'success' : 'warning'}>
                      {assignment.esaAuthorized ? 'Authorized' : 'Pending'}
                    </Badge>
                  </div>
                  {assignment.esaAmount != null && (
                    <p className="text-sm text-main">Amount: ${assignment.esaAmount.toLocaleString()}</p>
                  )}
                  {assignment.esaNotes && (
                    <p className="text-sm text-muted">{assignment.esaNotes}</p>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Identifiers */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Reference Numbers</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              {[
                { label: 'Assignment #', value: assignment.assignmentNumber },
                { label: 'Claim #', value: assignment.claimNumber },
                { label: 'Policy #', value: assignment.policyNumber },
                { label: 'Carrier', value: assignment.carrierName },
              ].filter(r => r.value).map(r => (
                <div key={r.label} className="flex justify-between text-sm">
                  <span className="text-muted">{r.label}</span>
                  <span className="text-main font-medium">{r.value}</span>
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Internal Notes */}
          {assignment.internalNotes && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Internal Notes</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-muted whitespace-pre-wrap">{assignment.internalNotes}</p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
