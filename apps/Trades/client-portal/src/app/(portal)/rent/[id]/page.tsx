'use client';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft, AlertCircle, CheckCircle2, Clock, DollarSign, CreditCard } from 'lucide-react';
import { useRentPayments } from '@/lib/hooks/use-rent-payments';
import { formatCurrency, formatDate } from '@/lib/hooks/mappers';
import { chargeTypeLabel, paymentMethodLabel } from '@/lib/hooks/tenant-mappers';

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

export default function RentChargeDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { charge, payments, loading } = useRentPayments(id);

  const handlePayNow = () => {
    alert('Online payment coming soon. Contact your landlord for payment options.');
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
                    <p className="text-xs mt-0.5" style={{ color: 'var(--text-muted)' }}>
                      {paymentMethodLabel(payment.paymentMethod)}
                      {payment.paidAt ? ` · ${formatDate(payment.paidAt)}` : ` · ${formatDate(payment.createdAt)}`}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Pay Now Button */}
      {showPayButton && (
        <button
          onClick={handlePayNow}
          className="w-full py-3.5 text-white font-bold rounded-xl transition-all text-sm flex items-center justify-center gap-2"
          style={{ backgroundColor: 'var(--accent)' }}
          onMouseEnter={e => (e.currentTarget.style.backgroundColor = 'var(--accent-hover)')}
          onMouseLeave={e => (e.currentTarget.style.backgroundColor = 'var(--accent)')}
        >
          <DollarSign size={16} />
          Pay {formatCurrency(remaining)} Now
        </button>
      )}
    </div>
  );
}
