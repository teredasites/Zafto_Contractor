'use client';

import { useEffect, useState } from 'react';
import {
  Building2,
  Users,
  TicketCheck,
  AlertTriangle,
  DollarSign,
  Cpu,
  Clock,
  Inbox,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { getSupabase } from '@/lib/supabase';
import { formatRelativeTime } from '@/lib/utils';

interface MetricCard {
  label: string;
  value: string;
  icon: React.ReactNode;
  change?: string;
  loading: boolean;
}

interface AuditEntry {
  id: string;
  action: string;
  table_name: string;
  record_id: string;
  user_id: string;
  created_at: string;
  metadata: Record<string, unknown> | null;
}

export default function CommandCenterPage() {
  const [metrics, setMetrics] = useState<MetricCard[]>([
    {
      label: 'Active Companies',
      value: '--',
      icon: <Building2 className="h-5 w-5" />,
      loading: true,
    },
    {
      label: 'Total Users',
      value: '--',
      icon: <Users className="h-5 w-5" />,
      loading: true,
    },
    {
      label: 'Open Tickets',
      value: '--',
      icon: <TicketCheck className="h-5 w-5" />,
      loading: true,
    },
    {
      label: 'Platform Errors',
      value: '--',
      icon: <AlertTriangle className="h-5 w-5" />,
      loading: true,
    },
    {
      label: 'MRR',
      value: '$0',
      icon: <DollarSign className="h-5 w-5" />,
      loading: true,
    },
    {
      label: 'AI Cost MTD',
      value: '$0',
      icon: <Cpu className="h-5 w-5" />,
      loading: true,
    },
  ]);
  const [recentActivity, setRecentActivity] = useState<AuditEntry[]>([]);
  const [activityLoading, setActivityLoading] = useState(true);

  useEffect(() => {
    const fetchMetrics = async () => {
      const supabase = getSupabase();

      // Fetch companies count
      let companiesCount = 0;
      try {
        const res = await supabase
          .from('companies')
          .select('id', { count: 'exact', head: true });
        companiesCount = res.count ?? 0;
      } catch {
        companiesCount = 0;
      }

      // Fetch users count
      let usersCount = 0;
      try {
        const res = await supabase
          .from('users')
          .select('id', { count: 'exact', head: true });
        usersCount = res.count ?? 0;
      } catch {
        usersCount = 0;
      }

      // Fetch support tickets count (may not exist yet)
      let ticketsCount = 0;
      try {
        const res = await supabase
          .from('support_tickets')
          .select('id', { count: 'exact', head: true })
          .eq('status', 'new');
        ticketsCount = res.count ?? 0;
      } catch {
        ticketsCount = 0;
      }

      setMetrics([
        {
          label: 'Active Companies',
          value: String(companiesCount),
          icon: <Building2 className="h-5 w-5" />,
          loading: false,
        },
        {
          label: 'Total Users',
          value: String(usersCount),
          icon: <Users className="h-5 w-5" />,
          loading: false,
        },
        {
          label: 'Open Tickets',
          value: String(ticketsCount),
          icon: <TicketCheck className="h-5 w-5" />,
          loading: false,
        },
        {
          label: 'Platform Errors',
          value: '0',
          icon: <AlertTriangle className="h-5 w-5" />,
          loading: false,
        },
        {
          label: 'MRR',
          value: '$0',
          icon: <DollarSign className="h-5 w-5" />,
          loading: false,
        },
        {
          label: 'AI Cost MTD',
          value: '$0',
          icon: <Cpu className="h-5 w-5" />,
          loading: false,
        },
      ]);
    };

    const fetchActivity = async () => {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('audit_log')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(10);

      if (data) {
        setRecentActivity(data as AuditEntry[]);
      }
      setActivityLoading(false);
    };

    fetchMetrics();
    fetchActivity();
  }, []);

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">
          Command Center
        </h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">
          Platform overview and operational metrics
        </p>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
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

      {/* Action Queue */}
      <Card>
        <CardHeader>
          <CardTitle>Action Queue</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-8 text-[var(--text-secondary)]">
            <Inbox className="h-8 w-8 mb-2 opacity-40" />
            <p className="text-sm">No items need attention</p>
          </div>
        </CardContent>
      </Card>

      {/* Recent Activity */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Activity</CardTitle>
        </CardHeader>
        <CardContent>
          {activityLoading ? (
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
          ) : recentActivity.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-8 text-[var(--text-secondary)]">
              <Clock className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm">No recent activity</p>
            </div>
          ) : (
            <div className="space-y-3">
              {recentActivity.map((entry) => (
                <div
                  key={entry.id}
                  className="flex items-center justify-between py-2 border-b border-[var(--border)] last:border-0"
                >
                  <div className="flex items-center gap-3">
                    <div className="h-8 w-8 rounded-full bg-[var(--bg-elevated)] flex items-center justify-center">
                      <span className="text-xs font-medium text-[var(--text-secondary)]">
                        {entry.table_name?.[0]?.toUpperCase() || 'A'}
                      </span>
                    </div>
                    <div>
                      <p className="text-sm text-[var(--text-primary)]">
                        <span className="font-medium">{entry.action}</span>
                        {' '}
                        <Badge variant="default">{entry.table_name}</Badge>
                      </p>
                      <p className="text-xs text-[var(--text-secondary)]">
                        {formatRelativeTime(entry.created_at)}
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
