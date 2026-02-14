'use client';

import { useParams, useRouter } from 'next/navigation';
import { ArrowLeft, CheckCircle2, Clock, AlertTriangle, Flag, TrendingUp, TrendingDown } from 'lucide-react';
import { useClientTimeline } from '@/lib/hooks/use-client-timeline';

export default function ClientTimelinePage() {
  const params = useParams();
  const router = useRouter();
  const projectId = params.id as string;

  const { timeline, loading, error } = useClientTimeline(projectId);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-2 rounded-full" style={{ borderColor: 'var(--accent)', borderTopColor: 'transparent' }} />
      </div>
    );
  }

  if (error || !timeline) {
    return (
      <div className="text-center py-20 px-4">
        <AlertTriangle className="w-10 h-10 mx-auto mb-3" style={{ color: 'var(--text-muted)' }} />
        <p className="text-sm" style={{ color: 'var(--text-muted)' }}>{error || 'Timeline not available'}</p>
      </div>
    );
  }

  const statusConfig = {
    on_schedule: { label: 'On Schedule', color: 'var(--success, #22c55e)', icon: CheckCircle2 },
    ahead: { label: 'Ahead of Schedule', color: 'var(--info, #3b82f6)', icon: TrendingUp },
    behind: { label: 'Behind Schedule', color: 'var(--error, #ef4444)', icon: TrendingDown },
  };

  const status = statusConfig[timeline.schedule_status];
  const StatusIcon = status.icon;

  const completedCount = timeline.milestones.filter(m => m.status === 'completed').length;
  const overdueCount = timeline.milestones.filter(m => m.status === 'overdue').length;

  return (
    <div className="space-y-6 p-4 pb-8 animate-fade-in max-w-lg mx-auto">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button onClick={() => router.back()} className="p-1.5 rounded-md hover:opacity-80">
          <ArrowLeft className="w-4 h-4" style={{ color: 'var(--text-muted)' }} />
        </button>
        <div>
          <h1 className="text-lg font-semibold" style={{ color: 'var(--text)' }}>Project Timeline</h1>
          <p className="text-xs" style={{ color: 'var(--text-muted)' }}>{timeline.project_name}</p>
        </div>
      </div>

      {/* Status badge */}
      <div
        className="flex items-center gap-3 p-4 rounded-xl"
        style={{ background: `${status.color}10`, border: `1px solid ${status.color}30` }}
      >
        <StatusIcon className="w-5 h-5 flex-shrink-0" style={{ color: status.color }} />
        <div>
          <p className="text-sm font-semibold" style={{ color: status.color }}>{status.label}</p>
          {timeline.schedule_status === 'behind' && timeline.delay_days > 0 && (
            <p className="text-xs mt-0.5" style={{ color: 'var(--text-muted)' }}>
              Approximately {timeline.delay_days} day{timeline.delay_days !== 1 ? 's' : ''} behind the original schedule
            </p>
          )}
          {timeline.schedule_status === 'ahead' && Math.abs(timeline.delay_days) > 0 && (
            <p className="text-xs mt-0.5" style={{ color: 'var(--text-muted)' }}>
              About {Math.abs(timeline.delay_days)} day{Math.abs(timeline.delay_days) !== 1 ? 's' : ''} ahead
            </p>
          )}
        </div>
      </div>

      {/* Overall progress */}
      <div className="rounded-xl p-4" style={{ background: 'var(--bg-surface, var(--surface))', border: '1px solid var(--border)' }}>
        <div className="flex justify-between items-center mb-2">
          <span className="text-sm font-medium" style={{ color: 'var(--text)' }}>Overall Progress</span>
          <span className="text-lg font-bold" style={{ color: 'var(--accent)' }}>{timeline.overall_progress}%</span>
        </div>
        <div className="w-full h-3 rounded-full" style={{ background: 'var(--border)' }}>
          <div
            className="h-full rounded-full transition-all"
            style={{ width: `${timeline.overall_progress}%`, background: 'var(--accent)' }}
          />
        </div>
        <div className="flex justify-between mt-2 text-xs" style={{ color: 'var(--text-muted)' }}>
          {timeline.planned_start && (
            <span>Start: {new Date(timeline.planned_start).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}</span>
          )}
          {timeline.planned_finish && (
            <span>Est. Finish: {new Date(timeline.planned_finish).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}</span>
          )}
        </div>
      </div>

      {/* Current phase */}
      {timeline.current_phase && (
        <div className="flex items-center gap-2 px-4 py-3 rounded-xl" style={{ background: 'var(--bg-surface, var(--surface))', border: '1px solid var(--border)' }}>
          <Flag className="w-4 h-4" style={{ color: 'var(--accent)' }} />
          <div>
            <p className="text-xs" style={{ color: 'var(--text-muted)' }}>Current Phase</p>
            <p className="text-sm font-semibold" style={{ color: 'var(--text)' }}>{timeline.current_phase}</p>
          </div>
        </div>
      )}

      {/* Milestone summary */}
      <div className="grid grid-cols-3 gap-3">
        <div className="text-center rounded-xl p-3" style={{ background: 'var(--bg-surface, var(--surface))', border: '1px solid var(--border)' }}>
          <p className="text-lg font-bold" style={{ color: 'var(--text)' }}>{timeline.milestones.length}</p>
          <p className="text-[10px]" style={{ color: 'var(--text-muted)' }}>Total</p>
        </div>
        <div className="text-center rounded-xl p-3" style={{ background: 'var(--bg-surface, var(--surface))', border: '1px solid var(--border)' }}>
          <p className="text-lg font-bold" style={{ color: 'var(--success, #22c55e)' }}>{completedCount}</p>
          <p className="text-[10px]" style={{ color: 'var(--text-muted)' }}>Completed</p>
        </div>
        <div className="text-center rounded-xl p-3" style={{ background: 'var(--bg-surface, var(--surface))', border: '1px solid var(--border)' }}>
          <p className="text-lg font-bold" style={{ color: overdueCount > 0 ? 'var(--error, #ef4444)' : 'var(--text)' }}>{overdueCount}</p>
          <p className="text-[10px]" style={{ color: 'var(--text-muted)' }}>Overdue</p>
        </div>
      </div>

      {/* Milestone timeline */}
      <div>
        <h2 className="text-sm font-semibold mb-3" style={{ color: 'var(--text)' }}>Milestones</h2>
        {timeline.milestones.length === 0 ? (
          <p className="text-xs text-center py-8" style={{ color: 'var(--text-muted)' }}>No milestones defined</p>
        ) : (
          <div className="relative">
            {/* Vertical line */}
            <div
              className="absolute left-[15px] top-2 bottom-2 w-0.5"
              style={{ background: 'var(--border)' }}
            />

            <div className="space-y-4">
              {timeline.milestones.map((milestone) => {
                const isCompleted = milestone.status === 'completed';
                const isOverdue = milestone.status === 'overdue';

                return (
                  <div key={milestone.id} className="relative flex items-start gap-3 pl-0">
                    {/* Dot */}
                    <div className="relative z-10 flex-shrink-0">
                      {isCompleted ? (
                        <CheckCircle2 className="w-[30px] h-[30px]" style={{ color: 'var(--success, #22c55e)' }} />
                      ) : isOverdue ? (
                        <AlertTriangle className="w-[30px] h-[30px]" style={{ color: 'var(--error, #ef4444)' }} />
                      ) : (
                        <Clock className="w-[30px] h-[30px]" style={{ color: 'var(--text-muted)' }} />
                      )}
                    </div>

                    <div className="flex-1 min-w-0 pt-1">
                      <p className="text-sm font-medium" style={{
                        color: isCompleted ? 'var(--text-muted)' : 'var(--text)',
                        textDecoration: isCompleted ? 'line-through' : 'none',
                      }}>
                        {milestone.name}
                      </p>
                      <div className="flex items-center gap-2 mt-0.5">
                        {milestone.planned_date && (
                          <span className="text-xs" style={{ color: isOverdue ? 'var(--error, #ef4444)' : 'var(--text-muted)' }}>
                            {new Date(milestone.planned_date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                          </span>
                        )}
                        {isOverdue && (
                          <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded" style={{ background: '#ef444410', color: 'var(--error, #ef4444)' }}>
                            Overdue
                          </span>
                        )}
                        {isCompleted && (
                          <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded" style={{ background: '#22c55e10', color: 'var(--success, #22c55e)' }}>
                            Done
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
