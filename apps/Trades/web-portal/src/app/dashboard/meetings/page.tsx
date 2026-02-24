'use client';

import { useState } from 'react';
import {
  Video,
  Calendar,
  Clock,
  Users,
  Play,
  Plus,
  Search,
  ExternalLink,
  Briefcase,
  FileText,
  Camera,
  CheckCircle2,
  XCircle,
  Loader2,
  Copy,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { useMeetings } from '@/lib/hooks/use-meetings';
import type { Meeting } from '@/lib/hooks/use-meetings';
import Link from 'next/link';
import { useTranslation } from '@/lib/translations';
import { formatRelativeTime, cn } from '@/lib/utils';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

type MeetingTab = 'upcoming' | 'active' | 'past';

const meetingTypeLabels: Record<string, string> = {
  site_walk: 'Site Walk',
  virtual_estimate: 'Virtual Estimate',
  document_review: 'Document Review',
  team_huddle: 'Team Huddle',
  insurance_conference: 'Insurance Conference',
  subcontractor_consult: 'Subcontractor',
  expert_consult: 'Expert Consult',
  async_video: 'Async Video',
};

const meetingTypeColors: Record<string, string> = {
  site_walk: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
  virtual_estimate: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
  document_review: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
  team_huddle: 'bg-violet-500/10 text-violet-400 border-violet-500/20',
  insurance_conference: 'bg-orange-500/10 text-orange-400 border-orange-500/20',
  subcontractor_consult: 'bg-cyan-500/10 text-cyan-400 border-cyan-500/20',
  expert_consult: 'bg-pink-500/10 text-pink-400 border-pink-500/20',
  async_video: 'bg-secondary text-muted border-main',
};

function statusBadge(status: string) {
  const config: Record<string, { label: string; className: string }> = {
    scheduled: { label: 'Scheduled', className: 'bg-blue-500/10 text-blue-400 border-blue-500/20' },
    in_progress: { label: 'Live', className: 'bg-red-500/10 text-red-400 border-red-500/20 animate-pulse' },
    completed: { label: 'Completed', className: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' },
    cancelled: { label: 'Cancelled', className: 'bg-secondary text-muted border-main' },
    no_show: { label: 'No Show', className: 'bg-amber-500/10 text-amber-400 border-amber-500/20' },
  };
  const c = config[status] || { label: status, className: 'bg-secondary text-muted border-main' };
  return <Badge className={c.className}>{c.label}</Badge>;
}

function MeetingRow({ meeting, onJoin }: { meeting: Meeting; onJoin: (code: string) => void }) {
  const copyLink = () => {
    navigator.clipboard.writeText(`https://zafto.cloud/meet/${meeting.roomCode}`);
  };

  return (
    <div className="flex items-center gap-4 px-4 py-3 hover:bg-surface-hover border-b border-main">
      <div className="flex-shrink-0">
        <Video className={cn('h-5 w-5', meeting.status === 'in_progress' ? 'text-red-400' : 'text-muted')} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-medium text-main truncate">{meeting.title}</span>
          <Badge className={meetingTypeColors[meeting.meetingType] || meetingTypeColors.team_huddle}>
            {meetingTypeLabels[meeting.meetingType] || meeting.meetingType}
          </Badge>
        </div>
        <div className="flex items-center gap-3 text-xs text-muted mt-0.5">
          {meeting.scheduledAt && (
            <span className="flex items-center gap-1">
              <Calendar className="h-3 w-3" />
              {formatDateLocale(meeting.scheduledAt)} {formatTimeLocale(meeting.scheduledAt)}
            </span>
          )}
          <span className="flex items-center gap-1">
            <Clock className="h-3 w-3" />
            {meeting.actualDurationMinutes || meeting.durationMinutes}min
          </span>
          <span className="flex items-center gap-1">
            <Users className="h-3 w-3" />
            {meeting.participantCount}
          </span>
          {meeting.jobTitle && (
            <span className="flex items-center gap-1">
              <Briefcase className="h-3 w-3" />
              {meeting.jobTitle}
            </span>
          )}
        </div>
        {meeting.aiSummary && (
          <p className="text-xs text-muted mt-1 line-clamp-1">{meeting.aiSummary}</p>
        )}
      </div>
      <div className="flex items-center gap-2 flex-shrink-0">
        {statusBadge(meeting.status)}
        {meeting.status === 'in_progress' && (
          <Button size="sm" className="bg-red-600 hover:bg-red-700 gap-1" onClick={() => onJoin(meeting.roomCode)}>
            <Video className="h-3.5 w-3.5" />
            Join
          </Button>
        )}
        {meeting.status === 'scheduled' && (
          <Button size="sm" variant="outline" className="gap-1" onClick={() => onJoin(meeting.roomCode)}>
            <Video className="h-3.5 w-3.5" />
            Start
          </Button>
        )}
        <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={copyLink}>
          <Copy className="h-3.5 w-3.5" />
        </Button>
        {meeting.recordingPath && (
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0">
            <Play className="h-3.5 w-3.5" />
          </Button>
        )}
      </div>
    </div>
  );
}

export default function MeetingsPage() {
  const { t } = useTranslation();
  const { meetings, upcoming, active, past, loading, error, joinMeeting } = useMeetings();
  const [tab, setTab] = useState<MeetingTab>('upcoming');
  const [search, setSearch] = useState('');

  const displayed = tab === 'upcoming' ? upcoming : tab === 'active' ? active : past;
  const filtered = displayed.filter(m => {
    if (!search) return true;
    const q = search.toLowerCase();
    return m.title.toLowerCase().includes(q) || m.jobTitle?.toLowerCase().includes(q) ||
      m.roomCode.includes(q);
  });

  const handleJoin = async (roomCode: string) => {
    try {
      const result = await joinMeeting(roomCode);
      if (result?.livekitUrl && result?.token) {
        // In production: open LiveKit room in new window or embedded component
        window.open(`/dashboard/meetings/room?code=${roomCode}`, '_blank');
      }
    } catch (e) {
      console.error('Failed to join meeting:', e);
    }
  };

  return (
    <>
      <CommandPalette />
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-main">{t('meetings.title')}</h1>
            <p className="text-sm text-muted mt-1">Video meetings, site walks, and async video</p>
          </div>
          <div className="flex items-center gap-2">
            <Link href="/dashboard/meetings/async-videos">
              <Button variant="outline" size="sm" className="gap-1">
                <Play className="h-3.5 w-3.5" />
                Async Videos
              </Button>
            </Link>
            <Link href="/dashboard/meetings/booking-types">
              <Button variant="outline" size="sm" className="gap-1">
                <Calendar className="h-3.5 w-3.5" />
                Booking Types
              </Button>
            </Link>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-4 gap-4">
          <Card className="bg-secondary/50 border-main">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-muted">
                <Video className="h-4 w-4 text-red-400" />
                Live Now
              </div>
              <p className="text-2xl font-bold text-main mt-1">{active.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-secondary/50 border-main">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-muted">
                <Calendar className="h-4 w-4" />
                Upcoming
              </div>
              <p className="text-2xl font-bold text-main mt-1">{upcoming.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-secondary/50 border-main">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-muted">
                <CheckCircle2 className="h-4 w-4" />
                Completed
              </div>
              <p className="text-2xl font-bold text-main mt-1">{past.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-secondary/50 border-main">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-muted">
                <Users className="h-4 w-4" />
                Total
              </div>
              <p className="text-2xl font-bold text-main mt-1">{meetings.length}</p>
            </CardContent>
          </Card>
        </div>

        <Card className="bg-secondary/50 border-main">
          <CardHeader className="pb-0">
            <div className="flex items-center justify-between">
              <div className="flex gap-1">
                {(['upcoming', 'active', 'past'] as MeetingTab[]).map(t => (
                  <Button
                    key={t}
                    variant={tab === t ? 'default' : 'ghost'}
                    size="sm"
                    onClick={() => setTab(t)}
                    className="capitalize gap-1"
                  >
                    {t === 'active' && active.length > 0 && (
                      <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
                    )}
                    {t}
                    {t === 'upcoming' && upcoming.length > 0 && (
                      <span className="text-xs bg-secondary rounded-full px-1.5">{upcoming.length}</span>
                    )}
                  </Button>
                ))}
              </div>
              <SearchInput
                placeholder="Search meetings..."
                value={search}
                onChange={(v) => setSearch(v)}
                className="w-60"
              />
            </div>
          </CardHeader>
          <CardContent className="p-0 mt-4">
            {loading ? (
              <div className="flex items-center justify-center py-12 text-muted">{t('common.loading')}</div>
            ) : error ? (
              <div className="flex items-center justify-center py-12 text-red-400">{error}</div>
            ) : filtered.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-muted">
                <Video className="h-8 w-8 mb-2 opacity-50" />
                <p>No {tab} meetings</p>
                <p className="text-xs mt-1">{t('common.createAMeetingFromAnyJobOrCustomerPage')}</p>
              </div>
            ) : (
              <div>
                {filtered.map(meeting => (
                  <MeetingRow key={meeting.id} meeting={meeting} onJoin={handleJoin} />
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </>
  );
}
