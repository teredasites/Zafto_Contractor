'use client';

import { useState, useEffect } from 'react';
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
import { getSupabase } from '@/lib/supabase';

interface RevenueMetrics {
  totalCompanies: number;
  activeSubscriptions: number;
  trialCount: number;
  cancelledCount: number;
  tierBreakdown: Record<string, number>;
  recentPayments: Array<{ id: string; amount: number; type: string; createdAt: string }>;
}

// Pricing tiers for MRR estimation (S133 owner directive)
const TIER_PRICING: Record<string, number> = {
  solo: 69.99,
  team: 149.99,
  business: 249.99,
};

export default function RevenueDashboardPage() {
  const [metrics, setMetrics] = useState<RevenueMetrics | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchMetrics() {
      try {
        const supabase = getSupabase();

        // Query real company subscription data
        const { data: companies } = await supabase
          .from('companies')
          .select('subscription_tier, subscription_status')
          .is('deleted_at', null);

        const companyList = companies || [];
        const activeSubscriptions = companyList.filter((c: Record<string, unknown>) => c.subscription_status === 'active');
        const trialCount = companyList.filter((c: Record<string, unknown>) => c.subscription_status === 'trialing').length;
        const cancelledCount = companyList.filter((c: Record<string, unknown>) => c.subscription_status === 'cancelled').length;

        const tierBreakdown: Record<string, number> = {};
        activeSubscriptions.forEach((c: Record<string, unknown>) => {
          const tier = c.subscription_tier as string;
          tierBreakdown[tier] = (tierBreakdown[tier] || 0) + 1;
        });

        // Query recent payments
        const { data: payments } = await supabase
          .from('payments')
          .select('id, amount, payment_type, created_at')
          .eq('status', 'completed')
          .order('created_at', { ascending: false })
          .limit(10);

        setMetrics({
          totalCompanies: companyList.length,
          activeSubscriptions: activeSubscriptions.length,
          trialCount,
          cancelledCount,
          tierBreakdown,
          recentPayments: (payments || []).map((p: Record<string, unknown>) => ({
            id: p.id as string,
            amount: (p.amount as number) / 100, // Stripe stores cents
            type: (p.payment_type as string) || 'payment',
            createdAt: p.created_at as string,
          })),
        });
      } catch {
        // Non-blocking — show honest empty state
      } finally {
        setLoading(false);
      }
    }
    fetchMetrics();
  }, []);

  // Calculate MRR from active subscriptions × tier pricing
  const mrr = metrics
    ? Object.entries(metrics.tierBreakdown).reduce((sum, [tier, count]) => sum + (TIER_PRICING[tier] || 0) * count, 0)
    : 0;
  const arr = mrr * 12;
  const churnRate = metrics && metrics.totalCompanies > 0
    ? ((metrics.cancelledCount / metrics.totalCompanies) * 100).toFixed(1)
    : '0.0';

  const formatCurrency = (n: number) => n >= 1000 ? `$${(n / 1000).toFixed(1)}k` : `$${n}`;

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">
          Revenue Dashboard
        </h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">
          {loading ? 'Loading...' : `${metrics?.totalCompanies || 0} companies on platform`}
        </p>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Monthly Recurring Revenue', value: formatCurrency(mrr), icon: <DollarSign className="h-5 w-5" />, subtext: 'MRR' },
          { label: 'Annual Recurring Revenue', value: formatCurrency(arr), icon: <TrendingUp className="h-5 w-5" />, subtext: 'ARR' },
          { label: 'Active Subscriptions', value: String(metrics?.activeSubscriptions || 0), icon: <Users className="h-5 w-5" />, subtext: `${metrics?.trialCount || 0} trialing` },
          { label: 'Churn Rate', value: `${churnRate}%`, icon: <Percent className="h-5 w-5" />, subtext: 'All time' },
        ].map((metric) => (
          <Card key={metric.label}>
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm text-[var(--text-secondary)]">{metric.label}</p>
                <p className="text-2xl font-bold text-[var(--text-primary)] mt-1">{loading ? '...' : metric.value}</p>
                <p className="text-xs text-[var(--text-secondary)] mt-1">{metric.subtext}</p>
              </div>
              <div className="p-2 rounded-lg bg-[var(--accent)]/10 text-[var(--accent)]">
                {metric.icon}
              </div>
            </div>
          </Card>
        ))}
      </div>

      {/* Tier Breakdown */}
      {metrics && Object.keys(metrics.tierBreakdown).length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Subscription Tiers</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
              {Object.entries(TIER_PRICING).map(([tier, price]) => {
                const count = metrics.tierBreakdown[tier] || 0;
                return (
                  <div key={tier} className="p-4 rounded-lg border border-[var(--border)] bg-[var(--bg-elevated)] text-center">
                    <p className="text-xs text-[var(--text-secondary)] uppercase font-medium">{tier}</p>
                    <p className="text-2xl font-bold text-[var(--text-primary)] mt-1">{count}</p>
                    <p className="text-xs text-[var(--text-secondary)] mt-0.5">${price}/mo each</p>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      )}

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

      {/* Recent Payments */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Payments</CardTitle>
        </CardHeader>
        <CardContent>
          {metrics && metrics.recentPayments.length > 0 ? (
            <div className="space-y-2">
              {metrics.recentPayments.map((p) => (
                <div key={p.id} className="flex items-center justify-between p-3 rounded-lg border border-[var(--border)] bg-[var(--bg-elevated)]">
                  <div>
                    <p className="text-sm font-medium text-[var(--text-primary)] capitalize">
                      {p.type.replace(/_/g, ' ')}
                    </p>
                    <p className="text-xs text-[var(--text-secondary)]">
                      {new Date(p.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                  <p className="text-sm font-bold text-[var(--text-primary)]">${p.amount.toFixed(2)}</p>
                </div>
              ))}
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <CreditCard className="h-8 w-8 mb-3 opacity-30" />
              <p className="text-sm font-medium">No payments recorded yet</p>
              <p className="text-xs mt-1 opacity-70">
                Payments will appear here once customers subscribe
              </p>
            </div>
          )}
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
                Revenue metrics are estimated from subscription tiers. Connect Stripe for real-time payment data.
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
