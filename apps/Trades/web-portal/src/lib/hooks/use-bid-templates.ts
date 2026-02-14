'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface TemplateLineItem {
  id: string;
  description: string;
  unit: string;
  defaultQuantity: number;
  defaultUnitPrice: number;
  category: string;
  tags?: string[];
  sortOrder: number;
}

export interface TemplateAddOn {
  id: string;
  name: string;
  description: string;
  defaultPrice: number;
  sortOrder: number;
}

export interface BidTemplate {
  id: string;
  companyId: string | null;
  tradeType: string;
  category: string | null;
  name: string;
  description: string | null;
  lineItems: TemplateLineItem[];
  addOns: TemplateAddOn[];
  defaultScopeOfWork: string | null;
  defaultTerms: string | null;
  defaultTaxRate: number;
  defaultDepositPercent: number;
  defaultValidityDays: number;
  hasGoodBetterBest: boolean;
  goodDescription: string | null;
  betterDescription: string | null;
  bestDescription: string | null;
  betterMultiplier: number;
  bestMultiplier: number;
  isSystem: boolean;
  isActive: boolean;
  useCount: number;
  createdAt: string;
  updatedAt: string;
}

function mapTemplate(row: Record<string, unknown>): BidTemplate {
  return {
    id: row.id as string,
    companyId: row.company_id as string | null,
    tradeType: row.trade_type as string,
    category: row.category as string | null,
    name: row.name as string,
    description: row.description as string | null,
    lineItems: (row.line_items as TemplateLineItem[]) || [],
    addOns: (row.add_ons as TemplateAddOn[]) || [],
    defaultScopeOfWork: row.default_scope_of_work as string | null,
    defaultTerms: row.default_terms as string | null,
    defaultTaxRate: Number(row.default_tax_rate) || 0,
    defaultDepositPercent: Number(row.default_deposit_percent) || 0,
    defaultValidityDays: Number(row.default_validity_days) || 30,
    hasGoodBetterBest: row.has_good_better_best as boolean,
    goodDescription: row.good_description as string | null,
    betterDescription: row.better_description as string | null,
    bestDescription: row.best_description as string | null,
    betterMultiplier: Number(row.better_multiplier) || 1.3,
    bestMultiplier: Number(row.best_multiplier) || 1.6,
    isSystem: row.is_system as boolean,
    isActive: row.is_active as boolean,
    useCount: Number(row.use_count) || 0,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

export function useBidTemplates() {
  const [templates, setTemplates] = useState<BidTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTemplates = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('bid_templates')
        .select('*')
        .eq('is_active', true)
        .is('deleted_at', null)
        .order('trade_type')
        .order('name');

      if (err) throw err;
      setTemplates((data || []).map(mapTemplate));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load bid templates';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTemplates();
  }, [fetchTemplates]);

  const getTemplatesByTrade = (tradeType: string) =>
    templates.filter((t) => t.tradeType === tradeType);

  const getSystemTemplates = () => templates.filter((t) => t.isSystem);

  const getCompanyTemplates = () => templates.filter((t) => !t.isSystem);

  const createTemplate = async (data: Partial<BidTemplate>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('bid_templates')
      .insert({
        company_id: companyId,
        trade_type: data.tradeType || 'general',
        category: data.category || null,
        name: data.name || 'Untitled Template',
        description: data.description || null,
        line_items: data.lineItems || [],
        add_ons: data.addOns || [],
        default_scope_of_work: data.defaultScopeOfWork || null,
        default_terms: data.defaultTerms || null,
        default_tax_rate: data.defaultTaxRate || 0,
        default_deposit_percent: data.defaultDepositPercent || 0,
        default_validity_days: data.defaultValidityDays || 30,
        has_good_better_best: data.hasGoodBetterBest || false,
        good_description: data.goodDescription || null,
        better_description: data.betterDescription || null,
        best_description: data.bestDescription || null,
        better_multiplier: data.betterMultiplier || 1.3,
        best_multiplier: data.bestMultiplier || 1.6,
        is_system: false,
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchTemplates();
    return result.id;
  };

  const cloneTemplate = async (templateId: string, name?: string): Promise<string> => {
    const template = templates.find((t) => t.id === templateId);
    if (!template) throw new Error('Template not found');

    return createTemplate({
      ...template,
      name: name || `${template.name} (Copy)`,
    });
  };

  const updateTemplate = async (id: string, data: Partial<BidTemplate>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.name !== undefined) updateData.name = data.name;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.tradeType !== undefined) updateData.trade_type = data.tradeType;
    if (data.category !== undefined) updateData.category = data.category;
    if (data.lineItems !== undefined) updateData.line_items = data.lineItems;
    if (data.addOns !== undefined) updateData.add_ons = data.addOns;
    if (data.defaultScopeOfWork !== undefined) updateData.default_scope_of_work = data.defaultScopeOfWork;
    if (data.defaultTerms !== undefined) updateData.default_terms = data.defaultTerms;
    if (data.defaultTaxRate !== undefined) updateData.default_tax_rate = data.defaultTaxRate;
    if (data.defaultDepositPercent !== undefined) updateData.default_deposit_percent = data.defaultDepositPercent;
    if (data.defaultValidityDays !== undefined) updateData.default_validity_days = data.defaultValidityDays;
    if (data.hasGoodBetterBest !== undefined) updateData.has_good_better_best = data.hasGoodBetterBest;
    if (data.isActive !== undefined) updateData.is_active = data.isActive;

    const { error: err } = await supabase.from('bid_templates').update(updateData).eq('id', id);
    if (err) throw err;
    await fetchTemplates();
  };

  const deleteTemplate = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('bid_templates')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    await fetchTemplates();
  };

  const incrementUseCount = async (id: string) => {
    const supabase = getSupabase();
    await supabase.rpc('increment_bid_template_use_count', { template_id: id }).catch(() => {
      // Non-critical — don't fail on count increment
    });
  };

  return {
    templates,
    loading,
    error,
    getTemplatesByTrade,
    getSystemTemplates,
    getCompanyTemplates,
    createTemplate,
    cloneTemplate,
    updateTemplate,
    deleteTemplate,
    incrementUseCount,
    refetch: fetchTemplates,
  };
}
