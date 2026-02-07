'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapUnitTurn, mapUnitTurnTask } from './pm-mappers';
import type { UnitTurnData, UnitTurnTaskData } from './pm-mappers';

export function useUnitTurns() {
  const [turns, setTurns] = useState<UnitTurnData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTurns = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('unit_turns')
        .select('*, properties(address_line1), units(unit_number), unit_turn_tasks(*)')
        .order('created_at', { ascending: false });

      if (err) throw err;
      setTurns((data || []).map(mapUnitTurn));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load unit turns';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTurns();

    const supabase = getSupabase();
    const channel = supabase
      .channel('unit-turns-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'unit_turns' }, () => {
        fetchTurns();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchTurns]);

  const createTurn = async (data: {
    propertyId: string;
    unitId: string;
    outgoingLeaseId?: string;
    incomingLeaseId?: string;
    moveOutDate?: string;
    targetReadyDate?: string;
    moveOutInspectionId?: string;
    depositDeductions?: number;
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('unit_turns')
      .insert({
        company_id: companyId,
        property_id: data.propertyId,
        unit_id: data.unitId,
        outgoing_lease_id: data.outgoingLeaseId || null,
        incoming_lease_id: data.incomingLeaseId || null,
        move_out_date: data.moveOutDate || null,
        target_ready_date: data.targetReadyDate || null,
        move_out_inspection_id: data.moveOutInspectionId || null,
        deposit_deductions: data.depositDeductions || 0,
        total_cost: 0,
        notes: data.notes || null,
        status: 'pending',
      })
      .select('id')
      .single();

    if (err) throw err;

    // Update unit status to unit_turn
    const { error: unitErr } = await supabase
      .from('units')
      .update({ status: 'unit_turn' })
      .eq('id', data.unitId);

    if (unitErr) throw unitErr;

    return result.id;
  };

  const updateTurn = async (id: string, data: {
    outgoingLeaseId?: string;
    incomingLeaseId?: string;
    moveOutDate?: string;
    targetReadyDate?: string;
    actualReadyDate?: string;
    moveOutInspectionId?: string;
    moveInInspectionId?: string;
    totalCost?: number;
    depositDeductions?: number;
    notes?: string;
  }) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.outgoingLeaseId !== undefined) updateData.outgoing_lease_id = data.outgoingLeaseId;
    if (data.incomingLeaseId !== undefined) updateData.incoming_lease_id = data.incomingLeaseId;
    if (data.moveOutDate !== undefined) updateData.move_out_date = data.moveOutDate;
    if (data.targetReadyDate !== undefined) updateData.target_ready_date = data.targetReadyDate;
    if (data.actualReadyDate !== undefined) updateData.actual_ready_date = data.actualReadyDate;
    if (data.moveOutInspectionId !== undefined) updateData.move_out_inspection_id = data.moveOutInspectionId;
    if (data.moveInInspectionId !== undefined) updateData.move_in_inspection_id = data.moveInInspectionId;
    if (data.totalCost !== undefined) updateData.total_cost = data.totalCost;
    if (data.depositDeductions !== undefined) updateData.deposit_deductions = data.depositDeductions;
    if (data.notes !== undefined) updateData.notes = data.notes;

    const { error: err } = await supabase
      .from('unit_turns')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;
  };

  const updateTurnStatus = async (id: string, status: UnitTurnData['status']) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = { status };

    if (status === 'ready') {
      updateData.actual_ready_date = new Date().toISOString().split('T')[0];
    }

    const { error: err } = await supabase
      .from('unit_turns')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;

    // Update unit status based on turn status
    if (status === 'ready' || status === 'listed' || status === 'leased') {
      const { data: turn } = await supabase
        .from('unit_turns')
        .select('unit_id')
        .eq('id', id)
        .single();

      if (turn) {
        const unitStatus = status === 'leased' ? 'occupied' : status === 'listed' ? 'listed' : 'vacant';
        await supabase
          .from('units')
          .update({ status: unitStatus })
          .eq('id', turn.unit_id);
      }
    }
  };

  const addTask = async (turnId: string, data: {
    taskType: UnitTurnTaskData['taskType'];
    description: string;
    assignedTo?: string;
    vendorId?: string;
    estimatedCost?: number;
    notes?: string;
    sortOrder?: number;
  }): Promise<string> => {
    const supabase = getSupabase();

    const { data: result, error: err } = await supabase
      .from('unit_turn_tasks')
      .insert({
        unit_turn_id: turnId,
        task_type: data.taskType,
        description: data.description,
        assigned_to: data.assignedTo || null,
        vendor_id: data.vendorId || null,
        estimated_cost: data.estimatedCost || null,
        notes: data.notes || null,
        sort_order: data.sortOrder || 0,
        status: 'pending',
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateTask = async (taskId: string, data: {
    taskType?: UnitTurnTaskData['taskType'];
    description?: string;
    assignedTo?: string;
    vendorId?: string;
    estimatedCost?: number;
    actualCost?: number;
    status?: UnitTurnTaskData['status'];
    notes?: string;
    sortOrder?: number;
  }) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.taskType !== undefined) updateData.task_type = data.taskType;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.assignedTo !== undefined) updateData.assigned_to = data.assignedTo;
    if (data.vendorId !== undefined) updateData.vendor_id = data.vendorId;
    if (data.estimatedCost !== undefined) updateData.estimated_cost = data.estimatedCost;
    if (data.actualCost !== undefined) updateData.actual_cost = data.actualCost;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.sortOrder !== undefined) updateData.sort_order = data.sortOrder;

    const { error: err } = await supabase
      .from('unit_turn_tasks')
      .update(updateData)
      .eq('id', taskId);

    if (err) throw err;
  };

  const completeTask = async (taskId: string) => {
    const supabase = getSupabase();

    // Complete the task
    const { error: err } = await supabase
      .from('unit_turn_tasks')
      .update({
        status: 'completed',
        completed_at: new Date().toISOString(),
      })
      .eq('id', taskId);

    if (err) throw err;

    // Get the task's turn ID
    const { data: task, error: taskErr } = await supabase
      .from('unit_turn_tasks')
      .select('unit_turn_id')
      .eq('id', taskId)
      .single();

    if (taskErr) throw taskErr;

    // Check if all tasks for this turn are complete
    const { data: incompleteTasks, error: checkErr } = await supabase
      .from('unit_turn_tasks')
      .select('id')
      .eq('unit_turn_id', task.unit_turn_id)
      .not('status', 'in', '("completed","skipped")');

    if (checkErr) throw checkErr;

    // If all tasks are complete or skipped, auto-update turn status to 'ready'
    if (!incompleteTasks || incompleteTasks.length === 0) {
      // Calculate total actual cost from all tasks
      const { data: allTasks, error: costErr } = await supabase
        .from('unit_turn_tasks')
        .select('actual_cost')
        .eq('unit_turn_id', task.unit_turn_id);

      if (costErr) throw costErr;

      const costRows: { actual_cost: number | null }[] = allTasks || [];
      const totalCost = costRows.reduce((sum, t) => sum + (Number(t.actual_cost) || 0), 0);

      await supabase
        .from('unit_turns')
        .update({
          status: 'ready',
          actual_ready_date: new Date().toISOString().split('T')[0],
          total_cost: totalCost,
        })
        .eq('id', task.unit_turn_id);
    }
  };

  const createJobFromTask = async (taskId: string): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Get the task details with its turn and property info
    const { data: task, error: taskErr } = await supabase
      .from('unit_turn_tasks')
      .select('*, unit_turns(property_id, unit_id, properties(address_line1))')
      .eq('id', taskId)
      .single();

    if (taskErr) throw taskErr;
    if (!task) throw new Error('Task not found');

    const turn = task.unit_turns as Record<string, unknown>;
    const property = turn.properties as Record<string, unknown> | null;

    // Create the job
    const { data: job, error: jobErr } = await supabase
      .from('jobs')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        property_id: turn.property_id,
        unit_id: turn.unit_id,
        title: `Unit Turn: ${task.description}`,
        description: task.notes || task.description,
        address: property ? (property.address_line1 as string) : null,
        status: 'scheduled',
        assigned_to: task.assigned_to || user.id,
      })
      .select('id')
      .single();

    if (jobErr) throw jobErr;

    // Link the job to the task
    const { error: linkErr } = await supabase
      .from('unit_turn_tasks')
      .update({ job_id: job.id, status: 'in_progress' })
      .eq('id', taskId);

    if (linkErr) throw linkErr;

    return job.id;
  };

  return {
    turns,
    loading,
    error,
    refetch: fetchTurns,
    createTurn,
    updateTurn,
    updateTurnStatus,
    addTask,
    updateTask,
    completeTask,
    createJobFromTask,
  };
}
