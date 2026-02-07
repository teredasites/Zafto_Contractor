'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ==================== INTERFACES ====================

export interface ChecklistItem {
  label: string;
  required: boolean;
}

export interface CustomFieldDef {
  label: string;
  type: 'text' | 'number' | 'select' | 'checkbox' | 'rating';
  required: boolean;
  options?: string[];
  defaultValue?: string;
}

export interface TemplateRoom {
  name: string;
  roomType: string;
  requiredPhotos: number;
  customFields: Record<string, CustomFieldDef>;
  checklist: ChecklistItem[];
}

export interface WalkthroughTemplate {
  id: string;
  companyId: string | null;
  name: string;
  description: string;
  walkthroughType: string;
  propertyType: string;
  rooms: TemplateRoom[];
  customFields: Record<string, CustomFieldDef>;
  checklist: ChecklistItem[];
  aiInstructions: string;
  isSystem: boolean;
  usageCount: number;
  createdAt: string;
  updatedAt: string;
}

// ==================== MAPPERS ====================

function mapTemplateFromDb(row: Record<string, unknown>): WalkthroughTemplate {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || null,
    name: (row.name as string) || '',
    description: (row.description as string) || '',
    walkthroughType: (row.walkthrough_type as string) || 'general',
    propertyType: (row.property_type as string) || 'residential',
    rooms: (row.rooms as TemplateRoom[]) || [],
    customFields: (row.custom_fields as Record<string, CustomFieldDef>) || {},
    checklist: (row.checklist as ChecklistItem[]) || [],
    aiInstructions: (row.ai_instructions as string) || '',
    isSystem: (row.is_system as boolean) || false,
    usageCount: Number(row.usage_count) || 0,
    createdAt: (row.created_at as string) || '',
    updatedAt: (row.updated_at as string) || '',
  };
}

function mapTemplateToDb(data: Partial<WalkthroughTemplate>): Record<string, unknown> {
  const result: Record<string, unknown> = {};

  if (data.name !== undefined) result.name = data.name;
  if (data.description !== undefined) result.description = data.description;
  if (data.walkthroughType !== undefined) result.walkthrough_type = data.walkthroughType;
  if (data.propertyType !== undefined) result.property_type = data.propertyType;
  if (data.rooms !== undefined) result.rooms = data.rooms;
  if (data.customFields !== undefined) result.custom_fields = data.customFields;
  if (data.checklist !== undefined) result.checklist = data.checklist;
  if (data.aiInstructions !== undefined) result.ai_instructions = data.aiInstructions;

  return result;
}

// ==================== HOOK ====================

export function useWalkthroughTemplates() {
  const [templates, setTemplates] = useState<WalkthroughTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTemplates = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Fetch system templates (company_id IS NULL) + company templates
      const { data: { user } } = await supabase.auth.getUser();
      const companyId = user?.app_metadata?.company_id;

      let query = supabase
        .from('walkthrough_templates')
        .select('*')
        .order('is_system', { ascending: false })
        .order('name', { ascending: true });

      if (companyId) {
        query = query.or(`is_system.eq.true,company_id.eq.${companyId}`);
      } else {
        query = query.eq('is_system', true);
      }

      const { data, error: err } = await query;

      if (err) throw err;
      const rows: Record<string, unknown>[] = data || [];
      setTemplates(rows.map(mapTemplateFromDb));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load templates';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTemplates();

    const supabase = getSupabase();
    const channel = supabase
      .channel('walkthrough-templates-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'walkthrough_templates' }, () => {
        fetchTemplates();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchTemplates]);

  const createTemplate = async (data: Partial<WalkthroughTemplate>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const insertData = {
      company_id: companyId,
      name: data.name || 'Untitled Template',
      description: data.description || '',
      walkthrough_type: data.walkthroughType || 'general',
      property_type: data.propertyType || 'residential',
      rooms: data.rooms || [],
      custom_fields: data.customFields || {},
      checklist: data.checklist || [],
      ai_instructions: data.aiInstructions || '',
      is_system: false,
      usage_count: 0,
    };

    const { data: result, error: err } = await supabase
      .from('walkthrough_templates')
      .insert(insertData)
      .select('id')
      .single();

    if (err) throw err;
    const row = result as { id: string };
    return row.id;
  };

  const updateTemplate = async (id: string, data: Partial<WalkthroughTemplate>) => {
    const supabase = getSupabase();
    const updateData = mapTemplateToDb(data);

    const { error: err } = await supabase
      .from('walkthrough_templates')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;
  };

  const deleteTemplate = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('walkthrough_templates')
      .delete()
      .eq('id', id);

    if (err) throw err;
  };

  const cloneTemplate = async (templateId: string, newName: string): Promise<string> => {
    const source = templates.find((t) => t.id === templateId);
    if (!source) throw new Error('Template not found');

    return createTemplate({
      name: newName,
      description: source.description,
      walkthroughType: source.walkthroughType,
      propertyType: source.propertyType,
      rooms: JSON.parse(JSON.stringify(source.rooms)),
      customFields: JSON.parse(JSON.stringify(source.customFields)),
      checklist: JSON.parse(JSON.stringify(source.checklist)),
      aiInstructions: source.aiInstructions,
    });
  };

  return {
    templates,
    loading,
    error,
    createTemplate,
    updateTemplate,
    deleteTemplate,
    cloneTemplate,
    refetch: fetchTemplates,
  };
}
