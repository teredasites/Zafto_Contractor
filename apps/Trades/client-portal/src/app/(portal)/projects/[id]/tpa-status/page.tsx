'use client';

import { useParams } from 'next/navigation';
import Link from 'next/link';
import {
  Shield,
  Clock,
  CheckCircle2,
  AlertTriangle,
  ArrowLeft,
  FileCheck,
  Loader2,
} from 'lucide-react';
import { useTpaStatus } from '@/lib/hooks/use-tpa-status';

// ============================================================================
// HELPERS
// ============================================================================

const STATUS_LABELS: Record<string, string> = {
  received: 'Received',
  contacted: 'Contacted',
  scheduled: 'Scheduled',
  onsite: 'On Site',
  inspecting: 'Inspecting',
  estimate_pending: 'Estimate Pending',
  estimate_submitted: 'Estimate Submitted',
  approved: 'Approved',
  in_progress: 'In Progress',
  supplement_pending: 'Supplement Pending',
  drying: 'Drying',
  monitoring: 'Monitoring',
  completed: 'Completed',
  paid: 'Paid',
};

const SLA_COLORS = {
  on_track: { bg: 'bg-emerald-50', text: 'text-emerald-700', border: 'border-emerald-200', icon: CheckCircle2 },
  approaching: { bg: 'bg-amber-50', text: 'text-amber-700', border: 'border-amber-200', icon: Clock },
  overdue: { bg: 'bg-red-50', text: 'text-red-700', border: 'border-red-200', icon: AlertTriangle },
};

const SLA_LABELS = {
  on_track: 'On Track',
  approaching: 'Approaching Deadline',
  overdue: 'Past Deadline',
};

// ============================================================================
// PAGE
// ============================================================================

export default function TpaStatusPage() {
  const params = useParams();
  const jobId = params.id as string;
  const { status, loading, error } = useTpaStatus(jobId);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <Loader2 className="h-6 w-6 animate-spin text-gray-400" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-sm text-red-700">{error}</p>
        </div>
      </div>
    );
  }

  if (!status) {
    return (
      <div className="p-6">
        <Link href={`/projects/${jobId}`} className="flex items-center gap-1 text-sm text-gray-500 mb-4">
          <ArrowLeft className="h-4 w-4" />
          Back to Project
        </Link>
        <div className="text-center py-12">
          <Shield className="h-10 w-10 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">This project is not part of an insurance program</p>
        </div>
      </div>
    );
  }

  const slaStyle = SLA_COLORS[status.slaStatus];

  return (
    <div className="p-6 space-y-6 max-w-2xl mx-auto">
      {/* Back link */}
      <Link href={`/projects/${jobId}`} className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700">
        <ArrowLeft className="h-4 w-4" />
        Back to Project
      </Link>

      {/* Header */}
      <div>
        <h1 className="text-xl font-semibold text-gray-900 flex items-center gap-2">
          <Shield className="h-5 w-5 text-blue-600" />
          Insurance Claim Status
        </h1>
        <p className="text-sm text-gray-500 mt-1">{status.programName}</p>
      </div>

      {/* Claim Info */}
      <div className="bg-white border border-gray-200 rounded-lg p-4 space-y-3">
        <div className="grid grid-cols-2 gap-3">
          <div>
            <span className="text-xs text-gray-500 block">Claim Number</span>
            <span className="text-sm font-medium text-gray-900">{status.claimNumber || '--'}</span>
          </div>
          <div>
            <span className="text-xs text-gray-500 block">Status</span>
            <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-50 text-blue-700">
              {STATUS_LABELS[status.status] || status.status}
            </span>
          </div>
          {status.lossType && (
            <div>
              <span className="text-xs text-gray-500 block">Loss Type</span>
              <span className="text-sm text-gray-900 capitalize">{status.lossType.replace(/_/g, ' ')}</span>
            </div>
          )}
          {status.lossDate && (
            <div>
              <span className="text-xs text-gray-500 block">Date of Loss</span>
              <span className="text-sm text-gray-900">{new Date(status.lossDate).toLocaleDateString()}</span>
            </div>
          )}
        </div>
      </div>

      {/* SLA Status */}
      <div className={`${slaStyle.bg} border ${slaStyle.border} rounded-lg p-4`}>
        <div className="flex items-center gap-2 mb-1">
          <slaStyle.icon className={`h-5 w-5 ${slaStyle.text}`} />
          <span className={`text-sm font-medium ${slaStyle.text}`}>
            {SLA_LABELS[status.slaStatus]}
          </span>
        </div>
        {status.slaDeadline && (
          <p className={`text-xs ${slaStyle.text} opacity-80`}>
            Target completion: {new Date(status.slaDeadline).toLocaleDateString()} at{' '}
            {new Date(status.slaDeadline).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </p>
        )}
      </div>

      {/* Documentation Progress */}
      {status.docItemsTotal > 0 && (
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="flex items-center gap-2 mb-3">
            <FileCheck className="h-4 w-4 text-gray-600" />
            <span className="text-sm font-medium text-gray-900">Documentation Progress</span>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex-1">
              <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                <div
                  className={`h-full rounded-full ${
                    status.docCompliancePercent >= 100 ? 'bg-emerald-500' :
                    status.docCompliancePercent >= 75 ? 'bg-blue-500' :
                    status.docCompliancePercent >= 50 ? 'bg-amber-500' : 'bg-red-500'
                  }`}
                  style={{ width: `${status.docCompliancePercent}%` }}
                />
              </div>
            </div>
            <span className="text-sm font-medium text-gray-900">{status.docCompliancePercent}%</span>
          </div>
          <p className="text-xs text-gray-500 mt-1">
            {status.docItemsCompleted} of {status.docItemsTotal} items completed
          </p>
        </div>
      )}
    </div>
  );
}
