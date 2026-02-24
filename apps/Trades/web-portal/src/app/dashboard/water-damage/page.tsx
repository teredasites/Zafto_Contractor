'use client';

import { useState, useMemo } from 'react';
import {
  Droplets,
  Activity,
  AlertTriangle,
  CheckCircle2,
  Clock,
  Thermometer,
  Wind,
  ArrowUpRight,
  Calculator,
  ShieldAlert,
  ChevronDown,
  ChevronRight,
  Package,
  Gauge,
  BookOpen,
  Layers,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDateTime, formatCurrency, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { useRestorationTools } from '@/lib/hooks/use-restoration-tools';
import { useWaterDamageAssessments, calculateGpp, calculateDewPoint } from '@/lib/hooks/use-water-damage';
import type { WaterDamageAssessmentData } from '@/lib/hooks/use-water-damage';
import type { RestorationEquipmentWithJob, MoistureReadingWithJob, DryingLogWithJob } from '@/lib/hooks/use-restoration-tools';
import {
  WATER_CATEGORIES,
  WATER_CLASSES,
  DRYING_STANDARDS,
  AIR_MOVER_FORMULAS,
  DEHUMIDIFICATION_FORMULA,
  S500_DOCUMENTATION_REQUIREMENTS,
  calculateAirMovers,
  calculateDehumidifiers,
  assessCategoryEscalation,
} from '@/lib/official-iicrc-protocols';

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

// ============================================================================
// CONSTANTS & REFERENCE DATA
// ============================================================================

// Derived from IICRC S500-2021 official protocol data
const CATEGORY_COLORS: Record<number, { color: string; bg: string }> = {
  1: { color: 'text-blue-400', bg: 'bg-blue-900/10 border-blue-700/30' },
  2: { color: 'text-amber-400', bg: 'bg-amber-900/10 border-amber-700/30' },
  3: { color: 'text-red-400', bg: 'bg-red-900/10 border-red-700/30' },
};
const CATEGORY_INFO: Record<number, { label: string; color: string; bg: string; description: string; examples: string; antimicrobial: string }> = Object.fromEntries(
  WATER_CATEGORIES.map(cat => [cat.category, {
    label: `Category ${cat.category} — ${cat.name}`,
    color: CATEGORY_COLORS[cat.category].color,
    bg: CATEGORY_COLORS[cat.category].bg,
    description: cat.description,
    examples: cat.sources.join(', '),
    antimicrobial: cat.specialProcedures[0] || 'Follow S500 procedures',
  }])
);

// Derived from IICRC S500-2021 official protocol data
const CLASS_INFO: Record<number, { label: string; description: string; equipment: string; materials: string }> = Object.fromEntries(
  WATER_CLASSES.map(cls => [cls.class, {
    label: `Class ${cls.class} — ${cls.name.split('—')[0]?.trim() || cls.name}`,
    description: cls.description,
    equipment: `Air movers: ${cls.equipmentGuidelines.airMoversPerSqFt}. Dehu: ${cls.equipmentGuidelines.dehumidificationFactor}`,
    materials: cls.typicalMaterials.join(', '),
  }])
);

// Drying targets from IICRC S500-2021 — Note: per S500, most meters are NOT calibrated
// for drywall/plaster/concrete. Targets for those materials are comparative, not absolute.
// The numbers below are general field guidelines. Per S500, "acceptable dry standard" is
// within 10% of pre-loss EMC of similar unaffected materials in the same structure.
const MATERIAL_TARGETS: Record<string, { target: number; description: string; source: string }> = {
  drywall: { target: 12, description: 'Standard 1/2" or 5/8" gypsum board', source: 'S500: comparative to unaffected drywall — meters not calibrated for gypsum' },
  wood: { target: 15, description: 'Dimensional lumber, studs, plates, joists', source: 'S500/USDA: target 15% MC, not to exceed 19%. Below 16% before installing new drywall.' },
  concrete: { target: 17, description: 'Slab, block, poured foundation', source: 'S500/ASTM F2170: comparative. Below 75% RH at slab surface for flooring install.' },
  carpet: { target: 10, description: 'Carpet fiber (test backing separately)', source: 'S500: dry to touch, matching ambient. Cat 2/3 pad must be discarded.' },
  pad: { target: 10, description: 'Carpet cushion/padding', source: 'S500: must be removed for Cat 2/3 water. Cat 1 — discard if not dried within 48hrs.' },
  insulation: { target: 8, description: 'Fiberglass batt, blown-in cellulose', source: 'S500: wet insulation should be removed, not dried in place.' },
  subfloor: { target: 15, description: 'OSB or plywood subfloor', source: 'S500: within 4% of pre-loss EMC. Not to exceed 19%.' },
  hardwood: { target: 14, description: 'Hardwood flooring planks', source: 'S500/NWFA: within 2-4% of pre-loss EMC. Risk of cupping/crowning.' },
  laminate: { target: 12, description: 'Laminate/engineered flooring', source: 'S500: comparative to unaffected areas.' },
  tile_backer: { target: 12, description: 'Cement backer board (Durock, HardieBacker)', source: 'S500: comparative.' },
  plaster: { target: 5, description: 'Plaster walls — very low permeance (Class 4)', source: 'S500: Class 4 material, specialty drying. Comparative only.' },
};

const ESCALATION_HOURS = 48;

// ============================================================================
// TABS
// ============================================================================

const TABS = [
  { key: 'dashboard' as const, label: 'Dashboard', icon: Activity },
  { key: 'classification' as const, label: 'Classification Guide', icon: BookOpen },
  { key: 'equipment' as const, label: 'Equipment', icon: Package },
  { key: 'calculator' as const, label: 'Calculators', icon: Calculator },
] satisfies { key: string; label: string; icon: LucideIcon }[];

type TabKey = typeof TABS[number]['key'];

// ============================================================================
// PAGE
// ============================================================================

export default function WaterDamagePage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<TabKey>('dashboard');
  const { readings, dryingLogs, equipment, activeEquipment, stats, loading } = useRestorationTools();

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-56 mb-2" /><div className="skeleton h-4 w-64" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl p-6"><div className="skeleton h-64 w-full" /></div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div>
        <h1 className="text-2xl font-semibold text-main">Water Damage Management</h1>
        <p className="text-muted mt-1">IICRC S500 compliant water damage tracking, equipment management, and drying calculations</p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-900/30 rounded-lg"><Droplets size={20} className="text-blue-400" /></div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.totalReadings}</p>
                <p className="text-sm text-muted">Moisture Readings</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-900/30 rounded-lg"><Activity size={20} className="text-purple-400" /></div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.dryingInProgress}</p>
                <p className="text-sm text-muted">Active Drying Jobs</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-900/30 rounded-lg"><Package size={20} className="text-emerald-400" /></div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.activeEquipment}</p>
                <p className="text-sm text-muted">Deployed Equipment</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-900/30 rounded-lg"><Clock size={20} className="text-amber-400" /></div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.overdueReadings}</p>
                <p className="text-sm text-muted">Overdue (24h+)</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-900/30 rounded-lg"><Gauge size={20} className="text-red-400" /></div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(stats.dailyRateTotal)}</p>
                <p className="text-sm text-muted">Daily Rental Cost</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 border-b border-main overflow-x-auto">
        {TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={cn(
              'flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors whitespace-nowrap',
              activeTab === tab.key
                ? 'border-blue-500 text-blue-400'
                : 'border-transparent text-muted hover:text-main'
            )}
          >
            <tab.icon size={16} />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'dashboard' && (
        <DashboardTab
          readings={readings}
          dryingLogs={dryingLogs}
          equipment={equipment}
          activeEquipment={activeEquipment}
          stats={stats}
        />
      )}
      {activeTab === 'classification' && <ClassificationGuideTab />}
      {activeTab === 'equipment' && <EquipmentTab equipment={equipment} activeEquipment={activeEquipment} stats={stats} />}
      {activeTab === 'calculator' && <CalculatorTab />}
    </div>
  );
}

// ============================================================================
// DASHBOARD TAB
// ============================================================================

function DashboardTab({
  readings,
  dryingLogs,
  equipment,
  activeEquipment,
  stats,
}: {
  readings: MoistureReadingWithJob[];
  dryingLogs: DryingLogWithJob[];
  equipment: RestorationEquipmentWithJob[];
  activeEquipment: RestorationEquipmentWithJob[];
  stats: ReturnType<typeof useRestorationTools>['stats'];
}) {
  const [search, setSearch] = useState('');

  // Group readings by job to create per-job status cards
  const jobSummaries = useMemo(() => {
    const jobMap = new Map<string, {
      jobId: string;
      jobName: string;
      totalReadings: number;
      latestReadingAt: string | null;
      dryCount: number;
      wetCount: number;
      equipmentDeployed: number;
      dryingLogs: number;
      hasCompletion: boolean;
      overdueReading: boolean;
    }>();

    for (const r of readings) {
      const existing = jobMap.get(r.jobId) || {
        jobId: r.jobId,
        jobName: r.jobName,
        totalReadings: 0,
        latestReadingAt: null,
        dryCount: 0,
        wetCount: 0,
        equipmentDeployed: 0,
        dryingLogs: 0,
        hasCompletion: false,
        overdueReading: false,
      };
      existing.totalReadings++;
      if (r.isDry) existing.dryCount++; else existing.wetCount++;
      if (!existing.latestReadingAt || r.recordedAt > existing.latestReadingAt) {
        existing.latestReadingAt = r.recordedAt;
      }
      jobMap.set(r.jobId, existing);
    }

    // Add equipment counts
    for (const eq of activeEquipment) {
      const existing = jobMap.get(eq.jobId);
      if (existing) existing.equipmentDeployed++;
    }

    // Add drying log info
    for (const log of dryingLogs) {
      const existing = jobMap.get(log.jobId);
      if (existing) {
        existing.dryingLogs++;
        if (log.logType === 'completion') existing.hasCompletion = true;
      }
    }

    // Mark overdue
    const now = Date.now();
    const twentyFourHours = 24 * 60 * 60 * 1000;
    for (const [, summary] of jobMap) {
      if (summary.latestReadingAt) {
        summary.overdueReading = (now - new Date(summary.latestReadingAt).getTime()) > twentyFourHours;
      }
    }

    return Array.from(jobMap.values())
      .sort((a, b) => {
        // Active jobs first, then by latest reading
        if (a.hasCompletion !== b.hasCompletion) return a.hasCompletion ? 1 : -1;
        return (b.latestReadingAt || '').localeCompare(a.latestReadingAt || '');
      });
  }, [readings, dryingLogs, activeEquipment]);

  const filtered = jobSummaries.filter(j =>
    !search || j.jobName.toLowerCase().includes(search.toLowerCase())
  );

  // Category escalation alerts — check if any reading's job has logs older than 48h without completion
  const escalationAlerts = useMemo(() => {
    const alerts: { jobId: string; jobName: string; hoursSinceLoss: number }[] = [];
    const jobFirstReading = new Map<string, { at: string; name: string }>();
    for (const r of readings) {
      const existing = jobFirstReading.get(r.jobId);
      if (!existing || r.recordedAt < existing.at) {
        jobFirstReading.set(r.jobId, { at: r.recordedAt, name: r.jobName });
      }
    }
    const now = Date.now();
    for (const [jobId, info] of jobFirstReading) {
      const hoursSince = (now - new Date(info.at).getTime()) / (1000 * 60 * 60);
      if (hoursSince > ESCALATION_HOURS) {
        const summary = jobSummaries.find(j => j.jobId === jobId);
        if (summary && !summary.hasCompletion && summary.wetCount > 0) {
          alerts.push({ jobId, jobName: info.name, hoursSinceLoss: Math.round(hoursSince) });
        }
      }
    }
    return alerts;
  }, [readings, jobSummaries]);

  return (
    <div className="space-y-6">
      {/* Category Escalation Alerts */}
      {escalationAlerts.length > 0 && (
        <div className="bg-red-900/15 border border-red-700/30 rounded-xl p-4 space-y-2">
          <div className="flex items-center gap-2 mb-2">
            <ShieldAlert size={18} className="text-red-400" />
            <p className="font-medium text-red-300">Category Escalation Alert</p>
          </div>
          {escalationAlerts.map((alert) => (
            <div key={alert.jobId} className="flex items-center justify-between text-sm">
              <span className="text-red-300">
                <span className="font-medium">{alert.jobName || 'Unnamed Job'}</span> — water present for {alert.hoursSinceLoss}h (IICRC: Cat 1 → Cat 2 after 48h)
              </span>
              <Badge variant="error">Escalate Category</Badge>
            </div>
          ))}
          <p className="text-xs text-red-400/70 mt-2">
            Per IICRC S500, Category 1 clean water that remains {'>'}48 hours may escalate to Category 2 due to microbial amplification. Apply antimicrobial treatment and re-classify.
          </p>
        </div>
      )}

      {/* Overdue Readings Alert */}
      {stats.overdueReadings > 0 && (
        <div className="bg-amber-900/15 border border-amber-700/30 rounded-xl p-4 flex items-center gap-3">
          <Clock size={18} className="text-amber-400" />
          <div>
            <p className="font-medium text-amber-300">{stats.overdueReadings} job{stats.overdueReadings > 1 ? 's' : ''} with overdue readings (24h+)</p>
            <p className="text-xs text-amber-400/70">IICRC S500 requires daily moisture monitoring during active drying.</p>
          </div>
        </div>
      )}

      {/* Search */}
      <SearchInput value={search} onChange={setSearch} placeholder="Search jobs..." className="sm:w-80" />

      {/* Job Cards */}
      {filtered.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center">
            <Droplets size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No Water Damage Jobs</h3>
            <p className="text-muted">Moisture readings will appear here when jobs have active water damage monitoring.</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {filtered.map((job) => {
            const percentDry = job.totalReadings > 0 ? Math.round((job.dryCount / job.totalReadings) * 100) : 0;
            return (
              <Card key={job.jobId}>
                <CardContent className="p-4 space-y-3">
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="font-medium text-main">{job.jobName || 'Unnamed Job'}</p>
                      <p className="text-xs text-muted">{job.totalReadings} readings across {job.dryCount + job.wetCount} locations</p>
                    </div>
                    <div className="flex items-center gap-2">
                      {job.hasCompletion && <Badge variant="success">Complete</Badge>}
                      {job.overdueReading && !job.hasCompletion && <Badge variant="warning">Overdue</Badge>}
                      {!job.hasCompletion && !job.overdueReading && <Badge variant="info">Active</Badge>}
                    </div>
                  </div>

                  {/* Progress Bar */}
                  <div>
                    <div className="flex items-center justify-between text-xs text-muted mb-1">
                      <span>Drying Progress</span>
                      <span className={cn(percentDry === 100 ? 'text-emerald-400' : percentDry >= 75 ? 'text-amber-400' : 'text-red-400')}>
                        {percentDry}% dry ({job.dryCount}/{job.dryCount + job.wetCount})
                      </span>
                    </div>
                    <div className="w-full bg-secondary rounded-full h-2">
                      <div
                        className={cn('h-2 rounded-full transition-all',
                          percentDry === 100 ? 'bg-emerald-500' : percentDry >= 75 ? 'bg-amber-500' : 'bg-red-500'
                        )}
                        style={{ width: `${percentDry}%` }}
                      />
                    </div>
                  </div>

                  {/* Quick Stats */}
                  <div className="flex items-center gap-4 text-xs text-muted">
                    <span className="flex items-center gap-1"><Package size={12} /> {job.equipmentDeployed} equipment</span>
                    <span className="flex items-center gap-1"><Wind size={12} /> {job.dryingLogs} logs</span>
                    {job.latestReadingAt && (
                      <span className="flex items-center gap-1"><Clock size={12} /> {formatDateTime(job.latestReadingAt)}</span>
                    )}
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      {/* Latest Readings Quick Table */}
      {readings.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Recent Moisture Readings</CardTitle>
          </CardHeader>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left px-4 py-2 text-xs font-medium text-muted uppercase">Date</th>
                  <th className="text-left px-4 py-2 text-xs font-medium text-muted uppercase">Job</th>
                  <th className="text-left px-4 py-2 text-xs font-medium text-muted uppercase">Area</th>
                  <th className="text-left px-4 py-2 text-xs font-medium text-muted uppercase">Material</th>
                  <th className="text-right px-4 py-2 text-xs font-medium text-muted uppercase">Reading</th>
                  <th className="text-right px-4 py-2 text-xs font-medium text-muted uppercase">Target</th>
                  <th className="text-center px-4 py-2 text-xs font-medium text-muted uppercase">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {readings.slice(0, 15).map((r) => {
                  const target = r.targetValue ?? MATERIAL_TARGETS[r.materialType]?.target ?? 15;
                  const atTarget = r.readingValue <= target;
                  return (
                    <tr key={r.id} className="hover:bg-surface-hover">
                      <td className="px-4 py-2 text-main text-xs whitespace-nowrap">{formatDateTime(r.recordedAt)}</td>
                      <td className="px-4 py-2 text-main font-medium truncate max-w-[160px]">{r.jobName || '—'}</td>
                      <td className="px-4 py-2 text-main">{r.areaName}</td>
                      <td className="px-4 py-2"><Badge variant="secondary">{r.materialType}</Badge></td>
                      <td className={cn('px-4 py-2 text-right font-mono font-medium', atTarget ? 'text-emerald-400' : 'text-red-400')}>
                        {r.readingValue}{r.readingUnit === 'percent' ? '%' : ` ${r.readingUnit}`}
                      </td>
                      <td className="px-4 py-2 text-right font-mono text-muted">{target}</td>
                      <td className="px-4 py-2 text-center">
                        {atTarget
                          ? <CheckCircle2 size={16} className="text-emerald-500 mx-auto" />
                          : <AlertTriangle size={16} className="text-amber-500 mx-auto" />}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      )}
    </div>
  );
}

// ============================================================================
// CLASSIFICATION GUIDE TAB
// ============================================================================

function ClassificationGuideTab() {
  const [expandedCat, setExpandedCat] = useState<number | null>(null);
  const [expandedClass, setExpandedClass] = useState<number | null>(null);

  return (
    <div className="space-y-6">
      {/* IICRC S500 Categories */}
      <div>
        <h2 className="text-lg font-semibold text-main mb-3">Water Damage Categories (IICRC S500)</h2>
        <div className="space-y-3">
          {[1, 2, 3].map((cat) => {
            const info = CATEGORY_INFO[cat];
            const isExpanded = expandedCat === cat;
            return (
              <Card key={cat} className={cn('border', info.bg)}>
                <button
                  onClick={() => setExpandedCat(isExpanded ? null : cat)}
                  className="w-full px-4 py-3 flex items-center justify-between hover:bg-surface-hover/30 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    {isExpanded ? <ChevronDown size={16} className="text-muted" /> : <ChevronRight size={16} className="text-muted" />}
                    <span className={cn('font-semibold', info.color)}>{info.label}</span>
                  </div>
                </button>
                {isExpanded && (
                  <CardContent className="pt-0 pb-4 px-4 space-y-3">
                    <div>
                      <p className="text-xs text-muted uppercase tracking-wider mb-1">Description</p>
                      <p className="text-sm text-main">{info.description}</p>
                    </div>
                    <div>
                      <p className="text-xs text-muted uppercase tracking-wider mb-1">Examples</p>
                      <p className="text-sm text-main">{info.examples}</p>
                    </div>
                    <div>
                      <p className="text-xs text-muted uppercase tracking-wider mb-1">Antimicrobial Treatment</p>
                      <p className="text-sm text-main">{info.antimicrobial}</p>
                    </div>
                    {cat < 3 && (
                      <div className="p-3 bg-amber-900/10 border border-amber-700/20 rounded-lg">
                        <p className="text-xs text-amber-400 font-medium flex items-center gap-1">
                          <ArrowUpRight size={14} />
                          Escalation: Category {cat} water that remains {'>'}48 hours may escalate to Category {cat + 1}
                        </p>
                      </div>
                    )}
                  </CardContent>
                )}
              </Card>
            );
          })}
        </div>
      </div>

      {/* IICRC S500 Classes */}
      <div>
        <h2 className="text-lg font-semibold text-main mb-3">Water Damage Classes (IICRC S500)</h2>
        <div className="space-y-3">
          {[1, 2, 3, 4].map((cls) => {
            const info = CLASS_INFO[cls];
            const isExpanded = expandedClass === cls;
            return (
              <Card key={cls}>
                <button
                  onClick={() => setExpandedClass(isExpanded ? null : cls)}
                  className="w-full px-4 py-3 flex items-center justify-between hover:bg-surface-hover transition-colors"
                >
                  <div className="flex items-center gap-3">
                    {isExpanded ? <ChevronDown size={16} className="text-muted" /> : <ChevronRight size={16} className="text-muted" />}
                    <span className="font-semibold text-main">{info.label}</span>
                  </div>
                  <Badge variant="secondary">Class {cls}</Badge>
                </button>
                {isExpanded && (
                  <CardContent className="pt-0 pb-4 px-4 space-y-3">
                    <div>
                      <p className="text-xs text-muted uppercase tracking-wider mb-1">Description</p>
                      <p className="text-sm text-main">{info.description}</p>
                    </div>
                    <div>
                      <p className="text-xs text-muted uppercase tracking-wider mb-1">Equipment Recommendations</p>
                      <p className="text-sm text-main">{info.equipment}</p>
                    </div>
                    <div>
                      <p className="text-xs text-muted uppercase tracking-wider mb-1">Typical Materials</p>
                      <p className="text-sm text-main">{info.materials}</p>
                    </div>
                  </CardContent>
                )}
              </Card>
            );
          })}
        </div>
      </div>

      {/* Drying Goals Reference */}
      <div>
        <h2 className="text-lg font-semibold text-main mb-3">Material Drying Goals (Target Moisture Content)</h2>
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Material</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Target MC (%)</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Description</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {Object.entries(MATERIAL_TARGETS).map(([material, info]) => (
                  <tr key={material} className="hover:bg-surface-hover">
                    <td className="px-4 py-2.5 text-main font-medium capitalize">{material.replace(/_/g, ' ')}</td>
                    <td className="px-4 py-2.5 text-right font-mono text-emerald-400 font-medium">{info.target}%</td>
                    <td className="px-4 py-2.5 text-muted">{info.description}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
        <p className="text-xs text-muted mt-2">
          Note: Always compare wet area readings to a non-affected reference standard of the same material in the same structure.
          If the reference standard reads 14% MC, a target of 15% is acceptable. Drying goal = reference standard reading.
        </p>
      </div>
    </div>
  );
}

// ============================================================================
// EQUIPMENT TAB
// ============================================================================

function EquipmentTab({
  equipment,
  activeEquipment,
  stats,
}: {
  equipment: RestorationEquipmentWithJob[];
  activeEquipment: RestorationEquipmentWithJob[];
  stats: ReturnType<typeof useRestorationTools>['stats'];
}) {
  const [filter, setFilter] = useState<'all' | 'deployed' | 'removed'>('all');
  const [search, setSearch] = useState('');

  const typeLabels: Record<string, string> = {
    dehumidifier: 'Dehumidifier',
    air_mover: 'Air Mover',
    air_scrubber: 'Air Scrubber',
    heater: 'Heater',
    negative_air: 'Negative Air Machine',
    moisture_meter: 'Moisture Meter',
    thermal_camera: 'Thermal Camera',
  };

  const filtered = equipment.filter((eq) => {
    const matchesFilter = filter === 'all' || (filter === 'deployed' ? eq.status === 'deployed' : eq.status !== 'deployed');
    const matchesSearch = !search ||
      eq.jobName.toLowerCase().includes(search.toLowerCase()) ||
      eq.areaDeployed.toLowerCase().includes(search.toLowerCase()) ||
      (eq.serialNumber || '').toLowerCase().includes(search.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  // Group by job for rental cost summary
  const rentalByJob = useMemo(() => {
    const map = new Map<string, { jobName: string; dailyCost: number; units: number; days: number }>();
    for (const eq of activeEquipment) {
      const existing = map.get(eq.jobId) || { jobName: eq.jobName, dailyCost: 0, units: 0, days: 0 };
      existing.dailyCost += eq.dailyRate || 0;
      existing.units++;
      if (eq.deployedAt) {
        const daysSinceDeployed = Math.ceil((Date.now() - new Date(eq.deployedAt).getTime()) / (1000 * 60 * 60 * 24));
        existing.days = Math.max(existing.days, daysSinceDeployed);
      }
      map.set(eq.jobId, existing);
    }
    return Array.from(map.entries()).sort((a, b) => b[1].dailyCost - a[1].dailyCost);
  }, [activeEquipment]);

  return (
    <div className="space-y-6">
      {/* Rental Cost Summary */}
      {rentalByJob.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Equipment Rental Cost by Job</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {rentalByJob.map(([jobId, info]) => (
                <div key={jobId} className="flex items-center justify-between p-3 bg-secondary/50 rounded-lg">
                  <div>
                    <p className="font-medium text-main">{info.jobName || 'Unnamed Job'}</p>
                    <p className="text-xs text-muted">{info.units} units deployed | Day {info.days}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-main">{formatCurrency(info.dailyCost)}/day</p>
                    <p className="text-xs text-muted">Est. total: {formatCurrency(info.dailyCost * info.days)}</p>
                  </div>
                </div>
              ))}
              <div className="flex items-center justify-between pt-2 border-t border-main">
                <p className="font-medium text-main">Total Daily Cost</p>
                <p className="font-bold text-lg text-main">{formatCurrency(stats.dailyRateTotal)}/day</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search equipment..." className="sm:w-80" />
        <Select
          options={[
            { value: 'all', label: 'All Equipment' },
            { value: 'deployed', label: 'Deployed' },
            { value: 'removed', label: 'Returned/Removed' },
          ]}
          value={filter}
          onChange={(e) => setFilter(e.target.value as 'all' | 'deployed' | 'removed')}
          className="sm:w-48"
        />
      </div>

      {/* Equipment Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Type</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Job</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Area</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Serial/Tag</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Daily Rate</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Deployed</th>
                <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {filtered.map((eq) => (
                <tr key={eq.id} className="hover:bg-surface-hover">
                  <td className="px-4 py-2.5">
                    <Badge variant="secondary">{typeLabels[eq.equipmentType] || eq.equipmentType}</Badge>
                  </td>
                  <td className="px-4 py-2.5 text-main font-medium truncate max-w-[160px]">{eq.jobName || '—'}</td>
                  <td className="px-4 py-2.5 text-main">{eq.areaDeployed}</td>
                  <td className="px-4 py-2.5 text-muted font-mono text-xs">{eq.serialNumber || eq.assetTag || '—'}</td>
                  <td className="px-4 py-2.5 text-right font-mono text-main">{formatCurrency(eq.dailyRate)}</td>
                  <td className="px-4 py-2.5 text-main text-xs">{formatDateTime(eq.deployedAt)}</td>
                  <td className="px-4 py-2.5 text-center">
                    <Badge variant={eq.status === 'deployed' ? 'success' : eq.status === 'maintenance' ? 'warning' : 'secondary'}>
                      {eq.status}
                    </Badge>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filtered.length === 0 && (
          <CardContent className="p-12 text-center">
            <Package size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No Equipment</h3>
            <p className="text-muted">Equipment deployed to water damage jobs will appear here.</p>
          </CardContent>
        )}
      </Card>
    </div>
  );
}

// ============================================================================
// CALCULATOR TAB
// ============================================================================

function CalculatorTab() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <AirMoverCalculator />
      <DehumidifierCalculator />
      <DryingGoalCalculator />
      <PsychrometricCalculator />
    </div>
  );
}

function AirMoverCalculator() {
  const [length, setLength] = useState('');
  const [width, setWidth] = useState('');
  const [wallHeight, setWallHeight] = useState('8');
  const [waterClass, setWaterClass] = useState('2');

  const results = useMemo(() => {
    const l = parseFloat(length) || 0;
    const w = parseFloat(width) || 0;
    const h = parseFloat(wallHeight) || 8;
    if (l <= 0 || w <= 0) return null;

    const perimeter = 2 * (l + w);
    const cls = parseInt(waterClass);

    // IICRC S500: Air movers per 10-16 LF of affected wall
    // Class 1: 1 per 16 LF (minimal), Class 2: 1 per 12 LF, Class 3: 1 per 10 LF, Class 4: specialty
    const lfPerMover = cls === 1 ? 16 : cls === 2 ? 12 : cls === 3 ? 10 : 14;
    const airMovers = Math.ceil(perimeter / lfPerMover);

    // Ceiling fans if Class 3 (water from above)
    const ceilingFans = cls >= 3 ? Math.ceil((l * w) / 200) : 0;

    return { perimeter, airMovers, lfPerMover, ceilingFans, sqft: l * w };
  }, [length, width, wallHeight, waterClass]);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2"><Wind size={18} /> Air Mover Placement</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <Input label="Room Length (ft)" type="number" value={length} onChange={(e) => setLength(e.target.value)} placeholder="20" />
          <Input label="Room Width (ft)" type="number" value={width} onChange={(e) => setWidth(e.target.value)} placeholder="15" />
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Input label="Wall Height (ft)" type="number" value={wallHeight} onChange={(e) => setWallHeight(e.target.value)} placeholder="8" />
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Water Class</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
              value={waterClass} onChange={(e) => setWaterClass(e.target.value)}>
              <option value="1">Class 1 — Minimal</option>
              <option value="2">Class 2 — Significant</option>
              <option value="3">Class 3 — Greatest</option>
              <option value="4">Class 4 — Specialty</option>
            </select>
          </div>
        </div>
        {results && (
          <div className="p-4 bg-blue-900/10 border border-blue-700/20 rounded-lg space-y-2">
            <div className="flex justify-between">
              <span className="text-sm text-muted">Perimeter</span>
              <span className="font-mono text-main">{results.perimeter} LF</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted">Placement ratio</span>
              <span className="font-mono text-main">1 per {results.lfPerMover} LF</span>
            </div>
            <div className="flex justify-between font-semibold border-t border-blue-800/30 pt-2">
              <span className="text-blue-400">Air Movers Needed</span>
              <span className="text-blue-300 text-lg">{results.airMovers}</span>
            </div>
            {results.ceilingFans > 0 && (
              <div className="flex justify-between text-sm">
                <span className="text-muted">Ceiling-directed fans</span>
                <span className="text-main">{results.ceilingFans}</span>
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function DehumidifierCalculator() {
  const [length, setLength] = useState('');
  const [width, setWidth] = useState('');
  const [ceilingHeight, setCeilingHeight] = useState('8');
  const [currentRh, setCurrentRh] = useState('');
  const [tempF, setTempF] = useState('');

  const results = useMemo(() => {
    const l = parseFloat(length) || 0;
    const w = parseFloat(width) || 0;
    const h = parseFloat(ceilingHeight) || 8;
    if (l <= 0 || w <= 0) return null;

    const volume = l * w * h;
    const sqft = l * w;

    // IICRC: ~1 commercial dehumidifier (70 pints/day) per 1,000-1,200 sqft
    const dehuCount = Math.ceil(sqft / 1000);

    // Pints per day: rough estimate from volume and humidity
    const rh = parseFloat(currentRh) || 0;
    const targetRh = 40;
    const excessMoisture = rh > targetRh ? (rh - targetRh) / 100 : 0;
    const estimatedPints = Math.round(volume * 0.002 * (1 + excessMoisture * 5));

    // Air changes per hour recommendation
    const cfmNeeded = Math.ceil((volume * 4) / 60);

    return { volume, sqft, dehuCount, estimatedPints, cfmNeeded };
  }, [length, width, ceilingHeight, currentRh]);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2"><Thermometer size={18} /> Dehumidifier Sizing</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <Input label="Room Length (ft)" type="number" value={length} onChange={(e) => setLength(e.target.value)} placeholder="20" />
          <Input label="Room Width (ft)" type="number" value={width} onChange={(e) => setWidth(e.target.value)} placeholder="15" />
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Input label="Ceiling Height (ft)" type="number" value={ceilingHeight} onChange={(e) => setCeilingHeight(e.target.value)} placeholder="8" />
          <Input label="Current RH (%)" type="number" value={currentRh} onChange={(e) => setCurrentRh(e.target.value)} placeholder="75" />
        </div>
        {results && (
          <div className="p-4 bg-purple-900/10 border border-purple-700/20 rounded-lg space-y-2">
            <div className="flex justify-between">
              <span className="text-sm text-muted">Room Volume</span>
              <span className="font-mono text-main">{results.volume.toLocaleString()} cu ft</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted">Room Area</span>
              <span className="font-mono text-main">{results.sqft.toLocaleString()} sq ft</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted">Min CFM (4 ACH)</span>
              <span className="font-mono text-main">{results.cfmNeeded} CFM</span>
            </div>
            <div className="flex justify-between font-semibold border-t border-purple-800/30 pt-2">
              <span className="text-purple-400">Dehumidifiers Needed</span>
              <span className="text-purple-300 text-lg">{results.dehuCount}</span>
            </div>
            <p className="text-xs text-muted">Based on 1 commercial dehumidifier (70 pints/day) per 1,000 sq ft</p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function DryingGoalCalculator() {
  const [material, setMaterial] = useState('drywall');
  const [currentMC, setCurrentMC] = useState('');
  const [referenceMC, setReferenceMC] = useState('');

  const materialInfo = MATERIAL_TARGETS[material];
  const target = parseFloat(referenceMC) || materialInfo?.target || 15;
  const current = parseFloat(currentMC) || 0;
  const isDry = current > 0 && current <= target;
  const percentToGoal = current > 0 ? Math.max(0, Math.min(100, Math.round(((current - target) / (current)) * 100))) : 0;

  // Rough estimate of drying days
  // Typical drying rate: 2-4% MC reduction per day with proper equipment
  const dryingRate = 3;
  const estimatedDays = current > target ? Math.ceil((current - target) / dryingRate) : 0;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2"><Layers size={18} /> Drying Goal Calculator</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-main mb-1.5">Material Type</label>
          <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
            value={material} onChange={(e) => setMaterial(e.target.value)}>
            {Object.entries(MATERIAL_TARGETS).map(([key, info]) => (
              <option key={key} value={key}>{key.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())} (target: {info.target}%)</option>
            ))}
          </select>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Input label="Current MC (%)" type="number" value={currentMC} onChange={(e) => setCurrentMC(e.target.value)} placeholder="18" />
          <Input label="Reference Standard (%)" type="number" value={referenceMC} onChange={(e) => setReferenceMC(e.target.value)} placeholder="Optional" />
        </div>
        {current > 0 && (
          <div className={cn('p-4 rounded-lg border space-y-2', isDry ? 'bg-emerald-900/10 border-emerald-700/20' : 'bg-amber-900/10 border-amber-700/20')}>
            <div className="flex justify-between">
              <span className="text-sm text-muted">Material</span>
              <span className="text-main capitalize">{material.replace(/_/g, ' ')}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted">Target MC</span>
              <span className="font-mono text-emerald-400">{target}%</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted">Current MC</span>
              <span className={cn('font-mono font-medium', isDry ? 'text-emerald-400' : 'text-amber-400')}>{current}%</span>
            </div>
            <div className="flex justify-between font-semibold border-t pt-2" style={{ borderColor: isDry ? 'rgba(16,185,129,0.2)' : 'rgba(245,158,11,0.2)' }}>
              <span className={isDry ? 'text-emerald-400' : 'text-amber-400'}>
                {isDry ? 'AT TARGET — Dry' : `${current - target}% above goal`}
              </span>
              {!isDry && <span className="text-amber-300">~{estimatedDays} days</span>}
            </div>
            {!isDry && (
              <p className="text-xs text-muted">Estimated at {dryingRate}% MC reduction/day with proper equipment deployment</p>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function PsychrometricCalculator() {
  const [indoorTemp, setIndoorTemp] = useState('');
  const [indoorRh, setIndoorRh] = useState('');
  const [outdoorTemp, setOutdoorTemp] = useState('');
  const [outdoorRh, setOutdoorRh] = useState('');

  const indoorGpp = indoorTemp && indoorRh ? calculateGpp(parseFloat(indoorTemp), parseFloat(indoorRh)) : null;
  const indoorDew = indoorTemp && indoorRh ? calculateDewPoint(parseFloat(indoorTemp), parseFloat(indoorRh)) : null;
  const outdoorGpp = outdoorTemp && outdoorRh ? calculateGpp(parseFloat(outdoorTemp), parseFloat(outdoorRh)) : null;
  const outdoorDew = outdoorTemp && outdoorRh ? calculateDewPoint(parseFloat(outdoorTemp), parseFloat(outdoorRh)) : null;

  const grainDepression = indoorGpp != null && outdoorGpp != null ? indoorGpp - outdoorGpp : null;
  const dryingEfficient = grainDepression != null && grainDepression > 0;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2"><Gauge size={18} /> Psychrometric Calculator</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-xs text-muted">
          Calculate GPP (Grains Per Pound) and grain depression for drying efficiency analysis.
          Target: indoor GPP should exceed outdoor GPP by 40+ grains for effective drying.
        </p>
        <div className="grid grid-cols-2 gap-4">
          <Input label="Indoor Temp (F)" type="number" value={indoorTemp} onChange={(e) => setIndoorTemp(e.target.value)} placeholder="72" />
          <Input label="Indoor RH (%)" type="number" value={indoorRh} onChange={(e) => setIndoorRh(e.target.value)} placeholder="55" />
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Input label="Outdoor Temp (F)" type="number" value={outdoorTemp} onChange={(e) => setOutdoorTemp(e.target.value)} placeholder="45" />
          <Input label="Outdoor RH (%)" type="number" value={outdoorRh} onChange={(e) => setOutdoorRh(e.target.value)} placeholder="65" />
        </div>
        {indoorGpp != null && (
          <div className="space-y-3">
            <div className="p-3 bg-blue-900/10 border border-blue-800/20 rounded-lg">
              <p className="text-xs text-blue-400 uppercase tracking-wider mb-2">Indoor</p>
              <div className="flex justify-between text-sm">
                <span className="text-muted">GPP</span>
                <span className="font-mono text-main font-medium">{indoorGpp.toFixed(1)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">Dew Point</span>
                <span className="font-mono text-main">{indoorDew?.toFixed(1)}°F</span>
              </div>
            </div>
            {outdoorGpp != null && (
              <>
                <div className="p-3 bg-secondary/50 border border-main/30 rounded-lg">
                  <p className="text-xs text-muted uppercase tracking-wider mb-2">Outdoor</p>
                  <div className="flex justify-between text-sm">
                    <span className="text-muted">GPP</span>
                    <span className="font-mono text-main font-medium">{outdoorGpp.toFixed(1)}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-muted">Dew Point</span>
                    <span className="font-mono text-main">{outdoorDew?.toFixed(1)}°F</span>
                  </div>
                </div>
                {grainDepression != null && (
                  <div className={cn('p-3 rounded-lg border', dryingEfficient
                    ? (grainDepression >= 40 ? 'bg-emerald-900/10 border-emerald-700/20' : 'bg-amber-900/10 border-amber-700/20')
                    : 'bg-red-900/10 border-red-700/20'
                  )}>
                    <p className="text-xs text-muted uppercase tracking-wider mb-1">Grain Depression (Indoor GPP - Outdoor GPP)</p>
                    <p className={cn('text-xl font-bold', dryingEfficient
                      ? (grainDepression >= 40 ? 'text-emerald-400' : 'text-amber-400')
                      : 'text-red-400'
                    )}>
                      {grainDepression > 0 ? '+' : ''}{grainDepression.toFixed(1)} grains
                    </p>
                    <p className="text-xs text-muted mt-1">
                      {grainDepression >= 40
                        ? 'Excellent drying conditions. Dehumidifiers working efficiently.'
                        : grainDepression > 0
                        ? 'Marginal drying. Consider running more dehumidifiers or adding heat.'
                        : 'Poor drying conditions. Indoor moisture exceeds outdoor — increase dehumidification.'}
                    </p>
                  </div>
                )}
              </>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
