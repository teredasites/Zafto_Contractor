'use client';

import { useEffect, useState, useCallback } from 'react';
import {
  Satellite,
  Loader2,
  AlertCircle,
  RefreshCw,
  TrendingUp,
  DollarSign,
  Zap,
  Clock,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

interface ApiCostSummary {
  api_name: string;
  total_requests: number;
  total_cost_cents: number;
  avg_latency_ms: number;
  error_count: number;
  last_called: string | null;
}

interface DailyCost {
  date: string;
  total_cost_cents: number;
  total_requests: number;
}

const API_LABELS: Record<string, { label: string; free: boolean }> = {
  google_solar: { label: 'Google Solar API', free: true },
  overpass: { label: 'Overpass (OSM)', free: true },
  nominatim: { label: 'Nominatim (OSM)', free: true },
  noaa: { label: 'NOAA Storm Events', free: true },
  spc: { label: 'SPC Storm Reports', free: true },
  usgs_3dep: { label: 'USGS 3DEP Elevation', free: true },
  attom: { label: 'ATTOM Property', free: false },
  regrid: { label: 'Regrid Parcels', free: false },
  unwrangle: { label: 'Unwrangle (HD/Lowes)', free: false },
};

// ============================================================================
// PAGE
// ============================================================================

export default function ApiCostsPage() {
  const [summaries, setSummaries] = useState<ApiCostSummary[]>([]);
  const [dailyCosts, setDailyCosts] = useState<DailyCost[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [period, setPeriod] = useState<'7d' | '30d' | '90d'>('30d');

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const daysBack = period === '7d' ? 7 : period === '30d' ? 30 : 90;
      const cutoff = new Date();
      cutoff.setDate(cutoff.getDate() - daysBack);
      const cutoffStr = cutoff.toISOString();

      // Fetch raw cost log entries for aggregation
      const { data: logs, error: logErr } = await supabase
        .from('api_cost_log')
        .select('api_name, cost_cents, latency_ms, response_status, created_at')
        .gte('created_at', cutoffStr)
        .order('created_at', { ascending: false })
        .limit(5000);

      if (logErr) throw logErr;
      const rows = logs || [];

      // Aggregate by api_name
      const apiMap = new Map<string, ApiCostSummary>();
      for (const row of rows) {
        const name = row.api_name as string;
        if (!apiMap.has(name)) {
          apiMap.set(name, {
            api_name: name,
            total_requests: 0,
            total_cost_cents: 0,
            avg_latency_ms: 0,
            error_count: 0,
            last_called: null,
          });
        }
        const summary = apiMap.get(name)!;
        summary.total_requests += 1;
        summary.total_cost_cents += Number(row.cost_cents) || 0;
        summary.avg_latency_ms += Number(row.latency_ms) || 0;
        if (Number(row.response_status) >= 400) summary.error_count += 1;
        if (!summary.last_called) summary.last_called = row.created_at as string;
      }

      // Finalize averages
      const summaryList: ApiCostSummary[] = [];
      for (const [, s] of apiMap) {
        s.avg_latency_ms = s.total_requests > 0 ? Math.round(s.avg_latency_ms / s.total_requests) : 0;
        summaryList.push(s);
      }
      summaryList.sort((a, b) => b.total_cost_cents - a.total_cost_cents || b.total_requests - a.total_requests);
      setSummaries(summaryList);

      // Aggregate daily costs
      const dayMap = new Map<string, DailyCost>();
      for (const row of rows) {
        const date = (row.created_at as string).slice(0, 10);
        if (!dayMap.has(date)) {
          dayMap.set(date, { date, total_cost_cents: 0, total_requests: 0 });
        }
        const d = dayMap.get(date)!;
        d.total_cost_cents += Number(row.cost_cents) || 0;
        d.total_requests += 1;
      }
      const dailyList = Array.from(dayMap.values()).sort((a, b) => a.date.localeCompare(b.date));
      setDailyCosts(dailyList);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load API cost data');
    } finally {
      setLoading(false);
    }
  }, [period]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const totalCostCents = summaries.reduce((sum, s) => sum + s.total_cost_cents, 0);
  const totalRequests = summaries.reduce((sum, s) => sum + s.total_requests, 0);
  const freeRequests = summaries
    .filter(s => API_LABELS[s.api_name]?.free)
    .reduce((sum, s) => sum + s.total_requests, 0);
  const paidRequests = totalRequests - freeRequests;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Satellite className="h-6 w-6 text-[var(--accent)]" />
          <div>
            <h1 className="text-xl font-bold text-[var(--text-primary)]">API Cost Tracker</h1>
            <p className="text-sm text-[var(--text-secondary)]">
              Property Intelligence & Recon API usage
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {(['7d', '30d', '90d'] as const).map(p => (
            <button
              key={p}
              onClick={() => setPeriod(p)}
              className={`px-3 py-1.5 rounded-md text-sm transition-colors ${
                period === p
                  ? 'bg-[var(--accent)]/10 text-[var(--accent)] font-medium'
                  : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
              }`}
            >
              {p}
            </button>
          ))}
          <button
            onClick={fetchData}
            className="p-2 text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors"
          >
            <RefreshCw className="h-4 w-4" />
          </button>
        </div>
      </div>

      {loading && (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="h-6 w-6 animate-spin text-[var(--text-secondary)]" />
        </div>
      )}

      {error && (
        <div className="flex items-center gap-2 p-4 rounded-lg bg-red-50 dark:bg-red-950/20 text-red-600 dark:text-red-400">
          <AlertCircle className="h-5 w-5" />
          <span className="text-sm">{error}</span>
        </div>
      )}

      {!loading && !error && (
        <>
          {/* Summary Cards */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <Card>
              <CardContent className="pt-4 text-center">
                <DollarSign className="h-5 w-5 mx-auto text-[var(--text-secondary)] mb-1" />
                <p className="text-2xl font-bold text-[var(--text-primary)]">
                  ${(totalCostCents / 100).toFixed(2)}
                </p>
                <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider mt-1">Total Cost</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-4 text-center">
                <Zap className="h-5 w-5 mx-auto text-[var(--text-secondary)] mb-1" />
                <p className="text-2xl font-bold text-[var(--text-primary)]">
                  {totalRequests.toLocaleString()}
                </p>
                <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider mt-1">Total Requests</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-4 text-center">
                <TrendingUp className="h-5 w-5 mx-auto text-emerald-500 mb-1" />
                <p className="text-2xl font-bold text-emerald-500">
                  {freeRequests.toLocaleString()}
                </p>
                <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider mt-1">Free API Calls</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-4 text-center">
                <DollarSign className="h-5 w-5 mx-auto text-amber-500 mb-1" />
                <p className="text-2xl font-bold text-amber-500">
                  {paidRequests.toLocaleString()}
                </p>
                <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider mt-1">Paid API Calls</p>
              </CardContent>
            </Card>
          </div>

          {/* Daily cost chart (simplified bar chart) */}
          {dailyCosts.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Daily Request Volume</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex items-end gap-1 h-32">
                  {dailyCosts.map(d => {
                    const maxReqs = Math.max(...dailyCosts.map(dc => dc.total_requests), 1);
                    const heightPct = (d.total_requests / maxReqs) * 100;
                    return (
                      <div
                        key={d.date}
                        className="flex-1 min-w-0 group relative"
                        title={`${d.date}: ${d.total_requests} requests, $${(d.total_cost_cents / 100).toFixed(2)}`}
                      >
                        <div
                          className="bg-[var(--accent)]/20 hover:bg-[var(--accent)]/40 rounded-t transition-colors"
                          style={{ height: `${Math.max(heightPct, 2)}%` }}
                        />
                      </div>
                    );
                  })}
                </div>
                <div className="flex justify-between mt-2 text-[10px] text-[var(--text-secondary)]">
                  <span>{dailyCosts[0]?.date}</span>
                  <span>{dailyCosts[dailyCosts.length - 1]?.date}</span>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Per-API breakdown */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">API Breakdown</CardTitle>
            </CardHeader>
            <CardContent>
              {summaries.length === 0 ? (
                <p className="text-center text-sm text-[var(--text-secondary)] py-8">
                  No API usage data in selected period
                </p>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-[var(--border)] text-left">
                        <th className="pb-3 text-[var(--text-secondary)] font-medium">API</th>
                        <th className="pb-3 text-[var(--text-secondary)] font-medium text-right">Requests</th>
                        <th className="pb-3 text-[var(--text-secondary)] font-medium text-right">Cost</th>
                        <th className="pb-3 text-[var(--text-secondary)] font-medium text-right">Avg Latency</th>
                        <th className="pb-3 text-[var(--text-secondary)] font-medium text-right">Errors</th>
                        <th className="pb-3 text-[var(--text-secondary)] font-medium text-right">Last Called</th>
                      </tr>
                    </thead>
                    <tbody>
                      {summaries.map(s => {
                        const info = API_LABELS[s.api_name] || { label: s.api_name, free: true };
                        return (
                          <tr key={s.api_name} className="border-b border-[var(--border)]/50">
                            <td className="py-3">
                              <div className="flex items-center gap-2">
                                <span className="text-[var(--text-primary)] font-medium">{info.label}</span>
                                <span className={`text-[10px] px-1.5 py-0.5 rounded ${
                                  info.free
                                    ? 'bg-emerald-500/10 text-emerald-500'
                                    : 'bg-amber-500/10 text-amber-500'
                                }`}>
                                  {info.free ? 'FREE' : 'PAID'}
                                </span>
                              </div>
                            </td>
                            <td className="py-3 text-right text-[var(--text-primary)]">
                              {s.total_requests.toLocaleString()}
                            </td>
                            <td className="py-3 text-right text-[var(--text-primary)] font-medium">
                              {s.total_cost_cents > 0 ? `$${(s.total_cost_cents / 100).toFixed(2)}` : '$0.00'}
                            </td>
                            <td className="py-3 text-right text-[var(--text-secondary)]">
                              <span className="flex items-center justify-end gap-1">
                                <Clock className="h-3 w-3" />
                                {s.avg_latency_ms}ms
                              </span>
                            </td>
                            <td className="py-3 text-right">
                              <span className={s.error_count > 0 ? 'text-red-500 font-medium' : 'text-[var(--text-secondary)]'}>
                                {s.error_count}
                              </span>
                            </td>
                            <td className="py-3 text-right text-[var(--text-secondary)] text-xs">
                              {s.last_called
                                ? new Date(s.last_called).toLocaleDateString()
                                : '—'
                              }
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                    <tfoot>
                      <tr className="border-t-2 border-[var(--border)]">
                        <td className="py-3 font-semibold text-[var(--text-primary)]">Total</td>
                        <td className="py-3 text-right font-semibold text-[var(--text-primary)]">
                          {totalRequests.toLocaleString()}
                        </td>
                        <td className="py-3 text-right font-semibold text-[var(--text-primary)]">
                          ${(totalCostCents / 100).toFixed(2)}
                        </td>
                        <td colSpan={3} />
                      </tr>
                    </tfoot>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Cost projection */}
          {totalCostCents > 0 && (
            <Card>
              <CardContent className="py-4">
                <div className="flex items-center gap-3">
                  <TrendingUp className="h-5 w-5 text-amber-500" />
                  <div>
                    <p className="text-sm font-medium text-[var(--text-primary)]">
                      Projected Monthly Cost: ${((totalCostCents / (period === '7d' ? 7 : period === '30d' ? 30 : 90)) * 30 / 100).toFixed(2)}
                    </p>
                    <p className="text-xs text-[var(--text-secondary)]">
                      Based on current {period} usage rate. Free APIs ($0) keep costs near zero at launch.
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Empty state */}
          {summaries.length === 0 && (
            <div className="text-center py-12">
              <Satellite className="h-12 w-12 mx-auto text-[var(--text-secondary)]/30 mb-3" />
              <p className="text-sm text-[var(--text-secondary)]">
                No API calls tracked yet. Costs will appear here once Property Intelligence is active.
              </p>
              <p className="text-xs text-[var(--text-secondary)] mt-1">
                All APIs are FREE at launch — ATTOM, Regrid, and Unwrangle are gated behind API keys.
              </p>
            </div>
          )}
        </>
      )}
    </div>
  );
}
