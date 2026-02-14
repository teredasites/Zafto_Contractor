'use client';

import { useState, useMemo, useCallback, useEffect, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  Plus,
  ZoomIn,
  ZoomOut,
  Activity,
  Users,
  RefreshCw,
  ChevronDown,
  Diamond,
  Trash2,
  CheckCircle2,
  Link2,
  Bookmark,
  Upload,
  Download,
} from 'lucide-react';
import { useScheduleProject } from '@/lib/hooks/use-schedule';
import { useScheduleTasks } from '@/lib/hooks/use-schedule-tasks';
import { useScheduleDependencies } from '@/lib/hooks/use-schedule-dependencies';
import { useScheduleImportExport } from '@/lib/hooks/use-schedule-import-export';
import type { ScheduleTask, ScheduleDependency } from '@/lib/types/scheduling';

type ZoomLevel = 'day' | 'week' | 'month';

const ZOOM_DAY_WIDTH: Record<ZoomLevel, number> = {
  day: 40,
  week: 16,
  month: 4,
};

const ROW_HEIGHT = 32;
const TASK_LIST_WIDTH = 320;
const HEADER_HEIGHT = 36;
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

export default function GanttPage() {
  const params = useParams();
  const router = useRouter();
  const projectId = params.id as string;

  const { project, loading: projLoading } = useScheduleProject(projectId);
  const { tasks, loading: tasksLoading, createTask, updateTask, deleteTask, updateProgress, triggerCpmRecalc } = useScheduleTasks(projectId);
  const { dependencies } = useScheduleDependencies(projectId);
  const { importing, exporting, importSchedule, exportSchedule, detectFormat, importResult, exportResult, error: ieError, clearResults } = useScheduleImportExport(projectId);

  const [zoom, setZoom] = useState<ZoomLevel>('week');
  const [showCritical, setShowCritical] = useState(true);
  const [showImport, setShowImport] = useState(false);
  const [showExport, setShowExport] = useState(false);
  const [showDeps, setShowDeps] = useState(true);
  const [selectedTask, setSelectedTask] = useState<string | null>(null);
  const [showAddTask, setShowAddTask] = useState(false);
  const [newTaskName, setNewTaskName] = useState('');
  const [newTaskDuration, setNewTaskDuration] = useState('5');

  const chartRef = useRef<HTMLDivElement>(null);

  const dayWidth = ZOOM_DAY_WIDTH[zoom];

  // Compute date range from tasks
  const { startDate, endDate, totalDays } = useMemo(() => {
    let min = new Date();
    let max = new Date();
    let hasData = false;

    for (const t of tasks) {
      const es = t.early_start || t.planned_start;
      const ef = t.early_finish || t.planned_finish;
      if (es) {
        const d = new Date(es);
        if (!hasData || d < min) min = d;
        hasData = true;
      }
      if (ef) {
        const d = new Date(ef);
        if (!hasData || d > max) max = d;
        hasData = true;
      }
    }

    const start = new Date(min);
    start.setDate(start.getDate() - 7);
    const end = new Date(max);
    end.setDate(end.getDate() + 14);
    const days = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));

    return { startDate: start, endDate: end, totalDays: Math.max(days, 30) };
  }, [tasks]);

  // Keyboard shortcuts
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === '+' || e.key === '=') {
        setZoom(prev => prev === 'month' ? 'week' : prev === 'week' ? 'day' : 'day');
      } else if (e.key === '-') {
        setZoom(prev => prev === 'day' ? 'week' : prev === 'week' ? 'month' : 'month');
      } else if (e.key === 'Delete' && selectedTask) {
        deleteTask(selectedTask);
        setSelectedTask(null);
      } else if (e.ctrlKey && e.key === 'n') {
        e.preventDefault();
        setShowAddTask(true);
      }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [selectedTask, deleteTask]);

  const handleAddTask = async () => {
    if (!newTaskName.trim()) return;
    try {
      await createTask({
        name: newTaskName.trim(),
        original_duration: parseInt(newTaskDuration) || 5,
        planned_start: new Date().toISOString().slice(0, 10),
      });
      setShowAddTask(false);
      setNewTaskName('');
      setNewTaskDuration('5');
    } catch {
      // Error in hook
    }
  };

  const getTaskX = (dateStr: string | null) => {
    if (!dateStr) return 0;
    const d = new Date(dateStr);
    const days = (d.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24);
    return days * dayWidth;
  };

  const loading = projLoading || tasksLoading;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin w-8 h-8 border-2 border-accent border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      {/* Toolbar */}
      <div className="flex items-center justify-between px-4 py-2 border-b border-main bg-surface">
        <div className="flex items-center gap-3">
          <button onClick={() => router.push('/dashboard/scheduling')} className="p-1.5 hover:bg-surface-alt rounded-md">
            <ArrowLeft className="w-4 h-4 text-secondary" />
          </button>
          <h1 className="text-sm font-semibold text-primary">{project?.name || 'Schedule'}</h1>
        </div>

        <div className="flex items-center gap-1">
          <button onClick={() => setZoom(prev => prev === 'day' ? 'week' : prev === 'week' ? 'month' : 'month')} className="p-1.5 hover:bg-surface-alt rounded-md" title="Zoom out">
            <ZoomOut className="w-4 h-4 text-secondary" />
          </button>
          <span className="px-2 text-xs text-tertiary min-w-[50px] text-center">{zoom}</span>
          <button onClick={() => setZoom(prev => prev === 'month' ? 'week' : prev === 'week' ? 'day' : 'day')} className="p-1.5 hover:bg-surface-alt rounded-md" title="Zoom in">
            <ZoomIn className="w-4 h-4 text-secondary" />
          </button>

          <div className="w-px h-5 bg-main mx-1" />

          <button
            onClick={() => setShowCritical(!showCritical)}
            className={`p-1.5 rounded-md ${showCritical ? 'bg-error/10 text-error' : 'hover:bg-surface-alt text-secondary'}`}
            title="Critical path"
          >
            <Activity className="w-4 h-4" />
          </button>

          <button
            onClick={() => setShowDeps(!showDeps)}
            className={`p-1.5 rounded-md ${showDeps ? 'bg-accent/10 text-accent' : 'hover:bg-surface-alt text-secondary'}`}
            title="Dependencies"
          >
            <Link2 className="w-4 h-4" />
          </button>

          <div className="w-px h-5 bg-main mx-1" />

          <button onClick={() => router.push(`/dashboard/scheduling/${projectId}/resources`)} className="p-1.5 hover:bg-surface-alt rounded-md" title="Resources">
            <Users className="w-4 h-4 text-secondary" />
          </button>

          <button onClick={() => router.push(`/dashboard/scheduling/${projectId}/baselines`)} className="p-1.5 hover:bg-surface-alt rounded-md" title="Baselines">
            <Bookmark className="w-4 h-4 text-secondary" />
          </button>

          <div className="w-px h-5 bg-main mx-1" />

          <button onClick={() => setShowImport(true)} disabled={importing} className="p-1.5 hover:bg-surface-alt rounded-md" title="Import Schedule">
            <Upload className={`w-4 h-4 ${importing ? 'text-accent animate-pulse' : 'text-secondary'}`} />
          </button>

          <button onClick={() => setShowExport(true)} disabled={exporting} className="p-1.5 hover:bg-surface-alt rounded-md" title="Export Schedule">
            <Download className={`w-4 h-4 ${exporting ? 'text-accent animate-pulse' : 'text-secondary'}`} />
          </button>

          <button onClick={triggerCpmRecalc} className="p-1.5 hover:bg-surface-alt rounded-md" title="Recalculate CPM">
            <RefreshCw className="w-4 h-4 text-secondary" />
          </button>

          <button
            onClick={() => setShowAddTask(true)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-accent text-on-accent rounded-md text-xs font-medium ml-2"
          >
            <Plus className="w-3.5 h-3.5" />
            Task
          </button>
        </div>
      </div>

      {/* Gantt body */}
      {tasks.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center">
          <div className="w-16 h-16 rounded-full bg-surface-alt flex items-center justify-center mb-4">
            <Plus className="w-8 h-8 text-secondary" />
          </div>
          <h3 className="text-lg font-semibold text-primary mb-1">No tasks yet</h3>
          <p className="text-sm text-secondary mb-4">Add tasks to build your project schedule</p>
          <button onClick={() => setShowAddTask(true)} className="flex items-center gap-2 px-4 py-2 bg-accent text-on-accent rounded-lg text-sm font-medium">
            <Plus className="w-4 h-4" /> Add Task
          </button>
        </div>
      ) : (
        <div className="flex-1 flex overflow-hidden">
          {/* Task list */}
          <div className="flex-shrink-0 border-r border-main" style={{ width: TASK_LIST_WIDTH }}>
            {/* Task list header */}
            <div className="flex items-center px-3 text-xs font-medium text-secondary bg-surface-alt border-b border-main" style={{ height: HEADER_HEIGHT }}>
              <span className="flex-1">Task Name</span>
              <span className="w-14 text-right">Dur</span>
              <span className="w-14 text-right">%</span>
            </div>
            {/* Task rows */}
            <div className="overflow-y-auto" style={{ height: `calc(100% - ${HEADER_HEIGHT}px)` }}>
              {tasks.map((task) => (
                <div
                  key={task.id}
                  onClick={() => setSelectedTask(task.id === selectedTask ? null : task.id)}
                  className={`flex items-center px-3 border-b border-main/50 cursor-pointer text-xs transition-colors ${
                    selectedTask === task.id ? 'bg-accent/10' : 'hover:bg-surface-alt'
                  } ${showCritical && task.is_critical ? 'bg-error/5' : ''}`}
                  style={{ height: ROW_HEIGHT, paddingLeft: 12 + (task.indent_level || 0) * 16 }}
                >
                  {task.task_type === 'summary' && <ChevronDown className="w-3 h-3 text-tertiary mr-1 flex-shrink-0" />}
                  {task.task_type === 'milestone' && <Diamond className="w-3 h-3 text-warning mr-1 flex-shrink-0" />}
                  <span className={`flex-1 truncate ${
                    task.task_type === 'summary' ? 'font-semibold' : ''
                  } ${showCritical && task.is_critical ? 'text-error' : 'text-primary'}`}>
                    {task.name}
                  </span>
                  <span className="w-14 text-right text-tertiary">{task.original_duration ?? '-'}</span>
                  <span className="w-14 text-right text-tertiary">{task.percent_complete.toFixed(0)}%</span>
                </div>
              ))}
            </div>
          </div>

          {/* Chart area */}
          <div className="flex-1 overflow-auto" ref={chartRef}>
            {/* Timeline header */}
            <div className="sticky top-0 z-10 bg-surface-alt border-b border-main" style={{ height: HEADER_HEIGHT, width: totalDays * dayWidth }}>
              <svg width={totalDays * dayWidth} height={HEADER_HEIGHT}>
                {Array.from({ length: totalDays }, (_, i) => {
                  const date = new Date(startDate);
                  date.setDate(date.getDate() + i);
                  const x = i * dayWidth;

                  let label = '';
                  if (zoom === 'day') {
                    label = `${date.getDate()}`;
                  } else if (zoom === 'week' && date.getDay() === 1) {
                    label = `${MONTHS[date.getMonth()]} ${date.getDate()}`;
                  } else if (zoom === 'month' && date.getDate() === 1) {
                    label = `${MONTHS[date.getMonth()]} ${date.getFullYear()}`;
                  }

                  if (!label) return null;

                  return (
                    <g key={i}>
                      <line x1={x} y1={HEADER_HEIGHT - 6} x2={x} y2={HEADER_HEIGHT} stroke="var(--color-border-main)" strokeWidth={0.5} />
                      <text x={x + 3} y={HEADER_HEIGHT / 2 + 4} fontSize={10} fill="var(--color-text-tertiary)">{label}</text>
                    </g>
                  );
                })}
              </svg>
            </div>

            {/* Task bars */}
            <div className="relative" style={{ width: totalDays * dayWidth, height: tasks.length * ROW_HEIGHT }}>
              {/* Today line */}
              {(() => {
                const todayDays = (Date.now() - startDate.getTime()) / (1000 * 60 * 60 * 24);
                const todayX = todayDays * dayWidth;
                return <div className="absolute top-0 bottom-0 w-px bg-error/40 z-10" style={{ left: todayX }} />;
              })()}

              {/* Row backgrounds */}
              {tasks.map((_, i) => (
                <div
                  key={i}
                  className="absolute border-b border-main/30"
                  style={{ top: i * ROW_HEIGHT, height: ROW_HEIGHT, left: 0, right: 0 }}
                />
              ))}

              {/* Dependency arrows (SVG) */}
              {showDeps && (
                <svg className="absolute inset-0 pointer-events-none" style={{ width: totalDays * dayWidth, height: tasks.length * ROW_HEIGHT }}>
                  {dependencies.map((dep) => {
                    const predIdx = tasks.findIndex(t => t.id === dep.predecessor_id);
                    const succIdx = tasks.findIndex(t => t.id === dep.successor_id);
                    if (predIdx === -1 || succIdx === -1) return null;

                    const pred = tasks[predIdx];
                    const succ = tasks[succIdx];

                    const predEnd = getTaskX(pred.early_finish || pred.planned_finish);
                    const succStart = getTaskX(succ.early_start || succ.planned_start);
                    const predY = predIdx * ROW_HEIGHT + ROW_HEIGHT / 2;
                    const succY = succIdx * ROW_HEIGHT + ROW_HEIGHT / 2;

                    // FS dependency arrow path
                    const midX = Math.max(predEnd + 8, succStart - 8);
                    const path = `M ${predEnd} ${predY} L ${midX} ${predY} L ${midX} ${succY} L ${succStart} ${succY}`;

                    return (
                      <g key={dep.id}>
                        <path d={path} fill="none" stroke="var(--color-text-tertiary)" strokeWidth={1} opacity={0.5} />
                        <polygon
                          points={`${succStart},${succY} ${succStart - 5},${succY - 3} ${succStart - 5},${succY + 3}`}
                          fill="var(--color-text-tertiary)"
                          opacity={0.5}
                        />
                      </g>
                    );
                  })}
                </svg>
              )}

              {/* Task bars */}
              {tasks.map((task, i) => {
                const es = task.early_start || task.planned_start;
                const ef = task.early_finish || task.planned_finish;
                if (!es) return null;

                const x = getTaskX(es);
                const barWidth = ef ? Math.max(getTaskX(ef) - x, 4) : dayWidth * 5;
                const y = i * ROW_HEIGHT;
                const barY = ROW_HEIGHT * 0.2;
                const barH = ROW_HEIGHT * 0.6;

                const isCritical = showCritical && task.is_critical;
                const barColor = isCritical ? 'bg-error' : 'bg-accent';
                const barBg = isCritical ? 'bg-error/20' : 'bg-accent/20';

                if (task.task_type === 'milestone') {
                  return (
                    <div
                      key={task.id}
                      className="absolute flex items-center justify-center"
                      style={{ left: x - 6, top: y, width: 12, height: ROW_HEIGHT }}
                    >
                      <Diamond className="w-3 h-3 text-warning fill-warning" />
                    </div>
                  );
                }

                if (task.task_type === 'summary') {
                  return (
                    <div key={task.id} className="absolute" style={{ left: x, top: y + barY + barH * 0.35, width: barWidth, height: barH * 0.3 }}>
                      <div className="h-full bg-secondary rounded-sm" />
                      <div className="absolute left-0 top-[-4px] w-[3px] bg-secondary" style={{ height: barH }} />
                      <div className="absolute right-0 top-[-4px] w-[3px] bg-secondary" style={{ height: barH }} />
                    </div>
                  );
                }

                return (
                  <div
                    key={task.id}
                    className={`absolute rounded-sm cursor-pointer group ${barBg}`}
                    style={{ left: x, top: y + barY, width: barWidth, height: barH }}
                    onClick={() => setSelectedTask(task.id)}
                  >
                    {/* Progress fill */}
                    {task.percent_complete > 0 && (
                      <div
                        className={`h-full rounded-sm ${barColor}`}
                        style={{ width: `${Math.min(task.percent_complete, 100)}%` }}
                      />
                    )}
                    {/* Border */}
                    <div className={`absolute inset-0 rounded-sm border ${isCritical ? 'border-error/50' : 'border-accent/50'}`} />
                    {/* Task name tooltip on hover */}
                    <div className="absolute -top-6 left-0 hidden group-hover:block bg-surface border border-main rounded px-2 py-0.5 text-[10px] text-primary whitespace-nowrap shadow-sm z-20">
                      {task.name} ({task.percent_complete.toFixed(0)}%)
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* Selected task panel */}
      {selectedTask && (() => {
        const task = tasks.find(t => t.id === selectedTask);
        if (!task) return null;

        return (
          <div className="border-t border-main bg-surface px-4 py-3 flex items-center gap-4 text-xs">
            <span className="font-semibold text-primary flex-shrink-0">{task.name}</span>
            <span className="text-tertiary">Duration: {task.original_duration ?? '-'}d</span>
            <span className="text-tertiary">ES: {task.early_start?.slice(5, 10) || '-'}</span>
            <span className="text-tertiary">EF: {task.early_finish?.slice(5, 10) || '-'}</span>
            <span className="text-tertiary">Float: {task.total_float?.toFixed(0) ?? '-'}d</span>
            {task.is_critical && <span className="text-error font-medium">Critical</span>}
            <div className="flex-1" />
            <button onClick={() => { updateProgress(task.id, 100); }} className="p-1 hover:bg-success/10 rounded text-success" title="Mark complete">
              <CheckCircle2 className="w-4 h-4" />
            </button>
            <button onClick={() => { deleteTask(task.id); setSelectedTask(null); }} className="p-1 hover:bg-error/10 rounded text-error" title="Delete">
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        );
      })()}

      {/* Add task modal */}
      {showAddTask && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => setShowAddTask(false)}>
          <div className="bg-surface border border-main rounded-xl p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-lg font-semibold text-primary mb-4">Add Task</h2>
            <input
              type="text"
              placeholder="Task name"
              value={newTaskName}
              onChange={(e) => setNewTaskName(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleAddTask()}
              autoFocus
              className="w-full px-4 py-2.5 bg-base border border-main rounded-lg text-sm text-primary placeholder:text-quaternary focus:outline-none focus:border-accent mb-3"
            />
            <input
              type="number"
              placeholder="Duration (days)"
              value={newTaskDuration}
              onChange={(e) => setNewTaskDuration(e.target.value)}
              className="w-full px-4 py-2.5 bg-base border border-main rounded-lg text-sm text-primary placeholder:text-quaternary focus:outline-none focus:border-accent mb-4"
            />
            <div className="flex justify-end gap-3">
              <button onClick={() => setShowAddTask(false)} className="px-4 py-2 text-sm text-secondary">Cancel</button>
              <button onClick={handleAddTask} disabled={!newTaskName.trim()} className="px-4 py-2 bg-accent text-on-accent rounded-lg text-sm font-medium disabled:opacity-50">Add</button>
            </div>
          </div>
        </div>
      )}

      {/* Import modal */}
      {showImport && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => { setShowImport(false); clearResults(); }}>
          <div className="bg-surface border border-main rounded-xl p-6 w-full max-w-lg" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-lg font-semibold text-primary mb-1">Import Schedule</h2>
            <p className="text-xs text-tertiary mb-4">Supports P6 XER, MS Project XML, and CSV</p>

            {ieError && (
              <div className="p-3 bg-error/5 border border-error/20 rounded-lg mb-3">
                <p className="text-xs text-error">{ieError}</p>
              </div>
            )}

            {importResult ? (
              <div className="space-y-3">
                <div className="p-4 bg-success/5 border border-success/20 rounded-lg">
                  <p className="text-sm font-medium text-primary mb-2">Import Complete</p>
                  <div className="grid grid-cols-2 gap-2 text-xs text-secondary">
                    <span>Tasks: {importResult.tasks_imported}</span>
                    <span>Dependencies: {importResult.dependencies_imported}</span>
                    <span>Resources: {importResult.resources_imported}</span>
                    <span>Assignments: {importResult.assignments_imported}</span>
                  </div>
                </div>
                {importResult.warnings.length > 0 && (
                  <div className="p-3 bg-warning/5 border border-warning/20 rounded-lg">
                    <p className="text-xs font-medium text-warning mb-1">Warnings:</p>
                    <ul className="space-y-1">
                      {importResult.warnings.map((w, i) => (
                        <li key={i} className="text-xs text-secondary">{w}</li>
                      ))}
                    </ul>
                  </div>
                )}
                <button onClick={() => { setShowImport(false); clearResults(); }} className="w-full py-2 bg-accent text-on-accent rounded-lg text-sm font-medium">
                  Done
                </button>
              </div>
            ) : (
              <div>
                <label className="block w-full p-8 border-2 border-dashed border-main rounded-xl text-center cursor-pointer hover:border-accent/50 transition-colors mb-4">
                  <Upload className="w-8 h-8 text-tertiary mx-auto mb-2" />
                  <p className="text-sm text-secondary mb-1">Drop file here or click to browse</p>
                  <p className="text-xs text-tertiary">.xer, .xml, .csv</p>
                  <input
                    type="file"
                    accept=".xer,.xml,.csv"
                    className="hidden"
                    onChange={async (e) => {
                      const file = e.target.files?.[0];
                      if (!file) return;
                      const format = detectFormat(file.name);
                      if (!format) return;
                      await importSchedule(file, format);
                    }}
                    disabled={importing}
                  />
                </label>
                {importing && (
                  <div className="flex items-center justify-center gap-2 text-sm text-secondary">
                    <div className="animate-spin w-4 h-4 border-2 border-accent border-t-transparent rounded-full" />
                    Importing...
                  </div>
                )}
                <div className="flex justify-end mt-2">
                  <button onClick={() => { setShowImport(false); clearResults(); }} className="px-4 py-2 text-sm text-secondary">Cancel</button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Export modal */}
      {showExport && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => { setShowExport(false); clearResults(); }}>
          <div className="bg-surface border border-main rounded-xl p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-lg font-semibold text-primary mb-1">Export Schedule</h2>
            <p className="text-xs text-tertiary mb-4">Download in your preferred format</p>

            {ieError && (
              <div className="p-3 bg-error/5 border border-error/20 rounded-lg mb-3">
                <p className="text-xs text-error">{ieError}</p>
              </div>
            )}

            {exportResult ? (
              <div className="space-y-3">
                <div className="p-4 bg-success/5 border border-success/20 rounded-lg text-center">
                  <p className="text-sm font-medium text-primary mb-2">Export Ready</p>
                  <p className="text-xs text-secondary mb-3">{exportResult.filename} ({exportResult.tasks_exported} tasks)</p>
                  <a
                    href={exportResult.download_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 px-4 py-2 bg-accent text-on-accent rounded-lg text-sm font-medium"
                  >
                    <Download className="w-4 h-4" />
                    Download
                  </a>
                </div>
                <button onClick={() => { setShowExport(false); clearResults(); }} className="w-full py-2 text-sm text-secondary">
                  Close
                </button>
              </div>
            ) : (
              <div className="space-y-2">
                {([
                  { fmt: 'csv' as const, label: 'CSV', desc: 'Spreadsheet-compatible' },
                  { fmt: 'msp_xml' as const, label: 'MS Project XML', desc: 'Microsoft Project compatible' },
                  { fmt: 'xer' as const, label: 'Primavera P6 XER', desc: 'Oracle Primavera compatible' },
                  { fmt: 'pdf' as const, label: 'PDF Report', desc: 'Printable schedule report' },
                ]).map(({ fmt, label, desc }) => (
                  <button
                    key={fmt}
                    onClick={async () => {
                      const result = await exportSchedule(fmt);
                      if (result?.download_url && fmt === 'pdf') {
                        window.open(result.download_url, '_blank');
                      }
                    }}
                    disabled={exporting}
                    className="w-full flex items-center gap-3 p-3 border border-main rounded-lg hover:bg-surface-alt transition-colors text-left disabled:opacity-50"
                  >
                    <Download className="w-4 h-4 text-secondary flex-shrink-0" />
                    <div>
                      <p className="text-sm font-medium text-primary">{label}</p>
                      <p className="text-xs text-tertiary">{desc}</p>
                    </div>
                  </button>
                ))}
                {exporting && (
                  <div className="flex items-center justify-center gap-2 py-2 text-sm text-secondary">
                    <div className="animate-spin w-4 h-4 border-2 border-accent border-t-transparent rounded-full" />
                    Exporting...
                  </div>
                )}
                <div className="flex justify-end pt-1">
                  <button onClick={() => { setShowExport(false); clearResults(); }} className="px-4 py-2 text-sm text-secondary">Cancel</button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
