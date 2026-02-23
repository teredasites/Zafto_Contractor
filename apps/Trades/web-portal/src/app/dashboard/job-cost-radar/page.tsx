'use client';

import { useState } from 'react';
import {
  Radar,
  AlertTriangle,
  Users,
  Package,
  Loader2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { useJobCosts } from '@/lib/hooks/use-job-costs';
import type { JobCostData, RiskLevel } from '@/lib/hooks/use-job-costs';
import { useTranslation } from '@/lib/translations';

const riskConfig: Record<RiskLevel, { label: string; color: string; bgColor: string }> = {
  on_track: { label: 'On Track', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  at_risk: { label: 'At Risk', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  over_budget: { label: 'Over Budget', color: 'text-orange-700 dark:text-orange-300', bgColor: 'bg-orange-100 dark:bg-orange-900/30' },
  critical: { label: 'Critical', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
};

export default function JobCostRadarPage() {
  const { t } = useTranslation();
  const { jobs, stats, loading, error } = useJobCosts();
  const [selectedJob, setSelectedJob] = useState<JobCostData | null>(null);
  const [riskFilter, setRiskFilter] = useState<'all' | RiskLevel>('all');

  const filtered = riskFilter === 'all' ? jobs : jobs.filter(j => j.risk === riskFilter);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-muted" />
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col min-h-0">
      <CommandPalette />
      <div className="shrink-0 border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-red-500 to-rose-600 flex items-center justify-center">
              <Radar className="w-4 h-4 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-semibold text-foreground">{t('jobCostRadar.title')}</h1>
              <p className="text-sm text-muted-foreground">Real-time burn rate tracking — catch overruns before they happen</p>
            </div>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {error && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-300">
            {error}
          </div>
        )}

        {/* Portfolio Stats */}
        <div className="grid grid-cols-4 gap-4">
          <Card className={stats.critical > 0 ? 'border-red-200 dark:border-red-800' : ''}>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Portfolio Health</p>
              <div className="flex items-center gap-2 mt-1">
                <p className="text-2xl font-semibold">{stats.critical > 0 ? 'At Risk' : stats.activeJobs > 0 ? 'Healthy' : 'No Active Jobs'}</p>
                {stats.critical > 0 && <AlertTriangle className="w-5 h-5 text-red-500" />}
              </div>
              <p className="text-xs text-muted-foreground mt-1">{stats.critical} critical, {stats.atRisk} at risk</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Total Budget vs Projected</p>
              <p className="text-2xl font-semibold mt-1">{formatCurrency(stats.projectedTotal)}</p>
              {stats.projectedTotal > stats.totalBudget ? (
                <p className="text-xs text-red-500 mt-1">{formatCurrency(stats.projectedTotal - stats.totalBudget)} over budget</p>
              ) : (
                <p className="text-xs text-emerald-500 mt-1">{formatCurrency(stats.totalBudget - stats.projectedTotal)} under budget</p>
              )}
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Avg Projected Margin</p>
              <p className={cn('text-2xl font-semibold mt-1', stats.avgMarginProjected < 10 ? 'text-red-500' : '')}>{stats.avgMarginProjected}%</p>
              <p className="text-xs text-muted-foreground mt-1">Originally {stats.avgMarginOriginal}%</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Active Spend</p>
              <p className="text-2xl font-semibold mt-1">{formatCurrency(stats.totalSpend)}</p>
              <p className="text-xs text-muted-foreground mt-1">of {formatCurrency(stats.totalBudget)} budgeted</p>
            </CardContent>
          </Card>
        </div>

        {/* Filter */}
        <div className="flex items-center gap-2">
          {(['all', 'critical', 'over_budget', 'at_risk', 'on_track'] as const).map(f => (
            <Button key={f} variant={riskFilter === f ? 'default' : 'outline'} size="sm" onClick={() => setRiskFilter(f)}>
              {f === 'all' ? 'All Jobs' : riskConfig[f as RiskLevel].label}
              {f !== 'all' && <Badge variant="secondary" className="ml-1.5 text-xs">{jobs.filter(j => j.risk === f).length}</Badge>}
            </Button>
          ))}
        </div>

        {/* Jobs Grid */}
        {filtered.length > 0 ? (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {filtered.map(job => {
              const risk = riskConfig[job.risk];
              const budgetOverrun = job.projectedTotal - job.bidAmount;
              return (
                <Card key={job.id} className={cn('cursor-pointer transition-all hover:shadow-md', selectedJob?.id === job.id && 'ring-2 ring-primary', job.risk === 'critical' && 'border-red-200 dark:border-red-800')} onClick={() => setSelectedJob(job)}>
                  <CardContent className="p-4 space-y-3">
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="text-sm font-medium">{job.name}</p>
                        <p className="text-xs text-muted-foreground">{job.customer} &middot; {job.trade}</p>
                      </div>
                      <Badge className={cn('text-xs', risk.bgColor, risk.color)}>{risk.label}</Badge>
                    </div>

                    {/* Budget bar */}
                    <div>
                      <div className="flex items-center justify-between text-xs mb-1">
                        <span className="text-muted-foreground">{job.percentComplete}% complete</span>
                        <span className="text-muted-foreground">{job.percentBudgetUsed}% budget used</span>
                      </div>
                      <div className="relative h-2 rounded-full bg-muted overflow-hidden">
                        <div className="absolute inset-y-0 left-0 rounded-full bg-muted-foreground/20" style={{ width: `${job.percentComplete}%` }} />
                        <div className={cn('absolute inset-y-0 left-0 rounded-full', job.percentBudgetUsed > job.percentComplete + 10 ? 'bg-red-500' : job.percentBudgetUsed > job.percentComplete ? 'bg-amber-500' : 'bg-emerald-500')} style={{ width: `${Math.min(job.percentBudgetUsed, 100)}%` }} />
                      </div>
                    </div>

                    {/* Key metrics */}
                    <div className="grid grid-cols-3 gap-2 text-center">
                      <div className="p-2 rounded-md bg-muted/40">
                        <p className="text-xs text-muted-foreground">Bid</p>
                        <p className="text-sm font-medium">{formatCurrency(job.bidAmount)}</p>
                      </div>
                      <div className="p-2 rounded-md bg-muted/40">
                        <p className="text-xs text-muted-foreground">Projected</p>
                        <p className={cn('text-sm font-medium', budgetOverrun > 0 ? 'text-red-500' : 'text-emerald-500')}>{formatCurrency(job.projectedTotal)}</p>
                      </div>
                      <div className="p-2 rounded-md bg-muted/40">
                        <p className="text-xs text-muted-foreground">{t('common.margin')}</p>
                        <p className={cn('text-sm font-medium', job.projectedMargin < 0 ? 'text-red-500' : job.projectedMargin < 10 ? 'text-amber-500' : 'text-emerald-500')}>{job.projectedMargin}%</p>
                      </div>
                    </div>

                    {/* Alerts */}
                    {job.alerts.length > 0 && (
                      <div className="space-y-1">
                        {job.alerts.slice(0, 2).map((alert, i) => (
                          <div key={i} className="flex items-start gap-1.5 text-xs text-amber-600 dark:text-amber-400">
                            <AlertTriangle className="w-3 h-3 shrink-0 mt-0.5" />
                            <span>{alert}</span>
                          </div>
                        ))}
                        {job.alerts.length > 2 && <p className="text-xs text-muted-foreground">+{job.alerts.length - 2} more alerts</p>}
                      </div>
                    )}
                  </CardContent>
                </Card>
              );
            })}
          </div>
        ) : (
          <Card>
            <CardContent className="p-8 text-center text-muted-foreground">
              {jobs.length === 0 ? 'No active jobs to analyze' : 'No jobs match the selected filter'}
            </CardContent>
          </Card>
        )}

        {/* Detail Panel */}
        {selectedJob && (
          <Card>
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <CardTitle className="text-base">{selectedJob.name} — Cost Breakdown</CardTitle>
                <Badge className={cn('text-xs', riskConfig[selectedJob.risk].bgColor, riskConfig[selectedJob.risk].color)}>{riskConfig[selectedJob.risk].label}</Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                {/* Materials */}
                <div className="p-3 rounded-lg border border-border/60">
                  <div className="flex items-center gap-2 mb-2">
                    <Package className="w-4 h-4 text-muted-foreground" />
                    <span className="text-sm font-medium">Materials</span>
                  </div>
                  <div className="space-y-1">
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">Budgeted</span>
                      <span>{formatCurrency(selectedJob.bidAmount * 0.4)}</span>
                    </div>
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">{t('common.actual')}</span>
                      <span>{formatCurrency(selectedJob.materialsActual)}</span>
                    </div>
                    <div className="h-1.5 rounded-full bg-muted overflow-hidden mt-2">
                      <div className={cn('h-full rounded-full', selectedJob.materialsActual / (selectedJob.bidAmount * 0.4) > 0.8 ? 'bg-red-500' : 'bg-purple-500')} style={{ width: `${Math.min((selectedJob.materialsActual / Math.max(selectedJob.bidAmount * 0.4, 1)) * 100, 100)}%` }} />
                    </div>
                  </div>
                </div>
                {/* Spend */}
                <div className="p-3 rounded-lg border border-border/60">
                  <div className="flex items-center gap-2 mb-2">
                    <Users className="w-4 h-4 text-muted-foreground" />
                    <span className="text-sm font-medium">Total Spend</span>
                  </div>
                  <div className="space-y-1">
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">{t('common.budget')}</span>
                      <span>{formatCurrency(selectedJob.bidAmount)}</span>
                    </div>
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">{t('common.actual')}</span>
                      <span className={selectedJob.actualSpend > selectedJob.bidAmount ? 'text-red-500 font-medium' : ''}>{formatCurrency(selectedJob.actualSpend)}</span>
                    </div>
                    <div className="h-1.5 rounded-full bg-muted overflow-hidden mt-2">
                      <div className={cn('h-full rounded-full', selectedJob.percentBudgetUsed > 80 ? 'bg-red-500' : 'bg-blue-500')} style={{ width: `${Math.min(selectedJob.percentBudgetUsed, 100)}%` }} />
                    </div>
                  </div>
                </div>
              </div>

              {/* Change orders + margin impact */}
              <div className="grid grid-cols-3 gap-3">
                <div className="p-3 rounded-lg bg-muted/40 text-center">
                  <p className="text-xs text-muted-foreground">Change Orders</p>
                  <p className="text-lg font-semibold">{formatCurrency(selectedJob.changeOrdersTotal)}</p>
                </div>
                <div className="p-3 rounded-lg bg-muted/40 text-center">
                  <p className="text-xs text-muted-foreground">Original Margin</p>
                  <p className="text-lg font-semibold">{selectedJob.originalMargin}%</p>
                </div>
                <div className={cn('p-3 rounded-lg text-center', selectedJob.projectedMargin < 0 ? 'bg-red-50 dark:bg-red-950/30' : 'bg-muted/40')}>
                  <p className="text-xs text-muted-foreground">Projected Margin</p>
                  <p className={cn('text-lg font-semibold', selectedJob.projectedMargin < 0 ? 'text-red-500' : '')}>{selectedJob.projectedMargin}%</p>
                </div>
              </div>

              {/* All alerts */}
              {selectedJob.alerts.length > 0 && (
                <div className="space-y-2">
                  <p className="text-sm font-medium">Alerts</p>
                  {selectedJob.alerts.map((alert, i) => (
                    <div key={i} className="flex items-start gap-2 p-2 rounded-md bg-amber-50 dark:bg-amber-950/20 text-sm text-amber-700 dark:text-amber-300">
                      <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                      {alert}
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
