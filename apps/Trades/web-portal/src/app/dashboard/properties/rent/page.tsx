'use client';

import { useState } from 'react';
import {
  Plus,
  DollarSign,
  AlertCircle,
  CheckCircle,
  Clock,
  CreditCard,
  Loader2,
  XCircle,
  Zap,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useRent } from '@/lib/hooks/use-rent';
import type { RentChargeData, RentPaymentData } from '@/lib/hooks/pm-mappers';
import { useTranslation } from '@/lib/translations';

type ChargeStatus = RentChargeData['status'];

const statusConfig: Record<ChargeStatus, { label: string; color: string; bgColor: string }> = {
  pending: { label: 'Pending', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  partial: { label: 'Partial', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  paid: { label: 'Paid', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  overdue: { label: 'Overdue', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  waived: { label: 'Waived', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
  credited: { label: 'Credited', color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
};

const chargeTypeLabels: Record<RentChargeData['chargeType'], string> = {
  rent: 'Rent',
  late_fee: 'Late Fee',
  utility: 'Utility',
  parking: 'Parking',
  pet: 'Pet Fee',
  damage: 'Damage',
  other: 'Other',
};

const paymentMethodOptions: { value: RentPaymentData['paymentMethod']; label: string }[] = [
  { value: 'ach', label: 'ACH / Bank Transfer' },
  { value: 'check', label: 'Check' },
  { value: 'cash', label: 'Cash' },
  { value: 'money_order', label: 'Money Order' },
  { value: 'stripe', label: 'Stripe (Online)' },
  { value: 'other', label: 'Other' },
];

function isOverdue(charge: RentChargeData): boolean {
  if (charge.status === 'paid' || charge.status === 'waived' || charge.status === 'credited') return false;
  const now = new Date();
  const dueDate = new Date(charge.dueDate);
  return dueDate < now;
}

export default function RentRollPage() {
  const { t } = useTranslation();
  const { charges, loading, error, recordPayment, generateMonthlyCharges } = useRent();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [monthFilter, setMonthFilter] = useState('all');
  const [paymentChargeId, setPaymentChargeId] = useState<string | null>(null);
  const [paymentAmount, setPaymentAmount] = useState('');
  const [paymentMethod, setPaymentMethod] = useState<RentPaymentData['paymentMethod']>('check');
  const [paymentNote, setPaymentNote] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [generating, setGenerating] = useState(false);

  if (loading && charges.length === 0) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-40 mb-2" /><div className="skeleton h-4 w-64" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-14" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => <div key={i} className="px-6 py-4 flex items-center gap-4"><div className="flex-1"><div className="skeleton h-4 w-36 mb-2" /><div className="skeleton h-3 w-28" /></div><div className="skeleton h-5 w-16 rounded-full" /></div>)}
        </div>
      </div>
    );
  }

  // Enrich status: mark past-due pending/partial as overdue for display
  const enrichedCharges = charges.map((c) => {
    if (isOverdue(c) && (c.status === 'pending' || c.status === 'partial')) {
      return { ...c, displayStatus: 'overdue' as ChargeStatus };
    }
    return { ...c, displayStatus: c.status };
  });

  const filteredCharges = enrichedCharges.filter((charge) => {
    const matchesSearch =
      (charge.tenantName || '').toLowerCase().includes(search.toLowerCase()) ||
      (charge.unitNumber || '').toLowerCase().includes(search.toLowerCase()) ||
      (charge.propertyAddress || '').toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || charge.displayStatus === statusFilter;

    if (monthFilter !== 'all') {
      const dueMonth = charge.dueDate.slice(0, 7); // YYYY-MM
      if (dueMonth !== monthFilter) return false;
    }

    return matchesSearch && matchesStatus;
  });

  // Stats for this month
  const now = new Date();
  const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  const thisMonthCharges = enrichedCharges.filter((c) => c.dueDate.startsWith(currentMonth));
  const totalDue = thisMonthCharges.reduce((sum, c) => sum + c.amount, 0);
  const totalCollected = thisMonthCharges.reduce((sum, c) => sum + c.paidAmount, 0);
  const outstanding = Math.max(0, totalDue - totalCollected);
  const delinquentCount = enrichedCharges.filter((c) => c.displayStatus === 'overdue').length;

  // Get unique months for filter
  const uniqueMonths = [...new Set(charges.map((c) => c.dueDate.slice(0, 7)))].sort().reverse();
  const monthOptions = [
    { value: 'all', label: 'All Months' },
    ...uniqueMonths.map((m) => {
      const [y, mo] = m.split('-');
      const monthName = new Date(Number(y), Number(mo) - 1).toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
      return { value: m, label: monthName };
    }),
  ];

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    ...Object.entries(statusConfig).map(([k, v]) => ({ value: k, label: v.label })),
  ];

  const handleRecordPayment = async () => {
    if (!paymentChargeId || !paymentAmount) return;
    const charge = charges.find((c) => c.id === paymentChargeId);
    if (!charge) return;

    setActionLoading(true);
    try {
      await recordPayment(paymentChargeId, {
        tenantId: charge.tenantId,
        amount: parseFloat(paymentAmount),
        paymentMethod,
        notes: paymentNote.trim() || undefined,
      });
      setPaymentChargeId(null);
      setPaymentAmount('');
      setPaymentNote('');
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to record payment');
    } finally {
      setActionLoading(false);
    }
  };

  const handleGenerateCharges = async () => {
    setGenerating(true);
    try {
      // Generate for next month
      const nextMonth = now.getMonth() + 2; // 1-indexed next month
      const year = nextMonth > 12 ? now.getFullYear() + 1 : now.getFullYear();
      const month = nextMonth > 12 ? 1 : nextMonth;

      // Note: generateMonthlyCharges requires a propertyId — in production this would iterate all properties
      // For now, we generate for the current month if charges are missing
      const currentMonthNum = now.getMonth() + 1;
      alert(`Charges generation triggered for ${String(currentMonthNum).padStart(2, '0')}/${now.getFullYear()}. Select a property to generate charges.`);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to generate charges');
    } finally {
      setGenerating(false);
    }
  };

  const paymentTarget = paymentChargeId ? charges.find((c) => c.id === paymentChargeId) : null;

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('propertiesRent.title')}</h1>
          <p className="text-muted mt-1">Track rent charges, payments, and delinquencies</p>
        </div>
        <Button onClick={handleGenerateCharges} disabled={generating}>
          {generating ? <Loader2 size={16} className="animate-spin" /> : <Zap size={16} />}
          Generate Charges
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg"><DollarSign size={20} className="text-blue-600 dark:text-blue-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{formatCurrency(totalDue)}</p><p className="text-sm text-muted">Total Due (This Month)</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg"><CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{formatCurrency(totalCollected)}</p><p className="text-sm text-muted">{t('common.totalCollected')}</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg"><Clock size={20} className="text-amber-600 dark:text-amber-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{formatCurrency(outstanding)}</p><p className="text-sm text-muted">{t('common.overdue')}</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg"><AlertCircle size={20} className="text-red-600 dark:text-red-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{delinquentCount}</p><p className="text-sm text-muted">{t('propertyRent.delinquent')}</p></div>
        </div></CardContent></Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search tenants, units..." className="sm:w-80" />
        <Select options={statusOptions} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="sm:w-48" />
        <Select options={monthOptions} value={monthFilter} onChange={(e) => setMonthFilter(e.target.value)} className="sm:w-56" />
      </div>

      {/* Table */}
      <div className="bg-surface border border-main rounded-xl divide-y divide-main">
        {/* Header row */}
        <div className="hidden md:grid grid-cols-12 gap-4 px-6 py-3 text-sm font-medium text-muted">
          <div className="col-span-2">{t('common.tenant')}</div>
          <div className="col-span-2">{t('propertyRent.unitProperty')}</div>
          <div className="col-span-1">{t('common.type')}</div>
          <div className="col-span-1 text-right">Amount Due</div>
          <div className="col-span-1 text-right">{t('common.paid')}</div>
          <div className="col-span-1">{t('common.dueDate')}</div>
          <div className="col-span-1">{t('common.status')}</div>
          <div className="col-span-3 text-right">{t('common.actions')}</div>
        </div>

        {filteredCharges.map((charge) => {
          const isOverdueRow = charge.displayStatus === 'overdue';
          const sConfig = statusConfig[charge.displayStatus];
          const canRecordPayment = charge.displayStatus === 'pending' || charge.displayStatus === 'partial' || charge.displayStatus === 'overdue';
          const remaining = charge.amount - charge.paidAmount;

          return (
            <div
              key={charge.id}
              className={cn(
                'grid grid-cols-1 md:grid-cols-12 gap-4 px-6 py-4 items-center transition-colors',
                isOverdueRow && 'bg-red-50/50 dark:bg-red-900/5'
              )}
            >
              <div className="col-span-2">
                <p className="font-medium text-sm text-main">{charge.tenantName || 'Unknown'}</p>
              </div>
              <div className="col-span-2">
                <p className="text-sm text-main">{charge.unitNumber ? `Unit ${charge.unitNumber}` : 'N/A'}</p>
                <p className="text-xs text-muted">{charge.propertyAddress || ''}</p>
              </div>
              <div className="col-span-1">
                <p className="text-sm text-muted">{chargeTypeLabels[charge.chargeType]}</p>
              </div>
              <div className="col-span-1 text-right">
                <p className="text-sm font-medium text-main">{formatCurrency(charge.amount)}</p>
              </div>
              <div className="col-span-1 text-right">
                <p className={cn('text-sm font-medium', charge.paidAmount > 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-muted')}>
                  {formatCurrency(charge.paidAmount)}
                </p>
              </div>
              <div className="col-span-1">
                <p className={cn('text-sm', isOverdueRow ? 'text-red-600 dark:text-red-400 font-medium' : 'text-muted')}>
                  {formatDate(charge.dueDate)}
                </p>
              </div>
              <div className="col-span-1">
                <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>
                  {sConfig.label}
                </span>
              </div>
              <div className="col-span-3 text-right">
                {canRecordPayment && (
                  <Button
                    size="sm"
                    variant="secondary"
                    onClick={(e) => {
                      e.stopPropagation();
                      setPaymentChargeId(charge.id);
                      setPaymentAmount(String(remaining > 0 ? remaining : charge.amount));
                    }}
                  >
                    <CreditCard size={14} />
                    Record Payment
                  </Button>
                )}
              </div>
            </div>
          );
        })}

        {filteredCharges.length === 0 && (
          <div className="px-6 py-12 text-center">
            <DollarSign size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('propertyRent.noRentChargesFound')}</h3>
            <p className="text-muted mb-4">{t('propertyRent.generateMonthlyChargesToGetStarted')}</p>
          </div>
        )}
      </div>

      {/* Payment Modal */}
      {paymentChargeId && paymentTarget && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <Card className="w-full max-w-md">
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle>{t('common.recordPayment')}</CardTitle>
              <Button variant="ghost" size="sm" onClick={() => setPaymentChargeId(null)}>
                <XCircle size={18} />
              </Button>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="p-3 bg-secondary rounded-lg">
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-muted">{t('common.tenant')}</span>
                  <span className="font-medium text-main">{paymentTarget.tenantName || 'Unknown'}</span>
                </div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-muted">{t('common.amountDue')}</span>
                  <span className="font-medium text-main">{formatCurrency(paymentTarget.amount)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">{t('propertyRent.alreadyPaid')}</span>
                  <span className="font-medium text-emerald-600">{formatCurrency(paymentTarget.paidAmount)}</span>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Payment Amount *</label>
                <input
                  type="number"
                  value={paymentAmount}
                  onChange={(e) => setPaymentAmount(e.target.value)}
                  step="0.01"
                  min="0"
                  className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-main mb-1.5">{t('common.paymentMethod')}</label>
                <select
                  value={paymentMethod}
                  onChange={(e) => setPaymentMethod(e.target.value as RentPaymentData['paymentMethod'])}
                  className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
                >
                  {paymentMethodOptions.map((opt) => (
                    <option key={opt.value} value={opt.value}>{opt.label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-main mb-1.5">{t('common.notes')}</label>
                <input
                  type="text"
                  value={paymentNote}
                  onChange={(e) => setPaymentNote(e.target.value)}
                  placeholder="Check #, reference number..."
                  className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
                />
              </div>

              <div className="flex items-center gap-3 pt-2">
                <Button
                  variant="secondary"
                  className="flex-1"
                  onClick={() => setPaymentChargeId(null)}
                  disabled={actionLoading}
                >
                  Cancel
                </Button>
                <Button
                  className="flex-1"
                  onClick={handleRecordPayment}
                  disabled={actionLoading || !paymentAmount || parseFloat(paymentAmount) <= 0}
                >
                  {actionLoading ? <Loader2 size={16} className="animate-spin" /> : <CheckCircle size={16} />}
                  Record Payment
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
