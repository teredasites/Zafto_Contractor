'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapInvoice, INVOICE_STATUS_TO_DB } from './mappers';
import { createInvoiceJournal, createPaymentJournal } from './use-zbooks-engine';
import type { Invoice, InvoiceStatus } from '@/types';

export function useInvoices() {
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchInvoices = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('invoices')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setInvoices((data || []).map(mapInvoice));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load invoices';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchInvoices();

    const supabase = getSupabase();
    const channel = supabase
      .channel('invoices-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'invoices' }, () => {
        fetchInvoices();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchInvoices]);

  const createInvoice = async (data: Partial<Invoice>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Auto-generate invoice number
    const year = new Date().getFullYear();
    const { count } = await supabase
      .from('invoices')
      .select('*', { count: 'exact', head: true })
      .ilike('invoice_number', `INV-${year}-%`);

    const seq = String((count || 0) + 1).padStart(4, '0');
    const invoiceNumber = `INV-${year}-${seq}`;

    const lineItemsJson = (data.lineItems || []).map((li) => ({
      id: li.id,
      description: li.description,
      quantity: li.quantity,
      unit_price: li.unitPrice,
      amount: li.total,
    }));

    const { data: result, error: err } = await supabase
      .from('invoices')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        customer_id: data.customerId || null,
        job_id: data.jobId || null,
        invoice_number: invoiceNumber,
        customer_name: data.customer ? `${data.customer.firstName} ${data.customer.lastName}`.trim() : '',
        customer_email: data.customer?.email || null,
        customer_phone: data.customer?.phone || null,
        customer_address: data.customer?.address?.street || null,
        line_items: lineItemsJson,
        subtotal: data.subtotal || 0,
        tax_rate: data.taxRate || 0,
        tax_amount: data.tax || 0,
        total: data.total || 0,
        amount_paid: 0,
        amount_due: data.total || 0,
        status: 'draft',
        due_date: data.dueDate ? new Date(data.dueDate).toISOString() : null,
        notes: data.notes || null,
        po_number: data.poNumber || null,
        retainage_percent: data.retainagePercent || 0,
        retainage_amount: data.retainageAmount || 0,
        late_fee_per_day: data.lateFeePerDay || 0,
        discount_percent: data.discountPercent || 0,
        payment_terms: data.paymentTerms || 'net_30',
      })
      .select('id')
      .single();

    if (err) throw err;
    fetchInvoices();
    return result.id;
  };

  const updateInvoice = async (id: string, data: Partial<Invoice>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.status !== undefined) updateData.status = INVOICE_STATUS_TO_DB[data.status] || data.status;
    if (data.lineItems !== undefined) {
      updateData.line_items = data.lineItems.map((li) => ({
        id: li.id,
        description: li.description,
        quantity: li.quantity,
        unit_price: li.unitPrice,
        amount: li.total,
      }));
    }
    if (data.subtotal !== undefined) updateData.subtotal = data.subtotal;
    if (data.taxRate !== undefined) updateData.tax_rate = data.taxRate;
    if (data.tax !== undefined) updateData.tax_amount = data.tax;
    if (data.total !== undefined) updateData.total = data.total;
    if (data.dueDate !== undefined) updateData.due_date = data.dueDate ? new Date(data.dueDate).toISOString() : null;
    if (data.notes !== undefined) updateData.notes = data.notes;

    const { error: err } = await supabase.from('invoices').update(updateData).eq('id', id);
    if (err) throw err;
    fetchInvoices();
  };

  const recordPayment = async (id: string, amount: number, method: string) => {
    const supabase = getSupabase();

    // Fetch current invoice
    const { data: inv, error: fetchErr } = await supabase.from('invoices').select('total, amount_paid').eq('id', id).single();
    if (fetchErr) throw fetchErr;

    const newAmountPaid = Number(inv.amount_paid) + amount;
    const newAmountDue = Number(inv.total) - newAmountPaid;
    const newStatus = newAmountDue <= 0 ? 'paid' : 'partiallyPaid';

    const { error: err } = await supabase
      .from('invoices')
      .update({
        amount_paid: newAmountPaid,
        amount_due: Math.max(0, newAmountDue),
        status: newStatus,
        payment_method: method,
        paid_at: newAmountDue <= 0 ? new Date().toISOString() : null,
      })
      .eq('id', id);

    if (err) throw err;

    // Auto-post journal entry: DR Cash/Bank, CR Accounts Receivable
    await createPaymentJournal(id, amount, method);
    fetchInvoices();
  };

  const sendInvoice = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('invoices')
      .update({ status: 'sent', sent_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;

    // Auto-post journal entry: DR Accounts Receivable, CR Revenue
    await createInvoiceJournal(id);

    // U22: Actually send email via SendGrid EF (with PDF + payment link)
    try {
      await supabase.functions.invoke('sendgrid-email', {
        body: { action: 'send_invoice', entityId: id },
      });
    } catch {
      // Email send is best-effort — don't fail the status update
    }
    fetchInvoices();
  };

  const deleteInvoice = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('invoices')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    fetchInvoices();
  };

  // Create invoice from approved estimate — one-click convert
  const createInvoiceFromEstimate = async (estimateId: string): Promise<string | null> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    // Fetch estimate + line items
    const [estRes, linesRes] = await Promise.all([
      supabase.from('estimates').select('*').eq('id', estimateId).single(),
      supabase.from('estimate_line_items').select('*').eq('estimate_id', estimateId).order('sort_order'),
    ]);
    if (estRes.error || !estRes.data) throw new Error('Estimate not found');
    const est = estRes.data;
    const lines = linesRes.data || [];

    // Generate invoice number
    const year = new Date().getFullYear();
    const { count } = await supabase
      .from('invoices')
      .select('id', { count: 'exact', head: true })
      .eq('company_id', companyId);
    const seq = String((count || 0) + 1).padStart(4, '0');
    const invoiceNumber = `INV-${year}-${seq}`;

    // Map estimate line items to invoice line items
    const invoiceLineItems = lines.map((li: Record<string, unknown>, idx: number) => ({
      id: `li-${idx}`,
      description: (li.description as string) || '',
      quantity: Number(li.quantity) || 1,
      unit_price: Number(li.unit_price) || 0,
      amount: Number(li.line_total) || 0,
      category: (li.action_type as string) || 'labor',
    }));

    const subtotal = Number(est.subtotal) || 0;
    const taxRate = Number(est.tax_percent) || 0;
    const taxAmount = Number(est.tax_amount) || 0;
    const total = Number(est.grand_total) || 0;

    const { data: inv, error: invErr } = await supabase
      .from('invoices')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        invoice_number: invoiceNumber,
        customer_id: est.customer_id || null,
        job_id: est.job_id || null,
        estimate_id: estimateId,
        customer_name: (est.customer_name as string) || '',
        customer_email: (est.customer_email as string) || '',
        customer_phone: (est.customer_phone as string) || '',
        title: (est.title as string) || 'Estimate Invoice',
        status: 'draft',
        line_items: invoiceLineItems,
        subtotal,
        tax_rate: taxRate,
        tax_amount: taxAmount,
        total,
        amount_due: total,
        amount_paid: 0,
        due_date: new Date(Date.now() + 30 * 86400000).toISOString(),
        notes: (est.notes as string) || null,
      })
      .select('id')
      .single();
    if (invErr) throw invErr;
    fetchInvoices();
    return inv?.id || null;
  };

  // Apply late fee to an overdue invoice
  const applyLateFee = async (id: string, feeAmount: number, description?: string) => {
    const supabase = getSupabase();
    const { data: inv, error: fetchErr } = await supabase
      .from('invoices')
      .select('line_items, subtotal, tax_rate, tax_amount, total, amount_paid, amount_due')
      .eq('id', id)
      .single();
    if (fetchErr) throw fetchErr;

    const currentItems = (inv.line_items as Array<Record<string, unknown>>) || [];
    const lateFeeItem = {
      id: `late-fee-${Date.now()}`,
      description: description || 'Late fee',
      quantity: 1,
      unit_price: feeAmount,
      amount: feeAmount,
      category: 'late_fee',
    };
    const newItems = [...currentItems, lateFeeItem];
    const newTotal = Number(inv.total) + feeAmount;
    const newAmountDue = Number(inv.amount_due) + feeAmount;

    const { error: err } = await supabase.from('invoices').update({
      line_items: newItems,
      total: newTotal,
      amount_due: Math.max(0, newAmountDue),
    }).eq('id', id);
    if (err) throw err;
    fetchInvoices();
  };

  // Create a credit memo (negative invoice linked to original)
  const createCreditMemo = async (originalInvoiceId: string, creditAmount: number, reason: string): Promise<string | null> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    // Fetch original invoice
    const { data: orig, error: origErr } = await supabase
      .from('invoices')
      .select('*')
      .eq('id', originalInvoiceId)
      .single();
    if (origErr || !orig) throw new Error('Original invoice not found');

    // Generate credit memo number
    const year = new Date().getFullYear();
    const { count } = await supabase
      .from('invoices')
      .select('id', { count: 'exact', head: true })
      .ilike('invoice_number', `CM-${year}-%`);
    const seq = String((count || 0) + 1).padStart(4, '0');

    const { data: memo, error: memoErr } = await supabase
      .from('invoices')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        invoice_number: `CM-${year}-${seq}`,
        customer_id: orig.customer_id || null,
        job_id: orig.job_id || null,
        customer_name: (orig.customer_name as string) || '',
        customer_email: (orig.customer_email as string) || '',
        title: `Credit Memo — ${reason}`,
        status: 'paid',
        line_items: [{ id: 'cm-1', description: reason, quantity: 1, unit_price: -creditAmount, amount: -creditAmount }],
        subtotal: -creditAmount,
        tax_rate: 0,
        tax_amount: 0,
        total: -creditAmount,
        amount_due: 0,
        amount_paid: -creditAmount,
        notes: `Credit memo for invoice ${(orig.invoice_number as string) || originalInvoiceId}`,
        parent_invoice_id: originalInvoiceId,
      })
      .select('id')
      .single();
    if (memoErr) throw memoErr;

    // Apply credit to original invoice balance
    const newAmountDue = Math.max(0, Number(orig.amount_due) - creditAmount);
    const newAmountPaid = Number(orig.amount_paid) + creditAmount;
    await supabase.from('invoices').update({
      amount_due: newAmountDue,
      amount_paid: newAmountPaid,
      status: newAmountDue <= 0 ? 'paid' : orig.status,
    }).eq('id', originalInvoiceId);

    fetchInvoices();
    return memo?.id || null;
  };

  // Batch create invoices from multiple jobs
  const batchCreateInvoices = async (jobIds: string[]): Promise<string[]> => {
    const results: string[] = [];
    for (const jobId of jobIds) {
      const id = await createInvoiceFromJob(jobId);
      if (id) results.push(id);
    }
    return results;
  };

  // Create draft invoice from completed job
  const createInvoiceFromJob = async (jobId: string): Promise<string | null> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    // Fetch job
    const { data: job, error: jobErr } = await supabase
      .from('jobs')
      .select('*, customers(name, email, phone)')
      .eq('id', jobId)
      .single();
    if (jobErr || !job) throw new Error('Job not found');

    // Generate invoice number
    const year = new Date().getFullYear();
    const { count } = await supabase
      .from('invoices')
      .select('id', { count: 'exact', head: true })
      .eq('company_id', companyId);
    const seq = String((count || 0) + 1).padStart(4, '0');
    const invoiceNumber = `INV-${year}-${seq}`;

    const amount = (job.actual_cost as number) || (job.estimated_value as number) || 0;
    const customer = job.customers as Record<string, unknown> | null;

    const { data: inv, error: invErr } = await supabase
      .from('invoices')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        invoice_number: invoiceNumber,
        customer_id: job.customer_id || null,
        job_id: jobId,
        customer_name: customer ? (customer.name as string) || '' : '',
        customer_email: customer ? (customer.email as string) || '' : '',
        customer_phone: customer ? (customer.phone as string) || '' : '',
        title: (job.title as string) || 'Job Invoice',
        status: 'draft',
        line_items: [{
          description: (job.title as string) || 'Services rendered',
          quantity: 1,
          unit: 'job',
          unit_price: amount,
          category: 'labor',
        }],
        subtotal: amount,
        tax_rate: 0,
        tax_amount: 0,
        total: amount,
        amount_due: amount,
        amount_paid: 0,
        due_date: new Date(Date.now() + 30 * 86400000).toISOString(),
      })
      .select('id')
      .single();
    if (invErr) throw invErr;
    fetchInvoices();
    return inv?.id || null;
  };

  return {
    invoices,
    loading,
    error,
    createInvoice,
    updateInvoice,
    recordPayment,
    sendInvoice,
    createInvoiceFromJob,
    createInvoiceFromEstimate,
    applyLateFee,
    createCreditMemo,
    batchCreateInvoices,
    deleteInvoice,
    refetch: fetchInvoices,
  };
}

export function useInvoice(id: string | undefined) {
  const [invoice, setInvoice] = useState<Invoice | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) {
      setLoading(false);
      return;
    }

    let ignore = false;

    const fetchInvoice = async () => {
      try {
        setLoading(true);
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase.from('invoices').select('*').eq('id', id).single();

        if (ignore) return;
        if (err) throw err;
        setInvoice(data ? mapInvoice(data) : null);
      } catch (e: unknown) {
        if (ignore) return;
        const msg = e instanceof Error ? e.message : 'Invoice not found';
        setError(msg);
      } finally {
        if (!ignore) setLoading(false);
      }
    };

    fetchInvoice();
    return () => { ignore = true; };
  }, [id]);

  return { invoice, loading, error };
}
