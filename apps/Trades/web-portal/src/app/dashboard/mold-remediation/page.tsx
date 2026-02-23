'use client';

import { useState } from 'react';
import { useTranslation } from '@/lib/translations';
import {
  useMoldAssessments,
  useMoldLabSamples,
  useMoldStateLicensing,
  useMoldRemediationPlans,
  useMoldEquipment,
  useMoldMoistureReadings,
  type MoldAssessment,
  type MoldLabSample,
  type MoldStateLicensing,
  type MoldEquipmentDeployment,
  type MoldMoistureReading,
} from '@/lib/hooks/use-mold-remediation';
import { SearchInput } from '@/components/ui/input';

// ── IICRC S520 Level Reference ──

type IicrcLevel = 1 | 2 | 3;

const IICRC_LEVEL_INFO: Record<IicrcLevel, { label: string; ppe: string; description: string }> = {
  1: {
    label: 'Level 1 — Small Isolated Area',
    ppe: 'N95, gloves, goggles',
    description: 'Up to 10 sq ft. Maintenance worker with training.',
  },
  2: {
    label: 'Level 2 — Mid-Size Isolated Area',
    ppe: 'N95/half-face, gloves, goggles, disposable coveralls',
    description: '10-30 sq ft. Trained remediation personnel required.',
  },
  3: {
    label: 'Level 3 — Large Area',
    ppe: 'Full-face respirator, Tyvek suit, gloves, boot covers',
    description: '30+ sq ft. Full containment, HEPA filtration, professional remediator.',
  },
};

// ── Status Helpers ──

const STATUS_COLORS: Record<string, string> = {
  planned: 'bg-zinc-500/15 text-zinc-400 border-zinc-500/30',
  in_progress: 'bg-blue-500/15 text-blue-400 border-blue-500/30',
  completed: 'bg-green-500/15 text-green-400 border-green-500/30',
  on_hold: 'bg-yellow-500/15 text-yellow-400 border-yellow-500/30',
};

const STATUS_LABELS: Record<string, string> = {
  planned: 'Planned',
  in_progress: 'In Progress',
  completed: 'Completed',
  on_hold: 'On Hold',
};

const LEVEL_COLORS: Record<IicrcLevel, string> = {
  1: 'bg-green-500/15 text-green-400 border-green-500/30',
  2: 'bg-yellow-500/15 text-yellow-400 border-yellow-500/30',
  3: 'bg-red-500/15 text-red-400 border-red-500/30',
};

const CAUSE_LABELS: Record<string, string> = {
  water_intrusion: 'Water Intrusion',
  hvac_issue: 'HVAC Issue',
  plumbing_leak: 'Plumbing Leak',
  flooding: 'Flooding',
  condensation: 'Condensation',
  unknown: 'Unknown',
  roof_leak: 'Roof Leak',
  foundation_crack: 'Foundation Crack',
};

function formatDate(iso: string | null | undefined): string {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
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

  // Stats
  const totalAssessments = assessments.length;
  const level1 = assessments.filter((a) => a.remediationLevel === 1).length;
  const level2 = assessments.filter((a) => a.remediationLevel === 2).length;
  const level3 = assessments.filter((a) => a.remediationLevel === 3).length;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white" />
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
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-white">{t('moldRemediation.title')}</h1>
        <p className="text-sm text-zinc-400 mt-1">IICRC S520 compliant assessments, containment, air sampling, and clearance</p>
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
                  : 'text-zinc-400 border-zinc-700 hover:border-zinc-600'
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
        <div className="col-span-5 space-y-3">
          {filtered.length === 0 ? (
            <div className="text-center py-12 text-zinc-500">
              <p className="text-sm">{t('moldRemediation.noRecords')}</p>
            </div>
          ) : (
            filtered.map((a) => (
              <button
                key={a.id}
                onClick={() => setSelectedId(a.id)}
                className={`w-full text-left p-4 rounded-xl border transition-colors ${
                  selectedId === a.id
                    ? 'bg-zinc-800 border-zinc-600'
                    : 'bg-zinc-900 border-zinc-800 hover:border-zinc-700'
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
                      : 'bg-zinc-500/15 text-zinc-400 border-zinc-500/30'
                  }`}>
                    {a.moistureSourceStatus === 'active_leak' ? 'Active Leak' : a.moistureSourceStatus === 'resolved' ? 'Resolved' : 'Unknown Source'}
                  </span>
                </div>
                <div className="text-sm text-white font-medium">
                  {CAUSE_LABELS[a.suspectedCause ?? ''] ?? 'Unknown Cause'} — {a.occupancyStatus ?? 'Unknown'}
                </div>
                <div className="flex items-center gap-3 mt-1 text-xs text-zinc-500">
                  <span>{a.affectedAreaSqft ? `${a.affectedAreaSqft} sqft` : 'Area TBD'}</span>
                  <span>{formatDate(a.assessmentDate)}</span>
                </div>
              </button>
            ))
          )}
        </div>

        {/* Detail Panel */}
        <div className="col-span-7">
          {selected ? (
            <AssessmentDetail assessment={selected} licensing={licensing} />
          ) : (
            <div className="flex items-center justify-center h-96 rounded-xl bg-zinc-900 border border-zinc-800">
              <p className="text-sm text-zinc-500">Select an assessment to view details</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Components ──

function StatCard({ label, value, color = 'text-white' }: { label: string; value: number; color?: string }) {
  return (
    <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
      <p className="text-xs text-zinc-500 mb-1">{label}</p>
      <p className={`text-2xl font-bold ${color}`}>{value}</p>
    </div>
  );
}

function AssessmentDetail({
  assessment: a,
  licensing,
}: {
  assessment: MoldAssessment;
  licensing: MoldStateLicensing[];
}) {
  const { t } = useTranslation();
  const { samples: labSamples } = useMoldLabSamples(a.id);
  const { plans: remediationPlans } = useMoldRemediationPlans(a.id);
  const { readings: moistureReadings } = useMoldMoistureReadings(a.id);
  const activePlan = remediationPlans.find((p) => p.status !== 'completed') ?? remediationPlans[0];
  const { deployments: equipment } = useMoldEquipment(activePlan?.id);

  const level = (a.remediationLevel ?? 1) as IicrcLevel;
  const levelInfo = IICRC_LEVEL_INFO[level];

  return (
    <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-bold text-white">
            {CAUSE_LABELS[a.suspectedCause ?? ''] ?? 'Unknown'} — Level {level}
          </h2>
          <p className="text-xs text-zinc-500 mt-1">{levelInfo.label}</p>
        </div>
        <span className={`text-xs font-semibold px-2 py-0.5 rounded border ${LEVEL_COLORS[level]}`}>
          Level {level}
        </span>
      </div>

      {/* Overview Grid */}
      <div className="grid grid-cols-2 gap-4">
        <InfoRow label={t('moisture.affectedArea')} value={a.affectedAreaSqft ? `${a.affectedAreaSqft} sqft` : 'TBD'} />
        <InfoRow label="Suspected Cause" value={CAUSE_LABELS[a.suspectedCause ?? ''] ?? 'Unknown'} />
        <InfoRow label="Moisture Source" value={a.moistureSourceStatus === 'active_leak' ? 'Active Leak' : a.moistureSourceStatus === 'resolved' ? 'Resolved' : 'Unknown'} />
        <InfoRow label={t('dashboard.occupancy')} value={a.occupancyStatus ? a.occupancyStatus.charAt(0).toUpperCase() + a.occupancyStatus.slice(1) : 'Unknown'} />
        <InfoRow label="PPE Required" value={levelInfo.ppe} />
        <InfoRow label="Assessment Date" value={formatDate(a.assessmentDate)} />
      </div>

      {/* Visible Mold Types */}
      {Array.isArray(a.visibleMoldType) && a.visibleMoldType.length > 0 && (
        <div>
          <h3 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-2">Visible Mold Types</h3>
          <div className="flex flex-wrap gap-2">
            {a.visibleMoldType.map((mt, i) => (
              <span key={i} className="text-xs bg-zinc-800 text-zinc-300 px-2 py-1 rounded">{String(mt)}</span>
            ))}
          </div>
        </div>
      )}

      {/* Moisture Readings */}
      {moistureReadings.length > 0 && (
        <div>
          <h3 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-3">
            Moisture Readings ({moistureReadings.length})
          </h3>
          <div className="space-y-2">
            {moistureReadings.slice(0, 8).map((r: MoldMoistureReading) => (
              <div key={r.id} className="bg-zinc-800/50 rounded-lg p-3 flex items-center justify-between">
                <div>
                  <p className="text-sm text-white font-medium">{r.roomName}</p>
                  <p className="text-xs text-zinc-500">{r.locationDetail ?? r.readingType}</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-sm font-semibold text-white">{r.readingValue}{r.readingUnit}</span>
                  {r.severity && (
                    <span className={`text-xs px-2 py-0.5 rounded ${
                      r.severity === 'normal' ? 'bg-green-500/15 text-green-400' :
                      r.severity === 'concern' ? 'bg-yellow-500/15 text-yellow-400' :
                      'bg-red-500/15 text-red-400'
                    }`}>
                      {r.severity}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Remediation Plan */}
      {activePlan && (
        <div>
          <h3 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-3">Remediation Plan</h3>
          <div className="bg-zinc-800/50 rounded-lg p-4">
            <div className="flex items-center justify-between mb-2">
              <span className={`text-xs font-medium px-2 py-0.5 rounded border ${STATUS_COLORS[activePlan.status] ?? ''}`}>
                {STATUS_LABELS[activePlan.status] ?? activePlan.status}
              </span>
              {activePlan.containmentType && (
                <span className="text-xs text-zinc-400">{activePlan.containmentType} containment</span>
              )}
            </div>
            {activePlan.scopeDescription && (
              <p className="text-sm text-zinc-400 mt-1">{activePlan.scopeDescription}</p>
            )}
          </div>
        </div>
      )}

      {/* Equipment & Lab Samples */}
      <div className="grid grid-cols-2 gap-4">
        <div>
          <h3 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-2">
            Equipment ({equipment.length})
          </h3>
          {equipment.length === 0 ? (
            <p className="text-xs text-zinc-600">None deployed</p>
          ) : (
            <div className="space-y-1">
              {equipment.map((eq: MoldEquipmentDeployment) => (
                <div key={eq.id} className="text-xs text-zinc-400 flex items-center gap-1">
                  <span className="w-1 h-1 rounded-full bg-blue-400" />
                  {eq.equipmentType.replace(/_/g, ' ')} {eq.modelName ? `(${eq.modelName})` : ''}
                </div>
              ))}
            </div>
          )}
        </div>
        <div>
          <h3 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-2">
            Lab Samples ({labSamples.length})
          </h3>
          {labSamples.length === 0 ? (
            <p className="text-xs text-zinc-600">No samples collected</p>
          ) : (
            <div className="space-y-1">
              {labSamples.map((s: MoldLabSample) => (
                <div key={s.id} className="text-xs text-zinc-400 flex items-center justify-between">
                  <div className="flex items-center gap-1">
                    <span className="w-1 h-1 rounded-full bg-purple-400" />
                    {s.sampleType.replace(/_/g, ' ')} — {s.sampleLocation}
                  </div>
                  {s.passFail ? (
                    <span className={`font-bold ${s.passFail === 'pass' ? 'text-green-400' : 'text-red-400'}`}>
                      {s.passFail.toUpperCase()}
                    </span>
                  ) : (
                    <span className="text-zinc-500">{s.status}</span>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Notes */}
      {a.overallNotes && (
        <div>
          <h3 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-2">{t('common.notes')}</h3>
          <p className="text-sm text-zinc-400">{a.overallNotes}</p>
        </div>
      )}
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-[10px] text-zinc-500 uppercase tracking-wider">{label}</p>
      <p className="text-sm text-zinc-300">{value}</p>
    </div>
  );
}
