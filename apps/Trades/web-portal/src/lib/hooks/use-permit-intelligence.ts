'use client';

// L2: Permit Intelligence Hook — jurisdictions, requirements, permit lookup
// Connects to L1 tables: permit_jurisdictions, permit_requirements, job_permits, permit_inspections.
// Separate from use-permits.ts (old permits table).

import { useState, useEffect, useCallback } from 'react';
import { createClient } from '../supabase';

const supabase = createClient();

// ── Interfaces ──────────────────────────────────────────

export interface PermitJurisdiction {
  id: string;
  jurisdiction_name: string;
  jurisdiction_type: string;
  state_code: string;
  county_fips: string | null;
  city_name: string | null;
  building_dept_name: string | null;
  building_dept_phone: string | null;
  building_dept_url: string | null;
  online_submission_url: string | null;
  avg_turnaround_days: number | null;
  notes: string | null;
  verified: boolean;
  contributed_by: string | null;
  contribution_count: number;
  created_at: string;
}

export interface PermitRequirement {
  id: string;
  jurisdiction_id: string;
  work_type: string;
  trade_type: string | null;
  permit_required: boolean;
  permit_type: string;
  estimated_fee: number | null;
  inspections_required: string[];
  typical_documents: string[];
  exemptions: string | null;
  verified: boolean;
  created_at: string;
}

export interface JobPermitRecord {
  id: string;
  company_id: string;
  job_id: string;
  jurisdiction_id: string | null;
  permit_type: string;
  permit_number: string | null;
  application_date: string | null;
  approval_date: string | null;
  expiration_date: string | null;
  fee_paid: number | null;
  status: string;
  notes: string | null;
  document_path: string | null;
  created_at: string;
}

export interface PermitInspectionRecord {
  id: string;
  company_id: string;
  job_permit_id: string;
  inspection_type: string;
  scheduled_date: string | null;
  completed_date: string | null;
  inspector_name: string | null;
  inspector_phone: string | null;
  result: string | null;
  failure_reason: string | null;
  correction_notes: string | null;
  correction_deadline: string | null;
  photos: Array<{ path: string; caption?: string }>;
  reinspection_needed: boolean;
  reinspection_date: string | null;
  created_at: string;
}

export interface PermitLookupResult {
  address: string;
  geocoded: {
    city: string | null;
    county: string | null;
    state: string | null;
    stateCode: string | null;
    lat: number;
    lng: number;
    displayName: string;
  } | null;
  jurisdiction: {
    id: string;
    name: string;
    type: string;
    stateCode: string;
    buildingDeptName: string | null;
    buildingDeptPhone: string | null;
    buildingDeptUrl: string | null;
    onlineSubmissionUrl: string | null;
    avgTurnaroundDays: number | null;
  } | null;
  matchType: string;
  requirements: PermitRequirement[];
  requirementCount: number;
  attribution: string;
}

// ── Jurisdictions Hook ──────────────────────────────────

export function useJurisdictions(stateCode?: string) {
  const [jurisdictions, setJurisdictions] = useState<PermitJurisdiction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      let query = supabase.from('permit_jurisdictions').select('*');
      if (stateCode) query = query.eq('state_code', stateCode);
      query = query.is('deleted_at', null);
      const { data, error: err } = await query.order('jurisdiction_name');
      if (err) throw err;
      setJurisdictions(data || []);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load jurisdictions');
    } finally {
      setLoading(false);
    }
  }, [stateCode]);

  useEffect(() => { load(); }, [load]);

  const updateJurisdiction = useCallback(async (
    id: string,
    updates: Partial<PermitJurisdiction>
  ) => {
    const { error: err } = await supabase
      .from('permit_jurisdictions')
      .update(updates)
      .eq('id', id);
    if (err) throw err;
    await load();
  }, [load]);

  const createJurisdiction = useCallback(async (
    jurisdiction: Partial<PermitJurisdiction>
  ) => {
    const { error: err } = await supabase
      .from('permit_jurisdictions')
      .insert(jurisdiction);
    if (err) throw err;
    await load();
  }, [load]);

  return { jurisdictions, loading, error, updateJurisdiction, createJurisdiction, reload: load };
}

// ── Job Permits Hook (real-time) ────────────────────────

export function useJobPermitRecords(jobId?: string) {
  const [permits, setPermits] = useState<JobPermitRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      let query = supabase.from('job_permits').select('*');
      if (jobId) query = query.eq('job_id', jobId);
      query = query.is('deleted_at', null);
      const { data, error: err } = await query.order('created_at', { ascending: false });
      if (err) throw err;
      setPermits(data || []);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load permits');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    load();
    const channel = supabase
      .channel('job-permits-intel-rt')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'job_permits' }, () => load())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [load]);

  const createPermit = useCallback(async (permit: Partial<JobPermitRecord>) => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const { error: err } = await supabase.from('job_permits').insert({
      ...permit,
      company_id: user.app_metadata?.company_id,
    });
    if (err) throw err;
  }, []);

  const updateStatus = useCallback(async (id: string, status: string) => {
    const updates: Record<string, unknown> = { status };
    if (status === 'approved') {
      updates.approval_date = new Date().toISOString().split('T')[0];
    }
    const { error: err } = await supabase.from('job_permits').update(updates).eq('id', id);
    if (err) throw err;
  }, []);

  const activePermits = permits.filter(p => !['closed', 'denied'].includes(p.status));
  const expiringSoon = permits.filter(p => {
    if (!p.expiration_date) return false;
    const days = Math.ceil((new Date(p.expiration_date).getTime() - Date.now()) / 86400000);
    return days > 0 && days <= 30;
  });

  return { permits, activePermits, expiringSoon, loading, error, createPermit, updateStatus, reload: load };
}

// ── Permit Lookup Hook ──────────────────────────────────

export function usePermitLookup() {
  const [result, setResult] = useState<PermitLookupResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const lookup = useCallback(async (address: string, tradeType?: string) => {
    setLoading(true);
    setError(null);
    setResult(null);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');
      const resp = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/permit-requirement-lookup`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ address, trade_type: tradeType }),
        }
      );
      const data = await resp.json();
      if (data.error && !data.geocoded) throw new Error(data.error);
      setResult(data);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Permit lookup failed');
    } finally {
      setLoading(false);
    }
  }, []);

  return { result, loading, error, lookup };
}

// ── Inspections Hook ────────────────────────────────────

export function usePermitInspections(jobPermitId: string) {
  const [inspections, setInspections] = useState<PermitInspectionRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const { data, error: err } = await supabase
        .from('permit_inspections')
        .select('*')
        .eq('job_permit_id', jobPermitId)
        .is('deleted_at', null)
        .order('scheduled_date');
      if (err) throw err;
      setInspections(data || []);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load inspections');
    } finally {
      setLoading(false);
    }
  }, [jobPermitId]);

  useEffect(() => { load(); }, [load]);

  const createInspection = useCallback(async (
    inspection: Partial<PermitInspectionRecord>
  ) => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const { error: err } = await supabase.from('permit_inspections').insert({
      ...inspection,
      company_id: user.app_metadata?.company_id,
    });
    if (err) throw err;
    await load();
  }, [load]);

  const updateResult = useCallback(async (
    id: string,
    result: string,
    details?: { failureReason?: string; correctionNotes?: string; correctionDeadline?: string }
  ) => {
    const updates: Record<string, unknown> = {
      result,
      completed_date: new Date().toISOString().split('T')[0],
      reinspection_needed: result === 'fail',
    };
    if (details?.failureReason) updates.failure_reason = details.failureReason;
    if (details?.correctionNotes) updates.correction_notes = details.correctionNotes;
    if (details?.correctionDeadline) updates.correction_deadline = details.correctionDeadline;
    const { error: err } = await supabase.from('permit_inspections').update(updates).eq('id', id);
    if (err) throw err;
    await load();
  }, [load]);

  return { inspections, loading, error, createInspection, updateResult, reload: load };
}
