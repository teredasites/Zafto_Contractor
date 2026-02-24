'use client';

import { useState, useMemo } from 'react';
import {
  Plus,
  Wind,
  Activity,
  Thermometer,
  Droplets,
  ChevronDown,
  ChevronRight,
  Image,
  Lock,
  X,
  AlertTriangle,
  CheckCircle2,
  TrendingDown,
  TrendingUp,
  Gauge,
  FileText,
  Clock,
  BarChart3,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDateTime, formatDate, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { useRestorationTools } from '@/lib/hooks/use-restoration-tools';
import { calculateGpp, calculateDewPoint } from '@/lib/hooks/use-water-damage';
import type { DryingLogWithJob, MoistureReadingWithJob } from '@/lib/hooks/use-restoration-tools';

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

const logTypeConfig: Record<string, { label: string; variant: 'info' | 'default' | 'warning' | 'purple' | 'success' | 'secondary' }> = {
  setup: { label: 'Setup', variant: 'info' },
  daily: { label: 'Daily', variant: 'default' },
  adjustment: { label: 'Adjustment', variant: 'warning' },
  equipment_change: { label: 'Equipment Change', variant: 'purple' },
  completion: { label: 'Completion', variant: 'success' },
  note: { label: 'Note', variant: 'secondary' },
};

const logTypeOptions = [
  { value: 'all', label: 'All Types' },
  { value: 'setup', label: 'Setup' },
  { value: 'daily', label: 'Daily' },
  { value: 'adjustment', label: 'Adjustment' },
  { value: 'equipment_change', label: 'Equipment Change' },
  { value: 'completion', label: 'Completion' },
  { value: 'note', label: 'Note' },
];

// ============================================================================
// TABS
// ============================================================================

const TABS = [
  { key: 'logs' as const, label: 'Drying Logs', icon: Wind },
  { key: 'trends' as const, label: 'Trends & Alerts', icon: BarChart3 },
  { key: 'psychrometric' as const, label: 'Psychrometric', icon: Gauge },
  { key: 'completion' as const, label: 'Completion Status', icon: CheckCircle2 },
] satisfies { key: string; label: string; icon: LucideIcon }[];

type TabKey = typeof TABS[number]['key'];

// ============================================================================
// PAGE
// ============================================================================

export default function DryingLogsPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<TabKey>('logs');
  const { dryingLogs, readings, stats, loading, addDryingLog } = useRestorationTools();

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-48 mb-2" /><div className="skeleton h-4 w-56" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => <div key={i} className="px-6 py-4 flex items-center gap-4"><div className="flex-1"><div className="skeleton h-4 w-40 mb-2" /><div className="skeleton h-3 w-32" /></div><div className="skeleton h-5 w-16 rounded-full" /></div>)}
        </div>
      </div>
    );
  }

  // Unique job count
  const uniqueJobs = new Set(dryingLogs.map((l) => l.jobId)).size;
  const totalEquipmentRunning = dryingLogs.length > 0
    ? dryingLogs[0].dehumidifiersRunning + dryingLogs[0].airMoversRunning + dryingLogs[0].airScrubbersRunning
    : 0;

  // Psychrometric summary from latest log entry with temperature data
  const latestWithTemp = dryingLogs.find(l => l.indoorTempF != null && l.indoorHumidity != null);
  const latestGpp = latestWithTemp?.indoorTempF != null && latestWithTemp?.indoorHumidity != null
    ? calculateGpp(latestWithTemp.indoorTempF, latestWithTemp.indoorHumidity)
    : null;

  // Average indoor humidity
  const avgIndoorHumidity = (() => {
    const withHumidity = dryingLogs.filter((l) => l.indoorHumidity != null);
    if (withHumidity.length === 0) return '--';
    return (withHumidity.reduce((sum, l) => sum + (l.indoorHumidity || 0), 0) / withHumidity.length).toFixed(1) + '%';
  })();

  return (
    <div className="space-y-6 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('dryingLogs.title')}</h1>
          <p className="text-muted mt-1">IICRC S500 drying documentation with psychrometric analysis and completion tracking</p>
        </div>
      </div>

      {/* Immutable Notice */}
      <div className="flex items-center gap-2 px-4 py-2.5 bg-amber-900/15 border border-amber-700/30 rounded-lg">
        <Lock size={14} className="text-amber-500 flex-shrink-0" />
        <span className="text-sm text-amber-300">{t('dryingLogs.immutableNotice')}</span>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-900/30 rounded-lg"><Wind size={20} className="text-blue-400" /></div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.totalLogs}</p>
                <p className="text-sm text-muted">{t('dryingLogs.totalEntries')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-900/30 rounded-lg"><Activity size={20} className="text-purple-400" /></div>
              <div>
                <p className="text-2xl font-semibold text-main">{uniqueJobs}</p>
                <p className="text-sm text-muted">{t('dashboard.activeJobs')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-900/30 rounded-lg"><Thermometer size={20} className="text-emerald-400" /></div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalEquipmentRunning}</p>
                <p className="text-sm text-muted">{t('dryingLogs.equipmentRunning')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-900/30 rounded-lg"><Droplets size={20} className="text-amber-400" /></div>
              <div>
                <p className="text-2xl font-semibold text-main">{avgIndoorHumidity}</p>
                <p className="text-sm text-muted">{t('dryingLogs.avgIndoorHumidity')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-cyan-900/30 rounded-lg"><Gauge size={20} className="text-cyan-400" /></div>
              <div>
                <p className="text-2xl font-semibold text-main">{latestGpp?.toFixed(0) ?? '--'}</p>
                <p className="text-sm text-muted">Indoor GPP</p>
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
      {activeTab === 'logs' && <LogsTab dryingLogs={dryingLogs} addDryingLog={addDryingLog} />}
      {activeTab === 'trends' && <TrendsTab dryingLogs={dryingLogs} readings={readings} />}
      {activeTab === 'psychrometric' && <PsychrometricTab dryingLogs={dryingLogs} />}
      {activeTab === 'completion' && <CompletionTab dryingLogs={dryingLogs} readings={readings} />}
    </div>
  );
}

// ============================================================================
// LOGS TAB
// ============================================================================

function LogsTab({
  dryingLogs,
  addDryingLog,
}: {
  dryingLogs: DryingLogWithJob[];
  addDryingLog: ReturnType<typeof useRestorationTools>['addDryingLog'];
}) {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);

  const filtered = dryingLogs.filter((log) => {
    const matchesSearch =
      log.jobName.toLowerCase().includes(search.toLowerCase()) ||
      log.summary.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || log.logType === typeFilter;
    return matchesSearch && matchesType;
  });

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        <div className="flex flex-col sm:flex-row gap-4">
          <SearchInput value={search} onChange={setSearch} placeholder="Search by job or summary..." className="sm:w-80" />
          <Select options={logTypeOptions} value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} className="sm:w-48" />
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus size={16} />
          Add Entry
        </Button>
      </div>

      {/* Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-main">
                <th className="w-8 px-2 py-3"></th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.date')}</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.job')}</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.type')}</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.summary')}</th>
                <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.equipment')}</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Indoor / GPP</th>
                <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.photos')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {filtered.map((log) => (
                <LogRow
                  key={log.id}
                  log={log}
                  isExpanded={expandedId === log.id}
                  onToggle={() => setExpandedId(expandedId === log.id ? null : log.id)}
                />
              ))}
            </tbody>
          </table>
        </div>

        {filtered.length === 0 && (
          <CardContent className="p-12 text-center">
            <Wind size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('dryingLogs.noRecords')}</h3>
            <p className="text-muted mb-4">Start documenting drying progress with setup logs, daily readings, and equipment changes.</p>
            <Button onClick={() => setShowAddModal(true)}>
              <Plus size={16} />Add Entry
            </Button>
          </CardContent>
        )}
      </Card>

      {showAddModal && <AddDryingLogModal onClose={() => setShowAddModal(false)} onAdd={addDryingLog} />}
    </div>
  );
}

function LogRow({ log, isExpanded, onToggle }: { log: DryingLogWithJob; isExpanded: boolean; onToggle: () => void }) {
  const { t } = useTranslation();
  const typeInfo = logTypeConfig[log.logType] || logTypeConfig.note;
  const photosArray = Array.isArray(log.photos) ? log.photos : [];

  // Calculate GPP for this log entry
  const gpp = log.indoorTempF != null && log.indoorHumidity != null
    ? calculateGpp(log.indoorTempF, log.indoorHumidity)
    : null;
  const outdoorGpp = log.outdoorTempF != null && log.outdoorHumidity != null
    ? calculateGpp(log.outdoorTempF, log.outdoorHumidity)
    : null;
  const grainDepression = gpp != null && outdoorGpp != null ? gpp - outdoorGpp : null;

  return (
    <>
      <tr className="hover:bg-surface-hover transition-colors cursor-pointer" onClick={onToggle}>
        <td className="px-2 py-3">
          {isExpanded
            ? <ChevronDown size={16} className="text-muted" />
            : <ChevronRight size={16} className="text-muted" />
          }
        </td>
        <td className="px-4 py-3 text-main whitespace-nowrap">{formatDateTime(log.recordedAt)}</td>
        <td className="px-4 py-3 text-main font-medium truncate max-w-[180px]">{log.jobName || 'Unknown Job'}</td>
        <td className="px-4 py-3">
          <Badge variant={typeInfo.variant}>{typeInfo.label}</Badge>
        </td>
        <td className="px-4 py-3 text-main truncate max-w-[250px]">{log.summary}</td>
        <td className="px-4 py-3 text-center text-main">{log.equipmentCount}</td>
        <td className="px-4 py-3 text-right text-main whitespace-nowrap">
          {log.indoorTempF != null && log.indoorHumidity != null ? (
            <div>
              <span>{log.indoorTempF}°F / {log.indoorHumidity}%</span>
              {gpp != null && <span className="text-xs text-blue-400 ml-1">({gpp.toFixed(0)} GPP)</span>}
            </div>
          ) : (
            <span className="text-muted">--</span>
          )}
        </td>
        <td className="px-4 py-3 text-center">
          {photosArray.length > 0 ? (
            <span className="flex items-center justify-center gap-1 text-muted">
              <Image size={14} />{photosArray.length}
            </span>
          ) : (
            <span className="text-muted">--</span>
          )}
        </td>
      </tr>
      {isExpanded && (
        <tr>
          <td colSpan={8} className="px-6 py-4 bg-secondary/50">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
              {log.details && (
                <div className="col-span-2 md:col-span-4">
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.details')}</p>
                  <p className="text-main">{log.details}</p>
                </div>
              )}
              <div>
                <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('moisture.dehumidifiers')}</p>
                <p className="font-medium text-main">{log.dehumidifiersRunning}</p>
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('moisture.airMovers')}</p>
                <p className="font-medium text-main">{log.airMoversRunning}</p>
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.airScrubbers')}</p>
                <p className="font-medium text-main">{log.airScrubbersRunning}</p>
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('dryingLogs.totalEquipment')}</p>
                <p className="font-medium text-main">{log.equipmentCount}</p>
              </div>

              {/* Psychrometric Data */}
              {log.indoorTempF != null && (
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Indoor</p>
                  <p className="font-medium text-main">{log.indoorTempF}°F / {log.indoorHumidity}% RH</p>
                  {gpp != null && <p className="text-xs text-blue-400">GPP: {gpp.toFixed(1)}</p>}
                </div>
              )}
              {log.outdoorTempF != null && (
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Outdoor</p>
                  <p className="font-medium text-main">{log.outdoorTempF}°F / {log.outdoorHumidity}% RH</p>
                  {outdoorGpp != null && <p className="text-xs text-muted">GPP: {outdoorGpp.toFixed(1)}</p>}
                </div>
              )}
              {grainDepression != null && (
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Grain Depression</p>
                  <p className={cn('font-bold', grainDepression >= 40 ? 'text-emerald-400' : grainDepression > 0 ? 'text-amber-400' : 'text-red-400')}>
                    {grainDepression > 0 ? '+' : ''}{grainDepression.toFixed(1)} grains
                  </p>
                  <p className="text-xs text-muted">{grainDepression >= 40 ? 'Efficient' : grainDepression > 0 ? 'Marginal' : 'Inefficient'}</p>
                </div>
              )}
              {gpp != null && (
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Dew Point</p>
                  <p className="font-medium text-main">{calculateDewPoint(log.indoorTempF!, log.indoorHumidity!).toFixed(1)}°F</p>
                </div>
              )}
            </div>
          </td>
        </tr>
      )}
    </>
  );
}

// ============================================================================
// TRENDS TAB
// ============================================================================

function TrendsTab({ dryingLogs, readings }: { dryingLogs: DryingLogWithJob[]; readings: MoistureReadingWithJob[] }) {
  // Group by job, analyze day-over-day changes
  const jobTrends = useMemo(() => {
    const jobMap = new Map<string, { jobName: string; logs: DryingLogWithJob[]; readings: MoistureReadingWithJob[] }>();
    for (const log of dryingLogs) {
      const existing = jobMap.get(log.jobId) || { jobName: log.jobName, logs: [], readings: [] };
      existing.logs.push(log);
      jobMap.set(log.jobId, existing);
    }
    for (const r of readings) {
      const existing = jobMap.get(r.jobId);
      if (existing) existing.readings.push(r);
    }
    return Array.from(jobMap.values()).filter(j => j.logs.length >= 2);
  }, [dryingLogs, readings]);

  // Anomaly detection: readings that went UP instead of down
  const anomalies = useMemo(() => {
    const alerts: { jobName: string; area: string; prev: number; curr: number; date: string }[] = [];

    for (const job of jobTrends) {
      // Group readings by area
      const areaMap = new Map<string, MoistureReadingWithJob[]>();
      for (const r of job.readings) {
        const key = r.areaName;
        const existing = areaMap.get(key) || [];
        existing.push(r);
        areaMap.set(key, existing);
      }

      for (const [area, areaReadings] of areaMap) {
        const sorted = [...areaReadings].sort((a, b) => new Date(a.recordedAt).getTime() - new Date(b.recordedAt).getTime());
        for (let i = 1; i < sorted.length; i++) {
          if (sorted[i].readingValue > sorted[i - 1].readingValue) {
            alerts.push({
              jobName: job.jobName,
              area,
              prev: sorted[i - 1].readingValue,
              curr: sorted[i].readingValue,
              date: sorted[i].recordedAt,
            });
          }
        }
      }
    }
    return alerts.slice(0, 20);
  }, [jobTrends]);

  // Humidity trend analysis
  const humidityTrends = useMemo(() => {
    const trends: {
      jobName: string;
      entries: { date: string; indoorRh: number; indoorGpp: number | null; outdoorGpp: number | null; equipmentCount: number }[];
      direction: 'improving' | 'stagnant' | 'worsening';
    }[] = [];

    for (const job of jobTrends) {
      const logsWithHumidity = job.logs
        .filter(l => l.indoorHumidity != null && l.indoorTempF != null)
        .sort((a, b) => new Date(a.recordedAt).getTime() - new Date(b.recordedAt).getTime());

      if (logsWithHumidity.length < 2) continue;

      const entries = logsWithHumidity.map(l => ({
        date: l.recordedAt,
        indoorRh: l.indoorHumidity!,
        indoorGpp: l.indoorTempF != null && l.indoorHumidity != null ? calculateGpp(l.indoorTempF, l.indoorHumidity) : null,
        outdoorGpp: l.outdoorTempF != null && l.outdoorHumidity != null ? calculateGpp(l.outdoorTempF, l.outdoorHumidity) : null,
        equipmentCount: l.equipmentCount,
      }));

      // Check if humidity is trending down
      const first3 = entries.slice(0, Math.min(3, entries.length));
      const last3 = entries.slice(-Math.min(3, entries.length));
      const avgFirst = first3.reduce((s, e) => s + e.indoorRh, 0) / first3.length;
      const avgLast = last3.reduce((s, e) => s + e.indoorRh, 0) / last3.length;
      const direction = avgLast < avgFirst - 5 ? 'improving' : avgLast > avgFirst + 5 ? 'worsening' : 'stagnant';

      trends.push({ jobName: job.jobName, entries, direction });
    }

    return trends;
  }, [jobTrends]);

  return (
    <div className="space-y-6">
      {/* Anomaly Alerts */}
      {anomalies.length > 0 && (
        <Card className="border-amber-700/30">
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2 text-amber-400">
              <AlertTriangle size={18} />
              Moisture Increase Alerts
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-xs text-muted mb-3">
              These monitoring points showed INCREASED moisture since the previous reading. This may indicate new water intrusion, equipment malfunction, or secondary damage.
            </p>
            <div className="space-y-2">
              {anomalies.map((alert, i) => (
                <div key={i} className="flex items-center justify-between p-3 bg-amber-900/10 border border-amber-700/20 rounded-lg">
                  <div>
                    <p className="text-sm font-medium text-main">{alert.jobName} — {alert.area}</p>
                    <p className="text-xs text-muted">{formatDateTime(alert.date)}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-muted">{alert.prev}</span>
                    <TrendingUp size={14} className="text-red-400" />
                    <span className="font-mono text-red-400 font-medium">{alert.curr}</span>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {anomalies.length === 0 && (
        <div className="bg-emerald-900/15 border border-emerald-700/30 rounded-xl p-4 flex items-center gap-3">
          <CheckCircle2 size={18} className="text-emerald-400" />
          <div>
            <p className="font-medium text-emerald-300">No Anomalies Detected</p>
            <p className="text-xs text-emerald-400/70">All monitored points show consistent downward (drying) trends.</p>
          </div>
        </div>
      )}

      {/* Humidity Trends by Job */}
      <div>
        <h2 className="text-lg font-semibold text-main mb-3">Indoor Humidity Trends by Job</h2>
        {humidityTrends.length === 0 ? (
          <Card>
            <CardContent className="p-8 text-center">
              <BarChart3 size={36} className="mx-auto text-muted mb-3" />
              <p className="text-muted">Need at least 2 drying log entries per job to show trends.</p>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-4">
            {humidityTrends.map((trend, i) => (
              <Card key={i}>
                <CardHeader className="pb-2">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-base">{trend.jobName || 'Unnamed Job'}</CardTitle>
                    <Badge variant={trend.direction === 'improving' ? 'success' : trend.direction === 'worsening' ? 'error' : 'warning'}>
                      {trend.direction === 'improving' && <TrendingDown size={12} className="mr-1" />}
                      {trend.direction === 'worsening' && <TrendingUp size={12} className="mr-1" />}
                      {trend.direction}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent>
                  {/* Simple text-based trend chart */}
                  <div className="overflow-x-auto">
                    <table className="w-full text-xs">
                      <thead>
                        <tr className="border-b border-main">
                          <th className="text-left px-3 py-2 text-muted uppercase">Date</th>
                          <th className="text-right px-3 py-2 text-muted uppercase">Indoor RH%</th>
                          <th className="text-right px-3 py-2 text-muted uppercase">Indoor GPP</th>
                          <th className="text-right px-3 py-2 text-muted uppercase">Outdoor GPP</th>
                          <th className="text-right px-3 py-2 text-muted uppercase">Grain Depr.</th>
                          <th className="text-center px-3 py-2 text-muted uppercase">Equipment</th>
                          <th className="px-3 py-2 text-muted uppercase">Trend</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-main">
                        {trend.entries.map((entry, j) => {
                          const grainDep = entry.indoorGpp != null && entry.outdoorGpp != null
                            ? entry.indoorGpp - entry.outdoorGpp : null;
                          const prevRh = j > 0 ? trend.entries[j - 1].indoorRh : null;
                          const improving = prevRh != null ? entry.indoorRh < prevRh : null;
                          return (
                            <tr key={j} className="hover:bg-surface-hover">
                              <td className="px-3 py-2 text-main whitespace-nowrap">{formatDate(entry.date)}</td>
                              <td className="px-3 py-2 text-right font-mono text-main">{entry.indoorRh}%</td>
                              <td className="px-3 py-2 text-right font-mono text-blue-400">{entry.indoorGpp?.toFixed(1) ?? '—'}</td>
                              <td className="px-3 py-2 text-right font-mono text-muted">{entry.outdoorGpp?.toFixed(1) ?? '—'}</td>
                              <td className={cn('px-3 py-2 text-right font-mono font-medium',
                                grainDep != null ? (grainDep >= 40 ? 'text-emerald-400' : grainDep > 0 ? 'text-amber-400' : 'text-red-400') : 'text-muted'
                              )}>
                                {grainDep != null ? `${grainDep > 0 ? '+' : ''}${grainDep.toFixed(1)}` : '—'}
                              </td>
                              <td className="px-3 py-2 text-center text-muted">{entry.equipmentCount}</td>
                              <td className="px-3 py-2">
                                {improving === true && <TrendingDown size={14} className="text-emerald-400" />}
                                {improving === false && <TrendingUp size={14} className="text-red-400" />}
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ============================================================================
// PSYCHROMETRIC TAB
// ============================================================================

function PsychrometricTab({ dryingLogs }: { dryingLogs: DryingLogWithJob[] }) {
  const logsWithPsych = useMemo(() =>
    dryingLogs
      .filter(l => l.indoorTempF != null && l.indoorHumidity != null)
      .map(l => {
        const indoorGpp = calculateGpp(l.indoorTempF!, l.indoorHumidity!);
        const indoorDew = calculateDewPoint(l.indoorTempF!, l.indoorHumidity!);
        const outdoorGpp = l.outdoorTempF != null && l.outdoorHumidity != null
          ? calculateGpp(l.outdoorTempF, l.outdoorHumidity) : null;
        const outdoorDew = l.outdoorTempF != null && l.outdoorHumidity != null
          ? calculateDewPoint(l.outdoorTempF, l.outdoorHumidity) : null;
        const grainDep = outdoorGpp != null ? indoorGpp - outdoorGpp : null;
        return { ...l, indoorGpp, indoorDew, outdoorGpp, outdoorDew, grainDep };
      }),
    [dryingLogs]
  );

  if (logsWithPsych.length === 0) {
    return (
      <Card>
        <CardContent className="p-12 text-center">
          <Gauge size={48} className="mx-auto text-muted mb-4" />
          <h3 className="text-lg font-medium text-main mb-2">No Psychrometric Data</h3>
          <p className="text-muted mb-2">Add drying log entries with indoor temperature and humidity to see psychrometric calculations.</p>
          <p className="text-xs text-muted">GPP (Grains Per Pound) measures absolute moisture content. Grain Depression = Indoor GPP - Outdoor GPP. Target: 40+ grains for efficient drying.</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {/* Reference Guide */}
      <div className="bg-secondary/50 border border-main/30 rounded-xl p-4">
        <h3 className="text-sm font-semibold text-main mb-2">Psychrometric Quick Reference</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          <div>
            <p className="text-muted uppercase tracking-wider mb-1">GPP (Grains Per Pound)</p>
            <p className="text-main">Absolute moisture content of air. Higher = more moisture. Used to compare indoor vs outdoor regardless of temperature.</p>
          </div>
          <div>
            <p className="text-muted uppercase tracking-wider mb-1">Grain Depression</p>
            <p className="text-main">Indoor GPP minus Outdoor GPP. Positive = dehumidifiers removing moisture. Target: 40+ grains for efficient drying.</p>
          </div>
          <div>
            <p className="text-muted uppercase tracking-wider mb-1">Dew Point</p>
            <p className="text-main">Temperature at which condensation forms. Keep indoor dew point above surface temperatures to prevent secondary damage.</p>
          </div>
        </div>
      </div>

      {/* Psychrometric Log Table */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Psychrometric Readings Log</CardTitle>
        </CardHeader>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left px-3 py-3 text-xs font-medium text-muted uppercase">Date</th>
                <th className="text-left px-3 py-3 text-xs font-medium text-muted uppercase">Job</th>
                <th className="text-right px-3 py-3 text-xs font-medium text-muted uppercase">Temp (F)</th>
                <th className="text-right px-3 py-3 text-xs font-medium text-muted uppercase">RH%</th>
                <th className="text-right px-3 py-3 text-xs font-medium text-muted uppercase">GPP</th>
                <th className="text-right px-3 py-3 text-xs font-medium text-muted uppercase">Dew Pt</th>
                <th className="text-right px-3 py-3 text-xs font-medium text-muted uppercase">Out GPP</th>
                <th className="text-right px-3 py-3 text-xs font-medium text-muted uppercase">Grain Dep.</th>
                <th className="text-center px-3 py-3 text-xs font-medium text-muted uppercase">Equipment</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {logsWithPsych.map((log) => (
                <tr key={log.id} className="hover:bg-surface-hover">
                  <td className="px-3 py-2.5 text-main text-xs whitespace-nowrap">{formatDateTime(log.recordedAt)}</td>
                  <td className="px-3 py-2.5 text-main font-medium truncate max-w-[140px]">{log.jobName || '—'}</td>
                  <td className="px-3 py-2.5 text-right font-mono text-main">{log.indoorTempF}°</td>
                  <td className="px-3 py-2.5 text-right font-mono text-main">{log.indoorHumidity}%</td>
                  <td className="px-3 py-2.5 text-right font-mono text-blue-400 font-medium">{log.indoorGpp.toFixed(1)}</td>
                  <td className="px-3 py-2.5 text-right font-mono text-muted">{log.indoorDew.toFixed(1)}°</td>
                  <td className="px-3 py-2.5 text-right font-mono text-muted">{log.outdoorGpp?.toFixed(1) ?? '—'}</td>
                  <td className={cn('px-3 py-2.5 text-right font-mono font-medium',
                    log.grainDep != null
                      ? (log.grainDep >= 40 ? 'text-emerald-400' : log.grainDep > 0 ? 'text-amber-400' : 'text-red-400')
                      : 'text-muted'
                  )}>
                    {log.grainDep != null ? `${log.grainDep > 0 ? '+' : ''}${log.grainDep.toFixed(1)}` : '—'}
                  </td>
                  <td className="px-3 py-2.5 text-center text-xs text-muted">
                    {log.dehumidifiersRunning}D/{log.airMoversRunning}AM/{log.airScrubbersRunning}AS
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      {/* Grain Depression Performance Legend */}
      <div className="grid grid-cols-3 gap-4 text-sm">
        <div className="p-3 bg-emerald-900/10 border border-emerald-700/20 rounded-lg text-center">
          <p className="font-semibold text-emerald-400">40+ grains</p>
          <p className="text-xs text-muted">Excellent drying efficiency</p>
        </div>
        <div className="p-3 bg-amber-900/10 border border-amber-700/20 rounded-lg text-center">
          <p className="font-semibold text-amber-400">1-39 grains</p>
          <p className="text-xs text-muted">Marginal — increase dehu/heat</p>
        </div>
        <div className="p-3 bg-red-900/10 border border-red-700/20 rounded-lg text-center">
          <p className="font-semibold text-red-400">0 or negative</p>
          <p className="text-xs text-muted">Inefficient — check equipment</p>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// COMPLETION TAB
// ============================================================================

function CompletionTab({ dryingLogs, readings }: { dryingLogs: DryingLogWithJob[]; readings: MoistureReadingWithJob[] }) {
  // Group by job, determine completion status
  const jobStatuses = useMemo(() => {
    const jobMap = new Map<string, {
      jobId: string;
      jobName: string;
      hasCompletion: boolean;
      logCount: number;
      firstLog: string | null;
      lastLog: string | null;
      daysActive: number;
      readingCount: number;
      dryCount: number;
      wetCount: number;
      allDry: boolean;
      percentDry: number;
    }>();

    for (const log of dryingLogs) {
      const existing = jobMap.get(log.jobId) || {
        jobId: log.jobId,
        jobName: log.jobName,
        hasCompletion: false,
        logCount: 0,
        firstLog: null,
        lastLog: null,
        daysActive: 0,
        readingCount: 0,
        dryCount: 0,
        wetCount: 0,
        allDry: false,
        percentDry: 0,
      };
      existing.logCount++;
      if (log.logType === 'completion') existing.hasCompletion = true;
      if (!existing.firstLog || log.recordedAt < existing.firstLog) existing.firstLog = log.recordedAt;
      if (!existing.lastLog || log.recordedAt > existing.lastLog) existing.lastLog = log.recordedAt;
      jobMap.set(log.jobId, existing);
    }

    // Add reading data
    for (const r of readings) {
      const existing = jobMap.get(r.jobId);
      if (!existing) continue;
      existing.readingCount++;
      if (r.isDry) existing.dryCount++; else existing.wetCount++;
    }

    // Calculate completion
    for (const [, job] of jobMap) {
      if (job.firstLog && job.lastLog) {
        job.daysActive = Math.ceil((new Date(job.lastLog).getTime() - new Date(job.firstLog).getTime()) / (1000 * 60 * 60 * 24)) + 1;
      }
      const total = job.dryCount + job.wetCount;
      job.percentDry = total > 0 ? Math.round((job.dryCount / total) * 100) : 0;
      job.allDry = total > 0 && job.wetCount === 0;
    }

    return Array.from(jobMap.values()).sort((a, b) => {
      // Sort: complete last, then by percent dry descending
      if (a.hasCompletion !== b.hasCompletion) return a.hasCompletion ? 1 : -1;
      return b.percentDry - a.percentDry;
    });
  }, [dryingLogs, readings]);

  const completeJobs = jobStatuses.filter(j => j.hasCompletion);
  const activeJobs = jobStatuses.filter(j => !j.hasCompletion);
  const readyForCompletion = activeJobs.filter(j => j.allDry && j.readingCount > 0);

  return (
    <div className="space-y-6">
      {/* Ready for Completion */}
      {readyForCompletion.length > 0 && (
        <div className="bg-emerald-900/15 border border-emerald-700/30 rounded-xl p-4">
          <div className="flex items-center gap-2 mb-3">
            <CheckCircle2 size={18} className="text-emerald-400" />
            <p className="font-medium text-emerald-300">{readyForCompletion.length} Job{readyForCompletion.length > 1 ? 's' : ''} Ready for Drying Completion</p>
          </div>
          {readyForCompletion.map((job) => (
            <div key={job.jobId} className="flex items-center justify-between p-3 bg-emerald-900/10 rounded-lg mb-2 last:mb-0">
              <div>
                <p className="font-medium text-main">{job.jobName || 'Unnamed Job'}</p>
                <p className="text-xs text-muted">All {job.dryCount} monitoring points at or below drying goal | Day {job.daysActive}</p>
              </div>
              <Badge variant="success">All Points Dry</Badge>
            </div>
          ))}
          <p className="text-xs text-emerald-400/70 mt-2">
            IICRC S500: Drying is complete when all monitored points reach or fall below their target moisture content. Document final readings and create a completion log entry.
          </p>
        </div>
      )}

      {/* Active Jobs */}
      <div>
        <h2 className="text-lg font-semibold text-main mb-3">Active Drying Jobs</h2>
        {activeJobs.length === 0 ? (
          <Card>
            <CardContent className="p-8 text-center">
              <Wind size={36} className="mx-auto text-muted mb-3" />
              <p className="text-muted">No active drying jobs in progress.</p>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-3">
            {activeJobs.map((job) => (
              <Card key={job.jobId}>
                <CardContent className="p-4">
                  <div className="flex items-center justify-between mb-3">
                    <div>
                      <p className="font-medium text-main">{job.jobName || 'Unnamed Job'}</p>
                      <p className="text-xs text-muted">Day {job.daysActive} | {job.logCount} log entries | {job.readingCount} readings</p>
                    </div>
                    {job.allDry ? (
                      <Badge variant="success">All Dry</Badge>
                    ) : job.percentDry >= 75 ? (
                      <Badge variant="warning">Nearly Dry ({job.percentDry}%)</Badge>
                    ) : (
                      <Badge variant="error">Drying ({job.percentDry}%)</Badge>
                    )}
                  </div>
                  <div className="w-full bg-secondary rounded-full h-2.5">
                    <div
                      className={cn('h-2.5 rounded-full transition-all',
                        job.allDry ? 'bg-emerald-500' : job.percentDry >= 75 ? 'bg-amber-500' : 'bg-red-500'
                      )}
                      style={{ width: `${job.percentDry}%` }}
                    />
                  </div>
                  <div className="flex items-center justify-between mt-2 text-xs text-muted">
                    <span>{job.dryCount} dry / {job.wetCount} wet monitoring points</span>
                    <span>Started: {job.firstLog ? formatDate(job.firstLog) : '—'}</span>
                  </div>

                  {/* Criteria Checklist */}
                  <div className="mt-3 pt-3 border-t border-main">
                    <p className="text-xs text-muted uppercase tracking-wider mb-2">Completion Criteria</p>
                    <div className="space-y-1">
                      {[
                        { label: 'All monitoring points at or below drying goal', met: job.allDry },
                        { label: 'Minimum 3 daily drying log entries', met: job.logCount >= 3 },
                        { label: 'At least 2 days of stable (consistent) readings', met: job.daysActive >= 2 && job.readingCount >= 4 },
                        { label: 'Completion log entry submitted', met: job.hasCompletion },
                      ].map((criterion, i) => (
                        <div key={i} className="flex items-center gap-2 text-xs">
                          {criterion.met ? (
                            <CheckCircle2 size={14} className="text-emerald-400 flex-shrink-0" />
                          ) : (
                            <div className="w-3.5 h-3.5 rounded-full border-2 border-muted flex-shrink-0" />
                          )}
                          <span className={criterion.met ? 'text-main' : 'text-muted'}>{criterion.label}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>

      {/* Completed Jobs */}
      {completeJobs.length > 0 && (
        <div>
          <h2 className="text-lg font-semibold text-main mb-3">Completed Drying Jobs</h2>
          <div className="space-y-2">
            {completeJobs.map((job) => (
              <Card key={job.jobId}>
                <CardContent className="p-4 flex items-center justify-between">
                  <div>
                    <p className="font-medium text-main">{job.jobName || 'Unnamed Job'}</p>
                    <p className="text-xs text-muted">{job.daysActive} days | {job.logCount} entries | {job.readingCount} readings</p>
                  </div>
                  <div className="flex items-center gap-3">
                    <Badge variant="success">Complete</Badge>
                    <p className="text-xs text-muted">{job.lastLog ? formatDate(job.lastLog) : ''}</p>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// ============================================================================
// ADD DRYING LOG MODAL
// ============================================================================

function AddDryingLogModal({
  onClose,
  onAdd,
}: {
  onClose: () => void;
  onAdd: ReturnType<typeof useRestorationTools>['addDryingLog'];
}) {
  const { t } = useTranslation();
  const [logType, setLogType] = useState('daily');
  const [summary, setSummary] = useState('');
  const [details, setDetails] = useState('');
  const [dehuCount, setDehuCount] = useState('0');
  const [amCount, setAmCount] = useState('0');
  const [asCount, setAsCount] = useState('0');
  const [indoorTemp, setIndoorTemp] = useState('');
  const [indoorRh, setIndoorRh] = useState('');
  const [outdoorTemp, setOutdoorTemp] = useState('');
  const [outdoorRh, setOutdoorRh] = useState('');
  const [jobId, setJobId] = useState('');
  const [saving, setSaving] = useState(false);

  // Auto-calculate psychrometric
  const indoorGpp = indoorTemp && indoorRh ? calculateGpp(parseFloat(indoorTemp), parseFloat(indoorRh)) : null;
  const indoorDew = indoorTemp && indoorRh ? calculateDewPoint(parseFloat(indoorTemp), parseFloat(indoorRh)) : null;
  const outdoorGpp = outdoorTemp && outdoorRh ? calculateGpp(parseFloat(outdoorTemp), parseFloat(outdoorRh)) : null;
  const grainDep = indoorGpp != null && outdoorGpp != null ? indoorGpp - outdoorGpp : null;

  const equipmentTotal = (parseInt(dehuCount) || 0) + (parseInt(amCount) || 0) + (parseInt(asCount) || 0);

  const handleSave = async () => {
    if (!summary || !jobId) return;
    try {
      setSaving(true);
      await onAdd({
        jobId,
        logType: logType as 'setup' | 'daily' | 'adjustment' | 'equipment_change' | 'completion' | 'note',
        summary,
        details: details || undefined,
        equipmentCount: equipmentTotal,
        dehumidifiersRunning: parseInt(dehuCount) || 0,
        airMoversRunning: parseInt(amCount) || 0,
        airScrubbersRunning: parseInt(asCount) || 0,
        indoorTempF: indoorTemp ? parseFloat(indoorTemp) : undefined,
        indoorHumidity: indoorRh ? parseFloat(indoorRh) : undefined,
        outdoorTempF: outdoorTemp ? parseFloat(outdoorTemp) : undefined,
        outdoorHumidity: outdoorRh ? parseFloat(outdoorRh) : undefined,
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
            <CardTitle>{t('dryingLogs.addDryingLogEntry')}</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input label="Job ID *" value={jobId} onChange={(e) => setJobId(e.target.value)} placeholder="Paste job ID" />
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Log Type *</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
              value={logType} onChange={(e) => setLogType(e.target.value)}>
              <option value="setup">{t('dryingLogs.setup')}</option>
              <option value="daily">{t('common.daily')}</option>
              <option value="adjustment">{t('dryingLogs.adjustment')}</option>
              <option value="equipment_change">{t('dryingLogs.equipmentChange')}</option>
              <option value="completion">{t('dryingLogs.completion')}</option>
              <option value="note">{t('common.note')}</option>
            </select>
          </div>
          <Input label="Summary *" value={summary} onChange={(e) => setSummary(e.target.value)} placeholder="Daily moisture check - Day 3" />
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.details')}</label>
            <textarea
              rows={3}
              value={details}
              onChange={(e) => setDetails(e.target.value)}
              placeholder="Detailed observations..."
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none"
            />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <Input label={t('moisture.dehumidifiers')} type="number" value={dehuCount} onChange={(e) => setDehuCount(e.target.value)} />
            <Input label={t('moisture.airMovers')} type="number" value={amCount} onChange={(e) => setAmCount(e.target.value)} />
            <Input label={t('common.airScrubbers')} type="number" value={asCount} onChange={(e) => setAsCount(e.target.value)} />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input label="Indoor Temp (F)" type="number" value={indoorTemp} onChange={(e) => setIndoorTemp(e.target.value)} placeholder="72" />
            <Input label="Indoor RH (%)" type="number" value={indoorRh} onChange={(e) => setIndoorRh(e.target.value)} placeholder="55" />
          </div>
          {indoorGpp != null && (
            <div className="p-3 bg-blue-900/10 rounded-lg border border-blue-800/20 text-sm">
              <p className="text-blue-400">GPP: {indoorGpp.toFixed(1)} | Dew Point: {indoorDew?.toFixed(1)}°F</p>
            </div>
          )}
          <div className="grid grid-cols-2 gap-4">
            <Input label="Outdoor Temp (F)" type="number" value={outdoorTemp} onChange={(e) => setOutdoorTemp(e.target.value)} placeholder="65" />
            <Input label="Outdoor RH (%)" type="number" value={outdoorRh} onChange={(e) => setOutdoorRh(e.target.value)} placeholder="60" />
          </div>
          {grainDep != null && (
            <div className={cn('p-3 rounded-lg border text-sm',
              grainDep >= 40 ? 'bg-emerald-900/10 border-emerald-700/20' : grainDep > 0 ? 'bg-amber-900/10 border-amber-700/20' : 'bg-red-900/10 border-red-700/20'
            )}>
              <p className={grainDep >= 40 ? 'text-emerald-400' : grainDep > 0 ? 'text-amber-400' : 'text-red-400'}>
                Grain Depression: {grainDep > 0 ? '+' : ''}{grainDep.toFixed(1)} — {grainDep >= 40 ? 'Efficient drying' : grainDep > 0 ? 'Marginal drying' : 'Inefficient — increase dehu'}
              </p>
            </div>
          )}
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1" onClick={handleSave} disabled={saving || !summary || !jobId}>
              {saving ? 'Saving...' : t('dryingLogs.saveEntry')}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
