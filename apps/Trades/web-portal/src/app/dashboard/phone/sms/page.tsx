'use client';

import { useState, useRef, useEffect } from 'react';
import {
  MessageSquare,
  Send,
  Search,
  User,
  Phone,
  ArrowLeft,
  Clock,
  CheckCheck,
  AlertCircle,
  Image,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { useSmsThreads } from '@/lib/hooks/use-phone';
import type { SmsThread, SmsMessage } from '@/lib/hooks/use-phone';
import { formatRelativeTime, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

function ThreadItem({ thread, isActive, onClick }: { thread: SmsThread; isActive: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={cn(
        'w-full text-left px-4 py-3 hover:bg-surface-hover border-b border-main transition-colors',
        isActive && 'bg-secondary/70'
      )}
    >
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 rounded-full bg-secondary flex items-center justify-center flex-shrink-0">
          <User className="h-4 w-4 text-muted" />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between">
            <span className="font-medium text-main text-sm truncate">
              {thread.contactName || thread.contactNumber}
            </span>
            <span className="text-xs text-muted flex-shrink-0 ml-2">
              {formatRelativeTime(thread.lastMessageAt)}
            </span>
          </div>
          <p className="text-xs text-muted truncate mt-0.5">{thread.lastMessage}</p>
        </div>
      </div>
    </button>
  );
}

function MessageBubble({ message }: { message: SmsMessage }) {
  const isOutbound = message.direction === 'outbound';

  return (
    <div className={cn('flex mb-3', isOutbound ? 'justify-end' : 'justify-start')}>
      <div className={cn(
        'max-w-[70%] rounded-2xl px-4 py-2',
        isOutbound
          ? 'bg-emerald-600 text-white rounded-br-md'
          : 'bg-secondary text-main rounded-bl-md'
      )}>
        <p className="text-sm whitespace-pre-wrap">{message.body}</p>
        {message.mediaUrls.length > 0 && (
          <div className="flex items-center gap-1 mt-1 text-xs opacity-70">
            <Image className="h-3 w-3" />
            {message.mediaUrls.length} attachment{message.mediaUrls.length > 1 ? 's' : ''}
          </div>
        )}
        <div className={cn(
          'flex items-center gap-1 mt-1 text-xs',
          isOutbound ? 'text-emerald-200/70 justify-end' : 'text-muted'
        )}>
          <span>{formatTimeLocale(message.createdAt)}</span>
          {isOutbound && message.status === 'delivered' && <CheckCheck className="h-3 w-3" />}
          {isOutbound && message.status === 'failed' && <AlertCircle className="h-3 w-3 text-red-300" />}
          {message.isAutomated && <Badge className="text-[10px] px-1 py-0 bg-secondary">auto</Badge>}
        </div>
      </div>
    </div>
  );
}

export default function SmsPage() {
  const { t } = useTranslation();
  const { threads, loading, error, sendSms } = useSmsThreads();
  const [activeThread, setActiveThread] = useState<SmsThread | null>(null);
  const [search, setSearch] = useState('');
  const [newMessage, setNewMessage] = useState('');
  const [sending, setSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [activeThread?.messages]);

  const filteredThreads = threads.filter(t => {
    if (!search) return true;
    const q = search.toLowerCase();
    return t.contactNumber.includes(q) || t.contactName?.toLowerCase().includes(q) ||
      t.lastMessage.toLowerCase().includes(q);
  });

  const handleSend = async () => {
    if (!newMessage.trim() || !activeThread || sending) return;
    try {
      setSending(true);
      await sendSms(activeThread.contactNumber, newMessage.trim(), activeThread.customerId || undefined);
      setNewMessage('');
    } catch (e) {
      console.error('Failed to send:', e);
    } finally {
      setSending(false);
    }
  };

  return (
    <>
      <CommandPalette />
      <div className="space-y-4">
        <div>
          <h1 className="text-2xl font-bold text-main">{t('phoneSms.title')}</h1>
          <p className="text-sm text-muted mt-1">{t('phoneSms.smsConversationsWithCustomers')}</p>
        </div>

        <Card className="bg-surface border-main overflow-hidden">
          <div className="flex h-[calc(100vh-220px)]">
            {/* Thread list */}
            <div className="w-80 border-r border-main flex flex-col">
              <div className="p-3 border-b border-main">
                <SearchInput
                  placeholder="Search conversations..."
                  value={search}
                  onChange={(v) => setSearch(v)}
                  className="w-full"
                />
              </div>
              <div className="flex-1 overflow-y-auto">
                {loading ? (
                  <div className="flex items-center justify-center py-12 text-muted">{t('common.loading')}</div>
                ) : filteredThreads.length === 0 ? (
                  <div className="flex flex-col items-center justify-center py-12 text-muted">
                    <MessageSquare className="h-8 w-8 mb-2 opacity-50" />
                    <p className="text-sm">{t('phoneSms.noConversations')}</p>
                  </div>
                ) : (
                  filteredThreads.map(thread => (
                    <ThreadItem
                      key={thread.contactNumber}
                      thread={thread}
                      isActive={activeThread?.contactNumber === thread.contactNumber}
                      onClick={() => setActiveThread(thread)}
                    />
                  ))
                )}
              </div>
            </div>

            {/* Message view */}
            <div className="flex-1 flex flex-col">
              {activeThread ? (
                <>
                  {/* Header */}
                  <div className="flex items-center gap-3 px-4 py-3 border-b border-main">
                    <Button
                      variant="ghost"
                      size="sm"
                      className="h-8 w-8 p-0 lg:hidden"
                      onClick={() => setActiveThread(null)}
                    >
                      <ArrowLeft className="h-4 w-4" />
                    </Button>
                    <div className="w-8 h-8 rounded-full bg-secondary flex items-center justify-center">
                      <User className="h-4 w-4 text-muted" />
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-main text-sm">
                        {activeThread.contactName || activeThread.contactNumber}
                      </p>
                      {activeThread.contactName && (
                        <p className="text-xs text-muted">{activeThread.contactNumber}</p>
                      )}
                    </div>
                    <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                      <Phone className="h-4 w-4" />
                    </Button>
                  </div>

                  {/* Messages */}
                  <div className="flex-1 overflow-y-auto p-4">
                    {activeThread.messages.map(msg => (
                      <MessageBubble key={msg.id} message={msg} />
                    ))}
                    <div ref={messagesEndRef} />
                  </div>

                  {/* Compose */}
                  <div className="p-3 border-t border-main">
                    <div className="flex items-center gap-2">
                      <input
                        type="text"
                        placeholder={t('teamChat.typeMessage')}
                        value={newMessage}
                        onChange={(e) => setNewMessage(e.target.value)}
                        onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleSend()}
                        className="flex-1 bg-secondary text-main rounded-full px-4 py-2 text-sm border border-main focus:border-emerald-500 focus:outline-none"
                      />
                      <Button
                        size="sm"
                        onClick={handleSend}
                        disabled={!newMessage.trim() || sending}
                        className="h-9 w-9 rounded-full p-0 bg-emerald-600 hover:bg-emerald-700"
                      >
                        <Send className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </>
              ) : (
                <div className="flex-1 flex flex-col items-center justify-center text-muted">
                  <MessageSquare className="h-12 w-12 mb-3 opacity-30" />
                  <p className="text-sm">{t('phoneSms.selectAConversation')}</p>
                </div>
              )}
            </div>
          </div>
        </Card>
      </div>
    </>
  );
}
