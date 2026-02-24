'use client';

import { useState, useMemo, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import {
  Home,
  Plus,
  Clock,
  DollarSign,
  AlertTriangle,
  CheckCircle,
  ClipboardList,
  MapPin,
  Calendar,
  ArrowRight,
  Filter,
  Search,
  ChevronDown,
  ChevronRight,
  Loader2,
  Building2,
  Truck,
  Camera,
  Snowflake,
  Trash2,
  Wrench,
  Zap,
  Eye,
  Shield,
  FileText,
  BarChart3,
  TrendingUp,
  X,
  Ban,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import {
  usePpWorkOrders,
  usePpChargebacks,
  usePpVendorApps,
  usePpReferenceData,
  usePpBoilerModels,
  usePpPricing,
  type PpWorkOrder,
  type PpWorkOrderStatus,
  type PpChargeback,
  type PpNationalCompany,
  type PpWorkOrderType,
  type PpVendorApplication,
  type BoilerFurnaceModel,
  type PpPricingMatrix,
  type EquipmentType,
} from '@/lib/hooks/use-property-preservation';

// ── Types ──

type TabKey = 'board' | 'deadlines' | 'daily' | 'revenue' | 'nationals' | 'tools';

const TABS: { key: TabKey; label: string; icon: React.ComponentType<{ size?: number; className?: string }> }[] = [
  { key: 'board', label: 'Work Orders', icon: ClipboardList },
  { key: 'deadlines', label: 'Deadlines', icon: Clock },
  { key: 'daily', label: 'Daily Summary', icon: Calendar },
  { key: 'revenue', label: 'Revenue', icon: DollarSign },
  { key: 'nationals', label: 'Nationals', icon: Building2 },
  { key: 'tools', label: 'PP Tools', icon: Wrench },
];

const KANBAN_COLUMNS: { key: PpWorkOrderStatus; label: string; color: string; bg: string }[] = [
  { key: 'assigned', label: 'Assigned', color: 'text-blue-400', bg: 'bg-blue-500/10' },
  { key: 'in_progress', label: 'In Progress', color: 'text-yellow-400', bg: 'bg-yellow-500/10' },
  { key: 'completed', label: 'Completed', color: 'text-emerald-400', bg: 'bg-emerald-500/10' },
  { key: 'submitted', label: 'Submitted', color: 'text-purple-400', bg: 'bg-purple-500/10' },
  { key: 'approved', label: 'Approved', color: 'text-green-400', bg: 'bg-green-500/10' },
  { key: 'rejected', label: 'Rejected', color: 'text-red-400', bg: 'bg-red-500/10' },
  { key: 'disputed', label: 'Disputed', color: 'text-orange-400', bg: 'bg-orange-500/10' },
];

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

const CATEGORY_ICONS: Record<string, LucideIcon> = {
  securing: Shield,
  winterization: Snowflake,
  debris: Trash2,
  lawn_snow: Home,
  inspection: Eye,
  repair: Wrench,
  utility: Zap,
  specialty: FileText,
};

const CATEGORY_LABELS: Record<string, string> = {
  securing: 'Securing',
  winterization: 'Winterization',
  debris: 'Debris Removal',
  lawn_snow: 'Lawn/Snow',
  inspection: 'Inspection',
  repair: 'Repair',
  utility: 'Utility',
  specialty: 'Specialty',
};

// ── Helpers ──

function getDeadlineInfo(dueDate: string | null, submissionDeadlineHours?: number): { hoursLeft: number; label: string; urgent: boolean; overdue: boolean } {
  if (!dueDate) return { hoursLeft: Infinity, label: 'No deadline', urgent: false, overdue: false };
  const due = new Date(dueDate);
  const now = new Date();
  const diffMs = due.getTime() - now.getTime();
  const hoursLeft = diffMs / (1000 * 60 * 60);
  const overdue = hoursLeft < 0;
  const urgent = hoursLeft > 0 && hoursLeft < 4;
  let label: string;
  if (overdue) {
    const hrsOver = Math.abs(Math.floor(hoursLeft));
    label = hrsOver >= 24 ? `${Math.floor(hrsOver / 24)}d overdue` : `${hrsOver}h overdue`;
  } else if (hoursLeft < 1) {
    label = `${Math.floor(hoursLeft * 60)}m left`;
  } else if (hoursLeft < 24) {
    label = `${Math.floor(hoursLeft)}h left`;
  } else {
    label = `${Math.floor(hoursLeft / 24)}d left`;
  }
  return { hoursLeft, label, urgent, overdue };
}

// ── Work Order Creation Modal ──

interface CreateWoModalProps {
  onClose: () => void;
  onSubmit: (data: Record<string, unknown>) => Promise<void>;
  nationals: Array<{ id: string; name: string }>;
  woTypes: Array<{ id: string; name: string; category: string; code: string }>;
}

function CreateWorkOrderModal({ onClose, onSubmit, nationals, woTypes }: CreateWoModalProps) {
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    externalOrderId: '',
    nationalCompanyId: '',
    workOrderTypeId: '',
    dueDate: '',
    notes: '',
    photoMode: 'standard' as string,
  });

  const handleSave = async () => {
    if (!form.nationalCompanyId || !form.workOrderTypeId) return;
    setSaving(true);
    try {
      await onSubmit({
        externalOrderId: form.externalOrderId || null,
        nationalCompanyId: form.nationalCompanyId,
        workOrderTypeId: form.workOrderTypeId,
        dueDate: form.dueDate || null,
        notes: form.notes || null,
        photoMode: form.photoMode,
        status: 'assigned',
      });
      onClose();
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="bg-surface rounded-xl border border-main shadow-2xl w-full max-w-lg" onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between px-6 py-4 border-b border-main">
          <h2 className="text-lg font-semibold text-main">New Work Order</h2>
          <button onClick={onClose} className="text-muted hover:text-main"><X size={18} /></button>
        </div>
        <div className="p-6 space-y-4">
          <div>
            <label className="block text-xs font-medium text-muted mb-1">National Company *</label>
            <select
              className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
              value={form.nationalCompanyId}
              onChange={e => setForm(f => ({ ...f, nationalCompanyId: e.target.value }))}
            >
              <option value="">Select national...</option>
              {nationals.map(n => (
                <option key={n.id} value={n.id}>{n.name}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium text-muted mb-1">Work Order Type *</label>
            <select
              className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
              value={form.workOrderTypeId}
              onChange={e => setForm(f => ({ ...f, workOrderTypeId: e.target.value }))}
            >
              <option value="">Select type...</option>
              {woTypes.map(t => (
                <option key={t.id} value={t.id}>{t.name} ({CATEGORY_LABELS[t.category] || t.category})</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium text-muted mb-1">External Order ID</label>
            <input
              className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
              placeholder="National's order number..."
              value={form.externalOrderId}
              onChange={e => setForm(f => ({ ...f, externalOrderId: e.target.value }))}
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-muted mb-1">Due Date</label>
            <input
              type="datetime-local"
              className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
              value={form.dueDate}
              onChange={e => setForm(f => ({ ...f, dueDate: e.target.value }))}
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-muted mb-1">Photo Mode</label>
            <select
              className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
              value={form.photoMode}
              onChange={e => setForm(f => ({ ...f, photoMode: e.target.value }))}
            >
              <option value="quick">Quick (2-3 photos)</option>
              <option value="standard">Standard (5-8 photos)</option>
              <option value="full_protection">Full Protection (10+ photos)</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium text-muted mb-1">Notes</label>
            <textarea
              className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm h-20 resize-none"
              placeholder="Work order notes..."
              value={form.notes}
              onChange={e => setForm(f => ({ ...f, notes: e.target.value }))}
            />
          </div>
        </div>
        <div className="flex justify-end gap-3 px-6 py-4 border-t border-main">
          <Button variant="secondary" onClick={onClose}>Cancel</Button>
          <Button onClick={handleSave} disabled={saving || !form.nationalCompanyId || !form.workOrderTypeId}>
            {saving ? <><Loader2 size={14} className="animate-spin" /> Creating...</> : 'Create Work Order'}
          </Button>
        </div>
      </div>
    </div>
  );
}

// ── Main Page ──

export default function PropertyPreservationPage() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState<TabKey>('board');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');

  const { workOrders, loading: woLoading, createWorkOrder, updateWorkOrderStatus } = usePpWorkOrders();
  const { chargebacks, loading: cbLoading } = usePpChargebacks();
  const { applications: vendorApps, loading: vaLoading } = usePpVendorApps();
  const { nationals, woTypes: workOrderTypes } = usePpReferenceData();

  const loading = woLoading;

  // National lookup
  const nationalMap = useMemo(() => {
    const m: Record<string, string> = {};
    for (const n of nationals) m[n.id] = n.name;
    return m;
  }, [nationals]);

  // WO type lookup
  const woTypeMap = useMemo(() => {
    const m: Record<string, { name: string; category: string }> = {};
    for (const t of workOrderTypes) m[t.id] = { name: t.name, category: t.category };
    return m;
  }, [workOrderTypes]);

  // Filter work orders
  const filteredOrders = useMemo(() => {
    let list = workOrders;
    if (statusFilter) list = list.filter(wo => wo.status === statusFilter);
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      list = list.filter(wo =>
        wo.externalOrderId?.toLowerCase().includes(q) ||
        wo.notes?.toLowerCase().includes(q) ||
        (wo.nationalCompanyId ? nationalMap[wo.nationalCompanyId]?.toLowerCase().includes(q) : false)
      );
    }
    return list;
  }, [workOrders, statusFilter, searchQuery, nationalMap]);

  // Stats
  const stats = useMemo(() => {
    const total = workOrders.length;
    const assigned = workOrders.filter(w => w.status === 'assigned').length;
    const inProgress = workOrders.filter(w => w.status === 'in_progress').length;
    const completed = workOrders.filter(w => w.status === 'completed').length;
    const submitted = workOrders.filter(w => w.status === 'submitted').length;
    const approved = workOrders.filter(w => w.status === 'approved').length;
    const rejected = workOrders.filter(w => w.status === 'rejected').length;

    // Revenue
    const approvedRevenue = workOrders
      .filter(w => w.status === 'approved')
      .reduce((s, w) => s + (w.approvedAmount || 0), 0);
    const pendingRevenue = workOrders
      .filter(w => ['completed', 'submitted'].includes(w.status))
      .reduce((s, w) => s + (w.bidAmount || 0), 0);
    const chargebackTotal = chargebacks.reduce((s, c) => s + (c.amount || 0), 0);

    // Deadlines
    const urgentDeadlines = workOrders
      .filter(w => ['assigned', 'in_progress'].includes(w.status) && w.dueDate)
      .filter(w => {
        const { hoursLeft } = getDeadlineInfo(w.dueDate);
        return hoursLeft < 4 && hoursLeft > 0;
      }).length;
    const overdueCount = workOrders
      .filter(w => ['assigned', 'in_progress'].includes(w.status) && w.dueDate)
      .filter(w => getDeadlineInfo(w.dueDate).overdue).length;

    return { total, assigned, inProgress, completed, submitted, approved, rejected, approvedRevenue, pendingRevenue, chargebackTotal, urgentDeadlines, overdueCount };
  }, [workOrders, chargebacks]);

  const handleCreateWo = useCallback(async (data: Record<string, unknown>) => {
    await createWorkOrder(data as unknown as Omit<PpWorkOrder, 'id' | 'updatedAt' | 'createdAt'>);
  }, [createWorkOrder]);

  const handleStatusChange = useCallback(async (woId: string, updatedAt: string, newStatus: PpWorkOrderStatus) => {
    await updateWorkOrderStatus(woId, updatedAt, newStatus);
  }, [updateWorkOrderStatus]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-accent" />
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-main flex items-center gap-3">
            <Home size={24} />
            Property Preservation
          </h1>
          <p className="text-sm text-muted mt-1">
            Work orders, deadlines, and revenue tracking for PP nationals
          </p>
        </div>
        <Button onClick={() => setShowCreateModal(true)}>
          <Plus size={16} />
          New Work Order
        </Button>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-6 gap-3">
        <Card className="p-3">
          <div className="flex items-center gap-2">
            <ClipboardList size={14} className="text-blue-400" />
            <span className="text-xs text-muted">Assigned</span>
          </div>
          <p className="text-lg font-bold text-main mt-1">{stats.assigned}</p>
        </Card>
        <Card className="p-3">
          <div className="flex items-center gap-2">
            <Truck size={14} className="text-yellow-400" />
            <span className="text-xs text-muted">In Progress</span>
          </div>
          <p className="text-lg font-bold text-main mt-1">{stats.inProgress}</p>
        </Card>
        <Card className="p-3">
          <div className="flex items-center gap-2">
            <CheckCircle size={14} className="text-emerald-400" />
            <span className="text-xs text-muted">Approved</span>
          </div>
          <p className="text-lg font-bold text-main mt-1">{stats.approved}</p>
        </Card>
        <Card className="p-3">
          <div className="flex items-center gap-2">
            <DollarSign size={14} className="text-green-400" />
            <span className="text-xs text-muted">Revenue</span>
          </div>
          <p className="text-lg font-bold text-main mt-1">{formatCurrency(stats.approvedRevenue)}</p>
        </Card>
        <Card className="p-3">
          <div className="flex items-center gap-2">
            <AlertTriangle size={14} className="text-red-400" />
            <span className="text-xs text-muted">Overdue</span>
          </div>
          <p className={cn('text-lg font-bold mt-1', stats.overdueCount > 0 ? 'text-red-400' : 'text-main')}>{stats.overdueCount}</p>
        </Card>
        <Card className="p-3">
          <div className="flex items-center gap-2">
            <Clock size={14} className="text-orange-400" />
            <span className="text-xs text-muted">Urgent ({'<'}4h)</span>
          </div>
          <p className={cn('text-lg font-bold mt-1', stats.urgentDeadlines > 0 ? 'text-orange-400' : 'text-main')}>{stats.urgentDeadlines}</p>
        </Card>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 border-b border-main overflow-x-auto">
        {TABS.map(tab => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 text-sm font-medium whitespace-nowrap border-b-2 transition-colors',
                activeTab === tab.key
                  ? 'border-accent text-accent'
                  : 'border-transparent text-muted hover:text-main'
              )}
            >
              <Icon size={14} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Tab Content */}
      {activeTab === 'board' && (
        <BoardTab
          workOrders={filteredOrders}
          nationalMap={nationalMap}
          woTypeMap={woTypeMap}
          onStatusChange={handleStatusChange}
          onViewDetail={(id) => router.push(`/dashboard/property-preservation/${id}`)}
          statusFilter={statusFilter}
          setStatusFilter={setStatusFilter}
          searchQuery={searchQuery}
          setSearchQuery={setSearchQuery}
        />
      )}
      {activeTab === 'deadlines' && (
        <DeadlinesTab
          workOrders={workOrders}
          nationalMap={nationalMap}
          woTypeMap={woTypeMap}
          onViewDetail={(id) => router.push(`/dashboard/property-preservation/${id}`)}
        />
      )}
      {activeTab === 'daily' && (
        <DailySummaryTab
          workOrders={workOrders}
          nationalMap={nationalMap}
          woTypeMap={woTypeMap}
          onViewDetail={(id) => router.push(`/dashboard/property-preservation/${id}`)}
        />
      )}
      {activeTab === 'revenue' && (
        <RevenueTab
          workOrders={workOrders}
          chargebacks={chargebacks}
          nationalMap={nationalMap}
        />
      )}
      {activeTab === 'nationals' && (
        <NationalsTab
          nationals={nationals}
          vendorApps={vendorApps}
          workOrders={workOrders}
          chargebacks={chargebacks}
        />
      )}
      {activeTab === 'tools' && (
        <ToolsTab />
      )}

      {/* Create Modal */}
      {showCreateModal && (
        <CreateWorkOrderModal
          onClose={() => setShowCreateModal(false)}
          onSubmit={handleCreateWo}
          nationals={nationals}
          woTypes={workOrderTypes}
        />
      )}
    </div>
  );
}

// ── Board Tab (Kanban) ──

interface BoardTabProps {
  workOrders: PpWorkOrder[];
  nationalMap: Record<string, string>;
  woTypeMap: Record<string, { name: string; category: string }>;
  onStatusChange: (id: string, updatedAt: string, newStatus: PpWorkOrderStatus) => Promise<void>;
  onViewDetail: (id: string) => void;
  statusFilter: string;
  setStatusFilter: (s: string) => void;
  searchQuery: string;
  setSearchQuery: (s: string) => void;
}

function BoardTab({ workOrders, nationalMap, woTypeMap, onStatusChange, onViewDetail, statusFilter, setStatusFilter, searchQuery, setSearchQuery }: BoardTabProps) {
  const grouped = useMemo(() => {
    const g: Record<string, PpWorkOrder[]> = {};
    for (const col of KANBAN_COLUMNS) g[col.key] = [];
    for (const wo of workOrders) {
      const s = wo.status || 'assigned';
      if (g[s]) g[s].push(wo);
      else if (g.assigned) g.assigned.push(wo);
    }
    return g;
  }, [workOrders]);

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex items-center gap-3">
        <div className="relative flex-1 max-w-xs">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
          <input
            className="w-full pl-9 pr-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
            placeholder="Search orders..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
          />
        </div>
        <select
          className="px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
          value={statusFilter}
          onChange={e => setStatusFilter(e.target.value)}
        >
          <option value="">All Statuses</option>
          {KANBAN_COLUMNS.map(c => (
            <option key={c.key} value={c.key}>{c.label}</option>
          ))}
        </select>
      </div>

      {/* Kanban Board */}
      <div className="overflow-x-auto">
        <div className="flex gap-4 min-w-[1200px] pb-4">
          {KANBAN_COLUMNS.map(col => {
            const items = grouped[col.key] || [];
            if (statusFilter && col.key !== statusFilter) return null;
            return (
              <div key={col.key} className="flex-1 min-w-[200px]">
                <div className={cn('px-3 py-2 rounded-t-lg flex items-center justify-between', col.bg)}>
                  <span className={cn('text-sm font-semibold', col.color)}>{col.label}</span>
                  <Badge variant="default" className="text-xs">{items.length}</Badge>
                </div>
                <div className="bg-secondary/30 rounded-b-lg p-2 space-y-2 min-h-[200px]">
                  {items.length === 0 ? (
                    <p className="text-xs text-muted text-center py-8">No orders</p>
                  ) : (
                    items.map(wo => {
                      const woType = woTypeMap[wo.workOrderTypeId || ''];
                      const CatIcon = CATEGORY_ICONS[woType?.category || ''] || FileText;
                      const deadline = getDeadlineInfo(wo.dueDate);
                      return (
                        <div
                          key={wo.id}
                          className="bg-surface border border-main rounded-lg p-3 cursor-pointer hover:border-accent/50 transition-colors"
                          onClick={() => onViewDetail(wo.id)}
                        >
                          <div className="flex items-start justify-between gap-2 mb-2">
                            <div className="flex items-center gap-2 min-w-0">
                              <CatIcon size={14} className="text-muted shrink-0" />
                              <span className="text-sm font-medium text-main truncate">
                                {woType?.name || 'Work Order'}
                              </span>
                            </div>
                          </div>
                          {wo.externalOrderId && (
                            <p className="text-xs text-muted font-mono mb-1">#{wo.externalOrderId}</p>
                          )}
                          <div className="flex items-center gap-2 text-xs text-muted">
                            <Building2 size={10} />
                            <span className="truncate">{nationalMap[wo.nationalCompanyId || ''] || 'Unknown'}</span>
                          </div>
                          {wo.dueDate && (
                            <div className={cn(
                              'flex items-center gap-1 mt-2 text-xs font-medium',
                              deadline.overdue ? 'text-red-400' : deadline.urgent ? 'text-orange-400' : 'text-muted'
                            )}>
                              <Clock size={10} />
                              {deadline.label}
                            </div>
                          )}
                          {wo.bidAmount != null && wo.bidAmount > 0 && (
                            <div className="flex items-center gap-1 mt-1 text-xs text-muted">
                              <DollarSign size={10} />
                              {formatCurrency(wo.bidAmount)}
                            </div>
                          )}
                          {/* Quick status buttons */}
                          <div className="flex gap-1 mt-2">
                            {col.key === 'assigned' && (
                              <button
                                className="text-[10px] px-2 py-0.5 bg-yellow-500/10 text-yellow-400 rounded hover:bg-yellow-500/20"
                                onClick={e => { e.stopPropagation(); onStatusChange(wo.id, wo.updatedAt, 'in_progress'); }}
                              >
                                Start
                              </button>
                            )}
                            {col.key === 'in_progress' && (
                              <button
                                className="text-[10px] px-2 py-0.5 bg-emerald-500/10 text-emerald-400 rounded hover:bg-emerald-500/20"
                                onClick={e => { e.stopPropagation(); onStatusChange(wo.id, wo.updatedAt, 'completed'); }}
                              >
                                Complete
                              </button>
                            )}
                            {col.key === 'completed' && (
                              <button
                                className="text-[10px] px-2 py-0.5 bg-purple-500/10 text-purple-400 rounded hover:bg-purple-500/20"
                                onClick={e => { e.stopPropagation(); onStatusChange(wo.id, wo.updatedAt, 'submitted'); }}
                              >
                                Submit
                              </button>
                            )}
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ── Deadlines Tab ──

interface DeadlinesTabProps {
  workOrders: PpWorkOrder[];
  nationalMap: Record<string, string>;
  woTypeMap: Record<string, { name: string; category: string }>;
  onViewDetail: (id: string) => void;
}

function DeadlinesTab({ workOrders, nationalMap, woTypeMap, onViewDetail }: DeadlinesTabProps) {
  const activeOrders = useMemo(() => {
    return workOrders
      .filter(wo => ['assigned', 'in_progress'].includes(wo.status as string) && wo.dueDate)
      .map(wo => ({
        ...wo,
        deadline: getDeadlineInfo(wo.dueDate as string | null),
      }))
      .sort((a, b) => a.deadline.hoursLeft - b.deadline.hoursLeft);
  }, [workOrders]);

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Clock size={16} className="text-orange-400" />
            Upcoming Deadlines ({activeOrders.length})
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {activeOrders.length === 0 ? (
            <div className="text-center py-8 text-muted text-sm">
              <Clock size={32} className="mx-auto mb-2 opacity-30" />
              <p>No active deadlines</p>
            </div>
          ) : (
            <div className="divide-y divide-main/50">
              {activeOrders.map(wo => {
                const woType = woTypeMap[(wo.workOrderTypeId as string) || ''];
                const CatIcon = CATEGORY_ICONS[woType?.category || ''] || FileText;
                return (
                  <div
                    key={wo.id as string}
                    className="px-5 py-3 flex items-center justify-between hover:bg-surface-hover transition-colors cursor-pointer"
                    onClick={() => onViewDetail(wo.id as string)}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div className={cn(
                        'w-10 h-10 rounded-lg flex items-center justify-center',
                        wo.deadline.overdue ? 'bg-red-500/10' : wo.deadline.urgent ? 'bg-orange-500/10' : 'bg-blue-500/10'
                      )}>
                        <CatIcon size={18} className={
                          wo.deadline.overdue ? 'text-red-400' : wo.deadline.urgent ? 'text-orange-400' : 'text-blue-400'
                        } />
                      </div>
                      <div className="min-w-0">
                        <p className="text-sm font-medium text-main">{woType?.name || 'Work Order'}</p>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-xs text-muted">{nationalMap[(wo.nationalCompanyId as string) || ''] || 'Unknown'}</span>
                          {wo.externalOrderId && (
                            <span className="text-xs text-muted font-mono">#{wo.externalOrderId as string}</span>
                          )}
                        </div>
                      </div>
                    </div>
                    <div className="text-right shrink-0 ml-4">
                      <p className={cn(
                        'text-sm font-bold',
                        wo.deadline.overdue ? 'text-red-400' : wo.deadline.urgent ? 'text-orange-400' : 'text-main'
                      )}>
                        {wo.deadline.label}
                      </p>
                      <p className="text-xs text-muted">
                        Due {formatDate(wo.dueDate as string)}
                      </p>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// ── Daily Summary Tab ──

function DailySummaryTab({ workOrders, nationalMap, woTypeMap, onViewDetail }: DeadlinesTabProps) {
  const today = new Date().toISOString().split('T')[0];

  const todayOrders = useMemo(() => {
    return workOrders.filter(wo => {
      if (wo.dueDate && (wo.dueDate as string).startsWith(today)) return true;
      if (['assigned', 'in_progress'].includes(wo.status as string)) return true;
      return false;
    });
  }, [workOrders, today]);

  const byCategory = useMemo(() => {
    const cats: Record<string, number> = {};
    for (const wo of todayOrders) {
      const woType = woTypeMap[(wo.workOrderTypeId as string) || ''];
      const cat = woType?.category || 'other';
      cats[cat] = (cats[cat] || 0) + 1;
    }
    return cats;
  }, [todayOrders, woTypeMap]);

  return (
    <div className="space-y-4">
      {/* Today's Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="p-4">
          <div className="flex items-center gap-2 text-muted text-xs mb-1">
            <Calendar size={12} />
            Today&apos;s Orders
          </div>
          <p className="text-2xl font-bold text-main">{todayOrders.length}</p>
        </Card>
        <Card className="p-4">
          <div className="flex items-center gap-2 text-muted text-xs mb-1">
            <Truck size={12} />
            In Progress
          </div>
          <p className="text-2xl font-bold text-yellow-400">
            {todayOrders.filter(wo => wo.status === 'in_progress').length}
          </p>
        </Card>
        <Card className="p-4">
          <div className="flex items-center gap-2 text-muted text-xs mb-1">
            <CheckCircle size={12} />
            Completed Today
          </div>
          <p className="text-2xl font-bold text-emerald-400">
            {workOrders.filter(wo => wo.completedAt && (wo.completedAt as string).startsWith(today)).length}
          </p>
        </Card>
      </div>

      {/* Category Breakdown */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Today&apos;s Work by Category</CardTitle>
        </CardHeader>
        <CardContent>
          {Object.keys(byCategory).length === 0 ? (
            <p className="text-sm text-muted text-center py-4">No work orders for today</p>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              {Object.entries(byCategory).map(([cat, count]) => {
                const CatIcon = CATEGORY_ICONS[cat] || FileText;
                return (
                  <div key={cat} className="flex items-center gap-2 p-2 bg-secondary rounded-lg">
                    <CatIcon size={14} className="text-muted" />
                    <span className="text-sm text-main">{CATEGORY_LABELS[cat] || cat}</span>
                    <Badge variant="default" className="ml-auto text-xs">{count}</Badge>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Order List */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Active Work Orders</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {todayOrders.length === 0 ? (
            <div className="text-center py-8 text-muted text-sm">
              <Calendar size={32} className="mx-auto mb-2 opacity-30" />
              <p>No active work orders</p>
            </div>
          ) : (
            <div className="divide-y divide-main/50">
              {todayOrders.map(wo => {
                const woType = woTypeMap[(wo.workOrderTypeId as string) || ''];
                const CatIcon = CATEGORY_ICONS[woType?.category || ''] || FileText;
                const deadline = getDeadlineInfo(wo.dueDate as string | null);
                return (
                  <div
                    key={wo.id as string}
                    className="px-5 py-3 flex items-center justify-between hover:bg-surface-hover transition-colors cursor-pointer"
                    onClick={() => onViewDetail(wo.id as string)}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <CatIcon size={16} className="text-muted shrink-0" />
                      <div className="min-w-0">
                        <p className="text-sm font-medium text-main">{woType?.name || 'Work Order'}</p>
                        <p className="text-xs text-muted">{nationalMap[(wo.nationalCompanyId as string) || ''] || 'Unknown'}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3 shrink-0">
                      <Badge variant={wo.status === 'in_progress' ? 'warning' : wo.status === 'completed' ? 'success' : 'default'} className="text-xs">
                        {(wo.status as string).replace('_', ' ')}
                      </Badge>
                      {wo.dueDate && (
                        <span className={cn(
                          'text-xs font-medium',
                          deadline.overdue ? 'text-red-400' : deadline.urgent ? 'text-orange-400' : 'text-muted'
                        )}>
                          {deadline.label}
                        </span>
                      )}
                      <ChevronRight size={14} className="text-muted" />
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// ── Revenue Tab ──

interface RevenueTabProps {
  workOrders: PpWorkOrder[];
  chargebacks: PpChargeback[];
  nationalMap: Record<string, string>;
}

function RevenueTab({ workOrders, chargebacks, nationalMap }: RevenueTabProps) {
  const revenue = useMemo(() => {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const thisMonth = workOrders.filter(wo => new Date(wo.createdAt as string) >= monthStart);

    const submitted = thisMonth
      .filter(wo => ['submitted', 'approved'].includes(wo.status as string))
      .reduce((s, wo) => s + ((wo.bidAmount as number) || 0), 0);
    const approved = thisMonth
      .filter(wo => wo.status === 'approved')
      .reduce((s, wo) => s + ((wo.approvedAmount as number) || 0), 0);
    const pending = thisMonth
      .filter(wo => ['completed', 'submitted'].includes(wo.status as string))
      .reduce((s, wo) => s + ((wo.bidAmount as number) || 0), 0);
    const chargebackAmt = chargebacks
      .filter(cb => new Date(cb.createdAt as string) >= monthStart)
      .reduce((s, cb) => s + ((cb.amount as number) || 0), 0);

    // Per national
    const byNational: Record<string, { submitted: number; approved: number; chargebacks: number }> = {};
    for (const wo of thisMonth) {
      const nId = wo.nationalCompanyId as string;
      if (!byNational[nId]) byNational[nId] = { submitted: 0, approved: 0, chargebacks: 0 };
      if (['submitted', 'approved'].includes(wo.status as string)) {
        byNational[nId].submitted += (wo.bidAmount as number) || 0;
      }
      if (wo.status === 'approved') {
        byNational[nId].approved += (wo.approvedAmount as number) || 0;
      }
    }
    for (const cb of chargebacks) {
      const nId = cb.nationalCompanyId as string;
      if (!byNational[nId]) byNational[nId] = { submitted: 0, approved: 0, chargebacks: 0 };
      byNational[nId].chargebacks += (cb.amount as number) || 0;
    }

    return { submitted, approved, pending, chargebackAmt, byNational };
  }, [workOrders, chargebacks]);

  return (
    <div className="space-y-4">
      {/* Revenue Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="p-4">
          <div className="text-xs text-muted mb-1 flex items-center gap-1"><TrendingUp size={12} /> Submitted</div>
          <p className="text-2xl font-bold text-main">{formatCurrency(revenue.submitted)}</p>
          <p className="text-xs text-muted mt-1">This month</p>
        </Card>
        <Card className="p-4">
          <div className="text-xs text-muted mb-1 flex items-center gap-1"><CheckCircle size={12} /> Approved</div>
          <p className="text-2xl font-bold text-emerald-400">{formatCurrency(revenue.approved)}</p>
          <p className="text-xs text-muted mt-1">This month</p>
        </Card>
        <Card className="p-4">
          <div className="text-xs text-muted mb-1 flex items-center gap-1"><Clock size={12} /> Pending</div>
          <p className="text-2xl font-bold text-yellow-400">{formatCurrency(revenue.pending)}</p>
          <p className="text-xs text-muted mt-1">Awaiting review</p>
        </Card>
        <Card className="p-4">
          <div className="text-xs text-muted mb-1 flex items-center gap-1"><Ban size={12} /> Chargebacks</div>
          <p className={cn('text-2xl font-bold', revenue.chargebackAmt > 0 ? 'text-red-400' : 'text-main')}>
            {formatCurrency(revenue.chargebackAmt)}
          </p>
          <p className="text-xs text-muted mt-1">This month</p>
        </Card>
      </div>

      {/* Per-National Revenue */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <BarChart3 size={16} />
            Revenue by National
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {Object.keys(revenue.byNational).length === 0 ? (
            <div className="text-center py-8 text-muted text-sm">No revenue data for this month</div>
          ) : (
            <div className="divide-y divide-main/50">
              {Object.entries(revenue.byNational)
                .sort((a, b) => b[1].approved - a[1].approved)
                .map(([nId, data]) => (
                  <div key={nId} className="px-5 py-3 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <Building2 size={14} className="text-muted" />
                      <span className="text-sm font-medium text-main">{nationalMap[nId] || 'Unknown'}</span>
                    </div>
                    <div className="flex items-center gap-4 text-sm">
                      <span className="text-muted">Sub: {formatCurrency(data.submitted)}</span>
                      <span className="text-emerald-400">Appr: {formatCurrency(data.approved)}</span>
                      {data.chargebacks > 0 && (
                        <span className="text-red-400">CB: {formatCurrency(data.chargebacks)}</span>
                      )}
                    </div>
                  </div>
                ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Chargebacks */}
      {chargebacks.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <AlertTriangle size={16} className="text-red-400" />
              Recent Chargebacks ({chargebacks.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y divide-main/50">
              {chargebacks.slice(0, 10).map(cb => (
                <div key={cb.id as string} className="px-5 py-3 flex items-center justify-between">
                  <div className="min-w-0">
                    <p className="text-sm text-main">{cb.propertyAddress as string || 'Unknown address'}</p>
                    <p className="text-xs text-muted">{cb.reason as string || 'No reason given'}</p>
                    <p className="text-xs text-muted mt-0.5">
                      {nationalMap[(cb.nationalCompanyId as string) || ''] || 'Unknown'} — {formatDate(cb.chargebackDate as string)}
                    </p>
                  </div>
                  <div className="text-right shrink-0 ml-4">
                    <p className="text-sm font-bold text-red-400">{formatCurrency((cb.amount as number) || 0)}</p>
                    <Badge variant={
                      cb.disputeStatus === 'resolved_won' ? 'success' :
                      cb.disputeStatus === 'resolved_lost' || cb.disputeStatus === 'denied' ? 'error' :
                      cb.disputeStatus === 'submitted' || cb.disputeStatus === 'under_review' ? 'warning' : 'default'
                    } className="text-xs mt-1">
                      {((cb.disputeStatus as string) || 'none').replace('_', ' ')}
                    </Badge>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// ── Nationals Tab ──

interface NationalsTabProps {
  nationals: PpNationalCompany[];
  vendorApps: PpVendorApplication[];
  workOrders: PpWorkOrder[];
  chargebacks: PpChargeback[];
}

function NationalsTab({ nationals, vendorApps, workOrders, chargebacks }: NationalsTabProps) {
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const appMap = useMemo(() => {
    const m: Record<string, PpVendorApplication> = {};
    for (const app of vendorApps) m[app.nationalCompanyId] = app;
    return m;
  }, [vendorApps]);

  const woCountMap = useMemo(() => {
    const m: Record<string, number> = {};
    for (const wo of workOrders) {
      const nId = wo.nationalCompanyId as string;
      m[nId] = (m[nId] || 0) + 1;
    }
    return m;
  }, [workOrders]);

  const cbCountMap = useMemo(() => {
    const m: Record<string, number> = {};
    for (const cb of chargebacks) {
      const nId = cb.nationalCompanyId as string;
      m[nId] = (m[nId] || 0) + 1;
    }
    return m;
  }, [chargebacks]);

  return (
    <div className="space-y-3">
      {nationals.length === 0 ? (
        <Card>
          <CardContent className="p-8 text-center text-muted text-sm">
            <Building2 size={32} className="mx-auto mb-2 opacity-30" />
            <p>No national companies configured</p>
            <p className="text-xs mt-1">National company data will appear when the reference tables are seeded</p>
          </CardContent>
        </Card>
      ) : (
        nationals.map(nat => {
          const app = appMap[nat.id as string];
          const woCount = woCountMap[nat.id as string] || 0;
          const cbCount = cbCountMap[nat.id as string] || 0;
          const expanded = expandedId === (nat.id as string);

          return (
            <Card key={nat.id as string}>
              <div
                className="px-5 py-4 flex items-center justify-between cursor-pointer hover:bg-surface-hover transition-colors"
                onClick={() => setExpandedId(expanded ? null : (nat.id as string))}
              >
                <div className="flex items-center gap-3">
                  <Building2 size={18} className="text-muted" />
                  <div>
                    <p className="text-sm font-semibold text-main">{nat.name as string}</p>
                    <div className="flex items-center gap-2 mt-0.5">
                      {app ? (
                        <Badge variant={
                          app.status === 'approved' ? 'success' :
                          app.status === 'submitted' ? 'warning' :
                          app.status === 'rejected' ? 'error' : 'default'
                        } className="text-xs">
                          {(app.status as string) || 'Not started'}
                        </Badge>
                      ) : (
                        <Badge variant="default" className="text-xs">Not registered</Badge>
                      )}
                      <span className="text-xs text-muted">{woCount} orders</span>
                      {cbCount > 0 && (
                        <span className="text-xs text-red-400">{cbCount} chargebacks</span>
                      )}
                    </div>
                  </div>
                </div>
                <ChevronDown size={16} className={cn('text-muted transition-transform', expanded && 'rotate-180')} />
              </div>
              {expanded && (
                <div className="px-5 pb-4 pt-0 border-t border-main/50 space-y-3">
                  <div className="grid grid-cols-2 gap-3 text-sm">
                    {nat.phone && (
                      <div>
                        <span className="text-xs text-muted block">Phone</span>
                        <span className="text-main">{nat.phone as string}</span>
                      </div>
                    )}
                    {nat.email && (
                      <div>
                        <span className="text-xs text-muted block">Email</span>
                        <span className="text-main">{nat.email as string}</span>
                      </div>
                    )}
                    {nat.submissionDeadlineHours && (
                      <div>
                        <span className="text-xs text-muted block">Deadline</span>
                        <span className="text-main">{nat.submissionDeadlineHours as number}h after completion</span>
                      </div>
                    )}
                    {nat.paySchedule && (
                      <div>
                        <span className="text-xs text-muted block">Pay Schedule</span>
                        <span className="text-main capitalize">{nat.paySchedule as string}</span>
                      </div>
                    )}
                    {nat.insuranceMinimum && (
                      <div>
                        <span className="text-xs text-muted block">Insurance Min</span>
                        <span className="text-main">{formatCurrency(nat.insuranceMinimum ?? 0)}</span>
                      </div>
                    )}
                  </div>
                  {nat.portalUrl && (
                    <a
                      href={nat.portalUrl as string}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-accent hover:underline flex items-center gap-1"
                    >
                      Open Vendor Portal <ArrowRight size={10} />
                    </a>
                  )}
                </div>
              )}
            </Card>
          );
        })
      )}
    </div>
  );
}

// ── PP Tools Tab ──

const ROOM_TYPES = [
  'Living Room', 'Bedroom', 'Kitchen', 'Bathroom', 'Basement',
  'Garage', 'Dining Room', 'Den/Office', 'Hallway', 'Attic',
  'Laundry Room', 'Utility Room', 'Closet', 'Porch/Patio',
];

const FILL_LEVELS: { key: string; label: string; min: number; max: number }[] = [
  { key: 'broom_clean', label: 'Broom Clean', min: 0.5, max: 1.0 },
  { key: 'normal', label: 'Normal Cleanout', min: 1.5, max: 3.0 },
  { key: 'heavy', label: 'Heavy', min: 3.0, max: 5.0 },
  { key: 'hoarder', label: 'Hoarder', min: 5.0, max: 10.0 },
];

const HOARDING_SCALE = [
  { level: 1, label: 'Light', min: 10, max: 20, desc: 'Some clutter, accessible pathways' },
  { level: 2, label: 'Noticeable', min: 20, max: 40, desc: 'Blocked pathways, difficult navigation' },
  { level: 3, label: 'Significant', min: 40, max: 70, desc: 'PPE required, structural concern' },
  { level: 4, label: 'Severe', min: 70, max: 100, desc: 'Biohazard PPE, heavy equipment needed' },
  { level: 5, label: 'Extreme', min: 100, max: 150, desc: 'Full hazmat, structural assessment required' },
];

const DUMPSTER_RECS = [
  { maxCy: 10, name: 'Trailer', costMin: 100, costMax: 200 },
  { maxCy: 15, name: '10-yd Dumpster', costMin: 220, costMax: 580 },
  { maxCy: 25, name: '20-yd Dumpster', costMin: 280, costMax: 700 },
  { maxCy: 35, name: '30-yd Dumpster', costMin: 311, costMax: 718 },
  { maxCy: Infinity, name: '40-yd Dumpster', costMin: 350, costMax: 780 },
];

const STRIPPED_ITEMS = [
  { item: 'Copper Piping (per LF)', hudRate: 4.50 },
  { item: 'Water Heater', hudRate: 450 },
  { item: 'Furnace', hudRate: 1200 },
  { item: 'AC Condenser', hudRate: 900 },
  { item: 'Kitchen Sink', hudRate: 175 },
  { item: 'Bathroom Sink', hudRate: 125 },
  { item: 'Toilet', hudRate: 150 },
  { item: 'Bathtub', hudRate: 350 },
  { item: 'Electrical Panel', hudRate: 800 },
  { item: 'Light Fixtures (each)', hudRate: 35 },
  { item: 'Kitchen Cabinets (per LF)', hudRate: 85 },
  { item: 'Countertops (per LF)', hudRate: 45 },
  { item: 'Interior Door (each)', hudRate: 95 },
  { item: 'Refrigerator', hudRate: 500 },
  { item: 'Stove/Range', hudRate: 350 },
  { item: 'Dishwasher', hudRate: 300 },
  { item: 'Washer', hudRate: 350 },
  { item: 'Dryer', hudRate: 300 },
];

interface RoomEntry {
  room: string;
  sqft: number;
  level: string;
}

function ToolsTab() {
  const [activeTool, setActiveTool] = useState<'debris' | 'hoarding' | 'stripped' | 'boiler' | 'pricing'>('debris');

  const tools: { key: typeof activeTool; label: string; icon: React.ComponentType<{ size?: number; className?: string }> }[] = [
    { key: 'debris', label: 'Debris Calculator', icon: Trash2 },
    { key: 'hoarding', label: 'Hoarding Scale', icon: AlertTriangle },
    { key: 'stripped', label: 'Stripped Estimator', icon: Home },
    { key: 'boiler', label: 'Boiler/Furnace DB', icon: Snowflake },
    { key: 'pricing', label: 'HUD Pricing', icon: DollarSign },
  ];

  return (
    <div className="space-y-4">
      {/* Tool Selector */}
      <div className="flex gap-2 flex-wrap">
        {tools.map(tool => {
          const Icon = tool.icon;
          return (
            <button
              key={tool.key}
              onClick={() => setActiveTool(tool.key)}
              className={cn(
                'flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                activeTool === tool.key
                  ? 'bg-accent/10 text-accent border border-accent/30'
                  : 'bg-secondary text-muted hover:text-main border border-transparent'
              )}
            >
              <Icon size={14} />
              {tool.label}
            </button>
          );
        })}
      </div>

      {activeTool === 'debris' && <RoomByRoomDebrisCalc />}
      {activeTool === 'hoarding' && <HoardingScaleTool />}
      {activeTool === 'stripped' && <StrippedEstimator />}
      {activeTool === 'boiler' && <BoilerModelSearch />}
      {activeTool === 'pricing' && <HudPricingLookup />}
    </div>
  );
}

// ── Room-by-Room Debris Calculator ──

function RoomByRoomDebrisCalc() {
  const [rooms, setRooms] = useState<RoomEntry[]>([]);
  const [hudRate, setHudRate] = useState(40);
  const [nationalCut, setNationalCut] = useState(30);

  const addRoom = () => {
    setRooms(r => [...r, { room: ROOM_TYPES[0], sqft: 0, level: 'normal' }]);
  };

  const removeRoom = (idx: number) => {
    setRooms(r => r.filter((_, i) => i !== idx));
  };

  const updateRoom = (idx: number, patch: Partial<RoomEntry>) => {
    setRooms(r => r.map((room, i) => i === idx ? { ...room, ...patch } : room));
  };

  const results = useMemo(() => {
    let totalMinCy = 0;
    let totalMaxCy = 0;
    const roomResults = rooms.map(room => {
      const fillLevel = FILL_LEVELS.find(f => f.key === room.level) || FILL_LEVELS[1];
      const minCy = (room.sqft / 100) * fillLevel.min;
      const maxCy = (room.sqft / 100) * fillLevel.max;
      totalMinCy += minCy;
      totalMaxCy += maxCy;
      return { ...room, minCy, maxCy, avgCy: (minCy + maxCy) / 2 };
    });
    const avgCy = (totalMinCy + totalMaxCy) / 2;
    const dumpster = DUMPSTER_RECS.find(d => avgCy <= d.maxCy) || DUMPSTER_RECS[DUMPSTER_RECS.length - 1];
    const grossRevenue = avgCy * hudRate;
    const nationalCutAmt = grossRevenue * (nationalCut / 100);
    const dumpsterCost = (dumpster.costMin + dumpster.costMax) / 2;
    const profit = grossRevenue - nationalCutAmt - dumpsterCost;

    return { roomResults, totalMinCy, totalMaxCy, avgCy, dumpster, grossRevenue, nationalCutAmt, dumpsterCost, profit };
  }, [rooms, hudRate, nationalCut]);

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Room-by-Room Debris Calculator</CardTitle>
            <Button variant="secondary" size="sm" onClick={addRoom}>
              <Plus size={14} /> Add Room
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          {rooms.length === 0 ? (
            <div className="text-center py-6 text-muted text-sm">
              <Trash2 size={32} className="mx-auto mb-2 opacity-30" />
              <p>Add rooms to calculate debris volume</p>
              <Button variant="secondary" size="sm" className="mt-3" onClick={addRoom}>
                <Plus size={14} /> Add First Room
              </Button>
            </div>
          ) : (
            rooms.map((room, idx) => (
              <div key={idx} className="flex items-center gap-3 p-3 bg-secondary rounded-lg">
                <select
                  className="px-2 py-1.5 bg-surface border border-main rounded text-main text-sm min-w-[120px]"
                  value={room.room}
                  onChange={e => updateRoom(idx, { room: e.target.value })}
                >
                  {ROOM_TYPES.map(r => <option key={r} value={r}>{r}</option>)}
                </select>
                <input
                  type="number"
                  className="px-2 py-1.5 bg-surface border border-main rounded text-main text-sm w-20"
                  placeholder="Sq ft"
                  value={room.sqft || ''}
                  onChange={e => updateRoom(idx, { sqft: Number(e.target.value) || 0 })}
                />
                <select
                  className="px-2 py-1.5 bg-surface border border-main rounded text-main text-sm"
                  value={room.level}
                  onChange={e => updateRoom(idx, { level: e.target.value })}
                >
                  {FILL_LEVELS.map(f => <option key={f.key} value={f.key}>{f.label}</option>)}
                </select>
                <span className="text-sm text-muted ml-auto whitespace-nowrap">
                  {results.roomResults[idx]?.avgCy.toFixed(1) || '0'} CY
                </span>
                <button onClick={() => removeRoom(idx)} className="text-muted hover:text-red-400">
                  <X size={14} />
                </button>
              </div>
            ))
          )}
        </CardContent>
      </Card>

      {rooms.length > 0 && (
        <>
          {/* Profit Calculator */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-muted mb-1">HUD Rate ($/CY)</label>
              <input
                type="number"
                className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
                value={hudRate}
                onChange={e => setHudRate(Number(e.target.value) || 0)}
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted mb-1">National&apos;s Cut (%)</label>
              <input
                type="number"
                className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
                value={nationalCut}
                onChange={e => setNationalCut(Number(e.target.value) || 0)}
              />
            </div>
          </div>

          {/* Results */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Calculation Results</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
                <div>
                  <span className="text-xs text-muted block">Total CY Range</span>
                  <span className="text-lg font-bold text-main">{results.totalMinCy.toFixed(1)} - {results.totalMaxCy.toFixed(1)}</span>
                </div>
                <div>
                  <span className="text-xs text-muted block">Average CY</span>
                  <span className="text-lg font-bold text-main">{results.avgCy.toFixed(1)}</span>
                </div>
                <div>
                  <span className="text-xs text-muted block">Dumpster</span>
                  <span className="text-sm font-medium text-main">{results.dumpster.name}</span>
                  <span className="text-xs text-muted block">${results.dumpster.costMin}-${results.dumpster.costMax}</span>
                </div>
              </div>

              {results.avgCy > 12 && (
                <div className="flex items-center gap-2 p-2 bg-orange-500/10 rounded-lg text-orange-400 text-sm">
                  <AlertTriangle size={14} />
                  Exceeds 12 CY — pre-approval required from national
                </div>
              )}

              <div className="border-t border-main/50 pt-3 space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-muted">HUD Allowable ({results.avgCy.toFixed(1)} CY x ${hudRate})</span>
                  <span className="text-main">{formatCurrency(results.grossRevenue)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">National&apos;s Cut ({nationalCut}%)</span>
                  <span className="text-red-400">-{formatCurrency(results.nationalCutAmt)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Dumpster Cost (avg)</span>
                  <span className="text-red-400">-{formatCurrency(results.dumpsterCost)}</span>
                </div>
                <div className="flex justify-between text-sm font-bold border-t border-main/50 pt-2">
                  <span className="text-main">Estimated Profit</span>
                  <span className={results.profit >= 0 ? 'text-emerald-400' : 'text-red-400'}>
                    {formatCurrency(results.profit)}
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}

// ── Hoarding Scale Assessment ──

function HoardingScaleTool() {
  const [propertySqft, setPropertySqft] = useState(1500);
  const [selectedLevel, setSelectedLevel] = useState(1);

  const results = useMemo(() => {
    const scale = HOARDING_SCALE.find(h => h.level === selectedLevel) || HOARDING_SCALE[0];
    const factor = propertySqft / 1000;
    const minCy = scale.min * factor;
    const maxCy = scale.max * factor;
    const avgCy = (minCy + maxCy) / 2;
    const dumpster = DUMPSTER_RECS.find(d => avgCy <= d.maxCy) || DUMPSTER_RECS[DUMPSTER_RECS.length - 1];
    const pulls = Math.ceil(avgCy / (dumpster.maxCy === Infinity ? 40 : dumpster.maxCy));
    return { scale, minCy, maxCy, avgCy, dumpster, pulls };
  }, [propertySqft, selectedLevel]);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Hoarding Scale Assessment</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div>
          <label className="block text-xs font-medium text-muted mb-1">Property Size (sq ft)</label>
          <input
            type="number"
            className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm max-w-xs"
            value={propertySqft}
            onChange={e => setPropertySqft(Number(e.target.value) || 0)}
          />
        </div>

        <div className="space-y-2">
          {HOARDING_SCALE.map(scale => (
            <div
              key={scale.level}
              onClick={() => setSelectedLevel(scale.level)}
              className={cn(
                'p-3 rounded-lg border cursor-pointer transition-colors',
                selectedLevel === scale.level
                  ? 'border-accent bg-accent/5'
                  : 'border-main hover:border-accent/30'
              )}
            >
              <div className="flex items-center justify-between">
                <div>
                  <span className="text-sm font-medium text-main">Level {scale.level}: {scale.label}</span>
                  <p className="text-xs text-muted">{scale.desc}</p>
                </div>
                <span className="text-xs text-muted">{scale.min}-{scale.max} CY/1k sqft</span>
              </div>
            </div>
          ))}
        </div>

        <div className="p-4 bg-secondary rounded-lg space-y-2">
          <div className="flex justify-between text-sm">
            <span className="text-muted">CY Range ({propertySqft} sqft)</span>
            <span className="text-main font-bold">{results.minCy.toFixed(0)} - {results.maxCy.toFixed(0)} CY</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-muted">Recommended</span>
            <span className="text-main">{results.dumpster.name} x {results.pulls}</span>
          </div>
          {selectedLevel >= 3 && (
            <div className="flex items-center gap-2 text-xs text-orange-400 mt-2">
              <AlertTriangle size={12} />
              {selectedLevel >= 4 ? 'Biohazard PPE required' : 'PPE required'}
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

// ── Stripped Property Estimator ──

function StrippedEstimator() {
  const [items, setItems] = useState<Record<string, number>>({});

  const total = useMemo(() => {
    return STRIPPED_ITEMS.reduce((sum, si) => sum + (items[si.item] || 0) * si.hudRate, 0);
  }, [items]);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Stripped Property Estimator</CardTitle>
        <p className="text-xs text-muted mt-1">Estimate replacement costs for stripped items using HUD allowable rates</p>
      </CardHeader>
      <CardContent>
        <div className="space-y-1">
          <div className="grid grid-cols-[1fr,80px,80px,80px] gap-2 px-2 py-1 text-xs font-medium text-muted border-b border-main/50">
            <span>Item</span>
            <span className="text-right">HUD Rate</span>
            <span className="text-center">Qty</span>
            <span className="text-right">Total</span>
          </div>
          {STRIPPED_ITEMS.map(si => (
            <div key={si.item} className="grid grid-cols-[1fr,80px,80px,80px] gap-2 px-2 py-1.5 items-center hover:bg-surface-hover rounded">
              <span className="text-sm text-main">{si.item}</span>
              <span className="text-xs text-muted text-right">{formatCurrency(si.hudRate)}</span>
              <input
                type="number"
                min="0"
                className="w-full px-2 py-1 bg-secondary border border-main rounded text-main text-sm text-center"
                value={items[si.item] || ''}
                onChange={e => setItems(prev => ({ ...prev, [si.item]: Number(e.target.value) || 0 }))}
              />
              <span className="text-sm text-main text-right">
                {(items[si.item] || 0) > 0 ? formatCurrency((items[si.item] || 0) * si.hudRate) : '--'}
              </span>
            </div>
          ))}
        </div>

        <div className="flex justify-between items-center mt-4 pt-3 border-t border-main/50">
          <span className="text-sm font-medium text-main">Total Estimated Replacement</span>
          <span className="text-lg font-bold text-emerald-400">{formatCurrency(total)}</span>
        </div>
      </CardContent>
    </Card>
  );
}

// ── Boiler/Furnace Model Search ──

function BoilerModelSearch() {
  const [searchTerm, setSearchTerm] = useState('');
  const [equipType, setEquipType] = useState<EquipmentType | ''>('');
  const { models, loading } = usePpBoilerModels({
    equipmentType: equipType || undefined,
    search: searchTerm || undefined,
  });

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Boiler/Furnace Model Database</CardTitle>
        <p className="text-xs text-muted mt-1">Search equipment models for winterization procedure guidance</p>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex gap-3">
          <div className="flex-1">
            <input
              className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
              placeholder="Search manufacturer or model..."
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
            />
          </div>
          <select
            className="px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
            value={equipType}
            onChange={e => setEquipType(e.target.value as EquipmentType | '')}
          >
            <option value="">All Types</option>
            <option value="boiler">Boiler</option>
            <option value="furnace">Furnace</option>
            <option value="heat_pump">Heat Pump</option>
            <option value="water_heater">Water Heater</option>
          </select>
        </div>

        {loading ? (
          <div className="text-center py-8">
            <Loader2 className="h-5 w-5 animate-spin mx-auto text-muted" />
          </div>
        ) : models.length === 0 ? (
          <div className="text-center py-8 text-muted text-sm">
            <Snowflake size={32} className="mx-auto mb-2 opacity-30" />
            <p>{searchTerm ? 'No models found' : 'Equipment models will appear when the reference database is seeded'}</p>
          </div>
        ) : (
          <div className="space-y-2">
            {models.slice(0, 20).map(model => (
              <div key={model.id} className="p-3 bg-secondary rounded-lg">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm font-medium text-main">{model.manufacturer} {model.modelName}</span>
                  <Badge variant="default" className="text-xs capitalize">{model.equipmentType.replace('_', ' ')}</Badge>
                </div>
                {model.modelNumber && (
                  <p className="text-xs text-muted font-mono">Model: {model.modelNumber}</p>
                )}
                {model.fuelType && (
                  <p className="text-xs text-muted capitalize">Fuel: {model.fuelType.replace('_', ' ')}</p>
                )}
                {model.winterizationNotes && (
                  <p className="text-xs text-blue-400 mt-1">{model.winterizationNotes}</p>
                )}
                {model.isDiscontinued && (
                  <Badge variant="warning" className="text-xs mt-1">Discontinued</Badge>
                )}
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ── HUD Pricing Lookup ──

function HudPricingLookup() {
  const [stateCode, setStateCode] = useState('');
  const { pricing, loading } = usePpPricing(stateCode || undefined);

  const US_STATES = [
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS',
    'KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY',
    'NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY','DC',
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">HUD Pricing Matrix</CardTitle>
        <p className="text-xs text-muted mt-1">Look up HUD allowable rates by state and work order type</p>
      </CardHeader>
      <CardContent className="space-y-4">
        <div>
          <label className="block text-xs font-medium text-muted mb-1">State</label>
          <select
            className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm max-w-xs"
            value={stateCode}
            onChange={e => setStateCode(e.target.value)}
          >
            <option value="">Select state...</option>
            {US_STATES.map(s => <option key={s} value={s}>{s}</option>)}
          </select>
        </div>

        {loading ? (
          <div className="text-center py-8">
            <Loader2 className="h-5 w-5 animate-spin mx-auto text-muted" />
          </div>
        ) : !stateCode ? (
          <div className="text-center py-8 text-muted text-sm">
            <DollarSign size={32} className="mx-auto mb-2 opacity-30" />
            <p>Select a state to view HUD pricing</p>
          </div>
        ) : pricing.length === 0 ? (
          <div className="text-center py-8 text-muted text-sm">
            <p>No pricing data for {stateCode}</p>
            <p className="text-xs mt-1">Pricing data will appear when the reference tables are seeded</p>
          </div>
        ) : (
          <div className="divide-y divide-main/50">
            {pricing.map(p => (
              <div key={p.id} className="py-2 flex items-center justify-between">
                <div>
                  <p className="text-sm text-main capitalize">{p.workOrderType.replace(/_/g, ' ')}</p>
                  <p className="text-xs text-muted capitalize">{p.pricingSource} — {p.rateUnit.replace(/_/g, ' ')}</p>
                </div>
                <span className="text-sm font-bold text-emerald-400">{formatCurrency(p.rate)}</span>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
