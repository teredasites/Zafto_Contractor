'use client';
import { useRouter } from 'next/navigation';
import { DollarSign, AlertCircle, ChevronRight, Receipt, Clock } from 'lucide-react';
import { useRentCharges } from '@/lib/hooks/use-rent-payments';
import { formatCurrency, formatDate } from '@/lib/hooks/mappers';
import { chargeTypeLabel } from '@/lib/hooks/tenant-mappers';

const statusConfig: Record<string, { label: string; color: string }> = {
  pending: { label: 'Pending', color: 'var(--text-muted)' },
  partial: { label: 'Partial', color: 'var(--warning)' },
  paid: { label: 'Paid', color: 'var(--success)' },
  overdue: { label: 'Overdue', color: 'var(--danger)' },
  waived: { label: 'Waived', color: 'var(--text-muted)' },
  void: { label: 'Void', color: 'var(--text-muted)' },
};

export default function RentPage() {
  const router = useRouter();
  const { charges, balance, overdueCount, loading } = useRentCharges();

  const handlePayNow = () => {
    alert('Online payment coming soon. Contact your landlord for payment options.');
  };

  // Loading skeleton
  if (loading) {
    return (
      <div className="space-y-5">
        <div className="animate-pulse">
          <div className="h-7 rounded w-20 mb-1" style={{ backgroundColor: 'var(--border-light)' }} />
          <div className="h-4 rounded w-40" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        </div>
        <div className="rounded-xl p-5 animate-pulse" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
          <div className="h-3 rounded w-24 mb-2" style={{ backgroundColor: 'var(--bg-secondary)' }} />
          <div className="h-8 rounded w-32 mb-2" style={{ backgroundColor: 'var(--border-light)' }} />
          <div className="h-10 rounded-xl w-full mt-3" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        </div>
        <div className="space-y-2">
          {[1, 2, 3].map(i => (
            <div key={i} className="flex items-center gap-3 rounded-xl p-4 animate-pulse" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
              <div className="w-10 h-10 rounded-xl" style={{ backgroundColor: 'var(--bg-secondary)' }} />
              <div className="flex-1 space-y-2">
                <div className="h-4 rounded w-32" style={{ backgroundColor: 'var(--border-light)' }} />
                <div className="h-3 rounded w-48" style={{ backgroundColor: 'var(--bg-secondary)' }} />
              </div>
              <div className="h-4 rounded w-20" style={{ backgroundColor: 'var(--border-light)' }} />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold" style={{ color: 'var(--text)' }}>Rent</h1>
        <p className="text-sm mt-0.5" style={{ color: 'var(--text-muted)' }}>
          {charges.length} charge{charges.length !== 1 ? 's' : ''}
        </p>
      </div>

      {/* Balance Card */}
      <div className="rounded-xl p-5" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
        <p className="text-xs font-medium" style={{ color: 'var(--text-muted)' }}>Balance Due</p>
        <div className="flex items-center gap-2 mt-1">
          <p className="text-3xl font-black" style={{ color: balance > 0 ? 'var(--danger)' : 'var(--text)' }}>
            {formatCurrency(balance)}
          </p>
          {overdueCount > 0 && (
            <span
              className="text-[10px] font-bold px-2 py-0.5 rounded-full text-white"
              style={{ backgroundColor: 'var(--danger)' }}
            >
              {overdueCount} overdue
            </span>
          )}
        </div>
        <button
          onClick={handlePayNow}
          className="w-full mt-4 py-3 text-white font-bold rounded-xl transition-all text-sm"
          style={{ backgroundColor: 'var(--accent)' }}
          onMouseEnter={e => (e.currentTarget.style.backgroundColor = 'var(--accent-hover)')}
          onMouseLeave={e => (e.currentTarget.style.backgroundColor = 'var(--accent)')}
        >
          Pay Now
        </button>
      </div>

      {/* Empty State */}
      {charges.length === 0 && (
        <div className="rounded-xl p-8 text-center" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
          <Receipt size={32} className="mx-auto mb-3" style={{ color: 'var(--border-light)' }} />
          <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>No rent charges</h3>
          <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>
            Rent charges from your landlord will appear here.
          </p>
        </div>
      )}

      {/* Charges List */}
      {charges.length > 0 && (
        <div className="space-y-2">
          {charges.map(charge => {
            const config = statusConfig[charge.status] || statusConfig.pending;
            return (
              <button
                key={charge.id}
                onClick={() => router.push(`/rent/${charge.id}`)}
                className="w-full flex items-center gap-3 rounded-xl p-4 transition-all text-left"
                style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}
                onMouseEnter={e => (e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.08)')}
                onMouseLeave={e => (e.currentTarget.style.boxShadow = 'none')}
              >
                <div className="p-2.5 rounded-xl" style={{ backgroundColor: 'var(--bg-secondary)' }}>
                  {charge.status === 'overdue' ? (
                    <AlertCircle size={18} style={{ color: 'var(--danger)' }} />
                  ) : charge.status === 'paid' ? (
                    <DollarSign size={18} style={{ color: 'var(--success)' }} />
                  ) : (
                    <Clock size={18} style={{ color: 'var(--text-muted)' }} />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>
                      {chargeTypeLabel(charge.chargeType)}
                    </h3>
                    <span
                      className="text-[10px] font-medium px-2 py-0.5 rounded-full"
                      style={{
                        color: config.color,
                        backgroundColor: `color-mix(in srgb, ${config.color} 12%, transparent)`,
                      }}
                    >
                      {config.label}
                    </span>
                  </div>
                  <p className="text-xs mt-0.5" style={{ color: 'var(--text-muted)' }}>
                    Due {formatDate(charge.dueDate)}
                    {charge.status === 'partial' && ` · Paid ${formatCurrency(charge.paidAmount)}`}
                  </p>
                </div>
                <div className="text-right flex items-center gap-2">
                  <span className="font-bold text-sm" style={{ color: 'var(--text)' }}>
                    {formatCurrency(charge.amount)}
                  </span>
                  <ChevronRight size={14} style={{ color: 'var(--border-light)' }} />
                </div>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
