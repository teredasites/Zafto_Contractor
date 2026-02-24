'use client';

import { useState, useEffect, useMemo } from 'react';
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
  Heart,
  X,
  Copy,
  ExternalLink,
  UserPlus,
  Send,
  ChevronRight,
  CheckCircle,
  Home,
  CreditCard,
  StickyNote,
  PhoneCall,
  PhoneIncoming,
  PhoneOutgoing,
  Building2,
  Zap,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge, Badge } from '@/components/ui/badge';
import { Avatar } from '@/components/ui/avatar';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useCustomer, useCustomers } from '@/lib/hooks/use-customers';
import { useBids } from '@/lib/hooks/use-bids';
import { useJobs } from '@/lib/hooks/use-jobs';
import { useInvoices } from '@/lib/hooks/use-invoices';
import { useEstimates } from '@/lib/hooks/use-estimates';
import { Input, Select } from '@/components/ui/input';
import { isValidEmail, isValidPhone, formatPhone } from '@/lib/validation';
import { getSupabase } from '@/lib/supabase';
import { EntityDocumentsPanel } from '@/components/entity-documents-panel';
import { CommandPalette } from '@/components/command-palette';
import type { Customer } from '@/types';
import { useTranslation } from '@/lib/translations';

type TabType = 'overview' | 'bids' | 'jobs' | 'invoices' | 'documents' | 'activity' | 'estimates' | 'communications' | 'properties' | 'payments' | 'notes';

// ---------------------------------------------------------------------------
// Shared interfaces for tabs backed by inline Supabase queries
// ---------------------------------------------------------------------------

interface CommunicationItem {
  id: string;
  type: 'call' | 'email' | 'sms';
  direction: 'inbound' | 'outbound';
  subject: string;
  preview: string;
  timestamp: string;
  duration?: number; // seconds, for calls
  status: string;
  assignedTo?: string;
}

interface PropertyItem {
  id: string;
  address: string;
  city: string;
  state: string;
  zip: string;
  propertyType: string;
  yearBuilt: number | null;
  sqft: number | null;
  lastScanDate?: string;
  jobCount: number;
}

interface PaymentItem {
  id: string;
  invoiceId: string;
  invoiceNumber: string;
  amount: number;
  method: string;
  status: string;
  paidAt: string;
  transactionId?: string;
  cardLast4?: string;
}

// ---------------------------------------------------------------------------
// Utility functions
// ---------------------------------------------------------------------------

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

/** Compute customer health score (0-100) from payment, engagement, and value metrics */
function computeHealthScore(customer: Customer, invoices: any[], jobs: any[], bids: any[]) {
  let score = 50; // Base score

  // Payment behavior (up to +30 or -20)
  const paymentStats = computePaymentBehavior(invoices);
  if (paymentStats.paidCount > 0) {
    score += Math.round((paymentStats.onTimeRate / 100) * 20); // On-time pays up to +20
    if (paymentStats.avgDaysToPay <= 14) score += 10; // Fast payer
    else if (paymentStats.avgDaysToPay > 45) score -= 15; // Very slow
    else if (paymentStats.avgDaysToPay > 30) score -= 5; // Slow
  }

  // Engagement — recent activity (up to +15)
  const allDates = [
    ...jobs.map((j: any) => new Date(j.updatedAt || j.createdAt)),
    ...invoices.map((i: any) => new Date(i.updatedAt || i.createdAt)),
    ...bids.map((b: any) => new Date(b.updatedAt || b.createdAt)),
  ];
  if (allDates.length > 0) {
    const mostRecent = Math.max(...allDates.map(d => d.getTime()));
    const daysSinceActivity = Math.round((Date.now() - mostRecent) / 86400000);
    if (daysSinceActivity <= 30) score += 15;
    else if (daysSinceActivity <= 90) score += 8;
    else if (daysSinceActivity > 180) score -= 10;
  }

  // Value — repeat business (up to +10)
  if (jobs.length >= 5) score += 10;
  else if (jobs.length >= 3) score += 5;
  else if (jobs.length >= 2) score += 2;

  // Lifetime value bonus (up to +5)
  if (customer.totalRevenue > 50000) score += 5;
  else if (customer.totalRevenue > 10000) score += 3;

  // Outstanding balance penalty
  const overdueInvoices = invoices.filter((i: any) => i.status === 'overdue');
  if (overdueInvoices.length > 0) score -= overdueInvoices.length * 5;

  return Math.max(0, Math.min(100, score));
}

function getHealthLabel(score: number): { label: string; color: string; bgColor: string } {
  if (score >= 80) return { label: 'Excellent', color: 'text-emerald-500', bgColor: 'bg-emerald-500' };
  if (score >= 60) return { label: 'Good', color: 'text-blue-500', bgColor: 'bg-blue-500' };
  if (score >= 40) return { label: 'Fair', color: 'text-amber-500', bgColor: 'bg-amber-500' };
  return { label: 'At Risk', color: 'text-red-500', bgColor: 'bg-red-500' };
}

// ---------------------------------------------------------------------------
// Main page component
// ---------------------------------------------------------------------------

export default function CustomerDetailPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const customerId = params.id as string;

  const { customer, loading, refetch } = useCustomer(customerId);
  const { updateCustomer, deleteCustomer } = useCustomers();
  const { bids } = useBids();
  const { jobs } = useJobs();
  const { invoices } = useInvoices();
  const { estimates } = useEstimates();
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [menuOpen, setMenuOpen] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [newTag, setNewTag] = useState('');
  const [showTagInput, setShowTagInput] = useState(false);
  const [showPortalInvite, setShowPortalInvite] = useState(false);
  const [portalLoading, setPortalLoading] = useState(false);
  const [editData, setEditData] = useState({
    firstName: '', lastName: '', email: '', phone: '', alternatePhone: '',
    street: '', city: '', state: '', zip: '', notes: '',
    customerType: 'residential' as 'residential' | 'commercial',
    preferredContactMethod: 'phone' as 'phone' | 'email' | 'text',
    accessInstructions: '',
  });
  const [editErrors, setEditErrors] = useState<Record<string, string>>({});

  const startEditing = () => {
    if (!customer) return;
    setEditData({
      firstName: customer.firstName, lastName: customer.lastName,
      email: customer.email || '', phone: customer.phone || '',
      alternatePhone: customer.alternatePhone || '',
      street: customer.address?.street || '', city: customer.address?.city || '',
      state: customer.address?.state || '', zip: customer.address?.zip || '',
      notes: customer.notes || '',
      customerType: customer.customerType || 'residential',
      preferredContactMethod: customer.preferredContactMethod || 'phone',
      accessInstructions: customer.accessInstructions || '',
    });
    setEditErrors({});
    setIsEditing(true);
    setMenuOpen(false);
  };

  const handleSaveEdit = async () => {
    const errs: Record<string, string> = {};
    if (!editData.firstName.trim()) errs.firstName = 'First name required';
    if (!editData.lastName.trim()) errs.lastName = 'Last name required';
    if (editData.email && !isValidEmail(editData.email)) errs.email = 'Invalid email';
    if (editData.phone && !isValidPhone(editData.phone)) errs.phone = 'Invalid phone';
    if (Object.keys(errs).length > 0) { setEditErrors(errs); return; }

    try {
      setSaving(true);
      await updateCustomer(customerId, {
        firstName: editData.firstName.trim(),
        lastName: editData.lastName.trim(),
        email: editData.email?.trim() || undefined,
        phone: editData.phone ? formatPhone(editData.phone) : undefined,
        address: { street: editData.street, city: editData.city, state: editData.state, zip: editData.zip },
        notes: editData.notes || undefined,
      });
      setIsEditing(false);
      refetch();
    } catch (err) {
      setEditErrors({ submit: err instanceof Error ? err.message : 'Failed to update' });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!window.confirm(`Delete ${customer?.firstName} ${customer?.lastName}? This cannot be undone.`)) return;
    try {
      await deleteCustomer(customerId);
      router.push('/dashboard/customers');
    } catch {
      // silent
    }
  };

  const addTag = async (tag: string) => {
    if (!customer || !tag.trim()) return;
    const normalized = tag.trim().toLowerCase().replace(/\s+/g, '-');
    if (customer.tags.includes(normalized)) return;
    try {
      await updateCustomer(customerId, { tags: [...customer.tags, normalized] });
      setNewTag('');
      setShowTagInput(false);
      refetch();
    } catch { /* silent */ }
  };

  const removeTag = async (tag: string) => {
    if (!customer) return;
    try {
      await updateCustomer(customerId, { tags: customer.tags.filter(t => t !== tag) });
      refetch();
    } catch { /* silent */ }
  };

  const sendPortalInvite = async () => {
    if (!customer?.email) { alert('Customer has no email address'); return; }
    setPortalLoading(true);
    try {
      const supabase = getSupabase();
      const { error: err } = await supabase.functions.invoke('send-client-portal-invite', {
        body: { customerId, email: customer.email, name: `${customer.firstName} ${customer.lastName}` },
      });
      if (err) throw err;
      alert('Portal invitation sent!');
      setShowPortalInvite(false);
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to send invite');
    } finally {
      setPortalLoading(false);
    }
  };

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
        <h2 className="text-xl font-semibold text-main">{t('customers.customerNotFound')}</h2>
        <p className="text-muted mt-2">{t('customers.customerDoesntExist')}</p>
        <Button variant="secondary" className="mt-4" onClick={() => router.push('/dashboard/customers')}>
          Back to Customers
        </Button>
      </div>
    );
  }

  const customerBids = useMemo(() => bids.filter((b) => b.customerId === customerId), [bids, customerId]);
  const customerJobs = useMemo(() => jobs.filter((j) => j.customerId === customerId), [jobs, customerId]);
  const customerInvoices = useMemo(() => invoices.filter((i) => i.customerId === customerId), [invoices, customerId]);
  const customerEstimates = useMemo(() => estimates.filter((e) => e.customerId === customerId), [estimates, customerId]);

  // Derive unique property addresses from customer jobs for the Properties tab
  const customerPropertyAddresses = useMemo(() => {
    const seen = new Set<string>();
    const results: PropertyItem[] = [];
    for (const j of customerJobs) {
      const addr = j.address?.street || '';
      if (!addr) continue;
      const key = `${addr}|${j.address?.city || ''}|${j.address?.state || ''}|${j.address?.zip || ''}`;
      if (seen.has(key)) {
        // Increment job count on existing entry
        const existing = results.find(p => p.id === key);
        if (existing) existing.jobCount++;
        continue;
      }
      seen.add(key);
      results.push({
        id: key,
        address: addr,
        city: j.address?.city || '',
        state: j.address?.state || '',
        zip: j.address?.zip || '',
        propertyType: 'residential',
        yearBuilt: null,
        sqft: null,
        jobCount: 1,
      });
    }
    return results;
  }, [customerJobs]);

  // Derive payment records from paid invoices
  const customerPayments = useMemo((): PaymentItem[] => {
    return customerInvoices
      .filter((inv) => inv.paidAt && inv.amountPaid > 0)
      .map((inv) => ({
        id: `pay-${inv.id}`,
        invoiceId: inv.id,
        invoiceNumber: inv.invoiceNumber,
        amount: inv.amountPaid,
        method: inv.paymentMethod || 'other',
        status: inv.amountDue <= 0 ? 'completed' : 'partial',
        paidAt: typeof inv.paidAt === 'string' ? inv.paidAt : inv.paidAt ? new Date(inv.paidAt).toISOString() : new Date().toISOString(),
      }));
  }, [customerInvoices]);

  const tabs: { id: TabType; label: string; count: number }[] = [
    { id: 'overview', label: 'Overview', count: 0 },
    { id: 'bids', label: 'Bids', count: customerBids.length },
    { id: 'estimates', label: 'Estimates', count: customerEstimates.length },
    { id: 'jobs', label: 'Jobs', count: customerJobs.length },
    { id: 'invoices', label: 'Invoices', count: customerInvoices.length },
    { id: 'payments', label: 'Payments', count: customerPayments.length },
    { id: 'properties', label: 'Properties', count: customerPropertyAddresses.length },
    { id: 'communications', label: 'Comms', count: 0 },
    { id: 'documents', label: 'Documents', count: 0 },
    { id: 'notes', label: 'Notes', count: 0 },
    { id: 'activity', label: 'Activity', count: 0 },
  ];

  const paymentStats = computePaymentBehavior(customerInvoices);
  const healthScore = computeHealthScore(customer, customerInvoices, customerJobs, customerBids);
  const health = getHealthLabel(healthScore);

  // Compute projected annual value from service agreements + repeat patterns
  const avgJobValue = customer.jobCount > 0 ? customer.totalRevenue / customer.jobCount : 0;
  const customerAge = Math.max(1, Math.round((Date.now() - new Date(customer.createdAt).getTime()) / (365.25 * 86400000)));
  const annualValue = customer.totalRevenue / customerAge;

  return (
    <div className="space-y-6 pb-8">
      <CommandPalette />

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
                <div className="absolute right-0 top-full mt-1 w-56 bg-surface border border-main rounded-lg shadow-lg py-1 z-50">
                  <button onClick={startEditing} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Edit size={16} />
                    Edit Customer
                  </button>
                  <hr className="my-1 border-main" />
                  <button onClick={() => { setMenuOpen(false); router.push(`/dashboard/jobs/new?customerId=${customer.id}`); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Briefcase size={16} />
                    Create Job
                  </button>
                  <button onClick={() => { setMenuOpen(false); router.push(`/dashboard/bids/new?customerId=${customer.id}`); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <FileText size={16} />
                    Create Estimate
                  </button>
                  <button onClick={() => { setMenuOpen(false); router.push(`/dashboard/invoices/new?customerId=${customer.id}`); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Receipt size={16} />
                    Create Invoice
                  </button>
                  <button onClick={() => { setMenuOpen(false); router.push(`/dashboard/zdocs/new?customerId=${customer.id}`); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <FileText size={16} />
                    Send Document
                  </button>
                  <button onClick={() => { setMenuOpen(false); router.push(`/dashboard/scheduling/new?customerId=${customer.id}`); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Calendar size={16} />
                    Schedule Appointment
                  </button>
                  <hr className="my-1 border-main" />
                  <button onClick={() => { setMenuOpen(false); setShowPortalInvite(true); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <ExternalLink size={16} />
                    Send Portal Invite
                  </button>
                  <button onClick={() => { setMenuOpen(false); navigator.clipboard.writeText(`${customer.firstName} ${customer.lastName}\n${customer.email}\n${customer.phone}`); alert('Contact copied!'); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Copy size={16} />
                    Copy Contact Info
                  </button>
                  <hr className="my-1 border-main" />
                  <button onClick={handleDelete} className="w-full px-4 py-2 text-left text-sm hover:bg-red-50 dark:hover:bg-red-900/20 text-red-600 flex items-center gap-2">
                    <Trash2 size={16} />
                    Delete
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Edit Modal */}
      {isEditing && (
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="text-base">{t('common.editCustomer')}</CardTitle>
            <Button variant="ghost" size="icon" onClick={() => setIsEditing(false)}>
              <span className="sr-only">{t('common.close')}</span>&times;
            </Button>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input label={t('customers.firstName')} value={editData.firstName} onChange={(e) => setEditData({ ...editData, firstName: e.target.value })} error={editErrors.firstName} />
              <Input label={t('customers.lastName')} value={editData.lastName} onChange={(e) => setEditData({ ...editData, lastName: e.target.value })} error={editErrors.lastName} />
              <Input label={t('email.title')} type="email" value={editData.email} onChange={(e) => setEditData({ ...editData, email: e.target.value })} error={editErrors.email} />
              <Input label={t('phone.title')} value={editData.phone} onChange={(e) => setEditData({ ...editData, phone: e.target.value })} error={editErrors.phone} />
              <Input label="Alternate Phone" value={editData.alternatePhone} onChange={(e) => setEditData({ ...editData, alternatePhone: e.target.value })} />
              <Select label={t('common.type')} value={editData.customerType} onChange={(e) => setEditData({ ...editData, customerType: e.target.value as 'residential' | 'commercial' })} options={[{ value: 'residential', label: 'Residential' }, { value: 'commercial', label: 'Commercial' }]} />
              <Input label={t('common.street')} value={editData.street} onChange={(e) => setEditData({ ...editData, street: e.target.value })} />
              <Input label={t('common.city')} value={editData.city} onChange={(e) => setEditData({ ...editData, city: e.target.value })} />
              <Input label={t('common.state')} value={editData.state} onChange={(e) => setEditData({ ...editData, state: e.target.value })} />
              <Input label={t('common.zip')} value={editData.zip} onChange={(e) => setEditData({ ...editData, zip: e.target.value })} />
              <div className="md:col-span-2">
                <Input label="Access Instructions" value={editData.accessInstructions} onChange={(e) => setEditData({ ...editData, accessInstructions: e.target.value })} />
              </div>
              <div className="md:col-span-2">
                <Input label={t('walkthroughs.notes')} value={editData.notes} onChange={(e) => setEditData({ ...editData, notes: e.target.value })} />
              </div>
            </div>
            {editErrors.submit && <p className="text-sm text-red-500 mt-2">{editErrors.submit}</p>}
            <div className="flex items-center justify-end gap-3 mt-4">
              <Button variant="ghost" onClick={() => setIsEditing(false)}>{t('common.cancel')}</Button>
              <Button onClick={handleSaveEdit} disabled={saving}>{saving ? 'Saving...' : 'Save Changes'}</Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Tabs — scrollable on mobile */}
      <div className="flex gap-1 p-1 bg-secondary rounded-lg w-fit max-w-full overflow-x-auto">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              'flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors whitespace-nowrap',
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
          {activeTab === 'estimates' && <EstimatesTab customerId={customerId} estimates={customerEstimates} />}
          {activeTab === 'jobs' && <JobsTab jobs={customerJobs} />}
          {activeTab === 'invoices' && <InvoicesTab invoices={customerInvoices} />}
          {activeTab === 'payments' && <PaymentsTab customerId={customerId} payments={customerPayments} />}
          {activeTab === 'properties' && <PropertiesTab customerId={customerId} properties={customerPropertyAddresses} />}
          {activeTab === 'communications' && <CommunicationsTab customerId={customerId} />}
          {activeTab === 'documents' && <DocumentsTab customerId={customerId} />}
          {activeTab === 'notes' && <NotesTab customerId={customerId} customerNotes={customer.notes || ''} updateCustomer={updateCustomer} refetch={refetch} />}
          {activeTab === 'activity' && <ActivityTimeline customerId={customerId} bids={customerBids} jobs={customerJobs} invoices={customerInvoices} />}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Health Score */}
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-base flex items-center gap-2">
                <Heart size={16} className={health.color} />
                Customer Health
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-center justify-between">
                <div>
                  <span className={cn('text-3xl font-bold', health.color)}>{healthScore}</span>
                  <span className="text-sm text-muted">/100</span>
                </div>
                <span className={cn('text-sm font-medium px-2 py-0.5 rounded-full', health.color, health.bgColor + '/10')}>
                  {health.label}
                </span>
              </div>
              <div className="w-full h-2 bg-secondary rounded-full overflow-hidden">
                <div
                  className={cn('h-full rounded-full transition-all', health.bgColor)}
                  style={{ width: `${healthScore}%` }}
                />
              </div>
            </CardContent>
          </Card>

          {/* Lifetime Value */}
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-base flex items-center gap-2">
                <DollarSign size={16} className="text-emerald-500" />
                Lifetime Value
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(customer.totalRevenue)}</p>
                <p className="text-xs text-muted">{t('common.lifetimeRevenue')}</p>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('customers.totalJobs')}</span>
                <span className="font-medium text-main">{customer.jobCount}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.avgJobValue')}</span>
                <span className="font-medium text-main">{formatCurrency(avgJobValue)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">Annual Value</span>
                <span className="font-medium text-main">{formatCurrency(annualValue)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('customers.customerSince')}</span>
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
                  <span className="text-sm text-muted">{t('common.status')}</span>
                  <Badge variant={paymentStats.label === 'Slow Payer' ? 'warning' : paymentStats.label === 'Reliable' ? 'success' : 'default'}>
                    {paymentStats.label === 'Slow Payer' && <AlertTriangle size={10} className="mr-1" />}
                    {paymentStats.label}
                  </Badge>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">{t('common.avgDaysToPay')}</span>
                  <span className={cn('font-medium', paymentStats.avgDaysToPay > 30 ? 'text-amber-500' : 'text-main')}>
                    {paymentStats.avgDaysToPay} days
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">{t('common.onTimeRate')}</span>
                  <span className={cn('font-medium', paymentStats.onTimeRate >= 80 ? 'text-emerald-500' : 'text-amber-500')}>
                    {paymentStats.onTimeRate}%
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">{t('common.totalPaid')}</span>
                  <span className="font-medium text-main">{formatCurrency(paymentStats.totalLifetimeSpend)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">{t('common.invoicesPaid')}</span>
                  <span className="font-medium text-main">{paymentStats.paidCount}</span>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Contact Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">{t('common.contactInformation')}</CardTitle>
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
              <CardTitle className="text-base">{t('common.tags')}</CardTitle>
              <Button variant="ghost" size="sm" onClick={() => setShowTagInput(true)}>
                <Plus size={14} />
                Add
              </Button>
            </CardHeader>
            <CardContent>
              <div className="flex flex-wrap gap-2">
                {customer.tags.map((tag) => (
                  <span key={tag} className="inline-flex items-center gap-1 px-2.5 py-1 bg-secondary border border-main rounded-full text-sm text-main group">
                    {tag}
                    <button
                      onClick={() => removeTag(tag)}
                      className="opacity-0 group-hover:opacity-100 transition-opacity p-0.5 hover:bg-red-500/10 rounded-full"
                    >
                      <X size={12} className="text-red-400" />
                    </button>
                  </span>
                ))}
                {customer.tags.length === 0 && !showTagInput && (
                  <p className="text-sm text-muted">{t('common.noTags')}</p>
                )}
              </div>
              {showTagInput && (
                <div className="flex items-center gap-2 mt-3">
                  <input
                    type="text"
                    value={newTag}
                    onChange={(e) => setNewTag(e.target.value)}
                    placeholder="Tag name..."
                    className="flex-1 px-3 py-1.5 bg-secondary border border-main rounded-lg text-sm text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
                    onKeyDown={(e) => { if (e.key === 'Enter') addTag(newTag); if (e.key === 'Escape') setShowTagInput(false); }}
                    autoFocus
                  />
                  <Button size="sm" onClick={() => addTag(newTag)}>Add</Button>
                  <button onClick={() => { setShowTagInput(false); setNewTag(''); }} className="p-1 hover:bg-surface-hover rounded">
                    <X size={14} className="text-muted" />
                  </button>
                </div>
              )}
              {/* Preset tag suggestions */}
              {showTagInput && (
                <div className="flex flex-wrap gap-1.5 mt-2">
                  {['vip', 'commercial', 'residential', 'insurance', 'maintenance', 'referral', 'repeat'].filter(t => !customer.tags.includes(t)).slice(0, 5).map((suggestion) => (
                    <button
                      key={suggestion}
                      onClick={() => addTag(suggestion)}
                      className="px-2 py-0.5 text-xs bg-surface border border-main rounded-full text-muted hover:text-main hover:bg-surface-hover transition-colors"
                    >
                      + {suggestion}
                    </button>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Notes */}
          {customer.notes && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">{t('common.notes')}</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-main">{customer.notes}</p>
              </CardContent>
            </Card>
          )}

          {/* Source / Referral */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <UserPlus size={16} className="text-muted" />
                Source & Referral
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-muted">Lead Source</span>
                <Badge variant="default" className="capitalize">{customer.source || 'Direct'}</Badge>
              </div>
              {customer.source === 'referral' && (
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Referred By</span>
                  <span className="text-main font-medium">--</span>
                </div>
              )}
              <div className="flex justify-between text-sm">
                <span className="text-muted">Referrals Made</span>
                <span className="text-main font-medium">0</span>
              </div>
            </CardContent>
          </Card>

          {/* Client Portal */}
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-base flex items-center gap-2">
                <ExternalLink size={16} className="text-muted" />
                Client Portal
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="text-xs text-muted">
                Give this customer access to view their jobs, invoices, and documents at client.zafto.cloud
              </p>
              <Button
                variant="secondary"
                size="sm"
                className="w-full"
                disabled={portalLoading || !customer.email}
                onClick={() => setShowPortalInvite(true)}
              >
                <Send size={14} className="mr-1" />
                Send Portal Invite
              </Button>
              {!customer.email && (
                <p className="text-xs text-amber-500">Add an email to send portal invites</p>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Portal Invite Modal */}
      {showPortalInvite && (
        <>
          <div className="fixed inset-0 bg-black/50 z-50" onClick={() => setShowPortalInvite(false)} />
          <div className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md z-50">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <ExternalLink size={18} />
                  Send Portal Invitation
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-sm text-muted">
                  Send a magic link to <span className="text-main font-medium">{customer.email}</span> so they can access their client portal at client.zafto.cloud
                </p>
                <div className="p-3 bg-secondary rounded-lg space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-muted">Customer</span>
                    <span className="text-main">{customer.firstName} {customer.lastName}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-muted">Email</span>
                    <span className="text-main">{customer.email}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-muted">Portal access</span>
                    <span className="text-main">Jobs, Invoices, Documents, Payments</span>
                  </div>
                </div>
                <div className="flex gap-3">
                  <Button variant="secondary" className="flex-1" onClick={() => setShowPortalInvite(false)}>Cancel</Button>
                  <Button className="flex-1" disabled={portalLoading} onClick={sendPortalInvite}>
                    {portalLoading ? 'Sending...' : 'Send Invite'}
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        </>
      )}
    </div>
  );
}

// ===========================================================================
// EXISTING TABS
// ===========================================================================

function OverviewTab({ customer, bids, jobs, invoices }: { customer: Customer; bids: any[]; jobs: any[]; invoices: any[] }) {
  const { t } = useTranslation();
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
            <p className="text-sm text-muted">{t('bidsPage.title')}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <Briefcase size={24} className="mx-auto text-indigo-500 mb-2" />
            <p className="text-2xl font-semibold text-main">{jobs.length}</p>
            <p className="text-sm text-muted">{t('customers.tabs.jobs')}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <Receipt size={24} className="mx-auto text-emerald-500 mb-2" />
            <p className="text-2xl font-semibold text-main">{invoices.length}</p>
            <p className="text-sm text-muted">{t('customers.tabs.invoices')}</p>
          </CardContent>
        </Card>
      </div>

      {/* Recent Activity */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t('dashboard.recentActivity')}</CardTitle>
        </CardHeader>
        <CardContent>
          {recentActivity.length === 0 ? (
            <p className="text-center text-muted py-4">{t('common.noActivityYet')}</p>
          ) : (
            <div className="space-y-3">
              {recentActivity.map((item) => (
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
  const { t } = useTranslation();
  const router = useRouter();

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">{t('bidsPage.title')}</CardTitle>
        <Button variant="secondary" size="sm">
          <Plus size={14} />
          New Bid
        </Button>
      </CardHeader>
      <CardContent className="p-0">
        {bids.length === 0 ? (
          <div className="py-12 text-center">
            <FileText size={40} className="mx-auto text-muted mb-2 opacity-50" />
            <p className="text-muted">{t('bidsPage.noBids')}</p>
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
  const { t } = useTranslation();
  const router = useRouter();

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">{t('customers.tabs.jobs')}</CardTitle>
        <Button variant="secondary" size="sm">
          <Plus size={14} />
          New Job
        </Button>
      </CardHeader>
      <CardContent className="p-0">
        {jobs.length === 0 ? (
          <div className="py-12 text-center">
            <Briefcase size={40} className="mx-auto text-muted mb-2 opacity-50" />
            <p className="text-muted">{t('common.noJobsYet')}</p>
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
  const { t } = useTranslation();
  const router = useRouter();

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">{t('customers.tabs.invoices')}</CardTitle>
        <Button variant="secondary" size="sm">
          <Plus size={14} />
          New Invoice
        </Button>
      </CardHeader>
      <CardContent className="p-0">
        {invoices.length === 0 ? (
          <div className="py-12 text-center">
            <Receipt size={40} className="mx-auto text-muted mb-2 opacity-50" />
            <p className="text-muted">{t('invoices.noInvoices')}</p>
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
  const { t } = useTranslation();
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
            <p className="text-sm text-muted">{t('common.noActivityRecordedYet')}</p>
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

/** Documents associated with a customer */
function DocumentsTab({ customerId }: { customerId: string }) {
  const { t } = useTranslation();
  const router = useRouter();
  const [docs, setDocs] = useState<{ id: string; title: string; type: string; createdAt: string; status: string }[]>([]);
  const [docsLoading, setDocsLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    async function loadDocs() {
      try {
        const supabase = getSupabase();
        const { data } = await supabase
          .from('documents')
          .select('id, title, document_type, created_at, status')
          .eq('customer_id', customerId)
          .is('deleted_at', null)
          .order('created_at', { ascending: false });

        if (cancelled) return;
        setDocs((data || []).map((d: Record<string, string>) => ({
          id: d.id,
          title: d.title || 'Untitled',
          type: d.document_type || 'document',
          createdAt: d.created_at,
          status: d.status || 'draft',
        })));
      } catch {
        // Table may not exist yet
      } finally {
        if (!cancelled) setDocsLoading(false);
      }
    }
    loadDocs();
    return () => { cancelled = true; };
  }, [customerId]);

  if (docsLoading) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="space-y-3">
            {[1, 2, 3].map(i => <div key={i} className="h-12 bg-secondary rounded-lg animate-pulse" />)}
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {/* ZDocs Generated Documents */}
      <EntityDocumentsPanel
        entityType="customer"
        entityId={customerId}
        onGenerateDocument={() => router.push('/dashboard/zdocs')}
      />

      {/* Uploaded/Legacy Documents */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-base">Uploaded Documents</CardTitle>
          <Button variant="secondary" size="sm" onClick={() => router.push(`/dashboard/zdocs/new?customerId=${customerId}`)}>
            <Plus size={14} />
            New Document
          </Button>
        </CardHeader>
        <CardContent className="p-0">
          {docs.length === 0 ? (
            <div className="py-12 text-center">
              <FileText size={40} className="mx-auto text-muted mb-2 opacity-50" />
              <p className="text-muted">No uploaded documents yet</p>
            </div>
          ) : (
            <div className="divide-y divide-main">
              {docs.map((doc) => (
                <div
                  key={doc.id}
                  onClick={() => router.push(`/dashboard/zdocs/${doc.id}`)}
                  className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <FileText size={16} className="text-muted" />
                      <div>
                        <p className="font-medium text-main">{doc.title}</p>
                        <p className="text-xs text-muted capitalize">{doc.type.replace(/_/g, ' ')} &middot; {formatDate(doc.createdAt)}</p>
                      </div>
                    </div>
                    <Badge variant={doc.status === 'signed' ? 'success' : doc.status === 'sent' ? 'info' : 'default'}>
                      {doc.status}
                    </Badge>
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

// ===========================================================================
// NEW TABS
// ===========================================================================

/** Estimates tab — shows all estimates for this customer (real data from useEstimates) */
function EstimatesTab({ customerId, estimates }: { customerId: string; estimates: import('@/lib/hooks/use-estimates').Estimate[] }) {
  const { t } = useTranslation();
  const router = useRouter();
  const [filterStatus, setFilterStatus] = useState<string>('all');

  const filtered = filterStatus === 'all' ? estimates : estimates.filter(e => e.status === filterStatus);

  const totalPipeline = estimates.filter(e => e.status === 'sent').reduce((s, e) => s + e.grandTotal, 0);
  const totalApproved = estimates.filter(e => e.status === 'approved').reduce((s, e) => s + e.grandTotal, 0);
  const conversionRate = estimates.length > 0
    ? Math.round((estimates.filter(e => e.status === 'approved').length / estimates.length) * 100)
    : 0;

  function getEstimateStatusBadge(status: string) {
    const map: Record<string, { variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple'; label: string }> = {
      draft: { variant: 'secondary', label: 'Draft' },
      sent: { variant: 'info', label: 'Sent' },
      approved: { variant: 'success', label: 'Approved' },
      declined: { variant: 'error', label: 'Declined' },
      revised: { variant: 'purple', label: 'Revised' },
      completed: { variant: 'success', label: 'Completed' },
    };
    const cfg = map[status] || { variant: 'default' as const, label: status };
    return <Badge variant={cfg.variant}>{cfg.label}</Badge>;
  }

  return (
    <div className="space-y-4">
      {/* Summary cards */}
      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider">Pipeline</p>
            <p className="text-xl font-semibold text-main mt-1">{formatCurrency(totalPipeline)}</p>
            <p className="text-xs text-muted">{estimates.filter(e => e.status === 'sent').length} open estimates</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider">Won</p>
            <p className="text-xl font-semibold text-emerald-500 mt-1">{formatCurrency(totalApproved)}</p>
            <p className="text-xs text-muted">{estimates.filter(e => e.status === 'approved').length} approved</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider">Win Rate</p>
            <p className="text-xl font-semibold text-main mt-1">{conversionRate}%</p>
            <p className="text-xs text-muted">{estimates.length} total estimates</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-base">Estimates</CardTitle>
          <div className="flex items-center gap-2">
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="text-xs bg-secondary border border-main rounded-md px-2 py-1 text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
            >
              <option value="all">All Statuses</option>
              <option value="draft">Draft</option>
              <option value="sent">Sent</option>
              <option value="approved">Approved</option>
              <option value="declined">Declined</option>
              <option value="revised">Revised</option>
              <option value="completed">Completed</option>
            </select>
            <Button variant="secondary" size="sm" onClick={() => router.push(`/dashboard/bids/new?customerId=${customerId}`)}>
              <Plus size={14} />
              New Estimate
            </Button>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {filtered.length === 0 ? (
            <div className="py-12 text-center">
              <FileText size={40} className="mx-auto text-muted mb-2 opacity-50" />
              <p className="text-muted">No estimates found</p>
            </div>
          ) : (
            <div className="divide-y divide-main">
              {filtered.map((est) => (
                <div
                  key={est.id}
                  className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
                  onClick={() => router.push(`/dashboard/bids/${est.id}`)}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="font-medium text-main">{est.title || 'Untitled Estimate'}</p>
                        <span className="text-xs text-muted">{est.estimateNumber}</span>
                      </div>
                      {est.notes && <p className="text-sm text-muted mt-0.5 truncate">{est.notes}</p>}
                      <div className="flex items-center gap-3 mt-1">
                        <span className="text-xs text-muted capitalize">{est.estimateType}</span>
                        <span className="text-xs text-muted">Created {formatDate(est.createdAt)}</span>
                        {est.validUntil && <span className="text-xs text-muted">Expires {formatDate(est.validUntil)}</span>}
                      </div>
                    </div>
                    <div className="flex items-center gap-3 ml-4">
                      <span className="font-semibold text-main">{formatCurrency(est.grandTotal)}</span>
                      {getEstimateStatusBadge(est.status)}
                    </div>
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

/** Communications tab — calls, emails, SMS timeline */
function CommunicationsTab({ customerId }: { customerId: string }) {
  const { t } = useTranslation();
  const [filterType, setFilterType] = useState<string>('all');
  const [communications, setCommunications] = useState<CommunicationItem[]>([]);
  const [commsLoading, setCommsLoading] = useState(true);

  useEffect(() => {
    let ignore = false;

    async function fetchCommunications() {
      try {
        setCommsLoading(true);
        const supabase = getSupabase();

        // Fetch phone calls
        const { data: calls } = await supabase
          .from('phone_calls')
          .select('id, direction, status, duration_seconds, ai_summary, started_at, caller_name')
          .eq('customer_id', customerId)
          .is('deleted_at', null)
          .order('started_at', { ascending: false })
          .limit(50);

        // Fetch text messages
        const { data: messages } = await supabase
          .from('phone_messages')
          .select('id, direction, body, status, created_at')
          .eq('customer_id', customerId)
          .is('deleted_at', null)
          .order('created_at', { ascending: false })
          .limit(50);

        // Fetch emails linked to this customer
        const { data: emails } = await supabase
          .from('email_sends')
          .select('id, subject, status, created_at, direction')
          .eq('related_type', 'customer')
          .eq('related_id', customerId)
          .is('deleted_at', null)
          .order('created_at', { ascending: false })
          .limit(50);

        if (ignore) return;

        const items: CommunicationItem[] = [];

        for (const c of calls || []) {
          items.push({
            id: c.id,
            type: 'call',
            direction: c.direction === 'inbound' ? 'inbound' : 'outbound',
            subject: c.direction === 'inbound' ? 'Incoming Call' : 'Outgoing Call',
            preview: c.ai_summary || 'No summary',
            timestamp: c.started_at || '',
            duration: c.duration_seconds ?? undefined,
            status: c.status || 'completed',
          });
        }

        for (const m of messages || []) {
          items.push({
            id: m.id,
            type: 'sms',
            direction: m.direction === 'inbound' ? 'inbound' : 'outbound',
            subject: m.direction === 'inbound' ? 'Incoming Text' : 'Outgoing Text',
            preview: m.body || '',
            timestamp: m.created_at || '',
            status: m.status || 'delivered',
          });
        }

        for (const e of emails || []) {
          items.push({
            id: e.id,
            type: 'email',
            direction: (e as any).direction === 'inbound' ? 'inbound' : 'outbound',
            subject: e.subject || 'No Subject',
            preview: '',
            timestamp: e.created_at || '',
            status: e.status || 'sent',
          });
        }

        // Sort by timestamp descending
        items.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
        setCommunications(items);
      } catch {
        // Non-blocking — leave empty
      } finally {
        if (!ignore) setCommsLoading(false);
      }
    }

    fetchCommunications();
    return () => { ignore = true; };
  }, [customerId]);

  const filtered = filterType === 'all' ? communications : communications.filter(c => c.type === filterType);

  const callCount = communications.filter(c => c.type === 'call').length;
  const emailCount = communications.filter(c => c.type === 'email').length;
  const smsCount = communications.filter(c => c.type === 'sms').length;

  function getCommIcon(type: string, direction: string) {
    if (type === 'call') {
      return direction === 'inbound'
        ? <PhoneIncoming size={16} className="text-green-500" />
        : <PhoneOutgoing size={16} className="text-blue-500" />;
    }
    if (type === 'email') return <Mail size={16} className="text-cyan-500" />;
    return <MessageSquare size={16} className="text-purple-500" />;
  }

  function getCommStatusBadge(status: string) {
    const map: Record<string, { variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple'; label: string }> = {
      completed: { variant: 'success', label: 'Completed' },
      missed: { variant: 'error', label: 'Missed' },
      sent: { variant: 'info', label: 'Sent' },
      delivered: { variant: 'success', label: 'Delivered' },
      read: { variant: 'purple', label: 'Read' },
      bounced: { variant: 'error', label: 'Bounced' },
      failed: { variant: 'error', label: 'Failed' },
    };
    const cfg = map[status] || { variant: 'default' as const, label: status };
    return <Badge variant={cfg.variant}>{cfg.label}</Badge>;
  }

  function formatDuration(seconds: number): string {
    if (seconds < 60) return `${seconds}s`;
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return secs > 0 ? `${mins}m ${secs}s` : `${mins}m`;
  }

  if (commsLoading) {
    return (
      <div className="flex items-center justify-center h-32">
        <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Summary stats */}
      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-green-500/10 flex items-center justify-center">
              <PhoneCall size={20} className="text-green-500" />
            </div>
            <div>
              <p className="text-lg font-semibold text-main">{callCount}</p>
              <p className="text-xs text-muted">Phone Calls</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-cyan-500/10 flex items-center justify-center">
              <Mail size={20} className="text-cyan-500" />
            </div>
            <div>
              <p className="text-lg font-semibold text-main">{emailCount}</p>
              <p className="text-xs text-muted">Emails</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-purple-500/10 flex items-center justify-center">
              <MessageSquare size={20} className="text-purple-500" />
            </div>
            <div>
              <p className="text-lg font-semibold text-main">{smsCount}</p>
              <p className="text-xs text-muted">Text Messages</p>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-base">Communications</CardTitle>
          <div className="flex items-center gap-2">
            <select
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
              className="text-xs bg-secondary border border-main rounded-md px-2 py-1 text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
            >
              <option value="all">All Types</option>
              <option value="call">Calls</option>
              <option value="email">Emails</option>
              <option value="sms">Text Messages</option>
            </select>
          </div>
        </CardHeader>
        <CardContent>
          {filtered.length === 0 ? (
            <div className="py-12 text-center">
              <MessageSquare size={40} className="mx-auto text-muted mb-2 opacity-50" />
              <p className="text-muted">No communications recorded</p>
            </div>
          ) : (
            <div className="relative">
              <div className="absolute left-[17px] top-2 bottom-2 w-px bg-main" />
              <div className="space-y-4">
                {filtered.map((comm) => (
                  <div key={comm.id} className="flex items-start gap-3 pl-1 relative">
                    <div className="w-8 h-8 rounded-full bg-surface border border-main flex items-center justify-center z-10 flex-shrink-0">
                      {getCommIcon(comm.type, comm.direction)}
                    </div>
                    <div className="flex-1 min-w-0 bg-secondary rounded-lg p-3">
                      <div className="flex items-center justify-between mb-1">
                        <div className="flex items-center gap-2">
                          <p className="text-sm font-medium text-main">{comm.subject}</p>
                          <Badge variant={comm.direction === 'inbound' ? 'info' : 'default'}>
                            {comm.direction === 'inbound' ? 'Inbound' : 'Outbound'}
                          </Badge>
                        </div>
                        {getCommStatusBadge(comm.status)}
                      </div>
                      {comm.preview && <p className="text-sm text-muted mt-1">{comm.preview}</p>}
                      <div className="flex items-center gap-3 mt-2">
                        <span className="text-xs text-muted">{formatDate(comm.timestamp)}</span>
                        {comm.duration !== undefined && (
                          <span className="text-xs text-muted">
                            <Clock size={10} className="inline mr-1" />
                            {formatDuration(comm.duration)}
                          </span>
                        )}
                        {comm.assignedTo && (
                          <span className="text-xs text-muted">
                            <User size={10} className="inline mr-1" />
                            {comm.assignedTo}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

/** Properties tab — derived from customer job addresses */
function PropertiesTab({ customerId, properties }: { customerId: string; properties: PropertyItem[] }) {
  const router = useRouter();

  function getPropertyTypeIcon(type: string) {
    if (type === 'commercial') return <Building2 size={18} className="text-blue-500" />;
    if (type === 'industrial') return <Zap size={18} className="text-amber-500" />;
    return <Home size={18} className="text-indigo-500" />;
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-medium text-main">Properties ({properties.length})</h3>
      </div>

      {properties.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <Home size={40} className="mx-auto text-muted mb-2 opacity-50" />
            <p className="text-muted">No properties linked to this customer</p>
            <p className="text-xs text-muted mt-1">Properties are derived from job addresses</p>
          </CardContent>
        </Card>
      ) : (
        properties.map((prop) => (
          <Card key={prop.id}>
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between">
                <div className="flex items-start gap-3">
                  <div className="w-10 h-10 rounded-lg bg-secondary flex items-center justify-center mt-0.5">
                    {getPropertyTypeIcon(prop.propertyType)}
                  </div>
                  <div>
                    <CardTitle className="text-base">{prop.address}</CardTitle>
                    <p className="text-sm text-muted mt-0.5">{prop.city}, {prop.state} {prop.zip}</p>
                    <div className="flex items-center gap-3 mt-1">
                      {prop.yearBuilt && <span className="text-xs text-muted">Built {prop.yearBuilt}</span>}
                      {prop.sqft && <span className="text-xs text-muted">{prop.sqft.toLocaleString()} sq ft</span>}
                      <Badge variant="default" className="capitalize">{prop.propertyType}</Badge>
                      <span className="text-xs text-muted">{prop.jobCount} {prop.jobCount === 1 ? 'job' : 'jobs'}</span>
                    </div>
                  </div>
                </div>
                {prop.lastScanDate && (
                  <div className="text-right">
                    <p className="text-xs text-muted">Last Scan</p>
                    <p className="text-xs text-main">{formatDate(prop.lastScanDate)}</p>
                  </div>
                )}
              </div>
            </CardHeader>
          </Card>
        ))
      )}
    </div>
  );
}

/** Payments tab — payment history derived from paid invoices */
function PaymentsTab({ customerId, payments }: { customerId: string; payments: PaymentItem[] }) {
  const router = useRouter();

  const totalReceived = payments.filter(p => p.status === 'completed').reduce((s, p) => s + p.amount, 0);
  const totalPartial = payments.filter(p => p.status === 'partial').reduce((s, p) => s + p.amount, 0);

  function getPaymentMethodLabel(method: string): string {
    const map: Record<string, string> = {
      credit_card: 'Credit Card',
      ach: 'ACH Transfer',
      check: 'Check',
      cash: 'Cash',
      wire: 'Wire Transfer',
      stripe: 'Stripe',
      other: 'Other',
    };
    return map[method] || method;
  }

  function getPaymentMethodIcon(method: string) {
    if (method === 'credit_card' || method === 'stripe') return <CreditCard size={16} className="text-blue-500" />;
    if (method === 'ach') return <Building2 size={16} className="text-indigo-500" />;
    if (method === 'check') return <FileText size={16} className="text-amber-500" />;
    if (method === 'wire') return <Zap size={16} className="text-purple-500" />;
    return <DollarSign size={16} className="text-emerald-500" />;
  }

  function getPaymentStatusBadge(status: string) {
    const map: Record<string, { variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple'; label: string }> = {
      completed: { variant: 'success', label: 'Paid in Full' },
      partial: { variant: 'warning', label: 'Partial' },
      pending: { variant: 'warning', label: 'Pending' },
      failed: { variant: 'error', label: 'Failed' },
      refunded: { variant: 'info', label: 'Refunded' },
    };
    const cfg = map[status] || { variant: 'default' as const, label: status };
    return <Badge variant={cfg.variant}>{cfg.label}</Badge>;
  }

  return (
    <div className="space-y-4">
      {/* Payment summary cards */}
      <div className="grid grid-cols-2 gap-4">
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider">Total Received</p>
            <p className="text-xl font-semibold text-emerald-500 mt-1">{formatCurrency(totalReceived)}</p>
            <p className="text-xs text-muted">{payments.filter(p => p.status === 'completed').length} payments</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider">Partial Payments</p>
            <p className="text-xl font-semibold text-amber-500 mt-1">{formatCurrency(totalPartial)}</p>
            <p className="text-xs text-muted">{payments.filter(p => p.status === 'partial').length} partial</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-base">Payment History</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {payments.length === 0 ? (
            <div className="py-12 text-center">
              <CreditCard size={40} className="mx-auto text-muted mb-2 opacity-50" />
              <p className="text-muted">No payments recorded</p>
              <p className="text-xs text-muted mt-1">Payments appear here when invoices are paid</p>
            </div>
          ) : (
            <div className="divide-y divide-main">
              {payments.map((payment) => (
                <div
                  key={payment.id}
                  className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
                  onClick={() => router.push(`/dashboard/invoices/${payment.invoiceId}`)}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      {getPaymentMethodIcon(payment.method)}
                      <div>
                        <div className="flex items-center gap-2">
                          <p className="font-medium text-main">{formatCurrency(payment.amount)}</p>
                          {getPaymentStatusBadge(payment.status)}
                        </div>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-xs text-muted">{getPaymentMethodLabel(payment.method)}</span>
                          {payment.cardLast4 && (
                            <span className="text-xs text-muted">ending {payment.cardLast4}</span>
                          )}
                          <span className="text-xs text-muted">for {payment.invoiceNumber}</span>
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-main">{formatDate(payment.paidAt)}</p>
                      {payment.transactionId && (
                        <p className="text-xs text-muted font-mono">{payment.transactionId}</p>
                      )}
                    </div>
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

/** Notes tab — persists to the customer.notes text field in the database */
function NotesTab({ customerId, customerNotes, updateCustomer, refetch }: {
  customerId: string;
  customerNotes: string;
  updateCustomer: (id: string, data: Partial<Customer>) => Promise<void>;
  refetch: () => void;
}) {
  const { t } = useTranslation();
  const [noteText, setNoteText] = useState(customerNotes);
  const [isEditing, setIsEditing] = useState(false);
  const [saving, setSaving] = useState(false);

  // Sync if customer data refreshes from outside
  useEffect(() => {
    if (!isEditing) {
      setNoteText(customerNotes);
    }
  }, [customerNotes, isEditing]);

  const handleSave = async () => {
    try {
      setSaving(true);
      await updateCustomer(customerId, { notes: noteText.trim() || undefined });
      setIsEditing(false);
      refetch();
    } catch {
      // silent
    } finally {
      setSaving(false);
    }
  };

  const handleCancel = () => {
    setNoteText(customerNotes);
    setIsEditing(false);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-medium text-main">Customer Notes</h3>
        {!isEditing && (
          <Button variant="secondary" size="sm" onClick={() => setIsEditing(true)}>
            <Edit size={14} />
            {noteText ? 'Edit Notes' : 'Add Notes'}
          </Button>
        )}
      </div>

      {isEditing ? (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-base">{noteText ? 'Edit Notes' : 'Add Notes'}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <textarea
              value={noteText}
              onChange={(e) => setNoteText(e.target.value)}
              placeholder="Write notes about this customer — preferences, site access details, follow-up reminders..."
              rows={8}
              className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50 resize-y"
              autoFocus
            />
            <div className="flex items-center justify-end gap-2">
              <Button variant="ghost" size="sm" onClick={handleCancel}>
                {t('common.cancel')}
              </Button>
              <Button size="sm" onClick={handleSave} disabled={saving}>
                {saving ? 'Saving...' : 'Save Notes'}
              </Button>
            </div>
          </CardContent>
        </Card>
      ) : noteText ? (
        <Card>
          <CardContent className="p-4">
            <p className="text-sm text-main whitespace-pre-wrap">{noteText}</p>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="py-12 text-center">
            <StickyNote size={40} className="mx-auto text-muted mb-2 opacity-50" />
            <p className="text-muted">No notes yet</p>
            <p className="text-xs text-muted mt-1">Add notes to keep track of important customer details</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
