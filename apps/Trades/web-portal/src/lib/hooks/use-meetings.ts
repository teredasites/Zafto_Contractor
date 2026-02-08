'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface Meeting {
  id: string;
  companyId: string;
  jobId: string | null;
  jobTitle?: string;
  claimId: string | null;
  title: string;
  meetingType: string;
  roomCode: string;
  scheduledAt: string | null;
  durationMinutes: number;
  startedAt: string | null;
  endedAt: string | null;
  actualDurationMinutes: number | null;
  isRecorded: boolean;
  recordingPath: string | null;
  aiSummary: string | null;
  aiActionItems: Array<{ description: string; assigned_to?: string; due_date?: string }>;
  status: string;
  bookedByName: string | null;
  bookedByEmail: string | null;
  participantCount: number;
  createdAt: string;
}

export interface BookingType {
  id: string;
  companyId: string;
  name: string;
  slug: string;
  description: string | null;
  durationMinutes: number;
  meetingType: string;
  isActive: boolean;
  showOnWebsite: boolean;
  showOnClientPortal: boolean;
}

export interface MeetingParticipant {
  id: string;
  meetingId: string;
  userId: string | null;
  participantType: string;
  name: string;
  email: string | null;
  joinedAt: string | null;
  leftAt: string | null;
  durationSeconds: number | null;
}

function mapMeeting(row: Record<string, unknown>): Meeting {
  const job = row.jobs as Record<string, unknown> | null;
  const participants = (row.meeting_participants as unknown[]) || [];
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    jobId: (row.job_id as string) || null,
    jobTitle: (job?.title as string) || undefined,
    claimId: (row.claim_id as string) || null,
    title: row.title as string,
    meetingType: row.meeting_type as string,
    roomCode: row.room_code as string,
    scheduledAt: (row.scheduled_at as string) || null,
    durationMinutes: (row.duration_minutes as number) || 30,
    startedAt: (row.started_at as string) || null,
    endedAt: (row.ended_at as string) || null,
    actualDurationMinutes: (row.actual_duration_minutes as number) || null,
    isRecorded: (row.is_recorded as boolean) || false,
    recordingPath: (row.recording_path as string) || null,
    aiSummary: (row.ai_summary as string) || null,
    aiActionItems: (row.ai_action_items as Meeting['aiActionItems']) || [],
    status: row.status as string,
    bookedByName: (row.booked_by_name as string) || null,
    bookedByEmail: (row.booked_by_email as string) || null,
    participantCount: participants.length,
    createdAt: row.created_at as string,
  };
}

export function useMeetings() {
  const [meetings, setMeetings] = useState<Meeting[]>([]);
  const [bookingTypes, setBookingTypes] = useState<BookingType[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const [meetingsRes, typesRes] = await Promise.all([
        supabase
          .from('meetings')
          .select('*, jobs(title), meeting_participants(id)')
          .order('scheduled_at', { ascending: false, nullsFirst: false })
          .limit(100),
        supabase
          .from('meeting_booking_types')
          .select('*')
          .order('name'),
      ]);

      if (meetingsRes.error) throw meetingsRes.error;
      if (typesRes.error) throw typesRes.error;

      setMeetings((meetingsRes.data || []).map(mapMeeting));
      setBookingTypes((typesRes.data || []).map((r: Record<string, unknown>) => ({
        id: r.id as string,
        companyId: r.company_id as string,
        name: r.name as string,
        slug: r.slug as string,
        description: (r.description as string) || null,
        durationMinutes: r.duration_minutes as number,
        meetingType: r.meeting_type as string,
        isActive: r.is_active as boolean,
        showOnWebsite: r.show_on_website as boolean,
        showOnClientPortal: r.show_on_client_portal as boolean,
      })));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load meetings';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();

    const supabase = getSupabase();
    const channel = supabase
      .channel('meetings-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'meetings' }, () => fetchData())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchData]);

  const createMeeting = async (input: {
    title: string;
    meetingType: string;
    jobId?: string;
    claimId?: string;
    scheduled?: string;
    durationMinutes?: number;
    record?: boolean;
  }) => {
    const supabase = getSupabase();
    const response = await supabase.functions.invoke('meeting-room', {
      body: { action: 'create', ...input },
    });
    if (response.error) throw new Error(response.error.message);
    return response.data;
  };

  const joinMeeting = async (roomCode: string) => {
    const supabase = getSupabase();
    const response = await supabase.functions.invoke('meeting-room', {
      body: { action: 'join', roomCode },
    });
    if (response.error) throw new Error(response.error.message);
    return response.data;
  };

  const endMeeting = async (meetingId: string) => {
    const supabase = getSupabase();
    const response = await supabase.functions.invoke('meeting-room', {
      body: { action: 'end', meetingId },
    });
    if (response.error) throw new Error(response.error.message);
    return response.data;
  };

  const upcoming = meetings.filter(m => m.status === 'scheduled');
  const active = meetings.filter(m => m.status === 'in_progress');
  const past = meetings.filter(m => m.status === 'completed');

  return {
    meetings, upcoming, active, past, bookingTypes,
    loading, error, refetch: fetchData,
    createMeeting, joinMeeting, endMeeting,
  };
}
