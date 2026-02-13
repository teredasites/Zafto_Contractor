'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { createClient } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type DocPhase = 'initial_inspection' | 'during_work' | 'daily_monitoring' | 'completion' | 'closeout';
export type EvidenceType = 'photo' | 'document' | 'signature' | 'reading' | 'form' | 'any';

export interface DocChecklistItemData {
  id: string;
  templateId: string;
  phase: DocPhase;
  itemName: string;
  description: string | null;
  isRequired: boolean;
  evidenceType: EvidenceType;
  minCount: number;
  sortOrder: number;
}

export interface DocProgressData {
  id: string;
  companyId: string;
  jobId: string;
  tpaAssignmentId: string | null;
  checklistItemId: string;
  isComplete: boolean;
  completedAt: string | null;
  completedByUserId: string | null;
  evidenceCount: number;
  evidenceNotes: string | null;
  photoPhase: string | null;
  evidencePaths: string[];
  createdAt: string;
}

export interface CertificateOfCompletionData {
  id: string;
  companyId: string;
  jobId: string;
  tpaAssignmentId: string | null;
  scopeSummary: string;
  workPerformed: string;
  startDate: string;
  completionDate: string;
  allAreasDry: boolean;
  finalMoistureReadingsVerified: boolean;
  dryingGoalMet: boolean;
  totalInvoiced: number | null;
  totalPaid: number | null;
  lienWaiverSigned: boolean;
  technicianSignedAt: string | null;
  customerSignedAt: string | null;
  customerName: string | null;
  satisfactionRating: number | null;
  satisfactionFeedback: string | null;
  wouldRecommend: boolean | null;
  status: string;
  createdAt: string;
}

export interface PhaseProgress {
  phase: DocPhase;
  totalItems: number;
  completedItems: number;
  requiredItems: number;
  requiredCompleted: number;
  percentage: number;
}

export interface ValidationSummary {
  totalItems: number;
  completedItems: number;
  requiredTotal: number;
  requiredCompleted: number;
  compliancePercentage: number;
  isFullyCompliant: boolean;
  phases: PhaseProgress[];
}

// ============================================================================
// MAPPERS
// ============================================================================

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapChecklistItem(row: any): DocChecklistItemData {
  return {
    id: row.id,
    templateId: row.template_id,
    phase: row.phase,
    itemName: row.item_name,
    description: row.description ?? null,
    isRequired: row.is_required ?? true,
    evidenceType: row.evidence_type ?? 'any',
    minCount: row.min_count ?? 1,
    sortOrder: row.sort_order ?? 0,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapProgress(row: any): DocProgressData {
  return {
    id: row.id,
    companyId: row.company_id,
    jobId: row.job_id,
    tpaAssignmentId: row.tpa_assignment_id ?? null,
    checklistItemId: row.checklist_item_id,
    isComplete: row.is_complete ?? false,
    completedAt: row.completed_at ?? null,
    completedByUserId: row.completed_by_user_id ?? null,
    evidenceCount: row.evidence_count ?? 0,
    evidenceNotes: row.evidence_notes ?? null,
    photoPhase: row.photo_phase ?? null,
    evidencePaths: row.evidence_paths ?? [],
    createdAt: row.created_at,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapCoc(row: any): CertificateOfCompletionData {
  return {
    id: row.id,
    companyId: row.company_id,
    jobId: row.job_id,
    tpaAssignmentId: row.tpa_assignment_id ?? null,
    scopeSummary: row.scope_summary,
    workPerformed: row.work_performed,
    startDate: row.start_date,
    completionDate: row.completion_date,
    allAreasDry: row.all_areas_dry ?? false,
    finalMoistureReadingsVerified: row.final_moisture_readings_verified ?? false,
    dryingGoalMet: row.drying_goal_met ?? false,
    totalInvoiced: row.total_invoiced != null ? parseFloat(row.total_invoiced) : null,
    totalPaid: row.total_paid != null ? parseFloat(row.total_paid) : null,
    lienWaiverSigned: row.lien_waiver_signed ?? false,
    technicianSignedAt: row.technician_signed_at ?? null,
    customerSignedAt: row.customer_signed_at ?? null,
    customerName: row.customer_name ?? null,
    satisfactionRating: row.satisfaction_rating ?? null,
    satisfactionFeedback: row.satisfaction_feedback ?? null,
    wouldRecommend: row.would_recommend ?? null,
    status: row.status,
    createdAt: row.created_at,
  };
}

// ============================================================================
// HOOKS
// ============================================================================

const PHASE_ORDER: DocPhase[] = ['initial_inspection', 'during_work', 'daily_monitoring', 'completion', 'closeout'];

export function useDocumentationValidation(jobId: string | null, jobType?: string) {
  const [checklistItems, setChecklistItems] = useState<DocChecklistItemData[]>([]);
  const [progress, setProgress] = useState<DocProgressData[]>([]);
  const [coc, setCoc] = useState<CertificateOfCompletionData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!jobId) { setChecklistItems([]); setProgress([]); setCoc(null); setLoading(false); return; }
    try {
      setLoading(true);
      setError(null);
      const supabase = createClient();

      // Get template for job type
      const mappedType = mapJobType(jobType || 'general_restoration');
      const { data: templates } = await supabase
        .from('doc_checklist_templates')
        .select('id')
        .eq('job_type', mappedType)
        .eq('is_active', true)
        .order('is_system_default', { ascending: true })
        .limit(1);

      const templateId = templates?.[0]?.id;
      if (!templateId) {
        setChecklistItems([]);
        setProgress([]);
        setLoading(false);
        return;
      }

      const [itemsRes, progressRes, cocRes] = await Promise.all([
        supabase
          .from('doc_checklist_items')
          .select('*')
          .eq('template_id', templateId)
          .order('sort_order'),
        supabase
          .from('job_doc_progress')
          .select('*')
          .eq('job_id', jobId)
          .order('created_at'),
        supabase
          .from('certificates_of_completion')
          .select('*')
          .eq('job_id', jobId)
          .order('created_at', { ascending: false })
          .limit(1),
      ]);

      if (itemsRes.error) throw itemsRes.error;
      if (progressRes.error) throw progressRes.error;

      setChecklistItems((itemsRes.data || []).map(mapChecklistItem));
      setProgress((progressRes.data || []).map(mapProgress));
      setCoc(cocRes.data?.[0] ? mapCoc(cocRes.data[0]) : null);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load documentation data');
    } finally {
      setLoading(false);
    }
  }, [jobId, jobType]);

  useEffect(() => {
    fetch();
    if (!jobId) return;
    const supabase = createClient();
    const channel = supabase
      .channel(`doc-validation-${jobId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'job_doc_progress', filter: `job_id=eq.${jobId}` }, () => { fetch(); })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'certificates_of_completion', filter: `job_id=eq.${jobId}` }, () => { fetch(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetch, jobId]);

  const validation = useMemo<ValidationSummary>(() => {
    const progressMap = new Map(progress.map(p => [p.checklistItemId, p]));
    const phases: PhaseProgress[] = [];

    for (const phase of PHASE_ORDER) {
      const phaseItems = checklistItems.filter(i => i.phase === phase);
      if (phaseItems.length === 0) continue;

      const required = phaseItems.filter(i => i.isRequired);
      let completed = 0;
      let reqCompleted = 0;

      for (const item of phaseItems) {
        const prog = progressMap.get(item.id);
        if (prog?.isComplete && prog.evidenceCount >= item.minCount) {
          completed++;
          if (item.isRequired) reqCompleted++;
        }
      }

      phases.push({
        phase,
        totalItems: phaseItems.length,
        completedItems: completed,
        requiredItems: required.length,
        requiredCompleted: reqCompleted,
        percentage: required.length > 0 ? Math.round((reqCompleted / required.length) * 100) : 100,
      });
    }

    const totalItems = phases.reduce((s, p) => s + p.totalItems, 0);
    const completedItems = phases.reduce((s, p) => s + p.completedItems, 0);
    const requiredTotal = phases.reduce((s, p) => s + p.requiredItems, 0);
    const requiredCompleted = phases.reduce((s, p) => s + p.requiredCompleted, 0);

    return {
      totalItems,
      completedItems,
      requiredTotal,
      requiredCompleted,
      compliancePercentage: requiredTotal > 0 ? Math.round((requiredCompleted / requiredTotal) * 100) : 100,
      isFullyCompliant: requiredCompleted === requiredTotal,
      phases,
    };
  }, [checklistItems, progress]);

  const markComplete = async (checklistItemId: string, evidencePaths?: string[], photoPhase?: string): Promise<void> => {
    if (!jobId) return;
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const existing = progress.find(p => p.checklistItemId === checklistItemId);
    if (existing) {
      await supabase
        .from('job_doc_progress')
        .update({
          is_complete: true,
          completed_at: new Date().toISOString(),
          completed_by_user_id: user.id,
          evidence_count: (existing.evidenceCount || 0) + (evidencePaths?.length || 0),
          evidence_paths: [...(existing.evidencePaths || []), ...(evidencePaths || [])],
          photo_phase: photoPhase ?? existing.photoPhase,
        })
        .eq('id', existing.id);
    } else {
      await supabase
        .from('job_doc_progress')
        .insert({
          company_id: companyId,
          job_id: jobId,
          checklist_item_id: checklistItemId,
          is_complete: true,
          completed_at: new Date().toISOString(),
          completed_by_user_id: user.id,
          evidence_count: evidencePaths?.length || 0,
          evidence_paths: evidencePaths || [],
          photo_phase: photoPhase ?? null,
        });
    }
  };

  const markIncomplete = async (checklistItemId: string): Promise<void> => {
    const existing = progress.find(p => p.checklistItemId === checklistItemId);
    if (!existing) return;
    const supabase = createClient();
    await supabase
      .from('job_doc_progress')
      .update({ is_complete: false, completed_at: null })
      .eq('id', existing.id);
  };

  return {
    checklistItems,
    progress,
    coc,
    validation,
    loading,
    error,
    markComplete,
    markIncomplete,
    refetch: fetch,
  };
}

function mapJobType(type: string): string {
  const t = type.toLowerCase();
  if (t.includes('water') || t.includes('flood') || t.includes('mitigation')) return 'water_mitigation';
  if (t.includes('fire') || t.includes('smoke')) return 'fire_restoration';
  if (t.includes('mold')) return 'mold_remediation';
  if (t.includes('roof')) return 'roofing_claim';
  if (t.includes('contents') || t.includes('pack')) return 'contents_packout';
  return 'general_restoration';
}
