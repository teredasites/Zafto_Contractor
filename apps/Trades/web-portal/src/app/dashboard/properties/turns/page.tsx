'use client';

import { useState } from 'react';
import {
  Plus,
  RefreshCcw,
  DollarSign,
  Clock,
  CheckCircle,
  Calendar,
  Building,
  ChevronDown,
  ChevronRight,
  Loader2,
  XCircle,
  Home,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { SearchInput } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useUnitTurns } from '@/lib/hooks/use-unit-turns';
import { turnStatusLabels } from '@/lib/hooks/pm-mappers';
import type { UnitTurnData, UnitTurnTaskData } from '@/lib/hooks/pm-mappers';
import { useTranslation } from '@/lib/translations';

type TurnStatus = UnitTurnData['status'];

const statusConfig: Record<TurnStatus, { label: string; color: string; bgColor: string }> = {
  pending: { label: 'Pending', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
  in_progress: { label: 'In Progress', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  ready: { label: 'Ready', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  listed: { label: 'Listed', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  leased: { label: 'Leased', color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
};

const taskTypeLabels: Record<UnitTurnTaskData['taskType'], string> = {
  cleaning: 'Cleaning',
  painting: 'Painting',
  flooring: 'Flooring',
  appliance: 'Appliance',
  plumbing: 'Plumbing',
  electrical: 'Electrical',
  hvac: 'HVAC',
  general_repair: 'General Repair',
  pest_control: 'Pest Control',
  landscaping: 'Landscaping',
  inspection: 'Inspection',
  other: 'Other',
};

const kanbanColumns: TurnStatus[] = ['pending', 'in_progress', 'ready', 'listed', 'leased'];

export default function UnitTurnsPage() {
  const { t } = useTranslation();
  const { turns, loading, error, createTurn, completeTask, updateTurnStatus } = useUnitTurns();
  const [search, setSearch] = useState('');
  const [expandedTurnId, setExpandedTurnId] = useState<string | null>(null);
  const [showNewModal, setShowNewModal] = useState(false);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  if (loading && turns.length === 0) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-40 mb-2" /><div className="skeleton h-4 w-64" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-14" /></div>)}
        </div>
        <div className="flex gap-4 overflow-x-auto pb-4">
          {[...Array(5)].map((_, i) => <div key={i} className="flex-shrink-0 w-72 bg-secondary rounded-xl p-3 min-h-[300px]"><div className="skeleton h-5 w-24 mb-3" /></div>)}
        </div>
      </div>
    );
  }

  const filteredTurns = turns.filter((turn) => {
    const matchesSearch =
      (turn.propertyAddress || '').toLowerCase().includes(search.toLowerCase()) ||
      (turn.unitNumber || '').toLowerCase().includes(search.toLowerCase());
    return matchesSearch;
  });

  const activeTurns = turns.filter((t) => t.status !== 'leased');
  const totalCost = activeTurns.reduce((sum, t) => sum + t.totalCost, 0);
  const depositRecovered = activeTurns.reduce((sum, t) => sum + t.depositDeductions, 0);

  // Calculate average days to ready
  const readyTurns = turns.filter((t) => t.actualReadyDate && t.moveOutDate);
  const avgDays = readyTurns.length > 0
    ? Math.round(
        readyTurns.reduce((sum, t) => {
          const moveOut = new Date(t.moveOutDate!);
          const ready = new Date(t.actualReadyDate!);
          return sum + Math.max(0, (ready.getTime() - moveOut.getTime()) / (1000 * 60 * 60 * 24));
        }, 0) / readyTurns.length
      )
    : 0;

  const getColumnTurns = (status: TurnStatus) =>
    filteredTurns.filter((t) => t.status === status);

  const handleCompleteTask = async (taskId: string) => {
    setActionLoading(taskId);
    try {
      await completeTask(taskId);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to complete task');
    } finally {
      setActionLoading(null);
    }
  };

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
          <h1 className="text-2xl font-semibold text-main">Unit Turns</h1>
          <p className="text-muted mt-1">Manage turnover tasks from move-out to re-lease</p>
        </div>
        <Button onClick={() => setShowNewModal(true)}>
          <Plus size={16} />
          New Turn
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg"><RefreshCcw size={20} className="text-blue-600 dark:text-blue-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{activeTurns.length}</p><p className="text-sm text-muted">Active Turns</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg"><DollarSign size={20} className="text-amber-600 dark:text-amber-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{formatCurrency(totalCost)}</p><p className="text-sm text-muted">Total Cost</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg"><Clock size={20} className="text-purple-600 dark:text-purple-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{avgDays}</p><p className="text-sm text-muted">Avg Days to Ready</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg"><CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{formatCurrency(depositRecovered)}</p><p className="text-sm text-muted">Deposit Recovered</p></div>
        </div></CardContent></Card>
      </div>

      {/* Search */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search units, properties..." className="sm:w-80" />
      </div>

      {/* Kanban Board */}
      <div className="flex gap-4 overflow-x-auto pb-4">
        {kanbanColumns.map((status) => {
          const columnTurns = getColumnTurns(status);
          const sConfig = statusConfig[status];

          return (
            <div key={status} className="flex-shrink-0 w-72">
              <div className="bg-secondary rounded-t-xl px-4 py-3 border border-main border-b-0">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>
                      {sConfig.label}
                    </span>
                    <span className="text-sm text-muted">{columnTurns.length}</span>
                  </div>
                </div>
              </div>
              <div className="bg-secondary/50 rounded-b-xl border border-main border-t-0 p-2 min-h-[400px] space-y-2">
                {columnTurns.map((turn) => {
                  const tasks = turn.tasks || [];
                  const completedTasks = tasks.filter((t) => t.status === 'completed' || t.status === 'skipped').length;
                  const totalTasks = tasks.length;
                  const isExpanded = expandedTurnId === turn.id;

                  return (
                    <div
                      key={turn.id}
                      className="bg-surface border border-main rounded-lg p-3 cursor-pointer hover:shadow-md transition-all"
                      onClick={() => setExpandedTurnId(isExpanded ? null : turn.id)}
                    >
                      <div className="flex items-start justify-between mb-2">
                        <div>
                          <p className="text-sm font-medium text-main">
                            {turn.unitNumber ? `Unit ${turn.unitNumber}` : 'Unit'}
                          </p>
                          <p className="text-xs text-muted flex items-center gap-1">
                            <Building size={11} />
                            {turn.propertyAddress || 'N/A'}
                          </p>
                        </div>
                        {isExpanded ? <ChevronDown size={14} className="text-muted mt-0.5" /> : <ChevronRight size={14} className="text-muted mt-0.5" />}
                      </div>

                      <div className="space-y-1.5 text-xs text-muted">
                        {turn.moveOutDate && (
                          <p className="flex items-center gap-1">
                            <Calendar size={11} />
                            Move-out: {formatDate(turn.moveOutDate)}
                          </p>
                        )}
                        {turn.targetReadyDate && (
                          <p className="flex items-center gap-1">
                            <Clock size={11} />
                            Target: {formatDate(turn.targetReadyDate)}
                          </p>
                        )}
                      </div>

                      {totalTasks > 0 && (
                        <div className="mt-2 pt-2 border-t border-main/50">
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-xs text-muted">{completedTasks}/{totalTasks} tasks</span>
                            <span className="text-xs font-medium text-main">{formatCurrency(turn.totalCost)}</span>
                          </div>
                          <div className="w-full h-1.5 bg-secondary rounded-full overflow-hidden">
                            <div
                              className={cn(
                                'h-full rounded-full transition-all',
                                completedTasks === totalTasks ? 'bg-emerald-500' : completedTasks > 0 ? 'bg-amber-500' : 'bg-gray-300'
                              )}
                              style={{ width: `${totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0}%` }}
                            />
                          </div>
                        </div>
                      )}

                      {/* Expanded: Tasks List */}
                      {isExpanded && tasks.length > 0 && (
                        <div className="mt-3 pt-2 border-t border-main space-y-1.5" onClick={(e) => e.stopPropagation()}>
                          {tasks.sort((a, b) => a.sortOrder - b.sortOrder).map((task) => {
                            const isTaskCompleted = task.status === 'completed' || task.status === 'skipped';
                            const isTaskLoading = actionLoading === task.id;

                            return (
                              <div
                                key={task.id}
                                className={cn(
                                  'flex items-center gap-2 p-2 rounded-lg text-xs',
                                  isTaskCompleted ? 'bg-emerald-50/50 dark:bg-emerald-900/10' : 'bg-secondary'
                                )}
                              >
                                <button
                                  onClick={() => {
                                    if (!isTaskCompleted && !isTaskLoading) {
                                      handleCompleteTask(task.id);
                                    }
                                  }}
                                  disabled={isTaskCompleted || isTaskLoading}
                                  className={cn(
                                    'flex-shrink-0 w-4 h-4 rounded border-2 flex items-center justify-center transition-colors',
                                    isTaskCompleted
                                      ? 'bg-emerald-500 border-emerald-500 text-white'
                                      : 'border-muted hover:border-accent'
                                  )}
                                >
                                  {isTaskLoading ? (
                                    <Loader2 size={10} className="animate-spin" />
                                  ) : isTaskCompleted ? (
                                    <CheckCircle size={10} />
                                  ) : null}
                                </button>
                                <div className="flex-1 min-w-0">
                                  <p className={cn('font-medium', isTaskCompleted ? 'line-through text-muted' : 'text-main')}>
                                    {task.description}
                                  </p>
                                  <p className="text-muted">{taskTypeLabels[task.taskType]}</p>
                                </div>
                                {task.estimatedCost && (
                                  <span className="text-muted flex-shrink-0">
                                    {formatCurrency(task.actualCost || task.estimatedCost)}
                                  </span>
                                )}
                              </div>
                            );
                          })}
                        </div>
                      )}

                      {isExpanded && tasks.length === 0 && (
                        <div className="mt-3 pt-2 border-t border-main text-center">
                          <p className="text-xs text-muted py-2">No tasks added yet</p>
                        </div>
                      )}
                    </div>
                  );
                })}
                {columnTurns.length === 0 && (
                  <div className="text-center py-8 text-muted text-sm">
                    No turns in this stage
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* New Turn Modal */}
      {showNewModal && (
        <NewTurnModal
          onClose={() => setShowNewModal(false)}
          onCreate={createTurn}
        />
      )}
    </div>
  );
}

function NewTurnModal({ onClose, onCreate }: {
  onClose: () => void;
  onCreate: (data: {
    propertyId: string;
    unitId: string;
    moveOutDate?: string;
    targetReadyDate?: string;
    notes?: string;
  }) => Promise<string>;
}) {
  const [propertyId, setPropertyId] = useState('');
  const [unitId, setUnitId] = useState('');
  const [moveOutDate, setMoveOutDate] = useState('');
  const [targetReadyDate, setTargetReadyDate] = useState('');
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSubmit = async () => {
    if (!propertyId.trim() || !unitId.trim()) return;
    setSaving(true);
    try {
      await onCreate({
        propertyId: propertyId.trim(),
        unitId: unitId.trim(),
        moveOutDate: moveOutDate || undefined,
        targetReadyDate: targetReadyDate || undefined,
        notes: notes.trim() || undefined,
      });
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to create unit turn');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>New Unit Turn</CardTitle>
          <Button variant="ghost" size="sm" onClick={onClose}>
            <XCircle size={18} />
          </Button>
        </CardHeader>
        <CardContent className="space-y-4">
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
            <label className="block text-sm font-medium text-main mb-1.5">Unit ID *</label>
            <input
              type="text"
              value={unitId}
              onChange={(e) => setUnitId(e.target.value)}
              placeholder="Enter unit ID"
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Move-Out Date</label>
              <input
                type="date"
                value={moveOutDate}
                onChange={(e) => setMoveOutDate(e.target.value)}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Target Ready Date</label>
              <input
                type="date"
                value={targetReadyDate}
                onChange={(e) => setTargetReadyDate(e.target.value)}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
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
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !propertyId.trim() || !unitId.trim()}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <Plus size={16} />}
              {saving ? 'Creating...' : 'Create Turn'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
