'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  Satellite,
  Search,
  ArrowRight,
  Shield,
  MapPin,
  Loader2,
  Layers,
  Home,
  CloudLightning,
  Target,
  Wrench,
  RefreshCw,
  BarChart3,
  Zap,
  ChevronRight,
  Calendar,
  TrendingUp,
  AlertTriangle,
  Map,
  Trash2,
  X,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { StatusBadge } from '@/components/ui/badge';
import { formatDate, cn } from '@/lib/utils';
import { usePropertyScans, type ConfidenceGrade } from '@/lib/hooks/use-property-scan';
import { getSupabase } from '@/lib/supabase';
import { useTranslation } from '@/lib/translations';

// Mapbox Geocoding — address autocomplete
const MAPBOX_TOKEN = process.env.NEXT_PUBLIC_MAPBOX_TOKEN;

interface GeocodingSuggestion {
  id: string;
  place_name: string;
  center: [number, number];
}

function useAddressAutocomplete() {
  const [query, setQuery] = useState('');
  const [suggestions, setSuggestions] = useState<GeocodingSuggestion[]>([]);
  const [isOpen, setIsOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const search = useCallback((text: string) => {
    setQuery(text);
    if (timerRef.current) clearTimeout(timerRef.current);

    if (!text.trim() || text.trim().length < 3 || !MAPBOX_TOKEN) {
      setSuggestions([]);
      setIsOpen(false);
      return;
    }

    timerRef.current = setTimeout(async () => {
      setLoading(true);
      try {
        const encoded = encodeURIComponent(text.trim());
        const res = await fetch(
          `https://api.mapbox.com/geocoding/v5/mapbox.places/${encoded}.json?access_token=${MAPBOX_TOKEN}&types=address&country=us&limit=5`
        );
        if (!res.ok) throw new Error('Geocoding failed');
        const data = await res.json();
        const results: GeocodingSuggestion[] = (data.features || []).map((f: { id: string; place_name: string; center: [number, number] }) => ({
          id: f.id,
          place_name: f.place_name,
          center: f.center,
        }));
        setSuggestions(results);
        setIsOpen(results.length > 0);
      } catch {
        setSuggestions([]);
        setIsOpen(false);
      } finally {
        setLoading(false);
      }
    }, 300);
  }, []);

  const select = useCallback((suggestion: GeocodingSuggestion) => {
    setQuery(suggestion.place_name);
    setSuggestions([]);
    setIsOpen(false);
  }, []);

  const close = useCallback(() => {
    setIsOpen(false);
  }, []);

  return { query, setQuery: search, suggestions, isOpen, loading, select, close };
}

const STATUS_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
  complete: { label: 'Complete', color: '#10B981', bg: 'rgba(16,185,129,0.1)' },
  partial: { label: 'Partial', color: '#F59E0B', bg: 'rgba(245,158,11,0.1)' },
  pending: { label: 'Pending', color: '#3B82F6', bg: 'rgba(59,130,246,0.1)' },
  failed: { label: 'Failed', color: '#EF4444', bg: 'rgba(239,68,68,0.1)' },
  cancelled: { label: 'Cancelled', color: '#6B7280', bg: 'rgba(107,114,128,0.1)' },
};

export default function ReconPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const { scans, loading, error, refetch } = usePropertyScans();
  const [searchQuery, setSearchQuery] = useState('');
  const [scanning, setScanning] = useState(false);
  const [scanError, setScanError] = useState<string | null>(null);
  const autocomplete = useAddressAutocomplete();
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        autocomplete.close();
      }
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, [autocomplete]);

  const selectedCoordsRef = useRef<[number, number] | null>(null);

  const handleScan = async (addressOverride?: string) => {
    const address = (addressOverride || autocomplete.query).trim();
    if (!address || scanning) return;
    setScanning(true);
    setScanError(null);
    autocomplete.close();
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      // Pass Mapbox-resolved coordinates if available (avoids needing Google geocoding)
      const coords = selectedCoordsRef.current;
      const payload: Record<string, unknown> = { address };
      if (coords) {
        payload.longitude = coords[0];
        payload.latitude = coords[1];
      }

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-property-lookup`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify(payload),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Scan failed');

      autocomplete.setQuery('');
      selectedCoordsRef.current = null;
      refetch();
      if (data.scan_id) {
        router.push(`/dashboard/recon/${data.scan_id}`);
      }
    } catch (e) {
      setScanError(e instanceof Error ? e.message : 'Scan failed');
    } finally {
      setScanning(false);
    }
  };

  const handleDeleteScan = async (scanId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    e.preventDefault();
    const supabase = getSupabase();
    await supabase
      .from('property_scans')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', scanId);
    refetch();
  };

  const handleClearAll = async () => {
    if (!confirm('Delete all scan history? This cannot be undone.')) return;
    const supabase = getSupabase();
    const ids = scans.map(s => s.id);
    if (ids.length === 0) return;
    for (const id of ids) {
      await supabase
        .from('property_scans')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', id);
    }
    refetch();
  };

  const filtered = scans.filter(s =>
    s.address.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (s.city || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
    (s.state || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  const stats = {
    total: scans.length,
    complete: scans.filter(s => s.status === 'complete').length,
    highConf: scans.filter(s => s.confidenceGrade === 'high').length,
  };

  return (
    <div className="space-y-5">
      {/* ── SCAN BAR ─────────────────────────────────── */}
      <div className="rounded-xl border border-main bg-card p-4">
        <div className="flex gap-3">
          <div className="relative flex-1" ref={dropdownRef}>
            <Satellite size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-accent z-10" />
            <input
              type="text"
              placeholder="Enter an address to scan — roof, walls, solar, storm data instantly..."
              value={autocomplete.query}
              onChange={(e) => autocomplete.setQuery(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') handleScan(); if (e.key === 'Escape') autocomplete.close(); }}
              onFocus={() => { if (autocomplete.suggestions.length > 0) autocomplete.close(); }}
              disabled={scanning}
              autoComplete="off"
              style={{ color: 'var(--text)', backgroundColor: 'var(--surface)', caretColor: 'var(--accent)' }}
              className="w-full pl-10 pr-4 py-3 rounded-lg border border-main text-sm placeholder:text-neutral-500 focus:outline-none focus:ring-2 focus:ring-accent disabled:opacity-50"
            />
            {autocomplete.loading && (
              <Loader2 size={14} className="absolute right-3 top-1/2 -translate-y-1/2 animate-spin text-neutral-400" />
            )}

            {autocomplete.isOpen && (
              <div className="absolute top-full left-0 right-0 mt-1 rounded-lg border border-main overflow-hidden shadow-lg z-50"
                   style={{ backgroundColor: 'var(--surface)' }}>
                {autocomplete.suggestions.map((s) => (
                  <button
                    key={s.id}
                    onClick={() => {
                      selectedCoordsRef.current = s.center;
                      autocomplete.select(s);
                      handleScan(s.place_name);
                    }}
                    className="w-full flex items-center gap-3 px-4 py-2.5 text-left text-sm hover:bg-accent/10 transition-colors"
                    style={{ color: 'var(--text)' }}
                  >
                    <MapPin size={14} className="shrink-0 text-accent" />
                    <span className="truncate">{s.place_name}</span>
                  </button>
                ))}
              </div>
            )}
          </div>
          <Button onClick={() => handleScan()} disabled={!autocomplete.query.trim() || scanning} className="px-6 shrink-0">
            {scanning ? (
              <><Loader2 size={16} className="animate-spin mr-2" />Scanning...</>
            ) : (
              <><Satellite size={16} className="mr-2" />Scan Property</>
            )}
          </Button>
        </div>

        {scanError && <p className="mt-2 text-sm text-red-500">{scanError}</p>}
        {!MAPBOX_TOKEN && <p className="mt-2 text-xs text-amber-500">Address autocomplete unavailable — NEXT_PUBLIC_MAPBOX_TOKEN not configured.</p>}
      </div>

      {/* ── STATS ROW ────────────────────────────────── */}
      {!loading && scans.length > 0 && (
        <div className="grid grid-cols-3 gap-3">
          <div className="rounded-lg border border-main bg-card px-4 py-3 flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-accent/10 flex items-center justify-center">
              <Satellite size={16} className="text-accent" />
            </div>
            <div>
              <p className="text-lg font-bold text-main">{stats.total}</p>
              <p className="text-[11px] text-muted">Total Scans</p>
            </div>
          </div>
          <div className="rounded-lg border border-main bg-card px-4 py-3 flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-emerald-500/10 flex items-center justify-center">
              <TrendingUp size={16} className="text-emerald-400" />
            </div>
            <div>
              <p className="text-lg font-bold text-main">{stats.complete}</p>
              <p className="text-[11px] text-muted">Complete</p>
            </div>
          </div>
          <div className="rounded-lg border border-main bg-card px-4 py-3 flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-blue-500/10 flex items-center justify-center">
              <Shield size={16} className="text-blue-400" />
            </div>
            <div>
              <p className="text-lg font-bold text-main">{stats.highConf}</p>
              <p className="text-[11px] text-muted">High Confidence</p>
            </div>
          </div>
        </div>
      )}

      {/* ── ERROR ─────────────────────────────────────── */}
      {error && (
        <div className="flex items-center justify-between bg-red-900/20 border border-red-800/50 rounded-lg px-4 py-2.5">
          <p className="text-sm text-red-400">{error}</p>
          <button onClick={refetch} className="flex items-center gap-1.5 text-xs text-red-400 hover:text-red-300 transition-colors">
            <RefreshCw size={12} /> Retry
          </button>
        </div>
      )}

      {/* ── TOOLBAR ───────────────────────────────────── */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h2 className="text-sm font-semibold text-main">
            {t('recon.title')}{!loading && scans.length > 0 ? ` (${filtered.length})` : ''}
          </h2>
        </div>
        <div className="flex items-center gap-2">
          <div className="relative">
            <Search size={14} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-muted" />
            <input
              type="text"
              placeholder="Filter..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-44 pl-8 pr-3 py-1.5 rounded-lg border border-main bg-surface text-xs text-main placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-accent"
            />
          </div>
          <Link href="/dashboard/recon/area-scans"
            className="flex items-center gap-1.5 px-3 py-1.5 border border-main rounded-lg text-xs font-medium text-muted hover:text-main hover:bg-surface-hover transition-colors">
            <Target size={13} /> Area Scans
          </Link>
          {scans.length > 0 && (
            <button
              onClick={handleClearAll}
              className="flex items-center gap-1.5 px-3 py-1.5 border border-red-800/50 rounded-lg text-xs font-medium text-red-400 hover:text-red-300 hover:bg-red-900/20 transition-colors"
            >
              <Trash2 size={13} /> Clear All
            </button>
          )}
        </div>
      </div>

      {/* ── LOADING ───────────────────────────────────── */}
      {loading && (
        <div className="flex items-center justify-center py-16">
          <Loader2 size={18} className="animate-spin text-muted" />
          <span className="ml-2 text-sm text-muted">Loading scans...</span>
        </div>
      )}

      {/* ── EMPTY ─────────────────────────────────────── */}
      {!loading && !error && filtered.length === 0 && (
        <div className="text-center py-16 rounded-xl border border-dashed border-main bg-surface/30">
          <Satellite size={36} className="mx-auto mb-3 text-muted/50" />
          <p className="text-sm font-medium text-main mb-1">
            {searchQuery ? 'No scans match your filter' : 'No property scans yet'}
          </p>
          <p className="text-xs text-muted">
            {searchQuery ? 'Try a different search term.' : 'Enter an address above to run your first property scan.'}
          </p>
        </div>
      )}

      {/* ── SCAN CARDS ────────────────────────────────── */}
      {!loading && filtered.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
          {filtered.map((scan) => {
            const status = STATUS_CONFIG[scan.status] || STATUS_CONFIG.pending;
            const confColor = scan.confidenceGrade === 'high' ? '#10B981' : scan.confidenceGrade === 'moderate' ? '#F59E0B' : '#EF4444';
            const hasCoords = scan.latitude != null && scan.longitude != null;
            const thumbUrl = hasCoords && MAPBOX_TOKEN
              ? `https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/${scan.longitude},${scan.latitude},17,0/400x200@2x?access_token=${MAPBOX_TOKEN}`
              : null;

            return (
              <div
                key={scan.id}
                onClick={() => router.push(`/dashboard/recon/${scan.id}`)}
                className="rounded-xl border border-main bg-card overflow-hidden cursor-pointer hover:border-accent/30 transition-all group"
              >
                {/* Satellite thumbnail */}
                <div className="relative h-32 bg-surface overflow-hidden">
                  {thumbUrl ? (
                    <img
                      src={thumbUrl}
                      alt={`Satellite view of ${scan.address}`}
                      className="absolute inset-0 w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                      loading="lazy"
                    />
                  ) : (
                    <div className="absolute inset-0 flex items-center justify-center bg-surface">
                      <Map size={20} className="text-muted/30" />
                    </div>
                  )}

                  {/* Status pill */}
                  <div className="absolute top-2 left-2">
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold backdrop-blur-sm"
                      style={{ color: status.color, backgroundColor: `${status.bg}CC` }}>
                      <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: status.color }} />
                      {status.label}
                    </span>
                  </div>

                  {/* Confidence pill */}
                  <div className="absolute top-2 right-2 flex items-center gap-1">
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold bg-black/60 backdrop-blur-sm"
                      style={{ color: confColor }}>
                      <Shield size={9} />
                      {scan.confidenceScore}%
                    </span>
                    <button
                      onClick={(e) => handleDeleteScan(scan.id, e)}
                      className="w-5 h-5 rounded-md bg-black/60 backdrop-blur-sm flex items-center justify-center text-neutral-400 hover:text-red-400 hover:bg-red-900/60 transition-colors opacity-0 group-hover:opacity-100"
                      title="Delete scan"
                    >
                      <X size={10} />
                    </button>
                  </div>
                </div>

                {/* Card body */}
                <div className="p-3">
                  <h3 className="text-sm font-semibold text-main truncate mb-0.5 group-hover:text-accent transition-colors">
                    {scan.address}
                  </h3>
                  <p className="text-[11px] text-muted mb-2">
                    {[scan.city, scan.state, scan.zip].filter(Boolean).join(', ')}
                  </p>

                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2 flex-wrap">
                      {scan.scanSources?.length > 0 && (
                        <span className="text-[10px] text-muted">
                          {scan.scanSources.length} source{scan.scanSources.length !== 1 ? 's' : ''}
                        </span>
                      )}
                      {scan.floodZone && (
                        <span className="text-[10px] font-medium" style={{ color: scan.floodRisk === 'high' ? '#EF4444' : scan.floodRisk === 'moderate' ? '#F59E0B' : '#10B981' }}>
                          Zone {scan.floodZone}
                        </span>
                      )}
                      {Object.keys(scan.externalLinks || {}).length > 0 && (
                        <span className="text-[10px] text-muted">
                          {Object.keys(scan.externalLinks).length} links
                        </span>
                      )}
                      {scan.imageryDate && (
                        <span className="text-[10px] text-muted flex items-center gap-0.5">
                          <Calendar size={8} /> {formatDate(scan.imageryDate)}
                        </span>
                      )}
                    </div>
                    <ChevronRight size={12} className="text-muted group-hover:text-accent transition-colors" />
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
