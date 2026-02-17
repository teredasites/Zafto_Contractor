'use client';

// ZAFTO — Team Portal: Fire Assessment (field tech view)
// Sprint REST1

import { useState, useEffect, useCallback } from 'react';
import {
  Flame,
  AlertTriangle,
  Shield,
  Wind,
  PackageOpen,
  ChevronRight,
} from 'lucide-react';

interface FireAssessmentSummary {
  id: string;
  originRoom: string | null;
  damageSeverity: string;
  assessmentStatus: string;
  damageZoneCount: number;
  boardUpCount: number;
  odorTreatmentCount: number;
  structuralCompromise: boolean;
  waterDamageFromSuppression: boolean;
  createdAt: string;
}

export default function TeamFireAssessmentPage() {
  const [assessments, setAssessments] = useState<FireAssessmentSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAssessments = useCallback(async () => {
    try {
      setError(null);
      const { createClient } = await import('@/lib/supabase');
      const supabase = createClient();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { data, error: err } = await supabase
        .from('fire_assessments')
        .select('id, origin_room, damage_severity, assessment_status, damage_zones, board_up_entries, odor_treatments, structural_compromise, water_damage_from_suppression, created_at')
        .eq('company_id', user.app_metadata?.company_id)
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(50);

      if (err) throw err;

      setAssessments(
        (data || []).map((row: Record<string, unknown>) => ({
          id: row.id as string,
          originRoom: (row.origin_room as string) || null,
          damageSeverity: (row.damage_severity as string) || 'moderate',
          assessmentStatus: (row.assessment_status as string) || 'in_progress',
          damageZoneCount: Array.isArray(row.damage_zones) ? row.damage_zones.length : 0,
          boardUpCount: Array.isArray(row.board_up_entries) ? row.board_up_entries.length : 0,
          odorTreatmentCount: Array.isArray(row.odor_treatments) ? row.odor_treatments.length : 0,
          structuralCompromise: (row.structural_compromise as boolean) || false,
          waterDamageFromSuppression: (row.water_damage_from_suppression as boolean) || false,
          createdAt: row.created_at as string,
        }))
      );
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchAssessments(); }, [fetchAssessments]);

  const severityColor = (s: string) => {
    switch (s) {
      case 'minor': return 'bg-blue-500/10 text-blue-400';
      case 'moderate': return 'bg-yellow-500/10 text-yellow-400';
      case 'major': return 'bg-red-500/10 text-red-400';
      case 'total_loss': return 'bg-red-500/20 text-red-500';
      default: return 'bg-gray-500/10 text-gray-400';
    }
  };

  return (
    <div className="flex flex-col gap-4 p-4">
      <div>
        <h1 className="text-xl font-bold">Fire Assessments</h1>
        <p className="text-sm text-muted-foreground">
          Field assessment, soot classification, board-up, odor treatment
        </p>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-20">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      ) : error ? (
        <div className="rounded-lg border border-red-500/30 bg-red-500/5 p-6 text-center">
          <AlertTriangle className="mx-auto mb-2 h-8 w-8 text-red-500" />
          <p className="text-sm text-red-400">{error}</p>
          <button onClick={fetchAssessments} className="mt-2 text-sm text-primary underline">
            Retry
          </button>
        </div>
      ) : assessments.length === 0 ? (
        <div className="rounded-lg border border-dashed p-12 text-center">
          <Flame className="mx-auto mb-3 h-10 w-10 text-muted-foreground/30" />
          <p className="text-sm text-muted-foreground">No fire assessments yet</p>
          <p className="mt-1 text-xs text-muted-foreground/70">
            Create assessments from the mobile app on-site
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {assessments.map((a) => (
            <div
              key={a.id}
              className="flex items-center justify-between rounded-lg border bg-card p-4"
            >
              <div className="space-y-1">
                <div className="flex items-center gap-2">
                  <Flame className="h-4 w-4 text-orange-500" />
                  <span className="text-sm font-medium">
                    {a.originRoom || 'Unspecified origin'}
                  </span>
                  <span className={`rounded-full px-2 py-0.5 text-[10px] font-semibold ${severityColor(a.damageSeverity)}`}>
                    {a.damageSeverity.replace('_', ' ').toUpperCase()}
                  </span>
                  {a.structuralCompromise && (
                    <AlertTriangle className="h-3.5 w-3.5 text-red-500" />
                  )}
                </div>
                <div className="flex items-center gap-3 text-xs text-muted-foreground">
                  <span>{a.damageZoneCount} zone{a.damageZoneCount !== 1 ? 's' : ''}</span>
                  <span>{a.boardUpCount} board-up{a.boardUpCount !== 1 ? 's' : ''}</span>
                  <span>{a.odorTreatmentCount} treatment{a.odorTreatmentCount !== 1 ? 's' : ''}</span>
                  {a.waterDamageFromSuppression && (
                    <span className="text-blue-400">+ water suppression</span>
                  )}
                </div>
              </div>
              <ChevronRight className="h-4 w-4 text-muted-foreground" />
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
