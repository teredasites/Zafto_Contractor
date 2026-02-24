'use client';

import { useState, useMemo } from 'react';
import { useTranslation } from '@/lib/translations';
import {
  useMoldAssessments,
  useMoldLabSamples,
  useMoldStateLicensing,
  useMoldRemediationPlans,
  useMoldEquipment,
  useMoldMoistureReadings,
  useMoldClearanceTests,
  type MoldAssessment,
  type MoldLabSample,
  type MoldStateLicensing,
  type MoldEquipmentDeployment,
  type MoldMoistureReading,
  type MoldRemediationPlan,
  type MoldClearanceTest,
} from '@/lib/hooks/use-mold-remediation';
import { SearchInput } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  ChevronRight,
  ChevronDown,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Eye,
  Layers,
  Droplets,
  Wind,
  Shield,
  FlaskConical,
  ClipboardList,
  Calculator,
  Microscope,
  FileText,
  MapPin,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { formatCurrency, formatDateLocale } from '@/lib/format-locale';
import { CommandPalette } from '@/components/command-palette';
import {
  MOLD_CONTAINMENT_LEVELS,
  MOLD_REMEDIATION_STEPS,
  MATERIAL_REMEDIATION_DECISIONS,
  determineContainmentLevel,
} from '@/lib/official-iicrc-protocols';

// ── Types ──

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;
type IicrcLevel = 1 | 2 | 3;
type DetailTab = 'overview' | 'containment' | 'moisture' | 'clearance' | 'protocol' | 'licensing';

const DETAIL_TABS: { key: DetailTab; label: string; icon: LucideIcon }[] = [
  { key: 'overview', label: 'Overview', icon: Eye },
  { key: 'containment', label: 'Containment', icon: Shield },
  { key: 'moisture', label: 'Moisture', icon: Droplets },
  { key: 'clearance', label: 'Clearance', icon: FlaskConical },
  { key: 'protocol', label: 'Protocol', icon: ClipboardList },
  { key: 'licensing', label: 'State Licensing', icon: FileText },
];

// ── IICRC S520 Reference ──

const IICRC_LEVEL_INFO: Record<IicrcLevel, {
  label: string;
  sqft: string;
  ppe: string[];
  containment: string;
  airFiltration: string;
  description: string;
  clearance: string;
}> = Object.fromEntries(
  MOLD_CONTAINMENT_LEVELS.map(lvl => [lvl.level, {
    label: `Level ${lvl.level} — ${lvl.name}`,
    sqft: lvl.affectedArea,
    ppe: lvl.ppeRequirements,
    containment: lvl.containmentRequirements.join('; '),
    airFiltration: lvl.airFiltration.join('; '),
    description: `${lvl.name}: ${lvl.affectedArea}. ${lvl.containmentRequirements[0] || ''}`,
    clearance: lvl.postRemediationVerification.join('; '),
  }])
) as Record<IicrcLevel, { label: string; sqft: string; ppe: string[]; containment: string; airFiltration: string; description: string; clearance: string }>;

const STATUS_COLORS: Record<string, string> = {
  planned: 'bg-secondary text-muted border-main',
  in_progress: 'bg-blue-500/15 text-blue-400 border-blue-500/30',
  completed: 'bg-green-500/15 text-green-400 border-green-500/30',
  on_hold: 'bg-yellow-500/15 text-yellow-400 border-yellow-500/30',
};

const STATUS_LABELS: Record<string, string> = {
  planned: 'Planned', in_progress: 'In Progress', completed: 'Completed', on_hold: 'On Hold',
};

const LEVEL_COLORS: Record<IicrcLevel, string> = {
  1: 'bg-green-500/15 text-green-400 border-green-500/30',
  2: 'bg-yellow-500/15 text-yellow-400 border-yellow-500/30',
  3: 'bg-red-500/15 text-red-400 border-red-500/30',
};

const CAUSE_LABELS: Record<string, string> = {
  water_intrusion: 'Water Intrusion', hvac_issue: 'HVAC Issue', plumbing_leak: 'Plumbing Leak',
  flooding: 'Flooding', condensation: 'Condensation', unknown: 'Unknown',
  roof_leak: 'Roof Leak', foundation_crack: 'Foundation Crack',
};

function fmtDate(iso: string | null | undefined): string {
  if (!iso) return '—';
  return formatDateLocale(new Date(iso));
}

// ── Main Page ──

export default function MoldRemediationPage() {
  const { t } = useTranslation();
  const { assessments, loading, error } = useMoldAssessments('');
  const { states: licensing } = useMoldStateLicensing();
  const [searchQuery, setSearchQuery] = useState('');
  const [filterLevel, setFilterLevel] = useState<IicrcLevel | 'all'>('all');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const filtered = assessments.filter((a) => {
    if (filterLevel !== 'all' && a.remediationLevel !== filterLevel) return false;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      return (
        (a.suspectedCause ?? '').toLowerCase().includes(q) ||
        (a.overallNotes ?? '').toLowerCase().includes(q) ||
        (a.moistureSourceStatus ?? '').toLowerCase().includes(q) ||
        (a.jobId ?? '').toLowerCase().includes(q)
      );
    }
    return true;
  });

  const selected = selectedId ? assessments.find((a) => a.id === selectedId) ?? null : null;

  const totalAssessments = assessments.length;
  const level1 = assessments.filter((a) => a.remediationLevel === 1).length;
  const level2 = assessments.filter((a) => a.remediationLevel === 2).length;
  const level3 = assessments.filter((a) => a.remediationLevel === 3).length;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-96">
        <p className="text-red-400">Error: {error}</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <CommandPalette />
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-main">{t('moldRemediation.title')}</h1>
        <p className="text-sm text-muted mt-1">IICRC S520 compliant assessments, containment planning, air sampling, clearance testing</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <StatCard label="Total Assessments" value={totalAssessments} />
        <StatCard label="Level 1 (Small)" value={level1} color="text-green-400" />
        <StatCard label="Level 2 (Mid)" value={level2} color="text-yellow-400" />
        <StatCard label="Level 3 (Large)" value={level3} color="text-red-400" />
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3">
        <div className="flex-1 max-w-sm">
          <SearchInput
            placeholder="Search by cause, notes, job..."
            value={searchQuery}
            onChange={(v) => setSearchQuery(v)}
          />
        </div>
        <div className="flex gap-2">
          {(['all', 1, 2, 3] as const).map((level) => (
            <button
              key={level}
              onClick={() => setFilterLevel(level)}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-colors ${
                filterLevel === level
                  ? 'bg-white/10 text-white border-white/20'
                  : 'text-muted border-main hover:border-accent/30'
              }`}
            >
              {level === 'all' ? 'All Levels' : `Level ${level}`}
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="grid grid-cols-12 gap-6">
        {/* List */}
        <div className="col-span-4 space-y-3 max-h-[calc(100vh-300px)] overflow-y-auto pr-1">
          {filtered.length === 0 ? (
            <div className="text-center py-12 text-muted">
              <p className="text-sm">{t('moldRemediation.noRecords')}</p>
            </div>
          ) : (
            filtered.map((a) => (
              <button
                key={a.id}
                onClick={() => setSelectedId(a.id)}
                className={`w-full text-left p-4 rounded-xl border transition-colors ${
                  selectedId === a.id
                    ? 'bg-secondary border-accent/30'
                    : 'bg-surface border-main hover:border-accent/30'
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  {a.remediationLevel && (
                    <span className={`text-xs font-semibold px-2 py-0.5 rounded border ${LEVEL_COLORS[a.remediationLevel as IicrcLevel] ?? ''}`}>
                      Level {a.remediationLevel}
                    </span>
                  )}
                  <span className={`text-xs font-medium px-2 py-0.5 rounded border ${
                    a.moistureSourceStatus === 'active_leak'
                      ? 'bg-red-500/15 text-red-400 border-red-500/30'
                      : a.moistureSourceStatus === 'resolved'
                      ? 'bg-green-500/15 text-green-400 border-green-500/30'
                      : 'bg-secondary text-muted border-main'
                  }`}>
                    {a.moistureSourceStatus === 'active_leak' ? 'Active Leak' : a.moistureSourceStatus === 'resolved' ? 'Resolved' : 'Unknown Source'}
                  </span>
                </div>
                <div className="text-sm text-main font-medium">
                  {CAUSE_LABELS[a.suspectedCause ?? ''] ?? 'Unknown Cause'} — {a.occupancyStatus ?? 'Unknown'}
                </div>
                <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                  <span>{a.affectedAreaSqft ? `${a.affectedAreaSqft} sqft` : 'Area TBD'}</span>
                  <span>{fmtDate(a.assessmentDate)}</span>
                </div>
              </button>
            ))
          )}
        </div>

        {/* Detail Panel */}
        <div className="col-span-8">
          {selected ? (
            <AssessmentDetail assessment={selected} licensing={licensing} />
          ) : (
            <div className="flex items-center justify-center h-96 rounded-xl bg-secondary/50 border border-main">
              <p className="text-sm text-muted">{t('common.selectAnAssessmentToViewDetails')}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Components ──

function StatCard({ label, value, color = 'text-main' }: { label: string; value: number; color?: string }) {
  return (
    <div className="bg-secondary/50 border border-main rounded-xl p-4">
      <p className="text-xs text-muted mb-1">{label}</p>
      <p className={`text-2xl font-bold ${color}`}>{value}</p>
    </div>
  );
}

// ── TABBED DETAIL ──

function AssessmentDetail({
  assessment: a,
  licensing,
}: {
  assessment: MoldAssessment;
  licensing: MoldStateLicensing[];
}) {
  const [activeTab, setActiveTab] = useState<DetailTab>('overview');

  return (
    <div className="space-y-4">
      {/* Tabs */}
      <div className="flex gap-1 overflow-x-auto pb-1">
        {DETAIL_TABS.map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-medium whitespace-nowrap transition-colors',
                activeTab === tab.key
                  ? 'bg-white/10 text-white'
                  : 'text-muted hover:text-main hover:bg-surface-hover'
              )}
            >
              <Icon size={14} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {activeTab === 'overview' && <OverviewTab assessment={a} />}
      {activeTab === 'containment' && <ContainmentTab assessment={a} />}
      {activeTab === 'moisture' && <MoistureTab assessment={a} />}
      {activeTab === 'clearance' && <ClearanceTab assessment={a} />}
      {activeTab === 'protocol' && <ProtocolTab assessment={a} />}
      {activeTab === 'licensing' && <LicensingTab licensing={licensing} />}
    </div>
  );
}

// ── OVERVIEW TAB ──

function OverviewTab({ assessment: a }: { assessment: MoldAssessment }) {
  const { t } = useTranslation();
  const { samples: labSamples } = useMoldLabSamples(a.id);
  const { plans: remediationPlans } = useMoldRemediationPlans(a.id);
  const { readings: moistureReadings } = useMoldMoistureReadings(a.id);
  const activePlan = remediationPlans.find((p) => p.status !== 'completed') ?? remediationPlans[0];
  const { deployments: equipment } = useMoldEquipment(activePlan?.id);

  const level = (a.remediationLevel ?? 1) as IicrcLevel;
  const levelInfo = IICRC_LEVEL_INFO[level];

  return (
    <div className="space-y-4">
      {/* IICRC Level Card */}
      <div className={cn('rounded-xl border p-5', LEVEL_COLORS[level])}>
        <div className="flex items-center justify-between mb-2">
          <h2 className="text-lg font-bold">{levelInfo.label}</h2>
          <span className={cn('text-xs font-bold px-2 py-1 rounded border', LEVEL_COLORS[level])}>
            Level {level}
          </span>
        </div>
        <p className="text-sm opacity-80">{levelInfo.description}</p>
        <div className="grid grid-cols-2 gap-3 mt-3 text-xs">
          <div><span className="opacity-60">Area:</span> {levelInfo.sqft}</div>
          <div><span className="opacity-60">Clearance:</span> {levelInfo.clearance}</div>
        </div>
      </div>

      {/* Overview Grid */}
      <div className="bg-secondary/50 border border-main rounded-xl p-5">
        <div className="grid grid-cols-2 gap-4">
          <InfoRow label="Affected Area" value={a.affectedAreaSqft ? `${a.affectedAreaSqft} sqft` : 'TBD'} />
          <InfoRow label="Suspected Cause" value={CAUSE_LABELS[a.suspectedCause ?? ''] ?? 'Unknown'} />
          <InfoRow label="Moisture Source" value={a.moistureSourceStatus === 'active_leak' ? 'Active Leak' : a.moistureSourceStatus === 'resolved' ? 'Resolved' : 'Unknown'} />
          <InfoRow label="Occupancy" value={a.occupancyStatus ? a.occupancyStatus.charAt(0).toUpperCase() + a.occupancyStatus.slice(1) : 'Unknown'} />
          <InfoRow label="PPE Required" value={levelInfo.ppe.join(', ')} />
          <InfoRow label="Assessment Date" value={fmtDate(a.assessmentDate)} />
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-4 gap-3">
        <MiniStat label="Readings" value={moistureReadings.length} />
        <MiniStat label="Lab Samples" value={labSamples.length} />
        <MiniStat label="Equipment" value={equipment.length} />
        <MiniStat label="Plans" value={remediationPlans.length} />
      </div>

      {/* Visible Mold Types */}
      {Array.isArray(a.visibleMoldType) && a.visibleMoldType.length > 0 && (
        <div className="bg-secondary/50 border border-main rounded-xl p-4">
          <h3 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2">Visible Mold Types</h3>
          <div className="flex flex-wrap gap-2">
            {a.visibleMoldType.map((mt, i) => (
              <span key={i} className="text-xs bg-secondary text-main px-2 py-1 rounded">{String(mt)}</span>
            ))}
          </div>
        </div>
      )}

      {/* Remediation Plan Summary */}
      {activePlan && (
        <div className="bg-secondary/50 border border-main rounded-xl p-4">
          <h3 className="text-xs font-semibold text-muted uppercase tracking-wider mb-3">Active Remediation Plan</h3>
          <div className="flex items-center justify-between mb-2">
            <span className={`text-xs font-medium px-2 py-0.5 rounded border ${STATUS_COLORS[activePlan.status] ?? ''}`}>
              {STATUS_LABELS[activePlan.status] ?? activePlan.status}
            </span>
            {activePlan.containmentType && (
              <span className="text-xs text-muted">{activePlan.containmentType} containment</span>
            )}
          </div>
          {activePlan.scopeDescription && (
            <p className="text-sm text-muted mt-1">{activePlan.scopeDescription}</p>
          )}
        </div>
      )}

      {/* Notes */}
      {a.overallNotes && (
        <div className="bg-secondary/50 border border-main rounded-xl p-4">
          <h3 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2">Notes</h3>
          <p className="text-sm text-muted whitespace-pre-wrap">{a.overallNotes}</p>
        </div>
      )}
    </div>
  );
}

// ── CONTAINMENT TAB ──

function ContainmentTab({ assessment: a }: { assessment: MoldAssessment }) {
  const level = (a.remediationLevel ?? 1) as IicrcLevel;
  const levelInfo = IICRC_LEVEL_INFO[level];
  const { plans } = useMoldRemediationPlans(a.id);
  const activePlan = plans.find((p) => p.status !== 'completed') ?? plans[0];
  const { deployments: equipment } = useMoldEquipment(activePlan?.id);

  // Containment calculations
  const sqft = a.affectedAreaSqft ?? 0;
  const estimatedRoomDimensions = useMemo(() => {
    if (sqft <= 0) return null;
    const side = Math.sqrt(sqft);
    const height = 8; // standard ceiling
    const wallSqft = side * 4 * height;
    const totalPolySqft = wallSqft + sqft; // walls + ceiling
    const polyRolls = Math.ceil(totalPolySqft / 400); // 10x40 roll = 400 sqft
    const roomVolume = sqft * height;
    const cfmRequired = (roomVolume * 4) / 60; // 4 ACH minimum
    const negAirMachines = Math.ceil(cfmRequired / 500); // standard 500 CFM unit
    return { side: Math.round(side), height, wallSqft: Math.round(wallSqft), totalPolySqft: Math.round(totalPolySqft), polyRolls, roomVolume: Math.round(roomVolume), cfmRequired: Math.round(cfmRequired), negAirMachines };
  }, [sqft]);

  return (
    <div className="space-y-4">
      {/* Containment Type */}
      <div className={cn('rounded-xl border p-5', LEVEL_COLORS[level])}>
        <h3 className="text-sm font-bold mb-2">Level {level} Containment Requirements</h3>
        <p className="text-sm opacity-80">{levelInfo.containment}</p>
        <p className="text-xs opacity-60 mt-1">Air Filtration: {levelInfo.airFiltration}</p>
      </div>

      {/* Containment Calculator */}
      {estimatedRoomDimensions && (
        <div className="bg-secondary/50 border border-main rounded-xl p-5">
          <h3 className="text-sm font-bold text-main mb-3 flex items-center gap-2">
            <Calculator size={14} />
            Containment Material Calculator
          </h3>
          <div className="grid grid-cols-2 gap-3 text-sm">
            <InfoRow label="Affected Area" value={`${sqft} sqft`} />
            <InfoRow label="Est. Room Dimensions" value={`${estimatedRoomDimensions.side}' x ${estimatedRoomDimensions.side}' x ${estimatedRoomDimensions.height}'`} />
            <InfoRow label="Wall Coverage Needed" value={`${estimatedRoomDimensions.wallSqft} sqft`} />
            <InfoRow label="Total Poly Required" value={`${estimatedRoomDimensions.totalPolySqft} sqft`} />
            <InfoRow label="Poly Rolls (10x40)" value={`${estimatedRoomDimensions.polyRolls} rolls`} />
            <InfoRow label="Room Volume" value={`${estimatedRoomDimensions.roomVolume} cu ft`} />
            <InfoRow label="CFM Required (4 ACH)" value={`${estimatedRoomDimensions.cfmRequired} CFM`} />
            <InfoRow label="Neg Air Machines (500 CFM)" value={`${estimatedRoomDimensions.negAirMachines} units`} />
          </div>

          {level >= 3 && (
            <div className="mt-3 rounded-lg bg-red-500/10 border border-red-500/20 p-3">
              <p className="text-xs text-red-400">
                Level 3 requires: Full poly enclosure sealed with tape, decontamination chamber at entry/exit, negative air pressure verified with manometer, HEPA exhaust vented outdoors
              </p>
            </div>
          )}
        </div>
      )}

      {/* PPE Requirements */}
      <div className="bg-secondary/50 border border-main rounded-xl p-5">
        <h3 className="text-sm font-bold text-main mb-3">PPE Requirements</h3>
        <div className="space-y-2">
          {levelInfo.ppe.map((item, i) => (
            <div key={i} className="flex items-center gap-2 text-sm text-main">
              <CheckCircle size={14} className="text-green-500 flex-shrink-0" />
              {item}
            </div>
          ))}
        </div>
      </div>

      {/* Equipment Deployed */}
      <div className="bg-secondary/50 border border-main rounded-xl p-5">
        <h3 className="text-sm font-bold text-main mb-3">Equipment Deployed ({equipment.length})</h3>
        {equipment.length === 0 ? (
          <p className="text-sm text-muted">No equipment deployed</p>
        ) : (
          <div className="space-y-2">
            {equipment.map((eq) => (
              <div key={eq.id} className="flex items-center justify-between bg-secondary/50 rounded-lg p-3">
                <div>
                  <p className="text-sm text-main font-medium">{eq.equipmentType.replace(/_/g, ' ')}</p>
                  <p className="text-xs text-muted">
                    {eq.modelName || 'No model'} {eq.placementLocation ? `— ${eq.placementLocation}` : ''}
                  </p>
                </div>
                <Badge variant={eq.retrievedAt ? 'default' : 'info'}>
                  {eq.retrievedAt ? `Retrieved (${eq.runtimeHours ?? '?'}h)` : 'Active'}
                </Badge>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Containment Checklist */}
      <div className="bg-secondary/50 border border-main rounded-xl p-5">
        <h3 className="text-sm font-bold text-main mb-3">Containment Setup Checklist</h3>
        <div className="space-y-1.5">
          {[
            'Identify and stop moisture source',
            'Pre-containment air samples collected',
            'HVAC isolated in affected zone',
            'Poly sheeting installed on all openings',
            'All seams sealed with tape',
            'Negative air machine(s) installed',
            'Manometer reading verified (-5 to -20 Pa)',
            'Decon chamber set up at entry/exit',
            'Warning signage posted',
            'Workers donned in proper PPE',
          ].map((item, i) => (
            <div key={i} className="flex items-center gap-2 text-sm text-muted py-1">
              <div className="h-4 w-4 rounded border border-main flex-shrink-0" />
              {item}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ── MOISTURE TAB ──

function MoistureTab({ assessment: a }: { assessment: MoldAssessment }) {
  const { readings, loading } = useMoldMoistureReadings(a.id);
  const [expandedRoom, setExpandedRoom] = useState<string | null>(null);

  // Group by room
  const byRoom = useMemo(() => {
    const map = new Map<string, MoldMoistureReading[]>();
    for (const r of readings) {
      const existing = map.get(r.roomName) || [];
      existing.push(r);
      map.set(r.roomName, existing);
    }
    return Array.from(map.entries());
  }, [readings]);

  if (loading) {
    return <div className="flex justify-center py-12"><div className="animate-spin rounded-full h-6 w-6 border-b-2 border-white" /></div>;
  }

  return (
    <div className="space-y-4">
      {/* Moisture Source Info */}
      <div className={cn(
        'rounded-xl border p-4',
        a.moistureSourceStatus === 'active_leak' ? 'border-red-500/30 bg-red-500/5' :
        a.moistureSourceStatus === 'resolved' ? 'border-green-500/30 bg-green-500/5' :
        'border-main bg-surface'
      )}>
        <div className="flex items-center gap-2 mb-2">
          <Droplets size={16} className={
            a.moistureSourceStatus === 'active_leak' ? 'text-red-400' :
            a.moistureSourceStatus === 'resolved' ? 'text-green-400' : 'text-muted'
          } />
          <span className="text-sm font-bold text-main">
            Moisture Source: {a.moistureSourceStatus === 'active_leak' ? 'ACTIVE LEAK' : a.moistureSourceStatus === 'resolved' ? 'Resolved' : 'Unknown'}
          </span>
        </div>
        <p className="text-xs text-muted">
          Cause: {CAUSE_LABELS[a.suspectedCause ?? ''] ?? 'Unknown'}
        </p>
        {a.moistureSourceStatus === 'active_leak' && (
          <div className="mt-2 rounded-lg bg-red-500/10 border border-red-500/20 p-2">
            <p className="text-xs text-red-400">
              Moisture source must be stopped before remediation can begin. Document source location, extent, and path of migration.
            </p>
          </div>
        )}
      </div>

      {/* Readings Summary */}
      <div className="grid grid-cols-3 gap-3">
        <MiniStat label="Total Readings" value={readings.length} />
        <MiniStat label="Rooms Mapped" value={byRoom.length} />
        <MiniStat label="Concerns" value={readings.filter((r) => r.severity === 'concern' || r.severity === 'saturation').length} />
      </div>

      {/* Readings by Room */}
      {byRoom.length === 0 ? (
        <div className="bg-secondary/50 border border-main rounded-xl p-8 text-center">
          <Droplets size={32} className="mx-auto text-muted opacity-50 mb-3" />
          <p className="text-sm text-muted">No moisture readings recorded</p>
          <p className="text-xs text-muted mt-1">Document readings at each monitoring point to track moisture levels over time</p>
        </div>
      ) : (
        byRoom.map(([room, roomReadings]) => {
          const isExpanded = expandedRoom === room;
          const latestReading = roomReadings[0];
          const hasConcern = roomReadings.some((r) => r.severity === 'concern' || r.severity === 'saturation');

          return (
            <div key={room} className="bg-secondary/50 border border-main rounded-xl overflow-hidden">
              <button
                className="w-full text-left p-4 flex items-center justify-between hover:bg-secondary/50 transition-colors"
                onClick={() => setExpandedRoom(isExpanded ? null : room)}
              >
                <div className="flex items-center gap-3">
                  <MapPin size={14} className={hasConcern ? 'text-yellow-400' : 'text-muted'} />
                  <div>
                    <p className="text-sm font-medium text-main">{room}</p>
                    <p className="text-xs text-muted">{roomReadings.length} reading{roomReadings.length !== 1 ? 's' : ''}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {hasConcern && <Badge variant="warning">Elevated</Badge>}
                  <span className="text-sm font-bold text-main">{latestReading.readingValue}{latestReading.readingUnit}</span>
                  {isExpanded ? <ChevronDown size={14} className="text-muted" /> : <ChevronRight size={14} className="text-muted" />}
                </div>
              </button>

              {isExpanded && (
                <div className="border-t border-main p-4 space-y-2">
                  {roomReadings.map((r) => (
                    <div key={r.id} className="flex items-center justify-between bg-secondary/30 rounded-lg p-3">
                      <div>
                        <p className="text-xs text-muted">{r.locationDetail ?? r.readingType.replace(/_/g, ' ')}</p>
                        <p className="text-xs text-muted">{r.meterModel ? `Meter: ${r.meterModel}` : ''} {fmtDate(r.createdAt)}</p>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-bold text-main">{r.readingValue}{r.readingUnit}</span>
                        {r.severity && (
                          <span className={cn(
                            'text-xs px-2 py-0.5 rounded',
                            r.severity === 'normal' ? 'bg-green-500/15 text-green-400' :
                            r.severity === 'concern' ? 'bg-yellow-500/15 text-yellow-400' :
                            'bg-red-500/15 text-red-400'
                          )}>
                            {r.severity}
                          </span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          );
        })
      )}

      {/* Moisture Reference */}
      <div className="bg-secondary/50 border border-main rounded-xl p-4">
        <h3 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2">Moisture Content Reference</h3>
        <div className="space-y-1 text-xs text-muted">
          <div className="flex justify-between"><span>Drywall (normal)</span><span className="text-green-400">{'<'} 1% MC</span></div>
          <div className="flex justify-between"><span>Wood framing (normal)</span><span className="text-green-400">6-12% MC</span></div>
          <div className="flex justify-between"><span>Concrete (normal)</span><span className="text-green-400">{'<'} 4% MC</span></div>
          <div className="flex justify-between"><span>Concern threshold</span><span className="text-yellow-400">{'>'}15% MC</span></div>
          <div className="flex justify-between"><span>Mold growth likely</span><span className="text-red-400">{'>'}20% MC sustained 48h+</span></div>
        </div>
      </div>
    </div>
  );
}

// ── CLEARANCE TAB ──

function ClearanceTab({ assessment: a }: { assessment: MoldAssessment }) {
  const { plans } = useMoldRemediationPlans(a.id);
  const activePlan = plans[0];
  const { tests: clearanceTests } = useMoldClearanceTests(activePlan?.id, a.id);
  const { samples: labSamples } = useMoldLabSamples(a.id);
  const level = (a.remediationLevel ?? 1) as IicrcLevel;

  return (
    <div className="space-y-4">
      {/* Clearance Workflow */}
      <div className="bg-secondary/50 border border-main rounded-xl p-5">
        <h3 className="text-sm font-bold text-main mb-3">Clearance Testing Workflow</h3>
        <div className="relative">
          {[
            { step: 1, label: 'Pre-Remediation Samples', description: 'Air + surface samples to establish baseline', done: labSamples.some((s) => s.status !== 'pending') },
            { step: 2, label: 'Remediation', description: 'Complete all removal and cleaning per protocol', done: activePlan?.status === 'completed' },
            { step: 3, label: 'Post-Remediation Samples', description: 'Air + surface samples after remediation', done: clearanceTests.length > 0 },
            { step: 4, label: 'Lab Results', description: 'Review spore counts against baseline', done: labSamples.some((s) => s.status === 'results_in') },
            { step: 5, label: 'Clearance Determination', description: 'Pass/fail/conditional based on all criteria', done: clearanceTests.some((t) => t.overallResult != null) },
          ].map((step, i) => (
            <div key={i} className="flex items-start gap-3 mb-4 last:mb-0">
              <div className={cn(
                'flex h-7 w-7 items-center justify-center rounded-full text-xs font-bold flex-shrink-0',
                step.done ? 'bg-green-500 text-white' : 'bg-secondary text-muted'
              )}>
                {step.done ? <CheckCircle size={14} /> : step.step}
              </div>
              <div>
                <p className={cn('text-sm font-medium', step.done ? 'text-green-400' : 'text-main')}>{step.label}</p>
                <p className="text-xs text-muted">{step.description}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Lab Samples */}
      <div className="bg-secondary/50 border border-main rounded-xl p-5">
        <h3 className="text-sm font-bold text-main mb-3 flex items-center gap-2">
          <Microscope size={14} />
          Lab Samples ({labSamples.length})
        </h3>
        {labSamples.length === 0 ? (
          <p className="text-sm text-muted text-center py-4">No samples collected</p>
        ) : (
          <div className="space-y-2">
            {labSamples.map((s) => (
              <div key={s.id} className="bg-secondary/50 rounded-lg p-3">
                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-main">{s.sampleType.replace(/_/g, ' ')}</span>
                    <span className="text-xs text-muted">@ {s.sampleLocation}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    {s.passFail ? (
                      <Badge variant={s.passFail === 'pass' ? 'success' : 'error'}>
                        {s.passFail.toUpperCase()}
                      </Badge>
                    ) : (
                      <Badge variant="secondary">{s.status.replace(/_/g, ' ')}</Badge>
                    )}
                  </div>
                </div>
                <div className="grid grid-cols-3 gap-2 mt-2 text-xs text-muted">
                  <div>Collected: {fmtDate(s.dateCollected)}</div>
                  {s.labName && <div>Lab: {s.labName}</div>}
                  {s.sporeCount != null && (
                    <div>Spores: {s.sporeCount} {s.sporeCountUnit}</div>
                  )}
                </div>
                {s.speciesFound && Array.isArray(s.speciesFound) && s.speciesFound.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-2">
                    {s.speciesFound.map((sp, i) => (
                      <span key={i} className="text-xs bg-secondary text-main px-2 py-0.5 rounded">{String(sp)}</span>
                    ))}
                  </div>
                )}
                {s.resultsNotes && (
                  <p className="text-xs text-muted mt-1">{s.resultsNotes}</p>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Clearance Tests */}
      <div className="bg-secondary/50 border border-main rounded-xl p-5">
        <h3 className="text-sm font-bold text-main mb-3">Clearance Tests ({clearanceTests.length})</h3>
        {clearanceTests.length === 0 ? (
          <p className="text-sm text-muted text-center py-4">No clearance tests performed</p>
        ) : (
          <div className="space-y-3">
            {clearanceTests.map((ct) => (
              <div key={ct.id} className={cn(
                'rounded-lg border p-4',
                ct.overallResult === 'pass' ? 'border-green-500/30 bg-green-500/5' :
                ct.overallResult === 'fail' ? 'border-red-500/30 bg-red-500/5' :
                'border-main bg-secondary/50'
              )}>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-main">Clearance — {fmtDate(ct.clearanceDate)}</span>
                  {ct.overallResult && (
                    <Badge variant={ct.overallResult === 'pass' ? 'success' : ct.overallResult === 'fail' ? 'error' : 'warning'}>
                      {ct.overallResult.toUpperCase()}
                    </Badge>
                  )}
                </div>
                <div className="grid grid-cols-4 gap-2 text-xs">
                  <ClearanceItem label="Visual" pass={ct.visualPass} />
                  <ClearanceItem label="Moisture" pass={ct.moisturePass} />
                  <ClearanceItem label="Air Quality" pass={ct.airQualityPass} />
                  <ClearanceItem label="Odor" pass={ct.odorPass} />
                </div>
                {ct.assessorName && (
                  <p className="text-xs text-muted mt-2">
                    Assessor: {ct.assessorName} {ct.assessorCompany ? `(${ct.assessorCompany})` : ''} {ct.assessorLicense ? `License: ${ct.assessorLicense}` : ''}
                  </p>
                )}
                {ct.certificateNumber && (
                  <p className="text-xs text-muted">Certificate: {ct.certificateNumber}</p>
                )}
                {ct.notes && <p className="text-xs text-muted mt-1">{ct.notes}</p>}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Clearance Criteria Reference */}
      <div className="bg-secondary/50 border border-main rounded-xl p-4">
        <h3 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2">Clearance Criteria — Level {level}</h3>
        <div className="space-y-1 text-xs text-muted">
          <p>1. All visible mold removed — no remaining growth on surfaces</p>
          <p>2. Moisture readings at or below normal for material type</p>
          <p>3. No musty odor detected in remediated area</p>
          {level >= 2 && <p>4. Air sample spore counts below outdoor baseline (or normal background)</p>}
          {level >= 3 && <p>5. Third-party clearance by independent assessor (not the remediator)</p>}
          {level >= 3 && <p>6. Certificate of completion issued with lab reports attached</p>}
        </div>
      </div>
    </div>
  );
}

function ClearanceItem({ label, pass }: { label: string; pass: boolean | null }) {
  return (
    <div className="text-center">
      <p className="text-muted mb-1">{label}</p>
      {pass === true ? (
        <CheckCircle size={16} className="mx-auto text-green-400" />
      ) : pass === false ? (
        <XCircle size={16} className="mx-auto text-red-400" />
      ) : (
        <div className="h-4 w-4 mx-auto rounded-full bg-secondary" />
      )}
    </div>
  );
}

// ── PROTOCOL TAB ──

function ProtocolTab({ assessment: a }: { assessment: MoldAssessment }) {
  const level = (a.remediationLevel ?? 1) as IicrcLevel;
  const levelInfo = IICRC_LEVEL_INFO[level];
  const { plans } = useMoldRemediationPlans(a.id);
  const activePlan = plans[0];

  // Auto-generate protocol based on level and assessment data
  const protocolSections = useMemo(() => {
    const sections: { title: string; items: string[] }[] = [];

    // Pre-remediation
    sections.push({
      title: 'Pre-Remediation',
      items: [
        'Complete moisture source identification and documentation',
        a.moistureSourceStatus === 'active_leak'
          ? 'STOP MOISTURE SOURCE before proceeding — leak is currently active'
          : 'Verify moisture source has been resolved',
        level >= 2 ? 'Collect pre-remediation air samples (2 interior + 1 outdoor baseline)' : 'Document pre-remediation conditions with photos',
        'Establish containment per IICRC S520 guidelines',
        `Set up PPE station: ${levelInfo.ppe.join(', ')}`,
      ],
    });

    // Containment
    sections.push({
      title: 'Containment Setup',
      items: level >= 3 ? [
        'Isolate HVAC in affected zone',
        'Install full poly enclosure — 6 mil poly, double-layered at entry',
        'Seal all seams with tape — no gaps',
        'Install decontamination chamber at entry/exit',
        `Install negative air machine(s) — minimum ${Math.ceil((a.affectedAreaSqft ?? 100) * 8 * 4 / 60 / 500)} unit(s)`,
        'Verify negative pressure with manometer (-5 to -20 Pa)',
        'Post warning signage at all entry points',
      ] : level >= 2 ? [
        'Cover all openings with poly sheeting',
        'HEPA vacuum perimeter of work area',
        'Install HEPA air scrubber',
        'Mist work area to suppress spores',
      ] : [
        'Mist affected area to suppress airborne spores',
        'Work in well-ventilated area if possible',
      ],
    });

    // Removal
    const materialsToRemove = activePlan?.materialsToRemove ?? a.affectedMaterials ?? [];
    sections.push({
      title: 'Material Removal',
      items: [
        'Remove all visibly mold-damaged porous materials (drywall, insulation, carpet)',
        'Cut drywall minimum 2 feet beyond visible mold growth',
        'HEPA vacuum all exposed framing and non-porous surfaces',
        'Apply antimicrobial treatment to all exposed surfaces',
        materialsToRemove.length > 0
          ? `Specific materials: ${materialsToRemove.map(String).join(', ')}`
          : 'Document all materials removed with photos',
        'Double-bag all removed materials in 6-mil poly bags',
        'Seal bags before removing from containment',
        'HEPA vacuum containment after all removal is complete',
      ],
    });

    // Clearance
    sections.push({
      title: 'Post-Remediation Clearance',
      items: level >= 3 ? [
        'Engage third-party assessor for clearance testing',
        'Collect post-remediation air samples at same locations as pre-remediation',
        'Visual inspection — all surfaces clean, no remaining mold',
        'Moisture readings at or below normal for material type',
        'No musty odor in remediated area',
        'Lab results: indoor spore counts below outdoor baseline',
        'Obtain clearance certificate before reconstruction',
      ] : level >= 2 ? [
        'Visual inspection — all mold removed',
        'Moisture readings verify normal levels',
        'Optional: post-remediation air samples',
        'Document completion with photos',
      ] : [
        'Visual inspection confirms all mold removed',
        'Area is dry — moisture levels normal',
        'Document with photos',
      ],
    });

    return sections;
  }, [a, level, levelInfo.ppe, activePlan]);

  return (
    <div className="space-y-4">
      {/* Protocol Header */}
      <div className="bg-secondary/50 border border-main rounded-xl p-5">
        <h3 className="text-sm font-bold text-main mb-1">Remediation Protocol — Level {level}</h3>
        <p className="text-xs text-muted">
          Auto-generated based on IICRC S520 standards for {a.affectedAreaSqft ?? 0} sqft,{' '}
          {CAUSE_LABELS[a.suspectedCause ?? ''] ?? 'unknown cause'}, {a.occupancyStatus ?? 'unknown'} occupancy
        </p>
      </div>

      {/* Protocol Sections */}
      {protocolSections.map((section, si) => (
        <div key={si} className="bg-secondary/50 border border-main rounded-xl p-5">
          <h4 className="text-sm font-bold text-main mb-3">{si + 1}. {section.title}</h4>
          <div className="space-y-2">
            {section.items.map((item, ii) => (
              <div key={ii} className="flex items-start gap-2 text-sm text-muted">
                <div className="h-4 w-4 mt-0.5 rounded border border-main flex-shrink-0" />
                <span>{item}</span>
              </div>
            ))}
          </div>
        </div>
      ))}

      {/* Active Plan Status */}
      {activePlan && (
        <div className="bg-secondary/50 border border-main rounded-xl p-5">
          <h4 className="text-sm font-bold text-main mb-2">Plan Status</h4>
          <div className="flex items-center justify-between">
            <span className={cn('text-xs font-medium px-2 py-0.5 rounded border', STATUS_COLORS[activePlan.status] ?? '')}>
              {STATUS_LABELS[activePlan.status] ?? activePlan.status}
            </span>
            <div className="flex items-center gap-3 text-xs text-muted">
              {activePlan.startedAt && <span>Started: {fmtDate(activePlan.startedAt)}</span>}
              {activePlan.completedAt && <span>Completed: {fmtDate(activePlan.completedAt)}</span>}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ── LICENSING TAB ──

function LicensingTab({ licensing }: { licensing: MoldStateLicensing[] }) {
  const [search, setSearch] = useState('');

  const filtered = licensing.filter((s) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return s.stateName.toLowerCase().includes(q) || s.stateCode.toLowerCase().includes(q);
  });

  return (
    <div className="space-y-4">
      <div className="bg-secondary/50 border border-main rounded-xl p-5">
        <h3 className="text-sm font-bold text-main mb-1">State Licensing Requirements</h3>
        <p className="text-xs text-muted mb-3">
          Mold remediation licensing requirements vary by state. Check your operating state before beginning work.
        </p>
        <SearchInput
          placeholder="Search by state..."
          value={search}
          onChange={(v) => setSearch(v)}
        />
      </div>

      {filtered.length === 0 ? (
        <div className="text-center py-8 text-muted text-sm">
          {licensing.length === 0 ? 'Licensing data not available' : 'No matching states'}
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map((s) => (
            <div key={s.id} className="bg-secondary/50 border border-main rounded-xl p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-medium text-main">{s.stateName} ({s.stateCode})</span>
                <Badge variant={s.licenseRequired ? 'warning' : 'success'}>
                  {s.licenseRequired ? 'License Required' : 'No License Required'}
                </Badge>
              </div>
              {s.licenseRequired && (
                <div className="grid grid-cols-2 gap-2 text-xs text-muted mt-2">
                  {s.issuingAgency && <div>Agency: {s.issuingAgency}</div>}
                  {s.costRange && <div>Cost: {s.costRange}</div>}
                  {s.renewalPeriod && <div>Renewal: {s.renewalPeriod}</div>}
                  {s.ceRequirements && <div>CE: {s.ceRequirements}</div>}
                </div>
              )}
              {s.notes && <p className="text-xs text-muted mt-2">{s.notes}</p>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ── Shared ──

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-[10px] text-muted uppercase tracking-wider">{label}</p>
      <p className="text-sm text-main">{value}</p>
    </div>
  );
}

function MiniStat({ label, value }: { label: string; value: number }) {
  return (
    <div className="bg-secondary/50 border border-main rounded-xl p-3 text-center">
      <p className="text-lg font-bold text-main">{value}</p>
      <p className="text-[10px] text-muted">{label}</p>
    </div>
  );
}
