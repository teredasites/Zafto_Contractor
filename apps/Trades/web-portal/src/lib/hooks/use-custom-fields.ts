'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Custom Fields Hook — CRUD + dynamic form rendering
// ============================================================

export type EntityType = 'customer' | 'job' | 'bid' | 'invoice' | 'expense' | 'employee';
export type FieldType = 'text' | 'number' | 'date' | 'boolean' | 'select' | 'multi_select' | 'file' | 'email' | 'phone' | 'url' | 'textarea';

export interface CustomField {
  id: string;
  companyId: string;
  entityType: EntityType;
  fieldName: string;
  fieldLabel: string;
  fieldType: FieldType;
  options: string[] | null;
  required: boolean;
  displayOrder: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

interface RawCustomField {
  id: string;
  company_id: string;
  entity_type: string;
  field_name: string;
  field_label: string;
  field_type: string;
  options: string[] | null;
  required: boolean;
  display_order: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

function mapCustomField(raw: RawCustomField): CustomField {
  return {
    id: raw.id,
    companyId: raw.company_id,
    entityType: raw.entity_type as EntityType,
    fieldName: raw.field_name,
    fieldLabel: raw.field_label,
    fieldType: raw.field_type as FieldType,
    options: raw.options,
    required: raw.required,
    displayOrder: raw.display_order,
    isActive: raw.is_active,
    createdAt: raw.created_at,
    updatedAt: raw.updated_at,
  };
}

export function useCustomFields(entityType?: EntityType) {
  const [fields, setFields] = useState<CustomField[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchFields = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      let query = supabase
        .from('custom_fields')
        .select('*')
        .is('deleted_at', null)
        .order('display_order', { ascending: true });

      if (entityType) {
        query = query.eq('entity_type', entityType);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setFields((data || []).map((r: RawCustomField) => mapCustomField(r)));
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load custom fields');
    } finally {
      setLoading(false);
    }
  }, [entityType]);

  useEffect(() => {
    fetchFields();
  }, [fetchFields]);

  // Real-time subscription
  useEffect(() => {
    const supabase = getSupabase();
    const channel = supabase
      .channel('custom-fields-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'custom_fields' }, () => {
        fetchFields();
      })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchFields]);

  const createField = useCallback(async (input: {
    entityType: EntityType;
    fieldName: string;
    fieldLabel: string;
    fieldType: FieldType;
    options?: string[];
    required?: boolean;
    displayOrder?: number;
  }) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { data, error: err } = await supabase
      .from('custom_fields')
      .insert({
        company_id: companyId,
        entity_type: input.entityType,
        field_name: input.fieldName,
        field_label: input.fieldLabel,
        field_type: input.fieldType,
        options: input.options || null,
        required: input.required || false,
        display_order: input.displayOrder ?? fields.length,
      })
      .select()
      .single();
    if (err) throw err;
    return mapCustomField(data);
  }, [fields.length]);

  const updateField = useCallback(async (id: string, updates: Partial<{
    fieldLabel: string;
    fieldType: FieldType;
    options: string[] | null;
    required: boolean;
    displayOrder: number;
    isActive: boolean;
  }>) => {
    const supabase = getSupabase();
    const payload: Record<string, unknown> = {};
    if (updates.fieldLabel !== undefined) payload.field_label = updates.fieldLabel;
    if (updates.fieldType !== undefined) payload.field_type = updates.fieldType;
    if (updates.options !== undefined) payload.options = updates.options;
    if (updates.required !== undefined) payload.required = updates.required;
    if (updates.displayOrder !== undefined) payload.display_order = updates.displayOrder;
    if (updates.isActive !== undefined) payload.is_active = updates.isActive;

    const { error: err } = await supabase
      .from('custom_fields')
      .update(payload)
      .eq('id', id);
    if (err) throw err;
  }, []);

  const deleteField = useCallback(async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('custom_fields')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  }, []);

  const reorderFields = useCallback(async (orderedIds: string[]) => {
    const supabase = getSupabase();
    const updates = orderedIds.map((id, i) =>
      supabase.from('custom_fields').update({ display_order: i }).eq('id', id)
    );
    await Promise.all(updates);
    fetchFields();
  }, [fetchFields]);

  // Group fields by entity type
  const fieldsByEntity = useMemo(() => {
    const grouped: Record<EntityType, CustomField[]> = {
      customer: [], job: [], bid: [], invoice: [], expense: [], employee: [],
    };
    fields.forEach((f) => {
      if (grouped[f.entityType]) grouped[f.entityType].push(f);
    });
    return grouped;
  }, [fields]);

  return {
    fields,
    fieldsByEntity,
    loading,
    error,
    createField,
    updateField,
    deleteField,
    reorderFields,
    refetch: fetchFields,
  };
}
