'use client';

import { useState, useEffect, useCallback } from 'react';
import {
  Building2,
  TrendingUp,
  ClipboardList,
  AlertTriangle,
  DollarSign,
  Star,
  Loader2,
  RefreshCw,
} from 'lucide-react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

interface CompanyTpaStats {
  companyId: string;
  companyName: string;
  programCount: number;
  assignmentsReceived: number;
  assignmentsCompleted: number;
  slaViolations: number;
  totalRevenue: number;
  avgScore: number | null;
}

interface PlatformTpaOverview {
  totalCompanies: number;
  totalPrograms: number;
  totalAssignments: number;
  totalRevenue: number;
  avgSlaCompliance: number;
  companyStats: CompanyTpaStats[];
}

// ============================================================================
// PAGE
// ============================================================================

export default function OpsTpaPage() {
  const [overview, setOverview] = useState<PlatformTpaOverview | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();

      // Get all companies with TPA programs
      const { data: programs } = await supabase
        .from('tpa_programs')
        .select('id, company_id, name, companies(name)')
        .is('deleted_at', null);

      const programList = programs || [];
      const companyMap = new Map<string, { name: string; programIds: string[] }>();

      for (const p of programList) {
        const cid = p.company_id as string;
        const cname = (p.companies as Record<string, unknown>)?.name as string || 'Unknown';
        if (!companyMap.has(cid)) {
          companyMap.set(cid, { name: cname, programIds: [] });
        }
        companyMap.get(cid)!.programIds.push(p.id);
      }

      // Get assignments stats
      const { data: assignments } = await supabase
        .from('tpa_assignments')
        .select('id, company_id, status, sla_deadline')
        .is('deleted_at', null);

      const assignmentList = assignments || [];

      // Get financials
      const { data: financials } = await supabase
        .from('tpa_program_financials')
        .select('company_id, total_revenue, sla_violations_count, avg_scorecard_rating');

      const finList = financials || [];

      // Build per-company stats
      const companyStats: CompanyTpaStats[] = [];
      let totalRevenue = 0;
      let totalAssignments = 0;
      let slaCompliantCount = 0;

      for (const [companyId, info] of companyMap) {
        const companyAssignments = assignmentList.filter((a: Record<string, unknown>) => a.company_id === companyId);
        const received = companyAssignments.length;
        const completed = companyAssignments.filter((a: Record<string, unknown>) =>
          a.status === 'completed' || a.status === 'paid'
        ).length;

        const now = new Date();
        const violations = companyAssignments.filter((a: Record<string, unknown>) => {
          if (!a.sla_deadline) return false;
          return new Date(a.sla_deadline as string) < now && !['completed', 'paid'].includes(a.status as string);
        }).length;

        const companyFin = finList.filter((f: Record<string, unknown>) => f.company_id === companyId);
        const revenue = companyFin.reduce((s: number, f: Record<string, unknown>) => s + (Number(f.total_revenue) || 0), 0);
        const scores = companyFin
          .map((f: Record<string, unknown>) => f.avg_scorecard_rating)
          .filter((s: unknown): s is number => s != null)
          .map(Number);
        const avgScore = scores.length > 0 ? scores.reduce((a: number, b: number) => a + b, 0) / scores.length : null;

        totalRevenue += revenue;
        totalAssignments += received;
        slaCompliantCount += (received - violations);

        companyStats.push({
          companyId,
          companyName: info.name,
          programCount: info.programIds.length,
          assignmentsReceived: received,
          assignmentsCompleted: completed,
          slaViolations: violations,
          totalRevenue: revenue,
          avgScore,
        });
      }

      companyStats.sort((a, b) => b.totalRevenue - a.totalRevenue);

      setOverview({
        totalCompanies: companyMap.size,
        totalPrograms: programList.length,
        totalAssignments,
        totalRevenue,
        avgSlaCompliance: totalAssignments > 0 ? Math.round((slaCompliantCount / totalAssignments) * 100) : 100,
        companyStats,
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load TPA data');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const fmt = (n: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(n);

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-white flex items-center gap-2">
            <Building2 className="h-5 w-5 text-blue-400" />
            TPA Analytics
          </h1>
          <p className="text-sm text-zinc-400 mt-0.5">
            Platform-wide TPA program performance across all companies
          </p>
        </div>
        <button
          onClick={fetchData}
          className="flex items-center gap-1 px-3 py-1.5 text-sm border border-zinc-700 rounded hover:bg-zinc-800 text-zinc-300"
        >
          <RefreshCw className="h-4 w-4" />
          Refresh
        </button>
      </div>

      {loading && (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="h-6 w-6 animate-spin text-zinc-400" />
          <span className="ml-2 text-sm text-zinc-400">Loading...</span>
        </div>
      )}

      {error && (
        <div className="p-4 bg-red-500/10 border border-red-500/20 rounded">
          <p className="text-sm text-red-400">{error}</p>
        </div>
      )}

      {!loading && !error && overview && (
        <>
          {/* Summary */}
          <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
            {[
              { label: 'Companies', value: String(overview.totalCompanies), icon: Building2, color: 'text-blue-400' },
              { label: 'Programs', value: String(overview.totalPrograms), icon: ClipboardList, color: 'text-purple-400' },
              { label: 'Assignments', value: String(overview.totalAssignments), icon: TrendingUp, color: 'text-emerald-400' },
              { label: 'Revenue', value: fmt(overview.totalRevenue), icon: DollarSign, color: 'text-amber-400' },
              { label: 'SLA Compliance', value: `${overview.avgSlaCompliance}%`, icon: AlertTriangle, color: overview.avgSlaCompliance >= 90 ? 'text-emerald-400' : 'text-red-400' },
            ].map((card) => (
              <div key={card.label} className="bg-zinc-900 border border-zinc-800 rounded-lg p-3">
                <div className="flex items-center gap-1.5 mb-1">
                  <card.icon className={`h-3.5 w-3.5 ${card.color}`} />
                  <span className="text-[11px] text-zinc-400">{card.label}</span>
                </div>
                <p className="text-lg font-semibold text-white">{card.value}</p>
              </div>
            ))}
          </div>

          {/* Company Table */}
          <div className="bg-zinc-900 border border-zinc-800 rounded-lg overflow-hidden">
            <div className="px-4 py-3 border-b border-zinc-800">
              <h2 className="text-sm font-medium text-white">Company Breakdown</h2>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead>
                  <tr className="border-b border-zinc-800 text-zinc-400">
                    <th className="text-left px-4 py-2 font-medium">Company</th>
                    <th className="text-right px-4 py-2 font-medium">Programs</th>
                    <th className="text-right px-4 py-2 font-medium">Assignments</th>
                    <th className="text-right px-4 py-2 font-medium">Completed</th>
                    <th className="text-right px-4 py-2 font-medium">SLA Violations</th>
                    <th className="text-right px-4 py-2 font-medium">Revenue</th>
                    <th className="text-right px-4 py-2 font-medium">Avg Score</th>
                  </tr>
                </thead>
                <tbody>
                  {overview.companyStats.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="px-4 py-8 text-center text-zinc-500">
                        No companies with TPA programs yet
                      </td>
                    </tr>
                  ) : (
                    overview.companyStats.map((cs) => (
                      <tr key={cs.companyId} className="border-b border-zinc-800/50 hover:bg-zinc-800/30">
                        <td className="px-4 py-2 text-white font-medium">{cs.companyName}</td>
                        <td className="text-right px-4 py-2 text-zinc-300">{cs.programCount}</td>
                        <td className="text-right px-4 py-2 text-zinc-300">{cs.assignmentsReceived}</td>
                        <td className="text-right px-4 py-2 text-zinc-300">{cs.assignmentsCompleted}</td>
                        <td className={`text-right px-4 py-2 font-medium ${cs.slaViolations > 0 ? 'text-red-400' : 'text-emerald-400'}`}>
                          {cs.slaViolations}
                        </td>
                        <td className="text-right px-4 py-2 text-white">{fmt(cs.totalRevenue)}</td>
                        <td className="text-right px-4 py-2">
                          {cs.avgScore != null ? (
                            <span className="flex items-center justify-end gap-0.5">
                              <Star className="h-3 w-3 text-amber-400 fill-amber-400" />
                              <span className="text-white">{cs.avgScore.toFixed(1)}</span>
                            </span>
                          ) : (
                            <span className="text-zinc-500">--</span>
                          )}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
