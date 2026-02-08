'use client';

import { useParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft, Calculator, User, MapPin, Shield, FileText,
  Layers, Hash, DollarSign, Calendar,
} from 'lucide-react';
import { useEstimate } from '@/lib/hooks/use-estimates';
import {
  ESTIMATE_STATUS_LABELS, ESTIMATE_STATUS_COLORS,
  type EstimateStatus, type EstimateAreaData, type EstimateLineItemData,
} from '@/lib/hooks/mappers';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { formatCurrency, formatDate, cn } from '@/lib/utils';

function EstimateStatusBadge({ status }: { status: EstimateStatus }) {
  const colors = ESTIMATE_STATUS_COLORS[status] || ESTIMATE_STATUS_COLORS.draft;
  const label = ESTIMATE_STATUS_LABELS[status] || status;
  return (
    <span className={cn('inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-medium rounded-full', colors.bg, colors.text)}>
      {label}
    </span>
  );
}

function DetailRow({ label, value, icon: Icon }: { label: string; value: string; icon?: React.ElementType }) {
  if (!value) return null;
  return (
    <div className="flex items-start gap-3 py-2">
      {Icon && <Icon size={14} className="text-muted mt-0.5 flex-shrink-0" />}
      <div className="min-w-0">
        <p className="text-xs text-muted">{label}</p>
        <p className="text-sm text-main">{value}</p>
      </div>
    </div>
  );
}

function TotalsRow({ label, value, bold }: { label: string; value: number; bold?: boolean }) {
  return (
    <div className={cn('flex items-center justify-between py-1.5', bold && 'border-t border-main pt-2.5 mt-1')}>
      <span className={cn('text-sm', bold ? 'font-semibold text-main' : 'text-muted')}>{label}</span>
      <span className={cn('text-sm font-mono', bold ? 'font-bold text-main text-base' : 'text-main')}>
        {formatCurrency(value)}
      </span>
    </div>
  );
}

function LineItemRow({ item }: { item: EstimateLineItemData }) {
  return (
    <div className="flex items-start justify-between gap-3 py-2.5 border-b border-main last:border-0">
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          {item.zaftoCode && (
            <span className="text-[10px] font-mono text-muted bg-surface-hover px-1.5 py-0.5 rounded">
              {item.zaftoCode}
            </span>
          )}
          <span className="text-[10px] uppercase text-muted">{item.actionType}</span>
        </div>
        <p className="text-sm text-main mt-0.5">{item.description}</p>
        <p className="text-xs text-muted mt-0.5">
          {item.quantity.toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 2 })} {item.unitCode} x {formatCurrency(item.unitPrice)}
        </p>
      </div>
      <p className="text-sm font-mono font-medium text-main whitespace-nowrap flex-shrink-0">
        {formatCurrency(item.lineTotal)}
      </p>
    </div>
  );
}

function AreaSection({ area, lineItems }: { area: EstimateAreaData; lineItems: EstimateLineItemData[] }) {
  const areaItems = lineItems.filter((li) => li.areaId === area.id);
  const areaSf = area.floorSf > 0 ? `${area.floorSf.toLocaleString('en-US')} SF` : null;
  const dimensions =
    area.lengthFt > 0 && area.widthFt > 0
      ? `${area.lengthFt}' x ${area.widthFt}' x ${area.heightFt}'`
      : null;

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Layers size={14} className="text-accent" />
            {area.name}
          </CardTitle>
          <div className="flex items-center gap-3 text-xs text-muted">
            {dimensions && <span>{dimensions}</span>}
            {areaSf && <span className="font-medium">{areaSf}</span>}
          </div>
        </div>
      </CardHeader>
      <CardContent className="py-1">
        {areaItems.length === 0 ? (
          <p className="text-sm text-muted py-3 text-center">No line items in this area</p>
        ) : (
          areaItems.map((item) => <LineItemRow key={item.id} item={item} />)
        )}
      </CardContent>
    </Card>
  );
}

function DetailSkeleton() {
  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center gap-3">
        <div className="skeleton h-9 w-9 rounded-lg" />
        <div className="skeleton h-6 w-48 rounded-lg" />
      </div>
      <div className="skeleton h-8 w-64 rounded-lg" />
      <div className="skeleton h-40 w-full rounded-xl" />
      <div className="skeleton h-48 w-full rounded-xl" />
      <div className="skeleton h-32 w-full rounded-xl" />
    </div>
  );
}

export default function EstimateDetailPage() {
  const params = useParams();
  const estimateId = params.id as string;
  const { estimate, areas, lineItems, loading } = useEstimate(estimateId);

  if (loading) return <DetailSkeleton />;

  if (!estimate) {
    return (
      <div className="space-y-6 animate-fade-in">
        <Link
          href="/dashboard/estimates"
          className="inline-flex items-center gap-2 text-sm text-muted hover:text-main transition-colors"
        >
          <ArrowLeft size={16} />
          Back to Estimates
        </Link>
        <Card>
          <CardContent className="py-12 text-center">
            <Calculator size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">Estimate not found</p>
            <p className="text-sm text-muted mt-1">This estimate may have been deleted or you do not have access.</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  // Line items not assigned to any area
  const unassignedItems = lineItems.filter((li) => !li.areaId);

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Back Link */}
      <Link
        href="/dashboard/estimates"
        className="inline-flex items-center gap-2 text-sm text-muted hover:text-main transition-colors"
      >
        <ArrowLeft size={16} />
        Back to Estimates
      </Link>

      {/* Header */}
      <div>
        <div className="flex items-center gap-3 flex-wrap">
          <span className="text-xs font-mono text-muted">{estimate.estimateNumber}</span>
          <EstimateStatusBadge status={estimate.status} />
          {estimate.estimateType === 'insurance' && (
            <span className="inline-flex items-center px-1.5 py-0.5 text-[10px] font-medium rounded bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400">
              Insurance
            </span>
          )}
        </div>
        <h1 className="text-xl font-bold text-main mt-2">{estimate.title}</h1>
      </div>

      {/* Details Card */}
      <Card>
        <CardHeader>
          <CardTitle>Estimate Details</CardTitle>
        </CardHeader>
        <CardContent className="space-y-0 divide-y divide-main">
          <DetailRow label="Customer" value={estimate.customerName} icon={User} />
          <DetailRow label="Property Address" value={estimate.propertyAddress} icon={MapPin} />
          <DetailRow label="Created" value={formatDate(estimate.createdAt)} icon={Calendar} />
          {estimate.validUntil && (
            <DetailRow label="Valid Until" value={formatDate(estimate.validUntil)} icon={Calendar} />
          )}
          {estimate.sentAt && (
            <DetailRow label="Sent" value={formatDate(estimate.sentAt)} icon={Calendar} />
          )}
        </CardContent>
      </Card>

      {/* Insurance Section */}
      {estimate.estimateType === 'insurance' && (estimate.claimNumber || estimate.carrierName || estimate.deductible > 0) && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Shield size={14} className="text-accent" />
              Insurance Information
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-0 divide-y divide-main">
            {estimate.claimNumber && (
              <DetailRow label="Claim Number" value={estimate.claimNumber} icon={Hash} />
            )}
            {estimate.carrierName && (
              <DetailRow label="Carrier" value={estimate.carrierName} icon={Shield} />
            )}
            {estimate.deductible > 0 && (
              <DetailRow label="Deductible" value={formatCurrency(estimate.deductible)} icon={DollarSign} />
            )}
          </CardContent>
        </Card>
      )}

      {/* Areas + Line Items */}
      {areas.length > 0 && (
        <div className="space-y-3">
          <h2 className="text-sm font-semibold text-main flex items-center gap-2">
            <Layers size={14} className="text-muted" />
            Areas ({areas.length})
          </h2>
          {areas.map((area) => (
            <AreaSection key={area.id} area={area} lineItems={lineItems} />
          ))}
        </div>
      )}

      {/* Unassigned Line Items */}
      {unassignedItems.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText size={14} className="text-accent" />
              General Line Items
            </CardTitle>
          </CardHeader>
          <CardContent className="py-1">
            {unassignedItems.map((item) => (
              <LineItemRow key={item.id} item={item} />
            ))}
          </CardContent>
        </Card>
      )}

      {/* No line items message */}
      {areas.length === 0 && unassignedItems.length === 0 && (
        <Card>
          <CardContent className="py-8 text-center">
            <FileText size={32} className="text-muted mx-auto mb-2" />
            <p className="text-sm text-muted">No areas or line items added yet</p>
          </CardContent>
        </Card>
      )}

      {/* Totals */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <DollarSign size={14} className="text-accent" />
            Totals
          </CardTitle>
        </CardHeader>
        <CardContent>
          <TotalsRow label="Subtotal" value={estimate.subtotal} />
          {estimate.overheadPercent > 0 && (
            <TotalsRow label={`Overhead (${estimate.overheadPercent}%)`} value={estimate.overheadAmount} />
          )}
          {estimate.profitPercent > 0 && (
            <TotalsRow label={`Profit (${estimate.profitPercent}%)`} value={estimate.profitAmount} />
          )}
          {estimate.taxPercent > 0 && (
            <TotalsRow label={`Tax (${estimate.taxPercent}%)`} value={estimate.taxAmount} />
          )}
          <TotalsRow label="Grand Total" value={estimate.grandTotal} bold />
        </CardContent>
      </Card>

      {/* Notes */}
      {estimate.notes && (
        <Card>
          <CardHeader>
            <CardTitle>Notes</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-main whitespace-pre-wrap">{estimate.notes}</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
