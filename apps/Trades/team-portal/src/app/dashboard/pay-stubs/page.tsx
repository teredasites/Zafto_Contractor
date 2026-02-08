'use client';

import { useState } from 'react';
import {
  DollarSign, Calendar, ChevronDown, ChevronUp,
  Download, TrendingUp, Clock, FileText,
} from 'lucide-react';
import { usePayStubs } from '@/lib/hooks/use-pay-stubs';
import type { PayStubData } from '@/lib/hooks/use-pay-stubs';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { cn, formatCurrency, formatDate } from '@/lib/utils';

// ============================================================
// SKELETON
// ============================================================

function PayStubsSkeleton() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div className="h-8 w-48 bg-surface-hover animate-pulse rounded" />
      <div className="grid grid-cols-3 gap-4">
        {[...Array(3)].map((_, i) => <div key={i} className="h-24 bg-surface-hover animate-pulse rounded-xl" />)}
      </div>
      <div className="space-y-3">
        {[...Array(4)].map((_, i) => <div key={i} className="h-28 bg-surface-hover animate-pulse rounded-xl" />)}
      </div>
    </div>
  );
}

// ============================================================
// DEDUCTION ROW
// ============================================================

function DeductionRow({ label, amount }: { label: string; amount: number }) {
  if (amount === 0) return null;
  return (
    <div className="flex items-center justify-between text-sm py-1.5">
      <span className="text-muted">{label}</span>
      <span className="text-main font-medium">{formatCurrency(amount)}</span>
    </div>
  );
}

// ============================================================
// PAY STUB CARD
// ============================================================

function PayStubCard({ stub, isExpanded, onToggle }: {
  stub: PayStubData;
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const periodStart = formatDate(stub.payPeriodStart);
  const periodEnd = formatDate(stub.payPeriodEnd);

  return (
    <Card className={cn('transition-all', isExpanded && 'ring-2 ring-accent/20')}>
      <CardContent className="p-4">
        {/* Summary Row */}
        <button onClick={onToggle} className="w-full text-left">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center flex-shrink-0">
              <DollarSign size={20} className="text-emerald-600 dark:text-emerald-400" />
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-0.5">
                <span className="text-[15px] font-semibold text-main">
                  {periodStart} - {periodEnd}
                </span>
                <Badge variant={stub.status === 'paid' ? 'success' : stub.status === 'processed' ? 'info' : 'default'}>
                  {stub.status === 'paid' ? 'Paid' : stub.status === 'processed' ? 'Processed' : 'Draft'}
                </Badge>
              </div>
              <div className="text-xs text-muted">
                Pay Date: {formatDate(stub.payDate)}
              </div>
            </div>

            <div className="flex items-center gap-3 flex-shrink-0">
              <div className="text-right">
                <div className="text-[15px] font-bold text-emerald-600 dark:text-emerald-400">
                  {formatCurrency(stub.netPay)}
                </div>
                <div className="text-[11px] text-muted">Net Pay</div>
              </div>
              {isExpanded ? (
                <ChevronUp size={16} className="text-muted" />
              ) : (
                <ChevronDown size={16} className="text-muted" />
              )}
            </div>
          </div>
        </button>

        {/* Expanded Detail */}
        {isExpanded && (
          <div className="mt-4 pt-4 border-t border-main space-y-4">
            {/* Earnings */}
            <div>
              <p className="text-xs font-semibold text-muted uppercase tracking-wider mb-2">Earnings</p>
              <div className="space-y-0.5">
                <div className="flex items-center justify-between text-sm py-1.5">
                  <span className="text-muted">Regular ({stub.regularHours}h @ {formatCurrency(stub.regularRate)}/hr)</span>
                  <span className="text-main font-medium">{formatCurrency(stub.regularHours * stub.regularRate)}</span>
                </div>
                {stub.overtimeHours > 0 && (
                  <div className="flex items-center justify-between text-sm py-1.5">
                    <span className="text-muted">Overtime ({stub.overtimeHours}h @ {formatCurrency(stub.overtimeRate)}/hr)</span>
                    <span className="text-main font-medium">{formatCurrency(stub.overtimeHours * stub.overtimeRate)}</span>
                  </div>
                )}
                {stub.bonuses > 0 && (
                  <div className="flex items-center justify-between text-sm py-1.5">
                    <span className="text-muted">Bonuses</span>
                    <span className="text-main font-medium">{formatCurrency(stub.bonuses)}</span>
                  </div>
                )}
                {stub.reimbursements > 0 && (
                  <div className="flex items-center justify-between text-sm py-1.5">
                    <span className="text-muted">Reimbursements</span>
                    <span className="text-main font-medium">{formatCurrency(stub.reimbursements)}</span>
                  </div>
                )}
                <div className="flex items-center justify-between text-sm py-1.5 font-semibold border-t border-main mt-1 pt-2">
                  <span className="text-main">Gross Pay</span>
                  <span className="text-main">{formatCurrency(stub.grossPay)}</span>
                </div>
              </div>
            </div>

            {/* Deductions */}
            <div>
              <p className="text-xs font-semibold text-muted uppercase tracking-wider mb-2">Deductions</p>
              <div className="space-y-0.5">
                <DeductionRow label="Federal Income Tax" amount={stub.deductions.federalTax} />
                <DeductionRow label="State Income Tax" amount={stub.deductions.stateTax} />
                <DeductionRow label="Social Security" amount={stub.deductions.socialSecurity} />
                <DeductionRow label="Medicare" amount={stub.deductions.medicare} />
                <DeductionRow label="Health Insurance" amount={stub.deductions.healthInsurance} />
                <DeductionRow label="Dental Insurance" amount={stub.deductions.dentalInsurance} />
                <DeductionRow label="Vision Insurance" amount={stub.deductions.visionInsurance} />
                <DeductionRow label="401(k) Contribution" amount={stub.deductions.retirement401k} />
                <DeductionRow label="Other Deductions" amount={stub.deductions.otherDeductions} />
                <div className="flex items-center justify-between text-sm py-1.5 font-semibold border-t border-main mt-1 pt-2">
                  <span className="text-main">Total Deductions</span>
                  <span className="text-red-500">{formatCurrency(stub.totalDeductions)}</span>
                </div>
              </div>
            </div>

            {/* Net Pay */}
            <div className="bg-emerald-50 dark:bg-emerald-900/20 rounded-lg p-3">
              <div className="flex items-center justify-between">
                <span className="text-sm font-semibold text-emerald-700 dark:text-emerald-300">Net Pay</span>
                <span className="text-lg font-bold text-emerald-700 dark:text-emerald-300">{formatCurrency(stub.netPay)}</span>
              </div>
            </div>

            {/* Download */}
            <Button
              variant="secondary"
              size="sm"
              onClick={(e) => {
                e.stopPropagation();
                // Placeholder for zdocs-render EF
              }}
              className="w-full sm:w-auto"
            >
              <Download size={14} />
              Download PDF
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ============================================================
// MAIN PAGE
// ============================================================

export default function PayStubsPage() {
  const { payStubs, ytdTotals, loading, error } = usePayStubs();
  const [expandedId, setExpandedId] = useState<string | null>(null);

  if (loading) return <PayStubsSkeleton />;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-main">Pay Stubs</h1>
        <p className="text-sm text-muted mt-1">
          Your pay history and earnings breakdown
        </p>
      </div>

      {error && (
        <div className="px-4 py-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* YTD Summary */}
      {ytdTotals.stubCount > 0 && (
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-surface border border-main rounded-xl p-4 text-center">
            <TrendingUp size={20} className="mx-auto mb-1.5 text-emerald-500" />
            <div className="text-xl font-bold text-main">{formatCurrency(ytdTotals.grossPay)}</div>
            <div className="text-xs text-muted">YTD Gross</div>
          </div>
          <div className="bg-surface border border-main rounded-xl p-4 text-center">
            <DollarSign size={20} className="mx-auto mb-1.5 text-blue-500" />
            <div className="text-xl font-bold text-main">{formatCurrency(ytdTotals.netPay)}</div>
            <div className="text-xs text-muted">YTD Net</div>
          </div>
          <div className="bg-surface border border-main rounded-xl p-4 text-center">
            <Clock size={20} className="mx-auto mb-1.5 text-amber-500" />
            <div className="text-xl font-bold text-main">{ytdTotals.totalHours.toFixed(1)}</div>
            <div className="text-xs text-muted">YTD Hours</div>
          </div>
        </div>
      )}

      {/* Pay Stubs List */}
      {payStubs.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16">
          <FileText size={40} className="text-muted opacity-30 mb-3" />
          <p className="text-main font-medium">No pay stubs yet</p>
          <p className="text-sm text-muted mt-1">Your pay stubs will appear here after payroll is processed.</p>
        </div>
      ) : (
        <div className="space-y-3">
          <p className="text-sm font-semibold text-muted">
            {payStubs.length} Pay Stub{payStubs.length !== 1 ? 's' : ''}
          </p>
          {payStubs.map(stub => (
            <PayStubCard
              key={stub.id}
              stub={stub}
              isExpanded={expandedId === stub.id}
              onToggle={() => setExpandedId(expandedId === stub.id ? null : stub.id)}
            />
          ))}
        </div>
      )}
    </div>
  );
}
