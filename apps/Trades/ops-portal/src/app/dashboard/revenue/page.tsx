'use client';

import { useState } from 'react';
import {
  DollarSign,
  TrendingUp,
  Users,
  Percent,
  BarChart3,
  CreditCard,
  Link as LinkIcon,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';

interface MetricCard {
  label: string;
  value: string;
  icon: React.ReactNode;
  subtext: string;
}

export default function RevenueDashboardPage() {
  const [metrics] = useState<MetricCard[]>([
    {
      label: 'Monthly Recurring Revenue',
      value: '$0',
      icon: <DollarSign className="h-5 w-5" />,
      subtext: 'MRR',
    },
    {
      label: 'Annual Recurring Revenue',
      value: '$0',
      icon: <TrendingUp className="h-5 w-5" />,
      subtext: 'ARR',
    },
    {
      label: 'Active Subscriptions',
      value: '0',
      icon: <Users className="h-5 w-5" />,
      subtext: 'Subscribers',
    },
    {
      label: 'Churn Rate',
      value: '0%',
      icon: <Percent className="h-5 w-5" />,
      subtext: 'Monthly',
    },
  ]);

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">
          Revenue Dashboard
        </h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">
          Subscription metrics and financial overview
        </p>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {metrics.map((metric) => (
          <Card key={metric.label}>
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm text-[var(--text-secondary)]">
                  {metric.label}
                </p>
                <p className="text-2xl font-bold text-[var(--text-primary)] mt-1">
                  {metric.value}
                </p>
                <p className="text-xs text-[var(--text-secondary)] mt-1">
                  {metric.subtext}
                </p>
              </div>
              <div className="p-2 rounded-lg bg-[var(--accent)]/10 text-[var(--accent)]">
                {metric.icon}
              </div>
            </div>
          </Card>
        ))}
      </div>

      {/* Revenue Chart Placeholder */}
      <Card>
        <CardHeader>
          <CardTitle>Revenue Over Time</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-16 text-[var(--text-secondary)]">
            <BarChart3 className="h-10 w-10 mb-3 opacity-30" />
            <p className="text-sm font-medium">
              Revenue chart will display here when Stripe is connected
            </p>
            <p className="text-xs mt-1 opacity-70">
              MRR, ARR, and growth trends will populate automatically
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Recent Transactions */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Transactions</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
            <CreditCard className="h-8 w-8 mb-3 opacity-30" />
            <p className="text-sm font-medium">
              Connect Stripe to view transactions
            </p>
            <p className="text-xs mt-1 opacity-70">
              Payments, refunds, and subscription changes will appear here
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Integration Status */}
      <Card>
        <CardHeader>
          <CardTitle>Payment Integration</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-4 p-4 rounded-lg border border-[var(--border)] bg-[var(--bg-elevated)]">
            <div className="p-3 rounded-lg bg-[var(--bg-card)]">
              <LinkIcon className="h-5 w-5 text-[var(--text-secondary)]" />
            </div>
            <div className="flex-1">
              <p className="text-sm font-medium text-[var(--text-primary)]">
                Stripe Integration
              </p>
              <p className="text-xs text-[var(--text-secondary)] mt-0.5">
                Not connected. Revenue data will populate once Stripe API keys are configured.
              </p>
            </div>
            <div className="px-3 py-1.5 rounded-full border border-[var(--border)] bg-[var(--bg-card)] text-xs font-medium text-[var(--text-secondary)]">
              Pending Setup
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
