'use client';

import { useState, useMemo, useRef, useEffect } from 'react';
import {
  Phone,
  PhoneIncoming,
  PhoneOutgoing,
  PhoneMissed,
  Voicemail,
  Clock,
  Play,
  Search,
  PhoneCall,
  Briefcase,
  Eye,
  MessageSquare,
  ArrowRightLeft,
  Send,
  ExternalLink,
  User,
  Reply,
  ChevronDown,
  Activity,
  Filter,
  MessageCircle,
} from 'lucide-react';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { StatsCard } from '@/components/ui/stats-card';
import { CommandPalette } from '@/components/command-palette';
import { usePhone, useSmsThreads } from '@/lib/hooks/use-phone';
import type { CallRecord, Voicemail as VoicemailType, SmsThread, SmsMessage } from '@/lib/hooks/use-phone';
import { useTranslation } from '@/lib/translations';
import { formatRelativeTime, cn } from '@/lib/utils';

// ============================================================================
// TYPES
// ============================================================================
type Tab = 'calls' | 'voicemail' | 'sms' | 'activity';

interface ActivityEntry {
  id: string;
  type: 'call' | 'sms' | 'voicemail';
  direction: 'inbound' | 'outbound' | 'internal';
  contactName: string;
  contactNumber: string;
  customerId: string | null;
  jobId: string | null;
  jobTitle?: string;
  timestamp: string;
  durationSeconds?: number;
  preview?: string;
  status?: string;
}

// ============================================================================
// QUICK TEMPLATES
// ============================================================================
const SMS_TEMPLATES = [
  { label: 'On my way!', body: 'On my way!' },
  { label: 'Running late', body: 'Running 15 min late' },
  { label: 'Job complete + invoice', body: 'Job complete — here\'s your invoice: {{link}}' },
  { label: 'Review request', body: 'Please leave us a review: {{link}}' },
  { label: 'Appointment reminder', body: 'We\'re scheduled for {{date}}. See you then!' },
];

// ============================================================================
// HELPERS
// ============================================================================
function formatDuration(seconds: number): string {
  if (seconds < 60) return `${seconds}s`;
  const min = Math.floor(seconds / 60);
  const sec = seconds % 60;
  return `${min}:${sec.toString().padStart(2, '0')}`;
}

function DirectionIcon({ direction, status }: { direction: string; status?: string }) {
  if (status === 'missed' || status === 'no_answer') {
    return <PhoneMissed className="h-4 w-4 text-red-500" />;
  }
  if (direction === 'inbound') return <PhoneIncoming className="h-4 w-4 text-blue-500" />;
  if (direction === 'outbound') return <PhoneOutgoing className="h-4 w-4 text-emerald-500" />;
  return <ArrowRightLeft className="h-4 w-4 text-violet-500" />;
}

function statusBadge(status: string) {
  const map: Record<string, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
    completed: { label: 'Completed', variant: 'success' },
    missed: { label: 'Missed', variant: 'error' },
    no_answer: { label: 'No Answer', variant: 'warning' },
    voicemail: { label: 'Voicemail', variant: 'purple' },
    in_progress: { label: 'In Progress', variant: 'info' },
    ringing: { label: 'Ringing', variant: 'warning' },
    failed: { label: 'Failed', variant: 'error' },
    busy: { label: 'Busy', variant: 'warning' },
    initiated: { label: 'Initiated', variant: 'secondary' },
    delivered: { label: 'Delivered', variant: 'success' },
    sent: { label: 'Sent', variant: 'info' },
    read: { label: 'Read', variant: 'success' },
  };
  const c = map[status] || { label: status, variant: 'default' as const };
  return <Badge variant={c.variant}>{c.label}</Badge>;
}

function directionBadge(direction: string) {
  if (direction === 'inbound') return <Badge variant="info">Inbound</Badge>;
  if (direction === 'outbound') return <Badge variant="success">Outbound</Badge>;
  return <Badge variant="purple">Internal</Badge>;
}

// ============================================================================
// CALL ROW
// ============================================================================
function CallRow({ call }: { call: CallRecord }) {
  const contactName = call.customerName || (call.direction === 'inbound' ? call.fromNumber : call.toNumber);
  const contactNumber = call.direction === 'inbound' ? call.fromNumber : call.toNumber;

  return (
    <div className="flex items-center gap-4 px-4 py-3 hover:bg-surface-hover border-b border-main">
      <DirectionIcon direction={call.direction} status={call.status} />
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-medium text-main truncate">{contactName}</span>
          {call.customerName && (
            <span className="text-xs text-muted">{contactNumber}</span>
          )}
          {call.customerId && (
            <a
              href={`/dashboard/customers/${call.customerId}`}
              className="text-blue-400 hover:text-blue-300 transition-colors"
              title="View customer"
            >
              <ExternalLink className="h-3 w-3" />
            </a>
          )}
        </div>
        <div className="flex items-center gap-3 text-xs text-muted mt-0.5">
          {call.jobId && call.jobTitle && (
            <a
              href={`/dashboard/jobs/${call.jobId}`}
              className="flex items-center gap-1 hover:text-blue-400 transition-colors"
            >
              <Briefcase className="h-3 w-3" />
              {call.jobTitle}
            </a>
          )}
          {!call.jobId && call.jobTitle && (
            <span className="flex items-center gap-1">
              <Briefcase className="h-3 w-3" />
              {call.jobTitle}
            </span>
          )}
          {call.aiSummary && (
            <span className="truncate max-w-xs">{call.aiSummary}</span>
          )}
        </div>
      </div>
      <div className="flex items-center gap-3 text-sm">
        {statusBadge(call.status)}
        {call.durationSeconds > 0 && (
          <span className="text-muted tabular-nums w-12 text-right">{formatDuration(call.durationSeconds)}</span>
        )}
        <span className="text-muted text-xs w-20 text-right">{formatRelativeTime(call.startedAt)}</span>
        {call.recordingPath && (
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0">
            <Play className="h-3.5 w-3.5" />
          </Button>
        )}
      </div>
    </div>
  );
}

// ============================================================================
// VOICEMAIL ROW
// ============================================================================
function VoicemailRow({
  vm,
  onMarkRead,
  onQuickReply,
}: {
  vm: VoicemailType;
  onMarkRead: (id: string) => void;
  onQuickReply: (number: string) => void;
}) {
  return (
    <div className={cn(
      'flex items-start gap-4 px-4 py-3 hover:bg-surface-hover border-b border-main',
      !vm.isRead && 'bg-secondary/30'
    )}>
      <div className="mt-1">
        <Voicemail className={cn('h-4 w-4', vm.isRead ? 'text-muted' : 'text-blue-400')} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          {!vm.isRead && <span className="w-2 h-2 rounded-full bg-blue-500 flex-shrink-0" />}
          <span className="font-medium text-main">{vm.customerName || vm.fromNumber}</span>
          {vm.customerName && <span className="text-xs text-muted">{vm.fromNumber}</span>}
        </div>
        {vm.transcript && (
          <p className="text-sm text-muted mt-1 line-clamp-2">{vm.transcript}</p>
        )}
        {vm.aiIntent && (
          <p className="text-xs text-violet-400 mt-1">Intent: {vm.aiIntent}</p>
        )}
      </div>
      <div className="flex items-center gap-2 text-sm flex-shrink-0">
        {vm.durationSeconds && (
          <span className="text-muted tabular-nums">{formatDuration(vm.durationSeconds)}</span>
        )}
        <span className="text-muted text-xs">{formatRelativeTime(vm.createdAt)}</span>
        <Button variant="ghost" size="sm" className="h-7 w-7 p-0">
          <Play className="h-3.5 w-3.5" />
        </Button>
        <Button
          variant="ghost"
          size="sm"
          className="h-7 w-7 p-0"
          onClick={() => onQuickReply(vm.fromNumber)}
          title="Reply via SMS"
        >
          <Reply className="h-3.5 w-3.5" />
        </Button>
        {!vm.isRead && (
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={() => onMarkRead(vm.id)}>
            <Eye className="h-3.5 w-3.5" />
          </Button>
        )}
      </div>
    </div>
  );
}

// ============================================================================
// SMS THREAD LIST ITEM
// ============================================================================
function ThreadListItem({
  thread,
  isActive,
  onClick,
}: {
  thread: SmsThread;
  isActive: boolean;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className={cn(
        'w-full text-left px-4 py-3 border-b border-main hover:bg-surface-hover transition-colors',
        isActive && 'bg-secondary/70'
      )}
    >
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-2 min-w-0">
          <div className="w-8 h-8 rounded-full bg-secondary flex items-center justify-center flex-shrink-0">
            <User className="h-4 w-4 text-muted" />
          </div>
          <div className="min-w-0">
            <p className="font-medium text-main text-sm truncate">
              {thread.contactName || thread.contactNumber}
            </p>
            {thread.contactName && (
              <p className="text-xs text-muted truncate">{thread.contactNumber}</p>
            )}
          </div>
        </div>
        <div className="flex flex-col items-end gap-1 flex-shrink-0">
          <span className="text-xs text-muted">{formatRelativeTime(thread.lastMessageAt)}</span>
          {thread.unreadCount > 0 && (
            <span className="bg-blue-500 text-white text-xs rounded-full min-w-[18px] h-[18px] flex items-center justify-center px-1">
              {thread.unreadCount}
            </span>
          )}
        </div>
      </div>
      <p className="text-xs text-muted mt-1 truncate pl-10">{thread.lastMessage}</p>
    </button>
  );
}

// ============================================================================
// SMS MESSAGE BUBBLE
// ============================================================================
function MessageBubble({ message }: { message: SmsMessage }) {
  const isOutbound = message.direction === 'outbound';
  return (
    <div className={cn('flex mb-3', isOutbound ? 'justify-end' : 'justify-start')}>
      <div className={cn(
        'max-w-[70%] rounded-2xl px-4 py-2.5',
        isOutbound
          ? 'bg-blue-600 text-white rounded-br-md'
          : 'bg-secondary text-main rounded-bl-md'
      )}>
        <p className="text-sm whitespace-pre-wrap break-words">{message.body}</p>
        <div className={cn(
          'flex items-center gap-2 mt-1 text-xs',
          isOutbound ? 'text-blue-200' : 'text-muted'
        )}>
          <span>{formatRelativeTime(message.createdAt)}</span>
          {message.isAutomated && <Badge variant="secondary">Auto</Badge>}
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// SMS TAB PANEL
// ============================================================================
function SmsPanel() {
  const { t } = useTranslation();
  const { threads, loading: smsLoading, error: smsError, sendSms } = useSmsThreads();
  const [activeThreadNumber, setActiveThreadNumber] = useState<string | null>(null);
  const [composeText, setComposeText] = useState('');
  const [sending, setSending] = useState(false);
  const [threadSearch, setThreadSearch] = useState('');
  const [showTemplates, setShowTemplates] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const composeRef = useRef<HTMLTextAreaElement>(null);

  const activeThread = threads.find(th => th.contactNumber === activeThreadNumber) || null;

  // Auto-select first thread if none active
  useEffect(() => {
    if (!activeThreadNumber && threads.length > 0) {
      setActiveThreadNumber(threads[0].contactNumber);
    }
  }, [threads, activeThreadNumber]);

  // Scroll to bottom when active thread changes
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [activeThread?.messages?.length, activeThreadNumber]);

  const filteredThreads = useMemo(() => {
    if (!threadSearch) return threads;
    const q = threadSearch.toLowerCase();
    return threads.filter(th =>
      th.contactName?.toLowerCase().includes(q) ||
      th.contactNumber.includes(q) ||
      th.lastMessage.toLowerCase().includes(q)
    );
  }, [threads, threadSearch]);

  const handleSend = async () => {
    if (!composeText.trim() || !activeThread) return;
    setSending(true);
    try {
      await sendSms(
        activeThread.contactNumber,
        composeText.trim(),
        activeThread.customerId || undefined
      );
      setComposeText('');
    } catch {
      // Error handled by hook
    } finally {
      setSending(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const insertTemplate = (body: string) => {
    setComposeText(prev => prev ? `${prev} ${body}` : body);
    setShowTemplates(false);
    composeRef.current?.focus();
  };

  if (smsLoading) {
    return (
      <div className="flex items-center justify-center py-12 text-muted">
        {t('common.loading')}
      </div>
    );
  }

  if (smsError) {
    return (
      <div className="flex items-center justify-center py-12 text-red-400">
        {smsError}
      </div>
    );
  }

  if (threads.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-muted">
        <MessageSquare className="h-8 w-8 mb-2 opacity-50" />
        <p>No SMS conversations</p>
        <p className="text-xs mt-1">Messages will appear here when your phone system is active</p>
      </div>
    );
  }

  return (
    <div className="flex h-[520px]">
      {/* Thread list */}
      <div className="w-80 border-r border-main flex flex-col">
        <div className="p-3 border-b border-main">
          <SearchInput
            placeholder="Search conversations..."
            value={threadSearch}
            onChange={setThreadSearch}
            className="w-full"
          />
        </div>
        <div className="flex-1 overflow-y-auto">
          {filteredThreads.map(thread => (
            <ThreadListItem
              key={thread.contactNumber}
              thread={thread}
              isActive={thread.contactNumber === activeThreadNumber}
              onClick={() => setActiveThreadNumber(thread.contactNumber)}
            />
          ))}
          {filteredThreads.length === 0 && (
            <p className="text-center text-xs text-muted py-8">No threads match your search</p>
          )}
        </div>
      </div>

      {/* Conversation area */}
      <div className="flex-1 flex flex-col min-w-0">
        {activeThread ? (
          <>
            {/* Thread header */}
            <div className="flex items-center justify-between px-4 py-3 border-b border-main">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-secondary flex items-center justify-center">
                  <User className="h-4 w-4 text-muted" />
                </div>
                <div>
                  <p className="font-medium text-main text-sm">
                    {activeThread.contactName || activeThread.contactNumber}
                  </p>
                  {activeThread.contactName && (
                    <p className="text-xs text-muted">{activeThread.contactNumber}</p>
                  )}
                </div>
              </div>
              {activeThread.customerId && (
                <a
                  href={`/dashboard/customers/${activeThread.customerId}`}
                  className="text-blue-400 hover:text-blue-300 transition-colors flex items-center gap-1 text-xs"
                >
                  <ExternalLink className="h-3.5 w-3.5" />
                  View Customer
                </a>
              )}
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4">
              {activeThread.messages.map(msg => (
                <MessageBubble key={msg.id} message={msg} />
              ))}
              <div ref={messagesEndRef} />
            </div>

            {/* Compose bar */}
            <div className="border-t border-main p-3">
              <div className="flex items-end gap-2">
                <div className="relative flex-1">
                  <textarea
                    ref={composeRef}
                    value={composeText}
                    onChange={e => setComposeText(e.target.value)}
                    onKeyDown={handleKeyDown}
                    placeholder="Type a message... (Enter to send, Shift+Enter for new line)"
                    className="w-full bg-secondary border border-main rounded-lg px-3 py-2 text-sm text-main placeholder-muted resize-none focus:outline-none focus:ring-1 focus:ring-blue-500 min-h-[40px] max-h-[120px]"
                    rows={1}
                  />
                </div>
                <div className="relative">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setShowTemplates(!showTemplates)}
                    className="h-9 px-2"
                    title="Quick Templates"
                  >
                    <ChevronDown className="h-4 w-4" />
                  </Button>
                  {showTemplates && (
                    <div className="absolute bottom-full right-0 mb-1 w-64 bg-surface border border-main rounded-lg shadow-xl z-20">
                      <p className="px-3 py-2 text-xs font-medium text-muted border-b border-main">
                        Quick Templates
                      </p>
                      {SMS_TEMPLATES.map((tpl, i) => (
                        <button
                          key={i}
                          onClick={() => insertTemplate(tpl.body)}
                          className="w-full text-left px-3 py-2 text-sm text-main hover:bg-surface-hover transition-colors"
                        >
                          {tpl.label}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
                <Button
                  variant="primary"
                  size="sm"
                  onClick={handleSend}
                  disabled={!composeText.trim() || sending}
                  loading={sending}
                  className="h-9"
                >
                  <Send className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-muted">
            <div className="text-center">
              <MessageSquare className="h-8 w-8 mx-auto mb-2 opacity-50" />
              <p className="text-sm">Select a conversation</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ============================================================================
// ACTIVITY LOG ENTRY
// ============================================================================
function ActivityLogEntry({ entry }: { entry: ActivityEntry }) {
  const typeIcon = () => {
    if (entry.type === 'call') return <PhoneCall className="h-4 w-4 text-blue-400" />;
    if (entry.type === 'sms') return <MessageSquare className="h-4 w-4 text-emerald-400" />;
    return <Voicemail className="h-4 w-4 text-violet-400" />;
  };

  const typeLabel = () => {
    if (entry.type === 'call') return 'Call';
    if (entry.type === 'sms') return 'SMS';
    return 'Voicemail';
  };

  return (
    <div className="flex items-center gap-4 px-4 py-3 hover:bg-surface-hover border-b border-main">
      <div className="flex-shrink-0">{typeIcon()}</div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-medium text-main text-sm truncate">{entry.contactName}</span>
          {entry.contactName !== entry.contactNumber && (
            <span className="text-xs text-muted">{entry.contactNumber}</span>
          )}
          {entry.customerId && (
            <a
              href={`/dashboard/customers/${entry.customerId}`}
              className="text-blue-400 hover:text-blue-300 transition-colors"
              title="View customer"
            >
              <ExternalLink className="h-3 w-3" />
            </a>
          )}
        </div>
        {entry.preview && (
          <p className="text-xs text-muted mt-0.5 truncate max-w-md">{entry.preview}</p>
        )}
        {entry.jobId && entry.jobTitle && (
          <a
            href={`/dashboard/jobs/${entry.jobId}`}
            className="flex items-center gap-1 text-xs text-muted mt-0.5 hover:text-blue-400 transition-colors"
          >
            <Briefcase className="h-3 w-3" />
            {entry.jobTitle}
          </a>
        )}
      </div>
      <div className="flex items-center gap-3 text-sm flex-shrink-0">
        <Badge variant={entry.type === 'call' ? 'info' : entry.type === 'sms' ? 'success' : 'purple'}>
          {typeLabel()}
        </Badge>
        {directionBadge(entry.direction)}
        {entry.status && entry.type === 'call' && statusBadge(entry.status)}
        {entry.durationSeconds !== undefined && entry.durationSeconds > 0 && (
          <span className="text-muted tabular-nums text-xs">{formatDuration(entry.durationSeconds)}</span>
        )}
        <span className="text-muted text-xs w-20 text-right">{formatRelativeTime(entry.timestamp)}</span>
      </div>
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================
export default function PhonePage() {
  const { t } = useTranslation();
  const { calls, voicemails, lines, loading, error, markVoicemailRead } = usePhone();
  const { threads, messages: smsMessages, loading: smsLoading } = useSmsThreads();
  const [tab, setTab] = useState<Tab>('calls');
  const [search, setSearch] = useState('');
  const [directionFilter, setDirectionFilter] = useState('all');
  const [activityTypeFilter, setActivityTypeFilter] = useState('all');

  const unreadVm = voicemails.filter(v => !v.isRead).length;
  const totalUnreadSms = threads.reduce((sum, th) => sum + th.unreadCount, 0);

  // ---- Filtered calls ----
  const filteredCalls = useMemo(() => {
    return calls.filter(c => {
      if (search) {
        const q = search.toLowerCase();
        const match = c.fromNumber.includes(q) || c.toNumber.includes(q) ||
          c.customerName?.toLowerCase().includes(q) || c.jobTitle?.toLowerCase().includes(q);
        if (!match) return false;
      }
      if (directionFilter !== 'all' && c.direction !== directionFilter) return false;
      return true;
    });
  }, [calls, search, directionFilter]);

  // ---- Filtered voicemails ----
  const filteredVm = useMemo(() => {
    return voicemails.filter(v => {
      if (!search) return true;
      const q = search.toLowerCase();
      return v.fromNumber.includes(q) || v.customerName?.toLowerCase().includes(q) ||
        v.transcript?.toLowerCase().includes(q);
    });
  }, [voicemails, search]);

  // ---- Stats ----
  const todayCalls = useMemo(() => {
    return calls.filter(c => {
      const d = new Date(c.startedAt);
      const now = new Date();
      return d.toDateString() === now.toDateString();
    });
  }, [calls]);

  const missedToday = todayCalls.filter(c => c.status === 'missed' || c.status === 'no_answer').length;
  const avgDuration = todayCalls.length > 0
    ? Math.round(todayCalls.reduce((s, c) => s + c.durationSeconds, 0) / todayCalls.length)
    : 0;

  // ---- Activity log ----
  const activityLog = useMemo((): ActivityEntry[] => {
    const entries: ActivityEntry[] = [];

    // Calls
    for (const c of calls) {
      entries.push({
        id: `call-${c.id}`,
        type: 'call',
        direction: c.direction,
        contactName: c.customerName || (c.direction === 'inbound' ? c.fromNumber : c.toNumber),
        contactNumber: c.direction === 'inbound' ? c.fromNumber : c.toNumber,
        customerId: c.customerId,
        jobId: c.jobId,
        jobTitle: c.jobTitle,
        timestamp: c.startedAt,
        durationSeconds: c.durationSeconds,
        preview: c.aiSummary || undefined,
        status: c.status,
      });
    }

    // SMS
    for (const msg of smsMessages) {
      entries.push({
        id: `sms-${msg.id}`,
        type: 'sms',
        direction: msg.direction,
        contactName: msg.customerName || (msg.direction === 'inbound' ? msg.fromNumber : msg.toNumber),
        contactNumber: msg.direction === 'inbound' ? msg.fromNumber : msg.toNumber,
        customerId: msg.customerId,
        jobId: msg.jobId,
        jobTitle: undefined,
        timestamp: msg.createdAt,
        preview: msg.body.length > 80 ? msg.body.slice(0, 80) + '...' : msg.body,
      });
    }

    // Voicemails
    for (const vm of voicemails) {
      entries.push({
        id: `vm-${vm.id}`,
        type: 'voicemail',
        direction: 'inbound',
        contactName: vm.customerName || vm.fromNumber,
        contactNumber: vm.fromNumber,
        customerId: vm.customerId,
        jobId: null,
        jobTitle: undefined,
        timestamp: vm.createdAt,
        durationSeconds: vm.durationSeconds || undefined,
        preview: vm.transcript || undefined,
      });
    }

    // Sort chronologically descending
    entries.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
    return entries;
  }, [calls, smsMessages, voicemails]);

  const filteredActivity = useMemo(() => {
    let result = activityLog;
    if (activityTypeFilter !== 'all') {
      result = result.filter(e => e.type === activityTypeFilter);
    }
    if (search) {
      const q = search.toLowerCase();
      result = result.filter(e =>
        e.contactName.toLowerCase().includes(q) ||
        e.contactNumber.includes(q) ||
        e.preview?.toLowerCase().includes(q) ||
        e.jobTitle?.toLowerCase().includes(q)
      );
    }
    return result;
  }, [activityLog, activityTypeFilter, search]);

  // Quick-reply from voicemail: switch to SMS tab and select the thread
  const handleVoicemailQuickReply = (number: string) => {
    setTab('sms');
    // The SMS panel will auto-select or the user can find the thread
  };

  return (
    <>
      <CommandPalette />
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-main">{t('phone.title')}</h1>
            <p className="text-sm text-muted mt-1">{lines.length} active lines</p>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-5 gap-4">
          <StatsCard
            title="Calls Today"
            value={todayCalls.length}
            icon={<Phone className="h-4 w-4" />}
          />
          <StatsCard
            title="Missed"
            value={missedToday}
            icon={<PhoneMissed className="h-4 w-4" />}
            trend={missedToday > 0 ? 'down' : 'neutral'}
          />
          <StatsCard
            title="Avg Duration"
            value={formatDuration(avgDuration)}
            icon={<Clock className="h-4 w-4" />}
          />
          <StatsCard
            title="Voicemails"
            value={unreadVm > 0 ? `${voicemails.length} (${unreadVm} new)` : `${voicemails.length}`}
            icon={<Voicemail className="h-4 w-4" />}
          />
          <StatsCard
            title="SMS Threads"
            value={totalUnreadSms > 0 ? `${threads.length} (${totalUnreadSms} unread)` : `${threads.length}`}
            icon={<MessageSquare className="h-4 w-4" />}
          />
        </div>

        {/* Tab bar + filters */}
        <Card className="bg-surface border-main">
          <CardHeader className="pb-0">
            <div className="flex items-center justify-between">
              <div className="flex gap-1">
                <Button
                  variant={tab === 'calls' ? 'default' : 'ghost'}
                  size="sm"
                  onClick={() => setTab('calls')}
                  className="gap-2"
                >
                  <PhoneCall className="h-4 w-4" />
                  Calls
                </Button>
                <Button
                  variant={tab === 'voicemail' ? 'default' : 'ghost'}
                  size="sm"
                  onClick={() => setTab('voicemail')}
                  className="gap-2"
                >
                  <Voicemail className="h-4 w-4" />
                  Voicemail
                  {unreadVm > 0 && (
                    <span className="bg-blue-500 text-white text-xs rounded-full px-1.5 py-0.5 ml-1">{unreadVm}</span>
                  )}
                </Button>
                <Button
                  variant={tab === 'sms' ? 'default' : 'ghost'}
                  size="sm"
                  onClick={() => setTab('sms')}
                  className="gap-2"
                >
                  <MessageCircle className="h-4 w-4" />
                  SMS
                  {totalUnreadSms > 0 && (
                    <span className="bg-blue-500 text-white text-xs rounded-full px-1.5 py-0.5 ml-1">{totalUnreadSms}</span>
                  )}
                </Button>
                <Button
                  variant={tab === 'activity' ? 'default' : 'ghost'}
                  size="sm"
                  onClick={() => setTab('activity')}
                  className="gap-2"
                >
                  <Activity className="h-4 w-4" />
                  Activity Log
                </Button>
              </div>
              <div className="flex items-center gap-2">
                {tab !== 'sms' && (
                  <SearchInput
                    placeholder={t('common.searchPlaceholder')}
                    value={search}
                    onChange={(v) => setSearch(v)}
                    className="w-60"
                  />
                )}
                {tab === 'calls' && (
                  <Select
                    value={directionFilter}
                    onChange={(e) => setDirectionFilter(e.target.value)}
                    options={[
                      { value: 'all', label: 'All calls' },
                      { value: 'inbound', label: 'Inbound' },
                      { value: 'outbound', label: 'Outbound' },
                      { value: 'internal', label: 'Internal' },
                    ]}
                    className="w-36"
                  />
                )}
                {tab === 'activity' && (
                  <Select
                    value={activityTypeFilter}
                    onChange={(e) => setActivityTypeFilter(e.target.value)}
                    options={[
                      { value: 'all', label: 'All activity' },
                      { value: 'call', label: 'Calls only' },
                      { value: 'sms', label: 'SMS only' },
                      { value: 'voicemail', label: 'Voicemails only' },
                    ]}
                    className="w-40"
                  />
                )}
              </div>
            </div>
          </CardHeader>
          <CardContent className="p-0 mt-4">
            {/* ============ CALLS TAB ============ */}
            {tab === 'calls' && (
              loading ? (
                <div className="flex items-center justify-center py-12 text-muted">
                  {t('common.loading')}
                </div>
              ) : error ? (
                <div className="flex items-center justify-center py-12 text-red-400">{error}</div>
              ) : filteredCalls.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 text-muted">
                  <Phone className="h-8 w-8 mb-2 opacity-50" />
                  <p>{t('phone.noCallsTitle')}</p>
                  <p className="text-xs mt-1">{t('common.callsWillAppearHereOnceYourPhoneSystemIsActive')}</p>
                </div>
              ) : (
                <div className="divide-y divide-main">
                  {filteredCalls.map(call => (
                    <CallRow key={call.id} call={call} />
                  ))}
                </div>
              )
            )}

            {/* ============ VOICEMAIL TAB ============ */}
            {tab === 'voicemail' && (
              loading ? (
                <div className="flex items-center justify-center py-12 text-muted">
                  {t('common.loading')}
                </div>
              ) : error ? (
                <div className="flex items-center justify-center py-12 text-red-400">{error}</div>
              ) : filteredVm.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 text-muted">
                  <Voicemail className="h-8 w-8 mb-2 opacity-50" />
                  <p>{t('common.noVoicemails')}</p>
                </div>
              ) : (
                <div className="divide-y divide-main">
                  {filteredVm.map(vm => (
                    <VoicemailRow
                      key={vm.id}
                      vm={vm}
                      onMarkRead={markVoicemailRead}
                      onQuickReply={handleVoicemailQuickReply}
                    />
                  ))}
                </div>
              )
            )}

            {/* ============ SMS TAB ============ */}
            {tab === 'sms' && <SmsPanel />}

            {/* ============ ACTIVITY LOG TAB ============ */}
            {tab === 'activity' && (
              (loading || smsLoading) ? (
                <div className="flex items-center justify-center py-12 text-muted">
                  {t('common.loading')}
                </div>
              ) : error ? (
                <div className="flex items-center justify-center py-12 text-red-400">{error}</div>
              ) : filteredActivity.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 text-muted">
                  <Activity className="h-8 w-8 mb-2 opacity-50" />
                  <p>No activity to display</p>
                  <p className="text-xs mt-1">Call, SMS, and voicemail activity will appear here</p>
                </div>
              ) : (
                <div className="divide-y divide-main">
                  {filteredActivity.map(entry => (
                    <ActivityLogEntry key={entry.id} entry={entry} />
                  ))}
                </div>
              )
            )}
          </CardContent>
        </Card>
      </div>
    </>
  );
}
