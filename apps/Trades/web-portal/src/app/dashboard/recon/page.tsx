'use client';

import { useState } from 'react';
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
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge } from '@/components/ui/badge';
import { formatDate, cn } from '@/lib/utils';
import { usePropertyScans, type ConfidenceGrade } from '@/lib/hooks/use-property-scan';
import { getSupabase } from '@/lib/supabase';

const CAPABILITIES = [
  { icon: <Home size={16} />, label: 'Roof Analysis', detail: 'Area, pitch, ridges, valleys, facets, material ID', color: 'text-emerald-400 bg-emerald-500/10' },
  { icon: <Layers size={16} />, label: 'Wall Measurements', detail: 'Siding area, trim, fascia, soffit per face', color: 'text-blue-400 bg-blue-500/10' },
  { icon: <Wrench size={16} />, label: 'Trade Estimates', detail: '10 trades: roofing, siding, gutters, solar...', color: 'text-purple-400 bg-purple-500/10' },
  { icon: <BarChart3 size={16} />, label: 'Material Takeoffs', detail: 'Quantities, waste factors, crew sizing', color: 'text-orange-400 bg-orange-500/10' },
  { icon: <Target size={16} />, label: 'Lead Scoring', detail: 'Confidence grade + priority ranking', color: 'text-pink-400 bg-pink-500/10' },
  { icon: <CloudLightning size={16} />, label: 'Storm Assessment', detail: 'Hail, wind, and flood damage indicators', color: 'text-amber-400 bg-amber-500/10' },
  { icon: <Zap size={16} />, label: 'Multi-Source Intel', detail: 'Google Solar, USGS, MS Footprints, ATTOM', color: 'text-cyan-400 bg-cyan-500/10' },
  { icon: <MapPin size={16} />, label: 'Area Scans', detail: 'Batch scan entire neighborhoods at once', color: 'text-teal-400 bg-teal-500/10' },
];

const GRADE_CONFIG: Record<ConfidenceGrade, { label: string; variant: string }> = {
  high: { label: 'High', variant: 'success' },
  moderate: { label: 'Moderate', variant: 'warning' },
  low: { label: 'Low', variant: 'error' },
};

export default function ReconPage() {
  const router = useRouter();
  const { scans, loading, error, refetch } = usePropertyScans();
  const [searchQuery, setSearchQuery] = useState('');
  const [scanAddress, setScanAddress] = useState('');
  const [scanning, setScanning] = useState(false);
  const [scanError, setScanError] = useState<string | null>(null);

  const handleScan = async () => {
    const address = scanAddress.trim();
    if (!address || scanning) return;
    setScanning(true);
    setScanError(null);
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-property-lookup`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ address }),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Scan failed');

      setScanAddress('');
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

  const filtered = scans.filter(s =>
    s.address.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (s.city || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
    (s.state || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Hero — Property Scan */}
      <div className="relative overflow-hidden rounded-xl border border-main bg-gradient-to-br from-surface to-accent/5 p-6">
        <div className="relative z-10">
          <div className="flex items-center gap-3 mb-1">
            <div className="w-10 h-10 rounded-lg bg-accent/10 flex items-center justify-center">
              <Satellite size={20} className="text-accent" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-main">Property Intelligence</h1>
              <p className="text-sm text-muted">Scan any address for instant roof, wall, and trade measurements</p>
            </div>
          </div>

          {/* Address Input */}
          <div className="mt-4 flex gap-3">
            <div className="relative flex-1">
              <MapPin size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
              <input
                type="text"
                placeholder="Enter property address (e.g. 123 Main St, Springfield, IL 62701)"
                value={scanAddress}
                onChange={(e) => setScanAddress(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter') handleScan(); }}
                disabled={scanning}
                className="w-full pl-10 pr-4 py-3 rounded-lg border border-main bg-surface text-main text-sm placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent disabled:opacity-50"
              />
            </div>
            <Button onClick={handleScan} disabled={!scanAddress.trim() || scanning} className="px-6">
              {scanning ? (
                <><Loader2 size={16} className="animate-spin mr-2" />Scanning...</>
              ) : (
                <><Satellite size={16} className="mr-2" />Scan Property</>
              )}
            </Button>
          </div>

          {scanError && (
            <p className="mt-2 text-sm text-red-500">{scanError}</p>
          )}
        </div>
        <div className="absolute -right-8 -top-8 w-36 h-36 rounded-full bg-accent/5" />
        <div className="absolute -right-4 -bottom-10 w-28 h-28 rounded-full bg-accent/5" />
      </div>

      {/* Capabilities Grid — ALWAYS visible */}
      <div>
        <h2 className="text-sm font-medium text-muted mb-3 uppercase tracking-wider">Scan Capabilities</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-4 xl:grid-cols-8 gap-3">
          {CAPABILITIES.map((cap) => {
            const [textColor, bgColor] = cap.color.split(' ');
            return (
              <div key={cap.label} className="p-3 rounded-lg border border-main bg-surface hover:border-accent/30 transition-colors text-center">
                <div className={`w-8 h-8 mx-auto mb-2 rounded-lg ${bgColor} flex items-center justify-center`}>
                  <span className={textColor}>{cap.icon}</span>
                </div>
                <p className="text-xs font-medium text-main">{cap.label}</p>
                <p className="text-[10px] text-muted mt-0.5 leading-tight">{cap.detail}</p>
              </div>
            );
          })}
        </div>
      </div>

      {/* Error Banner (small, doesn't block content) */}
      {error && (
        <div className="flex items-center justify-between bg-red-900/20 border border-red-800/50 rounded-lg px-4 py-2.5">
          <p className="text-sm text-red-400">{error}</p>
          <button
            onClick={refetch}
            className="flex items-center gap-1.5 text-xs text-red-400 hover:text-red-300 transition-colors"
          >
            <RefreshCw size={12} />
            Retry
          </button>
        </div>
      )}

      {/* Scans Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-sm font-medium text-muted uppercase tracking-wider">
          Recent Scans{!loading && scans.length > 0 ? ` (${scans.length})` : ''}
        </h2>
        <div className="flex items-center gap-3">
          <div className="relative">
            <Search size={14} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-muted" />
            <input
              type="text"
              placeholder="Filter scans..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-48 pl-8 pr-3 py-1.5 rounded-md border border-main bg-surface text-xs text-main placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-accent"
            />
          </div>
          <Link
            href="/dashboard/recon/area-scans"
            className="flex items-center gap-2 px-3 py-1.5 border border-main rounded-md text-xs text-muted hover:text-main hover:bg-surface-hover transition-colors"
          >
            <MapPin size={14} />
            Area Scans
            <ArrowRight size={12} />
          </Link>
        </div>
      </div>

      {/* Loading */}
      {loading && (
        <div className="flex items-center justify-center py-8">
          <Loader2 size={18} className="animate-spin text-muted" />
          <span className="ml-2 text-sm text-muted">Loading scans...</span>
        </div>
      )}

      {/* Empty */}
      {!loading && !error && filtered.length === 0 && (
        <div className="text-center py-8 rounded-xl border border-dashed border-main bg-surface/50">
          <Satellite size={32} className="mx-auto mb-3 text-muted" />
          <p className="text-sm font-medium text-main mb-1">
            {searchQuery ? 'No scans match your filter' : 'No property scans yet'}
          </p>
          <p className="text-xs text-muted">
            {searchQuery ? 'Try a different search term.' : 'Enter an address above to run your first property scan.'}
          </p>
        </div>
      )}

      {/* Scan List */}
      {!loading && filtered.length > 0 && (
        <div className="space-y-2">
          {filtered.map((scan) => (
            <Card
              key={scan.id}
              className="cursor-pointer hover:border-accent transition-colors"
              onClick={() => router.push(`/dashboard/recon/${scan.id}`)}
            >
              <CardContent className="py-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="shrink-0 w-9 h-9 rounded-lg bg-accent/10 flex items-center justify-center">
                      <Satellite size={16} className="text-accent" />
                    </div>
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-main truncate">{scan.address}</p>
                      <p className="text-xs text-muted">
                        {[scan.city, scan.state, scan.zip].filter(Boolean).join(', ')}
                        {scan.imageryDate && ` — Imagery: ${formatDate(scan.imageryDate)}`}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 shrink-0">
                    <div className="flex items-center gap-2">
                      <StatusBadge status={scan.status === 'complete' ? 'completed' : scan.status === 'partial' ? 'pending' : scan.status === 'failed' ? 'cancelled' : 'pending'} />
                      <div className={cn(
                        'flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium',
                        scan.confidenceGrade === 'high' ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400' :
                        scan.confidenceGrade === 'moderate' ? 'bg-amber-500/10 text-amber-600 dark:text-amber-400' :
                        'bg-red-500/10 text-red-600 dark:text-red-400'
                      )}>
                        <Shield size={10} />
                        {scan.confidenceScore}%
                      </div>
                    </div>
                    <ArrowRight size={16} className="text-muted" />
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
