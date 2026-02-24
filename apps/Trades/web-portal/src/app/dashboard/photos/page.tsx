'use client';

// ZAFTO Photo Gallery — Cross-Feature Wiring (Phase 14)
// Standalone company-wide photo gallery with filtering by category, job, date range,
// and client visibility. Shows stats, thumbnails, and links back to associated jobs.

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  Camera,
  Search,
  Filter,
  Eye,
  EyeOff,
  Calendar,
  Briefcase,
  Tag,
  Image,
  AlertTriangle,
  Loader2,
  ExternalLink,
  Trash2,
  X,
  Grid3X3,
  List,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { SearchInput, Select } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import { usePhotos, type PhotoCategory, type PhotoData } from '@/lib/hooks/use-photos';
import { useJobs } from '@/lib/hooks/use-jobs';
import { useTranslation } from '@/lib/translations';

// ── Category config ──

const CATEGORY_OPTIONS: { value: string; tKey: string; color: string; icon: typeof Camera }[] = [
  { value: '', tKey: 'photos.allCategories', color: '', icon: Camera },
  { value: 'general', tKey: 'photos.categoryGeneral', color: 'bg-secondary text-muted', icon: Image },
  { value: 'before', tKey: 'photos.categoryBefore', color: 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300', icon: Camera },
  { value: 'after', tKey: 'photos.categoryAfter', color: 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300', icon: Camera },
  { value: 'defect', tKey: 'photos.categoryDefect', color: 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300', icon: AlertTriangle },
  { value: 'markup', tKey: 'photos.categoryMarkup', color: 'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300', icon: Tag },
  { value: 'receipt', tKey: 'photos.categoryReceipt', color: 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300', icon: Tag },
  { value: 'inspection', tKey: 'photos.categoryInspection', color: 'bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300', icon: Search },
  { value: 'completion', tKey: 'photos.categoryCompletion', color: 'bg-teal-100 dark:bg-teal-900/30 text-teal-700 dark:text-teal-300', icon: Camera },
];

const CATEGORY_TKEY_MAP: Record<string, string> = {
  general: 'photos.categoryGeneral',
  before: 'photos.categoryBefore',
  after: 'photos.categoryAfter',
  defect: 'photos.categoryDefect',
  markup: 'photos.categoryMarkup',
  receipt: 'photos.categoryReceipt',
  inspection: 'photos.categoryInspection',
  completion: 'photos.categoryCompletion',
};

const CATEGORY_BADGE_VARIANTS: Record<string, 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple'> = {
  general: 'default',
  before: 'warning',
  after: 'success',
  defect: 'error',
  markup: 'purple',
  receipt: 'info',
  inspection: 'info',
  completion: 'success',
};

// ── Main page ──

export default function PhotosGalleryPage() {
  const { t, formatDate } = useTranslation();
  const router = useRouter();

  // Fetch ALL company photos (no jobId filter)
  const { photos, loading, error, updatePhoto, deletePhoto, toggleClientVisible, refresh } = usePhotos();
  const { jobs } = useJobs();

  // Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [jobFilter, setJobFilter] = useState('');
  const [clientVisibleFilter, setClientVisibleFilter] = useState<'all' | 'visible' | 'hidden'>('all');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');

  // Detail modal
  const [selectedPhoto, setSelectedPhoto] = useState<PhotoData | null>(null);
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);

  // Job lookup map for display
  const jobMap = useMemo(() => {
    const map = new Map<string, string>();
    for (const job of jobs) {
      map.set(job.id, job.title || t('photos.untitledJob'));
    }
    return map;
  }, [jobs, t]);

  // Job dropdown options
  const jobOptions = useMemo(() => {
    const uniqueJobIds = new Set(photos.map(p => p.jobId).filter(Boolean));
    return [
      { value: '', label: t('photos.allJobs') },
      ...Array.from(uniqueJobIds).map(id => ({
        value: id,
        label: jobMap.get(id) || id.slice(0, 8),
      })),
    ];
  }, [photos, jobMap, t]);

  // Filtered photos
  const filteredPhotos = useMemo(() => {
    let result = photos;

    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      result = result.filter(p =>
        p.caption.toLowerCase().includes(q) ||
        p.fileName.toLowerCase().includes(q) ||
        p.tags.some(tag => tag.toLowerCase().includes(q))
      );
    }

    if (categoryFilter) {
      result = result.filter(p => p.category === categoryFilter);
    }

    if (jobFilter) {
      result = result.filter(p => p.jobId === jobFilter);
    }

    if (clientVisibleFilter === 'visible') {
      result = result.filter(p => p.isClientVisible);
    } else if (clientVisibleFilter === 'hidden') {
      result = result.filter(p => !p.isClientVisible);
    }

    if (dateFrom) {
      const from = new Date(dateFrom);
      result = result.filter(p => new Date(p.createdAt) >= from);
    }

    if (dateTo) {
      const to = new Date(dateTo);
      to.setHours(23, 59, 59, 999);
      result = result.filter(p => new Date(p.createdAt) <= to);
    }

    return result;
  }, [photos, searchQuery, categoryFilter, jobFilter, clientVisibleFilter, dateFrom, dateTo]);

  // Stats
  const stats = useMemo(() => {
    const byCategory = new Map<string, number>();
    let clientVisibleCount = 0;

    for (const p of photos) {
      byCategory.set(p.category, (byCategory.get(p.category) || 0) + 1);
      if (p.isClientVisible) clientVisibleCount++;
    }

    return { total: photos.length, byCategory, clientVisibleCount };
  }, [photos]);

  const handleDelete = async (id: string) => {
    await deletePhoto(id);
    setDeleteConfirmId(null);
    setSelectedPhoto(null);
  };

  const handleToggleClientVisible = async (id: string, visible: boolean) => {
    await toggleClientVisible(id, visible);
  };

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <CommandPalette />
        <div className="flex items-center justify-center py-20">
          <div className="flex items-center gap-3">
            <Loader2 className="h-5 w-5 animate-spin text-[var(--accent)]" />
            <span className="text-sm text-muted">{t('photos.loadingPhotos')}</span>
          </div>
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
          <h1 className="text-2xl font-semibold text-main">{t('photos.pageTitle')}</h1>
          <p className="text-[13px] text-muted mt-1">
            {t('photos.pageSubtitle')}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setViewMode('grid')}
            className={cn(
              'p-2 rounded-lg border transition-colors',
              viewMode === 'grid'
                ? 'bg-[var(--accent)]/10 border-[var(--accent)]/30 text-[var(--accent)]'
                : 'border-main text-muted hover:text-main'
            )}
            title={t('photos.gridView')}
          >
            <Grid3X3 size={16} />
          </button>
          <button
            onClick={() => setViewMode('list')}
            className={cn(
              'p-2 rounded-lg border transition-colors',
              viewMode === 'list'
                ? 'bg-[var(--accent)]/10 border-[var(--accent)]/30 text-[var(--accent)]'
                : 'border-main text-muted hover:text-main'
            )}
            title={t('photos.listView')}
          >
            <List size={16} />
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
        <Card>
          <CardContent className="p-3">
            <div className="flex items-center gap-2.5">
              <div className="p-1.5 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Camera size={16} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-lg font-semibold text-main">{stats.total}</p>
                <p className="text-[11px] text-muted">{t('photos.totalPhotos')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        {CATEGORY_OPTIONS.slice(1).map(cat => {
          const count = stats.byCategory.get(cat.value) || 0;
          if (count === 0) return null;
          return (
            <Card key={cat.value}>
              <CardContent className="p-3">
                <div className="flex items-center gap-2.5">
                  <Badge variant={CATEGORY_BADGE_VARIANTS[cat.value] || 'default'} size="sm">
                    {t(cat.tKey)}
                  </Badge>
                  <p className="text-lg font-semibold text-main ml-auto">{count}</p>
                </div>
              </CardContent>
            </Card>
          );
        })}
        <Card>
          <CardContent className="p-3">
            <div className="flex items-center gap-2.5">
              <div className="p-1.5 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Eye size={16} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-lg font-semibold text-main">{stats.clientVisibleCount}</p>
                <p className="text-[11px] text-muted">{t('photos.clientVisible')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="p-4">
          <div className="flex items-center gap-2 mb-3">
            <Filter size={14} className="text-muted" />
            <span className="text-xs font-semibold text-muted uppercase tracking-wider">{t('photos.filters')}</span>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-3">
            <SearchInput
              value={searchQuery}
              onChange={setSearchQuery}
              placeholder={t('photos.searchPlaceholder')}
            />
            <Select
              options={CATEGORY_OPTIONS.map(c => ({ value: c.value, label: t(c.tKey) }))}
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
            />
            <Select
              options={jobOptions}
              value={jobFilter}
              onChange={(e) => setJobFilter(e.target.value)}
            />
            <Select
              options={[
                { value: 'all', label: t('photos.allVisibility') },
                { value: 'visible', label: t('photos.clientVisible') },
                { value: 'hidden', label: t('photos.hiddenFromClient') },
              ]}
              value={clientVisibleFilter}
              onChange={(e) => setClientVisibleFilter(e.target.value as 'all' | 'visible' | 'hidden')}
            />
            <div className="space-y-1.5">
              <input
                type="date"
                value={dateFrom}
                onChange={(e) => setDateFrom(e.target.value)}
                className="w-full px-3 py-2 bg-main border border-main rounded-lg text-main text-sm focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors"
                placeholder={t('photos.fromDate')}
              />
            </div>
            <div className="space-y-1.5">
              <input
                type="date"
                value={dateTo}
                onChange={(e) => setDateTo(e.target.value)}
                className="w-full px-3 py-2 bg-main border border-main rounded-lg text-main text-sm focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors"
                placeholder={t('photos.toDate')}
              />
            </div>
          </div>
          {(searchQuery || categoryFilter || jobFilter || clientVisibleFilter !== 'all' || dateFrom || dateTo) && (
            <div className="flex items-center gap-2 mt-3 pt-3 border-t border-main">
              <span className="text-xs text-muted">
                {t('photos.showingOfPhotos', { shown: String(filteredPhotos.length), total: String(photos.length) })}
              </span>
              <button
                onClick={() => {
                  setSearchQuery('');
                  setCategoryFilter('');
                  setJobFilter('');
                  setClientVisibleFilter('all');
                  setDateFrom('');
                  setDateTo('');
                }}
                className="text-xs text-[var(--accent)] hover:underline ml-auto"
              >
                {t('photos.clearAllFilters')}
              </button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Error */}
      {error && (
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2 text-red-500">
              <AlertTriangle size={16} />
              <span className="text-sm">{error}</span>
              <button onClick={refresh} className="ml-auto text-xs text-red-400 hover:text-red-300 underline">
                {t('common.retry')}
              </button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Empty state */}
      {!loading && !error && filteredPhotos.length === 0 && (
        <Card>
          <CardContent className="py-16">
            <div className="text-center">
              <div className="w-14 h-14 rounded-2xl bg-secondary flex items-center justify-center mx-auto mb-4">
                <Camera size={24} className="text-muted" />
              </div>
              <h3 className="text-base font-semibold text-main mb-1">
                {photos.length === 0 ? t('photos.noPhotosYet') : t('photos.noPhotosMatchFilters')}
              </h3>
              <p className="text-sm text-muted max-w-sm mx-auto">
                {photos.length === 0
                  ? t('photos.noPhotosYetDesc')
                  : t('photos.noPhotosMatchFiltersDesc')}
              </p>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Photo Grid */}
      {viewMode === 'grid' && filteredPhotos.length > 0 && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
          {filteredPhotos.map((photo) => (
            <PhotoCard
              key={photo.id}
              photo={photo}
              jobName={jobMap.get(photo.jobId) || null}
              onClick={() => setSelectedPhoto(photo)}
            />
          ))}
        </div>
      )}

      {/* Photo List */}
      {viewMode === 'list' && filteredPhotos.length > 0 && (
        <Card>
          <CardContent className="p-0">
            <div className="divide-y divide-[var(--border)]">
              {filteredPhotos.map((photo) => (
                <PhotoListRow
                  key={photo.id}
                  photo={photo}
                  jobName={jobMap.get(photo.jobId) || null}
                  onClick={() => setSelectedPhoto(photo)}
                  onToggleClientVisible={(visible) => handleToggleClientVisible(photo.id, visible)}
                  onNavigateToJob={() => photo.jobId && router.push(`/dashboard/jobs/${photo.jobId}`)}
                />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Detail Modal */}
      {selectedPhoto && (
        <PhotoDetailModal
          photo={selectedPhoto}
          jobName={jobMap.get(selectedPhoto.jobId) || null}
          onClose={() => setSelectedPhoto(null)}
          onToggleClientVisible={(visible) => {
            handleToggleClientVisible(selectedPhoto.id, visible);
            setSelectedPhoto({ ...selectedPhoto, isClientVisible: visible });
          }}
          onDelete={() => setDeleteConfirmId(selectedPhoto.id)}
          onNavigateToJob={() => {
            if (selectedPhoto.jobId) {
              router.push(`/dashboard/jobs/${selectedPhoto.jobId}`);
            }
          }}
        />
      )}

      {/* Delete Confirmation */}
      {deleteConfirmId && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/60 backdrop-blur-sm">
          <div className="bg-main border border-main rounded-xl p-6 max-w-sm w-full mx-4 shadow-2xl">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-xl bg-red-100 dark:bg-red-900/20 flex items-center justify-center">
                <Trash2 size={18} className="text-red-500" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-main">{t('photos.deletePhoto')}</h3>
                <p className="text-xs text-muted">{t('common.cannotUndo')}</p>
              </div>
            </div>
            <p className="text-sm text-muted mb-6">
              {t('photos.deletePhotoConfirm')}
            </p>
            <div className="flex items-center gap-3 justify-end">
              <button
                onClick={() => setDeleteConfirmId(null)}
                className="px-4 py-2 text-sm font-medium text-muted hover:text-main transition-colors"
              >
                {t('common.cancel')}
              </button>
              <button
                onClick={() => handleDelete(deleteConfirmId)}
                className="px-4 py-2 text-sm font-semibold text-white bg-red-600 hover:bg-red-500 rounded-lg transition-colors"
              >
                {t('common.delete')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// =============================================================================
// PHOTO CARD (grid view)
// =============================================================================

function PhotoCard({
  photo,
  jobName,
  onClick,
}: {
  photo: PhotoData;
  jobName: string | null;
  onClick: () => void;
}) {
  const { t, formatDate } = useTranslation();
  return (
    <div
      onClick={onClick}
      className="group relative rounded-xl border border-main bg-secondary overflow-hidden cursor-pointer hover:border-[var(--accent)]/30 transition-all"
    >
      {/* Thumbnail */}
      <div className="aspect-square bg-secondary relative overflow-hidden">
        {photo.signedUrl ? (
          <img
            src={photo.signedUrl}
            alt={photo.caption || photo.fileName}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
            loading="lazy"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <Image size={24} className="text-muted" />
          </div>
        )}

        {/* Category badge — top left */}
        <div className="absolute top-2 left-2">
          <Badge variant={CATEGORY_BADGE_VARIANTS[photo.category] || 'default'} size="sm">
            {t(CATEGORY_TKEY_MAP[photo.category] || 'photos.categoryGeneral')}
          </Badge>
        </div>

        {/* Client visibility indicator — top right */}
        <div className="absolute top-2 right-2">
          {photo.isClientVisible ? (
            <div className="p-1 bg-emerald-500/80 rounded-full" title={t('photos.clientVisible')}>
              <Eye size={10} className="text-white" />
            </div>
          ) : (
            <div className="p-1 bg-surface-hover/60 rounded-full" title={t('photos.hiddenFromClient')}>
              <EyeOff size={10} className="text-white" />
            </div>
          )}
        </div>

        {/* Hover overlay */}
        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors" />
      </div>

      {/* Details */}
      <div className="px-2.5 py-2">
        {photo.caption && (
          <p className="text-xs font-medium text-main truncate">{photo.caption}</p>
        )}
        <div className="flex items-center gap-2 mt-1">
          {jobName && (
            <span className="text-[10px] text-[var(--accent)] truncate flex items-center gap-0.5">
              <Briefcase size={9} />
              {jobName}
            </span>
          )}
          <span className="text-[10px] text-muted ml-auto flex items-center gap-0.5">
            <Calendar size={9} />
            {formatDate(photo.createdAt)}
          </span>
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// PHOTO LIST ROW (list view)
// =============================================================================

function PhotoListRow({
  photo,
  jobName,
  onClick,
  onToggleClientVisible,
  onNavigateToJob,
}: {
  photo: PhotoData;
  jobName: string | null;
  onClick: () => void;
  onToggleClientVisible: (visible: boolean) => void;
  onNavigateToJob: () => void;
}) {
  const { t, formatDate } = useTranslation();
  return (
    <div
      className="flex items-center gap-4 px-4 py-3 hover:bg-[var(--bg-hover)] transition-colors cursor-pointer"
      onClick={onClick}
    >
      {/* Thumbnail */}
      <div className="w-12 h-12 rounded-lg bg-secondary overflow-hidden flex-shrink-0">
        {photo.signedUrl ? (
          <img
            src={photo.signedUrl}
            alt={photo.caption || photo.fileName}
            className="w-full h-full object-cover"
            loading="lazy"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <Image size={16} className="text-muted" />
          </div>
        )}
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <p className="text-sm font-medium text-main truncate">
            {photo.caption || photo.fileName}
          </p>
          <Badge variant={CATEGORY_BADGE_VARIANTS[photo.category] || 'default'} size="sm">
            {t(CATEGORY_TKEY_MAP[photo.category] || 'photos.categoryGeneral')}
          </Badge>
        </div>
        <div className="flex items-center gap-3 mt-0.5">
          {jobName && (
            <button
              onClick={(e) => { e.stopPropagation(); onNavigateToJob(); }}
              className="text-[11px] text-[var(--accent)] hover:underline flex items-center gap-0.5"
            >
              <Briefcase size={10} />
              {jobName}
            </button>
          )}
          <span className="text-[11px] text-muted">{formatDate(photo.createdAt)}</span>
          {photo.tags.length > 0 && (
            <span className="text-[11px] text-muted flex items-center gap-0.5">
              <Tag size={10} />
              {photo.tags.slice(0, 3).join(', ')}
            </span>
          )}
        </div>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-2 flex-shrink-0">
        <button
          onClick={(e) => { e.stopPropagation(); onToggleClientVisible(!photo.isClientVisible); }}
          className={cn(
            'p-1.5 rounded-lg border transition-colors',
            photo.isClientVisible
              ? 'bg-emerald-100 dark:bg-emerald-900/30 border-emerald-200 dark:border-emerald-800 text-emerald-600 dark:text-emerald-400'
              : 'border-main text-muted hover:text-main'
          )}
          title={photo.isClientVisible ? t('photos.visibleClickToHide') : t('photos.hiddenClickToShow')}
        >
          {photo.isClientVisible ? <Eye size={14} /> : <EyeOff size={14} />}
        </button>
      </div>
    </div>
  );
}

// =============================================================================
// PHOTO DETAIL MODAL
// =============================================================================

function PhotoDetailModal({
  photo,
  jobName,
  onClose,
  onToggleClientVisible,
  onDelete,
  onNavigateToJob,
}: {
  photo: PhotoData;
  jobName: string | null;
  onClose: () => void;
  onToggleClientVisible: (visible: boolean) => void;
  onDelete: () => void;
  onNavigateToJob: () => void;
}) {
  const { t, formatDate } = useTranslation();
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm" onClick={onClose}>
      <div
        className="bg-main border border-main rounded-2xl shadow-2xl max-w-3xl w-full mx-4 max-h-[90vh] flex flex-col overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-main">
          <div className="flex items-center gap-3 min-w-0">
            <Camera size={18} className="text-[var(--accent)] flex-shrink-0" />
            <div className="min-w-0">
              <h2 className="text-sm font-semibold text-main truncate">
                {photo.caption || photo.fileName}
              </h2>
              <div className="flex items-center gap-2 mt-0.5">
                <Badge variant={CATEGORY_BADGE_VARIANTS[photo.category] || 'default'} size="sm">
                  {t(CATEGORY_TKEY_MAP[photo.category] || 'photos.categoryGeneral')}
                </Badge>
                <span className="text-[11px] text-muted">{formatDate(photo.createdAt)}</span>
              </div>
            </div>
          </div>
          <button onClick={onClose} className="p-1.5 rounded-lg text-muted hover:text-main hover:bg-[var(--bg-hover)] transition-colors">
            <X size={16} />
          </button>
        </div>

        {/* Image */}
        <div className="flex-1 overflow-auto bg-surface flex items-center justify-center min-h-[300px]">
          {photo.signedUrl ? (
            <img
              src={photo.signedUrl}
              alt={photo.caption || photo.fileName}
              className="max-w-full max-h-[60vh] object-contain"
            />
          ) : (
            <div className="text-center">
              <Image size={48} className="text-muted mx-auto mb-2" />
              <p className="text-sm text-muted">{t('photos.imageNotAvailable')}</p>
            </div>
          )}
        </div>

        {/* Details */}
        <div className="px-5 py-4 border-t border-main space-y-3">
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
            <div>
              <span className="text-muted block">{t('photos.fileName')}</span>
              <span className="text-main font-medium truncate block">{photo.fileName}</span>
            </div>
            <div>
              <span className="text-muted block">{t('photos.fileSize')}</span>
              <span className="text-main font-medium">{formatFileSize(photo.fileSize)}</span>
            </div>
            <div>
              <span className="text-muted block">{t('photos.dimensions')}</span>
              <span className="text-main font-medium">
                {photo.width && photo.height ? `${photo.width} x ${photo.height}` : t('common.unknown')}
              </span>
            </div>
            <div>
              <span className="text-muted block">{t('common.type')}</span>
              <span className="text-main font-medium">{photo.mimeType || t('common.unknown')}</span>
            </div>
          </div>

          {photo.tags.length > 0 && (
            <div className="flex items-center gap-1.5 flex-wrap">
              <Tag size={12} className="text-muted" />
              {photo.tags.map(tag => (
                <Badge key={tag} variant="secondary" size="sm">{tag}</Badge>
              ))}
            </div>
          )}

          {photo.latitude && photo.longitude && (
            <div className="text-xs text-muted">
              {t('photos.gpsCoordinates', { lat: photo.latitude.toFixed(6), lng: photo.longitude.toFixed(6) })}
            </div>
          )}
        </div>

        {/* Actions */}
        <div className="flex items-center justify-between px-5 py-3 border-t border-main">
          <div className="flex items-center gap-2">
            {jobName && (
              <button
                onClick={onNavigateToJob}
                className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-[var(--accent)] border border-[var(--accent)]/30 rounded-lg hover:bg-[var(--accent)]/10 transition-colors"
              >
                <ExternalLink size={12} />
                {t('photos.goToJob')}
              </button>
            )}
            <button
              onClick={() => onToggleClientVisible(!photo.isClientVisible)}
              className={cn(
                'flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg border transition-colors',
                photo.isClientVisible
                  ? 'text-emerald-600 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800 bg-emerald-50 dark:bg-emerald-900/20'
                  : 'text-muted border-main hover:text-main hover:bg-[var(--bg-hover)]'
              )}
            >
              {photo.isClientVisible ? <Eye size={12} /> : <EyeOff size={12} />}
              {photo.isClientVisible ? t('photos.clientVisible') : t('photos.hiddenFromClient')}
            </button>
          </div>
          <button
            onClick={onDelete}
            className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-red-500 border border-red-200 dark:border-red-800 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
          >
            <Trash2 size={12} />
            {t('common.delete')}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Utility ──

function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${(bytes / Math.pow(1024, i)).toFixed(1)} ${sizes[i]}`;
}
