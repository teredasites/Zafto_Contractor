'use client';

import { useState } from 'react';
import {
  Phone, PhoneIncoming, PhoneOutgoing, PhoneMissed,
  Voicemail, MessageSquare, Send, Clock,
} from 'lucide-react';
import { usePhone } from '@/lib/hooks/use-phone';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { cn, formatDateTime, formatRelativeTime } from '@/lib/utils';

type Tab = 'calls' | 'voicemail' | 'text';

function formatDuration(seconds: number): string {
  if (!seconds) return '0:00';
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}:${String(s).padStart(2, '0')}`;
}

function formatPhoneNumber(num: string): string {
  if (!num) return '';
  const cleaned = num.replace(/\D/g, '');
  if (cleaned.length === 11 && cleaned.startsWith('1')) {
    return `(${cleaned.slice(1, 4)}) ${cleaned.slice(4, 7)}-${cleaned.slice(7)}`;
  }
  if (cleaned.length === 10) {
    return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6)}`;
  }
  return num;
}

export default function PhonePage() {
  const { calls, voicemails, messages, loading, error, sendSms, markVoicemailRead } = usePhone();
  const [activeTab, setActiveTab] = useState<Tab>('calls');

  // SMS form state
  const [smsTo, setSmsTo] = useState('');
  const [smsBody, setSmsBody] = useState('');
  const [sending, setSending] = useState(false);
  const [sendError, setSendError] = useState<string | null>(null);
  const [sendSuccess, setSendSuccess] = useState(false);

  const handleSendSms = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!smsTo.trim() || !smsBody.trim()) return;
    setSending(true);
    setSendError(null);
    setSendSuccess(false);
    try {
      await sendSms(smsTo.trim(), smsBody.trim());
      setSmsTo('');
      setSmsBody('');
      setSendSuccess(true);
      setTimeout(() => setSendSuccess(false), 3000);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to send message';
      setSendError(msg);
    } finally {
      setSending(false);
    }
  };

  const tabs: { key: Tab; label: string; icon: React.ReactNode; count?: number }[] = [
    { key: 'calls', label: 'Calls', icon: <Phone size={16} />, count: calls.length },
    { key: 'voicemail', label: 'Voicemail', icon: <Voicemail size={16} />, count: voicemails.filter(v => !v.isRead).length },
    { key: 'text', label: 'Text', icon: <MessageSquare size={16} /> },
  ];

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="skeleton h-7 w-32 rounded-lg" />
        <div className="skeleton h-12 w-full rounded-lg" />
        <div className="skeleton h-48 w-full rounded-xl" />
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-main">Phone</h1>
        <p className="text-sm text-muted mt-1">
          Call log, voicemails, and text messages
        </p>
      </div>

      {error && (
        <div className="px-4 py-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-1 p-1 bg-secondary rounded-lg">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={cn(
              'flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors flex-1 justify-center',
              activeTab === tab.key
                ? 'bg-surface text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
          >
            {tab.icon}
            {tab.label}
            {tab.count !== undefined && tab.count > 0 && (
              <span className={cn(
                'text-xs px-1.5 py-0.5 rounded-full',
                activeTab === tab.key
                  ? 'bg-accent/10 text-accent'
                  : 'bg-slate-200 dark:bg-slate-700 text-muted'
              )}>
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'calls' && (
        <div className="space-y-2">
          {calls.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <Phone size={40} className="text-muted mx-auto mb-3" />
                <p className="text-sm font-medium text-main">No recent calls</p>
                <p className="text-sm text-muted mt-1">Your call history will appear here.</p>
              </CardContent>
            </Card>
          ) : (
            calls.map((call) => {
              const isInbound = call.direction === 'inbound';
              const isMissed = call.status === 'missed' || call.status === 'no_answer';
              const DirectionIcon = isMissed ? PhoneMissed : isInbound ? PhoneIncoming : PhoneOutgoing;
              const iconColor = isMissed
                ? 'text-red-500'
                : isInbound
                  ? 'text-emerald-500'
                  : 'text-blue-500';
              const contactNumber = isInbound ? call.fromNumber : call.toNumber;

              return (
                <Card key={call.id}>
                  <CardContent className="py-3.5">
                    <div className="flex items-center gap-3">
                      <div className={cn('p-2 rounded-lg bg-secondary flex-shrink-0', iconColor)}>
                        <DirectionIcon size={18} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <p className="text-sm font-medium text-main truncate">
                            {call.customerName || formatPhoneNumber(contactNumber)}
                          </p>
                          {isMissed && <Badge variant="error">Missed</Badge>}
                        </div>
                        {call.customerName && (
                          <p className="text-xs text-muted">{formatPhoneNumber(contactNumber)}</p>
                        )}
                        {call.jobTitle && (
                          <p className="text-xs text-muted truncate">{call.jobTitle}</p>
                        )}
                      </div>
                      <div className="text-right flex-shrink-0">
                        <p className="text-xs text-muted">{formatRelativeTime(call.startedAt)}</p>
                        {call.durationSeconds > 0 && (
                          <div className="flex items-center gap-1 justify-end mt-0.5">
                            <Clock size={12} className="text-muted" />
                            <span className="text-xs text-muted">{formatDuration(call.durationSeconds)}</span>
                          </div>
                        )}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              );
            })
          )}
        </div>
      )}

      {activeTab === 'voicemail' && (
        <div className="space-y-2">
          {voicemails.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <Voicemail size={40} className="text-muted mx-auto mb-3" />
                <p className="text-sm font-medium text-main">No voicemails</p>
                <p className="text-sm text-muted mt-1">Voicemails left for you will appear here.</p>
              </CardContent>
            </Card>
          ) : (
            voicemails.map((vm) => (
              <Card
                key={vm.id}
                onClick={() => { if (!vm.isRead) markVoicemailRead(vm.id); }}
                className={cn(!vm.isRead && 'border-accent/40')}
              >
                <CardContent className="py-3.5">
                  <div className="flex items-start gap-3">
                    <div className={cn(
                      'p-2 rounded-lg flex-shrink-0',
                      vm.isRead ? 'bg-secondary text-muted' : 'bg-accent/10 text-accent'
                    )}>
                      <Voicemail size={18} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-medium text-main truncate">
                          {vm.customerName || formatPhoneNumber(vm.fromNumber)}
                        </p>
                        {!vm.isRead && <Badge variant="info">New</Badge>}
                      </div>
                      {vm.transcript && (
                        <p className="text-xs text-muted mt-1 line-clamp-2">{vm.transcript}</p>
                      )}
                      <div className="flex items-center gap-3 mt-1">
                        {vm.durationSeconds !== null && (
                          <span className="text-xs text-muted flex items-center gap-1">
                            <Clock size={12} />
                            {formatDuration(vm.durationSeconds)}
                          </span>
                        )}
                        <span className="text-xs text-muted">{formatDateTime(vm.createdAt)}</span>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))
          )}
        </div>
      )}

      {activeTab === 'text' && (
        <div className="space-y-6">
          {/* Send SMS Form */}
          <Card>
            <CardContent>
              <form onSubmit={handleSendSms} className="space-y-4">
                <p className="text-sm font-semibold text-main">Send a Text</p>
                <Input
                  label="To"
                  type="tel"
                  placeholder="(555) 123-4567"
                  value={smsTo}
                  onChange={(e) => setSmsTo(e.target.value)}
                  required
                />
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-main">Message</label>
                  <textarea
                    rows={3}
                    placeholder="Type your message..."
                    value={smsBody}
                    onChange={(e) => setSmsBody(e.target.value)}
                    required
                    className={cn(
                      'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                      'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                      'text-[15px] resize-none'
                    )}
                  />
                </div>

                {sendError && (
                  <p className="text-xs text-red-500">{sendError}</p>
                )}
                {sendSuccess && (
                  <p className="text-xs text-emerald-600 dark:text-emerald-400">Message sent successfully.</p>
                )}

                <Button
                  type="submit"
                  loading={sending}
                  disabled={!smsTo.trim() || !smsBody.trim()}
                  className="w-full sm:w-auto min-h-[44px]"
                >
                  <Send size={16} />
                  Send
                </Button>
              </form>
            </CardContent>
          </Card>

          {/* Recent Sent Messages */}
          <div>
            <p className="text-sm font-semibold text-main mb-2">Recent Messages</p>
            {messages.length === 0 ? (
              <Card>
                <CardContent className="py-12 text-center">
                  <MessageSquare size={40} className="text-muted mx-auto mb-3" />
                  <p className="text-sm font-medium text-main">No messages yet</p>
                  <p className="text-sm text-muted mt-1">Messages you send will appear here.</p>
                </CardContent>
              </Card>
            ) : (
              <div className="space-y-2">
                {messages.map((msg) => (
                  <Card key={msg.id}>
                    <CardContent className="py-3">
                      <div className="flex items-start gap-3">
                        <div className="p-2 rounded-lg bg-secondary flex-shrink-0 text-blue-500">
                          <MessageSquare size={16} />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <p className="text-sm font-medium text-main truncate">
                              {msg.customerName || formatPhoneNumber(msg.toNumber)}
                            </p>
                            <Badge variant={msg.direction === 'outbound' ? 'info' : 'default'}>
                              {msg.direction === 'outbound' ? 'Sent' : 'Received'}
                            </Badge>
                          </div>
                          <p className="text-xs text-muted mt-1 line-clamp-2">{msg.body}</p>
                          <p className="text-xs text-muted mt-1">{formatRelativeTime(msg.createdAt)}</p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
