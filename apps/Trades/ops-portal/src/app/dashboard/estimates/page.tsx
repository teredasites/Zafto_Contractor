'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import {
  FileText,
  TrendingUp,
  DollarSign,
  PenLine,
  Send,
  CheckCircle2,
  RefreshCw,
  Search,
  Database,
  ShieldCheck,
  BarChart3,
  Hash,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { formatDate, formatCurrency } from '@/lib/utils';

interface EstimateStats {
  total: number;
  draft: number;
  sent: number;
  approved: number;
  declined: number;
  expired: number;
  conversionRate: number;
  averageValue: number;
  regularCount: number;
  insuranceCount: number;
}

interface EstimateRow {
  id: string;
  estimate_number: string;
  customer_name: string | null;
  estimate_type: string;
  status: string;
  grand_total: number;
  created_at: string;
  company_id: string;
  companies: { name: string } | null;
}

interface CodeHealthStats {
  totalItems: number;
  pricedItems: number;
  coveragePct: number;
  topCodes: { zafto_code: string; usage_count: number }[];
}

type StatusFilter = 'all' | 'draft' | 'sent' | 'approved' | 'declined' | 'expired';

const STATUS_COLORS: Record<string, string> = {
  draft: 'bg-gray-500/10 text-gray-400',
  sent: 'bg-blue-500/10 text-blue-400',
  approved: 'bg-emerald-500/10 text-emerald-400',
  declined: 'bg-red-500/10 text-red-400',
  expired: 'bg-amber-500/10 text-amber-400',
};

const TYPE_COLORS: Record<string, string> = {
  regular: 'bg-blue-500/10 text-blue-400',
  insurance: 'bg-amber-500/10 text-amber-400',
};

export default function EstimatesPage() {
  const { profile } = useAuth();
  const [stats, setStats] = useState<EstimateStats | null>(null);
  const [estimates, setEstimates] = useState<EstimateRow[]>([]);
  const [codeHealth, setCodeHealth] = useState<CodeHealthStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<StatusFilter>('all');
  const [search, setSearch] = useState('');

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const supabase = getSupabase();

      // Fetch all stats in parallel
      const [
        totalRes,
        statusRes,
        avgRes,
        typeRes,
        recentRes,
        itemCountRes,
        pricedRes,
        topCodesRes,
      ] = await Promise.all([
        // Total estimates count
        supabase
          .from('estimates')
          .select('*', { count: 'exact', head: true })
          .is('deleted_at', null),

        // Status breakdown
        supabase
          .from('estimates')
          .select('status')
          .is('deleted_at', null),

        // Average grand total
        supabase
          .from('estimates')
          .select('grand_total')
          .is('deleted_at', null)
          .gt('grand_total', 0),

        // Type breakdown
        supabase
          .from('estimates')
          .select('estimate_type')
          .is('deleted_at', null),

        // Recent estimates with company join
        supabase
          .from('estimates')
          .select('id, estimate_number, customer_name, estimate_type, status, grand_total, created_at, company_id, companies(name)')
          .is('deleted_at', null)
          .order('created_at', { ascending: false })
          .limit(50),

        // Code health: total estimate_items
        supabase
          .from('estimate_items')
          .select('*', { count: 'exact', head: true })
          .is('deleted_at', null),

        // Code health: priced items (NATIONAL)
        supabase
          .from('estimate_pricing')
          .select('item_id', { count: 'exact', head: true })
          .eq('region_code', 'NATIONAL'),

        // Top 5 most-used codes
        supabase
          .from('estimate_line_items')
          .select('zafto_code'),
      ]);

      // Compute status counts
      const statusData = (statusRes.data || []) as { status: string }[];
      const draft = statusData.filter((r) => r.status === 'draft').length;
      const sent = statusData.filter((r) => r.status === 'sent').length;
      const approved = statusData.filter((r) => r.status === 'approved').length;
      const declined = statusData.filter((r) => r.status === 'declined').length;
      const expired = statusData.filter((r) => r.status === 'expired').length;

      // Conversion rate: approved / (sent + approved + declined)
      const conversionBase = sent + approved + declined;
      const conversionRate = conversionBase > 0 ? (approved / conversionBase) * 100 : 0;

      // Average value
      const grandTotals = (avgRes.data || []) as { grand_total: number }[];
      const avgValue =
        grandTotals.length > 0
          ? grandTotals.reduce((sum, r) => sum + (r.grand_total || 0), 0) / grandTotals.length
          : 0;

      // Type breakdown
      const typeData = (typeRes.data || []) as { estimate_type: string }[];
      const regularCount = typeData.filter((r) => r.estimate_type === 'regular').length;
      const insuranceCount = typeData.filter((r) => r.estimate_type === 'insurance').length;

      setStats({
        total: totalRes.count || 0,
        draft,
        sent,
        approved,
        declined,
        expired,
        conversionRate,
        averageValue: avgValue,
        regularCount,
        insuranceCount,
      });

      setEstimates((recentRes.data || []) as unknown as EstimateRow[]);

      // Code health: top codes aggregation
      const lineItems = (topCodesRes.data || []) as { zafto_code: string }[];
      const codeCounts = new Map<string, number>();
      lineItems.forEach((item) => {
        if (item.zafto_code) {
          codeCounts.set(item.zafto_code, (codeCounts.get(item.zafto_code) || 0) + 1);
        }
      });
      const topCodes = Array.from(codeCounts.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([zafto_code, usage_count]) => ({ zafto_code, usage_count }));

      const totalItems = itemCountRes.count || 0;
      const pricedItems = pricedRes.count || 0;
      const coveragePct = totalItems > 0 ? Math.round((pricedItems / totalItems) * 100) : 0;

      setCodeHealth({
        totalItems,
        pricedItems,
        coveragePct,
        topCodes,
      });
    } catch {
      // silently fail
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Filter estimates by status
  const filteredEstimates = estimates.filter((e) => {
    if (filter !== 'all' && e.status !== filter) return false;
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      (e.estimate_number || '').toLowerCase().includes(q) ||
      (e.customer_name || '').toLowerCase().includes(q) ||
      (e.companies?.name || '').toLowerCase().includes(q)
    );
  });

  const filterTabs: { key: StatusFilter; label: string; count?: number }[] = [
    { key: 'all', label: 'All', count: stats?.total },
    { key: 'draft', label: 'Draft', count: stats?.draft },
    { key: 'sent', label: 'Sent', count: stats?.sent },
    { key: 'approved', label: 'Approved', count: stats?.approved },
    { key: 'declined', label: 'Declined', count: stats?.declined },
    { key: 'expired', label: 'Expired', count: stats?.expired },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Estimate Analytics
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            Platform-wide estimate performance, conversion tracking, and code database health
          </p>
        </div>
        <button
          onClick={fetchData}
          disabled={loading}
          className="flex items-center gap-2 px-3 py-2 text-sm rounded-lg border border-[var(--border)] text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)] transition-colors"
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Stats Grid */}
      {loading ? (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <Card key={i}>
              <CardContent className="py-4">
                <div className="h-3 w-20 rounded skeleton-shimmer mb-3" />
                <div className="h-7 w-16 rounded skeleton-shimmer" />
              </CardContent>
            </Card>
          ))}
        </div>
      ) : stats && (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-2 mb-1">
                <FileText className="h-3.5 w-3.5 text-[var(--text-secondary)]" />
                <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider">Total</p>
              </div>
              <p className="text-2xl font-bold text-[var(--text-primary)]">{stats.total}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-2 mb-1">
                <TrendingUp className="h-3.5 w-3.5 text-[var(--text-secondary)]" />
                <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider">Conversion</p>
              </div>
              <p className="text-2xl font-bold text-emerald-400">{stats.conversionRate.toFixed(1)}%</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-2 mb-1">
                <DollarSign className="h-3.5 w-3.5 text-[var(--text-secondary)]" />
                <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider">Avg Value</p>
              </div>
              <p className="text-2xl font-bold text-[var(--text-primary)]">{formatCurrency(stats.averageValue)}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-2 mb-1">
                <PenLine className="h-3.5 w-3.5 text-yellow-500" />
                <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider">Draft</p>
              </div>
              <p className="text-2xl font-bold text-yellow-500">{stats.draft}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-2 mb-1">
                <Send className="h-3.5 w-3.5 text-blue-400" />
                <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider">Sent</p>
              </div>
              <p className="text-2xl font-bold text-blue-400">{stats.sent}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center gap-2 mb-1">
                <CheckCircle2 className="h-3.5 w-3.5 text-emerald-400" />
                <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider">Approved</p>
              </div>
              <p className="text-2xl font-bold text-emerald-400">{stats.approved}</p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Estimate Type Breakdown */}
      {stats && !loading && (
        <Card>
          <CardContent>
            <div className="flex items-center gap-2 mb-4">
              <BarChart3 className="h-4 w-4 text-[var(--text-secondary)]" />
              <h3 className="text-[15px] font-semibold text-[var(--text-primary)]">
                Estimate Type Breakdown
              </h3>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Visual bars */}
              <div className="space-y-4">
                {[
                  { label: 'Regular', count: stats.regularCount, color: 'bg-blue-500' },
                  { label: 'Insurance', count: stats.insuranceCount, color: 'bg-amber-500' },
                ].map((type) => {
                  const maxCount = Math.max(stats.regularCount, stats.insuranceCount, 1);
                  const widthPct = (type.count / maxCount) * 100;
                  return (
                    <div key={type.label}>
                      <div className="flex items-center justify-between mb-1.5">
                        <span className="text-sm font-medium text-[var(--text-primary)]">
                          {type.label}
                        </span>
                        <span className="text-sm font-mono text-[var(--text-secondary)]">
                          {type.count}
                        </span>
                      </div>
                      <div className="h-3 w-full rounded-full bg-[var(--bg-elevated)] overflow-hidden">
                        <div
                          className={`h-full rounded-full ${type.color} transition-all duration-500`}
                          style={{ width: `${widthPct}%` }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
              {/* Summary stats */}
              <div className="flex items-center justify-center gap-8">
                <div className="text-center">
                  <p className="text-3xl font-bold text-blue-400">{stats.regularCount}</p>
                  <p className="text-xs text-[var(--text-secondary)] mt-1">Regular</p>
                </div>
                <div className="w-px h-12 bg-[var(--border)]" />
                <div className="text-center">
                  <p className="text-3xl font-bold text-amber-400">{stats.insuranceCount}</p>
                  <p className="text-xs text-[var(--text-secondary)] mt-1">Insurance</p>
                </div>
                <div className="w-px h-12 bg-[var(--border)]" />
                <div className="text-center">
                  <p className="text-3xl font-bold text-[var(--text-primary)]">{stats.total}</p>
                  <p className="text-xs text-[var(--text-secondary)] mt-1">Total</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Filters + Search */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
        <div className="flex items-center gap-1 bg-[var(--bg-elevated)] rounded-lg p-1">
          {filterTabs.map((tab) => (
            <button
              key={tab.key}
              onClick={() => setFilter(tab.key)}
              className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
                filter === tab.key
                  ? 'bg-[var(--accent)] text-white'
                  : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
              }`}
            >
              {tab.label}
              {tab.count !== undefined && (
                <span className="ml-1 opacity-70">({tab.count})</span>
              )}
            </button>
          ))}
        </div>
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[var(--text-secondary)]" />
          <Input
            placeholder="Search estimate #, customer, company..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
      </div>

      {/* Recent Estimates Table */}
      <Card>
        <CardContent>
          <div className="flex items-center gap-2 mb-4">
            <FileText className="h-4 w-4 text-[var(--text-secondary)]" />
            <h3 className="text-[15px] font-semibold text-[var(--text-primary)]">
              Recent Estimates
            </h3>
            <span className="text-xs text-[var(--text-secondary)] ml-1">
              (Last 50)
            </span>
          </div>
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3, 4, 5, 6, 7, 8].map((i) => (
                <div key={i} className="flex items-center gap-4 py-3">
                  <div className="h-4 w-20 rounded skeleton-shimmer" />
                  <div className="h-4 w-28 rounded skeleton-shimmer" />
                  <div className="h-4 w-32 rounded skeleton-shimmer" />
                  <div className="h-5 w-16 rounded-full skeleton-shimmer" />
                  <div className="h-5 w-14 rounded-full skeleton-shimmer" />
                  <div className="h-4 w-20 rounded skeleton-shimmer ml-auto" />
                  <div className="h-4 w-20 rounded skeleton-shimmer" />
                </div>
              ))}
            </div>
          ) : filteredEstimates.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <FileText className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm">No estimates found</p>
              <p className="text-xs mt-1 opacity-60">
                Estimates will appear here as companies create them
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-[var(--border)]">
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Estimate #
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Company
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Customer
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Type
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Status
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Grand Total
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Created
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {filteredEstimates.map((e) => (
                    <tr
                      key={e.id}
                      className="border-b border-[var(--border)] last:border-0 hover:bg-[var(--bg-elevated)] transition-colors"
                    >
                      <td className="py-3 px-2">
                        <span className="text-sm font-mono font-medium text-[var(--accent)]">
                          {e.estimate_number || '--'}
                        </span>
                      </td>
                      <td className="py-3 px-2">
                        <span className="text-sm text-[var(--text-primary)]">
                          {e.companies?.name || '--'}
                        </span>
                      </td>
                      <td className="py-3 px-2">
                        <span className="text-sm text-[var(--text-primary)]">
                          {e.customer_name || '--'}
                        </span>
                      </td>
                      <td className="py-3 px-2">
                        <span
                          className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                            TYPE_COLORS[e.estimate_type] || 'bg-gray-500/10 text-gray-400'
                          }`}
                        >
                          {e.estimate_type || 'regular'}
                        </span>
                      </td>
                      <td className="py-3 px-2">
                        <span
                          className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                            STATUS_COLORS[e.status] || 'bg-gray-500/10 text-gray-400'
                          }`}
                        >
                          {e.status}
                        </span>
                      </td>
                      <td className="py-3 px-2 text-right">
                        <span className="text-sm font-mono text-[var(--text-primary)]">
                          {e.grand_total != null ? formatCurrency(e.grand_total) : '--'}
                        </span>
                      </td>
                      <td className="py-3 px-2">
                        <span className="text-xs text-[var(--text-secondary)]">
                          {formatDate(e.created_at)}
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

      {/* Code Database Health */}
      {loading ? (
        <Card>
          <CardContent>
            <div className="h-5 w-48 rounded skeleton-shimmer mb-6" />
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="space-y-2">
                  <div className="h-3 w-24 rounded skeleton-shimmer" />
                  <div className="h-7 w-16 rounded skeleton-shimmer" />
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      ) : codeHealth && (
        <Card>
          <CardContent>
            <div className="flex items-center gap-2 mb-5">
              <Database className="h-4 w-4 text-[var(--text-secondary)]" />
              <h3 className="text-[15px] font-semibold text-[var(--text-primary)]">
                Code Database Health
              </h3>
            </div>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-6">
              <div>
                <div className="flex items-center gap-1.5 mb-1">
                  <Hash className="h-3 w-3 text-[var(--text-secondary)]" />
                  <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider">
                    Total Items
                  </p>
                </div>
                <p className="text-2xl font-bold text-[var(--text-primary)]">
                  {codeHealth.totalItems.toLocaleString()}
                </p>
              </div>
              <div>
                <div className="flex items-center gap-1.5 mb-1">
                  <DollarSign className="h-3 w-3 text-[var(--text-secondary)]" />
                  <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider">
                    Priced (National)
                  </p>
                </div>
                <p className="text-2xl font-bold text-[var(--text-primary)]">
                  {codeHealth.pricedItems.toLocaleString()}
                </p>
              </div>
              <div>
                <div className="flex items-center gap-1.5 mb-1">
                  <ShieldCheck className="h-3 w-3 text-[var(--text-secondary)]" />
                  <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider">
                    Coverage
                  </p>
                </div>
                <p className={`text-2xl font-bold ${
                  codeHealth.coveragePct >= 80
                    ? 'text-emerald-400'
                    : codeHealth.coveragePct >= 50
                      ? 'text-amber-400'
                      : 'text-red-400'
                }`}>
                  {codeHealth.coveragePct}%
                </p>
                {/* Coverage bar */}
                <div className="h-1.5 w-full rounded-full bg-[var(--bg-elevated)] mt-2 overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all duration-500 ${
                      codeHealth.coveragePct >= 80
                        ? 'bg-emerald-500'
                        : codeHealth.coveragePct >= 50
                          ? 'bg-amber-500'
                          : 'bg-red-500'
                    }`}
                    style={{ width: `${codeHealth.coveragePct}%` }}
                  />
                </div>
              </div>
              <div>
                <div className="flex items-center gap-1.5 mb-1">
                  <BarChart3 className="h-3 w-3 text-[var(--text-secondary)]" />
                  <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider">
                    Unpriced
                  </p>
                </div>
                <p className="text-2xl font-bold text-[var(--text-secondary)]">
                  {(codeHealth.totalItems - codeHealth.pricedItems).toLocaleString()}
                </p>
              </div>
            </div>

            {/* Top 5 Most-Used Codes */}
            {codeHealth.topCodes.length > 0 && (
              <div className="border-t border-[var(--border)] pt-5">
                <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider mb-3">
                  Top 5 Most-Used Codes
                </p>
                <div className="space-y-2.5">
                  {codeHealth.topCodes.map((code, idx) => {
                    const maxUsage = codeHealth.topCodes[0]?.usage_count || 1;
                    const barPct = (code.usage_count / maxUsage) * 100;
                    return (
                      <div key={code.zafto_code} className="flex items-center gap-3">
                        <span className="text-xs font-mono text-[var(--text-secondary)] w-5 text-right">
                          {idx + 1}.
                        </span>
                        <span className="text-sm font-mono text-[var(--accent)] w-32 shrink-0">
                          {code.zafto_code}
                        </span>
                        <div className="flex-1 h-2 rounded-full bg-[var(--bg-elevated)] overflow-hidden">
                          <div
                            className="h-full rounded-full bg-[var(--accent)] transition-all duration-500"
                            style={{ width: `${barPct}%` }}
                          />
                        </div>
                        <span className="text-sm font-mono text-[var(--text-primary)] w-12 text-right">
                          {code.usage_count}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}
