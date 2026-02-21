'use client';

// DEPTH29: Labor Units Hook (Team Portal)
// Read-only labor database + performance logging for field technicians.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type LaborDifficulty = 'normal' | 'difficult' | 'very_difficult';

export interface LaborUnit {
  id: string;
  companyId: string | null;
  trade: string;
  category: string;
  taskName: string;
  description: string | null;
  unit: string;
  hoursNormal: number;
  hoursDifficult: number;
  hoursVeryDifficult: number;
  crewSizeDefault: number;
  notes: string | null;
  isSystemDefault: boolean;
}

// ============================================================================
// MAPPER
// ============================================================================

function mapLaborUnit(row: Record<string, unknown>): LaborUnit {
  return {
    id: row.id as string,
    companyId: row.company_id as string | null,
    trade: row.trade as string,
    category: row.category as string,
    taskName: row.task_name as string,
    description: row.description as string | null,
    unit: row.unit as string,
    hoursNormal: Number(row.hours_normal) || 0,
    hoursDifficult: Number(row.hours_difficult) || 0,
    hoursVeryDifficult: Number(row.hours_very_difficult) || 0,
    crewSizeDefault: Number(row.crew_size_default) || 1,
    notes: row.notes as string | null,
    isSystemDefault: row.company_id === null,
  };
}

// ============================================================================
// HOOK: useLaborUnits (Team — read + performance logging)
// ============================================================================

export function useLaborUnits(trade?: string) {
  const [units, setUnits] = useState<LaborUnit[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchUnits = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      let query = supabase
        .from('labor_units')
        .select('*')
        .is('deleted_at', null)
        .order('trade')
        .order('category')
        .order('task_name');

      if (trade) {
        query = query.eq('trade', trade);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setUnits((data || []).map(mapLaborUnit));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load labor units');
    } finally {
      setLoading(false);
    }
  }, [trade]);

  useEffect(() => { fetchUnits(); }, [fetchUnits]);

  // Get hours for a specific difficulty
  const getHours = useCallback((unitId: string, difficulty: LaborDifficulty = 'normal') => {
    const unit = units.find(u => u.id === unitId);
    if (!unit) return 0;
    switch (difficulty) {
      case 'difficult': return unit.hoursDifficult;
      case 'very_difficult': return unit.hoursVeryDifficult;
      default: return unit.hoursNormal;
    }
  }, [units]);

  // Get unique trades
  const trades = [...new Set(units.map(u => u.trade))].sort();

  // Log crew performance (field techs can report actual hours)
  const logPerformance = useCallback(async (input: {
    laborUnitId?: string;
    taskName: string;
    trade: string;
    estimatedHours: number;
    actualHours: number;
    crewSize: number;
    difficulty: LaborDifficulty;
    jobId?: string;
    notes?: string;
  }) => {
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const companyId = session.user.app_metadata?.company_id;
      if (!companyId) throw new Error('No company context');

      const { error: err } = await supabase.from('crew_performance_log').insert({
        company_id: companyId,
        labor_unit_id: input.laborUnitId || null,
        task_name: input.taskName,
        trade: input.trade,
        estimated_hours: input.estimatedHours,
        actual_hours: input.actualHours,
        crew_size: input.crewSize,
        difficulty: input.difficulty,
        job_id: input.jobId || null,
        notes: input.notes || null,
      });

      if (err) throw err;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to log performance');
    }
  }, []);

  return {
    units,
    trades,
    loading,
    error,
    refetch: fetchUnits,
    getHours,
    logPerformance,
  };
}
