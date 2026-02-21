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
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatDate, cn } from '@/lib/utils';
import {
  usePropertyScan,
  type RoofMeasurementData,
  type RoofFacetData,
  type WallMeasurementData,
  type TradeBidData,
  type TradeType,
} from '@/lib/hooks/use-property-scan';
import { useStormAssess } from '@/lib/hooks/use-storm-assess';

type TabType = 'roof' | 'walls' | 'trades' | 'solar' | 'storm';

const TABS: { key: TabType; label: string; icon: typeof Ruler }[] = [
  { key: 'roof', label: 'Roof', icon: Layers },
  { key: 'walls', label: 'Walls', icon: Ruler },
  { key: 'trades', label: 'Trade Data', icon: BarChart3 },
  { key: 'solar', label: 'Solar', icon: Sun },
  { key: 'storm', label: 'Storm', icon: CloudLightning },
];

const TRADE_LABELS: Record<TradeType, string> = {
  roofing: 'Roofing',
  siding: 'Siding / Exterior',
  gutters: 'Gutters',
  solar: 'Solar',
  painting: 'Painting',
  landscaping: 'Landscaping',
  fencing: 'Fencing',
  concrete: 'Concrete / Paving',
  hvac: 'HVAC',
  electrical: 'Electrical',
  plumbing: 'Plumbing',
  insulation: 'Insulation',
  windows_doors: 'Windows & Doors',
  flooring: 'Flooring',
  drywall: 'Drywall',
  framing: 'Framing',
  masonry: 'Masonry',
  waterproofing: 'Waterproofing',
  demolition: 'Demolition',
  tree_service: 'Tree Service',
  pool: 'Pool',
  garage_door: 'Garage Door',
  fire_protection: 'Fire Protection',
  elevator: 'Elevator',
  fire_alarm: 'Fire Alarm',
  low_voltage: 'Low Voltage',
  irrigation: 'Irrigation',
  paving: 'Paving',
  metal_fabrication: 'Metal Fabrication',
  glass_glazing: 'Glass & Glazing',
};

const SHAPE_LABELS: Record<string, string> = {
  gable: 'Gable', hip: 'Hip', flat: 'Flat', gambrel: 'Gambrel', mansard: 'Mansard', mixed: 'Complex/Mixed',
};

const CONFIDENCE_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
  high: { label: 'High Confidence', color: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-500/10' },
  moderate: { label: 'Moderate — Verify on Site', color: 'text-amber-600 dark:text-amber-400', bg: 'bg-amber-500/10' },
  low: { label: 'Low — Verify on Site', color: 'text-red-600 dark:text-red-400', bg: 'bg-red-500/10' },
};

function MetricRow({ label, value, unit }: { label: string; value: string | number; unit?: string }) {
  return (
    <div className="flex justify-between py-1.5">
      <span className="text-sm text-muted">{label}</span>
      <span className="text-sm font-medium text-main">
        {typeof value === 'number' ? value.toLocaleString() : value}
        {unit && <span className="text-muted ml-1">{unit}</span>}
      </span>
    </div>
  );
}

export default function ReconDetailPage() {
  const router = useRouter();
  const params = useParams();
  const scanId = params.id as string;
  const [activeTab, setActiveTab] = useState<TabType>('roof');
  const [selectedTrade, setSelectedTrade] = useState<TradeType | null>(null);
  const [estimating, setEstimating] = useState(false);

  const { scan, roof, facets, walls, tradeBids, loading, error, refetch, triggerTradeEstimate } = usePropertyScan(scanId, 'scan');

  const handleEstimate = useCallback(async () => {
    if (!scan) return;
    setEstimating(true);
    await triggerTradeEstimate(scan.id);
    setEstimating(false);
  }, [scan, triggerTradeEstimate]);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (error || !scan) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" size="sm" onClick={() => router.back()}>
          <ArrowLeft size={16} /> Back
        </Button>
        <Card>
          <CardContent className="py-12 text-center">
            <p className="text-sm text-red-500">{error || 'Scan not found'}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  const conf = CONFIDENCE_CONFIG[scan.confidenceGrade] || CONFIDENCE_CONFIG.low;
  const imageryOld = scan.imageryAgeMonths != null && scan.imageryAgeMonths > 18;
  const activeTrade = selectedTrade ? tradeBids.find(t => t.trade === selectedTrade) : null;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="sm" onClick={() => router.back()}>
            <ArrowLeft size={16} />
          </Button>
          <div>
            <h1 className="text-xl font-bold text-main">{scan.address}</h1>
            <p className="text-sm text-muted">
              {[scan.city, scan.state, scan.zip].filter(Boolean).join(', ')}
              {scan.imageryDate && ` — Imagery: ${formatDate(scan.imageryDate)}`}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <div className={cn('inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium', conf.bg, conf.color)}>
            <Shield size={12} />
            {conf.label} ({scan.confidenceScore}%)
          </div>
          {scan.scanSources.length > 0 && (
            <div className="flex gap-1">
              {scan.scanSources.map(src => (
                <Badge key={src} variant="secondary" className="text-[10px]">
                  {src.replace('_', ' ')}
                </Badge>
              ))}
            </div>
          )}
          <Button
            variant="primary"
            size="sm"
            onClick={async () => {
              const supabase = createClient();
              const { data: { user } } = await supabase.auth.getUser();
              if (!user) return;
              const companyId = user.app_metadata?.company_id;
              if (!companyId) return;
              const now = new Date();
              const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
              const { data: est } = await supabase
                .from('estimates')
                .insert({
                  company_id: companyId,
                  created_by: user.id,
                  title: `Estimate — ${scan.address}`,
                  estimate_number: `EST-${dateStr}-001`,
                  estimate_type: 'regular',
                  status: 'draft',
                  property_scan_id: scan.id,
                  job_id: scan.jobId,
                  property_address: scan.address,
                  property_city: scan.city || '',
                  property_state: scan.state || '',
                  property_zip: scan.zip || '',
                  overhead_percent: 10,
                  profit_percent: 10,
                  tax_percent: 0,
                })
                .select('id')
                .single();
              if (est) router.push(`/dashboard/estimates/${est.id}`);
            }}
          >
            <FileText size={14} />
            Create Estimate
          </Button>
        </div>
      </div>

      {/* Warnings */}
      {imageryOld && (
        <div className="flex items-start gap-2 p-3 rounded-lg bg-amber-500/10 text-amber-600 dark:text-amber-400 text-sm">
          <AlertTriangle size={16} className="mt-0.5 shrink-0" />
          Imagery may not reflect recent changes ({scan.imageryAgeMonths} months old). Verify on site.
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-1 border-b border-main">
        {TABS.map(tab => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={cn(
              'flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors',
              activeTab === tab.key
                ? 'border-accent text-accent'
                : 'border-transparent text-muted hover:text-main hover:border-main/30'
            )}
          >
            <tab.icon size={14} />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'roof' && <RoofTab roof={roof} facets={facets} />}
      {activeTab === 'walls' && <WallsTab walls={walls} />}
      {activeTab === 'trades' && (
        <TradesTab
          tradeBids={tradeBids}
          selectedTrade={selectedTrade}
          onSelectTrade={setSelectedTrade}
          onEstimate={handleEstimate}
          estimating={estimating}
        />
      )}
      {activeTab === 'solar' && <SolarTab facets={facets} tradeBids={tradeBids} />}
      {activeTab === 'storm' && <StormTab scanId={scan.id} scanState={scan.state} />}

      {/* Legal Disclaimer */}
      <p className="text-[11px] text-muted leading-relaxed">
        Property measurements are derived from satellite imagery, public records, and AI analysis.
        They are estimates intended as starting points for bidding and estimating.
        Always verify critical measurements on site before placing material orders.
        Roof analysis powered by Google Solar API.
      </p>
    </div>
  );
}

// ============================================================================
// ROOF TAB
// ============================================================================

function RoofTab({
  roof,
  facets,
}: {
  roof: RoofMeasurementData | null;
  facets: RoofFacetData[];
}) {
  if (!roof) {
    return (
      <Card>
        <CardContent className="py-12 text-center">
          <Layers size={32} className="mx-auto mb-3 text-muted" />
          <p className="text-sm text-muted">No roof measurement data available.</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      {/* Summary */}
      <Card>
        <CardHeader><CardTitle className="text-base">Roof Summary</CardTitle></CardHeader>
        <CardContent className="space-y-0.5">
          <MetricRow label="Total Area" value={roof.totalAreaSqft} unit="sq ft" />
          <MetricRow label="Total Squares" value={roof.totalAreaSquares} unit="SQ" />
          {roof.pitchPrimary && <MetricRow label="Primary Pitch" value={roof.pitchPrimary} />}
          <MetricRow label="Pitch (degrees)" value={roof.pitchDegrees} unit="deg" />
          {roof.predominantShape && <MetricRow label="Shape" value={SHAPE_LABELS[roof.predominantShape] || roof.predominantShape} />}
          <MetricRow label="Facets" value={roof.facetCount} />
          <MetricRow label="Complexity" value={`${roof.complexityScore}/10`} />
          <MetricRow label="Penetrations" value={roof.penetrationCount} />
          {roof.predominantMaterial && <MetricRow label="Material" value={roof.predominantMaterial} />}
        </CardContent>
      </Card>

      {/* Edge Lengths */}
      <Card>
        <CardHeader><CardTitle className="text-base">Edge Lengths</CardTitle></CardHeader>
        <CardContent className="space-y-0.5">
          <MetricRow label="Ridge" value={roof.ridgeLengthFt} unit="ft" />
          <MetricRow label="Hip" value={roof.hipLengthFt} unit="ft" />
          <MetricRow label="Valley" value={roof.valleyLengthFt} unit="ft" />
          <MetricRow label="Eave" value={roof.eaveLengthFt} unit="ft" />
          <MetricRow label="Rake" value={roof.rakeLengthFt} unit="ft" />
          <div className="pt-2 border-t border-main mt-2">
            <MetricRow
              label="Total Edge"
              value={roof.ridgeLengthFt + roof.hipLengthFt + roof.valleyLengthFt + roof.eaveLengthFt + roof.rakeLengthFt}
              unit="ft"
            />
          </div>
        </CardContent>
      </Card>

      {/* Facets Table */}
      {facets.length > 0 && (
        <Card className="md:col-span-2">
          <CardHeader><CardTitle className="text-base">Roof Facets ({facets.length})</CardTitle></CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-main text-left">
                    <th className="pb-2 text-muted font-medium">#</th>
                    <th className="pb-2 text-muted font-medium">Area (sqft)</th>
                    <th className="pb-2 text-muted font-medium">Pitch (deg)</th>
                    <th className="pb-2 text-muted font-medium">Azimuth</th>
                    <th className="pb-2 text-muted font-medium">Sun Hours/yr</th>
                    <th className="pb-2 text-muted font-medium">Shade</th>
                  </tr>
                </thead>
                <tbody>
                  {facets.map(f => (
                    <tr key={f.id} className="border-b border-main/50">
                      <td className="py-2 text-main">{f.facetNumber}</td>
                      <td className="py-2 text-main">{f.areaSqft.toLocaleString()}</td>
                      <td className="py-2 text-main">{f.pitchDegrees.toFixed(1)}</td>
                      <td className="py-2 text-main">{f.azimuthDegrees.toFixed(0)}°</td>
                      <td className="py-2 text-main">{f.annualSunHours?.toLocaleString() ?? '—'}</td>
                      <td className="py-2 text-main">
                        {f.shadeFactor != null ? `${Math.round((1 - f.shadeFactor) * 100)}%` : '—'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// ============================================================================
// WALLS TAB
// ============================================================================

function WallsTab({ walls }: { walls: WallMeasurementData | null }) {
  if (!walls) {
    return (
      <Card>
        <CardContent className="py-12 text-center">
          <Ruler size={32} className="mx-auto mb-3 text-muted" />
          <p className="text-sm text-muted">No wall measurement data. Run trade estimation to generate.</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      {/* Summary */}
      <Card>
        <CardHeader><CardTitle className="text-base">Wall Summary</CardTitle></CardHeader>
        <CardContent className="space-y-0.5">
          <MetricRow label="Total Wall Area" value={walls.totalWallAreaSqft} unit="sq ft" />
          <MetricRow label="Siding Area (net)" value={walls.totalSidingAreaSqft} unit="sq ft" />
          <MetricRow label="Stories" value={walls.stories} />
          <MetricRow label="Avg Wall Height" value={walls.avgWallHeightFt} unit="ft" />
          <MetricRow label="Window Area (est)" value={walls.windowAreaEstSqft} unit="sq ft" />
          <MetricRow label="Door Area (est)" value={walls.doorAreaEstSqft} unit="sq ft" />
          <MetricRow label="Confidence" value={`${walls.confidence}%`} />
          {walls.isEstimated && (
            <div className="pt-2">
              <Badge variant="secondary" className="text-[10px]">Derived from footprint</Badge>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Trim & Accessories */}
      <Card>
        <CardHeader><CardTitle className="text-base">Trim & Accessories</CardTitle></CardHeader>
        <CardContent className="space-y-0.5">
          <MetricRow label="Trim" value={walls.trimLinearFt} unit="LF" />
          <MetricRow label="Fascia" value={walls.fasciaLinearFt} unit="LF" />
          <MetricRow label="Soffit" value={walls.soffitSqft} unit="sq ft" />
        </CardContent>
      </Card>

      {/* Per-face breakdown */}
      {walls.perFace.length > 0 && (
        <Card className="md:col-span-2">
          <CardHeader><CardTitle className="text-base">Per-Face Breakdown</CardTitle></CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-main text-left">
                    <th className="pb-2 text-muted font-medium">Face</th>
                    <th className="pb-2 text-muted font-medium">Width</th>
                    <th className="pb-2 text-muted font-medium">Height</th>
                    <th className="pb-2 text-muted font-medium">Area</th>
                    <th className="pb-2 text-muted font-medium">Windows</th>
                    <th className="pb-2 text-muted font-medium">Doors</th>
                    <th className="pb-2 text-muted font-medium">Net Area</th>
                  </tr>
                </thead>
                <tbody>
                  {walls.perFace.map((face, i) => (
                    <tr key={i} className="border-b border-main/50">
                      <td className="py-2 text-main capitalize font-medium">{face.direction}</td>
                      <td className="py-2 text-main">{face.width_ft} ft</td>
                      <td className="py-2 text-main">{face.height_ft} ft</td>
                      <td className="py-2 text-main">{face.area_sqft} sq ft</td>
                      <td className="py-2 text-main">{face.window_count_est}</td>
                      <td className="py-2 text-main">{face.door_count_est}</td>
                      <td className="py-2 text-main font-medium">{face.net_area_sqft} sq ft</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// ============================================================================
// TRADES TAB
// ============================================================================

function TradesTab({
  tradeBids,
  selectedTrade,
  onSelectTrade,
  onEstimate,
  estimating,
}: {
  tradeBids: TradeBidData[];
  selectedTrade: TradeType | null;
  onSelectTrade: (t: TradeType | null) => void;
  onEstimate: () => void;
  estimating: boolean;
}) {
  const activeTrade = selectedTrade ? tradeBids.find(t => t.trade === selectedTrade) : null;

  if (tradeBids.length === 0) {
    return (
      <Card>
        <CardContent className="py-12 text-center">
          <BarChart3 size={32} className="mx-auto mb-3 text-muted" />
          <p className="text-sm text-muted mb-4">No trade data generated yet.</p>
          <Button variant="primary" size="sm" onClick={onEstimate} disabled={estimating}>
            {estimating ? (
              <><RefreshCw size={14} className="animate-spin" /> Calculating...</>
            ) : (
              <><BarChart3 size={14} /> Generate Trade Data</>
            )}
          </Button>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {/* Trade selector */}
      <div className="flex flex-wrap gap-2">
        {tradeBids.map(t => (
          <button
            key={t.trade}
            onClick={() => onSelectTrade(selectedTrade === t.trade ? null : t.trade)}
            className={cn(
              'px-3 py-1.5 rounded-lg text-sm font-medium transition-colors border',
              selectedTrade === t.trade
                ? 'border-accent bg-accent/10 text-accent'
                : 'border-main text-muted hover:text-main hover:border-main/60'
            )}
          >
            {TRADE_LABELS[t.trade] || t.trade}
          </button>
        ))}
        <Button variant="ghost" size="sm" onClick={onEstimate} disabled={estimating}>
          <RefreshCw size={12} className={estimating ? 'animate-spin' : ''} />
          Refresh
        </Button>
      </div>

      {/* Overview grid when no trade selected */}
      {!activeTrade && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {tradeBids.map(t => (
            <Card
              key={t.trade}
              className="cursor-pointer hover:border-accent transition-colors"
              onClick={() => onSelectTrade(t.trade)}
            >
              <CardContent className="py-4 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-semibold text-main">{TRADE_LABELS[t.trade]}</span>
                  <Badge variant="secondary" className="text-[10px]">{t.materialList.length} items</Badge>
                </div>
                <div className="space-y-1 text-xs">
                  <div className="flex justify-between">
                    <span className="text-muted">Waste Factor</span>
                    <span className="text-main">{t.wasteFactorPct}%</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted">Complexity</span>
                    <span className="text-main">{t.complexityScore}/10</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted">Crew Size</span>
                    <span className="text-main">{t.recommendedCrewSize}</span>
                  </div>
                  {t.estimatedLaborHours && (
                    <div className="flex justify-between">
                      <span className="text-muted">Labor Hours</span>
                      <span className="text-main">{t.estimatedLaborHours}h</span>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Selected trade detail */}
      {activeTrade && <TradeDetail trade={activeTrade} />}
    </div>
  );
}

function TradeDetail({ trade }: { trade: TradeBidData }) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      {/* Measurements */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{TRADE_LABELS[trade.trade]} — Measurements</CardTitle>
        </CardHeader>
        <CardContent className="space-y-0.5">
          {Object.entries(trade.measurements).map(([key, val]) => (
            <MetricRow
              key={key}
              label={key.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
              value={typeof val === 'number' ? val : String(val ?? '—')}
            />
          ))}
        </CardContent>
      </Card>

      {/* Stats */}
      <Card>
        <CardHeader><CardTitle className="text-base">Job Estimates</CardTitle></CardHeader>
        <CardContent className="space-y-0.5">
          <MetricRow label="Waste Factor" value={`${trade.wasteFactorPct}%`} />
          <MetricRow label="Complexity Score" value={`${trade.complexityScore}/10`} />
          <div className="flex items-center gap-1.5 py-1.5">
            <Users size={14} className="text-muted" />
            <span className="text-sm text-muted">Recommended Crew</span>
            <span className="text-sm font-medium text-main ml-auto">{trade.recommendedCrewSize} workers</span>
          </div>
          {trade.estimatedLaborHours && (
            <div className="flex items-center gap-1.5 py-1.5">
              <Clock size={14} className="text-muted" />
              <span className="text-sm text-muted">Estimated Labor</span>
              <span className="text-sm font-medium text-main ml-auto">{trade.estimatedLaborHours} hours</span>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Material List */}
      <Card className="md:col-span-2">
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Package size={16} />
            Material List ({trade.materialList.length} items)
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main text-left">
                  <th className="pb-2 text-muted font-medium">Item</th>
                  <th className="pb-2 text-muted font-medium text-right">Qty</th>
                  <th className="pb-2 text-muted font-medium">Unit</th>
                  <th className="pb-2 text-muted font-medium text-right">Waste %</th>
                  <th className="pb-2 text-muted font-medium text-right">Total (w/ waste)</th>
                </tr>
              </thead>
              <tbody>
                {trade.materialList.map((mat, i) => (
                  <tr key={i} className="border-b border-main/50">
                    <td className="py-2 text-main">{mat.item}</td>
                    <td className="py-2 text-main text-right">{mat.quantity.toLocaleString()}</td>
                    <td className="py-2 text-muted">{mat.unit}</td>
                    <td className="py-2 text-main text-right">{mat.waste_pct}%</td>
                    <td className="py-2 text-main text-right font-medium">{mat.total_with_waste.toLocaleString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================================
// SOLAR TAB
// ============================================================================

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
    assessProperty({
      property_scan_id: scanId,
      storm_date: stormDate,
      state,
      county: county || undefined,
    });
  };

  return (
    <div className="space-y-4">
      {/* Input */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <CloudLightning size={16} className="text-purple-400" />
            Storm Damage Assessment
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="text-xs text-muted block mb-1">Storm Date</label>
              <input
                type="date"
                value={stormDate}
                onChange={(e) => setStormDate(e.target.value)}
                className="w-full bg-surface border border-main rounded-md px-3 py-2 text-sm text-main focus:border-accent focus:outline-none"
              />
            </div>
            <div>
              <label className="text-xs text-muted block mb-1">State (2-letter)</label>
              <input
                type="text"
                value={state}
                onChange={(e) => setState(e.target.value.toUpperCase())}
                placeholder="TX"
                maxLength={2}
                className="w-full bg-surface border border-main rounded-md px-3 py-2 text-sm text-main focus:border-accent focus:outline-none uppercase"
              />
            </div>
            <div>
              <label className="text-xs text-muted block mb-1">County (optional)</label>
              <input
                type="text"
                value={county}
                onChange={(e) => setCounty(e.target.value)}
                placeholder="Harris"
                className="w-full bg-surface border border-main rounded-md px-3 py-2 text-sm text-main focus:border-accent focus:outline-none"
              />
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="primary" size="sm" onClick={handleAssess} disabled={loading || !stormDate || !state}>
              {loading ? <Loader2 size={14} className="animate-spin" /> : <ShieldAlert size={14} />}
              {loading ? 'Analyzing...' : 'Run Assessment'}
            </Button>
            {result && (
              <Button variant="ghost" size="sm" onClick={reset}>Clear</Button>
            )}
          </div>
          {error && (
            <div className="flex items-center gap-2 text-sm text-red-400">
              <AlertTriangle size={14} />
              {error}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Results */}
      {result && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Probability gauge */}
          <Card>
            <CardHeader><CardTitle className="text-base">Damage Probability</CardTitle></CardHeader>
            <CardContent className="text-center py-6">
              <div className="relative inline-flex items-center justify-center w-32 h-32">
                <svg className="w-32 h-32 -rotate-90" viewBox="0 0 128 128">
                  <circle cx="64" cy="64" r="56" fill="none" stroke="currentColor" strokeWidth="8" className="text-surface" />
                  <circle
                    cx="64" cy="64" r="56" fill="none" strokeWidth="8"
                    strokeDasharray={`${((result.probability || 0) / 100) * 352} 352`}
                    strokeLinecap="round"
                    className={
                      (result.probability || 0) >= 50
                        ? 'text-red-500'
                        : (result.probability || 0) >= 25
                          ? 'text-orange-500'
                          : 'text-blue-500'
                    }
                    stroke="currentColor"
                  />
                </svg>
                <span className="absolute text-3xl font-bold text-main">{result.probability || 0}%</span>
              </div>
              <p className="text-sm text-muted mt-3">Estimated storm damage probability</p>
            </CardContent>
          </Card>

          {/* Storm Details */}
          <Card>
            <CardHeader><CardTitle className="text-base">Storm Intelligence</CardTitle></CardHeader>
            <CardContent className="space-y-0.5">
              <MetricRow label="Storm Events Found" value={result.storm_events_found} />
              <MetricRow
                label="Max Hail Size"
                value={result.maxHailInches ? `${result.maxHailInches}"` : 'None detected'}
              />
              <MetricRow
                label="Max Wind Speed"
                value={result.maxWindKnots ? `${result.maxWindKnots} kts` : 'None detected'}
              />
              <MetricRow
                label="Nearest Event"
                value={result.nearestEventMiles != null && result.nearestEventMiles >= 0
                  ? `${result.nearestEventMiles} mi`
                  : 'N/A'
                }
              />
              <div className="pt-3 border-t border-main mt-3 space-y-2">
                <div className="flex items-center gap-2 text-xs">
                  <CircleDot size={12} className="text-muted" />
                  <span className="text-muted">Hail &ge; 1&quot; causes shingle damage</span>
                </div>
                <div className="flex items-center gap-2 text-xs">
                  <Wind size={12} className="text-muted" />
                  <span className="text-muted">Wind &ge; 65 kts causes structural damage</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Disclaimer */}
      <p className="text-[11px] text-muted leading-relaxed">
        Storm data sourced from NOAA Storm Events Database and SPC Storm Reports (public domain).
        Damage probability is estimated based on proximity, hail size, wind speed, and estimated roof age.
        This assessment is for informational purposes only and does not constitute an insurance claim or damage report.
      </p>
    </div>
  );
}

function SolarTab({ facets, tradeBids }: { facets: RoofFacetData[]; tradeBids: TradeBidData[] }) {
  const solarBid = tradeBids.find(t => t.trade === 'solar');

  if (!solarBid && facets.length === 0) {
    return (
      <Card>
        <CardContent className="py-12 text-center">
          <Sun size={32} className="mx-auto mb-3 text-muted" />
          <p className="text-sm text-muted">No solar data available. Run trade estimation first.</p>
        </CardContent>
      </Card>
    );
  }

  const measurements = solarBid?.measurements || {};

  // Sun hours heatmap per facet
  const maxSunHours = Math.max(...facets.map(f => f.annualSunHours || 0), 1);

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      {/* System Overview */}
      {solarBid && (
        <Card>
          <CardHeader><CardTitle className="text-base">Solar Potential</CardTitle></CardHeader>
          <CardContent className="space-y-0.5">
            <MetricRow label="Usable Roof Area" value={Number(measurements.usable_roof_area_sqft) || 0} unit="sq ft" />
            <MetricRow label="Max Panel Count" value={Number(measurements.max_panel_count) || 0} />
            <MetricRow label="System Size" value={Number(measurements.system_size_kw) || 0} unit="kW" />
            <MetricRow label="Est. Annual Production" value={Number(measurements.estimated_annual_kwh) || 0} unit="kWh" />
            <MetricRow label="Usable Facets" value={`${measurements.usable_facets || 0} / ${measurements.total_facets || 0}`} />
          </CardContent>
        </Card>
      )}

      {/* Facet Sun Analysis */}
      <Card className={!solarBid ? 'md:col-span-2' : ''}>
        <CardHeader><CardTitle className="text-base">Sun Exposure by Facet</CardTitle></CardHeader>
        <CardContent>
          <div className="space-y-2">
            {facets.map(f => {
              const ratio = (f.annualSunHours || 0) / maxSunHours;
              const az = f.azimuthDegrees;
              const direction = az >= 315 || az < 45 ? 'N' : az >= 45 && az < 135 ? 'E' : az >= 135 && az < 225 ? 'S' : 'W';
              const isUsable = az >= 90 && az <= 315 && ratio > 0.5;

              return (
                <div key={f.id} className="space-y-1">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-muted">
                      Facet {f.facetNumber} ({direction}, {f.areaSqft.toLocaleString()} sqft)
                    </span>
                    <span className={cn('font-medium', isUsable ? 'text-emerald-500' : 'text-muted')}>
                      {f.annualSunHours?.toLocaleString() ?? '—'} hrs/yr
                    </span>
                  </div>
                  <div className="h-2 rounded-full bg-main/10 overflow-hidden">
                    <div
                      className={cn('h-full rounded-full transition-all', isUsable ? 'bg-amber-500' : 'bg-gray-400')}
                      style={{ width: `${Math.round(ratio * 100)}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Material list */}
      {solarBid && solarBid.materialList.length > 0 && (
        <Card className="md:col-span-2">
          <CardHeader><CardTitle className="text-base">Solar Material List</CardTitle></CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-main text-left">
                    <th className="pb-2 text-muted font-medium">Item</th>
                    <th className="pb-2 text-muted font-medium text-right">Qty</th>
                    <th className="pb-2 text-muted font-medium">Unit</th>
                  </tr>
                </thead>
                <tbody>
                  {solarBid.materialList.map((mat, i) => (
                    <tr key={i} className="border-b border-main/50">
                      <td className="py-2 text-main">{mat.item}</td>
                      <td className="py-2 text-main text-right">{mat.total_with_waste.toLocaleString()}</td>
                      <td className="py-2 text-muted">{mat.unit}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
