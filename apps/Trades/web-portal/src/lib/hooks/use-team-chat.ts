'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface TeamMessage {
  id: string;
  companyId: string;
  channelType: string;
  channelId: string;
  jobId: string | null;
  senderId: string;
  senderName: string;
  messageText: string | null;
  attachmentPath: string | null;
  attachmentType: string | null;
  mentionedUserIds: string[];
  isEdited: boolean;
  isDeleted: boolean;
  createdAt: string;
}

export interface ChatChannel {
  channelType: string;
  channelId: string;
  displayName: string;
  lastMessage: string;
  lastSender: string;
  lastAt: string;
  unreadCount: number;
}

function mapMessage(row: Record<string, unknown>): TeamMessage {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    channelType: row.channel_type as string,
    channelId: row.channel_id as string,
    jobId: (row.job_id as string) || null,
    senderId: row.sender_id as string,
    senderName: row.sender_name as string,
    messageText: (row.message_text as string) || null,
    attachmentPath: (row.attachment_path as string) || null,
    attachmentType: (row.attachment_type as string) || null,
    mentionedUserIds: (row.mentioned_user_ids as string[]) || [],
    isEdited: (row.is_edited as boolean) || false,
    isDeleted: (row.is_deleted as boolean) || false,
    createdAt: row.created_at as string,
  };
}

export function useTeamChat() {
  const [channels, setChannels] = useState<ChatChannel[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchChannels = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      const response = await supabase.functions.invoke('team-chat', {
        body: { action: 'channels' },
      });
      if (response.error) throw new Error(response.error.message);
      setChannels(response.data?.channels || []);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load channels');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchChannels();

    const supabase = getSupabase();
    const channel = supabase
      .channel('team-messages-changes')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'team_messages' }, () => fetchChannels())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchChannels]);

  const sendMessage = async (channelType: string, channelId: string, messageText: string) => {
    const supabase = getSupabase();
    const response = await supabase.functions.invoke('team-chat', {
      body: { action: 'send', channelType, channelId, messageText },
    });
    if (response.error) throw new Error(response.error.message);
    return response.data;
  };

  const getMessages = async (channelType: string, channelId: string, limit?: number): Promise<TeamMessage[]> => {
    const supabase = getSupabase();
    const response = await supabase.functions.invoke('team-chat', {
      body: { action: 'list', channelType, channelId, limit },
    });
    if (response.error) throw new Error(response.error.message);
    return (response.data?.messages || []).map(mapMessage);
  };

  const markRead = async (channelType: string, channelId: string) => {
    const supabase = getSupabase();
    await supabase.functions.invoke('team-chat', {
      body: { action: 'mark_read', channelType, channelId },
    });
  };

  const totalUnread = channels.reduce((sum, c) => sum + c.unreadCount, 0);

  return { channels, totalUnread, loading, error, sendMessage, getMessages, markRead, refetch: fetchChannels };
}
