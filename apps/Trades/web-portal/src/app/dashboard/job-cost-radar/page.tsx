'use client';

import { useState } from 'react';
import {
  Radar,
  AlertTriangle,
  TrendingUp,
  TrendingDown,
  DollarSign,
  Clock,
  Users,
  Package,
  CheckCircle,
  ArrowUpRight,
  ArrowDownRight,
  Eye,
  ChevronRight,
  Briefcase,
  BarChart3,
  Activity,
  Target,
  Zap,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';

type RiskLevel = 'on_track' | 'at_risk' | 'over_budget' | 'critical';

interface ActiveJob {
  id: string;
  name: string;
  customer: string;
  bidAmount: number;
  actualSpend: number;
  projectedTotal: number;
  percentComplete: number;
  percentBudgetUsed: number;
  laborHoursBudgeted: number;
  laborHoursActual: number;
  materialsBudgeted: number;
  materialsActual: number;
  changeOrdersTotal: number;
  daysElapsed: number;
  daysEstimated: number;
  risk: RiskLevel;
  alerts: string[];
  projectedMargin: number;
  originalMargin: number;
  trade: string;
}

const riskConfig: Record<RiskLevel, { label: string; color: string; bgColor: string }> = {
  on_track: { label: 'On Track', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  at_risk: { label: 'At Risk', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  over_budget: { label: 'Over Budget', color: 'text-orange-700 dark:text-orange-300', bgColor: 'bg-orange-100 dark:bg-orange-900/30' },
  critical: { label: 'Critical', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
};

const mockJobs: ActiveJob[] = [
  {
    id: 'jr1', name: 'Johnson Whole-House Rewire', customer: 'Robert Johnson', trade: 'Electrical',
    bidAmount: 18500, actualSpend: 14430, projectedTotal: 20900,
    percentComplete: 60, percentBudgetUsed: 78,
    laborHoursBudgeted: 120, laborHoursActual: 98,
    materialsBudgeted: 6200, materialsActual: 5840,
    changeOrdersTotal: 1200, daysElapsed: 12, daysEstimated: 18,
    risk: 'critical',
    alerts: ['Projected $2,400 overrun', '14 extra labor hours on panel work', 'Change order for sub-panel not in original scope'],
    projectedMargin: -13.0, originalMargin: 28.0,
  },
  {
    id: 'jr2', name: 'Martinez HVAC Replacement', customer: 'Elena Martinez', trade: 'HVAC',
    bidAmount: 12800, actualSpend: 5100, projectedTotal: 11200,
    percentComplete: 45, percentBudgetUsed: 40,
    laborHoursBudgeted: 32, laborHoursActual: 14,
    materialsBudgeted: 7800, materialsActual: 3200,
    changeOrdersTotal: 0, daysElapsed: 3, daysEstimated: 5,
    risk: 'on_track',
    alerts: [],
    projectedMargin: 12.5, originalMargin: 14.0,
  },
  {
    id: 'jr3', name: 'Thompson Bathroom Remodel', customer: 'David Thompson', trade: 'Plumbing',
    bidAmount: 22000, actualSpend: 16800, projectedTotal: 23100,
    percentComplete: 72, percentBudgetUsed: 76,
    laborHoursBudgeted: 80, laborHoursActual: 68,
    materialsBudgeted: 9000, materialsActual: 8200,
    changeOrdersTotal: 3500, daysElapsed: 14, daysEstimated: 20,
    risk: 'at_risk',
    alerts: ['Change orders added $3,500 — only $2,800 approved by customer', 'Tile work taking 30% longer than estimated'],
    projectedMargin: -5.0, originalMargin: 22.0,
  },
  {
    id: 'jr4', name: 'Wilson Roof Replacement', customer: 'Sarah Wilson', trade: 'Roofing',
    bidAmount: 16500, actualSpend: 4200, projectedTotal: 14800,
    percentComplete: 25, percentBudgetUsed: 25,
    laborHoursBudgeted: 48, laborHoursActual: 12,
    materialsBudgeted: 8400, materialsActual: 2100,
    changeOrdersTotal: 0, daysElapsed: 2, daysEstimated: 6,
    risk: 'on_track',
    alerts: [],
    projectedMargin: 10.3, originalMargin: 11.0,
  },
  {
    id: 'jr5', name: 'Garcia Kitchen Remodel', customer: 'Maria Garcia', trade: 'Remodeler',
    bidAmount: 38000, actualSpend: 31200, projectedTotal: 41600,
    percentComplete: 82, percentBudgetUsed: 82,
    laborHoursBudgeted: 160, laborHoursActual: 142,
    materialsBudgeted: 18000, materialsActual: 17400,
    changeOrdersTotal: 4800, daysElapsed: 28, daysEstimated: 35,
    risk: 'over_budget',
    alerts: ['Custom cabinet delay added 5 days', 'Countertop material upgrade increased cost by $2,200', 'Projected $3,600 overrun on labor'],
    projectedMargin: -9.5, originalMargin: 18.0,
  },
];

const portfolioStats = {
  activeJobs: 5,
  totalBudget: 107800,
  totalSpend: 71730,
  projectedTotal: 111600,
  atRisk: 2,
  critical: 1,
  avgMarginProjected: 4.2,
  avgMarginOriginal: 18.6,
};

export default function JobCostRadarPage() {
  const [selectedJob, setSelectedJob] = useState<ActiveJob | null>(null);
  const [riskFilter, setRiskFilter] = useState<'all' | RiskLevel>('all');

  const filtered = riskFilter === 'all' ? mockJobs : mockJobs.filter(j => j.risk === riskFilter);
  const sorted = [...filtered].sort((a, b) => {
    const riskOrder: Record<RiskLevel, number> = { critical: 0, over_budget: 1, at_risk: 2, on_track: 3 };
    return riskOrder[a.risk] - riskOrder[b.risk];
  });

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
              <h1 className="text-lg font-semibold text-foreground">Job Cost Radar</h1>
              <p className="text-sm text-muted-foreground">Real-time burn rate tracking — catch overruns before they happen</p>
            </div>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Portfolio Stats */}
        <div className="grid grid-cols-4 gap-4">
          <Card className={portfolioStats.critical > 0 ? 'border-red-200 dark:border-red-800' : ''}>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Portfolio Health</p>
              <div className="flex items-center gap-2 mt-1">
                <p className="text-2xl font-semibold">{portfolioStats.critical > 0 ? 'At Risk' : 'Healthy'}</p>
                {portfolioStats.critical > 0 && <AlertTriangle className="w-5 h-5 text-red-500" />}
              </div>
              <p className="text-xs text-muted-foreground mt-1">{portfolioStats.critical} critical, {portfolioStats.atRisk} at risk</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Total Budget vs Projected</p>
              <p className="text-2xl font-semibold mt-1">{formatCurrency(portfolioStats.projectedTotal)}</p>
              <p className="text-xs text-red-500 mt-1">{formatCurrency(portfolioStats.projectedTotal - portfolioStats.totalBudget)} over budget</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Avg Projected Margin</p>
              <p className={cn('text-2xl font-semibold mt-1', portfolioStats.avgMarginProjected < 10 ? 'text-red-500' : '')}>{portfolioStats.avgMarginProjected}%</p>
              <p className="text-xs text-muted-foreground mt-1">Originally {portfolioStats.avgMarginOriginal}%</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Active Spend</p>
              <p className="text-2xl font-semibold mt-1">{formatCurrency(portfolioStats.totalSpend)}</p>
              <p className="text-xs text-muted-foreground mt-1">of {formatCurrency(portfolioStats.totalBudget)} budgeted</p>
            </CardContent>
          </Card>
        </div>

        {/* Filter */}
        <div className="flex items-center gap-2">
          {(['all', 'critical', 'over_budget', 'at_risk', 'on_track'] as const).map(f => (
            <Button key={f} variant={riskFilter === f ? 'default' : 'outline'} size="sm" onClick={() => setRiskFilter(f)}>
              {f === 'all' ? 'All Jobs' : riskConfig[f as RiskLevel].label}
              {f !== 'all' && <Badge variant="secondary" className="ml-1.5 text-xs">{mockJobs.filter(j => j.risk === f).length}</Badge>}
            </Button>
          ))}
        </div>

        {/* Jobs Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {sorted.map(job => {
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
                      <div className={cn('absolute inset-y-0 left-0 rounded-full', job.percentBudgetUsed > job.percentComplete + 10 ? 'bg-red-500' : job.percentBudgetUsed > job.percentComplete ? 'bg-amber-500' : 'bg-emerald-500')} style={{ width: `${job.percentBudgetUsed}%` }} />
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
                      <p className="text-xs text-muted-foreground">Margin</p>
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
                {/* Labor */}
                <div className="p-3 rounded-lg border border-border/60">
                  <div className="flex items-center gap-2 mb-2">
                    <Users className="w-4 h-4 text-muted-foreground" />
                    <span className="text-sm font-medium">Labor</span>
                  </div>
                  <div className="space-y-1">
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">Hours budgeted</span>
                      <span>{selectedJob.laborHoursBudgeted}h</span>
                    </div>
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">Hours actual</span>
                      <span className={selectedJob.laborHoursActual > selectedJob.laborHoursBudgeted * (selectedJob.percentComplete / 100) * 1.1 ? 'text-red-500 font-medium' : ''}>{selectedJob.laborHoursActual}h</span>
                    </div>
                    <div className="h-1.5 rounded-full bg-muted overflow-hidden mt-2">
                      <div className={cn('h-full rounded-full', selectedJob.laborHoursActual / selectedJob.laborHoursBudgeted > 0.8 ? 'bg-red-500' : 'bg-blue-500')} style={{ width: `${Math.min((selectedJob.laborHoursActual / selectedJob.laborHoursBudgeted) * 100, 100)}%` }} />
                    </div>
                  </div>
                </div>
                {/* Materials */}
                <div className="p-3 rounded-lg border border-border/60">
                  <div className="flex items-center gap-2 mb-2">
                    <Package className="w-4 h-4 text-muted-foreground" />
                    <span className="text-sm font-medium">Materials</span>
                  </div>
                  <div className="space-y-1">
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">Budgeted</span>
                      <span>{formatCurrency(selectedJob.materialsBudgeted)}</span>
                    </div>
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">Actual</span>
                      <span className={selectedJob.materialsActual > selectedJob.materialsBudgeted * (selectedJob.percentComplete / 100) * 1.1 ? 'text-red-500 font-medium' : ''}>{formatCurrency(selectedJob.materialsActual)}</span>
                    </div>
                    <div className="h-1.5 rounded-full bg-muted overflow-hidden mt-2">
                      <div className={cn('h-full rounded-full', selectedJob.materialsActual / selectedJob.materialsBudgeted > 0.8 ? 'bg-red-500' : 'bg-purple-500')} style={{ width: `${Math.min((selectedJob.materialsActual / selectedJob.materialsBudgeted) * 100, 100)}%` }} />
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

              {/* Timeline */}
              <div className="flex items-center justify-between p-3 rounded-lg border border-border/60">
                <div className="text-sm">
                  <span className="text-muted-foreground">Day </span>
                  <span className="font-medium">{selectedJob.daysElapsed}</span>
                  <span className="text-muted-foreground"> of </span>
                  <span className="font-medium">{selectedJob.daysEstimated}</span>
                </div>
                <div className="w-32 h-1.5 rounded-full bg-muted overflow-hidden">
                  <div className="h-full rounded-full bg-blue-500" style={{ width: `${(selectedJob.daysElapsed / selectedJob.daysEstimated) * 100}%` }} />
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
