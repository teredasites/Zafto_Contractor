'use client';

import { useState, useCallback } from 'react';
import {
  Plus,
  DollarSign,
  Users,
  Calendar,
  FileText,
  ChevronDown,
  ChevronRight,
  CheckCircle,
  Clock,
  AlertTriangle,
  Banknote,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import {
  usePayroll,
  type PayPeriod,
  type PayStub,
  type PeriodStatus,
} from '@/lib/hooks/use-payroll';
import { useTranslation } from '@/lib/translations';

// ────────────────────────────────────────────────────────
// Status config
// ────────────────────────────────────────────────────────

const periodStatusConfig: Record<PeriodStatus, { label: string; variant: 'secondary' | 'info' | 'warning' | 'success' | 'error' }> = {
  draft: { label: 'Draft', variant: 'secondary' },
  processing: { label: 'Processing', variant: 'info' },
  approved: { label: 'Approved', variant: 'warning' },
  paid: { label: 'Paid', variant: 'success' },
  voided: { label: 'Voided', variant: 'error' },
};

const periodTypeLabels: Record<string, string> = {
  weekly: 'Weekly',
  biweekly: 'Bi-Weekly',
  semimonthly: 'Semi-Monthly',
  monthly: 'Monthly',
};

// ────────────────────────────────────────────────────────
// Page
// ────────────────────────────────────────────────────────

export default function PayrollPage() {
  const { t } = useTranslation();
  const [statusFilter, setStatusFilter] = useState('all');
  const [expandedPeriod, setExpandedPeriod] = useState<string | null>(null);
  const [periodStubs, setPeriodStubs] = useState<Record<string, PayStub[]>>({});
  const [loadingStubs, setLoadingStubs] = useState<Record<string, boolean>>({});

  const {
    payPeriods,
    loading,
    currentPeriod,
    totalPayroll,
    pendingApproval,
    getStubsForPeriod,
    updatePayPeriodStatus,
  } = usePayroll();

  // ── Load stubs on expand ──
  const handleTogglePeriod = useCallback(async (periodId: string) => {
    if (expandedPeriod === periodId) {
      setExpandedPeriod(null);
      return;
    }

    setExpandedPeriod(periodId);

    if (!periodStubs[periodId]) {
      try {
        setLoadingStubs((prev) => ({ ...prev, [periodId]: true }));
        const stubs = await getStubsForPeriod(periodId);
        setPeriodStubs((prev) => ({ ...prev, [periodId]: stubs }));
      } catch {
        // Silent — stubs will show as empty
      } finally {
        setLoadingStubs((prev) => ({ ...prev, [periodId]: false }));
      }
    }
  }, [expandedPeriod, periodStubs, getStubsForPeriod]);

  // ── Status actions ──
  const handleStatusUpdate = useCallback(async (id: string, status: PeriodStatus) => {
    try {
      await updatePayPeriodStatus(id, status);
    } catch {
      // Silent — real-time will refetch
    }
  }, [updatePayPeriodStatus]);

  // ── Filtering ──
  const filteredPeriods = payPeriods.filter((p) => {
    return statusFilter === 'all' || p.status === statusFilter;
  });

  // ── Stats ──
  const totalEmployees = currentPeriod?.employeeCount || 0;
  const currentNet = currentPeriod?.totalNet || 0;

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-32 mb-2" /><div className="skeleton h-4 w-48" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-5">
              <div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" />
            </div>
          ))}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="px-6 py-4 flex items-center gap-4">
              <div className="flex-1"><div className="skeleton h-4 w-40 mb-2" /><div className="skeleton h-3 w-32" /></div>
              <div className="skeleton h-5 w-16 rounded-full" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('payroll.title')}</h1>
          <p className="text-muted mt-1">Manage pay periods, stubs, and tax reporting</p>
        </div>
        <Button><Plus size={16} />New Pay Period</Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Calendar size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">
                  {currentPeriod
                    ? `${formatDate(currentPeriod.startDate).split(',')[0]} - ${formatDate(currentPeriod.endDate).split(',')[0]}`
                    : 'None'}
                </p>
                <p className="text-sm text-muted">Current Period</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <DollarSign size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(totalPayroll)}</p>
                <p className="text-sm text-muted">Total Gross</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Banknote size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(currentNet)}</p>
                <p className="text-sm text-muted">Total Net</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Users size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalEmployees}</p>
                <p className="text-sm text-muted">{t('common.employees')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Pending Approval Banner */}
      {pendingApproval > 0 && (
        <div className="flex items-center gap-3 p-4 bg-amber-50 dark:bg-amber-900/10 border border-amber-200 dark:border-amber-800/30 rounded-xl">
          <AlertTriangle size={20} className="text-amber-600 dark:text-amber-400" />
          <p className="text-sm font-medium text-amber-800 dark:text-amber-300">
            {pendingApproval} pay period{pendingApproval > 1 ? 's' : ''} pending approval
          </p>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <Select
          options={[
            { value: 'all', label: 'All Statuses' },
            { value: 'draft', label: 'Draft' },
            { value: 'processing', label: 'Processing' },
            { value: 'approved', label: 'Approved' },
            { value: 'paid', label: 'Paid' },
            { value: 'voided', label: 'Voided' },
          ]}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Pay Periods Table */}
      <Card>
        <CardContent className="p-0">
          {filteredPeriods.length === 0 ? (
            <div className="py-12 text-center text-muted">
              <FileText size={40} className="mx-auto mb-2 opacity-50" />
              <p>{t('payroll.noRecords')}</p>
            </div>
          ) : (
            <div className="divide-y divide-main">
              {/* Table Header */}
              <div className="px-6 py-3 bg-secondary/50 grid grid-cols-12 gap-4 text-xs font-medium text-muted uppercase tracking-wider">
                <div className="col-span-1" />
                <div className="col-span-2">Date Range</div>
                <div className="col-span-1">{t('common.type')}</div>
                <div className="col-span-1">{t('common.status')}</div>
                <div className="col-span-1">{t('common.employees')}</div>
                <div className="col-span-2">{t('common.grossPay')}</div>
                <div className="col-span-1">{t('common.taxes')}</div>
                <div className="col-span-2">{t('common.netPay')}</div>
                <div className="col-span-1">{t('common.actions')}</div>
              </div>

              {filteredPeriods.map((period) => {
                const isExpanded = expandedPeriod === period.id;
                const stubs = periodStubs[period.id] || [];
                const isLoadingStubs = loadingStubs[period.id] || false;

                return (
                  <div key={period.id}>
                    <PayPeriodRow
                      period={period}
                      isExpanded={isExpanded}
                      onToggle={() => handleTogglePeriod(period.id)}
                      onApprove={() => handleStatusUpdate(period.id, 'approved')}
                      onProcess={() => handleStatusUpdate(period.id, 'processing')}
                    />
                    {isExpanded && (
                      <PayPeriodDetail
                        stubs={stubs}
                        loading={isLoadingStubs}
                      />
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// ────────────────────────────────────────────────────────
// Pay Period Row
// ────────────────────────────────────────────────────────

function PayPeriodRow({
  period,
  isExpanded,
  onToggle,
  onApprove,
  onProcess,
}: {
  period: PayPeriod;
  isExpanded: boolean;
  onToggle: () => void;
  onApprove: () => void;
  onProcess: () => void;
}) {
  const statusCfg = periodStatusConfig[period.status];

  return (
    <div
      className={cn(
        'px-6 py-4 grid grid-cols-12 gap-4 items-center cursor-pointer hover:bg-surface-hover transition-colors',
        isExpanded && 'bg-surface-hover'
      )}
      onClick={onToggle}
    >
      <div className="col-span-1 flex items-center">
        {isExpanded ? (
          <ChevronDown size={16} className="text-muted" />
        ) : (
          <ChevronRight size={16} className="text-muted" />
        )}
      </div>
      <div className="col-span-2">
        <p className="text-sm font-medium text-main">
          {formatDate(period.startDate)} - {formatDate(period.endDate)}
        </p>
        <p className="text-xs text-muted mt-0.5 flex items-center gap-1">
          <Clock size={10} />
          Pay date: {formatDate(period.payDate)}
        </p>
      </div>
      <div className="col-span-1">
        <span className="text-sm text-muted">{periodTypeLabels[period.periodType] || period.periodType}</span>
      </div>
      <div className="col-span-1">
        <Badge variant={statusCfg.variant} dot>{statusCfg.label}</Badge>
      </div>
      <div className="col-span-1">
        <div className="flex items-center gap-1">
          <Users size={14} className="text-muted" />
          <span className="text-sm text-main">{period.employeeCount}</span>
        </div>
      </div>
      <div className="col-span-2">
        <p className="text-sm font-semibold text-main">{formatCurrency(period.totalGross)}</p>
      </div>
      <div className="col-span-1">
        <p className="text-sm text-muted">{formatCurrency(period.totalTaxes)}</p>
      </div>
      <div className="col-span-2">
        <p className="text-sm font-semibold text-emerald-600 dark:text-emerald-400">{formatCurrency(period.totalNet)}</p>
      </div>
      <div className="col-span-1" onClick={(e) => e.stopPropagation()}>
        {period.status === 'draft' && (
          <Button variant="outline" size="sm" onClick={onProcess}>
            Process
          </Button>
        )}
        {period.status === 'processing' && (
          <Button variant="primary" size="sm" onClick={onApprove}>
            <CheckCircle size={14} />
            Approve
          </Button>
        )}
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────
// Expanded Detail — Pay Stubs
// ────────────────────────────────────────────────────────

function PayPeriodDetail({
  stubs,
  loading,
}: {
  stubs: PayStub[];
  loading: boolean;
}) {
  if (loading) {
    return (
      <div className="px-6 pb-6 pt-2 bg-secondary/30 border-t border-main">
        <div className="space-y-2">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="p-3 bg-surface border border-main rounded-lg">
              <div className="skeleton h-4 w-40 mb-2" />
              <div className="skeleton h-3 w-64" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="px-6 pb-6 pt-2 bg-secondary/30 border-t border-main">
      <h4 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
        <FileText size={14} />
        Pay Stubs ({stubs.length})
      </h4>

      {stubs.length === 0 ? (
        <p className="text-sm text-muted py-2">No pay stubs for this period</p>
      ) : (
        <div className="space-y-2">
          {/* Stub Header */}
          <div className="grid grid-cols-12 gap-3 px-3 py-2 text-xs font-medium text-muted uppercase tracking-wider">
            <div className="col-span-2">Employee</div>
            <div className="col-span-1">Reg Hrs</div>
            <div className="col-span-1">OT Hrs</div>
            <div className="col-span-2">Gross Pay</div>
            <div className="col-span-2">Taxes</div>
            <div className="col-span-2">Deductions</div>
            <div className="col-span-2">Net Pay</div>
          </div>

          {stubs.map((stub) => {
            const totalTaxes = stub.federalTax + stub.stateTax + stub.localTax + stub.socialSecurity + stub.medicare;

            return (
              <div key={stub.id} className="grid grid-cols-12 gap-3 items-center p-3 bg-surface border border-main rounded-lg">
                <div className="col-span-2">
                  <p className="text-sm font-medium text-main truncate">
                    {stub.userId.slice(0, 8)}...
                  </p>
                  <p className="text-xs text-muted capitalize">{stub.paymentMethod.replace('_', ' ')}</p>
                </div>
                <div className="col-span-1">
                  <p className="text-sm text-main">{stub.hoursRegular}h</p>
                </div>
                <div className="col-span-1">
                  <p className={cn('text-sm', stub.hoursOvertime > 0 ? 'text-amber-600 dark:text-amber-400 font-medium' : 'text-muted')}>
                    {stub.hoursOvertime}h
                  </p>
                </div>
                <div className="col-span-2">
                  <p className="text-sm font-semibold text-main">{formatCurrency(stub.grossPay)}</p>
                </div>
                <div className="col-span-2">
                  <p className="text-sm text-red-600 dark:text-red-400">{formatCurrency(totalTaxes)}</p>
                  <p className="text-[10px] text-muted">
                    Fed {formatCurrency(stub.federalTax)} / St {formatCurrency(stub.stateTax)}
                  </p>
                </div>
                <div className="col-span-2">
                  <p className="text-sm text-muted">{formatCurrency(stub.totalDeductions)}</p>
                  {stub.retirement401k > 0 && (
                    <p className="text-[10px] text-muted">401k: {formatCurrency(stub.retirement401k)}</p>
                  )}
                </div>
                <div className="col-span-2">
                  <p className="text-sm font-semibold text-emerald-600 dark:text-emerald-400">
                    {formatCurrency(stub.netPay)}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
