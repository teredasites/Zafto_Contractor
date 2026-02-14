'use client';

import { ArrowLeft, Calendar, AlertTriangle, TrendingUp, Clock, Users, CheckCircle2, BarChart3 } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useOpsSchedulingAnalytics } from '@/lib/hooks/use-ops-scheduling-analytics';

export default function SchedulingAnalyticsPage() {
  const router = useRouter();
  const { analytics, loading, error } = useOpsSchedulingAnalytics();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-2 rounded-full" style={{ borderColor: 'var(--accent)', borderTopColor: 'transparent' }} />
      </div>
    );
  }

  if (error || !analytics) {
    return (
      <div className="text-center py-20">
        <AlertTriangle className="w-10 h-10 mx-auto mb-3" style={{ color: 'var(--text)' }} />
        <p className="text-sm" style={{ color: 'var(--text)' }}>{error || 'Failed to load analytics'}</p>
      </div>
    );
  }

  const { metrics, monthly_health, bottlenecks } = analytics;

  return (
    <div className="space-y-6 p-6 max-w-6xl mx-auto animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button onClick={() => router.back()} className="p-1.5 rounded-md hover:opacity-80">
          <ArrowLeft className="w-4 h-4" style={{ color: 'var(--text)' }} />
        </button>
        <div>
          <h1 className="text-xl font-semibold" style={{ color: 'var(--text)' }}>Scheduling Analytics</h1>
          <p className="text-xs" style={{ color: 'var(--text)', opacity: 0.5 }}>Cross-company scheduling performance</p>
        </div>
      </div>

      {/* Top metrics */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Total Projects', value: metrics.total_projects, icon: Calendar, color: 'var(--accent)' },
          { label: 'On-Time %', value: `${metrics.on_time_pct}%`, icon: CheckCircle2, color: metrics.on_time_pct >= 80 ? '#22c55e' : metrics.on_time_pct >= 60 ? '#f59e0b' : '#ef4444' },
          { label: 'Avg Delay', value: `${metrics.avg_delay_days}d`, icon: Clock, color: metrics.avg_delay_days > 5 ? '#ef4444' : '#22c55e' },
          { label: 'Resource Util', value: `${metrics.avg_resource_utilization}%`, icon: Users, color: 'var(--accent)' },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="rounded-xl p-4" style={{ background: 'var(--bg-card)', border: '1px solid var(--border)' }}>
            <div className="flex items-center justify-between mb-2">
              <Icon className="w-4 h-4" style={{ color }} />
            </div>
            <p className="text-2xl font-bold" style={{ color: 'var(--text)' }}>{value}</p>
            <p className="text-xs mt-1" style={{ color: 'var(--text)', opacity: 0.5 }}>{label}</p>
          </div>
        ))}
      </div>

      {/* Secondary metrics */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Active Projects', value: metrics.active_projects },
          { label: 'Total Tasks', value: metrics.total_tasks.toLocaleString() },
          { label: 'Critical Tasks', value: metrics.critical_tasks },
          { label: 'Overdue Milestones', value: metrics.overdue_milestones },
        ].map(({ label, value }) => (
          <div key={label} className="rounded-xl p-3 text-center" style={{ background: 'var(--bg-card)', border: '1px solid var(--border)' }}>
            <p className="text-lg font-bold" style={{ color: 'var(--text)' }}>{value}</p>
            <p className="text-[10px]" style={{ color: 'var(--text)', opacity: 0.5 }}>{label}</p>
          </div>
        ))}
      </div>

      {/* Monthly health chart (text-based) */}
      <div className="rounded-xl p-5" style={{ background: 'var(--bg-card)', border: '1px solid var(--border)' }}>
        <div className="flex items-center gap-2 mb-4">
          <BarChart3 className="w-4 h-4" style={{ color: 'var(--accent)' }} />
          <h2 className="text-sm font-semibold" style={{ color: 'var(--text)' }}>Schedule Health by Month</h2>
        </div>

        <div className="grid grid-cols-6 gap-2">
          {monthly_health.map(({ month, on_time, delayed, completed }) => {
            const total = on_time + delayed;
            const healthPct = total > 0 ? Math.round((on_time / total) * 100) : 0;

            return (
              <div key={month} className="text-center">
                {/* Bar */}
                <div className="h-24 flex flex-col justify-end items-center gap-1 mb-1">
                  {delayed > 0 && (
                    <div
                      className="w-full rounded-t"
                      style={{ height: `${Math.max(delayed * 8, 4)}px`, background: '#ef4444', maxHeight: '96px' }}
                    />
                  )}
                  {on_time > 0 && (
                    <div
                      className="w-full rounded-t"
                      style={{ height: `${Math.max(on_time * 8, 4)}px`, background: '#22c55e', maxHeight: '96px' }}
                    />
                  )}
                </div>
                <p className="text-[10px] font-medium" style={{ color: 'var(--text)' }}>{month}</p>
                <p className="text-[9px]" style={{ color: 'var(--text)', opacity: 0.5 }}>{healthPct}%</p>
              </div>
            );
          })}
        </div>

        <div className="flex items-center justify-center gap-4 mt-3 text-[10px]" style={{ color: 'var(--text)', opacity: 0.5 }}>
          <span className="flex items-center gap-1">
            <div className="w-2 h-2 rounded" style={{ background: '#22c55e' }} /> On Time
          </span>
          <span className="flex items-center gap-1">
            <div className="w-2 h-2 rounded" style={{ background: '#ef4444' }} /> Delayed
          </span>
        </div>
      </div>

      {/* Trade bottlenecks */}
      <div className="rounded-xl p-5" style={{ background: 'var(--bg-card)', border: '1px solid var(--border)' }}>
        <div className="flex items-center gap-2 mb-4">
          <TrendingUp className="w-4 h-4" style={{ color: 'var(--accent)' }} />
          <h2 className="text-sm font-semibold" style={{ color: 'var(--text)' }}>Bottleneck Trades</h2>
        </div>

        {bottlenecks.length === 0 ? (
          <p className="text-xs text-center py-6" style={{ color: 'var(--text)', opacity: 0.5 }}>
            No trade-specific delays detected
          </p>
        ) : (
          <div className="space-y-2">
            {bottlenecks.map((b) => (
              <div key={b.trade} className="flex items-center gap-3">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <p className="text-xs font-medium truncate" style={{ color: 'var(--text)' }}>{b.trade}</p>
                    <p className="text-xs" style={{ color: '#ef4444' }}>{b.delay_count} delays</p>
                  </div>
                  <div className="flex items-center gap-2 mt-1">
                    <div className="flex-1 h-1.5 rounded-full" style={{ background: 'var(--border)' }}>
                      <div
                        className="h-full rounded-full"
                        style={{
                          width: `${Math.min(b.avg_delay_days * 5, 100)}%`,
                          background: b.avg_delay_days > 10 ? '#ef4444' : b.avg_delay_days > 5 ? '#f59e0b' : '#22c55e',
                        }}
                      />
                    </div>
                    <span className="text-[10px] w-10 text-right" style={{ color: 'var(--text)', opacity: 0.5 }}>
                      ~{b.avg_delay_days}d avg
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
