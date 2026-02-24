'use client';

import { useState, useMemo } from 'react';
import {
  Radar,
  AlertTriangle,
  Users,
  Package,
  Loader2,
  TrendingUp,
  TrendingDown,
  BarChart3,
  Clock,
  DollarSign,
  Target,
  ChevronRight,
  ArrowUpRight,
  ArrowDownRight,
  Minus,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { useJobCosts } from '@/lib/hooks/use-job-costs';
import type { JobCostData, RiskLevel } from '@/lib/hooks/use-job-costs';
import { useTranslation } from '@/lib/translations';

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

type ViewTab = 'portfolio' | 'post_mortem' | 'line_items' | 'crew' | 'trends' | 'overhead';

const riskConfig: Record<RiskLevel, { label: string; color: string; bgColor: string }> = {
  on_track: { label: 'On Track', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  at_risk: { label: 'At Risk', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  over_budget: { label: 'Over Budget', color: 'text-orange-700 dark:text-orange-300', bgColor: 'bg-orange-100 dark:bg-orange-900/30' },
  critical: { label: 'Critical', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
};

// ── Demo data for new tabs ──

interface PostMortem {
  id: string;
  jobName: string;
  trade: string;
  completedDate: string;
  estimatedLabor: number;
  actualLabor: number;
  estimatedMaterials: number;
  actualMaterials: number;
  estimatedTotal: number;
  actualTotal: number;
  profitMargin: number;
  estimatedMargin: number;
}

interface LineItemAccuracy {
  category: string;
  estimatedAvg: number;
  actualAvg: number;
  variance: number;
  sampleSize: number;
  trend: 'over' | 'under' | 'on_target';
  suggestion: string;
}

interface CrewMetric {
  crewName: string;
  members: number;
  avgJobDays: number;
  avgDailyOutput: number;
  completionRate: number;
  callbackRate: number;
  specialties: string[];
  costPerHour: number;
}

interface CostTrend {
  month: string;
  avgMargin: number;
  totalRevenue: number;
  totalCost: number;
  jobCount: number;
}

interface OverheadItem {
  category: string;
  monthlyCost: number;
  perJobHour: number;
  percentOfRevenue: number;
}

const demoPostMortems: PostMortem[] = [
  { id: '1', jobName: 'Kitchen Remodel — Wilson', trade: 'General Contractor', completedDate: '2026-02-10', estimatedLabor: 8500, actualLabor: 9200, estimatedMaterials: 12000, actualMaterials: 11800, estimatedTotal: 24000, actualTotal: 24500, profitMargin: 18.2, estimatedMargin: 22.0 },
  { id: '2', jobName: 'Roof Replacement — Garcia', trade: 'Roofing', completedDate: '2026-02-05', estimatedLabor: 4200, actualLabor: 3800, estimatedMaterials: 6500, actualMaterials: 7100, estimatedTotal: 14000, actualTotal: 14200, profitMargin: 24.1, estimatedMargin: 25.0 },
  { id: '3', jobName: 'Panel Upgrade — Chen', trade: 'Electrical', completedDate: '2026-01-28', estimatedLabor: 2800, actualLabor: 3400, estimatedMaterials: 1800, actualMaterials: 1750, estimatedTotal: 6000, actualTotal: 6550, profitMargin: 12.3, estimatedMargin: 18.0 },
  { id: '4', jobName: 'Bathroom Repipe — Thompson', trade: 'Plumbing', completedDate: '2026-01-20', estimatedLabor: 3200, actualLabor: 2900, estimatedMaterials: 2100, actualMaterials: 2300, estimatedTotal: 7500, actualTotal: 7400, profitMargin: 28.5, estimatedMargin: 26.0 },
  { id: '5', jobName: 'HVAC Install — Roberts', trade: 'HVAC', completedDate: '2026-01-15', estimatedLabor: 5000, actualLabor: 5800, estimatedMaterials: 8200, actualMaterials: 8100, estimatedTotal: 16500, actualTotal: 17200, profitMargin: 15.8, estimatedMargin: 20.0 },
];

const demoLineItems: LineItemAccuracy[] = [
  { category: 'Drywall patching', estimatedAvg: 450, actualAvg: 520, variance: 15.6, sampleSize: 34, trend: 'over', suggestion: 'Increase labor hours for drywall patching by 15% in future estimates' },
  { category: 'Electrical rough-in', estimatedAvg: 2800, actualAvg: 3200, variance: 14.3, sampleSize: 18, trend: 'over', suggestion: 'Panel installs consistently run over. Add 1 extra labor hour per panel' },
  { category: 'Framing', estimatedAvg: 3500, actualAvg: 3200, variance: -8.6, sampleSize: 22, trend: 'under', suggestion: 'Framing estimates are conservative. Could reduce labor by 10%' },
  { category: 'Finish painting', estimatedAvg: 1800, actualAvg: 1850, variance: 2.8, sampleSize: 45, trend: 'on_target', suggestion: 'Painting estimates are well-calibrated' },
  { category: 'Plumbing fixtures', estimatedAvg: 1200, actualAvg: 1350, variance: 12.5, sampleSize: 28, trend: 'over', suggestion: 'Fixture install time underestimated. Account for supply line variations' },
  { category: 'Roofing tear-off', estimatedAvg: 2200, actualAvg: 1900, variance: -13.6, sampleSize: 15, trend: 'under', suggestion: 'Tear-off estimates are padded. Tighten by 10% for standard shingle roofs' },
  { category: 'HVAC ductwork', estimatedAvg: 4500, actualAvg: 5100, variance: 13.3, sampleSize: 12, trend: 'over', suggestion: 'Ductwork labor consistently underestimated in older homes with tight spaces' },
  { category: 'Concrete flatwork', estimatedAvg: 3800, actualAvg: 3750, variance: -1.3, sampleSize: 9, trend: 'on_target', suggestion: 'Concrete estimates are accurate' },
];

const demoCrews: CrewMetric[] = [
  { crewName: 'Alpha Team', members: 4, avgJobDays: 3.2, avgDailyOutput: 1850, completionRate: 96, callbackRate: 2.1, specialties: ['Roofing', 'Siding'], costPerHour: 185 },
  { crewName: 'Bravo Team', members: 3, avgJobDays: 2.8, avgDailyOutput: 1600, completionRate: 94, callbackRate: 3.5, specialties: ['Electrical', 'HVAC'], costPerHour: 210 },
  { crewName: 'Charlie Team', members: 5, avgJobDays: 4.5, avgDailyOutput: 2200, completionRate: 98, callbackRate: 1.2, specialties: ['General', 'Remodel'], costPerHour: 165 },
  { crewName: 'Delta Team', members: 2, avgJobDays: 1.5, avgDailyOutput: 1200, completionRate: 92, callbackRate: 4.8, specialties: ['Plumbing'], costPerHour: 195 },
];

const demoCostTrends: CostTrend[] = [
  { month: 'Sep 2025', avgMargin: 22.1, totalRevenue: 145000, totalCost: 112900, jobCount: 12 },
  { month: 'Oct 2025', avgMargin: 20.5, totalRevenue: 168000, totalCost: 133560, jobCount: 14 },
  { month: 'Nov 2025', avgMargin: 18.2, totalRevenue: 132000, totalCost: 107976, jobCount: 10 },
  { month: 'Dec 2025', avgMargin: 16.8, totalRevenue: 98000, totalCost: 81536, jobCount: 7 },
  { month: 'Jan 2026', avgMargin: 19.4, totalRevenue: 156000, totalCost: 125736, jobCount: 11 },
  { month: 'Feb 2026', avgMargin: 21.3, totalRevenue: 142000, totalCost: 111754, jobCount: 9 },
];

const demoOverhead: OverheadItem[] = [
  { category: 'Vehicle / Fuel', monthlyCost: 3200, perJobHour: 4.80, percentOfRevenue: 2.3 },
  { category: 'Insurance (GL + WC)', monthlyCost: 4500, perJobHour: 6.75, percentOfRevenue: 3.2 },
  { category: 'Tool Depreciation', monthlyCost: 1200, perJobHour: 1.80, percentOfRevenue: 0.9 },
  { category: 'Office / Admin', monthlyCost: 2800, perJobHour: 4.20, percentOfRevenue: 2.0 },
  { category: 'Software / Subscriptions', monthlyCost: 890, perJobHour: 1.34, percentOfRevenue: 0.6 },
  { category: 'Marketing', monthlyCost: 1500, perJobHour: 2.25, percentOfRevenue: 1.1 },
  { category: 'Licenses / Permits (fixed)', monthlyCost: 350, perJobHour: 0.53, percentOfRevenue: 0.3 },
  { category: 'Misc Operating', monthlyCost: 600, perJobHour: 0.90, percentOfRevenue: 0.4 },
];

export default function JobCostRadarPage() {
  const { t } = useTranslation();
  const { jobs, stats, loading, error } = useJobCosts();
  const [selectedJob, setSelectedJob] = useState<JobCostData | null>(null);
  const [riskFilter, setRiskFilter] = useState<'all' | RiskLevel>('all');
  const [activeTab, setActiveTab] = useState<ViewTab>('portfolio');

  const filtered = riskFilter === 'all' ? jobs : jobs.filter(j => j.risk === riskFilter);

  const totalOverhead = demoOverhead.reduce((s, o) => s + o.monthlyCost, 0);
  const avgPostMortemMargin = demoPostMortems.length > 0
    ? demoPostMortems.reduce((s, p) => s + p.profitMargin, 0) / demoPostMortems.length
    : 0;

  const tabs: { key: ViewTab; label: string; icon: LucideIcon }[] = [
    { key: 'portfolio', label: 'Portfolio', icon: Radar },
    { key: 'post_mortem', label: 'Post-Mortem', icon: Target },
    { key: 'line_items', label: 'Line-Item Accuracy', icon: BarChart3 },
    { key: 'crew', label: 'Crew Performance', icon: Users },
    { key: 'trends', label: 'Cost Trends', icon: TrendingUp },
    { key: 'overhead', label: 'Overhead', icon: DollarSign },
  ];

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
        {/* Tabs */}
        <div className="flex items-center gap-1 px-6 pb-2">
          {tabs.map(tab => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={cn(
                  'flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm transition-colors',
                  activeTab === tab.key
                    ? 'bg-primary text-primary-foreground'
                    : 'text-muted-foreground hover:text-foreground hover:bg-muted'
                )}
              >
                <Icon size={14} />
                {tab.label}
              </button>
            );
          })}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {error && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-300">
            {error}
          </div>
        )}

        {/* ── PORTFOLIO TAB ── (original view) */}
        {activeTab === 'portfolio' && (
          <>
            <div className="grid grid-cols-4 gap-4">
              <Card className={stats.critical > 0 ? 'border-red-200 dark:border-red-800' : ''}>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">{t('jobCostRadar.portfolioHealth')}</p>
                  <div className="flex items-center gap-2 mt-1">
                    <p className="text-2xl font-semibold">{stats.critical > 0 ? 'At Risk' : stats.activeJobs > 0 ? 'Healthy' : 'No Active Jobs'}</p>
                    {stats.critical > 0 && <AlertTriangle className="w-5 h-5 text-red-500" />}
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">{stats.critical} critical, {stats.atRisk} at risk</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">{t('jobCostRadar.totalBudgetVsProjected')}</p>
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
                  <p className="text-xs text-muted-foreground">{t('jobCostRadar.avgProjectedMargin')}</p>
                  <p className={cn('text-2xl font-semibold mt-1', stats.avgMarginProjected < 10 ? 'text-red-500' : '')}>{stats.avgMarginProjected}%</p>
                  <p className="text-xs text-muted-foreground mt-1">Originally {stats.avgMarginOriginal}%</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">{t('jobCostRadar.activeSpend')}</p>
                  <p className="text-2xl font-semibold mt-1">{formatCurrency(stats.totalSpend)}</p>
                  <p className="text-xs text-muted-foreground mt-1">of {formatCurrency(stats.totalBudget)} budgeted</p>
                </CardContent>
              </Card>
            </div>

            <div className="flex items-center gap-2">
              {(['all', 'critical', 'over_budget', 'at_risk', 'on_track'] as const).map(f => (
                <Button key={f} variant={riskFilter === f ? 'default' : 'outline'} size="sm" onClick={() => setRiskFilter(f)}>
                  {f === 'all' ? 'All Jobs' : riskConfig[f as RiskLevel].label}
                  {f !== 'all' && <Badge variant="secondary" className="ml-1.5 text-xs">{jobs.filter(j => j.risk === f).length}</Badge>}
                </Button>
              ))}
            </div>

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
                        <div className="grid grid-cols-3 gap-2 text-center">
                          <div className="p-2 rounded-md bg-muted/40">
                            <p className="text-xs text-muted-foreground">{t('common.bid')}</p>
                            <p className="text-sm font-medium">{formatCurrency(job.bidAmount)}</p>
                          </div>
                          <div className="p-2 rounded-md bg-muted/40">
                            <p className="text-xs text-muted-foreground">{t('jobCostRadar.projected')}</p>
                            <p className={cn('text-sm font-medium', budgetOverrun > 0 ? 'text-red-500' : 'text-emerald-500')}>{formatCurrency(job.projectedTotal)}</p>
                          </div>
                          <div className="p-2 rounded-md bg-muted/40">
                            <p className="text-xs text-muted-foreground">{t('common.margin')}</p>
                            <p className={cn('text-sm font-medium', job.projectedMargin < 0 ? 'text-red-500' : job.projectedMargin < 10 ? 'text-amber-500' : 'text-emerald-500')}>{job.projectedMargin}%</p>
                          </div>
                        </div>
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
                    <div className="p-3 rounded-lg border border-border/60">
                      <div className="flex items-center gap-2 mb-2">
                        <Package className="w-4 h-4 text-muted-foreground" />
                        <span className="text-sm font-medium">{t('common.materials')}</span>
                      </div>
                      <div className="space-y-1">
                        <div className="flex justify-between text-xs">
                          <span className="text-muted-foreground">{t('jobCostRadar.budgeted')}</span>
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
                    <div className="p-3 rounded-lg border border-border/60">
                      <div className="flex items-center gap-2 mb-2">
                        <Users className="w-4 h-4 text-muted-foreground" />
                        <span className="text-sm font-medium">{t('jobCostRadar.totalSpend')}</span>
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
                  <div className="grid grid-cols-3 gap-3">
                    <div className="p-3 rounded-lg bg-muted/40 text-center">
                      <p className="text-xs text-muted-foreground">{t('jobs.changeOrders')}</p>
                      <p className="text-lg font-semibold">{formatCurrency(selectedJob.changeOrdersTotal)}</p>
                    </div>
                    <div className="p-3 rounded-lg bg-muted/40 text-center">
                      <p className="text-xs text-muted-foreground">{t('jobCostRadar.originalMargin')}</p>
                      <p className="text-lg font-semibold">{selectedJob.originalMargin}%</p>
                    </div>
                    <div className={cn('p-3 rounded-lg text-center', selectedJob.projectedMargin < 0 ? 'bg-red-50 dark:bg-red-950/30' : 'bg-muted/40')}>
                      <p className="text-xs text-muted-foreground">{t('jobCostRadar.projectedMargin')}</p>
                      <p className={cn('text-lg font-semibold', selectedJob.projectedMargin < 0 ? 'text-red-500' : '')}>{selectedJob.projectedMargin}%</p>
                    </div>
                  </div>
                  {selectedJob.alerts.length > 0 && (
                    <div className="space-y-2">
                      <p className="text-sm font-medium">{t('jobCostRadar.alerts')}</p>
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
          </>
        )}

        {/* ── POST-MORTEM TAB ── */}
        {activeTab === 'post_mortem' && (
          <>
            <div className="grid grid-cols-4 gap-4">
              <Card>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">Completed Jobs</p>
                  <p className="text-2xl font-semibold mt-1">{demoPostMortems.length}</p>
                  <p className="text-xs text-muted-foreground mt-1">Last 90 days</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">Avg Actual Margin</p>
                  <p className={cn('text-2xl font-semibold mt-1', avgPostMortemMargin < 15 ? 'text-amber-500' : 'text-emerald-500')}>{avgPostMortemMargin.toFixed(1)}%</p>
                  <p className="text-xs text-muted-foreground mt-1">Estimated was {(demoPostMortems.reduce((s, p) => s + p.estimatedMargin, 0) / demoPostMortems.length).toFixed(1)}%</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">Labor Accuracy</p>
                  <p className="text-2xl font-semibold mt-1">
                    {(() => {
                      const totalEst = demoPostMortems.reduce((s, p) => s + p.estimatedLabor, 0);
                      const totalAct = demoPostMortems.reduce((s, p) => s + p.actualLabor, 0);
                      const diff = ((totalAct - totalEst) / totalEst * 100);
                      return diff > 0 ? `+${diff.toFixed(1)}%` : `${diff.toFixed(1)}%`;
                    })()}
                  </p>
                  <p className="text-xs text-muted-foreground mt-1">vs estimated labor costs</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">Material Accuracy</p>
                  <p className="text-2xl font-semibold mt-1">
                    {(() => {
                      const totalEst = demoPostMortems.reduce((s, p) => s + p.estimatedMaterials, 0);
                      const totalAct = demoPostMortems.reduce((s, p) => s + p.actualMaterials, 0);
                      const diff = ((totalAct - totalEst) / totalEst * 100);
                      return diff > 0 ? `+${diff.toFixed(1)}%` : `${diff.toFixed(1)}%`;
                    })()}
                  </p>
                  <p className="text-xs text-muted-foreground mt-1">vs estimated material costs</p>
                </CardContent>
              </Card>
            </div>

            <div className="space-y-3">
              {demoPostMortems.map(pm => {
                const laborVariance = ((pm.actualLabor - pm.estimatedLabor) / pm.estimatedLabor * 100);
                const materialVariance = ((pm.actualMaterials - pm.estimatedMaterials) / pm.estimatedMaterials * 100);
                const totalVariance = ((pm.actualTotal - pm.estimatedTotal) / pm.estimatedTotal * 100);
                return (
                  <Card key={pm.id}>
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between mb-3">
                        <div>
                          <p className="text-sm font-medium">{pm.jobName}</p>
                          <p className="text-xs text-muted-foreground">{pm.trade} &middot; Completed {pm.completedDate}</p>
                        </div>
                        <Badge variant={pm.profitMargin >= pm.estimatedMargin ? 'default' : 'secondary'} className={cn('text-xs', pm.profitMargin >= pm.estimatedMargin ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300' : 'text-red-600')}>
                          {pm.profitMargin.toFixed(1)}% margin
                        </Badge>
                      </div>
                      <div className="grid grid-cols-4 gap-3">
                        <div className="p-2 rounded-md bg-muted/40">
                          <p className="text-xs text-muted-foreground">Labor</p>
                          <p className="text-sm font-medium">{formatCurrency(pm.actualLabor)}</p>
                          <p className={cn('text-xs', laborVariance > 5 ? 'text-red-500' : laborVariance < -5 ? 'text-emerald-500' : 'text-muted-foreground')}>
                            {laborVariance > 0 ? '+' : ''}{laborVariance.toFixed(1)}% vs est
                          </p>
                        </div>
                        <div className="p-2 rounded-md bg-muted/40">
                          <p className="text-xs text-muted-foreground">Materials</p>
                          <p className="text-sm font-medium">{formatCurrency(pm.actualMaterials)}</p>
                          <p className={cn('text-xs', materialVariance > 5 ? 'text-red-500' : materialVariance < -5 ? 'text-emerald-500' : 'text-muted-foreground')}>
                            {materialVariance > 0 ? '+' : ''}{materialVariance.toFixed(1)}% vs est
                          </p>
                        </div>
                        <div className="p-2 rounded-md bg-muted/40">
                          <p className="text-xs text-muted-foreground">Total</p>
                          <p className="text-sm font-medium">{formatCurrency(pm.actualTotal)}</p>
                          <p className={cn('text-xs', totalVariance > 5 ? 'text-red-500' : totalVariance < -5 ? 'text-emerald-500' : 'text-muted-foreground')}>
                            {totalVariance > 0 ? '+' : ''}{totalVariance.toFixed(1)}% vs est
                          </p>
                        </div>
                        <div className={cn('p-2 rounded-md', pm.profitMargin >= pm.estimatedMargin ? 'bg-emerald-50 dark:bg-emerald-950/20' : 'bg-red-50 dark:bg-red-950/20')}>
                          <p className="text-xs text-muted-foreground">Margin</p>
                          <p className={cn('text-sm font-medium', pm.profitMargin >= pm.estimatedMargin ? 'text-emerald-600' : 'text-red-600')}>{pm.profitMargin.toFixed(1)}%</p>
                          <p className="text-xs text-muted-foreground">Est: {pm.estimatedMargin}%</p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          </>
        )}

        {/* ── LINE-ITEM ACCURACY TAB ── */}
        {activeTab === 'line_items' && (
          <>
            <p className="text-sm text-muted-foreground">
              Analysis of estimate accuracy by line item category across all completed jobs. Shows which items consistently run over or under budget.
            </p>
            <div className="space-y-3">
              {demoLineItems.map((item, i) => (
                <Card key={i}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between mb-2">
                      <div className="flex items-center gap-2">
                        {item.trend === 'over' ? <ArrowUpRight className="w-4 h-4 text-red-500" /> :
                         item.trend === 'under' ? <ArrowDownRight className="w-4 h-4 text-emerald-500" /> :
                         <Minus className="w-4 h-4 text-zinc-400" />}
                        <div>
                          <p className="text-sm font-medium">{item.category}</p>
                          <p className="text-xs text-muted-foreground">{item.sampleSize} jobs sampled</p>
                        </div>
                      </div>
                      <Badge variant={item.trend === 'on_target' ? 'default' : 'secondary'} className={cn('text-xs',
                        item.trend === 'over' ? 'text-red-600 border-red-300' :
                        item.trend === 'under' ? 'text-emerald-600 border-emerald-300' :
                        'bg-emerald-100 text-emerald-700'
                      )}>
                        {item.variance > 0 ? '+' : ''}{item.variance.toFixed(1)}%
                      </Badge>
                    </div>
                    <div className="grid grid-cols-2 gap-4 mb-2">
                      <div className="text-xs">
                        <span className="text-muted-foreground">Avg Estimated:</span> <span className="font-medium">{formatCurrency(item.estimatedAvg)}</span>
                      </div>
                      <div className="text-xs">
                        <span className="text-muted-foreground">Avg Actual:</span> <span className="font-medium">{formatCurrency(item.actualAvg)}</span>
                      </div>
                    </div>
                    {/* Variance bar */}
                    <div className="h-2 rounded-full bg-muted overflow-hidden mb-2">
                      <div className={cn('h-full rounded-full transition-all',
                        item.trend === 'over' ? 'bg-red-500' : item.trend === 'under' ? 'bg-emerald-500' : 'bg-blue-500'
                      )} style={{ width: `${Math.min(Math.abs(item.variance) * 3, 100)}%` }} />
                    </div>
                    <div className="flex items-start gap-2 p-2 rounded-md bg-blue-50 dark:bg-blue-950/20">
                      <Target className="w-3.5 h-3.5 text-blue-500 shrink-0 mt-0.5" />
                      <p className="text-xs text-blue-700 dark:text-blue-300">{item.suggestion}</p>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </>
        )}

        {/* ── CREW PERFORMANCE TAB ── */}
        {activeTab === 'crew' && (
          <>
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              {demoCrews.map(crew => (
                <Card key={crew.crewName}>
                  <CardContent className="p-4 space-y-3">
                    <div>
                      <p className="text-sm font-medium">{crew.crewName}</p>
                      <p className="text-xs text-muted-foreground">{crew.members} members &middot; {crew.specialties.join(', ')}</p>
                    </div>
                    <div className="space-y-2">
                      <div className="flex justify-between text-xs">
                        <span className="text-muted-foreground">Avg Job Duration</span>
                        <span className="font-medium">{crew.avgJobDays} days</span>
                      </div>
                      <div className="flex justify-between text-xs">
                        <span className="text-muted-foreground">Daily Output</span>
                        <span className="font-medium">{formatCurrency(crew.avgDailyOutput)}</span>
                      </div>
                      <div className="flex justify-between text-xs">
                        <span className="text-muted-foreground">Completion Rate</span>
                        <span className={cn('font-medium', crew.completionRate >= 95 ? 'text-emerald-500' : 'text-amber-500')}>{crew.completionRate}%</span>
                      </div>
                      <div className="flex justify-between text-xs">
                        <span className="text-muted-foreground">Callback Rate</span>
                        <span className={cn('font-medium', crew.callbackRate <= 2 ? 'text-emerald-500' : crew.callbackRate <= 4 ? 'text-amber-500' : 'text-red-500')}>{crew.callbackRate}%</span>
                      </div>
                      <div className="flex justify-between text-xs">
                        <span className="text-muted-foreground">Cost / Hour</span>
                        <span className="font-medium">{formatCurrency(crew.costPerHour)}</span>
                      </div>
                    </div>
                    {/* Quality score bar */}
                    <div>
                      <div className="flex justify-between text-xs mb-1">
                        <span className="text-muted-foreground">Quality Score</span>
                        <span className="font-medium">{(100 - crew.callbackRate * 10).toFixed(0)}%</span>
                      </div>
                      <div className="h-1.5 rounded-full bg-muted overflow-hidden">
                        <div className={cn('h-full rounded-full', crew.callbackRate <= 2 ? 'bg-emerald-500' : crew.callbackRate <= 4 ? 'bg-amber-500' : 'bg-red-500')} style={{ width: `${100 - crew.callbackRate * 10}%` }} />
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>

            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Crew Comparison</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-border/60">
                        <th className="text-left py-2 px-3 text-xs text-muted-foreground font-medium">Crew</th>
                        <th className="text-right py-2 px-3 text-xs text-muted-foreground font-medium">Members</th>
                        <th className="text-right py-2 px-3 text-xs text-muted-foreground font-medium">Avg Days</th>
                        <th className="text-right py-2 px-3 text-xs text-muted-foreground font-medium">Output/Day</th>
                        <th className="text-right py-2 px-3 text-xs text-muted-foreground font-medium">Completion</th>
                        <th className="text-right py-2 px-3 text-xs text-muted-foreground font-medium">Callbacks</th>
                        <th className="text-right py-2 px-3 text-xs text-muted-foreground font-medium">Cost/Hr</th>
                        <th className="text-right py-2 px-3 text-xs text-muted-foreground font-medium">Efficiency</th>
                      </tr>
                    </thead>
                    <tbody>
                      {demoCrews.map(crew => {
                        const efficiency = crew.avgDailyOutput / crew.costPerHour / 8;
                        return (
                          <tr key={crew.crewName} className="border-b border-border/30">
                            <td className="py-2 px-3 font-medium">{crew.crewName}</td>
                            <td className="py-2 px-3 text-right">{crew.members}</td>
                            <td className="py-2 px-3 text-right">{crew.avgJobDays}</td>
                            <td className="py-2 px-3 text-right">{formatCurrency(crew.avgDailyOutput)}</td>
                            <td className="py-2 px-3 text-right">{crew.completionRate}%</td>
                            <td className={cn('py-2 px-3 text-right', crew.callbackRate > 3 ? 'text-red-500' : '')}>{crew.callbackRate}%</td>
                            <td className="py-2 px-3 text-right">{formatCurrency(crew.costPerHour)}</td>
                            <td className="py-2 px-3 text-right font-medium">{efficiency.toFixed(2)}x</td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>
          </>
        )}

        {/* ── COST TRENDS TAB ── */}
        {activeTab === 'trends' && (
          <>
            <div className="grid grid-cols-3 gap-4">
              <Card>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">6-Month Avg Margin</p>
                  <p className="text-2xl font-semibold mt-1">{(demoCostTrends.reduce((s, t) => s + t.avgMargin, 0) / demoCostTrends.length).toFixed(1)}%</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">Margin Trend</p>
                  {(() => {
                    const first3 = demoCostTrends.slice(0, 3).reduce((s, t) => s + t.avgMargin, 0) / 3;
                    const last3 = demoCostTrends.slice(-3).reduce((s, t) => s + t.avgMargin, 0) / 3;
                    const improving = last3 > first3;
                    return (
                      <div className="flex items-center gap-1 mt-1">
                        {improving ? <TrendingUp className="w-5 h-5 text-emerald-500" /> : <TrendingDown className="w-5 h-5 text-red-500" />}
                        <p className={cn('text-2xl font-semibold', improving ? 'text-emerald-500' : 'text-red-500')}>
                          {improving ? 'Improving' : 'Declining'}
                        </p>
                      </div>
                    );
                  })()}
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">Total Revenue (6 mo)</p>
                  <p className="text-2xl font-semibold mt-1">{formatCurrency(demoCostTrends.reduce((s, t) => s + t.totalRevenue, 0))}</p>
                </CardContent>
              </Card>
            </div>

            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Monthly Profitability</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {demoCostTrends.map((month, i) => {
                    const profit = month.totalRevenue - month.totalCost;
                    const prevMargin = i > 0 ? demoCostTrends[i - 1].avgMargin : month.avgMargin;
                    const marginDelta = month.avgMargin - prevMargin;
                    return (
                      <div key={month.month} className="flex items-center gap-4 p-3 rounded-lg bg-muted/40">
                        <div className="w-24 text-sm font-medium">{month.month}</div>
                        <div className="flex-1">
                          <div className="flex items-center justify-between text-xs mb-1">
                            <span className="text-muted-foreground">Revenue: {formatCurrency(month.totalRevenue)}</span>
                            <span className="text-muted-foreground">Cost: {formatCurrency(month.totalCost)}</span>
                          </div>
                          <div className="h-2 rounded-full bg-muted overflow-hidden">
                            <div className="h-full rounded-full bg-emerald-500" style={{ width: `${month.avgMargin * 4}%` }} />
                          </div>
                        </div>
                        <div className="text-right w-28">
                          <p className={cn('text-sm font-medium', month.avgMargin < 15 ? 'text-amber-500' : 'text-emerald-500')}>{month.avgMargin}% margin</p>
                          <p className={cn('text-xs', marginDelta > 0 ? 'text-emerald-500' : marginDelta < 0 ? 'text-red-500' : 'text-muted-foreground')}>
                            {marginDelta > 0 ? '+' : ''}{marginDelta.toFixed(1)}pp
                          </p>
                        </div>
                        <div className="text-right w-20">
                          <p className="text-sm font-medium">{formatCurrency(profit)}</p>
                          <p className="text-xs text-muted-foreground">{month.jobCount} jobs</p>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </CardContent>
            </Card>

            {/* Estimate feedback */}
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Estimate Feedback Loop</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <p className="text-xs text-muted-foreground mb-3">Based on your last 90 days of completed jobs, here are recommended estimate adjustments:</p>
                {[
                  { category: 'Roofing — Valley Flashing', adjustment: '+15%', reason: 'Labor hours consistently underestimated on complex valley intersections', direction: 'up' as const },
                  { category: 'Electrical — Panel Install', adjustment: '+12%', reason: 'Older homes with outdated wiring require more prep time', direction: 'up' as const },
                  { category: 'Plumbing — Fixture Rough-in', adjustment: '+8%', reason: 'Supply line variations add unexpected time', direction: 'up' as const },
                  { category: 'Framing — Standard Walls', adjustment: '-10%', reason: 'Crew efficiency has improved. Estimates are consistently padded', direction: 'down' as const },
                  { category: 'Painting — Interior', adjustment: 'No change', reason: 'Estimates are well-calibrated within 3% of actuals', direction: 'neutral' as const },
                ].map((fb, i) => (
                  <div key={i} className="flex items-center justify-between p-3 rounded-lg border border-border/60">
                    <div className="flex items-center gap-3">
                      {fb.direction === 'up' ? <ArrowUpRight className="w-4 h-4 text-red-500" /> :
                       fb.direction === 'down' ? <ArrowDownRight className="w-4 h-4 text-emerald-500" /> :
                       <Minus className="w-4 h-4 text-zinc-400" />}
                      <div>
                        <p className="text-sm font-medium">{fb.category}</p>
                        <p className="text-xs text-muted-foreground">{fb.reason}</p>
                      </div>
                    </div>
                    <Badge variant={fb.direction === 'neutral' ? 'default' : 'secondary'} className={cn('text-xs',
                      fb.direction === 'up' ? 'text-red-600 border-red-300' :
                      fb.direction === 'down' ? 'text-emerald-600 border-emerald-300' : ''
                    )}>
                      {fb.adjustment}
                    </Badge>
                  </div>
                ))}
              </CardContent>
            </Card>
          </>
        )}

        {/* ── OVERHEAD TAB ── */}
        {activeTab === 'overhead' && (
          <>
            <div className="grid grid-cols-3 gap-4">
              <Card>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">Total Monthly Overhead</p>
                  <p className="text-2xl font-semibold mt-1">{formatCurrency(totalOverhead)}</p>
                  <p className="text-xs text-muted-foreground mt-1">{formatCurrency(totalOverhead * 12)}/year</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">Overhead per Job Hour</p>
                  <p className="text-2xl font-semibold mt-1">{formatCurrency(demoOverhead.reduce((s, o) => s + o.perJobHour, 0))}</p>
                  <p className="text-xs text-muted-foreground mt-1">~667 billable hours/month</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4">
                  <p className="text-xs text-muted-foreground">Overhead % of Revenue</p>
                  <p className="text-2xl font-semibold mt-1">{demoOverhead.reduce((s, o) => s + o.percentOfRevenue, 0).toFixed(1)}%</p>
                  <p className="text-xs text-muted-foreground mt-1">Industry avg: 10-15%</p>
                </CardContent>
              </Card>
            </div>

            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Overhead Breakdown</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {demoOverhead.sort((a, b) => b.monthlyCost - a.monthlyCost).map((item, i) => (
                    <div key={i} className="flex items-center gap-4 p-3 rounded-lg bg-muted/40">
                      <div className="flex-1">
                        <div className="flex items-center justify-between mb-1">
                          <p className="text-sm font-medium">{item.category}</p>
                          <p className="text-sm font-semibold">{formatCurrency(item.monthlyCost)}/mo</p>
                        </div>
                        <div className="h-1.5 rounded-full bg-muted overflow-hidden">
                          <div className="h-full rounded-full bg-blue-500" style={{ width: `${(item.monthlyCost / totalOverhead) * 100}%` }} />
                        </div>
                      </div>
                      <div className="text-right w-24">
                        <p className="text-xs text-muted-foreground">{formatCurrency(item.perJobHour)}/hr</p>
                        <p className="text-xs text-muted-foreground">{item.percentOfRevenue}% rev</p>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-sm">True Profitability (with Overhead)</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-xs text-muted-foreground mb-3">
                  When overhead is allocated to each job based on labor hours, here is the true profitability picture:
                </p>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-border/60">
                        <th className="text-left py-2 px-3 text-xs text-muted-foreground font-medium">Job</th>
                        <th className="text-right py-2 px-3 text-xs text-muted-foreground font-medium">Revenue</th>
                        <th className="text-right py-2 px-3 text-xs text-muted-foreground font-medium">Direct Cost</th>
                        <th className="text-right py-2 px-3 text-xs text-muted-foreground font-medium">Overhead Alloc</th>
                        <th className="text-right py-2 px-3 text-xs text-muted-foreground font-medium">Gross Margin</th>
                        <th className="text-right py-2 px-3 text-xs text-muted-foreground font-medium">Net Margin</th>
                      </tr>
                    </thead>
                    <tbody>
                      {demoPostMortems.map(pm => {
                        const overheadAlloc = pm.actualTotal * 0.10;
                        const grossMargin = ((pm.estimatedTotal - pm.actualTotal) / pm.estimatedTotal * 100);
                        const netMargin = ((pm.estimatedTotal - pm.actualTotal - overheadAlloc) / pm.estimatedTotal * 100);
                        return (
                          <tr key={pm.id} className="border-b border-border/30">
                            <td className="py-2 px-3 font-medium">{pm.jobName}</td>
                            <td className="py-2 px-3 text-right">{formatCurrency(pm.estimatedTotal)}</td>
                            <td className="py-2 px-3 text-right">{formatCurrency(pm.actualTotal)}</td>
                            <td className="py-2 px-3 text-right text-muted-foreground">{formatCurrency(overheadAlloc)}</td>
                            <td className={cn('py-2 px-3 text-right', grossMargin < 0 ? 'text-red-500' : '')}>{grossMargin.toFixed(1)}%</td>
                            <td className={cn('py-2 px-3 text-right font-medium', netMargin < 0 ? 'text-red-500' : netMargin < 10 ? 'text-amber-500' : 'text-emerald-500')}>{netMargin.toFixed(1)}%</td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>
          </>
        )}
      </div>
    </div>
  );
}
