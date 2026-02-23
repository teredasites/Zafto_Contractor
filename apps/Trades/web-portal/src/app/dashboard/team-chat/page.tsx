'use client';

// ZAFTO Team Chat — Conversation-Based Messaging (CRM)
// Upgraded: Sprint FIELD1 (Session 131)
//
// Split-view: conversation list (left) + chat panel (right).
// Direct messages, group chats, job-scoped conversations.
// Real-time message delivery via Supabase Realtime.

import { useState, useEffect, useRef, useCallback } from 'react';
import {
  MessageSquare,
  Send,
  Users,
  User,
  Briefcase,
  Loader2,
  Paperclip,
  Image,
  Plus,
  Search,
  X,
  Check,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import {
  useConversations,
  useMessages,
  useTeamMembers,
  sendChatMessage,
  markConversationRead,
  createDirectConversation,
  createGroupConversation,
  type Conversation,
  type ChatMessage,
  type TeamMember,
} from '@/lib/hooks/use-team-chat';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { getSupabase } from '@/lib/supabase';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

// ════════════════════════════════════════════════════════════════
// CONVERSATION LIST ITEM
// ════════════════════════════════════════════════════════════════

const typeIcons: Record<string, typeof User> = {
  direct: User,
  group: Users,
  job: Briefcase,
};

function ConversationItem({
  conversation,
  isActive,
  onClick,
  currentUserId,
  memberMap,
}: {
  conversation: Conversation;
  isActive: boolean;
  onClick: () => void;
  currentUserId: string;
  memberMap: Map<string, TeamMember>;
}) {
  const Icon = typeIcons[conversation.type] || MessageSquare;

  // Display title: for direct conversations, show the other person's name
  let displayTitle = conversation.title || 'Untitled';
  if (conversation.type === 'direct') {
    const otherId = conversation.participantIds.find(id => id !== currentUserId);
    if (otherId) {
      const other = memberMap.get(otherId);
      if (other) displayTitle = `${other.firstName} ${other.lastName}`.trim() || 'Unknown';
    }
  }

  const timeLabel = conversation.lastMessageAt
    ? formatRelative(new Date(conversation.lastMessageAt))
    : '';

  return (
    <button
      onClick={onClick}
      className={cn(
        'w-full flex items-center gap-2.5 px-3 py-2.5 text-left hover:bg-zinc-800/50 transition-colors',
        isActive && 'bg-zinc-800',
      )}
    >
      <div className={cn(
        'flex items-center justify-center w-9 h-9 rounded-full flex-shrink-0',
        isActive ? 'bg-emerald-500/20' : 'bg-zinc-800',
      )}>
        <Icon className={cn('h-4 w-4', isActive ? 'text-emerald-400' : 'text-zinc-500')} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between">
          <span className={cn(
            'text-sm truncate',
            conversation.unreadCount > 0 ? 'text-zinc-100 font-semibold' : isActive ? 'text-zinc-100' : 'text-zinc-300',
          )}>
            {displayTitle}
          </span>
          <div className="flex items-center gap-1.5 flex-shrink-0 ml-2">
            {timeLabel && (
              <span className={cn(
                'text-[10px]',
                conversation.unreadCount > 0 ? 'text-emerald-400' : 'text-zinc-600',
              )}>
                {timeLabel}
              </span>
            )}
            {conversation.unreadCount > 0 && (
              <Badge className="bg-emerald-500/20 text-emerald-400 border-0 text-[10px] px-1.5 min-w-[18px] text-center">
                {conversation.unreadCount > 99 ? '99+' : conversation.unreadCount}
              </Badge>
            )}
          </div>
        </div>
        {conversation.lastMessagePreview && (
          <p className={cn(
            'text-xs truncate mt-0.5',
            conversation.unreadCount > 0 ? 'text-zinc-400' : 'text-zinc-600',
          )}>
            {conversation.lastMessagePreview}
          </p>
        )}
      </div>
    </button>
  );
}

// ════════════════════════════════════════════════════════════════
// MESSAGE BUBBLE
// ════════════════════════════════════════════════════════════════

function MessageBubble({ message, isOwn }: { message: ChatMessage; isOwn: boolean }) {
  if (message.messageType === 'system') {
    return (
      <div className="text-center py-1.5">
        <span className="text-[11px] text-zinc-600 bg-zinc-800/50 px-2.5 py-1 rounded-full">
          {message.content}
        </span>
      </div>
    );
  }

  return (
    <div className={cn('flex gap-2 px-4 py-0.5', isOwn ? 'flex-row-reverse' : 'flex-row')}>
      <div className={cn(
        'max-w-[70%] rounded-xl px-3.5 py-2',
        isOwn ? 'bg-emerald-600/20 text-zinc-100' : 'bg-zinc-800 text-zinc-200',
      )}>
        {!isOwn && (
          <p className="text-[11px] text-emerald-400 font-medium mb-0.5">{message.senderName}</p>
        )}
        {message.fileUrl && message.messageType === 'image' && (
          <div className="mb-1.5 rounded-lg overflow-hidden">
            <img
              src={message.fileUrl}
              alt={message.fileName || 'Image'}
              className="max-w-full max-h-60 object-cover"
              loading="lazy"
            />
          </div>
        )}
        {message.fileUrl && message.messageType === 'file' && (
          <div className="flex items-center gap-1.5 text-xs text-zinc-400 mb-1">
            <Paperclip className="h-3 w-3" />
            <span className="truncate underline">{message.fileName || 'File'}</span>
          </div>
        )}
        {message.content && (
          <p className="text-sm whitespace-pre-wrap break-words">{message.content}</p>
        )}
        <div className="flex items-center gap-1 mt-1">
          <span className="text-[10px] text-zinc-500">
            {formatTimeLocale(message.createdAt)}
          </span>
          {message.isEdited && <span className="text-[10px] text-zinc-600">(edited)</span>}
        </div>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// NEW CONVERSATION MODAL
// ════════════════════════════════════════════════════════════════

function NewConversationModal({
  onClose,
  onCreated,
  members,
  currentUserId,
}: {
  onClose: () => void;
  onCreated: (conv: Conversation) => void;
  members: TeamMember[];
  currentUserId: string;
}) {
  const { t } = useTranslation();
  const [mode, setMode] = useState<'direct' | 'group'>('direct');
  const [search, setSearch] = useState('');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [groupName, setGroupName] = useState('');
  const [creating, setCreating] = useState(false);

  const filteredMembers = members.filter(m => {
    if (m.id === currentUserId) return false;
    if (!search) return true;
    const name = `${m.firstName} ${m.lastName}`.toLowerCase();
    return name.includes(search.toLowerCase());
  });

  const handleDirectSelect = async (member: TeamMember) => {
    try {
      setCreating(true);
      const conv = await createDirectConversation(member.id);
      onCreated(conv);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to start conversation');
      setCreating(false);
    }
  };

  const handleCreateGroup = async () => {
    if (selectedIds.size < 2) {
      alert('Select at least 2 members');
      return;
    }
    if (!groupName.trim()) {
      alert('Enter a group name');
      return;
    }
    try {
      setCreating(true);
      const conv = await createGroupConversation(groupName.trim(), Array.from(selectedIds));
      onCreated(conv);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to create group');
      setCreating(false);
    }
  };

  const toggleMember = (id: string) => {
    setSelectedIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  return (
    <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4">
      <Card className="bg-zinc-900 border-zinc-800 w-full max-w-md max-h-[80vh] flex flex-col overflow-hidden">
        {/* Header */}
        <div className="px-4 py-3 border-b border-zinc-800 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-zinc-100">
            {mode === 'direct' ? 'New Message' : 'New Group'}
          </h2>
          <div className="flex items-center gap-2">
            {mode === 'direct' ? (
              <Button variant="ghost" size="sm" onClick={() => setMode('group')}>
                <Users className="h-4 w-4 mr-1" /> Group
              </Button>
            ) : (
              <Button
                size="sm"
                onClick={handleCreateGroup}
                disabled={creating || selectedIds.size < 2 || !groupName.trim()}
              >
                {creating ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Create'}
              </Button>
            )}
            <button onClick={onClose} className="p-1 hover:bg-zinc-800 rounded">
              <X className="h-4 w-4 text-zinc-500" />
            </button>
          </div>
        </div>

        {/* Group name input */}
        {mode === 'group' && (
          <div className="px-4 py-2 border-b border-zinc-800">
            <input
              value={groupName}
              onChange={e => setGroupName(e.target.value)}
              placeholder="Group name..."
              className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-zinc-100 placeholder:text-zinc-500 focus:outline-none focus:ring-1 focus:ring-emerald-500/50"
            />
            {selectedIds.size > 0 && (
              <div className="flex flex-wrap gap-1.5 mt-2">
                {Array.from(selectedIds).map(id => {
                  const m = members.find(mm => mm.id === id);
                  if (!m) return null;
                  return (
                    <span
                      key={id}
                      className="flex items-center gap-1 text-xs bg-emerald-500/10 text-emerald-400 px-2 py-1 rounded-full"
                    >
                      {m.firstName} {m.lastName}
                      <button onClick={() => toggleMember(id)}>
                        <X className="h-3 w-3" />
                      </button>
                    </span>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* Search */}
        <div className="px-4 py-2 border-b border-zinc-800">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-zinc-500" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search team members..."
              className="w-full bg-zinc-800 border border-zinc-700 rounded-lg pl-9 pr-3 py-2 text-sm text-zinc-100 placeholder:text-zinc-500 focus:outline-none focus:ring-1 focus:ring-emerald-500/50"
            />
          </div>
        </div>

        {/* Member list */}
        <div className="flex-1 overflow-y-auto">
          {creating && mode === 'direct' ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="h-5 w-5 animate-spin text-zinc-500" />
            </div>
          ) : filteredMembers.length === 0 ? (
            <div className="text-center py-8 text-zinc-500 text-sm">{t('dispatch.noTeamMembers')}</div>
          ) : (
            filteredMembers.map(member => {
              const isSelected = selectedIds.has(member.id);
              const name = `${member.firstName} ${member.lastName}`.trim() || 'Unknown';

              return (
                <button
                  key={member.id}
                  onClick={() => mode === 'direct' ? handleDirectSelect(member) : toggleMember(member.id)}
                  className="w-full flex items-center gap-3 px-4 py-2.5 hover:bg-zinc-800/50 transition-colors text-left"
                >
                  <div className="w-8 h-8 rounded-full bg-zinc-800 flex items-center justify-center text-xs font-medium text-zinc-400">
                    {name[0]?.toUpperCase() || '?'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-zinc-200 truncate">{name}</p>
                    <p className="text-xs text-zinc-600 truncate">{member.role}</p>
                  </div>
                  {mode === 'group' && (
                    <div className={cn(
                      'w-5 h-5 rounded border flex items-center justify-center',
                      isSelected ? 'bg-emerald-500 border-emerald-500' : 'border-zinc-700',
                    )}>
                      {isSelected && <Check className="h-3 w-3 text-white" />}
                    </div>
                  )}
                </button>
              );
            })
          )}
        </div>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// MAIN PAGE
// ════════════════════════════════════════════════════════════════

export default function TeamChatPage() {
  const { t } = useTranslation();
  const { conversations, totalUnread, loading, error, refetch } = useConversations();
  const { members } = useTeamMembers();
  const [activeConvId, setActiveConvId] = useState<string | null>(null);
  const { messages, loading: messagesLoading } = useMessages(activeConvId);
  const [compose, setCompose] = useState('');
  const [sending, setSending] = useState(false);
  const [showNewConversation, setShowNewConversation] = useState(false);
  const [searchFilter, setSearchFilter] = useState('');
  const [currentUserId, setCurrentUserId] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Get current user ID
  useEffect(() => {
    async function fetchUser() {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (user) setCurrentUserId(user.id);
    }
    fetchUser();
  }, []);

  // Build member map for name lookups
  const memberMap = new Map(members.map(m => [m.id, m]));

  // Active conversation object
  const activeConv = conversations.find(c => c.id === activeConvId) || null;

  // Auto-select first conversation
  useEffect(() => {
    if (conversations.length > 0 && !activeConvId) {
      setActiveConvId(conversations[0].id);
    }
  }, [conversations, activeConvId]);

  // Mark as read when selecting a conversation
  useEffect(() => {
    if (activeConvId && activeConv && activeConv.unreadCount > 0) {
      markConversationRead(activeConvId).then(() => refetch()).catch(() => {});
    }
  }, [activeConvId]); // eslint-disable-line react-hooks/exhaustive-deps

  // Scroll to bottom on new messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Filtered conversations
  const filteredConversations = searchFilter
    ? conversations.filter(c => {
        const title = c.title?.toLowerCase() || '';
        const preview = c.lastMessagePreview?.toLowerCase() || '';
        const q = searchFilter.toLowerCase();
        // Check member names too
        if (c.type === 'direct') {
          const otherId = c.participantIds.find(id => id !== currentUserId);
          const other = otherId ? memberMap.get(otherId) : null;
          if (other) {
            const name = `${other.firstName} ${other.lastName}`.toLowerCase();
            if (name.includes(q)) return true;
          }
        }
        return title.includes(q) || preview.includes(q);
      })
    : conversations;

  // Send message
  const handleSend = async () => {
    if (!compose.trim() || !activeConvId || sending) return;
    const text = compose.trim();
    setSending(true);
    setCompose('');
    try {
      await sendChatMessage(activeConvId, text);
    } catch {
      setCompose(text); // Restore on failure
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

  // Display title for active conversation
  let activeChatTitle = activeConv?.title || 'Untitled';
  if (activeConv?.type === 'direct') {
    const otherId = activeConv.participantIds.find(id => id !== currentUserId);
    if (otherId) {
      const other = memberMap.get(otherId);
      if (other) activeChatTitle = `${other.firstName} ${other.lastName}`.trim() || 'Unknown';
    }
  }

  return (
    <>
      <CommandPalette />
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-zinc-100">{t('teamChat.title')}</h1>
            <p className="text-sm text-zinc-500 mt-1">
              Internal messaging — direct, group, and job conversations
              {totalUnread > 0 && (
                <Badge className="ml-2 bg-emerald-500/20 text-emerald-400 border-0">
                  {totalUnread} unread
                </Badge>
              )}
            </p>
          </div>
          <Button onClick={() => setShowNewConversation(true)}>
            <Plus className="h-4 w-4 mr-1" />
            New Chat
          </Button>
        </div>

        <Card className="bg-zinc-900 border-zinc-800 overflow-hidden">
          <div className="flex h-[calc(100vh-220px)]">
            {/* ══════ Conversation List (Left Panel) ══════ */}
            <div className="w-80 border-r border-zinc-800 flex flex-col">
              {/* Search */}
              <div className="p-3 border-b border-zinc-800">
                <div className="relative">
                  <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-zinc-500" />
                  <input
                    value={searchFilter}
                    onChange={e => setSearchFilter(e.target.value)}
                    placeholder="Search conversations..."
                    className="w-full bg-zinc-800 border border-zinc-700 rounded-lg pl-8 pr-3 py-1.5 text-sm text-zinc-100 placeholder:text-zinc-500 focus:outline-none focus:ring-1 focus:ring-emerald-500/50"
                  />
                </div>
              </div>

              {/* Conversations */}
              <div className="flex-1 overflow-y-auto">
                {loading ? (
                  <div className="flex items-center justify-center py-8 text-zinc-500">
                    <Loader2 className="h-4 w-4 animate-spin mr-2" />
                    Loading...
                  </div>
                ) : error ? (
                  <div className="p-4 text-center">
                    <p className="text-sm text-red-400">{error}</p>
                    <Button variant="ghost" size="sm" onClick={refetch} className="mt-2">{t('common.retry')}</Button>
                  </div>
                ) : filteredConversations.length === 0 ? (
                  <div className="p-4 text-center text-zinc-500 text-sm">
                    <MessageSquare className="h-6 w-6 mx-auto mb-2 opacity-50" />
                    {searchFilter ? 'No matching conversations' : 'No conversations yet'}
                  </div>
                ) : (
                  filteredConversations.map(conv => (
                    <ConversationItem
                      key={conv.id}
                      conversation={conv}
                      isActive={conv.id === activeConvId}
                      onClick={() => setActiveConvId(conv.id)}
                      currentUserId={currentUserId}
                      memberMap={memberMap}
                    />
                  ))
                )}
              </div>
            </div>

            {/* ══════ Chat Panel (Right) ══════ */}
            <div className="flex-1 flex flex-col">
              {activeConv ? (
                <>
                  {/* Chat Header */}
                  <div className="px-4 py-3 border-b border-zinc-800 flex items-center gap-2">
                    {(() => {
                      const Icon = typeIcons[activeConv.type] || MessageSquare;
                      return <Icon className="h-4 w-4 text-zinc-500" />;
                    })()}
                    <span className="font-medium text-zinc-100">{activeChatTitle}</span>
                    <Badge className="bg-zinc-800 text-zinc-400 border-zinc-700 text-xs">
                      {activeConv.type}
                    </Badge>
                    {activeConv.participantIds.length > 2 && (
                      <span className="text-xs text-zinc-600 ml-auto">
                        {activeConv.participantIds.length} members
                      </span>
                    )}
                  </div>

                  {/* Messages */}
                  <div className="flex-1 overflow-y-auto py-2">
                    {messagesLoading ? (
                      <div className="flex items-center justify-center h-full text-zinc-500">
                        <Loader2 className="h-5 w-5 animate-spin" />
                      </div>
                    ) : messages.length === 0 ? (
                      <div className="flex items-center justify-center h-full text-zinc-500 text-sm">
                        <div className="text-center">
                          <MessageSquare className="h-6 w-6 mx-auto mb-2 opacity-50" />
                          <p>{t('common.noMessagesYetStartTheConversation')}</p>
                        </div>
                      </div>
                    ) : (
                      <>
                        {messages.map(msg => (
                          <MessageBubble
                            key={msg.id}
                            message={msg}
                            isOwn={msg.senderId === currentUserId}
                          />
                        ))}
                        <div ref={messagesEndRef} />
                      </>
                    )}
                  </div>

                  {/* Compose Bar */}
                  <div className="p-3 border-t border-zinc-800">
                    <div className="flex items-end gap-2">
                      <textarea
                        value={compose}
                        onChange={e => setCompose(e.target.value)}
                        onKeyDown={handleKeyDown}
                        placeholder={t('teamChat.typeMessage')}
                        className="flex-1 bg-zinc-800 border border-zinc-700 rounded-xl px-3.5 py-2 text-sm text-zinc-100 placeholder:text-zinc-500 resize-none focus:outline-none focus:ring-1 focus:ring-emerald-500/50"
                        rows={1}
                      />
                      <Button
                        size="sm"
                        onClick={handleSend}
                        disabled={!compose.trim() || sending}
                        className="gap-1"
                      >
                        {sending ? (
                          <Loader2 className="h-3.5 w-3.5 animate-spin" />
                        ) : (
                          <Send className="h-3.5 w-3.5" />
                        )}
                        Send
                      </Button>
                    </div>
                  </div>
                </>
              ) : (
                <div className="flex items-center justify-center h-full text-zinc-500">
                  <div className="text-center">
                    <MessageSquare className="h-10 w-10 mx-auto mb-3 opacity-50" />
                    <p className="text-sm">{t('common.selectAConversationToStartChatting')}</p>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setShowNewConversation(true)}
                      className="mt-3"
                    >
                      <Plus className="h-4 w-4 mr-1" /> New Conversation
                    </Button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </Card>
      </div>

      {/* New Conversation Modal */}
      {showNewConversation && (
        <NewConversationModal
          onClose={() => setShowNewConversation(false)}
          onCreated={(conv) => {
            setShowNewConversation(false);
            setActiveConvId(conv.id);
            refetch();
          }}
          members={members}
          currentUserId={currentUserId}
        />
      )}
    </>
  );
}

// ════════════════════════════════════════════════════════════════
// UTILS
// ════════════════════════════════════════════════════════════════

function formatRelative(date: Date): string {
  const now = new Date();
  const diff = now.getTime() - date.getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'now';
  if (mins < 60) return `${mins}m`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d`;
  return `${date.getMonth() + 1}/${date.getDate()}`;
}
