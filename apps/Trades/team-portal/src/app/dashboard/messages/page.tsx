'use client';

// ZAFTO Team Portal — Messages Page
// Created: Sprint FIELD1 (Session 131)
//
// Mobile-optimized two-panel messaging for field employees.
// List view → tap → chat view. New conversation creation.
// Real-time via Supabase Realtime.

import { useState, useEffect, useRef, useCallback } from 'react';
import {
  MessageSquare,
  Send,
  Users,
  User,
  Briefcase,
  Loader2,
  Plus,
  Search,
  ArrowLeft,
  X,
  Check,
  Paperclip,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import {
  useConversations,
  useMessages,
  useTeamMembers,
  sendMessage,
  markRead,
  createDirectConversation,
  createGroupConversation,
  type Conversation,
  type ChatMessage,
  type TeamMember,
} from '@/lib/hooks/use-messages';
import { cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';

// ════════════════════════════════════════════════════════════════
// LOADING SKELETON
// ════════════════════════════════════════════════════════════════

function MessagesSkeleton() {
  return (
    <div className="space-y-4 animate-fade-in p-4">
      <div className="skeleton h-7 w-32 rounded-lg" />
      <div className="skeleton h-10 w-full rounded-lg" />
      {[1, 2, 3, 4, 5].map(i => (
        <div key={i} className="flex items-center gap-3">
          <div className="skeleton h-10 w-10 rounded-full" />
          <div className="flex-1 space-y-1">
            <div className="skeleton h-4 w-32 rounded" />
            <div className="skeleton h-3 w-48 rounded" />
          </div>
        </div>
      ))}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// MAIN COMPONENT
// ════════════════════════════════════════════════════════════════

export default function MessagesPage() {
  const { conversations, totalUnread, loading, error, refetch } = useConversations();
  const { members } = useTeamMembers();
  const [activeConvId, setActiveConvId] = useState<string | null>(null);
  const { messages, loading: msgsLoading } = useMessages(activeConvId);
  const [compose, setCompose] = useState('');
  const [sending, setSending] = useState(false);
  const [searchFilter, setSearchFilter] = useState('');
  const [showNewChat, setShowNewChat] = useState(false);
  const [currentUserId, setCurrentUserId] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Get current user
  useEffect(() => {
    async function fetchUser() {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (user) setCurrentUserId(user.id);
    }
    fetchUser();
  }, []);

  const memberMap = new Map(members.map(m => [m.id, m]));
  const activeConv = conversations.find(c => c.id === activeConvId) || null;

  // Mark read on open
  useEffect(() => {
    if (activeConvId && activeConv && activeConv.unreadCount > 0) {
      markRead(activeConvId).then(() => refetch()).catch(() => {});
    }
  }, [activeConvId]); // eslint-disable-line react-hooks/exhaustive-deps

  // Auto-scroll
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Filtered conversations
  const filtered = searchFilter
    ? conversations.filter(c => {
        const q = searchFilter.toLowerCase();
        if ((c.title || '').toLowerCase().includes(q)) return true;
        if ((c.lastMessagePreview || '').toLowerCase().includes(q)) return true;
        if (c.type === 'direct') {
          const otherId = c.participantIds.find(id => id !== currentUserId);
          const other = otherId ? memberMap.get(otherId) : null;
          if (other && `${other.firstName} ${other.lastName}`.toLowerCase().includes(q)) return true;
        }
        return false;
      })
    : conversations;

  // Display name helper
  const getConvTitle = (conv: Conversation): string => {
    if (conv.title) return conv.title;
    if (conv.type === 'direct') {
      const otherId = conv.participantIds.find(id => id !== currentUserId);
      const other = otherId ? memberMap.get(otherId) : null;
      if (other) return `${other.firstName} ${other.lastName}`.trim() || 'Unknown';
    }
    return 'Untitled';
  };

  const getConvIcon = (type: string) => {
    switch (type) {
      case 'group': return Users;
      case 'job': return Briefcase;
      default: return User;
    }
  };

  // Send handler
  const handleSend = async () => {
    if (!compose.trim() || !activeConvId || sending) return;
    const text = compose.trim();
    setSending(true);
    setCompose('');
    try {
      await sendMessage(activeConvId, text);
    } catch {
      setCompose(text);
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

  if (loading) return <MessagesSkeleton />;

  // ════════════════════════════════════════════════════════════
  // CHAT VIEW (when a conversation is selected)
  // ════════════════════════════════════════════════════════════

  if (activeConvId && activeConv) {
    const chatTitle = getConvTitle(activeConv);
    const ChatIcon = getConvIcon(activeConv.type);

    return (
      <div className="flex flex-col h-[calc(100vh-64px)]">
        {/* Chat Header */}
        <div className="flex items-center gap-2 px-4 py-3 border-b border-main bg-main">
          <button
            onClick={() => setActiveConvId(null)}
            className="p-1.5 hover:bg-surface-hover rounded-lg"
          >
            <ArrowLeft size={18} className="text-muted" />
          </button>
          <ChatIcon size={16} className="text-muted" />
          <h2 className="font-medium text-main truncate">{chatTitle}</h2>
          {activeConv.participantIds.length > 2 && (
            <span className="text-xs text-muted ml-auto">
              {activeConv.participantIds.length} members
            </span>
          )}
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto px-3 py-2">
          {msgsLoading ? (
            <div className="flex items-center justify-center h-full">
              <Loader2 className="h-5 w-5 animate-spin text-muted" />
            </div>
          ) : messages.length === 0 ? (
            <div className="flex items-center justify-center h-full text-muted text-sm">
              <div className="text-center">
                <MessageSquare className="h-6 w-6 mx-auto mb-2 opacity-50" />
                <p>No messages yet. Say hello!</p>
              </div>
            </div>
          ) : (
            <>
              {messages.map((msg, idx) => {
                const isOwn = msg.senderId === currentUserId;
                const showDate = idx === 0 || !sameDay(
                  new Date(msg.createdAt),
                  new Date(messages[idx - 1].createdAt),
                );

                return (
                  <div key={msg.id}>
                    {showDate && (
                      <div className="text-center py-2">
                        <span className="text-[10px] text-muted bg-secondary px-2 py-0.5 rounded-full">
                          {formatDateLabel(new Date(msg.createdAt))}
                        </span>
                      </div>
                    )}
                    {msg.messageType === 'system' ? (
                      <div className="text-center py-1">
                        <span className="text-[11px] text-muted">{msg.content}</span>
                      </div>
                    ) : (
                      <div className={cn('flex gap-2 py-0.5', isOwn ? 'flex-row-reverse' : 'flex-row')}>
                        <div className={cn(
                          'max-w-[80%] rounded-2xl px-3 py-2',
                          isOwn
                            ? 'bg-accent text-white rounded-br-sm'
                            : 'bg-secondary text-main rounded-bl-sm',
                        )}>
                          {!isOwn && (
                            <p className="text-[10px] font-medium opacity-70 mb-0.5">
                              {msg.senderName}
                            </p>
                          )}
                          {msg.fileUrl && msg.messageType === 'image' && (
                            <div className="mb-1 rounded-lg overflow-hidden">
                              <img src={msg.fileUrl} alt="" className="max-w-full max-h-48 object-cover" loading="lazy" />
                            </div>
                          )}
                          {msg.fileUrl && msg.messageType === 'file' && (
                            <div className="flex items-center gap-1 text-xs opacity-70 mb-1">
                              <Paperclip size={12} />
                              <span className="truncate underline">{msg.fileName || 'File'}</span>
                            </div>
                          )}
                          {msg.content && (
                            <p className="text-sm whitespace-pre-wrap break-words">{msg.content}</p>
                          )}
                          <p className={cn(
                            'text-[10px] mt-1',
                            isOwn ? 'text-white/50' : 'text-muted',
                          )}>
                            {new Date(msg.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            {msg.isEdited && ' (edited)'}
                          </p>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
              <div ref={messagesEndRef} />
            </>
          )}
        </div>

        {/* Compose */}
        <div className="px-3 py-2 border-t border-main bg-main">
          <div className="flex items-end gap-2">
            <textarea
              value={compose}
              onChange={e => setCompose(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Type a message..."
              className="flex-1 bg-secondary border border-main rounded-2xl px-3.5 py-2 text-sm text-main placeholder:text-muted resize-none focus:outline-none focus:ring-1 focus:ring-accent"
              rows={1}
            />
            <button
              onClick={handleSend}
              disabled={!compose.trim() || sending}
              className={cn(
                'p-2.5 rounded-full transition-colors',
                compose.trim() && !sending
                  ? 'bg-accent text-white'
                  : 'bg-secondary text-muted',
              )}
            >
              {sending ? <Loader2 size={18} className="animate-spin" /> : <Send size={18} />}
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ════════════════════════════════════════════════════════════
  // CONVERSATION LIST VIEW
  // ════════════════════════════════════════════════════════════

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-main">Messages</h1>
          {totalUnread > 0 && (
            <p className="text-sm text-accent mt-0.5">{totalUnread} unread</p>
          )}
        </div>
        <Button size="sm" onClick={() => setShowNewChat(true)}>
          <Plus size={16} />
          New
        </Button>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted" />
        <input
          value={searchFilter}
          onChange={e => setSearchFilter(e.target.value)}
          placeholder="Search conversations..."
          className="w-full bg-secondary border border-main rounded-xl pl-9 pr-3 py-2.5 text-sm text-main placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-accent"
        />
      </div>

      {/* Error state */}
      {error && (
        <Card>
          <CardContent className="py-6 text-center">
            <p className="text-sm text-red-500">{error}</p>
            <Button variant="ghost" size="sm" onClick={refetch} className="mt-2">Retry</Button>
          </CardContent>
        </Card>
      )}

      {/* Empty state */}
      {!error && filtered.length === 0 && (
        <Card>
          <CardContent className="py-12 text-center">
            <MessageSquare className="h-8 w-8 mx-auto mb-2 text-muted opacity-50" />
            <p className="text-muted text-sm">
              {searchFilter ? 'No matching conversations' : 'No messages yet'}
            </p>
            {!searchFilter && (
              <Button size="sm" className="mt-3" onClick={() => setShowNewChat(true)}>
                <Plus size={14} className="mr-1" />
                Start a conversation
              </Button>
            )}
          </CardContent>
        </Card>
      )}

      {/* Conversation list */}
      {filtered.length > 0 && (
        <div className="space-y-1">
          {filtered.map(conv => {
            const title = getConvTitle(conv);
            const Icon = getConvIcon(conv.type);
            const timeLabel = conv.lastMessageAt ? formatRelative(new Date(conv.lastMessageAt)) : '';

            return (
              <button
                key={conv.id}
                onClick={() => setActiveConvId(conv.id)}
                className="w-full flex items-center gap-3 px-3 py-3 rounded-xl hover:bg-surface-hover transition-colors text-left"
              >
                <div className={cn(
                  'w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0',
                  conv.unreadCount > 0 ? 'bg-accent/10' : 'bg-secondary',
                )}>
                  <Icon size={18} className={conv.unreadCount > 0 ? 'text-accent' : 'text-muted'} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <span className={cn(
                      'text-sm truncate',
                      conv.unreadCount > 0 ? 'font-semibold text-main' : 'text-main',
                    )}>
                      {title}
                    </span>
                    <span className={cn(
                      'text-[10px] flex-shrink-0 ml-2',
                      conv.unreadCount > 0 ? 'text-accent' : 'text-muted',
                    )}>
                      {timeLabel}
                    </span>
                  </div>
                  {conv.lastMessagePreview && (
                    <p className={cn(
                      'text-xs truncate mt-0.5',
                      conv.unreadCount > 0 ? 'text-main' : 'text-muted',
                    )}>
                      {conv.lastMessagePreview}
                    </p>
                  )}
                </div>
                {conv.unreadCount > 0 && (
                  <span className="flex-shrink-0 bg-accent text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full min-w-[20px] text-center">
                    {conv.unreadCount > 99 ? '99+' : conv.unreadCount}
                  </span>
                )}
              </button>
            );
          })}
        </div>
      )}

      {/* New Chat Modal */}
      {showNewChat && (
        <NewChatModal
          onClose={() => setShowNewChat(false)}
          onCreated={(conv) => {
            setShowNewChat(false);
            setActiveConvId(conv.id);
            refetch();
          }}
          members={members}
          currentUserId={currentUserId}
        />
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// NEW CHAT MODAL
// ════════════════════════════════════════════════════════════════

function NewChatModal({
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
  const [mode, setMode] = useState<'direct' | 'group'>('direct');
  const [search, setSearch] = useState('');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [groupName, setGroupName] = useState('');
  const [creating, setCreating] = useState(false);

  const filteredMembers = members.filter(m => {
    if (m.id === currentUserId) return false;
    if (!search) return true;
    return `${m.firstName} ${m.lastName}`.toLowerCase().includes(search.toLowerCase());
  });

  const handleDirect = async (member: TeamMember) => {
    try {
      setCreating(true);
      const conv = await createDirectConversation(member.id);
      onCreated(conv);
    } catch {
      setCreating(false);
    }
  };

  const handleGroup = async () => {
    if (selectedIds.size < 2 || !groupName.trim()) return;
    try {
      setCreating(true);
      const conv = await createGroupConversation(groupName.trim(), Array.from(selectedIds));
      onCreated(conv);
    } catch {
      setCreating(false);
    }
  };

  const toggleId = (id: string) => {
    setSelectedIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center">
      <Card className="w-full sm:max-w-md max-h-[85vh] flex flex-col rounded-t-2xl sm:rounded-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-main">
          <h2 className="font-semibold text-main">
            {mode === 'direct' ? 'New Message' : 'New Group'}
          </h2>
          <div className="flex items-center gap-2">
            {mode === 'direct' ? (
              <button
                onClick={() => setMode('group')}
                className="text-xs font-medium text-accent px-2 py-1 rounded hover:bg-surface-hover"
              >
                Group
              </button>
            ) : (
              <button
                onClick={handleGroup}
                disabled={creating || selectedIds.size < 2 || !groupName.trim()}
                className="text-xs font-medium text-accent px-2 py-1 rounded hover:bg-surface-hover disabled:opacity-50"
              >
                {creating ? 'Creating...' : 'Create'}
              </button>
            )}
            <button onClick={onClose} className="p-1 hover:bg-surface-hover rounded">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </div>

        {/* Group name */}
        {mode === 'group' && (
          <div className="px-4 py-2 border-b border-main">
            <input
              value={groupName}
              onChange={e => setGroupName(e.target.value)}
              placeholder="Group name..."
              className="w-full bg-secondary border border-main rounded-lg px-3 py-2 text-sm text-main placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-accent"
            />
          </div>
        )}

        {/* Search */}
        <div className="px-4 py-2 border-b border-main">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search team members..."
              className="w-full bg-secondary border border-main rounded-lg pl-9 pr-3 py-2 text-sm text-main placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-accent"
            />
          </div>
        </div>

        {/* Members */}
        <div className="flex-1 overflow-y-auto">
          {creating && mode === 'direct' ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="h-5 w-5 animate-spin text-muted" />
            </div>
          ) : filteredMembers.length === 0 ? (
            <p className="text-center py-8 text-muted text-sm">No team members found</p>
          ) : (
            filteredMembers.map(member => {
              const name = `${member.firstName} ${member.lastName}`.trim() || 'Unknown';
              const isSelected = selectedIds.has(member.id);

              return (
                <button
                  key={member.id}
                  onClick={() => mode === 'direct' ? handleDirect(member) : toggleId(member.id)}
                  className="w-full flex items-center gap-3 px-4 py-2.5 hover:bg-surface-hover transition-colors text-left"
                >
                  <div className="w-9 h-9 rounded-full bg-secondary flex items-center justify-center text-xs font-medium text-muted">
                    {name[0]?.toUpperCase() || '?'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-main truncate">{name}</p>
                    <p className="text-[11px] text-muted truncate">{member.role}</p>
                  </div>
                  {mode === 'group' && (
                    <div className={cn(
                      'w-5 h-5 rounded border flex items-center justify-center',
                      isSelected ? 'bg-accent border-accent' : 'border-main',
                    )}>
                      {isSelected && <Check size={12} className="text-white" />}
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

function sameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

function formatDateLabel(date: Date): string {
  const now = new Date();
  if (sameDay(date, now)) return 'Today';
  const yesterday = new Date(now);
  yesterday.setDate(yesterday.getDate() - 1);
  if (sameDay(date, yesterday)) return 'Yesterday';
  return `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;
}
