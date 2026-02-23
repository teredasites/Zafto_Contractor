'use client';

import { useState, useEffect } from 'react';
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
  const { bids, loading, sendBid, deleteBid } = useBids();
  const { stats: dashStats } = useStats();
  const stats = dashStats.bids;
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  const filteredBids = bids.filter((bid) => {
    const matchesSearch =
      bid.title?.toLowerCase().includes(search.toLowerCase()) ||
      bid.customerName?.toLowerCase().includes(search.toLowerCase()) ||
      bid.customer?.firstName?.toLowerCase().includes(search.toLowerCase()) ||
      bid.customer?.lastName?.toLowerCase().includes(search.toLowerCase());

    const matchesStatus = statusFilter === 'all' || bid.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'draft', label: 'Draft' },
    { value: 'sent', label: 'Sent' },
    { value: 'viewed', label: 'Viewed' },
    { value: 'accepted', label: 'Accepted' },
    { value: 'rejected', label: 'Rejected' },
    { value: 'expired', label: 'Expired' },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('bids.title')}</h1>
          <p className="text-muted mt-1">Create and manage your bids</p>
        </div>
        <Button onClick={() => router.push('/dashboard/bids/new')}>
          <Plus size={16} />
          New Bid
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Clock size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.pending}</p>
                <p className="text-sm text-muted">Pending</p>
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
                <p className="text-sm text-muted">Sent</p>
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
                <p className="text-sm text-muted">Accepted</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-slate-100 dark:bg-slate-800 rounded-lg">
                <FileText size={20} className="text-slate-600 dark:text-slate-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(stats.totalValue)}</p>
                <p className="text-sm text-muted">Total Value</p>
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
          placeholder="Search bids..."
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

      {/* Bids List */}
      <Card>
        <CardContent className="p-0">
          {filteredBids.length === 0 ? (
            <div className="py-12 text-center text-muted">
              <FileText size={40} className="mx-auto mb-2 opacity-50" />
              <p>{t('bids.noRecords')}</p>
            </div>
          ) : (
            <>
              {/* Select All Header */}
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
                      if (selected) {
                        newSet.add(bid.id);
                      } else {
                        newSet.delete(bid.id);
                      }
                      setSelectedIds(newSet);
                    }}
                    onClick={() => router.push(`/dashboard/bids/${bid.id}`)}
                    onView={() => router.push(`/dashboard/bids/${bid.id}`)}
                    onSend={async () => { await sendBid(bid.id); }}
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
    </div>
  );
}

function BidRow({ bid, isSelected, onSelect, onClick, onView, onSend, onDelete, onDownloadPdf }: { bid: Bid; isSelected: boolean; onSelect: (selected: boolean) => void; onClick: () => void; onView: () => void; onSend: () => Promise<void>; onDelete: () => Promise<void>; onDownloadPdf: () => Promise<void> }) {
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
