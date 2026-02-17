'use client';

// ZAFTO — Fire Restoration Hook
// Created: Sprint REST1 (Session 131)
//
// CRUD for fire_assessments + content_packout_items tables.
// Realtime subscriptions. Soot types, odor treatment, board-up, pack-out stats.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// =============================================================================
// TYPES
// =============================================================================

export type DamageSeverity = 'minor' | 'moderate' | 'major' | 'total_loss';
export type DamageZoneType = 'direct_flame' | 'smoke' | 'heat' | 'water_suppression';
export type SootType = 'wet_smoke' | 'dry_smoke' | 'protein' | 'fuel_oil' | 'mixed';
export type OdorTreatmentMethod = 'thermal_fog' | 'ozone' | 'hydroxyl' | 'air_scrub' | 'sealer';
export type AssessmentStatus = 'in_progress' | 'pending_review' | 'approved' | 'submitted_to_carrier';
export type ContentCategory = 'electronics' | 'soft_goods' | 'hard_goods' | 'documents' | 'artwork' | 'furniture' | 'clothing' | 'appliances' | 'kitchenware' | 'personal' | 'tools' | 'sporting' | 'other';
export type ContentCondition = 'salvageable' | 'non_salvageable' | 'needs_cleaning' | 'needs_restoration' | 'questionable';
export type CleaningMethod = 'dry_clean' | 'wet_clean' | 'ultrasonic' | 'ozone' | 'immersion' | 'soda_blast' | 'dry_ice_blast' | 'hand_wipe' | 'laundry' | 'none';

export interface DamageZone {
  room: string;
  zone_type: DamageZoneType;
  severity: 'light' | 'moderate' | 'heavy';
  soot_type?: SootType;
  notes?: string;
  photos: string[];
}

export interface SootAssessment {
  room: string;
  soot_type: SootType;
  surface_types: string[];
  cleaning_method: string;
  notes?: string;
}

export interface OdorTreatment {
  method: OdorTreatmentMethod;
  room: string;
  start_time?: string;
  end_time?: string;
  equipment_id?: string;
  pre_reading?: number;
  post_reading?: number;
  notes?: string;
}

export interface BoardUpEntry {
  opening_type: string;
  location: string;
  material?: string;
  dimensions?: string;
  photo_before?: string;
  photo_after?: string;
  secured_by?: string;
  secured_at?: string;
}

export interface FireAssessment {
  id: string;
  companyId: string;
  jobId: string;
  insuranceClaimId: string | null;
  createdByUserId: string | null;
  originRoom: string | null;
  originDescription: string | null;
  fireDepartmentReportNumber: string | null;
  fireDepartmentName: string | null;
  dateOfLoss: string | null;
  damageSeverity: DamageSeverity;
  structuralCompromise: boolean;
  roofDamage: boolean;
  foundationDamage: boolean;
  loadBearingAffected: boolean;
  structuralNotes: string | null;
  damageZones: DamageZone[];
  sootAssessments: SootAssessment[];
  odorTreatments: OdorTreatment[];
  boardUpEntries: BoardUpEntry[];
  airQualityReadings: Record<string, unknown>[];
  waterDamageFromSuppression: boolean;
  photos: Record<string, unknown>[];
  assessmentStatus: AssessmentStatus;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ContentPackoutItem {
  id: string;
  companyId: string;
  fireAssessmentId: string;
  jobId: string;
  itemDescription: string;
  roomOfOrigin: string;
  category: ContentCategory;
  condition: ContentCondition;
  cleaningMethod: CleaningMethod | null;
  boxNumber: string | null;
  storageLocation: string | null;
  packedAt: string | null;
  returnedAt: string | null;
  returnedTo: string | null;
  estimatedValue: number | null;
  replacementCost: number | null;
  actualCashValue: number | null;
  photoUrls: string[];
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

// =============================================================================
// SOOT REFERENCE DATA
// =============================================================================

export const SOOT_TYPE_INFO: Record<SootType, {
  label: string;
  description: string;
  cleaningMethod: string;
}> = {
  wet_smoke: {
    label: 'Wet Smoke',
    description: 'Low heat, smoldering — thick, sticky, pungent residue. Hard to clean.',
    cleaningMethod: 'Degreaser + multiple passes, avoid spreading. May need encapsulant.',
  },
  dry_smoke: {
    label: 'Dry Smoke',
    description: 'High heat, fast burn — dry, powdery, non-smeary. Easier to clean.',
    cleaningMethod: 'Dry sponge first, then wet wipe. Do NOT wet first (smears).',
  },
  protein: {
    label: 'Protein',
    description: 'Cooking fire — nearly invisible residue, extreme odor, discolors paints.',
    cleaningMethod: 'Enzyme-based cleaner. Standard cleaners spread residue. May need repaint.',
  },
  fuel_oil: {
    label: 'Fuel Oil',
    description: 'Petroleum product — thick, black, sticky. Requires specialized solvents.',
    cleaningMethod: 'Solvent-based cleaner. Heavy PPE. Multiple passes. Seal afterward.',
  },
  mixed: {
    label: 'Mixed',
    description: 'Multiple soot types present — requires layered cleaning approach.',
    cleaningMethod: 'Test each surface. Start with least aggressive method, escalate as needed.',
  },
};

// =============================================================================
// MAPPERS
// =============================================================================

function mapAssessment(row: Record<string, unknown>): FireAssessment {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    jobId: row.job_id as string,
    insuranceClaimId: (row.insurance_claim_id as string) || null,
    createdByUserId: (row.created_by_user_id as string) || null,
    originRoom: (row.origin_room as string) || null,
    originDescription: (row.origin_description as string) || null,
    fireDepartmentReportNumber: (row.fire_department_report_number as string) || null,
    fireDepartmentName: (row.fire_department_name as string) || null,
    dateOfLoss: (row.date_of_loss as string) || null,
    damageSeverity: (row.damage_severity as DamageSeverity) || 'moderate',
    structuralCompromise: (row.structural_compromise as boolean) || false,
    roofDamage: (row.roof_damage as boolean) || false,
    foundationDamage: (row.foundation_damage as boolean) || false,
    loadBearingAffected: (row.load_bearing_affected as boolean) || false,
    structuralNotes: (row.structural_notes as string) || null,
    damageZones: (row.damage_zones as DamageZone[]) || [],
    sootAssessments: (row.soot_assessments as SootAssessment[]) || [],
    odorTreatments: (row.odor_treatments as OdorTreatment[]) || [],
    boardUpEntries: (row.board_up_entries as BoardUpEntry[]) || [],
    airQualityReadings: (row.air_quality_readings as Record<string, unknown>[]) || [],
    waterDamageFromSuppression: (row.water_damage_from_suppression as boolean) || false,
    photos: (row.photos as Record<string, unknown>[]) || [],
    assessmentStatus: (row.assessment_status as AssessmentStatus) || 'in_progress',
    notes: (row.notes as string) || null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapPackoutItem(row: Record<string, unknown>): ContentPackoutItem {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    fireAssessmentId: row.fire_assessment_id as string,
    jobId: row.job_id as string,
    itemDescription: row.item_description as string,
    roomOfOrigin: row.room_of_origin as string,
    category: (row.category as ContentCategory) || 'other',
    condition: (row.condition as ContentCondition) || 'needs_cleaning',
    cleaningMethod: (row.cleaning_method as CleaningMethod) || null,
    boxNumber: (row.box_number as string) || null,
    storageLocation: (row.storage_location as string) || null,
    packedAt: (row.packed_at as string) || null,
    returnedAt: (row.returned_at as string) || null,
    returnedTo: (row.returned_to as string) || null,
    estimatedValue: (row.estimated_value as number) || null,
    replacementCost: (row.replacement_cost as number) || null,
    actualCashValue: (row.actual_cash_value as number) || null,
    photoUrls: (row.photo_urls as string[]) || [],
    notes: (row.notes as string) || null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

// =============================================================================
// HOOK: useFireRestoration
// =============================================================================

export function useFireRestoration() {
  const [assessments, setAssessments] = useState<FireAssessment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAssessments = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { data, error: err } = await supabase
        .from('fire_assessments')
        .select('*')
        .eq('company_id', user.app_metadata?.company_id)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setAssessments((data || []).map((row: Record<string, unknown>) => mapAssessment(row)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load fire assessments');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAssessments();
  }, [fetchAssessments]);

  // Realtime
  useEffect(() => {
    const supabase = getSupabase();
    const channel = supabase
      .channel('fire-assessment-changes')
      .on(
        'postgres_changes' as 'system',
        {
          event: '*',
          schema: 'public',
          table: 'fire_assessments',
        } as Record<string, unknown>,
        () => { fetchAssessments(); }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchAssessments]);

  const createAssessment = async (input: {
    jobId: string;
    insuranceClaimId?: string;
    originRoom?: string;
    originDescription?: string;
    damageSeverity?: DamageSeverity;
  }): Promise<void> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error: err } = await supabase.from('fire_assessments').insert({
      company_id: user.app_metadata?.company_id,
      job_id: input.jobId,
      insurance_claim_id: input.insuranceClaimId || null,
      created_by_user_id: user.id,
      origin_room: input.originRoom || null,
      origin_description: input.originDescription || null,
      damage_severity: input.damageSeverity || 'moderate',
      assessment_status: 'in_progress',
    });

    if (err) throw err;
    await fetchAssessments();
  };

  const updateAssessment = async (
    id: string,
    updates: Partial<Record<string, unknown>>
  ): Promise<void> => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('fire_assessments')
      .update(updates)
      .eq('id', id);

    if (err) throw err;
    await fetchAssessments();
  };

  const deleteAssessment = async (id: string): Promise<void> => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('fire_assessments')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);

    if (err) throw err;
    await fetchAssessments();
  };

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

// =============================================================================
// HOOK: useContentPackout
// =============================================================================

export function useContentPackout(assessmentId: string | null) {
  const [items, setItems] = useState<ContentPackoutItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchItems = useCallback(async () => {
    if (!assessmentId) {
      setItems([]);
      setLoading(false);
      return;
    }
    try {
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('content_packout_items')
        .select('*')
        .eq('fire_assessment_id', assessmentId)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setItems((data || []).map((row: Record<string, unknown>) => mapPackoutItem(row)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load packout items');
    } finally {
      setLoading(false);
    }
  }, [assessmentId]);

  useEffect(() => {
    fetchItems();
  }, [fetchItems]);

  // Realtime
  useEffect(() => {
    if (!assessmentId) return;
    const supabase = getSupabase();
    const channel = supabase
      .channel('content-packout-changes')
      .on(
        'postgres_changes' as 'system',
        {
          event: '*',
          schema: 'public',
          table: 'content_packout_items',
        } as Record<string, unknown>,
        () => { fetchItems(); }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [assessmentId, fetchItems]);

  const addItem = async (input: {
    jobId: string;
    itemDescription: string;
    roomOfOrigin: string;
    category?: ContentCategory;
    condition?: ContentCondition;
    boxNumber?: string;
    estimatedValue?: number;
  }): Promise<void> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error: err } = await supabase.from('content_packout_items').insert({
      company_id: user.app_metadata?.company_id,
      fire_assessment_id: assessmentId,
      job_id: input.jobId,
      item_description: input.itemDescription,
      room_of_origin: input.roomOfOrigin,
      category: input.category || 'other',
      condition: input.condition || 'needs_cleaning',
      box_number: input.boxNumber || null,
      estimated_value: input.estimatedValue || null,
    });

    if (err) throw err;
    await fetchItems();
  };

  const updateItem = async (
    id: string,
    updates: Partial<Record<string, unknown>>
  ): Promise<void> => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('content_packout_items')
      .update(updates)
      .eq('id', id);

    if (err) throw err;
    await fetchItems();
  };

  const deleteItem = async (id: string): Promise<void> => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('content_packout_items')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);

    if (err) throw err;
    await fetchItems();
  };

  // Stats
  const stats = {
    totalItems: items.length,
    packed: items.filter(i => i.packedAt !== null).length,
    returned: items.filter(i => i.returnedAt !== null).length,
    salvageable: items.filter(i =>
      i.condition === 'salvageable' || i.condition === 'needs_cleaning' || i.condition === 'needs_restoration'
    ).length,
    totalEstimatedValue: items.reduce((sum, i) => sum + (i.estimatedValue || 0), 0),
    totalReplacementCost: items.reduce((sum, i) => sum + (i.replacementCost || 0), 0),
  };

  return {
    items,
    loading,
    error,
    stats,
    refetch: fetchItems,
    addItem,
    updateItem,
    deleteItem,
  };
}
