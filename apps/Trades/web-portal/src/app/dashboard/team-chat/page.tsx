'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import {
  MessageSquare,
  Send,
  Hash,
  Briefcase,
  Users,
  User,
  Loader2,
  Paperclip,
  Image,
} from 'lucide-react';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { useTeamChat, type ChatChannel, type TeamMessage } from '@/lib/hooks/use-team-chat';
import { cn } from '@/lib/utils';

const channelTypeIcons: Record<string, typeof Hash> = {
  job: Briefcase,
  crew: Users,
  company: Hash,
  direct: User,
};

function ChannelItem({
  channel,
  isActive,
  onClick,
}: {
  channel: ChatChannel;
  isActive: boolean;
  onClick: () => void;
}) {
  const Icon = channelTypeIcons[channel.channelType] || Hash;
  return (
    <button
      onClick={onClick}
      className={cn(
        'w-full flex items-center gap-2 px-3 py-2.5 text-left hover:bg-zinc-800/50 transition-colors',
        isActive && 'bg-zinc-800'
      )}
    >
      <Icon className="h-4 w-4 text-zinc-500 flex-shrink-0" />
      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between">
          <span className={cn('text-sm truncate', isActive ? 'text-zinc-100' : 'text-zinc-300')}>
            {channel.displayName}
          </span>
          {channel.unreadCount > 0 && (
            <Badge className="bg-emerald-500/20 text-emerald-400 border-0 text-xs px-1.5 min-w-[20px] text-center">
              {channel.unreadCount}
            </Badge>
          )}
        </div>
        <p className="text-xs text-zinc-500 truncate mt-0.5">
          {channel.lastSender}: {channel.lastMessage}
        </p>
      </div>
    </button>
  );
}

function MessageBubble({ message, isOwn }: { message: TeamMessage; isOwn: boolean }) {
  return (
    <div className={cn('flex gap-2 px-4 py-1', isOwn ? 'flex-row-reverse' : 'flex-row')}>
      <div className={cn(
        'max-w-[70%] rounded-lg px-3 py-2',
        isOwn ? 'bg-emerald-600/20 text-zinc-100' : 'bg-zinc-800 text-zinc-200'
      )}>
        {!isOwn && (
          <p className="text-xs text-emerald-400 font-medium mb-0.5">{message.senderName}</p>
        )}
        {message.messageText && (
          <p className="text-sm whitespace-pre-wrap">{message.messageText}</p>
        )}
        {message.attachmentPath && (
          <div className="flex items-center gap-1 text-xs text-zinc-400 mt-1">
            {message.attachmentType === 'image' ? <Image className="h-3 w-3" /> : <Paperclip className="h-3 w-3" />}
            Attachment
          </div>
        )}
        <div className="flex items-center gap-1 mt-1">
          <span className="text-[10px] text-zinc-500">
            {new Date(message.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </span>
          {message.isEdited && <span className="text-[10px] text-zinc-600">(edited)</span>}
        </div>
      </div>
    </div>
  );
}

export default function TeamChatPage() {
  const { channels, totalUnread, loading, error, sendMessage, getMessages, markRead } = useTeamChat();
  const [activeChannel, setActiveChannel] = useState<ChatChannel | null>(null);
  const [messages, setMessages] = useState<TeamMessage[]>([]);
  const [messagesLoading, setMessagesLoading] = useState(false);
  const [compose, setCompose] = useState('');
  const [sending, setSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Auto-select first channel
  useEffect(() => {
    if (channels.length > 0 && !activeChannel) {
      setActiveChannel(channels[0]);
    }
  }, [channels, activeChannel]);

  // Load messages when channel changes
  const loadMessages = useCallback(async () => {
    if (!activeChannel) return;
    try {
      setMessagesLoading(true);
      const msgs = await getMessages(activeChannel.channelType, activeChannel.channelId, 50);
      setMessages(msgs);
      await markRead(activeChannel.channelType, activeChannel.channelId);
    } catch {
      // Non-critical
    } finally {
      setMessagesLoading(false);
    }
  }, [activeChannel, getMessages, markRead]);

  useEffect(() => {
    loadMessages();
  }, [loadMessages]);

  // Scroll to bottom on new messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async () => {
    if (!compose.trim() || !activeChannel || sending) return;
    try {
      setSending(true);
      await sendMessage(activeChannel.channelType, activeChannel.channelId, compose.trim());
      setCompose('');
      await loadMessages();
    } catch {
      // Could show error toast
    } finally {
      setSending(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <>
      <CommandPalette />
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-zinc-100">Team Chat</h1>
            <p className="text-sm text-zinc-500 mt-1">
              Internal messaging by job, crew, or company
              {totalUnread > 0 && (
                <Badge className="ml-2 bg-emerald-500/20 text-emerald-400 border-0">{totalUnread} unread</Badge>
              )}
            </p>
          </div>
        </div>

        <Card className="bg-zinc-900 border-zinc-800 overflow-hidden">
          <div className="flex h-[calc(100vh-220px)]">
            {/* Channel List */}
            <div className="w-72 border-r border-zinc-800 flex flex-col">
              <div className="p-3 border-b border-zinc-800">
                <p className="text-xs font-medium text-zinc-500 uppercase tracking-wide">Channels</p>
              </div>
              <div className="flex-1 overflow-y-auto">
                {loading ? (
                  <div className="flex items-center justify-center py-8 text-zinc-500">
                    <Loader2 className="h-4 w-4 animate-spin mr-2" />Loading...
                  </div>
                ) : channels.length === 0 ? (
                  <div className="p-4 text-center text-zinc-500 text-sm">
                    <MessageSquare className="h-6 w-6 mx-auto mb-2 opacity-50" />
                    No conversations yet
                  </div>
                ) : (
                  channels.map(ch => (
                    <ChannelItem
                      key={`${ch.channelType}:${ch.channelId}`}
                      channel={ch}
                      isActive={activeChannel?.channelId === ch.channelId && activeChannel?.channelType === ch.channelType}
                      onClick={() => setActiveChannel(ch)}
                    />
                  ))
                )}
              </div>
            </div>

            {/* Messages Area */}
            <div className="flex-1 flex flex-col">
              {activeChannel ? (
                <>
                  {/* Channel Header */}
                  <div className="px-4 py-3 border-b border-zinc-800 flex items-center gap-2">
                    {(() => { const Icon = channelTypeIcons[activeChannel.channelType] || Hash; return <Icon className="h-4 w-4 text-zinc-500" />; })()}
                    <span className="font-medium text-zinc-100">{activeChannel.displayName}</span>
                    <Badge className="bg-zinc-800 text-zinc-400 border-zinc-700 text-xs">{activeChannel.channelType}</Badge>
                  </div>

                  {/* Messages */}
                  <div className="flex-1 overflow-y-auto py-2">
                    {messagesLoading ? (
                      <div className="flex items-center justify-center h-full text-zinc-500">
                        <Loader2 className="h-5 w-5 animate-spin" />
                      </div>
                    ) : messages.length === 0 ? (
                      <div className="flex items-center justify-center h-full text-zinc-500 text-sm">
                        No messages yet. Start the conversation.
                      </div>
                    ) : (
                      messages.map(msg => (
                        <MessageBubble
                          key={msg.id}
                          message={msg}
                          isOwn={false} // Would compare to current user ID
                        />
                      ))
                    )}
                    <div ref={messagesEndRef} />
                  </div>

                  {/* Compose */}
                  <div className="p-3 border-t border-zinc-800">
                    <div className="flex items-end gap-2">
                      <textarea
                        value={compose}
                        onChange={e => setCompose(e.target.value)}
                        onKeyDown={handleKeyDown}
                        placeholder="Type a message..."
                        className="flex-1 bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-zinc-100 placeholder:text-zinc-500 resize-none focus:outline-none focus:ring-1 focus:ring-emerald-500/50"
                        rows={1}
                      />
                      <Button
                        size="sm"
                        onClick={handleSend}
                        disabled={!compose.trim() || sending}
                        className="gap-1"
                      >
                        <Send className="h-3.5 w-3.5" />
                        Send
                      </Button>
                    </div>
                  </div>
                </>
              ) : (
                <div className="flex items-center justify-center h-full text-zinc-500">
                  <div className="text-center">
                    <MessageSquare className="h-8 w-8 mx-auto mb-2 opacity-50" />
                    <p>Select a channel to start chatting</p>
                  </div>
                </div>
              )}
            </div>
          </div>
        </Card>
      </div>
    </>
  );
}
