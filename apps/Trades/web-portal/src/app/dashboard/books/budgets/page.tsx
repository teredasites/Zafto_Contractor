'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';

import { useBudgetVsActual, CATEGORY_LABELS } from '@/lib/hooks/use-job-budgets';
import {
  DollarSign,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  ChevronRight,
  ArrowLeft,
} from 'lucide-react';
import Link from 'next/link';
import { useTranslation } from '@/lib/translations';

export default function BudgetsPage() {
  const { t } = useTranslation();
  const { summaries, loading, error } = useBudgetVsActual();
  const [expandedJob, setExpandedJob] = useState<string | null>(null);

  const totals = summaries.reduce(
    (acc, s) => ({
      budget: acc.budget + s.totalBudget,
      actual: acc.actual + s.totalActual,
      variance: acc.variance + s.variance,
    }),
    { budget: 0, actual: 0, variance: 0 }
  );

  return (
    <div className="space-y-8 animate-fade-in">
        <CommandPalette />

        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <div className="flex items-center gap-3 mb-1">
              <Link href="/dashboard/books" className="text-muted hover:text-main transition-colors">
                <ArrowLeft size={20} />
              </Link>
              <h1 className="text-2xl font-semibold text-main">{t('booksBudgets.title')}</h1>
            </div>
            <p className="text-[13px] text-muted ml-8">Compare job budgets to actual expenses. Identify overruns early.</p>
          </div>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <SummaryCard label="Total Budget" amount={totals.budget} icon={<DollarSign size={20} />} />
          <SummaryCard
            label="Total Actual"
            amount={totals.actual}
            icon={<TrendingUp size={20} />}
          />
          <SummaryCard
            label="Variance"
            amount={totals.variance}
            icon={totals.variance >= 0 ? <TrendingDown size={20} /> : <AlertTriangle size={20} />}
            variant={totals.variance >= 0 ? 'positive' : 'negative'}
          />
        </div>

        {/* Job Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle>Job-Level Breakdown</CardTitle>
            <CardDescription>Click a job to see category-level budget details</CardDescription>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="space-y-3">
                {[1, 2, 3].map((i) => (
                  <div key={i} className="h-16 bg-secondary rounded-lg animate-pulse" />
                ))}
              </div>
            ) : error ? (
              <div className="text-center py-8">
                <AlertTriangle size={32} className="mx-auto mb-2 text-red-500 opacity-60" />
                <p className="text-sm text-red-500">{error}</p>
              </div>
            ) : summaries.length === 0 ? (
              <div className="text-center py-8 text-muted">
                <DollarSign size={32} className="mx-auto mb-2 opacity-40" />
                <p>No job budgets created yet.</p>
                <p className="text-sm mt-1">Create budgets from the job detail page to start tracking.</p>
              </div>
            ) : (
              <div className="space-y-2">
                {summaries.map((summary) => (
                  <div key={summary.jobId} className="border border-main rounded-lg">
                    <div
                      className="flex items-center justify-between p-4 cursor-pointer hover:bg-surface-hover/50 transition-colors"
                      onClick={() =>
                        setExpandedJob(expandedJob === summary.jobId ? null : summary.jobId)
                      }
                    >
                      <div className="flex items-center gap-3">
                        <ChevronRight
                          size={16}
                          className={cn(
                            'text-muted transition-transform',
                            expandedJob === summary.jobId && 'rotate-90'
                          )}
                        />
                        <div>
                          <p className="font-medium text-main">{summary.jobName}</p>
                          <p className="text-sm text-muted">
                            {summary.categories.length} budget categories
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-6 text-sm">
                        <div className="text-right hidden sm:block">
                          <p className="text-muted text-xs">{t('common.budget')}</p>
                          <p className="font-medium text-main">
                            ${summary.totalBudget.toLocaleString()}
                          </p>
                        </div>
                        <div className="text-right hidden sm:block">
                          <p className="text-muted text-xs">{t('common.actual')}</p>
                          <p className="font-medium text-main">
                            ${summary.totalActual.toLocaleString()}
                          </p>
                        </div>
                        <div className="text-right">
                          <p className="text-muted text-xs">{t('common.variance')}</p>
                          <p
                            className={cn(
                              'font-medium',
                              summary.variance >= 0 ? 'text-emerald-500' : 'text-red-500'
                            )}
                          >
                            {summary.variance >= 0 ? '+' : ''}$
                            {summary.variance.toLocaleString()}
                          </p>
                        </div>
                        <Badge variant={summary.variance >= 0 ? 'success' : 'secondary'}>
                          <span
                            className={cn(summary.variance < 0 && 'text-red-600 dark:text-red-400')}
                          >
                            {summary.variance >= 0 ? 'Under' : 'Over'}
                          </span>
                        </Badge>
                      </div>
                    </div>

                    {expandedJob === summary.jobId && (
                      <div className="border-t border-main p-4">
                        <div className="grid grid-cols-5 gap-2 text-[11px] font-medium text-muted uppercase tracking-wider pb-2 border-b border-light">
                          <span>Category</span>
                          <span className="text-right">{t('common.budget')}</span>
                          <span className="text-right">{t('common.actual')}</span>
                          <span className="text-right">{t('common.variance')}</span>
                          <span className="text-right">Usage</span>
                        </div>
                        {summary.categories.map((cat) => {
                          const pct =
                            cat.budgeted > 0 ? (cat.actual / cat.budgeted) * 100 : 0;
                          return (
                            <div
                              key={cat.category}
                              className="grid grid-cols-5 gap-2 py-2.5 border-b border-light last:border-0 text-sm"
                            >
                              <span className="text-main font-medium">
                                {CATEGORY_LABELS[cat.category] || cat.category}
                              </span>
                              <span className="text-right text-muted">
                                ${cat.budgeted.toLocaleString()}
                              </span>
                              <span className="text-right text-main">
                                ${cat.actual.toLocaleString()}
                              </span>
                              <span
                                className={cn(
                                  'text-right font-medium',
                                  cat.variance >= 0 ? 'text-emerald-500' : 'text-red-500'
                                )}
                              >
                                {cat.variance >= 0 ? '+' : ''}${cat.variance.toLocaleString()}
                              </span>
                              <div className="flex items-center justify-end gap-2">
                                <div className="w-16 h-1.5 bg-secondary rounded-full overflow-hidden">
                                  <div
                                    className={cn(
                                      'h-full rounded-full transition-all',
                                      pct > 100
                                        ? 'bg-red-500'
                                        : pct > 80
                                          ? 'bg-amber-400'
                                          : 'bg-emerald-500'
                                    )}
                                    style={{ width: `${Math.min(pct, 100)}%` }}
                                  />
                                </div>
                                <span
                                  className={cn(
                                    'text-xs w-10 text-right',
                                    pct > 100 ? 'text-red-500' : 'text-muted'
                                  )}
                                >
                                  {pct.toFixed(0)}%
                                </span>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
  );
}

function SummaryCard({
  label,
  amount,
  icon,
  variant = 'default',
}: {
  label: string;
  amount: number;
  icon: React.ReactNode;
  variant?: 'default' | 'positive' | 'negative';
}) {
  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-xs font-medium text-muted uppercase tracking-wider">{label}</p>
            <p
              className={cn(
                'text-2xl font-semibold mt-1',
                variant === 'positive'
                  ? 'text-emerald-500'
                  : variant === 'negative'
                    ? 'text-red-500'
                    : 'text-main'
              )}
            >
              ${Math.abs(amount).toLocaleString()}
            </p>
          </div>
          <div
            className={cn(
              'p-2.5 rounded-xl',
              variant === 'positive'
                ? 'bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400'
                : variant === 'negative'
                  ? 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400'
                  : 'bg-secondary text-muted'
            )}
          >
            {icon}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function UpgradePrompt() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div>
        <h1 className="text-2xl font-semibold text-main">Budget vs Actual</h1>
        <p className="text-[13px] text-muted mt-1">Job-level budgeting and variance reporting</p>
      </div>
      <Card>
        <CardContent className="text-center py-12">
          <DollarSign size={40} className="mx-auto mb-3 text-muted opacity-40" />
          <h3 className="text-lg font-semibold text-main">Enterprise Feature</h3>
          <p className="text-sm text-muted mt-2 max-w-md mx-auto">
            Budget vs Actual reporting with job-level budgeting, variance tracking, and overrun alerts
            is available on the Enterprise plan.
          </p>
          <Button variant="secondary" className="mt-6">
            Upgrade Plan
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
