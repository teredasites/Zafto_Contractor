'use client';

import { useState, useMemo } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft, Check, X, Clock, FileText, Shield,
  AlertTriangle, MapPin, Hash, Calendar, Pen,
  ChevronDown, ChevronUp, Loader2,
} from 'lucide-react';
import { useProjectEstimate, useEstimateDetail, useEstimates } from '@/lib/hooks/use-estimates';
import {
  formatCurrency, formatDate, ESTIMATE_STATUS_LABELS,
  type EstimateStatus, type EstimateAreaData, type EstimateLineItemData,
} from '@/lib/hooks/mappers';

// ==================== STATUS CONFIG ====================

const statusConfig: Record<EstimateStatus, { label: string; color: string; bg: string; border: string }> = {
  draft: { label: 'Draft', color: 'text-gray-700', bg: 'bg-gray-50', border: 'border-gray-200' },
  sent: { label: 'Pending Review', color: 'text-amber-700', bg: 'bg-amber-50', border: 'border-amber-200' },
  approved: { label: 'Approved', color: 'text-green-700', bg: 'bg-green-50', border: 'border-green-200' },
  declined: { label: 'Declined', color: 'text-red-700', bg: 'bg-red-50', border: 'border-red-200' },
  revised: { label: 'Revised', color: 'text-blue-700', bg: 'bg-blue-50', border: 'border-blue-200' },
  completed: { label: 'Completed', color: 'text-green-700', bg: 'bg-green-50', border: 'border-green-200' },
};

// ==================== LOADING SKELETON ====================

function EstimateSkeleton() {
  return (
    <div className="space-y-5 animate-pulse">
      <div>
        <div className="h-4 w-28 bg-gray-200 rounded mb-3" />
        <div className="h-6 w-56 bg-gray-200 rounded" />
        <div className="h-4 w-40 bg-gray-100 rounded mt-2" />
      </div>
      <div className="bg-white rounded-xl border border-gray-100 p-4">
        <div className="h-4 bg-gray-100 rounded w-full mb-3" />
        <div className="h-4 bg-gray-100 rounded w-3/4 mb-3" />
        <div className="h-4 bg-gray-100 rounded w-1/2" />
      </div>
      <div className="bg-white rounded-xl border border-gray-100 p-4">
        <div className="h-5 bg-gray-100 rounded w-32 mb-4" />
        <div className="space-y-2">
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="h-10 bg-gray-50 rounded" />
          ))}
        </div>
      </div>
      <div className="bg-white rounded-xl border border-gray-100 p-4">
        <div className="h-4 bg-gray-100 rounded w-24 mb-3" />
        <div className="h-4 bg-gray-100 rounded w-48" />
      </div>
    </div>
  );
}

// ==================== AREA LINE ITEMS SECTION ====================

function AreaSection({
  area,
  lineItems,
  defaultOpen,
}: {
  area: EstimateAreaData | null;
  lineItems: EstimateLineItemData[];
  defaultOpen: boolean;
}) {
  const [open, setOpen] = useState(defaultOpen);
  const areaTotal = lineItems.reduce((sum, li) => sum + li.lineTotal, 0);

  return (
    <div className="border border-gray-100 rounded-lg overflow-hidden">
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between px-4 py-3 bg-gray-50 hover:bg-gray-100 transition-colors text-left"
      >
        <div className="flex items-center gap-2">
          <span className="text-sm font-semibold text-gray-900">
            {area ? area.name : 'General Items'}
          </span>
          {area && area.floorSf > 0 && (
            <span className="text-xs text-gray-400">{area.floorSf} SF</span>
          )}
          <span className="text-xs text-gray-400">({lineItems.length} item{lineItems.length !== 1 ? 's' : ''})</span>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-sm font-bold text-gray-900">{formatCurrency(areaTotal)}</span>
          {open ? <ChevronUp size={16} className="text-gray-400" /> : <ChevronDown size={16} className="text-gray-400" />}
        </div>
      </button>
      {open && (
        <div className="divide-y divide-gray-50">
          {/* Header row */}
          <div className="grid grid-cols-12 gap-2 px-4 py-2 bg-gray-50/50 text-xs text-gray-400 font-medium">
            <div className="col-span-5">Description</div>
            <div className="col-span-2 text-center">Qty</div>
            <div className="col-span-2 text-center">Unit</div>
            <div className="col-span-3 text-right">Amount</div>
          </div>
          {lineItems.map(li => (
            <div key={li.id} className="grid grid-cols-12 gap-2 px-4 py-3 items-center">
              <div className="col-span-5">
                <p className="text-sm text-gray-800">{li.description}</p>
                <p className="text-xs text-gray-400 capitalize">{li.actionType}</p>
              </div>
              <div className="col-span-2 text-center text-sm text-gray-600">
                {li.quantity}
              </div>
              <div className="col-span-2 text-center text-xs text-gray-400 uppercase">
                {li.unitCode}
              </div>
              <div className="col-span-3 text-right text-sm font-medium text-gray-900">
                {formatCurrency(li.lineTotal)}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ==================== MAIN PAGE ====================

export default function EstimateDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { estimateId, loading: lookupLoading } = useProjectEstimate(id);
  const { estimate, areas, lineItems, loading: detailLoading } = useEstimateDetail(estimateId);
  const { approveEstimate, rejectEstimate, error: actionError } = useEstimates();

  const [signatureName, setSignatureName] = useState('');
  const [agreed, setAgreed] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [showDeclineConfirm, setShowDeclineConfirm] = useState(false);
  const [declineReason, setDeclineReason] = useState('');
  const [actionCompleted, setActionCompleted] = useState<'approved' | 'declined' | null>(null);

  const loading = lookupLoading || detailLoading;

  // Group line items by area
  const groupedItems = useMemo(() => {
    const groups: { area: EstimateAreaData | null; items: EstimateLineItemData[] }[] = [];

    // Items with area IDs grouped under their area
    const areaMap = new Map<string, EstimateLineItemData[]>();
    const unassigned: EstimateLineItemData[] = [];

    lineItems.forEach(li => {
      if (li.areaId) {
        const existing = areaMap.get(li.areaId) || [];
        existing.push(li);
        areaMap.set(li.areaId, existing);
      } else {
        unassigned.push(li);
      }
    });

    // Add area groups in sort order
    areas.forEach(area => {
      const items = areaMap.get(area.id) || [];
      if (items.length > 0) {
        groups.push({ area, items });
      }
    });

    // Add unassigned items as "General" group
    if (unassigned.length > 0) {
      groups.push({ area: null, items: unassigned });
    }

    return groups;
  }, [areas, lineItems]);

  // Expiration check
  const isExpiring = useMemo(() => {
    if (!estimate?.validUntil) return false;
    const expiry = new Date(estimate.validUntil);
    const now = new Date();
    const daysLeft = Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
    return daysLeft <= 7 && daysLeft > 0;
  }, [estimate?.validUntil]);

  const isExpired = useMemo(() => {
    if (!estimate?.validUntil) return false;
    return new Date(estimate.validUntil) < new Date();
  }, [estimate?.validUntil]);

  const daysUntilExpiry = useMemo(() => {
    if (!estimate?.validUntil) return null;
    const expiry = new Date(estimate.validUntil);
    const now = new Date();
    return Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  }, [estimate?.validUntil]);

  const canApprove = estimate?.status === 'sent' || estimate?.status === 'revised';
  const canSign = signatureName.trim().length >= 2 && agreed;

  const handleApprove = async () => {
    if (!estimate || !canSign) return;
    setSubmitting(true);
    await approveEstimate(estimate.id);
    setSubmitting(false);
    setActionCompleted('approved');
  };

  const handleDecline = async () => {
    if (!estimate) return;
    setSubmitting(true);
    await rejectEstimate(estimate.id);
    setSubmitting(false);
    setShowDeclineConfirm(false);
    setActionCompleted('declined');
  };

  // ==================== RENDER ====================

  return (
    <div className="space-y-5">
      {/* Back Link */}
      <div>
        <Link
          href={`/projects/${id}`}
          className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3"
        >
          <ArrowLeft size={16} /> Back to Project
        </Link>
      </div>

      {/* Loading State */}
      {loading && <EstimateSkeleton />}

      {/* No Estimate Found */}
      {!loading && !estimate && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <FileText size={32} className="mx-auto text-gray-300 mb-3" />
          <h3 className="font-semibold text-gray-900 text-sm">No estimate available</h3>
          <p className="text-xs text-gray-500 mt-1">
            Your contractor has not yet sent an estimate for this project.
          </p>
        </div>
      )}

      {/* Estimate Content */}
      {!loading && estimate && (
        <>
          {/* Header */}
          <div className="flex items-start justify-between">
            <div>
              <h1 className="text-xl font-bold text-gray-900">{estimate.title}</h1>
              <p className="text-sm text-gray-500 mt-0.5">
                {estimate.estimateNumber}{estimate.customerName ? ` for ${estimate.customerName}` : ''}
              </p>
            </div>
            <span className={`flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full ${statusConfig[estimate.status].bg} ${statusConfig[estimate.status].color}`}>
              {ESTIMATE_STATUS_LABELS[estimate.status]}
            </span>
          </div>

          {/* Action Completed Banner */}
          {actionCompleted === 'approved' && (
            <div className="bg-green-50 border border-green-200 rounded-xl p-6 text-center">
              <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-3">
                <Check size={24} className="text-green-600" />
              </div>
              <h2 className="text-lg font-bold text-green-800">Estimate Approved</h2>
              <p className="text-sm text-green-600 mt-1">
                Your contractor has been notified and will reach out to schedule.
              </p>
              <p className="text-xs text-green-500 mt-2">
                Signed by {signatureName} on {new Date().toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
              </p>
            </div>
          )}

          {actionCompleted === 'declined' && (
            <div className="bg-red-50 border border-red-200 rounded-xl p-6 text-center">
              <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-3">
                <X size={24} className="text-red-600" />
              </div>
              <h2 className="text-lg font-bold text-red-800">Estimate Declined</h2>
              <p className="text-sm text-red-600 mt-1">
                Your contractor has been notified. They may reach out with a revised estimate.
              </p>
            </div>
          )}

          {/* Already Approved (from DB state, not just-now action) */}
          {!actionCompleted && estimate.status === 'approved' && (
            <div className="bg-green-50 border border-green-200 rounded-xl p-4 flex items-center gap-3">
              <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center flex-shrink-0">
                <Check size={20} className="text-green-600" />
              </div>
              <div>
                <p className="text-sm font-semibold text-green-800">Estimate Approved</p>
                {estimate.approvedAt && (
                  <p className="text-xs text-green-600">Approved on {formatDate(estimate.approvedAt)}</p>
                )}
              </div>
            </div>
          )}

          {/* Already Declined (from DB state) */}
          {!actionCompleted && estimate.status === 'declined' && (
            <div className="bg-red-50 border border-red-200 rounded-xl p-4 flex items-center gap-3">
              <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center flex-shrink-0">
                <X size={20} className="text-red-600" />
              </div>
              <div>
                <p className="text-sm font-semibold text-red-800">Estimate Declined</p>
                {estimate.declinedAt && (
                  <p className="text-xs text-red-600">Declined on {formatDate(estimate.declinedAt)}</p>
                )}
              </div>
            </div>
          )}

          {/* Expiration Warning */}
          {canApprove && !actionCompleted && isExpiring && !isExpired && (
            <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 flex items-center gap-2">
              <Clock size={16} className="text-amber-600 flex-shrink-0" />
              <p className="text-xs text-amber-700">
                This estimate expires in <strong>{daysUntilExpiry} day{daysUntilExpiry !== 1 ? 's' : ''}</strong> ({formatDate(estimate.validUntil)})
              </p>
            </div>
          )}

          {canApprove && !actionCompleted && isExpired && (
            <div className="bg-red-50 border border-red-200 rounded-xl p-3 flex items-center gap-2">
              <AlertTriangle size={16} className="text-red-600 flex-shrink-0" />
              <p className="text-xs text-red-700">
                This estimate expired on <strong>{formatDate(estimate.validUntil)}</strong>. Please contact your contractor for an updated estimate.
              </p>
            </div>
          )}

          {/* Error Banner */}
          {actionError && (
            <div className="bg-red-50 border border-red-200 rounded-xl p-3 flex items-center gap-2">
              <AlertTriangle size={16} className="text-red-600 flex-shrink-0" />
              <p className="text-xs text-red-700">{actionError}</p>
            </div>
          )}

          {/* Estimate Details Card */}
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
            <h3 className="font-semibold text-sm text-gray-900 mb-3 flex items-center gap-2">
              <FileText size={16} className="text-gray-400" />
              Estimate Details
            </h3>
            <div className="space-y-2">
              {estimate.propertyAddress && (
                <div className="flex items-start gap-2 text-sm">
                  <MapPin size={14} className="text-gray-400 mt-0.5 flex-shrink-0" />
                  <span className="text-gray-600">{estimate.propertyAddress}</span>
                </div>
              )}
              <div className="flex items-center gap-2 text-sm">
                <Hash size={14} className="text-gray-400 flex-shrink-0" />
                <span className="text-gray-600">{estimate.estimateNumber}</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <Calendar size={14} className="text-gray-400 flex-shrink-0" />
                <span className="text-gray-600">
                  Created {formatDate(estimate.createdAt)}
                  {estimate.validUntil && !isExpired && (
                    <span className="text-gray-400"> &middot; Valid until {formatDate(estimate.validUntil)}</span>
                  )}
                </span>
              </div>
              {estimate.estimateType === 'insurance' && (
                <div className="flex items-center gap-2 text-sm">
                  <Shield size={14} className="text-amber-500 flex-shrink-0" />
                  <span className="text-amber-700 font-medium">Insurance Estimate</span>
                </div>
              )}
            </div>
          </div>

          {/* Line Items by Area */}
          {groupedItems.length > 0 && (
            <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
              <h3 className="font-semibold text-sm text-gray-900 mb-3">Scope of Work</h3>
              <div className="space-y-2">
                {groupedItems.map((group, i) => (
                  <AreaSection
                    key={group.area?.id || 'general'}
                    area={group.area}
                    lineItems={group.items}
                    defaultOpen={i === 0}
                  />
                ))}
              </div>
            </div>
          )}

          {/* No line items fallback */}
          {groupedItems.length === 0 && (
            <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-6 text-center">
              <FileText size={24} className="mx-auto text-gray-300 mb-2" />
              <p className="text-sm text-gray-500">No line items have been added to this estimate yet.</p>
            </div>
          )}

          {/* Totals Card */}
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
            <h3 className="font-semibold text-sm text-gray-900 mb-3">Cost Summary</h3>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">Subtotal</span>
                <span className="font-medium text-gray-700">{formatCurrency(estimate.subtotal)}</span>
              </div>
              {estimate.overheadAmount > 0 && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Overhead</span>
                  <span className="font-medium text-gray-700">{formatCurrency(estimate.overheadAmount)}</span>
                </div>
              )}
              {estimate.profitAmount > 0 && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Profit</span>
                  <span className="font-medium text-gray-700">{formatCurrency(estimate.profitAmount)}</span>
                </div>
              )}
              {estimate.taxAmount > 0 && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Tax</span>
                  <span className="font-medium text-gray-700">{formatCurrency(estimate.taxAmount)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm border-t border-gray-100 pt-2">
                <span className="font-semibold text-gray-900">Total</span>
                <span className="font-bold text-lg text-gray-900">{formatCurrency(estimate.grandTotal)}</span>
              </div>
            </div>
          </div>

          {/* Contractor Notes */}
          {estimate.notes && (
            <div className="bg-gray-50 rounded-xl border border-gray-100 p-4">
              <h3 className="font-semibold text-sm text-gray-900 mb-2">Contractor Notes</h3>
              <p className="text-sm text-gray-600 leading-relaxed whitespace-pre-wrap">{estimate.notes}</p>
            </div>
          )}

          {/* Approval / Decline Section */}
          {canApprove && !actionCompleted && !isExpired && (
            <>
              {/* Digital Signature */}
              <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
                <h3 className="font-semibold text-sm text-gray-900 mb-1 flex items-center gap-2">
                  <Pen size={16} className="text-gray-400" />
                  Digital Signature
                </h3>
                <p className="text-xs text-gray-500 mb-4">
                  Type your full name below to approve this estimate.
                </p>

                {/* Signature Input */}
                <div className="mb-4">
                  <label htmlFor="signature-name" className="block text-xs font-medium text-gray-700 mb-1">
                    Full Name
                  </label>
                  <input
                    id="signature-name"
                    type="text"
                    value={signatureName}
                    onChange={(e) => setSignatureName(e.target.value)}
                    placeholder="Type your full legal name"
                    className="w-full px-3 py-2.5 border border-gray-200 rounded-lg text-sm text-gray-900 placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all"
                  />
                  {signatureName.trim().length > 0 && (
                    <div className="mt-2 px-3 py-2 bg-gray-50 rounded-lg border border-gray-100">
                      <p className="text-lg text-gray-900" style={{ fontFamily: 'cursive' }}>
                        {signatureName}
                      </p>
                    </div>
                  )}
                </div>

                {/* Agreement Checkbox */}
                <label className="flex items-start gap-3 cursor-pointer group">
                  <input
                    type="checkbox"
                    checked={agreed}
                    onChange={(e) => setAgreed(e.target.checked)}
                    className="mt-0.5 w-4 h-4 rounded border-gray-300 text-orange-500 focus:ring-orange-500/20"
                  />
                  <span className="text-xs text-gray-600 leading-relaxed">
                    I, <strong>{signatureName || '(your name)'}</strong>, authorize this estimate
                    for <strong>{formatCurrency(estimate.grandTotal)}</strong> and agree to the scope
                    of work described above. I understand this constitutes a binding agreement.
                  </span>
                </label>
              </div>

              {/* Action Buttons */}
              <div className="space-y-2">
                <button
                  onClick={handleApprove}
                  disabled={!canSign || submitting}
                  className={`w-full py-3.5 font-bold rounded-xl transition-all text-sm flex items-center justify-center gap-2 ${
                    canSign && !submitting
                      ? 'bg-orange-500 hover:bg-orange-600 text-white shadow-sm'
                      : 'bg-gray-100 text-gray-400 cursor-not-allowed'
                  }`}
                >
                  {submitting ? (
                    <>
                      <Loader2 size={16} className="animate-spin" />
                      Processing...
                    </>
                  ) : (
                    <>
                      <Check size={16} />
                      Approve Estimate -- {formatCurrency(estimate.grandTotal)}
                    </>
                  )}
                </button>

                {!showDeclineConfirm ? (
                  <button
                    onClick={() => setShowDeclineConfirm(true)}
                    disabled={submitting}
                    className="w-full py-3 text-sm font-medium text-gray-500 hover:text-red-600 hover:bg-red-50 rounded-xl transition-all"
                  >
                    Decline Estimate
                  </button>
                ) : (
                  <div className="bg-red-50 border border-red-200 rounded-xl p-4 space-y-3">
                    <p className="text-sm font-medium text-red-800">Are you sure you want to decline?</p>
                    <p className="text-xs text-red-600">
                      Your contractor will be notified. They may follow up with a revised estimate.
                    </p>
                    <textarea
                      value={declineReason}
                      onChange={(e) => setDeclineReason(e.target.value)}
                      placeholder="Reason for declining (optional)"
                      rows={2}
                      className="w-full px-3 py-2 border border-red-200 rounded-lg text-sm text-gray-900 placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-500 bg-white resize-none"
                    />
                    <div className="flex gap-2">
                      <button
                        onClick={() => setShowDeclineConfirm(false)}
                        disabled={submitting}
                        className="flex-1 py-2.5 text-sm font-medium text-gray-700 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-all"
                      >
                        Cancel
                      </button>
                      <button
                        onClick={handleDecline}
                        disabled={submitting}
                        className="flex-1 py-2.5 text-sm font-bold text-white bg-red-500 hover:bg-red-600 rounded-lg transition-all flex items-center justify-center gap-1.5"
                      >
                        {submitting ? (
                          <>
                            <Loader2 size={14} className="animate-spin" />
                            Declining...
                          </>
                        ) : (
                          <>
                            <X size={14} />
                            Confirm Decline
                          </>
                        )}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </>
          )}

          {/* Revised Estimate Note */}
          {!actionCompleted && estimate.status === 'revised' && (
            <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 flex items-center gap-3">
              <FileText size={20} className="text-blue-500 flex-shrink-0" />
              <div>
                <p className="text-sm font-semibold text-blue-800">Revised Estimate</p>
                <p className="text-xs text-blue-600">
                  Your contractor has revised this estimate. Please review the updated scope and pricing above.
                </p>
              </div>
            </div>
          )}

          {/* Completed Note */}
          {!actionCompleted && estimate.status === 'completed' && (
            <div className="bg-green-50 border border-green-200 rounded-xl p-4 flex items-center gap-3">
              <Check size={20} className="text-green-500 flex-shrink-0" />
              <div>
                <p className="text-sm font-semibold text-green-800">Project Completed</p>
                <p className="text-xs text-green-600">
                  This estimate has been fulfilled. Thank you for your business.
                </p>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
