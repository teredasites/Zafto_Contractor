'use client';

import Link from 'next/link';
import { Calendar, ChevronRight, CheckCircle2, Clock, AlertTriangle } from 'lucide-react';
import { useTeamSchedule } from '@/lib/hooks/use-team-schedule';

export default function ProjectScheduleListPage() {
  const { projects, loading } = useTeamSchedule();

  if (loading) {
    return (
      <div className="space-y-4 animate-fade-in p-4">
        {[1, 2, 3].map((i) => (
          <div key={i} className="skeleton h-28 w-full rounded-xl" />
        ))}
      </div>
    );
  }

  if (projects.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-center px-4">
        <div className="w-16 h-16 rounded-full bg-[var(--bg-surface)] flex items-center justify-center mb-4">
          <Calendar className="w-8 h-8" style={{ color: 'var(--text-muted)' }} />
        </div>
        <h3 className="text-lg font-semibold mb-1" style={{ color: 'var(--text)' }}>No project schedules</h3>
        <p className="text-sm" style={{ color: 'var(--text-muted)' }}>
          You&apos;ll see schedules here when you&apos;re assigned to project tasks
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4 p-4 animate-fade-in">
      <h1 className="text-xl font-semibold" style={{ color: 'var(--text)' }}>Project Schedules</h1>

      {projects.map((project) => {
        const progressPct = project.overall_progress;
        const isOverdue = project.next_deadline && project.next_deadline < new Date().toISOString().slice(0, 10);

        return (
          <Link key={project.id} href={`/dashboard/schedule/project/${project.id}`}>
            <div
              className="rounded-xl p-4 transition-colors hover:opacity-90"
              style={{ background: 'var(--bg-surface)', border: '1px solid var(--border)' }}
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex-1 min-w-0">
                  <h3 className="text-sm font-semibold truncate" style={{ color: 'var(--text)' }}>
                    {project.name}
                  </h3>
                  <p className="text-xs mt-0.5" style={{ color: 'var(--text-muted)' }}>
                    {project.my_tasks} assigned tasks | {project.total_tasks} total
                  </p>
                </div>
                <ChevronRight className="w-4 h-4 flex-shrink-0 mt-0.5" style={{ color: 'var(--text-muted)' }} />
              </div>

              {/* Progress bar */}
              <div className="mb-3">
                <div className="flex justify-between items-center mb-1">
                  <span className="text-xs font-medium" style={{ color: 'var(--text-muted)' }}>
                    Overall Progress
                  </span>
                  <span className="text-xs font-bold" style={{ color: 'var(--accent)' }}>
                    {progressPct}%
                  </span>
                </div>
                <div className="w-full h-2 rounded-full" style={{ background: 'var(--border)' }}>
                  <div
                    className="h-full rounded-full transition-all"
                    style={{ width: `${progressPct}%`, background: 'var(--accent)' }}
                  />
                </div>
              </div>

              {/* Footer stats */}
              <div className="flex items-center gap-4 text-xs" style={{ color: 'var(--text-muted)' }}>
                <span className="flex items-center gap-1">
                  <CheckCircle2 className="w-3 h-3" style={{ color: 'var(--success, #22c55e)' }} />
                  {project.my_completed}/{project.my_tasks} done
                </span>
                {project.next_deadline && (
                  <span className="flex items-center gap-1">
                    {isOverdue ? (
                      <AlertTriangle className="w-3 h-3" style={{ color: 'var(--error, #ef4444)' }} />
                    ) : (
                      <Clock className="w-3 h-3" />
                    )}
                    Next: {new Date(project.next_deadline).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                  </span>
                )}
              </div>
            </div>
          </Link>
        );
      })}
    </div>
  );
}
