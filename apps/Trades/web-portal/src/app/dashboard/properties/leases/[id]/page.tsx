'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import {
  ArrowLeft,
  FileText,
  RefreshCcw,
  XCircle,
  Calendar,
  DollarSign,
  Clock,
  CheckCircle,
  Download,
  AlertTriangle,
  Loader2,
  CreditCard,
  Ban,
  Shield,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useLeases, useLease } from '@/lib/hooks/use-leases';
import { leaseStatusLabels } from '@/lib/hooks/pm-mappers';
import type { LeaseData, LeaseDocumentData } from '@/lib/hooks/pm-mappers';
import { useTranslation } from '@/lib/translations';

type LeaseStatus = LeaseData['status'];

const statusConfig: Record<LeaseStatus, { label: string; color: string; bgColor: string }> = {
  draft: { label: 'Draft', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
  active: { label: 'Active', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  expired: { label: 'Expired', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  terminated: { label: 'Terminated', color: 'text-slate-700 dark:text-slate-300', bgColor: 'bg-slate-100 dark:bg-slate-900/30' },
  renewed: { label: 'Renewed', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
};

const lateFeeTypeLabels: Record<LeaseData['lateFeeType'], string> = {
  flat: 'Flat Fee',
  percent: 'Percentage',
  daily: 'Daily',
  none: 'None',
};

const processorFeeLabels: Record<LeaseData['paymentProcessorFee'], string> = {
  landlord: 'Landlord Pays',
  tenant: 'Tenant Pays',
  split: 'Split 50/50',
};

const docTypeLabels: Record<LeaseDocumentData['documentType'], string> = {
  lease_agreement: 'Lease Agreement',
  addendum: 'Addendum',
  notice: 'Notice',
  move_in_checklist: 'Move-In Checklist',
  move_out_checklist: 'Move-Out Checklist',
  other: 'Other',
};

export default function LeaseDetailPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const leaseId = params.id as string;

  const { lease, loading, error } = useLease(leaseId);
  const { renewLease, terminateLease, getLeaseDocuments } = useLeases();

  const [documents, setDocuments] = useState<LeaseDocumentData[]>([]);
  const [docsLoading, setDocsLoading] = useState(true);
  const [showTerminateModal, setShowTerminateModal] = useState(false);
  const [terminateReason, setTerminateReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    if (!leaseId) return;
    let ignore = false;
    const loadDocs = async () => {
      try {
        const docs = await getLeaseDocuments(leaseId);
        if (!ignore) setDocuments(docs);
      } catch {
        // silent
      } finally {
        if (!ignore) setDocsLoading(false);
      }
    };
    loadDocs();
    return () => { ignore = true; };
  }, [leaseId, getLeaseDocuments]);

  const handleRenew = async () => {
    if (!lease) return;
    setActionLoading(true);
    try {
      const newLeaseId = await renewLease(lease.id);
      router.push(`/dashboard/properties/leases/${newLeaseId}`);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to renew lease');
    } finally {
      setActionLoading(false);
    }
  };

  const handleTerminate = async () => {
    if (!lease || !terminateReason.trim()) return;
    setActionLoading(true);
    try {
      await terminateLease(lease.id, terminateReason.trim());
      setShowTerminateModal(false);
      setTerminateReason('');
      router.refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to terminate lease');
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-muted" />
      </div>
    );
  }

  if (!lease) {
    return (
      <div className="text-center py-12">
        <FileText size={48} className="mx-auto text-muted mb-4" />
        <h2 className="text-xl font-semibold text-main">{t('leases.notFound')}</h2>
        <p className="text-muted mt-2">{error || t('leases.notFoundDesc')}</p>
        <Button variant="secondary" className="mt-4" onClick={() => router.push('/dashboard/properties/leases')}>
          {t('common.back')}
        </Button>
      </div>
    );
  }

  const sConfig = statusConfig[lease.status];

  return (
    <div className="space-y-6 pb-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.push('/dashboard/properties/leases')}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
          >
            <ArrowLeft size={20} className="text-muted" />
          </button>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-semibold text-main">
                Lease #{lease.id.slice(0, 8)}
              </h1>
              <span className={cn('px-2.5 py-1 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>
                {sConfig.label}
              </span>
            </div>
            <p className="text-muted mt-1">
              {lease.tenantName || 'Unknown Tenant'} - {lease.propertyAddress || 'N/A'}
              {lease.unitNumber ? `, Unit ${lease.unitNumber}` : ''}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {(lease.status === 'active' || lease.status === 'expired') && (
            <Button onClick={handleRenew} disabled={actionLoading}>
              {actionLoading ? <Loader2 size={16} className="animate-spin" /> : <RefreshCcw size={16} />}
              Renew Lease
            </Button>
          )}
          {(lease.status === 'active' || lease.status === 'draft') && (
            <Button variant="secondary" onClick={() => setShowTerminateModal(true)} disabled={actionLoading}>
              <Ban size={16} />
              Terminate
            </Button>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Terms */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <FileText size={18} className="text-muted" />
                Lease Terms
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-6">
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.leaseType')}</p>
                  <p className="text-sm font-medium text-main">
                    {lease.leaseType === 'fixed' ? 'Fixed Term' : lease.leaseType === 'month_to_month' ? 'Month-to-Month' : 'Week-to-Week'}
                  </p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.startDate')}</p>
                  <p className="text-sm font-medium text-main">{formatDate(lease.startDate)}</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.endDate')}</p>
                  <p className="text-sm font-medium text-main">{lease.endDate ? formatDate(lease.endDate) : 'Open-ended'}</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.monthlyRent')}</p>
                  <p className="text-sm font-semibold text-main">{formatCurrency(lease.rentAmount)}</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Due Day</p>
                  <p className="text-sm font-medium text-main">{lease.rentDueDay}{lease.rentDueDay === 1 ? 'st' : lease.rentDueDay === 2 ? 'nd' : lease.rentDueDay === 3 ? 'rd' : 'th'} of month</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Security Deposit</p>
                  <p className="text-sm font-medium text-main">{formatCurrency(lease.depositAmount)}</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Grace Period</p>
                  <p className="text-sm font-medium text-main">{lease.gracePeriodDays} days</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Late Fee</p>
                  <p className="text-sm font-medium text-main">
                    {lease.lateFeeType === 'none' ? 'None' : `${formatCurrency(lease.lateFeeAmount)} (${lateFeeTypeLabels[lease.lateFeeType]})`}
                  </p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Auto-Renew</p>
                  <p className={cn('text-sm font-medium', lease.autoRenew ? 'text-emerald-600 dark:text-emerald-400' : 'text-muted')}>
                    {lease.autoRenew ? 'Yes' : 'No'}
                  </p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Processing Fee</p>
                  <p className="text-sm font-medium text-main">{processorFeeLabels[lease.paymentProcessorFee]}</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Partial Payments</p>
                  <p className={cn('text-sm font-medium', lease.partialPaymentsAllowed ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400')}>
                    {lease.partialPaymentsAllowed ? 'Allowed' : 'Not Allowed'}
                  </p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Auto-Pay Required</p>
                  <p className={cn('text-sm font-medium', lease.autoPayRequired ? 'text-emerald-600 dark:text-emerald-400' : 'text-muted')}>
                    {lease.autoPayRequired ? 'Required' : 'Optional'}
                  </p>
                </div>
              </div>

              {lease.termsNotes && (
                <div className="mt-6 pt-4 border-t border-main">
                  <p className="text-xs text-muted uppercase tracking-wider mb-2">Additional Terms</p>
                  <p className="text-sm text-main whitespace-pre-wrap">{lease.termsNotes}</p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Documents */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="text-base flex items-center gap-2">
                <Shield size={18} className="text-muted" />
                Documents
              </CardTitle>
            </CardHeader>
            <CardContent>
              {docsLoading ? (
                <div className="space-y-3">
                  {[...Array(2)].map((_, i) => <div key={i} className="skeleton h-12 w-full rounded-lg" />)}
                </div>
              ) : documents.length === 0 ? (
                <div className="text-center py-8">
                  <FileText size={36} className="mx-auto text-muted mb-3 opacity-50" />
                  <p className="text-sm text-muted">No documents attached to this lease</p>
                </div>
              ) : (
                <div className="space-y-2">
                  {documents.map((doc) => (
                    <div
                      key={doc.id}
                      className="flex items-center justify-between p-3 bg-secondary rounded-lg"
                    >
                      <div className="flex items-center gap-3">
                        <FileText size={18} className="text-muted" />
                        <div>
                          <p className="text-sm font-medium text-main">{doc.title}</p>
                          <div className="flex items-center gap-2 text-xs text-muted">
                            <span>{docTypeLabels[doc.documentType]}</span>
                            <span>-</span>
                            <span>{formatDate(doc.createdAt)}</span>
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        {doc.signedByTenant && doc.signedByLandlord && (
                          <span className="text-xs text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
                            <CheckCircle size={12} />
                            Signed
                          </span>
                        )}
                        <Button variant="ghost" size="sm">
                          <Download size={14} />
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Payment History */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <CreditCard size={18} className="text-muted" />
                Payment History
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-center py-8">
                <DollarSign size={36} className="mx-auto text-muted mb-3 opacity-50" />
                <p className="text-sm text-muted">Payment history is available in the Rent Roll</p>
                <Button
                  variant="secondary"
                  size="sm"
                  className="mt-3"
                  onClick={() => router.push('/dashboard/properties/rent')}
                >
                  View Rent Roll
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Quick Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Quick Info</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.status')}</span>
                <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>
                  {sConfig.label}
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.monthlyRent')}</span>
                <span className="font-semibold text-main">{formatCurrency(lease.rentAmount)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.deposit')}</span>
                <span className="text-main">{formatCurrency(lease.depositAmount)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">Deposit Held</span>
                <span className={cn('text-xs font-medium', lease.depositHeld ? 'text-emerald-600' : 'text-amber-600')}>
                  {lease.depositHeld ? 'Yes' : 'No'}
                </span>
              </div>
              {lease.signedAt && (
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Signed</span>
                  <span className="text-main">{formatDate(lease.signedAt)}</span>
                </div>
              )}
              {lease.terminatedAt && (
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Terminated</span>
                  <span className="text-red-600">{formatDate(lease.terminatedAt)}</span>
                </div>
              )}
              {lease.terminationReason && (
                <div className="pt-2 border-t border-main">
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Termination Reason</p>
                  <p className="text-sm text-main">{lease.terminationReason}</p>
                </div>
              )}
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.createdAt')}</span>
                <span className="text-main">{formatDate(lease.createdAt)}</span>
              </div>
            </CardContent>
          </Card>

          {/* Tenant Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Tenant</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="font-medium text-main">{lease.tenantName || 'Unknown Tenant'}</p>
            </CardContent>
          </Card>

          {/* Property Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Property</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-main">{lease.propertyAddress || 'N/A'}</p>
              {lease.unitNumber && <p className="text-sm text-muted mt-1">Unit {lease.unitNumber}</p>}
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Terminate Modal */}
      {showTerminateModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <Card className="w-full max-w-md">
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="flex items-center gap-2">
                <AlertTriangle size={20} className="text-red-500" />
                Terminate Lease
              </CardTitle>
              <Button variant="ghost" size="sm" onClick={() => setShowTerminateModal(false)}>
                <XCircle size={18} />
              </Button>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted">
                This will permanently terminate the lease for {lease.tenantName || 'this tenant'}.
                This action cannot be undone.
              </p>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Reason for Termination *</label>
                <textarea
                  value={terminateReason}
                  onChange={(e) => setTerminateReason(e.target.value)}
                  placeholder="Enter reason for termination..."
                  rows={3}
                  className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent resize-none"
                />
              </div>
              <div className="flex items-center gap-3 pt-2">
                <Button
                  variant="secondary"
                  className="flex-1"
                  onClick={() => setShowTerminateModal(false)}
                  disabled={actionLoading}
                >
                  Cancel
                </Button>
                <Button
                  className="flex-1 bg-red-600 hover:bg-red-700 text-white"
                  onClick={handleTerminate}
                  disabled={actionLoading || !terminateReason.trim()}
                >
                  {actionLoading ? <Loader2 size={16} className="animate-spin" /> : <Ban size={16} />}
                  Terminate
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
