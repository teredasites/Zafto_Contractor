'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import {
  ArrowLeft,
  Send,
  FileText,
  Download,
  Copy,
  Trash2,
  Edit,
  CheckCircle,
  XCircle,
  Clock,
  Eye,
  Mail,
  Phone,
  MapPin,
  Calendar,
  DollarSign,
  User,
  PenTool,
  Briefcase,
  MoreHorizontal,
  ExternalLink,
  Star,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge, Badge } from '@/components/ui/badge';
import { formatCurrency, formatDate, formatDateTime, cn, getStatusColor } from '@/lib/utils';
import { useBid, useBids } from '@/lib/hooks/use-bids';
import { getSupabase } from '@/lib/supabase';
import type { Bid, BidOption } from '@/types';
import { useTranslation } from '@/lib/translations';

// Timeline event type
interface TimelineEvent {
  id: string;
  type: 'created' | 'sent' | 'viewed' | 'accepted' | 'rejected' | 'signed' | 'deposit_paid' | 'converted';
  label: string;
  date?: Date;
  completed: boolean;
}

export default function BidDetailPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const bidId = params.id as string;

  const { bid, loading } = useBid(bidId);
  const { sendBid, deleteBid, convertToJob, createBid } = useBids();
  const [activeOptionIndex, setActiveOptionIndex] = useState(0);
  const [menuOpen, setMenuOpen] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  // Set active option when bid loads
  useEffect(() => {
    if (!bid) return;
    if (bid.selectedOptionId) {
      const idx = bid.options.findIndex((o) => o.id === bid.selectedOptionId);
      if (idx >= 0) setActiveOptionIndex(idx);
    } else {
      const recommendedIdx = bid.options.findIndex((o) => o.isRecommended);
      if (recommendedIdx >= 0) setActiveOptionIndex(recommendedIdx);
    }
  }, [bid]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (!bid) {
    return (
      <div className="text-center py-12">
        <FileText size={48} className="mx-auto text-muted mb-4" />
        <h2 className="text-xl font-semibold text-main">{t('bids.bidNotFound')}</h2>
        <p className="text-muted mt-2">The bid you're looking for doesn't exist.</p>
        <Button variant="secondary" className="mt-4" onClick={() => router.push('/dashboard/bids')}>
          Back to Bids
        </Button>
      </div>
    );
  }

  const activeOption = bid.options[activeOptionIndex];
  const selectedAddOns = bid.addOns.filter((a) => bid.selectedAddOnIds.includes(a.id));
  const addOnsTotal = selectedAddOns.reduce((sum, a) => sum + a.price, 0);
  const grandTotal = (activeOption?.subtotal || 0) + addOnsTotal + bid.tax;

  // Build timeline
  const timeline: TimelineEvent[] = [
    { id: '1', type: 'created', label: 'Bid Created', date: bid.createdAt, completed: true },
    { id: '2', type: 'sent', label: 'Sent to Customer', date: bid.sentAt, completed: !!bid.sentAt },
    { id: '3', type: 'viewed', label: 'Viewed by Customer', date: bid.viewedAt, completed: !!bid.viewedAt },
    {
      id: '4',
      type: bid.status === 'rejected' ? 'rejected' : 'accepted',
      label: bid.status === 'rejected' ? 'Declined' : 'Accepted',
      date: bid.status === 'accepted' || bid.status === 'rejected' ? bid.updatedAt : undefined,
      completed: bid.status === 'accepted' || bid.status === 'rejected',
    },
    { id: '5', type: 'signed', label: 'Contract Signed', date: bid.signedAt, completed: !!bid.signedAt },
    { id: '6', type: 'deposit_paid', label: 'Deposit Paid', completed: bid.depositPaid },
    { id: '7', type: 'converted', label: 'Converted to Job', completed: bid.status === 'converted' },
  ];

  const getTimelineIcon = (type: TimelineEvent['type'], completed: boolean) => {
    const iconClass = completed ? 'text-white' : 'text-muted';
    switch (type) {
      case 'created':
        return <FileText size={14} className={iconClass} />;
      case 'sent':
        return <Send size={14} className={iconClass} />;
      case 'viewed':
        return <Eye size={14} className={iconClass} />;
      case 'accepted':
        return <CheckCircle size={14} className={iconClass} />;
      case 'rejected':
        return <XCircle size={14} className={iconClass} />;
      case 'signed':
        return <PenTool size={14} className={iconClass} />;
      case 'deposit_paid':
        return <DollarSign size={14} className={iconClass} />;
      case 'converted':
        return <Briefcase size={14} className={iconClass} />;
      default:
        return <Clock size={14} className={iconClass} />;
    }
  };

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
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-semibold text-main">{bid.title}</h1>
              <StatusBadge status={bid.status} />
              {bid.depositPaid && (
                <Badge variant="success" size="sm">Deposit Paid</Badge>
              )}
            </div>
            <p className="text-muted mt-1">
              {bid.customer?.firstName} {bid.customer?.lastName}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {bid.status === 'draft' && (
            <>
              <Button variant="secondary" onClick={() => router.push(`/dashboard/bids/${bid.id}/edit`)}>
                <Edit size={16} />
                Edit
              </Button>
              <Button disabled={actionLoading} onClick={async () => {
                if (!bid.customerEmail) { alert('No customer email on file. Please add an email address first.'); return; }
                if (!confirm(`Send bid to ${bid.customerEmail}?`)) return;
                setActionLoading(true);
                try {
                  // Generate PDF HTML
                  const supabase = getSupabase();
                  const { data: { session } } = await supabase.auth.getSession();
                  if (!session) throw new Error('Not authenticated');
                  const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
                  const pdfRes = await fetch(`${baseUrl}/functions/v1/export-bid-pdf?bid_id=${bid.id}`, {
                    headers: { 'Authorization': `Bearer ${session.access_token}`, 'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '' },
                  });
                  const pdfHtml = pdfRes.ok ? await pdfRes.text() : '';
                  // Send email via sendgrid-email EF
                  await supabase.functions.invoke('sendgrid-email', {
                    body: {
                      action: 'send',
                      to_email: bid.customerEmail,
                      to_name: bid.customerName || '',
                      subject: `Bid ${bid.bidNumber || ''}: ${bid.title || 'Your Bid'}`,
                      body_html: pdfHtml || `<p>Please find your bid attached. View it online at: ${window.location.origin}/portal/bids/${bid.id}</p>`,
                      email_type: 'bid_send',
                      related_type: 'bid',
                      related_id: bid.id,
                    },
                  });
                  await sendBid(bid.id);
                  window.location.reload();
                } catch (e) { alert(e instanceof Error ? e.message : 'Failed to send'); }
                setActionLoading(false);
              }}>
                <Send size={16} />
                Send to Customer
              </Button>
            </>
          )}
          {bid.status === 'accepted' && !bid.depositPaid && (
            <Button onClick={() => {
              router.push(`/dashboard/invoices/new?customer_id=${bid.customerId || ''}&bid_id=${bid.id}&type=deposit&amount=${Math.round((bid.total || 0) * 0.5)}`);
            }}>
              <DollarSign size={16} />
              Request Deposit
            </Button>
          )}
          {(bid.status === 'accepted' || bid.depositPaid) && bid.status !== 'converted' && (
            <Button disabled={actionLoading} onClick={async () => {
              if (!confirm('Convert this bid to a job?')) return;
              setActionLoading(true);
              try {
                const jobId = await convertToJob(bid.id);
                router.push(`/dashboard/jobs/${jobId}`);
              } catch (e) { alert(e instanceof Error ? e.message : 'Failed to convert'); setActionLoading(false); }
            }}>
              <Briefcase size={16} />
              Convert to Job
            </Button>
          )}
          <Button variant="secondary" onClick={async () => {
            try {
              setActionLoading(true);
              const newId = await createBid({
                customerId: bid.customerId || undefined,
                customerName: bid.customerName ? `${bid.customerName} (Copy)` : undefined,
                customerEmail: bid.customerEmail || undefined,
                title: `${bid.title} (Copy)`,
                scopeOfWork: bid.scopeOfWork || undefined,
                options: bid.options || [],
                addOns: bid.addOns || [],
                taxRate: bid.taxRate,
                tax: bid.tax,
                subtotal: bid.subtotal,
                total: bid.total,
                termsAndConditions: bid.termsAndConditions || undefined,
              });
              router.push(`/dashboard/bids/${newId}`);
            } catch (e) {
              alert(e instanceof Error ? e.message : 'Failed to duplicate');
            } finally {
              setActionLoading(false);
            }
          }}>
            <Copy size={16} />
            Duplicate
          </Button>
          <div className="relative">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setMenuOpen(!menuOpen)}
            >
              <MoreHorizontal size={18} />
            </Button>
            {menuOpen && (
              <div className="absolute right-0 top-full mt-1 w-48 bg-surface border border-main rounded-lg shadow-lg py-1 z-10">
                <button onClick={async () => {
                  setMenuOpen(false);
                  const supabase = getSupabase();
                  const { data: { session } } = await supabase.auth.getSession();
                  if (!session) return;
                  const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
                  const res = await fetch(`${baseUrl}/functions/v1/export-bid-pdf?bid_id=${bid.id}`, {
                    headers: {
                      'Authorization': `Bearer ${session.access_token}`,
                      'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
                    },
                  });
                  if (!res.ok) return;
                  const html = await res.text();
                  const blob = new Blob([html], { type: 'text/html' });
                  window.open(URL.createObjectURL(blob), '_blank');
                }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                  <Download size={16} />
                  Download PDF
                </button>
                <button onClick={() => { setMenuOpen(false); router.push(`/dashboard/bids/new?duplicate=${bid.id}`); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                  <Copy size={16} />
                  Duplicate
                </button>
                <button onClick={() => { setMenuOpen(false); navigator.clipboard.writeText(`${window.location.origin}/portal/bids/${bid.id}`); alert('Link copied to clipboard'); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                  <ExternalLink size={16} />
                  Property Portal Link
                </button>
                <hr className="my-1 border-main" />
                <button onClick={async () => { setMenuOpen(false); if (confirm('Delete this bid?')) { await deleteBid(bid.id); router.push('/dashboard/bids'); } }} className="w-full px-4 py-2 text-left text-sm hover:bg-red-50 dark:hover:bg-red-900/20 text-red-600 flex items-center gap-2">
                  <Trash2 size={16} />
                  Delete
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Status & Total Card */}
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted">{t('common.total')}</p>
                  <p className="text-3xl font-semibold text-main">{formatCurrency(bid.total)}</p>
                  {bid.depositAmount > 0 && (
                    <p className="text-sm text-muted mt-1">
                      Deposit: {formatCurrency(bid.depositAmount)}
                      {bid.depositPaid && (
                        <span className="text-emerald-600 ml-2">{t('common.paid')}</span>
                      )}
                    </p>
                  )}
                </div>
                <div className="text-right">
                  <p className="text-sm text-muted">{t('common.validUntil')}</p>
                  <p className="text-main font-medium">{formatDate(bid.validUntil)}</p>
                  {new Date(bid.validUntil) < new Date() && bid.status !== 'accepted' && (
                    <Badge variant="warning" className="mt-1">{t('common.expired')}</Badge>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Customer Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <User size={18} className="text-muted" />
                Customer
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="font-medium text-main">
                {bid.customer?.firstName} {bid.customer?.lastName}
              </div>
              {bid.customer?.email && (
                <div className="flex items-center gap-2 text-sm text-muted">
                  <Mail size={14} />
                  <a href={`mailto:${bid.customer.email}`} className="hover:text-accent">
                    {bid.customer.email}
                  </a>
                </div>
              )}
              {bid.customer?.phone && (
                <div className="flex items-center gap-2 text-sm text-muted">
                  <Phone size={14} />
                  <a href={`tel:${bid.customer.phone}`} className="hover:text-accent">
                    {bid.customer.phone}
                  </a>
                </div>
              )}
              {bid.customer?.address && (
                <div className="flex items-center gap-2 text-sm text-muted">
                  <MapPin size={14} />
                  <span>
                    {bid.customer.address.street}, {bid.customer.address.city},{' '}
                    {bid.customer.address.state} {bid.customer.address.zip}
                  </span>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Options */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <DollarSign size={18} className="text-muted" />
                {bid.options.length > 1 ? 'Pricing Options' : 'Line Items'}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {/* Option Tabs */}
              {bid.options.length > 1 && (
                <div className="flex gap-2 mb-4 pb-4 border-b border-main">
                  {bid.options.map((option, index) => (
                    <button
                      key={option.id}
                      onClick={() => setActiveOptionIndex(index)}
                      className={cn(
                        'px-4 py-2 rounded-lg text-sm font-medium transition-colors flex items-center gap-2',
                        activeOptionIndex === index
                          ? 'bg-accent text-white'
                          : 'bg-secondary text-muted hover:bg-surface-hover',
                        bid.selectedOptionId === option.id && 'ring-2 ring-emerald-500'
                      )}
                    >
                      {option.name}
                      {option.isRecommended && <Star size={14} className="fill-current" />}
                      {bid.selectedOptionId === option.id && (
                        <CheckCircle size={14} className="text-emerald-400" />
                      )}
                    </button>
                  ))}
                </div>
              )}

              {/* Line Items */}
              {activeOption && (
                <div className="space-y-4">
                  {activeOption.description && (
                    <p className="text-sm text-muted">{activeOption.description}</p>
                  )}

                  <table className="w-full">
                    <thead>
                      <tr className="text-left text-sm text-muted border-b border-main">
                        <th className="pb-2 font-medium">{t('common.description')}</th>
                        <th className="pb-2 font-medium text-right">{t('common.qty')}</th>
                        <th className="pb-2 font-medium text-right">{t('common.price')}</th>
                        <th className="pb-2 font-medium text-right">{t('common.total')}</th>
                      </tr>
                    </thead>
                    <tbody>
                      {activeOption.lineItems.map((item) => (
                        <tr key={item.id} className="border-b border-main/50">
                          <td className="py-3">
                            <div className="font-medium text-main">{item.description}</div>
                          </td>
                          <td className="py-3 text-right text-muted">
                            {item.quantity}
                          </td>
                          <td className="py-3 text-right text-muted">
                            {formatCurrency(item.unitPrice)}
                          </td>
                          <td className="py-3 text-right font-medium text-main">
                            {formatCurrency(item.total)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>

                  {/* Subtotals */}
                  <div className="pt-4 border-t border-main">
                    <div className="flex justify-end">
                      <div className="w-64 space-y-2">
                        <div className="flex justify-between text-sm">
                          <span className="text-muted">{t('common.subtotal')}</span>
                          <span className="text-main">{formatCurrency(activeOption.subtotal)}</span>
                        </div>
                        {selectedAddOns.length > 0 && (
                          <div className="flex justify-between text-sm">
                            <span className="text-muted">Add-ons</span>
                            <span className="text-main">{formatCurrency(addOnsTotal)}</span>
                          </div>
                        )}
                        <div className="flex justify-between text-sm">
                          <span className="text-muted">{t('common.tax')}</span>
                          <span className="text-main">{formatCurrency(bid.tax)}</span>
                        </div>
                        <div className="flex justify-between font-semibold text-lg pt-2 border-t border-main">
                          <span>{t('common.total')}</span>
                          <span>{formatCurrency(bid.total)}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Add-Ons */}
          {bid.addOns.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Add-Ons</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {bid.addOns.map((addon) => {
                    const isSelected = bid.selectedAddOnIds.includes(addon.id);
                    return (
                      <div
                        key={addon.id}
                        className={cn(
                          'flex items-center justify-between p-3 rounded-lg border',
                          isSelected
                            ? 'border-emerald-500 bg-emerald-50 dark:bg-emerald-900/20'
                            : 'border-main'
                        )}
                      >
                        <div className="flex items-center gap-3">
                          {isSelected ? (
                            <CheckCircle size={18} className="text-emerald-500" />
                          ) : (
                            <div className="w-[18px] h-[18px] rounded-full border-2 border-muted" />
                          )}
                          <div>
                            <div className="font-medium text-main">{addon.name}</div>
                            {addon.description && (
                              <div className="text-sm text-muted">{addon.description}</div>
                            )}
                          </div>
                        </div>
                        <div className="font-medium text-main">{formatCurrency(addon.price)}</div>
                      </div>
                    );
                  })}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Description */}
          {bid.description && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">{t('common.scopeOfWork')}</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-main whitespace-pre-wrap">{bid.description}</p>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Timeline */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">{t('common.timeline')}</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {timeline.map((event, index) => (
                  <div key={event.id} className="flex gap-3">
                    <div className="flex flex-col items-center">
                      <div
                        className={cn(
                          'w-7 h-7 rounded-full flex items-center justify-center',
                          event.completed
                            ? event.type === 'rejected'
                              ? 'bg-red-500'
                              : 'bg-emerald-500'
                            : 'bg-secondary border-2 border-main'
                        )}
                      >
                        {getTimelineIcon(event.type, event.completed)}
                      </div>
                      {index < timeline.length - 1 && (
                        <div
                          className={cn(
                            'w-0.5 h-8 mt-1',
                            event.completed ? 'bg-emerald-500' : 'bg-main'
                          )}
                        />
                      )}
                    </div>
                    <div className="flex-1 pb-4">
                      <div
                        className={cn(
                          'font-medium',
                          event.completed ? 'text-main' : 'text-muted'
                        )}
                      >
                        {event.label}
                      </div>
                      {event.date && (
                        <div className="text-xs text-muted">
                          {formatDateTime(event.date)}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Signature */}
          {bid.signatureData && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">{t('common.signature')}</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="bg-secondary rounded-lg p-4">
                  <img
                    src={bid.signatureData}
                    alt="Customer signature"
                    className="max-h-24 mx-auto"
                  />
                </div>
                {bid.signedAt && (
                  <p className="text-sm text-muted mt-2 text-center">
                    Signed on {formatDateTime(bid.signedAt)}
                  </p>
                )}
              </CardContent>
            </Card>
          )}

          {/* Quick Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">{t('common.details')}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.createdAt')}</span>
                <span className="text-main">{formatDate(bid.createdAt)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.lastUpdated')}</span>
                <span className="text-main">{formatDate(bid.updatedAt)}</span>
              </div>
              {bid.sentAt && (
                <div className="flex justify-between text-sm">
                  <span className="text-muted">{t('common.sent')}</span>
                  <span className="text-main">{formatDate(bid.sentAt)}</span>
                </div>
              )}
              {bid.viewedAt && (
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Viewed</span>
                  <span className="text-main">{formatDate(bid.viewedAt)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.validUntil')}</span>
                <span className="text-main">{formatDate(bid.validUntil)}</span>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
