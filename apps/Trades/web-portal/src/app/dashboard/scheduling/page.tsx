'use client';

import { useState } from 'react';
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
} from 'lucide-react';
import { useScheduleProjects } from '@/lib/hooks/use-schedule';
import type { ScheduleProject, ScheduleProjectStatus } from '@/lib/types/scheduling';

const STATUS_CONFIG: Record<ScheduleProjectStatus, { label: string; color: string; bg: string; icon: typeof Clock }> = {
  draft: { label: 'Draft', color: 'text-secondary', bg: 'bg-surface-alt', icon: Clock },
  active: { label: 'Active', color: 'text-success', bg: 'bg-success/10', icon: Activity },
  on_hold: { label: 'On Hold', color: 'text-warning', bg: 'bg-warning/10', icon: PauseCircle },
  complete: { label: 'Complete', color: 'text-info', bg: 'bg-info/10', icon: CheckCircle2 },
  archived: { label: 'Archived', color: 'text-secondary', bg: 'bg-surface-alt', icon: Archive },
};

export default function SchedulingPage() {
  const router = useRouter();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [showNewModal, setShowNewModal] = useState(false);
  const [newName, setNewName] = useState('');
  const [creating, setCreating] = useState(false);
  const { projects, loading, createProject } = useScheduleProjects();

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
          <h1 className="text-xl font-semibold text-primary">Scheduling</h1>
          <p className="text-sm text-secondary mt-1">Gantt charts, CPM, and resource management</p>
        </div>
        <div className="flex items-center gap-2">
          {projects.length >= 2 && (
            <button
              onClick={() => router.push('/dashboard/scheduling/portfolio')}
              className="flex items-center gap-2 px-4 py-2 bg-surface border border-main rounded-lg hover:border-accent/30 text-sm font-medium text-secondary hover:text-primary transition-colors"
            >
              <LayoutDashboard className="w-4 h-4" />
              Portfolio
            </button>
          )}
          <button
            onClick={() => setShowNewModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-accent text-on-accent rounded-lg hover:bg-accent/90 text-sm font-medium transition-colors"
          >
            <Plus className="w-4 h-4" />
            New Schedule
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <StatCard label="Total Schedules" value={stats.total} />
        <StatCard label="Active" value={stats.active} color="text-success" />
        <StatCard label="On Track" value={stats.onTrack} color="text-info" />
        <StatCard label="Completed" value={stats.complete} color="text-accent" />
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-secondary" />
          <input
            type="text"
            placeholder="Search schedules..."
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
              {s === 'all' ? 'All' : s === 'on_hold' ? 'On Hold' : s.charAt(0).toUpperCase() + s.slice(1)}
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
          <h3 className="text-lg font-semibold text-primary mb-1">No schedules yet</h3>
          <p className="text-sm text-secondary mb-4">Create your first project schedule to get started</p>
          <button
            onClick={() => setShowNewModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-accent text-on-accent rounded-lg text-sm font-medium"
          >
            <Plus className="w-4 h-4" />
            New Schedule
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

      {/* New Schedule Modal */}
      {showNewModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => setShowNewModal(false)}>
          <div className="bg-surface border border-main rounded-xl p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-lg font-semibold text-primary mb-4">New Schedule</h2>
            <input
              type="text"
              placeholder="Schedule name"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleCreate()}
              autoFocus
              className="w-full px-4 py-2.5 bg-base border border-main rounded-lg text-sm text-primary placeholder:text-quaternary focus:outline-none focus:border-accent mb-4"
            />
            <div className="flex justify-end gap-3">
              <button onClick={() => setShowNewModal(false)} className="px-4 py-2 text-sm text-secondary hover:text-primary">Cancel</button>
              <button
                onClick={handleCreate}
                disabled={!newName.trim() || creating}
                className="px-4 py-2 bg-accent text-on-accent rounded-lg text-sm font-medium disabled:opacity-50"
              >
                {creating ? 'Creating...' : 'Create'}
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
          {config.label}
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
      </div>

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
