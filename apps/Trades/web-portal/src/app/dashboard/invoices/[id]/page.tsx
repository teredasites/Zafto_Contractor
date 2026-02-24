'use client';

import React, { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import {
  ArrowLeft,
  Receipt,
  User,
  Mail,
  Phone,
  MapPin,
  DollarSign,
  Calendar,
  Send,
  Download,
  CreditCard,
  CheckCircle,
  Clock,
  Edit,
  MoreHorizontal,
  Trash2,
  Copy,
  Printer,
  AlertCircle,
  Ban,
  FileText,
  Percent,
  ChevronRight,
  Repeat,
  Layers,
  Link,
  ExternalLink,
  Plus,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge, Badge } from '@/components/ui/badge';
import { formatCurrency, formatDate, formatDateTime, cn } from '@/lib/utils';
import { useInvoice, useInvoices } from '@/lib/hooks/use-invoices';
import type { InvoiceStatus } from '@/types';
import { getSupabase } from '@/lib/supabase';
import type { Invoice, InvoiceLineItem } from '@/types';
import { useTranslation } from '@/lib/translations';
import { formatCurrency as fmtCurr } from '@/lib/format-locale';
import { EntityDocumentsPanel } from '@/components/entity-documents-panel';

// ── Invoice Status Pipeline ──
const PIPELINE_STAGES: { key: InvoiceStatus; label: string; color: string; bgActive: string }[] = [
  { key: 'draft', label: 'Draft', color: 'text-zinc-400', bgActive: 'bg-zinc-500' },
  { key: 'sent', label: 'Sent', color: 'text-blue-400', bgActive: 'bg-blue-500' },
  { key: 'viewed', label: 'Viewed', color: 'text-purple-400', bgActive: 'bg-purple-500' },
  { key: 'partial', label: 'Partial', color: 'text-amber-400', bgActive: 'bg-amber-500' },
  { key: 'paid', label: 'Paid', color: 'text-emerald-400', bgActive: 'bg-emerald-500' },
];

function InvoicePipeline({ status }: { status: InvoiceStatus }) {
  const isVoid = status === 'void' || status === 'refunded';
  const isOverdue = status === 'overdue';

  if (isVoid) {
    return (
      <div className="flex items-center gap-2 px-4 py-3 bg-red-500/10 border border-red-500/20 rounded-lg">
        <Ban className="w-4 h-4 text-red-400" />
        <span className="text-sm font-medium text-red-400">
          {status === 'void' ? 'Voided' : 'Refunded'}
        </span>
      </div>
    );
  }

  // Map overdue to sent stage (it's still in the sent state, just past due)
  const activeStatus = isOverdue ? 'sent' : status;
  const activeIdx = PIPELINE_STAGES.findIndex(s => s.key === activeStatus);

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-1">
        {PIPELINE_STAGES.map((stage, idx) => {
          const isActive = idx === activeIdx;
          const isPast = idx < activeIdx;
          const isFuture = idx > activeIdx;
          return (
            <React.Fragment key={stage.key}>
              {idx > 0 && (
                <div className={cn(
                  'flex-1 h-0.5 rounded',
                  isPast || isActive ? (isOverdue && idx <= activeIdx ? 'bg-red-500' : stage.bgActive) : 'bg-zinc-800'
                )} />
              )}
              <div className="flex flex-col items-center gap-1">
                <div className={cn(
                  'w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold border-2 transition-all',
                  isActive ? `${isOverdue ? 'bg-red-500/20 border-red-500 text-red-400' : `${stage.bgActive}/20 border-current ${stage.color}`}` :
                  isPast ? 'bg-emerald-500/20 border-emerald-500 text-emerald-400' :
                  'bg-zinc-900 border-zinc-700 text-zinc-600'
                )}>
                  {isPast ? <CheckCircle className="w-3.5 h-3.5" /> : (idx + 1)}
                </div>
                <span className={cn(
                  'text-[10px] font-medium whitespace-nowrap',
                  isActive ? (isOverdue ? 'text-red-400' : stage.color) :
                  isPast ? 'text-emerald-400' : 'text-zinc-600'
                )}>
                  {isActive && isOverdue ? 'Overdue' : stage.label}
                </span>
              </div>
            </React.Fragment>
          );
        })}
      </div>
    </div>
  );
}

export default function InvoiceDetailPage() {
  const { t, formatDate } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const invoiceId = params.id as string;

  const { invoice, loading } = useInvoice(invoiceId);
  const { sendInvoice, createInvoice, deleteInvoice, applyLateFee, createCreditMemo, createProgressInvoices, setupRecurringInvoice, generateFromRecurring, generatePaymentLink, getProgressGroup, invoices: allInvoices } = useInvoices();
  const [menuOpen, setMenuOpen] = useState(false);
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [showCreditMemoModal, setShowCreditMemoModal] = useState(false);
  const [showLateFeeModal, setShowLateFeeModal] = useState(false);
  const [showProgressModal, setShowProgressModal] = useState(false);
  const [showRecurringModal, setShowRecurringModal] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (!invoice) {
    return (
      <div className="text-center py-12">
        <Receipt size={48} className="mx-auto text-muted mb-4" />
        <h2 className="text-xl font-semibold text-main">{t('invoices.invoiceNotFound')}</h2>
        <p className="text-muted mt-2">{t('invoices.theInvoiceYoureLookingForDoesntExist')}</p>
        <Button variant="secondary" className="mt-4" onClick={() => router.push('/dashboard/invoices')}>
          Back to Invoices
        </Button>
      </div>
    );
  }

  const isOverdue = invoice.status === 'overdue';
  const isPaid = invoice.status === 'paid';

  return (
    <div className="space-y-6 pb-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
          >
            <ArrowLeft size={20} className="text-muted" />
          </button>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-semibold text-main">{invoice.invoiceNumber}</h1>
              <StatusBadge status={invoice.status} />
              {isOverdue && (
                <Badge variant="error">
                  <AlertCircle size={12} className="mr-1" />
                  Overdue
                </Badge>
              )}
            </div>
            <p className="text-muted mt-1">
              {invoice.customer?.firstName} {invoice.customer?.lastName}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {invoice.status === 'draft' && (
            <Button disabled={actionLoading} onClick={async () => {
              const custEmail = invoice.customer?.email;
              if (!custEmail) { alert('No customer email on file.'); return; }
              if (!confirm(`Send invoice to ${custEmail}?`)) return;
              setActionLoading(true);
              try {
                const supabase = getSupabase();
                const { data: { session } } = await supabase.auth.getSession();
                if (!session) throw new Error('Not authenticated');
                const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
                const pdfRes = await fetch(`${baseUrl}/functions/v1/export-invoice-pdf?invoice_id=${invoice.id}`, {
                  headers: { 'Authorization': `Bearer ${session.access_token}`, 'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '' },
                });
                const pdfHtml = pdfRes.ok ? await pdfRes.text() : '';
                await supabase.functions.invoke('sendgrid-email', {
                  body: {
                    action: 'send',
                    to_email: custEmail,
                    to_name: `${invoice.customer?.firstName || ''} ${invoice.customer?.lastName || ''}`.trim(),
                    subject: `Invoice ${invoice.invoiceNumber || ''} — ${fmtCurr(invoice.total || 0)} Due`,
                    body_html: pdfHtml || `<p>Your invoice is ready. Amount due: ${fmtCurr(invoice.amountDue || 0)}</p>`,
                    email_type: 'invoice_send',
                    related_type: 'invoice',
                    related_id: invoice.id,
                  },
                });
                await sendInvoice(invoice.id);
                window.location.reload();
              } catch (e) { alert(e instanceof Error ? e.message : 'Failed to send'); }
              setActionLoading(false);
            }}>
              <Send size={16} />
              Send Invoice
            </Button>
          )}
          {(invoice.status === 'sent' || invoice.status === 'overdue') && (
            <>
              <Button variant="secondary" disabled={actionLoading} onClick={async () => {
                const custEmail = invoice.customer?.email;
                if (!custEmail) { alert('No customer email on file.'); return; }
                if (!confirm(`Send payment reminder to ${custEmail}?`)) return;
                setActionLoading(true);
                try {
                  const supabase = getSupabase();
                  await supabase.functions.invoke('sendgrid-email', {
                    body: {
                      action: 'send',
                      to_email: custEmail,
                      to_name: `${invoice.customer?.firstName || ''} ${invoice.customer?.lastName || ''}`.trim(),
                      subject: `Payment Reminder: Invoice ${invoice.invoiceNumber || ''} — ${fmtCurr(invoice.amountDue || 0)} Due`,
                      body_html: `<div style="font-family:sans-serif;max-width:600px;margin:0 auto;"><h2>{t('invoices.paymentReminder')}</h2><p>This is a friendly reminder that invoice <strong>${invoice.invoiceNumber || ''}</strong> has an outstanding balance of <strong>${fmtCurr(invoice.amountDue || 0)}</strong>.</p><p>Due date: ${invoice.dueDate ? formatDate(invoice.dueDate) : 'N/A'}</p><p>If you have already sent payment, please disregard this notice.</p></div>`,
                      email_type: 'invoice_reminder',
                      related_type: 'invoice',
                      related_id: invoice.id,
                    },
                  });
                  alert('Reminder sent successfully');
                } catch (e) { alert(e instanceof Error ? e.message : 'Failed to send'); }
                setActionLoading(false);
              }}>
                <Mail size={16} />
                Send Reminder
              </Button>
              <Button onClick={() => setShowPaymentModal(true)}>
                <CreditCard size={16} />
                Record Payment
              </Button>
            </>
          )}
          {isPaid && (
            <Badge variant="success" className="text-base px-4 py-2">
              <CheckCircle size={16} className="mr-2" />
              Paid
            </Badge>
          )}
          <div className="relative">
            <Button variant="ghost" size="icon" onClick={() => setMenuOpen(!menuOpen)}>
              <MoreHorizontal size={18} />
            </Button>
            {menuOpen && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setMenuOpen(false)} />
                <div className="absolute right-0 top-full mt-1 w-48 bg-surface border border-main rounded-lg shadow-lg py-1 z-50">
                  <button onClick={() => { setMenuOpen(false); router.push(`/dashboard/invoices/new?edit=${invoice.id}`); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Edit size={16} />
                    Edit Invoice
                  </button>
                  <button onClick={async () => {
                    setMenuOpen(false);
                    const supabase = getSupabase();
                    const { data: { session } } = await supabase.auth.getSession();
                    if (!session) return;
                    const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
                    const res = await fetch(`${baseUrl}/functions/v1/export-invoice-pdf?invoice_id=${invoice.id}`, {
                      headers: {
                        'Authorization': `Bearer ${session.access_token}`,
                        'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
                      },
                    });
                    if (!res.ok) return;
                    const html = await res.text();
                    const blob = new Blob([html], { type: 'text/html' });
                    window.open(URL.createObjectURL(blob), '_blank');
                  }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Download size={16} />
                    Download PDF
                  </button>
                  <button onClick={async () => {
                    setMenuOpen(false);
                    const supabase = getSupabase();
                    const { data: { session } } = await supabase.auth.getSession();
                    if (!session) return;
                    const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
                    const res = await fetch(`${baseUrl}/functions/v1/export-invoice-pdf?invoice_id=${invoice.id}`, {
                      headers: { 'Authorization': `Bearer ${session.access_token}`, 'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '' },
                    });
                    if (!res.ok) return;
                    const html = await res.text();
                    const w = window.open('', '_blank');
                    if (w) { w.document.write(html); w.document.close(); w.print(); }
                  }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Printer size={16} />
                    Print
                  </button>
                  <button onClick={async () => {
                    setMenuOpen(false);
                    try {
                      await createInvoice({
                        customerId: invoice.customerId,
                        jobId: invoice.jobId || undefined,
                        lineItems: invoice.lineItems,
                        subtotal: invoice.subtotal,
                        taxRate: invoice.taxRate,
                        tax: invoice.tax,
                        total: invoice.total,
                        dueDate: invoice.dueDate,
                        notes: invoice.notes,
                        status: 'draft',
                      } as Partial<Invoice>);
                      router.push('/dashboard/invoices');
                    } catch (e) { alert(e instanceof Error ? e.message : 'Failed to duplicate'); }
                  }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Copy size={16} />
                    Duplicate
                  </button>
                  <hr className="my-1 border-main" />
                  <button onClick={async () => {
                    setMenuOpen(false);
                    if (!confirm('Void this invoice? This cannot be undone.')) return;
                    try {
                      await deleteInvoice(invoice.id);
                      router.push('/dashboard/invoices');
                    } catch (e) { alert(e instanceof Error ? e.message : 'Failed to void'); }
                  }} className="w-full px-4 py-2 text-left text-sm hover:bg-red-50 dark:hover:bg-red-900/20 text-red-600 flex items-center gap-2">
                    <Trash2 size={16} />
                    Void Invoice
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Status Pipeline */}
      <Card>
        <CardContent className="p-4">
          <InvoicePipeline status={invoice.status} />
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Amount Summary */}
          <Card className={cn(isOverdue && 'border-red-300 dark:border-red-800')}>
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted">{t('common.amountDue')}</p>
                  <p className={cn(
                    'text-3xl font-semibold',
                    isPaid ? 'text-emerald-600' : isOverdue ? 'text-red-600' : 'text-main'
                  )}>
                    {formatCurrency(invoice.amountDue)}
                  </p>
                  {invoice.amountPaid > 0 && invoice.amountDue > 0 && (
                    <p className="text-sm text-muted mt-1">
                      {formatCurrency(invoice.amountPaid)} paid of {formatCurrency(invoice.total)}
                    </p>
                  )}
                </div>
                <div className="text-right">
                  <p className="text-sm text-muted">{t('common.dueDate')}</p>
                  <p className={cn(
                    'font-medium',
                    isOverdue ? 'text-red-600' : 'text-main'
                  )}>
                    {formatDate(invoice.dueDate)}
                  </p>
                  {isOverdue && (
                    <p className="text-sm text-red-600 mt-1">
                      {Math.floor((new Date().getTime() - new Date(invoice.dueDate).getTime()) / (1000 * 60 * 60 * 24))} days overdue
                    </p>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Customer */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <User size={18} className="text-muted" />
                Bill To
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="font-medium text-main">
                {invoice.customer?.firstName} {invoice.customer?.lastName}
              </div>
              {invoice.customer?.email && (
                <div className="flex items-center gap-2 text-sm text-muted">
                  <Mail size={14} />
                  <a href={`mailto:${invoice.customer.email}`} className="hover:text-accent">
                    {invoice.customer.email}
                  </a>
                </div>
              )}
              {invoice.customer?.phone && (
                <div className="flex items-center gap-2 text-sm text-muted">
                  <Phone size={14} />
                  <a href={`tel:${invoice.customer.phone}`} className="hover:text-accent">
                    {invoice.customer.phone}
                  </a>
                </div>
              )}
              {invoice.customer?.address && (
                <div className="flex items-center gap-2 text-sm text-muted">
                  <MapPin size={14} />
                  <span>
                    {invoice.customer.address.street}, {invoice.customer.address.city},{' '}
                    {invoice.customer.address.state} {invoice.customer.address.zip}
                  </span>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Line Items */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <DollarSign size={18} className="text-muted" />
                Line Items
              </CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-main">
                    <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('common.description')}</th>
                    <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.qty')}</th>
                    <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.price')}</th>
                    <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.total')}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-main">
                  {(() => {
                    const hasInsurance = invoice.lineItems.some((i: InvoiceLineItem) => i.paymentSource && i.paymentSource !== 'standard');
                    if (!hasInsurance) {
                      return invoice.lineItems.map((item: InvoiceLineItem) => (
                        <tr key={item.id}>
                          <td className="px-6 py-4 font-medium text-main">{item.description}</td>
                          <td className="px-6 py-4 text-right text-muted">{item.quantity}</td>
                          <td className="px-6 py-4 text-right text-muted">{formatCurrency(item.unitPrice)}</td>
                          <td className="px-6 py-4 text-right font-medium text-main">{formatCurrency(item.total)}</td>
                        </tr>
                      ));
                    }
                    const sections: { key: string; label: string; color: string; items: InvoiceLineItem[] }[] = [
                      { key: 'carrier', label: 'Insurance-Covered Work', color: 'text-blue-600 dark:text-blue-400', items: [] },
                      { key: 'deductible', label: 'Deductible', color: 'text-orange-600 dark:text-orange-400', items: [] },
                      { key: 'upgrade', label: 'Upgrades (Out-of-Pocket)', color: 'text-purple-600 dark:text-purple-400', items: [] },
                      { key: 'standard', label: 'Other', color: 'text-muted', items: [] },
                    ];
                    for (const item of invoice.lineItems) {
                      const s = sections.find(s => s.key === (item.paymentSource || 'standard'));
                      if (s) s.items.push(item);
                    }
                    return sections.filter(s => s.items.length > 0).map(section => (
                      <React.Fragment key={section.key}>
                        <tr className="bg-muted/30">
                          <td colSpan={3} className={`px-6 py-2 text-xs font-semibold uppercase ${section.color}`}>{section.label}</td>
                          <td className={`px-6 py-2 text-right text-xs font-semibold ${section.color}`}>{formatCurrency(section.items.reduce((s, i) => s + i.total, 0))}</td>
                        </tr>
                        {section.items.map((item: InvoiceLineItem) => (
                          <tr key={item.id}>
                            <td className="px-6 py-4 font-medium text-main">{item.description}</td>
                            <td className="px-6 py-4 text-right text-muted">{item.quantity}</td>
                            <td className="px-6 py-4 text-right text-muted">{formatCurrency(item.unitPrice)}</td>
                            <td className="px-6 py-4 text-right font-medium text-main">{formatCurrency(item.total)}</td>
                          </tr>
                        ))}
                      </React.Fragment>
                    ));
                  })()}
                </tbody>
              </table>

              {/* Totals */}
              <div className="px-6 py-4 border-t border-main">
                <div className="flex justify-end">
                  <div className="w-64 space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-muted">{t('common.subtotal')}</span>
                      <span className="text-main">{formatCurrency(invoice.subtotal)}</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-muted">Tax ({invoice.taxRate}%)</span>
                      <span className="text-main">{formatCurrency(invoice.tax)}</span>
                    </div>
                    <div className="flex justify-between font-semibold text-lg pt-2 border-t border-main">
                      <span>{t('common.total')}</span>
                      <span>{formatCurrency(invoice.total)}</span>
                    </div>
                    {invoice.amountPaid > 0 && (
                      <>
                        <div className="flex justify-between text-sm text-emerald-600">
                          <span>{t('common.paid')}</span>
                          <span>-{formatCurrency(invoice.amountPaid)}</span>
                        </div>
                        <div className="flex justify-between font-semibold text-lg">
                          <span>{t('invoices.balanceDue')}</span>
                          <span className={isOverdue ? 'text-red-600' : ''}>{formatCurrency(invoice.amountDue)}</span>
                        </div>
                      </>
                    )}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Notes */}
          {invoice.notes && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">{t('common.notes')}</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-main whitespace-pre-wrap">{invoice.notes}</p>
              </CardContent>
            </Card>
          )}

          {/* Linked Documents (ZDocs) */}
          <EntityDocumentsPanel
            entityType="invoice"
            entityId={invoice.id}
            onGenerateDocument={() => router.push('/dashboard/zdocs')}
          />
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Status */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">{t('common.details')}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.status')}</span>
                <StatusBadge status={invoice.status} />
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('invoices.invoice')}</span>
                <span className="text-main font-mono">{invoice.invoiceNumber}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.createdAt')}</span>
                <span className="text-main">{formatDate(invoice.createdAt)}</span>
              </div>
              {invoice.sentAt && (
                <div className="flex justify-between text-sm">
                  <span className="text-muted">{t('common.sent')}</span>
                  <span className="text-main">{formatDate(invoice.sentAt)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('invoices.due')}</span>
                <span className={cn('font-medium', isOverdue ? 'text-red-600' : 'text-main')}>
                  {formatDate(invoice.dueDate)}
                </span>
              </div>
              {invoice.paidAt && (
                <div className="flex justify-between text-sm">
                  <span className="text-muted">{t('common.paid')}</span>
                  <span className="text-emerald-600">{formatDate(invoice.paidAt)}</span>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Payment History */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">{t('invoices.paymentHistory')}</CardTitle>
            </CardHeader>
            <CardContent>
              {invoice.amountPaid > 0 ? (
                <div className="space-y-3">
                  <div className="flex items-center justify-between p-3 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg">
                    <div className="flex items-center gap-3">
                      <CheckCircle size={16} className="text-emerald-600" />
                      <div>
                        <p className="font-medium text-main text-sm">{formatCurrency(invoice.amountPaid)}</p>
                        <p className="text-xs text-muted">
                          {invoice.paymentMethod === 'card' ? 'Card payment' :
                           invoice.paymentMethod === 'ach' ? 'Bank transfer' :
                           invoice.paymentMethod || 'Payment'}
                        </p>
                      </div>
                    </div>
                    <span className="text-xs text-muted">
                      {invoice.paidAt ? formatDate(invoice.paidAt) : ''}
                    </span>
                  </div>
                </div>
              ) : (
                <p className="text-sm text-muted text-center py-4">{t('invoices.noPaymentsRecorded')}</p>
              )}
            </CardContent>
          </Card>

          {/* Related Job */}
          {invoice.jobId && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">{t('invoices.relatedJob')}</CardTitle>
              </CardHeader>
              <CardContent>
                <Button
                  variant="secondary"
                  className="w-full"
                  onClick={() => router.push(`/dashboard/jobs/${invoice.jobId}`)}
                >
                  View Job
                </Button>
              </CardContent>
            </Card>
          )}

          {/* Late Fee */}
          {isOverdue && !isPaid && (
            <Card className="border-red-300 dark:border-red-800">
              <CardHeader className="pb-2">
                <CardTitle className="text-base text-red-400 flex items-center gap-2">
                  <AlertCircle size={16} />
                  Late Fee
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {invoice.lateFeePerDay != null && invoice.lateFeePerDay > 0 ? (
                  <>
                    <div className="flex justify-between text-sm">
                      <span className="text-muted">Fee rate</span>
                      <span className="text-main">{formatCurrency(invoice.lateFeePerDay)}/day</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-muted">Days overdue</span>
                      <span className="text-red-400 font-medium">
                        {Math.floor((new Date().getTime() - new Date(invoice.dueDate).getTime()) / 86400000)}
                      </span>
                    </div>
                    <div className="flex justify-between text-sm font-medium">
                      <span className="text-muted">Accrued fee</span>
                      <span className="text-red-400">
                        {formatCurrency(
                          invoice.lateFeePerDay * Math.floor((new Date().getTime() - new Date(invoice.dueDate).getTime()) / 86400000)
                        )}
                      </span>
                    </div>
                  </>
                ) : (
                  <p className="text-sm text-muted">No late fee configured</p>
                )}
                <Button
                  variant="secondary"
                  size="sm"
                  className="w-full text-red-400 border-red-500/20 hover:bg-red-500/10"
                  onClick={() => setShowLateFeeModal(true)}
                >
                  Apply Late Fee
                </Button>
              </CardContent>
            </Card>
          )}

          {/* Progress Billing */}
          {invoice.total > 0 && invoice.amountPaid > 0 && invoice.amountDue > 0 && (
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-base flex items-center gap-2">
                  <Percent size={16} className="text-muted" />
                  Progress Billing
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="w-full h-3 bg-zinc-800 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-emerald-500 rounded-full transition-all"
                    style={{ width: `${Math.min(100, (invoice.amountPaid / invoice.total) * 100)}%` }}
                  />
                </div>
                <div className="flex justify-between text-xs text-muted">
                  <span>{Math.round((invoice.amountPaid / invoice.total) * 100)}% collected</span>
                  <span>{formatCurrency(invoice.amountDue)} remaining</span>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Progress Invoice Group (milestone-based) */}
          {invoice.isProgressInvoice && invoice.progressGroupId && (() => {
            const group = getProgressGroup(invoice.progressGroupId);
            if (group.length <= 1) return null;
            const totalContract = group.reduce((s, i) => s + i.total, 0);
            const totalPaid = group.reduce((s, i) => s + i.amountPaid, 0);
            return (
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-base flex items-center gap-2">
                    <Layers size={16} className="text-muted" />
                    Milestone Schedule
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="w-full h-3 bg-zinc-800 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-emerald-500 rounded-full transition-all"
                      style={{ width: `${totalContract > 0 ? Math.min(100, (totalPaid / totalContract) * 100) : 0}%` }}
                    />
                  </div>
                  <div className="flex justify-between text-xs text-muted">
                    <span>{totalContract > 0 ? Math.round((totalPaid / totalContract) * 100) : 0}% collected</span>
                    <span>{formatCurrency(totalContract - totalPaid)} remaining</span>
                  </div>
                  <div className="space-y-2 mt-2">
                    {group.sort((a, b) => (a.milestonePercent || 0) - (b.milestonePercent || 0)).map((mi) => (
                      <button
                        key={mi.id}
                        onClick={() => router.push(`/dashboard/invoices/${mi.id}`)}
                        className={cn(
                          'w-full flex items-center justify-between p-2 rounded-lg text-sm transition-colors',
                          mi.id === invoice.id ? 'bg-accent/10 border border-accent/20' : 'hover:bg-surface-hover'
                        )}
                      >
                        <div className="flex items-center gap-2">
                          {mi.status === 'paid' ? (
                            <CheckCircle size={14} className="text-emerald-500" />
                          ) : (
                            <div className="w-3.5 h-3.5 rounded-full border-2 border-zinc-600" />
                          )}
                          <span className="text-main">{mi.milestoneName || mi.invoiceNumber}</span>
                          <span className="text-muted">({mi.milestonePercent}%)</span>
                        </div>
                        <span className={cn('font-medium', mi.status === 'paid' ? 'text-emerald-500' : 'text-main')}>
                          {formatCurrency(mi.total)}
                        </span>
                      </button>
                    ))}
                  </div>
                </CardContent>
              </Card>
            );
          })()}

          {/* Recurring Invoice Info */}
          {invoice.isRecurringTemplate && (
            <Card className="border-blue-500/20">
              <CardHeader className="pb-2">
                <CardTitle className="text-base flex items-center gap-2 text-blue-400">
                  <Repeat size={16} />
                  Recurring Template
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Frequency</span>
                  <span className="text-main capitalize">{invoice.recurringFrequency?.replace('_', ' ')}</span>
                </div>
                {invoice.recurringNextDate && (
                  <div className="flex justify-between text-sm">
                    <span className="text-muted">Next invoice</span>
                    <span className="text-main">{formatDate(invoice.recurringNextDate)}</span>
                  </div>
                )}
                {invoice.recurringEndDate && (
                  <div className="flex justify-between text-sm">
                    <span className="text-muted">Ends</span>
                    <span className="text-main">{formatDate(invoice.recurringEndDate)}</span>
                  </div>
                )}
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Generated</span>
                  <span className="text-main">{invoice.recurringCount || 0} invoices</span>
                </div>
                <Button
                  variant="secondary"
                  size="sm"
                  className="w-full"
                  disabled={actionLoading}
                  onClick={async () => {
                    setActionLoading(true);
                    try {
                      const newId = await generateFromRecurring(invoice.id);
                      if (newId) router.push(`/dashboard/invoices/${newId}`);
                    } catch (e) { alert(e instanceof Error ? e.message : 'Failed'); }
                    setActionLoading(false);
                  }}
                >
                  <Plus size={14} className="mr-1" />
                  Generate Next Invoice
                </Button>
              </CardContent>
            </Card>
          )}
          {invoice.recurringTemplateId && (
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-base flex items-center gap-2">
                  <Repeat size={16} className="text-muted" />
                  Recurring Series
                </CardTitle>
              </CardHeader>
              <CardContent>
                <Button
                  variant="secondary"
                  size="sm"
                  className="w-full"
                  onClick={() => router.push(`/dashboard/invoices/${invoice.recurringTemplateId}`)}
                >
                  View Template
                </Button>
              </CardContent>
            </Card>
          )}

          {/* Online Payment Link */}
          {!isPaid && invoice.status !== 'void' && (
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-base flex items-center gap-2">
                  <Link size={16} className="text-muted" />
                  Payment Link
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {invoice.paymentLinkUrl ? (
                  <>
                    <div className="flex items-center gap-2">
                      <input
                        type="text"
                        readOnly
                        value={invoice.paymentLinkUrl}
                        className="flex-1 px-3 py-2 bg-secondary border border-main rounded-lg text-xs text-muted truncate"
                      />
                      <button
                        onClick={() => { navigator.clipboard.writeText(invoice.paymentLinkUrl || ''); alert('Link copied!'); }}
                        className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
                        title="Copy link"
                      >
                        <Copy size={14} className="text-muted" />
                      </button>
                    </div>
                    <p className="text-xs text-muted">Share this link with your customer to collect payment online.</p>
                  </>
                ) : (
                  <Button
                    variant="secondary"
                    size="sm"
                    className="w-full"
                    disabled={actionLoading}
                    onClick={async () => {
                      setActionLoading(true);
                      try {
                        const url = await generatePaymentLink(invoice.id);
                        navigator.clipboard.writeText(url);
                        alert('Payment link generated and copied!');
                        window.location.reload();
                      } catch (e) { alert(e instanceof Error ? e.message : 'Failed'); }
                      setActionLoading(false);
                    }}
                  >
                    <ExternalLink size={14} className="mr-1" />
                    Generate Payment Link
                  </Button>
                )}
              </CardContent>
            </Card>
          )}

          {/* Quick Actions */}
          {!isPaid && invoice.status !== 'void' && (
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-base">Quick Actions</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <Button
                  variant="secondary"
                  size="sm"
                  className="w-full justify-start"
                  onClick={() => setShowCreditMemoModal(true)}
                >
                  <FileText size={14} className="mr-2" />
                  Issue Credit Memo
                </Button>
                {(invoice.status === 'sent' || invoice.status === 'overdue' || invoice.status === 'partial') && (
                  <Button
                    variant="secondary"
                    size="sm"
                    className="w-full justify-start"
                    onClick={() => setShowPaymentModal(true)}
                  >
                    <CreditCard size={14} className="mr-2" />
                    Record Partial Payment
                  </Button>
                )}
                {invoice.status === 'draft' && !invoice.isProgressInvoice && !invoice.isRecurringTemplate && (
                  <>
                    <Button
                      variant="secondary"
                      size="sm"
                      className="w-full justify-start"
                      onClick={() => setShowProgressModal(true)}
                    >
                      <Layers size={14} className="mr-2" />
                      Create Progress Invoices
                    </Button>
                    <Button
                      variant="secondary"
                      size="sm"
                      className="w-full justify-start"
                      onClick={() => setShowRecurringModal(true)}
                    >
                      <Repeat size={14} className="mr-2" />
                      Set Up Recurring
                    </Button>
                  </>
                )}
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Payment Modal */}
      {showPaymentModal && (
        <RecordPaymentModal
          invoice={invoice}
          onClose={() => setShowPaymentModal(false)}
        />
      )}

      {/* Late Fee Modal */}
      {showLateFeeModal && (
        <LateFeeModal
          invoice={invoice}
          onApply={applyLateFee}
          onClose={() => setShowLateFeeModal(false)}
        />
      )}

      {/* Credit Memo Modal */}
      {showCreditMemoModal && (
        <CreditMemoModal
          invoice={invoice}
          onCreateMemo={createCreditMemo}
          onClose={() => setShowCreditMemoModal(false)}
        />
      )}

      {/* Progress Invoice Modal */}
      {showProgressModal && (
        <ProgressInvoiceModal
          invoice={invoice}
          onCreate={createProgressInvoices}
          onClose={() => setShowProgressModal(false)}
        />
      )}

      {/* Recurring Invoice Modal */}
      {showRecurringModal && (
        <RecurringInvoiceModal
          invoice={invoice}
          onSetup={setupRecurringInvoice}
          onClose={() => setShowRecurringModal(false)}
        />
      )}
    </div>
  );
}

function RecordPaymentModal({ invoice, onClose }: { invoice: Invoice; onClose: () => void }) {
  const { t } = useTranslation();
  const [amount, setAmount] = useState(invoice.amountDue.toString());
  const [method, setMethod] = useState('card');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [saving, setSaving] = useState(false);
  const { recordPayment } = useInvoices();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const paymentAmount = parseFloat(amount);
    if (isNaN(paymentAmount) || paymentAmount <= 0) return;

    setSaving(true);
    try {
      await recordPayment(invoice.id, paymentAmount, method);
      onClose();
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to record payment');
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <div className="fixed inset-0 bg-black/50 z-50" onClick={onClose} />
      <div className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md z-50">
        <Card>
          <CardHeader>
            <CardTitle>{t('common.recordPayment')}</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">{t('common.amount')}</label>
                <div className="relative">
                  <DollarSign size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                  <input
                    type="number"
                    step="0.01"
                    value={amount}
                    min="0"
                    onChange={(e) => setAmount(e.target.value.replace(/[^0-9.]/g, ''))}
                    className="w-full pl-10 pr-4 py-2.5 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-main mb-1.5">{t('common.paymentMethod')}</label>
                <select
                  value={method}
                  onChange={(e) => setMethod(e.target.value)}
                  className="w-full px-4 py-2.5 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
                >
                  <option value="card">{t('common.creditCard')}</option>
                  <option value="ach">Bank Transfer (ACH)</option>
                  <option value="check">{t('common.check')}</option>
                  <option value="cash">{t('common.cash')}</option>
                  <option value="other">{t('common.other')}</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-main mb-1.5">{t('common.date')}</label>
                <input
                  type="date"
                  value={date}
                  onChange={(e) => setDate(e.target.value)}
                  className="w-full px-4 py-2.5 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
                />
              </div>

              <div className="flex gap-3 pt-4">
                <Button type="button" variant="secondary" className="flex-1" onClick={onClose}>
                  Cancel
                </Button>
                <Button type="submit" className="flex-1">
                  Record Payment
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </>
  );
}

function LateFeeModal({ invoice, onApply, onClose }: {
  invoice: Invoice;
  onApply: (id: string, amount: number, description?: string) => Promise<void>;
  onClose: () => void;
}) {
  const daysOverdue = Math.max(0, Math.floor((new Date().getTime() - new Date(invoice.dueDate).getTime()) / 86400000));
  const defaultRate = invoice.lateFeePerDay || 0;
  const [feeType, setFeeType] = useState<'flat' | 'daily' | 'percent'>('flat');
  const [feeValue, setFeeValue] = useState(defaultRate > 0 ? (defaultRate * daysOverdue).toString() : '25');
  const [saving, setSaving] = useState(false);

  const calculatedFee = (() => {
    const val = parseFloat(feeValue) || 0;
    if (feeType === 'flat') return val;
    if (feeType === 'daily') return val * daysOverdue;
    if (feeType === 'percent') return (val / 100) * invoice.amountDue;
    return 0;
  })();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (calculatedFee <= 0) return;
    setSaving(true);
    try {
      const desc = feeType === 'daily'
        ? `Late fee: $${parseFloat(feeValue).toFixed(2)}/day x ${daysOverdue} days`
        : feeType === 'percent'
        ? `Late fee: ${feeValue}% of balance`
        : `Late fee`;
      await onApply(invoice.id, calculatedFee, desc);
      onClose();
      window.location.reload();
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to apply late fee');
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <div className="fixed inset-0 bg-black/50 z-50" onClick={onClose} />
      <div className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md z-50">
        <Card>
          <CardHeader>
            <CardTitle>Apply Late Fee</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="text-sm text-muted">
                This invoice is <span className="text-red-400 font-medium">{daysOverdue} days</span> overdue.
              </div>

              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Fee Type</label>
                <select
                  value={feeType}
                  onChange={(e) => setFeeType(e.target.value as 'flat' | 'daily' | 'percent')}
                  className="w-full px-4 py-2.5 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
                >
                  <option value="flat">Flat Amount</option>
                  <option value="daily">Per Day</option>
                  <option value="percent">% of Balance</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-main mb-1.5">
                  {feeType === 'flat' ? 'Fee Amount' : feeType === 'daily' ? 'Daily Rate' : 'Percentage'}
                </label>
                <div className="relative">
                  {feeType !== 'percent' && <DollarSign size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />}
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={feeValue}
                    onChange={(e) => setFeeValue(e.target.value)}
                    className={cn(
                      "w-full pr-4 py-2.5 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50",
                      feeType !== 'percent' ? 'pl-10' : 'pl-4'
                    )}
                  />
                  {feeType === 'percent' && <span className="absolute right-3 top-1/2 -translate-y-1/2 text-muted">%</span>}
                </div>
              </div>

              <div className="p-3 bg-red-50 dark:bg-red-900/20 rounded-lg">
                <div className="flex justify-between text-sm font-medium">
                  <span className="text-muted">Late fee to add</span>
                  <span className="text-red-400">{formatCurrency(calculatedFee)}</span>
                </div>
                <div className="flex justify-between text-xs text-muted mt-1">
                  <span>New total</span>
                  <span>{formatCurrency(invoice.total + calculatedFee)}</span>
                </div>
              </div>

              <div className="flex gap-3 pt-2">
                <Button type="button" variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
                <Button type="submit" className="flex-1 bg-red-600 hover:bg-red-500" disabled={saving || calculatedFee <= 0}>
                  {saving ? 'Applying...' : 'Apply Late Fee'}
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </>
  );
}

function CreditMemoModal({ invoice, onCreateMemo, onClose }: {
  invoice: Invoice;
  onCreateMemo: (invoiceId: string, amount: number, reason: string) => Promise<string | null>;
  onClose: () => void;
}) {
  const [amount, setAmount] = useState('');
  const [reason, setReason] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const creditAmount = parseFloat(amount);
    if (isNaN(creditAmount) || creditAmount <= 0 || !reason.trim()) return;
    if (creditAmount > invoice.amountDue) {
      alert('Credit amount cannot exceed amount due');
      return;
    }
    setSaving(true);
    try {
      await onCreateMemo(invoice.id, creditAmount, reason.trim());
      onClose();
      window.location.reload();
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to create credit memo');
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <div className="fixed inset-0 bg-black/50 z-50" onClick={onClose} />
      <div className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md z-50">
        <Card>
          <CardHeader>
            <CardTitle>Issue Credit Memo</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <p className="text-sm text-muted">
                Issue a credit against invoice <span className="font-mono text-main">{invoice.invoiceNumber}</span>.
                Current balance: <span className="font-medium text-main">{formatCurrency(invoice.amountDue)}</span>
              </p>

              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Credit Amount</label>
                <div className="relative">
                  <DollarSign size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    max={invoice.amountDue}
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="0.00"
                    className="w-full pl-10 pr-4 py-2.5 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Reason</label>
                <input
                  type="text"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  placeholder="e.g. Warranty work, disputed item, goodwill adjustment"
                  className="w-full px-4 py-2.5 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
                />
              </div>

              {parseFloat(amount) > 0 && (
                <div className="p-3 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg">
                  <div className="flex justify-between text-sm font-medium">
                    <span className="text-muted">Credit to apply</span>
                    <span className="text-emerald-400">-{formatCurrency(parseFloat(amount))}</span>
                  </div>
                  <div className="flex justify-between text-xs text-muted mt-1">
                    <span>New balance due</span>
                    <span>{formatCurrency(Math.max(0, invoice.amountDue - parseFloat(amount)))}</span>
                  </div>
                </div>
              )}

              <div className="flex gap-3 pt-2">
                <Button type="button" variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
                <Button type="submit" className="flex-1" disabled={saving || !amount || !reason.trim()}>
                  {saving ? 'Creating...' : 'Issue Credit Memo'}
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </>
  );
}

function ProgressInvoiceModal({ invoice, onCreate, onClose }: {
  invoice: Invoice;
  onCreate: (data: Partial<Invoice>, milestones: { name: string; percent: number }[]) => Promise<string[]>;
  onClose: () => void;
}) {
  const [milestones, setMilestones] = useState<{ name: string; percent: string }[]>([
    { name: 'Deposit', percent: '30' },
    { name: 'Rough-in Complete', percent: '40' },
    { name: 'Final Completion', percent: '30' },
  ]);
  const [saving, setSaving] = useState(false);

  const totalPercent = milestones.reduce((sum, m) => sum + (parseFloat(m.percent) || 0), 0);
  const isValid = milestones.length >= 2 && Math.abs(totalPercent - 100) < 0.01 && milestones.every(m => m.name.trim());

  const addMilestone = () => {
    const remaining = 100 - totalPercent;
    setMilestones([...milestones, { name: '', percent: remaining > 0 ? remaining.toString() : '0' }]);
  };

  const removeMilestone = (idx: number) => {
    if (milestones.length <= 2) return;
    setMilestones(milestones.filter((_, i) => i !== idx));
  };

  const updateMilestone = (idx: number, field: 'name' | 'percent', value: string) => {
    setMilestones(milestones.map((m, i) => i === idx ? { ...m, [field]: value } : m));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isValid) return;
    setSaving(true);
    try {
      const parsed = milestones.map(m => ({ name: m.name.trim(), percent: parseFloat(m.percent) }));
      await onCreate(invoice, parsed);
      onClose();
      window.location.reload();
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to create progress invoices');
    } finally {
      setSaving(false);
    }
  };

  const usePreset = (preset: { name: string; percent: string }[]) => setMilestones(preset);

  return (
    <>
      <div className="fixed inset-0 bg-black/50 z-50" onClick={onClose} />
      <div className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-lg z-50 max-h-[90vh] overflow-y-auto">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Layers size={18} />
              Progress Invoicing
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <p className="text-sm text-muted">
                Split invoice <span className="font-mono text-main">{invoice.invoiceNumber}</span> ({formatCurrency(invoice.total)}) into milestone-based invoices.
              </p>

              {/* Presets */}
              <div>
                <label className="block text-xs font-medium text-muted uppercase tracking-wider mb-2">Quick Presets</label>
                <div className="flex gap-2 flex-wrap">
                  <button type="button" onClick={() => usePreset([{ name: 'Deposit', percent: '50' }, { name: 'Completion', percent: '50' }])} className="px-3 py-1.5 text-xs bg-secondary border border-main rounded-lg hover:bg-surface-hover transition-colors">50/50</button>
                  <button type="button" onClick={() => usePreset([{ name: 'Deposit', percent: '30' }, { name: 'Rough-in', percent: '40' }, { name: 'Completion', percent: '30' }])} className="px-3 py-1.5 text-xs bg-secondary border border-main rounded-lg hover:bg-surface-hover transition-colors">30/40/30</button>
                  <button type="button" onClick={() => usePreset([{ name: 'Deposit', percent: '33' }, { name: 'Progress', percent: '34' }, { name: 'Final', percent: '33' }])} className="px-3 py-1.5 text-xs bg-secondary border border-main rounded-lg hover:bg-surface-hover transition-colors">Thirds</button>
                  <button type="button" onClick={() => usePreset([{ name: 'Deposit', percent: '25' }, { name: 'Framing', percent: '25' }, { name: 'Rough-in', percent: '25' }, { name: 'Completion', percent: '25' }])} className="px-3 py-1.5 text-xs bg-secondary border border-main rounded-lg hover:bg-surface-hover transition-colors">Quarters</button>
                </div>
              </div>

              {/* Milestones */}
              <div className="space-y-3">
                <label className="block text-xs font-medium text-muted uppercase tracking-wider">Milestones</label>
                {milestones.map((m, idx) => (
                  <div key={idx} className="flex items-center gap-2">
                    <span className="text-xs text-muted w-5">{idx + 1}.</span>
                    <input
                      type="text"
                      value={m.name}
                      onChange={(e) => updateMilestone(idx, 'name', e.target.value)}
                      placeholder="Milestone name"
                      className="flex-1 px-3 py-2 bg-secondary border border-main rounded-lg text-sm text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
                    />
                    <div className="relative w-24">
                      <input
                        type="number"
                        step="1"
                        min="1"
                        max="100"
                        value={m.percent}
                        onChange={(e) => updateMilestone(idx, 'percent', e.target.value)}
                        className="w-full px-3 py-2 pr-8 bg-secondary border border-main rounded-lg text-sm text-main text-right focus:outline-none focus:ring-2 focus:ring-accent/50"
                      />
                      <span className="absolute right-3 top-1/2 -translate-y-1/2 text-muted text-sm">%</span>
                    </div>
                    <span className="text-xs text-muted w-20 text-right">{formatCurrency(invoice.total * (parseFloat(m.percent) || 0) / 100)}</span>
                    {milestones.length > 2 && (
                      <button type="button" onClick={() => removeMilestone(idx)} className="p-1 hover:bg-red-500/10 rounded transition-colors">
                        <X size={14} className="text-red-400" />
                      </button>
                    )}
                  </div>
                ))}
                <button type="button" onClick={addMilestone} className="flex items-center gap-1 text-sm text-accent hover:text-accent/80 transition-colors">
                  <Plus size={14} />
                  Add Milestone
                </button>
              </div>

              {/* Total check */}
              <div className={cn(
                'p-3 rounded-lg',
                Math.abs(totalPercent - 100) < 0.01 ? 'bg-emerald-50 dark:bg-emerald-900/20' : 'bg-red-50 dark:bg-red-900/20'
              )}>
                <div className="flex justify-between text-sm font-medium">
                  <span className="text-muted">Total</span>
                  <span className={Math.abs(totalPercent - 100) < 0.01 ? 'text-emerald-400' : 'text-red-400'}>
                    {totalPercent}%
                  </span>
                </div>
                {Math.abs(totalPercent - 100) >= 0.01 && (
                  <p className="text-xs text-red-400 mt-1">Must equal 100%</p>
                )}
              </div>

              <div className="flex gap-3 pt-2">
                <Button type="button" variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
                <Button type="submit" className="flex-1" disabled={saving || !isValid}>
                  {saving ? 'Creating...' : `Create ${milestones.length} Invoices`}
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </>
  );
}

function RecurringInvoiceModal({ invoice, onSetup, onClose }: {
  invoice: Invoice;
  onSetup: (data: Partial<Invoice>, frequency: 'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'semi_annual' | 'annual', startDate: Date, endDate?: Date, serviceAgreementId?: string) => Promise<string>;
  onClose: () => void;
}) {
  const [frequency, setFrequency] = useState<'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'semi_annual' | 'annual'>('monthly');
  const [startDate, setStartDate] = useState(new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0]);
  const [hasEndDate, setHasEndDate] = useState(false);
  const [endDate, setEndDate] = useState(new Date(Date.now() + 365 * 86400000).toISOString().split('T')[0]);
  const [saving, setSaving] = useState(false);

  const frequencyLabel: Record<string, string> = {
    weekly: 'Every week',
    biweekly: 'Every 2 weeks',
    monthly: 'Every month',
    quarterly: 'Every 3 months',
    semi_annual: 'Every 6 months',
    annual: 'Every year',
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      const newId = await onSetup(
        invoice,
        frequency,
        new Date(startDate),
        hasEndDate ? new Date(endDate) : undefined
      );
      onClose();
      window.location.href = `/dashboard/invoices/${newId}`;
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to set up recurring');
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <div className="fixed inset-0 bg-black/50 z-50" onClick={onClose} />
      <div className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md z-50">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Repeat size={18} />
              Set Up Recurring Invoice
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <p className="text-sm text-muted">
                Create a recurring template from invoice <span className="font-mono text-main">{invoice.invoiceNumber}</span>.
                New invoices ({formatCurrency(invoice.total)} each) will be generated automatically.
              </p>

              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Frequency</label>
                <select
                  value={frequency}
                  onChange={(e) => setFrequency(e.target.value as typeof frequency)}
                  className="w-full px-4 py-2.5 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
                >
                  <option value="weekly">Weekly</option>
                  <option value="biweekly">Bi-weekly</option>
                  <option value="monthly">Monthly</option>
                  <option value="quarterly">Quarterly</option>
                  <option value="semi_annual">Semi-annual</option>
                  <option value="annual">Annual</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Start Date</label>
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="w-full px-4 py-2.5 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
                />
              </div>

              <div>
                <label className="flex items-center gap-2 text-sm font-medium text-main mb-1.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={hasEndDate}
                    onChange={(e) => setHasEndDate(e.target.checked)}
                    className="rounded border-main"
                  />
                  Set end date
                </label>
                {hasEndDate && (
                  <input
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    className="w-full px-4 py-2.5 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50 mt-2"
                  />
                )}
              </div>

              <div className="p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                <div className="flex justify-between text-sm font-medium">
                  <span className="text-muted">Amount per invoice</span>
                  <span className="text-blue-400">{formatCurrency(invoice.total)}</span>
                </div>
                <div className="flex justify-between text-xs text-muted mt-1">
                  <span>Schedule</span>
                  <span>{frequencyLabel[frequency]}</span>
                </div>
              </div>

              <div className="flex gap-3 pt-2">
                <Button type="button" variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
                <Button type="submit" className="flex-1" disabled={saving}>
                  {saving ? 'Setting up...' : 'Create Recurring Template'}
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </>
  );
}
