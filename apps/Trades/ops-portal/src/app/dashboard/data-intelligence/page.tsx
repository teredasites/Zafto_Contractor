'use client';

// DATA-ARCH4: Data Intelligence Dashboard — Ops Portal nerve center for all data pipelines.
// Shows: source health, ingestion timeline, gateway metrics, cost tracker, coverage map, manual controls.

import { useState, useMemo } from 'react';
import {
  Database,
  Loader2,
  AlertCircle,
  RefreshCw,
  Activity,
  CheckCircle,
  XCircle,
  Clock,
  DollarSign,
  Zap,
  BarChart3,
  Shield,
  Pause,
  Play,
  TestTube,
  Filter,
  ChevronDown,
  ChevronUp,
  Globe,
  Server,
  Layers,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { useDataSources } from '@/lib/hooks/use-data-sources';

// ============================================================================
// STATUS HELPERS
// ============================================================================

function statusColor(status: string): string {
  switch (status) {
    case 'OK': return 'text-green-400';
    case 'PENDING': return 'text-yellow-400';
    case 'STALE': return 'text-yellow-400';
    case 'FAILED': return 'text-red-400';
    case 'DISABLED': return 'text-zinc-500';
    default: return 'text-zinc-400';
  }
}

function statusBg(status: string): string {
  switch (status) {
    case 'OK': return 'bg-green-500/10 border-green-500/20';
    case 'PENDING': return 'bg-yellow-500/10 border-yellow-500/20';
    case 'STALE': return 'bg-yellow-500/10 border-yellow-500/20';
    case 'FAILED': return 'bg-red-500/10 border-red-500/20';
    case 'DISABLED': return 'bg-zinc-500/10 border-zinc-500/20';
    default: return 'bg-zinc-500/10 border-zinc-500/20';
  }
}

function StatusIcon({ status }: { status: string }) {
  switch (status) {
    case 'OK': return <CheckCircle className="h-4 w-4 text-green-400" />;
    case 'PENDING': return <Clock className="h-4 w-4 text-yellow-400" />;
    case 'STALE': return <Clock className="h-4 w-4 text-yellow-400" />;
    case 'FAILED': return <XCircle className="h-4 w-4 text-red-400" />;
    case 'DISABLED': return <Pause className="h-4 w-4 text-zinc-500" />;
    default: return <Activity className="h-4 w-4 text-zinc-400" />;
  }
}

function tierLabel(tier: number): string {
  switch (tier) {
    case 1: return 'Core';
    case 2: return 'Enhanced';
    case 3: return 'Specialized';
    default: return `Tier ${tier}`;
  }
}

function tierBg(tier: number): string {
  switch (tier) {
    case 1: return 'bg-blue-500/10 text-blue-400 border-blue-500/20';
    case 2: return 'bg-purple-500/10 text-purple-400 border-purple-500/20';
    case 3: return 'bg-amber-500/10 text-amber-400 border-amber-500/20';
    default: return 'bg-zinc-500/10 text-zinc-400 border-zinc-500/20';
  }
}

function timeAgo(dateStr: string | null): string {
  if (!dateStr) return 'Never';
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'Just now';
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

// ============================================================================
// PAGE
// ============================================================================

export default function DataIntelligencePage() {
  const {
    sources, ingestionLogs, metrics, staleSources,
    totalSources, activeSources, tier1Sources, tier2Sources, tier3Sources,
    totalMonthlyCost, failedSources, categories,
    loading, error, refreshing,
    refreshSource, refreshAllStale, toggleSource, reload,
  } = useDataSources();

  const [filterCategory, setFilterCategory] = useState<string>('all');
  const [filterTier, setFilterTier] = useState<number | null>(null);
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [expandedSource, setExpandedSource] = useState<string | null>(null);
  const [logPeriod, setLogPeriod] = useState<'24h' | '7d' | '30d'>('24h');

  // Filtered sources
  const filteredSources = useMemo(() => {
    return sources.filter(s => {
      if (filterCategory !== 'all' && s.category !== filterCategory) return false;
      if (filterTier !== null && s.tier !== filterTier) return false;
      if (filterStatus !== 'all' && s.lastStatus !== filterStatus) return false;
      return true;
    });
  }, [sources, filterCategory, filterTier, filterStatus]);

  // Filtered ingestion logs by period
  const filteredLogs = useMemo(() => {
    const cutoff = {
      '24h': 86400000,
      '7d': 7 * 86400000,
      '30d': 30 * 86400000,
    }[logPeriod];
    const threshold = Date.now() - cutoff;
    return ingestionLogs.filter(l => new Date(l.startedAt).getTime() > threshold);
  }, [ingestionLogs, logPeriod]);

  // Metrics aggregation (last 7 days)
  const metricsAgg = useMemo(() => {
    const totalRequests = metrics.reduce((s, m) => s + m.totalRequests, 0);
    const totalCacheHits = metrics.reduce((s, m) => s + m.cacheHits, 0);
    const totalFailures = metrics.reduce((s, m) => s + m.failures, 0);
    const totalExternal = metrics.reduce((s, m) => s + m.externalCalls, 0);
    const cacheHitRate = totalRequests > 0 ? (totalCacheHits / totalRequests) * 100 : 0;
    const failureRate = totalRequests > 0 ? (totalFailures / totalRequests) * 100 : 0;
    const avgResponseMs = metrics.length > 0
      ? metrics.reduce((s, m) => s + m.avgResponseMs, 0) / metrics.length
      : 0;

    return {
      totalRequests, totalCacheHits, totalFailures, totalExternal,
      cacheHitRate, failureRate, avgResponseMs,
    };
  }, [metrics]);

  // ── Loading state ──
  if (loading) {
    return (
      <div className="flex items-center justify-center h-[60vh]">
        <Loader2 className="h-8 w-8 animate-spin text-zinc-400" />
        <span className="ml-3 text-zinc-400">Loading data intelligence...</span>
      </div>
    );
  }

  // ── Error state ──
  if (error) {
    return (
      <div className="flex items-center justify-center h-[60vh]">
        <AlertCircle className="h-8 w-8 text-red-400" />
        <span className="ml-3 text-red-400">{error}</span>
        <button onClick={reload} className="ml-4 px-3 py-1 bg-zinc-700 rounded text-sm hover:bg-zinc-600">
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Database className="h-7 w-7 text-blue-400" />
          <div>
            <h1 className="text-2xl font-bold text-white">Data Intelligence</h1>
            <p className="text-sm text-zinc-400">API registry, ingestion health, gateway metrics</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {staleSources.length > 0 && (
            <button
              onClick={refreshAllStale}
              disabled={refreshing === '__all__'}
              className="px-3 py-2 bg-yellow-600 hover:bg-yellow-500 text-white text-sm rounded-lg flex items-center gap-2 disabled:opacity-50"
            >
              {refreshing === '__all__' ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Zap className="h-4 w-4" />
              )}
              Refresh {staleSources.length} Stale
            </button>
          )}
          <button
            onClick={reload}
            className="px-3 py-2 bg-zinc-700 hover:bg-zinc-600 text-white text-sm rounded-lg flex items-center gap-2"
          >
            <RefreshCw className="h-4 w-4" />
            Reload
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
        <Card className="bg-zinc-900 border-zinc-800">
          <CardContent className="pt-4 pb-3 px-4">
            <div className="flex items-center gap-2 mb-1">
              <Server className="h-4 w-4 text-blue-400" />
              <span className="text-xs text-zinc-400">Total Sources</span>
            </div>
            <p className="text-2xl font-bold text-white">{totalSources}</p>
            <p className="text-xs text-zinc-500">{activeSources} active</p>
          </CardContent>
        </Card>

        <Card className="bg-zinc-900 border-zinc-800">
          <CardContent className="pt-4 pb-3 px-4">
            <div className="flex items-center gap-2 mb-1">
              <CheckCircle className="h-4 w-4 text-green-400" />
              <span className="text-xs text-zinc-400">Healthy</span>
            </div>
            <p className="text-2xl font-bold text-green-400">
              {sources.filter(s => s.lastStatus === 'OK').length}
            </p>
            <p className="text-xs text-zinc-500">
              {failedSources.length > 0 ? `${failedSources.length} failed` : 'All good'}
            </p>
          </CardContent>
        </Card>

        <Card className="bg-zinc-900 border-zinc-800">
          <CardContent className="pt-4 pb-3 px-4">
            <div className="flex items-center gap-2 mb-1">
              <Clock className="h-4 w-4 text-yellow-400" />
              <span className="text-xs text-zinc-400">Stale</span>
            </div>
            <p className="text-2xl font-bold text-yellow-400">{staleSources.length}</p>
            <p className="text-xs text-zinc-500">Need refresh</p>
          </CardContent>
        </Card>

        <Card className="bg-zinc-900 border-zinc-800">
          <CardContent className="pt-4 pb-3 px-4">
            <div className="flex items-center gap-2 mb-1">
              <BarChart3 className="h-4 w-4 text-purple-400" />
              <span className="text-xs text-zinc-400">Requests (7d)</span>
            </div>
            <p className="text-2xl font-bold text-white">{metricsAgg.totalRequests.toLocaleString()}</p>
            <p className="text-xs text-zinc-500">
              {metricsAgg.cacheHitRate.toFixed(0)}% cache hit
            </p>
          </CardContent>
        </Card>

        <Card className="bg-zinc-900 border-zinc-800">
          <CardContent className="pt-4 pb-3 px-4">
            <div className="flex items-center gap-2 mb-1">
              <Shield className="h-4 w-4 text-cyan-400" />
              <span className="text-xs text-zinc-400">Failure Rate</span>
            </div>
            <p className={`text-2xl font-bold ${metricsAgg.failureRate > 5 ? 'text-red-400' : 'text-green-400'}`}>
              {metricsAgg.failureRate.toFixed(1)}%
            </p>
            <p className="text-xs text-zinc-500">{metricsAgg.totalFailures} failures</p>
          </CardContent>
        </Card>

        <Card className="bg-zinc-900 border-zinc-800">
          <CardContent className="pt-4 pb-3 px-4">
            <div className="flex items-center gap-2 mb-1">
              <DollarSign className="h-4 w-4 text-green-400" />
              <span className="text-xs text-zinc-400">Monthly Cost</span>
            </div>
            <p className="text-2xl font-bold text-green-400">
              ${(totalMonthlyCost / 100).toFixed(2)}
            </p>
            <p className="text-xs text-zinc-500">$0/mo target</p>
          </CardContent>
        </Card>
      </div>

      {/* Tier Breakdown */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {[
          { tier: 1, label: 'Core APIs', sources: tier1Sources, desc: 'Essential for day-1 operations' },
          { tier: 2, label: 'Enhanced APIs', sources: tier2Sources, desc: 'Deeper intelligence features' },
          { tier: 3, label: 'Specialized APIs', sources: tier3Sources, desc: 'Trade-specific & niche' },
        ].map(t => (
          <Card key={t.tier} className="bg-zinc-900 border-zinc-800">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm flex items-center gap-2">
                <Layers className="h-4 w-4 text-zinc-400" />
                {t.label}
                <span className={`ml-auto px-2 py-0.5 rounded text-xs border ${tierBg(t.tier)}`}>
                  {t.sources.length} sources
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-xs text-zinc-500 mb-2">{t.desc}</p>
              <div className="flex gap-2 text-xs">
                <span className="text-green-400">
                  {t.sources.filter(s => s.lastStatus === 'OK').length} OK
                </span>
                <span className="text-yellow-400">
                  {t.sources.filter(s => s.lastStatus === 'PENDING' || s.lastStatus === 'STALE').length} Pending
                </span>
                <span className="text-red-400">
                  {t.sources.filter(s => s.lastStatus === 'FAILED').length} Failed
                </span>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Filters */}
      <Card className="bg-zinc-900 border-zinc-800">
        <CardContent className="py-3 px-4">
          <div className="flex items-center gap-4 flex-wrap">
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-zinc-400" />
              <span className="text-sm text-zinc-400">Filters:</span>
            </div>

            <select
              value={filterCategory}
              onChange={e => setFilterCategory(e.target.value)}
              className="bg-zinc-800 border border-zinc-700 rounded px-2 py-1 text-sm text-zinc-300"
            >
              <option value="all">All Categories</option>
              {categories.map(c => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>

            <select
              value={filterTier ?? 'all'}
              onChange={e => setFilterTier(e.target.value === 'all' ? null : Number(e.target.value))}
              className="bg-zinc-800 border border-zinc-700 rounded px-2 py-1 text-sm text-zinc-300"
            >
              <option value="all">All Tiers</option>
              <option value="1">Tier 1 (Core)</option>
              <option value="2">Tier 2 (Enhanced)</option>
              <option value="3">Tier 3 (Specialized)</option>
            </select>

            <select
              value={filterStatus}
              onChange={e => setFilterStatus(e.target.value)}
              className="bg-zinc-800 border border-zinc-700 rounded px-2 py-1 text-sm text-zinc-300"
            >
              <option value="all">All Statuses</option>
              <option value="OK">OK</option>
              <option value="PENDING">Pending</option>
              <option value="STALE">Stale</option>
              <option value="FAILED">Failed</option>
              <option value="DISABLED">Disabled</option>
            </select>

            <span className="text-xs text-zinc-500 ml-auto">
              Showing {filteredSources.length} of {totalSources}
            </span>
          </div>
        </CardContent>
      </Card>

      {/* Data Sources Table */}
      <Card className="bg-zinc-900 border-zinc-800">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm flex items-center gap-2">
            <Globe className="h-4 w-4 text-blue-400" />
            Data Sources Registry
          </CardTitle>
        </CardHeader>
        <CardContent>
          {filteredSources.length === 0 ? (
            <p className="text-sm text-zinc-500 text-center py-8">No sources match filters</p>
          ) : (
            <div className="divide-y divide-zinc-800">
              {filteredSources.map(source => {
                const isExpanded = expandedSource === source.sourceKey;
                const sourceLogs = ingestionLogs.filter(l => l.sourceKey === source.sourceKey).slice(0, 5);
                const sourceMetrics = metrics.filter(m => m.sourceKey === source.sourceKey);

                return (
                  <div key={source.id} className="py-3">
                    <div className="flex items-center gap-3">
                      <StatusIcon status={source.lastStatus} />

                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-white text-sm">{source.displayName}</span>
                          <span className={`px-1.5 py-0.5 rounded text-xs border ${tierBg(source.tier)}`}>
                            {tierLabel(source.tier)}
                          </span>
                          <span className={`px-1.5 py-0.5 rounded text-xs border ${statusBg(source.lastStatus)}`}>
                            <span className={statusColor(source.lastStatus)}>{source.lastStatus}</span>
                          </span>
                          <span className="text-xs text-zinc-600">{source.category}</span>
                        </div>
                        <div className="flex items-center gap-4 mt-1 text-xs text-zinc-500">
                          <span>Key: {source.sourceKey}</span>
                          <span>Auth: {source.authMethod}</span>
                          <span>Refresh: {source.refreshFrequency}</span>
                          <span>Last: {timeAgo(source.lastRefreshedAt)}</span>
                          <span>Rate: {source.rateLimitRemaining}/{source.rateLimitPerDay}</span>
                        </div>
                      </div>

                      <div className="flex items-center gap-2 shrink-0">
                        {/* Refresh button */}
                        <button
                          onClick={() => refreshSource(source.sourceKey)}
                          disabled={refreshing !== null}
                          className="p-1.5 bg-zinc-800 hover:bg-zinc-700 rounded text-zinc-400 hover:text-white disabled:opacity-50"
                          title="Refresh Now"
                        >
                          {refreshing === source.sourceKey ? (
                            <Loader2 className="h-4 w-4 animate-spin" />
                          ) : (
                            <RefreshCw className="h-4 w-4" />
                          )}
                        </button>

                        {/* Toggle active/disabled */}
                        <button
                          onClick={() => toggleSource(source.sourceKey, !source.isActive)}
                          className={`p-1.5 rounded ${
                            source.isActive
                              ? 'bg-green-500/10 text-green-400 hover:bg-green-500/20'
                              : 'bg-zinc-800 text-zinc-500 hover:bg-zinc-700'
                          }`}
                          title={source.isActive ? 'Pause Source' : 'Resume Source'}
                        >
                          {source.isActive ? <Play className="h-4 w-4" /> : <Pause className="h-4 w-4" />}
                        </button>

                        {/* Expand */}
                        <button
                          onClick={() => setExpandedSource(isExpanded ? null : source.sourceKey)}
                          className="p-1.5 bg-zinc-800 hover:bg-zinc-700 rounded text-zinc-400"
                        >
                          {isExpanded ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
                        </button>
                      </div>
                    </div>

                    {/* Expanded detail */}
                    {isExpanded && (
                      <div className="mt-3 ml-7 space-y-3">
                        {/* Description */}
                        {source.description && (
                          <p className="text-sm text-zinc-400">{source.description}</p>
                        )}

                        {/* Source details grid */}
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                          <div className="bg-zinc-800 rounded p-2">
                            <span className="text-xs text-zinc-500">Base URL</span>
                            <p className="text-xs text-zinc-300 truncate">{source.baseUrl}</p>
                          </div>
                          <div className="bg-zinc-800 rounded p-2">
                            <span className="text-xs text-zinc-500">Monthly Cost</span>
                            <p className="text-xs text-zinc-300">${(source.monthlyCostCents / 100).toFixed(2)}</p>
                          </div>
                          <div className="bg-zinc-800 rounded p-2">
                            <span className="text-xs text-zinc-500">License</span>
                            <p className="text-xs text-zinc-300">{source.license || 'N/A'}</p>
                          </div>
                          <div className="bg-zinc-800 rounded p-2">
                            <span className="text-xs text-zinc-500">Fallback</span>
                            <p className="text-xs text-zinc-300">{source.fallbackSourceKey || 'None'}</p>
                          </div>
                        </div>

                        {/* Last error */}
                        {source.lastError && (
                          <div className="bg-red-500/10 border border-red-500/20 rounded p-2">
                            <span className="text-xs text-red-400 font-medium">Last Error:</span>
                            <p className="text-xs text-red-300 mt-1">{source.lastError}</p>
                          </div>
                        )}

                        {/* Recent ingestion logs */}
                        {sourceLogs.length > 0 && (
                          <div>
                            <h4 className="text-xs text-zinc-400 font-medium mb-2">Recent Ingestion Logs</h4>
                            <div className="space-y-1">
                              {sourceLogs.map(log => (
                                <div key={log.id} className="flex items-center gap-3 text-xs bg-zinc-800 rounded px-2 py-1.5">
                                  <StatusIcon status={log.status} />
                                  <span className="text-zinc-400">
                                    {new Date(log.startedAt).toLocaleString()}
                                  </span>
                                  <span className={log.status === 'SUCCESS' ? 'text-green-400' : 'text-red-400'}>
                                    {log.status}
                                  </span>
                                  <span className="text-zinc-500">
                                    {log.durationMs ? `${log.durationMs}ms` : '...'}
                                  </span>
                                  <span className="text-zinc-500">
                                    {log.recordsFetched} fetched / {log.recordsUpserted} upserted
                                  </span>
                                  {log.errorMessage && (
                                    <span className="text-red-400 truncate">{log.errorMessage}</span>
                                  )}
                                </div>
                              ))}
                            </div>
                          </div>
                        )}

                        {/* Source metrics */}
                        {sourceMetrics.length > 0 && (
                          <div>
                            <h4 className="text-xs text-zinc-400 font-medium mb-2">Gateway Metrics (7d)</h4>
                            <div className="grid grid-cols-3 md:grid-cols-5 gap-2">
                              {sourceMetrics.slice(0, 7).map(m => (
                                <div key={m.id} className="bg-zinc-800 rounded p-2 text-center">
                                  <p className="text-xs text-zinc-500">{m.metricDate}</p>
                                  <p className="text-sm font-medium text-white">{m.totalRequests}</p>
                                  <p className="text-xs text-zinc-500">
                                    {m.totalRequests > 0
                                      ? `${((m.cacheHits / m.totalRequests) * 100).toFixed(0)}% cached`
                                      : 'No requests'}
                                  </p>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}

                        {/* Documentation link */}
                        {source.documentationUrl && (
                          <a
                            href={source.documentationUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1 text-xs text-blue-400 hover:text-blue-300"
                          >
                            <Globe className="h-3 w-3" />
                            API Documentation
                          </a>
                        )}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Ingestion Timeline */}
      <Card className="bg-zinc-900 border-zinc-800">
        <CardHeader className="pb-2">
          <div className="flex items-center justify-between">
            <CardTitle className="text-sm flex items-center gap-2">
              <Activity className="h-4 w-4 text-purple-400" />
              Ingestion Timeline
            </CardTitle>
            <div className="flex gap-1">
              {(['24h', '7d', '30d'] as const).map(p => (
                <button
                  key={p}
                  onClick={() => setLogPeriod(p)}
                  className={`px-2 py-1 rounded text-xs ${
                    logPeriod === p
                      ? 'bg-blue-600 text-white'
                      : 'bg-zinc-800 text-zinc-400 hover:text-white'
                  }`}
                >
                  {p}
                </button>
              ))}
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {filteredLogs.length === 0 ? (
            <p className="text-sm text-zinc-500 text-center py-6">No ingestion logs in this period</p>
          ) : (
            <div className="space-y-1 max-h-[400px] overflow-y-auto">
              {filteredLogs.map(log => (
                <div key={log.id} className="flex items-center gap-3 text-xs bg-zinc-800/50 rounded px-3 py-2">
                  <StatusIcon status={log.status} />
                  <span className="text-zinc-300 font-medium w-32 truncate">{log.sourceKey}</span>
                  <span className="text-zinc-500 w-36">
                    {new Date(log.startedAt).toLocaleString()}
                  </span>
                  <span className={`w-16 ${log.status === 'SUCCESS' ? 'text-green-400' : log.status === 'RUNNING' ? 'text-blue-400' : 'text-red-400'}`}>
                    {log.status}
                  </span>
                  <span className="text-zinc-500 w-16">
                    {log.durationMs ? `${log.durationMs}ms` : '...'}
                  </span>
                  <span className="text-zinc-400">
                    {log.recordsFetched}F / {log.recordsUpserted}U / {log.recordsSkipped}S
                  </span>
                  <span className="text-zinc-600 ml-auto">{log.triggeredBy}</span>
                  {log.errorMessage && (
                    <span className="text-red-400 truncate max-w-[200px]" title={log.errorMessage}>
                      {log.errorMessage}
                    </span>
                  )}
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Gateway Metrics Summary */}
      <Card className="bg-zinc-900 border-zinc-800">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm flex items-center gap-2">
            <BarChart3 className="h-4 w-4 text-cyan-400" />
            Gateway Performance (7-day aggregate)
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="bg-zinc-800 rounded p-3 text-center">
              <p className="text-2xl font-bold text-white">{metricsAgg.totalRequests.toLocaleString()}</p>
              <p className="text-xs text-zinc-500">Total Requests</p>
            </div>
            <div className="bg-zinc-800 rounded p-3 text-center">
              <p className="text-2xl font-bold text-green-400">{metricsAgg.cacheHitRate.toFixed(1)}%</p>
              <p className="text-xs text-zinc-500">Cache Hit Rate</p>
            </div>
            <div className="bg-zinc-800 rounded p-3 text-center">
              <p className="text-2xl font-bold text-cyan-400">{metricsAgg.avgResponseMs.toFixed(0)}ms</p>
              <p className="text-xs text-zinc-500">Avg Response</p>
            </div>
            <div className="bg-zinc-800 rounded p-3 text-center">
              <p className="text-2xl font-bold text-purple-400">{metricsAgg.totalExternal.toLocaleString()}</p>
              <p className="text-xs text-zinc-500">External Calls</p>
            </div>
          </div>

          {/* Per-source metrics table */}
          {metrics.length > 0 && (
            <div className="mt-4">
              <h4 className="text-xs text-zinc-400 font-medium mb-2">By Source (latest day)</h4>
              <div className="space-y-1">
                {/* Group metrics by source, show latest */}
                {[...new Set(metrics.map(m => m.sourceKey))].map(sourceKey => {
                  const latest = metrics.find(m => m.sourceKey === sourceKey);
                  if (!latest) return null;
                  const hitRate = latest.totalRequests > 0
                    ? ((latest.cacheHits / latest.totalRequests) * 100).toFixed(0)
                    : '0';

                  return (
                    <div key={sourceKey} className="flex items-center gap-3 text-xs bg-zinc-800/50 rounded px-3 py-2">
                      <span className="text-zinc-300 font-medium w-40 truncate">{sourceKey}</span>
                      <span className="text-zinc-400 w-20">{latest.metricDate}</span>
                      <span className="text-white w-20">{latest.totalRequests} req</span>
                      <span className="text-green-400 w-20">{hitRate}% cache</span>
                      <span className="text-cyan-400 w-20">{latest.avgResponseMs}ms avg</span>
                      <span className={`w-16 ${latest.failures > 0 ? 'text-red-400' : 'text-zinc-500'}`}>
                        {latest.failures} fail
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Cost Tracker */}
      <Card className="bg-zinc-900 border-zinc-800">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm flex items-center gap-2">
            <DollarSign className="h-4 w-4 text-green-400" />
            Cost Tracker — $0/mo Verification
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-1">
            {sources
              .sort((a, b) => b.monthlyCostCents - a.monthlyCostCents)
              .map(s => (
                <div key={s.id} className="flex items-center gap-3 text-xs py-1.5">
                  <span className={`w-2 h-2 rounded-full ${s.monthlyCostCents === 0 ? 'bg-green-400' : 'bg-red-400'}`} />
                  <span className="text-zinc-300 w-40 truncate">{s.displayName}</span>
                  <span className={`font-medium ${s.monthlyCostCents === 0 ? 'text-green-400' : 'text-red-400'}`}>
                    ${(s.monthlyCostCents / 100).toFixed(2)}/mo
                  </span>
                  <span className="text-zinc-600 truncate">{s.costNotes || ''}</span>
                </div>
              ))}
          </div>
          <div className="mt-3 pt-3 border-t border-zinc-800 flex items-center justify-between">
            <span className="text-sm text-zinc-400">Total Monthly API Cost</span>
            <span className={`text-lg font-bold ${totalMonthlyCost === 0 ? 'text-green-400' : 'text-red-400'}`}>
              ${(totalMonthlyCost / 100).toFixed(2)}/mo
            </span>
          </div>
        </CardContent>
      </Card>

      {/* Coverage Map: which features are wired to which APIs */}
      <Card className="bg-zinc-900 border-zinc-800">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm flex items-center gap-2">
            <Layers className="h-4 w-4 text-amber-400" />
            API Coverage by Category
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
            {categories.map(cat => {
              const catSources = sources.filter(s => s.category === cat);
              const active = catSources.filter(s => s.isActive).length;
              const ok = catSources.filter(s => s.lastStatus === 'OK').length;

              return (
                <div key={cat} className="bg-zinc-800 rounded p-3">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm font-medium text-white">{cat}</span>
                    <span className="text-xs text-zinc-500">{catSources.length} sources</span>
                  </div>
                  <div className="flex gap-2 mb-2">
                    <div className="h-1.5 flex-1 bg-zinc-700 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-green-400 rounded-full"
                        style={{ width: `${catSources.length > 0 ? (ok / catSources.length) * 100 : 0}%` }}
                      />
                    </div>
                  </div>
                  <div className="flex gap-3 text-xs text-zinc-500">
                    <span className="text-green-400">{ok} healthy</span>
                    <span>{active} active</span>
                  </div>
                  <div className="mt-2 flex flex-wrap gap-1">
                    {catSources.map(s => (
                      <span
                        key={s.id}
                        className={`px-1.5 py-0.5 rounded text-xs border ${statusBg(s.lastStatus)}`}
                        title={`${s.displayName}: ${s.lastStatus}`}
                      >
                        <span className={statusColor(s.lastStatus)}>{s.sourceKey}</span>
                      </span>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
