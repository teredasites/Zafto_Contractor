'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import {
  ArrowLeft,
  User,
  Mail,
  Phone,
  MapPin,
  DollarSign,
  Briefcase,
  FileText,
  Receipt,
  Edit,
  MoreHorizontal,
  Trash2,
  Plus,
  Tag,
  Calendar,
  Star,
  Clock,
  TrendingUp,
  AlertTriangle,
  MessageSquare,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge, Badge } from '@/components/ui/badge';
import { Avatar } from '@/components/ui/avatar';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useCustomer } from '@/lib/hooks/use-customers';
import { useBids } from '@/lib/hooks/use-bids';
import { useJobs } from '@/lib/hooks/use-jobs';
import { useInvoices } from '@/lib/hooks/use-invoices';
import { getSupabase } from '@/lib/supabase';
import type { Customer } from '@/types';

type TabType = 'overview' | 'bids' | 'jobs' | 'invoices' | 'activity';

/** Compute payment behavior stats from customer's invoices */
function computePaymentBehavior(invoices: { sentAt?: Date | string; paidAt?: Date | string; dueDate?: Date | string; total: number; status: string }[]) {
  const paid = invoices.filter((i) => i.paidAt && i.sentAt);
  if (paid.length === 0) return { avgDaysToPay: 0, onTimeRate: 0, totalLifetimeSpend: 0, paidCount: 0, label: 'New' };

  let totalDays = 0;
  let onTimeCount = 0;
  let totalSpend = 0;

  for (const inv of paid) {
    const sent = new Date(inv.sentAt as string | Date);
    const paidDate = new Date(inv.paidAt as string | Date);
    const days = Math.max(0, Math.round((paidDate.getTime() - sent.getTime()) / 86400000));
    totalDays += days;
    totalSpend += inv.total;
    if (inv.dueDate && paidDate <= new Date(inv.dueDate as string | Date)) onTimeCount++;
  }

  const avgDays = Math.round(totalDays / paid.length);
  const onTimeRate = Math.round((onTimeCount / paid.length) * 100);

  let label = 'Regular';
  if (paid.length < 2) label = 'New';
  else if (avgDays > 30) label = 'Slow Payer';
  else if (onTimeRate >= 90) label = 'Reliable';

  return { avgDaysToPay: avgDays, onTimeRate, totalLifetimeSpend: totalSpend, paidCount: paid.length, label };
}

export default function CustomerDetailPage() {
  const router = useRouter();
  const params = useParams();
  const customerId = params.id as string;

  const { customer, loading } = useCustomer(customerId);
  const { bids } = useBids();
  const { jobs } = useJobs();
  const { invoices } = useInvoices();
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [menuOpen, setMenuOpen] = useState(false);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (!customer) {
    return (
      <div className="text-center py-12">
        <User size={48} className="mx-auto text-muted mb-4" />
        <h2 className="text-xl font-semibold text-main">Customer not found</h2>
        <p className="text-muted mt-2">The customer you're looking for doesn't exist.</p>
        <Button variant="secondary" className="mt-4" onClick={() => router.push('/dashboard/customers')}>
          Back to Customers
        </Button>
      </div>
    );
  }

  const customerBids = bids.filter((b) => b.customerId === customerId);
  const customerJobs = jobs.filter((j) => j.customerId === customerId);
  const customerInvoices = invoices.filter((i) => i.customerId === customerId);

  const tabs: { id: TabType; label: string; count: number }[] = [
    { id: 'overview', label: 'Overview', count: 0 },
    { id: 'bids', label: 'Bids', count: customerBids.length },
    { id: 'jobs', label: 'Jobs', count: customerJobs.length },
    { id: 'invoices', label: 'Invoices', count: customerInvoices.length },
    { id: 'activity', label: 'Activity', count: 0 },
  ];

  const paymentStats = computePaymentBehavior(customerInvoices);

  return (
    <div className="space-y-6 pb-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
          >
            <ArrowLeft size={20} className="text-muted" />
          </button>
          <Avatar name={`${customer.firstName} ${customer.lastName}`} size="xl" />
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-semibold text-main">
                {customer.firstName} {customer.lastName}
              </h1>
              {customer.tags.includes('vip') && (
                <Badge variant="warning">
                  <Star size={12} className="mr-1" />
                  VIP
                </Badge>
              )}
            </div>
            <p className="text-muted mt-1">{customer.email}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button onClick={() => router.push(`/dashboard/bids/new?customerId=${customer.id}`)}>
            <Plus size={16} />
            New Bid
          </Button>
          <div className="relative">
            <Button variant="ghost" size="icon" onClick={() => setMenuOpen(!menuOpen)}>
              <MoreHorizontal size={18} />
            </Button>
            {menuOpen && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setMenuOpen(false)} />
                <div className="absolute right-0 top-full mt-1 w-48 bg-surface border border-main rounded-lg shadow-lg py-1 z-50">
                  <button className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Edit size={16} />
                    Edit Customer
                  </button>
                  <button className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Briefcase size={16} />
                    Create Job
                  </button>
                  <button className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Receipt size={16} />
                    Create Invoice
                  </button>
                  <hr className="my-1 border-main" />
                  <button className="w-full px-4 py-2 text-left text-sm hover:bg-red-50 dark:hover:bg-red-900/20 text-red-600 flex items-center gap-2">
                    <Trash2 size={16} />
                    Delete
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 p-1 bg-secondary rounded-lg w-fit">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              'flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors',
              activeTab === tab.id
                ? 'bg-surface text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
          >
            {tab.label}
            {tab.count > 0 && (
              <span className={cn(
                'px-1.5 py-0.5 text-xs rounded-full',
                activeTab === tab.id ? 'bg-accent text-white' : 'bg-main text-muted'
              )}>
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {activeTab === 'overview' && (
            <OverviewTab customer={customer} bids={customerBids} jobs={customerJobs} invoices={customerInvoices} />
          )}
          {activeTab === 'bids' && <BidsTab bids={customerBids} />}
          {activeTab === 'jobs' && <JobsTab jobs={customerJobs} />}
          {activeTab === 'invoices' && <InvoicesTab invoices={customerInvoices} />}
          {activeTab === 'activity' && <ActivityTimeline customerId={customerId} bids={customerBids} jobs={customerJobs} invoices={customerInvoices} />}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Stats */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Customer Value</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm text-muted mb-1">Lifetime Revenue</p>
                <p className="text-2xl font-semibold text-main">{formatCurrency(customer.totalRevenue)}</p>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">Total Jobs</span>
                <span className="font-medium text-main">{customer.jobCount}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">Avg. Job Value</span>
                <span className="font-medium text-main">
                  {customer.jobCount > 0 ? formatCurrency(customer.totalRevenue / customer.jobCount) : '$0'}
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">Customer Since</span>
                <span className="font-medium text-main">{formatDate(customer.createdAt)}</span>
              </div>
            </CardContent>
          </Card>

          {/* Payment Behavior */}
          {paymentStats.paidCount > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2">
                  <TrendingUp size={16} className="text-muted" />
                  Payment Behavior
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted">Status</span>
                  <Badge variant={paymentStats.label === 'Slow Payer' ? 'warning' : paymentStats.label === 'Reliable' ? 'success' : 'default'}>
                    {paymentStats.label === 'Slow Payer' && <AlertTriangle size={10} className="mr-1" />}
                    {paymentStats.label}
                  </Badge>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Avg. Days to Pay</span>
                  <span className={cn('font-medium', paymentStats.avgDaysToPay > 30 ? 'text-amber-500' : 'text-main')}>
                    {paymentStats.avgDaysToPay} days
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">On-Time Rate</span>
                  <span className={cn('font-medium', paymentStats.onTimeRate >= 80 ? 'text-emerald-500' : 'text-amber-500')}>
                    {paymentStats.onTimeRate}%
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Total Paid</span>
                  <span className="font-medium text-main">{formatCurrency(paymentStats.totalLifetimeSpend)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Invoices Paid</span>
                  <span className="font-medium text-main">{paymentStats.paidCount}</span>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Contact Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Contact Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-center gap-3 text-sm">
                <Mail size={16} className="text-muted" />
                <a href={`mailto:${customer.email}`} className="text-main hover:text-accent">
                  {customer.email}
                </a>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <Phone size={16} className="text-muted" />
                <a href={`tel:${customer.phone}`} className="text-main hover:text-accent">
                  {customer.phone}
                </a>
              </div>
              <div className="flex items-start gap-3 text-sm">
                <MapPin size={16} className="text-muted mt-0.5" />
                <span className="text-main">
                  {customer.address.street}<br />
                  {customer.address.city}, {customer.address.state} {customer.address.zip}
                </span>
              </div>
            </CardContent>
          </Card>

          {/* Tags */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="text-base">Tags</CardTitle>
              <Button variant="ghost" size="sm">
                <Plus size={14} />
                Add
              </Button>
            </CardHeader>
            <CardContent>
              <div className="flex flex-wrap gap-2">
                {customer.tags.map((tag) => (
                  <Badge key={tag} variant="default">{tag}</Badge>
                ))}
                {customer.tags.length === 0 && (
                  <p className="text-sm text-muted">No tags</p>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Notes */}
          {customer.notes && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Notes</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-main">{customer.notes}</p>
              </CardContent>
            </Card>
          )}

          {/* Source */}
          {customer.source && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Lead Source</CardTitle>
              </CardHeader>
              <CardContent>
                <Badge variant="default" className="capitalize">{customer.source}</Badge>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}

function OverviewTab({ customer, bids, jobs, invoices }: { customer: Customer; bids: any[]; jobs: any[]; invoices: any[] }) {
  const router = useRouter();
  const recentActivity = [
    ...bids.map((b) => ({ type: 'bid', title: b.title, status: b.status, date: b.updatedAt, id: b.id })),
    ...jobs.map((j) => ({ type: 'job', title: j.title, status: j.status, date: j.updatedAt, id: j.id })),
    ...invoices.map((i) => ({ type: 'invoice', title: i.invoiceNumber, status: i.status, date: i.updatedAt, id: i.id })),
  ].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()).slice(0, 5);

  return (
    <div className="space-y-6">
      {/* Quick Stats */}
      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4 text-center">
            <FileText size={24} className="mx-auto text-blue-500 mb-2" />
            <p className="text-2xl font-semibold text-main">{bids.length}</p>
            <p className="text-sm text-muted">Bids</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <Briefcase size={24} className="mx-auto text-indigo-500 mb-2" />
            <p className="text-2xl font-semibold text-main">{jobs.length}</p>
            <p className="text-sm text-muted">Jobs</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <Receipt size={24} className="mx-auto text-emerald-500 mb-2" />
            <p className="text-2xl font-semibold text-main">{invoices.length}</p>
            <p className="text-sm text-muted">Invoices</p>
          </CardContent>
        </Card>
      </div>

      {/* Recent Activity */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Recent Activity</CardTitle>
        </CardHeader>
        <CardContent>
          {recentActivity.length === 0 ? (
            <p className="text-center text-muted py-4">No activity yet</p>
          ) : (
            <div className="space-y-3">
              {recentActivity.map((item, index) => (
                <div
                  key={`${item.type}-${item.id}`}
                  onClick={() => router.push(`/dashboard/${item.type}s/${item.id}`)}
                  className="flex items-center justify-between p-3 bg-secondary rounded-lg hover:bg-surface-hover cursor-pointer transition-colors"
                >
                  <div className="flex items-center gap-3">
                    {item.type === 'bid' && <FileText size={16} className="text-blue-500" />}
                    {item.type === 'job' && <Briefcase size={16} className="text-indigo-500" />}
                    {item.type === 'invoice' && <Receipt size={16} className="text-emerald-500" />}
                    <div>
                      <p className="font-medium text-main text-sm">{item.title}</p>
                      <p className="text-xs text-muted capitalize">{item.type}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <StatusBadge status={item.status} />
                    <span className="text-xs text-muted">{formatDate(item.date)}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function BidsTab({ bids }: { bids: any[] }) {
  const router = useRouter();

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">Bids</CardTitle>
        <Button variant="secondary" size="sm">
          <Plus size={14} />
          New Bid
        </Button>
      </CardHeader>
      <CardContent className="p-0">
        {bids.length === 0 ? (
          <div className="py-12 text-center">
            <FileText size={40} className="mx-auto text-muted mb-2 opacity-50" />
            <p className="text-muted">No bids yet</p>
          </div>
        ) : (
          <div className="divide-y divide-main">
            {bids.map((bid) => (
              <div
                key={bid.id}
                onClick={() => router.push(`/dashboard/bids/${bid.id}`)}
                className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium text-main">{bid.title}</p>
                    <p className="text-sm text-muted">{formatDate(bid.createdAt)}</p>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="font-semibold text-main">{formatCurrency(bid.total)}</span>
                    <StatusBadge status={bid.status} />
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function JobsTab({ jobs }: { jobs: any[] }) {
  const router = useRouter();

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">Jobs</CardTitle>
        <Button variant="secondary" size="sm">
          <Plus size={14} />
          New Job
        </Button>
      </CardHeader>
      <CardContent className="p-0">
        {jobs.length === 0 ? (
          <div className="py-12 text-center">
            <Briefcase size={40} className="mx-auto text-muted mb-2 opacity-50" />
            <p className="text-muted">No jobs yet</p>
          </div>
        ) : (
          <div className="divide-y divide-main">
            {jobs.map((job) => (
              <div
                key={job.id}
                onClick={() => router.push(`/dashboard/jobs/${job.id}`)}
                className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium text-main">{job.title}</p>
                    <p className="text-sm text-muted">{formatDate(job.scheduledStart || job.createdAt)}</p>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="font-semibold text-main">{formatCurrency(job.estimatedValue)}</span>
                    <StatusBadge status={job.status} />
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function InvoicesTab({ invoices }: { invoices: any[] }) {
  const router = useRouter();

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">Invoices</CardTitle>
        <Button variant="secondary" size="sm">
          <Plus size={14} />
          New Invoice
        </Button>
      </CardHeader>
      <CardContent className="p-0">
        {invoices.length === 0 ? (
          <div className="py-12 text-center">
            <Receipt size={40} className="mx-auto text-muted mb-2 opacity-50" />
            <p className="text-muted">No invoices yet</p>
          </div>
        ) : (
          <div className="divide-y divide-main">
            {invoices.map((invoice) => (
              <div
                key={invoice.id}
                onClick={() => router.push(`/dashboard/invoices/${invoice.id}`)}
                className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium text-main">{invoice.invoiceNumber}</p>
                    <p className="text-sm text-muted">Due {formatDate(invoice.dueDate)}</p>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="font-semibold text-main">{formatCurrency(invoice.total)}</span>
                    <StatusBadge status={invoice.status} />
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

/** Unified communication timeline for a customer */
function ActivityTimeline({ customerId, bids, jobs, invoices }: {
  customerId: string;
  bids: any[];
  jobs: any[];
  invoices: any[];
}) {
  const router = useRouter();
  const [commsLoading, setCommsLoading] = useState(true);
  const [comms, setComms] = useState<{ type: string; title: string; date: string; detail?: string; icon: string }[]>([]);

  useEffect(() => {
    let cancelled = false;
    async function loadComms() {
      try {
        const supabase = getSupabase();
        // Fetch phone calls, messages, emails for this customer
        const [callsRes, messagesRes, emailsRes] = await Promise.all([
          supabase.from('phone_calls').select('id, direction, duration, created_at').eq('customer_id', customerId).order('created_at', { ascending: false }).limit(20),
          supabase.from('phone_messages').select('id, direction, body, created_at').eq('customer_id', customerId).order('created_at', { ascending: false }).limit(20),
          supabase.from('emails').select('id, subject, direction, created_at').eq('customer_id', customerId).order('created_at', { ascending: false }).limit(20),
        ]);

        if (cancelled) return;
        const items: typeof comms = [];

        for (const c of (callsRes.data || [])) {
          items.push({ type: 'call', title: `Phone Call (${c.direction})`, date: c.created_at, detail: c.duration ? `${Math.round(c.duration / 60)}min` : undefined, icon: 'phone' });
        }
        for (const m of (messagesRes.data || [])) {
          items.push({ type: 'sms', title: `Text (${m.direction})`, date: m.created_at, detail: m.body?.slice(0, 80), icon: 'message' });
        }
        for (const e of (emailsRes.data || [])) {
          items.push({ type: 'email', title: e.subject || `Email (${e.direction})`, date: e.created_at, icon: 'mail' });
        }

        setComms(items);
      } catch {
        // Non-blocking — tables may not exist
      } finally {
        if (!cancelled) setCommsLoading(false);
      }
    }
    loadComms();
    return () => { cancelled = true; };
  }, [customerId]);

  // Merge all activity into one timeline
  const timeline = [
    ...bids.map((b) => ({ type: 'bid', title: `Bid: ${b.title}`, date: b.createdAt, status: b.status, id: b.id, link: `/dashboard/bids/${b.id}` })),
    ...jobs.map((j) => ({ type: 'job', title: `Job: ${j.title}`, date: j.createdAt, status: j.status, id: j.id, link: `/dashboard/jobs/${j.id}` })),
    ...invoices.map((i) => ({ type: 'invoice', title: `Invoice: ${i.invoiceNumber}`, date: i.createdAt, status: i.status, id: i.id, link: `/dashboard/invoices/${i.id}` })),
    ...comms.map((c, idx) => ({ type: c.type, title: c.title, date: c.date, status: c.detail, id: `comm-${idx}`, link: '' })),
  ].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

  const ICON_MAP: Record<string, typeof Mail> = { bid: FileText, job: Briefcase, invoice: Receipt, call: Phone, sms: MessageSquare, email: Mail };
  const COLOR_MAP: Record<string, string> = { bid: 'text-blue-500', job: 'text-indigo-500', invoice: 'text-emerald-500', call: 'text-green-500', sms: 'text-purple-500', email: 'text-cyan-500' };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2">
          <Clock size={16} className="text-muted" />
          Communication Timeline
        </CardTitle>
      </CardHeader>
      <CardContent>
        {commsLoading ? (
          <div className="space-y-3">
            {[1, 2, 3].map((i) => <div key={i} className="h-12 bg-secondary rounded-lg animate-pulse" />)}
          </div>
        ) : timeline.length === 0 ? (
          <div className="text-center py-8">
            <MessageSquare size={32} className="mx-auto text-muted mb-3" />
            <p className="text-sm text-muted">No activity recorded yet</p>
          </div>
        ) : (
          <div className="relative">
            {/* Vertical line */}
            <div className="absolute left-[17px] top-2 bottom-2 w-px bg-main" />
            <div className="space-y-3">
              {timeline.slice(0, 30).map((item) => {
                const Icon = ICON_MAP[item.type] || FileText;
                const color = COLOR_MAP[item.type] || 'text-muted';
                return (
                  <div
                    key={item.id}
                    className={cn('flex items-start gap-3 pl-1 relative', item.link && 'cursor-pointer hover:opacity-80')}
                    onClick={() => item.link && router.push(item.link)}
                  >
                    <div className={cn('w-8 h-8 rounded-full bg-surface border border-main flex items-center justify-center z-10 flex-shrink-0', color)}>
                      <Icon size={14} />
                    </div>
                    <div className="flex-1 min-w-0 pt-1">
                      <p className="text-sm font-medium text-main truncate">{item.title}</p>
                      <div className="flex items-center gap-2 mt-0.5">
                        <span className="text-xs text-muted">{formatDate(item.date)}</span>
                        {item.status && typeof item.status === 'string' && item.status.length < 20 && (
                          <StatusBadge status={item.status} />
                        )}
                        {item.status && typeof item.status === 'string' && item.status.length >= 20 && (
                          <span className="text-xs text-muted truncate">{item.status}</span>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
