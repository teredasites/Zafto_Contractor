'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  Search,
  TicketCheck,
  ChevronRight,
  Filter,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge, StatusBadge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { getSupabase } from '@/lib/supabase';
import { formatRelativeTime } from '@/lib/utils';

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

const priorityVariant: Record<string, 'danger' | 'warning' | 'default' | 'info'> = {
  critical: 'danger',
  high: 'warning',
  medium: 'default',
  low: 'info',
};

export default function TicketQueuePage() {
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [priorityFilter, setPriorityFilter] = useState('all');

  useEffect(() => {
    const fetchTickets = async () => {
      const supabase = getSupabase();

      // Fetch count
      const { count } = await supabase
        .from('support_tickets')
        .select('id', { count: 'exact', head: true });
      setTotalCount(count ?? 0);

      // Fetch tickets
      const { data } = await supabase
        .from('support_tickets')
        .select('*')
        .order('created_at', { ascending: false });

      if (data) {
        setTickets(data as SupportTicket[]);
      }
      setLoading(false);
    };

    fetchTickets();
  }, []);

  const filtered = tickets.filter((t) => {
    const matchesSearch = t.subject.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || t.status === statusFilter;
    const matchesPriority = priorityFilter === 'all' || t.priority === priorityFilter;
    return matchesSearch && matchesStatus && matchesPriority;
  });

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">
          Ticket Queue
        </h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">
          {totalCount} total tickets
        </p>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative max-w-md flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[var(--text-secondary)]" />
          <Input
            placeholder="Search by subject..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
        <div className="flex gap-3">
          <div className="relative">
            <Filter className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[var(--text-secondary)]" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="appearance-none rounded-lg border border-[var(--border)] bg-[var(--bg-card)] pl-9 pr-8 py-2.5 text-sm text-[var(--text-primary)] focus:border-[var(--accent)] focus:outline-none focus:ring-2 focus:ring-[var(--accent)]/20 transition-colors"
            >
              <option value="all">All Statuses</option>
              <option value="new">New</option>
              <option value="in_progress">In Progress</option>
              <option value="waiting_customer">Waiting Customer</option>
              <option value="resolved">Resolved</option>
              <option value="closed">Closed</option>
            </select>
          </div>
          <select
            value={priorityFilter}
            onChange={(e) => setPriorityFilter(e.target.value)}
            className="appearance-none rounded-lg border border-[var(--border)] bg-[var(--bg-card)] px-4 pr-8 py-2.5 text-sm text-[var(--text-primary)] focus:border-[var(--accent)] focus:outline-none focus:ring-2 focus:ring-[var(--accent)]/20 transition-colors"
          >
            <option value="all">All Priorities</option>
            <option value="critical">Critical</option>
            <option value="high">High</option>
            <option value="medium">Medium</option>
            <option value="low">Low</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <Card>
        <CardContent>
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3, 4, 5].map((i) => (
                <div key={i} className="flex items-center gap-4 py-3">
                  <div className="h-4 w-16 rounded skeleton-shimmer" />
                  <div className="h-4 w-48 rounded skeleton-shimmer" />
                  <div className="h-5 w-20 rounded-full skeleton-shimmer" />
                  <div className="h-5 w-16 rounded-full skeleton-shimmer" />
                  <div className="h-5 w-20 rounded-full skeleton-shimmer" />
                  <div className="h-4 w-16 rounded skeleton-shimmer ml-auto" />
                </div>
              ))}
            </div>
          ) : filtered.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <TicketCheck className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm">No tickets found</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-[var(--border)]">
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Ticket #
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Subject
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Category
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Priority
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Status
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Created
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((ticket) => (
                    <tr
                      key={ticket.id}
                      className="border-b border-[var(--border)] last:border-0 hover:bg-[var(--bg-elevated)] transition-colors"
                    >
                      <td className="py-3 px-2">
                        <span className="text-sm font-mono text-[var(--text-secondary)]">
                          {ticket.ticket_number}
                        </span>
                      </td>
                      <td className="py-3 px-2">
                        <Link
                          href={`/dashboard/tickets/${ticket.id}`}
                          className="text-sm font-medium text-[var(--text-primary)] hover:text-[var(--accent)] transition-colors"
                        >
                          {ticket.subject}
                        </Link>
                      </td>
                      <td className="py-3 px-2">
                        <Badge>{ticket.category || '--'}</Badge>
                      </td>
                      <td className="py-3 px-2">
                        <Badge variant={priorityVariant[ticket.priority] || 'default'}>
                          {ticket.priority
                            ? ticket.priority.charAt(0).toUpperCase() + ticket.priority.slice(1)
                            : '--'}
                        </Badge>
                      </td>
                      <td className="py-3 px-2">
                        <StatusBadge status={ticket.status || 'unknown'} />
                      </td>
                      <td className="py-3 px-2">
                        <span className="text-sm text-[var(--text-secondary)]">
                          {formatRelativeTime(ticket.created_at)}
                        </span>
                      </td>
                      <td className="py-3 px-2 text-right">
                        <Link
                          href={`/dashboard/tickets/${ticket.id}`}
                          className="inline-flex items-center gap-1 text-sm text-[var(--accent)] hover:underline"
                        >
                          View
                          <ChevronRight className="h-3.5 w-3.5" />
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
