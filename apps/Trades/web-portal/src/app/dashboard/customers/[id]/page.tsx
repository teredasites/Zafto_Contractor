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
  Heart,
  X,
  Copy,
  ExternalLink,
  Shield,
  UserPlus,
  Merge,
  Send,
  Activity,
  ChevronRight,
  CheckCircle,
  Home,
  CreditCard,
  StickyNote,
  PhoneCall,
  PhoneIncoming,
  PhoneOutgoing,
  Building2,
  Droplets,
  Zap,
  Thermometer,
  Gauge,
  TreePine,
  Search,
  Filter,
  Download,
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
import { Input, Select } from '@/components/ui/input';
import { isValidEmail, isValidPhone, formatPhone } from '@/lib/validation';
import { getSupabase } from '@/lib/supabase';
import { EntityDocumentsPanel } from '@/components/entity-documents-panel';
import { CommandPalette } from '@/components/command-palette';
import type { Customer } from '@/types';
import { useTranslation } from '@/lib/translations';

type TabType = 'overview' | 'bids' | 'jobs' | 'invoices' | 'documents' | 'activity' | 'estimates' | 'communications' | 'properties' | 'payments' | 'notes';

// ---------------------------------------------------------------------------
// Demo data interfaces for new tabs (will be replaced by real hooks)
// ---------------------------------------------------------------------------

interface EstimateItem {
  id: string;
  estimateNumber: string;
  title: string;
  description: string;
  status: 'draft' | 'sent' | 'viewed' | 'accepted' | 'declined' | 'expired';
  total: number;
  createdAt: string;
  expiresAt: string;
  lineItemCount: number;
  jobType: string;
}

interface CommunicationItem {
  id: string;
  type: 'call' | 'email' | 'sms';
  direction: 'inbound' | 'outbound';
  subject: string;
  preview: string;
  timestamp: string;
  duration?: number; // seconds, for calls
  status: 'completed' | 'missed' | 'sent' | 'delivered' | 'read' | 'bounced' | 'failed';
  assignedTo?: string;
}

interface PropertyItem {
  id: string;
  address: string;
  city: string;
  state: string;
  zip: string;
  propertyType: 'residential' | 'commercial' | 'industrial';
  yearBuilt: number;
  sqft: number;
  lastScanDate?: string;
  conditions: PropertyCondition[];
  jobCount: number;
}

interface PropertyCondition {
  area: string;
  severity: 'good' | 'fair' | 'poor' | 'critical';
  note: string;
}

interface PaymentItem {
  id: string;
  invoiceId: string;
  invoiceNumber: string;
  amount: number;
  method: 'credit_card' | 'ach' | 'check' | 'cash' | 'wire';
  status: 'completed' | 'pending' | 'failed' | 'refunded';
  paidAt: string;
  transactionId?: string;
  cardLast4?: string;
}

interface NoteItem {
  id: string;
  content: string;
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  isPinned: boolean;
  category: 'general' | 'follow-up' | 'issue' | 'preference' | 'site-access';
}

// ---------------------------------------------------------------------------
// Demo data generators
// ---------------------------------------------------------------------------

function getDemoEstimates(customerId: string): EstimateItem[] {
  return [
    {
      id: 'est-001',
      estimateNumber: 'EST-2026-0147',
      title: 'Full Kitchen Remodel',
      description: 'Complete kitchen renovation including cabinets, countertops, backsplash, and flooring',
      status: 'accepted',
      total: 28750.00,
      createdAt: '2026-01-15T10:30:00Z',
      expiresAt: '2026-02-15T10:30:00Z',
      lineItemCount: 18,
      jobType: 'Remodel',
    },
    {
      id: 'est-002',
      estimateNumber: 'EST-2026-0163',
      title: 'Bathroom Tile & Fixture Replacement',
      description: 'Master bath tile replacement, new vanity, toilet, and shower fixtures',
      status: 'sent',
      total: 9450.00,
      createdAt: '2026-02-01T14:15:00Z',
      expiresAt: '2026-03-01T14:15:00Z',
      lineItemCount: 12,
      jobType: 'Renovation',
    },
    {
      id: 'est-003',
      estimateNumber: 'EST-2026-0178',
      title: 'Deck Repair & Staining',
      description: 'Repair damaged deck boards, replace railing sections, sand and restain entire deck',
      status: 'draft',
      total: 4200.00,
      createdAt: '2026-02-10T09:00:00Z',
      expiresAt: '2026-03-10T09:00:00Z',
      lineItemCount: 7,
      jobType: 'Repair',
    },
    {
      id: 'est-004',
      estimateNumber: 'EST-2025-0892',
      title: 'Exterior Paint — Full House',
      description: 'Pressure wash, scrape, prime, and paint exterior of 2-story colonial',
      status: 'expired',
      total: 12600.00,
      createdAt: '2025-09-20T11:00:00Z',
      expiresAt: '2025-10-20T11:00:00Z',
      lineItemCount: 9,
      jobType: 'Painting',
    },
    {
      id: 'est-005',
      estimateNumber: 'EST-2025-0910',
      title: 'HVAC System Replacement',
      description: 'Remove existing 15-year-old furnace and AC, install new high-efficiency system with smart thermostat',
      status: 'declined',
      total: 18900.00,
      createdAt: '2025-10-05T08:45:00Z',
      expiresAt: '2025-11-05T08:45:00Z',
      lineItemCount: 14,
      jobType: 'HVAC',
    },
  ];
}

function getDemoCommunications(customerId: string): CommunicationItem[] {
  return [
    {
      id: 'comm-001',
      type: 'call',
      direction: 'outbound',
      subject: 'Kitchen remodel scheduling',
      preview: 'Discussed start date options for the kitchen remodel project. Customer prefers mid-February start.',
      timestamp: '2026-02-20T15:30:00Z',
      duration: 480,
      status: 'completed',
      assignedTo: 'Mike Torres',
    },
    {
      id: 'comm-002',
      type: 'email',
      direction: 'outbound',
      subject: 'Estimate #EST-2026-0163 — Bathroom Renovation',
      preview: 'Hi, please find attached the estimate for your master bathroom tile and fixture replacement project...',
      timestamp: '2026-02-01T14:20:00Z',
      status: 'read',
      assignedTo: 'Mike Torres',
    },
    {
      id: 'comm-003',
      type: 'sms',
      direction: 'inbound',
      subject: 'Appointment confirmation',
      preview: 'Yes, Thursday at 9am works for us. The side gate code is 4521.',
      timestamp: '2026-02-18T08:12:00Z',
      status: 'delivered',
    },
    {
      id: 'comm-004',
      type: 'call',
      direction: 'inbound',
      subject: 'Warranty question',
      preview: 'Customer called about warranty coverage on last year\'s roof repair. Confirmed 5-year material warranty.',
      timestamp: '2026-02-10T11:00:00Z',
      duration: 300,
      status: 'completed',
      assignedTo: 'Sarah Kim',
    },
    {
      id: 'comm-005',
      type: 'email',
      direction: 'outbound',
      subject: 'Invoice #INV-2026-0089 — Payment Received',
      preview: 'Thank you for your payment of $14,375.00. This confirms the first 50% deposit for your kitchen remodel...',
      timestamp: '2026-01-28T10:00:00Z',
      status: 'read',
    },
    {
      id: 'comm-006',
      type: 'sms',
      direction: 'outbound',
      subject: 'Crew arrival notification',
      preview: 'Hi! Our crew (Jake + Luis) will arrive at 7:30am tomorrow for the demo day. Please make sure all items are cleared from kitchen counters.',
      timestamp: '2026-02-16T16:45:00Z',
      status: 'delivered',
    },
    {
      id: 'comm-007',
      type: 'call',
      direction: 'outbound',
      subject: 'Follow-up on deck estimate',
      preview: 'Left voicemail regarding the deck repair estimate. Customer hasn\'t responded to the proposal sent 2/10.',
      timestamp: '2026-02-22T09:30:00Z',
      duration: 45,
      status: 'missed',
      assignedTo: 'Mike Torres',
    },
    {
      id: 'comm-008',
      type: 'email',
      direction: 'inbound',
      subject: 'RE: Deck Repair & Staining Estimate',
      preview: 'Mike — we reviewed the estimate and have a few questions about the composite vs. wood option for the replacement boards...',
      timestamp: '2026-02-23T13:15:00Z',
      status: 'read',
    },
  ];
}

function getDemoProperties(customerId: string): PropertyItem[] {
  return [
    {
      id: 'prop-001',
      address: '1847 Oakridge Drive',
      city: 'Cedar Park',
      state: 'TX',
      zip: '78613',
      propertyType: 'residential',
      yearBuilt: 2004,
      sqft: 2850,
      lastScanDate: '2026-01-12T10:00:00Z',
      conditions: [
        { area: 'Roof', severity: 'fair', note: 'Some granule loss on south-facing slope, estimated 5-7 years remaining' },
        { area: 'Foundation', severity: 'good', note: 'No visible cracks, proper drainage grade observed' },
        { area: 'Exterior Siding', severity: 'poor', note: 'Faded paint, peeling on north and west facades, caulk deterioration around windows' },
        { area: 'Deck', severity: 'critical', note: '3 warped boards, 2 loose railing posts, surface splintering throughout' },
        { area: 'HVAC', severity: 'fair', note: 'Unit is 15 years old, running but efficiency is down 20% from baseline' },
      ],
      jobCount: 4,
    },
    {
      id: 'prop-002',
      address: '320 Commerce Blvd, Suite 100',
      city: 'Round Rock',
      state: 'TX',
      zip: '78664',
      propertyType: 'commercial',
      yearBuilt: 2012,
      sqft: 5200,
      lastScanDate: '2025-11-08T14:00:00Z',
      conditions: [
        { area: 'Roof (Flat TPO)', severity: 'good', note: 'Membrane intact, no ponding observed, seams solid' },
        { area: 'Parking Lot', severity: 'fair', note: 'Minor cracking in northwest corner, seal coat recommended within 12 months' },
        { area: 'Interior Plumbing', severity: 'poor', note: 'Restroom fixtures aged, supply lines showing corrosion, recommend replacement' },
      ],
      jobCount: 1,
    },
  ];
}

function getDemoPayments(customerId: string): PaymentItem[] {
  return [
    {
      id: 'pay-001',
      invoiceId: 'inv-089',
      invoiceNumber: 'INV-2026-0089',
      amount: 14375.00,
      method: 'credit_card',
      status: 'completed',
      paidAt: '2026-01-28T09:45:00Z',
      transactionId: 'ch_3Nk2pJ4f8sR7xY',
      cardLast4: '4242',
    },
    {
      id: 'pay-002',
      invoiceId: 'inv-072',
      invoiceNumber: 'INV-2025-0072',
      amount: 6300.00,
      method: 'ach',
      status: 'completed',
      paidAt: '2025-11-15T14:20:00Z',
      transactionId: 'bt_7Hm3qK5g9tS8zA',
    },
    {
      id: 'pay-003',
      invoiceId: 'inv-072',
      invoiceNumber: 'INV-2025-0072',
      amount: 6300.00,
      method: 'ach',
      status: 'completed',
      paidAt: '2025-12-01T10:00:00Z',
      transactionId: 'bt_9Jn4rL6h0uT9aB',
    },
    {
      id: 'pay-004',
      invoiceId: 'inv-055',
      invoiceNumber: 'INV-2025-0055',
      amount: 3150.00,
      method: 'check',
      status: 'completed',
      paidAt: '2025-08-22T11:30:00Z',
    },
    {
      id: 'pay-005',
      invoiceId: 'inv-089',
      invoiceNumber: 'INV-2026-0089',
      amount: 14375.00,
      method: 'credit_card',
      status: 'pending',
      paidAt: '2026-02-20T00:00:00Z',
      transactionId: 'ch_4Ol3qK5g9tS8zA',
      cardLast4: '4242',
    },
    {
      id: 'pay-006',
      invoiceId: 'inv-041',
      invoiceNumber: 'INV-2025-0041',
      amount: 1800.00,
      method: 'cash',
      status: 'completed',
      paidAt: '2025-06-10T08:00:00Z',
    },
  ];
}

function getDemoNotes(customerId: string): NoteItem[] {
  return [
    {
      id: 'note-001',
      content: 'Customer prefers to be contacted after 4pm on weekdays. Works from home and has meetings until then. Best to call cell, not home phone.',
      createdAt: '2026-01-10T16:00:00Z',
      updatedAt: '2026-01-10T16:00:00Z',
      createdBy: 'Mike Torres',
      isPinned: true,
      category: 'preference',
    },
    {
      id: 'note-002',
      content: 'Side gate code is 4521. Dogs are friendly but loud — ring doorbell first so they can put them in the backyard. Park on the street, not driveway (fresh seal coat).',
      createdAt: '2026-01-12T10:30:00Z',
      updatedAt: '2026-02-18T08:15:00Z',
      createdBy: 'Jake Moreno',
      isPinned: true,
      category: 'site-access',
    },
    {
      id: 'note-003',
      content: 'Follow up in March about the deck repair estimate. Customer said they want to wait until after their daughter\'s outdoor birthday party on 3/8.',
      createdAt: '2026-02-22T09:45:00Z',
      updatedAt: '2026-02-22T09:45:00Z',
      createdBy: 'Mike Torres',
      isPinned: false,
      category: 'follow-up',
    },
    {
      id: 'note-004',
      content: 'Customer mentioned water staining on the ceiling in the master bedroom during walkthrough. Could indicate a slow roof leak. Worth a closer inspection when crew is on-site for kitchen work.',
      createdAt: '2026-01-15T11:20:00Z',
      updatedAt: '2026-01-15T11:20:00Z',
      createdBy: 'Sarah Kim',
      isPinned: false,
      category: 'issue',
    },
    {
      id: 'note-005',
      content: 'Great referral source — sent us the Henderson family for their bathroom remodel. Consider adding to the referral rewards program.',
      createdAt: '2025-12-05T14:00:00Z',
      updatedAt: '2025-12-05T14:00:00Z',
      createdBy: 'Mike Torres',
      isPinned: false,
      category: 'general',
    },
  ];
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

  const customerBids = bids.filter((b) => b.customerId === customerId);
  const customerJobs = jobs.filter((j) => j.customerId === customerId);
  const customerInvoices = invoices.filter((i) => i.customerId === customerId);

  // Demo data counts for new tabs
  const demoEstimates = getDemoEstimates(customerId);
  const demoCommunications = getDemoCommunications(customerId);
  const demoProperties = getDemoProperties(customerId);
  const demoPayments = getDemoPayments(customerId);
  const demoNotes = getDemoNotes(customerId);

  const tabs: { id: TabType; label: string; count: number }[] = [
    { id: 'overview', label: 'Overview', count: 0 },
    { id: 'bids', label: 'Bids', count: customerBids.length },
    { id: 'estimates', label: 'Estimates', count: demoEstimates.length },
    { id: 'jobs', label: 'Jobs', count: customerJobs.length },
    { id: 'invoices', label: 'Invoices', count: customerInvoices.length },
    { id: 'payments', label: 'Payments', count: demoPayments.length },
    { id: 'properties', label: 'Properties', count: demoProperties.length },
    { id: 'communications', label: 'Comms', count: demoCommunications.length },
    { id: 'documents', label: 'Documents', count: 0 },
    { id: 'notes', label: 'Notes', count: demoNotes.length },
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
          {activeTab === 'estimates' && <EstimatesTab customerId={customerId} estimates={demoEstimates} />}
          {activeTab === 'jobs' && <JobsTab jobs={customerJobs} />}
          {activeTab === 'invoices' && <InvoicesTab invoices={customerInvoices} />}
          {activeTab === 'payments' && <PaymentsTab customerId={customerId} payments={demoPayments} />}
          {activeTab === 'properties' && <PropertiesTab customerId={customerId} properties={demoProperties} />}
          {activeTab === 'communications' && <CommunicationsTab customerId={customerId} communications={demoCommunications} />}
          {activeTab === 'documents' && <DocumentsTab customerId={customerId} />}
          {activeTab === 'notes' && <NotesTab customerId={customerId} notes={demoNotes} />}
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
              <div className="w-full h-2 bg-zinc-800 rounded-full overflow-hidden">
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

/** Estimates tab — shows all estimates for this customer */
function EstimatesTab({ customerId, estimates }: { customerId: string; estimates: EstimateItem[] }) {
  const { t } = useTranslation();
  const router = useRouter();
  const [filterStatus, setFilterStatus] = useState<string>('all');

  const filtered = filterStatus === 'all' ? estimates : estimates.filter(e => e.status === filterStatus);

  const totalPipeline = estimates.filter(e => e.status === 'sent' || e.status === 'viewed').reduce((s, e) => s + e.total, 0);
  const totalAccepted = estimates.filter(e => e.status === 'accepted').reduce((s, e) => s + e.total, 0);
  const conversionRate = estimates.length > 0
    ? Math.round((estimates.filter(e => e.status === 'accepted').length / estimates.length) * 100)
    : 0;

  function getEstimateStatusBadge(status: EstimateItem['status']) {
    const map: Record<EstimateItem['status'], { variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple'; label: string }> = {
      draft: { variant: 'secondary', label: 'Draft' },
      sent: { variant: 'info', label: 'Sent' },
      viewed: { variant: 'purple', label: 'Viewed' },
      accepted: { variant: 'success', label: 'Accepted' },
      declined: { variant: 'error', label: 'Declined' },
      expired: { variant: 'warning', label: 'Expired' },
    };
    const cfg = map[status];
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
            <p className="text-xs text-muted">{estimates.filter(e => e.status === 'sent' || e.status === 'viewed').length} open estimates</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider">Won</p>
            <p className="text-xl font-semibold text-emerald-500 mt-1">{formatCurrency(totalAccepted)}</p>
            <p className="text-xs text-muted">{estimates.filter(e => e.status === 'accepted').length} accepted</p>
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
              <option value="viewed">Viewed</option>
              <option value="accepted">Accepted</option>
              <option value="declined">Declined</option>
              <option value="expired">Expired</option>
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
                        <p className="font-medium text-main">{est.title}</p>
                        <span className="text-xs text-muted">{est.estimateNumber}</span>
                      </div>
                      <p className="text-sm text-muted mt-0.5 truncate">{est.description}</p>
                      <div className="flex items-center gap-3 mt-1">
                        <span className="text-xs text-muted">{est.lineItemCount} line items</span>
                        <span className="text-xs text-muted">{est.jobType}</span>
                        <span className="text-xs text-muted">Created {formatDate(est.createdAt)}</span>
                      </div>
                    </div>
                    <div className="flex items-center gap-3 ml-4">
                      <span className="font-semibold text-main">{formatCurrency(est.total)}</span>
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
function CommunicationsTab({ customerId, communications }: { customerId: string; communications: CommunicationItem[] }) {
  const { t } = useTranslation();
  const [filterType, setFilterType] = useState<string>('all');

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

  function getCommStatusBadge(status: CommunicationItem['status']) {
    const map: Record<CommunicationItem['status'], { variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple'; label: string }> = {
      completed: { variant: 'success', label: 'Completed' },
      missed: { variant: 'error', label: 'Missed' },
      sent: { variant: 'info', label: 'Sent' },
      delivered: { variant: 'success', label: 'Delivered' },
      read: { variant: 'purple', label: 'Read' },
      bounced: { variant: 'error', label: 'Bounced' },
      failed: { variant: 'error', label: 'Failed' },
    };
    const cfg = map[status];
    return <Badge variant={cfg.variant}>{cfg.label}</Badge>;
  }

  function formatDuration(seconds: number): string {
    if (seconds < 60) return `${seconds}s`;
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return secs > 0 ? `${mins}m ${secs}s` : `${mins}m`;
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
                      <p className="text-sm text-muted mt-1">{comm.preview}</p>
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

/** Properties tab — linked properties with condition data */
function PropertiesTab({ customerId, properties }: { customerId: string; properties: PropertyItem[] }) {
  const { t } = useTranslation();
  const router = useRouter();

  function getSeverityBadge(severity: PropertyCondition['severity']) {
    const map: Record<PropertyCondition['severity'], { variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple'; label: string }> = {
      good: { variant: 'success', label: 'Good' },
      fair: { variant: 'warning', label: 'Fair' },
      poor: { variant: 'error', label: 'Poor' },
      critical: { variant: 'error', label: 'Critical' },
    };
    const cfg = map[severity];
    return <Badge variant={cfg.variant}>{cfg.label}</Badge>;
  }

  function getPropertyTypeIcon(type: PropertyItem['propertyType']) {
    if (type === 'commercial') return <Building2 size={18} className="text-blue-500" />;
    if (type === 'industrial') return <Zap size={18} className="text-amber-500" />;
    return <Home size={18} className="text-indigo-500" />;
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-medium text-main">Linked Properties ({properties.length})</h3>
        <Button variant="secondary" size="sm">
          <Plus size={14} />
          Link Property
        </Button>
      </div>

      {properties.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <Home size={40} className="mx-auto text-muted mb-2 opacity-50" />
            <p className="text-muted">No properties linked to this customer</p>
            <p className="text-xs text-muted mt-1">Link a property to track conditions and scan data</p>
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
                      <span className="text-xs text-muted">Built {prop.yearBuilt}</span>
                      <span className="text-xs text-muted">{prop.sqft.toLocaleString()} sq ft</span>
                      <Badge variant="default" className="capitalize">{prop.propertyType}</Badge>
                      <span className="text-xs text-muted">{prop.jobCount} jobs</span>
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
            <CardContent className="pt-0">
              {prop.conditions.length > 0 && (
                <div className="space-y-2">
                  <p className="text-xs font-medium text-muted uppercase tracking-wider">Condition Report</p>
                  <div className="space-y-2">
                    {prop.conditions.map((cond, idx) => (
                      <div key={idx} className="flex items-start gap-3 p-2 bg-secondary rounded-lg">
                        <div className="min-w-[100px]">
                          <p className="text-sm font-medium text-main">{cond.area}</p>
                          {getSeverityBadge(cond.severity)}
                        </div>
                        <p className="text-sm text-muted flex-1">{cond.note}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        ))
      )}
    </div>
  );
}

/** Payments tab — payment history across all invoices */
function PaymentsTab({ customerId, payments }: { customerId: string; payments: PaymentItem[] }) {
  const { t } = useTranslation();
  const router = useRouter();

  const totalReceived = payments.filter(p => p.status === 'completed').reduce((s, p) => s + p.amount, 0);
  const totalPending = payments.filter(p => p.status === 'pending').reduce((s, p) => s + p.amount, 0);
  const totalRefunded = payments.filter(p => p.status === 'refunded').reduce((s, p) => s + p.amount, 0);

  function getPaymentMethodLabel(method: PaymentItem['method']): string {
    const map: Record<PaymentItem['method'], string> = {
      credit_card: 'Credit Card',
      ach: 'ACH Transfer',
      check: 'Check',
      cash: 'Cash',
      wire: 'Wire Transfer',
    };
    return map[method];
  }

  function getPaymentMethodIcon(method: PaymentItem['method']) {
    if (method === 'credit_card') return <CreditCard size={16} className="text-blue-500" />;
    if (method === 'ach') return <Building2 size={16} className="text-indigo-500" />;
    if (method === 'check') return <FileText size={16} className="text-amber-500" />;
    if (method === 'wire') return <Zap size={16} className="text-purple-500" />;
    return <DollarSign size={16} className="text-emerald-500" />;
  }

  function getPaymentStatusBadge(status: PaymentItem['status']) {
    const map: Record<PaymentItem['status'], { variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple'; label: string }> = {
      completed: { variant: 'success', label: 'Completed' },
      pending: { variant: 'warning', label: 'Pending' },
      failed: { variant: 'error', label: 'Failed' },
      refunded: { variant: 'info', label: 'Refunded' },
    };
    const cfg = map[status];
    return <Badge variant={cfg.variant}>{cfg.label}</Badge>;
  }

  return (
    <div className="space-y-4">
      {/* Payment summary cards */}
      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider">Total Received</p>
            <p className="text-xl font-semibold text-emerald-500 mt-1">{formatCurrency(totalReceived)}</p>
            <p className="text-xs text-muted">{payments.filter(p => p.status === 'completed').length} payments</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider">Pending</p>
            <p className="text-xl font-semibold text-amber-500 mt-1">{formatCurrency(totalPending)}</p>
            <p className="text-xs text-muted">{payments.filter(p => p.status === 'pending').length} pending</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider">Refunded</p>
            <p className="text-xl font-semibold text-blue-500 mt-1">{formatCurrency(totalRefunded)}</p>
            <p className="text-xs text-muted">{payments.filter(p => p.status === 'refunded').length} refunds</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-base">Payment History</CardTitle>
          <Button variant="secondary" size="sm">
            <Download size={14} />
            Export
          </Button>
        </CardHeader>
        <CardContent className="p-0">
          {payments.length === 0 ? (
            <div className="py-12 text-center">
              <CreditCard size={40} className="mx-auto text-muted mb-2 opacity-50" />
              <p className="text-muted">No payments recorded</p>
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

/** Notes tab — customer notes with add note functionality */
function NotesTab({ customerId, notes: initialNotes }: { customerId: string; notes: NoteItem[] }) {
  const { t } = useTranslation();
  const [notes, setNotes] = useState<NoteItem[]>(initialNotes);
  const [newNoteContent, setNewNoteContent] = useState('');
  const [newNoteCategory, setNewNoteCategory] = useState<NoteItem['category']>('general');
  const [showAddForm, setShowAddForm] = useState(false);
  const [filterCategory, setFilterCategory] = useState<string>('all');

  const pinnedNotes = notes.filter(n => n.isPinned);
  const unpinnedNotes = notes.filter(n => !n.isPinned);

  const filteredNotes = filterCategory === 'all'
    ? [...pinnedNotes, ...unpinnedNotes]
    : [...pinnedNotes.filter(n => n.category === filterCategory), ...unpinnedNotes.filter(n => n.category === filterCategory)];

  const handleAddNote = () => {
    if (!newNoteContent.trim()) return;
    const newNote: NoteItem = {
      id: `note-${Date.now()}`,
      content: newNoteContent.trim(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      createdBy: 'You',
      isPinned: false,
      category: newNoteCategory,
    };
    setNotes([newNote, ...notes]);
    setNewNoteContent('');
    setNewNoteCategory('general');
    setShowAddForm(false);
  };

  const togglePin = (noteId: string) => {
    setNotes(notes.map(n => n.id === noteId ? { ...n, isPinned: !n.isPinned } : n));
  };

  const deleteNote = (noteId: string) => {
    setNotes(notes.filter(n => n.id !== noteId));
  };

  function getCategoryBadge(category: NoteItem['category']) {
    const map: Record<NoteItem['category'], { variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple'; label: string }> = {
      general: { variant: 'default', label: 'General' },
      'follow-up': { variant: 'info', label: 'Follow-up' },
      issue: { variant: 'error', label: 'Issue' },
      preference: { variant: 'purple', label: 'Preference' },
      'site-access': { variant: 'warning', label: 'Site Access' },
    };
    const cfg = map[category];
    return <Badge variant={cfg.variant}>{cfg.label}</Badge>;
  }

  return (
    <div className="space-y-4">
      {/* Add note button / form */}
      {!showAddForm ? (
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <select
              value={filterCategory}
              onChange={(e) => setFilterCategory(e.target.value)}
              className="text-xs bg-secondary border border-main rounded-md px-2 py-1 text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
            >
              <option value="all">All Categories</option>
              <option value="general">General</option>
              <option value="follow-up">Follow-up</option>
              <option value="issue">Issue</option>
              <option value="preference">Preference</option>
              <option value="site-access">Site Access</option>
            </select>
          </div>
          <Button variant="secondary" size="sm" onClick={() => setShowAddForm(true)}>
            <Plus size={14} />
            Add Note
          </Button>
        </div>
      ) : (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-base">New Note</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <textarea
              value={newNoteContent}
              onChange={(e) => setNewNoteContent(e.target.value)}
              placeholder="Write a note about this customer..."
              rows={4}
              className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50 resize-none"
              autoFocus
            />
            <div className="flex items-center justify-between">
              <select
                value={newNoteCategory}
                onChange={(e) => setNewNoteCategory(e.target.value as NoteItem['category'])}
                className="text-xs bg-secondary border border-main rounded-md px-2 py-1 text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
              >
                <option value="general">General</option>
                <option value="follow-up">Follow-up</option>
                <option value="issue">Issue</option>
                <option value="preference">Preference</option>
                <option value="site-access">Site Access</option>
              </select>
              <div className="flex items-center gap-2">
                <Button variant="ghost" size="sm" onClick={() => { setShowAddForm(false); setNewNoteContent(''); }}>
                  {t('common.cancel')}
                </Button>
                <Button size="sm" onClick={handleAddNote} disabled={!newNoteContent.trim()}>
                  Save Note
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Notes list */}
      {filteredNotes.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <StickyNote size={40} className="mx-auto text-muted mb-2 opacity-50" />
            <p className="text-muted">No notes yet</p>
            <p className="text-xs text-muted mt-1">Add notes to keep track of important customer details</p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {filteredNotes.map((note) => (
            <Card key={note.id} className={cn(note.isPinned && 'border-amber-500/30')}>
              <CardContent className="p-4">
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1 min-w-0">
                    {note.isPinned && (
                      <div className="flex items-center gap-1 mb-1">
                        <Tag size={12} className="text-amber-500" />
                        <span className="text-xs font-medium text-amber-500">Pinned</span>
                      </div>
                    )}
                    <p className="text-sm text-main whitespace-pre-wrap">{note.content}</p>
                    <div className="flex items-center gap-3 mt-2">
                      {getCategoryBadge(note.category)}
                      <span className="text-xs text-muted">
                        <User size={10} className="inline mr-1" />
                        {note.createdBy}
                      </span>
                      <span className="text-xs text-muted">{formatDate(note.createdAt)}</span>
                      {note.updatedAt !== note.createdAt && (
                        <span className="text-xs text-muted">(edited)</span>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-1 flex-shrink-0">
                    <button
                      onClick={() => togglePin(note.id)}
                      className={cn(
                        'p-1.5 rounded-md transition-colors',
                        note.isPinned
                          ? 'text-amber-500 bg-amber-500/10 hover:bg-amber-500/20'
                          : 'text-muted hover:text-main hover:bg-surface-hover'
                      )}
                      title={note.isPinned ? 'Unpin note' : 'Pin note'}
                    >
                      <Tag size={14} />
                    </button>
                    <button
                      onClick={() => deleteNote(note.id)}
                      className="p-1.5 rounded-md text-muted hover:text-red-500 hover:bg-red-500/10 transition-colors"
                      title="Delete note"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
