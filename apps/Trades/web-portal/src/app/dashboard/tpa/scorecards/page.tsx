'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import {
  Star,
  Plus,
  ArrowLeft,
  AlertTriangle,
  BarChart3,
  Save,
  X,
  ChevronDown,
  ChevronUp,
  Loader2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import {
  useTpaScorecards,
  SCORE_CATEGORIES,
  type TpaScorecardData,
  type CreateScorecardInput,
} from '@/lib/hooks/use-tpa-scorecards';
import { useTpaPrograms, type TpaProgramData } from '@/lib/hooks/use-tpa-programs';

// ============================================================================
// HELPERS
// ============================================================================

function scoreColor(score: number | null): string {
  if (score == null) return 'text-zinc-500';
  if (score >= 90) return 'text-emerald-400';
  if (score >= 75) return 'text-blue-400';
  if (score >= 60) return 'text-amber-400';
  return 'text-red-400';
}

function scoreBg(score: number | null): string {
  if (score == null) return 'bg-zinc-800';
  if (score >= 90) return 'bg-emerald-500/10';
  if (score >= 75) return 'bg-blue-500/10';
  if (score >= 60) return 'bg-amber-500/10';
  return 'bg-red-500/10';
}

function formatPeriod(start: string, end: string): string {
  const s = new Date(start);
  const e = new Date(end);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return `${months[s.getMonth()]} ${s.getFullYear()} - ${months[e.getMonth()]} ${e.getFullYear()}`;
}

// ============================================================================
// COMPONENT: Score Entry Modal
// ============================================================================

function NewScorecardModal({
  programs,
  onSave,
  onClose,
}: {
  programs: TpaProgramData[];
  onSave: (input: CreateScorecardInput) => Promise<boolean>;
  onClose: () => void;
}) {
  const [programId, setProgramId] = useState('');
  const [periodStart, setPeriodStart] = useState('');
  const [periodEnd, setPeriodEnd] = useState('');
  const [scores, setScores] = useState<Record<string, string>>({});
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!programId || !periodStart || !periodEnd) return;
    setSaving(true);
    const input: CreateScorecardInput = {
      tpaProgramId: programId,
      periodStart,
      periodEnd,
      notes: notes || undefined,
    };

    for (const cat of SCORE_CATEGORIES) {
      const val = scores[cat.key];
      if (val) {
        const num = parseFloat(val);
        if (!isNaN(num) && num >= 0 && num <= 100) {
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          (input as any)[cat.key] = num;
        }
      }
    }

    const ok = await onSave(input);
    setSaving(false);
    if (ok) onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4">
      <div className="bg-zinc-900 border border-zinc-800 rounded-lg w-full max-w-lg max-h-[85vh] overflow-y-auto">
        <div className="flex items-center justify-between p-4 border-b border-zinc-800">
          <h3 className="font-medium text-white">New Scorecard</h3>
          <Button variant="ghost" size="icon" onClick={onClose} className="h-7 w-7">
            <X className="h-4 w-4" />
          </Button>
        </div>
        <div className="p-4 space-y-4">
          {/* Program */}
          <div>
            <label className="text-xs text-zinc-400 block mb-1">TPA Program</label>
            <select
              className="w-full bg-zinc-800 border border-zinc-700 rounded px-3 py-2 text-sm text-white"
              value={programId}
              onChange={(e) => setProgramId(e.target.value)}
            >
              <option value="">Select program...</option>
              {programs.map((p) => (
                <option key={p.id} value={p.id}>{p.name}</option>
              ))}
            </select>
          </div>

          {/* Period */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs text-zinc-400 block mb-1">Period Start</label>
              <Input type="date" value={periodStart} onChange={(e) => setPeriodStart(e.target.value)} />
            </div>
            <div>
              <label className="text-xs text-zinc-400 block mb-1">Period End</label>
              <Input type="date" value={periodEnd} onChange={(e) => setPeriodEnd(e.target.value)} />
            </div>
          </div>

          {/* Score Categories */}
          <div>
            <label className="text-xs text-zinc-400 block mb-2">Scores (0-100)</label>
            <div className="grid grid-cols-2 gap-2">
              {SCORE_CATEGORIES.map((cat) => (
                <div key={cat.key} className="flex items-center gap-2">
                  <label className="text-[11px] text-zinc-400 min-w-[100px]">{cat.label}</label>
                  <Input
                    type="number"
                    min={0}
                    max={100}
                    step={0.1}
                    placeholder="--"
                    className="h-8 text-xs"
                    value={scores[cat.key] || ''}
                    onChange={(e) => setScores({ ...scores, [cat.key]: e.target.value })}
                  />
                </div>
              ))}
            </div>
          </div>

          {/* Notes */}
          <div>
            <label className="text-xs text-zinc-400 block mb-1">Notes</label>
            <textarea
              className="w-full bg-zinc-800 border border-zinc-700 rounded px-3 py-2 text-sm text-white resize-none h-20"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Additional context..."
            />
          </div>
        </div>

        <div className="flex items-center justify-end gap-2 p-4 border-t border-zinc-800">
          <Button variant="outline" size="sm" onClick={onClose}>Cancel</Button>
          <Button
            size="sm"
            onClick={handleSave}
            disabled={!programId || !periodStart || !periodEnd || saving}
          >
            {saving ? <Loader2 className="h-4 w-4 mr-1 animate-spin" /> : <Save className="h-4 w-4 mr-1" />}
            Save Scorecard
          </Button>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// COMPONENT: Scorecard Row (expandable)
// ============================================================================

function ScorecardRow({
  scorecard,
  programName,
}: {
  scorecard: TpaScorecardData;
  programName: string;
}) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="border-b border-zinc-800/50">
      <button
        className="w-full flex items-center gap-3 p-3 hover:bg-zinc-800/30 transition-colors text-left"
        onClick={() => setExpanded(!expanded)}
      >
        <div className={cn('p-1.5 rounded', scoreBg(scorecard.overallScore))}>
          <Star className={cn('h-4 w-4', scoreColor(scorecard.overallScore))} />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="text-sm font-medium text-white">{programName}</span>
            <Badge variant="secondary" className="text-[10px]">
              {formatPeriod(scorecard.periodStart, scorecard.periodEnd)}
            </Badge>
          </div>
          <div className="flex items-center gap-3 mt-0.5">
            <span className="text-[11px] text-zinc-400">
              {scorecard.totalAssignments} assignments
            </span>
            {scorecard.slaViolations > 0 && (
              <span className="text-[11px] text-red-400 flex items-center gap-0.5">
                <AlertTriangle className="h-3 w-3" />
                {scorecard.slaViolations} SLA violations
              </span>
            )}
          </div>
        </div>
        <div className="text-right mr-2">
          <span className={cn('text-lg font-bold', scoreColor(scorecard.overallScore))}>
            {scorecard.overallScore != null ? scorecard.overallScore.toFixed(1) : '--'}
          </span>
          <span className="text-[10px] text-zinc-500 block">overall</span>
        </div>
        {expanded ? (
          <ChevronUp className="h-4 w-4 text-zinc-400" />
        ) : (
          <ChevronDown className="h-4 w-4 text-zinc-400" />
        )}
      </button>

      {expanded && (
        <div className="px-3 pb-3">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-2 mb-3">
            {SCORE_CATEGORIES.map((cat) => {
              const score = scorecard[cat.key as keyof TpaScorecardData] as number | null;
              return (
                <div key={cat.key} className="bg-zinc-800/50 rounded p-2">
                  <span className="text-[10px] text-zinc-500 block">{cat.label}</span>
                  <span className={cn('text-sm font-semibold', scoreColor(score))}>
                    {score != null ? score.toFixed(1) : '--'}
                  </span>
                  {score != null && (
                    <div className="h-1 bg-zinc-700 rounded-full mt-1 overflow-hidden">
                      <div
                        className={cn(
                          'h-full rounded-full',
                          score >= 90 ? 'bg-emerald-500' :
                          score >= 75 ? 'bg-blue-500' :
                          score >= 60 ? 'bg-amber-500' : 'bg-red-500'
                        )}
                        style={{ width: `${score}%` }}
                      />
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* Volume stats */}
          <div className="flex items-center gap-4 text-xs text-zinc-400">
            <span>Completed: {scorecard.assignmentsCompleted}/{scorecard.totalAssignments}</span>
            {scorecard.averageCycleDays != null && (
              <span>Avg Cycle: {scorecard.averageCycleDays.toFixed(1)} days</span>
            )}
            <Badge variant="secondary" className="text-[10px]">{scorecard.source}</Badge>
          </div>

          {scorecard.notes && (
            <p className="text-xs text-zinc-400 mt-2 italic">{scorecard.notes}</p>
          )}
        </div>
      )}
    </div>
  );
}

// ============================================================================
// PAGE: Scorecards
// ============================================================================

export default function ScorecardsPage() {
  const [selectedProgram, setSelectedProgram] = useState<string>('all');
  const [showNew, setShowNew] = useState(false);

  const { programs: allPrograms, loading: programsLoading } = useTpaPrograms();
  const activePrograms = useMemo(
    () => (allPrograms || []).filter((p) => !p.deletedAt),
    [allPrograms]
  );

  const programFilter = selectedProgram !== 'all' ? selectedProgram : undefined;
  const { scorecards, loading, error, createScorecard } = useTpaScorecards(programFilter);

  const programMap = useMemo(() => {
    const map: Record<string, string> = {};
    for (const p of activePrograms) map[p.id] = p.name;
    return map;
  }, [activePrograms]);

  // Trend: latest score per program
  const latestByProgram = useMemo(() => {
    const latest: Record<string, TpaScorecardData> = {};
    for (const sc of scorecards) {
      if (!latest[sc.tpaProgramId] || sc.periodStart > latest[sc.tpaProgramId].periodStart) {
        latest[sc.tpaProgramId] = sc;
      }
    }
    return Object.values(latest);
  }, [scorecards]);

  // Alert thresholds
  const alerts = latestByProgram.filter((sc) => sc.overallScore != null && sc.overallScore < 75);

  return (
    <div className="p-6 space-y-6 max-w-[1200px] mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/dashboard/tpa">
            <Button variant="ghost" size="icon" className="h-8 w-8">
              <ArrowLeft className="h-4 w-4" />
            </Button>
          </Link>
          <div>
            <h1 className="text-xl font-semibold text-white flex items-center gap-2">
              <Star className="h-5 w-5 text-amber-400" />
              TPA Scorecards
            </h1>
            <p className="text-sm text-zinc-400 mt-0.5">
              Track and trend TPA program performance scores
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <select
            className="bg-zinc-800 border border-zinc-700 rounded px-3 py-1.5 text-sm text-white"
            value={selectedProgram}
            onChange={(e) => setSelectedProgram(e.target.value)}
          >
            <option value="all">All Programs</option>
            {activePrograms.map((p) => (
              <option key={p.id} value={p.id}>{p.name}</option>
            ))}
          </select>
          <Button size="sm" onClick={() => setShowNew(true)}>
            <Plus className="h-4 w-4 mr-1" />
            New Scorecard
          </Button>
        </div>
      </div>

      {/* Alerts */}
      {alerts.length > 0 && (
        <Card className="bg-red-500/5 border-red-500/20">
          <CardContent className="p-3">
            <div className="flex items-center gap-2 mb-2">
              <AlertTriangle className="h-4 w-4 text-red-400" />
              <span className="text-sm font-medium text-red-400">Score Alerts</span>
            </div>
            <div className="space-y-1">
              {alerts.map((sc) => (
                <div key={sc.id} className="flex items-center justify-between text-xs">
                  <span className="text-zinc-300">{programMap[sc.tpaProgramId] || 'Unknown'}</span>
                  <span className="text-red-400 font-medium">
                    {sc.overallScore?.toFixed(1)} — below threshold
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Latest Scores Summary */}
      {latestByProgram.length > 0 && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {latestByProgram.map((sc) => (
            <Card key={sc.id} className="bg-zinc-900 border-zinc-800">
              <CardContent className="p-3">
                <span className="text-[11px] text-zinc-400 block truncate">
                  {programMap[sc.tpaProgramId] || 'Unknown'}
                </span>
                <div className="flex items-center gap-2 mt-1">
                  <span className={cn('text-2xl font-bold', scoreColor(sc.overallScore))}>
                    {sc.overallScore != null ? sc.overallScore.toFixed(1) : '--'}
                  </span>
                  <div className="flex-1">
                    <div className="h-1.5 bg-zinc-800 rounded-full overflow-hidden">
                      <div
                        className={cn(
                          'h-full rounded-full',
                          (sc.overallScore ?? 0) >= 90 ? 'bg-emerald-500' :
                          (sc.overallScore ?? 0) >= 75 ? 'bg-blue-500' :
                          (sc.overallScore ?? 0) >= 60 ? 'bg-amber-500' : 'bg-red-500'
                        )}
                        style={{ width: `${sc.overallScore ?? 0}%` }}
                      />
                    </div>
                  </div>
                </div>
                <span className="text-[10px] text-zinc-500">{formatPeriod(sc.periodStart, sc.periodEnd)}</span>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Loading */}
      {(loading || programsLoading) && (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-5 w-5 animate-spin text-zinc-400" />
          <span className="ml-2 text-sm text-zinc-400">Loading scorecards...</span>
        </div>
      )}

      {/* Error */}
      {error && (
        <Card className="bg-red-500/5 border-red-500/20">
          <CardContent className="p-4">
            <p className="text-sm text-red-400">{error}</p>
          </CardContent>
        </Card>
      )}

      {/* Scorecard List */}
      {!loading && !error && (
        <Card className="bg-zinc-900 border-zinc-800">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-white flex items-center gap-2">
              <BarChart3 className="h-4 w-4 text-blue-400" />
              Scorecard History ({scorecards.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            {scorecards.length === 0 ? (
              <div className="py-12 text-center">
                <Star className="h-8 w-8 text-zinc-600 mx-auto mb-2" />
                <p className="text-sm text-zinc-400">No scorecards yet</p>
                <p className="text-xs text-zinc-500 mt-1">
                  Add your first scorecard to start tracking performance
                </p>
              </div>
            ) : (
              scorecards.map((sc) => (
                <ScorecardRow
                  key={sc.id}
                  scorecard={sc}
                  programName={programMap[sc.tpaProgramId] || 'Unknown'}
                />
              ))
            )}
          </CardContent>
        </Card>
      )}

      {/* New Scorecard Modal */}
      {showNew && (
        <NewScorecardModal
          programs={activePrograms}
          onSave={createScorecard}
          onClose={() => setShowNew(false)}
        />
      )}
    </div>
  );
}
