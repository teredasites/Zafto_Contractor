'use client';

// J4: Per-Job Autopsy Detail — estimated vs actual breakdown, variance callouts

import { useParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  AlertTriangle,
  TrendingUp,
  TrendingDown,
  Clock,
  Repeat,
  Car,
  DollarSign,
  FileBarChart,
} from 'lucide-react';
import { useJobIntelligence } from '@/lib/hooks/use-job-intelligence';
import { useTranslation } from '@/lib/translations';
import { formatCompactCurrency } from '@/lib/format-locale';

export default function JobAutopsyDetailPage() {
  const { t, formatDate } = useTranslation();
  const params = useParams();
  const jobId = params.jobId as string;
  const { autopsies, loading, error } = useJobIntelligence();

  const autopsy = autopsies.find((a) => a.job_id === jobId);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin h-8 w-8 border-2 border-blue-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  if (error || !autopsy) {
    return (
      <div className="p-6 max-w-4xl mx-auto">
        <Link
          href="/dashboard/job-intelligence"
          className="inline-flex items-center gap-2 text-sm text-zinc-400 hover:text-zinc-200 mb-6"
        >
          <ArrowLeft className="h-4 w-4" /> Back to Intelligence
        </Link>
        <div className="flex flex-col items-center justify-center h-64 text-zinc-400">
          <FileBarChart className="h-12 w-12 mb-4 text-zinc-600" />
          <p>{error ? 'Error loading data' : 'No autopsy found for this job'}</p>
        </div>
      </div>
    );
  }

  const margin = autopsy.gross_margin_pct || 0;
  const isProfitable = (autopsy.gross_profit || 0) > 0;
  const isOverBudget = (autopsy.variance_pct || 0) > 0;

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <Link
        href="/dashboard/job-intelligence"
        className="inline-flex items-center gap-2 text-sm text-zinc-400 hover:text-zinc-200 mb-6"
      >
        <ArrowLeft className="h-4 w-4" /> Back to Intelligence
      </Link>

      <h1 className="text-2xl font-semibold text-white mb-1">{t('jobIntelligence.title')}</h1>
      <p className="text-sm text-zinc-500 mb-6">
        {(autopsy.job_type || 'Unknown').replace(/_/g, ' ')}
        {autopsy.completed_at && ` — ${formatDate(autopsy.completed_at)}`}
      </p>

      {/* Profitability Header */}
      <div
        className={`rounded-xl p-6 mb-6 border ${
          isProfitable
            ? 'bg-emerald-500/5 border-emerald-500/20'
            : 'bg-red-500/5 border-red-500/20'
        }`}
      >
        <div className="flex items-center gap-6">
          <div
            className={`w-20 h-20 rounded-full flex items-center justify-center ${
              isProfitable ? 'bg-emerald-500/15' : 'bg-red-500/15'
            }`}
          >
            <span
              className={`text-2xl font-bold ${
                isProfitable ? 'text-emerald-400' : 'text-red-400'
              }`}
            >
              {margin.toFixed(1)}%
            </span>
          </div>
          <div>
            <p
              className={`text-xl font-semibold ${
                isProfitable ? 'text-emerald-400' : 'text-red-400'
              }`}
            >
              {isProfitable ? 'Profitable' : 'Unprofitable'}
            </p>
            <p className="text-sm text-zinc-400 mt-1">
              Revenue: {fmtMoney(autopsy.revenue || 0)} | Profit:{' '}
              {fmtMoney(autopsy.gross_profit || 0)}
            </p>
          </div>
        </div>
      </div>

      {/* Cost Comparison */}
      <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-5 mb-6">
        <h3 className="text-sm font-medium text-zinc-300 mb-4">{t('jobIntel.costComparison')}</h3>
        <div className="space-y-6">
          <ComparisonBar
            label={t('estimates.labor')}
            estimated={autopsy.estimated_labor_cost || 0}
            actual={autopsy.actual_labor_cost || 0}
          />
          <ComparisonBar
            label={t('estimates.material')}
            estimated={autopsy.estimated_material_cost || 0}
            actual={autopsy.actual_material_cost || 0}
          />
          <ComparisonBar
            label={t('invoices.total')}
            estimated={autopsy.estimated_total || 0}
            actual={autopsy.actual_total || 0}
          />
        </div>
      </div>

      {/* Variance Callouts */}
      <div className="space-y-3 mb-6">
        <h3 className="text-sm font-medium text-zinc-300">{t('jobIntel.varianceAnalysis')}</h3>

        {isOverBudget ? (
          <Callout
            icon={TrendingUp}
            color="text-red-400"
            bgColor="bg-red-500/10"
            borderColor="border-red-500/20"
            title={`Over budget by ${(autopsy.variance_pct || 0).toFixed(1)}%`}
            subtitle={`Actual exceeded estimate by ${fmtMoney((autopsy.actual_total || 0) - (autopsy.estimated_total || 0))}`}
          />
        ) : autopsy.estimated_total && autopsy.estimated_total > 0 ? (
          <Callout
            icon={TrendingDown}
            color="text-emerald-400"
            bgColor="bg-emerald-500/10"
            borderColor="border-emerald-500/20"
            title={`Under budget by ${(-(autopsy.variance_pct || 0)).toFixed(1)}%`}
            subtitle={`Saved ${fmtMoney((autopsy.estimated_total || 0) - (autopsy.actual_total || 0))} vs estimate`}
          />
        ) : null}

        {(autopsy.actual_labor_hours || 0) > (autopsy.estimated_labor_hours || 0) && (
          <Callout
            icon={Clock}
            color="text-amber-400"
            bgColor="bg-amber-500/10"
            borderColor="border-amber-500/20"
            title={`${((autopsy.actual_labor_hours || 0) - (autopsy.estimated_labor_hours || 0)).toFixed(1)}h extra labor`}
            subtitle={`Estimated ${(autopsy.estimated_labor_hours || 0).toFixed(1)}h, actual ${(autopsy.actual_labor_hours || 0).toFixed(1)}h`}
          />
        )}

        {autopsy.actual_callbacks > 0 && (
          <Callout
            icon={Repeat}
            color="text-amber-400"
            bgColor="bg-amber-500/10"
            borderColor="border-amber-500/20"
            title={`${autopsy.actual_callbacks} callback${autopsy.actual_callbacks === 1 ? '' : 's'}`}
            subtitle="Follow-up visits required after completion"
          />
        )}

        {autopsy.actual_drive_time_hours > 0 && (
          <Callout
            icon={Car}
            color="text-zinc-400"
            bgColor="bg-zinc-700/30"
            borderColor="border-zinc-700/50"
            title={`${autopsy.actual_drive_time_hours.toFixed(1)}h drive time`}
            subtitle={`${fmtMoney(autopsy.actual_drive_cost)} in mileage costs`}
          />
        )}
      </div>

      {/* Cost Breakdown */}
      <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-5 mb-6">
        <h3 className="text-sm font-medium text-zinc-300 mb-4">{t('jobIntel.actualCostBreakdown')}</h3>
        <div className="space-y-3">
          {[
            { label: 'Labor', value: autopsy.actual_labor_cost || 0 },
            { label: 'Materials', value: autopsy.actual_material_cost || 0 },
            { label: 'Drive Cost', value: autopsy.actual_drive_cost },
            { label: 'Change Orders', value: autopsy.actual_change_order_cost },
          ]
            .filter((item) => item.value > 0)
            .map((item) => {
              const total = autopsy.actual_total || 1;
              const pct = ((item.value / total) * 100).toFixed(0);
              return (
                <div key={item.label} className="flex items-center justify-between">
                  <span className="text-sm text-zinc-400">{item.label}</span>
                  <div className="flex items-center gap-3">
                    <span className="text-sm font-medium text-zinc-200">
                      {fmtMoney(item.value)}
                    </span>
                    <span className="text-xs text-zinc-600 w-10 text-right">{pct}%</span>
                  </div>
                </div>
              );
            })}
        </div>
      </div>

      {/* Metadata */}
      <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-5">
        <h3 className="text-sm font-medium text-zinc-300 mb-4">{t('jobIntel.jobInfo')}</h3>
        <div className="grid grid-cols-2 gap-4">
          <MetaRow label={t('hiring.jobType')} value={(autopsy.job_type || 'N/A').replace(/_/g, ' ')} />
          <MetaRow label={t('common.trade')} value={autopsy.trade_type || 'N/A'} />
          <MetaRow
            label={t('inspections.completed')}
            value={
              autopsy.completed_at
                ? formatDate(autopsy.completed_at)
                : 'N/A'
            }
          />
          <MetaRow
            label={t('estimates.laborHours')}
            value={`${(autopsy.actual_labor_hours || 0).toFixed(1)} actual / ${(autopsy.estimated_labor_hours || 0).toFixed(1)} est`}
          />
        </div>
      </div>
    </div>
  );
}

// ── Components ──

function ComparisonBar({
  label,
  estimated,
  actual,
}: {
  label: string;
  estimated: number;
  actual: number;
}) {
  const { t } = useTranslation();
  const max = Math.max(estimated, actual, 1);
  const isOver = actual > estimated;

  return (
    <div>
      <div className="flex items-center justify-between mb-1">
        <span className="text-xs text-zinc-500">{label}</span>
        <span className={`text-xs font-medium ${isOver ? 'text-red-400' : 'text-emerald-400'}`}>
          {isOver ? '+' : '-'}{fmtMoney(Math.abs(actual - estimated))}
        </span>
      </div>
      <div className="space-y-1">
        <div className="flex items-center gap-2">
          <span className="text-[10px] text-zinc-600 w-8">{t('jobIntel.est')}</span>
          <div className="flex-1 h-3 bg-zinc-700/30 rounded">
            <div
              className="h-full bg-blue-500/50 rounded"
              style={{ width: `${(estimated / max) * 100}%` }}
            />
          </div>
          <span className="text-[10px] text-zinc-500 w-16 text-right">{fmtMoney(estimated)}</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-[10px] text-zinc-600 w-8">{t('jobIntel.act')}</span>
          <div className="flex-1 h-3 bg-zinc-700/30 rounded">
            <div
              className={`h-full rounded ${isOver ? 'bg-red-500/50' : 'bg-emerald-500/50'}`}
              style={{ width: `${(actual / max) * 100}%` }}
            />
          </div>
          <span className="text-[10px] text-zinc-500 w-16 text-right">{fmtMoney(actual)}</span>
        </div>
      </div>
    </div>
  );
}

function Callout({
  icon: Icon,
  color,
  bgColor,
  borderColor,
  title,
  subtitle,
}: {
  icon: React.ComponentType<{ className?: string }>;
  color: string;
  bgColor: string;
  borderColor: string;
  title: string;
  subtitle: string;
}) {
  return (
    <div className={`${bgColor} border ${borderColor} rounded-xl p-4 flex items-center gap-3`}>
      <Icon className={`h-5 w-5 ${color} flex-shrink-0`} />
      <div>
        <p className={`text-sm font-medium ${color}`}>{title}</p>
        <p className="text-xs text-zinc-500 mt-0.5">{subtitle}</p>
      </div>
    </div>
  );
}

function MetaRow({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-xs text-zinc-500">{label}</p>
      <p className="text-sm text-zinc-300 capitalize">{value}</p>
    </div>
  );
}

function fmtMoney(v: number): string {
  return formatCompactCurrency(v);
}
