'use client';
import { useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft, AlertCircle, CheckCircle2, Clock, DollarSign, CreditCard, Upload, Send, X, ShieldCheck, Loader2 } from 'lucide-react';
import { useRentPayments } from '@/lib/hooks/use-rent-payments';
import { formatCurrency, formatDate } from '@/lib/hooks/mappers';
import {
  chargeTypeLabel, paymentMethodLabel, verificationStatusLabel,
  type PaymentMethodType,
} from '@/lib/hooks/tenant-mappers';

const chargeStatusConfig: Record<string, { label: string; color: string }> = {
  pending: { label: 'Pending', color: 'var(--text-muted)' },
  partial: { label: 'Partial', color: 'var(--warning)' },
  paid: { label: 'Paid', color: 'var(--success)' },
  overdue: { label: 'Overdue', color: 'var(--danger)' },
  waived: { label: 'Waived', color: 'var(--text-muted)' },
  void: { label: 'Void', color: 'var(--text-muted)' },
};

const paymentStatusConfig: Record<string, { label: string; color: string }> = {
  pending: { label: 'Pending', color: 'var(--text-muted)' },
  processing: { label: 'Processing', color: 'var(--warning)' },
  completed: { label: 'Completed', color: 'var(--success)' },
  failed: { label: 'Failed', color: 'var(--danger)' },
  refunded: { label: 'Refunded', color: 'var(--text-muted)' },
};

// Offline payment methods the tenant can select
const OFFLINE_METHODS: { value: PaymentMethodType; label: string }[] = [
  { value: 'cash', label: 'Cash' },
  { value: 'check', label: 'Check' },
  { value: 'money_order', label: 'Money Order' },
  { value: 'zelle', label: 'Zelle' },
  { value: 'venmo', label: 'Venmo' },
  { value: 'cashapp', label: 'Cash App' },
  { value: 'direct_deposit', label: 'Direct Deposit / Bank Transfer' },
  { value: 'wire_transfer', label: 'Wire Transfer' },
  { value: 'other', label: 'Other' },
];

const verificationStatusConfig: Record<string, { label: string; color: string }> = {
  auto_verified: { label: 'Verified', color: 'var(--success)' },
  pending_verification: { label: 'Pending Verification', color: 'var(--warning)' },
  verified: { label: 'Verified', color: 'var(--success)' },
  disputed: { label: 'Disputed — More Info Needed', color: 'var(--danger)' },
  rejected: { label: 'Rejected', color: 'var(--danger)' },
};

export default function RentChargeDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { charge, payments, loading, reportPayment, uploadProof } = useRentPayments(id);

  // Report Payment form state
  const [showReportForm, setShowReportForm] = useState(false);
  const [reportMethod, setReportMethod] = useState<PaymentMethodType>('check');
  const [reportAmount, setReportAmount] = useState('');
  const [reportDate, setReportDate] = useState(new Date().toISOString().split('T')[0]);
  const [reportReference, setReportReference] = useState('');
  const [reportNotes, setReportNotes] = useState('');
  const [proofFile, setProofFile] = useState<File | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  const handleReportSubmit = async () => {
    if (!reportAmount || parseFloat(reportAmount) <= 0) {
      setSubmitError('Please enter a valid amount.');
      return;
    }
    setSubmitting(true);
    setSubmitError(null);

    let proofUrl: string | undefined;
    if (proofFile) {
      const url = await uploadProof(proofFile);
      if (url) proofUrl = url;
    }

    const result = await reportPayment({
      amount: parseFloat(reportAmount),
      paymentMethod: reportMethod,
      paymentDate: reportDate,
      reference: reportReference || undefined,
      proofUrl,
      notes: reportNotes || undefined,
    });

    setSubmitting(false);
    if (result.success) {
      setSubmitSuccess(true);
      setShowReportForm(false);
      // Reset form
      setReportAmount('');
      setReportReference('');
      setReportNotes('');
      setProofFile(null);
    } else {
      setSubmitError(result.error || 'Failed to report payment.');
    }
  };

  const handlePayNow = () => {
    alert('Online payments are not yet configured. Please contact your property manager for payment options.');
  };

  // Loading skeleton
  if (loading) {
    return (
      <div className="space-y-5 animate-pulse">
        <div className="h-4 rounded w-28" style={{ backgroundColor: 'var(--border-light)' }} />
        <div className="flex items-start justify-between">
          <div className="space-y-2">
            <div className="h-6 rounded w-40" style={{ backgroundColor: 'var(--border-light)' }} />
            <div className="h-4 rounded w-56" style={{ backgroundColor: 'var(--bg-secondary)' }} />
          </div>
          <div className="h-6 rounded-full w-20" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        </div>
        <div className="rounded-xl overflow-hidden" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
          <div className="p-4" style={{ borderBottom: '1px solid var(--border-light)' }}>
            <div className="h-4 rounded w-28" style={{ backgroundColor: 'var(--border-light)' }} />
          </div>
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="px-4 py-3 flex justify-between">
              <div className="h-4 rounded w-32" style={{ backgroundColor: 'var(--bg-secondary)' }} />
              <div className="h-4 rounded w-20" style={{ backgroundColor: 'var(--bg-secondary)' }} />
            </div>
          ))}
        </div>
        <div className="rounded-xl p-5" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
          <div className="h-4 rounded w-32 mb-3" style={{ backgroundColor: 'var(--border-light)' }} />
          <div className="h-14 rounded-xl" style={{ backgroundColor: 'var(--bg-secondary)' }} />
          <div className="h-14 rounded-xl mt-2" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        </div>
      </div>
    );
  }

  // Charge not found
  if (!charge) {
    return (
      <div className="space-y-5">
        <Link href="/rent" className="flex items-center gap-1 text-sm" style={{ color: 'var(--text-muted)' }}>
          <ArrowLeft size={16} /> Back to Rent
        </Link>
        <div className="rounded-xl p-8 text-center" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
          <AlertCircle size={32} className="mx-auto mb-3" style={{ color: 'var(--border-light)' }} />
          <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>Charge not found</h3>
          <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>
            This charge may have been removed or the link is incorrect.
          </p>
        </div>
      </div>
    );
  }

  const config = chargeStatusConfig[charge.status] || chargeStatusConfig.pending;
  const remaining = charge.amount - charge.paidAmount;
  const showPayButton = charge.status === 'pending' || charge.status === 'partial' || charge.status === 'overdue';

  return (
    <div className="space-y-5">
      {/* Back Link */}
      <Link href="/rent" className="flex items-center gap-1 text-sm hover:opacity-80" style={{ color: 'var(--text-muted)' }}>
        <ArrowLeft size={16} /> Back to Rent
      </Link>

      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-xl font-bold" style={{ color: 'var(--text)' }}>
            {chargeTypeLabel(charge.chargeType)}
          </h1>
          <p className="text-sm mt-0.5" style={{ color: 'var(--text-muted)' }}>
            Due {formatDate(charge.dueDate)}
          </p>
        </div>
        <span
          className="flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full"
          style={{
            color: config.color,
            backgroundColor: `color-mix(in srgb, ${config.color} 12%, transparent)`,
          }}
        >
          {charge.status === 'overdue' && <AlertCircle size={12} />}
          {charge.status === 'paid' && <CheckCircle2 size={12} />}
          {config.label}
        </span>
      </div>

      {/* Charge Details Card */}
      <div className="rounded-xl overflow-hidden" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
        <div className="p-4" style={{ borderBottom: '1px solid var(--border-light)' }}>
          <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>Charge Details</h3>
        </div>
        <div className="divide-y" style={{ borderColor: 'var(--bg-secondary)' }}>
          <div className="px-4 py-3 flex justify-between">
            <span className="text-sm" style={{ color: 'var(--text-muted)' }}>Type</span>
            <span className="text-sm font-medium" style={{ color: 'var(--text)' }}>
              {chargeTypeLabel(charge.chargeType)}
            </span>
          </div>
          <div className="px-4 py-3 flex justify-between" style={{ borderTop: '1px solid var(--bg-secondary)' }}>
            <span className="text-sm" style={{ color: 'var(--text-muted)' }}>Amount</span>
            <span className="text-sm font-bold" style={{ color: 'var(--text)' }}>
              {formatCurrency(charge.amount)}
            </span>
          </div>
          <div className="px-4 py-3 flex justify-between" style={{ borderTop: '1px solid var(--bg-secondary)' }}>
            <span className="text-sm" style={{ color: 'var(--text-muted)' }}>Due Date</span>
            <span className="text-sm font-medium" style={{ color: 'var(--text)' }}>
              {formatDate(charge.dueDate)}
            </span>
          </div>
          <div className="px-4 py-3 flex justify-between" style={{ borderTop: '1px solid var(--bg-secondary)' }}>
            <span className="text-sm" style={{ color: 'var(--text-muted)' }}>Status</span>
            <span className="text-sm font-medium" style={{ color: config.color }}>{config.label}</span>
          </div>
          <div className="px-4 py-3 flex justify-between" style={{ borderTop: '1px solid var(--bg-secondary)' }}>
            <span className="text-sm" style={{ color: 'var(--text-muted)' }}>Paid</span>
            <span className="text-sm font-medium" style={{ color: 'var(--success)' }}>
              {formatCurrency(charge.paidAmount)}
            </span>
          </div>
          <div className="px-4 py-3 flex justify-between" style={{ borderTop: '1px solid var(--bg-secondary)' }}>
            <span className="text-sm" style={{ color: 'var(--text-muted)' }}>Remaining</span>
            <span className="text-sm font-bold" style={{ color: remaining > 0 ? 'var(--danger)' : 'var(--success)' }}>
              {formatCurrency(remaining)}
            </span>
          </div>
        </div>
      </div>

      {/* Payment History */}
      <div className="rounded-xl overflow-hidden" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
        <div className="p-4" style={{ borderBottom: '1px solid var(--border-light)' }}>
          <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>Payment History</h3>
        </div>
        {payments.length === 0 ? (
          <div className="px-4 py-8 text-center">
            <Clock size={24} className="mx-auto mb-2" style={{ color: 'var(--border-light)' }} />
            <p className="text-sm" style={{ color: 'var(--text-muted)' }}>No payments recorded yet</p>
          </div>
        ) : (
          <div>
            {payments.map((payment, idx) => {
              const pConfig = paymentStatusConfig[payment.status] || paymentStatusConfig.pending;
              return (
                <div
                  key={payment.id}
                  className="flex items-center gap-3 px-4 py-3"
                  style={idx > 0 ? { borderTop: '1px solid var(--bg-secondary)' } : undefined}
                >
                  <div className="p-2 rounded-lg" style={{ backgroundColor: 'var(--bg-secondary)' }}>
                    <CreditCard size={16} style={{ color: 'var(--text-muted)' }} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="text-sm font-medium" style={{ color: 'var(--text)' }}>
                        {formatCurrency(payment.amount)}
                      </p>
                      <span
                        className="text-[10px] font-medium px-2 py-0.5 rounded-full"
                        style={{
                          color: pConfig.color,
                          backgroundColor: `color-mix(in srgb, ${pConfig.color} 12%, transparent)`,
                        }}
                      >
                        {pConfig.label}
                      </span>
                    </div>
                    <div className="flex items-center gap-1.5 mt-0.5">
                      <p className="text-xs" style={{ color: 'var(--text-muted)' }}>
                        {paymentMethodLabel(payment.paymentMethod)}
                        {payment.paidAt ? ` · ${formatDate(payment.paidAt)}` : payment.paymentDate ? ` · ${formatDate(payment.paymentDate)}` : ` · ${formatDate(payment.createdAt)}`}
                      </p>
                      {payment.verificationStatus && payment.verificationStatus !== 'auto_verified' && (
                        <span
                          className="text-[9px] font-medium px-1.5 py-0.5 rounded-full"
                          style={{
                            color: (verificationStatusConfig[payment.verificationStatus] || verificationStatusConfig.pending_verification).color,
                            backgroundColor: `color-mix(in srgb, ${(verificationStatusConfig[payment.verificationStatus] || verificationStatusConfig.pending_verification).color} 12%, transparent)`,
                          }}
                        >
                          {verificationStatusLabel(payment.verificationStatus)}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Success Message */}
      {submitSuccess && (
        <div className="rounded-xl p-4 flex items-start gap-3" style={{ backgroundColor: 'color-mix(in srgb, var(--success) 10%, transparent)', border: '1px solid color-mix(in srgb, var(--success) 30%, transparent)' }}>
          <ShieldCheck size={20} style={{ color: 'var(--success)', flexShrink: 0, marginTop: 2 }} />
          <div>
            <p className="text-sm font-semibold" style={{ color: 'var(--success)' }}>Payment Reported</p>
            <p className="text-xs mt-0.5" style={{ color: 'var(--text-muted)' }}>
              Your property manager will verify this payment. You&apos;ll be notified once confirmed.
            </p>
          </div>
          <button onClick={() => setSubmitSuccess(false)} className="ml-auto">
            <X size={14} style={{ color: 'var(--text-muted)' }} />
          </button>
        </div>
      )}

      {/* Report Payment Form */}
      {showReportForm && showPayButton && (
        <div className="rounded-xl overflow-hidden" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
          <div className="p-4 flex items-center justify-between" style={{ borderBottom: '1px solid var(--border-light)' }}>
            <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>Report Offline Payment</h3>
            <button onClick={() => { setShowReportForm(false); setSubmitError(null); }}>
              <X size={16} style={{ color: 'var(--text-muted)' }} />
            </button>
          </div>
          <div className="p-4 space-y-4">
            {/* Payment Method */}
            <div>
              <label className="block text-xs font-medium mb-1.5" style={{ color: 'var(--text-muted)' }}>
                Payment Method *
              </label>
              <select
                value={reportMethod}
                onChange={e => setReportMethod(e.target.value as PaymentMethodType)}
                className="w-full rounded-lg px-3 py-2.5 text-sm"
                style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text)', border: '1px solid var(--border-light)' }}
              >
                {OFFLINE_METHODS.map(m => (
                  <option key={m.value} value={m.value}>{m.label}</option>
                ))}
              </select>
            </div>

            {/* Amount */}
            <div>
              <label className="block text-xs font-medium mb-1.5" style={{ color: 'var(--text-muted)' }}>
                Amount Paid *
              </label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm" style={{ color: 'var(--text-muted)' }}>$</span>
                <input
                  type="number"
                  step="0.01"
                  min="0.01"
                  max={remaining}
                  value={reportAmount}
                  onChange={e => setReportAmount(e.target.value)}
                  placeholder={remaining.toFixed(2)}
                  className="w-full rounded-lg pl-7 pr-3 py-2.5 text-sm"
                  style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text)', border: '1px solid var(--border-light)' }}
                />
              </div>
            </div>

            {/* Date Paid */}
            <div>
              <label className="block text-xs font-medium mb-1.5" style={{ color: 'var(--text-muted)' }}>
                Date Paid *
              </label>
              <input
                type="date"
                value={reportDate}
                onChange={e => setReportDate(e.target.value)}
                className="w-full rounded-lg px-3 py-2.5 text-sm"
                style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text)', border: '1px solid var(--border-light)' }}
              />
            </div>

            {/* Reference Number */}
            <div>
              <label className="block text-xs font-medium mb-1.5" style={{ color: 'var(--text-muted)' }}>
                Reference / Confirmation # (optional)
              </label>
              <input
                type="text"
                value={reportReference}
                onChange={e => setReportReference(e.target.value)}
                placeholder="Check #, Zelle confirmation, etc."
                className="w-full rounded-lg px-3 py-2.5 text-sm"
                style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text)', border: '1px solid var(--border-light)' }}
              />
            </div>

            {/* Proof Upload */}
            <div>
              <label className="block text-xs font-medium mb-1.5" style={{ color: 'var(--text-muted)' }}>
                Proof of Payment (optional)
              </label>
              <label
                className="flex items-center gap-2 px-3 py-2.5 rounded-lg cursor-pointer text-sm"
                style={{ backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border-light)', color: 'var(--text-muted)' }}
              >
                <Upload size={14} />
                {proofFile ? proofFile.name : 'Upload receipt, check photo, or screenshot'}
                <input
                  type="file"
                  accept="image/*,.pdf"
                  className="hidden"
                  onChange={e => setProofFile(e.target.files?.[0] || null)}
                />
              </label>
            </div>

            {/* Notes */}
            <div>
              <label className="block text-xs font-medium mb-1.5" style={{ color: 'var(--text-muted)' }}>
                Notes (optional)
              </label>
              <textarea
                value={reportNotes}
                onChange={e => setReportNotes(e.target.value)}
                placeholder="Any additional details..."
                rows={2}
                className="w-full rounded-lg px-3 py-2.5 text-sm resize-none"
                style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text)', border: '1px solid var(--border-light)' }}
              />
            </div>

            {/* Error */}
            {submitError && (
              <div className="rounded-lg px-3 py-2 text-xs flex items-center gap-2" style={{ backgroundColor: 'color-mix(in srgb, var(--danger) 10%, transparent)', color: 'var(--danger)' }}>
                <AlertCircle size={12} /> {submitError}
              </div>
            )}

            {/* Submit */}
            <button
              onClick={handleReportSubmit}
              disabled={submitting || !reportAmount}
              className="w-full py-3 text-white font-bold rounded-xl transition-all text-sm flex items-center justify-center gap-2 disabled:opacity-50"
              style={{ backgroundColor: 'var(--accent)' }}
            >
              {submitting ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />}
              {submitting ? 'Submitting...' : 'Submit for Verification'}
            </button>

            <p className="text-[10px] text-center" style={{ color: 'var(--text-muted)' }}>
              Your property manager will review and verify this payment.
            </p>
          </div>
        </div>
      )}

      {/* Action Buttons */}
      {showPayButton && !showReportForm && (
        <div className="space-y-2.5">
          {/* Report Offline Payment */}
          <button
            onClick={() => { setShowReportForm(true); setSubmitSuccess(false); setReportAmount(remaining.toFixed(2)); }}
            className="w-full py-3.5 font-bold rounded-xl transition-all text-sm flex items-center justify-center gap-2"
            style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text)', border: '1px solid var(--border-light)' }}
          >
            <ShieldCheck size={16} />
            Report Offline Payment
          </button>

          {/* Pay Now (Stripe — disabled for now) */}
          <button
            onClick={handlePayNow}
            className="w-full py-3.5 text-white font-bold rounded-xl transition-all text-sm flex items-center justify-center gap-2"
            style={{ backgroundColor: 'var(--accent)' }}
            onMouseEnter={e => (e.currentTarget.style.backgroundColor = 'var(--accent-hover)')}
            onMouseLeave={e => (e.currentTarget.style.backgroundColor = 'var(--accent)')}
          >
            <DollarSign size={16} />
            Pay {formatCurrency(remaining)} Online
          </button>
        </div>
      )}
    </div>
  );
}
