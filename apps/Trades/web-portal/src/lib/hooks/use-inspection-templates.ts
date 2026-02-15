'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface InspectionTemplateData {
  id: string;
  companyId: string | null;
  trade: string | null;
  category: string;
  name: string;
  description: string | null;
  sections: Array<{
    name: string;
    items: Array<{
      name: string;
      description?: string;
      weight: number;
      requiresPhotoOnFail?: boolean;
    }>;
  }>;
  inspectionType: string;
  isSystem: boolean;
  isActive: boolean;
  createdAt: string;
}

function mapTemplate(row: Record<string, unknown>): InspectionTemplateData {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || null,
    trade: (row.trade as string) || null,
    category: (row.category as string) || 'inspection',
    name: row.name as string,
    description: (row.description as string) || null,
    sections: (row.sections as InspectionTemplateData['sections']) || [],
    inspectionType: (row.inspection_type as string) || 'general',
    isSystem: (row.is_system as boolean) || false,
    isActive: (row.is_active as boolean) ?? true,
    createdAt: (row.created_at as string) || '',
  };
}

export function useInspectionTemplates() {
  const [templates, setTemplates] = useState<InspectionTemplateData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTemplates = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('inspection_templates')
        .select('*')
        .order('name');

      if (err) throw err;
      setTemplates((data || []).map(mapTemplate));
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
      .channel('inspection-templates-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'inspection_templates' }, () => {
        fetchTemplates();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchTemplates]);

  const createTemplate = async (input: {
    name: string;
    description?: string;
    trade?: string;
    category?: string;
    inspectionType?: string;
    sections: InspectionTemplateData['sections'];
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('inspection_templates')
      .insert({
        company_id: companyId,
        name: input.name,
        description: input.description || null,
        trade: input.trade || null,
        category: input.category || 'inspection',
        inspection_type: input.inspectionType || 'general',
        sections: input.sections,
        is_system: false,
        is_active: true,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateTemplate = async (id: string, input: {
    name?: string;
    description?: string;
    trade?: string;
    inspectionType?: string;
    sections?: InspectionTemplateData['sections'];
    isActive?: boolean;
  }) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (input.name !== undefined) updateData.name = input.name;
    if (input.description !== undefined) updateData.description = input.description;
    if (input.trade !== undefined) updateData.trade = input.trade;
    if (input.inspectionType !== undefined) updateData.inspection_type = input.inspectionType;
    if (input.sections !== undefined) updateData.sections = input.sections;
    if (input.isActive !== undefined) updateData.is_active = input.isActive;

    const { error: err } = await supabase
      .from('inspection_templates')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;
  };

  const deleteTemplate = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('inspection_templates')
      .update({ is_active: false, deleted_at: new Date().toISOString() })
      .eq('id', id);

    if (err) throw err;
  };

  const systemTemplates = templates.filter(t => t.isSystem);
  const companyTemplates = templates.filter(t => !t.isSystem && t.isActive);

  return {
    templates,
    systemTemplates,
    companyTemplates,
    loading,
    error,
    refetch: fetchTemplates,
    createTemplate,
    updateTemplate,
    deleteTemplate,
  };
}
