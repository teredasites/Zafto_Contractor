'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  Satellite,
  Play,
  Loader2,
  MapPin,
  Cloud,
  AlertCircle,
} from 'lucide-react';
import { createClient } from '@/lib/supabase';

type ScanType = 'prospecting' | 'storm_response' | 'canvassing';

export default function NewAreaScanPage() {
  const router = useRouter();
  const [name, setName] = useState('');
  const [scanType, setScanType] = useState<ScanType>('prospecting');
  const [stormType, setStormType] = useState('');
  const [stormDate, setStormDate] = useState('');
  const [stormEventId, setStormEventId] = useState('');
  const [polygonInput, setPolygonInput] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = useCallback(async () => {
    setError(null);

    // Parse polygon GeoJSON
    let polygonGeojson: { type: string; coordinates: number[][][] };
    try {
      const parsed = JSON.parse(polygonInput);
      if (parsed.type === 'Polygon' && Array.isArray(parsed.coordinates)) {
        polygonGeojson = parsed;
      } else if (parsed.type === 'Feature' && parsed.geometry?.type === 'Polygon') {
        polygonGeojson = parsed.geometry;
      } else {
        setError('Must be a GeoJSON Polygon or Feature with Polygon geometry');
        return;
      }
    } catch {
      setError('Invalid JSON. Paste a valid GeoJSON polygon.');
      return;
    }

    setSubmitting(true);
    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-area-scan`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({
            name: name || undefined,
            scan_type: scanType,
            polygon_geojson: polygonGeojson,
            storm_event_id: stormEventId || undefined,
            storm_date: stormDate || undefined,
            storm_type: stormType || undefined,
          }),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Area scan failed');

      router.push(`/dashboard/recon/area-scans/${data.area_scan_id}`);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to start area scan');
    } finally {
      setSubmitting(false);
    }
  }, [name, scanType, polygonInput, stormType, stormDate, stormEventId, router]);

  return (
    <div className="p-6 max-w-2xl mx-auto">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <Link
          href="/dashboard/recon/area-scans"
          className="p-1.5 text-muted hover:text-main rounded-md hover:bg-surface-hover transition-colors"
        >
          <ArrowLeft size={18} />
        </Link>
        <div>
          <h1 className="text-lg font-semibold text-main flex items-center gap-2">
            <Satellite size={20} />
            New Area Scan
          </h1>
          <p className="text-sm text-muted mt-0.5">
            Draw a polygon to scan an area for leads
          </p>
        </div>
      </div>

      <div className="space-y-5">
        {/* Name */}
        <div>
          <label className="block text-xs font-medium text-muted mb-1.5">
            Scan Name (optional)
          </label>
          <input
            type="text"
            placeholder="e.g., Riverside Neighborhood"
            value={name}
            onChange={e => setName(e.target.value)}
            className="w-full px-3 py-2 border border-main rounded-md bg-surface text-main text-sm placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-accent"
          />
        </div>

        {/* Scan Type */}
        <div>
          <label className="block text-xs font-medium text-muted mb-1.5">
            Scan Type
          </label>
          <div className="grid grid-cols-3 gap-2">
            {[
              { value: 'prospecting' as ScanType, label: 'Prospecting', icon: MapPin, desc: 'Find new leads' },
              { value: 'storm_response' as ScanType, label: 'Storm Response', icon: Cloud, desc: 'Post-storm targeting' },
              { value: 'canvassing' as ScanType, label: 'Canvassing', icon: MapPin, desc: 'Door-to-door prep' },
            ].map(opt => (
              <button
                key={opt.value}
                onClick={() => setScanType(opt.value)}
                className={`flex flex-col items-center gap-1.5 p-3 rounded-lg border text-center transition-colors ${
                  scanType === opt.value
                    ? 'border-accent bg-accent/5 text-accent'
                    : 'border-main text-muted hover:text-main hover:bg-surface-hover'
                }`}
              >
                <opt.icon size={18} />
                <span className="text-xs font-medium">{opt.label}</span>
                <span className="text-[10px] text-muted">{opt.desc}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Storm fields (shown only for storm_response) */}
        {scanType === 'storm_response' && (
          <div className="space-y-3 p-3 border border-orange-500/20 rounded-lg bg-orange-500/5">
            <div className="flex items-center gap-1.5 text-xs font-medium text-orange-400">
              <Cloud size={14} />
              Storm Details
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-[11px] text-muted mb-1">Storm Type</label>
                <select
                  value={stormType}
                  onChange={e => setStormType(e.target.value)}
                  className="w-full px-2 py-1.5 border border-main rounded-md bg-surface text-main text-sm focus:outline-none focus:ring-1 focus:ring-accent"
                >
                  <option value="">Select...</option>
                  <option value="hail">Hail</option>
                  <option value="wind">Wind</option>
                  <option value="tornado">Tornado</option>
                  <option value="flood">Flood</option>
                </select>
              </div>
              <div>
                <label className="block text-[11px] text-muted mb-1">Storm Date</label>
                <input
                  type="date"
                  value={stormDate}
                  onChange={e => setStormDate(e.target.value)}
                  className="w-full px-2 py-1.5 border border-main rounded-md bg-surface text-main text-sm focus:outline-none focus:ring-1 focus:ring-accent"
                />
              </div>
            </div>
            <div>
              <label className="block text-[11px] text-muted mb-1">Event ID (optional)</label>
              <input
                type="text"
                placeholder="NOAA event ID"
                value={stormEventId}
                onChange={e => setStormEventId(e.target.value)}
                className="w-full px-2 py-1.5 border border-main rounded-md bg-surface text-main text-sm placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-accent"
              />
            </div>
          </div>
        )}

        {/* Polygon Input */}
        <div>
          <label className="block text-xs font-medium text-muted mb-1.5">
            Polygon GeoJSON
          </label>
          <p className="text-[11px] text-muted mb-2">
            Paste a GeoJSON Polygon or Feature. Use{' '}
            <a href="https://geojson.io" target="_blank" rel="noopener noreferrer" className="text-accent hover:underline">
              geojson.io
            </a>
            {' '}to draw your polygon and copy the JSON.
          </p>
          <textarea
            value={polygonInput}
            onChange={e => setPolygonInput(e.target.value)}
            placeholder='{"type":"Polygon","coordinates":[[[-97.1,32.7],[-97.1,32.75],[-97.05,32.75],[-97.05,32.7],[-97.1,32.7]]]}'
            rows={6}
            className="w-full px-3 py-2 border border-main rounded-md bg-surface text-main text-sm font-mono placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-accent resize-y"
          />
        </div>

        {/* Error */}
        {error && (
          <div className="flex items-center gap-2 text-sm text-red-400 bg-red-500/10 border border-red-500/20 rounded-md px-3 py-2">
            <AlertCircle size={14} />
            {error}
          </div>
        )}

        {/* Submit */}
        <button
          onClick={handleSubmit}
          disabled={!polygonInput || submitting}
          className="w-full flex items-center justify-center gap-2 px-4 py-2.5 bg-accent text-white rounded-md text-sm font-medium hover:bg-accent/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {submitting ? (
            <>
              <Loader2 size={16} className="animate-spin" />
              Scanning area...
            </>
          ) : (
            <>
              <Play size={16} />
              Start Area Scan
            </>
          )}
        </button>
      </div>
    </div>
  );
}
