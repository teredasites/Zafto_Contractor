'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  Send,
  Clock,
  User,
  Bot,
  ShieldCheck,
  Inbox,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge, StatusBadge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { getSupabase } from '@/lib/supabase';
import { formatDate, formatRelativeTime } from '@/lib/utils';

interface SupportTicket {
  id: string;
  company_id: string;
  user_id: string;
  ticket_number: string;
  subject: string;
  description: string;
  category: string;
  priority: string;
  status: string;
  source: string;
  created_at: string;
  updated_at: string;
  resolved_at: string | null;
  resolution_notes: string | null;
  satisfaction_rating: number | null;
}

interface SupportMessage {
  id: string;
  ticket_id: string;
  sender_type: 'customer' | 'admin' | 'ai_auto';
  sender_id: string | null;
  message: string;
  attachments: unknown[] | null;
  created_at: string;
}

const priorityVariant: Record<string, 'danger' | 'warning' | 'default' | 'info'> = {
  critical: 'danger',
  high: 'warning',
  medium: 'default',
  low: 'info',
};

const senderIcon: Record<string, React.ReactNode> = {
  customer: <User className="h-4 w-4" />,
  admin: <ShieldCheck className="h-4 w-4" />,
  ai_auto: <Bot className="h-4 w-4" />,
};

const senderVariant: Record<string, 'default' | 'info' | 'success'> = {
  customer: 'default',
  admin: 'info',
  ai_auto: 'success',
};

export default function TicketDetailPage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;

  const [ticket, setTicket] = useState<SupportTicket | null>(null);
  const [messages, setMessages] = useState<SupportMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [replyText, setReplyText] = useState('');
  const [sending, setSending] = useState(false);
  const [statusUpdating, setStatusUpdating] = useState(false);

  useEffect(() => {
    const fetchTicket = async () => {
      const supabase = getSupabase();

      const { data: ticketData } = await supabase
        .from('support_tickets')
        .select('*')
        .eq('id', id)
        .single();

      if (ticketData) {
        setTicket(ticketData as SupportTicket);
      }

      const { data: messagesData } = await supabase
        .from('support_messages')
        .select('*')
        .eq('ticket_id', id)
        .order('created_at', { ascending: true });

      if (messagesData) {
        setMessages(messagesData as SupportMessage[]);
      }

      setLoading(false);
    };

    fetchTicket();
  }, [id]);

  const handleSendReply = async () => {
    if (!replyText.trim() || sending) return;

    setSending(true);
    const supabase = getSupabase();

    const { data, error } = await supabase
      .from('support_messages')
      .insert({
        ticket_id: id,
        sender_type: 'admin',
        message: replyText.trim(),
      })
      .select()
      .single();

    if (!error && data) {
      setMessages((prev) => [...prev, data as SupportMessage]);
      setReplyText('');
    }
    setSending(false);
  };

  const handleStatusChange = async (newStatus: string) => {
    if (!ticket || statusUpdating) return;

    setStatusUpdating(true);
    const supabase = getSupabase();

    const updateData: Record<string, unknown> = { status: newStatus };
    if (newStatus === 'resolved') {
      updateData.resolved_at = new Date().toISOString();
    }

    const { error } = await supabase
      .from('support_tickets')
      .update(updateData)
      .eq('id', id);

    if (!error) {
      setTicket((prev) => prev ? { ...prev, status: newStatus, ...(newStatus === 'resolved' ? { resolved_at: new Date().toISOString() } : {}) } : prev);
    }
    setStatusUpdating(false);
  };

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="flex items-center gap-3">
          <div className="h-8 w-8 rounded skeleton-shimmer" />
          <div className="h-6 w-48 rounded skeleton-shimmer" />
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-4">
            <div className="h-32 rounded-xl skeleton-shimmer" />
            <div className="h-64 rounded-xl skeleton-shimmer" />
          </div>
          <div className="space-y-4">
            <div className="h-48 rounded-xl skeleton-shimmer" />
          </div>
        </div>
      </div>
    );
  }

  if (!ticket) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="flex flex-col items-center justify-center py-20 text-[var(--text-secondary)]">
          <Inbox className="h-8 w-8 mb-2 opacity-40" />
          <p className="text-sm">Ticket not found</p>
          <Link
            href="/dashboard/tickets"
            className="text-sm text-[var(--accent)] hover:underline mt-2"
          >
            Back to tickets
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link
          href="/dashboard/tickets"
          className="p-2 rounded-lg hover:bg-[var(--bg-elevated)] transition-colors text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
        >
          <ArrowLeft className="h-5 w-5" />
        </Link>
        <div className="flex-1">
          <div className="flex items-center gap-3 flex-wrap">
            <h1 className="text-2xl font-bold text-[var(--text-primary)]">
              {ticket.ticket_number}
            </h1>
            <StatusBadge status={ticket.status} />
            <Badge variant={priorityVariant[ticket.priority] || 'default'}>
              {ticket.priority
                ? ticket.priority.charAt(0).toUpperCase() + ticket.priority.slice(1)
                : '--'}
            </Badge>
          </div>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            {ticket.subject}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Description */}
          <Card>
            <CardHeader>
              <CardTitle>Description</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-[var(--text-primary)] whitespace-pre-wrap">
                {ticket.description || 'No description provided.'}
              </p>
            </CardContent>
          </Card>

          {/* Message Thread */}
          <Card>
            <CardHeader>
              <CardTitle>Messages ({messages.length})</CardTitle>
            </CardHeader>
            <CardContent>
              {messages.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-8 text-[var(--text-secondary)]">
                  <Inbox className="h-8 w-8 mb-2 opacity-40" />
                  <p className="text-sm">No messages yet</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {messages.map((msg) => (
                    <div
                      key={msg.id}
                      className="rounded-lg border border-[var(--border)] bg-[var(--bg-elevated)] p-4"
                    >
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center gap-2">
                          <div className="p-1.5 rounded-md bg-[var(--bg-card)] text-[var(--text-secondary)]">
                            {senderIcon[msg.sender_type] || <User className="h-4 w-4" />}
                          </div>
                          <Badge variant={senderVariant[msg.sender_type] || 'default'}>
                            {msg.sender_type === 'ai_auto' ? 'AI Auto' : msg.sender_type.charAt(0).toUpperCase() + msg.sender_type.slice(1)}
                          </Badge>
                        </div>
                        <span className="text-xs text-[var(--text-secondary)]">
                          {formatRelativeTime(msg.created_at)}
                        </span>
                      </div>
                      <p className="text-sm text-[var(--text-primary)] whitespace-pre-wrap">
                        {msg.message}
                      </p>
                    </div>
                  ))}
                </div>
              )}

              {/* Reply Form */}
              <div className="mt-6 pt-4 border-t border-[var(--border)]">
                <textarea
                  value={replyText}
                  onChange={(e) => setReplyText(e.target.value)}
                  placeholder="Type your reply..."
                  rows={4}
                  className="w-full rounded-lg border border-[var(--border)] bg-[var(--bg-card)] px-3 py-2.5 text-sm text-[var(--text-primary)] placeholder:text-[var(--text-secondary)] focus:border-[var(--accent)] focus:outline-none focus:ring-2 focus:ring-[var(--accent)]/20 transition-colors resize-none"
                />
                <div className="flex justify-end mt-3">
                  <Button
                    onClick={handleSendReply}
                    loading={sending}
                    disabled={!replyText.trim()}
                  >
                    <Send className="h-4 w-4" />
                    Send Reply
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Ticket Info */}
          <Card>
            <CardHeader>
              <CardTitle>Ticket Details</CardTitle>
            </CardHeader>
            <CardContent>
              <dl className="space-y-3">
                <div>
                  <dt className="text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                    Category
                  </dt>
                  <dd className="mt-1">
                    <Badge>{ticket.category || '--'}</Badge>
                  </dd>
                </div>
                <div>
                  <dt className="text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                    Source
                  </dt>
                  <dd className="text-sm text-[var(--text-primary)] mt-1">
                    {ticket.source || '--'}
                  </dd>
                </div>
                <div>
                  <dt className="text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                    Company ID
                  </dt>
                  <dd className="text-sm text-[var(--text-primary)] mt-1 font-mono text-xs">
                    {ticket.company_id || '--'}
                  </dd>
                </div>
                <div>
                  <dt className="text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                    User ID
                  </dt>
                  <dd className="text-sm text-[var(--text-primary)] mt-1 font-mono text-xs">
                    {ticket.user_id || '--'}
                  </dd>
                </div>
                <div>
                  <dt className="text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                    Created
                  </dt>
                  <dd className="text-sm text-[var(--text-primary)] mt-1 flex items-center gap-1.5">
                    <Clock className="h-3.5 w-3.5 text-[var(--text-secondary)]" />
                    {formatDate(ticket.created_at)}
                  </dd>
                </div>
                <div>
                  <dt className="text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                    Updated
                  </dt>
                  <dd className="text-sm text-[var(--text-primary)] mt-1">
                    {formatRelativeTime(ticket.updated_at)}
                  </dd>
                </div>
                {ticket.resolved_at && (
                  <div>
                    <dt className="text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Resolved
                    </dt>
                    <dd className="text-sm text-[var(--text-primary)] mt-1">
                      {formatDate(ticket.resolved_at)}
                    </dd>
                  </div>
                )}
                {ticket.satisfaction_rating !== null && (
                  <div>
                    <dt className="text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Satisfaction
                    </dt>
                    <dd className="text-sm text-[var(--text-primary)] mt-1">
                      {ticket.satisfaction_rating} / 5
                    </dd>
                  </div>
                )}
              </dl>
            </CardContent>
          </Card>

          {/* Status Update */}
          <Card>
            <CardHeader>
              <CardTitle>Update Status</CardTitle>
            </CardHeader>
            <CardContent>
              <select
                value={ticket.status}
                onChange={(e) => handleStatusChange(e.target.value)}
                disabled={statusUpdating}
                className="w-full appearance-none rounded-lg border border-[var(--border)] bg-[var(--bg-card)] px-3 py-2.5 text-sm text-[var(--text-primary)] focus:border-[var(--accent)] focus:outline-none focus:ring-2 focus:ring-[var(--accent)]/20 transition-colors disabled:opacity-50"
              >
                <option value="new">New</option>
                <option value="in_progress">In Progress</option>
                <option value="waiting_customer">Waiting Customer</option>
                <option value="resolved">Resolved</option>
                <option value="closed">Closed</option>
              </select>
              {statusUpdating && (
                <p className="text-xs text-[var(--text-secondary)] mt-2">
                  Updating...
                </p>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
