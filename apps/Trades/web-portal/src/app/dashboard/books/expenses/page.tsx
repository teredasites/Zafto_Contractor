'use client';

import { useState, useRef } from 'react';
import {
  Plus, Search, ArrowLeft, Check, X, Ban, Upload,
  Receipt, Calendar, DollarSign, Tag, Building2, Percent,
} from 'lucide-react';
import Link from 'next/link';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import {
  useExpenses,
  EXPENSE_CATEGORIES,
  EXPENSE_CATEGORY_LABELS,
  PAYMENT_METHODS,
  PAYMENT_METHOD_LABELS,
} from '@/lib/hooks/use-expenses';
import { useVendors } from '@/lib/hooks/use-vendors';
import { useProperties } from '@/lib/hooks/use-properties';
import type { ExpenseData } from '@/lib/hooks/use-expenses';
import { useTranslation } from '@/lib/translations';

const statusConfig: Record<string, { label: string; variant: 'default' | 'success' | 'warning' | 'error' }> = {
  draft: { label: 'Draft', variant: 'default' },
  approved: { label: 'Approved', variant: 'warning' },
  posted: { label: 'Posted', variant: 'success' },
  voided: { label: 'Voided', variant: 'error' },
};

export default function ExpensesPage() {
  const { t } = useTranslation();
  const [statusFilter, setStatusFilter] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [search, setSearch] = useState('');

  const { expenses, loading, error, createExpense, approveExpense, postExpense, voidExpense, totalByCategory, grandTotal } = useExpenses({
    status: statusFilter || undefined,
    category: categoryFilter || undefined,
    dateFrom: dateFrom || undefined,
    dateTo: dateTo || undefined,
  });
  const { vendors } = useVendors();
  const { properties } = useProperties();
  const [propertyFilter, setPropertyFilter] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [voidId, setVoidId] = useState<string | null>(null);
  const [voidReason, setVoidReason] = useState('');

  const filtered = expenses.filter((e) => {
    const q = search.toLowerCase();
    const matchesSearch = !search || e.description.toLowerCase().includes(q) || (e.vendorName?.toLowerCase().includes(q) ?? false);
    const matchesProperty = !propertyFilter || e.propertyId === propertyFilter;
    return matchesSearch && matchesProperty;
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-2 border-accent border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/dashboard/books" className="p-2 hover:bg-surface-hover rounded-lg transition-colors">
            <ArrowLeft size={18} className="text-muted" />
          </Link>
          <div>
            <h1 className="text-2xl font-semibold text-main">{t('booksExpenses.title')}</h1>
            <p className="text-muted mt-0.5">{expenses.length} records</p>
          </div>
        </div>
        <Button onClick={() => setModalOpen(true)}>
          <Plus size={16} />
          New Expense
        </Button>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wide">{t('common.total')}</p>
          <p className="text-xl font-semibold text-main mt-1 tabular-nums">{formatCurrency(grandTotal)}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wide">Draft</p>
          <p className="text-xl font-semibold text-main mt-1">{expenses.filter((e) => e.status === 'draft').length}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wide">{t('common.pendingApproval')}</p>
          <p className="text-xl font-semibold text-amber-600 mt-1">{expenses.filter((e) => e.status === 'draft').length}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wide">Posted</p>
          <p className="text-xl font-semibold text-emerald-600 mt-1">{expenses.filter((e) => e.status === 'posted').length}</p>
        </CardContent></Card>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="relative flex-1 max-w-xs">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
          <Input placeholder={t('common.searchPlaceholder')} value={search} onChange={(e) => setSearch(e.target.value)} className="pl-9" />
        </div>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm">
          <option value="">All Statuses</option>
          <option value="draft">Draft</option>
          <option value="approved">Approved</option>
          <option value="posted">Posted</option>
          <option value="voided">Voided</option>
        </select>
        <select value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)} className="px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm">
          <option value="">All Categories</option>
          {EXPENSE_CATEGORIES.map((c) => <option key={c} value={c}>{EXPENSE_CATEGORY_LABELS[c]}</option>)}
        </select>
        <Input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} className="w-36" placeholder="From" />
        <Input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} className="w-36" placeholder="To" />
        <select value={propertyFilter} onChange={(e) => setPropertyFilter(e.target.value)} className="px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm">
          <option value="">All Properties</option>
          {properties.map((p) => <option key={p.id} value={p.id}>{p.addressLine1 || p.city}</option>)}
        </select>
      </div>

      {error && (
        <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-700 dark:text-red-300 text-sm">{error}</div>
      )}

      {/* Expense Table */}
      <Card>
        <CardContent className="p-0">
          {/* Header */}
          <div className="grid grid-cols-12 gap-2 px-6 py-3 text-xs font-medium text-muted uppercase tracking-wide bg-secondary/50 border-b border-main">
            <div className="col-span-1">Date</div>
            <div className="col-span-2">Description</div>
            <div className="col-span-2">Vendor</div>
            <div className="col-span-1">Category</div>
            <div className="col-span-1">{t('common.property')}</div>
            <div className="col-span-1">Method</div>
            <div className="col-span-1 text-right">Amount</div>
            <div className="col-span-1">Status</div>
            <div className="col-span-2 text-right">Actions</div>
          </div>
          <div className="divide-y divide-main">
            {filtered.length === 0 && (
              <div className="px-6 py-16 text-center">
                <Receipt size={40} className="mx-auto mb-3 text-muted opacity-50" />
                <p className="text-sm font-medium text-main">No expenses found</p>
                <p className="text-xs text-muted mt-1">Record your first expense to start tracking costs</p>
              </div>
            )}
            {filtered.map((expense) => {
              const sc = statusConfig[expense.status] || statusConfig.draft;
              return (
                <div key={expense.id} className="grid grid-cols-12 gap-2 px-6 py-3 items-center hover:bg-surface-hover transition-colors">
                  <div className="col-span-1 text-sm text-muted tabular-nums">{expense.expenseDate}</div>
                  <div className="col-span-2">
                    <p className="text-sm font-medium text-main truncate">{expense.description}</p>
                    {expense.jobTitle && <p className="text-xs text-muted truncate">Job: {expense.jobTitle}</p>}
                  </div>
                  <div className="col-span-2 text-sm text-muted truncate">{expense.vendorName || '—'}</div>
                  <div className="col-span-1"><Badge variant="default" size="sm">{EXPENSE_CATEGORY_LABELS[expense.category] || expense.category}</Badge></div>
                  <div className="col-span-1 text-xs text-muted truncate">{expense.propertyAddress || '—'}</div>
                  <div className="col-span-1 text-xs text-muted">{PAYMENT_METHOD_LABELS[expense.paymentMethod] || expense.paymentMethod}</div>
                  <div className="col-span-1 text-right text-sm font-medium text-main tabular-nums">{formatCurrency(expense.total)}</div>
                  <div className="col-span-1"><Badge variant={sc.variant} size="sm">{sc.label}</Badge></div>
                  <div className="col-span-2 flex items-center justify-end gap-1">
                    {expense.receiptUrl && (
                      <a href={expense.receiptUrl} target="_blank" rel="noreferrer" className="p-1 text-muted hover:text-main rounded transition-colors">
                        <Receipt size={14} />
                      </a>
                    )}
                    {expense.status === 'draft' && (
                      <button onClick={() => approveExpense(expense.id)} className="p-1 text-muted hover:text-amber-600 rounded transition-colors" title="Approve">
                        <Check size={14} />
                      </button>
                    )}
                    {expense.status === 'approved' && (
                      <button onClick={() => postExpense(expense.id)} className="p-1 text-muted hover:text-emerald-600 rounded transition-colors" title="Post to GL">
                        <DollarSign size={14} />
                      </button>
                    )}
                    {(expense.status === 'posted' || expense.status === 'approved') && (
                      <button onClick={() => setVoidId(expense.id)} className="p-1 text-muted hover:text-red-600 rounded transition-colors" title="Void">
                        <Ban size={14} />
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* New Expense Modal */}
      {modalOpen && (
        <ExpenseModal
          vendors={vendors}
          properties={properties}
          onSave={async (data) => {
            await createExpense(data);
            setModalOpen(false);
          }}
          onClose={() => setModalOpen(false)}
        />
      )}

      {/* Void Reason Modal */}
      {voidId && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={() => setVoidId(null)}>
          <div className="bg-surface rounded-xl shadow-2xl w-full max-w-sm border border-main p-6" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-semibold text-main mb-4">{t('common.voidExpense')}</h3>
            <textarea value={voidReason} onChange={(e) => setVoidReason(e.target.value)} placeholder="Reason for voiding..." rows={3} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm resize-none mb-4" />
            <div className="flex justify-end gap-3">
              <Button variant="secondary" onClick={() => { setVoidId(null); setVoidReason(''); }}>{t('common.cancel')}</Button>
              <Button className="bg-red-600 hover:bg-red-700 text-white" onClick={async () => {
                await voidExpense(voidId, voidReason || 'Voided by admin');
                setVoidId(null);
                setVoidReason('');
              }}>{t('common.voidExpense')}</Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function ExpenseModal({ vendors, properties, onSave, onClose }: {
  vendors: { id: string; vendorName: string }[];
  properties: { id: string; addressLine1: string; city: string }[];
  onSave: (data: Parameters<ReturnType<typeof useExpenses>['createExpense']>[0]) => Promise<void>;
  onClose: () => void;
}) {
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  const [vendorId, setVendorId] = useState('');
  const [expenseDate, setExpenseDate] = useState(new Date().toISOString().split('T')[0]);
  const [description, setDescription] = useState('');
  const [amount, setAmount] = useState('');
  const [taxAmount, setTaxAmount] = useState('');
  const [category, setCategory] = useState('materials');
  const [paymentMethod, setPaymentMethod] = useState('credit_card');
  const [checkNumber, setCheckNumber] = useState('');
  const [notes, setNotes] = useState('');
  const [receiptFile, setReceiptFile] = useState<File | null>(null);
  const [propertyId, setPropertyId] = useState('');
  const [scheduleECategory, setScheduleECategory] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setErr(null);
    try {
      if (!description.trim()) throw new Error('Description is required');
      if (!amount || Number(amount) <= 0) throw new Error('Amount must be positive');
      await onSave({
        vendorId: vendorId || undefined,
        expenseDate,
        description: description.trim(),
        amount: Number(amount),
        taxAmount: taxAmount ? Number(taxAmount) : undefined,
        category,
        paymentMethod,
        checkNumber: checkNumber || undefined,
        notes: notes || undefined,
        receiptFile: receiptFile || undefined,
        propertyId: propertyId || undefined,
        scheduleECategory: scheduleECategory || undefined,
      });
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Save failed');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-surface rounded-xl shadow-2xl w-full max-w-lg border border-main max-h-[85vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
        <div className="px-6 py-4 border-b border-main">
          <h2 className="text-lg font-semibold text-main">New Expense</h2>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1">Date *</label>
              <Input type="date" value={expenseDate} onChange={(e) => setExpenseDate(e.target.value)} required />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">Vendor</label>
              <select value={vendorId} onChange={(e) => setVendorId(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm">
                <option value="">None</option>
                {vendors.filter((v) => v.vendorName).map((v) => <option key={v.id} value={v.id}>{v.vendorName}</option>)}
              </select>
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1">Description *</label>
            <Input value={description} onChange={(e) => setDescription(e.target.value)} required />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1">Property</label>
              <select value={propertyId} onChange={(e) => setPropertyId(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm">
                <option value="">None (Business)</option>
                {properties.map((p) => <option key={p.id} value={p.id}>{p.addressLine1 || p.city}</option>)}
              </select>
            </div>
            {propertyId && (
              <div>
                <label className="block text-sm font-medium text-main mb-1">Schedule E Category</label>
                <select value={scheduleECategory} onChange={(e) => setScheduleECategory(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm">
                  <option value="">Select...</option>
                  <option value="advertising">Advertising</option>
                  <option value="auto_and_travel">Auto and travel</option>
                  <option value="cleaning_maintenance">Cleaning and maintenance</option>
                  <option value="commissions">Commissions</option>
                  <option value="insurance">Insurance</option>
                  <option value="legal_professional">Legal/professional fees</option>
                  <option value="management_fees">Management fees</option>
                  <option value="mortgage_interest">Mortgage interest</option>
                  <option value="other_interest">Other interest</option>
                  <option value="repairs">Repairs</option>
                  <option value="supplies">Supplies</option>
                  <option value="taxes">Taxes</option>
                  <option value="utilities">Utilities</option>
                  <option value="depreciation">Depreciation</option>
                  <option value="other">Other expenses</option>
                </select>
              </div>
            )}
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1">Amount *</label>
              <Input type="number" step="0.01" min="0.01" value={amount} onChange={(e) => setAmount(e.target.value.replace(/[^0-9.]/g, ''))} required />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">Tax Amount</label>
              <Input type="number" step="0.01" min="0" value={taxAmount} onChange={(e) => setTaxAmount(e.target.value.replace(/[^0-9.]/g, ''))} />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1">Category</label>
              <select value={category} onChange={(e) => setCategory(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm">
                {EXPENSE_CATEGORIES.map((c) => <option key={c} value={c}>{EXPENSE_CATEGORY_LABELS[c]}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">Payment Method</label>
              <select value={paymentMethod} onChange={(e) => setPaymentMethod(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm">
                {PAYMENT_METHODS.map((m) => <option key={m} value={m}>{PAYMENT_METHOD_LABELS[m]}</option>)}
              </select>
            </div>
          </div>
          {paymentMethod === 'check' && (
            <div>
              <label className="block text-sm font-medium text-main mb-1">Check Number</label>
              <Input value={checkNumber} onChange={(e) => setCheckNumber(e.target.value)} />
            </div>
          )}
          <div>
            <label className="block text-sm font-medium text-main mb-1">Receipt</label>
            <div className="flex items-center gap-3">
              <input type="file" ref={fileRef} accept="image/*,.pdf" className="hidden" onChange={(e) => setReceiptFile(e.target.files?.[0] || null)} />
              <Button type="button" variant="secondary" size="sm" onClick={() => fileRef.current?.click()}>
                <Upload size={14} />
                {receiptFile ? receiptFile.name : 'Upload Receipt'}
              </Button>
              {receiptFile && (
                <button type="button" onClick={() => setReceiptFile(null)} className="text-muted hover:text-red-600">
                  <X size={14} />
                </button>
              )}
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1">Notes</label>
            <textarea value={notes} onChange={(e) => setNotes(e.target.value)} rows={2} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm resize-none" />
          </div>
          {err && <p className="text-sm text-red-600">{err}</p>}
          <div className="flex justify-end gap-3 pt-2">
            <Button type="button" variant="secondary" onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={saving}>{saving ? 'Saving...' : 'Create Expense'}</Button>
          </div>
        </form>
      </div>
    </div>
  );
}
