'use client';

import { useState } from 'react';
import {
  Wrench,
  Clock,
  AlertTriangle,
  Calendar,
  DollarSign,
  ChevronRight,
  RefreshCw,
  Loader2,
  CheckCircle,
  XCircle,
  Send,
  Zap,
  Thermometer,
  Filter,
  Play,
  BarChart3,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import {
  useMaintenancePredictions,
  type MaintenancePrediction,
  type OutreachStatus,
} from '@/lib/hooks/use-maintenance-predictions';
import { useTranslation } from '@/lib/translations';

type ViewMode = 'pipeline' | 'calendar' | 'revenue';

const predictionTypeConfig: Record<string, { label: string; icon: typeof Wrench; color: string }> = {
  maintenance_due: { label: 'Maintenance Due', icon: Wrench, color: 'text-blue-400' },
  end_of_life: { label: 'End of Life', icon: AlertTriangle, color: 'text-red-400' },
  seasonal_check: { label: 'Seasonal Check', icon: Thermometer, color: 'text-orange-400' },
  filter_replacement: { label: 'Filter Replace', icon: Filter, color: 'text-cyan-400' },
  inspection_recommended: { label: 'Inspection', icon: CheckCircle, color: 'text-green-400' },
};

const outreachStatusConfig: Record<OutreachStatus, { label: string; bg: string; text: string }> = {
  pending: { label: 'Pending', bg: 'bg-zinc-700/50', text: 'text-zinc-400' },
  sent: { label: 'Sent', bg: 'bg-blue-500/20', text: 'text-blue-400' },
  booked: { label: 'Booked', bg: 'bg-green-500/20', text: 'text-green-400' },
  declined: { label: 'Declined', bg: 'bg-red-500/20', text: 'text-red-400' },
  completed: { label: 'Completed', bg: 'bg-emerald-500/20', text: 'text-emerald-400' },
};

export default function MaintenancePipelinePage() {
  const { t } = useTranslation();
  const {
    predictions,
    upcomingPredictions,
    loading,
    error,
    stats,
    updateOutreachStatus,
    triggerEngine,
    refresh,
  } = useMaintenancePredictions();

  const [viewMode, setViewMode] = useState<ViewMode>('pipeline');
  const [runningEngine, setRunningEngine] = useState(false);
  const [engineResult, setEngineResult] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const handleRunEngine = async () => {
    setRunningEngine(true);
    setEngineResult(null);
    try {
      const result = await triggerEngine();
      setEngineResult(`Generated ${result.predictionsGenerated} predictions from ${result.equipmentScanned} equipment`);
    } catch (err) {
      setEngineResult(`Error: ${err instanceof Error ? err.message : 'Unknown error'}`);
    } finally {
      setRunningEngine(false);
    }
  };

  const filteredPredictions = statusFilter === 'all'
    ? upcomingPredictions
    : upcomingPredictions.filter(p => p.outreachStatus === statusFilter);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="w-8 h-8 animate-spin text-zinc-400" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-96 gap-4">
        <AlertTriangle className="w-12 h-12 text-red-400" />
        <p className="text-zinc-400">{error}</p>
        <Button onClick={refresh} variant="outline" size="sm">
          <RefreshCw className="w-4 h-4 mr-2" /> Retry
        </Button>
      </div>
    );
  }

  return (
    <>
      <CommandPalette />
      <div className="space-y-6 p-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-zinc-100">{t('maintenancePipeline.title')}</h1>
            <p className="text-sm text-zinc-400 mt-1">
              Predictive maintenance opportunities and revenue forecast
            </p>
          </div>
          <div className="flex gap-2">
            <Button onClick={handleRunEngine} variant="outline" size="sm" disabled={runningEngine}>
              {runningEngine ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <Play className="w-4 h-4 mr-2" />}
              Run Engine
            </Button>
            <Button onClick={refresh} variant="outline" size="sm">
              <RefreshCw className="w-4 h-4 mr-2" /> Refresh
            </Button>
          </div>
        </div>

        {/* Engine Result Toast */}
        {engineResult && (
          <div className="p-3 rounded-lg bg-zinc-800 border border-zinc-700 text-sm text-zinc-300 flex items-center justify-between">
            <span>{engineResult}</span>
            <button onClick={() => setEngineResult(null)} className="text-zinc-500 hover:text-zinc-300">
              <XCircle className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* Stats Row */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
          <StatCard icon={BarChart3} label="Total Predictions" value={stats.total} color="blue" />
          <StatCard icon={Clock} label="Upcoming (30d)" value={stats.upcoming} color="yellow" />
          <StatCard icon={AlertTriangle} label="Overdue" value={stats.overdue} color="red" />
          <StatCard icon={CheckCircle} label="Booked" value={stats.booked} color="green" />
          <StatCard icon={DollarSign} label="Pipeline Value" value={formatCurrency(stats.totalEstimatedRevenue)} color="green" />
        </div>

        {/* View Mode Tabs */}
        <div className="flex gap-1 border-b border-zinc-800 pb-px">
          {([
            { key: 'pipeline' as const, label: 'Pipeline', icon: Wrench },
            { key: 'calendar' as const, label: 'Timeline', icon: Calendar },
            { key: 'revenue' as const, label: 'Revenue Forecast', icon: DollarSign },
          ]).map(tab => (
            <button
              key={tab.key}
              onClick={() => setViewMode(tab.key)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 text-sm font-medium rounded-t-lg transition-colors',
                viewMode === tab.key
                  ? 'bg-zinc-800 text-zinc-100 border-b-2 border-blue-500'
                  : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/50'
              )}
            >
              <tab.icon className="w-4 h-4" />
              {tab.label}
            </button>
          ))}
        </div>

        {/* Pipeline View */}
        {viewMode === 'pipeline' && (
          <div className="space-y-4">
            {/* Status Filter */}
            <div className="flex gap-2">
              {['all', 'pending', 'sent', 'booked', 'declined', 'completed'].map(s => (
                <button
                  key={s}
                  onClick={() => setStatusFilter(s)}
                  className={cn(
                    'px-3 py-1.5 text-xs rounded-full transition-colors',
                    statusFilter === s
                      ? 'bg-blue-500/20 text-blue-400'
                      : 'bg-zinc-800 text-zinc-400 hover:text-zinc-200'
                  )}
                >
                  {s === 'all' ? 'All' : s.charAt(0).toUpperCase() + s.slice(1)}
                </button>
              ))}
            </div>

            {filteredPredictions.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-16">
                <Wrench className="w-12 h-12 text-zinc-600 mb-3" />
                <p className="text-zinc-400">No predictions match filter</p>
                <p className="text-xs text-zinc-500 mt-1">Run the engine to generate predictions from your equipment data</p>
              </div>
            ) : (
              <div className="space-y-2">
                {filteredPredictions.map(prediction => (
                  <PredictionCard
                    key={prediction.id}
                    prediction={prediction}
                    onUpdateStatus={updateOutreachStatus}
                  />
                ))}
              </div>
            )}
          </div>
        )}

        {/* Timeline View */}
        {viewMode === 'calendar' && (
          <TimelineView predictions={upcomingPredictions} />
        )}

        {/* Revenue Forecast */}
        {viewMode === 'revenue' && (
          <RevenueView predictions={predictions} stats={stats} />
        )}
      </div>
    </>
  );
}

// ── Prediction Card ─────────────────────────────────────

function PredictionCard({
  prediction,
  onUpdateStatus,
}: {
  prediction: MaintenancePrediction;
  onUpdateStatus: (id: string, status: OutreachStatus) => Promise<void>;
}) {
  const typeConfig = predictionTypeConfig[prediction.predictionType] || predictionTypeConfig.maintenance_due;
  const statusConfig = outreachStatusConfig[prediction.outreachStatus];
  const TypeIcon = typeConfig.icon;

  return (
    <Card className={cn(prediction.isOverdue && 'border-red-500/30')}>
      <CardContent className="p-4">
        <div className="flex items-start gap-3">
          <div className={cn('p-2 rounded-lg bg-zinc-800', typeConfig.color)}>
            <TypeIcon className="w-5 h-5" />
          </div>

          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <p className="text-sm font-medium text-zinc-200 truncate">{prediction.recommendedAction}</p>
            </div>
            <div className="flex items-center gap-3 text-xs text-zinc-400">
              <span>{prediction.equipmentName || 'Equipment'}</span>
              {prediction.equipmentManufacturer && (
                <>
                  <span className="text-zinc-600">|</span>
                  <span>{prediction.equipmentManufacturer}</span>
                </>
              )}
              {prediction.customerName && (
                <>
                  <span className="text-zinc-600">|</span>
                  <span>{prediction.customerName}</span>
                </>
              )}
            </div>
            <div className="flex items-center gap-3 mt-2 text-xs">
              <span className={cn(
                'font-medium',
                prediction.isOverdue ? 'text-red-400' :
                prediction.daysUntil <= 7 ? 'text-yellow-400' : 'text-zinc-400'
              )}>
                {prediction.isOverdue
                  ? `${Math.abs(prediction.daysUntil)}d overdue`
                  : prediction.daysUntil === 0
                    ? 'Today'
                    : `In ${prediction.daysUntil}d`}
              </span>
              <span className="text-zinc-600">|</span>
              <span className="text-zinc-500">
                Confidence: {Math.round(prediction.confidenceScore * 100)}%
              </span>
              {prediction.estimatedCost != null && (
                <>
                  <span className="text-zinc-600">|</span>
                  <span className="text-green-400">{formatCurrency(prediction.estimatedCost)}</span>
                </>
              )}
            </div>
          </div>

          <div className="flex items-center gap-2">
            <Badge className={cn(statusConfig.bg, statusConfig.text, 'text-[10px]')}>
              {statusConfig.label}
            </Badge>
            {prediction.outreachStatus === 'pending' && (
              <div className="flex gap-1">
                <Button
                  variant="outline"
                  size="sm"
                  className="text-xs h-7 px-2"
                  onClick={() => onUpdateStatus(prediction.id, 'sent')}
                >
                  <Send className="w-3 h-3 mr-1" /> Send
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  className="text-xs h-7 px-2 text-green-400"
                  onClick={() => onUpdateStatus(prediction.id, 'booked')}
                >
                  Book
                </Button>
              </div>
            )}
            {prediction.outreachStatus === 'sent' && (
              <div className="flex gap-1">
                <Button
                  variant="outline"
                  size="sm"
                  className="text-xs h-7 px-2 text-green-400"
                  onClick={() => onUpdateStatus(prediction.id, 'booked')}
                >
                  Booked
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  className="text-xs h-7 px-2 text-red-400"
                  onClick={() => onUpdateStatus(prediction.id, 'declined')}
                >
                  Declined
                </Button>
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

// ── Timeline View ───────────────────────────────────────

function TimelineView({ predictions }: { predictions: MaintenancePrediction[] }) {
  // Group by month
  const byMonth = predictions.reduce((acc, p) => {
    const month = p.predictedDate.slice(0, 7); // YYYY-MM
    if (!acc[month]) acc[month] = [];
    acc[month].push(p);
    return acc;
  }, {} as Record<string, MaintenancePrediction[]>);

  const months = Object.keys(byMonth).sort();

  if (months.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16">
        <Calendar className="w-12 h-12 text-zinc-600 mb-3" />
        <p className="text-zinc-400">No upcoming predictions</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {months.map(month => {
        const items = byMonth[month];
        const label = new Date(month + '-01').toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
        return (
          <div key={month}>
            <h3 className="text-sm font-medium text-zinc-300 mb-3 flex items-center gap-2">
              <Calendar className="w-4 h-4 text-zinc-500" />
              {label} ({items.length})
            </h3>
            <div className="space-y-1.5 pl-6 border-l border-zinc-800">
              {items.map(p => {
                const tc = predictionTypeConfig[p.predictionType] || predictionTypeConfig.maintenance_due;
                return (
                  <div key={p.id} className="flex items-center gap-3 p-2 rounded-lg hover:bg-zinc-800/50 transition-colors">
                    <span className="text-xs text-zinc-500 w-16 shrink-0">{formatDate(p.predictedDate)}</span>
                    <span className={cn('w-2 h-2 rounded-full shrink-0', tc.color.replace('text-', 'bg-'))} />
                    <span className="text-sm text-zinc-300 truncate flex-1">{p.recommendedAction}</span>
                    <span className="text-xs text-zinc-500 shrink-0">{p.customerName}</span>
                  </div>
                );
              })}
            </div>
          </div>
        );
      })}
    </div>
  );
}

// ── Revenue Forecast ────────────────────────────────────

function RevenueView({ predictions, stats }: { predictions: MaintenancePrediction[]; stats: ReturnType<typeof useMaintenancePredictions>['stats'] }) {
  // Revenue by month
  const byMonth = predictions
    .filter(p => p.outreachStatus !== 'completed' && p.outreachStatus !== 'declined')
    .reduce((acc, p) => {
      const month = p.predictedDate.slice(0, 7);
      if (!acc[month]) acc[month] = { count: 0, revenue: 0 };
      acc[month].count++;
      acc[month].revenue += p.estimatedCost || 0;
      return acc;
    }, {} as Record<string, { count: number; revenue: number }>);

  const months = Object.keys(byMonth).sort().slice(0, 6);

  // Revenue by type
  const byType = predictions
    .filter(p => p.outreachStatus !== 'completed' && p.outreachStatus !== 'declined')
    .reduce((acc, p) => {
      const type = p.predictionType;
      if (!acc[type]) acc[type] = { count: 0, revenue: 0 };
      acc[type].count++;
      acc[type].revenue += p.estimatedCost || 0;
      return acc;
    }, {} as Record<string, { count: number; revenue: number }>);

  return (
    <div className="space-y-6">
      {/* Summary */}
      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-6 text-center">
            <p className="text-3xl font-bold text-green-400">{formatCurrency(stats.totalEstimatedRevenue)}</p>
            <p className="text-sm text-zinc-400 mt-1">Pipeline Value</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 text-center">
            <p className="text-3xl font-bold text-blue-400">{stats.total - stats.booked}</p>
            <p className="text-sm text-zinc-400 mt-1">Open Opportunities</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 text-center">
            <p className="text-3xl font-bold text-emerald-400">
              {stats.total > 0 ? Math.round((stats.booked / stats.total) * 100) : 0}%
            </p>
            <p className="text-sm text-zinc-400 mt-1">Booking Rate</p>
          </CardContent>
        </Card>
      </div>

      {/* Monthly Forecast */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-medium text-zinc-300">Monthly Forecast</CardTitle>
        </CardHeader>
        <CardContent>
          {months.length === 0 ? (
            <p className="text-sm text-zinc-500 text-center py-6">No forecast data available</p>
          ) : (
            <div className="space-y-3">
              {months.map(month => {
                const data = byMonth[month];
                const label = new Date(month + '-01').toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
                const maxRevenue = Math.max(...months.map(m => byMonth[m].revenue), 1);
                const barWidth = data.revenue > 0 ? Math.max((data.revenue / maxRevenue) * 100, 5) : 5;

                return (
                  <div key={month} className="flex items-center gap-3">
                    <span className="text-xs text-zinc-400 w-16 shrink-0">{label}</span>
                    <div className="flex-1 bg-zinc-800 rounded-full h-6 overflow-hidden">
                      <div
                        className="h-full bg-gradient-to-r from-green-500/30 to-green-500/60 rounded-full flex items-center px-2"
                        style={{ width: `${barWidth}%` }}
                      >
                        <span className="text-[10px] text-green-400 font-medium whitespace-nowrap">
                          {formatCurrency(data.revenue)}
                        </span>
                      </div>
                    </div>
                    <span className="text-xs text-zinc-500 w-12 text-right">{data.count} jobs</span>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* By Type */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-medium text-zinc-300">By Prediction Type</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            {Object.entries(byType).map(([type, data]) => {
              const config = predictionTypeConfig[type] || predictionTypeConfig.maintenance_due;
              const TypeIcon = config.icon;
              return (
                <div key={type} className="p-3 bg-zinc-800/50 rounded-lg">
                  <div className="flex items-center gap-2 mb-2">
                    <TypeIcon className={cn('w-4 h-4', config.color)} />
                    <span className="text-xs text-zinc-400">{config.label}</span>
                  </div>
                  <p className="text-lg font-bold text-zinc-200">{data.count}</p>
                  <p className="text-xs text-green-400">{formatCurrency(data.revenue)}</p>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ── Stat Card ───────────────────────────────────────────

function StatCard({ icon: Icon, label, value, color }: {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  value: string | number;
  color: string;
}) {
  const iconColors: Record<string, string> = {
    blue: 'text-blue-400', green: 'text-green-400', yellow: 'text-yellow-400', red: 'text-red-400',
  };
  const bgColors: Record<string, string> = {
    blue: 'bg-blue-500/10', green: 'bg-green-500/10', yellow: 'bg-yellow-500/10', red: 'bg-red-500/10',
  };
  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center gap-3">
          <div className={cn('p-2 rounded-lg', bgColors[color] || bgColors.blue)}>
            <Icon className={cn('w-5 h-5', iconColors[color] || iconColors.blue)} />
          </div>
          <div>
            <p className="text-xl font-bold text-zinc-100">{value}</p>
            <p className="text-xs text-zinc-400">{label}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
