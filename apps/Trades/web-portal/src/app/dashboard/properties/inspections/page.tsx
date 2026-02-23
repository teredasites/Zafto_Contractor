'use client';

import { useState } from 'react';
import {
  Plus,
  ClipboardCheck,
  Calendar,
  CheckCircle,
  AlertTriangle,
  ChevronDown,
  ChevronRight,
  Wrench,
  Loader2,
  XCircle,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, cn } from '@/lib/utils';
import { usePmInspections } from '@/lib/hooks/use-pm-inspections';
import type { PmInspectionData, PmInspectionItemData } from '@/lib/hooks/pm-mappers';
import { useTranslation } from '@/lib/translations';

type InspectionType = PmInspectionData['inspectionType'];
type InspectionStatus = PmInspectionData['status'];

const statusConfig: Record<InspectionStatus, { label: string; color: string; bgColor: string }> = {
  scheduled: { label: 'Scheduled', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  in_progress: { label: 'In Progress', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  completed: { label: 'Completed', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  cancelled: { label: 'Cancelled', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
};

const typeConfig: Record<InspectionType, { label: string; color: string; bgColor: string }> = {
  move_in: { label: 'Move-In', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  move_out: { label: 'Move-Out', color: 'text-orange-700 dark:text-orange-300', bgColor: 'bg-orange-100 dark:bg-orange-900/30' },
  routine: { label: 'Routine', color: 'text-cyan-700 dark:text-cyan-300', bgColor: 'bg-cyan-100 dark:bg-cyan-900/30' },
  drive_by: { label: 'Drive-By', color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
  annual: { label: 'Annual', color: 'text-indigo-700 dark:text-indigo-300', bgColor: 'bg-indigo-100 dark:bg-indigo-900/30' },
  emergency: { label: 'Emergency', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
};

const conditionConfig: Record<string, { label: string; color: string; bgColor: string }> = {
  excellent: { label: 'Excellent', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  good: { label: 'Good', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  fair: { label: 'Fair', color: 'text-yellow-700 dark:text-yellow-300', bgColor: 'bg-yellow-100 dark:bg-yellow-900/30' },
  poor: { label: 'Poor', color: 'text-orange-700 dark:text-orange-300', bgColor: 'bg-orange-100 dark:bg-orange-900/30' },
  damaged: { label: 'Damaged', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  missing: { label: 'Missing', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
};

export default function PmInspectionsPage() {
  const { t } = useTranslation();
  const { inspections, loading, error, createInspection } = usePmInspections();
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [showNewModal, setShowNewModal] = useState(false);

  if (loading && inspections.length === 0) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-48 mb-2" /><div className="skeleton h-4 w-56" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(4)].map((_, i) => <div key={i} className="px-6 py-4 flex items-center gap-4"><div className="flex-1"><div className="skeleton h-4 w-40 mb-2" /><div className="skeleton h-3 w-32" /></div><div className="skeleton h-5 w-16 rounded-full" /></div>)}
        </div>
      </div>
    );
  }

  const filteredInspections = inspections.filter((ins) => {
    const matchesSearch =
      (ins.propertyAddress || '').toLowerCase().includes(search.toLowerCase()) ||
      (ins.unitNumber || '').toLowerCase().includes(search.toLowerCase()) ||
      ins.inspectionType.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || ins.inspectionType === typeFilter;
    const matchesStatus = statusFilter === 'all' || ins.status === statusFilter;
    return matchesSearch && matchesType && matchesStatus;
  });

  const totalCount = inspections.length;
  const scheduledCount = inspections.filter((i) => i.status === 'scheduled').length;
  const completedCount = inspections.filter((i) => i.status === 'completed').length;
  const needsRepairCount = inspections.reduce((count, ins) => {
    return count + (ins.items || []).filter((item) => item.requiresRepair).length;
  }, 0);

  const typeOptions = [
    { value: 'all', label: 'All Types' },
    ...Object.entries(typeConfig).map(([k, v]) => ({ value: k, label: v.label })),
  ];

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    ...Object.entries(statusConfig).map(([k, v]) => ({ value: k, label: v.label })),
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
          <h1 className="text-2xl font-semibold text-main">{t('propertiesInspections.title')}</h1>
          <p className="text-muted mt-1">Manage move-in, move-out, routine, and emergency inspections</p>
        </div>
        <Button onClick={() => setShowNewModal(true)}>
          <Plus size={16} />
          New Inspection
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg"><ClipboardCheck size={20} className="text-blue-600 dark:text-blue-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{totalCount}</p><p className="text-sm text-muted">{t('common.totalInspections')}</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg"><Calendar size={20} className="text-amber-600 dark:text-amber-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{scheduledCount}</p><p className="text-sm text-muted">{t('common.scheduled')}</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg"><CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{completedCount}</p><p className="text-sm text-muted">{t('common.completed')}</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg"><Wrench size={20} className="text-red-600 dark:text-red-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{needsRepairCount}</p><p className="text-sm text-muted">Items Needing Repair</p></div>
        </div></CardContent></Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder={t('inspections.searchInspections')} className="sm:w-80" />
        <Select options={typeOptions} value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} className="sm:w-48" />
        <Select options={statusOptions} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="sm:w-48" />
      </div>

      {/* Table */}
      <div className="bg-surface border border-main rounded-xl divide-y divide-main">
        <div className="hidden md:grid grid-cols-12 gap-4 px-6 py-3 text-sm font-medium text-muted">
          <div className="col-span-1"></div>
          <div className="col-span-3">{t('common.propertyUnit')}</div>
          <div className="col-span-1">{t('common.type')}</div>
          <div className="col-span-2">{t('common.date')}</div>
          <div className="col-span-1">{t('common.condition')}</div>
          <div className="col-span-1">{t('common.status')}</div>
          <div className="col-span-1">{t('common.items')}</div>
          <div className="col-span-2">{t('common.repairs')}</div>
        </div>

        {filteredInspections.map((ins) => {
          const sConfig = statusConfig[ins.status];
          const tConfig = typeConfig[ins.inspectionType];
          const cConfig = ins.overallCondition ? conditionConfig[ins.overallCondition] : null;
          const isExpanded = expandedId === ins.id;
          const itemCount = (ins.items || []).length;
          const repairCount = (ins.items || []).filter((i) => i.requiresRepair).length;

          return (
            <div key={ins.id}>
              <div
                className="grid grid-cols-1 md:grid-cols-12 gap-4 px-6 py-4 items-center hover:bg-surface-hover cursor-pointer transition-colors"
                onClick={() => setExpandedId(isExpanded ? null : ins.id)}
              >
                <div className="col-span-1">
                  {isExpanded ? <ChevronDown size={16} className="text-muted" /> : <ChevronRight size={16} className="text-muted" />}
                </div>
                <div className="col-span-3">
                  <p className="text-sm font-medium text-main">{ins.propertyAddress || 'N/A'}</p>
                  {ins.unitNumber && <p className="text-xs text-muted">Unit {ins.unitNumber}</p>}
                </div>
                <div className="col-span-1">
                  <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', tConfig.bgColor, tConfig.color)}>
                    {tConfig.label}
                  </span>
                </div>
                <div className="col-span-2">
                  <p className="text-sm text-muted">{formatDate(ins.inspectionDate)}</p>
                </div>
                <div className="col-span-1">
                  {cConfig ? (
                    <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', cConfig.bgColor, cConfig.color)}>
                      {cConfig.label}
                    </span>
                  ) : (
                    <span className="text-xs text-muted">-</span>
                  )}
                </div>
                <div className="col-span-1">
                  <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>
                    {sConfig.label}
                  </span>
                </div>
                <div className="col-span-1">
                  <p className="text-sm text-muted">{itemCount}</p>
                </div>
                <div className="col-span-2">
                  {repairCount > 0 ? (
                    <span className="text-sm text-red-600 dark:text-red-400 flex items-center gap-1">
                      <AlertTriangle size={14} />
                      {repairCount} repair{repairCount !== 1 ? 's' : ''} needed
                    </span>
                  ) : (
                    <span className="text-sm text-muted">{t('common.none')}</span>
                  )}
                </div>
              </div>

              {/* Expanded Items */}
              {isExpanded && (ins.items || []).length > 0 && (
                <div className="px-6 pb-4">
                  <div className="ml-6 bg-secondary rounded-lg border border-main overflow-hidden">
                    <div className="grid grid-cols-12 gap-2 px-4 py-2 text-xs font-medium text-muted border-b border-main">
                      <div className="col-span-2">{t('common.area')}</div>
                      <div className="col-span-3">{t('common.item')}</div>
                      <div className="col-span-2">{t('common.condition')}</div>
                      <div className="col-span-1">Repair</div>
                      <div className="col-span-4">{t('common.notes')}</div>
                    </div>
                    {(ins.items || []).map((item) => {
                      const itemCond = conditionConfig[item.condition] || conditionConfig.good;
                      return (
                        <div key={item.id} className="grid grid-cols-12 gap-2 px-4 py-2.5 border-b border-main/30 last:border-b-0 items-center">
                          <div className="col-span-2">
                            <p className="text-sm text-main">{item.area}</p>
                          </div>
                          <div className="col-span-3">
                            <p className="text-sm text-main">{item.item}</p>
                          </div>
                          <div className="col-span-2">
                            <span className={cn('px-1.5 py-0.5 rounded text-[10px] font-medium', itemCond.bgColor, itemCond.color)}>
                              {itemCond.label}
                            </span>
                          </div>
                          <div className="col-span-1">
                            {item.requiresRepair ? (
                              <Wrench size={14} className="text-red-500" />
                            ) : (
                              <CheckCircle size={14} className="text-emerald-500" />
                            )}
                          </div>
                          <div className="col-span-4">
                            <p className="text-xs text-muted line-clamp-1">{item.notes || '-'}</p>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {isExpanded && (ins.items || []).length === 0 && (
                <div className="px-6 pb-4">
                  <div className="ml-6 p-4 bg-secondary rounded-lg text-center text-sm text-muted">
                    No inspection items recorded yet
                  </div>
                </div>
              )}
            </div>
          );
        })}

        {filteredInspections.length === 0 && (
          <div className="px-6 py-12 text-center">
            <ClipboardCheck size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('common.noInspectionsFound')}</h3>
            <p className="text-muted mb-4">Schedule your first property inspection.</p>
            <Button onClick={() => setShowNewModal(true)}>
              <Plus size={16} />
              New Inspection
            </Button>
          </div>
        )}
      </div>

      {/* New Inspection Modal */}
      {showNewModal && (
        <NewInspectionModal
          onClose={() => setShowNewModal(false)}
          onCreate={createInspection}
        />
      )}
    </div>
  );
}

function NewInspectionModal({ onClose, onCreate }: {
  onClose: () => void;
  onCreate: (data: {
    propertyId: string;
    unitId?: string;
    inspectionType: PmInspectionData['inspectionType'];
    inspectionDate: string;
    notes?: string;
  }) => Promise<string>;
}) {
  const { t } = useTranslation();
  const [propertyId, setPropertyId] = useState('');
  const [unitId, setUnitId] = useState('');
  const [inspectionType, setInspectionType] = useState<PmInspectionData['inspectionType']>('routine');
  const [inspectionDate, setInspectionDate] = useState(new Date().toISOString().split('T')[0]);
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSubmit = async () => {
    if (!propertyId.trim() || !inspectionDate) return;
    setSaving(true);
    try {
      await onCreate({
        propertyId: propertyId.trim(),
        unitId: unitId.trim() || undefined,
        inspectionType,
        inspectionDate,
        notes: notes.trim() || undefined,
      });
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to create inspection');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>New Property Inspection</CardTitle>
          <Button variant="ghost" size="sm" onClick={onClose}>
            <XCircle size={18} />
          </Button>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Inspection Type *</label>
            <select
              value={inspectionType}
              onChange={(e) => setInspectionType(e.target.value as PmInspectionData['inspectionType'])}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
            >
              <option value="move_in">Move-In</option>
              <option value="move_out">Move-Out</option>
              <option value="routine">Routine</option>
              <option value="drive_by">Drive-By</option>
              <option value="annual">{t('common.annual')}</option>
              <option value="emergency">{t('common.emergency')}</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Property ID *</label>
            <input
              type="text"
              value={propertyId}
              onChange={(e) => setPropertyId(e.target.value)}
              placeholder="Enter property ID"
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Unit ID (Optional)</label>
            <input
              type="text"
              value={unitId}
              onChange={(e) => setUnitId(e.target.value)}
              placeholder="Enter unit ID"
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Date *</label>
            <input
              type="date"
              value={inspectionDate}
              onChange={(e) => setInspectionDate(e.target.value)}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.notes')}</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Special instructions..."
              rows={2}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !propertyId.trim()}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <Plus size={16} />}
              {saving ? 'Creating...' : 'Create Inspection'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
