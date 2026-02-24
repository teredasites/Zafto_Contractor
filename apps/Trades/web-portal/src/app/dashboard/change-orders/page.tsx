'use client';

import { useState, useEffect, useMemo } from 'react';
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
  FileText,
  TrendingUp,
  AlertTriangle,
  ChevronDown,
  ChevronUp,
  Minus,
  Download,
  History,
  BarChart3,
} from 'lucide-react';
import { getSupabase } from '@/lib/supabase';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, cn } from '@/lib/utils';
import { useChangeOrders } from '@/lib/hooks/use-change-orders';
import type { ChangeOrderData } from '@/lib/hooks/mappers';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

type ChangeOrderStatus = 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'voided';

const statusConfig: Record<ChangeOrderStatus, { label: string; color: string; bgColor: string }> = {
  draft: { label: 'Draft', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
  pending_approval: { label: 'Pending Approval', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  approved: { label: 'Approved', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  rejected: { label: 'Rejected', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  voided: { label: 'Voided', color: 'text-slate-700 dark:text-slate-300', bgColor: 'bg-slate-100 dark:bg-slate-900/30' },
};

// ── Demo data for depth features ──

interface ScopeDiffItem {
  category: string;
  item: string;
  originalQty: number;
  newQty: number;
  originalPrice: number;
  newPrice: number;
  changeType: 'added' | 'removed' | 'modified' | 'unchanged';
}

interface CumulativeJob {
  jobId: string;
  jobName: string;
  customerName: string;
  originalContract: number;
  changeOrders: { coNumber: string; amount: number; status: string; date: string; scheduleDays: number }[];
  currentContract: number;
  totalDaysAdded: number;
  originalEndDate: string;
  adjustedEndDate: string;
}

const demoScopeDiffs: ScopeDiffItem[] = [
  { category: 'Electrical', item: '200A Panel Upgrade', originalQty: 1, newQty: 1, originalPrice: 3200, newPrice: 3200, changeType: 'unchanged' },
  { category: 'Electrical', item: 'EV Charger Circuit (240V/50A)', originalQty: 0, newQty: 1, originalPrice: 0, newPrice: 1850, changeType: 'added' },
  { category: 'Electrical', item: 'Whole-House Surge Protector', originalQty: 0, newQty: 1, originalPrice: 0, newPrice: 450, changeType: 'added' },
  { category: 'Plumbing', item: 'Water Heater Replacement', originalQty: 1, newQty: 1, originalPrice: 2800, newPrice: 2800, changeType: 'unchanged' },
  { category: 'Plumbing', item: 'Tankless Recirculating Pump', originalQty: 1, newQty: 0, originalPrice: 650, newPrice: 0, changeType: 'removed' },
  { category: 'HVAC', item: 'Ductwork Modification', originalQty: 1, newQty: 1, originalPrice: 1400, newPrice: 1750, changeType: 'modified' },
  { category: 'HVAC', item: 'Zone Damper (additional)', originalQty: 0, newQty: 2, originalPrice: 0, newPrice: 380, changeType: 'added' },
  { category: 'Framing', item: 'Load-Bearing Wall Header', originalQty: 1, newQty: 1, originalPrice: 900, newPrice: 900, changeType: 'unchanged' },
  { category: 'Drywall', item: 'Drywall Repair (sq ft)', originalQty: 120, newQty: 180, originalPrice: 4.50, newPrice: 4.50, changeType: 'modified' },
];

const demoCumulativeJobs: CumulativeJob[] = [
  {
    jobId: 'j1', jobName: 'Kitchen Remodel — Thompson', customerName: 'Sarah Thompson',
    originalContract: 45000,
    changeOrders: [
      { coNumber: 'CO-001', amount: 2300, status: 'approved', date: '2026-01-15', scheduleDays: 2 },
      { coNumber: 'CO-002', amount: -650, status: 'approved', date: '2026-01-28', scheduleDays: 0 },
      { coNumber: 'CO-003', amount: 1100, status: 'pending_approval', date: '2026-02-10', scheduleDays: 1 },
    ],
    currentContract: 47750,
    totalDaysAdded: 3,
    originalEndDate: '2026-03-15',
    adjustedEndDate: '2026-03-18',
  },
  {
    jobId: 'j2', jobName: 'Bathroom Addition — Garcia', customerName: 'Miguel Garcia',
    originalContract: 28500,
    changeOrders: [
      { coNumber: 'CO-004', amount: 4200, status: 'approved', date: '2026-02-01', scheduleDays: 5 },
      { coNumber: 'CO-005', amount: 850, status: 'approved', date: '2026-02-12', scheduleDays: 0 },
    ],
    currentContract: 33550,
    totalDaysAdded: 5,
    originalEndDate: '2026-04-01',
    adjustedEndDate: '2026-04-06',
  },
  {
    jobId: 'j3', jobName: 'Roof Replacement — Park', customerName: 'James Park',
    originalContract: 18200,
    changeOrders: [
      { coNumber: 'CO-006', amount: 2100, status: 'approved', date: '2026-02-05', scheduleDays: 1 },
    ],
    currentContract: 20300,
    totalDaysAdded: 1,
    originalEndDate: '2026-02-28',
    adjustedEndDate: '2026-03-01',
  },
  {
    jobId: 'j4', jobName: 'HVAC System — Williams', customerName: 'Denise Williams',
    originalContract: 12800,
    changeOrders: [],
    currentContract: 12800,
    totalDaysAdded: 0,
    originalEndDate: '2026-03-10',
    adjustedEndDate: '2026-03-10',
  },
];

interface COAnalytics {
  totalCOs: number;
  approvalRate: number;
  avgAmount: number;
  avgApprovalDays: number;
  totalAdded: number;
  totalRemoved: number;
  netChange: number;
  avgScheduleImpact: number;
  byReason: { reason: string; count: number; totalAmount: number }[];
  byMonth: { month: string; count: number; amount: number }[];
}

const demoAnalytics: COAnalytics = {
  totalCOs: 24,
  approvalRate: 87.5,
  avgAmount: 1850,
  avgApprovalDays: 2.3,
  totalAdded: 38400,
  totalRemoved: 6200,
  netChange: 32200,
  avgScheduleImpact: 1.8,
  byReason: [
    { reason: 'Customer Request', count: 10, totalAmount: 18500 },
    { reason: 'Discovered During Work', count: 6, totalAmount: 8200 },
    { reason: 'Code Requirement', count: 4, totalAmount: 5100 },
    { reason: 'Design Change', count: 3, totalAmount: 4600 },
    { reason: 'Contractor Recommendation', count: 1, totalAmount: 1800 },
  ],
  byMonth: [
    { month: 'Sep 2025', count: 2, amount: 3400 },
    { month: 'Oct 2025', count: 4, amount: 7200 },
    { month: 'Nov 2025', count: 3, amount: 4100 },
    { month: 'Dec 2025', count: 5, amount: 9800 },
    { month: 'Jan 2026', count: 6, amount: 11200 },
    { month: 'Feb 2026', count: 4, amount: 6500 },
  ],
};

// ── Tabs ──
const tabs = [
  { key: 'orders', label: 'Change Orders', icon: FileDiff },
  { key: 'cumulative', label: 'Cumulative', icon: TrendingUp },
  { key: 'scope-diff', label: 'Scope Diff', icon: FileDiff },
  { key: 'analytics', label: 'Analytics', icon: BarChart3 },
] as const;

type TabKey = typeof tabs[number]['key'];

export default function ChangeOrdersPage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [showNewModal, setShowNewModal] = useState(false);
  const [selectedCO, setSelectedCO] = useState<ChangeOrderData | null>(null);
  const [activeTab, setActiveTab] = useState<TabKey>('orders');
  const { changeOrders, loading, createChangeOrder } = useChangeOrders();

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-40 mb-2" /><div className="skeleton h-4 w-64" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-14" /></div>)}
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
    <div className="space-y-6 animate-fade-in">
      <CommandPalette />
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('changeOrders.title')}</h1>
          <p className="text-muted mt-1">Manage scope changes, customer approvals, and cost adjustments</p>
        </div>
        <Button onClick={() => setShowNewModal(true)}><Plus size={16} />{t('common.newChangeOrder')}</Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg"><Clock size={20} className="text-amber-600 dark:text-amber-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{pendingCount}</p><p className="text-sm text-muted">{t('common.pendingApproval')}</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg"><ArrowUpRight size={20} className="text-emerald-600 dark:text-emerald-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{formatCurrency(approvedTotal)}</p><p className="text-sm text-muted">{t('changeOrders.approvedAdditions')}</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg"><DollarSign size={20} className="text-cyan-600 dark:text-cyan-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{formatCurrency(pendingTotal)}</p><p className="text-sm text-muted">{t('changeOrders.pendingValue')}</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg"><Calendar size={20} className="text-purple-600 dark:text-purple-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{totalCOs}</p><p className="text-sm text-muted">{t('changeOrders.totalCos')}</p></div>
        </div></CardContent></Card>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 border-b border-main">
        {tabs.map(tab => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors',
                activeTab === tab.key
                  ? 'border-accent text-accent'
                  : 'border-transparent text-muted hover:text-main'
              )}
            >
              <Icon size={16} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Tab Content */}
      {activeTab === 'orders' && (
        <OrdersTab
          filteredCOs={filteredCOs}
          search={search}
          setSearch={setSearch}
          statusFilter={statusFilter}
          setStatusFilter={setStatusFilter}
          onSelectCO={setSelectedCO}
          onNewCO={() => setShowNewModal(true)}
          t={t}
        />
      )}
      {activeTab === 'cumulative' && <CumulativeTab />}
      {activeTab === 'scope-diff' && <ScopeDiffTab />}
      {activeTab === 'analytics' && <AnalyticsTab />}

      {selectedCO && <CODetailModal co={selectedCO} onClose={() => setSelectedCO(null)} />}
      {showNewModal && <NewCOModal onClose={() => setShowNewModal(false)} onCreate={createChangeOrder} />}
    </div>
  );
}

// ── Orders Tab (original list) ──

function OrdersTab({ filteredCOs, search, setSearch, statusFilter, setStatusFilter, onSelectCO, onNewCO, t }: {
  filteredCOs: ChangeOrderData[];
  search: string;
  setSearch: (v: string) => void;
  statusFilter: string;
  setStatusFilter: (v: string) => void;
  onSelectCO: (co: ChangeOrderData) => void;
  onNewCO: () => void;
  t: (key: string) => string;
}) {
  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search change orders..." className="sm:w-80" />
        <Select options={[{ value: 'all', label: 'All Statuses' }, ...Object.entries(statusConfig).map(([k, v]) => ({ value: k, label: v.label }))]} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="sm:w-48" />
      </div>

      <div className="space-y-3">
        {filteredCOs.map((co) => {
          const sConfig = statusConfig[co.status];
          const isIncrease = co.amount >= 0;
          return (
            <Card key={co.id} className="hover:border-accent/30 transition-colors cursor-pointer" onClick={() => onSelectCO(co)}>
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
            <Button onClick={onNewCO}><Plus size={16} />{t('common.newChangeOrder')}</Button>
          </CardContent></Card>
        )}
      </div>
    </div>
  );
}

// ── Cumulative Tracking Tab ──

function CumulativeTab() {
  const [expandedJob, setExpandedJob] = useState<string | null>(null);

  const totals = useMemo(() => {
    let origTotal = 0, currentTotal = 0, totalDays = 0, totalCOs = 0;
    demoCumulativeJobs.forEach(j => {
      origTotal += j.originalContract;
      currentTotal += j.currentContract;
      totalDays += j.totalDaysAdded;
      totalCOs += j.changeOrders.length;
    });
    return { origTotal, currentTotal, netChange: currentTotal - origTotal, totalDays, totalCOs };
  }, []);

  return (
    <div className="space-y-6">
      {/* Summary stats */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Original Contracts</p>
          <p className="text-xl font-semibold text-main mt-1">{formatCurrency(totals.origTotal)}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Current Value</p>
          <p className="text-xl font-semibold text-emerald-400 mt-1">{formatCurrency(totals.currentTotal)}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Net Change</p>
          <p className={cn('text-xl font-semibold mt-1', totals.netChange >= 0 ? 'text-emerald-400' : 'text-red-400')}>
            {totals.netChange >= 0 ? '+' : ''}{formatCurrency(totals.netChange)}
          </p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Total COs</p>
          <p className="text-xl font-semibold text-main mt-1">{totals.totalCOs}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Schedule Impact</p>
          <p className="text-xl font-semibold text-amber-400 mt-1">+{totals.totalDays} days</p>
        </CardContent></Card>
      </div>

      {/* Per-job cumulative breakdown */}
      <div className="space-y-3">
        {demoCumulativeJobs.map(job => {
          const isExpanded = expandedJob === job.jobId;
          const changePercent = ((job.currentContract - job.originalContract) / job.originalContract * 100);
          return (
            <Card key={job.jobId}>
              <div
                className="p-4 cursor-pointer hover:bg-surface-hover transition-colors"
                onClick={() => setExpandedJob(isExpanded ? null : job.jobId)}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <button className="p-1">
                      {isExpanded ? <ChevronUp size={16} className="text-muted" /> : <ChevronDown size={16} className="text-muted" />}
                    </button>
                    <div>
                      <h3 className="font-medium text-main">{job.jobName}</h3>
                      <p className="text-sm text-muted">{job.customerName}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-6">
                    <div className="text-right">
                      <p className="text-sm text-muted">Original</p>
                      <p className="font-medium text-main">{formatCurrency(job.originalContract)}</p>
                    </div>
                    <div className="text-center">
                      <ArrowUpRight size={14} className="text-muted mx-auto" />
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-muted">Current</p>
                      <p className="font-semibold text-emerald-400">{formatCurrency(job.currentContract)}</p>
                    </div>
                    <div className="text-right w-20">
                      <Badge variant={changePercent > 10 ? 'warning' : changePercent > 0 ? 'info' : 'secondary'} size="sm">
                        {changePercent >= 0 ? '+' : ''}{changePercent.toFixed(1)}%
                      </Badge>
                    </div>
                    <div className="text-right">
                      <p className="text-xs text-muted">{job.changeOrders.length} CO{job.changeOrders.length !== 1 ? 's' : ''}</p>
                    </div>
                  </div>
                </div>
              </div>

              {isExpanded && (
                <div className="border-t border-main px-4 pb-4">
                  {/* CO timeline for this job */}
                  <div className="ml-8 mt-3 space-y-2">
                    {/* Original contract line */}
                    <div className="flex items-center gap-3 text-sm p-2 bg-secondary/30 rounded-lg">
                      <FileText size={14} className="text-muted" />
                      <span className="font-mono text-xs text-muted w-20">Original</span>
                      <span className="text-main flex-1">Original Contract</span>
                      <span className="font-medium text-main">{formatCurrency(job.originalContract)}</span>
                      <span className="text-xs text-muted w-24 text-right">Running: {formatCurrency(job.originalContract)}</span>
                    </div>

                    {/* Each CO */}
                    {job.changeOrders.reduce<{ runningTotal: number; elements: React.ReactNode[] }>((acc, co) => {
                      acc.runningTotal += co.amount;
                      const sConfig = statusConfig[co.status as ChangeOrderStatus] || statusConfig.draft;
                      acc.elements.push(
                        <div key={co.coNumber} className="flex items-center gap-3 text-sm p-2 rounded-lg hover:bg-secondary/20">
                          {co.amount >= 0
                            ? <ArrowUpRight size={14} className="text-emerald-400" />
                            : <ArrowDownRight size={14} className="text-red-400" />
                          }
                          <span className="font-mono text-xs text-muted w-20">{co.coNumber}</span>
                          <span className={cn('px-1.5 py-0.5 rounded text-xs', sConfig.bgColor, sConfig.color)}>{sConfig.label}</span>
                          <span className="text-xs text-muted">{co.date}</span>
                          <span className="flex-1" />
                          <span className={cn('font-medium', co.amount >= 0 ? 'text-emerald-400' : 'text-red-400')}>
                            {co.amount >= 0 ? '+' : ''}{formatCurrency(co.amount)}
                          </span>
                          <span className="text-xs text-muted w-24 text-right">Running: {formatCurrency(job.originalContract + acc.runningTotal)}</span>
                          {co.scheduleDays > 0 && (
                            <span className="text-xs text-amber-400">+{co.scheduleDays}d</span>
                          )}
                        </div>
                      );
                      return acc;
                    }, { runningTotal: 0, elements: [] }).elements}

                    {/* Final line */}
                    <div className="flex items-center gap-3 text-sm p-2 bg-secondary/50 rounded-lg border border-main">
                      <DollarSign size={14} className="text-accent" />
                      <span className="font-mono text-xs text-accent w-20">Current</span>
                      <span className="text-main font-medium flex-1">Current Contract Value</span>
                      <span className="font-bold text-accent">{formatCurrency(job.currentContract)}</span>
                    </div>
                  </div>

                  {/* Schedule impact */}
                  {job.totalDaysAdded > 0 && (
                    <div className="ml-8 mt-3 p-3 bg-amber-500/5 border border-amber-500/20 rounded-lg">
                      <div className="flex items-center gap-2 text-sm">
                        <Calendar size={14} className="text-amber-400" />
                        <span className="text-amber-300 font-medium">Schedule Impact: +{job.totalDaysAdded} days</span>
                      </div>
                      <div className="flex items-center gap-4 mt-1 text-xs text-muted ml-6">
                        <span>Original end: {job.originalEndDate}</span>
                        <span>Adjusted end: <span className="text-amber-300">{job.adjustedEndDate}</span></span>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </Card>
          );
        })}
      </div>
    </div>
  );
}

// ── Scope Diff Tab ──

function ScopeDiffTab() {
  const categories = useMemo(() => {
    const map = new Map<string, ScopeDiffItem[]>();
    demoScopeDiffs.forEach(d => {
      const existing = map.get(d.category) || [];
      existing.push(d);
      map.set(d.category, existing);
    });
    return Array.from(map.entries());
  }, []);

  const originalTotal = demoScopeDiffs.reduce((sum, d) => sum + d.originalQty * d.originalPrice, 0);
  const newTotal = demoScopeDiffs.reduce((sum, d) => sum + d.newQty * d.newPrice, 0);
  const added = demoScopeDiffs.filter(d => d.changeType === 'added').length;
  const removed = demoScopeDiffs.filter(d => d.changeType === 'removed').length;
  const modified = demoScopeDiffs.filter(d => d.changeType === 'modified').length;

  return (
    <div className="space-y-6">
      {/* Diff summary */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Original Scope</p>
          <p className="text-xl font-semibold text-main mt-1">{formatCurrency(originalTotal)}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Revised Scope</p>
          <p className="text-xl font-semibold text-main mt-1">{formatCurrency(newTotal)}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Net Delta</p>
          <p className={cn('text-xl font-semibold mt-1', newTotal - originalTotal >= 0 ? 'text-emerald-400' : 'text-red-400')}>
            {newTotal - originalTotal >= 0 ? '+' : ''}{formatCurrency(newTotal - originalTotal)}
          </p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <div className="flex items-center gap-2">
            <Badge variant="success" size="sm">+{added}</Badge>
            <Badge variant="error" size="sm">-{removed}</Badge>
            <Badge variant="warning" size="sm">{modified} mod</Badge>
          </div>
          <p className="text-xs text-muted mt-2">Line Item Changes</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Total Items</p>
          <p className="text-xl font-semibold text-main mt-1">{demoScopeDiffs.length}</p>
        </CardContent></Card>
      </div>

      {/* Category breakdown with diff table */}
      {categories.map(([category, items]) => (
        <Card key={category}>
          <CardHeader className="pb-2">
            <CardTitle className="text-base">{category}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="border border-main rounded-lg overflow-hidden">
              <table className="w-full">
                <thead>
                  <tr className="bg-secondary text-left text-xs font-medium text-muted">
                    <th className="px-4 py-2">Item</th>
                    <th className="px-4 py-2 text-right">Original Qty</th>
                    <th className="px-4 py-2 text-right">New Qty</th>
                    <th className="px-4 py-2 text-right">Original Price</th>
                    <th className="px-4 py-2 text-right">New Price</th>
                    <th className="px-4 py-2 text-right">Original Total</th>
                    <th className="px-4 py-2 text-right">New Total</th>
                    <th className="px-4 py-2 text-center">Change</th>
                  </tr>
                </thead>
                <tbody>
                  {items.map((item, i) => {
                    const origTotal = item.originalQty * item.originalPrice;
                    const nTotal = item.newQty * item.newPrice;
                    return (
                      <tr key={i} className={cn(
                        'border-t border-main/50 text-sm',
                        item.changeType === 'added' && 'bg-emerald-500/5',
                        item.changeType === 'removed' && 'bg-red-500/5',
                        item.changeType === 'modified' && 'bg-amber-500/5',
                      )}>
                        <td className="px-4 py-2 text-main">{item.item}</td>
                        <td className="px-4 py-2 text-right text-muted">{item.originalQty}</td>
                        <td className={cn('px-4 py-2 text-right font-medium',
                          item.newQty > item.originalQty ? 'text-emerald-400' :
                          item.newQty < item.originalQty ? 'text-red-400' : 'text-main'
                        )}>{item.newQty}</td>
                        <td className="px-4 py-2 text-right text-muted">{formatCurrency(item.originalPrice)}</td>
                        <td className={cn('px-4 py-2 text-right font-medium',
                          item.newPrice > item.originalPrice ? 'text-emerald-400' :
                          item.newPrice < item.originalPrice ? 'text-red-400' : 'text-main'
                        )}>{formatCurrency(item.newPrice)}</td>
                        <td className="px-4 py-2 text-right text-muted">{formatCurrency(origTotal)}</td>
                        <td className="px-4 py-2 text-right font-medium text-main">{formatCurrency(nTotal)}</td>
                        <td className="px-4 py-2 text-center">
                          {item.changeType === 'added' && <Badge variant="success" size="sm">Added</Badge>}
                          {item.changeType === 'removed' && <Badge variant="error" size="sm">Removed</Badge>}
                          {item.changeType === 'modified' && <Badge variant="warning" size="sm">Modified</Badge>}
                          {item.changeType === 'unchanged' && <Minus size={14} className="mx-auto text-muted" />}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}

// ── Analytics Tab ──

function AnalyticsTab() {
  const maxMonthAmount = Math.max(...demoAnalytics.byMonth.map(m => m.amount));
  const maxReasonAmount = Math.max(...demoAnalytics.byReason.map(r => r.totalAmount));

  return (
    <div className="space-y-6">
      {/* Top stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Approval Rate</p>
          <p className="text-2xl font-bold text-emerald-400 mt-1">{demoAnalytics.approvalRate}%</p>
          <p className="text-xs text-muted mt-1">{demoAnalytics.totalCOs} total change orders</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Average CO Amount</p>
          <p className="text-2xl font-bold text-main mt-1">{formatCurrency(demoAnalytics.avgAmount)}</p>
          <p className="text-xs text-muted mt-1">Avg {demoAnalytics.avgApprovalDays} days to approve</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Net Contract Change</p>
          <p className="text-2xl font-bold text-emerald-400 mt-1">+{formatCurrency(demoAnalytics.netChange)}</p>
          <p className="text-xs text-muted mt-1">
            <span className="text-emerald-400">+{formatCurrency(demoAnalytics.totalAdded)}</span>
            {' / '}
            <span className="text-red-400">-{formatCurrency(demoAnalytics.totalRemoved)}</span>
          </p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">Avg Schedule Impact</p>
          <p className="text-2xl font-bold text-amber-400 mt-1">+{demoAnalytics.avgScheduleImpact} days</p>
          <p className="text-xs text-muted mt-1">per change order</p>
        </CardContent></Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* By Reason */}
        <Card>
          <CardHeader><CardTitle className="text-base">By Reason</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            {demoAnalytics.byReason.map((r, i) => (
              <div key={i}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm text-main">{r.reason}</span>
                  <div className="flex items-center gap-3">
                    <span className="text-xs text-muted">{r.count} COs</span>
                    <span className="text-sm font-medium text-main">{formatCurrency(r.totalAmount)}</span>
                  </div>
                </div>
                <div className="h-2 bg-secondary rounded-full overflow-hidden">
                  <div
                    className="h-full bg-accent rounded-full"
                    style={{ width: `${(r.totalAmount / maxReasonAmount) * 100}%` }}
                  />
                </div>
              </div>
            ))}
          </CardContent>
        </Card>

        {/* By Month */}
        <Card>
          <CardHeader><CardTitle className="text-base">Monthly Trend</CardTitle></CardHeader>
          <CardContent>
            <div className="flex items-end gap-2 h-40">
              {demoAnalytics.byMonth.map((m, i) => (
                <div key={i} className="flex-1 flex flex-col items-center gap-1">
                  <span className="text-xs text-muted">{formatCurrency(m.amount)}</span>
                  <div
                    className="w-full bg-accent/80 rounded-t"
                    style={{ height: `${(m.amount / maxMonthAmount) * 120}px` }}
                  />
                  <span className="text-xs text-muted">{m.count}</span>
                  <span className="text-[10px] text-muted">{m.month.split(' ')[0]}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Recommendations */}
      <Card>
        <CardHeader><CardTitle className="text-base">Insights</CardTitle></CardHeader>
        <CardContent className="space-y-3">
          <div className="flex items-start gap-3 p-3 bg-secondary/30 rounded-lg">
            <AlertTriangle size={16} className="text-amber-400 mt-0.5 shrink-0" />
            <div>
              <p className="text-sm font-medium text-main">High change order rate on kitchen jobs</p>
              <p className="text-xs text-muted mt-1">Kitchen remodels average 2.8 change orders per job vs 1.2 for other jobs. Consider more thorough initial scoping for kitchens.</p>
            </div>
          </div>
          <div className="flex items-start gap-3 p-3 bg-secondary/30 rounded-lg">
            <TrendingUp size={16} className="text-emerald-400 mt-0.5 shrink-0" />
            <div>
              <p className="text-sm font-medium text-main">Change orders increase revenue by 6.1%</p>
              <p className="text-xs text-muted mt-1">Net positive change orders added {formatCurrency(demoAnalytics.netChange)} to contract values this period. {demoAnalytics.approvalRate}% approval rate indicates strong customer trust.</p>
            </div>
          </div>
          <div className="flex items-start gap-3 p-3 bg-secondary/30 rounded-lg">
            <Clock size={16} className="text-blue-400 mt-0.5 shrink-0" />
            <div>
              <p className="text-sm font-medium text-main">Average approval time: {demoAnalytics.avgApprovalDays} days</p>
              <p className="text-xs text-muted mt-1">Down from 3.1 days last quarter. Faster approvals reduce crew idle time and improve schedule predictability.</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ── Detail Modal ──

function CODetailModal({ co, onClose }: { co: ChangeOrderData; onClose: () => void }) {
  const { t } = useTranslation();
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
            <div><p className="text-xs text-muted uppercase tracking-wider">{t('common.job')}</p><p className="font-medium text-main">{co.jobName}</p></div>
            <div><p className="text-xs text-muted uppercase tracking-wider">{t('common.customer')}</p><p className="font-medium text-main">{co.customerName}</p></div>
            <div><p className="text-xs text-muted uppercase tracking-wider">{t('common.reason')}</p><p className="font-medium text-main">{co.reason}</p></div>
            <div><p className="text-xs text-muted uppercase tracking-wider">{t('common.created')}</p><p className="font-medium text-main">{formatDate(co.createdAt)}</p></div>
          </div>

          <div>
            <p className="text-xs text-muted uppercase tracking-wider mb-3">{t('estimates.lineItems')}</p>
            <div className="border border-main rounded-lg overflow-hidden">
              <table className="w-full">
                <thead><tr className="bg-secondary">
                  <th className="text-left text-xs font-medium text-muted px-4 py-2">{t('common.description')}</th>
                  <th className="text-right text-xs font-medium text-muted px-4 py-2">{t('common.qty')}</th>
                  <th className="text-right text-xs font-medium text-muted px-4 py-2">{t('common.unitPrice')}</th>
                  <th className="text-right text-xs font-medium text-muted px-4 py-2">{t('common.total')}</th>
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
              <span className="font-medium text-main">{t('changeOrders.changeOrderAmount')}</span>
              <span className={cn('text-lg font-semibold', isIncrease ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400')}>{isIncrease ? '+' : ''}{formatCurrency(co.amount)}</span>
            </div>
          </div>

          {co.approvedByName && (
            <div className="flex items-center gap-2 p-3 bg-emerald-50 dark:bg-emerald-900/10 rounded-lg">
              <CheckCircle size={16} className="text-emerald-600" />
              <span className="text-sm text-emerald-700 dark:text-emerald-300">Approved by {co.approvedByName} on {co.approvedAt ? formatDate(co.approvedAt) : 'N/A'}</span>
            </div>
          )}

          {co.notes && <div><p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.notes')}</p><p className="text-sm text-main">{co.notes}</p></div>}

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.close')}</Button>
            <Button variant="outline" className="gap-2"><Download size={14} />Export PDF</Button>
            {co.status === 'draft' && <Button className="flex-1"><Send size={16} />{t('changeOrders.sendForApproval')}</Button>}
            {co.status === 'pending_approval' && <Button className="flex-1"><CheckCircle size={16} />{t('changeOrders.markApproved')}</Button>}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ── New CO Modal ──

interface COLineItem {
  description: string;
  quantity: string;
  unitPrice: string;
}

function NewCOModal({ onClose, onCreate }: {
  onClose: () => void;
  onCreate: (input: { jobId: string; title: string; description: string; reason?: string; items?: { description: string; quantity: number; unitPrice: number; total: number }[]; amount: number; notes?: string }) => Promise<string>;
}) {
  const { t } = useTranslation();
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
        <CardHeader><CardTitle>{t('changeOrders.newChangeOrder')}</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Job *</label>
            <select value={jobId} onChange={(e) => setJobId(e.target.value)} className={inputCls}>
              <option value="">{t('common.selectJob')}</option>
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
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.reason')}</label>
              <select value={reason} onChange={(e) => setReason(e.target.value)} className={inputCls}>
                <option value="customer_request">{t('changeOrders.customerRequest')}</option>
                <option value="discovered_during_work">{t('changeOrders.discoveredDuringWork')}</option>
                <option value="code_requirement">{t('changeOrders.codeRequirement')}</option>
                <option value="design_change">{t('changeOrders.designChange')}</option>
                <option value="contractor_recommendation">{t('changeOrders.contractorRecommendation')}</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Schedule Impact (days)</label>
              <input type="number" value={scheduleImpact} onChange={(e) => setScheduleImpact(e.target.value)} placeholder="0" className={inputCls} />
            </div>
          </div>

          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="block text-sm font-medium text-main">{t('estimates.lineItems')}</label>
              <button type="button" onClick={addLineItem} className="text-xs text-accent hover:underline flex items-center gap-1">
                <Plus size={12} /> Add Item
              </button>
            </div>
            <div className="space-y-2">
              {lineItems.map((item, idx) => (
                <div key={idx} className="grid grid-cols-12 gap-2 items-start">
                  <input type="text" value={item.description} onChange={(e) => updateLineItem(idx, 'description', e.target.value)} placeholder={t('common.description')} className={`col-span-6 ${inputCls}`} />
                  <input type="number" value={item.quantity} onChange={(e) => updateLineItem(idx, 'quantity', e.target.value)} placeholder={t('common.qty')} min="0" step="0.01" className={`col-span-2 ${inputCls}`} />
                  <input type="number" value={item.unitPrice} onChange={(e) => updateLineItem(idx, 'unitPrice', e.target.value)} placeholder={t('common.price')} min="0" step="0.01" className={`col-span-3 ${inputCls}`} />
                  <button type="button" onClick={() => removeLineItem(idx)} disabled={lineItems.length <= 1} className="col-span-1 flex items-center justify-center h-[42px] text-muted hover:text-red-500 disabled:opacity-30">
                    <Trash2 size={14} />
                  </button>
                </div>
              ))}
            </div>
            <div className="flex justify-end mt-2">
              <span className="text-sm font-semibold text-main">Total: {formatCurrency(computedTotal)}</span>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.notes')}</label>
            <textarea rows={2} value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Internal notes..." className={`${inputCls} resize-none`} />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>{t('common.cancel')}</Button>
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
