'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapJob, JOB_STATUS_TO_DB, JOB_TYPE_COLORS } from './mappers';
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
        .is('deleted_at', null)
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
        job_type: data.jobType || 'standard',
        type_metadata: data.typeMetadata || {},
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
        estimated_duration: data.estimatedDuration || null,
        trade_type: data.tradeType || null,
        internal_notes: data.internalNotes || null,
        assigned_user_ids: data.assignedTo || [],
        tags: data.tags || [],
      })
      .select('id')
      .single();

    if (err) throw err;

    // Fire-and-forget: auto-trigger property scan if address exists
    const address = [data.address?.street, data.address?.city, data.address?.state, data.address?.zip].filter(Boolean).join(', ');
    if (address) {
      supabase.auth.getSession().then(({ data: sessionData }: { data: { session: { access_token: string } | null } }) => {
        const token = sessionData.session?.access_token;
        if (token) {
          fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-property-lookup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
            body: JSON.stringify({ address, job_id: result.id }),
          }).catch(() => { /* non-blocking — scan failure doesn't affect job creation */ });
        }
      });
    }

    fetchJobs();
    return result.id;
  };

  const updateJob = async (id: string, data: Partial<Job>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.title !== undefined) updateData.title = data.title;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.jobType !== undefined) updateData.job_type = data.jobType;
    if (data.typeMetadata !== undefined) updateData.type_metadata = data.typeMetadata;
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
    fetchJobs();
  };

  const updateJobStatus = async (id: string, status: JobStatus) => {
    const supabase = getSupabase();
    const dbStatus = JOB_STATUS_TO_DB[status] || status;
    const updateData: Record<string, unknown> = { status: dbStatus };

    if (status === 'in_progress') updateData.started_at = new Date().toISOString();
    if (status === 'completed') updateData.completed_at = new Date().toISOString();

    const { error: err } = await supabase.from('jobs').update(updateData).eq('id', id);
    if (err) throw err;
    fetchJobs();
  };

  const deleteJob = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('jobs')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    fetchJobs();
  };

  // U22: OSHA → Job Safety — attach safety checklist based on trade
  const attachSafetyChecklist = async (jobId: string, tradeType: string) => {
    const supabase = getSupabase();

    // Look up OSHA standards for this trade
    const { data: standards } = await supabase
      .from('osha_standards')
      .select('standard_number, title, description')
      .contains('applicable_trades', [tradeType])
      .eq('frequently_cited', true)
      .limit(10);

    if (standards && standards.length > 0) {
      const checklist = standards.map((s: Record<string, unknown>) => ({
        standard: s.standard_number,
        title: s.title,
        description: s.description,
        acknowledged: false,
      }));

      await supabase.from('jobs').update({ safety_checklist: checklist }).eq('id', jobId);
    }
  };

  // U22: Acknowledge safety for job
  const acknowledgeSafety = async (jobId: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    await supabase.from('jobs').update({
      safety_acknowledged_at: new Date().toISOString(),
      safety_acknowledged_by: user.id,
    }).eq('id', jobId);
  };

  return { jobs, loading, error, createJob, updateJob, updateJobStatus, deleteJob, attachSafetyChecklist, acknowledgeSafety, refetch: fetchJobs };
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

    let ignore = false;

    const fetchJob = async () => {
      try {
        setLoading(true);
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase.from('jobs').select('*').eq('id', id).single();

        if (ignore) return;
        if (err) throw err;
        setJob(data ? mapJob(data) : null);
      } catch (e: unknown) {
        if (ignore) return;
        const msg = e instanceof Error ? e.message : 'Job not found';
        setError(msg);
      } finally {
        if (!ignore) setLoading(false);
      }
    };

    fetchJob();
    return () => { ignore = true; };
  }, [id]);

  return { job, loading, error };
}

// Derive schedule items from jobs + inspections + permits + compliance deadlines
export function useSchedule() {
  const { jobs, loading: jobsLoading, error: jobsError } = useJobs();
  const [extraItems, setExtraItems] = useState<ScheduledItem[]>([]);
  const [extraLoading, setExtraLoading] = useState(true);

  // Fetch inspections, permits, compliance records in parallel
  const fetchExtraSources = useCallback(async () => {
    try {
      setExtraLoading(true);
      const supabase = getSupabase();

      const [inspRes, permitsRes, complianceRes] = await Promise.all([
        // Inspections from compliance_records where record_type = 'inspection' and has a date
        supabase
          .from('compliance_records')
          .select('id, company_id, job_id, status, started_at, ended_at, data, created_at, jobs(title)')
          .eq('record_type', 'inspection')
          .is('deleted_at', null)
          .order('created_at', { ascending: false }),
        // Permits with relevant dates
        supabase
          .from('permits')
          .select('id, company_id, job_id, permit_number, permit_type, status, description, applied_date, approved_date, expiration_date, inspections, created_at, jobs(title)')
          .is('deleted_at', null)
          .order('created_at', { ascending: false }),
        // Compliance deadlines (non-inspection records)
        supabase
          .from('compliance_records')
          .select('id, company_id, job_id, record_type, status, started_at, ended_at, data, created_at, jobs(title)')
          .neq('record_type', 'inspection')
          .is('deleted_at', null)
          .order('created_at', { ascending: false }),
      ]);

      const items: ScheduledItem[] = [];

      // Map inspections
      if (!inspRes.error && inspRes.data) {
        for (const row of inspRes.data) {
          const startDate = row.started_at || row.created_at;
          if (!startDate) continue;
          const data = (row.data as Record<string, unknown>) || {};
          const jobData = row.jobs as { title?: string } | null;
          const title = (data.title as string) || 'Inspection';
          const start = new Date(startDate);
          const end = row.ended_at ? new Date(row.ended_at) : new Date(start.getTime() + 1 * 60 * 60 * 1000);
          items.push({
            id: row.id,
            type: 'inspection',
            title: `${title}${jobData?.title ? ` — ${jobData.title}` : ''}`,
            description: `Status: ${row.status || 'scheduled'}`,
            start,
            end,
            allDay: false,
            jobId: row.job_id || undefined,
            assignedTo: data.assigned_to ? [data.assigned_to as string] : [],
            color: '#f59e0b', // amber
          });
        }
      }

      // Map permits — show expiration dates and inspection dates
      if (!permitsRes.error && permitsRes.data) {
        for (const row of permitsRes.data) {
          const jobData = row.jobs as { title?: string } | null;
          const permitLabel = row.permit_number ? `Permit #${row.permit_number}` : `${(row.permit_type || 'other').replace(/_/g, ' ')} Permit`;

          // Expiration date as a deadline event
          if (row.expiration_date) {
            const expDate = new Date(row.expiration_date);
            items.push({
              id: `${row.id}-exp`,
              type: 'permit',
              title: `${permitLabel} Expires${jobData?.title ? ` — ${jobData.title}` : ''}`,
              description: row.description || `Status: ${row.status}`,
              start: expDate,
              end: expDate,
              allDay: true,
              jobId: row.job_id || undefined,
              assignedTo: [],
              color: '#ef4444', // red
            });
          }

          // Permit inspection dates
          const inspections = row.inspections as Array<{ id: string; date: string; result: string }> | null;
          if (Array.isArray(inspections)) {
            for (const insp of inspections) {
              if (!insp.date) continue;
              const inspDate = new Date(insp.date);
              items.push({
                id: `${row.id}-insp-${insp.id}`,
                type: 'permit',
                title: `Permit Inspection${jobData?.title ? ` — ${jobData.title}` : ''}`,
                description: `Result: ${insp.result || 'scheduled'}`,
                start: inspDate,
                end: new Date(inspDate.getTime() + 1 * 60 * 60 * 1000),
                allDay: false,
                jobId: row.job_id || undefined,
                assignedTo: [],
                color: '#ef4444', // red
              });
            }
          }
        }
      }

      // Map compliance deadlines
      if (!complianceRes.error && complianceRes.data) {
        for (const row of complianceRes.data) {
          const startDate = row.started_at || row.created_at;
          if (!startDate) continue;
          const data = (row.data as Record<string, unknown>) || {};
          const jobData = row.jobs as { title?: string } | null;
          const title = (data.title as string) || `${(row.record_type || 'compliance').replace(/_/g, ' ')} Deadline`;
          const start = new Date(startDate);
          const end = row.ended_at ? new Date(row.ended_at) : new Date(start.getTime() + 1 * 60 * 60 * 1000);
          items.push({
            id: row.id,
            type: 'compliance',
            title: `${title}${jobData?.title ? ` — ${jobData.title}` : ''}`,
            description: `Status: ${row.status || 'pending'}`,
            start,
            end,
            allDay: false,
            jobId: row.job_id || undefined,
            assignedTo: data.assigned_to ? [data.assigned_to as string] : [],
            color: '#8b5cf6', // purple
          });
        }
      }

      setExtraItems(items);
    } catch {
      // Non-critical — calendar still shows jobs even if extra sources fail
      setExtraItems([]);
    } finally {
      setExtraLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchExtraSources();
  }, [fetchExtraSources]);

  const jobItems: ScheduledItem[] = jobs
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
      color: j.propertyId ? '#10b981' : JOB_TYPE_COLORS[j.jobType]?.dot,
    }));

  const schedule = [...jobItems, ...extraItems];
  const loading = jobsLoading || extraLoading;
  const error = jobsError;

  return { schedule, loading, error };
}

// Team members from users table — enriched with GPS from active time entries
export function useTeam() {
  const [team, setTeam] = useState<TeamMember[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTeam = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Fetch users and active time entries in parallel
      const [usersRes, entriesRes] = await Promise.all([
        supabase
          .from('users')
          .select('*')
          .eq('is_active', true)
          .order('full_name'),
        supabase
          .from('time_entries')
          .select('user_id, location_pings, clock_in')
          .eq('status', 'active'),
      ]);

      if (usersRes.error) throw usersRes.error;

      // Build location map from active time entries
      const locationMap = new Map<string, { lat: number; lng: number; timestamp: Date }>();
      if (!entriesRes.error && entriesRes.data) {
        for (const entry of entriesRes.data) {
          const pings = entry.location_pings as { lat: number; lng: number; timestamp?: string }[] | null;
          if (pings && pings.length > 0) {
            const latest = pings[pings.length - 1];
            if (latest.lat && latest.lng) {
              locationMap.set(entry.user_id as string, {
                lat: latest.lat,
                lng: latest.lng,
                timestamp: latest.timestamp ? new Date(latest.timestamp) : new Date(entry.clock_in as string),
              });
            }
          }
        }
      }

      // Map users and enrich with location
      const members = (usersRes.data || []).map((row: Record<string, unknown>) => {
        const member = mapTeamMember(row);
        const loc = locationMap.get(member.id);
        if (loc) {
          member.location = loc;
        }
        return member;
      });

      setTeam(members);
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
