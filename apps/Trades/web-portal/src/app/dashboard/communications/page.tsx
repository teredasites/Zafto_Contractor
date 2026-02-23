'use client';

import { useState, useEffect, useCallback } from 'react';
import {
  Search,
  Mail,
  MessageSquare,
  Phone,
  Send,
  Inbox,
  ArrowUpRight,
  Clock,
  CheckCheck,
  User,
  Filter,
  Plus,
  X,
  Paperclip,
  MoreHorizontal,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, formatRelativeTime, cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import { useTranslation } from '@/lib/translations';

type MessageType = 'email' | 'sms' | 'call';
type MessageDirection = 'inbound' | 'outbound';

interface Communication {
  id: string;
  type: MessageType;
  direction: MessageDirection;
  customerId: string;
  customerName: string;
  customerEmail?: string;
  customerPhone?: string;
  subject?: string;
  body: string;
  jobId?: string;
  jobName?: string;
  status: 'sent' | 'delivered' | 'read' | 'failed' | 'received';
  timestamp: Date;
  duration?: number; // for calls, in seconds
  attachments?: string[];
}

export default function CommunicationsPage() {
  const { t } = useTranslation();
  const [comms, setComms] = useState<Communication[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [directionFilter, setDirectionFilter] = useState('all');
  const [selectedComm, setSelectedComm] = useState<Communication | null>(null);
  const [showComposeModal, setShowComposeModal] = useState(false);

  const fetchComms = useCallback(async () => {
    const supabase = getSupabase();
    const results: Communication[] = [];

    // Fetch emails
    const { data: emails } = await supabase
      .from('email_sends')
      .select('id, to_email, to_name, from_email, subject, body_preview, status, email_type, related_type, related_id, created_at')
      .order('created_at', { ascending: false })
      .limit(100);

    for (const e of emails || []) {
      results.push({
        id: `email-${e.id}`,
        type: 'email',
        direction: 'outbound',
        customerId: '',
        customerName: (e.to_name as string) || (e.to_email as string) || '',
        customerEmail: e.to_email as string,
        subject: e.subject as string,
        body: (e.body_preview as string) || '',
        status: (e.status as Communication['status']) || 'sent',
        timestamp: new Date(e.created_at as string),
      });
    }

    // Fetch SMS messages
    const { data: smsMessages } = await supabase
      .from('phone_messages')
      .select('id, direction, phone_number, contact_name, body, status, created_at')
      .order('created_at', { ascending: false })
      .limit(100);

    for (const m of smsMessages || []) {
      results.push({
        id: `sms-${m.id}`,
        type: 'sms',
        direction: (m.direction as string) === 'inbound' ? 'inbound' : 'outbound',
        customerId: '',
        customerName: (m.contact_name as string) || (m.phone_number as string) || '',
        customerPhone: m.phone_number as string,
        body: (m.body as string) || '',
        status: (m.status as Communication['status']) || 'sent',
        timestamp: new Date(m.created_at as string),
      });
    }

    // Fetch phone calls
    const { data: calls } = await supabase
      .from('phone_calls')
      .select('id, direction, phone_number, contact_name, status, duration_seconds, created_at')
      .order('created_at', { ascending: false })
      .limit(100);

    for (const c of calls || []) {
      results.push({
        id: `call-${c.id}`,
        type: 'call',
        direction: (c.direction as string) === 'inbound' ? 'inbound' : 'outbound',
        customerId: '',
        customerName: (c.contact_name as string) || (c.phone_number as string) || '',
        customerPhone: c.phone_number as string,
        body: `Call ${(c.direction as string) === 'inbound' ? 'from' : 'to'} ${(c.contact_name as string) || (c.phone_number as string)}`,
        status: (c.status as Communication['status']) || 'sent',
        duration: c.duration_seconds as number | undefined,
        timestamp: new Date(c.created_at as string),
      });
    }

    // Sort by timestamp descending
    results.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
    setComms(results);
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchComms();

    const supabase = getSupabase();
    const channel = supabase.channel('comms-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'email_sends' }, () => fetchComms())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_messages' }, () => fetchComms())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_calls' }, () => fetchComms())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchComms]);

  const filteredComms = comms.filter((comm) => {
    const matchesSearch =
      comm.customerName.toLowerCase().includes(search.toLowerCase()) ||
      comm.body.toLowerCase().includes(search.toLowerCase()) ||
      comm.subject?.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || comm.type === typeFilter;
    const matchesDirection = directionFilter === 'all' || comm.direction === directionFilter;
    return matchesSearch && matchesType && matchesDirection;
  });

  const typeOptions = [
    { value: 'all', label: 'All Types' },
    { value: 'email', label: 'Email' },
    { value: 'sms', label: 'SMS' },
    { value: 'call', label: 'Calls' },
  ];

  const directionOptions = [
    { value: 'all', label: 'All' },
    { value: 'inbound', label: 'Inbound' },
    { value: 'outbound', label: 'Outbound' },
  ];

  // Stats
  const todayCount = comms.filter((c) => {
    const today = new Date();
    return c.timestamp.toDateString() === today.toDateString();
  }).length;
  const unreadCount = comms.filter((c) => c.direction === 'inbound' && c.status === 'received').length;
  const sentCount = comms.filter((c) => c.direction === 'outbound').length;

  const getTypeIcon = (type: MessageType) => {
    switch (type) {
      case 'email': return <Mail size={16} />;
      case 'sms': return <MessageSquare size={16} />;
      case 'call': return <Phone size={16} />;
    }
  };

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('communications.title')}</h1>
          <p className="text-muted mt-1">Email, SMS, and call history with customers</p>
        </div>
        <Button onClick={() => setShowComposeModal(true)}>
          <Plus size={16} />
          New Message
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <MessageSquare size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{todayCount}</p>
                <p className="text-sm text-muted">{t('common.today')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Inbox size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{unreadCount}</p>
                <p className="text-sm text-muted">{t('communications.needResponse')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Send size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{sentCount}</p>
                <p className="text-sm text-muted">{t('common.sent')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Mail size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{comms.length}</p>
                <p className="text-sm text-muted">{t('common.total')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search messages..."
          className="sm:w-80"
        />
        <Select
          options={typeOptions}
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="sm:w-40"
        />
        <Select
          options={directionOptions}
          value={directionFilter}
          onChange={(e) => setDirectionFilter(e.target.value)}
          className="sm:w-40"
        />
      </div>

      {/* Communications List */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* List */}
        <Card className="lg:max-h-[600px] overflow-hidden">
          <CardContent className="p-0">
            <div className="divide-y divide-main overflow-y-auto max-h-[550px]">
              {filteredComms.map((comm) => (
                <div
                  key={comm.id}
                  onClick={() => setSelectedComm(comm)}
                  className={cn(
                    'px-4 py-3 cursor-pointer hover:bg-surface-hover transition-colors',
                    selectedComm?.id === comm.id && 'bg-accent-light',
                    comm.direction === 'inbound' && comm.status === 'received' && 'border-l-2 border-l-accent'
                  )}
                >
                  <div className="flex items-start gap-3">
                    <div className={cn(
                      'p-2 rounded-full',
                      comm.type === 'email' ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-600' :
                      comm.type === 'sms' ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600' :
                      'bg-purple-100 dark:bg-purple-900/30 text-purple-600'
                    )}>
                      {getTypeIcon(comm.type)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-medium text-main">{comm.customerName}</span>
                        {comm.direction === 'outbound' && (
                          <ArrowUpRight size={12} className="text-muted" />
                        )}
                        {comm.status === 'read' && (
                          <CheckCheck size={12} className="text-blue-500" />
                        )}
                      </div>
                      {comm.subject && (
                        <p className="text-sm font-medium text-main truncate">{comm.subject}</p>
                      )}
                      <p className="text-sm text-muted truncate">{comm.body}</p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-xs text-muted">{formatRelativeTime(comm.timestamp)}</span>
                        {comm.duration && (
                          <span className="text-xs text-muted">({formatDuration(comm.duration)})</span>
                        )}
                        {comm.attachments && comm.attachments.length > 0 && (
                          <Paperclip size={12} className="text-muted" />
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Detail */}
        <Card className="lg:max-h-[600px]">
          <CardContent className="p-0 h-full">
            {selectedComm ? (
              <div className="flex flex-col h-full">
                {/* Header */}
                <div className="px-4 py-3 border-b border-main">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <Avatar name={selectedComm.customerName} size="md" />
                      <div>
                        <h3 className="font-medium text-main">{selectedComm.customerName}</h3>
                        <p className="text-sm text-muted">
                          {selectedComm.customerEmail || selectedComm.customerPhone}
                        </p>
                      </div>
                    </div>
                    <Button variant="ghost" size="sm">
                      <MoreHorizontal size={16} />
                    </Button>
                  </div>
                </div>

                {/* Content */}
                <div className="flex-1 p-4 overflow-y-auto">
                  {selectedComm.subject && (
                    <h2 className="text-lg font-semibold text-main mb-2">{selectedComm.subject}</h2>
                  )}
                  <div className="flex items-center gap-2 mb-4 text-sm text-muted">
                    <Badge variant={selectedComm.direction === 'inbound' ? 'info' : 'success'} size="sm">
                      {selectedComm.direction === 'inbound' ? 'Received' : 'Sent'}
                    </Badge>
                    <span>{formatDate(selectedComm.timestamp)}</span>
                    {selectedComm.jobName && (
                      <>
                        <span>•</span>
                        <span>{selectedComm.jobName}</span>
                      </>
                    )}
                  </div>
                  <p className="text-main whitespace-pre-wrap">{selectedComm.body}</p>

                  {selectedComm.attachments && selectedComm.attachments.length > 0 && (
                    <div className="mt-4 pt-4 border-t border-main">
                      <p className="text-sm text-muted mb-2">{t('permits.attachments')}</p>
                      <div className="space-y-2">
                        {selectedComm.attachments.map((att, i) => (
                          <div key={i} className="flex items-center gap-2 p-2 bg-secondary rounded-lg">
                            <Paperclip size={14} className="text-muted" />
                            <span className="text-sm text-main">{att}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                {/* Reply */}
                <div className="px-4 py-3 border-t border-main">
                  <div className="flex gap-2">
                    <Button className="flex-1">
                      <Send size={14} />
                      Reply
                    </Button>
                    <Button variant="secondary">
                      <Phone size={14} />
                      Call
                    </Button>
                  </div>
                </div>
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center h-full text-muted">
                <Mail size={48} className="mb-2 opacity-50" />
                <p>{t('communications.selectAMessageToView')}</p>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Compose Modal */}
      {showComposeModal && (
        <ComposeModal onClose={() => setShowComposeModal(false)} />
      )}
    </div>
  );
}

function ComposeModal({ onClose }: { onClose: () => void }) {
  const { t } = useTranslation();
  const [type, setType] = useState<'email' | 'sms'>('email');

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>{t('phone.newMessage')}</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Type Toggle */}
          <div className="flex gap-2">
            <button
              onClick={() => setType('email')}
              className={cn(
                'flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                type === 'email' ? 'bg-accent text-white' : 'bg-secondary text-muted hover:text-main'
              )}
            >
              <Mail size={16} />
              Email
            </button>
            <button
              onClick={() => setType('sms')}
              className={cn(
                'flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                type === 'sms' ? 'bg-accent text-white' : 'bg-secondary text-muted hover:text-main'
              )}
            >
              <MessageSquare size={16} />
              SMS
            </button>
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.to')}</label>
            <input
              type="text"
              placeholder={t('customers.searchCustomers')}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>

          {type === 'email' && (
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.subject')}</label>
              <input
                type="text"
                placeholder="Enter subject..."
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.message')}</label>
            <textarea
              rows={type === 'sms' ? 3 : 6}
              placeholder={type === 'sms' ? 'Enter message (160 chars)...' : 'Enter your message...'}
              maxLength={type === 'sms' ? 160 : undefined}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent resize-none"
            />
          </div>

          {type === 'email' && (
            <button className="flex items-center gap-2 text-sm text-muted hover:text-main">
              <Paperclip size={14} />
              Attach file
            </button>
          )}

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1">
              <Send size={16} />
              Send
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
