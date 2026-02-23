'use client';

import { useState } from 'react';
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
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDateTime, formatDate, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { useRestorationTools } from '@/lib/hooks/use-restoration-tools';
import type { DryingLogWithJob } from '@/lib/hooks/use-restoration-tools';

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

export default function DryingLogsPage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const { dryingLogs, stats, loading } = useRestorationTools();

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

  const filtered = dryingLogs.filter((log) => {
    const matchesSearch =
      log.jobName.toLowerCase().includes(search.toLowerCase()) ||
      log.summary.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || log.logType === typeFilter;
    return matchesSearch && matchesType;
  });

  // Stats
  const uniqueJobs = new Set(dryingLogs.map((l) => l.jobId)).size;
  const totalEquipmentRunning = dryingLogs.length > 0
    ? dryingLogs[0].dehumidifiersRunning + dryingLogs[0].airMoversRunning + dryingLogs[0].airScrubbersRunning
    : 0;
  const avgIndoorHumidity = (() => {
    const withHumidity = dryingLogs.filter((l) => l.indoorHumidity != null);
    if (withHumidity.length === 0) return '--';
    return (withHumidity.reduce((sum, l) => sum + (l.indoorHumidity || 0), 0) / withHumidity.length).toFixed(1) + '%';
  })();

  const toggleExpand = (id: string) => {
    setExpandedId((prev) => (prev === id ? null : id));
  };

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('dryingLogs.title')}</h1>
          <p className="text-muted mt-1">Document drying progress and environmental conditions</p>
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus size={16} />
          Add Entry
        </Button>
      </div>

      {/* Immutable Notice */}
      <div className="flex items-center gap-2 px-4 py-2.5 bg-amber-900/15 border border-amber-700/30 rounded-lg">
        <Lock size={14} className="text-amber-500 flex-shrink-0" />
        <span className="text-sm text-amber-300">Drying logs are immutable legal records and cannot be edited or deleted once created.</span>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Wind size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.totalLogs}</p>
                <p className="text-sm text-muted">Total Entries</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Activity size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{uniqueJobs}</p>
                <p className="text-sm text-muted">Active Jobs</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Thermometer size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalEquipmentRunning}</p>
                <p className="text-sm text-muted">Equipment Running</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Droplets size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{avgIndoorHumidity}</p>
                <p className="text-sm text-muted">Avg Indoor Humidity</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search by job or summary..."
          className="sm:w-80"
        />
        <Select
          options={logTypeOptions}
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="sm:w-48"
        />
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
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Summary</th>
                <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Equipment</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Indoor</th>
                <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Photos</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {filtered.map((log) => (
                <LogRow
                  key={log.id}
                  log={log}
                  isExpanded={expandedId === log.id}
                  onToggle={() => toggleExpand(log.id)}
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

      {showAddModal && <AddDryingLogModal onClose={() => setShowAddModal(false)} />}
    </div>
  );
}

function LogRow({ log, isExpanded, onToggle }: { log: DryingLogWithJob; isExpanded: boolean; onToggle: () => void }) {
  const typeInfo = logTypeConfig[log.logType] || logTypeConfig.note;
  const photosArray = Array.isArray(log.photos) ? log.photos : [];

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
            <span>{log.indoorTempF}°F / {log.indoorHumidity}%</span>
          ) : (
            <span className="text-zinc-500">--</span>
          )}
        </td>
        <td className="px-4 py-3 text-center">
          {photosArray.length > 0 ? (
            <span className="flex items-center justify-center gap-1 text-muted">
              <Image size={14} />{photosArray.length}
            </span>
          ) : (
            <span className="text-zinc-500">--</span>
          )}
        </td>
      </tr>
      {isExpanded && (
        <tr>
          <td colSpan={8} className="px-6 py-4 bg-secondary/50">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
              {log.details && (
                <div className="col-span-2 md:col-span-4">
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Details</p>
                  <p className="text-main">{log.details}</p>
                </div>
              )}
              <div>
                <p className="text-xs text-muted uppercase tracking-wider mb-1">Dehumidifiers</p>
                <p className="font-medium text-main">{log.dehumidifiersRunning}</p>
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wider mb-1">Air Movers</p>
                <p className="font-medium text-main">{log.airMoversRunning}</p>
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wider mb-1">Air Scrubbers</p>
                <p className="font-medium text-main">{log.airScrubbersRunning}</p>
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wider mb-1">Total Equipment</p>
                <p className="font-medium text-main">{log.equipmentCount}</p>
              </div>
              {log.outdoorTempF != null && (
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Outdoor Temp</p>
                  <p className="font-medium text-main">{log.outdoorTempF}°F</p>
                </div>
              )}
              {log.outdoorHumidity != null && (
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Outdoor Humidity</p>
                  <p className="font-medium text-main">{log.outdoorHumidity}%</p>
                </div>
              )}
              {log.indoorTempF != null && (
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Indoor Temp</p>
                  <p className="font-medium text-main">{log.indoorTempF}°F</p>
                </div>
              )}
              {log.indoorHumidity != null && (
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider mb-1">Indoor Humidity</p>
                  <p className="font-medium text-main">{log.indoorHumidity}%</p>
                </div>
              )}
            </div>
          </td>
        </tr>
      )}
    </>
  );
}

function AddDryingLogModal({ onClose }: { onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Add Drying Log Entry</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Log Type *</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
              <option value="setup">Setup</option>
              <option value="daily">Daily</option>
              <option value="adjustment">Adjustment</option>
              <option value="equipment_change">Equipment Change</option>
              <option value="completion">Completion</option>
              <option value="note">Note</option>
            </select>
          </div>
          <Input label="Summary *" placeholder="Daily moisture check - Day 3" />
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Details</label>
            <textarea
              rows={3}
              placeholder="Detailed observations..."
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none"
            />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <Input label="Dehumidifiers" type="number" placeholder="0" />
            <Input label="Air Movers" type="number" placeholder="0" />
            <Input label="Air Scrubbers" type="number" placeholder="0" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input label="Indoor Temp (F)" type="number" placeholder="72" />
            <Input label="Indoor Humidity (%)" type="number" placeholder="55" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input label="Outdoor Temp (F)" type="number" placeholder="65" />
            <Input label="Outdoor Humidity (%)" type="number" placeholder="60" />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1"><Plus size={16} />Save Entry</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
