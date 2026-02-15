'use client';

import { useState, useEffect, useCallback } from 'react';
import {
  ClipboardCheck,
  TrendingUp,
  AlertTriangle,
  Users,
  BarChart3,
  RefreshCw,
  CheckCircle,
  XCircle,
  Clock,
  Repeat,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { getSupabase } from '@/lib/supabase';
import { formatNumber } from '@/lib/utils';

interface InspectorMetrics {
  totalInspections: number;
  completedInspections: number;
  passRate: number;
  avgScore: number;
  totalDeficiencies: number;
  reinspectionRate: number;
  companiesUsingInspections: number;
  topDeficiencyTypes: Array<{ type: string; count: number }>;
  inspectionsByType: Array<{ type: string; count: number }>;
  recentActivity: Array<{ companyName: string; type: string; status: string; date: string }>;
}

function useInspectorMetrics() {
  const [data, setData] = useState<InspectorMetrics>({
    totalInspections: 0,
    completedInspections: 0,
    passRate: 0,
    avgScore: 0,
    totalDeficiencies: 0,
    reinspectionRate: 0,
    companiesUsingInspections: 0,
    topDeficiencyTypes: [],
    inspectionsByType: [],
    recentActivity: [],
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Fetch aggregate inspection data
      const [inspectionsRes, deficienciesRes] = await Promise.all([
        supabase
          .from('pm_inspections')
          .select('id, company_id, inspection_type, status, score, scheduled_date, completed_date, parent_inspection_id')
          .order('created_at', { ascending: false })
          .limit(500),
        supabase
          .from('inspection_deficiencies')
          .select('id, severity, status')
          .limit(500),
      ]);

      const inspections = inspectionsRes.data || [];
      const deficiencies = deficienciesRes.data || [];

      const completed = inspections.filter((i: Record<string, unknown>) => i.status === 'completed');
      const scores = completed.filter((i: Record<string, unknown>) => typeof i.score === 'number').map((i: Record<string, unknown>) => i.score as number);
      const avgScore = scores.length > 0 ? scores.reduce((a: number, b: number) => a + b, 0) / scores.length : 0;
      const passCount = scores.filter((s: number) => s >= 70).length;
      const passRate = scores.length > 0 ? (passCount / scores.length) * 100 : 0;
      const reInspections = inspections.filter((i: Record<string, unknown>) => i.parent_inspection_id != null).length;
      const reinspectionRate = inspections.length > 0 ? (reInspections / inspections.length) * 100 : 0;
      const companies = new Set(inspections.map((i: Record<string, unknown>) => i.company_id));

      // Group by type
      const typeMap = new Map<string, number>();
      for (const i of inspections) {
        const t = (i as Record<string, unknown>).inspection_type as string || 'unknown';
        typeMap.set(t, (typeMap.get(t) || 0) + 1);
      }
      const inspectionsByType = Array.from(typeMap.entries())
        .map(([type, count]) => ({ type, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 10);

      // Group deficiencies by severity
      const sevMap = new Map<string, number>();
      for (const d of deficiencies) {
        const s = (d as Record<string, unknown>).severity as string || 'unknown';
        sevMap.set(s, (sevMap.get(s) || 0) + 1);
      }
      const topDeficiencyTypes = Array.from(sevMap.entries())
        .map(([type, count]) => ({ type, count }))
        .sort((a, b) => b.count - a.count);

      setData({
        totalInspections: inspections.length,
        completedInspections: completed.length,
        passRate,
        avgScore,
        totalDeficiencies: deficiencies.length,
        reinspectionRate,
        companiesUsingInspections: companies.size,
        topDeficiencyTypes,
        inspectionsByType,
        recentActivity: [],
      });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load metrics');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}

export default function InspectorMetricsPage() {
  const { data, loading, error, refetch } = useInspectorMetrics();

  const metrics = [
    { label: 'Total Inspections', value: formatNumber(data.totalInspections), icon: <ClipboardCheck className="h-5 w-5" />, subtext: 'All companies' },
    { label: 'Completed', value: formatNumber(data.completedInspections), icon: <CheckCircle className="h-5 w-5" />, subtext: 'Finished inspections' },
    { label: 'Pass Rate', value: `${data.passRate.toFixed(1)}%`, icon: <TrendingUp className="h-5 w-5" />, subtext: 'Score >= 70%' },
    { label: 'Avg Score', value: data.avgScore.toFixed(1), icon: <BarChart3 className="h-5 w-5" />, subtext: 'Out of 100' },
    { label: 'Deficiencies', value: formatNumber(data.totalDeficiencies), icon: <AlertTriangle className="h-5 w-5" />, subtext: 'Total found' },
    { label: 'Re-Inspection Rate', value: `${data.reinspectionRate.toFixed(1)}%`, icon: <Repeat className="h-5 w-5" />, subtext: 'Follow-ups' },
    { label: 'Companies', value: formatNumber(data.companiesUsingInspections), icon: <Users className="h-5 w-5" />, subtext: 'Using inspections' },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Inspector Metrics</h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">Platform-wide inspection analytics across all companies</p>
        </div>
        <button onClick={refetch} disabled={loading} className="flex items-center gap-2 px-4 py-2 rounded-lg border text-sm font-medium hover:bg-[var(--bg-secondary)] transition-colors" style={{ borderColor: 'var(--border)', color: 'var(--text-primary)' }}>
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />Refresh
        </button>
      </div>

      {error && (
        <div className="rounded-lg p-4 border" style={{ backgroundColor: 'color-mix(in srgb, var(--danger) 10%, transparent)', borderColor: 'var(--danger)' }}>
          <p className="text-sm" style={{ color: 'var(--danger)' }}>{error}</p>
        </div>
      )}

      {/* Metrics grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {metrics.map((m, i) => (
          <Card key={i}>
            <CardContent className="p-4">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg" style={{ backgroundColor: 'var(--bg-secondary)' }}>{m.icon}</div>
                <div>
                  <p className="text-xl font-bold" style={{ color: 'var(--text-primary)' }}>{loading ? '—' : m.value}</p>
                  <p className="text-xs" style={{ color: 'var(--text-secondary)' }}>{m.label}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Inspections by type */}
      <Card>
        <CardHeader><CardTitle>Inspections by Type</CardTitle></CardHeader>
        <CardContent>
          {data.inspectionsByType.length === 0 ? (
            <p className="text-center py-6 text-sm" style={{ color: 'var(--text-secondary)' }}>No inspection data yet</p>
          ) : (
            <div className="space-y-3">
              {data.inspectionsByType.map((item) => {
                const pct = data.totalInspections > 0 ? (item.count / data.totalInspections) * 100 : 0;
                return (
                  <div key={item.type} className="flex items-center gap-4">
                    <span className="text-sm font-medium w-36 truncate" style={{ color: 'var(--text-primary)' }}>{item.type}</span>
                    <div className="flex-1 h-2 rounded-full" style={{ backgroundColor: 'var(--bg-secondary)' }}>
                      <div className="h-full rounded-full bg-[var(--accent)]" style={{ width: `${pct}%` }} />
                    </div>
                    <span className="text-sm font-medium w-12 text-right" style={{ color: 'var(--text-primary)' }}>{item.count}</span>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Deficiencies by severity */}
      <Card>
        <CardHeader><CardTitle>Deficiencies by Severity</CardTitle></CardHeader>
        <CardContent>
          {data.topDeficiencyTypes.length === 0 ? (
            <p className="text-center py-6 text-sm" style={{ color: 'var(--text-secondary)' }}>No deficiency data yet</p>
          ) : (
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {data.topDeficiencyTypes.map((item) => {
                const colorMap: Record<string, string> = { critical: 'var(--danger)', major: 'var(--warning)', minor: 'var(--accent)', info: 'var(--text-secondary)' };
                const color = colorMap[item.type] || 'var(--text-secondary)';
                return (
                  <div key={item.type} className="rounded-lg p-4 border text-center" style={{ borderColor: 'var(--border)' }}>
                    <p className="text-2xl font-bold" style={{ color }}>{item.count}</p>
                    <p className="text-xs capitalize mt-1" style={{ color: 'var(--text-secondary)' }}>{item.type}</p>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
