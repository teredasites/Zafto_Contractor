'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type TrainingType = 'safety' | 'technical' | 'compliance' | 'onboarding' | 'continuing_education' | 'other';
export type TrainingStatus = 'assigned' | 'in_progress' | 'completed' | 'expired' | 'waived';

export interface TrainingRecord {
  id: string;
  userId: string;
  companyId: string;
  courseName: string;
  trainingType: TrainingType;
  status: TrainingStatus;
  provider: string;
  completedDate: string | null;
  expiresDate: string | null;
  score: number | null;
  certificateUrl: string | null;
  notes: string;
  createdAt: string;
}

export type ChecklistItemStatus = 'pending' | 'completed' | 'skipped' | 'na';

export interface OnboardingChecklistItem {
  id: string;
  checklistId: string;
  title: string;
  description: string;
  category: string;
  status: ChecklistItemStatus;
  completedAt: string | null;
  sortOrder: number;
}

export interface OnboardingChecklist {
  id: string;
  userId: string;
  companyId: string;
  templateName: string;
  startedAt: string;
  completedAt: string | null;
  items: OnboardingChecklistItem[];
  createdAt: string;
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapTrainingRecord(row: Record<string, unknown>): TrainingRecord {
  return {
    id: row.id as string,
    userId: row.user_id as string,
    companyId: row.company_id as string,
    courseName: (row.course_name as string) || '',
    trainingType: (row.training_type as TrainingType) || 'other',
    status: (row.status as TrainingStatus) || 'assigned',
    provider: (row.provider as string) || '',
    completedDate: (row.completed_date as string) || null,
    expiresDate: (row.expires_date as string) || null,
    score: row.score != null ? Number(row.score) : null,
    certificateUrl: (row.certificate_url as string) || null,
    notes: (row.notes as string) || '',
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

function mapChecklistItem(row: Record<string, unknown>): OnboardingChecklistItem {
  return {
    id: row.id as string,
    checklistId: row.checklist_id as string,
    title: (row.title as string) || '',
    description: (row.description as string) || '',
    category: (row.category as string) || 'general',
    status: (row.status as ChecklistItemStatus) || 'pending',
    completedAt: (row.completed_at as string) || null,
    sortOrder: (row.sort_order as number) || 0,
  };
}

function mapChecklist(row: Record<string, unknown>): OnboardingChecklist {
  const items = (row.onboarding_checklist_items as Record<string, unknown>[]) || [];
  return {
    id: row.id as string,
    userId: row.user_id as string,
    companyId: row.company_id as string,
    templateName: (row.template_name as string) || 'Onboarding',
    startedAt: (row.started_at as string) || '',
    completedAt: (row.completed_at as string) || null,
    items: items.map(mapChecklistItem).sort((a, b) => a.sortOrder - b.sortOrder),
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

// ============================================================================
// HOOK: useMyTraining (team portal — scoped to current user)
// ============================================================================

export function useMyTraining() {
  const [trainingRecords, setTrainingRecords] = useState<TrainingRecord[]>([]);
  const [checklists, setChecklists] = useState<OnboardingChecklist[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const [trainingRes, checklistRes] = await Promise.all([
        supabase
          .from('training_records')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', { ascending: false }),
        supabase
          .from('onboarding_checklists')
          .select('*, onboarding_checklist_items(*)')
          .eq('user_id', user.id)
          .order('created_at', { ascending: false }),
      ]);

      if (trainingRes.error) throw trainingRes.error;
      if (checklistRes.error) throw checklistRes.error;

      setTrainingRecords((trainingRes.data || []).map((row: Record<string, unknown>) => mapTrainingRecord(row)));
      setChecklists((checklistRes.data || []).map((row: Record<string, unknown>) => mapChecklist(row)));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load training data';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();

    const supabase = getSupabase();
    const channel = supabase
      .channel('team-training')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'training_records' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'onboarding_checklists' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'onboarding_checklist_items' }, () => fetchData())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchData]);

  // Computed: expiring soon (within 60 days)
  const expiringSoon = useMemo(() => {
    const now = Date.now();
    const sixtyDaysMs = 60 * 24 * 60 * 60 * 1000;
    return trainingRecords.filter(t => {
      if (!t.expiresDate) return false;
      const expiresMs = new Date(t.expiresDate).getTime();
      const daysUntil = expiresMs - now;
      return daysUntil > 0 && daysUntil <= sixtyDaysMs;
    }).sort((a, b) => {
      const aTime = new Date(a.expiresDate!).getTime();
      const bTime = new Date(b.expiresDate!).getTime();
      return aTime - bTime;
    });
  }, [trainingRecords]);

  const completedTraining = useMemo(() =>
    trainingRecords.filter(t => t.status === 'completed'),
    [trainingRecords]
  );

  const activeTraining = useMemo(() =>
    trainingRecords.filter(t => t.status === 'assigned' || t.status === 'in_progress'),
    [trainingRecords]
  );

  // Incomplete checklists
  const incompleteChecklists = useMemo(() =>
    checklists.filter(c => !c.completedAt),
    [checklists]
  );

  return {
    trainingRecords, checklists,
    expiringSoon, completedTraining, activeTraining, incompleteChecklists,
    loading, error,
    refetch: fetchData,
  };
}

// ============================================================================
// HELPERS
// ============================================================================

export const TRAINING_TYPE_LABELS: Record<TrainingType, string> = {
  safety: 'Safety',
  technical: 'Technical',
  compliance: 'Compliance',
  onboarding: 'Onboarding',
  continuing_education: 'Continuing Ed',
  other: 'Other',
};

export const TRAINING_TYPE_COLORS: Record<TrainingType, { bg: string; text: string }> = {
  safety: { bg: 'bg-red-100 dark:bg-red-900/30', text: 'text-red-700 dark:text-red-300' },
  technical: { bg: 'bg-blue-100 dark:bg-blue-900/30', text: 'text-blue-700 dark:text-blue-300' },
  compliance: { bg: 'bg-purple-100 dark:bg-purple-900/30', text: 'text-purple-700 dark:text-purple-300' },
  onboarding: { bg: 'bg-emerald-100 dark:bg-emerald-900/30', text: 'text-emerald-700 dark:text-emerald-300' },
  continuing_education: { bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-700 dark:text-amber-300' },
  other: { bg: 'bg-slate-100 dark:bg-slate-900/30', text: 'text-slate-700 dark:text-slate-300' },
};
