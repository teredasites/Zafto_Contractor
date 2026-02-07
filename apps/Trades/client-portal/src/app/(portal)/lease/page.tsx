'use client';
import { FileText, Calendar, DollarSign, Clock, RotateCcw, AlertTriangle, CheckCircle2 } from 'lucide-react';
import { useTenant } from '@/lib/hooks/use-tenant';
import { formatCurrency, formatDate } from '@/lib/hooks/mappers';
import { leaseStatusLabel, formatAddress } from '@/lib/hooks/tenant-mappers';

const leaseStatusColor: Record<string, string> = {
  draft: 'var(--text-muted)',
  pending_signature: 'var(--warning)',
  active: 'var(--success)',
  month_to_month: 'var(--accent)',
  expiring: 'var(--warning)',
  expired: 'var(--danger)',
  terminated: 'var(--danger)',
  renewed: 'var(--success)',
};

function getDaysUntil(dateStr: string): number {
  const target = new Date(dateStr);
  const now = new Date();
  const diffMs = target.getTime() - now.getTime();
  return Math.ceil(diffMs / (1000 * 60 * 60 * 24));
}

export default function LeasePage() {
  const { tenant, lease, property, unit, loading } = useTenant();

  // Loading skeleton
  if (loading) {
    return (
      <div className="space-y-5 animate-pulse">
        <div>
          <div className="h-7 rounded w-28 mb-1" style={{ backgroundColor: 'var(--border-light)' }} />
          <div className="h-4 rounded w-48" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        </div>
        <div className="rounded-xl p-5" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
          <div className="space-y-3">
            <div className="h-5 rounded w-40" style={{ backgroundColor: 'var(--border-light)' }} />
            <div className="h-4 rounded w-64" style={{ backgroundColor: 'var(--bg-secondary)' }} />
          </div>
        </div>
        <div className="rounded-xl p-5" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
          <div className="h-4 rounded w-28 mb-4" style={{ backgroundColor: 'var(--border-light)' }} />
          {[1, 2, 3, 4, 5].map(i => (
            <div key={i} className="flex justify-between py-2.5">
              <div className="h-4 rounded w-28" style={{ backgroundColor: 'var(--bg-secondary)' }} />
              <div className="h-4 rounded w-24" style={{ backgroundColor: 'var(--bg-secondary)' }} />
            </div>
          ))}
        </div>
      </div>
    );
  }

  // No active lease
  if (!lease) {
    return (
      <div className="space-y-5">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: 'var(--text)' }}>My Lease</h1>
          <p className="text-sm mt-0.5" style={{ color: 'var(--text-muted)' }}>
            {tenant ? `${tenant.firstName} ${tenant.lastName}` : 'Tenant'}
          </p>
        </div>
        <div className="rounded-xl p-8 text-center" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
          <FileText size={32} className="mx-auto mb-3" style={{ color: 'var(--border-light)' }} />
          <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>No active lease found</h3>
          <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>
            Contact your landlord if you believe this is an error.
          </p>
        </div>
      </div>
    );
  }

  const statusColor = leaseStatusColor[lease.status] || 'var(--text-muted)';
  const daysUntilEnd = lease.endDate ? getDaysUntil(lease.endDate) : null;
  const showCountdown = lease.endDate && (lease.status === 'active' || lease.status === 'expiring') && daysUntilEnd !== null;

  return (
    <div className="space-y-5">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold" style={{ color: 'var(--text)' }}>My Lease</h1>
        <p className="text-sm mt-0.5" style={{ color: 'var(--text-muted)' }}>
          {tenant ? `${tenant.firstName} ${tenant.lastName}` : 'Tenant'}
        </p>
      </div>

      {/* Status + Address Card */}
      <div className="rounded-xl p-5" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl" style={{ backgroundColor: 'var(--bg-secondary)' }}>
              <FileText size={20} style={{ color: 'var(--accent)' }} />
            </div>
            <div>
              <h2 className="font-bold" style={{ color: 'var(--text)' }}>
                {lease.leaseType === 'month_to_month' ? 'Month-to-Month' : 'Fixed Term'} Lease
              </h2>
              {property && (
                <p className="text-xs mt-0.5" style={{ color: 'var(--text-muted)' }}>
                  {formatAddress(property, unit || undefined)}
                </p>
              )}
            </div>
          </div>
          <span
            className="text-[10px] font-bold px-2.5 py-1 rounded-full"
            style={{
              color: statusColor,
              backgroundColor: `color-mix(in srgb, ${statusColor} 12%, transparent)`,
            }}
          >
            {leaseStatusLabel(lease.status)}
          </span>
        </div>
      </div>

      {/* Expiry Countdown */}
      {showCountdown && daysUntilEnd !== null && (
        <div
          className="rounded-xl p-4 flex items-center gap-3"
          style={{
            backgroundColor: daysUntilEnd <= 30
              ? 'color-mix(in srgb, var(--warning) 10%, transparent)'
              : 'color-mix(in srgb, var(--accent) 8%, transparent)',
            border: `1px solid ${daysUntilEnd <= 30 ? 'color-mix(in srgb, var(--warning) 25%, transparent)' : 'color-mix(in srgb, var(--accent) 20%, transparent)'}`,
          }}
        >
          {daysUntilEnd <= 30 ? (
            <AlertTriangle size={20} style={{ color: 'var(--warning)' }} />
          ) : (
            <Calendar size={20} style={{ color: 'var(--accent)' }} />
          )}
          <div>
            <p className="text-sm font-semibold" style={{ color: 'var(--text)' }}>
              {daysUntilEnd > 0 ? `${daysUntilEnd} days remaining` : 'Lease has expired'}
            </p>
            <p className="text-xs" style={{ color: 'var(--text-muted)' }}>
              {daysUntilEnd > 0
                ? `Expires ${formatDate(lease.endDate)}`
                : `Expired ${formatDate(lease.endDate)}`}
            </p>
          </div>
        </div>
      )}

      {/* Lease Details Card */}
      <div className="rounded-xl overflow-hidden" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
        <div className="p-4" style={{ borderBottom: '1px solid var(--border-light)' }}>
          <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>Lease Details</h3>
        </div>
        <div>
          <DetailRow label="Type" value={lease.leaseType === 'month_to_month' ? 'Month-to-Month' : 'Fixed Term'} icon={<FileText size={14} />} />
          <DetailRow label="Start Date" value={formatDate(lease.startDate)} icon={<Calendar size={14} />} />
          <DetailRow label="End Date" value={lease.endDate ? formatDate(lease.endDate) : 'No end date'} icon={<Calendar size={14} />} />
          <DetailRow label="Monthly Rent" value={formatCurrency(lease.rentAmount)} icon={<DollarSign size={14} />} highlight />
          <DetailRow label="Due Day" value={`${getOrdinal(lease.rentDueDay)} of each month`} icon={<Clock size={14} />} />
          <DetailRow label="Security Deposit" value={formatCurrency(lease.depositAmount)} icon={<DollarSign size={14} />} />
          <DetailRow label="Grace Period" value={`${lease.gracePeriodDays} day${lease.gracePeriodDays !== 1 ? 's' : ''}`} icon={<Clock size={14} />} />
          <DetailRow
            label="Late Fee"
            value={
              lease.lateFeeType === 'flat'
                ? formatCurrency(lease.lateFeeAmount)
                : lease.lateFeeType === 'percentage'
                  ? `${lease.lateFeeAmount}%`
                  : `${formatCurrency(lease.lateFeeAmount)} (${lease.lateFeeType})`
            }
            icon={<AlertTriangle size={14} />}
          />
          <DetailRow
            label="Auto-Renew"
            value={lease.autoRenew ? 'Yes' : 'No'}
            icon={<RotateCcw size={14} />}
            valueIcon={
              lease.autoRenew
                ? <CheckCircle2 size={12} style={{ color: 'var(--success)' }} />
                : undefined
            }
          />
          <DetailRow
            label="Partial Payments"
            value={lease.partialPaymentsAllowed ? 'Allowed' : 'Not allowed'}
            icon={<DollarSign size={14} />}
            valueIcon={
              lease.partialPaymentsAllowed
                ? <CheckCircle2 size={12} style={{ color: 'var(--success)' }} />
                : undefined
            }
          />
        </div>
      </div>

      {/* Terms / Notes */}
      {lease.termsNotes && (
        <div className="rounded-xl p-5" style={{ backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)' }}>
          <h3 className="font-semibold text-sm mb-3" style={{ color: 'var(--text)' }}>Lease Terms &amp; Notes</h3>
          <p className="text-sm leading-relaxed whitespace-pre-wrap" style={{ color: 'var(--text-muted)' }}>
            {lease.termsNotes}
          </p>
        </div>
      )}
    </div>
  );
}

// Helper: detail row component
function DetailRow({
  label,
  value,
  icon,
  highlight,
  valueIcon,
}: {
  label: string;
  value: string;
  icon: React.ReactNode;
  highlight?: boolean;
  valueIcon?: React.ReactNode;
}) {
  return (
    <div
      className="flex items-center justify-between px-4 py-3"
      style={{ borderTop: '1px solid var(--bg-secondary)' }}
    >
      <div className="flex items-center gap-2">
        <span style={{ color: 'var(--text-muted)' }}>{icon}</span>
        <span className="text-sm" style={{ color: 'var(--text-muted)' }}>{label}</span>
      </div>
      <div className="flex items-center gap-1.5">
        {valueIcon}
        <span
          className={`text-sm ${highlight ? 'font-bold' : 'font-medium'}`}
          style={{ color: highlight ? 'var(--accent)' : 'var(--text)' }}
        >
          {value}
        </span>
      </div>
    </div>
  );
}

function getOrdinal(n: number): string {
  const s = ['th', 'st', 'nd', 'rd'];
  const v = n % 100;
  return n + (s[(v - 20) % 10] || s[v] || s[0]);
}
