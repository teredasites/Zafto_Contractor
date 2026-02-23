'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  Calendar,
  Lock,
  Unlock,
  ChevronDown,
  ChevronRight,
  CheckCircle,
  XCircle,
  AlertTriangle,
  RefreshCw,
  Shield,
  BookOpen,
  Clock,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import {
  useFiscalPeriods,
} from '@/lib/hooks/use-fiscal-periods';
import type { FiscalPeriodData, AuditLogEntry } from '@/lib/hooks/use-fiscal-periods';
import { useTranslation } from '@/lib/translations';

const zbooksNav = [
  { label: 'Overview', href: '/dashboard/books', active: false },
  { label: 'Reports', href: '/dashboard/books/reports', active: false },
  { label: 'Recurring', href: '/dashboard/books/recurring', active: false },
  { label: 'Periods', href: '/dashboard/books/periods', active: true },
];

const periodTypeBadge: Record<string, { label: string; variant: 'info' | 'purple' | 'warning' }> = {
  month: { label: 'Month', variant: 'info' },
  quarter: { label: 'Quarter', variant: 'purple' },
  year: { label: 'Year', variant: 'warning' },
};

// -------------------------------------------------------------------
// Reopen Reason Modal
// -------------------------------------------------------------------
function ReopenModal({
  periodName,
  onConfirm,
  onClose,
}: {
  periodName: string;
  onConfirm: (reason: string) => Promise<void>;
  onClose: () => void;
}) {
  const [reason, setReason] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reason.trim()) return;
    setSaving(true);
    try {
      await onConfirm(reason.trim());
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div
        className="bg-surface rounded-xl shadow-2xl w-full max-w-md border border-main"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="px-6 py-4 border-b border-main">
          <h2 className="text-lg font-semibold text-main">Reopen Period</h2>
          <p className="text-sm text-muted mt-1">
            Reopening &quot;{periodName}&quot; allows new entries to be posted. A reason is required for the audit trail.
          </p>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1">Reason *</label>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              rows={3}
              className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm resize-none"
              placeholder="e.g., Late adjustment needed for vendor invoice"
              required
              autoFocus
            />
          </div>
          <div className="flex justify-end gap-3">
            <Button type="button" variant="secondary" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" variant="danger" disabled={saving || !reason.trim()}>
              {saving ? 'Reopening...' : 'Reopen Period'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}

// -------------------------------------------------------------------
// Year-End Close Confirmation Modal
// -------------------------------------------------------------------
function YearEndCloseModal({
  year,
  onConfirm,
  onClose,
}: {
  year: number;
  onConfirm: () => Promise<void>;
  onClose: () => void;
}) {
  const [confirmed, setConfirmed] = useState(false);
  const [running, setRunning] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!confirmed) return;
    setRunning(true);
    try {
      await onConfirm();
    } finally {
      setRunning(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div
        className="bg-surface rounded-xl shadow-2xl w-full max-w-lg border border-main"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="px-6 py-4 border-b border-main">
          <h2 className="text-lg font-semibold text-main">Year-End Close - FY {year}</h2>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div className="p-4 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg">
            <div className="flex gap-3">
              <AlertTriangle size={20} className="text-amber-600 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-amber-800 dark:text-amber-200 space-y-2">
                <p className="font-medium">This action will:</p>
                <ul className="list-disc list-inside space-y-1">
                  <li>Create a closing journal entry zeroing all revenue and expense accounts</li>
                  <li>Post the net income (or loss) to Retained Earnings (3200)</li>
                  <li>Mark FY {year} as retained earnings posted</li>
                </ul>
                <p>This entry will be posted as of December 31, {year}.</p>
              </div>
            </div>
          </div>

          <label className="flex items-center gap-3 cursor-pointer">
            <input
              type="checkbox"
              checked={confirmed}
              onChange={(e) => setConfirmed(e.target.checked)}
              className="w-4 h-4 rounded border-gray-300 text-accent focus:ring-accent"
            />
            <span className="text-sm text-main">
              I understand this is a permanent accounting action and have reviewed all period balances.
            </span>
          </label>

          <div className="flex justify-end gap-3 pt-2">
            <Button type="button" variant="secondary" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={!confirmed || running}>
              {running ? 'Processing...' : `Close FY ${year}`}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}

// -------------------------------------------------------------------
// Period Row
// -------------------------------------------------------------------
function PeriodRow({
  period,
  onClose,
  onReopen,
}: {
  period: FiscalPeriodData;
  onClose: (id: string) => Promise<void>;
  onReopen: (id: string) => void;
}) {
  const { t } = useTranslation();
  const [closing, setClosing] = useState(false);
  const typeCfg = periodTypeBadge[period.periodType] || periodTypeBadge.month;

  const handleClose = async () => {
    setClosing(true);
    try {
      await onClose(period.id);
    } finally {
      setClosing(false);
    }
  };

  return (
    <tr className="border-b border-default last:border-b-0 hover:bg-secondary/50 transition-colors">
      {/* Period Name */}
      <td className="px-6 py-3">
        <span className="text-sm font-medium text-main">{period.periodName}</span>
      </td>

      {/* Type */}
      <td className="px-4 py-3">
        <Badge variant={typeCfg.variant} size="sm">{typeCfg.label}</Badge>
      </td>

      {/* Start Date */}
      <td className="px-4 py-3">
        <span className="text-sm text-muted tabular-nums">{period.startDate}</span>
      </td>

      {/* End Date */}
      <td className="px-4 py-3">
        <span className="text-sm text-muted tabular-nums">{period.endDate}</span>
      </td>

      {/* Status */}
      <td className="px-4 py-3">
        {period.isClosed ? (
          <Badge variant="error" size="sm" dot>{t('common.closed')}</Badge>
        ) : (
          <Badge variant="success" size="sm" dot>{t('common.open')}</Badge>
        )}
      </td>

      {/* Closed At */}
      <td className="px-4 py-3">
        <span className="text-xs text-muted tabular-nums">
          {period.closedAt ? new Date(period.closedAt).toLocaleDateString() : '--'}
        </span>
      </td>

      {/* Actions */}
      <td className="px-4 py-3">
        <div className="flex items-center gap-2 justify-end">
          {period.isClosed ? (
            <button
              onClick={() => onReopen(period.id)}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-amber-700 dark:text-amber-300 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg hover:bg-amber-100 dark:hover:bg-amber-900/30 transition-colors"
              title="Reopen period"
            >
              <Unlock size={12} />
              Reopen
            </button>
          ) : (
            <button
              onClick={handleClose}
              disabled={closing}
              className={cn(
                'inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg transition-colors border',
                closing
                  ? 'text-muted border-main bg-secondary'
                  : 'text-red-700 dark:text-red-300 bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800 hover:bg-red-100 dark:hover:bg-red-900/30'
              )}
              title="Close period"
            >
              {closing ? (
                <RefreshCw size={12} className="animate-spin" />
              ) : (
                <Lock size={12} />
              )}
              {closing ? 'Closing...' : 'Close'}
            </button>
          )}
        </div>
      </td>
    </tr>
  );
}

// -------------------------------------------------------------------
// Main Page
// -------------------------------------------------------------------
export default function FiscalPeriodsPage() {
  const { t, formatDate } = useTranslation();
  const router = useRouter();
  const {
    periods,
    loading,
    generatePeriodsForYear,
    closePeriod,
    reopenPeriod,
    yearEndClose,
    fetchAuditLog,
  } = useFiscalPeriods();

  const currentYear = new Date().getFullYear();
  const [selectedYear, setSelectedYear] = useState(currentYear);
  const [generating, setGenerating] = useState(false);
  const [reopenModalPeriod, setReopenModalPeriod] = useState<FiscalPeriodData | null>(null);
  const [yearEndModal, setYearEndModal] = useState(false);
  const [yearEndResult, setYearEndResult] = useState<{ closingEntryId?: string; error?: string } | null>(null);
  const [auditLogOpen, setAuditLogOpen] = useState(false);
  const [auditEntries, setAuditEntries] = useState<AuditLogEntry[]>([]);
  const [auditLoading, setAuditLoading] = useState(false);

  // Year range: current year +/- 3
  const years = Array.from({ length: 7 }, (_, i) => currentYear - 3 + i);

  // Filter periods by selected year
  const yearStart = `${selectedYear}-01-01`;
  const yearEnd = `${selectedYear}-12-31`;
  const filteredPeriods = periods.filter(
    (p) => p.startDate >= yearStart && p.endDate <= yearEnd
  );

  const monthlyPeriods = filteredPeriods.filter((p) => p.periodType === 'month');
  const quarterlyPeriods = filteredPeriods.filter((p) => p.periodType === 'quarter');
  const yearPeriod = filteredPeriods.find((p) => p.periodType === 'year');

  // Summary stats
  const totalPeriods = monthlyPeriods.length;
  const closedCount = monthlyPeriods.filter((p) => p.isClosed).length;
  const allMonthlyClosed = totalPeriods === 12 && closedCount === 12;
  const yearEndDone = yearPeriod?.retainedEarningsPosted ?? false;

  // Handle generate periods
  const handleGenerate = async () => {
    setGenerating(true);
    try {
      await generatePeriodsForYear(selectedYear);
    } finally {
      setGenerating(false);
    }
  };

  // Handle close period
  const handleClose = async (id: string) => {
    await closePeriod(id);
  };

  // Handle reopen
  const handleReopenClick = (id: string) => {
    const period = filteredPeriods.find((p) => p.id === id);
    if (period) setReopenModalPeriod(period);
  };

  const handleReopenConfirm = async (reason: string) => {
    if (!reopenModalPeriod) return;
    await reopenPeriod(reopenModalPeriod.id, reason);
    setReopenModalPeriod(null);
  };

  // Handle year-end close
  const handleYearEndClose = async () => {
    const result = await yearEndClose(selectedYear);
    setYearEndModal(false);
    if (result.success) {
      setYearEndResult({ closingEntryId: result.closingEntryId });
    } else {
      setYearEndResult({ error: result.error });
    }
  };

  // Toggle audit log
  const handleToggleAuditLog = async () => {
    if (!auditLogOpen) {
      setAuditLoading(true);
      const entries = await fetchAuditLog();
      setAuditEntries(entries);
      setAuditLoading(false);
    }
    setAuditLogOpen(!auditLogOpen);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-2 border-accent border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="p-8 space-y-6 max-w-[1400px] mx-auto">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('booksPeriods.title')}</h1>
          <p className="text-muted mt-1">Manage accounting periods and year-end close</p>
        </div>
        <div className="flex items-center gap-3">
          {/* Year Selector */}
          <select
            value={selectedYear}
            onChange={(e) => {
              setSelectedYear(Number(e.target.value));
              setYearEndResult(null);
            }}
            className="px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
          >
            {years.map((y) => (
              <option key={y} value={y}>FY {y}</option>
            ))}
          </select>
          <Button onClick={handleGenerate} disabled={generating} variant="primary">
            {generating ? (
              <>
                <RefreshCw size={16} className="animate-spin" />
                Generating...
              </>
            ) : (
              <>
                <Calendar size={16} />
                Generate Periods
              </>
            )}
          </Button>
        </div>
      </div>

      {/* Ledger Navigation */}
      <div className="flex items-center gap-2">
        {zbooksNav.map((tab) => (
          <button
            key={tab.label}
            onClick={() => { if (!tab.active) router.push(tab.href); }}
            className={cn(
              'px-4 py-2 text-sm font-medium rounded-lg transition-colors',
              tab.active
                ? 'bg-accent text-white'
                : 'bg-secondary text-muted hover:text-main'
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-blue-500/10 flex items-center justify-center">
                <Calendar size={20} className="text-blue-500" />
              </div>
              <div>
                <p className="text-muted text-xs">Monthly Periods</p>
                <p className="text-xl font-bold text-main">{closedCount} / {totalPeriods > 0 ? totalPeriods : 12}</p>
                <p className="text-xs text-muted">closed</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center gap-3">
              <div className={cn(
                'w-10 h-10 rounded-lg flex items-center justify-center',
                allMonthlyClosed ? 'bg-emerald-500/10' : 'bg-amber-500/10'
              )}>
                {allMonthlyClosed ? (
                  <CheckCircle size={20} className="text-emerald-500" />
                ) : (
                  <AlertTriangle size={20} className="text-amber-500" />
                )}
              </div>
              <div>
                <p className="text-muted text-xs">Year-End Ready</p>
                <p className="text-xl font-bold text-main">{allMonthlyClosed ? 'Yes' : 'No'}</p>
                <p className="text-xs text-muted">
                  {allMonthlyClosed ? 'All periods closed' : `${12 - closedCount} period${12 - closedCount !== 1 ? 's' : ''} still open`}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center gap-3">
              <div className={cn(
                'w-10 h-10 rounded-lg flex items-center justify-center',
                yearEndDone ? 'bg-emerald-500/10' : 'bg-slate-500/10'
              )}>
                <BookOpen size={20} className={yearEndDone ? 'text-emerald-500' : 'text-slate-400'} />
              </div>
              <div>
                <p className="text-muted text-xs">Retained Earnings</p>
                <p className="text-xl font-bold text-main">{yearEndDone ? 'Posted' : 'Pending'}</p>
                <p className="text-xs text-muted">FY {selectedYear}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Year-End Result Message */}
      {yearEndResult && (
        <div className={cn(
          'p-4 rounded-lg border text-sm',
          yearEndResult.error
            ? 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800 text-red-700 dark:text-red-300'
            : 'bg-emerald-50 dark:bg-emerald-900/20 border-emerald-200 dark:border-emerald-800 text-emerald-700 dark:text-emerald-300'
        )}>
          <div className="flex items-start gap-3">
            {yearEndResult.error ? (
              <XCircle size={18} className="flex-shrink-0 mt-0.5" />
            ) : (
              <CheckCircle size={18} className="flex-shrink-0 mt-0.5" />
            )}
            <div>
              {yearEndResult.error ? (
                <p>{yearEndResult.error}</p>
              ) : (
                <div>
                  <p className="font-medium">Year-end close completed successfully.</p>
                  <p className="mt-1">
                    Closing journal entry created: <span className="font-mono font-medium">YE-{selectedYear}</span>
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Monthly Periods Table */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Monthly Periods - FY {selectedYear}</CardTitle>
            {totalPeriods === 0 && (
              <p className="text-xs text-muted">No periods generated. Click &quot;Generate Periods&quot; to create them.</p>
            )}
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {monthlyPeriods.length === 0 ? (
            <div className="px-6 py-12 text-center">
              <Calendar size={40} className="mx-auto text-muted mb-3" />
              <h3 className="text-sm font-medium text-main mb-1">No monthly periods</h3>
              <p className="text-xs text-muted mb-4">
                Generate periods for FY {selectedYear} to get started.
              </p>
              <Button size="sm" onClick={handleGenerate} disabled={generating}>
                <Calendar size={14} />
                Generate Periods
              </Button>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="text-xs font-medium text-muted uppercase tracking-wide bg-secondary/50 border-b border-default">
                    <th className="px-6 py-3 text-left">{t('common.period')}</th>
                    <th className="px-4 py-3 text-left">{t('common.type')}</th>
                    <th className="px-4 py-3 text-left">{t('common.start')}</th>
                    <th className="px-4 py-3 text-left">{t('common.end')}</th>
                    <th className="px-4 py-3 text-left">{t('common.status')}</th>
                    <th className="px-4 py-3 text-left">Closed At</th>
                    <th className="px-4 py-3 text-right">{t('common.actions')}</th>
                  </tr>
                </thead>
                <tbody>
                  {monthlyPeriods
                    .sort((a, b) => a.startDate.localeCompare(b.startDate))
                    .map((period) => (
                      <PeriodRow
                        key={period.id}
                        period={period}
                        onClose={handleClose}
                        onReopen={handleReopenClick}
                      />
                    ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Quarterly + Yearly Periods */}
      {(quarterlyPeriods.length > 0 || yearPeriod) && (
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Quarterly &amp; Annual Periods</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="text-xs font-medium text-muted uppercase tracking-wide bg-secondary/50 border-b border-default">
                    <th className="px-6 py-3 text-left">{t('common.period')}</th>
                    <th className="px-4 py-3 text-left">{t('common.type')}</th>
                    <th className="px-4 py-3 text-left">{t('common.start')}</th>
                    <th className="px-4 py-3 text-left">{t('common.end')}</th>
                    <th className="px-4 py-3 text-left">{t('common.status')}</th>
                    <th className="px-4 py-3 text-left">Closed At</th>
                    <th className="px-4 py-3 text-right">{t('common.actions')}</th>
                  </tr>
                </thead>
                <tbody>
                  {[...quarterlyPeriods, ...(yearPeriod ? [yearPeriod] : [])]
                    .sort((a, b) => a.startDate.localeCompare(b.startDate))
                    .map((period) => (
                      <PeriodRow
                        key={period.id}
                        period={period}
                        onClose={handleClose}
                        onReopen={handleReopenClick}
                      />
                    ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Year-End Close Section */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center gap-3">
            <Shield size={18} className="text-accent" />
            <CardTitle className="text-base">Year-End Close - FY {selectedYear}</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Checklist */}
          <div className="space-y-3">
            <p className="text-sm font-medium text-main">Requirements Checklist</p>

            {/* Requirement 1: All monthly periods generated */}
            <div className="flex items-center gap-3 px-4 py-3 rounded-lg bg-secondary/50">
              {totalPeriods === 12 ? (
                <CheckCircle size={18} className="text-emerald-500 flex-shrink-0" />
              ) : (
                <XCircle size={18} className="text-red-400 flex-shrink-0" />
              )}
              <span className="text-sm text-main">
                All 12 monthly periods generated
              </span>
              <span className="text-xs text-muted ml-auto tabular-nums">
                {totalPeriods} / 12
              </span>
            </div>

            {/* Requirement 2: All monthly periods closed */}
            <div className="flex items-center gap-3 px-4 py-3 rounded-lg bg-secondary/50">
              {allMonthlyClosed ? (
                <CheckCircle size={18} className="text-emerald-500 flex-shrink-0" />
              ) : (
                <XCircle size={18} className="text-red-400 flex-shrink-0" />
              )}
              <span className="text-sm text-main">
                All monthly periods closed
              </span>
              <span className="text-xs text-muted ml-auto tabular-nums">
                {closedCount} / 12 closed
              </span>
            </div>

            {/* Requirement 3: Year-end not already posted */}
            <div className="flex items-center gap-3 px-4 py-3 rounded-lg bg-secondary/50">
              {!yearEndDone ? (
                <CheckCircle size={18} className="text-emerald-500 flex-shrink-0" />
              ) : (
                <AlertTriangle size={18} className="text-amber-500 flex-shrink-0" />
              )}
              <span className="text-sm text-main">
                {yearEndDone ? 'Retained earnings already posted for this year' : 'Retained earnings not yet posted'}
              </span>
            </div>
          </div>

          {/* Close Year Button */}
          <div className="flex items-center gap-4 pt-2">
            <Button
              onClick={() => setYearEndModal(true)}
              disabled={!allMonthlyClosed || yearEndDone}
              variant={allMonthlyClosed && !yearEndDone ? 'primary' : 'secondary'}
            >
              <BookOpen size={16} />
              {yearEndDone ? 'Year Already Closed' : 'Close Year'}
            </Button>
            {!allMonthlyClosed && !yearEndDone && (
              <p className="text-xs text-muted">
                Close all monthly periods before performing year-end close.
              </p>
            )}
            {yearEndDone && (
              <p className="text-xs text-emerald-600 dark:text-emerald-400">
                Year-end closing entry has been posted. Retained earnings are up to date.
              </p>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Audit Log Section (collapsible) */}
      <Card>
        <CardHeader
          className="pb-3 cursor-pointer"
          onClick={handleToggleAuditLog}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Clock size={18} className="text-muted" />
              <CardTitle className="text-base">Period Audit Log</CardTitle>
            </div>
            <div className="flex items-center gap-2 text-muted">
              <span className="text-xs">{auditLogOpen ? 'Collapse' : 'Expand'}</span>
              {auditLogOpen ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
            </div>
          </div>
        </CardHeader>
        {auditLogOpen && (
          <CardContent className="p-0 border-t border-main">
            {auditLoading ? (
              <div className="flex items-center gap-2 px-6 py-8 justify-center text-sm text-muted">
                <RefreshCw size={14} className="animate-spin" />
                Loading audit log...
              </div>
            ) : auditEntries.length === 0 ? (
              <div className="px-6 py-8 text-center text-sm text-muted">
                No period audit entries found.
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="text-xs font-medium text-muted uppercase tracking-wide bg-secondary/50 border-b border-default">
                      <th className="px-6 py-3 text-left">Timestamp</th>
                      <th className="px-4 py-3 text-left">{t('common.action')}</th>
                      <th className="px-4 py-3 text-left">{t('common.summary')}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {auditEntries.map((entry) => (
                      <tr key={entry.id} className="border-b border-default last:border-b-0">
                        <td className="px-6 py-3">
                          <span className="text-xs text-muted tabular-nums">
                            {formatDate(entry.createdAt)}
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          <Badge
                            variant={entry.action === 'period_closed' ? 'error' : 'warning'}
                            size="sm"
                          >
                            {entry.action === 'period_closed' ? 'Closed' : 'Reopened'}
                          </Badge>
                        </td>
                        <td className="px-4 py-3">
                          <span className="text-sm text-main">
                            {entry.changeSummary || '--'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        )}
      </Card>

      {/* Reopen Modal */}
      {reopenModalPeriod && (
        <ReopenModal
          periodName={reopenModalPeriod.periodName}
          onConfirm={handleReopenConfirm}
          onClose={() => setReopenModalPeriod(null)}
        />
      )}

      {/* Year-End Close Modal */}
      {yearEndModal && (
        <YearEndCloseModal
          year={selectedYear}
          onConfirm={handleYearEndClose}
          onClose={() => setYearEndModal(false)}
        />
      )}
    </div>
  );
}
