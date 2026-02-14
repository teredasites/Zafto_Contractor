'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  ArrowLeft,
  CheckCircle2,
  AlertTriangle,
  Clock,
  Flag,
  Users,
  ChevronRight,
  AlertCircle,
} from 'lucide-react';
import { useSchedulePortfolio } from '@/lib/hooks/use-schedule-portfolio';

const HEALTH_CONFIG = {
  on_track: { label: 'On Track', color: 'text-success', bg: 'bg-success/10', border: 'border-success/20' },
  at_risk: { label: 'At Risk', color: 'text-warning', bg: 'bg-warning/10', border: 'border-warning/20' },
  behind: { label: 'Behind', color: 'text-error', bg: 'bg-error/10', border: 'border-error/20' },
};

export default function PortfolioPage() {
  const router = useRouter();
  const { portfolio, loading, error } = useSchedulePortfolio();
  const [filter, setFilter] = useState<string>('all');

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-2 border-accent border-t-transparent rounded-full" />
      </div>
    );
  }

  if (error || !portfolio) {
    return (
      <div className="text-center py-20">
        <AlertCircle className="w-10 h-10 mx-auto mb-3 text-error" />
        <p className="text-sm text-secondary">{error || 'Failed to load portfolio'}</p>
      </div>
    );
  }

  const { projects, milestones, conflicts, resource_utilization, summary } = portfolio;

  const filteredProjects = filter === 'all'
    ? projects
    : projects.filter(p => p.health === filter);

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button onClick={() => router.push('/dashboard/scheduling')} className="p-1.5 hover:bg-surface-alt rounded-md">
          <ArrowLeft className="w-4 h-4 text-secondary" />
        </button>
        <div>
          <h1 className="text-xl font-semibold text-primary">Portfolio View</h1>
          <p className="text-sm text-secondary">{summary.total_projects} active projects</p>
        </div>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
        <div className="bg-surface border border-main rounded-xl p-4 text-center">
          <p className="text-2xl font-bold text-primary">{summary.total_projects}</p>
          <p className="text-[10px] text-tertiary">Total</p>
        </div>
        <div className="bg-success/5 border border-success/20 rounded-xl p-4 text-center">
          <p className="text-2xl font-bold text-success">{summary.on_track}</p>
          <p className="text-[10px] text-tertiary">On Track</p>
        </div>
        <div className="bg-warning/5 border border-warning/20 rounded-xl p-4 text-center">
          <p className="text-2xl font-bold text-warning">{summary.at_risk}</p>
          <p className="text-[10px] text-tertiary">At Risk</p>
        </div>
        <div className="bg-error/5 border border-error/20 rounded-xl p-4 text-center">
          <p className="text-2xl font-bold text-error">{summary.behind}</p>
          <p className="text-[10px] text-tertiary">Behind</p>
        </div>
        <div className="bg-surface border border-main rounded-xl p-4 text-center">
          <p className="text-2xl font-bold text-accent">{summary.upcoming_milestones}</p>
          <p className="text-[10px] text-tertiary">Milestones (2wk)</p>
        </div>
      </div>

      {/* Cross-project conflicts */}
      {conflicts.length > 0 && (
        <div className="bg-error/5 border border-error/20 rounded-xl p-4">
          <div className="flex items-center gap-2 mb-3">
            <AlertTriangle className="w-4 h-4 text-error" />
            <span className="text-sm font-semibold text-primary">{conflicts.length} Cross-Project Conflict{conflicts.length !== 1 ? 's' : ''}</span>
          </div>
          <div className="space-y-2">
            {conflicts.slice(0, 5).map((conflict, i) => (
              <div key={i} className="flex items-start gap-2 text-xs">
                <Users className="w-3.5 h-3.5 text-error flex-shrink-0 mt-0.5" />
                <div>
                  <span className="font-medium text-primary">{conflict.resource_name}</span>
                  <span className="text-secondary"> is double-booked </span>
                  <span className="text-tertiary">
                    {conflict.overlap_start} to {conflict.overlap_end}
                  </span>
                  <div className="mt-0.5 text-tertiary">
                    {conflict.projects.map(p => `${p.project_name}: "${p.task_name}"`).join(' + ')}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Filter chips */}
      <div className="flex gap-1 bg-surface border border-main rounded-lg p-1 w-fit">
        {['all', 'on_track', 'at_risk', 'behind'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
              filter === f ? 'bg-accent text-on-accent' : 'text-secondary hover:text-primary'
            }`}
          >
            {f === 'all' ? 'All' : f === 'on_track' ? 'On Track' : f === 'at_risk' ? 'At Risk' : 'Behind'}
          </button>
        ))}
      </div>

      {/* Project list */}
      <div className="space-y-3">
        {filteredProjects.map((project) => {
          const health = HEALTH_CONFIG[project.health];

          return (
            <button
              key={project.id}
              onClick={() => router.push(`/dashboard/scheduling/${project.id}`)}
              className="w-full bg-surface border border-main rounded-xl p-5 text-left hover:border-accent/30 transition-colors"
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="text-sm font-semibold text-primary truncate">{project.name}</h3>
                    <span className={`px-2 py-0.5 text-[10px] font-semibold rounded ${health.bg} ${health.color}`}>
                      {health.label}
                    </span>
                  </div>
                  <p className="text-xs text-tertiary mt-0.5">
                    {project.planned_start && project.planned_finish
                      ? `${formatDate(project.planned_start)} — ${formatDate(project.planned_finish)}`
                      : 'No dates set'}
                  </p>
                </div>
                <ChevronRight className="w-4 h-4 text-tertiary flex-shrink-0" />
              </div>

              {/* Progress bar */}
              <div className="mb-3">
                <div className="flex justify-between text-xs mb-1">
                  <span className="text-tertiary">{project.total_tasks} tasks</span>
                  <span className="font-medium text-accent">{project.overall_progress}%</span>
                </div>
                <div className="w-full h-2 bg-surface-alt rounded-full">
                  <div
                    className="h-full rounded-full transition-all"
                    style={{
                      width: `${project.overall_progress}%`,
                      backgroundColor: project.health === 'behind' ? 'var(--color-error)' : project.health === 'at_risk' ? 'var(--color-warning)' : 'var(--color-accent)',
                    }}
                  />
                </div>
              </div>

              {/* Stats row */}
              <div className="flex items-center gap-4 text-xs text-tertiary">
                <span className="flex items-center gap-1">
                  <AlertTriangle className="w-3 h-3" />
                  {project.critical_tasks} critical
                </span>
                <span className="flex items-center gap-1">
                  <Flag className="w-3 h-3" />
                  {project.completed_milestones}/{project.milestones} milestones
                </span>
                <span className="flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  Float: {project.min_float}d
                </span>
              </div>
            </button>
          );
        })}
      </div>

      {/* Upcoming milestones */}
      {milestones.length > 0 && (
        <div className="bg-surface border border-main rounded-xl p-5">
          <h2 className="text-sm font-semibold text-primary mb-3 flex items-center gap-2">
            <Flag className="w-4 h-4 text-accent" />
            Upcoming Milestones (Next 2 Weeks)
          </h2>
          <div className="space-y-2">
            {milestones.map((m) => (
              <div key={m.id} className="flex items-center gap-3">
                {m.is_overdue ? (
                  <AlertTriangle className="w-4 h-4 text-error flex-shrink-0" />
                ) : (
                  <CheckCircle2 className="w-4 h-4 text-tertiary flex-shrink-0" />
                )}
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-medium text-primary truncate">{m.name}</p>
                  <p className="text-[10px] text-tertiary">{m.project_name}</p>
                </div>
                <div className="text-right">
                  <p className={`text-xs font-medium ${m.is_overdue ? 'text-error' : 'text-secondary'}`}>
                    {m.planned_date ? formatDate(m.planned_date) : '—'}
                  </p>
                  {m.is_overdue && (
                    <p className="text-[10px] text-error">Overdue</p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Resource utilization */}
      {resource_utilization.length > 0 && (
        <div className="bg-surface border border-main rounded-xl p-5">
          <h2 className="text-sm font-semibold text-primary mb-3 flex items-center gap-2">
            <Users className="w-4 h-4 text-accent" />
            Resource Utilization
          </h2>
          <div className="space-y-2">
            {resource_utilization.slice(0, 10).map((r) => (
              <div key={r.resource_id} className="flex items-center gap-3">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-xs font-medium text-primary truncate">{r.resource_name}</p>
                    {r.is_over_allocated && (
                      <span className="px-1.5 py-0.5 text-[9px] font-semibold bg-warning/10 text-warning rounded">
                        Multi-Project
                      </span>
                    )}
                  </div>
                  <p className="text-[10px] text-tertiary">{r.resource_type} | {r.project_count} project{r.project_count !== 1 ? 's' : ''} | {r.total_assignments} tasks</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function formatDate(d: string): string {
  return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}
