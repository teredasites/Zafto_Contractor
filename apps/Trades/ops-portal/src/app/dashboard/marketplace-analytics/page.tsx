'use client';

import { useEffect, useState, useCallback } from 'react';
import {
  ShoppingBag,
  Gavel,
  TrendingUp,
  UserCheck,
  BarChart3,
  Inbox,
  RefreshCw,
  Building2,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { getSupabase } from '@/lib/supabase';
import { formatNumber } from '@/lib/utils';

interface CompanyMarketplace {
  company_id: string;
  company_name: string;
  leads: number;
  bids: number;
}

interface FunnelStep {
  label: string;
  count: number;
  color: string;
}

interface MarketplaceData {
  openLeads: number;
  totalBids: number;
  avgBidsPerLead: number;
  contractorProfiles: number;
  marketplaceByCompany: CompanyMarketplace[];
  funnel: FunnelStep[];
}

const emptyData: MarketplaceData = {
  openLeads: 0,
  totalBids: 0,
  avgBidsPerLead: 0,
  contractorProfiles: 0,
  marketplaceByCompany: [],
  funnel: [],
};

function useMarketplaceAnalytics() {
  const [data, setData] = useState<MarketplaceData>(emptyData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();

      const [
        openLeadsRes,
        totalBidsRes,
        profilesRes,
        allLeadsRes,
        leadsByCompanyRes,
        bidsByCompanyRes,
        wonLeadsRes,
      ] = await Promise.all([
        // Open leads
        supabase
          .from('marketplace_leads')
          .select('id', { count: 'exact', head: true })
          .eq('status', 'open'),
        // Total bids
        supabase
          .from('marketplace_bids')
          .select('id', { count: 'exact', head: true }),
        // Contractor profiles
        supabase
          .from('contractor_profiles')
          .select('id', { count: 'exact', head: true }),
        // All leads for funnel calculation
        supabase
          .from('marketplace_leads')
          .select('id, status'),
        // Leads by company
        supabase
          .from('marketplace_leads')
          .select('company_id'),
        // Bids by company
        supabase
          .from('marketplace_bids')
          .select('company_id'),
        // Won/accepted leads for funnel
        supabase
          .from('marketplace_leads')
          .select('id', { count: 'exact', head: true })
          .in('status', ['won', 'accepted', 'completed']),
      ]);

      // Calculate avg bids per lead
      const totalLeads = allLeadsRes.data?.length ?? 0;
      const totalBids = totalBidsRes.count ?? 0;
      const avgBidsPerLead = totalLeads > 0 ? Math.round((totalBids / totalLeads) * 10) / 10 : 0;

      // Aggregate by company
      const companyIds = new Set<string>();
      const leadsCountByCompany: Record<string, number> = {};
      const bidsCountByCompany: Record<string, number> = {};

      if (leadsByCompanyRes.data) {
        for (const l of leadsByCompanyRes.data) {
          const row = l as { company_id: string };
          companyIds.add(row.company_id);
          leadsCountByCompany[row.company_id] = (leadsCountByCompany[row.company_id] || 0) + 1;
        }
      }

      if (bidsByCompanyRes.data) {
        for (const b of bidsByCompanyRes.data) {
          const row = b as { company_id: string };
          companyIds.add(row.company_id);
          bidsCountByCompany[row.company_id] = (bidsCountByCompany[row.company_id] || 0) + 1;
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

      // Build marketplace by company
      const marketplaceByCompany: CompanyMarketplace[] = Array.from(companyIds)
        .map((cid) => ({
          company_id: cid,
          company_name: companyNames[cid] || 'Unknown',
          leads: leadsCountByCompany[cid] || 0,
          bids: bidsCountByCompany[cid] || 0,
        }))
        .sort((a, b) => b.leads - a.leads)
        .slice(0, 15);

      // Build lead conversion funnel
      const wonCount = wonLeadsRes.count ?? 0;
      const biddedLeads = new Set<string>();
      // We need to count unique leads that received bids - approximate with total leads that have bids
      const leadsWithBids = Math.min(totalBids > 0 ? Math.ceil(totalLeads * 0.7) : 0, totalLeads);

      const funnel: FunnelStep[] = [
        { label: 'Total Leads', count: totalLeads, color: 'bg-blue-500' },
        { label: 'Open Leads', count: openLeadsRes.count ?? 0, color: 'bg-amber-500' },
        { label: 'Bids Received', count: totalBids, color: 'bg-purple-500' },
        { label: 'Won / Completed', count: wonCount, color: 'bg-emerald-500' },
      ];

      setData({
        openLeads: openLeadsRes.count ?? 0,
        totalBids,
        avgBidsPerLead,
        contractorProfiles: profilesRes.count ?? 0,
        marketplaceByCompany,
        funnel,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch marketplace analytics');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}

export default function MarketplaceAnalyticsPage() {
  const { data, loading, error, refetch } = useMarketplaceAnalytics();

  const metrics = [
    {
      label: 'Open Leads',
      value: formatNumber(data.openLeads),
      icon: <ShoppingBag className="h-5 w-5" />,
      subtext: 'Currently open',
    },
    {
      label: 'Total Bids',
      value: formatNumber(data.totalBids),
      icon: <Gavel className="h-5 w-5" />,
      subtext: 'All companies',
    },
    {
      label: 'Avg Bids / Lead',
      value: data.avgBidsPerLead > 0 ? data.avgBidsPerLead.toFixed(1) : '--',
      icon: <TrendingUp className="h-5 w-5" />,
      subtext: 'Competition density',
    },
    {
      label: 'Contractor Profiles',
      value: formatNumber(data.contractorProfiles),
      icon: <UserCheck className="h-5 w-5" />,
      subtext: 'Registered profiles',
    },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Marketplace Analytics
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            Cross-company marketplace leads, bids, and contractor activity
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

      {/* Lead Conversion Funnel */}
      <Card>
        <CardHeader>
          <CardTitle>Lead Conversion Funnel</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-3">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex items-center justify-between py-4">
                  <div className="h-4 w-32 rounded skeleton-shimmer" />
                  <div className="h-6 w-16 rounded skeleton-shimmer" />
                </div>
              ))}
            </div>
          ) : data.funnel.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-[var(--text-secondary)]">
              <BarChart3 className="h-10 w-10 mb-3 opacity-30" />
              <p className="text-sm font-medium">No funnel data yet</p>
              <p className="text-xs mt-1 opacity-70">
                Conversion funnel will appear when marketplace leads are created
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {data.funnel.map((step, idx) => {
                const maxCount = data.funnel[0]?.count || 1;
                const widthPct = Math.max((step.count / maxCount) * 100, 8);
                return (
                  <div key={step.label} className="space-y-1">
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-[var(--text-primary)]">
                        {step.label}
                      </span>
                      <span className="text-sm font-bold text-[var(--text-primary)]">
                        {formatNumber(step.count)}
                      </span>
                    </div>
                    <div className="w-full bg-[var(--bg-elevated)] rounded-full h-3 overflow-hidden">
                      <div
                        className={`h-full rounded-full transition-all ${step.color}`}
                        style={{ width: `${widthPct}%` }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Marketplace Activity by Company */}
      <Card>
        <CardHeader>
          <CardTitle>Marketplace Activity by Company</CardTitle>
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
          ) : data.marketplaceByCompany.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <Inbox className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm font-medium">No marketplace data yet</p>
              <p className="text-xs mt-1 opacity-60">
                Marketplace activity will appear when leads and bids are created
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
                      Leads
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Bids
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Bid Rate
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {data.marketplaceByCompany.map((company) => {
                    const bidRate = company.leads > 0
                      ? Math.round((company.bids / company.leads) * 100)
                      : 0;
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
                            {formatNumber(company.leads)}
                          </span>
                        </td>
                        <td className="py-3 px-2 text-right">
                          <span className="text-sm text-[var(--text-secondary)]">
                            {formatNumber(company.bids)}
                          </span>
                        </td>
                        <td className="py-3 px-2 text-right">
                          <span className="text-sm font-semibold text-[var(--text-primary)]">
                            {bidRate}%
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
