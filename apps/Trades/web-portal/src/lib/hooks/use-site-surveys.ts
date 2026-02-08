'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface SiteSurvey {
  id: string;
  companyId: string;
  jobId: string | null;
  jobTitle?: string;
  sketchId: string | null;
  title: string;
  surveyType: string;
  surveyorId: string | null;
  surveyorName: string;
  propertyType: string | null;
  yearBuilt: number | null;
  stories: number;
  totalSqft: number | null;
  exteriorCondition: string | null;
  interiorCondition: string | null;
  roofCondition: string | null;
  electricalService: string | null;
  plumbingType: string | null;
  hvacType: string | null;
  conditions: Array<{ area: string; condition: string; notes?: string; severity?: string }>;
  measurements: Array<{ area: string; length: number; width: number; height?: number; notes?: string }>;
  hazards: Array<{ type: string; location: string; severity: string; mitigation_needed?: boolean }>;
  accessNotes: string | null;
  photos: Array<{ path: string; caption?: string }>;
  status: string;
  completedAt: string | null;
  signaturePath: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

function mapSurvey(row: Record<string, unknown>): SiteSurvey {
  const job = row.jobs as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    jobId: (row.job_id as string) || null,
    jobTitle: (job?.title as string) || undefined,
    sketchId: (row.sketch_id as string) || null,
    title: row.title as string,
    surveyType: row.survey_type as string,
    surveyorId: (row.surveyor_id as string) || null,
    surveyorName: row.surveyor_name as string,
    propertyType: (row.property_type as string) || null,
    yearBuilt: (row.year_built as number) || null,
    stories: (row.stories as number) || 1,
    totalSqft: (row.total_sqft as number) || null,
    exteriorCondition: (row.exterior_condition as string) || null,
    interiorCondition: (row.interior_condition as string) || null,
    roofCondition: (row.roof_condition as string) || null,
    electricalService: (row.electrical_service as string) || null,
    plumbingType: (row.plumbing_type as string) || null,
    hvacType: (row.hvac_type as string) || null,
    conditions: (row.conditions as SiteSurvey['conditions']) || [],
    measurements: (row.measurements as SiteSurvey['measurements']) || [],
    hazards: (row.hazards as SiteSurvey['hazards']) || [],
    accessNotes: (row.access_notes as string) || null,
    photos: (row.photos as SiteSurvey['photos']) || [],
    status: row.status as string,
    completedAt: (row.completed_at as string) || null,
    signaturePath: (row.signature_path as string) || null,
    notes: (row.notes as string) || null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

export function useSiteSurveys() {
  const [surveys, setSurveys] = useState<SiteSurvey[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSurveys = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: fetchError } = await supabase
        .from('site_surveys')
        .select('*, jobs(title)')
        .order('created_at', { ascending: false })
        .limit(100);

      if (fetchError) throw fetchError;
      setSurveys((data || []).map(mapSurvey));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load surveys');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSurveys();

    const supabase = getSupabase();
    const channel = supabase
      .channel('site-surveys-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'site_surveys' }, () => fetchSurveys())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchSurveys]);

  const createSurvey = async (survey: { title: string; surveyType: string; surveyorName: string; jobId?: string; propertyType?: string }) => {
    const supabase = getSupabase();
    const { error: insertError } = await supabase
      .from('site_surveys')
      .insert({
        title: survey.title,
        survey_type: survey.surveyType,
        surveyor_name: survey.surveyorName,
        job_id: survey.jobId || null,
        property_type: survey.propertyType || null,
      });
    if (insertError) throw insertError;
    await fetchSurveys();
  };

  const updateSurvey = async (id: string, updates: Partial<{
    status: string;
    exteriorCondition: string;
    interiorCondition: string;
    roofCondition: string;
    conditions: SiteSurvey['conditions'];
    measurements: SiteSurvey['measurements'];
    hazards: SiteSurvey['hazards'];
    notes: string;
  }>) => {
    const supabase = getSupabase();
    const dbUpdates: Record<string, unknown> = {};
    if (updates.status) dbUpdates.status = updates.status;
    if (updates.exteriorCondition) dbUpdates.exterior_condition = updates.exteriorCondition;
    if (updates.interiorCondition) dbUpdates.interior_condition = updates.interiorCondition;
    if (updates.roofCondition) dbUpdates.roof_condition = updates.roofCondition;
    if (updates.conditions) dbUpdates.conditions = updates.conditions;
    if (updates.measurements) dbUpdates.measurements = updates.measurements;
    if (updates.hazards) dbUpdates.hazards = updates.hazards;
    if (updates.notes !== undefined) dbUpdates.notes = updates.notes;

    const { error: updateError } = await supabase
      .from('site_surveys')
      .update(dbUpdates)
      .eq('id', id);
    if (updateError) throw updateError;
    await fetchSurveys();
  };

  const drafts = surveys.filter(s => s.status === 'draft');
  const inProgress = surveys.filter(s => s.status === 'in_progress');
  const completed = surveys.filter(s => s.status === 'completed' || s.status === 'submitted');

  return {
    surveys, drafts, inProgress, completed,
    loading, error, fetchSurveys,
    createSurvey, updateSurvey,
  };
}
