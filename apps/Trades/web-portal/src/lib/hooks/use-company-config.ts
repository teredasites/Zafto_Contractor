'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Company Config Hook — reads/writes companies.settings JSONB
// ============================================================

export interface TaxRate {
  name: string;
  rate: number;
  appliesTo: string; // 'all' | 'materials' | 'labor' | 'equipment'
}

export interface CompanyConfig {
  // Custom statuses (null = use defaults)
  customJobStatuses: string[] | null;
  customLeadSources: string[] | null;
  customBidStatuses: string[] | null;
  customInvoiceStatuses: string[] | null;
  customPriorityLevels: string[] | null;
  // Tax
  defaultTaxRate: number;
  taxRates: TaxRate[];
  // Payment
  defaultPaymentTerms: string;
  lateFeeRate: number;
  earlyPaymentDiscount: number;
  // Numbering
  invoiceNumberFormat: string;
  bidNumberFormat: string;
  bidValidityDays: number;
  // Line items
  lineItemUnits: string[];
  lineItemCategories: string[];
  // General
  currency: string;
}

// Defaults used when settings is empty or keys are missing
const DEFAULTS: CompanyConfig = {
  customJobStatuses: null,
  customLeadSources: null,
  customBidStatuses: null,
  customInvoiceStatuses: null,
  customPriorityLevels: null,
  defaultTaxRate: 6.35,
  taxRates: [{ name: 'Sales Tax', rate: 6.35, appliesTo: 'all' }],
  defaultPaymentTerms: 'net_30',
  lateFeeRate: 1.5,
  earlyPaymentDiscount: 0,
  invoiceNumberFormat: 'INV-{YYYY}-{NNNN}',
  bidNumberFormat: 'BID-{YYMMDD}-{NNN}',
  bidValidityDays: 30,
  lineItemUnits: ['ea', 'lf', 'sf', 'sy', 'cf', 'cy', 'hr', 'day', 'week', 'month', 'lot', 'pair', 'set'],
  lineItemCategories: ['materials', 'labor', 'equipment', 'subcontractor', 'permits', 'overhead', 'other'],
  currency: 'USD',
};

// Default status lists used when custom is null
export const DEFAULT_JOB_STATUSES = ['lead', 'quoted', 'scheduled', 'in_progress', 'on_hold', 'completed', 'cancelled'];
export const DEFAULT_LEAD_SOURCES = ['referral', 'google', 'website', 'yelp', 'facebook', 'instagram', 'nextdoor', 'homeadvisor', 'other'];
export const DEFAULT_BID_STATUSES = ['draft', 'sent', 'viewed', 'accepted', 'declined', 'expired'];
export const DEFAULT_INVOICE_STATUSES = ['draft', 'sent', 'viewed', 'paid', 'partial', 'overdue', 'void'];
export const DEFAULT_PRIORITY_LEVELS = ['low', 'medium', 'high', 'urgent'];

interface RawSettings {
  custom_job_statuses?: string[] | null;
  custom_lead_sources?: string[] | null;
  custom_bid_statuses?: string[] | null;
  custom_invoice_statuses?: string[] | null;
  custom_priority_levels?: string[] | null;
  default_tax_rate?: number;
  tax_rates?: { name: string; rate: number; applies_to: string }[];
  default_payment_terms?: string;
  late_fee_rate?: number;
  early_payment_discount?: number;
  invoice_number_format?: string;
  bid_number_format?: string;
  bid_validity_days?: number;
  line_item_units?: string[];
  line_item_categories?: string[];
  currency?: string;
}

function parseSettings(raw: RawSettings | null): CompanyConfig {
  if (!raw) return { ...DEFAULTS };
  return {
    customJobStatuses: raw.custom_job_statuses ?? DEFAULTS.customJobStatuses,
    customLeadSources: raw.custom_lead_sources ?? DEFAULTS.customLeadSources,
    customBidStatuses: raw.custom_bid_statuses ?? DEFAULTS.customBidStatuses,
    customInvoiceStatuses: raw.custom_invoice_statuses ?? DEFAULTS.customInvoiceStatuses,
    customPriorityLevels: raw.custom_priority_levels ?? DEFAULTS.customPriorityLevels,
    defaultTaxRate: raw.default_tax_rate ?? DEFAULTS.defaultTaxRate,
    taxRates: (raw.tax_rates || []).map((t) => ({
      name: t.name,
      rate: t.rate,
      appliesTo: t.applies_to || 'all',
    })),
    defaultPaymentTerms: raw.default_payment_terms ?? DEFAULTS.defaultPaymentTerms,
    lateFeeRate: raw.late_fee_rate ?? DEFAULTS.lateFeeRate,
    earlyPaymentDiscount: raw.early_payment_discount ?? DEFAULTS.earlyPaymentDiscount,
    invoiceNumberFormat: raw.invoice_number_format ?? DEFAULTS.invoiceNumberFormat,
    bidNumberFormat: raw.bid_number_format ?? DEFAULTS.bidNumberFormat,
    bidValidityDays: raw.bid_validity_days ?? DEFAULTS.bidValidityDays,
    lineItemUnits: raw.line_item_units ?? DEFAULTS.lineItemUnits,
    lineItemCategories: raw.line_item_categories ?? DEFAULTS.lineItemCategories,
    currency: raw.currency ?? DEFAULTS.currency,
  };
}

function toRawSettings(config: Partial<CompanyConfig>): Record<string, unknown> {
  const raw: Record<string, unknown> = {};
  if (config.customJobStatuses !== undefined) raw.custom_job_statuses = config.customJobStatuses;
  if (config.customLeadSources !== undefined) raw.custom_lead_sources = config.customLeadSources;
  if (config.customBidStatuses !== undefined) raw.custom_bid_statuses = config.customBidStatuses;
  if (config.customInvoiceStatuses !== undefined) raw.custom_invoice_statuses = config.customInvoiceStatuses;
  if (config.customPriorityLevels !== undefined) raw.custom_priority_levels = config.customPriorityLevels;
  if (config.defaultTaxRate !== undefined) raw.default_tax_rate = config.defaultTaxRate;
  if (config.taxRates !== undefined) raw.tax_rates = config.taxRates.map((t) => ({
    name: t.name, rate: t.rate, applies_to: t.appliesTo,
  }));
  if (config.defaultPaymentTerms !== undefined) raw.default_payment_terms = config.defaultPaymentTerms;
  if (config.lateFeeRate !== undefined) raw.late_fee_rate = config.lateFeeRate;
  if (config.earlyPaymentDiscount !== undefined) raw.early_payment_discount = config.earlyPaymentDiscount;
  if (config.invoiceNumberFormat !== undefined) raw.invoice_number_format = config.invoiceNumberFormat;
  if (config.bidNumberFormat !== undefined) raw.bid_number_format = config.bidNumberFormat;
  if (config.bidValidityDays !== undefined) raw.bid_validity_days = config.bidValidityDays;
  if (config.lineItemUnits !== undefined) raw.line_item_units = config.lineItemUnits;
  if (config.lineItemCategories !== undefined) raw.line_item_categories = config.lineItemCategories;
  if (config.currency !== undefined) raw.currency = config.currency;
  return raw;
}

export function useCompanyConfig() {
  const [config, setConfig] = useState<CompanyConfig>({ ...DEFAULTS });
  const [companyId, setCompanyId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const fetchConfig = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const cid = user.app_metadata?.company_id;
      if (!cid) throw new Error('No company');
      setCompanyId(cid);

      const { data, error: err } = await supabase
        .from('companies')
        .select('settings')
        .eq('id', cid)
        .single();
      if (err) throw err;
      setConfig(parseSettings(data?.settings as RawSettings | null));
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load config');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchConfig();
  }, [fetchConfig]);

  const updateConfig = useCallback(async (updates: Partial<CompanyConfig>) => {
    if (!companyId) throw new Error('No company');
    try {
      setSaving(true);
      const supabase = getSupabase();

      // Merge with current settings
      const { data: current } = await supabase
        .from('companies')
        .select('settings')
        .eq('id', companyId)
        .single();

      const currentSettings = (current?.settings || {}) as Record<string, unknown>;
      const newSettings = { ...currentSettings, ...toRawSettings(updates) };

      const { error: err } = await supabase
        .from('companies')
        .update({ settings: newSettings })
        .eq('id', companyId);
      if (err) throw err;

      // Update local state
      setConfig((prev) => ({ ...prev, ...updates }));
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save config');
      throw err;
    } finally {
      setSaving(false);
    }
  }, [companyId]);

  // Resolved values (custom or defaults)
  const jobStatuses = config.customJobStatuses || DEFAULT_JOB_STATUSES;
  const leadSources = config.customLeadSources || DEFAULT_LEAD_SOURCES;
  const bidStatuses = config.customBidStatuses || DEFAULT_BID_STATUSES;
  const invoiceStatuses = config.customInvoiceStatuses || DEFAULT_INVOICE_STATUSES;
  const priorityLevels = config.customPriorityLevels || DEFAULT_PRIORITY_LEVELS;

  return {
    config,
    loading,
    error,
    saving,
    updateConfig,
    refetch: fetchConfig,
    // Resolved values
    jobStatuses,
    leadSources,
    bidStatuses,
    invoiceStatuses,
    priorityLevels,
  };
}
