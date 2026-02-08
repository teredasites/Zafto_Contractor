'use client';

import { Video, Calendar, Clock, ChevronRight, Play, FileText, Loader2 } from 'lucide-react';
import Link from 'next/link';
import { useMeetings, type MeetingData } from '@/lib/hooks/use-meetings';

// ==================== HELPERS ====================

function formatDateTime(dateStr: string | null): string {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
    + ' at '
    + d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
}

function formatTime(dateStr: string | null): string {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
}

function formatDateShort(dateStr: string | null): string {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
}

function formatDuration(minutes: number): string {
  if (minutes < 60) return `${minutes} min`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m > 0 ? `${h}h ${m}m` : `${h}h`;
}

const MEETING_TYPE_LABELS: Record<string, string> = {
  site_walk: 'Site Walk',
  virtual_estimate: 'Virtual Estimate',
  document_review: 'Document Review',
  team_huddle: 'Team Huddle',
  insurance_conference: 'Insurance Conference',
  subcontractor_consult: 'Subcontractor Consult',
  expert_consult: 'Expert Consult',
  async_video: 'Async Video',
};

const STATUS_STYLES: Record<string, { label: string; color: string; bg: string }> = {
  scheduled: { label: 'Scheduled', color: 'var(--accent)', bg: 'var(--accent-light)' },
  in_progress: { label: 'Live Now', color: 'var(--success)', bg: 'color-mix(in srgb, var(--success) 15%, transparent)' },
  completed: { label: 'Completed', color: 'var(--text-muted)', bg: 'var(--bg-secondary)' },
  cancelled: { label: 'Cancelled', color: 'var(--error)', bg: 'color-mix(in srgb, var(--error) 15%, transparent)' },
  no_show: { label: 'No Show', color: 'var(--warning)', bg: 'color-mix(in srgb, var(--warning) 15%, transparent)' },
};

// ==================== SKELETON ====================

function ListSkeleton() {
  return (
    <div className="space-y-2 animate-pulse">
      {[1, 2, 3].map(i => (
        <div key={i} className="flex items-center gap-3 rounded-xl border p-4" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <div className="w-10 h-10 rounded-xl" style={{ backgroundColor: 'var(--bg-secondary)' }} />
          <div className="flex-1 space-y-2">
            <div className="h-4 rounded w-40" style={{ backgroundColor: 'var(--bg-secondary)' }} />
            <div className="h-3 rounded w-56" style={{ backgroundColor: 'var(--border-light)' }} />
          </div>
          <div className="h-5 rounded-full w-16" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        </div>
      ))}
    </div>
  );
}

// ==================== ACTIVE MEETING CARD ====================

function ActiveMeetingCard({ meeting, onJoin, joining }: { meeting: MeetingData; onJoin: (code: string) => void; joining: boolean }) {
  return (
    <div className="rounded-xl border-2 p-5" style={{ borderColor: 'var(--success)', backgroundColor: 'var(--surface)' }}>
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-2">
          <div className="relative">
            <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: 'var(--success)' }} />
            <div className="absolute inset-0 w-2.5 h-2.5 rounded-full animate-ping" style={{ backgroundColor: 'var(--success)', opacity: 0.4 }} />
          </div>
          <span className="text-xs font-semibold uppercase tracking-wider" style={{ color: 'var(--success)' }}>Live Now</span>
        </div>
        <span className="text-xs" style={{ color: 'var(--text-muted)' }}>
          {formatDuration(meeting.durationMinutes)}
        </span>
      </div>

      <h3 className="font-bold text-base mb-1" style={{ color: 'var(--text)' }}>{meeting.title}</h3>
      <p className="text-xs mb-4" style={{ color: 'var(--text-muted)' }}>
        {MEETING_TYPE_LABELS[meeting.meetingType] || meeting.meetingType}
        {meeting.startedAt && ` -- Started ${formatTime(meeting.startedAt)}`}
      </p>

      <button
        onClick={() => onJoin(meeting.roomCode)}
        disabled={joining}
        className="w-full flex items-center justify-center gap-2 py-3 rounded-xl text-sm font-semibold text-white transition-colors"
        style={{ backgroundColor: 'var(--success)' }}
      >
        {joining ? <Loader2 size={16} className="animate-spin" /> : <Video size={16} />}
        {joining ? 'Joining...' : 'Join Now'}
      </button>
    </div>
  );
}

// ==================== MEETING ROW ====================

function MeetingRow({ meeting, onJoin, joining }: { meeting: MeetingData; onJoin: (code: string) => void; joining: boolean }) {
  const style = STATUS_STYLES[meeting.status] || STATUS_STYLES.scheduled;
  const isJoinable = meeting.status === 'scheduled' || meeting.status === 'in_progress';
  const hasSummary = !!meeting.aiSummary;

  return (
    <div className="flex items-center gap-3 rounded-xl border p-4 transition-colors" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
      {/* Icon */}
      <div className="p-2.5 rounded-xl flex-shrink-0" style={{ backgroundColor: 'var(--bg-secondary)' }}>
        <Video size={18} style={{ color: 'var(--accent)' }} />
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <h3 className="font-semibold text-sm truncate" style={{ color: 'var(--text)' }}>{meeting.title}</h3>
        <div className="flex items-center gap-3 mt-0.5 flex-wrap">
          <span className="flex items-center gap-1 text-xs" style={{ color: 'var(--text-muted)' }}>
            <Calendar size={11} />
            {formatDateShort(meeting.scheduledAt)}
          </span>
          <span className="flex items-center gap-1 text-xs" style={{ color: 'var(--text-muted)' }}>
            <Clock size={11} />
            {meeting.scheduledAt ? formatTime(meeting.scheduledAt) : '--'}
          </span>
          <span className="text-xs" style={{ color: 'var(--text-muted)' }}>
            {formatDuration(meeting.actualDurationMinutes || meeting.durationMinutes)}
          </span>
        </div>
      </div>

      {/* Actions / Status */}
      <div className="flex items-center gap-2 flex-shrink-0">
        {hasSummary && (
          <span className="flex items-center gap-1 text-[10px] font-medium px-2 py-0.5 rounded-full" style={{ backgroundColor: 'var(--accent-light)', color: 'var(--accent)' }}>
            <FileText size={10} />
            Summary
          </span>
        )}

        <span className="text-[10px] font-medium px-2.5 py-1 rounded-full" style={{ backgroundColor: style.bg, color: style.color }}>
          {style.label}
        </span>

        {isJoinable && (
          <button
            onClick={() => onJoin(meeting.roomCode)}
            disabled={joining}
            className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold text-white transition-colors"
            style={{ backgroundColor: 'var(--accent)' }}
          >
            {joining ? <Loader2 size={12} className="animate-spin" /> : <Play size={12} />}
            Join
          </button>
        )}
      </div>
    </div>
  );
}

// ==================== PAST MEETING DETAIL (expandable AI summary) ====================

function PastMeetingRow({ meeting }: { meeting: MeetingData }) {
  const style = STATUS_STYLES[meeting.status] || STATUS_STYLES.completed;

  return (
    <div className="rounded-xl border p-4" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
      <div className="flex items-center gap-3">
        <div className="p-2.5 rounded-xl flex-shrink-0" style={{ backgroundColor: 'var(--bg-secondary)' }}>
          <Video size={18} style={{ color: 'var(--text-muted)' }} />
        </div>

        <div className="flex-1 min-w-0">
          <h3 className="font-semibold text-sm truncate" style={{ color: 'var(--text)' }}>{meeting.title}</h3>
          <div className="flex items-center gap-3 mt-0.5 flex-wrap">
            <span className="flex items-center gap-1 text-xs" style={{ color: 'var(--text-muted)' }}>
              <Calendar size={11} />
              {formatDateShort(meeting.scheduledAt)}
            </span>
            <span className="text-xs" style={{ color: 'var(--text-muted)' }}>
              {formatDuration(meeting.actualDurationMinutes || meeting.durationMinutes)}
            </span>
            {meeting.isRecorded && (
              <span className="flex items-center gap-1 text-[10px] font-medium px-2 py-0.5 rounded-full" style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text-muted)' }}>
                <Play size={10} />
                Recorded
              </span>
            )}
          </div>
        </div>

        <span className="text-[10px] font-medium px-2.5 py-1 rounded-full flex-shrink-0" style={{ backgroundColor: style.bg, color: style.color }}>
          {style.label}
        </span>
      </div>

      {/* AI Summary */}
      {meeting.aiSummary && (
        <div className="mt-3 pt-3" style={{ borderTop: '1px solid var(--border-light)' }}>
          <div className="flex items-center gap-1.5 mb-1.5">
            <FileText size={12} style={{ color: 'var(--accent)' }} />
            <span className="text-[10px] font-semibold uppercase tracking-wider" style={{ color: 'var(--accent)' }}>AI Summary</span>
          </div>
          <p className="text-xs leading-relaxed" style={{ color: 'var(--text-secondary)' }}>
            {meeting.aiSummary}
          </p>
        </div>
      )}

      {/* Action Items */}
      {meeting.aiActionItems.length > 0 && (
        <div className="mt-2">
          <span className="text-[10px] font-semibold uppercase tracking-wider" style={{ color: 'var(--text-muted)' }}>Action Items</span>
          <ul className="mt-1 space-y-0.5">
            {meeting.aiActionItems.map((item, i) => (
              <li key={i} className="flex items-start gap-1.5 text-xs" style={{ color: 'var(--text-secondary)' }}>
                <ChevronRight size={10} className="mt-0.5 flex-shrink-0" style={{ color: 'var(--accent)' }} />
                <span>{item}</span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

// ==================== PAGE ====================

export default function MeetingsPage() {
  const { active, upcoming, past, loading, error, joining, joinMeeting } = useMeetings();

  const handleJoin = async (roomCode: string) => {
    const result = await joinMeeting(roomCode);
    if (result?.joinUrl) {
      window.open(result.joinUrl, '_blank');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold" style={{ color: 'var(--text)' }}>Meetings</h1>
          <p className="text-sm mt-0.5" style={{ color: 'var(--text-muted)' }}>
            Video calls and consultations with your contractor
          </p>
        </div>
        <Link
          href="/book"
          className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-semibold text-white transition-colors"
          style={{ backgroundColor: 'var(--accent)' }}
        >
          <Calendar size={14} />
          Book Meeting
        </Link>
      </div>

      {/* Error */}
      {error && (
        <div className="rounded-xl px-4 py-3 text-sm" style={{ backgroundColor: 'var(--error-light)', color: 'var(--error)' }}>
          {error}
        </div>
      )}

      {/* Loading */}
      {loading && <ListSkeleton />}

      {/* Empty State */}
      {!loading && active.length === 0 && upcoming.length === 0 && past.length === 0 && (
        <div className="rounded-xl border p-8 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <Video size={32} className="mx-auto mb-3" style={{ color: 'var(--text-muted)' }} />
          <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>No meetings yet</h3>
          <p className="text-xs mt-1 mb-4" style={{ color: 'var(--text-muted)' }}>
            When your contractor schedules a meeting, it will appear here.
          </p>
          <Link
            href="/book"
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-semibold text-white transition-colors"
            style={{ backgroundColor: 'var(--accent)' }}
          >
            <Calendar size={14} />
            Book a Meeting
          </Link>
        </div>
      )}

      {/* Active / Live Meetings */}
      {!loading && active.length > 0 && (
        <section>
          <h2 className="text-xs font-semibold uppercase tracking-wider mb-2" style={{ color: 'var(--success)' }}>
            Active Now
          </h2>
          <div className="space-y-2">
            {active.map(m => (
              <ActiveMeetingCard key={m.id} meeting={m} onJoin={handleJoin} joining={joining} />
            ))}
          </div>
        </section>
      )}

      {/* Upcoming Meetings */}
      {!loading && upcoming.length > 0 && (
        <section>
          <h2 className="text-xs font-semibold uppercase tracking-wider mb-2" style={{ color: 'var(--text-muted)' }}>
            Upcoming
          </h2>
          <div className="space-y-2">
            {upcoming.map(m => (
              <MeetingRow key={m.id} meeting={m} onJoin={handleJoin} joining={joining} />
            ))}
          </div>
        </section>
      )}

      {/* Past Meetings */}
      {!loading && past.length > 0 && (
        <section>
          <h2 className="text-xs font-semibold uppercase tracking-wider mb-2" style={{ color: 'var(--text-muted)' }}>
            Past
          </h2>
          <div className="space-y-2">
            {past.map(m => (
              <PastMeetingRow key={m.id} meeting={m} />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
