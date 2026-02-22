'use client';

import { useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  Satellite,
  Ruler,
  Layers,
  BarChart3,
  Sun,
  Shield,
  AlertTriangle,
  Package,
  Users,
  Clock,
  RefreshCw,
  FileText,
  CloudLightning,
  Wind,
  CircleDot,
  Loader2,
  ShieldAlert,
  Home,
  Compass,
  Activity,
  Zap,
  Droplet,
  Flame,
  Thermometer,
  TrendingUp,
  Info,
  ChevronRight,
  MapPin,
  Calendar,
  Database,
  Map,
  PenTool,
  Building,
  ExternalLink,
  FolderOpen,
  type LucideIcon,
} from 'lucide-react';

const MAPBOX_TOKEN = process.env.NEXT_PUBLIC_MAPBOX_TOKEN;
import { Button } from '@/components/ui/button';
import { formatDate, cn } from '@/lib/utils';
import {
  usePropertyScan,
  type PropertyScanData,
  type RoofMeasurementData,
  type RoofFacetData,
  type WallMeasurementData,
  type TradeBidData,
  type TradeType,
} from '@/lib/hooks/use-property-scan';
import { useStormAssess } from '@/lib/hooks/use-storm-assess';

type TabType = 'roof' | 'walls' | 'trades' | 'solar' | 'storm';

const STATUS_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
  complete: { label: 'Complete', color: '#10B981', bg: 'rgba(16,185,129,0.1)' },
  partial: { label: 'Partial', color: '#F59E0B', bg: 'rgba(245,158,11,0.1)' },
  pending: { label: 'Pending', color: '#3B82F6', bg: 'rgba(59,130,246,0.1)' },
  failed: { label: 'Failed', color: '#EF4444', bg: 'rgba(239,68,68,0.1)' },
  cancelled: { label: 'Cancelled', color: '#6B7280', bg: 'rgba(107,114,128,0.1)' },
};

const TABS: { key: TabType; label: string; icon: LucideIcon; color: string }[] = [
  { key: 'roof', label: 'Roof', icon: Home, color: '#8B5CF6' },
  { key: 'walls', label: 'Walls', icon: Ruler, color: '#3B82F6' },
  { key: 'trades', label: 'Trade Data', icon: BarChart3, color: '#10B981' },
  { key: 'solar', label: 'Solar', icon: Sun, color: '#F59E0B' },
  { key: 'storm', label: 'Storm', icon: CloudLightning, color: '#EF4444' },
];

const TRADE_LABELS: Record<TradeType, string> = {
  roofing: 'Roofing', siding: 'Siding / Exterior', gutters: 'Gutters', solar: 'Solar',
  painting: 'Painting', landscaping: 'Landscaping', fencing: 'Fencing', concrete: 'Concrete / Paving',
  hvac: 'HVAC', electrical: 'Electrical', plumbing: 'Plumbing', insulation: 'Insulation',
  windows_doors: 'Windows & Doors', flooring: 'Flooring', drywall: 'Drywall', framing: 'Framing',
  masonry: 'Masonry', waterproofing: 'Waterproofing', demolition: 'Demolition', tree_service: 'Tree Service',
  pool: 'Pool', garage_door: 'Garage Door', fire_protection: 'Fire Protection', elevator: 'Elevator',
  fire_alarm: 'Fire Alarm', low_voltage: 'Low Voltage', irrigation: 'Irrigation', paving: 'Paving',
  metal_fabrication: 'Metal Fabrication', glass_glazing: 'Glass & Glazing',
};

const TRADE_ICONS: Partial<Record<TradeType, LucideIcon>> = {
  roofing: Home, siding: Layers, electrical: Zap, plumbing: Droplet,
  hvac: Wind, solar: Sun, fire_protection: Flame, painting: Activity,
  insulation: Thermometer, concrete: Compass,
};

const TRADE_COLORS: Partial<Record<TradeType, string>> = {
  roofing: '#8B5CF6', siding: '#06B6D4', gutters: '#64748B', solar: '#F59E0B',
  painting: '#F472B6', electrical: '#F59E0B', plumbing: '#3B82F6', hvac: '#10B981',
  insulation: '#EC4899', concrete: '#78716C', framing: '#D97706', drywall: '#6B7280',
  flooring: '#14B8A6', demolition: '#F97316', fire_protection: '#DC2626',
  landscaping: '#22C55E', fencing: '#A78BFA',
};

const SHAPE_LABELS: Record<string, string> = {
  gable: 'Gable', hip: 'Hip', flat: 'Flat', gambrel: 'Gambrel', mansard: 'Mansard', mixed: 'Complex/Mixed',
};

const SOURCE_COLORS: Record<string, string> = {
  google_solar: '#F59E0B',
  usgs: '#10B981',
  ms_footprints: '#3B82F6',
  attom: '#8B5CF6',
  regrid: '#EC4899',
  nominatim: '#06B6D4',
  census_geocoder: '#64748B',
  google_streetview: '#DC2626',
  fema_flood: '#0EA5E9',
};

const SOURCE_LABELS: Record<string, string> = {
  google_solar: 'Google Solar',
  usgs: 'USGS Elevation',
  ms_footprints: 'Building Footprints',
  attom: 'ATTOM Property',
  regrid: 'Regrid Parcels',
  nominatim: 'OpenStreetMap',
  census_geocoder: 'US Census',
  google_streetview: 'Street View',
  fema_flood: 'FEMA Flood',
};

const EXTERNAL_LINK_LABELS: Record<string, { label: string; color: string }> = {
  zillow: { label: 'Zillow', color: '#006AFF' },
  redfin: { label: 'Redfin', color: '#A02021' },
  realtor: { label: 'Realtor.com', color: '#D92228' },
  trulia: { label: 'Trulia', color: '#3BB87C' },
  google_maps: { label: 'Google Maps', color: '#4285F4' },
  fema_flood_map: { label: 'FEMA Flood Map', color: '#0EA5E9' },
  county_assessor: { label: 'County Assessor', color: '#8B5CF6' },
};

const FLOOD_RISK_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
  high: { label: 'High Risk', color: '#EF4444', bg: 'rgba(239,68,68,0.1)' },
  moderate: { label: 'Moderate', color: '#F59E0B', bg: 'rgba(245,158,11,0.1)' },
  low: { label: 'Low Risk', color: '#3B82F6', bg: 'rgba(59,130,246,0.1)' },
  minimal: { label: 'Minimal', color: '#10B981', bg: 'rgba(16,185,129,0.1)' },
};

// ============================================================================
// SHARED COMPONENTS
// ============================================================================

function KpiStrip({ items }: {
  items: { label: string; value: string | number; unit?: string; icon?: LucideIcon; color?: string }[];
}) {
  return (
    <div className="grid gap-px bg-main/10 rounded-xl overflow-hidden" style={{ gridTemplateColumns: `repeat(${items.length}, 1fr)` }}>
      {items.map((item, i) => (
        <div key={i} className="bg-card px-4 py-3.5 flex items-center gap-3">
          {item.icon && (
            <div className="w-9 h-9 rounded-lg flex items-center justify-center shrink-0"
              style={{ backgroundColor: `${item.color || 'var(--accent)'}15` }}>
              <item.icon size={16} style={{ color: item.color || 'var(--accent)' }} />
            </div>
          )}
          <div className="min-w-0">
            <p className="text-[10px] font-medium text-muted uppercase tracking-wider">{item.label}</p>
            <p className="text-lg font-bold text-main leading-tight">
              {typeof item.value === 'number' ? item.value.toLocaleString() : item.value}
              {item.unit && <span className="text-xs font-normal text-muted ml-1">{item.unit}</span>}
            </p>
          </div>
        </div>
      ))}
    </div>
  );
}

function DataRow({ label, value, unit, highlight, mono }: {
  label: string; value: string | number; unit?: string; highlight?: boolean; mono?: boolean;
}) {
  return (
    <div className={cn('flex justify-between items-center py-2 px-3 rounded-lg', highlight && 'bg-accent/5')}>
      <span className="text-[13px] text-muted">{label}</span>
      <span className={cn('text-[13px] font-semibold', mono && 'font-mono', highlight ? 'text-accent' : 'text-main')}>
        {typeof value === 'number' ? value.toLocaleString() : value}
        {unit && <span className="text-muted ml-1 font-normal text-xs">{unit}</span>}
      </span>
    </div>
  );
}

function Panel({ title, icon: Icon, color, actions, children, className, noPad }: {
  title: string; icon?: LucideIcon; color?: string; actions?: React.ReactNode;
  children: React.ReactNode; className?: string; noPad?: boolean;
}) {
  return (
    <div className={cn('rounded-xl bg-card border border-main overflow-hidden', className)}>
      <div className="px-4 py-2.5 border-b border-main flex items-center gap-2.5">
        {Icon && <Icon size={14} style={{ color: color || 'var(--accent)' }} />}
        <h3 className="text-[13px] font-semibold text-main flex-1">{title}</h3>
        {actions}
      </div>
      <div className={noPad ? '' : 'p-4'}>{children}</div>
    </div>
  );
}

function ConfidenceBadge({ score, grade }: { score: number; grade: string }) {
  const color = grade === 'high' ? '#10B981' : grade === 'moderate' ? '#F59E0B' : '#EF4444';
  const label = grade === 'high' ? 'High' : grade === 'moderate' ? 'Moderate' : 'Low';
  return (
    <div className="flex items-center gap-2.5">
      <div className="relative w-11 h-11">
        <svg className="w-11 h-11 -rotate-90" viewBox="0 0 48 48">
          <circle cx="24" cy="24" r="18" fill="none" strokeWidth="3.5" className="stroke-current text-main/10" />
          <circle cx="24" cy="24" r="18" fill="none" strokeWidth="3.5" strokeLinecap="round"
            strokeDasharray={`${2 * Math.PI * 18}`}
            strokeDashoffset={`${2 * Math.PI * 18 * (1 - score / 100)}`}
            style={{ stroke: color, transition: 'stroke-dashoffset 0.5s ease' }} />
        </svg>
        <span className="absolute inset-0 flex items-center justify-center text-[10px] font-bold text-main">{score}</span>
      </div>
      <div>
        <p className="text-xs font-bold" style={{ color }}>{label}</p>
        <p className="text-[10px] text-muted">Confidence</p>
      </div>
    </div>
  );
}

function EmptyTab({ icon: Icon, title, description, action, onAction, loading }: {
  icon: LucideIcon; title: string; description: string;
  action?: string; onAction?: () => void; loading?: boolean;
}) {
  return (
    <div className="rounded-xl bg-card border border-dashed border-main/50 p-10 text-center">
      <div className="w-12 h-12 mx-auto rounded-xl bg-accent/10 flex items-center justify-center mb-3">
        <Icon size={22} className="text-accent" />
      </div>
      <h3 className="text-sm font-semibold text-main mb-1.5">{title}</h3>
      <p className="text-xs text-muted max-w-md mx-auto mb-5 leading-relaxed">{description}</p>
      {action && onAction && (
        <Button variant="primary" size="sm" onClick={onAction} disabled={loading}>
          {loading ? <Loader2 size={14} className="animate-spin" /> : <ChevronRight size={14} />}
          {loading ? 'Processing...' : action}
        </Button>
      )}
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

// Generate Mapbox satellite image URL
function getSatelliteUrl(lat: number, lng: number, zoom = 18, w = 800, h = 400) {
  if (!MAPBOX_TOKEN) return null;
  return `https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/${lng},${lat},${zoom},0/${w}x${h}@2x?access_token=${MAPBOX_TOKEN}`;
}

// Generate Mapbox satellite-streets overlay (with labels + roads)
function getSatelliteStreetsUrl(lat: number, lng: number, zoom = 17, w = 800, h = 400) {
  if (!MAPBOX_TOKEN) return null;
  return `https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/static/pin-l+ff3b30(${lng},${lat})/${lng},${lat},${zoom},0/${w}x${h}@2x?access_token=${MAPBOX_TOKEN}`;
}

// Generate Mapbox streets map URL
function getStreetMapUrl(lat: number, lng: number, zoom = 16, w = 400, h = 400) {
  if (!MAPBOX_TOKEN) return null;
  return `https://api.mapbox.com/styles/v1/mapbox/dark-v11/static/pin-l+3b82f6(${lng},${lat})/${lng},${lat},${zoom},0/${w}x${h}@2x?access_token=${MAPBOX_TOKEN}`;
}

export default function ReconDetailPage() {
  const router = useRouter();
  const params = useParams();
  const scanId = params.id as string;
  const [activeTab, setActiveTab] = useState<TabType>('roof');
  const [selectedTrade, setSelectedTrade] = useState<TradeType | null>(null);
  const [estimating, setEstimating] = useState(false);
  const [imgView, setImgView] = useState<'satellite' | 'streets' | 'streetview'>('satellite');

  const { scan, roof, facets, walls, tradeBids, loading, error, triggerTradeEstimate } = usePropertyScan(scanId, 'scan');

  const handleEstimate = useCallback(async () => {
    if (!scan) return;
    setEstimating(true);
    await triggerTradeEstimate(scan.id);
    setEstimating(false);
  }, [scan, triggerTradeEstimate]);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-32 gap-3">
        <div className="relative w-16 h-16">
          <div className="absolute inset-0 rounded-full border-2 border-accent/20" />
          <div className="absolute inset-0 rounded-full border-2 border-transparent border-t-accent animate-spin" />
          <Satellite size={22} className="absolute inset-0 m-auto text-accent" />
        </div>
        <p className="text-sm text-muted font-medium">Analyzing property intelligence...</p>
        <p className="text-[10px] text-muted/60">Satellite imagery, roof measurements, structural data</p>
      </div>
    );
  }

  if (error || !scan) {
    return (
      <div className="space-y-4 max-w-lg mx-auto py-20">
        <Button variant="ghost" size="sm" onClick={() => router.back()}>
          <ArrowLeft size={16} /> Back to Recon
        </Button>
        <div className="rounded-xl bg-red-500/10 border border-red-500/20 p-8 text-center">
          <AlertTriangle size={28} className="mx-auto mb-3 text-red-400" />
          <p className="text-sm font-medium text-red-400">{error || 'Scan not found'}</p>
        </div>
      </div>
    );
  }

  const hasCoords = scan.latitude != null && scan.longitude != null;
  const satelliteUrl = hasCoords ? getSatelliteUrl(scan.latitude!, scan.longitude!) : null;
  const satelliteStreetsUrl = hasCoords ? getSatelliteStreetsUrl(scan.latitude!, scan.longitude!) : null;
  const streetMapUrl = hasCoords ? getStreetMapUrl(scan.latitude!, scan.longitude!) : null;
  const imageryOld = scan.imageryAgeMonths != null && scan.imageryAgeMonths > 18;

  const quickStats = [
    { label: 'Roof Area', value: roof ? `${roof.totalAreaSqft.toLocaleString()} sqft` : '—', icon: Home, color: '#8B5CF6' },
    { label: 'Squares', value: roof ? roof.totalAreaSquares.toFixed(1) : '—', icon: Layers, color: '#3B82F6' },
    { label: 'Pitch', value: roof?.pitchPrimary || (roof ? `${roof.pitchDegrees.toFixed(1)}°` : '—'), icon: TrendingUp, color: '#10B981' },
    { label: 'Facets', value: roof ? String(roof.facetCount) : '—', icon: Layers, color: '#06B6D4' },
    { label: 'Shape', value: roof?.predominantShape ? (SHAPE_LABELS[roof.predominantShape] || roof.predominantShape) : '—', icon: Building, color: '#F59E0B' },
    { label: 'Sources', value: String(scan.scanSources.length), icon: Database, color: '#EC4899' },
  ];

  return (
    <div className="space-y-4">
      {/* ── BACK NAV ───────────────────────────────── */}
      <div className="flex items-center gap-3">
        <button onClick={() => router.back()}
          className="p-1.5 rounded-lg text-muted hover:text-main hover:bg-surface-hover transition-colors">
          <ArrowLeft size={18} />
        </button>
        <div className="flex items-center gap-2 text-xs text-muted">
          <Link href="/dashboard/recon" className="hover:text-main transition-colors">Recon</Link>
          <ChevronRight size={10} />
          <span className="text-main font-medium truncate max-w-xs">{scan.address}</span>
        </div>
      </div>

      {/* ── HERO: SATELLITE IMAGERY + PROPERTY OVERVIEW ───── */}
      <div className="rounded-xl bg-card border border-main overflow-hidden">
        <div className="grid grid-cols-1 lg:grid-cols-[1fr,360px]">
          {/* Satellite / Street imagery */}
          <div className="relative aspect-[2/1] lg:aspect-auto lg:min-h-[320px] bg-black/90 overflow-hidden">
            {(() => {
              const imgSrc = imgView === 'satellite' ? satelliteStreetsUrl
                : imgView === 'streets' ? streetMapUrl
                : scan.streetViewUrl;
              const imgAlt = imgView === 'satellite' ? 'Satellite view'
                : imgView === 'streets' ? 'Street map'
                : 'Street view';
              return hasCoords && imgSrc ? (
                <img
                  src={imgSrc}
                  alt={`${imgAlt} of ${scan.address}`}
                  className="absolute inset-0 w-full h-full object-cover"
                  loading="eager"
                />
              ) : (
                <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 bg-surface/50">
                  <Map size={32} className="text-muted/30" />
                  <p className="text-xs text-muted">{imgView === 'streetview' ? 'Street View not available' : 'No coordinates available for imagery'}</p>
                </div>
              );
            })()}

            {/* View toggle */}
            {hasCoords && (
              <div className="absolute top-3 left-3 flex gap-1 bg-black/60 backdrop-blur-sm rounded-lg p-0.5">
                <button
                  onClick={() => setImgView('satellite')}
                  className={cn('px-2.5 py-1 rounded-md text-[10px] font-semibold transition-all',
                    imgView === 'satellite' ? 'bg-white/20 text-white' : 'text-white/50 hover:text-white/80'
                  )}>
                  <Satellite size={10} className="inline mr-1" />Satellite
                </button>
                <button
                  onClick={() => setImgView('streets')}
                  className={cn('px-2.5 py-1 rounded-md text-[10px] font-semibold transition-all',
                    imgView === 'streets' ? 'bg-white/20 text-white' : 'text-white/50 hover:text-white/80'
                  )}>
                  <Map size={10} className="inline mr-1" />Map
                </button>
                {scan.streetViewUrl && (
                  <button
                    onClick={() => setImgView('streetview')}
                    className={cn('px-2.5 py-1 rounded-md text-[10px] font-semibold transition-all',
                      imgView === 'streetview' ? 'bg-white/20 text-white' : 'text-white/50 hover:text-white/80'
                    )}>
                    <Home size={10} className="inline mr-1" />Street
                  </button>
                )}
              </div>
            )}

            {/* Confidence overlay */}
            <div className="absolute top-3 right-3">
              <div className="bg-black/60 backdrop-blur-sm rounded-lg px-3 py-2 flex items-center gap-2.5">
                <ConfidenceBadge score={scan.confidenceScore} grade={scan.confidenceGrade} />
              </div>
            </div>

            {/* Imagery age warning */}
            {imageryOld && (
              <div className="absolute bottom-3 left-3 flex items-center gap-1.5 bg-amber-500/80 backdrop-blur-sm px-2.5 py-1 rounded-md text-[10px] font-semibold text-black">
                <AlertTriangle size={10} /> Imagery {scan.imageryAgeMonths}+ months old
              </div>
            )}

            {/* Coordinates badge */}
            {hasCoords && (
              <div className="absolute bottom-3 right-3 bg-black/60 backdrop-blur-sm rounded-md px-2.5 py-1 text-[10px] font-mono text-white/70">
                {scan.latitude!.toFixed(5)}, {scan.longitude!.toFixed(5)}
              </div>
            )}
          </div>

          {/* Property info sidebar */}
          <div className="border-t lg:border-t-0 lg:border-l border-main p-5 flex flex-col">
            {/* Address */}
            <div className="mb-4">
              <h1 className="text-lg font-bold text-main tracking-tight leading-tight">{scan.address}</h1>
              <div className="flex items-center gap-2 mt-1">
                <span className="flex items-center gap-1 text-xs text-muted">
                  <MapPin size={10} />
                  {[scan.city, scan.state, scan.zip].filter(Boolean).join(', ')}
                </span>
              </div>
            </div>

            {/* Status + date */}
            <div className="flex items-center gap-2 mb-4">
              {(() => {
                const st = STATUS_CONFIG[scan.status] || STATUS_CONFIG.pending;
                return (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-semibold"
                    style={{ color: st.color, backgroundColor: st.bg }}>
                    <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: st.color }} />
                    {st.label}
                  </span>
                );
              })()}
              {scan.imageryDate && (
                <span className="text-[10px] text-muted flex items-center gap-1">
                  <Calendar size={9} /> {formatDate(scan.imageryDate)}
                </span>
              )}
            </div>

            {/* Source badges */}
            <div className="mb-4">
              <p className="text-[9px] font-semibold text-muted uppercase tracking-wider mb-1.5">Data Sources</p>
              <div className="flex flex-wrap gap-1">
                {scan.scanSources.map(src => (
                  <span key={src} className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-surface border border-main/50 text-[10px] font-medium text-muted">
                    <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: SOURCE_COLORS[src] || '#6B7280' }} />
                    {SOURCE_LABELS[src] || src.replace(/_/g, ' ')}
                  </span>
                ))}
                {scan.scanSources.length === 0 && (
                  <span className="text-[10px] text-muted/50">No sources</span>
                )}
              </div>
            </div>

            {/* Flood zone badge */}
            {scan.floodZone && (() => {
              const fc = FLOOD_RISK_CONFIG[scan.floodRisk || 'low'] || FLOOD_RISK_CONFIG.low;
              return (
                <div className="mb-4">
                  <p className="text-[9px] font-semibold text-muted uppercase tracking-wider mb-1.5">Flood Zone</p>
                  <div className="flex items-center gap-2">
                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-semibold"
                      style={{ color: fc.color, backgroundColor: fc.bg }}>
                      <Droplet size={10} />
                      Zone {scan.floodZone} — {fc.label}
                    </span>
                  </div>
                </div>
              );
            })()}

            {/* Divider */}
            <div className="border-t border-main my-2" />

            {/* Quick property stats */}
            <div className="grid grid-cols-2 gap-x-4 gap-y-2 mb-4 flex-1">
              {quickStats.map((stat, i) => (
                <div key={i} className="flex items-center gap-2">
                  <stat.icon size={11} style={{ color: stat.color }} className="shrink-0" />
                  <div className="min-w-0">
                    <p className="text-[9px] text-muted uppercase tracking-wider">{stat.label}</p>
                    <p className="text-xs font-semibold text-main truncate">{stat.value}</p>
                  </div>
                </div>
              ))}
            </div>

            {/* Actions */}
            <div className="flex gap-2 mt-auto pt-3 border-t border-main">
              <Button
                variant="primary"
                size="sm"
                onClick={async () => {
                  const supabase = createClient();
                  const { data: { user } } = await supabase.auth.getUser();
                  if (!user) return;
                  const companyId = user.app_metadata?.company_id;
                  if (!companyId) return;
                  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
                  const { data: est } = await supabase
                    .from('estimates')
                    .insert({
                      company_id: companyId, created_by: user.id,
                      title: `Estimate — ${scan.address}`,
                      estimate_number: `EST-${dateStr}-001`,
                      estimate_type: 'regular', status: 'draft',
                      property_scan_id: scan.id, job_id: scan.jobId,
                      property_address: scan.address,
                      property_city: scan.city || '', property_state: scan.state || '',
                      property_zip: scan.zip || '',
                      overhead_percent: 10, profit_percent: 10, tax_percent: 0,
                    })
                    .select('id')
                    .single();
                  if (est) router.push(`/dashboard/estimates/${est.id}`);
                }}
                className="flex-1 gap-1.5"
              >
                <FileText size={13} /> Create Estimate
              </Button>
              <Button
                variant="secondary"
                size="sm"
                onClick={() => router.push('/dashboard/sketch-engine')}
                className="gap-1.5"
              >
                <PenTool size={13} /> Sketch
              </Button>
            </div>
          </div>
        </div>
      </div>

      {/* ── QUICK STATS STRIP ──────────────────────────── */}
      <div className="grid gap-px bg-main/10 rounded-xl overflow-hidden" style={{ gridTemplateColumns: `repeat(${quickStats.length}, 1fr)` }}>
        {quickStats.map((stat, i) => (
          <div key={i} className="bg-card px-3 py-3 flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0" style={{ backgroundColor: `${stat.color}15` }}>
              <stat.icon size={14} style={{ color: stat.color }} />
            </div>
            <div className="min-w-0">
              <p className="text-[9px] font-medium text-muted uppercase tracking-wider">{stat.label}</p>
              <p className="text-sm font-bold text-main leading-tight truncate">{stat.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* ── EXTERNAL LINKS + STORAGE ───────────────────── */}
      {Object.keys(scan.externalLinks).length > 0 && (
        <div className="rounded-xl bg-card border border-main p-4">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <ExternalLink size={13} className="text-accent" />
              <h3 className="text-[13px] font-semibold text-main">Property Research Links</h3>
            </div>
            {scan.storageFolder && (
              <span className="flex items-center gap-1.5 text-[10px] text-muted">
                <FolderOpen size={10} />
                {scan.storageFolder}
              </span>
            )}
          </div>
          <div className="flex flex-wrap gap-2">
            {Object.entries(scan.externalLinks).map(([key, url]) => {
              const linkConfig = EXTERNAL_LINK_LABELS[key] || { label: key.replace(/_/g, ' '), color: '#6B7280' };
              return (
                <a
                  key={key}
                  href={url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-surface border border-main/50 text-[11px] font-medium text-muted hover:text-main hover:border-accent/30 transition-all group"
                >
                  <span className="w-2 h-2 rounded-full shrink-0" style={{ backgroundColor: linkConfig.color }} />
                  {linkConfig.label}
                  <ExternalLink size={9} className="text-muted/50 group-hover:text-accent transition-colors" />
                </a>
              );
            })}
          </div>
        </div>
      )}

      {/* ── TAB BAR ────────────────────────────────────── */}
      <div className="flex gap-0.5 bg-card rounded-xl border border-main p-1">
        {TABS.map(tab => {
          const isActive = activeTab === tab.key;
          return (
            <button key={tab.key} onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 rounded-lg text-[13px] font-medium transition-all flex-1 justify-center',
                isActive ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main hover:bg-surface/40'
              )}>
              <tab.icon size={14} style={{ color: isActive ? tab.color : undefined }} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* ── TAB CONTENT ────────────────────────────────── */}
      {activeTab === 'roof' && <RoofTab roof={roof} facets={facets} scan={scan} />}
      {activeTab === 'walls' && <WallsTab walls={walls} onEstimate={handleEstimate} estimating={estimating} />}
      {activeTab === 'trades' && (
        <TradesTab tradeBids={tradeBids} selectedTrade={selectedTrade}
          onSelectTrade={setSelectedTrade} onEstimate={handleEstimate} estimating={estimating} />
      )}
      {activeTab === 'solar' && <SolarTab facets={facets} tradeBids={tradeBids} />}
      {activeTab === 'storm' && <StormTab scanId={scan.id} scanState={scan.state} />}

      {/* ── DISCLAIMER ─────────────────────────────────── */}
      <div className="flex items-start gap-2 px-4 py-2.5 rounded-lg bg-card border border-main">
        <Info size={12} className="text-muted mt-0.5 shrink-0" />
        <p className="text-[10px] text-muted leading-relaxed">
          Measurements derived from satellite imagery and public records. Roof footprint area shown — multiply by number of stories for estimated living area.
          Always verify on site before material orders. Roof analysis powered by Google Solar API where available.
        </p>
      </div>
    </div>
  );
}

// ============================================================================
// ROOF TAB
// ============================================================================

function RoofTab({ roof, facets, scan }: {
  roof: RoofMeasurementData | null; facets: RoofFacetData[]; scan: PropertyScanData;
}) {
  if (!roof) {
    const hasSolarSource = scan.scanSources.includes('google_solar');
    return (
      <EmptyTab
        icon={Home}
        title="Roof Measurements Pending"
        description={
          hasSolarSource
            ? 'Google Solar API returned building data but detailed roof segment measurements were not available. This typically happens with newer construction or limited satellite coverage. Use the Sketch Engine to manually measure.'
            : 'No roof measurement data yet. A scan with Google Solar API coverage is required for automated roof measurements. You can also use the Sketch Engine to create measurements manually.'
        }
      />
    );
  }

  const totalEdge = roof.ridgeLengthFt + roof.hipLengthFt + roof.valleyLengthFt + roof.eaveLengthFt + roof.rakeLengthFt;
  const edges = [
    { label: 'Ridge', value: roof.ridgeLengthFt, color: '#8B5CF6' },
    { label: 'Hip', value: roof.hipLengthFt, color: '#F59E0B' },
    { label: 'Valley', value: roof.valleyLengthFt, color: '#EF4444' },
    { label: 'Eave', value: roof.eaveLengthFt, color: '#3B82F6' },
    { label: 'Rake', value: roof.rakeLengthFt, color: '#10B981' },
  ];

  return (
    <div className="space-y-4">
      {/* KPI strip */}
      <KpiStrip items={[
        { label: 'Total Area', value: roof.totalAreaSqft, unit: 'sq ft', icon: Layers, color: '#8B5CF6' },
        { label: 'Squares', value: roof.totalAreaSquares, unit: 'SQ', icon: Home, color: '#3B82F6' },
        { label: 'Primary Pitch', value: roof.pitchPrimary || `${roof.pitchDegrees.toFixed(1)}°`, icon: TrendingUp, color: '#10B981' },
        { label: 'Complexity', value: `${roof.complexityScore}/10`, icon: Activity, color: '#F59E0B' },
        { label: 'Facets', value: roof.facetCount, icon: Layers, color: '#06B6D4' },
        { label: 'Penetrations', value: roof.penetrationCount, icon: CircleDot, color: '#EC4899' },
      ]} />

      {/* Two-column: edges + structure */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Panel title="Edge Lengths" icon={Ruler} color="#3B82F6">
          <div className="space-y-2">
            {edges.map(edge => {
              const pct = totalEdge > 0 ? (edge.value / totalEdge) * 100 : 0;
              return (
                <div key={edge.label} className="flex items-center gap-3">
                  <span className="text-xs text-muted w-11 shrink-0">{edge.label}</span>
                  <div className="flex-1 h-2 rounded-full bg-main/10 overflow-hidden">
                    <div className="h-full rounded-full" style={{ width: `${pct}%`, backgroundColor: edge.color }} />
                  </div>
                  <span className="text-xs font-semibold text-main w-16 text-right font-mono">{edge.value.toLocaleString()} ft</span>
                </div>
              );
            })}
            <div className="pt-2 mt-1 border-t border-main flex justify-between">
              <span className="text-xs font-semibold text-muted">Total</span>
              <span className="text-xs font-bold text-main font-mono">{totalEdge.toLocaleString()} ft</span>
            </div>
          </div>
        </Panel>

        <Panel title="Structure" icon={Home} color="#8B5CF6">
          <div className="space-y-0">
            <DataRow label="Shape" value={roof.predominantShape ? (SHAPE_LABELS[roof.predominantShape] || roof.predominantShape) : 'Unknown'} />
            {roof.predominantMaterial && <DataRow label="Material" value={roof.predominantMaterial.replace(/_/g, ' ')} highlight />}
            <DataRow label="Facet Count" value={roof.facetCount} />
            <DataRow label="Penetrations" value={roof.penetrationCount} />
            <DataRow label="Pitch" value={`${roof.pitchDegrees.toFixed(1)}°`} />
            <DataRow label="Total Area" value={roof.totalAreaSqft} unit="sq ft" highlight />
          </div>
        </Panel>
      </div>

      {/* Facets table */}
      {facets.length > 0 && (
        <Panel title={`Roof Facets (${facets.length})`} icon={Layers} color="#8B5CF6" noPad>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  {['#', 'Area', 'Pitch', 'Direction', 'Sun Hours', 'Shade Factor'].map(h => (
                    <th key={h} className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {facets.map(f => {
                  const az = f.azimuthDegrees;
                  const dir = az >= 315 || az < 45 ? 'N' : az >= 45 && az < 135 ? 'E' : az >= 135 && az < 225 ? 'S' : 'W';
                  return (
                    <tr key={f.id} className="border-b border-main/30 hover:bg-surface/40 transition-colors">
                      <td className="px-4 py-2.5 font-semibold text-main">{f.facetNumber}</td>
                      <td className="px-4 py-2.5 text-main font-mono">{f.areaSqft.toLocaleString()} <span className="text-muted font-sans">sqft</span></td>
                      <td className="px-4 py-2.5 text-main font-mono">{f.pitchDegrees.toFixed(1)}°</td>
                      <td className="px-4 py-2.5">
                        <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded bg-surface text-[11px] font-medium text-main">
                          <Compass size={10} className="text-muted" /> {dir} ({f.azimuthDegrees.toFixed(0)}°)
                        </span>
                      </td>
                      <td className="px-4 py-2.5 text-main font-mono">{f.annualSunHours?.toLocaleString() ?? '—'} <span className="text-muted font-sans">hrs</span></td>
                      <td className="px-4 py-2.5">
                        {f.shadeFactor != null ? (
                          <span className={cn('text-[11px] font-semibold px-2 py-0.5 rounded',
                            f.shadeFactor >= 0.7 ? 'bg-emerald-500/10 text-emerald-500' :
                            f.shadeFactor >= 0.4 ? 'bg-amber-500/10 text-amber-500' : 'bg-red-500/10 text-red-400'
                          )}>
                            {Math.round(f.shadeFactor * 100)}% sun
                          </span>
                        ) : <span className="text-muted text-xs">—</span>}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Panel>
      )}
    </div>
  );
}

// ============================================================================
// WALLS TAB
// ============================================================================

function WallsTab({ walls, onEstimate, estimating }: {
  walls: WallMeasurementData | null; onEstimate: () => void; estimating: boolean;
}) {
  if (!walls) {
    return (
      <EmptyTab icon={Ruler} title="Wall Measurements Pending"
        description="Wall measurements are generated from building footprints and structural data. Run trade estimation to auto-calculate wall areas, siding, and per-face breakdowns."
        action="Generate Trade Data" onAction={onEstimate} loading={estimating} />
    );
  }

  return (
    <div className="space-y-4">
      <KpiStrip items={[
        { label: 'Gross Wall Area', value: walls.totalWallAreaSqft, unit: 'sq ft', icon: Ruler, color: '#3B82F6' },
        { label: 'Net Siding Area', value: walls.totalSidingAreaSqft, unit: 'sq ft', icon: Layers, color: '#06B6D4' },
        { label: 'Stories', value: walls.stories, icon: Home, color: '#8B5CF6' },
        { label: 'Avg Height', value: walls.avgWallHeightFt, unit: 'ft', icon: TrendingUp, color: '#10B981' },
        { label: 'Confidence', value: `${walls.confidence}%`, icon: Shield, color: walls.confidence >= 70 ? '#10B981' : '#F59E0B' },
      ]} />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Openings */}
        <Panel title="Openings" icon={Ruler} color="#3B82F6">
          <div className="space-y-0">
            <DataRow label="Window Area (est)" value={walls.windowAreaEstSqft} unit="sq ft" />
            <DataRow label="Door Area (est)" value={walls.doorAreaEstSqft} unit="sq ft" />
            <div className="pt-2 mt-1 border-t border-main">
              <DataRow label="Total Deductions" value={walls.windowAreaEstSqft + walls.doorAreaEstSqft} unit="sq ft" highlight />
            </div>
          </div>
        </Panel>

        {/* Trim */}
        <Panel title="Trim & Accessories" icon={Activity} color="#F59E0B">
          <div className="space-y-0">
            <DataRow label="Trim" value={walls.trimLinearFt} unit="LF" />
            <DataRow label="Fascia" value={walls.fasciaLinearFt} unit="LF" />
            <DataRow label="Soffit" value={walls.soffitSqft} unit="sq ft" />
          </div>
        </Panel>

        {/* Source */}
        <Panel title="Data Quality" icon={Shield} color="#10B981">
          <div className="space-y-0">
            <DataRow label="Source" value={walls.dataSource} />
            <DataRow label="Method" value={walls.isEstimated ? 'Derived from footprint' : 'Direct measurement'} />
            <DataRow label="Confidence" value={`${walls.confidence}%`} highlight={walls.confidence >= 70} />
          </div>
        </Panel>
      </div>

      {/* Per-face */}
      {walls.perFace.length > 0 && (
        <Panel title="Per-Face Breakdown" icon={Compass} color="#8B5CF6" noPad>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  {['Face', 'Width', 'Height', 'Gross Area', 'Windows', 'Doors', 'Net Area'].map(h => (
                    <th key={h} className={cn('px-4 py-2.5 text-[10px] font-semibold text-muted uppercase tracking-wider',
                      h === 'Face' ? 'text-left' : 'text-right')}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {walls.perFace.map((face, i) => (
                  <tr key={i} className="border-b border-main/30 hover:bg-surface/40 transition-colors">
                    <td className="px-4 py-2.5 capitalize font-semibold text-main">
                      <span className="inline-flex items-center gap-1.5">
                        <Compass size={11} className="text-muted" /> {face.direction}
                      </span>
                    </td>
                    <td className="px-4 py-2.5 text-main text-right font-mono">{face.width_ft} ft</td>
                    <td className="px-4 py-2.5 text-main text-right font-mono">{face.height_ft} ft</td>
                    <td className="px-4 py-2.5 text-main text-right font-mono">{face.area_sqft} sq ft</td>
                    <td className="px-4 py-2.5 text-main text-right">{face.window_count_est}</td>
                    <td className="px-4 py-2.5 text-main text-right">{face.door_count_est}</td>
                    <td className="px-4 py-2.5 text-right font-bold text-accent font-mono">{face.net_area_sqft} sq ft</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Panel>
      )}
    </div>
  );
}

// ============================================================================
// TRADES TAB
// ============================================================================

function TradesTab({ tradeBids, selectedTrade, onSelectTrade, onEstimate, estimating }: {
  tradeBids: TradeBidData[]; selectedTrade: TradeType | null;
  onSelectTrade: (t: TradeType | null) => void; onEstimate: () => void; estimating: boolean;
}) {
  const activeTrade = selectedTrade ? tradeBids.find(t => t.trade === selectedTrade) : null;

  if (tradeBids.length === 0) {
    return (
      <EmptyTab icon={BarChart3} title="Trade Data Not Generated"
        description="Generate trade-specific measurements, material lists, waste factors, and crew estimates for all applicable trades using your property scan data."
        action="Generate Trade Data" onAction={onEstimate} loading={estimating} />
    );
  }

  return (
    <div className="space-y-4">
      {/* Trade pills */}
      <div className="flex items-center gap-1.5 flex-wrap">
        {tradeBids.map(t => {
          const isSelected = selectedTrade === t.trade;
          const color = TRADE_COLORS[t.trade] || '#6B7280';
          return (
            <button key={t.trade} onClick={() => onSelectTrade(isSelected ? null : t.trade)}
              className={cn(
                'inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all border',
                isSelected ? 'shadow-sm text-main' : 'border-main/50 text-muted hover:text-main hover:border-main'
              )}
              style={isSelected ? { borderColor: color, backgroundColor: `${color}10` } : undefined}>
              <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: color }} />
              {TRADE_LABELS[t.trade] || t.trade}
              <span className="text-[10px] text-muted">{t.materialList.length}</span>
            </button>
          );
        })}
        <Button variant="ghost" size="sm" onClick={onEstimate} disabled={estimating} className="ml-auto">
          <RefreshCw size={12} className={estimating ? 'animate-spin' : ''} /> Refresh
        </Button>
      </div>

      {/* Grid overview (no trade selected) */}
      {!activeTrade && (
        <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3">
          {tradeBids.map(t => {
            const color = TRADE_COLORS[t.trade] || '#6B7280';
            const Icon = TRADE_ICONS[t.trade] || BarChart3;
            return (
              <button key={t.trade} onClick={() => onSelectTrade(t.trade)}
                className="relative overflow-hidden rounded-xl bg-card border border-main p-3.5 text-left hover:border-accent/30 transition-all group">
                <div className="absolute top-0 left-0 w-1 h-full" style={{ backgroundColor: color }} />
                <div className="flex items-center gap-2.5 pl-2 mb-2.5">
                  <div className="w-7 h-7 rounded-lg flex items-center justify-center opacity-30 group-hover:opacity-50 transition-opacity"
                    style={{ backgroundColor: color }}>
                    <Icon size={14} className="text-white" />
                  </div>
                  <div className="min-w-0">
                    <h4 className="text-xs font-semibold text-main truncate">{TRADE_LABELS[t.trade]}</h4>
                    <p className="text-[10px] text-muted">{t.materialList.length} items</p>
                  </div>
                </div>
                <div className="pl-2 grid grid-cols-2 gap-y-1 text-[11px]">
                  <span className="text-muted">Waste</span>
                  <span className="text-main text-right font-medium">{t.wasteFactorPct}%</span>
                  <span className="text-muted">Complexity</span>
                  <span className="text-main text-right font-medium">{t.complexityScore}/10</span>
                  <span className="text-muted">Crew</span>
                  <span className="text-main text-right font-medium">{t.recommendedCrewSize}</span>
                  {t.estimatedLaborHours != null && <>
                    <span className="text-muted">Labor</span>
                    <span className="text-main text-right font-medium">{t.estimatedLaborHours}h</span>
                  </>}
                </div>
              </button>
            );
          })}
        </div>
      )}

      {/* Trade detail */}
      {activeTrade && <TradeDetail trade={activeTrade} />}
    </div>
  );
}

function TradeDetail({ trade }: { trade: TradeBidData }) {
  const color = TRADE_COLORS[trade.trade] || '#6B7280';

  return (
    <div className="space-y-4">
      <KpiStrip items={[
        { label: 'Materials', value: trade.materialList.length, icon: Package, color },
        { label: 'Waste Factor', value: `${trade.wasteFactorPct}%`, icon: Activity, color: '#F59E0B' },
        { label: 'Crew Size', value: trade.recommendedCrewSize, unit: 'workers', icon: Users, color: '#3B82F6' },
        { label: 'Est. Labor', value: trade.estimatedLaborHours ?? '—', unit: trade.estimatedLaborHours ? 'hrs' : '', icon: Clock, color: '#10B981' },
        { label: 'Complexity', value: `${trade.complexityScore}/10`, icon: Activity, color: '#EC4899' },
      ]} />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Measurements */}
        <Panel title={`${TRADE_LABELS[trade.trade]} Measurements`} icon={Ruler} color={color}>
          <div className="space-y-0">
            {Object.entries(trade.measurements).map(([key, val]) => (
              <DataRow key={key}
                label={key.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                value={typeof val === 'number' ? val : String(val ?? '—')} />
            ))}
            {Object.keys(trade.measurements).length === 0 && (
              <p className="text-xs text-muted py-4 text-center">No detailed measurements</p>
            )}
          </div>
        </Panel>

        {/* Job Intelligence */}
        <Panel title="Job Intelligence" icon={Activity} color="#F59E0B">
          <div className="space-y-0">
            <DataRow label="Complexity" value={`${trade.complexityScore}/10`} highlight={trade.complexityScore >= 7} />
            <DataRow label="Waste Factor" value={`${trade.wasteFactorPct}%`} />
            <DataRow label="Crew" value={`${trade.recommendedCrewSize} workers`} />
            {trade.estimatedLaborHours != null && <DataRow label="Labor" value={`${trade.estimatedLaborHours} hours`} highlight />}
            {trade.dataSources.length > 0 && (
              <div className="pt-2 mt-2 border-t border-main">
                <p className="text-[10px] text-muted uppercase tracking-wider mb-1.5">Data Sources</p>
                <div className="flex flex-wrap gap-1">
                  {trade.dataSources.map(s => (
                    <span key={s} className="px-2 py-0.5 rounded bg-surface border border-main/50 text-[10px] text-muted">{s.replace(/_/g, ' ')}</span>
                  ))}
                </div>
              </div>
            )}
          </div>
        </Panel>
      </div>

      {/* Material List */}
      {trade.materialList.length > 0 && (
        <Panel title={`Material List (${trade.materialList.length})`} icon={Package} color={color} noPad>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">Item</th>
                  <th className="px-4 py-2.5 text-right text-[10px] font-semibold text-muted uppercase tracking-wider">Base Qty</th>
                  <th className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">Unit</th>
                  <th className="px-4 py-2.5 text-right text-[10px] font-semibold text-muted uppercase tracking-wider">Waste</th>
                  <th className="px-4 py-2.5 text-right text-[10px] font-semibold text-muted uppercase tracking-wider">Total Qty</th>
                </tr>
              </thead>
              <tbody>
                {trade.materialList.map((mat, i) => (
                  <tr key={i} className="border-b border-main/30 hover:bg-surface/40 transition-colors">
                    <td className="px-4 py-2.5 font-medium text-main">{mat.item}</td>
                    <td className="px-4 py-2.5 text-main text-right font-mono">{mat.quantity.toLocaleString()}</td>
                    <td className="px-4 py-2.5 text-muted">{mat.unit}</td>
                    <td className="px-4 py-2.5 text-right">
                      <span className="px-1.5 py-0.5 rounded text-[10px] font-semibold bg-amber-500/10 text-amber-500">+{mat.waste_pct}%</span>
                    </td>
                    <td className="px-4 py-2.5 text-right font-bold text-main font-mono">{mat.total_with_waste.toLocaleString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Panel>
      )}
    </div>
  );
}

// ============================================================================
// SOLAR TAB
// ============================================================================

function SolarTab({ facets, tradeBids }: { facets: RoofFacetData[]; tradeBids: TradeBidData[] }) {
  const solarBid = tradeBids.find(t => t.trade === 'solar');

  if (!solarBid && facets.length === 0) {
    return (
      <EmptyTab icon={Sun} title="Solar Analysis Pending"
        description="Solar potential data comes from roof facet analysis and trade estimation. Run trade estimation to calculate panel capacity, annual production, and sun exposure per facet." />
    );
  }

  const measurements = solarBid?.measurements || {};
  const maxSunHours = Math.max(...facets.map(f => f.annualSunHours || 0), 1);

  return (
    <div className="space-y-4">
      {solarBid && (
        <KpiStrip items={[
          { label: 'Max Panels', value: Number(measurements.max_panel_count) || 0, icon: Sun, color: '#F59E0B' },
          { label: 'System Size', value: Number(measurements.system_size_kw) || 0, unit: 'kW', icon: Zap, color: '#10B981' },
          { label: 'Annual Production', value: Number(measurements.estimated_annual_kwh) || 0, unit: 'kWh', icon: Activity, color: '#3B82F6' },
          { label: 'Usable Roof', value: Number(measurements.usable_roof_area_sqft) || 0, unit: 'sq ft', icon: Home, color: '#8B5CF6' },
        ]} />
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Sun Exposure */}
        {facets.length > 0 && (
          <Panel title="Sun Exposure by Facet" icon={Sun} color="#F59E0B">
            <div className="space-y-2.5">
              {facets.map(f => {
                const ratio = (f.annualSunHours || 0) / maxSunHours;
                const az = f.azimuthDegrees;
                const direction = az >= 315 || az < 45 ? 'N' : az >= 45 && az < 135 ? 'E' : az >= 135 && az < 225 ? 'S' : 'W';
                const isUsable = az >= 90 && az <= 315 && ratio > 0.5;
                return (
                  <div key={f.id}>
                    <div className="flex items-center justify-between text-xs mb-1">
                      <span className="text-muted flex items-center gap-1.5">
                        Facet {f.facetNumber}
                        <span className="px-1.5 py-0.5 rounded bg-surface text-[10px] font-medium">{direction}</span>
                        <span className="text-muted">{f.areaSqft.toLocaleString()} sqft</span>
                      </span>
                      <span className={cn('font-semibold font-mono', isUsable ? 'text-amber-500' : 'text-muted')}>
                        {f.annualSunHours?.toLocaleString() ?? '—'} hrs
                      </span>
                    </div>
                    <div className="h-2 rounded-full bg-main/10 overflow-hidden">
                      <div className={cn('h-full rounded-full', isUsable ? 'bg-gradient-to-r from-amber-500 to-yellow-400' : 'bg-gray-500')}
                        style={{ width: `${Math.round(ratio * 100)}%` }} />
                    </div>
                  </div>
                );
              })}
            </div>
          </Panel>
        )}

        {/* Solar summary */}
        {solarBid && (
          <Panel title="Solar Summary" icon={Zap} color="#10B981">
            <div className="space-y-0">
              {Object.entries(measurements).map(([key, val]) => (
                <DataRow key={key}
                  label={key.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                  value={typeof val === 'number' ? val : String(val ?? '—')} />
              ))}
            </div>
          </Panel>
        )}
      </div>

      {/* Solar Material List */}
      {solarBid && solarBid.materialList.length > 0 && (
        <Panel title="Solar Material List" icon={Package} color="#F59E0B" noPad>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">Item</th>
                  <th className="px-4 py-2.5 text-right text-[10px] font-semibold text-muted uppercase tracking-wider">Qty</th>
                  <th className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">Unit</th>
                </tr>
              </thead>
              <tbody>
                {solarBid.materialList.map((mat, i) => (
                  <tr key={i} className="border-b border-main/30 hover:bg-surface/40 transition-colors">
                    <td className="px-4 py-2.5 font-medium text-main">{mat.item}</td>
                    <td className="px-4 py-2.5 text-main text-right font-bold font-mono">{mat.total_with_waste.toLocaleString()}</td>
                    <td className="px-4 py-2.5 text-muted">{mat.unit}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Panel>
      )}
    </div>
  );
}

// ============================================================================
// STORM TAB
// ============================================================================

function StormTab({ scanId, scanState }: { scanId: string; scanState: string | null }) {
  const { result, loading, error, assessProperty, reset } = useStormAssess();
  const [stormDate, setStormDate] = useState('');
  const [state, setState] = useState(scanState || '');
  const [county, setCounty] = useState('');

  const handleAssess = () => {
    if (!stormDate || !state) return;
    assessProperty({ property_scan_id: scanId, storm_date: stormDate, state, county: county || undefined });
  };

  return (
    <div className="space-y-4">
      {/* Input form */}
      <Panel title="Storm Damage Assessment" icon={CloudLightning} color="#EF4444">
        <div className="space-y-3">
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="text-[10px] font-medium text-muted uppercase tracking-wider block mb-1">Storm Date</label>
              <input type="date" value={stormDate} onChange={(e) => setStormDate(e.target.value)}
                className="w-full bg-surface border border-main rounded-lg px-3 py-2 text-sm text-main focus:border-accent focus:outline-none transition-colors" />
            </div>
            <div>
              <label className="text-[10px] font-medium text-muted uppercase tracking-wider block mb-1">State</label>
              <input type="text" value={state} onChange={(e) => setState(e.target.value.toUpperCase())}
                placeholder="CT" maxLength={2}
                className="w-full bg-surface border border-main rounded-lg px-3 py-2 text-sm text-main focus:border-accent focus:outline-none uppercase transition-colors" />
            </div>
            <div>
              <label className="text-[10px] font-medium text-muted uppercase tracking-wider block mb-1">County (optional)</label>
              <input type="text" value={county} onChange={(e) => setCounty(e.target.value)} placeholder="Hartford"
                className="w-full bg-surface border border-main rounded-lg px-3 py-2 text-sm text-main focus:border-accent focus:outline-none transition-colors" />
            </div>
          </div>
          <div className="flex items-center gap-3">
            <Button variant="primary" size="sm" onClick={handleAssess} disabled={loading || !stormDate || !state}>
              {loading ? <Loader2 size={14} className="animate-spin" /> : <ShieldAlert size={14} />}
              {loading ? 'Analyzing...' : 'Run Assessment'}
            </Button>
            {result && <Button variant="ghost" size="sm" onClick={reset}>Clear</Button>}
          </div>
          {error && (
            <div className="flex items-center gap-2 text-sm text-red-400 bg-red-500/10 px-3 py-2 rounded-lg">
              <AlertTriangle size={14} /> {error}
            </div>
          )}
        </div>
      </Panel>

      {/* Results */}
      {result && (
        <>
          <KpiStrip items={[
            { label: 'Damage Probability', value: `${result.probability || 0}%`, icon: ShieldAlert,
              color: (result.probability || 0) >= 50 ? '#EF4444' : (result.probability || 0) >= 25 ? '#F59E0B' : '#3B82F6' },
            { label: 'Storm Events', value: result.storm_events_found, icon: CloudLightning, color: '#8B5CF6' },
            { label: 'Max Hail', value: result.maxHailInches ? `${result.maxHailInches}"` : 'None', icon: CircleDot, color: '#06B6D4' },
            { label: 'Max Wind', value: result.maxWindKnots ? `${result.maxWindKnots} kts` : 'None', icon: Wind, color: '#F59E0B' },
          ]} />

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {/* Probability gauge */}
            <Panel title="Damage Probability" icon={Activity} color="#EF4444">
              <div className="text-center py-4">
                <div className="relative inline-flex items-center justify-center w-32 h-32">
                  <svg className="w-32 h-32 -rotate-90" viewBox="0 0 144 144">
                    <circle cx="72" cy="72" r="56" fill="none" strokeWidth="8" className="stroke-current text-main/10" />
                    <circle cx="72" cy="72" r="56" fill="none" strokeWidth="8" strokeLinecap="round"
                      strokeDasharray={`${((result.probability || 0) / 100) * 2 * Math.PI * 56} ${2 * Math.PI * 56}`}
                      className={cn('transition-all duration-700',
                        (result.probability || 0) >= 50 ? 'text-red-500' : (result.probability || 0) >= 25 ? 'text-orange-500' : 'text-blue-500'
                      )}
                      stroke="currentColor" />
                  </svg>
                  <span className="absolute text-3xl font-bold text-main">{result.probability || 0}%</span>
                </div>
                <p className="text-xs text-muted mt-2">Estimated storm damage probability</p>
              </div>
            </Panel>

            {/* Storm Details */}
            <Panel title="Storm Intelligence" icon={Database} color="#3B82F6">
              <div className="space-y-0">
                <DataRow label="Storm Events Found" value={result.storm_events_found} highlight={result.storm_events_found > 0} />
                <DataRow label="Max Hail Size" value={result.maxHailInches ? `${result.maxHailInches}"` : 'None detected'} />
                <DataRow label="Max Wind Speed" value={result.maxWindKnots ? `${result.maxWindKnots} kts` : 'None detected'} />
                <DataRow label="Nearest Event" value={
                  result.nearestEventMiles != null && result.nearestEventMiles >= 0
                    ? `${result.nearestEventMiles} mi` : 'N/A'
                } />
                <div className="pt-3 mt-3 border-t border-main space-y-1.5">
                  <div className="flex items-center gap-2 text-[11px] text-muted">
                    <CircleDot size={10} /> Hail &ge; 1&quot; causes shingle damage
                  </div>
                  <div className="flex items-center gap-2 text-[11px] text-muted">
                    <Wind size={10} /> Wind &ge; 65 kts causes structural damage
                  </div>
                </div>
              </div>
            </Panel>
          </div>
        </>
      )}

      {/* Disclaimer */}
      <div className="flex items-start gap-2 px-4 py-2.5 rounded-lg bg-card border border-main">
        <Info size={12} className="text-muted mt-0.5 shrink-0" />
        <p className="text-[10px] text-muted leading-relaxed">
          Storm data from NOAA Storm Events Database and SPC Storm Reports (public domain).
          Damage probability estimated based on proximity, hail size, wind speed, and roof age.
          For informational purposes only — does not constitute an insurance claim.
        </p>
      </div>
    </div>
  );
}
