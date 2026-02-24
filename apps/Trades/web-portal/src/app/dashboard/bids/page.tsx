'use client';

import { useState, useEffect, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Search,
  Filter,
  MoreHorizontal,
  FileText,
  Eye,
  Send,
  CheckCircle,
  XCircle,
  Clock,
  ArrowRight,
  Download,
  Trash2,
  Square,
  CheckSquare,
  X,
  Copy,
  TrendingUp,
  AlertTriangle,
  BarChart3,
  Target,
  DollarSign,
  Calendar,
  Briefcase,
  Loader2,
  LayoutGrid,
  List,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge, Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, formatRelativeTime, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { useBids } from '@/lib/hooks/use-bids';
import { getSupabase } from '@/lib/supabase';
import { useStats } from '@/lib/hooks/use-stats';
import { usePermissions } from '@/components/permission-gate';
import type { Bid } from '@/types';

export default function BidsPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const { loading: permLoading } = usePermissions();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [viewMode, setViewMode] = useState<'list' | 'pipeline'>('list');
  const { bids, loading, sendBid, deleteBid, convertToJob, rejectWithAnalysis } = useBids();
  const { stats: dashStats } = useStats();
  const stats = dashStats.bids;
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [showLossModal, setShowLossModal] = useState<string | null>(null);
  const [converting, setConverting] = useState<string | null>(null);

  const filteredBids = bids.filter((bid) => {
    const matchesSearch =
      bid.title?.toLowerCase().includes(search.toLowerCase()) ||
      bid.customerName?.toLowerCase().includes(search.toLowerCase()) ||
      bid.customer?.firstName?.toLowerCase().includes(search.toLowerCase()) ||
      bid.customer?.lastName?.toLowerCase().includes(search.toLowerCase());

    const matchesStatus = statusFilter === 'all' || bid.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  // Bid analytics
  const winRate = useMemo(() => {
    const decided = bids.filter(b => ['accepted', 'rejected'].includes(b.status));
    if (decided.length === 0) return null;
    return Math.round((decided.filter(b => b.status === 'accepted').length / decided.length) * 100);
  }, [bids]);

  const avgBidSize = useMemo(() => {
    if (bids.length === 0) return 0;
    return bids.reduce((sum, b) => sum + (b.total || 0), 0) / bids.length;
  }, [bids]);

  const avgTimeToDecision = useMemo(() => {
    const decided = bids.filter(b => b.sentAt && (b.status === 'accepted' || b.status === 'rejected'));
    if (decided.length === 0) return null;
    const totalDays = decided.reduce((sum, b) => {
      const sent = new Date(b.sentAt!).getTime();
      const raw = b as unknown as Record<string, unknown>;
      const decidedAt = b.status === 'accepted'
        ? new Date((raw.acceptedAt as string) || b.updatedAt).getTime()
        : new Date((raw.rejectedAt as string) || b.updatedAt).getTime();
      return sum + (decidedAt - sent) / 86400000;
    }, 0);
    return Math.round(totalDays / decided.length);
  }, [bids]);

  // Follow-up alerts — bids sent 7+ days ago with no response
  const staleBids = useMemo(() => {
    const cutoff = new Date(Date.now() - 7 * 86400000);
    return bids.filter(b =>
      b.status === 'sent' && b.sentAt && new Date(b.sentAt) < cutoff
    );
  }, [bids]);

  // Expiring bids — valid_until within 7 days
  const expiringBids = useMemo(() => {
    const now = new Date();
    const cutoff = new Date(Date.now() + 7 * 86400000);
    return bids.filter(b =>
      b.validUntil && !['accepted', 'rejected', 'expired'].includes(b.status) &&
      new Date(b.validUntil) > now && new Date(b.validUntil) < cutoff
    );
  }, [bids]);

  const handleConvertToJob = async (bidId: string) => {
    setConverting(bidId);
    try {
      const jobId = await convertToJob(bidId);
      router.push(`/dashboard/jobs/${jobId}`);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to convert');
    } finally {
      setConverting(null);
    }
  };

  const pipelineStages = ['draft', 'sent', 'viewed', 'accepted', 'rejected'] as const;
  const stageConfig: Record<string, { label: string; color: string; bgColor: string }> = {
    draft: { label: 'Draft', color: 'text-muted', bgColor: 'bg-secondary' },
    sent: { label: 'Sent', color: 'text-blue-600 dark:text-blue-400', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
    viewed: { label: 'Viewed', color: 'text-purple-600 dark:text-purple-400', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
    accepted: { label: 'Won', color: 'text-emerald-600 dark:text-emerald-400', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
    rejected: { label: 'Lost', color: 'text-red-600 dark:text-red-400', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  };

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'draft', label: 'Draft' },
    { value: 'sent', label: 'Sent' },
    { value: 'viewed', label: 'Viewed' },
    { value: 'accepted', label: 'Accepted' },
    { value: 'rejected', label: 'Rejected' },
    { value: 'expired', label: 'Expired' },
  ];

  // Loss modal state
  const [lossReason, setLossReason] = useState('');
  const [lossCompetitor, setLossCompetitor] = useState('');
  const [lossCompetitorPrice, setLossCompetitorPrice] = useState('');
  const [lossFeedback, setLossFeedback] = useState('');
  const [submittingLoss, setSubmittingLoss] = useState(false);

  const handleLossSubmit = async () => {
    if (!showLossModal || !lossReason) return;
    setSubmittingLoss(true);
    try {
      await rejectWithAnalysis(showLossModal, {
        reason: lossReason,
        competitor: lossCompetitor || undefined,
        competitorPrice: lossCompetitorPrice ? parseFloat(lossCompetitorPrice) : undefined,
        feedback: lossFeedback || undefined,
      });
      setShowLossModal(null);
      setLossReason('');
      setLossCompetitor('');
      setLossCompetitorPrice('');
      setLossFeedback('');
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to record loss');
    } finally {
      setSubmittingLoss(false);
    }
  };

  return (
    <div className="space-y-6 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('bids.title')}</h1>
          <p className="text-muted mt-1">{t('bids.createAndManageYourBids')}</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex items-center border border-main rounded-lg overflow-hidden">
            <button
              onClick={() => setViewMode('list')}
              className={cn('p-2 transition-colors', viewMode === 'list' ? 'bg-accent text-white' : 'hover:bg-surface-hover text-muted')}
            >
              <List size={16} />
            </button>
            <button
              onClick={() => setViewMode('pipeline')}
              className={cn('p-2 transition-colors', viewMode === 'pipeline' ? 'bg-accent text-white' : 'hover:bg-surface-hover text-muted')}
            >
              <LayoutGrid size={16} />
            </button>
          </div>
          <Button onClick={() => router.push('/dashboard/bids/new')}>
            <Plus size={16} />
            New Bid
          </Button>
        </div>
      </div>

      {/* Stats Row 1: Counts */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Clock size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.pending}</p>
                <p className="text-sm text-muted">{t('common.pending')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Send size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.sent}</p>
                <p className="text-sm text-muted">{t('common.sent')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.accepted}</p>
                <p className="text-sm text-muted">{t('common.accepted')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-secondary rounded-lg">
                <FileText size={20} className="text-muted" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(stats.totalValue)}</p>
                <p className="text-sm text-muted">{t('common.totalValue')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Stats Row 2: Tracking Dashboard */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg">
                <Target size={20} className="text-indigo-600 dark:text-indigo-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{winRate !== null ? `${winRate}%` : '--'}</p>
                <p className="text-sm text-muted">Win Rate</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg">
                <DollarSign size={20} className="text-cyan-600 dark:text-cyan-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(avgBidSize)}</p>
                <p className="text-sm text-muted">Avg Bid Size</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange-100 dark:bg-orange-900/30 rounded-lg">
                <BarChart3 size={20} className="text-orange-600 dark:text-orange-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{avgTimeToDecision !== null ? `${avgTimeToDecision}d` : '--'}</p>
                <p className="text-sm text-muted">Avg Time to Decision</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Follow-up Alert */}
      {staleBids.length > 0 && (
        <div className="flex items-center gap-3 px-4 py-3 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg">
          <AlertTriangle size={18} className="text-amber-600 dark:text-amber-400 flex-shrink-0" />
          <p className="text-sm text-amber-800 dark:text-amber-200">
            <span className="font-medium">{staleBids.length} bid{staleBids.length > 1 ? 's' : ''}</span> sent 7+ days ago with no response. Following up within 48 hours increases close rate by 50%.
          </p>
        </div>
      )}

      {/* Expiring Alert */}
      {expiringBids.length > 0 && (
        <div className="flex items-center gap-3 px-4 py-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
          <Calendar size={18} className="text-red-600 dark:text-red-400 flex-shrink-0" />
          <p className="text-sm text-red-800 dark:text-red-200">
            <span className="font-medium">{expiringBids.length} bid{expiringBids.length > 1 ? 's' : ''}</span> expiring within 7 days. Contact customers before they lapse.
          </p>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder={t('bidsPage.searchBids')}
          className="sm:w-80"
        />
        <Select
          options={statusOptions}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Batch Action Bar */}
      {selectedIds.size > 0 && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 lg:left-[calc(50%+128px)]">
          <div className="flex items-center gap-3 px-4 py-3 bg-surface border border-main rounded-xl shadow-lg">
            <span className="text-sm font-medium text-main">
              {selectedIds.size} selected
            </span>
            <div className="w-px h-6 bg-main" />
            <Button variant="secondary" size="sm" onClick={async () => {
              if (!confirm(`Mark ${selectedIds.size} bid(s) as sent?`)) return;
              for (const id of selectedIds) { try { await sendBid(id); } catch {} }
              setSelectedIds(new Set());
            }}>
              <Send size={14} />
              Send All
            </Button>
            <Button variant="secondary" size="sm" onClick={() => {
              const rows = bids.filter(b => selectedIds.has(b.id));
              const csv = ['Title,Customer,Status,Total,Created'].concat(
                rows.map(b => `"${b.title}","${b.customerName}","${b.status}",${b.total},"${b.createdAt}"`)
              ).join('\n');
              const blob = new Blob([csv], { type: 'text/csv' });
              const url = URL.createObjectURL(blob);
              const a = document.createElement('a'); a.href = url; a.download = 'bids-export.csv'; a.click();
              URL.revokeObjectURL(url);
            }}>
              <Download size={14} />
              Export
            </Button>
            <Button variant="secondary" size="sm" className="text-red-600 hover:text-red-700" onClick={async () => {
              if (!confirm(`Delete ${selectedIds.size} bid(s)? This cannot be undone.`)) return;
              for (const id of selectedIds) { try { await deleteBid(id); } catch {} }
              setSelectedIds(new Set());
            }}>
              <Trash2 size={14} />
              Delete
            </Button>
            <button
              onClick={() => setSelectedIds(new Set())}
              className="p-1.5 hover:bg-surface-hover rounded-lg transition-colors"
            >
              <X size={16} className="text-muted" />
            </button>
          </div>
        </div>
      )}

      {/* Pipeline View */}
      {viewMode === 'pipeline' && (
        <div className="grid grid-cols-5 gap-3">
          {pipelineStages.map((stage) => {
            const config = stageConfig[stage];
            const stageBids = bids.filter(b => b.status === stage);
            const stageTotal = stageBids.reduce((s, b) => s + (b.total || 0), 0);
            return (
              <div key={stage} className="space-y-2">
                <div className={cn('px-3 py-2 rounded-lg', config.bgColor)}>
                  <div className="flex items-center justify-between">
                    <span className={cn('text-sm font-medium', config.color)}>{config.label}</span>
                    <span className={cn('text-xs', config.color)}>{stageBids.length}</span>
                  </div>
                  <p className="text-xs text-muted mt-0.5">{formatCurrency(stageTotal)}</p>
                </div>
                <div className="space-y-2 min-h-[100px]">
                  {stageBids.map((bid) => (
                    <div
                      key={bid.id}
                      onClick={() => router.push(`/dashboard/bids/${bid.id}`)}
                      className="p-3 bg-surface border border-main rounded-lg hover:border-accent cursor-pointer transition-colors"
                    >
                      <p className="text-sm font-medium text-main truncate">{bid.title}</p>
                      <p className="text-xs text-muted mt-1 truncate">
                        {bid.customer?.firstName} {bid.customer?.lastName}
                      </p>
                      <div className="flex items-center justify-between mt-2">
                        <span className="text-sm font-semibold text-main">{formatCurrency(bid.total)}</span>
                        {bid.validUntil && (
                          <span className={cn('text-xs', new Date(bid.validUntil) < new Date() ? 'text-red-500' : 'text-muted')}>
                            {formatRelativeTime(bid.validUntil)}
                          </span>
                        )}
                      </div>
                      {stage === 'sent' && bid.sentAt && new Date(bid.sentAt) < new Date(Date.now() - 7 * 86400000) && (
                        <div className="mt-2 flex items-center gap-1 text-xs text-amber-600 dark:text-amber-400">
                          <AlertTriangle size={12} />
                          Follow up
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* List View */}
      {viewMode === 'list' && (
        <Card>
          <CardContent className="p-0">
            {filteredBids.length === 0 ? (
              <div className="py-12 text-center text-muted">
                <FileText size={40} className="mx-auto mb-2 opacity-50" />
                <p>{t('bids.noRecords')}</p>
              </div>
            ) : (
              <>
                <div className="px-6 py-3 border-b border-main flex items-center gap-4 bg-secondary/50">
                  <button
                    onClick={() => {
                      if (selectedIds.size === filteredBids.length) {
                        setSelectedIds(new Set());
                      } else {
                        setSelectedIds(new Set(filteredBids.map((b) => b.id)));
                      }
                    }}
                    className="p-1 hover:bg-surface-hover rounded transition-colors"
                  >
                    {selectedIds.size === filteredBids.length && filteredBids.length > 0 ? (
                      <CheckSquare size={18} className="text-accent" />
                    ) : (
                      <Square size={18} className="text-muted" />
                    )}
                  </button>
                  <span className="text-sm text-muted">
                    {selectedIds.size === 0 ? 'Select all' : `${selectedIds.size} of ${filteredBids.length} selected`}
                  </span>
                </div>
                <div className="divide-y divide-main">
                  {filteredBids.map((bid) => (
                    <BidRow
                      key={bid.id}
                      bid={bid}
                      isSelected={selectedIds.has(bid.id)}
                      onSelect={(selected) => {
                        const newSet = new Set(selectedIds);
                        if (selected) newSet.add(bid.id);
                        else newSet.delete(bid.id);
                        setSelectedIds(newSet);
                      }}
                      onClick={() => router.push(`/dashboard/bids/${bid.id}`)}
                      onView={() => router.push(`/dashboard/bids/${bid.id}`)}
                      onSend={async () => { await sendBid(bid.id); }}
                      onConvert={() => handleConvertToJob(bid.id)}
                      onMarkLost={() => setShowLossModal(bid.id)}
                      converting={converting === bid.id}
                      onDelete={async () => {
                        if (confirm('Delete this bid?')) await deleteBid(bid.id);
                      }}
                      onDownloadPdf={async () => {
                        try {
                          const supabase = getSupabase();
                          const { data: { session } } = await supabase.auth.getSession();
                          if (!session) { alert('Not authenticated'); return; }
                          const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
                          const res = await fetch(`${baseUrl}/functions/v1/export-bid-pdf?bid_id=${bid.id}`, {
                            headers: { 'Authorization': `Bearer ${session.access_token}`, 'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '' },
                          });
                          if (!res.ok) throw new Error(await res.text());
                          const html = await res.text();
                          const w = window.open('', '_blank');
                          if (w) { w.document.write(html); w.document.close(); }
                        } catch (e) { alert(e instanceof Error ? e.message : 'Failed to download PDF'); }
                      }}
                    />
                  ))}
                </div>
              </>
            )}
          </CardContent>
        </Card>
      )}

      {/* Win/Loss Analysis Modal */}
      {showLossModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={() => setShowLossModal(null)}>
          <div className="bg-surface border border-main rounded-xl shadow-2xl w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold text-main">Record Bid Loss</h3>
              <button onClick={() => setShowLossModal(null)} className="p-1 hover:bg-surface-hover rounded-lg">
                <X size={18} className="text-muted" />
              </button>
            </div>
            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-main mb-1">Reason *</label>
                <select
                  value={lossReason}
                  onChange={(e) => setLossReason(e.target.value)}
                  className="w-full px-3 py-2 bg-surface border border-main rounded-lg text-sm text-main"
                >
                  <option value="">Select reason...</option>
                  <option value="price_too_high">Price too high</option>
                  <option value="chose_competitor">Chose competitor</option>
                  <option value="project_cancelled">Project cancelled</option>
                  <option value="timeline_mismatch">Timeline mismatch</option>
                  <option value="scope_mismatch">Scope mismatch</option>
                  <option value="unresponsive">Customer unresponsive</option>
                  <option value="out_of_service_area">Out of service area</option>
                  <option value="other">Other</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1">Competitor (if known)</label>
                <input
                  type="text"
                  value={lossCompetitor}
                  onChange={(e) => setLossCompetitor(e.target.value)}
                  placeholder="Company name"
                  className="w-full px-3 py-2 bg-surface border border-main rounded-lg text-sm text-main"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1">Competitor Price</label>
                <input
                  type="number"
                  value={lossCompetitorPrice}
                  onChange={(e) => setLossCompetitorPrice(e.target.value)}
                  placeholder="$0.00"
                  className="w-full px-3 py-2 bg-surface border border-main rounded-lg text-sm text-main"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1">Additional Feedback</label>
                <textarea
                  value={lossFeedback}
                  onChange={(e) => setLossFeedback(e.target.value)}
                  rows={3}
                  placeholder="Any additional notes..."
                  className="w-full px-3 py-2 bg-surface border border-main rounded-lg text-sm text-main resize-none"
                />
              </div>
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <Button variant="secondary" onClick={() => setShowLossModal(null)}>Cancel</Button>
              <Button onClick={handleLossSubmit} disabled={!lossReason || submittingLoss}>
                {submittingLoss ? <Loader2 size={16} className="animate-spin" /> : <XCircle size={16} />}
                Record Loss
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function BidRow({ bid, isSelected, onSelect, onClick, onView, onSend, onConvert, onMarkLost, converting, onDelete, onDownloadPdf }: { bid: Bid; isSelected: boolean; onSelect: (selected: boolean) => void; onClick: () => void; onView: () => void; onSend: () => Promise<void>; onConvert: () => void; onMarkLost: () => void; converting: boolean; onDelete: () => Promise<void>; onDownloadPdf: () => Promise<void> }) {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <div
      className={cn(
        "px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors",
        isSelected && "bg-accent-light/50"
      )}
      onClick={onClick}
    >
      <div className="flex items-center gap-4">
        <button
          onClick={(e) => {
            e.stopPropagation();
            onSelect(!isSelected);
          }}
          className="p-1 hover:bg-surface-hover rounded transition-colors flex-shrink-0"
        >
          {isSelected ? (
            <CheckSquare size={18} className="text-accent" />
          ) : (
            <Square size={18} className="text-muted" />
          )}
        </button>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h4 className="font-medium text-main truncate">{bid.title}</h4>
            <StatusBadge status={bid.status} />
            {bid.depositPaid && (
              <Badge variant="success" size="sm">
                Deposit Paid
              </Badge>
            )}
          </div>
          <p className="text-sm text-muted mt-1">
            {bid.customer?.firstName} {bid.customer?.lastName}
          </p>
        </div>
        <div className="text-right">
          <p className="font-semibold text-main">{formatCurrency(bid.total)}</p>
          <p className="text-sm text-muted">{formatDate(bid.createdAt)}</p>
          {bid.validUntil && (
            <p className={cn('text-xs mt-0.5', new Date(bid.validUntil) < new Date() ? 'text-red-500 font-medium' : 'text-muted')}>
              {new Date(bid.validUntil) < new Date() ? 'Expired' : `Expires ${formatRelativeTime(bid.validUntil)}`}
            </p>
          )}
        </div>
        <div className="relative">
          <button
            onClick={(e) => {
              e.stopPropagation();
              setMenuOpen(!menuOpen);
            }}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
          >
            <MoreHorizontal size={18} className="text-muted" />
          </button>
          {menuOpen && (
            <div className="absolute right-0 top-full mt-1 w-48 bg-surface border border-main rounded-lg shadow-lg py-1 z-10">
              <button onClick={(e) => { e.stopPropagation(); setMenuOpen(false); onView(); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                <Eye size={16} />
                View
              </button>
              <button onClick={async (e) => { e.stopPropagation(); setMenuOpen(false); await onSend(); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                <Send size={16} />
                Send
              </button>
              <button onClick={async (e) => { e.stopPropagation(); setMenuOpen(false); await onDownloadPdf(); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                <Download size={16} />
                Download PDF
              </button>
              {bid.status === 'accepted' && (
                <button onClick={(e) => { e.stopPropagation(); setMenuOpen(false); onConvert(); }} disabled={converting} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2 text-emerald-600">
                  {converting ? <Loader2 size={16} className="animate-spin" /> : <Briefcase size={16} />}
                  Convert to Job
                </button>
              )}
              {!['accepted', 'rejected'].includes(bid.status) && (
                <button onClick={(e) => { e.stopPropagation(); setMenuOpen(false); onMarkLost(); }} className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2 text-amber-600">
                  <TrendingUp size={16} />
                  Mark Lost
                </button>
              )}
              <hr className="my-1 border-main" />
              <button onClick={async (e) => { e.stopPropagation(); setMenuOpen(false); await onDelete(); }} className="w-full px-4 py-2 text-left text-sm hover:bg-red-50 dark:hover:bg-red-900/20 text-red-600 flex items-center gap-2">
                <Trash2 size={16} />
                Delete
              </button>
            </div>
          )}
        </div>
      </div>
      {bid.options.length > 1 && (
        <div className="mt-3 flex items-center gap-2">
          {bid.options.map((option) => (
            <span
              key={option.id}
              className={cn(
                'px-2 py-1 text-xs rounded-md',
                option.isRecommended
                  ? 'bg-accent-light text-accent font-medium'
                  : 'bg-secondary text-muted'
              )}
            >
              {option.name}: {formatCurrency(option.subtotal)}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}
