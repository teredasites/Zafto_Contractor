'use client';

// ZAFTO Team Portal — Messaging Hook
// Created: Sprint FIELD1 (Session 131)
//
// Real-time conversations and messages for field employees.
// Uses conversations + messages + conversation_members tables.
// Actions via send-message + mark-messages-read Edge Functions.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ════════════════════════════════════════════════════════════════
// TYPES
// ════════════════════════════════════════════════════════════════

export type ConversationType = 'direct' | 'group' | 'job';

export interface Conversation {
  id: string;
  type: ConversationType;
  title: string | null;
  participantIds: string[];
  jobId: string | null;
  lastMessageAt: string | null;
  lastMessagePreview: string | null;
  lastSenderId: string | null;
  createdAt: string;
  unreadCount: number;
  isMuted: boolean;
  isPinned: boolean;
}

export interface ChatMessage {
  id: string;
  conversationId: string;
  senderId: string;
  senderName: string;
  content: string | null;
  messageType: 'text' | 'image' | 'file' | 'system';
  fileUrl: string | null;
  fileName: string | null;
  fileSize: number | null;
  replyToId: string | null;
  isEdited: boolean;
  createdAt: string;
}

export interface TeamMember {
  id: string;
  firstName: string;
  lastName: string;
  role: string;
}

// ════════════════════════════════════════════════════════════════
// MAPPERS
// ════════════════════════════════════════════════════════════════

function mapConversation(row: Record<string, unknown>): Conversation {
  const members = row.conversation_members as Record<string, unknown>[] | undefined;
  const memberData = (members?.length ? members[0] : {}) as Record<string, unknown>;

  return {
    id: row.id as string,
    type: (row.type as ConversationType) || 'direct',
    title: (row.title as string) || null,
    participantIds: (row.participant_ids as string[]) || [],
    jobId: (row.job_id as string) || null,
    lastMessageAt: (row.last_message_at as string) || null,
    lastMessagePreview: (row.last_message_preview as string) || null,
    lastSenderId: (row.last_sender_id as string) || null,
    createdAt: row.created_at as string,
    unreadCount: (memberData.unread_count as number) || 0,
    isMuted: (memberData.is_muted as boolean) || false,
    isPinned: (memberData.is_pinned as boolean) || false,
  };
}

function mapMessage(row: Record<string, unknown>): ChatMessage {
  return {
    id: row.id as string,
    conversationId: (row.conversation_id as string) || '',
    senderId: (row.sender_id as string) || '',
    senderName: (row.sender_name as string) || 'Unknown',
    content: (row.content as string) || null,
    messageType: (row.message_type as ChatMessage['messageType']) || 'text',
    fileUrl: (row.file_url as string) || null,
    fileName: (row.file_name as string) || null,
    fileSize: (row.file_size as number) || null,
    replyToId: (row.reply_to_id as string) || null,
    isEdited: (row.is_edited as boolean) || false,
    createdAt: row.created_at as string,
  };
}

// ════════════════════════════════════════════════════════════════
// CONVERSATIONS HOOK
// ════════════════════════════════════════════════════════════════

export function useConversations() {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchConversations = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const { data, error: err } = await supabase
        .from('conversations')
        .select('*, conversation_members!inner(unread_count, is_muted, is_pinned)')
        .contains('participant_ids', [user.id])
        .eq('conversation_members.user_id', user.id)
        .is('deleted_at', null)
        .order('last_message_at', { ascending: false, nullsFirst: false });

      if (err) throw err;
      setConversations((data || []).map(mapConversation));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load conversations');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchConversations();

    const supabase = getSupabase();
    const channel = supabase
      .channel('team-portal-conversations')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'conversations' }, () => fetchConversations())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'conversation_members' }, () => fetchConversations())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchConversations]);

  const totalUnread = conversations.reduce((sum, c) => sum + c.unreadCount, 0);

  return { conversations, totalUnread, loading, error, refetch: fetchConversations };
}

// ════════════════════════════════════════════════════════════════
// MESSAGES HOOK
// ════════════════════════════════════════════════════════════════

export function useMessages(conversationId: string | null) {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchMessages = useCallback(async () => {
    if (!conversationId) { setMessages([]); return; }
    try {
      setError(null);
      setLoading(true);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .is('deleted_at', null)
        .order('created_at', { ascending: true })
        .limit(100);

      if (err) throw err;
      setMessages((data || []).map(mapMessage));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load messages');
    } finally {
      setLoading(false);
    }
  }, [conversationId]);

  useEffect(() => {
    fetchMessages();

    if (!conversationId) return;

    const supabase = getSupabase();
    const channel = supabase
      .channel(`team-messages-${conversationId}`)
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'messages', filter: `conversation_id=eq.${conversationId}` },
        (payload: { new: Record<string, unknown> }) => {
          const newMsg = mapMessage(payload.new);
          setMessages(prev => [...prev, newMsg]);
        },
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchMessages, conversationId]);

  return { messages, loading, error, refetch: fetchMessages };
}

// ════════════════════════════════════════════════════════════════
// TEAM MEMBERS HOOK
// ════════════════════════════════════════════════════════════════

export function useTeamMembers() {
  const [members, setMembers] = useState<TeamMember[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let ignore = false;

    async function fetch() {
      try {
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('users')
          .select('id, first_name, last_name, role')
          .is('deleted_at', null)
          .order('first_name');

        if (err) throw err;
        if (!ignore) {
          setMembers((data || []).map((row: Record<string, unknown>) => ({
            id: row.id as string,
            firstName: (row.first_name as string) || '',
            lastName: (row.last_name as string) || '',
            role: (row.role as string) || '',
          })));
        }
      } catch {
        // Non-critical
      } finally {
        if (!ignore) setLoading(false);
      }
    }

    fetch();
    return () => { ignore = true; };
  }, []);

  return { members, loading };
}

// ════════════════════════════════════════════════════════════════
// ACTIONS
// ════════════════════════════════════════════════════════════════

export async function sendMessage(conversationId: string, content: string): Promise<ChatMessage> {
  const supabase = getSupabase();
  const response = await supabase.functions.invoke('send-message', {
    body: { conversation_id: conversationId, content, message_type: 'text' },
  });
  if (response.error) throw new Error(response.error.message);
  if (response.data?.error) throw new Error(response.data.error);
  return mapMessage(response.data.message);
}

export async function markRead(conversationId: string): Promise<void> {
  const supabase = getSupabase();
  const response = await supabase.functions.invoke('mark-messages-read', {
    body: { conversation_id: conversationId },
  });
  if (response.error) throw new Error(response.error.message);
}

export async function createDirectConversation(otherUserId: string): Promise<Conversation> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');
  const companyId = user.app_metadata?.company_id;
  if (!companyId) throw new Error('No company');

  // Check existing
  const { data: existing } = await supabase
    .from('conversations')
    .select()
    .eq('type', 'direct')
    .eq('company_id', companyId)
    .contains('participant_ids', [user.id, otherUserId])
    .is('deleted_at', null)
    .maybeSingle();

  if (existing) return mapConversation(existing);

  const response = await supabase.functions.invoke('send-message', {
    body: {
      action: 'create_conversation',
      type: 'direct',
      participant_ids: [otherUserId],
    },
  });
  if (response.error) throw new Error(response.error.message);
  if (response.data?.error) throw new Error(response.data.error);
  return mapConversation(response.data.conversation);
}

export async function createGroupConversation(title: string, participantIds: string[]): Promise<Conversation> {
  const supabase = getSupabase();
  const response = await supabase.functions.invoke('send-message', {
    body: {
      action: 'create_conversation',
      type: 'group',
      title,
      participant_ids: participantIds,
    },
  });
  if (response.error) throw new Error(response.error.message);
  if (response.data?.error) throw new Error(response.data.error);
  return mapConversation(response.data.conversation);
}
