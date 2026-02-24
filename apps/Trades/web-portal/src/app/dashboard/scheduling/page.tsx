'use client';

import { useState, useEffect, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Search,
  GanttChart,
  CalendarRange,
  MoreHorizontal,
  Activity,
  CheckCircle2,
  PauseCircle,
  Clock,
  Archive,
  LayoutDashboard,
  ClipboardList,
  AlertTriangle,
  MapPin,
  Users,
  Diamond,
  TrendingUp,
  Copy,
  Save,
} from 'lucide-react';
import { useScheduleProjects } from '@/lib/hooks/use-schedule';
import { useTranslation } from '@/lib/translations';
import { getSupabase } from '@/lib/supabase';
import type { ScheduleProject, ScheduleProjectStatus, ScheduleTask } from '@/lib/types/scheduling';

const STATUS_CONFIG: Record<ScheduleProjectStatus, { labelKey: string; color: string; bg: string; icon: typeof Clock }> = {
  draft: { labelKey: 'scheduling.statusDraft', color: 'text-secondary', bg: 'bg-surface-alt', icon: Clock },
  active: { labelKey: 'scheduling.statusActive', color: 'text-success', bg: 'bg-success/10', icon: Activity },
  on_hold: { labelKey: 'scheduling.statusOnHold', color: 'text-warning', bg: 'bg-warning/10', icon: PauseCircle },
  complete: { labelKey: 'scheduling.statusComplete', color: 'text-info', bg: 'bg-info/10', icon: CheckCircle2 },
  archived: { labelKey: 'scheduling.statusArchived', color: 'text-secondary', bg: 'bg-surface-alt', icon: Archive },
};

export default function SchedulingPage() {
  const router = useRouter();
  const { t, formatDate } = useTranslation();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [showNewModal, setShowNewModal] = useState(false);
  const [newName, setNewName] = useState('');
  const [creating, setCreating] = useState(false);
  const [activeTab, setActiveTab] = useState<'projects' | 'dispatch'>('projects');
  const [todayTasks, setTodayTasks] = useState<ScheduleTask[]>([]);
  const [loadingDispatch, setLoadingDispatch] = useState(false);
  const { projects, loading, createProject } = useScheduleProjects();

  // Load today's tasks for dispatch view
  useEffect(() => {
    if (activeTab !== 'dispatch') return;
    const loadTodayTasks = async () => {
      setLoadingDispatch(true);
      try {
        const supabase = getSupabase();
        const today = new Date().toISOString().slice(0, 10);
        const { data } = await supabase
          .from('schedule_tasks')
          .select('*')
          .is('deleted_at', null)
          .lte('planned_start', today)
          .gte('planned_finish', today)
          .lt('percent_complete', 100)
          .order('planned_start', { ascending: true });
        setTodayTasks(data || []);
      } catch {
        // silent
      } finally {
        setLoadingDispatch(false);
      }
    };
    loadTodayTasks();
  }, [activeTab]);

  // Group today's tasks by assigned_to for dispatch
  const dispatchGroups = useMemo(() => {
    const groups: Record<string, ScheduleTask[]> = { unassigned: [] };
    for (const task of todayTasks) {
      const key = task.assigned_to || 'unassigned';
      if (!groups[key]) groups[key] = [];
      groups[key].push(task);
    }
    return groups;
  }, [todayTasks]);

  const filtered = projects.filter((p) => {
    const matchesSearch = !search || p.name.toLowerCase().includes(search.toLowerCase()) ||
      p.description?.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || p.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const stats = {
    total: projects.length,
    active: projects.filter(p => p.status === 'active').length,
    onTrack: projects.filter(p => p.status === 'active' && p.overall_percent_complete >= 0).length,
    complete: projects.filter(p => p.status === 'complete').length,
  };

  // Schedule vs actual — count projects behind/ahead/on-track
  const varianceStats = useMemo(() => {
    let behind = 0, ahead = 0, onTrack = 0;
    for (const p of projects.filter(p => p.status === 'active')) {
      if (p.planned_finish && p.actual_finish) {
        const diff = new Date(p.actual_finish).getTime() - new Date(p.planned_finish).getTime();
        if (diff > 86400000) behind++;
        else if (diff < -86400000) ahead++;
        else onTrack++;
      } else if (p.planned_finish) {
        // Still in progress — compare planned finish to today
        const diff = new Date().getTime() - new Date(p.planned_finish).getTime();
        if (diff > 86400000) behind++;
        else onTrack++;
      } else {
        onTrack++;
      }
    }
    return { behind, ahead, onTrack };
  }, [projects]);

  const handleCreate = async () => {
    if (!newName.trim() || creating) return;
    setCreating(true);
    try {
      const id = await createProject({
        name: newName.trim(),
        planned_start: new Date().toISOString().slice(0, 10),
      });
      setShowNewModal(false);
      setNewName('');
      router.push(`/dashboard/scheduling/${id}`);
    } catch {
      // Error handled by hook
    } finally {
      setCreating(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-32 mb-2" /><div className="skeleton h-4 w-48" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-primary">{t('scheduling.title')}</h1>
          <p className="text-sm text-secondary mt-1">{t('scheduling.manageDesc')}</p>
        </div>
        <div className="flex items-center gap-2">
          {projects.length >= 2 && (
            <button
              onClick={() => router.push('/dashboard/scheduling/portfolio')}
              className="flex items-center gap-2 px-4 py-2 bg-surface border border-main rounded-lg hover:border-accent/30 text-sm font-medium text-secondary hover:text-primary transition-colors"
            >
              <LayoutDashboard className="w-4 h-4" />
              {t('scheduling.portfolio')}
            </button>
          )}
          <button
            onClick={() => setShowNewModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-accent text-on-accent rounded-lg hover:bg-accent/90 text-sm font-medium transition-colors"
          >
            <Plus className="w-4 h-4" />
            {t('scheduling.newSchedule')}
          </button>
        </div>
      </div>

      {/* Tabs: Projects | Today's Dispatch */}
      <div className="flex gap-1 bg-surface border border-main rounded-lg p-1 w-fit">
        <button
          onClick={() => setActiveTab('projects')}
          className={`flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors ${
            activeTab === 'projects' ? 'bg-accent text-on-accent' : 'text-secondary hover:text-primary'
          }`}
        >
          <GanttChart className="w-4 h-4" />
          {t('scheduling.schedules')}
        </button>
        <button
          onClick={() => setActiveTab('dispatch')}
          className={`flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors ${
            activeTab === 'dispatch' ? 'bg-accent text-on-accent' : 'text-secondary hover:text-primary'
          }`}
        >
          <ClipboardList className="w-4 h-4" />
          {t('scheduling.todaysDispatch')}
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <StatCard label={t('scheduling.totalSchedules')} value={stats.total} />
        <StatCard label={t('common.active')} value={stats.active} color="text-success" />
        <StatCard label={t('scheduling.onTrack')} value={varianceStats.onTrack} color="text-info" />
        <StatCard label={t('common.completed')} value={stats.complete} color="text-accent" />
      </div>

      {/* Behind Schedule Alert */}
      {varianceStats.behind > 0 && activeTab === 'projects' && (
        <div className="flex items-center gap-3 px-4 py-3 bg-amber-500/10 border border-amber-500/20 rounded-lg">
          <AlertTriangle className="w-4 h-4 text-warning flex-shrink-0" />
          <p className="text-sm text-primary">
            <span className="font-medium">{varianceStats.behind > 1 ? t('scheduling.projectsBehindSchedule', { count: varianceStats.behind }) : t('scheduling.projectBehindSchedule', { count: varianceStats.behind })}</span>{' '}
            {t('scheduling.reviewAndAdjust')}
          </p>
        </div>
      )}

      {activeTab === 'projects' && (
        <>
          {/* Filters */}
          <div className="flex items-center gap-3">
            <div className="relative flex-1 max-w-sm">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-secondary" />
              <input
                type="text"
                placeholder={t('scheduling.searchSchedules')}
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-surface border border-main rounded-lg text-sm text-primary placeholder:text-quaternary focus:outline-none focus:border-accent"
              />
            </div>
            <div className="flex gap-1 bg-surface border border-main rounded-lg p-1">
              {['all', 'active', 'draft', 'on_hold', 'complete'].map((s) => (
                <button
                  key={s}
                  onClick={() => setStatusFilter(s)}
                  className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
                    statusFilter === s ? 'bg-accent text-on-accent' : 'text-secondary hover:text-primary'
                  }`}
                >
                  {s === 'all' ? t('scheduling.filterAll') : t(`scheduling.status${s === 'on_hold' ? 'OnHold' : s.charAt(0).toUpperCase() + s.slice(1)}`)}
                </button>
              ))}
            </div>
          </div>

          {/* Projects List */}
          {filtered.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-center">
              <div className="w-16 h-16 rounded-full bg-surface-alt flex items-center justify-center mb-4">
                <GanttChart className="w-8 h-8 text-secondary" />
              </div>
              <h3 className="text-lg font-semibold text-primary mb-1">{t('scheduling.noSchedules')}</h3>
              <p className="text-sm text-secondary mb-4">{t('scheduling.noSchedulesDesc')}</p>
              <button
                onClick={() => setShowNewModal(true)}
                className="flex items-center gap-2 px-4 py-2 bg-accent text-on-accent rounded-lg text-sm font-medium"
              >
                <Plus className="w-4 h-4" />
                {t('scheduling.newSchedule')}
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
              {filtered.map((project) => (
                <ProjectCard
                  key={project.id}
                  project={project}
                  onClick={() => router.push(`/dashboard/scheduling/${project.id}`)}
                />
              ))}
            </div>
          )}
        </>
      )}

      {/* Daily Dispatch View */}
      {activeTab === 'dispatch' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-primary">
              {t('scheduling.todaysDispatch')} — {formatDate(new Date(), { weekday: 'long', month: 'long', day: 'numeric' })}
            </h2>
            <span className="text-sm text-secondary">{todayTasks.length !== 1 ? t('scheduling.tasksScheduled', { count: todayTasks.length }) : t('scheduling.taskScheduled', { count: todayTasks.length })}</span>
          </div>

          {loadingDispatch ? (
            <div className="space-y-3">
              {[...Array(3)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-4 w-32 mb-2" /><div className="skeleton h-3 w-48" /></div>)}
            </div>
          ) : todayTasks.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-center">
              <div className="w-16 h-16 rounded-full bg-surface-alt flex items-center justify-center mb-4">
                <ClipboardList className="w-8 h-8 text-secondary" />
              </div>
              <h3 className="text-lg font-semibold text-primary mb-1">{t('scheduling.noTasksToday')}</h3>
              <p className="text-sm text-secondary">{t('scheduling.noTasksTodayDesc')}</p>
            </div>
          ) : (
            <div className="space-y-4">
              {Object.entries(dispatchGroups).map(([userId, tasks]) => (
                <div key={userId} className="bg-surface border border-main rounded-xl overflow-hidden">
                  <div className="px-5 py-3 bg-surface-alt border-b border-main flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-accent/10 flex items-center justify-center">
                      <Users className="w-4 h-4 text-accent" />
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-primary">
                        {userId === 'unassigned' ? t('scheduling.unassigned') : t('scheduling.teamMember')}
                      </p>
                      <p className="text-xs text-secondary">{tasks.length} {tasks.length !== 1 ? t('scheduling.tasks') : t('scheduling.task')}</p>
                    </div>
                  </div>
                  <div className="divide-y divide-main">
                    {tasks.map((task) => (
                      <div key={task.id} className="px-5 py-3 hover:bg-surface-alt/50 transition-colors">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-3">
                            {task.task_type === 'milestone' ? (
                              <Diamond className="w-4 h-4 text-warning flex-shrink-0" />
                            ) : (
                              <Activity className="w-4 h-4 text-accent flex-shrink-0" />
                            )}
                            <div>
                              <p className="text-sm font-medium text-primary">{task.name}</p>
                              {task.notes && <p className="text-xs text-secondary mt-0.5 line-clamp-1">{task.notes}</p>}
                            </div>
                          </div>
                          <div className="flex items-center gap-3">
                            <div className="text-right">
                              <p className="text-xs text-secondary">
                                {task.planned_start?.slice(5, 10)} → {task.planned_finish?.slice(5, 10)}
                              </p>
                              <div className="flex items-center gap-1 mt-0.5">
                                <div className="w-16 h-1.5 bg-surface-alt rounded-full overflow-hidden">
                                  <div className="h-full bg-accent rounded-full" style={{ width: `${task.percent_complete}%` }} />
                                </div>
                                <span className="text-xs text-secondary">{task.percent_complete}%</span>
                              </div>
                            </div>
                            {task.is_critical && (
                              <span className="px-1.5 py-0.5 text-[10px] font-medium rounded bg-red-500/10 text-red-500">{t('scheduling.critical')}</span>
                            )}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* New Schedule Modal */}
      {showNewModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => setShowNewModal(false)}>
          <div className="bg-surface border border-main rounded-xl p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-lg font-semibold text-primary mb-4">{t('scheduling.newSchedule')}</h2>
            <input
              type="text"
              placeholder={t('scheduling.scheduleName')}
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleCreate()}
              autoFocus
              className="w-full px-4 py-2.5 bg-base border border-main rounded-lg text-sm text-primary placeholder:text-quaternary focus:outline-none focus:border-accent mb-4"
            />
            <div className="flex justify-end gap-3">
              <button onClick={() => setShowNewModal(false)} className="px-4 py-2 text-sm text-secondary hover:text-primary">{t('common.cancel')}</button>
              <button
                onClick={handleCreate}
                disabled={!newName.trim() || creating}
                className="px-4 py-2 bg-accent text-on-accent rounded-lg text-sm font-medium disabled:opacity-50"
              >
                {creating ? t('scheduling.creating') : t('scheduling.create')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function StatCard({ label, value, color }: { label: string; value: number; color?: string }) {
  return (
    <div className="bg-surface border border-main rounded-xl p-5">
      <p className="text-xs text-secondary mb-1">{label}</p>
      <p className={`text-2xl font-bold ${color || 'text-primary'}`}>{value}</p>
    </div>
  );
}

function ProjectCard({ project, onClick }: { project: ScheduleProject; onClick: () => void }) {
  const { t } = useTranslation();
  const config = STATUS_CONFIG[project.status];
  const StatusIcon = config.icon;

  return (
    <div
      onClick={onClick}
      className="bg-surface border border-main rounded-xl p-5 hover:border-accent/30 cursor-pointer transition-colors group"
    >
      <div className="flex items-start justify-between mb-3">
        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium ${config.bg} ${config.color}`}>
          <StatusIcon className="w-3 h-3" />
          {t(config.labelKey)}
        </span>
        {project.overall_percent_complete > 0 && (
          <span className="text-sm font-semibold text-accent">{project.overall_percent_complete.toFixed(0)}%</span>
        )}
      </div>

      <h3 className="text-base font-semibold text-primary group-hover:text-accent transition-colors mb-1">
        {project.name}
      </h3>

      {project.description && (
        <p className="text-sm text-secondary line-clamp-2 mb-3">{project.description}</p>
      )}

      <div className="flex items-center gap-3 text-xs text-tertiary">
        {project.planned_start && (
          <span className="flex items-center gap-1">
            <CalendarRange className="w-3 h-3" />
            {project.planned_start.slice(5, 10)}
            {project.planned_finish && ` → ${project.planned_finish.slice(5, 10)}`}
          </span>
        )}
        {project.actual_start && (
          <span className="flex items-center gap-1 text-success">
            <Activity className="w-3 h-3" />
            {t('scheduling.started')} {project.actual_start.slice(5, 10)}
          </span>
        )}
      </div>

      {/* Schedule Variance */}
      {project.status === 'active' && project.planned_finish && (
        (() => {
          const today = new Date();
          const planned = new Date(project.planned_finish);
          const diffDays = Math.round((today.getTime() - planned.getTime()) / 86400000);
          if (diffDays > 1) {
            return (
              <div className="mt-2 flex items-center gap-1.5 text-xs text-warning">
                <AlertTriangle className="w-3 h-3" />
                {diffDays > 1 ? t('scheduling.daysBehindSchedule', { count: diffDays }) : t('scheduling.dayBehindSchedule', { count: diffDays })}
              </div>
            );
          }
          if (diffDays < -7) {
            return (
              <div className="mt-2 flex items-center gap-1.5 text-xs text-success">
                <TrendingUp className="w-3 h-3" />
                {Math.abs(diffDays) > 1 ? t('scheduling.daysAhead', { count: Math.abs(diffDays) }) : t('scheduling.dayAhead', { count: Math.abs(diffDays) })}
              </div>
            );
          }
          return null;
        })()
      )}

      {project.overall_percent_complete > 0 && (
        <div className="mt-3 h-1.5 bg-surface-alt rounded-full overflow-hidden">
          <div
            className={`h-full rounded-full transition-all ${
              project.status === 'complete' ? 'bg-success' : 'bg-accent'
            }`}
            style={{ width: `${Math.min(project.overall_percent_complete, 100)}%` }}
          />
        </div>
      )}
    </div>
  );
}
