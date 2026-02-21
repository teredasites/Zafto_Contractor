'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================
export interface PhoneLine {
  id: string;
  companyId: string;
  userId: string | null;
  phoneNumber: string;
  lineType: 'main' | 'direct' | 'department' | 'fax';
  displayName: string | null;
  displayRole: string | null;
  callerIdName: string | null;
  isActive: boolean;
  voicemailEnabled: boolean;
  dndEnabled: boolean;
  status: 'online' | 'busy' | 'dnd' | 'offline';
}

export interface CallRecord {
  id: string;
  companyId: string;
  signalwireCallId: string | null;
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
  aiSummary: string | null;
  startedAt: string;
  answeredAt: string | null;
  endedAt: string | null;
  createdAt: string;
}

export interface Voicemail {
  id: string;
  companyId: string;
  callId: string | null;
  lineId: string;
  fromNumber: string;
  customerId: string | null;
  customerName?: string;
  audioPath: string;
  transcript: string | null;
  aiIntent: string | null;
  durationSeconds: number | null;
  isRead: boolean;
  createdAt: string;
}

export interface SmsMessage {
  id: string;
  companyId: string;
  direction: 'inbound' | 'outbound';
  fromNumber: string;
  toNumber: string;
  fromUserId: string | null;
  customerId: string | null;
  customerName?: string;
  jobId: string | null;
  body: string;
  mediaUrls: string[];
  isAutomated: boolean;
  status: string;
  createdAt: string;
}

export interface SmsThread {
  contactNumber: string;
  contactName: string | null;
  customerId: string | null;
  lastMessage: string;
  lastMessageAt: string;
  unreadCount: number;
  messages: SmsMessage[];
}

// ============================================================================
// MAPPERS
// ============================================================================
function mapLine(row: Record<string, unknown>): PhoneLine {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    userId: (row.user_id as string) || null,
    phoneNumber: row.phone_number as string,
    lineType: row.line_type as PhoneLine['lineType'],
    displayName: (row.display_name as string) || null,
    displayRole: (row.display_role as string) || null,
    callerIdName: (row.caller_id_name as string) || null,
    isActive: row.is_active as boolean,
    voicemailEnabled: row.voicemail_enabled as boolean,
    dndEnabled: row.dnd_enabled as boolean,
    status: row.status as PhoneLine['status'],
  };
}

function mapCall(row: Record<string, unknown>): CallRecord {
  const customer = row.customers as Record<string, unknown> | null;
  const job = row.jobs as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    signalwireCallId: (row.signalwire_call_id as string) || null,
    direction: row.direction as CallRecord['direction'],
    fromNumber: row.from_number as string,
    toNumber: row.to_number as string,
    fromUserId: (row.from_user_id as string) || null,
    toUserId: (row.to_user_id as string) || null,
    customerId: (row.customer_id as string) || null,
    customerName: (customer?.name as string) || undefined,
    jobId: (row.job_id as string) || null,
    jobTitle: (job?.title as string) || undefined,
    status: row.status as string,
    durationSeconds: (row.duration_seconds as number) || 0,
    recordingPath: (row.recording_path as string) || null,
    aiSummary: (row.ai_summary as string) || null,
    startedAt: row.started_at as string,
    answeredAt: (row.answered_at as string) || null,
    endedAt: (row.ended_at as string) || null,
    createdAt: row.created_at as string,
  };
}

function mapVoicemail(row: Record<string, unknown>): Voicemail {
  const customer = row.customers as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    callId: (row.call_id as string) || null,
    lineId: row.line_id as string,
    fromNumber: row.from_number as string,
    customerId: (row.customer_id as string) || null,
    customerName: (customer?.name as string) || undefined,
    audioPath: row.audio_path as string,
    transcript: (row.transcript as string) || null,
    aiIntent: (row.ai_intent as string) || null,
    durationSeconds: (row.duration_seconds as number) || null,
    isRead: row.is_read as boolean,
    createdAt: row.created_at as string,
  };
}

function mapMessage(row: Record<string, unknown>): SmsMessage {
  const customer = row.customers as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    direction: row.direction as SmsMessage['direction'],
    fromNumber: row.from_number as string,
    toNumber: row.to_number as string,
    fromUserId: (row.from_user_id as string) || null,
    customerId: (row.customer_id as string) || null,
    customerName: (customer?.name as string) || undefined,
    jobId: (row.job_id as string) || null,
    body: row.body as string,
    mediaUrls: (row.media_urls as string[]) || [],
    isAutomated: row.is_automated as boolean,
    status: row.status as string,
    createdAt: row.created_at as string,
  };
}

// ============================================================================
// HOOK: usePhone
// ============================================================================
export function usePhone() {
  const [calls, setCalls] = useState<CallRecord[]>([]);
  const [voicemails, setVoicemails] = useState<Voicemail[]>([]);
  const [lines, setLines] = useState<PhoneLine[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const [callsRes, voicemailsRes, linesRes] = await Promise.all([
        supabase
          .from('phone_calls')
          .select('*, customers(name), jobs(title)')
          .order('started_at', { ascending: false })
          .limit(100),
        supabase
          .from('phone_voicemails')
          .select('*, customers(name)')
          .order('created_at', { ascending: false })
          .limit(50),
        supabase
          .from('phone_lines')
          .select('*')
          .eq('is_active', true)
          .order('line_type', { ascending: true }),
      ]);

      if (callsRes.error) throw callsRes.error;
      if (voicemailsRes.error) throw voicemailsRes.error;
      if (linesRes.error) throw linesRes.error;

      setCalls((callsRes.data || []).map(mapCall));
      setVoicemails((voicemailsRes.data || []).map(mapVoicemail));
      setLines((linesRes.data || []).map(mapLine));
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
      .channel('phone-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_calls' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_voicemails' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_lines' }, () => fetchData())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchData]);

  const markVoicemailRead = async (id: string) => {
    const supabase = getSupabase();
    await supabase.from('phone_voicemails').update({ is_read: true }).eq('id', id);
  };

  // U22: Inbound call from unknown → auto-create lead
  const autoCreateLeadFromCall = async (callerNumber: string, direction: 'inbound' | 'outbound', durationSeconds?: number) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const companyId = user.app_metadata?.company_id;
    if (!companyId) return;

    // Check if number matches existing customer
    const { data: existingCustomer } = await supabase
      .from('customers')
      .select('id, name')
      .eq('company_id', companyId)
      .eq('phone', callerNumber)
      .is('deleted_at', null)
      .limit(1)
      .single();

    // Log to communication timeline
    await supabase.from('customer_communications').insert({
      company_id: companyId,
      customer_id: existingCustomer?.id || null,
      direction,
      channel: 'call',
      from_number: direction === 'inbound' ? callerNumber : null,
      to_number: direction === 'outbound' ? callerNumber : null,
      duration_seconds: durationSeconds || null,
      status: 'completed',
    });

    // If unknown caller, auto-create lead
    if (!existingCustomer && direction === 'inbound') {
      await supabase.from('leads').insert({
        company_id: companyId,
        created_by_user_id: user.id,
        name: `Caller ${callerNumber}`,
        phone: callerNumber,
        source: 'phone_call',
        stage: 'new',
        value: 0,
      });
    }
  };

  // U22: Log SMS to communication timeline
  const logSmsToTimeline = async (customerPhone: string, body: string, direction: 'inbound' | 'outbound') => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const companyId = user.app_metadata?.company_id;
    if (!companyId) return;

    const { data: customer } = await supabase
      .from('customers')
      .select('id')
      .eq('company_id', companyId)
      .eq('phone', customerPhone)
      .is('deleted_at', null)
      .limit(1)
      .single();

    await supabase.from('customer_communications').insert({
      company_id: companyId,
      customer_id: customer?.id || null,
      direction,
      channel: 'sms',
      from_number: direction === 'inbound' ? customerPhone : null,
      to_number: direction === 'outbound' ? customerPhone : null,
      message_body: body,
      status: 'delivered',
    });
  };

  return { calls, voicemails, lines, loading, error, refetch: fetchData, markVoicemailRead, autoCreateLeadFromCall, logSmsToTimeline };
}

// ============================================================================
// HOOK: useSmsThreads
// ============================================================================
export function useSmsThreads() {
  const [messages, setMessages] = useState<SmsMessage[]>([]);
  const [threads, setThreads] = useState<SmsThread[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchMessages = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('phone_messages')
        .select('*, customers(name)')
        .order('created_at', { ascending: false })
        .limit(500);

      if (err) throw err;

      const mapped = (data || []).map(mapMessage);
      setMessages(mapped);

      // Group into threads by contact number
      const threadMap = new Map<string, SmsMessage[]>();
      for (const msg of mapped) {
        const contactNum = msg.direction === 'inbound' ? msg.fromNumber : msg.toNumber;
        const existing = threadMap.get(contactNum) || [];
        existing.push(msg);
        threadMap.set(contactNum, existing);
      }

      const threadList: SmsThread[] = Array.from(threadMap.entries()).map(([num, msgs]) => {
        const sorted = msgs.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
        const latest = sorted[0];
        // Unread = inbound messages after our last outbound reply in this thread
        const lastOutbound = sorted.find(m => m.direction === 'outbound');
        const lastOutboundTime = lastOutbound ? new Date(lastOutbound.createdAt).getTime() : 0;
        const unread = sorted.filter(
          m => m.direction === 'inbound' && new Date(m.createdAt).getTime() > lastOutboundTime
        ).length;
        return {
          contactNumber: num,
          contactName: latest.customerName || null,
          customerId: latest.customerId,
          lastMessage: latest.body,
          lastMessageAt: latest.createdAt,
          unreadCount: unread,
          messages: sorted.reverse(),
        };
      });

      threadList.sort((a, b) => new Date(b.lastMessageAt).getTime() - new Date(a.lastMessageAt).getTime());
      setThreads(threadList);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load messages';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchMessages();

    const supabase = getSupabase();
    const channel = supabase
      .channel('sms-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_messages' }, () => fetchMessages())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchMessages]);

  const sendSms = async (toNumber: string, message: string, customerId?: string, jobId?: string) => {
    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) throw new Error('Not authenticated');

    const response = await supabase.functions.invoke('signalwire-sms', {
      body: { action: 'send', toNumber, message, customerId, jobId },
    });

    if (response.error) throw new Error(response.error.message);
    return response.data;
  };

  return { messages, threads, loading, error, refetch: fetchMessages, sendSms };
}
