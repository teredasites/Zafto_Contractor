'use client';
import { useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft, Wrench, CheckCircle2, Clock, AlertCircle, Calendar,
  ClipboardCheck, Hammer, Star, Send, DollarSign, User,
} from 'lucide-react';
import { useMaintenanceRequest } from '@/lib/hooks/use-maintenance';
import { formatDate } from '@/lib/hooks/mappers';
import { urgencyLabel, categoryLabel, maintenanceStatusLabel } from '@/lib/hooks/tenant-mappers';

// ==================== STATUS TIMELINE CONFIG ====================

type MaintenanceStatusKey = 'submitted' | 'reviewed' | 'approved' | 'scheduled' | 'in_progress' | 'completed';

const timelineSteps: { status: MaintenanceStatusKey; label: string; icon: typeof Clock }[] = [
  { status: 'submitted', label: 'Submitted', icon: Send },
  { status: 'reviewed', label: 'Under Review', icon: ClipboardCheck },
  { status: 'approved', label: 'Approved', icon: CheckCircle2 },
  { status: 'scheduled', label: 'Scheduled', icon: Calendar },
  { status: 'in_progress', label: 'In Progress', icon: Hammer },
  { status: 'completed', label: 'Completed', icon: CheckCircle2 },
];

const STATUS_ORDER: Record<string, number> = {
  submitted: 0,
  reviewed: 1,
  approved: 2,
  scheduled: 3,
  in_progress: 4,
  completed: 5,
  cancelled: -1,
};

const urgencyBadge: Record<string, { color: string; bg: string }> = {
  routine: { color: 'var(--text-muted)', bg: 'var(--bg-secondary)' },
  urgent: { color: 'var(--warning)', bg: 'color-mix(in srgb, var(--warning) 15%, transparent)' },
  emergency: { color: 'var(--danger)', bg: 'color-mix(in srgb, var(--danger) 15%, transparent)' },
};

const statusBadge: Record<string, { color: string; bg: string }> = {
  submitted: { color: 'var(--accent)', bg: 'var(--accent-light)' },
  reviewed: { color: 'var(--warning)', bg: 'color-mix(in srgb, var(--warning) 15%, transparent)' },
  approved: { color: '#3b82f6', bg: '#eff6ff' },
  scheduled: { color: '#3b82f6', bg: '#eff6ff' },
  in_progress: { color: 'var(--accent)', bg: 'var(--accent-light)' },
  completed: { color: 'var(--success)', bg: 'color-mix(in srgb, var(--success) 15%, transparent)' },
  cancelled: { color: 'var(--text-muted)', bg: 'var(--bg-secondary)' },
};

// ==================== LOADING SKELETON ====================

function DetailSkeleton() {
  return (
    <div className="space-y-5 animate-pulse">
      <div className="rounded-xl border p-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
        <div className="h-5 w-48 rounded" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        <div className="h-3 w-full rounded mt-3" style={{ backgroundColor: 'var(--border-light)' }} />
        <div className="h-3 w-2/3 rounded mt-2" style={{ backgroundColor: 'var(--border-light)' }} />
      </div>
      <div className="rounded-xl border p-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
        <div className="space-y-4">
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="flex gap-3">
              <div className="w-3 h-3 rounded-full" style={{ backgroundColor: 'var(--bg-secondary)' }} />
              <div className="h-4 w-28 rounded" style={{ backgroundColor: 'var(--bg-secondary)' }} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ==================== PAGE ====================

export default function MaintenanceDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { request, actions, loading, submitRating } = useMaintenanceRequest(id);

  // Rating state
  const [rating, setRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);
  const [feedback, setFeedback] = useState('');
  const [ratingSubmitting, setRatingSubmitting] = useState(false);
  const [ratingSubmitted, setRatingSubmitted] = useState(false);

  async function handleRatingSubmit() {
    if (rating === 0) return;
    setRatingSubmitting(true);
    try {
      await submitRating(rating, feedback.trim());
      setRatingSubmitted(true);
    } catch {
      // silently fail
    }
    setRatingSubmitting(false);
  }

  if (loading) {
    return (
      <div className="space-y-5">
        <Link href="/maintenance" className="flex items-center gap-1 text-sm" style={{ color: 'var(--text-muted)' }}>
          <ArrowLeft size={16} /> Back to Maintenance
        </Link>
        <DetailSkeleton />
      </div>
    );
  }

  if (!request) {
    return (
      <div className="space-y-5">
        <Link href="/maintenance" className="flex items-center gap-1 text-sm" style={{ color: 'var(--text-muted)' }}>
          <ArrowLeft size={16} /> Back to Maintenance
        </Link>
        <div className="rounded-xl border p-8 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <AlertCircle size={32} className="mx-auto mb-3" style={{ color: 'var(--text-muted)' }} />
          <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>Request not found</h3>
          <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>This request may have been removed or you don&apos;t have access.</p>
        </div>
      </div>
    );
  }

  const currentIndex = STATUS_ORDER[request.status] ?? 0;
  const isCancelled = request.status === 'cancelled';
  const isCompleted = request.status === 'completed';
  const uBadge = urgencyBadge[request.urgency] || urgencyBadge.routine;
  const sBadge = statusBadge[request.status] || statusBadge.submitted;

  // Build action date map by status for timeline
  const actionDateMap: Record<string, string> = {};
  if (actions.length > 0) {
    for (const action of actions) {
      const type = action.actionType.toLowerCase();
      if (type.includes('submit')) actionDateMap['submitted'] = action.createdAt;
      if (type.includes('review')) actionDateMap['reviewed'] = action.createdAt;
      if (type.includes('approv')) actionDateMap['approved'] = action.createdAt;
      if (type.includes('schedul')) actionDateMap['scheduled'] = action.createdAt;
      if (type.includes('start') || type.includes('in_progress')) actionDateMap['in_progress'] = action.createdAt;
      if (type.includes('complet')) actionDateMap['completed'] = action.createdAt;
    }
  }
  // Always set submitted date from request creation
  if (!actionDateMap['submitted']) actionDateMap['submitted'] = request.createdAt;
  // Set completed date from request if available
  if (request.completedAt && !actionDateMap['completed']) actionDateMap['completed'] = request.completedAt;

  const showRating = isCompleted && !request.tenantRating && !ratingSubmitted;

  return (
    <div className="space-y-5">
      {/* Back Link */}
      <Link href="/maintenance" className="flex items-center gap-1 text-sm hover:opacity-80 transition-opacity" style={{ color: 'var(--text-muted)' }}>
        <ArrowLeft size={16} /> Back to Maintenance
      </Link>

      {/* ==================== REQUEST INFO CARD ==================== */}
      <div className="rounded-xl border p-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
        <div className="flex items-start justify-between gap-3 mb-3">
          <h1 className="text-lg font-bold" style={{ color: 'var(--text)' }}>{request.title}</h1>
          <span
            className="text-[10px] font-medium px-2.5 py-1 rounded-full flex-shrink-0"
            style={{ backgroundColor: sBadge.bg, color: sBadge.color }}
          >
            {maintenanceStatusLabel(request.status)}
          </span>
        </div>

        <p className="text-sm leading-relaxed mb-4" style={{ color: 'var(--text-muted)' }}>
          {request.description}
        </p>

        <div className="flex flex-wrap gap-2 mb-4">
          <span
            className="text-[10px] font-medium px-2.5 py-1 rounded-full flex items-center gap-1"
            style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text)' }}
          >
            <Wrench size={10} /> {categoryLabel(request.category)}
          </span>
          <span
            className="text-[10px] font-medium px-2.5 py-1 rounded-full"
            style={{ backgroundColor: uBadge.bg, color: uBadge.color }}
          >
            {urgencyLabel(request.urgency)}
          </span>
        </div>

        {/* Dates */}
        <div className="space-y-2 border-t pt-3" style={{ borderColor: 'var(--border-light)' }}>
          <div className="flex justify-between text-sm">
            <span style={{ color: 'var(--text-muted)' }}>Submitted</span>
            <span className="font-medium" style={{ color: 'var(--text)' }}>{formatDate(request.createdAt)}</span>
          </div>
          {request.completedAt && (
            <div className="flex justify-between text-sm">
              <span style={{ color: 'var(--text-muted)' }}>Completed</span>
              <span className="font-medium" style={{ color: 'var(--success)' }}>{formatDate(request.completedAt)}</span>
            </div>
          )}
        </div>

        {/* Cost Info */}
        {(request.estimatedCost || request.actualCost) && (
          <div className="space-y-2 border-t pt-3 mt-3" style={{ borderColor: 'var(--border-light)' }}>
            {request.estimatedCost && (
              <div className="flex justify-between text-sm">
                <span className="flex items-center gap-1" style={{ color: 'var(--text-muted)' }}>
                  <DollarSign size={12} /> Estimated Cost
                </span>
                <span className="font-medium" style={{ color: 'var(--text)' }}>
                  ${request.estimatedCost.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                </span>
              </div>
            )}
            {request.actualCost && (
              <div className="flex justify-between text-sm">
                <span className="flex items-center gap-1" style={{ color: 'var(--text-muted)' }}>
                  <DollarSign size={12} /> Actual Cost
                </span>
                <span className="font-bold" style={{ color: 'var(--text)' }}>
                  ${request.actualCost.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                </span>
              </div>
            )}
          </div>
        )}
      </div>

      {/* ==================== STATUS TIMELINE ==================== */}
      {!isCancelled && (
        <div className="rounded-xl border p-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <h3 className="font-bold text-sm mb-4" style={{ color: 'var(--text)' }}>Status Timeline</h3>
          <div className="space-y-0">
            {timelineSteps.map((step, i) => {
              const stepIndex = STATUS_ORDER[step.status];
              const isComplete = currentIndex > stepIndex;
              const isCurrent = currentIndex === stepIndex;
              const isLast = i === timelineSteps.length - 1;
              const dateStr = actionDateMap[step.status];
              const StepIcon = step.icon;

              return (
                <div key={step.status} className="flex gap-3">
                  {/* Dot + Line */}
                  <div className="flex flex-col items-center">
                    <div
                      className="w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0"
                      style={{
                        backgroundColor: isComplete
                          ? 'color-mix(in srgb, var(--success) 15%, transparent)'
                          : isCurrent
                            ? 'var(--accent-light)'
                            : 'var(--bg-secondary)',
                      }}
                    >
                      <StepIcon
                        size={14}
                        style={{
                          color: isComplete
                            ? 'var(--success)'
                            : isCurrent
                              ? 'var(--accent)'
                              : 'var(--text-muted)',
                        }}
                      />
                    </div>
                    {!isLast && (
                      <div
                        className="w-0.5 h-6"
                        style={{
                          backgroundColor: isComplete
                            ? 'color-mix(in srgb, var(--success) 40%, transparent)'
                            : 'var(--border-light)',
                        }}
                      />
                    )}
                  </div>
                  {/* Label */}
                  <div className={`pb-3 ${isLast ? 'pb-0' : ''}`}>
                    <p
                      className="text-sm font-medium"
                      style={{
                        color: isComplete || isCurrent ? 'var(--text)' : 'var(--text-muted)',
                      }}
                    >
                      {step.label}
                      {isCurrent && (
                        <span
                          className="ml-2 text-[10px] font-medium px-2 py-0.5 rounded-full"
                          style={{ backgroundColor: 'var(--accent-light)', color: 'var(--accent)' }}
                        >
                          Current
                        </span>
                      )}
                    </p>
                    {dateStr && (
                      <p className="text-xs mt-0.5" style={{ color: 'var(--text-muted)' }}>{formatDate(dateStr)}</p>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Cancelled Banner */}
      {isCancelled && (
        <div className="rounded-xl border p-5" style={{ backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border-light)' }}>
          <div className="flex items-center gap-2">
            <AlertCircle size={18} style={{ color: 'var(--text-muted)' }} />
            <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>Request Cancelled</h3>
          </div>
          <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>This maintenance request was cancelled.</p>
        </div>
      )}

      {/* ==================== WORK ORDER ACTIONS ==================== */}
      {actions.length > 0 && (
        <div className="rounded-xl border p-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <h3 className="font-bold text-sm mb-4" style={{ color: 'var(--text)' }}>Activity</h3>
          <div className="space-y-3">
            {actions.map(action => (
              <div
                key={action.id}
                className="flex gap-3 p-3 rounded-xl"
                style={{ backgroundColor: 'var(--bg-secondary)' }}
              >
                <div className="w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: 'var(--surface)' }}>
                  <User size={14} style={{ color: 'var(--text-muted)' }} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-sm font-medium" style={{ color: 'var(--text)' }}>
                      {action.actorName || action.actorType}
                    </span>
                    <span className="text-[10px] font-medium px-2 py-0.5 rounded-full" style={{ backgroundColor: 'var(--surface)', color: 'var(--text-muted)' }}>
                      {action.actionType}
                    </span>
                  </div>
                  {action.notes && (
                    <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>{action.notes}</p>
                  )}
                  <p className="text-[10px] mt-1" style={{ color: 'var(--text-muted)' }}>{formatDate(action.createdAt)}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ==================== RATING SECTION ==================== */}
      {showRating && (
        <div className="rounded-xl border p-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <h3 className="font-bold text-sm mb-1" style={{ color: 'var(--text)' }}>How was the service?</h3>
          <p className="text-xs mb-4" style={{ color: 'var(--text-muted)' }}>Your feedback helps us improve.</p>

          {/* Stars */}
          <div className="flex gap-1 mb-4">
            {[1, 2, 3, 4, 5].map(n => (
              <button
                key={n}
                onClick={() => setRating(n)}
                onMouseEnter={() => setHoverRating(n)}
                onMouseLeave={() => setHoverRating(0)}
                className="p-1 transition-transform hover:scale-110"
              >
                <Star
                  size={28}
                  fill={(hoverRating || rating) >= n ? 'var(--accent)' : 'none'}
                  style={{
                    color: (hoverRating || rating) >= n ? 'var(--accent)' : 'var(--border-light)',
                  }}
                />
              </button>
            ))}
          </div>

          {/* Feedback */}
          <textarea
            value={feedback}
            onChange={e => setFeedback(e.target.value)}
            placeholder="Share your experience (optional)..."
            rows={3}
            className="w-full px-4 py-3 rounded-xl border outline-none text-sm resize-none mb-3 transition-colors"
            style={{ borderColor: 'var(--border-light)', color: 'var(--text)', backgroundColor: 'var(--surface)' }}
          />

          <button
            onClick={handleRatingSubmit}
            disabled={rating === 0 || ratingSubmitting}
            className="w-full py-3 font-bold rounded-xl text-sm text-white transition-all disabled:opacity-40 disabled:cursor-not-allowed"
            style={{ backgroundColor: 'var(--accent)' }}
          >
            {ratingSubmitting ? 'Submitting...' : 'Submit Rating'}
          </button>
        </div>
      )}

      {/* Already rated */}
      {isCompleted && (request.tenantRating || ratingSubmitted) && (
        <div className="rounded-xl border p-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <div className="flex items-center gap-2 mb-1">
            <CheckCircle2 size={16} style={{ color: 'var(--success)' }} />
            <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>Rating Submitted</h3>
          </div>
          {request.tenantRating && (
            <div className="flex gap-0.5 mt-2">
              {[1, 2, 3, 4, 5].map(n => (
                <Star
                  key={n}
                  size={16}
                  fill={n <= request.tenantRating! ? 'var(--accent)' : 'none'}
                  style={{ color: n <= request.tenantRating! ? 'var(--accent)' : 'var(--border-light)' }}
                />
              ))}
            </div>
          )}
          {request.tenantFeedback && (
            <p className="text-xs mt-2" style={{ color: 'var(--text-muted)' }}>&ldquo;{request.tenantFeedback}&rdquo;</p>
          )}
        </div>
      )}
    </div>
  );
}
