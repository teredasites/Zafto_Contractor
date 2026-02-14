'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import type {
  ScheduleResource,
  ScheduleTaskResource,
  ResourceType,
} from '@/lib/types/scheduling';

interface DailyUsage {
  date: string;
  hours: number;
  capacity: number;
  over_allocated: boolean;
}

interface OverAllocation {
  resource_id: string;
  resource_name: string;
  date: string;
  allocated_hours: number;
  capacity: number;
  excess_hours: number;
  conflicting_task_ids: string[];
}

interface LevelingDelay {
  task_id: string;
  original_start: string;
  new_start: string;
  delay_days: number;
}

interface LevelingResult {
  delays: LevelingDelay[];
  resolved: number;
  remaining: number;
  iterations: number;
  warnings: string[];
}

interface ResourceLevelingResponse {
  success: boolean;
  over_allocations: OverAllocation[];
  over_allocation_count: number;
  leveling: LevelingResult | null;
  histogram: Record<string, DailyUsage[]>;
}

export function useScheduleResources() {
  const [resources, setResources] = useState<ScheduleResource[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchResources = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('schedule_resources')
        .select('*')
        .is('deleted_at', null)
        .order('name', { ascending: true });

      if (err) throw err;
      setResources(data || []);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load resources';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchResources();

    const supabase = getSupabase();
    const channel = supabase
      .channel('schedule-resources-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'schedule_resources' }, () => {
        fetchResources();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchResources]);

  const createResource = async (data: {
    name: string;
    resource_type: ResourceType;
    max_units?: number;
    cost_per_hour?: number;
    cost_per_unit?: number;
    overtime_rate_multiplier?: number;
    trade?: string;
    role?: string;
    user_id?: string;
    calendar_id?: string;
    color?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('schedule_resources')
      .insert({
        company_id: companyId,
        name: data.name,
        resource_type: data.resource_type,
        max_units: data.max_units ?? 1,
        cost_per_hour: data.cost_per_hour ?? 0,
        cost_per_unit: data.cost_per_unit ?? 0,
        overtime_rate_multiplier: data.overtime_rate_multiplier ?? 1.5,
        trade: data.trade || null,
        role: data.role || null,
        user_id: data.user_id || null,
        calendar_id: data.calendar_id || null,
        color: data.color || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateResource = async (id: string, data: Partial<ScheduleResource>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.name !== undefined) updateData.name = data.name;
    if (data.resource_type !== undefined) updateData.resource_type = data.resource_type;
    if (data.max_units !== undefined) updateData.max_units = data.max_units;
    if (data.cost_per_hour !== undefined) updateData.cost_per_hour = data.cost_per_hour;
    if (data.cost_per_unit !== undefined) updateData.cost_per_unit = data.cost_per_unit;
    if (data.overtime_rate_multiplier !== undefined) updateData.overtime_rate_multiplier = data.overtime_rate_multiplier;
    if (data.trade !== undefined) updateData.trade = data.trade;
    if (data.role !== undefined) updateData.role = data.role;
    if (data.user_id !== undefined) updateData.user_id = data.user_id;
    if (data.calendar_id !== undefined) updateData.calendar_id = data.calendar_id;
    if (data.color !== undefined) updateData.color = data.color;

    const { error: err } = await supabase
      .from('schedule_resources')
      .update(updateData)
      .eq('id', id);
    if (err) throw err;
  };

  const deleteResource = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('schedule_resources')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  return {
    resources,
    loading,
    error,
    createResource,
    updateResource,
    deleteResource,
    refetch: fetchResources,
  };
}

export function useTaskResources(taskId: string | undefined) {
  const [taskResources, setTaskResources] = useState<ScheduleTaskResource[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTaskResources = useCallback(async () => {
    if (!taskId) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('schedule_task_resources')
        .select('*')
        .eq('task_id', taskId)
        .order('created_at', { ascending: true });

      if (err) throw err;
      setTaskResources(data || []);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load task resources';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [taskId]);

  useEffect(() => {
    fetchTaskResources();

    if (!taskId) return;

    const supabase = getSupabase();
    const channel = supabase
      .channel(`task-resources-${taskId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'schedule_task_resources',
        filter: `task_id=eq.${taskId}`,
      }, () => {
        fetchTaskResources();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [taskId, fetchTaskResources]);

  const assignResource = async (data: {
    resource_id: string;
    units_assigned?: number;
    hours_per_day?: number;
    budgeted_cost?: number;
    quantity_needed?: number;
  }): Promise<string> => {
    if (!taskId) throw new Error('No task selected');

    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('schedule_task_resources')
      .insert({
        company_id: companyId,
        task_id: taskId,
        resource_id: data.resource_id,
        units_assigned: data.units_assigned ?? 1,
        hours_per_day: data.hours_per_day ?? null,
        budgeted_cost: data.budgeted_cost ?? 0,
        quantity_needed: data.quantity_needed ?? null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const removeResource = async (assignmentId: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('schedule_task_resources')
      .delete()
      .eq('id', assignmentId);
    if (err) throw err;
  };

  return {
    taskResources,
    loading,
    error,
    assignResource,
    removeResource,
    refetch: fetchTaskResources,
  };
}

export function useResourceLeveling(projectId: string | undefined) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<ResourceLevelingResponse | null>(null);
  const [histogram, setHistogram] = useState<Record<string, DailyUsage[]>>({});

  const levelResources = useCallback(async (options?: {
    respect_critical_path?: boolean;
    leveling_order?: 'priority' | 'float';
    level?: boolean;
  }) => {
    if (!projectId) return;

    try {
      setLoading(true);
      setError(null);

      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/schedule-level-resources`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({
            project_id: projectId,
            options: {
              respect_critical_path: options?.respect_critical_path ?? true,
              leveling_order: options?.leveling_order ?? 'float',
            },
            level: options?.level ?? true,
          }),
        },
      );

      if (!response.ok) {
        const err = await response.json();
        throw new Error(err.error || 'Resource leveling failed');
      }

      const data: ResourceLevelingResponse = await response.json();
      setResult(data);
      setHistogram(data.histogram || {});
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Resource leveling failed';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [projectId]);

  return {
    loading,
    error,
    result,
    histogram,
    levelResources,
  };
}
