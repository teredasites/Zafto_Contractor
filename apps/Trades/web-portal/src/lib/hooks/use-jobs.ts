'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapJob, JOB_STATUS_TO_DB } from './mappers';
import type { Job, JobStatus, ScheduledItem, TeamMember } from '@/types';
import { mapTeamMember } from './mappers';

export function useJobs() {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchJobs = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('jobs')
        .select('*')
        .order('created_at', { ascending: false });

      if (err) throw err;
      setJobs((data || []).map(mapJob));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load jobs';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchJobs();

    const supabase = getSupabase();
    const channel = supabase
      .channel('jobs-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'jobs' }, () => {
        fetchJobs();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchJobs]);

  const createJob = async (data: Partial<Job>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('jobs')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        customer_id: data.customerId || null,
        title: data.title || 'Untitled Job',
        description: data.description || null,
        status: JOB_STATUS_TO_DB[data.status || 'lead'] || 'draft',
        priority: data.priority || 'normal',
        address: data.address?.street || '',
        city: data.address?.city || '',
        state: data.address?.state || '',
        zip_code: data.address?.zip || '',
        customer_name: data.customer ? `${data.customer.firstName} ${data.customer.lastName}`.trim() : '',
        customer_email: data.customer?.email || null,
        customer_phone: data.customer?.phone || null,
        scheduled_start: data.scheduledStart ? new Date(data.scheduledStart).toISOString() : null,
        scheduled_end: data.scheduledEnd ? new Date(data.scheduledEnd).toISOString() : null,
        estimated_amount: data.estimatedValue || null,
        assigned_user_ids: data.assignedTo || [],
        tags: data.tags || [],
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateJob = async (id: string, data: Partial<Job>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.title !== undefined) updateData.title = data.title;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.status !== undefined) updateData.status = JOB_STATUS_TO_DB[data.status] || data.status;
    if (data.priority !== undefined) updateData.priority = data.priority;
    if (data.address) {
      updateData.address = data.address.street;
      updateData.city = data.address.city;
      updateData.state = data.address.state;
      updateData.zip_code = data.address.zip;
    }
    if (data.scheduledStart !== undefined) {
      updateData.scheduled_start = data.scheduledStart ? new Date(data.scheduledStart).toISOString() : null;
    }
    if (data.scheduledEnd !== undefined) {
      updateData.scheduled_end = data.scheduledEnd ? new Date(data.scheduledEnd).toISOString() : null;
    }
    if (data.estimatedValue !== undefined) updateData.estimated_amount = data.estimatedValue;
    if (data.actualCost !== undefined) updateData.actual_amount = data.actualCost;
    if (data.assignedTo !== undefined) updateData.assigned_user_ids = data.assignedTo;
    if (data.tags) updateData.tags = data.tags;

    const { error: err } = await supabase.from('jobs').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const updateJobStatus = async (id: string, status: JobStatus) => {
    const supabase = getSupabase();
    const dbStatus = JOB_STATUS_TO_DB[status] || status;
    const updateData: Record<string, unknown> = { status: dbStatus };

    if (status === 'in_progress') updateData.started_at = new Date().toISOString();
    if (status === 'completed') updateData.completed_at = new Date().toISOString();

    const { error: err } = await supabase.from('jobs').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const deleteJob = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('jobs')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  return { jobs, loading, error, createJob, updateJob, updateJobStatus, deleteJob, refetch: fetchJobs };
}

export function useJob(id: string | undefined) {
  const [job, setJob] = useState<Job | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) {
      setLoading(false);
      return;
    }

    const fetchJob = async () => {
      try {
        setLoading(true);
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase.from('jobs').select('*').eq('id', id).single();

        if (err) throw err;
        setJob(data ? mapJob(data) : null);
      } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Job not found';
        setError(msg);
      } finally {
        setLoading(false);
      }
    };

    fetchJob();
  }, [id]);

  return { job, loading, error };
}

// Derive schedule items from jobs
export function useSchedule() {
  const { jobs, loading, error } = useJobs();

  const schedule: ScheduledItem[] = jobs
    .filter((j) => j.scheduledStart)
    .map((j) => ({
      id: j.id,
      type: 'job' as const,
      title: j.title,
      description: j.description,
      start: j.scheduledStart!,
      end: j.scheduledEnd || new Date(new Date(j.scheduledStart!).getTime() + 2 * 60 * 60 * 1000),
      allDay: false,
      jobId: j.id,
      customerId: j.customerId,
      assignedTo: j.assignedTo,
    }));

  return { schedule, loading, error };
}

// Team members from users table
export function useTeam() {
  const [team, setTeam] = useState<TeamMember[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTeam = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('users')
        .select('*')
        .eq('is_active', true)
        .order('full_name');

      if (err) throw err;
      setTeam((data || []).map(mapTeamMember));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load team';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTeam();
  }, [fetchTeam]);

  return { team, loading, error, refetch: fetchTeam };
}
