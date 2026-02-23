'use client';

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Search,
  MapPin,
  Camera,
  DoorOpen,
  ClipboardList,
  LayoutGrid,
  LayoutList,
  Clock,
  CheckCircle,
  Upload,
  Archive,
  FileText,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, cn } from '@/lib/utils';
import { useWalkthroughs } from '@/lib/hooks/use-walkthroughs';
import type { Walkthrough } from '@/lib/hooks/use-walkthroughs';
import { useTranslation } from '@/lib/translations';

// ── Status config ──

const STATUS_CONFIG: Record<string, { label: string; variant: string; bg: string; text: string; dot: string }> = {
  in_progress: {
    label: 'In Progress',
    variant: 'warning',
    bg: 'bg-amber-100 dark:bg-amber-900/30',
    text: 'text-amber-700 dark:text-amber-300',
    dot: 'bg-amber-500',
  },
  completed: {
    label: 'Completed',
    variant: 'success',
    bg: 'bg-emerald-100 dark:bg-emerald-900/30',
    text: 'text-emerald-700 dark:text-emerald-300',
    dot: 'bg-emerald-500',
  },
  uploaded: {
    label: 'Uploaded',
    variant: 'info',
    bg: 'bg-blue-100 dark:bg-blue-900/30',
    text: 'text-blue-700 dark:text-blue-300',
    dot: 'bg-blue-500',
  },
  bid_generated: {
    label: 'Bid Generated',
    variant: 'purple',
    bg: 'bg-purple-100 dark:bg-purple-900/30',
    text: 'text-purple-700 dark:text-purple-300',
    dot: 'bg-purple-500',
  },
  archived: {
    label: 'Archived',
    variant: 'default',
    bg: 'bg-slate-100 dark:bg-slate-800',
    text: 'text-slate-600 dark:text-slate-400',
    dot: 'bg-slate-400',
  },
};

function WalkthroughStatusBadge({ status }: { status: string }) {
  const config = STATUS_CONFIG[status] || STATUS_CONFIG.in_progress;
  return (
    <span className={cn('inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full', config.bg, config.text)}>
      <span className={cn('w-1.5 h-1.5 rounded-full', config.dot)} />
      {config.label}
    </span>
  );
}

// ── Type config ──

const TYPE_LABELS: Record<string, string> = {
  general: 'General',
  insurance: 'Insurance',
  maintenance: 'Maintenance',
  pre_purchase: 'Pre-Purchase',
  renovation: 'Renovation',
  restoration: 'Restoration',
};

// ── Filter tabs ──

const FILTER_TABS = [
  { key: 'all', label: 'All' },
  { key: 'in_progress', label: 'In Progress' },
  { key: 'completed', label: 'Completed' },
  { key: 'uploaded', label: 'Uploaded' },
  { key: 'archived', label: 'Archived' },
];

export default function WalkthroughsPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const { walkthroughs, loading } = useWalkthroughs();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [view, setView] = useState<'list' | 'grid'>('list');

  // ── Stats ──
  const stats = useMemo(() => {
    const total = walkthroughs.length;
    const inProgress = walkthroughs.filter((w) => w.status === 'in_progress').length;
    const completed = walkthroughs.filter((w) => w.status === 'completed').length;
    const uploaded = walkthroughs.filter((w) => w.status === 'uploaded').length;
    return { total, inProgress, completed, uploaded };
  }, [walkthroughs]);

  // ── Filtered list ──
  const filteredWalkthroughs = useMemo(() => {
    return walkthroughs.filter((w) => {
      const matchesSearch =
        w.name.toLowerCase().includes(search.toLowerCase()) ||
        w.address.toLowerCase().includes(search.toLowerCase()) ||
        w.city.toLowerCase().includes(search.toLowerCase());

      const matchesStatus = statusFilter === 'all' || w.status === statusFilter;

      return matchesSearch && matchesStatus;
    });
  }, [walkthroughs, search, statusFilter]);

  // ── Loading state ──
  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div>
          <div className="skeleton h-7 w-36 mb-2" />
          <div className="skeleton h-4 w-56" />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-5">
              <div className="skeleton h-3 w-20 mb-2" />
              <div className="skeleton h-7 w-10" />
            </div>
          ))}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="px-6 py-4 flex items-center gap-4">
              <div className="flex-1">
                <div className="skeleton h-4 w-40 mb-2" />
                <div className="skeleton h-3 w-32" />
              </div>
              <div className="skeleton h-4 w-20" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('walkthroughs.title')}</h1>
          <p className="text-muted mt-1">{t('walkthroughs.propertyWalkthroughsAndSiteAssessments')}</p>
        </div>
        <Button onClick={() => router.push('/dashboard/walkthroughs/new')}>
          <Plus size={16} />
          New Walkthrough
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <ClipboardList size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.total}</p>
                <p className="text-sm text-muted">{t('common.total')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Clock size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.inProgress}</p>
                <p className="text-sm text-muted">{t('common.inProgress')}</p>
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
                <p className="text-2xl font-semibold text-main">{stats.completed}</p>
                <p className="text-sm text-muted">{t('common.completed')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg">
                <Upload size={20} className="text-indigo-600 dark:text-indigo-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.uploaded}</p>
                <p className="text-sm text-muted">{t('common.uploaded')}</p>
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
          placeholder="Search walkthroughs..."
          className="sm:w-80"
        />
        {/* Tab filters */}
        <div className="flex items-center gap-1 p-1 bg-secondary rounded-lg">
          {FILTER_TABS.map((tab) => (
            <button
              key={tab.key}
              onClick={() => setStatusFilter(tab.key)}
              className={cn(
                'px-3 py-1.5 text-sm rounded-md transition-colors',
                statusFilter === tab.key
                  ? 'bg-surface text-main shadow-sm'
                  : 'text-muted hover:text-main'
              )}
            >
              {tab.label}
            </button>
          ))}
        </div>
        {/* View toggle */}
        <div className="flex items-center gap-1 p-1 bg-secondary rounded-lg ml-auto">
          <button
            onClick={() => setView('list')}
            className={cn(
              'p-1.5 rounded-md transition-colors',
              view === 'list'
                ? 'bg-surface text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
            title="List view"
          >
            <LayoutList size={16} />
          </button>
          <button
            onClick={() => setView('grid')}
            className={cn(
              'p-1.5 rounded-md transition-colors',
              view === 'grid'
                ? 'bg-surface text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
            title="Grid view"
          >
            <LayoutGrid size={16} />
          </button>
        </div>
      </div>

      {/* List/Grid */}
      {filteredWalkthroughs.length === 0 ? (
        <Card>
          <CardContent className="p-0">
            <div className="py-16 text-center text-muted">
              <ClipboardList size={40} className="mx-auto mb-3 opacity-50" />
              <p className="text-lg font-medium">{t('walkthroughs.noWalkthroughsFound')}</p>
              <p className="text-sm mt-1">
                {search || statusFilter !== 'all'
                  ? 'Try adjusting your filters'
                  : 'Create your first walkthrough to get started'}
              </p>
              {!search && statusFilter === 'all' && (
                <Button
                  className="mt-4"
                  onClick={() => router.push('/dashboard/walkthroughs/new')}
                >
                  <Plus size={16} />
                  New Walkthrough
                </Button>
              )}
            </div>
          </CardContent>
        </Card>
      ) : view === 'list' ? (
        <Card>
          <CardContent className="p-0">
            {/* Table header */}
            <div className="hidden lg:grid grid-cols-[1fr_120px_1fr_80px_80px_110px_110px_40px] gap-4 px-6 py-3 border-b border-main text-xs font-medium uppercase tracking-wider text-muted">
              <span>{t('common.name')}</span>
              <span>{t('common.type')}</span>
              <span>{t('common.address')}</span>
              <span className="text-center">{t('common.rooms')}</span>
              <span className="text-center">{t('common.photos')}</span>
              <span>{t('common.status')}</span>
              <span>{t('common.started')}</span>
              <span />
            </div>
            <div className="divide-y divide-main">
              {filteredWalkthroughs.map((w) => (
                <WalkthroughRow
                  key={w.id}
                  walkthrough={w}
                  onClick={() => router.push(`/dashboard/walkthroughs/${w.id}`)}
                />
              ))}
            </div>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {filteredWalkthroughs.map((w) => (
            <WalkthroughCard
              key={w.id}
              walkthrough={w}
              onClick={() => router.push(`/dashboard/walkthroughs/${w.id}`)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// ── Row component ──

function WalkthroughRow({ walkthrough, onClick }: { walkthrough: Walkthrough; onClick: () => void }) {
  const fullAddress = [walkthrough.address, walkthrough.city, walkthrough.state]
    .filter(Boolean)
    .join(', ');

  return (
    <div
      className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
      onClick={onClick}
    >
      {/* Mobile layout */}
      <div className="lg:hidden space-y-2">
        <div className="flex items-center justify-between">
          <h4 className="font-medium text-main truncate">{walkthrough.name}</h4>
          <WalkthroughStatusBadge status={walkthrough.status} />
        </div>
        <div className="flex items-center gap-4 text-sm text-muted">
          <span className="flex items-center gap-1">
            <MapPin size={14} />
            {fullAddress || 'No address'}
          </span>
        </div>
        <div className="flex items-center gap-4 text-sm text-muted">
          <span className="flex items-center gap-1">
            <DoorOpen size={14} />
            {walkthrough.totalRooms} rooms
          </span>
          <span className="flex items-center gap-1">
            <Camera size={14} />
            {walkthrough.totalPhotos} photos
          </span>
        </div>
      </div>

      {/* Desktop layout */}
      <div className="hidden lg:grid grid-cols-[1fr_120px_1fr_80px_80px_110px_110px_40px] gap-4 items-center">
        <div className="min-w-0">
          <h4 className="font-medium text-main truncate">{walkthrough.name}</h4>
        </div>
        <div>
          <Badge variant="secondary" size="sm">
            {TYPE_LABELS[walkthrough.walkthroughType] || walkthrough.walkthroughType}
          </Badge>
        </div>
        <div className="min-w-0">
          <span className="text-sm text-muted truncate flex items-center gap-1">
            <MapPin size={14} className="flex-shrink-0" />
            {fullAddress || 'No address'}
          </span>
        </div>
        <div className="text-center">
          <span className="text-sm text-main flex items-center justify-center gap-1">
            <DoorOpen size={14} className="text-muted" />
            {walkthrough.totalRooms}
          </span>
        </div>
        <div className="text-center">
          <span className="text-sm text-main flex items-center justify-center gap-1">
            <Camera size={14} className="text-muted" />
            {walkthrough.totalPhotos}
          </span>
        </div>
        <div>
          <WalkthroughStatusBadge status={walkthrough.status} />
        </div>
        <div>
          <span className="text-sm text-muted">
            {walkthrough.startedAt ? formatDate(walkthrough.startedAt) : '--'}
          </span>
        </div>
        <div />
      </div>
    </div>
  );
}

// ── Card component ──

function WalkthroughCard({ walkthrough, onClick }: { walkthrough: Walkthrough; onClick: () => void }) {
  const fullAddress = [walkthrough.address, walkthrough.city, walkthrough.state]
    .filter(Boolean)
    .join(', ');

  return (
    <Card hover onClick={onClick} className="p-4">
      <div className="flex items-start justify-between gap-2 mb-3">
        <h4 className="font-medium text-main text-sm line-clamp-2">{walkthrough.name}</h4>
        <WalkthroughStatusBadge status={walkthrough.status} />
      </div>
      <div className="space-y-2 mb-3">
        <p className="text-xs text-muted flex items-center gap-1">
          <MapPin size={12} />
          {fullAddress || 'No address'}
        </p>
        <div className="flex items-center gap-1">
          <Badge variant="secondary" size="sm">
            {TYPE_LABELS[walkthrough.walkthroughType] || walkthrough.walkthroughType}
          </Badge>
          {walkthrough.propertyType && (
            <Badge variant="secondary" size="sm">
              {walkthrough.propertyType}
            </Badge>
          )}
        </div>
      </div>
      <div className="flex items-center justify-between text-xs text-muted pt-3 border-t border-main">
        <div className="flex items-center gap-3">
          <span className="flex items-center gap-1">
            <DoorOpen size={12} />
            {walkthrough.totalRooms} rooms
          </span>
          <span className="flex items-center gap-1">
            <Camera size={12} />
            {walkthrough.totalPhotos} photos
          </span>
        </div>
        <span>
          {walkthrough.startedAt ? formatDate(walkthrough.startedAt) : '--'}
        </span>
      </div>
    </Card>
  );
}
