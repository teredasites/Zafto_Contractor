'use client';

import { useEffect, useState } from 'react';
import {
  TrendingDown,
  DollarSign,
  AlertTriangle,
  RefreshCw,
  BarChart3,
  Inbox,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';

interface ChurnMetric {
  label: string;
  value: string;
  icon: React.ReactNode;
  loading: boolean;
}

export default function ChurnAnalysisPage() {
  const [metrics, setMetrics] = useState<ChurnMetric[]>([
    {
      label: 'Monthly Churn',
      value: '--',
      icon: <TrendingDown className="h-5 w-5" />,
      loading: true,
    },
    {
      label: 'Revenue Churn',
      value: '--',
      icon: <DollarSign className="h-5 w-5" />,
      loading: true,
    },
    {
      label: 'At-Risk Accounts',
      value: '--',
      icon: <AlertTriangle className="h-5 w-5" />,
      loading: true,
    },
    {
      label: 'Recovered',
      value: '--',
      icon: <RefreshCw className="h-5 w-5" />,
      loading: true,
    },
  ]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // All zeros — no subscription data yet
    const timer = setTimeout(() => {
      setMetrics([
        {
          label: 'Monthly Churn',
          value: '0%',
          icon: <TrendingDown className="h-5 w-5" />,
          loading: false,
        },
        {
          label: 'Revenue Churn',
          value: '0%',
          icon: <DollarSign className="h-5 w-5" />,
          loading: false,
        },
        {
          label: 'At-Risk Accounts',
          value: '0',
          icon: <AlertTriangle className="h-5 w-5" />,
          loading: false,
        },
        {
          label: 'Recovered',
          value: '0',
          icon: <RefreshCw className="h-5 w-5" />,
          loading: false,
        },
      ]);
      setLoading(false);
    }, 400);

    return () => clearTimeout(timer);
  }, []);

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">
          Churn Analysis
        </h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">
          Subscription churn metrics and at-risk account tracking
        </p>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {metrics.map((metric) => (
          <Card key={metric.label}>
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm text-[var(--text-secondary)]">
                  {metric.label}
                </p>
                {metric.loading ? (
                  <div className="h-8 w-16 mt-1 rounded skeleton-shimmer" />
                ) : (
                  <p className="text-2xl font-bold text-[var(--text-primary)] mt-1">
                    {metric.value}
                  </p>
                )}
              </div>
              <div className="p-2 rounded-lg bg-[var(--accent)]/10 text-[var(--accent)]">
                {metric.icon}
              </div>
            </div>
          </Card>
        ))}
      </div>

      {/* Churn Trend Chart Placeholder */}
      <Card>
        <CardHeader>
          <CardTitle>Churn Trend</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="h-64 rounded skeleton-shimmer" />
          ) : (
            <div className="flex flex-col items-center justify-center py-16 text-[var(--text-secondary)] border border-dashed border-[var(--border)] rounded-lg">
              <BarChart3 className="h-10 w-10 mb-3 opacity-30" />
              <p className="text-sm font-medium">
                Churn trend chart will display when subscription data is available
              </p>
              <p className="text-xs mt-1 opacity-60">
                Monthly and revenue churn rates will be plotted over time
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* At-Risk Accounts */}
      <Card>
        <CardHeader>
          <CardTitle>At-Risk Accounts</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-3">
              {[1, 2, 3].map((i) => (
                <div key={i} className="flex items-center gap-3">
                  <div className="h-8 w-8 rounded-full skeleton-shimmer" />
                  <div className="flex-1 space-y-1.5">
                    <div className="h-3 w-3/4 rounded skeleton-shimmer" />
                    <div className="h-2.5 w-1/3 rounded skeleton-shimmer" />
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <Inbox className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm font-medium">No at-risk accounts</p>
              <p className="text-xs mt-1 opacity-60">
                Accounts showing churn signals will appear here
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
