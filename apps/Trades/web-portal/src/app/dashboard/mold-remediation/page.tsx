'use client';

import { useState } from 'react';
import {
  useMoldRemediation,
  useChainOfCustody,
  useStateRegulations,
  IICRC_LEVEL_INFO,
  type MoldAssessment,
  type IicrcLevel,
  type MoldClearanceStatus,
} from '@/lib/hooks/use-mold-remediation';
import { SearchInput } from '@/components/ui/input';

// ── Status Helpers ──

const STATUS_COLORS: Record<string, string> = {
  in_progress: 'bg-blue-500/15 text-blue-400 border-blue-500/30',
  pending_review: 'bg-yellow-500/15 text-yellow-400 border-yellow-500/30',
  remediation_active: 'bg-orange-500/15 text-orange-400 border-orange-500/30',
  awaiting_clearance: 'bg-purple-500/15 text-purple-400 border-purple-500/30',
  cleared: 'bg-green-500/15 text-green-400 border-green-500/30',
  failed_clearance: 'bg-red-500/15 text-red-400 border-red-500/30',
};

const STATUS_LABELS: Record<string, string> = {
  in_progress: 'In Progress',
  pending_review: 'Pending Review',
  remediation_active: 'Remediation Active',
  awaiting_clearance: 'Awaiting Clearance',
  cleared: 'Cleared',
  failed_clearance: 'Failed Clearance',
};

const CLEARANCE_COLORS: Record<MoldClearanceStatus, string> = {
  pending: 'text-yellow-400',
  sampling: 'text-blue-400',
  awaiting_results: 'text-orange-400',
  passed: 'text-green-400',
  failed: 'text-red-400',
  not_required: 'text-zinc-500',
};

const LEVEL_COLORS: Record<IicrcLevel, string> = {
  1: 'bg-green-500/15 text-green-400 border-green-500/30',
  2: 'bg-yellow-500/15 text-yellow-400 border-yellow-500/30',
  3: 'bg-red-500/15 text-red-400 border-red-500/30',
};

function formatDate(iso: string | null): string {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

// ── Main Page ──

export default function MoldRemediationPage() {
  const { assessments, loading, error } = useMoldRemediation();
  const { regulations } = useStateRegulations();
  const [searchQuery, setSearchQuery] = useState('');
  const [filterLevel, setFilterLevel] = useState<IicrcLevel | 'all'>('all');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const filtered = assessments.filter((a) => {
    if (filterLevel !== 'all' && a.iicrc_level !== filterLevel) return false;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      return (
        (a.mold_type ?? '').toLowerCase().includes(q) ||
        (a.moisture_source ?? '').toLowerCase().includes(q) ||
        (a.notes ?? '').toLowerCase().includes(q) ||
        a.job_id.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const selected = selectedId ? assessments.find((a) => a.id === selectedId) ?? null : null;

  // Stats
  const totalAssessments = assessments.length;
  const activeRemediation = assessments.filter((a) => a.assessment_status === 'remediation_active').length;
  const awaitingClearance = assessments.filter((a) => a.clearance_status === 'awaiting_results' || a.clearance_status === 'sampling').length;
  const cleared = assessments.filter((a) => a.clearance_status === 'passed').length;

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
        <h1 className="text-2xl font-bold text-white">Mold Remediation</h1>
        <p className="text-sm text-zinc-400 mt-1">IICRC S520 compliant assessments, containment, air sampling, and clearance</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <StatCard label="Total Assessments" value={totalAssessments} />
        <StatCard label="Active Remediation" value={activeRemediation} color="text-orange-400" />
        <StatCard label="Awaiting Clearance" value={awaitingClearance} color="text-purple-400" />
        <StatCard label="Cleared" value={cleared} color="text-green-400" />
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3">
        <div className="flex-1 max-w-sm">
          <SearchInput
            placeholder="Search by mold type, moisture source..."
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
              <p className="text-sm">No mold assessments found</p>
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
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded border ${LEVEL_COLORS[a.iicrc_level]}`}>
                    Level {a.iicrc_level}
                  </span>
                  <span className={`text-xs font-medium px-2 py-0.5 rounded border ${STATUS_COLORS[a.assessment_status] ?? ''}`}>
                    {STATUS_LABELS[a.assessment_status] ?? a.assessment_status}
                  </span>
                </div>
                <div className="text-sm text-white font-medium">
                  {a.mold_type ?? 'Unidentified mold'} — {a.moisture_source ?? 'Unknown source'}
                </div>
                <div className="flex items-center gap-3 mt-1 text-xs text-zinc-500">
                  <span>{a.affected_area_sqft ? `${a.affected_area_sqft} sqft` : 'Area TBD'}</span>
                  <span>•</span>
                  <span>{a.containment_type !== 'none' ? `${a.containment_type} containment` : 'No containment'}</span>
                  <span>•</span>
                  <span>{formatDate(a.created_at)}</span>
                </div>
                {a.air_sampling_required && (
                  <div className="flex items-center gap-1 mt-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-blue-400" />
                    <span className="text-xs text-blue-400">Air sampling required</span>
                  </div>
                )}
              </button>
            ))
          )}
        </div>

        {/* Detail Panel */}
        <div className="col-span-7">
          {selected ? (
            <AssessmentDetail assessment={selected} regulations={regulations} />
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
  regulations,
}: {
  assessment: MoldAssessment;
  regulations: { state_code: string; license_required: boolean; state_name: string }[];
}) {
  const { samples } = useChainOfCustody(a.id);
  const levelInfo = IICRC_LEVEL_INFO[a.iicrc_level];
  const sporeReduction = a.spore_count_before && a.spore_count_after && a.spore_count_before > 0
    ? ((a.spore_count_before - a.spore_count_after) / a.spore_count_before * 100)
    : null;

  return (
    <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-bold text-white">
            {a.mold_type ?? 'Unidentified'} — Level {a.iicrc_level}
          </h2>
          <p className="text-xs text-zinc-500 mt-1">{levelInfo.label}</p>
        </div>
        <div className="flex gap-2">
          <span className={`text-xs font-semibold px-2 py-0.5 rounded border ${LEVEL_COLORS[a.iicrc_level]}`}>
            Level {a.iicrc_level}
          </span>
          <span className={`text-xs font-medium px-2 py-0.5 rounded border ${STATUS_COLORS[a.assessment_status] ?? ''}`}>
            {STATUS_LABELS[a.assessment_status] ?? a.assessment_status}
          </span>
        </div>
      </div>

      {/* Overview Grid */}
      <div className="grid grid-cols-2 gap-4">
        <InfoRow label="Affected Area" value={a.affected_area_sqft ? `${a.affected_area_sqft} sqft` : 'TBD'} />
        <InfoRow label="Moisture Source" value={a.moisture_source ?? 'Unknown'} />
        <InfoRow label="Containment" value={`${a.containment_type}${a.negative_pressure ? ' + negative pressure' : ''}`} />
        <InfoRow label="Air Sampling" value={a.air_sampling_required ? 'Required' : 'Not required'} />
        <InfoRow label="PPE" value={levelInfo.ppe} />
        <InfoRow label="Created" value={formatDate(a.created_at)} />
      </div>

      {/* Clearance Status */}
      <div>
        <h3 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-3">Clearance</h3>
        <div className="bg-zinc-800/50 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className={`text-sm font-semibold ${CLEARANCE_COLORS[a.clearance_status]}`}>
                {a.clearance_status === 'awaiting_results' ? 'Awaiting Results' :
                 a.clearance_status === 'not_required' ? 'Not Required' :
                 a.clearance_status.charAt(0).toUpperCase() + a.clearance_status.slice(1)}
              </span>
            </div>
            {a.clearance_date && (
              <span className="text-xs text-zinc-500">{formatDate(a.clearance_date)}</span>
            )}
          </div>
          {a.clearance_inspector && (
            <p className="text-xs text-zinc-400 mt-1">
              Inspector: {a.clearance_inspector}{a.clearance_company ? ` (${a.clearance_company})` : ''}
            </p>
          )}

          {/* Spore Counts */}
          {(a.spore_count_before || a.spore_count_after) && (
            <div className="grid grid-cols-3 gap-3 mt-3">
              <div>
                <p className="text-[10px] text-zinc-500 uppercase">Pre-Remediation</p>
                <p className="text-sm font-semibold text-white">
                  {a.spore_count_before ? `${a.spore_count_before.toLocaleString()} sp/m³` : '—'}
                </p>
              </div>
              <div>
                <p className="text-[10px] text-zinc-500 uppercase">Post-Remediation</p>
                <p className="text-sm font-semibold text-white">
                  {a.spore_count_after ? `${a.spore_count_after.toLocaleString()} sp/m³` : '—'}
                </p>
              </div>
              {sporeReduction !== null && (
                <div>
                  <p className="text-[10px] text-zinc-500 uppercase">Reduction</p>
                  <p className={`text-sm font-bold ${sporeReduction >= 80 ? 'text-green-400' : 'text-red-400'}`}>
                    {sporeReduction.toFixed(1)}%
                  </p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Chain of Custody Samples */}
      <div>
        <h3 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-3">
          Chain of Custody ({samples.length} samples)
        </h3>
        {samples.length === 0 ? (
          <p className="text-sm text-zinc-600">No samples collected yet</p>
        ) : (
          <div className="space-y-2">
            {samples.map((s) => (
              <div key={s.id} className="bg-zinc-800/50 rounded-lg p-3 flex items-center justify-between">
                <div>
                  <p className="text-sm text-white font-medium">
                    {s.sample_type === 'tape_lift' ? 'Tape Lift' : s.sample_type.charAt(0).toUpperCase() + s.sample_type.slice(1)} Sample
                  </p>
                  <p className="text-xs text-zinc-500">{s.sample_location ?? 'No location'} • {s.lab_name ?? 'No lab'}</p>
                </div>
                <div className="flex items-center gap-2">
                  {s.pass_fail ? (
                    <span className={`text-xs font-bold px-2 py-0.5 rounded ${
                      s.pass_fail === 'pass' ? 'bg-green-500/15 text-green-400' : 'bg-red-500/15 text-red-400'
                    }`}>
                      {s.pass_fail.toUpperCase()}
                    </span>
                  ) : (
                    <span className="text-xs text-zinc-500">
                      {s.results_available_at ? 'Results in' :
                       s.lab_received_at ? 'At lab' :
                       s.shipped_to_lab_at ? 'Shipped' : 'Collected'}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Protocol Progress */}
      {a.protocol_steps.length > 0 && (
        <div>
          <h3 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-3">
            Protocol Progress
          </h3>
          <div className="bg-zinc-800/50 rounded-lg p-3">
            {(() => {
              const completed = a.protocol_steps.filter((s) => s.completed === true).length;
              const total = a.protocol_steps.length;
              const pct = total > 0 ? (completed / total) * 100 : 0;
              return (
                <div>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-zinc-400">{completed} of {total} steps</span>
                    <span className="text-zinc-500">{pct.toFixed(0)}%</span>
                  </div>
                  <div className="w-full bg-zinc-700 rounded-full h-2">
                    <div
                      className="bg-green-500 h-2 rounded-full transition-all"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                </div>
              );
            })()}
          </div>
        </div>
      )}

      {/* Material Removal + Equipment */}
      <div className="grid grid-cols-2 gap-4">
        <div>
          <h3 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-2">
            Materials Removed ({a.material_removal.length})
          </h3>
          {a.material_removal.length === 0 ? (
            <p className="text-xs text-zinc-600">None logged</p>
          ) : (
            <div className="space-y-1">
              {a.material_removal.map((m, i) => (
                <div key={i} className="text-xs text-zinc-400 flex items-center gap-1">
                  <span className="w-1 h-1 rounded-full bg-orange-400" />
                  {String(m.material ?? '')}
                </div>
              ))}
            </div>
          )}
        </div>
        <div>
          <h3 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-2">
            Equipment Deployed ({a.equipment_deployed.length})
          </h3>
          {a.equipment_deployed.length === 0 ? (
            <p className="text-xs text-zinc-600">None logged</p>
          ) : (
            <div className="space-y-1">
              {a.equipment_deployed.map((eq, i) => (
                <div key={i} className="text-xs text-zinc-400 flex items-center gap-1">
                  <span className="w-1 h-1 rounded-full bg-blue-400" />
                  {String(eq.equipment ?? '')}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Notes */}
      {a.notes && (
        <div>
          <h3 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-2">Notes</h3>
          <p className="text-sm text-zinc-400">{a.notes}</p>
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
