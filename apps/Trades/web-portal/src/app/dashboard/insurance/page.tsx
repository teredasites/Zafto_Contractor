'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Shield, Search, Plus, Building2, Calendar, DollarSign, ChevronRight } from 'lucide-react';
import { useClaims } from '@/lib/hooks/use-insurance';
import { CLAIM_STATUS_LABELS, CLAIM_STATUS_COLORS, LOSS_TYPE_LABELS, CLAIM_CATEGORY_LABELS, CLAIM_CATEGORY_COLORS } from '@/lib/hooks/mappers';
import type { InsuranceClaimData, ClaimStatus, ClaimCategory } from '@/types';

const PIPELINE_STAGES: ClaimStatus[] = [
  'new', 'scope_requested', 'scope_submitted', 'estimate_pending', 'estimate_approved',
  'work_in_progress', 'work_complete', 'final_inspection', 'settled', 'closed', 'denied',
];

const FILTER_OPTIONS: { label: string; value: ClaimStatus | 'all' | 'active' }[] = [
  { label: 'All', value: 'all' },
  { label: 'Active', value: 'active' },
  { label: 'New', value: 'new' },
  { label: 'Estimate Pending', value: 'estimate_pending' },
  { label: 'Work In Progress', value: 'work_in_progress' },
  { label: 'Settled', value: 'settled' },
  { label: 'Denied', value: 'denied' },
];

export default function InsurancePage() {
  const router = useRouter();
  const { claims, loading } = useClaims();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [view, setView] = useState<'list' | 'pipeline'>('list');
  const [categoryFilter, setCategoryFilter] = useState<ClaimCategory | 'all'>('all');

  const filtered = claims.filter((c) => {
    if (categoryFilter !== 'all' && c.claimCategory !== categoryFilter) return false;
    if (search) {
      const q = search.toLowerCase();
      if (!c.claimNumber.toLowerCase().includes(q) &&
          !c.insuranceCompany.toLowerCase().includes(q) &&
          !(c.job?.title || '').toLowerCase().includes(q) &&
          !(c.job?.customer_name || '').toLowerCase().includes(q)) {
        return false;
      }
    }
    if (statusFilter === 'all') return true;
    if (statusFilter === 'active') return !['closed', 'denied', 'settled'].includes(c.claimStatus);
    return c.claimStatus === statusFilter;
  });

  const totalApproved = filtered.reduce((sum, c) => sum + (c.approvedAmount || 0), 0);
  const totalDeductibles = filtered.reduce((sum, c) => sum + c.deductible, 0);

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Insurance Claims</h1>
          <p className="text-sm text-muted-foreground mt-1">
            {filtered.length} claim{filtered.length !== 1 ? 's' : ''} &middot; ${totalApproved.toLocaleString()} approved &middot; ${totalDeductibles.toLocaleString()} deductibles
          </p>
        </div>
        <button
          onClick={() => router.push('/dashboard/jobs/new?type=insurance_claim')}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-amber-500 text-white text-sm font-medium hover:bg-amber-600 transition-colors"
        >
          <Plus className="w-4 h-4" />
          New Insurance Job
        </button>
      </div>

      {/* Search + Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="relative flex-1 min-w-[240px] max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search claims, carriers, jobs..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-sm rounded-lg border border-border bg-background focus:outline-none focus:ring-2 focus:ring-amber-500/30"
          />
        </div>
        <div className="flex items-center gap-1.5">
          {FILTER_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              onClick={() => setStatusFilter(opt.value)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${
                statusFilter === opt.value
                  ? 'bg-amber-500 text-white'
                  : 'bg-muted text-muted-foreground hover:bg-muted/80'
              }`}
            >
              {opt.label}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-1.5">
          {(['all', 'restoration', 'storm', 'reconstruction', 'commercial'] as const).map((cat) => (
            <button
              key={cat}
              onClick={() => setCategoryFilter(cat)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${
                categoryFilter === cat
                  ? 'bg-purple-500 text-white'
                  : 'bg-muted text-muted-foreground hover:bg-muted/80'
              }`}
            >
              {cat === 'all' ? 'All Types' : CLAIM_CATEGORY_LABELS[cat]}
            </button>
          ))}
        </div>
        <div className="ml-auto flex items-center gap-1 bg-muted rounded-lg p-0.5">
          <button
            onClick={() => setView('list')}
            className={`px-3 py-1 rounded-md text-xs font-medium ${view === 'list' ? 'bg-background shadow-sm' : ''}`}
          >
            List
          </button>
          <button
            onClick={() => setView('pipeline')}
            className={`px-3 py-1 rounded-md text-xs font-medium ${view === 'pipeline' ? 'bg-background shadow-sm' : ''}`}
          >
            Pipeline
          </button>
        </div>
      </div>

      {/* Loading */}
      {loading && (
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-20 rounded-xl bg-muted animate-pulse" />
          ))}
        </div>
      )}

      {/* Empty */}
      {!loading && filtered.length === 0 && (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <div className="w-12 h-12 rounded-full bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center mb-4">
            <Shield className="w-6 h-6 text-amber-500" />
          </div>
          <p className="text-sm font-medium">No insurance claims</p>
          <p className="text-xs text-muted-foreground mt-1">Create an insurance job to start tracking claims</p>
        </div>
      )}

      {/* List View */}
      {!loading && filtered.length > 0 && view === 'list' && (
        <div className="space-y-2">
          {filtered.map((claim) => (
            <ClaimRow key={claim.id} claim={claim} onClick={() => router.push(`/dashboard/insurance/${claim.id}`)} />
          ))}
        </div>
      )}

      {/* Pipeline View */}
      {!loading && filtered.length > 0 && view === 'pipeline' && (
        <div className="overflow-x-auto pb-4">
          <div className="flex gap-3 min-w-max">
            {PIPELINE_STAGES.map((stage) => {
              const stageClaims = filtered.filter((c) => c.claimStatus === stage);
              if (stageClaims.length === 0 && !['new', 'work_in_progress', 'settled'].includes(stage)) return null;
              return (
                <div key={stage} className="w-[280px] flex-shrink-0">
                  <div className="flex items-center justify-between mb-2 px-1">
                    <span className="text-xs font-medium text-muted-foreground">{CLAIM_STATUS_LABELS[stage]}</span>
                    <span className="text-xs text-muted-foreground">{stageClaims.length}</span>
                  </div>
                  <div className="space-y-2">
                    {stageClaims.map((claim) => (
                      <div
                        key={claim.id}
                        onClick={() => router.push(`/dashboard/insurance/${claim.id}`)}
                        className="p-3 rounded-xl border border-border bg-card hover:bg-muted/50 cursor-pointer transition-colors"
                      >
                        <div className="flex items-center gap-2 mb-1">
                          <Shield className="w-3.5 h-3.5 text-amber-500" />
                          <span className="text-xs font-mono text-muted-foreground">{claim.claimNumber}</span>
                        </div>
                        <p className="text-sm font-medium truncate">{claim.job?.title || 'Untitled Job'}</p>
                        <p className="text-xs text-muted-foreground truncate">{claim.insuranceCompany}</p>
                        {claim.approvedAmount != null && (
                          <p className="text-xs font-medium text-green-600 mt-1">${claim.approvedAmount.toLocaleString()}</p>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

function ClaimRow({ claim, onClick }: { claim: InsuranceClaimData; onClick: () => void }) {
  return (
    <div
      onClick={onClick}
      className="flex items-center gap-4 p-4 rounded-xl border border-border bg-card hover:bg-muted/50 cursor-pointer transition-colors group"
    >
      <div className="w-9 h-9 rounded-lg bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center flex-shrink-0">
        <Shield className="w-4 h-4 text-amber-500" />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium truncate">{claim.job?.title || 'Untitled Job'}</span>
          <span className={`inline-flex px-2 py-0.5 rounded-full text-[10px] font-medium ${CLAIM_STATUS_COLORS[claim.claimStatus]}`}>
            {CLAIM_STATUS_LABELS[claim.claimStatus]}
          </span>
          {claim.claimCategory !== 'restoration' && (
            <span className={`inline-flex px-2 py-0.5 rounded-full text-[10px] font-medium ${CLAIM_CATEGORY_COLORS[claim.claimCategory]}`}>
              {CLAIM_CATEGORY_LABELS[claim.claimCategory]}
            </span>
          )}
        </div>
        <div className="flex items-center gap-3 mt-0.5 text-xs text-muted-foreground">
          <span className="flex items-center gap-1">
            <Building2 className="w-3 h-3" />
            {claim.insuranceCompany}
          </span>
          <span className="font-mono">{claim.claimNumber}</span>
          <span className="flex items-center gap-1">
            <Calendar className="w-3 h-3" />
            {LOSS_TYPE_LABELS[claim.lossType] || claim.lossType} &middot; {new Date(claim.dateOfLoss).toLocaleDateString()}
          </span>
        </div>
      </div>
      <div className="text-right flex-shrink-0">
        {claim.approvedAmount != null && (
          <p className="text-sm font-medium flex items-center gap-1">
            <DollarSign className="w-3.5 h-3.5 text-green-500" />
            {claim.approvedAmount.toLocaleString()}
          </p>
        )}
        <p className="text-xs text-muted-foreground">
          Ded: ${claim.deductible.toLocaleString()}
        </p>
      </div>
      <ChevronRight className="w-4 h-4 text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity" />
    </div>
  );
}
