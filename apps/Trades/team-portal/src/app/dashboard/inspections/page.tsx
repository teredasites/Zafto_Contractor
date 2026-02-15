'use client';

import { useState, useEffect, useCallback } from 'react';
import {
  ClipboardCheck,
  Calendar,
  CheckCircle,
  XCircle,
  Clock,
  AlertTriangle,
  BarChart3,
  RefreshCw,
} from 'lucide-react';
import { getSupabase } from '@/lib/supabase';

interface InspectionRow {
  id: string;
  inspectionType: string;
  status: string;
  score: number | null;
  scheduledDate: string | null;
  completedDate: string | null;
  notes: string | null;
}

function mapRow(row: Record<string, unknown>): InspectionRow {
  return {
    id: row.id as string,
    inspectionType: (row.inspection_type as string) || 'general',
    status: (row.status as string) || 'scheduled',
    score: (row.score as number) ?? null,
    scheduledDate: (row.scheduled_date as string) || null,
    completedDate: (row.completed_date as string) || null,
    notes: (row.notes as string) || null,
  };
}

function useMyInspections() {
  const [inspections, setInspections] = useState<InspectionRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { data, error: err } = await supabase
        .from('pm_inspections')
        .select('id, inspection_type, status, score, scheduled_date, completed_date, notes')
        .eq('inspected_by', user.id)
        .order('scheduled_date', { ascending: false })
        .limit(100);

      if (err) throw err;
      setInspections((data || []).map(mapRow));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load inspections');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetch(); }, [fetch]);

  return { inspections, loading, error, refetch: fetch };
}

function formatDate(d: string | null): string {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function typeLabel(t: string): string {
  const labels: Record<string, string> = {
    move_in: 'Move-In', move_out: 'Move-Out', routine: 'Routine', annual: 'Annual',
    maintenance: 'Maintenance', safety: 'Safety', rough_in: 'Rough-In', framing: 'Framing',
    foundation: 'Foundation', final_inspection: 'Final', permit: 'Permit',
    code_compliance: 'Code Compliance', qc_hold_point: 'QC Hold Point',
    re_inspection: 'Re-Inspection', electrical: 'Electrical', plumbing: 'Plumbing', hvac: 'HVAC',
    roofing: 'Roofing', fire_life_safety: 'Fire/Life Safety',
  };
  return labels[t] || t.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

export default function InspectionsPage() {
  const { inspections, loading, error, refetch } = useMyInspections();
  const [tab, setTab] = useState<'upcoming' | 'history'>('upcoming');

  const now = new Date();
  const upcoming = inspections.filter(i => i.status === 'scheduled' || i.status === 'in_progress');
  const history = inspections.filter(i => i.status === 'completed' || i.status === 'cancelled');
  const display = tab === 'upcoming' ? upcoming : history;

  const completedCount = history.length;
  const scores = history.filter(i => i.score != null).map(i => i.score!);
  const avgScore = scores.length > 0 ? scores.reduce((a, b) => a + b, 0) / scores.length : 0;
  const passCount = scores.filter(s => s >= 70).length;
  const passRate = scores.length > 0 ? (passCount / scores.length) * 100 : 0;

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold" style={{ color: 'var(--text)' }}>My Inspections</h1>
          <p className="text-sm mt-0.5" style={{ color: 'var(--text-muted)' }}>
            Your inspection history and upcoming schedule
          </p>
        </div>
        <button onClick={refetch} className="p-2 rounded-lg" style={{ color: 'var(--text-muted)' }}>
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3">
        <div className="rounded-xl border p-3 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <p className="text-lg font-bold" style={{ color: 'var(--accent)' }}>{upcoming.length}</p>
          <p className="text-[10px] font-medium" style={{ color: 'var(--text-muted)' }}>Upcoming</p>
        </div>
        <div className="rounded-xl border p-3 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <p className="text-lg font-bold" style={{ color: 'var(--success)' }}>{completedCount}</p>
          <p className="text-[10px] font-medium" style={{ color: 'var(--text-muted)' }}>Completed</p>
        </div>
        <div className="rounded-xl border p-3 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <p className="text-lg font-bold" style={{ color: passRate >= 70 ? 'var(--success)' : 'var(--warning)' }}>{passRate.toFixed(0)}%</p>
          <p className="text-[10px] font-medium" style={{ color: 'var(--text-muted)' }}>Pass Rate</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 p-1 rounded-xl" style={{ backgroundColor: 'var(--bg-secondary)' }}>
        <button onClick={() => setTab('upcoming')} className="flex-1 py-2 rounded-lg text-sm font-medium transition-colors" style={{ backgroundColor: tab === 'upcoming' ? 'var(--surface)' : 'transparent', color: tab === 'upcoming' ? 'var(--text)' : 'var(--text-muted)' }}>
          Upcoming ({upcoming.length})
        </button>
        <button onClick={() => setTab('history')} className="flex-1 py-2 rounded-lg text-sm font-medium transition-colors" style={{ backgroundColor: tab === 'history' ? 'var(--surface)' : 'transparent', color: tab === 'history' ? 'var(--text)' : 'var(--text-muted)' }}>
          History ({history.length})
        </button>
      </div>

      {/* Loading */}
      {loading && (
        <div className="space-y-2 animate-pulse">
          {[1, 2, 3].map(i => (
            <div key={i} className="rounded-xl border p-4" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
              <div className="h-4 rounded w-40 mb-2" style={{ backgroundColor: 'var(--bg-secondary)' }} />
              <div className="h-3 rounded w-24" style={{ backgroundColor: 'var(--border-light)' }} />
            </div>
          ))}
        </div>
      )}

      {/* Error */}
      {error && (
        <div className="rounded-xl border p-4 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--danger)' }}>
          <AlertTriangle size={24} className="mx-auto mb-2" style={{ color: 'var(--danger)' }} />
          <p className="text-sm" style={{ color: 'var(--danger)' }}>{error}</p>
        </div>
      )}

      {/* List */}
      {!loading && !error && display.length === 0 && (
        <div className="rounded-xl border p-8 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <ClipboardCheck size={32} className="mx-auto mb-3" style={{ color: 'var(--text-muted)' }} />
          <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>
            {tab === 'upcoming' ? 'No upcoming inspections' : 'No inspection history'}
          </h3>
          <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>
            {tab === 'upcoming' ? 'New inspections will appear when assigned to you.' : 'Completed inspections will show up here.'}
          </p>
        </div>
      )}

      {!loading && !error && display.length > 0 && (
        <div className="space-y-2">
          {display.map(insp => {
            const isCompleted = insp.status === 'completed';
            const passed = insp.score != null && insp.score >= 70;
            const statusColor = isCompleted ? (passed ? 'var(--success)' : 'var(--danger)') : insp.status === 'in_progress' ? 'var(--warning)' : 'var(--accent)';
            const statusLabel = isCompleted ? (passed ? 'Passed' : 'Failed') : insp.status === 'in_progress' ? 'In Progress' : 'Scheduled';

            return (
              <div key={insp.id} className="flex items-center gap-3 rounded-xl border p-4" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
                <div className="p-2.5 rounded-xl" style={{ backgroundColor: 'var(--bg-secondary)' }}>
                  <ClipboardCheck size={18} style={{ color: statusColor }} />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>{typeLabel(insp.inspectionType)}</h3>
                  <div className="flex items-center gap-2 mt-0.5">
                    <Calendar size={11} style={{ color: 'var(--text-muted)' }} />
                    <span className="text-xs" style={{ color: 'var(--text-muted)' }}>
                      {formatDate(isCompleted ? insp.completedDate : insp.scheduledDate)}
                    </span>
                  </div>
                </div>
                <div className="flex flex-col items-end gap-1 flex-shrink-0">
                  <span className="text-[10px] font-medium px-2.5 py-1 rounded-full" style={{ backgroundColor: `color-mix(in srgb, ${statusColor} 15%, transparent)`, color: statusColor }}>
                    {statusLabel}
                  </span>
                  {insp.score != null && (
                    <span className="text-xs font-bold" style={{ color: passed ? 'var(--success)' : 'var(--danger)' }}>
                      {insp.score}%
                    </span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
