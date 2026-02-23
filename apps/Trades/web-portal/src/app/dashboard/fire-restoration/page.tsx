'use client';

import { useState } from 'react';
import { useTranslation } from '@/lib/translations';
import {
  Flame,
  Plus,
  Search,
  ChevronRight,
  Building,
  AlertTriangle,
  PackageOpen,
  Wind,
  Shield,
  Trash2,
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
} from '@/lib/hooks/use-fire-restoration';

// =============================================================================
// CONFIG
// =============================================================================

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

// =============================================================================
// PAGE
// =============================================================================

export default function FireRestorationPage() {
  const { t } = useTranslation();
  const { assessments, loading, error, createAssessment, deleteAssessment } = useFireRestoration();
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
              Fire damage assessments, soot classification, content pack-out, odor treatment
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
                Fire assessments are created from job details in the mobile app
              </p>
            </CardContent>
          </Card>
        ) : (
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
            {/* Assessment List */}
            <div className="space-y-3">
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
                          {a.damageZones.length > 0 && (
                            <span className="text-xs text-muted-foreground">
                              {a.damageZones.length} zone{a.damageZones.length !== 1 ? 's' : ''}
                            </span>
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
              <AssessmentDetail assessment={selected} />
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
// DETAIL PANEL
// =============================================================================

function AssessmentDetail({ assessment }: { assessment: FireAssessment }) {
  const { t: tr } = useTranslation();
  const { items, stats } = useContentPackout(assessment.id);

  return (
    <div className="space-y-4">
      {/* Overview */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{tr('fireRestoration.assessmentOverview')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3 text-sm">
          <div className="grid grid-cols-2 gap-2">
            <div>
              <p className="text-xs text-muted-foreground">{tr('fireRestoration.origin')}</p>
              <p className="font-medium">{assessment.originRoom || 'Not specified'}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">{tr('common.severity')}</p>
              <Badge variant={severityConfig[assessment.damageSeverity]?.variant || 'default'}>
                {severityConfig[assessment.damageSeverity]?.label}
              </Badge>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">{tr('fireRestoration.fdReport')}</p>
              <p className="font-medium">{assessment.fireDepartmentReportNumber || '—'}</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">{tr('common.status')}</p>
              <Badge variant={statusConfig[assessment.assessmentStatus]?.variant || 'default'}>
                {statusConfig[assessment.assessmentStatus]?.label}
              </Badge>
            </div>
          </div>

          {/* Structural flags */}
          {(assessment.structuralCompromise || assessment.roofDamage ||
            assessment.foundationDamage || assessment.loadBearingAffected) && (
            <div className="rounded-lg border border-red-500/30 bg-red-500/5 p-3">
              <div className="flex items-center gap-2 text-xs font-medium text-red-500">
                <AlertTriangle className="h-3.5 w-3.5" />
                Structural Concerns
              </div>
              <div className="mt-1 flex flex-wrap gap-1">
                {assessment.structuralCompromise && <Badge variant="error">{tr('common.structural')}</Badge>}
                {assessment.roofDamage && <Badge variant="error">{tr('fireRestoration.roof')}</Badge>}
                {assessment.foundationDamage && <Badge variant="error">{tr('fireRestoration.foundation')}</Badge>}
                {assessment.loadBearingAffected && <Badge variant="error">{tr('fireRestoration.loadbearing')}</Badge>}
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Damage Zones */}
      {assessment.damageZones.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              Damage Zones ({assessment.damageZones.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {assessment.damageZones.map((zone, i) => (
              <div key={i} className="flex items-center justify-between rounded-lg bg-accent/50 p-3">
                <div>
                  <p className="text-sm font-medium">{zone.room}</p>
                  <p className="text-xs text-muted-foreground">
                    {zone.zone_type.replace('_', ' ')} — {zone.severity}
                  </p>
                </div>
                {zone.soot_type && (
                  <Badge variant="secondary">
                    {SOOT_TYPE_INFO[zone.soot_type]?.label || zone.soot_type}
                  </Badge>
                )}
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Odor Treatments */}
      {assessment.odorTreatments.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              Odor Treatments ({assessment.odorTreatments.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {assessment.odorTreatments.map((t, i) => (
              <div key={i} className="flex items-center justify-between rounded-lg bg-accent/50 p-3">
                <div>
                  <p className="text-sm font-medium">{t.method.replace('_', ' ')}</p>
                  <p className="text-xs text-muted-foreground">{t.room}</p>
                </div>
                <Badge variant={t.end_time ? 'success' : 'info'}>
                  {t.end_time ? 'Complete' : 'Active'}
                </Badge>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Board-Up */}
      {assessment.boardUpEntries.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              Board-Up ({assessment.boardUpEntries.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {assessment.boardUpEntries.map((b, i) => (
              <div key={i} className="flex items-center justify-between rounded-lg bg-accent/50 p-3">
                <div>
                  <p className="text-sm font-medium">
                    {b.opening_type.charAt(0).toUpperCase() + b.opening_type.slice(1)} — {b.location}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {b.material || 'No material specified'}
                    {b.dimensions ? ` | ${b.dimensions}` : ''}
                  </p>
                </div>
                <Shield className="h-4 w-4 text-green-500" />
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Content Pack-out Stats */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <PackageOpen className="h-4 w-4" />
            Content Pack-out
          </CardTitle>
        </CardHeader>
        <CardContent>
          {items.length === 0 ? (
            <p className="text-sm text-muted-foreground">{tr('fireRestoration.noContentItemsDocumented')}</p>
          ) : (
            <div className="grid grid-cols-3 gap-4 text-center">
              <div>
                <p className="text-lg font-bold">{stats.totalItems}</p>
                <p className="text-xs text-muted-foreground">{tr('common.items')}</p>
              </div>
              <div>
                <p className="text-lg font-bold">{stats.packed}</p>
                <p className="text-xs text-muted-foreground">{tr('fireRestoration.packed')}</p>
              </div>
              <div>
                <p className="text-lg font-bold">
                  ${stats.totalEstimatedValue.toLocaleString()}
                </p>
                <p className="text-xs text-muted-foreground">{tr('common.estValue')}</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
