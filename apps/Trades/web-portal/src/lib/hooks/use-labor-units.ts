'use client';

// DEPTH29: Labor Units Hook
// Manages trade-specific labor hour database with condition multipliers
// and crew performance tracking.

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
  source: 'system' | 'company';
  isSystemDefault: boolean;
}

export interface CrewPerformanceEntry {
  id: string;
  taskName: string;
  trade: string;
  estimatedHours: number;
  actualHours: number;
  crewSize: number;
  difficulty: LaborDifficulty;
  jobId: string | null;
  notes: string | null;
  createdAt: string;
}

// ============================================================================
// MAPPERS
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
    source: row.source as 'system' | 'company',
    isSystemDefault: row.company_id === null,
  };
}

function mapPerformance(row: Record<string, unknown>): CrewPerformanceEntry {
  return {
    id: row.id as string,
    taskName: row.task_name as string,
    trade: row.trade as string,
    estimatedHours: Number(row.estimated_hours) || 0,
    actualHours: Number(row.actual_hours) || 0,
    crewSize: Number(row.crew_size) || 1,
    difficulty: row.difficulty as LaborDifficulty,
    jobId: row.job_id as string | null,
    notes: row.notes as string | null,
    createdAt: row.created_at as string,
  };
}

// ============================================================================
// HOOK: useLaborUnits
// ============================================================================

export function useLaborUnits(trade?: string) {
  const [units, setUnits] = useState<LaborUnit[]>([]);
  const [performance, setPerformance] = useState<CrewPerformanceEntry[]>([]);
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

  // Get categories for a trade
  const getCategories = useCallback((t: string) => {
    return [...new Set(units.filter(u => u.trade === t).map(u => u.category))].sort();
  }, [units]);

  // Calculate total labor hours for a set of tasks
  const calculateTotalHours = useCallback((tasks: Array<{
    unitId: string;
    quantity: number;
    difficulty: LaborDifficulty;
  }>) => {
    return tasks.reduce((total, task) => {
      return total + (getHours(task.unitId, task.difficulty) * task.quantity);
    }, 0);
  }, [getHours]);

  // Add company-specific labor unit
  const addUnit = useCallback(async (input: {
    trade: string;
    category: string;
    taskName: string;
    unit: string;
    hoursNormal: number;
    hoursDifficult: number;
    hoursVeryDifficult: number;
    crewSizeDefault?: number;
    description?: string;
    notes?: string;
  }) => {
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const companyId = session.user.app_metadata?.company_id;
      if (!companyId) throw new Error('No company context');

      const { error: err } = await supabase.from('labor_units').insert({
        company_id: companyId,
        trade: input.trade,
        category: input.category,
        task_name: input.taskName,
        unit: input.unit,
        hours_normal: input.hoursNormal,
        hours_difficult: input.hoursDifficult,
        hours_very_difficult: input.hoursVeryDifficult,
        crew_size_default: input.crewSizeDefault ?? 1,
        description: input.description || null,
        notes: input.notes || null,
        source: 'company',
      });

      if (err) throw err;
      await fetchUnits();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to add labor unit');
    }
  }, [fetchUnits]);

  // Log crew performance for learning
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

  // Fetch crew performance history
  const fetchPerformance = useCallback(async (t?: string) => {
    try {
      const supabase = getSupabase();
      let query = supabase
        .from('crew_performance_log')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);

      if (t) query = query.eq('trade', t);

      const { data, error: err } = await query;
      if (err) throw err;
      setPerformance((data || []).map(mapPerformance));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load performance data');
    }
  }, []);

  return {
    units,
    performance,
    trades,
    loading,
    error,
    refetch: fetchUnits,
    getHours,
    getCategories,
    calculateTotalHours,
    addUnit,
    logPerformance,
    fetchPerformance,
  };
}
