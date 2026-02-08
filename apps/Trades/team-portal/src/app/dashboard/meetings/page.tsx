'use client';

import { useState, useCallback } from 'react';
import { Video, Users, Clock, Calendar, ExternalLink } from 'lucide-react';
import {
  useMeetings,
  MEETING_TYPE_LABELS,
  MEETING_TYPE_COLORS,
} from '@/lib/hooks/use-meetings';
import type { MeetingData, MeetingType } from '@/lib/hooks/use-meetings';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { cn, formatDateTime, formatDate, formatTime } from '@/lib/utils';

function MeetingsSkeleton() {
  return (
    <div className="space-y-6 animate-fade-in">
      <div className="skeleton h-7 w-40 rounded-lg" />
      <div className="space-y-4">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="skeleton h-24 w-full rounded-xl" />
        ))}
      </div>
    </div>
  );
}

function formatDuration(minutes: number | null): string {
  if (!minutes) return '--';
  if (minutes < 60) return `${minutes}m`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m > 0 ? `${h}h ${m}m` : `${h}h`;
}

function MeetingTypeBadge({ type }: { type: MeetingType }) {
  const colors = MEETING_TYPE_COLORS[type];
  const label = MEETING_TYPE_LABELS[type];
  return (
    <Badge className={cn(colors.bg, colors.text)}>
      {label}
    </Badge>
  );
}

function ActiveMeetingRow({
  meeting,
  onJoin,
  joining,
}: {
  meeting: MeetingData;
  onJoin: (roomCode: string) => void;
  joining: boolean;
}) {
  return (
    <Card className="border-red-500/40 bg-red-500/5">
      <CardContent className="py-3">
        <div className="flex items-center gap-3">
          <div className="w-2 h-2 rounded-full bg-red-500 animate-pulse flex-shrink-0" />
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2">
              <p className="text-sm font-semibold text-main truncate">{meeting.title}</p>
              <MeetingTypeBadge type={meeting.meetingType} />
            </div>
            <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1">
              {meeting.startedAt && (
                <span className="text-xs text-muted flex items-center gap-1">
                  <Clock size={11} className="flex-shrink-0" />
                  Started {formatTime(meeting.startedAt)}
                </span>
              )}
              <span className="text-xs text-muted flex items-center gap-1">
                <Users size={11} className="flex-shrink-0" />
                {meeting.participantCount} participant{meeting.participantCount !== 1 ? 's' : ''}
              </span>
            </div>
          </div>
          <Button
            variant="danger"
            size="sm"
            disabled={joining}
            onClick={() => onJoin(meeting.roomCode)}
          >
            <Video size={14} />
            Join
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

function UpcomingMeetingRow({
  meeting,
  onJoin,
  joining,
}: {
  meeting: MeetingData;
  onJoin: (roomCode: string) => void;
  joining: boolean;
}) {
  return (
    <Card className="hover:border-accent/30 transition-colors">
      <CardContent className="py-3">
        <div className="flex items-center gap-3">
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2">
              <p className="text-sm font-medium text-main truncate">{meeting.title}</p>
              <MeetingTypeBadge type={meeting.meetingType} />
            </div>
            <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1">
              {meeting.scheduledAt && (
                <span className="text-xs text-secondary flex items-center gap-1">
                  <Calendar size={11} className="flex-shrink-0" />
                  {formatDateTime(meeting.scheduledAt)}
                </span>
              )}
              <span className="text-xs text-muted flex items-center gap-1">
                <Clock size={11} className="flex-shrink-0" />
                {formatDuration(meeting.durationMinutes)}
              </span>
              <span className="text-xs text-muted flex items-center gap-1">
                <Users size={11} className="flex-shrink-0" />
                {meeting.participantCount}
              </span>
            </div>
          </div>
          <Button
            variant="secondary"
            size="sm"
            disabled={joining}
            onClick={() => onJoin(meeting.roomCode)}
          >
            <ExternalLink size={14} />
            Join
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

function PastMeetingRow({ meeting }: { meeting: MeetingData }) {
  return (
    <Card>
      <CardContent className="py-3">
        <div className="flex items-center gap-3">
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2">
              <p className="text-sm font-medium text-main truncate">{meeting.title}</p>
              <MeetingTypeBadge type={meeting.meetingType} />
            </div>
            <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1">
              {meeting.scheduledAt && (
                <span className="text-xs text-muted flex items-center gap-1">
                  <Calendar size={11} className="flex-shrink-0" />
                  {formatDate(meeting.scheduledAt)}
                </span>
              )}
              <span className="text-xs text-muted flex items-center gap-1">
                <Clock size={11} className="flex-shrink-0" />
                {formatDuration(meeting.actualDurationMinutes || meeting.durationMinutes)}
              </span>
              <span className="text-xs text-muted flex items-center gap-1">
                <Users size={11} className="flex-shrink-0" />
                {meeting.participantCount}
              </span>
              {meeting.isRecorded && (
                <Badge variant="info">Recorded</Badge>
              )}
              {meeting.status === 'no_show' && (
                <Badge variant="warning">No Show</Badge>
              )}
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

export default function MeetingsPage() {
  const { active, upcoming, past, loading, error, joinMeeting } = useMeetings();
  const [joining, setJoining] = useState(false);
  const [joinError, setJoinError] = useState<string | null>(null);

  const handleJoin = useCallback(async (roomCode: string) => {
    try {
      setJoining(true);
      setJoinError(null);
      const result = await joinMeeting(roomCode);
      if (result?.url) {
        window.open(result.url, '_blank', 'noopener,noreferrer');
      }
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to join meeting';
      setJoinError(msg);
    } finally {
      setJoining(false);
    }
  }, [joinMeeting]);

  if (loading) return <MeetingsSkeleton />;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-semibold text-main">Meetings</h1>
        <p className="text-sm text-muted mt-0.5">
          {active.length > 0
            ? `${active.length} active now`
            : upcoming.length > 0
            ? `${upcoming.length} upcoming`
            : 'No meetings scheduled'}
        </p>
      </div>

      {/* Error */}
      {(error || joinError) && (
        <Card className="border-red-500/30">
          <CardContent className="py-3">
            <p className="text-sm text-red-500">{error || joinError}</p>
          </CardContent>
        </Card>
      )}

      {/* Active Meetings */}
      {active.length > 0 && (
        <div>
          <CardHeader className="px-1 py-0 border-b-0 mb-2">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
              <CardTitle className="text-red-500">Live Now</CardTitle>
              <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-red-500/10 text-red-500">
                {active.length}
              </span>
            </div>
          </CardHeader>
          <div className="space-y-2">
            {active.map((meeting) => (
              <ActiveMeetingRow
                key={meeting.id}
                meeting={meeting}
                onJoin={handleJoin}
                joining={joining}
              />
            ))}
          </div>
        </div>
      )}

      {/* Upcoming Meetings */}
      <div>
        <div className="flex items-center gap-2 mb-2 px-1">
          <Calendar size={16} className="text-accent" />
          <p className="text-sm font-semibold text-main">Upcoming</p>
          {upcoming.length > 0 && (
            <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-accent/10 text-accent">
              {upcoming.length}
            </span>
          )}
        </div>
        {upcoming.length === 0 ? (
          <Card>
            <CardContent className="py-8 text-center">
              <Video size={24} className="mx-auto text-muted mb-2" />
              <p className="text-sm text-muted">No upcoming meetings</p>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-2">
            {upcoming.map((meeting) => (
              <UpcomingMeetingRow
                key={meeting.id}
                meeting={meeting}
                onJoin={handleJoin}
                joining={joining}
              />
            ))}
          </div>
        )}
      </div>

      {/* Past Meetings */}
      {past.length > 0 && (
        <div>
          <div className="flex items-center gap-2 mb-2 px-1">
            <Clock size={16} className="text-muted" />
            <p className="text-sm font-semibold text-muted">Past Meetings</p>
            <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-secondary text-muted">
              {past.length}
            </span>
          </div>
          <div className="space-y-2">
            {past.map((meeting) => (
              <PastMeetingRow key={meeting.id} meeting={meeting} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
