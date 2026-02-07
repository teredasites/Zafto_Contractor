'use client';

import { useEffect, useState } from 'react';
import {
  AlertTriangle,
  Bug,
  Users,
  TrendingUp,
  Inbox,
  Settings,
  ExternalLink,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

interface ErrorMetric {
  label: string;
  value: string;
  icon: React.ReactNode;
  loading: boolean;
}

const SENTRY_ENV_VARS = [
  {
    name: 'SENTRY_DSN_WEB_CRM',
    description: 'Web CRM (zafto.cloud)',
  },
  {
    name: 'SENTRY_DSN_CLIENT_PORTAL',
    description: 'Client Portal (client.zafto.cloud)',
  },
  {
    name: 'SENTRY_DSN_OPS_PORTAL',
    description: 'Ops Portal (ops.zafto.cloud)',
  },
  {
    name: 'SENTRY_DSN_MOBILE',
    description: 'Flutter Mobile App',
  },
];

export default function ErrorDashboardPage() {
  const [metrics, setMetrics] = useState<ErrorMetric[]>([
    {
      label: 'Total Errors',
      value: '--',
      icon: <Bug className="h-5 w-5" />,
      loading: true,
    },
    {
      label: 'Unresolved',
      value: '--',
      icon: <AlertTriangle className="h-5 w-5" />,
      loading: true,
    },
    {
      label: 'Error Rate',
      value: '--',
      icon: <TrendingUp className="h-5 w-5" />,
      loading: true,
    },
    {
      label: 'Affected Users',
      value: '--',
      icon: <Users className="h-5 w-5" />,
      loading: true,
    },
  ]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // All zeros — Sentry not connected yet
    const timer = setTimeout(() => {
      setMetrics([
        {
          label: 'Total Errors',
          value: '0',
          icon: <Bug className="h-5 w-5" />,
          loading: false,
        },
        {
          label: 'Unresolved',
          value: '0',
          icon: <AlertTriangle className="h-5 w-5" />,
          loading: false,
        },
        {
          label: 'Error Rate',
          value: '0%',
          icon: <TrendingUp className="h-5 w-5" />,
          loading: false,
        },
        {
          label: 'Affected Users',
          value: '0',
          icon: <Users className="h-5 w-5" />,
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
          Error Dashboard
        </h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">
          Error feed will populate when Sentry API integration is configured
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

      {/* Error Feed Empty State */}
      <Card>
        <CardHeader>
          <CardTitle>Error Feed</CardTitle>
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
              <p className="text-sm font-medium">Connect Sentry API to view real-time error tracking</p>
              <p className="text-xs mt-1 opacity-60">
                Errors from all ZAFTO applications will appear here
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Configure Sentry */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Settings className="h-4 w-4 text-[var(--text-secondary)]" />
            <CardTitle>Configure Sentry</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-[var(--text-secondary)] mb-4">
            The following DSN environment variables need to be set to enable error tracking:
          </p>
          <div className="space-y-3">
            {SENTRY_ENV_VARS.map((envVar) => (
              <div
                key={envVar.name}
                className="flex items-center justify-between py-2.5 px-3 rounded-lg bg-[var(--bg-elevated)] border border-[var(--border)]"
              >
                <div className="flex items-center gap-3">
                  <code className="text-xs font-mono text-[var(--accent)]">
                    {envVar.name}
                  </code>
                  <span className="text-xs text-[var(--text-secondary)]">
                    {envVar.description}
                  </span>
                </div>
                <Badge variant="default">Not Set</Badge>
              </div>
            ))}
          </div>
          <div className="mt-4 flex items-center gap-2 text-xs text-[var(--text-secondary)]">
            <ExternalLink className="h-3.5 w-3.5" />
            <span>DSN values are available in Sentry project settings</span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
