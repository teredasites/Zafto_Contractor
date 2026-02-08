'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  Calculator, Plus, Search, User, MapPin, X, FileText, Send,
  CheckCircle2, XCircle, RefreshCw, Archive,
} from 'lucide-react';
import { useEstimates, createFieldEstimate } from '@/lib/hooks/use-estimates';
import { useAuth } from '@/components/auth-provider';
import {
  ESTIMATE_STATUS_LABELS, ESTIMATE_STATUS_COLORS,
  type EstimateStatus, type EstimateType,
} from '@/lib/hooks/mappers';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { formatCurrency, formatDate, cn } from '@/lib/utils';

type FilterTab = 'all' | EstimateStatus;

const FILTER_TABS: { key: FilterTab; label: string }[] = [
  { key: 'all', label: 'All' },
  { key: 'draft', label: 'Draft' },
  { key: 'sent', label: 'Sent' },
  { key: 'approved', label: 'Approved' },
  { key: 'declined', label: 'Declined' },
  { key: 'revised', label: 'Revised' },
  { key: 'completed', label: 'Completed' },
];

function EstimateStatusBadge({ status }: { status: EstimateStatus }) {
  const colors = ESTIMATE_STATUS_COLORS[status] || ESTIMATE_STATUS_COLORS.draft;
  const label = ESTIMATE_STATUS_LABELS[status] || status;
  return (
    <span className={cn('inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full', colors.bg, colors.text)}>
      {label}
    </span>
  );
}

function StatCard({ label, value, icon: Icon }: { label: string; value: number; icon: React.ElementType }) {
  return (
    <div className="bg-surface border border-main rounded-xl px-4 py-3 flex items-center gap-3">
      <div className="p-2 rounded-lg bg-accent/10">
        <Icon size={16} className="text-accent" />
      </div>
      <div>
        <p className="text-lg font-bold text-main">{value}</p>
        <p className="text-xs text-muted">{label}</p>
      </div>
    </div>
  );
}

function NewEstimateModal({
  onClose,
  onSubmit,
  submitting,
}: {
  onClose: () => void;
  onSubmit: (data: { title: string; estimateType: EstimateType; customerName: string; propertyAddress: string }) => void;
  submitting: boolean;
}) {
  const [title, setTitle] = useState('');
  const [estimateType, setEstimateType] = useState<EstimateType>('regular');
  const [customerName, setCustomerName] = useState('');
  const [propertyAddress, setPropertyAddress] = useState('');

  const canSubmit = title.trim().length > 0;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div className="relative bg-surface border border-main rounded-2xl shadow-xl w-full max-w-md">
        <div className="flex items-center justify-between px-5 py-4 border-b border-main">
          <h2 className="text-base font-semibold text-main">New Estimate</h2>
          <button onClick={onClose} className="p-1.5 rounded-md hover:bg-surface-hover text-muted hover:text-main transition-colors">
            <X size={16} />
          </button>
        </div>

        <div className="px-5 py-4 space-y-4">
          {/* Title */}
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Title</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Kitchen Remodel Estimate"
              className="w-full px-3 py-2 bg-surface border border-main rounded-lg text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50 focus:border-accent"
            />
          </div>

          {/* Estimate Type */}
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Type</label>
            <div className="flex gap-2">
              <button
                onClick={() => setEstimateType('regular')}
                className={cn(
                  'flex-1 px-3 py-2 rounded-lg text-sm font-medium border transition-colors',
                  estimateType === 'regular'
                    ? 'border-accent bg-accent/10 text-accent'
                    : 'border-main text-muted hover:bg-surface-hover'
                )}
              >
                Regular
              </button>
              <button
                onClick={() => setEstimateType('insurance')}
                className={cn(
                  'flex-1 px-3 py-2 rounded-lg text-sm font-medium border transition-colors',
                  estimateType === 'insurance'
                    ? 'border-accent bg-accent/10 text-accent'
                    : 'border-main text-muted hover:bg-surface-hover'
                )}
              >
                Insurance
              </button>
            </div>
          </div>

          {/* Customer Name */}
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Customer Name</label>
            <input
              type="text"
              value={customerName}
              onChange={(e) => setCustomerName(e.target.value)}
              placeholder="John Smith"
              className="w-full px-3 py-2 bg-surface border border-main rounded-lg text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50 focus:border-accent"
            />
          </div>

          {/* Property Address */}
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Property Address</label>
            <input
              type="text"
              value={propertyAddress}
              onChange={(e) => setPropertyAddress(e.target.value)}
              placeholder="123 Main St, City, ST 12345"
              className="w-full px-3 py-2 bg-surface border border-main rounded-lg text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50 focus:border-accent"
            />
          </div>
        </div>

        <div className="flex items-center justify-end gap-2 px-5 py-4 border-t border-main">
          <Button variant="secondary" size="sm" onClick={onClose} disabled={submitting}>
            Cancel
          </Button>
          <Button
            size="sm"
            onClick={() => onSubmit({ title: title.trim(), estimateType, customerName: customerName.trim(), propertyAddress: propertyAddress.trim() })}
            disabled={!canSubmit || submitting}
            loading={submitting}
          >
            <Plus size={16} />
            Create Estimate
          </Button>
        </div>
      </div>
    </div>
  );
}

export default function EstimatesPage() {
  const { profile } = useAuth();
  const { estimates, loading } = useEstimates();
  const router = useRouter();

  const [filter, setFilter] = useState<FilterTab>('all');
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  // Filtered estimates
  const filtered = useMemo(() => {
    let result = estimates;
    if (filter !== 'all') {
      result = result.filter((e) => e.status === filter);
    }
    if (search.trim()) {
      const q = search.toLowerCase();
      result = result.filter(
        (e) =>
          e.estimateNumber.toLowerCase().includes(q) ||
          e.customerName.toLowerCase().includes(q) ||
          e.title.toLowerCase().includes(q)
      );
    }
    return result;
  }, [estimates, filter, search]);

  // Stats
  const stats = useMemo(() => {
    const total = estimates.length;
    const draft = estimates.filter((e) => e.status === 'draft').length;
    const sent = estimates.filter((e) => e.status === 'sent').length;
    const approved = estimates.filter((e) => e.status === 'approved').length;
    return { total, draft, sent, approved };
  }, [estimates]);

  const handleCreate = async (data: { title: string; estimateType: EstimateType; customerName: string; propertyAddress: string }) => {
    if (!profile?.companyId || !profile?.uid) return;
    setSubmitting(true);
    try {
      const id = await createFieldEstimate({
        companyId: profile.companyId,
        userId: profile.uid,
        title: data.title,
        estimateType: data.estimateType,
        customerName: data.customerName,
        propertyAddress: data.propertyAddress,
      });
      if (id) {
        setShowModal(false);
        router.push(`/dashboard/estimates/${id}`);
      }
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="skeleton h-7 w-40 rounded-lg" />
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="skeleton h-20 rounded-xl" />
          ))}
        </div>
        <div className="space-y-2">
          {[1, 2, 3].map((i) => (
            <div key={i} className="skeleton h-24 w-full rounded-xl" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold text-main">Estimates</h1>
          <p className="text-sm text-muted mt-1">
            {estimates.length} estimate{estimates.length !== 1 ? 's' : ''} total
          </p>
        </div>
        <Button size="sm" className="flex-shrink-0" onClick={() => setShowModal(true)}>
          <Plus size={16} />
          New Estimate
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <StatCard label="Total" value={stats.total} icon={Calculator} />
        <StatCard label="Draft" value={stats.draft} icon={FileText} />
        <StatCard label="Sent" value={stats.sent} icon={Send} />
        <StatCard label="Approved" value={stats.approved} icon={CheckCircle2} />
      </div>

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search by number, customer, or title..."
          className="w-full pl-9 pr-4 py-2.5 bg-surface border border-main rounded-lg text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50 focus:border-accent"
        />
        {search && (
          <button onClick={() => setSearch('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-main">
            <X size={14} />
          </button>
        )}
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-1 overflow-x-auto pb-1 -mx-1 px-1">
        {FILTER_TABS.map((tab) => {
          const count = tab.key === 'all' ? estimates.length : estimates.filter((e) => e.status === tab.key).length;
          return (
            <button
              key={tab.key}
              onClick={() => setFilter(tab.key)}
              className={cn(
                'px-3 py-1.5 rounded-lg text-xs font-medium whitespace-nowrap transition-colors',
                filter === tab.key
                  ? 'bg-accent/10 text-accent'
                  : 'text-muted hover:text-main hover:bg-surface-hover'
              )}
            >
              {tab.label}
              <span className="ml-1 text-[10px] opacity-70">({count})</span>
            </button>
          );
        })}
      </div>

      {/* Estimates List */}
      {filtered.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <Calculator size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">
              {search || filter !== 'all' ? 'No estimates match your filters' : 'No estimates yet'}
            </p>
            <p className="text-sm text-muted mt-1">
              {search || filter !== 'all'
                ? 'Try adjusting your search or filter criteria.'
                : 'Create your first estimate to get started.'}
            </p>
            {!search && filter === 'all' && (
              <Button className="mt-4" onClick={() => setShowModal(true)}>
                <Plus size={16} />
                Create Estimate
              </Button>
            )}
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {filtered.map((est) => (
            <Link key={est.id} href={`/dashboard/estimates/${est.id}`}>
              <Card className="hover:bg-surface-hover transition-colors cursor-pointer">
                <CardContent className="py-3.5">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="text-xs font-mono text-muted">{est.estimateNumber}</span>
                        <EstimateStatusBadge status={est.status} />
                        {est.estimateType === 'insurance' && (
                          <span className="inline-flex items-center px-1.5 py-0.5 text-[10px] font-medium rounded bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400">
                            Insurance
                          </span>
                        )}
                      </div>
                      <p className="text-sm font-medium text-main mt-1 truncate">{est.title}</p>
                      {est.customerName && (
                        <span className="text-xs text-muted flex items-center gap-1 mt-0.5">
                          <User size={12} />
                          {est.customerName}
                        </span>
                      )}
                      {est.propertyAddress && (
                        <span className="text-xs text-muted flex items-center gap-1 mt-0.5">
                          <MapPin size={12} />
                          <span className="truncate">{est.propertyAddress}</span>
                        </span>
                      )}
                      <p className="text-xs text-muted mt-1">{formatDate(est.createdAt)}</p>
                    </div>
                    <p className="text-sm font-semibold text-main whitespace-nowrap flex-shrink-0">
                      {formatCurrency(est.grandTotal)}
                    </p>
                  </div>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}

      {/* New Estimate Modal */}
      {showModal && (
        <NewEstimateModal
          onClose={() => setShowModal(false)}
          onSubmit={handleCreate}
          submitting={submitting}
        />
      )}
    </div>
  );
}
