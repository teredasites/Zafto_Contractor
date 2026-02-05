'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Search,
  Filter,
  MoreHorizontal,
  Package,
  Truck,
  CheckCircle,
  Clock,
  AlertCircle,
  FileText,
  Download,
  Send,
  Eye,
  Trash2,
  Building,
  DollarSign,
  Calendar,
  ChevronDown,
  ChevronUp,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge, Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';

type POStatus = 'draft' | 'sent' | 'confirmed' | 'partial' | 'received' | 'cancelled';

interface POLineItem {
  id: string;
  description: string;
  sku?: string;
  quantity: number;
  unitCost: number;
  total: number;
  receivedQty: number;
}

interface PurchaseOrder {
  id: string;
  poNumber: string;
  vendorId: string;
  vendorName: string;
  jobId?: string;
  jobName?: string;
  status: POStatus;
  lineItems: POLineItem[];
  subtotal: number;
  tax: number;
  shipping: number;
  total: number;
  notes?: string;
  expectedDate?: Date;
  createdAt: Date;
  updatedAt: Date;
  sentAt?: Date;
  receivedAt?: Date;
}

const statusConfig: Record<POStatus, { label: string; color: string }> = {
  draft: { label: 'Draft', color: 'default' },
  sent: { label: 'Sent', color: 'info' },
  confirmed: { label: 'Confirmed', color: 'purple' },
  partial: { label: 'Partial', color: 'warning' },
  received: { label: 'Received', color: 'success' },
  cancelled: { label: 'Cancelled', color: 'error' },
};

const mockPurchaseOrders: PurchaseOrder[] = [
  {
    id: '1',
    poNumber: 'PO-2024-001',
    vendorId: 'v1',
    vendorName: 'Electrical Supply Co.',
    jobId: 'j1',
    jobName: 'Panel Upgrade - Martinez',
    status: 'sent',
    lineItems: [
      { id: 'li1', description: '200A Main Breaker Panel', sku: 'MBP-200', quantity: 1, unitCost: 180, total: 180, receivedQty: 0 },
      { id: 'li2', description: '20A Single Pole Breaker', sku: 'SPB-20', quantity: 10, unitCost: 8, total: 80, receivedQty: 0 },
      { id: 'li3', description: '12/2 Romex Wire (250ft)', sku: 'RMX-12-250', quantity: 2, unitCost: 95, total: 190, receivedQty: 0 },
    ],
    subtotal: 450,
    tax: 28.35,
    shipping: 0,
    total: 478.35,
    expectedDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    sentAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
  },
  {
    id: '2',
    poNumber: 'PO-2024-002',
    vendorId: 'v2',
    vendorName: 'Plumbing Wholesale',
    jobId: 'j2',
    jobName: 'Bathroom Remodel - Chen',
    status: 'partial',
    lineItems: [
      { id: 'li4', description: '50 Gallon Water Heater', sku: 'WH-50G', quantity: 1, unitCost: 450, total: 450, receivedQty: 1 },
      { id: 'li5', description: '3/4" Copper Pipe (10ft)', sku: 'CP-34-10', quantity: 5, unitCost: 25, total: 125, receivedQty: 5 },
      { id: 'li6', description: 'SharkBite Fittings Assortment', sku: 'SB-ASST', quantity: 1, unitCost: 85, total: 85, receivedQty: 0 },
    ],
    subtotal: 660,
    tax: 41.58,
    shipping: 25,
    total: 726.58,
    expectedDate: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000),
    createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    sentAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
  },
  {
    id: '3',
    poNumber: 'PO-2024-003',
    vendorId: 'v1',
    vendorName: 'Electrical Supply Co.',
    status: 'draft',
    lineItems: [
      { id: 'li7', description: 'LED Recessed Light 6"', sku: 'LED-RC-6', quantity: 12, unitCost: 18, total: 216, receivedQty: 0 },
      { id: 'li8', description: 'Dimmer Switch', sku: 'DIM-SW', quantity: 3, unitCost: 35, total: 105, receivedQty: 0 },
    ],
    subtotal: 321,
    tax: 20.22,
    shipping: 0,
    total: 341.22,
    notes: 'For kitchen lighting project',
    createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
  },
  {
    id: '4',
    poNumber: 'PO-2024-004',
    vendorId: 'v3',
    vendorName: 'HVAC Distributors Inc.',
    jobId: 'j3',
    jobName: 'AC Install - Thompson',
    status: 'received',
    lineItems: [
      { id: 'li9', description: '3 Ton AC Condenser', sku: 'AC-3T', quantity: 1, unitCost: 1800, total: 1800, receivedQty: 1 },
      { id: 'li10', description: 'Evaporator Coil', sku: 'EC-3T', quantity: 1, unitCost: 650, total: 650, receivedQty: 1 },
      { id: 'li11', description: 'Line Set 25ft', sku: 'LS-25', quantity: 1, unitCost: 120, total: 120, receivedQty: 1 },
    ],
    subtotal: 2570,
    tax: 161.91,
    shipping: 75,
    total: 2806.91,
    createdAt: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
    sentAt: new Date(Date.now() - 13 * 24 * 60 * 60 * 1000),
    receivedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
  },
];

export default function PurchaseOrdersPage() {
  const router = useRouter();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [showNewPOModal, setShowNewPOModal] = useState(false);
  const [expandedPO, setExpandedPO] = useState<string | null>(null);

  const filteredPOs = mockPurchaseOrders.filter((po) => {
    const matchesSearch =
      po.poNumber.toLowerCase().includes(search.toLowerCase()) ||
      po.vendorName.toLowerCase().includes(search.toLowerCase()) ||
      po.jobName?.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || po.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'draft', label: 'Draft' },
    { value: 'sent', label: 'Sent' },
    { value: 'confirmed', label: 'Confirmed' },
    { value: 'partial', label: 'Partial' },
    { value: 'received', label: 'Received' },
    { value: 'cancelled', label: 'Cancelled' },
  ];

  // Stats
  const draftCount = mockPurchaseOrders.filter((po) => po.status === 'draft').length;
  const pendingCount = mockPurchaseOrders.filter((po) => ['sent', 'confirmed', 'partial'].includes(po.status)).length;
  const pendingValue = mockPurchaseOrders
    .filter((po) => ['sent', 'confirmed', 'partial'].includes(po.status))
    .reduce((sum, po) => sum + po.total, 0);
  const thisMonthTotal = mockPurchaseOrders
    .filter((po) => po.status === 'received')
    .reduce((sum, po) => sum + po.total, 0);

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Purchase Orders</h1>
          <p className="text-muted mt-1">Order materials and track deliveries</p>
        </div>
        <Button onClick={() => setShowNewPOModal(true)}>
          <Plus size={16} />
          New Purchase Order
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-slate-100 dark:bg-slate-800 rounded-lg">
                <FileText size={20} className="text-slate-600 dark:text-slate-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{draftCount}</p>
                <p className="text-sm text-muted">Drafts</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Truck size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{pendingCount}</p>
                <p className="text-sm text-muted">Pending Delivery</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <DollarSign size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(pendingValue)}</p>
                <p className="text-sm text-muted">Pending Value</p>
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
                <p className="text-2xl font-semibold text-main">{formatCurrency(thisMonthTotal)}</p>
                <p className="text-sm text-muted">Received This Month</p>
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
          placeholder="Search purchase orders..."
          className="sm:w-80"
        />
        <Select
          options={statusOptions}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Purchase Orders List */}
      <Card>
        <CardContent className="p-0">
          {filteredPOs.length === 0 ? (
            <div className="py-12 text-center text-muted">
              <Package size={40} className="mx-auto mb-2 opacity-50" />
              <p>No purchase orders found</p>
            </div>
          ) : (
            <div className="divide-y divide-main">
              {filteredPOs.map((po) => (
                <PORow
                  key={po.id}
                  po={po}
                  isExpanded={expandedPO === po.id}
                  onToggle={() => setExpandedPO(expandedPO === po.id ? null : po.id)}
                />
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* New PO Modal */}
      {showNewPOModal && (
        <NewPOModal onClose={() => setShowNewPOModal(false)} />
      )}
    </div>
  );
}

function PORow({ po, isExpanded, onToggle }: { po: PurchaseOrder; isExpanded: boolean; onToggle: () => void }) {
  const config = statusConfig[po.status];
  const isOverdue = po.expectedDate && new Date(po.expectedDate) < new Date() && !['received', 'cancelled'].includes(po.status);

  return (
    <div>
      <div
        className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
        onClick={onToggle}
      >
        <div className="flex items-center gap-4">
          <button className="p-1 hover:bg-surface rounded transition-colors">
            {isExpanded ? (
              <ChevronUp size={18} className="text-muted" />
            ) : (
              <ChevronDown size={18} className="text-muted" />
            )}
          </button>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-3">
              <span className="font-mono font-medium text-main">{po.poNumber}</span>
              <StatusBadge status={config.label.toLowerCase() as any} />
              {isOverdue && (
                <Badge variant="error" size="sm">
                  <AlertCircle size={12} />
                  Overdue
                </Badge>
              )}
            </div>
            <div className="flex items-center gap-4 mt-1 text-sm text-muted">
              <span className="flex items-center gap-1">
                <Building size={14} />
                {po.vendorName}
              </span>
              {po.jobName && (
                <span className="flex items-center gap-1">
                  <Package size={14} />
                  {po.jobName}
                </span>
              )}
            </div>
          </div>
          <div className="text-right">
            <p className="font-semibold text-main">{formatCurrency(po.total)}</p>
            <p className="text-sm text-muted">
              {po.expectedDate ? `Expected ${formatDate(po.expectedDate)}` : 'No date set'}
            </p>
          </div>
          <div className="flex items-center gap-1">
            <button
              onClick={(e) => { e.stopPropagation(); }}
              className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
            >
              <MoreHorizontal size={18} className="text-muted" />
            </button>
          </div>
        </div>
      </div>

      {/* Expanded Details */}
      {isExpanded && (
        <div className="px-6 pb-4 bg-secondary/30">
          <div className="ml-8 border-l-2 border-main pl-6 py-4">
            {/* Line Items */}
            <table className="w-full mb-4">
              <thead>
                <tr className="text-left text-sm text-muted border-b border-main">
                  <th className="pb-2 font-medium">Item</th>
                  <th className="pb-2 font-medium">SKU</th>
                  <th className="pb-2 font-medium text-right">Qty</th>
                  <th className="pb-2 font-medium text-right">Received</th>
                  <th className="pb-2 font-medium text-right">Unit Cost</th>
                  <th className="pb-2 font-medium text-right">Total</th>
                </tr>
              </thead>
              <tbody>
                {po.lineItems.map((item) => (
                  <tr key={item.id} className="border-b border-main/50">
                    <td className="py-2 text-main">{item.description}</td>
                    <td className="py-2 text-muted text-sm">{item.sku || '-'}</td>
                    <td className="py-2 text-right text-main">{item.quantity}</td>
                    <td className="py-2 text-right">
                      <span className={cn(
                        'font-medium',
                        item.receivedQty === item.quantity ? 'text-emerald-600' :
                        item.receivedQty > 0 ? 'text-amber-600' : 'text-muted'
                      )}>
                        {item.receivedQty}
                      </span>
                    </td>
                    <td className="py-2 text-right text-muted">{formatCurrency(item.unitCost)}</td>
                    <td className="py-2 text-right font-medium text-main">{formatCurrency(item.total)}</td>
                  </tr>
                ))}
              </tbody>
            </table>

            {/* Totals */}
            <div className="flex justify-between items-start">
              <div className="flex gap-2">
                {po.status === 'draft' && (
                  <Button size="sm">
                    <Send size={14} />
                    Send to Vendor
                  </Button>
                )}
                {['sent', 'confirmed', 'partial'].includes(po.status) && (
                  <Button size="sm" variant="secondary">
                    <CheckCircle size={14} />
                    Mark Received
                  </Button>
                )}
                <Button size="sm" variant="ghost">
                  <Download size={14} />
                  Download PDF
                </Button>
              </div>
              <div className="w-48 space-y-1 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted">Subtotal</span>
                  <span className="text-main">{formatCurrency(po.subtotal)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted">Tax</span>
                  <span className="text-main">{formatCurrency(po.tax)}</span>
                </div>
                {po.shipping > 0 && (
                  <div className="flex justify-between">
                    <span className="text-muted">Shipping</span>
                    <span className="text-main">{formatCurrency(po.shipping)}</span>
                  </div>
                )}
                <div className="flex justify-between font-semibold pt-1 border-t border-main">
                  <span>Total</span>
                  <span>{formatCurrency(po.total)}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function NewPOModal({ onClose }: { onClose: () => void }) {
  const [vendor, setVendor] = useState('');
  const [job, setJob] = useState('');

  const vendors = [
    { value: '', label: 'Select Vendor' },
    { value: 'v1', label: 'Electrical Supply Co.' },
    { value: 'v2', label: 'Plumbing Wholesale' },
    { value: 'v3', label: 'HVAC Distributors Inc.' },
  ];

  const jobs = [
    { value: '', label: 'No Job (Stock Order)' },
    { value: 'j1', label: 'Panel Upgrade - Martinez' },
    { value: 'j2', label: 'Bathroom Remodel - Chen' },
    { value: 'j3', label: 'AC Install - Thompson' },
  ];

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>New Purchase Order</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Select
            label="Vendor *"
            options={vendors}
            value={vendor}
            onChange={(e) => setVendor(e.target.value)}
          />
          <Select
            label="Link to Job (Optional)"
            options={jobs}
            value={job}
            onChange={(e) => setJob(e.target.value)}
          />
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Expected Delivery Date</label>
            <input
              type="date"
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>
              Cancel
            </Button>
            <Button className="flex-1">
              <Plus size={16} />
              Create PO
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
