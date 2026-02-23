'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  Satellite,
  Plus,
  Search,
  MapPin,
  Flame,
  Thermometer,
  Snowflake,
  Loader2,
  AlertCircle,
  ArrowLeft,
} from 'lucide-react';
import { useAreaScans, type AreaScanData } from '@/lib/hooks/use-area-scan';
import { useTranslation } from '@/lib/translations';

function StatusBadge({ status }: { status: string }) {
  const colors: Record<string, string> = {
    pending: 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20',
    scanning: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
    complete: 'bg-green-500/10 text-green-400 border-green-500/20',
    failed: 'bg-red-500/10 text-red-400 border-red-500/20',
  };
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border ${colors[status] || colors.pending}`}>
      {status === 'scanning' && <Loader2 size={10} className="mr-1 animate-spin" />}
      {status}
    </span>
  );
}

function ScanTypeLabel({ type }: { type: string }) {
  const labels: Record<string, string> = {
    prospecting: 'Prospecting',
    storm_response: 'Storm Response',
    canvassing: 'Canvassing',
  };
  return <span className="text-xs text-muted">{labels[type] || type}</span>;
}

function ScanCard({ scan }: { scan: AreaScanData }) {
  const totalLeads = scan.hotLeads + scan.warmLeads + scan.coldLeads;
  const progress = scan.totalParcels > 0
    ? Math.round((scan.scannedParcels / scan.totalParcels) * 100)
    : 0;

  return (
    <Link
      href={`/dashboard/recon/area-scans/${scan.id}`}
      className="block border border-main rounded-lg p-4 hover:bg-surface-hover transition-colors"
    >
      <div className="flex items-start justify-between mb-3">
        <div>
          <h3 className="text-sm font-medium text-main truncate max-w-[300px]">
            {scan.name || 'Unnamed Scan'}
          </h3>
          <div className="flex items-center gap-2 mt-1">
            <ScanTypeLabel type={scan.scanType} />
            {scan.stormType && (
              <span className="text-xs text-orange-400">
                {scan.stormType}
              </span>
            )}
          </div>
        </div>
        <StatusBadge status={scan.status} />
      </div>

      {/* Progress bar */}
      {scan.status === 'scanning' && (
        <div className="mb-3">
          <div className="flex items-center justify-between text-xs text-muted mb-1">
            <span>{scan.scannedParcels} / {scan.totalParcels} parcels</span>
            <span>{progress}%</span>
          </div>
          <div className="h-1.5 bg-surface rounded-full overflow-hidden">
            <div
              className="h-full bg-accent rounded-full transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      )}

      {/* Lead counts */}
      <div className="flex items-center gap-4 text-xs">
        <div className="flex items-center gap-1">
          <MapPin size={12} className="text-muted" />
          <span className="text-muted">{scan.totalParcels} parcels</span>
        </div>
        {totalLeads > 0 && (
          <>
            <div className="flex items-center gap-1">
              <Flame size={12} className="text-red-400" />
              <span className="text-red-400 font-medium">{scan.hotLeads}</span>
            </div>
            <div className="flex items-center gap-1">
              <Thermometer size={12} className="text-orange-400" />
              <span className="text-orange-400 font-medium">{scan.warmLeads}</span>
            </div>
            <div className="flex items-center gap-1">
              <Snowflake size={12} className="text-blue-400" />
              <span className="text-blue-400 font-medium">{scan.coldLeads}</span>
            </div>
          </>
        )}
      </div>

      <div className="mt-2 text-[11px] text-muted">
        {new Date(scan.createdAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}
      </div>
    </Link>
  );
}

export default function AreaScansPage() {
  const { t } = useTranslation();
  const { scans, loading, error } = useAreaScans();
  const [search, setSearch] = useState('');

  const filtered = search
    ? scans.filter(s =>
      (s.name || '').toLowerCase().includes(search.toLowerCase()) ||
      s.scanType.toLowerCase().includes(search.toLowerCase())
    )
    : scans;

  return (
    <div className="p-6 max-w-6xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <Link
            href="/dashboard/recon"
            className="p-1.5 text-muted hover:text-main rounded-md hover:bg-surface-hover transition-colors"
          >
            <ArrowLeft size={18} />
          </Link>
          <div>
            <h1 className="text-lg font-semibold text-main flex items-center gap-2">
              <Satellite size={20} />
              {t('areaScans.title')}
            </h1>
            <p className="text-sm text-muted mt-0.5">
              Batch scan neighborhoods to find leads
            </p>
          </div>
        </div>

        <Link
          href="/dashboard/recon/area-scans/new"
          className="flex items-center gap-2 px-3 py-2 bg-accent text-white rounded-md text-sm font-medium hover:bg-accent/90 transition-colors"
        >
          <Plus size={16} />
          New Area Scan
        </Link>
      </div>

      {/* Search */}
      <div className="relative mb-4">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
        <input
          type="text"
          placeholder="Search area scans..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="w-full pl-10 pr-4 py-2 border border-main rounded-md bg-surface text-main text-sm placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-accent"
        />
      </div>

      {/* Content */}
      {loading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 size={24} className="animate-spin text-muted" />
        </div>
      ) : error ? (
        <div className="flex items-center justify-center py-20 text-red-400 gap-2">
          <AlertCircle size={18} />
          <span className="text-sm">{error}</span>
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-20">
          <Satellite size={40} className="mx-auto text-muted/30 mb-3" />
          <p className="text-sm text-muted">
            {search ? 'No area scans match your search' : 'No area scans yet'}
          </p>
          {!search && (
            <Link
              href="/dashboard/recon/area-scans/new"
              className="inline-flex items-center gap-1.5 mt-3 text-sm text-accent hover:text-accent/80"
            >
              <Plus size={14} />
              Create your first area scan
            </Link>
          )}
        </div>
      ) : (
        <div className="grid gap-3">
          {filtered.map(scan => (
            <ScanCard key={scan.id} scan={scan} />
          ))}
        </div>
      )}
    </div>
  );
}
