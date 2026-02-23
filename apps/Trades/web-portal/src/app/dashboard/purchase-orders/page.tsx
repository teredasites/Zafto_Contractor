'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Plus,
  Package,
  Truck,
  CheckCircle,
  Clock,
  AlertCircle,
  FileText,
  Download,
  Send,
  Building,
  DollarSign,
  ChevronDown,
  ChevronUp,
  X,
  MoreHorizontal,
  ClipboardList,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge, Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import { useProcurement, type POLineItem, type ReceivingRecord } from '@/lib/hooks/use-procurement';
import { useTranslation } from '@/lib/translations';

// ============================================================
// Types for purchase_orders table (fetched directly)
// ============================================================

interface PurchaseOrderData {
  id: string;
  companyId: string;
  poNumber: string;
  vendorId: string | null;
  vendorName: string;
  jobId: string | null;
  jobTitle: string;
  status: string;
  subtotal: number;
  taxAmount: number;
  shippingAmount: number;
  totalAmount: number;
  notes: string | null;
  expectedDeliveryDate: string | null;
  createdAt: string;
  updatedAt: string;
  sentAt: string | null;
  receivedAt: string | null;
}

function mapPurchaseOrder(row: Record<string, unknown>): PurchaseOrderData {
  const vendor = row.vendor_directory as Record<string, unknown> | null;
  const job = row.jobs as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    poNumber: (row.po_number as string) || '',
    vendorId: row.vendor_id as string | null,
    vendorName: (vendor?.name as string) || 'Unknown Vendor',
    jobId: row.job_id as string | null,
    jobTitle: (job?.title as string) || '',
    status: (row.status as string) || 'draft',
    subtotal: (row.subtotal as number) || 0,
    taxAmount: (row.tax_amount as number) || 0,
    shippingAmount: (row.shipping_amount as number) || 0,
    totalAmount: (row.total_amount as number) || 0,
    notes: row.notes as string | null,
    expectedDeliveryDate: row.expected_delivery_date as string | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
    sentAt: row.sent_at as string | null,
    receivedAt: row.received_at as string | null,
  };
}

const statusConfig: Record<string, { label: string; variant: string }> = {
  draft: { label: 'Draft', variant: 'default' },
  sent: { label: 'Sent', variant: 'info' },
  confirmed: { label: 'Confirmed', variant: 'purple' },
  partial: { label: 'Partial', variant: 'warning' },
  received: { label: 'Received', variant: 'success' },
  cancelled: { label: 'Cancelled', variant: 'error' },
};

const statusOptions = [
  { value: 'all', label: 'All Statuses' },
  { value: 'draft', label: 'Draft' },
  { value: 'sent', label: 'Sent' },
  { value: 'confirmed', label: 'Confirmed' },
  { value: 'partial', label: 'Partial' },
  { value: 'received', label: 'Received' },
  { value: 'cancelled', label: 'Cancelled' },
];

export default function PurchaseOrdersPage() {
  const { t } = useTranslation();
  const [purchaseOrders, setPurchaseOrders] = useState<PurchaseOrderData[]>([]);
  const [poLoading, setPOLoading] = useState(true);
  const [poError, setPOError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [expandedPO, setExpandedPO] = useState<string | null>(null);
  const [showNewPOModal, setShowNewPOModal] = useState(false);

  const { lineItems, receivingRecords, getLineItemsForPO, getReceivingForPO, loading: procLoading } = useProcurement();

  const fetchPurchaseOrders = useCallback(async () => {
    try {
      setPOLoading(true);
      setPOError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('purchase_orders')
        .select('*, vendor_directory(name), jobs(title)')
        .order('created_at', { ascending: false });

      if (err) throw err;
      setPurchaseOrders((data || []).map((r: Record<string, unknown>) => mapPurchaseOrder(r)));
    } catch (e: unknown) {
      setPOError(e instanceof Error ? e.message : 'Failed to load purchase orders');
    } finally {
      setPOLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPurchaseOrders();

    const supabase = getSupabase();
    const channel = supabase
      .channel('purchase-orders-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'purchase_orders' }, () => {
        fetchPurchaseOrders();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchPurchaseOrders]);

  const filteredPOs = useMemo(() => {
    return purchaseOrders.filter((po) => {
      const matchesSearch =
        po.poNumber.toLowerCase().includes(search.toLowerCase()) ||
        po.vendorName.toLowerCase().includes(search.toLowerCase()) ||
        po.jobTitle.toLowerCase().includes(search.toLowerCase());
      const matchesStatus = statusFilter === 'all' || po.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [purchaseOrders, search, statusFilter]);

  // Stats
  const totalPOs = purchaseOrders.length;
  const pendingPOs = purchaseOrders.filter((po) => ['sent', 'confirmed', 'partial'].includes(po.status));
  const pendingValue = pendingPOs.reduce((sum, po) => sum + po.totalAmount, 0);
  const receivedValue = purchaseOrders
    .filter((po) => po.status === 'received')
    .reduce((sum, po) => sum + po.totalAmount, 0);
  const openOrders = purchaseOrders.filter((po) => !['received', 'cancelled'].includes(po.status)).length;

  const loading = poLoading || procLoading;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('purchaseOrders.title')}</h1>
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
                <p className="text-2xl font-semibold text-main">{totalPOs}</p>
                <p className="text-sm text-muted">Total POs</p>
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
                <p className="text-2xl font-semibold text-main">{pendingPOs.length}</p>
                <p className="text-sm text-muted">{t('common.pending')}</p>
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
                <p className="text-2xl font-semibold text-main">{formatCurrency(receivedValue)}</p>
                <p className="text-sm text-muted">Received Value</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <ClipboardList size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{openOrders}</p>
                <p className="text-sm text-muted">Open Orders</p>
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
          {poError ? (
            <div className="py-12 text-center">
              <p className="text-red-500 mb-2">{poError}</p>
              <Button variant="secondary" size="sm" onClick={fetchPurchaseOrders}>{t('common.retry')}</Button>
            </div>
          ) : filteredPOs.length === 0 ? (
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
                  lineItems={getLineItemsForPO(po.id)}
                  receivingRecords={getReceivingForPO(po.id)}
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

function PORow({
  po,
  lineItems,
  receivingRecords,
  isExpanded,
  onToggle,
}: {
  po: PurchaseOrderData;
  lineItems: POLineItem[];
  receivingRecords: ReceivingRecord[];
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const { t } = useTranslation();
  const config = statusConfig[po.status] || statusConfig.draft;
  const isOverdue =
    po.expectedDeliveryDate &&
    new Date(po.expectedDeliveryDate) < new Date() &&
    !['received', 'cancelled'].includes(po.status);

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
              <StatusBadge status={po.status} />
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
              {po.jobTitle && (
                <span className="flex items-center gap-1">
                  <Package size={14} />
                  {po.jobTitle}
                </span>
              )}
              {lineItems.length > 0 && (
                <span className="text-xs">
                  {lineItems.length} item{lineItems.length !== 1 ? 's' : ''}
                </span>
              )}
            </div>
          </div>
          <div className="text-right">
            <p className="font-semibold text-main">{formatCurrency(po.totalAmount)}</p>
            <p className="text-sm text-muted">
              {po.expectedDeliveryDate ? `Expected ${formatDate(po.expectedDeliveryDate)}` : 'No date set'}
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
            {lineItems.length > 0 ? (
              <table className="w-full mb-4">
                <thead>
                  <tr className="text-left text-sm text-muted border-b border-main">
                    <th className="pb-2 font-medium">Item</th>
                    <th className="pb-2 font-medium text-right">{t('common.qty')}</th>
                    <th className="pb-2 font-medium text-right">Received</th>
                    <th className="pb-2 font-medium text-right">Unit Price</th>
                    <th className="pb-2 font-medium text-right">{t('common.total')}</th>
                    <th className="pb-2 font-medium">{t('common.status')}</th>
                  </tr>
                </thead>
                <tbody>
                  {lineItems.map((item) => (
                    <tr key={item.id} className="border-b border-main/50">
                      <td className="py-2 text-main">{item.itemDescription}</td>
                      <td className="py-2 text-right text-main">
                        {item.quantity}{item.unit ? ` ${item.unit}` : ''}
                      </td>
                      <td className="py-2 text-right">
                        <span className={cn(
                          'font-medium',
                          item.receivedQuantity === item.quantity ? 'text-emerald-600' :
                          item.receivedQuantity > 0 ? 'text-amber-600' : 'text-muted'
                        )}>
                          {item.receivedQuantity}
                        </span>
                      </td>
                      <td className="py-2 text-right text-muted">{formatCurrency(item.unitPrice)}</td>
                      <td className="py-2 text-right font-medium text-main">{formatCurrency(item.totalPrice)}</td>
                      <td className="py-2">
                        <Badge
                          variant={
                            item.status === 'received' ? 'success' :
                            item.status === 'partial' ? 'warning' :
                            item.status === 'cancelled' ? 'error' : 'default'
                          }
                          size="sm"
                        >
                          {item.status}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <p className="text-sm text-muted mb-4">No line items recorded</p>
            )}

            {/* Receiving Records */}
            {receivingRecords.length > 0 && (
              <div className="mb-4">
                <p className="text-sm font-medium text-main mb-2">Receiving History</p>
                <div className="space-y-2">
                  {receivingRecords.map((rec) => (
                    <div key={rec.id} className="flex items-center gap-3 text-sm p-2 bg-surface rounded-lg">
                      <Truck size={16} className="text-muted" />
                      <span className="text-main">{formatDate(rec.receivedAt)}</span>
                      {rec.deliveryMethod && (
                        <Badge variant="secondary" size="sm">{rec.deliveryMethod}</Badge>
                      )}
                      {rec.trackingNumber && (
                        <span className="text-xs text-muted">#{rec.trackingNumber}</span>
                      )}
                      <span className="text-xs text-muted">
                        {rec.items.length} item{rec.items.length !== 1 ? 's' : ''} received
                      </span>
                      {rec.allItemsReceived && (
                        <Badge variant="success" size="sm">Complete</Badge>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Actions + Totals */}
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
                  <span className="text-muted">{t('common.subtotal')}</span>
                  <span className="text-main">{formatCurrency(po.subtotal)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted">{t('common.tax')}</span>
                  <span className="text-main">{formatCurrency(po.taxAmount)}</span>
                </div>
                {po.shippingAmount > 0 && (
                  <div className="flex justify-between">
                    <span className="text-muted">Shipping</span>
                    <span className="text-main">{formatCurrency(po.shippingAmount)}</span>
                  </div>
                )}
                <div className="flex justify-between font-semibold pt-1 border-t border-main">
                  <span>{t('common.total')}</span>
                  <span>{formatCurrency(po.totalAmount)}</span>
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
  const { vendors } = useProcurement();
  const [vendorId, setVendorId] = useState('');
  const [jobId, setJobId] = useState('');
  const [jobs, setJobs] = useState<{ id: string; title: string }[]>([]);

  useEffect(() => {
    const fetchJobs = async () => {
      try {
        const supabase = getSupabase();
        const { data } = await supabase
          .from('jobs')
          .select('id, title')
          .is('deleted_at', null)
          .order('title');
        setJobs((data || []) as { id: string; title: string }[]);
      } catch {
        // Ignore fetch error for jobs dropdown
      }
    };
    fetchJobs();
  }, []);

  const vendorOptions = [
    { value: '', label: 'Select Vendor' },
    ...vendors.filter((v) => v.isActive).map((v) => ({ value: v.id, label: v.name })),
  ];

  const jobOptions = [
    { value: '', label: 'No Job (Stock Order)' },
    ...jobs.map((j) => ({ value: j.id, label: j.title })),
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
            options={vendorOptions}
            value={vendorId}
            onChange={(e) => setVendorId(e.target.value)}
          />
          <Select
            label="Link to Job (Optional)"
            options={jobOptions}
            value={jobId}
            onChange={(e) => setJobId(e.target.value)}
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
            <Button className="flex-1" disabled={!vendorId}>
              <Plus size={16} />
              Create PO
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
