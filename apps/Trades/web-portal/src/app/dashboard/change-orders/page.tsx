'use client';

import { useState } from 'react';
import {
  Plus,
  Search,
  FileDiff,
  FileText,
  Clock,
  Calendar,
  AlertTriangle,
  CheckCircle,
  XCircle,
  MoreHorizontal,
  ArrowRight,
  DollarSign,
  ArrowUpRight,
  ArrowDownRight,
  User,
  Briefcase,
  Pen,
  Send,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';

type ChangeOrderStatus = 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'completed';

interface ChangeOrderItem {
  description: string;
  quantity: number;
  unitPrice: number;
  total: number;
}

interface ChangeOrder {
  id: string;
  number: string;
  status: ChangeOrderStatus;
  jobId: string;
  jobName: string;
  customerId: string;
  customerName: string;
  title: string;
  description: string;
  reason: string;
  items: ChangeOrderItem[];
  originalJobTotal: number;
  changeAmount: number;
  newJobTotal: number;
  createdAt: Date;
  sentAt?: Date;
  approvedAt?: Date;
  approvedBy?: string;
  customerSignature?: boolean;
  scheduledDaysImpact: number;
  notes?: string;
}

const statusConfig: Record<ChangeOrderStatus, { label: string; color: string; bgColor: string }> = {
  draft: { label: 'Draft', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
  pending_approval: { label: 'Pending Approval', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  approved: { label: 'Approved', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  rejected: { label: 'Rejected', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  completed: { label: 'Completed', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
};

const mockChangeOrders: ChangeOrder[] = [
  {
    id: 'co1', number: 'CO-2026-001', status: 'pending_approval',
    jobId: 'j1', jobName: 'Full Home Rewire - 123 Oak Ave',
    customerId: 'c1', customerName: 'Robert Chen',
    title: 'Add EV Charger Circuit',
    description: 'Customer requested addition of 50A dedicated circuit for Level 2 EV charger in garage.',
    reason: 'Customer request - new electric vehicle purchase',
    items: [
      { description: '50A breaker and GFCI protection', quantity: 1, unitPrice: 185, total: 185 },
      { description: '6/3 NM-B wire (45 ft run)', quantity: 45, unitPrice: 4.50, total: 202.50 },
      { description: 'NEMA 14-50 outlet and box', quantity: 1, unitPrice: 65, total: 65 },
      { description: 'Labor - circuit installation', quantity: 4, unitPrice: 95, total: 380 },
    ],
    originalJobTotal: 15000, changeAmount: 832.50, newJobTotal: 15832.50,
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    sentAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    scheduledDaysImpact: 1,
  },
  {
    id: 'co2', number: 'CO-2026-002', status: 'approved',
    jobId: 'j2', jobName: 'HVAC Install - 456 Elm St',
    customerId: 'c2', customerName: 'Sarah Martinez',
    title: 'Upgrade to Variable Speed Blower',
    description: 'Upgrade air handler from single-speed to variable-speed blower motor for improved efficiency.',
    reason: 'Contractor recommendation for energy savings',
    items: [
      { description: 'Variable speed ECM blower motor upgrade', quantity: 1, unitPrice: 850, total: 850 },
      { description: 'Additional labor for motor swap', quantity: 2, unitPrice: 95, total: 190 },
    ],
    originalJobTotal: 12500, changeAmount: 1040, newJobTotal: 13540,
    createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
    sentAt: new Date(Date.now() - 9 * 24 * 60 * 60 * 1000),
    approvedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
    approvedBy: 'Sarah Martinez', customerSignature: true,
    scheduledDaysImpact: 0,
  },
  {
    id: 'co3', number: 'CO-2026-003', status: 'draft',
    jobId: 'j5', jobName: 'Full Roof Replacement - 555 Birch Ln',
    customerId: 'c5', customerName: 'David Wilson',
    title: 'Add Ridge Vent and Soffit Vents',
    description: 'Found inadequate attic ventilation during tear-off. Recommend adding continuous ridge vent and soffit intake vents.',
    reason: 'Discovered during work - code requirement',
    items: [
      { description: 'Ridge vent material (42 LF)', quantity: 42, unitPrice: 8, total: 336 },
      { description: 'Soffit intake vents (8 units)', quantity: 8, unitPrice: 35, total: 280 },
      { description: 'Labor - ventilation install', quantity: 6, unitPrice: 85, total: 510 },
    ],
    originalJobTotal: 18500, changeAmount: 1126, newJobTotal: 19626,
    createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    scheduledDaysImpact: 1,
    notes: 'Required per IRC R806.1 for proper attic ventilation ratio',
  },
  {
    id: 'co4', number: 'CO-2026-004', status: 'rejected',
    jobId: 'j3', jobName: 'Water Heater Replacement - 789 Industrial',
    customerId: 'c3', customerName: 'Mike Thompson',
    title: 'Upgrade to Commercial Recirculation System',
    description: 'Proposed hot water recirculation pump and dedicated return line for faster hot water delivery.',
    reason: 'Contractor recommendation',
    items: [
      { description: 'Grundfos commercial recirc pump', quantity: 1, unitPrice: 450, total: 450 },
      { description: '3/4" copper return line (80 ft)', quantity: 80, unitPrice: 12, total: 960 },
      { description: 'Labor - recirculation install', quantity: 8, unitPrice: 95, total: 760 },
    ],
    originalJobTotal: 8500, changeAmount: 2170, newJobTotal: 10670,
    createdAt: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
    sentAt: new Date(Date.now() - 13 * 24 * 60 * 60 * 1000),
    scheduledDaysImpact: 2,
    notes: 'Customer declined - budget constraints',
  },
  {
    id: 'co5', number: 'CO-2025-012', status: 'completed',
    jobId: 'j7', jobName: 'Store Buildout - 100 Main St',
    customerId: 'c5', customerName: 'David Wilson',
    title: 'Additional Lighting Circuits for Display Area',
    description: 'Customer wants dedicated circuits for track lighting in new display area not in original scope.',
    reason: 'Design change by customer',
    items: [
      { description: '20A dedicated circuits (3x)', quantity: 3, unitPrice: 285, total: 855 },
      { description: 'Track lighting rough-in (12 heads)', quantity: 12, unitPrice: 45, total: 540 },
      { description: 'Dimmer switches (3x)', quantity: 3, unitPrice: 85, total: 255 },
    ],
    originalJobTotal: 45000, changeAmount: 1650, newJobTotal: 46650,
    createdAt: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000),
    sentAt: new Date(Date.now() - 44 * 24 * 60 * 60 * 1000),
    approvedAt: new Date(Date.now() - 42 * 24 * 60 * 60 * 1000),
    approvedBy: 'David Wilson', customerSignature: true,
    scheduledDaysImpact: 2,
  },
];

export default function ChangeOrdersPage() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [showNewModal, setShowNewModal] = useState(false);
  const [selectedCO, setSelectedCO] = useState<ChangeOrder | null>(null);

  const filteredCOs = mockChangeOrders.filter((co) => {
    const matchesSearch =
      co.title.toLowerCase().includes(search.toLowerCase()) ||
      co.customerName.toLowerCase().includes(search.toLowerCase()) ||
      co.number.toLowerCase().includes(search.toLowerCase()) ||
      co.jobName.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || co.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const pendingCount = mockChangeOrders.filter((co) => co.status === 'pending_approval').length;
  const approvedTotal = mockChangeOrders.filter((co) => ['approved', 'completed'].includes(co.status)).reduce((sum, co) => sum + co.changeAmount, 0);
  const pendingTotal = mockChangeOrders.filter((co) => co.status === 'pending_approval').reduce((sum, co) => sum + co.changeAmount, 0);
  const totalImpactDays = mockChangeOrders.filter((co) => ['approved', 'completed'].includes(co.status)).reduce((sum, co) => sum + co.scheduledDaysImpact, 0);

  return (
    <div className="space-y-6">
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
          <div><p className="text-2xl font-semibold text-main">{totalImpactDays} days</p><p className="text-sm text-muted">Schedule Impact</p></div>
        </div></CardContent></Card>
      </div>

      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search change orders..." className="sm:w-80" />
        <Select options={[{ value: 'all', label: 'All Statuses' }, ...Object.entries(statusConfig).map(([k, v]) => ({ value: k, label: v.label }))]} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="sm:w-48" />
      </div>

      <div className="space-y-3">
        {filteredCOs.map((co) => {
          const sConfig = statusConfig[co.status];
          const isIncrease = co.changeAmount >= 0;
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
                        {co.customerSignature && <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300">Signed</span>}
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
                      {isIncrease ? '+' : ''}{formatCurrency(co.changeAmount)}
                    </p>
                    <p className="text-sm text-muted">{co.items.length} item{co.items.length !== 1 ? 's' : ''}</p>
                    {co.scheduledDaysImpact > 0 && <p className="text-xs text-muted mt-1">+{co.scheduledDaysImpact} day{co.scheduledDaysImpact !== 1 ? 's' : ''}</p>}
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

function CODetailModal({ co, onClose }: { co: ChangeOrder; onClose: () => void }) {
  const sConfig = statusConfig[co.status];
  const isIncrease = co.changeAmount >= 0;

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
            <div><p className="text-xs text-muted uppercase tracking-wider">Schedule Impact</p><p className="font-medium text-main">{co.scheduledDaysImpact > 0 ? `+${co.scheduledDaysImpact} day${co.scheduledDaysImpact !== 1 ? 's' : ''}` : 'No impact'}</p></div>
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
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-muted">Original Job Total</span>
              <span className="font-medium text-main">{formatCurrency(co.originalJobTotal)}</span>
            </div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-muted">Change Order Amount</span>
              <span className={cn('font-medium', isIncrease ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400')}>{isIncrease ? '+' : ''}{formatCurrency(co.changeAmount)}</span>
            </div>
            <div className="flex items-center justify-between pt-2 border-t border-main">
              <span className="font-medium text-main">New Job Total</span>
              <span className="text-lg font-semibold text-main">{formatCurrency(co.newJobTotal)}</span>
            </div>
          </div>

          {co.approvedBy && (
            <div className="flex items-center gap-2 p-3 bg-emerald-50 dark:bg-emerald-900/10 rounded-lg">
              <CheckCircle size={16} className="text-emerald-600" />
              <span className="text-sm text-emerald-700 dark:text-emerald-300">Approved by {co.approvedBy} on {co.approvedAt ? formatDate(co.approvedAt) : 'N/A'}</span>
              {co.customerSignature && <span className="text-xs text-emerald-600 ml-auto">Customer signed</span>}
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
