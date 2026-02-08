'use client';

import { useEffect, useState, useCallback } from 'react';
import {
  Briefcase,
  UserPlus,
  Calendar,
  CheckCircle2,
  BarChart3,
  Inbox,
  RefreshCw,
  Building2,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { getSupabase } from '@/lib/supabase';
import { formatNumber } from '@/lib/utils';

interface CompanyHiring {
  company_id: string;
  company_name: string;
  postings: number;
  applicants: number;
  interviews: number;
}

interface SourceBreakdown {
  source: string;
  count: number;
}

interface HiringData {
  activePostings: number;
  totalApplicants: number;
  interviewsThisWeek: number;
  hiredThisMonth: number;
  hiringByCompany: CompanyHiring[];
  applicantSources: SourceBreakdown[];
}

const emptyData: HiringData = {
  activePostings: 0,
  totalApplicants: 0,
  interviewsThisWeek: 0,
  hiredThisMonth: 0,
  hiringByCompany: [],
  applicantSources: [],
};

function useHiringAnalytics() {
  const [data, setData] = useState<HiringData>(emptyData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();
      const now = new Date();
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
      const weekStart = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();

      const [
        activePostingsRes,
        totalApplicantsRes,
        interviewsWeekRes,
        hiredMonthRes,
        postingsByCompanyRes,
        applicantsByCompanyRes,
        interviewsByCompanyRes,
        applicantSourcesRes,
      ] = await Promise.all([
        // Active postings
        supabase
          .from('job_postings')
          .select('id', { count: 'exact', head: true })
          .eq('status', 'active'),
        // Total applicants
        supabase
          .from('applicants')
          .select('id', { count: 'exact', head: true }),
        // Interviews this week
        supabase
          .from('interview_schedules')
          .select('id', { count: 'exact', head: true })
          .gte('scheduled_at', weekStart),
        // Hired this month
        supabase
          .from('applicants')
          .select('id', { count: 'exact', head: true })
          .eq('status', 'hired')
          .gte('updated_at', monthStart),
        // Postings by company
        supabase
          .from('job_postings')
          .select('company_id')
          .eq('status', 'active'),
        // Applicants by company
        supabase
          .from('applicants')
          .select('company_id'),
        // Interviews by company
        supabase
          .from('interview_schedules')
          .select('company_id'),
        // Applicant sources
        supabase
          .from('applicants')
          .select('source'),
      ]);

      // Aggregate by company
      const companyIds = new Set<string>();
      const postingsCount: Record<string, number> = {};
      const applicantsCount: Record<string, number> = {};
      const interviewsCount: Record<string, number> = {};

      if (postingsByCompanyRes.data) {
        for (const p of postingsByCompanyRes.data) {
          const row = p as { company_id: string };
          companyIds.add(row.company_id);
          postingsCount[row.company_id] = (postingsCount[row.company_id] || 0) + 1;
        }
      }

      if (applicantsByCompanyRes.data) {
        for (const a of applicantsByCompanyRes.data) {
          const row = a as { company_id: string };
          companyIds.add(row.company_id);
          applicantsCount[row.company_id] = (applicantsCount[row.company_id] || 0) + 1;
        }
      }

      if (interviewsByCompanyRes.data) {
        for (const i of interviewsByCompanyRes.data) {
          const row = i as { company_id: string };
          companyIds.add(row.company_id);
          interviewsCount[row.company_id] = (interviewsCount[row.company_id] || 0) + 1;
        }
      }

      // Source distribution
      const sourceCounts: Record<string, number> = {};
      if (applicantSourcesRes.data) {
        for (const a of applicantSourcesRes.data) {
          const row = a as { source: string };
          const src = row.source || 'unknown';
          sourceCounts[src] = (sourceCounts[src] || 0) + 1;
        }
      }
      const applicantSources: SourceBreakdown[] = Object.entries(sourceCounts)
        .map(([source, count]) => ({ source, count }))
        .sort((a, b) => b.count - a.count);

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

      // Build hiring by company
      const hiringByCompany: CompanyHiring[] = Array.from(companyIds)
        .map((cid) => ({
          company_id: cid,
          company_name: companyNames[cid] || 'Unknown',
          postings: postingsCount[cid] || 0,
          applicants: applicantsCount[cid] || 0,
          interviews: interviewsCount[cid] || 0,
        }))
        .sort((a, b) => b.applicants - a.applicants)
        .slice(0, 15);

      setData({
        activePostings: activePostingsRes.count ?? 0,
        totalApplicants: totalApplicantsRes.count ?? 0,
        interviewsThisWeek: interviewsWeekRes.count ?? 0,
        hiredThisMonth: hiredMonthRes.count ?? 0,
        hiringByCompany,
        applicantSources,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch hiring analytics');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}

function formatSourceLabel(source: string): string {
  return source
    .split('_')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

export default function HiringAnalyticsPage() {
  const { data, loading, error, refetch } = useHiringAnalytics();

  const metrics = [
    {
      label: 'Active Postings',
      value: formatNumber(data.activePostings),
      icon: <Briefcase className="h-5 w-5" />,
      subtext: 'Platform-wide',
    },
    {
      label: 'Total Applicants',
      value: formatNumber(data.totalApplicants),
      icon: <UserPlus className="h-5 w-5" />,
      subtext: 'All companies',
    },
    {
      label: 'Interviews This Week',
      value: formatNumber(data.interviewsThisWeek),
      icon: <Calendar className="h-5 w-5" />,
      subtext: 'Last 7 days',
    },
    {
      label: 'Hired This Month',
      value: formatNumber(data.hiredThisMonth),
      icon: <CheckCircle2 className="h-5 w-5" />,
      subtext: 'Current month',
    },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Hiring Analytics
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            Cross-company hiring pipeline and recruitment metrics
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

      {/* Applicant Source Distribution + Hiring Pipeline side by side */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Applicant Source Distribution */}
        <Card>
          <CardHeader>
            <CardTitle>Applicant Sources</CardTitle>
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
            ) : data.applicantSources.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-16 text-[var(--text-secondary)]">
                <BarChart3 className="h-10 w-10 mb-3 opacity-30" />
                <p className="text-sm font-medium">No applicant source data yet</p>
                <p className="text-xs mt-1 opacity-70">
                  Source distribution will appear when applicants are tracked
                </p>
              </div>
            ) : (
              <div className="space-y-2">
                {data.applicantSources.map((item) => {
                  const total = data.totalApplicants || 1;
                  const pct = ((item.count / total) * 100).toFixed(1);
                  return (
                    <div
                      key={item.source}
                      className="flex items-center justify-between py-2 border-b border-[var(--border)] last:border-0"
                    >
                      <div className="flex items-center gap-3">
                        <Badge variant="default">
                          {formatSourceLabel(item.source)}
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

        {/* Pipeline Summary */}
        <Card>
          <CardHeader>
            <CardTitle>Pipeline Summary</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="space-y-3">
                {[1, 2, 3].map((i) => (
                  <div key={i} className="flex items-center justify-between py-4">
                    <div className="h-4 w-32 rounded skeleton-shimmer" />
                    <div className="h-6 w-16 rounded skeleton-shimmer" />
                  </div>
                ))}
              </div>
            ) : (
              <div className="space-y-4">
                {[
                  { label: 'Active Postings', value: data.activePostings, color: 'bg-blue-500' },
                  { label: 'Total Applicants', value: data.totalApplicants, color: 'bg-amber-500' },
                  { label: 'Interviews Scheduled', value: data.interviewsThisWeek, color: 'bg-purple-500' },
                  { label: 'Hired', value: data.hiredThisMonth, color: 'bg-emerald-500' },
                ].map((step) => (
                  <div
                    key={step.label}
                    className="flex items-center justify-between py-3 border-b border-[var(--border)] last:border-0"
                  >
                    <div className="flex items-center gap-3">
                      <div className={`w-3 h-3 rounded-full ${step.color}`} />
                      <span className="text-sm text-[var(--text-primary)]">
                        {step.label}
                      </span>
                    </div>
                    <span className="text-lg font-bold text-[var(--text-primary)]">
                      {formatNumber(step.value)}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Hiring Pipeline by Company */}
      <Card>
        <CardHeader>
          <CardTitle>Hiring Pipeline by Company</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3, 4, 5].map((i) => (
                <div key={i} className="flex items-center gap-4 py-3">
                  <div className="h-4 w-40 rounded skeleton-shimmer" />
                  <div className="h-4 w-16 rounded skeleton-shimmer" />
                  <div className="h-4 w-16 rounded skeleton-shimmer" />
                  <div className="h-4 w-16 rounded skeleton-shimmer ml-auto" />
                </div>
              ))}
            </div>
          ) : data.hiringByCompany.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <Inbox className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm font-medium">No hiring data yet</p>
              <p className="text-xs mt-1 opacity-60">
                Hiring pipeline will appear when job postings are created
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
                      Postings
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Applicants
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Interviews
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {data.hiringByCompany.map((company) => (
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
                          {formatNumber(company.postings)}
                        </span>
                      </td>
                      <td className="py-3 px-2 text-right">
                        <span className="text-sm text-[var(--text-secondary)]">
                          {formatNumber(company.applicants)}
                        </span>
                      </td>
                      <td className="py-3 px-2 text-right">
                        <span className="text-sm font-semibold text-[var(--text-primary)]">
                          {formatNumber(company.interviews)}
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
