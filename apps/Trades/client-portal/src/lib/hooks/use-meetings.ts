'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// ============================================================================
// TYPES
// ============================================================================

export type MeetingStatus = 'scheduled' | 'in_progress' | 'completed' | 'cancelled' | 'no_show';

export interface MeetingData {
  id: string;
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
  aiActionItems: string[];
  status: MeetingStatus;
  jobId: string | null;
  bookedByName: string | null;
}

export interface BookingTypeData {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  durationMinutes: number;
  meetingType: string;
}

export interface TimeSlot {
  start: string;
  end: string;
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapMeeting(row: Record<string, unknown>): MeetingData {
  return {
    id: row.id as string,
    title: (row.title as string) || '',
    meetingType: (row.meeting_type as string) || 'virtual_estimate',
    roomCode: (row.room_code as string) || '',
    scheduledAt: row.scheduled_at as string | null,
    durationMinutes: (row.duration_minutes as number) || 30,
    startedAt: row.started_at as string | null,
    endedAt: row.ended_at as string | null,
    actualDurationMinutes: row.actual_duration_minutes as number | null,
    isRecorded: (row.is_recorded as boolean) || false,
    recordingPath: row.recording_path as string | null,
    aiSummary: row.ai_summary as string | null,
    aiActionItems: Array.isArray(row.ai_action_items) ? (row.ai_action_items as string[]) : [],
    status: (row.status as MeetingStatus) || 'scheduled',
    jobId: row.job_id as string | null,
    bookedByName: row.booked_by_name as string | null,
  };
}

function mapBookingType(row: Record<string, unknown>): BookingTypeData {
  return {
    id: row.id as string,
    name: (row.name as string) || '',
    slug: (row.slug as string) || '',
    description: row.description as string | null,
    durationMinutes: (row.duration_minutes as number) || 15,
    meetingType: (row.meeting_type as string) || 'virtual_estimate',
  };
}

// ============================================================================
// HOOK: useMeetings
// ============================================================================

export function useMeetings() {
  const { profile } = useAuth();
  const [meetings, setMeetings] = useState<MeetingData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [joining, setJoining] = useState(false);

  const fetchMeetings = useCallback(async () => {
    if (!profile?.customerId) { setLoading(false); return; }
    const supabase = getSupabase();

    // Get meetings where this client is a participant
    const { data: participantRows, error: pErr } = await supabase
      .from('meeting_participants')
      .select('meeting_id')
      .eq('participant_type', 'client');

    if (pErr) {
      setError(pErr.message);
      setLoading(false);
      return;
    }

    const meetingIds = (participantRows || []).map((r: Record<string, unknown>) => r.meeting_id as string);
    if (meetingIds.length === 0) {
      setMeetings([]);
      setLoading(false);
      return;
    }

    const { data, error: fetchError } = await supabase
      .from('meetings')
      .select('*')
      .in('id', meetingIds)
      .order('scheduled_at', { ascending: false });

    if (fetchError) {
      setError(fetchError.message);
    } else {
      setMeetings((data || []).map(mapMeeting));
    }
    setLoading(false);
  }, [profile?.customerId]);

  useEffect(() => {
    fetchMeetings();
    if (!profile?.customerId) return;

    const supabase = getSupabase();
    const channel = supabase.channel('client-meetings')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'meetings' }, () => fetchMeetings())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchMeetings, profile?.customerId]);

  const joinMeeting = async (roomCode: string) => {
    setJoining(true);
    setError(null);

    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const response = await supabase.functions.invoke('meeting-room', {
        body: { action: 'join', roomCode },
      });

      if (response.error) throw new Error(response.error.message);
      return response.data;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to join meeting';
      setError(msg);
      return null;
    } finally {
      setJoining(false);
    }
  };

  // Categorize meetings
  const now = new Date();
  const active = meetings.filter(m => m.status === 'in_progress');
  const upcoming = meetings.filter(m =>
    m.status === 'scheduled' && m.scheduledAt && new Date(m.scheduledAt) >= now
  );
  const past = meetings.filter(m =>
    m.status === 'completed' || m.status === 'no_show' || m.status === 'cancelled'
    || (m.status === 'scheduled' && m.scheduledAt && new Date(m.scheduledAt) < now)
  );

  return { meetings, active, upcoming, past, loading, error, joining, joinMeeting };
}

// ============================================================================
// HOOK: useBookingTypes
// ============================================================================

export function useBookingTypes() {
  const { profile } = useAuth();
  const [bookingTypes, setBookingTypes] = useState<BookingTypeData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchBookingTypes = useCallback(async () => {
    if (!profile?.companyId) { setLoading(false); return; }

    try {
      const supabase = getSupabase();
      const response = await supabase.functions.invoke('meeting-booking', {
        body: {
          action: 'booking_types',
          companyId: profile.companyId,
          surface: 'client_portal',
        },
      });

      if (response.error) throw new Error(response.error.message);
      const types = response.data?.bookingTypes || response.data || [];
      setBookingTypes(Array.isArray(types) ? types.map(mapBookingType) : []);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load booking types';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [profile?.companyId]);

  useEffect(() => { fetchBookingTypes(); }, [fetchBookingTypes]);

  return { bookingTypes, loading, error };
}

// ============================================================================
// HOOK: useAvailability
// ============================================================================

export function useAvailability(bookingTypeSlug: string | null, startDate: string, endDate: string) {
  const { profile } = useAuth();
  const [slots, setSlots] = useState<TimeSlot[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchAvailability = useCallback(async () => {
    if (!profile?.companyId || !bookingTypeSlug) { setSlots([]); return; }
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();
      const response = await supabase.functions.invoke('meeting-booking', {
        body: {
          action: 'availability',
          companyId: profile.companyId,
          bookingTypeSlug,
          startDate,
          endDate,
        },
      });

      if (response.error) throw new Error(response.error.message);
      const available = response.data?.slots || response.data || [];
      setSlots(Array.isArray(available) ? available : []);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load availability';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [profile?.companyId, bookingTypeSlug, startDate, endDate]);

  useEffect(() => { fetchAvailability(); }, [fetchAvailability]);

  return { slots, loading, error, refresh: fetchAvailability };
}

// ============================================================================
// HOOK: useBookMeeting
// ============================================================================

export function useBookMeeting() {
  const { profile } = useAuth();
  const [booking, setBooking] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const bookMeeting = async (bookingTypeSlug: string, startTime: string) => {
    if (!profile?.companyId) return null;
    setBooking(true);
    setError(null);
    setSuccess(false);

    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const response = await supabase.functions.invoke('meeting-booking', {
        body: {
          action: 'book',
          companyId: profile.companyId,
          bookingTypeSlug,
          startTime,
          name: profile.displayName,
          email: profile.email,
        },
      });

      if (response.error) throw new Error(response.error.message);
      setSuccess(true);
      return response.data;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to book meeting';
      setError(msg);
      return null;
    } finally {
      setBooking(false);
    }
  };

  const reset = () => { setError(null); setSuccess(false); };

  return { bookMeeting, booking, error, success, reset };
}
