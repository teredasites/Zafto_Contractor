'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface CallRecord {
  id: string;
  direction: 'inbound' | 'outbound' | 'internal';
  fromNumber: string;
  toNumber: string;
  fromUserId: string | null;
  toUserId: string | null;
  customerId: string | null;
  customerName?: string;
  jobId: string | null;
  jobTitle?: string;
  status: string;
  durationSeconds: number;
  recordingPath: string | null;
  startedAt: string;
  answeredAt: string | null;
  endedAt: string | null;
  createdAt: string;
}

export interface Voicemail {
  id: string;
  callId: string | null;
  lineId: string;
  fromNumber: string;
  customerId: string | null;
  customerName?: string;
  audioPath: string;
  transcript: string | null;
  durationSeconds: number | null;
  isRead: boolean;
  createdAt: string;
}

export interface SmsMessage {
  id: string;
  direction: 'inbound' | 'outbound';
  fromNumber: string;
  toNumber: string;
  fromUserId: string | null;
  customerId: string | null;
  customerName?: string;
  jobId: string | null;
  body: string;
  status: string;
  createdAt: string;
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapCall(row: Record<string, unknown>): CallRecord {
  const customer = row.customers as Record<string, unknown> | null;
  const job = row.jobs as Record<string, unknown> | null;
  return {
    id: row.id as string,
    direction: row.direction as CallRecord['direction'],
    fromNumber: (row.from_number as string) || '',
    toNumber: (row.to_number as string) || '',
    fromUserId: (row.from_user_id as string) || null,
    toUserId: (row.to_user_id as string) || null,
    customerId: (row.customer_id as string) || null,
    customerName: (customer?.name as string) || undefined,
    jobId: (row.job_id as string) || null,
    jobTitle: (job?.title as string) || undefined,
    status: (row.status as string) || '',
    durationSeconds: (row.duration_seconds as number) || 0,
    recordingPath: (row.recording_path as string) || null,
    startedAt: (row.started_at as string) || '',
    answeredAt: (row.answered_at as string) || null,
    endedAt: (row.ended_at as string) || null,
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

function mapVoicemail(row: Record<string, unknown>): Voicemail {
  const customer = row.customers as Record<string, unknown> | null;
  return {
    id: row.id as string,
    callId: (row.call_id as string) || null,
    lineId: (row.line_id as string) || '',
    fromNumber: (row.from_number as string) || '',
    customerId: (row.customer_id as string) || null,
    customerName: (customer?.name as string) || undefined,
    audioPath: (row.audio_path as string) || '',
    transcript: (row.transcript as string) || null,
    durationSeconds: (row.duration_seconds as number) || null,
    isRead: (row.is_read as boolean) || false,
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

function mapMessage(row: Record<string, unknown>): SmsMessage {
  const customer = row.customers as Record<string, unknown> | null;
  return {
    id: row.id as string,
    direction: row.direction as SmsMessage['direction'],
    fromNumber: (row.from_number as string) || '',
    toNumber: (row.to_number as string) || '',
    fromUserId: (row.from_user_id as string) || null,
    customerId: (row.customer_id as string) || null,
    customerName: (customer?.name as string) || undefined,
    jobId: (row.job_id as string) || null,
    body: (row.body as string) || '',
    status: (row.status as string) || '',
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

// ============================================================================
// HOOK: usePhone (team portal — scoped to current user)
// ============================================================================

export function usePhone() {
  const [calls, setCalls] = useState<CallRecord[]>([]);
  const [voicemails, setVoicemails] = useState<Voicemail[]>([]);
  const [messages, setMessages] = useState<SmsMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      // Fetch calls where current user is sender or recipient
      const [callsRes, voicemailsRes, messagesRes] = await Promise.all([
        supabase
          .from('phone_calls')
          .select('*, customers(name), jobs(title)')
          .or(`from_user_id.eq.${user.id},to_user_id.eq.${user.id}`)
          .order('started_at', { ascending: false })
          .limit(50),
        supabase
          .from('phone_voicemails')
          .select('*, customers(name)')
          .eq('line_id', user.id)
          .order('created_at', { ascending: false })
          .limit(30),
        supabase
          .from('phone_messages')
          .select('*, customers(name)')
          .eq('from_user_id', user.id)
          .order('created_at', { ascending: false })
          .limit(50),
      ]);

      if (callsRes.error) throw callsRes.error;
      if (voicemailsRes.error) throw voicemailsRes.error;
      if (messagesRes.error) throw messagesRes.error;

      setCalls((callsRes.data || []).map(mapCall));
      setVoicemails((voicemailsRes.data || []).map(mapVoicemail));
      setMessages((messagesRes.data || []).map(mapMessage));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load phone data';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();

    const supabase = getSupabase();
    const channel = supabase
      .channel('team-phone')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_calls' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_voicemails' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_messages' }, () => fetchData())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchData]);

  const markVoicemailRead = async (id: string) => {
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase.from('phone_voicemails').update({ is_read: true }).eq('id', id);
      if (err) throw err;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to mark voicemail read';
      setError(msg);
    }
  };

  const sendSms = async (toNumber: string, message: string) => {
    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) throw new Error('Not authenticated');

    const response = await supabase.functions.invoke('signalwire-sms', {
      body: { action: 'send', toNumber, message },
    });

    if (response.error) throw new Error(response.error.message);
    await fetchData();
    return response.data;
  };

  return { calls, voicemails, messages, loading, error, sendSms, markVoicemailRead, refetch: fetchData };
}
