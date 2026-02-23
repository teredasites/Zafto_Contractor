'use client';

// J4: Job Intelligence Dashboard — profitability trends, top/bottom types, tech performance

import { useState, useMemo } from 'react';
import Link from 'next/link';
import {
  BarChart3,
  TrendingUp,
  TrendingDown,
  DollarSign,
  Briefcase,
  AlertTriangle,
  ChevronRight,
  Lightbulb,
  HardHat,
  Percent,
} from 'lucide-react';
import { useJobIntelligence, type JobCostAutopsy, type AutopsyInsight } from '@/lib/hooks/use-job-intelligence';
import { useTranslation } from '@/lib/translations';

export default function JobIntelligencePage() {
  const { t } = useTranslation();
  const { autopsies, insights, summary, pendingAdjustments, insightsByType, loading, error } =
    useJobIntelligence();
  const [activeTab, setActiveTab] = useState<'overview' | 'types' | 'techs' | 'trends'>('overview');

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin h-8 w-8 border-2 border-blue-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-96 text-zinc-400">
        <AlertTriangle className="h-12 w-12 mb-4 text-red-400" />
        <p>Failed to load intelligence data</p>
      </div>
    );
  }

  const tabs = [
    { key: 'overview' as const, label: 'Overview' },
    { key: 'types' as const, label: 'By Job Type' },
    { key: 'techs' as const, label: 'By Technician' },
    { key: 'trends' as const, label: 'Trends' },
  ];

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-semibold text-white">{t('jobIntelligence.title')}</h1>
          <p className="text-sm text-zinc-400 mt-1">
            Profitability analysis from {summary.totalJobs} completed jobs
          </p>
        </div>
        {pendingAdjustments.length > 0 && (
          <Link
            href="/dashboard/job-intelligence/adjustments"
            className="flex items-center gap-2 px-4 py-2 bg-amber-500/10 border border-amber-500/30 rounded-lg text-amber-400 hover:bg-amber-500/20 transition-colors"
          >
            <Lightbulb className="h-4 w-4" />
            <span className="text-sm font-medium">
              {pendingAdjustments.length} pricing suggestion{pendingAdjustments.length !== 1 ? 's' : ''}
            </span>
            <ChevronRight className="h-4 w-4" />
          </Link>
        )}
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <StatCard
          icon={Briefcase}
          label="Jobs Analyzed"
          value={summary.totalJobs.toString()}
        />
        <StatCard
          icon={Percent}
          label="Avg Margin"
          value={`${summary.avgMargin.toFixed(1)}%`}
          valueColor={summary.avgMargin >= 20 ? 'text-emerald-400' : summary.avgMargin >= 10 ? 'text-amber-400' : 'text-red-400'}
        />
        <StatCard
          icon={DollarSign}
          label={t('customers.totalRevenue')}
          value={fmtMoney(summary.totalRevenue)}
        />
        <StatCard
          icon={TrendingUp}
          label="Total Profit"
          value={fmtMoney(summary.totalProfit)}
          valueColor={summary.totalProfit >= 0 ? 'text-emerald-400' : 'text-red-400'}
        />
      </div>

      {/* Tabs */}
      <div className="flex gap-1 mb-6 bg-zinc-800/50 p-1 rounded-lg w-fit">
        {tabs.map((t) => (
          <button
            key={t.key}
            onClick={() => setActiveTab(t.key)}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              activeTab === t.key
                ? 'bg-zinc-700 text-white'
                : 'text-zinc-400 hover:text-zinc-200'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'overview' && (
        <OverviewTab autopsies={autopsies} summary={summary} />
      )}
      {activeTab === 'types' && (
        <ByTypeTab insights={insightsByType('profitability_by_job_type')} />
      )}
      {activeTab === 'techs' && (
        <ByTechTab insights={insightsByType('profitability_by_tech')} />
      )}
      {activeTab === 'trends' && (
        <TrendsTab insights={insightsByType('variance_trend')} autopsies={autopsies} />
      )}
    </div>
  );
}

// ── Stat Card ──

function StatCard({
  icon: Icon,
  label,
  value,
  valueColor = 'text-white',
}: {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  value: string;
  valueColor?: string;
}) {
  return (
    <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-4">
      <Icon className="h-5 w-5 text-zinc-500 mb-2" />
      <p className={`text-xl font-bold ${valueColor}`}>{value}</p>
      <p className="text-xs text-zinc-500 mt-1">{label}</p>
    </div>
  );
}

// ── Overview Tab ──

function OverviewTab({
  autopsies,
  summary,
}: {
  autopsies: JobCostAutopsy[];
  summary: { overBudgetCount: number; totalJobs: number };
}) {
  const recent = autopsies.slice(0, 15);
  const overPct = summary.totalJobs > 0
    ? ((summary.overBudgetCount / summary.totalJobs) * 100).toFixed(0)
    : '0';

  return (
    <div className="space-y-6">
      {/* Over budget warning */}
      {summary.overBudgetCount > 0 && (
        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-4 flex items-center gap-3">
          <AlertTriangle className="h-5 w-5 text-red-400 flex-shrink-0" />
          <div>
            <p className="text-sm font-medium text-red-300">
              {summary.overBudgetCount} of {summary.totalJobs} jobs ({overPct}%) went over budget
            </p>
            <p className="text-xs text-red-400/60 mt-1">
              Review job types with consistent overruns in the &quot;By Job Type&quot; tab
            </p>
          </div>
        </div>
      )}

      {/* Recent autopsies list */}
      <div>
        <h3 className="text-sm font-medium text-zinc-300 mb-3">Recent Job Autopsies</h3>
        {recent.length === 0 ? (
          <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-8 text-center">
            <BarChart3 className="h-10 w-10 text-zinc-600 mx-auto mb-3" />
            <p className="text-zinc-500 text-sm">No autopsies yet. Complete jobs to generate analysis.</p>
          </div>
        ) : (
          <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl divide-y divide-zinc-700/50">
            {recent.map((a) => {
              const margin = a.gross_margin_pct || 0;
              const revenue = a.revenue || 0;
              const variance = a.variance_pct || 0;

              return (
                <Link
                  key={a.id}
                  href={`/dashboard/job-intelligence/${a.job_id}`}
                  className="flex items-center justify-between px-4 py-3 hover:bg-zinc-700/30 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <div
                      className={`w-10 h-10 rounded-lg flex items-center justify-center text-xs font-bold ${
                        margin >= 20
                          ? 'bg-emerald-500/15 text-emerald-400'
                          : margin >= 10
                          ? 'bg-amber-500/15 text-amber-400'
                          : 'bg-red-500/15 text-red-400'
                      }`}
                    >
                      {margin.toFixed(0)}%
                    </div>
                    <div>
                      <p className="text-sm font-medium text-zinc-200">
                        {(a.job_type || 'Unknown').replace(/_/g, ' ')}
                      </p>
                      <p className="text-xs text-zinc-500">
                        {a.completed_at
                          ? new Date(a.completed_at).toLocaleDateString()
                          : 'No date'}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-4">
                    <div className="text-right">
                      <p className="text-sm text-zinc-300">{fmtMoney(revenue)}</p>
                      <p className={`text-xs ${variance > 0 ? 'text-red-400' : 'text-emerald-400'}`}>
                        {variance > 0 ? '+' : ''}{variance.toFixed(1)}% variance
                      </p>
                    </div>
                    <ChevronRight className="h-4 w-4 text-zinc-600" />
                  </div>
                </Link>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

// ── By Type Tab ──

function ByTypeTab({ insights }: { insights: AutopsyInsight[] }) {
  if (insights.length === 0) {
    return <EmptyState message="Complete more jobs to see type-based insights" />;
  }

  // Sort by margin descending
  const sorted = [...insights].sort((a, b) => {
    const aMargin = (a.insight_data?.avg_margin_pct as number) || 0;
    const bMargin = (b.insight_data?.avg_margin_pct as number) || 0;
    return bMargin - aMargin;
  });

  return (
    <div className="space-y-3">
      {sorted.map((ins) => {
        const data = ins.insight_data;
        const margin = (data.avg_margin_pct as number) || 0;
        const revenue = (data.total_revenue as number) || 0;
        const profit = (data.total_profit as number) || 0;
        const variance = (data.avg_variance_pct as number) || 0;
        const count = (data.job_count as number) || 0;
        const confidence = ins.confidence_score || 0;

        return (
          <div
            key={ins.id}
            className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-5"
          >
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-semibold text-zinc-200 uppercase tracking-wide">
                {(ins.insight_key || '').replace(/_/g, ' ')}
              </h3>
              <span
                className={`text-xs px-2 py-0.5 rounded-full ${
                  confidence >= 0.7
                    ? 'bg-emerald-500/15 text-emerald-400'
                    : 'bg-amber-500/15 text-amber-400'
                }`}
              >
                {(confidence * 100).toFixed(0)}% confidence
              </span>
            </div>
            <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
              <MiniStat
                label="Avg Margin"
                value={`${margin.toFixed(1)}%`}
                color={margin >= 20 ? 'text-emerald-400' : margin >= 10 ? 'text-amber-400' : 'text-red-400'}
              />
              <MiniStat label="Revenue" value={fmtMoney(revenue)} />
              <MiniStat
                label="Profit"
                value={fmtMoney(profit)}
                color={profit >= 0 ? 'text-emerald-400' : 'text-red-400'}
              />
              <MiniStat
                label="Avg Variance"
                value={`${variance > 0 ? '+' : ''}${variance.toFixed(1)}%`}
                color={variance > 5 ? 'text-red-400' : variance < -5 ? 'text-emerald-400' : 'text-zinc-300'}
              />
              <MiniStat label="Jobs" value={count.toString()} />
            </div>
          </div>
        );
      })}
    </div>
  );
}

// ── By Tech Tab ──

function ByTechTab({ insights }: { insights: AutopsyInsight[] }) {
  if (insights.length === 0) {
    return <EmptyState message="Complete more jobs to see technician insights" />;
  }

  const sorted = [...insights].sort((a, b) => {
    const aMargin = (a.insight_data?.avg_margin_pct as number) || 0;
    const bMargin = (b.insight_data?.avg_margin_pct as number) || 0;
    return bMargin - aMargin;
  });

  return (
    <div className="space-y-3">
      {sorted.map((ins, idx) => {
        const data = ins.insight_data;
        const margin = (data.avg_margin_pct as number) || 0;
        const revenue = (data.total_revenue as number) || 0;
        const avgHours = (data.avg_labor_hours as number) || 0;
        const count = (data.job_count as number) || 0;

        return (
          <div
            key={ins.id}
            className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-5"
          >
            <div className="flex items-center gap-3 mb-3">
              <div
                className={`w-8 h-8 rounded-lg flex items-center justify-center text-xs font-bold ${
                  idx === 0
                    ? 'bg-emerald-500/15 text-emerald-400'
                    : 'bg-zinc-700/50 text-zinc-400'
                }`}
              >
                #{idx + 1}
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <HardHat className="h-4 w-4 text-zinc-500" />
                  <p className="text-sm font-medium text-zinc-200">Technician</p>
                </div>
                <p className="text-xs text-zinc-600">
                  {(ins.insight_key || '').substring(0, 8)}...
                </p>
              </div>
            </div>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <MiniStat
                label="Margin"
                value={`${margin.toFixed(1)}%`}
                color={margin >= 20 ? 'text-emerald-400' : margin >= 10 ? 'text-amber-400' : 'text-red-400'}
              />
              <MiniStat label="Revenue" value={fmtMoney(revenue)} />
              <MiniStat label="Avg Hours" value={`${avgHours.toFixed(1)}h`} />
              <MiniStat label="Jobs" value={count.toString()} />
            </div>
          </div>
        );
      })}
    </div>
  );
}

// ── Trends Tab ──

function TrendsTab({
  insights,
  autopsies,
}: {
  insights: AutopsyInsight[];
  autopsies: JobCostAutopsy[];
}) {
  const trendInsight = insights[0];
  const trendData = trendInsight
    ? ((trendInsight.insight_data?.trend) as Array<{
        month: string;
        avg_variance: number;
        count: number;
      }>) || []
    : [];

  // Monthly margin summary from autopsies
  const monthlyMargins = useMemo(() => {
    const groups: Record<string, { total: number; count: number }> = {};
    for (const a of autopsies) {
      const date = a.completed_at;
      if (!date) continue;
      const month = date.slice(0, 7);
      if (!groups[month]) groups[month] = { total: 0, count: 0 };
      groups[month].total += a.gross_margin_pct || 0;
      groups[month].count++;
    }
    return Object.entries(groups)
      .map(([month, data]) => ({
        month,
        avgMargin: data.total / data.count,
        count: data.count,
      }))
      .sort((a, b) => a.month.localeCompare(b.month));
  }, [autopsies]);

  if (monthlyMargins.length === 0 && trendData.length === 0) {
    return <EmptyState message="Need more data to show trends" />;
  }

  return (
    <div className="space-y-6">
      {/* Margin trend */}
      {monthlyMargins.length > 0 && (
        <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-5">
          <h3 className="text-sm font-medium text-zinc-300 mb-4">Monthly Margin Trend</h3>
          <div className="space-y-2">
            {monthlyMargins.map((m) => {
              const barWidth = Math.min(Math.max(m.avgMargin, 0), 50) * 2;
              return (
                <div key={m.month} className="flex items-center gap-3">
                  <span className="text-xs text-zinc-500 w-16">{m.month}</span>
                  <div className="flex-1 h-6 bg-zinc-700/30 rounded relative">
                    <div
                      className={`h-full rounded ${
                        m.avgMargin >= 20
                          ? 'bg-emerald-500/40'
                          : m.avgMargin >= 10
                          ? 'bg-amber-500/40'
                          : 'bg-red-500/40'
                      }`}
                      style={{ width: `${barWidth}%` }}
                    />
                    <span className="absolute inset-y-0 left-2 flex items-center text-xs text-zinc-300">
                      {m.avgMargin.toFixed(1)}%
                    </span>
                  </div>
                  <span className="text-xs text-zinc-600 w-12">{m.count} jobs</span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Variance trend */}
      {trendData.length > 0 && (
        <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-5">
          <h3 className="text-sm font-medium text-zinc-300 mb-4">Cost Variance Trend</h3>
          <div className="space-y-2">
            {trendData.map((t) => (
              <div key={t.month} className="flex items-center gap-3">
                <span className="text-xs text-zinc-500 w-16">{t.month}</span>
                <div className="flex-1 flex items-center">
                  {t.avg_variance > 0 ? (
                    <TrendingUp className="h-4 w-4 text-red-400 mr-2" />
                  ) : (
                    <TrendingDown className="h-4 w-4 text-emerald-400 mr-2" />
                  )}
                  <span
                    className={`text-sm font-medium ${
                      t.avg_variance > 0 ? 'text-red-400' : 'text-emerald-400'
                    }`}
                  >
                    {t.avg_variance > 0 ? '+' : ''}{t.avg_variance.toFixed(1)}%
                  </span>
                </div>
                <span className="text-xs text-zinc-600 w-12">{t.count} jobs</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// ── Shared ──

function MiniStat({
  label,
  value,
  color = 'text-zinc-300',
}: {
  label: string;
  value: string;
  color?: string;
}) {
  return (
    <div>
      <p className={`text-sm font-semibold ${color}`}>{value}</p>
      <p className="text-xs text-zinc-500">{label}</p>
    </div>
  );
}

function EmptyState({ message }: { message: string }) {
  return (
    <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-12 text-center">
      <BarChart3 className="h-12 w-12 text-zinc-600 mx-auto mb-4" />
      <p className="text-zinc-500">{message}</p>
    </div>
  );
}

function fmtMoney(v: number): string {
  if (v >= 1000000) return `$${(v / 1000000).toFixed(1)}M`;
  if (v >= 1000) return `$${(v / 1000).toFixed(1)}K`;
  return `$${v.toFixed(0)}`;
}
