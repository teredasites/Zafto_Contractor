'use client';

import { useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase';
import { useRouter, useParams } from 'next/navigation';
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
  type LucideIcon,
} from 'lucide-react';
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
};

// ============================================================================
// SHARED COMPONENTS
// ============================================================================

function StatCard({ label, value, unit, icon: Icon, color, subtitle }: {
  label: string; value: string | number; unit?: string;
  icon?: LucideIcon; color?: string; subtitle?: string;
}) {
  return (
    <div className="relative overflow-hidden rounded-xl bg-card border border-main p-4 group hover:border-accent/30 transition-colors">
      <div className="absolute top-0 left-0 w-1 h-full" style={{ backgroundColor: color || 'var(--accent)' }} />
      <div className="flex items-start justify-between">
        <div className="pl-2">
          <p className="text-[11px] font-medium text-muted uppercase tracking-wider">{label}</p>
          <p className="text-2xl font-bold text-main mt-1">
            {typeof value === 'number' ? value.toLocaleString() : value}
            {unit && <span className="text-sm font-normal text-muted ml-1">{unit}</span>}
          </p>
          {subtitle && <p className="text-[11px] text-muted mt-0.5">{subtitle}</p>}
        </div>
        {Icon && (
          <div className="w-10 h-10 rounded-lg flex items-center justify-center opacity-20 group-hover:opacity-40 transition-opacity"
            style={{ backgroundColor: color || 'var(--accent)' }}>
            <Icon size={20} className="text-white" />
          </div>
        )}
      </div>
    </div>
  );
}

function MetricRow({ label, value, unit, highlight }: {
  label: string; value: string | number; unit?: string; highlight?: boolean;
}) {
  return (
    <div className={cn('flex justify-between items-center py-2 px-3 rounded-lg', highlight && 'bg-accent/5')}>
      <span className="text-sm text-muted">{label}</span>
      <span className={cn('text-sm font-medium', highlight ? 'text-accent' : 'text-main')}>
        {typeof value === 'number' ? value.toLocaleString() : value}
        {unit && <span className="text-muted ml-1 font-normal">{unit}</span>}
      </span>
    </div>
  );
}

function SectionCard({ title, icon: Icon, color, children, className }: {
  title: string; icon?: LucideIcon; color?: string;
  children: React.ReactNode; className?: string;
}) {
  return (
    <div className={cn('rounded-xl bg-card border border-main overflow-hidden', className)}>
      <div className="px-4 py-3 border-b border-main flex items-center gap-2.5">
        {Icon && <Icon size={15} style={{ color: color || 'var(--accent)' }} />}
        <h3 className="text-sm font-semibold text-main">{title}</h3>
      </div>
      <div className="p-4">{children}</div>
    </div>
  );
}

function ConfidenceGauge({ score, grade }: { score: number; grade: string }) {
  const radius = 20;
  const circ = 2 * Math.PI * radius;
  const offset = circ - (score / 100) * circ;
  const color = grade === 'high' ? '#10B981' : grade === 'moderate' ? '#F59E0B' : '#EF4444';

  return (
    <div className="relative flex items-center justify-center w-14 h-14">
      <svg className="w-14 h-14 -rotate-90" viewBox="0 0 48 48">
        <circle cx="24" cy="24" r={radius} fill="none" strokeWidth="4" className="stroke-current text-main/20" />
        <circle cx="24" cy="24" r={radius} fill="none" strokeWidth="4" strokeLinecap="round"
          strokeDasharray={circ} strokeDashoffset={offset}
          style={{ stroke: color, transition: 'stroke-dashoffset 0.5s ease' }} />
      </svg>
      <span className="absolute text-xs font-bold text-main">{score}%</span>
    </div>
  );
}

function EmptyState({ icon: Icon, title, description, action, onAction, loading }: {
  icon: LucideIcon; title: string; description: string;
  action?: string; onAction?: () => void; loading?: boolean;
}) {
  return (
    <div className="rounded-xl bg-card border border-dashed border-main/60 p-12 text-center">
      <div className="w-16 h-16 mx-auto rounded-2xl bg-accent/10 flex items-center justify-center mb-4">
        <Icon size={28} className="text-accent" />
      </div>
      <h3 className="text-base font-semibold text-main mb-2">{title}</h3>
      <p className="text-sm text-muted max-w-md mx-auto mb-6">{description}</p>
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

export default function ReconDetailPage() {
  const router = useRouter();
  const params = useParams();
  const scanId = params.id as string;
  const [activeTab, setActiveTab] = useState<TabType>('roof');
  const [selectedTrade, setSelectedTrade] = useState<TradeType | null>(null);
  const [estimating, setEstimating] = useState(false);

  const { scan, roof, facets, walls, tradeBids, loading, error, triggerTradeEstimate } = usePropertyScan(scanId, 'scan');

  const handleEstimate = useCallback(async () => {
    if (!scan) return;
    setEstimating(true);
    await triggerTradeEstimate(scan.id);
    setEstimating(false);
  }, [scan, triggerTradeEstimate]);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-32 gap-4">
        <div className="relative w-16 h-16">
          <div className="absolute inset-0 rounded-full border-2 border-accent/20" />
          <div className="absolute inset-0 rounded-full border-2 border-transparent border-t-accent animate-spin" />
          <Satellite size={24} className="absolute inset-0 m-auto text-accent" />
        </div>
        <p className="text-sm text-muted">Loading property intelligence...</p>
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
          <AlertTriangle size={32} className="mx-auto mb-3 text-red-400" />
          <p className="text-sm font-medium text-red-400">{error || 'Scan not found'}</p>
        </div>
      </div>
    );
  }

  const confColor = scan.confidenceGrade === 'high' ? '#10B981' : scan.confidenceGrade === 'moderate' ? '#F59E0B' : '#EF4444';
  const confLabel = scan.confidenceGrade === 'high' ? 'High Confidence' : scan.confidenceGrade === 'moderate' ? 'Moderate' : 'Low';
  const imageryOld = scan.imageryAgeMonths != null && scan.imageryAgeMonths > 18;
  const activeTabDef = TABS.find(t => t.key === activeTab)!;

  return (
    <div className="space-y-6 max-w-[1400px]">
      {/* ── HERO HEADER ────────────────────────────────── */}
      <div className="rounded-2xl bg-card border border-main overflow-hidden">
        <div className="px-6 py-5">
          <div className="flex items-start justify-between">
            <div className="flex items-start gap-4">
              <button onClick={() => router.back()}
                className="mt-1 p-2 rounded-lg text-muted hover:text-main hover:bg-surface-hover transition-colors">
                <ArrowLeft size={18} />
              </button>
              <div>
                <div className="flex items-center gap-3 mb-1">
                  <h1 className="text-2xl font-bold text-main tracking-tight">{scan.address}</h1>
                </div>
                <div className="flex items-center gap-4 text-sm text-muted">
                  <span className="flex items-center gap-1.5">
                    <MapPin size={13} />
                    {[scan.city, scan.state, scan.zip].filter(Boolean).join(', ')}
                  </span>
                  {scan.imageryDate && (
                    <span className="flex items-center gap-1.5">
                      <Calendar size={13} />
                      Imagery: {formatDate(scan.imageryDate)}
                    </span>
                  )}
                  <span className="flex items-center gap-1.5">
                    <Database size={13} />
                    {scan.scanSources.length} data source{scan.scanSources.length !== 1 ? 's' : ''}
                  </span>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-4">
              {/* Confidence gauge */}
              <div className="flex items-center gap-3">
                <ConfidenceGauge score={scan.confidenceScore} grade={scan.confidenceGrade} />
                <div>
                  <p className="text-xs font-semibold" style={{ color: confColor }}>{confLabel}</p>
                  <p className="text-[10px] text-muted">Data Quality</p>
                </div>
              </div>

              <div className="h-10 w-px bg-main" />

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
                className="gap-2"
              >
                <FileText size={14} />
                Create Estimate
              </Button>
            </div>
          </div>
        </div>

        {/* Source badges strip */}
        <div className="px-6 py-2.5 bg-secondary/50 border-t border-main flex items-center gap-3">
          <span className="text-[10px] font-semibold text-muted uppercase tracking-wider">Sources</span>
          <div className="flex gap-2">
            {scan.scanSources.map(src => (
              <span key={src} className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-surface border border-main text-[11px] font-medium text-main">
                <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: SOURCE_COLORS[src] || '#6B7280' }} />
                {src.replace(/_/g, ' ')}
              </span>
            ))}
          </div>
          {imageryOld && (
            <div className="ml-auto flex items-center gap-1.5 text-amber-500 text-[11px] font-medium">
              <AlertTriangle size={12} />
              Imagery {scan.imageryAgeMonths}mo old — verify on site
            </div>
          )}
        </div>
      </div>

      {/* ── TAB BAR ──────────────────────────────────── */}
      <div className="flex gap-1 bg-card rounded-xl border border-main p-1.5">
        {TABS.map(tab => {
          const isActive = activeTab === tab.key;
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-medium transition-all flex-1 justify-center',
                isActive
                  ? 'bg-surface shadow-sm text-main'
                  : 'text-muted hover:text-main hover:bg-surface/50'
              )}
            >
              <tab.icon size={15} style={{ color: isActive ? tab.color : undefined }} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* ── TAB CONTENT ──────────────────────────────── */}
      {activeTab === 'roof' && <RoofTab roof={roof} facets={facets} scan={scan} />}
      {activeTab === 'walls' && <WallsTab walls={walls} onEstimate={handleEstimate} estimating={estimating} />}
      {activeTab === 'trades' && (
        <TradesTab tradeBids={tradeBids} selectedTrade={selectedTrade}
          onSelectTrade={setSelectedTrade} onEstimate={handleEstimate} estimating={estimating} />
      )}
      {activeTab === 'solar' && <SolarTab facets={facets} tradeBids={tradeBids} />}
      {activeTab === 'storm' && <StormTab scanId={scan.id} scanState={scan.state} />}

      {/* ── LEGAL DISCLAIMER ─────────────────────────── */}
      <div className="flex items-start gap-2.5 px-4 py-3 rounded-xl bg-card border border-main">
        <Info size={14} className="text-muted mt-0.5 shrink-0" />
        <p className="text-[11px] text-muted leading-relaxed">
          Property measurements are derived from satellite imagery, public records, and analysis.
          They are estimates intended as starting points for bidding. Always verify critical
          measurements on site before placing material orders. Roof analysis powered by Google Solar API.
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
      <EmptyState
        icon={Home}
        title="Roof Measurements Pending"
        description={
          hasSolarSource
            ? 'Google Solar API returned building data for this address but detailed roof segment measurements were not available. This typically happens with newer construction, recent renovations, or areas with limited satellite coverage. Use the Sketch Engine to manually measure the roof from uploaded plans.'
            : 'No roof measurement data yet. A scan with Google Solar API coverage is required to generate automated roof measurements. You can also use the Sketch Engine to create measurements manually.'
        }
      />
    );
  }

  return (
    <div className="space-y-4">
      {/* Hero stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <StatCard label="Total Area" value={roof.totalAreaSqft} unit="sq ft" icon={Layers} color="#8B5CF6" />
        <StatCard label="Squares" value={roof.totalAreaSquares} unit="SQ" icon={Home} color="#3B82F6"
          subtitle={`${roof.facetCount} facet${roof.facetCount !== 1 ? 's' : ''}`} />
        <StatCard label="Primary Pitch" value={roof.pitchPrimary || `${roof.pitchDegrees.toFixed(1)}°`}
          icon={TrendingUp} color="#10B981"
          subtitle={roof.predominantShape ? SHAPE_LABELS[roof.predominantShape] || roof.predominantShape : undefined} />
        <StatCard label="Complexity" value={`${roof.complexityScore}/10`} icon={Activity} color="#F59E0B"
          subtitle={`${roof.penetrationCount} penetration${roof.penetrationCount !== 1 ? 's' : ''}`} />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Edge Lengths */}
        <SectionCard title="Edge Lengths" icon={Ruler} color="#3B82F6">
          <div className="space-y-1">
            {[
              { label: 'Ridge', value: roof.ridgeLengthFt, color: '#8B5CF6' },
              { label: 'Hip', value: roof.hipLengthFt, color: '#F59E0B' },
              { label: 'Valley', value: roof.valleyLengthFt, color: '#EF4444' },
              { label: 'Eave', value: roof.eaveLengthFt, color: '#3B82F6' },
              { label: 'Rake', value: roof.rakeLengthFt, color: '#10B981' },
            ].map(edge => {
              const total = roof.ridgeLengthFt + roof.hipLengthFt + roof.valleyLengthFt + roof.eaveLengthFt + roof.rakeLengthFt;
              const pct = total > 0 ? (edge.value / total) * 100 : 0;
              return (
                <div key={edge.label} className="flex items-center gap-3 py-1.5">
                  <span className="text-xs text-muted w-12">{edge.label}</span>
                  <div className="flex-1 h-2 rounded-full bg-main/10 overflow-hidden">
                    <div className="h-full rounded-full transition-all" style={{ width: `${pct}%`, backgroundColor: edge.color }} />
                  </div>
                  <span className="text-xs font-medium text-main w-16 text-right">{edge.value.toLocaleString()} ft</span>
                </div>
              );
            })}
            <div className="pt-2 mt-2 border-t border-main flex justify-between px-0">
              <span className="text-xs font-semibold text-muted">Total Edge</span>
              <span className="text-xs font-bold text-main">
                {(roof.ridgeLengthFt + roof.hipLengthFt + roof.valleyLengthFt + roof.eaveLengthFt + roof.rakeLengthFt).toLocaleString()} ft
              </span>
            </div>
          </div>
        </SectionCard>

        {/* Structure Details */}
        <SectionCard title="Structure Details" icon={Home} color="#8B5CF6">
          <div className="space-y-0">
            <MetricRow label="Shape" value={roof.predominantShape ? (SHAPE_LABELS[roof.predominantShape] || roof.predominantShape) : 'Unknown'} />
            {roof.predominantMaterial && <MetricRow label="Material" value={roof.predominantMaterial.replace(/_/g, ' ')} highlight />}
            <MetricRow label="Facet Count" value={roof.facetCount} />
            <MetricRow label="Penetrations" value={roof.penetrationCount} />
            <MetricRow label="Pitch (degrees)" value={`${roof.pitchDegrees.toFixed(1)}°`} />
          </div>
        </SectionCard>
      </div>

      {/* Facets Table */}
      {facets.length > 0 && (
        <SectionCard title={`Roof Facets (${facets.length})`} icon={Layers} color="#8B5CF6">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="pb-3 text-left text-[11px] font-semibold text-muted uppercase tracking-wider">#</th>
                  <th className="pb-3 text-left text-[11px] font-semibold text-muted uppercase tracking-wider">Area</th>
                  <th className="pb-3 text-left text-[11px] font-semibold text-muted uppercase tracking-wider">Pitch</th>
                  <th className="pb-3 text-left text-[11px] font-semibold text-muted uppercase tracking-wider">Direction</th>
                  <th className="pb-3 text-left text-[11px] font-semibold text-muted uppercase tracking-wider">Sun Hours</th>
                  <th className="pb-3 text-left text-[11px] font-semibold text-muted uppercase tracking-wider">Shade</th>
                </tr>
              </thead>
              <tbody>
                {facets.map(f => {
                  const az = f.azimuthDegrees;
                  const dir = az >= 315 || az < 45 ? 'N' : az >= 45 && az < 135 ? 'E' : az >= 135 && az < 225 ? 'S' : 'W';
                  return (
                    <tr key={f.id} className="border-b border-main/30 hover:bg-surface/50 transition-colors">
                      <td className="py-3 font-medium text-main">{f.facetNumber}</td>
                      <td className="py-3 text-main">{f.areaSqft.toLocaleString()} <span className="text-muted">sqft</span></td>
                      <td className="py-3 text-main">{f.pitchDegrees.toFixed(1)}°</td>
                      <td className="py-3">
                        <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-surface text-xs font-medium text-main">
                          <Compass size={11} className="text-muted" /> {dir} ({f.azimuthDegrees.toFixed(0)}°)
                        </span>
                      </td>
                      <td className="py-3 text-main">{f.annualSunHours?.toLocaleString() ?? '—'} <span className="text-muted">hrs/yr</span></td>
                      <td className="py-3">
                        {f.shadeFactor != null ? (
                          <span className={cn('text-xs font-medium px-2 py-0.5 rounded-md',
                            f.shadeFactor >= 0.7 ? 'bg-emerald-500/10 text-emerald-500' :
                            f.shadeFactor >= 0.4 ? 'bg-amber-500/10 text-amber-500' : 'bg-red-500/10 text-red-400'
                          )}>
                            {Math.round(f.shadeFactor * 100)}% sun
                          </span>
                        ) : '—'}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </SectionCard>
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
      <EmptyState icon={Ruler} title="Wall Measurements Pending"
        description="Wall measurements are generated from building footprints and structural data. Run trade estimation to auto-calculate wall areas, siding measurements, and per-face breakdowns."
        action="Generate Trade Data" onAction={onEstimate} loading={estimating} />
    );
  }

  return (
    <div className="space-y-4">
      {/* Hero stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <StatCard label="Total Wall Area" value={walls.totalWallAreaSqft} unit="sq ft" icon={Ruler} color="#3B82F6" />
        <StatCard label="Net Siding Area" value={walls.totalSidingAreaSqft} unit="sq ft" icon={Layers} color="#06B6D4" />
        <StatCard label="Stories" value={walls.stories} icon={Home} color="#8B5CF6"
          subtitle={`${walls.avgWallHeightFt} ft avg height`} />
        <StatCard label="Confidence" value={`${walls.confidence}%`} icon={Shield} color={walls.confidence >= 70 ? '#10B981' : '#F59E0B'}
          subtitle={walls.isEstimated ? 'Derived from footprint' : 'Measured'} />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Openings */}
        <SectionCard title="Openings & Deductions" icon={Ruler} color="#3B82F6">
          <div className="space-y-0">
            <MetricRow label="Window Area (est)" value={walls.windowAreaEstSqft} unit="sq ft" />
            <MetricRow label="Door Area (est)" value={walls.doorAreaEstSqft} unit="sq ft" />
            <div className="pt-2 mt-1 border-t border-main">
              <MetricRow label="Total Deductions" value={walls.windowAreaEstSqft + walls.doorAreaEstSqft} unit="sq ft" highlight />
            </div>
          </div>
        </SectionCard>

        {/* Trim & Accessories */}
        <SectionCard title="Trim & Accessories" icon={Activity} color="#F59E0B">
          <div className="space-y-0">
            <MetricRow label="Trim" value={walls.trimLinearFt} unit="LF" />
            <MetricRow label="Fascia" value={walls.fasciaLinearFt} unit="LF" />
            <MetricRow label="Soffit" value={walls.soffitSqft} unit="sq ft" />
          </div>
        </SectionCard>
      </div>

      {/* Per-face breakdown */}
      {walls.perFace.length > 0 && (
        <SectionCard title="Per-Face Breakdown" icon={Compass} color="#8B5CF6">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  {['Face', 'Width', 'Height', 'Gross Area', 'Windows', 'Doors', 'Net Area'].map(h => (
                    <th key={h} className="pb-3 text-left text-[11px] font-semibold text-muted uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {walls.perFace.map((face, i) => (
                  <tr key={i} className="border-b border-main/30 hover:bg-surface/50 transition-colors">
                    <td className="py-3 capitalize font-semibold text-main">
                      <span className="inline-flex items-center gap-1.5">
                        <Compass size={12} className="text-muted" /> {face.direction}
                      </span>
                    </td>
                    <td className="py-3 text-main">{face.width_ft} ft</td>
                    <td className="py-3 text-main">{face.height_ft} ft</td>
                    <td className="py-3 text-main">{face.area_sqft} sq ft</td>
                    <td className="py-3 text-main">{face.window_count_est}</td>
                    <td className="py-3 text-main">{face.door_count_est}</td>
                    <td className="py-3 font-semibold text-accent">{face.net_area_sqft} sq ft</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </SectionCard>
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
      <EmptyState icon={BarChart3} title="Trade Data Not Generated"
        description="Generate trade-specific measurements, material lists, waste factors, and crew estimates for all applicable trades. This uses your property scan data to calculate quantities for roofing, siding, gutters, painting, and more."
        action="Generate Trade Data" onAction={onEstimate} loading={estimating} />
    );
  }

  return (
    <div className="space-y-4">
      {/* Trade selector pills */}
      <div className="flex items-center gap-2 flex-wrap">
        {tradeBids.map(t => {
          const isSelected = selectedTrade === t.trade;
          const color = TRADE_COLORS[t.trade] || '#6B7280';
          return (
            <button key={t.trade}
              onClick={() => onSelectTrade(isSelected ? null : t.trade)}
              className={cn(
                'inline-flex items-center gap-2 px-3.5 py-2 rounded-lg text-sm font-medium transition-all border',
                isSelected
                  ? 'shadow-sm text-main'
                  : 'border-main/50 text-muted hover:text-main hover:border-main'
              )}
              style={isSelected ? { borderColor: color, backgroundColor: `${color}10` } : undefined}
            >
              <span className="w-2 h-2 rounded-full" style={{ backgroundColor: color }} />
              {TRADE_LABELS[t.trade] || t.trade}
              <span className="text-[10px] text-muted ml-0.5">{t.materialList.length}</span>
            </button>
          );
        })}
        <Button variant="ghost" size="sm" onClick={onEstimate} disabled={estimating} className="ml-auto">
          <RefreshCw size={12} className={estimating ? 'animate-spin' : ''} />
          Refresh
        </Button>
      </div>

      {/* Grid overview */}
      {!activeTrade && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {tradeBids.map(t => {
            const color = TRADE_COLORS[t.trade] || '#6B7280';
            const Icon = TRADE_ICONS[t.trade] || BarChart3;
            return (
              <button key={t.trade}
                onClick={() => onSelectTrade(t.trade)}
                className="relative overflow-hidden rounded-xl bg-card border border-main p-4 text-left hover:border-accent/40 transition-all group"
              >
                <div className="absolute top-0 left-0 w-1 h-full" style={{ backgroundColor: color }} />
                <div className="flex items-start justify-between pl-2 mb-3">
                  <div>
                    <h4 className="text-sm font-semibold text-main">{TRADE_LABELS[t.trade]}</h4>
                    <p className="text-[11px] text-muted">{t.materialList.length} material{t.materialList.length !== 1 ? 's' : ''}</p>
                  </div>
                  <div className="w-8 h-8 rounded-lg flex items-center justify-center opacity-20 group-hover:opacity-40 transition-opacity"
                    style={{ backgroundColor: color }}>
                    <Icon size={16} className="text-white" />
                  </div>
                </div>
                <div className="pl-2 grid grid-cols-2 gap-y-1.5 text-xs">
                  <span className="text-muted">Waste</span>
                  <span className="text-main text-right font-medium">{t.wasteFactorPct}%</span>
                  <span className="text-muted">Complexity</span>
                  <span className="text-main text-right font-medium">{t.complexityScore}/10</span>
                  <span className="text-muted">Crew</span>
                  <span className="text-main text-right font-medium">{t.recommendedCrewSize}</span>
                  {t.estimatedLaborHours && <>
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
      {/* Hero stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <StatCard label="Material Items" value={trade.materialList.length} icon={Package} color={color} />
        <StatCard label="Waste Factor" value={`${trade.wasteFactorPct}%`} icon={Activity} color="#F59E0B" />
        <StatCard label="Crew Size" value={trade.recommendedCrewSize} unit="workers" icon={Users} color="#3B82F6" />
        <StatCard label="Labor" value={trade.estimatedLaborHours ?? '—'} unit={trade.estimatedLaborHours ? 'hours' : ''} icon={Clock} color="#10B981" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Measurements */}
        <SectionCard title={`${TRADE_LABELS[trade.trade]} Measurements`} icon={Ruler} color={color}>
          <div className="space-y-0">
            {Object.entries(trade.measurements).map(([key, val]) => (
              <MetricRow key={key}
                label={key.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                value={typeof val === 'number' ? val : String(val ?? '—')} />
            ))}
            {Object.keys(trade.measurements).length === 0 && (
              <p className="text-xs text-muted py-4 text-center">No detailed measurements available</p>
            )}
          </div>
        </SectionCard>

        {/* Complexity info */}
        <SectionCard title="Job Intelligence" icon={Activity} color="#F59E0B">
          <div className="space-y-0">
            <MetricRow label="Complexity Score" value={`${trade.complexityScore}/10`} highlight={trade.complexityScore >= 7} />
            <MetricRow label="Waste Factor" value={`${trade.wasteFactorPct}%`} />
            <MetricRow label="Recommended Crew" value={`${trade.recommendedCrewSize} workers`} />
            {trade.estimatedLaborHours && <MetricRow label="Estimated Labor" value={`${trade.estimatedLaborHours} hours`} highlight />}
            {trade.dataSources.length > 0 && (
              <div className="pt-2 mt-2 border-t border-main">
                <p className="text-[10px] text-muted uppercase tracking-wider mb-1.5">Data Sources</p>
                <div className="flex flex-wrap gap-1">
                  {trade.dataSources.map(s => (
                    <span key={s} className="px-2 py-0.5 rounded-md bg-surface border border-main text-[10px] text-muted">{s.replace(/_/g, ' ')}</span>
                  ))}
                </div>
              </div>
            )}
          </div>
        </SectionCard>
      </div>

      {/* Material List */}
      {trade.materialList.length > 0 && (
        <SectionCard title={`Material List (${trade.materialList.length})`} icon={Package} color={color}>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  {['Item', 'Base Qty', 'Unit', 'Waste', 'Total Qty'].map(h => (
                    <th key={h} className={cn('pb-3 text-[11px] font-semibold text-muted uppercase tracking-wider',
                      h !== 'Item' && h !== 'Unit' ? 'text-right' : 'text-left')}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {trade.materialList.map((mat, i) => (
                  <tr key={i} className="border-b border-main/30 hover:bg-surface/50 transition-colors">
                    <td className="py-3 font-medium text-main">{mat.item}</td>
                    <td className="py-3 text-main text-right">{mat.quantity.toLocaleString()}</td>
                    <td className="py-3 text-muted">{mat.unit}</td>
                    <td className="py-3 text-right">
                      <span className="px-1.5 py-0.5 rounded text-[10px] font-medium bg-amber-500/10 text-amber-500">+{mat.waste_pct}%</span>
                    </td>
                    <td className="py-3 text-right font-bold text-main">{mat.total_with_waste.toLocaleString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </SectionCard>
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
      <EmptyState icon={Sun} title="Solar Analysis Pending"
        description="Solar potential data is generated from roof facet analysis and trade estimation. Run trade estimation to calculate panel capacity, annual production, and sun exposure per facet." />
    );
  }

  const measurements = solarBid?.measurements || {};
  const maxSunHours = Math.max(...facets.map(f => f.annualSunHours || 0), 1);

  return (
    <div className="space-y-4">
      {/* Hero stats */}
      {solarBid && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          <StatCard label="Max Panels" value={Number(measurements.max_panel_count) || 0} icon={Sun} color="#F59E0B" />
          <StatCard label="System Size" value={Number(measurements.system_size_kw) || 0} unit="kW" icon={Zap} color="#10B981" />
          <StatCard label="Annual Production" value={Number(measurements.estimated_annual_kwh) || 0} unit="kWh" icon={Activity} color="#3B82F6" />
          <StatCard label="Usable Roof" value={Number(measurements.usable_roof_area_sqft) || 0} unit="sq ft" icon={Home} color="#8B5CF6"
            subtitle={`${measurements.usable_facets || 0} of ${measurements.total_facets || 0} facets`} />
        </div>
      )}

      {/* Facet Sun Analysis */}
      {facets.length > 0 && (
        <SectionCard title="Sun Exposure by Facet" icon={Sun} color="#F59E0B">
          <div className="space-y-3">
            {facets.map(f => {
              const ratio = (f.annualSunHours || 0) / maxSunHours;
              const az = f.azimuthDegrees;
              const direction = az >= 315 || az < 45 ? 'N' : az >= 45 && az < 135 ? 'E' : az >= 135 && az < 225 ? 'S' : 'W';
              const isUsable = az >= 90 && az <= 315 && ratio > 0.5;
              return (
                <div key={f.id} className="space-y-1.5">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-muted flex items-center gap-1.5">
                      <Compass size={11} />
                      Facet {f.facetNumber}
                      <span className="px-1.5 py-0.5 rounded bg-surface text-[10px] font-medium">{direction}</span>
                      <span className="text-muted">{f.areaSqft.toLocaleString()} sqft</span>
                    </span>
                    <span className={cn('font-semibold', isUsable ? 'text-amber-500' : 'text-muted')}>
                      {f.annualSunHours?.toLocaleString() ?? '—'} hrs/yr
                    </span>
                  </div>
                  <div className="h-2.5 rounded-full bg-main/10 overflow-hidden">
                    <div
                      className={cn('h-full rounded-full transition-all', isUsable ? 'bg-gradient-to-r from-amber-500 to-yellow-400' : 'bg-gray-500')}
                      style={{ width: `${Math.round(ratio * 100)}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </SectionCard>
      )}

      {/* Solar Material List */}
      {solarBid && solarBid.materialList.length > 0 && (
        <SectionCard title="Solar Material List" icon={Package} color="#F59E0B">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="pb-3 text-left text-[11px] font-semibold text-muted uppercase tracking-wider">Item</th>
                  <th className="pb-3 text-right text-[11px] font-semibold text-muted uppercase tracking-wider">Qty</th>
                  <th className="pb-3 text-left text-[11px] font-semibold text-muted uppercase tracking-wider">Unit</th>
                </tr>
              </thead>
              <tbody>
                {solarBid.materialList.map((mat, i) => (
                  <tr key={i} className="border-b border-main/30 hover:bg-surface/50 transition-colors">
                    <td className="py-3 font-medium text-main">{mat.item}</td>
                    <td className="py-3 text-main text-right font-bold">{mat.total_with_waste.toLocaleString()}</td>
                    <td className="py-3 text-muted">{mat.unit}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </SectionCard>
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
      {/* Input */}
      <SectionCard title="Storm Damage Assessment" icon={CloudLightning} color="#EF4444">
        <div className="space-y-4">
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="text-[11px] font-medium text-muted uppercase tracking-wider block mb-1.5">Storm Date</label>
              <input type="date" value={stormDate} onChange={(e) => setStormDate(e.target.value)}
                className="w-full bg-surface border border-main rounded-lg px-3 py-2.5 text-sm text-main focus:border-accent focus:outline-none transition-colors" />
            </div>
            <div>
              <label className="text-[11px] font-medium text-muted uppercase tracking-wider block mb-1.5">State</label>
              <input type="text" value={state} onChange={(e) => setState(e.target.value.toUpperCase())}
                placeholder="CT" maxLength={2}
                className="w-full bg-surface border border-main rounded-lg px-3 py-2.5 text-sm text-main focus:border-accent focus:outline-none uppercase transition-colors" />
            </div>
            <div>
              <label className="text-[11px] font-medium text-muted uppercase tracking-wider block mb-1.5">County (optional)</label>
              <input type="text" value={county} onChange={(e) => setCounty(e.target.value)} placeholder="Hartford"
                className="w-full bg-surface border border-main rounded-lg px-3 py-2.5 text-sm text-main focus:border-accent focus:outline-none transition-colors" />
            </div>
          </div>
          <div className="flex items-center gap-3">
            <Button variant="primary" size="sm" onClick={handleAssess} disabled={loading || !stormDate || !state}>
              {loading ? <Loader2 size={14} className="animate-spin" /> : <ShieldAlert size={14} />}
              {loading ? 'Analyzing...' : 'Run Assessment'}
            </Button>
            {result && <Button variant="ghost" size="sm" onClick={reset}>Clear Results</Button>}
          </div>
          {error && (
            <div className="flex items-center gap-2 text-sm text-red-400 bg-red-500/10 px-3 py-2 rounded-lg">
              <AlertTriangle size={14} /> {error}
            </div>
          )}
        </div>
      </SectionCard>

      {/* Results */}
      {result && (
        <>
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
            <StatCard label="Damage Probability" value={`${result.probability || 0}%`}
              icon={ShieldAlert} color={(result.probability || 0) >= 50 ? '#EF4444' : (result.probability || 0) >= 25 ? '#F59E0B' : '#3B82F6'} />
            <StatCard label="Storm Events" value={result.storm_events_found} icon={CloudLightning} color="#8B5CF6" />
            <StatCard label="Max Hail" value={result.maxHailInches ? `${result.maxHailInches}"` : 'None'} icon={CircleDot} color="#06B6D4" />
            <StatCard label="Max Wind" value={result.maxWindKnots ? `${result.maxWindKnots} kts` : 'None'} icon={Wind} color="#F59E0B" />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Probability gauge */}
            <SectionCard title="Damage Probability" icon={Activity} color="#EF4444">
              <div className="text-center py-4">
                <div className="relative inline-flex items-center justify-center w-36 h-36">
                  <svg className="w-36 h-36 -rotate-90" viewBox="0 0 144 144">
                    <circle cx="72" cy="72" r="60" fill="none" strokeWidth="10" className="stroke-current text-main/10" />
                    <circle cx="72" cy="72" r="60" fill="none" strokeWidth="10" strokeLinecap="round"
                      strokeDasharray={`${((result.probability || 0) / 100) * 377} 377`}
                      className={cn('transition-all duration-700',
                        (result.probability || 0) >= 50 ? 'text-red-500' : (result.probability || 0) >= 25 ? 'text-orange-500' : 'text-blue-500'
                      )}
                      stroke="currentColor" />
                  </svg>
                  <span className="absolute text-4xl font-bold text-main">{result.probability || 0}%</span>
                </div>
                <p className="text-sm text-muted mt-3">Estimated storm damage probability</p>
              </div>
            </SectionCard>

            {/* Storm Details */}
            <SectionCard title="Storm Intelligence" icon={Database} color="#3B82F6">
              <div className="space-y-0">
                <MetricRow label="Storm Events Found" value={result.storm_events_found} highlight={result.storm_events_found > 0} />
                <MetricRow label="Max Hail Size" value={result.maxHailInches ? `${result.maxHailInches}"` : 'None detected'} />
                <MetricRow label="Max Wind Speed" value={result.maxWindKnots ? `${result.maxWindKnots} kts` : 'None detected'} />
                <MetricRow label="Nearest Event" value={
                  result.nearestEventMiles != null && result.nearestEventMiles >= 0
                    ? `${result.nearestEventMiles} mi` : 'N/A'
                } />
                <div className="pt-3 mt-3 border-t border-main space-y-2">
                  <div className="flex items-center gap-2 text-xs text-muted">
                    <CircleDot size={11} /> Hail &ge; 1&quot; causes shingle damage
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted">
                    <Wind size={11} /> Wind &ge; 65 kts causes structural damage
                  </div>
                </div>
              </div>
            </SectionCard>
          </div>
        </>
      )}

      {/* Disclaimer */}
      <div className="flex items-start gap-2.5 px-4 py-3 rounded-xl bg-card border border-main">
        <Info size={14} className="text-muted mt-0.5 shrink-0" />
        <p className="text-[11px] text-muted leading-relaxed">
          Storm data sourced from NOAA Storm Events Database and SPC Storm Reports (public domain).
          Damage probability is estimated based on proximity, hail size, wind speed, and estimated roof age.
          This is for informational purposes only and does not constitute an insurance claim.
        </p>
      </div>
    </div>
  );
}
