'use client';

import { useState, useCallback } from 'react';
import {
  Store,
  Gavel,
  UserCircle,
  DollarSign,
  TrendingUp,
  Trophy,
  Clock,
  MapPin,
  Wrench,
  AlertTriangle,
  ChevronDown,
  ChevronUp,
  Send,
  XCircle,
  Save,
  Loader2,
  Shield,
  Award,
  Settings,
  Zap,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, formatRelativeTime, cn } from '@/lib/utils';
import {
  useMarketplace,
  type MarketplaceLead,
  type MarketplaceBid,
} from '@/lib/hooks/use-marketplace';
import { useTranslation } from '@/lib/translations';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

type TabId = 'leads' | 'bids' | 'profile';

const TABS: { id: TabId; label: string; icon: React.ReactNode }[] = [
  { id: 'leads', label: 'Available Leads', icon: <Store size={16} /> },
  { id: 'bids', label: 'My Bids', icon: <Gavel size={16} /> },
  { id: 'profile', label: 'Contractor Profile', icon: <UserCircle size={16} /> },
];

const urgencyConfig: Record<string, { label: string; variant: 'error' | 'warning' | 'info' | 'default' }> = {
  emergency: { label: 'Emergency', variant: 'error' },
  urgent: { label: 'Urgent', variant: 'warning' },
  standard: { label: 'Standard', variant: 'info' },
  flexible: { label: 'Flexible', variant: 'default' },
};

const bidStatusConfig: Record<string, { label: string; variant: 'default' | 'info' | 'success' | 'warning' | 'error' | 'secondary' }> = {
  pending: { label: 'Pending', variant: 'info' },
  submitted: { label: 'Submitted', variant: 'info' },
  accepted: { label: 'Accepted', variant: 'success' },
  rejected: { label: 'Rejected', variant: 'error' },
  withdrawn: { label: 'Withdrawn', variant: 'secondary' },
  expired: { label: 'Expired', variant: 'warning' },
};

const leadStatusConfig: Record<string, { label: string; variant: 'default' | 'success' | 'info' | 'warning' | 'error' | 'secondary' }> = {
  open: { label: 'Open', variant: 'success' },
  in_progress: { label: 'In Progress', variant: 'info' },
  closed: { label: 'Closed', variant: 'secondary' },
  expired: { label: 'Expired', variant: 'warning' },
  cancelled: { label: 'Cancelled', variant: 'error' },
};

const tradeOptions = [
  { value: 'all', label: 'All Trades' },
  { value: 'hvac', label: 'HVAC' },
  { value: 'plumbing', label: 'Plumbing' },
  { value: 'electrical', label: 'Electrical' },
  { value: 'roofing', label: 'Roofing' },
  { value: 'general', label: 'General' },
  { value: 'painting', label: 'Painting' },
  { value: 'flooring', label: 'Flooring' },
  { value: 'landscaping', label: 'Landscaping' },
  { value: 'restoration', label: 'Restoration' },
];

const urgencyOptions = [
  { value: 'all', label: 'All Urgencies' },
  { value: 'emergency', label: 'Emergency' },
  { value: 'urgent', label: 'Urgent' },
  { value: 'standard', label: 'Standard' },
  { value: 'flexible', label: 'Flexible' },
];

const statusFilterOptions = [
  { value: 'all', label: 'All Statuses' },
  { value: 'open', label: 'Open' },
  { value: 'in_progress', label: 'In Progress' },
  { value: 'closed', label: 'Closed' },
];

// ---------------------------------------------------------------------------
// Page Component
// ---------------------------------------------------------------------------

export default function MarketplacePage() {
  const { t } = useTranslation();
  const {
    leads,
    bids,
    profile,
    loading,
    error,
    createBid,
    withdrawBid,
    updateContractorProfile,
    openLeads,
    myActiveBids,
    wonBids,
    avgBidAmount,
  } = useMarketplace();

  const [activeTab, setActiveTab] = useState<TabId>('leads');

  if (loading && leads.length === 0 && bids.length === 0) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-muted" />
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('marketplace.title')}</h1>
          <p className="text-muted mt-1">Find leads, place bids, and grow your business</p>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Store size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{openLeads.length}</p>
                <p className="text-sm text-muted">Available Leads</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Gavel size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{myActiveBids.length}</p>
                <p className="text-sm text-muted">My Active Bids</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Trophy size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{wonBids.length}</p>
                <p className="text-sm text-muted">Won Bids</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg">
                <TrendingUp size={20} className="text-cyan-600 dark:text-cyan-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(avgBidAmount)}</p>
                <p className="text-sm text-muted">Avg Bid Amount</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 p-1 bg-secondary rounded-lg w-fit">
        {TABS.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              'flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors',
              activeTab === tab.id
                ? 'bg-surface shadow-sm text-main'
                : 'text-muted hover:text-main'
            )}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'leads' && (
        <AvailableLeadsTab leads={leads} onCreateBid={createBid} />
      )}
      {activeTab === 'bids' && (
        <MyBidsTab bids={bids} onWithdraw={withdrawBid} />
      )}
      {activeTab === 'profile' && (
        <ContractorProfileTab profile={profile} onSave={updateContractorProfile} />
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Tab: Available Leads
// ---------------------------------------------------------------------------

function AvailableLeadsTab({
  leads,
  onCreateBid,
}: {
  leads: MarketplaceLead[];
  onCreateBid: (input: {
    marketplaceLeadId: string;
    bidAmount: number;
    bidType?: string;
    description?: string;
    estimatedTimeline?: string;
    includesParts?: boolean;
    warrantyOffered?: string;
    earliestAvailable?: string;
  }) => Promise<string>;
}) {
  const [search, setSearch] = useState('');
  const [tradeFilter, setTradeFilter] = useState('all');
  const [urgencyFilter, setUrgencyFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [biddingLeadId, setBiddingLeadId] = useState<string | null>(null);

  const filtered = leads.filter((lead) => {
    const matchesSearch =
      (lead.homeownerName || '').toLowerCase().includes(search.toLowerCase()) ||
      (lead.description || '').toLowerCase().includes(search.toLowerCase()) ||
      (lead.propertyCity || '').toLowerCase().includes(search.toLowerCase()) ||
      (lead.serviceType || '').toLowerCase().includes(search.toLowerCase());
    const matchesTrade = tradeFilter === 'all' || (lead.tradeCategory || '').toLowerCase() === tradeFilter;
    const matchesUrgency = urgencyFilter === 'all' || (lead.urgency || '').toLowerCase() === urgencyFilter;
    const matchesStatus = statusFilter === 'all' || lead.status === statusFilter;
    return matchesSearch && matchesTrade && matchesUrgency && matchesStatus;
  });

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search leads..."
          className="sm:w-80"
        />
        <Select
          options={tradeOptions}
          value={tradeFilter}
          onChange={(e) => setTradeFilter(e.target.value)}
          className="sm:w-44"
        />
        <Select
          options={urgencyOptions}
          value={urgencyFilter}
          onChange={(e) => setUrgencyFilter(e.target.value)}
          className="sm:w-44"
        />
        <Select
          options={statusFilterOptions}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-44"
        />
      </div>

      {/* Lead Cards Grid */}
      {filtered.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <Store size={40} className="mx-auto text-muted mb-3" />
            <p className="text-main font-medium">No leads found</p>
            <p className="text-muted text-sm mt-1">Try adjusting your filters</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {filtered.map((lead) => (
            <LeadCard
              key={lead.id}
              lead={lead}
              isBidding={biddingLeadId === lead.id}
              onBidClick={() => setBiddingLeadId(lead.id)}
              onCancelBid={() => setBiddingLeadId(null)}
              onSubmitBid={onCreateBid}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Lead Card
// ---------------------------------------------------------------------------

function LeadCard({
  lead,
  isBidding,
  onBidClick,
  onCancelBid,
  onSubmitBid,
}: {
  lead: MarketplaceLead;
  isBidding: boolean;
  onBidClick: () => void;
  onCancelBid: () => void;
  onSubmitBid: (input: {
    marketplaceLeadId: string;
    bidAmount: number;
    bidType?: string;
    description?: string;
    estimatedTimeline?: string;
    includesParts?: boolean;
    warrantyOffered?: string;
    earliestAvailable?: string;
  }) => Promise<string>;
}) {
  const { t } = useTranslation();
  const [bidAmount, setBidAmount] = useState('');
  const [bidDescription, setBidDescription] = useState('');
  const [bidTimeline, setBidTimeline] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const urgency = urgencyConfig[lead.urgency || ''] || urgencyConfig.standard;
  const statusConf = leadStatusConfig[lead.status] || leadStatusConfig.open;
  const budgetMin = lead.estimatedBudgetMin;
  const budgetMax = lead.estimatedBudgetMax;
  const location = [lead.propertyCity, lead.propertyState].filter(Boolean).join(', ');

  const handleSubmit = async () => {
    const amount = parseFloat(bidAmount);
    if (!amount || amount <= 0) return;
    setSubmitting(true);
    try {
      await onSubmitBid({
        marketplaceLeadId: lead.id,
        bidAmount: amount,
        description: bidDescription.trim() || undefined,
        estimatedTimeline: bidTimeline.trim() || undefined,
      });
      onCancelBid();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to submit bid');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Card hover className="flex flex-col">
      <CardContent className="p-4 flex-1 space-y-3">
        {/* Top row: trade + urgency + status */}
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <div className="flex items-center gap-2">
            {lead.tradeCategory && (
              <Badge variant="purple">
                <Wrench size={12} />
                {lead.tradeCategory}
              </Badge>
            )}
            {lead.serviceType && (
              <Badge variant="default">{lead.serviceType}</Badge>
            )}
          </div>
          <div className="flex items-center gap-2">
            <Badge variant={urgency.variant}>
              {urgency.label}
            </Badge>
            <Badge variant={statusConf.variant}>
              {statusConf.label}
            </Badge>
          </div>
        </div>

        {/* Location */}
        {location && (
          <div className="flex items-center gap-1.5 text-sm text-muted">
            <MapPin size={14} />
            {location}
          </div>
        )}

        {/* Description */}
        {lead.description && (
          <p className="text-sm text-main line-clamp-3">{lead.description}</p>
        )}

        {/* Budget */}
        {(budgetMin || budgetMax) && (
          <div className="flex items-center gap-1.5 text-sm">
            <DollarSign size={14} className="text-emerald-500" />
            <span className="font-medium text-main">
              {budgetMin && budgetMax
                ? `${formatCurrency(budgetMin)} - ${formatCurrency(budgetMax)}`
                : budgetMin
                  ? `From ${formatCurrency(budgetMin)}`
                  : `Up to ${formatCurrency(budgetMax!)}`}
            </span>
          </div>
        )}

        {/* Timestamp */}
        <div className="flex items-center gap-1.5 text-xs text-muted">
          <Clock size={12} />
          {formatRelativeTime(lead.createdAt)}
          {lead.expiresAt && (
            <span className="ml-2 text-amber-500">
              Expires {formatDate(lead.expiresAt)}
            </span>
          )}
        </div>

        {/* Bid Form */}
        {isBidding && (
          <div className="pt-3 border-t border-main space-y-3">
            <div>
              <label className="block text-sm font-medium text-main mb-1">Bid Amount *</label>
              <input
                type="number"
                value={bidAmount}
                onChange={(e) => setBidAmount(e.target.value)}
                placeholder="Enter amount"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">{t('common.description')}</label>
              <textarea
                value={bidDescription}
                onChange={(e) => setBidDescription(e.target.value)}
                placeholder="Describe your approach..."
                rows={2}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] resize-none"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">{t('common.timeline')}</label>
              <input
                type="text"
                value={bidTimeline}
                onChange={(e) => setBidTimeline(e.target.value)}
                placeholder="e.g. 2-3 days"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
            <div className="flex items-center gap-2">
              <Button
                variant="secondary"
                size="sm"
                onClick={onCancelBid}
                disabled={submitting}
              >
                Cancel
              </Button>
              <Button
                size="sm"
                onClick={handleSubmit}
                disabled={submitting || !bidAmount}
                loading={submitting}
              >
                <Send size={14} />
                Submit Bid
              </Button>
            </div>
          </div>
        )}
      </CardContent>

      {/* Bid button */}
      {!isBidding && lead.status === 'open' && (
        <div className="px-4 pb-4">
          <Button variant="primary" size="sm" className="w-full" onClick={onBidClick}>
            <Gavel size={14} />
            Place Bid
          </Button>
        </div>
      )}
    </Card>
  );
}

// ---------------------------------------------------------------------------
// Tab: My Bids
// ---------------------------------------------------------------------------

function MyBidsTab({
  bids,
  onWithdraw,
}: {
  bids: MarketplaceBid[];
  onWithdraw: (bidId: string) => Promise<void>;
}) {
  const { t } = useTranslation();
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [withdrawingId, setWithdrawingId] = useState<string | null>(null);

  const handleWithdraw = async (bidId: string) => {
    setWithdrawingId(bidId);
    try {
      await onWithdraw(bidId);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to withdraw bid');
    } finally {
      setWithdrawingId(null);
    }
  };

  if (bids.length === 0) {
    return (
      <Card>
        <CardContent className="py-12 text-center">
          <Gavel size={40} className="mx-auto text-muted mb-3" />
          <p className="text-main font-medium">No bids yet</p>
          <p className="text-muted text-sm mt-1">Browse available leads and place your first bid</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardContent className="p-0">
        <table className="w-full">
          <thead>
            <tr className="border-b border-main">
              <th className="text-left text-sm font-medium text-muted px-6 py-3">Lead</th>
              <th className="text-left text-sm font-medium text-muted px-6 py-3">Bid Amount</th>
              <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.status')}</th>
              <th className="text-left text-sm font-medium text-muted px-6 py-3">Submitted</th>
              <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {bids.map((bid) => {
              const isExpanded = expandedId === bid.id;
              const statusConf = bidStatusConfig[bid.status] || bidStatusConfig.pending;
              const lead = bid.lead;
              const canWithdraw = bid.status === 'pending' || bid.status === 'submitted';

              return (
                <BidRow
                  key={bid.id}
                  bid={bid}
                  lead={lead ?? null}
                  isExpanded={isExpanded}
                  statusConf={statusConf}
                  canWithdraw={canWithdraw}
                  isWithdrawing={withdrawingId === bid.id}
                  onToggle={() => setExpandedId(isExpanded ? null : bid.id)}
                  onWithdraw={() => handleWithdraw(bid.id)}
                />
              );
            })}
          </tbody>
        </table>
      </CardContent>
    </Card>
  );
}

function BidRow({
  bid,
  lead,
  isExpanded,
  statusConf,
  canWithdraw,
  isWithdrawing,
  onToggle,
  onWithdraw,
}: {
  bid: MarketplaceBid;
  lead: MarketplaceLead | null;
  isExpanded: boolean;
  statusConf: { label: string; variant: 'default' | 'info' | 'success' | 'warning' | 'error' | 'secondary' };
  canWithdraw: boolean;
  isWithdrawing: boolean;
  onToggle: () => void;
  onWithdraw: () => void;
}) {
  const leadSummary = lead
    ? [lead.tradeCategory, lead.serviceType, lead.propertyCity].filter(Boolean).join(' / ')
    : 'Lead details unavailable';

  return (
    <>
      <tr className="border-b border-main/50 hover:bg-surface-hover">
        <td className="px-6 py-4">
          <button onClick={onToggle} className="flex items-center gap-2 text-left">
            {isExpanded ? <ChevronUp size={14} className="text-muted" /> : <ChevronDown size={14} className="text-muted" />}
            <div>
              <p className="font-medium text-main text-sm">{leadSummary}</p>
              {lead?.description && (
                <p className="text-xs text-muted line-clamp-1 mt-0.5">{lead.description}</p>
              )}
            </div>
          </button>
        </td>
        <td className="px-6 py-4 font-medium text-main">{formatCurrency(bid.bidAmount)}</td>
        <td className="px-6 py-4">
          <Badge variant={statusConf.variant}>{statusConf.label}</Badge>
        </td>
        <td className="px-6 py-4 text-sm text-muted">{formatRelativeTime(bid.createdAt)}</td>
        <td className="px-6 py-4">
          {canWithdraw && (
            <Button
              variant="ghost"
              size="sm"
              onClick={onWithdraw}
              disabled={isWithdrawing}
              loading={isWithdrawing}
            >
              <XCircle size={14} />
              Withdraw
            </Button>
          )}
        </td>
      </tr>
      {isExpanded && (
        <tr className="border-b border-main/50">
          <td colSpan={5} className="px-6 py-4 bg-secondary/30">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Lead Details */}
              <div className="space-y-2">
                <h4 className="text-sm font-semibold text-main">Lead Details</h4>
                {lead ? (
                  <div className="space-y-1.5 text-sm">
                    <div className="flex gap-2">
                      <span className="text-muted w-24 shrink-0">Location:</span>
                      <span className="text-main">
                        {[lead.propertyCity, lead.propertyState].filter(Boolean).join(', ') || '-'}
                      </span>
                    </div>
                    <div className="flex gap-2">
                      <span className="text-muted w-24 shrink-0">Trade:</span>
                      <span className="text-main">{lead.tradeCategory || '-'}</span>
                    </div>
                    <div className="flex gap-2">
                      <span className="text-muted w-24 shrink-0">Service:</span>
                      <span className="text-main">{lead.serviceType || '-'}</span>
                    </div>
                    <div className="flex gap-2">
                      <span className="text-muted w-24 shrink-0">Urgency:</span>
                      <span className="text-main">{lead.urgency || '-'}</span>
                    </div>
                    <div className="flex gap-2">
                      <span className="text-muted w-24 shrink-0">Budget:</span>
                      <span className="text-main">
                        {lead.estimatedBudgetMin && lead.estimatedBudgetMax
                          ? `${formatCurrency(lead.estimatedBudgetMin)} - ${formatCurrency(lead.estimatedBudgetMax)}`
                          : '-'}
                      </span>
                    </div>
                    {lead.description && (
                      <div className="flex gap-2">
                        <span className="text-muted w-24 shrink-0">Description:</span>
                        <span className="text-main">{lead.description}</span>
                      </div>
                    )}
                  </div>
                ) : (
                  <p className="text-sm text-muted">No lead details available</p>
                )}
              </div>

              {/* Bid Details */}
              <div className="space-y-2">
                <h4 className="text-sm font-semibold text-main">Bid Details</h4>
                <div className="space-y-1.5 text-sm">
                  <div className="flex gap-2">
                    <span className="text-muted w-24 shrink-0">Amount:</span>
                    <span className="text-main font-medium">{formatCurrency(bid.bidAmount)}</span>
                  </div>
                  {bid.bidType && (
                    <div className="flex gap-2">
                      <span className="text-muted w-24 shrink-0">Type:</span>
                      <span className="text-main capitalize">{bid.bidType}</span>
                    </div>
                  )}
                  {bid.estimatedTimeline && (
                    <div className="flex gap-2">
                      <span className="text-muted w-24 shrink-0">Timeline:</span>
                      <span className="text-main">{bid.estimatedTimeline}</span>
                    </div>
                  )}
                  {bid.warrantyOffered && (
                    <div className="flex gap-2">
                      <span className="text-muted w-24 shrink-0">Warranty:</span>
                      <span className="text-main">{bid.warrantyOffered}</span>
                    </div>
                  )}
                  {bid.description && (
                    <div className="flex gap-2">
                      <span className="text-muted w-24 shrink-0">Description:</span>
                      <span className="text-main">{bid.description}</span>
                    </div>
                  )}
                  <div className="flex gap-2">
                    <span className="text-muted w-24 shrink-0">Submitted:</span>
                    <span className="text-main">{formatDate(bid.createdAt)}</span>
                  </div>
                </div>
              </div>
            </div>
          </td>
        </tr>
      )}
    </>
  );
}

// ---------------------------------------------------------------------------
// Tab: Contractor Profile
// ---------------------------------------------------------------------------

function ContractorProfileTab({
  profile,
  onSave,
}: {
  profile: ReturnType<typeof useMarketplace>['profile'];
  onSave: ReturnType<typeof useMarketplace>['updateContractorProfile'];
}) {
  const { t: tr } = useTranslation();
  const [displayName, setDisplayName] = useState(profile?.displayName || '');
  const [tagline, setTagline] = useState(profile?.tagline || '');
  const [description, setDescription] = useState(profile?.description || '');
  const [serviceRadius, setServiceRadius] = useState(String(profile?.serviceRadiusMiles || ''));
  const [zipCodes, setZipCodes] = useState(profile?.serviceZipCodes?.join(', ') || '');
  const [trades, setTrades] = useState(profile?.tradeCategories?.join(', ') || '');
  const [specializations, setSpecializations] = useState(profile?.specializations?.join(', ') || '');
  const [licenseNumber, setLicenseNumber] = useState(profile?.licenseNumber || '');
  const [licenseState, setLicenseState] = useState(profile?.licenseState || '');
  const [yearsInBusiness, setYearsInBusiness] = useState(String(profile?.yearsInBusiness || ''));
  const [insuranceVerified, setInsuranceVerified] = useState(profile?.insuranceVerified || false);
  const [bonded, setBonded] = useState(profile?.bonded || false);
  const [autoBid, setAutoBid] = useState(profile?.autoBid || false);
  const [maxDailyLeads, setMaxDailyLeads] = useState(String(profile?.maxDailyLeads || ''));
  const [minJobValue, setMinJobValue] = useState(String(profile?.minJobValue || ''));
  const [saving, setSaving] = useState(false);

  const handleSave = useCallback(async () => {
    setSaving(true);
    try {
      await onSave({
        displayName: displayName.trim() || null,
        tagline: tagline.trim() || null,
        description: description.trim() || null,
        serviceRadiusMiles: serviceRadius ? parseFloat(serviceRadius) : null,
        serviceZipCodes: zipCodes ? zipCodes.split(',').map((z) => z.trim()).filter(Boolean) : null,
        tradeCategories: trades ? trades.split(',').map((t) => t.trim()).filter(Boolean) : null,
        specializations: specializations ? specializations.split(',').map((s) => s.trim()).filter(Boolean) : null,
        licenseNumber: licenseNumber.trim() || null,
        licenseState: licenseState.trim() || null,
        yearsInBusiness: yearsInBusiness ? parseInt(yearsInBusiness) : null,
        insuranceVerified,
        bonded,
        autoBid,
        maxDailyLeads: maxDailyLeads ? parseInt(maxDailyLeads) : null,
        minJobValue: minJobValue ? parseFloat(minJobValue) : null,
      });
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to save profile');
    } finally {
      setSaving(false);
    }
  }, [
    onSave, displayName, tagline, description, serviceRadius, zipCodes,
    trades, specializations, licenseNumber, licenseState, yearsInBusiness,
    insuranceVerified, bonded, autoBid, maxDailyLeads, minJobValue,
  ]);

  const inputClass = 'w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]';

  return (
    <div className="space-y-6">
      {/* Business Information */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Award size={18} className="text-muted" />
            <CardTitle>Business Information</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Display Name</label>
              <input
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                placeholder="Your Company Name"
                className={inputClass}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Tagline</label>
              <input
                type="text"
                value={tagline}
                onChange={(e) => setTagline(e.target.value)}
                placeholder="Short description of your business"
                className={inputClass}
              />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-main mb-1.5">{tr('common.description')}</label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Tell homeowners about your company, experience, and what sets you apart..."
                rows={3}
                className={cn(inputClass, 'resize-none')}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Years in Business</label>
              <input
                type="number"
                value={yearsInBusiness}
                onChange={(e) => setYearsInBusiness(e.target.value)}
                placeholder="10"
                className={inputClass}
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Service Area */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <MapPin size={18} className="text-muted" />
            <CardTitle>Service Area</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Service Radius (miles)</label>
              <input
                type="number"
                value={serviceRadius}
                onChange={(e) => setServiceRadius(e.target.value)}
                placeholder="25"
                className={inputClass}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Service Zip Codes</label>
              <input
                type="text"
                value={zipCodes}
                onChange={(e) => setZipCodes(e.target.value)}
                placeholder="90210, 90211, 90212"
                className={inputClass}
              />
              <p className="text-xs text-muted mt-1">Comma-separated list</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Trades & Specializations */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Wrench size={18} className="text-muted" />
            <CardTitle>Trades & Specializations</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Trade Categories</label>
              <input
                type="text"
                value={trades}
                onChange={(e) => setTrades(e.target.value)}
                placeholder="HVAC, Plumbing, Electrical"
                className={inputClass}
              />
              <p className="text-xs text-muted mt-1">Comma-separated list</p>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Specializations</label>
              <input
                type="text"
                value={specializations}
                onChange={(e) => setSpecializations(e.target.value)}
                placeholder="Water heater install, AC repair"
                className={inputClass}
              />
              <p className="text-xs text-muted mt-1">Comma-separated list</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Credentials */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Shield size={18} className="text-muted" />
            <CardTitle>Credentials</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">License Number</label>
              <input
                type="text"
                value={licenseNumber}
                onChange={(e) => setLicenseNumber(e.target.value)}
                placeholder="License #"
                className={inputClass}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">License State</label>
              <input
                type="text"
                value={licenseState}
                onChange={(e) => setLicenseState(e.target.value)}
                placeholder="CA"
                className={inputClass}
              />
            </div>
          </div>
          <div className="flex flex-wrap gap-6 pt-2">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={insuranceVerified}
                onChange={(e) => setInsuranceVerified(e.target.checked)}
                className="w-4 h-4 rounded border-main text-[var(--accent)] focus:ring-[var(--accent)]"
              />
              <span className="text-sm text-main">Insurance Verified</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={bonded}
                onChange={(e) => setBonded(e.target.checked)}
                className="w-4 h-4 rounded border-main text-[var(--accent)] focus:ring-[var(--accent)]"
              />
              <span className="text-sm text-main">Bonded</span>
            </label>
          </div>
        </CardContent>
      </Card>

      {/* Marketplace Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Settings size={18} className="text-muted" />
            <CardTitle>Marketplace Settings</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Max Daily Leads</label>
              <input
                type="number"
                value={maxDailyLeads}
                onChange={(e) => setMaxDailyLeads(e.target.value)}
                placeholder="10"
                className={inputClass}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Minimum Job Value</label>
              <input
                type="number"
                value={minJobValue}
                onChange={(e) => setMinJobValue(e.target.value)}
                placeholder="500"
                className={inputClass}
              />
            </div>
          </div>
          <div className="pt-2">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={autoBid}
                onChange={(e) => setAutoBid(e.target.checked)}
                className="w-4 h-4 rounded border-main text-[var(--accent)] focus:ring-[var(--accent)]"
              />
              <div>
                <span className="text-sm text-main font-medium flex items-center gap-1.5">
                  <Zap size={14} className="text-amber-500" />
                  Auto-Bid
                </span>
                <p className="text-xs text-muted mt-0.5">
                  Automatically place bids on matching leads within your criteria
                </p>
              </div>
            </label>
          </div>
        </CardContent>
      </Card>

      {/* Save Button */}
      <div className="flex justify-end">
        <Button onClick={handleSave} disabled={saving} loading={saving}>
          <Save size={16} />
          {saving ? 'Saving...' : 'Save Profile'}
        </Button>
      </div>
    </div>
  );
}
