'use client';

import { useState, useEffect } from 'react';
import {
  Plus,
  FileDiff,
  Clock,
  Calendar,
  CheckCircle,
  XCircle,
  DollarSign,
  ArrowUpRight,
  ArrowDownRight,
  User,
  Briefcase,
  Send,
  Loader2,
  Trash2,
} from 'lucide-react';
import { getSupabase } from '@/lib/supabase';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useChangeOrders } from '@/lib/hooks/use-change-orders';
import type { ChangeOrderData } from '@/lib/hooks/mappers';
import { useTranslation } from '@/lib/translations';

type ChangeOrderStatus = 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'voided';

const statusConfig: Record<ChangeOrderStatus, { label: string; color: string; bgColor: string }> = {
  draft: { label: 'Draft', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
  pending_approval: { label: 'Pending Approval', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  approved: { label: 'Approved', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  rejected: { label: 'Rejected', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  voided: { label: 'Voided', color: 'text-slate-700 dark:text-slate-300', bgColor: 'bg-slate-100 dark:bg-slate-900/30' },
};

export default function ChangeOrdersPage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [showNewModal, setShowNewModal] = useState(false);
  const [selectedCO, setSelectedCO] = useState<ChangeOrderData | null>(null);
  const { changeOrders, loading, createChangeOrder } = useChangeOrders();

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-40 mb-2" /><div className="skeleton h-4 w-64" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-14" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(4)].map((_, i) => <div key={i} className="px-6 py-4 flex items-center gap-4"><div className="flex-1"><div className="skeleton h-4 w-36 mb-2" /><div className="skeleton h-3 w-28" /></div><div className="skeleton h-5 w-16 rounded-full" /></div>)}
        </div>
      </div>
    );
  }

  const filteredCOs = changeOrders.filter((co) => {
    const matchesSearch =
      co.title.toLowerCase().includes(search.toLowerCase()) ||
      co.customerName.toLowerCase().includes(search.toLowerCase()) ||
      co.number.toLowerCase().includes(search.toLowerCase()) ||
      co.jobName.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || co.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const pendingCount = changeOrders.filter((co) => co.status === 'pending_approval').length;
  const approvedTotal = changeOrders.filter((co) => co.status === 'approved').reduce((sum, co) => sum + co.amount, 0);
  const pendingTotal = changeOrders.filter((co) => co.status === 'pending_approval').reduce((sum, co) => sum + co.amount, 0);
  const totalCOs = changeOrders.length;

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('changeOrders.title')}</h1>
          <p className="text-muted mt-1">Manage scope changes, customer approvals, and cost adjustments</p>
        </div>
        <Button onClick={() => setShowNewModal(true)}><Plus size={16} />{t('common.newChangeOrder')}</Button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg"><Clock size={20} className="text-amber-600 dark:text-amber-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{pendingCount}</p><p className="text-sm text-muted">{t('common.pendingApproval')}</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg"><ArrowUpRight size={20} className="text-emerald-600 dark:text-emerald-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{formatCurrency(approvedTotal)}</p><p className="text-sm text-muted">Approved Additions</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg"><DollarSign size={20} className="text-cyan-600 dark:text-cyan-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{formatCurrency(pendingTotal)}</p><p className="text-sm text-muted">Pending Value</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg"><Calendar size={20} className="text-purple-600 dark:text-purple-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{totalCOs}</p><p className="text-sm text-muted">Total COs</p></div>
        </div></CardContent></Card>
      </div>

      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search change orders..." className="sm:w-80" />
        <Select options={[{ value: 'all', label: 'All Statuses' }, ...Object.entries(statusConfig).map(([k, v]) => ({ value: k, label: v.label }))]} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="sm:w-48" />
      </div>

      <div className="space-y-3">
        {filteredCOs.map((co) => {
          const sConfig = statusConfig[co.status];
          const isIncrease = co.amount >= 0;
          return (
            <Card key={co.id} className="hover:border-accent/30 transition-colors cursor-pointer" onClick={() => setSelectedCO(co)}>
              <CardContent className="p-5">
                <div className="flex items-start justify-between">
                  <div className="flex items-start gap-4 flex-1">
                    <div className={cn('p-2.5 rounded-lg', isIncrease ? 'bg-emerald-100 dark:bg-emerald-900/30' : 'bg-red-100 dark:bg-red-900/30')}>
                      {isIncrease ? <ArrowUpRight size={22} className="text-emerald-600 dark:text-emerald-400" /> : <ArrowDownRight size={22} className="text-red-600 dark:text-red-400" />}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-sm font-mono text-muted">{co.number}</span>
                        <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>{sConfig.label}</span>
                        {co.approvedByName && co.status === 'approved' && <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300">{t('common.approved')}</span>}
                      </div>
                      <h3 className="font-medium text-main mb-1">{co.title}</h3>
                      <div className="flex items-center gap-4 text-sm text-muted">
                        <span className="flex items-center gap-1"><Briefcase size={14} />{co.jobName}</span>
                        <span className="flex items-center gap-1"><User size={14} />{co.customerName}</span>
                      </div>
                      <p className="text-sm text-muted mt-1 line-clamp-1">{co.reason}</p>
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0 ml-4">
                    <p className={cn('text-lg font-semibold', isIncrease ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400')}>
                      {isIncrease ? '+' : ''}{formatCurrency(co.amount)}
                    </p>
                    <p className="text-sm text-muted">{co.items.length} item{co.items.length !== 1 ? 's' : ''}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}

        {filteredCOs.length === 0 && (
          <Card><CardContent className="p-12 text-center">
            <FileDiff size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('common.noChangeOrdersFound')}</h3>
            <p className="text-muted mb-4">Change orders track scope modifications, cost adjustments, and customer approvals.</p>
            <Button onClick={() => setShowNewModal(true)}><Plus size={16} />{t('common.newChangeOrder')}</Button>
          </CardContent></Card>
        )}
      </div>

      {selectedCO && <CODetailModal co={selectedCO} onClose={() => setSelectedCO(null)} />}
      {showNewModal && <NewCOModal onClose={() => setShowNewModal(false)} onCreate={createChangeOrder} />}
    </div>
  );
}

function CODetailModal({ co, onClose }: { co: ChangeOrderData; onClose: () => void }) {
  const sConfig = statusConfig[co.status];
  const isIncrease = co.amount >= 0;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="text-sm font-mono text-muted">{co.number}</span>
              <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>{sConfig.label}</span>
            </div>
            <CardTitle>{co.title}</CardTitle>
          </div>
          <Button variant="ghost" size="sm" onClick={onClose}><XCircle size={18} /></Button>
        </CardHeader>
        <CardContent className="space-y-6">
          <p className="text-muted">{co.description}</p>

          <div className="grid grid-cols-2 gap-4">
            <div><p className="text-xs text-muted uppercase tracking-wider">Job</p><p className="font-medium text-main">{co.jobName}</p></div>
            <div><p className="text-xs text-muted uppercase tracking-wider">Customer</p><p className="font-medium text-main">{co.customerName}</p></div>
            <div><p className="text-xs text-muted uppercase tracking-wider">Reason</p><p className="font-medium text-main">{co.reason}</p></div>
            <div><p className="text-xs text-muted uppercase tracking-wider">Created</p><p className="font-medium text-main">{formatDate(co.createdAt)}</p></div>
          </div>

          <div>
            <p className="text-xs text-muted uppercase tracking-wider mb-3">Line Items</p>
            <div className="border border-main rounded-lg overflow-hidden">
              <table className="w-full">
                <thead><tr className="bg-secondary">
                  <th className="text-left text-xs font-medium text-muted px-4 py-2">Description</th>
                  <th className="text-right text-xs font-medium text-muted px-4 py-2">Qty</th>
                  <th className="text-right text-xs font-medium text-muted px-4 py-2">Unit Price</th>
                  <th className="text-right text-xs font-medium text-muted px-4 py-2">Total</th>
                </tr></thead>
                <tbody>
                  {co.items.map((item, i) => (
                    <tr key={i} className="border-t border-main/50">
                      <td className="px-4 py-2 text-sm text-main">{item.description}</td>
                      <td className="px-4 py-2 text-sm text-main text-right">{item.quantity}</td>
                      <td className="px-4 py-2 text-sm text-main text-right">{formatCurrency(item.unitPrice)}</td>
                      <td className="px-4 py-2 text-sm font-medium text-main text-right">{formatCurrency(item.total)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          <div className="p-4 bg-secondary rounded-lg">
            <div className="flex items-center justify-between">
              <span className="font-medium text-main">Change Order Amount</span>
              <span className={cn('text-lg font-semibold', isIncrease ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400')}>{isIncrease ? '+' : ''}{formatCurrency(co.amount)}</span>
            </div>
          </div>

          {co.approvedByName && (
            <div className="flex items-center gap-2 p-3 bg-emerald-50 dark:bg-emerald-900/10 rounded-lg">
              <CheckCircle size={16} className="text-emerald-600" />
              <span className="text-sm text-emerald-700 dark:text-emerald-300">Approved by {co.approvedByName} on {co.approvedAt ? formatDate(co.approvedAt) : 'N/A'}</span>
            </div>
          )}

          {co.notes && <div><p className="text-xs text-muted uppercase tracking-wider mb-1">Notes</p><p className="text-sm text-main">{co.notes}</p></div>}

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Close</Button>
            {co.status === 'draft' && <Button className="flex-1"><Send size={16} />Send for Approval</Button>}
            {co.status === 'pending_approval' && <Button className="flex-1"><CheckCircle size={16} />Mark Approved</Button>}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

interface COLineItem {
  description: string;
  quantity: string;
  unitPrice: string;
}

function NewCOModal({ onClose, onCreate }: {
  onClose: () => void;
  onCreate: (input: { jobId: string; title: string; description: string; reason?: string; items?: { description: string; quantity: number; unitPrice: number; total: number }[]; amount: number; notes?: string }) => Promise<string>;
}) {
  const [jobs, setJobs] = useState<{ id: string; title: string; customerName: string }[]>([]);
  const [jobId, setJobId] = useState('');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [reason, setReason] = useState('customer_request');
  const [notes, setNotes] = useState('');
  const [scheduleImpact, setScheduleImpact] = useState('');
  const [lineItems, setLineItems] = useState<COLineItem[]>([{ description: '', quantity: '1', unitPrice: '' }]);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const fetchJobs = async () => {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('jobs')
        .select('id, title, customer_name')
        .is('deleted_at', null)
        .in('status', ['draft', 'scheduled', 'in_progress', 'on_hold'])
        .order('created_at', { ascending: false })
        .limit(100);
      if (data) setJobs(data.map((j: Record<string, unknown>) => ({ id: j.id as string, title: (j.title as string) || '', customerName: (j.customer_name as string) || '' })));
    };
    fetchJobs();
  }, []);

  const addLineItem = () => setLineItems((prev) => [...prev, { description: '', quantity: '1', unitPrice: '' }]);
  const removeLineItem = (idx: number) => setLineItems((prev) => prev.filter((_, i) => i !== idx));
  const updateLineItem = (idx: number, field: keyof COLineItem, val: string) => {
    setLineItems((prev) => prev.map((item, i) => i === idx ? { ...item, [field]: val } : item));
  };

  const computedTotal = lineItems.reduce((sum, item) => {
    const qty = parseFloat(item.quantity) || 0;
    const price = parseFloat(item.unitPrice) || 0;
    return sum + qty * price;
  }, 0);

  const handleSubmit = async () => {
    if (!jobId || !title.trim() || !description.trim()) return;
    setSaving(true);
    try {
      const items = lineItems
        .filter((li) => li.description.trim() && li.unitPrice)
        .map((li) => ({
          description: li.description.trim(),
          quantity: parseFloat(li.quantity) || 1,
          unitPrice: parseFloat(li.unitPrice) || 0,
          total: (parseFloat(li.quantity) || 1) * (parseFloat(li.unitPrice) || 0),
        }));

      await onCreate({
        jobId,
        title: title.trim(),
        description: description.trim(),
        reason,
        items: items.length > 0 ? items : undefined,
        amount: items.length > 0 ? computedTotal : 0,
        notes: notes.trim() ? `${notes.trim()}${scheduleImpact ? `\nSchedule Impact: ${scheduleImpact} day(s)` : ''}` : scheduleImpact ? `Schedule Impact: ${scheduleImpact} day(s)` : undefined,
      });
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to create change order');
    } finally {
      setSaving(false);
    }
  };

  const inputCls = "w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent";

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader><CardTitle>New Change Order</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Job *</label>
            <select value={jobId} onChange={(e) => setJobId(e.target.value)} className={inputCls}>
              <option value="">Select job</option>
              {jobs.map((j) => (
                <option key={j.id} value={j.id}>{j.title || 'Untitled'} — {j.customerName}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Title *</label>
            <input type="text" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Add EV charger circuit" className={inputCls} />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Description *</label>
            <textarea rows={3} value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Detailed description of the scope change..." className={`${inputCls} resize-none`} />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Reason</label>
              <select value={reason} onChange={(e) => setReason(e.target.value)} className={inputCls}>
                <option value="customer_request">Customer Request</option>
                <option value="discovered_during_work">Discovered During Work</option>
                <option value="code_requirement">Code Requirement</option>
                <option value="design_change">Design Change</option>
                <option value="contractor_recommendation">Contractor Recommendation</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Schedule Impact (days)</label>
              <input type="number" value={scheduleImpact} onChange={(e) => setScheduleImpact(e.target.value)} placeholder="0" className={inputCls} />
            </div>
          </div>

          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="block text-sm font-medium text-main">Line Items</label>
              <button type="button" onClick={addLineItem} className="text-xs text-accent hover:underline flex items-center gap-1">
                <Plus size={12} /> Add Item
              </button>
            </div>
            <div className="space-y-2">
              {lineItems.map((item, idx) => (
                <div key={idx} className="grid grid-cols-12 gap-2 items-start">
                  <input type="text" value={item.description} onChange={(e) => updateLineItem(idx, 'description', e.target.value)} placeholder="Description" className={`col-span-6 ${inputCls}`} />
                  <input type="number" value={item.quantity} onChange={(e) => updateLineItem(idx, 'quantity', e.target.value)} placeholder="Qty" min="0" step="0.01" className={`col-span-2 ${inputCls}`} />
                  <input type="number" value={item.unitPrice} onChange={(e) => updateLineItem(idx, 'unitPrice', e.target.value)} placeholder="Price" min="0" step="0.01" className={`col-span-3 ${inputCls}`} />
                  <button type="button" onClick={() => removeLineItem(idx)} disabled={lineItems.length <= 1} className="col-span-1 flex items-center justify-center h-[42px] text-muted hover:text-red-500 disabled:opacity-30">
                    <Trash2 size={14} />
                  </button>
                </div>
              ))}
            </div>
            <div className="flex justify-end mt-2">
              <span className="text-sm font-semibold text-main">Total: ${computedTotal.toFixed(2)}</span>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
            <textarea rows={2} value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Internal notes..." className={`${inputCls} resize-none`} />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>Cancel</Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !jobId || !title.trim() || !description.trim()}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <Plus size={16} />}
              {saving ? 'Creating...' : 'Create Change Order'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
