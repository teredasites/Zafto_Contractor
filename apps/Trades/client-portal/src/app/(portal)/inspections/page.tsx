'use client';
import { ClipboardCheck, Calendar, AlertCircle } from 'lucide-react';
import { useInspections } from '@/lib/hooks/use-inspections-tenant';
import { formatDate } from '@/lib/hooks/mappers';
import { inspectionTypeLabel, conditionLabel } from '@/lib/hooks/tenant-mappers';

// ==================== CONDITION STYLES ====================

const conditionStyles: Record<string, { color: string; bg: string }> = {
  excellent: { color: 'var(--success)', bg: 'color-mix(in srgb, var(--success) 15%, transparent)' },
  good: { color: 'var(--success)', bg: 'color-mix(in srgb, var(--success) 15%, transparent)' },
  fair: { color: 'var(--warning)', bg: 'color-mix(in srgb, var(--warning) 15%, transparent)' },
  poor: { color: 'var(--danger)', bg: 'color-mix(in srgb, var(--danger) 15%, transparent)' },
  damaged: { color: 'var(--danger)', bg: 'color-mix(in srgb, var(--danger) 15%, transparent)' },
};

// ==================== LOADING SKELETON ====================

function ListSkeleton() {
  return (
    <div className="space-y-2 animate-pulse">
      {[1, 2, 3].map(i => (
        <div key={i} className="flex items-center gap-3 rounded-xl border p-4" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <div className="w-10 h-10 rounded-xl" style={{ backgroundColor: 'var(--bg-secondary)' }} />
          <div className="flex-1 space-y-2">
            <div className="h-4 rounded w-32" style={{ backgroundColor: 'var(--bg-secondary)' }} />
            <div className="h-3 rounded w-48" style={{ backgroundColor: 'var(--border-light)' }} />
          </div>
          <div className="h-5 rounded-full w-16" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        </div>
      ))}
    </div>
  );
}

// ==================== PAGE ====================

export default function InspectionsPage() {
  const { inspections, loading } = useInspections();

  return (
    <div className="space-y-5">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold" style={{ color: 'var(--text)' }}>Inspections</h1>
        <p className="text-sm mt-0.5" style={{ color: 'var(--text-muted)' }}>
          Completed inspection reports for your unit
        </p>
      </div>

      {/* Loading */}
      {loading && <ListSkeleton />}

      {/* Empty State */}
      {!loading && inspections.length === 0 && (
        <div className="rounded-xl border p-8 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <ClipboardCheck size={32} className="mx-auto mb-3" style={{ color: 'var(--text-muted)' }} />
          <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>No inspection reports yet</h3>
          <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>
            Completed inspections for your unit will appear here.
          </p>
        </div>
      )}

      {/* Inspection List */}
      {!loading && inspections.length > 0 && (
        <div className="space-y-2">
          {inspections.map(insp => {
            const cStyle = insp.overallCondition
              ? (conditionStyles[insp.overallCondition] || { color: 'var(--text-muted)', bg: 'var(--bg-secondary)' })
              : { color: 'var(--text-muted)', bg: 'var(--bg-secondary)' };

            return (
              <div
                key={insp.id}
                className="flex items-center gap-3 rounded-xl border p-4"
                style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}
              >
                {/* Icon */}
                <div className="p-2.5 rounded-xl" style={{ backgroundColor: 'var(--bg-secondary)' }}>
                  <ClipboardCheck size={18} style={{ color: 'var(--accent)' }} />
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>
                    {inspectionTypeLabel(insp.inspectionType)} Inspection
                  </h3>
                  <div className="flex items-center gap-2 mt-0.5">
                    <Calendar size={11} style={{ color: 'var(--text-muted)' }} />
                    <span className="text-xs" style={{ color: 'var(--text-muted)' }}>
                      {formatDate(insp.inspectionDate)}
                    </span>
                  </div>
                  {insp.notes && (
                    <p className="text-xs mt-1 truncate" style={{ color: 'var(--text-muted)' }}>
                      {insp.notes}
                    </p>
                  )}
                </div>

                {/* Condition Badge */}
                <div className="flex flex-col items-end gap-1 flex-shrink-0">
                  {insp.overallCondition && (
                    <span
                      className="text-[10px] font-medium px-2.5 py-1 rounded-full"
                      style={{ backgroundColor: cStyle.bg, color: cStyle.color }}
                    >
                      {conditionLabel(insp.overallCondition)}
                    </span>
                  )}
                  <span
                    className="text-[10px] font-medium px-2 py-0.5 rounded-full"
                    style={{
                      backgroundColor: insp.status === 'completed'
                        ? 'color-mix(in srgb, var(--success) 15%, transparent)'
                        : 'var(--bg-secondary)',
                      color: insp.status === 'completed'
                        ? 'var(--success)'
                        : 'var(--text-muted)',
                    }}
                  >
                    {insp.status === 'completed' ? 'Completed' : insp.status}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
