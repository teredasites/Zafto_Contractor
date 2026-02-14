'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { ArrowLeft, CheckCircle2, Flag, AlertTriangle } from 'lucide-react';
import { useTeamProjectTasks } from '@/lib/hooks/use-team-schedule';

export default function TeamProjectGanttPage() {
  const params = useParams();
  const router = useRouter();
  const projectId = params.id as string;

  const { tasks, loading, updateProgress } = useTeamProjectTasks(projectId);
  const [editingTask, setEditingTask] = useState<string | null>(null);
  const [tempProgress, setTempProgress] = useState(0);
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!editingTask || saving) return;
    setSaving(true);
    try {
      await updateProgress(editingTask, tempProgress);
      setEditingTask(null);
    } catch {
      // Error handled
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-2 rounded-full" style={{ borderColor: 'var(--accent)', borderTopColor: 'transparent' }} />
      </div>
    );
  }

  return (
    <div className="space-y-4 p-4 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button onClick={() => router.back()} className="p-1.5 rounded-md hover:opacity-80">
          <ArrowLeft className="w-4 h-4" style={{ color: 'var(--text-muted)' }} />
        </button>
        <div>
          <h1 className="text-lg font-semibold" style={{ color: 'var(--text)' }}>Schedule Tasks</h1>
          <p className="text-xs" style={{ color: 'var(--text-muted)' }}>{tasks.length} tasks | Tap to update progress</p>
        </div>
      </div>

      {/* Task list */}
      {tasks.length === 0 ? (
        <div className="text-center py-12">
          <p className="text-sm" style={{ color: 'var(--text-muted)' }}>No tasks in this schedule</p>
        </div>
      ) : (
        <div className="space-y-2">
          {tasks.map((task) => {
            const isMilestone = task.task_type === 'milestone';
            const isEditing = editingTask === task.id;
            const start = task.early_start || task.planned_start;
            const finish = task.early_finish || task.planned_finish;

            return (
              <div key={task.id}>
                <button
                  onClick={() => {
                    if (isEditing) {
                      setEditingTask(null);
                    } else {
                      setEditingTask(task.id);
                      setTempProgress(task.percent_complete);
                    }
                  }}
                  className="w-full text-left rounded-xl p-4 transition-colors"
                  style={{
                    background: 'var(--bg-surface)',
                    border: `1px solid ${isEditing ? 'var(--accent)' : 'var(--border)'}`,
                  }}
                >
                  <div className="flex items-start gap-3">
                    <div className="mt-0.5">
                      {isMilestone ? (
                        <Flag className="w-4 h-4" style={{ color: 'var(--accent)' }} />
                      ) : task.percent_complete >= 100 ? (
                        <CheckCircle2 className="w-4 h-4" style={{ color: 'var(--success, #22c55e)' }} />
                      ) : task.is_critical ? (
                        <AlertTriangle className="w-4 h-4" style={{ color: 'var(--error, #ef4444)' }} />
                      ) : (
                        <div
                          className="w-4 h-4 rounded-full border-2"
                          style={{ borderColor: 'var(--border)' }}
                        />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium truncate" style={{ color: 'var(--text)' }}>
                        {task.name}
                      </p>
                      <div className="flex items-center gap-3 mt-1 text-xs" style={{ color: 'var(--text-muted)' }}>
                        {start && (
                          <span>{new Date(start).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}</span>
                        )}
                        {start && finish && <span>-</span>}
                        {finish && (
                          <span>{new Date(finish).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}</span>
                        )}
                        {task.original_duration && <span>{task.original_duration}d</span>}
                        {task.is_critical && (
                          <span style={{ color: 'var(--error, #ef4444)' }} className="font-medium">Critical</span>
                        )}
                      </div>
                      {/* Progress bar */}
                      <div className="mt-2 flex items-center gap-2">
                        <div className="flex-1 h-1.5 rounded-full" style={{ background: 'var(--border)' }}>
                          <div
                            className="h-full rounded-full"
                            style={{
                              width: `${task.percent_complete}%`,
                              background: task.percent_complete >= 100 ? 'var(--success, #22c55e)' : 'var(--accent)',
                            }}
                          />
                        </div>
                        <span className="text-xs font-medium w-8 text-right" style={{ color: 'var(--text-muted)' }}>
                          {task.percent_complete}%
                        </span>
                      </div>
                    </div>
                  </div>
                </button>

                {/* Progress editor */}
                {isEditing && (
                  <div
                    className="mt-1 rounded-xl p-4"
                    style={{ background: 'var(--bg-surface)', border: '1px solid var(--accent)' }}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-medium" style={{ color: 'var(--text-muted)' }}>
                        Update Progress
                      </span>
                      <span className="text-sm font-bold" style={{ color: 'var(--accent)' }}>
                        {tempProgress}%
                      </span>
                    </div>
                    <input
                      type="range"
                      min={0}
                      max={100}
                      step={5}
                      value={tempProgress}
                      onChange={(e) => setTempProgress(parseInt(e.target.value))}
                      className="w-full mb-3 accent-[var(--accent)]"
                      style={{ accentColor: 'var(--accent)' }}
                    />
                    <div className="flex gap-2">
                      <button
                        onClick={() => setEditingTask(null)}
                        className="flex-1 py-2 rounded-lg text-xs font-medium"
                        style={{ background: 'var(--border)', color: 'var(--text-muted)' }}
                      >
                        Cancel
                      </button>
                      <button
                        onClick={handleSave}
                        disabled={saving}
                        className="flex-1 py-2 rounded-lg text-xs font-medium"
                        style={{ background: 'var(--accent)', color: '#fff', opacity: saving ? 0.5 : 1 }}
                      >
                        {saving ? 'Saving...' : 'Save'}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
