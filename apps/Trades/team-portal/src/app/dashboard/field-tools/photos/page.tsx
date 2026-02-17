'use client';

// ZAFTO Team Portal — Job Site Photos
// Created: Sprint FIELD3 (Session 131)
//
// Browse job photos by date/job. Upload from browser. Lightbox viewer.
// Filter by before/during/after category. Uses photos table + Supabase Storage.

import { useState, useEffect, useCallback, useRef } from 'react';
import Link from 'next/link';
import {
  ArrowLeft,
  Camera,
  ImageIcon,
  X,
  ChevronLeft,
  ChevronRight,
  Upload,
  Loader2,
  AlertTriangle,
  Filter,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';

// ════════════════════════════════════════════════════════════════
// TYPES
// ════════════════════════════════════════════════════════════════

interface PhotoRecord {
  id: string;
  jobId: string | null;
  storagePath: string;
  fileName: string | null;
  category: string;
  caption: string | null;
  takenAt: string | null;
  createdAt: string;
  signedUrl?: string;
  jobTitle?: string;
}

type CategoryFilter = 'all' | 'general' | 'before' | 'after' | 'defect' | 'inspection' | 'completion';

const CATEGORY_OPTIONS: { value: CategoryFilter; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'before', label: 'Before' },
  { value: 'after', label: 'After' },
  { value: 'general', label: 'General' },
  { value: 'defect', label: 'Defect' },
  { value: 'inspection', label: 'Inspection' },
  { value: 'completion', label: 'Completion' },
];

// ════════════════════════════════════════════════════════════════
// MAIN PAGE
// ════════════════════════════════════════════════════════════════

export default function PhotosPage() {
  const [photos, setPhotos] = useState<PhotoRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [category, setCategory] = useState<CategoryFilter>('all');
  const [lightboxIdx, setLightboxIdx] = useState<number | null>(null);
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const fetchPhotos = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      let query = supabase
        .from('photos')
        .select('*, jobs(title)')
        .eq('uploaded_by_user_id', user.id)
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(100);

      if (category !== 'all') {
        query = query.eq('category', category);
      }

      const { data, error: err } = await query;
      if (err) throw err;

      // Get signed URLs for each photo
      const mapped: PhotoRecord[] = [];
      for (const row of (data || [])) {
        const r = row as Record<string, unknown>;
        const jobData = r.jobs as Record<string, unknown> | null;
        const storagePath = r.storage_path as string;

        const { data: urlData } = await supabase.storage
          .from('photos')
          .createSignedUrl(storagePath, 3600);

        mapped.push({
          id: r.id as string,
          jobId: (r.job_id as string) || null,
          storagePath,
          fileName: (r.file_name as string) || null,
          category: (r.category as string) || 'general',
          caption: (r.caption as string) || null,
          takenAt: (r.taken_at as string) || null,
          createdAt: r.created_at as string,
          signedUrl: urlData?.signedUrl || undefined,
          jobTitle: jobData?.title as string | undefined,
        });
      }

      setPhotos(mapped);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load photos');
    } finally {
      setLoading(false);
    }
  }, [category]);

  useEffect(() => {
    fetchPhotos();
  }, [fetchPhotos]);

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const companyId = user.app_metadata?.company_id;
      if (!companyId) throw new Error('No company');

      const ext = file.name.split('.').pop() || 'jpg';
      const path = `${companyId}/${user.id}/${Date.now()}.${ext}`;

      const { error: uploadErr } = await supabase.storage
        .from('photos')
        .upload(path, file, { contentType: file.type });
      if (uploadErr) throw uploadErr;

      const { error: insertErr } = await supabase.from('photos').insert({
        company_id: companyId,
        uploaded_by_user_id: user.id,
        storage_path: path,
        file_name: file.name,
        file_size: file.size,
        mime_type: file.type,
        category: 'general',
      });
      if (insertErr) throw insertErr;

      await fetchPhotos();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Upload failed');
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const filtered = photos;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <Link
          href="/dashboard/field-tools"
          className="inline-flex items-center gap-1.5 text-sm text-muted hover:text-main transition-colors mb-3"
        >
          <ArrowLeft size={16} />
          <span>Field Tools</span>
        </Link>
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-main">Job Site Photos</h1>
            <p className="text-sm text-muted mt-1">Browse and upload job documentation photos</p>
          </div>
          <button
            onClick={() => fileInputRef.current?.click()}
            disabled={uploading}
            className="px-4 py-2 bg-accent text-white rounded-lg text-sm font-medium flex items-center gap-2"
          >
            {uploading ? <Loader2 size={16} className="animate-spin" /> : <Upload size={16} />}
            {uploading ? 'Uploading...' : 'Upload Photo'}
          </button>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            capture="environment"
            className="hidden"
            onChange={handleUpload}
          />
        </div>
      </div>

      {/* Category filter */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {CATEGORY_OPTIONS.map((opt) => (
          <button
            key={opt.value}
            onClick={() => setCategory(opt.value)}
            className={cn(
              'px-3 py-1.5 rounded-lg text-sm whitespace-nowrap border transition-colors',
              category === opt.value
                ? 'border-accent bg-accent/10 text-accent font-medium'
                : 'border-main text-muted hover:text-main',
            )}
          >
            {opt.label}
          </button>
        ))}
      </div>

      {/* Content */}
      {loading ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="aspect-square bg-secondary rounded-lg animate-pulse" />
          ))}
        </div>
      ) : error ? (
        <div className="text-center py-12">
          <AlertTriangle size={40} className="mx-auto text-red-400 mb-3" />
          <p className="text-main font-medium">Failed to load photos</p>
          <p className="text-sm text-muted mt-1">{error}</p>
          <button onClick={fetchPhotos} className="mt-4 px-4 py-2 bg-accent text-white rounded-lg text-sm">
            Retry
          </button>
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16">
          <Camera size={48} className="mx-auto text-muted mb-4" />
          <p className="text-main font-medium">No photos yet</p>
          <p className="text-sm text-muted mt-1">Upload your first job site photo</p>
          <button
            onClick={() => fileInputRef.current?.click()}
            className="mt-4 px-4 py-2 bg-accent text-white rounded-lg text-sm font-medium"
          >
            <Camera size={16} className="inline mr-2" /> Take Photo
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
          {filtered.map((photo, idx) => (
            <button
              key={photo.id}
              onClick={() => setLightboxIdx(idx)}
              className="relative aspect-square rounded-lg overflow-hidden bg-secondary group"
            >
              {photo.signedUrl ? (
                <img
                  src={photo.signedUrl}
                  alt={photo.caption || photo.fileName || 'Photo'}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center">
                  <ImageIcon size={24} className="text-muted" />
                </div>
              )}
              <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/60 to-transparent p-2">
                <span className="text-white text-xs font-medium capitalize">{photo.category}</span>
                {photo.jobTitle && (
                  <p className="text-white/80 text-xs truncate">{photo.jobTitle}</p>
                )}
              </div>
            </button>
          ))}
        </div>
      )}

      {/* Lightbox */}
      {lightboxIdx !== null && filtered[lightboxIdx] && (
        <Lightbox
          photos={filtered}
          index={lightboxIdx}
          onClose={() => setLightboxIdx(null)}
          onPrev={() => setLightboxIdx(Math.max(0, lightboxIdx - 1))}
          onNext={() => setLightboxIdx(Math.min(filtered.length - 1, lightboxIdx + 1))}
        />
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// LIGHTBOX
// ════════════════════════════════════════════════════════════════

function Lightbox({ photos, index, onClose, onPrev, onNext }: {
  photos: PhotoRecord[];
  index: number;
  onClose: () => void;
  onPrev: () => void;
  onNext: () => void;
}) {
  const photo = photos[index];

  return (
    <div className="fixed inset-0 bg-black/90 z-50 flex flex-col" onClick={onClose}>
      {/* Header */}
      <div className="flex items-center justify-between p-4 text-white" onClick={(e) => e.stopPropagation()}>
        <div>
          <p className="text-sm font-medium capitalize">{photo.category}</p>
          {photo.jobTitle && <p className="text-xs text-white/70">{photo.jobTitle}</p>}
          <p className="text-xs text-white/50">{new Date(photo.createdAt).toLocaleDateString()}</p>
        </div>
        <button onClick={onClose} className="p-2 hover:bg-white/10 rounded-lg">
          <X size={20} />
        </button>
      </div>

      {/* Image */}
      <div className="flex-1 flex items-center justify-center px-4" onClick={(e) => e.stopPropagation()}>
        {photo.signedUrl ? (
          <img
            src={photo.signedUrl}
            alt={photo.caption || 'Photo'}
            className="max-w-full max-h-full object-contain"
          />
        ) : (
          <div className="text-white/50 text-center">
            <ImageIcon size={48} className="mx-auto mb-2" />
            <p>Image not available</p>
          </div>
        )}
      </div>

      {/* Navigation */}
      <div className="flex items-center justify-between p-4" onClick={(e) => e.stopPropagation()}>
        <button
          onClick={onPrev}
          disabled={index === 0}
          className="p-3 bg-white/10 rounded-full disabled:opacity-30 text-white"
        >
          <ChevronLeft size={20} />
        </button>
        <p className="text-white/60 text-sm">{index + 1} / {photos.length}</p>
        <button
          onClick={onNext}
          disabled={index === photos.length - 1}
          className="p-3 bg-white/10 rounded-full disabled:opacity-30 text-white"
        >
          <ChevronRight size={20} />
        </button>
      </div>

      {/* Caption */}
      {photo.caption && (
        <div className="px-4 pb-4 text-center" onClick={(e) => e.stopPropagation()}>
          <p className="text-white/80 text-sm">{photo.caption}</p>
        </div>
      )}
    </div>
  );
}
