'use client';

import { useState, useEffect, useMemo, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  MapPin,
  Camera,
  DoorOpen,
  Clock,
  User,
  Briefcase,
  FileText,
  Star,
  ChevronDown,
  ChevronRight,
  X,
  Download,
  Archive,
  CloudSun,
  Thermometer,
  Droplets,
  Wind,
  Maximize2,
  Layers,
  StickyNote,
  AlertCircle,
  Loader2,
  ExternalLink,
  Grid3x3,
  Ruler,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { cn, formatDate, formatDateTime } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import {
  useWalkthrough,
  useWalkthroughs,
  type Walkthrough,
  type WalkthroughRoom,
  type WalkthroughPhoto,
  type FloorPlan,
  type FloorPlanData,
} from '@/lib/hooks/use-walkthroughs';

// ── Status badges ──

const STATUS_CONFIG: Record<string, { label: string; bg: string; text: string; dot: string }> = {
  in_progress: { label: 'In Progress', bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-700 dark:text-amber-300', dot: 'bg-amber-500' },
  completed: { label: 'Completed', bg: 'bg-emerald-100 dark:bg-emerald-900/30', text: 'text-emerald-700 dark:text-emerald-300', dot: 'bg-emerald-500' },
  uploaded: { label: 'Uploaded', bg: 'bg-blue-100 dark:bg-blue-900/30', text: 'text-blue-700 dark:text-blue-300', dot: 'bg-blue-500' },
  bid_generated: { label: 'Bid Generated', bg: 'bg-purple-100 dark:bg-purple-900/30', text: 'text-purple-700 dark:text-purple-300', dot: 'bg-purple-500' },
  archived: { label: 'Archived', bg: 'bg-slate-100 dark:bg-slate-800', text: 'text-slate-600 dark:text-slate-400', dot: 'bg-slate-400' },
};

const ROOM_STATUS_CONFIG: Record<string, { label: string; bg: string; text: string }> = {
  pending: { label: 'Pending', bg: 'bg-slate-100 dark:bg-slate-800', text: 'text-slate-600 dark:text-slate-400' },
  in_progress: { label: 'In Progress', bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-700 dark:text-amber-300' },
  completed: { label: 'Completed', bg: 'bg-emerald-100 dark:bg-emerald-900/30', text: 'text-emerald-700 dark:text-emerald-300' },
  skipped: { label: 'Skipped', bg: 'bg-red-100 dark:bg-red-900/30', text: 'text-red-600 dark:text-red-400' },
};

const PHOTO_TYPE_LABELS: Record<string, string> = {
  overview: 'Overview',
  detail: 'Detail',
  damage: 'Damage',
  measurement: 'Measurement',
  before: 'Before',
  after: 'After',
  exterior: 'Exterior',
  interior: 'Interior',
};

const TYPE_LABELS: Record<string, string> = {
  general: 'General',
  insurance: 'Insurance',
  maintenance: 'Maintenance',
  pre_purchase: 'Pre-Purchase',
  renovation: 'Renovation',
  restoration: 'Restoration',
};

// ── Tabs ──

type TabKey = 'rooms' | 'photos' | 'floor_plan' | 'notes';

const TABS: { key: TabKey; label: string; icon: React.ElementType }[] = [
  { key: 'rooms', label: 'Rooms', icon: DoorOpen },
  { key: 'photos', label: 'Photos', icon: Camera },
  { key: 'floor_plan', label: 'Floor Plan', icon: Layers },
  { key: 'notes', label: 'Notes', icon: StickyNote },
];

export default function WalkthroughDetailPage() {
  const params = useParams();
  const router = useRouter();
  const walkthroughId = params.id as string;

  const { walkthrough, loading: walkthroughLoading, error: walkthroughError } = useWalkthrough(walkthroughId);
  const { rooms, photos, floorPlans, fetchRooms, fetchPhotos, fetchFloorPlans, archiveWalkthrough } = useWalkthroughs();

  const [activeTab, setActiveTab] = useState<TabKey>('rooms');
  const [expandedRooms, setExpandedRooms] = useState<Set<string>>(new Set());
  const [lightboxPhoto, setLightboxPhoto] = useState<WalkthroughPhoto | null>(null);
  const [photoRoomFilter, setPhotoRoomFilter] = useState<string>('all');
  const [archiving, setArchiving] = useState(false);

  // Fetch related data when walkthrough loads
  useEffect(() => {
    if (walkthroughId) {
      fetchRooms(walkthroughId);
      fetchPhotos(walkthroughId);
      fetchFloorPlans(walkthroughId);
    }
  }, [walkthroughId, fetchRooms, fetchPhotos, fetchFloorPlans]);

  // ── Photo URL helper ──
  const getPhotoUrl = useCallback((storagePath: string) => {
    if (!storagePath) return '';
    const supabase = getSupabase();
    const { data } = supabase.storage.from('walkthrough-photos').getPublicUrl(storagePath);
    return data?.publicUrl || '';
  }, []);

  // ── Room photos map ──
  const photosByRoom = useMemo(() => {
    const map = new Map<string, WalkthroughPhoto[]>();
    for (const photo of photos) {
      const key = photo.roomId || 'unassigned';
      const existing = map.get(key) || [];
      existing.push(photo);
      map.set(key, existing);
    }
    return map;
  }, [photos]);

  // ── Filtered photos (for photos tab) ──
  const filteredPhotos = useMemo(() => {
    if (photoRoomFilter === 'all') return photos;
    if (photoRoomFilter === 'unassigned') return photos.filter((p) => !p.roomId);
    return photos.filter((p) => p.roomId === photoRoomFilter);
  }, [photos, photoRoomFilter]);

  // ── Toggle room expand ──
  const toggleRoom = (roomId: string) => {
    setExpandedRooms((prev) => {
      const next = new Set(prev);
      if (next.has(roomId)) {
        next.delete(roomId);
      } else {
        next.add(roomId);
      }
      return next;
    });
  };

  // ── Archive handler ──
  const handleArchive = async () => {
    if (!walkthroughId) return;
    setArchiving(true);
    try {
      await archiveWalkthrough(walkthroughId);
      router.push('/dashboard/walkthroughs');
    } catch {
      setArchiving(false);
    }
  };

  // ── Loading state ──
  if (walkthroughLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="w-6 h-6 text-muted animate-spin" />
      </div>
    );
  }

  if (walkthroughError || !walkthrough) {
    return (
      <div className="text-center py-16 text-muted">
        <AlertCircle className="w-12 h-12 mx-auto mb-3 opacity-50" />
        <p className="text-lg font-medium">Walkthrough not found</p>
        <button
          onClick={() => router.push('/dashboard/walkthroughs')}
          className="text-sm text-[var(--accent)] hover:underline mt-2"
        >
          Back to walkthroughs
        </button>
      </div>
    );
  }

  const statusConfig = STATUS_CONFIG[walkthrough.status] || STATUS_CONFIG.in_progress;
  const fullAddress = [walkthrough.address, walkthrough.city, walkthrough.state, walkthrough.zipCode]
    .filter(Boolean)
    .join(', ');

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Lightbox */}
      {lightboxPhoto && (
        <PhotoLightbox
          photo={lightboxPhoto}
          getPhotoUrl={getPhotoUrl}
          onClose={() => setLightboxPhoto(null)}
        />
      )}

      {/* Header */}
      <div className="flex items-start justify-between gap-4">
        <div className="flex items-start gap-3">
          <button
            onClick={() => router.push('/dashboard/walkthroughs')}
            className="p-2 rounded-lg hover:bg-surface-hover text-muted transition-colors mt-0.5"
          >
            <ArrowLeft size={18} />
          </button>
          <div>
            <div className="flex items-center gap-3 mb-1">
              <h1 className="text-2xl font-semibold text-main">{walkthrough.name}</h1>
              <span className={cn('inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-medium rounded-full', statusConfig.bg, statusConfig.text)}>
                <span className={cn('w-1.5 h-1.5 rounded-full', statusConfig.dot)} />
                {statusConfig.label}
              </span>
              <Badge variant="secondary" size="sm">
                {TYPE_LABELS[walkthrough.walkthroughType] || walkthrough.walkthroughType}
              </Badge>
            </div>
            <div className="flex items-center gap-4 text-sm text-muted">
              {fullAddress && (
                <span className="flex items-center gap-1">
                  <MapPin size={14} />
                  {fullAddress}
                </span>
              )}
              {walkthrough.startedAt && (
                <span className="flex items-center gap-1">
                  <Clock size={14} />
                  Started {formatDate(walkthrough.startedAt)}
                </span>
              )}
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
        </div>
        <div className="flex items-center gap-2 flex-shrink-0">
          <Button
            variant="outline"
            size="sm"
            onClick={() => router.push(`/dashboard/walkthroughs/${walkthroughId}/bid`)}
          >
            <FileText size={14} />
            Generate Bid
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={handleArchive}
            loading={archiving}
            disabled={walkthrough.status === 'archived'}
          >
            <Archive size={14} />
            Archive
          </Button>
          <Button variant="ghost" size="sm">
            <Download size={14} />
            Download Report
          </Button>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-main">
        <div className="flex items-center gap-1">
          {TABS.map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors',
                activeTab === tab.key
                  ? 'border-[var(--accent)] text-[var(--accent)]'
                  : 'border-transparent text-muted hover:text-main hover:border-main/50'
              )}
            >
              <tab.icon size={16} />
              {tab.label}
              {tab.key === 'rooms' && (
                <span className="ml-1 text-xs text-muted bg-secondary px-1.5 py-0.5 rounded-full">
                  {rooms.length}
                </span>
              )}
              {tab.key === 'photos' && (
                <span className="ml-1 text-xs text-muted bg-secondary px-1.5 py-0.5 rounded-full">
                  {photos.length}
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Tab content */}
      {activeTab === 'rooms' && (
        <RoomsTab
          rooms={rooms}
          photosByRoom={photosByRoom}
          expandedRooms={expandedRooms}
          onToggleRoom={toggleRoom}
          onPhotoClick={setLightboxPhoto}
          getPhotoUrl={getPhotoUrl}
        />
      )}

      {activeTab === 'photos' && (
        <PhotosTab
          photos={filteredPhotos}
          rooms={rooms}
          photoRoomFilter={photoRoomFilter}
          onRoomFilterChange={setPhotoRoomFilter}
          onPhotoClick={setLightboxPhoto}
          getPhotoUrl={getPhotoUrl}
        />
      )}

      {activeTab === 'floor_plan' && (
        <FloorPlanTab floorPlans={floorPlans} />
      )}

      {activeTab === 'notes' && (
        <NotesTab walkthrough={walkthrough} rooms={rooms} />
      )}
    </div>
  );
}

// ============================================================
// ROOMS TAB
// ============================================================

function RoomsTab({
  rooms,
  photosByRoom,
  expandedRooms,
  onToggleRoom,
  onPhotoClick,
  getPhotoUrl,
}: {
  rooms: WalkthroughRoom[];
  photosByRoom: Map<string, WalkthroughPhoto[]>;
  expandedRooms: Set<string>;
  onToggleRoom: (id: string) => void;
  onPhotoClick: (photo: WalkthroughPhoto) => void;
  getPhotoUrl: (path: string) => string;
}) {
  if (rooms.length === 0) {
    return (
      <Card>
        <CardContent className="py-12 text-center text-muted">
          <DoorOpen size={40} className="mx-auto mb-3 opacity-50" />
          <p className="text-lg font-medium">No rooms recorded</p>
          <p className="text-sm mt-1">Rooms are added during the walkthrough on the mobile app</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      {rooms.map((room) => {
        const isExpanded = expandedRooms.has(room.id);
        const roomPhotos = photosByRoom.get(room.id) || [];
        const statusConf = ROOM_STATUS_CONFIG[room.status] || ROOM_STATUS_CONFIG.pending;

        return (
          <Card key={room.id} className="overflow-hidden">
            {/* Room header */}
            <button
              onClick={() => onToggleRoom(room.id)}
              className="w-full flex items-center justify-between px-5 py-4 hover:bg-surface-hover transition-colors text-left"
            >
              <div className="flex items-center gap-3 min-w-0">
                {isExpanded ? (
                  <ChevronDown size={16} className="text-muted flex-shrink-0" />
                ) : (
                  <ChevronRight size={16} className="text-muted flex-shrink-0" />
                )}
                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="font-medium text-main truncate">{room.name}</h3>
                    <span className={cn('px-2 py-0.5 text-[10px] font-medium rounded-full', statusConf.bg, statusConf.text)}>
                      {statusConf.label}
                    </span>
                  </div>
                  <div className="flex items-center gap-3 mt-0.5 text-xs text-muted">
                    {room.roomType && <span>{room.roomType}</span>}
                    {room.floorLevel && <span>Floor: {room.floorLevel}</span>}
                    <span className="flex items-center gap-1">
                      <Camera size={10} />
                      {room.photoCount} photos
                    </span>
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-3 flex-shrink-0">
                {room.conditionRating != null && (
                  <div className="flex items-center gap-1">
                    {[1, 2, 3, 4, 5].map((s) => (
                      <Star
                        key={s}
                        size={12}
                        className={cn(
                          s <= (room.conditionRating || 0)
                            ? 'text-amber-400 fill-amber-400'
                            : 'text-slate-300 dark:text-slate-600'
                        )}
                      />
                    ))}
                  </div>
                )}
              </div>
            </button>

            {/* Expanded content */}
            {isExpanded && (
              <div className="border-t border-main px-5 py-4 space-y-4">
                {/* Dimensions */}
                {room.dimensions && (
                  <div className="flex items-center gap-4 text-sm">
                    <Ruler size={14} className="text-muted" />
                    <div className="flex items-center gap-3 text-muted">
                      {room.dimensions.length != null && (
                        <span>L: {room.dimensions.length} ft</span>
                      )}
                      {room.dimensions.width != null && (
                        <span>W: {room.dimensions.width} ft</span>
                      )}
                      {room.dimensions.height != null && (
                        <span>H: {room.dimensions.height} ft</span>
                      )}
                      {room.dimensions.area != null && (
                        <span className="font-medium text-main">
                          {room.dimensions.area} sq ft
                        </span>
                      )}
                    </div>
                  </div>
                )}

                {/* Notes */}
                {room.notes && (
                  <div className="text-sm text-muted bg-secondary rounded-lg px-3 py-2">
                    {room.notes}
                  </div>
                )}

                {/* Tags */}
                {room.tags.length > 0 && (
                  <div className="flex flex-wrap gap-1.5">
                    {room.tags.map((tag) => (
                      <Badge key={tag} variant="secondary" size="sm">
                        {tag}
                      </Badge>
                    ))}
                  </div>
                )}

                {/* Photos grid */}
                {roomPhotos.length > 0 ? (
                  <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                    {roomPhotos.map((photo) => (
                      <button
                        key={photo.id}
                        onClick={() => onPhotoClick(photo)}
                        className="relative aspect-square rounded-lg overflow-hidden bg-secondary hover:ring-2 hover:ring-[var(--accent)] transition-all group"
                      >
                        <img
                          src={getPhotoUrl(photo.thumbnailPath || photo.storagePath)}
                          alt={photo.caption || 'Walkthrough photo'}
                          className="w-full h-full object-cover"
                        />
                        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors flex items-center justify-center">
                          <Maximize2 size={16} className="text-white opacity-0 group-hover:opacity-100 transition-opacity" />
                        </div>
                        {photo.photoType && photo.photoType !== 'overview' && (
                          <span className="absolute bottom-1 left-1 px-1.5 py-0.5 text-[9px] font-medium bg-black/60 text-white rounded">
                            {PHOTO_TYPE_LABELS[photo.photoType] || photo.photoType}
                          </span>
                        )}
                      </button>
                    ))}
                  </div>
                ) : (
                  <p className="text-sm text-muted/60">No photos for this room</p>
                )}
              </div>
            )}
          </Card>
        );
      })}
    </div>
  );
}

// ============================================================
// PHOTOS TAB
// ============================================================

function PhotosTab({
  photos,
  rooms,
  photoRoomFilter,
  onRoomFilterChange,
  onPhotoClick,
  getPhotoUrl,
}: {
  photos: WalkthroughPhoto[];
  rooms: WalkthroughRoom[];
  photoRoomFilter: string;
  onRoomFilterChange: (filter: string) => void;
  onPhotoClick: (photo: WalkthroughPhoto) => void;
  getPhotoUrl: (path: string) => string;
}) {
  if (photos.length === 0 && photoRoomFilter === 'all') {
    return (
      <Card>
        <CardContent className="py-12 text-center text-muted">
          <Camera size={40} className="mx-auto mb-3 opacity-50" />
          <p className="text-lg font-medium">No photos captured</p>
          <p className="text-sm mt-1">Photos are taken during the walkthrough on the mobile app</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {/* Room filter */}
      <div className="flex items-center gap-2 flex-wrap">
        <button
          onClick={() => onRoomFilterChange('all')}
          className={cn(
            'px-3 py-1.5 text-sm rounded-lg border transition-colors',
            photoRoomFilter === 'all'
              ? 'bg-[var(--accent)] text-white border-[var(--accent)]'
              : 'bg-surface border-main text-muted hover:text-main hover:border-main/80'
          )}
        >
          All ({photos.length})
        </button>
        {rooms.map((room) => (
          <button
            key={room.id}
            onClick={() => onRoomFilterChange(room.id)}
            className={cn(
              'px-3 py-1.5 text-sm rounded-lg border transition-colors',
              photoRoomFilter === room.id
                ? 'bg-[var(--accent)] text-white border-[var(--accent)]'
                : 'bg-surface border-main text-muted hover:text-main hover:border-main/80'
            )}
          >
            {room.name}
          </button>
        ))}
        <button
          onClick={() => onRoomFilterChange('unassigned')}
          className={cn(
            'px-3 py-1.5 text-sm rounded-lg border transition-colors',
            photoRoomFilter === 'unassigned'
              ? 'bg-[var(--accent)] text-white border-[var(--accent)]'
              : 'bg-surface border-main text-muted hover:text-main hover:border-main/80'
          )}
        >
          Unassigned
        </button>
      </div>

      {/* Photo grid */}
      {photos.length === 0 ? (
        <div className="py-8 text-center text-muted">
          <p>No photos in this filter</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
          {photos.map((photo) => {
            const room = rooms.find((r) => r.id === photo.roomId);
            return (
              <button
                key={photo.id}
                onClick={() => onPhotoClick(photo)}
                className="relative aspect-square rounded-xl overflow-hidden bg-secondary hover:ring-2 hover:ring-[var(--accent)] transition-all group"
              >
                <img
                  src={getPhotoUrl(photo.thumbnailPath || photo.storagePath)}
                  alt={photo.caption || 'Photo'}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                <div className="absolute bottom-0 left-0 right-0 p-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  {photo.caption && (
                    <p className="text-[10px] text-white truncate">{photo.caption}</p>
                  )}
                  {room && (
                    <p className="text-[9px] text-white/70">{room.name}</p>
                  )}
                </div>
                {photo.photoType && (
                  <span className="absolute top-1.5 right-1.5 px-1.5 py-0.5 text-[9px] font-medium bg-black/60 text-white rounded">
                    {PHOTO_TYPE_LABELS[photo.photoType] || photo.photoType}
                  </span>
                )}
                {photo.annotations && photo.annotations.length > 0 && (
                  <span className="absolute top-1.5 left-1.5 w-4 h-4 bg-blue-500 text-white rounded-full flex items-center justify-center text-[8px] font-bold">
                    A
                  </span>
                )}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ============================================================
// PHOTO LIGHTBOX
// ============================================================

function PhotoLightbox({
  photo,
  getPhotoUrl,
  onClose,
}: {
  photo: WalkthroughPhoto;
  getPhotoUrl: (path: string) => string;
  onClose: () => void;
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80" onClick={onClose}>
      <div
        className="relative max-w-5xl max-h-[90vh] w-full mx-4 flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute -top-10 right-0 p-1.5 text-white/70 hover:text-white transition-colors"
        >
          <X size={20} />
        </button>

        {/* Image */}
        <div className="relative flex-1 min-h-0 flex items-center justify-center">
          <img
            src={getPhotoUrl(photo.storagePath)}
            alt={photo.caption || 'Photo'}
            className="max-w-full max-h-[75vh] object-contain rounded-lg"
          />

          {/* Annotation overlay */}
          {photo.annotations && photo.annotations.length > 0 && (
            <div className="absolute inset-0 pointer-events-none">
              {photo.annotations.map((annotation, idx) => {
                const x = (annotation.x as number) || 0;
                const y = (annotation.y as number) || 0;
                const text = (annotation.text as string) || '';
                return (
                  <div
                    key={idx}
                    className="absolute"
                    style={{ left: `${x}%`, top: `${y}%`, transform: 'translate(-50%, -100%)' }}
                  >
                    <div className="bg-red-500 text-white text-[10px] px-2 py-1 rounded shadow-lg whitespace-nowrap">
                      {text}
                    </div>
                    <div className="w-2 h-2 bg-red-500 rounded-full mx-auto -mt-0.5" />
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Info bar */}
        <div className="mt-3 bg-zinc-900/90 rounded-lg px-4 py-3 flex items-center justify-between text-sm">
          <div className="flex items-center gap-4">
            {photo.caption && (
              <span className="text-white">{photo.caption}</span>
            )}
            <span className="text-white/50">
              {PHOTO_TYPE_LABELS[photo.photoType] || photo.photoType}
            </span>
            <span className="text-white/50">
              {formatDateTime(photo.createdAt)}
            </span>
          </div>
          {photo.aiAnalysis && (
            <Badge variant="purple" size="sm">
              AI Analyzed
            </Badge>
          )}
        </div>
      </div>
    </div>
  );
}

// ============================================================
// FLOOR PLAN TAB
// ============================================================

function FloorPlanTab({ floorPlans }: { floorPlans: FloorPlan[] }) {
  const [selectedPlan, setSelectedPlan] = useState<string | null>(null);

  const activePlan = floorPlans.find((p) => p.id === selectedPlan) || floorPlans[0] || null;

  if (floorPlans.length === 0) {
    return (
      <Card>
        <CardContent className="py-12 text-center text-muted">
          <Layers size={40} className="mx-auto mb-3 opacity-50" />
          <p className="text-lg font-medium">No floor plan created</p>
          <p className="text-sm mt-1">Floor plans are created on the mobile app during the walkthrough</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {/* Floor level tabs (if multiple) */}
      {floorPlans.length > 1 && (
        <div className="flex items-center gap-2">
          {floorPlans.map((plan) => (
            <button
              key={plan.id}
              onClick={() => setSelectedPlan(plan.id)}
              className={cn(
                'px-3 py-1.5 text-sm rounded-lg border transition-colors',
                (selectedPlan === plan.id || (!selectedPlan && plan === floorPlans[0]))
                  ? 'bg-[var(--accent)] text-white border-[var(--accent)]'
                  : 'bg-surface border-main text-muted hover:text-main'
              )}
            >
              {plan.name || `Floor ${plan.floorLevel}`}
            </button>
          ))}
        </div>
      )}

      {/* Floor plan renderer */}
      {activePlan && (
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-medium text-main">
                {activePlan.name || `Floor ${activePlan.floorLevel}`}
              </h3>
              <span className="text-xs text-muted">
                Source: {activePlan.source || 'Mobile app'}
              </span>
            </div>
            <FloorPlanRenderer planData={activePlan.planData} />
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function FloorPlanRenderer({ planData }: { planData: FloorPlanData | null }) {
  if (!planData) {
    return (
      <div className="h-96 flex items-center justify-center text-muted bg-secondary rounded-xl">
        <p>No plan data available</p>
      </div>
    );
  }

  const svgWidth = planData.width || 800;
  const svgHeight = planData.height || 600;

  return (
    <div className="relative overflow-auto bg-secondary rounded-xl p-4">
      <svg
        viewBox={`0 0 ${svgWidth} ${svgHeight}`}
        className="w-full max-h-[500px]"
        style={{ minWidth: '400px' }}
      >
        {/* Walls */}
        {planData.walls?.map((wall, i) => (
          <line
            key={`wall-${i}`}
            x1={wall.x1}
            y1={wall.y1}
            x2={wall.x2}
            y2={wall.y2}
            stroke="currentColor"
            strokeWidth="3"
            className="text-main"
          />
        ))}

        {/* Rooms (filled polygons) */}
        {planData.rooms?.map((room, i) => {
          const points = room.points?.map((p) => `${p.x},${p.y}`).join(' ') || '';
          return (
            <g key={`room-${i}`} className="cursor-pointer group/room">
              <polygon
                points={points}
                fill="currentColor"
                className="text-blue-500/5 group-hover/room:text-blue-500/15 transition-colors"
                stroke="currentColor"
                strokeWidth="1"
                strokeDasharray="4 2"
              />
              {room.label && (
                <text
                  x={room.label.x}
                  y={room.label.y}
                  textAnchor="middle"
                  dominantBaseline="central"
                  className="text-xs fill-current text-muted pointer-events-none"
                  fontSize="12"
                >
                  {room.name}
                </text>
              )}
            </g>
          );
        })}

        {/* Doors */}
        {planData.doors?.map((door, i) => (
          <g key={`door-${i}`} transform={`translate(${door.x}, ${door.y}) rotate(${door.rotation || 0})`}>
            <rect x={-door.width / 2} y={-2} width={door.width} height={4} fill="currentColor" className="text-amber-500" rx="1" />
            <path
              d={`M ${-door.width / 2} -2 A ${door.width} ${door.width} 0 0 1 ${door.width / 2} -2`}
              fill="none"
              stroke="currentColor"
              strokeWidth="1"
              strokeDasharray="3 2"
              className="text-amber-400"
            />
          </g>
        ))}

        {/* Windows */}
        {planData.windows?.map((win, i) => (
          <g key={`window-${i}`} transform={`translate(${win.x}, ${win.y}) rotate(${win.rotation || 0})`}>
            <rect x={-win.width / 2} y={-3} width={win.width} height={6} fill="currentColor" className="text-sky-400/30" stroke="currentColor" strokeWidth="1.5" rx="1" />
            <line x1={-win.width / 2 + 2} y1={0} x2={win.width / 2 - 2} y2={0} stroke="currentColor" strokeWidth="1" className="text-sky-400" />
          </g>
        ))}

        {/* Fixtures */}
        {planData.fixtures?.map((fixture, i) => (
          <g key={`fixture-${i}`}>
            <circle cx={fixture.x} cy={fixture.y} r="6" fill="currentColor" className="text-slate-400/20" stroke="currentColor" strokeWidth="1" />
            {fixture.label && (
              <text
                x={fixture.x}
                y={fixture.y + 14}
                textAnchor="middle"
                className="text-[8px] fill-current text-muted"
              >
                {fixture.label}
              </text>
            )}
          </g>
        ))}

        {/* Dimensions */}
        {planData.dimensions?.map((dim, i) => {
          const midX = (dim.x1 + dim.x2) / 2;
          const midY = (dim.y1 + dim.y2) / 2;
          return (
            <g key={`dim-${i}`}>
              <line
                x1={dim.x1}
                y1={dim.y1}
                x2={dim.x2}
                y2={dim.y2}
                stroke="currentColor"
                strokeWidth="0.5"
                strokeDasharray="2 2"
                className="text-muted/50"
              />
              <text
                x={midX}
                y={midY - 4}
                textAnchor="middle"
                className="text-[9px] fill-current text-muted"
              >
                {dim.value}
              </text>
            </g>
          );
        })}
      </svg>
    </div>
  );
}

// ============================================================
// NOTES TAB
// ============================================================

function NotesTab({ walkthrough, rooms }: { walkthrough: Walkthrough; rooms: WalkthroughRoom[] }) {
  const roomsWithNotes = rooms.filter((r) => r.notes);

  return (
    <div className="space-y-6">
      {/* Overall notes */}
      <Card>
        <CardContent className="p-5">
          <h3 className="text-sm font-semibold text-main mb-3 flex items-center gap-2">
            <StickyNote size={16} />
            Overall Notes
          </h3>
          {walkthrough.notes ? (
            <p className="text-sm text-muted whitespace-pre-wrap">{walkthrough.notes}</p>
          ) : (
            <p className="text-sm text-muted/50">No notes recorded</p>
          )}
        </CardContent>
      </Card>

      {/* Weather conditions */}
      {walkthrough.weatherConditions && (
        <Card>
          <CardContent className="p-5">
            <h3 className="text-sm font-semibold text-main mb-3 flex items-center gap-2">
              <CloudSun size={16} />
              Weather Conditions
            </h3>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
              {walkthrough.weatherConditions.conditions && (
                <div className="flex items-center gap-2 text-sm">
                  <CloudSun size={14} className="text-muted" />
                  <span className="text-muted">Conditions:</span>
                  <span className="text-main">{walkthrough.weatherConditions.conditions}</span>
                </div>
              )}
              {walkthrough.weatherConditions.temperature != null && (
                <div className="flex items-center gap-2 text-sm">
                  <Thermometer size={14} className="text-muted" />
                  <span className="text-muted">Temp:</span>
                  <span className="text-main">{walkthrough.weatherConditions.temperature}F</span>
                </div>
              )}
              {walkthrough.weatherConditions.humidity != null && (
                <div className="flex items-center gap-2 text-sm">
                  <Droplets size={14} className="text-muted" />
                  <span className="text-muted">Humidity:</span>
                  <span className="text-main">{walkthrough.weatherConditions.humidity}%</span>
                </div>
              )}
              {walkthrough.weatherConditions.windSpeed != null && (
                <div className="flex items-center gap-2 text-sm">
                  <Wind size={14} className="text-muted" />
                  <span className="text-muted">Wind:</span>
                  <span className="text-main">{walkthrough.weatherConditions.windSpeed} mph</span>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Room-by-room notes */}
      {roomsWithNotes.length > 0 && (
        <Card>
          <CardContent className="p-5">
            <h3 className="text-sm font-semibold text-main mb-3 flex items-center gap-2">
              <DoorOpen size={16} />
              Room Notes
            </h3>
            <div className="space-y-4">
              {roomsWithNotes.map((room) => (
                <div key={room.id} className="border-l-2 border-main pl-4">
                  <div className="flex items-center gap-2 mb-1">
                    <h4 className="text-sm font-medium text-main">{room.name}</h4>
                    {room.roomType && (
                      <Badge variant="secondary" size="sm">{room.roomType}</Badge>
                    )}
                    {room.conditionRating != null && (
                      <div className="flex items-center gap-0.5">
                        {[1, 2, 3, 4, 5].map((s) => (
                          <Star
                            key={s}
                            size={10}
                            className={cn(
                              s <= (room.conditionRating || 0)
                                ? 'text-amber-400 fill-amber-400'
                                : 'text-slate-300 dark:text-slate-600'
                            )}
                          />
                        ))}
                      </div>
                    )}
                  </div>
                  <p className="text-sm text-muted whitespace-pre-wrap">{room.notes}</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Walkthrough metadata */}
      <Card>
        <CardContent className="p-5">
          <h3 className="text-sm font-semibold text-main mb-3 flex items-center gap-2">
            <FileText size={16} />
            Details
          </h3>
          <div className="grid grid-cols-2 gap-x-8 gap-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-muted">Property Type</span>
              <span className="text-main">{walkthrough.propertyType || '--'}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted">Walkthrough Type</span>
              <span className="text-main">
                {TYPE_LABELS[walkthrough.walkthroughType] || walkthrough.walkthroughType || '--'}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted">Started</span>
              <span className="text-main">
                {walkthrough.startedAt ? formatDateTime(walkthrough.startedAt) : '--'}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted">Completed</span>
              <span className="text-main">
                {walkthrough.completedAt ? formatDateTime(walkthrough.completedAt) : '--'}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted">Total Rooms</span>
              <span className="text-main">{walkthrough.totalRooms}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted">Total Photos</span>
              <span className="text-main">{walkthrough.totalPhotos}</span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
