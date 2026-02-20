'use client';

import { useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft, MapPin, Camera, DoorOpen, Ruler, FileText,
  ChevronDown, ChevronUp, ScanLine, X, Maximize2, Calendar,
  Printer, Layers, CheckCircle2,
} from 'lucide-react';
import { useWalkthrough } from '@/lib/hooks/use-walkthroughs';
import type { WalkthroughRoomData, WalkthroughPhotoData } from '@/lib/hooks/use-walkthroughs';
import { formatDate } from '@/lib/hooks/mappers';

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
    <div className="space-y-5 animate-pulse">
      <div>
        <div className="h-4 w-28 bg-gray-200 rounded mb-3" />
        <div className="flex items-start justify-between">
          <div>
            <div className="h-6 w-48 bg-gray-200 rounded" />
            <div className="h-4 w-32 bg-gray-100 rounded mt-2" />
          </div>
          <div className="h-6 w-20 bg-gray-100 rounded-full" />
        </div>
      </div>
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
        <div className="h-3 bg-gray-100 rounded-full mb-2" />
        <div className="h-3 bg-gray-100 rounded-full w-2/3" />
      </div>
      <div className="bg-white rounded-xl border border-gray-100 p-4 h-32" />
      <div className="bg-white rounded-xl border border-gray-100 p-4 h-48" />
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

      <div className="max-w-[90vw] max-h-[80vh] relative" onClick={(e) => e.stopPropagation()}>
        {photo.signedUrl ? (
          <img
            src={photo.signedUrl}
            alt={photo.caption || 'Walkthrough photo'}
            className="max-w-full max-h-[80vh] object-contain rounded-lg"
          />
        ) : (
          <div className="w-96 h-64 bg-gray-800 rounded-lg flex items-center justify-center">
            <Camera size={32} className="text-gray-600" />
          </div>
        )}

        {photo.annotations && photo.annotations.length > 0 && (
          <div className="absolute inset-0 pointer-events-none">
            {photo.annotations.map((ann, i) => {
              const x = (ann.x as number) || 0;
              const y = (ann.y as number) || 0;
              const label = (ann.label as string) || '';
              return (
                <div
                  key={i}
                  className="absolute text-white text-[10px] px-1.5 py-0.5 rounded font-medium"
                  style={{
                    left: `${x}%`,
                    top: `${y}%`,
                    transform: 'translate(-50%, -50%)',
                    backgroundColor: 'rgba(99, 91, 255, 0.85)',
                  }}
                >
                  {label}
                </div>
              );
            })}
          </div>
        )}

        {photo.caption && (
          <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/70 to-transparent p-4 rounded-b-lg">
            <p className="text-white text-sm">{photo.caption}</p>
          </div>
        )}
      </div>
    </div>
  );
}

// ==================== ROOM SECTION ====================

function RoomSection({
  room,
  photos,
}: {
  room: WalkthroughRoomData;
  photos: WalkthroughPhotoData[];
}) {
  const [expanded, setExpanded] = useState(false);
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);

  const roomPhotos = photos.filter((p) => p.roomId === room.id);

  return (
    <>
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        {/* Room Header */}
        <button
          onClick={() => setExpanded(!expanded)}
          className="w-full text-left p-4 hover:bg-gray-50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0"
              style={{ backgroundColor: 'color-mix(in srgb, var(--accent) 10%, transparent)' }}>
              <DoorOpen size={16} style={{ color: 'var(--accent)' }} />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <h3 className="font-semibold text-gray-900 text-sm">{room.name}</h3>
                {room.conditionTags.length > 0 && (
                  <span className="text-xs px-1.5 py-0.5 rounded bg-gray-100 text-gray-600">
                    {room.conditionTags[0]}
                  </span>
                )}
              </div>
              <div className="flex items-center gap-3 mt-0.5">
                <span className="text-xs text-gray-500 capitalize">
                  {room.roomType.replace(/_/g, ' ')}
                </span>
                {room.floorLevel && (
                  <span className="text-xs text-gray-400">
                    {FLOOR_LABELS[room.floorLevel] || room.floorLevel}
                  </span>
                )}
                <span className="text-xs text-gray-400 flex items-center gap-0.5">
                  <Camera size={10} /> {roomPhotos.length}
                </span>
              </div>
            </div>
            <div className="flex-shrink-0 text-gray-400">
              {expanded ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
            </div>
          </div>
        </button>

        {/* Expanded Content */}
        {expanded && (
          <div className="border-t border-gray-100 p-4 space-y-4">
            {/* Dimensions */}
            {room.dimensions && (room.dimensions.length || room.dimensions.width) && (
              <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                <Ruler size={16} className="text-gray-400 flex-shrink-0" />
                <div className="text-sm text-gray-700">
                  {room.dimensions.length && room.dimensions.width && (
                    <span className="font-medium">
                      {room.dimensions.length} ft x {room.dimensions.width} ft
                      {room.dimensions.height ? ` x ${room.dimensions.height} ft` : ''}
                      {' = '}
                      <span style={{ color: 'var(--accent)' }}>
                        {room.dimensions.area
                          ? `${room.dimensions.area} sq ft`
                          : `${(room.dimensions.length * room.dimensions.width).toFixed(0)} sq ft`}
                      </span>
                    </span>
                  )}
                </div>
              </div>
            )}

            {/* Condition */}
            {(room.conditionTags.length > 0 || room.materialTags.length > 0) && (
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <span className="text-sm text-gray-600">Condition</span>
                <div className="flex items-center gap-1.5 flex-wrap">
                  {room.conditionTags.map((tag) => (
                    <span key={tag} className="text-xs px-2 py-0.5 rounded-full bg-amber-100 text-amber-700">
                      {tag}
                    </span>
                  ))}
                  {room.materialTags.map((tag) => (
                    <span key={tag} className="text-xs px-2 py-0.5 rounded-full bg-blue-100 text-blue-700">
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Notes */}
            {room.notes && (
              <div className="flex items-start gap-3">
                <FileText size={14} className="text-gray-400 mt-0.5 flex-shrink-0" />
                <p className="text-sm text-gray-600 whitespace-pre-wrap leading-relaxed">{room.notes}</p>
              </div>
            )}

            {/* Photos Grid */}
            {roomPhotos.length > 0 && (
              <div>
                <p className="text-xs text-gray-500 uppercase tracking-wide font-medium mb-2">Photos</p>
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2">
                  {roomPhotos.map((photo, idx) => (
                    <button
                      key={photo.id}
                      onClick={() => setLightboxIndex(idx)}
                      className="relative aspect-square rounded-lg overflow-hidden bg-gray-100 group"
                    >
                      {photo.signedUrl ? (
                        <img
                          src={photo.signedUrl}
                          alt={photo.caption || 'Room photo'}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center">
                          <Camera size={16} className="text-gray-300" />
                        </div>
                      )}
                      <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors flex items-center justify-center">
                        <Maximize2 size={16} className="text-white opacity-0 group-hover:opacity-100 transition-opacity" />
                      </div>
                      {photo.caption && (
                        <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/60 to-transparent p-1.5">
                          <p className="text-white text-[10px] truncate">{photo.caption}</p>
                        </div>
                      )}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {roomPhotos.length === 0 && (
              <p className="text-xs text-gray-400 text-center py-2">No photos for this room.</p>
            )}
          </div>
        )}
      </div>

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
  const { id } = useParams<{ id: string }>();
  const { walkthrough, rooms, photos, loading, error } = useWalkthrough(id);

  if (loading) {
    return (
      <div className="space-y-5">
        <Link href="/walkthroughs" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to Walkthroughs
        </Link>
        <DetailSkeleton />
      </div>
    );
  }

  if (error || !walkthrough) {
    return (
      <div className="space-y-5">
        <Link href="/walkthroughs" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to Walkthroughs
        </Link>
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <ScanLine size={32} className="mx-auto text-gray-300 mb-3" />
          <h3 className="font-semibold text-gray-900 text-sm">Walkthrough not found</h3>
          <p className="text-xs text-gray-500 mt-1">
            {error || 'This walkthrough may have been removed or you don\'t have access.'}
          </p>
        </div>
      </div>
    );
  }

  const completedRooms = rooms.filter((r) => r.photoCount > 0).length;
  const totalRooms = rooms.length || walkthrough.totalRooms;

  // Group rooms by floor
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

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="space-y-5">
      {/* Back + Actions */}
      <div className="flex items-center justify-between">
        <Link href="/walkthroughs" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700">
          <ArrowLeft size={16} /> Back to Walkthroughs
        </Link>
        <button
          onClick={handlePrint}
          className="flex items-center gap-1.5 px-3 py-2 text-xs font-medium rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 transition-colors print:hidden"
        >
          <Printer size={14} />
          Print Report
        </button>
      </div>

      {/* Report Header */}
      <div>
        <h1 className="text-xl font-bold text-gray-900">{walkthrough.name}</h1>
        <p className="text-sm text-gray-500 mt-0.5">
          {TYPE_LABELS[walkthrough.walkthroughType] || walkthrough.walkthroughType}
        </p>
      </div>

      {/* Property Info */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
        <div className="space-y-3">
          {walkthrough.address && (
            <div className="flex items-center gap-3">
              <MapPin size={16} className="text-gray-400 flex-shrink-0" />
              <div>
                <p className="text-xs text-gray-400 uppercase tracking-wide font-medium">Property Address</p>
                <p className="text-sm text-gray-900 font-medium mt-0.5">{walkthrough.address}</p>
              </div>
            </div>
          )}
          {walkthrough.createdAt && (
            <div className="flex items-center gap-3">
              <Calendar size={16} className="text-gray-400 flex-shrink-0" />
              <div>
                <p className="text-xs text-gray-400 uppercase tracking-wide font-medium">Date</p>
                <p className="text-sm text-gray-900 mt-0.5">{formatDate(walkthrough.createdAt)}</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Summary Stats */}
      <div className="grid grid-cols-3 gap-2">
        <div className="bg-white rounded-xl border border-gray-100 p-3 text-center">
          <DoorOpen size={18} className="mx-auto mb-1" style={{ color: 'var(--accent)' }} />
          <p className="text-lg font-bold text-gray-900">{totalRooms}</p>
          <p className="text-[10px] text-gray-500 uppercase tracking-wide">Rooms</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-100 p-3 text-center">
          <Camera size={18} className="mx-auto mb-1" style={{ color: 'var(--accent)' }} />
          <p className="text-lg font-bold text-gray-900">{photos.length || walkthrough.totalPhotos}</p>
          <p className="text-[10px] text-gray-500 uppercase tracking-wide">Photos</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-100 p-3 text-center">
          <CheckCircle2 size={18} className="mx-auto text-green-500 mb-1" />
          <p className="text-lg font-bold text-gray-900">{completedRooms}</p>
          <p className="text-[10px] text-gray-500 uppercase tracking-wide">Completed</p>
        </div>
      </div>

      {/* Notes */}
      {walkthrough.notes && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
          <h3 className="font-semibold text-sm text-gray-900 mb-2">Notes</h3>
          <p className="text-sm text-gray-600 whitespace-pre-wrap leading-relaxed">{walkthrough.notes}</p>
        </div>
      )}

      {/* Room Sections by Floor */}
      {rooms.length > 0 ? (
        <div className="space-y-5">
          {sortedFloors.map((floor) => (
            <div key={floor}>
              <div className="flex items-center gap-2 mb-3">
                <Layers size={14} className="text-gray-400" />
                <h2 className="text-sm font-semibold text-gray-900">
                  {FLOOR_LABELS[floor] || (floor === 'unassigned' ? 'Rooms' : floor)}
                </h2>
                <span className="text-xs text-gray-400">
                  ({floorGroups[floor].length} room{floorGroups[floor].length !== 1 ? 's' : ''})
                </span>
              </div>
              <div className="space-y-2">
                {floorGroups[floor].map((room) => (
                  <RoomSection key={room.id} room={room} photos={photos} />
                ))}
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <DoorOpen size={28} className="mx-auto text-gray-300 mb-3" />
          <h3 className="font-semibold text-gray-900 text-sm">No rooms recorded</h3>
          <p className="text-xs text-gray-500 mt-1">Room details will appear here once the walkthrough is completed.</p>
        </div>
      )}
    </div>
  );
}
