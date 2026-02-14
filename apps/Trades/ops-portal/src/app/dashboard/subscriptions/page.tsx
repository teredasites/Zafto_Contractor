'use client';

import { useState } from 'react';
import {
  CreditCard,
  Users,
  UserMinus,
  AlertCircle,
  Inbox,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

interface SubMetric {
  label: string;
  value: string;
  icon: React.ReactNode;
  loading: boolean;
}

export default function SubscriptionsPage() {
  const [metrics] = useState<SubMetric[]>([
    { label: 'Active', value: '0', icon: <Users className="h-5 w-5" />, loading: false },
    { label: 'Trial', value: '0', icon: <CreditCard className="h-5 w-5" />, loading: false },
    { label: 'Cancelled', value: '0', icon: <UserMinus className="h-5 w-5" />, loading: false },
    { label: 'Past Due', value: '0', icon: <AlertCircle className="h-5 w-5" />, loading: false },
  ]);
  const [loading] = useState(false);

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">
          Subscriptions
        </h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">
          Stripe subscription management and billing overview
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

      {/* Subscriptions Table */}
      <Card>
        <CardHeader>
          <CardTitle>All Subscriptions</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="flex items-center gap-4 py-3">
                  <div className="h-4 w-32 rounded skeleton-shimmer" />
                  <div className="h-4 w-20 rounded skeleton-shimmer" />
                  <div className="h-5 w-16 rounded-full skeleton-shimmer" />
                  <div className="h-4 w-16 rounded skeleton-shimmer" />
                  <div className="h-4 w-24 rounded skeleton-shimmer ml-auto" />
                </div>
              ))}
            </div>
          ) : (
            <>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-[var(--border)]">
                      <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                        Company
                      </th>
                      <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                        Plan
                      </th>
                      <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                        Status
                      </th>
                      <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                        MRR
                      </th>
                      <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                        Started
                      </th>
                      <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                        Next Billing
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {/* Empty — no subscriptions yet */}
                  </tbody>
                </table>
              </div>
              <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
                <Inbox className="h-8 w-8 mb-2 opacity-40" />
                <p className="text-sm font-medium">Connect Stripe to manage subscriptions</p>
                <p className="text-xs mt-1 opacity-60">
                  Subscription data will sync from Stripe when configured
                </p>
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
