'use client';

import Link from 'next/link';
import {
  ScanLine, MapPin, Camera, DoorOpen, ChevronRight, Calendar,
  CheckCircle2, Clock,
} from 'lucide-react';
import { useWalkthroughs } from '@/lib/hooks/use-walkthroughs';
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

const STATUS_CONFIG: Record<string, { label: string; color: string; bg: string; icon: typeof Clock }> = {
  completed: { label: 'Completed', color: 'text-green-700', bg: 'bg-green-50', icon: CheckCircle2 },
  uploaded: { label: 'Uploaded', color: 'text-blue-700', bg: 'bg-blue-50', icon: Camera },
  reviewed: { label: 'Reviewed', color: 'text-purple-700', bg: 'bg-purple-50', icon: ScanLine },
};

// ==================== SKELETON ====================

function CardSkeleton() {
  return (
    <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4 animate-pulse">
      <div className="flex items-start justify-between mb-3">
        <div>
          <div className="h-4 w-40 bg-gray-200 rounded" />
          <div className="h-3 w-28 bg-gray-100 rounded mt-2" />
        </div>
        <div className="h-6 w-20 bg-gray-100 rounded-full" />
      </div>
      <div className="flex items-center gap-4">
        <div className="h-3 w-20 bg-gray-100 rounded" />
        <div className="h-3 w-20 bg-gray-100 rounded" />
        <div className="h-3 w-24 bg-gray-100 rounded" />
      </div>
    </div>
  );
}

// ==================== PAGE ====================

export default function WalkthroughsPage() {
  const { walkthroughs, loading } = useWalkthroughs();

  return (
    <div className="space-y-5">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Property Walkthroughs</h1>
        <p className="text-gray-500 text-sm mt-0.5">
          View walkthrough reports for your properties.
        </p>
      </div>

      {/* Loading Skeleton */}
      {loading && (
        <div className="space-y-3">
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
        </div>
      )}

      {/* Empty State */}
      {!loading && walkthroughs.length === 0 && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <ScanLine size={32} className="mx-auto text-gray-300 mb-3" />
          <h3 className="font-semibold text-gray-900 text-sm">No walkthroughs yet</h3>
          <p className="text-xs text-gray-500 mt-1">
            Walkthrough reports will appear here once your contractor completes them.
          </p>
        </div>
      )}

      {/* Walkthrough Cards */}
      {!loading && walkthroughs.length > 0 && (
        <div className="space-y-3">
          {walkthroughs.map((wt) => {
            const config = STATUS_CONFIG[wt.status] || STATUS_CONFIG.completed;
            const StatusIcon = config.icon;

            return (
              <Link
                key={wt.id}
                href={`/walkthroughs/${wt.id}`}
                className="block bg-white rounded-xl border border-gray-100 shadow-sm hover:shadow-md transition-all p-4"
              >
                <div className="flex items-start justify-between mb-2">
                  <div className="min-w-0 flex-1">
                    <h3 className="font-semibold text-gray-900 text-sm truncate">{wt.name}</h3>
                    <p className="text-xs text-gray-500 mt-0.5">
                      {TYPE_LABELS[wt.walkthroughType] || wt.walkthroughType}
                    </p>
                  </div>
                  <span className={`flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full flex-shrink-0 ${config.bg} ${config.color}`}>
                    <StatusIcon size={12} /> {config.label}
                  </span>
                </div>

                {/* Address */}
                {wt.address && (
                  <div className="flex items-center gap-1.5 mb-2">
                    <MapPin size={12} className="text-gray-400 flex-shrink-0" />
                    <p className="text-xs text-gray-600 truncate">{wt.address}</p>
                  </div>
                )}

                {/* Meta Row */}
                <div className="flex items-center gap-4 text-xs text-gray-400">
                  <span className="flex items-center gap-1">
                    <DoorOpen size={11} />
                    {wt.totalRooms} room{wt.totalRooms !== 1 ? 's' : ''}
                  </span>
                  <span className="flex items-center gap-1">
                    <Camera size={11} />
                    {wt.totalPhotos} photo{wt.totalPhotos !== 1 ? 's' : ''}
                  </span>
                  {wt.createdAt && (
                    <span className="flex items-center gap-1">
                      <Calendar size={11} />
                      {formatDate(wt.createdAt)}
                    </span>
                  )}
                  <ChevronRight size={14} className="ml-auto text-gray-300" />
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
