'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Recurring Transactions Hook — CRUD + generation + history
// ============================================================

export type TransactionType = 'expense' | 'invoice';
export type Frequency = 'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'annually';

export interface RecurringTemplateData {
  id: string;
  templateName: string;
  transactionType: TransactionType;
  frequency: Frequency;
  nextOccurrence: string;
  endDate: string | null;
  templateData: Record<string, unknown>;
  accountId: string | null;
  vendorId: string | null;
  jobId: string | null;
  isActive: boolean;
  lastGeneratedAt: string | null;
  timesGenerated: number;
  createdByUserId: string;
  createdAt: string;
  updatedAt: string;
}

export interface GenerationHistoryItem {
  id: string;
  createdAt: string;
  amount: number;
  description: string;
  type: TransactionType;
}

export const FREQUENCY_LABELS: Record<Frequency, string> = {
  weekly: 'Weekly',
  biweekly: 'Bi-Weekly',
  monthly: 'Monthly',
  quarterly: 'Quarterly',
  annually: 'Annually',
};

export const TRANSACTION_TYPE_LABELS: Record<TransactionType, string> = {
  expense: 'Expense',
  invoice: 'Invoice',
};

function mapTemplate(row: Record<string, unknown>): RecurringTemplateData {
  return {
    id: row.id as string,
    templateName: row.template_name as string,
    transactionType: row.transaction_type as TransactionType,
    frequency: row.frequency as Frequency,
    nextOccurrence: row.next_occurrence as string,
    endDate: row.end_date as string | null,
    templateData: (row.template_data as Record<string, unknown>) || {},
    accountId: row.account_id as string | null,
    vendorId: row.vendor_id as string | null,
    jobId: row.job_id as string | null,
    isActive: row.is_active as boolean,
    lastGeneratedAt: row.last_generated_at as string | null,
    timesGenerated: Number(row.times_generated || 0),
    createdByUserId: row.created_by_user_id as string,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function calculateNextOccurrence(currentDate: string, frequency: Frequency): string {
  const d = new Date(currentDate + 'T00:00:00');
  switch (frequency) {
    case 'weekly':
      d.setDate(d.getDate() + 7);
      break;
    case 'biweekly':
      d.setDate(d.getDate() + 14);
      break;
    case 'monthly':
      d.setMonth(d.getMonth() + 1);
      break;
    case 'quarterly':
      d.setMonth(d.getMonth() + 3);
      break;
    case 'annually':
      d.setFullYear(d.getFullYear() + 1);
      break;
  }
  return d.toISOString().split('T')[0];
}

export function useRecurring() {
  const [templates, setTemplates] = useState<RecurringTemplateData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTemplates = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('recurring_transactions')
        .select('*')
        .order('next_occurrence', { ascending: true });

      if (err) throw err;
      setTemplates((data || []).map((r: Record<string, unknown>) => mapTemplate(r)));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load recurring templates');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTemplates();
  }, [fetchTemplates]);

  const createTemplate = async (data: {
    templateName: string;
    transactionType: TransactionType;
    frequency: Frequency;
    nextOccurrence: string;
    endDate?: string;
    templateData: Record<string, unknown>;
    accountId?: string;
    vendorId?: string;
    jobId?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('recurring_transactions')
      .insert({
        company_id: companyId,
        template_name: data.templateName,
        transaction_type: data.transactionType,
        frequency: data.frequency,
        next_occurrence: data.nextOccurrence,
        end_date: data.endDate || null,
        template_data: data.templateData,
        account_id: data.accountId || null,
        vendor_id: data.vendorId || null,
        job_id: data.jobId || null,
        is_active: true,
        times_generated: 0,
        created_by_user_id: user.id,
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchTemplates();
    return result.id;
  };

  const updateTemplate = async (id: string, data: Partial<{
    templateName: string;
    transactionType: TransactionType;
    frequency: Frequency;
    nextOccurrence: string;
    endDate: string | null;
    templateData: Record<string, unknown>;
    accountId: string | null;
    vendorId: string | null;
    jobId: string | null;
  }>) => {
    const supabase = getSupabase();
    const update: Record<string, unknown> = {};
    if (data.templateName !== undefined) update.template_name = data.templateName;
    if (data.transactionType !== undefined) update.transaction_type = data.transactionType;
    if (data.frequency !== undefined) update.frequency = data.frequency;
    if (data.nextOccurrence !== undefined) update.next_occurrence = data.nextOccurrence;
    if (data.endDate !== undefined) update.end_date = data.endDate;
    if (data.templateData !== undefined) update.template_data = data.templateData;
    if (data.accountId !== undefined) update.account_id = data.accountId;
    if (data.vendorId !== undefined) update.vendor_id = data.vendorId;
    if (data.jobId !== undefined) update.job_id = data.jobId;
    update.updated_at = new Date().toISOString();

    const { error: err } = await supabase
      .from('recurring_transactions')
      .update(update)
      .eq('id', id);
    if (err) throw err;
    await fetchTemplates();
  };

  const pauseTemplate = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('recurring_transactions')
      .update({ is_active: false, updated_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    await fetchTemplates();
  };

  const resumeTemplate = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('recurring_transactions')
      .update({ is_active: true, updated_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    await fetchTemplates();
  };

  const deleteTemplate = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('recurring_transactions')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    await fetchTemplates();
  };

  const generateNow = async (id: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // 1. Read the template
    const { data: tmpl, error: fetchErr } = await supabase
      .from('recurring_transactions')
      .select('*')
      .eq('id', id)
      .single();
    if (fetchErr || !tmpl) throw new Error('Template not found');

    const template = mapTemplate(tmpl as Record<string, unknown>);
    const td = template.templateData;

    // 2. Generate based on transaction_type
    if (template.transactionType === 'expense') {
      const { error: insertErr } = await supabase
        .from('expense_records')
        .insert({
          company_id: companyId,
          vendor_id: template.vendorId || (td.vendor_id as string) || null,
          expense_date: template.nextOccurrence,
          description: (td.description as string) || template.templateName,
          amount: Number(td.amount || 0),
          tax_amount: Number(td.tax_amount || 0),
          total: Number(td.amount || 0) + Number(td.tax_amount || 0),
          category: (td.category as string) || 'uncategorized',
          account_id: template.accountId || (td.account_id as string) || null,
          job_id: template.jobId || (td.job_id as string) || null,
          payment_method: (td.payment_method as string) || 'bank_transfer',
          status: 'draft',
          notes: `Auto-generated from recurring template: ${template.templateName} (ID: ${template.id})`,
          created_by_user_id: user.id,
        });
      if (insertErr) throw insertErr;
    } else {
      // invoice
      const year = new Date().getFullYear();
      const { count } = await supabase
        .from('invoices')
        .select('*', { count: 'exact', head: true })
        .ilike('invoice_number', `INV-${year}-%`);

      const seq = String((count || 0) + 1).padStart(4, '0');
      const invoiceNumber = `INV-${year}-${seq}`;

      const amount = Number(td.amount || 0);
      const taxRate = Number(td.tax_rate || 0);
      const taxAmount = amount * (taxRate / 100);
      const total = amount + taxAmount;

      const { error: insertErr } = await supabase
        .from('invoices')
        .insert({
          company_id: companyId,
          created_by_user_id: user.id,
          customer_id: (td.customer_id as string) || null,
          job_id: template.jobId || (td.job_id as string) || null,
          invoice_number: invoiceNumber,
          customer_name: (td.customer_name as string) || '',
          customer_email: (td.customer_email as string) || null,
          line_items: (td.line_items as unknown[]) || [
            { description: template.templateName, quantity: 1, unit_price: amount, amount },
          ],
          subtotal: amount,
          tax_rate: taxRate,
          tax_amount: taxAmount,
          total,
          amount_paid: 0,
          amount_due: total,
          status: 'draft',
          due_date: (td.due_date_offset as number)
            ? new Date(Date.now() + (td.due_date_offset as number) * 86400000).toISOString()
            : new Date(Date.now() + 30 * 86400000).toISOString(),
          notes: `Auto-generated from recurring template: ${template.templateName} (ID: ${template.id})`,
        });
      if (insertErr) throw insertErr;
    }

    // 3. Calculate next occurrence
    const nextOcc = calculateNextOccurrence(template.nextOccurrence, template.frequency);

    // 4. Check if next occurrence exceeds end date — deactivate if so
    const shouldDeactivate = template.endDate && nextOcc > template.endDate;

    // 5. Update the template
    const { error: updateErr } = await supabase
      .from('recurring_transactions')
      .update({
        next_occurrence: nextOcc,
        last_generated_at: new Date().toISOString(),
        times_generated: template.timesGenerated + 1,
        is_active: shouldDeactivate ? false : template.isActive,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id);
    if (updateErr) throw updateErr;

    await fetchTemplates();
  };

  const getGenerationHistory = async (templateId: string): Promise<GenerationHistoryItem[]> => {
    const supabase = getSupabase();

    // Find the template to know its type
    const template = templates.find((t) => t.id === templateId);
    if (!template) return [];

    const searchNote = `(ID: ${templateId})`;
    const items: GenerationHistoryItem[] = [];

    if (template.transactionType === 'expense') {
      const { data: expenses } = await supabase
        .from('expense_records')
        .select('id, created_at, total, description')
        .ilike('notes', `%${searchNote}%`)
        .order('created_at', { ascending: false });

      for (const row of (expenses || []) as { id: string; created_at: string; total: number; description: string }[]) {
        items.push({
          id: row.id,
          createdAt: row.created_at,
          amount: Number(row.total),
          description: row.description,
          type: 'expense',
        });
      }
    } else {
      const { data: invoices } = await supabase
        .from('invoices')
        .select('id, created_at, total, customer_name')
        .ilike('notes', `%${searchNote}%`)
        .order('created_at', { ascending: false });

      for (const row of (invoices || []) as { id: string; created_at: string; total: number; customer_name: string }[]) {
        items.push({
          id: row.id,
          createdAt: row.created_at,
          amount: Number(row.total),
          description: row.customer_name || 'Invoice',
          type: 'invoice',
        });
      }
    }

    return items;
  };

  return {
    templates,
    loading,
    error,
    createTemplate,
    updateTemplate,
    pauseTemplate,
    resumeTemplate,
    deleteTemplate,
    generateNow,
    getGenerationHistory,
    refetch: fetchTemplates,
  };
}
