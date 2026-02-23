'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  Droplets,
  Thermometer,
  CheckCircle2,
  AlertTriangle,
  Clock,
  Wind,
  Activity,
  Package,
  Plus,
  X,
  ChevronDown,
  ChevronRight,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { cn, formatDateTime, formatCurrency } from '@/lib/utils';
import {
  useWaterDamageAssessments,
  useDryingMonitor,
  useContentsInventory,
  calculateGpp,
  calculateDewPoint,
} from '@/lib/hooks/use-water-damage';
import type {
  WaterCategory,
  WaterClass,
  WaterSourceType,
  AffectedArea,
  ContentsAction,
  ContentsCondition,
} from '@/lib/hooks/use-water-damage';
import { useTranslation } from '@/lib/translations';

// ============================================================================
// CONSTANTS
// ============================================================================

const CATEGORY_LABELS: Record<number, { label: string; color: string; description: string }> = {
  1: { label: 'Category 1', color: 'text-blue-400', description: 'Clean Water — supply lines, rain, melting ice' },
  2: { label: 'Category 2', color: 'text-amber-400', description: 'Gray Water — dishwasher, washing machine, toilet w/ urine' },
  3: { label: 'Category 3', color: 'text-red-400', description: 'Black Water — sewage, rising flood, fecal matter' },
};

const CLASS_LABELS: Record<number, { label: string; description: string }> = {
  1: { label: 'Class 1', description: 'Least absorption — part of room, low porosity materials' },
  2: { label: 'Class 2', description: 'Significant — entire room, carpet wet, <24" wall wicking' },
  3: { label: 'Class 3', description: 'Greatest — saturated ceiling, walls, insulation, subfloor' },
  4: { label: 'Class 4', description: 'Specialty drying — hardwood, plaster, concrete, stone' },
};

const SOURCE_LABELS: Record<string, string> = {
  supply_line: 'Supply Line',
  drain_line: 'Drain Line',
  appliance: 'Appliance',
  toilet: 'Toilet',
  sewage: 'Sewage',
  roof_leak: 'Roof Leak',
  window_leak: 'Window Leak',
  foundation: 'Foundation',
  storm: 'Storm',
  flood: 'Flood',
  fire_suppression: 'Fire Suppression',
  hvac: 'HVAC',
  ice_dam: 'Ice Dam',
  unknown: 'Unknown',
  other: 'Other',
};

const ACTION_LABELS: Record<string, string> = {
  move: 'Move',
  block: 'Block/Elevate',
  pack_out: 'Pack-Out',
  dispose: 'Dispose',
  clean: 'Clean',
  restore: 'Restore',
  no_action: 'No Action',
};

const CONDITION_OPTIONS: ContentsCondition[] = ['new', 'good', 'fair', 'poor', 'damaged', 'destroyed', 'unknown'];

const MATERIAL_TARGETS: Record<string, number> = {
  drywall: 12, wood: 15, concrete: 17, carpet: 10, pad: 10,
  insulation: 8, subfloor: 15, hardwood: 15, laminate: 12, tile_backer: 12,
};

// ============================================================================
// PAGE COMPONENT
// ============================================================================

export default function MoistureDryingMonitorPage() {
  const { t } = useTranslation();
  const params = useParams();
  const router = useRouter();
  const jobId = params.id as string;
  const [activeTab, setActiveTab] = useState<'overview' | 'readings' | 'psychrometric' | 'contents'>('overview');

  const { assessments, loading: assessLoading, createAssessment } = useWaterDamageAssessments(jobId);
  const { readings, psychLogs, dryingProgress, loading: dryingLoading, addPsychrometricLog } = useDryingMonitor(jobId);
  const { items, itemsByRoom, financialSummary, loading: contentsLoading, addItem } = useContentsInventory(jobId);

  const loading = assessLoading || dryingLoading || contentsLoading;
  const assessment = assessments[0]; // Latest assessment

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="skeleton h-8 w-72" />
        <div className="grid grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-10 w-full" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl p-6"><div className="skeleton h-64 w-full" /></div>
      </div>
    );
  }

  const tabs = [
    { key: 'overview' as const, label: 'Overview', icon: Activity },
    { key: 'readings' as const, label: `Readings (${readings.length})`, icon: Droplets },
    { key: 'psychrometric' as const, label: `Psychrometric (${psychLogs.length})`, icon: Thermometer },
    { key: 'contents' as const, label: `Contents (${items.length})`, icon: Package },
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button onClick={() => router.push(`/dashboard/jobs/${jobId}`)} className="p-2 hover:bg-surface-hover rounded-lg">
          <ArrowLeft size={20} className="text-muted" />
        </button>
        <div className="flex-1">
          <h1 className="text-2xl font-semibold text-main">{t('jobsMoisture.title')}</h1>
          <p className="text-muted mt-0.5">IICRC S500 compliant water damage tracking</p>
        </div>
        {!assessment && (
          <CreateAssessmentButton onCreate={createAssessment} jobId={jobId} />
        )}
      </div>

      {/* Drying Progress Dashboard */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        {assessment && (
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.classification')}</p>
              <p className={cn('text-lg font-semibold', CATEGORY_LABELS[assessment.waterCategory]?.color || 'text-main')}>
                Cat {assessment.waterCategory} / Class {assessment.waterClass}
              </p>
              <p className="text-xs text-muted mt-0.5">{SOURCE_LABELS[assessment.sourceType] || assessment.sourceType}</p>
            </CardContent>
          </Card>
        )}
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('moisture.dryingProgress')}</p>
            <div className="flex items-baseline gap-2">
              <p className={cn('text-2xl font-bold', dryingProgress.allDry ? 'text-emerald-400' : dryingProgress.percentDry >= 75 ? 'text-amber-400' : 'text-red-400')}>
                {dryingProgress.percentDry}%
              </p>
              <p className="text-sm text-muted">{dryingProgress.dryLocations}/{dryingProgress.totalLocations}</p>
            </div>
            <div className="w-full bg-zinc-800 rounded-full h-2 mt-2">
              <div
                className={cn('h-2 rounded-full transition-all', dryingProgress.allDry ? 'bg-emerald-500' : dryingProgress.percentDry >= 75 ? 'bg-amber-500' : 'bg-red-500')}
                style={{ width: `${dryingProgress.percentDry}%` }}
              />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.locations')}</p>
            <div className="flex items-center gap-3">
              <div>
                <p className="text-2xl font-bold text-main">{dryingProgress.totalLocations}</p>
                <p className="text-xs text-muted">monitored</p>
              </div>
              <div className="text-right">
                <p className="text-sm text-emerald-400">{dryingProgress.dryLocations} dry</p>
                <p className="text-sm text-red-400">{dryingProgress.wetLocations} wet</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.lastReading')}</p>
            {dryingProgress.latestReadingAt ? (
              <>
                <p className="text-sm text-main font-medium">{formatDateTime(dryingProgress.latestReadingAt)}</p>
                {dryingProgress.readingsOverdue && (
                  <Badge variant="warning" className="mt-1">
                    <Clock size={12} className="mr-1" />
                    Overdue (24h+)
                  </Badge>
                )}
              </>
            ) : (
              <p className="text-sm text-muted">{t('moisture.noReadingsYet')}</p>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.contents')}</p>
            <p className="text-2xl font-bold text-main">{financialSummary.totalItems}</p>
            <p className="text-xs text-muted">{financialSummary.packedOutCount} packed out, {financialSummary.disposedCount} disposed</p>
          </CardContent>
        </Card>
      </div>

      {/* All Dry Banner */}
      {dryingProgress.allDry && dryingProgress.totalLocations > 0 && (
        <div className="bg-emerald-900/20 border border-emerald-700/30 rounded-xl p-4 flex items-center gap-3">
          <CheckCircle2 size={24} className="text-emerald-400" />
          <div>
            <p className="font-medium text-emerald-300">{t('moisture.allLocationsAtTarget')}</p>
            <p className="text-sm text-emerald-400/70">All {dryingProgress.totalLocations} monitored locations have reached or are below their drying goal.</p>
          </div>
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-1 border-b border-main">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={cn(
              'flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors',
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
      {activeTab === 'overview' && <OverviewTab assessment={assessment} readings={readings} psychLogs={psychLogs} dryingProgress={dryingProgress} />}
      {activeTab === 'readings' && <ReadingsTab readings={readings} />}
      {activeTab === 'psychrometric' && <PsychrometricTab psychLogs={psychLogs} onAdd={addPsychrometricLog} jobId={jobId} />}
      {activeTab === 'contents' && <ContentsTab items={items} itemsByRoom={itemsByRoom} financialSummary={financialSummary} onAdd={addItem} />}
    </div>
  );
}

// ============================================================================
// OVERVIEW TAB
// ============================================================================

function OverviewTab({
  assessment,
  readings,
  psychLogs,
  dryingProgress,
}: {
  assessment: ReturnType<typeof useWaterDamageAssessments>['assessments'][0] | undefined;
  readings: ReturnType<typeof useDryingMonitor>['readings'];
  psychLogs: ReturnType<typeof useDryingMonitor>['psychLogs'];
  dryingProgress: ReturnType<typeof useDryingMonitor>['dryingProgress'];
}) {
  const { t } = useTranslation();
  if (!assessment && readings.length === 0) {
    return (
      <Card>
        <CardContent className="p-12 text-center">
          <Droplets size={48} className="mx-auto text-muted mb-4" />
          <h3 className="text-lg font-medium text-main mb-2">{t('moisture.noWaterDamageAssessment')}</h3>
          <p className="text-muted">Create an assessment to start tracking IICRC S500 classification, moisture readings, and drying progress.</p>
        </CardContent>
      </Card>
    );
  }

  // Latest psychrometric reading
  const latestPsych = psychLogs[0];

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Assessment Details */}
      {assessment && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{t('moisture.waterDamageAssessment')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">{t('common.category')}</p>
                <p className={cn('font-semibold', CATEGORY_LABELS[assessment.waterCategory]?.color)}>
                  {CATEGORY_LABELS[assessment.waterCategory]?.label}
                </p>
                <p className="text-xs text-muted mt-0.5">{CATEGORY_LABELS[assessment.waterCategory]?.description}</p>
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">{t('jobsMoisture.class')}</p>
                <p className="font-semibold text-main">{CLASS_LABELS[assessment.waterClass]?.label}</p>
                <p className="text-xs text-muted mt-0.5">{CLASS_LABELS[assessment.waterClass]?.description}</p>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">{t('common.source')}</p>
                <p className="text-main">{SOURCE_LABELS[assessment.sourceType]}</p>
                {assessment.sourceDescription && <p className="text-xs text-muted">{assessment.sourceDescription}</p>}
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">{t('moisture.sourceStopped')}</p>
                <Badge variant={assessment.sourceStopped ? 'success' : 'warning'}>
                  {assessment.sourceStopped ? 'Yes' : 'No'}
                </Badge>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">{t('moisture.totalAffected')}</p>
                <p className="text-main font-medium">{assessment.totalSqftAffected.toLocaleString()} sq ft</p>
                <p className="text-xs text-muted">{assessment.floorsAffected} floor{assessment.floorsAffected > 1 ? 's' : ''}</p>
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">{t('moisture.estDrying')}</p>
                <p className="text-main font-medium">{assessment.estimatedDryingDays ?? '—'} days</p>
              </div>
            </div>
            {(assessment.containmentRequired || assessment.asbestosSuspect || assessment.leadPaintSuspect || assessment.emergencyServicesRequired) && (
              <div className="flex flex-wrap gap-2 pt-2 border-t border-main">
                {assessment.emergencyServicesRequired && <Badge variant="error">{t('moisture.emergencyServices')}</Badge>}
                {assessment.containmentRequired && <Badge variant="warning">{t('moisture.containmentRequired')}</Badge>}
                {assessment.asbestosSuspect && <Badge variant="error">{t('moisture.asbestosSuspect')}</Badge>}
                {assessment.leadPaintSuspect && <Badge variant="error">{t('moisture.leadPaintSuspect')}</Badge>}
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Latest Psychrometric Reading */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t('moisture.latestConditions')}</CardTitle>
        </CardHeader>
        <CardContent>
          {latestPsych ? (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="p-3 bg-blue-900/10 rounded-lg border border-blue-800/20">
                  <p className="text-xs text-blue-400 uppercase tracking-wider mb-1">{t('common.indoor')}</p>
                  <p className="text-lg font-semibold text-main">{latestPsych.indoorTempF}°F / {latestPsych.indoorRh}% RH</p>
                  <p className="text-xs text-muted">
                    GPP: {latestPsych.indoorGpp?.toFixed(1) ?? '—'} | Dew: {latestPsych.indoorDewPointF?.toFixed(1) ?? '—'}°F
                  </p>
                </div>
                <div className="p-3 bg-zinc-800/50 rounded-lg border border-zinc-700/30">
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.outdoor')}</p>
                  {latestPsych.outdoorTempF != null ? (
                    <>
                      <p className="text-lg font-semibold text-main">{latestPsych.outdoorTempF}°F / {latestPsych.outdoorRh}% RH</p>
                      <p className="text-xs text-muted">
                        GPP: {latestPsych.outdoorGpp?.toFixed(1) ?? '—'} | Dew: {latestPsych.outdoorDewPointF?.toFixed(1) ?? '—'}°F
                      </p>
                    </>
                  ) : (
                    <p className="text-sm text-muted">{t('common.notRecorded')}</p>
                  )}
                </div>
              </div>
              <div className="flex items-center gap-4 text-sm text-muted">
                <span className="flex items-center gap-1"><Wind size={14} /> {latestPsych.dehumidifiersRunning} dehu</span>
                <span>{latestPsych.airMoversRunning} air movers</span>
                <span>{latestPsych.airScrubbersRunning} scrubbers</span>
                {latestPsych.heatersRunning > 0 && <span>{latestPsych.heatersRunning} heaters</span>}
              </div>
              <p className="text-xs text-muted">Recorded: {formatDateTime(latestPsych.recordedAt)}</p>
            </div>
          ) : (
            <div className="text-center py-6">
              <Thermometer size={36} className="mx-auto text-muted mb-2" />
              <p className="text-sm text-muted">{t('moisture.noPsychrometricReadings')}</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Location Grid — latest readings by area */}
      <Card className="lg:col-span-2">
        <CardHeader>
          <CardTitle className="text-base">{t('moisture.moistureLocationGrid')}</CardTitle>
        </CardHeader>
        <CardContent>
          {readings.length > 0 ? (
            <LocationGrid readings={readings} />
          ) : (
            <div className="text-center py-8">
              <Droplets size={36} className="mx-auto text-muted mb-2" />
              <p className="text-sm text-muted">{t('moisture.noMoistureReadingsRecorded')}</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================================
// LOCATION GRID — Shows latest reading per area with color coding
// ============================================================================

function LocationGrid({ readings }: { readings: ReturnType<typeof useDryingMonitor>['readings'] }) {
  // Group by area, show latest per area
  const areaMap = new Map<string, typeof readings[0]>();
  for (const r of readings) {
    const key = `${r.areaName}|${r.locationNumber ?? 'x'}`;
    const existing = areaMap.get(key);
    if (!existing || new Date(r.recordedAt) > new Date(existing.recordedAt)) {
      areaMap.set(key, r);
    }
  }
  const locations = Array.from(areaMap.values()).sort((a, b) => {
    if (a.areaName !== b.areaName) return a.areaName.localeCompare(b.areaName);
    return (a.locationNumber ?? 0) - (b.locationNumber ?? 0);
  });

  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-3">
      {locations.map((r) => {
        const target = r.targetValue ?? r.dryingGoalMc ?? MATERIAL_TARGETS[r.materialType] ?? 15;
        const atTarget = r.readingValue <= target;
        const nearTarget = !atTarget && r.readingValue <= target * 1.2;

        return (
          <div
            key={`${r.areaName}-${r.locationNumber}`}
            className={cn(
              'p-3 rounded-lg border text-center',
              atTarget ? 'bg-emerald-900/10 border-emerald-700/30' :
              nearTarget ? 'bg-amber-900/10 border-amber-700/30' :
              'bg-red-900/10 border-red-700/30'
            )}
          >
            <p className="text-xs text-muted truncate">{r.areaName}</p>
            {r.locationNumber != null && <p className="text-xs text-muted">#{r.locationNumber}</p>}
            <p className={cn(
              'text-xl font-bold mt-1',
              atTarget ? 'text-emerald-400' : nearTarget ? 'text-amber-400' : 'text-red-400'
            )}>
              {r.readingValue}
              <span className="text-xs ml-0.5">{r.readingUnit === 'percent' ? '%' : r.readingUnit}</span>
            </p>
            <p className="text-xs text-muted">goal: {target}</p>
            <Badge variant={atTarget ? 'success' : nearTarget ? 'warning' : 'error'} className="mt-1 text-xs">
              {atTarget ? 'DRY' : nearTarget ? 'NEAR' : 'WET'}
            </Badge>
          </div>
        );
      })}
    </div>
  );
}

// ============================================================================
// READINGS TAB — Chronological moisture readings table
// ============================================================================

function ReadingsTab({ readings }: { readings: ReturnType<typeof useDryingMonitor>['readings'] }) {
  const { t } = useTranslation();
  if (readings.length === 0) {
    return (
      <Card><CardContent className="p-12 text-center">
        <Droplets size={48} className="mx-auto text-muted mb-4" />
        <h3 className="text-lg font-medium text-main mb-2">{t('moisture.noMoistureReadings')}</h3>
        <p className="text-muted">{t('jobsMoisture.readingsAreAddedFromTheMobileAppDuringOnsiteMonito')}</p>
      </CardContent></Card>
    );
  }

  return (
    <Card>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-main">
              <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">{t('common.date')}</th>
              <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">{t('common.area')}</th>
              <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">#</th>
              <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">{t('common.material')}</th>
              <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">{t('common.reading')}</th>
              <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">{t('common.target')}</th>
              <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">{t('moisture.refStd')}</th>
              <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase">{t('common.status')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-main">
            {readings.map((r) => {
              const target = r.targetValue ?? r.dryingGoalMc ?? MATERIAL_TARGETS[r.materialType] ?? 15;
              const atTarget = r.readingValue <= target;
              return (
                <tr key={r.id} className={cn('hover:bg-surface-hover', atTarget ? 'bg-emerald-900/5' : 'bg-red-900/5')}>
                  <td className="px-4 py-3 text-main whitespace-nowrap text-xs">{formatDateTime(r.recordedAt)}</td>
                  <td className="px-4 py-3 text-main">{r.areaName}</td>
                  <td className="px-4 py-3 text-muted">{r.locationNumber ?? '—'}</td>
                  <td className="px-4 py-3"><Badge variant="secondary">{r.materialType}</Badge></td>
                  <td className={cn('px-4 py-3 text-right font-mono font-medium', atTarget ? 'text-emerald-400' : 'text-red-400')}>
                    {r.readingValue}{r.readingUnit === 'percent' ? '%' : ` ${r.readingUnit}`}
                  </td>
                  <td className="px-4 py-3 text-right font-mono text-muted">{target}</td>
                  <td className="px-4 py-3 text-right font-mono text-muted">{r.referenceStandard ?? '—'}</td>
                  <td className="px-4 py-3 text-center">
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
  );
}

// ============================================================================
// PSYCHROMETRIC TAB
// ============================================================================

function PsychrometricTab({
  psychLogs,
  onAdd,
  jobId,
}: {
  psychLogs: ReturnType<typeof useDryingMonitor>['psychLogs'];
  onAdd: ReturnType<typeof useDryingMonitor>['addPsychrometricLog'];
  jobId: string;
}) {
  const { t } = useTranslation();
  const [showAdd, setShowAdd] = useState(false);

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <Button onClick={() => setShowAdd(true)}>
          <Plus size={16} />
          Add Reading
        </Button>
      </div>

      {psychLogs.length === 0 ? (
        <Card><CardContent className="p-12 text-center">
          <Thermometer size={48} className="mx-auto text-muted mb-4" />
          <h3 className="text-lg font-medium text-main mb-2">{t('moisture.noPsychrometricLogs')}</h3>
          <p className="text-muted">Track indoor/outdoor temperature, humidity, and GPP to optimize drying.</p>
        </CardContent></Card>
      ) : (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">{t('common.date')}</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">{t('common.room')}</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">{t('common.indoor')}</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">{t('moisture.gppIn')}</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">{t('common.outdoor')}</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">{t('moisture.gppOut')}</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">{t('jobsMoisture.gppDiff')}</th>
                  <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase">{t('common.equipment')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {psychLogs.map((log) => {
                  const gppDiff = log.indoorGpp != null && log.outdoorGpp != null
                    ? (log.indoorGpp - log.outdoorGpp).toFixed(1) : null;
                  return (
                    <tr key={log.id} className="hover:bg-surface-hover">
                      <td className="px-4 py-3 text-main whitespace-nowrap text-xs">{formatDateTime(log.recordedAt)}</td>
                      <td className="px-4 py-3 text-main">{log.roomName || '—'}</td>
                      <td className="px-4 py-3 text-right font-mono text-main">{log.indoorTempF}°F / {log.indoorRh}%</td>
                      <td className="px-4 py-3 text-right font-mono text-blue-400">{log.indoorGpp?.toFixed(1) ?? '—'}</td>
                      <td className="px-4 py-3 text-right font-mono text-muted">
                        {log.outdoorTempF != null ? `${log.outdoorTempF}°F / ${log.outdoorRh}%` : '—'}
                      </td>
                      <td className="px-4 py-3 text-right font-mono text-muted">{log.outdoorGpp?.toFixed(1) ?? '—'}</td>
                      <td className={cn('px-4 py-3 text-right font-mono font-medium',
                        gppDiff != null ? (parseFloat(gppDiff) > 0 ? 'text-amber-400' : 'text-emerald-400') : 'text-muted')}>
                        {gppDiff != null ? `${parseFloat(gppDiff) > 0 ? '+' : ''}${gppDiff}` : '—'}
                      </td>
                      <td className="px-4 py-3 text-center text-xs text-muted">
                        {log.dehumidifiersRunning}D / {log.airMoversRunning}AM / {log.airScrubbersRunning}AS
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {showAdd && <AddPsychrometricModal onClose={() => setShowAdd(false)} onAdd={onAdd} />}
    </div>
  );
}

function AddPsychrometricModal({
  onClose,
  onAdd,
}: {
  onClose: () => void;
  onAdd: ReturnType<typeof useDryingMonitor>['addPsychrometricLog'];
}) {
  const { t } = useTranslation();
  const [indoorTemp, setIndoorTemp] = useState('');
  const [indoorRh, setIndoorRh] = useState('');
  const [outdoorTemp, setOutdoorTemp] = useState('');
  const [outdoorRh, setOutdoorRh] = useState('');
  const [dehuCount, setDehuCount] = useState('0');
  const [amCount, setAmCount] = useState('0');
  const [asCount, setAsCount] = useState('0');
  const [roomName, setRoomName] = useState('');
  const [saving, setSaving] = useState(false);

  const indoorGpp = indoorTemp && indoorRh ? calculateGpp(parseFloat(indoorTemp), parseFloat(indoorRh)) : null;
  const indoorDew = indoorTemp && indoorRh ? calculateDewPoint(parseFloat(indoorTemp), parseFloat(indoorRh)) : null;

  const handleSave = async () => {
    if (!indoorTemp || !indoorRh) return;
    try {
      setSaving(true);
      await onAdd({
        indoorTempF: parseFloat(indoorTemp),
        indoorRh: parseFloat(indoorRh),
        outdoorTempF: outdoorTemp ? parseFloat(outdoorTemp) : undefined,
        outdoorRh: outdoorRh ? parseFloat(outdoorRh) : undefined,
        dehumidifiersRunning: parseInt(dehuCount) || 0,
        airMoversRunning: parseInt(amCount) || 0,
        airScrubbersRunning: parseInt(asCount) || 0,
        roomName: roomName || undefined,
      });
      onClose();
    } catch {
      // Error handled by hook
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>{t('jobsMoisture.addPsychrometricReading')}</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg"><X size={18} className="text-muted" /></button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input label="Room Name" value={roomName} onChange={(e) => setRoomName(e.target.value)} placeholder="Living Room" />
          <div className="grid grid-cols-2 gap-4">
            <Input label="Indoor Temp (°F) *" type="number" value={indoorTemp} onChange={(e) => setIndoorTemp(e.target.value)} placeholder="72" />
            <Input label="Indoor RH (%) *" type="number" value={indoorRh} onChange={(e) => setIndoorRh(e.target.value)} placeholder="55" />
          </div>
          {indoorGpp != null && (
            <div className="p-3 bg-blue-900/10 rounded-lg border border-blue-800/20 text-sm">
              <p className="text-blue-400">Auto-calculated: GPP = {indoorGpp.toFixed(1)} | Dew Point = {indoorDew?.toFixed(1)}°F</p>
            </div>
          )}
          <div className="grid grid-cols-2 gap-4">
            <Input label="Outdoor Temp (°F)" type="number" value={outdoorTemp} onChange={(e) => setOutdoorTemp(e.target.value)} placeholder="45" />
            <Input label="Outdoor RH (%)" type="number" value={outdoorRh} onChange={(e) => setOutdoorRh(e.target.value)} placeholder="65" />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <Input label={t('moisture.dehumidifiers')} type="number" value={dehuCount} onChange={(e) => setDehuCount(e.target.value)} />
            <Input label={t('moisture.airMovers')} type="number" value={amCount} onChange={(e) => setAmCount(e.target.value)} />
            <Input label={t('common.scrubbers')} type="number" value={asCount} onChange={(e) => setAsCount(e.target.value)} />
          </div>
          <div className="flex gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1" onClick={handleSave} disabled={saving || !indoorTemp || !indoorRh}>
              {saving ? 'Saving...' : 'Save Reading'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================================
// CONTENTS TAB
// ============================================================================

function ContentsTab({
  items,
  itemsByRoom,
  financialSummary,
  onAdd,
}: {
  items: ReturnType<typeof useContentsInventory>['items'];
  itemsByRoom: ReturnType<typeof useContentsInventory>['itemsByRoom'];
  financialSummary: ReturnType<typeof useContentsInventory>['financialSummary'];
  onAdd: ReturnType<typeof useContentsInventory>['addItem'];
}) {
  const { t } = useTranslation();
  const [showAdd, setShowAdd] = useState(false);
  const [expandedRooms, setExpandedRooms] = useState<Set<string>>(new Set(Array.from(itemsByRoom.keys())));

  const toggleRoom = (room: string) => {
    const next = new Set(expandedRooms);
    next.has(room) ? next.delete(room) : next.add(room);
    setExpandedRooms(next);
  };

  return (
    <div className="space-y-4">
      {/* Financial Summary */}
      {items.length > 0 && (
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <Card><CardContent className="p-4">
            <p className="text-xs text-muted uppercase">{t('common.totalItems')}</p>
            <p className="text-xl font-bold text-main">{financialSummary.totalItems}</p>
          </CardContent></Card>
          <Card><CardContent className="p-4">
            <p className="text-xs text-muted uppercase">{t('jobsMoisture.prelossValue')}</p>
            <p className="text-xl font-bold text-main">{formatCurrency(financialSummary.totalPreLoss)}</p>
          </CardContent></Card>
          <Card><CardContent className="p-4">
            <p className="text-xs text-muted uppercase">{t('jobsMoisture.replacementValue')}</p>
            <p className="text-xl font-bold text-main">{formatCurrency(financialSummary.totalReplacement)}</p>
          </CardContent></Card>
          <Card><CardContent className="p-4">
            <p className="text-xs text-muted uppercase">{t('common.acv')}</p>
            <p className="text-xl font-bold text-main">{formatCurrency(financialSummary.totalAcv)}</p>
          </CardContent></Card>
        </div>
      )}

      <div className="flex justify-end">
        <Button onClick={() => setShowAdd(true)}><Plus size={16} />{t('common.addItem')}</Button>
      </div>

      {items.length === 0 ? (
        <Card><CardContent className="p-12 text-center">
          <Package size={48} className="mx-auto text-muted mb-4" />
          <h3 className="text-lg font-medium text-main mb-2">{t('jobsMoisture.noContentsInventory')}</h3>
          <p className="text-muted">Track affected contents room-by-room: move, block, pack-out, or dispose.</p>
        </CardContent></Card>
      ) : (
        <div className="space-y-3">
          {Array.from(itemsByRoom.entries()).map(([room, roomItems]) => (
            <Card key={room}>
              <button
                onClick={() => toggleRoom(room)}
                className="w-full flex items-center justify-between px-4 py-3 hover:bg-surface-hover transition-colors"
              >
                <div className="flex items-center gap-3">
                  {expandedRooms.has(room) ? <ChevronDown size={16} className="text-muted" /> : <ChevronRight size={16} className="text-muted" />}
                  <span className="font-medium text-main">{room}</span>
                  <Badge variant="secondary">{roomItems.length} items</Badge>
                </div>
              </button>
              {expandedRooms.has(room) && (
                <div className="border-t border-main">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-main">
                        <th className="text-left px-4 py-2 text-xs text-muted uppercase">#</th>
                        <th className="text-left px-4 py-2 text-xs text-muted uppercase">{t('common.item')}</th>
                        <th className="text-left px-4 py-2 text-xs text-muted uppercase">{t('common.qty')}</th>
                        <th className="text-left px-4 py-2 text-xs text-muted uppercase">{t('common.condition')}</th>
                        <th className="text-left px-4 py-2 text-xs text-muted uppercase">{t('common.action')}</th>
                        <th className="text-right px-4 py-2 text-xs text-muted uppercase">{t('common.value')}</th>
                        <th className="text-left px-4 py-2 text-xs text-muted uppercase">{t('common.status')}</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-main">
                      {roomItems.map((item) => (
                        <tr key={item.id} className="hover:bg-surface-hover">
                          <td className="px-4 py-2 text-muted">{item.itemNumber}</td>
                          <td className="px-4 py-2 text-main">{item.description}</td>
                          <td className="px-4 py-2 text-muted">{item.quantity}</td>
                          <td className="px-4 py-2"><Badge variant="secondary">{item.conditionBefore || '—'}</Badge></td>
                          <td className="px-4 py-2"><Badge variant={item.action === 'dispose' ? 'error' : item.action === 'pack_out' ? 'warning' : 'secondary'}>{ACTION_LABELS[item.action]}</Badge></td>
                          <td className="px-4 py-2 text-right font-mono text-muted">{item.preLossValue ? formatCurrency(item.preLossValue) : '—'}</td>
                          <td className="px-4 py-2"><Badge variant="secondary">{item.status}</Badge></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </Card>
          ))}
        </div>
      )}

      {showAdd && <AddContentsModal onClose={() => setShowAdd(false)} onAdd={onAdd} />}
    </div>
  );
}

function AddContentsModal({
  onClose,
  onAdd,
}: {
  onClose: () => void;
  onAdd: ReturnType<typeof useContentsInventory>['addItem'];
}) {
  const { t } = useTranslation();
  const [description, setDescription] = useState('');
  const [quantity, setQuantity] = useState('1');
  const [roomName, setRoomName] = useState('');
  const [condition, setCondition] = useState<ContentsCondition>('good');
  const [action, setAction] = useState<ContentsAction>('move');
  const [destination, setDestination] = useState('');
  const [preLossValue, setPreLossValue] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!description || !roomName) return;
    try {
      setSaving(true);
      await onAdd({
        description,
        quantity: parseInt(quantity) || 1,
        roomName,
        conditionBefore: condition,
        action,
        destination: destination || undefined,
        preLossValue: preLossValue ? parseFloat(preLossValue) : undefined,
      });
      onClose();
    } catch {
      // Error handled by hook
    } finally {
      setSaving(false);
    }
  };

  const actionOptions = Object.entries(ACTION_LABELS).map(([value, label]) => ({ value, label }));
  const conditionOptions = CONDITION_OPTIONS.map(c => ({ value: c, label: c.charAt(0).toUpperCase() + c.slice(1) }));

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>{t('jobsMoisture.addContentsItem')}</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg"><X size={18} className="text-muted" /></button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input label="Room *" value={roomName} onChange={(e) => setRoomName(e.target.value)} placeholder="Living Room" />
          <Input label="Item Description *" value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Samsung 65 TV" />
          <div className="grid grid-cols-2 gap-4">
            <Input label="Quantity" type="number" value={quantity} onChange={(e) => setQuantity(e.target.value)} />
            <Input label="Pre-Loss Value ($)" type="number" value={preLossValue} onChange={(e) => setPreLossValue(e.target.value)} placeholder="0.00" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Condition *</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={condition}
                onChange={(e) => setCondition(e.target.value as ContentsCondition)}
              >
                {conditionOptions.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Action *</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={action}
                onChange={(e) => setAction(e.target.value as ContentsAction)}
              >
                {actionOptions.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
          </div>
          {(action === 'move' || action === 'pack_out') && (
            <Input label="Destination" value={destination} onChange={(e) => setDestination(e.target.value)} placeholder="Garage / Storage Unit #4" />
          )}
          <div className="flex gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1" onClick={handleSave} disabled={saving || !description || !roomName}>
              {saving ? 'Saving...' : 'Save Item'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================================
// CREATE ASSESSMENT BUTTON (with modal)
// ============================================================================

function CreateAssessmentButton({
  onCreate,
  jobId,
}: {
  onCreate: ReturnType<typeof useWaterDamageAssessments>['createAssessment'];
  jobId: string;
}) {
  const { t } = useTranslation();
  const [showModal, setShowModal] = useState(false);
  const [category, setCategory] = useState<WaterCategory>(1);
  const [waterClass, setWaterClass] = useState<WaterClass>(1);
  const [sourceType, setSourceType] = useState<WaterSourceType>('unknown');
  const [sourceDesc, setSourceDesc] = useState('');
  const [lossDate, setLossDate] = useState(new Date().toISOString().split('T')[0]);
  const [sqft, setSqft] = useState('');
  const [dryingDays, setDryingDays] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    try {
      setSaving(true);
      await onCreate({
        waterCategory: category,
        waterClass: waterClass,
        sourceType,
        sourceDescription: sourceDesc || undefined,
        lossDate: new Date(lossDate).toISOString(),
        totalSqftAffected: sqft ? parseFloat(sqft) : undefined,
        estimatedDryingDays: dryingDays ? parseInt(dryingDays) : undefined,
      });
      setShowModal(false);
    } catch {
      // Error handled by hook
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <Button onClick={() => setShowModal(true)}><Plus size={16} />{t('jobsMoisture.createAssessment')}</Button>
      {showModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>IICRC S500 Water Damage Assessment</CardTitle>
                <button onClick={() => setShowModal(false)} className="p-1.5 hover:bg-surface-hover rounded-lg"><X size={18} className="text-muted" /></button>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Water Category *</label>
                {[1, 2, 3].map((c) => (
                  <label key={c} className={cn('flex items-start gap-3 p-3 rounded-lg border mb-2 cursor-pointer transition-colors',
                    category === c ? 'border-blue-500 bg-blue-900/10' : 'border-main hover:bg-surface-hover')}>
                    <input type="radio" name="category" checked={category === c} onChange={() => setCategory(c as WaterCategory)} className="mt-1" />
                    <div>
                      <p className={cn('font-medium', CATEGORY_LABELS[c].color)}>{CATEGORY_LABELS[c].label}</p>
                      <p className="text-xs text-muted">{CATEGORY_LABELS[c].description}</p>
                    </div>
                  </label>
                ))}
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Water Class *</label>
                <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                  value={waterClass} onChange={(e) => setWaterClass(parseInt(e.target.value) as WaterClass)}>
                  {[1, 2, 3, 4].map(c => (
                    <option key={c} value={c}>{CLASS_LABELS[c].label} — {CLASS_LABELS[c].description}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Source Type *</label>
                <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                  value={sourceType} onChange={(e) => setSourceType(e.target.value as WaterSourceType)}>
                  {Object.entries(SOURCE_LABELS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                </select>
              </div>
              <Input label="Source Description" value={sourceDesc} onChange={(e) => setSourceDesc(e.target.value)} placeholder="2nd floor bathroom supply line burst" />
              <div className="grid grid-cols-3 gap-4">
                <Input label="Loss Date *" type="date" value={lossDate} onChange={(e) => setLossDate(e.target.value)} />
                <Input label="Affected Sq Ft" type="number" value={sqft} onChange={(e) => setSqft(e.target.value)} placeholder="0" />
                <Input label="Est. Drying Days" type="number" value={dryingDays} onChange={(e) => setDryingDays(e.target.value)} placeholder="3" />
              </div>
              <div className="flex gap-3 pt-4">
                <Button variant="secondary" className="flex-1" onClick={() => setShowModal(false)}>{t('common.cancel')}</Button>
                <Button className="flex-1" onClick={handleSave} disabled={saving}>
                  {saving ? 'Creating...' : 'Create Assessment'}
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </>
  );
}
