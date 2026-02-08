'use client';

import {
  Video,
  Calendar,
  CheckCircle2,
  Clock,
  BarChart3,
  Inbox,
  RefreshCw,
  Building2,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useMeetingAnalytics } from '@/lib/hooks/use-meeting-analytics';
import { formatNumber } from '@/lib/utils';

const statusVariantMap: Record<string, 'success' | 'warning' | 'danger' | 'info' | 'default'> = {
  scheduled: 'info',
  in_progress: 'warning',
  completed: 'success',
  cancelled: 'danger',
  no_show: 'danger',
};

const typeLabels: Record<string, string> = {
  site_walk: 'Site Walk',
  virtual_estimate: 'Virtual Estimate',
  document_review: 'Document Review',
  team_huddle: 'Team Huddle',
  insurance_conference: 'Insurance Conference',
  subcontractor_consult: 'Subcontractor Consult',
  expert_consult: 'Expert Consult',
  async_video: 'Async Video',
};

function formatStatusLabel(status: string): string {
  return status
    .split('_')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

export default function MeetingAnalyticsPage() {
  const { data, loading, error, refetch } = useMeetingAnalytics();

  const metrics = [
    {
      label: 'Total Meetings',
      value: formatNumber(data.totalMeetings),
      icon: <Calendar className="h-5 w-5" />,
      subtext: 'All companies',
    },
    {
      label: 'Active Now',
      value: formatNumber(data.activeMeetings),
      icon: <Video className="h-5 w-5" />,
      subtext: 'In progress',
    },
    {
      label: 'Completed',
      value: formatNumber(data.completedMeetings),
      icon: <CheckCircle2 className="h-5 w-5" />,
      subtext: 'Finished meetings',
    },
    {
      label: 'Avg Duration',
      value: data.avgDuration > 0 ? `${data.avgDuration}m` : '--',
      icon: <Clock className="h-5 w-5" />,
      subtext: 'Minutes per meeting',
    },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Meeting Analytics
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            Cross-company meeting activity and performance metrics
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

      {/* Status Breakdown + Type Breakdown side by side */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Status Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle>Status Breakdown</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="space-y-3">
                {[1, 2, 3, 4, 5].map((i) => (
                  <div key={i} className="flex items-center justify-between py-2">
                    <div className="h-4 w-24 rounded skeleton-shimmer" />
                    <div className="h-5 w-16 rounded-full skeleton-shimmer" />
                  </div>
                ))}
              </div>
            ) : data.byStatus.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-16 text-[var(--text-secondary)]">
                <BarChart3 className="h-10 w-10 mb-3 opacity-30" />
                <p className="text-sm font-medium">No meeting data available yet</p>
                <p className="text-xs mt-1 opacity-70">
                  Status breakdown will appear when meetings are created
                </p>
              </div>
            ) : (
              <div className="space-y-2">
                {data.byStatus.map((item) => {
                  const total = data.totalMeetings || 1;
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
                        <div className="w-24 bg-[var(--bg-elevated)] rounded-full h-2 overflow-hidden">
                          <div
                            className="h-full bg-[var(--accent)] rounded-full transition-all"
                            style={{ width: `${pct}%` }}
                          />
                        </div>
                        <span className="text-sm font-medium text-[var(--text-primary)] w-10 text-right">
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

        {/* Meeting Type Breakdown */}
        <Card>
          <CardHeader>
            <CardTitle>Meeting Types</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="space-y-3">
                {[1, 2, 3, 4, 5].map((i) => (
                  <div key={i} className="flex items-center justify-between py-2">
                    <div className="h-4 w-32 rounded skeleton-shimmer" />
                    <div className="h-5 w-16 rounded-full skeleton-shimmer" />
                  </div>
                ))}
              </div>
            ) : data.byType.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-16 text-[var(--text-secondary)]">
                <BarChart3 className="h-10 w-10 mb-3 opacity-30" />
                <p className="text-sm font-medium">No meeting type data yet</p>
                <p className="text-xs mt-1 opacity-70">
                  Type distribution will appear when meetings are created
                </p>
              </div>
            ) : (
              <div className="space-y-2">
                {data.byType.map((item) => {
                  const total = data.totalMeetings || 1;
                  const pct = ((item.count / total) * 100).toFixed(1);
                  return (
                    <div
                      key={item.meeting_type}
                      className="flex items-center justify-between py-2 border-b border-[var(--border)] last:border-0"
                    >
                      <span className="text-sm text-[var(--text-primary)]">
                        {typeLabels[item.meeting_type] || formatStatusLabel(item.meeting_type)}
                      </span>
                      <div className="flex items-center gap-4">
                        <div className="w-24 bg-[var(--bg-elevated)] rounded-full h-2 overflow-hidden">
                          <div
                            className="h-full bg-[var(--accent)] rounded-full transition-all"
                            style={{ width: `${pct}%` }}
                          />
                        </div>
                        <span className="text-sm font-medium text-[var(--text-primary)] w-10 text-right">
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
      </div>

      {/* Top Companies by Meetings */}
      <Card>
        <CardHeader>
          <CardTitle>Top Companies by Meeting Volume</CardTitle>
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
          ) : data.topCompanies.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <Inbox className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm font-medium">No company meeting data yet</p>
              <p className="text-xs mt-1 opacity-60">
                Company meeting volumes will appear when meetings are scheduled
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
                      Meetings
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Avg Duration
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {data.topCompanies.map((company) => (
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
                          {formatNumber(company.meeting_count)}
                        </span>
                      </td>
                      <td className="py-3 px-2 text-right">
                        <span className="text-sm text-[var(--text-secondary)]">
                          {company.avg_duration > 0 ? `${company.avg_duration}m` : '--'}
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
