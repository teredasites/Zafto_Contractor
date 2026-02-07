'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapJob, type JobData, type JobType } from './mappers';

export function useMyJobs() {
  const [jobs, setJobs] = useState<JobData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchJobs = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const { data, error: err } = await supabase
        .from('jobs')
        .select('*')
        .contains('assigned_user_ids', [user.id])
        .is('deleted_at', null)
        .order('scheduled_start', { ascending: true, nullsFirst: false });

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
    const channel = supabase.channel('team-jobs')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'jobs' }, () => fetchJobs())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchJobs]);

  return { jobs, loading, error };
}

export function useJob(jobId: string) {
  const [job, setJob] = useState<JobData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!jobId) { setLoading(false); return; }

    let ignore = false;

    async function fetchJob() {
      try {
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('jobs')
          .select('*')
          .eq('id', jobId)
          .single();

        if (err) throw err;
        if (!ignore) {
          setJob(data ? mapJob(data) : null);
        }
      } catch (e: unknown) {
        if (!ignore) {
          const msg = e instanceof Error ? e.message : 'Failed to load job';
          setError(msg);
        }
      } finally {
        if (!ignore) {
          setLoading(false);
        }
      }
    }

    fetchJob();

    return () => { ignore = true; };
  }, [jobId]);

  return { job, loading, error };
}

export interface CreateJobInput {
  title: string;
  customerName?: string;
  address?: string;
  city?: string;
  state?: string;
  description?: string;
  jobType?: JobType;
  typeMetadata?: Record<string, unknown>;
  scheduledStart?: string;
  scheduledEnd?: string;
  assignedTo?: string[];
  estimatedAmount?: number;
}

export async function createJob(input: CreateJobInput): Promise<JobData> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { data, error } = await supabase
    .from('jobs')
    .insert({
      title: input.title,
      customer_name: input.customerName || '',
      address: input.address || '',
      city: input.city || '',
      state: input.state || '',
      description: input.description || '',
      job_type: input.jobType || 'standard',
      type_metadata: input.typeMetadata || {},
      scheduled_start: input.scheduledStart || null,
      scheduled_end: input.scheduledEnd || null,
      assigned_user_ids: input.assignedTo || [user.id],
      estimated_amount: input.estimatedAmount || 0,
      status: 'draft',
    })
    .select()
    .single();

  if (error) throw error;
  return mapJob(data);
}

export interface UpdateJobInput {
  title?: string;
  customerName?: string;
  address?: string;
  city?: string;
  state?: string;
  description?: string;
  status?: string;
  jobType?: JobType;
  typeMetadata?: Record<string, unknown>;
  scheduledStart?: string | null;
  scheduledEnd?: string | null;
  assignedTo?: string[];
  estimatedAmount?: number;
}

const JOB_STATUS_TO_DB: Record<string, string> = {
  draft: 'draft', scheduled: 'scheduled', dispatched: 'dispatched',
  en_route: 'enRoute', in_progress: 'inProgress',
  on_hold: 'onHold', completed: 'completed',
  invoiced: 'invoiced', cancelled: 'cancelled',
};

export async function updateJob(jobId: string, input: UpdateJobInput): Promise<JobData> {
  const supabase = getSupabase();

  const updates: Record<string, unknown> = {};
  if (input.title !== undefined) updates.title = input.title;
  if (input.customerName !== undefined) updates.customer_name = input.customerName;
  if (input.address !== undefined) updates.address = input.address;
  if (input.city !== undefined) updates.city = input.city;
  if (input.state !== undefined) updates.state = input.state;
  if (input.description !== undefined) updates.description = input.description;
  if (input.status !== undefined) updates.status = JOB_STATUS_TO_DB[input.status] || input.status;
  if (input.jobType !== undefined) updates.job_type = input.jobType;
  if (input.typeMetadata !== undefined) updates.type_metadata = input.typeMetadata;
  if (input.scheduledStart !== undefined) updates.scheduled_start = input.scheduledStart;
  if (input.scheduledEnd !== undefined) updates.scheduled_end = input.scheduledEnd;
  if (input.assignedTo !== undefined) updates.assigned_user_ids = input.assignedTo;
  if (input.estimatedAmount !== undefined) updates.estimated_amount = input.estimatedAmount;

  const { data, error } = await supabase
    .from('jobs')
    .update(updates)
    .eq('id', jobId)
    .select()
    .single();

  if (error) throw error;
  return mapJob(data);
}
