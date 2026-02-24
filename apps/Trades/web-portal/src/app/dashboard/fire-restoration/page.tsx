'use client';

import { useState, useMemo } from 'react';
import { useTranslation } from '@/lib/translations';
import {
  Flame,
  Plus,
  ChevronRight,
  Building,
  AlertTriangle,
  PackageOpen,
  Wind,
  Shield,
  Trash2,
  Camera,
  ClipboardList,
  Layers,
  ChevronDown,
  CheckCircle,
  XCircle,
  Eye,
  Box,
  Thermometer,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDateTime, cn } from '@/lib/utils';
import {
  useFireRestoration,
  useContentPackout,
  SOOT_TYPE_INFO,
} from '@/lib/hooks/use-fire-restoration';
import type {
  FireAssessment,
  DamageSeverity,
  AssessmentStatus,
  DamageZone,
  SootType,
  OdorTreatment,
  OdorTreatmentMethod,
  ContentPackoutItem,
  ContentCategory,
  ContentCondition,
  CleaningMethod,
} from '@/lib/hooks/use-fire-restoration';
import { formatCurrency } from '@/lib/format-locale';

// =============================================================================
// CONFIG
// =============================================================================

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

const severityConfig: Record<DamageSeverity, { label: string; variant: 'info' | 'default' | 'warning' | 'error' }> = {
  minor: { label: 'Minor', variant: 'info' },
  moderate: { label: 'Moderate', variant: 'warning' },
  major: { label: 'Major', variant: 'error' },
  total_loss: { label: 'Total Loss', variant: 'error' },
};

const statusConfig: Record<AssessmentStatus, { label: string; variant: 'info' | 'default' | 'warning' | 'success' | 'secondary' }> = {
  in_progress: { label: 'In Progress', variant: 'info' },
  pending_review: { label: 'Pending Review', variant: 'warning' },
  approved: { label: 'Approved', variant: 'success' },
  submitted_to_carrier: { label: 'Submitted', variant: 'secondary' },
};

const severityOptions = [
  { value: 'all', label: 'All Severities' },
  { value: 'minor', label: 'Minor' },
  { value: 'moderate', label: 'Moderate' },
  { value: 'major', label: 'Major' },
  { value: 'total_loss', label: 'Total Loss' },
];

type DetailTab = 'overview' | 'rooms' | 'packout' | 'deodorization' | 'structural' | 'photos';

const DETAIL_TABS: { key: DetailTab; label: string; icon: LucideIcon }[] = [
  { key: 'overview', label: 'Overview', icon: Eye },
  { key: 'rooms', label: 'Room Assessment', icon: Layers },
  { key: 'packout', label: 'Content Pack-out', icon: PackageOpen },
  { key: 'deodorization', label: 'Deodorization', icon: Wind },
  { key: 'structural', label: 'Structural', icon: Building },
  { key: 'photos', label: 'Photos', icon: Camera },
];

const SOOT_TYPES: SootType[] = ['wet_smoke', 'dry_smoke', 'protein', 'fuel_oil', 'mixed'];
const ODOR_METHODS: { value: OdorTreatmentMethod; label: string }[] = [
  { value: 'thermal_fog', label: 'Thermal Fogging' },
  { value: 'ozone', label: 'Ozone Treatment' },
  { value: 'hydroxyl', label: 'Hydroxyl Generator' },
  { value: 'air_scrub', label: 'HEPA Air Scrubbing' },
  { value: 'sealer', label: 'Sealant/Encapsulant' },
];

const CONTENT_CATEGORIES: { value: ContentCategory; label: string }[] = [
  { value: 'electronics', label: 'Electronics' },
  { value: 'soft_goods', label: 'Soft Goods' },
  { value: 'hard_goods', label: 'Hard Goods' },
  { value: 'documents', label: 'Documents' },
  { value: 'artwork', label: 'Artwork' },
  { value: 'furniture', label: 'Furniture' },
  { value: 'clothing', label: 'Clothing' },
  { value: 'appliances', label: 'Appliances' },
  { value: 'kitchenware', label: 'Kitchenware' },
  { value: 'personal', label: 'Personal Items' },
  { value: 'tools', label: 'Tools' },
  { value: 'sporting', label: 'Sporting Goods' },
  { value: 'other', label: 'Other' },
];

const CONTENT_CONDITIONS: { value: ContentCondition; label: string }[] = [
  { value: 'salvageable', label: 'Salvageable' },
  { value: 'non_salvageable', label: 'Non-Salvageable' },
  { value: 'needs_cleaning', label: 'Needs Cleaning' },
  { value: 'needs_restoration', label: 'Needs Restoration' },
  { value: 'questionable', label: 'Questionable' },
];

const CLEANING_METHODS: { value: CleaningMethod; label: string }[] = [
  { value: 'dry_clean', label: 'Dry Clean' },
  { value: 'wet_clean', label: 'Wet Clean' },
  { value: 'ultrasonic', label: 'Ultrasonic' },
  { value: 'ozone', label: 'Ozone' },
  { value: 'immersion', label: 'Immersion' },
  { value: 'soda_blast', label: 'Soda Blast' },
  { value: 'dry_ice_blast', label: 'Dry Ice Blast' },
  { value: 'hand_wipe', label: 'Hand Wipe' },
  { value: 'laundry', label: 'Laundry' },
  { value: 'none', label: 'None (Dispose)' },
];

// =============================================================================
// PAGE
// =============================================================================

export default function FireRestorationPage() {
  const { t } = useTranslation();
  const { assessments, loading, error, updateAssessment } = useFireRestoration();
  const [searchQuery, setSearchQuery] = useState('');
  const [severityFilter, setSeverityFilter] = useState('all');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const filtered = assessments.filter((a) => {
    if (severityFilter !== 'all' && a.damageSeverity !== severityFilter) return false;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      return (
        (a.originRoom || '').toLowerCase().includes(q) ||
        (a.originDescription || '').toLowerCase().includes(q) ||
        (a.fireDepartmentReportNumber || '').toLowerCase().includes(q) ||
        (a.notes || '').toLowerCase().includes(q)
      );
    }
    return true;
  });

  const selected = assessments.find((a) => a.id === selectedId) || null;

  // Stats
  const totalAssessments = assessments.length;
  const totalZones = assessments.reduce((s, a) => s + a.damageZones.length, 0);
  const structural = assessments.filter((a) =>
    a.structuralCompromise || a.roofDamage || a.foundationDamage || a.loadBearingAffected
  ).length;
  const waterSuppression = assessments.filter((a) => a.waterDamageFromSuppression).length;

  return (
    <>
      <CommandPalette />
      <div className="flex flex-col gap-6 p-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-foreground">{t('fireRestoration.title')}</h1>
            <p className="text-sm text-muted-foreground">
              Fire damage assessments, soot classification, content pack-out, deodorization, structural assessment
            </p>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-4 gap-4">
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-orange-500/10">
                  <Flame className="h-5 w-5 text-orange-500" />
                </div>
                <div>
                  <p className="text-2xl font-bold">{totalAssessments}</p>
                  <p className="text-xs text-muted-foreground">{t('fireRestoration.assessments')}</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-red-500/10">
                  <Building className="h-5 w-5 text-red-500" />
                </div>
                <div>
                  <p className="text-2xl font-bold">{totalZones}</p>
                  <p className="text-xs text-muted-foreground">{t('fireRestoration.damageZones')}</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-yellow-500/10">
                  <AlertTriangle className="h-5 w-5 text-yellow-500" />
                </div>
                <div>
                  <p className="text-2xl font-bold">{structural}</p>
                  <p className="text-xs text-muted-foreground">{t('common.structural')}</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-blue-500/10">
                  <Wind className="h-5 w-5 text-blue-500" />
                </div>
                <div>
                  <p className="text-2xl font-bold">{waterSuppression}</p>
                  <p className="text-xs text-muted-foreground">{t('fireRestoration.waterSuppression')}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Filters */}
        <div className="flex items-center gap-3">
          <SearchInput
            placeholder="Search assessments..."
            value={searchQuery}
            onChange={(v) => setSearchQuery(v)}
            className="max-w-xs"
          />
          <Select
            value={severityFilter}
            onChange={(e) => setSeverityFilter(e.target.value)}
            options={severityOptions}
          />
        </div>

        {/* Content */}
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
          </div>
        ) : error ? (
          <Card>
            <CardContent className="py-10 text-center">
              <AlertTriangle className="mx-auto mb-2 h-8 w-8 text-destructive" />
              <p className="text-sm text-destructive">{error}</p>
            </CardContent>
          </Card>
        ) : filtered.length === 0 ? (
          <Card>
            <CardContent className="py-16 text-center">
              <Flame className="mx-auto mb-3 h-12 w-12 text-muted-foreground/30" />
              <p className="text-sm font-medium text-muted-foreground">{t('fireRestoration.noRecords')}</p>
              <p className="mt-1 text-xs text-muted-foreground/70">
                Fire assessments are created from job details
              </p>
            </CardContent>
          </Card>
        ) : (
          <div className="grid grid-cols-1 gap-6 xl:grid-cols-[380px_1fr]">
            {/* Assessment List */}
            <div className="space-y-3 max-h-[calc(100vh-320px)] overflow-y-auto pr-1">
              {filtered.map((a) => (
                <Card
                  key={a.id}
                  className={cn(
                    'cursor-pointer transition-colors hover:bg-accent/50',
                    selectedId === a.id && 'border-primary'
                  )}
                  onClick={() => setSelectedId(a.id)}
                >
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <Flame className="h-4 w-4 text-orange-500" />
                          <span className="text-sm font-medium">
                            {a.originRoom || 'Unspecified origin'}
                          </span>
                        </div>
                        {a.originDescription && (
                          <p className="text-xs text-muted-foreground line-clamp-2">
                            {a.originDescription}
                          </p>
                        )}
                        <div className="flex items-center gap-2 pt-1">
                          <Badge variant={severityConfig[a.damageSeverity]?.variant || 'default'}>
                            {severityConfig[a.damageSeverity]?.label || a.damageSeverity}
                          </Badge>
                          <Badge variant={statusConfig[a.assessmentStatus]?.variant || 'default'}>
                            {statusConfig[a.assessmentStatus]?.label || a.assessmentStatus}
                          </Badge>
                        </div>
                        <div className="flex items-center gap-3 text-xs text-muted-foreground pt-0.5">
                          {a.damageZones.length > 0 && (
                            <span>{a.damageZones.length} zone{a.damageZones.length !== 1 ? 's' : ''}</span>
                          )}
                          {a.odorTreatments.length > 0 && (
                            <span>{a.odorTreatments.length} treatment{a.odorTreatments.length !== 1 ? 's' : ''}</span>
                          )}
                          {a.boardUpEntries.length > 0 && (
                            <span>{a.boardUpEntries.length} board-up{a.boardUpEntries.length !== 1 ? 's' : ''}</span>
                          )}
                        </div>
                      </div>
                      <ChevronRight className="mt-1 h-4 w-4 text-muted-foreground" />
                    </div>
                    <div className="mt-2 flex items-center gap-3 text-xs text-muted-foreground">
                      {a.fireDepartmentReportNumber && (
                        <span>FD# {a.fireDepartmentReportNumber}</span>
                      )}
                      <span>{formatDateTime(a.createdAt)}</span>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>

            {/* Detail Panel */}
            {selected ? (
              <AssessmentDetail assessment={selected} onUpdate={updateAssessment} />
            ) : (
              <Card>
                <CardContent className="flex items-center justify-center py-20">
                  <p className="text-sm text-muted-foreground">
                    Select an assessment to view details
                  </p>
                </CardContent>
              </Card>
            )}
          </div>
        )}
      </div>
    </>
  );
}

// =============================================================================
// DETAIL PANEL — TABBED
// =============================================================================

function AssessmentDetail({
  assessment,
  onUpdate,
}: {
  assessment: FireAssessment;
  onUpdate: (id: string, updates: Partial<Record<string, unknown>>) => Promise<void>;
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
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:bg-accent/50'
              )}
            >
              <Icon size={14} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {activeTab === 'overview' && <OverviewTab assessment={assessment} />}
      {activeTab === 'rooms' && <RoomAssessmentTab assessment={assessment} onUpdate={onUpdate} />}
      {activeTab === 'packout' && <ContentPackoutTab assessment={assessment} />}
      {activeTab === 'deodorization' && <DeodorizationTab assessment={assessment} onUpdate={onUpdate} />}
      {activeTab === 'structural' && <StructuralTab assessment={assessment} onUpdate={onUpdate} />}
      {activeTab === 'photos' && <PhotosTab assessment={assessment} />}
    </div>
  );
}

// =============================================================================
// OVERVIEW TAB
// =============================================================================

function OverviewTab({ assessment }: { assessment: FireAssessment }) {
  const { t: tr } = useTranslation();
  const { stats } = useContentPackout(assessment.id);

  const completionScore = useMemo(() => {
    let score = 0;
    let total = 0;
    // Damage zones documented
    total += 1;
    if (assessment.damageZones.length > 0) score += 1;
    // Soot types classified
    total += 1;
    if (assessment.sootAssessments.length > 0) score += 1;
    // Odor treatment planned
    total += 1;
    if (assessment.odorTreatments.length > 0) score += 1;
    // Structural assessed
    total += 1;
    if (assessment.structuralNotes || assessment.structuralCompromise || assessment.roofDamage || assessment.foundationDamage) score += 1;
    // Board-up completed
    total += 1;
    if (assessment.boardUpEntries.length > 0) score += 1;
    // Content pack-out
    total += 1;
    if (stats.totalItems > 0) score += 1;
    // Fire dept report
    total += 1;
    if (assessment.fireDepartmentReportNumber) score += 1;
    // Photos
    total += 1;
    if (assessment.photos.length > 0) score += 1;
    return { score, total, percent: total > 0 ? Math.round((score / total) * 100) : 0 };
  }, [assessment, stats.totalItems]);

  return (
    <div className="space-y-4">
      {/* Completion Score */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center justify-between mb-3">
            <span className="text-sm font-medium">Assessment Completion</span>
            <span className="text-sm font-bold">{completionScore.percent}%</span>
          </div>
          <div className="w-full h-2 bg-accent rounded-full overflow-hidden">
            <div
              className={cn(
                'h-full rounded-full transition-all',
                completionScore.percent >= 80 ? 'bg-green-500' :
                completionScore.percent >= 50 ? 'bg-yellow-500' : 'bg-red-500'
              )}
              style={{ width: `${completionScore.percent}%` }}
            />
          </div>
          <p className="text-xs text-muted-foreground mt-2">
            {completionScore.score} of {completionScore.total} sections documented
          </p>
        </CardContent>
      </Card>

      {/* Overview Grid */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{tr('fireRestoration.assessmentOverview')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3 text-sm">
          <div className="grid grid-cols-2 gap-3">
            <InfoField label={tr('fireRestoration.origin')} value={assessment.originRoom || 'Not specified'} />
            <InfoField label={tr('common.severity')}>
              <Badge variant={severityConfig[assessment.damageSeverity]?.variant || 'default'}>
                {severityConfig[assessment.damageSeverity]?.label}
              </Badge>
            </InfoField>
            <InfoField label={tr('fireRestoration.fdReport')} value={assessment.fireDepartmentReportNumber || '—'} />
            <InfoField label={tr('common.status')}>
              <Badge variant={statusConfig[assessment.assessmentStatus]?.variant || 'default'}>
                {statusConfig[assessment.assessmentStatus]?.label}
              </Badge>
            </InfoField>
            <InfoField label="Fire Dept" value={assessment.fireDepartmentName || '—'} />
            <InfoField label="Date of Loss" value={assessment.dateOfLoss ? formatDateTime(assessment.dateOfLoss) : '—'} />
          </div>

          {assessment.originDescription && (
            <div>
              <p className="text-xs text-muted-foreground mb-1">Description</p>
              <p className="text-sm">{assessment.originDescription}</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Quick Stats Row */}
      <div className="grid grid-cols-4 gap-3">
        <MiniStat icon={Layers} label="Damage Zones" value={assessment.damageZones.length} />
        <MiniStat icon={Wind} label="Treatments" value={assessment.odorTreatments.length} />
        <MiniStat icon={Shield} label="Board-Ups" value={assessment.boardUpEntries.length} />
        <MiniStat icon={PackageOpen} label="Pack-out Items" value={stats.totalItems} />
      </div>

      {/* Structural Flags */}
      {(assessment.structuralCompromise || assessment.roofDamage ||
        assessment.foundationDamage || assessment.loadBearingAffected) && (
        <Card className="border-red-500/30">
          <CardContent className="pt-4 pb-4">
            <div className="flex items-center gap-2 text-sm font-medium text-red-500 mb-2">
              <AlertTriangle className="h-4 w-4" />
              Structural Concerns Identified
            </div>
            <div className="flex flex-wrap gap-1.5">
              {assessment.structuralCompromise && <Badge variant="error">Structural Compromise</Badge>}
              {assessment.roofDamage && <Badge variant="error">Roof Damage</Badge>}
              {assessment.foundationDamage && <Badge variant="error">Foundation Damage</Badge>}
              {assessment.loadBearingAffected && <Badge variant="error">Load-Bearing Affected</Badge>}
              {assessment.waterDamageFromSuppression && <Badge variant="warning">Water Suppression Damage</Badge>}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Notes */}
      {assessment.notes && (
        <Card>
          <CardHeader><CardTitle className="text-base">Notes</CardTitle></CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground whitespace-pre-wrap">{assessment.notes}</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// =============================================================================
// ROOM ASSESSMENT TAB
// =============================================================================

function RoomAssessmentTab({
  assessment,
  onUpdate,
}: {
  assessment: FireAssessment;
  onUpdate: (id: string, updates: Partial<Record<string, unknown>>) => Promise<void>;
}) {
  const [expandedRoom, setExpandedRoom] = useState<number | null>(null);

  // Group zones + soot assessments by room
  const rooms = useMemo(() => {
    const roomMap = new Map<string, {
      zones: DamageZone[];
      sootAssessments: { room: string; soot_type: SootType; surface_types: string[]; cleaning_method: string; notes?: string }[];
    }>();

    for (const zone of assessment.damageZones) {
      const existing = roomMap.get(zone.room) || { zones: [], sootAssessments: [] };
      existing.zones.push(zone);
      roomMap.set(zone.room, existing);
    }

    for (const soot of assessment.sootAssessments) {
      const existing = roomMap.get(soot.room) || { zones: [], sootAssessments: [] };
      existing.sootAssessments.push(soot);
      roomMap.set(soot.room, existing);
    }

    return Array.from(roomMap.entries()).map(([room, data]) => ({ room, ...data }));
  }, [assessment.damageZones, assessment.sootAssessments]);

  if (rooms.length === 0) {
    return (
      <Card>
        <CardContent className="py-16 text-center">
          <Layers className="mx-auto mb-3 h-12 w-12 text-muted-foreground/30" />
          <p className="text-sm font-medium text-muted-foreground">No rooms assessed yet</p>
          <p className="mt-1 text-xs text-muted-foreground/70">
            Room-by-room assessments document soot type, char depth, smoke damage level, and content salvageability per room
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between mb-2">
        <p className="text-sm font-medium">{rooms.length} room{rooms.length !== 1 ? 's' : ''} assessed</p>
      </div>

      {rooms.map((room, idx) => {
        const isExpanded = expandedRoom === idx;
        const primaryZone = room.zones[0];
        const primarySoot = room.sootAssessments[0];

        return (
          <Card key={idx}>
            <button
              className="w-full text-left"
              onClick={() => setExpandedRoom(isExpanded ? null : idx)}
            >
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className={cn(
                      'flex h-8 w-8 items-center justify-center rounded-lg text-xs font-bold',
                      primaryZone?.severity === 'heavy' ? 'bg-red-500/15 text-red-400' :
                      primaryZone?.severity === 'moderate' ? 'bg-yellow-500/15 text-yellow-400' :
                      'bg-blue-500/15 text-blue-400'
                    )}>
                      {idx + 1}
                    </div>
                    <div>
                      <p className="text-sm font-medium">{room.room}</p>
                      <div className="flex items-center gap-2 mt-0.5">
                        {primaryZone && (
                          <Badge variant={
                            primaryZone.severity === 'heavy' ? 'error' :
                            primaryZone.severity === 'moderate' ? 'warning' : 'info'
                          }>
                            {primaryZone.severity} {primaryZone.zone_type.replace(/_/g, ' ')}
                          </Badge>
                        )}
                        {primarySoot && (
                          <Badge variant="secondary">
                            {SOOT_TYPE_INFO[primarySoot.soot_type]?.label || primarySoot.soot_type}
                          </Badge>
                        )}
                      </div>
                    </div>
                  </div>
                  {isExpanded ? <ChevronDown size={16} className="text-muted-foreground" /> : <ChevronRight size={16} className="text-muted-foreground" />}
                </div>
              </CardContent>
            </button>

            {isExpanded && (
              <CardContent className="pt-0 pb-4 px-4 space-y-4">
                <div className="border-t border-main pt-4" />

                {/* All Damage Zones in this room */}
                {room.zones.length > 0 && (
                  <div>
                    <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2">
                      Damage Zones ({room.zones.length})
                    </p>
                    <div className="space-y-2">
                      {room.zones.map((zone, zi) => (
                        <div key={zi} className="rounded-lg bg-accent/50 p-3">
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-sm font-medium">{zone.zone_type.replace(/_/g, ' ')}</span>
                            <Badge variant={
                              zone.severity === 'heavy' ? 'error' :
                              zone.severity === 'moderate' ? 'warning' : 'info'
                            }>
                              {zone.severity}
                            </Badge>
                          </div>
                          {zone.soot_type && (
                            <div className="mt-2">
                              <p className="text-xs text-muted-foreground">
                                Soot: {SOOT_TYPE_INFO[zone.soot_type]?.label} — {SOOT_TYPE_INFO[zone.soot_type]?.description}
                              </p>
                              <p className="text-xs text-muted-foreground mt-1">
                                Cleaning: {SOOT_TYPE_INFO[zone.soot_type]?.cleaningMethod}
                              </p>
                            </div>
                          )}
                          {zone.notes && (
                            <p className="text-xs text-muted-foreground mt-1">{zone.notes}</p>
                          )}
                          {zone.photos.length > 0 && (
                            <div className="flex items-center gap-1 mt-2 text-xs text-muted-foreground">
                              <Camera size={12} />
                              {zone.photos.length} photo{zone.photos.length !== 1 ? 's' : ''}
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Soot Assessments */}
                {room.sootAssessments.length > 0 && (
                  <div>
                    <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2">
                      Soot Classification
                    </p>
                    {room.sootAssessments.map((soot, si) => (
                      <div key={si} className="rounded-lg bg-accent/30 p-3 space-y-1">
                        <div className="flex items-center gap-2">
                          <Badge variant="secondary">{SOOT_TYPE_INFO[soot.soot_type]?.label}</Badge>
                        </div>
                        <p className="text-xs text-muted-foreground">{SOOT_TYPE_INFO[soot.soot_type]?.description}</p>
                        {soot.surface_types.length > 0 && (
                          <p className="text-xs text-muted-foreground">
                            Surfaces: {soot.surface_types.join(', ')}
                          </p>
                        )}
                        <p className="text-xs text-muted-foreground">
                          Cleaning: {soot.cleaning_method || SOOT_TYPE_INFO[soot.soot_type]?.cleaningMethod}
                        </p>
                        {soot.notes && <p className="text-xs text-muted-foreground">{soot.notes}</p>}
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            )}
          </Card>
        );
      })}
    </div>
  );
}

// =============================================================================
// CONTENT PACK-OUT TAB
// =============================================================================

function ContentPackoutTab({ assessment }: { assessment: FireAssessment }) {
  const { items, stats, loading } = useContentPackout(assessment.id);
  const [filterCategory, setFilterCategory] = useState('all');
  const [filterCondition, setFilterCondition] = useState('all');
  const [expandedItem, setExpandedItem] = useState<string | null>(null);

  const filtered = items.filter((item) => {
    if (filterCategory !== 'all' && item.category !== filterCategory) return false;
    if (filterCondition !== 'all' && item.condition !== filterCondition) return false;
    return true;
  });

  // Group by room
  const byRoom = useMemo(() => {
    const map = new Map<string, ContentPackoutItem[]>();
    for (const item of filtered) {
      const existing = map.get(item.roomOfOrigin) || [];
      existing.push(item);
      map.set(item.roomOfOrigin, existing);
    }
    return Array.from(map.entries());
  }, [filtered]);

  // Box summary
  const boxes = useMemo(() => {
    const boxMap = new Map<string, number>();
    for (const item of items) {
      if (item.boxNumber) {
        boxMap.set(item.boxNumber, (boxMap.get(item.boxNumber) || 0) + 1);
      }
    }
    return Array.from(boxMap.entries()).sort((a, b) => a[0].localeCompare(b[0]));
  }, [items]);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Stats Row */}
      <div className="grid grid-cols-3 gap-3">
        <Card>
          <CardContent className="pt-4 pb-3 text-center">
            <p className="text-xl font-bold">{stats.totalItems}</p>
            <p className="text-xs text-muted-foreground">Total Items</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3 text-center">
            <p className="text-xl font-bold">{stats.salvageable}</p>
            <p className="text-xs text-muted-foreground">Salvageable</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3 text-center">
            <p className="text-xl font-bold">{formatCurrency(stats.totalEstimatedValue)}</p>
            <p className="text-xs text-muted-foreground">Est. Value</p>
          </CardContent>
        </Card>
      </div>

      {/* Pack-out Progress */}
      <Card>
        <CardContent className="pt-4 pb-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium">Pack-out Progress</span>
            <span className="text-sm font-bold">
              {stats.totalItems > 0 ? Math.round((stats.packed / stats.totalItems) * 100) : 0}%
            </span>
          </div>
          <div className="w-full h-2 bg-accent rounded-full overflow-hidden">
            <div
              className="h-full bg-blue-500 rounded-full transition-all"
              style={{ width: `${stats.totalItems > 0 ? (stats.packed / stats.totalItems) * 100 : 0}%` }}
            />
          </div>
          <div className="flex items-center justify-between mt-2 text-xs text-muted-foreground">
            <span>{stats.packed} packed</span>
            <span>{stats.returned} returned</span>
          </div>
        </CardContent>
      </Card>

      {/* Box Summary */}
      {boxes.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm flex items-center gap-2">
              <Box size={14} />
              Box Inventory ({boxes.length} boxes)
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2">
              {boxes.map(([boxNum, count]) => (
                <div key={boxNum} className="flex items-center gap-1.5 px-2.5 py-1.5 bg-accent/50 rounded-lg text-xs">
                  <Box size={12} className="text-muted-foreground" />
                  <span className="font-medium">Box {boxNum}</span>
                  <span className="text-muted-foreground">({count} items)</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Filters */}
      <div className="flex items-center gap-3">
        <select
          className="px-3 py-1.5 bg-secondary border border-main rounded-lg text-main text-xs"
          value={filterCategory}
          onChange={(e) => setFilterCategory(e.target.value)}
        >
          <option value="all">All Categories</option>
          {CONTENT_CATEGORIES.map((c) => (
            <option key={c.value} value={c.value}>{c.label}</option>
          ))}
        </select>
        <select
          className="px-3 py-1.5 bg-secondary border border-main rounded-lg text-main text-xs"
          value={filterCondition}
          onChange={(e) => setFilterCondition(e.target.value)}
        >
          <option value="all">All Conditions</option>
          {CONTENT_CONDITIONS.map((c) => (
            <option key={c.value} value={c.value}>{c.label}</option>
          ))}
        </select>
        <span className="text-xs text-muted-foreground ml-auto">{filtered.length} items</span>
      </div>

      {/* Items by Room */}
      {filtered.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <PackageOpen className="mx-auto mb-3 h-10 w-10 text-muted-foreground/30" />
            <p className="text-sm text-muted-foreground">No content items documented</p>
            <p className="text-xs text-muted-foreground/70 mt-1">
              Content pack-out items are inventoried room-by-room with condition and box assignments
            </p>
          </CardContent>
        </Card>
      ) : (
        byRoom.map(([room, roomItems]) => (
          <Card key={room}>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm">{room} ({roomItems.length} items)</CardTitle>
            </CardHeader>
            <CardContent className="space-y-1.5">
              {roomItems.map((item) => {
                const isExpanded = expandedItem === item.id;
                return (
                  <div key={item.id}>
                    <button
                      className="w-full text-left rounded-lg bg-accent/30 hover:bg-accent/50 p-3 transition-colors"
                      onClick={() => setExpandedItem(isExpanded ? null : item.id)}
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          {item.condition === 'salvageable' || item.condition === 'needs_cleaning' || item.condition === 'needs_restoration' ? (
                            <CheckCircle size={14} className="text-green-500" />
                          ) : item.condition === 'non_salvageable' ? (
                            <XCircle size={14} className="text-red-500" />
                          ) : (
                            <AlertTriangle size={14} className="text-yellow-500" />
                          )}
                          <span className="text-sm">{item.itemDescription}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          {item.boxNumber && (
                            <span className="text-xs bg-accent px-1.5 py-0.5 rounded">Box {item.boxNumber}</span>
                          )}
                          <Badge variant={
                            item.condition === 'salvageable' ? 'success' :
                            item.condition === 'non_salvageable' ? 'error' :
                            item.condition === 'needs_cleaning' ? 'info' :
                            item.condition === 'needs_restoration' ? 'warning' : 'default'
                          }>
                            {CONTENT_CONDITIONS.find((c) => c.value === item.condition)?.label || item.condition}
                          </Badge>
                        </div>
                      </div>
                    </button>

                    {isExpanded && (
                      <div className="ml-6 mt-2 p-3 bg-accent/20 rounded-lg text-xs space-y-2">
                        <div className="grid grid-cols-2 gap-2">
                          <InfoField label="Category" value={CONTENT_CATEGORIES.find((c) => c.value === item.category)?.label || item.category} />
                          <InfoField label="Cleaning Method" value={item.cleaningMethod ? CLEANING_METHODS.find((c) => c.value === item.cleaningMethod)?.label || item.cleaningMethod : 'Not assigned'} />
                          <InfoField label="Box #" value={item.boxNumber || 'Unboxed'} />
                          <InfoField label="Storage" value={item.storageLocation || 'Not specified'} />
                          <InfoField label="Est. Value" value={item.estimatedValue ? formatCurrency(item.estimatedValue) : '—'} />
                          <InfoField label="Replacement" value={item.replacementCost ? formatCurrency(item.replacementCost) : '—'} />
                          <InfoField label="Packed" value={item.packedAt ? formatDateTime(item.packedAt) : 'Not packed'} />
                          <InfoField label="Returned" value={item.returnedAt ? formatDateTime(item.returnedAt) : 'Not returned'} />
                        </div>
                        {item.notes && <p className="text-muted-foreground">{item.notes}</p>}
                        {item.photoUrls.length > 0 && (
                          <div className="flex items-center gap-1 text-muted-foreground">
                            <Camera size={12} />
                            {item.photoUrls.length} photo{item.photoUrls.length !== 1 ? 's' : ''}
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                );
              })}
            </CardContent>
          </Card>
        ))
      )}

      {/* Value Summary */}
      {items.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Value Summary</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-3 gap-4 text-center">
              <div>
                <p className="text-lg font-bold">{formatCurrency(stats.totalEstimatedValue)}</p>
                <p className="text-xs text-muted-foreground">Estimated Value</p>
              </div>
              <div>
                <p className="text-lg font-bold">{formatCurrency(stats.totalReplacementCost)}</p>
                <p className="text-xs text-muted-foreground">Replacement Cost</p>
              </div>
              <div>
                <p className="text-lg font-bold">
                  {items.filter((i) => i.condition === 'non_salvageable').length}
                </p>
                <p className="text-xs text-muted-foreground">Non-Salvageable</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// =============================================================================
// DEODORIZATION TAB
// =============================================================================

function DeodorizationTab({
  assessment,
  onUpdate,
}: {
  assessment: FireAssessment;
  onUpdate: (id: string, updates: Partial<Record<string, unknown>>) => Promise<void>;
}) {
  const treatments = assessment.odorTreatments;

  // Treatment recommendation based on damage
  const recommendations = useMemo(() => {
    const recs: { method: string; reason: string }[] = [];
    const hasProteinSoot = assessment.sootAssessments.some((s) => s.soot_type === 'protein');
    const hasHeavyDamage = assessment.damageZones.some((z) => z.severity === 'heavy');
    const hasFuelOil = assessment.sootAssessments.some((s) => s.soot_type === 'fuel_oil');
    const hasWetSmoke = assessment.sootAssessments.some((s) => s.soot_type === 'wet_smoke');

    if (hasProteinSoot) {
      recs.push({ method: 'Thermal Fogging', reason: 'Protein soot detected — thermal fogging penetrates porous surfaces to neutralize odor molecules' });
      recs.push({ method: 'Hydroxyl Generator', reason: 'Safe for occupied spaces — treats protein residue without evacuating contents' });
    }
    if (hasHeavyDamage) {
      recs.push({ method: 'Ozone Treatment', reason: 'Heavy damage requires aggressive odor treatment — ozone oxidizes odor at molecular level' });
      recs.push({ method: 'HEPA Air Scrubbing', reason: 'Heavy smoke residue — HEPA filtration removes airborne particulate during restoration' });
    }
    if (hasFuelOil) {
      recs.push({ method: 'Ozone + Thermal Fog Combo', reason: 'Fuel oil soot requires dual treatment — ozone for embedded odor, thermal fog for surface' });
    }
    if (hasWetSmoke) {
      recs.push({ method: 'Sealant/Encapsulant', reason: 'Wet smoke leaves sticky residue — seal affected surfaces after cleaning to lock in remaining odor' });
    }
    if (recs.length === 0) {
      recs.push({ method: 'HEPA Air Scrubbing', reason: 'Standard recommendation for all fire restoration projects' });
      recs.push({ method: 'Thermal Fogging', reason: 'Effective for light-to-moderate smoke odor penetration' });
    }
    return recs;
  }, [assessment.sootAssessments, assessment.damageZones]);

  return (
    <div className="space-y-4">
      {/* Treatment Recommendations */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm flex items-center gap-2">
            <ClipboardList size={14} />
            Recommended Treatment Plan
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {recommendations.map((rec, i) => (
            <div key={i} className="rounded-lg bg-blue-500/5 border border-blue-500/20 p-3">
              <p className="text-sm font-medium text-blue-400">{rec.method}</p>
              <p className="text-xs text-muted-foreground mt-1">{rec.reason}</p>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Active/Completed Treatments */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">
            Treatments ({treatments.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {treatments.length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-6">
              No odor treatments documented yet
            </p>
          ) : (
            <div className="space-y-3">
              {treatments.map((t, i) => (
                <div key={i} className="rounded-lg bg-accent/50 p-4 space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Thermometer size={14} className="text-orange-400" />
                      <span className="text-sm font-medium">
                        {ODOR_METHODS.find((m) => m.value === t.method)?.label || t.method.replace(/_/g, ' ')}
                      </span>
                    </div>
                    <Badge variant={t.end_time ? 'success' : 'info'}>
                      {t.end_time ? 'Complete' : 'Active'}
                    </Badge>
                  </div>
                  <p className="text-xs text-muted-foreground">Room: {t.room}</p>
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    {t.start_time && <InfoField label="Started" value={formatDateTime(t.start_time)} />}
                    {t.end_time && <InfoField label="Completed" value={formatDateTime(t.end_time)} />}
                    {t.pre_reading != null && <InfoField label="Pre-Reading" value={`${t.pre_reading} ppb`} />}
                    {t.post_reading != null && <InfoField label="Post-Reading" value={`${t.post_reading} ppb`} />}
                  </div>
                  {t.pre_reading != null && t.post_reading != null && (
                    <div className="rounded-lg bg-accent/50 p-2">
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-muted-foreground">Odor Reduction</span>
                        <span className={cn(
                          'font-bold',
                          t.post_reading < t.pre_reading ? 'text-green-500' : 'text-red-500'
                        )}>
                          {t.pre_reading > 0
                            ? `${Math.round(((t.pre_reading - t.post_reading) / t.pre_reading) * 100)}%`
                            : '—'}
                        </span>
                      </div>
                    </div>
                  )}
                  {t.notes && <p className="text-xs text-muted-foreground">{t.notes}</p>}
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Soot-Specific Cleaning Guide */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">Soot Type Quick Reference</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {SOOT_TYPES.map((type) => {
            const info = SOOT_TYPE_INFO[type];
            const isPresent = assessment.sootAssessments.some((s) => s.soot_type === type) ||
              assessment.damageZones.some((z) => z.soot_type === type);
            return (
              <div
                key={type}
                className={cn(
                  'rounded-lg p-3 border text-xs',
                  isPresent ? 'border-orange-500/30 bg-orange-500/5' : 'border-main bg-accent/20 opacity-60'
                )}
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="font-medium">{info.label}</span>
                  {isPresent && <Badge variant="warning">Present</Badge>}
                </div>
                <p className="text-muted-foreground">{info.description}</p>
                <p className="text-muted-foreground mt-1">
                  <span className="font-medium">Cleaning:</span> {info.cleaningMethod}
                </p>
              </div>
            );
          })}
        </CardContent>
      </Card>
    </div>
  );
}

// =============================================================================
// STRUCTURAL TAB
// =============================================================================

function StructuralTab({
  assessment,
  onUpdate,
}: {
  assessment: FireAssessment;
  onUpdate: (id: string, updates: Partial<Record<string, unknown>>) => Promise<void>;
}) {
  const structuralFlags = [
    { key: 'structuralCompromise', label: 'Structural Compromise', value: assessment.structuralCompromise, description: 'Overall structural integrity has been compromised by fire damage' },
    { key: 'roofDamage', label: 'Roof Damage', value: assessment.roofDamage, description: 'Roof structure, decking, or rafters show fire or heat damage' },
    { key: 'foundationDamage', label: 'Foundation Damage', value: assessment.foundationDamage, description: 'Foundation shows cracking, spalling, or heat damage' },
    { key: 'loadBearingAffected', label: 'Load-Bearing Affected', value: assessment.loadBearingAffected, description: 'Load-bearing walls, headers, or beams show char or damage' },
    { key: 'waterDamageFromSuppression', label: 'Water Suppression Damage', value: assessment.waterDamageFromSuppression, description: 'Water damage from fire suppression (sprinklers, fire hoses)' },
  ];

  const hasStructuralIssues = structuralFlags.some((f) => f.value);

  // Char depth reference guide
  const charDepthGuide = [
    { depth: '1/8" or less', rating: 'Surface char', action: 'Clean and seal — structural integrity intact', color: 'text-green-500' },
    { depth: '1/4"', rating: 'Light char', action: 'Evaluate — may need sister or reinforce', color: 'text-yellow-500' },
    { depth: '1/2"', rating: 'Moderate char', action: 'Sistering required — reduce load capacity in calculations', color: 'text-orange-500' },
    { depth: '3/4"+', rating: 'Deep char', action: 'Replace member — structural capacity severely compromised', color: 'text-red-500' },
  ];

  // Fire wall ratings reference
  const fireRatings = [
    { rating: '1-Hour', assembly: '5/8" Type X gypsum board both sides', use: 'Interior bearing walls, corridors' },
    { rating: '2-Hour', assembly: '2 layers 5/8" Type X each side', use: 'Separation walls, stairwell enclosures' },
    { rating: '3-Hour', assembly: '3 layers 5/8" Type X each side', use: 'Area separation walls, fire walls' },
  ];

  return (
    <div className="space-y-4">
      {/* Structural Flags */}
      <Card className={hasStructuralIssues ? 'border-red-500/30' : ''}>
        <CardHeader>
          <CardTitle className="text-sm flex items-center gap-2">
            <AlertTriangle size={14} className={hasStructuralIssues ? 'text-red-500' : 'text-muted-foreground'} />
            Structural Assessment
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {structuralFlags.map((flag) => (
            <div key={flag.key} className={cn(
              'flex items-start gap-3 rounded-lg p-3',
              flag.value ? 'bg-red-500/5 border border-red-500/20' : 'bg-accent/30'
            )}>
              {flag.value ? (
                <AlertTriangle size={16} className="text-red-500 mt-0.5 flex-shrink-0" />
              ) : (
                <CheckCircle size={16} className="text-green-500 mt-0.5 flex-shrink-0" />
              )}
              <div>
                <p className="text-sm font-medium">{flag.label}</p>
                <p className="text-xs text-muted-foreground">{flag.description}</p>
              </div>
              <Badge variant={flag.value ? 'error' : 'success'} className="ml-auto flex-shrink-0">
                {flag.value ? 'YES' : 'Clear'}
              </Badge>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Structural Notes */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">Structural Notes</CardTitle>
        </CardHeader>
        <CardContent>
          {assessment.structuralNotes ? (
            <p className="text-sm whitespace-pre-wrap">{assessment.structuralNotes}</p>
          ) : (
            <p className="text-sm text-muted-foreground text-center py-4">No structural notes documented</p>
          )}
        </CardContent>
      </Card>

      {/* Char Depth Reference */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">Char Depth Assessment Guide</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {charDepthGuide.map((item, i) => (
              <div key={i} className="flex items-start gap-3 rounded-lg bg-accent/30 p-3">
                <div className={cn('text-sm font-bold w-16 flex-shrink-0', item.color)}>
                  {item.depth}
                </div>
                <div>
                  <p className="text-sm font-medium">{item.rating}</p>
                  <p className="text-xs text-muted-foreground">{item.action}</p>
                </div>
              </div>
            ))}
          </div>
          <p className="text-xs text-muted-foreground mt-3">
            Measure char depth with a probe or awl. Remove loose char to find sound wood. Record depth at multiple points along each structural member.
          </p>
        </CardContent>
      </Card>

      {/* Fire Wall Ratings Reference */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">Fire Wall Rating Reference</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {fireRatings.map((item, i) => (
              <div key={i} className="rounded-lg bg-accent/30 p-3 text-xs">
                <div className="flex items-center justify-between mb-1">
                  <span className="font-bold text-sm">{item.rating}</span>
                </div>
                <p className="text-muted-foreground">Assembly: {item.assembly}</p>
                <p className="text-muted-foreground">Use: {item.use}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Demolition Scope */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">Demolition Scope Summary</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 gap-3">
            <div className="rounded-lg bg-accent/30 p-3 text-center">
              <p className="text-lg font-bold">
                {assessment.damageZones.filter((z) => z.severity === 'heavy').length}
              </p>
              <p className="text-xs text-muted-foreground">Heavy Damage Zones</p>
            </div>
            <div className="rounded-lg bg-accent/30 p-3 text-center">
              <p className="text-lg font-bold">
                {assessment.damageZones.filter((z) => z.zone_type === 'direct_flame').length}
              </p>
              <p className="text-xs text-muted-foreground">Direct Flame Zones</p>
            </div>
          </div>
          <div className="mt-3 rounded-lg bg-yellow-500/5 border border-yellow-500/20 p-3">
            <p className="text-xs text-yellow-500">
              {hasStructuralIssues
                ? 'Structural engineer review recommended before demolition begins. Document all damaged structural members with measurements and photos.'
                : 'No structural concerns flagged. Standard demolition procedures apply. Document scope with photos before beginning.'}
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// =============================================================================
// PHOTOS TAB
// =============================================================================

function PhotosTab({ assessment }: { assessment: FireAssessment }) {
  const { items } = useContentPackout(assessment.id);

  // Photo counts from various sources
  const zonePhotos = assessment.damageZones.reduce((sum, z) => sum + z.photos.length, 0);
  const assessmentPhotos = assessment.photos.length;
  const contentPhotos = items.reduce((sum, i) => sum + i.photoUrls.length, 0);
  const boardUpPhotos = assessment.boardUpEntries.reduce((sum, b) =>
    sum + (b.photo_before ? 1 : 0) + (b.photo_after ? 1 : 0), 0);
  const totalPhotos = zonePhotos + assessmentPhotos + contentPhotos + boardUpPhotos;

  // Required photo checklist for insurance
  const photoChecklist = [
    { category: 'Exterior', items: ['Front of structure', 'All four sides', 'Roof (if accessible)', 'Address/signage'] },
    { category: 'Point of Origin', items: ['Fire origin room - wide shot', 'Fire origin - close-up', 'Burn pattern on walls', 'Burn pattern on ceiling', 'V-pattern documentation'] },
    { category: 'Damage Zones', items: ['Each affected room - wide shot', 'Soot damage - close-ups', 'Char damage - with ruler', 'Content damage per room'] },
    { category: 'Board-Up', items: ['Before boarding - each opening', 'After boarding - each opening', 'Materials used'] },
    { category: 'Structural', items: ['Damaged structural members', 'Char depth measurements', 'Roof structure (if accessible)', 'Foundation (if damaged)'] },
    { category: 'Contents', items: ['Each room contents overview', 'High-value items individual', 'Packed boxes labeled', 'Storage facility'] },
  ];

  return (
    <div className="space-y-4">
      {/* Photo Stats */}
      <div className="grid grid-cols-4 gap-3">
        <Card>
          <CardContent className="pt-4 pb-3 text-center">
            <p className="text-xl font-bold">{totalPhotos}</p>
            <p className="text-xs text-muted-foreground">Total Photos</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3 text-center">
            <p className="text-xl font-bold">{zonePhotos}</p>
            <p className="text-xs text-muted-foreground">Zone Photos</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3 text-center">
            <p className="text-xl font-bold">{contentPhotos}</p>
            <p className="text-xs text-muted-foreground">Content Photos</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3 text-center">
            <p className="text-xl font-bold">{boardUpPhotos}</p>
            <p className="text-xs text-muted-foreground">Board-Up Photos</p>
          </CardContent>
        </Card>
      </div>

      {/* Required Photo Checklist */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm flex items-center gap-2">
            <ClipboardList size={14} />
            Insurance Required Photos Checklist
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {photoChecklist.map((group) => (
            <div key={group.category}>
              <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2">
                {group.category}
              </p>
              <div className="space-y-1">
                {group.items.map((item) => (
                  <div key={item} className="flex items-center gap-2 text-sm py-1">
                    <div className="h-4 w-4 rounded border border-main flex-shrink-0" />
                    <span className="text-muted-foreground">{item}</span>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Photo naming convention */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">Photo Naming Convention</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2 text-xs">
            <div className="rounded-lg bg-accent/50 p-3 font-mono">
              [JobNumber]_[Room]_[Type]_[Sequence].jpg
            </div>
            <p className="text-muted-foreground">Examples:</p>
            <div className="space-y-1 text-muted-foreground font-mono">
              <p>FR-2024-001_Kitchen_Before_001.jpg</p>
              <p>FR-2024-001_Kitchen_SootDamage_002.jpg</p>
              <p>FR-2024-001_MasterBed_CharDepth_001.jpg</p>
              <p>FR-2024-001_Exterior_BoardUp_Before_001.jpg</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Photos by Zone */}
      {assessment.damageZones.some((z) => z.photos.length > 0) && (
        <Card>
          <CardHeader>
            <CardTitle className="text-sm">Zone Photos</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {assessment.damageZones.filter((z) => z.photos.length > 0).map((zone, i) => (
              <div key={i} className="flex items-center justify-between rounded-lg bg-accent/30 p-3">
                <div>
                  <p className="text-sm font-medium">{zone.room}</p>
                  <p className="text-xs text-muted-foreground">{zone.zone_type.replace(/_/g, ' ')} — {zone.severity}</p>
                </div>
                <div className="flex items-center gap-1 text-xs text-muted-foreground">
                  <Camera size={12} />
                  {zone.photos.length} photo{zone.photos.length !== 1 ? 's' : ''}
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// =============================================================================
// SHARED COMPONENTS
// =============================================================================

function InfoField({
  label,
  value,
  children,
}: {
  label: string;
  value?: string;
  children?: React.ReactNode;
}) {
  return (
    <div>
      <p className="text-xs text-muted-foreground">{label}</p>
      {children || <p className="text-sm font-medium">{value || '—'}</p>}
    </div>
  );
}

function MiniStat({
  icon: Icon,
  label,
  value,
}: {
  icon: LucideIcon;
  label: string;
  value: number;
}) {
  return (
    <Card>
      <CardContent className="pt-3 pb-3 flex items-center gap-2">
        <Icon size={14} className="text-muted-foreground flex-shrink-0" />
        <div>
          <p className="text-lg font-bold leading-none">{value}</p>
          <p className="text-[10px] text-muted-foreground mt-0.5">{label}</p>
        </div>
      </CardContent>
    </Card>
  );
}
