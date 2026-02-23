'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  Building2,
  TrendingUp,
  TrendingDown,
  DollarSign,
  ClipboardList,
  AlertTriangle,
  RefreshCw,
  ChevronRight,
  ChevronLeft,
  ArrowUpRight,
  ArrowDownRight,
  BarChart3,
  Receipt,
  Clock,
  Star,
  FileCheck,
  PieChart,
  Loader2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import {
  useTpaFinancials,
  formatCurrency,
  formatPercent,
  type ProgramFinancialSummary,
} from '@/lib/hooks/use-tpa-financials';
import { useTranslation } from '@/lib/translations';

// ============================================================================
// CONSTANTS
// ============================================================================

const MONTH_NAMES = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const PROGRAM_TYPE_LABELS: Record<string, string> = {
  national: 'National',
  regional: 'Regional',
  carrier_direct: 'Carrier Direct',
  independent: 'Independent',
};

const PROGRAM_TYPE_COLORS: Record<string, string> = {
  national: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
  regional: 'bg-purple-500/10 text-purple-400 border-purple-500/20',
  carrier_direct: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
  independent: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
};

// ============================================================================
// COMPONENT: Period Selector
// ============================================================================

function PeriodSelector({
  month,
  year,
  onChange,
}: {
  month: number;
  year: number;
  onChange: (m: number, y: number) => void;
}) {
  const prev = () => {
    if (month === 1) onChange(12, year - 1);
    else onChange(month - 1, year);
  };
  const next = () => {
    if (month === 12) onChange(1, year + 1);
    else onChange(month + 1, year);
  };

  return (
    <div className="flex items-center gap-2">
      <Button variant="outline" size="icon" onClick={prev} className="h-8 w-8">
        <ChevronLeft className="h-4 w-4" />
      </Button>
      <span className="text-sm font-medium min-w-[140px] text-center">
        {MONTH_NAMES[month - 1]} {year}
      </span>
      <Button variant="outline" size="icon" onClick={next} className="h-8 w-8">
        <ChevronRight className="h-4 w-4" />
      </Button>
    </div>
  );
}

// ============================================================================
// COMPONENT: Summary Cards
// ============================================================================

function SummaryCards({
  totalRevenue,
  avgGrossMarginPercent,
  totalAssignmentsReceived,
  totalAssignmentsCompleted,
  totalReferralFees,
  totalArOutstanding,
  totalSlaViolations,
  avgSupplementApprovalRate,
}: {
  totalRevenue: number;
  avgGrossMarginPercent: number;
  totalAssignmentsReceived: number;
  totalAssignmentsCompleted: number;
  totalReferralFees: number;
  totalArOutstanding: number;
  totalSlaViolations: number;
  avgSupplementApprovalRate: number;
}) {
  const cards = [
    {
      title: 'Total Revenue',
      value: formatCurrency(totalRevenue),
      icon: DollarSign,
      color: 'text-emerald-400',
      bg: 'bg-emerald-500/10',
    },
    {
      title: 'Gross Margin',
      value: formatPercent(avgGrossMarginPercent),
      icon: avgGrossMarginPercent >= 30 ? TrendingUp : TrendingDown,
      color: avgGrossMarginPercent >= 30 ? 'text-emerald-400' : 'text-red-400',
      bg: avgGrossMarginPercent >= 30 ? 'bg-emerald-500/10' : 'bg-red-500/10',
    },
    {
      title: 'Assignments',
      value: `${totalAssignmentsCompleted}/${totalAssignmentsReceived}`,
      icon: ClipboardList,
      color: 'text-blue-400',
      bg: 'bg-blue-500/10',
    },
    {
      title: 'Referral Fees',
      value: formatCurrency(totalReferralFees),
      icon: Receipt,
      color: 'text-amber-400',
      bg: 'bg-amber-500/10',
    },
    {
      title: 'AR Outstanding',
      value: formatCurrency(totalArOutstanding),
      icon: Clock,
      color: totalArOutstanding > 0 ? 'text-orange-400' : 'text-zinc-400',
      bg: totalArOutstanding > 0 ? 'bg-orange-500/10' : 'bg-zinc-500/10',
    },
    {
      title: 'SLA Violations',
      value: String(totalSlaViolations),
      icon: AlertTriangle,
      color: totalSlaViolations > 0 ? 'text-red-400' : 'text-emerald-400',
      bg: totalSlaViolations > 0 ? 'bg-red-500/10' : 'bg-emerald-500/10',
    },
    {
      title: 'Supplement Rate',
      value: formatPercent(avgSupplementApprovalRate),
      icon: FileCheck,
      color: avgSupplementApprovalRate >= 70 ? 'text-emerald-400' : 'text-amber-400',
      bg: avgSupplementApprovalRate >= 70 ? 'bg-emerald-500/10' : 'bg-amber-500/10',
    },
  ];

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3">
      {cards.map((card) => (
        <Card key={card.title} className="bg-zinc-900 border-zinc-800">
          <CardContent className="p-3">
            <div className="flex items-center gap-2 mb-1">
              <div className={cn('p-1 rounded', card.bg)}>
                <card.icon className={cn('h-3.5 w-3.5', card.color)} />
              </div>
              <span className="text-[11px] text-zinc-400 truncate">{card.title}</span>
            </div>
            <p className="text-lg font-semibold text-white">{card.value}</p>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}

// ============================================================================
// COMPONENT: Program Card
// ============================================================================

function ProgramCard({ summary }: { summary: ProgramFinancialSummary }) {
  const { t } = useTranslation();
  const typeColor = PROGRAM_TYPE_COLORS[summary.programType] || PROGRAM_TYPE_COLORS.independent;
  const typeLabel = PROGRAM_TYPE_LABELS[summary.programType] || summary.programType;
  const marginHealthy = summary.grossMarginPercent >= 30;

  return (
    <Card className="bg-zinc-900 border-zinc-800 hover:border-zinc-700 transition-colors">
      <CardContent className="p-4">
        {/* Header */}
        <div className="flex items-start justify-between mb-3">
          <div className="min-w-0 flex-1">
            <h3 className="font-medium text-white truncate">{summary.programName}</h3>
            <Badge variant="secondary" className={cn('mt-1 text-[10px]', typeColor)}>
              {typeLabel}
            </Badge>
          </div>
          <Link href={`/dashboard/tpa/assignments?program=${summary.programId}`}>
            <Button variant="ghost" size="icon" className="h-7 w-7 text-zinc-400 hover:text-white">
              <ChevronRight className="h-4 w-4" />
            </Button>
          </Link>
        </div>

        {/* Revenue + Margin */}
        <div className="grid grid-cols-2 gap-3 mb-3">
          <div>
            <span className="text-[11px] text-zinc-500">{t('common.revenue')}</span>
            <p className="text-sm font-semibold text-white">{formatCurrency(summary.totalRevenue)}</p>
          </div>
          <div>
            <span className="text-[11px] text-zinc-500">{t('common.margin')}</span>
            <div className="flex items-center gap-1">
              {marginHealthy ? (
                <ArrowUpRight className="h-3 w-3 text-emerald-400" />
              ) : (
                <ArrowDownRight className="h-3 w-3 text-red-400" />
              )}
              <p className={cn('text-sm font-semibold', marginHealthy ? 'text-emerald-400' : 'text-red-400')}>
                {formatPercent(summary.grossMarginPercent)}
              </p>
            </div>
          </div>
        </div>

        {/* Stats Row */}
        <div className="grid grid-cols-3 gap-2 pt-3 border-t border-zinc-800">
          <div className="text-center">
            <span className="text-[10px] text-zinc-500 block">{t('common.jobs')}</span>
            <span className="text-xs font-medium text-white">
              {summary.assignmentsCompleted}/{summary.assignmentsReceived}
            </span>
          </div>
          <div className="text-center">
            <span className="text-[10px] text-zinc-500 block">{t('common.referral')}</span>
            <span className="text-xs font-medium text-amber-400">
              {formatCurrency(summary.referralFeesPaid)}
            </span>
          </div>
          <div className="text-center">
            <span className="text-[10px] text-zinc-500 block">{t('common.score')}</span>
            <span className="text-xs font-medium text-white flex items-center justify-center gap-0.5">
              {summary.avgScorecardRating != null ? (
                <>
                  <Star className="h-3 w-3 text-amber-400 fill-amber-400" />
                  {summary.avgScorecardRating.toFixed(1)}
                </>
              ) : (
                <span className="text-zinc-500">--</span>
              )}
            </span>
          </div>
        </div>

        {/* Warnings */}
        {(summary.slaViolationsCount > 0 || summary.arTotal > 0) && (
          <div className="mt-3 pt-3 border-t border-zinc-800 flex flex-wrap gap-2">
            {summary.slaViolationsCount > 0 && (
              <Badge variant="secondary" className="bg-red-500/10 text-red-400 border-red-500/20 text-[10px]">
                <AlertTriangle className="h-3 w-3 mr-1" />
                {summary.slaViolationsCount} SLA violations
              </Badge>
            )}
            {summary.arTotal > 0 && (
              <Badge variant="secondary" className="bg-orange-500/10 text-orange-400 border-orange-500/20 text-[10px]">
                <Clock className="h-3 w-3 mr-1" />
                {formatCurrency(summary.arTotal)} AR
              </Badge>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ============================================================================
// COMPONENT: P&L Table
// ============================================================================

function PnLTable({
  summaries,
  totalRevenue,
  totalCost,
}: {
  summaries: ProgramFinancialSummary[];
  totalRevenue: number;
  totalCost: number;
}) {
  const { t } = useTranslation();
  if (summaries.length === 0) return null;

  return (
    <Card className="bg-zinc-900 border-zinc-800">
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium text-white flex items-center gap-2">
          <BarChart3 className="h-4 w-4 text-blue-400" />
          P&L by Program
        </CardTitle>
      </CardHeader>
      <CardContent className="p-0">
        <div className="overflow-x-auto">
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-zinc-800 text-zinc-400">
                <th className="text-left px-4 py-2 font-medium">Program</th>
                <th className="text-right px-4 py-2 font-medium">{t('common.revenue')}</th>
                <th className="text-right px-4 py-2 font-medium">{t('common.cost')}</th>
                <th className="text-right px-4 py-2 font-medium">{t('common.margin')}</th>
                <th className="text-right px-4 py-2 font-medium">Margin %</th>
                <th className="text-right px-4 py-2 font-medium">{t('common.referral')}</th>
                <th className="text-right px-4 py-2 font-medium">Supp. Rate</th>
              </tr>
            </thead>
            <tbody>
              {summaries.map((s) => {
                const margin = s.totalRevenue - s.totalCost;
                return (
                  <tr key={s.programId} className="border-b border-zinc-800/50 hover:bg-zinc-800/30">
                    <td className="px-4 py-2 text-white font-medium">{s.programName}</td>
                    <td className="text-right px-4 py-2 text-white">{formatCurrency(s.totalRevenue)}</td>
                    <td className="text-right px-4 py-2 text-zinc-400">{formatCurrency(s.totalCost)}</td>
                    <td className={cn('text-right px-4 py-2 font-medium', margin >= 0 ? 'text-emerald-400' : 'text-red-400')}>
                      {formatCurrency(margin)}
                    </td>
                    <td className={cn('text-right px-4 py-2', s.grossMarginPercent >= 30 ? 'text-emerald-400' : 'text-red-400')}>
                      {formatPercent(s.grossMarginPercent)}
                    </td>
                    <td className="text-right px-4 py-2 text-amber-400">{formatCurrency(s.referralFeesPaid)}</td>
                    <td className="text-right px-4 py-2 text-zinc-300">{formatPercent(s.supplementApprovalRate)}</td>
                  </tr>
                );
              })}
            </tbody>
            <tfoot>
              <tr className="border-t border-zinc-700 font-medium">
                <td className="px-4 py-2 text-white">{t('common.total')}</td>
                <td className="text-right px-4 py-2 text-white">{formatCurrency(totalRevenue)}</td>
                <td className="text-right px-4 py-2 text-zinc-400">{formatCurrency(totalCost)}</td>
                <td className={cn('text-right px-4 py-2', totalRevenue - totalCost >= 0 ? 'text-emerald-400' : 'text-red-400')}>
                  {formatCurrency(totalRevenue - totalCost)}
                </td>
                <td className="text-right px-4 py-2 text-zinc-400">
                  {totalRevenue > 0 ? formatPercent(((totalRevenue - totalCost) / totalRevenue) * 100) : '--'}
                </td>
                <td className="text-right px-4 py-2 text-amber-400">
                  {formatCurrency(summaries.reduce((s, p) => s + p.referralFeesPaid, 0))}
                </td>
                <td className="text-right px-4 py-2 text-zinc-400">--</td>
              </tr>
            </tfoot>
          </table>
        </div>
      </CardContent>
    </Card>
  );
}

// ============================================================================
// COMPONENT: Assignment Pipeline
// ============================================================================

function AssignmentPipeline({ summaries }: { summaries: ProgramFinancialSummary[] }) {
  const totalReceived = summaries.reduce((s, p) => s + p.assignmentsReceived, 0);
  const totalCompleted = summaries.reduce((s, p) => s + p.assignmentsCompleted, 0);

  if (totalReceived === 0) return null;

  const completionRate = Math.round((totalCompleted / totalReceived) * 100);

  return (
    <Card className="bg-zinc-900 border-zinc-800">
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium text-white flex items-center gap-2">
          <PieChart className="h-4 w-4 text-purple-400" />
          Assignment Pipeline
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex items-center gap-4 mb-4">
          <div className="flex-1">
            <div className="flex justify-between text-xs mb-1">
              <span className="text-zinc-400">Completion Rate</span>
              <span className="text-white font-medium">{completionRate}%</span>
            </div>
            <div className="h-2 bg-zinc-800 rounded-full overflow-hidden">
              <div
                className="h-full bg-emerald-500 rounded-full transition-all"
                style={{ width: `${completionRate}%` }}
              />
            </div>
          </div>
          <div className="text-right">
            <span className="text-xl font-bold text-white">{totalReceived}</span>
            <span className="text-xs text-zinc-400 block">total</span>
          </div>
        </div>

        {/* Per-program bars */}
        <div className="space-y-2">
          {summaries.map((s) => {
            const pct = s.assignmentsReceived > 0
              ? Math.round((s.assignmentsCompleted / s.assignmentsReceived) * 100)
              : 0;
            return (
              <div key={s.programId} className="flex items-center gap-3">
                <span className="text-[11px] text-zinc-400 min-w-[100px] truncate">{s.programName}</span>
                <div className="flex-1 h-1.5 bg-zinc-800 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-blue-500 rounded-full"
                    style={{ width: `${pct}%` }}
                  />
                </div>
                <span className="text-[11px] text-zinc-300 min-w-[40px] text-right">
                  {s.assignmentsCompleted}/{s.assignmentsReceived}
                </span>
              </div>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}

// ============================================================================
// PAGE: TPA Dashboard
// ============================================================================

export default function TpaDashboardPage() {
  const { t } = useTranslation();
  const now = new Date();
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [year, setYear] = useState(now.getFullYear());
  const [recalculating, setRecalculating] = useState(false);

  const { overview, loading, error, recalculate } = useTpaFinancials(month, year);

  const handleRecalculate = async () => {
    setRecalculating(true);
    await recalculate();
    setRecalculating(false);
  };

  return (
    <div className="p-6 space-y-6 max-w-[1600px] mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-white flex items-center gap-2">
            <Building2 className="h-5 w-5 text-blue-400" />
            {t('tpaDashboard.title')}
          </h1>
          <p className="text-sm text-zinc-400 mt-0.5">
            Program performance, financials, and compliance overview
          </p>
        </div>
        <div className="flex items-center gap-3">
          <PeriodSelector month={month} year={year} onChange={(m, y) => { setMonth(m); setYear(y); }} />
          <Button
            variant="outline"
            size="sm"
            onClick={handleRecalculate}
            disabled={recalculating || loading}
          >
            {recalculating ? (
              <Loader2 className="h-4 w-4 mr-1 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4 mr-1" />
            )}
            Recalculate
          </Button>
          <Link href="/dashboard/tpa/assignments">
            <Button size="sm">
              <ClipboardList className="h-4 w-4 mr-1" />
              Assignments
            </Button>
          </Link>
        </div>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="h-6 w-6 animate-spin text-zinc-400" />
          <span className="ml-2 text-sm text-zinc-400">{t('common.loadingFinancialData')}</span>
        </div>
      )}

      {/* Error State */}
      {error && !loading && (
        <Card className="bg-red-500/5 border-red-500/20">
          <CardContent className="p-4 flex items-center gap-3">
            <AlertTriangle className="h-5 w-5 text-red-400" />
            <div>
              <p className="text-sm font-medium text-red-400">Failed to load data</p>
              <p className="text-xs text-red-400/70">{error}</p>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Data State */}
      {!loading && !error && (
        <>
          {/* Summary Cards */}
          <SummaryCards
            totalRevenue={overview.totalRevenue}
            avgGrossMarginPercent={overview.avgGrossMarginPercent}
            totalAssignmentsReceived={overview.totalAssignmentsReceived}
            totalAssignmentsCompleted={overview.totalAssignmentsCompleted}
            totalReferralFees={overview.totalReferralFees}
            totalArOutstanding={overview.totalArOutstanding}
            totalSlaViolations={overview.totalSlaViolations}
            avgSupplementApprovalRate={overview.avgSupplementApprovalRate}
          />

          {/* Empty State */}
          {overview.programSummaries.length === 0 && (
            <Card className="bg-zinc-900 border-zinc-800">
              <CardContent className="py-12 text-center">
                <Building2 className="h-10 w-10 text-zinc-600 mx-auto mb-3" />
                <p className="text-sm text-zinc-400">No financial data for {MONTH_NAMES[month - 1]} {year}</p>
                <p className="text-xs text-zinc-500 mt-1">
                  Click &quot;Recalculate&quot; to generate data from assignments and invoices
                </p>
              </CardContent>
            </Card>
          )}

          {/* Program Cards */}
          {overview.programSummaries.length > 0 && (
            <>
              <div>
                <h2 className="text-sm font-medium text-zinc-300 mb-3">Programs ({overview.programSummaries.length})</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3">
                  {overview.programSummaries.map((s) => (
                    <ProgramCard key={s.programId} summary={s} />
                  ))}
                </div>
              </div>

              {/* P&L Table + Pipeline side by side */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
                <div className="lg:col-span-2">
                  <PnLTable
                    summaries={overview.programSummaries}
                    totalRevenue={overview.totalRevenue}
                    totalCost={overview.totalCost}
                  />
                </div>
                <div>
                  <AssignmentPipeline summaries={overview.programSummaries} />
                </div>
              </div>
            </>
          )}
        </>
      )}
    </div>
  );
}
