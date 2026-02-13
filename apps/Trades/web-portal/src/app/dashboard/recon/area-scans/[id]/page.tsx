'use client';

import { useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  Satellite,
  Flame,
  Thermometer,
  Snowflake,
  MapPin,
  Download,
  Loader2,
  AlertCircle,
  ChevronRight,
  BarChart3,
  Target,
  CloudLightning,
  Wind,
  CircleDot,
  Navigation,
  ShieldAlert,
} from 'lucide-react';
import { useAreaScan, type LeadScoreData } from '@/lib/hooks/use-area-scan';
import { useStormAssess, type StormPropertyResult } from '@/lib/hooks/use-storm-assess';

function GradeBadge({ grade, score }: { grade: string; score: number }) {
  const config: Record<string, { icon: typeof Flame; color: string; bg: string }> = {
    hot: { icon: Flame, color: 'text-red-400', bg: 'bg-red-500/10 border-red-500/20' },
    warm: { icon: Thermometer, color: 'text-orange-400', bg: 'bg-orange-500/10 border-orange-500/20' },
    cold: { icon: Snowflake, color: 'text-blue-400', bg: 'bg-blue-500/10 border-blue-500/20' },
  };
  const c = config[grade] || config.cold;
  const Icon = c.icon;

  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded border text-xs font-medium ${c.bg} ${c.color}`}>
      <Icon size={11} />
      {score}
    </span>
  );
}

function LeadRow({ lead }: { lead: LeadScoreData }) {
  return (
    <Link
      href={`/dashboard/recon/${lead.propertyScanId}`}
      className="flex items-center justify-between px-4 py-3 border-b border-main last:border-0 hover:bg-surface-hover transition-colors"
    >
      <div className="flex items-center gap-3 min-w-0">
        <GradeBadge grade={lead.grade} score={lead.overallScore} />
        <div className="min-w-0">
          <p className="text-sm text-main truncate">{lead.address || 'Unknown address'}</p>
          {(lead.city || lead.state) && (
            <p className="text-xs text-muted truncate">
              {[lead.city, lead.state].filter(Boolean).join(', ')}
            </p>
          )}
        </div>
      </div>
      <ChevronRight size={14} className="text-muted flex-shrink-0" />
    </Link>
  );
}

// ============================================================================
// STORM PROBABILITY BADGE
// ============================================================================

function StormBadge({ probability }: { probability: number }) {
  const color = probability >= 50
    ? 'text-red-400 bg-red-500/10 border-red-500/20'
    : probability >= 25
      ? 'text-orange-400 bg-orange-500/10 border-orange-500/20'
      : 'text-blue-400 bg-blue-500/10 border-blue-500/20';

  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded border text-xs font-medium ${color}`}>
      <CloudLightning size={11} />
      {probability}%
    </span>
  );
}

// ============================================================================
// STORM RESULT ROW
// ============================================================================

function StormResultRow({ result }: { result: StormPropertyResult }) {
  return (
    <Link
      href={`/dashboard/recon/${result.property_scan_id}`}
      className="flex items-center justify-between px-4 py-3 border-b border-main last:border-0 hover:bg-surface-hover transition-colors"
    >
      <div className="flex items-center gap-3 min-w-0">
        <StormBadge probability={result.probability} />
        <div className="min-w-0">
          <p className="text-sm text-main truncate">{result.address || 'Unknown address'}</p>
          <div className="flex items-center gap-3 mt-0.5">
            {result.max_hail > 0 && (
              <span className="text-[10px] text-muted flex items-center gap-0.5">
                <CircleDot size={9} /> {result.max_hail}&quot; hail
              </span>
            )}
            {result.max_wind > 0 && (
              <span className="text-[10px] text-muted flex items-center gap-0.5">
                <Wind size={9} /> {result.max_wind} kts
              </span>
            )}
          </div>
        </div>
      </div>
      <ChevronRight size={14} className="text-muted flex-shrink-0" />
    </Link>
  );
}

// ============================================================================
// STORM ASSESSMENT PANEL
// ============================================================================

function StormAssessmentPanel({
  areaScanId,
  scanState,
  stormDate: defaultStormDate,
}: {
  areaScanId: string;
  scanState: string | null;
  stormDate: string | null;
}) {
  const { result, loading, error, assessArea, reset } = useStormAssess();
  const [stormDate, setStormDate] = useState(defaultStormDate || '');
  const [state, setState] = useState(scanState || '');
  const [county, setCounty] = useState('');

  const handleAssess = () => {
    if (!stormDate || !state) return;
    assessArea({
      area_scan_id: areaScanId,
      storm_date: stormDate,
      state,
      county: county || undefined,
    });
  };

  return (
    <div className="border border-purple-500/20 rounded-lg bg-purple-500/5 overflow-hidden">
      {/* Storm panel header */}
      <div className="px-4 py-3 border-b border-purple-500/20 flex items-center gap-2">
        <CloudLightning size={16} className="text-purple-400" />
        <span className="text-sm font-semibold text-purple-400">Storm Damage Assessment</span>
        <span className="text-[10px] text-muted ml-auto">NOAA + SPC data</span>
      </div>

      {/* Input form */}
      <div className="p-4 space-y-3">
        <div className="grid grid-cols-3 gap-3">
          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted block mb-1">Storm Date</label>
            <input
              type="date"
              value={stormDate}
              onChange={(e) => setStormDate(e.target.value)}
              className="w-full bg-surface border border-main rounded-md px-3 py-2 text-sm text-main focus:border-accent focus:outline-none"
            />
          </div>
          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted block mb-1">State</label>
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
            <label className="text-[10px] uppercase tracking-wider text-muted block mb-1">County (opt)</label>
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
          <button
            onClick={handleAssess}
            disabled={loading || !stormDate || !state}
            className="flex items-center gap-1.5 px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded-md text-sm text-white font-medium transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
          >
            {loading ? <Loader2 size={14} className="animate-spin" /> : <ShieldAlert size={14} />}
            {loading ? 'Analyzing...' : 'Run Storm Assessment'}
          </button>
          {result && (
            <button
              onClick={reset}
              className="px-3 py-2 text-xs text-muted hover:text-main transition-colors"
            >
              Clear results
            </button>
          )}
        </div>

        {error && (
          <div className="flex items-center gap-2 text-sm text-red-400">
            <AlertCircle size={14} />
            {error}
          </div>
        )}
      </div>

      {/* Results */}
      {result && (
        <div className="border-t border-purple-500/20">
          {/* Summary stats */}
          <div className="grid grid-cols-4 gap-3 p-4">
            <div className="text-center">
              <p className="text-lg font-semibold text-main">{result.storm_events_found}</p>
              <p className="text-[10px] text-muted uppercase tracking-wider">Storm Events</p>
            </div>
            <div className="text-center">
              <p className="text-lg font-semibold text-red-400">{result.high_probability || 0}</p>
              <p className="text-[10px] text-muted uppercase tracking-wider">High Prob (&ge;50%)</p>
            </div>
            <div className="text-center">
              <p className="text-lg font-semibold text-orange-400">{result.medium_probability || 0}</p>
              <p className="text-[10px] text-muted uppercase tracking-wider">Medium (25-49%)</p>
            </div>
            <div className="text-center">
              <p className="text-lg font-semibold text-blue-400">{result.low_probability || 0}</p>
              <p className="text-[10px] text-muted uppercase tracking-wider">Low (&lt;25%)</p>
            </div>
          </div>

          {/* Canvass priority list — ranked by probability */}
          {result.results && result.results.length > 0 && (
            <div className="border-t border-purple-500/20">
              <div className="px-4 py-2 flex items-center gap-2">
                <Navigation size={14} className="text-purple-400" />
                <span className="text-xs font-medium text-purple-400">Canvass Priority List</span>
                <span className="text-[10px] text-muted ml-auto">
                  {result.results.length} properties ranked by damage probability
                </span>
              </div>
              <div className="max-h-96 overflow-y-auto">
                {result.results.map((r, i) => (
                  <div key={r.property_scan_id} className="flex items-center gap-0">
                    <span className="w-8 text-center text-xs text-muted font-mono">{i + 1}</span>
                    <div className="flex-1">
                      <StormResultRow result={r} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Legal disclaimer */}
          <div className="px-4 py-3 border-t border-purple-500/20 bg-purple-500/5">
            <p className="text-[10px] text-muted leading-relaxed">
              Storm damage probability is estimated from NOAA Storm Events Database and SPC Storm Reports.
              Actual damage may vary. Probabilities are based on proximity to reported storm events, hail size,
              wind speed, and estimated roof age. This data is for canvassing guidance only and does not
              constitute a damage assessment or insurance claim.
            </p>
          </div>
        </div>
      )}
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function AreaScanDetailPage() {
  const params = useParams();
  const areaScanId = params.id as string;
  const { scan, leads, loading, error, exportCsv } = useAreaScan(areaScanId);
  const [gradeFilter, setGradeFilter] = useState<'all' | 'hot' | 'warm' | 'cold'>('all');
  const [showStorm, setShowStorm] = useState(false);

  const filteredLeads = gradeFilter === 'all'
    ? leads
    : leads.filter(l => l.grade === gradeFilter);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-32">
        <Loader2 size={24} className="animate-spin text-muted" />
      </div>
    );
  }

  if (error || !scan) {
    return (
      <div className="flex flex-col items-center justify-center py-32 gap-2">
        <AlertCircle size={24} className="text-red-400" />
        <p className="text-sm text-red-400">{error || 'Area scan not found'}</p>
        <Link href="/dashboard/recon/area-scans" className="text-sm text-accent hover:underline mt-2">
          Back to area scans
        </Link>
      </div>
    );
  }

  const progress = scan.totalParcels > 0
    ? Math.round((scan.scannedParcels / scan.totalParcels) * 100)
    : 0;

  const isScanning = scan.status === 'scanning';

  return (
    <div className="p-6 max-w-5xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <Link
            href="/dashboard/recon/area-scans"
            className="p-1.5 text-muted hover:text-main rounded-md hover:bg-surface-hover transition-colors"
          >
            <ArrowLeft size={18} />
          </Link>
          <div>
            <h1 className="text-lg font-semibold text-main flex items-center gap-2">
              <Satellite size={20} />
              {scan.name || 'Area Scan'}
            </h1>
            <div className="flex items-center gap-3 mt-0.5">
              <span className="text-xs text-muted capitalize">{scan.scanType.replace('_', ' ')}</span>
              <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border ${
                isScanning
                  ? 'bg-blue-500/10 text-blue-400 border-blue-500/20'
                  : scan.status === 'complete'
                    ? 'bg-green-500/10 text-green-400 border-green-500/20'
                    : 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20'
              }`}>
                {isScanning && <Loader2 size={10} className="mr-1 animate-spin" />}
                {scan.status}
              </span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowStorm(!showStorm)}
            className={`flex items-center gap-1.5 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
              showStorm
                ? 'bg-purple-600 text-white'
                : 'border border-main text-muted hover:text-main hover:bg-surface-hover'
            }`}
          >
            <CloudLightning size={14} />
            Storm Mode
          </button>
          <button
            onClick={exportCsv}
            disabled={leads.length === 0}
            className="flex items-center gap-1.5 px-3 py-2 border border-main rounded-md text-sm text-muted hover:text-main hover:bg-surface-hover transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <Download size={14} />
            Export CSV
          </button>
        </div>
      </div>

      {/* Progress bar (show when scanning) */}
      {isScanning && (
        <div className="mb-6 p-4 border border-blue-500/20 rounded-lg bg-blue-500/5">
          <div className="flex items-center justify-between text-sm mb-2">
            <span className="text-blue-400 font-medium">Scanning in progress...</span>
            <span className="text-muted">{scan.scannedParcels} / {scan.totalParcels}</span>
          </div>
          <div className="h-2 bg-surface rounded-full overflow-hidden">
            <div
              className="h-full bg-blue-500 rounded-full transition-all duration-500"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      )}

      {/* Stats Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 mb-6">
        <div className="border border-main rounded-lg p-3 text-center">
          <MapPin size={16} className="mx-auto text-muted mb-1" />
          <p className="text-xl font-semibold text-main">{scan.totalParcels}</p>
          <p className="text-[10px] text-muted uppercase tracking-wider">Total Parcels</p>
        </div>
        <div className="border border-main rounded-lg p-3 text-center">
          <Target size={16} className="mx-auto text-muted mb-1" />
          <p className="text-xl font-semibold text-main">{scan.scannedParcels}</p>
          <p className="text-[10px] text-muted uppercase tracking-wider">Scanned</p>
        </div>
        <div className="border border-main rounded-lg p-3 text-center">
          <Flame size={16} className="mx-auto text-red-400 mb-1" />
          <p className="text-xl font-semibold text-red-400">{scan.hotLeads}</p>
          <p className="text-[10px] text-muted uppercase tracking-wider">Hot Leads</p>
        </div>
        <div className="border border-main rounded-lg p-3 text-center">
          <Thermometer size={16} className="mx-auto text-orange-400 mb-1" />
          <p className="text-xl font-semibold text-orange-400">{scan.warmLeads}</p>
          <p className="text-[10px] text-muted uppercase tracking-wider">Warm Leads</p>
        </div>
        <div className="border border-main rounded-lg p-3 text-center">
          <Snowflake size={16} className="mx-auto text-blue-400 mb-1" />
          <p className="text-xl font-semibold text-blue-400">{scan.coldLeads}</p>
          <p className="text-[10px] text-muted uppercase tracking-wider">Cold Leads</p>
        </div>
      </div>

      {/* Score distribution bar */}
      {(scan.hotLeads + scan.warmLeads + scan.coldLeads) > 0 && (
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-2">
            <BarChart3 size={14} className="text-muted" />
            <span className="text-xs font-medium text-muted">Lead Distribution</span>
          </div>
          <div className="h-3 bg-surface rounded-full overflow-hidden flex">
            {scan.hotLeads > 0 && (
              <div
                className="h-full bg-red-500 transition-all"
                style={{ width: `${(scan.hotLeads / (scan.hotLeads + scan.warmLeads + scan.coldLeads)) * 100}%` }}
                title={`${scan.hotLeads} hot`}
              />
            )}
            {scan.warmLeads > 0 && (
              <div
                className="h-full bg-orange-500 transition-all"
                style={{ width: `${(scan.warmLeads / (scan.hotLeads + scan.warmLeads + scan.coldLeads)) * 100}%` }}
                title={`${scan.warmLeads} warm`}
              />
            )}
            {scan.coldLeads > 0 && (
              <div
                className="h-full bg-blue-500 transition-all"
                style={{ width: `${(scan.coldLeads / (scan.hotLeads + scan.warmLeads + scan.coldLeads)) * 100}%` }}
                title={`${scan.coldLeads} cold`}
              />
            )}
          </div>
        </div>
      )}

      {/* Storm Assessment Panel */}
      {showStorm && (
        <div className="mb-6">
          <StormAssessmentPanel
            areaScanId={areaScanId}
            scanState={scan.stormType ? null : null}
            stormDate={scan.stormDate}
          />
        </div>
      )}

      {/* Grade filter tabs */}
      <div className="flex items-center gap-1 mb-4 border-b border-main">
        {[
          { value: 'all' as const, label: 'All', count: leads.length },
          { value: 'hot' as const, label: 'Hot', count: leads.filter(l => l.grade === 'hot').length, color: 'text-red-400' },
          { value: 'warm' as const, label: 'Warm', count: leads.filter(l => l.grade === 'warm').length, color: 'text-orange-400' },
          { value: 'cold' as const, label: 'Cold', count: leads.filter(l => l.grade === 'cold').length, color: 'text-blue-400' },
        ].map(tab => (
          <button
            key={tab.value}
            onClick={() => setGradeFilter(tab.value)}
            className={`px-3 py-2 text-xs font-medium border-b-2 transition-colors ${
              gradeFilter === tab.value
                ? 'border-accent text-accent'
                : 'border-transparent text-muted hover:text-main'
            }`}
          >
            {tab.label}
            <span className={`ml-1 ${tab.color || ''}`}>({tab.count})</span>
          </button>
        ))}
      </div>

      {/* Lead list */}
      {filteredLeads.length === 0 ? (
        <div className="text-center py-16">
          <Target size={32} className="mx-auto text-muted/30 mb-2" />
          <p className="text-sm text-muted">
            {isScanning ? 'Leads will appear as scanning progresses...' : 'No leads found'}
          </p>
        </div>
      ) : (
        <div className="border border-main rounded-lg divide-y divide-main overflow-hidden">
          {filteredLeads.map(lead => (
            <LeadRow key={lead.id} lead={lead} />
          ))}
        </div>
      )}
    </div>
  );
}
