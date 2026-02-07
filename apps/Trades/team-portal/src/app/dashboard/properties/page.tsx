'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Building2, MapPin, Search, ChevronRight, Phone, Mail, User, AlertTriangle } from 'lucide-react';
import { useMaintenanceRequests, updateRequestStatus } from '@/lib/hooks/use-maintenance-requests';
import { Card, CardContent } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { cn, formatDate } from '@/lib/utils';
import { URGENCY_COLORS, MAINTENANCE_STATUS_LABELS } from '@/lib/hooks/mappers';
import type { MaintenanceRequestStatus, MaintenanceUrgency } from '@/lib/hooks/mappers';

type FilterTab = 'all' | 'open' | 'in_progress' | 'completed';

const FILTER_TABS: { key: FilterTab; label: string }[] = [
  { key: 'all', label: 'All' },
  { key: 'open', label: 'Open' },
  { key: 'in_progress', label: 'In Progress' },
  { key: 'completed', label: 'Completed' },
];

const OPEN_STATUSES = new Set<MaintenanceRequestStatus>(['new', 'assigned']);
const IN_PROGRESS_STATUSES = new Set<MaintenanceRequestStatus>(['in_progress', 'on_hold']);
const COMPLETED_STATUSES = new Set<MaintenanceRequestStatus>(['completed', 'cancelled']);

function PropertiesSkeleton() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div className="skeleton h-7 w-48 rounded-lg" />
      <div className="flex gap-2">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="skeleton h-9 w-24 rounded-lg" />
        ))}
      </div>
      <div className="space-y-3">
        {[1, 2, 3].map((i) => (
          <div key={i} className="skeleton h-32 w-full rounded-xl" />
        ))}
      </div>
    </div>
  );
}

export default function PropertiesPage() {
  const { requests, loading, error } = useMaintenanceRequests();
  const [filter, setFilter] = useState<FilterTab>('all');
  const [search, setSearch] = useState('');
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  const filteredRequests = requests.filter((req) => {
    if (filter === 'open' && !OPEN_STATUSES.has(req.status)) return false;
    if (filter === 'in_progress' && !IN_PROGRESS_STATUSES.has(req.status)) return false;
    if (filter === 'completed' && !COMPLETED_STATUSES.has(req.status)) return false;

    if (search) {
      const q = search.toLowerCase();
      return (
        req.title.toLowerCase().includes(q) ||
        req.propertyName.toLowerCase().includes(q) ||
        req.description.toLowerCase().includes(q) ||
        (req.tenantName || '').toLowerCase().includes(q)
      );
    }
    return true;
  });

  const counts: Record<FilterTab, number> = {
    all: requests.length,
    open: requests.filter((r) => OPEN_STATUSES.has(r.status)).length,
    in_progress: requests.filter((r) => IN_PROGRESS_STATUSES.has(r.status)).length,
    completed: requests.filter((r) => COMPLETED_STATUSES.has(r.status)).length,
  };

  const handleStatusUpdate = async (requestId: string, status: MaintenanceRequestStatus) => {
    setUpdatingId(requestId);
    try {
      await updateRequestStatus(requestId, status);
    } catch {
      // Real-time subscription will refetch
    }
    setUpdatingId(null);
  };

  if (loading) return <PropertiesSkeleton />;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-semibold text-main">Property Maintenance</h1>
        <p className="text-sm text-muted mt-0.5">
          {requests.length} maintenance request{requests.length !== 1 ? 's' : ''} assigned to you
        </p>
      </div>

      {error && (
        <div className="flex items-center gap-2 text-sm text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 p-3 rounded-lg">
          <AlertTriangle size={16} />
          {error}
        </div>
      )}

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
        <input
          type="text"
          placeholder="Search requests..."
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

      {/* Requests List */}
      {filteredRequests.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <Building2 size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">No maintenance requests</p>
            <p className="text-sm text-muted mt-1">
              {search
                ? 'Try adjusting your search'
                : filter !== 'all'
                ? 'No requests match this filter'
                : 'No property maintenance requests assigned to you'}
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {filteredRequests.map((req) => (
            <Card key={req.id} className="hover:border-accent/30 transition-colors">
              <CardContent className="py-4">
                <div className="space-y-3">
                  {/* Title row */}
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-main">{req.title}</p>
                      {req.description && (
                        <p className="text-xs text-muted mt-0.5 line-clamp-2">{req.description}</p>
                      )}
                    </div>
                    <div className="flex items-center gap-1.5 flex-shrink-0">
                      <span className={cn(
                        'inline-flex items-center px-1.5 py-0.5 text-[10px] font-medium rounded-full',
                        URGENCY_COLORS[req.urgency].bg,
                        URGENCY_COLORS[req.urgency].text,
                      )}>
                        {req.urgency}
                      </span>
                      <StatusBadge status={req.status} label={MAINTENANCE_STATUS_LABELS[req.status]} />
                    </div>
                  </div>

                  {/* Property info */}
                  <div className="flex flex-wrap items-center gap-x-4 gap-y-1">
                    <span className="text-xs text-secondary flex items-center gap-1">
                      <Building2 size={12} className="flex-shrink-0" />
                      {req.propertyName}
                      {req.unitNumber && <span className="text-muted">Unit {req.unitNumber}</span>}
                    </span>
                    {req.tenantName && (
                      <span className="text-xs text-muted flex items-center gap-1">
                        <User size={12} className="flex-shrink-0" />
                        {req.tenantName}
                      </span>
                    )}
                    {req.createdAt && (
                      <span className="text-xs text-muted">
                        {formatDate(req.createdAt)}
                      </span>
                    )}
                  </div>

                  {/* Tenant contact */}
                  {(req.tenantPhone || req.tenantEmail) && (
                    <div className="flex flex-wrap gap-3">
                      {req.tenantPhone && (
                        <a href={`tel:${req.tenantPhone}`} className="text-xs text-accent flex items-center gap-1 hover:underline">
                          <Phone size={12} /> {req.tenantPhone}
                        </a>
                      )}
                      {req.tenantEmail && (
                        <a href={`mailto:${req.tenantEmail}`} className="text-xs text-accent flex items-center gap-1 hover:underline">
                          <Mail size={12} /> {req.tenantEmail}
                        </a>
                      )}
                    </div>
                  )}

                  {/* Actions */}
                  <div className="flex items-center gap-2 pt-1">
                    {req.status === 'new' || req.status === 'assigned' ? (
                      <Button
                        size="sm"
                        onClick={() => handleStatusUpdate(req.id, 'in_progress')}
                        loading={updatingId === req.id}
                      >
                        Start Work
                      </Button>
                    ) : req.status === 'in_progress' ? (
                      <Button
                        size="sm"
                        onClick={() => handleStatusUpdate(req.id, 'completed')}
                        loading={updatingId === req.id}
                      >
                        Mark Complete
                      </Button>
                    ) : null}
                    {req.jobId && (
                      <Link href={`/dashboard/jobs/${req.jobId}`}>
                        <Button variant="secondary" size="sm" className="flex items-center gap-1">
                          View Job <ChevronRight size={14} />
                        </Button>
                      </Link>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
