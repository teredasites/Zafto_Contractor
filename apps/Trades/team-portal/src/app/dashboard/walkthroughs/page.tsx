'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  ScanLine, MapPin, Camera, DoorOpen, Search,
  ChevronRight, Calendar, Smartphone,
} from 'lucide-react';
import { useWalkthroughs } from '@/lib/hooks/use-walkthroughs';
import { Card, CardContent } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { cn, formatDate } from '@/lib/utils';

// ==================== TYPES ====================

type FilterTab = 'all' | 'in_progress' | 'completed' | 'draft';

const FILTER_TABS: { key: FilterTab; label: string }[] = [
  { key: 'all', label: 'All' },
  { key: 'in_progress', label: 'In Progress' },
  { key: 'completed', label: 'Completed' },
  { key: 'draft', label: 'Draft' },
];

const STATUS_GROUPS: Record<FilterTab, Set<string>> = {
  all: new Set(),
  in_progress: new Set(['in_progress', 'uploading']),
  completed: new Set(['completed', 'uploaded', 'reviewed']),
  draft: new Set(['draft', 'scheduled']),
};

const TYPE_LABELS: Record<string, string> = {
  general: 'General',
  pre_construction: 'Pre-Construction',
  post_construction: 'Post-Construction',
  insurance_claim: 'Insurance Claim',
  inspection: 'Inspection',
  move_in: 'Move-In',
  move_out: 'Move-Out',
};

// ==================== SKELETON ====================

function WalkthroughsListSkeleton() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div className="skeleton h-7 w-40 rounded-lg" />
      <div className="flex gap-2">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="skeleton h-9 w-24 rounded-lg" />
        ))}
      </div>
      <div className="space-y-3">
        {[1, 2, 3].map((i) => (
          <div key={i} className="skeleton h-28 w-full rounded-xl" />
        ))}
      </div>
    </div>
  );
}

// ==================== PAGE ====================

export default function WalkthroughsListPage() {
  const { walkthroughs, loading, error } = useWalkthroughs();
  const [filter, setFilter] = useState<FilterTab>('all');
  const [search, setSearch] = useState('');
  const [showMobilePrompt, setShowMobilePrompt] = useState(false);

  const filtered = walkthroughs.filter((wt) => {
    // Filter by tab
    if (filter !== 'all' && !STATUS_GROUPS[filter].has(wt.status)) return false;

    // Filter by search
    if (search) {
      const q = search.toLowerCase();
      return (
        wt.name.toLowerCase().includes(q) ||
        wt.address.toLowerCase().includes(q) ||
        wt.walkthroughType.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const counts: Record<FilterTab, number> = {
    all: walkthroughs.length,
    in_progress: walkthroughs.filter((w) => STATUS_GROUPS.in_progress.has(w.status)).length,
    completed: walkthroughs.filter((w) => STATUS_GROUPS.completed.has(w.status)).length,
    draft: walkthroughs.filter((w) => STATUS_GROUPS.draft.has(w.status)).length,
  };

  if (loading) return <WalkthroughsListSkeleton />;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-main">Walkthroughs</h1>
          <p className="text-sm text-muted mt-0.5">
            {walkthroughs.length} walkthrough{walkthroughs.length !== 1 ? 's' : ''}
          </p>
        </div>
        <Button size="sm" onClick={() => setShowMobilePrompt(true)}>
          <Smartphone size={14} />
          Start New
        </Button>
      </div>

      {/* Mobile App Prompt */}
      {showMobilePrompt && (
        <Card>
          <CardContent className="py-4">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-lg bg-accent/10 flex items-center justify-center flex-shrink-0">
                <Smartphone size={20} className="text-accent" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-main">Start from Mobile App</p>
                <p className="text-xs text-muted mt-0.5">
                  New walkthroughs are created using the ZAFTO mobile app. Open the app and navigate to Walkthroughs to start a new one.
                </p>
              </div>
              <button
                onClick={() => setShowMobilePrompt(false)}
                className="text-muted hover:text-main transition-colors p-1"
              >
                <span className="sr-only">Close</span>
                <span aria-hidden="true" className="text-lg leading-none">&times;</span>
              </button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Error */}
      {error && (
        <Card>
          <CardContent className="py-4 text-center">
            <p className="text-sm text-red-500">{error}</p>
          </CardContent>
        </Card>
      )}

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
        <input
          type="text"
          placeholder="Search walkthroughs..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className={cn(
            'w-full pl-10 pr-4 py-3 bg-secondary border border-main rounded-lg text-main',
            'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
            'text-[15px]'
          )}
        />
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2 overflow-x-auto pb-1 -mx-1 px-1">
        {FILTER_TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setFilter(tab.key)}
            className={cn(
              'flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors min-h-[40px]',
              filter === tab.key
                ? 'bg-accent text-white'
                : 'bg-secondary text-muted hover:text-main hover:bg-surface-hover border border-main'
            )}
          >
            {tab.label}
            <span className={cn(
              'text-xs px-1.5 py-0.5 rounded-full',
              filter === tab.key
                ? 'bg-white/20 text-white'
                : 'bg-surface text-muted'
            )}>
              {counts[tab.key]}
            </span>
          </button>
        ))}
      </div>

      {/* Walkthrough Cards */}
      {filtered.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <ScanLine size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">No walkthroughs found</p>
            <p className="text-sm text-muted mt-1">
              {search
                ? 'Try adjusting your search'
                : filter !== 'all'
                  ? 'No walkthroughs match this filter'
                  : 'Walkthroughs will appear here once created'}
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {filtered.map((wt) => (
            <Link key={wt.id} href={`/dashboard/walkthroughs/${wt.id}`}>
              <Card className="hover:border-accent/30 transition-colors">
                <CardContent className="py-3.5">
                  <div className="flex items-start gap-3">
                    <div className="min-w-0 flex-1">
                      <div className="flex items-start justify-between gap-2">
                        <p className="text-sm font-medium text-main truncate">{wt.name}</p>
                        <StatusBadge status={wt.status} className="flex-shrink-0" />
                      </div>

                      {/* Type Label */}
                      <p className="text-xs text-secondary mt-0.5">
                        {TYPE_LABELS[wt.walkthroughType] || wt.walkthroughType}
                      </p>

                      <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-2">
                        {wt.address && (
                          <span className="text-xs text-muted flex items-center gap-1">
                            <MapPin size={12} className="flex-shrink-0" />
                            <span className="truncate max-w-[200px]">{wt.address}</span>
                          </span>
                        )}
                        <span className="text-xs text-muted flex items-center gap-1">
                          <DoorOpen size={12} className="flex-shrink-0" />
                          {wt.totalRooms} room{wt.totalRooms !== 1 ? 's' : ''}
                        </span>
                        <span className="text-xs text-muted flex items-center gap-1">
                          <Camera size={12} className="flex-shrink-0" />
                          {wt.totalPhotos} photo{wt.totalPhotos !== 1 ? 's' : ''}
                        </span>
                        {wt.createdAt && (
                          <span className="text-xs text-muted flex items-center gap-1">
                            <Calendar size={12} className="flex-shrink-0" />
                            {formatDate(wt.createdAt)}
                          </span>
                        )}
                      </div>
                    </div>
                    <ChevronRight size={16} className="text-muted flex-shrink-0 mt-1" />
                  </div>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
