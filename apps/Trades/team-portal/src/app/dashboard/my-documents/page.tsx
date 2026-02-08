'use client';

import { useState } from 'react';
import {
  FileText, Download, Search, FolderOpen,
  File, FileSpreadsheet, FileImage, Eye,
} from 'lucide-react';
import { useMyDocuments, CATEGORY_LABELS, CATEGORY_COLORS, formatFileSize } from '@/lib/hooks/use-my-documents';
import type { DocumentData, DocumentCategory } from '@/lib/hooks/use-my-documents';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { cn, formatDate } from '@/lib/utils';

// ============================================================
// SKELETON
// ============================================================

function DocumentsSkeleton() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div className="h-8 w-48 bg-surface-hover animate-pulse rounded" />
      <div className="grid grid-cols-3 gap-4">
        {[...Array(3)].map((_, i) => <div key={i} className="h-20 bg-surface-hover animate-pulse rounded-xl" />)}
      </div>
      <div className="space-y-3">
        {[...Array(5)].map((_, i) => <div key={i} className="h-16 bg-surface-hover animate-pulse rounded-xl" />)}
      </div>
    </div>
  );
}

// ============================================================
// HELPERS
// ============================================================

type FilterCategory = 'all' | DocumentCategory;

function getFileIcon(fileType: string) {
  const type = fileType.toLowerCase();
  if (type.includes('pdf')) return FileText;
  if (type.includes('sheet') || type.includes('csv') || type.includes('excel') || type.includes('xlsx')) return FileSpreadsheet;
  if (type.includes('image') || type.includes('png') || type.includes('jpg') || type.includes('jpeg')) return FileImage;
  return File;
}

function getFileTypeBadge(fileType: string): { label: string; variant: 'default' | 'info' | 'success' | 'warning' | 'error' } {
  const type = fileType.toLowerCase();
  if (type.includes('pdf')) return { label: 'PDF', variant: 'error' };
  if (type.includes('sheet') || type.includes('csv') || type.includes('xlsx')) return { label: 'Spreadsheet', variant: 'success' };
  if (type.includes('image') || type.includes('png') || type.includes('jpg')) return { label: 'Image', variant: 'info' };
  if (type.includes('doc') || type.includes('word')) return { label: 'Document', variant: 'info' };
  return { label: fileType || 'File', variant: 'default' };
}

// ============================================================
// MAIN PAGE
// ============================================================

export default function MyDocumentsPage() {
  const { documents, byCategory, loading, error, getDownloadUrl } = useMyDocuments();
  const [filter, setFilter] = useState<FilterCategory>('all');
  const [search, setSearch] = useState('');
  const [downloading, setDownloading] = useState<string | null>(null);

  if (loading) return <DocumentsSkeleton />;

  // Filter documents
  const filtered = documents.filter(doc => {
    if (filter !== 'all' && doc.category !== filter) return false;
    if (search) {
      const q = search.toLowerCase();
      return doc.name.toLowerCase().includes(q) ||
        doc.fileName.toLowerCase().includes(q) ||
        doc.description.toLowerCase().includes(q);
    }
    return true;
  });

  // Category counts
  const categoryCounts: Record<string, number> = { all: documents.length };
  Object.entries(byCategory).forEach(([cat, docs]) => {
    if (docs.length > 0) categoryCounts[cat] = docs.length;
  });

  // Active filter categories (only show tabs with docs + "all")
  const activeCategories: { key: FilterCategory; label: string; count: number }[] = [
    { key: 'all', label: 'All', count: documents.length },
  ];
  (Object.keys(CATEGORY_LABELS) as DocumentCategory[]).forEach(cat => {
    const count = byCategory[cat]?.length || 0;
    if (count > 0) {
      activeCategories.push({ key: cat, label: CATEGORY_LABELS[cat], count });
    }
  });

  const handleDownload = async (doc: DocumentData) => {
    setDownloading(doc.id);
    try {
      const url = await getDownloadUrl(doc.storagePath);
      window.open(url, '_blank');
    } catch {
      // Error is handled silently — could add toast
    } finally {
      setDownloading(null);
    }
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-main">My Documents</h1>
        <p className="text-sm text-muted mt-1">
          Your pay stubs, contracts, training certs, and job documents
        </p>
      </div>

      {error && (
        <div className="px-4 py-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Category Summary */}
      {documents.length > 0 && (
        <div className="grid grid-cols-3 sm:grid-cols-6 gap-3">
          {(Object.keys(CATEGORY_LABELS) as DocumentCategory[]).map(cat => {
            const count = byCategory[cat]?.length || 0;
            const colors = CATEGORY_COLORS[cat];
            return (
              <button
                key={cat}
                onClick={() => setFilter(filter === cat ? 'all' : cat)}
                className={cn(
                  'bg-surface border rounded-xl p-3 text-center transition-all',
                  filter === cat ? 'border-accent ring-2 ring-accent/20' : 'border-main hover:border-accent/40'
                )}
              >
                <div className={cn('w-8 h-8 rounded-lg mx-auto mb-1.5 flex items-center justify-center', colors.bg)}>
                  <FolderOpen size={16} className={colors.text} />
                </div>
                <div className="text-lg font-bold text-main">{count}</div>
                <div className="text-[10px] text-muted leading-tight">{CATEGORY_LABELS[cat]}</div>
              </button>
            );
          })}
        </div>
      )}

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
        <input
          type="text"
          placeholder="Search documents..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="w-full pl-9 pr-4 py-2.5 rounded-lg border border-main bg-surface text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/30"
        />
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2 flex-wrap">
        {activeCategories.map(tab => (
          <button
            key={tab.key}
            onClick={() => setFilter(tab.key)}
            className={cn(
              'px-3 py-2 rounded-lg text-xs font-medium transition-colors',
              filter === tab.key
                ? 'bg-accent/10 text-accent'
                : 'text-muted hover:text-main hover:bg-surface-hover'
            )}
          >
            {tab.label}
            <span className="ml-1 opacity-60">({tab.count})</span>
          </button>
        ))}
      </div>

      {/* Documents List */}
      {filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16">
          <FileText size={40} className="text-muted opacity-30 mb-3" />
          <p className="text-main font-medium">
            {documents.length === 0 ? 'No documents' : 'No matching documents'}
          </p>
          <p className="text-sm text-muted mt-1">
            {documents.length === 0 ? 'Documents shared with you will appear here.' : 'Try adjusting your search or filter.'}
          </p>
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map(doc => {
            const FileIcon = getFileIcon(doc.fileType);
            const typeBadge = getFileTypeBadge(doc.fileType);
            const catColors = CATEGORY_COLORS[doc.category] || CATEGORY_COLORS.other;
            const isDownloading = downloading === doc.id;

            return (
              <Card key={doc.id}>
                <CardContent className="py-3.5">
                  <div className="flex items-center gap-3">
                    <div className={cn('p-2 rounded-lg flex-shrink-0', catColors.bg)}>
                      <FileIcon size={18} className={catColors.text} />
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <p className="text-sm font-medium text-main truncate">{doc.name}</p>
                        <Badge variant={typeBadge.variant}>{typeBadge.label}</Badge>
                        <span className={cn('px-1.5 py-0.5 rounded text-[10px] font-medium', catColors.bg, catColors.text)}>
                          {CATEGORY_LABELS[doc.category] || doc.category}
                        </span>
                      </div>
                      <div className="flex items-center gap-3 text-xs text-muted">
                        <span>{formatDate(doc.createdAt)}</span>
                        {doc.fileSize > 0 && <span>{formatFileSize(doc.fileSize)}</span>}
                        {doc.fileName && (
                          <span className="truncate max-w-[200px]">{doc.fileName}</span>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-1 flex-shrink-0">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleDownload(doc)}
                        disabled={isDownloading}
                        title="Download"
                      >
                        {isDownloading ? (
                          <svg className="animate-spin h-4 w-4 text-muted" fill="none" viewBox="0 0 24 24">
                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                          </svg>
                        ) : (
                          <Download size={16} className="text-muted" />
                        )}
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
