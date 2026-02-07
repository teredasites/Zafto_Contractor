'use client';

import { useState } from 'react';
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
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useChangeOrders } from '@/lib/hooks/use-change-orders';
import type { ChangeOrderData } from '@/lib/hooks/mappers';

type ChangeOrderStatus = 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'voided';

const statusConfig: Record<ChangeOrderStatus, { label: string; color: string; bgColor: string }> = {
  draft: { label: 'Draft', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
  pending_approval: { label: 'Pending Approval', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  approved: { label: 'Approved', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  rejected: { label: 'Rejected', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  voided: { label: 'Voided', color: 'text-slate-700 dark:text-slate-300', bgColor: 'bg-slate-100 dark:bg-slate-900/30' },
};

export default function ChangeOrdersPage() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [showNewModal, setShowNewModal] = useState(false);
  const [selectedCO, setSelectedCO] = useState<ChangeOrderData | null>(null);
  const { changeOrders, loading } = useChangeOrders();

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
          <h1 className="text-2xl font-semibold text-main">Change Orders</h1>
          <p className="text-muted mt-1">Manage scope changes, customer approvals, and cost adjustments</p>
        </div>
        <Button onClick={() => setShowNewModal(true)}><Plus size={16} />New Change Order</Button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg"><Clock size={20} className="text-amber-600 dark:text-amber-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{pendingCount}</p><p className="text-sm text-muted">Pending Approval</p></div>
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
                        {co.approvedByName && co.status === 'approved' && <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300">Approved</span>}
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
            <h3 className="text-lg font-medium text-main mb-2">No change orders found</h3>
            <p className="text-muted mb-4">Change orders track scope modifications, cost adjustments, and customer approvals.</p>
            <Button onClick={() => setShowNewModal(true)}><Plus size={16} />New Change Order</Button>
          </CardContent></Card>
        )}
      </div>

      {selectedCO && <CODetailModal co={selectedCO} onClose={() => setSelectedCO(null)} />}
      {showNewModal && <NewCOModal onClose={() => setShowNewModal(false)} />}
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

function NewCOModal({ onClose }: { onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader><CardTitle>New Change Order</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Job *</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
              <option value="">Select job</option><option value="j1">Full Home Rewire - 123 Oak Ave</option><option value="j2">HVAC Install - 456 Elm St</option><option value="j3">Water Heater Replacement</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Title *</label>
            <input type="text" placeholder="Add EV charger circuit" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent" />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Description</label>
            <textarea rows={3} placeholder="Detailed description of the scope change..." className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none" />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Reason</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
              <option value="customer_request">Customer Request</option>
              <option value="discovered_during_work">Discovered During Work</option>
              <option value="code_requirement">Code Requirement</option>
              <option value="design_change">Design Change</option>
              <option value="contractor_recommendation">Contractor Recommendation</option>
            </select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Change Amount</label>
              <input type="number" placeholder="832.50" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Schedule Impact (days)</label>
              <input type="number" placeholder="1" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
            <textarea rows={2} placeholder="Internal notes..." className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none" />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1"><Plus size={16} />Create Change Order</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
