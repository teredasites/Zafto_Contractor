'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  Cpu,
  Heart,
  Calendar,
  Package,
  AlertTriangle,
  Clock,
  DollarSign,
  Wrench,
  ChevronRight,
  RefreshCcw,
  ShieldCheck,
  Loader2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import {
  useEquipmentInsights,
} from '@/lib/hooks/use-equipment-insights';
import type {
  MaintenanceItem,
  PartSuggestion,
  ReplacementTimeline,
} from '@/lib/hooks/use-equipment-insights';
import { getSupabase } from '@/lib/supabase';
import { useTranslation } from '@/lib/translations';

function healthColor(score: number): string {
  if (score >= 80) return 'text-emerald-600 dark:text-emerald-400';
  if (score >= 60) return 'text-amber-600 dark:text-amber-400';
  if (score >= 40) return 'text-orange-600 dark:text-orange-400';
  return 'text-red-600 dark:text-red-400';
}

function healthBg(score: number): string {
  if (score >= 80) return 'bg-emerald-100 dark:bg-emerald-900/30';
  if (score >= 60) return 'bg-amber-100 dark:bg-amber-900/30';
  if (score >= 40) return 'bg-orange-100 dark:bg-orange-900/30';
  return 'bg-red-100 dark:bg-red-900/30';
}

function healthLabel(score: number): string {
  if (score >= 80) return 'Excellent';
  if (score >= 60) return 'Good';
  if (score >= 40) return 'Fair';
  return 'Poor';
}

function priorityVariant(priority: string): 'error' | 'warning' | 'info' {
  if (priority === 'high') return 'error';
  if (priority === 'medium') return 'warning';
  return 'info';
}

function urgencyVariant(urgency: string): 'error' | 'warning' | 'info' {
  if (urgency === 'immediate') return 'error';
  if (urgency === 'soon') return 'warning';
  return 'info';
}

function riskVariant(risk: string): 'error' | 'warning' | 'success' {
  if (risk === 'high') return 'error';
  if (risk === 'medium') return 'warning';
  return 'success';
}

export default function EquipmentInsightsPage() {
  const { t } = useTranslation();
  const params = useParams();
  const router = useRouter();
  const propertyId = params.id as string;
  const { insights, loading, error, fetchInsights } = useEquipmentInsights(propertyId);
  const [propertyName, setPropertyName] = useState<string>('');

  // Fetch property name
  useEffect(() => {
    async function loadProperty() {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('properties')
        .select('name, address_line1')
        .eq('id', propertyId)
        .single();
      if (data) {
        setPropertyName(data.name || data.address_line1 || 'Property');
      }
    }
    loadProperty();
  }, [propertyId]);

  // Fetch insights on mount
  useEffect(() => {
    fetchInsights();
  }, [fetchInsights]);

  return (
    <div className="flex-1 flex flex-col min-h-0">
      <CommandPalette />

      {/* Header */}
      <div className="shrink-0 border-b border-main bg-surface">
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="icon" onClick={() => router.back()}>
              <ArrowLeft className="w-4 h-4" />
            </Button>
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-blue-600 flex items-center justify-center">
              <Cpu className="w-4 h-4 text-white" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-lg font-semibold text-main">{t('propertyEquipment.equipmentMemory')}</h1>
                <Badge variant="purple" size="sm">{t('common.poweredByZ')}</Badge>
              </div>
              {propertyName && (
                <p className="text-sm text-muted">{propertyName}</p>
              )}
            </div>
          </div>
          <Button
            variant="outline"
            size="sm"
            onClick={() => fetchInsights()}
            disabled={loading}
          >
            <RefreshCcw className={cn('w-3.5 h-3.5 mr-1.5', loading && 'animate-spin')} />
            Refresh Analysis
          </Button>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {loading && !insights && (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="w-8 h-8 text-muted animate-spin mb-3" />
            <p className="text-sm text-muted">{t('propertyEquipment.analyzingEquipmentData')}</p>
            <p className="text-xs text-muted mt-1">{t('propertyEquipment.thisMayTakeAFewSeconds')}</p>
          </div>
        )}

        {error && (
          <Card className="border-red-200 dark:border-red-800">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-red-600 dark:text-red-400">
                <AlertTriangle className="w-4 h-4" />
                <p className="text-sm font-medium">{t('propertyEquipment.errorLoadingInsights')}</p>
              </div>
              <p className="text-xs text-muted mt-1">{error}</p>
              <Button variant="outline" size="sm" className="mt-3" onClick={() => fetchInsights()}>
                Try Again
              </Button>
            </CardContent>
          </Card>
        )}

        {insights && (
          <>
            {/* Equipment Health Overview */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <Card className="md:col-span-1">
                <CardContent className="p-5 flex flex-col items-center justify-center">
                  <div className={cn('w-16 h-16 rounded-full flex items-center justify-center mb-2', healthBg(insights.equipment_health))}>
                    <span className={cn('text-2xl font-bold', healthColor(insights.equipment_health))}>
                      {insights.equipment_health}
                    </span>
                  </div>
                  <p className={cn('text-sm font-medium', healthColor(insights.equipment_health))}>
                    {healthLabel(insights.equipment_health)}
                  </p>
                  <p className="text-xs text-muted mt-1">{t('propertyEquipment.overallHealthScore')}</p>
                </CardContent>
              </Card>

              <Card>
                <CardContent className="p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <Calendar className="w-4 h-4 text-muted" />
                    <p className="text-xs text-muted">{t('common.nextService')}</p>
                  </div>
                  <p className="text-lg font-semibold text-main">
                    {insights.next_service_date || 'None scheduled'}
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardContent className="p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <Package className="w-4 h-4 text-muted" />
                    <p className="text-xs text-muted">{t('propertyEquipment.equipmentTracked')}</p>
                  </div>
                  <p className="text-lg font-semibold text-main">{insights.equipment_count}</p>
                </CardContent>
              </Card>

              <Card>
                <CardContent className="p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <DollarSign className="w-4 h-4 text-muted" />
                    <p className="text-xs text-muted">{t('propertyEquipment.estAnnualCost')}</p>
                  </div>
                  <p className="text-lg font-semibold text-main">
                    {formatCurrency(insights.estimated_annual_cost)}
                  </p>
                </CardContent>
              </Card>
            </div>

            {/* Summary */}
            {insights.summary && (
              <Card>
                <CardContent className="p-4">
                  <div className="flex items-start gap-2">
                    <ShieldCheck className="w-4 h-4 text-muted mt-0.5 shrink-0" />
                    <p className="text-sm text-muted leading-relaxed">{insights.summary}</p>
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Maintenance Timeline */}
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Wrench className="w-4 h-4 text-muted" />
                    <CardTitle>{t('propertyEquipment.maintenanceTimeline')}</CardTitle>
                  </div>
                  <Badge variant="secondary" size="sm">
                    {insights.maintenance_schedule.length} upcoming
                  </Badge>
                </div>
              </CardHeader>
              <CardContent className="p-0">
                {insights.maintenance_schedule.length === 0 ? (
                  <div className="p-6 text-center text-sm text-muted">
                    No maintenance items identified
                  </div>
                ) : (
                  <div className="divide-y divide-main">
                    {insights.maintenance_schedule.map((item: MaintenanceItem, i: number) => (
                      <div key={i} className="flex items-center justify-between px-6 py-3 hover:bg-surface-hover transition-colors">
                        <div className="flex items-start gap-3">
                          <div className={cn(
                            'w-2 h-2 rounded-full mt-1.5 shrink-0',
                            item.priority === 'high' ? 'bg-red-500' : item.priority === 'medium' ? 'bg-amber-500' : 'bg-blue-500'
                          )} />
                          <div>
                            <p className="text-sm font-medium text-main">{item.task}</p>
                            <p className="text-xs text-muted mt-0.5">{item.notes}</p>
                            <div className="flex items-center gap-3 mt-1">
                              <span className="text-xs text-muted flex items-center gap-1">
                                <Clock className="w-3 h-3" />
                                Every {item.interval_months} months
                              </span>
                              <span className="text-xs text-muted flex items-center gap-1">
                                <Calendar className="w-3 h-3" />
                                Due {item.next_due}
                              </span>
                            </div>
                          </div>
                        </div>
                        <div className="flex items-center gap-3 shrink-0">
                          <Badge variant={priorityVariant(item.priority)} size="sm">
                            {item.priority}
                          </Badge>
                          <span className="text-sm font-medium text-main">
                            {formatCurrency(item.estimated_cost)}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Parts to Stock */}
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Package className="w-4 h-4 text-muted" />
                    <CardTitle>{t('propertyEquipment.partsToStock')}</CardTitle>
                  </div>
                  <Badge variant="secondary" size="sm">
                    {insights.parts_to_stock.length} suggested
                  </Badge>
                </div>
              </CardHeader>
              <CardContent className="p-0">
                {insights.parts_to_stock.length === 0 ? (
                  <div className="p-6 text-center text-sm text-muted">
                    No parts recommendations at this time
                  </div>
                ) : (
                  <div className="divide-y divide-main">
                    {insights.parts_to_stock.map((part: PartSuggestion, i: number) => (
                      <div key={i} className="flex items-center justify-between px-6 py-3 hover:bg-surface-hover transition-colors">
                        <div>
                          <div className="flex items-center gap-2">
                            <p className="text-sm font-medium text-main">{part.name}</p>
                            {part.part_number && (
                              <span className="text-xs text-muted font-mono">{part.part_number}</span>
                            )}
                          </div>
                          <p className="text-xs text-muted mt-0.5">{part.reason}</p>
                        </div>
                        <div className="flex items-center gap-3 shrink-0">
                          <Badge variant={urgencyVariant(part.urgency)} size="sm">
                            {part.urgency}
                          </Badge>
                          <span className="text-sm font-medium text-main">
                            {formatCurrency(part.estimated_cost)}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Replacement Planning */}
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <AlertTriangle className="w-4 h-4 text-muted" />
                    <CardTitle>{t('propertyEquipment.replacementPlanning')}</CardTitle>
                  </div>
                  <Badge variant="secondary" size="sm">
                    {insights.replacement_timeline.length} items
                  </Badge>
                </div>
              </CardHeader>
              <CardContent className="p-0">
                {insights.replacement_timeline.length === 0 ? (
                  <div className="p-6 text-center text-sm text-muted">
                    No equipment nearing end of life
                  </div>
                ) : (
                  <div className="divide-y divide-main">
                    {insights.replacement_timeline.map((item: ReplacementTimeline, i: number) => (
                      <div key={i} className="flex items-center justify-between px-6 py-3 hover:bg-surface-hover transition-colors">
                        <div>
                          <p className="text-sm font-medium text-main">{item.equipment_name}</p>
                          <p className="text-xs text-muted mt-0.5">{item.recommendation}</p>
                          <span className="text-xs text-muted flex items-center gap-1 mt-1">
                            <Calendar className="w-3 h-3" />
                            Expected replacement: {item.expected_replacement_year}
                          </span>
                        </div>
                        <div className="flex items-center gap-3 shrink-0">
                          <Badge variant={riskVariant(item.risk_level)} size="sm">
                            {item.risk_level} risk
                          </Badge>
                          <span className="text-sm font-medium text-main">
                            {formatCurrency(item.estimated_replacement_cost)}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </>
        )}
      </div>
    </div>
  );
}
