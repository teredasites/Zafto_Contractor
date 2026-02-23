'use client';

import { useState } from 'react';
import {
  Plus,
  Wrench,
  Clock,
  CheckCircle,
  AlertTriangle,
  User,
  Building,
  Calendar,
  Loader2,
  LayoutList,
  LayoutGrid,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, cn } from '@/lib/utils';
import { usePmMaintenance } from '@/lib/hooks/use-pm-maintenance';
import { maintenanceStatusLabels, urgencyLabels } from '@/lib/hooks/pm-mappers';
import type { MaintenanceRequestData } from '@/lib/hooks/pm-mappers';
import { useTranslation } from '@/lib/translations';

type MaintenanceStatus = MaintenanceRequestData['status'];
type Urgency = MaintenanceRequestData['urgency'];
type Category = MaintenanceRequestData['category'];

const statusConfig: Record<MaintenanceStatus, { label: string; color: string; bgColor: string }> = {
  submitted: { label: 'Submitted', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  reviewed: { label: 'Reviewed', color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
  scheduled: { label: 'Scheduled', color: 'text-cyan-700 dark:text-cyan-300', bgColor: 'bg-cyan-100 dark:bg-cyan-900/30' },
  in_progress: { label: 'In Progress', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  completed: { label: 'Completed', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  cancelled: { label: 'Cancelled', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
};

const urgencyConfig: Record<Urgency, { label: string; color: string; bgColor: string }> = {
  low: { label: 'Low', color: 'text-green-700 dark:text-green-300', bgColor: 'bg-green-100 dark:bg-green-900/30' },
  medium: { label: 'Medium', color: 'text-yellow-700 dark:text-yellow-300', bgColor: 'bg-yellow-100 dark:bg-yellow-900/30' },
  high: { label: 'High', color: 'text-orange-700 dark:text-orange-300', bgColor: 'bg-orange-100 dark:bg-orange-900/30' },
  emergency: { label: 'Emergency', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
};

const categoryLabels: Record<Category, string> = {
  plumbing: 'Plumbing',
  electrical: 'Electrical',
  hvac: 'HVAC',
  appliance: 'Appliance',
  structural: 'Structural',
  pest: 'Pest Control',
  landscaping: 'Landscaping',
  cleaning: 'Cleaning',
  safety: 'Safety',
  other: 'Other',
};

const kanbanColumns: MaintenanceStatus[] = ['submitted', 'reviewed', 'scheduled', 'in_progress', 'completed'];

export default function MaintenancePage() {
  const { t } = useTranslation();
  const { requests, loading, error, assignToSelf, updateRequestStatus } = usePmMaintenance();
  const [search, setSearch] = useState('');
  const [urgencyFilter, setUrgencyFilter] = useState('all');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [viewMode, setViewMode] = useState<'board' | 'list'>('board');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  if (loading && requests.length === 0) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-56 mb-2" /><div className="skeleton h-4 w-64" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
        <div className="flex gap-4 overflow-x-auto pb-4">
          {[...Array(5)].map((_, i) => <div key={i} className="flex-shrink-0 w-72 bg-secondary rounded-xl p-3 min-h-[300px]"><div className="skeleton h-5 w-24 mb-3" /></div>)}
        </div>
      </div>
    );
  }

  const filteredRequests = requests.filter((req) => {
    const matchesSearch =
      req.title.toLowerCase().includes(search.toLowerCase()) ||
      (req.propertyAddress || '').toLowerCase().includes(search.toLowerCase()) ||
      (req.tenantName || '').toLowerCase().includes(search.toLowerCase());
    const matchesUrgency = urgencyFilter === 'all' || req.urgency === urgencyFilter;
    const matchesCategory = categoryFilter === 'all' || req.category === categoryFilter;
    return matchesSearch && matchesUrgency && matchesCategory;
  });

  const totalCount = requests.length;
  const openCount = requests.filter((r) => r.status === 'submitted' || r.status === 'reviewed').length;
  const inProgressCount = requests.filter((r) => r.status === 'in_progress' || r.status === 'scheduled').length;
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const completedThisMonth = requests.filter((r) => r.status === 'completed' && r.completedAt && r.completedAt >= startOfMonth).length;

  const getColumnRequests = (status: MaintenanceStatus) =>
    filteredRequests.filter((r) => r.status === status);

  const handleAssignToSelf = async (requestId: string) => {
    setActionLoading(requestId);
    try {
      await assignToSelf(requestId);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to assign');
    } finally {
      setActionLoading(null);
    }
  };

  const handleUpdateStatus = async (requestId: string, status: MaintenanceStatus) => {
    setActionLoading(requestId);
    try {
      await updateRequestStatus(requestId, status);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to update status');
    } finally {
      setActionLoading(null);
    }
  };

  const urgencyOptions = [
    { value: 'all', label: 'All Urgencies' },
    ...Object.entries(urgencyLabels).map(([k, v]) => ({ value: k, label: v })),
  ];

  const categoryOptions = [
    { value: 'all', label: 'All Categories' },
    ...Object.entries(categoryLabels).map(([k, v]) => ({ value: k, label: v })),
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('propertiesMaintenance.title')}</h1>
          <p className="text-muted mt-1">Track and manage property maintenance requests</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center p-1 bg-secondary rounded-lg">
            <button
              onClick={() => setViewMode('board')}
              className={cn(
                'p-2 rounded-md transition-colors',
                viewMode === 'board' ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
              )}
            >
              <LayoutGrid size={16} />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={cn(
                'p-2 rounded-md transition-colors',
                viewMode === 'list' ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
              )}
            >
              <LayoutList size={16} />
            </button>
          </div>
          <Button>
            <Plus size={16} />
            New Request
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg"><Wrench size={20} className="text-blue-600 dark:text-blue-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{totalCount}</p><p className="text-sm text-muted">Total Requests</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg"><AlertTriangle size={20} className="text-amber-600 dark:text-amber-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{openCount}</p><p className="text-sm text-muted">Open</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg"><Clock size={20} className="text-purple-600 dark:text-purple-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{inProgressCount}</p><p className="text-sm text-muted">In Progress</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg"><CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{completedThisMonth}</p><p className="text-sm text-muted">Completed (This Month)</p></div>
        </div></CardContent></Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search requests..." className="sm:w-80" />
        <Select options={urgencyOptions} value={urgencyFilter} onChange={(e) => setUrgencyFilter(e.target.value)} className="sm:w-48" />
        <Select options={categoryOptions} value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)} className="sm:w-48" />
      </div>

      {viewMode === 'board' ? (
        /* Kanban Board */
        <div className="flex gap-4 overflow-x-auto pb-4">
          {kanbanColumns.map((status) => {
            const columnRequests = getColumnRequests(status);
            const sConfig = statusConfig[status];

            return (
              <div key={status} className="flex-shrink-0 w-72">
                <div className="bg-secondary rounded-t-xl px-4 py-3 border border-main border-b-0">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>
                        {sConfig.label}
                      </span>
                      <span className="text-sm text-muted">{columnRequests.length}</span>
                    </div>
                  </div>
                </div>
                <div className="bg-secondary/50 rounded-b-xl border border-main border-t-0 p-2 min-h-[400px] space-y-2">
                  {columnRequests.map((req) => {
                    const uConfig = urgencyConfig[req.urgency];
                    const isActioning = actionLoading === req.id;

                    return (
                      <div
                        key={req.id}
                        className="bg-surface border border-main rounded-lg p-3 cursor-pointer hover:shadow-md transition-all"
                      >
                        <div className="flex items-start justify-between mb-2">
                          <h4 className="text-sm font-medium text-main line-clamp-2">{req.title}</h4>
                          <span className={cn('ml-2 flex-shrink-0 px-1.5 py-0.5 rounded text-[10px] font-semibold', uConfig.bgColor, uConfig.color)}>
                            {uConfig.label}
                          </span>
                        </div>

                        <div className="space-y-1 mb-3">
                          <p className="text-xs text-muted flex items-center gap-1">
                            <Building size={11} />
                            {req.propertyAddress || 'N/A'}
                            {req.unitNumber ? ` - Unit ${req.unitNumber}` : ''}
                          </p>
                          {req.tenantName && (
                            <p className="text-xs text-muted flex items-center gap-1">
                              <User size={11} />
                              {req.tenantName}
                            </p>
                          )}
                          <p className="text-xs text-muted flex items-center gap-1">
                            <Calendar size={11} />
                            {formatDate(req.createdAt)}
                          </p>
                        </div>

                        <div className="flex items-center gap-1 text-xs text-muted mb-2">
                          <span className={cn('px-1.5 py-0.5 rounded text-[10px] font-medium bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400')}>
                            {categoryLabels[req.category]}
                          </span>
                        </div>

                        {/* Actions */}
                        <div className="flex items-center gap-1.5 pt-2 border-t border-main/50">
                          {(req.status === 'submitted' || req.status === 'reviewed') && (
                            <button
                              onClick={(e) => { e.stopPropagation(); handleAssignToSelf(req.id); }}
                              disabled={isActioning}
                              className="text-[10px] font-medium text-accent hover:underline disabled:opacity-50"
                            >
                              {isActioning ? 'Assigning...' : "I'll Handle It"}
                            </button>
                          )}
                          {req.status === 'submitted' && (
                            <button
                              onClick={(e) => { e.stopPropagation(); handleUpdateStatus(req.id, 'reviewed'); }}
                              disabled={isActioning}
                              className="text-[10px] font-medium text-purple-600 dark:text-purple-400 hover:underline disabled:opacity-50 ml-auto"
                            >
                              Mark Reviewed
                            </button>
                          )}
                          {req.status === 'in_progress' && (
                            <button
                              onClick={(e) => { e.stopPropagation(); handleUpdateStatus(req.id, 'completed'); }}
                              disabled={isActioning}
                              className="text-[10px] font-medium text-emerald-600 dark:text-emerald-400 hover:underline disabled:opacity-50 ml-auto"
                            >
                              Complete
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                  {columnRequests.length === 0 && (
                    <div className="text-center py-8 text-muted text-sm">
                      No requests
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        /* List View */
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          <div className="hidden md:grid grid-cols-12 gap-4 px-6 py-3 text-sm font-medium text-muted">
            <div className="col-span-3">Title</div>
            <div className="col-span-2">Property / Unit</div>
            <div className="col-span-1">Tenant</div>
            <div className="col-span-1">Category</div>
            <div className="col-span-1">Urgency</div>
            <div className="col-span-1">Status</div>
            <div className="col-span-1">Created</div>
            <div className="col-span-2 text-right">Actions</div>
          </div>

          {filteredRequests.map((req) => {
            const sConfig = statusConfig[req.status];
            const uConfig = urgencyConfig[req.urgency];
            const isActioning = actionLoading === req.id;

            return (
              <div key={req.id} className="grid grid-cols-1 md:grid-cols-12 gap-4 px-6 py-4 items-center hover:bg-surface-hover transition-colors">
                <div className="col-span-3">
                  <p className="text-sm font-medium text-main">{req.title}</p>
                  <p className="text-xs text-muted line-clamp-1">{req.description}</p>
                </div>
                <div className="col-span-2">
                  <p className="text-sm text-main">{req.propertyAddress || 'N/A'}</p>
                  {req.unitNumber && <p className="text-xs text-muted">Unit {req.unitNumber}</p>}
                </div>
                <div className="col-span-1">
                  <p className="text-sm text-muted">{req.tenantName || '-'}</p>
                </div>
                <div className="col-span-1">
                  <p className="text-xs text-muted">{categoryLabels[req.category]}</p>
                </div>
                <div className="col-span-1">
                  <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', uConfig.bgColor, uConfig.color)}>
                    {uConfig.label}
                  </span>
                </div>
                <div className="col-span-1">
                  <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>
                    {sConfig.label}
                  </span>
                </div>
                <div className="col-span-1">
                  <p className="text-xs text-muted">{formatDate(req.createdAt)}</p>
                </div>
                <div className="col-span-2 text-right flex items-center gap-1.5 justify-end">
                  {(req.status === 'submitted' || req.status === 'reviewed') && (
                    <Button
                      size="sm"
                      variant="secondary"
                      onClick={() => handleAssignToSelf(req.id)}
                      disabled={isActioning}
                    >
                      {isActioning ? <Loader2 size={12} className="animate-spin" /> : <User size={12} />}
                      Handle
                    </Button>
                  )}
                  {req.status === 'in_progress' && (
                    <Button
                      size="sm"
                      variant="secondary"
                      onClick={() => handleUpdateStatus(req.id, 'completed')}
                      disabled={isActioning}
                    >
                      <CheckCircle size={12} />
                      Complete
                    </Button>
                  )}
                </div>
              </div>
            );
          })}

          {filteredRequests.length === 0 && (
            <div className="px-6 py-12 text-center">
              <Wrench size={48} className="mx-auto text-muted mb-4" />
              <h3 className="text-lg font-medium text-main mb-2">No maintenance requests found</h3>
              <p className="text-muted">All caught up. No open requests match your filters.</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
