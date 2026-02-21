'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// ============================================================================
// TYPES
// ============================================================================
export interface SmsMessageData {
  id: string;
  direction: 'inbound' | 'outbound';
  fromNumber: string;
  toNumber: string;
  body: string;
  mediaUrls: string[];
  status: string;
  createdAt: string;
}

// ============================================================================
// MAPPER
// ============================================================================
function mapMessage(row: Record<string, unknown>): SmsMessageData {
  return {
    id: row.id as string,
    direction: row.direction as SmsMessageData['direction'],
    fromNumber: row.from_number as string,
    toNumber: row.to_number as string,
    body: row.body as string,
    mediaUrls: (row.media_urls as string[]) || [],
    status: row.status as string,
    createdAt: row.created_at as string,
  };
}

// ============================================================================
// HOOK: useMessages
// ============================================================================
export function useMessages() {
  const { profile } = useAuth();
  const [messages, setMessages] = useState<SmsMessageData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [sending, setSending] = useState(false);
  const scrollRef = useRef<HTMLDivElement | null>(null);

  const fetchMessages = useCallback(async () => {
    if (!profile?.customerId) { setLoading(false); return; }
    const supabase = getSupabase();

    const { data, error: fetchError } = await supabase
      .from('phone_messages')
      .select('*')
      .eq('customer_id', profile.customerId)
      .order('created_at', { ascending: true });

    if (fetchError) {
      setError(fetchError.message);
    } else {
      setMessages((data || []).map(mapMessage));
    }
    setLoading(false);
  }, [profile?.customerId]);

  useEffect(() => {
    fetchMessages();
    if (!profile?.customerId) return;

    const supabase = getSupabase();
    const channel = supabase.channel('client-messages')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_messages' }, () => fetchMessages())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchMessages, profile?.customerId]);

  const sendMessage = async (message: string) => {
    if (!profile?.customerId || !profile?.companyId || !message.trim()) return;
    setSending(true);
    setError(null);

    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      // Resolve the company's primary phone line to get the toNumber
      const { data: line } = await supabase
        .from('phone_lines')
        .select('phone_number')
        .eq('company_id', profile.companyId)
        .eq('is_active', true)
        .limit(1)
        .single();

      if (!line?.phone_number) {
        throw new Error('This company does not have a phone number configured for messaging.');
      }

      const response = await supabase.functions.invoke('signalwire-sms', {
        body: {
          action: 'send',
          toNumber: line.phone_number,
          message: message.trim(),
          customerId: profile.customerId,
        },
      });

      if (response.error) throw new Error(response.error.message);

      // Refetch to include the new message
      await fetchMessages();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to send message';
      setError(msg);
    } finally {
      setSending(false);
    }
  };

  return { messages, loading, error, sending, sendMessage, scrollRef };
}
