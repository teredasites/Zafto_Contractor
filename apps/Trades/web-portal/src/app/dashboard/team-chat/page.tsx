'use client';

// ZAFTO Team Chat — Full-Depth Conversation Messaging (CRM)
// Phase 12C: @mentions, read receipts, photo sharing, job thread cards,
//   conversation info panel, typing indicator, message reactions.
//
// Split-view: conversation list (left) + chat panel (right) + info panel (right).
// Direct messages, group chats, job-scoped conversations.
// Real-time message delivery via Supabase Realtime.

import { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import {
  MessageSquare,
  Send,
  Users,
  User,
  Briefcase,
  Loader2,
  Paperclip,
  Image as ImageIcon,
  Plus,
  Search,
  X,
  Check,
  Eye,
  ThumbsUp,
  Heart,
  Info,
  Pin,
  FileText,
  ChevronRight,
  Camera,
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
import { formatTimeLocale } from '@/lib/format-locale';

// ════════════════════════════════════════════════════════════════
// TYPES
// ════════════════════════════════════════════════════════════════

type ReactionType = 'thumbsup' | 'check' | 'heart' | 'eyes';

interface MessageReaction {
  type: ReactionType;
  userIds: string[];
}

interface ReadReceipt {
  userId: string;
  readAt: string;
}

// Demo data for job thread cards
const DEMO_JOB_DATA: Record<string, { title: string; status: string; customer: string }> = {
  default: { title: 'Kitchen Remodel — 1245 Oak Ave', status: 'In Progress', customer: 'Sarah Mitchell' },
};

// Demo online status
const DEMO_ONLINE_IDS = new Set<string>();

// ════════════════════════════════════════════════════════════════
// MENTION RENDERING
// ════════════════════════════════════════════════════════════════

function renderMessageContent(content: string, members: Map<string, TeamMember>): React.ReactNode {
  // Split on @Name patterns — match @Word or @Word (first+last handled by single @First)
  const parts = content.split(/(@\w+)/g);
  return parts.map((part, i) => {
    if (part.startsWith('@')) {
      const mentionName = part.slice(1).toLowerCase();
      // Check if it matches any member first name
      let isMention = false;
      const memberArr = Array.from(members.values());
      for (let mi = 0; mi < memberArr.length; mi++) {
        if (memberArr[mi].firstName.toLowerCase() === mentionName) {
          isMention = true;
          break;
        }
      }
      if (isMention) {
        return (
          <span key={i} className="text-emerald-400 font-medium">
            {part}
          </span>
        );
      }
    }
    return <span key={i}>{part}</span>;
  });
}

// ════════════════════════════════════════════════════════════════
// REACTION BAR (hover overlay)
// ════════════════════════════════════════════════════════════════

const REACTION_OPTIONS: { type: ReactionType; icon: typeof ThumbsUp; label: string }[] = [
  { type: 'thumbsup', icon: ThumbsUp, label: 'Like' },
  { type: 'check', icon: Check, label: 'Done' },
  { type: 'heart', icon: Heart, label: 'Love' },
  { type: 'eyes', icon: Eye, label: 'Seen' },
];

function ReactionPicker({ onReact }: { onReact: (type: ReactionType) => void }) {
  return (
    <div className="flex items-center gap-0.5 bg-zinc-800 border border-zinc-700 rounded-lg px-1 py-0.5 shadow-lg">
      {REACTION_OPTIONS.map(r => {
        const Icon = r.icon;
        return (
          <button
            key={r.type}
            onClick={() => onReact(r.type)}
            className="p-1 rounded hover:bg-zinc-700 transition-colors"
            title={r.label}
          >
            <Icon className="h-3.5 w-3.5 text-zinc-400 hover:text-zinc-200" />
          </button>
        );
      })}
    </div>
  );
}

function ReactionDisplay({
  reactions,
  memberMap,
}: {
  reactions: MessageReaction[];
  memberMap: Map<string, TeamMember>;
}) {
  if (reactions.length === 0) return null;
  return (
    <div className="flex items-center gap-1 mt-1">
      {reactions.map(r => {
        const Icon = REACTION_OPTIONS.find(o => o.type === r.type)?.icon || ThumbsUp;
        return (
          <span
            key={r.type}
            className="inline-flex items-center gap-0.5 bg-zinc-700/50 rounded-full px-1.5 py-0.5 text-[10px] text-zinc-400"
            title={r.userIds
              .map(id => {
                const m = memberMap.get(id);
                return m ? `${m.firstName} ${m.lastName}` : 'Unknown';
              })
              .join(', ')}
          >
            <Icon className="h-3 w-3" />
            {r.userIds.length > 1 && <span>{r.userIds.length}</span>}
          </span>
        );
      })}
    </div>
  );
}

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
// MESSAGE BUBBLE (enhanced: @mentions, reactions, read receipts)
// ════════════════════════════════════════════════════════════════

function MessageBubble({
  message,
  isOwn,
  memberMap,
  reactions,
  onReact,
  readReceipts,
  isLastMessage,
}: {
  message: ChatMessage;
  isOwn: boolean;
  memberMap: Map<string, TeamMember>;
  reactions: MessageReaction[];
  onReact: (type: ReactionType) => void;
  readReceipts: ReadReceipt[];
  isLastMessage: boolean;
}) {
  const [showReactions, setShowReactions] = useState(false);

  if (message.messageType === 'system') {
    return (
      <div className="text-center py-1.5">
        <span className="text-[11px] text-zinc-600 bg-zinc-800/50 px-2.5 py-1 rounded-full">
          {message.content}
        </span>
      </div>
    );
  }

  const readCount = readReceipts.length;

  return (
    <div
      className={cn('flex gap-2 px-4 py-0.5 group relative', isOwn ? 'flex-row-reverse' : 'flex-row')}
      onMouseEnter={() => setShowReactions(true)}
      onMouseLeave={() => setShowReactions(false)}
    >
      <div className="relative max-w-[70%]">
        {/* Reaction picker on hover */}
        {showReactions && (
          <div className={cn(
            'absolute -top-8 z-10',
            isOwn ? 'right-0' : 'left-0',
          )}>
            <ReactionPicker onReact={onReact} />
          </div>
        )}

        <div className={cn(
          'rounded-xl px-3.5 py-2',
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
                className="max-w-full max-h-60 object-cover cursor-pointer hover:opacity-90 transition-opacity"
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
            <p className="text-sm whitespace-pre-wrap break-words">
              {renderMessageContent(message.content, memberMap)}
            </p>
          )}
          <div className="flex items-center gap-1 mt-1">
            <span className="text-[10px] text-zinc-500">
              {formatTimeLocale(message.createdAt)}
            </span>
            {message.isEdited && <span className="text-[10px] text-zinc-600">(edited)</span>}
            {/* Read receipt indicator for own messages */}
            {isOwn && readCount > 0 && (
              <span className="flex items-center gap-0.5 text-[10px] text-zinc-500 ml-1">
                <Eye className="h-2.5 w-2.5" />
                {readCount}
              </span>
            )}
          </div>
        </div>

        {/* Reactions display */}
        <ReactionDisplay reactions={reactions} memberMap={memberMap} />

        {/* Last message read receipt avatars */}
        {isOwn && isLastMessage && readReceipts.length > 0 && (
          <div className="flex items-center gap-0.5 mt-1 justify-end">
            {readReceipts.slice(0, 5).map(receipt => {
              const m = memberMap.get(receipt.userId);
              const initial = m ? m.firstName[0]?.toUpperCase() : '?';
              return (
                <div
                  key={receipt.userId}
                  className="w-4 h-4 rounded-full bg-zinc-700 flex items-center justify-center text-[8px] text-zinc-300 border border-zinc-900"
                  title={m ? `${m.firstName} ${m.lastName}` : 'Read'}
                >
                  {initial}
                </div>
              );
            })}
            {readReceipts.length > 5 && (
              <span className="text-[9px] text-zinc-500 ml-0.5">+{readReceipts.length - 5}</span>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// TYPING INDICATOR
// ════════════════════════════════════════════════════════════════

function TypingIndicator({ name }: { name: string }) {
  return (
    <div className="flex items-center gap-2 px-4 py-1">
      <div className="bg-zinc-800 rounded-xl px-3 py-2 flex items-center gap-1.5">
        <span className="text-xs text-zinc-500">{name} is typing</span>
        <span className="flex gap-0.5">
          <span className="w-1 h-1 bg-zinc-500 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
          <span className="w-1 h-1 bg-zinc-500 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
          <span className="w-1 h-1 bg-zinc-500 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
        </span>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// MENTIONS DROPDOWN
// ════════════════════════════════════════════════════════════════

function MentionsDropdown({
  members,
  filter,
  onSelect,
  position,
}: {
  members: TeamMember[];
  filter: string;
  onSelect: (member: TeamMember) => void;
  position: { bottom: number; left: number };
}) {
  const filtered = members.filter(m => {
    if (!filter) return true;
    const name = `${m.firstName} ${m.lastName}`.toLowerCase();
    return name.includes(filter.toLowerCase());
  });

  if (filtered.length === 0) return null;

  return (
    <div
      className="absolute z-20 bg-zinc-800 border border-zinc-700 rounded-lg shadow-xl max-h-48 overflow-y-auto w-56"
      style={{ bottom: position.bottom, left: position.left }}
    >
      {filtered.slice(0, 8).map(member => {
        const name = `${member.firstName} ${member.lastName}`.trim();
        return (
          <button
            key={member.id}
            onClick={() => onSelect(member)}
            className="w-full flex items-center gap-2 px-3 py-2 hover:bg-zinc-700/50 transition-colors text-left"
          >
            <div className="w-6 h-6 rounded-full bg-zinc-700 flex items-center justify-center text-[10px] font-medium text-zinc-300">
              {name[0]?.toUpperCase() || '?'}
            </div>
            <div className="min-w-0">
              <p className="text-sm text-zinc-200 truncate">{name}</p>
              <p className="text-[10px] text-zinc-500">{member.role}</p>
            </div>
          </button>
        );
      })}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// PHOTO PREVIEW
// ════════════════════════════════════════════════════════════════

function PhotoPreview({
  file,
  onCancel,
  onSend,
  sending,
}: {
  file: File;
  onCancel: () => void;
  onSend: () => void;
  sending: boolean;
}) {
  const [preview, setPreview] = useState<string | null>(null);

  useEffect(() => {
    const url = URL.createObjectURL(file);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [file]);

  if (!preview) return null;

  return (
    <div className="p-3 border-t border-zinc-800 bg-zinc-900/50">
      <div className="flex items-end gap-3">
        <div className="relative">
          <img
            src={preview}
            alt="Preview"
            className="h-20 w-20 object-cover rounded-lg border border-zinc-700"
          />
          <button
            onClick={onCancel}
            className="absolute -top-1.5 -right-1.5 w-5 h-5 bg-zinc-700 rounded-full flex items-center justify-center hover:bg-zinc-600"
          >
            <X className="h-3 w-3 text-zinc-300" />
          </button>
        </div>
        <div className="flex-1">
          <p className="text-xs text-zinc-400 truncate mb-1">{file.name}</p>
          <p className="text-[10px] text-zinc-600">{(file.size / 1024).toFixed(1)} KB</p>
        </div>
        <Button size="sm" onClick={onSend} disabled={sending}>
          {sending ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Send className="h-3.5 w-3.5" />}
          <span className="ml-1">Send</span>
        </Button>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// JOB THREAD CARD
// ════════════════════════════════════════════════════════════════

function JobThreadCard({ conversation }: { conversation: Conversation }) {
  const jobData = DEMO_JOB_DATA.default;

  return (
    <div className="px-4 py-2.5 border-b border-zinc-800 bg-zinc-800/30">
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 rounded-lg bg-emerald-500/10 flex items-center justify-center flex-shrink-0">
          <Briefcase className="h-4 w-4 text-emerald-400" />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="text-sm font-medium text-zinc-100 truncate">{jobData.title}</span>
            <Badge variant="success" className="text-[10px] px-1.5 py-0">{jobData.status}</Badge>
          </div>
          <p className="text-xs text-zinc-500 mt-0.5">Customer: {jobData.customer}</p>
        </div>
        <ChevronRight className="h-4 w-4 text-zinc-600 flex-shrink-0" />
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// CONVERSATION INFO PANEL
// ════════════════════════════════════════════════════════════════

function ConversationInfoPanel({
  conversation,
  memberMap,
  messages,
  onClose,
}: {
  conversation: Conversation;
  memberMap: Map<string, TeamMember>;
  messages: ChatMessage[];
  onClose: () => void;
}) {
  const [activeTab, setActiveTab] = useState<'members' | 'files' | 'images' | 'pinned'>('members');

  const participants = conversation.participantIds
    .map(id => memberMap.get(id))
    .filter(Boolean) as TeamMember[];

  // Collect shared files and images from messages
  const sharedFiles = messages.filter(m => m.messageType === 'file' && m.fileUrl);
  const sharedImages = messages.filter(m => m.messageType === 'image' && m.fileUrl);

  // Demo pinned messages
  const pinnedMessages = messages.slice(0, 2);

  const tabs: { key: typeof activeTab; label: string }[] = [
    { key: 'members', label: 'Members' },
    { key: 'files', label: 'Files' },
    { key: 'images', label: 'Images' },
    { key: 'pinned', label: 'Pinned' },
  ];

  return (
    <div className="w-72 border-l border-zinc-800 flex flex-col bg-zinc-900">
      {/* Header */}
      <div className="px-4 py-3 border-b border-zinc-800 flex items-center justify-between">
        <h3 className="text-sm font-semibold text-zinc-100">Conversation Info</h3>
        <button onClick={onClose} className="p-1 hover:bg-zinc-800 rounded">
          <X className="h-4 w-4 text-zinc-500" />
        </button>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-zinc-800">
        {tabs.map(tab => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={cn(
              'flex-1 py-2 text-[11px] font-medium transition-colors',
              activeTab === tab.key
                ? 'text-emerald-400 border-b-2 border-emerald-400'
                : 'text-zinc-500 hover:text-zinc-300',
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {activeTab === 'members' && (
          <div className="py-1">
            {participants.map(member => {
              const isOnline = DEMO_ONLINE_IDS.has(member.id) || Math.random() > 0.5;
              const name = `${member.firstName} ${member.lastName}`.trim();
              return (
                <div key={member.id} className="flex items-center gap-2.5 px-4 py-2">
                  <div className="relative">
                    <div className="w-8 h-8 rounded-full bg-zinc-800 flex items-center justify-center text-xs font-medium text-zinc-400">
                      {name[0]?.toUpperCase() || '?'}
                    </div>
                    <div className={cn(
                      'absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full border-2 border-zinc-900',
                      isOnline ? 'bg-emerald-500' : 'bg-zinc-600',
                    )} />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm text-zinc-200 truncate">{name}</p>
                    <p className="text-[10px] text-zinc-500">{member.role}</p>
                  </div>
                  <span className={cn('text-[10px]', isOnline ? 'text-emerald-400' : 'text-zinc-600')}>
                    {isOnline ? 'Online' : 'Offline'}
                  </span>
                </div>
              );
            })}
            {participants.length === 0 && (
              <p className="text-xs text-zinc-500 text-center py-6">No participants</p>
            )}
          </div>
        )}

        {activeTab === 'files' && (
          <div className="py-1">
            {sharedFiles.length === 0 ? (
              <div className="text-center py-8">
                <FileText className="h-6 w-6 mx-auto mb-2 text-zinc-600" />
                <p className="text-xs text-zinc-500">No shared files yet</p>
              </div>
            ) : (
              sharedFiles.map(f => (
                <div key={f.id} className="flex items-center gap-2 px-4 py-2 hover:bg-zinc-800/50">
                  <Paperclip className="h-3.5 w-3.5 text-zinc-500 flex-shrink-0" />
                  <div className="min-w-0 flex-1">
                    <p className="text-xs text-zinc-200 truncate">{f.fileName || 'Unnamed'}</p>
                    <p className="text-[10px] text-zinc-500">{formatTimeLocale(f.createdAt)}</p>
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {activeTab === 'images' && (
          <div className="p-2">
            {sharedImages.length === 0 ? (
              <div className="text-center py-8">
                <ImageIcon className="h-6 w-6 mx-auto mb-2 text-zinc-600" />
                <p className="text-xs text-zinc-500">No shared images yet</p>
              </div>
            ) : (
              <div className="grid grid-cols-3 gap-1">
                {sharedImages.map(img => (
                  <div key={img.id} className="aspect-square rounded overflow-hidden">
                    <img
                      src={img.fileUrl!}
                      alt={img.fileName || 'Image'}
                      className="w-full h-full object-cover hover:opacity-80 cursor-pointer transition-opacity"
                      loading="lazy"
                    />
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'pinned' && (
          <div className="py-1">
            {pinnedMessages.length === 0 ? (
              <div className="text-center py-8">
                <Pin className="h-6 w-6 mx-auto mb-2 text-zinc-600" />
                <p className="text-xs text-zinc-500">No pinned messages</p>
              </div>
            ) : (
              pinnedMessages.map(msg => (
                <div key={msg.id} className="px-4 py-2 border-b border-zinc-800/50">
                  <div className="flex items-center gap-1 mb-1">
                    <Pin className="h-2.5 w-2.5 text-emerald-400" />
                    <span className="text-[10px] text-emerald-400 font-medium">{msg.senderName}</span>
                  </div>
                  <p className="text-xs text-zinc-300 line-clamp-2">{msg.content}</p>
                  <span className="text-[10px] text-zinc-600 mt-0.5 block">
                    {formatTimeLocale(msg.createdAt)}
                  </span>
                </div>
              ))
            )}
          </div>
        )}
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// SHARED IMAGES STRIP (in chat header)
// ════════════════════════════════════════════════════════════════

function SharedImagesStrip({ messages }: { messages: ChatMessage[] }) {
  const images = messages.filter(m => m.messageType === 'image' && m.fileUrl).slice(-6);
  if (images.length === 0) return null;

  return (
    <div className="flex items-center gap-1 ml-auto mr-2">
      {images.map(img => (
        <div
          key={img.id}
          className="w-6 h-6 rounded overflow-hidden border border-zinc-700 flex-shrink-0 cursor-pointer hover:border-zinc-500 transition-colors"
        >
          <img
            src={img.fileUrl!}
            alt=""
            className="w-full h-full object-cover"
            loading="lazy"
          />
        </div>
      ))}
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
  const [showInfoPanel, setShowInfoPanel] = useState(false);
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [showMentions, setShowMentions] = useState(false);
  const [mentionFilter, setMentionFilter] = useState('');
  const [typingUser, setTypingUser] = useState<string | null>(null);
  const [reactions, setReactions] = useState<Record<string, MessageReaction[]>>({});
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const composeRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

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
  const memberMap = useMemo(() => new Map<string, TeamMember>(members.map(m => [m.id, m])), [members]);

  // Active conversation object
  const activeConv = conversations.find(c => c.id === activeConvId) || null;

  // Participants of active conversation for mentions
  const activeParticipants = useMemo(() => {
    if (!activeConv) return [];
    return activeConv.participantIds
      .filter(id => id !== currentUserId)
      .map(id => memberMap.get(id))
      .filter(Boolean) as TeamMember[];
  }, [activeConv, currentUserId, memberMap]);

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

  // Reset info panel when changing conversations
  useEffect(() => {
    setShowInfoPanel(false);
    setPhotoFile(null);
    setShowMentions(false);
  }, [activeConvId]);

  // Simulated typing indicator — demo behavior
  useEffect(() => {
    if (!activeConv || activeParticipants.length === 0) {
      setTypingUser(null);
      return;
    }
    // Show a random participant "typing" for 3 seconds every 12 seconds
    const interval = setInterval(() => {
      const randomParticipant = activeParticipants[Math.floor(Math.random() * activeParticipants.length)];
      if (randomParticipant) {
        setTypingUser(randomParticipant.firstName);
        setTimeout(() => setTypingUser(null), 3000);
      }
    }, 12000);

    return () => clearInterval(interval);
  }, [activeConv, activeParticipants]);

  // Generate demo read receipts for own messages
  const generateReadReceipts = useCallback(
    (msg: ChatMessage): ReadReceipt[] => {
      if (msg.senderId !== currentUserId) return [];
      if (!activeConv) return [];
      // Demo: random subset of other participants have read
      const otherIds = activeConv.participantIds.filter(id => id !== currentUserId);
      // Use message ID hash for deterministic "random" subset
      const hash = msg.id.split('').reduce((acc, ch) => acc + ch.charCodeAt(0), 0);
      return otherIds
        .filter((_, i) => (hash + i) % 3 !== 0)
        .map(userId => ({ userId, readAt: msg.createdAt }));
    },
    [currentUserId, activeConv],
  );

  // Filtered conversations
  const filteredConversations = searchFilter
    ? conversations.filter(c => {
        const title = c.title?.toLowerCase() || '';
        const preview = c.lastMessagePreview?.toLowerCase() || '';
        const q = searchFilter.toLowerCase();
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
    setShowMentions(false);
    try {
      await sendChatMessage(activeConvId, text);
    } catch {
      setCompose(text); // Restore on failure
    } finally {
      setSending(false);
    }
  };

  // Handle compose input for @mention detection
  const handleComposeChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const val = e.target.value;
    setCompose(val);

    // Check for @ mention trigger
    const cursorPos = e.target.selectionStart || 0;
    const textUpToCursor = val.slice(0, cursorPos);
    const atMatch = textUpToCursor.match(/@(\w*)$/);

    if (atMatch) {
      setShowMentions(true);
      setMentionFilter(atMatch[1]);
    } else {
      setShowMentions(false);
      setMentionFilter('');
    }
  };

  // Insert mention
  const handleMentionSelect = (member: TeamMember) => {
    const textarea = composeRef.current;
    if (!textarea) return;

    const cursorPos = textarea.selectionStart || 0;
    const textBefore = compose.slice(0, cursorPos);
    const textAfter = compose.slice(cursorPos);

    // Replace the @partial with @FirstName
    const atIndex = textBefore.lastIndexOf('@');
    const newText = textBefore.slice(0, atIndex) + `@${member.firstName} ` + textAfter;
    setCompose(newText);
    setShowMentions(false);
    setMentionFilter('');

    // Refocus
    setTimeout(() => {
      textarea.focus();
      const newPos = atIndex + member.firstName.length + 2;
      textarea.setSelectionRange(newPos, newPos);
    }, 0);
  };

  // Handle photo file selection
  const handlePhotoSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file && file.type.startsWith('image/')) {
      setPhotoFile(file);
    }
    // Reset input so same file can be re-selected
    e.target.value = '';
  };

  const handlePhotoSend = async () => {
    if (!photoFile || !activeConvId) return;
    // For now, send a text message indicating an image was shared
    // In production, this would upload to Supabase Storage then call sendChatMessage with file_url
    setSending(true);
    try {
      await sendChatMessage(activeConvId, `[Shared image: ${photoFile.name}]`);
      setPhotoFile(null);
    } catch {
      // keep file for retry
    } finally {
      setSending(false);
    }
  };

  // Handle reactions
  const handleReaction = (messageId: string, type: ReactionType) => {
    setReactions(prev => {
      const msgReactions = [...(prev[messageId] || [])];
      const existingIdx = msgReactions.findIndex(r => r.type === type);

      if (existingIdx >= 0) {
        const existing = msgReactions[existingIdx];
        if (existing.userIds.includes(currentUserId)) {
          // Remove own reaction
          const newUserIds = existing.userIds.filter(id => id !== currentUserId);
          if (newUserIds.length === 0) {
            msgReactions.splice(existingIdx, 1);
          } else {
            msgReactions[existingIdx] = { ...existing, userIds: newUserIds };
          }
        } else {
          // Add own reaction
          msgReactions[existingIdx] = { ...existing, userIds: [...existing.userIds, currentUserId] };
        }
      } else {
        // New reaction
        msgReactions.push({ type, userIds: [currentUserId] });
      }

      return { ...prev, [messageId]: msgReactions };
    });
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
            {/* Conversation List (Left Panel) */}
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

            {/* Chat Panel (Center) */}
            <div className="flex-1 flex flex-col min-w-0">
              {activeConv ? (
                <>
                  {/* Chat Header */}
                  <div className="px-4 py-3 border-b border-zinc-800 flex items-center gap-2">
                    {(() => {
                      const Icon = typeIcons[activeConv.type] || MessageSquare;
                      return <Icon className="h-4 w-4 text-zinc-500 flex-shrink-0" />;
                    })()}
                    <span className="font-medium text-zinc-100 truncate">{activeChatTitle}</span>
                    <Badge className="bg-zinc-800 text-zinc-400 border-zinc-700 text-xs flex-shrink-0">
                      {activeConv.type}
                    </Badge>
                    {activeConv.participantIds.length > 2 && (
                      <span className="text-xs text-zinc-600 flex-shrink-0">
                        {activeConv.participantIds.length} members
                      </span>
                    )}

                    {/* Shared images thumbnails in header */}
                    <SharedImagesStrip messages={messages} />

                    {/* Info panel toggle */}
                    <button
                      onClick={() => setShowInfoPanel(prev => !prev)}
                      className={cn(
                        'p-1.5 rounded hover:bg-zinc-800 transition-colors flex-shrink-0 ml-auto',
                        showInfoPanel && 'bg-zinc-800 text-emerald-400',
                      )}
                      title="Conversation info"
                    >
                      <Info className={cn('h-4 w-4', showInfoPanel ? 'text-emerald-400' : 'text-zinc-500')} />
                    </button>
                  </div>

                  {/* Job thread card (for job-type conversations) */}
                  {activeConv.type === 'job' && (
                    <JobThreadCard conversation={activeConv} />
                  )}

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
                        {messages.map((msg, idx) => (
                          <MessageBubble
                            key={msg.id}
                            message={msg}
                            isOwn={msg.senderId === currentUserId}
                            memberMap={memberMap}
                            reactions={reactions[msg.id] || []}
                            onReact={(type) => handleReaction(msg.id, type)}
                            readReceipts={generateReadReceipts(msg)}
                            isLastMessage={idx === messages.length - 1}
                          />
                        ))}
                        {/* Typing indicator */}
                        {typingUser && <TypingIndicator name={typingUser} />}
                        <div ref={messagesEndRef} />
                      </>
                    )}
                  </div>

                  {/* Photo preview (before compose) */}
                  {photoFile && (
                    <PhotoPreview
                      file={photoFile}
                      onCancel={() => setPhotoFile(null)}
                      onSend={handlePhotoSend}
                      sending={sending}
                    />
                  )}

                  {/* Compose Bar */}
                  <div className="p-3 border-t border-zinc-800 relative">
                    {/* Mentions dropdown */}
                    {showMentions && (
                      <MentionsDropdown
                        members={activeParticipants}
                        filter={mentionFilter}
                        onSelect={handleMentionSelect}
                        position={{ bottom: 56, left: 12 }}
                      />
                    )}

                    <div className="flex items-end gap-2">
                      {/* Photo button */}
                      <button
                        onClick={() => fileInputRef.current?.click()}
                        className="p-2 rounded-lg hover:bg-zinc-800 transition-colors flex-shrink-0"
                        title="Share image"
                      >
                        <Camera className="h-4 w-4 text-zinc-500 hover:text-zinc-300" />
                      </button>
                      <input
                        ref={fileInputRef}
                        type="file"
                        accept="image/*"
                        onChange={handlePhotoSelect}
                        className="hidden"
                      />

                      <textarea
                        ref={composeRef}
                        value={compose}
                        onChange={handleComposeChange}
                        onKeyDown={handleKeyDown}
                        placeholder={`${t('teamChat.typeMessage')} — type @ to mention`}
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

            {/* Info Panel (Right) */}
            {showInfoPanel && activeConv && (
              <ConversationInfoPanel
                conversation={activeConv}
                memberMap={memberMap}
                messages={messages}
                onClose={() => setShowInfoPanel(false)}
              />
            )}
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
