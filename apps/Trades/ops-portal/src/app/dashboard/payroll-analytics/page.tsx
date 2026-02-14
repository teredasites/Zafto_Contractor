'use client';

import { useEffect, useState, useCallback } from 'react';
import {
  DollarSign,
  Building2,
  FileText,
  Users,
  BarChart3,
  Inbox,
  RefreshCw,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { getSupabase } from '@/lib/supabase';
import { formatNumber, formatCurrency, formatDate } from '@/lib/utils';

interface PayrollData {
  totalPayrollProcessed: number;
  avgPayrollPerCompany: number;
  companiesUsingPayroll: number;
  stubsThisMonth: number;
  recentPayPeriods: {
    id: string;
    company_id: string;
    company_name: string;
    period_start: string;
    period_end: string;
    status: string;
    total_amount: number;
  }[];
}

const emptyData: PayrollData = {
  totalPayrollProcessed: 0,
  avgPayrollPerCompany: 0,
  companiesUsingPayroll: 0,
  stubsThisMonth: 0,
  recentPayPeriods: [],
};

function usePayrollAnalytics() {
  const [data, setData] = useState<PayrollData>(emptyData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();
      const now = new Date();
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

      // Run queries in parallel
      const [
        payPeriodsRes,
        stubsMonthRes,
        allStubsRes,
      ] = await Promise.all([
        // All pay periods
        supabase
          .from('pay_periods')
          .select('id, company_id, period_start, period_end, status, total_amount')
          .order('period_end', { ascending: false })
          .limit(100),
        // Stubs this month
        supabase
          .from('pay_stubs')
          .select('id', { count: 'exact', head: true })
          .gte('created_at', monthStart),
        // All stubs for total amount
        supabase
          .from('pay_stubs')
          .select('net_pay, company_id'),
      ]);

      // Calculate totals
      let totalPayroll = 0;
      const companyPayroll: Record<string, number> = {};

      if (allStubsRes.data) {
        for (const stub of allStubsRes.data) {
          const row = stub as { net_pay: number; company_id: string };
          totalPayroll += row.net_pay || 0;
          companyPayroll[row.company_id] = (companyPayroll[row.company_id] || 0) + (row.net_pay || 0);
        }
      }

      const companyIds = new Set<string>();
      if (payPeriodsRes.data) {
        for (const pp of payPeriodsRes.data) {
          const row = pp as { company_id: string };
          companyIds.add(row.company_id);
        }
      }
      // Also add stub company IDs
      Object.keys(companyPayroll).forEach((cid) => companyIds.add(cid));

      const companiesUsingPayroll = companyIds.size;
      const avgPayrollPerCompany = companiesUsingPayroll > 0 ? totalPayroll / companiesUsingPayroll : 0;

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

      // Build recent pay periods with company names
      const recentPayPeriods = (payPeriodsRes.data || []).slice(0, 20).map((pp) => {
        const row = pp as {
          id: string;
          company_id: string;
          period_start: string;
          period_end: string;
          status: string;
          total_amount: number;
        };
        return {
          ...row,
          company_name: companyNames[row.company_id] || 'Unknown',
        };
      });

      setData({
        totalPayrollProcessed: totalPayroll,
        avgPayrollPerCompany,
        companiesUsingPayroll,
        stubsThisMonth: stubsMonthRes.count ?? 0,
        recentPayPeriods,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch payroll analytics');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}

const statusVariantMap: Record<string, string> = {
  draft: 'text-[var(--text-secondary)]',
  processing: 'text-blue-500',
  completed: 'text-emerald-500',
  failed: 'text-red-500',
};

export default function PayrollAnalyticsPage() {
  const { data, loading, error, refetch } = usePayrollAnalytics();

  const metrics = [
    {
      label: 'Total Payroll Processed',
      value: formatCurrency(data.totalPayrollProcessed),
      icon: <DollarSign className="h-5 w-5" />,
      subtext: 'All-time across all companies',
    },
    {
      label: 'Avg per Company',
      value: formatCurrency(data.avgPayrollPerCompany),
      icon: <Building2 className="h-5 w-5" />,
      subtext: 'Average payroll per company',
    },
    {
      label: 'Companies Using Payroll',
      value: formatNumber(data.companiesUsingPayroll),
      icon: <Users className="h-5 w-5" />,
      subtext: 'Active payroll users',
    },
    {
      label: 'Stubs This Month',
      value: formatNumber(data.stubsThisMonth),
      icon: <FileText className="h-5 w-5" />,
      subtext: 'Pay stubs generated',
    },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Payroll Analytics
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            Cross-company payroll processing and distribution metrics
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

      {/* Chart Placeholder */}
      <Card>
        <CardHeader>
          <CardTitle>Payroll Volume Over Time</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-16 text-[var(--text-secondary)]">
            <BarChart3 className="h-10 w-10 mb-3 opacity-30" />
            <p className="text-sm font-medium">No payroll data yet</p>
            <p className="text-xs mt-1 opacity-70">
              Payroll volume trends will be visualized here once data is available
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Recent Pay Periods */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Pay Periods</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3, 4, 5].map((i) => (
                <div key={i} className="flex items-center gap-4 py-3">
                  <div className="h-4 w-40 rounded skeleton-shimmer" />
                  <div className="h-4 w-24 rounded skeleton-shimmer" />
                  <div className="h-4 w-20 rounded skeleton-shimmer" />
                  <div className="h-4 w-20 rounded skeleton-shimmer ml-auto" />
                </div>
              ))}
            </div>
          ) : data.recentPayPeriods.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <Inbox className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm font-medium">No pay period data yet</p>
              <p className="text-xs mt-1 opacity-60">
                Pay periods will appear when payroll processing begins
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
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Period
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Status
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Total
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {data.recentPayPeriods.map((pp) => (
                    <tr
                      key={pp.id}
                      className="border-b border-[var(--border)] last:border-0 hover:bg-[var(--bg-elevated)] transition-colors"
                    >
                      <td className="py-3 px-2">
                        <div className="flex items-center gap-2">
                          <Building2 className="h-4 w-4 text-[var(--text-secondary)]" />
                          <span className="text-sm font-medium text-[var(--text-primary)]">
                            {pp.company_name}
                          </span>
                        </div>
                      </td>
                      <td className="py-3 px-2">
                        <span className="text-sm text-[var(--text-secondary)]">
                          {formatDate(pp.period_start)} - {formatDate(pp.period_end)}
                        </span>
                      </td>
                      <td className="py-3 px-2">
                        <span className={`text-sm font-medium capitalize ${statusVariantMap[pp.status] || 'text-[var(--text-secondary)]'}`}>
                          {pp.status}
                        </span>
                      </td>
                      <td className="py-3 px-2 text-right">
                        <span className="text-sm font-semibold text-[var(--text-primary)]">
                          {formatCurrency(pp.total_amount || 0)}
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
