'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Search,
  Receipt,
  DollarSign,
  AlertCircle,
  CheckCircle,
  Clock,
  Send,
  MoreHorizontal,
  Download,
  Mail,
  CreditCard,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge, Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { useInvoices } from '@/lib/hooks/use-invoices';
import { getSupabase } from '@/lib/supabase';
import { useStats } from '@/lib/hooks/use-stats';
import type { Invoice } from '@/types';

export default function InvoicesPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const { invoices, loading: invoicesLoading, sendInvoice, recordPayment, deleteInvoice } = useInvoices();
  const { stats: dashStats } = useStats();
  const stats = dashStats.invoices;

  if (invoicesLoading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-32 mb-2" /><div className="skeleton h-4 w-52" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-24 mb-2" /><div className="skeleton h-7 w-16" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => <div key={i} className="px-6 py-4 flex items-center gap-4"><div className="flex-1"><div className="skeleton h-4 w-28 mb-2" /><div className="skeleton h-3 w-40" /></div><div className="skeleton h-4 w-20" /></div>)}
        </div>
      </div>
    );
  }

  const filteredInvoices = invoices.filter((invoice) => {
    const matchesSearch =
      invoice.invoiceNumber.toLowerCase().includes(search.toLowerCase()) ||
      invoice.customer?.firstName?.toLowerCase().includes(search.toLowerCase()) ||
      invoice.customer?.lastName?.toLowerCase().includes(search.toLowerCase());

    const matchesStatus = statusFilter === 'all' || invoice.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'draft', label: 'Draft' },
    { value: 'sent', label: 'Sent' },
    { value: 'viewed', label: 'Viewed' },
    { value: 'paid', label: 'Paid' },
    { value: 'partial', label: 'Partial' },
    { value: 'overdue', label: 'Overdue' },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('invoices.title')}</h1>
          <p className="text-muted mt-1">{t('invoices.createAndTrackYourInvoices')}</p>
        </div>
        <Button onClick={() => router.push('/dashboard/invoices/new')}>
          <Plus size={16} />
          New Invoice
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Send size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.sent}</p>
                <p className="text-sm text-muted">{t('common.overdue')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg">
                <AlertCircle size={20} className="text-red-600 dark:text-red-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.overdue}</p>
                <p className="text-sm text-muted">{t('common.overdue')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(stats.paidThisMonth)}</p>
                <p className="text-sm text-muted">{t('invoices.paidThisMonth')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <DollarSign size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(stats.overdueAmount)}</p>
                <p className="text-sm text-muted">{t('invoices.overdueAmount')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder={t('invoices.searchInvoices')}
          className="sm:w-80"
        />
        <Select
          options={statusOptions}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Invoices Table */}
      <Card>
        <CardContent className="p-0">
          {filteredInvoices.length === 0 ? (
            <div className="py-12 text-center text-muted">
              <Receipt size={40} className="mx-auto mb-2 opacity-50" />
              <p>{t('invoices.noRecords')}</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-main">
                    <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-6 py-3">
                      Invoice
                    </th>
                    <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-6 py-3">
                      Customer
                    </th>
                    <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-6 py-3">
                      Status
                    </th>
                    <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-6 py-3">
                      Due Date
                    </th>
                    <th className="text-right text-xs font-medium text-muted uppercase tracking-wider px-6 py-3">
                      Amount
                    </th>
                    <th className="text-right text-xs font-medium text-muted uppercase tracking-wider px-6 py-3">
                      Balance
                    </th>
                    <th className="px-6 py-3"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-main">
                  {filteredInvoices.map((invoice) => (
                    <InvoiceRow
                      key={invoice.id}
                      invoice={invoice}
                      onClick={() => router.push(`/dashboard/invoices/${invoice.id}`)}
                      onSendReminder={async () => { await sendInvoice(invoice.id); }}
                      onRecordPayment={async () => {
                        const amtStr = prompt(`Record payment for ${invoice.invoiceNumber}\nAmount due: ${formatCurrency(invoice.amountDue || 0)}\n\nEnter payment amount:`);
                        if (!amtStr) return;
                        const amt = parseFloat(amtStr);
                        if (isNaN(amt) || amt <= 0) { alert('Invalid amount'); return; }
                        await recordPayment(invoice.id, amt, 'manual');
                      }}
                      onDelete={async () => { if (confirm('Delete this invoice?')) await deleteInvoice(invoice.id); }}
                      onDownloadPdf={async () => {
                        try {
                          const supabase = getSupabase();
                          const { data: { session } } = await supabase.auth.getSession();
                          if (!session) { alert('Not authenticated'); return; }
                          const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
                          const res = await fetch(`${baseUrl}/functions/v1/export-invoice-pdf?invoice_id=${invoice.id}`, {
                            headers: { 'Authorization': `Bearer ${session.access_token}`, 'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '' },
                          });
                          if (!res.ok) throw new Error(await res.text());
                          const html = await res.text();
                          const w = window.open('', '_blank');
                          if (w) { w.document.write(html); w.document.close(); }
                        } catch (e) { alert(e instanceof Error ? e.message : 'Failed to download PDF'); }
                      }}
                    />
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function InvoiceRow({ invoice, onClick, onSendReminder, onRecordPayment, onDelete, onDownloadPdf }: { invoice: Invoice; onClick: () => void; onSendReminder: () => Promise<void>; onRecordPayment: () => Promise<void>; onDelete: () => Promise<void>; onDownloadPdf: () => Promise<void> }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const isOverdue = invoice.status === 'overdue';

  return (
    <tr
      className={cn(
        'hover:bg-surface-hover cursor-pointer transition-colors',
        isOverdue && 'bg-red-50/50 dark:bg-red-900/5'
      )}
      onClick={onClick}
    >
      <td className="px-6 py-4">
        <p className="font-medium text-main">{invoice.invoiceNumber}</p>
      </td>
      <td className="px-6 py-4">
        <p className="text-main">
          {invoice.customer?.firstName} {invoice.customer?.lastName}
        </p>
      </td>
      <td className="px-6 py-4">
        <StatusBadge status={invoice.status} />
      </td>
      <td className="px-6 py-4">
        <p className={cn('text-sm', isOverdue ? 'text-red-600 dark:text-red-400 font-medium' : 'text-muted')}>
          {formatDate(invoice.dueDate)}
        </p>
      </td>
      <td className="px-6 py-4 text-right">
        <p className="font-medium text-main">{formatCurrency(invoice.total)}</p>
      </td>
      <td className="px-6 py-4 text-right">
        <p className={cn(
          'font-medium',
          invoice.amountDue > 0 ? 'text-main' : 'text-emerald-600 dark:text-emerald-400'
        )}>
          {invoice.amountDue > 0 ? formatCurrency(invoice.amountDue) : 'Paid'}
        </p>
      </td>
      <td className="px-6 py-4 text-right">
        <div className="relative">
          <button
            onClick={(e) => {
              e.stopPropagation();
              setMenuOpen(!menuOpen);
            }}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
          >
            <MoreHorizontal size={18} className="text-muted" />
          </button>
          {menuOpen && (
            <div className="absolute right-0 top-full mt-1 w-48 bg-surface border border-main rounded-lg shadow-lg py-1 z-10">
              <button onClick={async (e) => { e.stopPropagation(); setMenuOpen(false); await onSendReminder(); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                <Mail size={16} />
                Send Reminder
              </button>
              <button onClick={async (e) => { e.stopPropagation(); setMenuOpen(false); await onRecordPayment(); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                <CreditCard size={16} />
                Record Payment
              </button>
              <button onClick={async (e) => { e.stopPropagation(); setMenuOpen(false); await onDownloadPdf(); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                <Download size={16} />
                Download PDF
              </button>
            </div>
          )}
        </div>
      </td>
    </tr>
  );
}
