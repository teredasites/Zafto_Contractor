'use client';

import { useEffect, useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase';

// ── Types ──

export type IicrcLevel = 1 | 2 | 3;
export type ContainmentType = 'none' | 'limited' | 'full';
export type MoldClearanceStatus = 'pending' | 'sampling' | 'awaiting_results' | 'passed' | 'failed' | 'not_required';
export type MoldAssessmentStatus = 'in_progress' | 'pending_review' | 'remediation_active' | 'awaiting_clearance' | 'cleared' | 'failed_clearance';
export type SampleType = 'air' | 'surface' | 'bulk' | 'tape_lift';

export interface MoldAssessment {
  id: string;
  company_id: string;
  job_id: string;
  insurance_claim_id: string | null;
  created_by_user_id: string | null;
  iicrc_level: IicrcLevel;
  affected_area_sqft: number | null;
  mold_type: string | null;
  moisture_source: string | null;
  containment_type: ContainmentType;
  negative_pressure: boolean;
  containment_notes: string | null;
  containment_checks: Record<string, unknown>[];
  air_sampling_required: boolean;
  pre_samples: Record<string, unknown>[];
  post_samples: Record<string, unknown>[];
  outdoor_baseline: Record<string, unknown> | null;
  clearance_status: MoldClearanceStatus;
  clearance_date: string | null;
  clearance_inspector: string | null;
  clearance_company: string | null;
  lab_name: string | null;
  lab_sample_id: string | null;
  spore_count_before: number | null;
  spore_count_after: number | null;
  protocol_level: string | null;
  protocol_steps: Record<string, unknown>[];
  material_removal: Record<string, unknown>[];
  equipment_deployed: Record<string, unknown>[];
  ppe_level: string | null;
  antimicrobial_treatments: Record<string, unknown>[];
  photos: Record<string, unknown>[];
  assessment_status: MoldAssessmentStatus;
  notes: string | null;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
}

export interface ChainOfCustodySample {
  id: string;
  company_id: string;
  mold_assessment_id: string;
  sample_type: SampleType;
  sample_location: string | null;
  collected_by: string | null;
  collected_at: string | null;
  shipped_to_lab_at: string | null;
  lab_received_at: string | null;
  results_available_at: string | null;
  lab_name: string | null;
  lab_sample_number: string | null;
  spore_count: number | null;
  spore_types_found: string | null;
  pass_fail: string | null;
  notes: string | null;
  created_at: string;
}

export interface MoldStateRegulation {
  id: string;
  state_code: string;
  state_name: string;
  license_required: boolean;
  license_type: string | null;
  license_url: string | null;
  assessment_required_before_remediation: boolean;
  third_party_clearance_required: boolean;
  disclosure_required: boolean;
  max_sqft_without_license: number | null;
  notes: string | null;
}

export interface MoldLab {
  id: string;
  name: string;
  city: string | null;
  state_code: string | null;
  phone: string | null;
  email: string | null;
  website: string | null;
  aiha_accredited: boolean;
  turnaround_days: number | null;
  notes: string | null;
}

// ── IICRC Level Info ──

export const IICRC_LEVEL_INFO: Record<IicrcLevel, {
  label: string;
  sqft: string;
  containment: string;
  ppe: string;
  airSampling: string;
}> = {
  1: {
    label: 'Level 1 — Small (<10 sqft)',
    sqft: '<10 sqft',
    containment: 'None or limited. Work area isolation.',
    ppe: 'N95 respirator, goggles, gloves',
    airSampling: 'Not typically required',
  },
  2: {
    label: 'Level 2 — Medium (10-30 sqft)',
    sqft: '10-30 sqft',
    containment: 'Limited or full. Poly sheeting, negative air recommended.',
    ppe: 'Half-face P100, goggles, Tyvek, gloves',
    airSampling: 'Recommended. Pre and post remediation.',
  },
  3: {
    label: 'Level 3 — Large (>30 sqft)',
    sqft: '>30 sqft',
    containment: 'Full containment REQUIRED. Negative air, decon chamber, HEPA.',
    ppe: 'Full-face P100, goggles, full Tyvek, boot covers, gloves',
    airSampling: 'REQUIRED. Pre-remediation, post-remediation, outdoor baseline. Clearance testing mandatory.',
  },
};

// ── Mappers ──

function mapAssessment(row: Record<string, unknown>): MoldAssessment {
  return {
    id: row.id as string,
    company_id: row.company_id as string,
    job_id: row.job_id as string,
    insurance_claim_id: (row.insurance_claim_id as string) ?? null,
    created_by_user_id: (row.created_by_user_id as string) ?? null,
    iicrc_level: (row.iicrc_level as IicrcLevel) ?? 2,
    affected_area_sqft: (row.affected_area_sqft as number) ?? null,
    mold_type: (row.mold_type as string) ?? null,
    moisture_source: (row.moisture_source as string) ?? null,
    containment_type: (row.containment_type as ContainmentType) ?? 'none',
    negative_pressure: (row.negative_pressure as boolean) ?? false,
    containment_notes: (row.containment_notes as string) ?? null,
    containment_checks: (row.containment_checks as Record<string, unknown>[]) ?? [],
    air_sampling_required: (row.air_sampling_required as boolean) ?? false,
    pre_samples: (row.pre_samples as Record<string, unknown>[]) ?? [],
    post_samples: (row.post_samples as Record<string, unknown>[]) ?? [],
    outdoor_baseline: (row.outdoor_baseline as Record<string, unknown>) ?? null,
    clearance_status: (row.clearance_status as MoldClearanceStatus) ?? 'pending',
    clearance_date: (row.clearance_date as string) ?? null,
    clearance_inspector: (row.clearance_inspector as string) ?? null,
    clearance_company: (row.clearance_company as string) ?? null,
    lab_name: (row.lab_name as string) ?? null,
    lab_sample_id: (row.lab_sample_id as string) ?? null,
    spore_count_before: (row.spore_count_before as number) ?? null,
    spore_count_after: (row.spore_count_after as number) ?? null,
    protocol_level: (row.protocol_level as string) ?? null,
    protocol_steps: (row.protocol_steps as Record<string, unknown>[]) ?? [],
    material_removal: (row.material_removal as Record<string, unknown>[]) ?? [],
    equipment_deployed: (row.equipment_deployed as Record<string, unknown>[]) ?? [],
    ppe_level: (row.ppe_level as string) ?? null,
    antimicrobial_treatments: (row.antimicrobial_treatments as Record<string, unknown>[]) ?? [],
    photos: (row.photos as Record<string, unknown>[]) ?? [],
    assessment_status: (row.assessment_status as MoldAssessmentStatus) ?? 'in_progress',
    notes: (row.notes as string) ?? null,
    created_at: row.created_at as string,
    updated_at: row.updated_at as string,
    deleted_at: (row.deleted_at as string) ?? null,
  };
}

function mapSample(row: Record<string, unknown>): ChainOfCustodySample {
  return {
    id: row.id as string,
    company_id: row.company_id as string,
    mold_assessment_id: row.mold_assessment_id as string,
    sample_type: (row.sample_type as SampleType) ?? 'air',
    sample_location: (row.sample_location as string) ?? null,
    collected_by: (row.collected_by as string) ?? null,
    collected_at: (row.collected_at as string) ?? null,
    shipped_to_lab_at: (row.shipped_to_lab_at as string) ?? null,
    lab_received_at: (row.lab_received_at as string) ?? null,
    results_available_at: (row.results_available_at as string) ?? null,
    lab_name: (row.lab_name as string) ?? null,
    lab_sample_number: (row.lab_sample_number as string) ?? null,
    spore_count: (row.spore_count as number) ?? null,
    spore_types_found: (row.spore_types_found as string) ?? null,
    pass_fail: (row.pass_fail as string) ?? null,
    notes: (row.notes as string) ?? null,
    created_at: row.created_at as string,
  };
}

// ── Hooks ──

export function useMoldRemediation() {
  const supabase = createClient();
  const [assessments, setAssessments] = useState<MoldAssessment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAssessments = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const { data, error: err } = await supabase
        .from('mold_assessments')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setAssessments((data ?? []).map(mapAssessment));
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  useEffect(() => {
    fetchAssessments();

    const channel = supabase
      .channel('mold_assessments_realtime')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'mold_assessments' },
        () => { fetchAssessments(); }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [supabase, fetchAssessments]);

  const createAssessment = useCallback(async (payload: Partial<MoldAssessment>) => {
    const { data, error: err } = await supabase
      .from('mold_assessments')
      .insert(payload)
      .select()
      .single();

    if (err) throw err;
    return mapAssessment(data);
  }, [supabase]);

  const updateAssessment = useCallback(async (id: string, updates: Partial<MoldAssessment>) => {
    const { data, error: err } = await supabase
      .from('mold_assessments')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (err) throw err;
    return mapAssessment(data);
  }, [supabase]);

  const deleteAssessment = useCallback(async (id: string) => {
    const { error: err } = await supabase
      .from('mold_assessments')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);

    if (err) throw err;
  }, [supabase]);

  return {
    assessments,
    loading,
    error,
    refetch: fetchAssessments,
    createAssessment,
    updateAssessment,
    deleteAssessment,
  };
}

export function useChainOfCustody(assessmentId: string | null) {
  const supabase = createClient();
  const [samples, setSamples] = useState<ChainOfCustodySample[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSamples = useCallback(async () => {
    if (!assessmentId) {
      setSamples([]);
      setLoading(false);
      return;
    }
    try {
      setLoading(true);
      setError(null);
      const { data, error: err } = await supabase
        .from('mold_chain_of_custody')
        .select('*')
        .eq('mold_assessment_id', assessmentId)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setSamples((data ?? []).map(mapSample));
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [supabase, assessmentId]);

  useEffect(() => {
    fetchSamples();

    if (!assessmentId) return;

    const channel = supabase
      .channel(`coc_${assessmentId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'mold_chain_of_custody',
          filter: `mold_assessment_id=eq.${assessmentId}`,
        },
        () => { fetchSamples(); }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [supabase, assessmentId, fetchSamples]);

  const addSample = useCallback(async (payload: Partial<ChainOfCustodySample>) => {
    const { data, error: err } = await supabase
      .from('mold_chain_of_custody')
      .insert(payload)
      .select()
      .single();

    if (err) throw err;
    return mapSample(data);
  }, [supabase]);

  const updateSample = useCallback(async (id: string, updates: Partial<ChainOfCustodySample>) => {
    const { error: err } = await supabase
      .from('mold_chain_of_custody')
      .update(updates)
      .eq('id', id);

    if (err) throw err;
  }, [supabase]);

  return {
    samples,
    loading,
    error,
    refetch: fetchSamples,
    addSample,
    updateSample,
  };
}

export function useStateRegulations() {
  const supabase = createClient();
  const [regulations, setRegulations] = useState<MoldStateRegulation[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        setLoading(true);
        const { data, error: err } = await supabase
          .from('mold_state_regulations')
          .select('*')
          .order('state_code');

        if (err) throw err;
        setRegulations((data ?? []) as unknown as MoldStateRegulation[]);
      } catch {
        // Non-critical — degrade silently
      } finally {
        setLoading(false);
      }
    })();
  }, [supabase]);

  return { regulations, loading };
}

export function useMoldLabs(stateCode?: string) {
  const supabase = createClient();
  const [labs, setLabs] = useState<MoldLab[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        setLoading(true);
        let query = supabase.from('mold_labs').select('*');
        if (stateCode) {
          query = query.eq('state_code', stateCode);
        }
        const { data, error: err } = await query.order('name');

        if (err) throw err;
        setLabs((data ?? []) as unknown as MoldLab[]);
      } catch {
        // Non-critical — degrade silently
      } finally {
        setLoading(false);
      }
    })();
  }, [supabase, stateCode]);

  return { labs, loading };
}
