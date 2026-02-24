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
  TrendingUp,
  AlertTriangle,
  ChevronDown,
  ChevronUp,
  Download,
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
import { formatCurrency } from '@/lib/format-locale';

type ChangeOrderStatus = 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'voided';

const statusConfig: Record<ChangeOrderStatus, { tKey: string; color: string; bgColor: string }> = {
  draft: { tKey: 'changeOrders.statusDraft', color: 'text-muted', bgColor: 'bg-secondary' },
  pending_approval: { tKey: 'changeOrders.statusPendingApproval', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  approved: { tKey: 'changeOrders.statusApproved', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  rejected: { tKey: 'changeOrders.statusRejected', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  voided: { tKey: 'changeOrders.statusVoided', color: 'text-muted', bgColor: 'bg-secondary' },
};

const REASON_LABELS: Record<string, string> = {
  customer_request: 'Customer Request',
  discovered_during_work: 'Discovered During Work',
  code_requirement: 'Code Requirement',
  design_change: 'Design Change',
  contractor_recommendation: 'Contractor Recommendation',
};

const tabs = [
  { key: 'orders', tKey: 'changeOrders.tabOrders', icon: FileDiff },
  { key: 'cumulative', tKey: 'changeOrders.tabCumulative', icon: TrendingUp },
  { key: 'scope-diff', tKey: 'changeOrders.tabScopeDiff', icon: FileDiff },
  { key: 'analytics', tKey: 'changeOrders.tabAnalytics', icon: BarChart3 },
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
              {t(tab.tKey)}
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
      {activeTab === 'cumulative' && <CumulativeTab changeOrders={changeOrders} />}
      {activeTab === 'scope-diff' && <ScopeDiffTab changeOrders={changeOrders} />}
      {activeTab === 'analytics' && <AnalyticsTab changeOrders={changeOrders} />}

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
        <SearchInput value={search} onChange={setSearch} placeholder={t('changeOrders.searchPlaceholder')} className="sm:w-80" />
        <Select options={[{ value: 'all', label: t('changeOrders.allStatuses') }, ...Object.entries(statusConfig).map(([k, v]) => ({ value: k, label: t(v.tKey) }))]} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="sm:w-48" />
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
                        <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>{t(sConfig.tKey)}</span>
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
                    <p className="text-sm text-muted">{co.items.length} {co.items.length !== 1 ? t('common.items') : t('common.item')}</p>
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

function CumulativeTab({ changeOrders }: { changeOrders: ChangeOrderData[] }) {
  const { t } = useTranslation();
  const [expandedJob, setExpandedJob] = useState<string | null>(null);

  const cumulativeJobs = useMemo(() => {
    const jobMap = new Map<string, {
      jobId: string;
      jobName: string;
      customerName: string;
      changeOrders: { coNumber: string; amount: number; status: string; date: string }[];
    }>();

    changeOrders.forEach(co => {
      const existing = jobMap.get(co.jobId);
      const coEntry = {
        coNumber: co.number,
        amount: co.amount,
        status: co.status,
        date: co.createdAt.toISOString().split('T')[0],
      };
      if (existing) {
        existing.changeOrders.push(coEntry);
      } else {
        jobMap.set(co.jobId, {
          jobId: co.jobId,
          jobName: co.jobName || 'Untitled Job',
          customerName: co.customerName || 'Unknown',
          changeOrders: [coEntry],
        });
      }
    });

    return Array.from(jobMap.values()).map(job => {
      const approvedTotal = job.changeOrders
        .filter(co => co.status === 'approved')
        .reduce((sum, co) => sum + co.amount, 0);
      return { ...job, approvedTotal };
    });
  }, [changeOrders]);

  const totals = useMemo(() => {
    let totalApproved = 0;
    let totalCOs = 0;
    cumulativeJobs.forEach(j => {
      totalApproved += j.approvedTotal;
      totalCOs += j.changeOrders.length;
    });
    return { totalApproved, totalCOs, jobCount: cumulativeJobs.length };
  }, [cumulativeJobs]);

  if (cumulativeJobs.length === 0) {
    return (
      <Card><CardContent className="p-12 text-center">
        <TrendingUp size={48} className="mx-auto text-muted mb-4" />
        <h3 className="text-lg font-medium text-main mb-2">{t('changeOrders.noCumulativeData')}</h3>
        <p className="text-muted">{t('changeOrders.noCumulativeDataDesc')}</p>
      </CardContent></Card>
    );
  }

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">{t('changeOrders.jobsWithCOs')}</p>
          <p className="text-xl font-semibold text-main mt-1">{totals.jobCount}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">{t('changeOrders.netApproved')}</p>
          <p className={cn('text-xl font-semibold mt-1', totals.totalApproved >= 0 ? 'text-emerald-400' : 'text-red-400')}>
            {totals.totalApproved >= 0 ? '+' : ''}{formatCurrency(totals.totalApproved)}
          </p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">{t('changeOrders.totalCos')}</p>
          <p className="text-xl font-semibold text-main mt-1">{totals.totalCOs}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">{t('changeOrders.avgCOsPerJob')}</p>
          <p className="text-xl font-semibold text-main mt-1">
            {totals.jobCount > 0 ? (totals.totalCOs / totals.jobCount).toFixed(1) : '0'}
          </p>
        </CardContent></Card>
      </div>

      <div className="space-y-3">
        {cumulativeJobs.map(job => {
          const isExpanded = expandedJob === job.jobId;
          const jobTotal = job.changeOrders.reduce((sum, co) => sum + co.amount, 0);
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
                      <p className="text-sm text-muted">{t('changeOrders.netChange')}</p>
                      <p className={cn('font-semibold', jobTotal >= 0 ? 'text-emerald-400' : 'text-red-400')}>
                        {jobTotal >= 0 ? '+' : ''}{formatCurrency(jobTotal)}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-xs text-muted">{job.changeOrders.length} {t('changeOrders.coAbbrev')}</p>
                    </div>
                  </div>
                </div>
              </div>

              {isExpanded && (
                <div className="border-t border-main px-4 pb-4">
                  <div className="ml-8 mt-3 space-y-2">
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
                          <span className={cn('px-1.5 py-0.5 rounded text-xs', sConfig.bgColor, sConfig.color)}>{t(sConfig.tKey)}</span>
                          <span className="text-xs text-muted">{co.date}</span>
                          <span className="flex-1" />
                          <span className={cn('font-medium', co.amount >= 0 ? 'text-emerald-400' : 'text-red-400')}>
                            {co.amount >= 0 ? '+' : ''}{formatCurrency(co.amount)}
                          </span>
                          <span className="text-xs text-muted w-24 text-right">{t('changeOrders.running')}: {formatCurrency(acc.runningTotal)}</span>
                        </div>
                      );
                      return acc;
                    }, { runningTotal: 0, elements: [] }).elements}

                    <div className="flex items-center gap-3 text-sm p-2 bg-secondary/50 rounded-lg border border-main">
                      <DollarSign size={14} className="text-accent" />
                      <span className="font-mono text-xs text-accent w-20">{t('common.total')}</span>
                      <span className="text-main font-medium flex-1">{t('changeOrders.netChangeOrderValue')}</span>
                      <span className="font-bold text-accent">{formatCurrency(jobTotal)}</span>
                    </div>
                  </div>
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

function ScopeDiffTab({ changeOrders }: { changeOrders: ChangeOrderData[] }) {
  const { t } = useTranslation();
  const scopeItems = useMemo(() => {
    const allItems: { category: string; item: string; quantity: number; unitPrice: number; total: number; coNumber: string; coStatus: string }[] = [];
    changeOrders.forEach(co => {
      co.items.forEach(item => {
        allItems.push({
          category: co.jobName || 'Uncategorized',
          item: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          total: item.total,
          coNumber: co.number,
          coStatus: co.status,
        });
      });
    });
    return allItems;
  }, [changeOrders]);

  const categories = useMemo(() => {
    const map = new Map<string, typeof scopeItems>();
    scopeItems.forEach(d => {
      const existing = map.get(d.category) || [];
      existing.push(d);
      map.set(d.category, existing);
    });
    return Array.from(map.entries());
  }, [scopeItems]);

  const totalValue = scopeItems.reduce((sum, d) => sum + d.total, 0);
  const totalItems = scopeItems.length;
  const approvedItems = scopeItems.filter(d => d.coStatus === 'approved');
  const pendingItems = scopeItems.filter(d => d.coStatus === 'pending_approval');
  const approvedValue = approvedItems.reduce((sum, d) => sum + d.total, 0);

  if (scopeItems.length === 0) {
    return (
      <Card><CardContent className="p-12 text-center">
        <FileDiff size={48} className="mx-auto text-muted mb-4" />
        <h3 className="text-lg font-medium text-main mb-2">{t('changeOrders.noScopeItems')}</h3>
        <p className="text-muted">{t('changeOrders.noScopeItemsDesc')}</p>
      </CardContent></Card>
    );
  }

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">{t('changeOrders.totalValue')}</p>
          <p className="text-xl font-semibold text-main mt-1">{formatCurrency(totalValue)}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">{t('changeOrders.approvedValue')}</p>
          <p className="text-xl font-semibold text-emerald-400 mt-1">{formatCurrency(approvedValue)}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <div className="flex items-center gap-2">
            <Badge variant="success" size="sm">{approvedItems.length} {t('common.approved').toLowerCase()}</Badge>
            <Badge variant="warning" size="sm">{pendingItems.length} {t('common.pending').toLowerCase()}</Badge>
          </div>
          <p className="text-xs text-muted mt-2">{t('changeOrders.lineItemStatuses')}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">{t('changeOrders.totalItems')}</p>
          <p className="text-xl font-semibold text-main mt-1">{totalItems}</p>
        </CardContent></Card>
      </div>

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
                    <th className="px-4 py-2">{t('changeOrders.item')}</th>
                    <th className="px-4 py-2 text-center">{t('changeOrders.coNumber')}</th>
                    <th className="px-4 py-2 text-right">{t('common.qty')}</th>
                    <th className="px-4 py-2 text-right">{t('common.unitPrice')}</th>
                    <th className="px-4 py-2 text-right">{t('common.total')}</th>
                    <th className="px-4 py-2 text-center">{t('common.status')}</th>
                  </tr>
                </thead>
                <tbody>
                  {items.map((item, i) => {
                    const sConfig = statusConfig[item.coStatus as ChangeOrderStatus] || statusConfig.draft;
                    return (
                      <tr key={i} className="border-t border-main/50 text-sm">
                        <td className="px-4 py-2 text-main">{item.item}</td>
                        <td className="px-4 py-2 text-center font-mono text-xs text-muted">{item.coNumber}</td>
                        <td className="px-4 py-2 text-right text-main">{item.quantity}</td>
                        <td className="px-4 py-2 text-right text-muted">{formatCurrency(item.unitPrice)}</td>
                        <td className="px-4 py-2 text-right font-medium text-main">{formatCurrency(item.total)}</td>
                        <td className="px-4 py-2 text-center">
                          <span className={cn('px-1.5 py-0.5 rounded text-xs', sConfig.bgColor, sConfig.color)}>{t(sConfig.tKey)}</span>
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

function AnalyticsTab({ changeOrders }: { changeOrders: ChangeOrderData[] }) {
  const { t } = useTranslation();
  const analytics = useMemo(() => {
    const total = changeOrders.length;
    const approved = changeOrders.filter(co => co.status === 'approved');
    const approvalRate = total > 0 ? (approved.length / total) * 100 : 0;
    const avgAmount = total > 0 ? changeOrders.reduce((sum, co) => sum + Math.abs(co.amount), 0) / total : 0;

    const totalAdded = changeOrders.filter(co => co.amount > 0).reduce((sum, co) => sum + co.amount, 0);
    const totalRemoved = changeOrders.filter(co => co.amount < 0).reduce((sum, co) => sum + Math.abs(co.amount), 0);
    const netChange = totalAdded - totalRemoved;

    let avgApprovalDays = 0;
    const approvedWithDates = approved.filter(co => co.approvedAt);
    if (approvedWithDates.length > 0) {
      const totalDays = approvedWithDates.reduce((sum, co) => {
        const created = co.createdAt.getTime();
        const approvedDate = co.approvedAt!.getTime();
        return sum + Math.max(0, (approvedDate - created) / (1000 * 60 * 60 * 24));
      }, 0);
      avgApprovalDays = totalDays / approvedWithDates.length;
    }

    const reasonMap = new Map<string, { count: number; totalAmount: number }>();
    changeOrders.forEach(co => {
      const reason = REASON_LABELS[co.reason] || co.reason || 'Other';
      const existing = reasonMap.get(reason) || { count: 0, totalAmount: 0 };
      existing.count += 1;
      existing.totalAmount += Math.abs(co.amount);
      reasonMap.set(reason, existing);
    });
    const byReason = Array.from(reasonMap.entries())
      .map(([reason, data]) => ({ reason, ...data }))
      .sort((a, b) => b.totalAmount - a.totalAmount);

    const monthMap = new Map<string, { count: number; amount: number }>();
    changeOrders.forEach(co => {
      const d = co.createdAt;
      const monthKey = `${d.toLocaleString('en', { month: 'short' })} ${d.getFullYear()}`;
      const existing = monthMap.get(monthKey) || { count: 0, amount: 0 };
      existing.count += 1;
      existing.amount += Math.abs(co.amount);
      monthMap.set(monthKey, existing);
    });
    const byMonth = Array.from(monthMap.entries())
      .map(([month, data]) => ({ month, ...data }))
      .sort((a, b) => {
        const parseMonth = (s: string) => {
          const [mon, yr] = s.split(' ');
          return new Date(`${mon} 1, ${yr}`).getTime();
        };
        return parseMonth(a.month) - parseMonth(b.month);
      });

    return { totalCOs: total, approvalRate, avgAmount, avgApprovalDays, totalAdded, totalRemoved, netChange, byReason, byMonth };
  }, [changeOrders]);

  if (changeOrders.length === 0) {
    return (
      <Card><CardContent className="p-12 text-center">
        <BarChart3 size={48} className="mx-auto text-muted mb-4" />
        <h3 className="text-lg font-medium text-main mb-2">{t('changeOrders.noAnalyticsData')}</h3>
        <p className="text-muted">{t('changeOrders.noAnalyticsDataDesc')}</p>
      </CardContent></Card>
    );
  }

  const maxMonthAmount = analytics.byMonth.length > 0 ? Math.max(...analytics.byMonth.map(m => m.amount)) : 1;
  const maxReasonAmount = analytics.byReason.length > 0 ? Math.max(...analytics.byReason.map(r => r.totalAmount)) : 1;

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">{t('changeOrders.approvalRate')}</p>
          <p className="text-2xl font-bold text-emerald-400 mt-1">{analytics.approvalRate.toFixed(1)}%</p>
          <p className="text-xs text-muted mt-1">{analytics.totalCOs} {t('changeOrders.totalChangeOrders')}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">{t('changeOrders.averageCOAmount')}</p>
          <p className="text-2xl font-bold text-main mt-1">{formatCurrency(analytics.avgAmount)}</p>
          <p className="text-xs text-muted mt-1">{t('changeOrders.avgDaysToApprove', { days: analytics.avgApprovalDays.toFixed(1) })}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">{t('changeOrders.netContractChange')}</p>
          <p className={cn('text-2xl font-bold mt-1', analytics.netChange >= 0 ? 'text-emerald-400' : 'text-red-400')}>
            {analytics.netChange >= 0 ? '+' : ''}{formatCurrency(analytics.netChange)}
          </p>
          <p className="text-xs text-muted mt-1">
            <span className="text-emerald-400">+{formatCurrency(analytics.totalAdded)}</span>
            {' / '}
            <span className="text-red-400">-{formatCurrency(analytics.totalRemoved)}</span>
          </p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider">{t('changeOrders.avgApprovalTime')}</p>
          <p className="text-2xl font-bold text-amber-400 mt-1">{analytics.avgApprovalDays.toFixed(1)} {t('common.days')}</p>
          <p className="text-xs text-muted mt-1">{t('changeOrders.perChangeOrder')}</p>
        </CardContent></Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader><CardTitle className="text-base">{t('changeOrders.byReason')}</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            {analytics.byReason.length === 0 && <p className="text-sm text-muted">{t('common.noData')}</p>}
            {analytics.byReason.map((r, i) => (
              <div key={i}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm text-main">{r.reason}</span>
                  <div className="flex items-center gap-3">
                    <span className="text-xs text-muted">{r.count} {t('changeOrders.coAbbrev')}</span>
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

        <Card>
          <CardHeader><CardTitle className="text-base">{t('changeOrders.monthlyTrend')}</CardTitle></CardHeader>
          <CardContent>
            {analytics.byMonth.length === 0 ? (
              <p className="text-sm text-muted">{t('common.noData')}</p>
            ) : (
              <div className="flex items-end gap-2 h-40">
                {analytics.byMonth.map((m, i) => (
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
            )}
          </CardContent>
        </Card>
      </div>

      {analytics.totalCOs > 0 && (
        <Card>
          <CardHeader><CardTitle className="text-base">{t('changeOrders.insights')}</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            {analytics.approvalRate > 0 && (
              <div className="flex items-start gap-3 p-3 bg-secondary/30 rounded-lg">
                <TrendingUp size={16} className="text-emerald-400 mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium text-main">
                    {analytics.netChange >= 0 ? t('changeOrders.insightRevenueIncrease') : t('changeOrders.insightNetReductions')}
                  </p>
                  <p className="text-xs text-muted mt-1">
                    {t('changeOrders.insightNetChangeDetail', { amount: formatCurrency(Math.abs(analytics.netChange)), count: String(analytics.totalCOs), rate: analytics.approvalRate.toFixed(0) })}
                  </p>
                </div>
              </div>
            )}
            {analytics.avgApprovalDays > 0 && (
              <div className="flex items-start gap-3 p-3 bg-secondary/30 rounded-lg">
                <Clock size={16} className="text-blue-400 mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium text-main">{t('changeOrders.insightAvgApprovalTime', { days: analytics.avgApprovalDays.toFixed(1) })}</p>
                  <p className="text-xs text-muted mt-1">{t('changeOrders.insightApprovalBenefit')}</p>
                </div>
              </div>
            )}
            {analytics.byReason.length > 0 && (
              <div className="flex items-start gap-3 p-3 bg-secondary/30 rounded-lg">
                <AlertTriangle size={16} className="text-amber-400 mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium text-main">{t('changeOrders.insightTopReason', { reason: analytics.byReason[0].reason })}</p>
                  <p className="text-xs text-muted mt-1">
                    {t('changeOrders.insightTopReasonDetail', { count: String(analytics.byReason[0].count), amount: formatCurrency(analytics.byReason[0].totalAmount), reason: analytics.byReason[0].reason.toLowerCase() })}
                  </p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      )}
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
              <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>{t(sConfig.tKey)}</span>
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
              <span className="text-sm text-emerald-700 dark:text-emerald-300">{t('changeOrders.approvedByOn', { name: co.approvedByName, date: co.approvedAt ? formatDate(co.approvedAt) : 'N/A' })}</span>
            </div>
          )}

          {co.notes && <div><p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.notes')}</p><p className="text-sm text-main">{co.notes}</p></div>}

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.close')}</Button>
            <Button variant="outline" className="gap-2"><Download size={14} />{t('common.exportPDF')}</Button>
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
      alert(e instanceof Error ? e.message : t('changeOrders.failedToCreate'));
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
            <label className="block text-sm font-medium text-main mb-1.5">{t('changeOrders.jobLabel')} *</label>
            <select value={jobId} onChange={(e) => setJobId(e.target.value)} className={inputCls}>
              <option value="">{t('common.selectJob')}</option>
              {jobs.map((j) => (
                <option key={j.id} value={j.id}>{j.title || 'Untitled'} — {j.customerName}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('changeOrders.titleLabel')} *</label>
            <input type="text" value={title} onChange={(e) => setTitle(e.target.value)} placeholder={t('changeOrders.titlePlaceholder')} className={inputCls} />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('changeOrders.descriptionLabel')} *</label>
            <textarea rows={3} value={description} onChange={(e) => setDescription(e.target.value)} placeholder={t('changeOrders.descriptionPlaceholder')} className={`${inputCls} resize-none`} />
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
              <label className="block text-sm font-medium text-main mb-1.5">{t('changeOrders.scheduleImpactLabel')}</label>
              <input type="number" value={scheduleImpact} onChange={(e) => setScheduleImpact(e.target.value)} placeholder="0" className={inputCls} />
            </div>
          </div>

          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="block text-sm font-medium text-main">{t('estimates.lineItems')}</label>
              <button type="button" onClick={addLineItem} className="text-xs text-accent hover:underline flex items-center gap-1">
                <Plus size={12} /> {t('changeOrders.addItem')}
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
              <span className="text-sm font-semibold text-main">{t('common.total')}: {formatCurrency(computedTotal)}</span>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.notes')}</label>
            <textarea rows={2} value={notes} onChange={(e) => setNotes(e.target.value)} placeholder={t('changeOrders.notesPlaceholder')} className={`${inputCls} resize-none`} />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>{t('common.cancel')}</Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !jobId || !title.trim() || !description.trim()}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <Plus size={16} />}
              {saving ? t('common.creating') : t('changeOrders.createChangeOrder')}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
