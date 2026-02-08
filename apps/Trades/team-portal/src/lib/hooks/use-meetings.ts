'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ==================== TYPES ====================

export type MeetingType =
  | 'site_walk' | 'virtual_estimate' | 'document_review'
  | 'team_huddle' | 'insurance_conference' | 'subcontractor_consult'
  | 'expert_consult' | 'async_video';

export type MeetingStatus = 'scheduled' | 'in_progress' | 'completed' | 'cancelled' | 'no_show';

export interface MeetingData {
  id: string;
  companyId: string;
  jobId: string | null;
  claimId: string | null;
  title: string;
  meetingType: MeetingType;
  roomCode: string;
  scheduledAt: string | null;
  durationMinutes: number;
  startedAt: string | null;
  endedAt: string | null;
  actualDurationMinutes: number | null;
  isRecorded: boolean;
  status: MeetingStatus;
  participantCount: number;
  createdAt: string;
}

export const MEETING_TYPE_LABELS: Record<MeetingType, string> = {
  site_walk: 'Site Walk',
  virtual_estimate: 'Virtual Estimate',
  document_review: 'Document Review',
  team_huddle: 'Team Huddle',
  insurance_conference: 'Insurance Conference',
  subcontractor_consult: 'Subcontractor Consult',
  expert_consult: 'Expert Consult',
  async_video: 'Async Video',
};

export const MEETING_TYPE_COLORS: Record<MeetingType, { bg: string; text: string }> = {
  site_walk: { bg: 'bg-emerald-100 dark:bg-emerald-900/30', text: 'text-emerald-700 dark:text-emerald-300' },
  virtual_estimate: { bg: 'bg-blue-100 dark:bg-blue-900/30', text: 'text-blue-700 dark:text-blue-300' },
  document_review: { bg: 'bg-slate-100 dark:bg-slate-800', text: 'text-slate-700 dark:text-slate-300' },
  team_huddle: { bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-700 dark:text-amber-300' },
  insurance_conference: { bg: 'bg-purple-100 dark:bg-purple-900/30', text: 'text-purple-700 dark:text-purple-300' },
  subcontractor_consult: { bg: 'bg-cyan-100 dark:bg-cyan-900/30', text: 'text-cyan-700 dark:text-cyan-300' },
  expert_consult: { bg: 'bg-indigo-100 dark:bg-indigo-900/30', text: 'text-indigo-700 dark:text-indigo-300' },
  async_video: { bg: 'bg-orange-100 dark:bg-orange-900/30', text: 'text-orange-700 dark:text-orange-300' },
};

// ==================== MAPPER ====================

function mapMeeting(row: Record<string, unknown>): MeetingData {
  const participants = row.meeting_participants as Array<{ id: string }> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    jobId: (row.job_id as string) || null,
    claimId: (row.claim_id as string) || null,
    title: (row.title as string) || 'Untitled Meeting',
    meetingType: (row.meeting_type as MeetingType) || 'team_huddle',
    roomCode: (row.room_code as string) || '',
    scheduledAt: (row.scheduled_at as string) || null,
    durationMinutes: (row.duration_minutes as number) || 30,
    startedAt: (row.started_at as string) || null,
    endedAt: (row.ended_at as string) || null,
    actualDurationMinutes: (row.actual_duration_minutes as number) || null,
    isRecorded: (row.is_recorded as boolean) || false,
    status: (row.status as MeetingStatus) || 'scheduled',
    participantCount: participants?.length || 0,
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

// ==================== HOOK ====================

export function useMeetings() {
  const [meetings, setMeetings] = useState<MeetingData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchMeetings = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const { data, error: err } = await supabase
        .from('meetings')
        .select('*, meeting_participants(id)')
        .order('scheduled_at', { ascending: true, nullsFirst: false });

      if (err) throw err;
      setMeetings((data || []).map((row: Record<string, unknown>) => mapMeeting(row)));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load meetings';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchMeetings();
    const supabase = getSupabase();
    const channel = supabase.channel('team-meetings')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'meetings' }, () => fetchMeetings())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'meeting_participants' }, () => fetchMeetings())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchMeetings]);

  // Computed lists
  const now = useMemo(() => new Date(), []);

  const active = useMemo(() =>
    meetings.filter((m) => m.status === 'in_progress'),
    [meetings]
  );

  const upcoming = useMemo(() =>
    meetings.filter((m) => {
      if (m.status !== 'scheduled') return false;
      if (!m.scheduledAt) return true;
      return new Date(m.scheduledAt) >= now;
    }).sort((a, b) => {
      const aTime = a.scheduledAt ? new Date(a.scheduledAt).getTime() : Infinity;
      const bTime = b.scheduledAt ? new Date(b.scheduledAt).getTime() : Infinity;
      return aTime - bTime;
    }),
    [meetings, now]
  );

  const past = useMemo(() =>
    meetings.filter((m) =>
      m.status === 'completed' || m.status === 'no_show'
    ).sort((a, b) => {
      const aTime = a.endedAt ? new Date(a.endedAt).getTime() : a.scheduledAt ? new Date(a.scheduledAt).getTime() : 0;
      const bTime = b.endedAt ? new Date(b.endedAt).getTime() : b.scheduledAt ? new Date(b.scheduledAt).getTime() : 0;
      return bTime - aTime;
    }),
    [meetings]
  );

  const joinMeeting = useCallback(async (roomCode: string) => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase.functions.invoke('meeting-room', {
      body: { action: 'join', roomCode },
    });
    if (err) throw err;
    return data as { url: string };
  }, []);

  return { meetings, active, upcoming, past, loading, error, joinMeeting };
}
