'use client';

import {
  Phone,
  MessageSquare,
  Printer,
  Radio,
  BarChart3,
  Inbox,
  RefreshCw,
  Building2,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { usePhoneAnalytics } from '@/lib/hooks/use-phone-analytics';
import { formatNumber } from '@/lib/utils';

const statusVariantMap: Record<string, 'success' | 'warning' | 'danger' | 'info' | 'default'> = {
  completed: 'success',
  in_progress: 'info',
  ringing: 'info',
  initiated: 'default',
  missed: 'warning',
  voicemail: 'warning',
  no_answer: 'warning',
  busy: 'warning',
  failed: 'danger',
};

function formatStatusLabel(status: string): string {
  return status
    .split('_')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

export default function PhoneAnalyticsPage() {
  const { data, loading, error, refetch } = usePhoneAnalytics();

  const metrics = [
    {
      label: 'Total Calls',
      value: formatNumber(data.totalCalls),
      icon: <Phone className="h-5 w-5" />,
      subtext: 'All companies',
    },
    {
      label: 'Total SMS',
      value: formatNumber(data.totalSMS),
      icon: <MessageSquare className="h-5 w-5" />,
      subtext: 'All companies',
    },
    {
      label: 'Total Faxes',
      value: formatNumber(data.totalFaxes),
      icon: <Printer className="h-5 w-5" />,
      subtext: 'All companies',
    },
    {
      label: 'Active Lines',
      value: formatNumber(data.activeLines),
      icon: <Radio className="h-5 w-5" />,
      subtext: 'Currently active',
    },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Phone Analytics
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            Cross-company phone system usage and metrics
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

      {/* Call Status Breakdown */}
      <Card>
        <CardHeader>
          <CardTitle>Call Status Breakdown</CardTitle>
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
          ) : data.callsByStatus.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-[var(--text-secondary)]">
              <BarChart3 className="h-10 w-10 mb-3 opacity-30" />
              <p className="text-sm font-medium">
                No call data available yet
              </p>
              <p className="text-xs mt-1 opacity-70">
                Call status breakdown will appear when phone system data is recorded
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {data.callsByStatus.map((item) => {
                const total = data.totalCalls || 1;
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

      {/* Top Companies by Usage */}
      <Card>
        <CardHeader>
          <CardTitle>Top Companies by Usage</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3, 4, 5].map((i) => (
                <div key={i} className="flex items-center gap-4 py-3">
                  <div className="h-4 w-40 rounded skeleton-shimmer" />
                  <div className="h-4 w-16 rounded skeleton-shimmer" />
                  <div className="h-4 w-16 rounded skeleton-shimmer" />
                  <div className="h-4 w-16 rounded skeleton-shimmer" />
                  <div className="h-4 w-20 rounded skeleton-shimmer ml-auto" />
                </div>
              ))}
            </div>
          ) : data.topCompanies.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <Inbox className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm font-medium">No company phone data yet</p>
              <p className="text-xs mt-1 opacity-60">
                Company usage will appear when phone system is active
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
                      Calls
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      SMS
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Faxes
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Total
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {data.topCompanies.map((company) => {
                    const total = company.call_count + company.sms_count + company.fax_count;
                    return (
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
                          <span className="text-sm text-[var(--text-secondary)]">
                            {formatNumber(company.call_count)}
                          </span>
                        </td>
                        <td className="py-3 px-2 text-right">
                          <span className="text-sm text-[var(--text-secondary)]">
                            {formatNumber(company.sms_count)}
                          </span>
                        </td>
                        <td className="py-3 px-2 text-right">
                          <span className="text-sm text-[var(--text-secondary)]">
                            {formatNumber(company.fax_count)}
                          </span>
                        </td>
                        <td className="py-3 px-2 text-right">
                          <span className="text-sm font-semibold text-[var(--text-primary)]">
                            {formatNumber(total)}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
