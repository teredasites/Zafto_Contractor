'use client';

import { useState, useCallback } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft, MapPin, Camera, DoorOpen, ChevronDown, ChevronUp,
  CheckCircle2, Clock, Ruler, Star, ScanLine, X, Maximize2,
  Layers, FileText,
} from 'lucide-react';
import { useWalkthrough, markRoomCompleted } from '@/lib/hooks/use-walkthroughs';
import type { WalkthroughRoomData, WalkthroughPhotoData } from '@/lib/hooks/use-walkthroughs';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge } from '@/components/ui/badge';
import { cn, formatDate } from '@/lib/utils';

// ==================== TYPE LABELS ====================

const TYPE_LABELS: Record<string, string> = {
  general: 'General',
  pre_construction: 'Pre-Construction',
  post_construction: 'Post-Construction',
  insurance_claim: 'Insurance Claim',
  inspection: 'Inspection',
  move_in: 'Move-In',
  move_out: 'Move-Out',
};

const FLOOR_LABELS: Record<string, string> = {
  basement: 'Basement',
  ground: 'Ground Floor',
  first: '1st Floor',
  second: '2nd Floor',
  third: '3rd Floor',
  attic: 'Attic',
};

// ==================== SKELETON ====================

function DetailSkeleton() {
  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center gap-3">
        <div className="skeleton h-9 w-9 rounded-lg" />
        <div className="skeleton h-6 w-48 rounded-lg" />
      </div>
      <div className="skeleton h-8 w-64 rounded-lg" />
      <div className="skeleton h-4 w-full rounded-lg" />
      <div className="skeleton h-40 w-full rounded-xl" />
      <div className="grid grid-cols-2 gap-3">
        <div className="skeleton h-24 rounded-xl" />
        <div className="skeleton h-24 rounded-xl" />
        <div className="skeleton h-24 rounded-xl" />
        <div className="skeleton h-24 rounded-xl" />
      </div>
    </div>
  );
}

// ==================== CONDITION STARS ====================

function ConditionStars({ rating }: { rating: number | null }) {
  if (rating === null || rating === undefined) return null;
  const stars = Math.min(5, Math.max(0, Math.round(rating)));
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((i) => (
        <Star
          key={i}
          size={12}
          className={cn(
            i <= stars ? 'text-amber-400 fill-amber-400' : 'text-slate-300 dark:text-slate-600'
          )}
        />
      ))}
    </div>
  );
}

// ==================== PHOTO LIGHTBOX ====================

function PhotoLightbox({
  photo,
  onClose,
  onPrev,
  onNext,
}: {
  photo: WalkthroughPhotoData;
  onClose: () => void;
  onPrev: () => void;
  onNext: () => void;
}) {
  return (
    <div className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center" onClick={onClose}>
      <div className="absolute top-4 right-4 z-10">
        <button onClick={onClose} className="text-white/80 hover:text-white transition-colors p-2">
          <X size={24} />
        </button>
      </div>

      {/* Navigation */}
      <button
        onClick={(e) => { e.stopPropagation(); onPrev(); }}
        className="absolute left-4 top-1/2 -translate-y-1/2 text-white/60 hover:text-white p-3 transition-colors"
      >
        <ChevronDown size={28} className="rotate-90" />
      </button>
      <button
        onClick={(e) => { e.stopPropagation(); onNext(); }}
        className="absolute right-4 top-1/2 -translate-y-1/2 text-white/60 hover:text-white p-3 transition-colors"
      >
        <ChevronUp size={28} className="rotate-90" />
      </button>

      {/* Image */}
      <div className="max-w-[90vw] max-h-[80vh] relative" onClick={(e) => e.stopPropagation()}>
        {photo.signedUrl ? (
          <img
            src={photo.signedUrl}
            alt={photo.caption || 'Walkthrough photo'}
            className="max-w-full max-h-[80vh] object-contain rounded-lg"
          />
        ) : (
          <div className="w-96 h-64 bg-slate-800 rounded-lg flex items-center justify-center">
            <Camera size={32} className="text-slate-600" />
          </div>
        )}

        {/* Annotations Overlay */}
        {photo.annotations && photo.annotations.length > 0 && (
          <div className="absolute inset-0 pointer-events-none">
            {photo.annotations.map((ann, i) => {
              const x = (ann.x as number) || 0;
              const y = (ann.y as number) || 0;
              const label = (ann.label as string) || '';
              return (
                <div
                  key={i}
                  className="absolute bg-red-500/80 text-white text-[10px] px-1.5 py-0.5 rounded font-medium"
                  style={{ left: `${x}%`, top: `${y}%`, transform: 'translate(-50%, -50%)' }}
                >
                  {label}
                </div>
              );
            })}
          </div>
        )}

        {/* Caption */}
        {photo.caption && (
          <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/70 to-transparent p-4 rounded-b-lg">
            <p className="text-white text-sm">{photo.caption}</p>
          </div>
        )}
      </div>
    </div>
  );
}

// ==================== ROOM CARD ====================

function RoomCard({
  room,
  photos,
  onMarkComplete,
}: {
  room: WalkthroughRoomData;
  photos: WalkthroughPhotoData[];
  onMarkComplete: (roomId: string) => void;
}) {
  const [expanded, setExpanded] = useState(false);
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);
  const [marking, setMarking] = useState(false);

  const roomPhotos = photos.filter((p) => p.roomId === room.id);
  const isCompleted = room.status === 'completed';

  const handleMarkComplete = async () => {
    setMarking(true);
    try {
      await onMarkComplete(room.id);
    } finally {
      setMarking(false);
    }
  };

  return (
    <>
      <Card className={cn(isCompleted && 'border-emerald-200 dark:border-emerald-800/40')}>
        <button
          onClick={() => setExpanded(!expanded)}
          className="w-full text-left"
        >
          <CardContent className="py-3.5">
            <div className="flex items-center gap-3">
              <div className={cn(
                'w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0',
                isCompleted
                  ? 'bg-emerald-100 dark:bg-emerald-900/30'
                  : 'bg-secondary'
              )}>
                {isCompleted ? (
                  <CheckCircle2 size={16} className="text-emerald-500" />
                ) : (
                  <DoorOpen size={16} className="text-muted" />
                )}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <p className="text-sm font-medium text-main truncate">{room.name}</p>
                  <ConditionStars rating={room.conditionRating} />
                </div>
                <div className="flex items-center gap-3 mt-0.5">
                  <span className="text-xs text-muted capitalize">
                    {room.roomType.replace(/_/g, ' ')}
                  </span>
                  {room.floorLevel && (
                    <span className="text-xs text-muted">
                      {FLOOR_LABELS[room.floorLevel] || room.floorLevel}
                    </span>
                  )}
                  <span className="text-xs text-muted flex items-center gap-0.5">
                    <Camera size={10} /> {roomPhotos.length}
                  </span>
                </div>
              </div>
              <div className="flex-shrink-0">
                {expanded ? <ChevronUp size={16} className="text-muted" /> : <ChevronDown size={16} className="text-muted" />}
              </div>
            </div>
          </CardContent>
        </button>

        {/* Expanded Content */}
        {expanded && (
          <div className="border-t border-main px-5 py-4 space-y-4">
            {/* Dimensions */}
            {room.dimensions && (room.dimensions.length || room.dimensions.width) && (
              <div className="flex items-start gap-3">
                <Ruler size={14} className="text-muted mt-0.5 flex-shrink-0" />
                <div className="text-sm text-secondary">
                  {room.dimensions.length && room.dimensions.width && (
                    <span>
                      {room.dimensions.length} x {room.dimensions.width}
                      {room.dimensions.height ? ` x ${room.dimensions.height}` : ''}
                      {room.dimensions.area ? ` = ${room.dimensions.area} sq ft` : ` = ${(room.dimensions.length * room.dimensions.width).toFixed(0)} sq ft`}
                    </span>
                  )}
                </div>
              </div>
            )}

            {/* Notes */}
            {room.notes && (
              <div className="flex items-start gap-3">
                <FileText size={14} className="text-muted mt-0.5 flex-shrink-0" />
                <p className="text-sm text-secondary whitespace-pre-wrap">{room.notes}</p>
              </div>
            )}

            {/* Photos Grid */}
            {roomPhotos.length > 0 && (
              <div>
                <p className="text-xs text-muted uppercase tracking-wide font-medium mb-2">Photos</p>
                <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                  {roomPhotos.map((photo, idx) => (
                    <button
                      key={photo.id}
                      onClick={() => setLightboxIndex(idx)}
                      className="relative aspect-square rounded-lg overflow-hidden bg-secondary group"
                    >
                      {photo.signedUrl ? (
                        <img
                          src={photo.signedUrl}
                          alt={photo.caption || 'Room photo'}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center">
                          <Camera size={16} className="text-muted" />
                        </div>
                      )}
                      <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors flex items-center justify-center">
                        <Maximize2 size={16} className="text-white opacity-0 group-hover:opacity-100 transition-opacity" />
                      </div>
                      {photo.annotations && photo.annotations.length > 0 && (
                        <div className="absolute top-1 right-1 w-4 h-4 rounded-full bg-red-500 flex items-center justify-center">
                          <span className="text-white text-[8px] font-bold">{photo.annotations.length}</span>
                        </div>
                      )}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {roomPhotos.length === 0 && (
              <p className="text-xs text-muted text-center py-2">No photos for this room.</p>
            )}

            {/* Mark Complete Button */}
            {!isCompleted && (
              <div className="pt-1">
                <Button
                  variant="primary"
                  size="sm"
                  onClick={handleMarkComplete}
                  loading={marking}
                  className="w-full"
                >
                  <CheckCircle2 size={14} />
                  Mark as Complete
                </Button>
              </div>
            )}
          </div>
        )}
      </Card>

      {/* Lightbox */}
      {lightboxIndex !== null && roomPhotos[lightboxIndex] && (
        <PhotoLightbox
          photo={roomPhotos[lightboxIndex]}
          onClose={() => setLightboxIndex(null)}
          onPrev={() => setLightboxIndex((prev) => (prev !== null && prev > 0 ? prev - 1 : roomPhotos.length - 1))}
          onNext={() => setLightboxIndex((prev) => (prev !== null && prev < roomPhotos.length - 1 ? prev + 1 : 0))}
        />
      )}
    </>
  );
}

// ==================== PAGE ====================

export default function WalkthroughDetailPage() {
  const params = useParams();
  const walkthroughId = params.id as string;
  const { walkthrough, rooms, photos, loading, error } = useWalkthrough(walkthroughId);

  const handleMarkComplete = useCallback(async (roomId: string) => {
    try {
      await markRoomCompleted(roomId);
      // Real-time subscription will pick up the update
    } catch {
      // Error handling would go here (toast, etc.)
    }
  }, []);

  if (loading) return <DetailSkeleton />;

  if (error || !walkthrough) {
    return (
      <div className="space-y-6 animate-fade-in">
        <Link
          href="/dashboard/walkthroughs"
          className="inline-flex items-center gap-2 text-sm text-muted hover:text-main transition-colors min-h-[44px]"
        >
          <ArrowLeft size={16} />
          Back to Walkthroughs
        </Link>
        <Card>
          <CardContent className="py-12 text-center">
            <ScanLine size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">Walkthrough not found</p>
            <p className="text-sm text-muted mt-1">
              {error || 'This walkthrough may have been removed or you no longer have access.'}
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  const completedRooms = rooms.filter((r) => r.status === 'completed').length;
  const totalRooms = rooms.length || walkthrough.totalRooms;
  const progressPct = totalRooms > 0 ? Math.round((completedRooms / totalRooms) * 100) : 0;

  // Group rooms by floor level
  const floorGroups = rooms.reduce<Record<string, WalkthroughRoomData[]>>((acc, room) => {
    const floor = room.floorLevel || 'unassigned';
    if (!acc[floor]) acc[floor] = [];
    acc[floor].push(room);
    return acc;
  }, {});

  const floorOrder = ['basement', 'ground', 'first', 'second', 'third', 'attic', 'unassigned'];
  const sortedFloors = Object.keys(floorGroups).sort(
    (a, b) => floorOrder.indexOf(a) - floorOrder.indexOf(b)
  );

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Back navigation */}
      <Link
        href="/dashboard/walkthroughs"
        className="inline-flex items-center gap-2 text-sm text-muted hover:text-main transition-colors min-h-[44px]"
      >
        <ArrowLeft size={16} />
        Back to Walkthroughs
      </Link>

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-start gap-3">
        <div className="flex-1 min-w-0">
          <h1 className="text-xl font-semibold text-main">{walkthrough.name}</h1>
          <p className="text-sm text-secondary mt-0.5">
            {TYPE_LABELS[walkthrough.walkthroughType] || walkthrough.walkthroughType}
          </p>
        </div>
        <StatusBadge status={walkthrough.status} className="self-start" />
      </div>

      {/* Info Card */}
      <Card>
        <CardContent className="py-4 space-y-4">
          {walkthrough.address && (
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
                <MapPin size={16} className="text-muted" />
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wide font-medium">Address</p>
                <p className="text-sm text-main mt-0.5">{walkthrough.address}</p>
              </div>
            </div>
          )}
          {walkthrough.createdAt && (
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
                <Clock size={16} className="text-muted" />
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wide font-medium">Created</p>
                <p className="text-sm text-main mt-0.5">{formatDate(walkthrough.createdAt)}</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Progress Bar */}
      <Card>
        <CardContent className="py-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-main">Room Progress</span>
            <span className="text-sm font-bold text-main">{completedRooms} / {totalRooms}</span>
          </div>
          <div className="h-3 bg-secondary rounded-full overflow-hidden">
            <div
              className="h-full rounded-full bg-accent transition-all duration-500"
              style={{ width: `${progressPct}%` }}
            />
          </div>
          <p className="text-xs text-muted mt-1.5">{progressPct}% complete</p>
        </CardContent>
      </Card>

      {/* Stats Row */}
      <div className="grid grid-cols-3 gap-3">
        <Card>
          <CardContent className="py-3 text-center">
            <DoorOpen size={18} className="text-accent mx-auto mb-1" />
            <p className="text-lg font-bold text-main">{totalRooms}</p>
            <p className="text-xs text-muted">Rooms</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-3 text-center">
            <Camera size={18} className="text-accent mx-auto mb-1" />
            <p className="text-lg font-bold text-main">{photos.length || walkthrough.totalPhotos}</p>
            <p className="text-xs text-muted">Photos</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-3 text-center">
            <CheckCircle2 size={18} className="text-emerald-500 mx-auto mb-1" />
            <p className="text-lg font-bold text-main">{completedRooms}</p>
            <p className="text-xs text-muted">Done</p>
          </CardContent>
        </Card>
      </div>

      {/* Notes */}
      {walkthrough.notes && (
        <Card>
          <CardHeader>
            <CardTitle>Notes</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-secondary whitespace-pre-wrap leading-relaxed">{walkthrough.notes}</p>
          </CardContent>
        </Card>
      )}

      {/* Rooms by Floor */}
      {rooms.length > 0 ? (
        <div className="space-y-5">
          {sortedFloors.map((floor) => (
            <div key={floor}>
              <div className="flex items-center gap-2 mb-3">
                <Layers size={14} className="text-muted" />
                <h2 className="text-[15px] font-semibold text-main">
                  {FLOOR_LABELS[floor] || (floor === 'unassigned' ? 'Rooms' : floor)}
                </h2>
                <span className="text-xs text-muted">
                  ({floorGroups[floor].length})
                </span>
              </div>
              <div className="space-y-2">
                {floorGroups[floor].map((room) => (
                  <RoomCard
                    key={room.id}
                    room={room}
                    photos={photos}
                    onMarkComplete={handleMarkComplete}
                  />
                ))}
              </div>
            </div>
          ))}
        </div>
      ) : (
        <Card>
          <CardContent className="py-8 text-center">
            <DoorOpen size={32} className="text-muted mx-auto mb-2" />
            <p className="text-sm text-muted">No rooms recorded yet.</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
