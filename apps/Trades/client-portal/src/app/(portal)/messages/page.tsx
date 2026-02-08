'use client';

import { useState, useEffect, useRef, type FormEvent } from 'react';
import { Send, ArrowLeft, CheckCheck, Check, Clock, AlertCircle, Loader2 } from 'lucide-react';
import Link from 'next/link';
import { useMessages, type SmsMessageData } from '@/lib/hooks/use-messages';
import { useAuth } from '@/components/auth-provider';

function formatTime(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
}

function formatDateHeader(dateStr: string): string {
  const date = new Date(dateStr);
  const now = new Date();
  const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return date.toLocaleDateString('en-US', { weekday: 'long' });
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function StatusIcon({ status }: { status: string }) {
  switch (status) {
    case 'delivered':
      return <CheckCheck size={12} className="text-orange-200" />;
    case 'sent':
      return <Check size={12} className="text-orange-300" />;
    case 'queued':
      return <Clock size={12} className="text-orange-300" />;
    case 'failed':
      return <AlertCircle size={12} className="text-red-300" />;
    default:
      return <Check size={12} className="text-orange-300" />;
  }
}

function shouldShowDateHeader(messages: SmsMessageData[], index: number): boolean {
  if (index === 0) return true;
  const curr = new Date(messages[index].createdAt).toDateString();
  const prev = new Date(messages[index - 1].createdAt).toDateString();
  return curr !== prev;
}

function LoadingSkeleton() {
  return (
    <div className="flex flex-col h-[calc(100vh-10rem)] md:h-[calc(100vh-7rem)]">
      <div className="flex items-center gap-3 pb-4 border-b" style={{ borderColor: 'var(--border-light)' }}>
        <div className="w-10 h-10 rounded-full animate-pulse" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        <div className="space-y-2">
          <div className="h-4 w-32 rounded animate-pulse" style={{ backgroundColor: 'var(--bg-secondary)' }} />
          <div className="h-3 w-48 rounded animate-pulse" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        </div>
      </div>
      <div className="flex-1 py-4 space-y-3">
        {[1, 2, 3, 4, 5].map(i => (
          <div key={i} className={`flex ${i % 2 === 0 ? 'justify-end' : 'justify-start'}`}>
            <div className="h-12 rounded-2xl animate-pulse" style={{ backgroundColor: 'var(--bg-secondary)', width: `${50 + (i * 5)}%`, maxWidth: '80%' }} />
          </div>
        ))}
      </div>
    </div>
  );
}

function EmptyState() {
  return (
    <div className="flex flex-col h-[calc(100vh-10rem)] md:h-[calc(100vh-7rem)]">
      <div className="flex items-center gap-3 pb-4 border-b" style={{ borderColor: 'var(--border-light)' }}>
        <Link href="/menu" className="p-2 rounded-lg transition-colors md:hidden" style={{ color: 'var(--text-muted)' }}>
          <ArrowLeft size={18} />
        </Link>
        <h2 className="font-bold text-sm" style={{ color: 'var(--text)' }}>Messages</h2>
      </div>
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center px-8">
          <div className="w-16 h-16 rounded-full mx-auto mb-4 flex items-center justify-center" style={{ backgroundColor: 'var(--bg-secondary)' }}>
            <Send size={24} style={{ color: 'var(--text-muted)' }} />
          </div>
          <p className="text-sm font-semibold" style={{ color: 'var(--text)' }}>No messages yet</p>
          <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>
            When your contractor sends you a text, it will appear here.
          </p>
        </div>
      </div>
    </div>
  );
}

export default function MessagesPage() {
  const { profile } = useAuth();
  const { messages, loading, error, sending, sendMessage } = useMessages();
  const [newMsg, setNewMsg] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!newMsg.trim() || sending) return;
    const msg = newMsg;
    setNewMsg('');
    await sendMessage(msg);
  };

  if (loading) return <LoadingSkeleton />;
  if (!profile?.customerId) {
    return (
      <div className="flex items-center justify-center h-[calc(100vh-10rem)] md:h-[calc(100vh-7rem)]">
        <p className="text-sm" style={{ color: 'var(--text-muted)' }}>Please sign in to view messages.</p>
      </div>
    );
  }
  if (messages.length === 0 && !error) return <EmptyState />;

  return (
    <div className="flex flex-col h-[calc(100vh-10rem)] md:h-[calc(100vh-7rem)]">
      {/* Header */}
      <div className="flex items-center gap-3 pb-4 border-b" style={{ borderColor: 'var(--border-light)' }}>
        <Link href="/menu" className="p-2 rounded-lg transition-colors md:hidden" style={{ color: 'var(--text-muted)' }}>
          <ArrowLeft size={18} />
        </Link>
        <div className="w-10 h-10 rounded-full flex items-center justify-center" style={{ backgroundColor: 'var(--accent-light)' }}>
          <span className="text-xs font-semibold" style={{ color: 'var(--accent)' }}>
            {profile.displayName ? profile.displayName.split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2) : '?'}
          </span>
        </div>
        <div>
          <h2 className="font-bold text-sm" style={{ color: 'var(--text)' }}>Your Contractor</h2>
          <p className="text-xs" style={{ color: 'var(--text-muted)' }}>SMS Conversation</p>
        </div>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="mx-0 mt-3 px-3 py-2 rounded-lg text-xs flex items-center gap-2" style={{ backgroundColor: 'var(--error-light)', color: 'var(--error)' }}>
          <AlertCircle size={14} />
          <span>{error}</span>
        </div>
      )}

      {/* Messages */}
      <div className="flex-1 overflow-y-auto py-4 space-y-1">
        {messages.map((msg, idx) => {
          const isOutbound = msg.direction === 'outbound';
          const showDate = shouldShowDateHeader(messages, idx);
          return (
            <div key={msg.id}>
              {showDate && (
                <div className="flex justify-center my-3">
                  <span className="text-[10px] font-medium px-3 py-1 rounded-full" style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text-muted)' }}>
                    {formatDateHeader(msg.createdAt)}
                  </span>
                </div>
              )}
              <div className={`flex ${isOutbound ? 'justify-end' : 'justify-start'} mb-1.5`}>
                <div className={`max-w-[80%] px-4 py-2.5 rounded-2xl text-sm ${
                  isOutbound
                    ? 'rounded-br-md text-white'
                    : 'rounded-bl-md shadow-sm'
                }`} style={isOutbound
                  ? { backgroundColor: 'var(--accent)' }
                  : { backgroundColor: 'var(--surface)', border: '1px solid var(--border-light)', color: 'var(--text)' }
                }>
                  <p className="whitespace-pre-wrap break-words">{msg.body}</p>
                  {msg.mediaUrls.length > 0 && (
                    <div className="mt-2 space-y-1">
                      {msg.mediaUrls.map((url, i) => (
                        <a key={i} href={url} target="_blank" rel="noopener noreferrer"
                          className="block text-xs underline opacity-80">
                          Attachment {i + 1}
                        </a>
                      ))}
                    </div>
                  )}
                  <div className={`flex items-center gap-1 mt-1 ${isOutbound ? 'justify-end' : ''}`}>
                    <span className={`text-[10px] ${isOutbound ? 'opacity-70' : ''}`}
                      style={isOutbound ? { color: 'white' } : { color: 'var(--text-muted)' }}>
                      {formatTime(msg.createdAt)}
                    </span>
                    {isOutbound && <StatusIcon status={msg.status} />}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <form onSubmit={handleSubmit} className="border-t pt-3 flex items-center gap-2" style={{ borderColor: 'var(--border-light)' }}>
        <input
          value={newMsg}
          onChange={e => setNewMsg(e.target.value)}
          placeholder="Type a message..."
          disabled={sending}
          className="flex-1 px-4 py-2.5 rounded-xl border text-sm outline-none transition-colors"
          style={{
            borderColor: 'var(--border-light)',
            backgroundColor: 'var(--surface)',
            color: 'var(--text)',
          }}
          onFocus={e => { e.currentTarget.style.borderColor = 'var(--accent)'; }}
          onBlur={e => { e.currentTarget.style.borderColor = 'var(--border-light)'; }}
        />
        <button
          type="submit"
          disabled={!newMsg.trim() || sending}
          className="p-2.5 rounded-xl transition-all disabled:opacity-40"
          style={{ backgroundColor: 'var(--accent)', color: 'white' }}
        >
          {sending ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />}
        </button>
      </form>
    </div>
  );
}
