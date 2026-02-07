'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapMaintenanceRequest, mapWorkOrderAction } from './pm-mappers';
import type { MaintenanceRequestData, WorkOrderActionData } from './pm-mappers';

export function usePmMaintenance() {
  const [requests, setRequests] = useState<MaintenanceRequestData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchRequests = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('maintenance_requests')
        .select('*, properties(address_line1), units(unit_number), tenants(first_name, last_name)')
        .order('created_at', { ascending: false });

      if (err) throw err;
      setRequests((data || []).map(mapMaintenanceRequest));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load maintenance requests';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchRequests();

    const supabase = getSupabase();
    const channel = supabase
      .channel('maintenance-requests-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'maintenance_requests' }, () => {
        fetchRequests();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchRequests]);

  const createRequest = async (data: {
    propertyId: string;
    unitId?: string;
    tenantId?: string;
    title: string;
    description: string;
    urgency: MaintenanceRequestData['urgency'];
    category: MaintenanceRequestData['category'];
    preferredTimes?: string[];
    estimatedCost?: number;
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('maintenance_requests')
      .insert({
        company_id: companyId,
        property_id: data.propertyId,
        unit_id: data.unitId || null,
        tenant_id: data.tenantId || null,
        title: data.title,
        description: data.description,
        urgency: data.urgency,
        category: data.category,
        preferred_times: data.preferredTimes || null,
        estimated_cost: data.estimatedCost || null,
        notes: data.notes || null,
        status: 'submitted',
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateRequest = async (id: string, data: {
    title?: string;
    description?: string;
    urgency?: MaintenanceRequestData['urgency'];
    category?: MaintenanceRequestData['category'];
    preferredTimes?: string[];
    estimatedCost?: number;
    actualCost?: number;
    notes?: string;
  }) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.title !== undefined) updateData.title = data.title;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.urgency !== undefined) updateData.urgency = data.urgency;
    if (data.category !== undefined) updateData.category = data.category;
    if (data.preferredTimes !== undefined) updateData.preferred_times = data.preferredTimes;
    if (data.estimatedCost !== undefined) updateData.estimated_cost = data.estimatedCost;
    if (data.actualCost !== undefined) updateData.actual_cost = data.actualCost;
    if (data.notes !== undefined) updateData.notes = data.notes;

    const { error: err } = await supabase
      .from('maintenance_requests')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;
  };

  const updateRequestStatus = async (id: string, status: MaintenanceRequestData['status']) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = { status };

    if (status === 'completed') {
      updateData.completed_at = new Date().toISOString();
    }

    const { error: err } = await supabase
      .from('maintenance_requests')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;
  };

  const assignToSelf = async (requestId: string): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Get the maintenance request details to link property/unit to the job
    const { data: request, error: fetchErr } = await supabase
      .from('maintenance_requests')
      .select('*, properties(address_line1), tenants(first_name, last_name)')
      .eq('id', requestId)
      .single();

    if (fetchErr) throw fetchErr;
    if (!request) throw new Error('Maintenance request not found');

    const property = request.properties as Record<string, unknown> | null;
    const tenant = request.tenants as Record<string, unknown> | null;
    const customerName = tenant
      ? `${tenant.first_name} ${tenant.last_name}`
      : (property ? (property.address_line1 as string) : 'Maintenance Request');

    // Create a job from the maintenance request
    const { data: job, error: jobErr } = await supabase
      .from('jobs')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        maintenance_request_id: requestId,
        property_id: request.property_id,
        unit_id: request.unit_id || null,
        title: request.title,
        description: request.description,
        customer_name: customerName,
        address: property ? (property.address_line1 as string) : null,
        status: 'scheduled',
        assigned_to: user.id,
      })
      .select('id')
      .single();

    if (jobErr) throw jobErr;

    // Update the maintenance request: link job, set assigned_to, update status
    const { error: updateErr } = await supabase
      .from('maintenance_requests')
      .update({
        job_id: job.id,
        assigned_to: user.id,
        status: 'in_progress',
      })
      .eq('id', requestId);

    if (updateErr) throw updateErr;

    return job.id;
  };

  const assignToVendor = async (requestId: string, vendorId: string) => {
    const supabase = getSupabase();

    const { error: err } = await supabase
      .from('maintenance_requests')
      .update({
        assigned_vendor_id: vendorId,
        status: 'scheduled',
      })
      .eq('id', requestId);

    if (err) throw err;
  };

  const getRequestActions = async (requestId: string): Promise<WorkOrderActionData[]> => {
    const supabase = getSupabase();

    const { data, error: err } = await supabase
      .from('work_order_actions')
      .select('*')
      .eq('maintenance_request_id', requestId)
      .order('created_at', { ascending: true });

    if (err) throw err;
    return (data || []).map(mapWorkOrderAction);
  };

  const addAction = async (data: {
    maintenanceRequestId: string;
    jobId?: string;
    actionType: string;
    actorName: string;
    notes?: string;
    photos?: string[];
    metadata?: Record<string, unknown>;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('work_order_actions')
      .insert({
        company_id: companyId,
        maintenance_request_id: data.maintenanceRequestId,
        job_id: data.jobId || null,
        action_type: data.actionType,
        actor_type: 'user',
        actor_id: user.id,
        actor_name: data.actorName,
        notes: data.notes || null,
        photos: data.photos || [],
        metadata: data.metadata || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const getRequestsByStatus = async (status: MaintenanceRequestData['status']): Promise<MaintenanceRequestData[]> => {
    const supabase = getSupabase();

    const { data, error: err } = await supabase
      .from('maintenance_requests')
      .select('*, properties(address_line1), units(unit_number), tenants(first_name, last_name)')
      .eq('status', status)
      .order('created_at', { ascending: false });

    if (err) throw err;
    return (data || []).map(mapMaintenanceRequest);
  };

  return {
    requests,
    loading,
    error,
    refetch: fetchRequests,
    createRequest,
    updateRequest,
    updateRequestStatus,
    assignToSelf,
    assignToVendor,
    getRequestActions,
    addAction,
    getRequestsByStatus,
  };
}
