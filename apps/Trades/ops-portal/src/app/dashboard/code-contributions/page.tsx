'use client';

import { useEffect, useState, useCallback } from 'react';
import { Code2, CheckCircle2, XCircle, ArrowUpCircle, RefreshCw, Search, Filter } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { getSupabase } from '@/lib/supabase';
import { formatDate } from '@/lib/utils';

interface ContributionStats {
  total: number;
  pending: number;
  verified: number;
  promoted: number;
  ready_to_promote: number;
  threshold: number;
}

interface Contribution {
  id: string;
  company_id: string;
  user_id: string;
  industry_code: string;
  industry_selector: string;
  description: string;
  unit_code: string | null;
  action_type: string | null;
  trade: string | null;
  verified: boolean;
  verification_count: number;
  promoted_item_id: string | null;
  created_at: string;
}

type StatusFilter = 'all' | 'pending' | 'verified' | 'promoted' | 'ready';

export default function CodeContributionsPage() {
  const [stats, setStats] = useState<ContributionStats | null>(null);
  const [contributions, setContributions] = useState<Contribution[]>([]);
  const [loading, setLoading] = useState(true);
  const [acting, setActing] = useState<string | null>(null);
  const [promoting, setPromoting] = useState(false);
  const [filter, setFilter] = useState<StatusFilter>('all');
  const [search, setSearch] = useState('');

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) return;

      const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
      const url = `${baseUrl}/functions/v1/code-verify?status=${filter}&page_size=100`;
      const res = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${session.access_token}`,
          'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
        },
      });
      const json = await res.json();
      if (json.stats) setStats(json.stats);
      if (json.contributions) setContributions(json.contributions);
    } catch {
      // silently fail
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const callAction = async (action: string, contributionId?: string) => {
    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return;

    const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
    const body: Record<string, string> = { action };
    if (contributionId) body.contribution_id = contributionId;

    await fetch(`${baseUrl}/functions/v1/code-verify`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
        'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });
  };

  const handleVerify = async (id: string) => {
    setActing(id);
    await callAction('verify', id);
    await fetchData();
    setActing(null);
  };

  const handleReject = async (id: string) => {
    setActing(id);
    await callAction('reject', id);
    await fetchData();
    setActing(null);
  };

  const handlePromoteOne = async (id: string) => {
    setActing(id);
    await callAction('promote-one', id);
    await fetchData();
    setActing(null);
  };

  const handlePromoteAll = async () => {
    setPromoting(true);
    await callAction('promote-all');
    await fetchData();
    setPromoting(false);
  };

  const filtered = contributions.filter((c) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      c.industry_code.toLowerCase().includes(q) ||
      c.industry_selector.toLowerCase().includes(q) ||
      c.description.toLowerCase().includes(q) ||
      (c.trade || '').toLowerCase().includes(q)
    );
  });

  const filterTabs: { key: StatusFilter; label: string; count?: number }[] = [
    { key: 'all', label: 'All', count: stats?.total },
    { key: 'pending', label: 'Pending', count: stats?.pending },
    { key: 'ready', label: 'Ready', count: stats?.ready_to_promote },
    { key: 'verified', label: 'Verified', count: stats?.verified },
    { key: 'promoted', label: 'Promoted', count: stats?.promoted },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Code Contributions
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            Crowdsource verification pipeline — ESX imports feed the ZAFTO code database
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={fetchData}
            disabled={loading}
            className="flex items-center gap-2 px-3 py-2 text-sm rounded-lg border border-[var(--border)] text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)] transition-colors"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </button>
          {(stats?.ready_to_promote || 0) > 0 && (
            <button
              onClick={handlePromoteAll}
              disabled={promoting}
              className="flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-lg bg-[var(--accent)] text-white hover:opacity-90 transition-opacity"
            >
              <ArrowUpCircle className="h-4 w-4" />
              {promoting ? 'Promoting...' : `Promote All (${stats?.ready_to_promote})`}
            </button>
          )}
        </div>
      </div>

      {/* Stats */}
      {stats && (
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
          {[
            { label: 'Total', value: stats.total, color: 'text-[var(--text-primary)]' },
            { label: 'Pending', value: stats.pending, color: 'text-yellow-500' },
            { label: `Ready (${stats.threshold}+)`, value: stats.ready_to_promote, color: 'text-blue-500' },
            { label: 'Verified', value: stats.verified, color: 'text-green-500' },
            { label: 'Promoted', value: stats.promoted, color: 'text-[var(--accent)]' },
          ].map((stat) => (
            <Card key={stat.label}>
              <CardContent className="py-4">
                <p className="text-xs text-[var(--text-secondary)] uppercase tracking-wider">{stat.label}</p>
                <p className={`text-2xl font-bold mt-1 ${stat.color}`}>{stat.value}</p>
              </CardContent>
            </Card>
          ))}
        </div>
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
            placeholder="Search codes, descriptions..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
      </div>

      {/* Table */}
      <Card>
        <CardContent>
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3, 4, 5].map((i) => (
                <div key={i} className="flex items-center gap-4 py-3">
                  <div className="h-4 w-24 rounded skeleton-shimmer" />
                  <div className="h-4 w-16 rounded skeleton-shimmer" />
                  <div className="h-4 w-48 rounded skeleton-shimmer" />
                  <div className="h-5 w-12 rounded-full skeleton-shimmer" />
                  <div className="h-4 w-20 rounded skeleton-shimmer ml-auto" />
                </div>
              ))}
            </div>
          ) : filtered.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <Code2 className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm">No contributions found</p>
              <p className="text-xs mt-1 opacity-60">
                Contributions are created automatically when ESX files are imported
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-[var(--border)]">
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Code
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Selector
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Description
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Trade
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Unit
                    </th>
                    <th className="text-center py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Verifications
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Status
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Created
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((c) => {
                    const isReady = c.verification_count >= (stats?.threshold || 3);
                    const isPromoted = !!c.promoted_item_id;
                    const isVerified = c.verified;
                    const isActing = acting === c.id;

                    return (
                      <tr
                        key={c.id}
                        className="border-b border-[var(--border)] last:border-0 hover:bg-[var(--bg-elevated)] transition-colors"
                      >
                        <td className="py-3 px-2">
                          <span className="text-sm font-mono font-medium text-[var(--text-primary)]">
                            {c.industry_code}
                          </span>
                        </td>
                        <td className="py-3 px-2">
                          <span className="text-sm font-mono text-[var(--text-secondary)]">
                            {c.industry_selector}
                          </span>
                        </td>
                        <td className="py-3 px-2 max-w-xs">
                          <span className="text-sm text-[var(--text-primary)] line-clamp-2">
                            {c.description}
                          </span>
                        </td>
                        <td className="py-3 px-2">
                          <span className="text-xs text-[var(--text-secondary)] uppercase">
                            {c.trade || '--'}
                          </span>
                        </td>
                        <td className="py-3 px-2">
                          <span className="text-xs text-[var(--text-secondary)]">
                            {c.unit_code || 'EA'}
                          </span>
                        </td>
                        <td className="py-3 px-2 text-center">
                          <span className={`inline-flex items-center justify-center w-8 h-8 rounded-full text-sm font-bold ${
                            isReady
                              ? 'bg-green-500/10 text-green-500'
                              : c.verification_count >= 2
                                ? 'bg-yellow-500/10 text-yellow-500'
                                : 'bg-[var(--bg-elevated)] text-[var(--text-secondary)]'
                          }`}>
                            {c.verification_count}
                          </span>
                        </td>
                        <td className="py-3 px-2">
                          {isPromoted ? (
                            <span className="inline-flex items-center gap-1 text-xs font-medium text-[var(--accent)]">
                              <ArrowUpCircle className="h-3 w-3" /> Promoted
                            </span>
                          ) : isVerified ? (
                            <span className="inline-flex items-center gap-1 text-xs font-medium text-green-500">
                              <CheckCircle2 className="h-3 w-3" /> Verified
                            </span>
                          ) : isReady ? (
                            <span className="inline-flex items-center gap-1 text-xs font-medium text-blue-500">
                              <ArrowUpCircle className="h-3 w-3" /> Ready
                            </span>
                          ) : (
                            <span className="text-xs text-[var(--text-secondary)]">Pending</span>
                          )}
                        </td>
                        <td className="py-3 px-2">
                          <span className="text-xs text-[var(--text-secondary)]">
                            {formatDate(c.created_at)}
                          </span>
                        </td>
                        <td className="py-3 px-2 text-right">
                          {!isPromoted && (
                            <div className="flex items-center justify-end gap-1">
                              {!isVerified && (
                                <button
                                  onClick={() => handleVerify(c.id)}
                                  disabled={isActing}
                                  title="Verify"
                                  className="p-1.5 rounded-md text-green-500 hover:bg-green-500/10 transition-colors disabled:opacity-50"
                                >
                                  <CheckCircle2 className="h-4 w-4" />
                                </button>
                              )}
                              {(isVerified || isReady) && (
                                <button
                                  onClick={() => handlePromoteOne(c.id)}
                                  disabled={isActing}
                                  title="Promote to estimate items"
                                  className="p-1.5 rounded-md text-[var(--accent)] hover:bg-[var(--accent)]/10 transition-colors disabled:opacity-50"
                                >
                                  <ArrowUpCircle className="h-4 w-4" />
                                </button>
                              )}
                              <button
                                onClick={() => handleReject(c.id)}
                                disabled={isActing}
                                title="Reject"
                                className="p-1.5 rounded-md text-red-500 hover:bg-red-500/10 transition-colors disabled:opacity-50"
                              >
                                <XCircle className="h-4 w-4" />
                              </button>
                            </div>
                          )}
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
