'use client';

import { useEffect, useState, useCallback } from 'react';
import {
  Mail,
  Send,
  CheckCircle2,
  AlertTriangle,
  BarChart3,
  Inbox,
  RefreshCw,
  Building2,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { getSupabase } from '@/lib/supabase';
import { formatNumber } from '@/lib/utils';

interface CompanyEmail {
  company_id: string;
  company_name: string;
  sends: number;
  campaigns: number;
}

interface StatusBreakdown {
  status: string;
  count: number;
}

interface EmailData {
  totalSentThisMonth: number;
  deliveryRate: number;
  openRate: number;
  bounceRate: number;
  emailByCompany: CompanyEmail[];
  statusDistribution: StatusBreakdown[];
}

const emptyData: EmailData = {
  totalSentThisMonth: 0,
  deliveryRate: 0,
  openRate: 0,
  bounceRate: 0,
  emailByCompany: [],
  statusDistribution: [],
};

function useEmailAnalytics() {
  const [data, setData] = useState<EmailData>(emptyData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();
      const now = new Date();
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

      const [
        sendsMonthRes,
        allSendsRes,
        campaignsByCompanyRes,
      ] = await Promise.all([
        // Total sent this month
        supabase
          .from('email_sends')
          .select('id', { count: 'exact', head: true })
          .gte('created_at', monthStart),
        // All sends with status + company for breakdown
        supabase
          .from('email_sends')
          .select('status, company_id'),
        // Campaigns by company
        supabase
          .from('email_campaigns')
          .select('company_id'),
      ]);

      // Status distribution
      const statusCounts: Record<string, number> = {};
      const companyIds = new Set<string>();
      const sendsByCompany: Record<string, number> = {};

      let totalSends = 0;
      let delivered = 0;
      let opened = 0;
      let bounced = 0;

      if (allSendsRes.data) {
        totalSends = allSendsRes.data.length;
        for (const send of allSendsRes.data) {
          const row = send as { status: string; company_id: string };
          statusCounts[row.status] = (statusCounts[row.status] || 0) + 1;
          companyIds.add(row.company_id);
          sendsByCompany[row.company_id] = (sendsByCompany[row.company_id] || 0) + 1;

          if (row.status === 'delivered' || row.status === 'opened' || row.status === 'clicked') {
            delivered++;
          }
          if (row.status === 'opened' || row.status === 'clicked') {
            opened++;
          }
          if (row.status === 'bounced' || row.status === 'bounce') {
            bounced++;
          }
        }
      }

      const campaignsByCompany: Record<string, number> = {};
      if (campaignsByCompanyRes.data) {
        for (const c of campaignsByCompanyRes.data) {
          const row = c as { company_id: string };
          companyIds.add(row.company_id);
          campaignsByCompany[row.company_id] = (campaignsByCompany[row.company_id] || 0) + 1;
        }
      }

      // Fetch company names
      const companyNames: Record<string, string> = {};
      if (companyIds.size > 0) {
        const { data: companies } = await supabase
          .from('companies')
          .select('id, name')
          .in('id', Array.from(companyIds));
        if (companies) {
          for (const c of companies) {
            const row = c as { id: string; name: string };
            companyNames[row.id] = row.name;
          }
        }
      }

      // Build status distribution
      const statusDistribution: StatusBreakdown[] = Object.entries(statusCounts)
        .map(([status, count]) => ({ status, count }))
        .sort((a, b) => b.count - a.count);

      // Build email by company
      const emailByCompany: CompanyEmail[] = Array.from(companyIds)
        .map((cid) => ({
          company_id: cid,
          company_name: companyNames[cid] || 'Unknown',
          sends: sendsByCompany[cid] || 0,
          campaigns: campaignsByCompany[cid] || 0,
        }))
        .sort((a, b) => b.sends - a.sends)
        .slice(0, 15);

      const safeDenom = totalSends || 1;

      setData({
        totalSentThisMonth: sendsMonthRes.count ?? 0,
        deliveryRate: Math.round((delivered / safeDenom) * 100),
        openRate: Math.round((opened / safeDenom) * 100),
        bounceRate: Math.round((bounced / safeDenom) * 100),
        emailByCompany,
        statusDistribution,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch email analytics');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}

const statusVariantMap: Record<string, 'success' | 'warning' | 'danger' | 'info' | 'default'> = {
  delivered: 'success',
  opened: 'success',
  clicked: 'info',
  sent: 'info',
  queued: 'default',
  pending: 'default',
  bounced: 'danger',
  bounce: 'danger',
  failed: 'danger',
  dropped: 'warning',
  deferred: 'warning',
  spam_report: 'danger',
  unsubscribed: 'warning',
};

function formatStatusLabel(status: string): string {
  return status
    .split('_')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

export default function EmailAnalyticsPage() {
  const { data, loading, error, refetch } = useEmailAnalytics();

  const metrics = [
    {
      label: 'Sent This Month',
      value: formatNumber(data.totalSentThisMonth),
      icon: <Send className="h-5 w-5" />,
      subtext: 'Current month',
    },
    {
      label: 'Delivery Rate',
      value: `${data.deliveryRate}%`,
      icon: <CheckCircle2 className="h-5 w-5" />,
      subtext: 'All-time',
    },
    {
      label: 'Open Rate',
      value: `${data.openRate}%`,
      icon: <Mail className="h-5 w-5" />,
      subtext: 'All-time',
    },
    {
      label: 'Bounce Rate',
      value: `${data.bounceRate}%`,
      icon: <AlertTriangle className="h-5 w-5" />,
      subtext: 'All-time',
    },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Email Analytics
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            Cross-company email sending and campaign metrics
          </p>
        </div>
        <button
          onClick={refetch}
          disabled={loading}
          className="flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium border border-[var(--border)] bg-[var(--bg-card)] text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)] hover:text-[var(--text-primary)] transition-colors disabled:opacity-50"
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="p-4 rounded-lg border border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-950/30">
          <p className="text-sm text-red-700 dark:text-red-400">{error}</p>
        </div>
      )}

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {metrics.map((metric) => (
          <Card key={metric.label}>
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm text-[var(--text-secondary)]">
                  {metric.label}
                </p>
                {loading ? (
                  <div className="h-8 w-16 mt-1 rounded skeleton-shimmer" />
                ) : (
                  <p className="text-2xl font-bold text-[var(--text-primary)] mt-1">
                    {metric.value}
                  </p>
                )}
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

      {/* Status Distribution */}
      <Card>
        <CardHeader>
          <CardTitle>Email Status Distribution</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-3">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex items-center justify-between py-2">
                  <div className="h-4 w-24 rounded skeleton-shimmer" />
                  <div className="h-5 w-16 rounded-full skeleton-shimmer" />
                </div>
              ))}
            </div>
          ) : data.statusDistribution.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-[var(--text-secondary)]">
              <BarChart3 className="h-10 w-10 mb-3 opacity-30" />
              <p className="text-sm font-medium">No email status data yet</p>
              <p className="text-xs mt-1 opacity-70">
                Status distribution will appear when emails are sent
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {data.statusDistribution.map((item) => {
                const total = data.statusDistribution.reduce((sum, s) => sum + s.count, 0) || 1;
                const pct = ((item.count / total) * 100).toFixed(1);
                const variant = statusVariantMap[item.status] || 'default';
                return (
                  <div
                    key={item.status}
                    className="flex items-center justify-between py-2 border-b border-[var(--border)] last:border-0"
                  >
                    <div className="flex items-center gap-3">
                      <Badge variant={variant}>
                        {formatStatusLabel(item.status)}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-4">
                      <div className="w-32 bg-[var(--bg-elevated)] rounded-full h-2 overflow-hidden">
                        <div
                          className="h-full bg-[var(--accent)] rounded-full transition-all"
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                      <span className="text-sm font-medium text-[var(--text-primary)] w-12 text-right">
                        {formatNumber(item.count)}
                      </span>
                      <span className="text-xs text-[var(--text-secondary)] w-12 text-right">
                        {pct}%
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Email Volume by Company */}
      <Card>
        <CardHeader>
          <CardTitle>Email Volume by Company</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3, 4, 5].map((i) => (
                <div key={i} className="flex items-center gap-4 py-3">
                  <div className="h-4 w-40 rounded skeleton-shimmer" />
                  <div className="h-4 w-16 rounded skeleton-shimmer" />
                  <div className="h-4 w-20 rounded skeleton-shimmer ml-auto" />
                </div>
              ))}
            </div>
          ) : data.emailByCompany.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <Inbox className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm font-medium">No company email data yet</p>
              <p className="text-xs mt-1 opacity-60">
                Company email volumes will appear when email sends are recorded
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-[var(--border)]">
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Company
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Emails Sent
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Campaigns
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {data.emailByCompany.map((company) => (
                    <tr
                      key={company.company_id}
                      className="border-b border-[var(--border)] last:border-0 hover:bg-[var(--bg-elevated)] transition-colors"
                    >
                      <td className="py-3 px-2">
                        <div className="flex items-center gap-2">
                          <Building2 className="h-4 w-4 text-[var(--text-secondary)]" />
                          <span className="text-sm font-medium text-[var(--text-primary)]">
                            {company.company_name}
                          </span>
                        </div>
                      </td>
                      <td className="py-3 px-2 text-right">
                        <span className="text-sm font-semibold text-[var(--text-primary)]">
                          {formatNumber(company.sends)}
                        </span>
                      </td>
                      <td className="py-3 px-2 text-right">
                        <span className="text-sm text-[var(--text-secondary)]">
                          {formatNumber(company.campaigns)}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
