'use client';

import { useState, useCallback, useEffect } from 'react';
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
  ChevronDown,
  MapPin,
  Calendar,
  Database,
  Map,
  PenTool,
  Building,
  ExternalLink,
  FolderOpen,
  Bug,
  Snowflake,
  Mountain,
  TreePine,
  Leaf,
  Gauge,
  History,
  Download,
  type LucideIcon,
} from 'lucide-react';

const MAPBOX_TOKEN = process.env.NEXT_PUBLIC_MAPBOX_TOKEN;
import { Button } from '@/components/ui/button';
import { formatDate, cn } from '@/lib/utils';
import {
  usePropertyScan,
  type PropertyScanData,
  type PropertyFeaturesData,
  type RoofMeasurementData,
  type RoofFacetData,
  type WallMeasurementData,
  type TradeBidData,
  type TradeType,
  type HazardFlagData,
  type StormEventData,
} from '@/lib/hooks/use-property-scan';
import { useStormAssess } from '@/lib/hooks/use-storm-assess';
import { useTranslation } from '@/lib/translations';
import { formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

type TabType = 'property' | 'hazards' | 'environment' | 'roof' | 'walls' | 'trades' | 'solar' | 'storm';

const STATUS_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
  complete: { label: 'Complete', color: '#10B981', bg: 'rgba(16,185,129,0.1)' },
  partial: { label: 'Partial', color: '#F59E0B', bg: 'rgba(245,158,11,0.1)' },
  pending: { label: 'Pending', color: '#3B82F6', bg: 'rgba(59,130,246,0.1)' },
  failed: { label: 'Failed', color: '#EF4444', bg: 'rgba(239,68,68,0.1)' },
  cancelled: { label: 'Cancelled', color: '#6B7280', bg: 'rgba(107,114,128,0.1)' },
};

const TABS: { key: TabType; label: string; icon: LucideIcon; color: string }[] = [
  { key: 'property', label: 'Property', icon: Building, color: '#8B5CF6' },
  { key: 'hazards', label: 'Hazards', icon: ShieldAlert, color: '#EF4444' },
  { key: 'environment', label: 'Environment', icon: Leaf, color: '#10B981' },
  { key: 'roof', label: 'Roof', icon: Home, color: '#A855F7' },
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
  us_census: '#7C3AED',
  nws_alerts: '#F97316',
  open_meteo: '#14B8A6',
  noaa_storm: '#DC2626',
  nlcd_canopy: '#22C55E',
  epa_radon: '#A855F7',
  asce7: '#78716C',
  iecc: '#0EA5E9',
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
  us_census: 'US Census',
  nws_alerts: 'NWS Weather',
  open_meteo: 'Open-Meteo Weather',
  noaa_storm: 'NOAA Storm Events',
  nlcd_canopy: 'NLCD Tree Canopy',
  epa_radon: 'EPA Radon',
  asce7: 'ASCE 7 Standards',
  iecc: 'IECC Climate Data',
};

const EXTERNAL_LINK_LABELS: Record<string, { label: string; color: string }> = {
  zillow: { label: 'Zillow', color: '#006AFF' },
  redfin: { label: 'Redfin', color: '#A02021' },
  realtor: { label: 'Realtor.com', color: '#D92228' },
  trulia: { label: 'Trulia', color: '#3BB87C' },
  google_maps: { label: 'Google Maps', color: '#4285F4' },
  fema_flood_map: { label: 'FEMA Flood Map', color: '#0EA5E9' },
  county_assessor: { label: 'County Assessor', color: '#8B5CF6' },
  building_department: { label: 'Building Dept', color: '#D97706' },
  permit_history: { label: 'Permit History', color: '#7C3AED' },
  utility_lookup: { label: 'Utility Lookup', color: '#14B8A6' },
};

const HAZARD_SEVERITY_CONFIG: Record<string, { label: string; color: string; bg: string; icon: LucideIcon }> = {
  red: { label: 'High Risk', color: '#EF4444', bg: 'rgba(239,68,68,0.08)', icon: AlertTriangle },
  yellow: { label: 'Caution', color: '#F59E0B', bg: 'rgba(245,158,11,0.08)', icon: ShieldAlert },
  green: { label: 'Low Risk', color: '#10B981', bg: 'rgba(16,185,129,0.08)', icon: Shield },
};

const HAZARD_TYPE_ICONS: Record<string, LucideIcon> = {
  lead_paint: AlertTriangle,
  asbestos: AlertTriangle,
  radon: Mountain,
  flood: Droplet,
  wildfire: Flame,
  seismic: Activity,
  problem_panels: Zap,
  termite: Bug,
  galvanized_pipe: Droplet,
  knob_and_tube: Zap,
  chinese_drywall: Home,
  polybutylene_pipe: Droplet,
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
  const { t } = useTranslation();
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
        <p className="text-[10px] text-muted">{t('common.confidence')}</p>
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
  const { t, formatDate } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const scanId = params.id as string;
  const [activeTab, setActiveTab] = useState<TabType>('property');
  const [selectedTrade, setSelectedTrade] = useState<TradeType | null>(null);
  const [estimating, setEstimating] = useState(false);
  const [imgView, setImgView] = useState<'satellite' | 'streets' | 'streetview'>('satellite');

  const [pdfGenerating, setPdfGenerating] = useState(false);

  const { scan, features, roof, facets, walls, tradeBids, loading, error, triggerTradeEstimate } = usePropertyScan(scanId, 'scan');

  const handlePdfExport = useCallback(async () => {
    if (!scan) return;
    setPdfGenerating(true);
    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) return;

      // Build PDF content as structured HTML for print
      const printWindow = window.open('', '_blank');
      if (!printWindow) return;

      const hazards = scan.hazardFlags || [];
      const redCount = hazards.filter((h: HazardFlagData) => h.severity === 'red').length;
      const yellowCount = hazards.filter((h: HazardFlagData) => h.severity === 'yellow').length;
      const env = scan.environmentalData || {};
      const code = scan.codeRequirements || {};
      const weather = scan.weatherHistory || {};
      const measurements = scan.computedMeasurements || {};

      printWindow.document.write(`<!DOCTYPE html>
<html><head><title>Property Intelligence Report — ${scan.address}</title>
<style>
  body { font-family: 'Inter', -apple-system, sans-serif; color: #1a1a1a; max-width: 800px; margin: 0 auto; padding: 40px 30px; font-size: 12px; line-height: 1.5; }
  h1 { font-size: 20px; margin: 0 0 4px; } h2 { font-size: 14px; margin: 24px 0 8px; border-bottom: 1px solid #e5e5e5; padding-bottom: 4px; }
  .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #1a1a1a; padding-bottom: 12px; margin-bottom: 20px; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 4px 24px; } .grid3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 4px 24px; }
  .row { display: flex; justify-content: space-between; padding: 3px 0; border-bottom: 1px solid #f5f5f5; }
  .label { color: #666; } .value { font-weight: 600; }
  .badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 10px; font-weight: 600; }
  .red { background: #fee2e2; color: #dc2626; } .yellow { background: #fef3c7; color: #d97706; } .green { background: #dcfce7; color: #16a34a; }
  .hazard { padding: 8px 12px; margin: 4px 0; border-radius: 6px; border-left: 3px solid; }
  .hazard.severity-red { border-color: #dc2626; background: #fef2f2; } .hazard.severity-yellow { border-color: #d97706; background: #fffbeb; }
  .footer { margin-top: 40px; padding-top: 12px; border-top: 1px solid #e5e5e5; color: #999; font-size: 10px; text-align: center; }
  @media print { body { padding: 20px; } }
</style></head><body>
<div class="header">
  <div><h1>Property Intelligence Report</h1><div style="color:#666">${scan.address}</div>
    <div style="color:#999;font-size:10px">${[scan.city, scan.state, scan.zip].filter(Boolean).join(', ')}</div></div>
  <div style="text-align:right"><div style="font-size:10px;color:#666">Scan Date</div>
    <div style="font-weight:600">${new Date(scan.createdAt).toLocaleDateString()}</div>
    <div style="font-size:10px;color:#666;margin-top:4px">Confidence: <span style="font-weight:700">${scan.confidenceScore}%</span></div></div>
</div>

${features ? `<h2>Property Details</h2><div class="grid">
  ${features.yearBuilt ? `<div class="row"><span class="label">Year Built</span><span class="value">${features.yearBuilt}</span></div>` : ''}
  ${features.livingSqft ? `<div class="row"><span class="label">Living Area</span><span class="value">${features.livingSqft.toLocaleString()} sqft</span></div>` : ''}
  ${features.lotSqft ? `<div class="row"><span class="label">Lot Size</span><span class="value">${features.lotSqft.toLocaleString()} sqft</span></div>` : ''}
  ${features.stories ? `<div class="row"><span class="label">Stories</span><span class="value">${features.stories}</span></div>` : ''}
  ${features.beds ? `<div class="row"><span class="label">Bedrooms</span><span class="value">${features.beds}</span></div>` : ''}
  ${features.bathsFull || features.bathsHalf ? `<div class="row"><span class="label">Bathrooms</span><span class="value">${(features.bathsFull || 0) + (features.bathsHalf || 0) * 0.5}</span></div>` : ''}
  ${features.constructionType ? `<div class="row"><span class="label">Construction</span><span class="value">${features.constructionType}</span></div>` : ''}
  ${features.roofMaterial ? `<div class="row"><span class="label">Roof Material</span><span class="value">${features.roofMaterial}</span></div>` : ''}
  ${features.foundationType ? `<div class="row"><span class="label">Foundation</span><span class="value">${features.foundationType}</span></div>` : ''}
  ${features.heatingType ? `<div class="row"><span class="label">Heating</span><span class="value">${features.heatingType}</span></div>` : ''}
  ${features.coolingType ? `<div class="row"><span class="label">Cooling</span><span class="value">${features.coolingType}</span></div>` : ''}
</div>` : ''}

${roof ? `<h2>Roof Measurements</h2><div class="grid">
  <div class="row"><span class="label">Total Area</span><span class="value">${roof.totalAreaSqft.toLocaleString()} sqft (${roof.totalAreaSquares.toFixed(1)} squares)</span></div>
  ${roof.pitchPrimary ? `<div class="row"><span class="label">Primary Pitch</span><span class="value">${roof.pitchPrimary}</span></div>` : ''}
  <div class="row"><span class="label">Facets</span><span class="value">${roof.facetCount}</span></div>
  <div class="row"><span class="label">Ridge</span><span class="value">${roof.ridgeLengthFt.toLocaleString()} ft</span></div>
  <div class="row"><span class="label">Eave</span><span class="value">${roof.eaveLengthFt.toLocaleString()} ft</span></div>
  <div class="row"><span class="label">Valley</span><span class="value">${roof.valleyLengthFt.toLocaleString()} ft</span></div>
</div>` : ''}

${hazards.length > 0 ? `<h2>Hazard Flags (${redCount} High Risk, ${yellowCount} Caution)</h2>
${hazards.map((h: HazardFlagData) => `<div class="hazard severity-${h.severity}">
  <div style="font-weight:600">${h.title} <span class="badge ${h.severity}">${h.severity === 'red' ? 'HIGH RISK' : h.severity === 'yellow' ? 'CAUTION' : 'LOW RISK'}</span></div>
  <div style="margin-top:2px">${h.description}</div>
  ${h.what_to_do ? `<div style="margin-top:4px;color:#666"><strong>Action:</strong> ${h.what_to_do}</div>` : ''}
  ${h.cost_implications ? `<div style="color:#666"><strong>Cost Impact:</strong> ${h.cost_implications}</div>` : ''}
</div>`).join('')}` : ''}

${Object.keys(env).length > 0 || features?.climateZone ? `<h2>Environmental Data</h2><div class="grid">
  ${features?.climateZone || env.climate_zone ? `<div class="row"><span class="label">Climate Zone</span><span class="value">${features?.climateZone || env.climate_zone}</span></div>` : ''}
  ${features?.frostLineDepthIn || env.frost_line_depth_in ? `<div class="row"><span class="label">Frost Line</span><span class="value">${features?.frostLineDepthIn || env.frost_line_depth_in}" deep</span></div>` : ''}
  ${features?.soilType || env.soil_type ? `<div class="row"><span class="label">Soil Type</span><span class="value">${features?.soilType || env.soil_type}</span></div>` : ''}
  ${features?.radonZone ? `<div class="row"><span class="label">Radon Zone</span><span class="value">Zone ${features.radonZone}</span></div>` : ''}
  ${features?.wildfireRisk ? `<div class="row"><span class="label">Wildfire Risk</span><span class="value">${String(features.wildfireRisk).replace(/_/g, ' ')}</span></div>` : ''}
  ${features?.termiteZone ? `<div class="row"><span class="label">Termite Zone</span><span class="value">${String(features.termiteZone).replace(/_/g, ' ')}</span></div>` : ''}
</div>` : ''}

${Object.keys(code).length > 0 ? `<h2>Building Code Requirements</h2><div class="grid">
  ${code.wind_speed_mph ? `<div class="row"><span class="label">Design Wind Speed</span><span class="value">${code.wind_speed_mph} mph</span></div>` : ''}
  ${code.snow_load_psf ? `<div class="row"><span class="label">Snow Load</span><span class="value">${code.snow_load_psf} PSF</span></div>` : ''}
  ${code.seismic_category ? `<div class="row"><span class="label">Seismic Category</span><span class="value">${code.seismic_category}</span></div>` : ''}
  ${code.energy_code ? `<div class="row"><span class="label">Energy Code</span><span class="value">${code.energy_code}</span></div>` : ''}
</div>` : ''}

${Object.keys(weather).length > 0 ? `<h2>Weather History</h2><div class="grid">
  ${weather.freeze_thaw_cycles ? `<div class="row"><span class="label">Freeze-Thaw Cycles</span><span class="value">${weather.freeze_thaw_cycles}/yr</span></div>` : ''}
  ${weather.annual_precip_in ? `<div class="row"><span class="label">Annual Precip</span><span class="value">${weather.annual_precip_in}"</span></div>` : ''}
  ${weather.temp_min_f != null && weather.temp_max_f != null ? `<div class="row"><span class="label">Temp Range</span><span class="value">${weather.temp_min_f}°F to ${weather.temp_max_f}°F</span></div>` : ''}
  ${weather.avg_wind_mph ? `<div class="row"><span class="label">Avg Wind</span><span class="value">${weather.avg_wind_mph} mph</span></div>` : ''}
</div>` : ''}

<div class="footer">
  Generated by Zafto Property Intelligence &bull; ${new Date().toLocaleDateString()} &bull; ${scan.scanSources.length} data sources &bull; ${scan.confidenceScore}% confidence
</div>
</body></html>`);
      printWindow.document.close();
      printWindow.focus();
      setTimeout(() => printWindow.print(), 500);
    } finally {
      setPdfGenerating(false);
    }
  }, [scan, features, roof]);

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
        <p className="text-sm text-muted font-medium">{t('recon.analyzingPropertyIntelligence')}</p>
        <p className="text-[10px] text-muted/60">{t('recon.satelliteImageryRoofData')}</p>
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

  const bathsTotal = (features?.bathsFull || 0) + (features?.bathsHalf || 0) * 0.5;
  const quickStats = [
    { label: 'Beds', value: features?.beds != null ? String(features.beds) : '—', icon: Home, color: '#8B5CF6' },
    { label: 'Baths', value: bathsTotal > 0 ? String(bathsTotal) : '—', icon: Droplet, color: '#3B82F6' },
    { label: 'Sqft', value: features?.livingSqft ? `{formatCurrency(features.livingSqft)}` : '—', icon: Ruler, color: '#10B981' },
    { label: 'Year Built', value: features?.yearBuilt ? String(features.yearBuilt) : '—', icon: Calendar, color: '#F59E0B' },
    { label: 'Roof Area', value: roof ? `{formatCurrency(roof.totalAreaSqft)} sqft` : '—', icon: Layers, color: '#A855F7' },
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
          <Link href="/dashboard/recon" className="hover:text-main transition-colors">{t('recon.title')}</Link>
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
              <p className="text-[9px] font-semibold text-muted uppercase tracking-wider mb-1.5">{t('common.dataSources')}</p>
              <div className="flex flex-wrap gap-1">
                {scan.scanSources.map(src => (
                  <span key={src} className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-surface border border-main/50 text-[10px] font-medium text-muted">
                    <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: SOURCE_COLORS[src] || '#6B7280' }} />
                    {SOURCE_LABELS[src] || src.replace(/_/g, ' ')}
                  </span>
                ))}
                {scan.scanSources.length === 0 && (
                  <span className="text-[10px] text-muted/50">{t('recon.noSources')}</span>
                )}
              </div>
            </div>

            {/* Flood zone badge */}
            {scan.floodZone && (() => {
              const fc = FLOOD_RISK_CONFIG[scan.floodRisk || 'low'] || FLOOD_RISK_CONFIG.low;
              return (
                <div className="mb-4">
                  <p className="text-[9px] font-semibold text-muted uppercase tracking-wider mb-1.5">{t('common.floodZone')}</p>
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
                onClick={() => router.push(`/dashboard/sketch-engine?scan_id=${scan.id}`)}
                className="gap-1.5"
              >
                <PenTool size={13} /> Sketch
              </Button>
              <Button
                variant="secondary"
                size="sm"
                onClick={handlePdfExport}
                disabled={pdfGenerating}
                className="gap-1.5"
              >
                {pdfGenerating ? <Loader2 size={13} className="animate-spin" /> : <Download size={13} />}
                PDF
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

      {/* ── NO WASTED TRIP SUMMARY ───────────────────── */}
      <NoWastedTripSummary scan={scan} features={features} />

      {/* ── EXTERNAL LINKS + STORAGE ───────────────────── */}
      {Object.keys(scan.externalLinks).length > 0 && (
        <div className="rounded-xl bg-card border border-main p-4">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <ExternalLink size={13} className="text-accent" />
              <h3 className="text-[13px] font-semibold text-main">{t('recon.propertyResearchLinks')}</h3>
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
      {activeTab === 'property' && <PropertyTab features={features} scan={scan} />}
      {activeTab === 'hazards' && <HazardsTab scan={scan} />}
      {activeTab === 'environment' && <EnvironmentTab scan={scan} features={features} />}
      {activeTab === 'roof' && <RoofTab roof={roof} facets={facets} scan={scan} />}
      {activeTab === 'walls' && <WallsTab walls={walls} onEstimate={handleEstimate} estimating={estimating} />}
      {activeTab === 'trades' && (
        <TradesTab tradeBids={tradeBids} selectedTrade={selectedTrade}
          onSelectTrade={setSelectedTrade} onEstimate={handleEstimate} estimating={estimating}
          scan={scan} features={features} />
      )}
      {activeTab === 'solar' && <SolarTab facets={facets} tradeBids={tradeBids} />}
      {activeTab === 'storm' && <StormTab scanId={scan.id} scanState={scan.state} />}

      {/* ── SCAN HISTORY ──────────────────────────────── */}
      <ScanHistory address={scan.address} currentScanId={scan.id} />

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
// NO WASTED TRIP SUMMARY
// ============================================================================

function NoWastedTripSummary({ scan, features }: {
  scan: PropertyScanData; features: PropertyFeaturesData | null;
}) {
  const hazards = scan.hazardFlags || [];
  const redCount = hazards.filter(h => h.severity === 'red').length;
  const yellowCount = hazards.filter(h => h.severity === 'yellow').length;
  const greenCount = hazards.filter(h => h.severity === 'green').length;
  const propertyAge = features?.yearBuilt ? new Date().getFullYear() - features.yearBuilt : null;
  const measurements = (scan.computedMeasurements || {}) as Record<string, number>;
  const weather = (scan.weatherHistory || {}) as Record<string, number>;

  return (
    <div className="rounded-xl bg-card border border-main overflow-hidden">
      <div className="px-4 py-2.5 border-b border-main flex items-center gap-2.5 bg-gradient-to-r from-accent/5 to-transparent">
        <ShieldAlert size={14} className="text-accent" />
        <h3 className="text-[13px] font-semibold text-main flex-1">Pre-Visit Briefing</h3>
        <span className="text-[10px] text-muted">Decide in 10 seconds if this job is worth the drive</span>
      </div>
      <div className="p-4">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-4">
          {/* Property basics */}
          <div className="flex items-center gap-3 px-3 py-2.5 rounded-lg bg-surface">
            <Home size={16} className="text-[#8B5CF6] shrink-0" />
            <div className="min-w-0">
              <p className="text-[9px] text-muted uppercase tracking-wider">Property</p>
              <p className="text-xs font-semibold text-main truncate">
                {features?.livingSqft ? `${features.livingSqft.toLocaleString()} sqft` : '—'}
                {features?.stories ? ` / ${features.stories} story` : ''}
              </p>
            </div>
          </div>

          {/* Age */}
          <div className="flex items-center gap-3 px-3 py-2.5 rounded-lg bg-surface">
            <Calendar size={16} className="text-[#F59E0B] shrink-0" />
            <div className="min-w-0">
              <p className="text-[9px] text-muted uppercase tracking-wider">Age</p>
              <p className="text-xs font-semibold text-main">
                {propertyAge != null ? `${propertyAge} years` : '—'}
                {features?.yearBuilt ? ` (${features.yearBuilt})` : ''}
              </p>
            </div>
          </div>

          {/* Flood zone */}
          <div className="flex items-center gap-3 px-3 py-2.5 rounded-lg bg-surface">
            <Droplet size={16} className="text-[#3B82F6] shrink-0" />
            <div className="min-w-0">
              <p className="text-[9px] text-muted uppercase tracking-wider">Flood Zone</p>
              <p className="text-xs font-semibold text-main">
                {scan.floodZone ? `Zone ${scan.floodZone}` : 'None identified'}
              </p>
            </div>
          </div>

          {/* Last sale */}
          <div className="flex items-center gap-3 px-3 py-2.5 rounded-lg bg-surface">
            <TrendingUp size={16} className="text-[#10B981] shrink-0" />
            <div className="min-w-0">
              <p className="text-[9px] text-muted uppercase tracking-wider">Last Sale</p>
              <p className="text-xs font-semibold text-main">
                {features?.lastSalePrice ? `$${features.lastSalePrice.toLocaleString()}` : '—'}
              </p>
            </div>
          </div>
        </div>

        {/* Hazard flags summary */}
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-[10px] font-semibold text-muted uppercase tracking-wider mr-1">Hazards:</span>
          {hazards.length === 0 ? (
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-semibold bg-emerald-500/10 text-emerald-500">
              <Shield size={10} /> No hazards detected
            </span>
          ) : (
            <>
              {redCount > 0 && (
                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-semibold bg-red-500/10 text-red-400">
                  <AlertTriangle size={10} /> {redCount} high risk
                </span>
              )}
              {yellowCount > 0 && (
                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-semibold bg-amber-500/10 text-amber-500">
                  <ShieldAlert size={10} /> {yellowCount} caution
                </span>
              )}
              {greenCount > 0 && (
                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-semibold bg-emerald-500/10 text-emerald-500">
                  <Shield size={10} /> {greenCount} low risk
                </span>
              )}
            </>
          )}

          {/* Key measurements chips */}
          {measurements.lawn_area_sqft != null && measurements.lawn_area_sqft > 0 && (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-surface border border-main/50 text-[10px] text-muted">
              Yard: {Math.round(measurements.lawn_area_sqft).toLocaleString()} sqft
            </span>
          )}
          {measurements.boundary_perimeter_ft != null && measurements.boundary_perimeter_ft > 0 && (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-surface border border-main/50 text-[10px] text-muted">
              Boundary: {Math.round(measurements.boundary_perimeter_ft).toLocaleString()} LF
            </span>
          )}
          {weather.freeze_thaw_cycles != null && (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-surface border border-main/50 text-[10px] text-muted">
              <Snowflake size={9} /> {weather.freeze_thaw_cycles} freeze-thaw cycles/yr
            </span>
          )}
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// HAZARDS TAB
// ============================================================================

function HazardsTab({ scan }: { scan: PropertyScanData }) {
  const [expanded, setExpanded] = useState<string | null>(null);
  const hazards = scan.hazardFlags || [];

  if (hazards.length === 0) {
    return (
      <EmptyTab icon={Shield} title="No Hazards Detected"
        description="No environmental or structural hazards were identified for this property based on available data sources including EPA radon zones, FEMA flood maps, wildfire risk assessments, and historical property records." />
    );
  }

  // Sort: red first, then yellow, then green
  const severityOrder: Record<string, number> = { red: 0, yellow: 1, green: 2 };
  const sorted = [...hazards].sort((a, b) => (severityOrder[a.severity] ?? 9) - (severityOrder[b.severity] ?? 9));

  const redCount = hazards.filter(h => h.severity === 'red').length;
  const yellowCount = hazards.filter(h => h.severity === 'yellow').length;
  const greenCount = hazards.filter(h => h.severity === 'green').length;

  return (
    <div className="space-y-4">
      {/* Summary strip */}
      <KpiStrip items={[
        { label: 'Total Hazards', value: hazards.length, icon: ShieldAlert, color: '#8B5CF6' },
        { label: 'High Risk', value: redCount, icon: AlertTriangle, color: '#EF4444' },
        { label: 'Caution', value: yellowCount, icon: ShieldAlert, color: '#F59E0B' },
        { label: 'Low Risk', value: greenCount, icon: Shield, color: '#10B981' },
      ]} />

      {/* Hazard cards */}
      <div className="space-y-2">
        {sorted.map((hazard, i) => {
          const config = HAZARD_SEVERITY_CONFIG[hazard.severity] || HAZARD_SEVERITY_CONFIG.yellow;
          const HazardIcon = HAZARD_TYPE_ICONS[hazard.type] || config.icon;
          const isExpanded = expanded === `${hazard.type}-${i}`;

          return (
            <div key={`${hazard.type}-${i}`}
              className="rounded-xl border overflow-hidden transition-all"
              style={{ borderColor: `${config.color}30`, backgroundColor: config.bg }}>
              <button
                onClick={() => setExpanded(isExpanded ? null : `${hazard.type}-${i}`)}
                className="w-full px-4 py-3 flex items-center gap-3 text-left">
                <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
                  style={{ backgroundColor: `${config.color}20` }}>
                  <HazardIcon size={16} style={{ color: config.color }} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h4 className="text-sm font-semibold text-main">{hazard.title}</h4>
                    <span className="px-2 py-0.5 rounded text-[10px] font-semibold"
                      style={{ color: config.color, backgroundColor: `${config.color}15` }}>
                      {config.label}
                    </span>
                  </div>
                  <p className="text-xs text-muted mt-0.5 line-clamp-1">{hazard.description}</p>
                </div>
                <ChevronDown size={16} className={cn('text-muted transition-transform shrink-0', isExpanded && 'rotate-180')} />
              </button>

              {isExpanded && (
                <div className="px-4 pb-4 border-t space-y-3" style={{ borderColor: `${config.color}20` }}>
                  <div className="pt-3">
                    <p className="text-xs text-main leading-relaxed">{hazard.description}</p>
                  </div>
                  {hazard.what_to_do && (
                    <div>
                      <p className="text-[10px] font-semibold text-muted uppercase tracking-wider mb-1">What To Do</p>
                      <p className="text-xs text-main leading-relaxed">{hazard.what_to_do}</p>
                    </div>
                  )}
                  {hazard.cost_implications && (
                    <div>
                      <p className="text-[10px] font-semibold text-muted uppercase tracking-wider mb-1">Cost Implications</p>
                      <p className="text-xs text-main leading-relaxed">{hazard.cost_implications}</p>
                    </div>
                  )}
                  {hazard.regulatory && (
                    <div>
                      <p className="text-[10px] font-semibold text-muted uppercase tracking-wider mb-1">Regulatory</p>
                      <p className="text-xs text-main leading-relaxed">{hazard.regulatory}</p>
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ============================================================================
// ENVIRONMENT TAB (Environmental + Code Requirements + Weather + Measurements)
// ============================================================================

function EnvironmentTab({ scan, features }: {
  scan: PropertyScanData; features: PropertyFeaturesData | null;
}) {
  const env = (scan.environmentalData || {}) as Record<string, unknown>;
  const code = (scan.codeRequirements || {}) as Record<string, unknown>;
  const weather = (scan.weatherHistory || {}) as Record<string, unknown>;
  const measurements = (scan.computedMeasurements || {}) as Record<string, unknown>;
  const stormEvents = scan.noaaStormEvents || [];

  const hasEnv = Object.keys(env).length > 0 || features?.climateZone || features?.radonZone;
  const hasCode = Object.keys(code).length > 0;
  const hasWeather = Object.keys(weather).length > 0;
  const hasMeasurements = Object.keys(measurements).length > 0;
  const hasAny = hasEnv || hasCode || hasWeather || hasMeasurements || stormEvents.length > 0;

  if (!hasAny) {
    return (
      <EmptyTab icon={Leaf} title="Environmental Data Pending"
        description="Environmental analysis, building code requirements, weather history, and computed measurements will appear here after a complete property scan. This data is derived from IECC climate zones, EPA radon maps, ASCE 7 standards, Open-Meteo weather, and NOAA storm databases." />
    );
  }

  return (
    <div className="space-y-4">
      {/* Environmental Panel */}
      {hasEnv && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <Panel title="Climate & Environment" icon={Leaf} color="#10B981">
            <div className="space-y-0">
              {!!(features?.climateZone || env.climate_zone) && (
                <DataRow label="IECC Climate Zone" value={String(features?.climateZone || env.climate_zone)} highlight />
              )}
              {(features?.frostLineDepthIn != null || env.frost_line_depth_in != null) && (
                <DataRow label="Frost Line Depth" value={`${features?.frostLineDepthIn ?? env.frost_line_depth_in}"`} mono />
              )}
              {!!(features?.soilType || env.soil_type) && (
                <DataRow label="Soil Type" value={formatLabel(String(features?.soilType || env.soil_type))} />
              )}
              {!!(features?.soilDrainage || env.soil_drainage) && (
                <DataRow label="Soil Drainage" value={formatLabel(String(features?.soilDrainage || env.soil_drainage))} />
              )}
              {!!features?.soilBearingCapacity && (
                <DataRow label="Bearing Capacity" value={formatLabel(features.soilBearingCapacity)} />
              )}
              {(features?.treeCanopyPct != null || env.tree_canopy_pct != null) && (
                <DataRow label="Tree Canopy Coverage" value={`${Number(features?.treeCanopyPct ?? env.tree_canopy_pct).toFixed(1)}%`} />
              )}
            </div>
          </Panel>

          <Panel title="Hazard Zones" icon={ShieldAlert} color="#EF4444">
            <div className="space-y-0">
              {(features?.radonZone != null || env.radon_zone != null) && (() => {
                const zone = features?.radonZone ?? Number(env.radon_zone);
                const radonLabel = zone === 1 ? 'Zone 1 (High)' : zone === 2 ? 'Zone 2 (Moderate)' : 'Zone 3 (Low)';
                const isHigh = zone === 1;
                return <DataRow label="EPA Radon Zone" value={radonLabel} highlight={isHigh} />;
              })()}
              {!!(features?.wildfireRisk || env.wildfire_risk) && (
                <DataRow label="Wildfire Risk" value={formatLabel(String(features?.wildfireRisk || env.wildfire_risk))}
                  highlight={['very_high', 'high'].includes(String(features?.wildfireRisk || env.wildfire_risk))} />
              )}
              {!!(features?.termiteZone || env.termite_zone) && (
                <DataRow label="Termite Zone" value={formatLabel(String(features?.termiteZone || env.termite_zone))}
                  highlight={['very_heavy', 'moderate_to_heavy'].includes(String(features?.termiteZone || env.termite_zone))} />
              )}
              {scan.floodZone && (
                <DataRow label="FEMA Flood Zone" value={`Zone ${scan.floodZone}`} highlight />
              )}
              {!!(features?.seismicCategory || env.seismic_category) && (
                <DataRow label="Seismic Category" value={String(features?.seismicCategory || env.seismic_category)}
                  highlight={['D0', 'D1', 'D2', 'E', 'F'].includes(String(features?.seismicCategory || env.seismic_category))} />
              )}
            </div>
          </Panel>
        </div>
      )}

      {/* Code Requirements Panel */}
      {hasCode && (
        <Panel title="Building Code Requirements" icon={FileText} color="#3B82F6">
          <div className="grid grid-cols-2 lg:grid-cols-3 gap-x-6 gap-y-0">
            {code.wind_speed_mph != null && (
              <DataRow label="Design Wind Speed" value={`${code.wind_speed_mph} mph`} mono />
            )}
            {code.snow_load_psf != null && (
              <DataRow label="Ground Snow Load" value={`${code.snow_load_psf} PSF`} mono />
            )}
            {!!code.seismic_category && (
              <DataRow label="Seismic Design Category" value={String(code.seismic_category)} highlight={['D0', 'D1', 'D2', 'E', 'F'].includes(String(code.seismic_category))} />
            )}
            {!!code.energy_code && (
              <DataRow label="Energy Code" value={String(code.energy_code)} />
            )}
            {code.frost_line_depth_in != null && (
              <DataRow label="Min. Footing Depth" value={`${code.frost_line_depth_in}"`} mono />
            )}
            {!!code.insulation_r_values && (() => {
              const rVals = code.insulation_r_values as Record<string, number>;
              return (
                <>
                  {rVals.attic && <DataRow label="R-Value: Attic" value={`R-${rVals.attic}`} mono />}
                  {rVals.wall && <DataRow label="R-Value: Wall" value={`R-${rVals.wall}`} mono />}
                  {rVals.floor && <DataRow label="R-Value: Floor" value={`R-${rVals.floor}`} mono />}
                  {rVals.basement && <DataRow label="R-Value: Basement" value={`R-${rVals.basement}`} mono />}
                  {rVals.crawlspace && <DataRow label="R-Value: Crawlspace" value={`R-${rVals.crawlspace}`} mono />}
                </>
              );
            })()}
          </div>
        </Panel>
      )}

      {/* Weather History Panel */}
      {hasWeather && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <Panel title="Weather History (2yr)" icon={Thermometer} color="#06B6D4">
            <div className="space-y-0">
              {weather.freeze_thaw_cycles != null && (
                <DataRow label="Freeze-Thaw Cycles" value={`${weather.freeze_thaw_cycles}/yr`} mono
                  highlight={Number(weather.freeze_thaw_cycles) > 40} />
              )}
              {weather.annual_precip_in != null && (
                <DataRow label="Annual Precipitation" value={`${Number(weather.annual_precip_in).toFixed(1)}"`} mono />
              )}
              {weather.temp_min_f != null && weather.temp_max_f != null && (
                <DataRow label="Temperature Range" value={`${weather.temp_min_f}°F to ${weather.temp_max_f}°F`} mono />
              )}
              {weather.avg_wind_mph != null && (
                <DataRow label="Avg Wind Speed" value={`${Number(weather.avg_wind_mph).toFixed(1)} mph`} mono />
              )}
              {weather.hail_events != null && (
                <DataRow label="Hail Events" value={String(weather.hail_events)}
                  highlight={Number(weather.hail_events) > 0} />
              )}
              {weather.wind_events != null && (
                <DataRow label="Severe Wind Events" value={String(weather.wind_events)}
                  highlight={Number(weather.wind_events) > 0} />
              )}
            </div>
          </Panel>

          {/* Measurements Panel */}
          {hasMeasurements && (
            <Panel title="Computed Measurements" icon={Ruler} color="#8B5CF6">
              <div className="space-y-0">
                {measurements.lawn_area_sqft != null && (
                  <DataRow label="Lawn/Yard Area" value={Math.round(Number(measurements.lawn_area_sqft)).toLocaleString()} unit="sqft" mono />
                )}
                {measurements.wall_area_sqft != null && (
                  <DataRow label="Wall Area (est)" value={Math.round(Number(measurements.wall_area_sqft)).toLocaleString()} unit="sqft" mono />
                )}
                {measurements.roof_complexity_factor != null && (
                  <DataRow label="Roof Complexity" value={`${Number(measurements.roof_complexity_factor).toFixed(2)}x`} mono
                    highlight={Number(measurements.roof_complexity_factor) >= 1.5} />
                )}
                {measurements.boundary_perimeter_ft != null && (
                  <DataRow label="Property Boundary" value={Math.round(Number(measurements.boundary_perimeter_ft)).toLocaleString()} unit="LF" mono />
                )}
                {measurements.driveway_area_sqft != null && (
                  <DataRow label="Driveway Area (est)" value={Math.round(Number(measurements.driveway_area_sqft)).toLocaleString()} unit="sqft" mono />
                )}
              </div>
            </Panel>
          )}
        </div>
      )}

      {/* NOAA Storm Events Timeline */}
      {stormEvents.length > 0 && (
        <Panel title={`NOAA Storm Events (${stormEvents.length})`} icon={CloudLightning} color="#DC2626" noPad>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">Date</th>
                  <th className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">Event Type</th>
                  <th className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">Magnitude</th>
                  <th className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">Description</th>
                </tr>
              </thead>
              <tbody>
                {stormEvents.map((event, i) => (
                  <tr key={i} className="border-b border-main/30 hover:bg-surface/40 transition-colors">
                    <td className="px-4 py-2.5 text-main text-xs font-mono whitespace-nowrap">{event.date}</td>
                    <td className="px-4 py-2.5">
                      <span className={cn('inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-[11px] font-medium',
                        event.event_type.toLowerCase().includes('hail') ? 'bg-blue-500/10 text-blue-400' :
                        event.event_type.toLowerCase().includes('wind') ? 'bg-amber-500/10 text-amber-500' :
                        event.event_type.toLowerCase().includes('tornado') ? 'bg-red-500/10 text-red-400' :
                        'bg-surface text-muted'
                      )}>
                        {event.event_type.toLowerCase().includes('hail') ? <CircleDot size={10} /> :
                         event.event_type.toLowerCase().includes('wind') ? <Wind size={10} /> :
                         <CloudLightning size={10} />}
                        {event.event_type}
                      </span>
                    </td>
                    <td className="px-4 py-2.5 text-main font-mono text-xs">{event.magnitude || '—'}</td>
                    <td className="px-4 py-2.5 text-muted text-xs max-w-xs truncate">{event.description || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Panel>
      )}

      {/* Data source footer */}
      <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-surface border border-main/50">
        <Database size={11} className="text-muted shrink-0" />
        <span className="text-[10px] text-muted">Environmental data from:</span>
        {['open_meteo', 'noaa_storm', 'nlcd_canopy', 'epa_radon', 'asce7', 'iecc'].map(src => (
          scan.scanSources.includes(src) && (
            <span key={src} className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-card text-[10px] font-medium text-muted">
              <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: SOURCE_COLORS[src] || '#6B7280' }} />
              {SOURCE_LABELS[src] || src}
            </span>
          )
        ))}
      </div>
    </div>
  );
}

// ============================================================================
// PROPERTY TAB
// ============================================================================

function formatCurrency(val: number | null): string {
  if (val == null) return '—';
  return `${formatCurrency(val)}`;
}

function formatLabel(val: string | null): string {
  if (!val) return '—';
  return val.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

function PropertyTab({ features, scan }: {
  features: PropertyFeaturesData | null; scan: PropertyScanData;
}) {
  const { t } = useTranslation();
  if (!features) {
    return (
      <EmptyTab
        icon={Building}
        title="Property Details Pending"
        description="Property characteristics were not found for this address. This typically means the ATTOM property data API did not return results for this location. Public record data may not be available for newer construction or certain rural areas."
      />
    );
  }

  const bathsTotal = (features.bathsFull || 0) + (features.bathsHalf || 0) * 0.5;
  const propertyAge = features.yearBuilt ? new Date().getFullYear() - features.yearBuilt : null;

  // Census data extraction
  const census = features.censusData || {};
  const population = census.population as number | undefined;
  const medianIncome = census.median_household_income as number | undefined;
  const medianHomeValue = census.median_home_value as number | undefined;
  const ownerOccupied = census.owner_occupied_pct as number | undefined;
  const vacancyRate = census.vacancy_rate as number | undefined;

  return (
    <div className="space-y-4">
      {/* Property KPI strip */}
      <KpiStrip items={[
        { label: 'Living Area', value: features.livingSqft ? features.livingSqft.toLocaleString() : '—', unit: 'sqft', icon: Ruler, color: '#8B5CF6' },
        { label: 'Lot Size', value: features.lotSqft ? features.lotSqft.toLocaleString() : '—', unit: 'sqft', icon: Map, color: '#3B82F6' },
        { label: 'Bedrooms', value: features.beds != null ? String(features.beds) : '—', icon: Home, color: '#10B981' },
        { label: 'Bathrooms', value: bathsTotal > 0 ? String(bathsTotal) : '—', icon: Droplet, color: '#06B6D4' },
        { label: 'Year Built', value: features.yearBuilt ? String(features.yearBuilt) : '—', unit: propertyAge != null ? `(${propertyAge}yr)` : undefined, icon: Calendar, color: '#F59E0B' },
        { label: 'Assessed Value', value: formatCurrency(features.assessedValue), icon: TrendingUp, color: '#EC4899' },
      ]} />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Building Characteristics */}
        <Panel title="Building Characteristics" icon={Building} color="#8B5CF6">
          <div className="space-y-0">
            <DataRow label="Stories" value={features.stories ?? '—'} />
            <DataRow label="Construction" value={formatLabel(features.constructionType)} />
            <DataRow label="Foundation" value={formatLabel(features.foundationType)} />
            <DataRow label="Basement" value={formatLabel(features.basementType)} />
            <DataRow label="Exterior" value={formatLabel(features.exteriorMaterial || features.wallType)} highlight />
            <DataRow label="Roof Cover" value={formatLabel(features.roofMaterial || features.roofTypeRecord)} />
          </div>
        </Panel>

        {/* Systems & Features */}
        <Panel title="Systems & Features" icon={Zap} color="#F59E0B">
          <div className="space-y-0">
            <DataRow label="Heating" value={formatLabel(features.heatingType)} />
            <DataRow label="Cooling" value={formatLabel(features.coolingType)} />
            <DataRow label="Pool" value={features.poolType ? formatLabel(features.poolType) : 'None'} />
            <DataRow label="Garage" value={features.garageSpaces > 0 ? `${features.garageSpaces}-car` : 'None'} />
            <DataRow label="Elevation" value={features.elevationFt != null ? `{formatCurrency(features.elevationFt)} ft` : '—'} />
            <DataRow label="Property Type" value={formatLabel(scan.propertyType)} />
          </div>
        </Panel>

        {/* Financial */}
        <Panel title="Financial & Sales" icon={TrendingUp} color="#10B981">
          <div className="space-y-0">
            <DataRow label="Assessed Value" value={formatCurrency(features.assessedValue)} highlight />
            <DataRow label="Last Sale Price" value={formatCurrency(features.lastSalePrice)} highlight />
            <DataRow label="Last Sale Date" value={features.lastSaleDate ? formatDate(features.lastSaleDate) : '—'} />
            {features.estimatedValue != null && (
              <DataRow label="Estimated Value" value={formatCurrency(features.estimatedValue)} highlight />
            )}
            <DataRow label="Lot Size" value={features.lotSqft ? `{formatCurrency(features.lotSqft)} sqft` : '—'} />
            <DataRow label="Neighborhood" value={formatLabel(features.neighborhoodType)} />
          </div>
        </Panel>
      </div>

      {/* Terrain & Site */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Panel title="Terrain & Site" icon={Map} color="#3B82F6">
          <div className="space-y-0">
            <DataRow label="Elevation" value={features.elevationFt != null ? `{formatCurrency(features.elevationFt)} ft` : '—'} mono />
            {features.terrainSlopePct != null && (
              <DataRow label="Terrain Slope" value={`${features.terrainSlopePct.toFixed(1)}%`} mono />
            )}
            {features.treeCoveragePct != null && (
              <DataRow label="Tree Coverage" value={`${features.treeCoveragePct.toFixed(0)}%`} />
            )}
            {features.buildingHeightFt != null && (
              <DataRow label="Building Height" value={`${features.buildingHeightFt.toFixed(0)} ft`} mono />
            )}
            <DataRow label="Lot Description" value={formatLabel(features.lotDescription)} />
            {scan.floodZone && <DataRow label="Flood Zone" value={`Zone ${scan.floodZone}`} highlight />}
          </div>
        </Panel>

        {/* Census / Neighborhood */}
        {(population || medianIncome || medianHomeValue) ? (
          <Panel title="Neighborhood Demographics" icon={Users} color="#7C3AED">
            <div className="space-y-0">
              {population != null && <DataRow label="Population" value={population.toLocaleString()} />}
              {medianIncome != null && <DataRow label="Median Household Income" value={formatCurrency(medianIncome)} highlight />}
              {medianHomeValue != null && <DataRow label="Median Home Value" value={formatCurrency(medianHomeValue)} highlight />}
              {ownerOccupied != null && <DataRow label="Owner Occupied" value={`${ownerOccupied.toFixed(1)}%`} />}
              {vacancyRate != null && <DataRow label="Vacancy Rate" value={`${vacancyRate.toFixed(1)}%`} />}
            </div>
          </Panel>
        ) : (
          <Panel title="Neighborhood Demographics" icon={Users} color="#7C3AED">
            <div className="text-center py-6">
              <Users size={20} className="mx-auto mb-2 text-muted/30" />
              <p className="text-xs text-muted">{t('recon.censusNotAvailable')}</p>
            </div>
          </Panel>
        )}
      </div>

      {/* Data sources for this property */}
      {features.dataSources.length > 0 && (
        <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-surface border border-main/50">
          <Database size={11} className="text-muted shrink-0" />
          <span className="text-[10px] text-muted">Property data from:</span>
          {features.dataSources.map(src => (
            <span key={src} className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-card text-[10px] font-medium text-muted">
              <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: SOURCE_COLORS[src] || '#6B7280' }} />
              {SOURCE_LABELS[src] || src.replace(/_/g, ' ')}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}

// ============================================================================
// ROOF TAB
// ============================================================================

function RoofTab({ roof, facets, scan }: {
  roof: RoofMeasurementData | null; facets: RoofFacetData[]; scan: PropertyScanData;
}) {
  const { t } = useTranslation();
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
        <Panel title={t('common.edgeLengths')} icon={Ruler} color="#3B82F6">
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
              <span className="text-xs font-semibold text-muted">{t('common.total')}</span>
              <span className="text-xs font-bold text-main font-mono">{totalEdge.toLocaleString()} ft</span>
            </div>
          </div>
        </Panel>

        <Panel title="Structure" icon={Home} color="#8B5CF6">
          <div className="space-y-0">
            <DataRow label={t('common.shape')} value={roof.predominantShape ? (SHAPE_LABELS[roof.predominantShape] || roof.predominantShape) : 'Unknown'} />
            {roof.predominantMaterial && <DataRow label={t('estimates.material')} value={roof.predominantMaterial.replace(/_/g, ' ')} highlight />}
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

function TradesTab({ tradeBids, selectedTrade, onSelectTrade, onEstimate, estimating, scan, features }: {
  tradeBids: TradeBidData[]; selectedTrade: TradeType | null;
  onSelectTrade: (t: TradeType | null) => void; onEstimate: () => void; estimating: boolean;
  scan: PropertyScanData; features: PropertyFeaturesData | null;
}) {
  const { t: tr } = useTranslation();
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
                  <span className="text-muted">{tr('common.waste')}</span>
                  <span className="text-main text-right font-medium">{t.wasteFactorPct}%</span>
                  <span className="text-muted">{tr('common.complexity')}</span>
                  <span className="text-main text-right font-medium">{t.complexityScore}/10</span>
                  <span className="text-muted">{tr('common.crew')}</span>
                  <span className="text-main text-right font-medium">{t.recommendedCrewSize}</span>
                  {t.estimatedLaborHours != null && <>
                    <span className="text-muted">{tr('common.labor')}</span>
                    <span className="text-main text-right font-medium">{t.estimatedLaborHours}h</span>
                  </>}
                </div>
              </button>
            );
          })}
        </div>
      )}

      {/* Trade detail */}
      {activeTrade && <TradeDetail trade={activeTrade} scan={scan} features={features} />}
    </div>
  );
}

function TradeDetail({ trade, scan, features }: {
  trade: TradeBidData; scan: PropertyScanData; features: PropertyFeaturesData | null;
}) {
  const { t } = useTranslation();
  const color = TRADE_COLORS[trade.trade] || '#6B7280';
  const env = (scan.environmentalData || {}) as Record<string, unknown>;
  const code = (scan.codeRequirements || {}) as Record<string, unknown>;
  const weather = (scan.weatherHistory || {}) as Record<string, unknown>;
  const measurements = (scan.computedMeasurements || {}) as Record<string, unknown>;
  const hazards = scan.hazardFlags || [];

  // Build trade-specific intelligence items
  const intel: { label: string; value: string; highlight?: boolean }[] = [];

  const tradeName = trade.trade;
  const yearBuilt = features?.yearBuilt;
  const propertyAge = yearBuilt ? new Date().getFullYear() - yearBuilt : null;
  const tradeHazards = hazards.filter(h => {
    if (tradeName === 'roofing') return ['wildfire'].includes(h.type);
    if (tradeName === 'siding' || tradeName === 'painting') return ['lead_paint', 'asbestos'].includes(h.type);
    if (tradeName === 'electrical') return ['knob_and_tube', 'problem_panels'].includes(h.type);
    if (tradeName === 'plumbing') return ['polybutylene_pipe', 'galvanized_pipe'].includes(h.type);
    if (tradeName === 'insulation') return ['asbestos', 'radon'].includes(h.type);
    if (tradeName === 'hvac') return ['asbestos', 'radon'].includes(h.type);
    if (tradeName === 'concrete') return ['seismic'].includes(h.type);
    if (tradeName === 'landscaping' || tradeName === 'fencing' || tradeName === 'irrigation') return [];
    return [];
  });

  // Common intelligence for all trades
  if (propertyAge != null) intel.push({ label: 'Property Age', value: `${propertyAge} years (${yearBuilt})` });
  if (features?.livingSqft) intel.push({ label: 'Living Area', value: `${features.livingSqft.toLocaleString()} sqft` });

  // Trade-specific rows
  if (tradeName === 'roofing') {
    if (weather.hail_events != null) intel.push({ label: 'Hail Events (2yr)', value: String(weather.hail_events), highlight: Number(weather.hail_events) > 0 });
    if (weather.wind_events != null) intel.push({ label: 'Severe Wind Events', value: String(weather.wind_events), highlight: Number(weather.wind_events) > 0 });
    if (features?.treeCanopyPct != null) intel.push({ label: 'Tree Shading', value: `${features.treeCanopyPct.toFixed(0)}%` });
    if (code.wind_speed_mph != null) intel.push({ label: 'Design Wind Speed', value: `${code.wind_speed_mph} mph` });
    if (measurements.roof_complexity_factor != null) intel.push({ label: 'Complexity Factor', value: `${Number(measurements.roof_complexity_factor).toFixed(2)}x`, highlight: Number(measurements.roof_complexity_factor) >= 1.5 });
  } else if (tradeName === 'siding') {
    if (measurements.wall_area_sqft != null) intel.push({ label: 'Wall Area (est)', value: `${Math.round(Number(measurements.wall_area_sqft)).toLocaleString()} sqft` });
    if (features?.stories) intel.push({ label: 'Stories', value: String(features.stories) });
    if (features?.exteriorMaterial) intel.push({ label: 'Existing Material', value: formatLabel(features.exteriorMaterial) });
  } else if (tradeName === 'hvac') {
    if (features?.climateZone) intel.push({ label: 'Climate Zone', value: features.climateZone });
    if (features?.heatingType) intel.push({ label: 'Existing Heating', value: formatLabel(features.heatingType) });
    if (features?.coolingType) intel.push({ label: 'Existing Cooling', value: formatLabel(features.coolingType) });
    if (code.energy_code) intel.push({ label: 'Energy Code', value: String(code.energy_code) });
    if (code.insulation_r_values) {
      const rv = code.insulation_r_values as Record<string, number>;
      if (rv.attic) intel.push({ label: 'Required R-Value (Attic)', value: `R-${rv.attic}` });
    }
  } else if (tradeName === 'plumbing') {
    if (propertyAge != null && propertyAge > 30) intel.push({ label: 'Pipe Age Risk', value: propertyAge > 50 ? 'High — likely galvanized' : 'Moderate — inspect', highlight: true });
  } else if (tradeName === 'electrical') {
    if (propertyAge != null && propertyAge > 40) intel.push({ label: 'Wiring Age Risk', value: propertyAge > 60 ? 'High — likely knob & tube era' : 'Moderate — inspect', highlight: true });
  } else if (tradeName === 'painting') {
    if (measurements.wall_area_sqft != null) intel.push({ label: 'Exterior Wall Area', value: `${Math.round(Number(measurements.wall_area_sqft)).toLocaleString()} sqft` });
    if (features?.livingSqft) intel.push({ label: 'Interior Area (est)', value: `${Math.round(features.livingSqft * 3.5).toLocaleString()} sqft` });
  } else if (tradeName === 'fencing') {
    if (measurements.boundary_perimeter_ft != null) intel.push({ label: 'Property Boundary', value: `${Math.round(Number(measurements.boundary_perimeter_ft)).toLocaleString()} LF` });
    if (features?.soilType) intel.push({ label: 'Soil Type', value: formatLabel(features.soilType) });
    if (features?.frostLineDepthIn != null) intel.push({ label: 'Post Depth (frost line)', value: `${features.frostLineDepthIn}"` });
  } else if (tradeName === 'concrete') {
    if (measurements.driveway_area_sqft != null) intel.push({ label: 'Driveway Area (est)', value: `${Math.round(Number(measurements.driveway_area_sqft)).toLocaleString()} sqft` });
    if (features?.soilBearingCapacity) intel.push({ label: 'Soil Bearing', value: formatLabel(features.soilBearingCapacity) });
    if (features?.frostLineDepthIn != null) intel.push({ label: 'Frost Line Depth', value: `${features.frostLineDepthIn}"` });
    if (features?.seismicCategory) intel.push({ label: 'Seismic Category', value: features.seismicCategory, highlight: ['D0', 'D1', 'D2', 'E', 'F'].includes(features.seismicCategory) });
  } else if (tradeName === 'landscaping' || tradeName === 'irrigation') {
    if (measurements.lawn_area_sqft != null) intel.push({ label: 'Yard Area', value: `${Math.round(Number(measurements.lawn_area_sqft)).toLocaleString()} sqft` });
    if (features?.treeCanopyPct != null) intel.push({ label: 'Tree Canopy', value: `${features.treeCanopyPct.toFixed(0)}%` });
    if (features?.soilType) intel.push({ label: 'Soil Type', value: formatLabel(features.soilType) });
    if (features?.soilDrainage) intel.push({ label: 'Soil Drainage', value: formatLabel(features.soilDrainage) });
  } else if (tradeName === 'solar') {
    if (features?.treeCanopyPct != null) intel.push({ label: 'Tree Shading', value: `${features.treeCanopyPct.toFixed(0)}%` });
    if (weather.avg_wind_mph != null) intel.push({ label: 'Avg Wind', value: `${Number(weather.avg_wind_mph).toFixed(1)} mph` });
  } else if (tradeName === 'insulation') {
    if (features?.climateZone) intel.push({ label: 'Climate Zone', value: features.climateZone });
    if (code.insulation_r_values) {
      const rv = code.insulation_r_values as Record<string, number>;
      if (rv.attic) intel.push({ label: 'Required: Attic', value: `R-${rv.attic}` });
      if (rv.wall) intel.push({ label: 'Required: Wall', value: `R-${rv.wall}` });
      if (rv.floor) intel.push({ label: 'Required: Floor', value: `R-${rv.floor}` });
    }
    if (weather.freeze_thaw_cycles != null) intel.push({ label: 'Freeze-Thaw Cycles', value: `${weather.freeze_thaw_cycles}/yr`, highlight: Number(weather.freeze_thaw_cycles) > 40 });
  } else if (['waterproofing', 'demolition'].includes(tradeName)) {
    if (scan.floodZone) intel.push({ label: 'Flood Zone', value: `Zone ${scan.floodZone}`, highlight: true });
    if (weather.annual_precip_in != null) intel.push({ label: 'Annual Precipitation', value: `${Number(weather.annual_precip_in).toFixed(1)}"` });
  }

  return (
    <div className="space-y-4">
      <KpiStrip items={[
        { label: 'Materials', value: trade.materialList.length, icon: Package, color },
        { label: 'Waste Factor', value: `${trade.wasteFactorPct}%`, icon: Activity, color: '#F59E0B' },
        { label: 'Crew Size', value: trade.recommendedCrewSize, unit: 'workers', icon: Users, color: '#3B82F6' },
        { label: 'Est. Labor', value: trade.estimatedLaborHours ?? '—', unit: trade.estimatedLaborHours ? 'hrs' : '', icon: Clock, color: '#10B981' },
        { label: 'Complexity', value: `${trade.complexityScore}/10`, icon: Activity, color: '#EC4899' },
      ]} />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Measurements */}
        <Panel title={`${TRADE_LABELS[trade.trade]} Measurements`} icon={Ruler} color={color}>
          <div className="space-y-0">
            {Object.entries(trade.measurements).map(([key, val]) => (
              <DataRow key={key}
                label={key.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                value={typeof val === 'number' ? val : String(val ?? '—')} />
            ))}
            {Object.keys(trade.measurements).length === 0 && (
              <p className="text-xs text-muted py-4 text-center">{t('recon.noDetailedMeasurements')}</p>
            )}
          </div>
        </Panel>

        {/* Trade-Specific Intelligence */}
        <Panel title="Property Intelligence" icon={Satellite} color={color}>
          <div className="space-y-0">
            {intel.map((item, i) => (
              <DataRow key={i} label={item.label} value={item.value} highlight={item.highlight} />
            ))}
            {intel.length === 0 && (
              <p className="text-xs text-muted py-4 text-center">No trade-specific intelligence available</p>
            )}
            {/* Trade-relevant hazard warnings */}
            {tradeHazards.length > 0 && (
              <div className="pt-2 mt-2 border-t border-main space-y-1.5">
                <p className="text-[10px] font-semibold text-red-400 uppercase tracking-wider">Hazard Warnings</p>
                {tradeHazards.map((h, i) => (
                  <div key={i} className="flex items-start gap-2 text-[11px]">
                    <AlertTriangle size={10} className="text-red-400 mt-0.5 shrink-0" />
                    <span className="text-main">{h.title}: {h.what_to_do || h.description}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </Panel>

        {/* Job Intelligence */}
        <Panel title={t('nav.jobIntelligence')} icon={Activity} color="#F59E0B">
          <div className="space-y-0">
            <DataRow label={t('common.complexity')} value={`${trade.complexityScore}/10`} highlight={trade.complexityScore >= 7} />
            <DataRow label={t('estimates.wasteFactor')} value={`${trade.wasteFactorPct}%`} />
            <DataRow label={t('common.crew')} value={`${trade.recommendedCrewSize} workers`} />
            {trade.estimatedLaborHours != null && <DataRow label={t('estimates.labor')} value={`${trade.estimatedLaborHours} hours`} highlight />}
            {trade.dataSources.length > 0 && (
              <div className="pt-2 mt-2 border-t border-main">
                <p className="text-[10px] text-muted uppercase tracking-wider mb-1.5">{t('common.dataSources')}</p>
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
                  <th className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">{t('common.item')}</th>
                  <th className="px-4 py-2.5 text-right text-[10px] font-semibold text-muted uppercase tracking-wider">{t('recon.baseQty')}</th>
                  <th className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">{t('common.unit')}</th>
                  <th className="px-4 py-2.5 text-right text-[10px] font-semibold text-muted uppercase tracking-wider">{t('common.waste')}</th>
                  <th className="px-4 py-2.5 text-right text-[10px] font-semibold text-muted uppercase tracking-wider">{t('recon.totalQty')}</th>
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
  const { t: tr } = useTranslation();
  const solarBid = tradeBids.find(tb => tb.trade === 'solar');

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
                  <th className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">{tr('common.item')}</th>
                  <th className="px-4 py-2.5 text-right text-[10px] font-semibold text-muted uppercase tracking-wider">{tr('common.qty')}</th>
                  <th className="px-4 py-2.5 text-left text-[10px] font-semibold text-muted uppercase tracking-wider">{tr('common.unit')}</th>
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
  const { t } = useTranslation();
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
              <label className="text-[10px] font-medium text-muted uppercase tracking-wider block mb-1">{t('common.stormDate')}</label>
              <input type="date" value={stormDate} onChange={(e) => setStormDate(e.target.value)}
                className="w-full bg-surface border border-main rounded-lg px-3 py-2 text-sm text-main focus:border-accent focus:outline-none transition-colors" />
            </div>
            <div>
              <label className="text-[10px] font-medium text-muted uppercase tracking-wider block mb-1">{t('common.state')}</label>
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
            {result && <Button variant="ghost" size="sm" onClick={reset}>{t('common.clear')}</Button>}
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
                <p className="text-xs text-muted mt-2">{t('recon.estimatedStormDamage')}</p>
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

// ============================================================================
// SCAN HISTORY
// ============================================================================

interface ScanHistoryEntry {
  id: string;
  status: string;
  confidenceScore: number;
  confidenceGrade: string;
  scanSources: string[];
  createdAt: string;
  hazardCount: number;
}

function ScanHistory({ address, currentScanId }: { address: string; currentScanId: string }) {
  const { t } = useTranslation();
  const router = useRouter();
  const [history, setHistory] = useState<ScanHistoryEntry[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!address) return;
    const supabase = createClient();
    supabase
      .from('property_scans')
      .select('id, status, confidence_score, confidence_grade, scan_sources, created_at, hazard_flags')
      .eq('address', address)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .limit(20)
      .then(({ data }) => {
        setHistory(
          (data || [])
            .filter((r) => r.id !== currentScanId)
            .map((r) => ({
              id: r.id as string,
              status: r.status as string,
              confidenceScore: Number(r.confidence_score) || 0,
              confidenceGrade: (r.confidence_grade as string) || 'low',
              scanSources: (r.scan_sources as string[]) || [],
              createdAt: r.created_at as string,
              hazardCount: Array.isArray(r.hazard_flags) ? r.hazard_flags.length : 0,
            }))
        );
        setLoading(false);
      });
  }, [address, currentScanId]);

  if (loading || history.length === 0) return null;

  return (
    <Panel title={`Scan History — ${history.length} previous`} icon={History} color="#8B5CF6">
      <div className="space-y-0">
        {history.map((entry, i) => {
          const st = STATUS_CONFIG[entry.status] || STATUS_CONFIG.pending;
          const gradeColor = entry.confidenceGrade === 'high' ? '#10B981' : entry.confidenceGrade === 'moderate' ? '#F59E0B' : '#EF4444';
          return (
            <button
              key={entry.id}
              onClick={() => router.push(`/dashboard/recon/${entry.id}`)}
              className={cn(
                'w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-left transition-colors hover:bg-surface/60',
                i < history.length - 1 && 'border-b border-main/30'
              )}
            >
              <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
                style={{ backgroundColor: `${st.color}15` }}>
                <Satellite size={14} style={{ color: st.color }} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-semibold text-main">
                    {new Date(entry.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                  </span>
                  <span className="text-[10px] text-muted">
                    {new Date(entry.createdAt).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                  </span>
                  <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[9px] font-semibold"
                    style={{ color: st.color, backgroundColor: st.bg }}>
                    {st.label}
                  </span>
                </div>
                <div className="flex items-center gap-3 mt-0.5">
                  <span className="text-[10px] text-muted">{entry.scanSources.length} sources</span>
                  <span className="text-[10px] font-semibold" style={{ color: gradeColor }}>
                    {entry.confidenceScore}% confidence
                  </span>
                  {entry.hazardCount > 0 && (
                    <span className="text-[10px] text-red-400">{entry.hazardCount} hazards</span>
                  )}
                </div>
              </div>
              <ChevronRight size={14} className="text-muted shrink-0" />
            </button>
          );
        })}
      </div>
    </Panel>
  );
}
