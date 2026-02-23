'use client';

import { useState } from 'react';
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  Users,
  Target,
  ArrowUpRight,
  ArrowDownRight,
  RefreshCw,
  Lightbulb,
  AlertTriangle,
  Zap,
  Snowflake,
  BarChart3,
  ChevronDown,
  Loader2,
  Crown,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { ZMark } from '@/components/z-console/z-mark';
import { formatCurrency, cn } from '@/lib/utils';
import { useRevenueInsights } from '@/lib/hooks/use-revenue-insights';
import type {
  Period,
  KPIData,
  ChartDataPoint,
  ServiceRevenue,
  CustomerInsight,
  AIRecommendation,
} from '@/lib/hooks/use-revenue-insights';
import { useTranslation } from '@/lib/translations';

export default function RevenueInsightsPage() {
  const { t } = useTranslation();
  const [period, setPeriod] = useState<Period>('month');
  const { data, loading, error, refresh } = useRevenueInsights(period);

  const periods: { value: Period; label: string }[] = [
    { value: 'month', label: 'This Month' },
    { value: 'quarter', label: 'This Quarter' },
    { value: 'year', label: 'This Year' },
  ];

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div>
          <div className="skeleton h-7 w-44 mb-2" />
          <div className="skeleton h-4 w-64" />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-5">
              <div className="skeleton h-3 w-24 mb-3" />
              <div className="skeleton h-7 w-28" />
            </div>
          ))}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="bg-surface border border-main rounded-xl p-6">
            <div className="skeleton h-4 w-32 mb-4" />
            <div className="skeleton h-48 w-full" />
          </div>
          <div className="bg-surface border border-main rounded-xl p-6">
            <div className="skeleton h-4 w-32 mb-4" />
            <div className="skeleton h-48 w-full" />
          </div>
        </div>
      </div>
    );
  }

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
        <div className="flex items-center gap-3">
          <div>
            <h1 className="text-2xl font-semibold text-main">{t('revenueInsights.title')}</h1>
            <p className="text-muted mt-1">AI-powered revenue analytics and recommendations</p>
          </div>
          <Badge variant="purple" size="md" className="self-start mt-1">
            <ZMark size={12} className="text-purple-700 dark:text-purple-300" />
            Powered by Z
          </Badge>
        </div>
        <div className="flex items-center gap-2">
          <div className="relative">
            <select
              value={period}
              onChange={(e) => setPeriod(e.target.value as Period)}
              className="appearance-none pl-4 pr-10 py-2 bg-secondary border border-main rounded-lg text-main text-sm focus:outline-none focus:ring-2 focus:ring-accent/50"
            >
              {periods.map((p) => (
                <option key={p.value} value={p.value}>
                  {p.label}
                </option>
              ))}
            </select>
            <ChevronDown size={16} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted pointer-events-none" />
          </div>
          <Button variant="secondary" onClick={refresh}>
            <RefreshCw size={16} />
            Refresh
          </Button>
        </div>
      </div>

      {data && (
        <>
          {/* KPI Cards */}
          <KPICards kpis={data.kpis} />

          {/* Revenue Trend + AI Insights */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2">
              <RevenueTrendChart chartData={data.chartData} />
            </div>
            <div>
              <AIInsightsPanel recommendations={data.aiRecommendations} />
            </div>
          </div>

          {/* Top Services + Customer Insights */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <TopServicesCard services={data.services} />
            <CustomerInsightsCard customers={data.topCustomers} />
          </div>
        </>
      )}

      {!data && !loading && !error && (
        <div className="text-center py-16">
          <BarChart3 size={40} className="mx-auto text-muted mb-4" />
          <p className="text-muted">No revenue data available yet. Start creating jobs and invoices to see insights.</p>
        </div>
      )}
    </div>
  );
}

// === KPI Cards ===

function KPICards({ kpis }: { kpis: KPIData }) {
  const cards = [
    {
      label: 'Total Revenue',
      value: formatCurrency(kpis.totalRevenue),
      change: kpis.prevTotalRevenue > 0
        ? ((kpis.totalRevenue - kpis.prevTotalRevenue) / kpis.prevTotalRevenue) * 100
        : null,
      icon: DollarSign,
      iconBg: 'bg-emerald-100 dark:bg-emerald-900/30',
      iconColor: 'text-emerald-600',
    },
    {
      label: 'Avg Job Size',
      value: formatCurrency(kpis.avgJobSize),
      change: kpis.prevAvgJobSize > 0
        ? ((kpis.avgJobSize - kpis.prevAvgJobSize) / kpis.prevAvgJobSize) * 100
        : null,
      icon: Target,
      iconBg: 'bg-blue-100 dark:bg-blue-900/30',
      iconColor: 'text-blue-600',
    },
    {
      label: 'Profit Margin',
      value: `${kpis.profitMargin.toFixed(1)}%`,
      change: kpis.prevProfitMargin > 0
        ? kpis.profitMargin - kpis.prevProfitMargin
        : null,
      icon: TrendingUp,
      iconBg: 'bg-purple-100 dark:bg-purple-900/30',
      iconColor: 'text-purple-600',
    },
    {
      label: 'Active Customers',
      value: String(kpis.activeCustomers),
      change: kpis.prevActiveCustomers > 0
        ? ((kpis.activeCustomers - kpis.prevActiveCustomers) / kpis.prevActiveCustomers) * 100
        : null,
      icon: Users,
      iconBg: 'bg-amber-100 dark:bg-amber-900/30',
      iconColor: 'text-amber-600',
    },
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {cards.map((card) => (
        <Card key={card.label}>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div className="min-w-0 flex-1">
                <p className="text-sm text-muted">{card.label}</p>
                <p className="text-2xl font-semibold text-main mt-0.5">{card.value}</p>
                {card.change !== null && (
                  <div className="flex items-center gap-1 mt-1.5">
                    {card.change >= 0 ? (
                      <ArrowUpRight size={14} className="text-emerald-500" />
                    ) : (
                      <ArrowDownRight size={14} className="text-red-500" />
                    )}
                    <span
                      className={cn(
                        'text-xs font-medium',
                        card.change >= 0 ? 'text-emerald-600' : 'text-red-600'
                      )}
                    >
                      {card.change >= 0 ? '+' : ''}{card.change.toFixed(1)}%
                    </span>
                    <span className="text-xs text-muted">vs prev</span>
                  </div>
                )}
              </div>
              <div className={cn('p-2 rounded-lg flex-shrink-0', card.iconBg)}>
                <card.icon size={20} className={card.iconColor} />
              </div>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}

// === Revenue Trend ===

function RevenueTrendChart({ chartData }: { chartData: ChartDataPoint[] }) {
  const maxRevenue = Math.max(...chartData.map((d) => d.revenue), 1);

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="text-base">Revenue Trend</CardTitle>
          <div className="flex items-center gap-4 text-xs">
            <span className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-sm bg-emerald-500" />
              Revenue
            </span>
            <span className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-sm bg-slate-300 dark:bg-slate-600" />
              Expenses
            </span>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {chartData.length > 0 ? (
          <div className="space-y-3">
            {chartData.map((point) => {
              const revenueWidth = maxRevenue > 0 ? (point.revenue / maxRevenue) * 100 : 0;
              const expenseWidth = maxRevenue > 0 ? (point.expenses / maxRevenue) * 100 : 0;
              return (
                <div key={point.label} className="group">
                  <div className="flex items-center gap-4">
                    <span className="text-xs text-muted w-14 flex-shrink-0">{point.label}</span>
                    <div className="flex-1 space-y-1">
                      <div className="h-5 bg-secondary rounded overflow-hidden">
                        <div
                          className="h-full bg-emerald-500 rounded transition-all duration-500"
                          style={{ width: `${revenueWidth}%` }}
                        />
                      </div>
                      {point.expenses > 0 && (
                        <div className="h-2 bg-secondary rounded overflow-hidden">
                          <div
                            className="h-full bg-slate-300 dark:bg-slate-600 rounded transition-all duration-500"
                            style={{ width: `${expenseWidth}%` }}
                          />
                        </div>
                      )}
                    </div>
                    <div className="text-right flex-shrink-0 w-24">
                      <p className="text-sm font-medium text-main">{formatCurrency(point.revenue)}</p>
                      {point.profit !== point.revenue && (
                        <p className={cn('text-xs', point.profit >= 0 ? 'text-emerald-600' : 'text-red-500')}>
                          {formatCurrency(point.profit)}
                        </p>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <p className="text-center text-muted py-8">No revenue data for this period</p>
        )}
      </CardContent>
    </Card>
  );
}

// === AI Insights ===

function AIInsightsPanel({ recommendations }: { recommendations: AIRecommendation[] }) {
  const typeConfig: Record<string, { icon: typeof Lightbulb; color: string; bg: string }> = {
    pricing: {
      icon: DollarSign,
      color: 'text-blue-600',
      bg: 'bg-blue-50 dark:bg-blue-900/20',
    },
    growth: {
      icon: TrendingUp,
      color: 'text-emerald-600',
      bg: 'bg-emerald-50 dark:bg-emerald-900/20',
    },
    seasonal: {
      icon: Snowflake,
      color: 'text-cyan-600',
      bg: 'bg-cyan-50 dark:bg-cyan-900/20',
    },
    efficiency: {
      icon: Zap,
      color: 'text-amber-600',
      bg: 'bg-amber-50 dark:bg-amber-900/20',
    },
    risk: {
      icon: AlertTriangle,
      color: 'text-red-600',
      bg: 'bg-red-50 dark:bg-red-900/20',
    },
  };

  const impactVariant: Record<string, 'error' | 'warning' | 'default'> = {
    high: 'error',
    medium: 'warning',
    low: 'default',
  };

  return (
    <Card className="h-full">
      <CardHeader>
        <div className="flex items-center gap-2">
          <CardTitle className="text-base">AI Insights</CardTitle>
          <ZMark size={13} className="text-purple-500" />
        </div>
      </CardHeader>
      <CardContent className="p-3">
        {recommendations.length > 0 ? (
          <div className="space-y-3">
            {recommendations.map((rec) => {
              const config = typeConfig[rec.type] || typeConfig.growth;
              const Icon = config.icon;
              return (
                <div
                  key={rec.id}
                  className={cn('p-3 rounded-lg', config.bg)}
                >
                  <div className="flex items-start gap-2.5">
                    <Icon size={16} className={cn('mt-0.5 flex-shrink-0', config.color)} />
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <p className="text-sm font-medium text-main leading-tight">{rec.title}</p>
                        <Badge variant={impactVariant[rec.impact]} size="sm">
                          {rec.impact}
                        </Badge>
                      </div>
                      <p className="text-xs text-muted leading-relaxed">{rec.description}</p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <p className="text-center text-muted py-8 text-sm">
            Add more revenue data for AI-powered insights
          </p>
        )}
      </CardContent>
    </Card>
  );
}

// === Top Services ===

function TopServicesCard({ services }: { services: ServiceRevenue[] }) {
  const maxRevenue = Math.max(...services.map((s) => s.revenue), 1);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Top Services</CardTitle>
      </CardHeader>
      <CardContent>
        {services.length > 0 ? (
          <div className="space-y-4">
            {services.map((service, idx) => {
              const widthPct = maxRevenue > 0 ? (service.revenue / maxRevenue) * 100 : 0;
              return (
                <div key={service.service}>
                  <div className="flex items-center justify-between mb-1.5">
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-muted w-5">{idx + 1}.</span>
                      <span className="text-sm font-medium text-main">{service.service}</span>
                      <span className="text-xs text-muted">{service.jobCount} jobs</span>
                    </div>
                    <div className="flex items-center gap-3">
                      <Badge
                        variant={service.margin >= 40 ? 'success' : service.margin >= 20 ? 'warning' : 'error'}
                        size="sm"
                      >
                        {service.margin.toFixed(0)}% margin
                      </Badge>
                      <span className="text-sm font-medium text-main w-24 text-right">
                        {formatCurrency(service.revenue)}
                      </span>
                    </div>
                  </div>
                  <div className="h-1.5 bg-secondary rounded-full overflow-hidden">
                    <div
                      className={cn(
                        'h-full rounded-full transition-all duration-500',
                        service.margin >= 40
                          ? 'bg-emerald-500'
                          : service.margin >= 20
                          ? 'bg-amber-500'
                          : 'bg-red-500'
                      )}
                      style={{ width: `${widthPct}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <p className="text-center text-muted py-8">No service data yet. Tag your jobs to see service breakdowns.</p>
        )}
      </CardContent>
    </Card>
  );
}

// === Customer Insights ===

function CustomerInsightsCard({ customers }: { customers: CustomerInsight[] }) {
  const clvBadge = (score: number): { variant: 'success' | 'warning' | 'error' | 'info' | 'purple'; label: string } => {
    if (score >= 80) return { variant: 'purple', label: 'Platinum' };
    if (score >= 60) return { variant: 'success', label: 'Gold' };
    if (score >= 40) return { variant: 'info', label: 'Silver' };
    return { variant: 'default' as 'info', label: 'Bronze' };
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="text-base">Customer Insights</CardTitle>
          <span className="text-xs text-muted">by lifetime value</span>
        </div>
      </CardHeader>
      <CardContent className="p-0">
        {customers.length > 0 ? (
          <div className="divide-y divide-main">
            {customers.slice(0, 8).map((customer, idx) => {
              const badge = clvBadge(customer.clvScore);
              return (
                <div key={customer.id} className="flex items-center gap-4 px-6 py-3 hover:bg-surface-hover transition-colors">
                  <span className="text-xs text-muted w-5 flex-shrink-0">{idx + 1}</span>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="text-sm font-medium text-main truncate">{customer.name}</p>
                      <Badge variant={badge.variant} size="sm">
                        {badge.label}
                      </Badge>
                    </div>
                    <p className="text-xs text-muted mt-0.5">
                      {customer.jobCount} job{customer.jobCount !== 1 ? 's' : ''}
                      {customer.lastJobDate && (
                        <span> &middot; Last: {new Date(customer.lastJobDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}</span>
                      )}
                    </p>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <p className="text-sm font-medium text-main">{formatCurrency(customer.totalSpend)}</p>
                    <div className="flex items-center gap-1 justify-end mt-0.5">
                      <div className="w-12 h-1 bg-secondary rounded-full overflow-hidden">
                        <div
                          className="h-full bg-purple-500 rounded-full"
                          style={{ width: `${customer.clvScore}%` }}
                        />
                      </div>
                      <span className="text-[10px] text-muted">{customer.clvScore}</span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <div className="p-8 text-center text-muted">
            No customer data available yet
          </div>
        )}
      </CardContent>
    </Card>
  );
}
