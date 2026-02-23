'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  Bookmark,
  Camera,
  ChevronDown,
  ChevronUp,
  Trash2,
  BarChart2,
  AlertTriangle,
  ListTodo,
  Flag,
  Activity,
} from 'lucide-react';
import { useScheduleBaselines } from '@/lib/hooks/use-schedule-baselines';
import { useScheduleProject } from '@/lib/hooks/use-schedule';
import { formatCompactCurrency, formatDateLocale } from '@/lib/format-locale';
import type { ScheduleBaseline, ScheduleBaselineTask } from '@/lib/types/scheduling';
import { useTranslation } from '@/lib/translations';

interface VarianceRow {
  task_id: string;
  task_name: string;
  baseline_start: string | null;
  baseline_finish: string | null;
  current_start: string | null;
  current_finish: string | null;
  start_variance_days: number;
  finish_variance_days: number;
  status: 'ahead' | 'behind' | 'on_time';
}

export default function BaselinesPage() {
  const { t } = useTranslation();
  const params = useParams();
  const router = useRouter();
  const projectId = params.id as string;

  const { project } = useScheduleProject(projectId);
  const {
    baselines,
    loading,
    error,
    saveBaseline,
    deleteBaseline,
    getBaselineTasks,
    getVarianceReport,
  } = useScheduleBaselines(projectId);

  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [expandedTasks, setExpandedTasks] = useState<ScheduleBaselineTask[] | null>(null);
  const [varianceRows, setVarianceRows] = useState<VarianceRow[] | null>(null);
  const [showCapture, setShowCapture] = useState(false);
  const [captureName, setCaptureName] = useState('');
  const [captureNotes, setCaptureNotes] = useState('');
  const [capturing, setCapturing] = useState(false);
  const [captureResult, setCaptureResult] = useState<{ spi: number; cpi: number; tasks: number } | null>(null);

  const toggleExpand = async (id: string) => {
    if (expandedId === id) {
      setExpandedId(null);
      setExpandedTasks(null);
      setVarianceRows(null);
      return;
    }
    setExpandedId(id);
    setExpandedTasks(null);
    setVarianceRows(null);
    try {
      const tasks = await getBaselineTasks(id);
      setExpandedTasks(tasks);
    } catch {
      // Error handled in hook
    }
  };

  const handleCapture = async () => {
    if (!captureName.trim() || capturing) return;
    setCapturing(true);
    try {
      const result = await saveBaseline(captureName.trim(), captureNotes.trim() || undefined);
      if (result?.evm) {
        setCaptureResult({
          spi: result.evm.spi,
          cpi: result.evm.cpi,
          tasks: 0,
        });
      }
      setShowCapture(false);
      setCaptureName('');
      setCaptureNotes('');
    } catch {
      // Error in hook
    } finally {
      setCapturing(false);
    }
  };

  const handleDelete = async (baseline: ScheduleBaseline) => {
    if (!confirm(`Delete baseline "${baseline.name}"? This cannot be undone.`)) return;
    try {
      await deleteBaseline(baseline.id);
      if (expandedId === baseline.id) {
        setExpandedId(null);
        setExpandedTasks(null);
        setVarianceRows(null);
      }
    } catch {
      // Error in hook
    }
  };

  const handleVariance = async (baselineId: string) => {
    try {
      const rows = await getVarianceReport(baselineId);
      setVarianceRows(rows);
    } catch {
      // Error in hook
    }
  };

  const formatDate = (d: string) => {
    return formatDateLocale(d);
  };

  const formatCost = (cost: number) => formatCompactCurrency(cost);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-2 border-accent border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={() => router.push(`/dashboard/scheduling/${projectId}`)}
            className="p-1.5 hover:bg-surface-alt rounded-md"
          >
            <ArrowLeft className="w-4 h-4 text-secondary" />
          </button>
          <div>
            <h1 className="text-xl font-semibold text-primary">{t('schedulingBaselines.title')}</h1>
            <p className="text-sm text-secondary">{project?.name || 'Schedule'}</p>
          </div>
        </div>
        <button
          onClick={() => setShowCapture(true)}
          disabled={baselines.length >= 5}
          className="flex items-center gap-2 px-4 py-2 bg-accent text-on-accent rounded-lg text-sm font-medium disabled:opacity-50"
        >
          <Camera className="w-4 h-4" />
          Capture Baseline
        </button>
      </div>

      {/* Error */}
      {error && (
        <div className="p-3 bg-error/5 border border-error/20 rounded-lg">
          <p className="text-sm text-error">{error}</p>
        </div>
      )}

      {/* Capture result toast */}
      {captureResult && (
        <div className="p-4 bg-success/5 border border-success/20 rounded-xl flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Bookmark className="w-4 h-4 text-success" />
            <span className="text-sm font-medium text-primary">{t('schedulingBaselines.baselineCaptured')}</span>
          </div>
          <div className="flex items-center gap-4 text-xs text-secondary">
            <span>SPI: {captureResult.spi.toFixed(2)}</span>
            <span>CPI: {captureResult.cpi.toFixed(2)}</span>
          </div>
          <button onClick={() => setCaptureResult(null)} className="text-xs text-tertiary hover:text-secondary">
            Dismiss
          </button>
        </div>
      )}

      {/* Max baselines warning */}
      {baselines.length >= 5 && (
        <div className="flex items-center gap-2 p-3 bg-warning/5 border border-warning/20 rounded-lg">
          <AlertTriangle className="w-4 h-4 text-warning" />
          <span className="text-sm text-warning">Maximum 5 baselines reached. Delete one to capture a new baseline.</span>
        </div>
      )}

      {/* Baseline list */}
      {baselines.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <div className="w-16 h-16 rounded-full bg-surface-alt flex items-center justify-center mb-4">
            <Bookmark className="w-8 h-8 text-secondary" />
          </div>
          <h3 className="text-lg font-semibold text-primary mb-1">{t('schedulingBaselines.noBaselinesYet')}</h3>
          <p className="text-sm text-secondary mb-1">{t('schedulingBaselines.captureABaselineToSnapshotYourCurrentSchedule')}</p>
          <p className="text-xs text-tertiary">Max 5 baselines per project</p>
        </div>
      ) : (
        <div className="space-y-3">
          {baselines.map((baseline) => {
            const isExpanded = expandedId === baseline.id;

            return (
              <div
                key={baseline.id}
                className={`bg-surface border rounded-xl transition-colors ${
                  baseline.is_active ? 'border-accent/50' : 'border-main'
                }`}
              >
                {/* Card header */}
                <button
                  onClick={() => toggleExpand(baseline.id)}
                  className="w-full p-5 text-left"
                >
                  <div className="flex items-start gap-3">
                    <div className={`p-2.5 rounded-lg ${baseline.is_active ? 'bg-accent/10' : 'bg-surface-alt'}`}>
                      <Bookmark className={`w-5 h-5 ${baseline.is_active ? 'text-accent' : 'text-tertiary'}`} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <h3 className="text-sm font-semibold text-primary truncate">{baseline.name}</h3>
                        {baseline.is_active && (
                          <span className="px-2 py-0.5 text-[10px] font-semibold bg-accent/10 text-accent rounded">{t('common.active')}</span>
                        )}
                      </div>
                      <p className="text-xs text-tertiary mt-0.5">
                        BL #{baseline.baseline_number} | {formatDate(baseline.captured_at)}
                      </p>
                    </div>
                    {isExpanded ? (
                      <ChevronUp className="w-4 h-4 text-tertiary flex-shrink-0" />
                    ) : (
                      <ChevronDown className="w-4 h-4 text-tertiary flex-shrink-0" />
                    )}
                  </div>

                  {/* Stats */}
                  <div className="grid grid-cols-4 gap-3 mt-4">
                    <div className="text-center">
                      <p className="text-sm font-bold text-primary">{baseline.total_tasks}</p>
                      <p className="text-[10px] text-tertiary">{t('schedulingBaselines.tasks')}</p>
                    </div>
                    <div className="text-center">
                      <p className="text-sm font-bold text-primary">{baseline.total_milestones}</p>
                      <p className="text-[10px] text-tertiary">{t('schedulingBaselines.milestones')}</p>
                    </div>
                    <div className="text-center">
                      <p className="text-sm font-bold text-primary">{formatCost(baseline.total_cost)}</p>
                      <p className="text-[10px] text-tertiary">{t('common.cost')}</p>
                    </div>
                    <div className="text-center">
                      <p className="text-sm font-bold text-primary">
                        {baseline.planned_start && baseline.planned_finish
                          ? `${Math.round((new Date(baseline.planned_finish).getTime() - new Date(baseline.planned_start).getTime()) / (1000 * 60 * 60 * 24))}d`
                          : '—'}
                      </p>
                      <p className="text-[10px] text-tertiary">{t('common.duration')}</p>
                    </div>
                  </div>
                </button>

                {/* Expanded details */}
                {isExpanded && (
                  <div className="border-t border-main px-5 py-4 space-y-4">
                    {/* Description */}
                    {baseline.description && (
                      <p className="text-sm text-secondary">{baseline.description}</p>
                    )}

                    {/* Dates */}
                    <div className="grid grid-cols-2 gap-3 text-xs">
                      {baseline.planned_start && (
                        <div>
                          <span className="text-tertiary">Start: </span>
                          <span className="text-secondary font-medium">{formatDate(baseline.planned_start)}</span>
                        </div>
                      )}
                      {baseline.planned_finish && (
                        <div>
                          <span className="text-tertiary">Finish: </span>
                          <span className="text-secondary font-medium">{formatDate(baseline.planned_finish)}</span>
                        </div>
                      )}
                      {baseline.data_date && (
                        <div>
                          <span className="text-tertiary">Data Date: </span>
                          <span className="text-secondary font-medium">{formatDate(baseline.data_date)}</span>
                        </div>
                      )}
                    </div>

                    {/* Task snapshot */}
                    {expandedTasks && (
                      <div>
                        <h4 className="text-xs font-semibold text-primary mb-2">{t('schedulingBaselines.taskSnapshot')}</h4>
                        <div className="space-y-1.5">
                          <div className="flex items-center gap-2 text-xs">
                            <ListTodo className="w-3.5 h-3.5 text-tertiary" />
                            <span className="text-secondary">{expandedTasks.length} tasks</span>
                            <span className="text-tertiary">|</span>
                            <span className="text-secondary">
                              {expandedTasks.filter(t => t.is_critical).length} critical
                            </span>
                          </div>
                          <div className="flex items-center gap-2 text-xs">
                            <Flag className="w-3.5 h-3.5 text-tertiary" />
                            <span className="text-secondary">
                              {expandedTasks.filter(t => t.task_type === 'milestone').length} milestones
                            </span>
                            <span className="text-tertiary">|</span>
                            <span className="text-secondary">
                              {formatCost(expandedTasks.reduce((s, t) => s + (t.budgeted_cost ?? 0), 0))} budget
                            </span>
                          </div>
                          <div className="flex items-center gap-2 text-xs">
                            <Activity className="w-3.5 h-3.5 text-tertiary" />
                            <span className="text-secondary">
                              {expandedTasks.length > 0
                                ? (expandedTasks.reduce((s, t) => s + (t.percent_complete ?? 0), 0) / expandedTasks.length).toFixed(1)
                                : '0'}% avg complete
                            </span>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Variance report */}
                    {varianceRows && (
                      <div>
                        <h4 className="text-xs font-semibold text-primary mb-2">{t('schedulingBaselines.varianceReport')}</h4>
                        {varianceRows.length === 0 ? (
                          <p className="text-xs text-tertiary">{t('schedulingBaselines.noMatchingTasksForComparison')}</p>
                        ) : (
                          <div className="space-y-2">
                            {/* Summary chips */}
                            <div className="flex gap-2">
                              <span className="px-2.5 py-1 text-[11px] font-semibold bg-success/10 text-success rounded">
                                {varianceRows.filter(r => r.status === 'ahead').length} ahead
                              </span>
                              <span className="px-2.5 py-1 text-[11px] font-semibold bg-info/10 text-info rounded">
                                {varianceRows.filter(r => r.status === 'on_time').length} on time
                              </span>
                              <span className="px-2.5 py-1 text-[11px] font-semibold bg-error/10 text-error rounded">
                                {varianceRows.filter(r => r.status === 'behind').length} behind
                              </span>
                            </div>

                            {/* Behind tasks */}
                            {varianceRows.filter(r => r.status === 'behind').length > 0 && (
                              <div className="space-y-1">
                                {varianceRows
                                  .filter(r => r.status === 'behind')
                                  .slice(0, 5)
                                  .map((row) => (
                                    <div key={row.task_id} className="flex items-center gap-2 text-xs">
                                      <AlertTriangle className="w-3 h-3 text-warning flex-shrink-0" />
                                      <span className="text-secondary truncate flex-1">{row.task_name}</span>
                                      <span className="text-error font-semibold">+{row.finish_variance_days}d</span>
                                    </div>
                                  ))}
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    )}

                    {/* Action buttons */}
                    <div className="flex gap-2 pt-1">
                      <button
                        onClick={() => handleVariance(baseline.id)}
                        className="flex-1 flex items-center justify-center gap-2 py-2 border border-main rounded-lg text-xs font-medium text-primary hover:bg-surface-alt"
                      >
                        <BarChart2 className="w-3.5 h-3.5" />
                        Variance Report
                      </button>
                      <button
                        onClick={() => handleDelete(baseline)}
                        disabled={baselines.length <= 1}
                        className="flex-1 flex items-center justify-center gap-2 py-2 border border-main rounded-lg text-xs font-medium text-error hover:bg-error/5 disabled:opacity-30"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                        Delete
                      </button>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Capture modal */}
      {showCapture && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => setShowCapture(false)}>
          <div className="bg-surface border border-main rounded-xl p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-lg font-semibold text-primary">{t('schedulingBaselines.captureBaseline')}</h2>
            <p className="text-xs text-tertiary mt-1 mb-4">
              Snapshot all current task data (max 5 per project)
            </p>
            <input
              type="text"
              placeholder="Baseline name (e.g., Original Schedule)"
              value={captureName}
              onChange={(e) => setCaptureName(e.target.value)}
              autoFocus
              className="w-full px-4 py-2.5 bg-base border border-main rounded-lg text-sm text-primary placeholder:text-quaternary focus:outline-none focus:border-accent mb-3"
            />
            <textarea
              placeholder="Notes (optional)"
              value={captureNotes}
              onChange={(e) => setCaptureNotes(e.target.value)}
              rows={2}
              className="w-full px-4 py-2.5 bg-base border border-main rounded-lg text-sm text-primary placeholder:text-quaternary focus:outline-none focus:border-accent mb-4 resize-none"
            />
            <div className="flex justify-end gap-3">
              <button
                onClick={() => { setShowCapture(false); setCaptureName(''); setCaptureNotes(''); }}
                className="px-4 py-2 text-sm text-secondary"
              >
                Cancel
              </button>
              <button
                onClick={handleCapture}
                disabled={!captureName.trim() || capturing}
                className="px-4 py-2 bg-accent text-on-accent rounded-lg text-sm font-medium disabled:opacity-50"
              >
                {capturing ? 'Capturing...' : 'Capture'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
